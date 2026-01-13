# Vision System - Cup Detection & Robot Communication

**Author:** Mahmoud Ayoub  
**System:** External PC vision processing for ABB YuMi robot

---

## 🚀 Quick Start

### Complete System Startup

**1. Start RAPID Server (Robot Side)**
```
1. Open RobotStudio
2. Use rapid_server to YuMi controller
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
├── rapid_server.txt             # RAPID server code for robot
├── PythonToRapid.py             # Robot communication (src/)
├── calibration_capture.py       # Calibration tool
├── auto_calibrate.py            # Automatic calibration
│
├── best_medium.pt              # Trained model
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

## 🎯 Calibration 

## Automatic Calibration

```bash
python auto_calibrate.py
```

Robot moves gripper to predefined positions while vision system captures points automatically. Requires `calibration_positions.json`.

---

## 🖥️ System Modules

### 1. main.py
Main detection loop orchestrating all components.

**Key Functions:**
- Initialize camera, detector, pose estimator
- Run detection loop (30 FPS)
- Manage robot communication thread
- Handle keyboard controls

### 2. camera_manager.py
OAK-D camera interface with depth correction.

**Features:**
- RGB: 1920x1080 @ 30fps
- Depth: Stereo matching
- Zone-based correction (3 zones: <1200mm, <1350mm, >1350mm)
- Camera intrinsics

```python
camera = OAKDCamera(rgb_resolution="1080p", fps=30)
rgb_frame, depth_frame = camera.get_frames()
corrected_depth = camera.correct_depth(depth_value, depth_zone)
```

### 3. cup_detector.py
YOLO detection with marker detection.

**Detection Pipeline:**
- YOLO inference on RGB frame
- Class filtering (cups only)
- Robot base marker (green color detection)
- Bounding box extraction

```python
detector = CupDetector(model_path='best_medium.pt', confidence=0.6)
detections = detector.detect(rgb_frame, depth_frame)
```

### 4. pose_estimator.py
Coordinate transformation using calibration matrices.

**Transform Pipeline:**
```
Camera [pixel_x, pixel_y, depth_mm]
    ↓ camera intrinsics
3D Camera [X, Y, Z]
    ↓ calibration matrix (zone-specific)
Robot [x, y, z]
```

**Orientation Vectors:**
```python
'Back': [-1.0, 0.0, 0.0]
'Front': [1.0, 0.0, 0.0]
'upright': [0.0, 0.0, 1.0]
'upside_down': [0.0, 0.0, -1.0]
'left_side': [0.0, 1.0, 0.0]
'right_side': [0.0, -1.0, 0.0]
```

### 5. PythonToRapid.py
Thread-safe robot communication.

**Features:**
- Cup queue with 'sent' flag tracking
- Background communication thread
- Event-driven message handling
- Auto-reconnection
- Release position configuration

```python
robot = RobotCommunication(host='127.0.0.1', port=1025)
robot.add_cups(cups_data)
robot.start_robot_thread()
robot.set_release_position(x=421, y=-186, z=200)
```

### 6. visualizer.py
Real-time display with annotations.

**Display Elements:**
- Bounding boxes (color-coded)
- Cup numbers and orientations
- Confidence scores
- Depth values
- Status overlay
- FPS counter

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

### Camera Settings
```python
camera = OAKDCamera(
    rgb_resolution="1080p",  # Options: "720p", "1080p", "4k"
    fps=30,
    depth_enabled=True
)
```

### Detection Settings
```python
detector = CupDetector(
    model_path='YOLO8n_Model.pt',
    confidence_threshold=0.6  # Range: 0.0-1.0
)
```

### Robot Connection
```python
robot = RobotCommunication(
    host='127.0.0.1',      # Robot controller IP
    port=1025              # Match RAPID server port
)
robot.set_release_position(x=421, y=-186, z=200)  # mm
```

---

## 🛠️ Troubleshooting

### Camera Issues

**No camera detected:**
```bash
python -c "import depthai as dai; print(dai.Device.getAllAvailableDevices())"
```
- Check USB 3.0 connection
- Update DepthAI library
- Try different USB port

**Low FPS:**
- Reduce resolution to 720p
- Close other applications
- Check CPU usage

### Detection Issues

**No cups detected:**
- Lower confidence: `confidence_threshold=0.4`
- Check lighting (avoid shadows)
- Verify model path
- Ensure camera focus

**Wrong orientation:**
- Retrain model with more examples
- Check cup placement (handle visibility)
- Increase confidence threshold
- Verify lighting consistency

### Calibration Issues

**Inaccurate positions:**
- Recalibrate with 40-80 points
**Error >20mm:**
- Add more calibration points in problem zone
- Check camera stability (no movement during calibration)
- Verify depth values realistic (not 0 or max)

### Robot Communication Issues

**Cannot connect:**
```bash
telnet 127.0.0.1 1025
```
- Verify RAPID server running on robot
- Check IP and port match
- Disable firewall temporarily
- Ensure robot controller online

**Cups not sent:**
- Check status with `p`
- Toggle auto-start: `a`
- Manually start: `r`
- Verify robot state: `ready`

**Communication timeout:**
- Check network stability
- Restart RAPID server
- Restart Python system
- Verify message protocol in RAPID code

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

## 💡 Best Practices

### For Accurate Detection
- **Lighting:** Even, diffused lighting (avoid shadows)
- **Maintenance:** Clean camera lens weekly
- **Environment:** Avoid reflective surfaces nearby
- **Background:** Keep workspace clear

### For Reliable Communication
- **Calibration:** Recalibrate monthly or after camera movement
- **Monitoring:** Check system status regularly (`p` key)
- **Updates:** Archive working configs before changes
- **Testing:** Test with single cup before batch processing

### For Development
- Activate venv before editing
- Test changes with `python main.py`
- Archive old versions in `Old_Versions/`
- Document calibration changes
---

## 📁 Related Files

- **RAPID Server:** `rapid_server.txt` (robot-side communication)
- **Model Training:** See `Training_Model/` folder
- **Dependencies:** `Requirements.txt`
- **Calibration Data:** 
  - `calibration_input.json` (manual points)
  - `calibration_params.json` (transformation matrices)
  - `calibration_positions.json` (auto-calibration)

---

## 📚 External Documentation

- **OAK-D Camera:** [DepthAI Docs](https://docs.luxonis.com/)
- **YOLOv8:** [Ultralytics Docs](https://docs.ultralytics.com/)
- **ABB RAPID:** [ABB Robotics Documentation](https://new.abb.com/products/robotics)
- **OpenCV:** [OpenCV Docs](https://docs.opencv.org/)

---

## 🎖️ Technologies

- **Hardware:** ABB YuMi, OAK-D Pro camera
- **Computer Vision:** YOLOv8, OpenCV
- **Processing:** NumPy, SciPy, scikit-learn
- **Communication:** TCP/IP sockets, RAPID language
- **Framework:** Python 3.8+, Ultralytics

---

**Project Status:** ✅ Active Development  
**Last Updated:** January 2026  
**Contact:** Mahmoud Ayoub