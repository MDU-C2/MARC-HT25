MODULE Module1   
!    ***********************************************************
    
!     Module:  Module1
    
!     Description:  Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007
    
!    ***********************************************************

    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget calib_home_target := [[442.004,-92.0926,171.604],[0.0189937,-0.0236138,0.999427,-0.0150419],[-1,1,-1,4],[-152.666,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    PROC main()
        CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]];
        CONST speeddata movement_speed := v200; ! Movement speed for robot movement
        CONST num max_magnitude := 300;         ! Threshold for when to discretize robtarget (used in MovementProc)
        CONST num step_size := 200;             ! Step size when discretizing robtargets (used in MovementProc)
        CONST num x_offset := 0;                
        CONST num y_offset := 0;                
        CONST num z_offset := 0;                
        CONST num pick_z_offset := 200;         

!        shared_vars.target := CrobT(\Tool:=tGripper);
!        g_calibrate; ! Calibrate gripper (Requires YuMi lib)
        TPErase;     ! Erase all text on FlexPendant
        ConfJ\On;   ! Turn on configuration mode
        ConfL\On;
        WHILE TRUE DO
            !Flag is set by communication task
            WaitUntil shared_movement_vars.wait_flag = TRUE;
            TEST shared_movement_vars.flag 
            CASE flag_move: !Move to pos / orientation stored in shared_vars.target

                MoveJ calib_home_target,movement_speed,fine,tGripper;
!                moveToHomeTarget;
                MovementProc Offs(shared_movement_vars.target,x_offset,y_offset,pick_z_offset), step_size,max_magnitude, movement_speed;
!                g_GripOut;
                MovementProc Offs(shared_movement_vars.target,x_offset,y_offset,z_offset), step_size, max_magnitude, movement_speed;
!                g_GripIn;

            CASE flag_move_home: !Move to home position (revelotion counter calibration position) (Requires YuMi lib)
!                MoveToHome; (Does not work in sim)
            CASE flag_gripper_grip: !Close gripper to minimum (Requires YuMi lib)
!                g_gripIn;   (Does not work in sim)
            CASE flag_gripper_release: !Open gripper to maximum (Requires YuMi lib)
!                g_gripOut;  (Does not work in sim)
            CASE flag_move_home_target: !Move to home_target
                ConfJ\On;
                ConfL\On;
                MoveJ home_target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
            CASE flag_move_gripsequence:
                MovementProc Offs(shared_movement_vars.target,x_offset,y_offset,pick_z_offset), step_size, max_magnitude, movement_speed;
!                g_GripOut; (Does not work in sim)
                MovementProc Offs(shared_movement_vars.target,x_offset,y_offset,z_offset), step_size, max_magnitude, movement_speed;
            CASE flag_move_leavesequence: !Leave cup
                ConfJ\On;
!                g_GripIn; (Does not work in sim)
                MoveJ Offs(cup_target,x_offset,y_offset,pick_z_offset),movement_speed,fine,tGripper;
                MoveJ Offs(cup_target,x_offset,y_offset,z_offset),movement_speed,fine,tGripper;
!                g_GripOut; (Does not work in sim)
                MoveJ Offs(cup_target,x_offset,y_offset,pick_z_offset),movement_speed,fine,tGripper;
                ConfJ\Off;
            CASE flag_move_EGM: !EGM movement
                ConfJ\On;
                ConfL\On;
                MoveJ shared_movement_vars.target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
                EGMfollowCup;
            CASE flag_move_calibration:
                ConfJ\On;
                ConfL\On;
                MoveJ shared_movement_vars.target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
            ENDTEST
            shared_movement_vars.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE
