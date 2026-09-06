"""
DRISHTI AI Engine: Explainability & Responsible AI Alert Generator
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026

Strict Responsible AI Governance Directive:
1. The AI engine is a decision-support and triage tool ONLY.
2. Identifies potential operational anomalies; NEVER establishes fraud, corruption, or legal guilt.
3. Every finding MUST provide transparent, feature-derived reasons and actionable verification guidance.
4. Enforces human-in-the-loop verification before any administrative action.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime
import re
from ai.risk_scoring import RiskScoreResult

# Banned terminology to prevent defamatory or premature accusations
FORBIDDEN_TERMS = [
    r"\bfraud\b",
    r"\bcorrupt\w*\b",
    r"\bfake\b",
    r"\bguilty\b",
    r"\bcriminal\b",
    r"\bmisconduct\b",
    r"\bsiphon\w*\b",
    r"\bghost\b",
    r"\bscam\b"
]

def assert_responsible_language(text: str) -> None:
    """
    Validates that text output strictly adheres to Responsible AI standards,
    raising ValueError if forbidden accusatory words are detected.
    """
    for pattern in FORBIDDEN_TERMS:
        if re.search(pattern, text, re.IGNORECASE):
            raise ValueError(f"Responsible AI policy violation: Found forbidden accusatory term matching '{pattern}' in: {text}")

def sanitize_responsible_language(text: str) -> str:
    """
    Safely sanitizes text by substituting non-compliant words with responsible government terminology.
    """
    cleaned = text
    cleaned = re.sub(r"\bfake attendance\b", "unverified attendance telemetry", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bfake institution\b", "unverified facility records", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bfraud\b", "potential operational anomaly", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bcorrupt\w*\b", "procedural irregularity", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bguilty\b", "subject to verification", cleaned, flags=re.IGNORECASE)
    cleaned = re.sub(r"\bmisconduct\b", "telemetry discrepancy", cleaned, flags=re.IGNORECASE)
    return cleaned

def generate_explainable_assessment(
    features: Dict[str, float],
    risk_result: RiskScoreResult,
    institution_name: str = "Facility"
) -> Dict[str, Any]:
    """
    Produces deterministic, human-readable explanations and actionable recommendations
    derived strictly from the computed operational feature ratios.
    """
    reasons: List[str] = []
    recommendations: List[str] = []

    att_rate = float(features.get("attendance_rate", 0.85))
    bio_rate = float(features.get("biometric_rate", 0.90))
    att_var = float(features.get("attendance_variance", 0.002))
    meal_rate = float(features.get("meal_service_rate", 1.0))
    cctv_norm = float(features.get("cctv_uptime_norm", 0.95))
    geo_km = float(features.get("geofence_offset_km", 0.02))
    roster_rate = float(features.get("roster_discrepancy_rate", 0.02))
    delay_norm = float(features.get("inspection_delay_norm", 0.0))
    monitoring_dev = float(features.get("monitoring_deviation", 0.05))

    anomalies_detected = risk_result.risk_level in ("Medium", "High", "Critical") or risk_result.attention_score >= 25

    # 1. Attendance checks
    if att_rate < 0.65:
        reasons.append(
            f"Attendance rate ({att_rate * 100:.1f}%) is significantly below the expected operational baseline."
        )
        recommendations.append("Verify daily student/beneficiary physical registers against biometric logs.")
    elif att_var < 0.0001 and att_rate >= 0.95:
        reasons.append(
            "Attendance reporting exhibits invariant flatlining (constant 100% attendance across consecutive dates)."
        )
        recommendations.append("Conduct spot verification of daily biometric check-in equipment.")

    # 2. Biometric verification checks
    if bio_rate < 0.70:
        reasons.append(
            f"Biometric verification rate ({bio_rate * 100:.1f}%) shows a substantial divergence from claimed headcount."
        )
        recommendations.append("Inspect Aadhaar/biometric authentication devices for hardware connectivity issues.")

    # 3. Nutrition / meal distribution checks
    if meal_rate > 1.25:
        reasons.append(
            f"Meal distribution claims exceed expected physical headcount ratio ({meal_rate:.2f}x benchmark)."
        )
        recommendations.append("Reconcile kitchen ration registers and meal subsidy vouchers with active resident count.")
    elif meal_rate < 0.60 and att_rate > 0.60:
        reasons.append(
            f"Logged meal service ({meal_rate * 100:.1f}%) is unusually low relative to reported resident occupancy."
        )
        recommendations.append("Review catering logs and nutrition quality compliance records.")

    # 4. CCTV surveillance uptime checks
    if cctv_norm < 0.75:
        reasons.append(
            f"CCTV operational uptime ({cctv_norm * 100:.1f}%) is below the mandatory surveillance standard."
        )
        recommendations.append("Verify facility CCTV camera network connectivity, power backup, and storage logs.")

    # 5. Geofence boundary verification
    if geo_km > 0.150:
        offset_m = int(geo_km * 1000)
        reasons.append(
            f"Reported check-in coordinates diverge from the registered boundary by {offset_m} meters."
        )
        recommendations.append("Review mobile device GPS telemetry and verify approved facility geofence perimeter.")

    # 6. Roster discrepancy checks
    if roster_rate > 0.05:
        reasons.append(
            f"Beneficiary roster variance ({roster_rate * 100:.1f}%) indicates active enrollment record discrepancies."
        )
        recommendations.append("Perform full demographic reconciliation of registered beneficiary enrollments.")

    # 7. Inspection schedule checks
    if delay_norm > 0.30:
        reasons.append("Statutory periodic field inspection is overdue according to scheme monitoring guidelines.")
        recommendations.append("Prioritize field officer assignment for periodic routine physical inspection.")

    # Baseline explanation if no anomaly reasons triggered
    if not reasons:
        if risk_result.risk_level == "Low":
            reasons.append("Operational telemetry aligns with normal statistical variance across all monitored parameters.")
            recommendations.append("Continue standard automated telemetry ingestion. No immediate intervention required.")
        else:
            reasons.append("Minor composite statistical fluctuation observed across telemetry streams.")
            recommendations.append("Maintain routine periodic monitoring.")

    # High / Critical specific recommendations
    if risk_result.risk_level == "Critical":
        recommendations.insert(0, "Prioritize unannounced on-site physical verification by an authorized MoSJE field officer.")
    elif risk_result.risk_level == "High":
        recommendations.insert(0, "Supervisory review recommended. Human official verification required.")

    # Ensure all text strictly satisfies Responsible AI guidelines
    for r in reasons:
        assert_responsible_language(r)
    for rec in recommendations:
        assert_responsible_language(rec)

    return {
        "attention_score": risk_result.attention_score,
        "risk_level": risk_result.risk_level,
        "severity_level": risk_result.severity_level,
        "anomalies_detected": anomalies_detected,
        "reasons": reasons,
        "recommendations": recommendations,
        "human_review_required": risk_result.requires_human_review,
        "sub_scores": risk_result.sub_scores
    }

def generate_ai_alert(
    institution_id: str,
    institution_name: str,
    risk_result: RiskScoreResult,
    explanation: Dict[str, Any],
    ai_analysis_id: Optional[str] = None
) -> Optional[Dict[str, Any]]:
    """
    Generates a deterministic, triage-oriented AI Alert when attention scores
    fall into the High or Critical tier.
    Does NOT dispatch punitive actions; alerts officials that verification is recommended.
    """
    if risk_result.risk_level not in ("High", "Critical") and risk_result.attention_score < 50:
        return None

    top_reasons = explanation.get("reasons", [])
    primary_reason = top_reasons[0] if top_reasons else "Potential multi-variate telemetry anomaly detected."
    top_recommendations = explanation.get("recommendations", [])
    primary_action = top_recommendations[0] if top_recommendations else "Verification recommended. Human review required."

    alert_obj = {
        "institution_id": institution_id,
        "institution_name": institution_name,
        "ai_analysis_id": ai_analysis_id or "ANL-PENDING",
        "severity": risk_result.severity_level,
        "title": f"Telemetry Divergence Flagged: {institution_name}",
        "alert_summary": f"Potential anomaly detected (Attention Score: {risk_result.attention_score}/100, Level: {risk_result.risk_level}). {primary_reason}",
        "suggested_inspection_scope": primary_action,
        "attention_score": risk_result.attention_score,
        "risk_level": risk_result.risk_level,
        "status": "OPEN",
        "is_acknowledged": False,
        "human_review_required": True,
        "created_timestamp": datetime.utcnow().isoformat() + "Z"
    }

    assert_responsible_language(alert_obj["alert_summary"])
    assert_responsible_language(alert_obj["suggested_inspection_scope"])

    return alert_obj
