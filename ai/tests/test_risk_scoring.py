"""
Automated Unit Tests: Attention / Risk Scoring Engine
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026
"""

import pytest
from ai.risk_scoring import compute_attention_score, map_score_to_risk_level, RiskScoreResult

def test_map_score_to_risk_level():
    """Verifies strict 4-tier risk categorization."""
    assert map_score_to_risk_level(0.0) == "Low"
    assert map_score_to_risk_level(12.5) == "Low"
    assert map_score_to_risk_level(24.9) == "Low"

    assert map_score_to_risk_level(25.0) == "Medium"
    assert map_score_to_risk_level(37.0) == "Medium"
    assert map_score_to_risk_level(49.9) == "Medium"

    assert map_score_to_risk_level(50.0) == "High"
    assert map_score_to_risk_level(62.5) == "High"
    assert map_score_to_risk_level(74.9) == "High"

    assert map_score_to_risk_level(75.0) == "Critical"
    assert map_score_to_risk_level(85.0) == "Critical"
    assert map_score_to_risk_level(100.0) == "Critical"

    # Extreme bounds clamping
    assert map_score_to_risk_level(-10.0) == "Low"
    assert map_score_to_risk_level(150.0) == "Critical"

def test_compute_attention_score_bounds():
    """Verifies Attention Score is strictly bounded to [0, 100]."""
    # Ideal compliant institution
    ideal_features = {
        "attendance_rate": 0.95,
        "biometric_rate": 0.98,
        "attendance_variance": 0.003,
        "meal_service_rate": 1.00,
        "cctv_uptime_norm": 1.00,
        "geofence_offset_km": 0.005,
        "roster_discrepancy_rate": 0.0,
        "inspection_delay_norm": 0.0
    }
    res_ideal = compute_attention_score(ideal_features, anomaly_score=0.0)
    assert 0 <= res_ideal.attention_score <= 24
    assert res_ideal.risk_level == "Low"
    assert res_ideal.severity_level == "LOW"
    assert res_ideal.requires_human_review is False

    # Maximum divergence scenario
    worst_features = {
        "attendance_rate": 0.10,
        "biometric_rate": 0.05,
        "attendance_variance": 0.0,
        "meal_service_rate": 2.80,
        "cctv_uptime_norm": 0.10,
        "geofence_offset_km": 4.5,
        "roster_discrepancy_rate": 0.60,
        "inspection_delay_norm": 1.0
    }
    res_worst = compute_attention_score(worst_features, anomaly_score=1.0, previous_inspection_score=20.0)
    assert 75 <= res_worst.attention_score <= 100
    assert res_worst.risk_level == "Critical"
    assert res_worst.severity_level == "CRITICAL"
    assert res_worst.requires_human_review is True

def test_sub_score_transparency():
    """Verifies that all sub-score components are populated and sum coherently."""
    features = {
        "attendance_rate": 0.55,
        "biometric_rate": 0.60,
        "meal_service_rate": 1.40,
        "cctv_uptime_norm": 0.60,
        "geofence_offset_km": 0.150,
        "roster_discrepancy_rate": 0.10
    }
    res = compute_attention_score(features, anomaly_score=0.6)

    sub = res.sub_scores
    expected_keys = [
        "model_anomaly_component",
        "attendance_biometric_component",
        "meal_nutrition_component",
        "cctv_geofence_component",
        "inspection_roster_component",
        "baseline_offset"
    ]
    for k in expected_keys:
        assert k in sub
        assert sub[k] >= 0.0

    # Verification of human review flag alignment
    if res.risk_level in ("High", "Critical"):
        assert res.requires_human_review is True
    else:
        assert res.requires_human_review is False

def test_attendance_flatline_signature():
    """Verifies that artificial 100% flatlined attendance triggers variance penalty."""
    features_normal_var = {
        "attendance_rate": 0.98,
        "biometric_rate": 0.95,
        "attendance_variance": 0.005  # healthy variation
    }
    res_normal = compute_attention_score(features_normal_var, anomaly_score=0.1)

    features_flatline = {
        "attendance_rate": 0.98,
        "biometric_rate": 0.95,
        "attendance_variance": 0.00001  # zero-variance flatline
    }
    res_flat = compute_attention_score(features_flatline, anomaly_score=0.1)

    # Flatlined reporting should receive a higher risk score
    assert res_flat.attention_score > res_normal.attention_score
