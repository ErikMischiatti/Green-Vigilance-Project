from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass
class UAV:
    true_state: np.ndarray
    altitude_m: float

    @property
    def pose6(self) -> np.ndarray:
        return np.array([self.true_state[0], self.true_state[1], self.altitude_m, self.true_state[2], np.deg2rad(80.0), 0.0])
