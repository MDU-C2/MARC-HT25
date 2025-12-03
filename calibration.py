import socket
import cv2 as cv
import depthai as dai
import numpy as np
import json
import time
import ast
import Camera_Setup as cs
from updated_communication import Communication
import random

client = Communication()
client.connect()

_, pipeline, label_map = cs.cam_calibration()

count = 0
positions = []
num_positions = input("how many positions do you want to save for the calibration?: ")
if num_positions.isdigit() == False:
    print("invalid input, setting to 10 positions")
    num_positions = 10
num_positions = int(num_positions)
num_positions_copy = num_positions

random_pos = input("do you want to have random positions for the calibration? (y/n): ").lower()
if random_pos == 'y':

    for i in range(num_positions):
        rand_num = random.randint(1,40)
        if rand_num not in positions:
            positions.append(rand_num)
        else:
            num_positions += 1
else:
    for i in range(num_positions):
        positions.append(i+1)

# Initialize the device and pipeline
with dai.Device(pipeline) as device:
    # Output queues to retrieve frames and detections
    q_rgb   = device.getOutputQueue(name="rgb", maxSize=4, blocking=False)
    q_depth = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
    q_det   = device.getOutputQueue(name="detections", maxSize=4, blocking=False)


    Saved_Coordinates = []
    saved_robo_coordinates = []
    client.MoveCalibrationPosition(positions[count])
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

            if label == "Gripper": # Only process non-gripper detections (cups)
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
                        robot_position = client.GetPosition()# get coordinates from robot
                    except:
                        print("error getting coordinates from robot")
                    saved_robo_coordinates.append(robot_position) # save robot coordinates
                    print("coordinates saved", len(Saved_Coordinates))
                    print("Robot:", robot_position)
                    print("Camera", [coords.x,coords.y,coords.z])
                    count += 1
                    if count < num_positions_copy:
                        client.MoveCalibrationPosition(positions[count])
                    else:
                        print("all positions saved")
                        break
                    


        # Show the frames in windows
        cv.imshow("RGB", frame)

        if count >= num_positions_copy:
            break
        # Exit on 'q' key
        if cv.waitKey(1) & 0xFF == ord('q'):
            # client_socket.close() #close connection to server
            # print("Connection closed.")
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