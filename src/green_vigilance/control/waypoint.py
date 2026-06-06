from __future__ import annotations

import numpy as np

from green_vigilance.utils.geometry import wrap_to_pi


def waypoint_control(
    state: np.ndarray,
    waypoint_xy: np.ndarray,
    v_nom: float,
    w_max: float,
    kp_ang: float,
    kp_dist: float,
) -> tuple[np.ndarray, float]:
    state = np.asarray(state, dtype=float).reshape(3)
    waypoint = np.asarray(waypoint_xy, dtype=float).reshape(2)
    delta = waypoint - state[:2]
    dist = float(np.linalg.norm(delta))
    heading = float(np.arctan2(delta[1], delta[0]))
    err = float(wrap_to_pi(heading - state[2]))
    v = v_nom * (1.0 - np.exp(-kp_dist * dist))
    w = float(np.clip(kp_ang * err, -w_max, w_max))
    return np.array([v, w]), dist
