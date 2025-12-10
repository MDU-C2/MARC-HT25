MODULE CommunicationMain

    ! main
    CONST mug_vector mug_leave_pose := [[200,-550,60],[0,0,-1]];
    PROC main()
        CONST string file_name := "Positions.txt";
        
        ! init all shared variables
        shared_movement_left.wait_flag := FALSE;
        shared_movement_right.wait_flag := FALSE;
        shared_movement_left.flag := flag_nothing;
        shared_movement_right.flag := flag_nothing;
        
        TPErase;

        loadCalibTargets file_name,calib_robtargets,calib_array_size;
        
        WHILE TRUE DO !main loop
            
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE