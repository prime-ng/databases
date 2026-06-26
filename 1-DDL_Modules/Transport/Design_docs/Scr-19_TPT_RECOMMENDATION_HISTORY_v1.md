# Screen Design Specification: Recommendation History
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Track outcomes of applied ML recommendations and their actual impact on transport operations. Backed by `tpt_recommendation_history`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✓  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_recommendation_history`
├── id (BIGINT PRIMARY KEY)
├── recommendation_id (FK -> `tpt_model_recommendations.id`)
├── applied_by (FK -> `hrm_employees.id`)
├── applied_date (DATETIME)
├── predicted_impact (VARCHAR)
├── actual_impact (VARCHAR, nullable)
├── outcome_status (ENUM: SUCCESS, PARTIAL, FAILED, NEUTRAL)
├── feedback_score (INT, 1-5, nullable)
├── notes (TEXT, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Recommendation History Dashboard
**Route:** `/transport/recommendation-history`

#### 2.1.1 Layout (Applied Recommendations Timeline)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > RECOMMENDATION HISTORY                               │
├──────────────────────────────────────────────────────────────────┤
│ DATE RANGE: [2025-11-01 ▼] to [2025-12-01 ▼]                   │
│ OUTCOME: [All ▼]  TYPE: [All ▼]  FEEDBACK: [All ▼]             │
│ [Print Report] [Export CSV] [Analytics]                        │
├──────────────────────────────────────────────────────────────────┤
│ Date       | Recommendation              | Predicted  | Actual  │
├──────────────────────────────────────────────────────────────────┤
│ 2025-12-01 | Route Optimization - T123   | 15 min ↓   | 14 min ↓│
│ 2025-11-30 | Driver Assignment - Route A | Efficiency | Success │
│ 2025-11-29 | Schedule Adjust - Route B   | 10 min ↓   | 5 min ↓ │
│ 2025-11-28 | Cost Optimization - Fuel    | ₹50 ↓      | ₹48 ↓   │
│ 2025-11-27 | Route Optimization - T120   | 20 min ↓   | Failed  │
│
│ [View Details] [Provide Feedback] [Compare to Baseline]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Outcome Record Details
#### 2.2.1 Full History Card
```
┌────────────────────────────────────────────────────────┐
│ RECOMMENDATION OUTCOME                              [✕]│
├────────────────────────────────────────────────────────┤
│ ORIGINAL RECOMMENDATION
│ ID: REC-2025-0142
│ Type: Route Optimization
│ Model: Route Optimizer v2.3.1
│ Entity: Trip-123
│ Created: 2025-12-01 09:30:00
│ Confidence: 92%
│
│ PREDICTED IMPACT
│ Time Saving: 15 minutes
│ Cost Saving: ₹50
│ Safety Impact: No incidents
│
│ ACTUAL OUTCOME
│ Applied By: Ravi (Admin)
│ Applied Date: 2025-12-01 10:00:00
│ Outcome Status: SUCCESS ✓
│ Time Saved (Actual): 14 minutes
│ Cost Saved (Actual): ₹48
│ Accuracy: 93%
│
│ FEEDBACK
│ User Feedback: ★★★★★ (5/5)
│ Notes: "Excellent improvement. Stop merge worked well."
│
│ COMPARISON TO BASELINE
│ Baseline (no recommendation): 29 minutes, ₹98
│ With Recommendation: 14 minutes, ₹50
│ Improvement: -52% time, -49% cost
│
│ [Edit Notes] [Rate Recommendation] [Share Feedback]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Feedback Form
#### 2.3.1 Outcome & Feedback
```
┌────────────────────────────────────────────────┐
│ PROVIDE FEEDBACK                            [✕]│
├────────────────────────────────────────────────┤
│ OUTCOME
│ Outcome Status *     [SUCCESS ▼]              │
│                      SUCCESS / PARTIAL / FAILED / NEUTRAL
│
│ ACTUAL IMPACT
│ Time Saved (min)     [14                    ]│
│ Cost Saved (₹)       [48                    ]│
│ Incidents Prevented  [0                     ]│
│
│ USER FEEDBACK
│ Rating *             [★★★★★ 5/5           ]│
│ Notes                [__________________]│
│
│ COMPARISON
│ Baseline Value       [29 min, ₹98         ]│
│ (Recommended: 15 min, ₹50 saved)
│
├────────────────────────────────────────────────┤
│         [Cancel]        [Save]                 │
└────────────────────────────────────────────────┘
```

