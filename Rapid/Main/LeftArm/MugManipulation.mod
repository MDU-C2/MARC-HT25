MODULE MugManipulation

    ! fetch up mug
    PROC FetchMug(pos mug_position, num offset_lenght, pos mug_normal)
        VAR robtarget target;
        VAR orient hand_rotation;
        VAR pos offset_dir;
        !go to postion
        hand_rotation := NormalToOrientationSemiOptimal(mug_position,mug_normal);
!        hand_rotation := NormalToOrientation(mug_normal);
        
        offset_dir := RotatePointUsingQuaternion([0,0,1],hand_rotation);
        offset_dir.x := Round(offset_dir.x \Dec:=4);
        offset_dir.y := Round(offset_dir.y \Dec:=4);
        offset_dir.z := Round(offset_dir.z \Dec:=4);
        
        target := CRobT(\Tool := tGripper);
        ConfJ \Off;

        mug_position := mug_position - [0,0,1]*zOffset(mug_normal);
        
        target.rot := hand_rotation;
        target.trans := mug_position - offset_dir*offset_lenght;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movement_speed;
        
        ! grippers out
        WaitTime(1);
        g_GripOut;
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movement_speed;
        
        ! grippers in
        WaitTime(1);
        g_GripIn;
        
        target.trans := mug_position - offset_dir*offset_lenght;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movement_speed;
        
    ENDPROC
    
    ! the mug is longer if it standing up rather then laying down
    FUNC num ZOffset(pos normal)
        
        ! mug standing upright
        IF normal.z >= normal.x AND normal.z >= normal.y THEN
            RETURN 30;
        ELSE
            RETURN 20;
        ENDIF
            
    ENDFUNC
    
  FUNC pose HandOverTarget(pose end_target, pose mug_current_target)
    VAR pose middle_target;
    
    ! half way mark
    middle_target.trans := end_target.trans  - (end_target.trans - mug_current_target.trans)/2;
    
    ! to make it easier for the leaving arm
    middle_target.rot := end_target.rot;
    
        RETURN middle_target;
    ENDFUNC
    
    ! leave mug
   PROC LeaveMug(pos mug_end_position, pos mug_end_normal, num offset_lenght)
        VAR robtarget target;
        VAR orient hand_rotation;
        VAR pos offset;
        
        hand_rotation := NormalToOrientationSemiOptimal(mug_end_position,mug_end_normal);
        offset := [0,0,1]*offset_lenght; ! we always want to move straight up after leaving mug
        target := CRobT(\Tool := tGripper);
        ConfJ \Off;

       
        target.rot := hand_rotation;
        target.trans := mug_end_position + offset;
        moveJ target,movement_speed,z50,tGripper;
        WaitTime(1);
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        ! Leave mug
        target.trans := mug_end_position;
        moveJ target,movement_speed,z50,tGripper;
        
        ! grippers out
        WaitTime(1);
        
        target.trans := mug_end_position + offset;
        moveJ target,movement_speed,z50,tGripper;
        
       
   ENDPROC
    
ENDMODULE

   