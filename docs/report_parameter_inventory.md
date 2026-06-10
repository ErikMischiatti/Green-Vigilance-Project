# Report Parameter Inventory

This inventory compares parameters stated in `docs/Report_distribution_project.pdf` with the current Python scenario YAML files. It documents alignment and differences only; it does not change model behavior.

## Simulation Setup

| Parameter | Report Value | Python Config Value | Status | Notes |
|---|---:|---:|---|---|
| Field size | 200 m x 200 m | `field.xlim=[0, 200]`, `field.ylim=[0, 200]` | matched | All three scenarios use the report field dimensions. |
| Total area | 40,000 m2 | 40,000 m2 | matched | Derived from configured field bounds. |
| Number of trees | 80 | `field.n_trees=80` | matched | All three scenarios match. |
| UAV flight height | 7 m | `camera.altitude_m=7.0` | matched | All scenarios now use the report UAV height. |
| UAV minimum speed | 4 m/s | `uav.v_nom=4.0` | close | Python has one nominal speed/limit rather than separate min/max speed bounds; the nominal value is aligned to the report minimum. |
| UAV maximum speed | 10 m/s | not represented | missing | The current controller does not model a separate maximum speed above `v_nom`. |
| UAV angular velocity | 0.5-1 rad/s | `uav.w_max_deg=60` = 1.047 rad/s | close | Maximum is close to the report upper bound; no minimum angular velocity is modeled. |
| UGV camera height | 1 m | not represented | missing | Current UGV model has motion only, not a separate camera model. |
| UGV minimum speed | 1 m/s | `ugv.v_nom=1.0` | close | Python has one nominal speed/limit rather than separate min/max speed bounds; the nominal value is aligned to the report minimum. |
| UGV maximum speed | 7 m/s | not represented | missing | The current UGV controller does not model a separate maximum speed above `v_nom`. |
| Tree canopy radius | 5 m | `plants.crown_radius_xy=[4.5, 5.0]` | close | Python samples a narrow canopy-radius range around the report value because the generator expects a range. |
| Max tree height | 3 m | `plants.height_range=[2.0, 3.0]` | matched | Python samples tree heights up to the report maximum because the generator expects a range. |
| Initial infected trees | 4 | `disease.initial_infected_trees=4` | matched | All scenarios match. |
| Disease spread radius | 20 m | `disease.spread_radius=20.0` | matched | All scenarios match. |
| Field explored percentage | 30% | not explicitly represented | not implemented | Python reports observed leaf ratio, not explored field percentage. |

## Camera Parameters

| Parameter | Report Value | Python Config Value | Status | Notes |
|---|---:|---:|---|---|
| UAV camera height | 7 m | `camera.altitude_m=7.0` | matched | Same setting as UAV flight height. |
| Focal length | 0.012 m | `camera.focal_mm=12.0` = 0.012 m | matched | All scenarios now use the report focal length. |
| Sensor width | 0.036 m | `camera.sensor_width_mm=36.0` = 0.036 m | matched | All scenarios now use the report sensor width. |
| Sensor height | not specified | `camera.sensor_height_mm=24.0` | deliberate deviation | The Python camera model needs height to compute vertical FoV; 24 mm keeps a conventional 3:2 sensor shape with the report width. |
| f-stop | 4 | `camera.fstop_N=4.0` | matched | All scenarios match. |
| Circle of confusion | 0.03 m in report table | `camera.coc_mm=0.03` = 0.00003 m | different | The report appears to list 0.03 m, while MATLAB/Python code treats CoC as millimeters. |
| Field of view | 114.6 deg | about 112.6 deg from configured width/focal length | close | Python computes FoV from `2 atan(W/(2f))`; the report stated FoV is close but not identical. |
| Minimum focus distance | calculated | computed unless overridden by `range_min_m=1.0` | first-pass | Python supports DoF calculation but scenario configs force near range. |
| Maximum focus distance | calculated | overridden: baseline 18 m, high_noise 16 m, extreme 12 m | deliberate deviation | Kept as an implemented Python uncertainty proxy because explicit report uncertainty factors are not modeled. |

## Noise and Uncertainty Scenarios

| Parameter | Report Value | Python Config Value | Status | Notes |
|---|---:|---:|---|---|
| Simulation 2 UAV sigma height | 0.3 | not represented | not implemented | Python does not model camera height uncertainty directly. |
| Simulation 2 UAV sigma focal length | 0.003 | not represented | not implemented | Python changes configured camera range/noise rather than sampling focal uncertainty. |
| Simulation 2 UAV sigma sensor width | 0.003 | not represented | not implemented | Not directly modeled. |
| Simulation 2 distance uncertainty factor | 0.06 | not represented | not implemented | Not directly modeled. |
| Simulation 2 visibility uncertainty factor | 1.5 | not represented | not implemented | Not directly modeled. |
| Simulation 2 height uncertainty factor | 0.06 | not represented | not implemented | Not directly modeled. |
| Simulation 2 occlusion radius | 8 m | not represented | not implemented | No occlusion model is implemented. |
| Simulation 3 UAV sigma height | 0.8 | not represented | not implemented | Not directly modeled. |
| Simulation 3 UAV sigma focal length | 0.008 | not represented | not implemented | Not directly modeled. |
| Simulation 3 UAV sigma sensor width | 0.008 | not represented | not implemented | Not directly modeled. |
| Simulation 3 distance uncertainty factor | 0.2 | not represented | not implemented | Not directly modeled. |
| Simulation 3 visibility uncertainty factor | 2.5 | not represented | not implemented | Not directly modeled. |
| Simulation 3 height uncertainty factor | 0.15 | not represented | not implemented | Not directly modeled. |
| Simulation 3 occlusion radius | 8 m | not represented | not implemented | No occlusion model is implemented. |
| GPS noise trend | increased in high-noise/extreme cases | 0.8 m, 1.8 m, 3.0 m | first-pass | Python represents degradation through GPS/gyro/control noise and camera range changes. |
| Gyro noise trend | increased in high-noise/extreme cases | 1.5 deg/s, 4.0 deg/s, 8.0 deg/s | first-pass | Qualitatively aligned with increasing uncertainty. |

## Summary

The Python implementation now matches or closely aligns implemented parameters for field dimensions, tree count, UAV height, report camera width/focal length, f-stop, initial infected trees, disease spread radius, report maximum tree height, and lower-bound UAV/UGV nominal speeds. It still does not model separate min/max speed bounds, explicit uncertainty factors, occlusion radius, UGV camera height, or field-exploration percentage. Current scenarios should therefore be treated as report-aligned where implemented, not as a numerically equivalent reproduction of the report.
