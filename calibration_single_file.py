import socket
import cv2 as cv
import depthai as dai
import numpy as np
import json
import time
import ast
import Camera_Setup as cs

host='192.168.125.1' #Input server (robot) ip
port=1025 #Input used port
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM) #initialize client socket object, (IPv4, TCP)

try:
    client_socket.connect((host, port)) #simply connect the client (this code) to the robot
    print(f"Connected to {host}:{port}") #if successfull
except ConnectionRefusedError:
    print(f"Connection refused.") # If failure, (server probably not started or wrong values)

def get_coords():
    message = "Pos" # "Pos" is the command to get coordinates from robot
    client_socket.sendall(message.encode())  # Send message 
    data = client_socket.recv(1024).decode('utf-8')  # Receive response
    time.sleep(0.1) # To not cause issue with the followup "ask_next" message
    _ = client_socket.recv(1024).decode('utf-8') # throw away ask message
    data_float = ast.literal_eval(data) #Covert the string that looks like a list into a actual list
    return data_float


_, _, pipeline, label_map = cs.camera_setup()

# Initialize the device and pipeline
with dai.Device(pipeline) as device:
    # Output queues to retrieve frames and detections
    q_rgb   = device.getOutputQueue(name="rgb", maxSize=4, blocking=False)
    q_depth = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    q_det   = device.getOutputQueue(name="detections", maxSize=4, blocking=False)


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

            if label != "gripper": # Only process non-gripper detections (cups)
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
                    Saved_Coordinates.append([coords.x,coords.y,coords.z]) # save camera coordinates
                    try:
                        robot_position = get_coords() # get coordinates from robot
                    except:
                        print("error getting coordinates from robot")
                    saved_robo_coordinates.append(robot_position) # save robot coordinates
                    print("coordinates saved", len(Saved_Coordinates))
                    print("Robot:", robot_position)
                    print("Camera", [coords.x,coords.y,coords.z])

        # Show the frames in windows
        cv.imshow("RGB", frame)

        # Exit on 'q' key
        if cv.waitKey(1) & 0xFF == ord('q'):
            client_socket.close() #close connection to server
            print("Connection closed.")
            break # kill pipeline

# both these files are needed to run the main file, as they are used when converting camera fram into robot frame 
with open('saved_coordinates.txt', 'w') as f: 
    for coords in Saved_Coordinates:
        f.write("%s\n" % coords) #saves the camera coordinates to a .txt file
with open('robo_coords.txt', 'w') as f:
    for rcoords in saved_robo_coordinates:
        f.write("%s\n" % rcoords) # saves the robot coordinates to a .txt file 

print("Camera coordinates:", Saved_Coordinates)
print("Robot coordinates:", saved_robo_coordinates)
cv.destroyAllWindows()