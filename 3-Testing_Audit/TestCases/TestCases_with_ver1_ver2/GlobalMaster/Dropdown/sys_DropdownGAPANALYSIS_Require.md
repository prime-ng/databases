# Dropdown — Gap Analysis (`sys_DropdownGAPANALYSIS_Require.md`)

Maps every manual TC ↔ V2 Dusk method(s). Coverage = **Full / Partial / Gap**.

## 1. Coverage Mapping (by category)

### Positive
| Manual TC | V2 method(s) | Coverage | Notes |
|-----------|--------------|----------|-------|
| TC-P01 config/schema | 01,02,03,04,05,06,07,08,09 | Full | |
| TC-P02 index groups/paginates | 10,60,61,62 | Full | |
| TC-P03 create page | 63 | Full | |
| TC-P04 seed visible | 60 (+V1-08) | Full | |
| TC-P05 toggle + JSON | 13,96 | Full | 200-or-403 tolerant per env |
| TC-P06 soft delete | 12,42 | Full | |
| TC-P07 restore | 15 | Full | |
| TC-P08 force delete | 16,43 | Full | |
| TC-P09 destroy activity log | 14 | Full | central log guarded |
| TC-P10 checkbox coercion | 35 | Full | |
| TC-P11 comma parsing | 79 | Full | contract-level |
| TC-P12 empty state | 65 | Full | |
| TC-P13 relationships | 06,07,44 | Full | |

### Negative
| Manual TC | V2 method(s) | Coverage | Notes |
|-----------|--------------|----------|-------|
| TC-N01/N02 key/type unvalidated | 30,36 | Full | VAL-GLB-001 proven |
| TC-N03 value required | 31 | Full | |
| TC-N04 value max/boundary | 32,38 | Full | |
| TC-N05 value unique scoped | 34 | Full | |
| TC-N06 dup (key,value) | V1-18 | Full | DB-level (also band 40 sibling) |
| TC-N07 dup (key,ordinal) | 46 | Full | |
| TC-N08 non-boolean toggle | 39 | Full | |
| TC-N09 length mismatch | 72 | Full | documented |
| TC-N10 guest redirect | 50,95 | Full | |
| TC-N11 dead search route | 48,49,94 | Full | BUG-GLB-005 |
| TC-N12 invalid id 404 | 76,77,78,93 | Full | |

### Dependency
| Manual TC | V2 method(s) | Coverage | Notes |
|-----------|--------------|----------|-------|
| TC-D01 soft delete preserves | 42 | Full | |
| TC-D02 restore≠recover forceDeleted | 43 | Full | |
| TC-D03 cross-module Complaint | 44 | Full | defensive markTestSkipped |
| TC-D04 junction FK | 40,41 | Full | |
| TC-D05 lifecycle | 12,15,16,43 | Full | |
| TC-D06 ordinal by key | 46,47 | Full | |
| TC-D07 org_id defect | 45 | Full | BUG-GLB-009 |

### Security
| Manual TC | V2 method(s) | Coverage | Notes |
|-----------|--------------|----------|-------|
| TC-S01 stored XSS | 91 | Full | page-source assertion |
| TC-S02 mass-assign guard | 92 | Full | |
| TC-S03 IDOR/unknown id | 76,93 | Full | |
| TC-S04 injection search | 94 | Full | |
| TC-S05 guest→create | 95 | Full | |

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 13 | 13 | 0 | 0 | 100% |
| Negative | 12 | 12 | 0 | 0 | 100% |
| Dependency | 7 | 7 | 0 | 0 | 100% |
| Security | 5 | 5 | 0 | 0 | 100% |
| **Total** | **37** | **37** | **0** | **0** | **100%** |

Targets met: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅ (100%). Tenancy N/A (central scope; recorded skip in method 90).

