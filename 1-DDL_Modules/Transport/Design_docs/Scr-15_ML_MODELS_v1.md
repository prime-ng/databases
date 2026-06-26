# Screen Design Specification: ML Models Registry
## Document Version: 1.0
**Last Updated:** December 10, 2025

---

## 1. OVERVIEW

### 1.1 Purpose
Central registry for machine learning models used in transport optimization. Backed by `ml_models`.

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

Database Table: `ml_models`
├── id (BIGINT PRIMARY KEY)
├── model_name (VARCHAR)
├── model_type (ENUM: REGRESSION, CLASSIFICATION, CLUSTERING)
├── version (VARCHAR)
├── created_date (DATE)
├── artifact_path (VARCHAR)
├── accuracy_score (DECIMAL(5,3))
├── precision_score (DECIMAL(5,3))
├── recall_score (DECIMAL(5,3))
├── f1_score (DECIMAL(5,3))
├── status (ENUM: ACTIVE, INACTIVE, ARCHIVED, DEPRECATED)
├── last_trained (DATETIME, nullable)
├── deployed_date (DATETIME, nullable)
├── deleted_at (TIMESTAMP)

---

## 2. SCREEN LAYOUTS

### 2.1 ML Models Registry
**Route:** `/transport/ml-models`

#### 2.1.1 Layout (List + Metrics)
```
┌──────────────────────────────────────────────────────────────────┐
│ TRANSPORT > ML MODELS REGISTRY                                   │
├──────────────────────────────────────────────────────────────────┤
│ STATUS: [Active ▼]  TYPE: [All ▼]                                │
│ [+ Register Model] [Bulk Upload] [Export]                        │
├──────────────────────────────────────────────────────────────────┤
│ Model Name             | Type      | Version | Accuracy | Status │
├──────────────────────────────────────────────────────────────────┤
│ Route Optimizer        | Regression| v2.3.1  | 0.876    | ACTIVE     │
│ Demand Forecaster      | Regression| v1.5.2  | 0.812    | ACTIVE     │
│ Driver Classification  | Classifi..| v3.1.0  | 0.943    | ACTIVE     │
│ Student Cluster        | Clustering| v1.0.0  | N/A      | INACTIVE   │
│ ETA Predictor (v1)     | Regression| v1.2.0  | 0.654    | DEPRECATED |
│
│ [View Metrics] [View Artifacts] [Retrain] [Deploy] [Archive]
│
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Register New Model
#### 2.2.1 Registration Form
```
┌────────────────────────────────────────────────┐
│ REGISTER ML MODEL                           [✕]│
├────────────────────────────────────────────────┤
│ Model Name *              [Route Optimizer    ]│
│ Model Type *              [Regression ▼]      │
│ Version *                 [v2.3.1           ]│
│
│ PERFORMANCE METRICS
│ Accuracy Score *          [0.876            ]│
│ Precision Score *         [0.892            ]│
│ Recall Score *            [0.865            ]│
│ F1 Score *                [0.878            ]│
│
│ ARTIFACT DETAILS
│ Artifact Path *           [s3://bucket/...  ]│
│ File Size                 [245 MB]           │
│ Created Date *            [Calendar Picker]  │
│ Last Trained              [Calendar Picker]  │
│
│ STATUS
│ Status *                  [ACTIVE ▼]        │
│ Notes                     [__________________]│
│
├────────────────────────────────────────────────┤
│ [Cancel]  [Save & Deploy] [Save as Draft]    │
└────────────────────────────────────────────────┘
```

### 2.3 Model Details & Metrics
#### 2.3.1 Detail Panel
```
MODEL: Route Optimizer (v2.3.1)
────────────────────────────────────────────────
Type: Regression
Status: ACTIVE
Created: 2025-11-15
Last Trained: 2025-11-28
Deployed: 2025-12-01

PERFORMANCE METRICS
├─ Accuracy:   0.876
├─ Precision:  0.892
├─ Recall:     0.865
├─ F1 Score:   0.878

ARTIFACT INFO
├─ Artifact Path: s3://ml-models/route-opt-v2.3.1.pkl
├─ File Size: 245 MB
├─ Features: 24
├─ Training Samples: 50,000

[Retrain] [Test Model] [Deploy New Version] [Archive]
```

### 2.4 Model Artifacts & Versions
#### 2.4.1 Version History
```
MODEL: Route Optimizer
─────────────────────────────────────────────────────────────
Version | Type     | Created    | Accuracy | Status     | Actions
─────────────────────────────────────────────────────────────
v2.3.1  | ACTIVE   | 2025-11-15 | 0.876    | Deployed   | [Details] [Rollback]
v2.3.0  | Inactive | 2025-11-10 | 0.874    | Previous   | [Details] [Redeploy]
v2.2.5  | Archived | 2025-10-28 | 0.868    | Archived   | [Details]
v2.2.4  | Archived | 2025-10-15 | 0.865    | Archived   | [Details]
```

---

## 3. DATA MODEL & API CONTRACTS

### 3.1 Register Model
```json
POST /api/v1/transport/ml-models
{
  "model_name": "Route Optimizer",
  "model_type": "REGRESSION",
  "version": "v2.3.1",
  "created_date": "2025-11-15",
  "artifact_path": "s3://ml-models/route-opt-v2.3.1.pkl",
  "accuracy_score": 0.876,
  "precision_score": 0.892,
  "recall_score": 0.865,
  "f1_score": 0.878,
  "status": "ACTIVE"
}

Response:
{
  "id": 1,
  "model_name": "Route Optimizer",
  "version": "v2.3.1",
  "accuracy_score": 0.876,
  "status": "ACTIVE",
  "created_at": "2025-12-01T10:00:00Z"
}
```

### 3.2 Get Models
```json
GET /api/v1/transport/ml-models?status={status}&model_type={type}

Response:
{
  "data": [
    {
      "id": 1,
      "model_name": "Route Optimizer",
      "model_type": "REGRESSION",
      "version": "v2.3.1",
      "accuracy_score": 0.876,
      "precision_score": 0.892,
      "f1_score": 0.878,
      "status": "ACTIVE",
      "deployed_date": "2025-12-01T10:00:00Z"
    }
  ]
}
```

### 3.3 Update Model Status
```json
PATCH /api/v1/transport/ml-models/{id}
{
  "status": "INACTIVE",
  "notes": "Updating with new training data"
}
```

### 3.4 Deploy Model
```json
POST /api/v1/transport/ml-models/{id}/deploy
{
  "target_env": "production"
}

Response:
{
  "id": 1,
  "deployed_date": "2025-12-01T14:30:00Z",
  "status": "ACTIVE"
}
```

---

## 4. USER WORKFLOWS

### 4.1 Register New Model
```
1. Data Science team develops new model (Route Optimizer v2.3.1)
2. Uploads artifact to S3 bucket
3. Opens ML Models Registry
4. Clicks [+ Register Model]
5. Enters model details (name, type, version)
6. Enters performance metrics (accuracy, precision, recall, f1)
7. Provides artifact path and training date
8. Saves model (status = ACTIVE)
9. Can opt to deploy immediately or manually
```

### 4.2 Deploy Model to Production
```
1. Admin reviews model metrics (accuracy > 0.85 threshold)
2. Clicks [Deploy] on model
3. System copies artifact to production serving environment
4. Updates deployed_date
5. Sets status to ACTIVE
6. Model now used for real-time predictions
7. Rollback to previous version available
```

### 4.3 Archive Old Model
```
1. Admin determines model is deprecated (v2.2.5 replaced by v2.3.1)
2. Clicks [Archive] on old model
3. Status changed to ARCHIVED
4. Artifact remains but not used for predictions
5. Historical data preserved for audit
```

---

## 5. VISUAL DESIGN GUIDELINES

- Metrics displayed in prominent cards (accuracy, precision, recall)
- Color-code status: ACTIVE (green), INACTIVE (gray), ARCHIVED (silver), DEPRECATED (red)
- Version history timeline showing progression
- Responsive grid for model list

---

## 6. ACCESSIBILITY & USABILITY

- Performance metrics clearly labeled with explanations
- Numeric inputs for scores with decimal validation
- Calendar pickers for date fields
- Export to JSON for model metadata

---

## 7. TESTING CHECKLIST

- [ ] Register model with all required fields
- [ ] Accuracy score validation (0.0–1.0 range)
- [ ] Deploy model changes status to ACTIVE
- [ ] Archive model moves to ARCHIVED status
- [ ] Version history shows all model iterations
- [ ] Rollback to previous version works
- [ ] Export model metadata to JSON

---

## 8. FUTURE ENHANCEMENTS

1. Model performance monitoring dashboard (real-time metrics)
2. A/B testing framework (compare two models in production)
3. Auto-retraining scheduler (trigger when accuracy drops)
4. Model fairness and bias detection metrics
5. Prediction sample export and validation
6. Model card generation (documentation and responsible AI)

---

**Document Created By:** Database Architect
**Last Reviewed:** December 10, 2025
