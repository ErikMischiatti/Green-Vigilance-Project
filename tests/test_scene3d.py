from __future__ import annotations

import numpy as np

from green_vigilance.environment.field import Field
from green_vigilance.environment.plants import PlantField
from green_vigilance.sensing.camera import camera_from_specs
from green_vigilance.visualization.scene3d import plot_scene3d


def test_plot_scene3d_creates_png_with_zero_observed_leaves(tmp_path):
    field = Field((0.0, 20.0), (0.0, 20.0), (0.0, 8.0))
    plants = PlantField(
        leaf_xyz=np.array([[5.0, 5.0, 3.0], [6.0, 5.0, 3.5], [14.0, 12.0, 4.0]]),
        leaf_health=np.array([0.9, 0.2, 0.8]),
        leaf_tree_id=np.array([0, 0, 1]),
        tree_centers=np.array([[5.5, 5.0, 3.5], [14.0, 12.0, 4.0]]),
        tree_radius=np.array([2.0, 2.5]),
        tree_health=np.array([0.8, 0.7]),
    )
    observed = np.zeros(len(plants.leaf_xyz), dtype=bool)
    uav_path = np.array([[2.0, 2.0, 6.0], [10.0, 9.0, 6.0], [18.0, 18.0, 6.0]])
    ugv_paths = [np.array([[10.0, 10.0, 0.0], [12.0, 11.0, 0.0]])]
    camera = camera_from_specs({"hfov_deg": 60.0, "vfov_deg": 45.0, "range_min_m": 1.0, "range_max_m": 8.0})
    output = tmp_path / "scene3d.png"

    plot_scene3d(
        field,
        plants,
        plants.leaf_health,
        observed,
        uav_path,
        ugv_paths,
        output,
        camera=camera,
        camera_pose=np.array([18.0, 18.0, 6.0, 0.0, np.deg2rad(80.0), 0.0]),
        scenario_name="test",
    )

    assert output.exists()
    assert output.stat().st_size > 0
