import cv2 as cv
import depthai as dai
import numpy as np
import json




#==================================== FUNCTIONS ====================================
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
    
    #return list(map(int, obj_base_coordinates)) # Uncomment this line if you want to send integers instead of floats
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

def cam_calibration():
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
    cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_720_P)
    cam_rgb.setPreviewSize(640, 640) # Neural network input size. (MUST MATCH THE RUNNING MODELS SIZE)
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
    stereo.setOutputSize(mono_left.getResolutionWidth(), mono_left.getResolutionHeight())
    stereo.setSubpixel(True) 

    configPath = "new_blob_v8/best_Nano.json" # Path to the config JSON file for the model (MUST BE CHANGED IF YOU WANT TO USE A NEW MODEL)
    with open(configPath, "r") as f:
        config = json.load(f)
    nnConfig = config.get("nn_config", {})

    # Extract the metadata from the JSON file
    metadata = nnConfig.get("NN_specific_metadata", {})
    classes = metadata.get("classes", {})
    coordinates = metadata.get("coordinates", {})
    anchors = metadata.get("anchors", {})
    anchorMasks = metadata.get("anchor_masks", {})
    iouThreshold = metadata.get("iou_threshold", {})
    confidenceThreshold = metadata.get("confidence_threshold", {})

    print(metadata)

    nnMappings = config.get("mappings", {})
    labels = nnMappings.get("labels", {})

    nnPath = "new_blob_v8/best_Nano_openvino_2022.1_6shave.blob" # PATH TO THE .BLOB FILE (MUST BE CHANGED IF YOU WANT TO USE A NEW MODEL)

    # Specific settings for the network
    detection_nn.setConfidenceThreshold(confidenceThreshold)
    detection_nn.setNumClasses(classes)
    detection_nn.setCoordinateSize(coordinates)
    detection_nn.setAnchors(anchors)
    detection_nn.setAnchorMasks(anchorMasks)
    detection_nn.setIouThreshold(iouThreshold)
    detection_nn.setBlobPath(nnPath)
    detection_nn.setNumInferenceThreads(2)
    detection_nn.input.setBlocking(False)

    syncNN = True

    # Linking
    cam_rgb.preview.link(detection_nn.input)
    mono_left.out.link(stereo.left)
    mono_right.out.link(stereo.right)
    stereo.depth.link(detection_nn.inputDepth)

    detection_nn.passthrough.link(xout_rgb.input) # Passthrough RGB frames (frames that went into NN)
    detection_nn.passthroughDepth.link(xout_depth.input) # Aligned depth frames
    detection_nn.out.link(xout_nn.input) # Detection outputs (bounding boxes + coordinates)

    return  syncNN, pipeline, labels


    #==================================== CAMERA & COMMUNICATION SETUP ====================================
def camera_setup(cam_coords, robot_file):


    camera_points = extract_data(cam_coords) # Get coordinates from the camera 
    robot_points = extract_data(robot_file) # Get coordinats from the robot (both .txt files)
    rotation_matrix, translation_vector = estimate_rigid_transform(camera_points, robot_points) # Do an estimation from both the 3d robot and camera coordinates to get rotation matrix and translation vector
    homogeneous = build_homogeneous(rotation_matrix,translation_vector) # Convert the rotation and translation into a 4x4 homogeneous matrix that can be used to convert camera coordinates into robotframe

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
    cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_720_P)
    cam_rgb.setPreviewSize(640, 640) # Neural network input size. (MUST MATCH THE RUNNING MODELS SIZE)
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
    stereo.setOutputSize(mono_left.getResolutionWidth(), mono_left.getResolutionHeight())
    stereo.setSubpixel(True) 

    configPath = "blob_v8/best.json" # Path to the config JSON file for the model (MUST BE CHANGED IF YOU WANT TO USE A NEW MODEL)
    with open(configPath, "r") as f:
        config = json.load(f)
    nnConfig = config.get("nn_config", {})

    # Extract the metadata from the JSON file
    metadata = nnConfig.get("NN_specific_metadata", {})
    classes = metadata.get("classes", {})
    coordinates = metadata.get("coordinates", {})
    anchors = metadata.get("anchors", {})
    anchorMasks = metadata.get("anchor_masks", {})
    iouThreshold = metadata.get("iou_threshold", {})
    confidenceThreshold = metadata.get("confidence_threshold", {})

    print(metadata)

    nnMappings = config.get("mappings", {})
    labels = nnMappings.get("labels", {})

    nnPath = "blob_v8/best_openvino_2022.1_6shave.blob" # PATH TO THE .BLOB FILE (MUST BE CHANGED IF YOU WANT TO USE A NEW MODEL)

    # Specific settings for the network
    detection_nn.setConfidenceThreshold(confidenceThreshold)
    detection_nn.setNumClasses(classes)
    detection_nn.setCoordinateSize(coordinates)
    detection_nn.setAnchors(anchors)
    detection_nn.setAnchorMasks(anchorMasks)
    detection_nn.setIouThreshold(iouThreshold)
    detection_nn.setBlobPath(nnPath)
    detection_nn.setNumInferenceThreads(2)
    detection_nn.input.setBlocking(False)

    syncNN = True

    # Linking
    cam_rgb.preview.link(detection_nn.input)
    mono_left.out.link(stereo.left)
    mono_right.out.link(stereo.right)
    stereo.depth.link(detection_nn.inputDepth)

    detection_nn.passthrough.link(xout_rgb.input) # Passthrough RGB frames (frames that went into NN)
    detection_nn.passthroughDepth.link(xout_depth.input) # Aligned depth frames
    detection_nn.out.link(xout_nn.input) # Detection outputs (bounding boxes + coordinates)

    return homogeneous, syncNN, pipeline, labels, rotation_matrix, translation_vector, camera_points, robot_points