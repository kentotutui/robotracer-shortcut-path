%data = load("2024AllJapan_Dis,theta.txt");
%data = load("reRoeasymap_Dis,theta.txt");
%data = load("reRomap_xy.txt");
data = load("Distance, Theta.txt");

AllEuclideanDistance = 0;

% 距離と角度の列を抽出
distance = data(:, 1);
theta = data(:, 2);
theta_adj = theta .* 1;

% ゼロでない距離のみを抽出
distance = nonzeros(distance);
theta = theta(1:length(distance));

% 変数の初期化
x = 0;
y = 0;
th = 0;

X = [];
Y = [];
Th = [];

% 距離と角度の値を反復処理
for i = 1:length(distance)
    x = x + distance(i) * cos(th + theta_adj(i)/2); % 10mmの距離をx座標に変換
    y = y + distance(i) * sin(th + theta_adj(i)/2); % 10mmの距離をy座標に変換
    th = th + theta_adj(i); % 角度を調整
    %x = distance(i);%x座標
    %y = theta(i);%y座標
%{
    if i > 1
        dx = x - X(end); % x方向の差
        dy = y - Y(end); % y方向の差
        new_th = atan2(dy, dx); % 前の座標との角度を計算

        % 前の角度との差を計算
        delta_th = new_th - Th(end);
        
        % 急激な変化があった場合の補正 -9から-3になる不具合は修正されていない 実機のプログラムは克服済みなので，問題ない
        if delta_th > pi
            new_th = new_th - 2 * pi;
        elseif delta_th < -pi
            new_th = new_th + 2 * pi;
        end
        
        th = new_th; % 補正した角度を使用
    else
        th = atan2(y, x); % 最初のポイントはそのまま角度を計算
    end
%}
    X = [X x];
    Y = [Y y];
    Th = [Th th];
end

% コースの全体距離を計算
for i = 1:length(X)-1
    EuclideanDistance(i) = sqrt((X(i+1) - X(i))^2 + (Y(i+1) - Y(i))^2);
    AllEuclideanDistance = AllEuclideanDistance + EuclideanDistance(i);
end

% 平滑化のための変数の初期化
X_smooth = [];
Y_smooth = [];
Th_smooth = [];
Th_delta = [];
EuclideanDistance = [];
AllEuclideanDistance_shortcut = 0; % ユークリッド距離の総和の初期化
distance_threshold = 30; % 距離のしきい値を設定（例：10mm）

% 最初の点を追加
X_smooth = X(1);
Y_smooth = Y(1);
Th_smooth = Th(1); % 初期角度も追加

% 移動平均を計算
for i = 2:numel(X)
    windowSize = min(i, 10); % 窓のサイズを設定
    if i <= windowSize
        temp_x = sum(X(1:i)) / i; % Xの移動平均
        temp_y = sum(Y(1:i)) / i; % Yの移動平均
    else
        temp_x = sum(X(i-windowSize+1:i)) / windowSize; % Xの移動平均
        temp_y = sum(Y(i-windowSize+1:i)) / windowSize; % Yの移動平均
    end
    
    euclidean_dist = sqrt((temp_x - X_smooth(end))^2 + (temp_y - Y_smooth(end))^2);

    if euclidean_dist > distance_threshold
        % 新しい座標を追加
        X_smooth = [X_smooth temp_x];
        Y_smooth = [Y_smooth temp_y];
        
        % 新しい角度を計算
        dx = temp_x - X_smooth(end-1); % x方向の差
        dy = temp_y - Y_smooth(end-1); % y方向の差
        new_th2 = atan2(dy, dx); % 前の座標との角度を計算

        % 急激な変化があった場合の補正
        delta_th2 = new_th2 - Th_smooth(end);
        if delta_th2 > pi
            new_th2 = new_th2 - 2 * pi;
        elseif delta_th2 < -pi
            new_th2 = new_th2 + 2 * pi;
        end

        delta_th3 = new_th2 - Th_smooth(end);
        
        Th_smooth = [Th_smooth new_th2]; % 補正した角度を使用
        Th_delta = [Th_delta delta_th3];
        
        % ユークリッド距離を保存
        EuclideanDistance = [EuclideanDistance euclidean_dist];
        AllEuclideanDistance_shortcut = AllEuclideanDistance_shortcut + euclidean_dist;
        euclidean_dist = 0;
    end
end

% オリジナルコースとショートカットコースの総距離を表示
disp('コースの総距離:')
fprintf('%.0fmm\n', AllEuclideanDistance);

disp('ショートカット経路の総距離:')
fprintf('%.0fmm\n', AllEuclideanDistance_shortcut);

% ショートカット経路座標をファイルに保存
output_file = 'Shortcatdata_output.txt';
fid = fopen(output_file, 'w');
fprintf(fid, '%f %f\n', [X_smooth; Y_smooth]);
fclose(fid);
disp('ショートカット座標がファイルに保存されました。');

% ショートカット座標間のユークリッド距離をファイルに保存
output_file = 'EuclideanDistance_output.txt';
fid = fopen(output_file, 'w');
fprintf(fid, '%f\n', EuclideanDistance);
fclose(fid);
disp('ショートカット座標間の距離がファイルに保存されました。');

output_file = 'atan2.txt';
fid = fopen(output_file, 'w');
fprintf(fid, '%f\n', Th_smooth);
fclose(fid);
disp('atan2で計算された角速度がファイルに保存されました。');

output_file = 'atan2_delta.txt';
fid = fopen(output_file, 'w');
fprintf(fid, '%f\n', Th_delta);
fclose(fid);
disp('比較した角速度がファイルに保存されました。');

% オリジナルコースとショートカットコースをプロット
figure(1);
scatter(X, Y, 'red')
hold on
scatter(X_smooth, Y_smooth, 'blue')
xline(0, "-r")
xline(-1000, "-r")
yline(0, "-r")
grid on
grid minor
axis equal
legend('Original MAP (red)', 'Shortcut MAP (blue)')
