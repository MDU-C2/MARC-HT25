"""
Gripper Detector
Specialized detector for gripper detection during calibration
Uses gripper_nano.pt model with optimized settings
"""

import cv2
import numpy as np
from pathlib import Path


class GripperDetector:
    def __init__(self, model_path='gripper_nano.pt', confidence_threshold=0.5):
        """
        Initialize gripper detector with YOLO model

        Args:
            model_path: Path to YOLO model (default: 'gripper_nano.pt')
            confidence_threshold: Detection confidence threshold (0.0-1.0)
        """
        self.confidence_threshold = confidence_threshold
        self.model_path = model_path

        print("   - Loading gripper detection model...")
        try:
            from ultralytics import YOLO

            # Load model
            self.model = YOLO(model_path)

            print(f"   [OK] Model loaded: {model_path}")
            print(f"   - Confidence threshold: {confidence_threshold}")

        except ImportError:
            print("   [ERROR] Ultralytics not installed!")
            print("   Run: pip install ultralytics")
            raise
        except Exception as e:
            print(f"   [ERROR] Error loading model: {e}")
            raise

    def detect(self, rgb_frame, depth_frame):
        """
        Detect gripper in frame

        Args:
            rgb_frame: RGB image
            depth_frame: Depth map

        Returns:
            list: List of gripper detections
        """
        if rgb_frame is None:
            return []

        detections = []

        # Run inference
        results = self.model(rgb_frame, conf=self.confidence_threshold, verbose=False, imgsz=640)

        # Process results
        for result in results:
            boxes = result.boxes

            for box in boxes:
                # Get class name and confidence
                cls_id = int(box.cls[0])
                cls_name = result.names[cls_id]
                confidence = float(box.conf[0])

                # Only accept gripper detections
                if cls_name.lower() != 'gripper':
                    continue

                # Get bounding box
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                x, y, w, h = int(x1), int(y1), int(x2 - x1), int(y2 - y1)

                # Calculate center
                cx = x + w // 2
                cy = y + h // 2

                # Get depth at center
                depth_value = self._get_depth_at_point(depth_frame, rgb_frame, cx, cy)

                detection = {
                    'class': 'gripper',
                    'bbox': (x, y, w, h),
                    'center': (cx, cy),
                    'depth': depth_value,
                    'confidence': confidence,
                    'yolo_class': cls_name,
                    'orientation_state': 'upright',
                    'source': 'yolo'
                }

                detections.append(detection)

        return detections

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

    def get_best_detection(self, detections):
        """Get detection with highest confidence"""
        if len(detections) == 0:
            return None
        
        return max(detections, key=lambda x: x['confidence'])