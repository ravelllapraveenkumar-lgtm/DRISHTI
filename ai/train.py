"""
DRISHTI AI Engine: Training Pipeline
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026

Generates deterministic synthetic training telemetry, applies feature engineering,
trains the Isolation Forest anomaly detection engine, and serializes artifacts.
"""

import os
import sys
import time
import argparse
import numpy as np
import pandas as pd

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ai.synthetic_data import generate_synthetic_telemetry
from ai.feature_engineering import aggregate_institution_features, extract_feature_matrix, FEATURE_COLUMNS
from ai.anomaly_engine import DrishtiAnomalyEngine

DEFAULT_MODEL_DIR = os.path.join(os.path.dirname(__file__), "artifacts")
DEFAULT_MODEL_PATH = os.path.join(DEFAULT_MODEL_DIR, "isolation_forest.joblib")

def train_model(
    n_institutions: int = 60,
    days_per_institution: int = 30,
    contamination: float = 0.15,
    random_state: int = 42,
    output_path: str = DEFAULT_MODEL_PATH
) -> DrishtiAnomalyEngine:
    """
    Executes the complete training workflow:
    1. Generates deterministic synthetic operational dataset
    2. Runs feature engineering and aggregation
    3. Fits the Isolation Forest model
    4. Serializes the fitted engine artifact
    """
    start_time = time.time()
    print("=" * 70)
    print("  DRISHTI AI ENGINE — TRAINING PIPELINE")
    print("=" * 70)
    print(f"  Institutions:          {n_institutions}")
    print(f"  Days per Institution:  {days_per_institution}")
    print(f"  Contamination Factor:  {contamination}")
    print(f"  Random State Seed:     {random_state}")
    print(f"  Target Artifact Path:  {output_path}")

    # 1. Generate Synthetic Training Telemetry
    print("\n[Step 1/4] Generating deterministic synthetic telemetry...")
    raw_df = generate_synthetic_telemetry(
        n_institutions=n_institutions,
        days_per_institution=days_per_institution,
        seed=random_state
    )
    print(f"  Generated {len(raw_df)} daily observation records across {n_institutions} institutions.")

    # 2. Feature Engineering & Window Aggregation
    print("\n[Step 2/4] Applying feature engineering & institutional aggregation...")
    aggregated_df = aggregate_institution_features(raw_df)
    print(f"  Aggregated into {len(aggregated_df)} institutional statistical vectors.")
    print(f"  Feature columns ({len(FEATURE_COLUMNS)}): {', '.join(FEATURE_COLUMNS)}")

    X_train = extract_feature_matrix(aggregated_df, FEATURE_COLUMNS)
    print(f"  Extracted feature matrix shape: {X_train.shape}")

    # 3. Model Fitting
    print("\n[Step 3/4] Fitting Isolation Forest model...")
    engine = DrishtiAnomalyEngine(
        contamination=contamination,
        random_state=random_state,
        n_estimators=100
    )
    engine.fit(X_train)

    # In-sample evaluation
    is_anomaly, scores = engine.predict(X_train)
    n_anomalies = int(np.sum(is_anomaly))
    anomaly_pct = (n_anomalies / len(X_train)) * 100.0
    print(f"  Model Fitted:           {engine.algorithm_name}")
    print(f"  In-sample Inliers:      {len(X_train) - n_anomalies} ({(100 - anomaly_pct):.1f}%)")
    print(f"  In-sample Flagged:      {n_anomalies} ({anomaly_pct:.1f}%)")
    print(f"  Score Range:            Min {np.min(scores):.4f} | Mean {np.mean(scores):.4f} | Max {np.max(scores):.4f}")

    # 4. Artifact Serialization
    print("\n[Step 4/4] Persisting model artifact...")
    engine.save(output_path)
    print(f"  Model successfully saved to: {output_path}")

    duration = time.time() - start_time
    print(f"\n Training completed in {duration:.2f} seconds.")
    print("=" * 70)
    return engine

def main():
    parser = argparse.ArgumentParser(description="Train DRISHTI Isolation Forest Anomaly Engine")
    parser.add_argument("--institutions", type=int, default=60, help="Number of synthetic institutions")
    parser.add_argument("--days", type=int, default=30, help="Days of telemetry per institution")
    parser.add_argument("--contamination", type=float, default=0.15, help="Anomaly contamination fraction")
    parser.add_argument("--seed", type=int, default=42, help="Deterministic random seed")
    parser.add_argument("--output", type=str, default=DEFAULT_MODEL_PATH, help="Path for model artifact")

    args = parser.parse_args()
    train_model(
        n_institutions=args.institutions,
        days_per_institution=args.days,
        contamination=args.contamination,
        random_state=args.seed,
        output_path=args.output
    )

if __name__ == "__main__":
    main()
