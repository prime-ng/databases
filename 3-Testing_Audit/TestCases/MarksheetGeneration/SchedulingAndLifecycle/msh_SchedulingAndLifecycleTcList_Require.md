# MarksheetGeneration — Scheduling & Lifecycle — Test Case List (TcList)

- **Module:** MarksheetGeneration (`MSH`, prefix `msh_`)
- **Screen / Feature:** SchedulingAndLifecycle (`04-Scheduling-and-Lifecycle.md`)
- **Primary table:** `msh_marksheet_schedules` (prefix `msh_` verified against DDL `CREATE TABLE`)
- **Supporting tables:** `msh_schedule_class_jnt`, `msh_subject_practical_configs`, `msh_computation_logs` (immutable audit)
- **Route (combined):** `marksheet-generation.scheduling.combined` → `/marksheet-generation/scheduling`
- **Resource:** `marksheet-schedule` (bound param `{marksheet_schedule}`) + `schedule-class`, `subject-practical-config`
- **Controllers:** `MarksheetScheduleController`, `ScheduleClassController`, `SubjectPracticalConfigController`, `ComputationLogController`
- **Services:** `MarksheetScheduleService`, `MarksheetScheduleLifecycleService` (FSM, `DomainException`), `MarksheetComputationService`
- **DB scope:** tenant-side (`tenant_db`, `msh_*`) → tenancy scaffolding required
- **Test style:** browser Dusk (`Tests\Browser`, `extends DuskTestCase`) — mirrors same-module precedent + golden `csm_SchClass`
- **Test file:** `msh_SchedulingAndLifecycle_TestCas.php` (ONE comprehensive suite, 57 methods)
- **Generated:** 2026-Jul-10

> **VERIFIED SOURCE CORRECTION (supersedes audit DOC-MSH-002).** The audit stated the real status
> table is `sys_dropdowns`. This is **false** for this codebase. The migration
> (`create_msh_marksheet_schedules_table.php:38`) references `sys_dropdown_table`, the FormRequest
> validates `exists:sys_dropdown_table,id`, the `Dropdown` model binds `$table = 'sys_dropdown_table'`,
> `MarksheetComputationService` queries `DB::table('sys_dropdown_table')`, and the only such migration
> is `create_sys_dropdown_table.php`. There is **no** `sys_dropdowns` table. Per HARD-RULE #1 (source
> wins) all assertions use **`sys_dropdown_table`**. The same-module precedent files (V1/V2, now merged
> and superseded by this file) asserted `sys_dropdowns` and would fail `test_01` against the real DB.

---

## 1. Business Conditions

### 1.1 BC-DB — Schema / constraints (Source: `DDL-msh_marksheet_schedules` etc.)

| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `msh_marksheet_schedules` has FSM columns `status_id`, `is_locked`, `locked_at/by`, `unlock_reason`, `unlocked_at/by`, `last_computed_at`, `total_students` + `deleted_at` | DDL-msh_marksheet_schedules |
| BC-DB-02 | Unique key `uq_msh_ms_session_code` on (`academic_session_id`, `code`) | DDL |
| BC-DB-03 | FK `fk_msh_ms_template` → `msh_config_templates` ON DELETE RESTRICT | DDL |
| BC-DB-04 | FK `fk_msh_ms_status` → **`sys_dropdown_table`** ON DELETE RESTRICT (corrected) | DDL + migration:38 |
| BC-DB-05 | `msh_schedule_class_jnt` unique `uq_msh_scj_schedule_class`; FK schedule CASCADE, class_section RESTRICT; has `deleted_at` | DDL |
| BC-DB-06 | `msh_subject_practical_configs` unique `uq_msh_spc_session_class_sub`; `theory_max_marks`/`practical_max_marks` DECIMAL(5,2); has `deleted_at` | DDL |
| BC-DB-07 | `msh_computation_logs` has **no `deleted_at`** — immutable audit; FK schedule CASCADE | DDL + migration |

### 1.2 BC-VAL — Validation rules (Source: FormRequests)

