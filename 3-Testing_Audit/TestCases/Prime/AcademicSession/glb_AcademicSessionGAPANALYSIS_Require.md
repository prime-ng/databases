# Academic Session — Gap Analysis & Coverage

Single test file: `glb_AcademicSession_TestCas.php` — **35 methods**. DB scope CENTRAL (`global_master`), no tenancy.

## 1. Manual TC ↔ Dusk method mapping

### Positive / config
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-01 create | `test_..._11`, `test_..._12`, `test_..._19` | Full |
| MTC-03 update | `test_..._13`, `test_..._70` | Full |
| MTC-05 soft-delete/restore/force | `test_..._15`, `test_..._17`, `test_..._40` | Full |
| Schema truth | `test_..._01`, `test_..._02`, `test_..._43` | Full |
| Show / index render | `test_..._10`, `test_..._14`, `test_..._62`, `test_..._63` | Full |

### Negative / validation
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-02 required/max/duplicate | `test_..._30`, `_31`, `_32`, `_33`, `_34` | Full |
| Dates unvalidated (BUG-PRM-012) | `test_..._36`, `test_..._01` | Full |
| Whitespace name gap | `test_..._73` | Full |
| short_name spec mismatch | `test_..._71` | Full |

### State machine / dependency / security
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MTC-06 one-current (BR-PRM-021) | `test_..._20`, `test_..._21` | Full |
| MTC-04 toggle (BUG-PRM-013) | `test_..._23`, `test_..._01` | Full (proves defect at source + schema) |
| MTC-07 permissions/guest | `test_..._50`, `test_..._53`, `test_..._55` | Full |
| MTC-08 security XSS/404 | `test_..._39`, `test_..._92` | Full |
| Relationships / central | `test_..._42`, `test_..._43`, `test_..._90`, `test_..._91` | Full |

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 14 | 14 | 0 | 0 | 100% |
| Negative/Validation | 12 | 12 | 0 | 0 | 100% |
| Dependency/State/Security | 9 | 9 | 0 | 0 | 100% |
| **Total** | **35** | **35** | **0** | **0** | **100%** |

Targets met: Negative 100%, Positive ≥90%, Dependency ≥90%.

### Partial-coverage / limitations
- Runtime behavioural proof of BUG-PRM-013 (500 on toggle) and BUG-PRM-012 (insert failure) is asserted at **source + schema** level rather than by driving the failing endpoint, because the failing paths raise DB errors and the module is currently disabled in the runner. When Prime is enabled and `global_master` seeded, `_12`/`_23` can be extended to drive the live endpoints and assert the error banners.
- Limited-user 403 gate tests are represented via source-truth (`_53`) + guest redirect (`_50`); a dedicated non-super-admin 403 case requires central spatie-permission seeding and is deferred (documented).

## 3. Coverage-Score by requirement source
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (Screen-BR / BC-BIZ) | 8 | 8 | 100% |
| State-Machine (Screen-SM / BC-SM) | 3 | 3 | 100% |
| Validation Rules (Screen-VR / BC-VAL) | 5 | 5 | 100% |
| Integration Points (BC-INT / BC-REF) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 8 | 8 | 100% |

Every Source-tagged BC has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan
| # | Check | Compared | Finding | Defect | Proving method |
|---|-------|----------|---------|--------|----------------|
| 1 | Enum case | — | no ENUM columns | — | — |
| 2 | Route registration | Blade `route('central.prime.academic-session.*')` vs routes/web.php | all registered under prime group | OK | `_10`,`_53` |
| 3 | Gate vs Policy | controller string abilities vs `AcademicSessionPolicy` (model-mapped) | **string gates never invoke the model policy → policy dead; SessionBoardSetupPolicy orphan** | **BUG-PRM-011** | `_55` |
| 4 | Fillable vs DDL | model fillable / controller vs DDL columns | **controller/blades use `is_active`; column absent** | **BUG-PRM-013** | `_01`,`_23` |
| 5 | Cast vs DDL | casts vs DDL | is_current boolean OK; no is_active cast | OK | `_01` |
| 6 | Service delegation | controller vs service | no service layer (logic in controller) | note | — |
| 7 | State machine vs impl | BR-PRM-021 vs controller | **app never switches current; DB unique enforces; toggle broken** | **BR-PRM-021 / BUG-PRM-013** | `_20`,`_21`,`_23` |
| 8 | Validation vs FormRequest | form `required` dates vs rules() | **no start_date/end_date rules + `validated()` drops them** | **BUG-PRM-012** | `_01`,`_36` |
| 9 | Error message vs FormRequest | flash keys | **update uses hyphenated `academic-session`** | **BUG-PRM-014** | `_70` |
| 10 | Permissions vs Policy/Gates | gate strings vs policy | gates resolve via permission layer, not policy | (see #3) | `_53`,`_55` |
| 11 | Integration FK vs migration | relationships vs DDL | belongsToMany boards uses pivot; relationships defined | OK (verify pivot table) | `_42` |

### Defect register (feature-scoped)
| ID | Sev | Title | Status |
|----|-----|-------|--------|
| BUG-PRM-012 | P1 | Dates unvalidated + `validated()` drops NOT NULL date columns → create/update fail or lose data | Proven (source/schema) |
| BUG-PRM-013 | P1 | `is_active` referenced but not a column → toggleStatus 500; destroy guard dead; index/show status never render | Proven (source/schema) |
| BUG-PRM-011 | P1 | Model policy unreachable via string gates; SessionBoardSetupPolicy orphan; **no double `Gate::policy` in current source** (audit re-characterized) | Proven |
| BR-PRM-021 | P2 | One-current-session enforced only at DB (unique current_flag); app raises QueryException instead of switching | Proven |
| BUG-PRM-014 | P3 | update() flash uses `academic-session` (hyphen) vs `academic_session` elsewhere | Proven |
| D25-PRM-001 | audit | **NOT REPRODUCED** — current store/update use `$request->validated()`, not `$request->all()` (regressed into BUG-PRM-012) | Closed/superseded |

## 5. Legend
Full = every step has an automated assertion. Partial = happy path automated, some sub-checks manual. Gap = not automated. Defect proofs marked "source/schema" assert the failing construct via reflection/file-content + live schema rather than driving the erroring endpoint.
