% VIS3D_SCENE_OVERVIEW_small — Scena 3D statica, finestra e plot ridotti (pulita)
clear; clc;
startup;
C = config();

%% === Manopole veloci ===
FIG_POS = [120 120 980 620];       % [left bottom width height] finestra
AX_POS  = [0.12 0.12 0.76 0.76];   % [l b w h] riquadro assi (margini interni)
ZOOM_K  = 1.18;                    % >1 = zoom-out (plot più “piccolo” nella finestra)

%% === Parametri scena ===
XL = [0 200]; YL = [0 200]; ZL = [0 C.vision.altitude_m];
N_TREES = 55;
LEAVES_PER_TREE  = [140 260];
HEIGHT_RANGE     = [3 7];
CANOPY_BASE_FRAC = [0.60 0.80];
MIN_CLEARANCE    = 2.0;
CROWN_RADIUS_XY  = [2.5 6.0];
SHAPE_POWER      = [1.7 2.3];
LOBES            = [1 3];
LEAF_JITTER      = 0.12;

DRAW_TRUNKS = C.vis3d.draw_trunks;
LEAF_RADIUS = C.vis3d.leaf_radius;
LEAF_MODE   = C.vis3d.leaf_mode;

%% === Figura / Assi =======================================================
clf;
f = gcf;
set(f,'Units','pixels','Position',FIG_POS,'WindowState','normal','Renderer','opengl');
set(f,'GraphicsSmoothing','on');

ax = draw_field3d(struct('xlim',XL,'ylim',YL,'zlim',ZL));
set(ax,'Units','normalized','Position',AX_POS,'SortMethod','childorder');
set(ax,'LooseInset', max(get(ax,'TightInset'), 0.04));    % margini per evitare tagli

% Esagerazione verticale e stile base
xySpan = max(diff(xlim(ax)), diff(ylim(ax)));
zSpan  = max(diff(zlim(ax)), eps);
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
rng('shuffle');
[XYZ_leaf, health_leaf, trees] = generate_trees([XL; YL; ZL], N_TREES, ...
    'LeavesPerTree',     LEAVES_PER_TREE, ...
    'HeightRange',       HEIGHT_RANGE, ...
    'CanopyBaseFrac',    CANOPY_BASE_FRAC, ...
    'MinCanopyClearance',MIN_CLEARANCE, ...
    'CrownRadiusXY',     CROWN_RADIUS_XY, ...
    'ShapePower',        SHAPE_POWER, ...
    'Lobes',             LOBES, ...
    'LeafJitter',        LEAF_JITTER);

zOverlay = 2*eps;
centers = reshape([trees.center],3,[])';
draw_ground_shadows(centers(:,1:2), [trees.rXY]'*1.1, 'Z', zOverlay);

draw_leaf_spheres(XYZ_leaf, health_leaf, 'radius', LEAF_RADIUS, 'mode', LEAF_MODE);

if DRAW_TRUNKS
    for k=1:numel(trees)
        T = trees(k).trunk;
        plot3(ax, T(:,1), T(:,2), T(:,3), '-', ...
            'Color',[0.25 0.25 0.25], 'LineWidth',1.0, ...
            'HandleVisibility','off');
    end
end
