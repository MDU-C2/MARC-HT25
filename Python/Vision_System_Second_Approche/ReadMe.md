# Vision System - Cup Detection & Robot Communication

**Author:** Mahmoud Ayoub  
**System:** External PC vision processing for ABB YuMi robot

---

## 🚀 Quick Start

### Complete System Startup

**1. Start RAPID Server (Robot Side)**
```
1. Open RobotStudio
2. Load rapid_server.txt to YuMi controller
3. Run the RAPID program → Server starts on port 1025
4. Verify "Server listening..." message
```

**2. Start Vision System (PC Side)**
```bash
cd Vision_System_Second_Approche
.\venv\Scripts\activate
python main.py
```

**3. System Ready**
- Vision detects cups automatically
- Auto-start mode sends cups every 5 seconds
- Press `r` to send manually or `a` to toggle auto-mode

---

## 📋 Overview

External PC vision system that detects cups, estimates 6DOF poses, and communicates with YuMi robot via TCP/IP.

**Key Features:**
- YOLO-based detection (8 classes, 99.48% mAP@50)
- Multi-zone pixel-based calibration
- Thread-safe robot communication
- Real-time depth correction (OAK-D Pro)
- Event-driven RAPID protocol

**Detection Classes:**
- Cup orientations: `Back`, `Front`, `left_side`, `right_side`, `upright`, `upside_down`
- Additional: `Gripper`, `handle`
- Markers: `robot_base` (green color detection)

---

## 🗂️ Project Structure

```
Vision_System_Second_Approche/
│
├── main.py                      # Main detection loop
├── OffLine_test.py              # Offline testing without robot
├── test_calibration.py          # Calibration validation
│
├── rapid_server.txt             # RAPID server code for robot
├── calibration_capture.py       # Calibration tool
├── auto_calibrate.py            # Automatic calibration
│
├── best_medium.pt               # Trained model
├── calibration_input.json       # Manual calibration data
├── calibration_params.json      # Transformation matrices
├── calibration_positions.json   # Auto-calibration positions
│
├── src/                         # Core modules
│   ├── camera_manager.py        # OAK-D interface + depth correction
│   ├── cup_detector.py          # YOLO detection + markers
│   ├── pose_estimator.py        # Coordinate transformation
│   ├── PythonToRapid.py         # TCP/IP communication
│   ├── visualizer.py            # Display + UI
│   └── gripper_detector.py      # Gripper detection module
│
├── Requirements.txt
└── venv/
```

---

## ⚙️ Installation

```bash
# Navigate to project
cd Vision_System_Second_Approche

# Create virtual environment
python -m venv venv
.\venv\Scripts\activate          # Windows
source venv/bin/activate         # Linux/Mac

# Install dependencies
pip install -r Requirements.txt
```

**Dependencies:**
- OpenCV, NumPy, SciPy
- Ultralytics (YOLOv8)
- DepthAI (OAK-D camera)
- scikit-learn

---

## 🧪 Testing

### Offline Testing (No Robot Required)
```bash
python OffLine_test.py
```
Tests vision system without robot connection - useful for model and calibration validation.

### Calibration Testing
```bash
python test_calibration.py
```
Validates calibration accuracy by checking transformation errors across workspace zones.

---

## 🎯 Calibration

```bash
python auto_calibrate.py
```

Robot moves gripper to predefined positions while vision system captures points automatically. Requires `calibration_positions.json`.

---

## 🤖 RAPID Server

### Setup
1. Load `rapid_server.txt` in RobotStudio
2. Set IP/port to match Python: `127.0.0.1:1025`
3. Run RAPID program

### Communication Protocol
```
Robot → Python: Connection_test
Python → Robot: Connection_Confirmed
Python → Robot: Cups_available
Robot → Python: Ask_amount_of_cups
Python → Robot: <number>
Robot → Python: Ask_Coordinate
Python → Robot: <x,y,z>
Robot → Python: Ask_Orientation  
Python → Robot: <ox,oy,oz>
Robot → Python: Ask_Wait → Ack_stop
```

