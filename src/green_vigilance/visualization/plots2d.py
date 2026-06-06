from __future__ import annotations

from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np


def plot_trajectories(true_path: np.ndarray, est_path: np.ndarray, ugv_paths: list[np.ndarray], targets: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7, 6))
    ax.plot(true_path[:, 0], true_path[:, 1], label="UAV true", color="tab:green")
    ax.plot(est_path[:, 0], est_path[:, 1], label="UAV EKF", color="tab:blue", linestyle="--")
    for i, ugv_path in enumerate(ugv_paths):
        if len(ugv_path):
            ax.plot(ugv_path[:, 0], ugv_path[:, 1], label=f"UGV {i+1}", linewidth=1.5)
    if len(targets):
        ax.scatter(targets[:, 0], targets[:, 1], marker="x", s=80, color="black", label="targets")
    ax.set_aspect("equal", adjustable="box")
    ax.set_xlabel("X (m)")
    ax.set_ylabel("Y (m)")
    ax.grid(True, alpha=0.3)
    ax.legend(loc="best")
    fig.tight_layout()
    fig.savefig(path, dpi=160)
    plt.close(fig)


def plot_heatmap(heat: np.ndarray, x_edges: np.ndarray, y_edges: np.ndarray, targets: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(7, 6))
    image = ax.imshow(heat, origin="lower", extent=[x_edges[0], x_edges[-1], y_edges[0], y_edges[-1]], cmap="YlOrRd", vmin=0, vmax=max(0.01, float(np.max(heat))))
    if len(targets):
        ax.scatter(targets[:, 0], targets[:, 1], marker="x", s=80, color="black")
    fig.colorbar(image, ax=ax, label="disease probability")
    ax.set_xlabel("X (m)")
    ax.set_ylabel("Y (m)")
    ax.set_title("Observed Disease Heatmap")
    fig.tight_layout()
    fig.savefig(path, dpi=160)
    plt.close(fig)
