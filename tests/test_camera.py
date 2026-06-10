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


def test_report_like_camera_parameters_match_fov_formula():
    cam = camera_from_specs({
        "sensor_width_mm": 36.0,
        "sensor_height_mm": 24.0,
        "focal_mm": 12.0,
        "range_min_m": 1.0,
        "range_max_m": 40.0,
    })
    expected_hfov = np.rad2deg(2.0 * np.arctan(0.036 / (2.0 * 0.012)))
    assert np.isclose(cam.hfov_deg, expected_hfov)
    assert np.isclose(cam.hfov_deg, 112.62, atol=0.05)


def test_detection_radius_uses_report_formula():
    hfov_deg = np.rad2deg(2.0 * np.arctan(0.036 / (2.0 * 0.012)))
    assert np.isclose(detection_radius(7.0, hfov_deg), 7.0 * np.tan(np.deg2rad(hfov_deg) / 2.0))
