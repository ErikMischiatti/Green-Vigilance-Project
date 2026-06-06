# Original Project Summary

Green Vigilance was proposed as a distributed UAV/UGV precision-agriculture simulation for early crop disease detection.

The original concept:

- A UAV performs an aerial survey of a field.
- Hybrid depth/camera sensing accumulates 3D spatial information over time.
- Plant health and disease probability are visualized as heatmaps.
- UGVs are deployed after the UAV survey to inspect or treat high-risk areas.
- UAV and UGV agents use unicycle kinematics.
- UAV localization is improved with an Extended Kalman Filter using GPS and IMU-like angular velocity.
- UGV cooperative localization is intended to use Weighted Least Squares.
- Scenarios include baseline operation, increased sensor noise, and extreme uncertainty.

The local MATLAB prototype implemented only part of this:

- UAV unicycle dynamics.
- EKF prediction and GPS update.
- Camera FoV/depth/frustum utilities.
- Procedural 3D trees and leaf health visualization.
- UAV scan demo with visible-leaf highlighting.

Missing from the MATLAB prototype were complete UGV navigation, WLS integration, dynamic disease propagation, heatmaps, UGV target assignment, and a reproducible experiment runner.
