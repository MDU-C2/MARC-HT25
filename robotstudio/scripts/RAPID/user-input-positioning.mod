MODULE MainModule

    VAR robtarget requested_target:=[[0,0,0],[5.32125E-06,0.712376,-0.701798,-1.54796E-05],[0,-1,-2,4],[-160.18,9E+09,9E+09,9E+09,9E+09,9E+09]];
    VAR robtarget currentPos;
    VAR num choice;

    PROC main()
        !MoveToHome;
        !HandInit_Verify;


        !        moveTest;
        !        TPWrite "test Position1:"\Pos:=testtargets{1}.trans;
        !        TPWrite "test Position2:"\Pos:=testtargets{2}.trans;
!
        WHILE TRUE DO
            TPErase;
            TPWrite "Current pos";
            printCRobT;
            TPReadNum choice,"1: choose pos. 2: move to home 3: exit";

            TEST choice
            CASE 1:
                TPgetTarget;

                MoveY requested_target,vMedium,fine,tgripper;
            CASE 2:
                MoveToHome;
            CASE 3:
                Stop;
            ENDTEST
            

        ENDWHILE



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
        testtargets{2}:=currentPos;
        !        TPWrite "Position:"\Pos:=currentPos.trans;
        !        TPWrite "Orientation:"\Orient:=currentPos.rot;


    ENDPROC

    PROC printCRobT()

        currentPos:=CRobT(\Tool:=tGripper);
        TPWrite "Position:"\Pos:=currentPos.trans;
        TPWrite "Orientation:"\Orient:=currentPos.rot;
    ENDPROC
ENDMODULE
