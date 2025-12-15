MODULE left_main

    ! main
    PROC main()
        CONST string file_name := "Positions.txt";
        TPErase;

        loadCalibTargets file_name,calib_robtargets,calib_array_size;
        shared_movement_vars.wait_flag := FALSE;
        
        WHILE TRUE DO !main loop
            
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE