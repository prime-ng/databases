# Prime (PRM) — Mode X Complete Technical Audit
**Date:** 2026-06-29 | **Auditor:** pa-technical-auditor | **Module:** Prime (PRM) | **Type:** Central

---

## Audit Scope

Mode X = Layer A (12-layer deep audit) + Mode B (FRD gap analysis) + Mode C (business-rule enforcement) + Mode G (pre-deploy gate) + scoped Mode D (systemic pattern detectors).

**Module context:** Central platform administration console on `prime_db`. NOT a tenant module — `InitializeTenancyByDomain` middleware does NOT apply to central routes. Owns `prm_*` (10 tables), `sys_*` (12 tables), `bil_*` (5 tables) in `prime_db`. Reads from `global_db` for reference data.

**Source files examined:** 22 controllers, 27 models (+1 stale duplicate), 7 FormRequests, 16 policy files, 27 migrations, 1 app/Jobs file, FRD (12 REQs, 13 BRs), module-knowledge, known-issues.md.

---

## Executive Summary

| Dimension | Result |
|-----------|--------|
| Health Score | **40 / 100 (P0-capped; uncapped ≈ 88)** |
| Deploy Verdict | **NO-GO** |
| P0 Findings | 4 |
| P1 Findings | 9 |
| P2 Findings | 9 |
| P3 Findings | 3 |
| Resolved Issues | 3 (BUG-PRM-003, BUG-PRM-008, GAP-PRM-002) |

The Prime module has the strongest structural implementation of any audited module — proper `DB::transaction` usage in plan assignment, `$request->validated()` in TenantController, well-structured policy registration, and correct tenancy isolation via `$tenant->run()`. However, four P0 security defects must be fixed before any production deployment: plaintext database credentials, an escalation path to Super Admin via the user update API, an ungated role-permissions endpoint, and a hardcoded root password in the provisioning job.

---

## Mode A — 12-Layer Deep Audit

### Layer 1: DDL Schema Integrity

**Files:** `Modules/Prime/database/migrations/` (27 files)

**Findings:**

`MIG-PRM-001 (P1)` — Migration rollback names wrong table.
`2025_10_10_000010_create_tenants_table.php` line 61: `Schema::dropIfExists('tenants')`. The table is created as `prm_tenant` (line 18), not `tenants`. On rollback, this is either a no-op (if no `tenants` table exists) or silently destroys the wrong table.

`D29-PRM-001 (P2)` — ENUM column in sys_users migration.
`2025_10_17_101827_create_users_table.php` line 26: `$table->enum('status', ['ACTIVE', 'INVITED', 'DISABLED'])`. Platform baseline is ~476 ENUM columns; this is within norm but adds to the count.

**Verified Good:**
- `sys_users.super_admin_flag` is a `STORED` generated column (`CASE WHEN is_super_admin = 1 THEN 1 ELSE NULL END`) with `UNIQUE` constraint — correct D36 use to enforce single super admin.
- Two MySQL triggers (`trg_users_prevent_delete_super`, `trg_users_prevent_update_super`) provide defence-in-depth against deleting or demoting the super admin at DB level.
- `prm_billing_cycles` migration includes `softDeletes()` — consistent with BillingCycle model (module-knowledge DB-03 claim is inaccurate; migration has deleted_at).
- All `prm_*` and `bil_*` tables have correct auto-increment / UUID PKs and properly declared FKs.

---

### Layer 2: Migration ↔ DDL ↔ Model Three-Way Reconcile

**Findings:**

`BUG-PRM-DUP (P2)` — Stale root-level model file.
`Modules/Prime/Models/DropdownNeed.php` exists outside the correct `app/Models/` directory. This file is not autoloaded and is a dead artifact. Confirmed as BUG-PRM-007 in module-knowledge.

`FILL-PRM-001 (P2)` — Generated column `super_admin_flag` is in User model `$fillable`.
`Modules/Prime/app/Models/User.php` — `$fillable` array includes `'super_admin_flag'`. Writing to a STORED generated column via Eloquent triggers a MySQL error (3105: The value specified for generated column is not allowed). No code path currently writes `super_admin_flag` directly, but the fillable declaration is incorrect and could cause runtime errors if it receives user-supplied data.

**Verified Good:**
- `prm_tenant_domains` migration (`create_domains_table.php`) correctly creates the table with FK to `prm_tenant.id`.
- `sys_roles` has `deleted_at` added by separate migration `2026_03_21_000001_add_deleted_at_to_sys_roles_table.php` — D38 CLEAN.
- `sys_users` migration and User model agree on all column names.

---

### Layer 3: Model Mass-Assignment, Casts, and Relationships

**Findings:**

