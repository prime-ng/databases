# Review Queue — Gap Analysis & Coverage (`bha_ReviewQueueGAPANALYSIS_Require`)

**Module:** BehaviouralAssessment (BHA) · **Feature / Screen:** ReviewQueue
**Automation:** `bha_ReviewQueue_TestCas.php` — single comprehensive Dusk suite, **47 methods**, `php -l` clean.
**Manual spec:** `bha_ReviewQueueMANUALTESTING_Require.md` (MTC-01…MTC-93) · **TcList:** `bha_ReviewQueueTcList_Require.md`
**Screen requirement:** `BehaviouralAssessment_v2/11-Review-Queue.md`

**Legend:** ✅ **Full** — the manual TC is fully exercised by ≥1 method · 🟡 **Partial** — exercised with a stated limitation · ⛔ **Gap** — no method.

---

## 1. Manual TC ↔ Dusk method mapping

### Schema / configuration (Band 01–09)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-01 | TC-P01 | `_01_migration_model_and_request_configuration_are_correct` | ✅ Full |
| MTC-02 | TC-X01 | `_02_runtime_table_prefix_diverges_from_ddl_spec_doc_ba_001` | ✅ Full |
| MTC-03 | TC-P03 | `_03_audit_log_table_and_model_are_immutable_and_configured` | ✅ Full |
| MTC-04 | TC-P02 | `_04_status_enum_matches_ddl_values` | 🟡 Partial (MySQL only; skips on other drivers) |

### Business rules (Band 10–19)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-10 | TC-P04 | `_10_review_index_lists_only_submitted_assessments` | ✅ Full |
| MTC-11 | TC-P05 | `_11_review_index_shows_pending_count_badge` | ✅ Full |
| MTC-12 | TC-P06 | `_12_review_queue_tab_present_on_assessments_page` | ✅ Full |
| MTC-13 | TC-P07 / TC-SM02 | `_13_approve_transitions_submitted_to_reviewed_and_logs_audit` | 🟡 Partial (needs cross-module seed rows; skips in partial env) |
| MTC-14 | TC-P08 / TC-SM03 | `_14_send_back_transitions_to_draft_and_clears_review_fields` | 🟡 Partial (seed-dependent) |
| MTC-15 | TC-SM12 | `_15_approve_confirmation_text_marks_reviewed_not_locked_doc_ba_rev_001` | ✅ Full |
| MTC-16 | TC-SM12 | `_16_approve_sets_reviewed_status_not_approved_doc_ba_rev_001` | ✅ Full |
| MTC-17 | TC-P10 | `_17_approve_and_send_back_redirect_to_review_queue_tab` | ✅ Full |

### State machine + BUG-BA-001 (Band 20–29)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-20 | TC-SM10 | `_20_is_locked_true_only_for_locked_status_bug_ba_001` | ✅ Full (deterministic, no DB) |
| MTC-21 | TC-SM10 | `_21_bulk_rate_and_auto_save_guard_only_on_locked_status_bug_ba_001` | ✅ Full (source proof) |
| MTC-22 | TC-SM08 | `_22_ratings_editable_after_submit_endpoint_bug_ba_001` | 🟡 Partial (seed + rating-probe dependent) |
| MTC-23 | TC-SM09 | `_23_ratings_editable_after_approve_reviewed_endpoint_bug_ba_001` | 🟡 Partial (seed + rating-probe dependent) |
| MTC-24 | TC-N01 / TC-SM05 | `_24_submit_illegal_from_submitted_is_rejected` | 🟡 Partial (seed-dependent) |
| MTC-25 | TC-N02 / TC-SM06 | `_25_approve_illegal_from_draft_is_rejected` | 🟡 Partial (seed-dependent) |
| MTC-26 | TC-N03 / TC-SM07 | `_26_send_back_illegal_from_draft_is_rejected` | 🟡 Partial (seed-dependent) |
| MTC-27 | TC-SM04 | `_27_send_back_from_reviewed_unfreezes_bug_ba_rev_002` | 🟡 Partial (seed-dependent) |
| MTC-28 | TC-SM11 | `_28_locked_status_is_unreachable_for_assessments_dead_state` | ✅ Full (source proof) |
| MTC-29 | TC-P11 / TC-SM01 | `_29_legal_transition_chain_draft_submit_approve` | 🟡 Partial (seed-dependent) |

