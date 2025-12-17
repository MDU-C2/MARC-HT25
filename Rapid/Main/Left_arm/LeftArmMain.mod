MODULE LeftArmMain   
!    ***********************************************************
    
!     Module:  LeftArmMain
    
!     Description:  Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007 
    
!    ***********************************************************


    ! CONST VALUES
        !home positions
    CONST robtarget home_target:=[[357.9,284.46,274.39],[0.195938,0.546826,-0.570092,0.581021],[0,0,0,4],[175.044,9E+09,9E+09,9E+09,9E+09,9E+09]]; 
    CONST robtarget calib_target_outofway:=[[-155.85,250.06,761.03],[0.903777,0.225568,-0.131867,-0.338994],[-1,1,-1,4],[-147.134,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget calib_home_target := [[442.004,-92.0926,300.604],[0.0189937,-0.0236138,0.999427,-0.0150419],[-1,1,-1,4],[-152.666,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
        ! used for mug manipulation      
    CONST speeddata movement_speed := v300; ! Movement speed for robot movement
    CONST speeddata calib_movement_speed := v500; ! Movement speed for robot movement
    CONST num max_magnitude := 300;         ! Threshold for when to discretize robtarget (used in MovementProc)
    CONST num step_size := 50;             ! Step size when discretizing robtargets (used in MovementProc)
    CONST num sequence_delay := .2; ! sec
        
    
        ! used in basic movement
    CONST num x_offset := 0;                
    CONST num y_offset := -30;                
    CONST num z_offset := -30;     
    
    CONST num mug_offset_layingdown := -30;
    CONST num mug_offset_standingup := 5;
    
        ! used when fetching a mug
    CONST num gripper_offset := 20;    
    CONST num pick_offset := 100;
    CONST num offset_z_when_fetching := 100;
    
    
    PROC main()

        VAR mug_vector buffer;
        g_calibrate; ! Calibrate gripper (Requires YuMi lib)
        TPErase;     ! Erase all text on FlexPendant
        moveToHomeTarget;
        ConfJ\On;   ! Turn on configuration mode
        ConfL\On;
        WHILE TRUE DO
            !Flag is set by communication task
            
            WaitUntil shared_movement_left.wait_flag = TRUE;
            TEST shared_movement_left.flag 
            
            CASE flag_ERROR:
                TPWrite("ERROR OCCURED");
                StopMove;
                STOP;
            CASE flag_move: !Move to pos / orientation stored in shared_vars.target
                MovementProc Offs(shared_movement_left.target,x_offset,y_offset,z_offset), step_size,max_magnitude, movement_speed;

            CASE flag_move_home: !Move to home position (revelotion counter calibration position) (Requires YuMi lib)
                MoveToHome; 
 
            CASE flag_move_home_target: !Move to home_target
                moveToHomeTarget;
          
            CASE flag_move_calibration:
                ConfJ\On;
                ConfL\On;
                
                MoveJ calib_home_target,calib_movement_speed,fine,tGripper;
                MoveJ shared_movement_left.target,calib_movement_speed,fine,tGripper;
                
                ConfJ\Off;
                ConfL\Off;
                
            CASE flag_move_calibration_home:
                ConfJ\On;
                MoveJ calib_home_target,v500,fine,tGripper;
                ConfJ\Off;
                
             CASE flag_move_calibration_outofway:
                ConfJ\On;
                ConfL\On;
                MoveJ calib_target_outofway,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
  
            CASE flag_pick_up_mug:
                FetchMug shared_movement_left.mug.position,pick_offset,shared_movement_left.mug.normal;  
                
            CASE flag_leave_mug:
                ! leave mug sequence
                 LeaveMug shared_movement_left.mug.position,[0,0,-1],pick_offset;
            
            CASE flag_hand_over: 
                ! hand over sequence
                handOverSequence pick_offset;
                
            ENDTEST
            shared_movement_left.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE

