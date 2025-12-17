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
        MovementProc target,step_size,max_magnitude,movement_speed;
        
        ! grippers out
        WaitTime(0.2);
        g_GripOut;
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset ;
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,step_size,max_magnitude,movement_speed;
        
        ! grippers in
        WaitTime(1);
        g_GripIn;
        
        target.trans := mug_position - offset_dir*offset_lenght;
        moveL target,movement_speed,z50,tGripper;
!        MovementProc target,step_size,max_magnitude,movement_speed;
        
    ENDPROC
    
  
    PROC handOverSequence()
        VAR robtarget target;
        VAR pos offset_dir;
        VAR pos target_pos;
       
        ! get right pose 
        target := CRobT(\Tool := tGripper);
        target.rot := MugHandOverOrient();
        
        offset_dir := RotatePointUsingQuaternion([0,0,1],target.rot);
        offset_dir.x := Round(offset_dir.x \Dec:=4);
        offset_dir.y := Round(offset_dir.y \Dec:=4);
        offset_dir.z := Round(offset_dir.z \Dec:=4);
    
        target_pos := shared_movement_right.hand_over_pose.position + [0,0,1]*20;
        target.trans := target_pos - pick_offset*offset_dir;
        ! go to pose with offset
        ConfJ \Off;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,step_size,max_magnitude,movement_speed;
        
        ! open gripper
        g_GripOut;
        
        WaitTime(0.2);
        shared_movement_right.wait_flag := FALSE;
        
        ! Wait until left arm is ready
        WaitUntil shared_movement_right.wait_flag = TRUE;
        
        ! move in and gripp
        target.trans := target_pos;
        MovementProc offs(target,0,-30,0),step_size,max_magnitude,movement_speed;
        g_GripIn;
        WaitTime(0.2);
        
        ! wait for left arm to move
        shared_movement_right.wait_flag := FALSE;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        WaitTime(0.2);
        
        ! done
        
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
        
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,step_size,max_magnitude,movement_speed;
        WaitTime(1);
                
        ! Leave mug
        target.trans := mug_end_position;
        moveL target,movement_speed,z50,tGripper;
        
        ! grippers out
        WaitTime(0.2);
        g_GripOut;
        
        target.trans := mug_end_position + (offset*1.5);
        moveL target,movement_speed,z50,tGripper;
        
   ENDPROC
   
   PROC LeaveMugV2()
        VAR robtarget end_target;
        
        end_target := [[513.42,-441.85,110.96],[0.353418,-0.368452,0.597902,-0.617941],[1,1,1,4],[-179.943,9E+09,9E+09,9E+09,9E+09,9E+09]];
        
        ConfJ \On;
        
               
        MoveJ end_target,movement_speed,fine,tGripper;
        MoveJ Offs(end_target,0,0,-60),movement_speed,fine,tGripper;
        
        g_GripOut;
        WaitTime(0.2);
        
        MoveJ end_target,movement_speed,fine,tGripper;
   ENDPROC
ENDMODULE

   