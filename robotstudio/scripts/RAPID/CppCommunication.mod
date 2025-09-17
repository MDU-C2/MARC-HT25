MODULE CppCommunication

    VAR socketdev sd;
    VAR string ipAddress := "10.132.174.178";
    VAR num port := 5000;
    VAR string sendMsg := "Hello from RAPID!";
    VAR string recvMsg;
    !VAR num bytesSent;
    !VAR num bytesRecv;

    PROC main()
        SocketClose sd;
        ! Open socket connection
        SocketCreate sd;
        socketBind sd, ipAddress, port;
        SocketConnect sd, ipAddress, port;
        
        ! Send message
        SocketSend sd \Str := sendMsg;
        
        ! Receive message
        SocketReceive sd \Str := recvMsg;
        TPWrite recvMsg;
        
        ! Close socket
        SocketClose sd;
        TPWrite "socket closed";
    ENDPROC

ENDMODULE