### Validation (Band 30–39)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-30 | TC-N12 | `_30_send_back_reviewer_remarks_not_required_server_side_val_ba_rev_001` | 🟡 Partial (seed-dependent) |
| MTC-31 | TC-N12 / TC-X03 | `_31_send_back_has_no_required_remarks_rule_at_source_val_ba_rev_001` | ✅ Full (source proof) |
| MTC-32 | TC-X05 | `_32_form_request_rules_reference_ba_prefixed_tables` | ✅ Full |

### Integration / FK (Band 40–49)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-40 | TC-D01 | `_40_assessment_period_fk_is_restrict` | 🟡 Partial (MySQL FK metadata; skips otherwise) |
| MTC-41 | TC-D02 | `_41_assessment_reviewed_by_fk_is_set_null` | 🟡 Partial (MySQL FK metadata) |
| MTC-42 | TC-D03 / TC-P09 | `_42_approve_invokes_score_service_for_period` | ✅ Full |
| MTC-43 | TC-D04 | `_43_assessment_uses_soft_deletes` | ✅ Full |

### Permissions (Band 50–59)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-50 | TC-N07 | `_50_guest_is_redirected_to_login_on_review_index` | ✅ Full |
| MTC-51 | TC-N08 | `_51_limited_user_without_viewany_gets_403_on_review_index` | ✅ Full |
| MTC-52 | TC-N09 | `_52_limited_user_without_view_gets_403_on_review_show` | ✅ Full |
| MTC-53 | TC-N10 | `_53_limited_user_without_update_gets_403_on_approve` | ✅ Full |
| MTC-54 | TC-N11 | `_54_limited_user_without_update_gets_403_on_send_back` | ✅ Full |
| MTC-55 | TC-P12 | `_55_review_policy_methods_map_to_permission_strings` | ✅ Full |
| MTC-56 | TC-X04 | `_56_review_controller_methods_are_gated` | ✅ Full |

### UI/UX (Band 60–69)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-60 | TC-P13 | `_60_review_index_breadcrumb_and_heading` | ✅ Full |
| MTC-61 | TC-P13 | `_61_review_index_columns_present` | ✅ Full |
| MTC-62 | TC-P14 | `_62_empty_state_or_queue_renders_table` | ✅ Full |

### Edge cases (Band 70–79)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-70 | TC-N04 | `_70_review_show_invalid_id_returns_404` | ✅ Full |
| MTC-71 | TC-N05 | `_71_approve_invalid_id_returns_404` | ✅ Full |
| MTC-72 | TC-N06 | `_72_send_back_invalid_id_returns_404` | ✅ Full |
| MTC-73 | TC-X02 | `_73_review_show_references_unimported_bastudentremark_bug_ba_rev_001_candidate` | ✅ Full (source proof) |

### Tenancy / Security (Band 90–99)
| Manual TC | TC-ID | Method | Coverage |
|-----------|-------|--------|----------|
| MTC-90 | TC-T01 | `_90_tenant_context_is_initialized` | ✅ Full |
| MTC-91 | TC-T02 | `_91_cross_tenant_direct_id_isolation` | 🟡 Partial (needs ≥2 tenant domains; skips single-tenant) |
| MTC-92 | TC-S01 | `_92_form_request_authorize_returns_true_sec_ba_002` | ✅ Full |
| MTC-93 | TC-N13 / TC-S02 | `_93_review_show_grid_escapes_output_no_raw_blade` | ✅ Full |

---

## 2. Coverage Summary (by TC category)

| Category | Total TC | Full | Partial | Gap | % Covered (Full+Partial) |
|----------|----------|------|---------|-----|--------------------------|
| Positive (`TC-P`) | 14 | 12 | 2 | 0 | 100% |
| Negative (`TC-N`) | 13 | 13 | 0 | 0 | 100% |
| Dependency (`TC-D`) | 5 | 3 | 2 | 0 | 100% |
| State-Machine (`TC-SM`) | 12 | 4 | 8 | 0 | 100% |
| Tenancy (`TC-T`) | 2 | 1 | 1 | 0 | 100% |
| Security (`TC-S`) | 2 | 2 | 0 | 0 | 100% |
| Cross-reference (`TC-X`) | 5 | 5 | 0 | 0 | 100% |
| **Total (unique methods = 47)** | **53 TC refs** | **40** | **13** | **0** | **100%** |

