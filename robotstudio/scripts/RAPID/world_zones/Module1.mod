MODULE Module1
	CONST robtarget UNDER_GROUND:=[[289.86,-67.74,-110.14],[0.182077,-0.928103,-0.041173,-0.322146],[1,1,0,4],[166.74,9E+9,9E+9,9E+9,9E+9,9E+9]];
	CONST robtarget ABOVE_GROUND:=[[289.86,0,200.14],[0.182077,-0.928103,-0.041173,-0.322146],[1,1,0,4],[166.74,9E+9,9E+9,9E+9,9E+9,9E+9]];

    PROC main()
        !go to "valid" position
        MoveL ABOVE_GROUND, v100, z100, tool0;
        
       !move trough the ground
        WaitTime(2);
        MoveL UNDER_GROUND, v100, z100, tool0;
        WaitTime(1);
        
        !go to "valid" position
        MoveL ABOVE_GROUND, v100, z100, tool0;
        
    ENDPROC
    
ENDMODULE