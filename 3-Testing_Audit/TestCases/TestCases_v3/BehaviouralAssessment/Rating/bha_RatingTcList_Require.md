# bha_Rating — Business Conditions & Test Case List

**Module:** BehaviouralAssessment (`BHA`) · **Feature/Screen:** Rating (Ratings Grid) · **Screen file:** `BehaviouralAssessment_v2/09-Ratings.md`
**Primary table:** `ba_assessment_ratings` (live `ba_` prefix; DDL doc says `bha_` — DOC-BA-001) · **Controller:** `BaAssessmentController` (`show/edit/update/store/destroy` + `autoSave/bulkRate/submit`)
**DB scope:** TENANT-side (tenant_db) · **Test style:** Browser Dusk (`extends DuskTestCase`) — mirrors sibling `RatingScale`
**Type:** CRUD-transactional (grid data-entry), Full depth · **Primary audit target:** **BUG-BA-001** (ratings editable after submit/approve/lock)

> **File-prefix note:** file/class prefix stays `bha_` (registry + folder convention); **all test bodies assert the live `ba_` tables** (asserting `bha_` false-fails — DOC-BA-001).

---

## 1. Business Conditions

### BC-DB — Schema (Source: `DDL-ba_assessment_ratings`, `DDL-ba_assessments`, `DDL-ba_audit_log`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_assessment_ratings` has `id, assessment_id, student_id, criterion_id, rating_level_id, remark, is_active, created_by, updated_by, timestamps, deleted_at` | DDL-ba_assessment_ratings |
| BC-DB-02 | `rating_level_id` is NULLable (NULL = unrated cell) | DDL-ba_assessment_ratings |
| BC-DB-03 | UNIQUE `uq_bha_rating(assessment_id, student_id, criterion_id)` — one row per cell | DDL-ba_assessment_ratings |
| BC-DB-04 | Uses `SoftDeletes` (`deleted_at`); unique key does NOT include `deleted_at` (DATA-BA-003) | DDL + Model |
| BC-DB-05 | `ba_assessments.status` ENUM(`draft,submitted,reviewed,locked`) DEFAULT `draft` | DDL-ba_assessments |
| BC-DB-06 | `ba_audit_log` is immutable — no `updated_at`, no `deleted_at` | DDL-ba_audit_log |
| BC-DB-07 | Model binds live table `ba_assessment_ratings`; `bha_*` does NOT exist at runtime | Code / DOC-BA-001 |

### BC-REF — FK / referential integrity (Source: `DDL-ba_assessment_ratings`)
| ID | FK | Referenced | ON DELETE | Source |
|----|----|-----------|-----------|--------|
| BC-REF-01 | `assessment_id` | `ba_assessments` | CASCADE | DDL |
| BC-REF-02 | `student_id` | `std_students` | RESTRICT | DDL |
| BC-REF-03 | `criterion_id` | `ba_criteria` | RESTRICT | DDL |
| BC-REF-04 | `rating_level_id` | `ba_rating_levels` | SET NULL | DDL |

### BC-BIZ — Business rules (Source: Screen §Autosave/Formula/Workflow, Controller)
| ID | Rule | Source |
|----|------|--------|
| BC-BIZ-01 | Changing a cell triggers async POST to `auto-save`; `autoSave` upserts `ba_assessment_ratings` and returns `{success:true}` | Screen-BR (Autosave), Controller `autoSave` |
| BC-BIZ-02 | `bulkRate` saves the whole grid (ratings + per-student remarks) inside `DB::transaction` | Controller `bulkRate` |
| BC-BIZ-03 | Upsert is keyed on `(assessment_id, student_id, criterion_id)` — re-rating a cell UPDATEs, never duplicates | Controller, DDL uq |
| BC-BIZ-04 | Each changed `rating_level_id` appends an `assessment_rating` row to `ba_audit_log` | Controller `autoSave/bulkRate`, BaAuditLog |
| BC-BIZ-05 | Empty-string cell → `rating_level_id` stored NULL (partial grid allowed) | Controller `?: null` |
| BC-BIZ-06 | `submit` transitions `draft → submitted`, stamps `submitted_at`, logs status change | Controller `submit` |

