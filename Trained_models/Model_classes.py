
from ultralytics import YOLO
model = YOLO('Outside.pt')
print("\nYour model's classes:")
for idx, name in model.names.items():
    print(f"  {idx}: {name}")
