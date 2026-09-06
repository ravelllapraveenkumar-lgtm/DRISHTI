# DRISHTI AI Engine (Phase 3)

**Digital Real-Time Inspection & Scheme Holistic Tracking Infrastructure**
*Ministry of Social Justice and Empowerment (MoSJE) — SIH 2026 (Problem Statement ID: 26095)*

---

## 1. Executive Summary & Objective

The DRISHTI AI Engine provides an **unsupervised anomaly detection and attention-scoring system** designed to assist ministry administrators and district officers in identifying operational patterns that may warrant supervisory review or on-site physical inspection.

The engine analyzes daily telemetry across MoSJE flagship schemes:
- **DDRS** (*Deendayal Disabled Rehabilitation Scheme*)
- **AVYAY** (*Atal Vayo Abhyuday Yojana*)
- **NAPDDR** (*National Action Plan for Drug Demand Reduction*)
- **PM-DAKSH** (*Pradhan Mantri Dakshta Aur Kushalta Sampann Hitgrahi*)

---

## 2. Responsible AI Framework & Ethical Governance

> ⚠️ **CRITICAL DIRECTIVE: DECISION-SUPPORT & TRIAGE ONLY**  
> The DRISHTI AI Engine is an automated decision-support utility. It **DOES NOT** establish fraud, corruption, financial misconduct, or individual guilt.

### Core Principles:
1. **Decision-Support Only**: The AI engine flags statistical anomalies to prioritize inspection resources; it never replaces human judgement.
2. **Identification of Potential Anomalies**: The model detects multi-variate statistical divergence relative to empirical baselines.
3. **No Automatic Accusations**: Output strictly avoids accusatory language (`fraud`, `corruption`, `fake`, `guilty`, `criminal`, `misconduct`).
4. **Mandatory Standardized Terminology**:
   - *"Potential anomaly detected."*
   - *"Verification recommended."*
   - *"Human review required."*
5. **Human-in-the-Loop Verification**: High or Critical attention scores produce recommendation flags requiring supervisory review by MoSJE officials before any administrative or inspection steps are initiated.
6. **Synthetic & Demonstration Data**: All prototype models are developed and benchmarked on deterministic synthetic telemetry. No real citizen or personal identifiable information (PII) is processed.
7. **Real-World Deployment Safeguards**: Production deployment requires continuous drift monitoring, algorithmic bias testing across rural vs. urban institutions, privacy-preserving aggregation, and formal audit logging.

---

## 3. System Architecture

```
ai/
├── README.md               # Architecture documentation & Responsible AI charter
├── requirements.txt        # ML dependencies (scikit-learn, pandas, numpy, joblib)
├── synthetic_data.py       # Deterministic synthetic data generator (MoSJE schemes)
├── feature_engineering.py  # Zero-division safe feature transformation & aggregation
├── anomaly_engine.py       # Scikit-learn Isolation Forest with statistical fallback
├── risk_scoring.py         # Bounded Attention Score (0-100) & 4-tier risk mapping
├── explainability.py       # Deterministic human-readable reasons & AI alert generator
├── train.py                # Standalone model training & artifact serialization
├── predict.py              # End-to-end inference engine with FastAPI backend compatibility
├── artifacts/              # Serialized model artifacts (.joblib)
└── tests/                  # Automated Pytest suite (21 passing tests)
    ├── test_features.py
    ├── test_anomaly_engine.py
    ├── test_risk_scoring.py
    └── test_explainability.py
```

---

## 4. Feature Engineering Pipeline

Raw operational telemetry is converted into 10 normalized statistical vectors with mathematical protection against zero denominators, missing values, and domain boundaries:

