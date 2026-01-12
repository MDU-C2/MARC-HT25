# Cup Orientation Detection Models

**Mahmoud Ayoub** | Autonomous Dishwasher Robot | Mälardalen University

---

## Overview

Three YOLO models for cup orientation detection and gripper tracking, enabling ABB YuMi robot to identify and grasp cups in various positions.

**Deployment:**
- **On-Camera**: YOLOv5 Small on OAK-D Pro
- **External PC**: YOLOv8 Medium for higher accuracy

---

## Models

| Model           | Architecture | Images | Precision | mAP@50 | Use Case              |
| --------------- | ------------ | ------ | --------- | ------ | --------------------- |
| best_medium.pt  | YOLOv8m      | 4,856  | 97.3%     | 98.6%  | External PC (all env) |
| best_small.pt   | YOLOv5s      | 2,221  | 95.7%     | 98.3%  | On-camera             |
| gripper_nano.pt | YOLOv8n      | 668    | 99.9%     | 99.0%  | Calibration           |

---

## Classes

**best_medium.pt (8):** back, front, left_side, right_side, upright, upside_down, gripper, handle*  
**best_small.pt (7):** back, front, left_side, right_side, upright, upside_down, gripper  
**gripper_nano.pt (1):** gripper

*handle trained but not used in final system

---

## Training

**Config:** 100 epochs (medium/gripper), 100 epochs (small) | Batch 16 | 640×640 | Google Colab (Tesla T4)

**Augmentation:** Brightness/Exposure/Saturation variation, Blur, Noise. No horizontal flip for cups (preserves orientation).

---

## Usage

### External PC
```python
from cup_detector import CupDetector

detector = CupDetector(
    model_path='best_medium.pt',
    confidence_threshold=0.30
)
results = detector.detect(frame)
```

### Gripper Detection
```python
from gripper_detector import GripperDetector

gripper = GripperDetector(
    model_path='gripper_nano.pt',
    confidence_threshold=0.5
)
gripper_pos = gripper.detect(frame)
```

---

## Retraining

1. **Collect:** `python capture_training_images.py` (all 6 orientations, diverse conditions)
2. **Annotate:** Upload to Roboflow, label, export YOLOv8/v5 format
3. **Train:** Google Colab with appropriate YOLO version
4. **Deploy:** Update model paths, test with hardware

---

## Key Design

- **Medium on PC:** High accuracy across diverse conditions
- **Small on Camera:** Fits RVC2 memory (358 MiB), real-time performance
- **Separate Gripper:** Specialized model for 99.9% accuracy, easy retraining

---

## Repository

```
├── best_medium/         # External PC model
├── best_small/          # On-camera model
├── gripper_nano/        # Gripper detection
├── Experiment_area/     # Testing models in Experiment_area
├── presentation_area/   # Testing models in Presentation area
└── capture_training_images.py
```

---

## Resources

- [YOLOv8 Docs](https://docs.ultralytics.com/)
- [YOLOv5 Repo](https://github.com/ultralytics/yolov5)
- [DepthAI](https://docs.luxonis.com/)
- [Project GitHub](https://github.com/MDU-C2/MARC-HT25)

---

## Contact

**Mahmoud Ayoub** | mab19001@student.mdu.se  
**Course:** DVA490/DVA474 | **Institution:** Mälardalen University |

---

**Last Updated:** January 2026