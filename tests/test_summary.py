from __future__ import annotations

import json

import numpy as np

from green_vigilance.environment.field import Field
from green_vigilance.environment.plants import PlantField
from green_vigilance.simulation.runner import run_simulation
from green_vigilance.simulation.scenarios import load_scenario
from green_vigilance.simulation.summary import build_summary, write_summary


def test_build_summary_has_required_keys_and_safe_zero_leaf_ratio(tmp_path):
    field = Field((0.0, 20.0), (0.0, 10.0), (0.0, 5.0))
    plants = PlantField(
        leaf_xyz=np.empty((0, 3)),
        leaf_health=np.empty(0),
        leaf_tree_id=np.empty(0, dtype=int),
        tree_centers=np.empty((0, 3)),
        tree_radius=np.empty(0),
        tree_health=np.empty(0),
    )
    outputs = {
        "heatmap": tmp_path / "figures" / "heatmap.png",
        "trajectories": tmp_path / "figures" / "trajectories.png",
        "scene3d": tmp_path / "figures" / "scene3d.png",
        "summary": tmp_path / "summary.json",
    }

    summary = build_summary(
        {"name": "empty", "seed": 7, "_config_path": "configs/empty.yaml"},
        field=field,
        plants=plants,
        leaf_health=np.empty(0),
        observed=np.empty(0, dtype=bool),
        true_path=np.array([[0.0, 0.0, 0.0]]),
        est_path=np.array([[0.0, 0.0, 0.0]]),
        targets=np.empty((0, 2)),
        ugv_paths=[],
        outputs=outputs,
    )

    assert {"scenario", "config_path", "seed", "field", "plants", "uav", "ugv", "outputs", "limitations"} <= summary.keys()
    assert summary["uav"]["observed_leaf_ratio"] is None
    assert all(isinstance(path, str) for path in summary["outputs"].values())


def test_write_summary_writes_json(tmp_path):
    summary = {"scenario": "baseline", "outputs": {"heatmap": "results/baseline/figures/heatmap.png"}}
    path = tmp_path / "baseline" / "summary.json"

    write_summary(summary, path)

    assert json.loads(path.read_text(encoding="utf-8")) == summary


def test_baseline_scenario_writes_summary(tmp_path):
    cfg = load_scenario("configs/baseline.yaml")
    cfg["output"]["dir"] = str(tmp_path / "baseline")
    cfg["simulation"]["duration_s"] = 0.2
    cfg["ugv"]["duration_s"] = 0.2
    cfg["_config_path"] = "configs/baseline.yaml"

    result = run_simulation(cfg)

    summary_path = tmp_path / "baseline" / "summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    assert result["summary_path"] == str(summary_path)
    assert summary["scenario"] == "baseline"
    assert summary["outputs"]["summary"] == str(summary_path)
