# Scheduling & Lifecycle — Test Case List & Business Conditions

**Module:** MarksheetGeneration (`MSH`, prefix `msh_`) · **Feature/Screen:** Scheduling & Lifecycle
**Screen file:** `MarksheetGeneration_V2/04-Scheduling-and-Lifecycle.md`
**Primary table:** `msh_marksheet_schedules` · **Secondary:** `msh_schedule_class_jnt`, `msh_subject_practical_configs`, `msh_computation_logs` (immutable audit)
**Combined screen:** `route('marksheet-generation.scheduling.combined')` → `/marksheet-generation/scheduling` (gate `tenant.msh-scheduling.view`)
**Controllers:** `MarksheetScheduleController` (357 ln), `ScheduleClassController`, `SubjectPracticalConfigController`, `MarksheetGenerationController::scheduling()`
**Services:** `MarksheetScheduleService`, `MarksheetScheduleLifecycleService`, `MarksheetComputationService`, `MarksheetConfigService`, `ComputeMarksheetJob`
**DB scope:** tenant-side (`Database: tenant_db`, prefix `msh_`) → tenancy scaffolding required.
**Test style:** browser Dusk (`extends DuskTestCase`, `namespace Tests\Browser;`) — mirrors the golden `csm_SchClass` reference.

> **State machine feature — BC-SM mandatory.** FSM: `DRAFT → (compute) → COMPUTED → (review) → REVIEWED → (publish) → PUBLISHED → (lock) → LOCKED`, plus `PUBLISHED/LOCKED → (unlock, reason) → COMPUTED`.

---

## 1. Business Conditions

### BC-DB — Schema (Source: DDL / migrations)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_marksheet_schedules` has code/name/schedule_date/status_id/is_locked/locked_*/unlock_reason/unlocked_* + audit cols + `deleted_at` | DDL-msh_marksheet_schedules |
| BC-DB-02 | UNIQUE `(academic_session_id, code)` = `uq_msh_ms_session_code` | DDL-msh_marksheet_schedules |
| BC-DB-03 | FK `config_template_id → msh_config_templates` ON DELETE RESTRICT; `academic_session_id → sch_org_academic_sessions_jnt` RESTRICT; `status_id → sys_dropdowns` RESTRICT | DDL-msh_marksheet_schedules |
| BC-DB-04 | `msh_schedule_class_jnt`: UNIQUE `(schedule_id, class_section_id)`; `schedule_id → …schedules` CASCADE; `class_section_id → sch_class_section_jnt` RESTRICT; migration declares `softDeletes()` | DDL-msh_schedule_class_jnt |
| BC-DB-05 | `msh_subject_practical_configs`: UNIQUE `(academic_session_id, class_id, subject_id)`; theory/practical DECIMAL(5,2); `deleted_at` | DDL-msh_subject_practical_configs |
| BC-DB-06 | `msh_computation_logs`: immutable audit, **no `deleted_at`**; `action` ∈ COMPUTE/REVIEW/PUBLISH/UNLOCK/LOCK; `status` runtime uses RUNNING/SUCCESS/PARTIAL/FAILED/BLOCKED | DDL-msh_computation_logs |
| BC-DB-07 | Status table is **`sys_dropdowns`** not `sys_dropdown_table` (stale DDL comment) — DOC-MSH-002 | Audit-DOC-MSH-002 |

### BC-VAL — Validation (Source: FormRequests)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `config_template_id` required·integer·exists:msh_config_templates,id | Screen-VR / MarksheetScheduleRequest |
| BC-VAL-02 | `academic_session_id` required·integer·exists:sch_org_academic_sessions_jnt,id | MarksheetScheduleRequest |
| BC-VAL-03 | `code` required·string·max:50·unique per academic_session (ignore self) | MarksheetScheduleRequest |
| BC-VAL-04 | `name` required·string·max:150 | MarksheetScheduleRequest |
| BC-VAL-05 | `schedule_date` nullable·date | MarksheetScheduleRequest |
| BC-VAL-06 | `status_id` required·integer·exists:sys_dropdowns,id | MarksheetScheduleRequest |
| BC-VAL-07 | `class_section_ids` nullable·array; `.*` integer·exists:sch_class_section_jnt,id | MarksheetScheduleRequest |
| BC-VAL-08 | `unlock_reason` required·string·min:5·max:500 | UnlockMarksheetScheduleRequest |
| BC-VAL-09 | practical `theory_max_marks`/`practical_max_marks` required·numeric·min:0; unique(session,class,subject) | SubjectPracticalConfigRequest |

