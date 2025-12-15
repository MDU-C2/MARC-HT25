MODULE MugManipulation_SupportFunctions
   !!! ================== SUPPORT FUNCTIONS =========================== !!!
   
   !Align y axes with normal and align zaxes to a semi optimal vector from robot to mug
   FUNC orient NormalToOrientationSemiOptimal(pos mug_position,pos normal)
       
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
       SpanPlaneFromNormalSemiOptimal mug_position,normal,e;
      
       ! make the Span ortogonal to get proporties of Rotation matrix
       OrtogonalMatrix3x3 e;
        
        ! To make the frame "right" compared to the wated outcome
       PosToNumArr e{1},y;
       PosToNumArr e{2},z;
       PosToNumArr e{3},x;

        !%Chiaverini-Siciliano method
        q := ChiaveriniSiciliano(x,y,z);!now we have a queternium from a normal vector!
 
      RETURN q;
   ENDFUNC
  
   ! Convert position to num array
   PROC PosToNumArr(pos p, INOUT num e{*})
       e{1} := p.x;
       e{2} := p.y;
       e{3} := p.z;
   ENDPROC
   
   ! matrix multiplication
   PROC  MatrixMult3x3(INOUT num M{*,*},num M1{*,*}, num M2{*,*})
       
     FOR i FROM 1 TO 3 DO
         FOR j FROM 1 TO 3 DO
             M{i,j} := M1{i,1}*M2{1,j} + M1{i,2}*M2{2,j} +M1{i,3}*M2{3,j};
         ENDFOR
     ENDFOR
     
       
   ENDPROC
   
   ! get 2 vector non parallel to normal, but one of them is in specific direction
   PROC SpanPlaneFromNormalSemiOptimal(pos mug_position, pos normal, INOUT pos e{*})
       VAR pos e1;
       VAR pos e2;
       VAR pos e3;
       
       !normilze normal and add it to e1
       e1 := normal;
       Normilize e1;

       e2 := SemiOptimalPickUpOrientation(mug_position,e1);

       e3 := CrossProd(e1,e2);
      
      e{1} := e1;
      e{2} := e2;
      e{3} := e3;
      
   ENDPROC 
   
   
   ! support function to span plane to find the specifit directional vector
   FUNC pos SemiOptimalPickUpOrientation(pos position,pos normal)
       
       ! We want to make the magnitude of cross product of n and v1 to be as big as possible,
       ! This to make the area between them as big as possible, aka include more information and less distortion
       ! We also want to make sure that if the mug is laying down (n = [?,?,0]) the vector should be close to [small,small,sgn(mug.pos.z - robtarget.pos.z)] 
       
       VAR pos u;
       VAR pos v;
       VAR num scaler;
       scaler := .2; ! weight the normal vector minial value
    
       position := position - shoulderPos(position,[300,200,460],100); ! this to gain the vector from the sholder and not the base
       u := position/sqrt(DotProd(position,position)); ! robtarget.trans from robot base = [0,0,0] meaning u = pos - [0,0,0] = pos;
       
            ! generate "easy" vector to span plane
        !NOTE: we want to grip y and z from negativ to positive  
           IF Abs(normal.z) <= Abs(normal.y) AND Abs(normal.z) <= Abs(normal.x) THEN ! z is smallest numeric 
             v := [0,0,sign(u.z)*scaler];
          ELSEIF Abs(normal.y) <= Abs(normal.x) AND Abs(normal.y) <= Abs(normal.z) THEN ! y is smallest numeric 
             v := [0,sign(u.y)*scaler,0];
          ELSE !x is smallest numeric 
            v := [sign(u.x)*scaler,0,0];
          ENDIF
       
       v := v + u;
       
       v := v/sqrt(DotProd(v,v));
       
       v := v - Project(v,normal);
       
       v := v/sqrt(DotProd(v,v));
       
       RETURN v;
       
   ENDFUNC
   
   ! normilize position variable
   PROC Normilize(INOUT pos v)
       VAR num size;
       size := sqrt(DotProd(v,v));
       
       v.x := v.x/size;
       v.y := v.y/size;
       v.z := v.z/size;
       
   ENDPROC
   
   ! make a 3x3 matrix ortogonal
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
   
   ! convert 3x3 matrix to queternion
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
       
   ! return i +1, -1 or 0 depending of sign of number
    FUNC num sign(num eq)
        IF(eq >= 0) THEN RETURN 1;
        ELSE RETURN -1;
        ENDIF
    ENDFUNC

    ! rotate a point using a queterion
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
    
    ! get inverse or queternion
    FUNC orient QuaternionInverse(orient q)
        VAR orient q_inv;
        q_inv.q1 := q.q1;
        q_inv.q2 := -q.q2;
        q_inv.q3 := -q.q3;
        q_inv.q4 := -q.q4; 
        RETURN q_inv;
    ENDFUNC
    
    ! make a point into orinet (w = 0)
    FUNC orient PointToOrinet(pos p)
        VAR orient q;
        q.q1 := 0;
        q.q2 := p.x;
        q.q3 := p.y;
        q.q4 := p.z;
        
        RETURN q;
    ENDFUNC
    
    ! get wanted orientation
    ! sadly was not working with dynamic so needed to be hard coded
    FUNC orient MugHandOverOrient()
        RETURN  NOrient([.707,-.707,0,0]); 
    ENDFUNC       
    
      ! the mug is longer if it standing up rather then laying down
    FUNC num ZOffset(pos normal)
        
        ! mug standing upright
        IF abs(normal.z) >= abs(normal.x) AND abs(normal.z) >= abs(normal.y) THEN
            RETURN mug_offset_standingup;
        ELSE
            RETURN mug_offset_layingdown;
        ENDIF
            
    ENDFUNC
    
    FUNC pos shoulderPos(pos mug_pos, pos origo, num radius)
        VAR pos v1;
        VAR pos s_shoulder;
        VAR pos h_shoulder;
        VAR num v1_magn;
        h_shoulder := [origo.x,origo.y+500,origo.z];
        
        v1 := [mug_pos.x - origo.x,mug_pos.y-origo.y,origo.z];
        s_shoulder :=  [origo.x-v1.x,origo.y-v1.y,v1.z];
        v1_magn := Sqrt(v1.x*v1.x + v1.y*v1.y);
        IF v1_magn > radius THEN
            RETURN s_shoulder;
        ELSE
            RETURN h_shoulder;
        ENDIF
    ENDFUNC
    
ENDMODULE