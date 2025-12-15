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

!        TPWrite "mugs pos:" \Pos:=mug_position;
        mug_position := mug_position + [0,0,1]*zOffset(mug_normal) + ([1,0,0]*x_offset + [0,1,0]*y_offset +[0,0,1]*z_offset);
!        TPWrite "mugs after offsets pos:" \Pos:=mug_position;
        
        target.rot := hand_rotation;
        target.trans := mug_position - offset_dir*offset_lenght;
!        TPWrite "mugs offset pos:" \Pos:=mug_position;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,step_size,max_magnitude,movement_speed;
        
        ! grippers out
        WaitTime(1);
        g_GripOut;
                
        !ask for confermation
!        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset;
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,step_size,max_magnitude,movement_speed;
        
        ! grippers in
        WaitTime(1);
        
        g_GripIn;
        
!        WaitTime(1);
!        moveL Offs(target,0,0,30),movement_speed,z50,tGripper;
        
        target.trans := mug_position - offset_dir*offset_lenght  + [0,0,1]*offset_z_when_fetching;
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,step_size,max_magnitude,movement_speed;
        
    ENDPROC
    
  
    PROC handOverSequence()
        VAR robtarget target;
        VAR pos offset_dir;
       
        ! get right pose
        target := CRobT(\Tool := tGripper);
        
        target.rot := MugHandOverOrient(); ! should add normal
        
        offset_dir := RotatePointUsingQuaternion([0,0,1],target.rot);
        offset_dir.x := Round(offset_dir.x \Dec:=4);
        offset_dir.y := Round(offset_dir.y \Dec:=4);
        offset_dir.z := Round(offset_dir.z \Dec:=4);
        
        target.trans := shared_movement_left.hand_over_pose.position - offset_dir*gripper_offset;
        ConfJ \Off;
        
        ! move to right pose
!        moveJ target,movement_speed,z50,tGripper;
        MovementProc target,step_size,max_magnitude,movement_speed;
        shared_movement_left.wait_flag := FALSE;
        
        ! wait for right arm
        WaitUntil shared_movement_left.wait_flag = TRUE;
        
        ! open gripper and move back
        
        g_GripOut;
        
        
        WaitTime(1);
        target.trans := target.trans - offset_dir*(pick_offset+gripper_offset);
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,50,max_magnitude,movement_speed;
        
        
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
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,step_size,max_magnitude,movement_speed;
        WaitTime(1);
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        ! Leave mug
        target.trans := mug_end_position;
        moveL target,movement_speed,z50,tGripper;
        
        ! grippers out
        WaitTime(1);
        
        target.trans := mug_end_position + offset;
        moveL target,movement_speed,z50,tGripper;
        
       
   ENDPROC
    
ENDMODULE

   