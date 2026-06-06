# Green Vigilance MATLAB to Python Migration Report

## What Was Ported Directly

- `unicycle.m` to `agents/dynamics.py`.
- `jacobians_unicycle.m` to `agents/dynamics.py`.
- EKF initialization, prediction, and GPS update to `estimation/ekf.py`.
- Camera FoV/depth-of-field logic to `sensing/camera.py`.
- Frustum geometry and point visibility checks to `sensing/frustum.py`.

## What Was Redesigned

- MATLAB plotting-heavy scripts were split into simulation state generation and Matplotlib output.
- `config.m` was replaced by YAML scenario files.
- Procedural tree generation was ported into a data-oriented Python model without MATLAB graphics handles.
- The top-level MATLAB scaffold `main.m` was not ported because it called missing functions and was unrelated to Green Vigilance.

## Newly Implemented First-Pass Components

- `estimation/wls.py`: generic weighted position estimation.
- `environment/disease.py`: simple tree-level stochastic disease spread.
- `mapping/heatmap.py`: observed leaf-health heatmap generation.
- `agents/ugv.py`: basic UGV waypoint tracking.
- `control/obstacle_avoidance.py`: simple repulsive angular obstacle correction.
- `simulation/runner.py`: asynchronous UAV scan to UGV target handoff.

## Assumptions

- Paper values were used where clear: 200 m by 200 m field, 80 trees, 4 initially infected trees, 20 m spread radius, baseline/high-noise/extreme-uncertainty scenarios.
- Some MATLAB camera values differed from the paper tables; the Python baseline follows the current MATLAB config style more closely.
- Disease propagation is a simple simulation placeholder, not a validated biological disease model.
- UGV communication is modeled as a direct target assignment after UAV heatmap generation.

## Known Limitations

- Python 3D visualization is not implemented yet.
- The Python outputs are not numerically validated against MATLAB figures.
- UGV obstacle avoidance is intentionally simple.
- WLS is implemented as a generic estimator but not deeply integrated into UGV state estimation yet.
- Heatmap quality depends on observed leaves and current camera path coverage.

## MATLAB Archive

The MATLAB prototype has been copied to `matlab_legacy/`. Original files remain in place for now to avoid accidental loss during migration.

## Validation Commands

Expected commands:

```bash
python3 -m pip install -r requirements.txt
python3 -m compileall src
PYTHONPATH=src pytest -q
PYTHONPATH=src python3 -m green_vigilance --config configs/baseline.yaml
PYTHONPATH=src python3 -m green_vigilance --config configs/high_noise.yaml
PYTHONPATH=src python3 -m green_vigilance --config configs/extreme_uncertainty.yaml
```

Actual validation results in this workspace:

- `.venv/bin/python -m compileall src`: passed.
- `.venv/bin/pytest -q`: passed, 8 tests.
- `.venv/bin/python -m green_vigilance --config configs/baseline.yaml`: passed, observed 1734 / 13218 leaves, UAV RMSE 0.435 m.
- `.venv/bin/green-vigilance --config configs/baseline.yaml`: passed, observed 1734 / 13218 leaves, UAV RMSE 0.435 m.
- `.venv/bin/python -m green_vigilance --config configs/high_noise.yaml`: passed, observed 930 / 14151 leaves, UAV RMSE 1.461 m.
- `.venv/bin/python -m green_vigilance --config configs/extreme_uncertainty.yaml`: passed, observed 0 / 13495 leaves, UAV RMSE 1.658 m. This is documented as an extreme sensing-degradation outcome rather than a validated scientific result.
