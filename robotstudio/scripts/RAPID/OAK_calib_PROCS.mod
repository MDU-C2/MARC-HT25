MODULE OAK_calib

    !   Used for storing robtargets and joint values specifically for OAK camera calibration
    PROC calibStore()
        VAR num arr_nr;
        VAR num user_input;
        TPErase;
        TPWrite "Setting calibration positions";
        TPReadNum arr_nr,"Enter position # (correspinging to picture #) or 0: Exit.";
        IF user_input = 0 THEN
            
        ELSE
            arr_nr := user_input;
            testtargets{arr_nr}:=CRobT(\Tool:=tGripper);
            testjointtargets{arr_nr}:= CJointT();
            TPWrite "Position stored!";
        ENDIF


    ENDPROC
    
    !   Used to move to saved positions related to OAK camera calibration
    PROC calibMove()
        VAR num arr_pos;
        VAR num user_input;
        VAR bool user_continue := TRUE;
        
        TPErase;
        TPReadnum arr_pos, "Please enter pos #";
!        MoveY testtargets{arr_pos},vSlow,fine,tgripper;
        MoveAbsJ testjointtargets{arr_pos}, v100, fine, tool0;
        
        WHILE user_continue DO
            TPErase;
            TPWrite "Current postition #:"\num:=arr_pos;
            TPReadnum user_input, "1: Next pos. 2: Custom pos. 3: Save position. 0: Exit.";
            TEST user_input
            CASE 1: !next position
                arr_pos := arr_pos;
                arr_pos := arr_pos MOD calib_array_size;
                arr_pos := arr_pos + 1;
!                MoveY testtargets{arr_pos},vSlow,fine,tgripper;
                MoveAbsJ testjointtargets{arr_pos}, v100, fine, tool0;
            CASE 2: !Custom pos
                TPErase;
                TPWrite "Current position #"\num:=arr_pos;
                TPReadnum arr_pos, "Please enter pos #";
!                MoveY testtargets{arr_pos},vSlow,fine,tgripper;
                MoveAbsJ testjointtargets{arr_pos}, v100, fine, tool0;
            CASE 3: !save position

                calibStore;

            CASE 0: !Exit
                user_continue := FALSE;
            ENDTEST
        ENDWHILE
        
    ENDPROC
    
ENDMODULE