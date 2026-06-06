%EXTRA 

function h = draw_uav_cone(center, height, radius, opts)
%DRAW_UAV_CONE  Blue sensing cone standing on ground and pointing up.
%   h = DRAW_UAV_CONE([x y], height, radius, opts)
%   Options (Name-Value in struct 'opts'):
%     .color     : [r g b], face color (default [0.2 0.4 1.0])
%     .alpha     : 0..1, face alpha (default 0.35)
%     .edgeColor : [r g b] or 'none' (default 'none')
%     .wire      : true/false (draw edges only; default false)
%     .segments  : integer >= 12 (default 48)
%     .zBase     : scalar base Z (default eps)   % evita z-fighting col terreno
%     .cap       : true/false draw base disk (default false)
%     .ax        : target axes (default gca)
%     .tipMarker : true/false (default false)
%
%   h: hggroup handle containing the cone (and optional cap/tip)

if nargin<4, opts = struct; end
opts = defv(opts,'color',[0.2 0.4 1.0]);
opts = defv(opts,'alpha',0.35);
opts = defv(opts,'edgeColor','none');
opts = defv(opts,'wire',false);
opts = defv(opts,'segments',48);
opts = defv(opts,'zBase',eps);
opts = defv(opts,'cap',false);
opts = defv(opts,'ax',[]);
opts = defv(opts,'tipMarker',false);

ax = opts.ax; if isempty(ax), ax = gca; end
try, ax.SortMethod = 'childorder'; end

x0 = center(1); y0 = center(2);
n  = max(12, round(opts.segments));
t  = linspace(0, 2*pi, n+1); t(end) = [];   % n punti base
xb = x0 + radius*cos(t); 
yb = y0 + radius*sin(t);
zb = ones(1,n) * opts.zBase;

xa = x0; ya = y0; za = opts.zBase + height;

% --- Geometria triangolata: n triangoli lato (apice, base i, base i+1)
% Vertici: [base(1..n); apex]
V = [xb(:), yb(:), zb(:); xa, ya, za];

% Facce lato
apexIdx = n+1;
F = zeros(n, 3);
for i = 1:n
    i2 = i+1; if i2>n, i2 = 1; end
    F(i,:) = [apexIdx, i, i2];
end

% --- Disegno
holdState = ishold(ax); hold(ax, 'on');
hg = hggroup('Parent', ax, 'Tag','uav_cone', 'DisplayName','UAV Cone');

if opts.wire
    % wireframe: disegniamo gli spigoli della superficie
    % Lati
    for i=1:n
        i2 = i+1; if i2>n, i2=1; end
        line(ax, [xb(i) xb(i2)], [yb(i) yb(i2)], [zb(i) zb(i2)], ...
            'Color', opts.edgeColor, 'Parent', hg);
        line(ax, [xb(i) xa], [yb(i) ya], [zb(i) za], ...
            'Color', opts.edgeColor, 'Parent', hg);
    end
else
    % superficie singola triangolata
    patch('Faces', F, 'Vertices', V, ...
          'FaceColor', opts.color, 'FaceAlpha', opts.alpha, ...
          'EdgeColor', opts.edgeColor, ...
          'Parent', hg);
end

% --- Cap (disco base) opzionale
if opts.cap
    % triangolazione fan rispetto al baricentro base
    xc = mean(xb); yc = mean(yb); zc = opts.zBase;
    Vcap = [xc yc zc; xb(:) yb(:) zb(:)];
    Fcap = zeros(n, 3);
    for i=1:n
        i2 = i+1; if i2>n, i2=1; end
        Fcap(i,:) = [1, i+1, i2+1];
    end
    patch('Faces',Fcap, 'Vertices',Vcap, ...
          'FaceColor', opts.color, 'FaceAlpha', max(0, min(1, opts.alpha*0.6)), ...
          'EdgeColor','none', 'Parent', hg);
end

% --- Tip marker opzionale
if opts.tipMarker
    plot3(ax, xa, ya, za, '.', 'Color', opts.color, 'MarkerSize', 18, 'Parent', hg);
end

if ~holdState, hold(ax, 'off'); end
h = hg;
end

function S = defv(S, f, v)
if ~isfield(S,f) || isempty(S.(f)), S.(f) = v; end
end