### BC-AUTH — Authorization (Source: Controller `Gate::authorize` + Policy)
| ID | Ability | Gate | Source |
|----|---------|------|--------|
| BC-AUTH-01 | view combined screen | `tenant.msh-scheduling.view` | Screen-PM / MarksheetGenerationController::scheduling |
| BC-AUTH-02 | view/create/update/delete schedule | `tenant.msh-marksheet-schedule.{view,create,update,delete}` | MarksheetScheduleController |
| BC-AUTH-03 | review / publish / lock / unlock / export | `tenant.msh-marksheet-schedule.{review,publish,lock,unlock,export}` | MarksheetScheduleController + Policy |
| BC-AUTH-04 | compute / precheck | `tenant.msh-marksheet-schedule.update` | MarksheetScheduleController::compute/precheck |
| BC-AUTH-05 | schedule-class / practical-config CRUD | `tenant.msh-schedule-class.*`, `tenant.msh-subject-practical-config.*` | ScheduleClassController / SubjectPracticalConfigController |
| BC-AUTH-06 | **SEC-MSH-003 / D30**: all FormRequests `authorize()=true` (bypass) | — | Audit-SEC-MSH-003 |
| BC-AUTH-07 | **D39-MSH**: no MSH permissions seeded → super-admin-only | — | Audit-D39-MSH |

### BC-BIZ — Business rules / activity log (Source: Controller/Service + Screen)
| ID | Rule | Source |
|----|------|--------|
| BC-BIZ-01 | Create → `activityLog(Stored)` + `created_by`; Update → `Updated`; Delete → soft-delete + `Deleted` | MarksheetScheduleController |
| BC-BIZ-02 | Lifecycle activity events: `Reviewed`, `Published`, `Unlocked`, `Locked`; compute → **`ComputeDispatched`** | MarksheetScheduleController |
| BC-BIZ-03 | Lifecycle audit rows to `msh_computation_logs.action`: REVIEW/PUBLISH/UNLOCK/LOCK (service) + COMPUTE (computation service) | MarksheetScheduleLifecycleService / MarksheetComputationService |
| BC-BIZ-04 | compute() dispatches `ComputeMarksheetJob` (sync when local/queue=sync); computation flips status→COMPUTED on success | MarksheetScheduleController::compute / MarksheetComputationService |
| BC-BIZ-05 | practical/ schedule-class toggleStatus → `Toggled`; restore → `Restored` | ScheduleClassController / SubjectPracticalConfigController |

### BC-SM — State machine (Source: Screen-SM / MarksheetScheduleLifecycleService)
| ID | State → Trigger → Next | Rule | Source |
|----|----------------------|------|--------|
| BC-SM-01 | DRAFT → compute → (COMPUTED) | compute only checks `is_locked` (not FSM) — dispatches job | Screen-SM-1 / controller |
| BC-SM-02 | COMPUTED → review → REVIEWED | else `DomainException('Only COMPUTED schedules can be reviewed.')` | Screen-SM-2 / service.review |
| BC-SM-03 | REVIEWED → publish → PUBLISHED (+ template `is_locked=1`, BR-MSH-037) | else `Only REVIEWED schedules can be published.` | Screen-SM-3 / service.publish |
| BC-SM-04 | PUBLISHED → lock → LOCKED (`is_locked=1`) | else `Only PUBLISHED schedules can be locked.` | Screen-SM-4 / service.lock |
| BC-SM-05 | PUBLISHED/LOCKED → unlock(reason) → COMPUTED (`is_locked=0`, reason audited, BR-MSH-039) | unlock() does NOT check current state; reason required | Screen-SM-5 / service.unlock |
| BC-SM-06 | Illegal: DRAFT → review rejected | no status change, no REVIEW log | Screen-SM / service |
| BC-SM-07 | Illegal: COMPUTED/DRAFT → publish rejected | no status change | Screen-SM / service |
| BC-SM-08 | Illegal: REVIEWED → lock rejected | no status change | Screen-SM / service |
| BC-SM-09 | compute blocked when `is_locked=1` (LOCKED) → error flash, no dispatch | early return | controller::compute |

