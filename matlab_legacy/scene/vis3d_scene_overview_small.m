function [ax, S] = vis3d_scene_overview_small(opts)
%VIS3D_SCENE_OVERVIEW_SMALL  Crea la scena 3D (campo + alberi) come nel tuo script.
% USO:
%   [ax,S] = vis3d_scene_overview_small();                 % default
%   [ax,S] = vis3d_scene_overview_small(struct('XL',[0 300],'YL',[0 250],'N_TREES',80));
%
% RITORNA:
%   ax : handle assi 3D
%   S  : struct con limiti campo, base, info alberi e handles grafici
%
% Dipendenze: startup (opzionale), config, draw_field3d, generate_trees,
%             draw_ground_shadows, draw_leaf_spheres

if nargin < 1, opts = struct; end

% --- Setup base (opzionale: se non vuoi chiamarlo qui, imposta opts.do_startup=false)
do_startup = getOpt(opts,'do_startup',true);
if do_startup
    try startup; catch, end %#ok<CTCH>
end
C = config();

%% === Manopole veloci ===
FIG_POS = getOpt(opts,'FIG_POS',[120 120 980 620]);    % [left bottom width height]
AX_POS  = getOpt(opts,'AX_POS' ,[0.12 0.12 0.76 0.76]);
ZOOM_K  = getOpt(opts,'ZOOM_K' ,1.18);                 % >1 = zoom-out

%% === Parametri scena ===
XL = getOpt(opts,'XL',[0 200]);
YL = getOpt(opts,'YL',[0 200]);
ZL = getOpt(opts,'ZL',[0 C.vision.altitude_m]);

N_TREES          = getOpt(opts,'N_TREES',55);
LEAVES_PER_TREE  = getOpt(opts,'LEAVES_PER_TREE' ,[140 260]);
HEIGHT_RANGE     = getOpt(opts,'HEIGHT_RANGE'    ,[3 7]);
CANOPY_BASE_FRAC = getOpt(opts,'CANOPY_BASE_FRAC',[0.60 0.80]);
MIN_CLEARANCE    = getOpt(opts,'MIN_CLEARANCE'   ,2.0);
CROWN_RADIUS_XY  = getOpt(opts,'CROWN_RADIUS_XY' ,[2.5 6.0]);
SHAPE_POWER      = getOpt(opts,'SHAPE_POWER'     ,[1.7 2.3]);
LOBES            = getOpt(opts,'LOBES'           ,[1 3]);
LEAF_JITTER      = getOpt(opts,'LEAF_JITTER'     ,0.12);

DRAW_TRUNKS = getOpt(opts,'DRAW_TRUNKS',C.vis3d.draw_trunks);
LEAF_RADIUS = getOpt(opts,'LEAF_RADIUS',C.vis3d.leaf_radius);
LEAF_MODE   = getOpt(opts,'LEAF_MODE'  ,C.vis3d.leaf_mode);

% RNG (riproducibilità): 'shuffle' oppure un intero
rng_seed = getOpt(opts,'RNGSeed','shuffle');
rng(rng_seed);

%% === Figura / Assi =======================================================
clf;
f = gcf;
set(f,'Units','pixels','Position',FIG_POS,'WindowState','normal','Renderer','opengl');
set(f,'GraphicsSmoothing','on');

ax = draw_field3d(struct('xlim',XL,'ylim',YL,'zlim',ZL));
set(ax,'Units','normalized','Position',AX_POS,'SortMethod','childorder');
set(ax,'LooseInset', max(get(ax,'TightInset'), 0.04));    % margini per evitare tagli

% Esagerazione verticale e stile base
xySpan = max(diff(XL), diff(YL));
zSpan  = max(diff(ZL), eps);
exag   = (xySpan/zSpan) * C.vis3d.z_exaggeration_target;
daspect(ax,[1 1 1/exag]);
pbaspect(ax,[1 1 1]);
axis(ax,'vis3d'); grid(ax,'on'); box(ax,'on'); hold(ax,'on');
view(ax,35,20);

% Zoom ottico UNA SOLA VOLTA (zoom-out)
set(ax,'CameraViewAngleMode','manual');
ax.CameraViewAngle = ax.CameraViewAngle * ZOOM_K;

% Un filo di padding manuale sui limiti
padXY = 4; padZ = 1;
xlim(ax, [XL(1)-padXY, XL(2)+padXY]);
ylim(ax, [YL(1)-padXY, YL(2)+padXY]);
zlim(ax, [ZL(1),       ZL(2)+padZ]);

title(ax,'3D Scene');
set(ax,'FontName','Helvetica','FontSize',10,'LineWidth',1.0);
xlabel(ax,'X (m)'); ylabel(ax,'Y (m)'); zlabel(ax,'Z (m)');

%% === Ambiente: alberi / ombre / foglie ==================================
[XYZ_leaf, health_leaf, trees] = generate_trees([XL; YL; ZL], N_TREES, ...
    'LeavesPerTree',      LEAVES_PER_TREE, ...
    'HeightRange',        HEIGHT_RANGE, ...
    'CanopyBaseFrac',     CANOPY_BASE_FRAC, ...
    'MinCanopyClearance', MIN_CLEARANCE, ...
    'CrownRadiusXY',      CROWN_RADIUS_XY, ...
    'ShapePower',         SHAPE_POWER, ...
    'Lobes',              LOBES, ...
    'LeafJitter',         LEAF_JITTER);

zOverlay = 2*eps;
centers = reshape([trees.center],3,[])';
hShadows = draw_ground_shadows(centers(:,1:2), [trees.rXY]'*1.1, 'Z', zOverlay);
hLeaves  = draw_leaf_spheres(XYZ_leaf, health_leaf, 'radius', LEAF_RADIUS, 'mode', LEAF_MODE);

hTrunks = gobjects(0);
if DRAW_TRUNKS
    hTrunks = gobjects(numel(trees),1);
    for k=1:numel(trees)
        T = trees(k).trunk;
        hTrunks(k) = plot3(ax, T(:,1), T(:,2), T(:,3), '-', ...
            'Color',[0.25 0.25 0.25], 'LineWidth',1.0, ...
            'HandleVisibility','off');
    end
end

%% === Uscite comode =======================================================
baseXY = [(XL(1)+XL(2))/2, (YL(1)+YL(2))/2]; % centro campo

S = struct();
S.field.XL = XL; S.field.YL = YL; S.field.ZL = ZL;
S.base.xy  = baseXY;
S.trees.leafXYZ    = XYZ_leaf;
S.trees.leafHealth = health_leaf;
S.trees.objects    = trees;
S.handles.shadows  = hShadows;
S.handles.leaves   = hLeaves;
S.handles.trunks   = hTrunks;
S.params = struct('FIG_POS',FIG_POS,'AX_POS',AX_POS,'ZOOM_K',ZOOM_K, ...
                  'N_TREES',N_TREES,'RNGSeed',rng_seed);

end

% --- utility locale per leggere un campo con default ---
function v = getOpt(s, name, default)
if isfield(s,name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end
