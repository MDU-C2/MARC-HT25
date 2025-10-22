MODULE movementFunctions
    !***********************************************************
    !
    ! Module:  movementFunctions
    !
    ! Description:
    !   These functions can be used for movement between two points and
    !   handle problems such as points far away from eachother and high joint values
    !
    ! Author: fjn20007
    !
    ! Version: 1.0
    !
    !***********************************************************
    
!    PROC MovementProc(robtarget desired_target, num step_size, num orient_frac, num joint_threshold, speeddata movement_speed)
!        VAR robtarget current_target;
!        VAR robtarget disc_target;
!        VAR jointtarget desired_joint_value;
!        VAR bool home;
!        current_target := CRobT(\Tool:=tGripper);
!        disc_target := current_target;
        
        
!        desired_joint_value := CalcJointT(desired_target,tGripper);
!!        disc_target.trans := discreteMovement(current_target.trans,desired_target.trans,step_size);
!!        disc_target.rot := discreteOrient(current_target.rot,desired_target.rot,orient_frac);
!!        MoveJ disc_target,movement_speed,fine,tGripper;
!        MoveJ desired_target,movement_speed,fine,tGripper;
        
!        ERROR
!        IF ERRNO = ERR_ROBLIMIT THEN

!            IF HOME THEN
!                STOP;
!            ENDIF
!            disc_target.trans := discreteMovement(current_target.trans,desired_target.trans,step_size);
!            disc_target.rot := discreteOrient(current_target.rot,desired_target.rot,orient_frac);
            
!            WHILE NOT checkJointValues(current_target,disc_target, joint_threshold) DO
!                step_size := step_size + 50;
!                disc_target.trans := discreteMovement(current_target.trans,desired_target.trans,step_size);
!                disc_target.rot := discreteOrient(current_target.rot,desired_target.rot,orient_frac);
!                IF step_size > VectMagn(desired_target.trans-current_target.trans) THEN
!!                    STOP;
!                    IF HOME THEN
!                        RETRY;    
!                    ENDIF
                    
!                    ConfJ\On;
!                    MoveJ home_target,movement_speed,fine,tGripper;
!                    ConfJ\Off;
!                    current_target := CrobT(\Tool:=tGripper);
!                    home := TRUE;
!                    step_size := 50;
!                ENDIF
!            ENDWHILE
!!            checkJointValues current_target,disc_target, joint_threshold;
!            MoveJ disc_target,movement_speed,z50,tGripper;
!!            MoveJ home_target,movement_speed,fine,tool0;
!            current_target := CRobT(\Tool:=tGripper);

!            RETRY;
!        ENDIF
        
        
!!        WHILE VectMagn(desired_target.trans-current_target.trans) > 500 DO

!!            disc_target.trans := discreteMovement(current_target.trans,desired_target.trans,step_size);
!!            disc_target.rot := discreteOrient(current_target.rot,desired_target.rot,orient_frac);
!!            checkJointValues current_target,disc_target, joint_threshold;
!!            MoveJ disc_target,movement_speed,z50,tGripper;
!!            current_target := CRobT(\Tool:=tGripper);
!!        ENDWHILE
!!        checkJointValues current_target,disc_target, joint_threshold;
!!        MoveJ desired_target,movement_speed,z100,tool0;
!    ENDPROC
    



        PROC MovementProc(robtarget desired_target, num step_size, num orient_frac, num joint_threshold, speeddata movement_speed)
        VAR robtarget current_target;
        VAR robtarget disc_target;
        VAR jointtarget desired_joint_value;
        VAR bool home;
        current_target := CRobT(\Tool:=tGripper);
        disc_target := current_target;
        
        
        desired_joint_value := CalcJointT(desired_target,tGripper);
        
!        WHILE VectMagn(desired_target.trans-current_target.trans) > 500 DO
            
!            disc_target.trans := discretizePosition(current_target.trans,desired_target.trans,step_size);
!            disc_target.rot := discretizeOrient(current_target.rot,desired_target.rot,orient_frac);
            
!            MoveJ disc_target,movement_speed,z50,tGripper;
!            current_target := CRobT(\Tool:=tGripper);
            
