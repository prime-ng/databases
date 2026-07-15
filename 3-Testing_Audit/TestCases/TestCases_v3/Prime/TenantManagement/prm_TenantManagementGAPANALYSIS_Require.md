# prm_TenantManagement — Gap Analysis & Coverage

**Feature:** Prime → TenantManagement · **Screen type:** READ / COMPOSITE · **Test file:** `prm_TenantManagement_TestCas.php` (24 methods)
**Coverage model:** read-focused (render / listing / permissions / empty-state / guest / delegation) — no CRUD matrix because the screen has no create/edit/delete of its own.

---

## 1. Manual TC ↔ Automated method mapping

### Positive
| Manual TC | Automated method | Coverage |
|-----------|------------------|----------|
| MTC-01 (config/schema) | `test_..._01` | Full |
| MTC-03 (authorised render) | `test_..._10`, `_11`, `_12`, `_13`, `_15`, `_51` | Full |
| MTC-03 (stats not fabricated) | `test_..._14` | Full |
| MTC-03 (columns) | `test_..._60`, `_61` | Full |
| MTC-03 (action buttons) | `test_..._54` | Full |
| MTC-04 (pagination scope) | `test_..._62` | Full (params proven at source; live paging = Partial UI) |

### Negative / Defect
| Manual TC | Automated method | Coverage |
|-----------|------------------|----------|
| MTC-02 (guest redirect) | `test_..._50` | Full |
| MTC-05 (empty state) | `test_..._63` | Full (source-level) |
| MTC-06 (search/filter stub) | `test_..._64` | Full |
| MTC-06 (export stub) | `test_..._65` | Full |
| MTC-07 (address city_id) | `test_..._71` | Full |
| MTC-05 (colspan) | `test_..._72` | Full |

### Dependency / Security
| Manual TC | Automated method | Coverage |
|-----------|------------------|----------|
| MTC-09 (policy mismatch) | `test_..._53` | Full |
| MTC-08 (no mutation routes / delegation) | `test_..._70` | Full |
| MTC-01 (DDL drift) | `test_..._80` | Full (model-level; DB-level guarded) |
| Central scope | `test_..._91` | Full |
| Happy-path smoke | `test_..._90` | Full |
| Index gate | `test_..._52` | Full |

---

## 2. Coverage Summary
| Category | Total TC | Full | Partial | Gap | % Full |
|----------|----------|------|---------|-----|--------|
| Positive | 13 | 12 | 1 | 0 | 92% |
| Negative | 6 | 6 | 0 | 0 | 100% |
| Dependency/Security | 5 | 5 | 0 | 0 | 100% |
| **Total** | **24** | **23** | **1** | **0** | **96%** |

> The single Partial (TC-P13) is because live multi-page pagination cannot be forced deterministically on the shared central DB; the scoped page-parameter contract is proven at controller-source level and the container is asserted in-browser. Read-focused targets (render/permission/empty-state/guest 100%) are met.

## 3. Coverage-Score by requirement source (WP-F)
| Section | Covered | Total | % |
|---------|---------|-------|---|
| Render (Screen-Render) | 7 | 7 | 100% |
| Permissions (Screen-PM) | 5 | 5 | 100% |
| Empty state (Screen-EmptyState) | 2 | 2 | 100% |
| Search/Filter/Export (Screen-Search) | 3 | 3 | 100% |
| Delegation / no-mutation (Req-Route) | 1 | 1 | 100% |
| Schema/DDL (DDL + drift) | 3 | 3 | 100% |

Every `Source`-tagged item has ≥1 TC; no zero-coverage items.

---

## 4. Cross-Reference Defect Scan (11 checks)
| # | Check | Compared | Finding | ID | Proving test |
|---|-------|----------|---------|----|--------------|
| 1 | Enum case | DDL ENUM vs Request `in:` | No FormRequest on this screen | — | — |
| 2 | Route registration | Blade `route()` vs `routes/web.php` | All referenced routes (`central.prime.tenant.*`, `.tenant-group.*`) registered | OK | `test_..._70` |
| 3 | Gate vs Policy | Controller `Gate::authorize` vs Policy | **Mismatch** — controller uses `prime.tenant.viewAny`; dedicated policy uses `prime.tenant-management.viewAny` and is never invoked | **BUG-PRM-TM-001** | `test_..._53` |
| 4 | Fillable vs DDL | Model `$fillable`/custom cols vs DDL | Model declares `tenant_type/setup_status/rollover_*` absent from consolidated DDL | **BUG-PRM-TM-005** | `test_..._80` |
| 5 | Cast vs DDL | `$casts` vs DDL type | `is_active=>boolean` over `tinyint(1)` — correct | OK | `test_..._01` |
| 6 | Service delegation | Controller vs Service | No service; stats computed in controller (acceptable for read screen) | OK | `test_..._14` |
| 7 | State machine vs impl | — | No workflow on this read screen | N/A | — |
| 8 | Validation vs FormRequest | Requirement vs `rules()` | No input/validation on this screen | N/A | — |
| 9 | Error message vs FormRequest | — | N/A (no validation) | N/A | — |
| 10 | Permissions vs Policy/Gates | Requirement matrix vs Policy+Gate | Orphaned `prime.tenant-management.viewAny` permission (dup of #3) | **BUG-PRM-TM-001** | `test_..._53` |
| 11 | Integration FK vs migration | Requirement FK vs migration | `tenant_group_id`/`city_id` FKs RESTRICT — present | OK | `test_..._01` |

### Additional Blade-vs-Controller findings
| Finding | ID | Proving test |
|---------|----|--------------|
| Search box + filter dropdowns are non-functional stubs (dummy options, no `name`, no form action, controller reads no request) | **BUG-PRM-TM-002** | `test_..._64` |
| Export button has no handler | **BUG-PRM-TM-002b** | `test_..._65` |
| Tenant Address cell renders raw `city_id` instead of city name | **BUG-PRM-TM-003** | `test_..._71` |
| Empty-state `colspan="5"` under-spans 6–7 columns | **BUG-PRM-TM-004** | `test_..._72` |
| **BUG-PRM-009 NOT applicable** — stats are query-derived, no `rand()` | (verified clean) | `test_..._14` |

---

## 5. Legend
- **Full** — behaviour asserted end-to-end (browser DOM and/or verified source).
- **Partial** — contract asserted at source; runtime state not deterministically forceable on the shared central DB.
- **Gap** — no automated coverage (none here).