`BUG-PRM-001 (P0)` — `prm_tenant_domains.db_password` stored in plaintext.
`Modules/Prime/app/Models/Domain.php` — Model has only `$table = 'prm_tenant_domains'`; no `$casts` array, no `encrypted` cast for `db_password`. `TenantDomainController::store()` line 73 calls `Domain::create($validated)` where `$validated` includes the raw plaintext `db_password`. Any read of `prm_tenant_domains` exposes database credentials in plaintext. Violates BR-PRM-006.

`BUG-PRM-002 (P0)` — `is_super_admin` and `super_admin_flag` in User `$fillable`.
`Modules/Prime/app/Models/User.php` `$fillable`:
```php
'is_super_admin', 'super_admin_flag', 'remember_token'
```
All three are mass-assignable. `remember_token` in `$fillable` creates session fixation risk. Combined with the explicit assignment in UserController::update() (SEC-PRM-003 below), this represents a complete privilege escalation path.

**Verified Good:**
- `'password' => 'hashed'` cast exists — password column is hashed via Laravel's cast before storage.
- TenantPlan, TenantPlanRate, TenantPlanBillingSchedule models have correct relationship definitions and table names.
- Tenant model implements `TenantWithDatabase`, `HasDatabase`, `HasDomains` — BR-PRM-010 SATISFIED.

---

### Layer 4: FormRequest Validation

**Files:** 7 FormRequests in `Modules/Prime/app/Http/Requests/`

**Findings:**

`D30-PRM (P2)` — All 7 FormRequests return bare `true` in `authorize()`.
`UserRequest`, `BoardRequest`, `AcademicSessionRequest`, `TenantGroupRequest`, `DropdownRequest`, `TenantPlanRequest`, `TenantRequest` — every `authorize()` method returns bare `true`. Rate: 7/7 (100%), above the platform baseline of 90%. No resource-level IDOR check at the FormRequest layer for any PRM operation.

`D25-PRM-001 (P2)` — `AcademicSessionController::store()` and `update()` use `$request->all()`.
`Modules/Prime/app/Http/Controllers/AcademicSessionController.php` lines 42 and 80: `AcademicSession::create($request->all())` and `$academicSession->update($request->all())`. An `AcademicSessionRequest` FormRequest is injected but then bypassed by calling `$request->all()` directly. Unvalidated / un-whitelisted fields can reach the model.

`D25-PRM-002 (P2)` — `TenantGroupController::update()` uses `$request->all()`.
Line 99: `$tenantGroup->update($request->all())`. The `store()` method correctly uses `$request->validated()`, making this an inconsistency.

Platform D25 baseline is 24 sites across the full codebase. Prime contributes 3 sites (2 above plus DropdownNeedController — see Layer 5).

**Verified Good:**
- `TenantController::store()`, `update()`, `updateTenantPlan()` — all use `$request->validated()`. CORRECT.
- `TenantDomainController::store()` and `update()` use inline `$request->validate()` with explicit field lists. CORRECT.
- BUG-PRM-003 (module-knowledge claim that `TenantController::update()` uses `$request->all()`) is RESOLVED in live code — `$request->validated()` is used.

---

### Layer 5: Authorization (Gates, Policies, Middleware)

**Files:** 16 policy files, controllers with Gate::authorize() calls, PrimeServiceProvider.php

**Findings:**

`SEC-PRM-001 (P0)` — `RolePermissionController::getPermissions()` has zero authorization.
`Modules/Prime/app/Http/Controllers/RolePermissionController.php` lines 311-315:
```php
public function getPermissions(Role $role): JsonResponse
{
    $rolePermissions = $role->permissions->pluck('name')->toArray();
    return response()->json(['permissions' => $rolePermissions]);
}
```
No `Gate::authorize()`, no policy check. Any authenticated user (regardless of role) can enumerate all permissions assigned to any role. Violates BR-PRM-020 and AC-008-02.

`SEC-PRM-003 (P0)` — `UserController::update()` explicitly passes `is_super_admin` from the HTTP request.
`Modules/Prime/app/Http/Controllers/UserController.php` line 144:
```php
$userData = $request->only(['name', 'email', 'emp_code', 'phone_no', 'mobile_no',
    'is_active', 'two_factor_auth_enabled', 'is_super_admin']);
```
Any authenticated admin with the "update user" permission can elevate any account to Super Admin by including `is_super_admin=1` in the PUT body. The is_super_admin field is intentionally included in the `only()` call. Combined with the `$fillable` declaration on the User model, this is a complete horizontal privilege escalation path. Violates BR-PRM-007.

`BUG-PRM-006 (P1)` — Wrong gate on three TenantController methods.
`Modules/Prime/app/Http/Controllers/TenantController.php`:
- `completeTenantSetup()` line 211: `Gate::authorize('prime.tenant-group.update')` — should be `prime.tenant.update` per BR-PRM-013.
- `toggleStatus()` line 634: same wrong gate `prime.tenant-group.update`.
- `tenantPlanToggleStatus()` line 661: same wrong gate `prime.tenant-group.update`.
A user with `prime.tenant.update` permission but not `prime.tenant-group.update` cannot complete tenant setup or toggle tenant status. A user with only `prime.tenant-group.update` (group manager) gets unintended access to tenant-level mutations.

