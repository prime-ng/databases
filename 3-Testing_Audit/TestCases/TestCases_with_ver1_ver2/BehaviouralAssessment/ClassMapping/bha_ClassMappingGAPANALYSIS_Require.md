# ClassMapping — Gap Analysis & Coverage

**Feature:** BehaviouralAssessment › ClassMapping (app: ClassCategory) · **V1 = 14 methods · V2 = 35 methods (2.50×)**
**Style:** browser Dusk · **Scope:** tenant-side · **Live table:** `ba_class_category_jnt` · **Kind:** junction (store/toggle/destroy, no edit)

Legend: **Full** = behaviour asserted end-to-end · **Partial** = asserted at model/DB/source layer or defensively skipped · **Gap** = not covered.

---

## 1. Manual TC ↔ V2 Method Mapping

### Positive
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-P01 | 01 / 03 | Full |
| TC-P02 | 02 | Full |
| TC-P03 | 10 | Full |
| TC-P04 | 11 | Full |
| TC-P05 | 60 | Full |
| TC-P06 | 40 | Full |
| TC-P10 | 12 | Full |
| TC-P11 | 11 | Full |
| TC-P13 | 13 | Full (source-level) |
| TC-P60 | 12 | Full |
| TC-P61 | 61 | Full (source-level) |
| TC-P62 | 62 | Full (source-level) |

### Negative
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-N01 | 05 | Full |
| TC-N02 | 36 | Full |
| TC-N03 | 31 | Full |
| TC-N04 | 32 | Full |
| TC-N05 | 33 | Full |
| TC-N06 | 34 | Full |
| TC-N07 | 35 | Full |
| TC-N20 (BUG-BA-012) | 04 | Full (proves bug) |
| TC-N02b (VAL-BA-001) | 30 | Full (proves gap) |

### Dependency / State / Tenancy / Security
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-D01 (BUG-BA-012) | 22 | Full (proves hard delete) |
| TC-D02 | 23 | Full |
| TC-D03 | 40 | Partial (cross-module defensive skip if SchoolSetup absent) |
| TC-D04 (BUG-BA-007) | 41 | Partial (data-precondition proof; grid render is on the Rating screen) |
| TC-D05 (GAP-BA-CM-01) | 42 | Full (source + behaviour) |
| TC-D06 (GAP-BA-CM-02) | 43 | Full (source) |
| TC-D07 | 70 | Partial (needs two categoryless classes; else skip) |
| TC-D08 | 71 | Partial (async-JS fetch; env-dependent) |
| TC-SM01 | 20 | Full |
| TC-SM02 | 21 | Partial (async-JS fetch; env-dependent) |
| TC-T01 | 90 | Full |
| TC-S01 | 50 | Full |
| TC-S02 | 51 | Full |
| TC-S03 | 52 | Partial (limited-user provisioning defensive skip) |
| TC-S05 | 91 | Full (source) |
| TC-S06 | 92 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 12 | 12 | 0 | 0 | 100% |
| Negative | 9 | 9 | 0 | 0 | 100% |
| Dependency | 8 | 3 | 5 | 0 | 100% |
| State-machine | 2 | 1 | 1 | 0 | 100% |
| Tenancy | 1 | 1 | 0 | 0 | 100% |
| Security/Auth | 6 | 4 | 2 | 0 | 100% |
| **Total** | **38** | **30** | **8** | **0** | **100%** |

Targets met: Negative 100% (≥100), Positive 100% (≥90), Dependency 100% (≥90), Tenancy 100%.

**Partial-coverage limitations**
- TC-D03/40 — `markTestSkipped` when `sch_classes`/SchoolSetup is absent (cross-module).
- TC-D04/41 (BUG-BA-007) — proves the **data precondition** (unmapped class ⇒ 0 mappings). The actual blank-grid render lives on the Rating screen (`09-Ratings.md`); asserted there, referenced here.
- TC-D07/70 — `markTestSkipped` unless two classes are free of the chosen category.
- TC-D08/71 & TC-SM02/21 — JSON asserted via `executeAsyncScript`; if the page has no CSRF meta the fetch may 419; assertions are defensive (`assertStringNotContainsString('"success":true', …)` / substring presence).
- TC-S03/52 — `markTestSkipped` when a limited `sys_users` row can't be provisioned (FK to `glb_languages`).

---

## 3. Cross-Reference Defect Scan (11 checks)