### BC-INT — Integration points (Source: DDL FKs / cross-module reads)
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | precheck() reads StudentPortal `ExamResult`/`QuizQuestResult`, LmsHomework, StudentProfile, TimetableFoundation — **DEP-MSH-001** (pending modules) | Audit-DEP-MSH-001 |
| BC-INT-02 | publish() locks the linked `msh_config_templates` row (cross-entity) — BR-MSH-037 | service.publish |
| BC-INT-03 | schedule delete CASCADEs `msh_schedule_class_jnt` + `msh_computation_logs` | DDL FKs |

### BC-EDG — Edge cases / defects (Source: Audit)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | **BR-MSH-026 (P1)**: compute() checks only `is_locked`, not status FSM → a REVIEWED/PUBLISHED(unlocked) schedule can be recomputed | Audit-BR-MSH-026 |
| BC-EDG-02 | **BR-MSH-027 (P1)**: no concurrent-computation guard (RUNNING log not checked) | Audit-BR-MSH-027 |
| BC-EDG-03 | **BR-MSH-050 (P2)**: weightage sum not validated at compute; precheck shows count only | Audit-BR-MSH-050 |
| BC-EDG-04 | unlock() forces COMPUTED regardless of prior state (no guard) | service.unlock |
| BC-EDG-05 | **PERF-MSH-001 (P1)**: precheck N+1 (~6 queries per class-section) | Audit-PERF-MSH-001 |
| BC-EDG-06 | **PERF-MSH-002 (P2)**: `Schema::hasTable()` ×3 inside compute loop | Audit-PERF-MSH-002 |
| BC-EDG-07 | **PERF-MSH-004 (P3)**: recompute hard-deletes soft-deletable result rows | Audit-PERF-MSH-004 |
| BC-EDG-08 | **BUG-MSH-101 (NEW, P1 — verify in source)**: `ScheduleClass` model omits `SoftDeletes` though migration declares `softDeletes()`; controller `onlyTrashed()` + `MarksheetScheduleService::syncClassSections()` `withTrashed()/restore()` → `BadMethodCallException` on every schedule create/update with class_section_ids and on trash/restore/forceDelete | Traced (SC model + SC controller + service) |

### BC-CFG — Configuration
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Status ids resolved from `sys_dropdowns` key `msh_marksheet_schedules.status_id` (DRAFT..LOCKED) must be seeded | service.statusId |
| BC-CFG-02 | Module must be enabled in `modules_statuses.json` (currently `false`) | Env prereq |

---

## 2. Test Case List

**Columns:** TC ID | Category | BC | Source | Description | Expected | V1 | V2 | Status

### Positive (TC-P)
| TC | BC | Source | Description | Expected | V1 | V2 |
|----|----|--------|-------------|----------|----|----|
| TC-P01 | BC-DB-* | DDL | Schema/model/request truth (3 tables + FSM statuses) | All asserts pass | 01 | 01,02,03 |
| TC-P02 | BC-AUTH-01 | Screen-PM | Combined scheduling page renders tabs | Renders | 02 | 13 |
| TC-P03 | BC-BIZ-01 | Controller | Create persists + Stored + created_by | Row + log | 03 | 10 |
| TC-P04 | BC-BIZ-01 | Controller | Update persists + Updated | Row + log | 07 | 11 |
| TC-P05 | BC-BIZ-01 | Controller | Delete soft-deletes + Deleted | Trashed + log | 08 | 12 |
| TC-P06 | BC-AUTH-02 | Controller | Show page renders + breadcrumb | Renders | 06 | — |
| TC-P07 | BC-VAL-09 | Request | Practical config create + unique | Row + reject dup | 17 | 14,15 |
| TC-P08 | BC-BIZ-04 | Controller | compute() from DRAFT dispatches | ComputeDispatched | — | 17,20 |
| TC-P09 | BC-AUTH-03 | Controller | Export endpoint responds | 200/302/403 | — | 18 |

