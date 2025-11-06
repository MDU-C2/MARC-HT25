MODULE Module1   
!    ***********************************************************
    
!     Module:  Module1
    
!     Description:
!       Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007
    
!     Version: 1.0
    
!    ***********************************************************

    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];

    PROC main()
        CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]];
        VAR robtarget testing_target;
        VAR iodev logfile;
        CONST bool testing := FALSE;
        CONST bool testing_savingpos := FALSE;
        CONST speeddata movement_speed := v200;
        CONST num max_magnitude := 300;
        CONST num step_size := 200;

!        shared_vars.target := CrobT(\Tool:=tGripper);
        TPErase;
        ConfJ\Off;

        WHILE TRUE DO
            WaitUntil shared_vars.wait_flag = TRUE;
            TEST shared_vars.flag
            CASE 1: !Move to pos / orientation stored in shared_vars.target

                moveToHomeTarget;
                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, movement_speed;
                g_GripOut;
                MovementProc Offs(shared_vars.target,0,0,0), step_size, orient_frac, movement_speed;
                g_GripIn;
                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, v100;
            
                ConfJ\On;
                MoveJ Offs(cup_target,0,0,200),movement_speed,fine,tGripper;
                MoveJ Offs(cup_target,0,0,30),movement_speed,fine,tGripper;
                g_GripOut;
                MoveJ Offs(cup_target,0,0,200),movement_speed,fine,tGripper;


            CASE 2: !Move to home position
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
                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, movement_speed;
                g_GripOut;
                MovementProc Offs(shared_vars.target,0,0,0), step_size, orient_frac, movement_speed;
            CASE 7: !Leave cup
                ConfJ\On;
                g_GripIn;
                MoveJ Offs(cup_target,0,0,200),movement_speed,fine,tGripper;
                MoveJ Offs(cup_target,0,0,30),movement_speed,fine,tGripper;
                g_GripOut;
                MoveJ Offs(cup_target,0,0,200),movement_speed,fine,tGripper;
                ConfJ\Off;

            ENDTEST
            shared_vars.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE
