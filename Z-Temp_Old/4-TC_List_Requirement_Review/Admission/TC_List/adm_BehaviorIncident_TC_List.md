# adm_BehaviorIncident — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Behavior Incidents (CRUD + Soft-Delete + Review + Close + Actions)
**DB scope:** TENANT-side (`adm_behavior_incidents`, `adm_behavior_actions`) · **Test style:** Browser Dusk
**Primary table:** `adm_behavior_incidents` · **Module URL prefix:** `/admission/promotions-alumni?tab=incidents`
**Test file:** `adm_BehaviorIncident_TestCas.php`
**Tab:** Incidents (fourth tab of Promotions & Alumni)

Controllers:
- `AlumniController` — incident CRUD, review, close, actions
- `AdmMenuController::promotionsAlumni()` — loads incidents list

Routes (`adm.` prefix):
- `GET /admission/promotions-alumni` — tabbed page (incidents tab)
- `POST /admission/alumni/incidents` — store
- `GET /admission/alumni/incidents/{incident}` — show
- `PUT /admission/alumni/incidents/{incident}` — update
- `DELETE /admission/alumni/incidents/{incident}` — soft delete
- `POST /admission/alumni/incidents/{incident}/review` — Action_Taken
- `POST /admission/alumni/incidents/{incident}/close` — Closed
- `POST /admission/alumni/incidents/{incident}/actions` — store action
- `POST /admission/alumni/incidents/{id}/toggle-status` — AJAX toggle
- `GET /admission/alumni/incidents/trash/view` — trashed
- `GET /admission/alumni/incidents/{id}/restore` — restore
- `DELETE /admission/alumni/incidents/{id}/force-delete` — force delete

