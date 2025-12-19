MODULE sim_processes
    PROC g_calibrate ()
        TPWrite "Callibrating grippers [Sim]";
        
    ENDPROC
    
    
    PROC MoveToHome()
        
        TPWrite "Moving to home [Sim]";
        
    ENDPROC
    
    
    
    PROC g_gripIn()
    
        TPWrite "Gripping [Sim]";
    ENDPROC
    
    
    PROC g_gripOut()
        
        TPWrite "Releasing [Sim]";
    ENDPROC
ENDMODULE