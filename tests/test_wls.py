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


def test_weighted_position_equal_weights_are_arithmetic_mean():
    positions = np.array([[0.0, 0.0], [10.0, 0.0], [20.0, 6.0]])
    weights = np.ones(3)
    assert np.allclose(weighted_position_estimate(positions, weights), np.mean(positions, axis=0))


def test_weighted_position_higher_weight_pulls_estimate_toward_reliable_measurement():
    positions = np.array([[0.0, 0.0], [10.0, 0.0]])
    equal_weight_estimate = weighted_position_estimate(positions, np.array([1.0, 1.0]))
    high_second_weight_estimate = weighted_position_estimate(positions, np.array([1.0, 9.0]))
    assert high_second_weight_estimate[0] > equal_weight_estimate[0]
