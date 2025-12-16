MODULE MugManipulation
! FETCH MUG
!    ***********************************************************

!   This system extract the wanted hand pose depending on the position and mug normal
!   Then the system move the gripper to that pose with a offset "offset_lenght"
!   Init a gripp in and out sequence that fetch the mug in the local z offset of the gripper

!    ***********************************************************
    PROC FetchMug(pos mug_position, num offset_lenght, pos mug_normal)
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
        WaitTime(sequence_delay);
        g_GripOut;
                
        
        !pick up mug
        target.trans := mug_position + offset_dir*gripper_offset;
        moveL target,movement_speed,z50,tGripper;
        
        ! grippers in
        WaitTime(sequence_delay);
        g_GripIn;
        
        target.trans := mug_position - offset_dir*offset_lenght  + [0,0,1]*offset_z_when_fetching;
        moveL target,movement_speed,z50,tGripper;
        
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
    
        target_pos := shared_movement_right.hand_over_pose.position + [0,0,1]*20 - [0,1,0]*100;
        target.trans := target_pos - pick_offset*offset_dir;
        ! go to pose with offset
        ConfJ \Off;
!        moveJ target,movespeed,z50,tGripper;
        MovementProc target,step_size,max_magnitude,movement_speed;
        
        ! open gripper
        g_GripOut;
        
        WaitTime(1);
        shared_movement_right.wait_flag := FALSE;
        
        ! Wait until left arm is ready
        WaitUntil shared_movement_right.wait_flag = TRUE;
        
        ! move in and gripp
        target.trans := target_pos;
        MovementProc target,step_size,max_magnitude,movement_speed;
        g_GripIn;
        WaitTime(1);
        
        ! wait for left arm to move
        shared_movement_right.wait_flag := FALSE;
        WaitUntil shared_movement_right.wait_flag = TRUE;
        
        ! done
        
    ENDPROC
        
    
! LEAVE MUG
!    ***********************************************************

!   Leave the mug at a designated end pose
!   generate a wanted hand pose depending on mug position and normal
!   move to pose with a "offset_lenght"
!   move down and release gripper then move back up

!    ***********************************************************
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
        
        MovementProc target,step_size,max_magnitude,movement_speed;
        WaitTime(sequence_delay);
                
        !ask for confermation
        TPWrite("At mug picking frame");
        
        ! Leave mug
        target.trans := mug_end_position;
        moveL target,movement_speed,z50,tGripper;
        
        ! grippers out
        WaitTime(sequence_delay);
        
        target.trans := mug_end_position + offset;
        moveL target,movement_speed,z50,tGripper;
       
   ENDPROC
   
   ! hardcoded end pose because lack of time
   PROC LeaveMugV2()
        VAR robtarget end_target;
        
        end_target := [[513.42,-441.85,110.96],[0.353418,-0.368452,0.597902,-0.617941],[1,1,1,4],[-179.943,9E+09,9E+09,9E+09,9E+09,9E+09]];
        
        ConfJ \On;
        
        MoveJ end_target,movement_speed,fine,tGripper;
        MoveJ Offs(end_target,0,0,-60),movement_speed,fine,tGripper;
        
        g_GripOut;
        WaitTime(1);
        
        MoveJ end_target,movement_speed,fine,tGripper;
   ENDPROC
ENDMODULE

   