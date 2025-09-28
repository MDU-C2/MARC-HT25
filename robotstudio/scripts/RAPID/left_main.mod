MODULE left_main

    PROC dynamic_load()
        CONST string path:="C:\Users\Elliot\Desktop\year5\project-course\MARC-HT25\robotstudio\scripts\RAPID";
        
        Load \Dynamic, path \File:= "server.mod";
        
        
    ENDPROC
    
    ! main
    PROC main()
        !variables and init functions
        server_init;

        WHILE TRUE DO !main loop
            !server
            single_client_communication; ! get and connect client communication
        
            !move arm
            TPWrite("[INFO] this is the other function"); ! to check if multithreading might be needed

        ENDWHILE
    ENDPROC
ENDMODULE