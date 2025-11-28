MODULE Module1   
!    ***********************************************************
    
!     Module:  Module1
    
!     Description:  Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007
    
!    ***********************************************************

    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];

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
        g_calibrate; ! Calibrate gripper
        TPErase;     ! Erase all text on FlexPendant
        ConfJ\Off;   ! Turn off configuration mode

        WHILE TRUE DO
            WaitUntil shared_movement_vars.wait_flag = TRUE;
            TEST shared_movement_vars.flag
            CASE 1: !Move to pos / orientation stored in shared_vars.target

!                moveToHomeTarget;
!                MovementProc Offs(shared_vars.target,x_offset,y_offset,pick_z_offset), step_size,max_magnitude, movement_speed;
!                g_GripOut;
!                MovementProc Offs(shared_vars.target,x_offset,y_offset,z_offset), step_size, max_magnitude, movement_speed;
!                g_GripIn;
!                MovementProc Offs(shared_vars.target,x_offset,y_offset,pick_z_offset), step_size, max_magnitude, v100;
            
!                ConfJ\On;
!                MoveJ Offs(cup_target,x_offset,y_offset,pick_z_offset),movement_speed,fine,tGripper;
!                MoveJ Offs(cup_target,x_offset,y_offset,z_offset),movement_speed,fine,tGripper;
!                g_GripOut;
!                MoveJ Offs(cup_target,x_offset,y_offset,pick_z_offset),movement_speed,fine,tGripper;
!                ConfJ\Off;

            CASE 2: !Move to home position (revelotion counter calibration position)
                MoveToHome;
            CASE 3: !Close gripper to minimum
                g_gripIn;
            CASE 4: !Open gripper to maximum
                g_gripOut;
            CASE 5: !Move to home_target
                ConfJ\On;
                ConfL\On;
                MoveJ home_target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
            CASE 6: !test movement
                MovementProc Offs(shared_movement_vars.target,x_offset,y_offset,pick_z_offset), step_size, max_magnitude, movement_speed;
                g_GripOut;
                MovementProc Offs(shared_movement_vars.target,x_offset,y_offset,z_offset), step_size, max_magnitude, movement_speed;
            CASE 7: !Leave cup
                ConfJ\On;
                g_GripIn;
                MoveJ Offs(cup_target,x_offset,y_offset,pick_z_offset),movement_speed,fine,tGripper;
                MoveJ Offs(cup_target,x_offset,y_offset,z_offset),movement_speed,fine,tGripper;
                g_GripOut;
                MoveJ Offs(cup_target,x_offset,y_offset,pick_z_offset),movement_speed,fine,tGripper;
                ConfJ\Off;
            CASE 8: !EGM movement
                ConfJ\On;
                ConfL\On;
                MoveY shared_movement_vars.target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
                EGMfollowCup;
            CASE 9:
                ConfJ\On;
                ConfL\On;
                MoveY shared_movement_vars.target,movement_speed,fine,tGripper;
                ConfJ\Off;
                ConfL\Off;
            ENDTEST
            shared_movement_vars.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE
