================ C++ ================

To run client or server (most likley server would not be needed for RAPID have server functionalty) but you need a g++ compiler.
To create a .exe file go inte to folder via the terminal (cd <filepath>\MARC-HT25\robotstudio\scripts\C++) then run "Make build". this will both build and run the "FILENAME" variable,
currently clinet.

After that you have an .exe file you can run. To build the server change the "FILENAME" varaible in the Makefile to server.

The client read user input, send a message and wait untill it recives a message from a server. Meaning it does not "auto" read from the socket! for it was just a quit client mostly from 
microsofts own version.

NOTE! It uses winsock2.h and not sock.h meaning linux and mac might have problems with this client.


================ RAPID ================
Rapid have 2 main files.
- server.mod
- Server_functions.mod

To execute the functionallit from these files, in main (or where you want the server to exsist) just add "single_client_communication;"
This will call the function "single_client_communication;" and execute all server functionality.

-------------- SERVER.MOD --------------

Here the main functionality of the server lies. To change ip addres go to row 9 and change the variable "ipAddress" to the one you want. THe YuMi dual arm have a local ipv4 of "192.168.0.1".
The port can be changed on row 10 with variable name of "port". currently on port 1025.

To add your own client input message go to the process " PROC single_client_communication()" and go down to the switch case "TEST message"
In "TEST message" you can add your own "CASE: "<example>":" where the clinet would send a "<example>" string to the server.

If you want to change the watchdog timer (socket_time_out) go to line 49 and change the num after \Time

	49   SocketReceive client_socket \Str := message \Time:=30; <----- here, change \Time to your wanting duration


Currently the robot arm is moved by MoveAbsJ, but this does not garante a sucessfull movement, meaning this server system can't garantee that the robot arm acually moves when told to.
To add a garante look into a better wat to move the arm. 


-------------- SERVER_FUNCTIONS.MOD --------------

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



















