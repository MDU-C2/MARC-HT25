<h1 align="center">
  <br>
  <br>
  <img src="https://raw.githubusercontent.com/MDU-C2/MARC-HT25/developer/media/images/camera_to_rob_frame.png" width="600" alt="walkthrough banner">
  <br>
  <br>
  Walkthrough of the vision system.
  <br>
</h1>
<!--
  Lägg in mer här?
  <h4 align="center">This walkthrough tells how to run the vision system on for this project. </h4>
-->


## Calibration
The first step is to start the server from **RAPID** as shown in [this guide](/media/Guide/Yumi%20IRB%2014000/how_to_start_rapid.md) 

It is important to note that the quality of the calibration relies on how many positions are captured and that the calibration is done thoroughly and precise, which is why we have made the calibration fully automatic. To get started run the code: 

```bash
# Run the calibration code
> py auto_calibration.py
# Now a program should start
```

* You will be prompted to enter the amount of calibration positions that you want to use (at least 3 positions are needed for the calibration to work although we recomend running as many positions as possible to get the best calibration. In our case we have used 80 calibration positions). 

* You will then be asked if you want a specific starting index (defaults to the first position if the user inputs "n" or an invalid starting point).

* When the program has loaded you have to press **space** to start the calibration. Then the robot will start the automatic calibration. When the calibration is done the program will close and two .txt files will appear (**robo_coords.txt** and **saved_coords.txt**). These files contain positions of the aruco tag on the gripper in the camera frame and the grippers location in the robot frame. These coordinates are used in the main file to calculate the translation between the camera and the robot, which in turn ensures that the object coordinates in the camera frame can correctly be translated to the robot frame.

<!-- It is important to note that the quality of the calibration relies on how many positions are captured and that the calibration is done thoroughly and precise. It is also very important to have the gripper in the same position as you want it to grab the mug, since the calibration will capture the coordinates with the grippers relation to the mug. **For example:** If you want the robot to grab the mug from the right hand side, you would calibrate with positions where the gripper is grasping from the right hand side.

* Move the gripper into a desired grabbing position of a mug using **Leadthrough** on the flexpendant. It is important that the Gripper is in the exact same position relative to the mug troughtout the entire calibration process. 
* When you see a stable detection in the program press **Space** in the running Python program. This needs to be done atleast 3 times otherwise it will not work, but more position equals better calibration. For our tests we use 10-15 calibration positions. 
* When all desired positions have been captured, press **Q** on your keyboard which will close the program and save the positions to .txt files.
* Now 2 files should have been created **robo_coords.txt** and **saved_coords.txt**. These files contain positions of the mug captured in the camera frame and where the grippers location in the robots frame.
* These coordinates are used in the main file to calculate the translation between the camera and the robot, so that coordinates of objects in the camera frame can be translated to the robot frame. -->
## Running the main code
To run the main Python script the server needs to be started from RAPID first. When the server is up and running do:
```bash
# Run the main code 
> py main.py
```
This code will run the object detection and send the coordinates of the mugs to the robot. The robot will then go to the mug, attempt to pick it up and place it in a set location, then send a confirmation to the Python script that the task is done. Python will then send the next cup location (if there are any) and this will continue until the program is closed.
