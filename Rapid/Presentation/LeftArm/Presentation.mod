MODULE Presentation
    !FOR presentation
    PROC g_GripOut()
        TPWrite("Grip out");
    ENDPROC
    PROC g_GripIn()
        TPWrite("Grip in");
    ENDPROC
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
        
        TPWrite("move to pos + offset");
        
        shared_movement_left.wait_flag := False;
        WaitUntil shared_movement_left.wait_flag = TRUE;
        
        IF Faild() THEN
            RETURN;
        ENDIF
        g_GripOut;
                
        
        
        shared_movement_left.wait_flag := False;
        WaitUntil shared_movement_left.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset;
        moveL target,movement_speed,z50,tGripper;
        
        TPWrite("move to pos");
        
        shared_movement_left.wait_flag := False;
        WaitUntil shared_movement_left.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        ! grippers in
        WaitTime(sequence_delay);
        g_GripIn;
        
        
        shared_movement_left.wait_flag := False;
        WaitUntil shared_movement_left.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        TPWrite("move to pos + offset");
        target.trans := mug_position - offset_dir*offset_lenght  + [0,0,1]*offset_z_when_fetching;
        moveL target,movement_speed,z50,tGripper;

    ENDPROC
    
! LEAVE MUG
!    ***********************************************************

!   Leave the mug at a designated end pose
!   generate a wanted hand pose depending on mug position and normal
!   move to pose with a "offset_lenght"
!   move down and release gripper then move back up

!    ***********************************************************
   PROC  PresentationLeaveMug(pos mug_end_position, pos mug_end_normal, num offset_lenght)
        VAR robtarget target;
        VAR orient hand_rotation;
        VAR pos offset;
        
        hand_rotation := NormalToOrientationSemiOptimal(mug_end_position,mug_end_normal);
        offset := [0,0,1]*offset_lenght; ! we always want to move straight up after leaving mug
        target := CRobT(\Tool := tGripper);
        ConfJ \Off;

        target.rot := hand_rotation;
        target.trans := mug_end_position + offset;
        
        MovementProc target,step_size,max_magnitude,movement_speed; 
        
        shared_movement_left.wait_flag := False;
        WaitUntil shared_movement_left.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        ! Leave mug
        target.trans := mug_end_position;
        moveL target,movement_speed,z50,tGripper;
        
        ! grippers out
        shared_movement_left.wait_flag := False;
        WaitUntil shared_movement_left.wait_flag = TRUE;
        IF Faild() THEN
            RETURN;
        ENDIF
        
        target.trans := mug_end_position + offset;
        moveL target,movement_speed,z50,tGripper;
       
   ENDPROC
   
   FUNC bool Faild()
       
       IF shared_movement_left.flag = -1 THEN
            moveToHomeTarget;
            WaitTime(sequence_delay);
           RETURN TRUE;
       ENDIF
       RETURN FALSE;  
   ENDFUNC
   
ENDMODULE