clear,clc,close all;

addpath("support_functions\");

%% init var

n = [1,1,0];

mug_pos = [150,0,50];

rob_pos = [0,0,0];

v = [1,1,1]; % temp value
scaler = .8;

%% script

v = mug_pos/sqrt(dot(mug_pos,mug_pos));
a = [0,0,0];
if (abs(v(3)) <= abs(v(1)) && abs(v(3)) <= abs(v(2))) % z is the smallest
       a =  [0,0,sign(v(3))*scaler];
elseif(abs(v(2)) <= abs(v(1)) && abs(v(2)) <= abs(v(3))) % y is the smallest
       a =  [0,sign(v(2))*scaler,0];
else
       a =  [sign(v(1))*scaler,0,0];
end

v = v + a;
v = v/sqrt(dot(v,v));

v_ort = v - Proj(v,n);
%% GPT
%%PLOT

figure; hold on; grid on; axis equal
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Mug Position, Robot Position, and Vectors v, v\_ort, n');

%%--- draw spheres for mug_pos and robot_pos ---
[Xs, Ys, Zs] = sphere(20);

r_mug = 10;
r_robot = 10;

surf(r_mug*Xs + mug_pos(1), ...
     r_mug*Ys + mug_pos(2), ...
     r_mug*Zs + mug_pos(3), ...
     'FaceColor',[1 0 0],'EdgeColor','none','FaceAlpha',0.5);

surf(r_robot*Xs + rob_pos(1), ...
     r_robot*Ys + rob_pos(2), ...
     r_robot*Zs + rob_pos(3), ...
     'FaceColor',[0 0 1],'EdgeColor','none','FaceAlpha',0.5);

%%--- plot vectors starting at mug_pos ---
quiver3(mug_pos(1), mug_pos(2), mug_pos(3), ...
        v(1), v(2), v(3), ...
        50, 'k', 'LineWidth', 2);      % vector v (black)

quiver3(mug_pos(1), mug_pos(2), mug_pos(3), ...
        n(1), n(2), n(3), ...
        50, 'g', 'LineWidth', 2);      % vector n (green)

quiver3(mug_pos(1), mug_pos(2), mug_pos(3), ...
        v_ort(1), v_ort(2), v_ort(3), ...
        50, 'm', 'LineWidth', 2);      % vector v_ort (magenta)

legend('Mug','Robot','Vector v','Vector n','Vector v\_ort');
view(3)
