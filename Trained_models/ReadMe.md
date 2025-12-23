# Cup Orientation Detection Models

**Created by: Mahmoud Ayoub**  
**Project**: Autonomous Dishwasher Robot - Vision System  
**Institution**: Mälardalen University

---

## 📋 Overview

Four trained YOLOv8 models for detecting cups in various orientations and the robot gripper. Enables ABB YuMi robot to identify and grasp cups across different environmental conditions.

**Deployment Options:**
- **On-Camera**: Nano models on OAK-D Pro's Myriad X
- **External PC**: Medium model for higher accuracy

---

## 🎯 Models

### 1. **best_medium.pt** - Combined Environment
- **YOLOv8 Medium** | 4,856 images | ~12h training
- External PC | All environments

### 2. **gripper_nano.pt** - Gripper Detection
- **YOLOv8 Nano** | 668 images | ~2h training
- Calibration & tracking | Quick retrain

### 3. **best_nano_1.pt** - Inside
- **YOLOv8 Nano** | 1,300 images | ~6h training
- On-camera | Bright indoor lighting

### 4. **best_nano_2.pt** - Outside
- **YOLOv8 Nano** | 1,200 images | ~6h training
- On-camera | Darker/outdoor lighting

---

## 🏷️ Classes (7 Total)

**Cup Orientations (6):**
1. **Back** - Handle away
2. **Front** - Handle forward
3. **left_side** - Lying left
4. **right_side** - Lying right
5. **upright** - Standing
6. **upside_down** - Inverted

**Additional:**
7. **Gripper** - Robot gripper

---

## 📊 Training Config

| Parameter      | Value                   |
| -------------- | ----------------------- |
| **Epochs**     | 100                     |
| **Batch**      | 16                      |
| **Image Size** | 640×640                 |
| **Split**      | 70/20/10                |
| **Platform**   | Google Colab (Tesla T4) |

### Augmentation

| Type       | best_medium | gripper_nano | nano_1/2 |
| ---------- | ----------- | ------------ | -------- |
| Crop Zoom  | 0-23%       | -            | 0-10%    |
| Saturation | ±30%        | -            | ±15%     |
| Brightness | ±35%        | ±10%         | ±10%     |
| Exposure   | ±25%        | -            | ±10%     |
| Blur       | 2px         | -            | 2px      |
| Noise      | 2%          | 2%           | 1%       |
| H-Flip     | No*         | Yes          | No*      |

*Disabled for cups to preserve orientation

---

## 📈 Performance

- **Precision**: 98%
- **Real-world validated** on YuMi robot
- **Detects specific orientations** (not just "cup")
- **Environment-adapted models**

---

## 🗂️ Files

```
├── best_medium.pt
├── gripper_nano.pt
├── best_nano_1.pt
├── best_nano_2.pt
├── Cup_Orientation_Training_Colab.ipynb
├── capture_training_images.py
├── Model_classes.py
└── ReadMe.md
```

---

## 🔄 Model Selection

- **best_medium.pt** → External PC, all environments
- **gripper_nano.pt** → Calibration
- **best_nano_1.pt** → On-camera, bright inside
- **best_nano_2.pt** → On-camera, darker/outside

---

## 🔧 Integration

```python
# External PC
from cup_detector import CupDetector
detector = CupDetector(
    model_path='best_medium.pt',
    confidence_threshold=0.30
)

# Gripper
from gripper_detector import GripperDetector
gripper = GripperDetector(
    model_path='gripper_nano.pt',
    confidence_threshold=0.5
)
```

---

## 📝 Retraining

### 1. Capture Images
```bash
python capture_training_images.py
```
- All 6 orientations
- Diverse backgrounds & lighting
- 1,200+ images per model

### 2. Annotate (Roboflow)
- Upload images
- Draw bounding boxes
- Label orientations
- Export YOLOv8 format

### 3. Train (Google Colab)
```python
from ultralytics import YOLO
model = YOLO('yolov8n.pt')  # or yolov8m.pt
results = model.train(
    data='data.yaml',
    epochs=100,
    imgsz=640,
    batch=16
)
```

### 4. Deploy
```python
# Update model path
model_path='best_medium.pt'
```

---

## 💡 Tips

**Data Collection:**
- Multiple lighting conditions
- Various backgrounds
- Different angles
- Equal samples per class

**Common Issues:**
- Left/right confusion → Check labels
- Low confidence → Lower threshold
- Overfitting → More augmentation

---

## 📦 Versions

| Model           | Version | mAP@50 |
| --------------- | ------- | ------ |
| best_medium.pt  | v2.1    | 98%+   |
| gripper_nano.pt | v1.5    | 96%+   |
| best_nano_1.pt  | v2.0    | 88-90% |
| best_nano_2.pt  | v2.0    | 88-90% |

---

## 🔗 Related

**Vision:** `main.py`, `cup_detector.py`, `pose_estimator.py`  
**Calibration:** `auto_calibrate.py`, `gripper_detector.py`  
**Robot:** `PythonToRapid.py`, `MainProgram_Rapid.txt`

---

## 🐛 Troubleshooting

**Model won't load:**
```bash
pip install --upgrade ultralytics
```

**Poor accuracy:**
- Check lighting matches training
- Lower confidence threshold
- Add more similar data

**Deployment:**
- Nano only for on-camera
- Medium requires PC
- Check GPU availability

---

## 📚 Resources

- [YOLOv8 Docs](https://docs.ultralytics.com/)
- [DepthAI](https://docs.luxonis.com/)
- [Roboflow](https://roboflow.com/learn)
- [Colab](https://colab.research.google.com/)
- [GitHub](https://github.com/MDU-C2/MARC-HT25)

---

## 🎓 Academic

**Course**: DVA490/DVA474  
**University**: Mälardalen University  

---

## 📧 Contact

**Mahmoud Ayoub**  
mab19001@student.mdu.se

---

## 🙏 Acknowledgments

**Tools**: Ultralytics, Roboflow, Google Colab, DepthAI  
**Hardware**: OAK-D Pro, ABB YuMi, Tesla T4

---

**Last Updated**: December 23, 2025