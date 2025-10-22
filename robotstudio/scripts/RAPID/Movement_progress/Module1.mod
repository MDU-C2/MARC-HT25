MODULE Module1
    !***********************************************************
    !
    ! Module:  Module1
    !
    ! Description:
    !   Main module for arm movement which works together with the communication module.
    !
    ! Author: fjn20007
    !
    ! Version: 1.0
    !
    !***********************************************************
!-177.987

    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
!    CONST robtarget home_target := [[693.916,137.177,38.7584],[0.467517,-0.537106,0.454215,-0.535381],[-2,0,1,4],[83.8102,9E+09,9E+09,9E+09,9E+09,9E+09]];

    PROC main()
        CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]];
        VAR robtarget testing_target;
        VAR jointtarget test_joints;
        VAR iodev logfile;
!        CONST robtarget home_target:=[[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
        CONST bool testing := TRUE;
        CONST bool testing_savingpos := FALSE;
        CONST speeddata movement_speed := v200;
        CONST num max_magnitude := 300;
        CONST num step_size := 100;
        CONST num orient_frac := 0.3;
!        shared_vars.target := CrobT(\Tool:=tGripper);
        TPErase;
        ConfJ\Off;
!        RemoveFile "Home:/Positions.txt";
        IF testing_savingpos THEN
            Close logfile;
            Open "HOME:" \File:= "Positions.txt", logfile \Write;
            WHILE TRUE DO
                testing_target := CrobT(\Tool:=tGripper);
                Write logfile, "",\Pos:= testing_target.trans;
            ENDWHILE
        ENDIF
!        WaitTime 1;
        IF testing THEN
!            Open "Home:" \File:="Positions.txt", logfile \Write;
            testing_target := cRobT(\Tool:=tGripper);

            testing_target.rot := [0.00274,0.75169,0.65950,-0.00414];
            testing_target.trans := [200,300,0];
            
!            moveToHomeTarget;
            WHILE TRUE DO
                testing_target.trans := [400,100,50];
                MovementProc testing_target, step_size, orient_frac, movement_speed;
            ENDWHILE
!            MovementProc Offs(testing_target,0,0,200), step_size, orient_frac, joint_threshold, movement_speed;
!            g_GripOut;
!            MovementProc Offs(testing_target,0,0,0), step_size, orient_frac, joint_threshold, movement_speed;
!            g_GripIn;
!            MovementProc Offs(testing_target,0,0,200), step_size, orient_frac, joint_threshold, movement_speed;
!            MoveJ testing_target,movement_speed,fine,tool0;
!            testing_target.trans := [500,0,-55.75];
            
!            MovementProc Offs(testing_target,0,0,200), step_size, orient_frac, joint_threshold, movement_speed;
!            g_GripIn;
!!            MovementProc Offs(testing_target,0,0,0), step_size, orient_frac, joint_threshold, movement_speed;
!            g_GripOut;
!            MovementProc Offs(testing_target,0,0,200), step_size, orient_frac, joint_threshold, movement_speed;
            
!            ConfJ\On;
!            ConfL\On;
!            MoveJ home_target,movement_speed,fine,tGripper;
!            ConfJ\Off;
!            ConfL\Off;

            STOP;
        endif

        WHILE TRUE DO
            WaitUntil shared_vars.wait_flag = TRUE;
            TEST shared_vars.flag
            CASE 1: !Move to pos / orientation stored in shared_vars.target
                ConfJ\On;
                MoveJ home_target,movement_speed,fine,tGripper;
                ConfJ\Off;
                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, movement_speed;
                g_GripOut;
                MoveJ Offs(shared_vars.target,0,0,0),movement_speed,fine,tGripper;
                g_GripIn;
                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, v100;
                
                ConfJ\On;
                MoveJ Offs(cup_target,0,0,200),movement_speed,fine,tGripper;
                MoveJ Offs(cup_target,0,0,0),movement_speed,fine,tGripper;
                g_GripOut;
                MoveJ Offs(cup_target,0,0,200),movement_speed,fine,tGripper;
                
                MoveJ home_target,movement_speed,fine,tGripper;

                
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
            ENDTEST
            shared_vars.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE