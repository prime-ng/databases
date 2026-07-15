# Rating Scales — Gap Analysis & Coverage (`bha_RatingScaleGAPANALYSIS_Require`)

**Feature:** BehaviouralAssessment / RatingScale · **Test file:** `bha_RatingScale_TestCas.php` (49 methods, `php -l` clean)
**Legend:** ✅ Full · 🟡 Partial · ❌ Gap

---

## 1. Manual TC ↔ Dusk Method Coverage

### Positive
| Manual TC | Description | Test Method(s) | Coverage |
|-----------|-------------|----------------|----------|
| TC-P01 | Scale schema/model/request truth | `_01` | ✅ |
| TC-P02 | Runtime `ba_` prefix truth | `_02` | ✅ |
| TC-P03 | Levels schema/model truth | `_03` | ✅ |
| TC-P04 | Create persists + flash | `_10` | ✅ |
| TC-P05 | Code uppercased | `_11` | ✅ |
| TC-P06 | Update persists | `_12` | ✅ |
| TC-P07 | Store level | `_14` | ✅ |
| TC-P08 | Update/delete level | `_15` | ✅ |
| TC-P09 | Show renders | `_16` | ✅ |
| TC-P10 | Masters list + levels count | `_17` | ✅ |
| TC-P11 | Active↔Inactive transitions | `_20` | ✅ |
| TC-P12 | Full lifecycle | `_46` | ✅ |
| TC-P13 | Toggle JSON + message | `_55` | ✅ |
| TC-P14 | Search filter | `_60` | ✅ |
| TC-P15 | Trash renders | `_62` | ✅ |
| TC-P16 | Breadcrumb | `_63` | ✅ |
| TC-P17 | Tenancy initialized | `_90` | ✅ |
| — | Policy↔permission mapping | `_54` | ✅ |

### Negative
| Manual TC | Description | Test Method(s) | Coverage |
|-----------|-------------|----------------|----------|
| TC-N01 | Required fields | `_30` | ✅ |
| TC-N02 | code max 30 | `_31` | ✅ |
| TC-N03 | name max 100 | `_32` | ✅ |
| TC-N04 | grade_type enum | `_33` | ✅ |
| TC-N05 | min_rating numeric/≥0 | `_34` | ✅ |
| TC-N06 | max_rating gt min | `_35` | ✅ |
| TC-N07 | duplicate code | `_36` | ✅ |
| TC-N08 | code reuse after soft-delete | `_37` | ✅ |
| TC-N09 | XSS in name escaped | `_38` | ✅ |
| TC-N10 | level out-of-range (VAL-BA-002) + empty label 422 | `_39` | ✅ |
| TC-N11 | invalid id 404 | `_70` | ✅ |
| TC-N12 | max == min rejected | `_72` | ✅ |
| TC-N13 | whitespace-only name | `_73` | ✅ |
| TC-N14 | guest redirect | `_50` | ✅ |
| TC-N15 | limited create 403 | `_51` | ✅ |
| TC-N16 | limited toggle 403 | `_52` | ✅ |
| TC-N17 | limited destroy 403 | `_53` | ✅ |
| TC-N18 | empty-state message | `_61` | ✅ |
| TC-N19 | authorize() bare true (SEC-BA-002) | `_92` | ✅ |
| TC-N20 | stored XSS in description | `_93` | ✅ |

