MODULE left_main

    ! main
    PROC main()

        multi_move.left_flag := 0;
        multi_move.right_flag := 0;
        
        multi_move.right_in_process := FALSE;
        multi_move.left_in_process:= FALSE;
        WHILE TRUE DO !main loop
            !server
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE