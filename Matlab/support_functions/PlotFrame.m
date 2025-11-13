function PlotFrame(x, y, z, id)
% PlotFrame(x, y, z, id)
% Plots a 3D coordinate frame given three vectors x, y, z.
% Adds labels X_id, Y_id, Z_id at the end of each vector.
% If id ~= 0, colors are slightly adjusted for distinction.

if nargin < 4
    id = 0;
end

% --- Base colors ---
base_red   = [1 0 0];
base_green = [0 1 0];
base_blue  = [0 0 1];

% --- Adjust colors based on id ---
% (The higher the id, the more the colors shift toward white)
if id ~= 0
    shift = 0.2 * id; % controls how much color changes per id
    % clamp between 0 and 1
    shift = min(shift, 0.7);
    red   = min(base_red   - shift, 1) + base_green*shift + base_blue*shift;
    green = min(base_green - shift, 1)+ base_red*shift + base_blue*shift;
    blue  = min(base_blue  - shift, 1)+ base_green*shift + base_red*shift;
else
    red = base_red;
    green = base_green;
    blue = base_blue;
end

% Label suffix
if id == 0
    id_str = '';
else
    id_str = ['_' num2str(id)];
end


% --- Set axis limits ---
m = max([x, y, z], [], "all");
xlim([-m m]);
ylim([-m m]);
zlim([-m m]);

% --- Set view ---
view(45, 45);

hold on;
grid on;
axis equal;

% --- Plot axes ---
plot3([0 x(1)], [0 x(2)], [0 x(3)], 'Color', red,   'LineWidth', 1.5);
plot3([0 y(1)], [0 y(2)], [0 y(3)], 'Color', green, 'LineWidth', 1.5);
plot3([0 z(1)], [0 z(2)], [0 z(3)], 'Color', blue,  'LineWidth', 1.5);

% --- Plot axis endpoints ---
plot3(x(1), x(2), x(3), 'o', 'Color', red);
plot3(y(1), y(2), y(3), 'o', 'Color', green);
plot3(z(1), z(2), z(3), 'o', 'Color', blue);

% --- Origin ---
plot3(0, 0, 0, 'o', 'Color', 'black');

% --- Add labels at the end of each vector ---
offset = 0.05 * (m+id); % small offset so text doesn’t overlap
text(x(1)+offset, x(2)+offset, x(3)+offset, ['X' id_str], 'Color', red,   'FontWeight', 'bold');
text(y(1)+offset, y(2)+offset, y(3)+offset, ['Y' id_str], 'Color', green, 'FontWeight', 'bold');
text(z(1)+offset, z(2)+offset, z(3)+offset, ['Z' id_str], 'Color', blue,  'FontWeight', 'bold');

hold off;

end