| ID | Rule | Message / behaviour | Source |
|----|------|---------------------|--------|
| BC-VAL-01 | `config_template_id` required·integer·`exists:msh_config_templates,id` | reject invalid | MarksheetScheduleRequest |
| BC-VAL-02 | `academic_session_id` required·integer·`exists:sch_org_academic_sessions_jnt,id` | reject invalid | MarksheetScheduleRequest |
| BC-VAL-03 | `code` required·string·`max:50`·unique per session (`Rule::unique(...)->where(session)->ignore(id)`) | duplicate rejected | MarksheetScheduleRequest |
| BC-VAL-04 | `name` required·string·`max:150` | reject empty/over-length | MarksheetScheduleRequest |
| BC-VAL-05 | `status_id` required·integer·**`exists:sys_dropdown_table,id`** | reject invalid | MarksheetScheduleRequest |
| BC-VAL-06 | `schedule_date` `nullable·date` | null accepted | MarksheetScheduleRequest |
| BC-VAL-07 | `class_section_ids.*` integer·`exists:sch_class_section_jnt,id` | reject invalid | MarksheetScheduleRequest |
| BC-VAL-08 | `unlock_reason` required·string·`min:5`·`max:500` | reject too-short/blank | UnlockMarksheetScheduleRequest |
| BC-VAL-09 | SPC `theory_max_marks`/`practical_max_marks` required·numeric·`min:0` | reject non-numeric/negative | SubjectPracticalConfigRequest |
| BC-VAL-10 | Lifecycle service also enforces `trim(reason) !== ''` before unlock | `DomainException('Unlock reason is required.')` | LifecycleService:92 |

### 1.3 BC-AUTH — Permission gates (Source: Controller `Gate::authorize`)

| ID | Gate | Method | Source |
|----|------|--------|--------|
| BC-AUTH-01 | `tenant.msh-marksheet-schedule.view` | index/show | MarksheetScheduleController |
| BC-AUTH-02 | `tenant.msh-marksheet-schedule.create` | create/store | " |
| BC-AUTH-03 | `tenant.msh-marksheet-schedule.update` | edit/update/precheck/compute | " |
| BC-AUTH-04 | `tenant.msh-marksheet-schedule.delete` | destroy | " |
| BC-AUTH-05 | `tenant.msh-marksheet-schedule.review` | review — **gate present, NO Policy ability** (gap) | Controller vs Policy |
| BC-AUTH-06 | `tenant.msh-marksheet-schedule.publish` | publish | " |
| BC-AUTH-07 | `tenant.msh-marksheet-schedule.lock` | lock | " |
| BC-AUTH-08 | `tenant.msh-marksheet-schedule.unlock` | unlock | " |
| BC-AUTH-09 | `tenant.msh-marksheet-schedule.export` | export | " |
| BC-AUTH-10 | `tenant.msh-schedule-class.{viewAny,view,create,update,delete}` | ScheduleClass | ScheduleClassController |
| BC-AUTH-11 | `tenant.msh-subject-practical-config.{viewAny,view,create,update,delete}` | SPC | SubjectPracticalConfigController |
| BC-AUTH-12 | `tenant.msh-computation-log.view` | log index/show | ComputationLogController |
| BC-AUTH-13 | FormRequests bypass authorization (`authorize(){ return true; }`) — SEC-MSH-003/D30 | mass-assign guard only in fillable | 3× FormRequests |

### 1.4 BC-BIZ — Business behaviour / activity log (Source: Controller/Service)

| ID | Behaviour | Activity event (verbatim) | Source |
|----|-----------|---------------------------|--------|
| BC-BIZ-01 | Create schedule (+ sync class-sections) | `Stored` | store() |
| BC-BIZ-02 | Update schedule | `Updated` | update() |
| BC-BIZ-03 | Soft-delete schedule | `Deleted` | destroy() |
| BC-BIZ-04 | Review transition | `Reviewed` (+ `REVIEW` ComputationLog) | review() |
| BC-BIZ-05 | Publish transition (+ lock template) | `Published` (+ `PUBLISH` log) | publish() |
| BC-BIZ-06 | Lock transition | `Locked` (+ `LOCK` log) | lock() |
| BC-BIZ-07 | Unlock (revert + reason audit) | `Unlocked` (+ `UNLOCK` log, `remarks`=reason) | unlock() |
| BC-BIZ-08 | Compute dispatch | **`ComputeDispatched`** (not in the audit "verbatim" list — real string) | compute() |
| BC-BIZ-09 | SPC/ScheduleClass toggle status | `Toggled` | toggleStatus() |
| BC-BIZ-10 | SPC/ScheduleClass restore | `Restored` | restore() |
| BC-BIZ-11 | Publish locks the linked template (`msh_config_templates.is_locked=1`) — BR-MSH-037 | — | LifecycleService:41 |

