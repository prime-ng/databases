# adm_MeritList — Test Case List & Business Conditions

**Module:** Admission (CODE `ADM`, prefix `adm_`) · **Feature:** Merit Lists (CRUD + Soft-Delete + Toggle + Compute Scores + Publish)
**DB scope:** TENANT-side (`adm_merit_lists`, `adm_merit_list_entries`) · **Test style:** Browser Dusk
**Primary table:** `adm_merit_lists` · **Module URL prefix:** `/admission/assessment?tab=merit-lists`
**Test file:** `adm_MeritList_TestCas.php`
**Tab:** Merit Lists (second tab of the Assessment page)

Controllers:
- `MeritListController` — CRUD + trash + toggle + compute + publish
- `AdmMenuController::assessment()` — loads merit lists + entrance tests for pipeline page

Routes (`adm.` prefix):
- `GET /admission/assessment` — assessment page (merit-lists tab)
- `POST /admission/merit-lists` — store
- `GET /admission/merit-lists/{list}` — show
- `PUT /admission/merit-lists/{list}` — update
- `DELETE /admission/merit-lists/{list}` — soft delete
- `POST /admission/merit-lists/{id}/toggle-status` — toggle active (JSON)
- `POST /admission/merit-lists/{list}/compute` — compute scores (composite, ranking)
- `POST /admission/merit-lists/{list}/publish` — publish (Draft → Published)

Views:
- `pages/assessment.blade.php` — parent page (Merit Lists tab)
- `pages/partials/assessment/_merit-lists.blade.php` — merit lists tab partial (400 lines, AJAX modals)
- `pages/merit-list-show.blade.php` — detailed ranked candidates view (162 lines)
- `entrance-tests/trash.blade.php` — soft-deleted list (shared pattern)

Service:
- `MeritListService::computeScores()` — scoring engine with configurable criteria weights

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `adm_merit_lists`: id (BIGINT PK AI), admission_cycle_id (BIGINT UNSIGNED FK), class_id (INT UNSIGNED FK), quota_type (ENUM('General','Government','Management','RTE','NRI','Staff_Ward','Sibling','EWS')), generated_at (TIMESTAMP NULL), generated_by (INT UNSIGNED FK NULL), status (ENUM('Draft','Published','Finalized') DEFAULT 'Draft'), criteria_json (JSON NULL), sibling_bonus_score (TINYINT UNSIGNED DEFAULT 5), cutoff_score (DECIMAL 6,2 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_adm_ml_cycle_class_quota, idx_adm_ml_status, idx_adm_ml_generated_by | DDL |
| BC-DB-02 | Table `adm_merit_list_entries`: id (BIGINT PK AI), merit_list_id (BIGINT UNSIGNED FK), application_id (BIGINT UNSIGNED FK), merit_rank (SMALLINT UNSIGNED NOT NULL), composite_score (DECIMAL 6,2 NULL), entrance_score (DECIMAL 6,2 NULL), interview_score (DECIMAL 6,2 NULL), academic_score (DECIMAL 6,2 NULL), sibling_bonus_applied (TINYINT 1 DEFAULT 0), merit_status (ENUM('Shortlisted','Waitlisted','Rejected') DEFAULT 'Shortlisted'), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_adm_mle_list, idx_adm_mle_rank, idx_adm_mle_app, idx_adm_mle_status, idx_adm_mle_score | DDL |
| BC-DB-03 | Model `MeritList`: table adm_merit_lists, SoftDeletes, HasFactory, fillable 13 fields, casts: sibling_bonus_score→integer, cutoff_score→decimal:2, criteria_json→array, generated_at→datetime, is_active→boolean. Relations: cycle() belongsTo AdmissionCycle, schoolClass() belongsTo SchoolClass, generatedBy() belongsTo User, entries() hasMany MeritListEntry | Model |
| BC-DB-04 | Model `MeritListEntry`: table adm_merit_list_entries, SoftDeletes, HasFactory, fillable 12 fields, casts: composite_score/entrance_score/interview_score/academic_score→decimal:3, sibling_bonus_applied→boolean, is_active→boolean | Model |
| BC-DB-05 | (covered in BC-DB-03) | Model |
| BC-DB-06 | (covered in BC-DB-04) | Model |

### BC-VAL — Validation (StoreMeritListRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `admission_cycle_id` required integer exists:adm_admission_cycles,id | FR |
| BC-VAL-02 | `class_id` required integer exists:sch_classes,id | FR |
| BC-VAL-03 | `quota_type` required string | FR |
| BC-VAL-04 | `list_name` required string max:100 | FR |
| BC-VAL-05 | `seat_capacity` nullable integer min:1 | FR |
| BC-VAL-06 | `sibling_bonus_score` nullable numeric min:0 max:100 | FR |
| BC-VAL-07 | `cutoff_score` nullable numeric min:0 | FR |
| BC-VAL-08 | `is_active` nullable boolean | FR |
| BC-VAL-09 | `criteria_json` JSON with keys: academic_weight, entrance_weight, interview_weight | DDL |
| BC-VAL-10 | Criteria weights must sum to 100 (custom validation in withValidator) | FR |

### BC-VAL-UPD — UpdateMeritListRequest
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-UPD-01 | Same rules as Store (authorizes tenant.adm-merit-list.update) | FR |

### BC-AUTH — Authorization (MeritListPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.adm-merit-list.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.adm-merit-list.create` | Policy |
| BC-AUTH-03 | show gate `tenant.adm-merit-list.view` | Policy |
| BC-AUTH-04 | edit/update/toggleStatus gate `tenant.adm-merit-list.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.adm-merit-list.delete` | Policy |
| BC-AUTH-06 | compute/publish/submit gate `tenant.adm-merit-list.status` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Assessment page loads Merit Lists tab alongside Entrance Tests tab | MenuCtrl |
| BC-BIZ-02 | Merit list list: searches by list_name LIKE, filtered by status, paginated 20, ordered by id desc | MenuCtrl |
| BC-BIZ-03 | List loads cycle and schoolClass relations | MenuCtrl |
| BC-BIZ-04 | Status display: Draft, Published | View |
| BC-BIZ-05 | Store: defaults status='Draft', criteria_json stored as JSON with keys: academic_weight, entrance_weight, interview_weight | Ctrl |
| BC-BIZ-06 | Criterial weights must sum to exactly 100 (withValidator custom validation) | StoreRequest |
| BC-BIZ-07 | compute(): calls MeritListService::computeScores($meritList), catches DomainException | Ctrl |
| BC-BIZ-08 | publish(): calls MeritListService::publish($meritList), sets status=Published, published_at=now, logs activity | Ctrl |
| BC-BIZ-09 | Show loads entries ordered by merit_rank ascending, with application relation | Ctrl |
| BC-BIZ-10 | Toggle: validates is_active boolean, updates, returns JSON | Ctrl |
| BC-BIZ-11 | Delete is soft | Ctrl |

### BC-BIZ-COMPUTE — Scoring Engine (MeritListService)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-COMPUTE-01 | Fetches applications with status IN (Shortlisted, Waitlisted) for the merit list's cycle + class + quota | Service |
| BC-BIZ-COMPUTE-02 | Default weights: academic=40%, entrance=40%, interview=20% (if criteria_json not set) | Service |
| BC-BIZ-COMPUTE-03 | Academic score: computed from application's prev_marks_percent (normalized to 0-100) | Service |
| BC-BIZ-COMPUTE-04 | Entrance score: fetches best EntranceTestCandidate result for the application (highest marks_obtained / max_marks ratio), normalized to 0-100. Skips candidates with absent or no marks. | Service |
| BC-BIZ-COMPUTE-05 | Interview score: computed from application's interview_score (0-100 scale) | Service |
| BC-BIZ-COMPUTE-06 | Composite = (academic_weight% × academic) + (entrance_weight% × entrance) + (interview_weight% × interview), all normalized 0-100 | Service |
| BC-BIZ-COMPUTE-07 | Sibling bonus: if merit_list.sibling_bonus_score > 0 and application.is_sibling=true, adds bonus to composite_score | Service |
| BC-BIZ-COMPUTE-08 | All entries sorted by composite_score DESC; tiebreak by application_no ASC (FIFO) | Service |
| BC-BIZ-COMPUTE-09 | merit_status assignment: Shortlisted (rank ≤ seat_capacity), Waitlisted (rank > seat_capacity but composite ≥ cutoff_score), Rejected (composite < cutoff_score) | Service |
| BC-BIZ-COMPUTE-10 | Stores generated_by=auth id, generated_at=now | Service |
| BC-BIZ-COMPUTE-11 | Re-computation: deletes existing entries before re-computing (idempotent) | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Criteria weights not summing to 100 → validation error | StoreRequest |
| BC-EDG-02 | No shortlisted/waitlisted applications → merit list computed with zero entries | Service |
| BC-EDG-03 | No entrance test score available → entrance_score=0 for that candidate | Service |
| BC-EDG-04 | No interview score → interview_score=0 for that candidate | Service |
| BC-EDG-05 | Sibling bonus applied to non-sibling → bonus not added (is_sibling=false) | Service |
| BC-EDG-06 | Publish on already-published list → allowed (re-publish) | Service |
| BC-EDG-07 | Compute on Published list → allowed (re-compute with new entries) | Service |
| BC-EDG-08 | seat_capacity null → all entries get merit_status based on cutoff_score only | Service |
| BC-EDG-09 | cutoff_score null → no Rejected status, all entries are Shortlisted or Waitlisted | Service |

---

## 2. Test Case List

### Screen 1: Assessment — Merit Lists Tab (GET /admission/assessment?tab=merit-lists)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P10 | Positive | View | Merit Lists tab renders with table (List Name, Class & Quota, Cycle, Status badge, Active toggle, Actions) | Rendered | test_adm_ml_10 | Automated |
| TC-ADMML-P11 | Positive | View | Search by list_name, filter by status dropdown | Filtered | test_adm_ml_11 | Automated |
| TC-ADMML-P12 | Positive | View | Status badges: Draft=secondary, Published=success | Colors | test_adm_ml_12 | Automated |
| TC-ADMML-P13 | Positive | View | AJAX Create modal opens with all fields | Modal | test_adm_ml_13 | Automated |
| TC-ADMML-P14 | Positive | View | AJAX Edit modal pre-populated | Modal | test_adm_ml_14 | Automated |
| TC-ADMML-P15 | Positive | View | Empty state when no merit lists | Empty | test_adm_ml_15 | Automated |

### Screen 2: Create + Store (AJAX modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P30 | Positive | Ctrl | Valid create via AJAX: status=Draft, criteria_weights as JSON, returns JSON | Created | test_adm_ml_30 | Automated |
| TC-ADMML-P31 | Positive | View | Modal fields: cycle, class, quota_type, list_name, seat_capacity, sibling_bonus, cutoff_score, criteria weights (academic/entrance/interview) | All fields | test_adm_ml_31 | Automated |
| TC-ADMML-P32 | Positive | View | Dropdowns load active cycles, active classes | Loaded | test_adm_ml_32 | Automated |
| TC-ADMML-N33 | Negative | Val | Missing admission_cycle_id/class_id/quota_type/list_name → required errors | Errors | test_adm_ml_33 | Automated |
| TC-ADMML-N34 | Negative | Val | Criteria weights sum ≠ 100 → validation error | Weights error | test_adm_ml_34 | Automated |
| TC-ADMML-N35 | Negative | Val | sibling_bonus > 100 → max rule | Error | test_adm_ml_35 | Automated |

### Screen 3: Show (GET /admission/merit-lists/{list})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P50 | Positive | View | Show page: list info header (name, cycle, class, quota, status, seat_capacity, cutoff, weights) | Header | test_adm_ml_50 | Automated |
| TC-ADMML-P51 | Positive | View | Ranked candidates table: Rank, Application No, Student Name, Composite/Academic/Entrance/Interview scores, Sibling Bonus, Status, Allotment | Table | test_adm_ml_51 | Automated |
| TC-ADMML-P52 | Positive | View | Sorted by merit_rank ascending | Sorted | test_adm_ml_52 | Automated |
| TC-ADMML-P53 | Positive | View | merit_status badges: Shortlisted=success, Waitlisted=warning, Rejected=danger | Colors | test_adm_ml_53 | Automated |
| TC-ADMML-P54 | Positive | View | Compute and Publish buttons visible (permission-gated) | Buttons | test_adm_ml_54 | Automated |
| TC-ADMML-P55 | Positive | View | No entries → empty state | Empty | test_adm_ml_55 | Automated |

### Screen 4: Update (AJAX modal)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P70 | Positive | Ctrl | Update via AJAX: changes fields, returns JSON | Updated | test_adm_ml_70 | Automated |
| TC-ADMML-N71 | Negative | Val | Update with invalid weights sum → validation error | Error | test_adm_ml_71 | Automated |

### Screen 5: Compute + Publish

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P90 | Positive | Service | Compute with shortlisted apps: creates entries with rank, scores, merit_status | Computed | test_adm_ml_90 | Automated |
| TC-ADMML-P91 | Positive | Service | Composite score = weighted sum (academic + entrance + interview), normalized 0-100 | Correct score | test_adm_ml_91 | Automated |
| TC-ADMML-P92 | Positive | Service | Sibling bonus added when is_sibling=true and sibling_bonus > 0 | Bonus applied | test_adm_ml_92 | Automated |
| TC-ADMML-P93 | Positive | Service | Entry ranked by composite DESC, tiebreak by application_no ASC | Correct rank | test_adm_ml_93 | Automated |
| TC-ADMML-P94 | Positive | Service | Shortlisted: rank ≤ seat_capacity, Waitlisted: > seat_capacity but ≥ cutoff, Rejected: < cutoff | Statuses | test_adm_ml_94 | Automated |
| TC-ADMML-P95 | Positive | Service | Re-compute deletes old entries, creates new ones (idempotent) | Re-computed | test_adm_ml_95 | Automated |
| TC-ADMML-P96 | Positive | Ctrl | Publish: status=Published, published_at=now, activity logged | Published | test_adm_ml_96 | Automated |
| TC-ADMML-P97 | Positive | Ctrl | Publish on already-published list → allowed (re-publish) | Re-published | test_adm_ml_97 | Automated |
| TC-ADMML-N98 | Negative | Edge | No shortlisted/waitlisted apps → compute with zero entries | Empty list | test_adm_ml_98 | Automated |
| TC-ADMML-N99 | Negative | Edge | No entrance scores → entrance_score=0, composite from other weights only | Zero entrance | test_adm_ml_99 | Automated |

### Screen 6: Soft Delete Lifecycle + Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P110 | Positive | Ctrl | Soft-delete merit list, appears in trash | Trashed | test_adm_ml_110 | Automated |
| TC-ADMML-P111 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_adm_ml_111 | Automated |
| TC-ADMML-P112 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_adm_ml_112 | Automated |
| TC-ADMML-P120 | Positive | Ctrl | Toggle is_active on/off returns JSON | JSON | test_adm_ml_120 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-ADMML-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_adm_ml_200 | Automated |
| TC-ADMML-P201 | Positive | Auth | Compute/Publish with status permission → success | 200 | test_adm_ml_201 | Automated |
| TC-ADMML-N202 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_adm_ml_202 | Automated |
| TC-ADMML-N203 | Negative | Auth | Without create → 403 on store | 403 | test_adm_ml_203 | Automated |
| TC-ADMML-N204 | Negative | Auth | Without update → 403 on update/toggle | 403 | test_adm_ml_204 | Automated |
| TC-ADMML-N205 | Negative | Auth | Without delete → 403 on destroy | 403 | test_adm_ml_205 | Automated |
| TC-ADMML-N206 | Negative | Auth | Without status permission → 403 on compute/publish | 403 | test_adm_ml_206 | Automated |
