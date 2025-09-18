MODULE rotate_joint_r


PROC main()
VAR robtarget currentPos;
VAR jointtarget currentJoints;
CONST robtarget home:=[[385.20,290.61,225.75],[0.146381,-0.613708,0.75069,-0.195958],[-1,2,-2,4],[-169.424,9E+9,9E+9,9E+9,9E+9,9E+9]];
    ! Get current robot position in joint coordinates
    currentJoints := CJointT();

    ! Slightly increase the first joint (in degrees)
    !currentJoints.robax.rax_1 := currentJoints.robax.rax_1 - 5;
    ! Move to the new joint position
    !MoveAbsJ currentJoints, v100, fine, tool0;
    !currentJoints.robax.rax_1 := currentJoints.robax.rax_1 - 5;
    !MoveAbsJ currentJoints, v2000, fine, tool0;


ENDPROC

ENDMODULE