### 1.5 BC-SM — State machine (Source: `Screen-SM`, `MarksheetScheduleLifecycleService`)

| ID | State | Trigger | Next state | Guard / effect | Source |
|----|-------|---------|-----------|----------------|--------|
| BC-SM-01 | DRAFT | compute | COMPUTED | only `is_locked=0` (job flips status on success) | compute() + ComputationService:134 |
| BC-SM-02 | COMPUTED | review | REVIEWED | requires status=COMPUTED else `DomainException('Only COMPUTED schedules can be reviewed.')` | LifecycleService:59 |
| BC-SM-03 | REVIEWED | publish | PUBLISHED | requires REVIEWED; locks template | LifecycleService:25 |
| BC-SM-04 | PUBLISHED | lock | LOCKED | requires PUBLISHED; sets `is_locked=1` | LifecycleService:129 |
| BC-SM-05 | (any) | unlock | COMPUTED | requires non-empty reason (min:5); clears `is_locked` | LifecycleService:90 |
| BC-SM-06 | DRAFT | review | ✗ rejected | illegal (not COMPUTED) | LifecycleService:64 |
| BC-SM-07 | COMPUTED/DRAFT | publish | ✗ rejected | illegal (not REVIEWED) | LifecycleService:28 |
| BC-SM-08 | REVIEWED | lock | ✗ rejected | illegal (not PUBLISHED) | LifecycleService:133 |
| BC-SM-09 | LOCKED | compute | ✗ blocked | controller early-return `'Schedule is locked - unlock before recomputing.'` | compute():318 |

### 1.6 BC-INT / BC-REF — Integration & FK (Source: DDL + Controller)

| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | Deleting a referenced `msh_config_templates` row is blocked (RESTRICT) while a schedule references it | DDL |
| BC-REF-02 | Hard-deleting a schedule cascades `msh_schedule_class_jnt` rows | DDL |
| BC-INT-01 | `precheck()` reads pending StudentPortal `ExamResult`/`QuizQuestResult` + LmsHomework — cross-module (DEP-MSH-001) | Controller:23-25,271-291 |
| BC-INT-02 | Compute pipeline reads `std_student_academic_sessions`, `tt_class_requirement_groups`, score readers | ComputationService |

### 1.7 BC-EDG / BC-CFG — Edge & config

| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | unlock() does not validate current status — always forces COMPUTED | LifecycleService:90 |
| BC-EDG-02 | Same `code` under a different session is allowed (unique is per session) | DDL |
| BC-EDG-03 | `is_locked` is mass-assignable (`sometimes|boolean`, in fillable) | FormRequest + model |
| BC-CFG-01 | Status dropdown seeded on `sys_dropdown_table` key `msh_marksheet_schedules.status_id` (DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED) | DDL seeder note |

### 1.8 Known Source Defects (audit-equivalent, mapped by proving tests)