### Dependency
| Manual TC | Sub-cat | Description | Test Method(s) | Coverage |
|-----------|---------|-------------|----------------|----------|
| TC-D01 | B | soft-delete + inactive + trash | `_40` | ✅ |
| TC-D02 | B | restore | `_41` | ✅ |
| TC-D03 | B | force-delete cascades levels | `_42` | ✅ |
| TC-D04 | D | level force-delete → ratings SET NULL | `_43` | 🟡 (asserts FK rule when no live referencing row; nulling proven when present) |
| TC-D05 | C | config RESTRICT | `_44` | 🟡 (asserts FK DELETE_RULE metadata; live block not forced) |
| TC-D06 | E | soft-delete not blocked when referenced (RS-GAP-02) | `_45` | ✅ |
| TC-D07 | F | full lifecycle | `_46` | ✅ |
| TC-D08 | E | referenced-scale deactivation not blocked (DATA-BA-001) | `_21` | ✅ |
| TC-D09 | G | cross-tenant isolation | `_91` | 🟡 (defensive skip when single tenant) |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 18 | 18 | 0 | 0 | 100% |
| Negative | 20 | 20 | 0 | 0 | 100% |
| Dependency | 9 | 6 | 3 | 0 | 67% Full / 100% addressed |
| **Overall** | **47** | **44** | **3** | **0** | **93.6% Full, 0 gaps** |

**Gate check:** Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% addressed ✅ (100% addressed; 3 partials are environment-gated defensive checks, none are gaps) · Tenancy on P0/P1 ✅ (module is P1; `_90/_91` present).

### Remaining partial-coverage list (with limitations)
| TC | Method | Limitation | Why acceptable |
|----|--------|-----------|----------------|
| TC-D04 | `_43` | Requires a live `ba_assessment_ratings` row referencing the level to prove nulling end-to-end; otherwise asserts the FK `DELETE_RULE=SET NULL` via `information_schema` | Synthesizing a full assessment graph is out of this screen's scope; FK-rule assertion is authoritative |
| TC-D05 | `_44` | Asserts `ba_config` → scale `DELETE_RULE` is RESTRICT/NO ACTION rather than forcing a live hard-delete throw | Force-delete of a referenced scale would raise a DB exception; FK metadata is the safe, deterministic proof |
| TC-D09 | `_91` | Skips when only one tenant domain is registered | IDOR isolation needs a 2nd tenant; guarded per constraint #9 |

---

## 3. Cross-Reference Defect Scan (11 checks)

| # | Check | Compared | Finding | Status / Proof |
|---|-------|----------|---------|----------------|
| 1 | Enum case | (no DDL `ENUM` — `grade_type` is VARCHAR + `Rule::in(['letter','numeric','descriptive'])`) | `descriptive` accepted by Request but absent from create/edit UI (only letter/numeric) | **RS-GAP-03** — proven `_18` |
| 2 | Route registration | Blade `route('behavioural-assessment.rating-scales.*')` vs `routes/web.php` + `RouteServiceProvider` | All rating-scale routes registered (resource + static toggle/trash/restore/force/levels); static-before-resource ordering correct | OK (no defect) |
| 3 | Gate vs Policy | Controller `Gate::authorize('tenant.behavioural-assessment.rating-scales.*')` vs `BaRatingScalePolicy` | All 8 abilities present in Policy and mapped to permission strings | OK — verified `_54` |
| 4 | Fillable vs DDL/migration | Model `$fillable` vs migration columns | Fillable matches migration (no `id`/timestamps in fillable, all business cols present) | OK |
| 5 | Cast vs DDL | Model `$casts` (`min/max decimal:1`, `is_default/is_active boolean`) vs migration types (decimal(3,1), boolean) | Consistent | OK |
| 6 | Service delegation | Controller body vs `BehaviouralScoreService` | `BehaviouralScoreService:49` falls back to `BaRatingScale::where('is_default',true)->first()` — relies on a single default that the controller never enforces | Cross-reference for **BUG-BA-009** — proven `_13` |
| 7 | State machine vs impl | Requirement "Active Status Constraints" (BR-BA-029) vs `toggleStatus`/`destroy` | No usage guard before deactivating/deleting a referenced scale | **DATA-BA-001** — proven `_21` (+ `_45`) |
| 8 | Validation vs FormRequest | Requirement (code max 10; level unique score/name; 2–10 levels) vs `rules()` | code max is 30 not 10; per-scale level count (2–10) not enforced; level numeric range not checked | **RS-GAP-01** (`_71`), **VAL-BA-002** (`_39`); level 2–10 min/max count = un-enforced (documented gap, see §5) |
| 9 | Error message vs FormRequest | Expected vs `messages()` | Request defines no custom `messages()` → Laravel defaults; tests assert error KEY presence, not text | OK (documented) |
| 10 | Permissions vs Policy/Gates | Requirement admin-only vs Policy + Gate | Consistent `tenant.behavioural-assessment.rating-scales.*` prefix across controller + policy + blade `@can` | OK |
| 11 | Integration FK vs migration | Requirement (levels belong to scale; config selects scale; ratings use levels) vs migration `foreign()` | Levels CASCADE, config RESTRICT, ratings SET NULL — all present and correct | OK — proven `_42/_43/_44` |
| + | Prefix (DDL vs runtime) | DDL `bha_*` vs migration/model/request `ba_*` | Doc prefix stale | **DOC-BA-001** — proven `_02` |
| + | FormRequest authorize | `authorize()` body | Returns bare `true` (systemic D30) | **SEC-BA-002** — proven `_92` |

