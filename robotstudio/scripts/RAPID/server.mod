MODULE server

    !==== variables ====!

    VAR socketdev server_socket;
    VAR socketdev client_socket;
    
    ! port values
    VAR string ipAddress := "127.0.0.1"; ! local host
    VAR num port := 1025;

    ! process variables
    VAR string message := "";
    VAR robtarget hand_frame; 
    VAR num message_index := -1;
    
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
        !have_communication := TRUE;

    ERROR ! we use and expect errors in rapid,
        IF ERRNO=ERR_SOCK_TIMEOUT THEN
            RETRY;
        ELSEIF ERRNO=ERR_SOCK_CLOSED THEN
            RETURN;
        ENDIF
    ENDPROC

    ! hold comminication while client is connected
    ! close communication if timer runs out or clinet close communication
    PROC single_client_communication() ! only want one clinet, therefore we do not need to open other ports and arange new connections!

        ! while we want to have a communication we keep on having one
        WHILE TRUE DO

            SocketReceive client_socket \Str := message;
            ! swich case
            TEST message 
            
                CASE "Connection_test":
                    TPWrite("[INFO] client is sending test message");
                    SocketSend client_socket \Str:= "Connection_Confirmed";
                
                CASE "Cups_Available":
                    TPWrite("[INFO] client have found cups");
                    hand_frame := CRobT(\Tool:= tool0 \WObj:= wobj0);
                    SocketSend client_socket \Str:= "Ask_Instructions:" +  RobtargetToString(hand_frame);
                    
                CASE "Coordinates":
                    TPWrite "[INFO] clinet want cordinates";
                    hand_frame := CRobT(\Tool:= tool0 \WObj:= wobj0);
                    SocketSend client_socket \Str :=  RobtargetToString(hand_frame) + "_ack";! add real cordinates here
                          
                CASE "Move":
                 hand_frame := CRobT(\Tool:=tool0 \WObj:=wobj0);
                 SocketSend client_socket \Str:= "Ask_Coordinate: "+RobtargetToString(hand_frame);
                 MoveRob;  !start move sequence
                            
                !don't want to be able to end communication from client
                !CASE "end": 
!                    TPWrite "[INFO] end communication";
!                    SocketSend client_socket \Str := "end_ack";! add real cordinates here
!                    SocketClose client_socket;
!                    RETURN;

                CASE "Gripp":
                
                 SocketSend client_socket \Str:= "Ack_wait";
                 !grip function
                 SocketSend client_socket \Str:= "Ack_Gripp done";
                
                 CASE "Release":
                 
                 SocketSend client_socket \Str:= "Ack_wait";
                 !Release function
                 SocketSend client_socket \Str:= "Ack_Release done";
                 
                DEFAULT:
                TPWrite "[INFO] message from client: "+message;
                SocketSend client_socket \Str := "default_"+message;! add real cordinates here
            ENDTEST
            message := ""; ! reset message

        ENDWHILE

    ERROR ! if errors occure during run
        IF ERRNO = ERR_SOCK_CLOSED THEN ! clinet closed connection before sending end ack!
            server_init;
            RETRY;
        ELSEIF ERRNO = ERR_SOCK_TIMEOUT THEN
            RETRY;
        ENDIF
    ENDPROC
    
        ! move robot 
    PROC MoveRob()
        VAR pos target_pos;
        VAR orient target_orient;
        VAR robtarget target;
        VAR jointtarget joints;
        ! expect message [x,y,z] commands next
        SocketReceive client_socket \Str := message;
        target_pos := rob_coordinates(message);
        SocketSend client_socket \Str:= " Ack_Orientation_Received";
        
        ! expect message [q1,q2,q3,q4] commands next
        SocketReceive client_socket \Str := message;
        target_orient := rob_orientation(message);
        
        SocketSend client_socket \Str:= " Ack_Wait";
        target := CRobT(\Tool:=tool0 \WObj:=wobj0); ! copy same as hand frame
        target.trans := target_pos;
        target.rot := target_orient;
           
        joints := CalcJointT(target,tool0 \WObj:=wobj0);
        
        MoveJ target,vmax \T:=5,z30,tool0;
        
        SocketSend client_socket \Str:= " Ack_Done"; ! send new command or end communication   
    ERROR
        IF ERRNO = ERR_ROBLIMIT THEN
            SocketSend client_socket \Str:= "can't reach that possition,try again";
            RETURN;
        ENDIF
    ENDPROC
    
ENDMODULE