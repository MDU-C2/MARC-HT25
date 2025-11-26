MODULE GiveCup
    
    
    RECORD mug_vector
        pos position;
        pos normal;
    ENDRECORD
    
    !flag values:
    ! 0 = nothing
    ! 1 = hand over
    ! 2 = fetch
    ! 3 = drop off
    ! 4 = go home
    RECORD shared_information
      num right_flag;  
      num left_flag;
      mug_vector hand_over_pose;
      mug_vector mug;
      bool right_in_process;
      bool left_in_process;
    ENDRECORD
    PERS shared_information multi_move;
    
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
        MovementProc target,50,300,movespeed;
        ! grippers out
        WaitTime(1);
        g_GripOut;
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movespeed;
        ! grippers in
        WaitTime(1);
        g_GripIn;
        
        target.trans := mug_position - offset_dir*offset_lenght;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movespeed;
        
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
    
    ! hand over mug to other hand
    PROC HandOverMug()
        
        
        
    ENDPROC
    
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
        moveJ target,movespeed,z50,tGripper;
        WaitTime(1);
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        ! Leave mug
        target.trans := mug_end_position;
        moveJ target,movespeed,z50,tGripper;
        
        ! grippers out
        WaitTime(1);
        
        target.trans := mug_end_position + offset;
        moveJ target,movespeed,z50,tGripper;
        
       
   ENDPROC
    
ENDMODULE

   