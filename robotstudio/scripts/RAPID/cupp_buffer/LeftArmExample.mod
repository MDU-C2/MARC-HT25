MODULE LeftArmExample
    
    CONST speeddata movespeed:= v1000;
    CONST robtarget fetch_cup_target:=[[307.17,362.86,24.76],[0.0174599,0.997435,-0.0689982,0.0075649],[-1,2,-2,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget home:=[[-9.58,182.61,198.63],[0.0660107,0.842421,-0.111215,0.523069],[0,0,0,4],[101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    
    PROC main()
            
        TPErase;
        moveJ home,movespeed,z50,tool0;
        InitSharedArea 100,4,[100,0,-50];
        
        WHILE TRUE DO
            IF AddCup(fetch_cup_target) THEN
                TPWrite "left arm added cup to buffer, amount in buffer:" , \Num:=shared_area.current_index;
            ELSE
                WaitTime(1); ! can not add cup right now. To many in buffer
            ENDIF
        ENDWHILE
        
    ENDPROC
        
ENDMODULE