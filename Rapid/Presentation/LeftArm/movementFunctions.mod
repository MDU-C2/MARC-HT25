MODULE movementFunctions
!***********************************************************
!
! Module:  movementFunctions
!
! Description:  These functions can be used for movement between two points and handle problems
!               such as points far away from eachother and high joint values
!
!               Meant to be used with configuration mode off (ConfL & ConfJ \off)
!
! Author: fjn20007
!
!***********************************************************

    PROC MovementProc(robtarget desired_target, num step_size, num max_magnitude, speeddata movement_speed)
        
        VAR robtarget current_target;
        VAR robtarget disc_target;
        VAR robtarget testtarget;
        VAR jointtarget desired_joint_value;
        VAR bool home;
        VAR num testing := 0;
        ConfJ\Off;
        ConfL\Off;
        current_target := CRobT(\Tool:=tGripper);
        testtarget := desired_target;
        
        !Check if calculated joint values at robot target configuration is valid
        desired_joint_value := CalcJointT(testtarget,tGripper);
        
        !Check distance between desired and current targets. Discretize pos & orientation if high distance.
        WHILE VectMagn(desired_target.trans-current_target.trans) > max_magnitude DO
            disc_target := discretizeTarget(current_target,desired_target,step_size);
            desired_joint_value := CalcJointT(disc_target,tGripper);
            MoveJ disc_target,movement_speed,z50,tGripper;
            current_target := CRobT(\Tool:=tGripper);
        ENDWHILE

        !Check if calculated joint values at robot target configuration is valid
        desired_joint_value := CalcJointT(testtarget,tGripper);
        
        MoveJ desired_target,movement_speed,fine,tGripper;
!        ProcerrRecovery \SyncOrgMoveInst;
        
        ERROR
        IF ERRNO = ERR_ROBLIMIT THEN !Joint values outside of working range
            ResetRetryCount;
!            IF testing > 1 THEN
!                moveToHomeTarget;
!                TPWrite "Failed to reach target";
!                RETURN;
!            ENDIF
            IF VectMagn(desired_target.trans-current_target.trans) > max_magnitude THEN
                disc_target := discretizeTarget(current_target,desired_target,step_size);
                MoveJ disc_target,movement_speed,z50,tGripper;
                current_target := CRobT(\Tool:=tGripper);

                IF disc_target = home_target THEN
                    home := TRUE;
                    Incr testing;
                ENDIF
                RETRY;
            ELSEIF NOT home THEN
                moveToHomeTarget;
                current_target := CRobT(\Tool:=tGripper);
                home := TRUE;
                RETRY;
            ELSE
                moveToHomeTarget;
                TPWrite "Failed to reach target";

                RETURN;
            ENDIF
        ELSEIF ERRNO = ERR_OUTSIDE_REACH THEN !Robot cannot reach to desired position
            TPWrite "Outside of reach";
            RETURN;
        ELSEIF ERRNO = ERR_PATH_STOP THEN !Only used if ProcerrRecovery \SyncOrgMoveInst; is active
            TPWrite "Movement stopped!";
            TRYNEXT;
        ENDIF
    ENDPROC
    
!    ***********************************************************
!     Function: discretizeTarget

!     Description:  Returns a pos/orient between current and desired target, checking valid pos/orient iterating between the targets by step_size.
!                   Moves to predefined HomeTarget if no valid pos/orient.
    
!    ***********************************************************
    FUNC robtarget discretizeTarget(robtarget current_target, robtarget desired_target,num step_size)
        
        VAR robtarget disc_target;
        VAR jointtarget disc_joints;
        VAR num fixed_step;
        VAR num vector_magn;
        VAR num orient_frac;
        
        fixed_step := step_size;
        vector_magn := VectMagn(desired_target.trans-current_target.trans);
        orient_frac := step_size / vector_magn;
        
        disc_target := current_target;
       
        disc_target.trans := discretizePosition(current_target.trans,desired_target.trans,step_size);
        disc_target.rot := discretizeOrient(current_target.rot,desired_target.rot,orient_frac);
        
        WHILE NOT checkJointValues(disc_target) DO
            
            step_size := step_size + fixed_step;
            
            IF step_size > vector_magn THEN
                moveToHomeTarget;
                RETURN home_target;
            ENDIF
            
            disc_target.trans := discretizePosition(current_target.trans,desired_target.trans,step_size);
            disc_target.rot := discretizeOrient(current_target.rot,desired_target.rot,orient_frac);
            
        ENDWHILE
        
        RETURN disc_target;
        
    ENDFUNC
    
