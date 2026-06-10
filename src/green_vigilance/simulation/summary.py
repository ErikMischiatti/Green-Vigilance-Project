from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np

from green_vigilance.environment.field import Field
from green_vigilance.environment.plants import PlantField


LIMITATIONS = [
    "UGV/WLS integration is first-pass",
    "Disease propagation is a simplified stochastic model",
    "3D visualization is static",
    "MATLAB/Python numerical equivalence has not been validated",
]


def build_summary(
    cfg: dict[str, Any],
    *,
    field: Field,
    plants: PlantField,
    leaf_health: np.ndarray,
    observed: np.ndarray,
    true_path: np.ndarray,
    est_path: np.ndarray,
    targets: np.ndarray,
    ugv_paths: list[np.ndarray],
    outputs: dict[str, Path],
) -> dict[str, Any]:
    """Build a JSON-serializable summary from an already completed run."""
    total_leaves = int(len(observed))
    observed_count = int(np.count_nonzero(observed))
    infected_leaf_mask = np.asarray(leaf_health, dtype=float) < 0.5
    infected_leaf_count = int(np.count_nonzero(infected_leaf_mask))
    infected_tree_count = int(len(np.unique(plants.leaf_tree_id[infected_leaf_mask]))) if infected_leaf_count else 0
    completed_targets = _completed_target_count(ugv_paths, targets)

    return {
        "scenario": str(cfg.get("name", Path(str(cfg.get("output", {}).get("dir", "results"))).name)),
        "config_path": _optional_string(cfg.get("_config_path")),
        "seed": _optional_int(cfg.get("seed")),
        "field": {
            "width_m": float(field.xlim[1] - field.xlim[0]),
            "height_m": float(field.ylim[1] - field.ylim[0]),
            "area_m2": float((field.xlim[1] - field.xlim[0]) * (field.ylim[1] - field.ylim[0])),
        },
        "plants": {
            "tree_count": int(len(plants.tree_centers)),
            "leaf_count": total_leaves,
            "infected_tree_count": infected_tree_count,
            "infected_leaf_count": infected_leaf_count,
        },
        "uav": {
            "trajectory_length_m": _path_length(true_path[:, :2]),
            "position_rmse_m": _position_rmse(true_path[:, :2], est_path[:, :2]),
            "observed_leaf_count": observed_count,
            "observed_leaf_ratio": _safe_ratio(observed_count, total_leaves),
        },
        "ugv": {
            "count": int(len(ugv_paths)),
            "target_count": int(len(targets)),
            "completed_target_count": completed_targets,
        },
        "outputs": {name: str(path) for name, path in outputs.items()},
        "limitations": LIMITATIONS,
    }


def write_summary(summary: dict[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _path_length(points: np.ndarray) -> float:
    arr = np.asarray(points, dtype=float)
    if arr.ndim != 2 or len(arr) < 2:
        return 0.0
    return float(np.sum(np.linalg.norm(np.diff(arr, axis=0), axis=1)))


def _position_rmse(true_xy: np.ndarray, est_xy: np.ndarray) -> float | None:
    true_arr = np.asarray(true_xy, dtype=float)
    est_arr = np.asarray(est_xy, dtype=float)
    if true_arr.shape != est_arr.shape or true_arr.ndim != 2 or len(true_arr) == 0:
        return None
    return float(np.sqrt(np.mean(np.sum((true_arr - est_arr) ** 2, axis=1))))


def _safe_ratio(numerator: int, denominator: int) -> float | None:
    if denominator <= 0:
        return None
    return float(numerator / denominator)


def _completed_target_count(ugv_paths: list[np.ndarray], targets: np.ndarray, tolerance_m: float = 2.0) -> int:
    target_arr = np.asarray(targets, dtype=float)
    if target_arr.ndim != 2 or target_arr.shape[1] < 2:
        return 0
    completed = 0
    for path, target in zip(ugv_paths, target_arr):
        arr = np.asarray(path, dtype=float)
        if arr.ndim == 2 and len(arr) and arr.shape[1] >= 2:
            completed += int(float(np.linalg.norm(arr[-1, :2] - target[:2])) <= tolerance_m)
    return completed


def _optional_string(value: Any) -> str | None:
    if value is None:
        return None
    return str(value)


def _optional_int(value: Any) -> int | None:
    if value is None:
        return None
    return int(value)
