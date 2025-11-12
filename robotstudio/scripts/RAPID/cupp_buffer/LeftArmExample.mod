MODULE LeftArmExample
    
    CONST speeddata movespeed:= v200;
    CONST robtarget fetch_cup_target:=[[307.17,362.86,24.76],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget home:=[[-9.58,182.61,198.63],[0.0660107,0.842421,-0.111215,0.523069],[0,0,0,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS tooldata tGripper := [TRUE, [[0, 0, 0], [1, 0, 0, 0]], [0.001, [0, 0, 0.001],[1, 0, 0, 0], 0, 0, 0]];
    
    PROC main()
        VAR orient temp;
        VAR robtarget mug;
        VAR pos mug_normal;
        VAR num mug_offset;
        VAR num val;
        val := 1/sqrt(2);
        
        mug := fetch_cup_target;
        mug_normal := [1,0,0];
        
        ! for + or - does not mater!
        ! ======================================
            mug_normal.x := Abs(mug_normal.x);
            mug_normal.y := Abs(mug_normal.y);
            mug_normal.z := Abs(mug_normal.z);
        ! ======================================
        
        mug_offset := 50;
        
        TPErase;
        moveJ home,movespeed,z50,tool0;
        
        WaitTime(1);
        
        FetchMug mug.trans,mug_offset,mug_normal; !
        WaitTime(1);
        
        
        moveJ home,movespeed,z50,tool0;
        TPWrite("DONE");
    ENDPROC
        
ENDMODULE