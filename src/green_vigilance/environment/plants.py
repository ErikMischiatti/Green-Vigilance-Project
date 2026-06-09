from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from green_vigilance.environment.field import Field


@dataclass
class PlantField:
    leaf_xyz: np.ndarray
    leaf_health: np.ndarray
    leaf_tree_id: np.ndarray
    tree_centers: np.ndarray
    tree_radius: np.ndarray
    tree_health: np.ndarray


def generate_trees(field: Field, n_trees: int, seed: int | None = None, **kwargs: object) -> PlantField:
    """Procedural tree/leaf generation inspired by MATLAB generate_trees.m."""
    rng = np.random.default_rng(seed)
    leaves_range = tuple(kwargs.get("leaves_per_tree", (120, 260)))
    height_range = tuple(kwargs.get("height_range", (3.0, 7.0)))
    canopy_base_frac = tuple(kwargs.get("canopy_base_frac", (0.60, 0.80)))
    clearance = float(kwargs.get("min_canopy_clearance", 2.0))
    crown_range = tuple(kwargs.get("crown_radius_xy", (2.5, 6.0)))
    shape_range = tuple(kwargs.get("shape_power", (1.7, 2.3)))
    lobes_range = tuple(kwargs.get("lobes", (1, 3)))
    jitter = float(kwargs.get("leaf_jitter", 0.12))

    leaf_xyz: list[np.ndarray] = []
    leaf_health: list[np.ndarray] = []
    leaf_tree_id: list[np.ndarray] = []
    centers: list[np.ndarray] = []
    radii: list[float] = []
    tree_health: list[float] = []

    if n_trees <= 0:
        return PlantField(
            np.empty((0, 3), dtype=float),
            np.empty(0, dtype=float),
            np.empty(0, dtype=int),
            np.empty((0, 3), dtype=float),
            np.empty(0, dtype=float),
            np.empty(0, dtype=float),
        )

    for tree_id in range(n_trees):
        height = rng.uniform(*height_range)
        f_base = rng.uniform(*canopy_base_frac)
        z_base = field.zlim[0]
        z_canopy_base = max(z_base + clearance, z_base + f_base * height)
        z_top = z_base + height
        rz = 0.5 * (z_top - z_canopy_base)
        cz = z_canopy_base + rz
        rxy = rng.uniform(*crown_range)
        shape = rng.uniform(*shape_range)
        n_lobes = int(rng.integers(int(lobes_range[0]), int(lobes_range[1]) + 1))
        n_leaf = int(rng.integers(int(leaves_range[0]), int(leaves_range[1]) + 1))
        cx = rng.uniform(field.xlim[0] + rxy + 2.0, field.xlim[1] - rxy - 2.0)
        cy = rng.uniform(field.ylim[0] + rxy + 2.0, field.ylim[1] - rxy - 2.0)
        center = np.array([cx, cy, cz])

        if (cy > 0.6 * field.ylim[1]) or (cx > 0.6 * field.xlim[1] and cy > 0.4 * field.ylim[1]) or (cx < 0.3 * field.xlim[1] and cy > 0.45 * field.ylim[1]):
            th = float(np.clip(0.25 + 0.1 * rng.random(), 0.0, 1.0))
        else:
            th = float(np.clip(0.75 + 0.2 * rng.random(), 0.0, 1.0))

        main_n = round(0.65 * n_leaf)
        pts = [_sample_superellipsoid(rng, center, rxy, rz, shape, main_n)]
        remaining = n_leaf - main_n
        if n_lobes > 0 and remaining > 0:
            angles = rng.random(n_lobes) * 2.0 * np.pi
            offsets = (0.4 + 0.35 * rng.random(n_lobes)) * rxy
            for j in range(n_lobes):
                c2 = center + np.array([offsets[j] * np.cos(angles[j]), offsets[j] * np.sin(angles[j]), rz * (rng.random() - 0.2) * 0.3])
                pts.append(_sample_superellipsoid(rng, c2, rxy * (0.55 + 0.2 * rng.random()), rz * (0.6 + 0.25 * rng.random()), shape, max(8, round(remaining / n_lobes))))
        xyz = np.vstack(pts) + jitter * rng.normal(size=(sum(len(p) for p in pts), 3))
        xyz[:, 2] = np.maximum(xyz[:, 2], z_canopy_base + 0.05)
        health = np.clip(th + 0.12 * rng.normal(size=len(xyz)), 0.0, 1.0)

        leaf_xyz.append(xyz)
        leaf_health.append(health)
        leaf_tree_id.append(np.full(len(xyz), tree_id, dtype=int))
        centers.append(center)
        radii.append(float(rxy))
        tree_health.append(th)

    return PlantField(np.vstack(leaf_xyz), np.concatenate(leaf_health), np.concatenate(leaf_tree_id), np.vstack(centers), np.asarray(radii), np.asarray(tree_health))


def _sample_superellipsoid(rng: np.random.Generator, center: np.ndarray, rxy: float, rz: float, power: float, n: int) -> np.ndarray:
    u = rng.random(n) ** (1.0 / 3.5)
    phi = 2.0 * np.pi * rng.random(n)
    cost = 2.0 * rng.random(n) - 1.0
    theta = np.arccos(cost)
    sx = np.sign(np.sin(theta) * np.cos(phi)) * np.abs(np.sin(theta) * np.cos(phi)) ** (2.0 / power)
    sy = np.sign(np.sin(theta) * np.sin(phi)) * np.abs(np.sin(theta) * np.sin(phi)) ** (2.0 / power)
    sz = np.sign(np.cos(theta)) * np.abs(np.cos(theta)) ** (2.0 / power)
    return np.column_stack([rxy * u * sx + center[0], rxy * u * sy + center[1], rz * u * sz + center[2]])
