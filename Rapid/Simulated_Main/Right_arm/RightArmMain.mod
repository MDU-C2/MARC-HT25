MODULE RightArmMain   
!    ***********************************************************
    
!     Module:  RightArmMain
    
!     Description:  Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007 
    
!    ***********************************************************


    ! CONST VALUES
        !home positions
    CONST robtarget calib_target_outofway :=[[-220.65,-330.94,687.12],[0.149229,0.120937,-0.0351868,-0.980748],[1,2,0,5],[110.617,9E+09,9E+09,9E+09,9E+09,9E+09]];
!    CONST robtarget calib_home_target:=[[468.01,-81.56,159.21],[0.0309367,0.999372,0.00557454,-0.0163667],[0,-1,-1,4],[117.55,9E+09,9E+09,9E+09,9E+09,9E+09]];
!    CONST robtarget calib_home_target:=[[433.93,-203.39,154.81],[0.0215696,-0.0129362,0.999637,-0.00968712],[1,3,1,4],[171.309,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget calib_home_target:=[[447.68,-5.26,181.84],[0.0086866,-0.994821,0.101181,0.00433661],[1,1,1,5],[139.829,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget home_target_v3:=[[363.04,-198.14,250.65],[0.0417504,0.325274,0.761486,0.559099],[0,0,1,4],[177.611,9E+09,9E+09,9E+09,9E+09,9E+09]]; ![0,2,2,5]
    CONST robtarget home_target := home_target_v3;
    
        ! used for mug manipulation
    CONST pos sholder_pos_close := [110,-200,460];
    CONST pos sholder_pos_far := [200,-400,460];
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
            WaitUntil shared_movement_right.wait_flag = TRUE;
            ConfJ\On;   ! Turn on configuration mode
            ConfL\On;
            
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
                
            CASE flag_move_EGM: !EGM movement

                MoveJ shared_movement_right.target,movement_speed,fine,tGripper;
                EGMfollowCup;
                
            CASE flag_move_calibration:

                MoveJ calib_home_target,movement_speed,fine,tGripper;
                
                IF shared_movement_right.target.trans.z < 60 THEN
                    shared_movement_right.target.trans.z := 60;
                ENDIF
                
                MoveJ shared_movement_right.target,movement_speed,fine,tGripper;
                              
            CASE flag_move_calibration_home:

                MoveJ calib_home_target,movement_speed,fine,tGripper;
                
            CASE flag_move_calibration_outofway: ! Position so as not to disturn calibration process

                MoveJ calib_target_outofway,movement_speed,fine,tGripper;

            CASE flag_pick_up_mug: ! pick up mug sequence
            
                FetchMug shared_movement_right.mug.position,pick_offset,shared_movement_right.mug.normal;  
                
            CASE flag_leave_mug: ! leave mug sequence

                LeaveMugV2;
                
            CASE flag_hand_over: ! hand over sequence
                
                handOverSequence;
                
            ENDTEST
            
            current_right_target := CRobT(\Tool:=tGripper); ! Update right arm position for communication purposses
            shared_movement_right.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE

