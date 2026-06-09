from __future__ import annotations

from copy import deepcopy

import pytest

from green_vigilance.config import ConfigValidationError, load_config, validate_config


CONFIGS = [
    "configs/baseline.yaml",
    "configs/high_noise.yaml",
    "configs/extreme_uncertainty.yaml",
]


def test_existing_configs_load_and_validate():
    for path in CONFIGS:
        cfg = load_config(path)
        assert cfg["field"]["n_trees"] >= 0


def test_missing_required_section_fails_clearly():
    cfg = load_config("configs/baseline.yaml")
    del cfg["simulation"]

    with pytest.raises(ConfigValidationError, match="Missing required section 'simulation'"):
        validate_config(cfg)


def test_negative_dt_fails_clearly():
    cfg = load_config("configs/baseline.yaml")
    cfg["simulation"]["dt"] = -0.1

    with pytest.raises(ConfigValidationError, match="simulation.dt must be positive"):
        validate_config(cfg)


def test_invalid_camera_parameter_fails_clearly():
    cfg = load_config("configs/baseline.yaml")
    cfg["camera"]["focal_mm"] = 0.0

    with pytest.raises(ConfigValidationError, match="camera.focal_mm must be positive"):
        validate_config(cfg)


def test_invalid_count_parameter_fails_clearly():
    cfg = load_config("configs/baseline.yaml")
    cfg["ugv"]["count"] = -1

    with pytest.raises(ConfigValidationError, match="ugv.count must be greater than or equal to 0"):
        validate_config(cfg)


def test_max_speed_must_not_be_less_than_min_speed():
    cfg = deepcopy(load_config("configs/baseline.yaml"))
    cfg["uav"]["v_min"] = 3.0
    cfg["uav"]["v_max"] = 2.0

    with pytest.raises(ConfigValidationError, match="uav.v_max must be greater than or equal to uav.v_min"):
        validate_config(cfg)
