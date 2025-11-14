"""
Main script - Cup Detection System
REFACTORED: Only handles detection + visualization
All robot logic moved to PythonToRapid.py
"""

import cv2
import sys
import time
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.append(str(Path(__file__).parent / "src"))

from src.camera_manager import OAKDCamera
from src.cup_detector import CupDetector
from src.pose_estimator import PoseEstimator
from src.visualizer import Visualizer
from src.PythonToRapid import RobotCommunication


class CupDetectionSystem:
    def __init__(self):
        """Initialize cup detection system"""
        print("=" * 60)
        print("Cup Detection System - YuMi Robot")
        print("REFACTORED - Dynamic Protocol")
        print("=" * 60)

        # Initialize components
        print("\n[1/5] Initializing OAK-D Pro camera...")
        self.camera = OAKDCamera()

        print("[2/5] Loading detection model...")
        self.detector = CupDetector(
            model_path='best_cup_orientation_New.pt',
            confidence_threshold=0.6
        )

        print("[3/5] Initializing pose estimator...")
        self.pose_estimator = PoseEstimator(self.camera.intrinsics)

        print("[4/5] Setting up visualizer...")
        self.visualizer = Visualizer()
        
        print("[5/5] Initializing robot communication...")
        self.robot = RobotCommunication()

        print("\n✓ System ready!")
        self._print_controls()

    def _print_controls(self):
        """Print control instructions"""
        print("\nControls:")
        print("  'q' - Quit")
        print("  's' - Save frame")
        print("  'p' - Print status")
        print("  'r' - Start robot (manual)")
        print("  'a' - Toggle auto-start robot")
        print("\nMode: AUTOMATIC")
        print("  - Auto-detects cups")
        print("  - Auto-starts robot when cups found")
        print("-" * 60)

    def process_detections(self, detections, rgb_frame):
        """
        Process detections and update robot queue
        
        Args:
            detections: Raw detections from detector
            rgb_frame: RGB frame for pose estimation
            
        Returns:
            list: Processed cup data
        """
        cups_data = []
        
        for detection in detections:
            obj_class = detection['class']
            
            if obj_class != 'cup':
                continue
            
            # Get pose in robot frame
            pose = self.pose_estimator.get_full_pose(detection, rgb_frame, in_robot_frame=True)
            
            if pose is None:
                continue
            
            cup_index = detection.get('cup_index', len(cups_data) + 1)
            
            cup_data = {
                'id': f'cup_{cup_index}',
                'cup_number': cup_index,
                'position': {
                    'x': float(pose['position'][0]),
                    'y': float(pose['position'][1]),
                    'z': float(pose['position'][2])
                },
                'orientation': {
                    'x': float(pose['orientation'][0]),
                    'y': float(pose['orientation'][1]),
                    'z': float(pose['orientation'][2])
                },
                'orientation_state': pose['orientation_state'],
                'confidence': detection['confidence']
            }
            cups_data.append(cup_data)
        
        return cups_data

    def print_status(self):
        """Print current system status"""
        print("\n" + "=" * 60)
        print("SYSTEM STATUS")
        print("=" * 60)
        
        # Robot status
        status = self.robot.get_status()
        print(f"\n ROBOT:")
        print(f"  Connected: {status['connected']}")
        print(f"  Busy: {status['busy']}")
        print(f"  State: {status['state']}")
        print(f"  Total cups: {status['total_cups']}")
        print(f"  Unsent cups: {status['unsent_cups']}")
        print(f"  Cups sent: {status['cups_sent']}")
        
        print("\n CUP QUEUE:")
        unsent = self.robot.get_unsent_cups()
        if len(unsent) > 0:
            for cup in unsent:
                pos = cup['position']
                state = cup['orientation_state']
                num = cup['cup_number']
                print(f"  Cup_{num} [{state}]: x={pos['x']:.1f}, y={pos['y']:.1f}, z={pos['z']:.1f}")
        else:
            print("  (empty)")
        
        print("=" * 60 + "\n")

    def save_frame(self, display_frame):
        """Save current frame"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"capture_{timestamp}.png"
        cv2.imwrite(filename, display_frame)
        print(f"\n[SAVE] Frame saved: {filename}")

    def run(self):
        """Main detection loop"""
        auto_start = True
        last_auto_start_check = 0
        
        try:
            while True:
                # Get frames
                rgb_frame, depth_frame = self.camera.get_frames()

                if rgb_frame is None:
                    continue

                # Detect
                detections = self.detector.detect(rgb_frame, depth_frame)

                # Process detections → cup data
                cups_data = self.process_detections(detections, rgb_frame)
                
                # Add to robot queue
                if len(cups_data) > 0:
                    self.robot.add_cups(cups_data)

                # Auto-start robot (every 5 seconds)
                current_time = time.time()
                if auto_start and not self.robot.is_busy():
                    if current_time - last_auto_start_check > 5.0:
                        if len(self.robot.get_unsent_cups()) > 0:
                            print("\n[AUTO] Starting robot...")
                            self.robot.start_robot_thread()
                        last_auto_start_check = current_time

                # Visualize
                display_frame = self.visualizer.draw_detections(
                    rgb_frame,
                    depth_frame,
                    detections
                )

                # Add status overlay
                self._draw_status_overlay(display_frame, auto_start)

                # Show frame
                cv2.imshow("Cup Detection System - REFACTORED", display_frame)

                # Handle keys
                key = cv2.waitKey(1) & 0xFF

                if key == ord('q'):
                    print("\n[EXIT] Shutting down...")
                    break
                elif key == ord('s'):
                    self.save_frame(display_frame)
                elif key == ord('p'):
                    self.print_status()
                elif key == ord('r'):
                    print("\n[MANUAL] Starting robot...")
                    self.robot.start_robot_thread()
                elif key == ord('a'):
                    auto_start = not auto_start
                    status = "ON" if auto_start else "OFF"
                    print(f"\n[AUTO] Auto-start: {status}")

        except KeyboardInterrupt:
            print("\n[EXIT] Interrupted by user")
        except Exception as e:
            print(f"\n[ERROR] {str(e)}")
            import traceback
            traceback.print_exc()
        finally:
            # Cleanup
            self.robot.stop_robot_thread()
            self.camera.close()
            cv2.destroyAllWindows()
            print("[CLEANUP] Done")
            print("=" * 60)

    def _draw_status_overlay(self, frame, auto_start):
        """Draw status on frame"""
        h, w = frame.shape[:2]
        
        # Status box
        y = 50
        cv2.rectangle(frame, (10, y), (450, y + 120), (0, 0, 0), -1)
        cv2.rectangle(frame, (10, y), (450, y + 120), (0, 255, 0), 2)
        
        # Get status
        status = self.robot.get_status()
        
        # Status text
        status_lines = [
            f"CUPS IN QUEUE: {status['total_cups']} (Unsent: {status['unsent_cups']})",
            f"CUPS SENT: {status['cups_sent']}",
            f"ROBOT: {'BUSY' if status['busy'] else 'CONNECTED' if status['connected'] else 'DISCONNECTED'}",
            f"AUTO-START: {'ON' if auto_start else 'OFF'}"
        ]
        
        y_offset = y + 25
        for line in status_lines:
            cv2.putText(frame, line, (20, y_offset),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)
            y_offset += 28


def main():
    system = CupDetectionSystem()
    system.run()


if __name__ == "__main__":
    main()