`SEC-PRM-004 (P1)` — `DropdownNeedController::filterOptions()` has no Gate.
This AJAX endpoint for cascade dropdown filtering has no `Gate::authorize()` call. Any authenticated central user can call it regardless of permission. This is an ungated AJAX data endpoint on the central platform.

`BUG-PRM-011 (P1)` — Double policy registration in PrimeServiceProvider overwrites AcademicSessionPolicy.
`Modules/Prime/app/Providers/PrimeServiceProvider.php`:
```php
Gate::policy(AcademicSession::class, AcademicSessionPolicy::class);   // registered first
// ...
use Modules\Prime\Models\AcademicSession as PrimeAcademicSession;
Gate::policy(PrimeAcademicSession::class, SessionBoardSetupPolicy::class); // registered second
```
Since `PrimeAcademicSession` is an alias of `AcademicSession`, the second `Gate::policy()` call overwrites the first. Only `SessionBoardSetupPolicy` takes effect; `AcademicSessionPolicy` is dead code.

**Verified Good:**
- `TenantController::store()`, `update()`, `assignBoards()` — all gated correctly.
- `TenantDomainController` — all 7 methods have correct Gate calls.
- `RolePermissionController::destroy()` calls `$role->delete()` correctly — BUG-PRM-008 from module-knowledge is RESOLVED in live code.
- `SettingController` — all 7 methods have Gate::authorize() calls. BR-PRM-022 SATISFIED.
- `NotificationController::allNotifications()`, `markAsRead()` — gated with `prime.notification.viewAny`. CLEAN.

---

### Layer 6: Business Logic and Service Layer

**Findings:**

`GAP-PRM-001 (P1)` — `GenerateInvoicesCommand` does not exist.
`PrimeServiceProvider::registerCommands()` is empty. No artisan command in `app/Console/` generates invoices from `prm_tenant_plan_billing_schedule` entries. REQ-PRM-005 (Billing Schedule to Invoice Pipeline) and BR-PRM-016/BR-PRM-017 cannot be fulfilled without this command. The billing schedule table can be populated but invoices will never auto-generate.

`GAP-PRM-004 (P1)` — New platform user does not receive login credentials by email.
`Modules/Prime/app/Http/Controllers/UserController.php` line 98: `Notification::send($superAdmins, new UserCreatedNotification($user, Auth::user()->name))` sends a notification to super admins, not to the newly created user. `Modules/Prime/app/Emails/LoginMail.php` exists but is not invoked from `UserController::store()`. Violates BR-PRM-019 and AC-007-01.

`BUG-PRM-010 (P1)` — `UserController::usersByRole()` ignores the role parameter.
Line 50: `$users = User::paginate(10)` — the injected `$role` model is never used. All users are returned regardless of the requested role. Violates AC-007-04 (REQ-PRM-007).

`BUG-PRM-009 (P2)` — `UserController::index()` returns stub/random data.
Lines 30-36: `$totalRoles = 100` (hardcoded), `$totalStudents = rand(1000, 2000)`, `$totalClasses = rand(10, 30)`. Dashboard metrics for the user management section are fabricated. Violates AC-011-01.

**Verified Good:**
- `TenantPlanAssigner` service exists and wraps plan assignment in a 5-step `DB::transaction()`. BR-PRM-002, BR-PRM-003, BR-PRM-004, BR-PRM-005 structurally enforced.
- `TenantController::resetSetup()` method exists and re-dispatches `SetupTenantDatabase` — GAP-PRM-002 from module-knowledge is RESOLVED.
- `TenantController::updateTenantPlan()` delegates to `TenantPlanAssigner` and uses `$request->validated()` inside `DB::transaction()`. CLEAN.

---

### Layer 7: Tenancy Isolation

**Findings:**

`TEN-PRM-001 (P1)` — `tenancy()->initialize($tenant)` called without `tenancy()->end()` at two sites.
`Modules/Prime/app/Http/Controllers/DropdownNeedController.php`:
- Line 479: `tenancy()->initialize($tenant)` inside `getMigrationTables()` — no matching `->end()`.
- Line 641: `tenancy()->initialize($tenant)` inside `getTableColumns()` — no matching `->end()`.

Both methods are dev/tooling endpoints for schema inspection. A bare `initialize()` without `end()` leaks the tenant DB context for the remainder of the request. If any subsequent code in the same request cycle writes to the central DB, it may silently write to the tenant DB instead. Confirmed as a known anti-pattern in `known-issues.md`.