### State machine (TC-SM)
| TC | BC | Source | Description | Expected | V1 | V2 |
|----|----|--------|-------------|----------|----|----|
| TC-SM01 | BC-SM-02 | Screen-SM-2 | COMPUTED→review→REVIEWED (+REVIEW log) | Status+log | 09 | 21 |
| TC-SM02 | BC-SM-03 | Screen-SM-3 | REVIEWED→publish→PUBLISHED (+template lock) | Status+lock+log | 10 | 22 |
| TC-SM03 | BC-SM-04 | Screen-SM-4 | PUBLISHED→lock→LOCKED (is_locked=1) | Status+log | 11 | 23 |
| TC-SM04 | BC-SM-05 | Screen-SM-5 | unlock(reason)→COMPUTED, is_locked=0, reason audited | Status+reason+log | 12 | 24 |
| TC-SM05 | BC-SM-06 | Screen-SM | Illegal review from DRAFT rejected | No change | 13 | 25 |
| TC-SM06 | BC-SM-07 | Screen-SM | Illegal publish from COMPUTED/DRAFT rejected | No change | 14 | 26 |
| TC-SM07 | BC-SM-08 | Screen-SM | Illegal lock from REVIEWED rejected | No change | — | 27 |
| TC-SM08 | BC-SM-09 | Controller | compute blocked when LOCKED | No dispatch | 15 | 28 |
| TC-SM09 | BC-SM-01 | Controller | DRAFT compute dispatch | ComputeDispatched | — | 20 |

### Negative / validation (TC-N)
| TC | BC | Source | Description | Expected | V1 | V2 |
|----|----|--------|-------------|----------|----|----|
| TC-N01 | BC-VAL-01..06 | Request | Required fields block create | Not created | 04 | 30 |
| TC-N02 | BC-DB-02 | DDL | Duplicate (session,code) blocked; diff session allowed | Reject / allow | 05 | 31 |
| TC-N03 | BC-VAL-03 | Request | code max:50 rule | Present | — | 32 |
| TC-N04 | BC-VAL-04 | Request | name max:150 rule | Present | — | 33 |
| TC-N05 | BC-VAL-01/02/06/07 | Request | FK exists rules present | Present | — | 34 |
| TC-N06 | BC-VAL-08 | Request | unlock_reason min:5 rejected | Stays PUBLISHED/locked | — | 35 |
| TC-N07 | BC-VAL-09 | Request | practical numeric min:0 rules | Present | — | 36 |
| TC-N08 | BC-VAL-05 | Request | schedule_date nullable date | Null accepted | — | 37 |
| TC-N09 | BC-SEC | Security | XSS in name escaped on render | Escaped | — | 38 |
| TC-N10 | BC-VAL-03 | Request | whitespace-only code not accepted | Not created | — | 75 |

### Dependency / integration (TC-D)
| TC | Sub | BC | Source | Description | Expected | V1 | V2 |
|----|-----|----|--------|-------------|----------|----|----|
| TC-D01 | C | BC-DB-03 | DDL | config_template FK RESTRICT | Delete blocked | — | 40 |
| TC-D02 | C | BC-DB-03 | DDL | status_id FK → sys_dropdowns | Migration asserts | — | 41 |
| TC-D03 | B | BC-INT-03 | DDL | schedule delete CASCADEs junction | Rows removed | — | 42 |
| TC-D04 | E | BC-INT-01 | Audit-DEP-MSH-001 | precheck cross-module guarded | Skips if absent | 16 | 44 |
| TC-D05 | E | BC-INT-02 | service | publish locks linked template | is_locked=1 | 10 | 22 |
| TC-D06 | F | BC-EDG-07 | Audit-PERF-MSH-004 | recompute wipes previous results | Documented | — | 45 |
| TC-D07 | G | BC-EDG-02 | Audit-BR-MSH-027 | concurrent compute not guarded | Dispatches anyway | — | 71 |

### Permissions (TC-AUTH)
| TC | BC | Source | Description | Expected | V1 | V2 |
|----|----|--------|-------------|----------|----|----|
| TC-A01 | BC-AUTH-01 | Controller | Guest redirected to /login | Redirect | — | 50 |
| TC-A02 | BC-AUTH-02 | Policy | Limited user denied on show | 403/302 | — | 51 |
| TC-A03 | BC-AUTH-06 | Audit-SEC-MSH-003 | FormRequests authorize()=true | Confirmed | 01 | 52 |
| TC-A04 | BC-AUTH-03 | Controller | Lifecycle gates wired | Present | — | 53 |
| TC-A05 | BC-AUTH-03 | Policy | Policy abilities map to permissions | Present | — | 54 |

