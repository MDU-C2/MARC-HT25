MODULE CommunicationMain

    ! main
    CONST mug_vector mug_leave_pose := [[513.42,-441.85,110.96],[0,0,-1]];
!    PERS robtarget calib_robtargets20:=[[513.42,-441.85,110.96],[0.353418,-0.368452,0.597902,-0.617941],[1,1,1,4],[-179.943,9E+09,9E+09,9E+09,9E+09,9E+09]];
    PROC main()
        CONST string file_name := "Positions.txt";
        CONST string file_name2 := "Calib_Positions_rightarm";
        
        ! init all shared variables
        shared_movement_left.wait_flag := FALSE;
        shared_movement_right.wait_flag := FALSE;
        shared_movement_left.flag := flag_nothing;
        shared_movement_right.flag := flag_nothing;
        
        TPErase;

!        loadCalibTargets file_name,calib_robtargets,calib_array_size;
!        loadCalibTargets file_name2,calib_robtargets_right,39;
        
        WHILE TRUE DO !main loop
            
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE