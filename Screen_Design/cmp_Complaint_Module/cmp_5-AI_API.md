# Complaint Module - AI Features & API Documentation

## 1. AI-Based Analytical Data Insights

### A. Sentiment Analysis
- **Goal:** Detect urgency/tone to prioritize angry/distressed parents.
- **Mechanism:** NLP model analyzes `title` and `description`.
- **Output:** Label (Positive, Neutral, Negative, Very Negative) + Score (-1 to 1).
- **Action:** "Very Negative" scores auto-bump Priority to High.

### B. Predictive Escalation
- **Goal:** Alert Principal *before* SLA breach.
- **Mechanism:** Regression model uses inputs (Category, Time elapsed, Action count, Keyword "Agency/Lawyer").
- **Output:** `escalation_risk_score` (0-100).
- **Action:** If Score > 80, send Push Notification to Principal "High probability of escalation for Ticket #999".

### C. Auto-Categorization
- **Goal:** Reduce triage time.
- **Mechanism:** Classification model trained on historical tickets.
- **Action:** Auto-fills "Category" and "Subcategory" fields during submission, user just confirms.

---

## 2. API Documentation (REST Contracts)

### Endpoint: Submit Complaint
`POST /api/v1/complaints`
**Request:**
```json
{
  "complainant_type": "Parent",
  "complainant_user_id": 101,
  "category": "Transport",
  "is_transport_related": true,
  "route_id": 12,
  "severity_level": "High",
  "title": "Rash Driving",
  "description": "Driver crossed red light.",
  "is_anonymous": false
}
```
**Response (201 Created):**
```json
{
  "success": true,
  "data": {
    "ticket_no": "CMP-2023-555",
    "id": 555,
    "eta_resolution": "2023-10-12T14:00:00Z"
  }
}
```

### Endpoint: Status Update (Resolve/Escalate)
`PATCH /api/v1/complaints/{id}`
**Request:**
```json
{
  "action": "RESOLVE",
  "status": "Resolved",
  "resolution_summary": "Driver warned and counseling scheduled.",
  "user_id": 50 (Admin)
}
```

### Endpoint: Assign Ticket
`POST /api/v1/complaints/{id}/assign`
**Request:**
```json
{
  "assigned_to_role": 5 (Transport Manager),
  "assigned_to_user": 202,
  "notes": "Please verify GPS logs."
}
```

### Endpoint: AI Insights (Internal)
`GET /api/v1/complaints/{id}/ai-analysis`
**Response:**
```json
{
  "sentiment": "Negative",
  "sentiment_score": -0.85,
  "risk_score": 92,
  "risk_factors": ["Keywords: 'Police', 'Injury'", "SLA: < 1hr left"]
}
```
