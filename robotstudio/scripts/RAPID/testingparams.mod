MODULE testingparams(SYSMODULE)
    CONST num calib_array_size := 40;
    PERS jointtarget testjointtargets{calib_array_size};
    PERS robtarget testtargets{calib_array_size};
ENDMODULE