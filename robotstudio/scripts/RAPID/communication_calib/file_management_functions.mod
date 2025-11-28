MODULE file_management_functions
    PROC loadCalibTargets(string file_name)
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
            
            
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_confdata);
            calib_robtargets{i}.robconf := temp_confdata;
            
            !reset values
            bin_data := 0;
            temp_string := "";
            
            WHILE ByteToStr(bin_data\char) <> "]" DO
                bin_data := ReadBin(logfile);
                temp_string := temp_string + ByteToStr(bin_data\Char);
            ENDWHILE
            
            bin_data := ReadBin(logfile);
            ok := StrToVal(temp_string,temp_extjoint);
            calib_robtargets{i}.extax.eax_a := temp_extjoint;
            TPWrite ""\Num:=temp_extjoint;
            
        ENDFOR
        Close logfile;
    ENDPROC
ENDMODULE