**Verified Good:**
- `TenantController::update()` uses `$tenant->run(fn() => ...)` — auto-reverts. SAFE.
- `TenantController::completeTenantSetup()` uses `tenancy()->central(fn() => ...)` — SAFE.
- `TenantController::assignBoards()` uses `$tenant->run(fn() => ...)` — SAFE.
- `SetupTenantDatabase::handle()` uses `$tenant->run()` for Steps 3 and 4 — SAFE.
- Central routes use `Route::domain(config('app.domain'))` — correct (not `env()`; safe after `config:cache`).

---

### Layer 8: Queue Jobs and Async Processing

**Findings:**

`GAP-PRM-003 (P0)` — `SetupTenantDatabase` creates root tenant user with hardcoded password.
`app/Jobs/SetupTenantDatabase.php` line 82:
```php
'password' => Hash::make('password'),
```
The root administrator account for every provisioned school has the password `password`. This is delivered via `Hash::make()` so the stored value is a bcrypt hash, but the plaintext is predictable and universal. No random password is generated, and no password delivery email is sent to the school. Violates BR-PRM-009.

**Verified Good:**
- `SetupTenantDatabase.$tries = 1` — BR-PRM-008 (no auto-retry) is SATISFIED.
- `SetupTenantDatabase.$timeout = 600` — 10 minutes is adequate for DB provisioning.
- Exception handling catches `\Throwable`, logs the full stack trace, updates `setup_status` to `failed`, and notifies super admins — GOOD.
- All four stages (create DB, run migrations, create root user, add organization) wrapped in try/catch with progress updates — GOOD.
- Migration progress tracked via `MigrationStarted`/`MigrationEnded` events — GOOD.
- Notification sent to all super admins on success/failure (`TenantSetupCompletedNotification`, `TenantSetupFailedNotification`) — GOOD.

---

### Layer 9: Performance and N+1 Queries

**Findings:**

`PERF-PRM-001 (P2)` — `DropdownNeedController` issues `SHOW TABLES` and `SHOW COLUMNS FROM` raw SQL in a hot AJAX path.
`getMigrationTables()` (line 479 area) and `getTableColumns()` (line 641 area) use raw schema inspection queries on each call. No caching. These are called on every cascade dropdown interaction during tenant setup. The same methods also leak tenant context (TEN-PRM-001).

`PERF-PRM-002 (P2)` — `Navbar::resolveActiveMainMenu()` calls `Menu::find()` in a while-loop.
`Modules/Prime/routes/Navbar.php` (actually `App\View\Components\Backend\Partials\Navbar`) — the `resolveActiveMainMenu()` method traverses parent menu items via repeated `Menu::find()` calls until it reaches the root. This is an N+1 query pattern proportional to menu depth. No eager loading.

---

### Layer 10: Deployment Readiness

**Findings:**

`SEC-PRM-002 (P1)` — Debug/test routes are accessible in production.
Three routes are registered as full production routes with no environment guard:
- `EmailController::testEmail()` — gated by `prime.email.viewAny` but sends test email from a production server.
- `EmailController::sendTestEmail()` — gated by `prime.email.create`, sends email to hardcoded `primegurukul@yopmail.com`. No `App::environment()` check.
- `NotificationController::testNotification()` — gated by `prime.notification.create`, sends test notification to the auth user.

`BR-PRM-018` requires these routes to be unavailable in production. All three are wired to real routes with no `if (App::isLocal())` or `App::environment(['local', 'staging'])` guard at route registration. Violates AC-006-04.

**Verified Good:**
- No route closures in `web.php` or `api.php` — safe for `route:cache`.
- No `env()` calls in route files — `config('app.domain')` used correctly.
- No committed secrets found in migration or seeder files.
- `api.php` uses `auth:sanctum` middleware — API routes are authenticated.

---

### Layer 11: Blade Views and Frontend Security

**Files:** 97 Blade views in `resources/views/`

**Findings:**

No P0 XSS vulnerabilities found in the views examined. The controllers pass model objects to views using `compact()`, and standard Laravel `{{ }}` escaping is the dominant pattern.

`DEAD-PRM-001 (P3)` — Module-knowledge incorrectly counts Navbar.php as a route file.
`Modules/Prime/routes/Navbar.php` is `App\View\Components\Backend\Partials\Navbar` — a Blade Component, not a routes file. True route line count is 49 (web.php=41 + api.php=8). Module-knowledge should be corrected.

---

### Layer 12: Code Quality and Dead Code

**Findings:**

`BUG-PRM-STUB-001 (P2)` — `TenantController::destroy()` is an empty stub wired to a live route.
Line 620: method body is just `//`. The route is registered (tenants.destroy) and is reachable, but calling it silently does nothing — no auth check, no deletion, no response. Any DELETE request to this route returns a 200 with no action taken.

`DEAD-PRM-002 (P3)` — Two policy files are imported but never registered.
`PrimeServiceProvider` imports `RolePermissionPolicy` and `SettingPolicy` but only registers `PrimeRolePermissionPolicy` and `PrimeSettingPolicy` (duplicate/replacement versions). The original files are dead code.

