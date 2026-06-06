import numpy as np

from green_vigilance.sensing.camera import camera_from_specs, detection_radius
from green_vigilance.sensing.frustum import points_in_frustum


def test_camera_fov_and_detection_radius():
    cam = camera_from_specs({"sensor_width_mm": 6.3, "sensor_height_mm": 4.7, "focal_mm": 4.5, "range_min_m": 1.0, "range_max_m": 20.0})
    assert 0.0 < cam.hfov_deg < 180.0
    assert detection_radius(10.0, cam.hfov_deg) > 0.0


def test_points_in_frustum_basic():
    cam = camera_from_specs({"hfov_deg": 90.0, "vfov_deg": 90.0, "range_min_m": 0.5, "range_max_m": 10.0})
    pose = np.array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    pts = np.array([[0.0, 0.0, 5.0], [20.0, 0.0, 5.0], [0.0, 0.0, -1.0]])
    assert points_in_frustum(cam, pose, pts).tolist() == [True, False, False]
