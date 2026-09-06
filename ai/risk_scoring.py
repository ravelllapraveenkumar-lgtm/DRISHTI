"""
DRISHTI AI Engine: Attention / Risk Scoring Engine
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026

Calculates a bounded, transparent, explainable Attention Score (0 to 100)
and maps it to standardized operational risk tiers:
  0 – 24   = Low
  25 – 49  = Medium
  50 – 74  = High
  75 – 100 = Critical

Signal Breakdown & Weighting (Total: 100%):
  1. ML Model Anomaly Signal (35%): Unsupervised divergence from normal telemetry baseline
  2. Attendance & Biometric Signal (25%): Low attendance or large gap between claimed vs biometric verification
  3. Nutrition / Meal Claim Signal (15%): Ratio of meals billed vs verified beneficiaries
  4. CCTV Uptime & Geofence Boundary (15%): Offline surveillance or check-ins outside authorized geofence
  5. Inspection & Roster Discrepancy (10%): History of inspection findings and roster mismatches
"""

from dataclasses import dataclass, asdict
from typing import Dict, Any, Optional
import numpy as np

@dataclass
class RiskScoreResult:
    """
    Transparent container detailing the computed Attention Score and its constituent sub-scores.
    """
    attention_score: int              # Bounded integer 0 to 100
    exact_score: float                # Exact float before rounding
    risk_level: str                   # Low, Medium, High, Critical
    severity_level: str               # LOW, MEDIUM, HIGH, CRITICAL (backend-compatible)
    sub_scores: Dict[str, float]      # Component breakdown
    requires_human_review: bool       # True for High or Critical
    recommendation_tier: str

def map_score_to_risk_level(score: float) -> str:
    """
    Maps an attention score (0-100) to standard MoSJE operational risk levels.
      0 – 24   = Low
      25 – 49  = Medium
      50 – 74  = High
      75 – 100 = Critical
    """
    bounded = max(0.0, min(100.0, float(score)))
    if bounded < 25.0:
        return "Low"
    elif bounded < 50.0:
        return "Medium"
    elif bounded < 75.0:
        return "High"
    else:
        return "Critical"

def compute_attention_score(
    features: Dict[str, float],
    anomaly_score: float = 0.0,
    previous_inspection_score: Optional[float] = None
) -> RiskScoreResult:
    """
    Calculates the composite Attention / Risk Score (0-100) from engineered features
    and the anomaly detection model's divergence score.
    """
    # 1. Component: ML Model Anomaly Signal (Weight: 35 points)
    # anomaly_score is in [0.0, 1.0]
    c_model = float(np.clip(anomaly_score * 35.0, 0.0, 35.0))

    # 2. Component: Attendance & Biometric Variance (Weight: 25 points)
    att_rate = float(features.get("attendance_rate", 0.85))
    bio_rate = float(features.get("biometric_rate", 0.90))
    att_var = float(features.get("attendance_variance", 0.002))

    c_att = 0.0
    # Penalty for low attendance (< 70%)
    if att_rate < 0.70:
        c_att += (0.70 - att_rate) * 20.0  # Up to 14 pts
    # Penalty for biometric discrepancy (gap between attendance and biometric verification)
    bio_gap = max(0.0, 1.0 - bio_rate)
    c_att += bio_gap * 12.0  # Up to 12 pts
    # Penalty for artificial flatline (att_var < 0.0001 with near 100% attendance)
    if att_var < 0.0001 and att_rate >= 0.95:
        c_att += 8.0  # Flatline reporting signature
    c_att = float(np.clip(c_att, 0.0, 25.0))

    # 3. Component: Meal / Nutrition Service Discrepancy (Weight: 15 points)
    meal_rate = float(features.get("meal_service_rate", 1.0))
    c_meal = 0.0
    # Expected meal_rate is ~1.0. If > 1.20, penalize claimed over-delivery
    if meal_rate > 1.20:
        c_meal += min(15.0, (meal_rate - 1.20) * 20.0)
    elif meal_rate < 0.60:
        c_meal += (0.60 - meal_rate) * 15.0
    c_meal = float(np.clip(c_meal, 0.0, 15.0))

    # 4. Component: CCTV Uptime & Geofence Boundary (Weight: 15 points)
    cctv_norm = float(features.get("cctv_uptime_norm", 0.95))
    geo_km = float(features.get("geofence_offset_km", 0.02))
    c_env = 0.0
    # CCTV downtime penalty (< 80% uptime)
    if cctv_norm < 0.80:
        c_env += (0.80 - cctv_norm) * 15.0  # Up to 12 pts
    # Geofence boundary penalty (> 100 meters)
    if geo_km > 0.100:
        c_env += min(8.0, (geo_km - 0.100) * 10.0)
    c_env = float(np.clip(c_env, 0.0, 15.0))

    # 5. Component: Inspection History & Roster Discrepancy (Weight: 10 points)
    roster_rate = float(features.get("roster_discrepancy_rate", 0.02))
    delay_norm = float(features.get("inspection_delay_norm", 0.0))
    c_hist = 0.0
    c_hist += min(6.0, roster_rate * 30.0)
    c_hist += min(4.0, delay_norm * 4.0)

    # If previous inspection score is provided and low (< 60/100), add proportional weight
    if previous_inspection_score is not None:
        if previous_inspection_score < 60.0:
            c_hist += (60.0 - previous_inspection_score) * 0.05
    c_hist = float(np.clip(c_hist, 0.0, 10.0))

    # Base operational noise offset (3 points)
    base_offset = 3.0

    raw_total = base_offset + c_model + c_att + c_meal + c_env + c_hist
    bounded_score = float(np.clip(raw_total, 0.0, 100.0))
    rounded_score = int(round(bounded_score))

    risk_level = map_score_to_risk_level(bounded_score)
    severity_level = risk_level.upper()
    requires_human_review = risk_level in ("High", "Critical")

    if risk_level == "Critical":
        recommendation_tier = "PRIORITIZED_VERIFICATION_REQUIRED"
    elif risk_level == "High":
        recommendation_tier = "SUPERVISORY_REVIEW_RECOMMENDED"
    elif risk_level == "Medium":
        recommendation_tier = "ROUTINE_PERIODIC_CHECK"
    else:
        recommendation_tier = "STANDARD_MONITORING"

    sub_scores = {
        "model_anomaly_component": round(c_model, 2),
        "attendance_biometric_component": round(c_att, 2),
        "meal_nutrition_component": round(c_meal, 2),
        "cctv_geofence_component": round(c_env, 2),
        "inspection_roster_component": round(c_hist, 2),
        "baseline_offset": base_offset
    }

    return RiskScoreResult(
        attention_score=rounded_score,
        exact_score=round(bounded_score, 2),
        risk_level=risk_level,
        severity_level=severity_level,
        sub_scores=sub_scores,
        requires_human_review=requires_human_review,
        recommendation_tier=recommendation_tier
    )
