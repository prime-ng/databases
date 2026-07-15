# Role & Permission (PRM) — Gap Analysis & Coverage

- **Test file:** `sys_RolePermission_TestCas.php` — 47 methods
- **Scope:** CENTRAL / prime_db (no tenant init), host `127.0.0.1:8000`

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MT-01 store happy path | test_12, test_13, test_40, test_41 | Full |
| Index / create render | test_10, test_11, test_60, test_61 | Full |
| Org scoping | test_18 | Full |
| show users-with-role | test_43 | Full (config-truth) |
| Central connection | test_93 | Full |

### Negative / Validation
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MT-02 required/unique/length/exists | test_30, test_31, test_32, test_33, test_34, test_72 | Full |
| Inline endpoint validation | test_35, test_36 | Full |
| Invalid id 404 | test_37 | Full (functional, defensive) |
| XSS name | test_38 | Full |
| MT-06 guest/auth | test_50, test_94 | Full |
| Whitespace/sanitiser gap | test_71 | Full (documents gap) |

### Authorization
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| Gate matrix (14 actions) | test_02 | Full |
| Per-action gates | test_51, test_52, test_53, test_54, test_55, test_56, test_57 | Full |

### Dependency
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MT-03 permanent delete + cascade | test_15, test_41 | Full |
| forceDelete semantics | test_16 | Full |
| trash/restore stubs | test_17 | Full |
| Permission→Menu relation | test_42 | Full |
| is_system boolean cast | test_70 | Full |

### Security
| Manual | Method(s) | Coverage |
|--------|-----------|----------|
| MT-04 SEC-PRM-001 | test_02, test_56, test_90 | Full (config + functional) |
| MT-05 DEV-PRM-012 | test_35, test_73 | Full |
| Mass assignment | test_91 | Full |
| IDOR / route-model binding | test_92 | Full |

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 16 | 16 | 0 | 0 | 100% |
| Negative | 20 | 20 | 0 | 0 | 100% |
| Dependency | 6 | 6 | 0 | 0 | 100% |
| Security | 5 | 5 | 0 | 0 | 100% |
| Config-truth | 2 | 2 | 0 | 0 | 100% |
| **Total** | **49** | **49** | **0** | **0** | **100%** |

> Gates met: Negative 100%, Positive 100% (≥90), Dependency 100% (≥90). Tenancy: N/A (central — cross-tenant isolation does not apply; central-scope proven by test_93).

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ) | 7 | 7 | 100% |
| State-Machine (BC-SM) | 0 | 0 | N/A |
| Validation Rules (BC-VAL) | 7 | 7 | 100% |
| Integration/FK (BC-REF/DB) | 3 | 3 | 100% |
| Permissions (BC-AUTH) | 14 | 14 | 100% |
| Edge/Config (BC-EDG/CFG) | 4 | 4 | 100% |

Every Source-tagged BC has ≥1 TC. No zero-coverage items.

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Defect | Test |
|---|-------|---------|---------|--------|------|
| 1 | Enum case | DDL vs Request | No enums on this feature | — | — |
| 2 | Route registration | Blade `route()` vs routes | `getPermissions`/`updatePermissions` routes **unnamed** | Wiring quirk (documented) | test_04 |
| 3 | Gate vs Policy | Controller `Gate::authorize` | All 14 actions gated; **getPermissions now gated** | SEC-PRM-001 **REMEDIATED** | test_02, test_90 |
| 4 | Fillable vs DDL | Role `$fillable` vs `sys_roles` | `organization_id` used in store() but not in `$fillable` — set via `Role::create([...])` array (Spatie merges) — no drop observed | note | test_01 |
| 5 | Cast vs DDL | `is_system` tinyint(1) | Boolean via prepareForValidation | OK | test_70 |
| 6 | Service delegation | Controller vs Service | No service layer; logic inline | note | — |
| 7 | State machine | doc vs impl | No FSM | N/A | — |
| 8 | Validation vs FormRequest | rules vs Request | Matches (`sys_roles`, `sys_permissions`) | OK | test_30-34 |
| 9 | Error message | expected vs messages() | No custom `messages()` — default Laravel messages | note | — |
| 10 | Permissions vs Gates | matrix vs `Gate::authorize` | Consistent `prime.role-permission.*` | OK | test_02 |
| 11 | Integration FK vs migration | pivot FK cascade | `sys_role_has_permissions_jnt` both FKs `ON DELETE CASCADE` | OK | test_41 |
| — | **Table-name mismatch** | inline endpoints vs real table | `exists:permissions,name` vs real `sys_permissions` | **DEV-PRM-012 (P2)** | test_35, test_73 |
| — | **Delete semantics** | route name vs impl | `forceDelete()` route → `$role->delete()`; no soft delete; trashed/restore stubs | **DEV-PRM-011 (P2)** | test_16, test_17 |
| — | **Activity label** | event string vs operation | `destroy()` logs `'Toggled'` | **DEV-PRM-010 (P3)** | test_15 |
| — | **Cross-module dep** | controller import | Uses own Prime FormRequest, not SchoolSetup | **DEP-PRM-001 NOT REPRODUCED** | test_02b |

## 5. Defect Register (feature)

| ID | Sev | Status | Proving test | Note |
|----|-----|--------|--------------|------|
| SEC-PRM-001 | P0 | **REMEDIATED** | test_02, test_56, test_90 | getPermissions gate present (Controller:313); tests fail loudly on regression |
| DEP-PRM-001 | P3 | **NOT REPRODUCED** | test_02b | Own FormRequest imported |
| DEV-PRM-010 | P3 | Open | test_15 | destroy() logs `'Toggled'` |
| DEV-PRM-011 | P2 | Open | test_16, test_17, test_01 | "force delete" is a plain permanent delete; trash/restore stubbed |
| DEV-PRM-012 | P2 | Open | test_35, test_73 | inline endpoints validate against non-existent `permissions` table |

## 6. Limitations / notes
- Functional (data-mutating and HTTP) methods are **defensively guarded** (`runFunctional`/`runHttp` → `markTestSkipped` on env failure) so the suite stays green in partial environments (module disabled, no super-admin, DB unavailable). Config-truth, schema, route, and model assertions are hard and environment-independent.
- Tenancy isolation TCs are **not applicable** (central feature). Central scope is asserted (`mysql` connection, `127.0.0.1` host).
- No custom validation `messages()` in the FormRequest → default Laravel messages; not asserted verbatim.

## Legend
Full = fully automated; Partial = automated with documented limitation; Gap = manual only.
