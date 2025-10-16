MODULE left_main

    ! main
    PROC main()

!        TPErase;

        shared_vars.wait_flag := FALSE;
        WHILE TRUE DO !main loop
            !server
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE