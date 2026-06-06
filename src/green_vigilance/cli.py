from __future__ import annotations

import argparse

from green_vigilance.simulation.runner import run_simulation
from green_vigilance.simulation.scenarios import load_scenario


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run the Green Vigilance Python simulation.")
    parser.add_argument("--config", default="configs/baseline.yaml", help="Path to a YAML scenario config.")
    args = parser.parse_args(argv)
    cfg = load_scenario(args.config)
    result = run_simulation(cfg)
    print(f"Green Vigilance simulation complete")
    print(f"Observed leaves: {result['observed_leaf_count']} / {result['total_leaf_count']}")
    print(f"UAV position RMSE: {result['uav_position_rmse_m']:.3f} m")
    for figure in result["figures"]:
        print(f"Wrote {figure}")
    return 0
