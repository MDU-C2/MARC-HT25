# PythonToRapid - Robotic Dishwasher System

**Created by: Mahmoud Ayoub**

---

## 📋 Project Overview

PythonToRapid is an integrated robotic dishwasher system that combines computer vision, machine learning, and robotic automation to detect and manipulate cups in various orientations. The system uses a YuMi robot working with an OAK-D Pro camera-based detection system to identify cups in different positions and communicate precise positioning data for automated grasping and manipulation.

**Key Capabilities:**
- Real-time cup detection using YOLO (99.48% mAP@50)
- 6DOF pose estimation with pixel-based calibration
- Automated robot communication via custom protocol
- Support for 6 cup orientations plus gripper detection
- Thread-safe, event-driven architecture

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
        │                                           │
        │                                           │
        ▼                                           ▼
┌───────────────────┐                    ┌──────────────────┐
│  OAK-D Pro Camera │                    │  Robot Hardware  │
│  + YOLO Detection │                    │   + RobotStudio  │
└───────────────────┘                    └──────────────────┘
```

### Component Breakdown

**Vision System (Python):**
- Camera management with depth correction
- YOLO-based cup orientation detection
- Pixel-to-robot coordinate transformation
- Cup queue management and threading
- Real-time visualization

**RAPID Server (Robot):**
- Socket communication server
- Dynamic event-driven protocol
- Cup pickup and placement routines
- Position and orientation handling
- Safety and error management

**Communication Protocol:**
- TCP/IP socket connection (Virtual: 127.0.0.1:1025) & (Real: 192.168.125.1:1025)
- Text-based message passing
- Event-driven state machine
- Cup data: position [x,y,z] + orientation vector [x,y,z]

---

## 📁 Project Structure

```
PythonToRapid/
│
├── Vision_System/                    # Python vision and detection system
│   ├── src/                          # Core modules
│   │   ├── camera_manager.py         # OAK-D camera interface
│   │   ├── cup_detector.py           # YOLO detection
│   │   ├── pose_estimator.py         # Coordinate transformation
│   │   ├── PythonToRapid.py          # Robot communication
│   │   └── visualizer.py             # Display and UI
│   ├── main.py                       # Main detection system
│   ├── calibration_capture.py        # All-in-one calibration tool
│   ├── YOLO8n_Model.pt               # Trained YOLO model
│   ├── calibration_input.json        # Calibration input data
│   ├── calibration_params.json       # Calibration parameters
│   ├── Requirements.txt              # Python dependencies
│   └── ReadMe.md                     # Vision system documentation
│
├── Training_Model/                   # YOLO model training
│   ├── YOLO8n_Model.pt               # Trained model (99.48% mAP@50)
│   ├── Cup_Orientation_Training_Colab.ipynb  # Training notebook
│   ├── capture_training_images.py   # Data capture script
│   ├── Model_classes.py             # Class definitions
│   ├── val_batch2_pred.jpg          # Validation results
│   ├── confusion_matrix.png         # Performance metrics
│   ├── results.png                  # Training curves
│   └── ReadMe.md                    # Training documentation
│
├── Rapid/                            # RAPID server scripts (ABB YuMi)
│   ├── server.mod                   # Main RAPID server module
│   ├── Server_functions.mod         # Server helper functions
│   ├── Dynamic_rapid.txt            # Protocol documentation
│   ├── Examples_ppositions&Orientation.txt  # Example data format
│   └── Rapid_Server_TestVersion.txt # Test version notes
│
└── Readme.md                         # This file
```

**Note:** Full robot and RobotStudio documentation can be found in the `robotstudio` folder in the main repository.

---

## 🚀 Quick Start

### Prerequisites

**Hardware:**
- OAK-D Pro camera
- ABB YuMi robot with RobotStudio
- Windows/Linux PC
- USB 3.0 port for camera
- Network connection to robot

**Software:**
- Python 3.8+
- RobotStudio (for robot setup)
- Git

### Installation

#### Step 1: Clone Repository

```bash
git clone https://github.com/your-username/MARC-HT25.git
cd MARC-HT25/PythonToRapid
```

#### Step 2: Setup Vision System

```bash
cd Vision_System

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
.\venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r Requirements.txt
```

#### Step 3: Setup Robot

1. Load RAPID modules to robot controller:
   - Copy `Rapid/server.mod` to robot
   - Copy `Rapid/Server_functions.mod` to robot
   
2. Configure robot IP in `Vision_System/src/PythonToRapid.py`:
   ```python
   robot = RobotCommunication(
       host='192.168.125.1',  # Update with the robot IP
       port=1025
   )
   ```

3. Start RAPID server on robot

#### Step 4: Run Calibration

```bash
cd Vision_System
python calibration_capture.py
```

Follow on-screen instructions to capture calibration points.

#### Step 5: Run System

```bash
python main.py
```

**Controls:**
- `q` - Quit
- `s` - Save frame
- `p` - Print status
- `r` - Start robot manually
- `a` - Toggle auto-start

---

## 📊 System Features

### Vision System Features

✅ **Real-time Detection**
- 30 FPS camera operation
- ~30ms detection latency
- YOLO-based neural network (99.48% mAP@50)

✅ **Multi-Orientation Support**
- Back, Front, left_side, right_side
- upright, upside_down
- Automatic orientation vector calculation

✅ **Calibration System**
- Pixel-based multi-zone regression
- Interactive calibration capture
- Automatic transformation calculation
- <10mm accuracy in working zones

✅ **Robot Communication**
- Thread-safe cup queue
- Dynamic event-driven protocol
- Background communication thread
- Automatic reconnection

✅ **Visualization**
- Real-time bounding boxes
- Cup numbering and orientation display
- Depth visualization
- Status overlay

### RAPID Server Features

✅ **Communication Protocol**
- TCP/IP socket server
- Text-based message passing
- Event-driven state machine
- Error handling and recovery

✅ **Robot Control**
- Precise position control
- Orientation-based grasping
- Safe pickup and placement
- Collision avoidance

✅ **Data Handling**
- Position: [x, y, z] in mm
- Orientation: [x, y, z] directional vector
- Multiple cup queue support
- Sequential processing

---

## 🔄 Workflow

### Complete Detection → Manipulation Pipeline

```
1. Camera Capture
   └─► RGB frame (1920x1080) + Depth map
        │
