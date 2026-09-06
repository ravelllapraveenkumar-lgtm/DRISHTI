"""
Automated Unit Tests: Explainability, AI Alerts & Responsible AI Safeguards
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026
"""

import pytest
from ai.risk_scoring import RiskScoreResult
from ai.explainability import (
    generate_explainable_assessment,
    generate_ai_alert,
    assert_responsible_language,
    sanitize_responsible_language,
    FORBIDDEN_TERMS
)

def test_explainability_derived_from_features():
    """Verifies that generated reasons correspond to active telemetry deficiencies."""
    features = {
        "attendance_rate": 0.40,        # < 0.65 -> triggers low attendance reason
        "biometric_rate": 0.50,         # < 0.70 -> triggers biometric divergence
        "meal_service_rate": 1.50,      # > 1.25 -> triggers meal inflation reason
        "cctv_uptime_norm": 0.50,       # < 0.75 -> triggers CCTV uptime reason
        "geofence_offset_km": 0.300,    # > 0.150 -> triggers geofence reason
        "roster_discrepancy_rate": 0.12 # > 0.05 -> triggers roster variance reason
    }
    risk_res = RiskScoreResult(
        attention_score=78,
        exact_score=78.2,
        risk_level="Critical",
        severity_level="CRITICAL",
        sub_scores={},
        requires_human_review=True,
        recommendation_tier="PRIORITIZED_VERIFICATION_REQUIRED"
    )

    assessment = generate_explainable_assessment(features, risk_res, "Varanasi Special School")
    reasons_text = " ".join(assessment["reasons"]).lower()

    assert "attendance rate" in reasons_text
    assert "biometric verification rate" in reasons_text
    assert "meal distribution claims" in reasons_text
    assert "cctv operational uptime" in reasons_text
    assert "geofence" in reasons_text or "coordinates diverge" in reasons_text
    assert "roster variance" in reasons_text

    assert assessment["human_review_required"] is True
    assert len(assessment["recommendations"]) >= 3
    # Top recommendation for Critical should advise physical verification
    assert "unannounced on-site physical verification" in assessment["recommendations"][0].lower()

def test_explainability_normal_facility():
    """Verifies that normal compliant facilities receive reassurance explanations."""
    features = {
        "attendance_rate": 0.90,
        "biometric_rate": 0.95,
        "meal_service_rate": 1.00,
        "cctv_uptime_norm": 0.98,
        "geofence_offset_km": 0.015,
        "roster_discrepancy_rate": 0.01
    }
    risk_res = RiskScoreResult(
        attention_score=10,
        exact_score=9.8,
        risk_level="Low",
        severity_level="LOW",
        sub_scores={},
        requires_human_review=False,
        recommendation_tier="STANDARD_MONITORING"
    )
    assessment = generate_explainable_assessment(features, risk_res, "Lucknow Training Centre")
    assert assessment["human_review_required"] is False
    assert "normal statistical variance" in assessment["reasons"][0].lower()

def test_ai_alert_generation_threshold():
    """Verifies that AI Alerts are generated ONLY for High or Critical scores."""
    high_risk_res = RiskScoreResult(
        attention_score=65,
        exact_score=65.0,
        risk_level="High",
        severity_level="HIGH",
        sub_scores={},
        requires_human_review=True,
        recommendation_tier="SUPERVISORY_REVIEW_RECOMMENDED"
    )
    expl_high = {
        "reasons": ["Attendance rate is significantly below the expected operational baseline."],
        "recommendations": ["Supervisory review recommended. Human official verification required."]
    }

    # Should generate alert for High
    alert_high = generate_ai_alert("INST-101", "Demo Centre 101", high_risk_res, expl_high)
    assert alert_high is not None
    assert alert_high["institution_id"] == "INST-101"
    assert alert_high["severity"] == "HIGH"
    assert alert_high["human_review_required"] is True
    assert alert_high["is_acknowledged"] is False
    assert "potential anomaly" in alert_high["alert_summary"].lower()

    # Should NOT generate alert for Low
    low_risk_res = RiskScoreResult(
        attention_score=15,
        exact_score=15.0,
        risk_level="Low",
        severity_level="LOW",
        sub_scores={},
        requires_human_review=False,
        recommendation_tier="STANDARD_MONITORING"
    )
    alert_low = generate_ai_alert("INST-102", "Demo Centre 102", low_risk_res, {"reasons": [], "recommendations": []})
    assert alert_low is None

def test_responsible_ai_strict_wording_safeguards():
    """
    CRITICAL ETHICAL SAFEGUARD TEST:
    Ensures that the AI engine strictly bans accusatory, defamatory, or premature terms:
    fraud, corruption, fake, guilty, criminal, misconduct.
    """
    # 1. Assert that generated text does NOT contain any forbidden terms
    features = {"attendance_rate": 0.20, "biometric_rate": 0.10, "meal_service_rate": 2.50}
    risk_res = RiskScoreResult(
        attention_score=95,
        exact_score=94.5,
        risk_level="Critical",
        severity_level="CRITICAL",
        sub_scores={},
        requires_human_review=True,
        recommendation_tier="PRIORITIZED_VERIFICATION_REQUIRED"
    )
    assessment = generate_explainable_assessment(features, risk_res, "Suspect Facility")

    full_output_corpus = " ".join(assessment["reasons"] + assessment["recommendations"]).lower()
    banned_words = ["fraud", "corrupt", "fake", "guilty", "criminal", "misconduct", "siphon", "ghost", "scam"]

    for word in banned_words:
        assert word not in full_output_corpus, f"Forbidden term '{word}' found in AI explanation output!"

    alert = generate_ai_alert("INST-ERR", "Suspect Facility", risk_res, assessment)
    assert alert is not None
    alert_corpus = (alert["title"] + " " + alert["alert_summary"] + " " + alert["suggested_inspection_scope"]).lower()
    for word in banned_words:
        assert word not in alert_corpus, f"Forbidden term '{word}' found in AI alert output!"

    # 2. Test that assert_responsible_language catches forbidden words
    with pytest.raises(ValueError):
        assert_responsible_language("This institution is guilty of systematic fraud and ghost attendance.")

    with pytest.raises(ValueError):
        assert_responsible_language("Corrupt management detected.")

    # 3. Test sanitizer replaces forbidden phrases with neutral government terms
    sanitized = sanitize_responsible_language("Suspected fake attendance and fraud detected.")
    assert "fake attendance" not in sanitized
    assert "fraud" not in sanitized
    assert "unverified attendance telemetry" in sanitized
