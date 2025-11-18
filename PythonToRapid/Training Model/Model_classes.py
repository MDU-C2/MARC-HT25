# from ultralytics import YOLO

# model = YOLO('best_cup_orientation_New.pt')
# print("\nModel classes:")
# for idx, name in model.names.items():
#     print(f"  {idx}: {name}")
import cv2
from ultralytics import YOLO

# Load model
model = YOLO('best_cup_orientation_New.pt')

# Open laptop camera
cap = cv2.VideoCapture(0)

print("Press 'q' to quit")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Detect
    results = model(frame, conf=0.5)
    
    # Draw results
    annotated = results[0].plot()
    
    # Show
    cv2.imshow('Laptop Camera Test', annotated)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()