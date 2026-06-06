function mask = points_in_frustum(cam, pose, P_world)
%POINTS_IN_FRUSTUM  Boolean mask of points inside camera frustum.
% cam: struct with hfov_deg,vfov_deg or tan_half_h,tan_half_v; range_min/max (m)
% pose: [x y z yaw pitch roll] (rad), camera looks along +Z_cam
% P_world: Nx3

% ---- validate
if size(P_world,2)~=3, error('points_in_frustum:P','P_world must be Nx3'); end
if numel(pose)~=6, error('points_in_frustum:pose','pose must be [x y z yaw pitch roll]'); end

% ---- world -> camera
R = Rzyx(pose(4), pose(5), pose(6));
Pc = (R' * (P_world - pose(1:3))')';   % inverse SE3

% ---- precompute tangents (use cached if available)
if isfield(cam,'tan_half_h') && isfield(cam,'tan_half_v')
    th = cam.tan_half_h; tv = cam.tan_half_v;
else
    th = tan(deg2rad(cam.hfov_deg/2));
    tv = tan(deg2rad(cam.vfov_deg/2));
end

% ---- range & angular checks
% guardia: punti dietro la camera (z<=0) esclusi
epsZ = 1e-9;
z = Pc(:,3);
inFront = z > epsZ;

% range (con piccola tolleranza)
epsR = 1e-9;
inRange = (z >= cam.range_min - epsR) & (z <= cam.range_max + epsR);

% angoli (tan(theta) = x/z, y/z)
tx = abs(Pc(:,1))./max(z, epsZ);
ty = abs(Pc(:,2))./max(z, epsZ);
inFov = (tx <= th + 1e-12) & (ty <= tv + 1e-12);

mask = inFront & inRange & inFov;
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
