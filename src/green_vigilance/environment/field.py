from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Field:
    xlim: tuple[float, float]
    ylim: tuple[float, float]
    zlim: tuple[float, float]

    @property
    def center_xy(self) -> tuple[float, float]:
        return ((self.xlim[0] + self.xlim[1]) / 2.0, (self.ylim[0] + self.ylim[1]) / 2.0)
