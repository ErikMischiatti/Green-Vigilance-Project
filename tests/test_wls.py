import numpy as np
import pytest

from green_vigilance.estimation.wls import weighted_position_estimate


def test_weighted_position_estimate():
    positions = np.array([[0.0, 0.0], [10.0, 0.0]])
    weights = np.array([1.0, 3.0])
    assert np.allclose(weighted_position_estimate(positions, weights), [7.5, 0.0])


def test_weighted_position_estimate_rejects_zero_weights():
    with pytest.raises(ValueError):
        weighted_position_estimate(np.array([[1.0, 2.0]]), np.array([0.0]))
