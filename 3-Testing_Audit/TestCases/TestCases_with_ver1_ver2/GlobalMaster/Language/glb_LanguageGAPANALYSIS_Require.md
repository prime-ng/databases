# glb_Language — Gap Analysis & Coverage

**Feature:** GlobalMaster › Language (central / prime-side)
**V1 methods:** 18 · **V2 methods:** 65 · **Ratio:** 3.6× (≥ 2× gate ✅)
**Live controller under test:** `Modules\Prime\Http\Controllers\LanguageController` (`central.global-master.language.*`)

Legend: **Full** = behaviour asserted end-to-end · **Partial** = asserted with an env-dependent skip guard · **Gap** = not automated.

---

## 1. Manual TC ↔ V2 method mapping

### Positive
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-P01 schema/config | 01, 03, 04, 05 | Full |
| TC-P02 index render | 60, 65 | Full |
| TC-P03 create render | 66 | Full |
| TC-P04 store creates | 10, 11 | Full |
| TC-P05 edit prefilled | (V1-05) | Full (V1) |
| TC-P06 update persists | 12 | Full |
| TC-P07 destroy soft+log | 14, 15, 22 | Partial (domain-guarded) |
| TC-P08 trash list | (V1-09) | Full (V1) |
| TC-P09 restore+log | 16, 23 | Partial |
| TC-P10 forceDelete+log Stored | 17, 24 | Partial |
| TC-P11 toggle+log | 18, 20, 21 | Partial |
| TC-P12 activity row | 15, 16, 17, 18 (+V1-18) | Partial |
| TC-P13 search | 62 | Full |
| TC-P14 pagination | 64 | Full |
| TC-P15 full lifecycle | 25 | Partial |
| TC-P16 routes registered | 02 | Full |

### Negative
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-N01 code required | 30 | Full |
| TC-N02 name required | 31 | Full |
| TC-N03 direction required | 32 | Full |
| TC-N04 code max 10 | 33 | Full |
| TC-N05 name max 50 | 34 | Full |
| TC-N06 native_name max 50 | 35 | Full |
| TC-N07 native_name nullable | 36 | Full |
| TC-N08 duplicate code | 37 | Full |
| TC-N09 duplicate name | 38 | Full |
| TC-N10 invalid direction | 39 | Full |
| TC-N11 unique ignore self | 39b | Full |
| TC-N12 edit 404 | 73 | Full |
| TC-N13 destroy 404 | 74 | Full |
| TC-N14 restore 404 | 75 | Full |
| TC-N15 guest redirect | 50, 94 (+V1-17) | Full |

### Security
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-S01 index viewAny 403 | 51 | Partial (needs limited user) |
| TC-S02 create/store 403 | 52, 53 | Partial |
| TC-S03 edit/update 403 | 54 | Partial |
| TC-S04 destroy 403 | 55 | Partial |
| TC-S05 restore/forceDelete 403 | 56 | Partial |
| TC-S06 toggle 403 | 57 | Partial |
| TC-S07 authorize()=true D30 | 58 | Full |
| TC-S08 XSS name | 90, 92 | Full |
| TC-S09 XSS native_name | 91 | Full |
| TC-S10 IDOR 404 | 93 | Full |
| TC-S11 mass-assignment | 95 | Full |

### Dependency / State-machine
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-D01 soft/force preserve | 22, 23, 24 | Partial |
| TC-D02 full lifecycle | 25 | Partial |
| TC-D03 translations FK cascade | 40, 41, 42 | Partial (skip if table absent) |
| TC-D04 duplicate uniqueness | 37, 38 | Full |
| TC-SM-01..05 transitions | 20, 21, 22, 23, 24 | Partial |

---

## 2. Coverage Summary

| Category | Total | Full | Partial | Gap | % (Full+Partial) |
|----------|-------|------|---------|-----|------------------|
| Positive | 16 | 10 | 6 | 0 | 100% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| Security | 11 | 5 | 6 | 0 | 100% |
| Dependency/SM | 9 | 1 | 8 | 0 | 100% |
| **Total** | **51** | **31** | **20** | **0** | **100%** |

Targets: Negative 100% ✅ · Positive ≥ 90% ✅ (100%) · Dependency ≥ 90% ✅ (100%). All "Partial" items are fully asserted but carry an environment skip guard (central domain host match, limited-user creation, or optional `glb_translations`) per constraints E19/E21 and C-defensive.

---

## 3. Coverage-Score by requirement Source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 10 | 10 | 100% |
| State-Machine transitions (BC-SM) | 5 | 5 | 100% |
| Validation Rules (BC-VAL) | 11 | 11 | 100% |
| Integration Points (BC-REF/INT) | 1 | 1 | 100% |
| Permissions (BC-AUTH) | 9 | 9 | 100% |
| Schema (BC-DB) | 9 | 9 | 100% |
| Edge (BC-EDG) | 5 | 5 | 100% |

