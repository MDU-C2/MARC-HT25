MODULE LeftArmExample
    
    CONST speeddata movespeed:= v200;
!    CONST robtarget fetch_cup_target:=[[307.17,-50,-40.76],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
!    CONST robtarget fetch_cup_target:=[[307.17,362.86,24.76],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
!    CONST robtarget fetch_cup_target:=[[433.48,296.01,-39.85],[0.0281776,0.997805,-0.0448158,0.0397721],[-1,2,-2,4],[91.8814,9E+09,9E+09,9E+09,9E+09,9E+09]];
!    CONST robtarget home:=[[-9.58,182.61,198.63],[0.0660107,0.842421,-0.111215,0.523069],[0,0,0,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];

    CONST robtarget home_target:=[[339.81,263.01,178.28],[0.465383,0.56304,0.301843,0.612614],[0,0,-1,4],[121.274,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget fetch_cup_target:=[[355.37,13.65,50.38],[0.0303038,0.909324,-0.409024,0.0700746],[-1,2,-2,4],[132.67,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
   ! PERS tooldata tGripper := [TRUE, [[0, 0, 0], [1, 0, 0, 0]], [0.001, [0, 0, 0.001],[1, 0, 0, 0], 0, 0, 0]];
    
    PROC main()
        VAR orient temp;
        VAR robtarget mug;
        VAR pos mug_normal;
        VAR num mug_offset;
        VAR num val;
        
        mug := fetch_cup_target;
        mug_normal := [0,0,1];
        
!        ! for + or - does not mater!
!        ! ======================================
!            mug_normal.x := Abs(mug_normal.x);
!            mug_normal.y := Abs(mug_normal.y);
!            mug_normal.z := Abs(mug_normal.z);
!        ! ======================================
        
        mug_offset := 50;
        
        TPErase;
        moveJ home_target,movespeed,z50,tGripper;
        
        WaitTime(1);
        
        TPErase;
!        moveJ home_target,movespeed,z50,tGripper;
        
        FetchMug home_target.trans,mug_offset,mug_normal; !
!        WaitTime(1);m
        
        
        moveJ home_target,movespeed,z50,tGripper;
        TPWrite("DONE");
    ENDPROC
        
ENDMODULE