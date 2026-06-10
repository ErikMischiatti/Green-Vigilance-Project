# Scenario Validation

This document summarizes the current Python scenario behavior against the original report's qualitative expectations. It uses generated `summary.json` files and `results/scenario_comparison.md`.

## Commands

```bash
python -m green_vigilance --config configs/baseline.yaml
python -m green_vigilance --config configs/high_noise.yaml
python -m green_vigilance --config configs/extreme_uncertainty.yaml
python -m green_vigilance.compare --results results
```

## Scenario Summary

| Scenario | Observed Leaves | Observed Ratio | UAV RMSE (m) | Total Leaves | Infected Leaves | UGV Targets | Outputs Exist |
|---|---:|---:|---:|---:|---:|---:|---|
| baseline | 1734 | 0.131 | 0.435 | 13218 | 6811 | 2 | yes |
| high_noise | 930 | 0.066 | 1.461 | 14151 | 8876 | 2 | yes |
| extreme_uncertainty | 0 | 0.000 | 1.658 | 13495 | 8242 | 2 | yes |

## Observed Trends

- Observed leaf count decreases from baseline to high-noise and reaches zero in the extreme-uncertainty scenario.
- UAV position RMSE increases from baseline to high-noise and increases further in the extreme-uncertainty scenario.
- All scenarios still produce heatmap, trajectory, 3D scene, and summary outputs.
- The extreme scenario produces an empty observed heatmap because the configured sensing range/focal setup prevents leaves from entering the camera frustum during the run.

## Comparison with Report Expectations

The report states that increased sensor uncertainty degrades UAV stability, UGV navigation reliability, and disease-detection performance. The current Python implementation reproduces that trend qualitatively:

- Higher uncertainty produces worse UAV RMSE.
- Higher uncertainty reduces observed plant coverage.
- Extreme uncertainty can eliminate useful sensing output.

This is qualitative validation only. Exact numerical agreement with MATLAB/report figures is not established because:

- The YAML camera, speed, and tree-height parameters differ from report tables.
- Explicit report uncertainty factors and occlusion radius are not implemented.
- No archived MATLAB run outputs are available as numerical fixtures.

## Interpretation

The current scenarios are useful as a validated Python baseline for regression and future improvement. They should not be cited as reproducing the paper's exact quantitative results.
