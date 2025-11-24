MODULE processes

    VAR egmident egmID1;
    VAR egmstate egmSt1;

    VAR pose corr_frame_offs:=[[0,0,0],[1,0,0,0]];

    !    ! limits for cartesian convergence:    +-1 mm
    CONST egm_minmax egm_minmax_lin1 := [-1,1];
    !    ! limits for orientation convergence:  +-2 degrees
    CONST egm_minmax egm_minmax_rot1 := [-2,2];
    !    ! limits for joint convergence:        +-0.5 degrees
    CONST egm_minmax egm_minmax_joint:=[-0.5,0.5];


    PROC EGMPoseExample()
        
        setupEGMPose(40);

        EGMRunPose  egmID1, 
                    EGM_STOP_HOLD 
                    \x \y \z \rx \ry \rz 
                    \CondTime:=10
                    \RampInTime:=0.05;

        egmSt1 := EGMGetState(egmID1);

        ! (Debugging) Checks if robot is listening for external commands.
        IF egmSt1 = EGM_STATE_CONNECTED THEN
            TPWrite "EGM State: Waiting for movement request.";
        ENDIF

        ! (Debugging) Checks if the robot received an external command and is moving.
        IF egmSt1 = EGM_STATE_RUNNING THEN
            TPWrite "EGM State: Movement request received. Robot is moving.";
        ENDIF
        ! Reset EGM communication.
        IF egmSt1 <= EGM_STATE_CONNECTED THEN
            EGMReset egmID1;
        ENDIF
        
        EGMReset egmID1;
        ERROR
        IF ERRNO = ERR_UDPUC_COMM THEN
            setupEGMPose(40);
            RETRY;
        ENDIF
    ENDPROC

    PROC EGMJointExample()

        setupEGMJoint;

        EGMRunJoint egmID1, 
                    EGM_STOP_HOLD
                    \J1 \J2 \J3 \J4 \J5 \J6 \J7
                    \CondTime:=60
                    \RampInTime:=0.05;

        egmSt1 := EGMGetState(egmID1);


        ! (Debugging) Checks if robot is listening for external commands.
        IF egmSt1 = EGM_STATE_CONNECTED THEN
            TPWrite "EGM State: Waiting for movement request.";
        ENDIF

        ! (Debugging) Checks if the robot received an external command and is moving.
        IF egmSt1 = EGM_STATE_RUNNING THEN
            TPWrite "EGM State: Movement request received. Robot is moving.";
        ENDIF
        ! Reset EGM communication.
        IF egmSt1 <= EGM_STATE_CONNECTED THEN
            EGMReset egmID1;
        ENDIF
        
        EGMReset egmID1;
        ERROR
        IF ERRNO = ERR_UDPUC_COMM THEN
            setupEGMJoint;
            RETRY;
        ENDIF
    ENDPROC
    
    PROC EGMfollowCup()
        
        VAR robtarget starting_target := [[40,200,190],[0.0848672,-0.454517,-0.883453,0.0756562],[-1,-3,0,4],[158.907,9E+9,9E+9,9E+9,9E+9,9E+9]];

        MoveL starting_target,v1000,fine,tool0\WObj:=wobj0;
        
        setupEGMPose(40);
        EGMRunPose  egmID1, 
                    EGM_STOP_HOLD 
                    \x \y \z \rx \ry \rz 
                    \CondTime:=10
                    \RampInTime:=0.05;

        egmSt1 := EGMGetState(egmID1);

    ENDPROC
    PROC setupEGMJoint()
        EGMReset egmID1;
        EGMGetId egmID1;

        egmSt1 := EGMGetState(egmID1);

        TPWrite "EGM State: ", \Num:=egmSt1;
        
        IF egmSt1 <= EGM_STATE_CONNECTED THEN
            EGMSetupUC  ROB_L,
                        egmID1,
                        "EGMsensor:",
                        "UCdevice"
                        \joint 
                        \CommTimeout:=60;

        ENDIF
        EGMActJoint egmID1\Tool:=tGripper
                    \WObj:=wobj0
                    \J1:=egm_minmax_joint
                    \J2:=egm_minmax_joint
                    \J3:=egm_minmax_joint
                    \J4:=egm_minmax_joint
                    \J5:=egm_minmax_joint
                    \J6:=egm_minmax_joint
                    \J7:=egm_minmax_joint
                    \MaxSpeedDeviation:=20;

    ENDPROC
    
    PROC setupEGMPose(num max_speed_div)
        EGMReset egmID1;
        EGMGetId egmID1;
    
        egmSt1 := EGMGetState(egmID1);
    
        TPWrite "EGM State: ", \Num:=egmSt1;
        
        IF egmSt1 <= EGM_STATE_CONNECTED THEN
    
            EGMSetupUC  ROB_L, 
                        egmID1,
                        "EGMsensor:", 
                        "UCdevice"
                        \pose 
                        \CommTimeout:=60;
        ENDIF 

        EGMActPose  egmID1\Tool:=tGripper
                    \WObj:=wobj0,
                    corr_frame_offs,
                    EGM_FRAME_WORLD,
                    tool0.tframe,
                    EGM_FRAME_WORLD,
                    \x:=egm_minmax_lin1 
                    \y:=egm_minmax_lin1 
                    \z:=egm_minmax_lin1 
                    \rx:=egm_minmax_rot1 
                    \ry:=egm_minmax_rot1 
                    \rz:=egm_minmax_rot1\MaxSpeeddeviation:=max_speed_div;
    ENDPROC
    
ENDMODULE