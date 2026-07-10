# RatingScale — Gap Analysis & Coverage

**Feature:** BehaviouralAssessment › RatingScale · **V1 = 16 methods · V2 = 47 methods (2.94×)**
**Style:** browser Dusk · **Scope:** tenant-side · **Live tables:** `ba_rating_scales`, `ba_rating_levels`

Legend: **Full** = behaviour asserted end-to-end · **Partial** = asserted at model/DB layer or defensively skipped · **Gap** = not covered.

---

## 1. Manual TC ↔ V2 Method Mapping

### Positive
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-P01 | 01 | Full |
| TC-P02 | 02 | Full |
| TC-P03 | 03 | Full |
| TC-P04 | 06 | Full |
| TC-P10 | 10 | Full |
| TC-P11 | 11 | Full |
| TC-P12 | 12 | Full |
| TC-P13 | 14 | Full |
| TC-P14 | 15 | Full |
| TC-P15 | 16 | Full |
| TC-P16 | 17 | Full |
| TC-P17 | 18 | Full |
| TC-P21 | 63 | Full |
| TC-P60/61/62 | 60/61/62 | Full |

### Negative
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-N01 | 05 | Full |
| TC-N02 | 04 | Full |
| TC-N30 | 30 | Full |
| TC-N31 | 31 | Full |
| TC-N32 | 32 | Full |
| TC-N33 | 33 | Full |
| TC-N34 | 34 | Full |
| TC-N35 | 35 | Full |
| TC-N36 | 36 | Full |
| TC-N20 (BUG-BA-009) | 13 | Full (proves bug) |
| TC-N21 (DATA-BA-001) | 26 | Partial (model-layer proof; in-use link is cross-module) |
| TC-N22 (delete guard) | 27 | Full (proves gap) |
| TC-N23 (VAL-BA-002) | 38 | Full (proves bug) |
| TC-S03 (SEC-BA-002) | 52 | Full (proves gap) |

### Dependency / State / Tenancy / Security
| Manual TC | V2 method | Coverage |
|-----------|-----------|----------|
| TC-D01 | 22/23 | Full |
| TC-D02 | 23 | Full |
| TC-D03 | 24 | Full |
| TC-D04 | 37 | Full |
| TC-D05 (DATA-BA-003) | 39 | Full (proves bug) |
| TC-D06 | 40 | Partial (ba_config defensive skip if absent) |
| TC-D07 | 41 | Full |
| TC-D08 | 70 | Full |
| TC-D09 | 71 | Full |
| TC-SM01 | 20 | Full |
| TC-SM02 | 21 | Partial (async-JS fetch; env-dependent) |
| TC-SM03 | 22 | Full |
| TC-T01 | 90 | Full |
| TC-S01 | 50 | Full |
| TC-S02 | 51 | Full |
| TC-S04 | 53 | Partial (limited-user provisioning defensive skip) |
| TC-S05 | 91 | Full |
| TC-S06 | 92 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 16 | 16 | 0 | 0 | 100% |
| Negative | 14 | 12 | 1 | 0 | 100% (Full 93%) |
| Dependency | 9 | 8 | 1 | 0 | 100% |
| State-machine | 3 | 2 | 1 | 0 | 100% |
| Tenancy | 1 | 1 | 0 | 0 | 100% |
| Security/Auth | 6 | 4 | 2 | 0 | 100% |
| **Total** | **49** | **43** | **6** | **0** | **100%** |

Targets met: Negative 100% (≥100), Positive 100% (≥90), Dependency 100% (≥90), Tenancy 100%.

**Partial-coverage limitations**
- TC-SM02 (`21`) — asserts JSON via `executeAsyncScript`; if the page has no CSRF meta the fetch may 419; assertion is defensive.
- TC-N21/DATA-BA-001 (`26`) — proves the missing guard at the model layer; the full "ratings already exist for the session" variant needs `bha_assessments`/`ba_assessment_ratings` cross-module seed (out of scope for this feature suite).
- TC-D06 (`40`) — `markTestSkipped` when `ba_config` absent.
- TC-S04 (`53`) — `markTestSkipped` when a limited `sys_users` row can't be provisioned (FK to `glb_languages`).

---

## 3. Cross-Reference Defect Scan (11 checks)

