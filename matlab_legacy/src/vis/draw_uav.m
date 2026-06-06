% EXTRA

function h = draw_uav(pose, opts)
%DRAW_UAV  Draw a top-view stylized quadrotor at pose [x y (z) yaw].
%   h = DRAW_UAV([x y yaw], opts)
%   h = DRAW_UAV([x y z yaw], opts)
%
%   opts.size       : arm span (default 1.2 m)
%   opts.color      : body/rotor color (default [0.1 0.2 0.8])
%   opts.Z          : override Z if pose is 2D (default eps)
%   opts.RotorAlpha : 0..1 face alpha for rotors (default 0.15)
%   opts.LineWidth  : arms linewidth (default 2)
%   opts.Ax         : target axes (default gca)
%   opts.HeadingColor : color for heading line (default [0 0 0])

if nargin<2, opts = struct; end
opts = setDefault(opts,'size',        1.2);
opts = setDefault(opts,'color',       [0.1 0.2 0.8]);
opts = setDefault(opts,'Z',           eps);
opts = setDefault(opts,'RotorAlpha',  0.15);
opts = setDefault(opts,'LineWidth',   2);
opts = setDefault(opts,'HeadingColor',[0 0 0]);
opts = setDefault(opts,'Ax',          []);

% ---- Parse pose
pose = pose(:).';
if numel(pose)==3
    x = pose(1); y = pose(2); z = opts.Z; th = pose(3);
elseif numel(pose)==4
    x = pose(1); y = pose(2); z = pose(3); th = pose(4);
else
    error('draw_uav:pose','pose must be [x y yaw] or [x y z yaw].');
end

% ---- Axes
ax = opts.Ax;
if isempty(ax), ax = gca; end
try, ax.SortMethod = 'childorder'; end

s  = opts.size;
R2 = [cos(th) -sin(th); sin(th) cos(th)];

% body (X frame)
arm  = s*0.5;
body = [-arm 0; arm 0; 0 0; 0 -arm; 0 arm];
B = (R2*body')'; B(:,1)=B(:,1)+x; B(:,2)=B(:,2)+y;

% rotors geometry
rot      = s*0.15;
rotor_xy = rot*circlePts(25);
rotors   = [arm 0; -arm 0; 0 arm; 0 -arm];

% ---- Drawing (as 3D to avoid z-fighting with ground)
holdState = ishold(ax); hold(ax,'on');
hg = hggroup('Parent',ax,'Tag','uav','DisplayName','UAV');

% arms
line(ax, [B(1,1) B(2,1)], [B(1,2) B(2,2)], [z z], ...
    'Color',opts.color,'LineWidth',opts.LineWidth,'Parent',hg);
line(ax, [x x], [y-arm y+arm], [z z], ...
    'Color',opts.color,'LineWidth',opts.LineWidth,'Parent',hg);

% rotors
for i=1:4
    rxy = (R2*rotor_xy')' + rotors(i,:) + [x y];
    patch('XData',rxy(:,1),'YData',rxy(:,2),'ZData',z*ones(size(rxy,1),1), ...
        'FaceColor',opts.color,'FaceAlpha',opts.RotorAlpha, ...
        'EdgeColor',opts.color,'Parent',hg);
end

% heading
hd = (R2*[s*0.7; 0])' + [x y];
line(ax,[x hd(1)],[y hd(2)],[z z], 'Color',opts.HeadingColor,'LineWidth',1.2,'Parent',hg);

if ~holdState, hold(ax,'off'); end
h = hg;
end

% ---- helpers (local)
function xy = circlePts(n)
t = linspace(0,2*pi,n)'; xy = [cos(t) sin(t)];
end

function S = setDefault(S, field, val)
if ~isfield(S, field) || isempty(S.(field)), S.(field) = val; end
end