| ID | Sev | Description | Proving test |
|----|-----|-------------|--------------|
| BR-MSH-026 | P1 | `compute()` checks only `is_locked`, NOT the status FSM → a REVIEWED (unlocked) schedule can still be recomputed | test_29 |
| BR-MSH-027 | P1 | No concurrent-computation guard — a RUNNING ComputationLog is not checked before dispatch | test_71 |
| BR-MSH-037 | — | Publish locks the linked template (documented behaviour, proven) | test_22 |
| BR-MSH-039 | — | Unlock requires a reason and audits it in `remarks` (proven) | test_24, test_35 |
| BR-MSH-050 | P2 | Weightage sum not validated at compute time (precheck shows count only) | test_72 |
| PERF-MSH-001 | P1 | `precheck()` N+1 (~6 queries per class-section) | test_74 (soft timing) |
| PERF-MSH-002 | P2 | `Schema::hasTable()` 3× inside compute loop | test_73 |
| PERF-MSH-004 | P3 | `wipePreviousResults()` hard-deletes soft-deletable result rows on recompute | test_45 |
| DEP-MSH-001 | P2 | `precheck()` imports pending StudentPortal models — cross-module fragility | test_44 (guarded) |
| DOC-MSH-002 | P3 | **Corrected:** audit claim `sys_dropdowns` is wrong; real table is `sys_dropdown_table` | test_02, test_04, test_34, test_41 |
| SEC-MSH-003 | P1 | FormRequests `authorize(){ return true; }` (rely on controller gates) | test_52 |
| DOC-MSH-003 | P3 | BRD says unlock reverts to "Draft/Reviewed" but implementation reverts to COMPUTED | test_24 (asserts COMPUTED), Gap Analysis |
| BUG-MSH-101 | P1 | `ScheduleClass` omits `SoftDeletes` though its table has `deleted_at` and controller/service call `onlyTrashed`/`withTrashed` → runtime `BadMethodCallException` on create/update-with-classes | test_05, test_16 |
| REVIEW-GATE-GAP | P2 | Controller authorizes `tenant.msh-marksheet-schedule.review` but `MarksheetSchedulePolicy` defines no `review` ability | test_54 |

---

## 2. Test Case List

### 2.1 Positive (TC-P)

| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-P01 | BC-DB-01..07 | DDL | Schema/columns/unique/immutability truth | all present; logs have no `deleted_at` | test_01 |
| TC-P02 | BC-CFG-01 | DDL | Status dropdown rows on `sys_dropdown_table` | 5 statuses resolve (or skip) | test_02 |
| TC-P03 | BC-DB/model | src | Model config + relationships + casts | SoftDeletes/relations correct | test_03 |
| TC-P04 | BC-VAL-* | FormRequest | Migration + request rule strings verbatim | contains expected strings | test_04 |
| TC-P05 | BC-BIZ-01 | store | Create persists + `Stored` log | row + activity issued_by admin | test_10 |
| TC-P06 | BC-BIZ-02 | update | Update persists + `Updated` log | name changed + activity | test_11 |
| TC-P07 | BC-BIZ-03/DB | destroy | Soft-delete + `Deleted` log | hidden but trashed row exists | test_12 |
| TC-P08 | BC-BIZ | view | Combined page renders schedules + practical tabs | content rendered | test_13 |
| TC-P09 | BC-DB-06 | SPC | SPC create persists | row exists | test_14 |
| TC-P10 | BC-BIZ-09 | toggle | SPC toggleStatus endpoint responds | 200/302/419 | test_15 |
| TC-P11 | BC-BIZ-08/SM-01 | compute | Compute from DRAFT dispatches | `ComputeDispatched` increments | test_17, test_20 |
| TC-P12 | BC-AUTH-09 | export | Export endpoint authorizes/downloads | 200/302/403 | test_18 |
| TC-P13 | BC-SM-02 | review | COMPUTED→REVIEWED + REVIEW log | status + log | test_21 |
| TC-P14 | BC-SM-03/BIZ-11 | publish | REVIEWED→PUBLISHED + template locked | status + template is_locked=1 | test_22 |
| TC-P15 | BC-SM-04 | lock | PUBLISHED→LOCKED + is_locked | status + is_locked=1 + LOCK log | test_23 |
| TC-P16 | BC-SM-05/BIZ-07 | unlock | LOCKED→COMPUTED + reason audit | status + reason + UNLOCK log | test_24 |
| TC-P17 | BC-EDG-02 | DDL | Same code / different session allowed | second row persists | test_31 |
| TC-P18 | BC-VAL-06 | FormRequest | Null `schedule_date` persists | null stored | test_37 |
| TC-P19 | UI | view | search / paginate / empty-search / practical tab | pages render | test_60,61,62,63 |

### 2.2 Negative (TC-N) — target 100%

