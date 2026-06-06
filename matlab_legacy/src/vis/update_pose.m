%NON IMPIEGATA IN VIS3D_STATIC

function T = update_pose(h, pose, varargin)
%UPDATE_POSE  Update graphics pose via hgtransform (no redraw).
%   T = UPDATE_POSE(h, pose, 'Mode','absolute'|'delta')
%   pose: [x y yaw] or [x y z yaw]
%
%   Returns the hgtransform handle T used for the object (so puoi riusarlo).
%
%   Note:
%   - Funziona al meglio se l'oggetto è disegnato in coordinate locali ~[0,0,0]
%     e lo posizioni SOLO via questa funzione (o passando h = hgtransform).
%   - Se l'oggetto è già posizionato in coordinate globali “assolute” dal draw,
%     il primo wrap in hgtransform manterrà la posizione corrente come baseline
%     e da lì in poi gli aggiornamenti saranno coerenti.

% ---- options
p = inputParser;
p.addParameter('Mode','absolute',@(s)ischar(s)||isstring(s)); % 'absolute'|'delta'
p.parse(varargin{:});
mode = lower(string(p.Results.Mode));

% ---- normalize pose
pose = pose(:).';
switch numel(pose)
    case 3, x=pose(1); y=pose(2); z=0;       yaw=pose(3);
    case 4, x=pose(1); y=pose(2); z=pose(3); yaw=pose(4);
    otherwise, error('update_pose:pose','pose must be [x y yaw] or [x y z yaw].');
end

% ---- find or create hgtransform
if isgraphics(h,'hgtransform')
    T = h;
else
    % cerca un ancestor hgtransform
    T = ancestor(h,'hgtransform');
    if isempty(T)
        ax = ancestor(h,'axes');
        if isempty(ax), ax = gca; end
        % crea un wrapper hgtransform sopra l'oggetto
        T = hgtransform('Parent', ax);
        set(h, 'Parent', T);
        % salva lo stato iniziale come “baseline”
        setappdata(T, 'update_pose.currentPose', [0 0 0 0]);
        setappdata(T, 'update_pose.hasBaseline', true);
        % Matrice identità
        T.Matrix = eye(4);
    end
end

% ---- current pose (memorizzata)
if isappdata(T,'update_pose.currentPose')
    cur = getappdata(T,'update_pose.currentPose');
else
    cur = [0 0 0 0];
end

% ---- compose transforms
M_target = makeSE3(x,y,z,yaw);
switch mode
    case "absolute"
        T.Matrix = M_target;
        cur = [x y z yaw];
    case "delta"
        % delta rispetto alla posa corrente
        dx = x; dy = y; dz = z; dth = yaw;
        M_delta = makeSE3(dx,dy,dz,dth);
        T.Matrix = M_delta * T.Matrix;
        cur = cur + [dx dy dz dth]; %#ok<NASGU> % opzionale tener traccia
    otherwise
        error('update_pose:Mode','Unknown Mode: %s', mode);
end

setappdata(T,'update_pose.currentPose',cur);
end

% --- helpers
function M = makeSE3(x,y,z,yaw)
% SE(3) planar: Rz(yaw) + translation
cy = cos(yaw); sy = sin(yaw);
R = [cy -sy 0; sy cy 0; 0 0 1];
M = [R [x;y;z]; 0 0 0 1];
end