### 2.4 Analytics Dashboard
#### 2.4.1 Impact Summary
```
RECOMMENDATION PERFORMANCE ANALYSIS
Last 30 Days (Nov 1 - Dec 1, 2025)
────────────────────────────────────────────────────
ACCEPTANCE STATISTICS
├─ Total Recommendations: 45
├─ Applied: 32 (71%)
├─ Rejected: 8 (18%)
├─ Expired: 5 (11%)

OUTCOME BREAKDOWN
├─ SUCCESS: 28 (88% of applied)
├─ PARTIAL: 3 (9% of applied)
├─ FAILED: 1 (3% of applied)

CUMULATIVE IMPACT
├─ Time Saved: 432 minutes (7.2 hours)
├─ Cost Saved: ₹5,184
├─ Safety Incidents Prevented: 2

AVERAGE ACCURACY
├─ Predicted vs Actual: 91%
├─ User Rating: 4.7/5.0
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Record Recommendation Outcome
```json
POST /api/v1/transport/recommendation-history
{
  "recommendation_id": 142,
  "applied_by": 5,
  "applied_date": "2025-12-01T10:00:00Z",
  "predicted_impact": "Save 15 min, ₹50",
  "actual_impact": "Save 14 min, ₹48",
  "outcome_status": "SUCCESS",
  "feedback_score": 5,
  "notes": "Excellent improvement. Stop merge worked well."
}

Response:
{
  "id": 1,
  "recommendation_id": 142,
  "applied_by": 5,
  "applied_date": "2025-12-01T10:00:00Z",
  "outcome_status": "SUCCESS",
  "feedback_score": 5,
  "created_at": "2025-12-01T10:30:00Z"
}
```

### 3.2 Get History Records
```json
GET /api/v1/transport/recommendation-history?from_date=2025-11-01&to_date=2025-12-01&outcome_status=SUCCESS

Response:
{
  "data": [
    {
      "id": 1,
      "recommendation_id": 142,
      "recommendation_type": "ROUTE_OPTIMIZATION",
      "applied_by_name": "Ravi (Admin)",
      "applied_date": "2025-12-01T10:00:00Z",
      "predicted_impact": "Save 15 min, ₹50",
      "actual_impact": "Save 14 min, ₹48",
      "outcome_status": "SUCCESS",
      "feedback_score": 5
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 28}
}
```

### 3.3 Update Outcome
```json
PATCH /api/v1/transport/recommendation-history/{id}
{
  "actual_impact": "Save 14 min, ₹48",
  "outcome_status": "SUCCESS",
  "feedback_score": 5,
  "notes": "Excellent improvement"
}
```

### 3.4 Get Performance Analytics
```json
GET /api/v1/transport/recommendation-history/analytics?from_date=2025-11-01&to_date=2025-12-01

Response:
{
  "total_recommendations": 45,
  "applied": 32,
  "rejected": 8,
  "expired": 5,
  "success_rate": 0.88,
  "partial_rate": 0.09,
  "failed_rate": 0.03,
  "total_time_saved_minutes": 432,
  "total_cost_saved": 5184.00,
  "incidents_prevented": 2,
  "average_accuracy": 0.91,
  "average_feedback_score": 4.7
}
```

---

## 4. USER WORKFLOWS

### 4.1 Record Recommendation Outcome
```
1. Admin applies recommendation (Route Optimization)
2. Trips execute with recommendation (stop merge)
3. After trip completion, actual metrics collected
4. Admin opens Recommendation History
5. Clicks [Provide Feedback] on applied recommendation
6. Enters actual_impact (14 min saved, ₹48 cost saved)
7. Sets outcome_status to SUCCESS
8. Rates recommendation (5/5)
9. Saves feedback
```

### 4.2 Review Performance Analytics
```
1. Manager opens Recommendation History
2. Clicks [Analytics]
3. Selects date range (last 30 days)
4. Views cumulative impact (432 min saved, ₹5,184 cost saved)
5. Analyzes success rate (88%)
6. Compares predicted vs actual accuracy (91%)
7. Exports report to share with stakeholders
```

### 4.3 Compare Baseline
```
1. Admin selects applied recommendation
2. System shows "Comparison to Baseline"
3. Baseline: Trip without recommendation (29 min, ₹98)
4. With Recommendation: 14 min, ₹50
5. Improvement: -52% time, -49% cost
6. Validates recommendation effectiveness
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code outcomes: SUCCESS (green), PARTIAL (yellow), FAILED (red), NEUTRAL (gray)
- Feedback rating shown as stars (1–5)
- Timeline visualization for recommendations over time
- Impact metrics in prominent cards

---

## 6. ACCESSIBILITY & USABILITY

- Datetime pickers for date range filters
- Numeric inputs for actual impact values
- Star rating widget for feedback_score
- Clear labels for predicted vs actual impact

---

## 7. TESTING CHECKLIST

- [ ] Record outcome for applied recommendation
- [ ] Outcome status set correctly (SUCCESS/PARTIAL/FAILED)
- [ ] Feedback score between 1 and 5
- [ ] Actual impact compared to predicted impact
- [ ] Analytics dashboard calculates success rate correctly
- [ ] Date range filters work for history view
- [ ] Export to CSV includes all fields
- [ ] Baseline comparison calculated accurately

---

## 8. FUTURE ENHANCEMENTS

1. Automated outcome tracking (no manual feedback needed)
2. Machine learning on feedback (improve recommendation quality)
3. Anomaly detection (flag surprising outcomes)
4. Recommendation lifecycle dashboarding (track full journey)
5. Stakeholder reports (custom summaries for principal/admin)
6. Impact prediction refinement (improve accuracy over time)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
