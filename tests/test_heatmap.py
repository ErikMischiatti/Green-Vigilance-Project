import numpy as np

from green_vigilance.mapping.heatmap import disease_heatmap, top_targets_from_heatmap


def test_heatmap_dimensions_and_targets():
    xy = np.array([[5.0, 5.0], [15.0, 15.0]])
    health = np.array([0.2, 0.9])
    observed = np.array([True, True])
    heat, x_edges, y_edges = disease_heatmap(xy, health, observed, (0.0, 20.0), (0.0, 20.0), 5.0, 4.0)
    assert heat.shape == (4, 4)
    targets = top_targets_from_heatmap(heat, x_edges, y_edges, 1, 1.0)
    assert targets.shape == (1, 2)
