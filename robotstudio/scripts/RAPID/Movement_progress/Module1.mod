MODULE Module1
    
        
!!    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST speeddata movespeed:= v100;
!!    CONST robtarget fetch_cup_target:=[[307.17,362.86,24.76],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
!    CONST robtarget home:=[[509,103,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];![[-9.58,182.61,198.63],[0.0660107,0.842421,-0.111215,0.523069],[0,0,0,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
!    CONST robtarget fetch_cup_target:=[[368.38,340.33,-53.42],[0.0147446,-0.577182,0.815782,-0.0338125],[-1,1,2,5],[-118.581,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
!    PROC main()
            
!!        WaitTime(1); ! to let left arm init everything!
!!        TPWrite("debugging");
!        moveJ home,movespeed,z50,tool0;
!        InitSharedArea 170,4,[200,0,-50]; ! cup size about 170 mm in diameter
        
!        WHILE TRUE DO
!            IF AddCup(fetch_cup_target,FALSE) THEN
!                TPWrite "left arm added cup to buffer, amount in buffer:" , \Num:=shared_area.current_index;
!            ELSE
!                WaitTime(1); ! can not add cup right now. To many in buffer
!            ENDIF
!        ENDWHILE
        
!    ENDPROC
        
    
!    ***********************************************************
    
!     Module:  Module1
    
!     Description:
!       Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007
    
!     Version: 1.0
    
!    ***********************************************************
!-177.987

    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
!    CONST robtarget home_target := [[693.916,137.177,38.7584],[0.467517,-0.537106,0.454215,-0.535381],[-2,0,1,4],[83.8102,9E+09,9E+09,9E+09,9E+09,9E+09]];

    PROC main()
        CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]];
        VAR robtarget testing_target;
        VAR jointtarget test_joints;
        VAR iodev logfile;
!        CONST robtarget home_target:=[[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
        CONST bool testing := FALSE;
        CONST bool testing_savingpos := FALSE;
        CONST speeddata movement_speed := v200;
        CONST num max_magnitude := 300;
        CONST num step_size := 200;
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

!            Open "Home:" \File:="Positions.txt", logfile \Write;M

            testing_target := cRobT(\Tool:=tGripper);

            testing_target.rot := [0.00274,0.75169,0.65950,-0.00414];
            testing_target.trans := [485.16,128.19,2.85];
            
!            moveToHomeTarget;
            WHILE TRUE DO
                moveToHomeTarget;
                MovementProc Offs(testing_target,0,0,200), step_size, orient_frac, movement_speed;
                g_GripOut;
                MovementProc Offs(testing_target,0,0,0), step_size, orient_frac, movement_speed;
!                MoveJ Offs(shared_vars.target,0,0,0),movement_speed,fine,tGripper;
                g_GripIn;
                MovementProc Offs(testing_target,0,0,200), step_size, orient_frac, v100;
                
!                moveToHomeTarget;
!                testing_target.trans := [560,310,-50];
!                MovementProc testing_target, step_size, orient_frac, movement_speed;
!                MoveY \J,testing_target,movement_speed,fine,tGripper;
!                g_GripIn;
!                moveToHomeTarget;
!                MoveY \J,testing_target,movement_speed,fine,tGripper;
!                g_GripOut;
!                MoveToHomeTarget;
!                MoveJ testing_target,movement_speed,fine,tGripper;
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
            ENDTEST
            shared_vars.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE
