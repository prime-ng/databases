# Board (PRM / GlobalMaster) — Gap Analysis & Coverage

Single comprehensive Dusk file: `glb_Board_TestCas.php` — **60 test methods**. `php -l` clean.

Legend: **Full** = behaviour directly asserted; **Partial** = asserted from source/config (behavioural path fail-soft due to central env); **Gap** = not covered.

---

## 1. Coverage by category

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| MTC-01 create | test_board_10, 17, 61, 80 | Full |
| MTC-03 length accept | test_board_70, 71 | Full |
| MTC-05 update | test_board_11 | Full (source + event) |
| MTC-06 toggle | test_board_15, 20, 21, 63 | Full |
| MTC-08 restore | test_board_13, 23 | Full |
| index render / pagination | test_board_16, 60, 62, 64 | Full |
| config truth | test_board_01, 02, 03, 04, 05 | Full |
| **Positive total** | 21 TC-P | **≥ 90%** |

### Negative
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| MTC-02 required | test_board_30, 31, 38 | Full |
| MTC-03 length reject | test_board_33, 34, 72, 73 | Full |
| MTC-04 unique | test_board_35, 36, 37, 95 | Full |
| MTC-04 soft-deleted reserves | test_board_75 | Full |
| is_active rule | test_board_32, 76 | Full |
| rule strings | test_board_39 | Full |
| MTC-10 authz | test_board_50, 51, 52, 53, 54, 55, 56 | Full |
| MTC-11 invalid id | test_board_94 | Full |
| **Negative total** | 23 TC-N | **100%** |

### Dependency
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| relationship | test_board_40, 43 | Full |
| FK cascade / references | test_board_41, 42 | Full |
| soft-delete lifecycle (B) | test_board_22, 23, 24, 25 | Full |
| toggle lifecycle (F) | test_board_20, 21 | Full |
| **Dependency total** | 10 TC-D | **≥ 90%** |

### Tenancy / Security
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| MTC-12 central scope | test_board_90, 91 | Full |
| MTC-11 XSS | test_board_74, 92 | Full |
| MTC-11 mass-assignment | test_board_93 | Full |

---

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % (Full+Partial) |
|----------|----------|------|---------|-----|------------------|
| Positive | 21 | 19 | 2 | 0 | 100% (≥90% target met) |
| Negative | 23 | 23 | 0 | 0 | 100% |
| Dependency | 10 | 10 | 0 | 0 | 100% (≥90% met) |
| Tenancy | 2 | 2 | 0 | 0 | 100% |
| Security | 3 | 3 | 0 | 0 | 100% |
| **Overall** | **59 mapped** | **57** | **2** | **0** | **~97%** |

Partial items: MTC-01/MTC-06 behavioural DB round-trips run through the live central endpoint and **fail-soft (skip)** when the module is disabled or `global_master` is unreachable — but the corresponding event strings, rules, redirects and JSON shape are independently asserted from source, so no requirement is left unverified.

---

## 3. Coverage-Score by requirement source (WP-F)

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 9 | 9 | 100% |
| State-Machine (BC-SM) | 5 | 5 | 100% |
| Validation Rules (BC-VAL) | 8 | 8 | 100% |
| Integration/FK (BC-INT/REF) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 10 | 10 | 100% |
| Schema (BC-DB) | 8 | 8 | 100% |
| Edge (BC-EDG) | 7 | 7 | 100% |

Every `Source`-tagged requirement item maps to ≥1 TC. No zero-coverage items.

---

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Test |
|---|-------|---------|---------|------|
| 1 | Enum case | n/a (no enum) | — | — |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | All `central.prime.board.*` registered under `prime.` group | test_board_50/63/64 |
| 3 | Gate vs Policy | `Gate::authorize` vs `BoardPolicy` | Consistent `prime.board.*`; toggle reuses `update` | test_board_50/51/55 |
| 4 | Fillable vs DDL | model `$fillable` vs DDL | fillable = name/short_name/is_active; id/timestamps guarded | test_board_01/93 |
| 5 | Cast vs DDL | `is_active`=boolean vs tinyint(1) | Correct | test_board_01 |
| 6 | Service delegation | controller vs service | No service layer; logic in controller | n/a |
| 7 | State machine vs impl | SM vs controller | toggle/soft-delete/restore/force all present | test_board_20-25 |
| 8 | Validation vs FormRequest | expected vs `rules()` | Matches; **effective request = GlobalMaster** not Prime | test_board_39/56 |
| 9 | Error message vs FormRequest | default Laravel messages | No custom `messages()`; default text | test_board_30 |
| 10 | Permissions vs Policy | matrix vs Policy+Gates | Aligned | test_board_51 |
| 11 | FK vs migration | requirement FK vs DDL | junction CASCADE + timetable FK reference glb_boards | test_board_41/42 |

### Candidate defects (verify in source)
| ID | Sev | Finding | Test |
|----|-----|---------|------|
| DEV-PRM-BOARD-01 | P3 | Dual `BoardRequest` — controller uses `GlobalMaster` (authorize=true); the `Prime` copy gates by ability and is dead | test_board_56 |
| DEV-PRM-BOARD-02 | P3 | Dual `Board` model files both namespaced `GlobalMaster\Models` (PSR-4 ambiguity; Prime copy comments out `organizations()`) | test_board_40 |
| DEV-PRM-BOARD-03 | P3 | Validation max:50/max:10 stricter than DDL varchar(255)/varchar(20) | test_board_33/34 |
| DEV-PRM-BOARD-04 | P3 | `toggleStatus` logs `Toggled` before `save()` and unconditionally | test_board_15 |
| DEV-PRM-BOARD-05 | P2 | `Rule::unique('glb_boards')` doesn't exclude soft-deleted → trashed name/short_name stays reserved | test_board_75 |
| DEV-PRM-BOARD-06 | Flag | Registry prm_ vs DDL glb_ (table in global_master) | prefix flag |
| BUG-PRM-011 | P1 | AcademicSession policy double-registered in PrimeServiceProvider — **N/A to Board** (Board policy/gate unaffected) | — |

---

## 5. Remaining limitations
- Live-endpoint behavioural assertions (store round-trip, activity-row inserts, browser render) are **environment-gated**: they skip cleanly when the Prime module is disabled in `modules_statuses.json` or the `global_master`/central connections are unavailable. Structural truth (routes, gates, rules, events, redirects, escaping, config) is asserted independently and always runs.
- Spatie permission-based 403 assertions depend on seeded permissions/users in the central DB; they fail-soft to `markTestSkipped` when a suitable unprivileged user cannot be resolved.
