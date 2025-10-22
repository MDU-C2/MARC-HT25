MODULE Processes
    
    !Take hand position input from Flex Pendant.
    PROC TPgetTarget()

        TPReadNum requested_target.trans.x,"enter x-value (160 - 500):";
        TPReadNum requested_target.trans.y,"enter y-value (-200 - 300):";
        TPReadNum requested_target.trans.z,"enter z-value (0 - 700):";

    ENDPROC
    
    !Print current tool position & orientation to the FlexPendant
    PROC printCRobT()
        VAR robtarget target;
        target:=CRobT(\Tool:=tGripper);
        TPWrite "Position:"\Pos:=target.trans;
        TPWrite "Orientation:"\Orient:=target.rot;
    ENDPROC
ENDMODULE