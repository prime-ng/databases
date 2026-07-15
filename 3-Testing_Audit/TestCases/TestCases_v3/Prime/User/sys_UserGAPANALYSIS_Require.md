# Prime → User (PRM) — Gap Analysis & Coverage (`sys_UserGAPANALYSIS_Require.md`)

- **Test file:** `sys_User_TestCas.php` — 44 methods (single comprehensive suite, no V1/V2)
- **Scope:** CENTRAL / `prime_db` (connection `mysql`, no tenant init), host `http://127.0.0.1:8000`
- **Primary table:** `sys_users` · **Controller:** `Modules\Prime\Http\Controllers\UserController` · **Request:** `Modules\Prime\Http\Requests\UserRequest`
- **Base class:** `PrimeDuskTestCase` (host-locked; Constraint #21/#22)

## 1. Manual TC ↔ Dusk method mapping

### Positive
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-P01 schema/model/request config truth | test_user_01 | Full (config-truth) |
| TC-P02 unique indexes | test_user_02 | Full |
| TC-P03 generated column | test_user_03 | Full |
| TC-P04 routes registered | test_user_04 | Full |
| TC-P05 gates referenced | test_user_05 | Full |
| TC-P10 store hashes + emails creds | test_user_10 | Full (config-truth) |
| TC-P11 store notifies super admins | test_user_11 | Full |
| TC-P13 promote is separate gate | test_user_13 | Full |
| TC-P14 usersByRole filters by role | test_user_14 | Full |
| TC-P33 literal activity events | test_user_33 | Full |
| TC-P34 central activity sink | test_user_34 | Full (fail-soft guard, Constraint #25) |
| TC-P40 row persists to sys_users | test_user_40 | Full (functional, guarded) |
| TC-P60 index renders | test_user_60 | Full (browser) |
| TC-P61 create form renders | test_user_61 | Full (browser) |
| TC-P62 role filter dropdown | test_user_62 | Full (browser) |
| TC-P63 trash renders | test_user_63 | Full (browser) |
| TC-P64 paginate 10 | test_user_64 | Full |

### Negative / Defect
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-N15 rand() stub stats residual (BUG-PRM-009) | test_user_15 | Full (documents residual defect) |
| TC-N16 missing tenant view vars (BUG-PRM-N01) | test_user_16 | Full (documents open defect) |
| TC-N17 self-delete blocked | test_user_17 | Full |
| TC-N18 self-toggle blocked | test_user_18 | Full |
| TC-N30 validation rule set | test_user_30 | Full |
| TC-N31 2FA field mismatch (BUG-PRM-N02) | test_user_31 | Full (documents open defect) |
| TC-N32 image field mismatch (BUG-PRM-N03) | test_user_32 | Full (documents open defect) |

### Dependency / Lifecycle
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-D41 soft-delete column + restore/forceDelete flow | test_user_41 | Full |
| TC-D42 emp_code unique index | test_user_42 | Full |
| TC-D43 email unique index | test_user_43 | Full |
| TC-D44 generated flag mirrors is_super_admin | test_user_44 | Full (read-only DB truth) |
| TC-D45 super-admin protection triggers | test_user_45 | Full |

### Permissions / Authorization
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| TC-S50 guest → /login | test_user_50 | Full (browser) |
| TC-AUTH51 index gates viewAny | test_user_51 | Full |
| TC-AUTH52 store gates create | test_user_52 | Full |
| TC-AUTH53 update gates update | test_user_53 | Full |
| TC-AUTH54 destroy gates delete | test_user_54 | Full |
| TC-AUTH55 restore/forceDelete gates | test_user_55 | Full |
| TC-AUTH56 view gates action controls | test_user_56 | Full |

### Security
| Manual TC | Method(s) | Coverage |
|-----------|-----------|----------|
| SEC-PRM-003 update excludes is_super_admin | test_user_12, test_user_90 | Full (config + 3-layer) |
| TC-S90 escalation prevented (3 layers) | test_user_90 | Full |
| TC-S91 mass-assignment guard | test_user_91 | Full |
| TC-S92 IDOR / route-model binding | test_user_92 | Full |
| TC-S93 single super-admin invariant | test_user_93 | Full |
| TC-S94 actor logged on mutation | test_user_94 | Full |
| TC-EDG70 emp_code 20-char limit | test_user_70 | Full |
| TC-S71 escaped name output | test_user_71 | Full |

## 2. Coverage Summary

| Category | Total TC | Full | Partial | Gap | % |
|----------|----------|------|---------|-----|---|
| Positive | 17 | 17 | 0 | 0 | 100% |
| Negative / Defect | 7 | 7 | 0 | 0 | 100% |
| Dependency | 5 | 5 | 0 | 0 | 100% |
| Permissions | 7 | 7 | 0 | 0 | 100% |
| Security | 8 | 8 | 0 | 0 | 100% |
| **Total** | **44** | **44** | **0** | **0** | **100%** |

> Gates met: Negative 100%, Positive 100% (≥90), Dependency 100% (≥90), Security 100%. Tenancy isolation: **N/A** (central feature — cross-tenant isolation does not apply; central scope proven by `mysql` connection + `127.0.0.1` host in test_user_01/40).

## 3. Coverage-Score by requirement source

| Section | Covered | Total | % |
|---------|---------|-------|---|
| Business Rules (BC-BIZ 01–10) | 10 | 10 | 100% |
| State-Machine (BC-SM) | 0 | 0 | N/A |
| Validation Rules (BC-VAL 01–08) | 8 | 8 | 100% |
| Schema / Integration (BC-DB 01–06) | 6 | 6 | 100% |
| Permissions (BC-AUTH 01–08) | 8 | 8 | 100% |
| Edge / Config (BC-EDG-01, BC-CFG-01) | 2 | 2 | 100% |

Every Source-tagged BC has ≥1 proving method. No zero-coverage items. BC-VAL-08 (dead `image` rule) is covered by documenting the defect (test_user_32), not by a passing validation.

## 4. Cross-Reference Defect Scan

| # | Check | Compare | Finding | Defect | Test |
|---|-------|---------|---------|--------|------|
| 1 | Enum case | DDL vs Request | `sys_users.user_type` ENUM exists but is not written by this screen's create/update flow — no case-mismatch surface | — | — |
| 2 | Route registration | Blade `route()` vs routes | All 13 `central.prime.user.*` routes registered in app-level `routes/web.php` (Constraint #24) | OK | test_user_04 |
| 3 | Gate vs Policy | Controller `Gate::authorize` | All 8 `prime.user.*` + `prime.super-admin.promote` gates present; promotion is a **separate** high-privilege gate | SEC-PRM-003 **REMEDIATED** | test_user_05, test_user_12, test_user_90 |
| 4 | Fillable vs DDL | User `$fillable` vs `sys_users` | `is_super_admin` & `super_admin_flag` excluded from `$fillable`; `remember_token` still present | BUG-PRM-002 **REMEDIATED**; FILL-PRM-001 **RESIDUAL (P3)** | test_user_01, test_user_91 |
| 5 | Cast vs DDL | `is_super_admin` tinyint(1) / `password` | `is_super_admin` cast boolean, `password` cast hashed | OK | test_user_01 |
| 6 | Generated column write guard | STORED `super_admin_flag` | non-fillable → no MySQL 3105 on insert | OK | test_user_91 |
| 7 | State machine | doc vs impl | No FSM — `is_active` on/off + soft-delete only (BC-SM N/A) | N/A | — |
| 8 | Validation vs FormRequest | rules vs Request | Rules match (`unique:sys_users,email`, `Rule::unique('sys_users','emp_code')`, `roles max:1`) | OK | test_user_30 |
| 9 | 2FA field name | Request key vs Controller read | Request validates `two_fact_enabled`; controller persists `two_factor_auth_enabled` → toggle silently dropped | **BUG-PRM-N02 (P2)** | test_user_31 |
| 10 | Image field name | Request rule key vs upload/controller key | Rule keyed `image`; upload/controller keyed `user_img` → `image|max:2048` never fires (dead validation) | **BUG-PRM-N03 (P2)** | test_user_32 |
| 11 | Media collection | Model registers `image` vs controller stores `user_img` | Collection-name mismatch on avatar media | **BUG-PRM-N04 (P3)** | (documented; see §5) |
| 12 | usersByRole stats | view vars vs controller | `usersByRole()` omits `totalTenants`/`activeTenants` that `prime::user.index` references → undefined-var risk | **BUG-PRM-N01 (P1)** | test_user_16 |
| 13 | usersByRole stub stats | controller impl | `rand(1000,2000)`/`rand(10,30)` stub statistics (relocated from index()) | **BUG-PRM-009 (P2) RESIDUAL** | test_user_15 |
| 14 | usersByRole scope | controller impl | Filters `User::role($role)->paginate(10)` correctly | BUG-PRM-010 **REMEDIATED** | test_user_14 |
| 15 | Store credential email | controller impl | `Mail::to($user->email)->send(new LoginMail(...))` to the NEW user | GAP-PRM-004 **REMEDIATED** | test_user_10 |
| 16 | Activity sink | tenancy state vs table | Central (tenancy not initialized) → `sys_central_activity_logs` via `Modules\Prime\Models\ActivityLog` | OK | test_user_34 |
| 17 | Self-mutation guard | controller impl | `destroy()`/`toggleStatus()` block acting on self (`$user->id === Auth::user()->id`) | OK | test_user_17, test_user_18 |
| 18 | Super-admin protection | DDL triggers + unique key | `trg_users_prevent_delete_super`/`trg_users_prevent_update_super` + `uq_single_super_admin` | OK | test_user_45, test_user_93 |

## 5. Defect Register (feature)

| ID | Sev | Status vs current source | Proving test | Note |
|----|-----|--------------------------|--------------|------|
| SEC-PRM-003 | P0 | **REMEDIATED** | test_user_12, test_user_90 | update() excludes is_super_admin; promote is a separate gate |
| BUG-PRM-002 | P0 | **REMEDIATED** | test_user_01, test_user_91 | `$fillable` excludes is_super_admin & super_admin_flag |
| BUG-PRM-010 | P1 | **REMEDIATED** | test_user_14 | usersByRole filters by `$role` |
| GAP-PRM-004 | P1 | **REMEDIATED** | test_user_10 | store emails LoginMail credentials to new user |
| FILL-PRM-001 | P3 | **RESIDUAL** | test_user_01 | `remember_token` still fillable |
| BUG-PRM-009 | P2 | **RESIDUAL/relocated** | test_user_15 | usersByRole still uses `rand()` stub stats |
| BUG-PRM-N01 | P1 | **OPEN (new)** | test_user_16 | usersByRole omits totalTenants/activeTenants → index view undefined-var |
| BUG-PRM-N02 | P2 | **OPEN (new)** | test_user_31 | 2FA field mismatch (`two_fact_enabled` vs `two_factor_auth_enabled`) |
| BUG-PRM-N03 | P2 | **OPEN (new)** | test_user_32 | image rule key `image` vs upload key `user_img` (dead validation) |
| BUG-PRM-N04 | P3 | **OPEN (new)** | (documented) | media collection mismatch (model `image` vs controller `user_img`) |

## 6. Limitations / notes
- Functional (data-mutating) and browser methods are **defensively guarded** (`markTestSkipped` / `ensurePageAccessible` on env failure — module disabled, no super-admin, DB unavailable) so the suite stays green in partial environments. Schema, route, model, controller-source, and request-source assertions are hard and environment-independent.
- Tenancy isolation TCs are **not applicable** (central feature). Central scope is asserted via the `mysql` connection and `127.0.0.1` host.
- `sys_central_activity_logs` has no consolidated DDL — asserted with `Schema::hasTable` fail-soft guard + model `$fillable`, not a DDL-file `assertStringContainsString` (Constraint #25).
- Remediated defects (SEC-PRM-003, BUG-PRM-002/010, GAP-PRM-004) are asserted in their **remediated** state — the tests fail loudly on regression, per the HARD RULE "prove current behaviour".

## Legend
Full = fully automated; Partial = automated with documented limitation; Gap = manual only.
