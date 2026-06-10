# Green Vigilance Finalization Report

Date: 2026-06-10

## What This Sprint Added

- Per-scenario `summary.json` output under each generated results directory.
- Machine-readable scenario metrics for field size, plant counts, infected leaves/trees, UAV coverage, UAV RMSE, UAV path length, UGV target counts, and generated output paths.
- Scenario comparison command:

```bash
python -m green_vigilance.compare --results results
```

- Comparison outputs:
  - `results/scenario_comparison.csv`
  - `results/scenario_comparison.md`
- README updates covering features, summary outputs, comparison reporting, roadmap, and license.
- Focused tests for summary generation, JSON writing, comparison loading, comparison report writing, and baseline summary output.

## Metrics Now Generated

Each scenario summary includes:

- Scenario name, config path, and random seed.
- Field width, height, and area.
- Tree count, leaf count, infected tree count, and infected leaf count.
- UAV trajectory length, position RMSE, observed leaf count, and observed leaf ratio.
- UGV count, target count, and completed target count.
- Paths to `heatmap.png`, `trajectories.png`, `scene3d.png`, and `summary.json`.
- Known limitations for interpreting the run.

## Validation Commands

Expected final validation commands:

```bash
python -m compileall src
pytest -q
python -m green_vigilance --config configs/baseline.yaml
python -m green_vigilance --config configs/high_noise.yaml
python -m green_vigilance --config configs/extreme_uncertainty.yaml
python -m green_vigilance.compare --results results
```

## Remaining Limitations

- Disease propagation is still a simplified stochastic approximation.
- UGV obstacle avoidance and target completion are first-pass.
- WLS is implemented as a reusable estimator but is not yet integrated into the full UGV localization workflow.
- The 3D scene is a static Matplotlib overview.
- MATLAB/Python numerical equivalence has not been validated.

## Release Readiness

The project is now suitable as a presentable Python baseline: it installs cleanly, runs documented scenarios, writes figures and summaries, compares scenarios, has tests, has CI, and documents remaining research work.
