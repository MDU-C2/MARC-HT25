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
    PROC main()
        VAR robtarget testing_target;
        VAR jointtarget test_joints;
        VAR iodev logfile;
!        CONST robtarget home_target:=[[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
        CONST bool testing := TRUE;
        CONST bool testing_savingpos := FALSE;
        CONST speeddata movement_speed := vMedium;
        CONST num max_magnitude := 300;
        CONST num step_size := 50;
        CONST num orient_frac := 0.3;
        CONST num joint_threshold := 0.7;
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
            testing_target.trans := [481.44,150.01,-80];
            ConfJ\On;
            ConfL\On;
!            MoveJ home_target,movement_speed,fine,tool0;
            ConfJ\Off;
            ConfL\Off;
!            test_joints := CalcJointT(testing_target,tGripper);
!            Write logfile, "Calculated joint values:";
!            Write logfile, "1:"\Num:=test_joints.robax.rax_1;
!            Write logfile, "2:"\Num:=test_joints.robax.rax_2;
!            Write logfile, "3:"\Num:=test_joints.extax.eax_a;
!            Write logfile, "4:"\Num:=test_joints.robax.rax_3;
!            Write logfile, "5:"\Num:=test_joints.robax.rax_4;
!            Write logfile, "6:"\Num:=test_joints.robax.rax_5;
!            Write logfile, "7:"\Num:=test_joints.robax.rax_6;
            
            MovementProc testing_target, step_size, orient_frac, joint_threshold, movement_speed;
!            MoveJ testing_target,movement_speed,fine,tool0;
            
!            test_joints := CJointT();
!            Write logfile, "Actual joint values:";
!            Write logfile, "1:"\Num:=test_joints.robax.rax_1;
!            Write logfile, "2:"\Num:=test_joints.robax.rax_2;
!            Write logfile, "3:"\Num:=test_joints.extax.eax_a;
!            Write logfile, "4:"\Num:=test_joints.robax.rax_3;
!            Write logfile, "5:"\Num:=test_joints.robax.rax_4;
!            Write logfile, "6:"\Num:=test_joints.robax.rax_5;
!            Write logfile, "7:"\Num:=test_joints.robax.rax_6;

            STOP;
        endif

        WHILE TRUE DO
            WaitUntil shared_vars.wait_flag = TRUE;
            TEST shared_vars.flag
            CASE 1: !Move to pos / orientation stored in shared_vars.target
                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, joint_threshold, movement_speed;
                testing_target := CrobT(\Tool:=tool0);
                g_GripOut;
!                MovementProc Offs(shared_vars.target,0,0,0), step_size, orient_frac, joint_threshold, v100; 
                ConfJ\On;
                MoveJ testing_target,movement_speed,fine,tool0;
                g_GripIn;
!                MovementProc Offs(shared_vars.target,0,0,200), step_size, orient_frac, joint_threshold, v100;
                MoveJ Offs(testing_target,0,0,200),movement_speed,fine,tool0;
                Confj\Off;
                
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