| TC ID | BC | Source | Description | Expected | Method |
|-------|----|--------|-------------|----------|--------|
| TC-N01 | BC-VAL-01..05 | FormRequest | Empty store payload | not 201; no row | test_30 |
| TC-N02 | BC-VAL-03/DB-02 | DDL | Duplicate (session, code) | rejected (unique) | test_31 |
| TC-N03 | BC-VAL-03 | FormRequest | `code` `max:50` present | rule present | test_32 |
| TC-N04 | BC-VAL-04 | FormRequest | `name` `max:150` present | rule present | test_33 |
| TC-N05 | BC-VAL-01,02,05,07 | FormRequest | FK `exists` rules incl `sys_dropdown_table` | all present | test_34 |
| TC-N06 | BC-VAL-08 | Unlock | Too-short `unlock_reason` rejected | stays PUBLISHED+locked | test_35 |
| TC-N07 | BC-VAL-09 | SPC | Practical numeric `min:0` rules present | present | test_36 |
| TC-N08 | BC-DB-06 | DDL | Duplicate SPC (session,class,subject) | rejected | test_14 |
| TC-N09 | BC-SM-06 | LifecycleService | Illegal review from DRAFT | status unchanged; no REVIEW log | test_25 |
| TC-N10 | BC-SM-07 | LifecycleService | Illegal publish from COMPUTED | unchanged; no PUBLISH log | test_26 |
| TC-N11 | BC-SM-08 | LifecycleService | Illegal lock from REVIEWED | unchanged; no LOCK log | test_27 |
| TC-N12 | BC-SM-09 | compute | Compute blocked when locked | no dispatch | test_28 |
| TC-N13 | Security | render | Stored XSS in name escaped | not present raw | test_38 |
| TC-N14 | Security | render | Stored XSS in unlock_reason escaped | raw stored, escaped render | test_91 |
| TC-N15 | BC-AUTH | guest | Guest redirected to /login | `/login` | test_50 |
| TC-N16 | BC-AUTH-01 | gate | Limited user denied schedule view | 403/302 | test_51 |
| TC-N17 | BC-VAL-03/04 | store | Whitespace-only code/name | not created | test_75 |

### 2.3 Dependency (TC-D) — target ≥90%

| TC ID | Sub | BC | Source | Description | Expected | Method |
|-------|-----|----|--------|-------------|----------|--------|
| TC-D01 | C | BC-REF-01 | DDL | config_template FK RESTRICT blocks delete | blocked | test_40 |
| TC-D02 | — | BC-DB-04 | migration | status FK references `sys_dropdown_table` | asserted | test_41 |
| TC-D03 | B | BC-REF-02 | DDL | Delete schedule cascades junction rows | removed | test_42 |
| TC-D04 | B | BC-DB-07 | DDL | ComputationLog immutable (no SoftDeletes) | trait absent | test_43 |
| TC-D05 | E | BC-INT-01 | Controller | precheck cross-module guarded | render or skip | test_44 |
| TC-D06 | E | PERF-MSH-004 | Service | recompute wipes result tables (hard delete) | source asserts | test_45 |
| TC-D07 | F | BC-SM-01..05 | LifecycleService | Full FSM lifecycle across states | each transition | test_20-24 |
| TC-D08 | G | BR-MSH-027 | compute | Concurrent compute not guarded (RUNNING log) | still dispatches | test_71 |
| TC-D09 | G | BR-MSH-026 | compute | REVIEWED schedule recomputable | still dispatches | test_29 |
| TC-D10 | E | BUG-MSH-101 | model/service | ScheduleClass soft-delete gap path | documented | test_05, test_16 |

### 2.4 State-machine (TC-SM), Tenancy (TC-T), Security/Edge (TC-S/EDG)

