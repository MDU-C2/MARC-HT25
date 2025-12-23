# Vision System - Cup Detection & Robot Communication

**Created by: Mahmoud Ayoub**

---

## 📋 Overview

The Vision System combines computer vision, YOLO-based detection, and robotic communication to detect cups in various orientations and send precise positioning data to the YuMi robot.

**Key Features:**
- Real-time cup detection with OAK-D Pro camera
- 8-class YOLO model (99.48% mAP@50)
- Pixel-based multi-zone calibration
- 6DOF pose estimation
- Thread-safe robot communication
- Dynamic event-driven architecture

---

## 🏗️ System Architecture

```
Vision_System/
│
├── main.py                          # Main detection loop
├── calibration_capture.py           # All-in-one calibration tool
├── calibration_input.json           # Calibration input data
├── calibration_params.json          # Transformation matrices
├── YOLO8n_Model.pt                  # Trained YOLO model
├── Requirements.txt                 # Dependencies
│
├── src/                             # Source modules
│   ├── camera_manager.py           # OAK-D camera & depth correction
│   ├── cup_detector.py             # YOLO detection & markers
│   ├── pose_estimator.py           # Coordinate transformation
│   ├── PythonToRapid.py            # Robot communication
│   └── visualizer.py               # Visualization & UI
│
├── venv/                            # Virtual environment
```

**Workflow:** Camera → YOLO Detection → Pose Estimation → Cup Queue → Robot Communication → Visualization

---

## 🚀 Installation & Usage

### Quick Setup

```bash
# Navigate to folder
cd Vision_System

# Create environment
python -m venv venv
.\venv\Scripts\activate  # Windows

# Install dependencies
pip install -r Requirements.txt

# Run calibration (first time)
python calibration_capture.py

# Run system
python main.py
```

### Controls

- `q` - Quit | `s` - Save frame | `p` - Print status
- `r` - Start robot manually | `a` - Toggle auto-start

### Auto-Start Mode (Default)

System automatically detects cups, adds to queue, and starts robot communication every 5 seconds.

---

## 🎯 Calibration

**Method:** Pixel-based multi-zone regression transforms screen coordinates to robot coordinates.

### Running Calibration

```bash
python calibration_capture.py
```

**Process:**
1. Place object at specified position
2. Wait for detection (green box)
3. Press `c` to capture
4. Repeat for all points (12+ recommended)
5. Auto-generates `calibration_params.json`

**Zones:** CENTER, LEFT, RIGHT_BACK, MID_BACK, LEFT_BACK, FAR_RIGHT_BACK, FAR_BACK, FAR_LEFT_BACK

Each zone has its own transformation matrix for optimal accuracy.

---

## 📦 Module Documentation

### 1. `main.py` - Main System

Orchestrates entire vision pipeline: initializes components, runs detection loop, manages robot thread.

```python
system = CupDetectionSystem()
system.run()
```

### 2. `camera_manager.py` - Camera Interface

**Class:** `OAKDCamera`

**Features:**
- RGB (1920x1080) + Depth streams
- Zone-based depth correction (3 zones: <1200mm, <1350mm, <99999mm)
- Camera intrinsics calibration

```python
camera = OAKDCamera(rgb_resolution="1080p", fps=30)
rgb_frame, depth_frame = camera.get_frames()
```

### 3. `cup_detector.py` - YOLO Detection

**Class:** `CupDetector`

**Detects:**
- Cup orientations: Back, Front, left_side, right_side, upright, upside_down
- Additional: Gripper, handle
- Markers: robot_base (green color detection)

```python
detector = CupDetector(model_path='YOLO8n_Model.pt', confidence_threshold=0.6)
detections = detector.detect(rgb_frame, depth_frame)
```

### 4. `pose_estimator.py` - Coordinate Transformation

**Class:** `PoseEstimator`

Transforms screen [pixel_x, pixel_y, depth_mm] → robot [x, y, z] using calibration matrices.

**Orientation Vectors:**
```python
'Back': [-1.0, 0.0, 0.0]
'Front': [1.0, 0.0, 0.0]
'upright': [0.0, 0.0, 1.0]
# etc.
```

```python
robot_coords = pose_estimator.screen_to_robot(pixel_x, pixel_y, depth_mm)
```

### 5. `PythonToRapid.py` - Robot Communication

**Class:** `RobotCommunication`

**Features:**
- Thread-safe cup queue with 'sent' flag
- Background communication thread
- Dynamic message handling (event-driven)
- Connection management

**Protocol:** TCP/IP socket (default: 127.0.0.1:1025)

```python
robot = RobotCommunication(host='127.0.0.1', port=1025)
robot.add_cups(cups_data)
robot.start_robot_thread()
```

