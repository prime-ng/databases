# Review Queue — Business Conditions & Test Case List (`bha_ReviewQueueTcList_Require`)

**Module:** BehaviouralAssessment (code BHA) · **Feature/Screen:** ReviewQueue
**Screen requirement:** `4-Requirement_Module_wise/2-Module_Requirement_V1/BehaviouralAssessment_v2/11-Review-Queue.md`
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController` (`reviewIndex` / `reviewShow` / `approve` / `sendBack`; plus `submit` / `bulkRate` / `autoSave`)
**Policy:** `BaReviewPolicy` · **Service:** `BehaviouralScoreService::computeForPeriod`
**Primary table:** `ba_assessments` (live `ba_` prefix; DDL doc says `bha_` — DOC-BA-001). Filename prefix kept as `bha_`, test bodies assert `ba_`.
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant). Tenancy scaffolding required.
**Audit sink:** module-local `ba_audit_log` (immutable) via `BaAuditLog::log`, NOT the generic `activity_logs` helper.
**Test file:** `bha_ReviewQueue_TestCas.php` (single comprehensive Dusk suite, 47 methods) · `php -l` clean.

> **This is a WORKFLOW / STATE-MACHINE feature.** The `BC-SM` band is the centre of gravity. The mandated
> proof target is **BUG-BA-001** (ratings/assessment editable after submit/lock).

---

## 1. Business Conditions

### BC-DB — schema / DDL (Source: `DDL-ba_assessments`, migration `2026_06_16_130617`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_assessments` exists with columns id, period_id, teacher_id, class_section_id, status, submitted_at, reviewed_by, reviewed_at, reviewer_remarks, is_active, created_by, updated_by, timestamps, deleted_at | DDL-ba_assessments |
| BC-DB-02 | `status` is `ENUM('draft','submitted','reviewed','locked')` DEFAULT `draft` | DDL-ba_assessments |
| BC-DB-03 | Unique key `uq_ba_assessment (teacher_id, class_section_id, period_id)` | DDL-ba_assessments |
| BC-DB-04 | Model uses `SoftDeletes`; `deleted_at` present | Model BaAssessment |
| BC-DB-05 | Live table prefix is `ba_`; DDL-doc `bha_assessments` must NOT exist (DOC-BA-001) | Audit-DOC-BA-001 |
| BC-DB-06 | `ba_audit_log` is immutable: `$timestamps=false`, no `updated_at`, no `deleted_at`, no SoftDeletes | DDL-ba_audit_log |

### BC-VAL — validation (Source: FormRequest / controller)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `sendBack()` does **not** server-validate `reviewer_remarks` as required (UI marks it required only) | Screen-BR (Send Back Loop), Audit BR-BA-023 |
| BC-VAL-02 | `BaAssessmentRequest` rules reference the live `ba_assessment_periods`, `sch_class_section_jnt`, `sch_employees` | FormRequest |

### BC-AUTH — permissions (Source: `Screen-PM`, Policy, Controller Gates)
| ID | Condition | Permission | Source |
|----|-----------|------------|--------|
| BC-AUTH-01 | View the queue | `tenant.behavioural-assessment.reviews.viewAny` | reviewIndex Gate |
| BC-AUTH-02 | Open a review sheet | `tenant.behavioural-assessment.reviews.view` | reviewShow Gate |
| BC-AUTH-03 | Approve / Send Back | `tenant.behavioural-assessment.reviews.update` | approve/sendBack Gate |
| BC-AUTH-04 | Submit / Enter ratings | `tenant.behavioural-assessment.assessments.update` | submit/bulkRate Gate |
| BC-AUTH-05 | Guest is redirected to `/login` | web+auth middleware | Route stack |
| BC-AUTH-06 | Policy maps every ability to its `reviews.*` permission string (+ approve/sendBack → reviews.update) | BaReviewPolicy |

### BC-BIZ — business rules (Source: `Screen-BR`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Queue lists ONLY assessments with `status = submitted`, ordered by `submitted_at` | Screen-BR (Pending Queue), reviewIndex |
| BC-BIZ-02 | Approve computes/caches behavioural scores for the period (`computeForPeriod`) | Screen-BR (Approved State Freeze), approve() |
| BC-BIZ-03 | Approve/Send Back redirect back to the `review-queue` tab | Controller redirects |
| BC-BIZ-04 | Requirement expects Approve→`Approved` + permanent lock; code sets `reviewed`, no lock (DOC-BA-REV-001) | Screen-BR vs approve() |
| BC-BIZ-05 | Send Back copies feedback + reverts, unlocking the teacher's grid | Screen-BR (Send Back Loop), sendBack() |

