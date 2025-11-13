MODULE RightArmExample

    
    CONST speeddata movespeed:= v200;
    CONST robtarget home:=[[-9.58,-182.61,198.63],[0.0660107,-0.842421,-0.111215,-0.523069],[0,0,0,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget leave_cup_target:=[[303.05,-355.37,96.37],[0.116431,-0.991183,-0.0563017,0.028824],[1,-1,2,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    
    PROC main()
        
        moveJ home,movespeed,z50,tool0;
        WaitTime(1); ! to let left arm init everything!
        
        WHILE TRUE DO
            IF RemoveCup(leave_cup_target) THEN
                TPWrite"right arm removed cup to buffer, left in buffer:" , \Num:=shared_area.current_index;
            ELSE
                WaitTime(1); ! can not add cup right now. To many in buffer
            ENDIF
        ENDWHILE
        
    ENDPROC
ENDMODULE