**DDL references:** `adm_behavior_incidents` (Layer 8), `adm_behavior_actions` (Layer 9)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_behavior_incidents`: id (BIGINT PK AI), student_id (FK → std_students), incident_date (DATE), incident_type (ENUM:Bullying,Cheating,Disruption,Absenteeism,Vandalism,Violence,Misconduct,Other), severity (ENUM:Low,Medium,High,Critical), description (TEXT), location (VARCHAR 100 NULL), witnesses_json (JSON NULL), reported_by (FK → sys_users NULL), parent_notified (BOOLEAN DEFAULT false), parent_notified_at (TIMESTAMP NULL), status (ENUM:Open,Action_Taken,Closed,Escalated DEFAULT Open), behavior_score_impact (TINYINT DEFAULT 0), is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-02 | Table `adm_behavior_actions`: id (BIGINT PK AI), incident_id (FK CASCADE → adm_behavior_incidents), action_type (ENUM:Warning,Detention,Suspension,Expulsion,Parent_Meeting,Counseling,Community_Service), description (TEXT NULL), start_date (DATE NULL), end_date (DATE NULL), parent_meeting_date (DATETIME NULL), meeting_outcome (TEXT NULL), action_by (FK → sys_users NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-03 | Model `BehaviorIncident`: table adm_behavior_incidents, SoftDeletes, HasFactory, fillable 14 fields, casts: incident_date→date, parent_notified_at→datetime, witnesses_json→array, behavior_score_impact→integer, parent_notified→boolean, is_active→boolean. Relations: student(), reportedBy(), actions() | Model |
| BC-DB-04 | Model `BehaviorAction`: table adm_behavior_actions, SoftDeletes, HasFactory, fillable 10 fields, casts: start_date/end_date→date, parent_meeting_date→datetime, is_active→boolean. Relations: incident(), actionBy() | Model |

### BC-VAL — Validation
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required integer exists:std_students,id | StoreIncident |
| BC-VAL-02 | `incident_date` required date | StoreIncident |
| BC-VAL-03 | `incident_type` required in:Bullying,Cheating,Disruption,Absenteeism,Vandalism,Violence,Misconduct,Other | StoreIncident |
| BC-VAL-04 | `severity` required in:Low,Medium,High,Critical | StoreIncident |
| BC-VAL-05 | `description` required string | StoreIncident |
| BC-VAL-06 | `location` nullable string max:100 | StoreIncident |
| BC-VAL-07 | `witnesses_json` nullable array (converted from comma string) | StoreIncident |
| BC-VAL-08 | `reported_by` nullable integer exists:sys_users,id | StoreIncident |
| BC-VAL-09 | `behavior_score_impact` integer min:-127 max:127 | StoreIncident |
| BC-VAL-10 | `action_type` required in:Warning,Detention,Suspension,Expulsion,Parent_Meeting,Counseling,Community_Service | StoreAction |
| BC-VAL-11 | `end_date` nullable date after:start_date | StoreAction |
| BC-VAL-12 | `parent_meeting_date` nullable date | StoreAction |
| BC-VAL-13 | `meeting_outcome` nullable string | StoreAction |

### BC-AUTH — Authorization (BehaviorIncidentPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/trashed gate `tenant.adm-incident.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.adm-incident.create` | Policy |
| BC-AUTH-03 | show gate `tenant.adm-incident.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.adm-incident.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.adm-incident.delete` | Policy |
| BC-AUTH-06 | review/close/actions gate `tenant.adm-incident.status` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Incidents list: search by student name, filter by severity/status, paginated 20, ordered by id desc | MenuCtrl |
| BC-BIZ-02 | Import: Store creates incident with status=Open, parent_notified=false | Ctrl |
| BC-BIZ-03 | Update: changes fields, prepares witnesses_json from comma string | Ctrl |
| BC-BIZ-04 | review(): status → Action_Taken | Ctrl |
| BC-BIZ-05 | close(): status → Closed | Ctrl |
| BC-BIZ-06 | Action store: creates corrective action, links to incident | Ctrl |
| BC-BIZ-07 | Severity badges: Low=success, Medium=warning, High=danger, Critical=dark | View |
| BC-BIZ-08 | Status badges: Open=primary, Action_Taken=info, Closed=secondary, Escalated=danger | View |
| BC-BIZ-09 | Incident show: detail card + actions list table + add action form | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | behavior_score_impact > 127 or < -127 → validation error | StoreIncident |
| BC-EDG-02 | end_date before start_date → after rule fails | StoreAction |
| BC-EDG-03 | Critical severity: parent_notified auto-triggered on store | DDL |
| BC-EDG-04 | Delete incident cascades to actions (FK CASCADE) | DDL |

---

## 2. Test Case List

### Screen 1: Incidents Tab (GET /admission/promotions-alumni?tab=incidents)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBI-P10 | Positive | View | Incidents tab: search, filters (severity, status), table (Type, Date, Student, Severity badge, Status badge, Score, Actions) | Rendered | test_adm_bi_10 | Automated |
| TC-ADMBI-P11 | Positive | View | Severity badges: Low=success, Medium=warning, High=danger, Critical=dark | Colors | test_adm_bi_11 | Automated |
| TC-ADMBI-P12 | Positive | View | Status badges: Open=primary, Action_Taken=info, Closed=secondary, Escalated=danger | Colors | test_adm_bi_12 | Automated |
| TC-ADMBI-P13 | Positive | View | Create/Edit modals with full incident form | Modals | test_adm_bi_13 | Automated |
| TC-ADMBI-P14 | Positive | View | Empty state when no incidents | Empty | test_adm_bi_14 | Automated |

### Screen 2: Create + Store (AJAX Modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBI-P30 | Positive | Ctrl | Store: status=Open, parent_notified=false, witnesses_json stored as array | Created | test_adm_bi_30 | Automated |
| TC-ADMBI-P31 | Positive | View | Modal fields: student, date, type, severity, description, location, witnesses, reported_by, score_impact | Fields | test_adm_bi_31 | Automated |
| TC-ADMBI-N32 | Negative | Val | Missing student_id/incident_date/incident_type/severity/description → required errors | Errors | test_adm_bi_32 | Automated |
| TC-ADMBI-N33 | Negative | Val | Invalid incident_type/severity → in: rule rejects | Errors | test_adm_bi_33 | Automated |
| TC-ADMBI-N34 | Negative | Val | behavior_score_impact out of -127..127 range → integer error | Error | test_adm_bi_34 | Automated |

### Screen 3: Show + Actions + Review + Close

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBI-P50 | Positive | View | Incident show: detail card (all fields), actions list table, add action form | Layout | test_adm_bi_50 | Automated |
| TC-ADMBI-P51 | Positive | Ctrl | Action store: creates corrective action linked to incident | Created | test_adm_bi_51 | Automated |
| TC-ADMBI-P52 | Positive | View | Action types: Warning, Detention, Suspension, Expulsion, Parent_Meeting, Counseling, Community_Service | Types | test_adm_bi_52 | Automated |
| TC-ADMBI-P53 | Positive | Ctrl | review(): status → Action_Taken | Reviewed | test_adm_bi_53 | Automated |
| TC-ADMBI-P54 | Positive | Ctrl | close(): status → Closed | Closed | test_adm_bi_54 | Automated |
| TC-ADMBI-N55 | Negative | Val | Action end_date before start_date → after rule fails | Error | test_adm_bi_55 | Automated |

### Screen 4: Edit + Update (AJAX Modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBI-P70 | Positive | Ctrl | Update: changes incident fields, prepares witnesses_json | Updated | test_adm_bi_70 | Automated |

### Screen 5: Soft Delete Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBI-P90 | Positive | Ctrl | Soft-delete incident → appears in trash (actions cascade deleted) | Trashed | test_adm_bi_90 | Automated |
| TC-ADMBI-P91 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_bi_91 | Automated |
| TC-ADMBI-P92 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_bi_92 | Automated |
| TC-ADMBI-P100 | Positive | Ctrl | Toggle is_active on/off returns JSON | JSON | test_adm_bi_100 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMBI-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_bi_200 | Automated |
| TC-ADMBI-P201 | Positive | Auth | Review/Close with status permission → success | 200 | test_adm_bi_201 | Automated |
| TC-ADMBI-N202 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_adm_bi_202 | Automated |
| TC-ADMBI-N203 | Negative | Auth | Without create → 403 on store | 403 | test_adm_bi_203 | Automated |
| TC-ADMBI-N204 | Negative | Auth | Without status → 403 on review/close/actions | 403 | test_adm_bi_204 | Automated |
