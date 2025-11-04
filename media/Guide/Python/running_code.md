<h1 align="center">
  <br>
  <br>
  <img src="../../../media/images/Python/python_walkthrough.png" alt="walkthrough banner" width="600">
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
* Move the gripper into a cup using **Leadthrough** on the flexpendant. 
* When you see a detection in the program press **Space**. Do this atleast 3 times but more position equals better calibration. For our tests we use 10-15 calibration positions.
* When all positions have been saved, press **Q** on your keyboard which will close the program and save the positions to .txt files.
* Now 2 files should have been created **robo_coords.txt** and **saved_coords.txt** 
* These coordinates will be used in the main file later to calculate the translation between the camera and the robot.
## Running the main code
To run the main python script the server needs to be started from RAPID.
```bash
# Run the main code 
> py main.py
```
This code will run the object detection and send the coordinates of the cups to the robot. The robot will then go to the cup and place it in the correct location then send a confirmation to the python script that the task is done. Python will then send the next cup location and this will work until the program is closed.