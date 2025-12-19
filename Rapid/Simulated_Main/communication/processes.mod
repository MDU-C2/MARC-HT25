MODULE processes
!    ***********************************************************
!     Process: EGMMovement

!     Description: Gets starting position from tcp socket and initiates EGM in bot python and movement task.
    
!    ***********************************************************
    PROC EGMMovement()

        WaitUntil shared_movement_left.wait_flag=FALSE;
        
        shared_movement_left.flag:=flag_move_EGM;
!        SocketSend client_socket\Str:="enable_EGM";
        
        shared_movement_left.wait_flag:=TRUE;
        
    ENDPROC
    
    
!    ***********************************************************
!     Process: Grip

!     Description: Sets shared flag to initiate Gripper Grip in movement task.
    
!    ***********************************************************
    PROC Grip()
        TPWrite("[INFO] client wants to close the gripper");
        WaitUntil shared_movement_left.wait_flag=FALSE;
        shared_movement_left.flag:=flag_gripper_grip; 
        shared_movement_left.wait_flag:=TRUE;
  
    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ENDIF
    ENDPROC
    
    
!    ***********************************************************
!     Process: Release

!     Description: Sets shared flag to initiate Gripper Release in movement task.
    
!    ***********************************************************
    PROC Release()
        TPWrite("[INFO] client wants to open gripper");

        WaitUntil shared_movement_left.wait_flag=FALSE;
        SocketSend client_socket\Str:="AskNext";

        shared_movement_left.flag:=flag_gripper_release; 
        shared_movement_left.wait_flag:=TRUE;
   ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ENDIF
    ENDPROC 
    
    
!    ***********************************************************
!     Process: moveToHomeTarget

!     Description: Sets shared flag to initiate home target movement in movement task.
    
!    *********************************************************** 
    PROC moveToHomeTarget()
        WaitUntil shared_movement_left.wait_flag=FALSE;
        WaitUntil shared_movement_right.wait_flag=FALSE;
        shared_movement_left.flag:=flag_move_home_target;
        shared_movement_right.flag:=flag_move_home_target;
!        shared_movement_left.flag:=flag_move_calibration;
!        shared_movement_left.flag:=flag_move_home;
        shared_movement_left.wait_flag:=TRUE;
        shared_movement_right.wait_flag:=TRUE;
    
    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ENDIF
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
        
       IF position_in_file_index < calib_array_size + 1 THEN
            hand_frame:=CRobT(\Tool:=tGripper);
        ELSE
            hand_frame:=current_right_target;
       ENDIF
       ! testing
        SocketSend client_socket\Str:=RobPosToString(hand_frame.trans);
        SocketReceive client_socket\Str:=tempdata; ! ACK
    
    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ENDIF
    ENDPROC
    
    
!    ***********************************************************
!     Process: sendHandOrientation

!     Description: Sends current left hand frame orientation over TCP socket (to python vision system) as a string
    
!    *********************************************************** 
    PROC sendHandOrientation()
        VAR string tempdata;
        TPWrite "[INFO] client wants hand orientation";
        SocketSend client_socket\Str:="Robot_Wants_To_Send_Orientation";
        SocketReceive client_socket\Str:=tempdata; ! ACK
        
        IF position_in_file_index < calib_array_size + 1 THEN
            hand_frame:=CRobT(\Tool:=tGripper);
        ELSE
            hand_frame:=current_right_target;
        ENDIF
        SocketSend client_socket\Str:=RobOrientToString(hand_frame.rot);
        SocketReceive client_socket\Str:=tempdata; ! ACK
    
    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ENDIF
        
    ENDPROC
    
    
!    ***********************************************************
!     Process: calibrationMovement

!     Description: Asks for calibration position index over TCP and set shared target to corresponding posision, set flag to 9 (Calib movement).
    
