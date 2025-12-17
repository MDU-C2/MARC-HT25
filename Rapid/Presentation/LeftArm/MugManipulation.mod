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
    
  
! HARD CODED HAND OVER SEQUENCE
!    ***********************************************************

!   sadly this became hardcoded because the lack of time
!   But in short move to desitgnated pose, wait for right hand to go in and grip the mug
!   Then release and move back 

!    ***********************************************************
    PROC handOverSequence(num offset_lenght)
        VAR robtarget target;
        VAR pos offset_dir;
        VAR jointtarget joints;
        ! get right pose
        target := CRobT(\Tool := tGripper);
        
        joints := CJointT();
        joints.robax.rax_6:=0;
        joints.robax.rax_4:=0;
        MoveAbsJ joints,movement_speed,z50,tGripper;
        TPWrite "axes 6 = 0";
        target.rot := MugHandOverOrient(); ! should add normal
        
        offset_dir := RotatePointUsingQuaternion([0,0,1],target.rot);
        offset_dir.x := Round(offset_dir.x \Dec:=4);
        offset_dir.y := Round(offset_dir.y \Dec:=4);
        offset_dir.z := Round(offset_dir.z \Dec:=4);
        
        target.trans := shared_movement_left.hand_over_pose.position - offset_dir*gripper_offset;
        ConfJ \Off;
        
        ! move to right pose
        MovementProc target,step_size,max_magnitude,movement_speed;
        shared_movement_left.wait_flag := FALSE;
        
        ! wait for right arm
        WaitUntil shared_movement_left.wait_flag = TRUE;
        
        ! open gripper and move back
        g_GripOut;
        WaitTime(sequence_delay);
        
        target.trans := target.trans - offset_dir*(offset_lenght+gripper_offset);
        moveL target,movement_speed,z50,tGripper;
        
        
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
    
ENDMODULE

   