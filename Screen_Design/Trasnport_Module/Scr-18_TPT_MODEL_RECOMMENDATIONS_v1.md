# Screen Design Specification: Model Recommendations
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
View and manage AI-generated recommendations for route optimization, driver assignments, and resource allocation. Backed by `tpt_model_recommendations`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✓    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_model_recommendations`
├── id (BIGINT PRIMARY KEY)
├── model_id (FK -> `ml_models.id`)
├── entity_type (ENUM: TRIP, ROUTE, DRIVER, STUDENT_ALLOCATION)
├── entity_id (BIGINT)
├── recommendation_text (TEXT)
├── recommendation_type (ENUM: ROUTE_OPTIMIZATION, DRIVER_ASSIGNMENT, SCHEDULE_ADJUSTMENT, COST_OPTIMIZATION, SAFETY)
├── confidence_score (DECIMAL(5,3))
├── estimated_impact (VARCHAR)
├── status (ENUM: PENDING, ACCEPTED, REJECTED, EXPIRED)
├── created_date (DATE)
├── expiry_date (DATE, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Recommendations Dashboard
**Route:** `/transport/recommendations`

#### 2.1.1 Layout (Pending + History)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > AI RECOMMENDATIONS                                   │
├──────────────────────────────────────────────────────────────────┤
│ STATUS: [Pending ▼]  TYPE: [All ▼]  CONFIDENCE: [≥ 0.7 ▼]      │
│ [Apply Selected] [Reject Selected] [View History] [Export]      │
├──────────────────────────────────────────────────────────────────┤
│
│ ┌─ HIGH CONFIDENCE ─────────────────────────────────────┐
│ │ ✓ Route Optimization - Trip 123                       │
│ │   Confidence: 0.92 | Impact: Save 15 min, ₹50       │
│ │   Recommendation: Merge stops 5→6 (adjacent)         │
│ │   Model: Route Optimizer v2.3.1                      │
│ │   [Details] [Apply] [Reject] [Snooze 7 days]        │
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ MEDIUM CONFIDENCE ───────────────────────────────────┐
│ │ ○ Driver Assignment - Route A (Morning)              │
│ │   Confidence: 0.78 | Impact: Better vehicle match   │
│ │   Recommendation: Assign Ravi Kumar (experienced)    │
│ │   Model: Driver Classification v3.1.0                │
│ │   [Details] [Apply] [Reject]                         │
│ │
│ └───────────────────────────────────────────────────────┘
│
│ ┌─ LOW CONFIDENCE ──────────────────────────────────────┐
│ │ ○ Schedule Adjustment - Route B                      │
│ │   Confidence: 0.65 | Impact: Reduced traffic        │
│ │   Recommendation: Delay morning trip by 10 minutes   │
│ │   Model: Demand Forecaster v1.5.2                    │
│ │   [Details] [Apply] [Reject]                         │
│ │
│ └───────────────────────────────────────────────────────┘
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Recommendation Detail
#### 2.2.1 Full Recommendation Card
```
┌────────────────────────────────────────────────────────┐
│ RECOMMENDATION DETAIL                               [✕]│
├────────────────────────────────────────────────────────┤
│ ID: REC-2025-0142
│ Type: ROUTE_OPTIMIZATION
│ Entity: TRIP-123
│ Model: Route Optimizer v2.3.1
│
│ CONFIDENCE & IMPACT
│ Confidence Score: 92% (High)
│ Estimated Impact: Save 15 minutes + ₹50
│ Prediction Explanation: Route recalculation reduces
│   average trip time by 12% with lower fuel consumption
│
│ RECOMMENDATION
│ "Merge stops 5 and 6 into a single stop location
│  (geo-proximity < 500m). This reduces travel time
│  between stops and improves driver efficiency."
│
│ AFFECTED ENTITIES
│ • Trip: Trip-123 (Route A)
│ • Stop 5: Sector 12 (Pickup)
│ • Stop 6: Sector 13 (Pickup)
│ • Students: 8
│
│ HISTORICAL ACCEPTANCE
│ Applied Before: Yes (3 times)
│ Success Rate: 100%
│ Average Actual Impact: Save 14 min
│
│ STATUS: PENDING (Expires: 2025-12-08)
│ Created: 2025-12-01 09:30:00
│
│ [Apply] [Reject] [Snooze 7 Days] [Email to Principal]
│
└────────────────────────────────────────────────────────┘
```

### 2.3 Recommendations Analytics
#### 2.3.1 Impact Dashboard
```
RECOMMENDATIONS SUMMARY
Date Range: Last 30 Days
────────────────────────────────────────────────────
Total Recommendations: 45
├─ Accepted: 32 (71%)
├─ Rejected: 8 (18%)
├─ Pending: 5 (11%)

