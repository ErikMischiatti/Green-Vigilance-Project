import numpy as np

from green_vigilance.estimation.ekf import EKFState


def test_ekf_predict_update_shapes_and_covariance():
    ekf = EKFState.initialize(
        np.array([0.0, 0.0, 0.0]),
        np.eye(3),
        sigma_v=0.1,
        sigma_omega=0.05,
        r_gps=np.eye(2) * 0.25,
    )
    ekf.predict(np.array([1.0, 0.1]), 0.2)
    assert ekf.x.shape == (3,)
    assert ekf.p.shape == (3, 3)
    before_trace = np.trace(ekf.p)
    ekf.update_gps(np.array([0.2, 0.0]))
    assert np.trace(ekf.p) < before_trace
    assert np.all(np.linalg.eigvalsh(ekf.p) >= -1e-9)


def test_ekf_prediction_matches_unicycle_model_and_covariance_is_symmetric():
    from green_vigilance.agents.dynamics import unicycle_step

    x0 = np.array([1.0, 2.0, 0.3])
    control = np.array([1.2, 0.2])
    ekf = EKFState.initialize(x0, np.eye(3) * 0.1, sigma_v=0.05, sigma_omega=0.02, r_gps=np.eye(2) * 0.25)
    ekf.predict(control, 0.2)
    assert np.allclose(ekf.x, unicycle_step(x0, control, 0.2))
    assert np.allclose(ekf.p, ekf.p.T, atol=1e-12)
    assert np.all(np.diag(ekf.p) >= 0.0)


def test_ekf_gps_update_pulls_estimate_toward_measurement():
    ekf = EKFState.initialize(
        np.array([10.0, 0.0, 0.0]),
        np.eye(3),
        sigma_v=0.1,
        sigma_omega=0.05,
        r_gps=np.eye(2) * 0.01,
    )
    measurement = np.array([0.0, 0.0])
    before = np.linalg.norm(ekf.x[:2] - measurement)
    ekf.update_gps(measurement)
    after = np.linalg.norm(ekf.x[:2] - measurement)
    assert after < before
    assert np.allclose(ekf.p, ekf.p.T, atol=1e-12)
    assert np.all(np.diag(ekf.p) >= 0.0)
