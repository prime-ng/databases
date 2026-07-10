# Dropdown (PRM / Prime) — Gap Analysis & Coverage

**Test file:** `sys_Dropdown_TestCas.php` — 41 methods. **DB scope:** central / prime_db.

## 1. Manual TC ↔ Dusk method mapping
| Manual TC | Automated method(s) | Coverage |
|-----------|---------------------|----------|
| TC-M01 (schema truth) | test_dropdown_01, 02, 03, 04, 70, 71 | Full |
| TC-M02 (index render) | test_dropdown_60, 61, 62, 64 | Full |
| TC-M03 (create positive) | test_dropdown_10, 11, 32, 65 | Partial — end-to-end create needs a seeded dropdown_need (browser); model/route/rule truth covered |
| TC-M04 (validation) | test_dropdown_30, 31, 32, 33, 34 | Full (rule-level) |
| TC-M05 (toggle) | test_dropdown_33, 20 | Full (rule + lifecycle) |
| TC-M06 (soft delete/restore/force) | test_dropdown_20, 21, 22, 63 | Full |
| TC-M07 (permissions) | test_dropdown_50, 51, 52, 53, 54 | Full |
| TC-M08 (defects) | test_dropdown_12, 13, 14, 15, 34, 72, 73, 04 | Full (proven via source/DB) |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % (Full) |
|----------|----------|------|---------|-----|----------|
| Positive | 13 | 12 | 1 | 0 | 92% |
| Negative | 15 | 15 | 0 | 0 | 100% |
| Dependency/Lifecycle | 6 | 6 | 0 | 0 | 100% |
| Edge/Security/Tenancy | 7 | 7 | 0 | 0 | 100% |
| **Overall** | **41** | **40** | **1** | **0** | **97.6%** |

Gate check: Negative 100% ✅ · Positive ≥90% (92%) ✅ · Dependency ≥90% (100%) ✅ · Tenancy/route 100% ✅.

## 3. Partial-coverage notes / limitations
- **TC-M03 end-to-end create**: `store()` requires a valid `dropdown_need_id` and passes `canManageDropdownNeed`. A fully seeded browser create is environment-dependent (needs a `sys_dropdown_needs` row + junction). The suite proves the store rules, auto-ordinal logic location, model behaviour, and route registration; the browser HTTP round-trip is left to the manual TC to avoid a flaky seed dependency. Central DB write tests (`createDropdown`) are guarded with `markTestSkipped` when the central connection is unavailable.

## 4. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR / BC-BIZ) | 10 | 10 | 100% |
| State-Machine (BC-SM) | 4 | 4 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration/FK (BC-REF/INT) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 10 | 10 | 100% |
| Edge (BC-EDG) | 4 | 4 | 100% |

Every Source-tagged requirement item has ≥1 TC. No zero-coverage items.

## 5. Cross-Reference Defect Scan (11 checks)
| # | Check | Compare | Finding | DEV |
|---|-------|---------|---------|-----|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | Match (7 values, correct case). BUT `saveDropdownOption` uses only 5 (Datetime/Time missing) | **DEV-DROPDOWN-005** (verify in source) |
| 2 | Route registration | Blade `route('central.global-master.dropdown.*')` vs `routes/web.php` | All registered (index/store/edit/update/destroy/search/trashed/restore/forceDelete/toggle + AJAX/bulk) | none |
| 3 | Gate vs Policy | `Gate::authorize('prime.dropdown.*')` | String gates present per method; no Policy class inspected — relies on Gate::before/super-admin | verify (no per-key Policy) |
| 4 | Fillable vs DDL | `$fillable` vs columns | Match (ordinal,key,value,type,additional_info,is_active) | none |
| 5 | Cast vs DDL | `$casts` vs DDL type | is_active boolean/TINYINT ok; additional_info array/JSON ok; ordinal int/tinyint ok | none |
| 6 | Service delegation | Controller vs Service | No service layer — all logic in controller (duplicate create paths: store/saveDropdownOption/addBySelection/quickSave) | verify (duplication) |
| 7 | State machine vs impl | lifecycle vs controller | destroy/restore use inconsistent junction tables | **DEV-DROPDOWN-003** |
| 8 | Validation vs FormRequest | rules vs `rules()` | store inline rules vs DropdownRequest differ (store enforces global unique key; update ignores self) | **DEV-DROPDOWN-004** |
| 9 | Error message vs FormRequest | expected vs `messages()` | `key.unique` = "This key already exists." matches | none |
| 10 | Permissions vs Gates | matrix vs `Gate::authorize()` | mapDropdownsToNeed/removeMapping use `prime.dropdown-need.update` (cross-resource gate) | verify (intentional?) |
| 11 | Integration FK vs migration | FK vs migration | Junction FK → `sys_dropdown_table` (constraint #27); rename migration is a no-op | none (confirmed) |

### Additional discovered candidates (verify in source)
- **DEV-DROPDOWN-001** — consolidated `_prime_db_v4.sql` `sys_dropdown_table` omits `deleted_at`, but migration `softDeletes()` + model `SoftDeletes` require it. (Proven live by test_dropdown_04.)
- **DEV-DROPDOWN-002** — `destroy()` calls `activityLog($dropdown,'Trashed',…)` where `$dropdown` is declared only inside the `DB::transaction` closure → undefined outside → null subject logged. (test_dropdown_13)
- **DEV-DROPDOWN-006** — `unique(key,value)` / `unique(key,ordinal)` do not include `deleted_at`; a soft-deleted row still occupies the index, so recreating the same key+value collides. (test_dropdown_72)
- **DEV-DROPDOWN-007** — store/update emit no activity log (only Trashed/Restored/Toggled are recorded). (test_dropdown_12)
- **DEV-DROPDOWN-008** — `addBySelection()` (line ~964) and `quickSave()` (line ~1163) call `str_slug()`, removed since Laravel 6 → `Call to undefined function` fatal on those endpoints. (test_dropdown_15)

## 6. Legend
Full = every assertion for the TC is automated. Partial = core asserted, one aspect left to manual/env. Gap = not automated. DEV-### items are documented, not silently skipped; each has a proving test that asserts current (buggy) behaviour.
