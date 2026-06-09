from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


class ConfigValidationError(ValueError):
    """Raised when a scenario YAML file is structurally invalid."""


def load_config(path: str | Path) -> dict[str, Any]:
    with Path(path).open("r", encoding="utf-8") as fh:
        cfg = yaml.safe_load(fh) or {}
    validate_config(cfg)
    return cfg


def deep_get(cfg: dict[str, Any], dotted: str, default: Any = None) -> Any:
    cur: Any = cfg
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return default
        cur = cur[part]
    return cur


def validate_config(cfg: Any) -> None:
    """Validate the scenario structure used by the simulation runner."""
    errors: list[str] = []
    if not isinstance(cfg, dict):
        raise ConfigValidationError("Config root must be a mapping.")

    for section in ("output", "field", "simulation", "uav", "camera"):
        _require_mapping(cfg, section, errors)

    if errors:
        raise ConfigValidationError(_format_errors(errors))

    if "name" in cfg:
        _string(cfg["name"], "name", errors, allow_empty=False)
    if "seed" in cfg:
        _integer(cfg["seed"], "seed", errors)

    output = cfg["output"]
    _string(output.get("dir"), "output.dir", errors, allow_empty=False)

    field = cfg["field"]
    _ordered_number_pair(field.get("xlim"), "field.xlim", errors)
    _ordered_number_pair(field.get("ylim"), "field.ylim", errors)
    _ordered_number_pair(field.get("zlim", [0.0, 10.0]), "field.zlim", errors)
    _integer(field.get("n_trees"), "field.n_trees", errors, minimum=0)

    plants = cfg.get("plants", {})
    if plants is not None:
        _mapping(plants, "plants", errors)
        if isinstance(plants, dict):
            _integer_pair(plants.get("leaves_per_tree"), "plants.leaves_per_tree", errors, minimum=0, ordered=True, required=False)
            _ordered_number_pair(plants.get("height_range"), "plants.height_range", errors, required=False, positive=True)
            _ordered_number_pair(plants.get("canopy_base_frac"), "plants.canopy_base_frac", errors, required=False)
            _number(plants.get("min_canopy_clearance"), "plants.min_canopy_clearance", errors, minimum=0.0, required=False)
            _ordered_number_pair(plants.get("crown_radius_xy"), "plants.crown_radius_xy", errors, required=False, positive=True)
            _ordered_number_pair(plants.get("shape_power"), "plants.shape_power", errors, required=False, positive=True)
            _integer_pair(plants.get("lobes"), "plants.lobes", errors, minimum=0, ordered=True, required=False)
            _number(plants.get("leaf_jitter"), "plants.leaf_jitter", errors, minimum=0.0, required=False)

    disease = cfg.get("disease", {})
    if disease is not None:
        _mapping(disease, "disease", errors)
        if isinstance(disease, dict):
            _integer(disease.get("initial_infected_trees"), "disease.initial_infected_trees", errors, minimum=0, required=False)
            _number(disease.get("spread_radius"), "disease.spread_radius", errors, minimum=0.0, required=False)
            _integer(disease.get("steps"), "disease.steps", errors, minimum=0, required=False)
            _number(disease.get("base_probability"), "disease.base_probability", errors, minimum=0.0, maximum=1.0, required=False)
            _number(disease.get("height_bias"), "disease.height_bias", errors, minimum=0.0, required=False)

    simulation = cfg["simulation"]
    _number(simulation.get("dt"), "simulation.dt", errors, positive=True)
    _number(simulation.get("duration_s"), "simulation.duration_s", errors, positive=True)

    uav = cfg["uav"]
    _number_list(uav.get("initial_state"), "uav.initial_state", errors, length=3)
    _number_list(uav.get("initial_estimate_error"), "uav.initial_estimate_error", errors, length=3, required=False)
    _number_list(uav.get("initial_covariance"), "uav.initial_covariance", errors, length=3, positive=True, required=False)
    _number(uav.get("gps_hz"), "uav.gps_hz", errors, positive=True, required=False)
    _number(uav.get("v_nom"), "uav.v_nom", errors, minimum=0.0, required=False)
    _number(uav.get("w_max_deg"), "uav.w_max_deg", errors, positive=True, required=False)
    _number(uav.get("kp_ang"), "uav.kp_ang", errors, minimum=0.0, required=False)
    _number(uav.get("kp_dist"), "uav.kp_dist", errors, minimum=0.0, required=False)
    _number(uav.get("waypoint_tolerance"), "uav.waypoint_tolerance", errors, positive=True, required=False)
    _waypoints(uav.get("waypoints"), "uav.waypoints", errors)
    if "v_min" in uav and "v_max" in uav:
        min_speed = _as_number(uav["v_min"])
        max_speed = _as_number(uav["v_max"])
        if min_speed is not None and max_speed is not None and max_speed < min_speed:
            errors.append("uav.v_max must be greater than or equal to uav.v_min.")

    ugv = cfg.get("ugv", {})
    if ugv is not None:
        _mapping(ugv, "ugv", errors)
        if isinstance(ugv, dict):
            _integer(ugv.get("count"), "ugv.count", errors, minimum=0, required=False)
            _number(ugv.get("duration_s"), "ugv.duration_s", errors, minimum=0.0, required=False)
            _number(ugv.get("v_nom"), "ugv.v_nom", errors, minimum=0.0, required=False)
            _number(ugv.get("w_max_deg"), "ugv.w_max_deg", errors, positive=True, required=False)
            _number(ugv.get("kp_ang"), "ugv.kp_ang", errors, minimum=0.0, required=False)
            _number(ugv.get("kp_dist"), "ugv.kp_dist", errors, minimum=0.0, required=False)
            _number(ugv.get("obstacle_radius_m"), "ugv.obstacle_radius_m", errors, minimum=0.0, required=False)
            _number(ugv.get("obstacle_gain"), "ugv.obstacle_gain", errors, minimum=0.0, required=False)

    noise = cfg.get("noise", {})
    if noise is not None:
        _mapping(noise, "noise", errors)
        if isinstance(noise, dict):
            for key in ("sigma_gps_m", "sigma_gyro_deg", "sigma_vcmd", "sigma_omega_deg"):
                _number(noise.get(key), f"noise.{key}", errors, minimum=0.0, required=False)

    camera = cfg["camera"]
    for key in ("sensor_width_mm", "sensor_height_mm", "focal_mm", "fstop_N", "coc_mm", "altitude_m"):
        _number(camera.get(key), f"camera.{key}", errors, positive=True, required=False)
    _number(camera.get("hfov_deg"), "camera.hfov_deg", errors, positive=True, maximum=180.0, required=False)
    _number(camera.get("vfov_deg"), "camera.vfov_deg", errors, positive=True, maximum=180.0, required=False)
    _number(camera.get("pitch_deg"), "camera.pitch_deg", errors, required=False)
    _number(camera.get("roll_deg"), "camera.roll_deg", errors, required=False)
    _number(camera.get("range_min_m"), "camera.range_min_m", errors, positive=True, required=False)
    _number(camera.get("range_max_m"), "camera.range_max_m", errors, positive=True, required=False)
    if "range_min_m" in camera and "range_max_m" in camera:
        near = _as_number(camera["range_min_m"])
        far = _as_number(camera["range_max_m"])
        if near is not None and far is not None and far <= near:
            errors.append("camera.range_max_m must be greater than camera.range_min_m.")
    if not (("hfov_deg" in camera and "vfov_deg" in camera) or all(k in camera for k in ("sensor_width_mm", "sensor_height_mm", "focal_mm"))):
        errors.append("camera must provide either hfov_deg and vfov_deg, or sensor_width_mm, sensor_height_mm, and focal_mm.")

    heatmap = cfg.get("heatmap", {})
    if heatmap is not None:
        _mapping(heatmap, "heatmap", errors)
        if isinstance(heatmap, dict):
            _number(heatmap.get("resolution_m"), "heatmap.resolution_m", errors, positive=True, required=False)
            _number(heatmap.get("sigma_m"), "heatmap.sigma_m", errors, positive=True, required=False)
            _number(heatmap.get("target_min_separation_m"), "heatmap.target_min_separation_m", errors, minimum=0.0, required=False)

    if errors:
        raise ConfigValidationError(_format_errors(errors))


