# Tenant Group — Gap Analysis (`prm_TenantGroupGAPANALYSIS_Require.md`)

Single test file: `prm_TenantGroup_TestCas.php` — **39 test methods**. DB scope: CENTRAL (`prime_db`), no tenancy.

## 1. Manual TC ↔ Dusk method mapping

| Manual TC | Automated method(s) | Coverage |
|-----------|---------------------|----------|
| MTC-01 Create valid | test_10, test_17, test_72 | Full |
| MTC-02 Required validation | test_30, test_32, test_35, test_38 | Full |
| MTC-03 Duplicate short_name/name | test_34, test_37 | Full |
| MTC-04 Edit/update | test_15, test_16, test_41 | Full |
| MTC-05 Status toggle | test_14, test_92 | Full |
| MTC-06 Soft/restore/force + FK | test_11, test_12, test_13, test_42, test_43, test_44 | Full |
| MTC-07 Authorization | test_50, test_51, test_52, test_53 | Full |
| MTC-08 Security (XSS, 404) | test_90, test_91 | Full |
| MTC-09 Boundaries & optionals | test_70, test_71, test_72 | Full |
| Config truth (schema/model/request/gates/activity) | test_01, test_02 | Full |
| Relationships | test_45 | Full |

## 2. Coverage Summary (by TC category)

| Category | Total | Full | Partial | Gap | % |
|----------|-------|------|---------|-----|---|
| Positive (TC-P) | 24 | 23 | 1 | 0 | 96% |
| Negative (TC-N + TC-S) | 18 | 18 | 0 | 0 | 100% |
| Dependency (TC-D) | 4 | 4 | 0 | 0 | 100% |

**Targets met:** Negative 100% (target 100%), Positive 96% (target ≥90%), Dependency 100% (target ≥90%). Tenancy dimension **N/A** (single central DB — recorded, not a gap).

Partial: MTC-01 email dispatch/super-admin notification side effects (`TenantGroupCreatedMail`, `TenantGroupCreatedNotification`) are **not** asserted — they are external side effects wrapped in try/catch in the controller; the store test asserts persistence + activity only. Acceptable partial.

## 3. Coverage-Score by requirement Source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 6 | 6 | 100% |
| Validation Rules (BC-VAL) | 9 | 9 | 100% |
| Permissions (BC-AUTH) | 8 | 8 | 100% |
| Integration/FK (BC-INT/REF) | 3 | 3 | 100% |
| DB columns/constraints (BC-DB) | 11 | 11 | 100% |
| Edge cases (BC-EDG) | 3 | 3 | 100% |

Every `Source`-tagged BC has ≥1 TC.

## 4. Cross-Reference Defect Scan (11 checks)

| # | Check | Compared | Finding |
|---|-------|----------|---------|
| 1 | Enum case | No ENUM on this table | N/A |
| 2 | Route registration | Blade `route('central.prime.tenant-group.*')` vs `routes/web.php:134-138` | All present (resource + trashed/restore/forceDelete/toggleStatus) — OK |
| 3 | Gate vs Policy | Controller `Gate::authorize('prime.tenant-group.*')` | Uses string gates; permissions must be registered (Spatie). Verify seeded. |
| 4 | Fillable vs DDL | Model `$fillable` vs DDL columns | Match (10 fields) — OK |
| 5 | Cast vs DDL | `is_active`=boolean(tinyint1), `city_id`=integer(int) | OK |
| 6 | Service delegation | Controller has all logic inline (no Service) | OK (no service layer) |
| 7 | State machine vs impl | No status lifecycle beyond is_active toggle | N/A |
| 8 | Validation vs FormRequest | Request rules complete for all form fields | OK |
| 9 | Error message vs FormRequest | No custom `messages()` → Laravel defaults | OK (documented) |
| 10 | Permissions vs Gates | 7 gates used; consistent naming `prime.tenant-group.*` | OK |
| 11 | Integration FK vs migration | `city_id`→glb_cities RESTRICT; `prm_tenant.tenant_group_id`→prm_tenant_groups RESTRICT | Matches DDL — OK |

### Confirmed source findings (proving tests where applicable)
| ID | Sev | Finding | Evidence | Proving test |
|----|-----|---------|----------|--------------|
| **D25-PRM-002** | P2 | **NOT REPRODUCED.** Alleged `update()` uses `$request->all()`; actual source `TenantGroupController.php:99` uses `$tenantGroup->update($request->validated())` — identical protection to `store()` (`:43`). Test proves injected non-validated fields (`id`, `deleted_at`) are stripped. | Controller lines 43, 99 | test_15 |
| D25-PRM-003 | P3 | `update()` is the only mutating action with **no** `activityLog()` call (store/destroy/restore/forceDelete/toggleStatus all log). Audit trail gap. | Controller lines 96-101 (no activityLog) | test_16 |
| D25-PRM-004 | P2 | `tenant-group/index.blade.php` renders **cities** (`@forelse($cities as $city)`, city columns, `central.global-master.city` action URLs) instead of tenant groups — wrong/placeholder listing. Route `index` returns this view with no `$cities` passed by the controller (`index()` returns `view('prime::tenant-group.index')` with no data), so the page would error/empty. | index.blade.php lines 30-44; Controller::index line 24 | documented (browser render test_62 covers trash, not this broken index) |
| D25-PRM-005 | P4 | Redirect anchor typo/inconsistency: `store`/`update` redirect to `#tanent-group` (misspelled), `destroy` to `#tenant-group`. | Controller lines 69, 100, 118 | documented |
| D25-PRM-006 | P3 | `name` uniqueness enforced only in FormRequest — DDL `prm_tenant_groups` has a UNIQUE index on `short_name` only (`uq_tenantGroups_shortName`), none on `name`. Concurrent inserts can bypass. | DDL line 345; Request line 29 | test_02 (asserts index set) |
| D25-PRM-007 | P4 | `toggleStatus` calls `activityLog(..., 'Toggled')` **before** `save()`; a failed save still writes an audit row. | Controller lines 173-176 | documented |

> All findings above are **traced to source** (file+line), not speculative.

## 5. Legend
Full = every assertion in the manual TC is automated. Partial = core asserted, a peripheral side effect (email/notification) not asserted. Gap = no automation. N/A = dimension not applicable to a single central-DB feature.