### BC-SM — State machine / lock lifecycle (Source: `Screen-§Lock Constraints`, Audit BUG-BA-001)
| ID | State → Trigger → Next | Expected (requirement) | Actual (code) | Source |
|----|------------------------|------------------------|---------------|--------|
| BC-SM-01 | draft → autoSave → draft (rating saved) | ✅ allowed | ✅ allowed | Screen, Controller |
| BC-SM-02 | draft → submit → submitted | ✅ allowed | ✅ allowed | Controller `submit` |
| BC-SM-03 | **submitted → autoSave → (reject)** | ❌ must reject (read-only) | ⚠️ **ACCEPTED** — `isLocked()` false | **BUG-BA-001** |
| BC-SM-04 | **reviewed → autoSave → (reject)** | ❌ must reject | ⚠️ **ACCEPTED** | **BUG-BA-001** |
| BC-SM-05 | **period locked/past-deadline → autoSave → (reject)** | ❌ must reject | ⚠️ **ACCEPTED** — endpoints never read period | **BUG-BA-001** |
| BC-SM-06 | `isLocked()` ⇔ `status==='locked'` only; no code assigns `locked` → guard is a dead branch | guard must cover submitted/reviewed/locked/deadline | only `locked` | **BUG-BA-001** |

### BC-AUTH — Authorization (Source: `BaAssessmentPolicy`, Controller `Gate::authorize`)
| ID | Ability | Gate string | Source |
|----|---------|-------------|--------|
| BC-AUTH-01 | view grid (`show`) | `tenant.behavioural-assessment.assessments.view` | Policy/Controller |
| BC-AUTH-02 | save ratings (`autoSave/bulkRate/edit/update/submit`) | `tenant.behavioural-assessment.assessments.update` | Policy/Controller |
| BC-AUTH-03 | create assessment (`store`) | `tenant.behavioural-assessment.assessments.create` | Policy/Controller |
| BC-AUTH-04 | guest → redirect `/login` | web+auth middleware | RouteServiceProvider |
| BC-AUTH-05 | Blade disables grid unless `status==='draft'` AND `Gate::check(...update)` (client-only read-only) | show.blade | Screen, Blade |

### BC-VAL — Validation (Source: Controller inline `validate`, Audit VAL-BA-001)
| ID | Rule | Source |
|----|------|--------|
| BC-VAL-01 | `autoSave`: `ratings|nullable|array`, `ratings.*|array` — scalar payload → 422 | Controller `autoSave` |
| BC-VAL-02 | `bulkRate`: `remarks.*|nullable|string|max:1000` | Controller `bulkRate` |
| BC-VAL-03 | **No FK-exists validation** on nested student/criterion ids (VAL-BA-001) | Audit VAL-BA-001 |
| BC-VAL-04 | **No dedicated FormRequest** for the rating grid — inline validation only (VAL-BA-001) | Audit VAL-BA-001 |
| BC-VAL-05 | `BaAssessmentRequest::authorize()` returns bare `true` (SEC-BA-002) | Audit SEC-BA-002 |

### BC-EDG — Edge cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `autoSave`/`show` on missing id → 404 (`findOrFail`) | Controller |
| BC-EDG-02 | Empty `ratings` payload → success, no rows created | Controller |
| BC-EDG-03 | Remark rendered escaped (`{{ }}`), not raw (`{!! !!}`) — no stored XSS | Blade |

### Known Source Defects (audit-equivalent)
| ID | Severity | Summary | Proving test |
|----|----------|---------|--------------|
| **BUG-BA-001** | P1 (P0 if integration on) | Ratings editable after submit/approve/lock — `isLocked()` checks a state never set; period lock never cascades | `_20 _21 _22 _23 _24 _25 _26 _45` |
| DOC-BA-001 | Doc | DDL prefix `bha_` vs live `ba_` | `_02` |
| VAL-BA-001 | P1 | Rating write path has no FormRequest / no FK-exists validation | `_32 _33` |
| SEC-BA-002 | P1 | FormRequest `authorize()` bare `true` | `_55` |
| DATA-BA-003 | P2 | Soft-delete + unique without `deleted_at` → recreate-after-delete 500 | `_44` |
| **BUG-BA-RAT-01** (discovered) | P1 (High conf.) | `BaAssessmentController` uses unqualified `DB` + `BaStudentRemark` (no `use`) in `show/reviewShow/bulkRate` → runtime `Error` | `_93` (contrast `_94`) |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-P01 | BC-DB-01/04 | DDL | Ratings table + model config (fillable, softdeletes, relations) | All present | `_01` | ✅ |
| TC-P02 | BC-DB-07 | DOC-BA-001 | Runtime `ba_` tables exist, `bha_` absent | Divergence proven | `_02` | ✅ |
| TC-P03 | BC-DB-05 | DDL | status enum lists draft/submitted/reviewed/locked | Present | `_03` | ✅ |
| TC-P04 | BC-DB-06 | DDL | `ba_audit_log` immutable (no updated_at/deleted_at) | Confirmed | `_04` | ✅ |
| TC-P05 | BC-BIZ-01 | Screen | autoSave persists a rating (draft) | success:true + row | `_10` | ✅ |
| TC-P06 | BC-BIZ-03/04 | Controller | Upsert updates same cell + writes audit | 1 row, audit appended | `_11` | ✅ |
| TC-P07 | BC-BIZ-05 | Controller | Empty cell → NULL level | row with NULL | `_12` | ✅ |
| TC-P08 | BC-DB-03 | DDL | Unique index (assessment,student,criterion) | Present | `_13` | ✅ |
| TC-P09 | BC-SM-02 | Controller | submit draft→submitted, stamps submitted_at | Transition ok | `_25` | ✅ |
| TC-P10 | BC-AUTH-05 | Blade | Grid disabled for non-draft / no-update (client) | disabled attrs | `_60` | ✅ |
| TC-P11 | BC-BIZ-01/02 | Blade | Grid wires auto-save + bulk-rate | routes present | `_61` | ✅ |
| TC-P12 | BC-DB-03 | Blade | Cell name pattern `ratings[student][criterion]` | Present | `_62` | ✅ |

