# AssessmentPeriod — Business Conditions & Test Case List

**Module:** BehaviouralAssessment · **Feature/Screen:** AssessmentPeriod (`06-Periods.md`, screen "Periods")
**Primary table:** `ba_assessment_periods` (child: `ba_assessments` via `period_id`)
**File prefix:** `bha_` (per DDL doc `CREATE TABLE bha_assessment_periods` + inventory). **Live table is `ba_assessment_periods`** — see `DOC-BA-001`.
**App aliases:** route/controller = `assessment-periods` / `BaAssessmentPeriodController` · FormRequest `BaAssessmentPeriodRequest` · **Service in write path:** none (plain Eloquent; `BehaviouralScoreService` only reads).
**Test style:** browser **Dusk** (`extends DuskTestCase`) — matches committed sibling `AssessmentPeriodCrudTest.php`.
**DB scope:** **tenant-side** (DDL header `Database: tenant_db`; migration under `database/migrations/tenant/`).
**Activity log:** none for this feature (flash `->with('success'/'error', …)` only; `ba_audit_log` covers assessment/incident changes, not periods).

> ⚠️ **Prefix / doc discrepancy (`DOC-BA-001`, audit-confirmed):** the DDL doc + inventory label the table `bha_assessment_periods`; the live migration/model/DB use `ba_assessment_periods`. Artifact **file names** keep `bha_`; every **PHP schema assertion** targets the real `ba_` table. DOC-BA-001 proving test asserts `hasTable('ba_assessment_periods')` + `assertFalse(hasTable('bha_assessment_periods'))`.

> ⚠️ **This is a WORKFLOW/FSM feature.** Status enum = `('open','closed','locked')`. The `BC-SM` band (below) enumerates every transition (State→Trigger→Next). The committed sibling test is **stale** on several strings/selectors (wrong migration path, non-existent page texts, capitalised flash, `.lock-btn`/`.unlock-btn`/`.status-switch` selectors that do not exist) — this suite uses the **real** source strings and drives lock/unlock/toggle via the **real endpoints**.

---

## 1. Business Conditions

### BC-DB — Schema / columns / constraints (Source: DDL + live migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_assessment_periods` has `academic_session_id, academic_term_id, name, start_date, end_date, deadline, status, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-bha_assessment_periods |
| BC-DB-02 | `status` = `ENUM('open','closed','locked')` default `open`; live migration declares enum order `['closed','locked','open']` | migration:20 |
| BC-DB-03 | `academic_session_id` NOT NULL (FK RESTRICT); `academic_term_id` nullable (FK SET NULL) | DDL FKs |
| BC-DB-04 | `academic_session_id, name, start_date, end_date, deadline, created_by, updated_by` NOT NULL (DB rejects missing) | DDL |
| BC-DB-05 | `academic_term_id` nullable | DDL |
| BC-DB-06 | Model uses `SoftDeletes`; casts `start_date/end_date/deadline → date`, `is_active → boolean`; fillable includes `status`; scopes `open()`, `active()`; `isLocked()` helper | Model |

### BC-VAL — Validation rules (Source: `BaAssessmentPeriodRequest`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `academic_session_id` required, integer, `exists:sch_org_academic_sessions_jnt,id` | Request:19 |
| BC-VAL-02 | `name` required, string, `max:100` | Request:21 |
| BC-VAL-03 | `end_date` required, date, `after_or_equal:start_date` | Request:23 |
| BC-VAL-04 | `deadline` required, date, `gte:end_date` | Request:24 |
| BC-VAL-05 | `academic_term_id` nullable, integer, `exists:sch_academic_term,id` | Request:20 |
| BC-VAL-06 | `status` nullable, `in:open,closed,locked` — **editable directly on the edit form (FSM back-door)** | Request:26 / Audit-BUG-BA-002 |
| BC-VAL-07 | `prepareForValidation` normalises `academic_term_id` (null when empty) and `is_active` (default true) | Request:30-36 |

### BC-AUTH — Permission gates (Source: Controller `Gate::authorize` + `_periods` `@can`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | All web routes require auth; guest → `/login` | routes |
| BC-AUTH-02 | `viewAny/view/create/update/delete/status/lock/unlock/restore/forceDelete` gated by `tenant.behavioural-assessment.assessment-periods.*` | Controller (every method) |
| BC-AUTH-03 | `BaAssessmentPeriodRequest::authorize()` returns bare `true` — auth deferred to controller gates | Audit-SEC-BA-002 |
| BC-AUTH-04 | User lacking `.create` is blocked (403) from the create screen | Controller@create:27 |
| BC-AUTH-05 | Invalid id on `edit` → `findOrFail` 404 | Controller@edit:57 |

### BC-BIZ — Business behaviour / flash (Source: Controller + Screen)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Create page renders "Academic Context" + "Period Details" + note "New periods always start as Open." + "Save Assessment Period" | create.blade |
| BC-BIZ-02 | Store persists period with `status='open'`; flash `Assessment period created successfully.` | Controller@store:34-46 |
| BC-BIZ-03 | `show()` **redirects to edit**; edit page shows "Period Details" | Controller@show:48-52 |
| BC-BIZ-04 | Update persists, flash `Assessment period updated successfully.` (lowercase "period") | Controller@update:64-73 |
| BC-BIZ-05 | Edit page prefills existing values incl. `status` `<select>` | edit.blade |
| BC-BIZ-06 | Setup → Periods tab lists periods (search by name; status badge) | _periods.blade |
| BC-BIZ-07 | Periods tab filters by `status` (open/closed/locked) | _periods.blade:12-17 |
| BC-BIZ-08 | Trash page shows "Status at Deletion" + "Deleted At"; flash `Assessment period moved to trash.` | trash.blade / Controller@destroy |
| BC-BIZ-09 | When `status='locked'`, the edit form is disabled and the Update button hidden; banner "This period is locked." | edit.blade:22-33,161 |

### BC-SM — State-machine / status lifecycle (State → Trigger → Next State) · **CORE BAND (20–29)**
Status enum `open / closed / locked`. FRD FSM-2 intends `open → closed → locked` with **locked terminal**.
| ID | From | Trigger | To | Legal? | Impl? | Source |
|----|------|---------|----|--------|-------|--------|
| BC-SM-01 | open | `lock()` | locked | ⚠ (skips `closed`) | yes | Controller@lock:147-161 |
| BC-SM-02 | locked | `unlock()` | **closed** | ⚠ mislabeled (should → open) | yes | Controller@unlock:163-177 |
| BC-SM-03 | closed | `lock()` | locked | ❌ illegal (re-lock terminal) | **allowed** | Audit-BUG-BA-002 |
| BC-SM-04 | locked | `lock()` | (blocked) | guard | yes | "Period is already locked." |
| BC-SM-05 | open/closed | `unlock()` | (blocked) | guard | yes | "Period is not locked." |
| BC-SM-06 | any | `update(status=X)` | X | ❌ illegal back-door (no FSM guard) | **allowed** | Audit-BUG-BA-002 / edit.blade select |
| BC-SM-07 | any | `toggleStatus()` | (is_active flip only) | n/a (orthogonal) | yes | Controller@toggleStatus:132-145 |
| BC-SM-08 | open | *(no `close()` action)* | closed | — **UNREACHABLE via lifecycle** | ❌ missing | Audit-BUG-BA-002 |
| BC-SM-09 | (store) | create | open (default) | ✅ | yes | Controller@store:37-41 |
| BC-SM-10 | period | `lock()` | (assessments NOT frozen) | ❌ cascade missing | — | Audit-BUG-BA-001 |