| Feature Name | Computation / Formula | Normal Range | Detection Purpose |
|---|---|---|---|
| `attendance_rate` | $\frac{\text{attendance\_count}}{\max(\text{expected\_beneficiaries}, 1)}$ | $0.70 - 0.98$ | Severe under-occupancy or absenteeism |
| `biometric_rate` | $\frac{\text{biometric\_punches}}{\max(\text{attendance\_count}, 1)}$ | $0.85 - 1.00$ | Manual roll-call discrepancy vs. biometric audit |
| `meal_service_rate` | $\frac{\text{meals\_served}}{\max(\text{expected\_meals}, 1)}$ | $0.90 - 1.15$ | Ration/meal subsidy claim inflation |
| `cctv_uptime_norm` | $\frac{\text{cctv\_uptime\_percentage}}{100.0}$ | $0.85 - 1.00$ | Surveillance camera power or feed drops |
| `occupancy_ratio` | $\frac{\text{occupancy}}{\max(\text{registered\_capacity}, 1)}$ | $0.65 - 0.95$ | Overcrowding or vacant facility claims |
| `roster_discrepancy_rate`| $\frac{\text{roster\_discrepancy}}{\max(\text{registered\_capacity}, 1)}$ | $0.00 - 0.05$ | Enrollment and documentation discrepancies |
| `attendance_variance` | $\sigma^2(\text{attendance\_rate}_{7d})$ | $0.001 - 0.010$ | Artificial 100% invariant flatline reporting |
| `geofence_offset_km` | $\frac{\text{offset\_meters}}{1000.0}$ | $0.00 - 0.05$ | Check-in coordinates outside physical facility bounds |
| `inspection_delay_norm`| $\frac{\max(\text{delay\_days}, 0)}{180.0}$ | $0.00 - 0.20$ | Overdue periodic compliance inspections |
| `monitoring_deviation` | $\sum \text{penalties}(\Delta_{\text{peer\_norms}})$ | $0.00 - 0.15$ | Composite statistical divergence from peer cohort |

---

## 5. Anomaly Detection Engine

- **Primary Algorithm**: `sklearn.ensemble.IsolationForest`
  - Hyperparameters: `contamination=0.15`, `random_state=42`, `n_estimators=100`.
  - Continuous Anomaly Score: Inverted sigmoid of `decision_function(X)` mapped to $[0.0, 1.0]$.
- **Deterministic Statistical Fallback**:
  - Activated if scikit-learn is unavailable or unfitted.
  - Computes standardized multi-variate deviation ($Z$-score proxy) against empirical MoSJE operational distributions.
  - Strictly documented (`algorithm_used = "STATISTICAL_FALLBACK_V1"`).

---

## 6. Attention / Risk Score Scale (0–100)

The Attention Score synthesizes five weighted signals:
1. **ML Model Anomaly Signal (35%)**: Unsupervised divergence from baseline distributions.
2. **Attendance & Biometric Signal (25%)**: Low attendance or gap between attendance and biometric verification.
3. **Meal & Nutrition Signal (15%)**: Ratio of meals claimed vs. verified resident beneficiaries.
4. **CCTV & Geofence Signal (15%)**: Offline surveillance or pings distant from approved boundary.
5. **Inspection & Roster History (10%)**: Roster record variance and overdue inspection lag.

### Risk Tier Mapping:
| Score Range | Risk Level | Severity | Recommended System Action | Human Review |
|---|---|---|---|---|
| **0 – 24** | `Low` | `LOW` | Standard automated telemetry ingestion | Optional |
| **25 – 49** | `Medium` | `MEDIUM` | Routine monthly periodic monitoring | No |
| **50 – 74** | `High` | `HIGH` | Supervisory review recommended; human official verification | **Required** |
| **75 – 100** | `Critical` | `CRITICAL` | Prioritized unannounced on-site inspection recommended | **Required** |

---

## 7. Explainability & Actionable Recommendations

Every output contains:
1. `attention_score`: Continuous score between 0 and 100.
2. `risk_level`: Standardized tier (`Low`, `Medium`, `High`, `Critical`).
3. `reasons`: Explicit statements directly citing the feature that exceeded normal tolerance (e.g. *"Attendance rate (42.0%) is significantly below the expected operational baseline."*).
4. `recommendations`: Concrete operational next steps (e.g. *"Reconcile kitchen ration registers and meal subsidy vouchers with active resident count."*).
5. `human_review_required`: Boolean flag enforced for any High or Critical determination.

---

## 8. Backend Compatibility & Schemas

The AI Engine produces structured outputs directly convertible to the FastAPI backend schemas:
- `AIAnalysisCreate` (UUID, score, severity, reasons, recommendations)
- `AIAlertResponse` (alert title, summary, suggested scope, acknowledgment status)

---

## 9. Verification & Test Execution

```bash
# Run the complete test suite (26 backend + 21 AI tests = 47 passed)
pytest

# Run only AI engine tests
pytest ai/tests -v

# Train model from scratch on synthetic telemetry
python3 ai/train.py

# Run CLI inference demonstration
python3 ai/predict.py --sample
```
