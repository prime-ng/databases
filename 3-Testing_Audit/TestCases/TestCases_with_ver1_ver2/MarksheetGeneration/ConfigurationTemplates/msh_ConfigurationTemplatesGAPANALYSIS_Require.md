# Configuration Templates — Gap Analysis & Coverage

**Feature:** MarksheetGeneration → Configuration Templates · **Primary table:** `msh_config_templates`
**Suites:** `msh_ConfigurationTemplatesV1_TestCas.php` (16) · `msh_ConfigurationTemplatesV2_TestCas.php` (47)

Legend: **Full** = behaviour + DB/side-effect asserted · **Partial** = behaviour asserted, side-effect/edge not fully · **Gap** = not automated.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive

| Manual TC | V1 | V2 | Coverage | Note |
|-----------|----|----|----------|------|
| TC-P01 schema/config | 01,02 | 01,02,03 | Full | Schema + model + request + controller events |
| TC-P02 create + Stored | 04 | 10 | Full | DB row + activity issuer |
| TC-P03 null grading schema | – | 11 | Full | |
| TC-P04 class-assignment sync | – | 12 | Full | Skips if no active class |
| TC-P05 update + Updated | 05 | 13 | Full | |
| TC-P06 passing % default 33 | – | 14 | Full | Raw insert proves DDL default |
| TC-P07 best-of-N persist | – | 15 | Full | |
| TC-P08 board_code optional | – | 16 | Full | |
| TC-P09 toggle + Toggled | 06 | (via V1 06) | Full | JSON `{success,is_active}` |
| TC-P10 soft delete + Deleted | 07 | 17 | Full | |
| TC-P11 restore + Restored | 08 | 18 | Full | Reactivation asserted |
| TC-P12 force delete | – | 19 | Full | try/catch skip on media/FK |
| TC-P13 combined render | 03 | 60,54 | Full | Pane + gate |
| TC-P14 search | – | 61 | Full | |
| TC-P15 status filter | – | 62 | Partial | Loads 200; row-narrowing not row-counted |
| TC-P16 breadcrumb | 03 | 63 | Full | |

### Negative

| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-N01 required | 09 | 30 | Full |
| TC-N02 code max 50 | – | 31 | Full |
| TC-N03 name max 150 | – | 32 | Full |
| TC-N04 description max 500 | – | 33 | Full |
| TC-N05 board_code max 50 | – | 34 | Full |
| TC-N06 passing % range | 12 | 35 | Full (both bounds) |
| TC-N07 comp. failures range | – | 36 | Full |
| TC-N08 best_of_n min 1 | – | 37 | Full |
| TC-N09 duplicate code/session | 10 | 38 | Full (no-insert asserted) |
| TC-N10 same code diff session | – | 39 | Full (skips if 1 session) |
| TC-N11 invalid marksheet_type | 11 | 40 | Full |
| TC-N12 invalid exam_group | 11 | 41 | Full |
| TC-N13 invalid session | – | 42 | Full |
| TC-N14 invalid grading schema | – | 43 | Full |
| TC-N15 guest redirect | 14 | 50 | Full |
| TC-N16 no-create → 403 | – | 51 | Partial (skips if super-admin bypass) |
| TC-N17 no-delete → 403 | – | 52 | Partial (skips if super-admin bypass) |
| TC-N18 SEC-MSH-003 authorize=true | 01 | 53 | Full |
| TC-N19 XSS escaped | – | 70 | Full |
| TC-N20 IDOR/404 | – | 91 | Full |

### Dependency

| Manual TC | V1 | V2 | Coverage |
|-----------|----|----|----------|
| TC-D01 marksheet type RESTRICT | 13 | 44 | Full |
| TC-D02 exam group RESTRICT | – | 45 | Full |
| TC-D03 CASCADE junction | – | 46 | Full |
| TC-D04 schedule RESTRICT (23000) | – | 47 | Partial (skips if no dropdown status seed) |
| TC-D05 full lifecycle | 04-08 | 10,17,18,19 | Full |
| TC-D06 BUG-MSH-003 edit | 16 | 56 | Full |
| TC-D07 created_by forced | – | 71 | Full |
| TC-D08 is_locked not enforced | – | 21 | Full (documents current behaviour) |

### Tenancy

| Manual TC | V2 | Coverage |
|-----------|----|----------|
| TC-T01 tenant-scoped table | 90 | Full |
| TC-T02 cross-tenant id 404 | 91 | Full |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 16 | 15 | 1 | 0 | 100% |
| Negative | 20 | 17 | 3 | 0 | 100% |
| Dependency | 8 | 7 | 1 | 0 | 100% |
| Tenancy | 2 | 2 | 0 | 0 | 100% |
| **Total** | **46** | **41** | **5** | **0** | **100%** |

