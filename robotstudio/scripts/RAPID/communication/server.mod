MODULE server

    !==== variables ====!
    VAR socketdev server_socket;
    VAR socketdev client_socket;
    
    CONST num delay_time := 0.1;
    ! port values
    VAR string ipAddress := "127.0.0.1"; ! YuMi ip "192.168.0.1"
    VAR num port := 1025;

    ! process variables
    VAR string message := "";
    VAR robtarget hand_frame; 
    VAR num message_index := -1;
    VAR robtarget cup_end_frame := [ [0, 0, 0], [0, 0, 0, 0], [1, 1,
0, 0], [ 11, 12.3, 9E9, 9E9, 9E9, 9E9] ]; ! dummy values
    
 ! Open socket connection
    PROC server_init() !runs once in initzilise
        !can close socket even if they are not created!
        SocketClose server_socket;
        SocketClose client_socket;
        
        !create sockets
        SocketCreate server_socket;
        
        !connect client and server
        socketBind server_socket, ipAddress, port;
        SocketListen server_socket;
        SocketAccept server_socket,client_socket\ClientAddress:=ipAddress;
        TPWrite ("client connected");

    ERROR ! we use and expect errors in rapid,
        IF ERRNO=ERR_SOCK_TIMEOUT THEN ! if no clinet did connect, try again
            RETRY;
        ELSEIF ERRNO=ERR_SOCK_CLOSED THEN ! if the socket is closed that I lissen too, return from this function
            RETURN;
        ENDIF
    ENDPROC

    ! hold comminication while client is connected
    ! close communication if timer runs out or clinet close communication
    PROC single_client_communication() ! only want one clinet, therefore we do not need to open other ports and arange new connections!

        ! while we want to have a communication we keep on having one
        WHILE TRUE DO

            SocketReceive client_socket \Str := message \Time:=30; !you have 30 sec to send message or conneciton closes
            ! swich case
            TEST message 
                
                CASE "Connection_test":
                    TPWrite("[INFO] client is sending test message");
                    SocketSend client_socket \Str:= "Connection_Confirmed";
                
                CASE "Cups_available":
                    TPWrite("[INFO] client have found cups"); 
                    
                    MovingCups;
                    
                    WaitTime(delay_time);
                    SocketSend client_socket \Str:= "Ack_stop"; ! no more cups
                    SocketClose client_socket;
                    RETURN; !break process
                    
                CASE "Coordinates":
                    TPWrite "[INFO] clinet want cordinates";
                    hand_frame :=  CRobT(\Tool:= tool0);! tGripper);
                    SocketSend client_socket \Str :=  RobtargetToString(hand_frame) + "_ack";! add real cordinates here
                          
                CASE "Move":
                TPWrite("[INFO] client want to move arm");
                   IF(MoveRob(GetRobTarget())) THEN !Successfull move sequence 
                        SocketSend client_socket \Str :=  "Ack_succesfull";! add real cordinates here       
                   ELSE
                        SocketSend client_socket \Str:= "[ERROR]can't reach that possition,try again"; !move failed
                   ENDIF
                   
                CASE "Gripp":
                TPWrite("[INFO] client want to gripp with gripper");
                 SocketSend client_socket \Str:= "Ack_wait";
                 !grip function
                 SocketSend client_socket \Str:= "Ack_Gripp done";
                
                CASE "Release":  
                TPWrite("[INFO] client want to open with gripper");
                 SocketSend client_socket \Str:= "Ack_wait";
                 !Release function
                 SocketSend client_socket \Str:= "Ack_Release done";
                 
                DEFAULT:
                 TPWrite("[INFO] message from client: "+message);
                 SocketSend client_socket \Str := "default_"+message;! add real cordinates here
            ENDTEST
           
            WaitTime(delay_time);
            SocketSend client_socket \Str:= "Ask_next"; ! ask for next "order"

        ENDWHILE

    ERROR ! if errors occure during run
        IF ERRNO = ERR_SOCK_CLOSED THEN ! clinet closed connection before sending end ack!
            server_init;
            RETRY;
        ELSEIF ERRNO = ERR_SOCK_TIMEOUT THEN
            SocketClose client_socket; ! socket never send annything, close connection and return to main
            RETURN;
        ENDIF
    ENDPROC
    
    ! move robot to target
    FUNC bool MoveRob(robtarget target)
 
        WaitUntil shared_vars.wait_flag = FALSE;
        shared_vars.flag := 1;
        TPWrite "Pos(MoveRob):"\Pos:=target.trans;
        TPWrite "Orient(MoveRob)"\Orient:=target.rot;
        TPWrite "ConfData(MoveRob)"\Num:=target.robconf.cf1;
        TPWrite "ConfData(MoveRob)"\Num:=target.robconf.cf4;
        TPWrite "ConfData(MoveRob)"\Num:=target.robconf.cf6;
        TPWrite "ConfData(MoveRob)"\Num:=target.robconf.cfx;
        shared_vars.joint_values := CalcJointT(target,tool0);! tGripper); ! get target joint values
        TPWrite "wait_flag:"\Bool:=shared_vars.wait_flag;
        shared_vars.wait_flag := TRUE;
        TPWrite "wait_flag:"\Bool:=shared_vars.wait_flag;
        
        RETURN TRUE; 
    ERROR
        IF ERRNO = ERR_ROBLIMIT THEN ! exead limit, send error to client and expect new coordinates
            RETURN FALSE;
        ENDIF
    ENDFUNC
  
    FUNC robtarget GetRobTarget()
        VAR bool sucess := FALSE;
        VAR robtarget return_target;
        return_target := [[611.44,-10,224.449],[0.00944177,-0.683755,0.728027,-0.0486451],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];!CRobT(\Tool:= tGripper); !init values
        
        WaitTime(delay_time);
        SocketSend client_socket \Str:= "Ask_Coordinate";
        SocketReceive client_socket \Str := message;
        sucess := rob_coordinates(message,return_target.trans);
        WHILE NOT sucess DO
            SocketSend client_socket \Str:= "[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket \Str:= "Ask_Coordinate";
            
            SocketReceive client_socket \Str := message;
            sucess := rob_coordinates(message,return_target.trans);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=return_target.trans;
        SocketSend client_socket \Str:= "Ack_Coordinate";
        WaitTime(delay_time);
        SocketSend client_socket \Str:= "Ask_Orientation";
        
        ! expect message [q1,q2,q3,q4] commands next
        SocketReceive client_socket \Str := message;
        sucess := rob_orientation(message,return_target.rot);
        
        WHILE NOT sucess DO
            SocketSend client_socket \Str:= "[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket \Str:= "Ask_Orientation";
            
            SocketReceive client_socket \Str := message;
            sucess := rob_orientation(message,return_target.rot);
        ENDWHILE
        
        return_target.rot := NormilizeRotation(return_target.rot);
        
        
        SocketSend client_socket \Str:= "Ack_Orientation";
        WaitTime(delay_time);
        
        RETURN return_target;
    ENDFUNC
    !Move multiple cups
    PROC MovingCups()
        
        VAR num amount_of_cups := 0;
        VAR bool succeded := FALSE;
        
        VAR robtarget cup_start_frame;
        VAR robtarget cup_end_frame; 
        
        ! ==== expect amount of cups ==== !
        SocketSend client_socket \Str:= "Ask_amount_of_cups";   
        SocketReceive client_socket \Str := message;
        
        succeded := StrToVal(message,amount_of_cups); ! we got an cup amount
        
        WHILE NOT succeded DO !while we don't get a number
        
            SocketSend client_socket \Str:= "[ERROR]not a number,try again"; !move failed 
            WaitTime(delay_time);
            SocketSend client_socket \Str:= "Ask_amount_of_cups";  
            
            SocketReceive client_socket \Str := message;
            succeded := StrToVal(message,amount_of_cups); 
        ENDWHILE
        
        SocketSend client_socket \Str:= "Ack_amount_of_cups"; 
        
        ! ==== go through all cups ==== !
        WHILE(amount_of_cups > 0) DO
            
            !get current frame
            WaitTime(delay_time);
            SocketSend client_socket \Str:= "Ack_cup_current_position";   
            cup_start_frame := GetRobTarget();
            
            !get end frame
            SocketSend client_socket \Str:= "Ack_cup_end_position";   
            cup_end_frame := GetRobTarget();
            WaitTime(delay_time);
            SocketSend client_socket \Str:= "Ask_Wait";
            
            
            !move to current possition
            succeded := MoveRob(cup_start_frame);
            
            WHILE NOT succeded DO !while we fail to move
                SocketSend client_socket \Str:= "[ERROR]can't reach current frame,try again"; !move failed 
                WaitTime(delay_time);
                SocketSend client_socket \Str:= "Ack_cup_current_position";  !we want new position
                
                !try again
                cup_start_frame := GetRobTarget();
                succeded := MoveRob(cup_start_frame);
            ENDWHILE
            
            !move to end possition
            succeded := MoveRob(cup_end_frame);
             
            WHILE NOT succeded DO !while we fail to move
                SocketSend client_socket \Str:= "[ERROR]can't reach end frame,try again"; !move failed 
                WaitTime(delay_time);
                SocketSend client_socket \Str:= "Ack_cup_end_position"; 
                
                !try again
                cup_end_frame := GetRobTarget();
                succeded := MoveRob(cup_end_frame);
            ENDWHILE
            
