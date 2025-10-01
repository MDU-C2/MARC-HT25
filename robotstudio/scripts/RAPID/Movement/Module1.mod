MODULE Module1
    !***********************************************************
    !
    ! Module:  Module1
    !
    ! Description:
    !   <Insert description here>
    !
    ! Author: fjn20007
    !
    ! Version: 1.0
    !
    !***********************************************************


    PROC main()
        
        WHILE TRUE DO
            WaitUntil shared_vars.wait_flag = TRUE;
            
            TEST shared_vars.flag
            CASE 1:
                MoveAbsJ shared_vars.joint_values, v100, fine, tool0;
!                MoveAbsJ shared_vars.shared_jointtarget, v100, fine, tGripper;

            CASE 2:
!                MoveToHome;
            ENDTEST
            shared_vars.wait_flag := FALSE;
        ENDWHILE
    ENDPROC
ENDMODULE