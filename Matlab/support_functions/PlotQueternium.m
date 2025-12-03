function PlotQueternium(q)

hold on;
grid on;
axis equal;

% --- Plot axes ---
plot3([0 q{1}], [0 q{2}], [0 q{3}], 'Color', [0,0,0], 'LineWidth',3);
plot3(q{1},q{2}, q{3},"*", 'Color', [0,0,0], 'LineWidth',3);


end