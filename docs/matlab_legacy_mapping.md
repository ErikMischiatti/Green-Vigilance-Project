# MATLAB Legacy Mapping

This table maps archived MATLAB files to maintained Python modules and records the current validation status.

| MATLAB Legacy File | Python Equivalent | Validation Status | Notes |
|---|---|---|---|
| `matlab_legacy/src/alg/models/unicycle.m` | `src/green_vigilance/agents/dynamics.py` | ported and tested | Exact unicycle integration, speed/angular clipping, and angle wrapping are ported. |
| `matlab_legacy/src/alg/models/jacobians_unicycle.m` | `src/green_vigilance/agents/dynamics.py` | ported and tested | Analytical Jacobians are tested against finite differences. |
| `matlab_legacy/src/estimators/ekf_init.m` | `src/green_vigilance/estimation/ekf.py` | ported and tested | EKF state, covariance, input noise, and GPS covariance conventions are preserved. |
| `matlab_legacy/src/estimators/ekf_predict.m` | `src/green_vigilance/estimation/ekf.py` | ported and tested | Prediction uses unicycle propagation and projected input noise. |
| `matlab_legacy/src/estimators/ekf_update_gps.m` | `src/green_vigilance/estimation/ekf.py` | ported and tested | GPS update uses the Joseph covariance form. |
| `matlab_legacy/src/estimators/ekf_update_imu.m` | `src/green_vigilance/estimation/ekf.py` | ported, partially tested | Heading update exists in Python; scenario runner currently uses gyro in prediction rather than a separate heading update. |
| `matlab_legacy/src/utils/vision/camera_fov_from_specs.m` | `src/green_vigilance/sensing/camera.py` | ported and tested | FoV and DoF/range fallback logic is ported; scenario configs override ranges. |
| `matlab_legacy/src/utils/vision/points_in_frustum.m` | `src/green_vigilance/sensing/frustum.py` | ported and tested | Point-in-frustum logic uses the same ZYX rotation convention and tangent checks. |
| `matlab_legacy/src/utils/vision/camera_frustum_vertices.m` | `src/green_vigilance/sensing/frustum.py` | ported, partially tested | Frustum vertices support visualization; direct numerical vertex fixtures are not yet present. |
| `matlab_legacy/src/utils/vision/ground_footprint_from_altitude.m` | `src/green_vigilance/sensing/frustum.py` | redesigned | Python computes footprint from frustum-ground intersections. |
| `matlab_legacy/src/utils/vision/draw_camera_frustum.m` | `src/green_vigilance/visualization/scene3d.py` | redesigned | Python writes static Matplotlib PNG scenes instead of interactive MATLAB graphics. |
| `matlab_legacy/src/vis/*` | `src/green_vigilance/visualization/*` | first-pass Python replacement | Visualization was redesigned for reproducible PNG outputs. |
| `matlab_legacy/scene/*` | `src/green_vigilance/environment/plants.py`, `src/green_vigilance/visualization/scene3d.py` | redesigned | Tree/leaf generation and 3D rendering are data-oriented Python replacements. |
| `matlab_legacy/scripts/demo_ekf_uav.m` | `src/green_vigilance/simulation/runner.py` | ported, partially tested | UAV waypoint motion, GPS/gyro noise, and EKF loop are represented in the Python scenario runner. |
| `matlab_legacy/scripts/main_sim3d_uav.m` | `src/green_vigilance/simulation/runner.py`, `src/green_vigilance/visualization/scene3d.py` | redesigned | Python combines scan, heatmap, UGV target assignment, summaries, and static figures. |
| MATLAB WLS integration | `src/green_vigilance/estimation/wls.py` | first-pass Python replacement | Generic WLS estimator is tested, but full UGV cooperative localization is not integrated. |
| MATLAB heatmap/disease workflow | `src/green_vigilance/environment/disease.py`, `src/green_vigilance/mapping/heatmap.py` | first-pass Python replacement | These are conceptual Python implementations, not direct MATLAB ports. |
| Full report-level UAV/UGV communication loop | `src/green_vigilance/simulation/runner.py` | first-pass Python replacement | Current runner uses direct target assignment after UAV heatmap generation. |

## Interpretation

The low-level math and camera utilities are the strongest MATLAB-to-Python matches. The full experiment workflow, disease propagation, UGV behavior, WLS integration, and visualization were redesigned to create a maintainable Python baseline and should not be treated as validated MATLAB equivalents.
