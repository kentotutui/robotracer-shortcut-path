data = load("Distance, Theta.txt");
distance = data(:, 1);
theta = data(:, 2);

% データが有るところだけ抽出
distance = nonzeros(distance);
theta = theta(1:size(distance));

theta_adj = theta .* 1;

x = 0;
y = 0;
th = 0;

X = [];
Y = [];
for i = 1:size(distance)
    %x = x + distance(i) * cos(th + theta_adj(i)/2);
    %y = y + distance(i) * sin(th + theta_adj(i)/2);
    x = distance(i);
    y = theta(i);
    th = th + theta_adj(i);
    X = [X x];
    Y = [Y y];
end

figure(1);
scatter(X, Y)
xline(0,"-r")
xline(-1000,"-r")
yline(0,"-r")
grid on
grid minor
axis equal