function ort_m =  ortogonalMatrix (M)

   e1 = M(:,1);
   e2 = M(:,2);
   e3 = M(:,3);

   %e1 is ortogonal to itself

   % make e2 ortogonal to e1
   e2 = e2 - Proj(e2,e1);

   % make e3 ortogonal to e1 and e2
   e3 = e3 - Proj(e3,e1);
   e3 = e3 - Proj(e3,e2);
   
   % normilze all vectors
   e1 = e1./sqrt(dot(e1,e1));
   e2 = e2./sqrt(dot(e2,e2));
   e3 = e3./sqrt(dot(e3,e3));

   ort_m = [e1,e2,e3];
end