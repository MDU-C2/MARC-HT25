MODULE Task2
    PERS bool trapFlag := FALSE;
    PROC main()
        WHILE TRUE DO
            WaitTime 10; ! Run timer for 6 seconds
            trapFlag := NOT trapFlag; ! Trigger trap in Task1
        ENDWHILE
    ENDPROC
ENDMODULE