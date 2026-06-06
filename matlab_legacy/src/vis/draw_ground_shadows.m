function h = draw_ground_shadows(XY, radius, varargin)
%DRAW_GROUND_SHADOWS  Gray circular patches on ground at z≈0 to mimic canopies.
%   h = DRAW_GROUND_SHADOWS(XY, radius, 'Name',Value,...)
%   XY: Nx2; radius: scalar or Nx1
%
%   Options:
%     'Color'    : [r g b]     (default [0.85 0.85 0.85])
%     'Alpha'    : 0..1        (default 0.5)
%     'Z'        : scalar z    (default eps)  % evita z-fighting con il ground
%     'Segments' : integer >=8 (default 30)
%     'Ax'       : axes handle (default gca)

% ---- Parse & validate
p = inputParser;
p.addParameter('Color', [0.85 0.85 0.85], @(c)isnumeric(c)&&numel(c)==3);
p.addParameter('Alpha', 0.5, @(a)isnumeric(a)&&isscalar(a)&&a>=0&&a<=1);
p.addParameter('Z', eps, @(z)isnumeric(z)&&isscalar(z));
p.addParameter('Segments', 30, @(n)isnumeric(n)&&isscalar(n)&&n>=8);
p.addParameter('Ax', [], @(h) isempty(h) || (ishandle(h) && strcmp(get(h,'Type'),'axes')));
p.parse(varargin{:});
clr   = p.Results.Color;
alp   = p.Results.Alpha;
Z0    = p.Results.Z;
nSeg  = round(p.Results.Segments);
ax    = p.Results.Ax;
if isempty(ax), ax = gca; end

% ---- Inputs
if size(XY,2) ~= 2
    error('draw_ground_shadows:XY','XY must be Nx2.');
end
N = size(XY,1);
if isscalar(radius)
    radius = repmat(radius, N, 1);
else
    if ~isvector(radius) || numel(radius) ~= N
        error('draw_ground_shadows:radius','radius must be scalar or Nx1 matching XY.');
    end
    radius = radius(:);
end

% ---- Circle prototype
theta = linspace(0, 2*pi, nSeg);
ux = cos(theta); uy = sin(theta);

% ---- Draw
holdState = ishold(ax);
hold(ax, 'on');
h = gobjects(N,1);
for i = 1:N
    x = XY(i,1) + radius(i)*ux;
    y = XY(i,2) + radius(i)*uy;
    z = ones(1, numel(x)) * Z0;
    h(i) = patch('XData', x, 'YData', y, 'ZData', z, ...
        'FaceColor', clr, 'EdgeColor', 'none', 'FaceAlpha', alp, ...
        'Parent', ax, 'Tag', 'ground_shadow', 'DisplayName', 'Canopy footprint');
end
if ~holdState, hold(ax, 'off'); end
end
