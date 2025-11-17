# PythonToRapid - Robotic Dishwasher System

**Created by: Mahmoud Ayoub**

---

## 📋 Project Overview

This part of the project focuses on the Vision System and PythonToRapid Communication for the robotic dishwasher system. It handles real-time cup detection using computer vision and manages communication with the YuMi robot controller.

**Key Features:**
- Real-time cup detection using YOLO (99.48% mAP@50)
- 6DOF pose estimation with pixel-based calibration
- Automated robot communication via custom protocol
- Support for 6 cup orientations plus gripper detection

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    PythonToRapid System                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
        ▼                                           ▼
┌───────────────────┐                    ┌──────────────────┐
│  Vision System    │◄──────────────────►│   RAPID Server   │
│    (Python)       │   Socket Protocol  │  (ABB YuMi Robot)│
└───────────────────┘                    └──────────────────┘
        ▲                                           ▲
        │                                           │
        │                                           │
        ▼                                           ▼
┌───────────────────┐                    ┌──────────────────┐
│  OAK-D Pro Camera │                    │  Robot Hardware  │
│  + YOLO Detection │                    │   + RobotStudio  │
└───────────────────┘                    └──────────────────┘
```

**Vision System:** Camera management, YOLO detection, pose estimation, robot communication

**RAPID Server:** Socket server, event-driven protocol, cup pickup/placement, safety management

**Protocol:** TCP/IP (default 127.0.0.1:1025), text-based messages, position [x,y,z] + orientation [x,y,z]

---

## 📁 Project Structure

```
PythonToRapid/
│
├── Vision_System/              # Python vision and detection system
│   ├── src/                   # Core modules (camera, detector, pose, communication, visualizer)
│   ├── main.py                # Main detection system
│   ├── calibration_capture.py # All-in-one calibration tool
│   ├── YOLO8n_Model.pt        # Trained YOLO model
│   └── ReadMe.md              # Vision system documentation
│
├── Training_Model/             # YOLO model training
│   ├── YOLO8n_Model.pt        # Trained model (99.48% mAP@50)
│   ├── Cup_Orientation_Training_Colab.ipynb
│   └── ReadMe.md              # Training documentation
│
├── Rapid/                      # RAPID server scripts (ABB YuMi)
│   ├── server.mod             # Main RAPID server module
│   ├── Server_functions.mod   # Server helper functions
│   └── Dynamic_rapid.txt      # Protocol documentation
│
└── Readme.md                   # This file
```

**Note:** Full robot documentation → `robotstudio` folder in main repository

---

## 🚀 Quick Start

### Installation

```bash
# Clone and navigate
git clone https://github.com/your-username/MARC-HT25.git
cd MARC-HT25/PythonToRapid/Vision_System

# Setup Python environment
python -m venv venv
.\venv\Scripts\activate  # Windows
pip install -r Requirements.txt

# Run calibration
python calibration_capture.py

# Run system
python main.py
```

### Controls
- `q` - Quit | `s` - Save frame | `p` - Status | `r` - Start robot | `a` - Toggle auto-start

---

## 🎯 Detection Classes (8 Classes)

**Cup Orientations:**
- Back [-1,0,0] | Front [1,0,0] | left_side [0,-1,0] | right_side [0,1,0]
- upright [0,0,1] | upside_down [0,0,-1]

**Additional:** Gripper, handle

---

## 📚 Documentation

- **[Vision System](Vision_System/ReadMe.md)** - Python system, calibration, troubleshooting
- **[Training Model](Training_Model/ReadMe.md)** - YOLO training, retraining, metrics
- **[RAPID Server](robotstudio/)** - Robot programming, RobotStudio setup

---

## 📈 Performance

- **Detection**: 99.48% mAP@50, ~30 FPS, <30ms latency
- **Calibration**: <10mm error in working zones
- **System**: Thread-safe, auto-reconnection, 95%+ uptime

---

## 🐛 Quick Troubleshooting

**Camera not detected:** Verify USB 3.0 connection
**Robot connection failed:** Check IP address, verify RAPID server running
**Poor detection:** Check lighting, clean lens, recalibrate
**Inaccurate positions:** Run calibration with 15+ points

Details: [Vision System Troubleshooting](Vision_System/ReadMe.md#troubleshooting)

---

## 🎯 This Part of the Project Goals

### Achieved ✅
- Real-time cup detection (99.48% accuracy)
- Automated robot communication
- Robust calibration system
- Comprehensive documentation

### Future Enhancements 🚀
- Multi-robot support
- Additional object types (plates, bowls)
- Web interface for monitoring
- Advanced error recovery

---

## 🎖️ Acknowledgments

**Technologies:** Luxonis DepthAI, Ultralytics YOLOv8, ABB YuMi, OpenCV, PyTorch

**Tools:** Google Colab, Roboflow, RobotStudio

---

**Last Updated**: November 17, 2025 | **Status**: Active Development ✅

*For detailed documentation, see README files in each subdirectory.*