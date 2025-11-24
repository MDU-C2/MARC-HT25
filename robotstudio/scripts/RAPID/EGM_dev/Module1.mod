
    MODULE Module1   
!    ***********************************************************
    
!     Module:  Module1
    
!     Description:
    
!     Author: fjn20007
    
!     Version: 1.0
    
!    ***********************************************************

    CONST robtarget home_target := [[609,0,136],[0.56458,0.45107,0.48932,0.48820],[-1,-1,0,4],[-177.987,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    PROC main()
        VAR robtarget cur_target;

        EGMReset egmID1;
!        cur_target := CRobT(\Tool:=tGripper);
!        MoveL cur_target,v1000,fine,tool0\WObj:=wobj0;

!        EGMPoseExample;
!        EGMJointExample;
        EGMfollowCup;
    ENDPROC
ENDMODULE
