# Vision System - Cup Detection & Robot Communication

**Created by: Mahmoud Ayoub**

---

## 📋 Overview

The Vision System is the core component of the robotic dishwasher project. It combines computer vision, YOLO-based object detection, and robotic communication to detect cups in various orientations and send precise positioning data to the YuMi robot for automated grasping and manipulation.

**Key Features:**
- Real-time cup detection using OAK-D Pro camera
- 8-class YOLO model for orientation detection (99.48% mAP@50)
- Pixel-based multi-zone calibration system
- Automatic pose estimation with 6DOF coordinates
- Thread-safe robot communication protocol
- Dynamic event-driven architecture

---

## 🏗️ System Architecture

```
Vision_System/
│
├── main.py                          # Main detection loop & system orchestration
├── calibration_capture.py           # All-in-one calibration tool
├── calibration_input.json           # Calibration input data (robot coordinates)
├── calibration_params.json          # Calibration parameters (transformation matrices)
├── YOLO8n_Model.pt                  # Trained YOLO model (99.48% mAP@50)
├── Requirements.txt                 # Python dependencies
│
├── src/                             # Source modules
│   ├── camera_manager.py           # OAK-D camera interface & depth correction
│   ├── cup_detector.py             # YOLO-based detection & marker detection
│   ├── pose_estimator.py           # Pixel-to-robot coordinate transformation
│   ├── PythonToRapid.py            # Robot communication & cup queue management
│   └── visualizer.py               # Detection visualization & UI overlay
│
├── venv/                            # Python virtual environment
└── Old_Versions/                    # Archive of previous implementations
```

---

## 🎯 System Workflow

```
1. Camera Capture
   ↓
2. YOLO Detection (cups + gripper + markers)
   ↓
3. Pose Estimation (screen → robot coordinates)
   ↓
4. Cup Queue Management (add to robot queue)
   ↓
5. Robot Communication (send via PythonToRapid protocol)
   ↓
6. Visualization (display results with overlay)
```

---

## 🚀 Installation

### Prerequisites

- **Hardware**: OAK-D Pro camera
- **Robot**: ABB YuMi robot with RAPID server running
- **OS**: Windows/Linux
- **Python**: 3.8+

### Step 1: Clone Repository

```bash
cd Vision_System
```

### Step 2: Create Virtual Environment

```bash
python -m venv venv

# Windows
.\venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

### Step 3: Install Dependencies

```bash
pip install -r Requirements.txt
```

**Key Dependencies:**
- `depthai==2.30.0.0` - OAK-D camera SDK
- `opencv-python==4.12.0.88` - Computer vision
- `ultralytics==8.3.205` - YOLOv8 framework
- `numpy`, `scipy`, `scikit-learn` - Numerical computing
- `torch`, `torchvision` - Deep learning

### Step 4: Verify Installation

```bash
python -c "import depthai; print('DepthAI version:', depthai.__version__)"
python -c "import ultralytics; print('Ultralytics installed')"
```

---

## 🎮 Usage

### Running the Main System

```bash
# Activate virtual environment
.\venv\Scripts\activate

