# Step by step guide
Here you will follow a step by step guide to set everything up to run the system
## 1. Clone the Repo
Start by making a clone of this repo , you'll need [Git](https://git-scm.com) installed on your computer. From your command line:

```bash
# Clone this repository
$ git clone https://github.com/MDU-C2/MARC-HT25.git

# Go into the repository
$ cd MARC-HT25
```
Make sure you have the right version of [Python](/media/Guide/Python/README.md). If you do not have the right version some libraries will not work.


## 2. Setup
This section goes through everything needed in order to run the code in this repository.
### RAPID-setup
First you need to download **RobotStudio**. You can start a [30-day free trial](https://new.abb.com/products/robotics/nl/software-and-digital/robotstudio/robotstudio-desktop) through the ABB website or you can ask a teacher or the IT department to make **RobotStudio** available in the **Software Center** on any school computer. 

When you have **RobotStudio**, you can follow [these steps](/media/Guide/Yumi%20IRB%2014000/RobotStudio_setup.md) to configure the correct settings within **RobotStudio**.
### Python-setup
You can find all the necessary information about the Python setup by going through [this section](/media/Guide/Python/Readme.md).
### Robot / camera-setup
**Then start the robot by following this guide [YuMi guide](/media/Guide/Yumi%20IRB%2014000/README.md).**
>[!Note]
 >If you get a [system failure](/media/Guide/Yumi%20IRB%2014000/systemfailure.md) error, it can solved by following this [link](/media/Guide/Yumi%20IRB%2014000/systemfailure.md).

 Lastly set up the camera so that it can see the whole work space of the robot.
## 3. Run calibration script 
Make sure all the cables are connected and open Robotstudio and VsCode. 

### Rapid
Connect the controller and make sure you get WriteAcces, then include the programs **Communication,RightArm,LeftArm** all found in seperate folders in **\MARC-HT25\Rapid**. Make sure **RightArm** is connected to the right arm of the yumi and the **LeftArm** is connected to the left arm of the yumi. 
Then it should just be to put the pointer to top of main (ctrl+shift+m) and then start the code (f8).

For a even more indepth introduction follow [start Rapid](/media/Guide/Yumi%20IRB%2014000/how_to_start_rapid.md).

### Python
First the camera need to be callibrated, do this by starting Rapid but only start the communication program. Then start the **calibrate_single_file.py**. Here the camera should pop up in a new window and you should see what the camera seas. The system should outocalibrate for you. 

For more indepth or that this text is not up to date follow [start python](/media/Guide/Python/running_code.md).