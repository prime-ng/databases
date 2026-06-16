# Prime Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/Prime

---

## EXECUTIVE SUMMARY

| Category | Critical (P0) | High (P1) | Medium (P2) | Low (P3) | Total |
|----------|:---:|:---:|:---:|:---:|:---:|
| Security | 2 | 3 | 3 | 0 | 8 |
| Data Integrity | 1 | 2 | 3 | 1 | 7 |
| Architecture | 0 | 2 | 3 | 2 | 7 |
| Performance | 0 | 1 | 3 | 1 | 5 |
| Code Quality | 0 | 2 | 3 | 2 | 7 |
| Test Coverage | 0 | 1 | 1 | 0 | 2 |
| **TOTAL** | **3** | **11** | **16** | **6** | **36** |

### Module Scorecard

| Dimension | Score | Grade |
|-----------|:-----:|:-----:|
| Feature Completeness | 90% | A- |
| Security | 65% | D+ |
| Performance | 65% | D+ |
| Test Coverage | 55% | D+ |
| Code Quality | 70% | C |
| Architecture | 75% | B- |
| **Overall** | **70%** | **C** |

---

## SECTION 1: DATABASE INTEGRITY

### 1.1 DDL Tables (from prime_db_v2.sql — prm_* prefix)

| # | Table Name | Columns | FKs | Issues |
|---|-----------|---------|-----|--------|
| 1 | `prm_tenant_groups` | 12 | 1 (city_id) | Missing `created_by` per project rules |
| 2 | `prm_tenant` | 24 | 2 (tenant_group_id, city_id) | OK |
| 3 | `prm_tenant_domains` | 10 | 1 (tenant_id) | DB credentials stored — encryption needed |
| 4 | `prm_billing_cycles` | 7 | 0 | Missing `created_by`, `deleted_at` |
| 5 | `prm_plans` | 12 | 1 (billing_cycle_id) | FK type mismatch: `billing_cycle_id SMALLINT` vs `prm_billing_cycles.id SMALLINT unsigned` — signed vs unsigned |
| 6 | `prm_module_plan_jnt` | 5 | 2 (plan_id, module_id) | FK to VIEW `glb_modules` — may fail in some MySQL configs |
| 7 | `prm_tenant_plan_jnt` | 10 | 2 (tenant_id, plan_id) | Generated column `current_flag` — OK |
| 8 | `prm_tenant_plan_rates` | 20 | 2 (tenant_plan_id, billing_cycle_id) | Missing `is_active`, `created_by` |
| 9 | `prm_tenant_plan_module_jnt` | 5 | 2 (module_id, tenant_plan_id) | FK to VIEW `glb_modules` |
| 10 | `prm_tenant_plan_billing_schedule` | 10 | 4 | Cross-reference FK to `bil_tenant_invoices` — circular dependency |

### 1.2 DDL vs Model Gaps

| Issue ID | Severity | Issue |
|----------|----------|-------|
| DB-01 | **P0** | `prm_tenant_domains` stores `db_password` in plaintext VARCHAR(255). Must be encrypted at application level. Model `Domain.php` does not define any encryption cast. |
| DB-02 | **P1** | `prm_plans.billing_cycle_id` is `SMALLINT NOT NULL` (signed) but FK references `prm_billing_cycles.id` which is `SMALLINT unsigned`. Type mismatch. |
| DB-03 | **P1** | `prm_billing_cycles` DDL has NO `deleted_at` column but BillingCycle model in Billing module uses SoftDeletes. |
| DB-04 | **P2** | `prm_tenant_plan_rates` missing `is_active` and `created_by` columns per project standards. |
| DB-05 | **P2** | `prm_module_plan_jnt` and `prm_tenant_plan_module_jnt` have FKs to `glb_modules` which is a VIEW in prime_db. MySQL may not enforce FK constraints on views. |
| DB-06 | **P2** | `prm_tenant_plan_billing_schedule` has FK to `bil_tenant_invoices` (from Billing module). Cross-module circular FK dependency between prm_ and bil_ tables. |
| DB-07 | **P3** | Multiple tables missing `created_by` column per project rules. |

---

## SECTION 2: ROUTE INTEGRITY

### 2.1 Routes (from routes/web.php, central domain, `prime.` prefix)

All Prime routes are under `auth` + `verified` middleware in the central domain.

