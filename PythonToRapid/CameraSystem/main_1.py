"""
Main script - AUTOMATIC Cup Detection and Robot Communication
Compatible with actual RAPID script
With background threading - camera never freezes
"""

import cv2
import sys
import time
import threading
import numpy as np
from pathlib import Path
from datetime import datetime
from typing import Dict, List

# Add src to path
sys.path.append(str(Path(__file__).parent / "src"))

from camera_manager import OAKDCamera
from cup_detector import CupDetector
from pose_estimator import PoseEstimator
from visualizer import Visualizer
from PythonToRapid_1 import RobotCommunication


class CupDetectionSystem:
    def __init__(self):
        """Initialize cup detection system"""
        self.cups = []
        self.gripper = None
        self.robot_base = None
        
        # Robot communication
        self.robot = RobotCommunication()
        self.robot_thread = None
        self.robot_busy = False
        
        # Status tracking
        self.total_cups_sent = 0
        
        print("=" * 60)
        print("Cup Detection System - YuMi Robot")
        print("AUTOMATIC MODE - Actual RAPID Protocol")
        print("=" * 60)

        # Initialize components
        print("\n[1/4] Initializing OAK-D Pro camera...")
        self.camera = OAKDCamera()

        print("[2/4] Loading detection model...")
        self.detector = CupDetector(
            model_path='best.pt',
            confidence_threshold=0.6
        )

        print("[3/4] Initializing pose estimator...")
        self.pose_estimator = PoseEstimator(self.camera.intrinsics)

        print("[4/4] Setting up visualizer...")
        self.visualizer = Visualizer()

        print("\n✓ System ready!")
        self._print_controls()

    def _print_controls(self):
        """Print control instructions"""
        print("\nControls:")
        print("  'q' - Quit")
        print("  's' - Save frame (debug)")
        print("  'p' - Print detections (debug)")
        print("\nMode: AUTOMATIC")
        print("  - Auto-connects to robot")
        print("  - Auto-sends cups when detected")
        print("  - Camera runs continuously (no freezing)")
        print("-" * 60)

    def update_detections(self, detections, rgb_frame):
        """Update internal detection storage"""
        # Clear previous
        self.cups = []
        self.gripper = None
        self.robot_base = None
        
        # Process detections
        for detection in detections:
            obj_class = detection['class']
            
            # Get pose in robot frame
            pose = self.pose_estimator.get_full_pose(detection, rgb_frame, in_robot_frame=True)
            
            if pose is None:
                continue
            
            if obj_class == 'cup':
                cup_index = detection.get('cup_index', len(self.cups) + 1)
                
                cup_data = {
                    'id': f'cup_{cup_index}',
                    'cup_number': cup_index,
                    'position': {
                        'x': float(pose['position'][0]),
                        'y': float(pose['position'][1]),
                        'z': float(pose['position'][2])
                    },
                    'orientation': {
                        'q1': float(pose['orientation'][0]),
                        'q2': float(pose['orientation'][1]),
                        'q3': float(pose['orientation'][2]),
                        'q4': float(pose['orientation'][3])
                    },
                    'orientation_state': pose['orientation_state'],
                    'confidence': detection['confidence']
                }
                self.cups.append(cup_data)
            
            elif obj_class == 'gripper':
                self.gripper = {
                    'position': {
                        'x': float(pose['position'][0]),
                        'y': float(pose['position'][1]),
                        'z': float(pose['position'][2])
                    },
                    'confidence': detection['confidence']
                }
            
            elif obj_class == 'robot_base':
                self.robot_base = {
                    'position': {
                        'x': float(pose['position'][0]),
                        'y': float(pose['position'][1]),
                        'z': float(pose['position'][2])
                    },
                    'confidence': detection['confidence']
                }

    def print_detections(self):
        """Print current detections"""
        print("\n" + "=" * 60)
        print("CURRENT DETECTIONS")
        print("=" * 60)
        
        print(f"\n🥤 CUPS: {len(self.cups)}")
        for cup in self.cups:
            pos = cup['position']
            state = cup['orientation_state']
            num = cup['cup_number']
            print(f"  Cup_{num} [{state}]: x={pos['x']:.1f}, y={pos['y']:.1f}, z={pos['z']:.1f}")
        
        print(f"\n🤖 GRIPPER: {'Detected' if self.gripper else 'Not detected'}")
        if self.gripper:
            pos = self.gripper['position']
            print(f"  Position: x={pos['x']:.1f}, y={pos['y']:.1f}, z={pos['z']:.1f}")
        
        print("=" * 60 + "\n")

    def save_frame(self, display_frame):
        """Save current frame"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"capture_{timestamp}.png"
        cv2.imwrite(filename, display_frame)
        print(f"\n[SAVE] Frame saved: {filename}")

    def robot_communication_thread(self):
        """Background thread for robot communication - STAYS CONNECTED"""
        try:
            # Connect ONCE
            if not self.robot.connect():
                print("[ROBOT] ✗ Connection failed")
                self.robot_busy = False
                return
            
            if not self.robot.start_session():
                print("[ROBOT] ✗ Session start failed")
                self.robot.disconnect()
                self.robot_busy = False
                return
            
            print("[ROBOT] ✓ Connected and ready")
            
            # CONTINUOUS LOOP - never disconnect
            while self.robot.is_connected():
                # Wait for cups
                if len(self.cups) == 0:
                    time.sleep(0.5)
                    continue
                
                # Send all detected cups
                cups_to_send = self.cups.copy()
                
                for i, cup in enumerate(cups_to_send):
                    remaining = len(cups_to_send) - i
                    
                    print(f"\n[STATUS] Sending Cup {i+1}/{len(cups_to_send)}")
                    print(f"[STATUS] {remaining} cups remaining")
                    
                    # Send cup
                    success = self.robot.send_cup(cup)
                    
                    if success:
                        self.total_cups_sent += 1
                        print(f"[STATUS] ✓ Cup {i+1} completed")
                    else:
                        print(f"[STATUS] ✗ Failed to send cup {i+1}")
                        # Don't break - keep trying
                
                # Wait before checking for new cups
                print("\n[STATUS] Waiting for new cups...")
                time.sleep(1.0)
            
        except Exception as e:
            print(f"[ROBOT] ✗ Thread error: {e}")
        
        finally:
            self.robot.end_session()
            self.robot.disconnect()
            self.robot_busy = False

    def start_robot_session(self):
        """Start robot session in background thread - ONLY ONCE"""
        if self.robot_busy or self.robot.is_connected():
            return
        
        if len(self.cups) == 0:
            return
        
        print(f"\n[ROBOT] Starting continuous session...")
        
        self.robot_busy = True
        self.robot_thread = threading.Thread(target=self.robot_communication_thread, daemon=True)
        self.robot_thread.start()

    def run(self):
        """Main detection loop - NEVER BLOCKS"""
        try:
            last_connection_attempt = 0

            while True:
                # Get frames (always runs - never freezes)
                rgb_frame, depth_frame = self.camera.get_frames()

                if rgb_frame is None:
                    continue

                # Detect
                detections = self.detector.detect(rgb_frame, depth_frame)

                # Update internal storage
                self.update_detections(detections, rgb_frame)

                # Try connect if not busy and cups detected (every 5 seconds)
                current_time = time.time()
                if not self.robot_busy and not self.robot.is_connected() and len(self.cups) > 0:
                    if current_time - last_connection_attempt > 5.0:
                        self.start_robot_session()
                        last_connection_attempt = current_time

                # Visualize
                display_frame = self.visualizer.draw_detections(
                    rgb_frame,
                    depth_frame,
                    detections
                )

                # Add status overlay
                self._draw_status_overlay(display_frame)

                # Show frame (ALWAYS updates)
                cv2.imshow("Cup Detection - AUTOMATIC (Actual RAPID)", display_frame)

                # Handle keys
                key = cv2.waitKey(1) & 0xFF

                if key == ord('q'):
                    print("\n[EXIT] Shutting down...")
                    break
                elif key == ord('s'):
                    self.save_frame(display_frame)
                elif key == ord('p'):
                    self.print_detections()

        except KeyboardInterrupt:
            print("\n[EXIT] Interrupted by user")
        except Exception as e:
            print(f"\n[ERROR] {str(e)}")
            import traceback
            traceback.print_exc()
        finally:
            # Cleanup
            self.robot_busy = False
            if self.robot_thread and self.robot_thread.is_alive():
                self.robot_thread.join(timeout=2.0)
            if self.robot.is_connected():
                self.robot.end_session()
                self.robot.disconnect()
            self.camera.close()
            cv2.destroyAllWindows()
            print("[CLEANUP] Done")
            print("=" * 60)

    def _draw_status_overlay(self, frame):
        """Draw status on frame"""
        h, w = frame.shape[:2]
        
        # Status box
        y = 50
        cv2.rectangle(frame, (10, y), (400, y + 100), (0, 0, 0), -1)
        cv2.rectangle(frame, (10, y), (400, y + 100), (0, 255, 0), 2)
        
        # Status text
        status_lines = [
            f"CUPS DETECTED: {len(self.cups)}",
            f"CUPS SENT: {self.total_cups_sent}",
            f"ROBOT: {'BUSY' if self.robot_busy else 'CONNECTED' if self.robot.is_connected() else 'DISCONNECTED'}"
        ]
        
        y_offset = y + 25
        for line in status_lines:
            cv2.putText(frame, line, (20, y_offset),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
            y_offset += 30


def main():
    system = CupDetectionSystem()
    system.run()


if __name__ == "__main__":
    main()