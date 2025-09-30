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
    
!        TPWrite "" \Orient:= calib_robtargets{1}.rot;
!        MoveToHome;
        !HandInit_Verify;
!        TPErase;
        
!    single_client_communication;
!        tempTargets := calib_robtargets;
!        tempJoints := calib_jointtargets;
        
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

    !Take user position input from Flex Pendant.
    PROC TPgetTarget()

        TPReadNum requested_target.trans.x,"enter x-value (160 - 500):";
        TPReadNum requested_target.trans.y,"enter y-value (-200 - 300):";
        TPReadNum requested_target.trans.z,"enter z-value (0 - 700):";


    ENDPROC

    PROC moveTest()

        TPWrite "Moving...";

        MoveY YLExample_pMoveY,vMedium,fine,tGripper;


        TPWrite "Position:"\Pos:=currentPos.trans;
        TPWrite "Orientation:"\Orient:=currentPos.rot;


        !WaitForTap;
        WaitTime 1;

        !        MoveL target2, vSlow, fine,tgripper;
        !        !MoveY target2,vSlow,fine,tGripper;

        !        !MoveY Offs(YLExample_pMoveY,50,-100,0),vMedium,fine,tGripper;

        WaitTime 1;

        currentPos:=CRobT(\Tool:=tGripper);
        calib_robtargets{2}:=currentPos;
        !        TPWrite "Position:"\Pos:=currentPos.trans;
        !        TPWrite "Orientation:"\Orient:=currentPos.rot;


    ENDPROC

    !Print current tool position & orientation to the FlexPendant
    PROC printCRobT()

        currentPos:=CRobT(\Tool:=tGripper);
        TPWrite "Position:"\Pos:=currentPos.trans;
        TPWrite "Orientation:"\Orient:=currentPos.rot;
    ENDPROC


ENDMODULE