Findings reported as **verify in source** (traced to cited lines); each maps to a proving test.

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `ENUM` vs Request `in:` | No enums on this junction; `is_active` is boolean. No gap. | — | 01 |
| 2 | Route registration | Blade `route('behavioural-assessment.class-categories.*')` vs `routes/web.php` | `store`/`toggleStatus`/`destroy` all registered (lines 55-57). Setup list route `.setup` registered. No gap. | — | 51, 62 |
| 3 | Gate vs Policy | Controller `Gate::authorize('…class-categories.*')` vs Policy | Uses **permission-string gates** (not ability→policy). Works via Spatie permission gate; no dedicated Policy class for this junction. | AUTH-BA-CM-01 | 51 |
| 4 | Fillable vs DDL | `$fillable` vs columns | All writable cols present. No gap. | — | 03 |
| 5 | Cast vs DDL | `$casts` vs type | `is_active → boolean` on TINYINT(1) — correct. No gap. | — | 03 |
| 6 | Service delegation | Controller vs Service | No service used (plain Eloquent). No duplication. | — | 10 |
| 7 | State machine vs impl | Screen "Preservation of Existing Grades" vs `destroy()` | `destroy()` has **no** `ba_assessment_ratings` guard and no block message — unmapping never blocked. | **GAP-BA-CM-01** | 42 |
| 8 | Validation vs FormRequest | Screen rules vs `rules()` | **No FormRequest** — inline `$request->validate()`; requirement "≥1 category" / multi-select not modelled (single pair). | VAL-BA-001 / **GAP-BA-CM-02** | 30, 43 |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Only the duplicate message is custom (`This category is already mapped to the selected class.`); asserted verbatim. Others use Laravel defaults. | — | 31 |
| 10 | Permissions vs Policy/Gates | Screen matrix vs gates | 8 ability strings + `setup.viewAny`; controller gates create/status/delete; blade `@can` on create/delete/status. Consistent. | — | 51, 52 |
| 11 | Integration FK vs migration | Screen FKs vs migration | `class_id`→`sch_classes` (cascade), `category_id`→`ba_categories` (cascade), `uq_ba_class_cat`. **Model omits `SoftDeletes`** despite migration `deleted_at` → `destroy()` hard-deletes. | **BUG-BA-012** | 02, 04, 22 |

**Cross-Reference Findings count: 6** — `BUG-BA-012` (NEW, model vs migration soft-delete), `GAP-BA-CM-01` (NEW, no grades-recorded guard), `GAP-BA-CM-02` (NEW, single-pair form / no session vs requirement grid), `VAL-BA-001` (audit-confirmed, no FormRequest), `BUG-BA-007` (audit-confirmed, empty grid), `AUTH-BA-CM-01` (verify-in-source, permission-string gates, no Policy). Plus doc `DOC-BA-001`. 3 audit-confirmed (VAL-BA-001, BUG-BA-007, DOC-BA-001) and 3 newly surfaced (BUG-BA-012, GAP-BA-CM-01, GAP-BA-CM-02) + 1 minor AUTH candidate — all reported as **verify in source**.

---

## 4. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: no-blank-evaluations, preservation-of-grades, dynamic-form-rendering) | 3 | 3 | 100% |
| State-Machine transitions (`Screen-SM`: active↔inactive, add→remove) | 2 | 2 | 100% |
| Validation Rules (`Screen-VR`: class required, category required, pair-unique) | 3 | 3 | 100% |
| Integration Points (`Screen-IP`: class→sch_classes, category→ba_categories, ratings-grid read) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: create/status/delete gates + setup + guest) | 5 | 5 | 100% |

**Requirement coverage notes (every `Source`-tagged item has ≥1 TC):**
- `Screen-BR` "No Blank Evaluations" (≥1 category per class, multi-select) — covered as a **documented gap** (`GAP-BA-CM-02`, test 43): the implementation adds one pair at a time and never enforces a per-class minimum.
- `Screen-BR` "Preservation of Existing Grades" — covered as a **documented gap** (`GAP-BA-CM-01`, test 42): no ratings guard on unmap.
- `Screen-BR` "Dynamic Form Rendering" — covered via the empty-mapping precondition (`BUG-BA-007`, test 41) with the grid render asserted on the Rating screen.
- `Screen "Academic Session"` field — no schema column exists (`GAP-BA-CM-02`, test 43).

No `Source`-tagged item has 0 tests.