---

## 🖥️ System Modules

### 1. main.py
Main detection loop - initializes components, runs detection (30 FPS), manages robot thread.

### 2. camera_manager.py
OAK-D interface with zone-based depth correction (3 zones: <1200mm, <1350mm, >1350mm).

### 3. cup_detector.py
YOLO detection + robot base marker (green color detection).

### 4. pose_estimator.py
Transforms camera coordinates [pixel_x, pixel_y, depth_mm] → robot [x, y, z] using zone-specific calibration matrices.

### 5. PythonToRapid.py
Thread-safe TCP/IP communication with cup queue management and auto-reconnection.

### 6. visualizer.py
Real-time display with bounding boxes, cup numbers, orientations, confidence, depth, and status.

---

## ⌨️ Keyboard Controls

| Key | Action                               |
| --- | ------------------------------------ |
| `q` | Quit system                          |
| `s` | Save current frame                   |
| `p` | Print system status                  |
| `r` | Start robot communication manually   |
| `a` | Toggle auto-start mode (default: ON) |

---

## 🔧 Configuration

Edit in respective files:

**Camera:** `camera_manager.py` - RGB resolution (720p/1080p/4k), FPS (30)  
**Detection:** `cup_detector.py` - Model path (`best_medium.pt`), confidence (0.6)  
**Robot:** `PythonToRapid.py` - IP (127.0.0.1), port (1025), release position

---

## 🛠️ Troubleshooting

### Camera
- **Not detected:** Check USB 3.0 connection, try different port
- **Low FPS:** Reduce to 720p, close other apps

### Detection
- **No cups:** Lower confidence to 0.4, check lighting
- **Wrong orientation:** Check handle visibility, verify lighting

### Calibration
- **Inaccurate:** Recalibrate with 40-80 points
- **High error:** Add more points in problem zones

### Robot Communication
- **Cannot connect:** Verify RAPID server running, check IP/port (127.0.0.1:1025)
- **Cups not sent:** Press `p` for status, toggle auto-start with `a`

---

## 📈 Performance Metrics

**Detection:**
- **FPS:** ~30 fps @ 1080p
- **Latency:** ~30ms detection + ~70ms processing = ~100ms total
- **Accuracy:** 99.48% mAP@50 (YOLO8n)

**Calibration Accuracy:**
- **Working zone (<1200mm):** <10mm error
- **Mid zone (<1350mm):** <15mm error  
- **Extended zone:** <20mm error

**System Reliability:**
- Thread-safe queue operations
- Auto-reconnection on network failure
- 95%+ uptime in testing

---

## 🔬 Technical Details

### Coordinate Systems

**Camera Space:**
- Origin: Top-left corner
- Units: Pixels (X, Y) + millimeters (depth)
- Range: X=[0-1920], Y=[0-1080], Depth=[300-3000]mm

**Robot Space:**
- Origin: Robot base (green marker)
- Units: Millimeters
- Axes: X (forward), Y (left), Z (up)

---

## 💡 Best Practices

- **Detection:** Even lighting, clean lens, clear workspace
- **Communication:** Recalibrate monthly, monitor with `p`, test singles first
- **Development:** Use venv, test before deployment, archive working versions

---

## 📁 Related Files

- **RAPID Server:** `rapid_server.txt` (robot-side communication)
- **Testing:** `OffLine_test.py` (no robot), `test_calibration.py` (validation)
- **Model Training:** See `Training_Model/` folder
- **Dependencies:** `Requirements.txt`
- **Calibration Data:** 
  - `calibration_input.json` (manual points)
  - `calibration_params.json` (transformation matrices)
  - `calibration_positions.json` (auto-calibration)

---

**Project Status:** ✅ Active Development  
**Last Updated:** January 2026  
**Contact:** Mahmoud Ayoub