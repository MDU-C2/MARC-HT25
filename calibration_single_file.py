import socket
import cv2 as cv
import depthai as dai
import numpy as np
import blobconverter
import json
import time
import ast

host='192.168.125.1'
port=1025
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

try:
    client_socket.connect((host, port))
    print(f"Connected to {host}:{port}")
except ConnectionRefusedError:
    print(f"Connection refused.")

def get_coords():
    message = "Pos"
    client_socket.sendall(message.encode())  # Send message
    data = client_socket.recv(1024).decode('utf-8')  # Receive response
    time.sleep(0.1)
    _ = client_socket.recv(1024).decode('utf-8') # throw away ask message
    data_float = ast.literal_eval(data)
    return data_float

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
stereo.setDepthAlign(dai.CameraBoardSocket.RGB)        # Align depth map to RGB camera perspective:contentReference[oaicite:25]{index=25}
stereo.setOutputSize(mono_left.getResolutionWidth(), 
                     mono_left.getResolutionHeight())
stereo.setSubpixel(True)  # improve depth precision

# Download and set neural network model (Tiny-YOLOv4 COCO 416x416)
blob_path = blobconverter.from_zoo(name="yolov4_tiny_coco_416x416", 
                                   zoo_type="depthai", 
                                   shaves=6)
detection_nn.setBlobPath(str(blob_path))
detection_nn.setConfidenceThreshold(0.4)
detection_nn.input.setBlocking(False)
detection_nn.setBoundingBoxScaleFactor(0.5)  # extra area for depth averaging
detection_nn.setDepthLowerThreshold(100)     # 100 mm -> 10 cm minimum distance:contentReference[oaicite:26]{index=26}
detection_nn.setDepthUpperThreshold(5000)    # 5000 mm -> 5 m maximum distance:contentReference[oaicite:27]{index=27}

# YOLO-specific network settings (for COCO Tiny-YOLOv4 416x416)
detection_nn.setNumClasses(80)
detection_nn.setCoordinateSize(4)
detection_nn.setAnchors([10,14, 23,27, 37,58, 81,82, 135,169, 344,319])       # from model config:contentReference[oaicite:28]{index=28}
detection_nn.setAnchorMasks({ "side26": [1,2,3], "side13": [3,4,5] })         # YOLOv4-tiny masks:contentReference[oaicite:29]{index=29}
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
    ]  # COCO 80-class label list (indices 0-79):contentReference[oaicite:30]{index=30}:contentReference[oaicite:31]{index=31}

    Saved_Coordinates = []
    saved_robo_coordinates = []

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
                # Get bounding box coordinates (normalized 0..1 from NN, convert to pixel coords)
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
                
                if cv.waitKey(1) & 0xFF == ord(' '):
                    Saved_Coordinates.append([coords.x,coords.y,coords.z])
                    robot_position = get_coords()
                    saved_robo_coordinates.append(robot_position)
                    print("coordinates saved", len(Saved_Coordinates))

        # Show the frames in windows
        cv.imshow("RGB", frame)

        # Exit on 'q' key
        if cv.waitKey(1) & 0xFF == ord('q'):
            client_socket.close()
            print("Connection closed.")
            break

with open('saved_coordinates.txt', 'w') as f:
    for coords in Saved_Coordinates:
        f.write("%s\n" % coords)
with open('robo_coords.txt', 'w') as f:
    for rcoords in saved_robo_coordinates:
        f.write("%s\n" % rcoords)

print(Saved_Coordinates)
cv.destroyAllWindows()