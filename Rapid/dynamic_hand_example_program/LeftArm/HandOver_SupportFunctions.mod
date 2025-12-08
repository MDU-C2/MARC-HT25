MODULE HandOver_SupportFunctions
    
    FUNC pose HandOverTarget(pose end_target, pose mug_current_target)
        VAR pose middle_target;
        
        ! half way mark
        middle_target.trans := end_target.trans  - (end_target.trans - mug_current_target.trans)/2;
        
        ! to make it easier for the leaving arm
        middle_target.rot := end_target.rot;
        
        RETURN middle_target;
    ENDFUNC
    
ENDMODULE