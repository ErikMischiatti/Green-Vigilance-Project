# Report Parameter Inventory

This inventory compares parameters stated in `docs/Report_distribution_project.pdf` with the current Python scenario YAML files. It documents alignment and differences only; it does not change model behavior.

## Simulation Setup

| Parameter | Report Value | Python Config Value | Status | Notes |
|---|---:|---:|---|---|
| Field size | 200 m x 200 m | `field.xlim=[0, 200]`, `field.ylim=[0, 200]` | matched | All three scenarios use the report field dimensions. |
| Total area | 40,000 m2 | 40,000 m2 | matched | Derived from configured field bounds. |
| Number of trees | 80 | `field.n_trees=80` | matched | All three scenarios match. |
| UAV flight height | 7 m | `camera.altitude_m=10.0` | different | Python follows the migrated MATLAB visualization/demo setting rather than Table I. |
| UAV minimum speed | 4 m/s | not represented | missing | Python uses a nominal speed controller rather than min/max speed bounds. |
| UAV maximum speed | 10 m/s | `uav.v_nom=3.0` as limit | different | MATLAB demo and Python use 3 m/s nominal speed. |
| UAV angular velocity | 0.5-1 rad/s | `uav.w_max_deg=60` = 1.047 rad/s | close | Maximum is close to the report upper bound; no minimum angular velocity is modeled. |
| UGV camera height | 1 m | not represented | missing | Current UGV model has motion only, not a separate camera model. |
| UGV minimum speed | 1 m/s | not represented | missing | Current UGV uses nominal speed only. |
| UGV maximum speed | 7 m/s | `ugv.v_nom=2.0` | different | Python uses a conservative nominal UGV speed. |
| Tree canopy radius | 5 m | `plants.crown_radius_xy=[2.5, 5.0]` | close | Python samples canopies up to the report value. |
| Max tree height | 3 m | `plants.height_range=[3.0, 7.0]` | different | Python allows taller trees, matching the migrated visual prototype more than Table I. |
| Initial infected trees | 4 | `disease.initial_infected_trees=4` | matched | All scenarios match. |
| Disease spread radius | 20 m | `disease.spread_radius=20.0` | matched | All scenarios match. |
| Field explored percentage | 30% | not explicitly represented | not implemented | Python reports observed leaf ratio, not explored field percentage. |

## Camera Parameters

| Parameter | Report Value | Python Config Value | Status | Notes |
|---|---:|---:|---|---|
| UAV camera height | 7 m | `camera.altitude_m=10.0` | different | Same difference as UAV flight height. |
| Focal length | 0.012 m | baseline/high_noise `0.0045 m`; extreme `0.0065 m` | different | YAML values are 4.5 mm and 6.5 mm. |
| Sensor width | 0.036 m | `0.0063 m` | different | YAML uses compact-camera dimensions. |
| f-stop | 4 | `camera.fstop_N=4.0` | matched | All scenarios match. |
| Circle of confusion | 0.03 m in report table | `camera.coc_mm=0.03` = 0.00003 m | different | The report appears to list 0.03 m, while MATLAB/Python code treats CoC as millimeters. |
| Field of view | 114.6 deg | baseline/high_noise about 70.0 deg; extreme about 51.7 deg | different | Python computes FoV from configured sensor/focal values. Formula with report W=0.036 m and f=0.012 m gives about 112.6 deg. |
| Minimum focus distance | calculated | computed unless overridden by `range_min_m=1.0` | first-pass | Python supports DoF calculation but scenario configs force near range. |
| Maximum focus distance | calculated | overridden: baseline 18 m, high_noise 16 m, extreme 12 m | first-pass | Used as an operational sensing range. |

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

The Python implementation matches the report on field dimensions, tree count, initial infected trees, and disease spread radius. It does not yet reproduce the report parameterization for UAV speed, camera geometry, explicit uncertainty factors, occlusion radius, UGV camera height, or field-exploration percentage. Current scenarios should therefore be treated as a runnable Python baseline with qualitative trend validation, not a numerically equivalent reproduction of the report.