### UI / Edge / Security (TC-U / TC-EDG / TC-S / TC-T)
| TC | BC | Source | Description | Expected | V1 | V2 |
|----|----|--------|-------------|----------|----|----|
| TC-U01 | BC-BIZ | UI | Schedules tab search | Renders | — | 60 |
| TC-U02 | BC-BIZ | UI | Pagination (sch_page) | Renders | — | 61 |
| TC-U03 | BC-BIZ | UI | Empty search state | Renders | — | 62 |
| TC-U04 | BC-BIZ | UI | Practical-configs tab | Renders | — | 63 |
| TC-EDG01 | BC-EDG-01 | Audit-BR-MSH-026 | REVIEWED can be recomputed (defect) | Dispatches | — | 29 |
| TC-EDG02 | BC-EDG-04 | service | unlock from DRAFT → COMPUTED | Forced | — | 70 |
| TC-EDG03 | BC-EDG-03 | Audit-BR-MSH-050 | weightage sum not validated | Confirmed | — | 72 |
| TC-EDG04 | BC-EDG-06 | Audit-PERF-MSH-002 | hasTable ×3 in loop | Confirmed | — | 73 |
| TC-EDG05 | BC-EDG-05 | Audit-PERF-MSH-001 | precheck N+1 timing (soft) | Logged | — | 74 |
| TC-EDG06 | BC-EDG-08 | Traced | BUG-MSH-101 ScheduleClass SoftDeletes gap | Confirmed | 18 | 04,16 |
| TC-S01 | BC-SEC | Security | Stored XSS in unlock_reason escaped | Escaped | — | 91 |
| TC-S02 | BC-AUTH | Security | is_locked mass-assignable (note) | Documented | — | 92 |
| TC-T01 | Tenancy | Tenancy | Cross-tenant direct-ID isolation | Not exposed | — | 90 |

---

## 3. Known Source Defects (audit-equivalent — proving tests)
| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| BR-MSH-026 | P1 | compute() checks only is_locked, not FSM status | V2 test_29 |
| BR-MSH-027 | P1 | No concurrent-computation guard | V2 test_71 |
| PERF-MSH-001 | P1 | precheck N+1 (~6 q/class-section) | V2 test_74 (soft) |
| SEC-MSH-003 | P1 | 19/19 FormRequests authorize()=true | V1 test_01 / V2 test_52 |
| D39-MSH | P1 | MSH permissions unseeded | V2 test_54 + Validation Report prereq |
| BR-MSH-050 | P2 | Weightage sum not validated at compute | V2 test_72 |
| PERF-MSH-002 | P2 | Schema::hasTable ×3 in compute loop | V2 test_73 |
| DEP-MSH-001 | P2 | Cross-module StudentPortal import in precheck | V1 test_16 / V2 test_44 (guarded) |
| DOC-MSH-002 | P3 | DDL says sys_dropdown_table; real is sys_dropdowns | V1 test_01 / V2 test_02 |
| PERF-MSH-004 | P3 | Recompute hard-deletes soft-deletable rows | V2 test_45 |
| **BUG-MSH-101** | **P1 (NEW)** | ScheduleClass missing SoftDeletes trait despite migration softDeletes() + controller/service soft-delete calls → runtime BadMethodCallException | V1 test_18 / V2 test_04, test_16 |

---

