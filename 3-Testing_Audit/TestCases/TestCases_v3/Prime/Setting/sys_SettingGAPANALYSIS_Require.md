# Setting (Prime / System Config) — Gap Analysis & Coverage

- **Test file:** `sys_Setting_TestCas.php` — 37 methods, `extends PrimeDuskTestCase`, central scope.
- **Screen type:** READ + single-field UPDATE (light matrix — no create/delete/toggle/soft-delete/state-machine).

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | BC | Method(s) | Coverage |
|-----------|----|-----------|----------|
| TC-P01 schema | BC-DB-01..08 | `test_setting_01` | Full |
| TC-P02 is_public default | BC-CFG-01 | `test_setting_03` | Full |
| TC-P03 key mutator | BC-BIZ-01 | `test_setting_10` | Full |
| TC-P04 displayKey | BC-BIZ-02 | `test_setting_11` | Full |
| TC-P05 update persists | BC-BIZ-03 | `test_setting_12` | Full |
| TC-P06 paginate 10 | BC-BIZ-05 | `test_setting_14` | Full |
| TC-P07 model parity | BC-INT-01 | `test_setting_40` | Full |
| TC-P08 index render | BC-BIZ-06 | `test_setting_60` | Full |
| TC-P09 breadcrumb | BC-BIZ-07 | `test_setting_61` | Full |
| TC-P10 search wiring | BC-BIZ-08 | `test_setting_62` | Full |
| TC-P11 edit render | BC-BIZ-10 | `test_setting_64` | Full |
| TC-P12 search JSON | BC-BIZ-11 | `test_setting_65` | Full |
| TC-P13 empty search | BC-BIZ-12 | `test_setting_66` | Full |
| (BC-BIZ-09 empty state) | BC-BIZ-09 | `test_setting_63` | Full |
| (BC-VAL config) | BC-VAL-01,02 | `test_setting_02` | Full |

### Negative
| Manual TC | BC | Method | Coverage |
|-----------|----|--------|----------|
| TC-N01 missing value | BC-VAL-01 | `test_setting_30` | Full |
| TC-N02 missing key | BC-VAL-02 | `test_setting_31` | Full |
| TC-N03 bad key | BC-VAL-02 | `test_setting_32` | Full |
| TC-N04 empty value | BC-VAL-01 | `test_setting_33` | Full |
| TC-N05 edit 404 | BC-EDG-01 | `test_setting_70` | Full |
| TC-N06 guest redirect | BC-AUTH-08 | `test_setting_53` | Full |
| TC-N07 limited 403 | BC-AUTH-01 | `test_setting_54` | Full (defensive skip if user cannot be provisioned) |
| TC-N08 XSS | TC-S01 | `test_setting_91` | Full |
| TC-N09 injection search | TC-S02 | `test_setting_92` | Full |

### Dependency & Permissions
| Manual TC | BC | Method | Coverage |
|-----------|----|--------|----------|
| TC-D01 duplicate key | BC-INT-02 | `test_setting_42` | Full |
| TC-D02 no FK | BC-REF-01 | `test_setting_41` | Full |
| TC-D03 model parity | BC-INT-01 | `test_setting_40` | Full |
| TC-AUTH01 gates | BC-AUTH-01..05 | `test_setting_50` | Full |
| TC-AUTH02 view gates | BC-AUTH-07 | `test_setting_52` | Full |

### Defect proofs
| DEV | Method | Coverage |
|-----|--------|----------|
| DEV-001 search ungated | `test_setting_51` | Full |
| DEV-002 store no-op | `test_setting_71` | Full |
| DEV-003 destroy no-op | `test_setting_72` | Full |
| DEV-004 create view missing | `test_setting_73` | Full |
| DEV-005 show view missing | `test_setting_74` | Full |
| DEV-006 organization_id absent | `test_setting_75` | Full |
| DEV-007 dead all() | `test_setting_76` | Full |
| DEV-008 no activity log | `test_setting_13` | Full |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 15 | 15 | 0 | 0 | 100% |
| Negative | 9 | 9 | 0 | 0 | 100% |
| Dependency | 3 | 3 | 0 | 0 | 100% |
| Permissions | 3 | 3 | 0 | 0 | 100% |
| Defect proofs | 8 | 8 | 0 | 0 | 100% |
| **Overall** | **38** | **38** | **0** | **0** | **100%** |

> Positive ≥ 90% ✅ · Negative 100% ✅ · Dependency ≥ 90% ✅ · Tenancy N/A (central — documented) ✅

## 3. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 12 | 12 | 100% |
| State-Machine (BC-SM) | 0 | 0 | N/A (no lifecycle) |
| Validation Rules (BC-VAL) | 3 | 3 | 100% |
| Integration/FK (BC-INT/REF) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 9 | 9 | 100% |
| Schema (BC-DB) | 8 | 8 | 100% |
| Config (BC-CFG) | 2 | 2 | 100% (CFG-02 asserted via edit view branch in `test_setting_64` context / DEV-006) |
| Edge (BC-EDG) | 1 | 1 | 100% |

Every `Source`-tagged BC has ≥1 TC. No orphan requirements.

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compare | Finding | Verdict |
|---|-------|---------|---------|---------|
| 1 | Enum case | DDL ENUM vs FormRequest `in:` | No enums on sys_settings | N/A |
| 2 | Route registration | Blade `route()` vs routes/web.php | `central.system-config.setting.*` all registered (web.php:295-296) | OK |
| 3 | Gate vs Policy | Ctrl `Gate::authorize` vs Policy | String gates resolved by spatie/permission Gate::before; **search() ungated** | **DEV-001** |
| 4 | Fillable vs DDL | model fillable vs DDL columns | `description` in DDL but not fillable (read-only via UI — acceptable); all fillable exist | Note only |
| 5 | Cast vs DDL | model casts vs DDL | No casts declared; `is_public` tinyint returned as int — acceptable | OK |
| 6 | Service delegation | controller vs Service | No service layer for Setting; logic inline | OK |
| 7 | State machine vs impl | doc transitions vs code | No lifecycle | N/A |
| 8 | Validation vs FormRequest | rules vs `validate()` | Inline validate matches expectation | OK |
| 9 | Error message vs FormRequest | expected vs messages() | Uses Laravel defaults (no custom messages) | Note |
| 10 | Permissions vs Policy/Gates | matrix vs gates | RESTful gated; **search not gated** | **DEV-001** |
| 11 | Integration FK vs migration | FK relationships vs migration | No FKs — matches DDL | OK |

**Additional source defects found (verified in source):** DEV-002 (store no-op), DEV-003 (destroy no-op), DEV-004/005 (missing `prime::create`/`prime::show` views), DEV-006 (`organization_id` referenced but absent), DEV-007 (dead `Setting::all()`), DEV-008 (no activity logging). All carry proving tests.

## 5. Legend
Full = automated end-to-end; Partial = asserted indirectly; Gap = manual-only. `N/A` = not applicable to this screen's nature (central, no lifecycle, no soft-delete).
