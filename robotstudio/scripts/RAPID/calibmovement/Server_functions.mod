MODULE Server_functions
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

    FUNC pos rob_coordinates(string input_string)
        VAR num start_index := 1;
        VAR num end_index := 0;

        VAR string buffer;
        VAR pos rob_pos;
        VAR bool valid := FALSE;

        ! to find x
        start_index := StrFind(input_string,start_index,"[")+1;
        end_index := StrFind(input_string,start_index,",");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_pos.x); 
        
        ! to find y
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,",");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_pos.y); 

        ! to find z
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,"]");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_pos.z); 

        RETURN rob_pos;
    ENDFUNC
FUNC orient rob_orientation(string input_string)
        VAR num start_index := 1;
        VAR num end_index := 0;

        VAR string buffer;
        VAR orient rob_ori;
        VAR bool valid := FALSE;

        ! to find q1
        start_index := StrFind(input_string,start_index,"[")+1;
        end_index := StrFind(input_string,start_index,",");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q1); 

        ! to find q2
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,",");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q2); 

        ! to find q3
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,",");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q3); 

        ! to find q4
        start_index := end_index+1;
        end_index := StrFind(input_string,start_index,"]");

        buffer := StrPart(input_string,start_index,end_index-start_index);
        valid := StrToVal(buffer,rob_ori.q4); 

        RETURN rob_ori;
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