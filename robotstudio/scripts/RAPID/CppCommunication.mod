MODULE CppCommunication

    VAR socketdev sd;
    VAR socketdev client;
    VAR string ipAddress := "127.0.0.1";
    VAR num port := 8080;
    VAR string sendMsg := "Hello from RAPID!";
    VAR string recvMsg := "";
    !VAR num bytesSent;
    !VAR num bytesRecv;

    PROC single_communication()
        WaitTime 0.5;
        SocketClose sd;
        WaitTime 0.5;
        ! Open socket connection
        SocketCreate sd;
        WaitTime 0.5;
        socketBind sd, ipAddress, port;
        WaitTime 0.5;
        !SocketConnect sd, ipAddress, port;
        !WaitTime 0.5;
        
        ! Send message
        !SocketSend sd \Str := sendMsg;
        SocketListen sd;
        
        SocketAccept sd,client\ClientAddress:=ipAddress;
        TPWrite "client connected";
        
        ! Receive message
        WHILE recvMsg = "" DO
            SocketReceive client \Str := recvMsg;
            WaitTime 0.5;
        ENDWHILE
        
        TPWrite recvMsg;
        
        ! Close socket
        SocketClose sd;
        WaitTime 0.5;
        TPWrite "socket closed";
    ENDPROC

ENDMODULE