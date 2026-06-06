from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from green_vigilance.agents.dynamics import MotionLimits, unicycle_jacobians, unicycle_step
from green_vigilance.utils.geometry import wrap_to_pi


@dataclass
class EKFState:
    x: np.ndarray
    p: np.ndarray
    q: np.ndarray
    r_gps: np.ndarray

    @classmethod
    def initialize(
        cls,
        x0: np.ndarray,
        p0: np.ndarray,
        sigma_v: float,
        sigma_omega: float,
        r_gps: np.ndarray,
    ) -> "EKFState":
        return cls(
            x=np.asarray(x0, dtype=float).reshape(3),
            p=np.asarray(p0, dtype=float).reshape(3, 3),
            q=np.diag([sigma_v, sigma_omega]) ** 2,
            r_gps=np.asarray(r_gps, dtype=float).reshape(2, 2),
        )

    def predict(self, control: np.ndarray, dt: float, limits: MotionLimits | None = None) -> None:
        f, l = unicycle_jacobians(self.x, control, dt)
        x_pred = unicycle_step(self.x, control, dt, limits)
        if self.q.shape == (2, 2):
            q_proc = l @ self.q @ l.T
        elif self.q.shape == (3, 3):
            q_proc = self.q
        else:
            raise ValueError("EKF process noise must be 2x2 input noise or 3x3 state noise")
        self.x = np.array([x_pred[0], x_pred[1], wrap_to_pi(x_pred[2])])
        self.p = f @ self.p @ f.T + q_proc

    def update_gps(self, z_xy: np.ndarray) -> None:
        z = np.asarray(z_xy, dtype=float).reshape(2)
        h = np.array([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]])
        y = z - h @ self.x
        s = h @ self.p @ h.T + self.r_gps
        k = self.p @ h.T @ np.linalg.inv(s)
        self.x = self.x + k @ y
        self.x[2] = wrap_to_pi(self.x[2])
        i = np.eye(3)
        self.p = (i - k @ h) @ self.p @ (i - k @ h).T + k @ self.r_gps @ k.T

    def update_heading(self, theta_meas: float, sigma_theta: float) -> None:
        h = np.array([[0.0, 0.0, 1.0]])
        r = np.array([[sigma_theta**2]])
        y = np.array([wrap_to_pi(theta_meas - float(h @ self.x))])
        s = h @ self.p @ h.T + r
        k = self.p @ h.T @ np.linalg.inv(s)
        self.x = self.x + (k @ y).reshape(3)
        self.x[2] = wrap_to_pi(self.x[2])
        i = np.eye(3)
        self.p = (i - k @ h) @ self.p @ (i - k @ h).T + k @ r @ k.T