## 4. V2 Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 01 | schema_truth_for_all_scheduling_tables | TC-P01 | Schema | 01-09 |
| 02 | status_dropdown_rows_exist_on_sys_dropdowns | TC-P01/DOC-MSH-002 | Schema | 01-09 |
| 03 | models_configuration_and_relationships | TC-P01 | Schema | 01-09 |
| 04 | bug_msh_101_scheduleclass_missing_softdeletes | TC-EDG06 | Schema | 01-09 |
| 10 | create_persists_and_logs_stored | TC-P03 | BizRule | 10-19 |
| 11 | update_persists_and_logs_updated | TC-P04 | BizRule | 10-19 |
| 12 | delete_soft_deletes_and_logs_deleted | TC-P05 | BizRule | 10-19 |
| 13 | combined_page_renders_schedule_and_practical_tabs | TC-P02 | BizRule | 10-19 |
| 14 | practical_config_create_and_unique_constraint | TC-P07 | BizRule | 10-19 |
| 15 | practical_config_toggle_status_endpoint | TC-P07 | BizRule | 10-19 |
| 16 | schedule_class_unique_key_and_bug_101_path | TC-EDG06 | BizRule | 10-19 |
| 17 | compute_from_draft_dispatches_and_logs | TC-P08 | BizRule | 10-19 |
| 18 | export_endpoint_downloads_or_authorizes | TC-P09 | BizRule | 10-19 |
| 20 | draft_compute_flips_toward_computed | TC-SM09 | StateMachine | 20-29 |
| 21 | computed_review_to_reviewed | TC-SM01 | StateMachine | 20-29 |
| 22 | reviewed_publish_to_published_and_locks_template | TC-SM02/TC-D05 | StateMachine | 20-29 |
| 23 | published_lock_to_locked_sets_is_locked | TC-SM03 | StateMachine | 20-29 |
| 24 | unlock_with_reason_reverts_to_computed | TC-SM04 | StateMachine | 20-29 |
| 25 | illegal_review_from_draft_rejected | TC-SM05 | StateMachine | 20-29 |
| 26 | illegal_publish_from_computed_rejected | TC-SM06 | StateMachine | 20-29 |
| 27 | illegal_lock_from_reviewed_rejected | TC-SM07 | StateMachine | 20-29 |
| 28 | compute_blocked_when_locked | TC-SM08 | StateMachine | 20-29 |
| 29 | br_msh_026_reviewed_can_be_recomputed_defect | TC-EDG01 | StateMachine | 20-29 |
| 30 | required_fields_block_create | TC-N01 | Validation | 30-39 |
| 31 | duplicate_code_same_session_blocked_diff_session_allowed | TC-N02 | Validation | 30-39 |
| 32 | code_max_50_rule_present | TC-N03 | Validation | 30-39 |
| 33 | name_max_150_rule_present | TC-N04 | Validation | 30-39 |
| 34 | foreign_key_exists_rules_present | TC-N05 | Validation | 30-39 |
| 35 | unlock_reason_min_length_rejected | TC-N06 | Validation | 30-39 |
| 36 | practical_marks_numeric_rules_present | TC-N07 | Validation | 30-39 |
| 37 | schedule_date_is_nullable_date | TC-N08 | Validation | 30-39 |
| 38 | xss_in_name_is_stored_escaped_on_render | TC-N09 | Validation | 30-39 |
| 40 | config_template_fk_restrict_on_delete | TC-D01 | Integration | 40-49 |
| 41 | status_fk_references_sys_dropdowns | TC-D02 | Integration | 40-49 |
| 42 | deleting_schedule_removes_schedule_class_rows | TC-D03 | Integration | 40-49 |
| 43 | computation_log_fk_schedule_cascade | TC-D03 | Integration | 40-49 |
| 44 | precheck_cross_module_reads_guarded | TC-D04 | Integration | 40-49 |
| 45 | recompute_wipes_previous_results_perf_msh_004 | TC-D06 | Integration | 40-49 |
| 50 | guest_is_redirected_to_login | TC-A01 | Auth | 50-59 |
| 51 | view_gate_forbids_limited_user | TC-A02 | Auth | 50-59 |
| 52 | sec_msh_003_formrequests_authorize_true | TC-A03 | Auth | 50-59 |
| 53 | lifecycle_gates_wired_in_controller | TC-A04 | Auth | 50-59 |
| 54 | policy_methods_map_to_permissions | TC-A05 | Auth | 50-59 |
| 60 | schedules_tab_search_renders | TC-U01 | UI/UX | 60-69 |
| 61 | schedules_tab_paginates | TC-U02 | UI/UX | 60-69 |
| 62 | empty_search_renders_gracefully | TC-U03 | UI/UX | 60-69 |
| 63 | practical_configs_tab_renders | TC-U04 | UI/UX | 60-69 |
| 70 | unlock_from_draft_still_forces_computed | TC-EDG02 | Edge | 70-79 |
| 71 | br_msh_027_concurrent_compute_not_guarded_defect | TC-D07 | Edge | 70-79 |
| 72 | br_msh_050_weightage_sum_not_validated_at_compute | TC-EDG03 | Edge | 70-79 |
| 73 | perf_msh_002_schema_hastable_in_compute_loop | TC-EDG04 | Edge | 70-79 |
| 74 | perf_msh_001_precheck_n_plus_1_timing_soft | TC-EDG05 | Edge | 70-79 |
| 75 | whitespace_only_code_is_not_a_valid_schedule | TC-N10 | Edge | 70-79 |
| 90 | cross_tenant_direct_id_is_isolated | TC-T01 | Tenancy | 90-99 |
| 91 | stored_xss_in_unlock_reason_is_escaped | TC-S01 | Security | 90-99 |
| 92 | is_locked_is_fillable_mass_assignment_note | TC-S02 | Security | 90-99 |
