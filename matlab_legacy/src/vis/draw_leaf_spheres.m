function h = draw_leaf_spheres(XYZ, health, varargin)
%DRAW_LEAF_SPHERES  Render leaves as small spheres colored by health.
%   h = DRAW_LEAF_SPHERES(XYZ, health, 'radius',0.25, 'mode','scatter'|'surf', ...)
%   XYZ: Nx3 positions [x y z]
%   health: Nx1 in [0,1] (1=healthy). Scalar -> broadcast.

% ---- Parse opts
p = inputParser;
p.addParameter('radius', 0.25,  @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('mode',   'scatter', @(s)ischar(s)||isstring(s));
p.addParameter('Alpha',  0.95, @(a)isnumeric(a)&&isscalar(a)&&a>=0&&a<=1);
p.addParameter('Axes',   [], @(h)isempty(h)||(ishandle(h)&&strcmp(get(h,'Type'),'axes')));
p.addParameter('Colormap','rgYg', @(s)ischar(s)||isstring(s)||isa(s,'function_handle'));
p.addParameter('Clim',   [0 1], @(v)isnumeric(v)&&numel(v)==2&&v(1)<v(2));
p.parse(varargin{:});
r      = p.Results.radius;
mode   = lower(string(p.Results.mode));
alphaV = p.Results.Alpha;
ax     = p.Results.Axes;
cmap   = p.Results.Colormap;
climV  = p.Results.Clim;

% ---- Validate inputs
if size(XYZ,2)~=3, error('draw_leaf_spheres:XYZ','XYZ must be Nx3.'); end
N = size(XYZ,1);
if isscalar(health)
    health = repmat(health, N, 1);
else
    health = health(:);
    if numel(health)~=N, error('draw_leaf_spheres:health','health must be scalar or Nx1.'); end
end
% clamp health to [0,1]
health = max(0, min(1, health));

% ---- Axes
if isempty(ax), ax = gca; end
try, ax.SortMethod = 'childorder'; end

% ---- Colormap function
% default: red -> yellow -> green (percettivamente più chiaro al centro)
if isa(cmap,'function_handle')
    C = cmap(health);
else
    switch lower(string(cmap))
        case "rg"
            % semplice rosso->verde
            C = [1-health, health, zeros(N,1)];
        case "rgy"
            % rosso->giallo->verde
            C = [ones(N,1), min(1,health*2), max(0,1-health*2)];
        case "rgyg"
            % rosso->giallo->verde (più morbido)
            g = health;
            C = [ones(N,1)-g, 0.9*g + 0.1, max(0,0.2*(1-g))];
        otherwise % "rgYg"
            g = health;
            % rosso (malato) → giallo → verde (sano), senza discontinuità
            R = 1 - 0.6*g;
            G = 0.2 + 0.8*g;
            B = 0.1*(1-g);
            C = [R,G,B];
    end
end
C = max(0,min(1,C));

% ---- Draw
switch mode
    case "scatter"
        % Nota: la size di scatter è in punti^2, non in metri.
        % r->size: fattore empirico per avere proporzione visiva accettabile.
        sz = (r * 80); % puoi esporre come opzione se vuoi fine tuning
        h = scatter3(ax, XYZ(:,1), XYZ(:,2), XYZ(:,3), sz, C, 'filled', ...
            'Marker','o', 'Tag','leaf_scatter', 'DisplayName','leaves');
        if ~isempty(alphaV), try, h.MarkerFaceAlpha = alphaV; catch, alpha(h,alphaV); end, end
        % mappa colori coerente per legend/CB
        colormap(ax, 'parula'); % non influisce su CData per scatter filled, ma utile per CB
        caxis(ax, climV);

    case "surf"
        % Generiamo una singola sfera prototipo e la replichiamo
        [sx,sy,sz] = sphere(10);   % 11x11 grid
        sx = r*sx; sy = r*sy; sz = r*sz;
        % hggroup per avere un solo handle
        hg = hggroup('Parent', ax, 'Tag','leaf_spheres', 'DisplayName','leaves');
        for i = 1:N
            X = sx + XYZ(i,1);
            Y = sy + XYZ(i,2);
            Z = sz + XYZ(i,3);
            s = surf(ax, X, Y, Z, ...
                'FaceColor', C(i,:), 'EdgeColor','none', 'FaceAlpha', alphaV, ...
                'Parent', hg);
        end
        shading(ax, 'interp');
        h = hg;

    otherwise
        error('draw_leaf_spheres:mode','Unknown mode: %s', mode);
end
end
