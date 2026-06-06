import numpy as np

from green_vigilance.agents.dynamics import unicycle_jacobians, unicycle_step


def test_unicycle_straight_motion():
    out = unicycle_step(np.array([0.0, 0.0, 0.0]), np.array([2.0, 0.0]), 0.5)
    assert np.allclose(out, [1.0, 0.0, 0.0])


def test_unicycle_jacobian_shapes_and_numerical_theta():
    x = np.array([1.0, 2.0, 0.4])
    u = np.array([1.5, 0.2])
    f, l = unicycle_jacobians(x, u, 0.1)
    assert f.shape == (3, 3)
    assert l.shape == (3, 2)
    eps = 1e-6
    xp = x.copy()
    xp[2] += eps
    num = (unicycle_step(xp, u, 0.1)[:2] - unicycle_step(x, u, 0.1)[:2]) / eps
    assert np.allclose(num, f[:2, 2], atol=1e-5)