def _format_errors(errors: list[str]) -> str:
    return "Invalid scenario config:\n- " + "\n- ".join(errors)


def _require_mapping(cfg: dict[str, Any], path: str, errors: list[str]) -> None:
    if path not in cfg:
        errors.append(f"Missing required section '{path}'.")
    else:
        _mapping(cfg[path], path, errors)


def _mapping(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, dict):
        errors.append(f"{path} must be a mapping.")


def _string(value: Any, path: str, errors: list[str], *, allow_empty: bool) -> None:
    if not isinstance(value, str):
        errors.append(f"{path} must be a string.")
    elif not allow_empty and not value.strip():
        errors.append(f"{path} must not be empty.")


def _as_number(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if number == number and abs(number) != float("inf") else None


def _number(
    value: Any,
    path: str,
    errors: list[str],
    *,
    required: bool = True,
    positive: bool = False,
    minimum: float | None = None,
    maximum: float | None = None,
) -> None:
    if value is None:
        if required:
            errors.append(f"{path} is required.")
        return
    number = _as_number(value)
    if number is None:
        errors.append(f"{path} must be a finite number.")
        return
    if positive and number <= 0.0:
        errors.append(f"{path} must be positive.")
    if minimum is not None and number < minimum:
        errors.append(f"{path} must be greater than or equal to {minimum:g}.")
    if maximum is not None and number >= maximum:
        errors.append(f"{path} must be less than {maximum:g}.")


def _integer(value: Any, path: str, errors: list[str], *, required: bool = True, minimum: int | None = None) -> None:
    if value is None:
        if required:
            errors.append(f"{path} is required.")
        return
    if isinstance(value, bool) or not isinstance(value, int):
        errors.append(f"{path} must be an integer.")
        return
    if minimum is not None and value < minimum:
        errors.append(f"{path} must be greater than or equal to {minimum}.")


def _number_list(
    value: Any,
    path: str,
    errors: list[str],
    *,
    length: int,
    required: bool = True,
    positive: bool = False,
) -> None:
    if value is None:
        if required:
            errors.append(f"{path} is required.")
        return
    if not isinstance(value, list) or len(value) != length:
        errors.append(f"{path} must be a list of {length} numbers.")
        return
    for i, item in enumerate(value):
        _number(item, f"{path}[{i}]", errors, positive=positive)


def _ordered_number_pair(value: Any, path: str, errors: list[str], *, required: bool = True, positive: bool = False) -> None:
    if value is None:
        if required:
            errors.append(f"{path} is required.")
        return
    if not isinstance(value, list) or len(value) != 2:
        errors.append(f"{path} must be a two-item list of numbers.")
        return
    _number(value[0], f"{path}[0]", errors, positive=positive)
    _number(value[1], f"{path}[1]", errors, positive=positive)
    lo = _as_number(value[0])
    hi = _as_number(value[1])
    if lo is not None and hi is not None and hi <= lo:
        errors.append(f"{path}[1] must be greater than {path}[0].")


def _integer_pair(value: Any, path: str, errors: list[str], *, required: bool, minimum: int, ordered: bool) -> None:
    if value is None:
        if required:
            errors.append(f"{path} is required.")
        return
    if not isinstance(value, list) or len(value) != 2:
        errors.append(f"{path} must be a two-item list of integers.")
        return
    _integer(value[0], f"{path}[0]", errors, minimum=minimum)
    _integer(value[1], f"{path}[1]", errors, minimum=minimum)
    if ordered and isinstance(value[0], int) and isinstance(value[1], int) and value[1] < value[0]:
        errors.append(f"{path}[1] must be greater than or equal to {path}[0].")


def _waypoints(value: Any, path: str, errors: list[str]) -> None:
    if not isinstance(value, list) or not value:
        errors.append(f"{path} must contain at least one waypoint.")
        return
    for i, waypoint in enumerate(value):
        _number_list(waypoint, f"{path}[{i}]", errors, length=2)
