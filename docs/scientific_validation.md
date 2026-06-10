# Scientific Validation Baseline

## Scope

This validation layer checks the current Python implementation against the archived MATLAB code and the original project report where deterministic references are available. It is intended to establish an honest baseline, not to claim full MATLAB/Python or paper-level scientific equivalence.

## Validated Components

### Unicycle Model

`src/green_vigilance/agents/dynamics.py` directly ports `matlab_legacy/src/alg/models/unicycle.m`.

Validated behavior:

- Straight motion at heading 0.
- Motion at heading pi/2.
- Angular update with wrapping to the `[-pi, pi]` interval.
- Output shape and numeric dtype.
- Analytical state/input Jacobians compared against finite differences.

### EKF

`src/green_vigilance/estimation/ekf.py` ports the MATLAB EKF initialization, prediction, GPS update, and heading update structure.

Validated behavior:

- Prediction changes state consistently with the unicycle model.
- Covariance remains approximately symmetric.
- Covariance diagonal remains non-negative in tested cases.
- GPS update reduces estimate distance to a GPS measurement.

### Camera and Frustum

`src/green_vigilance/sensing/camera.py` and `src/green_vigilance/sensing/frustum.py` port the MATLAB FoV and frustum utilities.

Validated behavior:

- FoV follows `2 atan(W / (2f))`.
- Detection radius follows `h tan(FoV / 2)`.
- Report-like camera values produce the mathematically expected FoV; this is near but not identical to the report's stated 114.6 degrees.
- Basic frustum inclusion/exclusion works for points in front, outside angle bounds, and behind the camera.

### WLS

`src/green_vigilance/estimation/wls.py` is a first-pass Python estimator, not a full MATLAB port.

Validated behavior:

- Equal weights produce the arithmetic mean.
- Higher weights pull the estimate toward more reliable measurements.
- Zero/nonpositive weights are ignored, and all-invalid weights raise `ValueError`.

### Scenario Trend

The scenario summaries show the expected qualitative degradation:

- Baseline has the highest observed leaf count and lowest UAV RMSE.
- High-noise has fewer observed leaves and higher UAV RMSE.
- Extreme uncertainty can fully suppress useful leaf observation while still producing run artifacts.

## Alignment with the Report

Aligned:

- Field size: 200 m x 200 m.
- Total field area: 40,000 m2.
- Number of trees: 80.
- Initial infected trees: 4.
- Disease spread radius: 20 m.
- Unicycle dynamics and EKF structure.
- Hybrid camera/FoV/frustum concepts.
- Qualitative trend that increased uncertainty degrades performance.

## Differences from the Report

Different or missing:

- UAV flight height is 10 m in YAML, while the report table states 7 m.
- Python uses 3 m/s nominal UAV speed, while the report lists 4-10 m/s.
- Python camera sensor/focal values differ from the report's 0.036 m sensor width and 0.012 m focal length.
- Report uncertainty factors for distance, visibility, height, and occlusion radius are not represented directly.
- UGV camera height and UGV min/max speed are not modeled as report parameters.
- Field explored percentage is not computed; Python reports observed leaf ratio instead.

## First-Pass Components

- Disease propagation is a simplified stochastic approximation.
- UGV movement is waypoint-based with local obstacle avoidance.
- WLS is implemented as a reusable estimator but is not integrated into UGV cooperative localization.
- Heatmap generation is based on observed leaf health, not a validated disease-detection model.
- 3D visualization is a static Matplotlib overview.
- UAV-to-UGV coordination is direct target assignment, not a full distributed communication model.

## Not Validated

- Full MATLAB/Python numerical equivalence.
- Exact reproduction of report figures or tables.
- Real agricultural disease dynamics.
- Real camera/depth sensor physics.
- Real occlusion behavior.
- Real UAV/UGV communication and cooperative autonomy.

## Recommendations

1. Decide whether future scenarios should match the report tables exactly or preserve the migrated MATLAB demo settings.
2. Add archived numeric MATLAB outputs as fixtures if exact equivalence becomes a requirement.
3. Implement report uncertainty factors and occlusion radius explicitly before claiming scenario-level quantitative validation.
4. Integrate WLS into UGV cooperative localization and add scenario metrics for localization error.
5. Replace the first-pass disease model with a documented model before using disease metrics scientifically.

See also:

- `docs/report_parameter_inventory.md`
- `docs/matlab_legacy_mapping.md`
- `docs/scenario_validation.md`
