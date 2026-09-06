"""
Automated Unit Tests: Isolation Forest Anomaly Detection Engine
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026
"""

import pytest
import os
import tempfile
import numpy as np
from ai.anomaly_engine import DrishtiAnomalyEngine

def test_anomaly_engine_initialization():
    """Verifies default parameters and configuration of the engine."""
    engine = DrishtiAnomalyEngine(contamination=0.10, random_state=42, n_estimators=50)
    assert engine.contamination == 0.10
    assert engine.random_state == 42
    assert engine.n_estimators == 50
    assert not engine.is_fitted

def test_anomaly_engine_fit_predict_deterministic():
    """Verifies deterministic predictions with fixed seeds."""
    rng = np.random.RandomState(42)
    # Generate 100 normal samples + 10 extreme outliers
    normal = rng.normal(loc=0.85, scale=0.05, size=(100, 10))
    outliers = rng.uniform(low=-2.0, high=5.0, size=(10, 10))
    X = np.vstack([normal, outliers])

    engine1 = DrishtiAnomalyEngine(contamination=0.10, random_state=42)
    engine1.fit(X)
    is_anom1, scores1 = engine1.predict(X)

    engine2 = DrishtiAnomalyEngine(contamination=0.10, random_state=42)
    engine2.fit(X)
    is_anom2, scores2 = engine2.predict(X)

    np.testing.assert_array_equal(is_anom1, is_anom2)
    np.testing.assert_array_almost_equal(scores1, scores2)

def test_anomaly_score_range_and_sensitivity():
    """Verifies that scores lie in [0.0, 1.0] and outliers receive higher scores than inliers."""
    rng = np.random.RandomState(42)
    normal = rng.normal(loc=0.85, scale=0.02, size=(80, 10))
    # Extreme divergence sample
    severe_outlier = np.array([[0.10, 0.05, 3.5, 0.10, 0.10, 0.80, 0.50, 4.0, 1.0, 0.95]])

    engine = DrishtiAnomalyEngine(contamination=0.15, random_state=42)
    engine.fit(normal)

    is_normal_anom, normal_scores = engine.predict(normal[:5])
    is_outlier_anom, outlier_scores = engine.predict(severe_outlier)

    # Check bounds
    assert (normal_scores >= 0.0).all() and (normal_scores <= 1.0).all()
    assert (outlier_scores >= 0.0).all() and (outlier_scores <= 1.0).all()

    # The outlier score must exceed the typical inlier score
    assert outlier_scores[0] > np.mean(normal_scores)
    assert bool(is_outlier_anom[0]) is True

def test_anomaly_engine_empty_input():
    """Verifies that empty input matrices return empty arrays without crashing."""
    engine = DrishtiAnomalyEngine()
    is_anom, scores = engine.predict(np.empty((0, 10)))
    assert len(is_anom) == 0
    assert len(scores) == 0

def test_deterministic_statistical_fallback():
    """Verifies that the deterministic statistical fallback produces valid bounded scores."""
    engine = DrishtiAnomalyEngine(random_state=42)
    # Force fallback method directly
    X_sample = np.array([
        [0.85, 0.90, 1.00, 0.95, 0.85, 0.02, 0.002, 0.020, 0.10, 0.05], # standard inlier
        [0.20, 0.10, 2.50, 0.20, 0.20, 0.50, 0.050, 1.500, 0.90, 0.80]  # extreme outlier
    ])
    is_anom, scores = engine._deterministic_statistical_fallback(X_sample)

    assert len(is_anom) == 2
    assert len(scores) == 2
    assert 0.0 <= scores[0] <= 1.0
    assert 0.0 <= scores[1] <= 1.0
    # Inlier score must be smaller than outlier score
    assert scores[0] < scores[1]

def test_save_and_load_persistence():
    """Verifies that model artifacts can be serialized and restored identically."""
    rng = np.random.RandomState(42)
    X = rng.normal(loc=0.8, scale=0.1, size=(50, 10))

    engine = DrishtiAnomalyEngine(random_state=42)
    engine.fit(X)
    pred_orig, score_orig = engine.predict(X[:5])

    with tempfile.NamedTemporaryFile(suffix=".joblib", delete=False) as tmp_file:
        tmp_path = tmp_file.name

    try:
        engine.save(tmp_path)
        assert os.path.exists(tmp_path)

        loaded_engine = DrishtiAnomalyEngine.load(tmp_path)
        assert loaded_engine.is_fitted
        assert loaded_engine.algorithm_name == engine.algorithm_name

        pred_loaded, score_loaded = loaded_engine.predict(X[:5])
        np.testing.assert_array_equal(pred_orig, pred_loaded)
        np.testing.assert_array_almost_equal(score_orig, score_loaded)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
