# Module Knowledge — Prime (PRM)
> Single source of truth for accumulated knowledge about the Prime module.
> Updated: 2026-06-29 | Agent: pa-business-analyst

---

## Module Facts

| Property | Value |
|----------|-------|
| Module Code | PRM |
| Module Name | Prime |
| Table Prefix | `prm_*` (also owns `sys_*` and `bil_*` in prime_db) |
| Database Layer | **Central** — `prime_db` + `global_db` (reads) |
| Module Type | Platform Administration Console (NOT tenant-scoped) |
| App Directory | `Modules/Prime/` |
| Route Prefix | `/` (central domain only; domain-scoped routing) |
| Route Files | web.php (41 lines), Navbar.php (195 lines), api.php (8 lines) = **244 total** |
| Completion | ~70% overall (90% feature, 65% security, 55% test coverage) |

### Verified Code Counts (2026-06-29 against Modules/Prime/)

| Artifact | Count | Notes |
|----------|------:|-------|
| Controllers | 22 | All in `app/Http/Controllers/` |
| Models | 27 in `app/Models/` + 1 duplicate in root `Models/` = 28 files | 1 stale duplicate: `Models/DropdownNeed.php` (BUG-PRM-007) |
| Services | 1 | `TenantPlanAssigner` only |
| FormRequests | 7 | AcademicSessionRequest, BoardRequest, DropdownRequest, TenantGroupRequest, TenantPlanRequest, TenantRequest, UserRequest |
| Policies | 19 | In `Modules/Prime/app/Policies/` — includes duplicates (POL-01) |
| Views (Blade) | 97 | Confirmed via filesystem count (2026-06-29) |
| Seeders | 15 | PrimeDatabaseSeeder + 14 individual seeders |
| Jobs | 1 in module (`SendScheduledEmail`) + 1 in `app/Jobs/` (`SetupTenantDatabase`) |
| Test Files | 9 | 1 Feature (`SettingModelTest`) + 8 Unit |
| Events | 0 | No Event classes in module |
| Listeners | 0 | No Listener classes in module |
| Artisan Commands | 0 | No custom Artisan commands defined |

### DDL Table Inventory (prime_db_v4.sql — verified 2026-06-29)

**prm_* tables (10 — Prime-owned):**

| Table | Purpose |
|-------|---------|
| `prm_tenant_groups` | School chains / managing trusts |
| `prm_tenant` | School tenant records (UUID from stancl/tenancy) |
| `prm_tenant_domains` | Domain + DB credentials per tenant (db_password PLAINTEXT — P0 bug) |
| `prm_billing_cycles` | Billing recurrence types (MONTHLY/QUARTERLY/YEARLY/ONE_TIME) |
| `prm_plans` | Subscription plan catalogue with versioning |
| `prm_module_plan_jnt` | Plan ↔ module mapping |
| `prm_tenant_plan_jnt` | Tenant ↔ plan subscription (current_flag generated column) |
| `prm_tenant_plan_rates` | Rate card per subscription (pricing, taxes, discounts) |
| `prm_tenant_plan_module_jnt` | Licensed module list per tenant-plan subscription |
| `prm_tenant_plan_billing_schedule` | Pre-generated billing calendar entries |

**sys_* tables (12 — shared platform infrastructure, Prime owns/seeds):**

`sys_permissions`, `sys_roles`, `sys_role_has_permissions_jnt`, `sys_model_has_permissions_jnt`, `sys_model_has_roles_jnt`, `sys_users`, `sys_settings`, `sys_dropdown_needs`, `sys_dropdown_table`, `sys_dropdown_need_table_jnt`, `sys_media`, `sys_activity_logs`

