from __future__ import annotations

import numpy as np


def weighted_position_estimate(positions: np.ndarray, weights: np.ndarray) -> np.ndarray:
    """Return a weighted 2D/3D position estimate, ignoring nonpositive weights."""
    pts = np.asarray(positions, dtype=float)
    w = np.asarray(weights, dtype=float).reshape(-1)
    if pts.ndim != 2:
        raise ValueError("positions must be an NxD array")
    if len(w) != len(pts):
        raise ValueError("weights length must match positions")
    valid = np.isfinite(w) & (w > 0.0) & np.all(np.isfinite(pts), axis=1)
    if not np.any(valid):
        raise ValueError("at least one finite positive weight is required")
    return np.average(pts[valid], axis=0, weights=w[valid])


def cooperative_wls(own_positions: np.ndarray, own_weights: np.ndarray, shared_positions: np.ndarray, shared_weights: np.ndarray) -> np.ndarray:
    """First-pass cooperative UGV localization from own and shared estimates."""
    own_positions = np.asarray(own_positions, dtype=float)
    out = np.zeros_like(own_positions)
    for i in range(len(own_positions)):
        positions = [own_positions[i]]
        weights = [own_weights[i]]
        if len(shared_positions):
            positions.extend(np.asarray(shared_positions, dtype=float))
            weights.extend(np.asarray(shared_weights, dtype=float))
        out[i] = weighted_position_estimate(np.asarray(positions), np.asarray(weights))
    return out
