from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


SCENARIO_ORDER = ["baseline", "high_noise", "extreme_uncertainty"]
COLUMNS = [
    "scenario",
    "observed_leaf_count",
    "observed_leaf_ratio",
    "uav_position_rmse_m",
    "total_leaf_count",
    "infected_leaf_count",
    "ugv_target_count",
    "outputs_exist",
]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compare Green Vigilance scenario summaries.")
    parser.add_argument("--results", default="results", help="Directory containing scenario result folders.")
    args = parser.parse_args(argv)

    results_dir = Path(args.results)
    rows = compare_scenarios(results_dir)
    write_comparison(rows, results_dir)
    print(f"Wrote {results_dir / 'scenario_comparison.csv'}")
    print(f"Wrote {results_dir / 'scenario_comparison.md'}")
    return 0


def compare_scenarios(results_dir: Path) -> list[dict[str, Any]]:
    summaries = load_summaries(results_dir)
    return [_row_from_summary(summary) for summary in summaries]


def load_summaries(results_dir: Path) -> list[dict[str, Any]]:
    summaries: list[dict[str, Any]] = []
    for scenario in SCENARIO_ORDER:
        path = results_dir / scenario / "summary.json"
        if path.exists():
            summaries.append(json.loads(path.read_text(encoding="utf-8")))

    seen = {str(summary.get("scenario")) for summary in summaries}
    for path in sorted(results_dir.glob("*/summary.json")):
        if path.parent.name in seen:
            continue
        summary = json.loads(path.read_text(encoding="utf-8"))
        summaries.append(summary)
        seen.add(str(summary.get("scenario", path.parent.name)))
    return summaries


def write_comparison(rows: list[dict[str, Any]], results_dir: Path) -> None:
    results_dir.mkdir(parents=True, exist_ok=True)
    csv_path = results_dir / "scenario_comparison.csv"
    md_path = results_dir / "scenario_comparison.md"
    with csv_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=COLUMNS)
        writer.writeheader()
        writer.writerows(rows)
    md_path.write_text(_markdown_table(rows), encoding="utf-8")


def _row_from_summary(summary: dict[str, Any]) -> dict[str, Any]:
    plants = summary.get("plants", {})
    uav = summary.get("uav", {})
    ugv = summary.get("ugv", {})
    return {
        "scenario": summary.get("scenario"),
        "observed_leaf_count": uav.get("observed_leaf_count"),
        "observed_leaf_ratio": _format_float(uav.get("observed_leaf_ratio")),
        "uav_position_rmse_m": _format_float(uav.get("position_rmse_m")),
        "total_leaf_count": plants.get("leaf_count"),
        "infected_leaf_count": plants.get("infected_leaf_count"),
        "ugv_target_count": ugv.get("target_count"),
        "outputs_exist": _outputs_exist(summary.get("outputs", {})),
    }


def _markdown_table(rows: list[dict[str, Any]]) -> str:
    header = "| " + " | ".join(COLUMNS) + " |"
    divider = "| " + " | ".join(["---"] * len(COLUMNS)) + " |"
    body = ["| " + " | ".join(_cell(row.get(column)) for column in COLUMNS) + " |" for row in rows]
    lines = ["# Scenario Comparison", "", header, divider, *body, ""]
    return "\n".join(lines)


def _outputs_exist(outputs: Any) -> bool:
    if not isinstance(outputs, dict):
        return False
    figure_paths = [outputs.get("heatmap"), outputs.get("trajectories"), outputs.get("scene3d")]
    return all(isinstance(path, str) and Path(path).exists() for path in figure_paths)


def _format_float(value: Any) -> str | None:
    if value is None:
        return None
    return f"{float(value):.3f}"


def _cell(value: Any) -> str:
    return "" if value is None else str(value)


if __name__ == "__main__":
    raise SystemExit(main())
