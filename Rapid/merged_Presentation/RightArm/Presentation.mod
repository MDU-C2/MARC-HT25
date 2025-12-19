MODULE Presentation
!    !FOR presentation
!    PROC g_GripOut()
!        TPWrite("Grip out");
!    ENDPROC
!    PROC g_GripIn()
!        TPWrite("Grip in");
!    ENDPROC
!    ***********************************************************
    PROC PresentationFetchMug(pos mug_position, num offset_lenght, pos mug_normal)
        VAR robtarget target;
        VAR orient hand_rotation;
        VAR pos offset_dir;
        
        !go to postion
        hand_rotation := NormalToOrientationSemiOptimal(mug_position,mug_normal);
        
        offset_dir := RotatePointUsingQuaternion([0,0,1],hand_rotation);
        offset_dir.x := Round(offset_dir.x \Dec:=4);
        offset_dir.y := Round(offset_dir.y \Dec:=4);
        offset_dir.z := Round(offset_dir.z \Dec:=4);
        
        target := CRobT(\Tool := tGripper);
        ConfJ \Off;

        ! final mug position         mug standin up or laying down     standard gripper offset 
        mug_position := mug_position  + [0,0,1]*zOffset(mug_normal) + ([1,0,0]*x_offset + [0,1,0]*y_offset +[0,0,1]*z_offset);
        
        target.rot := hand_rotation;
        target.trans := mug_position - offset_dir*offset_lenght;
        MovementProc target,step_size,max_magnitude,movement_speed;
        ! grippers out
        
        shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        
        IF Faild() THEN
            RETURN;
        ENDIF
        
        g_GripOut;
                
        
        
        shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        
        IF Faild() THEN
            RETURN;
        ENDIF
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset;
        moveL target,movement_speed,z50,tGripper;
        
        
        shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        ! grippers in
        WaitTime(sequence_delay);
        g_GripIn;
        
        
        shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        target.trans := mug_position - offset_dir*offset_lenght  + [0,0,1]*offset_z_when_fetching;
        moveL target,movement_speed,z50,tGripper;
        
        
        shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
    ENDPROC
    
! LEAVE MUG
!    ***********************************************************

!   Leave the mug at a designated end pose
!   generate a wanted hand pose depending on mug position and normal
!   move to pose with a "offset_lenght"
!   move down and release gripper then move back up

!    ***********************************************************
   PROC  PresentationLeaveMug(robtarget mug_end_target, num offset_lenght)
       VAR robtarget end_target;
        
        end_target := mug_end_target;
        
        ConfJ \On;
        
        MoveJ end_target,movement_speed,fine,tGripper;
        
        TPWrite("move to pos");
        shared_movement_right.wait_flag := FALSE;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        TPWrite("move to pos - offset");
        MoveJ Offs(end_target,0,0,-60),movement_speed,fine,tGripper;
        
         shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        g_GripOut;
        WaitTime(1);
        
         shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        TPWrite("move to pos");
        MoveJ end_target,movement_speed,fine,tGripper;
       
         shared_movement_right.wait_flag := False;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
   ENDPROC
   
   FUNC bool Faild()
       
       IF shared_movement_right.flag = -1 THEN
            moveToHomeTarget;
            WaitTime(sequence_delay);
           RETURN TRUE;
       ENDIF
       RETURN FALSE;  
   ENDFUNC
   
ENDMODULE