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
        VAR pos offset;
        !go to postion
        hand_rotation := NormalToOrientationSemiOptimal(mug_position,mug_normal);
!        hand_rotation := NormalToOrientation(mug_normal);
        
        offset := RotatePointUsingQuaternion([0,0,1],hand_rotation)*offset_lenght;
        offset.x := Round(offset.x \Dec:=4);
        offset.y := Round(offset.y \Dec:=4);
        offset.z := Round(offset.z \Dec:=4);
        
        target := CRobT(\Tool := tGripper);
        ConfJ \Off;

        target.rot := hand_rotation;
        target.trans := mug_position - offset;
        moveJ target,movespeed,z50,tGripper;
!        MovementProc target,50,300,movespeed;
        ! grippers out
        WaitTime(1);
!         g_GripOut;
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position;
        moveJ target,movespeed,z50,tGripper;
!        MovementProc target,50,300,movespeed;
        ! grippers in
        WaitTime(1);
!         g_GripIn;
        
        target.trans := mug_position - offset;
        moveJ target,movespeed,z50,tGripper;
!        MovementProc target,50,300,movespeed;
        
    ENDPROC
    
    ! hand over mug to other hand
    PROC HandOverMug()
        
        
        
    ENDPROC
    
    ! leave mug
   PROC LeaveMug(pos mug_end_position, pos mug_end_normal)
        VAR robtarget target;
        VAR orient hand_rotation;
        VAR pos offset;
        VAR num offset_lenght;
        offset_lenght := 50;
        
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

   