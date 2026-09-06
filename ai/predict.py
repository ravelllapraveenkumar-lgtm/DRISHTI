"""
DRISHTI AI Engine: Inference & Prediction Pipeline
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026

Loads trained Isolation Forest model artifacts (or defaults to deterministic fallback),
runs feature engineering on incoming telemetry, evaluates anomaly indicators,
computes bounded Attention Scores (0-100), and outputs explainable assessments
compatible with the FastAPI backend database schemas.
"""

from typing import Dict, Any, List, Optional, Union
import os
import sys
import json
import argparse
from datetime import datetime
import numpy as np
import pandas as pd

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ai.anomaly_engine import DrishtiAnomalyEngine
from ai.feature_engineering import (
    aggregate_institution_features,
    extract_feature_matrix,
    compute_daily_features,
    FEATURE_COLUMNS
)
from ai.risk_scoring import compute_attention_score, RiskScoreResult
from ai.explainability import generate_explainable_assessment, generate_ai_alert

DEFAULT_MODEL_PATH = os.path.join(os.path.dirname(__file__), "artifacts", "isolation_forest.joblib")

class DrishtiPredictor:
    """
    Production-structured predictor for the DRISHTI platform.
    Gracefully handles missing model artifacts by utilizing deterministic statistical scoring.
    """
    def __init__(self, model_path: str = DEFAULT_MODEL_PATH):
        self.model_path = model_path
        self.engine: Optional[DrishtiAnomalyEngine] = None
        self._load_or_init_engine()

    def _load_or_init_engine(self) -> None:
        if os.path.exists(self.model_path):
            try:
                self.engine = DrishtiAnomalyEngine.load(self.model_path)
                return
            except Exception as e:
                print(f"[Warning] Failed to load model artifact at {self.model_path}: {e}")

        # Fallback initialization
        self.engine = DrishtiAnomalyEngine(contamination=0.15, random_state=42)
        # Initialize baseline with canonical empirical values
        dummy_baseline = np.tile(
            np.array([0.85, 0.90, 1.00, 0.95, 0.85, 0.02, 0.002, 0.020, 0.10, 0.05]),
            (20, 1)
        )
        self.engine.fit(dummy_baseline)

    def predict_institution_telemetry(
        self,
        telemetry_records: Union[pd.DataFrame, List[Dict[str, Any]], Dict[str, Any]],
        institution_id: Optional[str] = None,
        institution_name: Optional[str] = None,
        previous_inspection_score: Optional[float] = None
    ) -> Dict[str, Any]:
        """
        Processes multi-day telemetry logs or a single-day snapshot for an institution.
        Returns comprehensive analysis results matching the AIAnalysis & AIAlert backend schema.
        """
        # Convert input to DataFrame
        if isinstance(telemetry_records, dict):
            df = pd.DataFrame([telemetry_records])
        elif isinstance(telemetry_records, list):
            df = pd.DataFrame(telemetry_records)
        elif isinstance(telemetry_records, pd.DataFrame):
            df = telemetry_records.copy()
        else:
            raise ValueError("telemetry_records must be a DataFrame, dict, or list of dicts.")

        if df.empty:
            raise ValueError("Provided telemetry records are empty.")

        # Resolve institution metadata
        inst_id = institution_id or df.get("institution_id", pd.Series(["INST-UNKNOWN"])).iloc[0]
        inst_name = institution_name or df.get("institution_name", pd.Series(["MoSJE Facility"])).iloc[0]

        # 1. Feature Engineering
        if len(df) > 1 and "attendance_rate" not in df.columns:
            agg_df = aggregate_institution_features(df)
            feature_row = agg_df.iloc[0].to_dict()
        elif "attendance_rate" in df.columns:
            feature_row = df.iloc[0].to_dict()
        else:
            # Single-day record: compute features directly
            single_features = compute_daily_features(df.iloc[0])
            feature_row = single_features

        # Extract numerical feature vector for model
        feature_df = pd.DataFrame([feature_row])
        X = extract_feature_matrix(feature_df, FEATURE_COLUMNS)

        # 2. Anomaly Engine Prediction
        is_anom_arr, score_arr = self.engine.predict(X)
        potential_anomaly_flag = bool(is_anom_arr[0])
        model_anomaly_score = float(score_arr[0])

        # 3. Composite Attention / Risk Score (0 to 100)
        risk_result: RiskScoreResult = compute_attention_score(
            features=feature_row,
            anomaly_score=model_anomaly_score,
            previous_inspection_score=previous_inspection_score
        )

        # 4. Explainability and Recommendations
        explanation = generate_explainable_assessment(
            features=feature_row,
            risk_result=risk_result,
            institution_name=inst_name
        )

        # 5. Potential Alert Generation (for High / Critical scores)
        ai_alert = generate_ai_alert(
            institution_id=str(inst_id),
            institution_name=str(inst_name),
            risk_result=risk_result,
            explanation=explanation
        )

        # Formulate backend-compatible response structure
        primary_reason = explanation["reasons"][0] if explanation["reasons"] else "Operational metrics align with expectations."
        primary_recommendation = explanation["recommendations"][0] if explanation["recommendations"] else "Continue standard monitoring."

        output = {
            "institution_id": str(inst_id),
            "institution_name": str(inst_name),
            "analysis_timestamp": datetime.utcnow().isoformat() + "Z",
            "algorithm_used": self.engine.algorithm_name,
            "dataset_window_days": len(df),
            "risk_attention_score": risk_result.attention_score,
            "exact_score": risk_result.exact_score,
            "risk_level": risk_result.risk_level,
            "severity_level": risk_result.severity_level,
            "statistical_divergence_score": round(model_anomaly_score, 4),
            "potential_anomaly_flag": risk_result.risk_level in ("High", "Critical") or potential_anomaly_flag,
            "explainable_reason": primary_reason,
            "recommended_action": primary_recommendation,
            "all_reasons": explanation["reasons"],
            "all_recommendations": explanation["recommendations"],
            "requires_human_review": risk_result.requires_human_review,
            "sub_scores": risk_result.sub_scores,
            "features_analyzed": {col: round(float(feature_row.get(col, 0.0)), 4) for col in FEATURE_COLUMNS},
            "ai_alert": ai_alert
        }
        return output

