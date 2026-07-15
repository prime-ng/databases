# Assessment Period — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (BHA / live prefix `ba_`) · **Feature/Screen:** AssessmentPeriod (screen `06-Periods*`)
**File prefix:** `bha_` (registry/DDL-doc name) · **Real runtime table:** `ba_assessment_periods` (prefix divergence — DOC-BA-001)
**DB scope:** TENANT-side (database-per-tenant, no `tenant_id` columns → tenancy scaffolding emitted)
**Test style:** Browser Dusk (`namespace Tests\Browser`; `extends DuskTestCase`)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentPeriodController` · app alias route base `assessment-periods`
**FormRequest:** `BaAssessmentPeriodRequest` · **Policy:** `BaAssessmentPeriodPolicy` · **Model:** `BaAssessmentPeriod`
**CRUD master:** Full · **Feature class:** WORKFLOW / STATE-MACHINE
**Activity log:** NONE — controller calls no `activityLog()` helper and the model has no observer (documented absence, mirrors RatingScale).
**Screen requirement:** `2-Module_Requirement_V1/BehaviouralAssessment_v2/06-Periods.md`
**Test file:** `bha_AssessmentPeriod_TestCas.php` — **ONE comprehensive file, 59 methods** (no V1/V2 split), method naming `test_period_NN_*`.

---

## 1. Business Conditions

### BC-DB — Schema truth (Source: `DDL-bha_assessment_periods`; live table `ba_assessment_periods`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Runtime table `ba_assessment_periods` exists; DDL-doc name `bha_assessment_periods` does NOT (prefix divergence) | DDL / DOC-BA-001 |
| BC-DB-02 | Columns: id, academic_session_id, academic_term_id, name, start_date, end_date, deadline, status, is_active, created_by, updated_by, created_at, updated_at, deleted_at | DDL |
| BC-DB-03 | `status` ENUM('open','closed','locked') — exactly three lifecycle states | DDL / migration |
| BC-DB-04 | `is_active` TINYINT(1) (soft enable/disable, distinct from status) | DDL |
| BC-DB-05 | `name` VARCHAR(100); `academic_term_id` nullable (independent period) | DDL |
| BC-DB-06 | Model binds `ba_assessment_periods`; fillable = [academic_session_id, academic_term_id, name, start_date, end_date, deadline, status, is_active, created_by, updated_by]; uses SoftDeletes | Model |
| BC-DB-07 | Relationships: `assessments()`/`computedScores()` (HasMany), `academicSession()`/`academicTerm()` (BelongsTo); scopes `open()`/`active()`; helper `isLocked()` | Model |

### BC-VAL — Validation (Source: `BaAssessmentPeriodRequest`)
| ID | Rule | Behaviour | Source |
|----|------|-----------|--------|
| BC-VAL-01 | academic_session_id required, exists:sch_org_academic_sessions_jnt,id | 422 | Req |
| BC-VAL-02 | academic_term_id nullable, exists:sch_academic_term,id | 422 only if present+invalid | Req |
| BC-VAL-03 | name required, max:100 | 422 | Req |
| BC-VAL-04 | start_date required, valid date | 422 | Req |
| BC-VAL-05 | end_date required, date, **after_or_equal:start_date** | 422 if end<start | Req |
| BC-VAL-06 | deadline required, date, **gte:end_date** | 422 if deadline<end | Req |
| BC-VAL-07 | is_active nullable boolean; `prepareForValidation` defaults it true | — | Req |
| BC-VAL-08 | `status` is NOT a rule key → posted status stripped by validated() (edit back-door closed) | ignored | Req |

### BC-AUTH — Permissions (Source: Controller `Gate::authorize` + `BaAssessmentPeriodPolicy`)
| ID | Method | Gate ability (prefix `tenant.behavioural-assessment.assessment-periods.`) | Source |
|----|--------|--------------------------------------------------------------------------|--------|
| BC-AUTH-01 | index / viewAny / trashed | `viewAny` | Ctrl 21,96 |
| BC-AUTH-02 | create / store | `create` | Ctrl 27,36 |
| BC-AUTH-03 | show | `view` | Ctrl 50 |
| BC-AUTH-04 | edit / update | `update` | Ctrl 56,66 |
| BC-AUTH-05 | destroy | `delete` | Ctrl 77 |
| BC-AUTH-06 | restore / forceDelete | `restore` / `forceDelete` | Ctrl 107,118 |
| BC-AUTH-07 | toggleStatus | `status` | Ctrl 134 |
| BC-AUTH-08 | close / reopen / lock / unlock | **dedicated** abilities `close` / `reopen` / `lock` / `unlock` | Ctrl 149,165,181,197 |
| BC-AUTH-09 | guest → /login; super-admin bypasses gates | redirect / bypass | middleware |
| BC-AUTH-10 | FormRequest `authorize()` returns bare `true` (mitigated by controller Gate) → SEC-BA-002 | — | Req |

### BC-BIZ — Business logic (Source: Controller + Screen `06-Periods`)
| ID | Rule | Source |
|----|------|--------|
| BC-BIZ-01 | store() hardcodes status='open'; created_by/updated_by = auth()->id() | Ctrl 38-41 |
| BC-BIZ-02 | update() writes updated_by=auth()->id() (extend-deadline / edit flow) | Ctrl 66-72 |
| BC-BIZ-03 | destroy() blocked if assessments()/computedScores() exist → error flash; else sets is_active=false then soft-deletes | Ctrl 80-91 |
| BC-BIZ-04 | forceDelete() blocked if associations exist (incl. trashed) | Ctrl 121-122 |
| BC-BIZ-05 | toggleStatus() flips is_active; returns JSON {success,is_active,message} | Ctrl 132-145 |
| BC-BIZ-06 | index() redirects to `/setup?tab=periods`; show() redirects to edit | Ctrl |
| BC-BIZ-07 | No activityLog()/observer on periods → no audit-trail rows written | Ctrl (absent) |
| BC-BIZ-08 | created_by/updated_by are server-forced from auth id, NOT mass-assignable from payload | Ctrl / Model |

### BC-SM — State machine (Source: `Screen-SM` / Controller 147-208) — states `open` / `closed` / `locked`
| ID | State | Trigger | Next | Guard flash (on illegal trigger) | Source |
|----|-------|---------|------|----------------------------------|--------|
| BC-SM-01 | (create) | store() | open | — (store forces open) | Ctrl 38 |
| BC-SM-02 | open | close() | closed | "Only open periods can be closed." | Ctrl 152-156 |
| BC-SM-03 | closed | reopen() | open | "Only closed periods can be reopened." | Ctrl 168-172 |
| BC-SM-04 | closed | lock() | locked | "Only closed periods can be locked. Close the period first." | Ctrl 184-188 |
| BC-SM-05 | locked | unlock() | closed | "Period is not locked." | Ctrl 200-204 |
| BC-SM-06 | closed/locked | close() | (blocked, unchanged) | "Only open periods can be closed." | Ctrl 152-153 |
| BC-SM-07 | open/locked | reopen() | (blocked, unchanged) | "Only closed periods can be reopened." | Ctrl 168-169 |
| BC-SM-08 | open/locked | lock() | (blocked, unchanged) | "Only closed periods can be locked. Close the period first." | Ctrl 184-185 |
| BC-SM-09 | open/closed | unlock() | (blocked, unchanged) | "Period is not locked." | Ctrl 200-201 |

> **Legal cycle:** `(create)→open ⇄(close/reopen) closed ⇄(lock/unlock) locked`. There is NO direct `open→locked` (lock requires closed) and NO direct `locked→open` (unlock lands on closed). `unlock` (locked→closed) is an admin override that the DDL/FRD comment marks terminal but the screen requirement + code allow → DOC-BA-002.

### BC-INT / BC-REF — FK & cross-module (Source: migration / DDL)
| ID | FK | Referenced | onDelete | Source |
|----|----|-----------|----------|--------|
| BC-REF-01 | academic_session_id | sch_org_academic_sessions_jnt.id | RESTRICT | migration/DDL |
| BC-REF-02 | academic_term_id | sch_academic_term.id | SET NULL | migration/DDL |
| BC-INT-01 | assessments / computedScores (ba_assessments, ba_computed_scores) block period delete/forceDelete | RESTRICT | Screen "Delete Restrictions" |

### BC-EDG / BC-CFG — Edge & gaps
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | deadline == end_date accepted (gte boundary) | Req |
| BC-EDG-02 | end_date == start_date accepted (after_or_equal boundary) | Req |
| BC-EDG-03 | invalid / non-existent id → 404 (show/edit/toggle/close) | Ctrl route binding |
| BC-EDG-04 | is_active defaults true when omitted (prepareForValidation) | Req |
| BC-EDG-05 | whitespace-only name rejected (Laravel TrimStrings → required fails) | mw/Req |
| BC-EDG-06 | XSS payload in name stored, escaped on render (Blade `{{ }}`) | Blade |
| PER-GAP-01 | Chronological Non-Overlapping Rule NOT enforced — overlapping periods in same session accepted | Screen-BR |
| PER-GAP-02 | Period Name "Unique" (requirement) NOT enforced — FormRequest only max:100, duplicates accepted | Screen-BR |
| PER-GAP-03 | Requirement models boolean "Is Locked"; impl uses 3-state `status` enum + separate `is_active` | Screen vs impl |

---

## 2. Test Case List (one row per test method — mirrors the 59-method `.php` 1:1)

### Schema / config truth (Band 01–09)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-CFG01 | Config | BC-DB-01..07, BC-VAL-* | DDL/Req/Model | Schema, migration, FormRequest rule strings, model config truth | table/columns/enum/fillable/relations/scopes all match | test_period_01 | ✅ |
| TC-CFG02 | Config | BC-DB-01 | DOC-BA-001 | Runtime `ba_` prefix diverges from DDL-doc `bha_` | ba_ exists, bha_ absent, model binds ba_ | test_period_02 | ✅ |
| TC-CFG03 | Config | BC-DB-07 | Model | `open()`/`active()` scopes and `isLocked()` helper behave | scopes filter; isLocked true only for locked | test_period_03 | ✅ |

### Positive / business rules (Band 10–19)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P01 | Positive | BC-BIZ-01 | Ctrl | Create persists status=open + audit cols | open; created_by/updated_by=auth | test_period_10 | ✅ |
| TC-P02 | Positive | BC-VAL-08/BC-BIZ-01 | Req/Ctrl | Posted status=locked ignored (store forces open) | stays open | test_period_11 | ✅ |
| TC-P03 | Positive | BC-BIZ-02 | Ctrl | Update persists changes (name, deadline) | fields updated; updated_by=auth | test_period_12 | ✅ |
| TC-P04 | Positive | BC-DB-05 | DDL | Empty academic_term_id → independent period | term_id NULL | test_period_13 | ✅ |
| TC-P05 | Positive | BC-BIZ-06 | Ctrl | index() redirects to setup periods tab | 200/302 | test_period_14 | ✅ |
| TC-P06 | Positive | BC-BIZ-06 | Ctrl | show() redirects to edit | 200/302 | test_period_15 | ✅ |
| TC-P07 | Positive | BC-BIZ | Blade | Setup periods tab lists a period | name visible | test_period_16 | ✅ |
| TC-D01 | Dependency (C) | BC-BIZ-03/BC-INT-01 | Screen/DDL | Delete blocked when referenced by assessments/scores (FK RESTRICT metadata) | RESTRICT/NO ACTION | test_period_17 | ✅ |

### State machine (Band 20–29)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-SM01 | State (legal) | BC-SM-01 | Ctrl | New period starts open | status=open | test_period_20 | ✅ |
| TC-SM02 | State (legal) | BC-SM-02 | Ctrl | open --close()--> closed | closed | test_period_21 | ✅ |
| TC-SM03 | State (legal) | BC-SM-03 | Ctrl | closed --reopen()--> open | open | test_period_22 | ✅ |
| TC-SM04 | State (legal) | BC-SM-04 | Ctrl | closed --lock()--> locked | locked | test_period_23 | ✅ |
| TC-SM05 | State (legal) | BC-SM-05 | Ctrl | locked --unlock()--> closed (admin override) | closed | test_period_24 | ✅ |
| TC-SM06 | State (illegal) | BC-SM-06 | Ctrl | close() on closed & locked rejected | status unchanged | test_period_25 | ✅ |
| TC-SM07 | State (illegal) | BC-SM-07 | Ctrl | reopen() on open & locked rejected | status unchanged | test_period_26 | ✅ |
| TC-SM08 | State (illegal) | BC-SM-08 | Ctrl | Direct open→lock rejected + unlock on non-locked rejected | status unchanged | test_period_27 | ✅ |
| TC-SM09 | Regression | BUG-BA-002 | Audit/Ctrl | BUG-BA-002 remediated: close/reopen/lock/unlock routes exist; status not in FormRequest; lock guards closed→locked; store hardcodes open | all asserts pass | test_period_28 | ✅ |
| TC-SM10 | Defect proof | BUG-BA-002 (residual) | Audit/Ctrl | Locked period still mutable via direct PUT/toggle/destroy (no server isLocked guard) | mutation succeeds (current defective behaviour) | test_period_29 | ✅ |

### Negative / validation (Band 30–39)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N01 | Negative | BC-VAL-01/03/04/05/06 | Req | Empty payload — required fields | 422 for each field | test_period_30 | ✅ |
| TC-N02 | Negative | BC-VAL-03 | Req | name > 100 chars | 422 name | test_period_31 | ✅ |
| TC-N03 | Negative | BC-VAL-01 | Req | academic_session_id non-existent | 422 academic_session_id | test_period_32 | ✅ |
| TC-N04 | Negative | BC-VAL-02 | Req | academic_term_id non-existent (when provided) | 422 academic_term_id | test_period_33 | ✅ |
| TC-N05 | Negative | BC-VAL-05 | Req | end_date before start_date | 422 end_date | test_period_34 | ✅ |
| TC-N06 | Negative | BC-VAL-06 | Req | deadline before end_date | 422 deadline | test_period_35 | ✅ |
| TC-N07 | Negative | BC-VAL-04 | Req | non-date strings in date fields | 422 start_date | test_period_36 | ✅ |
| TC-N08 | Negative | BC-EDG-05 | mw/Req | whitespace-only name | 422 name | test_period_37 | ✅ |
| TC-S01 | Security | BC-EDG-06 | Blade | XSS payload in name — escaped on render | raw `<script>` not present | test_period_38 | ✅ |
| TC-N09 | Negative (gap) | PER-GAP-01/02 | Screen-BR | duplicate name + overlapping dates in same session | both accepted (gap proven) | test_period_39 | ✅ |

### Integration / FK & lifecycle (Band 40–49)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-D02 | Dependency (B) | BC-BIZ-03 | Ctrl | destroy() soft-deletes, sets is_active=false, moves to trash | in trash, inactive | test_period_40 | ✅ |
| TC-D03 | Dependency (F) | BC-BIZ | Ctrl | restore() returns period to default scope | visible again | test_period_41 | ✅ |
| TC-D04 | Dependency (B) | BC-BIZ-04 | Ctrl | forceDelete() removes permanently | row gone | test_period_42 | ✅ |
| TC-D05 | Dependency (E) | BC-BIZ | Ctrl | restore does NOT recover a force-deleted period | 404 | test_period_43 | ✅ |
| TC-D06 | Dependency (C/D) | BC-REF-01/02 | DDL | session FK RESTRICT + term FK SET NULL metadata | metadata matches | test_period_44 | ✅ |
| TC-D07 | Dependency (F) | BC-SM-*/BC-BIZ | Ctrl | Full lifecycle create→close→lock→unlock→delete→restore→forceDelete | each stage passes | test_period_45 | ✅ |

### Permissions / authorization (Band 50–59)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N10 | Negative | BC-AUTH-09 | mw | Guest → login redirect | /login | test_period_50 | ✅ |
| TC-N11 | Negative | BC-AUTH-02 | Ctrl | Limited user, no create perm — store | 403 | test_period_51 | ✅ |
| TC-N12 | Negative | BC-AUTH-04 | Ctrl | Limited user, no update perm — update | 403 | test_period_52 | ✅ |
| TC-N13 | Negative | BC-AUTH-05 | Ctrl | Limited user, no delete perm — destroy | 403 | test_period_53 | ✅ |
| TC-N14 | Negative | BC-AUTH-07 | Ctrl | Limited user, no status perm — toggle | 403 | test_period_54 | ✅ |
| TC-N15 | Negative | BC-AUTH-08 | Ctrl | Limited user, no lifecycle perm — lock | 403 | test_period_55 | ✅ |
| TC-P08 | Positive | BC-AUTH-* | Policy | Policy methods map to all 12 permission strings | every ability present | test_period_56 | ✅ |
| TC-P09 | Positive | BC-BIZ-05 | Ctrl | toggle-status updates is_active + JSON message | success + activated/deactivated text | test_period_57 | ✅ |

### UI / UX (Band 60–69)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-P10 | Positive | BC-BIZ | Blade | Setup search filters by name | matched name shown | test_period_60 | ✅ |
| TC-P11 | Positive | BC-DB-03 | Blade | Status filter narrows to Locked | locked row + "Locked" label | test_period_61 | ✅ |
| TC-P12 | Positive | BC-BIZ | Blade | Empty-state message when search matches nothing | "No assessment periods found." | test_period_62 | ✅ |
| TC-P13 | Positive | BC-BIZ | Blade | Trash page renders | trashed name shown | test_period_63 | ✅ |
| TC-P14 | Positive | BC-BIZ | Blade | Breadcrumb on create + edit | "Assessment Periods" | test_period_64 | ✅ |
| TC-P15 | Positive (UI) | PER-GAP-03/BUG-BA-002 | Blade | Locked edit page shows banner + CSS-disables form (client-side only) | banner + `pe-none`; submit hidden | test_period_65 | ✅ |

### Edge cases (Band 70–79)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-N16 | Negative | BC-EDG-03 | Ctrl | Invalid id — show/edit/toggle/close | 404 | test_period_70 | ✅ |
| TC-P16 | Positive | BC-EDG-01 | Req | deadline == end_date boundary | accepted | test_period_71 | ✅ |
| TC-P17 | Positive | BC-EDG-02 | Req | end_date == start_date boundary | accepted | test_period_72 | ✅ |
| TC-P18 | Positive | BC-EDG-04 | Req | is_active omitted defaults true | is_active=true | test_period_73 | ✅ |

### Tenancy + security pack (Band 90–99)
| TC ID | Category | BC | Source | Description | Expected Result | Test Method | Status |
|-------|----------|----|--------|-------------|-----------------|-------------|--------|
| TC-T01 | Tenancy | — | 05_ | Tenant context initialized + table present | tenancy()->initialized | test_period_90 | ✅ |
| TC-T02 | Tenancy | — | 05_ | Cross-tenant direct-ID isolation (defensive) | second tenant / skip | test_period_91 | ✅ |
| TC-S02 | Security | BC-AUTH-10 | Req | FormRequest authorize() returns bare true (SEC-BA-002) | pattern matches | test_period_92 | ✅ |
| TC-S03 | Security | BC-BIZ-08 | Ctrl | created_by/updated_by server-forced, not mass-assignable | audit cols=auth id | test_period_93 | ✅ |

---

## 3. Test Method Index (semantic bands)
| # | Method(s) | TC Map | Category | Band |
|---|-----------|--------|----------|------|
| 1 | test_period_01 | TC-CFG01 | Config truth | 01–09 |
| 2 | test_period_02 | TC-CFG02 | Config / DOC-BA-001 | 01–09 |
| 3 | test_period_03 | TC-CFG03 | Model scopes/helper | 01–09 |
| 4–11 | test_period_10..17 | TC-P01..P07, TC-D01 | Business rules | 10–19 |
| 12–21 | test_period_20..29 | TC-SM01..SM10 | State machine | 20–29 |
| 22–31 | test_period_30..39 | TC-N01..N09, TC-S01 | Validation | 30–39 |
| 32–37 | test_period_40..45 | TC-D02..D07 | Integration / FK | 40–49 |
| 38–45 | test_period_50..57 | TC-N10..N15, TC-P08..P09 | Permissions | 50–59 |
| 46–51 | test_period_60..65 | TC-P10..P15 | UI/UX | 60–69 |
| 52–55 | test_period_70..73 | TC-N16, TC-P16..P18 | Edge cases | 70–79 |
| 56–59 | test_period_90..93 | TC-T01..T02, TC-S02..S03 | Tenancy / security | 90–99 |

**Total: 59 test methods** in one file.

## 4. Known Source Defects (audit-equivalent)
| ID | Sev | Summary | Proving method(s) | Status |
|----|-----|---------|-------------------|--------|
| BUG-BA-002 | P1 | Period lifecycle FSM / lock enforcement. **Remediated** (close/reopen action+routes exist, open→locked blocked, `status` removed from FormRequest). **Residual:** update()/destroy()/toggleStatus() enforce NO server-side `isLocked()` guard — a LOCKED period is still mutated by a direct PUT/POST (lock is Blade-CSS only). | test_period_20–29 (esp. 27/28/29/65) | Remediated w/ residual |
| SEC-BA-002 | P1 | FormRequest `authorize()` returns bare `true` (mitigated by controller Gate) | test_period_92 | Documented |
| DOC-BA-001 | Doc | DDL-doc prefix `bha_` diverges from live `ba_` | test_period_02 | Confirmed |
| DOC-BA-002 | Doc | DDL/FRD mark `locked` terminal, but code + screen requirement allow admin unlock (locked→closed) | test_period_24 | Documented |
| PER-GAP-01 | Gap | Chronological Non-Overlapping Rule not enforced — overlapping periods accepted | test_period_39 | Open |
| PER-GAP-02 | Gap | Period Name uniqueness not enforced (FormRequest has no unique rule) | test_period_39 | Open |
| PER-GAP-03 | Gap/Doc | Requirement's boolean "Is Locked" vs impl 3-state `status` enum + separate `is_active` | test_period_65 | Documented |
