import cv2
from pathlib import Path
from ultralytics import YOLO
import sys
from depthai_sdk import OakCamera

# Add src to path if needed
sys.path.append(str(Path(__file__).parent / "src"))
#from src.camera_manager import OAKDCamera

def main():
    # Load trained YOLO model
    model_path = r"best.pt"
    model = YOLO(model_path)

    # Initialize camera
    camera = OakCamera()

    print("Camera initialized. Press 'q' to quit.")

    try:
        while True:
            rgb_frame, _ = camera.get()
            # if rgb_frame is None:
            #     continue

            # Run YOLO inference
            results = model(rgb_frame, conf=0.25, verbose=False)

            # Draw detections
            for result in results:
                boxes = result.boxes
                for box in boxes:
                    cls_id = int(box.cls[0])
                    cls_name = result.names[cls_id]
                    confidence = float(box.conf[0])

                    # Get bounding box coordinates
                    x1, y1, x2, y2 = map(int, box.xyxy[0].cpu().numpy())
                    # Get cup orientation from model (should be in class name)
                    orientation = cls_name

                    # Draw rectangle
                    cv2.rectangle(rgb_frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                    # Draw label
                    label = f"{orientation} ({confidence:.2f})"
                    cv2.putText(rgb_frame, label, (x1, y1-10), cv2.FONT_HERSHEY_SIMPLEX,
                                0.6, (0, 255, 0), 2)

            # Show frame
            cv2.imshow("Cup Orientation Detection", rgb_frame)

            # Quit on 'q'
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

    finally:
        camera.close()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()