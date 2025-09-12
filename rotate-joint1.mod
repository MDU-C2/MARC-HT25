MODULE RotateJoint1

VAR robtarget currentPos;
VAR jointtarget currentJoints;

PROC main()
    ! Get current robot position in joint coordinates
    currentJoints := CJointT();

    ! Slightly increase the first joint (in degrees)
    currentJoints.robax.rax_1 := currentJoints.robax.rax_1 + 5;
    ! Move to the new joint position
    MoveAbsJ currentJoints, v100, fine, tool0;

    currentJoints.r

ENDPROC

ENDMODULE