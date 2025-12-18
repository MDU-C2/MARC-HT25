



## How to run cup gripper software/program(s)
To run the cup gripper program on the robot follow it is recommended to follow the [step by step guide](/media/Guide/step_by_step_guide.md).

### Some info about the Programs
- [Communication module](/media/Guide/Yumi%20IRB%2014000/communication_rapid.md)
- [Movement functions](/media/Guide/Yumi%20IRB%2014000/move_arm.md)
- [Start RAPID code](/media/Guide/Yumi%20IRB%2014000/how_to_start_rapid.md)




## RAPID Quick Start Guide
RAPID is a programming language that ABB gives to their customers to program ABB robots. It is a high level language and you will generally not have detailed control over path planning or trajectory planning. If you use the MoveL command RAPID does not always avoid singularities, so it is possible to lock the robot arm this way. If you would like to control the robot joints through an external program you can use ABB's Externally Guided Motion (EGM) and set it up ***inside RAPID.***

### Documentation
---
Most of the documentation for RAPID can be found inside RobotStudio. You can find some of the documentation [here](/media/documents/RAPID%20Manuals) as well.


![RAPID doc](/media/images/RAPID/rapiddoc.png)
