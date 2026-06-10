# Green Vigilance Roadmap

## 1. Scientific Validation

- Select MATLAB reference runs and reproduce key numeric outputs in Python.
- Document accepted tolerances for EKF, camera coverage, heatmap, and trajectory metrics.
- Add regression fixtures for validated baseline outputs.

## 2. WLS and UGV Integration

- Connect the WLS estimator to UGV cooperative localization state.
- Model UGV-to-UGV and UAV-to-UGV measurement availability explicitly.
- Add tests for localization degradation under noise and missing measurements.

## 3. Disease Model

- Replace the current stochastic placeholder with a documented agronomic spread model.
- Parameterize disease spread and health degradation from report assumptions or external sources.
- Add scenario-specific validation metrics for infection progression.

## 4. Visualization

- Improve the static 3D scene with clearer agent markers, camera footprint overlays, and target annotations.
- Consider optional animation or interactive inspection after the baseline outputs are stable.
- Keep generated visual outputs reproducible and lightweight for CI.

## 5. Packaging and Release

- Pin release artifacts and example output summaries.
- Add a tagged release workflow if distribution beyond source install is needed.
- Publish final documentation with the original report, migration notes, cleanup notes, and generated comparison examples.
