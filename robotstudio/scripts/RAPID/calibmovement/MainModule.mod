MODULE MainModule

    !    VAR robtarget requested_target:=[[0,0,0],[5.32125E-06,0.712376,-0.701798,-1.54796E-05],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST num q1:=0.707;
    CONST num q2:=0;
    CONST num q3:=0.707;
    CONST num q4:=0;
    VAR robtarget requested_target:=[[0,0,0],[q1,q2,q3,q4],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];

    VAR robtarget currentPos;
    VAR num choice;
    VAR bool user_main_continue := TRUE;
    
    PERS robtarget tempTargets{calib_array_size};
    PERS jointtarget tempJoints{calib_array_size};

    PROC main()

!        MoveToHome;
        !HandInit_Verify;

        
!        user_main_continue := FALSE;
        WHILE user_main_continue DO
            TPErase;
            TPWrite "Current pos";
            printCRobT;
            TPWrite "1: Choose pos.";
            TPWrite "2: Move to home.";
            TPWrite "3: OAK calib pos.";
            TPWrite "0: Exit.";
            TPReadNum choice,"";

            TEST choice
            CASE 1:
                TPgetTarget;
                MoveJ requested_target,vMedium,fine,tgripper;
            CASE 2:
                MoveToHome;
            CASE 3:
                calibMove;
            CASE 0:
                user_main_continue := FALSE;
            ENDTEST
            
        ENDWHILE
        TPWrite "Program ended!";

    ENDPROC


ENDMODULE