!    *********************************************************** 
    PROC calibrationMovement()
        VAR bool ok;
        

        WaitUntil shared_movement_right.wait_flag=FALSE; !Wait for movement to be ready
        WaitUntil shared_movement_left.wait_flag=FALSE;
        
        SocketSend client_socket\Str:="AskCalPoint";
        SocketReceive client_socket\Str:=message; ! position number
        ok := StrToVal(message,position_in_file_index); ! saves value in index
        
        IF position_in_file_index < 41 THEN
            
            ! move right out of way
            shared_movement_right.flag := flag_move_calibration_outofway;
            shared_movement_right.wait_flag:=TRUE;
            WaitUntil shared_movement_right.wait_flag=FALSE; !Wait for movement to be ready
            
            shared_movement_left.flag:=flag_move_calibration; !Set flag to 9 (calibration movement)
            shared_movement_left.target := calib_robtargets{position_in_file_index}; !set shared robtarget to corresponding calibration position
            shared_movement_left.wait_flag:=TRUE;
            WaitUntil shared_movement_left.wait_flag=FALSE; !Wait for movement to be done
        ELSE
            ! move left out of way
            shared_movement_left.flag := flag_move_calibration_outofway;
            shared_movement_left.wait_flag:=TRUE;
            WaitUntil shared_movement_left.wait_flag=FALSE; !Wait for movement to be ready
            
            shared_movement_right.flag:=flag_move_calibration; !Set flag to 9 (calibration movement)
            shared_movement_right.target := calib_robtargets_right{position_in_file_index - 40}; !set shared robtarget to corresponding calibration position
            shared_movement_right.wait_flag:=TRUE;
            WaitUntil shared_movement_right.wait_flag=FALSE; !Wait for movement to be done
        ENDIF
    
    ERROR
        ! if errors occure during run
        IF ERRNO=ERR_SOCK_CLOSED THEN
            ! clinet closed connection before sending end ack!
            server_init;
            RETURN ;
        ENDIF
                
    ENDPROC 
    
    PROC calibrationMoveHome()
        IF position_in_file_index < calib_array_size + 1 THEN 
            
            shared_movement_left.flag:=flag_move_calibration_home; 
            shared_movement_left.wait_flag:=TRUE; !Wait for movement to be ready

        ELSE
            shared_movement_right.flag:=flag_move_calibration_home; 
            shared_movement_right.wait_flag:=TRUE; !Wait for movement to be ready
        ENDIF
        
        WaitUntil shared_movement_left.wait_flag=FALSE; !Wait for movement to be done
        WaitUntil shared_movement_right.wait_flag=FALSE; !Wait for movement to be done
    ENDPROC
    
    PROC pickupSequence()
       
        VAR mug_vector buffer;
        buffer := GetRobVector();
        
        ! if mug standing up
        IF abs(buffer.normal.z) < abs(buffer.normal.x) AND abs(buffer.normal.z) < abs(buffer.normal.y) THEN
            TPWrite "mug z value: " \Num:=buffer.normal.z;
            IF buffer.position.z < min_z_value THEN
                buffer.position.z := min_z_value;
            ENDIF
        ENDIF
        buffer.position.z := 65;
        ! mug to far to the right
        IF buffer.position.y < -100 THEN
            MoveRobMugVector buffer,FALSE;
            WaitUntil shared_movement_right.wait_flag = FALSE;
            leaveSequence;
        ELSE
            MoveRobMugVector buffer,TRUE;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            HandOverSequence;
            WaitUntil shared_movement_left.wait_flag = FALSE;
            leaveSequence;
        ENDIF
        moveToHomeTarget;
                
    ENDPROC
    
    PROC HandOverSequence()
        
        ! assumes left is holding the mug in right orient
        VAR mug_vector hand_over_pose;
        
        WaitUntil shared_movement_right.wait_flag = FALSE;
        WaitUntil shared_movement_left.wait_flag = FALSE;
        
        ! init all variables
        hand_over_pose := [GetHandOverPos(),[0,0,-1]];
        
        TPWrite "hand over pos:" \Pos:= hand_over_pose.position;
        
        shared_movement_left.hand_over_pose := hand_over_pose;
        shared_movement_right.hand_over_pose := hand_over_pose;
        
        shared_movement_left.flag := flag_hand_over;
        shared_movement_right.flag := flag_hand_over;
        
        shared_movement_right.wait_flag := TRUE;
        shared_movement_left.wait_flag := TRUE;
        
        ! wait until left and right arm is in right pose
        WaitUntil shared_movement_right.wait_flag = FALSE;
        WaitUntil shared_movement_left.wait_flag = FALSE;
        
        ! let right arm keep on going 
        shared_movement_right.wait_flag := TRUE;
        
        ! wait until right hand hold mug
        WaitUntil shared_movement_right.wait_flag = FALSE;
        
        ! let left hand release and go back
        shared_movement_left.wait_flag := TRUE;
        
        ! wait until left hand moves back
        WaitUntil shared_movement_left.wait_flag = FALSE;
        
        ! let right hand move back
        shared_movement_right.wait_flag := TRUE;
        
    ENDPROC
    
    PROC leaveSequence()
        ! assumes always the right arm holding the mug!!!!
        
        shared_movement_right.flag := flag_move_home_target;
        shared_movement_right.mug := mug_leave_pose;
        shared_movement_right.wait_flag := TRUE;
        
        WaitUntil shared_movement_right.wait_flag = FALSE;
        
        shared_movement_right.flag := flag_leave_mug;
        shared_movement_right.wait_flag := TRUE;
        
        WaitUntil shared_movement_right.wait_flag = FALSE;
        
    ENDPROC
