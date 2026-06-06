function [F, L] = jacobians_unicycle(x, u, dt)
% JACOBIANS_UNICYCLE   Jacobiani per EKF (modellando Q sugli input [v,omega])
th = x(3); v = u(1); w = u(2);

if abs(w) < 1e-8
    F = [1 0 -v*dt*sin(th);
         0 1  v*dt*cos(th);
         0 0  1];
    L = [dt*cos(th)  0;
         dt*sin(th)  0;
         0           dt];
else
    s1 = sin(th + w*dt); c1 = cos(th + w*dt);
    s0 = sin(th);        c0 = cos(th);
    F = [1 0 (v/w)*(c1-c0);
         0 1 (v/w)*(s1-s0);
         0 0 1];
    % sensitività a [v, w] (buona per dt piccoli)
    dv = [ (s1 - s0)/w;  (-c1 + c0)/w;  0 ];
    % d/dw dei termini (derivata approssimata)
    dwdx = ( v*( (w*dt*c1 - (s1 - s0)) / (w^2) ) );
    dwdy = ( v*( (w*dt*s1 - (-c1 + c0)) / (w^2) ) );
    % forma semplice/robusta:
    L = [ dv(1), dwdx;
          dv(2), dwdy;
          0    , dt  ];
    % fallback se instabile numericamente
    if any(~isfinite(L),'all')
        L = [dt*cos(th) 0; dt*sin(th) 0; 0 dt];
    end
end
end
