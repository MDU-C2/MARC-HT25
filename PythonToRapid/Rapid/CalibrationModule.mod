MODULE CalibrationModule
    VAR socketdev calib_client_socket;
    VAR socketdev calib_server_socket;
    CONST num CALIB_PORT := 1025;
    VAR robtarget calibTarget;
    VAR bool calibRunning := FALSE;
    
    PROC ServerCalibration()
        VAR string received_msg;
        VAR pos target_pos;
        
        SocketCreate calib_server_socket;
        SocketBind calib_server_socket, "127.0.0.1", CALIB_PORT;
        SocketListen calib_server_socket;
        
        TPWrite "Calibration Server Ready";
        
        WHILE TRUE DO
            SocketAccept calib_server_socket, calib_client_socket;
            TPWrite "Client Connected";
            
            calibRunning := TRUE;
            
            WHILE calibRunning DO
                SocketReceive calib_client_socket \Str:=received_msg \Time:=WAIT_MAX;
                TPWrite "RX: " + received_msg;
                
                IF received_msg = "START_CALIB" THEN
                    SocketSend calib_client_socket \Str:="READY";
                    TPWrite "Calibration started";
                    
                ELSEIF StrFind(received_msg, 1, "MOVE:") = 1 THEN
                    target_pos := ParsePosition(StrPart(received_msg, 6, StrLen(received_msg)-5));
                    
                    SocketSend calib_client_socket \Str:="MOVING";
                    TPWrite "Moving to position";
                    WaitTime 0.1;
                    
                    calibTarget := CRobT(\Tool:=tool0);
                    calibTarget.trans := target_pos;
                    MoveJ calibTarget, v50, fine, tool0;
                    
                    WaitTime 0.5;
                    SocketSend calib_client_socket \Str:="AT_POSITION";
                    TPWrite "Position reached";
                    
                ELSEIF received_msg = "END_CALIB" THEN
                    SocketSend calib_client_socket \Str:="DONE";
                    TPWrite "Calibration ended";
                    calibRunning := FALSE;
                    
                ELSE
                    TPWrite "Unknown command: " + received_msg;
                ENDIF
            ENDWHILE
            
            SocketClose calib_client_socket;
            TPWrite "Client disconnected";
        ENDWHILE
        
    ERROR
        IF ERRNO = ERR_SOCK_TIMEOUT THEN
            TPWrite "Socket timeout - retrying";
            RETRY;
        ELSEIF ERRNO = ERR_SOCK_CLOSED THEN
            TPWrite "Socket closed";
            RETURN;
        ELSE
            TPWrite "Error: " + NumToStr(ERRNO, 0);
            STOP;
        ENDIF
    ENDPROC
    
    FUNC pos ParsePosition(string pos_str)
        VAR pos result;
        VAR string temp_str;
        VAR num start_pos;
        VAR num end_pos;
        VAR bool ok;
        
        IF StrFind(pos_str, 1, "[") = 0 THEN
            TPWrite "ERROR: Invalid position format: " + pos_str;
            result := [0, 0, 0];
            RETURN result;
        ENDIF
        
        temp_str := StrPart(pos_str, 2, StrLen(pos_str) - 2);
        
        end_pos := StrFind(temp_str, 1, ",");
        IF end_pos = 0 THEN
            TPWrite "ERROR: Cannot parse X";
            result := [0, 0, 0];
            RETURN result;
        ENDIF
        ok := StrToVal(StrPart(temp_str, 1, end_pos - 1), result.x);
        
        start_pos := end_pos + 1;
        end_pos := StrFind(temp_str, start_pos, ",");
        IF end_pos = 0 THEN
            TPWrite "ERROR: Cannot parse Y";
            result := [0, 0, 0];
            RETURN result;
        ENDIF
        ok := StrToVal(StrPart(temp_str, start_pos, end_pos - start_pos), result.y);
        
        start_pos := end_pos + 1;
        ok := StrToVal(StrPart(temp_str, start_pos, StrLen(temp_str) - start_pos + 1), result.z);
        
        RETURN result;
        
    ERROR
        TPWrite "ERROR parsing position: " + pos_str;
        result := [0, 0, 0];
        RETURN result;
    ENDFUNC
    
ENDMODULE