---

## 4. Coverage-Score by Requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`) — unique code/name, ≥2/≤10 levels, one-default, active-status guard, soft-delete protection, unique level score | 5 | 6 | 83% |
| State-Machine transitions (`Screen-SM`) — Active→Inactive, Inactive→Active, referenced→Inactive(guarded) | 3 | 3 | 100% |
| Validation Rules (`Screen-VR`) — code, name, grade_type, min, max, level label/value/order | 7 | 7 | 100% |
| Integration Points (`Screen-IP`) — Configuration link, Ratings usage | 2 | 2 | 100% |
| Permissions (`Screen-PM`) — 8 abilities | 8 | 8 | 100% |

**Requirement item with 0 or partial TC (explicit gap):**
- **Screen-BR "Minimum & Maximum Levels" (2–10 per scale)** — the controller/FormRequest enforce **no** per-scale level-count rule (levels are added one-by-one via `storeLevel` with only `required|max:50|numeric` checks). This is an un-enforced business rule; no positive can prove enforcement because none exists. Documented as a coverage gap and a candidate defect (**RS-GAP-04**, see §5). All other BR items have ≥1 TC.

---

## 5. Discovered / Confirmed Defects (feature register)

| ID | Sev | Requirement | Description | Proving Test | Origin |
|----|-----|-------------|-------------|--------------|--------|
| DATA-BA-001 | P1 | BR-BA-029 | Active/referenced scale can be deactivated (and switched) mid-session — no usage guard | `_21`, `_45`, `_55` | Audit (confirmed) |
| SEC-BA-002 | P1 | D30 | `BaRatingScaleRequest::authorize()` returns bare `true` | `_92` | Audit (confirmed) |
| BUG-BA-009 | P2 | BR-BA-028 | Multiple scales can be `is_default=true` | `_13` | Audit (confirmed) |
| VAL-BA-002 | P2 | BR-BA-003 | Level `numeric_value` not range-checked vs `[min,max]` | `_39` | Audit (confirmed) |
| DOC-BA-001 | Doc | — | DDL doc prefix `bha_` stale vs live `ba_` | `_02` | Audit (confirmed) |
| RS-GAP-01 | Obs | Screen-BR | Requirement "code max 10" vs implementation max 30 | `_71` | Discovered |
| RS-GAP-02 | Obs | Screen-BR | Referenced scale soft-delete not blocked (Soft Delete Protection) | `_45` | Discovered |
| RS-GAP-03 | Obs | Screen-VR | `descriptive` grade_type valid but no UI option | `_18` | Discovered |
| RS-GAP-04 | Obs (candidate) | Screen-BR | Per-scale level count (2–10) never enforced; levels added individually with no min/max guard | — (no enforcement to assert; documented) | Discovered — **verify in source before filing** |

> **Note on DATA-BA-001 scope:** the audit's canonical enforcement location is `BaConfigController` (scale immutability once ratings exist). This suite proves the **RatingScale-side** manifestation: `toggleStatus`/`destroy` have no guard against operating on a Configuration-linked or default scale. The fix must cover both surfaces.