`DEP-PRM-001 (P3)` — Cross-module FormRequest dependency.
`RolePermissionController` imports `Modules\SchoolSetup\Http\Requests\RolePermissionRequest` instead of using a Prime-local FormRequest. This creates a compile-time dependency on SchoolSetup. If SchoolSetup is disabled or removed, RolePermissionController fails to load.

---

## Mode B — FRD Gap Analysis

**FRD:** `PRM_FRD_Complete_2026-06-29.md` | 12 REQs (9 P0, 3 P1)

| REQ | Title | Status | Blocker |
|-----|-------|--------|---------|
| REQ-PRM-001 | Tenant Provisioning Pipeline | PARTIAL | GAP-PRM-003 (root password hardcoded) |
| REQ-PRM-002 | School Group Management | PASS | — |
| REQ-PRM-003 | Plan Catalogue | PASS | — |
| REQ-PRM-004 | Plan Subscription + Billing Schedule | PASS | — |
| REQ-PRM-005 | Billing Schedule to Invoice Pipeline | FAIL | GAP-PRM-001 (command missing) |
| REQ-PRM-006 | Central Platform Authentication | PARTIAL | SEC-PRM-002 (debug routes in prod) |
| REQ-PRM-007 | Central Staff User Management | FAIL | SEC-PRM-003 (is_super_admin escalation), BUG-PRM-010 (role filter broken) |
| REQ-PRM-008 | Role and Permission Management | FAIL | SEC-PRM-001 (getPermissions ungated) |
| REQ-PRM-009 | Global Reference Data Management | PARTIAL | BUG-PRM-011 (AcademicSessionPolicy overwritten) |
| REQ-PRM-010 | Platform Settings | PASS | — |
| REQ-PRM-011 | Platform Dashboard and Analytics | FAIL | BUG-PRM-009 (stub/rand() data) |
| REQ-PRM-012 | Activity Log and Monitoring | PASS | — |

**Pass: 4 / Partial: 3 / Fail: 5** out of 12 REQs.

---

## Mode C — Business Rule Enforcement

| BR | Rule | Status | Evidence |
|----|------|--------|----------|
| BR-PRM-001 | School access requires active status + active subscription | PARTIAL | `Tenant::canAccess()` exists; not verified in full depth |
| BR-PRM-002 | Single active subscription per plan via generated column | PASS | `prm_tenant_plan_jnt.current_flag` generated column + UNIQUE constraint confirmed |
| BR-PRM-003 | Active session required before plan assignment | PASS | `TenantPlanAssigner` checks session before assignment |
| BR-PRM-004 | Billing window clamped to session bounds | PASS | `TenantPlanAssigner` Step 5 clamps window |
| BR-PRM-005 | Plan re-assignment soft-deactivates prior entries | PASS | `TenantPlanAssigner` uses update/deactivate pattern |
| BR-PRM-006 | db_password must be stored encrypted | **FAIL** | BUG-PRM-001 — Domain model has no encrypted cast |
| BR-PRM-007 | is_super_admin cannot be set via web form or API | **FAIL** | SEC-PRM-003 — UserController::update() line 144 explicitly includes it |
| BR-PRM-008 | Provisioning job runs exactly once | PASS | `$tries = 1` confirmed in SetupTenantDatabase |
| BR-PRM-009 | Root user must have randomly generated secure password | **FAIL** | GAP-PRM-003 — `Hash::make('password')` hardcoded |
| BR-PRM-010 | Tenant implements TenantWithDatabase + HasDatabase + HasDomains | PASS | Tenant model confirmed |
| BR-PRM-011 | Allowed modules = plan ∩ active plan modules ∩ global registry | PARTIAL | `allowedModuleIds()` exists; full intersection logic not verified |
| BR-PRM-012 | Plan edits create new version, don't overwrite | NOT VERIFIED | No plan version audit performed |
| BR-PRM-013 | completeTenantSetup requires tenant.update permission | **FAIL** | BUG-PRM-006 — uses `tenant-group.update` |
| BR-PRM-014 | School group delete blocked while schools exist | PARTIAL | FK restrict constraint at DB level; controller error handling not verified |
| BR-PRM-015 | ONE_TIME plan = single billing entry regardless of range | PASS | TenantPlanAssigner handles ONE_TIME case |
| BR-PRM-016 | Invoice generated flag prevents duplicate invoices | NOT MET | GAP-PRM-001 — command missing; flag exists but never set |
| BR-PRM-017 | Invoice due date = invoice date + credit days | NOT MET | GAP-PRM-001 — command missing |
| BR-PRM-018 | Debug routes not accessible in production | **FAIL** | SEC-PRM-002 — 3 debug routes registered as production routes |
| BR-PRM-019 | New user receives login credentials by email | **FAIL** | GAP-PRM-004 — UserCreatedNotification goes to admins, not new user |
| BR-PRM-020 | getPermissions endpoint requires authentication + permission | **FAIL** | SEC-PRM-001 — zero Gate call |
| BR-PRM-021 | Exactly one current academic session at a time | NOT VERIFIED | AcademicSessionController uses $request->all(); enforcement mechanism not found |
| BR-PRM-022 | Settings search requires View Settings permission | PASS | SettingController gated on all methods |
| BR-PRM-023 | All state-changing operations produce activity log entry | PARTIAL | activityLog() called in TenantController, TenantDomainController, RolePermissionController; coverage not 100% |