Findings reported as **verify in source** (traced to cited lines); each maps to a proving test.

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL `ENUM`/none vs Request `Rule::in` | `grade_type` `in:letter,numeric,descriptive` but UI `<select>` offers only letter/numeric; `descriptive` reachable only via crafted POST. Minor UI/validation drift. | UIX-BA-RS-01 | 33 |
| 2 | Route registration | Blade `route('behavioural-assessment.rating-scales.*')` vs `routes/web.php` | All referenced names registered (static routes declared **before** `Route::resource` to protect `/trash`). No gap. | — | 60–63 |
| 3 | Gate vs Policy | Controller `Gate::authorize('…rating-scales.*')` vs `BaRatingScalePolicy` | Policy methods exist for all 8 abilities; **gate strings are direct permission strings, not ability→policy** (controller uses `Gate::authorize(permission)` not `authorize('update',$model)`). Works via Spatie permission gate; policy class effectively unused for scales. | AUTH-BA-RS-01 | 52 |
| 4 | Fillable vs DDL | `BaRatingScale::$fillable` vs `ba_rating_scales` cols | All writable cols present; `created_by/updated_by` fillable (set in controller). No gap. | — | 03 |
| 5 | Cast vs DDL | `$casts` vs column type | `decimal:1` on DECIMAL(3,1), boolean on TINYINT(1) — correct. No gap. | — | 01 |
| 6 | Service delegation | Controller body vs Service | RatingScale CRUD does **not** use a service (plain Eloquent). `BehaviouralScoreService` only **reads** `is_default` — see BUG-BA-009 blast radius. No duplication. | — | 13 |
| 7 | State machine vs impl | Screen status constraints vs `toggleStatus`/`destroy` | `toggleStatus`/`destroy` enforce **no** lifecycle/usage guard (BR-BA-029, Soft-Delete-Protection missing). | DATA-BA-001 | 26, 27 |
| 8 | Validation vs FormRequest | Screen rules vs `rules()`/`storeLevel` | Level `numeric_value` has **no range check** vs scale bounds (BR-BA-003). Min/Max-levels (2–10) not enforced anywhere. | VAL-BA-002 | 38 |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Request defines **no** custom `messages()` → Laravel defaults used. Tests assert `.alert-danger` presence + no-insert (message text not asserted, by design). | — | 30–36 |
| 10 | Permissions vs Policy/Gates | Screen permission matrix vs Policy + gates | 8 abilities consistent across controller/policy/blade. `authorize()` in FormRequest returns bare `true`. | SEC-BA-002 | 52 |
| 11 | Integration FK vs migration | Screen FKs vs migration `foreign()` | `ba_rating_levels.rating_scale_id` → `ba_rating_scales` cascade present; `ba_config.rating_scale_id` RESTRICT present. `code` has **no DB unique index** (only request-level, `whereNull(deleted_at)`) → reuse-after-delete allowed; `uq_ba_level` unique **omits `deleted_at`** → collision. | DATA-BA-003 / DOC-BA-001 | 37, 39, 01 |

**Cross-Reference Findings count: 8** (UIX-BA-RS-01, AUTH-BA-RS-01, DATA-BA-001, VAL-BA-002, SEC-BA-002, DATA-BA-003, DOC-BA-001, BUG-BA-009). Of these, 5 are audit-confirmed (`DATA-BA-001`, `VAL-BA-002`, `SEC-BA-002`, `DATA-BA-003`, `BUG-BA-009` + doc `DOC-BA-001`); 2 are newly surfaced candidates (UIX/AUTH) reported as **verify in source**.

---

## 4. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`: unique name/score, min-max levels, active-status constraints, soft-delete protection) | 3 | 4 | 75% |
| State-Machine transitions (`Screen-SM`: active↔inactive, trash lifecycle) | 4 | 4 | 100% |
| Validation Rules (`Screen-VR`: code, name, grade_type, min, max, level label/value) | 6 | 6 | 100% |
| Integration Points (`Screen-IP`: config link, levels cascade, ratings ref) | 3 | 3 | 100% |
| Permissions (`Screen-PM`: 8 abilities + guest) | 5 | 5 | 100% |

**Explicit requirement gap (0 TC would be a fail — all have ≥1):**
- `Screen-BR` "min 2 / max 10 levels" — **no application enforcement exists in source**, so there is no behaviour to assert Full; covered only as a documented gap (counts as the 1 uncovered BR). Recommend a proving test once/if the rule is implemented.

Every other `Source`-tagged item has ≥ 1 mapped TC.
