function [ax, hGround] = draw_field3d(opts)
%DRAW_FIELD3D  Set up a 3D crop field scene.
%   ax = DRAW_FIELD3D(opts)
%   [ax,hGround] = DRAW_FIELD3D(opts)
%
%   opts.xlim, opts.ylim, opts.zlim
%   opts.bg        : background color (default [1 1 1])
%   opts.ground    : ground color (default [0.98 0.98 0.98])
%   opts.grid      : grid line color (default [0.85 0.85 0.85])
%   opts.groundAlpha : alpha for ground plane (default 1)
%   opts.drawGrid  : true/false (default true)
%   opts.newFigure : true/false (default false)  % crea nuova figura
%   opts.ax        : existing axes handle to draw into (default: create new axes)

if nargin<1, opts = struct; end
opts = defv(opts,'xlim',[0 200]);
opts = defv(opts,'ylim',[0 200]);
opts = defv(opts,'zlim',[0 8]);
opts = defv(opts,'bg',[1 1 1]);
opts = defv(opts,'ground',[0.98 0.98 0.98]);
opts = defv(opts,'grid',[0.85 0.85 0.85]);
opts = defv(opts,'groundAlpha', 1);
opts = defv(opts,'drawGrid', true);
opts = defv(opts,'newFigure', false);
opts = defv(opts,'ax', []);

% --- figura / axes
if opts.newFigure && isempty(opts.ax)
    figure('Color', opts.bg, 'Renderer','opengl');  % renderer 3D
end
if isempty(opts.ax) || ~ishandle(opts.ax) || ~strcmp(get(opts.ax,'Type'),'axes')
    ax = axes('NextPlot','add'); 
else
    ax = opts.ax;
    axes(ax);
end

% --- stile axes
axis(ax, 'vis3d');
xlim(ax, opts.xlim); ylim(ax, opts.ylim); zlim(ax, opts.zlim);
view(ax, 35, 20);
if opts.drawGrid
    grid(ax, 'on');
else
    grid(ax, 'off');
end
box(ax, 'on');
ax.GridColor = opts.grid;
ax.Color     = opts.bg;
ax.Projection = 'perspective';  % migliore per 3D outdoor
% Sorting utile con molte patch sovrapposte
try, ax.SortMethod = 'childorder'; end %#ok<TRYNC>

xlabel(ax,'X (m)'); ylabel(ax,'Y (m)'); zlabel(ax,'Height (m)');
if isempty(get(ax,'Title')) || isempty(get(get(ax,'Title'),'String'))
    title(ax,'Crop Field (3D)');
end

% --- ground plane (leggermente sollevato per evitare z-fighting)
[X,Y] = meshgrid(linspace(opts.xlim(1),opts.xlim(2),2), ...
                 linspace(opts.ylim(1),opts.ylim(2),2));
Z = zeros(size(X)) + eps;  % epsilon sopra z=0
hGround = surf(ax, X, Y, Z, ...
    'FaceColor', opts.ground, 'EdgeColor','none', 'FaceAlpha', opts.groundAlpha);

% --- soft lights
camlight(ax, 'headlight'); 
lighting(ax, 'gouraud');

end

function S = defv(S, f, v)
if ~isfield(S,f) || isempty(S.(f)), S.(f) = v; end
end
