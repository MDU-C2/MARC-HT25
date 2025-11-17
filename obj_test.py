
import cv2
from ultralytics import YOLO

# Load a small, fast YOLO model (COCO-pretrained)
# yolov8n, yolov8s, yolov8m, yolov8l, yolov8x 
model = YOLO("yolov8n.pt")

# Figure out the class IDs for the names we care about (mainly 'cup')
all_names = list(model.names.values())

wanted_names = all_names  # list ["cup", "person", "etc..."]
name_to_id = {name: idx for idx, name in model.names.items()}
wanted_ids = [name_to_id[n] for n in wanted_names if n in name_to_id]

# Open default webcam (try 1 or 2 if you have multiple cameras)
cap = cv2.VideoCapture(1)

if not cap.isOpened():
    raise RuntimeError("Could not open webcam.")

# Optional: set a smaller resolution for speed
cap.set(cv2.CAP_PROP_FRAME_WIDTH,  640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

print("Press 'q' to quit.")
while True:
    ok, frame = cap.read()
    if not ok:
        break

    # Inference on the current frame
    # - conf controls confidence threshold
    # - classes filters to just the IDs we want (e.g., cup)
    results = model(
        frame,
        conf=0.4,           # tweak 0.25–0.6 as needed
        classes=wanted_ids  # comment this line to see all classes
    )

    # Draw YOLO's nicely formatted annotations
    annotated = results[0].plot()

    # Show the frame
    cv2.imshow("YOLO – cups/mugs", annotated)

    # Quit on 'q'
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
