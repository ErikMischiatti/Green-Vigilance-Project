from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from green_vigilance.agents.dynamics import MotionLimits, unicycle_step
from green_vigilance.control.obstacle_avoidance import avoidance_turn_rate
from green_vigilance.control.waypoint import waypoint_control


@dataclass
class UGV:
    state: np.ndarray
    target: np.ndarray
    path: list[np.ndarray] = field(default_factory=list)

    def step(
        self,
        dt: float,
        v_nom: float,
        w_max: float,
        kp_ang: float,
        kp_dist: float,
        obstacles_xy: np.ndarray,
        obstacle_radius: float,
        obstacle_gain: float,
    ) -> None:
        control, _ = waypoint_control(self.state, self.target, v_nom, w_max, kp_ang, kp_dist)
        control[1] += avoidance_turn_rate(self.state, obstacles_xy, obstacle_radius, obstacle_gain, w_max)
        control[1] = np.clip(control[1], -w_max, w_max)
        self.state = unicycle_step(self.state, control, dt, MotionLimits(vmax=v_nom, wmax=w_max))
        self.path.append(self.state.copy())
