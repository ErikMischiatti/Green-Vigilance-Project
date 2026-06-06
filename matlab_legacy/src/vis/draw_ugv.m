%NON IMPIEGATA IN VIS3D_STATIC

function h = draw_ugv(pose, opts)
%DRAW_UGV  Draw a stylized differential-drive rover at pose [x y (z) yaw].
%   h = DRAW_UGV([x y yaw], opts)
%   h = DRAW_UGV([x y z yaw], opts)
%
%   opts.size        : body length L (default 0.9 m)
%   opts.color       : body color (default [0.2 0.6 0.2])
%   opts.Z           : override Z if pose is 2D (default eps)
%   opts.Wfrac       : body width as L*Wfrac (default 0.6)
%   opts.WheelFrac   : wheel thickness as W*WheelFrac (default 0.18)
%   opts.BodyAlpha   : body face alpha (default 0.2)
%   opts.EdgeWidth   : body edge width (default 1.5)
%   opts.TireColor   : wheel face color (default 0.2*[1 1 1])
%   opts.TireEdge    : wheel edge color (default 'k')
%   opts.HeadingColor: heading line color (default [0 0 0])
%   opts.Ax          : target axes (default gca)

if nargin<2, opts = struct; end
opts = setDefault(opts,'size',        0.9);
opts = setDefault(opts,'color',       [0.2 0.6 0.2]);
opts = setDefault(opts,'Z',           eps);
opts = setDefault(opts,'Wfrac',       0.6);
opts = setDefault(opts,'WheelFrac',   0.18);
opts = setDefault(opts,'BodyAlpha',   0.2);
opts = setDefault(opts,'EdgeWidth',   1.5);
opts = setDefault(opts,'TireColor',   0.2*[1 1 1]);
opts = setDefault(opts,'TireEdge',    'k');
opts = setDefault(opts,'HeadingColor',[0 0 0]);
opts = setDefault(opts,'Ax',          []);

% ---- Parse pose
pose = pose(:).';
if numel(pose)==3
    x = pose(1); y = pose(2); z = opts.Z; th = pose(3);
elseif numel(pose)==4
    x = pose(1); y = pose(2); z = pose(3); th = pose(4);
else
    error('draw_ugv:pose','pose must be [x y yaw] or [x y z yaw].');
end

% ---- Axes
ax = opts.Ax; if isempty(ax), ax = gca; end
try, ax.SortMethod = 'childorder'; end

L  = opts.size; 
W  = L*opts.Wfrac;

R2 = [cos(th) -sin(th); sin(th) cos(th)];

% body rectangle in robot frame
body = [-L/2 -W/2; L/2 -W/2; L/2 W/2; -L/2 W/2];
body = (R2*body')'; body(:,1)=body(:,1)+x; body(:,2)=body(:,2)+y;

% wheels (simple rectangular tracks)
tw = W*opts.WheelFrac; 
lw = [-L/2 -W/2-tw; L/2 -W/2-tw; L/2 -W/2; -L/2 -W/2];
rw = [-L/2  W/2;    L/2  W/2;    L/2  W/2+tw; -L/2  W/2+tw];
lw = (R2*lw')'; rw=(R2*rw')';
lw(:,1)=lw(:,1)+x; lw(:,2)=lw(:,2)+y; 
rw(:,1)=rw(:,1)+x; rw(:,2)=rw(:,2)+y;

% ---- Draw (3D, single group handle)
holdState = ishold(ax); hold(ax,'on');
hg = hggroup('Parent',ax,'Tag','ugv','DisplayName','UGV');

patch('XData',body(:,1),'YData',body(:,2),'ZData',z*ones(4,1), ...
      'FaceColor',opts.color,'FaceAlpha',opts.BodyAlpha, ...
      'EdgeColor',opts.color,'LineWidth',opts.EdgeWidth, 'Parent',hg);

patch('XData',lw(:,1),'YData',lw(:,2),'ZData',z*ones(4,1), ...
      'FaceColor',opts.TireColor,'EdgeColor',opts.TireEdge, 'Parent',hg);
patch('XData',rw(:,1),'YData',rw(:,2),'ZData',z*ones(4,1), ...
      'FaceColor',opts.TireColor,'EdgeColor',opts.TireEdge, 'Parent',hg);

% heading
hd = (R2*[L/2; 0])' + [x y];
plot3(ax,[x hd(1)],[y hd(2)],[z z],'Color',opts.HeadingColor,'LineWidth',1.2,'Parent',hg);

if ~holdState, hold(ax,'off'); end
h = hg;
end

function S = setDefault(S, field, val)
if ~isfield(S, field) || isempty(S.(field)), S.(field) = val; end
end