### State-Machine (TC-SM) — BUG-BA-001 core
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-SM01 | BC-SM-06 | BUG-BA-001 | `isLocked()` true only for `locked`; false for submitted/reviewed | Root cause proven | `_20` | ✅ |
| TC-SM02 | BC-SM-03 | BUG-BA-001 | Submitted assessment still accepts autoSave writes | success:true (BUG) | `_21` | ✅ |
| TC-SM03 | BC-SM-04 | BUG-BA-001 | Reviewed assessment still accepts writes | success:true (BUG) | `_22` | ✅ |
| TC-SM04 | BC-SM-05 | BUG-BA-001 | Endpoints never consult period status/deadline | no period guard | `_23` | ✅ |
| TC-SM05 | BC-SM-06 | BUG-BA-001 | No code sets `locked`; no `isEditable()` helper | dead guard proven | `_24` | ✅ |
| TC-SM06 | BC-SM-03 vs BC-AUTH-05 | BUG-BA-001 | Client disables grid but server accepts | divergence proven | `_26` | ✅ |
| TC-SM07 | BC-SM-01..03 | BUG-BA-001 | Lifecycle: rate→submit→still editable→cascade delete | still editable | `_45` | ✅ |

### Negative (TC-N)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-N01 | BC-VAL-01 | Controller | autoSave scalar ratings → 422 | 422 + errors.ratings | `_30` | ✅ |
| TC-N02 | BC-VAL-02 | Controller | bulkRate remark max:1000 (source) | rule present | `_31` | ✅ |
| TC-N03 | BC-VAL-03 | VAL-BA-001 | No FK-exists validation on ids | no exists: rules | `_32` | ✅ |
| TC-N04 | BC-VAL-04 | VAL-BA-001 | No dedicated rating FormRequest | absent | `_33` | ✅ |
| TC-N05 | BC-VAL-05 | SEC-BA-002 | authorize() bare true | matches regex | `_55` | ✅ |
| TC-N06 | BC-EDG-01 | Controller | autoSave invalid id → 404 | 404 | `_70` | ✅ |
| TC-N07 | BC-EDG-01 | Controller | show invalid id → 404 | 404 | `_72` | ✅ |
| TC-N08 | BC-EDG-02 | Controller | Empty ratings → no-op success | no rows | `_71` | ✅ |
| TC-N09 | BC-AUTH-04 | Middleware | Guest → /login | redirect | `_50` | ✅ |
| TC-N10 | BC-AUTH-02 | Policy | Limited user 403 on auto-save | 403 | `_51` | ✅ |
| TC-N11 | BC-AUTH-01 | Policy | Limited user 403 on show | 403 | `_52` | ✅ |
| TC-N12 | BC-AUTH-03 | Policy | Limited user 403 on store | 403 | `_53` | ✅ |
| TC-N13 | BC-EDG-03 | Blade | Remark escaped, not raw | no `{!! remark` | `_92` | ✅ |

### Dependency (TC-D)
| TC ID | BC | Sub-cat | Description | Expected | Method | Status |
|-------|----|---------|-------------|----------|--------|--------|
| TC-D01 | BC-REF-01 | B/F | Delete assessment cascades ratings | ratings gone | `_40` | ✅ |
| TC-D02 | BC-REF-02 | C | student FK RESTRICT | RESTRICT | `_41` | ✅ |
| TC-D03 | BC-REF-03 | C | criterion FK RESTRICT | RESTRICT | `_42` | ✅ |
| TC-D04 | BC-REF-04 | D | rating_level FK SET NULL | SET NULL | `_43` | ✅ |
| TC-D05 | BC-DB-04 | G | Unique omits deleted_at (DATA-BA-003) | no deleted_at in uq | `_44` | ✅ |
| TC-D06 | BC-AUTH | — | Policy strings map to all 8 abilities | present | `_54` | ✅ |

