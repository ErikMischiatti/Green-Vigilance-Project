# Green Vigilance Cleanup Report

Date: 2026-06-06

## Inventory

- Active Python package: `src/green_vigilance/`
- Active configs: `configs/baseline.yaml`, `configs/high_noise.yaml`, `configs/extreme_uncertainty.yaml`
- Active tests: `tests/test_camera.py`, `tests/test_disease.py`, `tests/test_dynamics.py`, `tests/test_ekf.py`, `tests/test_heatmap.py`, `tests/test_wls.py`
- Packaging: `pyproject.toml`, `requirements.txt`
- Documentation: `README.md`, `docs/migration_report.md`, `docs/original_project_summary.md`, `docs/Report_distribution_project.pdf`
- Legacy reference material: `matlab_legacy/`

## Files Moved or Archived

- Moved `Report_distribution_project.pdf` to `docs/Report_distribution_project.pdf`.
- Kept MATLAB reference code under `matlab_legacy/`.

## Files Removed

- Removed active-tree MATLAB duplicates: `main.m`, `startup.m`, `config.m`, `scene/`, `scripts/`, `src/alg/`, `src/estimators/`, `src/utils/`, `src/vis/`.
- Removed duplicate legacy report copy: `matlab_legacy/Report_distribution_project.pdf`; the report is now preserved under `docs/`.
- Removed MATLAB autosave: `matlab_legacy/scripts/main_sim3d_uav.asv`.
- Removed generated output and placeholders under `results/`.
- Removed local artifacts: `.venv/`, `.pytest_cache/`, `tests/__pycache__/`, Python package `__pycache__/` directories, and `src/green_vigilance.egg-info/`.
- Removed empty scaffold directories: `data/`, `scene/data/`, `scene/results/`, `scripts/data/`, `scripts/results/`.

## Files Modified

- `.gitignore`: simplified generated-output ignores and added build/package, log, and MATLAB generated-file coverage.
- `README.md`: updated to describe the Python-first status, install/test/run commands, outputs, repository structure, and known limitations.
- `pyproject.toml`: added the `dev` optional dependency group.
- `matlab_legacy/README.md`: replaced scaffold text with legacy-archive guidance.
- `src/green_vigilance/environment/disease.py`: added a guard for zero trees or zero initial infections.
- `tests/test_disease.py`: added a regression test for zero initial infections.

## MATLAB Material Kept

`matlab_legacy/` is kept because it contains reference implementations and visualization scripts from the original prototype. These files are historical material only; the maintained runtime is `src/green_vigilance/`.

## Fragility Review

Fixed:

- `propagate_disease` now returns unchanged health when there are zero trees or zero initially infected trees, avoiding empty-source indexing.
- `pyproject.toml` now provides a `dev` optional dependency group for clean editable installs with tests.
- Extreme scenario execution was verified to handle zero observed leaves while still producing output figures.

Follow-up items:

- WLS exists as a generic estimator but is not deeply integrated into full UGV localization.
- Disease propagation, target assignment, obstacle avoidance, and 3D visualization remain first-pass components.
- The new 3D scene is static PNG output and does not reproduce all MATLAB visual details.
- MATLAB/Python numerical equivalence has not been validated.

## Validation Log

Commands run from a clean virtual environment:

- `python3 -m venv .venv`: passed
- `.venv/bin/python -m pip install --upgrade pip`: passed; pip upgraded to 26.1.2
- `.venv/bin/python -m pip install -e ".[dev]"`: passed
- `.venv/bin/python -m compileall src`: passed
- `.venv/bin/pytest -q`: passed, 17 tests
- `.venv/bin/python -m green_vigilance --config configs/baseline.yaml`: passed; observed 1734 / 13218 leaves; RMSE 0.435 m
- `.venv/bin/python -m green_vigilance --config configs/high_noise.yaml`: passed; observed 930 / 14151 leaves; RMSE 1.461 m
- `.venv/bin/python -m green_vigilance --config configs/extreme_uncertainty.yaml`: passed; observed 0 / 13495 leaves; RMSE 1.658 m
- `.venv/bin/green-vigilance --config configs/baseline.yaml`: passed; observed 1734 / 13218 leaves; RMSE 0.435 m

## GitHub Readiness Notes

- Files intended for tracking: `README.md`, `pyproject.toml`, `requirements.txt`, `.gitignore`, `configs/`, `docs/`, `src/green_vigilance/`, `tests/`, `matlab_legacy/`.
- Files intentionally ignored or removed from tracking: `.venv/`, `__pycache__/`, `.pytest_cache/`, generated `results/`, logs, autosave files, IDE files, and build metadata.
- Curated baseline output images are tracked under `docs/assets/` for GitHub presentation only; the full generated `results/` directory remains ignored.

## Recommended Commit Message

`chore: clean repository for Python Green Vigilance release`

## Recommended Next Development Task

Improve scientific validation and scenario comparison metrics now that configuration validation and basic 3D scene output are available.
