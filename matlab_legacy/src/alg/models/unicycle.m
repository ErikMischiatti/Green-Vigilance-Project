function xnext = unicycle(x, u, dt, limits)
% UNICYCLE   Cinematica non-olonomica per UAV/UGV
%   x = [x y theta], u = [v omega]
%   limits: struct('vmax',..,'wmax',..) opzionale
if nargin<4 || isempty(limits)
    limits = struct('vmax', Inf, 'wmax', Inf);
end
v = clamp(u(1), -limits.vmax, limits.vmax);
w = clamp(u(2), -limits.wmax, limits.wmax);
 
th = x(3);
if abs(w) < 1e-8
    dx  = v*cos(th)*dt;
    dy  = v*sin(th)*dt;
    dth = w*dt;
else
    dx  = (v/w)*(sin(th + w*dt) - sin(th));
    dy  = (v/w)*(-cos(th + w*dt) + cos(th));
    dth = w*dt;
end
xnext = [x(1)+dx, x(2)+dy, wrapToPi_local(th + dth)];
end

function y = clamp(x,a,b), y = min(max(x,a),b); end
function a = wrapToPi_local(a), a = mod(a+pi,2*pi)-pi; end