| TC ID | BC | Description | Method |
|-------|----|-------------|--------|
| TC-SM-01..05 | BC-SM-01..05 | Every legal transition (compute/review/publish/lock/unlock) | test_20,21,22,23,24 |
| TC-SM-06..09 | BC-SM-06..09 | Key illegal transitions (review/publish/lock/compute-locked) | test_25,26,27,28 |
| TC-T01 | tenancy | Cross-tenant direct-ID isolation (IDOR) | test_90 |
| TC-S01 | SEC-MSH-003 | FormRequests authorize()=true | test_52 |
| TC-S02 | BC-AUTH | Lifecycle gates wired in controller | test_53 |
| TC-S03 | REVIEW-GATE-GAP | Policy abilities present + review gate gap | test_54 |
| TC-EDG-01 | BC-EDG-01 | unlock from DRAFT forces COMPUTED | test_70 |
| TC-EDG-02 | BR-MSH-050 | weightage sum not validated at compute | test_72 |
| TC-EDG-03 | PERF-MSH-002 | Schema::hasTable 3× in compute loop | test_73 |
| TC-EDG-04 | PERF-MSH-001 | precheck timing (soft) | test_74 |
| TC-EDG-05 | BC-EDG-03 | is_locked mass-assignable note | test_92 |

---

## 3. Test Method Index (57 methods, single file)