**Pass: 9 / Partial: 3 / Fail: 8 / Not met: 2 / Not verified: 1** out of 23 BRs.

---

## Mode D — Systemic Pattern Detectors (PRM-scoped)

| Pattern | PRM Count | Platform Baseline | Assessment |
|---------|-----------|-------------------|------------|
| D24 (wrong permission prefix) | 0 | Common | CLEAN — all permissions use `prime.*` prefix |
| D25 ($request->all() with FormRequest injected) | 3 sites | 24 platform-wide | Within norm; 3 sites: AcademicSessionController (×2), TenantGroupController (×1) |
| D29 (ENUM column in migration) | 1 | ~476 | Within norm; sys_users.status |
| D30 (authorize()=true in FormRequest) | 7/7 (100%) | 90% baseline | Above baseline — no FormRequest does resource-level check |
| D36 (GENERATED column degraded) | 0 degraded | Platform-wide | CLEAN — super_admin_flag UNIQUE constraint active; D36 correct use |
| D37 (status INT FK vs string) | 0 | Moderate | CLEAN — sys_users.status is ENUM string, not FK |
| D38 (SoftDeletes vs DDL mismatch) | 0 | Several | CLEAN — sys_roles and prm_billing_cycles both have deleted_at in migrations |
| D39 (permissions unseeded) | Not fully verified | Several modules | Seeder exists (RolePermissionSeeder); content not fully verified |

---

## Mode G — Pre-Deploy Gate

| Gate | Status |
|------|--------|
| G1: No P0 security issues | **FAIL** — 4 P0s (BUG-PRM-001, SEC-PRM-001, SEC-PRM-003, GAP-PRM-003) |
| G2: No unauthenticated data exposure | **FAIL** — SEC-PRM-001 (getPermissions ungated) |
| G3: No plaintext secret storage | **FAIL** — BUG-PRM-001 (db_password plaintext) |
| G4: Tenancy context correctly bounded | **FAIL** — TEN-PRM-001 (initialize without end, 2 sites) |
| G5: All routes use config() not env() | PASS |
| G6: No route closures (route:cache safe) | PASS |
| G7: Queue jobs production-ready | FAIL — GAP-PRM-003 (hardcoded root password) |
| G8: No debug routes in production | **FAIL** — SEC-PRM-002 (3 debug routes active) |
| G9: FormRequests validate all inputs | PARTIAL — 3 D25 sites bypass FormRequest |

**Deploy Verdict: NO-GO**
Blocking: G1, G2, G3, G4, G7, G8. Must resolve all P0 findings and TEN-PRM-001 before any production deployment.

---

## Health Score

| Layer | Weight | Raw Score | Weighted |
|-------|--------|-----------|---------|
| Tenancy | 15 | 90 (TEN-PRM-001 P1 ×2: -10) | 13.5 |
| Auth/Authorization | 14 | 65 (SEC-PRM-001 P0: -10, BUG-PRM-006 ×3 P1: -15, SEC-PRM-004 P1: -5, BUG-PRM-011 P1: -5) | 9.1 |
| Data Integrity | 13 | 80 (BUG-PRM-001 P0: -10, SEC-PRM-003 P0: -10) | 10.4 |
| Validation | 11 | 94 (D25 ×3 P2: -6) | 10.3 |
| Deployment | 10 | 95 (SEC-PRM-002 P1: -5) | 9.5 |
| Migration/DDL | 9 | 95 (MIG-PRM-001 P1: -5) | 8.6 |
| DDL Integrity | 7 | 96 (D29-PRM-001 P2: -2, FILL-PRM-001 P2: -2) | 6.7 |
| Performance | 7 | 96 (PERF-PRM-001/002 P2: -4) | 6.7 |
| Queue/Jobs | 6 | 75 (GAP-PRM-003 P0: -10, GAP-PRM-001 P1: -5, GAP-PRM-004 P1: -5, BUG-PRM-010 P1: -5) | 4.5 |
| Code Quality | 4 | 95 (BUG-PRM-STUB-001 P2: -2, BUG-PRM-009 P2: -2, DEAD-PRM-002 P3: -1) | 3.8 |
| ORM/Models | 2 | 96 (BUG-PRM-DUP P2: -2, DEP-PRM-001 P3: -1, DEAD-PRM-002 P3: -1) | 1.9 |
| Frontend/Blade | 2 | 100 (no XSS found) | 2.0 |
| **Raw Total** | **100** | | **87.0** |

