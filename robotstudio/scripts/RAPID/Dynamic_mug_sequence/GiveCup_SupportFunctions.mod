MODULE GiveCup_SupportFunctions
    
   
   !!! ================== SUPPORT FUNCTIONS =========================== !!!
   
   !this function will align the y axes to the normal axes
   FUNC orient NormalToOrientation(pos normal)
       
       VAR pos e{3}; ! base frame vectors
       ! to make it consistant with documentation
       VAR num x{3};
       VAR num y{3};
       VAR num z{3};
       VAR num buffer{3};
       VAR num Matrix{3,3};
       VAR num R{3,3};
       VAR orient q;
       
       Normilize normal;
       
       ! span the R3 Space
       SpanPlaneFromNormal normal,e;
      
       ! make the Span ortogonal to get proporties of Rotation matrix
       OrtogonalMatrix3x3 e;
       
       
       ! to make equations more consistant with documentation
       PosToNumArr e{1},x;
       PosToNumArr e{2},y;
       PosToNumArr e{3},z;
  
       
    ! ===== Not working correctly version 
        !NOTE: Here we declare that the Yaxes will align with the orientation
        ! rotate pi/2 around z axes to get y to align with normal
!!        R := [[0,-1,0],[1,0,0],[0,0,1]];
!        R := [[1,0,0],[0,1,0],[0,0,1]];
!        MatrixMult3x3 Matrix,[x,y,z],R;
        
!   ! to make equations more consistant with documentation
!    x := [Matrix{1,1},Matrix{1,2},Matrix{1,3}];
!    y := [Matrix{2,1},Matrix{2,2},Matrix{2,3}];
!    z := [Matrix{3,1},Matrix{3,2},Matrix{3,3}];

    ! ===== uggly and hard coded version of what is above
    buffer := x;
    x := [-y{1},-y{2},-y{3}];
    y:= buffer;
    
    
    !%Chiaverini-Siciliano method
    q := ChiaveriniSiciliano(x,y,z);!now we have a queternium from a normal vector!
 
      RETURN q;
   ENDFUNC
   
   PROC PosToNumArr(pos p, INOUT num e{*})
       e{1} := p.x;
       e{2} := p.y;
       e{3} := p.z;
   ENDPROC
   
   PROC  MatrixMult3x3(INOUT num M{*,*},num M1{*,*}, num M2{*,*})
       
     FOR i FROM 1 TO 3 DO
         FOR j FROM 1 TO 3 DO
             M{i,j} := M1{i,1}*M2{1,j} + M1{i,2}*M2{2,j} +M1{i,3}*M2{3,j};
         ENDFOR
     ENDFOR
     
       
   ENDPROC
   
   PROC SpanPlaneFromNormal(pos normal, INOUT pos e{*})
       VAR pos e1;
       VAR pos e2;
       VAR pos e3;
       
       !normilze normal and add it to e1
       e1 := normal;
       Normilize e1;
       
    ! generate "easy" vector to span plane
    !NOTE: we want to grip y and z from negativ to positive  
       IF Abs(e1.x) <= Abs(e1.y) AND Abs(e1.x) <= Abs(e1.z) THEN ! x is smallest numeric 
        e2 := [1,0,0]; 
      ELSEIF Abs(e1.y) <= Abs(e1.x) AND Abs(e1.y) <= Abs(e1.z) THEN ! y is smallest numeric 
        e2 := [0,-1,0];  
      ELSE !z is smallest numeric 
        e2 := [0,0,-1]; 
      ENDIF
    
      e3 := CrossProd(e1,e2);
      
      e{1} := e1;
      e{2} := e2;
      e{3} := e3;
      
   ENDPROC 
   
   PROC Normilize(INOUT pos v)
       VAR num size;
       size := sqrt(DotProd(v,v));
       
       v.x := v.x/size;
       v.y := v.y/size;
       v.z := v.z/size;
       
   ENDPROC
   
   PROC OrtogonalMatrix3x3(INOUT pos e{*})
       
       !e1 is ortogonal to nothing
       
       !make e2 ortogonal to e1
       e{2} := e{2} - Project(e{2},e{1});
       
       ! make sure e3 ortogonal to both e1 and e2
       e{3} := e{3} - Project(e{3},e{1});
       e{3} := e{3} - Project(e{3},e{2});
       
   ENDPROC
   
   ! project v1 onto v2
   FUNC pos Project(pos v1, pos v2)
       RETURN v2*(DotProd(v1,v2)/(sqrt(DotProd(v2,v2))));
   ENDFUNC
   
   FUNC orient ChiaveriniSiciliano(num x{*},num y{*},num z{*}) 
   
       VAR orient q;
       VAR num q1;
       VAR num q2;
       VAR num q3;
       VAR num q4;
       
       ! acording to ABB manual and Chiaverini Siciliano
       q1 := .5*sqrt(x{1} + y{2} + z{3} + 1);
       q2 := .5*sqrt(x{1} - y{2} - z{3} + 1)*sign(y{3}-z{2});
       q3 := .5*sqrt(-x{1} + y{2} - z{3} + 1)*sign(z{1}-x{3});
       q4 := .5*sqrt(-x{1} - y{2} + z{3} + 1)*sign(x{2}-y{1});
       
       q.q1 := q1;
       q.q2 := q2;
       q.q3 := q3;
       q.q4 := q4;
       
       q := NOrient(q);
       
       RETURN q;
       
   ENDFUNC
       
    FUNC num sign(num eq)
        IF(eq >= 0) THEN RETURN 1;
        ELSE RETURN -1;
        ENDIF
    ENDFUNC

    FUNC pos RotatePointUsingQuaternion(pos p, orient q)
        
        VAR orient q_inv;
        VAR orient p_representation;
        VAR orient q_buffer;
        VAR pos p_new;
        
        ! be able to handle point as queternion
        p_representation := PointToOrinet(p);
        
        !get acces to inverse of q
        q_inv := QuaternionInverse(q);
        
        q_buffer := QuaternionMultiplication(q,p_representation);
        q_buffer := QuaternionMultiplication(q_buffer,q_inv);
        
        p_new.x := q_buffer.q2;
        p_new.y := q_buffer.q3;
        p_new.z := q_buffer.q4;
        
        RETURN p_new;
    ENDFUNC
 
    !Hamilton product
    FUNC orient QuaternionMultiplication(orient q1, orient q2)
        VAR orient result;
        result.q1 := q1.q1 * q2.q1 - q1.q2 * q2.q2 - q1.q3 * q2.q3 - q1.q4 * q2.q4;
        result.q2 := q1.q1 * q2.q2 + q1.q2 * q2.q1 + q1.q3 * q2.q4 - q1.q4 * q2.q3;
        result.q3 := q1.q1 * q2.q3 - q1.q2 * q2.q4 + q1.q3 * q2.q1 + q1.q4 * q2.q2;
        result.q4 := q1.q1 * q2.q4 + q1.q2 * q2.q3 - q1.q3 * q2.q2 + q1.q4 * q2.q1;
        return result;
    ENDFUNC
    
    FUNC orient QuaternionInverse(orient q)
        VAR orient q_inv;
        q_inv.q1 := q.q1;
        q_inv.q2 := -q.q2;
        q_inv.q3 := -q.q3;
        q_inv.q4 := -q.q4; 
        RETURN q_inv;
    ENDFUNC
    
    FUNC orient PointToOrinet(pos p)
        VAR orient q;
        q.q1 := 0;
        q.q2 := p.x;
        q.q3 := p.y;
        q.q4 := p.z;
        
        RETURN q;
    ENDFUNC
ENDMODULE