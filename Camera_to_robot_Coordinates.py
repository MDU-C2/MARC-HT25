import cv2
import depthai as dai
import numpy as np
import blobconverter

# --- added: camera->robot homogeneous transform (mm) ---
H_cam_to_robot = np.array([
    [ 0.956132,  0.046079, -0.289289,  859.1997],
    [ 0.270961,  0.236151,  0.933174, -931.6338],
    [ 0.111315, -0.970623,  0.213306, -287.6907],
    [ 0.0,       0.0,       0.0,         1.0   ],
], dtype=np.float64)

def cam_to_robot_xyz(x_mm: float, y_mm: float, z_mm: float):
    """Apply 4x4 homogeneous transform to camera coords (mm) -> robot coords (mm)."""
    p_cam_h = np.array([x_mm, y_mm, z_mm, 1.0], dtype=np.float64)
    p_robot_h = H_cam_to_robot @ p_cam_h
    return float(p_robot_h[0]), float(p_robot_h[1]), float(p_robot_h[2])
# --- end added ---

def build_homogeneous(rotation_matrix, translation_vector):
    T_camera_to_base_effector = np.eye(4)
    T_camera_to_base_effector[:3, :3] = rotation_matrix
    T_camera_to_base_effector[:3, 3] = translation_vector.reshape(3)
    return T_camera_to_base_effector


def convert_coordinates(x ,y ,z, homogeneous_matrix): # X Y Z coordinates that should be translated into robot frame coordinates
    obj_camera_coordinates = np.array([x, y, z])
    obj_camera_coordinates_homo = np.append(obj_camera_coordinates, [1])  # Convert object coordinates to homogeneous coordinates
    obj_base_effector_coordinates_homo = homogeneous_matrix.dot(obj_camera_coordinates_homo)
    obj_base_coordinates = obj_base_effector_coordinates_homo[:3]  

    #return list(map(int, obj_base_coordinates)) # uncomment this line if you want to send integers instead of floats
    return np.around(obj_base_coordinates,2).tolist() # Use this to get a list of new coordinates, chane the number to get the number of decimal numbers

# Create DepthAI pipeline
pipeline = dai.Pipeline()

# Define camera nodes
cam_rgb   = pipeline.create(dai.node.ColorCamera)
mono_left  = pipeline.create(dai.node.MonoCamera)
mono_right = pipeline.create(dai.node.MonoCamera)
stereo     = pipeline.create(dai.node.StereoDepth)
detection_nn = pipeline.create(dai.node.YoloSpatialDetectionNetwork)  # Spatial NN for YOLO

# Define XLink outputs for streaming frames and detections to host
xout_rgb   = pipeline.create(dai.node.XLinkOut)
xout_depth = pipeline.create(dai.node.XLinkOut)
xout_nn    = pipeline.create(dai.node.XLinkOut)
xout_rgb.setStreamName("rgb")
xout_depth.setStreamName("depth")
xout_nn.setStreamName("detections")

# Camera configuration (RGB camera)
cam_rgb.setBoardSocket(dai.CameraBoardSocket.RGB)
cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_1080_P)
cam_rgb.setPreviewSize(416, 416)  # neural network input size for TinyYOLOv4
cam_rgb.setInterleaved(False)
cam_rgb.setColorOrder(dai.ColorCameraProperties.ColorOrder.BGR)

# Mono cameras (for depth)
mono_left.setBoardSocket(dai.CameraBoardSocket.LEFT)
mono_right.setBoardSocket(dai.CameraBoardSocket.RIGHT)
mono_left.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)
mono_right.setResolution(dai.MonoCameraProperties.SensorResolution.THE_400_P)

# Stereo depth configuration
stereo.setDefaultProfilePreset(dai.node.StereoDepth.PresetMode.HIGH_DENSITY)
stereo.setDepthAlign(dai.CameraBoardSocket.RGB)        # Align depth map to RGB camera perspective
stereo.setOutputSize(mono_left.getResolutionWidth(), 
                     mono_left.getResolutionHeight())
stereo.setSubpixel(True)  # improve depth precision

# Download and set neural network model (Tiny-YOLOv4 COCO 416x416)
blob_path = blobconverter.from_zoo(name="yolov4_tiny_coco_416x416", 
                                   zoo_type="depthai", 
                                   shaves=6)
detection_nn.setBlobPath(str(blob_path))
detection_nn.setConfidenceThreshold(0.5)
detection_nn.input.setBlocking(False)
detection_nn.setBoundingBoxScaleFactor(0.5)  # extra area for depth averaging
detection_nn.setDepthLowerThreshold(100)     # 100 mm -> 10 cm minimum distance
detection_nn.setDepthUpperThreshold(5000)    # 5000 mm -> 5 m maximum distance

