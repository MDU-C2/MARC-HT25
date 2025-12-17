MODULE server

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

    CONST num min_z_value := 120;
    VAR num position_in_file_index;
    
    ! Open socket connection
    PROC server_init()
        ! port values
        VAR string ipAddress:="192.168.125.5";
        ! YuMi ip "192.168.0.1"
        VAR num port:=1025;

        !runs once in initzilise
        !can close socket even if they are not created!
        SocketClose server_socket;
        SocketClose client_socket;
    
        WaitTime(1);
        
        !create sockets
        SocketCreate server_socket;
    
        TPWrite ipAddress;
        TPWrite ""\Num:=port;
        !connect client and server
        socketBind server_socket,ipAddress,port;
        SocketListen server_socket;
        SocketAccept server_socket,client_socket\ClientAddress:=ipAddress;
        TPWrite("client connected");

    ERROR
   
        ! we use and expect errors in rapid,
        IF ERRNO=ERR_SOCK_TIMEOUT THEN
            ! if no client connected, try again
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

!            SocketReceive client_socket\Str:=message\Time:=30; !you have 30 sec to send message or conneciton closes
            
            SocketReceive client_socket\Str:=message;

            ! switch case
            TEST message

            CASE "Connection_test": 
                TPWrite("[INFO] client is sending test message");
                SocketSend client_socket\Str:="Connection_Confirmed";
                
            CASE "Get_Coordinates": 
                sendHandCoordinates;
                
            CASE "Move":
                Move;    
                
            CASE "Home":
                moveToHomeTarget;

            CASE "Pick_Up_Sequence":
                 pickupSequence; 
                 
            CASE "Leave_Sequence":
                leaveSequence;
                
            CASE "Move_Calibration_Position": 
                calibrationMovement;
                
            CASE "Move_Calibration_home": 
                calibrationMoveHome;
                           
            DEFAULT:
                TPWrite("[INFO] message from client: "+message);
                SocketSend client_socket\Str:="default_"+message;
            ENDTEST
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_next"; ! ask for next "order"

        ENDWHILE

    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ELSEIF ERRNO=ERR_SOCK_TIMEOUT THEN
            SocketClose client_socket;
            ! socket never send annything, close connection and return to main
            RETURN ;
        ENDIF
    ENDPROC


ENDMODULE