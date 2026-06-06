from __future__ import annotations

import numpy as np


def disease_heatmap(
    leaf_xy: np.ndarray,
    leaf_health: np.ndarray,
    observed_mask: np.ndarray,
    xlim: tuple[float, float],
    ylim: tuple[float, float],
    resolution: float,
    sigma: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Accumulate observed disease probabilities into a 2D grid."""
    xy = np.asarray(leaf_xy, dtype=float)
    health = np.asarray(leaf_health, dtype=float)
    mask = np.asarray(observed_mask, dtype=bool)
    x_edges = np.arange(xlim[0], xlim[1] + resolution, resolution)
    y_edges = np.arange(ylim[0], ylim[1] + resolution, resolution)
    heat = np.zeros((len(y_edges) - 1, len(x_edges) - 1), dtype=float)
    weight = np.zeros_like(heat)
    if not np.any(mask):
        return heat, x_edges, y_edges

    xs = (x_edges[:-1] + x_edges[1:]) / 2.0
    ys = (y_edges[:-1] + y_edges[1:]) / 2.0
    grid_x, grid_y = np.meshgrid(xs, ys)
    for point, h in zip(xy[mask], health[mask]):
        disease_prob = 1.0 - float(np.clip(h, 0.0, 1.0))
        d2 = (grid_x - point[0]) ** 2 + (grid_y - point[1]) ** 2
        kernel = np.exp(-0.5 * d2 / max(sigma, 1e-9) ** 2)
        heat += disease_prob * kernel
        weight += kernel
    return np.divide(heat, weight, out=np.zeros_like(heat), where=weight > 1e-12), x_edges, y_edges


def top_targets_from_heatmap(heat: np.ndarray, x_edges: np.ndarray, y_edges: np.ndarray, count: int, min_separation: float) -> np.ndarray:
    flat_indices = np.argsort(heat.ravel())[::-1]
    targets: list[np.ndarray] = []
    xs = (x_edges[:-1] + x_edges[1:]) / 2.0
    ys = (y_edges[:-1] + y_edges[1:]) / 2.0
    for idx in flat_indices:
        if heat.ravel()[idx] <= 0.0:
            break
        iy, ix = np.unravel_index(idx, heat.shape)
        candidate = np.array([xs[ix], ys[iy]])
        if all(np.linalg.norm(candidate - t) >= min_separation for t in targets):
            targets.append(candidate)
        if len(targets) >= count:
            break
    return np.vstack(targets) if targets else np.empty((0, 2))