### BC-SM — STATE MACHINE (Source: `Screen-SM`, DDL FSM, controller). **Core band.**
State values: `draft`, `submitted`, `reviewed`, `locked` (`locked` unreachable for assessments).

| ID | From | Trigger | To | Guard / Note | Legal? | Source |
|----|------|---------|----|--------------|--------|--------|
| BC-SM-01 | draft | `submit` (POST assessments/{id}/submit) | submitted | only when status==draft; stamps `submitted_at` | ✅ legal | Screen-SM-1 |
| BC-SM-02 | submitted | `approve` (POST reviews/{id}/approve) | reviewed | only when status==submitted; stamps `reviewed_at`, computes scores | ✅ legal | Screen-SM-2 |
| BC-SM-03 | submitted | `sendBack` (POST reviews/{id}/send-back) | draft | clears submitted_at/reviewed_by | ✅ legal | Screen-SM-3 |
| BC-SM-04 | reviewed | `sendBack` | draft | **allowed** — freeze NOT permanent (BUG-BA-REV-002) | ⚠️ legal-but-violates-req | Screen-SM-3 / Audit |
| BC-SM-05 | submitted | `submit` | — | rejected: "Only draft assessments can be submitted." | ✅ illegal-rejected | Screen-SM |
| BC-SM-06 | draft | `approve` | — | rejected: "Only submitted assessments can be approved." | ✅ illegal-rejected | Screen-SM |
| BC-SM-07 | draft | `sendBack` | — | rejected: "Cannot send back this assessment." | ✅ illegal-rejected | Screen-SM |
| BC-SM-08 | any | (period lock / deadline) | — | assessment `status` is NEVER set to `locked` — dead state | ❌ gap (BUG-BA-001) | Audit BUG-BA-001 |
| BC-SM-09 | submitted/reviewed | `bulkRate`/`autoSave` | (ratings mutated) | guard checks only `isLocked()` (`status==='locked'`), which never holds → **ratings stay editable** | ❌ gap (BUG-BA-001) | Audit BUG-BA-001 |

### BC-INT / BC-REF — integration / FK (Source: DDL FKs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `period_id → ba_assessment_periods` ON DELETE RESTRICT | DDL-ba_assessments |
| BC-REF-02 | `teacher_id → sch_employees` RESTRICT; `class_section_id → sch_class_section_jnt` RESTRICT | DDL-ba_assessments |
| BC-REF-03 | `reviewed_by → sch_employees` ON DELETE SET NULL | DDL-ba_assessments |
| BC-INT-01 | Approve delegates to cross-module score service (`BehaviouralScoreService`) | approve() |

### BC-EDG — edge cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Missing review id → 404 on show/approve/send-back (findOrFail after Gate) | Controller |
| BC-EDG-02 | `reviewShow()` references `BaStudentRemark` unimported → latent fatal/500 (BUG-BA-REV-001, candidate) | Source scan |

### BC-CFG
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Approval workflow is globally toggled in Configuration; when disabled the queue is hidden and submissions bypass review (not enforced in queue code — noted) | Screen-BR (Approval Workflow Constraint) |

---

## 2. Test Case List

### Positive (`TC-P`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/04 | DDL | Table + model + relationships + FSM helpers configured | All present | `_01` | ✅ |
| TC-P02 | BC-DB-02 | DDL | status ENUM has draft/submitted/reviewed/locked | Present | `_04` | ✅ |
| TC-P03 | BC-DB-06 | DDL | ba_audit_log immutable | timestamps=false, no updated_at/deleted_at | `_03` | ✅ |
| TC-P04 | BC-BIZ-01 | Screen-BR | Queue filters to submitted + renders heading | "Submitted Assessments Awaiting Review" | `_10` | ✅ |
| TC-P05 | BC-BIZ-01 | Screen | Pending count badge | "pending" shown | `_11` | ✅ |
| TC-P06 | BC-BIZ-03 | Screen | Review-queue tab on assessments page | "Review Queue" shown | `_12` | ✅ |
| TC-P07 | BC-SM-02 | Screen-SM-2 | Approve submitted → reviewed + audit row | status reviewed, reviewed_at set, audit logged | `_13` | ✅ |
| TC-P08 | BC-SM-03 | Screen-SM-3 | Send Back submitted → draft + clears review fields | status draft, submitted_at/reviewed_by null | `_14` | ✅ |
| TC-P09 | BC-INT-01 | approve() | Approve invokes score service | computeForPeriod called | `_42` | ✅ |
| TC-P10 | BC-BIZ-03 | Controller | Redirect to review-queue tab | tab param present | `_17` | ✅ |
| TC-P11 | BC-SM-01/02 | Screen-SM | Legal chain draft→submit→approve | reaches reviewed | `_29` | ✅ |
| TC-P12 | BC-AUTH-06 | Policy | Policy maps permission strings | all reviews.* present | `_55` | ✅ |
| TC-P13 | BC-BIZ (UI) | Blade | Breadcrumb + columns render | Period/Teacher/Class/Submitted | `_60`,`_61` | ✅ |
| TC-P14 | BC-BIZ-01 | Blade | Empty-state or table renders | one of the two | `_62` | ✅ |

