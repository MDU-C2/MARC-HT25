MODULE LeftArmExample
    
    CONST speeddata movespeed:= v200;

    CONST robtarget home_target:=[[339.81,263.01,178.28],[0.465383,0.56304,0.301843,0.612614],[0,0,-1,4],[121.274,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget fetch_mup_target:=[[355.37,130.65,50.38],[0.0303038,0.909324,-0.409024,0.0700746],[-1,2,-2,4],[132.67,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget leave_mup_target:=[[355.37,-130.65,50.38],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST pos sholder_pos := [110,100,460];
    
    PROC main()
        VAR orient temp;
        VAR robtarget mug;
        VAR pos mug_normal;
        VAR num mug_offset;
        VAR num val;
        
        ! ==== CHANGE THESE TO CHANGE OUTCOME/SIMULATION ====
            mug := fetch_mup_target;
            mug_normal := [1,-1,0];
            mug_offset := 100;
        ! ====================================================
        
        TPErase;
        moveJ home_target,movespeed,z50,tGripper;
        
        WaitTime(1);
        
        TPErase;
        FetchMug mug.trans,mug_offset,mug_normal; !
        WaitTime(1);
        
        LeaveMug leave_mup_target.trans,[0,0,-1];

        moveJ home_target,movespeed,z50,tGripper;
        TPWrite("DONE");
    ENDPROC
        
ENDMODULE