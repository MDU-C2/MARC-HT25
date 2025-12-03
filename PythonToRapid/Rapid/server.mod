MODULE server

    !==== VARIABLES ====!
    VAR socketdev server_socket;
    VAR socketdev client_socket;

    CONST num delay_time := 0.2;

    ! Process variables
    VAR string message := "";
    VAR robtarget hand_frame;
    VAR num message_index := -1;
    VAR robtarget cup_end_frame := [[0,0,0],[0,0,0,0],[1,1,0,0],[11,12.3,9E9,9E9,9E9,9E9]];
    
    ! State tracking
    VAR string current_state := "idle";

    !==== SOCKET INITIALIZATION ====!
    
    PROC server_init()
        ! Port values
        VAR string ipAddress := "127.0.0.1";
        VAR num port := 1025;

        ! Close existing sockets
        SocketClose server_socket;
        SocketClose client_socket;
        
        WaitTime(1);
        
        ! Create sockets
        SocketCreate server_socket;

        ! Bind and listen
        SocketBind server_socket, ipAddress, port;
        SocketListen server_socket;
        SocketAccept server_socket, client_socket \ClientAddress:=ipAddress;
        
        TPWrite "Client connected";
        current_state := "connected";

    ERROR
        IF ERRNO = ERR_SOCK_TIMEOUT THEN
            RETRY;
        ELSEIF ERRNO = ERR_SOCK_CLOSED THEN
            RETURN;
        ELSEIF ERRNO = ERR_SOCK_ADDR_INVALID THEN
            ipAddress := "127.0.0.1";
            RETRY;
        ENDIF
    ENDPROC

    !==== DYNAMIC MESSAGE HANDLING ====!
    
    PROC handle_message(string msg)
        ! Dynamic message dispatcher
        
        TEST msg
            
            CASE "Connection_test":
                TPWrite "[INFO] Connection test received";
                SocketSend client_socket \Str:="Connection_Confirmed";
                current_state := "confirmed";
                
            CASE "Cups_available":
                TPWrite "[INFO] Cups available - starting MovingCups";
                current_state := "processing_cups";
                MovingCups;
                ! After cups processed, send stop
                WaitTime(delay_time);
                SocketSend client_socket \Str:="Ack_stop";
                current_state := "stop";
                
            CASE "Coordinates":
                TPWrite "[INFO] Coordinates requested";
                hand_frame := CRobT(\Tool:=tGripper);
                SocketSend client_socket \Str:=RobtargetToString(hand_frame) + "_ack";
                
            CASE "Pos":
                TPWrite "[INFO] Position requested";
                hand_frame := CRobT(\Tool:=tGripper);
                SocketSend client_socket \Str:=RobPosToString(hand_frame.trans);
                
            CASE "Move":
                TPWrite "[INFO] Move command received";
                IF (MoveRob(GetRobTarget())) THEN
                    SocketSend client_socket \Str:="Ack_successful";
                ELSE
                    SocketSend client_socket \Str:="[ERROR] Can't reach position";
                ENDIF
                
            CASE "Grip":
                TPWrite "[INFO] Grip command received";
                SocketSend client_socket \Str:="Ack_wait";
                WaitUntil shared_vars.wait_flag = FALSE;
                shared_vars.flag := 3;
                shared_vars.wait_flag := TRUE;
                SocketSend client_socket \Str:="Ack_Grip done";
                
            CASE "Release":
                TPWrite "[INFO] Release command received";
                SocketSend client_socket \Str:="Ack_wait";
                WaitUntil shared_vars.wait_flag = FALSE;
                shared_vars.flag := 4;
                shared_vars.wait_flag := TRUE;
                SocketSend client_socket \Str:="Ack_Release done";
                
            CASE "Home":
                TPWrite "[INFO] Home command received";
                SocketSend client_socket \Str:="Ack_wait";
                WaitUntil shared_vars.wait_flag = FALSE;
                shared_vars.flag := 5;
                shared_vars.wait_flag := TRUE;
                SocketSend client_socket \Str:="Ack_Home done";
                
            DEFAULT:
                TPWrite "[WARN] Unknown message: " + msg;
                SocketSend client_socket \Str:="default_" + msg;
                
        ENDTEST
        
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            TPWrite "[ERROR] Socket closed during message handling";
            RETURN;
        ELSEIF ERRNO = ERR_SOCK_TIMEOUT THEN
            RETRY;
        ENDIF
    ENDPROC

    !==== MAIN COMMUNICATION LOOP ====!
    
    PROC single_client_communication()
        ! Main communication loop with dynamic message handling
        
        WHILE TRUE DO
            ! Receive message
            SocketReceive client_socket \Str:=message;
            
            ! Handle message dynamically
            handle_message(message);
            
            ! Check if we should stop
            IF current_state = "stop" THEN
                SocketClose client_socket;
                RETURN;
            ENDIF
            
            ! Send Ask_next if ready
            IF current_state = "confirmed" OR current_state = "ready" THEN
                WaitTime(delay_time);
                SocketSend client_socket \Str:="Ask_next";
            ENDIF
            
        ENDWHILE

    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            TPWrite "[ERROR] Client closed connection";
            server_init;
            RETRY;
        ELSEIF ERRNO = ERR_SOCK_TIMEOUT THEN
            SocketClose client_socket;
            RETURN;
        ENDIF
    ENDPROC

    !==== ROBOT MOVEMENT ====!
    
    FUNC bool MoveRob(robtarget target)
        WaitUntil shared_vars.wait_flag = FALSE;
        shared_vars.flag := 1;

        ! TEMPORARY CONSTANT ORIENTATION
        target.rot := [0.00274, 0.75169, 0.65950, -0.00414];
        target.trans.z := -28;
        
        IF VectMagn(target.trans) > 560 THEN
            shared_vars.flag := 0;
            RETURN FALSE;
        ENDIF

        shared_vars.target := target;
        shared_vars.wait_flag := TRUE;
        TPWrite "wait_flag:" \Bool:=shared_vars.wait_flag;
        
        WaitUntil shared_vars.wait_flag = FALSE;
        RETURN TRUE;
        
    ERROR
        IF ERRNO = ERR_ROBLIMIT THEN
            RETURN FALSE;
        ELSEIF ERRNO = ERR_OUTSIDE_REACH THEN
            RETURN FALSE;
        ENDIF
    ENDFUNC

    !==== GET ROBTARGET FROM CLIENT ====!
    
    FUNC robtarget GetRobTarget()
        VAR bool success := FALSE;
        VAR robtarget return_target;
        VAR orient temp_orient;
        
        ! Initialize with default values
        return_target := [[611.44, -10, 224.449], [0.00944177, -0.683755, 0.728027, -0.0486451], [0, -1, -2, 4], [-160.18, 9E+09, 9E+09, 9E+09, 9E+09, 9E+09]];

        ! ==== GET COORDINATE ==== !
        WaitTime(delay_time);
        SocketSend client_socket \Str:="Ask_Coordinate";
        SocketReceive client_socket \Str:=message;
        
        success := rob_coordinates(message, return_target.trans);
        
        WHILE NOT success DO
            SocketSend client_socket \Str:="[ERROR] Wrong format, try again (example [x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ask_Coordinate";
            SocketReceive client_socket \Str:=message;
            success := rob_coordinates(message, return_target.trans);
        ENDWHILE
        
        TPWrite "Received pos:" \Pos:=return_target.trans;
        SocketSend client_socket \Str:="Ack_Coordinate";
        
        ! ==== GET ORIENTATION (as vector [x,y,z]) ==== !
        WaitTime(delay_time);
        SocketSend client_socket \Str:="Ask_Orientation";
        SocketReceive client_socket \Str:=message;
        
        ! Convert vector orientation to quaternion
        success := rob_orientation_vector(message, temp_orient);
        
        WHILE NOT success DO
            SocketSend client_socket \Str:="[ERROR] Wrong format, try again (example [x,y,z])";
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ask_Orientation";
            SocketReceive client_socket \Str:=message;
            success := rob_orientation_vector(message, temp_orient);
        ENDWHILE

        return_target.rot := NormalizeRotation(temp_orient);
        
        SocketSend client_socket \Str:="Ack_Orientation";
        WaitTime(delay_time);

        RETURN return_target;
        
    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDFUNC

    !==== MOVING MULTIPLE CUPS ====!
    
    PROC MovingCups()
        VAR num amount_of_cups := 0;
        VAR bool succeeded := FALSE;
        VAR robtarget cup_start_frame;
        VAR robtarget cup_end_frame;

        ! ==== Get amount of cups ==== !
        WaitTime(delay_time);
        SocketSend client_socket \Str:="Ask_amount_of_cups";
        SocketReceive client_socket \Str:=message;
        WaitTime(delay_time);

        succeeded := StrToVal(message, amount_of_cups);

        WHILE NOT succeeded DO
            SocketSend client_socket \Str:="[ERROR] Not a number, try again";
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ask_amount_of_cups";
            WaitTime(delay_time);
            SocketReceive client_socket \Str:=message;
            succeeded := StrToVal(message, amount_of_cups);
        ENDWHILE

        SocketSend client_socket \Str:="Ack_amount_of_cups";

        ! ==== Process each cup ==== !
        WHILE (amount_of_cups > 0) DO

            ! Get cup pickup position
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ack_cup_current_position";
            cup_start_frame := GetRobTarget();
            
            ! Get cup release position
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ack_cup_end_position";
            cup_end_frame := GetRobTarget();
            
            ! Notify robot is moving
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ask_Wait";

            ! Move to pickup position
            succeeded := MoveRob(cup_start_frame);

            WHILE NOT succeeded DO
                SocketSend client_socket \Str:="[ERROR] Can't reach pickup frame, try again";
                WaitTime(delay_time);
                SocketSend client_socket \Str:="Ack_cup_current_position";
                cup_start_frame := GetRobTarget();
                succeeded := MoveRob(cup_start_frame);
            ENDWHILE

            ! TODO: Grip cup here

            ! Move to release position
            succeeded := MoveRob(cup_end_frame);

            WHILE NOT succeeded DO
                SocketSend client_socket \Str:="[ERROR] Can't reach release frame, try again";
                WaitTime(delay_time);
                SocketSend client_socket \Str:="Ack_cup_end_position";
                cup_end_frame := GetRobTarget();
                succeeded := MoveRob(cup_end_frame);
            ENDWHILE

            ! TODO: Release cup here

            ! Movement complete - send Ask_next
            WaitTime(delay_time);
            SocketSend client_socket \Str:="Ask_next";
            
            ! Ask for more cups
            SocketSend client_socket \Str:="Ask_amount_of_cups";
            WaitTime(delay_time);
            
            ! Wait for response (y/n)
            amount_of_cups := -1;
            WHILE amount_of_cups = -1 DO
                WaitTime(delay_time);
                SocketReceive client_socket \Str:=message;
                
                IF message = "1" THEN
                    amount_of_cups := 1;
                ELSEIF message = "0" THEN
                    amount_of_cups := 0;
                ELSE
                    ! Try to parse as number
                    succeeded := StrToVal(message, amount_of_cups);
                    IF NOT succeeded THEN
                        SocketSend client_socket \Str:="[ERROR] Invalid amount, try again";
                        SocketSend client_socket \Str:="Ask_amount_of_cups";
                        amount_of_cups := -1;
                    ENDIF
                ENDIF
            ENDWHILE

        ENDWHILE

    ERROR
        IF ERRNO = ERR_SOCK_CLOSED THEN
            SocketClose client_socket;
        ENDIF
    ENDPROC

    !==== HELPER FUNCTIONS - PARSING ====!
    
    FUNC bool parse_orientation_vector(string coord_str, INOUT pos result)
        ! Parse coordinate string "[x,y,z]" to pos
        ! Example: "[400.5,-150.2,-50]" ? pos [400.5, -150.2, -50]
        
        VAR num start_pos;
        VAR num comma1_pos;
        VAR num comma2_pos;
        VAR num end_pos;
        VAR string x_str;
        VAR string y_str;
        VAR string z_str;
        VAR bool success;
        
        ! Find positions of brackets and commas
        start_pos := StrFind(coord_str, 1, "[");
        comma1_pos := StrFind(coord_str, 1, ",");
        comma2_pos := StrFind(coord_str, comma1_pos + 1, ",");
        end_pos := StrFind(coord_str, 1, "]");
        
        ! Check if format is correct
        IF start_pos < 1 OR comma1_pos < 1 OR comma2_pos < 1 OR end_pos < 1 THEN
            RETURN FALSE;
        ENDIF
        
        ! Extract substrings
        x_str := StrPart(coord_str, start_pos + 1, comma1_pos - start_pos - 1);
        y_str := StrPart(coord_str, comma1_pos + 1, comma2_pos - comma1_pos - 1);
        z_str := StrPart(coord_str, comma2_pos + 1, end_pos - comma2_pos - 1);
        
        ! Convert to numbers
        success := StrToVal(x_str, result.x);
        IF NOT success THEN RETURN FALSE; ENDIF
        
        success := StrToVal(y_str, result.y);
        IF NOT success THEN RETURN FALSE; ENDIF
        
        success := StrToVal(z_str, result.z);
        IF NOT success THEN RETURN FALSE; ENDIF
        
        RETURN TRUE;
        
    ERROR
        RETURN FALSE;
    ENDFUNC
    
    FUNC bool rob_orientation_vector(string orient_str, INOUT orient result)
        ! Parse orientation vector string "[x,y,z]" and convert to quaternion
        ! Example: "[0,0,1]" ? upright orientation
        
        VAR num start_pos;
        VAR num comma1_pos;
        VAR num comma2_pos;
        VAR num end_pos;
        VAR string x_str;
        VAR string y_str;
        VAR string z_str;
        VAR bool success;
        VAR num vx;
        VAR num vy;
        VAR num vz;
        
        ! Find positions of brackets and commas
        start_pos := StrFind(orient_str, 1, "[");
        comma1_pos := StrFind(orient_str, 1, ",");
        comma2_pos := StrFind(orient_str, comma1_pos + 1, ",");
        end_pos := StrFind(orient_str, 1, "]");
        
        ! Check if format is correct
        IF start_pos < 1 OR comma1_pos < 1 OR comma2_pos < 1 OR end_pos < 1 THEN
            RETURN FALSE;
        ENDIF
        
        ! Extract substrings
        x_str := StrPart(orient_str, start_pos + 1, comma1_pos - start_pos - 1);
        y_str := StrPart(orient_str, comma1_pos + 1, comma2_pos - comma1_pos - 1);
        z_str := StrPart(orient_str, comma2_pos + 1, end_pos - comma2_pos - 1);
        
        ! Convert to numbers
        success := StrToVal(x_str, vx);
        IF NOT success THEN RETURN FALSE; ENDIF
        
        success := StrToVal(y_str, vy);
        IF NOT success THEN RETURN FALSE; ENDIF
        
        success := StrToVal(z_str, vz);
        IF NOT success THEN RETURN FALSE; ENDIF
        
        ! Convert vector to quaternion
        ! This is a simplified conversion - you may need to adjust based on your coordinate system
        ! For now, use default orientation and adjust based on vector
        
        ! Default downward orientation (gripper pointing down)
        result := [0.00274, 0.75169, 0.65950, -0.00414];
        
        ! TODO: Implement proper vector to quaternion conversion based on your system
        ! For example:
        ! - [0,0,1] = upright
        ! - [0,0,-1] = upside down
        ! - [1,0,0] = front
        ! - [-1,0,0] = back
        ! etc.
        
        RETURN TRUE;
        
    ERROR
        RETURN FALSE;
    ENDFUNC
    
    FUNC orient NormalizeRotation(orient input_orient)
        ! Normalize quaternion orientation
        VAR num magnitude;
        VAR orient result;
        
        ! Calculate magnitude
        magnitude := Sqrt(input_orient.q1 * input_orient.q1 + 
                         input_orient.q2 * input_orient.q2 + 
                         input_orient.q3 * input_orient.q3 + 
                         input_orient.q4 * input_orient.q4);
        
        ! Normalize
        IF magnitude > 0.001 THEN
            result.q1 := input_orient.q1 / magnitude;
            result.q2 := input_orient.q2 / magnitude;
            result.q3 := input_orient.q3 / magnitude;
            result.q4 := input_orient.q4 / magnitude;
        ELSE
            ! If magnitude too small, return default orientation
            result := [1, 0, 0, 0];
        ENDIF
        
        RETURN result;
    ENDFUNC

    !==== MAIN ENTRY POINT ====! 

ENDMODULE