# Run main detection system
python main.py
```

### System Controls

**Keyboard Commands:**
- `q` - Quit system
- `s` - Save current frame
- `p` - Print system status
- `r` - Manually start robot communication
- `a` - Toggle auto-start robot (default: ON)

### Auto-Start Mode (Default)

The system automatically:
1. Detects cups in the camera view
2. Adds them to the robot queue
3. Starts robot communication every 5 seconds if cups are pending
4. Sends cup positions and orientations to YuMi

---

## 🎯 Calibration

The system uses a **pixel-based multi-zone regression** calibration method to transform screen coordinates to robot coordinates.

### Running Calibration

```bash
python calibration_capture.py
```

### Calibration Process

**Step 1: Prepare Calibration Objects**
- Green marker (robot base origin)
- 12+ cups placed at predefined robot positions

**Step 2: Interactive Capture**
1. Place object at specified position
2. Wait for detection (green bounding box)
3. Press `c` to capture screen coordinates
4. Repeat for all calibration points

**Step 3: Automatic Calculation**
- Generates transformation matrices per zone
- Calculates global fallback model
- Saves to `calibration_params.json`

### Calibration Files

**`calibration_input.json`** - Input data with robot coordinates
```json
{
  "robot_origin": {
    "name": "Robot Base (Green Marker)",
    "robot": [0, 0, 0],
    "screen": [973.0, 177.0, 1055.0]
  },
  "cups": [...]
}
```

**`calibration_params.json`** - Calculated transformation parameters
```json
{
  "method": "pixel_based_multizone_regression",
  "zones": { ... },
  "zone_boundaries": { ... },
  "global_fallback": { ... }
}
```

### Calibration Zones

The workspace is divided into zones for improved accuracy:
- `CENTER` - Main working area
- `LEFT`, `RIGHT_BACK`, `MID_BACK` - Peripheral zones
- `LEFT_BACK`, `FAR_RIGHT_BACK`, `FAR_BACK`, `FAR_LEFT_BACK` - Extended zones

Each zone has its own transformation matrix for optimal precision.

---

## 📦 Module Documentation

### 1. `main.py` - Main Detection System

**Purpose**: Orchestrates the entire vision pipeline

**Key Features:**
- Initializes all system components
- Runs main detection loop at camera FPS
- Manages robot communication thread
- Provides status overlay and controls

**Main Class**: `CupDetectionSystem`

```python
# Initialize system
system = CupDetectionSystem()

