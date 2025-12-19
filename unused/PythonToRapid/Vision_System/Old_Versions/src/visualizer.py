"""
Visualizer
Display detection results with orientation states, gripper, and cup numbering
"""

import cv2
import numpy as np


class Visualizer:
    def __init__(self):
        """Initialize visualizer"""
        self.show_coordinates = True
        self.show_depth = True
        self.show_confidence = True
        self.show_orientation = True

        # Colors for different classes (BGR format)
        self.colors = {
            'cup': (0, 255, 0),        # Green for cups
            'robot_base': (255, 0, 0),  # Blue for robot base
            'gripper': (255, 0, 255),   # Magenta for gripper
            'unknown': (0, 0, 255)      # Red for unknown
        }

        # Font settings
        self.font = cv2.FONT_HERSHEY_SIMPLEX
        self.font_scale = 0.5
        self.font_thickness = 1

        print("   ✓ Visualizer initialized")

    def draw_detections(self, rgb_frame, depth_frame, detections):
        """
        Draw detection results on frame

        Args:
            rgb_frame: RGB image
            depth_frame: Depth map
            detections: List of detections

        Returns:
            np.ndarray: Annotated frame
        """
        if rgb_frame is None:
            return np.zeros((480, 640, 3), dtype=np.uint8)

        # Create copy to draw on
        display_frame = rgb_frame.copy()

        # Separate detections by type
        cups = [d for d in detections if d['class'] == 'cup']
        gripper = [d for d in detections if d['class'] == 'gripper']
        base = [d for d in detections if d['class'] == 'robot_base']

        # Draw each detection
        for detection in detections:
            self._draw_detection(display_frame, detection)

        # Draw info panel with counts
        self._draw_info_panel(display_frame, len(cups), len(gripper), len(base))

        # Draw depth colormap (side by side if available)
        if depth_frame is not None and self.show_depth:
            display_frame = self._add_depth_view(display_frame, depth_frame)

        return display_frame

    def _draw_detection(self, frame, detection):
        """Draw single detection with orientation and cup numbering"""
        bbox = detection['bbox']
        x, y, w, h = bbox
        center = detection['center']
        cx, cy = center
        obj_class = detection['class']
        confidence = detection['confidence']
        depth = detection['depth']

        # Get color for class
        color = self.colors.get(obj_class, self.colors['unknown'])

        # Draw bounding box
        cv2.rectangle(frame, (x, y), (x + w, y + h), color, 2)

        # Draw center point
        cv2.circle(frame, (cx, cy), 5, color, -1)
        cv2.circle(frame, (cx, cy), 7, color, 2)

        # Prepare label
        label_parts = []

        # Class name with numbering
        if obj_class == 'cup':
            # Show Cup_X | Orientation
            cup_index = detection.get('cup_index', '?')
            orientation_state = detection.get('orientation_state', 'unknown')
            label_parts.append(f"Cup_{cup_index}")
            label_parts.append(orientation_state)
        elif obj_class == 'gripper':
            label_parts.append("GRIPPER")
        else:
            label_parts.append(obj_class.upper())

        # Add confidence
        if self.show_confidence:
            label_parts.append(f"{confidence:.2f}")

        # Add depth
        if self.show_depth and depth > 0:
            label_parts.append(f"{depth}mm")

        label = " | ".join(label_parts)

        # Draw label background
        (text_width, text_height), baseline = cv2.getTextSize(
            label, self.font, self.font_scale, self.font_thickness
        )

        # Position label above bbox
        label_y = y - 10
        if label_y < text_height + 10:
            label_y = y + h + text_height + 10

        cv2.rectangle(
            frame,
            (x, label_y - text_height - 5),
            (x + text_width + 5, label_y + 5),
            color,
            -1
        )

        # Draw label text
        cv2.putText(
            frame,
            label,
            (x + 3, label_y),
            self.font,
            self.font_scale,
            (255, 255, 255),
            self.font_thickness,
            cv2.LINE_AA
        )

        # Draw 3D coordinates if enabled
        if self.show_coordinates and depth > 0:
            coord_text = f"({cx}, {cy}, {depth})"
            cv2.putText(
                frame,
                coord_text,
                (x, y + h + 35),
                self.font,
                self.font_scale - 0.1,
                color,
                self.font_thickness,
                cv2.LINE_AA
            )

        # Draw orientation quaternion for cups
        if obj_class == 'cup' and self.show_orientation:
            quat = detection.get('orientation_quat', [1, 0, 0, 0])
            quat_text = f"q:[{quat[0]:.2f},{quat[1]:.2f},{quat[2]:.2f},{quat[3]:.2f}]"
            cv2.putText(
                frame,
                quat_text,
                (x, y + h + 50),
                self.font,
                0.35,
                color,
                1,
                cv2.LINE_AA
            )

    def _draw_info_panel(self, frame, num_cups, num_grippers, num_base):
        """Draw information panel at top of frame"""
        panel_height = 40
        panel = np.zeros((panel_height, frame.shape[1], 3), dtype=np.uint8)
        panel[:] = (40, 40, 40)  # Dark gray

        # Info text line 1
        info_text1 = f"Cups: {num_cups} | Gripper: {num_grippers} | Base: {num_base}"
        cv2.putText(
            panel,
            info_text1,
            (10, 15),
            self.font,
            0.4,
            (255, 255, 255),
            1,
            cv2.LINE_AA
        )

        # Info text line 2
        info_text2 = "Press: 'q'-quit | 's'-save | 'r'-send to robot | 'c'-toggle coords"
        cv2.putText(
            panel,
            info_text2,
            (10, 32),
            self.font,
            0.4,
            (200, 200, 200),
            1,
            cv2.LINE_AA
        )

        # Concatenate panel with frame
        frame_with_panel = np.vstack([panel, frame])

        # Copy back to original frame (expand it)
        frame.resize((frame_with_panel.shape[0], frame_with_panel.shape[1], 3), refcheck=False)
        frame[:] = frame_with_panel

    def _add_depth_view(self, rgb_frame, depth_frame):
        """Add depth visualization side by side"""
        # Normalize depth for visualization
        depth_normalized = cv2.normalize(
            depth_frame,
            None,
            0, 255,
            cv2.NORM_MINMAX,
            dtype=cv2.CV_8U
        )

        # Apply colormap
        depth_colored = cv2.applyColorMap(depth_normalized, cv2.COLORMAP_JET)

        # Resize depth to match RGB height
        target_height = rgb_frame.shape[0]
        aspect_ratio = depth_frame.shape[1] / depth_frame.shape[0]
        target_width = int(target_height * aspect_ratio)

        depth_resized = cv2.resize(depth_colored, (target_width, target_height))

        # Concatenate side by side
        combined = np.hstack([rgb_frame, depth_resized])

        return combined

    def toggle_coordinates(self):
        """Toggle coordinate display"""
        self.show_coordinates = not self.show_coordinates
        status = "ON" if self.show_coordinates else "OFF"
        print(f"   Coordinate display: {status}")

    def toggle_depth(self):
        """Toggle depth view"""
        self.show_depth = not self.show_depth
        status = "ON" if self.show_depth else "OFF"
        print(f"   Depth view: {status}")

    def toggle_confidence(self):
        """Toggle confidence display"""
        self.show_confidence = not self.show_confidence
        status = "ON" if self.show_confidence else "OFF"
        print(f"   Confidence display: {status}")

    def toggle_orientation(self):
        """Toggle orientation display"""
        self.show_orientation = not self.show_orientation
        status = "ON" if self.show_orientation else "OFF"
        print(f"   Orientation display: {status}")