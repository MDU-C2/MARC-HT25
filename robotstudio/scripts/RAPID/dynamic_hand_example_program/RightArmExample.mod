MODULE RightArmExample

    
    CONST speeddata movespeed:= v200;
    CONST robtarget home_target:=[[-9.58,-182.61,198.63],[0.0660107,-0.842421,-0.111215,-0.523069],[0,0,0,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget leave_mup_target:=[[303.05,-355.37,96.37],[0.116431,-0.991183,-0.0563017,0.028824],[1,-1,2,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST pos sholder_pos := [110,-100,460];
    
    PROC main()
        
        VAR robtarget buffer;
        TPErase;
        moveJ home_target,movespeed,z50,tGripper;
        WHILE TRUE DO
        WaitUntil multi_move.right_in_process = TRUE;
        TPWrite "[R]:" \Num:=multi_move.right_flag;
            TEST multi_move.right_flag 
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
                    LeaveMug multi_move.mug.position,[0,0,-1];
                CASE 4:
                    moveJ home_target,movespeed,z50,tGripper;
                
            ENDTEST
            WaitTime(1);
            multi_move.right_flag := 0;
            multi_move.right_in_process := FALSE;    
        ENDWHILE
    ENDPROC
    
ENDMODULE