MODULE load_modules
    
    PROC dynamic_load()
        
        CONST string path := "C:/Users/Elliot/Desktop/year5/project-course/MARC-HT25/robotstudio/scripts/RAPID/";
        
        Load \Dynamic, path \File:= "server.mod";
        
    ENDPROC
ENDMODULE