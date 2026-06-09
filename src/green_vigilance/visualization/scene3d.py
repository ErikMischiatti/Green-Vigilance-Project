from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

from green_vigilance.environment.field import Field
from green_vigilance.environment.plants import PlantField
from green_vigilance.sensing.camera import CameraModel
from green_vigilance.sensing.frustum import frustum_vertices


def plot_scene3d(
    field: Field,
    plants: PlantField | None,
    leaf_health: np.ndarray | None,
    observed_mask: np.ndarray | None,
    uav_path: np.ndarray | None,
    ugv_paths: list[np.ndarray] | None,
    path: Path,
    *,
    camera: CameraModel | None = None,
    camera_pose: np.ndarray | None = None,
    scenario_name: str | None = None,
) -> None:
    """Render a compact MATLAB-like 3D overview for scenario debugging."""
    path.parent.mkdir(parents=True, exist_ok=True)
    fig = plt.figure(figsize=(9, 7))
    ax = fig.add_subplot(111, projection="3d")

    _draw_field(ax, field)
    _draw_plants(ax, plants, leaf_health, observed_mask)
    _draw_uav(ax, uav_path)
    _draw_ugvs(ax, ugv_paths or [])
    if camera is not None and camera_pose is not None:
        _draw_frustum(ax, camera, camera_pose)

    ax.set_xlabel("X (m)")
    ax.set_ylabel("Y (m)")
    ax.set_zlabel("Z (m)")
    ax.set_title(f"3D Scene - {scenario_name}" if scenario_name else "3D Scene")
    ax.view_init(elev=28.0, azim=-132.0)
    _set_equal_axes(ax, field)
    ax.legend(loc="upper left", bbox_to_anchor=(0.02, 0.98))
    fig.tight_layout()
    fig.savefig(path, dpi=170)
    plt.close(fig)


def _draw_field(ax, field: Field) -> None:
    x0, x1 = field.xlim
    y0, y1 = field.ylim
    z0 = field.zlim[0]
    verts = [[(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0)]]
    ground = Poly3DCollection(verts, facecolor="#d9efc2", edgecolor="#6b8e23", alpha=0.35, linewidth=1.0)
    ax.add_collection3d(ground)
    ax.plot([x0, x1, x1, x0, x0], [y0, y0, y1, y1, y0], [z0] * 5, color="#446b2d", linewidth=1.3, label="field")


def _draw_plants(ax, plants: PlantField | None, leaf_health: np.ndarray | None, observed_mask: np.ndarray | None) -> None:
    if plants is None:
        return
    centers = _as_points(plants.tree_centers, 3)
    radii = np.asarray(plants.tree_radius if plants.tree_radius is not None else [], dtype=float)
    if len(centers):
        sizes = 18.0 + 11.0 * np.square(radii[: len(centers)] if len(radii) else np.ones(len(centers)))
        ax.scatter(centers[:, 0], centers[:, 1], centers[:, 2], s=sizes, color="#2f7d32", alpha=0.20, edgecolors="none", label="tree canopies")
        z0 = 0.0
        for center in centers[:: max(1, len(centers) // 80)]:
            ax.plot([center[0], center[0]], [center[1], center[1]], [z0, center[2]], color="#6b4f2a", alpha=0.35, linewidth=0.8)

    leaves = _as_points(plants.leaf_xyz, 3)
    if not len(leaves):
        return
    health = np.asarray(leaf_health if leaf_health is not None else plants.leaf_health, dtype=float)
    if len(health) != len(leaves):
        health = np.ones(len(leaves), dtype=float)
    observed = np.asarray(observed_mask if observed_mask is not None else np.zeros(len(leaves), dtype=bool), dtype=bool)
    if len(observed) != len(leaves):
        observed = np.zeros(len(leaves), dtype=bool)

    sample = _sample_indices(len(leaves), 5000)
    leaves = leaves[sample]
    health = health[sample]
    observed = observed[sample]

    unobserved = ~observed
    if np.any(unobserved):
        ax.scatter(leaves[unobserved, 0], leaves[unobserved, 1], leaves[unobserved, 2], s=2.0, color="#7a8a74", alpha=0.18, label="unobserved leaves")
    if np.any(observed):
        infected = observed & (health < 0.5)
        healthy = observed & ~infected
        if np.any(healthy):
            ax.scatter(leaves[healthy, 0], leaves[healthy, 1], leaves[healthy, 2], s=5.0, color="#20a64a", alpha=0.75, label="observed healthy")
        if np.any(infected):
            ax.scatter(leaves[infected, 0], leaves[infected, 1], leaves[infected, 2], s=7.0, color="#c7362f", alpha=0.85, label="observed infected")


def _draw_uav(ax, uav_path: np.ndarray | None) -> None:
    path = _as_points(uav_path, 3)
    if not len(path):
        return
    ax.plot(path[:, 0], path[:, 1], path[:, 2], color="#1455d9", linewidth=2.0, label="UAV trajectory")
    final = path[-1]
    ax.scatter([final[0]], [final[1]], [final[2]], marker="^", s=90, color="#092f87", edgecolors="white", linewidth=0.8, label="UAV final")


def _draw_ugvs(ax, ugv_paths: list[np.ndarray]) -> None:
    for i, raw_path in enumerate(ugv_paths):
        path = _as_points(raw_path, 3)
        if not len(path):
            continue
        ax.plot(path[:, 0], path[:, 1], path[:, 2], linewidth=1.5, label=f"UGV {i + 1}")
        ax.scatter([path[-1, 0]], [path[-1, 1]], [path[-1, 2]], marker="s", s=35)


def _draw_frustum(ax, camera: CameraModel, pose: np.ndarray) -> None:
    try:
        vertices, faces = frustum_vertices(camera, np.asarray(pose, dtype=float))
    except ValueError:
        return
    poly = Poly3DCollection(vertices[faces], facecolor="#f6c85f", edgecolor="#a66f00", alpha=0.13, linewidth=0.8)
    ax.add_collection3d(poly)
    for face in faces:
        loop = np.r_[face, face[0]]
        ax.plot(vertices[loop, 0], vertices[loop, 1], vertices[loop, 2], color="#a66f00", alpha=0.55, linewidth=0.8)
    ax.scatter([pose[0]], [pose[1]], [pose[2]], marker="o", s=28, color="#f08c00", label="camera frustum")


def _as_points(value: np.ndarray | None, width: int) -> np.ndarray:
    if value is None:
        return np.empty((0, width), dtype=float)
    arr = np.asarray(value, dtype=float)
    if arr.ndim != 2 or arr.shape[1] < width:
        return np.empty((0, width), dtype=float)
    return arr[:, :width]


def _sample_indices(count: int, limit: int) -> np.ndarray:
    if count <= limit:
        return np.arange(count)
    return np.linspace(0, count - 1, limit, dtype=int)


def _set_equal_axes(ax, field: Field) -> None:
    x0, x1 = field.xlim
    y0, y1 = field.ylim
    z0, z1 = field.zlim
    span = max(x1 - x0, y1 - y0, z1 - z0)
    cx = (x0 + x1) / 2.0
    cy = (y0 + y1) / 2.0
    cz = (z0 + z1) / 2.0
    half = span / 2.0
    ax.set_xlim(cx - half, cx + half)
    ax.set_ylim(cy - half, cy + half)
    ax.set_zlim(max(0.0, cz - half), cz + half)
