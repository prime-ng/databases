# adm_ApplicationStages — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Application Stages (Status Audit Trail)
**DB scope:** TENANT-side (`adm_application_stages`) · **Test style:** Browser Dusk
**Primary table:** `adm_application_stages` · **Module URL prefix:** `/admission/applications/{id}`
**Test file:** `adm_ApplicationStages_TestCas.php`

Controller: Handled internally by `AdmissionPipelineService` (append-only audit trail)

Routes: No direct CRUD — stages are appended automatically on status transitions

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_application_stages`: id (BIGINT PK AI), application_id (BIGINT UNSIGNED FK → adm_applications ON DELETE CASCADE), from_status (VARCHAR 50 NOT NULL), to_status (VARCHAR 50 NOT NULL), remarks (TEXT NULL), changed_by (INT UNSIGNED FK → sys_users NULL), changed_at (TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_adm_stage_app, idx_adm_stage_changed_at, idx_adm_stage_changed_by | DDL |
| BC-DB-02 | Model `ApplicationStage`: SoftDeletes, casts: changed_at→datetime, is_active→boolean. Relations: application() belongsTo, changedBy() belongsTo User | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | System-generated only — no user-facing create form | Design |
| BC-VAL-02 | `from_status` and `to_status` must be valid application lifecycle statuses | Service |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Read-only: visible to users with `tenant.adm-application.view` | Policy |
| BC-AUTH-02 | Append triggered internally by `AdmissionPipelineService` — no direct API | Service |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Immutable append-only audit trail — stages are NEVER updated or deleted | Service |
| BC-BIZ-02 | Every application status transition appends a stage record with from→to, timestamp, user | Service |
| BC-BIZ-03 | Stages displayed in reverse chronological order on application show page | View |
| BC-BIZ-04 | Timeline view: date badge, old status → new status arrow, staff name, remarks if any | View |
| BC-BIZ-05 | System transitions (e.g., offer expiry) show changed_by=NULL | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No stages → empty state (new application not yet submitted) | View |
| BC-EDG-02 | Consecutive same-status transitions (valid) → both recorded | Service |

---

## 2. Test Case List

### Screen 1: Application Show — Stages Timeline
| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMAST-P10 | Positive | View | Stages timeline: date, from→to status, staff name, remarks | Rendered | test_adm_ast_10 | Automated |
| TC-ADMAST-P11 | Positive | View | Stages sorted by changed_at DESC (newest first) | Sorted | test_adm_ast_11 | Automated |
| TC-ADMAST-P12 | Positive | View | System transitions show no staff name (changed_by=NULL) | System | test_adm_ast_12 | Automated |
| TC-ADMAST-P13 | Positive | Service | Status transition appends stage record with correct from/to | Appended | test_adm_ast_13 | Automated |
| TC-ADMAST-P14 | Positive | View | Empty state for new unsaved application | Empty | test_adm_ast_14 | Automated |
| TC-ADMAST-N15 | Negative | Biz | Attempt direct DELETE of stage → blocked (immutable) | Blocked | test_adm_ast_15 | Automated |
