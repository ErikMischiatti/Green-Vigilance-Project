from __future__ import annotations

import csv
import json

from green_vigilance.compare import compare_scenarios, write_comparison


def test_compare_scenarios_loads_summary_rows(tmp_path):
    scenario_dir = tmp_path / "baseline"
    figures = scenario_dir / "figures"
    figures.mkdir(parents=True)
    for name in ("heatmap.png", "trajectories.png", "scene3d.png"):
        (figures / name).write_text("png", encoding="utf-8")
    (scenario_dir / "summary.json").write_text(
        json.dumps(
            {
                "scenario": "baseline",
                "plants": {"leaf_count": 10, "infected_leaf_count": 2},
                "uav": {"observed_leaf_count": 5, "observed_leaf_ratio": 0.5, "position_rmse_m": 1.25},
                "ugv": {"target_count": 2},
                "outputs": {
                    "heatmap": str(figures / "heatmap.png"),
                    "trajectories": str(figures / "trajectories.png"),
                    "scene3d": str(figures / "scene3d.png"),
                },
            }
        ),
        encoding="utf-8",
    )

    rows = compare_scenarios(tmp_path)

    assert rows == [
        {
            "scenario": "baseline",
            "observed_leaf_count": 5,
            "observed_leaf_ratio": "0.500",
            "uav_position_rmse_m": "1.250",
            "total_leaf_count": 10,
            "infected_leaf_count": 2,
            "ugv_target_count": 2,
            "outputs_exist": True,
        }
    ]


def test_write_comparison_outputs_csv_and_markdown(tmp_path):
    rows = [
        {
            "scenario": "baseline",
            "observed_leaf_count": 5,
            "observed_leaf_ratio": "0.500",
            "uav_position_rmse_m": "1.250",
            "total_leaf_count": 10,
            "infected_leaf_count": 2,
            "ugv_target_count": 2,
            "outputs_exist": True,
        }
    ]

    write_comparison(rows, tmp_path)

    csv_rows = list(csv.DictReader((tmp_path / "scenario_comparison.csv").open(encoding="utf-8")))
    markdown = (tmp_path / "scenario_comparison.md").read_text(encoding="utf-8")
    assert csv_rows[0]["scenario"] == "baseline"
    assert "| baseline |" in markdown
