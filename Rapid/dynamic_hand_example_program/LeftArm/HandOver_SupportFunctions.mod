MODULE HandOver_SupportFunctions
    
    
    ! get wanted orientation
    FUNC orient MugHandOverOrient()

        VAR orient target;
        VAR num e1{3};
        VAR num e2{3};
        VAR num e3{3};
        
        
!            PosToNumArr [1,0,0],e1;
!            PosToNumArr [0,0,1],e2;
!            PosToNumArr [0,-1,0],e3;
        RETURN  NOrient([0,0,.707,-.707]); 
       
        
!        RETURN ChiaveriniSiciliano(e1,e2,e3);!now we have a queternium from a normal vector!
    ENDFUNC
    
    ! hand over sequence 
        ! move left hand to position
        ! move right to position + offset
        ! open right hand
        ! move right hand closer
        ! grip right -> release left
        ! move to designated areas
    PROC HandOverSequence(num mug_offset)
        
        VAR robtarget target;
        
        ConfJ\Off;
    
        target := CRobT(\Tool:=Gripper);
        target.trans := multi_move.hand_over_pose.position;
        target.rot := MugHandOverOrient();
        
        moveJ target,movespeed,z50,Gripper;
!            MovementProc target,movespeed,z50,tGripper;

        ! wait untill right arm is in right poss
        multi_move.right_in_process := TRUE;
        multi_move.left_in_process := FALSE;
        WaitUntil multi_move.left_in_process = TRUE;
        
        !open gripper
        
        target.trans := multi_move.hand_over_pose.position + [0,1,0]*mug_offset*2;
        moveJ target,movespeed,z50,Gripper;
!            MovementProc home_target,movespeed,z50,tGripper;
        
        ! tell right arm that we are not in the way
        multi_move.right_in_process := TRUE;
    ENDPROC
        
ENDMODULE