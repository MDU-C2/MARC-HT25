# What does the rapid communication script do?
The rapid communication script utilized the build in TCP handeling that RAPID provides. The program open a server socet communication and expect a string which provides as commands to the robot.

Worth noting. The robot in the Master in the communication, therefore the client (the system connecting to the robots) will ask for a sequence, example "Move". Then the server(Robot) will tell the client what it needs. Where "ACK" is acknowlagement, meaning telling the client that a message or action have been registered. Where "ASK" is a request that the client needs to provide.


![example: ](/images/RAPID/client_com.png)

# Modify the code

There exsist 3 files in "Communication.mod" where only 2 are of importance, for one of them is a example how to run the server.
there exsist 
- server
- server_functions
- left_main (which only include a command in a while loop)

The "server" is the bread and butter of the code, where server_functions is more or less smaller functions to support the main server code with out smudging out the server code more then it already is.

There might be times where you want to modify functions in te server_functions, but I doubt it. Therefor I will only go over the server code and what is of interest.

## server

The two main part that you might want to change is the Ipadress, and the input strings from the socets.
The ipAdress can be found in two places in the function server_init(). the first is at the top, defining the adress. The second one is in the error handeling.

The resoning for these two places is that the function "socketBind" provided by RAPID changes the ipAdress (don't know why but it does that on the robot). So change at both places if you want to change the ipAdress.

![server init code](/images/RAPID/server_init.png)

*note: the code might have changed a bit sence this was written.*

---
To add or change the string input, go down to the function "single_client_communication()" and in the swich case.
The input to the swich case is the variable "message", and the cases are "actions" or likeworthy of the robot.
![exmpale test connection](/images/RAPID/server_switch_case.png)

Here it's just add your own CASE "example" and or change the syntax of exsisting inputs. Worth noting. After the case is done the server will send a "Ask_next" to get next input. If none is sent in 30 second the communication is assumed to have ended and it will end.


 