**Message Flow:**
```
Connection_test → Connection_Confirmed
Cups_available → Ask_amount_of_cups → Send amount
Ask_Coordinate → Send [x,y,z] → Ask_Orientation → Send [x,y,z]
Ask_Wait → Robot moving → Ack_stop → Complete
```

### 6. `visualizer.py` - Visualization

**Class:** `Visualizer`

Displays bounding boxes, cup numbering, orientation states, confidence, depth, and status overlay.

**Colors:** Green (cups), Blue (robot base), Magenta (gripper)

---

## 🔧 Configuration

### Camera Settings
```python
camera = OAKDCamera(
    rgb_resolution="1080p",  # "1080p", "720p", "4k"
    fps=30,
    depth_enabled=True
)
```

### Detection Settings
```python
detector = CupDetector(
    model_path='YOLO8n_Model.pt',
    confidence_threshold=0.6  # 0.0-1.0
)
```

### Robot Connection
```python
robot = RobotCommunication(
    host='127.0.0.1',  # Robot IP
    port=1025
)
robot.set_release_position(x=421, y=-186, z=200)  # mm
```

---

## 📊 System Status

Press `p` during runtime:

```
SYSTEM STATUS
====================================================================
 ROBOT:
  Connected: True
  Busy: False
  State: ready
  Total cups: 3
  Unsent cups: 2
  Cups sent: 1

 CUP QUEUE:
  Cup_2 [upright]: x=450.5, y=-120.3, z=200.0
  Cup_3 [Front]: x=380.2, y=-95.1, z=200.0
====================================================================
```

---

## 🐛 Troubleshooting

### Camera Issues

**Problem:** Camera not detected
```bash
# Check USB 3.0 connection
python -c "import depthai as dai; print(dai.Device.getAllAvailableDevices())"
```

**Problem:** Low FPS → Reduce resolution to 720p, close other apps

### Detection Issues

**Problem:** No cups detected
- Lower confidence: `confidence_threshold=0.4`
- Check lighting and camera focus
- Verify model loaded

**Problem:** Wrong orientation
- Retrain with more data
- Check cup placement (handle visible)
- Increase confidence threshold

### Calibration Issues

**Problem:** Inaccurate positions
- Recalibrate with 15-20 points
- Verify robot base marker visible
- Check depth correction settings

### Robot Communication Issues

**Problem:** Cannot connect
```bash
# Verify RAPID server running
telnet 127.0.0.1 1025
```

**Problem:** Cups not sent
- Check status with `p`
- Enable auto-start: `a`
- Manually start: `r`

---

## 🔄 Development

### Making Changes

1. Activate environment: `.\venv\Scripts\activate`
2. Edit files in `src/`
3. Test: `python main.py`
4. Archive old version in `Old_Versions/`

### Adding Detection Class

1. Retrain YOLO with new class
2. Update `orientation_map` in `cup_detector.py`
3. Add vector in `pose_estimator.py`
4. Update visualizer colors if needed

---

## 📈 Performance

**Detection:**
- FPS: ~30 fps (1080p)
- Latency: ~30ms detection, ~100ms end-to-end
- Accuracy: 99.48% mAP@50

**Calibration:**
- Working zone error: <10mm
- Extended zone error: <20mm

**Reliability:**
- Thread-safe, no race conditions
- Auto-reconnection
- 95%+ uptime

---

## 🔗 Related Documentation

- **Training Model**: `../Training_Model/ReadMe.md`
- **RAPID Server**: See `robotstudio` folder
- **OAK-D Camera**: [DepthAI Docs](https://docs.luxonis.com/)
- **YOLOv8**: [Ultralytics Docs](https://docs.ultralytics.com/)

---

## 📝 Technical Details

### Coordinate Systems

**Screen:** Origin top-left, units: pixels + mm depth, range: x=[0-1920], y=[0-1080], depth=[0-3000]mm

**Robot:** Origin at base (green marker), units: mm, axes: X (forward), Y (left), Z (up)

### Transformation Pipeline

```
Camera Frame (pixels + depth)
    ↓ Camera Intrinsics
3D Camera Coordinates (X, Y, Z)
    ↓ Calibration Matrix (zone-based)
Robot Coordinates (x, y, z)
```

### Thread Architecture

**Main Thread:** Camera, detection, pose estimation, visualization, queue updates

**Robot Thread (background):** Socket connection, message handling, cup transmission, state management

---

## 💡 Best Practices

**For Accurate Detection:**
- Good, even lighting
- Clean camera lens
- Cups within calibrated zones
- Avoid cluttered backgrounds

**For Reliable Operation:**
- Calibrate weekly
- Monitor system status
- Update model with new cup types
- Archive working configurations

---

## 🎖️ Acknowledgments

**Technologies:** Luxonis DepthAI, Ultralytics YOLOv8, ABB YuMi, OpenCV, NumPy, SciPy, scikit-learn

---

**Last Updated**: November 17, 2025 | **Status**: Active Development ✅