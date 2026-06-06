from __future__ import annotations

from pathlib import Path
from typing import Any

import numpy as np

from green_vigilance.agents.dynamics import MotionLimits, unicycle_step
from green_vigilance.agents.ugv import UGV
from green_vigilance.control.waypoint import waypoint_control
from green_vigilance.environment.disease import propagate_disease
from green_vigilance.environment.field import Field
from green_vigilance.environment.plants import generate_trees
from green_vigilance.estimation.ekf import EKFState
from green_vigilance.mapping.heatmap import disease_heatmap, top_targets_from_heatmap
from green_vigilance.sensing.camera import camera_from_specs
from green_vigilance.sensing.frustum import points_in_frustum
from green_vigilance.visualization.plots2d import plot_heatmap, plot_trajectories


def run_simulation(cfg: dict[str, Any]) -> dict[str, Any]:
    seed = int(cfg.get("seed", 42))
    rng = np.random.default_rng(seed)
    output_dir = Path(cfg.get("output", {}).get("dir", "results"))
    figure_dir = output_dir / "figures"

    field_cfg = cfg["field"]
    field = Field(tuple(field_cfg["xlim"]), tuple(field_cfg["ylim"]), tuple(field_cfg.get("zlim", [0.0, 10.0])))
    plants = generate_trees(field, int(field_cfg["n_trees"]), seed=seed, **cfg.get("plants", {}))
    disease_cfg = cfg.get("disease", {})
    leaf_health = propagate_disease(
        plants,
        initial_infected_trees=int(disease_cfg.get("initial_infected_trees", 4)),
        spread_radius=float(disease_cfg.get("spread_radius", 20.0)),
        steps=int(disease_cfg.get("steps", 1)),
        seed=seed + 1,
        base_probability=float(disease_cfg.get("base_probability", 0.25)),
        height_bias=float(disease_cfg.get("height_bias", 0.15)),
    )

    sim_cfg = cfg["simulation"]
    uav_cfg = cfg["uav"]
    noise_cfg = cfg.get("noise", {})
    dt = float(sim_cfg["dt"])
    t_final = float(sim_cfg["duration_s"])
    times = np.arange(0.0, t_final + 1e-12, dt)
    gps_dt = 1.0 / max(float(uav_cfg.get("gps_hz", 1.0)), 1e-9)
    gps_tick = 0.0

    x_true = np.asarray(uav_cfg["initial_state"], dtype=float)
    x0_est = x_true + np.asarray(uav_cfg.get("initial_estimate_error", [0.5, -0.5, np.deg2rad(5.0)]), dtype=float)
    p0 = np.diag(uav_cfg.get("initial_covariance", [1.0, 1.0, np.deg2rad(10.0)])) ** 2
    sigma_gps = float(noise_cfg.get("sigma_gps_m", 0.8))
    sigma_gyro = np.deg2rad(float(noise_cfg.get("sigma_gyro_deg", 1.5)))
    sigma_v = float(noise_cfg.get("sigma_vcmd", 0.15))
    sigma_omega = np.deg2rad(float(noise_cfg.get("sigma_omega_deg", 2.0)))
    ekf = EKFState.initialize(x0_est, p0, sigma_v, sigma_omega, np.diag([sigma_gps, sigma_gps]) ** 2)

    waypoints = np.asarray(uav_cfg["waypoints"], dtype=float)
    wp_index = 0
    wp_tol = float(uav_cfg.get("waypoint_tolerance", 3.0))
    v_nom = float(uav_cfg.get("v_nom", 3.0))
    w_max = np.deg2rad(float(uav_cfg.get("w_max_deg", 60.0)))
    kp_ang = float(uav_cfg.get("kp_ang", 1.6))
    kp_dist = float(uav_cfg.get("kp_dist", 0.6))
    limits = MotionLimits(vmax=v_nom, wmax=w_max)

    camera = camera_from_specs(cfg["camera"])
    altitude = float(cfg["camera"].get("altitude_m", field.zlim[1]))
    pitch = np.deg2rad(float(cfg["camera"].get("pitch_deg", 80.0)))
    roll = np.deg2rad(float(cfg["camera"].get("roll_deg", 0.0)))

    true_path = np.zeros((len(times), 3))
    est_path = np.zeros((len(times), 3))
    observed = np.zeros(len(plants.leaf_xyz), dtype=bool)

    for k, now in enumerate(times):
        control, dist = waypoint_control(x_true, waypoints[wp_index], v_nom, w_max, kp_ang, kp_dist)
        x_true = unicycle_step(x_true, control, dt, limits)
        omega_meas = control[1] + sigma_gyro * rng.normal()
        ekf.predict(np.array([control[0], omega_meas]), dt, limits)
        if now >= gps_tick - 1e-9:
            z_gps = x_true[:2] + sigma_gps * rng.normal(size=2)
            ekf.update_gps(z_gps)
            gps_tick += gps_dt
        pose = np.array([x_true[0], x_true[1], altitude, x_true[2], pitch, roll])
        observed |= points_in_frustum(camera, pose, plants.leaf_xyz)
        true_path[k] = x_true
        est_path[k] = ekf.x
        if dist < wp_tol:
            wp_index = (wp_index + 1) % len(waypoints)

    heat_cfg = cfg.get("heatmap", {})
    heat, x_edges, y_edges = disease_heatmap(
        plants.leaf_xyz[:, :2],
        leaf_health,
        observed,
        field.xlim,
        field.ylim,
        resolution=float(heat_cfg.get("resolution_m", 5.0)),
        sigma=float(heat_cfg.get("sigma_m", 8.0)),
    )

    ugv_cfg = cfg.get("ugv", {})
    ugv_count = int(ugv_cfg.get("count", 2))
    targets = top_targets_from_heatmap(heat, x_edges, y_edges, ugv_count, float(heat_cfg.get("target_min_separation_m", 15.0)))
    if len(targets) < ugv_count:
        fallback = np.asarray([field.center_xy] * (ugv_count - len(targets)), dtype=float)
        targets = np.vstack([targets, fallback]) if len(targets) else fallback

    ugvs = [UGV(np.array([field.center_xy[0], field.center_xy[1], 0.0 + i * 0.1]), targets[i]) for i in range(ugv_count)]
    for ugv in ugvs:
        ugv.path.append(ugv.state.copy())
    ugv_steps = int(float(ugv_cfg.get("duration_s", 45.0)) / dt)
    for _ in range(ugv_steps):
        states_xy = np.vstack([u.state[:2] for u in ugvs])
        for i, ugv in enumerate(ugvs):
            other = np.delete(states_xy, i, axis=0)
            obstacles = np.vstack([plants.tree_centers[:, :2], other]) if len(other) else plants.tree_centers[:, :2]
            ugv.step(
                dt,
                float(ugv_cfg.get("v_nom", 2.0)),
                np.deg2rad(float(ugv_cfg.get("w_max_deg", 60.0))),
                float(ugv_cfg.get("kp_ang", 1.4)),
                float(ugv_cfg.get("kp_dist", 0.5)),
                obstacles,
                float(ugv_cfg.get("obstacle_radius_m", 6.0)),
                float(ugv_cfg.get("obstacle_gain", 0.8)),
            )

    ugv_paths = [np.asarray(u.path) for u in ugvs]
    plot_heatmap(heat, x_edges, y_edges, targets, figure_dir / "heatmap.png")
    plot_trajectories(true_path, est_path, ugv_paths, targets, figure_dir / "trajectories.png")

    rmse = float(np.sqrt(np.mean(np.sum((true_path[:, :2] - est_path[:, :2]) ** 2, axis=1))))
    return {
        "true_path": true_path,
        "est_path": est_path,
        "observed_leaf_count": int(np.count_nonzero(observed)),
        "total_leaf_count": int(len(observed)),
        "heatmap": heat,
        "targets": targets,
        "ugv_paths": ugv_paths,
        "uav_position_rmse_m": rmse,
        "figures": [str(figure_dir / "heatmap.png"), str(figure_dir / "trajectories.png")],
    }