!            SocketSend client_socket \Str:= "Ask_amount_of_cups";            
            
!            !expect amount of cups
!            SocketReceive client_socket \Str := message;
!            succeded := StrToVal(message,amount_of_cups);
            
!            WHILE NOT succeded DO !while we don't get a number
            
!                SocketSend client_socket \Str:= "[ERROR]not a number,try again"; !move failed 
!                WaitTime(delay_time);
!                SocketSend client_socket \Str:= "Ask_amount_of_cups";  
                
!                SocketReceive client_socket \Str := message;
!                succeded := StrToVal(message,amount_of_cups); 
!            ENDWHILE
            
!            WaitTime(delay_time);
!            SocketSend client_socket \Str:= "Ack_amount_of_cups";
    
           WHILE amount_of_cups > -1 DO
                WaitTime(delay_time);
                SocketSend client_socket \Str:= "Ask_next";
                SocketReceive client_socket \Str:= message;
                
                IF message = "y" THEN !yes 
                    amount_of_cups := 1;
                ELSEIF message = "n" THEN !no
                    amount_of_cups := 0;
                ELSE
                    SocketSend client_socket \Str:= "[ERROR] enter yes or no,try again";
                ENDIF
           ENDWHILE      
        ENDWHILE
    ENDPROC

ENDMODULE