# Run detection loop
system.run()
```

---

### 2. `camera_manager.py` - OAK-D Camera Interface

**Purpose**: Manages OAK-D Pro camera with depth correction

**Key Features:**
- RGB + Depth stream acquisition
- Zone-based distance-dependent depth correction
- Camera intrinsics calibration
- 3D coordinate calculation

**Main Class**: `OAKDCamera`

**Depth Correction Zones:**
```python
Near zone:  < 1200mm → scale=0.97
Mid zone:   < 1350mm → scale=0.92
Far zone:   < 99999mm → scale=0.95
```

**Usage Example:**
```python
camera = OAKDCamera(rgb_resolution="1080p", fps=30)
rgb_frame, depth_frame = camera.get_frames()
```

---

### 3. `cup_detector.py` - YOLO Detection

**Purpose**: Detects cups, gripper, and robot markers

**Key Features:**
- YOLO-based neural network detection
- 8-class orientation detection
- Color-based marker detection (green for robot base)
- Confidence filtering and depth integration

**Main Class**: `CupDetector`

**Detected Classes:**
- Cup orientations: `Back`, `Front`, `left_side`, `right_side`, `upright`, `upside_down`
- Additional: `Gripper`, `handle`
- Markers: `robot_base` (green)

**Usage Example:**
```python
detector = CupDetector(
    model_path='YOLO8n_Model.pt',
    confidence_threshold=0.6
)
detections = detector.detect(rgb_frame, depth_frame)
```

---

### 4. `pose_estimator.py` - Coordinate Transformation

**Purpose**: Transforms screen coordinates to robot coordinates

**Key Features:**
- Pixel-based calibration system
- Multi-zone regression for accuracy
- 3D orientation vectors (replaces quaternions)
- Gripper offset correction

**Main Class**: `PoseEstimator`

**Transformation Method:**
```python
# Screen [pixel_x, pixel_y, depth_mm] → Robot [x, y, z]
robot_coords = pose_estimator.screen_to_robot(pixel_x, pixel_y, depth_mm)
```

**Orientation Vectors:**
```python
'Back': [-1.0, 0.0, 0.0]
'Front': [1.0, 0.0, 0.0]
'upright': [0.0, 0.0, 1.0]
# ... etc
```

---

### 5. `PythonToRapid.py` - Robot Communication

**Purpose**: Manages robot communication and cup queue

**Key Features:**
- Thread-safe cup queue with 'sent' flag tracking
- Background communication thread
- Dynamic message handling (event-driven)
- Connection management with RAPID server

**Main Class**: `RobotCommunication`

**Communication Protocol:**
```python
Connection_test → Connection_Confirmed
Cups_available → Ask_amount_of_cups
Send amount → Ack_amount_of_cups
Ack_cup_current_position → Send pickup coordinate + orientation
Ack_cup_end_position → Send release coordinate + orientation
Ask_Wait → Robot moving
Ack_stop → Session complete
```

**Usage Example:**
```python
robot = RobotCommunication(host='127.0.0.1', port=1025)
# Using IP = '127.0.0.1' for virtual testing 
# Using IP = '192.168.125.1' for real testing 
robot.add_cups(cups_data)
robot.start_robot_thread()
```

---

### 6. `visualizer.py` - Detection Visualization

**Purpose**: Display detection results with annotations

**Key Features:**
- Bounding boxes with class labels
- Cup numbering (Cup_1, Cup_2, etc.)
- Orientation state display
- Depth visualization (side-by-side)
- Status overlay panel

**Main Class**: `Visualizer`

**Display Elements:**
- Green boxes for cups
- Blue box for robot base
- Magenta box for gripper
- Confidence scores and depth values
- 3D orientation vectors

---

## 🔧 Configuration

### Camera Settings

Edit in `camera_manager.py`:
```python
camera = OAKDCamera(
    rgb_resolution="1080p",  # Options: "1080p", "720p", "4k"
    fps=30,                  # Frame rate
    depth_enabled=True       # Enable depth stream
)
```

### Detection Settings

Edit in `main.py`:
```python
detector = CupDetector(
    model_path='YOLO8n_Model.pt',
    confidence_threshold=0.6  # Adjust for sensitivity (0.0-1.0)
)
```

### Robot Connection

Edit in `PythonToRapid.py`:
```python
robot = RobotCommunication(
    host='127.0.0.1',  # Robot IP address
    port=1025          # RAPID server port
)
```

### Release Position

Set default release position:
```python
robot.set_release_position(x=421, y=-186, z=-55)  # In mm
```

---

## 📊 System Status

During runtime, press `p` to view system status:

```
====================================================================
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
  Cup_2 [upright]: x=450.5, y=-120.3, z=-55.0
  Cup_3 [Front]: x=380.2, y=-95.1, z=-55.0
