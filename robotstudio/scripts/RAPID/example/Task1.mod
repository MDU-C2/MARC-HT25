MODULE Task1
    PERS bool trapFlag := FALSE;
    VAR intnum intTrap;
    
    CONST jointtarget jtPosA:=[[1,0,0,0,0,0],[0,9E9,9E9,9E9,9E9,9E9]];
    CONST jointtarget jtPosB:=[[-1,0,0,0,0,0],[0,9E9,9E9,9E9,9E9,9E9]];
    
    CONST jointtarget jtPosC:=[[0,1,0,0,0,0],[0,9E9,9E9,9E9,9E9,9E9]];
    CONST jointtarget jtPosD:=[[0,-1,0,0,0,0],[0,9E9,9E9,9E9,9E9,9E9]];

    PROC main()
        ! Connect interrupt to trap routine
        CONNECT intTrap  WITH trapRoutine;
        IPers trapFlag, intTrap;


        WHILE TRUE DO
            ! Oscillate Joint1 back and forth
            MoveabsJ jtPosA, v100, fine, tool0;
            MoveabsJ jtPosB, v100, fine, tool0;
            
        ENDWHILE
    ENDPROC

    TRAP trapRoutine
        !IDisable;
        StopMove;        ! Stop current motion
        ClearPath;       ! Clear planned path
        StorePath;       ! Save path so new moves are allowed
        
        !trapFlag := FALSE;   ! unnecessary, IPers triggers on change of trapFlag

        ! Oscillate Joint2 back and forth
        MoveAbsJ jtPosC, v100, fine, tool0;
        MoveAbsJ jtPosD, v100, fine, tool0;
        
        ! Remove ResttoPath & StartMove if you want to discard the motion that was executed before the TRAP/interrupt
        RestoPath;       ! Restore path afterwards if you want to resume
        StartMove;       ! Resume motion execution
        !IEnable;
    ENDTRAP
    
    
    
    
    
    
ENDMODULE