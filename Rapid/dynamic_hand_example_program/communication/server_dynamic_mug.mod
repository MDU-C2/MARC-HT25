MODULE server_dynamic_mug
    ! ==== dynamic global vars ====
    RECORD mug_vector
        pos position;
        pos normal;
    ENDRECORD
    
    !flag values:
    ! 0 = nothing
    ! 1 = hand over
    ! 2 = fetch
    ! 3 = drop off
    ! 4 = go home
    RECORD shared_information
      num right_flag;  
      num left_flag;
      mug_vector hand_over_pose;
      mug_vector mug;
      bool right_in_process;
      bool left_in_process;
    ENDRECORD
    PERS shared_information multi_move;
    
    !==== variables ====!
    VAR socketdev server_socket;
    VAR socketdev client_socket;

    CONST num delay_time:=0.2;

    ! process variables
    VAR string message:="";
    VAR robtarget hand_frame;
    VAR num message_index:=-1;
    VAR robtarget cup_end_frame:=[[0,0,0],[0,0,0,0],[1,1,0,0],[11,12.3,9E9,9E9,9E9,9E9]];
    ! dummy values

    ! Open socket connection
    PROC server_init()
        ! port values
        VAR string ipAddress:="192.168.125.1";
        ! YuMi ip "192.168.0.1"
        VAR num port:=1025;

        !runs once in initzilise
        !can close socket even if they are not created!
        SocketClose server_socket;
        SocketClose client_socket;
    
        WaitTime(1);
        
        !create sockets
        SocketCreate server_socket;

        !connect client and server
        socketBind server_socket,ipAddress,port;
        SocketListen server_socket;
        SocketAccept server_socket,client_socket\ClientAddress:=ipAddress;
        TPWrite("client connected");

    ERROR
   
        ! we use and expect errors in rapid,
        IF ERRNO=ERR_SOCK_TIMEOUT THEN
            ! if no clinet did connect, try again
            RETRY;
            
        ELSEIF ERRNO=ERR_SOCK_CLOSED THEN
            ! if the socket is closed that I lissen too, return from this function
            RETURN;
        ELSEIF ERRNO = ERR_SOCK_ADDR_INVALID THEN
            ipAddress:="192.168.125.1";

            RETRY;
        ENDIF
        
    ENDPROC

    ! hold comminication while client is connected
    ! close communication if timer runs out or clinet close communication
    PROC single_client_communication()
        VAR mug_vector buffer;
        ! only want one clinet, therefore we do not need to open other ports and arange new connections!

        ! while we want to have a communication we keep on having one
        WHILE TRUE DO

!            SocketReceive client_socket\Str:=message\Time:=30;
            
            SocketReceive client_socket\Str:=message;
            !you have 30 sec to send message or conneciton closes
            ! switch case
            TEST message

            CASE "Connection_test": ! not done but should not crash the program
                TPWrite("[INFO] client is sending test message");
                SocketSend client_socket\Str:="Connection_Confirmed";
                
            CASE "Get_Coordinates": ! this case sends only the x,y,z coordinates of the left hand gripper, Tool Center Point. ! not done but should not crash the program
                TPWrite "[INFO] client want cordinates";
                SocketSend client_socket\Str:="Robot_Wants_To_Send_Coordinates";
                SocketReceive client_socket\Str:=message; ! Just assume it is "ACK" for now
                
                hand_frame:=CRobT(\Tool:=tGripper);
                SocketSend client_socket\Str:=RobPosToString(hand_frame.trans);
                SocketReceive client_socket\Str:=message; ! Just assume it is "ACK" for now
                SocketSend client_socket\Str:="AskNext";
                
                
                ! add real cordinates here

            CASE "Move":
              
            CASE "Grip":
              

            CASE "Release":
               
            CASE "Home":
              
            CASE "Pick_Up_Sequence":
            
            buffer := GetRobVector();
            ! mug to far to the right
            IF buffer.position.y < -100 THEN
                MoveRob buffer,FALSE;
                
            ELSE
                MoveRob buffer,TRUE;
                
            ENDIF
            
             SocketSend client_socket\Str:="AskNext";
              
            CASE "Leave_Sequence":
            
                
            CASE "Move_Calibration_Position": ! not done but should not crash the program
                SocketSend client_socket\Str:="AskCalPoint";
                SocketReceive client_socket\Str:=message; ! position number
                ! Move to position, TODO
                SocketSend client_socket\Str:="AskNext";
                
            DEFAULT:
                TPWrite("[INFO] message from client: "+message);
                SocketSend client_socket\Str:="default_"+message;
                ! add real cordinates here
            ENDTEST

        ENDWHILE

    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            !RETRY;
            !SocketClose client_socket;
            ! socket never send annything, close connection and return to main
            RETURN ;
        ELSEIF ERRNO=ERR_SOCK_TIMEOUT THEN
            SocketClose client_socket;
            ! socket never send annything, close connection and return to main
            RETURN ;
        ENDIF
    ENDPROC

    ! move robot to target
    PROC MoveRob(mug_vector target, bool left_arm)
    
        IF left_arm THEN
            multi_move.mug := target; 
            multi_move.left_flag := 2;
            multi_move.left_in_process := TRUE;
            
            WaitUntil multi_move.left_in_process = FALSE;
        ELSE
            multi_move.mug := target; 
            multi_move.right_flag := 2;
            multi_move.right_in_process := TRUE;
            
            WaitUntil multi_move.left_in_process = FALSE;
            
        ENDIF
        
    ENDPROC

    FUNC mug_vector GetRobVector()
        VAR bool sucess;
        VAR mug_vector target;
        target:=[[611.44,-10,224.449],[0,0,1]];

        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_Coordinate";
        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,target.position);
        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_Coordinate";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,target.position);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=target.position;
        SocketSend client_socket\Str:="Ack_Coordinate";
        WaitTime(delay_time);
        
        
        SocketSend client_socket\Str:="Ask_MugNormal";

        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,target.normal);

        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_MugNormal";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,target.normal);
        ENDWHILE
        WaitTime(delay_time);

        RETURN target;
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDFUNC

ENDMODULE