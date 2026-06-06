from __future__ import annotations

import numpy as np

from green_vigilance.utils.geometry import wrap_to_pi


def avoidance_turn_rate(
    state: np.ndarray,
    obstacles_xy: np.ndarray,
    influence_radius: float,
    gain: float,
    w_max: float,
) -> float:
    """Simple repulsive angular correction for nearby obstacles."""
    obs = np.asarray(obstacles_xy, dtype=float)
    if obs.size == 0:
        return 0.0
    state = np.asarray(state, dtype=float).reshape(3)
    delta = obs[:, :2] - state[:2]
    dist = np.linalg.norm(delta, axis=1)
    mask = (dist > 1e-9) & (dist < influence_radius)
    if not np.any(mask):
        return 0.0
    angles = np.arctan2(delta[mask, 1], delta[mask, 0])
    rel = np.array([wrap_to_pi(a - state[2]) for a in angles])
    strengths = (influence_radius - dist[mask]) / influence_radius
    correction = -gain * float(np.sum(np.sign(rel) * strengths))
    return float(np.clip(correction, -w_max, w_max))
