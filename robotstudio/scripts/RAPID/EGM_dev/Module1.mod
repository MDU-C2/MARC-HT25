
    MODULE Module1   
!    ***********************************************************
    
!     Module:  Module1
    
!     Description:
!       Main module for arm movement which works together with the communication module.
    
!     Author: fjn20007
    
!     Version: 1.0
    
!    ***********************************************************

    CONST robtarget home_target := [[609,13,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    PROC main()
        CONST robtarget cup_target := [[499.548,-110.253,-46.3938],[0.0565402,0.114235,0.990146,-0.0580089],[-2,-3,-1,4],[-177.807,9E+09,9E+09,9E+09,9E+09,9E+09]];
        VAR robtarget cur_target;
        ConfJ\off;
        cur_target := CRobT(\Tool:=tGripper);
        
!        MoveJ Offs(cur_target,0,20,0),v1000,fine,tGripper;
        EGMReset egmID1;
        MoveL cur_target,v1000,fine,tool0\WObj:=wobj0;
!        moveToHomeTarget;
        dynamic_onetarget;
    ENDPROC
ENDMODULE
