function ekf = ekf_update_gps(ekf, z_xy)
% EKF_UPDATE_GPS  Update EKF con misura GPS [x;y].
% Richiede: ekf.x (3x1), ekf.P (3x3), ekf.Hgps (2x3), ekf.Rgps (2x2).

z = z_xy(:);                 % 2x1
H = ekf.Hgps;                % 2x3
x = ekf.x(:);  P = ekf.P;    % 3x1, 3x3

% innovazione
y = z - H*x;                 % 2x1
S = H*P*H.' + ekf.Rgps;      % 2x2
K = P*H.'/S;                 % 3x2  (equivale a P*H.'*inv(S))

% aggiornamento (forma di Joseph, numericamente più stabile)
I = eye(3);
x = x + K*y;
P = (I - K*H)*P*(I - K*H).' + K*ekf.Rgps*K.';

% normalizza angolo
x(3) = wrapToPi(x(3));

ekf.x = x; ekf.P = P;
end
