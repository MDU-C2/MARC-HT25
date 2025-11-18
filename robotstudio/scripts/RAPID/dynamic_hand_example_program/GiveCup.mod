MODULE GiveCup
    
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
         g_GripOut;
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movespeed;
        ! grippers in
        WaitTime(1);
         g_GripIn;
        
        target.trans := mug_position - offset;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movespeed;
        
    ENDPROC
    
    ! hand over mug to other hand
    PROC HandOverMug()
        
        
        
    ENDPROC
    
    
    ! leave mug
   PROC LeaveMug(pos mug_end_position, pos mug_end_normal)
       
   ENDPROC
    
   
   
    
ENDMODULE

   