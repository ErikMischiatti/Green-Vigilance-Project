from __future__ import annotations

import numpy as np

from green_vigilance.environment.plants import PlantField


def propagate_disease(
    plants: PlantField,
    initial_infected_trees: int,
    spread_radius: float,
    steps: int,
    seed: int | None,
    base_probability: float = 0.35,
    height_bias: float = 0.15,
) -> np.ndarray:
    """First-pass probabilistic disease propagation.

    This is a simple simulation model, not a validated biological model.
    Health is returned in [0, 1], where lower values indicate more disease.
    """
    rng = np.random.default_rng(seed)
    health = plants.leaf_health.copy()
    n_trees = len(plants.tree_centers)
    if n_trees == 0 or initial_infected_trees <= 0:
        return health

    infected_trees = set(rng.choice(n_trees, size=min(initial_infected_trees, n_trees), replace=False).tolist())
    tree_xy = plants.tree_centers[:, :2]
    tree_z = plants.tree_centers[:, 2]

    for _ in range(max(0, steps)):
        newly: set[int] = set()
        sources = np.array(sorted(infected_trees), dtype=int)
        candidates = [idx for idx in range(n_trees) if idx not in infected_trees]
        for idx in candidates:
            d = np.linalg.norm(tree_xy[sources] - tree_xy[idx], axis=1)
            near_mask = d <= spread_radius
            if not np.any(near_mask):
                continue
            near_sources = sources[near_mask]
            min_distance = float(np.min(d[near_mask]))
            downward_bonus = float(np.mean(tree_z[idx] < tree_z[near_sources])) * height_bias
            distance_factor = 1.0 - 0.25 * min_distance / max(spread_radius, 1e-9)
            p = min(0.95, base_probability + downward_bonus) * distance_factor
            if rng.random() < p:
                newly.add(idx)
        if not newly:
            break
        infected_trees.update(newly)

    infected_mask = np.isin(plants.leaf_tree_id, list(infected_trees))
    health[infected_mask] = np.minimum(health[infected_mask], 0.15 + 0.2 * rng.random(np.count_nonzero(infected_mask)))
    return health
