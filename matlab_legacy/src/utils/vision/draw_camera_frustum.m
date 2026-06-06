function h = draw_camera_frustum(cam, pose, style, varargin)
%DRAW_CAMERA_FRUSTUM  Plot camera volume (frustum rettangolare o cono tondo).
% h = DRAW_CAMERA_FRUSTUM(cam, [x y z yaw pitch roll], style, ...
%        'zExag', exag, 'wire', true, 'mode','frustum'|'cone','segments',32, ...
%        'draw_center', false)
%
% style: struct('face',[.2 .4 1],'alpha',0.25,'edge',[.1 .2 .6])

p = inputParser;
p.addParameter('zExag', 1.0, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('wire', true, @(x)islogical(x)||ismember(x,[0 1]));
p.addParameter('mode','frustum', @(s)ischar(s)||isstring(s));
p.addParameter('segments', 32, @(n)isnumeric(n)&&isscalar(n)&&n>=8);
p.addParameter('draw_center', false, @(x)islogical(x)||ismember(x,[0 1]));
p.parse(varargin{:});
zExag     = p.Results.zExag;
wantWire  = p.Results.wire;
mode      = lower(string(p.Results.mode));
Nseg      = p.Results.segments;
drawCenter= logical(p.Results.draw_center);

if nargin<3 || isempty(style), style = struct; end
style = defv(style,'face',[0.2 0.4 1]);
style = defv(style,'alpha',0.25);
style = defv(style,'edge',[0.1 0.2 0.6]);

% Geometria in camera frame (+Z in avanti)
switch mode
    case "frustum"  % rettangolare
        [V,F] = camera_frustum_vertices(cam, pose);
    case "cone"     % frustum circolare usando un FOV unico
        th = tan(deg2rad(cam.hfov_deg/2));
        tv = tan(deg2rad(cam.vfov_deg/2));
        tf = sqrt(th^2 + tv^2);
        fov_uni = 2*atan(tf);  % rad
        [V,F] = cone_vertices(cam.range_min, cam.range_max, fov_uni, pose, Nseg);
    otherwise
        error('draw_camera_frustum: mode non riconosciuto: %s', mode);
end

% Compensa l'esagerazione verticale (solo resa a video)
if zExag~=1
    V(:,3) = V(:,3) * zExag;
end

% Disegno patch
h = struct('patch',[], 'wire',gobjects(0), 'center',gobjects(0));
h.patch = patch('Vertices',V, 'Faces',F, ...
          'FaceColor',style.face, 'FaceAlpha',style.alpha, ...
          'EdgeColor',style.edge);

% (opzionale) Centro camera
if drawCenter
    h.center = plot3(pose(1), pose(2), pose(3)*zExag, ...
                     'bx', 'MarkerSize',8, 'LineWidth',1.2, ...
                     'HandleVisibility','off');
end

% Wireframe leggero (opzionale)
if wantWire
    holdstate = ishold; hold on;
    if mode=="frustum"
        idx = [1 2 3 4 1 5 6 7 8 5];
        hw1 = plot3(V(idx,1),V(idx,2),V(idx,3),'-','Color',[0 0 0],'LineWidth',0.5,'HandleVisibility','off');
        hw2 = plot3([V(2,1) V(6,1)],[V(2,2) V(6,2)],[V(2,3) V(6,3)],'-','Color',[0 0 0],'LineWidth',0.5,'HandleVisibility','off');
        hw3 = plot3([V(3,1) V(7,1)],[V(3,2) V(7,2)],[V(3,3) V(7,3)],'-','Color',[0 0 0],'LineWidth',0.5,'HandleVisibility','off');
        h.wire = [hw1; hw2; hw3];
    else
        k = 0:(Nseg-1); k2 = mod(k+1,Nseg); o = Nseg;
        hw1 = plot3(V(k+1,1), V(k+1,2), V(k+1,3), '-', 'Color',[0 0 0], 'LineWidth',0.5,'HandleVisibility','off');
        hw2 = plot3(V(k2+1,1), V(k2+1,2), V(k2+1,3), '-', 'Color',[0 0 0], 'LineWidth',0.5,'HandleVisibility','off');
        hw3 = plot3(V(o+k+1,1), V(o+k+1,2), V(o+k+1,3), '-', 'Color',[0 0 0], 'LineWidth',0.5,'HandleVisibility','off');
        h.wire = [hw1; hw2; hw3];
    end
    if ~holdstate, hold off; end
end
end

function S = defv(S,f,v), if ~isfield(S,f), S.(f)=v; end, end

function [Vw,F] = cone_vertices(zn,zf,fov,pose,N)
rn = zn*tan(fov/2);  rf = zf*tan(fov/2);
ang = linspace(0,2*pi,N+1)'; ang(end)=[];
near = [rn*cos(ang), rn*sin(ang), zn*ones(N,1)];
far  = [rf*cos(ang), rf*sin(ang), zf*ones(N,1)];

F = zeros(2*N,3);
for i=1:N
    i2 = mod(i,N)+1;
    F(2*i-1,:) = [i, i2, N+i2];
    F(2*i,:)   = [i, N+i2, N+i];
end
V = [near; far];

R = Rzyx(pose(4), pose(5), pose(6));
trow = reshape(pose(1:3), 1, 3);
Vw = V * R.'; 
Vw = bsxfun(@plus, Vw, trow);

F = unique(F,'rows');
F = F(all(F>0,2),:);
end

function R = Rzyx(yaw,pitch,roll)
cy=cos(yaw); sy=sin(yaw);
cp=cos(pitch); sp=sin(pitch);
cr=cos(roll);  sr=sin(roll);
Rz=[cy -sy 0; sy cy 0; 0 0 1];
Ry=[cp 0 sp; 0 1 0; -sp 0 cp];
Rx=[1 0 0; 0 cr -sr; 0 sr cr];
R = Rz*Ry*Rx;
end
