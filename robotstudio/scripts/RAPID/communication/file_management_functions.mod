MODULE file_management_functions
    PROC loadCalibTargets(string file_name, INOUT robtarget robtarget_array{*}, NUM array_size)
        VAR bool ok;
        VAR iodev logfile;
        VAR num i:=1;
        VAR pos temp_pos;
        VAR orient temp_orient;
        VAR confdata temp_confdata;
        VAR num temp_extjoint;
        VAR num bin_data;
        VAR string temp_string;
        TPErase;
        Open "Home:" \File:=file_name, logfile \Read;

        FOR i FROM 1 TO array_size DO
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_pos);
            robtarget_array{i}.trans := temp_pos;
            
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_orient);
            robtarget_array{i}.rot := temp_orient;
            
            
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_confdata);
            robtarget_array{i}.robconf := temp_confdata;
            
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_extjoint);
            robtarget_array{i}.extax := [9E+09,9E+09,9E+09,9E+09,9E+09,9E+09];
            robtarget_array{i}.extax.eax_a := temp_extjoint;
            
            
        ENDFOR
        Close logfile;
    ENDPROC
    PROC saveCalibTargets(string file_name, robtarget robtarget_array{*}, num array_size)

        VAR iodev logfile;
        VAR num i:=1;

        Open "Home:" \File:= file_name, logfile \Write;
        FOR i FROM 1 TO array_size DO
            Write logfile, "",\Pos:= robtarget_array{i}.trans\NoNewLine;
            Write logfile, ",",\Orient:= robtarget_array{i}.rot\NoNewLine;
            Write logfile, ",[",\Num:=robtarget_array{i}.robconf.cf1\NoNewLine;
            Write logfile, ",",\Num:=robtarget_array{i}.robconf.cf4\NoNewLine;
            Write logfile, ",",\Num:=robtarget_array{i}.robconf.cf6\NoNewLine;
            Write logfile, ",",\Num:=robtarget_array{i}.robconf.cfx\NoNewLine;
            Write logfile, "],[",\Num:=robtarget_array{i}.extax.eax_a\NoNewLine;
            Write logfile, "]";
            
        ENDFOR
        Close logfile;
    ENDPROC

ENDMODULE