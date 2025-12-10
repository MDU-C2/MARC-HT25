MODULE RightArmMain   
!    ***********************************************************
    
!     Module:  RightArmMain
    
!     Description:  Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007 
    
!    ***********************************************************


    ! CONST VALUES
        !home positions
    CONST robtarget calib_home_target:=[[-220.65,-330.94,687.12],[0.149229,0.120937,-0.0351868,-0.980748],[1,2,0,5],[110.617,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget home_target_v3:=[[363.04,-198.14,250.65],[0.0417504,0.325274,0.761486,0.559099],[0,0,1,4],[177.611,9E+09,9E+09,9E+09,9E+09,9E+09]]; ![0,2,2,5]
    CONST robtarget home_target := home_target_v3;
    
        ! used for mug manipulation
    CONST pos sholder_pos_close := [110,-200,460];
    CONST pos sholder_pos_far := [200,-400,460];
    CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]]; ! start value
        
    CONST speeddata movement_speed := v200; ! Movement speed for robot movement
    CONST num max_magnitude := 300;         ! Threshold for when to discretize robtarget (used in MovementProc)
    CONST num step_size := 200;             ! Step size when discretizing robtargets (used in MovementProc)
        
        ! used in basic movement
    CONST num x_offset := 0;            
    CONST num y_offset := -10;                
    CONST num z_offset := -10;           
        ! used when fetching a mug
    CONST num gripper_offset := 0;    
    CONST num pick_offset := 100;
!CONST robtarget calib_robtargets10:=[[308.66,-338.67,251.88],[0.47389,-0.816927,0.0698697,-0.321211],[0,0,1,4],[179.081,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    
    PROC main()

        VAR mug_vector buffer;
        g_calibrate; ! Calibrate gripper (Requires YuMi lib)
        TPErase;     ! Erase all text on FlexPendant
        moveToHomeTarget;
        ConfJ\On;   ! Turn on configuration mode
        ConfL\On;
        WHILE TRUE DO
            !Flag is set by communication task
            WaitUntil shared_movement_right.wait_flag = TRUE;
            TEST shared_movement_right.flag 
            CASE flag_ERROR:
                TPWrite("ERROR OCCURED");
                StopMove;
                STOP;
            CASE flag_move: !Move to pos / orientation stored in shared_vars.target
                MovementProc Offs(shared_movement_right.target,x_offset,y_offset,z_offset), step_size,max_magnitude, movement_speed;


            CASE flag_move_home: !Move to home position (revelotion counter calibration position) (Requires YuMi lib)
                MoveToHome; 
                
            CASE flag_gripper_grip: !Close gripper to minimum (Requires YuMi lib)
                g_gripIn;   
                
            CASE flag_gripper_release: !Open gripper to maximum (Requires YuMi lib)
                g_gripOut; 
                
            CASE flag_move_home_target: !Move to home_target
                moveToHomeTarget;
                
            CASE flag_move_gripsequence:
            
                MovementProc Offs(shared_movement_right.target,x_offset,y_offset,pick_offset), step_size, max_magnitude, movement_speed;
                g_GripOut; 
                MovementProc Offs(shared_movement_right.target,x_offset,y_offset,z_offset), step_size, max_magnitude, movement_speed;
                
            CASE flag_move_leavesequence: !Leave mug
                ConfJ\On;
                g_GripIn; 
                MoveJ Offs(cup_target,x_offset,y_offset,pick_offset),movement_speed,fine,tGripper;
                MoveJ Offs(cup_target,x_offset,y_offset,z_offset),movement_speed,fine,tGripper;
                g_GripOut;
                MoveJ Offs(cup_target,x_offset,y_offset,pick_offset),movement_speed,fine,tGripper;
                ConfJ\Off;
                
            CASE flag_move_EGM: !EGM movement
                ConfJ\On;
                ConfL\On;
                MoveJ shared_movement_right.target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
                EGMfollowCup;
                
            CASE flag_move_calibration:
                ConfJ\On;
                ConfL\On;
                MoveJ calib_home_target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
                
            CASE flag_pick_up_mug:    
                FetchMug shared_movement_right.mug.position,pick_offset,shared_movement_right.mug.normal;  
                
            CASE flag_leave_mug:
                 LeaveMug shared_movement_right.mug.position,[0,0,-1],pick_offset;
            
            CASE flag_hand_over: 
                ! hand over sequence
                
            ENDTEST
            shared_movement_right.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE

