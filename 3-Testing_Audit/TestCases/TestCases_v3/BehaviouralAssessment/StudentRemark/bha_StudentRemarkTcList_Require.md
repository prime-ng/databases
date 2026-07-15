# bha_StudentRemark — Test Case List & Business Conditions

**Module:** BehaviouralAssessment (BHA) · **Feature/Screen:** StudentRemark (Student Remarks — `10-Remarks`)
**Primary table:** `ba_student_remarks` (live `ba_` prefix; filename keeps `bha_` — see DOC-BA-001)
**Controller:** `Modules\BehaviouralAssessment\Http\Controllers\BaAssessmentController`
**Persistence surface:** remarks are entered on the assessment "show" grid (`GET /assessments/{id}` → `show()`) and saved via the "Save Ratings" form (`POST /assessments/{assessment}/bulk-rate` → `bulkRate()`), with a JS debounced autosave (`POST /assessments/{assessment}/auto-save` → `autoSave()`). There is **no** standalone remarks controller or FormRequest.
**DB scope:** TENANT-side (`tenant_db`, database-per-tenant, no `tenant_id`). Tenancy scaffolding required.
**Test file:** `bha_StudentRemark_TestCas.php` (single comprehensive suite, 41 methods)

> **HEADLINE DEFECT — BUG-BA-REM-001 (P0):** `BaAssessmentController` uses both `BaStudentRemark` and the `DB` facade **unqualified with no `use` import**. Inside the controller namespace they resolve to `Modules\BehaviouralAssessment\Http\Controllers\{BaStudentRemark,DB}` (nonexistent) → **fatal `Error` → HTTP 500**. This kills the remark READ path (`show()`, `reviewShow()`) and the remark WRITE path (`bulkRate()`). **Remarks cannot be viewed or saved through the application.** (This is the remarks manifestation of the RESUME-context BUG-BA-001 / MyAssessments BUG-BA-MYA-001.)

---

## 1. Business Conditions

### BC-DB (schema — DDL/migration)
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | `ba_student_remarks` has `id, assessment_id, student_id, remark_text, is_active, created_by, updated_by, created_at, updated_at, deleted_at` | DDL-ba_student_remarks |
| BC-DB-02 | `remark_text` is `TEXT NOT NULL` | DDL-ba_student_remarks |
| BC-DB-03 | `is_active TINYINT(1) DEFAULT 1` | DDL-ba_student_remarks |
| BC-DB-04 | Unique key `uq_ba_remark (assessment_id, student_id)` — one overall remark per student per assessment | DDL-ba_student_remarks |
| BC-DB-05 | `deleted_at` present (soft delete) | Migration `create_ba_student_remarks_table` |
| BC-DB-06 | Live table prefix is `ba_`; the DDL-doc `bha_student_remarks` must not exist at runtime | Audit DOC-BA-001 |

### BC-REF (foreign keys)
| ID | Condition | Source |
|----|-----------|--------|
| BC-REF-01 | `assessment_id` → `ba_assessments.id` **ON DELETE CASCADE** | DDL / migration |
| BC-REF-02 | `student_id` → `std_students.id` **ON DELETE RESTRICT** (cross-module) | DDL / migration |

### BC-VAL (validation — inline in `bulkRate()`)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `remarks` is `nullable|array`; `remarks.*` is `nullable|string|max:1000` | Controller `bulkRate()` |
| BC-VAL-02 | Requirement mandates **min 30 / max 500** chars & non-empty — **NOT enforced** (no `min:30`, max is 1000) → **VAL-BA-REM-002** | Screen-BR-1 vs Controller |
| BC-VAL-03 | Empty/whitespace remarks are skipped (`trim($remark) !== ''`) — no empty rows written | Controller `bulkRate()` |
| BC-VAL-04 | No dedicated `BaStudentRemarkRequest`; validation is inline, gated by `Gate::authorize` (SEC-BA-002 pattern) | Module source |

### BC-AUTH (permissions — inherit assessments gates)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | `show()` authorizes `tenant.behavioural-assessment.assessments.view` | Controller + BaAssessmentPolicy |
| BC-AUTH-02 | `bulkRate()`/`autoSave()` authorize `tenant.behavioural-assessment.assessments.update` | Controller |
| BC-AUTH-03 | Guest is redirected to `/login` | web middleware |
| BC-AUTH-04 | `Gate::before` grants Super Admin all abilities → negative auth tests must use a non-super-admin limited user (constraint #31) | AppServiceProvider |

### BC-BIZ (business logic)
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | A remark persists with `created_by`/`updated_by` = acting user | Model / Controller |
| BC-BIZ-02 | `updateOrCreate(assessment_id, student_id)` overwrites the single remark (one per student per assessment) | Controller `bulkRate()` |
| BC-BIZ-03 | `remark_text` stored verbatim (no server-side sanitisation; escaping is Blade's job on render) | Model |
| BC-BIZ-04 | Debounced autosave should write remarks to `ba_student_remarks` — **but `autoSave()` persists ratings only** → **BUG-BA-REM-003** | Screen-BR-2 vs Controller |

### BC-SM (state coupling — remark editability tracks assessment lifecycle)
| ID | State → Trigger → Next | Condition | Source |
|----|----------------------|-----------|--------|
| BC-SM-01 | draft → editable | Remark textarea enabled only when `status === 'draft'` and user has `.update` | show.blade |
| BC-SM-02 | non-draft/locked → read-only | `bulkRate()` `isLocked()` guard returns 302 *before* the `DB::transaction` fatal | Controller |

### BC-EDG (edge cases)
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | `bulk-rate` on a nonexistent assessment id → 404 (`findOrFail`) | Controller |
| BC-EDG-02 | Duplicate `(assessment_id, student_id)` insert violates `uq_ba_remark` | DDL |
| BC-EDG-03 | Missing `remark_text` insert fails (NOT NULL) | DDL |
| BC-EDG-04 | 3-char remark accepted at model layer (no min guard) | VAL-BA-REM-002 |
| BC-EDG-05 | 600-char narrative accepted (TEXT column, no 500 cap) | VAL-BA-REM-002 |

### BC-CFG / FE (requirement UI features absent)
| ID | Condition | Source |
|----|-----------|--------|
| FE-BA-REM-004 | "Comment Bank / Predefined Templates" panel absent from `show.blade` | Screen-BR-3 |
| FE-BA-REM-005 | Character counter absent; textarea labelled "Optional remark..." contradicting required min-30 | Screen-BR-1/UI |

### BC-INT / Tenancy
| ID | Condition | Source |
|----|-----------|--------|
| BC-INT-01 | Tenant context initialized; `ba_student_remarks` resolves within tenant DB | stancl/tenancy |
| BC-INT-02 | Cross-tenant direct-ID isolation (defensive; needs a 2nd tenant) | tenancy |

---

## 2. Test Case List

### Positive (TC-P)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-P01 | Schema | BC-DB-01..05 | DDL | Table/columns/model/migration truth | All present; model config correct | _01 | Automated |
| TC-P02 | Schema | BC-DB-06 | DOC-BA-001 | Live `ba_` prefix; `bha_` absent | ba_ exists, bha_ absent | _02 | Automated |
| TC-P03 | Schema | BC-DB-04, BC-REF | DDL | uq_ba_remark + FK delete rules | unique + CASCADE/RESTRICT | _03 | Automated |
| TC-P10 | Persist | BC-BIZ-01 | Model | Model create persists remark | row created, created_by set | _10 | Automated |
| TC-P11 | Persist | BC-BIZ-02 | Controller | One remark per student (updateOrCreate) | same id reused; count=1 | _11 | Automated |
| TC-P12 | Relation | BC-REF | Model | assessment()/student()/hasMany resolve | relations resolve | _12 | Automated |
| TC-P13 | Cast | BC-DB-03 | Model | is_active default true + boolean cast | bool true | _13 | Automated |
| TC-P14 | Persist | BC-EDG-05 | Model | 600-char narrative stored | stored verbatim | _14 | Automated |
| TC-P60 | UI | BC-SM-01 | Blade | Remarks textarea column + bulk-rate form present | present | _60 | Automated |
| TC-P93 | Security | BC-BIZ-01 | Model | created_by/updated_by from auth | stamped from admin | _93 | Automated |

### State Machine (TC-SM)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-SM01 | SM | BC-SM-02 | Controller | Locked assessment bulk-rate blocked before fatal | 302 (not 500) | _20 | Automated |
| TC-SM02 | SM | BC-SM-01 | Blade | Textarea disabled when not draft | disabled markup | _21 | Automated |

### Negative (TC-N)
| TC ID | Category | BC | Source | Description | Expected | Method | Status |
|-------|----------|----|--------|-------------|----------|--------|--------|
| TC-N30 | Validation | BC-VAL-02 | Screen-BR-1 | Inline rule omits required/min30/max500 | max:1000, no min:30 | _30 | Automated |
| TC-N31 | Validation | BC-EDG-04 | VAL-BA-REM-002 | 3-char remark accepted | persists | _31 | Automated |
| TC-N32 | Validation | BC-VAL-03 | Controller | Empty remark skipped | source guard present | _32 | Automated |
| TC-N33 | Security | BC-BIZ-03 | Model | XSS payload stored verbatim | stored (render dead) | _33 | Automated |
| TC-N70 | Edge | BC-EDG-01 | Controller | bulk-rate invalid id → 404 | 404 | _70 | Automated |
| TC-N73 | Edge | BC-EDG-03 | DDL | remark_text NOT NULL | insert throws | _73 | Automated |
| TC-N44 | Edge | BC-EDG-02 | DDL | Duplicate pair violates unique | throws; count=1 | _44 | Automated |

### Dependency (TC-D)
| TC ID | Sub | BC | Source | Description | Expected | Method | Status |
|-------|-----|----|--------|-------------|----------|--------|--------|
| TC-D40 | B | BC-DB-05 | Model | Soft delete hides remark | trashed only | _40 | Automated |
| TC-D41 | B | BC-REF-01 | DDL | Assessment hard-delete cascades remarks | remark gone | _41 | Automated |
| TC-D42 | C | BC-REF-02 | DDL | student_id RESTRICT | metadata RESTRICT | _42 | Automated |
| TC-D43 | B | BC-REF-01 | DDL | assessment_id CASCADE | metadata CASCADE | _43 | Automated |
| TC-D45 | B | BC-DB-05 | Model | Force delete removes physically | gone | _45 | Automated |

### Defect-proving (TC-DEV)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-DEV-REM-001a | BUG-BA-REM-001 | Controller | `show()` read path fatals | HTTP 500 | _46 | Automated |
| TC-DEV-REM-001b | BUG-BA-REM-001 | Controller | `bulk-rate` write path fatals on draft; no row saved | HTTP 500, 0 rows | _47 | Automated |
| TC-DEV-REM-001c | BUG-BA-REM-001 | Controller | `reviewShow()` read path fatals | HTTP 500 | _48 | Automated |
| TC-DEV-REM-001d | BUG-BA-REM-001 | Controller | Source: `BaStudentRemark`/`DB` unimported | usages present, imports absent | _49 | Automated |
| TC-DEV-REM-003a | BUG-BA-REM-003 | Controller | autosave drops posted remarks | 200, 0 rows | _71 | Automated |
| TC-DEV-REM-003b | BUG-BA-REM-003 | Controller | Source: autoSave body has no `remarks` | absent | _72 | Automated |
| TC-DEV-REM-004 | FE-BA-REM-004 | Blade | Comment Bank/templates absent | absent | _61 | Automated |
| TC-DEV-REM-005a | FE-BA-REM-005 | Blade | Character counter/maxlength absent | absent | _62 | Automated |
| TC-DEV-REM-005b | FE-BA-REM-005 | Blade | Textarea labelled "Optional" | present | _63 | Automated |
| TC-DEV-002 | SEC-BA-002 | Source | No dedicated FormRequest; inline validation | request file absent | _92 | Automated |

### Permissions (TC-AUTH) / Tenancy (TC-T)
| TC ID | BC | Source | Description | Expected | Method | Status |
|-------|----|--------|-------------|----------|--------|--------|
| TC-AUTH01 | BC-AUTH-03 | middleware | Guest → login on show | redirect /login | _50 | Automated |
| TC-AUTH02 | BC-AUTH-02/04 | Controller | Limited user 403 on bulk-rate | 403 | _51 | Automated |
| TC-AUTH03 | BC-AUTH-01/04 | Controller | Limited user 403 on show (before fatal) | 403 | _52 | Automated |
| TC-AUTH04 | BC-AUTH-01/02 | Policy | Policy strings map to permissions | all 8 present | _53 | Automated |
| TC-AUTH05 | BC-AUTH-02 | Controller | autoSave gated by .update | gate present | _54 | Automated |
| TC-T01 | BC-INT-01 | tenancy | Tenant context initialized | initialized | _90 | Automated |
| TC-T02 | BC-INT-02 | tenancy | Cross-tenant isolation | 2nd tenant / skip | _91 | Automated |

---

## 3. Known Source Defects (audit-equivalent)

| ID | Severity | Where | Proving method |
|----|----------|-------|----------------|
| **BUG-BA-REM-001** | **P0 (Critical)** | `BaAssessmentController` show/reviewShow/bulkRate — `BaStudentRemark` + `DB` unimported → 500 | _46, _47, _48, _49 |
| **BUG-BA-REM-003** | High | `autoSave()` silently drops remarks | _71, _72 |
| **VAL-BA-REM-002** | Medium | Inline rule `max:1000`, no `min:30`; requirement wants min 30 / max 500 required | _30, _31 |
| **FE-BA-REM-004** | Medium | Comment Bank / templates panel absent | _61 |
| **FE-BA-REM-005** | Medium | Character counter absent; textarea "Optional" contradicts required min-30 | _62, _63 |
| **DOC-BA-001** | Doc | DDL doc prefix `bha_` vs live `ba_` | _02 |
| **SEC-BA-002** | Low | No dedicated FormRequest; inline validation | _92 |

---

## 4. Test Method Index (bands)

| # | Method | Band | Category | TC |
|---|--------|------|----------|----|
| 1 | _01_migration_model_and_inline_validation_configuration | 01–09 | Schema | TC-P01 |
| 2 | _02_runtime_table_prefix_diverges | 01–09 | Schema | TC-P02 |
| 3 | _03_unique_index_and_foreign_key_rules | 01–09 | Schema | TC-P03 |
| 4 | _10_model_create_persists_remark_row | 10–19 | BIZ | TC-P10 |
| 5 | _11_one_remark_per_student_update_or_create | 10–19 | BIZ | TC-P11 |
| 6 | _12_relationships_resolve | 10–19 | REF | TC-P12 |
| 7 | _13_is_active_defaults_true_casts_boolean | 10–19 | Cast | TC-P13 |
| 8 | _14_remark_text_stores_long_narrative | 10–19 | EDG | TC-P14 |
| 9 | _20_bulk_rate_guard_blocks_locked | 20–29 | SM | TC-SM01 |
| 10 | _21_show_blade_disables_textarea_non_draft | 20–29 | SM | TC-SM02 |
| 11 | _30_inline_validation_omits_required_min30_max500 | 30–39 | VAL | TC-N30 |
| 12 | _31_short_3_char_remark_accepted | 30–39 | VAL | TC-N31 |
| 13 | _32_empty_remark_skipped_source | 30–39 | VAL | TC-N32 |
| 14 | _33_xss_stored_verbatim | 30–39 | SEC | TC-N33 |
| 15 | _40_soft_delete_hides | 40–49 | Dep-B | TC-D40 |
| 16 | _41_parent_force_delete_cascades | 40–49 | Dep-B | TC-D41 |
| 17 | _42_student_fk_restrict | 40–49 | Dep-C | TC-D42 |
| 18 | _43_assessment_fk_cascade | 40–49 | Dep-B | TC-D43 |
| 19 | _44_duplicate_pair_unique_violation | 40–49 | EDG | TC-N44 |
| 20 | _45_force_delete_removes | 40–49 | Dep-B | TC-D45 |
| 21 | _46_show_read_path_fatals | 40–49 | DEV | TC-DEV-REM-001a |
| 22 | _47_bulk_rate_write_path_fatals | 40–49 | DEV | TC-DEV-REM-001b |
| 23 | _48_review_show_read_path_fatals | 40–49 | DEV | TC-DEV-REM-001c |
| 24 | _49_controller_source_confirms_missing_imports | 40–49 | DEV | TC-DEV-REM-001d |
| 25 | _50_guest_redirected_login | 50–59 | AUTH | TC-AUTH01 |
| 26 | _51_limited_403_bulk_rate | 50–59 | AUTH | TC-AUTH02 |
| 27 | _52_limited_403_show | 50–59 | AUTH | TC-AUTH03 |
| 28 | _53_policy_strings_map | 50–59 | AUTH | TC-AUTH04 |
| 29 | _54_auto_save_gated_update | 50–59 | AUTH | TC-AUTH05 |
| 30 | _60_show_blade_textarea_column | 60–69 | UI | TC-P60 |
| 31 | _61_comment_bank_absent | 60–69 | FE | TC-DEV-REM-004 |
| 32 | _62_character_counter_absent | 60–69 | FE | TC-DEV-REM-005a |
| 33 | _63_textarea_optional_contradicts | 60–69 | FE | TC-DEV-REM-005b |
| 34 | _70_bulk_rate_invalid_id_404 | 70–79 | EDG | TC-N70 |
| 35 | _71_auto_save_drops_remarks | 70–79 | DEV | TC-DEV-REM-003a |
| 36 | _72_auto_save_source_ratings_only | 70–79 | DEV | TC-DEV-REM-003b |
| 37 | _73_remark_text_not_nullable | 70–79 | EDG | TC-N73 |
| 38 | _90_tenant_context_initialized | 90–99 | Tenancy | TC-T01 |
| 39 | _91_cross_tenant_isolation | 90–99 | Tenancy | TC-T02 |
| 40 | _92_no_dedicated_form_request | 90–99 | Security | TC-DEV-002 |
| 41 | _93_created_by_forced_from_auth | 90–99 | Security | TC-P93 |
