function C = config(varargin)
%CONFIG  Central configuration & hyperparameters.
%   C = CONFIG('name', value, ...) allows overrides using dot-paths.

C = struct();

% ==== Data ====
C.data.rawDir      = fullfile(pwd,'data','raw');
C.data.procDir     = fullfile(pwd,'data','processed');
C.data.cache       = true;

% ==== Algorithm ====
C.alg.name         = 'Baseline';
C.alg.maxIter      = 100;
C.alg.tol          = 1e-6;

% ==== Experiment ====
C.exp.seed         = 42;                     % [] to skip rng
C.exp.saveDir      = fullfile(pwd,'results');
C.exp.verbose      = true;

% ==== Simulation (NEW) ====
C.sim = struct();
C.sim.dt_uav       = 0.05;   % [s] integration step for UAV dynamics
C.sim.Tfinal       = 60;     % [s] default total simulation time
C.sim.gps_hz       = 1;      % [Hz] GPS update rate (if used)

% Controller defaults (facoltativi: usali se vuoi centralizzare)
C.sim.v_nom        = 3.0;    % [m/s] nominal forward speed
C.sim.w_max_deg    = 60;     % [deg/s] max yaw rate clamp
C.sim.kp_ang       = 1.6;    % angular gain
C.sim.kp_dist      = 0.6;    % distance gain

% Noise defaults (facoltativi: comodi nei mock sensor)
C.noise.sigma_gps_m         = 0.8;   % [m]
C.noise.sigma_gyro_deg      = 1.5;   % [deg/s] gyro noise on omega
C.noise.sigma_vcmd          = 0.15;  % [m/s] command noise on v
C.noise.sigma_omega_deg     = 2.0;   % [deg/s] additional omega noise

% ==== Vision / Camera (UAV) — optics + DoF ====
C.vision.sensor_width_mm   = 6.3;   % e.g., 1/2.3"
C.vision.sensor_height_mm  = 4.7;
C.vision.focal_mm          = 4.5;

% Depth of Field
C.vision.fstop_N           = 4;      % f-number
C.vision.coc_mm            = 0.03;   % circle of confusion [mm]
C.vision.focus_distance_m  = [];     % [] -> uses altitude_m
C.vision.altitude_m        = 10.0;   % UAV altitude

% (optional) direct FoV override (has priority if set)
C.vision.hfov_deg          = [];     % e.g., 78
C.vision.vfov_deg          = [];     % e.g., 62

% Range override (forces near/far regardless of DoF)
C.vision.range_min_m       = [];     % [] = let DoF compute
C.vision.range_max_m       = [];     % [] = let DoF compute

% Pose (deg) & style
C.vision.uav_yaw_deg       = 0;
C.vision.uav_pitch_deg     = 80;    % -90 = nadir
C.vision.uav_roll_deg      = 0;
C.vision.plot.face_rgb     = [0.2 0.4 1.0];
C.vision.plot.alpha        = 0.28;
C.vision.plot.edge_rgb     = [0.1 0.2 0.6];

% ==== 3D Viz ====
C.vis3d.z_exaggeration_target = 0.6;
C.vis3d.draw_trunks           = true;
C.vis3d.leaf_radius           = 0.23;
C.vis3d.leaf_mode             = 'scatter';  % 'scatter' | 'sphere' (se supportato)

% ==== Apply overrides ====
if mod(nargin,2)~=0, error('Overrides must be pairs'); end
for k = 1:2:nargin
    path = strsplit(varargin{k}, '.');
    C = setfield_nested_safe(C, path, varargin{k+1});
end

% ==== Post-process / validation ====
% Create dirs if needed
ensure_dir(C.data.rawDir);
ensure_dir(C.data.procDir);
ensure_dir(C.exp.saveDir);

% Apply RNG (optional)
if ~isempty(C.exp.seed) && isnumeric(C.exp.seed)
    try, rng(C.exp.seed); catch, warning('Invalid RNG seed, skipping.'); end
end

% Quick sanity checks
req = { 'vision.sensor_width_mm','vision.sensor_height_mm','vision.focal_mm','vision.altitude_m' };
for i=1:numel(req)
    if ~hasfield_nested(C, strsplit(req{i},'.'))
        error('config:missingField','Required field "%s" missing.', req{i});
    end
end

% Convenience (radians) — useful for plotting without repeated deg2rad
C.vision.uav_yaw_rad      = deg2rad(C.vision.uav_yaw_deg);
C.vision.uav_pitch_rad    = deg2rad(C.vision.uav_pitch_deg);
C.vision.uav_roll_rad     = deg2rad(C.vision.uav_roll_deg);

% Convenience (radians) for sim/noise clamps
C.sim.w_max_rad           = deg2rad(C.sim.w_max_deg);
C.noise.sigma_gyro_rad    = deg2rad(C.noise.sigma_gyro_deg);
C.noise.sigma_omega_rad   = deg2rad(C.noise.sigma_omega_deg);

end

% ===== helpers =====
function S = setfield_nested_safe(S, path, val)
% Create intermediate structs if absent.
p = path{1};
if numel(path) == 1
    S.(p) = val;
else
    if ~isfield(S, p) || ~isstruct(S.(p))
        S.(p) = struct();
    end
    S.(p) = setfield_nested_safe(S.(p), path(2:end), val);
end
end

function tf = hasfield_nested(S, path)
tf = true;
for i = 1:numel(path)
    if ~isstruct(S) || ~isfield(S, path{i})
        tf = false; return;
    end
    S = S.(path{i});
end
end

function ensure_dir(d)
if ~exist(d,'dir'), mkdir(d); end
end