2. YOLO Detection
   └─► Bounding boxes + Classes + Confidence
        │
3. Pose Estimation
   └─► Screen coords → Robot coords + Orientation vectors
        │
4. Cup Queue Management
   └─► Add to queue with 'sent' flag tracking
        │
5. Robot Communication (Background Thread)
   └─► TCP/IP → Send position + orientation
        │
6. Robot Execution
   └─► Move → Grasp → Place → Acknowledge
        │
7. Update Queue
   └─► Mark cup as sent → Process next cup
```

---

## 🎯 Detection Classes

The system detects **8 classes** with high accuracy:

### Cup Orientations (6 classes):
1. **Back** - Handle facing away → [-1.0, 0.0, 0.0]
2. **Front** - Handle facing forward → [1.0, 0.0, 0.0]
3. **left_side** - Tilted left → [0.0, -1.0, 0.0]
4. **right_side** - Tilted right → [0.0, 1.0, 0.0]
5. **upright** - Standing normal → [0.0, 0.0, 1.0]
6. **upside_down** - Inverted → [0.0, 0.0, -1.0]

### Additional Objects (2 classes):
7. **Gripper** - Robot gripper detection
8. **handle** - Cup handle detection

Each orientation maps to a 3D directional vector used by the robot for optimal grasping approach.

---

## 📡 Communication Protocol

### Message Flow Example

```
Vision → Robot: "Connection_test"
Robot → Vision: "Connection_Confirmed"

Vision → Robot: "Cups_available"
Robot → Vision: "Ask_next"

Robot → Vision: "Ask_amount_of_cups"
Vision → Robot: "1"

Robot → Vision: "Ack_amount_of_cups"
Robot → Vision: "Ack_cup_current_position"

Robot → Vision: "Ask_Coordinate"
Vision → Robot: "[450.5,-120.3,200.0]"  # Pickup position

Robot → Vision: "Ack_Coordinate"
Robot → Vision: "Ask_Orientation"
Vision → Robot: "[1.0,0.0,0.0]"  # Front orientation

Robot → Vision: "Ack_Orientation"
Robot → Vision: "Ask_Wait"  # Robot moving to pickup

