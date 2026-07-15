# My Assessments — Requirements & Test-Case List (`bha_MyAssessmentsTcList_Require.md`)

**Module:** BehaviouralAssessment (BHA)
**Feature / Screen:** My Assessments (`08-My-Assessments*`) — the *my-assessments* tab of the Assessments page
**Primary runtime table:** `ba_assessments` (live `ba_` prefix; DDL doc uses stale `bha_` — see **DOC-BA-001**)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController`
**Page controller:** `BaDashboardController::assessmentsPage()`
**FormRequest:** `BaAssessmentRequest`
**Policy:** `BaAssessmentPolicy`
**Audit log:** `ba_audit_log` via `BaAuditLog::log(ENTITY_ASSESSMENT, id, field, old, new)` (entity_type `assessment`)
**CRUD type:** CRUD-transactional Full (create / update / submit / soft-delete / restore / force-delete)
**DB scope:** TENANT-side (database-per-tenant, no `tenant_id` columns)
**Test file:** `bha_MyAssessments_TestCas.php` — **49** methods, single comprehensive Dusk suite
**Filename prefix note:** artifacts keep the `bha_` prefix (module registry); the test **asserts** the live `ba_` table names.

> This list mirrors the existing `bha_MyAssessments_TestCas.php` **1:1** — one row per test method, in file order. Do not renumber; the test file is authoritative.

---

## 1. Business Conditions

### BC-DB — Schema / DDL / model config (Source: DDL / migration `2026_06_16_130617_create_ba_assessments_table`)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-DB-01 | `ba_assessments` exists with columns id, period_id, teacher_id, class_section_id, status, submitted_at, reviewed_by, reviewed_at, reviewer_remarks, is_active, created_by, updated_by, timestamps, deleted_at | DDL-ba_assessments |
| BC-DB-02 | `status` is `ENUM('draft','locked','reviewed','submitted')` — exactly 4 values | DDL / migration |
| BC-DB-03 | Composite unique key `(teacher_id, class_section_id, period_id)` (no `status` in key) | migration |
| BC-DB-04 | `SoftDeletes` — `deleted_at` present; model uses trait | migration / model |
| BC-DB-05 | `ba_audit_log` immutable: `timestamps=false`, **no** `updated_at` / `deleted_at`; `ENTITY_ASSESSMENT='assessment'` | DDL-ba_audit_log |
| BC-DB-06 | Runtime prefix is `ba_` not `bha_`; `bha_assessments` must NOT exist at runtime (**DOC-BA-001**) | DDL / Audit |

### BC-REF — Referential integrity (Source: DDL FKs)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | `period_id → ba_assessment_periods.id` ON DELETE **RESTRICT** | DDL |
| BC-REF-02 | `teacher_id → sch_employees.id` ON DELETE **RESTRICT** | DDL |
| BC-REF-03 | `class_section_id → sch_class_section_jnt.id` ON DELETE **RESTRICT** | DDL |
| BC-REF-04 | `reviewed_by → sch_employees.id` ON DELETE **SET NULL** (distinct FK from teacher) | DDL |

### BC-VAL — Validation (Source: `BaAssessmentRequest` + controller)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-VAL-01 | `period_id` required, integer, `exists:ba_assessment_periods,id` | Request |
| BC-VAL-02 | `class_section_id` required, `exists:sch_class_section_jnt,id` | Request |
| BC-VAL-03 | `teacher_id` nullable but `exists:sch_employees,id` when present | Request |
| BC-VAL-04 | For a non-employee user with no `teacher_id`, controller returns 422 `"An assessor/teacher must be specified."` | Controller |
| BC-VAL-05 | **VAL-BA-MYA-004** — Req-08 requires 100%-completion before submit; `submit()` gates only on `status==='draft'` (no completion check) | Req-08 / Audit |

### BC-AUTH — Authorization (Source: `BaAssessmentPolicy` + controller Gate)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-AUTH-01 | Page gate `tenant.behavioural-assessment.assessments-page.viewAny` | Controller |
| BC-AUTH-02 | `store()` requires `...assessments.create` | Policy |
| BC-AUTH-03 | `submit()`/`update()` require `...assessments.update` | Policy |
| BC-AUTH-04 | `destroy()` requires `...assessments.delete` | Policy |
| BC-AUTH-05 | Policy maps every ability → `tenant.behavioural-assessment.assessments.{viewAny\|view\|create\|update\|delete\|restore\|forceDelete\|status}` | Policy |
| BC-AUTH-06 | **PERM-BA-MYA-003** — `restore()`/`forceDelete()` authorize `.delete`, NOT `.restore`/`.forceDelete` | Controller |
| BC-AUTH-07 | **SEC-BA-002** — `BaAssessmentRequest::authorize()` returns bare `true` (mitigated by controller Gate) | Request |
| BC-AUTH-08 | Guest is redirected to `/login` | middleware |

### BC-BIZ — Business rules (Source: `BaAssessmentController` / page controller)

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-BIZ-01 | `store()` creates a `draft` and writes a `ba_audit_log` `status → draft` row | Controller store |
| BC-BIZ-02 | `store()` is idempotent via `firstOrCreate` — no duplicate draft for same `(teacher,cs,period)` | Controller |
| BC-BIZ-03 | `update()` persists period change on a draft and writes an audit `period_id` row | Controller update |
| BC-BIZ-04 | `details()` returns 200 JSON carrying the assessment id | Controller details |
| BC-BIZ-05 | `status` query filter narrows the my-assessments grid | page controller |
| BC-BIZ-06 | `period_id` query filter is accepted | page controller |
| BC-BIZ-07 | `store()` hardcodes `status='draft'` — hostile `status`/`reviewed_by` mass-assign is ignored | Controller |
| BC-BIZ-08 | **BUG-BA-MYA-001** — `show()` references un-imported `BaStudentRemark` → fatal 500 on "View Summary" | Controller show |
| BC-BIZ-09 | **BUG-BA-MYA-002** — `bulkRate()` uses `DB` facade with no `use` import (source-scan) | Controller |
| BC-BIZ-10 | **BUG-BA-MYA-005** — a pre-existing submitted triple makes `firstOrCreate` miss → insert → unique violation 500 | Controller store |

### BC-SM — State machine (Source: Screen-SM / controller)

State machine: `(none) --store--> draft --submit--> submitted --approve--> reviewed (--sendBack--> draft) --lock--> locked`. MyAssessments (teacher) owns `create(draft)` and `submit(draft→submitted)`; edit/update/destroy are draft-only.

| BC ID | Transition | Source |
|-------|-----------|--------|
| BC-SM-01 | `draft --submit--> submitted` (+ `submitted_at`, + audit row) — legal | Screen-SM-2 |
| BC-SM-02 | `submit()` on a non-draft is rejected (illegal transition, no re-transition) | Screen-SM |
| BC-SM-03 | `edit()` on non-draft → 422 `"Only draft assessments can be edited"` | Controller |
| BC-SM-04 | `update()` on non-draft → 422 `"Only draft assessments can be updated"` | Controller |
| BC-SM-05 | `destroy()` on non-draft → 422 `"Only draft assessments can be deleted"` (post-submission freeze) | Controller |
| BC-SM-06 | Full lifecycle: create → submit → edit blocked | Screen-SM |

### BC-INT / BC-EDG / BC-SEC

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-INT-01 | Soft-delete of a draft moves it to trash (`onlyTrashed` visible, default scope hidden) | Controller |
| BC-INT-02 | Restore from trash returns row to default scope | Controller |
| BC-INT-03 | Force-delete physically removes the row | Controller |
| BC-EDG-01 | `submit()` on an invalid id → 404 | route-model binding |
| BC-EDG-02 | `details`/`edit` on invalid id → 404 | route-model binding |
| BC-EDG-03 | Non-integer `period_id` rejected (422) | Request |
| BC-SEC-01 | Tenant context is initialized for tenant-side tests | tenancy |
| BC-SEC-02 | Cross-tenant direct-ID isolation (defensive; skips if single-tenant) | tenancy |
| BC-SEC-03 | Stored `reviewer_remarks` XSS is escaped by Blade | Blade |

---

## 2. Test Case List (one row per test method — mirrors the file exactly)

Legend — Category: **CFG** config/schema · **POS** positive · **NEG** negative · **SM** state-machine · **DEP-x** dependency sub-cat (B soft-delete, C RESTRICT, D SET NULL, F lifecycle) · **AUTH** permission · **UIX** UI/UX · **EDG** edge · **TEN** tenancy · **SEC** security. `†` = proves a documented defect.

| TC ID | Method (`test_my_assessments_…`) | Category | BC | Source | Expected Result |
|-------|-----------------------------------|----------|----|--------|-----------------|
| TC-01 | `01_migration_model_and_request_configuration_are_correct` | CFG | BC-DB-01..04, BC-VAL-01..03 | DDL/Migration/Request | Table/columns/enum/unique/softDeletes + fillable + relations + request rule strings all correct |
| TC-02 | `02_runtime_table_prefix_diverges_from_ddl_doc_ba_001` † | CFG | BC-DB-06 | DOC-BA-001 | `ba_assessments` exists; `bha_assessments` does not |
| TC-03 | `03_audit_log_table_and_model_configuration_are_correct` | CFG | BC-DB-05 | DDL-ba_audit_log | Audit table immutable; no updated_at/deleted_at; timestamps off |
| TC-10 | `10_store_creates_draft_assessment_and_logs_audit` | POS | BC-BIZ-01 | Controller store | Draft created, is_active, created_by set, audit `status→draft` row |
| TC-11 | `11_store_is_idempotent_via_first_or_create` | POS | BC-BIZ-02 | Controller | Two identical POSTs → exactly 1 row |
| TC-12 | `12_store_without_teacher_returns_422_assessor_required` | NEG | BC-VAL-04 | Controller | 422 `"assessor/teacher must be specified"` |
| TC-13 | `13_assessments_page_renders_my_assessments_tab` | POS/UIX | BC-BIZ-05 | page controller | Tab renders; "Save Assessment" visible |
| TC-14 | `14_update_persists_period_change_and_logs_audit` | POS | BC-BIZ-03 | Controller update | period_id updated, updated_by set, audit `period_id` row |
| TC-15 | `15_details_endpoint_returns_assessment_json` | POS | BC-BIZ-04 | Controller details | 200 JSON with matching id |
| TC-16 | `16_status_filter_narrows_my_assessments_list` | POS/UIX | BC-BIZ-05 | page controller | `status=submitted` shows Submitted badge |
| TC-17 | `17_period_filter_query_is_accepted` | POS/UIX | BC-BIZ-06 | page controller | `period_id` filter accepted; page renders |
| TC-20 | `20_submit_transitions_draft_to_submitted_and_logs` | SM | BC-SM-01 | Screen-SM-2 | draft→submitted, submitted_at stamped, audit row |
| TC-21 | `21_submit_on_non_draft_is_rejected` | SM/NEG | BC-SM-02 | Screen-SM | submitted stays submitted (no re-transition) |
| TC-22 | `22_edit_on_non_draft_returns_422_only_draft` | SM/NEG | BC-SM-03 | Controller | 422 `"Only draft assessments can be edited"` |
| TC-23 | `23_update_on_non_draft_is_rejected` | SM/NEG | BC-SM-04 | Controller | 422 `"Only draft assessments can be updated"`; period unchanged |
| TC-24 | `24_destroy_on_non_draft_is_rejected_post_submission_freeze` | SM/NEG | BC-SM-05 | Controller | 422 `"Only draft assessments can be deleted"`; row survives |
| TC-25 | `25_submit_allowed_below_100_percent_completion_val_ba_mya_004` † | SM/NEG | BC-VAL-05 | Req-08/Audit | 0%-complete draft submits → proves missing completion gate |
| TC-30 | `30_required_fields_are_rejected` | NEG | BC-VAL-01/02 | Request | 422; errors for period_id + class_section_id |
| TC-31 | `31_period_id_must_exist` | NEG | BC-VAL-01 | Request | 422; period_id error |
| TC-32 | `32_class_section_id_must_exist` | NEG | BC-VAL-02 | Request | 422; class_section_id error |
| TC-33 | `33_teacher_id_must_exist_when_present` | NEG | BC-VAL-03 | Request | 422; teacher_id error |
| TC-34 | `34_non_integer_period_is_rejected` | NEG/EDG | BC-EDG-03 | Request | 422; period_id error for `'abc'` |
| TC-35 | `35_second_create_for_submitted_triple_triggers_unique_violation_bug_ba_mya_005` † | NEG | BC-BIZ-10 | Audit | 500 unique violation; no 2nd row |
| TC-40 | `40_soft_delete_moves_draft_to_trash` | DEP-B | BC-INT-01 | Controller | Draft hidden from default scope, present in trash |
| TC-41 | `41_restore_from_trash` | DEP-B | BC-INT-02 | Controller | Restored row back in default scope |
| TC-42 | `42_force_delete_removes_row` | DEP-B | BC-INT-03 | Controller | Row physically removed |
| TC-43 | `43_period_fk_is_restrict_on_delete` | DEP-C | BC-REF-01 | DDL | period FK delete rule RESTRICT/NO ACTION |
| TC-44 | `44_teacher_and_cs_fk_are_restrict` | DEP-C | BC-REF-02/03 | DDL | teacher + cs FK delete rule RESTRICT/NO ACTION |
| TC-45 | `45_reviewed_by_fk_is_set_null` | DEP-D | BC-REF-04 | DDL | reviewed_by FK delete rule SET NULL |
| TC-46 | `46_full_lifecycle_create_submit_then_edit_blocked` | DEP-F | BC-SM-06 | Screen-SM | create→submit→edit blocked (422) |
| TC-47 | `47_show_action_fatals_due_to_unimported_student_remark_bug_ba_mya_001` † | DEP | BC-BIZ-08 | Audit | `show()` → 500 (unimported BaStudentRemark) |
| TC-50 | `50_guest_is_redirected_to_login` | AUTH | BC-AUTH-08 | middleware | Guest → `/login` |
| TC-51 | `51_limited_user_without_create_permission_gets_403` | AUTH | BC-AUTH-02 | Policy | 403 on store |
| TC-52 | `52_limited_user_without_update_permission_gets_403_on_submit` | AUTH | BC-AUTH-03 | Policy | 403 on submit |
| TC-53 | `53_limited_user_without_delete_permission_gets_403_on_destroy` | AUTH | BC-AUTH-04 | Policy | 403 on destroy |
| TC-54 | `54_policy_methods_map_to_permission_strings` | AUTH | BC-AUTH-05 | Policy | Policy contains all 8 gate strings |
| TC-55 | `55_restore_and_force_delete_authorize_delete_not_restore_perm_ba_mya_003` † | AUTH | BC-AUTH-06 | Audit | restore/forceDelete authorize `.delete` gate |
| TC-60 | `60_status_badge_and_actions_render_for_draft_row` | UIX | BC-BIZ-01 | Blade | Draft badge renders |
| TC-61 | `61_empty_state_message_when_no_assessments` | UIX | BC-BIZ-05 | Blade | "No assessments found." shown |
| TC-62 | `62_trash_page_renders` | UIX | BC-INT-01 | Blade | Trash page renders |
| TC-63 | `63_create_modal_present_on_assessments_page` | UIX | BC-BIZ-01 | Blade | `assessmentModal` + "Save Assessment" present |
| TC-70 | `70_submit_on_invalid_id_returns_404` | EDG | BC-EDG-01 | route-model binding | 404 |
| TC-71 | `71_invalid_id_details_and_edit_return_404` | EDG | BC-EDG-02 | route-model binding | 404 for details + edit |
| TC-72 | `72_status_enum_is_limited_to_four_values` | EDG/DB | BC-DB-02 | DDL enum | enum includes draft/submitted/reviewed/locked |
| TC-90 | `90_tenant_context_is_initialized` | TEN | BC-SEC-01 | tenancy | tenancy initialized; table present |
| TC-91 | `91_cross_tenant_direct_id_isolation` | TEN | BC-SEC-02 | tenancy | second tenant isolation (skips if single-tenant) |
| TC-92 | `92_form_request_authorize_returns_true_sec_ba_002` † | SEC | BC-AUTH-07 | Audit | `authorize()` returns bare `true` |
| TC-93 | `93_store_cannot_override_status_via_mass_assignment` | SEC | BC-BIZ-07 | Controller | hostile status override ignored (stays draft) |
| TC-94 | `94_reviewer_remarks_xss_is_escaped_on_page` | SEC | BC-SEC-03 | Blade | `<script>` not present raw in page source |

**Total: 49 test methods.**

---

## 3. Test Method Index (band map)

| Band | Range | Category | Methods |
|------|-------|----------|---------|
| 01–09 | 01,02,03 | Schema / DDL / model / request config | 3 |
| 10–19 | 10–17 | Business rules (BC-BIZ) | 8 |
| 20–29 | 20–25 | State machine (BC-SM) | 6 |
| 30–39 | 30–35 | Validation + error messages (BC-VAL) | 6 |
| 40–49 | 40–47 | Integration / FK dependency (BC-INT/REF) | 8 |
| 50–59 | 50–55 | Permissions / authorization (BC-AUTH) | 6 |
| 60–69 | 60–63 | UI/UX | 4 |
| 70–79 | 70–72 | Edge cases (BC-EDG) | 3 |
| 90–99 | 90–94 | Tenancy isolation + security pack | 5 |
| | | **Total** | **49** |

---

## 4. Known Source Defects (proven / documented by this suite)

| ID | Sev | Description | Proving method |
|----|-----|-------------|----------------|
| BUG-BA-MYA-001 | P0 | `show()` references un-imported `BaStudentRemark` → fatal 500 on "View Summary" | `_47` |
| BUG-BA-MYA-002 | P1 | `bulkRate()` uses `DB` facade with no `use Illuminate\Support\Facades\DB` | source-scan (noted `_92`) |
| PERM-BA-MYA-003 | P1 | `restore()`/`forceDelete()` authorize `.delete`, not `.restore`/`.forceDelete` | `_55` |
| VAL-BA-MYA-004 | P1 | `submit()` has no 100%-completion gate (only checks `status==='draft'`) | `_25` |
| BUG-BA-MYA-005 | P1 | `firstOrCreate` keys on `status='draft'`; unique key is `(teacher,cs,period)` → submitted-triple collision 500 | `_35` |
| DOC-BA-001 | Doc | DDL doc prefix `bha_` diverges from live `ba_` | `_02` |
| SEC-BA-002 | Info | FormRequest `authorize()` returns bare `true` (mitigated by controller Gate) | `_92` |
