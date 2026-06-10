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


def test_unicycle_motion_at_pi_over_two():
    out = unicycle_step(np.array([0.0, 0.0, np.pi / 2.0]), np.array([2.0, 0.0]), 0.5)
    assert np.allclose(out, [0.0, 1.0, np.pi / 2.0], atol=1e-12)


def test_unicycle_angular_update_wraps_to_pi_interval():
    out = unicycle_step(np.array([0.0, 0.0, np.pi - 0.1]), np.array([0.0, 1.0]), 0.3)
    assert np.allclose(out, [0.0, 0.0, -np.pi + 0.2])


def test_unicycle_output_shape_and_type():
    out = unicycle_step([1.0, 2.0, 0.3], [1.0, 0.2], 0.1)
    assert out.shape == (3,)
    assert out.dtype == float


def test_unicycle_jacobians_match_full_finite_difference():
    x = np.array([1.0, 2.0, 0.4])
    u = np.array([1.5, 0.2])
    dt = 0.1
    f, l = unicycle_jacobians(x, u, dt)

    def step_state(state: np.ndarray) -> np.ndarray:
        return unicycle_step(state, u, dt)

    def step_control(control: np.ndarray) -> np.ndarray:
        return unicycle_step(x, control, dt)

    assert np.allclose(_finite_difference(step_state, x), f, atol=1e-5)
    assert np.allclose(_finite_difference(step_control, u), l, atol=1e-5)


def _finite_difference(func, value: np.ndarray, eps: float = 1e-6) -> np.ndarray:
    base = np.asarray(value, dtype=float)
    y0 = np.asarray(func(base), dtype=float)
    jac = np.zeros((len(y0), len(base)))
    for i in range(len(base)):
        plus = base.copy()
        minus = base.copy()
        plus[i] += eps
        minus[i] -= eps
        jac[:, i] = (np.asarray(func(plus)) - np.asarray(func(minus))) / (2.0 * eps)
    return jac