====================================================================
```

---

## 🐛 Troubleshooting

### Camera Issues

**Problem**: Camera not detected
```bash
# Check USB connection
# Verify USB 3.0 port (required for OAK-D)
# Test with:
python -c "import depthai as dai; print(dai.Device.getAllAvailableDevices())"
```

**Problem**: Low frame rate
- Reduce RGB resolution to 720p
- Close other applications using camera
- Check USB bandwidth

### Detection Issues

**Problem**: No cups detected
- Lower confidence threshold: `confidence_threshold=0.4`
- Check lighting conditions
- Verify camera focus
- Test YOLO model: `python -c "from ultralytics import YOLO; model = YOLO('YOLO8n_Model.pt')"`

**Problem**: Wrong orientation detected
- Retrain model with more data
- Check cup placement (clear view of handle)
- Increase confidence threshold for stricter detection

### Calibration Issues

**Problem**: Inaccurate robot positions
- Recalibrate with more points (15-20 recommended)
- Verify robot base marker is visible
- Check depth correction settings
- Test on known positions

**Problem**: Calibration capture fails
- Ensure good lighting
- Clean camera lens
- Adjust confidence threshold
- Verify object is in frame

### Robot Communication Issues

**Problem**: Cannot connect to robot
```bash
# Verify RAPID server is running on robot
# Check IP address and port
# Test connection:
telnet 127.0.0.1 1025
```

**Problem**: Cups not being sent
- Check cup queue: Press `p` for status
- Verify robot is not busy
- Enable auto-start: Press `a`
- Manually start: Press `r`

---

## 🔄 Development Workflow

### Making Changes

1. **Activate environment**
   ```bash
   .\venv\Scripts\activate
   ```

2. **Edit files** in `src/` folder

3. **Test changes**
   ```bash
   python main.py
   ```

4. **Archive old version** (optional)
   - Move to `Old_Versions/` folder

### Adding New Features

**Example: Adding a new detection class**

1. Retrain YOLO model with new class
2. Update `orientation_map` in `cup_detector.py`
3. Add orientation vector in `pose_estimator.py`
4. Update visualizer colors if needed

---

## 📈 Performance Metrics

**Detection Speed:**
- FPS: ~30 fps (1080p)
- Detection latency: ~30ms
- End-to-end latency: ~100ms (detection → robot)

**Accuracy:**
- YOLO mAP@50: 99.48%
- Calibration error: <10mm (within working zone)
- Orientation accuracy: ~95%

**Reliability:**
- Thread-safe cup queue (no duplicates)
- Automatic reconnection on failure
- Graceful error handling

---

## 🔗 Related Documentation

- **Training Model**: `../Training_Model/ReadMe.md` - Model training and retraining
- **RAPID Server**: Contact robot team for RAPID code documentation
- **OAK-D Camera**: [DepthAI Documentation](https://docs.luxonis.com/)
- **YOLOv8**: [Ultralytics Documentation](https://docs.ultralytics.com/)

---

## 📝 Version History

**Current Version** (November 2025)
- Refactored architecture with separated concerns
- Thread-safe robot communication
- Dynamic event-driven protocol
- Zone-based depth correction
- Vector-based orientation (replaced quaternions)

**Previous Versions** (See `Old_Versions/`)
- Quaternion-based orientation
- Sequential robot protocol
- Manual calibration system

---

## 🎓 Technical Details

### Coordinate Systems

**Screen Coordinates:**
- Origin: Top-left corner of camera image
- Units: Pixels (x, y) + millimeters (depth)
- Range: x=[0-1920], y=[0-1080], depth=[0-3000]mm

**Robot Coordinates:**
- Origin: Robot base (green marker)
- Units: Millimeters
- Axes: X (forward), Y (left), Z (up)

### Transformation Pipeline

```
Camera Frame (pixels + depth)
         ↓
Camera Intrinsics (fx, fy, cx, cy)
         ↓
3D Camera Coordinates (X, Y, Z)
         ↓
Calibration Matrix (zone-based regression)
         ↓
Robot Coordinates (x, y, z)
```

### Thread Architecture

```
Main Thread:
  - Camera capture
  - YOLO detection
  - Pose estimation
  - Visualization
  - Cup queue updates

Robot Thread (background):
  - Socket connection
  - Message handling
  - Cup transmission
  - State management
```

---

## 💡 Best Practices

### For Accurate Detection:
- Ensure good, even lighting
- Keep camera lens clean
- Place cups within calibrated zones
- Avoid cluttered backgrounds
- Maintain stable camera mounting

### For Reliable Operation:
- Run calibration regularly (weekly)
- Monitor system status frequently
- Keep robot communication active
- Update model with new cup types
- Archive working configurations

### For Development:
- Test changes in isolation first
- Use version control (git)
- Document configuration changes
- Keep old versions in archive
- Follow modular architecture

---

## 📧 Support

**Created by: Mahmoud Ayoub**

For technical questions:
- Check troubleshooting section above
- Review module documentation
- Test with simplified scenarios
- Consult related documentation
---

## 🎖️ Acknowledgments

- **Camera SDK**: Luxonis DepthAI
- **ML Framework**: Ultralytics YOLOv8
- **Robot Platform**: ABB YuMi
- **Computer Vision**: OpenCV
- **Numerical Computing**: NumPy, SciPy, scikit-learn

---

**Last Updated**: November 17, 2025
