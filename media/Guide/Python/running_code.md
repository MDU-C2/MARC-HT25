<h1 align="center">
  <br>
  <br>
  <img src="https://raw.githubusercontent.com/MDU-C2/MARC-HT25/developer/media/images/camera_to_rob_frame.png" width="600" alt="walkthrough banner">
  <br>
  <br>
  This walkthrough tells how to run the vision system on for this project.
  <br>
</h1>
<!--
  Lägg in mer här?
  <h4 align="center">This walkthrough tells how to run the vision system on for this project. </h4>
-->


## Calibration
The first step is to start the server from **RAPID** as shown in [this guide](/media/Guide/Yumi%20IRB%2014000/communication_rapid.md) 

Now run the code

```bash
# Run the calibration code
> py calibration_single_file.py
# Now a program should start
```
It is important to note that the quality of the calibration relies on how many positions are captured and that the calibration is done thoroughly and precise. It is also very important to have the gripper in a position as in you want it to grap the mug, since the calibration will capture the coordinates with the grippers relation to the mug.

* Move the gripper into a desired grabbing position of a mug using **Leadthrough** on the flexpendant. It is important that the Gripper is in the exact same position relative to the mug troughtout the entire calibration process. 
* When you see a stable detection in the program press **Space** in the running python program. This needs to be one atleast 3 times otherwise it will not work, but more position equals better calibration. For our tests we use 10-15 calibration positions. 
* When all desired positions have been captured, press **Q** on your keyboard which will close the program and save the positions to .txt files.
* Now 2 files should have been created **robo_coords.txt** and **saved_coords.txt**. These files contain positions of the mug captured in the camera frame and where the grippers location in the robots frame.
* These coordinates are used in the main file to calculate the translation between the camera and the robot, so that coordinates of objects in the camera frame can be translated to the robot frame.
## Running the main code
To run the main python script, first the server needs to be started from RAPID.
```bash
# Run the main code 
> py main.py
```
This code will run the object detection and send the coordinates of the mugs to the robot. The robot will then go to the mug, attempt to pick it up and place it in a set location, then send a confirmation to the python script that the task is done. Python will then send the next cup location (if there are any) and this will continue until the program is closed.