### Negative (`TC-N`)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-SM-05 | Screen-SM | submit on submitted rejected | status unchanged | `_24` | ✅ |
| TC-N02 | BC-SM-06 | Screen-SM | approve on draft rejected | status unchanged | `_25` | ✅ |
| TC-N03 | BC-SM-07 | Screen-SM | send-back on draft rejected | status unchanged | `_26` | ✅ |
| TC-N04 | BC-EDG-01 | Controller | show invalid id → 404 | 404 | `_70` | ✅ |
| TC-N05 | BC-EDG-01 | Controller | approve invalid id → 404 | 404 | `_71` | ✅ |
| TC-N06 | BC-EDG-01 | Controller | send-back invalid id → 404 | 404 | `_72` | ✅ |
| TC-N07 | BC-AUTH-05 | Route | Guest → /login | redirect | `_50` | ✅ |
| TC-N08 | BC-AUTH-01 | Policy | Limited user 403 on index | 403 | `_51` | ✅ |
| TC-N09 | BC-AUTH-02 | Policy | Limited user 403 on show | 403 | `_52` | ✅ |
| TC-N10 | BC-AUTH-03 | Policy | Limited user 403 on approve | 403 | `_53` | ✅ |
| TC-N11 | BC-AUTH-03 | Policy | Limited user 403 on send-back | 403 | `_54` | ✅ |
| TC-N12 | BC-VAL-01 | Screen/Audit | send-back empty remarks NOT rejected (VAL-BA-REV-001) | no 422, status→draft | `_30`,`_31` | ✅ |
| TC-N13 | BC-BIZ (XSS) | Security | review grid escapes output | no `{!!` | `_93` | ✅ |

### Dependency (`TC-D`)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D01 | C | BC-REF-01 | DDL | period_id FK RESTRICT | RESTRICT/NO ACTION | `_40` | ✅ |
| TC-D02 | D | BC-REF-03 | DDL | reviewed_by FK SET NULL | SET NULL | `_41` | ✅ |
| TC-D03 | E | BC-INT-01 | Service | approve → score service | method exists + called | `_42` | ✅ |
| TC-D04 | B | BC-DB-04 | Model | soft delete on assessment | trait + column | `_43` | ✅ |
| TC-D05 | F | BC-SM-01/02 | Screen-SM | full legal chain | reviewed | `_29` | ✅ |

### State-Machine (`TC-SM`)  — legal + illegal transitions
| TC ID | BC-SM | Description | Expected | Method | Status |
|-------|-------|-------------|----------|--------|--------|
| TC-SM01 | BC-SM-01 | draft --submit--> submitted | status submitted, submitted_at set | `_29` | ✅ |
| TC-SM02 | BC-SM-02 | submitted --approve--> reviewed | status reviewed, audit row | `_13`,`_29` | ✅ |
| TC-SM03 | BC-SM-03 | submitted --sendBack--> draft | status draft, fields cleared | `_14` | ✅ |
| TC-SM04 | BC-SM-04 | reviewed --sendBack--> draft (freeze not permanent, BUG-BA-REV-002) | status draft | `_27` | ✅ |
| TC-SM05 | BC-SM-05 | submit illegal from submitted | rejected | `_24` | ✅ |
| TC-SM06 | BC-SM-06 | approve illegal from draft | rejected | `_25` | ✅ |
| TC-SM07 | BC-SM-07 | sendBack illegal from draft | rejected | `_26` | ✅ |
| TC-SM08 | BC-SM-09 | **BUG-BA-001** ratings editable after submit | rating persists on submitted | `_22` | ✅ |
| TC-SM09 | BC-SM-09 | **BUG-BA-001** ratings editable after approve (reviewed) | rating persists on reviewed | `_23` | ✅ |
| TC-SM10 | BC-SM-08/09 | **BUG-BA-001** isLocked() true only for `locked`; guard ineffective | model + source proof | `_20`,`_21` | ✅ |
| TC-SM11 | BC-SM-08 | `locked` unreachable for assessments (dead state) | no `'status'=>'locked'` in controller | `_28` | ✅ |
| TC-SM12 | BC-BIZ-04 | Approve sets `reviewed` not `Approved`/`locked` (DOC-BA-REV-001) | source proof | `_15`,`_16` | ✅ |