BY TYPE
├─ Route Optimization: 18 (avg confidence: 0.87)
├─ Driver Assignment: 12 (avg confidence: 0.79)
├─ Schedule Adjustment: 10 (avg confidence: 0.72)
├─ Cost Optimization: 4 (avg confidence: 0.81)
└─ Safety: 1 (avg confidence: 0.95)

IMPACT
├─ Time Saved: 450 minutes (9 hours)
├─ Cost Savings: ₹5,400
└─ Safety Incidents Prevented: 2
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Recommendation
```json
POST /api/v1/transport/recommendations
{
  "model_id": 1,
  "entity_type": "TRIP",
  "entity_id": 123,
  "recommendation_text": "Merge stops 5 and 6 (geo-proximity < 500m)",
  "recommendation_type": "ROUTE_OPTIMIZATION",
  "confidence_score": 0.92,
  "estimated_impact": "Save 15 min, ₹50",
  "status": "PENDING",
  "created_date": "2025-12-01",
  "expiry_date": "2025-12-08"
}

Response:
{
  "id": 142,
  "model_id": 1,
  "entity_type": "TRIP",
  "recommendation_type": "ROUTE_OPTIMIZATION",
  "confidence_score": 0.92,
  "status": "PENDING",
  "created_at": "2025-12-01T09:30:00Z"
}
```

### 3.2 Get Recommendations
```json
GET /api/v1/transport/recommendations?status=PENDING&min_confidence=0.7&entity_type=TRIP

Response:
{
  "data": [
    {
      "id": 142,
      "model_id": 1,
      "model_name": "Route Optimizer",
      "entity_type": "TRIP",
      "entity_id": 123,
      "recommendation_text": "Merge stops 5 and 6",
      "recommendation_type": "ROUTE_OPTIMIZATION",
      "confidence_score": 0.92,
      "estimated_impact": "Save 15 min, ₹50",
      "status": "PENDING",
      "expiry_date": "2025-12-08"
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 45}
}
```

### 3.3 Apply Recommendation
```json
PATCH /api/v1/transport/recommendations/{id}
{
  "status": "ACCEPTED"
}

Response:
{
  "id": 142,
  "status": "ACCEPTED",
  "accepted_at": "2025-12-01T10:00:00Z"
}
```

### 3.4 Reject Recommendation
```json
PATCH /api/v1/transport/recommendations/{id}
{
  "status": "REJECTED",
  "rejection_reason": "Driver prefers existing route"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Review & Apply Recommendation
```
1. Admin opens Recommendations dashboard
2. Filters for high-confidence pending recommendations
3. Reviews recommendation details (impact, explanation, history)
4. Clicks [Apply]
5. System executes recommendation (updates trip, route, etc.)
6. Stores acceptance in recommendation_history
7. Notification sent to stakeholders
```

### 4.2 Reject Recommendation
```
1. Admin reviews recommendation
2. Determines not applicable (e.g., principal prefers current setup)
3. Clicks [Reject]
4. Optionally adds rejection reason
5. Recommendation marked as REJECTED
6. No further action
```

### 4.3 Snooze & Re-Review
```
1. Admin not ready to apply recommendation now
2. Clicks [Snooze 7 Days]
3. Recommendation hidden from dashboard
4. Reappears after 7 days with reminder
5. Can be applied, rejected, or snoozed again
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code confidence: High (green ≥0.8), Medium (yellow 0.6–0.8), Low (orange <0.6)
- Recommendation cards stacked, highest confidence first
- Impact displayed prominently (time, cost, safety)
- Timeline showing acceptance rate over time

---

## 6. ACCESSIBILITY & USABILITY

- Confidence score visualized as filled circle (percentage fill)
- Clear explanation of recommendation reasoning
- Keyboard shortcuts for Apply [A], Reject [R], Snooze [S]

---

## 7. TESTING CHECKLIST

- [ ] Recommendation created with valid entity_type and confidence score
- [ ] Confidence score between 0.0 and 1.0
- [ ] Pending recommendations filtered by confidence threshold
- [ ] Apply recommendation updates status and creates history entry
- [ ] Reject recommendation with optional reason
- [ ] Snooze recommendation hides and re-shows after delay
- [ ] Expired recommendations auto-expire after expiry_date
- [ ] Analytics dashboard calculates acceptance rate correctly

---

## 8. FUTURE ENHANCEMENTS

1. Auto-apply recommendations (for high-confidence + low-risk recommendations)
2. A/B testing framework (compare applied vs rejected recommendations)
3. Recommendation explanation using SHAP values (feature importance)
4. Feedback loop (track actual impact vs predicted impact)
5. Recommendation scheduling (apply at optimal time)
6. Batch apply recommendations (bulk operations)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
