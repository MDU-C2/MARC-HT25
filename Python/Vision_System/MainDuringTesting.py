import cv2 as cv
import numpy as np
import depthai as dai
import math
import time
from updated_communication import Communication
import camera_setup as cs
import test_protocol as tp
import threading
#==================================== THREADING SETUP ====================================
global busy, times_sec, count
busy = False
count = 0
times_sec = []

lock = threading.Lock()

#Thread function to move robot to specified coordinates
def local_move(orient, client, obj_list, normalized_vector, save_protocol ,file_path, conf=None, label=None):
    global busy, times_sec, count
    with lock:
        if busy != True:
            start_time = time.time()
            busy = True

            # ADD MUG SEQUENCE HERE

            client.PickUpSequence(obj_list[0], orient, normalized_vector)
            # client.Move(obj_list[0], orient, normalized_vector)
            
            client.MoveHome()
            
            end_time = time.time()
            process_time = end_time - start_time
            if save_protocol:
                count += 1
                tp.cup_information(file_path, count, obj_list[0], process_time , confidence = conf, label= label)

                times_sec.append(process_time)
            obj_list.pop(0)
            busy = False

def run():
    global busy, times_sec
    file_path = None
    normalized_vector = [0,0,1] # Initial orientation vector for the gripper
    #Normalized orientation vectors for different cup orientations
    orientation_map = {
            'Back': [ 0.0, 0.0,-1.0],
            'Front': [0.0, 0.0,1.0],
            'left_side': [-1.0, 0.0, 0.0],
            'right_side': [1.0, 0.0, 0.0],
            'upright': [0.0, 1.0 ,0.0],
            'upside_down': [0.0, -1.0, 0.0],
            'Gripper': [0.0, 0.0, -1.0],
        }
    quaternion = [1,0,0,0] # Dump value, not used in robot but needs to be sent.
    cam_coords = 'saved_coordinates.txt' # Path to camera coordinates .txt file
    robot_file = 'robo_coords.txt' # Path to robot coordinates .txt file
    client = Communication()
    
    
    if client.connectV2(): 



        homogeneous, syncNN, pipeline, labels, rotation_matrix, translation_vector, camera_points, robot_points = cs.camera_setup(cam_coords, robot_file)
        
        #==================================== TEST PROTOCOL SETUP ====================================


        save_protocol = False;#input("Do you want to save the test protocol? (y/n): ").lower() == 'y'
        if save_protocol:
            file_path = tp.create_today_textfile()
            tp.ask_user(file_path, "start")
            tp.fill_meta_data(file_path)
            rms_error = cs.rms_alignment_error(camera_points, robot_points, rotation_matrix, translation_vector)
            tp.log_rms_error(file_path, rms_error)



        #==================================== MAIN  ====================================

        first_run = True
        with dai.Device(pipeline) as device:
            # Output queues to retrieve frames and detections
            q_rgb   = device.getOutputQueue(name="rgb", maxSize=4, blocking=False)
            q_depth = device.getOutputQueue(name="depth", maxSize=4, blocking=False)
            q_det   = device.getOutputQueue(name="detections", maxSize=4, blocking=False)


            obj_list = []
            
            while True:
                in_rgb   = q_rgb.get() # latest RGB frame
                in_depth = q_depth.get() # latest depth frame (aligned to RGB)
                in_dets  = q_det.get() # latest detection results


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
                    if label != "handle":


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


                        if busy == False and label != "Gripper":

                            # should not add hard coded values for offset
                            if (cv.waitKey(1) & 0xFF == ord(' ')): # Fix to not use invalid coordinates while the camera is auto focusing
                                coordinates = cs.convert_coordinates(coords.x,coords.y,coords.z, homogeneous) # Convert camera coordinates to robot coordinates (RTF)

                                in_list = False
                                for i in obj_list:

                                    if (math.isclose(coordinates[0],i[0], abs_tol= 10) or math.isclose(coordinates[1],i[1], abs_tol= 10)):
                                        in_list = True
                            

                                with lock:
                                    if not in_list:
                                        obj_list.append(coordinates)

                                if obj_list:    
                                    try:    
                                        normalized_vector = orientation_map.get(label)
                                        norm = np.matmul(rotation_matrix,normalized_vector)#[0,0,-1])
                                        print(f"[DEBUGG] normal vector: {normalized_vector}")
                                        if (abs(normalized_vector[1]) < abs(normalized_vector[2])) or (abs(normalized_vector[1]) <  abs(normalized_vector[0])): # robot z not the biggest value -> mug is not up nor down
                                            norm -= [0,0,np.dot(norm,[0,0,1])]
                                            norm =  norm/np.sqrt(np.dot(norm,norm))
                                            np.set_printoptions(precision=3)
                                        else:
                                            # standing upright
                                            norm[2] = normalized_vector[1]/abs(normalized_vector[1])
                                            norm[1] = 0
                                            norm[0] = 0

                                        print(f"[DEBUGG] normal vector after matrix: {norm}")
                                        threading.Thread(target=local_move, args=(quaternion, client, obj_list, [float(norm[0]),float(norm[1]),float(norm[2])], save_protocol, file_path, conf, label), daemon=True).start()
                                    except Exception as e:
                                        print(f"Error {e}")

                    # Show the frames in windows
                cv.imshow("RGB", frame)
                if cv.waitKey(1) & 0xFF == ord('r'):
                    client.connect()
                # Exit on 'q' key
                if cv.waitKey(1) & 0xFF == ord('q'):

                    break

        cv.destroyAllWindows()

        if save_protocol:
            tp.ask_user(file_path, "end")
            tp.log_time_summary(file_path, times_sec)

if __name__ == "__main__":
    run()