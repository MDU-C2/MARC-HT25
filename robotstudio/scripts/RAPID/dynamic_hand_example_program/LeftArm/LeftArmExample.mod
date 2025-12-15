MODULE LeftArmExample
    
    
!    CONST robtarget fetch_mup_target:=[[355.37,130.65,50.38],[0.0303038,0.909324,-0.409024,0.0700746],[-1,2,-2,4],[132.67,9E+09,9E+09,9E+09,9E+09,9E+09]];
!    CONST robtarget leave_mup_target:=[[355.37,-130.65,50.38],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    
    CONST speeddata movespeed:= v100;
    CONST robtarget home_target:=[[339.81,263.01,178.28],[0.465383,0.56304,0.301843,0.612614],[0,0,-1,4],[121.274,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST pos sholder_pos_close := [110,100,460];
    CONST pos sholder_pos_far := [500,400,460];
    CONST num gripper_offset := 50;
    
    PROC main()
        VAR robtarget buffer;
        TPErase;
        g_Calibrate;
        WHILE TRUE DO 
!        moveJ home_target,movespeed,z50,tGripper;
        MovementProc home_target,50,300,movespeed;
        WaitUntil multi_move.left_in_process = TRUE;
        TPWrite "[L]:" \Num:=multi_move.left_flag;
            TEST multi_move.left_flag
                CASE -1:
                    Stop; 
                CASE 1:
                    ! move to same pos
                    buffer := CRobT(\Tool:=tGripper);
                    buffer.trans := multi_move.hand_over_pose.position;
                    moveJ buffer,movespeed,z50,tGripper;
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
            multi_move.left_flag := 0;
            multi_move.left_in_process := FALSE; 
        ENDWHILE
    ENDPROC
    
!    ! LEGAZY
!       VAR orient temp;
!        VAR robtarget mug;
!        VAR pos mug_normal;
!        VAR num mug_offset;
!        VAR num val;
!        VAR pose current_hand_over_buffer;
!        VAR pose end_hand_over_buffer;
        
!        ! ==== CHANGE THESE TO CHANGE OUTCOME/SIMULATION ====
!            mug := fetch_mup_target;
!            mug_normal := [1,-1,0];
!            mug_offset := 100;
!        ! ====================================================
        
!        TPErase;
!        moveJ home_target,movespeed,z50,tGripper;
        
!        WaitTime(1);
        
!        TPErase;
!        FetchMug mug.trans,mug_offset,mug_normal; 
!        WaitTime(1);
        
        
!        moveJ home_target,movespeed,z50,tGripper;
!        TPWrite("DONE");
ENDMODULE