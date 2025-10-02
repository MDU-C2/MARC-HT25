MODULE left_main

    ! main
    PROC main()
!        WaitTime 2;
!        shared_vars.flag := 3;
!        shared_vars.wait_flag := TRUE;

!        TPErase;
!        WaitTime 2;
!        TPwrite ""\Num:=shared_vars.flag;
!        TPWrite ""\Bool:=shared_vars.wait_flag;
        shared_vars.wait_flag := FALSE;
        WHILE TRUE DO !main loop
            !server
            single_client_communication; ! get and connect client communication
        
        ENDWHILE
    ENDPROC
ENDMODULE