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

        TPWrite "mugs pos:" \Pos:=mug_position;
        mug_position := mug_position + [0,0,1]*zOffset(mug_normal) + ([1,0,0]*x_offset + [0,1,0]*y_offset +[0,0,1]*z_offset);
        TPWrite "mugs after offsets pos:" \Pos:=mug_position;
        
        target.rot := hand_rotation;
        target.trans := mug_position - offset_dir*offset_lenght;
        TPWrite "mugs offset pos:" \Pos:=mug_position;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,50,300,movement_speed;
        
        ! grippers out
        WaitTime(1);
        g_GripOut;
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset ;
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,50,300,movement_speed;
        
        ! grippers in
        WaitTime(1);
        g_GripIn;
        
        target.trans := mug_position - offset_dir*offset_lenght;
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,50,300,movement_speed;
        
    ENDPROC
    
  
    PROC handOverSequence()
!        VAR robtarget target;
        
!        ConfJ\Off;
    
!        target := CRobT(\Tool:=Gripper);
!        target.trans := multi_move.hand_over_pose.position;
!        target.rot := MugHandOverOrient();
        
!        moveJ target,movespeed,z50,Gripper;
!!            MovementProc target,movespeed,z50,tGripper;

!        ! wait untill right arm is in right poss
!        multi_move.right_in_process := TRUE;
!        multi_move.left_in_process := FALSE;
!        WaitUntil multi_move.left_in_process = TRUE;
        
!        !open gripper
        
!        target.trans := multi_move.hand_over_pose.position + [0,1,0]*mug_offset*2;
!        moveJ target,movespeed,z50,Gripper;
!!            MovementProc home_target,movespeed,z50,tGripper;
        
!        ! tell right arm that we are not in the way
!        multi_move.right_in_process := TRUE;
    ENDPROC
        
    ! leave mug
   PROC LeaveMug(pos mug_end_position, pos mug_end_normal, num offset_lenght)
        VAR robtarget target;
        VAR orient hand_rotation;
        VAR pos offset;
        
        hand_rotation := NormalToOrientationSemiOptimal(mug_end_position,mug_end_normal);
        offset := [0,0,1]*offset_lenght+ ([1,0,0]*x_offset + [0,1,0]*y_offset +[0,0,1]*z_offset); ! we always want to move straight up after leaving mug
        target := CRobT(\Tool := tGripper);
        ConfJ \Off;

       TPWrite "q:" \Orient:=hand_rotation;
       
        target.rot := hand_rotation;
        target.trans := mug_end_position + offset;
        
        moveJ target,movement_speed,z50,tGripper;
        WaitTime(1);
                
        ! Leave mug
        target.trans := mug_end_position;
        moveL target,movement_speed,z50,tGripper;
        
        ! grippers out
        WaitTime(1);
        g_GripOut;
        
        target.trans := mug_end_position + offset;
        moveL target,movement_speed,z50,tGripper;
        
       
   ENDPROC
    
ENDMODULE

   