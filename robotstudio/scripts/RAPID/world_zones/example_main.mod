MODULE example_main
        
    VAR intnum collided;
    CONST robtarget OVER_GROUND:=[[424.65,-110.80,370.06],[0.0149491,4.71639E-7,-0.999888,-3.23973E-7],[-2,3,1,0],[145.363,9E+9,9E+9,9E+9,9E+9,9E+9]];
    CONST robtarget UNDER_GROUND:=[[274.65,-93.12,52.75],[0.0480841,0.200921,0.972837,-0.104436],[0,2,2,0],[112.041,9E+9,9E+9,9E+9,9E+9,9E+9]];
    
    PROC main()
        ! assumes that arm start in valid pos
        MoveJ OVER_GROUND, v100,fine,tool0;
        TPErase;
        
        ! ============ Start here =============     
        CONNECT collided WITH trapRoutine;
        ISignalDI HIT_FLOOR_IN, 1 , collided;
        
        init_world_zones;
        
        MoveJ UNDER_GROUND, v100,fine,tool0;
        WaitTime(1);
        
        MoveJ OVER_GROUND, v100,fine,tool0;
    ENDPROC
        
     TRAP trapRoutine
        !IDisable;
        StopMove;        ! Stop current motion
        ClearPath;       ! Clear planned path
        StorePath;       ! Save path so new moves are allowed
        TPWrite("[ERROR] collided with floor");
        
        !stop program?
        Stop;
    ENDTRAP
ENDMODULE