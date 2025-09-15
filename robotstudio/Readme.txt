RobotStudio is too large to upload to GitHub.

Setting up the Control Panel in RobotStudio:

1. In RobotStudio, go to Add-Ins -> Install to download and install the Control Panel.

2. Once installed, add the Control Panel to your robot:
   - Go to Home -> ABB Library -> Add Robot.
   - Then go to Home -> Virtual Controller -> From Layout.
   - Click Yes or Finish until the setup is complete.

Opening and Using the Virtual Controller and FlexPendant:

1. Open the Virtual Controller.

2. On the FlexPendant, set the controller mode:
   - Go to Controller -> Operating Mode -> Manual.
   - Then go to Controller -> FlexPendant.

Saving Robot Positions in FlexPendant:

1. Move the robot to the desired position.

2. In the top-left menu (the icon with 3 lines), go to:
   - Program Data -> View -> All Data Types -> robtarget.

3. Click New, give the position a name, and press OK.

Viewing Coordinates:

- To see the coordinates of a saved point:
  - Double-click the saved point to view its [x, y, z] coordinates.

- To view the hand frame coordinates while jogging:
  - Go to Jogging -> Motion Mode -> Linear -> press OK.

Note: Moving the hand frame in Linear mode can cause the robot to enter a singularity (a problematic position).

Opening and Editing Programs:

1. Open the program:
   - Click the menu in the top-left corner -> Program Editor -> select the arm you want to work with.

2. To add instructions:
   - In the Program Editor, click Add Instruction.
   - Select the instruction you want to add.

3. To edit points (e.g., MoveL):
   - Double-click the star (*) next to the instruction.
   - Select the point you want to assign.

Debugging:

- In the Program Editor, click Debug, then click PP to Main.(You need to do this for both arms!)
- Press "|>"(arrow to the right) in the left panel to run the code


Main file location:
C:\Users\Elliot\Documents\RobotStudio\Projects\YuMi2Arm-test\Virtual Controllers\Controller\INTERNAL\RAPID\PRG1\00050681
C:\Users\Elliot\Documents\RobotStudio\Projects\YuMi2Arm-test\Virtual Controllers\Controller\INTERNAL\RAPID\PRG2\00050682