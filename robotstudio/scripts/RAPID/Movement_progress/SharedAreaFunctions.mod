MODULE SharedAreaFunctions
        
    RECORD shared_area_struct
        num cup_diameter;
        num current_index;
        num max_index;
        pos origin;
        bool in_area;
    ENDRECORD
    
    PERS shared_area_struct shared_area;
    CONST robtarget cup_right_arm_offset:=[[0,-80,0],[0.0241174,-0.677492,-0.733923,-0.0421858],[2,1,0,5],[125.044,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget cup_left_arm_offset:=[[0,80,0],[0.00583917,-0.715952,0.697835,0.0201495],[-1,1,2,4],[-131.981,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST num mug_rads := 70/2;
    !CONST robtarget cup_origin:=[[111.17,0,-50],[0.00272004,0.292881,0.955993,0.0170228],[-1,3,1,0],[141.996,9E+9,9E+9,9E+9,9E+9,9E+9]];
    
    CONST num high_offset := 100;
    CONST num delay_time := 0.5;
    
    PROC InitSharedArea(num cup_diameter,num max_amount_of_cups,pos cup_origin)
        shared_area.cup_diameter := cup_diameter;
        shared_area.current_index := 0; 
        shared_area.max_index := max_amount_of_cups;
        shared_area.origin := cup_origin;
        shared_area.in_area := FALSE;
    ENDPROC
    
    ! add cup
    FUNC bool AddCup(robtarget fetch_target,bool right_arm) ! false = left arm. true = right arm
       ! init variables
        VAR robtarget leave_target;
        VAR pos cup_pos;
        
        ! if there buffer is full, return false
        IF shared_area.current_index >= shared_area.max_index THEN
            RETURN FALSE;
        ENDIF
        
        ! pick up cup
        PickUp(fetch_target);
        
        !take semaphore before entering shared area
        WHILE shared_area.in_area DO
            WaitTime(delay_time);
        ENDWHILE
        shared_area.in_area := TRUE;
         
        !get config stuff
        leave_target := CRobT(\Tool:=tGripper);
        
        !calculate new pos
        shared_area.current_index := shared_area.current_index +1;
        cup_pos := shared_area.origin;
        cup_pos.x := cup_pos.x + shared_area.cup_diameter*shared_area.current_index; !offset in x    
        
        IF right_arm THEN
            cup_pos.y := cup_pos.y - mug_rads;
        ELSE
            cup_pos.y := cup_pos.y + mug_rads;
        ENDIF
        
        leave_target.trans := cup_pos;
         
        ! go an place cup in desired pos
        DropOff(leave_target);
        
        !leave semaphore
         shared_area.in_area := FALSE;
        
        RETURN TRUE;
    ENDFUNC
        
    ! remove cup
    FUNC bool RemoveCup(robtarget leave_target,bool right_arm)
        VAR robtarget current;
        VAR pos cup_pos;
        
        IF shared_area.current_index <= 0 THEN
            RETURN FALSE;
        ENDIF
        
        ! move and pick up cup func   
        WHILE shared_area.in_area DO
            waitTime(delay_time);
        ENDWHILE
        
        ! get cup target
        shared_area.in_area := TRUE;
        current := cup_right_arm_offset;!CRobT(\Tool:=tGripper);
        cup_pos := shared_area.origin;
        cup_pos.x := cup_pos.x + shared_area.cup_diameter*shared_area.current_index; !offset in x  
     
        IF right_arm THEN
            cup_pos.y := cup_pos.y - mug_rads;
        ELSE
            cup_pos.y := cup_pos.y + mug_rads;
        ENDIF
        current.trans := cup_pos;
        
        PickUp(current);
        
        shared_area.in_area := FALSE;
        
        shared_area.current_index := shared_area.current_index -1;
         
        DropOff(leave_target);
        
        RETURN TRUE;
        
    ENDFUNC
    
    PROC  PickUp(robtarget target)
        
       ! ConfJ\Off;
        ! go and place cup in desired pos
        moveJ Offs(target,0,0,high_offset),movespeed,z50,tGripper;
        
        ! release
        WaitTime(delay_time);
        g_GripOut;
        
        WaitTime(delay_time);
        moveJ target,movespeed,z50,tGripper;   
        
        ! gripp
        WaitTime(delay_time);
        g_GripIn;
        
        WaitTime(delay_time);
        moveJ Offs(target,0,0,high_offset),movespeed,z50,tGripper;
    ENDPROC
    
    PROC  DropOff(robtarget target)
        
        ConfJ\Off;
        ! go and place cup in desired pos
        moveJ Offs(target,0,0,high_offset),movespeed,z50,tGripper;
        moveJ target,movespeed,z50,tGripper;   
        
        ! release
        WaitTime(delay_time);
        g_GripOut;
        
        WaitTime(delay_time);
        
        moveJ Offs(target,0,0,high_offset),movespeed,z50,tGripper;
    ENDPROC
    
ENDMODULE