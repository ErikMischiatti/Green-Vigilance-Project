function cam = camera_fov_from_specs(opts)
% CAMERA_FOV_FROM_SPECS  Compute camera FoV and near/far planes (DoF if available).
% Inputs (any subset):
%   FoV direct:  hfov_deg, vfov_deg
%   or optics:   sensor_width_mm, sensor_height_mm, focal_mm
%   DoF (opt):   fstop_N, coc_mm, focus_distance_m (or altitude_m as fallback)
%   Range ovrd:  range_min_m, range_max_m
%
% Returns (meters for ranges):
%   cam.hfov_deg, cam.vfov_deg, cam.range_min, cam.range_max
%   + extras: hfov_rad, vfov_rad, tan_half_h, tan_half_v, focus_m_used, f_m_used

hasf  = @(S,f) isstruct(S) && isfield(S,f) && ~isempty(S.(f));
getfs = @(S,f,d) safe_scalar(S,f,d);

% --- FoV selection ---
hfov = getfs(opts,'hfov_deg', NaN);
vfov = getfs(opts,'vfov_deg', NaN);
wmm  = getfs(opts,'sensor_width_mm',  NaN);
hmm  = getfs(opts,'sensor_height_mm', NaN);
fmm  = getfs(opts,'focal_mm',         NaN);

if isfinite(hfov) && isfinite(vfov)
    % both provided
elseif isfinite(hfov) && isfinite(wmm) && isfinite(hmm) && wmm>0 && hmm>0
    % derive vfov from hfov + aspect ratio
    hf = deg2rad(hfov);
    aspect = hmm / wmm;
    vfov = rad2deg( 2*atan( tan(hf/2) * aspect ) );
elseif isfinite(vfov) && isfinite(wmm) && isfinite(hmm) && wmm>0 && hmm>0
    % derive hfov from vfov + aspect ratio
    vf = deg2rad(vfov);
    aspect_inv = wmm / hmm;
    hfov = rad2deg( 2*atan( tan(vf/2) * aspect_inv ) );
else
    % compute from optics
    assert(all(isfinite([wmm hmm fmm])) && all([wmm hmm fmm] > 0), ...
        'Provide both hfov/vfov OR sensor_width_mm, sensor_height_mm, focal_mm > 0.');
    hfov = 2*atan2d((wmm/2), fmm);
    vfov = 2*atan2d((hmm/2), fmm);
end
assert(isfinite(hfov) && hfov>0 && hfov<180, 'Invalid hfov');
assert(isfinite(vfov) && vfov>0 && vfov<180, 'Invalid vfov');

cam.hfov_deg = hfov;
cam.vfov_deg = vfov;
cam.hfov_rad = deg2rad(hfov);
cam.vfov_rad = deg2rad(vfov);
cam.tan_half_h = tan(cam.hfov_rad/2);
cam.tan_half_v = tan(cam.vfov_rad/2);

% --- DoF / near-far ---
near = []; far = [];

N      = getfs(opts,'fstop_N',          NaN);
CoC_mm = getfs(opts,'coc_mm',           NaN);
s      = getfs(opts,'focus_distance_m', NaN);
if ~isfinite(s) || s<=0
    s = getfs(opts,'altitude_m', NaN);
end
cam.focus_m_used = s;

% focal in meters (try explicit, else infer from hfov + sensor width)
f_m_used = NaN;
if isfinite(fmm) && fmm>0
    f_m_used = fmm/1000;
elseif isfinite(wmm) && wmm>0
    f_m_used = ( (wmm/1000)/2 ) / cam.tan_half_h; % infer from hfov+sensor width
end
cam.f_m_used = f_m_used;

if isfinite(f_m_used) && f_m_used>0 && isfinite(N) && N>0 && isfinite(CoC_mm) && CoC_mm>0 && isfinite(s) && s>0
    C = CoC_mm/1000;
    H = (f_m_used^2)/(N*C) + f_m_used;  % hyperfocal
    near = (H*s) / (H + (s - f_m_used));
    den  = (H - (s - f_m_used));
    if den > 0, far = (H*s) / den; else, far = Inf; end
end

% --- fallback / override ---
if ~(isfinite(near) && isfinite(far) && far > near)
    near = getfs(opts,'range_min_m', 0.5);
    far  = getfs(opts,'range_max_m', 40.0);
end
% clamp near minimal physical
near = max(near, 1e-3);

if hasf(opts,'range_min_m'), tmp = getfs(opts,'range_min_m', near); if isfinite(tmp), near = max(tmp,1e-3); end, end
if hasf(opts,'range_max_m'), tmp = getfs(opts,'range_max_m', far ); if isfinite(tmp),  far = tmp; end, end

assert(isfinite(near) && isfinite(far) && far>near, 'Invalid range_min/max');

cam.range_min = near;
cam.range_max = far;
end

function v = safe_scalar(S,f,defaultVal)
v = defaultVal;
if ~(isstruct(S) && isfield(S,f)), return; end
x = S.(f);
if isnumeric(x) && ~isempty(x)
    x = double(x);
    if isscalar(x) && isfinite(x), v = x; end
end
end
