import numpy as np

from green_vigilance.environment.disease import propagate_disease
from green_vigilance.environment.plants import PlantField


def test_propagate_disease_allows_zero_initial_infections():
    plants = PlantField(
        leaf_xyz=np.array([[0.0, 0.0, 1.0], [1.0, 0.0, 1.0]]),
        leaf_health=np.array([0.8, 0.6]),
        leaf_tree_id=np.array([0, 1]),
        tree_centers=np.array([[0.0, 0.0, 1.0], [1.0, 0.0, 1.0]]),
        tree_radius=np.array([1.0, 1.0]),
        tree_health=np.array([0.8, 0.6]),
    )

    health = propagate_disease(plants, initial_infected_trees=0, spread_radius=1.0, steps=1, seed=1)

    assert np.array_equal(health, plants.leaf_health)
