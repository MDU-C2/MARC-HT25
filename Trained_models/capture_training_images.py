#!/usr/bin/env python3
"""
Training Image Capture Tool
Captures images for YOLO model retraining
100 images per class × 6 classes = 600 total images
"""

import cv2
import sys
from pathlib import Path
from datetime import datetime

# Add src to path
sys.path.append(str(Path(__file__).parent / "src"))

from src.camera_manager import OAKDCamera


class TrainingCapturetool:
    def __init__(self):
        """Initialize capture tool"""
        
        # Define classes
        self.classes = [
            'Upright',
            'Down',
            'Left',
            'Right',
            'Back',
            'Front',
        ]
        
        self.images_per_class = 10
        self.current_class_index = 0
        self.base_dir = Path('training_images')
        
        # Create directories
        self.base_dir.mkdir(exist_ok=True)
        for class_name in self.classes:
            (self.base_dir / class_name).mkdir(exist_ok=True)
        
        # Count existing images
        self.counts = {}
        for class_name in self.classes:
            existing = list((self.base_dir / class_name).glob('*.jpg'))
            self.counts[class_name] = len(existing)
        
        # Initialize camera
        print("=" * 70)
        print("TRAINING IMAGE CAPTURE TOOL")
        print("=" * 70)
        print("\nInitializing camera...")
        self.camera = OAKDCamera(rgb_resolution="1080p", fps=30, depth_enabled=False)
        
        print("\n✓ Ready to capture!")
        self._print_instructions()
    
    def _print_instructions(self):
        """Print usage instructions"""
        print("\n" + "=" * 70)
        print("CONTROLS:")
        print("=" * 70)
        print("  SPACE   - Capture image")
        print("  n       - Next class")
        print("  p       - Previous class")
        print("  1-9     - Jump to class (1=upright, 2=upside_down...)")
        print("  q       - Quit")
        print("\n" + "=" * 70)
        print(f"TARGET: {self.images_per_class} images per class")
        print(f"TOTAL CLASSES: {len(self.classes)}")
        print("=" * 70 + "\n")
    
    def get_current_class(self):
        """Get current class name"""
        return self.classes[self.current_class_index]
    
    def get_current_count(self):
        """Get count for current class"""
        return self.counts[self.get_current_class()]
    
    def get_progress(self):
        """Get overall progress"""
        total_captured = sum(self.counts.values())
        total_target = len(self.classes) * self.images_per_class
        return total_captured, total_target
    
    def capture_image(self, rgb_frame):
        """Capture and save current frame"""
        class_name = self.get_current_class()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        filename = f"{class_name}_{timestamp}.jpg"
        filepath = self.base_dir / class_name / filename
        
        # Save image
        cv2.imwrite(str(filepath), rgb_frame)
        
        # Update count
        self.counts[class_name] += 1
        
        current_count = self.counts[class_name]
        print(f"✓ Captured: {class_name} ({current_count}/{self.images_per_class})")
        
        # Check if class is complete
        if current_count >= self.images_per_class:
            print(f"  ✓✓✓ {class_name.upper()} COMPLETE! ✓✓✓")
            
            # Auto-advance to next incomplete class
            self._advance_to_next_incomplete()
    
    def _advance_to_next_incomplete(self):
        """Move to next class that needs images"""
        for i in range(len(self.classes)):
            next_index = (self.current_class_index + 1 + i) % len(self.classes)
            next_class = self.classes[next_index]
            if self.counts[next_class] < self.images_per_class:
                self.current_class_index = next_index
                print(f"\n→ Moved to: {self.get_current_class()}")
                return
        
        # All complete
        print("\n" + "=" * 70)
        print("🎉 ALL CLASSES COMPLETE! 🎉")
        print("=" * 70)
    
    def next_class(self):
        """Move to next class"""
        self.current_class_index = (self.current_class_index + 1) % len(self.classes)
        print(f"\n→ Current class: {self.get_current_class()}")
    
    def prev_class(self):
        """Move to previous class"""
        self.current_class_index = (self.current_class_index - 1) % len(self.classes)
        print(f"\n→ Current class: {self.get_current_class()}")
    
    def jump_to_class(self, index):
        """Jump to specific class by index"""
        if 0 <= index < len(self.classes):
            self.current_class_index = index
            print(f"\n→ Jumped to: {self.get_current_class()}")
    
    def draw_overlay(self, frame):
        """Draw info overlay on frame"""
        h, w = frame.shape[:2]
        
        # Top panel - dark background
        panel_h = 180
        overlay = frame.copy()
        cv2.rectangle(overlay, (0, 0), (w, panel_h), (0, 0, 0), -1)
        cv2.addWeighted(overlay, 0.7, frame, 0.3, 0, frame)
        
        # Current class
        class_name = self.get_current_class()
        current_count = self.get_current_count()
        
        # Title
        cv2.putText(frame, "TRAINING IMAGE CAPTURE", (20, 35),
                   cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)
        
        # Current class (BIG)
        class_text = f"CLASS: {class_name.upper()}"
        cv2.putText(frame, class_text, (20, 80),
                   cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
        
        # Progress for current class
        progress_text = f"Progress: {current_count}/{self.images_per_class}"
        color = (0, 255, 0) if current_count >= self.images_per_class else (0, 165, 255)
        cv2.putText(frame, progress_text, (20, 120),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)
        
        # Overall progress
        total_captured, total_target = self.get_progress()
        overall_text = f"Overall: {total_captured}/{total_target} images"
        cv2.putText(frame, overall_text, (20, 150),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
        
        # Controls reminder (bottom)
        controls = "SPACE=Capture | N=Next | P=Prev | Q=Quit"
        cv2.putText(frame, controls, (20, h - 20),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 1)
        
        # Progress bar
        bar_x = 20
        bar_y = panel_h - 20
        bar_w = w - 40
        bar_h = 15
        
        # Background
        cv2.rectangle(frame, (bar_x, bar_y), (bar_x + bar_w, bar_y + bar_h), (50, 50, 50), -1)
        
        # Fill
        if self.images_per_class > 0:
            fill_w = int((current_count / self.images_per_class) * bar_w)
            fill_color = (0, 255, 0) if current_count >= self.images_per_class else (0, 165, 255)
            cv2.rectangle(frame, (bar_x, bar_y), (bar_x + fill_w, bar_y + bar_h), fill_color, -1)
        
        # Border
        cv2.rectangle(frame, (bar_x, bar_y), (bar_x + bar_w, bar_y + bar_h), (255, 255, 255), 2)
        
        return frame
    
    def run(self):
        """Main capture loop"""
        try:
            print(f"\nStarting with class: {self.get_current_class()}\n")
            
            while True:
                # Get frame
                rgb_frame, _ = self.camera.get_frames()
                
                if rgb_frame is None:
                    continue
                
                # Draw overlay
                display_frame = self.draw_overlay(rgb_frame.copy())
                
                # Show
                cv2.imshow("Training Capture Tool", display_frame)
                
                # Handle keys
                key = cv2.waitKey(1) & 0xFF
                
                if key == ord(' '):
                    # Capture
                    self.capture_image(rgb_frame)
                
                elif key == ord('n'):
                    # Next class
                    self.next_class()
                
                elif key == ord('p'):
                    # Previous class
                    self.prev_class()
                
                elif key == ord('q'):
                    # Quit
                    print("\n\nExiting...")
                    self._print_summary()
                    break
                
                elif ord('1') <= key <= ord('9'):
                    # Jump to class
                    class_index = key - ord('1')
                    self.jump_to_class(class_index)
            
        except KeyboardInterrupt:
            print("\n\nInterrupted by user")
            self._print_summary()
        
        finally:
            self.camera.close()
            cv2.destroyAllWindows()
    
    def _print_summary(self):
        """Print capture summary"""
        print("\n" + "=" * 70)
        print("CAPTURE SUMMARY")
        print("=" * 70)
        
        for class_name in self.classes:
            count = self.counts[class_name]
            status = "✓ COMPLETE" if count >= self.images_per_class else f"  {count}/{self.images_per_class}"
            print(f"{class_name:20s}: {status}")
        
        total_captured, total_target = self.get_progress()
        print("=" * 70)
        print(f"TOTAL: {total_captured}/{total_target} images")
        print("=" * 70)

# Line 280 should be:
def main():
    tool = TrainingCapturetool()  
    tool.run()


if __name__ == "__main__":
    main()