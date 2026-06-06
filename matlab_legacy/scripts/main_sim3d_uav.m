% MAIN_SIM3D_UAV  Scena 3D (alberi) + UAV (uniciclo) + EKF + FoV coerente
startup; clf;
C = config();

%% --- Scena (modulare) ----------------------------------------------------
% Invece di ricreare campo/assi/alberi/ombre/foglie qui, li importiamo dalla funzione.
[ax, S] = vis3d_scene_overview_small(struct( ...
    'XL',[0 400], 'YL',[0 400], 'ZL',[0 C.vision.altitude_m], ...
    'N_TREES',55, 'RNGSeed','shuffle' ...
));

% Manteniamo variabili locali coerenti con il resto dello script
XL = S.field.XL; 
YL = S.field.YL; 
ZL = S.field.ZL;
base = S.base.xy;

% Renderer & sorting (già impostati in gran parte dalla scena, li ribadiamo safe)
set(gcf,'Renderer','opengl');
set(gcf,'GraphicsSmoothing','on');
set(ax,'SortMethod','childorder');

% Aspetti grafici base (il daspect è già impostato dalla scena; pbaspect lo allineo al tuo default)
xySpan = max(diff(xlim(ax)), diff(ylim(ax)));
zSpan  = max(diff(zlim(ax)), eps);
exag   = (xySpan/zSpan) * C.vis3d.z_exaggeration_target;
daspect(ax,[1 1 1/exag]); 
pbaspect(ax,[1 1 0.8]);

title(ax,'UAV + EKF nella scena 3D'); 
grid(ax,'on'); box(ax,'on'); view(ax,35,20);
axis(ax,'vis3d'); 
hold(ax,'on');

zGround  = 0.0;
zOverlay = 0.02;  % per footprint/marker, la scena ha già usato 2*eps internamente per ombre

% Base marker (sopra il suolo)
draw_agents_markers(base, [], 'Z', zOverlay);

% === Dati alberi dalla scena (niente generate_trees qui!) ================
XYZ_leaf    = S.trees.leafXYZ;
health_leaf = S.trees.leafHealth;
trees       = S.trees.objects;

% Overlay FoV (foglie visibili) — handle vuoto da riempire nel loop
hFoV = scatter3(ax, nan, nan, nan, 18, [0 0.5 1], 'filled', 'MarkerEdgeColor','none');

%% --- Camera model (come in statica) --------------------------------------
cam = camera_fov_from_specs(struct( ...
    'sensor_width_mm',  C.vision.sensor_width_mm, ...
    'sensor_height_mm', C.vision.sensor_height_mm, ...
    'focal_mm',         C.vision.focal_mm, ...
    'hfov_deg',         get_or(C.vision,'hfov_deg',[]), ...
    'vfov_deg',         get_or(C.vision,'vfov_deg',[]), ...
    'fstop_N',          get_or(C.vision,'fstop_N',[]), ...
    'coc_mm',           get_or(C.vision,'coc_mm',[]), ...
    'focus_distance_m', get_or(C.vision,'focus_distance_m',[]), ...
    'altitude_m',       C.vision.altitude_m, ...
    'range_min_m',      get_or(C.vision,'range_min_m',1.0), ...
    'range_max_m',      get_or(C.vision,'range_max_m',18.0) ));

% Rotazioni helper
cy=@(a)cos(a); sy=@(a)sin(a);
Rz=@(a)[cy(a) -sy(a) 0; sy(a) cy(a) 0; 0 0 1];
Ry=@(a)[cy(a) 0 sy(a); 0 1 0; -sy(a) 0 cy(a)];
Rx=@(a)[1 0 0; 0 cy(a) -sy(a); 0 sy(a) cy(a)];

%% --- Dinamica + EKF ------------------------------------------------------
dt       = get_or(C.sim,'dt_uav',0.05);
T        = get_or(C.sim,'Tfinal',60);
t        = 0:dt:T;
Ngps     = get_or(C.sim,'gps_hz',1);
gps_dt   = 1/max(Ngps,eps);
gps_tick = 0;

v_nom    = get_or(C.sim,'v_nom',3.0);
w_max    = get_or(C.sim,'w_max_rad',deg2rad(get_or(C.sim,'w_max_deg',60)));
kp_ang   = get_or(C.sim,'kp_ang',1.6);
kp_dist  = get_or(C.sim,'kp_dist',0.6);
limits   = struct('vmax',v_nom,'wmax',w_max);

