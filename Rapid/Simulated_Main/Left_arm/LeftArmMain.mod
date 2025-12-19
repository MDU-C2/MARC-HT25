MODULE LeftArmMain   
!    ***********************************************************
    
!     Module:  LeftArmMain
    
!     Description:  Main module for arm movement which works together with the communication module.
    
    
!    ***********************************************************


    ! CONST VALUES
        !home positions
    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget calib_target_outofway:=[[-155.85,250.06,761.03],[0.903777,0.225568,-0.131867,-0.338994],[-1,1,-1,4],[-147.134,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget calib_home_target := [[442.004,-92.0926,300.604],[0.0189937,-0.0236138,0.999427,-0.0150419],[-1,1,-1,4],[-152.666,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget home_target_v2:=[[247.91,314.47,202.37],[0.680648,0.280046,0.674068,0.0626469],[0,-2,0,5],[107.401,9E+09,9E+09,9E+09,9E+09,9E+09]];   
    CONST robtarget home_target_v3:=[[357.9,284.46,274.39],[0.195938,0.546826,-0.570092,0.581021],[0,0,0,4],[175.044,9E+09,9E+09,9E+09,9E+09,9E+09]]; 
    CONST robtarget EGM_starting_point := [[442.004,-92.0926,171.604],[0.0189937,-0.0236138,0.999427,-0.0150419],[-1,1,-1,4],[-152.666,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
        ! used for mug manipulation
    CONST pos sholder_pos_close := [110,200,460];
    CONST pos sholder_pos_far := [1000,800,460];
    CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]]; ! start value
        
    CONST speeddata movement_speed := v500; ! Movement speed for robot movement
    CONST speeddata pick_speed := v200;
    CONST num max_magnitude := 300;         ! Threshold for when to discretize robtarget (used in MovementProc)
    CONST num step_size := 50;             ! Step size when discretizing robtargets (used in MovementProc)
        
    
        ! used in basic movement
    CONST num x_offset := 10;                
    CONST num y_offset := -10;                
    CONST num z_offset := 0;        
        ! used when fetching a mug
    CONST num gripper_offset := 0;    
    CONST num pick_offset := 100;
    CONST num offset_z_when_fetching := 100;
    
    
    PROC main()

        VAR mug_vector buffer;
        g_calibrate; ! Calibrate gripper (Requires YuMi lib)
        TPErase;     ! Erase all text on FlexPendant
        moveToHomeTarget;

        WHILE TRUE DO
            !Flag is set by communication task
            WaitUntil shared_movement_left.wait_flag = TRUE;
            ConfJ\On;   ! Turn on configuration mode
            ConfL\On;
            
            TEST shared_movement_left.flag 
            CASE flag_ERROR:
                TPWrite("ERROR OCCURED");
                StopMove;
                STOP;
            CASE flag_move: !Move to pos / orientation stored in shared_vars.target

                MovementProc Offs(shared_movement_left.target,x_offset,y_offset,z_offset), step_size,max_magnitude, movement_speed;

            CASE flag_move_home: !Move to home position (revelotion counter calibration position) (Requires YuMi lib)
            
                MoveToHome; 
                
            CASE flag_gripper_grip: !Close gripper to minimum (Requires YuMi lib)
            
                g_gripIn;   
                
            CASE flag_gripper_release: !Open gripper to maximum (Requires YuMi lib)
            
                g_gripOut; 
                
            CASE flag_move_home_target: !Move to home_target
            
                moveToHomeTarget;
                
            CASE flag_move_EGM: !EGM movement (Only works in simulation without EGM installed on the robot)
            
                MoveJ EGM_starting_point,movement_speed,fine,tGripper;
                EGMfollowCup;
                
            CASE flag_move_calibration:
            
                MoveJ calib_home_target,movement_speed,fine,tGripper;
                MoveJ shared_movement_left.target,movement_speed,fine,tGripper;
                
            CASE flag_move_calibration_home:
            
                MoveJ calib_home_target,movement_speed,fine,tGripper;

             CASE flag_move_calibration_outofway: ! Position so as not to disturn calibration process

                MoveJ calib_target_outofway,movement_speed,fine,tGripper;
  
            CASE flag_pick_up_mug: ! pick up mug sequence

                FetchMug shared_movement_left.mug.position,pick_offset,shared_movement_left.mug.normal;  
                
            CASE flag_leave_mug: ! leave mug sequence
                
                 LeaveMug shared_movement_left.mug.position,[0,0,-1],pick_offset;
            
            CASE flag_hand_over: ! hand over sequence
                
                handOverSequence;
                
            ENDTEST
            shared_movement_left.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE

