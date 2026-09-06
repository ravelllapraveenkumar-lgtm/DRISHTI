"""
DRISHTI AI Engine: Feature Engineering Pipeline
Domain: Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026

Transforms raw operational telemetry into robust, normalized statistical vectors
suitable for unsupervised anomaly detection (Isolation Forest) and risk scoring.
Safely handles missing values, division by zero, invalid ranges, and duplicate records.
"""

from typing import List, Dict, Any, Tuple, Optional
import numpy as np
import pandas as pd

# Core numeric feature columns utilized by the anomaly model
FEATURE_COLUMNS = [
    "attendance_rate",
    "biometric_rate",
    "meal_service_rate",
    "cctv_uptime_norm",
    "occupancy_ratio",
    "roster_discrepancy_rate",
    "attendance_variance",
    "geofence_offset_km",
    "inspection_delay_norm",
    "monitoring_deviation"
]

# Safe default values for imputing missing or invalid inputs
DEFAULT_FEATURE_VALUES = {
    "attendance_rate": 0.85,
    "biometric_rate": 0.90,
    "meal_service_rate": 1.00,
    "cctv_uptime_norm": 0.95,
    "occupancy_ratio": 0.85,
    "roster_discrepancy_rate": 0.02,
    "attendance_variance": 0.002,
    "geofence_offset_km": 0.02,
    "inspection_delay_norm": 0.10,
    "monitoring_deviation": 0.05
}

def safe_divide(numerator: Any, denominator: Any, default: float = 0.0) -> float:
    """
    Safely divides two values, returning default if denominator is zero, NaN, or non-positive.
    """
    try:
        num = float(numerator)
        denom = float(denominator)
        if np.isnan(num) or np.isnan(denom) or abs(denom) < 1e-7:
            return default
        return num / denom
    except (ValueError, TypeError, ZeroDivisionError):
        return default

def clean_telemetry_dataframe(df: pd.DataFrame) -> pd.DataFrame:
    """
    Cleans raw telemetry input:
    - Deduplicates by institution_id and date
    - Coerces numeric columns
    - Handles missing values with sensible defaults
    """
    if df is None or df.empty:
        return pd.DataFrame()

    cleaned = df.copy()

    # Deduplicate if institution_id and date are present
    if "institution_id" in cleaned.columns and "date" in cleaned.columns:
        cleaned = cleaned.drop_duplicates(subset=["institution_id", "date"], keep="last")

    # Numeric columns to ensure proper float conversion
    numeric_cols = [
        "registered_capacity", "expected_beneficiaries", "attendance_count",
        "biometric_punch_count", "cctv_uptime_percentage", "occupancy",
        "meals_served", "expected_meals", "roster_discrepancy",
        "geofence_offset_meters", "inspection_delay", "previous_inspection_score"
    ]

    for col in numeric_cols:
        if col in cleaned.columns:
            cleaned[col] = pd.to_numeric(cleaned[col], errors="coerce")

    return cleaned

def compute_daily_features(row: pd.Series) -> Dict[str, float]:
    """
    Computes single-day operational feature ratios with domain bounding and zero-denominator safety.
    """
    expected = row.get("expected_beneficiaries", 50)
    attendance = row.get("attendance_count", 0)
    capacity = row.get("registered_capacity", 50)
    biometric = row.get("biometric_punch_count", 0)
    meals = row.get("meals_served", 0)
    expected_meals = row.get("expected_meals", 0)
    if expected_meals == 0 and attendance > 0:
        expected_meals = attendance * 2

    cctv = row.get("cctv_uptime_percentage", 95.0)
    occupancy = row.get("occupancy", attendance)
    roster_disc = row.get("roster_discrepancy", 0)
    geofence_m = row.get("geofence_offset_meters", 15.0)
    delay_days = row.get("inspection_delay", 0)

    # 1. Attendance rate (0.0 to 1.5)
    att_rate = safe_divide(attendance, expected, default=0.85)
    att_rate = float(np.clip(att_rate, 0.0, 1.5))

    # 2. Biometric verification rate (0.0 to 1.0)
    bio_rate = safe_divide(biometric, attendance, default=1.0 if attendance == 0 else 0.0)
    bio_rate = float(np.clip(bio_rate, 0.0, 1.0))

    # 3. Meal service rate (ratio of meals claimed vs meals expected)
    meal_rate = safe_divide(meals, expected_meals, default=1.0)
    meal_rate = float(np.clip(meal_rate, 0.0, 3.0))

    # 4. CCTV uptime normalized (0.0 to 1.0)
    cctv_norm = safe_divide(cctv, 100.0, default=0.95)
    cctv_norm = float(np.clip(cctv_norm, 0.0, 1.0))

    # 5. Occupancy ratio vs registered capacity (0.0 to 1.5)
    occ_ratio = safe_divide(occupancy, capacity, default=0.85)
    occ_ratio = float(np.clip(occ_ratio, 0.0, 1.5))

    # 6. Roster discrepancy rate (0.0 to 1.0)
    roster_rate = safe_divide(roster_disc, capacity, default=0.0)
    roster_rate = float(np.clip(roster_rate, 0.0, 1.0))

    # 7. Geofence offset in kilometers
    geo_km = safe_divide(geofence_m, 1000.0, default=0.015)
    geo_km = float(np.clip(geo_km, 0.0, 5.0))

    # 8. Inspection delay normalized (up to 180 days)
    delay_norm = safe_divide(max(0.0, float(delay_days or 0)), 180.0, default=0.0)
    delay_norm = float(np.clip(delay_norm, 0.0, 1.0))

    # 9. Monitoring deviation (composite departure score)
    # Penalizes meal excess > 1.25, low attendance < 0.65, low biometric < 0.70, low CCTV < 0.70
    dev_score = 0.0
    if meal_rate > 1.25:
        dev_score += (meal_rate - 1.25) * 0.4
    if att_rate < 0.65:
        dev_score += (0.65 - att_rate) * 0.5
    if bio_rate < 0.70:
        dev_score += (0.70 - bio_rate) * 0.4
    if cctv_norm < 0.70:
        dev_score += (0.70 - cctv_norm) * 0.3
    if geo_km > 0.150: # >150 meters
        dev_score += min(0.3, (geo_km - 0.150))
    dev_score = float(np.clip(dev_score, 0.0, 1.0))

    return {
        "attendance_rate": att_rate,
        "biometric_rate": bio_rate,
        "meal_service_rate": meal_rate,
        "cctv_uptime_norm": cctv_norm,
        "occupancy_ratio": occ_ratio,
        "roster_discrepancy_rate": roster_rate,
        "attendance_variance": 0.002,  # Window-level feature overridden in aggregation
        "geofence_offset_km": geo_km,
        "inspection_delay_norm": delay_norm,
        "monitoring_deviation": dev_score
    }

def aggregate_institution_features(telemetry_df: pd.DataFrame) -> pd.DataFrame:
    """
    Aggregates multi-day operational telemetry for each institution into a single
    statistical feature vector containing mean rates and rolling attendance variance.
    """
    cleaned = clean_telemetry_dataframe(telemetry_df)
    if cleaned.empty:
        return pd.DataFrame(columns=["institution_id"] + FEATURE_COLUMNS)

    # Compute daily features
    daily_records = []
    for idx, row in cleaned.iterrows():
        f = compute_daily_features(row)
        f["institution_id"] = row.get("institution_id", f"UNKNOWN_{idx}")
        f["institution_name"] = row.get("institution_name", "Unknown Facility")
        f["scheme_code"] = row.get("scheme_code", "DDRS")
        daily_records.append(f)

    daily_df = pd.DataFrame(daily_records)

    # Group by institution to compute aggregate statistical profiles
    aggregated = []
    for inst_id, group in daily_df.groupby("institution_id"):
        # Attendance variance across the window (detects flatline or erratic variance)
        att_var = float(group["attendance_rate"].var()) if len(group) > 1 else 0.002
        if np.isnan(att_var):
            att_var = 0.002

        agg_record = {
            "institution_id": inst_id,
            "institution_name": group["institution_name"].iloc[0],
            "scheme_code": group["scheme_code"].iloc[0],
            "records_count": len(group),
            "attendance_rate": float(group["attendance_rate"].mean()),
            "biometric_rate": float(group["biometric_rate"].mean()),
            "meal_service_rate": float(group["meal_service_rate"].mean()),
            "cctv_uptime_norm": float(group["cctv_uptime_norm"].mean()),
            "occupancy_ratio": float(group["occupancy_ratio"].mean()),
            "roster_discrepancy_rate": float(group["roster_discrepancy_rate"].mean()),
            "attendance_variance": att_var,
            "geofence_offset_km": float(group["geofence_offset_km"].mean()),
            "inspection_delay_norm": float(group["inspection_delay_norm"].mean()),
            "monitoring_deviation": float(group["monitoring_deviation"].mean())
        }
        aggregated.append(agg_record)

    agg_df = pd.DataFrame(aggregated)
    return agg_df

def extract_feature_matrix(
    df: pd.DataFrame,
    feature_cols: Optional[List[str]] = None
) -> np.ndarray:
    """
    Extracts a 2D numpy array for model training or inference, filling any NaN with defaults.
    """
    if feature_cols is None:
        feature_cols = FEATURE_COLUMNS

    matrix_df = pd.DataFrame(index=df.index)
    for col in feature_cols:
        if col in df.columns:
            matrix_df[col] = pd.to_numeric(df[col], errors="coerce").fillna(DEFAULT_FEATURE_VALUES.get(col, 0.0))
        else:
            matrix_df[col] = DEFAULT_FEATURE_VALUES.get(col, 0.0)

    return matrix_df.values.astype(np.float64)
