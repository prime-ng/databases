# Screen Design Specification: Feature Store
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Centralized repository of preprocessed feature vectors for model serving and offline/online prediction. Backed by `tpt_feature_store`.

### 1.2 User Roles & Permissions
| Role | Create | View | Update | Delete | print | Export | Import |
|------|--------|------|--------|--------|-------|--------|--------|
| Super Admin  |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| PG Support   |   ✓   |  ✓  |   ✓    |   ✓    |  ✓   |  ✓    |  ✓    |
| School Admin |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✓    |  ✗    |
| Principal    |   ✗   |  ✓  |   ✗    |   ✗    |  ✓   |  ✗    |  ✗    |
| Teacher      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Student      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |
| Parents      |   ✗   |  ✗  |   ✗    |   ✗    |  ✗   |  ✗    |  ✗    |

### 1.3 Data Context

Database Table: `tpt_feature_store`
├── id (BIGINT PRIMARY KEY)
├── entity_type (ENUM: TRIP, ROUTE, DRIVER, STUDENT, VEHICLE)
├── entity_id (BIGINT)
├── feature_vector (JSON)
├── computed_date (DATE)
├── is_latest (BOOLEAN)
├── model_id (FK -> `ml_models.id`, nullable)
├── feature_version (INT)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Feature Store Dashboard
**Route:** `/transport/feature-store`

#### 2.1.1 Layout (Feature Vector Browser)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > FEATURE STORE                                        │
├──────────────────────────────────────────────────────────────────┤
│ ENTITY TYPE: [TRIP ▼]  DATE: [2025-12-01 ▼]                    │
│ SEARCH: [Entity ID]  [Advanced Filter]                          │
│ [Compute Features] [Refresh Cache] [Export]                     │
├──────────────────────────────────────────────────────────────────┤
│ Entity ID | Model       | Feature Version | Computed Date | Latest│
├──────────────────────────────────────────────────────────────────┤
│ TRIP-123  | Route Optim.| v2.3.1         | 2025-12-01   | ✓     │
│ TRIP-124  | Route Optim.| v2.3.1         | 2025-12-01   | ✓     │
│ TRIP-122  | Route Optim.| v2.3.0         | 2025-11-30   | ✗     │
│ TRIP-125  | ETA Predict.| v1.2.0         | 2025-12-01   | ✓     │
│
│ [View Vectors] [View History] [Recompute]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Feature Vector Details
#### 2.2.1 Vector Viewer
```
┌────────────────────────────────────────────────────────────────┐
│ FEATURE VECTOR: TRIP-123 (Route Optimizer v2.3.1)          [✕]│
├────────────────────────────────────────────────────────────────┤
│ Entity ID: TRIP-123
│ Model: Route Optimizer v2.3.1
│ Feature Version: v2.3.1
│ Computed Date: 2025-12-01 10:15:30
│ Is Latest: Yes
│
│ FEATURE VECTOR (JSON)
│ ┌──────────────────────────────────────────────────────┐
│ │ {                                                    │
│ │   "route_distance": 0.64,                           │
│ │   "student_count": 0.82,                            │
│ │   "time_of_day": 0.45,                              │
│ │   "traffic_density": 0.58,                          │
│ │   "vehicle_type_encoded": 1,                        │
│ │   "driver_experience": 0.75,                        │
│ │   "day_of_week": 3,                                 │
│ │   "weather_condition": 0.2                          │
│ │ }                                                    │
│ └──────────────────────────────────────────────────────┘
│
│ VECTOR STATISTICS
│ Size: 8 features
│ Data Type: Float32
│ Missing Values: 0
│
│ [Copy JSON] [Export] [View Prediction]
│
└────────────────────────────────────────────────────────────────┘
```

### 2.3 Feature Computation Status
#### 2.3.1 Batch Computation
```
BATCH COMPUTATION: Route Optimizer Features
Date: 2025-12-01
────────────────────────────────────────────────────────────
Status: In Progress
├─ Total Trips: 450
├─ Computed: 385 (85%)
├─ Failed: 2
├─ Pending: 63
├─ Estimated Time: 5 minutes remaining

[Pause] [Resume] [Cancel] [View Logs]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Feature Vector
```json
POST /api/v1/transport/feature-store
{
  "entity_type": "TRIP",
  "entity_id": 123,
  "feature_vector": {
    "route_distance": 0.64,
    "student_count": 0.82,
    "time_of_day": 0.45,
    "traffic_density": 0.58,
    "vehicle_type_encoded": 1,
    "driver_experience": 0.75,
    "day_of_week": 3,
    "weather_condition": 0.2
  },
  "computed_date": "2025-12-01",
  "is_latest": true,
  "model_id": 1,
  "feature_version": 1
}

