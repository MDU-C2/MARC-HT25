MODULE processes
    PROC EGMMovement()
        VAR robtarget starting_point;
        
        starting_point:=[[0,0,0],[0.00944177,-0.683755,0.728027,-0.0486451],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];
        starting_point.trans := getMugCoordinates();
    ENDPROC
    
    FUNC robtarget GetRobTarget_two()
        VAR bool sucess:=FALSE;
        VAR robtarget return_target;
        return_target:=[[611.44,-10,224.449],[0.00944177,-0.683755,0.728027,-0.0486451],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];
        !CRobT(\Tool:= tGripper); !init values

        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_MugCoordinate";
        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,return_target.trans);
        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_MugCoordinate";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,return_target.trans);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=return_target.trans;
        SocketSend client_socket\Str:="Ask_MugOrientation";

        ! expect message [q1,q2,q3,q4] commands next
        SocketReceive client_socket\Str:=message;
        sucess:=rob_orientation(message,return_target.rot);

        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_MugOrientation";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_orientation(message,return_target.rot);
        ENDWHILE

        return_target.rot:=NormilizeRotation(return_target.rot);

        WaitTime(delay_time);

        RETURN return_target;
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDFUNC
    
    FUNC pos getMugCoordinates()
        VAR bool sucess:=FALSE;
        VAR pos return_Coordinates;

        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_MugCoordinate";
        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,return_Coordinates);
        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_MugCoordinate";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,return_Coordinates);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=return_Coordinates;
        
        RETURN return_Coordinates;
    ENDFUNC
    
    FUNC orient getMugOrient()
        VAR bool sucess:=FALSE;
        VAR orient return_Orientation;
        
        SocketSend client_socket\Str:="Ask_MugOrientation";

        ! expect message [q1,q2,q3,q4] commands next
        SocketReceive client_socket\Str:=message;
        sucess:=rob_orientation(message,return_Orientation);

        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_MugOrientation";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_orientation(message,return_Orientation;
        ENDWHILE

        return_Orientation:=NormilizeRotation(return_Orientation);

        WaitTime(delay_time);

        RETURN return_Orientation;
        
    ENDFUNC
    
ENDMODULE