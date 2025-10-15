MODULE Server_functions
    VAR errnum ERR_NOT_VALID_STRING := 42;
    FUNC string RobtargetToString(robtarget input_target)

        VAR string robtarget_string;
        VAR robtarget handframe;
        
        !extracting all single values
       robtarget_string := "[" +
            ValToStr(Round(input_target.trans.x)) + "," +
            ValToStr(Round(input_target.trans.y)) + "," +
            ValToStr(Round(input_target.trans.z)) + "],[" +
            ValToStr(Round(input_target.rot.q1)) + "," +
            ValToStr(Round(input_target.rot.q2)) + "," +
            ValToStr(Round(input_target.rot.q3)) + "," +
            ValToStr(Round(input_target.rot.q4)) + "]";
    
        RETURN robtarget_string;
       
       RETURN robtarget_string;
    ENDFUNC

    FUNC bool rob_coordinates(string input_string,INOUT pos rob_pos)
        
        
        VAR num start_index := 1;
        VAR num end_index := 0;

        VAR string buffer;
        VAR bool valid := FALSE;

        ! to find x
        start_index := StrFind(input_string,start_index,"[")+1;
        end_index := StrFind(input_string,start_index,",");
        ! wrong format
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_pos.x); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        ! to find y
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,",");
        ! wrong format
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_pos.y); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        ! to find z
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,"]");
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_pos.z); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        RETURN TRUE;
        
        ERROR
            IF ERRNO = ERR_NOT_VALID_STRING THEN        
                RETURN FALSE; ! should not be valid
            ENDIF
    ENDFUNC
    
FUNC bool rob_orientation(string input_string,INOUT orient rob_ori)
        VAR num start_index := 1;
        VAR num end_index := 0;

        VAR string buffer;
        VAR bool valid := FALSE;

        ! to find q1
        start_index := StrFind(input_string,start_index,"[")+1;
        end_index := StrFind(input_string,start_index,",");
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q1); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        ! to find q2
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,",");
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q2); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        ! to find q3
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,",");
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q3); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        ! to find q4
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,"]");
        IF end_index < start_index THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q4); 
        IF NOT valid THEN
            RAISE ERR_NOT_VALID_STRING;
        ENDIF
        
        RETURN TRUE;        
        
        ERROR
            IF ERRNO = ERR_NOT_VALID_STRING THEN        
                RETURN FALSE; ! Not valid
            ENDIF
    ENDFUNC
    
    
    FUNC orient NormilizeRotation(orient rot)
        
        VAR num total;
        
        total := sqrt(rot.q1*rot.q1 + rot.q2*rot.q2 +rot.q3*rot.q3 +rot.q4*rot.q4);
        
        rot.q1 := rot.q1/total;
        rot.q2 := rot.q2/total;
        rot.q3 := rot.q3/total;
        rot.q4 := rot.q4/total;
        
        rot := NOrient(rot); ! should not be needed!
        
        RETURN rot;
    ENDFUNC
ENDMODULE