sigma_gps = get_or(C.noise,'sigma_gps_m',0.8);
sigma_gyro= get_or(C.noise,'sigma_gyro_rad',deg2rad(get_or(C.noise,'sigma_gyro_deg',1.5)));
sigma_vcmd= get_or(C.noise,'sigma_vcmd',0.15);
sigma_om  = get_or(C.noise,'sigma_omega_rad',deg2rad(get_or(C.noise,'sigma_omega_deg',2.0)));

% Waypoints (notare che XL,YL = [0 400]; aggiorna se vuoi sfruttare tutto il campo)
W = [20 20; 180 20; 180 180; 20 180];  wp_i=1; wp_tol=3.0;

% Stati iniziali
x_true  = [base 0];
x0_est  = x_true + [0.5 -0.5 deg2rad(5)];
P0      = diag([1 1 deg2rad(10)]).^2;
Rgps    = diag([sigma_gps sigma_gps]).^2;
ekf     = ekf_init(x0_est, P0, sigma_vcmd, sigma_om, Rgps);

%% --- Grafica UAV + FoV iniziale ------------------------------------------
uav_alt = C.vision.altitude_m;
hUAV  = plot3(ax, x_true(1), x_true(2), uav_alt, 'bx', 'MarkerSize',10, 'LineWidth',1.8);
hTrail= plot3(ax, nan, nan, nan, '-', 'Color',[0.2 0.3 0.9], 'LineWidth',1.4);
trailX=[]; trailY=[]; trailZ=[];

USE_TRUE_FOR_VIZ = true;      % niente lag
APPLY_CAM_OFFSET = false;     % eventuale offset montaggio
cam_offset_fwd_m = 0.25;

