MODULE server

    !==== variables ====!

    VAR socketdev server_socket;
    VAR socketdev client_socket;
    
    ! port values
    VAR string ipAddress := "127.0.0.1"; ! local host
    VAR num port := 8080;

    ! process variables
    VAR string message := "";
    VAR bool have_communication := TRUE;
    
 ! Open socket connection
    PROC server_init() !runs once in initzilise
        SocketCreate server_socket;
        socketBind server_socket, ipAddress, port;
    ERROR
        TPWrite("[ERROR] IN CONNECTING OR BINDING SERVER SOCKET!");
        EXIT;
    ENDPROC

    ! hold comminication while client is connected
    ! close communication if timer runs out or clinet close communication
    PROC single_client_communication() ! only want one clinet, therefore we do not need to open other ports and arange new connections!

        SocketListen server_socket;

        SocketAccept server_socket,client_socket\ClientAddress:=ipAddress;
        TPWrite ("client connected");

        ! while we want to have a communication we keep on having one
        WHILE have_communication DO

            SocketReceive client_socket \Str := message;
            ! swich case
            TEST message 
                CASE "end": 
                    TPWrite "[INFO] end communication";
                    have_communication := FALSE;
                    SocketSend client_socket \Str := "end_ack";! add real cordinates here
                
                CASE "cordinates":
                    TPWrite "[INFO] clinet want cordinates";
                    SocketSend client_socket \Str := "[1,2,3],[1,2,3,4]";! add real cordinates here
                    
                DEFAULT:
                     TPWrite "[INFO] message from client: "+message;
                    SocketSend client_socket \Str := "ack";! add real cordinates here
            ENDTEST

            WaitTime 0.1; ! in seconds, don't like this way but add delay

        ENDWHILE

        SocketClose server_socket;

    ERROR ! if errors occure during run
    
    IF ERRNO = ERR_SOCK_CLOSED THEN ! clinet closed connection before sending end ack!
        have_communication := FALSE;
        SocketClose server_socket;
    ENDIF
        
    ENDPROC

    !save data to ques or variables, but for now print 

ENDMODULE