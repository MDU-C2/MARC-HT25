import cv2 as cv
import depthai as dai
import numpy as np
import blobconverter
import json

cam_coords = 'path/to/cam/coords' 
robot_file = 'path/to/robot/coords'
quaternion = [1,0,0,0] # dump value, not used in robot but needs to be sent.

def json_converter(coordinates, quaternion):
    data = [coordinates, quaternion] # We store the coordinates and quaternion in a list so that it can be easily accessible.

    # The layout/structure of the JSON file
    cup = {
        "id":"cup_1",
        "status": "Available",
        "position":{
            "x": data[0][0],
            "y": data[0][1],
            "z": data[0][2]
        },
        "orientation":{
            "q1": float(data[1][0]),
            "q2": float(data[1][1]),
            "q3": float(data[1][2]),
            "q4": float(data[1][3])
        },
        "approach_position":{
            "x": data[0][0],
            "y": data[0][1],
            "z": data[0][2]
        }
    }

    cup_data = {"cups": cup}

    with open("cups.json", "w") as f:
        json.dump(cup_data, f, indent=2)


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


def estimate_rigid_transform(camera_points, robot_points):
    cam = np.asarray(camera_points, dtype=np.float64)
    rob = np.asarray(robot_points,  dtype=np.float64)
    assert cam.shape == rob.shape and cam.shape[1] == 3 and cam.shape[0] >= 3, "Value error, differing amount of coordinates, Camera:" + str(len(cam)) + " Robot:"+ str(len(rob))
    

    camera_centroid = cam.mean(axis=0)
    robot_centroid  = rob.mean(axis=0)
    camera_centered = cam - camera_centroid
    robot_centered  = rob - robot_centroid

    cross_covariance = camera_centered.T @ robot_centered
    U, s, Vt = np.linalg.svd(cross_covariance)
    V = Vt.T

    # Ensure of proper rotation (det=+1)
    det_correction = np.sign(np.linalg.det(V @ U.T))
    rotation_matrix = V @ np.diag([1.0, 1.0, det_correction]) @ U.T

    translation_vector = robot_centroid - rotation_matrix @ camera_centroid
    return rotation_matrix, translation_vector

def rms_alignment_error(camera_points, robot_points, rotation_matrix, translation_vector):
    cam = np.asarray(camera_points, dtype=np.float64)
    rob = np.asarray(robot_points,  dtype=np.float64)
    t = np.asarray(translation_vector, dtype=np.float64).reshape(1, 3)
    predicted_robot_points = (rotation_matrix @ cam.T).T + t
    squared_errors = np.sum((predicted_robot_points - rob) ** 2, axis=1)
    rms_error = float(np.sqrt(np.mean(squared_errors)))
    return rms_error

def extract_data(file):
    float_list=[]
    with open(file, "r") as f:
        lines = f.readlines()
        for i in lines:
            x = json.loads(i)
            float_list.append(x)
    return list(float_list)

camera_points = extract_data(cam_coords) # get coordinates from the camera 
robot_points = extract_data(robot_file) # get coordinats from the robot (both .txt files)
rotation_matrix, translation_vector = estimate_rigid_transform(camera_points, robot_points) # Do an estimation from both the 3d robot and camera coordinates to get rotation matrix and translation vector
homogeneous = build_homogeneous(rotation_matrix,translation_vector) # convert the rotation and translation into a 4x4 homogeneous matrix that can be used to convert camera coordinates into robotframe

# Create DepthAI pipeline
pipeline = dai.Pipeline()

# Define the camera nodes
cam_rgb   = pipeline.create(dai.node.ColorCamera)
mono_left  = pipeline.create(dai.node.MonoCamera)
mono_right = pipeline.create(dai.node.MonoCamera)
stereo     = pipeline.create(dai.node.StereoDepth)
detection_nn = pipeline.create(dai.node.YoloSpatialDetectionNetwork)

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
stereo.setDepthAlign(dai.CameraBoardSocket.RGB)       
stereo.setOutputSize(mono_left.getResolutionWidth(), 
                     mono_left.getResolutionHeight())
stereo.setSubpixel(True)  # improve depth precision

# Download and set neural network model (Tiny-YOLOv4 COCO 416x416) <------- THIS CAN BE WHATEVER MODEL THAT EXISTS IN THE DEPTHAI ZOO
blob_path = blobconverter.from_zoo(name="yolov4_tiny_coco_416x416", 
                                   zoo_type="depthai", 
                                   shaves=6)
detection_nn.setBlobPath(str(blob_path))
detection_nn.setConfidenceThreshold(0.5)
detection_nn.input.setBlocking(False)
detection_nn.setBoundingBoxScaleFactor(0.5)
detection_nn.setDepthLowerThreshold(100)     
detection_nn.setDepthUpperThreshold(5000)    

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
detection_nn.passthrough.link(xout_rgb.input)      # passthrough RGB frames (frames that went into NN)
detection_nn.passthroughDepth.link(xout_depth.input)  # aligned depth frames
detection_nn.out.link(xout_nn.input)              # detection outputs (bounding boxes + coordinates)

# Initialize the device and pipeline
with dai.Device(pipeline) as device:
    # Output queues to retrieve frames and detections
    q_rgb   = device.getOutputQueue(name="rgb", maxSize=4, blocking=False)
    q_depth = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    q_det   = device.getOutputQueue(name="detections", maxSize=4, blocking=False)

    # Get label names for COCO classes
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
    ]
    while True:
        in_rgb   = q_rgb.get()      # latest RGB frame
        in_depth = q_depth.get()    # latest depth frame (aligned to RGB)
        in_dets  = q_det.get()      # latest detection results

        frame = in_rgb.getCvFrame()               # OpenCV BGR frame from color camera
        depth_frame = in_depth.getFrame()         # depth data in millimeters
        detections = in_dets.detections           # list of spatial detections

        # Iterate over detections and draw bounding boxes and labels (SET TO ONLY DISPLAY CUPS AT THE MOMENT)
        for det in detections:
            
            # Determine label text to display
            label = str(det.label)
            if det.label < len(label_map):
                label = label_map[det.label]
            conf  = int(det.confidence * 100)  # confidence percentage

            if label == "cup":
                # Get bounding box coordinates
                x1 = int(det.xmin * frame.shape[1])
                y1 = int(det.ymin * frame.shape[0])
                x2 = int(det.xmax * frame.shape[1])
                y2 = int(det.ymax * frame.shape[0])

                # Draw rectangle on RGB frame
                cv.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)

                # Draw label and confidence
                cv.putText(frame, f"{label} ({conf}%)", (x1+5, y1+20),
                            cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)

                # Draw spatial coordinates (X, Y, Z in mm)
                coords = det.spatialCoordinates  # spatial coordinates relative to camera
                cv.putText(frame, f"X: {int(coords.x)} mm", (x1+5, y1+35),
                            cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
                cv.putText(frame, f"Y: {int(coords.y)} mm", (x1+5, y1+50),
                            cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
                cv.putText(frame, f"Z: {int(coords.z)} mm", (x1+5, y1+65),
                            cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)

                coordinates = convert_coordinates(coords.x,coords.y,coords.z, homogeneous) # Convert camera coordinates to robot coordinates (RTF)
                json_converter(coordinates, quaternion)
                

        # Show the frames in windows
        cv.imshow("RGB", frame)

        # Exit on 'q' key
        if cv.waitKey(1) & 0xFF == ord('q'):
            break

cv.destroyAllWindows()