### Tenancy / Security (`TC-T` / `TC-S`)
| TC ID | BC | Description | Expected | Method | Status |
|-------|----|-------------|----------|--------|--------|
| TC-T01 | Tenancy | Tenant context initialized | true | `_90` | ✅ |
| TC-T02 | Tenancy | Cross-tenant isolation (defensive) | skip if single tenant | `_91` | ✅ |
| TC-S01 | SEC-BA-002 | FormRequest authorize() returns true (mitigated by Gate) | matches | `_92` | ✅ |
| TC-S02 | XSS | Review grid escapes output | no `{!!` | `_93` | ✅ |

### Cross-reference / source-scan proofs
| TC ID | Finding | Description | Method | Status |
|-------|---------|-------------|--------|--------|
| TC-X01 | DOC-BA-001 | live `ba_` vs stale `bha_` | `_02` | ✅ |
| TC-X02 | BUG-BA-REV-001 (candidate) | reviewShow references unimported BaStudentRemark | `_73` | ✅ |
| TC-X03 | VAL-BA-REV-001 | sendBack has no required-remarks rule | `_31` | ✅ |
| TC-X04 | BC-AUTH | review controller methods gated | `_56` | ✅ |
| TC-X05 | BC-VAL-02 | FormRequest references ba_ tables | `_32` | ✅ |

---

## 3. Known Source Defects (audit-equivalent `BUG-BA-###`)

| ID | Severity | Description | Proving test |
|----|----------|-------------|--------------|
| **BUG-BA-001** | P1 (P0 if result-integration on) | Ratings editable after submit/approve; `bulkRate`/`autoSave` guard only on `isLocked()` (`status==='locked'`), never set | `_20`,`_21`,`_22`,`_23` |
| BUG-BA-REV-002 | P2 (workflow) | Approved (`reviewed`) assessment can be sent back to draft — "freeze permanent" not enforced | `_27` |
| VAL-BA-REV-001 | P3 | `sendBack()` does not require `reviewer_remarks` server-side though UI/BR-BA-023 require it | `_30`,`_31` |
| DOC-BA-REV-001 | Doc | Approve sets `reviewed`, no lock; requirement says "Approve & Lock"/`Approved` | `_15`,`_16`,`_28` |
| BUG-BA-REV-001 | P1 (candidate — verify) | `reviewShow()` references unimported `BaStudentRemark` (and `bulkRate` uses unimported `DB` facade) → latent 500 | `_73` |
| DOC-BA-001 | Doc | DDL doc prefix `bha_` vs live `ba_` | `_02` |
| SEC-BA-002 | Info | `BaAssessmentRequest::authorize()` returns bare `true` (mitigated by controller Gate) | `_92` |

---

