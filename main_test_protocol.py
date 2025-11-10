import cv2 as cv
import depthai as dai
import numpy as np
import json
import math
import time
from send_coords import CupPickingClient
from copy import deepcopy
import test_protocol as tp

#model = 'best.pt' # Path to the model that should be used
cam_coords = 'saved_coordinates.txt' # Path to camera coordinates .txt file
robot_file = 'robo_coords.txt' # Path to robot coordinates .txt file
quaternion = [1,0,0,0] # Dump value, not used in robot but needs to be sent.

#==================================== TEST PROTOCOL SETUP ====================================
count = 0
save_protocol = input("Do you want to save the test protocol? (y/n): ").lower() == 'y'
if save_protocol:
    file_path = tp.create_today_textfile()
    tp.ask_user(file_path)
    tp.fill_meta_data(file_path)

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

#==================================== CAMERA & COMMUNICATION SETUP ====================================

client = CupPickingClient()
client.connect()
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
cam_rgb.setResolution(dai.ColorCameraProperties.SensorResolution.THE_1080_P)
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

# Initialize the device and pipeline
first_run = True
with dai.Device(pipeline) as device:
    # Output queues to retrieve frames and detections
    q_rgb   = device.getOutputQueue(name="rgb", maxSize=4, blocking=False)
    q_depth = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    q_det   = device.getOutputQueue(name="detections", maxSize=4, blocking=False)

    prev_coord = [[1,1,1]] # Temporary starting x,y,z coordinates to compare with
    obj_list = []
    
    while True:

        in_rgb   = q_rgb.get() # latest RGB frame
        in_depth = q_depth.get() # latest depth frame (aligned to RGB)
        in_dets  = q_det.get() # latest detection results

        out_frame = in_rgb.getCvFrame()
        frame = in_rgb.getCvFrame() # OpenCV BGR frame from color camera
        depth_frame = in_depth.getFrame() # Depth data in millimeters
        detections = in_dets.detections # List of spatial detections

        # This allows the camera to focus before it starts looking for detections
        if(first_run):
             time.sleep(1)
             first_run = False
        
        # Iterate over detections and draw bounding boxes and labels
        for det in detections:
            
            # Determine label text to display
            label = str(det.label)
            if det.label < len(labels):
                label = labels[det.label]

            conf  = int(det.confidence * 100) # Confidence percentage

            # Get bounding box coordinates
            x1 = int(det.xmin * frame.shape[1])
            y1 = int(det.ymin * frame.shape[0])
            x2 = int(det.xmax * frame.shape[1])
            y2 = int(det.ymax * frame.shape[0])

            # Draw rectangle on RGB frame
            cv.rectangle(frame, (x1, y1), (x2, y2), (0,255,0), 2)

            # Draw label and confidence
            cv.putText(frame, f"{label} ({conf}%)", (x1+5, y1+20), cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)

            # Draw spatial coordinates (X, Y, Z in mm)
            coords = det.spatialCoordinates  # Spatial coordinates relative to camera
            cv.putText(frame, f"X: {int(coords.x)} mm", (x1+5, y1+35), cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
            cv.putText(frame, f"Y: {int(coords.y)} mm", (x1+5, y1+50), cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
            cv.putText(frame, f"Z: {int(coords.z)} mm", (x1+5, y1+65), cv.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,255), 1)
            cv.imshow("RGB", frame)
            if not (coords.z == 0.0 or coords.z > 1500 or (coords.x < -150 and coords.y > 90 and coords.z > 800) or (coords.y < -100)): # Fix to not use invalid coordinates while the camera is auto focusing
                coordinates = convert_coordinates(coords.x,coords.y,coords.z, homogeneous) # Convert camera coordinates to robot coordinates (RTF)

                in_list = False
                for i in prev_coord:
                    print(i)
                    if (math.isclose(coordinates[0],i[0], abs_tol= 10) or math.isclose(coordinates[1],i[1], abs_tol= 10)):
                        in_list = True
            
                if not in_list:
                    obj_list.append(coordinates)
                    prev_coord = deepcopy(obj_list)

                if obj_list:
                    try:

                        temp_coords = obj_list.pop(0)
                        start_time = time.time()
                        client.move_cup_test(temp_coords, quaternion)

                        rob_coords = client.get_coords()

                        client.leave_cup()
                        end_time = time.time()
                        if save_protocol:
                            count += 1

                            with open(file_path, "a") as f:
                                f.write(f"------- Cup {count} Coordinates -------\n")
                                f.write(f"Camera Coordinates: {temp_coords}\n")
                                f.write(f"Robot Coordinates: {rob_coords}\n\n")
                                f.write(f"Time taken for pick and place: {end_time - start_time:.3f} seconds\n\n")
                                f.write(f"RMS Alignment Error: {rms_alignment_error(temp_coords, rob_coords, rotation_matrix, translation_vector):.3f} mm\n\n")

                        prev_coord = deepcopy(obj_list)
                    except Exception as e:
                        print(f"Error {e}")

            # Show the frames in windows
        cv.imshow("RGB", frame)

        # Exit on 'q' key
        if cv.waitKey(1) & 0xFF == ord('q'):
            cv.imwrite("test.jpg", out_frame)
            break

cv.destroyAllWindows()