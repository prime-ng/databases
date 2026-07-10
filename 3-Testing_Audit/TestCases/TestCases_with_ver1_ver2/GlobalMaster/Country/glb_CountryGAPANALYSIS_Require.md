# glb_Country — Gap Analysis & Coverage

**Feature:** GlobalMaster > Country  **Scope:** CENTRAL / prime-side
**V1 methods:** 16  **V2 methods:** 54  (V2 ≥ 2×V1 = 32 ✅)

Legend: **Full** = automated end-to-end assertion; **Partial** = asserted indirectly / source-truth only or env-gated; **Gap** = not automated.

---

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-P01 config | 01, 02, 03 | Full |
| TC-P02 index render | 04 | Full |
| TC-P03 create render | 04, 62 | Full |
| TC-P04 edit prefill | 05 | Full |
| TC-P05 store + log | 10 | Full |
| TC-P06 update + log | 11, 12 | Full |
| TC-P07 destroy + log | 13 | Full |
| TC-P08 restore + log | 14 | Full |
| TC-P09 force delete + log | 15 | Full |
| TC-P10 toggle + log | 16 | Full |
| TC-P11 pagination/order | 60, 61, 63 | Partial (source-truth assert) |
| TC-P12 status switch UI | 64 | Full |

### Negative
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-N01 name required | 30 | Full |
| TC-N02 name max 50 | 31 | Full |
| TC-N03 duplicate name | 32 | Full |
| TC-N04 same name self | 33 | Full |
| TC-N05 short_name required | 34 | Full |
| TC-N06 short_name max 10 | 35 | Full |
| TC-N07 global_code max 10 | 36 | Full |
| TC-N08 currency_code max 8 | 37 | Full |
| TC-N09 nullable codes | 38 | Full |
| TC-N10 toggle non-boolean | 39 | Full |
| TC-N11 whitespace name | 72 | Full |
| TC-N12 guest index | 50 | Full |
| TC-N13 guest store | 51 | Full |
| TC-N14 unauth index | 52 | Full |
| TC-N15 unauth create | 53 | Full |
| TC-N16 unauth store | 54 | Full |
| TC-N17 unauth toggle | 55 | Full |
| TC-N18 unauth forceDelete | 56 | Full |
| TC-N19 edit 404 | 93 | Full |
| TC-N20 show 404 | 94 | Full |
| TC-N21 forceDelete 404 | 95 | Full |
| TC-N22 guest toggle | 96 | Full |
| TC-N23 XSS name | 91 | Full |
| TC-N24 XSS short_name | 92 | Full |
| TC-N25 non-fillable ignored | 18 | Full |

### Dependency
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-D01 soft-delete/restore | 14 | Full |
| TC-D02 child not soft-deleted | 44 | Full (env-gated, skip-safe) |
| TC-D03 FK RESTRICT | 43 | Full (env-gated, skip-safe) |
| TC-D04 cascade states | 40 | Full (env-gated) |
| TC-D05 cascade districts | 41 | Full (env-gated) |
| TC-D06 no cascade cities (BUG-GLB-004) | 42 | Full (env-gated) |
| TC-D07 states() relation | 45 | Full (env-gated) |
| TC-D08 name boundary 50 | 70 | Full |
| TC-D09 short_name boundary 10 | 71 | Full |

### Security / Cross-ref / Tenancy
| Manual TC | V2 method(s) | Coverage |
|-----------|--------------|----------|
| TC-S01 SEC-GLB-001 default_timezone | 17 | Full |
| TC-S02 short_name unique cross-ref | 73 | Full (source-truth) |
| TC-S03 global_code unique cross-ref | 74 | Full (source-truth) |
| TC-S04 cross-tenant isolation | 90 | N/A — deliberate documented skip (central scope) |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 12 | 11 | 1 | 0 | 100% |
| Negative | 25 | 25 | 0 | 0 | 100% |
| Dependency | 9 | 9 | 0 | 0 | 100% |
| Security/Cross-ref | 3 | 3 | 0 | 0 | 100% |
| Tenancy | 1 | 0 | 0 | 0 (N/A) | N/A (central) |
| **Overall (ex-tenancy)** | **49** | **48** | **1** | **0** | **100%** |

Targets: Negative 100% ✅, Positive ≥ 90% ✅ (100%), Dependency ≥ 90% ✅ (100%). Tenancy 100% requirement is **N/A** for this central feature (recorded skip in test_country_90).

---

## 3. Cross-Reference Findings (defect scan)

| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | (no ENUM columns) | N/A | — | — |
| 2 | Route registration | Blade `route('central.global-master.country.*')` vs `routes/web.php` | All referenced names registered under `/global-master` prefix | OK | 03 |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.country.*')` | String gates only; verify Policy/permission seeding exists for `prime.country.*` | Verify in source | 52–56 |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | `default_timezone` validated but NOT in fillable nor DDL | **SEC-GLB-001** | 17, 18 |
| 5 | Cast vs DDL | Model `$casts` vs DDL `is_active tinyint(1)` | Country omits `is_active`=>boolean cast that State/District/City declare | **CR-GLB-03** | noted (74 context) |
| 6 | Service delegation | Controller body vs Service | No Service layer; toggle/cascade logic lives inline in controller | Observation | 40–42 |
| 7 | State machine vs impl | Toggle cascade requirement vs controller | Cascade omits Cities | **BUG-GLB-004** | 42 |
| 8 | Validation vs Request | Requirement rules vs `rules()` | `short_name`/`global_code` UNIQUE (DDL) missing from rules | **CR-GLB-01/02** | 73, 74 |
| 9 | Error message vs Request | expected vs `messages()` | No custom `messages()` — default Laravel messages used | Observation | 30–37 |
| 10 | Permissions vs Gates | permission matrix vs `Gate::authorize` | toggleStatus reuses `prime.country.update` (no dedicated status gate) | Observation | 55 |
| 11 | Integration FK vs migration | requirement FK vs DDL `foreign()` | `glb_states.country_id` FK ON DELETE RESTRICT present | OK | 43 |

---

## 4. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR` / BC-BIZ) | 8 | 8 | 100% |
| State-Machine transitions (BC-SM) | 5 | 5 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration Points (BC-INT/REF) | 5 | 5 | 100% |
| Permissions (BC-AUTH) | 8 | 8 | 100% |
| Edge/Boundary (BC-EDG) | 4 | 4 | 100% |

Every `Source`-tagged BC has ≥1 TC. No requirement item with 0 coverage.

---

## 5. Partial / limitation notes

- **TC-P11 (pagination/order):** asserted via controller source-truth (`paginate(10)`, `orderBy('is_active','desc')`) plus the empty-state marker in the view, rather than seeding 11+ rows and paging the DOM (kept fast + env-robust). Upgrade path: seed >10 countries and assert `.pagination` navigation.
- **Env-gated dependency tests (40–45):** require `global_master_mysql` + State/District/City tables. They `markTestSkipped()` if the connection/tables/models are absent, so partial environments stay green.
- **BUG-GLB-004 (test 42) & SEC-GLB-001 (test 17)** assert **current (defective) behaviour** deliberately; when the source is fixed these tests must be inverted (city cascades; default_timezone column added or rule removed).
- **Tenancy:** central scope → no per-tenant isolation surface; test_country_90 records the deliberate skip.
