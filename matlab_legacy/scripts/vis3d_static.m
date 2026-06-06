% VIS3D_STATIC  Static 3D scene (con scena modulare)
startup;

% 0) Config 
C = config();

% === 1) SCENA (campo + alberi + ombre + foglie) ==========================
% Passa qui i parametri che vuoi variare (oppure nulla per i default)
[ax, S] = vis3d_scene_overview_small(struct( ...
    'XL',[0 200], 'YL',[0 200], 'ZL',[0 C.vision.altitude_m], ...
    'N_TREES',50, 'RNGSeed','shuffle' ...
));

% Renderer & sorting (trasparenze affidabili) — (in genere già settati da vis3d_scene_overview_small)
set(gcf,'Renderer','opengl');
set(gcf,'GraphicsSmoothing','on');
set(ax,'SortMethod','childorder');

title(ax, '3D Visualization — Static');

% Layer Z utili per evitare z-fighting
zGround  = eps;
zOverlay = 2*eps;

% === 2) Base + UAV marker (sopra il suolo) ================================
base = S.base.xy;                        % centro campo dalla scena
draw_agents_markers(base, [], 'Z', zOverlay);

% === 3) Camera / Frustum (cono "pieno" con vertice ~drone) ================
cam = camera_fov_from_specs(struct( ...
    'sensor_width_mm',  C.vision.sensor_width_mm, ...
    'sensor_height_mm', C.vision.sensor_height_mm, ...
    'focal_mm',         C.vision.focal_mm, ...
    'hfov_deg',         get_or(C.vision,'hfov_deg',[]), ...
    'vfov_deg',         get_or(C.vision,'vfov_deg',[]), ...
    'fstop_N',          get_or(C.vision,'fstop_N',[]), ...
    'coc_mm',           get_or(C.vision,'coc_mm',[]), ...
    'focus_distance_m', get_or(C.vision,'focus_distance_m',[]), ...
    'altitude_m',       C.vision.altitude_m ...
));

uav_pose = [ ...
    base(1), base(2), C.vision.altitude_m, ...
    deg2rad(C.vision.uav_yaw_deg), ...
    deg2rad(C.vision.uav_pitch_deg), ...
    deg2rad(C.vision.uav_roll_deg) ];

% Direzione asse ottico in world (+Z_cam)
cy=@(a)cos(a); sy=@(a)sin(a);
Rz=@(a)[cy(a) -sy(a) 0; sy(a) cy(a) 0; 0 0 1];
Ry=@(a)[cy(a) 0 sy(a); 0 1 0; -sy(a) 0 cy(a)];
Rx=@(a)[1 0 0; 0 cy(a) -sy(a); 0 sy(a) cy(a)];
Rwc = Rz(uav_pose(4))*Ry(uav_pose(5))*Rx(uav_pose(6));
dir = Rwc*[0;0;1];

cam.range_min = max(eps, getfield(cam,'range_min'));
if dir(3) < -1e-6
    % Punta verso il suolo: base esattamente a z=0
    t_ground = (0 - uav_pose(3)) / dir(3);   % > 0
    cam.range_max = max(0.1, t_ground);
end

% Cono: niente spigoli, niente wire (mantello pulito)
draw_camera_frustum(cam, uav_pose, struct( ...
    'face',  C.vision.plot.face_rgb, ...
    'alpha', 0.28, ...
    'edge',  'none'), ...
    'zExag', 1, 'wire', false, 'mode','cone', 'segments', 64);

% Marker UAV (quota reale)
plot3(ax, uav_pose(1), uav_pose(2), uav_pose(3), ...
      'bx', 'MarkerSize',10, 'LineWidth',1.8);

% === 4) NIENTE generazione alberi qui =====================================
% (già fatto da vis3d_scene_overview_small)
% Usa i dati da S:
XYZ_leaf    = S.trees.leafXYZ;
health_leaf = S.trees.leafHealth;
trees       = S.trees.objects;

% === 5) NIENTE ombre (già disegnate dalla scena) ==========================
% (Se mai servisse ridisegnarle, sono in S.handles.shadows)

% === 6) NIENTE foglie (già disegnate) =====================================
% (Handle: S.handles.leaves)

% === 7) Foglie visibili nel FoV ===========================================
visMask = points_in_frustum(cam, uav_pose, XYZ_leaf);
hold(ax, 'on');
hFoV = scatter3(XYZ_leaf(visMask,1), XYZ_leaf(visMask,2), XYZ_leaf(visMask,3), ...
                18, [0 0.5 1], 'filled', 'DisplayName','visible in FoV');

% === 8) Footprint (cap) appena sopra il suolo =============================
poly = ground_footprint_from_altitude(cam, uav_pose);
if ~isempty(poly)
    patch('XData',poly(:,1), 'YData',poly(:,2), 'ZData',zOverlay*ones(size(poly,1),1), ...
          'FaceColor',C.vision.plot.face_rgb, 'FaceAlpha',0.18, 'EdgeColor','none', 'Parent',ax);
end

% ====== Layout/limiti opzionali (se vuoi mantenerli) =====================
set(ax,'Units','normalized');
set(ax,'Position',[0.18 0.10 0.72 0.83]);   % sposta la scena a destra
padXY = 8; padZ = 1;
xlim(ax, [S.field.XL(1)-padXY, S.field.XL(2)+padXY]);
ylim(ax, [S.field.YL(1)-padXY, S.field.YL(2)+padXY]);
zlim(ax, [S.field.ZL(1),       S.field.ZL(2)+padZ]);
set(ax,'CameraViewAngleMode','manual');
ax.CameraViewAngle = ax.CameraViewAngle * 1.08;

% ====== Legenda (ricrea solo i proxy necessari) ===========================
% proxy invisibili per legenda
hHealthy    = scatter3(ax, NaN,NaN,NaN, 36, [0 0.8 0], 'filled', 'DisplayName','healthy leaves (≥0.6)');
hUnhealthy  = scatter3(ax, NaN,NaN,NaN, 36, [0.85 0.25 0.15], 'filled', 'DisplayName','unhealthy leaves (≤0.4)');
hBaseProxy  = plot3(ax, NaN,NaN,NaN, 'k*', 'MarkerSize',10, 'LineWidth',1.2, 'DisplayName','base');
hUAVProxy   = plot3(ax, NaN,NaN,NaN, 'bx', 'MarkerSize',10, 'LineWidth',1.8, 'DisplayName','UAV');

lgd = legend(ax, [hHealthy, hUnhealthy, hFoV, hBaseProxy, hUAVProxy], ...
             'Location','eastoutside', 'Box','off', 'Interpreter','none');
lgd.ItemTokenSize = [18 9];
lgd.FontSize = 10;

% --- helper locale ---
function v = get_or(S, name, fallback)
if isfield(S,name) && ~isempty(S.(name)), v = S.(name); else, v = fallback; end
end