Targets — Negative 100% ✔ · Positive ≥90% ✔ (100%) · Dependency ≥90% ✔ (100%) · Tenancy 100% ✔ (P1 module).

**Partial-coverage list & limitations**
- TC-P15 (status filter): asserts page loads; does not count rows (row-content varies by tenant seed).
- TC-N16/N17 (403 gates): `markTestSkipped` when a super-admin/broad seed bypasses the gate — behaviour is environment-dependent; reflection assert in TC-N18 still proves the gate is the sole enforcer.
- TC-D04 (schedule RESTRICT): needs a `sys_dropdown_table` status id to build a schedule; skips defensively when absent.

---

## 3. Coverage-Score by requirement source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-FR / BC-BIZ) | 9 | 9 | 100% |
| State-Machine transitions (BC-SM) | 2 | 2 | 100% |
| Validation Rules (BC-VAL) | 14 | 14 | 100% |
| Integration Points (BC-REF / BC-INT) | 8 | 8 | 100% |
| Permissions (BC-AUTH) | 8 | 8 | 100% |

Every `Source`-tagged requirement item has ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Findings (defect scan)

| # | Check | Compared | Finding | Status |
|---|-------|----------|---------|--------|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | `class_assignments.*.type in:class,group` matches usage in service (`'class'`/`'group'`). No mismatch. | ✅ clean |
| 2 | Route registration | Blade `route('marksheet-generation.config-template.*')` vs `routes/web.php` | All referenced names registered (resource + `$modalEntities` loop). | ✅ clean |
| 3 | Gate vs Policy | Controller `Gate::authorize('tenant.msh-config-template.*')` vs `ConfigTemplatePolicy` | All 7 abilities present in policy. | ✅ clean |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | All non-audit columns fillable; matches. | ✅ clean |
| 5 | Cast vs DDL | Model `$casts` vs DDL types | `is_active/is_locked/is_best_of_n_enabled` → bool on TINYINT(1) ✔; `passing_percentage` → decimal:2 ✔. | ✅ clean |
| 6 | Service delegation | Controller body vs Service | `store/update/destroy` delegate to `ConfigTemplateService`. **But** `store/update` lack the `expectsJson()` JSON branch that sibling master controllers have → AJAX callers always get 302, never `{status,message,redirect}`. | ⚠ **DEV-MSH-CT-02** (verify in source) |
| 7 | State machine vs impl | BR-MSG-027 (`is_locked` immutable) vs controller/service | **No `is_locked` guard** in `update()`/`ConfigTemplateService::update()`; a locked template is still editable. | ⚠ **DEV-MSH-CT-01** (verify in source) |
| 8 | Validation vs FormRequest | Screen FR-02 fields vs `rules()` | All required fields present; `grading_schema_id` nullable per FR. | ✅ clean |
| 9 | Error message vs FormRequest | Expected vs `messages()` | No custom `messages()` → default Laravel text (assert on field keys, not prose). | ℹ note |
| 10 | Permissions vs Policy/Gates | Screen permission matrix vs Policy + gates | Matches; unseeded by default (**D39-MSH** env prereq). | ⚠ env |
| 11 | Integration FK vs migration | Requirement FKs vs DDL `FOREIGN KEY` | session/type/exam_group RESTRICT, grading SET NULL, children CASCADE, schedule RESTRICT — all present. | ✅ clean |

**Also surfaced (confirmed audit items):**
- **BUG-MSH-003** — `ExamGroupController::edit()` signature has no `ExamGroup` param (dead route-model binding). Proven by V2 `_56` / V1 `_16`.
- **SEC-MSH-003** — every FormRequest `authorize()` returns `true`. Proven by V2 `_53`.

> All ⚠ items are reported as **candidates ("verify in source")**, not asserted bugs; the proving tests document current behaviour so a future fix flips the canary assertion.

---

## 5. Notes
- Style: browser Dusk (no committed MSH sibling) — mirrors the `Class` golden reference + tenant scaffolding.
- Endpoint status codes verified via `sendJsonRequestFromBrowser` (Dusk `Browser` has no `assertStatus`).
- Cross-module / optional-dependency paths (`sch_classes`, `sys_dropdown_table`, second academic session, Spatie factory) are guarded with `markTestSkipped` so partial environments stay green.