## 4. Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `_01_migration_model_and_request_configuration_are_correct` | TC-P01 | Schema | 01–09 |
| 2 | `_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | TC-X01 | Schema/Doc | 01–09 |
| 3 | `_03_audit_log_table_and_model_are_immutable_and_configured` | TC-P03 | Schema | 01–09 |
| 4 | `_04_status_enum_matches_ddl_values` | TC-P02 | Schema | 01–09 |
| 5 | `_10_review_index_lists_only_submitted_assessments` | TC-P04 | BizRule | 10–19 |
| 6 | `_11_review_index_shows_pending_count_badge` | TC-P05 | BizRule | 10–19 |
| 7 | `_12_review_queue_tab_present_on_assessments_page` | TC-P06 | BizRule | 10–19 |
| 8 | `_13_approve_transitions_submitted_to_reviewed_and_logs_audit` | TC-P07/TC-SM02 | State | 10–19 |
| 9 | `_14_send_back_transitions_to_draft_and_clears_review_fields` | TC-P08/TC-SM03 | State | 10–19 |
| 10 | `_15_approve_confirmation_text_marks_reviewed_not_locked_doc_ba_rev_001` | TC-SM12 | Doc | 10–19 |
| 11 | `_16_approve_sets_reviewed_status_not_approved_doc_ba_rev_001` | TC-SM12 | Doc | 10–19 |
| 12 | `_17_approve_and_send_back_redirect_to_review_queue_tab` | TC-P10 | BizRule | 10–19 |
| 13 | `_20_is_locked_true_only_for_locked_status_bug_ba_001` | TC-SM10 | State/BUG | 20–29 |
| 14 | `_21_bulk_rate_and_auto_save_guard_only_on_locked_status_bug_ba_001` | TC-SM10 | State/BUG | 20–29 |
| 15 | `_22_ratings_editable_after_submit_endpoint_bug_ba_001` | TC-SM08 | State/BUG | 20–29 |
| 16 | `_23_ratings_editable_after_approve_reviewed_endpoint_bug_ba_001` | TC-SM09 | State/BUG | 20–29 |
| 17 | `_24_submit_illegal_from_submitted_is_rejected` | TC-N01/TC-SM05 | State | 20–29 |
| 18 | `_25_approve_illegal_from_draft_is_rejected` | TC-N02/TC-SM06 | State | 20–29 |
| 19 | `_26_send_back_illegal_from_draft_is_rejected` | TC-N03/TC-SM07 | State | 20–29 |
| 20 | `_27_send_back_from_reviewed_unfreezes_bug_ba_rev_002` | TC-SM04 | State/BUG | 20–29 |
| 21 | `_28_locked_status_is_unreachable_for_assessments_dead_state` | TC-SM11 | State/BUG | 20–29 |
| 22 | `_29_legal_transition_chain_draft_submit_approve` | TC-P11/TC-SM01 | State | 20–29 |
| 23 | `_30_send_back_reviewer_remarks_not_required_server_side_val_ba_rev_001` | TC-N12 | Validation | 30–39 |
| 24 | `_31_send_back_has_no_required_remarks_rule_at_source_val_ba_rev_001` | TC-N12/TC-X03 | Validation | 30–39 |
| 25 | `_32_form_request_rules_reference_ba_prefixed_tables` | TC-X05 | Validation | 30–39 |
| 26 | `_40_assessment_period_fk_is_restrict` | TC-D01 | Integration | 40–49 |
| 27 | `_41_assessment_reviewed_by_fk_is_set_null` | TC-D02 | Integration | 40–49 |
| 28 | `_42_approve_invokes_score_service_for_period` | TC-D03/TC-P09 | Integration | 40–49 |
| 29 | `_43_assessment_uses_soft_deletes` | TC-D04 | Integration | 40–49 |
| 30 | `_50_guest_is_redirected_to_login_on_review_index` | TC-N07 | Auth | 50–59 |
| 31 | `_51_limited_user_without_viewany_gets_403_on_review_index` | TC-N08 | Auth | 50–59 |
| 32 | `_52_limited_user_without_view_gets_403_on_review_show` | TC-N09 | Auth | 50–59 |
| 33 | `_53_limited_user_without_update_gets_403_on_approve` | TC-N10 | Auth | 50–59 |
| 34 | `_54_limited_user_without_update_gets_403_on_send_back` | TC-N11 | Auth | 50–59 |
| 35 | `_55_review_policy_methods_map_to_permission_strings` | TC-P12 | Auth | 50–59 |
| 36 | `_56_review_controller_methods_are_gated` | TC-X04 | Auth | 50–59 |
| 37 | `_60_review_index_breadcrumb_and_heading` | TC-P13 | UI/UX | 60–69 |
| 38 | `_61_review_index_columns_present` | TC-P13 | UI/UX | 60–69 |
| 39 | `_62_empty_state_or_queue_renders_table` | TC-P14 | UI/UX | 60–69 |
| 40 | `_70_review_show_invalid_id_returns_404` | TC-N04 | Edge | 70–79 |
| 41 | `_71_approve_invalid_id_returns_404` | TC-N05 | Edge | 70–79 |
| 42 | `_72_send_back_invalid_id_returns_404` | TC-N06 | Edge | 70–79 |
| 43 | `_73_review_show_references_unimported_bastudentremark_bug_ba_rev_001_candidate` | TC-X02 | Edge/BUG | 70–79 |
| 44 | `_90_tenant_context_is_initialized` | TC-T01 | Tenancy | 90–99 |
| 45 | `_91_cross_tenant_direct_id_isolation` | TC-T02 | Tenancy | 90–99 |
| 46 | `_92_form_request_authorize_returns_true_sec_ba_002` | TC-S01 | Security | 90–99 |
| 47 | `_93_review_show_grid_escapes_output_no_raw_blade` | TC-N13/TC-S02 | Security | 90–99 |
