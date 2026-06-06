% NON APPLICATA IN VIS3D_STATIC

function [V_world, F] = camera_frustum_vertices(cam, pose, varargin)
%CAMERA_FRUSTUM_VERTICES  Frustum vertices in world frame.
% cam: struct (hfov_deg, vfov_deg, range_min, range_max)
% pose: [x y z yaw pitch roll] (rad). yaw=Z, pitch=Y, roll=X.
% Returns:
%   V_world: 8x3 vertices (near 4 + far 4)
%   F: faces for patch (6 faces)

% --- FoV & range
hf = deg2rad(cam.hfov_deg);
vf = deg2rad(cam.vfov_deg);
zn = cam.range_min;
zf = cam.range_max;

% --- frustum in camera frame (forward = +Z_cam)
wxn = zn * tan(hf/2);  wyn = zn * tan(vf/2);
wxf = zf * tan(hf/2);  wyf = zf * tan(vf/2);

V_cam = [ ...
   -wxn, -wyn,  zn;   % 1 near
    wxn, -wyn,  zn;   % 2
    wxn,  wyn,  zn;   % 3
   -wxn,  wyn,  zn;   % 4
   -wxf, -wyf,  zf;   % 5 far
    wxf, -wyf,  zf;   % 6
    wxf,  wyf,  zf;   % 7
   -wxf,  wyf,  zf];  % 8

% --- camera-to-world rot & trans
yaw  = pose(4); pitch = pose(5); roll = pose(6);
R_wc = Rzyx(yaw, pitch, roll);    % 3x3
t    = reshape(pose(1:3), 1, 3);  % *** 1x3 riga ***

% --- trasformazione: (8x3)*(3x3) + (broadcast 1x3)
V_rot   = V_cam * R_wc.';         % 8x3
V_world = bsxfun(@plus, V_rot, t);

% --- faces
F = [ ...
    1 2 3 4;   % near
    5 6 7 8;   % far
    1 2 6 5;   % sides
    2 3 7 6;
    3 4 8 7;
    4 1 5 8];
end

% ---- local helper
function R = Rzyx(yaw,pitch,roll)
cy=cos(yaw); sy=sin(yaw);
cp=cos(pitch); sp=sin(pitch);
cr=cos(roll);  sr=sin(roll);
Rz=[cy -sy 0; sy cy 0; 0 0 1];
Ry=[cp 0 sp; 0 1 0; -sp 0 cp];
Rx=[1 0 0; 0 cr -sr; 0 sr cr];
R = Rz*Ry*Rx;
end