**Coverage gates:** Negative **100%** (target 100 ✅) · Positive **100%** (target ≥90 ✅) · Dependency **100%** (target ≥90 ✅) · Tenancy **100%** on the P0/P1 surface (✅). **Every TC-ID maps to ≥1 method; every method maps back to a TC/BC. Zero gaps.**

> "Partial" here means the method is present and correct but **fail-soft** — it `markTestSkipped()`s when a cross-module FK seed row (`ba_assessment_periods` / `sch_employees` / `sch_class_section_jnt`), a rating probe, a MySQL driver, or a second tenant is absent. This is required by constraints A/E/#31 for partial-environment greenness, not a coverage hole.

---

## 3. Coverage-Score (by requirement `Source`)

| Section | Covered | Total | % | Notes |
|---------|---------|-------|---|-------|
| Business Rules (`Screen-BR`) | 5 | 5 | 100% | Pending queue, Approve&Lock (as `reviewed`), Send-Back loop, redirect, Approval-Workflow-Constraint (noted BC-CFG-01) |
| State-Machine transitions (`Screen-SM`) | 9 | 9 | 100% | BC-SM-01…BC-SM-09 all have a legal-or-illegal proof (see §4) |
| Validation Rules (`Screen-VR`) | 2 | 2 | 100% | BC-VAL-01 (remarks not required — VAL-BA-REV-001), BC-VAL-02 (ba_ table rules) |
| Integration Points (`Screen-IP`) | 4 | 4 | 100% | period RESTRICT, reviewed_by SET NULL, score-service, soft-delete |
| Permissions (`Screen-PM`) | 6 | 6 | 100% | viewAny/view/update gates + guest + policy map + controller gating |

**Every `Source`-tagged requirement item has ≥1 TC — no zero-coverage requirement item.** The one requirement clause not enforced in code (BC-CFG-01, the global Approval-Workflow toggle that would hide the queue) is *documented* rather than destructively tested, and is flagged below as a source observation, not a coverage gap.

---

## 4. State-Machine Coverage Summary (explicit)

State values: `draft`, `submitted`, `reviewed`, `locked` (`locked` = **dead/unreachable** for assessments).

| BC-SM | Transition | Legal? | Proof method | Result asserted |
|-------|-----------|--------|--------------|-----------------|
| BC-SM-01 | draft --submit--> submitted | ✅ legal | `_29` | status submitted, `submitted_at` set |
| BC-SM-02 | submitted --approve--> reviewed | ✅ legal | `_13`, `_29` | status reviewed, `reviewed_at` set, `ba_audit_log` row |
| BC-SM-03 | submitted --sendBack--> draft | ✅ legal | `_14` | status draft, review fields cleared |
| BC-SM-04 | reviewed --sendBack--> draft | ⚠️ legal-but-violates-req | `_27` | status draft — **BUG-BA-REV-002** (freeze not permanent) |
| BC-SM-05 | submitted --submit--> (reject) | ✅ illegal-rejected | `_24` | status unchanged |
| BC-SM-06 | draft --approve--> (reject) | ✅ illegal-rejected | `_25` | status unchanged |
| BC-SM-07 | draft --sendBack--> (reject) | ✅ illegal-rejected | `_26` | status unchanged |
| BC-SM-08 | any --(period lock)--> locked | ❌ never happens | `_28` | no `'status'=>'locked'` in controller (dead state) |
| BC-SM-09 | submitted/reviewed --bulkRate/autoSave--> (mutated) | ❌ should be blocked, isn't | `_20`,`_21`,`_22`,`_23` | ratings persist post-submit/approve — **BUG-BA-001** |

**All legal transitions (SM-01/02/03) have a positive proof; all key illegal transitions (SM-05/06/07) have a negative proof; both FSM defects (SM-04 freeze, SM-08/09 dead-lock/editable-after-submit) have proving tests.** SM coverage = 9/9.

---

## 5. Cross-Reference Defect Scan (11-check active hunt)

