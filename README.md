# Green Vigilance: UAV-UGV Simulation for Early Crop Disease Detection

This repository contains the MATLAB implementation of **Green Vigilance**, a simulation framework for precision agriculture that integrates **Unmanned Aerial Vehicles (UAVs)** and **Unmanned Ground Vehicles (UGVs)** for early detection of plant diseases.  
The project combines **aerial surveys**, **ground-level inspections**, and **advanced estimation algorithms** (EKF & WLS) to improve plant monitoring and disease mapping in large agricultural fields.

---

## 🏗️ System Architecture

- **UAV Module**  
  - Flight modeled as a **unicycle model** (position + orientation).  
  - Equipped with **hybrid depth sensing** (3D spatial data + visual input).  
  - State estimation via **Extended Kalman Filter (EKF)**.  

- **UGV Module**  
  - Ground navigation with obstacle avoidance.  
  - Position refinement via **Weighted Least Squares (WLS)**.  
  - Executes local decisions based on UAV heatmaps.  

- **Hybrid Depth Sensor Model**  
  - Accumulates 3D data over time.  
  - Parameters include **FoV, depth resolution, and DoF**.  
  - Enables realistic modeling of plant canopies and disease spread.  

- **Plant & Disease Model**  
  - Simulates tree distribution, canopy growth, and probabilistic disease propagation.  
  - Supports visualization of healthy vs infected plants.  

---

## ⚙️ Repository Structure

```
src/
 ├── alg/
 │    ├── models/
 │    │    ├── unicycle.m             % UAV/UGV motion model
 │    │    ├── jacobians_unicycle.m   % Jacobians for EKF
 │    │
 │    ├── estimators/
 │    │    ├── ekf_init.m             % EKF initialization
 │    │    ├── ekf_predict.m          % EKF prediction step
 │    │    ├── ekf_update_gps.m       % EKF GPS update
 │    │    ├── ekf_update_imu.m       % EKF IMU update
 │    │    ├── wls_update.m           % WLS estimator for UGVs
 │    │
 │    └── control/
 │         ├── uav_control.m          % UAV control laws
 │         ├── ugv_control.m          % UGV control laws
 │
 ├── sim/
 │    ├── vis3d_static.m              % 3D field visualization
 │    ├── run_simulation.m            % Main simulation script
 │
 └── utils/
      ├── draw_field3d.m              % Visualization utilities
      ├── config.m                    % Simulation parameters
```

---

## 📊 Key Features

- **Extended Kalman Filter (EKF)**  
  - Fuses GPS and IMU data for UAV state estimation.  
  - Integrates IMU angular velocity directly into the motion model.  

- **Weighted Least Squares (WLS)**  
  - Multi-UGV cooperative localization.  
  - Accounts for uncertainty by weighting measurements.  

- **Control Laws**  
  - UAV: waypoint navigation, altitude management, velocity clamping.  
  - UGV: obstacle avoidance (trees & other UGVs), adaptive angular velocity.  

- **Visualization**  
  - 3D field rendering with UAV/UGV trajectories.  
  - Heatmaps for disease probability distribution.  
  - Ground-truth vs estimated UAV paths.  

---

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/<repo-name>.git
   cd <repo-name>
   ```

2. Open MATLAB and run the startup script:
   ```matlab
   startup;
   ```

3. Launch a simulation:
   ```matlab
   run_simulation;
   ```

---

## 📈 Results

- UAVs provide broad aerial coverage, generating **disease probability heatmaps**.  
- UGVs refine inspection with **detailed ground data and WLS positioning**.  
- The system demonstrates robustness under sensor noise and varying field conditions.  
- Results highlight the trade-off between **robustness vs precision** in high-uncertainty scenarios.  

---

## 📚 References

This work is based on the study:  
**"Green Vigilance: Drone Innovation for Early Detection of Crop Diseases"**  
Erik Mischiatti, 2024.  

---

## 📌 Future Work

- Integration of **real-world UAV/UGV communication protocols**.  
- Testing with **real agricultural datasets**.  
- Extension to **multi-agent coordination in real-time**.  

---

## 👤 Author

**Erik Mischiatti**  
M.Sc. Mechatronic Engineering (Electronics & Robotics)  
University of Trento & TU Wien  

🔗 [Portfolio](https://erikmischiatti.com) | [IEEE CASE 2024 Paper](https://ieeexplore.ieee.org/)