**P0 findings present (4) → Health capped at 40.**

**Final Health Score: 40 / 100 (P0-capped; uncapped ≈ 87)**

---

## Issue Register

### P0 — Critical (blocks production deployment)

| Code | Issue | File:Line | BR Violated |
|------|-------|-----------|-------------|
| BUG-PRM-001 | `prm_tenant_domains.db_password` stored in plaintext — Domain model has no `encrypted` cast; TenantDomainController::store() passes raw value via `Domain::create($validated)` | `app/Models/Domain.php`, `Http/Controllers/TenantDomainController.php:73` | BR-PRM-006 |
| SEC-PRM-001 | `RolePermissionController::getPermissions()` has zero Gate authorization — any authenticated user can enumerate all role permissions | `Http/Controllers/RolePermissionController.php:311-315` | BR-PRM-020 |
| SEC-PRM-003 | `UserController::update()` explicitly includes `is_super_admin` in `$request->only()` — any admin can escalate any user to Super Admin via PUT request | `Http/Controllers/UserController.php:144` | BR-PRM-007 |
| GAP-PRM-003 | `SetupTenantDatabase` creates root tenant user with `Hash::make('password')` — every provisioned school has the same predictable root password; no password email sent | `app/Jobs/SetupTenantDatabase.php:82` | BR-PRM-009 |

### P1 — High (blocks release)

| Code | Issue | File:Line | BR Violated |
|------|-------|-----------|-------------|
| TEN-PRM-001 | `tenancy()->initialize($tenant)` without `->end()` at two sites in DropdownNeedController — DB context leaks for remainder of request | `Http/Controllers/DropdownNeedController.php:479, 641` | — |
| BUG-PRM-006 | Wrong gate on three TenantController methods: `completeTenantSetup()`, `toggleStatus()`, `tenantPlanToggleStatus()` — all use `prime.tenant-group.update` instead of `prime.tenant.update` | `Http/Controllers/TenantController.php:211, 634, 661` | BR-PRM-013 |
| SEC-PRM-002 | Three debug/test routes accessible in production with no environment guard — `testEmail()`, `sendTestEmail()`, `testNotification()` | `Http/Controllers/EmailController.php`, `Http/Controllers/NotificationController.php:86` | BR-PRM-018 |
| GAP-PRM-001 | `GenerateInvoicesCommand` does not exist — `registerCommands()` in PrimeServiceProvider is empty; billing schedule → invoice pipeline is non-functional | `Providers/PrimeServiceProvider.php` | BR-PRM-016/017 |
| BUG-PRM-010 | `UserController::usersByRole()` ignores `$role` parameter — returns all users via `User::paginate(10)` regardless of requested role | `Http/Controllers/UserController.php:50` | AC-007-04 |
| SEC-PRM-004 | `DropdownNeedController::filterOptions()` AJAX endpoint has no Gate authorization | `Http/Controllers/DropdownNeedController.php` | — |
| BUG-PRM-011 | PrimeServiceProvider double-registers AcademicSession — `SessionBoardSetupPolicy` overwrites `AcademicSessionPolicy` (last `Gate::policy()` call wins); AcademicSessionPolicy is effectively dead | `Providers/PrimeServiceProvider.php` | — |
| GAP-PRM-004 | `UserController::store()` sends `UserCreatedNotification` to super admins, not login credentials to the new user — `LoginMail` exists but is unused in store() | `Http/Controllers/UserController.php:98` | BR-PRM-019 |
| MIG-PRM-001 | `create_tenants_table.php` down() calls `Schema::dropIfExists('tenants')` — table is `prm_tenant`; rollback either no-ops or destroys wrong table | `database/migrations/2025_10_10_000010_create_tenants_table.php:61` | — |

### P2 — Medium (technical debt / correctness)