Response:
{
  "id": 1000,
  "entity_type": "TRIP",
  "entity_id": 123,
  "feature_version": 1,
  "computed_date": "2025-12-01",
  "is_latest": true,
  "created_at": "2025-12-01T10:15:30Z"
}
```

### 3.2 Get Feature Vectors
```json
GET /api/v1/transport/feature-store?entity_type=TRIP&entity_id={id}&is_latest=true

Response:
{
  "data": [
    {
      "id": 1000,
      "entity_type": "TRIP",
      "entity_id": 123,
      "feature_vector": {
        "route_distance": 0.64,
        "student_count": 0.82,
        "time_of_day": 0.45,
        "traffic_density": 0.58,
        "vehicle_type_encoded": 1,
        "driver_experience": 0.75,
        "day_of_week": 3,
        "weather_condition": 0.2
      },
      "computed_date": "2025-12-01",
      "is_latest": true,
      "model_id": 1
    }
  ]
}
```

### 3.3 Batch Compute Features
```json
POST /api/v1/transport/feature-store/batch-compute
{
  "entity_type": "TRIP",
  "model_id": 1,
  "compute_date": "2025-12-01",
  "entity_ids": [123, 124, 125]
}

Response:
{
  "job_id": "job-12345",
  "status": "IN_PROGRESS",
  "total_entities": 3,
  "started_at": "2025-12-01T10:00:00Z"
}
```

### 3.4 Get Batch Status
```json
GET /api/v1/transport/feature-store/batch-compute/{job_id}

Response:
{
  "job_id": "job-12345",
  "status": "COMPLETED",
  "total_entities": 3,
  "computed": 3,
  "failed": 0,
  "started_at": "2025-12-01T10:00:00Z",
  "completed_at": "2025-12-01T10:05:00Z"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Compute Features for New Trip
```
1. New trip created (TRIP-123)
2. System fetches entity data (route, driver, students, etc.)
3. Preprocesses features according to ml_model_features config
4. Creates feature vector in feature_store
5. Stores with is_latest=true
6. Ready for model predictions
```

### 4.2 Batch Compute Features
```
1. Admin selects entity type (TRIP) and date (2025-12-01)
2. Selects model (Route Optimizer v2.3.1)
3. Clicks [Compute Features]
4. System queues batch job
5. Computes vectors for all entities on that date
6. Updates feature_store with latest vectors
7. Progress bar shown; can pause/resume/cancel
```

### 4.3 View Historical Vectors
```
1. Admin selects entity (TRIP-123)
2. Views all feature vectors (v1, v2, v3 versions)
3. Compares vectors across model versions
4. Analyzes feature value changes
```

---

## 5. VISUAL DESIGN GUIDELINES

- Feature vectors displayed as JSON/key-value pairs
- Color-code normalization: values closer to 1.0 = brighter (green), closer to 0.0 = darker (red)
- Batch progress shown as circular progress indicator
- Responsive grid for vector list

---

## 6. ACCESSIBILITY & USABILITY

- JSON viewer with copy-to-clipboard button
- Keyboard navigation for vector list
- Date pickers for batch computation filters

---

## 7. TESTING CHECKLIST

- [ ] Create feature vector for trip with all required fields
- [ ] Feature vector JSON structure validated
- [ ] Batch compute processes multiple entities
- [ ] is_latest flag updated when new vector created
- [ ] Feature version tracked correctly
- [ ] Batch job pause/resume works
- [ ] Export vectors to CSV includes JSON as string

---

## 8. FUTURE ENHANCEMENTS

1. Feature vector caching layer (Redis for low-latency access)
2. Online feature computation (real-time from live data)
3. Feature drift detection (alert when feature distributions change)
4. Vector similarity search (find similar trips)
5. Feature correlation analysis (identify redundant features)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