### BC-REF / BC-INT — FK & integration (Source: DDL FKs)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `ba_assessment_periods.academic_session_id` → `sch_org_academic_sessions_jnt.id` `ON DELETE RESTRICT` (`fk_ba_period_session_id`) | migration:29 |
| BC-REF-02 | `academic_term_id` → `sch_academic_term.id` `ON DELETE SET NULL` (`fk_ba_period_term_id`) | migration:31 |
| BC-REF-03 | `academicSession()`/`academicTerm()` belongsTo; `assessments()`/`computedScores()` hasMany (`period_id`) | Model |
| BC-INT-01 | `ba_assessments.period_id` → `ba_assessment_periods.id` `ON DELETE RESTRICT`; destroy() blocks delete when assessments/computedScores exist | DDL / Controller@destroy:80-82 |

### BC-EDG — Edge / boundary
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `start_date == end_date == deadline` accepted (after_or_equal / gte allow equality) | Request:23-24 |
| BC-EDG-02 | Overlapping periods in same session **allowed** — "Chronological Non-Overlapping Rule" not enforced | Screen-BR / VAL-BA-AP-01 |
| BC-EDG-03 | Period `name` free-text; Blade `{{ }}` escapes stored XSS | edit.blade |

### BC-CFG — Tenancy
| ID | Condition | Source |
|----|-----------|--------|
| BC-CFG-01 | Tenant-per-DB; no `tenant_id` column; requires initialized tenant | DDL header |

### Known Source Defects (audit-equivalent — `BUG-BA-###`/`SEC-BA-###`/`VAL-BA-###`)
| ID | Description | Proven by |
|----|-------------|-----------|
| BUG-BA-002 | Period FSM violated — illegal transitions allowed (closed→locked; any→any edit back-door); `open→closed` unreachable via lifecycle | V2 `_25 _26 _27 _28` |
| BUG-BA-001 | Period lock never freezes assessments/ratings (no cascade) | V2 `_29` (source) + `_41` (data, defensive) |
| SEC-BA-002 | `BaAssessmentPeriodRequest::authorize()` returns bare `true` (systemic) | V2 `_52` |
| VAL-BA-AP-01 | Non-overlapping-period rule not enforced (new candidate — verify in source) | V2 `_71` |
| DOC-BA-001 | DDL doc prefix `bha_` vs live `ba_` table | V2 `_01` |

---

## 2. Test Case List