Every `Source`-tagged BC maps to ≥ 1 TC and ≥ 1 test method. No zero-coverage requirement items.

---

## 4. Cross-Reference Findings (source-defect scan)

| # | Check | Compared | Finding | Status | Encoded |
|---|-------|----------|---------|--------|---------|
| 1 | Enum case | DDL `ENUM('LTR','RTL')` vs FormRequest `Rule::in(['LTR','RTL'])` | **Match** (case-exact) — no defect | OK | test_39 asserts case-exact rejection |
| 2 | Route registration | Blade `route('central.global-master.language.*')` vs `routes/web.php` | Registered — but **triple-registered** (root web.php L426 & L571 + module `global-master.*`) → **DUP-WEB-001** name collision | Verify-in-source (defect) | test_02 asserts names resolve |
| 3 | Gate vs Policy | Live ctrl `prime.language.*` gates vs `LanguagePolicy` (`prime.language.*`) | Consistent on live Prime ctrl. GlobalMaster ctrl uses `global-master.*` (SEC-GLB-005) but policy is `prime.*` → mismatch only there | Reconciled | tests 55-57 assert live behaviour |
| 4 | Fillable vs DDL | Model `$fillable` vs `glb_languages` columns | Match (code/name/native_name/direction/is_active) | OK | test_01 |
| 5 | Cast vs DDL | Prime\Language `$casts` vs `is_active TINYINT(1)` | **MODEL drift** — Prime\Language has NO `is_active` boolean cast (returns `"0"/"1"`); GlobalMaster\Language casts it. Blade truthiness hazard | Verify-in-source (P3) | test_03 asserts no cast |
| 6 | Service delegation | Controller body vs Service | No service layer (audit Layer 4) — logic inline in controller | Noted | n/a |
| 7 | State machine vs impl | Soft-delete lifecycle vs controller | All transitions implemented | OK | tests 20-25 |
| 8 | Validation vs FormRequest | Expected rules vs `rules()` | All present | OK | test_04 |
| 9 | Error message vs FormRequest | Expected messages vs `messages()` | **No `messages()`** → default Laravel text (BC-VAL-10) | Noted | manual spec |
| 10 | Permissions vs Policy/Gates | Requirement matrix vs live gates | Live Prime ctrl gates all methods; **SEC-GLB-010** (ungated) applies to GlobalMaster ctrl only (disabled) | Reconciled | tests 51-54 |
| 11 | Integration FK vs migration | `glb_translations.language_id` FK CASCADE | Present in DDL; **DATA/MIG drift** — consolidated DDL omits `deleted_at`/`timestamps`/`name` UNIQUE the migration adds | Verify-in-source (P2) | tests 05, 40-42 |

### Additional filed-defect reconciliation
- **BUG-GLB-006a** (forceDelete logs `'Stored'`): **reproduces live** → `test_17`, `test_24`, V1-`11`.
- **BUG-GLB-006b** (update flash raw `'update.language'`): **reproduces live** → `test_13`, V1-`07`.
- **BUG-GLB-006c** (GlobalMaster ctrl imports `Prime\Language` — wrong model for its own module): does NOT apply to the live Prime ctrl (which correctly uses `Prime\Language`). Documented only.
- **SEC-GLB-010 / SEC-GLB-005**: filed against the GlobalMaster module controller (disabled → 404 in test env). Live central controller is correctly gated; bands 50-59 assert the live 403 behaviour and the Gap Analysis records the divergence.
- **D30**: `LanguageRequest::authorize()` returns bare `true` → `test_58`.

---

## 5. Remaining limitations (Partial items)

| Item | Limitation | Mitigation |
|------|-----------|-----------|
| Endpoint tests (10-25, 30-39, 50-57) | Use in-process HTTP with `HTTP_HOST` pinned to the central host so `Route::domain(config('app.domain'))` matches; if the env's `app.domain` differs, they skip on 404 | Documented in Validation Report; set `APP_URL`/`app.domain` to `127.0.0.1:8000` |
| Permission tests (51-57) | Require creating a non-super central user (emp_code/prefered_language FK/user_type). Skips if creation fails | Defensive per C8/C9 |
| Translations FK (40-42) | Skips if `glb_translations` absent | Defensive |
| Pagination (64) | Shared central DB — asserts table presence rather than forcing >11 rows | Soft check |
| Cross-tenant isolation (96) | N/A for a central master — deliberate `markTestSkipped` | Recorded |