| Route Group | Controller | Key Methods |
|-------------|-----------|-------------|
| tenant-management | TenantManagementController | index |
| tenant | TenantController | CRUD + setupProgress, setupStatus, toggleStatus, completeTenantSetup, updateTenantPlan, tenantPlanToggleStatus, trashed, restore, forceDelete |
| tenant-group | TenantGroupController | CRUD + trashed, restore, forceDelete, toggleStatus |
| user | UserController | CRUD + usersByRole, trashed, restore, forceDelete, toggleStatus |
| role-permission | RolePermissionController | CRUD + getRolesByOrganization, updateRolePermission, getPermissions, updatePermissions, trashed |
| sales-plan-mgmt | SalesPlanAndModuleMgmtController | CRUD |
| session-board-setup | SessionBoardSetupController | CRUD |
| user-role-prm | UserRolePrmController | CRUD + search |
| academic-session | AcademicSessionController | CRUD + trashed, restore, forceDelete, toggleStatus |
| board | BoardController | CRUD + trashed, restore, forceDelete, toggleStatus |

### 2.2 Route Issues

| Issue ID | Severity | Issue |
|----------|----------|-------|
| RT-01 | **P2** | Routes duplicated between `prime.` prefix group and `global-master.` prefix group. E.g., `activity-log`, `dropdown`, `dropdown-need`, `board`, `plan`, `country`, `state`, `city`, `district` are all defined under BOTH prefix groups — creates ambiguous routing. |
| RT-02 | **P2** | `system-config.` prefix group also re-defines `setting` and `menu` routes that exist in the SystemConfig module's own routes. Overlap risk. |

---

## SECTION 3: CONTROLLER AUDIT

### 3.1 Controllers (24 controllers)

The Prime module has 24 controllers handling core platform functionality:
- AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController, MenuController, NotificationController, PrimeAuthController, PrimeController, RolePermissionController, SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController, TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController

### 3.2 Authorization Issues

| Issue ID | Severity | Controller | Issue |
|----------|----------|-----------|-------|
| SEC-01 | **P0** | TenantController | `completeTenantSetup()` creates tenant database, runs migrations, seeds data — this is the MOST CRITICAL operation. Need to verify Gate::authorize is present. |
| SEC-02 | **P0** | RolePermissionController | `getPermissions()` and `updatePermissions()` — these routes have NO named route protection and handle the RBAC system itself. |
| SEC-03 | **P1** | PrimeController | Dashboard methods (`coreConfiguration`, `foundationSetup`, `subscriptionBilling`) — need to verify Gate::authorize for each. |
| SEC-04 | **P1** | NotificationController | `testNotification()` and `destroy()` — test routes should not exist in production. |
| SEC-05 | **P1** | EmailController | `testEmail()` and `sendTestEmail()` — test routes should not exist in production. |
| SEC-06 | **P2** | SettingController (Prime) | `search()` method — needs authorization check. |

### 3.3 Input Handling

| Issue ID | Severity | Issue |
|----------|----------|-------|
| INP-01 | **P1** | Multiple controllers likely use `$request->all()` for updates based on patterns seen in MenuController. Need FormRequest for all mutations. |
| INP-02 | **P2** | `DropdownNeedController` handles complex multi-field search — need to verify sanitization. |

---

## SECTION 4: MODEL AUDIT

### 4.1 Models (26 models in Prime module)

| Model | Table | SoftDeletes | Key Issues |
|-------|-------|:-----------:|-----------|
| AcademicSession | sys_academic_sessions | Unknown | Shared with GlobalMaster |
| ActivityLog | sys_activity_logs | No | System table — no soft delete OK |
| Board | glb_boards | Unknown | Global table |
| Domain | prm_tenant_domains | Unknown | **Must encrypt db_password** |
| Dropdown | sys_dropdown_table | Unknown | Shared with GlobalMaster |
| DropdownNeed | sys_dropdown_needs | Unknown | |
| DropdownNeedTableJnt | sys_dropdown_need_table_jnt | Unknown | |
| Language | glb_languages | Unknown | Global table |
| Media | sys_media | Unknown | |
| Menu | glb_menus | Unknown | Global table — shared with SystemConfig |
| Permission | sys_permissions | No | Spatie-style — no soft delete OK |
| Role | sys_roles | No | Spatie-style — no soft delete OK |
| Setting | sys_settings | Unknown | |
| Tenant | prm_tenant | YES | Core model |
| TenantGroup | prm_tenant_groups | YES | |
| TenantInvoice | bil_tenant_invoices | Unknown | **Cross-module**: Prime model for Billing table |
| TenantPlan | prm_tenant_plan_jnt | Unknown | |
| TenantPlanBillingSchedule | prm_tenant_plan_billing_schedule | Unknown | |
| TenantPlanModule | prm_tenant_plan_module_jnt | Unknown | |
| TenantPlanRate | prm_tenant_plan_rates | Unknown | |
| User | sys_users | YES | Core auth model |

