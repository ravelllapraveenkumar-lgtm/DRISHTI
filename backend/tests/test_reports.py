import uuid

def test_submit_and_review_report_lifecycle(client, inspector_headers, super_admin_headers):
    # Fetch inspections to find one without report
    insp_list = client.get("/api/v1/inspections").json()
    insp_id = insp_list["items"][0]["id"]

    # 1. Submit report
    report_payload = {
        "inspection_id": insp_id,
        "physical_beneficiary_count": 52,
        "roster_discrepancy_count": 3,
        "cleanliness_score": 8,
        "food_nutrition_score": 9,
        "infrastructure_condition_score": 8,
        "inspector_summary": "Comprehensive headcount conducted on premises. Identified 3 beneficiaries missing without registered leave records.",
        "overall_verdict": "MINOR_NON_COMPLIANCE"
    }
    submit_resp = client.post("/api/v1/inspection-reports", json=report_payload, headers=inspector_headers)
    assert submit_resp.status_code == 201
    report = submit_resp.json()
    assert report["overall_verdict"] == "MINOR_NON_COMPLIANCE"
    assert report["official_review_status"] == "PENDING_OFFICIAL_REVIEW"

    report_id = report["id"]

    # 2. Review report by official
    review_payload = {
        "official_review_status": "REVIEWED_ACCEPTED",
        "official_decision_notes": "Explanation verified against medical leave slips. Report accepted with advisory notice issued.",
        "action_taken_type": "ADVISORY_NOTICE_ISSUED"
    }
    review_resp = client.post(f"/api/v1/inspection-reports/{report_id}/review", json=review_payload, headers=super_admin_headers)
    assert review_resp.status_code == 200
    reviewed = review_resp.json()
    assert reviewed["official_review_status"] == "REVIEWED_ACCEPTED"
    assert reviewed["action_taken_type"] == "ADVISORY_NOTICE_ISSUED"
