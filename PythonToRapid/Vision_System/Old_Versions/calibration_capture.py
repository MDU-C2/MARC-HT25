#!/usr/bin/env python3
"""
ALL-IN-ONE Calibration Tool
1. Captures screen coordinates interactively
2. Updates calibration_input.json
3. Runs calibration calculations
4. Generates calibration_params.json
"""

import cv2
import json
import sys
import numpy as np
from pathlib import Path
from sklearn.linear_model import LinearRegression

# Add src to path
sys.path.append(str(Path(__file__).parent / "src"))

from camera_manager import OAKDCamera
from cup_detector import CupDetector


class AllInOneCalibrationTool:
    def __init__(self):
        """Initialize all-in-one calibration tool"""
        print("=" * 70)
        print("ALL-IN-ONE CALIBRATION TOOL")
        print("=" * 70)
        
        # Load existing calibration input (for robot coordinates)
        self.load_template()
        
        # Initialize camera
        print("\n[1/2] Initializing camera...")
        self.camera = OAKDCamera()
        
        # Initialize detector
        print("[2/2] Loading detector...")
        self.detector = CupDetector(
            model_path='best.pt',
            confidence_threshold=0.6
        )
        
        print("\n✓ Ready to capture!")
        print("\nInstructions:")
        print("  1. Place object at specified position")
        print("  2. Wait for detection (green box)")
        print("  3. Press 'c' to capture")
        print("  4. Press 'q' to quit (saves progress)")
        print("-" * 70)
        
        # Capture state
        self.current_step = 0
        self.captured_data = []

    def load_template(self):
        """Load existing calibration template with robot coordinates"""
        template_file = Path('calibration_input.json')
        
        if not template_file.exists():
            print("\n✗ ERROR: calibration_input.json not found!")
            print("Cannot proceed without template with robot coordinates.")
            sys.exit(1)
        
        with open(template_file, 'r') as f:
            self.template = json.load(f)
        
        # Build capture sequence
        self.sequence = []
        
        # Robot base first
        if 'robot_origin' in self.template:
            self.sequence.append({
                'type': 'robot_base',
                'name': self.template['robot_origin']['name'],
                'robot': self.template['robot_origin']['robot'],
                'description': self.template['robot_origin']['description'],
                'detect_class': 'robot_base'
            })
        
        # Then cups
        for cup in self.template['cups']:
            self.sequence.append({
                'type': 'cup',
                'name': cup['name'],
                'zone': cup['zone'],
                'robot': cup['robot'],
                'description': cup['description'],
                'detect_class': 'cup'
            })
        
        print(f"\n✓ Loaded template with {len(self.sequence)} objects to capture")

    def get_current_instruction(self):
        """Get instruction for current step"""
        if self.current_step >= len(self.sequence):
            return "ALL CAPTURED - Press 'q' to finish"
        
        item = self.sequence[self.current_step]
        step_num = self.current_step + 1
        total = len(self.sequence)
        
        instruction = f"[{step_num}/{total}] Place: {item['name']}"
        return instruction

    def detect_current_object(self, rgb_frame, depth_frame):
        """Detect the object we're looking for in current step"""
        if self.current_step >= len(self.sequence):
            return None
        
        target_class = self.sequence[self.current_step]['detect_class']
        
        # Detect all objects
        detections = self.detector.detect(rgb_frame, depth_frame)
        
        # Filter for target class
        matches = [d for d in detections if d['class'] == target_class]
        
        if len(matches) == 0:
            return None
        
        # Return best match (highest confidence)
        best = max(matches, key=lambda x: x['confidence'])
        return best

    def capture_screen_coordinates(self, detection):
        """Capture screen coordinates from detection"""
        cx, cy = detection['center']
        depth = detection['depth']
        
        screen = [float(cx), float(cy), float(depth)]
        
        # Get current item
        item = self.sequence[self.current_step]
        
        # Build captured data
        captured = {
            'name': item['name'],
            'robot': item['robot'],
            'screen': screen
        }
        
        # Add zone if cup
        if item['type'] == 'cup':
            captured['zone'] = item['zone']
            captured['description'] = item['description']
        elif item['type'] == 'robot_base':
            captured['description'] = item['description']
        
        return captured

    def save_calibration_input(self):
        """Save updated calibration_input.json"""
        # Separate robot_origin and cups
        robot_origin = None
        cups = []
        
        for item in self.captured_data:
            if 'zone' in item:
                # It's a cup
                cups.append(item)
            else:
                # It's robot base
                robot_origin = item
        
        # Build output
        output = {}
        
        if robot_origin:
            output['robot_origin'] = robot_origin
        
        output['cups'] = cups
        
        # Save
        with open('calibration_input.json', 'w') as f:
            json.dump(output, f, indent=4)
        
        print(f"\n✓ Saved calibration_input.json with {len(self.captured_data)} objects")

    def run_calibration_math(self):
        """Run calibration calculations (from calibrate.py logic)"""
        print("\n" + "=" * 70)
        print("RUNNING CALIBRATION CALCULATIONS")
        print("=" * 70)
        
        # Load the just-saved calibration input
        with open('calibration_input.json', 'r') as f:
            input_data = json.load(f)
        
        cups_data = input_data['cups']
        print(f"\n✓ Loaded {len(cups_data)} calibration cups")
        
        # Calculate global transformation
        print("\nCalculating global transformation...")
        global_params = self._calculate_global_transformation(cups_data)
        
        # Calculate zone-based transformations
        print("\nCalculating zone-based transformations...")
        zone_params = self._calculate_transformation_per_zone(cups_data)
        
        # Calculate zone boundaries
        print("\nCalculating zone boundaries...")
        boundaries = self._calculate_zone_boundaries(cups_data)
        
        # Build calibration output
        calibration = {
            'method': 'pixel_based_multizone_regression',
            'zones': zone_params,
            'zone_boundaries': boundaries,
            'global_fallback': global_params,
            'num_calibration_points': len(cups_data),
            'calibration_date': str(np.datetime64('today'))
        }
        
        # Save
        with open('calibration_params.json', 'w') as f:
            json.dump(calibration, f, indent=4)
        
        print("\n" + "=" * 70)
        print("✓ Calibration saved to calibration_params.json")
        print("=" * 70)
        print("\n✓ COMPLETE! You can now run main.py")

    def _calculate_global_transformation(self, cups_data):
        """Calculate global transformation as fallback"""
        screen_coords = np.array([c['screen'] for c in cups_data])
        robot_coords = np.array([c['robot'] for c in cups_data])

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

        # Calculate errors
        pred_x = model_x.predict(screen_coords)
        pred_y = model_y.predict(screen_coords)

        errors = []
        for i in range(len(cups_data)):
            err_x = pred_x[i] - robot_coords[i, 0]
            err_y = pred_y[i] - robot_coords[i, 1]
            err = np.sqrt(err_x ** 2 + err_y ** 2)
            errors.append(err)

        print(f"  Global avg error: {np.mean(errors):.1f}mm")

        return global_params

    def _calculate_transformation_per_zone(self, cups_data):
        """Calculate separate transformation for each zone"""
        # Group by zone
        zones = {}
        for cup in cups_data:
            zone = cup['zone']
            if zone not in zones:
                zones[zone] = []
            zones[zone].append(cup)

        zone_params = {}

        for zone_name, zone_cups in zones.items():
            print(f"  Zone: {zone_name} ({len(zone_cups)} cups)")

            # Extract data
            screen_coords = np.array([c['screen'] for c in zone_cups])
            robot_coords = np.array([c['robot'] for c in zone_cups])

            # Build regression model
            model_x = LinearRegression()
            model_y = LinearRegression()

            model_x.fit(screen_coords, robot_coords[:, 0])
            model_y.fit(screen_coords, robot_coords[:, 1])

            # Calculate average Z
            avg_z = np.mean(robot_coords[:, 2])

            # Store parameters
            zone_params[zone_name] = {
                'coef_x': model_x.coef_.tolist(),
                'intercept_x': float(model_x.intercept_),
                'coef_y': model_y.coef_.tolist(),
                'intercept_y': float(model_y.intercept_),
                'robot_z': float(avg_z)
            }

            # Verify accuracy
            pred_x = model_x.predict(screen_coords)
            pred_y = model_y.predict(screen_coords)

            errors = []
            for i in range(len(zone_cups)):
                err_x = pred_x[i] - robot_coords[i, 0]
                err_y = pred_y[i] - robot_coords[i, 1]
                err = np.sqrt(err_x ** 2 + err_y ** 2)
                errors.append(err)

            print(f"    Avg error: {np.mean(errors):.1f}mm")

        return zone_params

    def _calculate_zone_boundaries(self, cups_data):
        """Calculate zone boundaries from calibration data"""
        # Group cups by zone
        zones = {}
        for cup in cups_data:
            zone = cup['zone']
            if zone not in zones:
                zones[zone] = []
            zones[zone].append(cup['screen'])

        # Calculate boundaries
        boundaries = {}
        for zone_name, positions in zones.items():
            xs = [p[0] for p in positions]
            ys = [p[1] for p in positions]

            boundaries[zone_name] = {
                'x_min': min(xs) - 50,
                'x_max': max(xs) + 50,
                'y_min': min(ys) - 30,
                'y_max': max(ys) + 30,
                'center_x': np.mean(xs),
                'center_y': np.mean(ys)
            }

        return boundaries

    def run(self):
        """Main capture loop"""
        try:
            while True:
                # Get frames
                rgb_frame, depth_frame = self.camera.get_frames()
                
                if rgb_frame is None:
                    continue
                
                display_frame = rgb_frame.copy()
                
                # Detect current target
                detection = self.detect_current_object(rgb_frame, depth_frame)
                
                # Draw detection if found
                if detection:
                    bbox = detection['bbox']
                    x, y, w, h = bbox
                    cx, cy = detection['center']
                    
                    # Green box for detected object
                    cv2.rectangle(display_frame, (x, y), (x + w, y + h), (0, 255, 0), 3)
                    cv2.circle(display_frame, (cx, cy), 8, (0, 255, 0), -1)
                    
                    # Show detection info
                    info_text = f"DETECTED - Press 'c' to capture"
                    cv2.putText(display_frame, info_text, (x, y - 30),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                    
                    coord_text = f"Screen: [{cx}, {cy}, {detection['depth']}]"
                    cv2.putText(display_frame, coord_text, (x, y - 10),
                               cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
                
                # Draw instruction panel
                self._draw_instruction_panel(display_frame, detection is not None)
                
                # Show frame
                cv2.imshow("All-in-One Calibration Tool", display_frame)
                
                # Handle keys
                key = cv2.waitKey(1) & 0xFF
                
                if key == ord('c'):
                    if detection:
                        # Capture!
                        captured = self.capture_screen_coordinates(detection)
                        self.captured_data.append(captured)
                        
                        print(f"\n✓ Captured: {captured['name']}")
                        print(f"  Screen: {captured['screen']}")
                        print(f"  Robot: {captured['robot']}")
                        
                        self.current_step += 1
                        
                        # Check if done
                        if self.current_step >= len(self.sequence):
                            print("\n" + "=" * 70)
                            print("ALL OBJECTS CAPTURED!")
                            print("=" * 70)
                            
                            # Save input file
                            self.save_calibration_input()
                            
                            # Run calibration math
                            self.run_calibration_math()
                            
                            break
                    else:
                        print("\n✗ No object detected! Place object first.")
                
                elif key == ord('q'):
                    print("\n\nExiting...")
                    if len(self.captured_data) > 0:
                        print(f"Saving {len(self.captured_data)} captured objects...")
                        self.save_calibration_input()
                        print("Run this tool again to continue.")
                    break
        
        except KeyboardInterrupt:
            print("\n\nInterrupted by user")
        
        finally:
            self.camera.close()
            cv2.destroyAllWindows()

    def _draw_instruction_panel(self, frame, detected):
        """Draw instruction panel on frame"""
        h, w = frame.shape[:2]
        
        # Top panel
        panel_height = 120
        cv2.rectangle(frame, (0, 0), (w, panel_height), (40, 40, 40), -1)
        
        # Progress
        progress_text = f"Progress: {self.current_step}/{len(self.sequence)}"
        cv2.putText(frame, progress_text, (20, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        
        # Current instruction
        instruction = self.get_current_instruction()
        cv2.putText(frame, instruction, (20, 65),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 255), 2)
        
        # Status
        if self.current_step < len(self.sequence):
            if detected:
                status = "READY - Press 'c' to capture"
                color = (0, 255, 0)
            else:
                status = "Waiting for detection..."
                color = (0, 165, 255)
            
            cv2.putText(frame, status, (20, 100),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)


def main():
    tool = AllInOneCalibrationTool()
    tool.run()


if __name__ == "__main__":
    main()