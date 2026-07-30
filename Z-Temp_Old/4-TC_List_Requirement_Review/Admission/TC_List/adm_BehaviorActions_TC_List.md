# adm_BehaviorActions — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Behavior Actions (Incident Follow-up Actions)
**DB scope:** TENANT-side (`adm_behavior_actions`) · **Test style:** Browser Dusk
**Primary table:** `adm_behavior_actions` · **Module URL prefix:** `/admission/behavior-incidents/{id}/actions`
**Test file:** `adm_BehaviorActions_TestCas.php`

Controller: `BehaviorActionController` (CRUD within incident detail)

Routes (`adm.` prefix):
- `GET /admission/behavior-incidents/{incident}/actions` — action list
- `POST /admission/behavior-incidents/{incident}/actions` — store
- `PUT /admission/behavior-actions/{action}` — update
- `DELETE /admission/behavior-actions/{action}` — soft delete

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_behavior_actions`: id (BIGINT PK AI), incident_id (BIGINT UNSIGNED FK → adm_behavior_incidents ON DELETE CASCADE), action_type (ENUM('Warning','Detention','Suspension','Expulsion','Parent_Meeting','Counseling','Community_Service') NOT NULL), description (TEXT NULL), start_date (DATE NULL), end_date (DATE NULL, must be >= start_date), parent_meeting_date (DATETIME NULL), meeting_outcome (TEXT NULL), action_by (INT UNSIGNED FK → sys_users NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_adm_ba_incident, idx_adm_ba_action_by, idx_adm_ba_action_type | DDL |
| BC-DB-02 | Model `BehaviorAction`: SoftDeletes, casts: due_date→date, completed_at→datetime, is_active→boolean. Relations: incident() belongsTo, assignedTo() belongsTo User, completedBy() belongsTo User | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `action_type` required in:Warning,Detention,Suspension,Expulsion,Parent_Meeting,Counseling,Community_Service | FR |
| BC-VAL-02 | `start_date` nullable date | FR |
| BC-VAL-03 | `end_date` nullable date after_or_equal:start_date | FR |
| BC-VAL-04 | `description` required string max:1000 | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | CRUD gate `tenant.adm-behavior-action.*` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Action list shown within incident detail page, chronological order | View |
| BC-BIZ-02 | Action_type badges: color-coded per type | View |
| BC-BIZ-03 | start_date/end_date shown for Detention, Suspension actions | View |
| BC-BIZ-04 | Parent_Meeting type shows parent_meeting_date and meeting_outcome | View |
| BC-BIZ-05 | action_by shows staff who took the action | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | No actions → empty state | View |
| BC-EDG-02 | end_date < start_date → validation error | Val |

---

## 2. Test Case List

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBA-P10 | Positive | Ctrl | Create action on incident → stored | Created | test_adm_ba_10 | Automated |
| TC-ADMBA-P11 | Positive | View | Action list: type badge, description, start/end dates, action_by | Rendered | test_adm_ba_11 | Automated |
| TC-ADMBA-P12 | Positive | View | Detention type shows start_date/end_date | Dates | test_adm_ba_12 | Automated |
| TC-ADMBA-P13 | Positive | View | Parent_Meeting type shows meeting date and outcome | Meeting | test_adm_ba_13 | Automated |
| TC-ADMBA-P14 | Positive | View | Empty state | Empty | test_adm_ba_14 | Automated |
| TC-ADMBA-N15 | Negative | Val | Missing action_type/description → required error | Error | test_adm_ba_15 | Automated |
| TC-ADMBA-N16 | Negative | Val | end_date < start_date → validation error | Error | test_adm_ba_16 | Automated |
