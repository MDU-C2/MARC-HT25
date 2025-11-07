MODULE GiveCup
    
    ! cup info
    
    ! interchange cup
        ! call both arms
        ! make there orientation "same"/inverse
        ! release right, move closer, close right, release left
        
    ! fetch cup (semi optimal gripp strat)
        ! Find Ortogonal plane compared to cup
        ! Proj grip onto plane
        ! should be closest grip strat
    PROC fetchCup(pos CupNormal)
        
        ! v1 and v2 built the plance ortogonal to CupNormal
        VAR pos v1;
        VAR pos v2;
        VAR pos hand;
        VAR pos buffer;
        
        VAR robtarget current;
        
        ! Find Ortogonal plane compared to cup
        IF(CupNormal.x <= CupNormal.y AND CupNormal.x <= CupNormal.z) THEN ! x is smallest value
            v1 := [1,0,0];
        ELSEIF(CupNormal.y <= CupNormal.x AND CupNormal.y <= CupNormal.z) THEN ! y is smallest value
            v1 := [0,1,0];
        ELSE
            v1 := [0,0,1];
        ENDIF
        
        !cross product to find last vector of plane
        v2.x := CupNormal.y*v1.z - CupNormal.z*v1.y;
        v2.y := - CupNormal.x*v1.z + CupNormal.z*v1.x;
        v2.z := CupNormal.x*v1.y - CupNormal.y*v1.x;
        
        ! get current hand orientation
        current := CRobT(\Tool:=tGripper);
        hand.x := EulerZYX(\X, current.rot);
        hand.y := EulerZYX(\Y, current.rot);
        hand.z := EulerZYX(\Z, current.rot);
        
        !project hand on ortogonal mugg plane
        buffer := hand;
        buffer := Proj(hand,v1);
        hand := Proj(hand,v2);
        
        hand := hand + buffer;
        
        !hand is not in ortogonal to mug frame, but still as close as possible
        current.rot := OrientZYX(hand.z,hand.y,hand.x);
        
        !move to targett
        moveJ current,movespeed,z50,tGripper;
    ENDPROC
    
    ! project v1 on v2
    FUNC pos Proj(pos v1, pos v2)
        VAR num lenght;
        VAR pos proj_v1;
        lenght := (v2.x*v2.x + v2.y*v2.y + v2.z*v2.z);
        proj_v1 := (dotProd(v1,v2)/(lenght*lenght))*v2;
        RETURN proj_v1;
    ENDFUNC
    
ENDMODULE