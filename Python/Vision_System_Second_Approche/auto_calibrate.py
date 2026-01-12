#!/usr/bin/env python3
"""
Automated Calibration - GRIPPER DETECTION
Uses gripper_detector.py with gripper_nano.pt model
Usage: python auto_calibrate.py
Enter number of points when prompted (e.g., 3, 5, 10, 12, 20,40)
"""

import cv2
import json
import sys
import time
import socket
import numpy as np
from pathlib import Path
from sklearn.linear_model import LinearRegression

# Import gripper detector instead of cup detector
from src.gripper_detector import GripperDetector
from src.camera_manager import OAKDCamera
from src.visualizer import Visualizer


class AutoCalibration:
    def __init__(self, host='127.0.0.1', port=1025):
        """Initialize calibration system"""
        print("=" * 70)
        print("AUTOMATED CALIBRATION SYSTEM - GRIPPER DETECTION")
        print("=" * 70)
        
        self.host = host
        self.port = port
        self.socket = None
        self.connected = False
        
        # Get number of calibration points from user
        while True:
            try:
                num_input = input("\nHow many calibration points? (3-40): ")
                self.num_points = int(num_input)
                if 3 <= self.num_points <= 40:
                    break
                print("Please enter a number between 3 and 40")
            except ValueError:
                print("Please enter a valid number")
        
        # Load positions
        print(f"\n[1/4] Loading {self.num_points} calibration positions...")
        self.load_positions()
        
        # Initialize camera - SAME AS MAIN.PY
        print("[2/4] Initializing camera...")
        self.camera = OAKDCamera()
        
        # Initialize GRIPPER detector with gripper_nano.pt
        print("[3/4] Loading gripper detector...")
        self.detector = GripperDetector(
            model_path='gripper_nano.pt',
            confidence_threshold=0.5  # Adjusted for gripper
        )
        
        # Initialize visualizer - SAME AS MAIN.PY
        print("[4/4] Setting up visualizer...")
        self.visualizer = Visualizer()
        
        self.captured_data = []
        
        print(f"\n✓ Ready!")
        print(f"   Calibration points: {len(self.positions)}")
        print(f"   Target: {self.host}:{self.port}")
        print(f"   Detection: GRIPPER using gripper_nano.pt")
        print("=" * 70)

    def load_positions(self):
        """Load positions from config"""
        with open('calibration_positions.json', 'r') as f:
            config = json.load(f)
        
        all_positions = config['positions']
        
        # Take first N positions
        self.positions = all_positions[:self.num_points]
        
        print(f"   Loaded {len(self.positions)} positions")

    # ==================== SOCKET COMMUNICATION ====================
    
    def connect(self):
        """Connect to RAPID"""
        try:
            print(f"\n[SOCKET] Connecting to {self.host}:{self.port}...")
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(30.0)
            self.socket.connect((self.host, self.port))
            self.connected = True
            print("[SOCKET] ✓ Connected")
            return True
        except Exception as e:
            print(f"[SOCKET] ✗ Connection failed: {e}")
            return False

    def disconnect(self):
        """Close socket"""
        if self.socket:
            try:
                self.socket.close()
                self.connected = False
                print("[SOCKET] ✓ Disconnected")
            except:
                pass

    def send_message(self, message):
        """Send message"""
        if not self.connected:
            return False
        
        try:
            self.socket.send(message.encode())
            print(f"[SOCKET] → {message}")
            time.sleep(0.1)
            return True
        except Exception as e:
            print(f"[SOCKET] ✗ Send error: {e}")
            self.connected = False
            return False

    def receive_message(self, timeout=30.0):
        """Receive message"""
        try:
            old_timeout = self.socket.gettimeout()
            self.socket.settimeout(timeout)
            
            message = self.socket.recv(1024).decode().strip()
            print(f"[SOCKET] ← {message}")
            
            self.socket.settimeout(old_timeout)
            time.sleep(0.1)
            
            return message
        except socket.timeout:
            print(f"[SOCKET] ✗ Timeout")
            return None
        except Exception as e:
            print(f"[SOCKET] ✗ Receive error: {e}")
            self.connected = False
            return None

    # ==================== GRIPPER DETECTION ====================
    
    def wait_for_gripper_detection(self, timeout=15.0):
        """
        Wait for gripper detection using gripper_nano.pt model
        """
        print("   [CAMERA] Waiting for gripper detection...")
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            # Get frames - same as main.py
            rgb_frame, depth_frame = self.camera.get_frames()
            
            if rgb_frame is None:
                continue
            
            # Detect gripper
            detections = self.detector.detect(rgb_frame, depth_frame)
            
            # Visualize
            display_frame = self.visualizer.draw_detections(
                rgb_frame,
                depth_frame,
                detections
            )
            
            # Show
            cv2.imshow("Calibration Camera - Gripper Detection", display_frame)
            
            # Check if gripper found
            if len(detections) > 0:
                best_gripper = self.detector.get_best_detection(detections)
                cx, cy = best_gripper['center']
                depth = best_gripper['depth']
                
                print(f"   [CAMERA] ✓ Gripper detected!")
                print(f"   [CAMERA] Confidence: {best_gripper['confidence']:.2f}")
                print(f"   [CAMERA] Screen coords: [{cx}, {cy}, {depth}mm]")
                
                # Show for a moment
                cv2.waitKey(500)
                return best_gripper
            
            # Key handling
            if cv2.waitKey(1) & 0xFF == ord('q'):
                return None
        
        print("   [CAMERA] ✗ Timeout - no gripper detected")
        return None

    # ==================== CALIBRATION SESSION ====================
    
    def run_calibration(self):
        """Main calibration loop"""
        print("\n" + "=" * 70)
        print("CALIBRATION SESSION - GRIPPER MODE")
        print("=" * 70)
        print("\nNOTE:")
        print("  - Robot will move gripper to each position")
        print("  - Camera will detect gripper automatically")  
        input("\nPress ENTER when ready to start...")
        
        try:
            # Connect
            if not self.connect():
                return False
            
            # Start calibration
            print("\n[CALIBRATION] Starting...")
            self.send_message("START_CALIB")
            
            response = self.receive_message()
            if response != "READY":
                print(f"[CALIBRATION] ✗ Unexpected response: {response}")
                return False
            
            print("[CALIBRATION] ✓ RAPID ready")
            
            # Process each position
            for i, position in enumerate(self.positions):
                print("\n" + "-" * 70)
                print(f"[Position {i+1}/{len(self.positions)}] {position['name']}")
                print(f"   Zone: {position['zone']}")
                print(f"   Robot coords: {position['robot']}")
                
                # Send move command
                x, y, z = position['robot']
                move_cmd = f"MOVE:[{x},{y},{z}]"
                
                self.send_message(move_cmd)
                
                # Wait for MOVING
                response = self.receive_message()
                if response != "MOVING":
                    print(f"   ✗ Expected MOVING, got: {response}")
                    continue
                
                print("   [ROBOT] Moving...")
                
                # Wait for AT_POSITION
                response = self.receive_message(timeout=60.0)
                if response != "AT_POSITION":
                    print(f"   ✗ Expected AT_POSITION, got: {response}")
                    continue
                
                print("   [ROBOT] ✓ Position reached")
                
                # Stability delay
                time.sleep(1.0)
                
                # Capture - detect GRIPPER
                detection = self.wait_for_gripper_detection()
                
                if detection is None:
                    print("   ✗ Failed to detect gripper - SKIPPING")
                    continue
                
                # Save data
                cx, cy = detection['center']
                depth = detection['depth']
                
                calib_point = {
                    'name': position['name'],
                    'zone': position['zone'],
                    'robot': position['robot'],
                    'screen': [float(cx), float(cy), float(depth)],
                    'description': f"Gripper detection - conf: {detection['confidence']:.2f}"
                }
                
                self.captured_data.append(calib_point)
                
                print(f"   ✓ Captured ({len(self.captured_data)}/{len(self.positions)})")
                print(f"   Camera: [{cx}, {cy}, {depth}mm]")
                print(f"   Robot:  {position['robot']}")
            
            # End calibration safely
            print("\n" + "-" * 70)
            print("[CALIBRATION] Ending session...")
            self.send_message("END_CALIB")
            
            response = self.receive_message(timeout=5.0)
            if response == "DONE":
                print("[CALIBRATION] ✓ Session ended cleanly")
                time.sleep(1.0)
            
            print(f"\n✓ Captured {len(self.captured_data)}/{len(self.positions)} positions")
            return True
            
        except KeyboardInterrupt:
            print("\n\n[CALIBRATION] Interrupted by user")
            # Try to end gracefully
            if self.connected:
                try:
                    self.send_message("END_CALIB")
                    self.receive_message(timeout=2.0)
                except:
                    pass
            return False
        
        except Exception as e:
            print(f"\n✗ ERROR: {e}")
            import traceback
            traceback.print_exc()
            return False
        
        finally:
            # Always disconnect cleanly
            if self.connected:
                try:
                    print("[SOCKET] Closing connection...")
                    self.disconnect()
                except:
                    pass

    # ==================== SAVE & CALCULATE ====================
    
    def save_and_calculate(self):
        """Save and calculate calibration"""
        if len(self.captured_data) < 3:
            print(f"\n✗ Not enough data (need at least 3, got {len(self.captured_data)})")
            return False
        
        print("\n" + "=" * 70)
        print("SAVING CALIBRATION DATA")
        print("=" * 70)
        
        # Print summary
        print(f"\nCaptured {len(self.captured_data)} calibration points:")
        for i, point in enumerate(self.captured_data):
            print(f"  {i+1}. {point['name']}")
            print(f"     Robot:  {point['robot']}")
            print(f"     Camera: {point['screen']}")
        
        # Save input
        robot_origin = {
            'name': 'Robot Base',
            'robot': [0, 0, 0],
            'screen': [973.0, 177.0, 1055.0],
            'description': 'Robot origin'
        }
        
        output = {
            'robot_origin': robot_origin,
            'cups': self.captured_data
        }
        
        with open('calibration_input.json', 'w') as f:
            json.dump(output, f, indent=4)
        
        print(f"\n✓ Saved calibration_input.json")
        
        # Calculate parameters
        print("\n[CALCULATION] Computing calibration parameters...")
        
        cups_data = self.captured_data
        screen_coords = np.array([c['screen'] for c in cups_data])
        robot_coords = np.array([c['robot'] for c in cups_data])
        
        # Global model
        model_x = LinearRegression()
        model_y = LinearRegression()
        model_x.fit(screen_coords, robot_coords[:, 0])
        model_y.fit(screen_coords, robot_coords[:, 1])
        
        global_params = {
            'coef_x': model_x.coef_.tolist(),
            'intercept_x': float(model_x.intercept_),
            'coef_y': model_y.coef_.tolist(),
            'intercept_y': float(model_y.intercept_),
            'robot_z': float(np.mean(robot_coords[:, 2]))
        }
        
        # Zone models
        zones = {}
        for cup in cups_data:
            zone = cup['zone']
            if zone not in zones:
                zones[zone] = []
            zones[zone].append(cup)
        
        zone_params = {}
        boundaries = {}
        
        for zone_name, zone_cups in zones.items():
            if len(zone_cups) < 1:
                continue
            
            screen_z = np.array([c['screen'] for c in zone_cups])
            robot_z = np.array([c['robot'] for c in zone_cups])
            
            if len(zone_cups) >= 2:
                mx = LinearRegression()
                my = LinearRegression()
                mx.fit(screen_z, robot_z[:, 0])
                my.fit(screen_z, robot_z[:, 1])
                
                zone_params[zone_name] = {
                    'coef_x': mx.coef_.tolist(),
                    'intercept_x': float(mx.intercept_),
                    'coef_y': my.coef_.tolist(),
                    'intercept_y': float(my.intercept_),
                    'robot_z': float(np.mean(robot_z[:, 2]))
                }
            else:
                zone_params[zone_name] = global_params
            
            xs = [p['screen'][0] for p in zone_cups]
            ys = [p['screen'][1] for p in zone_cups]
            
            boundaries[zone_name] = {
                'x_min': min(xs) - 50,
                'x_max': max(xs) + 50,
                'y_min': min(ys) - 30,
                'y_max': max(ys) + 30,
                'center_x': np.mean(xs),
                'center_y': np.mean(ys)
            }
            
            print(f"  Zone {zone_name}: {len(zone_cups)} point(s)")
        
        # Save params
        calibration = {
            'method': 'pixel_based_multizone_regression',
            'zones': zone_params,
            'zone_boundaries': boundaries,
            'global_fallback': global_params,
            'num_calibration_points': len(cups_data),
            'calibration_date': str(np.datetime64('today'))
        }
        
        with open('calibration_params.json', 'w') as f:
            json.dump(calibration, f, indent=4)
        
        print("\n✓ Saved calibration_params.json")
        print("=" * 70)
        
        return True

    def run(self):
        """Main execution"""
        try:
            # Run calibration
            success = self.run_calibration()
            
            if not success:
                print("\n✗ Calibration session failed")
                return
            
            # Save and calculate
            if self.save_and_calculate():
                print("\n" + "=" * 70)
                print("✓✓✓ CALIBRATION COMPLETE! ✓✓✓")
                print("=" * 70)
                print("\nYou can now run: python main.py")
            
        finally:
            # Always cleanup
            self.camera.close()
            cv2.destroyAllWindows()
            
            # Always disconnect cleanly
            if self.connected:
                try:
                    print("[SOCKET] Closing connection...")
                    time.sleep(1.0)
                    self.disconnect()
                except:
                    pass


def main():
    calibration = AutoCalibration()
    calibration.run()


if __name__ == "__main__":
    main()