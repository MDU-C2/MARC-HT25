MODULE server_module_mug
    
    ! === global structs ====
    
    RECORD mug_vector
        pos position;
        pos normal;
    ENDRECORD
    
    !flag values:
    ! -1 = stop program
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
        WHILE TRUE DO

            SocketReceive client_socket\Str:=message;
            TEST message

            CASE "Connection_test": ! not done but should not crash the program
                TPWrite("[INFO] client is sending test message");
                SocketSend client_socket\Str:="Connection_Confirmed";
                

            CASE "Get_Coordinates": ! this case sends only the x,y,z coordinates of the left hand gripper, Tool Center Point. ! not done but should not crash the program
                TPWrite "[INFO] client want cordinates";
                SocketSend client_socket\Str:="Ask_RobotCoordinate";
                SocketReceive client_socket\Str:=message; ! Just assume it is "ACK" for now
                
                hand_frame:=CRobT(\Tool:=tGripper);
                SocketSend client_socket\Str:=RobPosToString(hand_frame.trans);
                SocketReceive client_socket\Str:=message; ! Just assume it is "ACK" for now
                SocketSend client_socket\Str:="AskNext";

            CASE "Move":
                TPWrite("[INFO] client want to move arm");
                IF (MoveRob(GetRobTarget())) THEN                   
                    SocketSend client_socket\Str:="AskNext";
                ELSE
                    SocketSend client_socket\Str:="[ERROR]can't reach that possition,try again";
                ENDIF
            
            CASE "Home":
            
                SocketSend client_socket\Str:="Ack_Release done";
            
            CASE "Pick_Up_Sequence":
                
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
            server_init;
            RETURN ;
        ELSEIF ERRNO=ERR_SOCK_TIMEOUT THEN
            SocketClose client_socket;
            RETURN ;
        ENDIF
    ENDPROC

    
   PROC FetchMug(bool left_arm, mug_vector target)
        
        multi_move.mug := target; 
        IF left_arm THEN
            multi_move.left_flag := 2; ! left hand fect mug
            multi_move.left_in_process := TRUE;
            
            WaitUntil multi_move.left_in_process = FALSE; ! wait untill process is done
        ELSE
            multi_move.right_flag := 2; ! left hand fect mug
            multi_move.right_in_process := TRUE;
            
            WaitUntil multi_move.right_in_process = FALSE;! wait untill process is done
        ENDIF
        
   ENDPROC
    
    ! not done yet
    PROC HandOver(mug_vector target)
    
       
    ENDPROC

     
   PROC LeaveMug(bool left_arm, mug_vector target)
        multi_move.mug := target; 
        IF left_arm THEN
            multi_move.left_flag := 3; ! left hand fect mug
            multi_move.left_in_process := TRUE;
            
            WaitUntil multi_move.left_in_process = FALSE; ! wait untill process is done
        ELSE
            multi_move.right_flag := 3; ! left hand fect mug
            multi_move.right_in_process := TRUE;
            
            WaitUntil multi_move.right_in_process = FALSE;! wait untill process is done
        ENDIF 
   ENDPROC
    
    FUNC mug_vector GetRobTarget()
        VAR bool sucess:=FALSE;
        VAR mug_vector return_target;
        return_target:=[[611.44,-10,224.449],[0,0,1]];
        !CRobT(\Tool:= tGripper); !init values

        ! ==== GET MUG COORDINATES ====
        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_Coordinate";
        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,return_target.position);
        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_Coordinate";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,return_target.position);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=return_target.position;
        SocketSend client_socket\Str:="Ack_Coordinate";
        WaitTime(delay_time);
        
        
        ! ==== GET MUG NORMAL ====
        SocketSend client_socket\Str:="Ask_MugNormal";

        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,return_target.normal);

        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="rob_coordinates";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,return_target.normal);
        ENDWHILE

        return_target.normal:=return_target.normal/sqrt(DotProd(return_target.normal,return_target.normal));
        WaitTime(delay_time);

        RETURN return_target;
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDFUNC
    
ENDMODULE