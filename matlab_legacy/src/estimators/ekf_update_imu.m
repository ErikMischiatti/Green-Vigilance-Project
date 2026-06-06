function ekf = ekf_update_imu(ekf, z_theta, sigma_theta)
H = [0 0 1];         % 1x3
R = sigma_theta^2;   % 1x1
z = wrapToPi(z_theta);

y = wrapToPi(z - H*ekf.x);
S = H*ekf.P*H.' + R;
K = ekf.P*H.'/S;

ekf.x = ekf.x + K*y;
ekf.x(3) = wrapToPi(ekf.x(3));
I = eye(3);
ekf.P = (I - K*H)*ekf.P*(I - K*H).' + K*R*K.';
end
