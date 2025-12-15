MODULE shared_vars
    
!    ***********************************************************
!     Module:  shared_vars
    
!     Description:  Module meant for sharing variables between tasks.
!                   Both tasks needs to define PERS (persistent) variables with identical names.

!                   This specific module is used to share variables between movement and communication tasks.
!    ***********************************************************

    ! ==== dynamic global vars ====
    RECORD mug_vector
        pos position;
        pos normal;
    ENDRECORD
    
    !========== MOVEMENT ========== 
    RECORD movement_vars
      bool wait_flag;
      num flag;
      robtarget target;
      mug_vector hand_over_pose;
      mug_vector mug;
    ENDRECORD
    
    PERS movement_vars shared_movement_left;
    
    CONST num flag_ERROR := -1;
    CONST num flag_nothing:=0;
    CONST num flag_move:= 1;
    CONST num flag_move_home:= 2;
    CONST num flag_gripper_grip:= 3;
    CONST num flag_gripper_release:= 4;
    CONST num flag_move_home_target:= 5;
    CONST num flag_move_gripsequence:= 6;
    CONST num flag_move_leavesequence:= 7;
    CONST num flag_move_EGM:= 8;
    CONST num flag_move_calibration:= 9;
    CONST num flag_pick_up_mug := 10;
    CONST num flag_leave_mug := 11;
    CONST num flag_hand_over := 12;
    
    
    ! ========== CALIBRATION ========== 
    CONST num calib_array_size := 40;
    PERS robtarget calib_robtargets{calib_array_size};
    
ENDMODULE