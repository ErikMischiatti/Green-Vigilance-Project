% DEMO_EKF_UAV  Dinamica uniciclo + EKF su traiettoria waypoint
startup;

% ---------- Parametri simulazione ----------
dt      = 0.05;             % s (EKF/gyro)
T       = 120;              % s
t       = 0:dt:T;
Ngps    = 1;                % Hz GPS
gps_dt  = 1/Ngps;
gps_tick= 0;

% Limiti e controlli
v_nom   = 3.0;              % m/s
w_max   = deg2rad(60);      % rad/s
kp_ang  = 1.6;
kp_dist = 0.6;

limits  = struct('vmax', v_nom, 'wmax', w_max);

% Waypoints (rettangolo)
W = [ 20 20;
     180 20;
     180 180;
      20 180];
wp_i = 1; wp_tol = 3.0;

% ---------- Rumori sensori ----------
sigma_gps  = 0.8;                 % m
sigma_gyro = deg2rad(1.5);        % rad/s
sigma_vcmd = 0.15;                % m/s incertezza sul comando
sigma_om   = deg2rad(2.0);        % rad/s incertezza su omega

% ---------- Stato vero & EKF ----------
x_true = [100 100 0];
x0_est = x_true + [0.5 -0.5 deg2rad(5)];
P0     = diag([1 1 deg2rad(10)]).^2;

sigma_vcmd = 0.15;                 % std m/s (NON al quadrato)
sigma_om   = deg2rad(2.0);         % std rad/s
Rgps       = diag([sigma_gps sigma_gps]).^2;

ekf = ekf_init(x0_est, P0, sigma_vcmd, sigma_om, Rgps);


% Log
Xtrue = zeros(numel(t),3);
Xest  = zeros(numel(t),3);

% ---------- Sim loop ----------
theta_meas = x0_est(3);  % integrazione grezza del gyro (se vuoi usare ekf_update_imu)
for k=1:numel(t)
    % --- controller verso waypoint corrente
    wp = W(wp_i,:);
    vec = wp - x_true(1:2);
    dist= hypot(vec(1), vec(2));
    ang_ref = atan2(vec(2), vec(1));
    ang_err = wrapToPi(ang_ref - x_true(3));
    v_cmd   = v_nom * (1 - exp(-kp_dist*dist));            % accelera con distanza
    w_cmd   = clamp(kp_ang*ang_err, -w_max, w_max);

    % --- verità a terra (usa comandi "perfetti")
    x_true = unicycle(x_true, [v_cmd, w_cmd], dt, limits);

    % --- sensori
    omega_meas = w_cmd + sigma_gyro*randn;                 % gyro
    if (t(k) >= gps_tick - 1e-9)
        z_gps = x_true(1:2) + sigma_gps*randn(1,2);
        gps_tick = gps_tick + gps_dt;
        got_gps = true;
    else
        got_gps = false;
    end

    % --- EKF: predizione con u = [v_cmd, omega_meas]
    ekf = ekf_predict(ekf, [v_cmd, omega_meas], dt);

    % (opzionale) update IMU con theta integrato (qui lo saltiamo)
    % theta_meas = wrapToPi_local(theta_meas + omega_meas*dt);
    % ekf = ekf_update_imu(ekf, theta_meas);

    % update GPS quando disponibile
    if got_gps
        ekf = ekf_update_gps(ekf, z_gps);
    end

    % --- log
    Xtrue(k,:) = x_true;
    Xest(k,:)  = ekf.x.';
    % cambio waypoint?
    if dist < wp_tol
        wp_i = mod(wp_i, size(W,1)) + 1;
    end
end

% ---------- Plot ----------
figure('Color','w'); hold on; axis equal
plot(W([1:end 1],1), W([1:end 1],2), 'k--', 'LineWidth',1); % poligono wp
plot(Xtrue(:,1), Xtrue(:,2), 'Color',[0.3 0.7 0.3], 'LineWidth',1.8);
plot(Xest(:,1),  Xest(:,2),  'Color',[0.2 0.3 0.9], 'LineWidth',1.6);
scatter(W(:,1), W(:,2), 50, 'k', 'filled');
legend({'Waypoints','True','EKF'}, 'Location','best'); grid on; box on
xlabel('X [m]'); ylabel('Y [m]'); title('UAV unicycle + EKF (GPS 1 Hz, gyro noisy)');

% RMSE posizione
pos_err = hypot(Xest(:,1)-Xtrue(:,1), Xest(:,2)-Xtrue(:,2));
fprintf('RMSE pos = %.2f m (mediana %.2f m)\n', rms(pos_err,'omitnan'), median(pos_err,'omitnan'));

% --- helpers locali ---
function y = clamp(x,a,b), y = min(max(x,a),b); end
function a = wrapToPi_local(a), a = mod(a+pi,2*pi)-pi; end