!    ***********************************************************
!     Function: GetRobTarget_two

!     Description: Recieve and check coordinates and orientation from TCP socket (from python vision system)

!     Returns: Returns a left arm robtarget
    
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

!     Returns: Returns the left arm pos
    
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

!     Returns: Returns an left arm orient
    
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

        WaitUntil shared_movement_left.wait_flag=FALSE;
        shared_movement_left.flag:=1;

        !EXCLAIMER TEMPORARY CONSTANT ORIENTATION & Z-value
        target.rot:=[0.00274,0.75169,0.65950,-0.00414];
        target.trans.z := 40;
        
        !EXCLAIMER TEMPORARY MAXIMUM REACH DISTANCE
        IF VectMagn(target.trans) > 560 THEN
            shared_movement_left.flag:=0;
            RETURN FALSE;
        ENDIF

        shared_movement_left.target:=target;

        shared_movement_left.wait_flag:=TRUE;
        
        WaitUntil shared_movement_left.wait_flag =FALSE;
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
    
    
    ! ============================ ebn support functions ================================
      ! move robot to target
    PROC MoveRobMugVector(mug_vector target, bool left_arm)
    
        IF left_arm THEN
            shared_movement_left.mug := target; 
            shared_movement_left.flag := flag_pick_up_mug;
            shared_movement_left.wait_flag := TRUE;
            
            WaitUntil shared_movement_left.wait_flag = FALSE;
        ELSE
            shared_movement_right.mug := target; 
            shared_movement_right.flag := flag_pick_up_mug;
            shared_movement_right.wait_flag := TRUE;
            
            WaitUntil shared_movement_right.wait_flag = FALSE;
            
        ENDIF
        
    ENDPROC

    FUNC mug_vector GetRobVector()
        VAR bool sucess;
        VAR mug_vector target;
        target:=[[611.44,-10,224.449],[0,0,1]]; ! temp

        WaitTime(delay_time);
        SocketSend client_socket\Str:="Ask_Coordinate";
        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,target.position);
        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_Coordinate";

            SocketReceive client_socket\Str:=message;
            
            sucess:=rob_coordinates(message,target.position);
        ENDWHILE
        TPWrite "Recieved pos(GetRobTarget):"\Pos:=target.position;
        SocketSend client_socket\Str:="Ack_Coordinate";
        WaitTime(delay_time);
        
        
        SocketSend client_socket\Str:="Ask_MugNormal";

        SocketReceive client_socket\Str:=message;
        sucess:=rob_coordinates(message,target.normal);

        WHILE NOT sucess DO
            SocketSend client_socket\Str:="[ERROR]_wrong_format,try_again(exampel[q1,q2,q3,q4])";
            WaitTime(delay_time);
            SocketSend client_socket\Str:="Ask_MugNormal";

            SocketReceive client_socket\Str:=message;
            sucess:=rob_coordinates(message,target.normal);
        ENDWHILE
        WaitTime(delay_time);

        RETURN target;
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDFUNC
    
ENDMODULE