Columns: **TC ID | BC | Source | Description | Expected | V1 | V2 | Status**

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-P01 | BC-DB-01/06 | DDL/migration | Schema+model+softdelete config | Table/cols/casts/relations correct; `ba_` exists, `bha_` not | 01 | 01 | ✅ |
| TC-P02 | BC-DB-05 | DDL | Null academic_term accepted | Saves with null term | 03 | 06 | ✅ |
| TC-P03 | BC-DB-06 | Model | Fillable/relationships/scopes | fillable+scopeOpen/Active | — | 03 | ✅ |
| TC-P04 | BC-DB-05 | DDL | Nullable term (dup layer) | null term persists | — | 06 | ✅ |
| TC-P10 | BC-BIZ-01/02 | Controller | Create page + valid submit | Sections render; row created `status=open` | 10/11 | 10/11/12 | ✅ |
| TC-P11 | BC-SM-09 | Controller | Create defaults status open | new period `status='open'` | 11 | 12 | ✅ |
| TC-P12 | BC-BIZ-03 | Controller | Show redirects to edit | lands on `/edit`, prefilled | 12 | 13 | ✅ |
| TC-P13 | BC-BIZ-04 | Controller | Edit update persists + flash | `Assessment period updated successfully.` | 13 | 14 | ✅ |
| TC-P15 | BC-BIZ-05 | edit.blade | Edit prefills existing values | name value + status select present | — | 15 | ✅ |
| TC-P20 | BC-BIZ-06 | _periods | Setup tab lists period (search) | period name visible | 60 | 60 | ✅ |
| TC-P21 | BC-BIZ-07 | _periods | Status filter | filtered list shows Open period | — | 61 | ✅ |
| TC-P22 | BC-BIZ-08 | trash.blade | Trash lists soft-deleted | "Status at Deletion"/"Deleted At" + name | — | 62 | ✅ |
| TC-P23 | BC-BIZ-09 | edit.blade | Locked edit hides Update button | banner shown, no Update button | — | 63 | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-N01 | BC-DB-04 | DDL | DB rejects missing required | Insert throws 23000 | 02 | 05 | ✅ |
| TC-N02 | BC-VAL-* | Request | FormRequest rule strings present | Literal rules asserted | 30 | 04 | ✅ |
| TC-N10 | BC-VAL-03 | Request | end_date before start rejected | `.alert-danger`, no row | 31 | 31 | ✅ |
| TC-N30 | BC-VAL-01/02 | Request | Required fields blocked at server | `.alert-danger`, no row | — | 30 | ✅ |
| TC-N32 | BC-VAL-04 | Request | deadline < end_date rejected (gte) | `.alert-danger`, no row | — | 32 | ✅ |
| TC-N33 | BC-VAL-02 | Request | name > 100 rejected | `.alert-danger`, no row | — | 33 | ✅ |
| TC-N34 | BC-VAL-01 | Request | invalid academic_session rejected (exists) | `.alert-danger`, no row | — | 34 | ✅ |
| TC-N20 | BUG-BA-002 | Audit | closed→locked re-lock allowed (proof) | status becomes locked | — | 25 | ✅ (proves bug) |
| TC-N21 | BUG-BA-002 | Audit | open→closed unreachable via actions (proof) | open stays open; no close route | — | 26 | ✅ (proves bug) |
| TC-N22 | BUG-BA-002 | Audit | edit back-door illegal transition closed→open (proof) | status→open via edit | — | 27 | ✅ (proves bug) |
| TC-N23 | BUG-BA-002 | Audit | open→closed only via edit back-door (proof) | status→closed via edit | — | 28 | ✅ (proves bug) |
| TC-N24 | BUG-BA-001 | Audit | lock() no cascade to assessments (source proof) | lock body has no `assessments` | — | 29 | ✅ (proves bug) |
| TC-N25 | BUG-BA-001 | Audit | assessment writable under locked period (data proof) | assessment saves + mutable | — | 41 | ✅ (proves bug) |
| TC-N26 | VAL-BA-AP-01 | Screen-BR | overlapping periods allowed (proof) | both periods persist | — | 71 | ✅ (proves gap) |
| TC-S03 | SEC-BA-002 | Audit | authorize() returns true (proof) | authorize()===true | — | 52 | ✅ (proves gap) |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|-----|----|--------|-------------|----------|----|----|--------|
| TC-D01 | F | BC-SM-05 | Controller | Full soft-delete→restore→forceDelete | lifecycle transitions correct | 23 | 43 | ✅ |
| TC-D02 | C | BC-INT-01 | Controller | Destroy blocked when assessments exist | guard predicate true (defensive) | — | 40 | ✅ |
| TC-D03 | E | BC-REF-03 | Model | Belongs to academic session | session id resolves | — | 42 | ✅ |
| TC-D04 | B | BC-SM-05 | Controller | Restore + forceDelete unreferenced | round-trips cleanly | — | 43 | ✅ |
| TC-D08 | G | BC-EDG-01 | Request | Equal start=end=deadline accepted | row created | — | 70 | ✅ |

