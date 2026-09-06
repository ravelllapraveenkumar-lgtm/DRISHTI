"""
Automated Unit Tests: Synthetic Data & Feature Engineering
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026
"""

import pytest
import numpy as np
import pandas as pd
from ai.synthetic_data import (
    generate_synthetic_telemetry,
    generate_institution_profiles,
    generate_benchmark_dataset
)
from ai.feature_engineering import (
    safe_divide,
    clean_telemetry_dataframe,
    compute_daily_features,
    aggregate_institution_features,
    extract_feature_matrix,
    FEATURE_COLUMNS,
    DEFAULT_FEATURE_VALUES
)

def test_synthetic_data_generation_deterministic():
    """Verifies that synthetic data generation is deterministic with fixed seeds."""
    df1 = generate_synthetic_telemetry(n_institutions=10, days_per_institution=5, seed=42)
    df2 = generate_synthetic_telemetry(n_institutions=10, days_per_institution=5, seed=42)

    assert len(df1) == 50
    assert len(df2) == 50
    pd.testing.assert_frame_equal(df1, df2)

    required_cols = [
        "institution_id", "institution_name", "scheme_code", "date",
        "registered_capacity", "expected_beneficiaries", "attendance_count",
        "biometric_punch_count", "cctv_uptime_percentage", "occupancy",
        "meals_served", "expected_meals", "roster_discrepancy",
        "geofence_offset_meters", "inspection_delay"
    ]
    for col in required_cols:
        assert col in df1.columns, f"Missing required telemetry column: {col}"

def test_synthetic_benchmark_dataset():
    """Verifies benchmark dataset generator splits into distinct train/test institutions."""
    train_df, test_df = generate_benchmark_dataset(seed=42)
    assert len(train_df) == 1800  # 60 * 30
    assert len(test_df) == 600    # 20 * 30
    train_insts = set(train_df["institution_id"].unique())
    test_insts = set(test_df["institution_id"].unique())
    # Both sets should have valid institutions
    assert len(train_insts) == 60
    assert len(test_insts) == 20

def test_safe_divide_edge_cases():
    """Tests zero denominators, NaNs, infinities, and invalid inputs."""
    assert safe_divide(10, 2) == 5.0
    assert safe_divide(10, 0) == 0.0
    assert safe_divide(10, 0, default=1.0) == 1.0
    assert safe_divide(np.nan, 5) == 0.0
    assert safe_divide(5, np.nan) == 0.0
    assert safe_divide("not_a_num", 5) == 0.0
    assert safe_divide(5, "not_a_num") == 0.0

def test_compute_daily_features_bounding():
    """Tests that computed features are properly clamped to domain boundaries."""
    # Test extreme over-capacity and over-meals
    extreme_row = pd.Series({
        "expected_beneficiaries": 50,
        "attendance_count": 150,       # 3x expected
        "registered_capacity": 50,
        "biometric_punch_count": 200,  # exceeds attendance
        "meals_served": 500,           # 5x expected
        "expected_meals": 100,
        "cctv_uptime_percentage": 150.0, # exceeds 100%
        "geofence_offset_meters": 10000.0, # 10km
        "inspection_delay": 500
    })
    feat = compute_daily_features(extreme_row)
    assert 0.0 <= feat["attendance_rate"] <= 1.5
    assert 0.0 <= feat["biometric_rate"] <= 1.0
    assert 0.0 <= feat["meal_service_rate"] <= 3.0
    assert 0.0 <= feat["cctv_uptime_norm"] <= 1.0
    assert 0.0 <= feat["geofence_offset_km"] <= 5.0
    assert 0.0 <= feat["inspection_delay_norm"] <= 1.0
    assert 0.0 <= feat["monitoring_deviation"] <= 1.0

def test_clean_telemetry_deduplication():
    """Verifies that duplicates based on institution_id and date are eliminated."""
    raw = pd.DataFrame([
        {"institution_id": "INST-1", "date": "2026-08-01", "attendance_count": 40},
        {"institution_id": "INST-1", "date": "2026-08-01", "attendance_count": 45},  # duplicate
        {"institution_id": "INST-1", "date": "2026-08-02", "attendance_count": 42}
    ])
    cleaned = clean_telemetry_dataframe(raw)
    assert len(cleaned) == 2
    assert cleaned.iloc[0]["attendance_count"] == 45  # keep="last"

def test_aggregate_institution_features():
    """Verifies window aggregation across multiple daily observations."""
    raw_df = generate_synthetic_telemetry(n_institutions=5, days_per_institution=10, seed=42)
    agg_df = aggregate_institution_features(raw_df)

    assert len(agg_df) == 5
    assert "attendance_variance" in agg_df.columns
    for col in FEATURE_COLUMNS:
        assert col in agg_df.columns

    # Check that variance is a non-negative float
    assert (agg_df["attendance_variance"] >= 0.0).all()

def test_extract_feature_matrix_nan_imputation():
    """Verifies that missing columns or NaN values are safely imputed with defaults."""
    incomplete_df = pd.DataFrame([
        {"attendance_rate": np.nan, "biometric_rate": 0.85},
        {"attendance_rate": 0.90}
    ])
    X = extract_feature_matrix(incomplete_df, FEATURE_COLUMNS)
    assert X.shape == (2, len(FEATURE_COLUMNS))
    # Check that no NaNs remain in feature matrix
    assert not np.isnan(X).any()
    # Row 0 attendance_rate should have been imputed with default 0.85
    assert X[0, 0] == DEFAULT_FEATURE_VALUES["attendance_rate"]
