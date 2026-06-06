# Green Vigilance

Green Vigilance is a Python-first UAV/UGV simulation prototype for early crop disease detection in precision agriculture. The project began as a MATLAB prototype; the active runtime is now the Python package under `src/green_vigilance/` and does not require MATLAB.

The archived MATLAB material is kept in `matlab_legacy/` for reference only. The Python implementation is a runnable migration foundation, not a scientifically complete or production-ready reproduction of the original report.

## Project Status

| Component | Status | Notes |
|---|---|---|
| Python package | Implemented | Installable from `src/green_vigilance/` |
| MATLAB dependency | Removed from active path | MATLAB files are archived as legacy/reference material |
| Scenario configs | Implemented | Baseline, high-noise, and extreme-uncertainty YAML scenarios |
| Unicycle dynamics | Implemented | Ported from MATLAB prototype |
| UAV EKF | Implemented | GPS update and gyro-driven prediction |
| Camera FoV / DoF / frustum | Implemented | Ported and simplified for Python |
| Procedural plant field | First-pass implementation | Conceptual migration, not biologically validated |
| Disease propagation | First-pass implementation | Simplified stochastic tree-level spread |
| Heatmap generation | First-pass implementation | Based on observed leaf health |
| UGV movement | First-pass implementation | Waypoint tracking with simple obstacle avoidance |
| WLS | Implemented, lightly integrated | Generic weighted position estimator; not yet deeply integrated into full UGV localization |
| 3D visualization | Planned / placeholder | MATLAB version archived; Python currently writes 2D figures |
| MATLAB/Python equivalence | Not validated | Numerical equivalence tests are future work |

## Installation

Create a virtual environment and install the package in editable mode:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -e ".[dev]"
```

`requirements.txt` is also provided for simple dependency installation:

```bash
python3 -m pip install -r requirements.txt
```

## Run Simulations

After installation, run a scenario with either the module entry point or console script:

```bash
python -m green_vigilance --config configs/baseline.yaml
green-vigilance --config configs/baseline.yaml
```

Additional scenarios:

```bash
python -m green_vigilance --config configs/high_noise.yaml
python -m green_vigilance --config configs/extreme_uncertainty.yaml
```

Expected generated outputs:

- `results/<scenario>/figures/heatmap.png`
- `results/<scenario>/figures/trajectories.png`

`results/` is generated output and is ignored by git.

## Tests

```bash
python -m compileall src
pytest -q
```

## Repository Structure

```text
configs/                 Scenario YAML files
docs/                    Reports, migration notes, and cleanup notes
matlab_legacy/           Archived MATLAB prototype/reference code
src/green_vigilance/     Active Python package
tests/                   Pytest tests
```

## Known Limitations

- Disease propagation is a simplified stochastic approximation, not a validated biological model.
- UGV obstacle avoidance is simple local steering, not a full planner.
- WLS is available as an estimator but is not yet deeply integrated into full UGV localization.
- Python 3D visualization is currently placeholder-level; normal runs generate 2D figures.
- MATLAB/Python numerical equivalence has not been validated.
- Configuration validation is minimal and should be strengthened before larger experiments.

## Relation to the Original Report

The original project report is preserved in `docs/Report_distribution_project.pdf`. The Python implementation preserves the core direction of the original UAV/UGV disease-monitoring workflow, but future work is needed to validate numerical equivalence and scientific assumptions.

See `docs/migration_report.md` and `docs/cleanup_report.md` for migration and cleanup details.