_default_predictor = None

def get_default_predictor() -> DrishtiPredictor:
    """Singleton getter for default predictor instance."""
    global _default_predictor
    if _default_predictor is None:
        _default_predictor = DrishtiPredictor()
    return _default_predictor

def predict_institution_risk(
    telemetry_records: Union[pd.DataFrame, List[Dict[str, Any]], Dict[str, Any]],
    institution_id: Optional[str] = None,
    institution_name: Optional[str] = None,
    previous_inspection_score: Optional[float] = None
) -> Dict[str, Any]:
    """Convenience functional API for single institution prediction."""
    predictor = get_default_predictor()
    return predictor.predict_institution_telemetry(
        telemetry_records=telemetry_records,
        institution_id=institution_id,
        institution_name=institution_name,
        previous_inspection_score=previous_inspection_score
    )

def main():
    parser = argparse.ArgumentParser(description="DRISHTI AI Inference CLI")
    parser.add_argument("--sample", action="store_true", help="Run inference on synthetic benchmark samples")
    args = parser.parse_args()

    predictor = get_default_predictor()

    print("=" * 75)
    print("  DRISHTI AI ENGINE — PREDICTION & EXPLAINABILITY EVALUATION")
    print("=" * 75)

    # Sample 1: Normal compliant institution
    normal_sample = {
        "institution_id": "INST-DEMO-001",
        "institution_name": "Saraswati Disabled Rehab Centre (DDRS)",
        "expected_beneficiaries": 50,
        "registered_capacity": 60,
        "attendance_count": 46,
        "biometric_punch_count": 44,
        "cctv_uptime_percentage": 98.0,
        "occupancy": 46,
        "meals_served": 92,
        "expected_meals": 92,
        "roster_discrepancy": 1,
        "geofence_offset_meters": 12.0,
        "inspection_delay": 0
    }
    res_normal = predictor.predict_institution_telemetry(normal_sample)
    print("\n--- SAMPLE 1: NORMAL COMPLIANT FACILITY ---")
    print(f"Attention Score:      {res_normal['risk_attention_score']}/100 ({res_normal['risk_level']})")
    print(f"Potential Anomaly:    {res_normal['potential_anomaly_flag']}")
    print(f"Human Review Needed:  {res_normal['requires_human_review']}")
    print(f"Explainable Reason:   {res_normal['explainable_reason']}")
    print(f"Recommended Action:   {res_normal['recommended_action']}")
    print(f"Alert Generated:      {res_normal['ai_alert'] is not None}")

    # Sample 2: Multi-factor divergence institution
    divergent_sample = {
        "institution_id": "INST-DEMO-999",
        "institution_name": "Shanti Senior Citizens Care (AVYAY)",
        "expected_beneficiaries": 60,
        "registered_capacity": 60,
        "attendance_count": 22,
        "biometric_punch_count": 7,
        "cctv_uptime_percentage": 35.0,
        "occupancy": 22,
        "meals_served": 130,  # Massive meal inflation
        "expected_meals": 44,
        "roster_discrepancy": 18,
        "geofence_offset_meters": 450.0,
        "inspection_delay": 90
    }
    res_div = predictor.predict_institution_telemetry(divergent_sample)
    print("\n--- SAMPLE 2: HIGH-DIVERGENCE FACILITY ---")
    print(f"Attention Score:      {res_div['risk_attention_score']}/100 ({res_div['risk_level']})")
    print(f"Potential Anomaly:    {res_div['potential_anomaly_flag']}")
    print(f"Human Review Needed:  {res_div['requires_human_review']}")
    print(f"Explainable Reason:   {res_div['explainable_reason']}")
    print(f"Recommended Action:   {res_div['recommended_action']}")
    print(f"Alert Generated:      {res_div['ai_alert'] is not None}")
    if res_div["ai_alert"]:
        print(f"Alert Title:          {res_div['ai_alert']['title']}")
        print(f"Alert Scope:          {res_div['ai_alert']['suggested_inspection_scope']}")
    print("=" * 75)

if __name__ == "__main__":
    main()