| # | Method | TC map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_scheduling_01_schema_truth_for_all_scheduling_tables | TC-P01 | Schema | 01-09 |
| 2 | test_scheduling_02_status_dropdown_lives_on_sys_dropdown_table | TC-P02 | Config | 01-09 |
| 3 | test_scheduling_03_models_configuration_and_relationships | TC-P03 | Schema | 01-09 |
| 4 | test_scheduling_04_migration_and_request_rule_strings | TC-P04 | Schema/Val | 01-09 |
| 5 | test_scheduling_05_bug_msh_101_scheduleclass_missing_softdeletes | TC-D10 | Defect | 01-09 |
| 6 | test_scheduling_10_create_persists_and_logs_stored | TC-P05 | BIZ | 10-19 |
| 7 | test_scheduling_11_update_persists_and_logs_updated | TC-P06 | BIZ | 10-19 |
| 8 | test_scheduling_12_delete_soft_deletes_and_logs_deleted | TC-P07 | BIZ | 10-19 |
| 9 | test_scheduling_13_combined_page_renders_schedule_and_practical_tabs | TC-P08 | BIZ/UI | 10-19 |
| 10 | test_scheduling_14_practical_config_create_and_unique_constraint | TC-P09/TC-N08 | BIZ/Val | 10-19 |
| 11 | test_scheduling_15_practical_config_toggle_status_endpoint_logs_toggled | TC-P10 | BIZ | 10-19 |
| 12 | test_scheduling_16_schedule_class_unique_key_and_bug_101_path | TC-D10 | Defect | 10-19 |
| 13 | test_scheduling_17_compute_from_draft_dispatches_and_logs | TC-P11 | BIZ/SM | 10-19 |
| 14 | test_scheduling_18_export_endpoint_authorizes_or_downloads | TC-P12 | BIZ | 10-19 |
| 15 | test_scheduling_20_draft_compute_dispatches | TC-SM-01 | SM | 20-29 |
| 16 | test_scheduling_21_computed_review_to_reviewed | TC-SM-02 | SM | 20-29 |
| 17 | test_scheduling_22_reviewed_publish_to_published_and_locks_template | TC-SM-03/BR-037 | SM | 20-29 |
| 18 | test_scheduling_23_published_lock_to_locked_sets_is_locked | TC-SM-04 | SM | 20-29 |
| 19 | test_scheduling_24_locked_unlock_with_reason_reverts_to_computed | TC-SM-05/BR-039 | SM | 20-29 |
| 20 | test_scheduling_25_illegal_review_from_draft_rejected | TC-N09 | SM- | 20-29 |
| 21 | test_scheduling_26_illegal_publish_from_computed_rejected | TC-N10 | SM- | 20-29 |
| 22 | test_scheduling_27_illegal_lock_from_reviewed_rejected | TC-N11 | SM- | 20-29 |
| 23 | test_scheduling_28_compute_blocked_when_locked | TC-N12 | SM- | 20-29 |
| 24 | test_scheduling_29_br_msh_026_reviewed_schedule_can_be_recomputed_defect | TC-D09/BR-026 | Defect | 20-29 |
| 25 | test_scheduling_30_required_fields_block_create | TC-N01 | Val | 30-39 |
| 26 | test_scheduling_31_duplicate_code_same_session_blocked_diff_session_allowed | TC-N02/TC-P17 | Val | 30-39 |
| 27 | test_scheduling_32_code_max_50_rule_present | TC-N03 | Val | 30-39 |
| 28 | test_scheduling_33_name_max_150_rule_present | TC-N04 | Val | 30-39 |
| 29 | test_scheduling_34_foreign_key_exists_rules_present | TC-N05 | Val | 30-39 |
| 30 | test_scheduling_35_unlock_reason_min_length_rejected | TC-N06 | Val | 30-39 |
| 31 | test_scheduling_36_practical_marks_numeric_rules_present | TC-N07 | Val | 30-39 |
| 32 | test_scheduling_37_schedule_date_is_nullable_date | TC-P18 | Val | 30-39 |
| 33 | test_scheduling_38_xss_in_name_is_stored_escaped_on_render | TC-N13 | Sec | 30-39 |
| 34 | test_scheduling_40_config_template_fk_restrict_on_delete | TC-D01 | FK | 40-49 |
| 35 | test_scheduling_41_status_fk_references_sys_dropdown_table | TC-D02 | FK | 40-49 |
| 36 | test_scheduling_42_deleting_schedule_cascades_schedule_class_rows | TC-D03 | FK | 40-49 |
| 37 | test_scheduling_43_computation_log_is_immutable_no_softdeletes | TC-D04 | FK | 40-49 |
| 38 | test_scheduling_44_precheck_cross_module_reads_guarded | TC-D05 | Integration | 40-49 |
| 39 | test_scheduling_45_recompute_wipes_previous_results_perf_msh_004 | TC-D06 | Integration | 40-49 |
| 40 | test_scheduling_50_guest_is_redirected_to_login | TC-N15 | Auth | 50-59 |
| 41 | test_scheduling_51_view_gate_forbids_limited_user | TC-N16 | Auth | 50-59 |
| 42 | test_scheduling_52_sec_msh_003_formrequests_authorize_true | TC-S01 | Auth | 50-59 |
| 43 | test_scheduling_53_lifecycle_gates_wired_in_controller | TC-S02 | Auth | 50-59 |
| 44 | test_scheduling_54_policy_abilities_present_and_review_gate_gap | TC-S03 | Auth | 50-59 |
| 45 | test_scheduling_60_schedules_tab_search_renders | TC-P19 | UI | 60-69 |
| 46 | test_scheduling_61_schedules_tab_paginates | TC-P19 | UI | 60-69 |
| 47 | test_scheduling_62_empty_search_renders_gracefully | TC-P19 | UI | 60-69 |
| 48 | test_scheduling_63_practical_configs_tab_renders | TC-P19 | UI | 60-69 |
| 49 | test_scheduling_70_unlock_from_draft_still_forces_computed | TC-EDG-01 | Edge | 70-79 |
| 50 | test_scheduling_71_br_msh_027_concurrent_compute_not_guarded_defect | TC-D08/BR-027 | Defect | 70-79 |
| 51 | test_scheduling_72_br_msh_050_weightage_sum_not_validated_at_compute | TC-EDG-02/BR-050 | Defect | 70-79 |
| 52 | test_scheduling_73_perf_msh_002_schema_hastable_in_compute_loop | TC-EDG-03/PERF-002 | Perf | 70-79 |
| 53 | test_scheduling_74_perf_msh_001_precheck_n_plus_1_timing_soft | TC-EDG-04/PERF-001 | Perf | 70-79 |
| 54 | test_scheduling_75_whitespace_only_code_is_not_a_valid_schedule | TC-N17 | Val | 70-79 |
| 55 | test_scheduling_90_cross_tenant_direct_id_is_isolated | TC-T01 | Tenancy | 90-99 |
| 56 | test_scheduling_91_stored_xss_in_unlock_reason_is_escaped | TC-N14 | Sec | 90-99 |
| 57 | test_scheduling_92_is_locked_is_fillable_mass_assignment_note | TC-EDG-05 | Sec | 90-99 |