| Code | Issue | File:Line |
|------|-------|-----------|
| D30-PRM | All 7 FormRequests return bare `true` in `authorize()` — no resource-level IDOR check at any FormRequest | 7 files in `Http/Requests/` |
| D25-PRM-001 | `AcademicSessionController::store()` and `update()` use `$request->all()` — FormRequest bypassed | `Http/Controllers/AcademicSessionController.php:42, 80` |
| D25-PRM-002 | `TenantGroupController::update()` uses `$request->all()` — store() correctly uses `$request->validated()` | `Http/Controllers/TenantGroupController.php:99` |
| BUG-PRM-009 | `UserController::index()` uses `rand()` for stub stats — `$totalRoles=100`, `$totalStudents=rand(1000,2000)` | `Http/Controllers/UserController.php:30-36` |
| BUG-PRM-STUB-001 | `TenantController::destroy()` is empty stub wired to live route — DELETE request silently does nothing, no auth, no logic | `Http/Controllers/TenantController.php:620` |
| FILL-PRM-001 | `super_admin_flag` (STORED generated column) is in User `$fillable` — attempting to write it via Eloquent triggers MySQL error 3105 | `app/Models/User.php` |
| PERF-PRM-001 | `DropdownNeedController::getMigrationTables/getTableColumns()` issue raw `SHOW TABLES`/`SHOW COLUMNS FROM` on every AJAX call — no caching | `Http/Controllers/DropdownNeedController.php:479, 641` |
| PERF-PRM-002 | `Navbar::resolveActiveMainMenu()` calls `Menu::find()` in while-loop — N+1 proportional to menu depth | `Modules/Prime/routes/Navbar.php` (Blade Component) |
| D29-PRM-001 | `sys_users.status` is ENUM — adds 1 to platform baseline count | `database/migrations/2025_10_17_101827_create_users_table.php:26` |

### P3 — Low (minor / informational)

| Code | Issue | File:Line |
|------|-------|-----------|
| DEAD-PRM-001 | Module-knowledge counts `Navbar.php` as a routes file — it is `App\View\Components\Backend\Partials\Navbar` (Blade Component); actual route lines = 49, not 244 | `Modules/Prime/routes/Navbar.php` |
| DEAD-PRM-002 | `RolePermissionPolicy` and `SettingPolicy` files imported but never registered in `Gate::policy()` — dead code | `Providers/PrimeServiceProvider.php` |
| DEP-PRM-001 | `RolePermissionController` imports `Modules\SchoolSetup\Http\Requests\RolePermissionRequest` — cross-module compile-time dependency | `Http/Controllers/RolePermissionController.php:top` |

---

## Resolved Issues (Previously Listed, Now Confirmed Fixed)

| Code | Description | Resolution |
|------|-------------|------------|
| BUG-PRM-003 | TenantController::update() used `$request->all()` | Live code uses `$request->validated()`. RESOLVED. |
| BUG-PRM-008 | RolePermissionController::destroy() called `$role->save()` | Live code calls `$role->delete()`. RESOLVED. |
| GAP-PRM-002 | No re-trigger button for failed tenant setup | `TenantController::resetSetup()` method exists and re-dispatches `SetupTenantDatabase`. RESOLVED. |

Note: BUG-PRM-002 (is_super_admin in $fillable) from module-knowledge is still open — confirmed in User.$fillable. The more critical angle is SEC-PRM-003 (explicit update() assignment).

---

## Recommended Fix Order

**Immediate (P0 — before any production use):**
1. `BUG-PRM-001` — Add `'db_password' => 'encrypted'` cast to Domain model; change DDL column to VARCHAR(500); add migration to re-encrypt existing rows.
2. `SEC-PRM-003` — Remove `'is_super_admin'` from `$request->only()` in `UserController::update()`. Remove `'is_super_admin'` and `'super_admin_flag'` from User `$fillable`. Create a separate admin-only artisan command for super admin promotion.
3. `SEC-PRM-001` — Add `Gate::authorize('prime.role.viewAny')` (or appropriate permission) to `RolePermissionController::getPermissions()`.
4. `GAP-PRM-003` — Replace `Hash::make('password')` with `Hash::make(Str::password(16))` in `SetupTenantDatabase`; send generated password to school's registered email via `LoginMail`.

**Before Release (P1):**
5. `TEN-PRM-001` — Add `tenancy()->end()` after each `tenancy()->initialize($tenant)` in `DropdownNeedController::getMigrationTables()` and `::getTableColumns()`.
6. `BUG-PRM-006` — Change gate to `prime.tenant.update` (or `prime.tenant.view`) on `completeTenantSetup()`, `toggleStatus()`, `tenantPlanToggleStatus()`.
7. `SEC-PRM-002` — Wrap test route registration in `if (App::isLocal() || App::isProduction() === false)` or move to a separate dev-only route file.
8. `GAP-PRM-001` — Create `GenerateInvoicesCommand` artisan command that processes due billing schedule entries.
9. `BUG-PRM-010` — Fix `usersByRole()` to use `$role->users()->paginate(10)` instead of `User::paginate(10)`.
10. `SEC-PRM-004` — Add `Gate::authorize()` to `DropdownNeedController::filterOptions()`.
11. `BUG-PRM-011` — Remove the duplicate `Gate::policy(PrimeAcademicSession::class, ...)` or use a different alias; restore `AcademicSessionPolicy` registration.
12. `GAP-PRM-004` — Invoke `LoginMail` in `UserController::store()` to send credentials to the new user.
13. `MIG-PRM-001` — Fix `down()` to call `Schema::dropIfExists('prm_tenant')`.

---

*Report generated: 2026-06-29 | Agent: pa-technical-auditor | Version: V1*
