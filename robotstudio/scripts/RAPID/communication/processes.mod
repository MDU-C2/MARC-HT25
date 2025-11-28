MODULE processes
!    ***********************************************************
!     Process: EGMMovement

!     Description: Gets starting position from tcp socket and initiates EGM in bot python and movement task.
    
!    ***********************************************************
    PROC EGMMovement()
        VAR robtarget starting_point;
        
!        starting_point:=[[0,0,0],[0.00944177,-0.683755,0.728027,-0.0486451],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];
!        starting_point.trans := getMugCoordinates();
        
        WaitUntil shared_movement_vars.wait_flag=FALSE;
        
        shared_movement_vars.flag:=8;
!        shared_movement_vars.target:=starting_point;
!        SocketSend client_socket\Str:="enable_EGM";
        
        shared_movement_vars.wait_flag:=TRUE;
        
    ENDPROC
    
    
!    ***********************************************************
!     Process: Grip

!     Description: Sets shared flag to initiate Gripper Grip in movement task.
    
!    ***********************************************************
    PROC Grip()
        TPWrite("[INFO] client wants to close the gripper");
        WaitUntil shared_movement_vars.wait_flag=FALSE;
        shared_movement_vars.flag:=3; 
        shared_movement_vars.wait_flag:=TRUE;
        
    ENDPROC
    
    
!    ***********************************************************
!     Process: Release

!     Description: Sets shared flag to initiate Gripper Release in movement task.
    
!    ***********************************************************
    PROC Release()
        TPWrite("[INFO] client wants to open gripper");

        WaitUntil shared_movement_vars.wait_flag=FALSE;
        SocketSend client_socket\Str:="AskNext";

        shared_movement_vars.flag:=4; 
        shared_movement_vars.wait_flag:=TRUE;
    ENDPROC 
    
    
!    ***********************************************************
!     Process: moveToHomeTarget

!     Description: Sets shared flag to initiate home target movement in movement task.
    
!    *********************************************************** 
    PROC moveToHomeTarget()
        WaitUntil shared_movement_vars.wait_flag=FALSE;
        shared_movement_vars.flag:=5; 
        shared_movement_vars.wait_flag:=TRUE;
    ENDPROC
    
    
!    ***********************************************************
!     Process: sendHandCoordinates

!     Description: Sends current hand frame coordinates over TCP socket (to python vision system) as a string
    
!    *********************************************************** 
    PROC sendHandCoordinates()
        VAR string tempdata;
        TPWrite "[INFO] client wants hand coordinates";

        SocketSend client_socket\Str:="Robot_Wants_To_Send_Coordinates";
        SocketReceive client_socket\Str:=tempdata; ! ACK
        
        hand_frame:=CRobT(\Tool:=tGripper);
        SocketSend client_socket\Str:=RobPosToString(hand_frame.trans);
        SocketReceive client_socket\Str:=tempdata; ! ACK
    ENDPROC
    
    
!    ***********************************************************
!     Process: sendHandOrientation

!     Description: Sends current hand frame orientation over TCP socket (to python vision system) as a string
    
!    *********************************************************** 
    PROC sendHandOrientation()
        VAR string tempdata;
        TPWrite "[INFO] client wants hand orientation";
        SocketSend client_socket\Str:="Robot_Wants_To_Send_Orientation";
        SocketReceive client_socket\Str:=tempdata; ! ACK
        
        hand_frame:=CRobT(\Tool:=tGripper);
        SocketSend client_socket\Str:=RobOrientToString(hand_frame.rot);
        SocketReceive client_socket\Str:=tempdata; ! ACK
        
    ENDPROC
    
    
    
    PROC calibrationMovement()
        VAR bool ok;
        VAR num index;
        SocketSend client_socket\Str:="AskCalPoint";
        SocketReceive client_socket\Str:=message; ! position number
        ok := StrToVal(message,index);
        WaitUntil shared_movement_vars.wait_flag=FALSE;
        shared_movement_vars.flag:=9;
        shared_movement_vars.target := calib_robtargets{index};
        shared_movement_vars.wait_flag:=TRUE;
                
    ENDPROC
    
    
!    ***********************************************************
!     Function: GetRobTarget_two

!     Description: Recieve and check coordinates and orientation from TCP socket (from python vision system)

!     Returns: Returns a robtarget
    
!    *********************************************************** 
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
    
    
!    ***********************************************************
!     Function: GetMugCoordinates

!     Description: Recieve and check coordinates from TCP socket (from python vision system)

!     Returns: Returns a pos
    
!    *********************************************************** 
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
    
    
!    ***********************************************************
!     Function: GetMugOrient

!     Description: Recieve and check orientation from TCP socket (from python vision system)

!     Returns: Returns a orient
    
!    *********************************************************** 
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
            sucess:=rob_orientation(message,return_Orientation);
        ENDWHILE

        return_Orientation:=NormilizeRotation(return_Orientation);

        WaitTime(delay_time);

        RETURN return_Orientation;
        
    ENDFUNC
    
    FUNC bool MoveRob(robtarget target)

        WaitUntil shared_movement_vars.wait_flag=FALSE;
        shared_movement_vars.flag:=1;

        !EXCLAIMER TEMPORARY CONSTANT ORIENTATION
        target.rot:=[0.00274,0.75169,0.65950,-0.00414];
        target.trans.z := -28;
        IF VectMagn(target.trans) > 560 THEN
            shared_movement_vars.flag:=0;
            RETURN FALSE;
        ENDIF

        shared_movement_vars.target:=target;
!        shared_vars.joint_values := CalcJointT(target,tGripper); ! get target joint values

        shared_movement_vars.wait_flag:=TRUE;
        
        WaitUntil shared_movement_vars.wait_flag =FALSE;
        RETURN TRUE;
    ERROR
        IF ERRNO=ERR_ROBLIMIT THEN
            ! exead limit, send error to client and expect new coordinates
            RETURN FALSE;
        ELSEIF ERRNO=ERR_OUTSIDE_REACH THEN
            RETURN FALSE;
        ENDIF
    ENDFUNC

    FUNC robtarget GetRobTarget()
        VAR bool sucess:=FALSE;
        VAR robtarget return_target;
        return_target:=[[611.44,-10,224.449],[0.00944177,-0.683755,0.728027,-0.0486451],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];
        !CRobT(\Tool:= tGripper); !init values

        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_Coordinate";
        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,return_target.trans);
        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_Coordinate";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,return_target.trans);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=return_target.trans;
        SocketSend client_socket\Str:="Ack_Coordinate";
        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_Orientation";

        ! expect message [q1,q2,q3,q4] commands next
        SocketReceive client_socket\Str:=message;
        sucess:=rob_orientation(message,return_target.rot);

        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_Orientation";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_orientation(message,return_target.rot);
        ENDWHILE

        return_target.rot:=NormilizeRotation(return_target.rot);


        SocketSend client_socket\Str:="Ack_Orientation";
        WaitTime(delay_time);

        RETURN return_target;
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDFUNC

ENDMODULE