from __future__ import annotations

import numpy as np

from green_vigilance.sensing.camera import CameraModel
from green_vigilance.utils.geometry import convex_hull_xy, rotation_zyx


def frustum_vertices(cam: CameraModel, pose: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    pose = np.asarray(pose, dtype=float).reshape(6)
    zn, zf = cam.range_min, cam.range_max
    wxn, wyn = zn * cam.tan_half_h, zn * cam.tan_half_v
    wxf, wyf = zf * cam.tan_half_h, zf * cam.tan_half_v
    v_cam = np.array(
        [
            [-wxn, -wyn, zn],
            [wxn, -wyn, zn],
            [wxn, wyn, zn],
            [-wxn, wyn, zn],
            [-wxf, -wyf, zf],
            [wxf, -wyf, zf],
            [wxf, wyf, zf],
            [-wxf, wyf, zf],
        ]
    )
    rot = rotation_zyx(pose[3], pose[4], pose[5])
    vertices = v_cam @ rot.T + pose[:3]
    faces = np.array([[0, 1, 2, 3], [4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]])
    return vertices, faces


def points_in_frustum(cam: CameraModel, pose: np.ndarray, points_world: np.ndarray) -> np.ndarray:
    pts = np.asarray(points_world, dtype=float)
    pose = np.asarray(pose, dtype=float).reshape(6)
    rot = rotation_zyx(pose[3], pose[4], pose[5])
    pc = (rot.T @ (pts - pose[:3]).T).T
    z = pc[:, 2]
    in_front = z > 1e-9
    in_range = (z >= cam.range_min - 1e-9) & (z <= cam.range_max + 1e-9)
    tx = np.abs(pc[:, 0]) / np.maximum(z, 1e-9)
    ty = np.abs(pc[:, 1]) / np.maximum(z, 1e-9)
    return in_front & in_range & (tx <= cam.tan_half_h + 1e-12) & (ty <= cam.tan_half_v + 1e-12)


def ground_footprint(cam: CameraModel, pose: np.ndarray) -> np.ndarray:
    vertices, _ = frustum_vertices(cam, pose)
    edges = np.array([[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]])
    pts: list[np.ndarray] = []
    for i, j in edges:
        a, b = vertices[i], vertices[j]
        za, zb = a[2], b[2]
        if abs(za) < 1e-9:
            pts.append(a[:2])
        if abs(zb) < 1e-9:
            pts.append(b[:2])
        if (za > 0 > zb) or (za < 0 < zb):
            t = -za / (zb - za)
            if 0.0 <= t <= 1.0:
                pts.append((a + t * (b - a))[:2])
    if len(pts) < 3:
        return np.empty((0, 2))
    return convex_hull_xy(np.round(np.asarray(pts), 6))
