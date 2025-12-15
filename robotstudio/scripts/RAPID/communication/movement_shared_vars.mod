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
        
    
    CONST num flag_move:= 1;
    CONST num flag_move_home:= 2;
    CONST num flag_gripper_grip:= 3;
    CONST num flag_gripper_release:= 4;
    CONST num flag_move_home_target:= 5;
    CONST num flag_move_gripsequence:= 6;
    CONST num flag_move_leavesequence:= 7;
    CONST num flag_move_EGM:= 8;
    CONST num flag_move_calibration:= 9;
ENDMODULE