# YOLO-specific network settings (for COCO Tiny-YOLOv4 416x416)
detection_nn.setNumClasses(80)
detection_nn.setCoordinateSize(4)
detection_nn.setAnchors([10,14, 23,27, 37,58, 81,82, 135,169, 344,319])
detection_nn.setAnchorMasks({ "side26": [1,2,3], "side13": [3,4,5] })
detection_nn.setIouThreshold(0.5)

# Link nodes: RGB -> Neural Network, Mono -> StereoDepth, Depth -> Neural Network
cam_rgb.preview.link(detection_nn.input)
mono_left.out.link(stereo.left)
mono_right.out.link(stereo.right)
stereo.depth.link(detection_nn.inputDepth)

# Link NN outputs to XLink outputs
detection_nn.passthrough.link(xout_rgb.input)           # passthrough RGB frames (frames that went into NN)
detection_nn.passthroughDepth.link(xout_depth.input)    # aligned depth frames
detection_nn.out.link(xout_nn.input)                    # detection outputs (bounding boxes + coordinates)

# Initialize the device and pipeline
with dai.Device(pipeline) as device:
    # Output queues to retrieve frames and detections
    q_rgb   = device.getOutputQueue(name="rgb", maxSize=4, blocking=False)
    q_depth = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    q_det   = device.getOutputQueue(name="detections", maxSize=4, blocking=False)

    # Get label names for COCO classes (for display purposes)
    label_map = [
        "person","bicycle","car","motorbike","aeroplane","bus","train","truck","boat",
        "traffic light","fire hydrant","stop sign","parking meter","bench","bird","cat",
        "dog","horse","sheep","cow","elephant","bear","zebra","giraffe","backpack","umbrella",
        "handbag","tie","suitcase","frisbee","skis","snowboard","sports ball","kite",
        "baseball bat","baseball glove","skateboard","surfboard","tennis racket","bottle",
        "wine glass","cup","fork","knife","spoon","bowl","banana","apple","sandwich",
        "orange","broccoli","carrot","hot dog","pizza","donut","cake","chair","sofa",
        "pottedplant","bed","diningtable","toilet","tvmonitor","laptop","mouse","remote",
        "keyboard","cell phone","microwave","oven","toaster","sink","refrigerator","book",
        "clock","vase","scissors","teddy bear","hair drier","toothbrush"
    ]  # COCO 80-class label list (indices 0-79)

    while True:
        in_rgb   = q_rgb.get()      # latest RGB frame
        in_depth = q_depth.get()    # latest depth frame (aligned to RGB)
        in_dets  = q_det.get()      # latest detection results

        frame = in_rgb.getCvFrame()               # OpenCV BGR frame from color camera
        depth_frame = in_depth.getFrame()         # depth data in millimeters
        detections = in_dets.detections           # list of spatial detections

        # Iterate over detections and draw bounding boxes and labels
        for det in detections:
            # Get bounding box coordinates (normalized 0..1 from NN, convert to pixel coords)
            x1 = int(det.xmin * frame.shape[1])
            y1 = int(det.ymin * frame.shape[0])
            x2 = int(det.xmax * frame.shape[1])
            y2 = int(det.ymax * frame.shape[0])

            # Draw rectangle on RGB frame
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)

            # Determine label text to display
            label = str(det.label)
            if det.label < len(label_map):
                label = label_map[det.label]
            conf  = int(det.confidence * 100)  # confidence percentage

            # Draw label and confidence
            cv2.putText(frame, f"{label} ({conf}%)", (x1+5, y1+20),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)

            # --- changed: use transform to show both camera and robot coords ---
            coords = det.spatialCoordinates  # spatial coordinates relative to camera (mm)
            xc, yc, zc = float(coords.x), float(coords.y), float(coords.z)
            #xr, yr, zr = cam_to_robot_xyz(xc, yc, zc)
            xr, yr, zr = convert_coordinates(xc, yc, zc, H_cam_to_robot) # our own old version that should do the same  

            # Camera-frame coords
            cv2.putText(frame, f"Xc: {int(xc)} mm", (x1+5, y1+35),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
            cv2.putText(frame, f"Yc: {int(yc)} mm", (x1+5, y1+50),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
            cv2.putText(frame, f"Zc: {int(zc)} mm", (x1+5, y1+65),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)

            # Robot-frame coords (optional on-screen)
            cv2.putText(frame, f"Xr: {int(xr)} mm", (x1+5, y1+80),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,255), 1)
            cv2.putText(frame, f"Yr: {int(yr)} mm", (x1+5, y1+95),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,255), 1)
            cv2.putText(frame, f"Zr: {int(zr)} mm", (x1+5, y1+110),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,255), 1)

            if label == "cup":
                print("cup (camera):", (xc, yc, zc), " -> (robot):", (xr, yr, zr))
            # --- end changed ---

        # Show the frames in windows
        cv2.imshow("RGB", frame)
        #cv2.imshow("Depth", depth_frame_disp)  # optional if you colorize depth

        # Exit on 'q' key
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

# Cleanup
cv2.destroyAllWindows()