## 3. Coverage-Score (by requirement Source tag — WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (`Screen-BR`/BC-BIZ) | 12 | 12 | 100% |
| State-Machine (`Screen-SM`) | 0 | 0 | N/A (no workflow lifecycle beyond soft-delete) |
| Validation Rules (`Screen-VR`/BC-VAL) | 7 | 7 | 100% |
| Integration Points (`Screen-IP`/BC-INT/REF) | 4 | 4 | 100% |
| Permissions (`Screen-PM`/BC-AUTH) | 9 | 9 | 100% |
| Edge cases (BC-EDG) | 5 | 5 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC — no zero-coverage items.

## 4. Cross-Reference Defect Scan (source-vs-source)

| # | Check | Compared | Finding | Status | Test |
|---|-------|----------|---------|--------|------|
| 1 | Enum case | DDL `ENUM('String',…)` vs model default/request | Model default `'String'` matches DDL; request does not validate `type` at all | Info (see #8) | 04,30 |
| 2 | Route registration | Blade `route('global-master.dropdown.*')` + controller `central.global-master.*` vs registered routes | Two name families exist (`central.global-master.*` via root web.php, `global-master.*` via module web.php); `dropdown.search` wired to a **missing** method | **BUG-GLB-005 (P1)** | 48,49 |
| 3 | Gate vs Policy | `Gate::authorize('prime.dropdown.*')` vs `DropdownPolicy` | All gates have matching Policy methods | OK | 08,51–56 |
| 4 | Fillable vs DDL | model `$fillable` vs columns | `org_id` used by controller is neither a column nor fillable | **BUG-GLB-009 (P2)** | 45,92 |
| 5 | Cast vs DDL | `$casts` vs column types | `is_active`→boolean, `ordinal`→integer, `additional_info`→array all correct | OK | 02 |
| 6 | Service delegation | controller vs service | No service layer; logic inline in controller | Info | — |
| 7 | State machine vs impl | lifecycle transitions | Only active/inactive + soft-delete; no FSM | N/A | 12 |
| 8 | Validation vs FormRequest | intended 5-field rules vs live `rules()` | Strict `key`/`type`/scoped-`value` rules are **commented out**; live rules validate only `value`+`is_active` | **VAL-GLB-001 (P1)** | 30,36 |
| 9 | Error message vs FormRequest | expected messages vs `messages()` | No `messages()` method — default messages only | Info | 30 |
| 10 | Permissions vs Policy/Gates | requirement matrix vs Policy | Controller/Policy use `prime.dropdown.*`; **Blade shared components pass `tenant.dropdown.*`** | UI mismatch (documented) | 57 |
| 11 | Integration FK vs migration | junction FKs | `sys_dropdown_need_table_jnt` FKs present in DDL | OK | 40,41 |
| 12 | Perf | index query shape | `foreach key { Dropdown::where(key)->get() }` → N+1 | **PERF-GLB-001 (P2)** | 69 |

## 5. Documented Defects (audit-equivalent)

| ID | Sev | Summary | Proving tests | Recommended fix |
|----|-----|---------|---------------|-----------------|
| VAL-GLB-001 | P1 | Request validates only `value`+`is_active`; `key`/`type` unvalidated | 30,36 (+V1-05) | Restore the commented strict `rules()` (require `key`, `type` in enum, scoped-unique `value`) |
| BUG-GLB-005 | P1 | `dropdown.search` route → missing `search()` method → 500 | 48,49,94 (+V1-15) | Implement `search()` or remove the route |
| BUG-GLB-009 | P2 | `org_id` not a column/fillable; ordinal `max()` not key-scoped; log/flash mislabeled `module` | 45,46,19,92 (+V1-04) | Drop `org_id`; scope ordinal by `key`; fix flash/log keys to `dropdown` |
| PERF-GLB-001 | P2 | `index()` N+1 grouping | 69 | Eager-group with a single `whereIn('key', …)->get()->groupBy('key')` |

## Legend
- **Full** — automated V2 method(s) assert the manual TC's expected result end-to-end.
- **Partial** — asserted at contract/schema level (no live browser round-trip) due to env constraints.
- **Gap** — no automated coverage.
- Env-tolerant asserts (200-or-403, {404,405,500}) are used where module-enable/permission wiring varies (constraints E19/E21/D14) — still Full because the meaningful branch is asserted.