### Tenancy / Security (TC-T / TC-S)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-T01 | — | Tenancy | Tenant context initialized | true | `_90` | ✅ |
| TC-T02 | — | Tenancy | Cross-tenant isolation (defensive) | skip/verify | `_91` | ✅ |
| TC-S01 | BUG-BA-RAT-01 | Discovered | Controller unqualified `DB`/`BaStudentRemark` → latent fatal | proven (source) | `_93` | ✅ |
| TC-S02 | — | Contrast | autoSave path is clean (runs) | no unqualified symbols | `_94` | ✅ |

---

## 3. Test Method Index
| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | `test_rating_01_*` | TC-P01 | Schema | 01–09 |
| 2 | `test_rating_02_*` | TC-P02 | Schema/Doc | 01–09 |
| 3 | `test_rating_03_*` | TC-P03 | Schema | 01–09 |
| 4 | `test_rating_04_*` | TC-P04 | Schema | 01–09 |
| 5 | `test_rating_10_*` | TC-P05 | Business | 10–19 |
| 6 | `test_rating_11_*` | TC-P06 | Business | 10–19 |
| 7 | `test_rating_12_*` | TC-P07 | Business | 10–19 |
| 8 | `test_rating_13_*` | TC-P08 | Business | 10–19 |
| 9 | `test_rating_20_*` | TC-SM01 | State machine | 20–29 |
| 10 | `test_rating_21_*` | TC-SM02 | State machine | 20–29 |
| 11 | `test_rating_22_*` | TC-SM03 | State machine | 20–29 |
| 12 | `test_rating_23_*` | TC-SM04 | State machine | 20–29 |
| 13 | `test_rating_24_*` | TC-SM05 | State machine | 20–29 |
| 14 | `test_rating_25_*` | TC-P09 | State machine | 20–29 |
| 15 | `test_rating_26_*` | TC-SM06 | State machine | 20–29 |
| 16 | `test_rating_30_*` | TC-N01 | Validation | 30–39 |
| 17 | `test_rating_31_*` | TC-N02 | Validation | 30–39 |
| 18 | `test_rating_32_*` | TC-N03 | Validation | 30–39 |
| 19 | `test_rating_33_*` | TC-N04 | Validation | 30–39 |
| 20 | `test_rating_40_*` | TC-D01 | Dependency | 40–49 |
| 21 | `test_rating_41_*` | TC-D02 | Dependency | 40–49 |
| 22 | `test_rating_42_*` | TC-D03 | Dependency | 40–49 |
| 23 | `test_rating_43_*` | TC-D04 | Dependency | 40–49 |
| 24 | `test_rating_44_*` | TC-D05 | Dependency | 40–49 |
| 25 | `test_rating_45_*` | TC-SM07 | Dependency/SM | 40–49 |
| 26 | `test_rating_50_*` | TC-N09 | Permissions | 50–59 |
| 27 | `test_rating_51_*` | TC-N10 | Permissions | 50–59 |
| 28 | `test_rating_52_*` | TC-N11 | Permissions | 50–59 |
| 29 | `test_rating_53_*` | TC-N12 | Permissions | 50–59 |
| 30 | `test_rating_54_*` | TC-D06 | Permissions | 50–59 |
| 31 | `test_rating_55_*` | TC-N05 | Permissions | 50–59 |
| 32 | `test_rating_60_*` | TC-P10 | UI/UX | 60–69 |
| 33 | `test_rating_61_*` | TC-P11 | UI/UX | 60–69 |
| 34 | `test_rating_62_*` | TC-P12 | UI/UX | 60–69 |
| 35 | `test_rating_70_*` | TC-N06 | Edge | 70–79 |
| 36 | `test_rating_71_*` | TC-N08 | Edge | 70–79 |
| 37 | `test_rating_72_*` | TC-N07 | Edge | 70–79 |
| 38 | `test_rating_90_*` | TC-T01 | Tenancy | 90–99 |
| 39 | `test_rating_91_*` | TC-T02 | Tenancy | 90–99 |
| 40 | `test_rating_92_*` | TC-N13 | Security | 90–99 |
| 41 | `test_rating_93_*` | TC-S01 | Security | 90–99 |
| 42 | `test_rating_94_*` | TC-S02 | Security | 90–99 |

**Total: 42 methods.**