!        ENDWHILE
!        disc_target.trans := discreteMovement(current_target.trans,desired_target.trans,step_size);
!        disc_target.rot := discreteOrient(current_target.rot,desired_target.rot,orient_frac);
!        MoveJ disc_target,movement_speed,fine,tGripper;
        MoveJ desired_target,movement_speed,fine,tGripper;
        
        ERROR
        IF ERRNO = ERR_ROBLIMIT THEN

            IF HOME THEN
                STOP;
            ENDIF
            disc_target.trans := discretizePosition(current_target.trans,desired_target.trans,step_size);
            disc_target.rot := discretizeOrient(current_target.rot,desired_target.rot,orient_frac);
            
            WHILE NOT checkJointValues(current_target,disc_target, joint_threshold) DO
                step_size := step_size + 50;
                disc_target.trans := discretizePosition(current_target.trans,desired_target.trans,step_size);
                disc_target.rot := discretizeOrient(current_target.rot,desired_target.rot,orient_frac);
                IF step_size > VectMagn(desired_target.trans-current_target.trans) THEN
!                    STOP;
                    IF HOME THEN
                        RETRY;    
                    ENDIF
                    
                    ConfJ\On;
                    MoveJ home_target,movement_speed,fine,tGripper;
                    ConfJ\Off;
                    current_target := CrobT(\Tool:=tGripper);
                    home := TRUE;
                    step_size := 50;
                ENDIF
            ENDWHILE
!            checkJointValues current_target,disc_target, joint_threshold;
            MoveJ disc_target,movement_speed,z50,tGripper;
!            MoveJ home_target,movement_speed,fine,tool0;
            current_target := CRobT(\Tool:=tGripper);

            RETRY;
        ENDIF
        
        
!        WHILE VectMagn(desired_target.trans-current_target.trans) > 500 DO

!            disc_target.trans := discreteMovement(current_target.trans,desired_target.trans,step_size);
!            disc_target.rot := discreteOrient(current_target.rot,desired_target.rot,orient_frac);
!            checkJointValues current_target,disc_target, joint_threshold;
!            MoveJ disc_target,movement_speed,z50,tGripper;
!            current_target := CRobT(\Tool:=tGripper);
!        ENDWHILE
!        checkJointValues current_target,disc_target, joint_threshold;
!        MoveJ desired_target,movement_speed,z100,tool0;
    ENDPROC
    
!    FUNC robtarget discretizeTarget(robtarget current_target,robtarget desired_target,num step_size,
    
    
    
    FUNC pos discretizePosition(pos current_target,pos desired_target,num step_size)
    
    VAR pos dir_vector;
    VAR pos return_pos;
    
    dir_vector := desired_target - current_target;
    dir_vector := dir_vector / VectMagn(dir_vector);
    !return_pos := current_target + dir_vector * step_size;
    return_pos := desired_target - dir_vector * step_size;
    
    RETURN return_pos;
    
    ENDFUNC
    
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
    
    ENDFUNC
    
    FUNC num QuaternionDotProd(orient q1,orient q2)
        VAR num dot_product;
        dot_product := q1.q1*q2.q1+q1.q2*q2.q2+q1.q3*q2.q3+q1.q4*q2.q4;
        RETURN dot_product;
    ENDFUNC
        
!    PROC checkCalcJoint(robtarget desired_target)
!        VAR jointtarget joints := CalcJointT(desired_target,tool0);
        
        
!    ENDPROC
    
    FUNC BOOL checkJointValues(robtarget target, robtarget desired_target,num threshold)
        
        VAR jointtarget desired_joint_target;
  !      VAR robtarget rob_target;
        
        desired_joint_target := CalcJointT(desired_target,tGripper);
        RETURN TRUE;
    ERROR
    IF ERRNO = ERR_ROBLIMIT THEN

!        desired_target := rob_target;
!        ConfJ\On;
!        ConfL\On;
!        MoveJ rob_target,vMedium,fine,tool0;
!        ConfJ\Off;
!        ConfJ\On;
        RETURN FALSE;
    ELSEIF ERRNO = ERR_OUTSIDE_REACH THEN
        RETURN FALSE;
    ENDIF
    ENDFUNC
ENDMODULE