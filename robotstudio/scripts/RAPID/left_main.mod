MODULE left_main

    ! main
    PROC main()
        !variables and init functions
        server_init;

        WHILE TRUE DO !main loop
            !server
            single_client_communication; ! get and connect client communication
        
            !move arm
            !TPWrite("[INFO] this is the other function"); ! to check if multithreading might be needed

        ENDWHILE
    ENDPROC
ENDMODULE