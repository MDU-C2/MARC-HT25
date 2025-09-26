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
    VAR num coordinates_index := -1;
    
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
                CASE "end": 
                    TPWrite "[INFO] end communication";
                    SocketSend client_socket \Str := "end_ack";! add real cordinates here
                    SocketClose client_socket;
                    RETURN;
                
                CASE "coordinates":
                    TPWrite "[INFO] clinet want cordinates";
                    hand_frame := CRobT(\Tool:=tool0 \WObj:=wobj0);
                  !  SocketSend client_socket \Str :=  RobtargetToString(hand_frame) + "_ack";! add real cordinates here
                    
                DEFAULT:
                     coordinates_index := StrFind(message,0,"move");
                     
                    !IF(cordinates_index > 0) THEN !we got a move message!
                        !example input: move [x,y,z],[q1,q2,q3,q4]
                     !   moveRob(StrPart(message,coordinates_index,
                        
                        
                    !ELSE !something else
                        TPWrite "[INFO] message from client: "+message;
                      !  SocketSend client_socket \Str := "ack";! add real cordinates here
                    !ENDIF
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

!    FUNC string RobtargetToString(robtarget target)
        
!        !position
!        VAR string temp_string := "[";
!        temp_string := temp_string+NumToStr(target.trans.x,0)+",";
!        temp_string :=temp_string+NumToStr(target.trans.y,0)+",";
!        temp_string :=temp_string+NumToStr(target.trans.z,0)+"]";
        
!        !orientation
!        temp_string := temp_string+",[";
!        temp_string := temp_string+NumToStr(target.rot.q1,0)+";";
!        temp_string :=temp_string+NumToStr(target.rot.q2,0)+";";
!        temp_string :=temp_string+NumToStr(target.rot.q3,0)+";";
!        temp_string :=temp_string+NumToStr(target.rot.q4,0)+"]";
        
!        RETURN temp_string;
!    ENDFUNC
    
!    PROC moveRob(string target)
        
        
!    ENDPROC
ENDMODULE