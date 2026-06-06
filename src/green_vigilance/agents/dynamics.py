from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from green_vigilance.utils.geometry import wrap_to_pi


@dataclass(frozen=True)
class MotionLimits:
    vmax: float = np.inf
    wmax: float = np.inf


def unicycle_step(
    state: np.ndarray,
    control: np.ndarray,
    dt: float,
    limits: MotionLimits | None = None,
) -> np.ndarray:
    """Exact unicycle integration ported from the MATLAB prototype."""
    x = np.asarray(state, dtype=float).reshape(3)
    u = np.asarray(control, dtype=float).reshape(2)
    lim = limits or MotionLimits()
    v = float(np.clip(u[0], -lim.vmax, lim.vmax))
    w = float(np.clip(u[1], -lim.wmax, lim.wmax))
    theta = x[2]

    if abs(w) < 1e-8:
        dx = v * np.cos(theta) * dt
        dy = v * np.sin(theta) * dt
    else:
        dx = (v / w) * (np.sin(theta + w * dt) - np.sin(theta))
        dy = (v / w) * (-np.cos(theta + w * dt) + np.cos(theta))

    return np.array([x[0] + dx, x[1] + dy, wrap_to_pi(theta + w * dt)], dtype=float)


def unicycle_jacobians(state: np.ndarray, control: np.ndarray, dt: float) -> tuple[np.ndarray, np.ndarray]:
    """Jacobians F=d f/dx and L=d f/du for EKF process noise projection."""
    x = np.asarray(state, dtype=float).reshape(3)
    u = np.asarray(control, dtype=float).reshape(2)
    theta, v, w = x[2], u[0], u[1]

    if abs(w) < 1e-8:
        f = np.array(
            [
                [1.0, 0.0, -v * dt * np.sin(theta)],
                [0.0, 1.0, v * dt * np.cos(theta)],
                [0.0, 0.0, 1.0],
            ]
        )
        l = np.array(
            [
                [dt * np.cos(theta), 0.0],
                [dt * np.sin(theta), 0.0],
                [0.0, dt],
            ]
        )
        return f, l

    s1, c1 = np.sin(theta + w * dt), np.cos(theta + w * dt)
    s0, c0 = np.sin(theta), np.cos(theta)
    f = np.array(
        [
            [1.0, 0.0, (v / w) * (c1 - c0)],
            [0.0, 1.0, (v / w) * (s1 - s0)],
            [0.0, 0.0, 1.0],
        ]
    )
    dv = np.array([(s1 - s0) / w, (-c1 + c0) / w, 0.0])
    dwdx = v * ((w * dt * c1 - (s1 - s0)) / (w**2))
    dwdy = v * ((w * dt * s1 - (-c1 + c0)) / (w**2))
    l = np.array([[dv[0], dwdx], [dv[1], dwdy], [0.0, dt]])
    if not np.all(np.isfinite(l)):
        l = np.array([[dt * np.cos(theta), 0.0], [dt * np.sin(theta), 0.0], [0.0, dt]])
    return f, l