### State-machine (TC-SM)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-SM-tog | BC-SM-07 | Controller | Toggle is_active (JSON) | `{success,message}`; is_active flips | 20 | 20 | ✅ |
| TC-SM-01 | BC-SM-01 | Controller | **open → locked** (lock, legal) | status becomes locked | 21 | 21 | ✅ |
| TC-SM-02 | BC-SM-02 | Controller | **locked → closed** (unlock, legal-ish) | status becomes closed | 22 | 22 | ✅ |
| TC-SM-04 | BC-SM-04 | Controller | lock already-locked (guard) | stays locked, no crash | — | 23 | ✅ |
| TC-SM-05 | BC-SM-05 | Controller | unlock non-locked (guard) | stays open | — | 24 | ✅ |
| TC-SM-03 | BC-SM-03 | Audit | **closed → locked** (illegal re-lock) | allowed → locked (bug) | — | 25 | ✅ (bug) |
| TC-SM-08 | BC-SM-08 | Audit | **open → closed** unreachable (lifecycle) | no action reaches closed | — | 26 | ✅ (bug) |
| TC-SM-06a | BC-SM-06 | Audit | edit back-door **closed → open** | allowed (bug) | — | 27 | ✅ (bug) |
| TC-SM-06b | BC-SM-06 | Audit | edit back-door **open → closed** | allowed (bug) | — | 28 | ✅ (bug) |
| TC-SM-10 | BC-SM-10 | Audit | lock does not freeze assessments | no cascade (bug) | — | 29/41 | ✅ (bug) |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | V1 | V2 | Status |
|-------|----|--------|-------------|----------|----|----|--------|
| TC-T01 | BC-CFG-01 | DDL | Tenant-scoped, no tenant_id | tenancy initialized, no tenant_id col | 90 | 90 | ✅ |
| TC-S01 | BC-AUTH-01 | routes | Guest redirected (create) | `/login` | 50 | 50 | ✅ |
| TC-S02 | BC-AUTH-01 | routes | Guest redirected (setup) | `/login` | — | 51 | ✅ |
| TC-S04 | BC-AUTH-04 | Controller | Limited user forbidden | 403 / no create form | — | 53 | ✅ (defensive) |
| TC-S05 | BC-EDG-03 | edit.blade | Stored XSS escaped | script not executed | — | 91 | ✅ |
| TC-S06 | BC-AUTH-05 | Controller | Invalid id no edit render | Update button absent | — | 92 | ✅ |

---