**bil_* tables (5 — Billing module's schema section, co-owned by Prime models):**

`bil_tenant_invoices`, `bil_tenant_invoicing_modules_jnt`, `bil_tenant_invoicing_payments`, `bil_tenant_invoicing_audit_logs`, `bil_tenant_email_schedules`

---

## FRD Summary

| Property | Value |
|----------|-------|
| FRD File | `PRM_FRD_Complete_2026-06-29.md` (complete analysis pack — single file) |
| FRD Date | 2026-06-29 |
| REQ Count | 12 (9 P0, 3 P1, 0 P2) |
| BR Count | 13 |
| RPT Count | 5 |
| ENH Count | 8 |
| Workflow Count | 4 |
| FSM Count | 3 |
| User Story Count | 12 (one per REQ-P0/P1) |

---

## Known Gaps & Open Issues

### P0 — Critical (must fix before production)

| ID | Issue | Evidence |
|----|-------|----------|
| BUG-PRM-001 | `prm_tenant_domains.db_password` stored in plaintext. Domain model has no `encrypted` cast. | `app/Models/Domain.php` — only `$table` override, no `$casts` |
| BUG-PRM-002 | `is_super_admin` mass-assignable in `App\Models\User` | User model `$fillable` check |
| SEC-PRM-001 | `RolePermissionController::getPermissions()` has no Gate authorization | Returns role permissions JSON with no auth check |

### P1 — High (must fix before release)

| ID | Issue | Evidence |
|----|-------|----------|
| BUG-PRM-005 | No `TenantCreationService` — business logic in TenantController::store() | `TenantController.php` lines 55–87 |
| BUG-PRM-006 | `completeTenantSetup()` uses wrong Gate: `prime.tenant-group.update` instead of `prime.tenant.update` | `TenantController.php` line 167 |
| GAP-PRM-001 | `GenerateInvoicesCommand` does not exist — billing schedules cannot auto-generate invoices | No artisan command in module or app/Console/ |
| GAP-PRM-002 | No re-trigger button on setup-progress view when setup_status='failed' | TenantController has no re-trigger route |
| GAP-PRM-003 | Root tenant user created with hardcoded `password` string | `SetupTenantDatabase::createRootUser()` |
| SEC-PRM-002 | Test/debug routes (`test-email`, `send-test-email`, `test-notification`) accessible in production | `EmailController`, `NotificationController` — no env gate |

### P2 — Medium (code quality / architecture)

| ID | Issue | Evidence |
|----|-------|----------|
| BUG-PRM-003 | `TenantController::update()` uses `$request->all()` not `$request->validated()` | Line ~141 TenantController |
| BUG-PRM-007 | Duplicate model: `Modules/Prime/Models/DropdownNeed.php` outside `app/` | Stale root-level Models directory |
| BUG-PRM-008 | RolePermissionController::destroy() calls `$role->save()` instead of deleting | Implementation stub |
| BUG-PRM-009 | `UserController::index()` uses `rand()` for student/class stats; `$totalRoles = 100` hardcoded | UserController stub |
| BUG-PRM-010 | `usersByRole()` does not filter by role — returns all users | UserController stub |
| DB-02 | FK type mismatch: `prm_plans.billing_cycle_id SMALLINT` (signed) vs `prm_billing_cycles.id SMALLINT UNSIGNED` | DDL inspection |
| DB-03 | `prm_billing_cycles` has no `deleted_at` but BillingCycle model uses SoftDeletes | DDL + model mismatch |
| DB-04 | `prm_tenant_plan_rates` missing `is_active` and `created_by` per project standards | DDL inspection |
| DB-05 | FK to `glb_modules` which is a VIEW — MySQL may not enforce FK constraints | DDL inspection |
| DB-06 | Cross-schema circular FK: `prm_tenant_plan_billing_schedule.generated_invoice_id → bil_tenant_invoices.id` | DDL inspection |
| DB-07 | `prm_tenant_groups` missing `created_by` column per project standards | DDL inspection |
| POL-01 | Duplicate/overlapping policies: `RolePermissionPolicy` vs `PrimeRolePermissionPolicy`; `SettingPolicy` vs `PrimeSettingPolicy` | app/Policies/ listing |
| RT-01 | Boards, academic-session, dropdown routes defined under both `prime.` and `global-master.` prefixes | routes/web.php audit |
| MDL-01 | `TenantInvoice` model exists in both Prime and Billing modules for same `bil_tenant_invoices` table | Module comparison |

### Test Coverage Gap (Critical)

All 9 existing tests are structural/reflective — they check that code exists, not that it behaves correctly. Zero feature-behavioral tests for the core pipeline:

- No test for tenant onboarding pipeline (create → job → progress → complete)
- No test for SetupTenantDatabase 4-stage job
- No test for TenantPlanAssigner 5-step transaction + rollback
- No test for billing schedule date-range generation
- No test for db_password encryption
- No test for is_super_admin mass-assignment protection

---

## Design Decisions Made

| Decision | Detail |
|----------|--------|
| INT PK for Tenant | `prm_tenant.id` uses INT UNSIGNED AUTO_INCREMENT, not UUID — stancl/tenancy's standard UUID PK is NOT used; custom columns declared via `getCustomColumns()` |
| generated column for subscription uniqueness | `prm_tenant_plan_jnt.current_flag` is a MySQL STORED generated column (`CASE WHEN is_subscribed=1 THEN tenant_id ELSE NULL END`) + UNIQUE constraint on `(current_flag, plan_id)` — prevents duplicate active subscriptions |
| Domain-scoped routing | All Prime routes use `Route::domain(config('app.domain'))` — but this breaks after `config:cache` (must use `Route::domain(config('app.domain'))` not `env()`) |
| Billing window clamping | Plan billing schedule is clamped to the active academic session bounds |
| SetupTenantDatabase $tries=1 | Job runs exactly once; failed setups must be manually re-triggered |
| Progress tracking via DB::connection('central') | Prevents progress writes from being swallowed by tenant DB context |

---

## Cross-Module Dependencies

### Prime Consumes
| Module / Package | Purpose |
|-----------------|---------|
| GlobalMaster | `glb_modules` (plan-module mapping), `glb_boards`, `glb_languages`, `glb_menus`, `glb_cities` FK |
| stancl/tenancy v3.9 | Tenant model infrastructure, DB isolation, domain routing |
| Spatie Permission v6.21 | Central RBAC (`sys_roles`, `sys_permissions`) |
| spatie/laravel-medialibrary | Tenant logo with small/medium/large conversions |
| Laravel Queue | `SetupTenantDatabase` async provisioning job |
| Laravel Mail | `TenantRegisteredMail`, `TenantGroupCreatedMail`, `LoginMail` |
| SchoolSetup module | `RolePermissionController` borrows `RolePermissionRequest` from SchoolSetup — P1 dependency to fix |

### Prime Produces
| Consumer | What It Receives |
|----------|-----------------|
| Billing module | `prm_tenant_plan_billing_schedule` drives invoice generation |
| All 40+ tenant modules | `SetupTenantDatabase` provisions tenant DB with all module migrations + seeds |
| All tenant modules | `prm_tenant_plan_module_jnt` controls which modules are licensed per tenant |
| SystemConfig module | Shares `sys_activity_logs`, `sys_settings`, `sys_dropdown_table`, `sys_media` tables |

---

## Lessons Learned

| Date | Lesson |
|------|--------|
| 2026-06-29 | Prime module has no V1 per-screen folder in `2-Module_Requirement_V1/` — the single V2 requirement doc (`PRM_Prime_Requirement.md`) is the only requirement source besides DDL and code. |
| 2026-06-29 | View count correction: modules-map correctly shows 97 (confirmed via filesystem); the V2 requirement doc says 84 (audit from 2026-03-22 — 13 additional views added since then). Always verify against filesystem. |
| 2026-06-29 | Route lines: 244 total across 3 files (web.php=41, Navbar.php=195, api.php=8) — modules-map count of 244 is correct. The Navbar.php file is the largest at 195 lines. |
| 2026-06-29 | Seeder count: 15 seeders in `database/seeders/` including PrimeDatabaseSeeder (orchestrator) + 14 individual seeders — consistent with "2" in modules-map which likely counted only the two non-orchestrator production seeders mentioned in V2. Filesystem shows 15. |
| 2026-06-29 | Test count: 9 test files (8 Unit + 1 Feature) — modules-map says 9, confirmed. All are structural/reflective tests only. |
| 2026-06-29 | The Prime module is functionally the most complete central module (~70%) but has the most critical security gaps (P0 db_password plaintext, is_super_admin mass-assignable). Feature completeness is 90% but security hardening is 65%. |

---

## Pending Next Steps

1. **P0 Security:** Encrypt `db_password` in Domain model (`encrypted` cast + VARCHAR(500) DDL change)
2. **P0 Security:** Remove `is_super_admin` from `$fillable` in `App\Models\User`
3. **P0 Security:** Add `Gate::authorize()` to `RolePermissionController::getPermissions()`
4. **P1 Feature:** Create `GenerateInvoicesCommand` artisan command
5. **P1 Feature:** Add re-trigger setup button/route for failed tenant provisioning
6. **P1 Architecture:** Consolidate `TenantController::updateTenantPlan()` into `TenantPlanAssigner::assign()`
7. **P1 Architecture:** Move `TenantInvoice*` models to Billing module exclusively
8. **P1 Testing:** Write feature tests for tenant onboarding pipeline and plan assigner transaction
9. **P2:** Clean up duplicate route definitions (RT-01), duplicate policies (POL-01), stale model file (BUG-PRM-007)
10. **DDL fixes:** DB-02 (FK type mismatch), DB-03 (missing deleted_at), DB-04 (missing columns), DB-07 (missing created_by)

---

## Version History

| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0 | 2026-06-29 | pa-business-analyst | Initial seed from V2 requirement doc + live code/DDL audit |
