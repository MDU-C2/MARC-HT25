MODULE left_main

    ! main
    PROC main()
        shared_vars.shared_bool := FALSE;
        WHILE TRUE DO !main loop
            !server
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE