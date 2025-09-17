MODULE CppCommunication

    VAR socketdev sd;
    VAR string ipAddress := "192.168.0.100";
    VAR num port := 5000;
    VAR string sendMsg := "Hello from RAPID!";
    VAR string recvMsg;
    VAR num bytesSent;
    VAR num bytesRecv;

    PROC Main()
        ! Open socket connection
        sd := SocketCreate();
        SocketConnect sd, ipAddress, port;
        
        ! Send message
        !bytesSent := SocketSend(sd, sendMsg);
        
        ! Receive message
        bytesRecv := SocketReceive(sd, recvMsg, 256);
        
        ! Close socket
        SocketClose(sd);
    ENDPROC

ENDMODULE