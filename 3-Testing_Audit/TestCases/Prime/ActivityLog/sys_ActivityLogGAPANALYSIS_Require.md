# sys_ActivityLog — Gap Analysis & Coverage

**Feature:** Prime / ActivityLog (read-only) · **Test file:** `sys_ActivityLog_TestCas.php` · **Methods:** 25
**Screen type:** read-only log viewer → read-focused coverage (render / list / search / filter / pagination / permissions / empty state / guest redirect). No create/edit/delete matrix (CRUD stubs are orphaned).

## 1. Manual TC ↔ Dusk method mapping
| Manual TC | Dusk method(s) | Coverage |
|-----------|----------------|----------|
| MTC-01 schema | test_01, test_02, test_91, test_92 | Full |
| MTC-02 admin render | test_11, test_12, test_13, test_63 | Full |
| MTC-03 search event | test_14 | Full |
| MTC-04 search empty | test_15 | Full |
| MTC-05 index filter | test_16, test_70 | Full |
| MTC-06 permissions | test_50, test_51, test_53, test_52 | Full |
| MTC-07 UI controls | test_60, test_61, test_62 | Full |
| MTC-08 security/edge | test_90, test_72, test_71 | Full |
| (data source) | test_40, test_41 | Full |
| (routes) | test_10 | Full |

## 2. Coverage Summary (by TC category)
| Category | Total | Full | Partial | Gap | % |
|----------|-------|------|---------|-----|---|
| Positive | 15 | 15 | 0 | 0 | 100% |
| Negative | 8 | 8 | 0 | 0 | 100% |
| Dependency/Security | 4 | 4 | 0 | 0 | 100% |
| **Overall** | **27** | **27** | **0** | **0** | **100%** |

Gates: Negative 100% ✅ · Positive ≥90% ✅ (100%) · Dependency ≥90% ✅. Tenancy N/A (central feature — no tenant isolation surface).

## 3. Coverage-Score (by requirement Source)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 5 | 5 | 100% |
| Permissions (BC-AUTH) | 6 | 6 | 100% |
| DB/schema (BC-DB) | 5 | 5 | 100% |
| Edge (BC-EDG) | 2 | 2 | 100% |
| Config/routing (BC-CFG) | 1 | 1 | 100% |
| Integration (BC-INT/REF) | 2 | 2 | 100% |

Every Source-tagged BC has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan
| # | Check | Compare | Finding | Test |
|---|-------|---------|---------|------|
| 2 | Route registration | blade `route()` vs web.php | `activity-log` resource registered 3× (prime.×1, global-master.×2) — duplicate names (**DEV-PRM-AL-002**) | test_10 |
| 2 | Route registration | index.blade `data-search-url` vs routes | Points at `central.global-master.activity-log.index` (list route); `central.global-master.activity-log.search` does NOT exist (**DEV-PRM-AL-003**) | test_10 |
| 3 | Gate vs Policy | `search()` body vs other methods | `search()` has **no** `Gate::authorize` while `index()` requires `viewAny` — broken access control (**DEV-PRM-AL-001**) | test_52 |
| 4 | Fillable vs DDL | model `$fillable` vs migration columns | Match (subject_type, subject_id, user_id, event, properties, ip_address, user_agent) — OK | test_01 |
| 5 | Cast vs DDL | `properties` cast vs JSON column | array cast on json column — OK | test_01 |
| 6 | Controller vs view path | `view('prime::create'/'edit'/'show')` vs actual `activity-log/*.blade.php` | Wrong view namespace paths; `store/update/destroy` empty no-ops — orphaned CRUD (**DEV-PRM-AL-004**) | test_53 |
| 10 | Permissions vs matrix | gate keys | `prime.activity-log.{viewAny,create,update,delete}` + view `@can('prime.activity-log.view')` — consistent | test_51/53 |
| 11 | Integration FK | migration `foreign()` | `user_id` → `sys_users` restrictOnDelete — OK | test_01 |

## 5. Known Source Defects
| ID | Severity | Description | Proving test | Status |
|----|----------|-------------|--------------|--------|
| DEV-PRM-AL-001 | High | `search()` missing authorization gate | test_52 | Documents current behaviour |
| DEV-PRM-AL-002 | Low | Triple route registration (duplicate names) | test_10 | Asserts absence of gm search / presence of dupes' names |
| DEV-PRM-AL-003 | Medium | Autocomplete `data-search-url` points at list route; gm search name missing | test_10 | Asserts route names |
| DEV-PRM-AL-004 | Medium | Orphaned CRUD stubs return non-existent views / no-op | test_53 | Gate proven; view-error not exercised (403 precedes it) |
| DEV-PRM-AL-005 | Info | BR-PRM-012/023 audit: activity-log coverage <100% — coverage observation (activityLog() is called across many Prime controllers) | test_41 | Not asserted as bug |

## 6. Partial / not-covered (with rationale)
- **CRUD write matrix** — intentionally out of scope (read-only screen; stubs are orphaned). Gate presence on `create` verified; the downstream broken-view error is not exercised because `Gate::authorize` returns 403 first for unprivileged users (and success would require the missing view, out of scope).
- **Tenant activity_logs sink** — this feature is central-only; the tenant sink is a separate GlobalMaster feature.
- **Autocomplete AJAX UI** — the suggestion box is driven client-side against the (mis-wired) index route; endpoint behaviour is covered directly via the search JSON tests rather than the JS widget.

## Legend
Full = every step automated · Partial = automated with a stated limitation · Gap = manual only.