build_pose_rad = @(xy,yaw_rad) ([xy(:).'  uav_alt  yaw_rad  C.vision.uav_pitch_rad  C.vision.uav_roll_rad]);

% Primo frustum/footprint
[pose_xy, yaw_use] = pick_pose(USE_TRUE_FOR_VIZ, x_true, ekf);
if APPLY_CAM_OFFSET
    Rz_y = [cos(yaw_use) -sin(yaw_use); sin(yaw_use) cos(yaw_use)];
    pose_xy = pose_xy(:) + Rz_y*[cam_offset_fwd_m; 0];
end
uav_pose = build_pose_rad(pose_xy, yaw_use);

hFr = draw_camera_frustum(cam, uav_pose, ...
    struct('face',C.vision.plot.face_rgb,'alpha',0.28,'edge','none'), ...
    'zExag', 1, 'wire', false, 'mode','cone', 'segments', 64);

poly = ground_footprint_from_altitude(cam, uav_pose);
hCap = [];
if ~isempty(poly)
    hCap = patch('XData',poly(:,1),'YData',poly(:,2), ...
                 'ZData',zOverlay*ones(size(poly,1),1), ...
                 'FaceColor',C.vision.plot.face_rgb,'FaceAlpha',0.12, ...
                 'EdgeColor','none','Parent',ax);
end

%% --- Legenda & assi ------------------------------------------------------
set(ax,'Units','normalized');
set(ax,'Position',[0.18 0.10 0.72 0.83]);
padXY = 8; padZ = 1;
xlim(ax, [XL(1)-padXY, XL(2)+padXY]);
ylim(ax, [YL(1)-padXY, YL(2)+padXY]);
zlim(ax, [ZL(1),       ZL(2)+padZ]);
set(ax,'CameraViewAngleMode','manual');
ax.CameraViewAngle = ax.CameraViewAngle * 1.08;

hHealthy   = scatter3(ax, NaN,NaN,NaN, 36, [0 0.8 0], 'filled', 'MarkerEdgeColor','none', 'DisplayName','healthy leaves (≥0.6)');
hUnhealthy = scatter3(ax, NaN,NaN,NaN, 36, [0.85 0.25 0.15], 'filled', 'MarkerEdgeColor','none', 'DisplayName','unhealthy leaves (≤0.4)');
set(hFoV,'DisplayName','visible in FoV');
hBaseProxy = plot3(ax, NaN,NaN,NaN, 'k*', 'MarkerSize',10, 'LineWidth',1.2, 'DisplayName','base');
hUAVProxy  = plot3(ax, NaN,NaN,NaN, 'bx', 'MarkerSize',10, 'LineWidth',1.8, 'DisplayName','UAV');

lgd = legend(ax, [hHealthy, hUnhealthy, hFoV, hBaseProxy, hUAVProxy], ...
             'Location','eastoutside', 'Box','off', 'Interpreter','none');
lgd.ItemTokenSize = [18 9]; lgd.FontSize = 10; lgd.AutoUpdate = 'off';
set([hTrail],'HandleVisibility','off');
if ~isempty(hCap), set(hCap,'HandleVisibility','off'); end
if isgraphics(hFr), set(hFr,'HandleVisibility','off'); end
set(ax,'FontName','Helvetica','FontSize',10,'LineWidth',1.0);
xlabel(ax,'X (m)'); ylabel(ax,'Y (m)'); zlabel(ax,'Z (m)');

%% --- Loop ---------------------------------------------------------------
for k=1:numel(t)
    % controller
    wp=W(wp_i,:); d=wp - x_true(1:2); dist=hypot(d(1),d(2));
    ang_ref=atan2(d(2),d(1)); ang_err=wrapToPi(ang_ref - x_true(3));
    v_cmd = v_nom * (1 - exp(-kp_dist*dist));
    w_cmd = max(min(kp_ang*ang_err, w_max), -w_max);

    % dinamica vera
    x_true = unicycle(x_true, [v_cmd, w_cmd], dt, limits);

    % sensori (mock)
    omega_meas = w_cmd + sigma_gyro*randn;
    got_gps=false;
    if t(k) >= gps_tick - 1e-9
        z_gps = x_true(1:2).' + sigma_gps*randn(2,1);
        gps_tick = gps_tick + gps_dt; got_gps=true;
    end

    % EKF
    ekf = ekf_predict(ekf, [v_cmd, omega_meas], dt);
    if got_gps, ekf = ekf_update_gps(ekf, z_gps); end

    % traiettoria/marker
    trailX(end+1)=ekf.x(1); trailY(end+1)=ekf.x(2); trailZ(end+1)=uav_alt;
    set(hUAV,'XData',ekf.x(1),'YData',ekf.x(2),'ZData',uav_alt);
    set(hTrail,'XData',trailX,'YData',trailY,'ZData',trailZ);

    % aggiorna FoV/footprint
    delete_all(hFr); 
    if ~isempty(hCap), delete_all(hCap); end

    [pose_xy, yaw_use] = pick_pose(USE_TRUE_FOR_VIZ, x_true, ekf);
    if APPLY_CAM_OFFSET
        Rz_off = [cos(yaw_use) -sin(yaw_use); sin(yaw_use) cos(yaw_use)];
        pose_xy = pose_xy(:) + Rz_off*[cam_offset_fwd_m; 0];
    end
    uav_pose = build_pose_rad(pose_xy, yaw_use);

    % aggiorna range_max in base all'inclinazione
    Rwc = Rz(uav_pose(4))*Ry(uav_pose(5))*Rx(uav_pose(6)); 
    dir = Rwc*[0;0;1];
    cam.range_min = max(eps, getfield(cam,'range_min'));
    if dir(3) < -1e-6
        t_ground = (0 - uav_pose(3)) / dir(3);
        cam.range_max = max(0.1, t_ground);
    end

    hFr = draw_camera_frustum(cam, uav_pose, ...
        struct('face',C.vision.plot.face_rgb,'alpha',0.20,'edge','none'), ...
        'zExag', 1, 'wire', false, 'mode','cone', 'segments', 64);

    poly = ground_footprint_from_altitude(cam, uav_pose);
    if ~isempty(poly)
        hCap = patch('XData',poly(:,1),'YData',poly(:,2), ...
                     'ZData',zOverlay*ones(size(poly,1),1), ...
                     'FaceColor',C.vision.plot.face_rgb,'FaceAlpha',0.18, ...
                     'EdgeColor','none','Parent',ax);
        set(hCap,'HandleVisibility','off');
    else
        hCap = [];
    end

    % foglie visibili
    visMask = points_in_frustum(cam, uav_pose, XYZ_leaf);
    set(hFoV,'XData',XYZ_leaf(visMask,1), ...
             'YData',XYZ_leaf(visMask,2), ...
             'ZData',XYZ_leaf(visMask,3));

    % waypoint switching
    if dist<wp_tol, wp_i = mod(wp_i,size(W,1))+1; end

    drawnow limitrate
end

%% --- helpers -------------------------------------------------------------
function v = get_or(S,name,fb)
if isstruct(S) && isfield(S,name) && ~isempty(S.(name)), v=S.(name); else, v=fb; end
end

function delete_all(h)
if isempty(h), return; end
if isstruct(h)
    f = fieldnames(h);
    for i=1:numel(f), delete_all(h.(f{i})); end
else
    try
        hh = h(ishandle(h));
        if ~isempty(hh), delete(hh); end
    catch
    end
end
end

function [xy,yaw] = pick_pose(useTrue, x_true, ekf)
if useTrue
    xy  = x_true(1:2);
    yaw = x_true(3);
else
    xy  = ekf.x(1:2);
    yaw = ekf.x(3);
end
end
