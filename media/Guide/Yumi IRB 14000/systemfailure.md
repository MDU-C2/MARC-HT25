## System failure
The following sections about system failure is only if you are are using the same YuMI IRB 14000 as we did.

When you start the robot you will most likely get the error "SMB communication failure" on the FlexPendant (the wired controller) and a system failure. System failure will prevent you from doing most things with the robot. To get out of this you will need to go to Restart -> advanced -> Shutdown main computer, then turn off the power knob. Turn on the power knob again and robot (controller) should start without system failure. However you will probably have to recalibrate the right arm. (Click the image play the video).

>**Note:** To calibrate the right arm you will have to [align all the joints](/media/documents/RAPID%20Manuals/Yumi%20Rev%20counter%20update.pdf) on the right arm with the calibration marks. After you have done that start the calibration program on the FlexPendant, all joints should be selected, just press next.


[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/O1MPd2k_ZHU/0.jpg)](http://www.youtube.com/watch?v=O1MPd2k_ZHU)


>**Note:** If system failure persists despite following the above method. Try to "Revert to last auto saved" instead of "Shutdown main computer". This should remove the system failure and the need to calibrate the right arm.



## Why system failure occurs (and how to fix it)

SMB errors that lead to system failure always occur when the robot has been left unpowered for more than 2 days (weekend) or has been shut down suddenly (power knob). The SMB (serial measurement board) is a component that is constantly powered through a battery (even with the robot turned off) and is responsibly for keeping track of movement in the robot arms. This is to prevent constant calibration or loss of accuracy. 

### Current theory
Each arm has its own SMB and its own battery to power it. Since it is always the right arm that needs calibrating and it is related to leaving the robot without power over time, the working theory is that the battery is bad.

### Temporary fix

If you don't shut down the robot with the knob but first go into Restart -> advanced -> shutdown main computer, ***Then*** turn off the robot with the knob. You should not have system failure if you turn on the robot again within one day. (Off at 15:00, On at 09:00).

### Longterm fix
As mentioned the long term fix seems to be changing the SMB battery for the ***right arm***. The battery seems to be two 18650 units in series with some built in protection circuits outputting 7.2V 

On [page 331]() you will find the instructions for replacing the battery on the YuMI.