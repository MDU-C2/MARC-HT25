function [e1,e2,e3] = CreateFrameFromNormal(normal)

if(size(normal,1) ~= 3)
    printf("[ERROR] wrong format");
    return
end

[e1,e2,e3] = SpanSpace(normal); % I want y to align with normal

end

function [e1,e2,e3] = SpanSpace(normal)

e1 = normal./sqrt(dot(normal,normal)); % get normilzied vector
e2 = zeros(3,1);
% generate a basic vector
if(e1(1) <= e1(2) && e1(1) <= e1(3)) % x is smallest vector
    e2 = [1;0;0];
elseif (e1(2) <= e1(1) && e1(2) <= e1(3)) % y is smallest vector
    e2 = [0;1;0];
else % z is smallest
    e2 = [0;0;1];
end

e3 = cross(e1,e2);

end