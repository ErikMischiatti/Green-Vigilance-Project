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
