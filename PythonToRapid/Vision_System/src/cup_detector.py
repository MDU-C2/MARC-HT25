"""
Cup Detector V5
Detects cups using trained YOLOv8 model best_cup_orientation_New.pt)
Detects gripper and robot markers
Orientation from YOLO class names
"""

import cv2
import numpy as np
from pathlib import Path


class CupDetector:
    def __init__(self, use_yolo=True, model_path='best_cup_orientation.pt', confidence_threshold=0.25):
        """
        Initialize cup detector with trained YOLOv8 model

        Args:
            use_yolo: Use YOLO neural network (True recommended)
            model_path: Path to trained YOLO model (default: 'best_cup_orientation.pt')
            confidence_threshold: Detection confidence threshold (0.0-1.0)
        """
        self.use_yolo = use_yolo
        self.confidence_threshold = confidence_threshold
        self.model_path = model_path

        # Orientation vectors for each YOLO class (3D directional vectors)
        # Model has 8 classes: Back, Front, left_side, right_side, upright, upside_down, Gripper, handle
        self.orientation_map = {
            'Back': [-1.0, 0.0, 0.0],
            'Front': [1.0, 0.0, 0.0],
            'left_side': [0.0, -1.0, 0.0],
            'right_side': [0.0, 1.0, 0.0],
            'upright': [0.0, 0.0, 1.0],
            'upside_down': [0.0, 0.0, -1.0],
        }

        if use_yolo:
            print("   - Loading trained YOLOv8 model...")
            try:
                from ultralytics import YOLO

                # Load trained model
                self.model = YOLO(model_path)

                print(f"   [OK] YOLOv8 model loaded: {model_path}")
                print(f"   - Confidence threshold: {confidence_threshold}")
                print(f"   - Classes: {list(self.orientation_map.keys())}")

            except ImportError:
                print("   [ERROR] Ultralytics not installed!")
                print("   Run: pip install ultralytics")
                raise
            except Exception as e:
                print(f"   [ERROR] Error loading YOLO model: {e}")
                raise
        else:
            print("   [OK] YOLO disabled")

        # Setup color detection for robot base marker
        self._setup_marker_detection()

    def _setup_marker_detection(self):
        """Setup color-based detection for robot base marker"""
        # Green marker (robot base) - HSV ranges
        self.green_ranges = [
            {'lower': np.array([35, 50, 50]), 'upper': np.array([85, 255, 255])},
        ]

        self.min_marker_area = 500
        print("   - Green marker (base) detection configured")

    def detect(self, rgb_frame, depth_frame):
        """
        Detect cups, gripper, and robot markers in frame

        Args:
            rgb_frame: RGB image
            depth_frame: Depth map

        Returns:
            list: List of detections with cup_index for ordering
        """
        if rgb_frame is None:
            return []

        detections = []

        # 1. Detect with YOLO (cups and gripper)
        if self.use_yolo:
            yolo_detections = self._detect_with_yolo(rgb_frame, depth_frame)
            detections.extend(yolo_detections)

        # 2. Detect robot base marker with color detection
        marker_detections = self._detect_markers(rgb_frame, depth_frame)
        detections.extend(marker_detections)

        # 3. Add cup numbering (Cup_1, Cup_2, etc.)
        cup_index = 1
        for detection in detections:
            if detection['class'] == 'cup':
                detection['cup_index'] = cup_index
                cup_index += 1

        return detections

    def _detect_with_yolo(self, rgb_frame, depth_frame):
        """YOLO-based detection for cups and gripper"""
        detections = []

        # Run inference
        results = self.model(rgb_frame, conf=self.confidence_threshold, verbose=False, imgsz=640)
        # Debug: print what YOLO found

        # Process results
        for result in results:
            boxes = result.boxes

            for box in boxes:
                # Get class name and confidence
                cls_id = int(box.cls[0])
                cls_name = result.names[cls_id]
                confidence = float(box.conf[0])

                # Check if this is a known class
                if cls_name not in self.orientation_map:
                    continue

                # Get bounding box
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                x, y, w, h = int(x1), int(y1), int(x2 - x1), int(y2 - y1)

                # Calculate center
                cx = x + w // 2
                cy = y + h // 2

                # Get depth at center
                depth_value = self._get_depth_at_point(depth_frame, rgb_frame, cx, cy)

                # Get orientation quaternion from class name
                orientation_quat = self.orientation_map.get(cls_name, [1.0, 0.0, 0.0, 0.0])

                # Determine object class
                if cls_name == 'Gripper':
                    obj_class = 'gripper'
                    orientation_state = 'upright'
                else:
                    obj_class = 'cup'
                    orientation_state = cls_name

                detection = {
                    'class': obj_class,
                    'bbox': (x, y, w, h),
                    'center': (cx, cy),
                    'depth': depth_value,
                    'confidence': confidence,
                    'yolo_class': cls_name,
                    'orientation_state': orientation_state,
                    'orientation_quat': orientation_quat,
                    'source': 'yolo'
                }

                detections.append(detection)

        return detections

    def _detect_markers(self, rgb_frame, depth_frame):
        """Color-based marker detection for robot base"""
        detections = []

        # Convert to HSV
        hsv = cv2.cvtColor(rgb_frame, cv2.COLOR_BGR2HSV)

        # Detect green marker (robot base)
        green_detection = self._detect_colored_marker(
            hsv, rgb_frame, depth_frame,
            self.green_ranges, 'robot_base'
        )
        if green_detection:
            detections.append(green_detection)

        return detections

    def _detect_colored_marker(self, hsv, rgb_frame, depth_frame, color_ranges, marker_class):
        """Detect a single colored marker"""
        # Combine all color ranges
        combined_mask = np.zeros(hsv.shape[:2], dtype=np.uint8)

        for color_range in color_ranges:
            mask = cv2.inRange(hsv, color_range['lower'], color_range['upper'])
            combined_mask = cv2.bitwise_or(combined_mask, mask)

        # Morphological operations to clean up
        kernel = np.ones((5, 5), np.uint8)
        combined_mask = cv2.morphologyEx(combined_mask, cv2.MORPH_OPEN, kernel)
        combined_mask = cv2.morphologyEx(combined_mask, cv2.MORPH_CLOSE, kernel)

        # Find contours
        contours, _ = cv2.findContours(combined_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Find largest contour
        largest_contour = None
        max_area = 0

        for contour in contours:
            area = cv2.contourArea(contour)
            if area > max_area and area > self.min_marker_area:
                max_area = area
                largest_contour = contour

        if largest_contour is None:
            return None

        # Get bounding box
        x, y, w, h = cv2.boundingRect(largest_contour)
        cx = x + w // 2
        cy = y + h // 2

        # Get depth at center
        depth_value = self._get_depth_at_point(depth_frame, rgb_frame, cx, cy)

        # Calculate confidence
        perimeter = cv2.arcLength(largest_contour, True)
        circularity = 4 * np.pi * max_area / (perimeter * perimeter) if perimeter > 0 else 0
        aspect_ratio = float(w) / h if h > 0 else 0
        aspect_score = 1.0 - abs(1.0 - aspect_ratio) if 0.5 < aspect_ratio < 2.0 else 0.3
        confidence = min((circularity + aspect_score) / 2.0, 1.0)

        detection = {
            'class': marker_class,
            'bbox': (x, y, w, h),
            'center': (cx, cy),
            'depth': depth_value,
            'confidence': confidence,
            'area': max_area,
            'orientation_state': 'upright',
            'orientation_quat': [1.0, 0.0, 0.0, 0.0]
        }

        return detection

    def _get_depth_at_point(self, depth_frame, rgb_frame, cx, cy):
        """Get depth value at a specific point"""
        if depth_frame is None:
            return 0

        h_ratio = depth_frame.shape[0] / rgb_frame.shape[0]
        w_ratio = depth_frame.shape[1] / rgb_frame.shape[1]

        depth_y = int(cy * h_ratio)
        depth_x = int(cx * w_ratio)

        if 0 <= depth_y < depth_frame.shape[0] and 0 <= depth_x < depth_frame.shape[1]:
            y1 = max(0, depth_y - 2)
            y2 = min(depth_frame.shape[0], depth_y + 3)
            x1 = max(0, depth_x - 2)
            x2 = min(depth_frame.shape[1], depth_x + 3)

            depth_patch = depth_frame[y1:y2, x1:x2]
            valid_depths = depth_patch[depth_patch > 0]

            if len(valid_depths) > 0:
                return int(np.median(valid_depths))

        return 0

    def filter_detections(self, detections, min_confidence=0.3):
        """Filter detections by confidence"""
        return [d for d in detections if d['confidence'] >= min_confidence]