## 3. V2 Test Method Index

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_assessment_period_01_schema_and_model_configuration_are_correct | TC-P01/DOC-BA-001 | Schema | 01–09 |
| 2 | test_assessment_period_02_migration_defines_enum_softdelete_and_fks | TC-P01/BC-REF | Schema | 01–09 |
| 3 | test_assessment_period_03_model_fillable_relationships_and_scopes | TC-P03 | Schema | 01–09 |
| 4 | test_assessment_period_04_form_request_rules_contain_expected_constraints | TC-N02 | Validation-cfg | 01–09 |
| 5 | test_assessment_period_05_db_rejects_each_missing_required_field | TC-N01 | Validation | 01–09 |
| 6 | test_assessment_period_06_nullable_academic_term_accepts_null | TC-P02/P04 | Schema | 01–09 |
| 7 | test_assessment_period_10_create_valid_persists_row | TC-P10 | Business | 10–19 |
| 8 | test_assessment_period_11_create_page_shows_sections_and_open_note | TC-P10 | Business | 10–19 |
| 9 | test_assessment_period_12_store_defaults_status_to_open | TC-P11/SM-09 | Business | 10–19 |
| 10 | test_assessment_period_13_show_redirects_to_edit | TC-P12 | Business | 10–19 |
| 11 | test_assessment_period_14_edit_update_persists_and_flashes | TC-P13 | Business | 10–19 |
| 12 | test_assessment_period_15_edit_page_prefills_existing_values | TC-P15 | Business | 10–19 |
| 13 | test_assessment_period_20_toggle_status_endpoint_returns_json_and_flips | TC-SM-tog | State | 20–29 |
| 14 | test_assessment_period_21_lock_open_period_transitions_to_locked | TC-SM-01 | State (legal) | 20–29 |
| 15 | test_assessment_period_22_unlock_locked_period_transitions_to_closed | TC-SM-02 | State (legal) | 20–29 |
| 16 | test_assessment_period_23_lock_already_locked_is_rejected | TC-SM-04 | State (guard) | 20–29 |
| 17 | test_assessment_period_24_unlock_non_locked_is_rejected | TC-SM-05 | State (guard) | 20–29 |
| 18 | test_assessment_period_25_closed_period_can_be_relocked_bug_ba_002 | TC-SM-03/N20 | State (bug) | 20–29 |
| 19 | test_assessment_period_26_open_to_closed_unreachable_via_lifecycle_actions_bug_ba_002 | TC-SM-08/N21 | State (bug) | 20–29 |
| 20 | test_assessment_period_27_edit_form_allows_illegal_status_transition_bug_ba_002 | TC-SM-06a/N22 | State (bug) | 20–29 |
| 21 | test_assessment_period_28_open_to_closed_only_via_edit_backdoor_bug_ba_002 | TC-SM-06b/N23 | State (bug) | 20–29 |
| 22 | test_assessment_period_29_lock_does_not_cascade_freeze_to_assessments_bug_ba_001 | TC-SM-10/N24 | State (bug) | 20–29 |
| 23 | test_assessment_period_30_required_fields_block_insert | TC-N30 | Validation | 30–39 |
| 24 | test_assessment_period_31_end_date_before_start_is_rejected | TC-N10 | Validation | 30–39 |
| 25 | test_assessment_period_32_deadline_before_end_date_is_rejected | TC-N32 | Validation | 30–39 |
| 26 | test_assessment_period_33_name_exceeding_max_is_rejected | TC-N33 | Validation | 30–39 |
| 27 | test_assessment_period_34_invalid_academic_session_is_rejected | TC-N34 | Validation | 30–39 |
| 28 | test_assessment_period_40_destroy_is_blocked_when_assessments_exist | TC-D02 | Integration | 40–49 |
| 29 | test_assessment_period_41_locked_period_assessment_still_writable_bug_ba_001 | TC-N25/SM-10 | Integration (bug) | 40–49 |
| 30 | test_assessment_period_42_belongs_to_academic_session | TC-D03 | Integration | 40–49 |
| 31 | test_assessment_period_43_restore_and_force_delete_when_unreferenced | TC-D01/D04 | Integration | 40–49 |
| 32 | test_assessment_period_50_guest_redirected_to_login_on_create | TC-S01 | Auth | 50–59 |
| 33 | test_assessment_period_51_guest_redirected_to_login_on_setup | TC-S02 | Auth | 50–59 |
| 34 | test_assessment_period_52_form_request_authorize_returns_true_sec_ba_002 | TC-S03 | Auth (gap) | 50–59 |
| 35 | test_assessment_period_53_user_without_permission_is_forbidden | TC-S04 | Auth | 50–59 |
| 36 | test_assessment_period_60_setup_periods_tab_lists_created_period | TC-P20 | UI/UX | 60–69 |
| 37 | test_assessment_period_61_setup_periods_status_filter | TC-P21 | UI/UX | 60–69 |
| 38 | test_assessment_period_62_trash_page_lists_soft_deleted_period | TC-P22 | UI/UX | 60–69 |
| 39 | test_assessment_period_63_locked_period_edit_form_hides_update_button | TC-P23 | UI/UX | 60–69 |
| 40 | test_assessment_period_70_equal_start_end_deadline_dates_are_accepted | TC-D08 | Edge | 70–79 |
| 41 | test_assessment_period_71_overlapping_periods_in_same_session_are_allowed_val_ba_ap_01 | TC-N26 | Edge (bug) | 70–79 |
| 42 | test_assessment_period_90_runs_inside_initialized_tenant | TC-T01 | Tenancy | 90–99 |
| 43 | test_assessment_period_91_stored_xss_in_name_is_escaped | TC-S05 | Security | 90–99 |
| 44 | test_assessment_period_92_invalid_id_does_not_render_edit | TC-S06 | Security | 90–99 |

**Counts:** V1 = 16 methods · V2 = 44 methods · ratio = **2.75×** (≥ 2× gate met).
