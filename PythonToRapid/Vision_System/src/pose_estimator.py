######### For presenting ##########
###################################
# #!/usr/bin/env python3
"""
Pose Estimator - PIXEL-BASED VERSION
Transforms screen coordinates [pixel_x, pixel_y, depth] directly to robot coordinates
Uses static calibration from calibration_params.json
"""

import numpy as np
import cv2
import json
from pathlib import Path
from typing import List, Tuple, Dict, Optional


class PoseEstimator:
    def __init__(self, camera_intrinsics):
        """
        Initialize pose estimator with pixel-based calibration

        Args:
            camera_intrinsics: Camera parameters (kept for compatibility)
        """
        self.intrinsics = camera_intrinsics
        self.pixel_mode = True

        # Load static calibration
        self._load_calibration()

        print("   - Using YOLO class-based orientations for cups")

    def _load_calibration(self):
        """Load pixel-based calibration from JSON"""
        calib_file = Path(__file__).parent.parent / 'calibration_params.json'

        if not calib_file.exists():
            print("   WARNING: calibration_params.json not found!")
            print("   Run: python calibrate.py first")
            self._use_fallback()
            return

        try:
            with open(calib_file, 'r') as f:
                calib = json.load(f)

            self.method = calib.get('method', 'unknown')
            self.zones = calib.get('zones', {})
            self.zone_boundaries = calib.get('zone_boundaries', {})
            self.global_fallback = calib.get('global_fallback', {})

            # USE GLOBAL MODEL AS PRIMARY
            self.use_global_model = True

            print(f"   [OK] Loaded pixel-based calibration")
            print(f"     Method: GLOBAL MODEL")

        except Exception as e:
            print(f"   [ERROR] ERROR loading calibration: {e}")
            self._use_fallback()

    def _use_fallback(self):
        """Emergency fallback calibration"""
        print("   Using emergency fallback calibration")
        self.zones = {}
        self.zone_boundaries = {}
        self.global_fallback = {
            'coef_x': [0.5, 0.0, 0.0],
            'intercept_x': 0,
            'coef_y': [0.0, 1.5, 0.0],
            'intercept_y': -500,
            'robot_z': -50
        }

    def screen_to_robot(self, pixel_x, pixel_y, depth_mm):
        """
        Transform screen coordinates to robot coordinates
        
        Args:
            pixel_x, pixel_y: Pixel coordinates from camera
            depth_mm: Depth in millimeters

        Returns:
            np.ndarray: [robot_x, robot_y, robot_z] in mm
        """
        screen = np.array([pixel_x, pixel_y, depth_mm])
        
        params = self.global_fallback
        
        robot_x = np.dot(params['coef_x'], screen) + params['intercept_x']
        robot_y = np.dot(params['coef_y'], screen) + params['intercept_y']
        robot_z = params['robot_z']
        
        return np.array([robot_x, robot_y, robot_z])

    def get_full_pose(self, detection, rgb_frame=None, in_robot_frame=True):
        """
        Get complete 6DOF pose using YOLO class-based orientation

        Args:
            detection: Detection dict with 'center', 'depth', and 'orientation_quat'
            rgb_frame: RGB image (not used, kept for compatibility)
            in_robot_frame: If True, return robot coordinates (default)

        Returns:
            dict: Pose information
        """
        cx, cy = detection['center']
        depth = detection['depth']

        if depth == 0:
            return None

        # Transform to robot frame
        if in_robot_frame:
            position = self.screen_to_robot(cx, cy, depth)
            
            # Apply gripper offset correction
            if detection['class'] == 'gripper':
                position[0] += 25.0   # X offset correction
                position[1] += 210.0  # Y offset correction
        else:
            # Return screen coordinates
            position = np.array([cx, cy, depth])

        # Get orientation from YOLO detection
        if 'orientation_quat' in detection and detection['class'] == 'cup':
            orientation = np.array(detection['orientation_quat'])
        else:
            # Default orientation for non-cups
            orientation = np.array([0.0, 0.0, 1.0])

        return {
            'position': position,
            'orientation': orientation,
            'class': detection['class'],
            'confidence': detection['confidence'],
            'frame': 'robot' if in_robot_frame else 'screen',
            'orientation_state': detection.get('orientation_state', 'unknown')
        }

    # LEGACY COMPATIBILITY
    def pixel_to_3d(self, pixel_x, pixel_y, depth_mm):
        """Legacy method - redirects to screen_to_robot"""
        return self.screen_to_robot(pixel_x, pixel_y, depth_mm)

    def transform_to_robot_frame(self, position_camera):
        """Legacy method - position_camera is [x,y,z] screen coords"""
        return self.screen_to_robot(position_camera[0], position_camera[1], position_camera[2])