!    ***********************************************************
!     Function: discretizePosition

!     Description:  Returns the point located the given step_size away from current position towards desired position.
    
!    ***********************************************************
    FUNC pos discretizePosition(pos current_target,pos desired_target,num step_size)
    
        VAR pos dir_vector;
        VAR pos return_pos;
        
        dir_vector := desired_target - current_target;
        dir_vector := dir_vector / VectMagn(dir_vector);
        return_pos := current_target + dir_vector * step_size;
    !    return_pos := desired_target - dir_vector * step_size;
        
        RETURN return_pos;
    ENDFUNC
    
!    ***********************************************************
!     Function: discretizePosition

!     Description:  Returns the orientation between current and desired orientation dependant on step_size.
    
!    ***********************************************************
    FUNC orient discretizeOrient(orient current_orient,orient desired_orient,num step_size)
    
        VAR orient dir_vector;
        VAR orient return_orient;
        VAR num angle;
        VAR num sin_angle;
        VAR num coeff_1;
        VAR num coeff_2;
        VAR num dot_prod;
        
        dot_prod := QuaternionDotProd(current_orient,desired_orient);
    
        IF (dot_prod > 1) OR (dot_prod < -1) THEN
            RETURN current_orient;
        ENDIF
        
        angle := ACos(dot_prod);
        sin_angle := sin(angle);
        coeff_1 := sin((1-step_size)*angle) / sin_angle;
        coeff_2 := sin(step_size*angle) / sin_angle;
    
        return_orient.q1 := coeff_1 * current_orient.q1 + coeff_2 * desired_orient.q1;
        return_orient.q2 := coeff_1 * current_orient.q2 + coeff_2 * desired_orient.q2;
        return_orient.q3 := coeff_1 * current_orient.q3 + coeff_2 * desired_orient.q3;
        return_orient.q4 := coeff_1 * current_orient.q4 + coeff_2 * desired_orient.q4;
    
        
        RETURN return_orient;
        ERROR
        IF ERRNO = ERR_DIVZERO THEN
            sin_angle := sin_angle + 0.000001;
            RETRY;
        ENDIF
    ENDFUNC
    
!    ***********************************************************
!     Function: QuaternionDotProd

!     Description:  Returns the dot product two quaternions
    
!    ***********************************************************
    FUNC num QuaternionDotProd(orient q1,orient q2)
        VAR num dot_product;
        dot_product := q1.q1*q2.q1+q1.q2*q2.q2+q1.q3*q2.q3+q1.q4*q2.q4;
        RETURN dot_product;
    ENDFUNC

!    ***********************************************************
!     Function: checkJointValues

!     Description:  Check wether calculated joint values from a target are valid
    
!    ***********************************************************
    FUNC BOOL checkJointValues(robtarget desired_target)
        
        VAR jointtarget desired_joint_target;
        
        desired_joint_target := CalcJointT(desired_target,tGripper);
        RETURN TRUE;
    ERROR
    IF ERRNO = ERR_ROBLIMIT THEN
        RETURN FALSE;
    ELSEIF ERRNO = ERR_OUTSIDE_REACH THEN
        RETURN FALSE;
    ENDIF
    ENDFUNC
    
!    ***********************************************************
!     Process: moveToHomeTarget

!     Description:  simply move to pre defined home_target
    
!    ***********************************************************
    PROC moveToHomeTarget()
        ConfJ\On;
        MoveJ home_target,v300,fine,tGripper;
        ConfJ\Off;
    ENDPROC
ENDMODULE
