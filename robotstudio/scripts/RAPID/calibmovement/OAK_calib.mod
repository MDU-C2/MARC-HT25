MODULE OAK_calib

    !   Used for storing robtargets and joint values specifically for OAK camera calibration
    PROC calibStore()
        VAR num arr_nr;
        VAR num user_input;
        TPErase;
        TPWrite "Setting calibration positions";
        TPReadNum user_input,"Enter position # (correspinging to picture #) or 0: Exit.";
        IF user_input = 0 THEN
            
        ELSE
            arr_nr := user_input;
            calib_robtargets{arr_nr}:=CRobT(\Tool:=tGripper);
            calib_jointtargets{arr_nr}:= CJointT();
            TPWrite "Position stored!";
        ENDIF


    ENDPROC
    
    !   Used to move to saved positions related to OAK camera calibration
    PROC calibMove()
        VAR num arr_pos :=1 ;
        VAR num user_input;
        VAR bool user_continue := TRUE;
        
        TPErase;
!        TPReadnum arr_pos, "Please enter pos #";
!!        MoveY testtargets{arr_pos},vSlow,fine,tgripper;
!        MoveAbsJ testjointtargets{arr_pos}, v100, fine, tool0;
        
        WHILE user_continue DO
            TPErase;
            TPWrite "Current postition #:"\num:=arr_pos;
            TPWrite "1: Next pos.";
            TPWrite "2: Choose pos.";
            TPWrite "3: Store pos.";
            TPWrite "4: Save pos.";
            TPWrite "5: Load pos";
            TPWrite "0: Exit.";
            TPReadnum user_input, "";
            TEST user_input
            CASE 1: !next position
                arr_pos := arr_pos;
                arr_pos := arr_pos MOD calib_array_size;
                arr_pos := arr_pos + 1;
!                MoveY testtargets{arr_pos},vSlow,fine,tgripper;
                MoveAbsJ calib_jointtargets{arr_pos}, v100, fine, tool0;
!                MoveJ calib_robtargets{arr_pos},vSlow,fine,tgripper;
            CASE 2: !Custom pos
                TPErase;
                TPWrite "Current position #"\num:=arr_pos;
                TPReadnum arr_pos, "Please enter pos #";
!                MoveY testtargets{arr_pos},vSlow,fine,tgripper;
                calib_jointtargets{arr_pos} := CalcJointT(calib_robtargets{arr_pos},tGripper);
                MoveAbsJ calib_jointtargets{arr_pos}, v100, fine, tool0;
!                MoveJ calib_robtargets{arr_pos},vSlow,fine,tgripper;
            CASE 3: !Store position
                calibStore;
            CASE 4: !Save positions
                saveCalibTargets;
            CASE 5: !Load positions
                loadCalibTargets;
            CASE 0: !Exit
                user_continue := FALSE;
            ENDTEST
        ENDWHILE
        
    ENDPROC
    
    PROC saveCalibTargets()

        VAR iodev logfile;
        VAR num i:=1;

        Open "Home:" \File:= "LOGFILE1.txt", logfile \Write;
        FOR i FROM 1 TO calib_array_size DO
            Write logfile, "",\Pos:= calib_robtargets{i}.trans;
            Write logfile, "",\Orient:= calib_robtargets{i}.rot;
        ENDFOR
        Close logfile;
    ENDPROC

    PROC loadCalibTargets()
        VAR bool ok;
        VAR iodev logfile;
        VAR num i:=1;
        VAR pos temp_pos;
        VAR orient temp_orient;
        VAR num bin_data;
        VAR string temp_string;
        TPErase;
        Open "Home:" \File:="LOGFILE1.txt", logfile \Read;

        FOR i FROM 1 TO calib_array_size DO
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_pos);
            calib_robtargets{i}.trans := temp_pos;
            
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_orient);
            calib_robtargets{i}.rot := temp_orient;
            
!            calib_jointtargets{i} := CalcJointT(calib_robtargets{i},tGripper);
        ENDFOR
        Close logfile;
    ENDPROC
    
ENDMODULE