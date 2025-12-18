## How to run the RAPID code

This section walks through how to start the RAPID code through RobotStudio assuming the steps of section [RobotStudio_setup](/media/Guide/Yumi%20IRB%2014000/RobotStudio_setup.md) have been followed. 
>and section [EGM_setup](/media/Guide/Yumi%20IRB%2014000/EGM_setup.md) if you want to start the EGM examples.

### Select Tasks

To run the system, all of the tasks need to be selected in RobotStudio:

1. Click **RAPID** at the top of RobotStudio
2. Click **Selected Tasks** and tick all three tasks


![TaskSelection](/media/images/TaskSelection.png)

## Reset program pointers and select Run Mode
The program pointers need to be set to main in order for the system to work properly:

1. Click **RAPID** at the top of RobotStudio
2. Click **Program Pointer** and in the drop down menu, select **Set Program Pointer to Main in all tasks**
>[!Note]
>The shortcut to reset the pointers is **Ctrl + Shft + M**
3. In the **Run Mode** drop down menu, select **single cycle** so that the RAPID program doesn't restart after execution
4. Click **Start**
>[!Note]
>The shortcut to start the code is **f8**

![PointerToMain](/media/images/PointerToMain.png)
