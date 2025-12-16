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
    
    PERS movement_vars shared_movement_right;
    
    CONST num flag_ERROR := -1;
    CONST num flag_nothing:=0;
    CONST num flag_move:= 1;
    CONST num flag_move_home:= 2;
    CONST num flag_move_home_target:= 3;
    CONST num flag_move_calibration:= 4;
    CONST num flag_pick_up_mug := 5;
    CONST num flag_leave_mug := 6;
    CONST num flag_hand_over := 7;
    CONST num flag_move_calibration_home := 8;
    CONST num flag_move_calibration_outofway := 9;
    CONST num flag_presentation_fetch := 10;
    CONST num flag_presentation_leave := 11;
    
    ! ========== CALIBRATION ========== 
    CONST num calib_array_size := 40;
    PERS robtarget calib_robtargets_right{calib_array_size};
    PERS robtarget current_right_target; ! to return right hand values, because communication is "left arm" dependent
    
ENDMODULE