# How to setup RobotStudio to run RAPID code

The RAPID code can be run together with the vision system in a simulated environment or on the physical YuMi robot. This section goes through how to set up and start the RAPID code in both cases.

## Simulation setup (Virtual Controller)

### RobotWare
Firstly, make sure to install **RobotWare** or that the correct version is installed. First click the **Add-Ins** tab at the top of the screen and select the following:

1. RobotApps
2. Gallery
3. RobotWare for IRC5
4. Select version (Latest version should work)
5. Add

![RobotWare](/media/images/RobotWare.png)


### Create a station with YuMi and virtual controller
At the top of the screen, click **File** and select the following:

1. New
2. Project
3. Choose name and location
4. Tick **Include a Robot and Virtual Controller**
4. Choose robot model: **IRB 14000 YuMi** Variant **IRB 14000 0.5kg 0.5m**
5. Tick **Customize options** and Press **create**

![NewProject](/media/images/NewProject.png)
>If you want the controller to be able to run EGM, in the Change Options window, navigate to the **Engineering Tools** catagory and tick the **Externally Guided Motion (EGM)** option.

![RobotWare](/media/images/EGMOptions.png)


You are now ready to add the RAPID code to the virtual controller which is explained in the sections following the YuMi setup.
## YuMi setup (Physical controller)

Connecting the YuMi to robot studio can be done by following [these steps.](/media/Guide/Yumi%20IRB%2014000/RobotStudioconnect.md)

## Adding tasks
In order to run the **communication** and be able to move the two arms of the YuMi at the same time, multiple tasks needs to be set up with correct RAPID programs.

To add a task, first open the **Controller Configuration** in the active station and then proceed with the following steps:

1. Double click the **Controller** section
2. Press **Task**
3. Right click within the window and add a **New task**

![AddingTask](/media/images/AddingTask.png)

4. Enter a name, for example "Communication"
5. Change the type to **Normal**
6. Press **OK**

![TaskSettings](/media/images/TaskSettings.png)

>Make sure Motion Task is set to **No**, since you can only have one motion task for each mechanical unit (each arm) and there should already be two tasks corresponding to each arm on the controller.

7. Restart the controller

![Restart](/media/images/Restart.png)

With the tasks ready, you can move on to adding programs/modules to them.

## Loading programs/modules to tasks

The tasks are located in the current station. You can view them by extending the RAPID tab.

![Tasksview](/media/images/Tasksview.png)

To add RAPID code to them, simply right click whichever task you want code on and press either **Load module** module to load specific modules or **Load Program** to load multiple modules. You can also modify existing modules on any task.

The following instructions show how to load the RAPID code from this repository:

1. Right click the **Communication** task
2. Press **Load Program**

![LoadProgram](/media/images/LoadProgram.png)

3. Navigate to where the repository is saved **(C:\ ...\MARC-HT25\RAPID\Main\communication)**
4. Choose **communication.pgf**
5. Press **Open**
<!-- BILD PÅ LOAD PROGRAM PROCEDURE -->

All of the necessary modules should now be loaded to the **Communication** task.

The same procedure is done for the left and right arm tasks where **Movement_left** and **Movement_right** is loaded to each respectively.

