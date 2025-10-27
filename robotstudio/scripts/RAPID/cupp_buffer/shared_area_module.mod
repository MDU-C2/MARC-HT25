MODULE shared_area_module
    ! assumes module can find these vars
     RECORD shared_area_struct
        num cup_diameter;
        num current_index;
        num max_index;
        pos origin;
    ENDRECORD
    VAR shared_area_struct shared_area;
    
    CONST robtarget cup_origin:=[[111.17,0,-50],[0.00272004,0.292881,0.955993,0.0170228],[-1,3,1,0],[141.996,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST speeddata movespeed:= v200;
    CONST robtarget home:=[[-9.58,-182.61,198.63],[0.0660107,-0.842421,-0.111215,-0.523069],[0,0,0,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget cup:=[[303.05,-355.37,96.37],[0.116431,-0.991183,-0.0563017,0.028824],[1,-1,2,4],[-101.964,9E+9,9E+9,9E+9,9E+9,9E+9]];
    
    PROC main()
        VAR robtarget disired_pos := cup_origin;
        
        !init
        shared_area.current_index := 0;
        shared_area.cup_diameter := 100; ! assume mm
        shared_area.max_index := 4;
        shared_area.origin := cup_origin.trans;
        ConfJ\Off;
        
        ! start pos
        moveJ home,movespeed,z50,tool0;
        
        !pick up cup
        moveJ cup,movespeed,z50,tool0;
        IF(NOT addCup()) THEN
                         ! failed
            StopMove;
            moveJ home,movespeed,z50,tool0;
            Stop;
        ENDIF
        
        !pick up cup
        moveJ cup,movespeed,z50,tool0;
        IF(NOT addCup()) THEN
            ! failed
            StopMove;
            moveJ home,movespeed,z50,tool0;
            Stop;
        ENDIF
        
        !pick up cup
        moveJ cup,movespeed,z50,tool0;
        IF(NOT addCup()) THEN
            ! failed
            StopMove;
            moveJ home,movespeed,z50,tool0;
            Stop;
        ENDIF
        
        ! wait a sec
        moveJ home,movespeed,z50,tool0;
        WaitTime(1);
        
        ! remove all cups
        WHILE shared_area.current_index > 0 DO
            IF(NOT removeCup(cup)) THEN
                
                ! failed
                StopMove;
                moveJ home,movespeed,z50,tool0;
                Stop;
            ENDIF
        ENDWHILE
        
        
    ENDPROC
    
    ! assumes arm have cup in gripper
    FUNC bool addCup()
        
        VAR robtarget drop_target;
        VAR pos cup_pos;
        
        IF shared_area.current_index >= shared_area.max_index THEN
            RETURN FALSE;
        ENDIF
        
        drop_target := CRobT(\Tool:=tool0);
        
        shared_area.current_index := shared_area.current_index +1;
        
        cup_pos := shared_area.origin;
        cup_pos.x := cup_pos.x + shared_area.cup_diameter*shared_area.current_index; !offset in x      
        drop_target.trans := cup_pos;
        
        ! go an place cup in desired pos
        moveDropOff(drop_target);
        
        RETURN TRUE;
    ENDFUNC
    
    FUNC bool removeCup(robtarget drop_target)
        
        VAR robtarget current;
        VAR pos cup_pos;
        
        IF shared_area.current_index <= 0 THEN
            RETURN FALSE;
        ENDIF
        
        current := CRobT(\Tool:=tool0);
        
        ! pick up cup
        cup_pos := shared_area.origin;
        cup_pos.x := cup_pos.x + shared_area.cup_diameter*shared_area.current_index; !offset in x  
        current.trans := cup_pos;
        
        ! move and pick up cup func   
        movePickUp(current);
        
        shared_area.current_index := shared_area.current_index -1;
         
        moveDropOff(drop_target);
        
        RETURN TRUE;
        
    ENDFUNC
    
    PROC movePickUp(robtarget target)
        
        ! go and place cup in desired pos
        moveJ Offs(target,0,0,300),movespeed,z50,tool0;
        ! release
        WaitTime(.5);
        moveJ target,movespeed,z50,tool0;   
        ! gripp
        WaitTime(.5);
        moveJ Offs(target,0,0,300),movespeed,z50,tool0;
    ENDPROC
    
    PROC moveDropOff(robtarget target)
        
        ! go and place cup in desired pos
        moveJ Offs(target,0,0,300),movespeed,z50,tool0;
        moveJ target,movespeed,z50,tool0;   
        ! release
        WaitTime(.5);
        
        moveJ Offs(target,0,0,300),movespeed,z50,tool0;
    ENDPROC
ENDMODULE