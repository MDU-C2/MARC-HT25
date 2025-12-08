
# RAPID TASKS

The main tasks, together with their modules, used in cup movement and python communication are:

* <a href="#movement">Movement</a> 
    - module1.mod
    - movementFunctions.mod
    - EGMprocesses.mod
    - movement_shared_vars.mod
* <a href="#communication">Communication</a> 
    - left_main.mod
    - server.mod
    - processes.mod
    - Server_functions.mod
    - movement_shared_vars.mod

## Movement
* Module1.mod

    Module1.mod is the main movement module which takes instructions from the communication task.


* movementFunctinos.mod

    The processes / functions in this module can be used for movement between two points when working with configuration mode OFF:
    ```c++
        ConfL\Off
        ConfJ\Off
    ```
    and handle problems such as points far away from eachother and high joint values.


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
    (MoveY is only available with YumiLib)
* EGMprocesses.mod

    Main module for EGM processes. Includes setup, activation and starting of EGM in both pose and joint mode.

* movement_shared_vars.mod

    Module meant for sharing variables between tasks. Both tasks needs to define PERS (persistent) variables with identical names. 
    
    This specific module is used to share variables between movement and communication tasks.

## communication

* left_main.mod

* server.mod

    Here the main functionality of the server lies. 

    To change ip address, in the process server_init, change the variable "ipAddress" to the one you want. THe YuMi dual arm have a local ipv4 of "192.168.0.1".
    ```c++
        PROC server_init()
            ! port values
            VAR string ipAddress:="192.168.125.1";
            ! YuMi ip "192.168.0.1"
            VAR num port:=1025;
    ```
    The port can be changed in the same process with variable name of "port" currently on port 1025.

    To add your own client input message, go to the process " PROC single_client_communication()" and go down to the switch case "TEST message"
    In "TEST message" you can add your own "CASE: "example":" where the client would send a "example" string to the server.
* processes.mod

* Server_functions.mod

    This file have support functions for the server. like normilize queternium values, and pars messages from the client. Currently the "rob_coordinates" and "rob_orientation" are quite simple 
    and "dumb" for it is hard coded te structure of the input from the client. This was mainly done for simplisity sake and to make the system a bit more robust.

    To change the input structure of from the clinet the functions need the be changed, or even to create new one. But in short here is the rough idea.

    Get a string, find index of chars warping a number, extract that number. If the wraped chars does not exsist or the wraped number is invalid raise the a error flag.

    ! to find x
            start_index := StrFind(input_string,start_index,"[")+1;
            end_index := StrFind(input_string,start_index,",");
            ! wrong format
            IF end_index < start_index THEN
                RAISE ERR_NOT_VALID_STRING;
            ENDIF
            
            buffer := StrPart(input_string,start_index,end_index-start_index);
            valid := StrToVal(buffer,rob_pos.x); 
            IF NOT valid THEN
                RAISE ERR_NOT_VALID_STRING;
            ENDIF 

* movement_shared_vars.mod

    Module meant for sharing variables between tasks. Both tasks needs to define PERS (persistent) variables with identical names. 
    
    This specific module is used to share variables between movement and communication tasks.