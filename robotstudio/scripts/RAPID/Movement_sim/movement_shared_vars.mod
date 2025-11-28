MODULE movement_shared_vars
!    ***********************************************************
    
!     Module:  movement_shared_vars
    
!     Description:  Module meant for sharing variables between tasks.
!                   Both tasks needs to define PERS (persistent) variables with identical names.

!                   This specific module is used to share variables between movement and communication tasks.
    
    
!    ***********************************************************
    RECORD movement_vars
        bool wait_flag;
        num flag;
        robtarget target;
    ENDRECORD
    
    PERS movement_vars shared_movement_vars;
        
ENDMODULE