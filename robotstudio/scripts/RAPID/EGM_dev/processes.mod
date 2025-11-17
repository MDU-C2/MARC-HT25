MODULE processes

    VAR egmident egmID1;
    VAR egmstate egmSt1;

    VAR pose corr_frame_offs:=[[0,0,0],[1,0,0,0]];

    
!    ! limits for cartesian convergence: +-1 mm
!    CONST egm_minmax egm_minmax_lin1:=[-1,1];

!    ! limits for orientation convergence: +-2 degrees
!    CONST egm_minmax egm_minmax_rot1:=[-2,2];
    
    CONST egm_minmax egm_minmax_lin1 := [-1,1];
    CONST egm_minmax egm_minmax_rot1 := [-2,2];


    PROC dynamic_onetarget()
        setup_EGM;
        egmSt1 := EGMGetState(egmID1);
        IF egmSt1 = EGM_STATE_CONNECTED THEN
            TPWrite "EGM State: Waiting for movement request.";
        ENDIF
        EGMRunPose egmID1, EGM_STOP_HOLD \x \y \z \rx \ry \rz \CondTime:=1\RampInTime:=0;
!        WaitDI custom_DI_0,high;

        egmSt1 := EGMGetState(egmID1);

!        IF egmSt1 = EGM_STATE_CONNECTED THEN
!            TPWRITE "Reset EGM instance egmID1";
!            EGMReset egmID1;
!        ENDIF
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


        ERROR
        IF ERRNO = ERR_UDPUC_COMM THEN
            setup_EGM;
            RETRY;
        ENDIF
    ENDPROC


    PROC setup_EGM()
        EGMReset egmID1;
        EGMGetId egmID1;

        egmSt1 := EGMGetState(egmID1);

        TPWrite "EGM State: ", \Num:=egmSt1;

        IF egmSt1 <= EGM_STATE_CONNECTED THEN
            EGMSetupUC ROB_L, egmID1, "EGMsensor:", "UCdevice"\pose;
            !EGMConfig egmCfg, \Pose, \CondTime:=5, \CommTimeout:=10;
        ENDIF

        EGMActPose  egmID1\Tool:=tGripper,
                    corr_frame_offs,
                    EGM_FRAME_BASE,
                    tGripper.tframe,
                    EGM_FRAME_BASE,
                    \x:=egm_minmax_lin1 
                    \y:=egm_minmax_lin1 
                    \z:=egm_minmax_lin1 
                    \rx:=egm_minmax_rot1 
                    \ry:=egm_minmax_rot1 
                    \rz:=egm_minmax_rot1;
    ENDPROC
ENDMODULE