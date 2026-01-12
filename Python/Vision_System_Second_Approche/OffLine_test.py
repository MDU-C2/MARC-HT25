"""
Test YOLO model on images in test_images/subfolder
Put your test images in: test_images/Set1/
Press any key to see next image, 'q' to quit
"""

import cv2
from pathlib import Path
from ultralytics import YOLO

# ========== SETTINGS ==========
MODEL_PATH = 'Both_Meduim.pt'
SUBFOLDER = 'Set5'  # Change this for different sets
CONFIDENCE = 0.2
# ==============================

def main():
    # Load model
    print(f"Loading model: {MODEL_PATH}")
    model = YOLO(MODEL_PATH)
    
    # Get images from subfolder
    test_path = Path('test_images') / SUBFOLDER
    images = list(test_path.glob('*.jpg')) + list(test_path.glob('*.png'))
    
    if len(images) == 0:
        print(f"✗ No images found in test_images/{SUBFOLDER}/")
        return
    
    print(f"✓ Found {len(images)} images in {SUBFOLDER}\n")
    
    # Process each image
    for i, img_path in enumerate(images, 1):
        print(f"[{i}/{len(images)}] {img_path.name}")
        
        # Load image
        img = cv2.imread(str(img_path))
        
        # Detect
        results = model(img, conf=CONFIDENCE, verbose=False)
        
        # Draw
        annotated = results[0].plot()
        
        # Show
        cv2.imshow(f"Test [{SUBFOLDER}] - {img_path.name}", annotated)
        
        # Wait for key
        key = cv2.waitKey(0) & 0xFF
        cv2.destroyAllWindows()
        
        if key == ord('q'):
            print("\nStopped by user")
            break
    
    print("\n✓ Done!")

if __name__ == "__main__":
    main()