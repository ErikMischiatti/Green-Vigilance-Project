function ekf = ekf_init(x0, P0, sigma_v, sigma_omega, Rgps)
% EKF_INIT  Crea lo struct EKF con convenzioni consistenti.
% x0: 3x1, P0: 3x3, sigma_v/omega: std dei comandi, Rgps: 2x2.

ekf.x     = x0(:);         % 3x1
ekf.P     = P0;            % 3x3
ekf.Q     = diag([sigma_v, sigma_omega]).^2;  % 2x2, sul vettore input [v; ω]
ekf.Rgps  = Rgps;          % 2x2
ekf.Hgps  = [1 0 0; 0 1 0];% 2x3
end