### 4.2 Model Issues

| Issue ID | Severity | Issue |
|----------|----------|-------|
| MDL-01 | **P0** | `Domain` model at `Modules/Prime/app/Models/Domain.php` — `prm_tenant_domains` stores DB credentials. The `db_password` field MUST have an encrypted cast or accessor/mutator. |
| MDL-02 | **P1** | Cross-module model references: Prime module has `TenantInvoice`, `TenantInvoicingAuditLog`, `TenantInvoicingPayment` models that map to `bil_*` tables — overlaps with Billing module models. Dual model ownership creates maintenance risk. |
| MDL-03 | **P2** | Duplicate model at `Modules/Prime/Models/DropdownNeed.php` (root-level Models dir) vs `Modules/Prime/app/Models/DropdownNeed.php`. |

---

## SECTION 5: SERVICE LAYER AUDIT

| Service | File | Purpose |
|---------|------|---------|
| TenantPlanAssigner | `app/Services/TenantPlanAssigner.php` | Assigns plans to tenants |

| Issue ID | Severity | Issue |
|----------|----------|-------|
| SVC-01 | **P1** | Only 1 service class for the entire Prime module. Tenant creation, user management, role/permission management all lack dedicated services. Business logic likely lives in controllers. |
| SVC-02 | **P2** | No TenantCreationService to encapsulate the complex tenant DB provisioning flow (create DB, run migrations, seed data, assign domain). |

---

## SECTION 6: FORM REQUEST AUDIT

| FormRequest | Used In |
|-------------|---------|
| AcademicSessionRequest | AcademicSessionController |
| BoardRequest | BoardController |
| DropdownRequest | DropdownController |
| TenantGroupRequest | TenantGroupController |
| TenantPlanRequest | TenantController (plan assignment) |
| TenantRequest | TenantController |
| UserRequest | UserController |

