from __future__ import annotations

from dataclasses import dataclass

import numpy as np


@dataclass(frozen=True)
class CameraModel:
    hfov_deg: float
    vfov_deg: float
    range_min: float
    range_max: float
    focus_m_used: float | None = None
    focal_m_used: float | None = None

    @property
    def hfov_rad(self) -> float:
        return float(np.deg2rad(self.hfov_deg))

    @property
    def vfov_rad(self) -> float:
        return float(np.deg2rad(self.vfov_deg))

    @property
    def tan_half_h(self) -> float:
        return float(np.tan(self.hfov_rad / 2.0))

    @property
    def tan_half_v(self) -> float:
        return float(np.tan(self.vfov_rad / 2.0))


def camera_from_specs(spec: dict) -> CameraModel:
    """Port of MATLAB camera_fov_from_specs with DoF near/far fallback."""
    hfov = _finite(spec.get("hfov_deg"))
    vfov = _finite(spec.get("vfov_deg"))
    wmm = _finite(spec.get("sensor_width_mm"))
    hmm = _finite(spec.get("sensor_height_mm"))
    fmm = _finite(spec.get("focal_mm"))

    if hfov is not None and vfov is not None:
        pass
    elif hfov is not None and wmm and hmm:
        vfov = float(np.rad2deg(2.0 * np.arctan(np.tan(np.deg2rad(hfov) / 2.0) * (hmm / wmm))))
    elif vfov is not None and wmm and hmm:
        hfov = float(np.rad2deg(2.0 * np.arctan(np.tan(np.deg2rad(vfov) / 2.0) * (wmm / hmm))))
    else:
        if not (wmm and hmm and fmm):
            raise ValueError("Provide hfov/vfov or sensor_width_mm, sensor_height_mm, focal_mm")
        hfov = float(2.0 * np.rad2deg(np.arctan2(wmm / 2.0, fmm)))
        vfov = float(2.0 * np.rad2deg(np.arctan2(hmm / 2.0, fmm)))

    if not (0.0 < hfov < 180.0 and 0.0 < vfov < 180.0):
        raise ValueError("invalid camera FoV")

    focus_m = _finite(spec.get("focus_distance_m")) or _finite(spec.get("altitude_m"))
    focal_m = fmm / 1000.0 if fmm else None
    if focal_m is None and wmm:
        focal_m = ((wmm / 1000.0) / 2.0) / np.tan(np.deg2rad(hfov) / 2.0)

    near: float | None = None
    far: float | None = None
    fstop = _finite(spec.get("fstop_N"))
    coc_mm = _finite(spec.get("coc_mm"))
    if focal_m and fstop and coc_mm and focus_m:
        coc_m = coc_mm / 1000.0
        hyperfocal = (focal_m**2) / (fstop * coc_m) + focal_m
        near = (hyperfocal * focus_m) / (hyperfocal + (focus_m - focal_m))
        den = hyperfocal - (focus_m - focal_m)
        far = (hyperfocal * focus_m) / den if den > 0 else np.inf

    if near is None or far is None or not np.isfinite(near) or not np.isfinite(far) or far <= near:
        near = float(spec.get("range_min_m", 0.5) or 0.5)
        far = float(spec.get("range_max_m", 40.0) or 40.0)
    if spec.get("range_min_m") is not None:
        near = max(float(spec["range_min_m"]), 1e-3)
    if spec.get("range_max_m") is not None:
        far = float(spec["range_max_m"])
    if not (np.isfinite(near) and np.isfinite(far) and far > near):
        raise ValueError("invalid camera range")
    return CameraModel(hfov, vfov, max(near, 1e-3), far, focus_m, focal_m)


def detection_radius(height: float, hfov_deg: float) -> float:
    return float(height * np.tan(np.deg2rad(hfov_deg) / 2.0))


def _finite(value: object) -> float | None:
    if value is None:
        return None
    try:
        out = float(value)
    except (TypeError, ValueError):
        return None
    return out if np.isfinite(out) else None
