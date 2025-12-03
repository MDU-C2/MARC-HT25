import cv2 as cv
import depthai as dai
import numpy as np
import json
import math
import time
from updated_communication import Communication
from copy import deepcopy
import Camera_Setup as cs
import test_protocol as tp



quaternion = [1,0,0,0] # Dump value, not used in robot but needs to be sent.
cam_coords = 'saved_coordinates.txt' # Path to camera coordinates .txt file
robot_file = 'robo_coords.txt' # Path to robot coordinates .txt file
client = Communication()
client.connect()


homogeneous, syncNN, pipeline, labels, rotation_matrix, translation_vector, camera_points, robot_points = cs.camera_setup(cam_coords, robot_file)
#==================================== TEST PROTOCOL SETUP ====================================
count = 0
times_sec = []

save_protocol = input("Do you want to save the test protocol? (y/n): ").lower() == 'y'
if save_protocol:
    file_path = tp.create_today_textfile()
    tp.ask_user(file_path, "start")
    tp.fill_meta_data(file_path)



rms_error = cs.rms_alignment_error(camera_points, robot_points, rotation_matrix, translation_vector)
if save_protocol:
    tp.log_rms_error(file_path, rms_error)




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
            if not (coords.z == 0.0 or coords.z > 1500 or (coords.x < -150 and coords.y > 90 and coords.z > 800) or (coords.z > 1046) and (det == "gripper")): # Fix to not use invalid coordinates while the camera is auto focusing
                coordinates = cs.convert_coordinates(coords.x,coords.y,coords.z, homogeneous) # Convert camera coordinates to robot coordinates (RTF)

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
                        client.Move(temp_coords, quaternion, [1,0,0])
                        rob_coords = client.GetPosition()
                        #rob_coords = [temp_coords[0]+10, temp_coords[1]+10, temp_coords[2]] # Dummy robot coordinates for testing without robot
                        end_time = time.time()
                        process_time = end_time - start_time
                        if save_protocol:
                            count += 1
                            tp.cup_information(file_path, count, temp_coords, rob_coords, process_time , confidence = conf, label= label)
                            times_sec.append(process_time)

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

if save_protocol:
    tp.ask_user(file_path, "end")
    tp.log_time_summary(file_path, times_sec)