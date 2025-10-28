#!/usr/bin/env python3
"""
Camera Manager for OAK-D Pro
Handles RGB and Depth stream acquisition
WITH ZONE-BASED DISTANCE-DEPENDENT DEPTH CORRECTION (FIXED)
"""

import depthai as dai
import cv2
import numpy as np


class OAKDCamera:
    def __init__(self, rgb_resolution="1080p", fps=30, depth_enabled=True):
        """
        Initialize OAK-D Pro camera

        Args:
            rgb_resolution: RGB camera resolution ("1080p", "720p", "4k")
            fps: Frames per second
            depth_enabled: Enable depth calculation
        """
        self.fps = fps
        self.depth_enabled = depth_enabled

        # Distance-dependent depth correction zones
        self.depth_correction_enabled = True
        self.correction_zones = [
            {'max_depth': 1200, 'scale': 0.97, 'offset': 0},  # Near zone
            {'max_depth': 1350, 'scale': 0.92, 'offset': 0},  # Mid zone
            {'max_depth': 99999, 'scale': 0.95, 'offset': 0}  # Far zone
        ]

        print(f"   - DepthAI version: {dai.__version__}")

        # Create pipeline
        self.pipeline = dai.Pipeline()

        # Setup cameras
        self._setup_rgb_camera(rgb_resolution)

        if depth_enabled:
            self._setup_depth()

        # Connect to device
        print(f"   - Connecting to device...")
        self.device = dai.Device(self.pipeline)

        # Get USB speed
        usb_speed = self.device.getUsbSpeed()
        print(f"   - USB Speed: {usb_speed.name}")

        # Output queues
        self.rgb_queue = self.device.getOutputQueue(name="rgb", maxSize=4, blocking=False)

        if depth_enabled:
            self.depth_queue = self.device.getOutputQueue(name="depth", maxSize=4, blocking=False)
        else:
            self.depth_queue = None

        # Get camera calibration
        self.calib = self.device.readCalibration()
        self.intrinsics = self._get_camera_intrinsics()

        if self.depth_correction_enabled:
            print(f"   ✓ Zone-based depth correction enabled:")
            for i, zone in enumerate(self.correction_zones):
                print(f"     Zone {i + 1}: <{zone['max_depth']}mm → scale={zone['scale']}, offset={zone['offset']}")

        print(f"   ✓ Camera initialized successfully")

    def _setup_rgb_camera(self, resolution):
        """Setup RGB camera pipeline"""
        # Create nodes
        cam_rgb = self.pipeline.createColorCamera()
        xout_rgb = self.pipeline.createXLinkOut()
        xout_rgb.setStreamName("rgb")

        # Set resolution
        if resolution == "1080p":
            cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_1080_P)
        elif resolution == "720p":
            cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_720_P)
        elif resolution == "4k":
            cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_4_K)

        cam_rgb.setBoardSocket(dai.CameraBoardSocket.RGB)
        cam_rgb.setInterleaved(False)
        cam_rgb.setColorOrder(dai.ColorCameraProperties.ColorOrder.BGR)
        cam_rgb.setFps(self.fps)

        # Link output
        cam_rgb.video.link(xout_rgb.input)

        self.cam_rgb = cam_rgb
        print(f"   - RGB camera configured: {resolution} @ {self.fps}fps")

    def _setup_depth(self):
        """Setup stereo depth pipeline"""
        # Create nodes
        mono_left = self.pipeline.createMonoCamera()
        mono_right = self.pipeline.createMonoCamera()
        stereo = self.pipeline.createStereoDepth()
        xout_depth = self.pipeline.createXLinkOut()
        xout_depth.setStreamName("depth")

        # Configure left camera
        mono_left.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
        mono_left.setBoardSocket(dai.CameraBoardSocket.LEFT)
        mono_left.setFps(self.fps)

        # Configure right camera
        mono_right.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
        mono_right.setBoardSocket(dai.CameraBoardSocket.RIGHT)
        mono_right.setFps(self.fps)

        # Configure stereo
        stereo.setDefaultProfilePreset(dai.node.StereoDepth.PresetMode.HIGH_ACCURACY)
        stereo.setLeftRightCheck(True)
        stereo.setExtendedDisparity(False)
        stereo.setSubpixel(True)

        # Link pipeline
        mono_left.out.link(stereo.left)
        mono_right.out.link(stereo.right)
        stereo.depth.link(xout_depth.input)

        self.stereo = stereo
        print(f"   - Depth configured")

    def _get_camera_intrinsics(self):
        """Get camera intrinsic parameters"""
        try:
            intrinsics = self.calib.getCameraIntrinsics(
                dai.CameraBoardSocket.RGB,
                1920, 1080
            )
            return {
                'fx': intrinsics[0][0],
                'fy': intrinsics[1][1],
                'cx': intrinsics[0][2],
                'cy': intrinsics[1][2]
            }
        except Exception as e:
            print(f"   ⚠ Could not get calibration, using defaults")
            return {
                'fx': 1000.0,
                'fy': 1000.0,
                'cx': 960.0,
                'cy': 540.0
            }

    def _correct_depth(self, depth_frame):
        """
        Apply zone-based distance-dependent depth correction (FIXED)

        Args:
            depth_frame: Raw depth frame from camera

        Returns:
            Corrected depth frame
        """
        if not self.depth_correction_enabled or depth_frame is None:
            return depth_frame

        corrected = depth_frame.astype(np.float32)

        # Apply zone-based correction with proper ranges
        prev_max = 0
        for zone in self.correction_zones:
            # Create mask for this zone's range: prev_max < depth <= current_max
            mask = (depth_frame > prev_max) & (depth_frame <= zone['max_depth'])
            corrected[mask] = depth_frame[mask] * zone['scale'] + zone['offset']
            prev_max = zone['max_depth']

        # Convert back to uint16
        corrected = np.clip(corrected, 0, 65535).astype(np.uint16)

        return corrected

    def get_frames(self):
        """
        Get current RGB and depth frames (with correction applied)

        Returns:
            tuple: (rgb_frame, depth_frame)
        """
        rgb_frame = None
        depth_frame = None

        # Get RGB frame
        in_rgb = self.rgb_queue.tryGet()
        if in_rgb is not None:
            rgb_frame = in_rgb.getCvFrame()

        # Get depth frame and apply correction
        if self.depth_enabled and self.depth_queue is not None:
            in_depth = self.depth_queue.tryGet()
            if in_depth is not None:
                depth_frame = in_depth.getFrame()
                # Apply depth correction
                depth_frame = self._correct_depth(depth_frame)

        return rgb_frame, depth_frame

    def set_correction_zone(self, zone_index, scale=None, offset=None, max_depth=None):
        """
        Update a specific correction zone

        Args:
            zone_index: Zone number (0, 1, 2)
            scale: New scale factor (optional)
            offset: New offset in mm (optional)
            max_depth: New max depth for zone in mm (optional)
        """
        if 0 <= zone_index < len(self.correction_zones):
            if scale is not None:
                self.correction_zones[zone_index]['scale'] = scale
            if offset is not None:
                self.correction_zones[zone_index]['offset'] = offset
            if max_depth is not None:
                self.correction_zones[zone_index]['max_depth'] = max_depth

            zone = self.correction_zones[zone_index]
            print(
                f"   ✓ Zone {zone_index} updated: <{zone['max_depth']}mm, scale={zone['scale']}, offset={zone['offset']}")
        else:
            print(f"   ✗ Invalid zone index: {zone_index}")

    def enable_depth_correction(self, enabled=True):
        """Enable or disable depth correction"""
        self.depth_correction_enabled = enabled
        status = "enabled" if enabled else "disabled"
        print(f"   Depth correction {status}")

    def get_3d_coordinates(self, x, y, depth_value):
        """
        Convert 2D pixel coordinates + depth to 3D world coordinates
        Note: depth_value should already be corrected if using frames from get_frames()

        Args:
            x, y: Pixel coordinates
            depth_value: Depth in mm (corrected)

        Returns:
            tuple: (X, Y, Z) in mm
        """
        if depth_value == 0:
            return None

        # Convert to 3D using camera intrinsics
        Z = depth_value
        X = (x - self.intrinsics['cx']) * Z / self.intrinsics['fx']
        Y = (y - self.intrinsics['cy']) * Z / self.intrinsics['fy']

        return (X, Y, Z)

    def close(self):
        """Close camera connection"""
        if hasattr(self, 'device'):
            self.device.close()
            print("   ✓ Camera closed")