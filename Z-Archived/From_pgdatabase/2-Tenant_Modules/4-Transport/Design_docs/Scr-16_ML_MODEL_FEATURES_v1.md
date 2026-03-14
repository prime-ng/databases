# Screen Design Specification: ML Model Features
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Define and manage features used by machine learning models in transport optimization. Backed by `ml_model_features`.

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

Database Table: `ml_model_features`
├── id (BIGINT PRIMARY KEY)
├── model_id (FK -> `ml_models.id`)
├── feature_name (VARCHAR)
├── feature_type (ENUM: NUMERIC, CATEGORICAL, TEMPORAL, GEOSPATIAL)
├── source_table (VARCHAR)
├── source_column (VARCHAR)
├── data_type (VARCHAR)
├── missing_value_strategy (ENUM: DROP, MEAN, MEDIAN, MODE, CUSTOM)
├── scaling_method (ENUM: NONE, MINMAX, ZSCORE, LOG)
├── feature_importance (DECIMAL(5,3))
├── is_active (BOOLEAN)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 Model Features List
**Route:** `/transport/ml-features`

#### 2.1.1 Layout (Features by Model)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > ML MODEL FEATURES                                    │
├──────────────────────────────────────────────────────────────────┤
│ MODEL: [Route Optimizer ▼]  STATUS: [Active ▼]                 │
│ [+ Add Feature] [Import CSV] [Export]                           │
├──────────────────────────────────────────────────────────────────┤
│ Feature Name       | Type       | Source    | Importance | Active│
├──────────────────────────────────────────────────────────────────┤
│ route_distance     | NUMERIC    | tpt_routes| 0.892      | ✓     │
│ student_count      | NUMERIC    | tpt_trip  | 0.876      | ✓     │
│ time_of_day        | TEMPORAL   | system    | 0.654      | ✓     │
│ traffic_density    | NUMERIC    | gps_logs  | 0.765      | ✓     │
│ vehicle_type       | CATEGORICAL| tpt_vehicle| 0.543     | ✓     │
│ driver_experience  | NUMERIC    | hrm_emp   | 0.701      | ✓     │
│
│ [Edit] [Delete] [Toggle Active]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Add/Edit Feature
#### 2.2.1 Feature Form
```
┌────────────────────────────────────────────────┐
│ ADD MODEL FEATURE                           [✕]│
├────────────────────────────────────────────────┤
│ Model *                   [Route Optimizer ▼]  │
│ Feature Name *            [route_distance    ]│
│ Feature Type *            [NUMERIC ▼]         │
│
│ DATA SOURCE
│ Source Table *            [tpt_routes ▼]     │
│ Source Column *           [distance ▼]       │
│ Data Type                 [DECIMAL]           │
│
│ PREPROCESSING
│ Missing Value Strategy    [DROP ▼]           │
│ Scaling Method            [MINMAX ▼]         │
│
│ IMPORTANCE
│ Feature Importance        [0.892            ]│
│ Is Active                 [☑] Yes            │
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Save]  [Save & Add Another]       │
└────────────────────────────────────────────────┘
```

### 2.3 Feature Engineering View
#### 2.3.1 Feature Transformation
```
FEATURE: route_distance
Model: Route Optimizer (v2.3.1)
────────────────────────────────────────────────
Source Table: tpt_routes
Source Column: distance
Data Type: DECIMAL(8,2)

STATISTICS (from training data)
├─ Count: 45,000 records
├─ Mean: 12.5 km
├─ Std Dev: 5.2 km
├─ Min: 0.5 km
├─ Max: 35.0 km
├─ Missing: 0 (0%)

PREPROCESSING CHAIN
1. Scaling: MINMAX (0.0–1.0)
2. Feature Importance: 0.892

IMPACT
├─ Used in Route Optimizer v2.3.1
├─ Used in ETA Predictor v1.2.0
└─ [View Impact on Other Models]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Create Feature
```json
POST /api/v1/transport/ml-features
{
  "model_id": 1,
  "feature_name": "route_distance",
  "feature_type": "NUMERIC",
  "source_table": "tpt_routes",
  "source_column": "distance",
  "data_type": "DECIMAL(8,2)",
  "missing_value_strategy": "DROP",
  "scaling_method": "MINMAX",
  "feature_importance": 0.892,
  "is_active": true
}

Response:
{
  "id": 1,
  "model_id": 1,
  "feature_name": "route_distance",
  "feature_type": "NUMERIC",
  "feature_importance": 0.892,
  "is_active": true,
  "created_at": "2025-12-01T10:00:00Z"
}
```

### 3.2 Get Model Features
```json
GET /api/v1/transport/ml-features?model_id={id}&is_active={true}

Response:
{
  "data": [
    {
      "id": 1,
      "model_id": 1,
      "feature_name": "route_distance",
      "feature_type": "NUMERIC",
      "source_table": "tpt_routes",
      "source_column": "distance",
      "feature_importance": 0.892,
      "is_active": true
    }
  ],
  "total_features": 24,
  "active_features": 24
}
```

### 3.3 Update Feature
```json
PATCH /api/v1/transport/ml-features/{id}
{
  "feature_importance": 0.905,
  "scaling_method": "ZSCORE",
  "is_active": false
}
```

---

## 4. USER WORKFLOWS

### 4.1 Add Feature to Model
```
1. Admin selects model (Route Optimizer)
2. Clicks [+ Add Feature]
3. Enters feature name (route_distance)
4. Selects source table and column
5. Chooses preprocessing (scaling, missing value handling)
6. Sets feature importance (from model's feature importance analysis)
7. Saves feature
```

### 4.2 Update Feature Engineering
```
1. Data scientist adjusts scaling method for feature
2. Updates feature_importance based on new model training
3. System applies changes to feature store
4. All downstream predictions recalculated
```

### 4.3 Deactivate Feature
```
1. Admin determines feature is no longer needed
2. Clicks [Toggle Active] to disable
3. Feature removed from model inference
4. Historical data preserved for audit
```

---

## 5. VISUAL DESIGN GUIDELINES

- Color-code feature types: NUMERIC (blue), CATEGORICAL (orange), TEMPORAL (green), GEOSPATIAL (purple)
- Importance scores visualized as horizontal bar charts
- Sortable by importance (descending)

---

## 6. ACCESSIBILITY & USABILITY

- Feature type dropdown searchable
- Decimal inputs with validation for importance (0.0–1.0)
- Statistics displayed in accessible tables

---

## 7. TESTING CHECKLIST

- [ ] Create feature for model with all required fields
- [ ] Feature importance score between 0.0 and 1.0
- [ ] Source table and column validation
- [ ] Update scaling method on existing feature
- [ ] Deactivate feature removes from model inference
- [ ] Export features to CSV includes all columns
- [ ] Statistics calculated from training data

---

## 8. FUTURE ENHANCEMENTS

1. Auto-detect features from source table (column introspection)
2. Feature interaction analysis (identify correlated features)
3. Feature selection algorithm (auto-remove low-importance features)
4. Feature store integration (fetch preprocessed values)
5. Feature importance visualization (SHAP values)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