Robot → Vision: "Ack_cup_end_position"
Robot → Vision: "Ask_Coordinate"
Vision → Robot: "[421,-186,200]"  # Release position

Robot → Vision: "Ack_Coordinate"
Robot → Vision: "Ask_Orientation"
Vision → Robot: "[0.0,0.0,1.0]"  # Upright for placement

Robot → Vision: "Ack_Orientation"
Robot → Vision: "Ask_Wait"  # Robot moving to release

Robot → Vision: "Ack_stop"  # Cup complete
```

---

## 📚 Documentation

### Module Documentation

- **[Vision System Documentation](Vision_System/ReadMe.md)** - Complete guide to Python vision system
  - Camera management
  - Detection pipeline
  - Calibration process
  - Module API reference
  - Troubleshooting

- **[Training Model Documentation](Training_Model/ReadMe.md)** - YOLO model training guide
  - Model architecture
  - Training process
  - Performance metrics
  - Retraining instructions

- **[RAPID Server Documentation](robotstudio/)** - Full robot programming guide
  - RobotStudio setup
  - RAPID code documentation
  - Protocol implementation
  - Safety procedures

### Configuration Files

**`calibration_input.json`** - Calibration input with robot coordinates
```json
{
  "robot_origin": {
    "robot": [0, 0, 0],
    "screen": [973.0, 177.0, 1055.0]
  },
  "cups": [...]
}
```

**`calibration_params.json`** - Calculated transformation matrices
```json
{
  "method": "pixel_based_multizone_regression",
  "zones": {...},
  "global_fallback": {...}
}
```

---

## 🛠️ Development

### Adding New Cup Orientations

1. **Collect Training Data**
   ```bash
   cd Training_Model
   python capture_training_images.py
   ```

2. **Annotate in Roboflow**
   - Label new orientation class
   - Export YOLOv8 format

3. **Train Model**
   - Open `Cup_Orientation_Training_Colab.ipynb`
   - Add new class to training
   - Train until >95% mAP@50

4. **Update Code**
   - Add orientation vector in `cup_detector.py`:
     ```python
     'new_orientation': [x, y, z]
     ```
   - Update `pose_estimator.py` if needed

5. **Test & Deploy**
   - Test detection accuracy
   - Verify robot grasping
   - Update documentation

### Modifying Communication Protocol

1. **Update RAPID Server**
   - Edit `Rapid/server.mod`
   - Add new message handlers
   - Test in RobotStudio

2. **Update Python Client**
   - Edit `Vision_System/src/PythonToRapid.py`
   - Add message handler method:
     ```python
     def _handle_new_message(self) -> bool:
         # Implementation
         return True
     ```
   - Register in `message_handlers` dict

3. **Update Protocol Documentation**
   - Document in `Rapid/Dynamic_rapid.txt`

---

## 📈 Performance Metrics

### Detection Performance
- **Model Accuracy**: 99.48% mAP@50
- **FPS**: ~30 fps (1080p)
- **Detection Latency**: ~30ms
- **End-to-end Latency**: ~100ms

### Calibration Accuracy
- **Working Zone Error**: <10mm
- **Extended Zone Error**: <20mm
- **Calibration Points**: 12+ recommended
- **Recalibration Frequency**: Weekly

### System Reliability
- **Thread Safety**: ✅ No race conditions
- **Error Recovery**: ✅ Automatic reconnection
- **Duplicate Prevention**: ✅ 'sent' flag tracking
- **Uptime**: >95% with proper setup

---

## 🐛 Troubleshooting

### Common Issues

**Issue: Camera not detected**
```bash
# Verify USB 3.0 connection
python -c "import depthai as dai; print(dai.Device.getAllAvailableDevices())"
```

**Issue: Robot connection failed**
- Check robot IP address
- Verify RAPID server is running
- Test connection: `telnet <robot_ip> 1025`

**Issue: Poor detection accuracy**
- Check lighting conditions
- Clean camera lens
- Lower confidence threshold
- Recalibrate system

**Issue: Inaccurate positions**
- Run calibration with 15+ points
- Verify robot base marker visible
- Check depth correction settings

For detailed troubleshooting, see:
- [Vision System Troubleshooting](Vision_System/ReadMe.md#troubleshooting)
- [RAPID Server Issues](robotstudio/)

---

## 🔐 Safety Considerations

### Vision System Safety
- Ensure stable camera mounting
- Verify working zone boundaries
- Test emergency stop functionality
- Monitor system status regularly

### Robot Safety
- Follow ABB YuMi safety guidelines
- Implement proper workspace barriers
- Test collision detection
- Use reduced speed during development
- Never bypass safety interlocks

**⚠️ IMPORTANT:** Always follow your facility's safety procedures and ABB's official safety documentation when operating the robot.

---

## 🎓 Technical Requirements

### Vision System Requirements
- **OS**: Windows 10/11 or Linux (Ubuntu 20.04+)
- **Python**: 3.8 - 3.11
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 2GB for installation
- **USB**: USB 3.0 port for OAK-D camera

### Robot Requirements
- **Robot**: ABB YuMi (IRB 14000)
- **Controller**: IRC5 with RobotWare 6.x+
- **RobotStudio**: Version 2021.x or newer
- **Network**: Ethernet connection to robot controller
- **RAPID License**: Required for custom programming

---

## 📦 Dependencies

### Python (Vision System)
```
depthai==2.30.0.0          # OAK-D camera SDK
opencv-python==4.12.0.88    # Computer vision
ultralytics==8.3.205        # YOLOv8
numpy==2.2.6                # Numerical computing
scipy==1.16.2               # Scientific computing
scikit-learn==1.7.2         # Machine learning
torch==2.8.0                # Deep learning
torchvision==0.23.0         # Vision models
```

Full list: [Vision_System/Requirements.txt](Vision_System/Requirements.txt)

### RAPID (Robot)
- ABB RobotWare 6.x+
- Socket Messaging module
- No external dependencies

---

## 🔄 Version History

### Current Version (November 2025)
- ✅ Refactored modular architecture
- ✅ Thread-safe robot communication
- ✅ Dynamic event-driven protocol
- ✅ Vector-based orientations (replaced quaternions)
- ✅ Zone-based depth correction
- ✅ Comprehensive documentation

### Previous Versions
- Quaternion-based orientation system
- Sequential robot protocol
- Manual calibration workflow
- Monolithic architecture

---

## 🤝 Contributing

### Development Workflow
1. Create feature branch
2. Test changes thoroughly
3. Update relevant documentation
4. Archive old versions in `Old_Versions/`
5. Submit with clear commit messages

### Code Style
- Python: PEP 8 compliance
- RAPID: ABB RAPID coding standards
- Comments: Clear, concise, informative
- Documentation: Update READMEs for changes

---

## 📧 Contact & Support

**Created by: Mahmoud Ayoub**

### Getting Help
1. Check relevant README documentation
2. Review troubleshooting sections
3. Test with simplified scenarios
4. Consult module-specific docs

### Documentation Links
- [Vision System Guide](Vision_System/ReadMe.md)
- [Training Model Guide](Training_Model/ReadMe.md)
- [RAPID Documentation](robotstudio/)

---

## 🎖️ Acknowledgments

### Technologies
- **Camera**: Luxonis OAK-D Pro & DepthAI SDK
- **ML Framework**: Ultralytics YOLOv8
- **Robot Platform**: ABB YuMi (IRB 14000)
- **Computer Vision**: OpenCV
- **Data Science**: NumPy, SciPy, scikit-learn
- **Deep Learning**: PyTorch

### Tools
- **Training**: Google Colab
- **Dataset Management**: Roboflow
- **Robot Programming**: ABB RobotStudio
- **Version Control**: Git/GitHub

---


## 🎯 This Part of Project Goals

### Achieved ✅
- Real-time cup detection with 99.48% accuracy
- Automated robot communication
- Robust calibration system
- Modular, maintainable architecture
- Comprehensive documentation

### Future Enhancements 🚀
- Multi-robot support
- Additional object types (plates, bowls)
- Machine learning-based calibration
- Web interface for monitoring
- Advanced error recovery
- Performance optimization

---

**Last Updated**: November 17, 2025


**Tested With**:
- OAK-D Pro (DepthAI 2.30.0.0)
- ABB YuMi IRB 14000
- Python 3.10
- RobotWare 6.15

---

*For detailed module documentation, please refer to the README files in each subdirectory.*