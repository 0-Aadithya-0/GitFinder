import numpy as np
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE


def reduce_to_2d(vectors: list[list[float]]) -> list[tuple[float, float]]:
    """
    Reduce 384-dimensional vectors to 2D coordinates.

    Strategy:
      - < 2 vectors  : return [(0.5, 0.5)] — not enough data to reduce.
      - 2–50 vectors : PCA (fast, deterministic, works with small n).
      - > 50 vectors : t-SNE (better cluster separation for larger sets).

    t-SNE notes:
      - random_state=42 makes results deterministic across restarts.
      - perplexity must be strictly less than n_samples; capped at 30.
    """
    n = len(vectors)

    if n < 2:
        return [(0.5, 0.5)] * n

    matrix = np.array(vectors)

    if n <= 50:
        reduced = PCA(n_components=2).fit_transform(matrix)
    else:
        perplexity = min(30, n - 1)
        reduced = TSNE(
            n_components=2,
            perplexity=perplexity,
            random_state=42,
        ).fit_transform(matrix)

    return [(float(row[0]), float(row[1])) for row in reduced]


def normalize_coordinates(
    points: list[tuple[float, float]],
) -> list[tuple[float, float]]:
    """
    Normalize x and y coordinates independently to strictly [0.0, 1.0].

    Formula: v_norm = (v - v_min) / (v_max - v_min)

    Edge case: if all points share the same value on an axis (max == min),
    every point on that axis is mapped to 0.5 to avoid division by zero.
    """
    if not points:
        return []

    xs = [p[0] for p in points]
    ys = [p[1] for p in points]

    def _norm(values: list[float]) -> list[float]:
        v_min, v_max = min(values), max(values)
        span = v_max - v_min
        if span == 0:
            return [0.5] * len(values)
        return [(v - v_min) / span for v in values]

    norm_xs = _norm(xs)
    norm_ys = _norm(ys)

    return list(zip(norm_xs, norm_ys))