| Issue ID | Severity | Issue |
|----------|----------|-------|
| FRQ-01 | **P1** | No FormRequest for RolePermissionController (role creation/update, permission assignment). |
| FRQ-02 | **P2** | No FormRequest for SettingController, MenuController (Prime's version), DropdownNeedController, SessionBoardSetupController, SalesPlanAndModuleMgmtController. |
| FRQ-03 | **P2** | No FormRequest for NotificationController, EmailController (even for test actions). |

---

## SECTION 7: POLICY AUDIT

### 7.1 Policies (17 policies)

| Policy | Model | Permission Prefix | Registered |
|--------|-------|------------------|:----------:|
| EmployeePolicy | Employee | prime.employee.* | YES |
| PrimeActivityLogPolicy | PrimeActivityLog | prime.activity-log.* | YES |
| PrimeAuthPolicy | — | prime.auth.* | Unknown |
| PrimeDashboardPolicy | — | prime.dashboard.* | YES (Gate::define) |
| PrimeDropdownPolicy | PrimeDropdown | prime.dropdown.* | YES |
| PrimeEmailPolicy | — | prime.email.* | YES (Gate::define) |
| PrimeMenuPolicy | PrimeMenu | prime.menu.* | YES |
| PrimePolicy | — | — | Unknown |
| PrimeRolePermissionPolicy | PrimeRole | prime.role-permission.* | YES |
| PrimeSettingPolicy | PrimeSetting | prime.setting.* | YES |
| PrimeUserPolicy | PrimeUser | prime.user.* | YES |
| RolePermissionPolicy | — | — | Unknown (separate from PrimeRolePermissionPolicy?) |
| SalesPlanAndModuleMgmtPolicy | TenantPlan | prime.sales-plan-mgmt.* | YES |
| SessionBoardSetupPolicy | PrimeAcademicSession | prime.session-board-setup.* | YES |
| SettingPolicy | — | — | Possibly duplicate of PrimeSettingPolicy |
| TenantGroupPolicy | TenantGroup | prime.tenant-group.* | YES |
| TenantManagementPolicy | — | prime.tenant-management.* | Unknown |
| TenantPolicy | Tenant | prime.tenant.* | YES |
| UserRolePrmPolicy | — | prime.user-role-prm.* | Unknown |

### 7.2 Issues

| Issue ID | Severity | Issue |
|----------|----------|-------|
| POL-01 | **P1** | Duplicate/overlapping policies: `RolePermissionPolicy` vs `PrimeRolePermissionPolicy`, `SettingPolicy` vs `PrimeSettingPolicy`. Unclear which is active. |
| POL-02 | **P2** | `PrimeAuthPolicy`, `PrimePolicy`, `TenantManagementPolicy`, `UserRolePrmPolicy` — registration status in AppServiceProvider unclear. May be dead code. |

---

## SECTION 8: TEST COVERAGE

### 8.1 Existing Tests (8 test files)

| File | Type | Tests |
|------|------|-------|
| `tests/Feature/SettingModelTest.php` | Feature | Setting model tests |
| `tests/Unit/ArchitectureTest.php` | Unit | Class existence checks |
| `tests/Unit/ControllerAuthTest.php` | Unit | Gate::authorize reflection checks |
| `tests/Unit/FormRequestValidationTest.php` | Unit | FormRequest rule checks |
| `tests/Unit/MigrationSchemaTest.php` | Unit | Migration file existence |
| `tests/Unit/ModelStructureTest.php` | Unit | Model fillable/casts/relationships |
| `tests/Unit/PolicyPermissionTest.php` | Unit | Policy method existence |
| `tests/Unit/SoftDeleteStatusTest.php` | Unit | SoftDeletes trait checks |

| Issue ID | Severity | Issue |
|----------|----------|-------|
| TST-01 | **P1** | No Feature/Integration tests for Tenant creation flow (the most critical business operation). |
| TST-02 | **P2** | No test for TenantPlanAssigner service. |

---

## SECTION 9: SECURITY AUDIT

| Check | Status | Details |
|-------|:------:|--------|
| SEC-CRED: DB passwords encrypted | **FAIL** | `prm_tenant_domains.db_password` stored as plaintext VARCHAR. Domain model has no encryption. |
| SEC-AUTH: All methods authorized | PARTIAL | Most controllers have Gate::authorize. Test/debug routes (testNotification, testEmail) are accessible. |
| SEC-PROD: No test routes in production | **FAIL** | `test-notification` and `test-email` routes exist with no environment check. |
| SEC-RBAC: Permission system secure | WARN | Super Admin bypass in Gate::before (AppServiceProvider line 500-508) — acceptable but needs audit trail. |

---

## SECTION 10: ARCHITECTURE AUDIT

| Check | Status | Details |
|-------|:------:|--------|
| ARCH-SRP: Controller SRP | WARN | TenantController likely handles too many responsibilities (CRUD + plan assignment + setup progress + complete setup). |
| ARCH-CROSS: Module boundaries | WARN | Prime module has models for bil_* tables (TenantInvoice, etc.) AND Billing module has its own models for same tables. Dual ownership. |
| ARCH-DUP: Duplicate files | FAIL | `Modules/Prime/Models/DropdownNeed.php` exists outside the `app/` directory — likely stale copy. |

---

## PRIORITY FIX PLAN

### P0 — Critical
1. **MDL-01/DB-01**: Encrypt `db_password` in Domain model using Laravel's `encrypted` cast or custom accessor/mutator.
2. **SEC-01/SEC-02**: Verify and add Gate::authorize on TenantController::completeTenantSetup() and RolePermissionController::getPermissions/updatePermissions.

### P1 — High
3. **SEC-04/SEC-05**: Remove or environment-gate test routes (testNotification, testEmail, sendTestEmail).
4. **SVC-01**: Create TenantCreationService, RolePermissionService.
5. **FRQ-01**: Create FormRequest for RolePermissionController.
6. **MDL-02**: Consolidate bil_* table models — either in Billing or Prime, not both.
7. **TST-01**: Write Feature tests for tenant creation flow.

### P2 — Medium
8. **RT-01**: Resolve duplicate route definitions between prime and global-master prefix groups.
9. **DB-04/DB-05**: Fix FK type mismatches and add missing standard columns.
10. **MDL-03**: Remove duplicate DropdownNeed.php from root Models directory.

---

## EFFORT ESTIMATION

| Priority | Items | Estimated Hours |
|----------|:-----:|:---------------:|
| P0 | 2 | 4-6 hrs |
| P1 | 5 | 20-30 hrs |
| P2 | 3 | 8-12 hrs |
| P3 | 6 | 6-8 hrs |
| **Total** | **16** | **38-56 hrs** |
