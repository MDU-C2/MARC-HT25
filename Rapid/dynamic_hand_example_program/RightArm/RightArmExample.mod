MODULE RightArmExample

    
    CONST speeddata movespeed:= v500;
!    CONST robtarget home_target:=[[-9.58,-182.61,198.63],[0.0660107,-0.842421,-0.111215,-0.523069],[0,0,0,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget leave_mup_target:=[[303.05,-355.37,96.37],[0.116431,-0.991183,-0.0563017,0.028824],[1,-1,2,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget home_target:=[[360.85,-296.53,140.43],[0.430341,0.438072,0.540926,0.574717],[1,0,-1,4],[-122.839,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST pos sholder_pos_close := [110,-100,460];
    CONST pos sholder_pos_far := [500,-400,460];
    CONST num gripper_offset := 50;
    
   PROC main()
        VAR robtarget buffer;
        TPErase;
!        g_Calibrate;
        WHILE TRUE DO 
        moveJ home_target,movespeed,z50,tGripper;
!        MovementProc home_target,50,300,movespeed;
        WaitUntil multi_move.right_in_process = TRUE;
        TPWrite "[L]:" \Num:=multi_move.right_flag;
            TEST multi_move.right_flag
                CASE -1:
!                    Stop; 
                    RETURN;
                CASE 1:
                    ! move to same pos
                    HandOverSequence gripper_offset; 
                    LeaveMug multi_move.mug.position,[0,0,-1],100;
                ! fetch
                CASE 2:
                    FetchMug multi_move.mug.position,50,multi_move.mug.normal;  
                ! leave
                CASE 3:
                    LeaveMug multi_move.mug.position,[0,0,-1],50;
                CASE 4:
                    moveJ home_target,movespeed,z50,tGripper;
            ENDTEST
            WaitTime(1);
            multi_move.right_flag := 0;
            multi_move.right_in_process := FALSE; 
        ENDWHILE
    ENDPROC
    
    
ENDMODULE