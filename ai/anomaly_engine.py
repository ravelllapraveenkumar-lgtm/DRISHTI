"""
DRISHTI AI Engine: Unsupervised Anomaly Detection Engine
Algorithm: Isolation Forest (Scikit-Learn) with Deterministic Robust Statistical Fallback
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026

Responsible AI Directive:
This engine identifies potential anomalies and produces a continuous divergence score.
It NEVER declares guilt, fraud, corruption, or legal liability.
"""

from typing import Tuple, Dict, Any, Optional, List
import os
import logging
import numpy as np
import pandas as pd
import joblib

try:
    from sklearn.ensemble import IsolationForest
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False

logger = logging.getLogger("drishti.ai.anomaly_engine")

class DrishtiAnomalyEngine:
    """
    Unsupervised telemetry anomaly detector leveraging Isolation Forest.
    Guarantees deterministic results via fixed random_state.
    Provides a mathematically rigorous fallback if ML estimators are unfitted.
    """
    def __init__(
        self,
        contamination: float = 0.15,
        random_state: int = 42,
        n_estimators: int = 100
    ):
        self.contamination = contamination
        self.random_state = random_state
        self.n_estimators = n_estimators
        self.is_fitted = False
        self.algorithm_name = "ISOLATION_FOREST_V1" if SKLEARN_AVAILABLE else "STATISTICAL_FALLBACK_V1"

        if SKLEARN_AVAILABLE:
            self.model: Optional[IsolationForest] = IsolationForest(
                contamination=self.contamination,
                random_state=self.random_state,
                n_estimators=self.n_estimators,
                bootstrap=False
            )
        else:
            self.model = None

        # Feature baseline statistics for fallback and calibration
        self.feature_means: Optional[np.ndarray] = None
        self.feature_stds: Optional[np.ndarray] = None
        self.min_decision_val: float = -0.5
        self.max_decision_val: float = 0.5

    def fit(self, X: np.ndarray) -> "DrishtiAnomalyEngine":
        """
        Fits the Isolation Forest on the feature matrix X.
        X shape: (n_samples, n_features)
        """
        if X is None or len(X) == 0:
            raise ValueError("Feature matrix X cannot be empty for fitting.")

        X_arr = np.asarray(X, dtype=np.float64)

        # Record baseline distributions for explainability & fallback
        self.feature_means = np.mean(X_arr, axis=0)
        self.feature_stds = np.std(X_arr, axis=0)
        # Avoid zero standard deviation
        self.feature_stds = np.where(self.feature_stds < 1e-6, 1e-3, self.feature_stds)

        if SKLEARN_AVAILABLE and self.model is not None:
            self.model.fit(X_arr)
            # Calibrate decision function bounds
            decisions = self.model.decision_function(X_arr)
            self.min_decision_val = float(np.min(decisions))
            self.max_decision_val = float(np.max(decisions))
            self.algorithm_name = "ISOLATION_FOREST_V1"
        else:
            self.algorithm_name = "STATISTICAL_FALLBACK_V1"
            logger.warning("Scikit-learn unavailable; engine initialized in deterministic statistical fallback mode.")

        self.is_fitted = True
        return self

    def predict(self, X: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Predicts anomaly indicators and continuous divergence scores for feature matrix X.
        Returns:
            is_anomaly: boolean array of shape (n_samples,), where True indicates potential anomaly
            anomaly_score: float array of shape (n_samples,), bounded in [0.0, 1.0] (higher = more anomalous)
        """
        if X is None or len(X) == 0:
            return np.array([], dtype=bool), np.array([], dtype=np.float64)

        X_arr = np.asarray(X, dtype=np.float64)

        # If model is fitted with scikit-learn, use Isolation Forest
        if self.is_fitted and SKLEARN_AVAILABLE and self.model is not None:
            # model.predict returns -1 for anomalies, 1 for inliers
            raw_preds = self.model.predict(X_arr)
            is_anomaly = (raw_preds == -1)

            # decision_function returns negative for anomalies, positive for inliers
            # Typically ranges from roughly -0.35 to +0.25
            decisions = self.model.decision_function(X_arr)

            # Convert decision values to [0.0, 1.0] anomaly score using inverted sigmoid
            # When decision is <= 0 (anomaly), score > 0.5
            # When decision > 0 (inlier), score < 0.5
            scale_factor = 8.0
            anomaly_score = 1.0 / (1.0 + np.exp(scale_factor * decisions))
            anomaly_score = np.clip(anomaly_score, 0.0, 1.0)
            return is_anomaly, np.round(anomaly_score, 4)

        # Fallback: Deterministic statistical deviation scoring
        return self._deterministic_statistical_fallback(X_arr)

    def _deterministic_statistical_fallback(self, X: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Clearly documented deterministic fallback using standardized Mahalanobis/Z-score proxy.
        Used when scikit-learn model is not fitted or unavailable.
        """
        if self.feature_means is not None and self.feature_stds is not None:
            means = self.feature_means
            stds = self.feature_stds
        else:
            # Canonical MoSJE empirical baseline reference values
            # Order: attendance_rate, biometric_rate, meal_service_rate, cctv_uptime_norm,
            #        occupancy_ratio, roster_discrepancy_rate, attendance_variance,
            #        geofence_offset_km, inspection_delay_norm, monitoring_deviation
            means = np.array([0.85, 0.90, 1.00, 0.95, 0.85, 0.02, 0.002, 0.020, 0.10, 0.05])
            stds = np.array([0.10, 0.10, 0.15, 0.10, 0.10, 0.04, 0.003, 0.030, 0.20, 0.10])

        z_scores = np.abs((X - means) / stds)
        # Composite divergence is the weighted sum of normalized deviations
        divergence = np.mean(z_scores, axis=1) / 3.0
        anomaly_score = np.clip(divergence, 0.0, 1.0)
        # Anomaly threshold at 0.45 divergence
        is_anomaly = anomaly_score >= 0.45
        return is_anomaly, np.round(anomaly_score, 4)

    def save(self, model_path: str) -> None:
        """
        Persists the trained engine artifact to disk using joblib.
        """
        os.makedirs(os.path.dirname(os.path.abspath(model_path)), exist_ok=True)
        payload = {
            "model": self.model,
            "contamination": self.contamination,
            "random_state": self.random_state,
            "n_estimators": self.n_estimators,
            "is_fitted": self.is_fitted,
            "algorithm_name": self.algorithm_name,
            "feature_means": self.feature_means,
            "feature_stds": self.feature_stds,
            "min_decision_val": self.min_decision_val,
            "max_decision_val": self.max_decision_val
        }
        joblib.dump(payload, model_path)
        logger.info(f"Model saved successfully to {model_path}")

    @classmethod
    def load(cls, model_path: str) -> "DrishtiAnomalyEngine":
        """
        Loads a persisted engine artifact from disk.
        """
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model artifact not found at {model_path}")

        payload = joblib.load(model_path)
        engine = cls(
            contamination=payload.get("contamination", 0.15),
            random_state=payload.get("random_state", 42),
            n_estimators=payload.get("n_estimators", 100)
        )
        engine.model = payload.get("model")
        engine.is_fitted = payload.get("is_fitted", False)
        engine.algorithm_name = payload.get("algorithm_name", "ISOLATION_FOREST_V1")
        engine.feature_means = payload.get("feature_means")
        engine.feature_stds = payload.get("feature_stds")
        engine.min_decision_val = payload.get("min_decision_val", -0.5)
        engine.max_decision_val = payload.get("max_decision_val", 0.5)
        return engine
