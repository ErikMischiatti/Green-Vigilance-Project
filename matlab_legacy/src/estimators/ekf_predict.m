function ekf = ekf_predict(ekf, u, dt)
% EKF_PREDICT  Predizione EKF (modello unicycle).
% Supporta Q sugli input (2x2) oppure Q sullo stato (3x3).

% 1) Jacobiani e propagazione stato
[F,L] = jacobians_unicycle(ekf.x, u, dt);   % F:3x3, L:3x2 (sensitività agli input)
x_pred = unicycle(ekf.x, u, dt);

% 2) Costruisci Q_processo in base alla shape di ekf.Q
Q = ekf.Q;
szQ = size(Q);
if isequal(szQ,[2 2])
    % Q su [v; omega] -> proietto nello spazio stato
    Qproc = L * Q * L.';                   % 3x3
elseif isequal(szQ,[3 3])
    % Q già nello spazio stato
    Qproc = Q;                              % 3x3
else
    error('ekf_predict:Qshape', ...
         'ekf.Q ha shape %sx%s ma deve essere 2x2 (input) o 3x3 (stato).', ...
          num2str(szQ(1)), num2str(szQ(2)));
end

% 3) Propagazione covarianza
P_pred = F * ekf.P * F.' + Qproc;

% 4) Aggiorna struct
ekf.x = [x_pred(1); x_pred(2); wrapToPi(x_pred(3))];
ekf.P = P_pred;
end
