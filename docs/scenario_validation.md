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
| baseline | 3746 | 0.283 | 0.441 | 13218 | 6670 | 2 | yes |
| high_noise | 2393 | 0.169 | 1.466 | 14151 | 9055 | 2 | yes |
| extreme_uncertainty | 2200 | 0.163 | 1.823 | 13495 | 8242 | 2 | yes |

## Observed Trends

- Observed leaf count decreases from baseline to high-noise and remains degraded in the extreme-uncertainty scenario.
- UAV position RMSE increases from baseline to high-noise and increases further in the extreme-uncertainty scenario.
- All scenarios still produce heatmap, trajectory, 3D scene, and summary outputs.
- After report-aligned camera changes, the extreme scenario no longer produces an empty observed heatmap, but its coverage remains below baseline and its RMSE is the worst of the three scenarios.

## Comparison with Report Expectations

The report states that increased sensor uncertainty degrades UAV stability, UGV navigation reliability, and disease-detection performance. The current Python implementation reproduces that trend qualitatively:

- Higher uncertainty produces worse UAV RMSE.
- Higher uncertainty reduces observed plant coverage relative to baseline.
- Extreme uncertainty retains some sensing after report-aligned camera changes, but navigation error is highest.

This is qualitative validation only. Exact numerical agreement with MATLAB/report figures is not established because:

- Some YAML camera, speed, and tree-height parameters are now aligned where the Python model supports them.
- Explicit report uncertainty factors and occlusion radius are not implemented.
- No archived MATLAB run outputs are available as numerical fixtures.

## Interpretation

The current scenarios are useful as a validated Python baseline for regression and future improvement. They should not be cited as reproducing the paper's exact quantitative results.