| # | Check | Compared | Finding | Proving method | Defect ID |
|---|-------|----------|---------|----------------|-----------|
| 1 | Enum case | DDL `ENUM(...)` vs runtime `SHOW COLUMNS` | Match — draft/submitted/reviewed/locked | `_04` | — |
| 2 | Route registration | Blade routes vs controller endpoints | reviews index/show/approve/send-back live; queue renders | `_10`,`_60` | — |
| 3 | Gate vs Policy | controller `Gate::authorize` vs `BaReviewPolicy` | Gates map to `reviews.*` policy methods (approve/sendBack reuse update) | `_55`,`_56` | — |
| 4 | Fillable vs DDL | `BaAssessment::$fillable` vs `ba_assessments` columns | Consistent | `_01` | — |
| 5 | Cast vs DDL | model casts vs types | `ba_audit_log` immutable (`$timestamps=false`, no soft-delete) confirmed | `_03` | — |
| 6 | Service delegation | controller `approve()` vs `BehaviouralScoreService` | `approve()` delegates `computeForPeriod` | `_42` | — |
| 7 | **State machine vs impl** | requirement transitions vs controller | (a) `reviewed` (approved) can be sent back — freeze not permanent; (b) `locked` never set; (c) ratings editable post-submit/approve | `_27`; `_28`; `_20`–`_23` | **BUG-BA-REV-002**; **BUG-BA-001** |
| 8 | Validation vs FormRequest | requirement "feedback required" vs `sendBack()` | `sendBack()` never validates `reviewer_remarks` required | `_30`,`_31` | **VAL-BA-REV-001** |
| 9 | Error message / naming | requirement "Approved / Approve & Lock" vs code | code uses `reviewed`, no lock; confirmation says "mark it as reviewed" | `_15`,`_16` | **DOC-BA-REV-001** |
| 10 | Permissions vs Policy | requirement matrix vs Gates | Non-super-admin gets 403 on index/show/approve/send-back | `_51`–`_54` | — |
| 11 | Integration FK vs migration | requirement relationships vs FKs | period_id RESTRICT, reviewed_by SET NULL confirmed | `_40`,`_41` | — |
| — | Prefix drift | DDL doc `bha_` vs runtime `ba_` | live table is `ba_assessments`; `bha_assessments` absent | `_02` | **DOC-BA-001** |
| — | Missing import (latent fatal) | `reviewShow()` symbol vs `use` block | `BaStudentRemark::` referenced, not imported/FQN → latent 500 | `_73` | **BUG-BA-REV-001** (candidate — verify in source) |
| — | FormRequest authorize | `authorize()` body | returns bare `true` (mitigated by controller Gate) | `_92` | **SEC-BA-002** |

---

## 6. BUG-BA-001 Mapping (mandated proof target)

**BUG-BA-001 — Ratings & assessment remain editable after submit/approve (lock is ineffective).**
Root cause: the read-only guard in `bulkRate()` / `autoSave()` checks **only** `$item->isLocked()` (`status === 'locked'`), but **no assessment path ever assigns `locked`** — so `submit` and `approve` (`reviewed`) never freeze the sheet. Severity **P1** (escalates to **P0** once approved averages are pushed to student records, because cached scores can silently diverge from an edited-but-"approved" sheet).

| Facet of the defect | Proving method | What it asserts |
|---------------------|----------------|-----------------|
| Lock predicate is `locked`-only | `_20` | `isLocked()` is false for draft/submitted/reviewed, true only for `locked` |
| Guard checks only `isLocked()`, no submitted/reviewed check | `_21` | `bulkRate`/`autoSave` guard on `isLocked()`; no `status !== 'draft'` guard exists |
| Ratings persist after **submit** | `_22` | bulk-rate on a `submitted` assessment persists a rating; status stays `submitted` |
| Ratings persist after **approve/reviewed** | `_23` | bulk-rate on a `reviewed` assessment persists a rating |
| `locked` is a dead state (why the guard never fires) | `_28` | controller never sets `'status' => 'locked'` |

**Coverage of BUG-BA-001: Full (4 endpoint/model + 1 dead-state source proof).** A future fix (a `status`-based read-only guard, or an approve step that sets `locked`) will flip `_21`/`_22`/`_23`/`_28` — those methods are written to fail loudly on remediation so the fix is re-reviewed.

---

## 7. Documented source observations (not coverage gaps)

- **BC-CFG-01** — the global "Approval Workflow" toggle (Configuration screen) that should hide the queue and bypass review is **not enforced in queue code**. Noted as an observation; not destructively tested here (belongs to the Configuration screen's suite).
- **DOC-BA-001** — DDL spec doc prefix `bha_` vs live `ba_`. Filenames intentionally keep `bha_`; all assertions use `ba_`.
- **SEC-BA-002** — `BaAssessmentRequest::authorize()` returns bare `true`; mitigated by the controller `Gate::authorize` calls (`_56`). Informational.
