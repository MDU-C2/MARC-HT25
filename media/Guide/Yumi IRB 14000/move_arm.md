## Movement

The 

* Module1.mod

    Module1.mod is the main movement module which takes instructions from the communication task.


* movementFunctinos.mod

    The processes / functions in this module can be used for movement between two points when working with configuration mode OFF:
    ```c++
        ConfL\Off
        ConfJ\Off
    ```
    and handle problems such as points far away from eachother and high joint values. In short, the path between current position and desired position is discretized given certain circumstances such as distance between positions and calculated joint values.
    


    When working with configuration ON:
    ```c++
        ConfL\On
        ConfJ\On
    ``` 
    it is recommended to use the standard movement functions:
    ```c++
        MoveJ
        MoveL
        MoveY
    ``` 
    >note: MoveY is only available with YumiLib
* EGMprocesses.mod

    Main module for EGM processes. Includes setup, activation and starting of EGM in both pose and joint mode.

* movement_shared_vars.mod

    Module meant for sharing variables between tasks. Both tasks needs to define PERS (persistent) variables with identical names. 
    
    This specific module is used to share variables between movement and communication tasks.
