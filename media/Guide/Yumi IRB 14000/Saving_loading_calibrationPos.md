# Saving/Loading calibration positions
For whatever reason, you might want to change the hand positions for the calibration procedure. This section describes how we stored and saved calibration positions.

## What we did

The calibration positions were saved by first moving an arm with **Lead-through** mode and iterating through a for-loop storing the position in a persistent (**PERS**) variable array in RobotStudio. 

A breakpoint was placed in the for loop in order to be able to easily run RAPID code and have **Lead_through** mode active at the same time. 
A more refined version would activate **Lead_through** in the code but we did not find any good solution.

At the start, we defined a suitable home position for the calibration procedure and stored it in the RAPID main module corresponding the the correct arm. We then marked on the robot where the joints were positioned. Then we moved the arm to the desired position, always moving from the home position. 

A typical loop through our saving procedure would look like this:

1. Start from the calibration home position.
2. Move the arm to the desired position using lead-through mode.
3. Run the RAPID code, iterating through the for-loop, saving the position.
4. Move the arm back to the calibration home position.
5. Repeat.
> note: A suitable calibration position is a position with roughly the same arm configuration as the calibration home position. This helps the moving functions to be able to easily move to the desired positions.

## RAPID functions
We made two processes to save/load robtargets to/from .txt files stored in the home folder on the robot controller.

The two functions are:
```c++
saveCalibTargets(string file_name, robtarget robtarget_array{*}, num array_size)
```
and 
```c++
loadCalibTargets(string file_name, INOUT robtarget robtarget_array{*}, NUM array_size)
```

These processes writes/reads to/from a file located in the Home folder on the controller with the name depending on the file_name argument.
## RAPID code example
A simple example of how the code was set up when saving calibration positions:

```c++
PERS robtarget calib_positions{array_size}
```

```
VAR num i := 1

FOR i FROM 1 to array_size DO
    TPWrite "Move arm";

    !(Breakpoint)

    calib_positions{i} = CrobT(\Tool:=tGripper)     !Current hand position
ENDFOR

saveCalibTargets "file_name", calib_positions, array_size;
```
