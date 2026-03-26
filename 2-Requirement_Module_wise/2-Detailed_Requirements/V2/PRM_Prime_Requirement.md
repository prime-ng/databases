# Prime Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** PRM  |  **Module Path:** `Modules/Prime/`
**Module Type:** Prime  |  **Database:** `prime_db + global_db`
**Table Prefix:** `prm_*`  |  **Processing Mode:** FULL
**RBS Reference:** PB, PC, PA, PH, PG (Platform-level modules)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Done/PRM_Prime_Requirement.md`
**Gap Analysis:** `3-Project_Planning/2-Gap_Analysis/2-Modules_Wise/2026Mar22/Prime_Deep_Gap_Analysis.md`
**Generation Batch:** 1/10

---

## TABLE OF CONTENTS
1. Executive Summary
2. Module Overview
3. Stakeholders & Actors
4. Functional Requirements
5. Data Model & Entity Specification
6. API & Route Specification
7. UI Screen Inventory & Field Mapping
8. Business Rules & Domain Constraints
9. Workflow & State Machine Definitions
10. Non-Functional Requirements
11. Cross-Module Dependencies
12. Test Case Reference & Coverage
13. Glossary & Terminology
14. Additional Suggestions
15. Appendices
16. V1 → V2 Delta Summary

---

## 1. Executive Summary

### 1.1 Purpose

The Prime module is the central SaaS platform management console for PrimeGurukul. It is the only module that operates on the **central domain** (`config('app.domain')`) and directly owns the `prime_db` database. It governs the complete multi-tenant lifecycle: school onboarding, isolated database provisioning, subscription plan management, module licensing, billing schedule generation, central RBAC, and global master data. All other ~40 modules are installed per-school through the tenant provisioning pipeline owned by this module.

### 1.2 Overall Completion

| Dimension | V1 Score | V2 Assessment | Grade |
|-----------|:--------:|:-------------:|:-----:|
| Feature Completeness | 90% | 90% | A- |
| Security | 65% | 65% | D+ |
| Performance | 65% | 65% | D+ |
| Test Coverage | 55% | 55% | D+ |
| Code Quality | 70% | 70% | C |
| Architecture | 75% | 75% | B- |
| **Overall** | **70%** | **70%** | **C** |

### 1.3 Module Statistics (Verified from Code Audit 2026-03-22)

| Artifact | Count | Notes |
|----------|:-----:|-------|
| Controllers | 21 | All in `app/Http/Controllers/` |
| Models | 27 | 26 in `app/Models/`, 1 duplicate in root `Models/` |
| Services | 1 | `TenantPlanAssigner` |
| FormRequests | 7 | See Section 4 for gaps |
| Policies | 19 | Includes duplicates — see SEC issues |
| Views (Blade) | 84 | Counted from `resources/views/` |
| Seeders | 2 | BillingCycleSeeder, PermissionSeeder (approx.) |
| Jobs | 1 | `SetupTenantDatabase` (in `app/Jobs/`) |
| Tests | 8 | 1 Feature + 7 Unit |
| DDL Tables (prm_*) | 8 | Core prime tables |
| DDL Tables (bil_*) | ~5 | Billing tables owned jointly |

### 1.4 Critical Issues Register (Carried Forward to V2)

| Bug ID | Severity | Description | Status |
|--------|----------|-------------|--------|
| BUG-PRM-001 | **CRITICAL (P0)** | `db_password` stored in plaintext in `prm_tenant_domains` | ❌ Open |
| BUG-PRM-002 | **HIGH (P1)** | `is_super_admin` mass-assignable in User model | ❌ Open |
| BUG-PRM-003 | **MEDIUM (P2)** | `$request->all()` used in `TenantController::update()` | ❌ Open |
| BUG-PRM-004 | FIXED | MigrateDatabase step was commented out | ✅ Fixed |
| BUG-PRM-005 | **HIGH (P1)** | No `TenantCreationService` — business logic in controller | ❌ Open |
| BUG-PRM-006 | **HIGH (P1)** | Test routes (`testEmail`, `testNotification`) in production | ❌ Open |
| BUG-PRM-007 | **MEDIUM (P2)** | Duplicate model: `Modules/Prime/Models/DropdownNeed.php` outside `app/` | ❌ Open |
| BUG-PRM-008 | **MEDIUM (P2)** | Duplicate routes between `prime.` and `global-master.` prefix groups | ❌ Open |

---

## 2. Module Overview

### 2.1 Business Purpose

Prime is the SaaS operations console for PrimeGurukul (the software company). Its core responsibilities are:

1. **Tenant Onboarding** — Create a new school tenant record, automatically provision an isolated MySQL database, run all tenant migrations (~297 migrations), seed a root admin user and organization record.
2. **Subscription & Module Licensing** — Define pricing plans, assign plans to tenants, enable/disable modules per tenant subscription.
3. **Billing Pipeline** — Generate billing schedules for the current academic session, feed the Billing module with pre-scheduled invoice dates.
4. **Central RBAC** — Manage Prime platform users (PrimeGurukul staff), their roles, and permission assignments.
5. **Global Master Data** — Own and maintain boards, languages, academic sessions, dropdowns, menus, and system settings that all tenant modules consume.
6. **Platform Dashboard** — Real-time visibility into tenant health, revenue, subscription trends, and overdue invoices.

### 2.2 Architecture

Prime operates exclusively on the **central domain** defined in `config('app.domain')`. Domain-scoped routing ensures that tenant subdomains (e.g., `school1.primeai.app`) never resolve to Prime routes.

```
Route::domain(config('app.domain'))->name("central.")->group(function () {
    // All Prime routes are here
});
```

The `Tenant` model extends `stancl/tenancy`'s `BaseTenant` and implements `TenantWithDatabase`, `HasDatabase`, `HasDomains`. Custom columns are declared via `getCustomColumns()` to bypass tenancy's JSON data store.

### 2.3 Three-Layer Database Context

| Layer | Database | Prefix | Prime Module Scope |
|-------|----------|--------|-------------------|
| Global | `global_db` | `glb_*` | Read-only consumer: boards, modules, languages, menus, cities |
| Central | `prime_db` | `prm_*`, `bil_*`, `sys_*` | Full owner: tenants, plans, billing, users, settings |
| Tenant | `tenant_{id}` | All prefixes | Creates via `SetupTenantDatabase` job; no ongoing read/write from Prime |

### 2.4 Navigation / Menu Path

```
Central Domain (primeai.app) > Prime Dashboard
├── Tenant Management
│   ├── Tenant Groups (prm_tenant_groups)
│   ├── Tenants (prm_tenant)
│   ├── Setup Progress (per-tenant view)
│   └── Complete Setup / Plan Assignment
├── Plans & Modules
│   ├── Plan Management (prm_plans)
│   ├── Module-Plan Mapping (prm_module_plan_jnt)
│   └── Billing Cycles (prm_billing_cycles)
├── Billing
│   ├── Billing Schedules (prm_tenant_plan_billing_schedule)
│   └── Invoices (bil_tenant_invoices)
├── Configuration
│   ├── Academic Sessions (sys_academic_sessions)
│   ├── Boards (glb_boards)
│   ├── Languages (glb_languages)
│   ├── Menus (glb_menus)
│   ├── Dropdowns (sys_dropdown_table)
│   └── Settings (sys_settings)
├── User Management
│   ├── Central Users (sys_user)
│   └── Roles & Permissions (sys_roles / sys_permissions)
└── Logs
    ├── Activity Logs (sys_activity_logs)
    └── Email Logs / Notifications
```

---

## 3. Stakeholders & Actors

| Actor | Role | Primary Access |
|-------|------|---------------|
| Prime Super Admin | Full platform control — all features | All Prime module screens; can set `is_super_admin` directly in DB |
| Prime Manager / Sales | Tenant onboarding, plan assignment | Tenant CRUD, Plan Management, Complete Setup |
| Prime Finance / Accounting | Invoice tracking, billing schedules | Billing Schedules, Invoice List |
| Prime IT/Ops | Settings, menus, dropdowns | Configuration screens |
| Queue Worker (system) | Automated tenant DB provisioning | Executes `SetupTenantDatabase` job |
| Tenant Admin | **No access to Prime** | Routes at their subdomain only — cannot reach central domain |

**Central Roles (Spatie RBAC, `prime.*` gate prefix):**
- `prime.tenant.*` — Tenant CRUD
- `prime.tenant-group.*` — Tenant group CRUD
- `prime.sales-plan-mgmt.*` — Plan management
- `prime.role-permission.*` — Role and permission management
- `prime.user.*` — Central user management
- `prime.dashboard.*` — Dashboard access
- `prime.activity-log.*` — Log viewing
- `prime.dropdown.*` — Dropdown management
- `prime.setting.*` — Settings management
- `prime.email.*` — Email testing (should be production-gated)

---

## 4. Functional Requirements

---

### FR-PRM-01: Tenant Registration & Onboarding
**Status:** ✅ Implemented (core flow) | 🟡 Partial (security hardening outstanding)
**RBS Ref:** PB — Tenant Management

#### Description
The most critical business operation in the entire platform. An admin creates a school record, and an asynchronous job automatically provisions a fully isolated MySQL database, runs all tenant migrations, and seeds a root user and organization.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-01.1 | Admin creates tenant with all required profile fields (code, name, address, contact, locale, currency) | P0 | ✅ |
| REQ-PRM-01.2 | On creation, `is_active = false` and `setup_status = 'pending'` until setup completes | P0 | ✅ |
| REQ-PRM-01.3 | Domain record is created as `{subdomain}.{config('app.domain')}` | P0 | ✅ |
| REQ-PRM-01.4 | `SetupTenantDatabase` job dispatched asynchronously after record creation | P0 | ✅ |
| REQ-PRM-01.5 | Registration confirmation email sent to `$tenant->email` via `TenantRegisteredMail` | P1 | ✅ |
| REQ-PRM-01.6 | All super admins notified via `TenantRegisteredNotification` | P1 | ✅ |
| REQ-PRM-01.7 | Activity log written on tenant creation | P2 | ✅ |
| REQ-PRM-01.8 | If setup fails, admin can re-dispatch `SetupTenantDatabase` from UI | P1 | ❌ Not implemented |
| REQ-PRM-01.9 | Root tenant user must be created with a randomly generated secure password (not hardcoded `password`) | P0 | ❌ Not implemented |
| REQ-PRM-01.10 | `db_password` in `prm_tenant_domains` must be stored encrypted, not plaintext | P0 | ❌ Not implemented |

#### `SetupTenantDatabase` Job Pipeline

| Stage | Progress Range | Action | Status |
|-------|:--------------:|--------|--------|
| CreateDatabase | 0% → 5% | `$tenant->database()->manager()->createDatabase($tenant)` | ✅ |
| RunMigrations | 5% → 88% | `Artisan::call('tenants:migrate', ['--tenants' => [$tenant->id]])` | ✅ |
| CreateRootUser | 88% → 93% | `User::create([...])` inside `$tenant->run()` | ✅ (but uses hardcoded `password`) |
| AddOrganization | 93% → 99% | `Organization::create([...])` inside `$tenant->run()` | ✅ |
| Completed | 100% | `TenantSetupCompletedNotification` sent | ✅ |
| Failed | frozen at N% | `TenantSetupFailedNotification` dispatched | ✅ |

Progress is written to `prm_tenant` directly via `DB::connection('central')` to avoid tenant-context interference. Per-migration progress tracking uses `MigrationStarted`/`MigrationEnded` events.

#### Acceptance Criteria
- AC-01.1: Given valid tenant creation form, the system creates tenant record, creates domain, dispatches job, sends email, and redirects to setup-progress page.
- AC-01.2: Given job completes all 4 stages: `setup_status = 'completed'`, `setup_progress = 100`, root user exists in tenant DB, organization record exists.
- AC-01.3: Given job fails at RunMigrations step: `setup_status = 'failed'`, progress frozen at last % before failure, failure notification sent to super admins.
- AC-01.4: Given job fails: admin sees a "Re-trigger Setup" button on the setup-progress page. (❌ Currently missing)
- AC-01.5: Given tenant domain is updated: stancl/tenancy resolves the new domain for all future requests.

#### Current Implementation
- `TenantController::store()` — `Modules/Prime/app/Http/Controllers/TenantController.php` (lines 55–87)
- `SetupTenantDatabase` job — `app/Jobs/SetupTenantDatabase.php`
- `TenantController::setupProgress()` and `setupStatus()` — implemented (lines 92–113)
- **BUG-PRM-001:** `Domain` model at `Modules/Prime/app/Models/Domain.php` has no encryption cast on `db_password`
- **BUG-PRM-003:** `TenantController::update()` uses `$request->all()` (line 141) not `$request->validated()`

#### Required Test Cases
- `tests/Feature/TenantOnboardingTest.php` — Full pipeline test (❌ Missing)
- `tests/Feature/SetupTenantDatabaseJobTest.php` — 4-stage job unit test (❌ Missing)
- `tests/Unit/Domain/DomainEncryptionTest.php` — Verify `db_password` is stored encrypted (❌ Missing)

---

### FR-PRM-02: Tenant Group Management
**Status:** ✅ Implemented
**RBS Ref:** PB — Tenant Management

#### Description
Tenants are organized into groups representing school chains, trusts, or managing committees. Every tenant must belong to exactly one group.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-02.1 | Admin can create, edit, soft-delete, restore, and force-delete tenant groups | P0 | ✅ |
| REQ-PRM-02.2 | Group fields: `code`, `short_name` (unique), `name`, `city_id`, `email`, `website_url`, `address_1`, `address_2`, `pincode` | P0 | ✅ |
| REQ-PRM-02.3 | On creation, `TenantGroupCreatedMail` sent to group email; `TenantGroupCreatedNotification` sent to super admins | P1 | ✅ |
| REQ-PRM-02.4 | Group cannot be deleted if it has active tenant records | P1 | 🟡 DB RESTRICT constraint exists; no friendly error message |
| REQ-PRM-02.5 | `is_active` toggle supported | P1 | ✅ |
| REQ-PRM-02.6 | Missing `created_by` column per project standards | P2 | ❌ DDL gap (DB-07) |

#### Acceptance Criteria
- AC-02.1: Given valid group form, group is created and email is sent to group's email address.
- AC-02.2: Given tenant group has associated tenants, delete attempt returns validation error (not DB exception).
- AC-02.3: Given `is_active` toggle, group immediately reflects new status on tenant domain routing.

#### Current Implementation
- `TenantGroupController` — full CRUD with `trashed`, `restore`, `forceDelete`, `toggleStatus`
- `TenantGroup` model — uses `SoftDeletes`
- `TenantGroupRequest` — FormRequest with validation rules
- Views: `tenant-group/` — index, create, edit, show, trash

#### Required Test Cases
- `tests/Feature/TenantGroupCrudTest.php` — CRUD + soft delete lifecycle (❌ Missing)

---

### FR-PRM-03: Subscription Plan Management
**Status:** ✅ Implemented (basic CRUD) | ❌ Missing: plan versioning on edit
**RBS Ref:** PC — Plan & Subscription

#### Description
Defines the pricing tier catalog. Plans specify which modules are included and at what pricing structure. A plan has a default billing cycle and three price points (monthly/quarterly/yearly).

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-03.1 | Admin can create/edit/deactivate plans | P0 | ✅ |
| REQ-PRM-03.2 | Plan fields: `plan_code` + `version` (composite unique), `name`, `description`, `billing_cycle_id`, `price_monthly`, `price_quarterly`, `price_yearly`, `currency`, `trial_days` | P0 | ✅ |
| REQ-PRM-03.3 | Plan-module mapping: admin selects which modules are included via `prm_module_plan_jnt` | P0 | ✅ |
| REQ-PRM-03.4 | When editing an existing plan, a new `version` must be created instead of mutating the old row (to preserve historical billing accuracy) | P1 | ❌ Not enforced |
| REQ-PRM-03.5 | Billing cycle options seeded: MONTHLY (1 month), QUARTERLY (3), YEARLY (12), ONE_TIME (0, non-recurring) | P0 | ✅ |
| REQ-PRM-03.6 | FK type mismatch: `prm_plans.billing_cycle_id SMALLINT` (signed) vs `prm_billing_cycles.id SMALLINT UNSIGNED` | P1 | ❌ DDL bug (DB-02) |

#### Acceptance Criteria
- AC-03.1: Given a plan is modified, a new version row is created; the previous version is deactivated, not overwritten.
- AC-03.2: Given a module is removed from a plan, existing tenant subscriptions for that plan are not affected until renewal.
- AC-03.3: Given billing_cycle_id FK mismatch is fixed, MySQL 8 strict mode does not reject inserts.

#### Current Implementation
- `SalesPlanAndModuleMgmtController` — CRUD
- Views: `sales-plan-and-module-mgmt/index.blade.php`
- **DB-02:** `prm_plans.billing_cycle_id SMALLINT` signed vs `prm_billing_cycles.id SMALLINT UNSIGNED` — type mismatch
- **DB-05:** FKs on `prm_module_plan_jnt` reference `glb_modules` which is a VIEW in prime_db — FK constraints may silently fail in MySQL

#### Required Test Cases
- `tests/Unit/Plan/PlanVersioningTest.php` — Verify new version on edit (❌ Missing)

---

### FR-PRM-04: Tenant Plan Assignment (TenantPlanAssigner)
**Status:** ✅ Implemented (service) | 🟡 Partial (discount/tax fields not fully surfaced in UI)
**RBS Ref:** PC — Plan & Subscription

#### Description
The transactional 5-step process of subscribing a tenant to a plan for a billing period. The `TenantPlanAssigner` service and `TenantController::updateTenantPlan()` both implement this logic (with the service being the canonical version).

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-04.1 | `TenantPlanAssigner::assign()` executes all 5 steps in a single `DB::transaction()` | P0 | ✅ |
| REQ-PRM-04.2 | Step 1: `prm_tenant_plan_jnt` — `firstOrNew` by (tenant_id, plan_id); sets subscription flags | P0 | ✅ |
| REQ-PRM-04.3 | Step 2: `prm_tenant_plan_rates` — creates rate record with pricing, discounts, taxes (tax1–tax4), credit_days | P0 | ✅ (discount/tax defaults to 0) |
| REQ-PRM-04.4 | Step 3: `prm_tenant_plan_module_jnt` — soft-disables existing, `updateOrCreate` for each new module | P0 | ✅ |
| REQ-PRM-04.5 | Step 4: `prm_tenant_plan_billing_schedule` — generates one entry per billing cycle between start/end dates clamped to academic session | P0 | ✅ |
| REQ-PRM-04.6 | Billing window clamped: `windowStart = max(start_date, session.start_date)`, `windowEnd = min(end_date, session.end_date)` | P0 | ✅ (in controller only — not in service) |
| REQ-PRM-04.7 | Active academic session must exist; `RuntimeException` thrown if none found | P0 | ✅ |
| REQ-PRM-04.8 | UI form surfaces all rate fields including discount, extra_charges, 4 tax types with remarks, credit_days | P1 | 🟡 Partial — discount/tax fields default to 0, not configurable via UI |
| REQ-PRM-04.9 | Duplicate logic between `TenantPlanAssigner::assign()` and `TenantController::updateTenantPlan()` should be refactored — controller must delegate to service | P2 | ❌ Both exist independently |
| REQ-PRM-04.10 | `completeTenantSetup()` uses incorrect Gate check (`prime.tenant-group.update`) — should use `prime.tenant.update` | P1 | ❌ BUG in authorization |

#### Acceptance Criteria
- AC-04.1: Given monthly billing from 2025-04-01 to 2026-03-31 within an academic session: 12 `prm_tenant_plan_billing_schedule` rows created.
- AC-04.2: Given billing window falls entirely outside the academic session: redirects with warning, no rows created.
- AC-04.3: Given transaction fails at step 3: all steps rolled back; no partial subscription state.
- AC-04.4: Given plan re-assignment (second call): old module rows set to `is_active = 0`, new modules added with `is_active = 1`, old billing schedule rows set to `is_active = 0`.
- AC-04.5: Given `completeTenantSetup()` is called by a user without `prime.tenant.update` permission: 403 response.

#### Current Implementation
- `TenantPlanAssigner` — `Modules/Prime/app/Services/TenantPlanAssigner.php`
- `TenantController::updateTenantPlan()` — lines 180–320 (duplicate logic)
- `TenantController::completeTenantSetup()` — line 165; uses wrong Gate check on line 167

#### Required Test Cases
- `tests/Feature/TenantPlanAssignerTest.php` — All 5 steps + rollback (❌ Missing)
- `tests/Unit/BillingScheduleGenerationTest.php` — Date range iteration correctness (❌ Missing)

---

### FR-PRM-05: Billing & Invoice Management
**Status:** 🟡 Partial — models exist, no dedicated invoice generation controller
**RBS Ref:** PC — Plan & Subscription

#### Description
The billing pipeline processes `prm_tenant_plan_billing_schedule` entries to generate `bil_tenant_invoices`. Invoice details include sub-total, discounts, 4 tax types, extra charges, and a calculated `net_payable_amount`. Invoices are visible on the Prime dashboard.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-05.1 | `bil_tenant_invoices` stores invoice with full financial breakdown | P0 | ✅ (DDL + models) |
| REQ-PRM-05.2 | Invoice number is auto-generated and unique | P0 | ✅ (DDL UNIQUE constraint) |
| REQ-PRM-05.3 | Invoice date = day after `billing_end_date`; payment_due_date = invoice_date + `credit_days` | P0 | ✅ (DDL computed) |
| REQ-PRM-05.4 | Scheduled command checks `bill_generated = false` and `schedule_billing_date <= today`, generates invoice, marks `bill_generated = true` | P0 | ❌ Not implemented — no `GenerateInvoicesCommand` exists |
| REQ-PRM-05.5 | `bil_tenant_invoicing_modules_jnt` records which modules were active during billed period | P1 | ✅ (DDL + TenantInvoiceModule model) |
| REQ-PRM-05.6 | Invoice status transitions: `PENDING → PAID` (via Billing module payment recording) | P1 | 🟡 DDL status field exists; Billing module owns the transition |
| REQ-PRM-05.7 | Cross-module FK: `prm_tenant_plan_billing_schedule.generated_invoice_id → bil_tenant_invoices.id` creates circular dependency between prm_ and bil_ schema sections | P2 | ❌ DB-06 — design issue |
| REQ-PRM-05.8 | Invoice list visible in Prime dashboard with overdue highlighting | P1 | ✅ (dashboard query implemented) |

#### Acceptance Criteria
- AC-05.1: Given `GenerateInvoicesCommand` runs on 2026-05-01: all schedules with `schedule_billing_date <= 2026-05-01` and `bill_generated = false` produce invoice records.
- AC-05.2: Given invoice is created: `net_payable_amount = sub_total - discount_amount + extra_charges + total_tax_amount`.
- AC-05.3: Given payment_due_date has passed and status is not PAID: invoice appears in overdue list on dashboard.

#### Current Implementation
- Models: `TenantInvoice`, `TenantInvoiceModule`, `TenantInvoicingAuditLog`, `TenantInvoicingPayment`
- Dashboard: `PrimeController::dashboard()` queries `TenantInvoice` for revenue/overdue stats
- **Missing:** `GenerateInvoicesCommand` (scheduled artisan command)
- **Ownership conflict (MDL-02):** Prime module has `TenantInvoice` model pointing at `bil_tenant_invoices`; Billing module also has models for same tables

#### Required Test Cases
- `tests/Feature/InvoiceGenerationCommandTest.php` — Schedule-to-invoice pipeline (❌ Missing)

---

### FR-PRM-06: Authentication & Authorization (Central)
**Status:** ✅ Implemented | 🟡 Test/debug routes not production-gated
**RBS Ref:** PH — User & Access Management

#### Description
Central authentication for PrimeGurukul staff. Scoped exclusively to the central domain. Uses Spatie Permission v6.21 for RBAC with a `prime.*` gate prefix.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-06.1 | Login: `POST /login` with email/password; session scoped to central domain | P0 | ✅ |
| REQ-PRM-06.2 | Logout: `POST /logout` with CSRF protection | P0 | ✅ |
| REQ-PRM-06.3 | Guest middleware applied to login routes; auth middleware applied to protected routes | P0 | ✅ |
| REQ-PRM-06.4 | Super Admin bypass via `Gate::before` in `AppServiceProvider` | P0 | ✅ (documented) |
| REQ-PRM-06.5 | Test email routes (`/test-email`, `/send-test-email`) must not be accessible in production | P1 | ❌ SEC-04/SEC-05 |
| REQ-PRM-06.6 | Test notification route (`/test-notification`) must be removed or environment-gated | P1 | ❌ SEC-04 |
| REQ-PRM-06.7 | Two-factor authentication flag (`two_factor_auth_enabled`) exists on user; full 2FA flow not implemented | P2 | 🟡 Flag only |

#### Acceptance Criteria
- AC-06.1: Given correct credentials on central domain: session is established, user redirected to dashboard.
- AC-06.2: Given correct credentials on tenant subdomain: user is NOT routed to Prime login — they reach tenant login instead.
- AC-06.3: Given unauthenticated request to a protected route: redirect to `prime.login`.
- AC-06.4: Given production environment: test routes return 404 or are not registered.

#### Current Implementation
- `PrimeAuthController` — `login()`, `logout()`, `index()` (login view)
- `routes/web.php` — domain-scoped auth routes
- `EmailController` — has `testEmail()` and `sendTestEmail()` methods with no environment check
- `NotificationController` — has `testNotification()` with no environment check

#### Required Test Cases
- `tests/Feature/PrimeAuthTest.php` — Login/logout/guest-redirect flow (❌ Missing)

---

### FR-PRM-07: Central User Management
**Status:** ✅ Implemented | ❌ `is_super_admin` mass-assignment vulnerability
**RBS Ref:** PH — User & Access Management

#### Description
Manages PrimeGurukul platform users (not school-level users). Central users can be assigned roles via Spatie Permission. The `is_super_admin` flag grants full bypass of all authorization gates.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-07.1 | Full CRUD for central users: create, edit, soft-delete, restore, force-delete | P0 | ✅ |
| REQ-PRM-07.2 | User fields: `name`, `email`, `emp_code`, `phone_no`, `mobile_no`, `short_name`, `is_active`, `two_factor_auth_enabled` | P0 | ✅ |
| REQ-PRM-07.3 | Password set on creation via `Hash::make()`; `LoginMail` sent to new user | P0 | ✅ |
| REQ-PRM-07.4 | `is_super_admin` must NOT be in `$fillable` — must be in `$guarded` or absent from fillable list | P0 | ❌ BUG-PRM-002 |
| REQ-PRM-07.5 | Super admin promotion via DB direct operation or dedicated protected artisan command only | P0 | ❌ No artisan command exists |
| REQ-PRM-07.6 | Role assignment: user can be assigned one or more Spatie roles via `UserRolePrmController` | P1 | ✅ |
| REQ-PRM-07.7 | `UserController::index()` contains hardcoded `rand()` calls for `$totalStudents` and `$totalClasses` — stub data | P2 | ❌ Code quality issue |
| REQ-PRM-07.8 | `UserController::index()` hardcodes `$totalRoles = 100` instead of querying actual count | P2 | ❌ Code quality issue |
| REQ-PRM-07.9 | `usersByRole()` method does not filter users by role — returns all users regardless of `$role` param | P1 | ❌ Stub method |

#### Acceptance Criteria
- AC-07.1: Given user creation form, `is_super_admin` cannot be set via any form field or API input.
- AC-07.2: Given `usersByRole('admin')`, only users with that role are returned.
- AC-07.3: Given new user creation, user receives login email with credentials.
- AC-07.4: Given user soft-deleted: user cannot log in; their records remain for audit trail.

#### Current Implementation
- `UserController` — `Modules/Prime/app/Http/Controllers/UserController.php`
- `UserRequest` — FormRequest (excludes `is_super_admin` from validation rules — must verify `$guarded`)
- `User` model — `App\Models\User` (shared with tenant side)
- **BUG-PRM-002:** Verify `is_super_admin` excluded from `$fillable` in `App\Models\User`

#### Required Test Cases
- `tests/Unit/UserModel/SuperAdminProtectionTest.php` — Mass assignment protection (❌ Missing)
- `tests/Feature/UserCrudTest.php` — Full user CRUD lifecycle (❌ Missing)

---

### FR-PRM-08: Role & Permission Management (Central RBAC)
**Status:** ✅ Implemented | 🟡 Missing FormRequest; duplicate policies
**RBS Ref:** PH — User & Access Management

#### Description
Central RBAC for Prime platform users. Roles use Spatie Permission v6.21. Permissions follow a `module.feature.action` naming convention (e.g., `prime.tenant.create`). Roles can be assigned per-organization (school-scoped) or platform-wide.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-08.1 | Full CRUD for roles: create, edit, delete | P0 | ✅ |
| REQ-PRM-08.2 | Role fields: `name`, `short_name`, `description`, `organization_id`, `is_system` | P0 | ✅ |
| REQ-PRM-08.3 | Permissions listed grouped by module and feature in UI | P0 | ✅ |
| REQ-PRM-08.4 | `syncPermissions()` called on role save to update permission assignments | P0 | ✅ |
| REQ-PRM-08.5 | `updateRolePermission()` — AJAX endpoint for individual permission toggle | P1 | ✅ |
| REQ-PRM-08.6 | `updatePermissions()` — bulk sync via AJAX | P1 | ✅ |
| REQ-PRM-08.7 | `getPermissions()` — returns role's current permissions as JSON; currently has no Gate authorization | P0 | ❌ SEC-02 |
| REQ-PRM-08.8 | `RolePermissionController::store()` uses `Modules\SchoolSetup\Http\Requests\RolePermissionRequest` from a different module — should have its own FormRequest | P1 | ❌ FRQ-01 |
| REQ-PRM-08.9 | Duplicate/overlapping policies: `RolePermissionPolicy` vs `PrimeRolePermissionPolicy` — one may be dead code | P2 | ❌ POL-01 |
| REQ-PRM-08.10 | `destroy()` method calls `$role->save()` without deleting — stub behavior | P1 | ❌ Incomplete |

#### Acceptance Criteria
- AC-08.1: Given unauthenticated request to `getPermissions()`: returns 403 (not open JSON endpoint).
- AC-08.2: Given permission `prime.tenant.create` toggled OFF for a role: users with that role cannot access tenant creation screen.
- AC-08.3: Given `destroy()` called: role is soft-deleted and users lose that role's permissions.

#### Current Implementation
- `RolePermissionController` — `Modules/Prime/app/Http/Controllers/RolePermissionController.php`
- `Role` model — `Modules/Prime/app/Models/Role.php` (extends Spatie Role)
- `Permission` model — `Modules/Prime/app/Models/Permission.php` (extends Spatie Permission)
- Uses `RolePermissionRequest` from `Modules\SchoolSetup` — cross-module dependency

#### Required Test Cases
- `tests/Feature/RolePermissionCrudTest.php` — Role CRUD + permission sync (❌ Missing)
- `tests/Unit/RolePermission/GetPermissionsAuthTest.php` — Verify Gate on getPermissions (❌ Missing)

---

### FR-PRM-09: Global Master Data Management
**Status:** ✅ Implemented (all sub-features)
**RBS Ref:** PG — System Configuration

#### Description
Prime owns the global reference data consumed by all modules across all tenants: education boards, languages, academic sessions, dropdown definitions, and navigation menus.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-09.1 | Boards: CRUD with soft-delete, restore, force-delete, toggleStatus | P0 | ✅ |
| REQ-PRM-09.2 | Languages: CRUD with soft-delete | P0 | ✅ |
| REQ-PRM-09.3 | Academic Sessions: CRUD with `start_date`, `end_date`, `is_current` flag | P0 | ✅ |
| REQ-PRM-09.4 | `AcademicSession::current()` scope used platform-wide; required for plan assignment | P0 | ✅ |
| REQ-PRM-09.5 | Dropdown management: three controllers for different aspects of dropdown system | P0 | ✅ |
| REQ-PRM-09.6 | Menu management: hierarchical `glb_menus` with module associations | P1 | ✅ |
| REQ-PRM-09.7 | Route duplication: `board`, `academic-session`, `dropdown` routes defined under both `prime.` and `global-master.` prefixes | P1 | ❌ RT-01 |
| REQ-PRM-09.8 | `SessionBoardSetupController` — combined view for session + board setup | P1 | ✅ |

#### Acceptance Criteria
- AC-09.1: Given no active academic session: `TenantPlanAssigner` throws `RuntimeException` — plan assignment is blocked.
- AC-09.2: Given board `CBSE` deactivated: it no longer appears in school setup dropdowns across all tenants.
- AC-09.3: Given dropdown value added: it becomes available in all tenant UI dropdowns that reference that dropdown type.

#### Current Implementation
- `BoardController`, `LanguageController`, `AcademicSessionController`, `DropdownController`, `DropdownMgmtController`, `DropdownNeedController`, `MenuController`, `SessionBoardSetupController`
- **RT-01:** Duplicate route definitions — `global-master.board.*` and `prime.board.*` exist simultaneously

---

### FR-PRM-10: System Settings
**Status:** ✅ Implemented
**RBS Ref:** PG — System Configuration

#### Description
Key-value settings store for platform-wide configuration: SMTP credentials, SMS provider, general options.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-10.1 | CRUD for system settings with key-value pairs | P0 | ✅ |
| REQ-PRM-10.2 | `SettingController::search()` method lacks authorization gate | P2 | ❌ SEC-06 |
| REQ-PRM-10.3 | Route duplication: `setting` routes overlap between `prime.` and `system-config.` prefix groups | P2 | ❌ RT-02 |
| REQ-PRM-10.4 | Duplicate policies: `SettingPolicy` vs `PrimeSettingPolicy` — registration status unclear | P2 | ❌ POL-01 |

---

### FR-PRM-11: Platform Dashboard & Analytics
**Status:** ✅ Implemented
**RBS Ref:** PA — Dashboard & Analytics

#### Description
Real-time platform-wide metrics visible to Prime admins. The dashboard aggregates tenant health, revenue statistics, subscription trends, overdue invoices, and recent activity logs.

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-11.1 | Tenant stats: total, active, inactive | P0 | ✅ |
| REQ-PRM-11.2 | User stats: total, active, super admin count | P0 | ✅ |
| REQ-PRM-11.3 | Billing stats: total revenue, total paid, outstanding, overdue invoice count | P0 | ✅ |
| REQ-PRM-11.4 | Subscription stats: active plans, trial plans, auto-renew plans | P0 | ✅ |
| REQ-PRM-11.5 | Monthly revenue for last 12 months (invoiced vs collected) — chart data | P1 | ✅ |
| REQ-PRM-11.6 | Tenant registration trend — last 12 months — chart data | P1 | ✅ |
| REQ-PRM-11.7 | Invoice status distribution (pie chart data) | P1 | ✅ |
| REQ-PRM-11.8 | Recent activity logs (last 15) | P1 | ✅ |
| REQ-PRM-11.9 | Overdue invoices list (top 10 by due date) | P1 | ✅ |
| REQ-PRM-11.10 | Notifications for current user | P1 | ✅ |
| REQ-PRM-11.11 | No database query optimization — all queries executed inline in `dashboard()` method (N+1 risk) | P2 | ❌ Performance concern |
| REQ-PRM-11.12 | Sub-dashboards: `coreConfiguration()`, `foundationSetup()`, `subscriptionBilling()`, `schoolSetup()`, `operationManagement()` — all return static views with no data | P2 | 🟡 Stub views |

#### Acceptance Criteria
- AC-11.1: Given dashboard loads: all stat cards display accurate real-time counts.
- AC-11.2: Given an invoice becomes overdue: it appears in the overdue list on next page load.
- AC-11.3: Given a new tenant is registered: tenant registration trend chart updates on next dashboard load.

#### Current Implementation
- `PrimeController::dashboard()` — `Modules/Prime/app/Http/Controllers/PrimeController.php` (lines 57–150)
- All stats computed inline via Eloquent queries
- Views: `prime/dashboard.blade.php`

---

### FR-PRM-12: Activity Logs & Monitoring
**Status:** ✅ Implemented
**RBS Ref:** PA — Dashboard & Analytics

#### Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| REQ-PRM-12.1 | `ActivityLogController` displays `sys_activity_logs` with filtering | P1 | ✅ |
| REQ-PRM-12.2 | All tenant create/update/plan-change operations call `activityLog()` helper | P1 | 🟡 Implemented in `store()`, may be missing from other methods |
| REQ-PRM-12.3 | Activity logs accessible only to users with `prime.activity-log.viewAny` permission | P0 | ✅ |

---

## 5. Data Model & Entity Specification

### 5.1 Table: `prm_tenant_groups`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | INT UNSIGNED | PK AUTO_INCREMENT | |
| `code` | VARCHAR(20) | NOT NULL | |
| `short_name` | VARCHAR(50) | NOT NULL, UNIQUE (`uq_tenantGroups_shortName`) | |
| `name` | VARCHAR(150) | NOT NULL | |
| `address_1` | VARCHAR(200) | DEFAULT NULL | |
| `address_2` | VARCHAR(200) | DEFAULT NULL | |
| `city_id` | INT UNSIGNED | NOT NULL, FK → `glb_cities.id` RESTRICT | |
| `pincode` | VARCHAR(10) | DEFAULT NULL | |
| `website_url` | VARCHAR(150) | DEFAULT NULL | |
| `email` | VARCHAR(100) | DEFAULT NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |
| ~~`created_by`~~ | ~~INT~~ | ~~MISSING~~ | ❌ DB-07 — missing per project standards |

**Indexes:** UNIQUE on `short_name`
**FKs:** `city_id → glb_cities.id` ON DELETE RESTRICT

---

### 5.2 Table: `prm_tenant`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | INT UNSIGNED | PK AUTO_INCREMENT | NOTE: stancl/tenancy normally uses UUID; this project uses INT |
| `tenant_group_id` | INT UNSIGNED | NOT NULL, FK → `prm_tenant_groups.id` RESTRICT | |
| `code` | VARCHAR(20) | NOT NULL, UNIQUE (`uq_tenant_code`) | |
| `short_name` | VARCHAR(50) | NOT NULL | |
| `name` | VARCHAR(150) | NOT NULL | |
| `udise_code` | VARCHAR(30) | DEFAULT NULL | Government UDISE identifier |
| `affiliation_no` | VARCHAR(60) | DEFAULT NULL | Board affiliation number |
| `crc_code` | VARCHAR(30) | DEFAULT NULL | CRC Code |
| `brc_code` | VARCHAR(30) | DEFAULT NULL | BRC Code |
| `instruction_language` | VARCHAR(20) | DEFAULT NULL | FK to `sys_dropdown_table.id` (soft ref) |
| `rural_urban` | ENUM('RURAL','URBAN') | DEFAULT 'URBAN' | |
| `email` | VARCHAR(100) | DEFAULT NULL | |
| `website_url` | VARCHAR(150) | DEFAULT NULL | |
| `address_1` | VARCHAR(200) | DEFAULT NULL | |
| `address_2` | VARCHAR(200) | DEFAULT NULL | |
| `area` | VARCHAR(100) | DEFAULT NULL | |
| `city_id` | INT UNSIGNED | NOT NULL, FK → `glb_cities.id` RESTRICT | |
| `pincode` | VARCHAR(10) | DEFAULT NULL | |
| `phone_1` | VARCHAR(20) | DEFAULT NULL | |
| `phone_2` | VARCHAR(20) | DEFAULT NULL | |
| `whatsapp_number` | VARCHAR(20) | DEFAULT NULL | |
| `longitude` | DECIMAL(10,7) | DEFAULT NULL | |
| `latitude` | DECIMAL(10,7) | DEFAULT NULL | |
| `locale` | VARCHAR(16) | DEFAULT 'en_IN' | |
| `currency` | VARCHAR(8) | DEFAULT 'INR' | |
| `established_date` | DATE | DEFAULT NULL | |
| `is_active` | TINYINT(1) | NOT NULL DEFAULT 1 | |
| `setup_status` | VARCHAR | | 'pending' / 'creating_database' / 'running_migrations' / 'creating_root_user' / 'adding_organization' / 'completed' / 'failed' |
| `setup_progress` | INT | | 0–100 |
| `setup_message` | VARCHAR | | Human-readable status message |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |
| `created_at` | TIMESTAMP | NULL | |
| `updated_at` | TIMESTAMP | NULL | |

**Model custom columns** declared via `getCustomColumns()` for stancl/tenancy v3.9 compatibility (bypasses JSON data column).
**Relationships:** `tenantGroup()`, `tenantPlans()`, `billingSchedules()`, `invoices()`, `domains()` (via HasDomains)
**Media:** Implements `HasMedia` via `spatie/laravel-medialibrary`; collection `tenant_img` with small/medium/large conversions.

---

### 5.3 Table: `prm_tenant_domains`

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| `id` | INT UNSIGNED | PK AUTO_INCREMENT | |
| `tenant_id` | INT UNSIGNED | NOT NULL, FK → `prm_tenant.id` RESTRICT | |
| `domain` | VARCHAR(255) | NOT NULL | Full domain: `schoolname.primeai.app` |
| `db_name` | VARCHAR(100) | NOT NULL | Tenant database name |
| `db_host` | VARCHAR(200) | NOT NULL | Database host |
| `db_port` | VARCHAR(10) | NOT NULL DEFAULT '3306' | |
| `db_username` | VARCHAR(100) | NOT NULL | Database username |
| `db_password` | VARCHAR(255) | NOT NULL | **CRITICAL SECURITY ISSUE — stored as plaintext** |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_at` | TIMESTAMP | | |
| `updated_at` | TIMESTAMP | NULL | |
| `deleted_at` | TIMESTAMP | NULL | Soft delete |

**BUG-PRM-001:** `db_password` stored as plaintext VARCHAR(255). The `Domain` model (`Modules/Prime/app/Models/Domain.php`) extends `BaseDomain` with only a `$table` override — no encryption cast defined. Fix: add `protected $casts = ['db_password' => 'encrypted'];` to Domain model AND update DDL column size to VARCHAR(500) to accommodate encrypted value length.

---

### 5.4 Table: `prm_billing_cycles`

| Column | Type | Notes |
|--------|------|-------|
| `id` | SMALLINT UNSIGNED PK | |
| `short_name` | VARCHAR(50) UNIQUE | 'MONTHLY', 'QUARTERLY', 'YEARLY', 'ONE_TIME' |
| `name` | VARCHAR(50) | Human-readable name |
| `months_count` | TINYINT UNSIGNED | 1, 3, 12, or 0 (ONE_TIME) |
| `description` | VARCHAR(255) DEFAULT NULL | |
| `is_recurring` | TINYINT(1) DEFAULT 1 | false for ONE_TIME |
| `is_active` | TINYINT(1) DEFAULT 1 | |

**DB-03 Note:** BillingCycle model in the Billing module uses `SoftDeletes` but this DDL has no `deleted_at` column.

---

### 5.5 Table: `prm_plans`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INT UNSIGNED PK | |
| `plan_code` | VARCHAR(20) NOT NULL | Part of composite unique |
| `version` | INT UNSIGNED DEFAULT 0 | Part of composite unique; increment on edit |
| `name` | VARCHAR(100) NOT NULL | |
| `description` | VARCHAR(255) DEFAULT NULL | |
| `billing_cycle_id` | SMALLINT NOT NULL | **FK type mismatch (signed vs unsigned) — DB-02** |
| `price_monthly` | DECIMAL(12,2) DEFAULT NULL | |
| `price_quarterly` | DECIMAL(12,2) DEFAULT NULL | |
| `price_yearly` | DECIMAL(12,2) DEFAULT NULL | |
| `currency` | CHAR(3) DEFAULT 'INR' | |
| `trial_days` | INT UNSIGNED DEFAULT 0 | |
| `is_active` | TINYINT(1) DEFAULT 1 | |
| `deleted_at` | TIMESTAMP NULL | Soft delete |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**UNIQUE:** `(plan_code, version)` — enforces versioning.

---

### 5.6 Table: `prm_module_plan_jnt`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INT UNSIGNED PK | |
| `plan_id` | INT UNSIGNED | FK → `prm_plans.id` ON DELETE CASCADE |
| `module_id` | INT UNSIGNED | FK → `glb_modules.id` — **DB-05: glb_modules is a VIEW; FK may not be enforced** |
| `is_active` | TINYINT(1) UNSIGNED NOT NULL | |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.7 Table: `prm_tenant_plan_jnt`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INT UNSIGNED PK | |
| `tenant_id` | INT UNSIGNED | FK → `prm_tenant.id` RESTRICT |
| `plan_id` | INT UNSIGNED | FK → `prm_plans.id` RESTRICT |
| `is_subscribed` | TINYINT(1) DEFAULT 1 | |
| `is_trial` | TINYINT(1) DEFAULT 0 | |
| `auto_renew` | TINYINT(1) DEFAULT 1 | |
| `automatic_billing` | TINYINT(1) DEFAULT 1 | |
| `status` | VARCHAR(20) DEFAULT 'ACTIVE' | 'ACTIVE', 'SUSPENDED', 'CANCELED', 'EXPIRED' |
| `is_active` | TINYINT(1) DEFAULT 1 | |
| `current_flag` | INT GENERATED STORED | `CASE WHEN is_subscribed=1 THEN tenant_id ELSE NULL END` |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**UNIQUE:** `(current_flag, plan_id)` — prevents two active subscriptions of the same plan per tenant.

---

### 5.8 Table: `prm_tenant_plan_rates`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INT UNSIGNED PK | |
| `tenant_plan_id` | INT UNSIGNED | FK → `prm_tenant_plan_jnt.id` ON DELETE CASCADE |
| `start_date` | DATE | Plan validity start |
| `end_date` | DATE | Plan validity end |
| `billing_cycle_id` | SMALLINT UNSIGNED | FK → `prm_billing_cycles.id` RESTRICT |
| `billing_cycle_day` | TINYINT DEFAULT 1 | Day of month for billing (derived from start_date.day) |
| `monthly_rate` | DECIMAL(12,2) NOT NULL | Base monthly rate |
| `rate_per_cycle` | DECIMAL(12,2) NOT NULL | Rate per billing period |
| `currency` | CHAR(3) DEFAULT 'INR' | |
| `min_billing_qty` | INT UNSIGNED DEFAULT 1 | Minimum chargeable licenses |
| `discount_percent` | DECIMAL(5,2) DEFAULT 0.00 | |
| `discount_amount` | DECIMAL(12,2) DEFAULT 0.00 | |
| `discount_remark` | VARCHAR(50) NULL | |
| `extra_charges` | DECIMAL(12,2) DEFAULT 0.00 | |
| `charges_remark` | VARCHAR(50) NULL | |
| `tax1_percent` – `tax4_percent` | DECIMAL(5,2) DEFAULT 0.00 | 4 configurable tax types (GST, IGST, CGST, etc.) |
| `tax1_remark` – `tax4_remark` | VARCHAR(50) NULL | Tax type labels |
| `credit_days` | SMALLINT UNSIGNED NOT NULL | Days before payment due |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

**UNIQUE:** `(tenant_plan_id, start_date, end_date)` — prevents duplicate rate periods.
**DB-04:** Missing `is_active` and `created_by` columns per project standards.

---

### 5.9 Table: `prm_tenant_plan_module_jnt`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INT UNSIGNED PK | |
| `module_id` | INT UNSIGNED | FK → `glb_modules.id` — **DB-05: VIEW FK issue** |
| `tenant_plan_id` | INT UNSIGNED | FK → `prm_tenant_plan_jnt.id` RESTRICT |
| `is_active` | TINYINT(1) DEFAULT 1 | Soft-disable on plan change; never deleted |
| `created_at` | TIMESTAMP NULL | |
| `updated_at` | TIMESTAMP NULL | |

---

### 5.10 Table: `prm_tenant_plan_billing_schedule`

| Column | Type | Notes |
|--------|------|-------|
| `id` | INT UNSIGNED PK | |
| `tenant_plan_id` | INT UNSIGNED | FK → `prm_tenant_plan_jnt.id` ON DELETE CASCADE |
| `tenant_id` | INT UNSIGNED | FK → `prm_tenant.id` ON DELETE CASCADE |
| `billing_cycle_id` | SMALLINT UNSIGNED | FK → `prm_billing_cycles.id` RESTRICT |
| `schedule_billing_date` | DATE NOT NULL | Date when invoice should be generated |
| `billing_start_date` | DATE NOT NULL | Period start |
| `billing_end_date` | DATE NOT NULL | Period end |
| `bill_generated` | TINYINT(1) DEFAULT 0 | Set to 1 after invoice is created |
| `generated_invoice_id` | INT UNSIGNED DEFAULT NULL | FK → `bil_tenant_invoices.id` — **DB-06: cross-module circular FK** |
| `is_active` | TINYINT(1) DEFAULT 1 | Soft-disable on plan re-assignment |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP |

---

### 5.11 Entity Relationship Summary

```
prm_tenant_groups (1) ──── (N) prm_tenant
prm_tenant        (1) ──── (N) prm_tenant_domains
prm_tenant        (1) ──── (N) prm_tenant_plan_jnt ──── (N) prm_plans
prm_plans         (N) ──── (N) glb_modules           [via prm_module_plan_jnt]
prm_tenant_plan_jnt (1) ── (N) prm_tenant_plan_rates
prm_tenant_plan_jnt (1) ── (N) prm_tenant_plan_module_jnt
prm_tenant_plan_jnt (1) ── (N) prm_tenant_plan_billing_schedule
prm_tenant_plan_billing_schedule (N) → (1) bil_tenant_invoices [generated_invoice_id]
prm_tenant        (1) ──── (N) bil_tenant_invoices    [via tenant_id]
prm_billing_cycles (1) ─── (N) prm_plans
prm_billing_cycles (1) ─── (N) prm_tenant_plan_rates
prm_billing_cycles (1) ─── (N) prm_tenant_plan_billing_schedule
```

---

## 6. API & Route Specification

### 6.1 Route Configuration

All Prime routes are domain-scoped in `Modules/Prime/routes/web.php`. Additional routes for sub-features are loaded by the module's `RouteServiceProvider` from separate route files (e.g., a `Navbar.php` route file).

```php
Route::domain(config('app.domain'))->name("central.")->group(function () {
    // Public
    Route::get('/', [PrimeController::class, 'index'])->name('prime.index');
    // Dashboard
    Route::get('/dashboard', ...)->middleware(['auth','verified'])->name('prime.dashboard');
    // Auth
    Route::middleware('guest')->name('prime.')->group(/* login */);
    Route::middleware('auth')->name('prime.')->group(/* logout */);
});
```

### 6.2 Route Inventory (from Gap Analysis — routes/web.php audit)

| Route Group | Controller | Key Methods | Gate Prefix |
|-------------|-----------|-------------|-------------|
| `tenant-management` | TenantManagementController | `index` | `prime.tenant-management.*` |
| `tenant` | TenantController | CRUD + `setupProgress`, `setupStatus`, `toggleStatus`, `completeTenantSetup`, `updateTenantPlan`, `tenantPlanToggleStatus`, `trashed`, `restore`, `forceDelete` | `prime.tenant.*` |
| `tenant-group` | TenantGroupController | CRUD + `trashed`, `restore`, `forceDelete`, `toggleStatus` | `prime.tenant-group.*` |
| `user` | UserController | CRUD + `usersByRole`, `trashed`, `restore`, `forceDelete`, `toggleStatus` | `prime.user.*` |
| `role-permission` | RolePermissionController | CRUD + `getRolesByOrganization`, `updateRolePermission`, `getPermissions`, `updatePermissions`, `trashed` | `prime.role-permission.*` |
| `sales-plan-mgmt` | SalesPlanAndModuleMgmtController | CRUD | `prime.sales-plan-mgmt.*` |
| `session-board-setup` | SessionBoardSetupController | CRUD | `prime.session-board-setup.*` |
| `user-role-prm` | UserRolePrmController | CRUD + `search` | `prime.user-role-prm.*` |
| `academic-session` | AcademicSessionController | CRUD + `trashed`, `restore`, `forceDelete`, `toggleStatus` | `prime.academic-session.*` |
| `board` | BoardController | CRUD + `trashed`, `restore`, `forceDelete`, `toggleStatus` | `prime.board.*` |

### 6.3 JSON API Endpoints

| Endpoint | Method | Controller@Method | Response |
|----------|--------|-------------------|----------|
| `/tenant/{id}/setup-status` | GET | `TenantController@setupStatus` | `{ status, progress, message, name }` |
| `/role-permission/{role}/permissions` | GET | `RolePermissionController@getPermissions` | `{ permissions: [...] }` |
| `/role-permission/{role}/update-permission` | POST | `RolePermissionController@updateRolePermission` | `{ success, message }` |
| `/role-permission/{role}/update-permissions` | POST | `RolePermissionController@updatePermissions` | `{ message }` |

### 6.4 Route Issues (from Gap Analysis)

| Issue | Severity | Description |
|-------|----------|-------------|
| RT-01 | P2 | `board`, `academic-session`, `dropdown`, `activity-log`, `country`, `state`, `city`, `district` defined under BOTH `prime.` and `global-master.` prefixes — ambiguous routing |
| RT-02 | P2 | `setting` and `menu` routes overlap between `prime.` and `system-config.` prefix groups |

---

## 7. UI Screen Inventory & Field Mapping

### 7.1 Prime Dashboard (`prime/dashboard.blade.php`)

| Section | Data Source | Status |
|---------|-------------|--------|
| Tenant stat cards (total/active/inactive) | `Tenant::count()` | ✅ |
| User stat cards | `User::count()` | ✅ |
| Revenue cards (total/paid/outstanding/overdue) | `TenantInvoice::sum()` | ✅ |
| Subscription cards (active/trial/auto-renew) | `TenantPlan::where()` | ✅ |
| Monthly revenue chart (12-month) | `TenantInvoice::selectRaw()` | ✅ |
| Tenant registration trend chart | `Tenant::selectRaw()` | ✅ |
| Invoice status pie chart | `TenantInvoice::groupBy('status')` | ✅ |
| Recent tenants table | `Tenant::with('tenantGroup')->latest()->take(10)` | ✅ |
| Overdue invoices list | `TenantInvoice::where(due<today)` | ✅ |
| Recent activity logs | `ActivityLog::with('user')->latest()->take(15)` | ✅ |
| Notifications | `auth()->user()->notifications()->take(10)` | ✅ |

### 7.2 Tenant Management Screens

| Screen | View File | Controller Method | Status |
|--------|-----------|-------------------|--------|
| Tenant list | `tenant/index.blade.php` | `TenantController@index` | ✅ |
| Create tenant | `tenant/create.blade.php` | `TenantController@create` / `store` | ✅ |
| Edit tenant | `tenant/edit.blade.php` | `TenantController@edit` / `update` | ✅ |
| Tenant details | `tenant/tenant-details.blade.php` | `TenantController@show` | 🟡 `show()` is stub |
| Setup progress | `tenant/setup-progress.blade.php` | `TenantController@setupProgress` | ✅ |
| Complete setup (plan assignment) | `tenant/complete-tenant-setup.blade.php` | `TenantController@completeTenantSetup` | ✅ |
| Assign plan (partial) | `tenant/partials/_assign-plan.blade.php` | — | ✅ |
| Tenant trash | `tenant/trash.blade.php` | `TenantController@trashed` | ✅ |

#### Create/Edit Tenant Form Fields

| Field | Type | Validation | Notes |
|-------|------|------------|-------|
| `tenant_group_id` | select | required | FK to prm_tenant_groups |
| `code` | text | required, unique | School short code |
| `short_name` | text | required | |
| `name` | text | required | Full school name |
| `udise_code` | text | nullable | Government ID |
| `affiliation_no` | text | nullable | Board affiliation |
| `email` | email | nullable | |
| `website_url` | url | nullable | |
| `address_1` | text | nullable | |
| `address_2` | text | nullable | |
| `area` | text | nullable | |
| `city_id` | select | required | FK to glb_cities |
| `pincode` | text | nullable | |
| `phone_1` / `phone_2` | text | nullable | |
| `whatsapp_number` | text | nullable | |
| `longitude` / `latitude` | decimal | nullable | |
| `locale` | select | required | Default 'en_IN' |
| `currency` | select | required | Default 'INR' |
| `established_date` | date | nullable | |
| `domain` | text | required (create only) | Subdomain prefix only; `.config('app.domain')` appended |

### 7.3 Plan Management Screen

| Screen | View File | Controller Method | Status |
|--------|-----------|-------------------|--------|
| Plans & module management | `sales-plan-and-module-mgmt/index.blade.php` | `SalesPlanAndModuleMgmtController` | ✅ |

### 7.4 User Management Screens

| Screen | View File | Status |
|--------|-----------|--------|
| User list | `user/index.blade.php` | ✅ (stub data issue) |
| Create user | `user/create.blade.php` | ✅ |
| Edit user | `user/edit.blade.php` | ✅ |
| User detail | `user/show.blade.php` | ✅ |
| User trash | `user/trash.blade.php` | ✅ |

### 7.5 Role & Permission Screens

| Screen | View File | Status |
|--------|-----------|--------|
| Role list with permissions | `role-permission/index.blade.php` | ✅ |
| Create role with permissions | `role-permission/create.blade.php` | ✅ |
| Edit role | `role-permission/edit.blade.php` | ✅ |
| Role detail / users with role | `role-permission/show.blade.php` | ✅ |
| User-role assignment | `user-role-permission/index.blade.php` | ✅ |

### 7.6 Configuration Screens

| Screen | View File | Status |
|--------|-----------|--------|
| Academic sessions | `academic-session/` (4 views) | ✅ |
| Boards | `board/` (4 views) | ✅ |
| Languages | `language/` (4 views) | ✅ |
| Dropdowns | `dropdown/` (4 views) + `dropdown-need/` + `dropdown-need-mgmt/` | ✅ |
| Menus | `menu/` (2 views — index, edit) | 🟡 No create view |
| Settings | `setting/` (4 views) | ✅ |
| Session-board setup | `session-board-setup/index.blade.php` | ✅ |

### 7.7 Email Templates (Blade)

| Template | Purpose | Status |
|----------|---------|--------|
| `email/tenant-registered.blade.php` | Sent to school on registration | ✅ |
| `email/tenant-group-created.blade.php` | Sent to group on creation | ✅ |
| `email/test-email.blade.php` | Test email — **should be removed in production** | ❌ |

---

## 8. Business Rules & Domain Constraints

| Rule ID | Description | Enforcement | Status |
|---------|-------------|-------------|--------|
| BR-PRM-01 | A tenant can only be accessed via domain routing if `is_active = true` AND `tenantPlans()->exists()`. `Tenant::canAccess()` checks both. | `Tenant::canAccess()` | ✅ |
| BR-PRM-02 | Only one plan subscription can be `is_subscribed = 1` per tenant per plan at any time. Enforced by `current_flag` generated column + UNIQUE constraint on `(current_flag, plan_id)`. | DB constraint | ✅ |
| BR-PRM-03 | An active academic session must exist before plan assignment. Throws `RuntimeException('No active academic session found.')` if none exists. | `TenantPlanAssigner` + `updateTenantPlan()` | ✅ |
| BR-PRM-04 | Billing schedule window is clamped to the current academic session: `max(start_date, session.start_date)` to `min(end_date, session.end_date)`. If the resulting window is empty, a warning is returned. | `TenantController::updateTenantPlan()` only (not in service) | 🟡 |
| BR-PRM-05 | Module deactivation on a tenant plan is soft-only. `prm_tenant_plan_module_jnt.is_active = 0`; rows are never deleted to preserve billing history. | `TenantPlanAssigner` | ✅ |
| BR-PRM-06 | `db_password` in `prm_tenant_domains` must be encrypted at rest. Plaintext DB credentials in a SaaS central database are a critical security exposure. | **NOT ENFORCED** | ❌ BUG-PRM-001 |
| BR-PRM-07 | `is_super_admin` on `sys_user` must not be settable via any web form or API request. Only DB-level direct operation or a protected Artisan command can set it. | **NOT ENFORCED at model level** | ❌ BUG-PRM-002 |
| BR-PRM-08 | `SetupTenantDatabase` job has `$tries = 1`. Failed setups must be manually re-triggered by admin. | `$tries = 1` | ✅ (but no re-trigger UI) |
| BR-PRM-09 | Root tenant user must NOT be created with a hardcoded password (`password`). A random secure password must be generated and emailed to the school admin on setup completion. | **NOT ENFORCED** | ❌ |
| BR-PRM-10 | Tenant domain routing requires stancl/tenancy v3.9. `Tenant` model must implement `TenantWithDatabase`, `HasDatabase`, `HasDomains`. | Model implements correct interfaces | ✅ |
| BR-PRM-11 | Allowed module IDs for a tenant are resolved via `Tenant::allowedModuleIds()` — intersects active tenant plan, active plan-module mapping, and active global module. | `Tenant::allowedModuleIds()` | ✅ |
| BR-PRM-12 | Plan version `version` field must be incremented (new row) whenever a plan definition is modified — existing subscriptions reference the versioned plan. | **NOT ENFORCED** | ❌ |
| BR-PRM-13 | `completeTenantSetup()` Gate check uses wrong permission: `prime.tenant-group.update` instead of `prime.tenant.update`. | **INCORRECT** | ❌ |

---

## 9. Workflow & State Machine Definitions

### 9.1 Tenant Onboarding Workflow

```
[Admin fills Create Tenant form]
       │
       ▼
[TenantController::store()]
  ├─ Create prm_tenant (is_active=0, setup_status='pending')
  ├─ Create prm_tenant_domains record
  ├─ Dispatch SetupTenantDatabase::dispatch($tenant->id) ──→ [Queue]
  ├─ Send TenantRegisteredMail to tenant email
  ├─ Send TenantRegisteredNotification to all super admins
  ├─ Write activity log
  └─ Redirect to setup-progress page
       │
       ▼ (async in queue worker)
[SetupTenantDatabase::handle()]
  ├─ Stage 1: CreateDatabase (0% → 5%)
  │    └─ $tenant->database()->manager()->createDatabase($tenant)
  ├─ Stage 2: RunMigrations (5% → 88%)
  │    └─ Artisan::call('tenants:migrate', ['--tenants'=>[$id]])
  │    └─ Per-migration progress via MigrationStarted/MigrationEnded events
  ├─ Stage 3: CreateRootUser (88% → 93%)
  │    └─ $tenant->run(fn() => User::create([...hardcoded password...]))
  ├─ Stage 4: AddOrganization (93% → 99%)
  │    └─ $tenant->run(fn() => Organization::create([...]))
  └─ Stage 5: Complete (100%)
       └─ TenantSetupCompletedNotification to super admins

[On error at any stage]
  └─ TenantSetupFailedNotification
  └─ setup_status = 'failed', progress frozen

[Admin monitors via setup-progress view]
  └─ JavaScript polls /tenant/{id}/setup-status every N seconds
  └─ On status='completed': redirect to completeTenantSetup
  └─ On status='failed': show error + [NO re-trigger button currently]
```

### 9.2 Plan Assignment Workflow

```
[Admin opens complete-setup page]
  └─ Selects plan, billing cycle, modules, dates, rates, taxes
       │
       ▼
[TenantController::updateTenantPlan()]
  └─ Validate via TenantPlanRequest
  └─ Resolve academic session (required)
  └─ DB::transaction():
       ├─ Step 1: TenantPlan (prm_tenant_plan_jnt) — firstOrNew
       ├─ Step 2: Resolve billing window (clamp to session)
       ├─ Step 3: TenantPlanRate (prm_tenant_plan_rates) — create
       ├─ Step 4: Soft-disable old modules, add new modules
       └─ Step 5: Soft-disable old schedules, generate new schedule entries
  └─ Commit on success / Rollback on failure
```

### 9.3 Tenant Status State Machine

```
States: INACTIVE(pending) | INACTIVE(completed) | ACTIVE | SUSPENDED | INACTIVE(failed)

INACTIVE(pending) ──[Setup job completes]──► INACTIVE(completed)
INACTIVE(pending) ──[Setup job fails]──────► INACTIVE(failed)
INACTIVE(completed) ──[Plan assigned + Admin activates]──► ACTIVE
INACTIVE(failed) ──[Admin re-triggers setup]──► INACTIVE(pending)  [❌ not implemented]
ACTIVE ──[Admin deactivates]──────► INACTIVE
ACTIVE ──[Plan expires or suspended]──► SUSPENDED
SUSPENDED ──[Admin re-activates plan]──► ACTIVE
```

### 9.4 Billing Schedule to Invoice State Machine

```
prm_tenant_plan_billing_schedule:
  bill_generated = 0 (PENDING) ──[GenerateInvoicesCommand runs, date reached]──► bill_generated = 1 (INVOICED)

bil_tenant_invoices:
  PENDING ──[Payment recorded via Billing module]──► PAID
  PENDING ──[Due date passed]──► OVERDUE
  PENDING ──[Admin voids]──► CANCELLED
```

---

## 10. Non-Functional Requirements

| NFR ID | Category | Requirement | Priority | Status |
|--------|----------|-------------|----------|--------|
| NFR-PRM-01 | Security | `prm_tenant_domains.db_password` must be encrypted at rest using Laravel `encrypted` cast (or `Crypt::encryptString()`). All existing records must be re-encrypted on deployment. | P0 | ❌ |
| NFR-PRM-02 | Security | `is_super_admin` must be in `$guarded` array in `App\Models\User`. Only DB-direct or artisan-protected promotion allowed. | P0 | ❌ |
| NFR-PRM-03 | Security | All test/debug routes (`test-email`, `send-test-email`, `test-notification`) must be removed or gated behind `APP_ENV=local` check. | P1 | ❌ |
| NFR-PRM-04 | Security | `TenantController::update()` must use `$request->validated()` not `$request->all()`. Same fix in all other affected controllers. | P1 | ❌ |
| NFR-PRM-05 | Security | `RolePermissionController::getPermissions()` must have `Gate::authorize()` call before returning role permissions. | P0 | ❌ |
| NFR-PRM-06 | Scalability | `SetupTenantDatabase` job runs up to ~297 tenant migrations in a 600-second window (`$timeout=600`). Progress tracking updates DB on every migration event. Queue worker must have sufficient memory (512 MB minimum recommended). | P1 | ✅ |
| NFR-PRM-07 | Scalability | `PrimeController::dashboard()` executes ~15 separate queries inline. Cache slow queries (revenue totals, trend data) with a 15-minute TTL. | P2 | ❌ |
| NFR-PRM-08 | Isolation | Central domain routing (`Route::domain(config('app.domain'))`) must prevent tenant users from accessing Prime routes. | P0 | ✅ |
| NFR-PRM-09 | Reliability | The setup progress API (`/tenant/{id}/setup-status`) must be a simple DB read with no complex computation — ensures low latency during polling. | P1 | ✅ |
| NFR-PRM-10 | Audit | All state-changing operations (create, update, plan assignment, status changes) must write to `sys_activity_logs`. Currently implemented for tenant create; coverage incomplete for other operations. | P1 | 🟡 |
| NFR-PRM-11 | Code Quality | `UserController::index()` stub data (`rand()`, hardcoded `$totalRoles = 100`) must be replaced with real queries. | P2 | ❌ |
| NFR-PRM-12 | Architecture | Billing logic duplication between `TenantPlanAssigner::assign()` and `TenantController::updateTenantPlan()` must be resolved — controller must delegate entirely to service. | P2 | ❌ |
| NFR-PRM-13 | Architecture | Cross-module model ownership: `TenantInvoice`, `TenantInvoicingAuditLog`, `TenantInvoicingPayment` models exist in BOTH Prime and Billing modules for the same `bil_*` tables. Consolidate to single owner. | P1 | ❌ |

---

## 11. Cross-Module Dependencies

### 11.1 Incoming Dependencies (Prime consumes)

| Dependency | Type | Purpose |
|-----------|------|---------|
| `global_db` → `glb_modules` | Read | Module registry for plan-module mapping |
| `global_db` → `glb_boards` | Read/Write | Board management |
| `global_db` → `glb_languages` | Read/Write | Language management |
| `global_db` → `glb_menus` | Read/Write | Menu management |
| `global_db` → `glb_cities` | Read | City FK in tenant and tenant_group |
| `stancl/tenancy v3.9` | Infrastructure | Tenant model, DB isolation, domain routing |
| `Spatie Permission v6.21` | Infrastructure | Central RBAC |
| `spatie/laravel-medialibrary` | Infrastructure | Tenant logo upload and conversions |
| `Laravel Queue` | Infrastructure | `SetupTenantDatabase` async job |
| `Laravel Mail` | Infrastructure | `TenantRegisteredMail`, `TenantGroupCreatedMail`, `LoginMail` |
| `Modules\SchoolSetup` | Cross-module | `RolePermissionController` borrows `RolePermissionRequest` from SchoolSetup module |

### 11.2 Outgoing Dependencies (Prime produces)

| Dependency | Type | Purpose |
|-----------|------|---------|
| Billing module | Data producer | `prm_tenant_plan_billing_schedule` drives invoice generation in Billing module |
| All 40 tenant modules | Infrastructure | `SetupTenantDatabase` provisions the tenant DB with all module migrations |
| All tenant modules | Data | `prm_tenant_plan_module_jnt` controls which modules are licensed per tenant |
| SystemConfig module | Shared tables | `sys_activity_logs`, `sys_settings`, `sys_dropdown_table`, `sys_media` |

### 11.3 Circular Dependency Risk

| Dependency | Risk |
|-----------|------|
| `prm_tenant_plan_billing_schedule.generated_invoice_id → bil_tenant_invoices.id` | Circular FK between prm_ and bil_ schema sections. If these are ever in separate DBs, this FK cannot exist. |
| `TenantInvoice` model exists in both Prime and Billing modules | Dual model ownership — maintenance complexity, potential data inconsistency |

---

## 12. Test Case Reference & Coverage

### 12.1 Existing Tests (8 files)

| File | Type | Coverage |
|------|------|----------|
| `tests/Feature/SettingModelTest.php` | Feature | Setting model read/write |
| `tests/Unit/ArchitectureTest.php` | Unit | Class existence convention checks |
| `tests/Unit/ControllerAuthTest.php` | Unit | Gate::authorize reflection checks on all controllers |
| `tests/Unit/FormRequestValidationTest.php` | Unit | FormRequest rule existence checks |
| `tests/Unit/MigrationSchemaTest.php` | Unit | Migration file existence |
| `tests/Unit/ModelStructureTest.php` | Unit | `$fillable`/`$casts`/relationship checks |
| `tests/Unit/PolicyPermissionTest.php` | Unit | Policy method existence |
| `tests/Unit/SoftDeleteStatusTest.php` | Unit | SoftDeletes trait + is_active consistency |

**Coverage gaps:** All existing tests are structural/reflective — they check that code exists, not that it behaves correctly.

### 12.2 Missing Critical Tests

| Test File | Type | Covers | Priority |
|-----------|------|--------|----------|
| `tests/Feature/TenantOnboardingTest.php` | Feature | Full `store()` → job dispatch → progress API flow | P0 |
| `tests/Feature/SetupTenantDatabaseJobTest.php` | Feature | 4-stage pipeline; success path; failure at each stage | P0 |
| `tests/Unit/Domain/DomainEncryptionTest.php` | Unit | `db_password` stored encrypted; readable via model | P0 |
| `tests/Unit/UserModel/SuperAdminProtectionTest.php` | Unit | `is_super_admin` not mass-assignable | P0 |
| `tests/Feature/TenantPlanAssignerTest.php` | Feature | All 5 steps + DB::transaction rollback | P1 |
| `tests/Unit/BillingScheduleGenerationTest.php` | Unit | Date cursor iteration; academic session clamping | P1 |
| `tests/Feature/TenantDomainRoutingTest.php` | Feature | Central domain routes not accessible from tenant subdomain | P1 |
| `tests/Feature/InvoiceGenerationCommandTest.php` | Feature | Schedule-to-invoice pipeline | P1 |
| `tests/Feature/PrimeAuthTest.php` | Feature | Login/logout/guest-redirect | P1 |
| `tests/Feature/RolePermissionCrudTest.php` | Feature | Role CRUD + permission sync | P1 |
| `tests/Feature/TenantGroupCrudTest.php` | Feature | Group CRUD + FK error on delete with tenants | P2 |
| `tests/Unit/Plan/PlanVersioningTest.php` | Unit | New version row on plan edit | P2 |

### 12.3 Test Coverage Target

| Category | Current | Target (V2) |
|----------|:-------:|:-----------:|
| Security (encryption, mass-assignment) | 0% | 100% |
| Tenant onboarding pipeline | 0% | 80% |
| Plan assignment transaction | 0% | 80% |
| RBAC / authorization | Structural only | 70% |
| Dashboard data accuracy | 0% | 50% |

---

## 13. Glossary & Terminology

| Term | Definition |
|------|-----------|
| **Tenant** | A school or educational institution subscribing to Prime-AI as an isolated customer |
| **Tenant Group** | A managing trust, chain, or committee that owns one or more school tenants |
| **Plan** | A subscription tier specifying included modules and pricing structure |
| **Tenant Plan** | A specific subscription of a plan by a tenant (`prm_tenant_plan_jnt`) |
| **Billing Cycle** | Recurrence period: MONTHLY (1 mo), QUARTERLY (3 mo), YEARLY (12 mo), ONE_TIME |
| **Billing Schedule** | Pre-generated list of future invoice generation dates within the academic session |
| **Academic Session** | A school year period (e.g., April 2025 – March 2026); gates plan assignment |
| **Central Domain** | The PrimeGurukul management domain (`config('app.domain')` — e.g., `primeai.app`) |
| **Tenant Subdomain** | School-specific domain (e.g., `greenwood.primeai.app`) — isolated from Prime routes |
| **TenantWithDatabase** | stancl/tenancy interface enabling per-tenant database isolation and creation |
| **Root User** | The first admin user auto-created in a tenant database during `SetupTenantDatabase` |
| **current_flag** | Generated column on `prm_tenant_plan_jnt`: `tenant_id` when `is_subscribed=1`, else NULL — prevents duplicate active subscriptions |
| **SetupTenantDatabase** | Laravel job that creates the tenant DB, runs ~297 migrations, seeds root user and org |
| **TenantPlanAssigner** | Service class encapsulating the 5-step transactional plan subscription process |
| **allowedModuleIds()** | Method on Tenant model returning array of module IDs accessible to the tenant |
| **is_super_admin** | Boolean flag on `sys_user` granting full bypass of all Gate authorization checks |
| **prime.* gate prefix** | Permission naming convention for all central platform RBAC: `prime.{feature}.{action}` |
| **BUG-PRM-001** | Critical: `db_password` stored in plaintext in `prm_tenant_domains` |
| **BUG-PRM-002** | High: `is_super_admin` mass-assignable in User model |
| **BUG-PRM-003** | Medium: `$request->all()` used in `TenantController::update()` |
| **DB-02** | FK type mismatch: `prm_plans.billing_cycle_id` SMALLINT signed vs `prm_billing_cycles.id` SMALLINT UNSIGNED |
| **DB-05** | FK to `glb_modules` which is a VIEW — MySQL may not enforce FK constraints on views |
| **DB-06** | Cross-schema circular FK between `prm_tenant_plan_billing_schedule` and `bil_tenant_invoices` |

---

## 14. Additional Suggestions

> **Note:** This section contains analyst recommendations not derived from existing code or RBS. These are forward-looking improvement ideas.

### 14.1 P0 — Critical Security Hardening

1. **Encrypt `db_password` immediately.** Add `protected $casts = ['db_password' => 'encrypted'];` to `Domain` model. Increase `db_password` column to `VARCHAR(500)` to fit encrypted value. Write a one-time migration command to re-encrypt all existing plaintext entries.

2. **Protect `is_super_admin` at model level.** Move `is_super_admin` to `$guarded` (or remove from `$fillable`) in `App\Models\User`. Create a dedicated `php artisan prime:promote-admin {email}` Artisan command with `App\Console\Commands\PromoteSuperAdmin` that requires `--confirm` flag and writes to the activity log.

3. **Replace `$request->all()` with `$request->validated()`** in `TenantController::update()` and any other controller using `$request->all()` for model updates. This is a mass-assignment attack vector.

### 14.2 P1 — Feature Completeness

4. **Invoice generation scheduler.** Create `php artisan prime:generate-invoices` Artisan command scheduled via `Schedule::command()` in `Kernel.php`. It should process `prm_tenant_plan_billing_schedule` entries where `bill_generated = 0` AND `schedule_billing_date <= today`, create `bil_tenant_invoices` records, and mark `bill_generated = 1`.

5. **Tenant re-setup capability.** Add a "Re-trigger Database Setup" button on the setup-progress view when `setup_status = 'failed'`. Route to a new `POST /tenant/{id}/re-trigger-setup` action that resets status to `pending` and dispatches a new `SetupTenantDatabase` job.

6. **Secure root password generation.** In `SetupTenantDatabase::createRootUser()`, replace the hardcoded `password` with `Str::password(16)`. Store the generated password temporarily in the job payload (not in DB) and email it to `$tenant->email` via `TenantSetupCompletedMail`.

7. **Remove production test routes.** Gate `EmailController@testEmail`, `EmailController@sendTestEmail`, and `NotificationController@testNotification` behind `if (app()->environment('local', 'staging'))` or remove entirely from production deployments.

8. **Consolidate duplicate billing logic.** Refactor `TenantController::updateTenantPlan()` to delegate entirely to `TenantPlanAssigner::assign()`. The controller should handle only: request validation, academic session resolution, billing window clamping (pass as parameter to service), and redirect. The service handles all DB operations.

### 14.3 P2 — Architecture & Quality

9. **Create `TenantCreationService`.** Extract tenant creation logic from `TenantController::store()` into a dedicated `TenantCreationService`. This encapsulates: Tenant model creation, domain creation, job dispatch, email/notification dispatch, and activity logging. Simplifies controller and enables unit testing.

10. **Plan version management UX.** When admin updates a plan, present two options: "Update Current Version" (for typo fixes) and "Create New Version" (for pricing/module changes). New versions create a new `prm_plans` row with incremented `version`; existing subscriptions retain reference to their original version.

11. **Tenant activation gate.** After setup completes AND plan is assigned, introduce an explicit "Activate Tenant" step (currently `is_active` is set manually). This gate should: verify setup_status=completed, verify plan assigned, send tenant welcome email with subdomain URL and root credentials, set `is_active = true`.

12. **Dashboard query optimization.** Cache the dashboard aggregate queries (`totalRevenue`, `monthlyRevenue`, `tenantTrend`) using `Cache::remember('prime.dashboard.revenue', 900, fn() => ...)` with a 15-minute TTL. Invalidate cache on invoice creation or plan assignment.

13. **Resolve duplicate route definitions (RT-01).** Audit all routes registered under both `prime.` and `global-master.` prefix groups. For routes that legitimately belong to GlobalMaster (boards, countries, states, etc.), remove them from Prime's route file and update view links to use `global-master.*` named routes.

14. **Consolidate `bil_*` model ownership.** Move `TenantInvoice`, `TenantInvoicingAuditLog`, and `TenantInvoicingPayment` models entirely to the Billing module. In Prime, reference these via `Modules\Billing\Models\TenantInvoice` where needed (e.g., in `PrimeController::dashboard()`).

---

## 15. Appendices

### Appendix A: Key File Paths

| Artifact | Path |
|----------|------|
| TenantController | `Modules/Prime/app/Http/Controllers/TenantController.php` |
| TenantPlanAssigner | `Modules/Prime/app/Services/TenantPlanAssigner.php` |
| Tenant Model | `Modules/Prime/app/Models/Tenant.php` |
| Domain Model | `Modules/Prime/app/Models/Domain.php` |
| PrimeController (Dashboard) | `Modules/Prime/app/Http/Controllers/PrimeController.php` |
| RolePermissionController | `Modules/Prime/app/Http/Controllers/RolePermissionController.php` |
| UserController | `Modules/Prime/app/Http/Controllers/UserController.php` |
| SetupTenantDatabase Job | `app/Jobs/SetupTenantDatabase.php` |
| Prime Routes | `Modules/Prime/routes/web.php` |
| FormRequests | `Modules/Prime/app/Http/Requests/` (7 files) |
| Policies | `Modules/Prime/app/Policies/` (19 files) |
| Views | `Modules/Prime/resources/views/` (84 blade files) |
| Prime DDL (prm_*) | `2-New_Primedb/pgdatabase/1-Master_DDLs/prime_db_v2.sql` (lines 317–525) |
| Global DDL | `2-New_Primedb/pgdatabase/1-Master_DDLs/global_db_v2.sql` |

### Appendix B: Known Bugs Register

| Bug ID | Severity | Description | Suggested Fix | Status |
|--------|----------|-------------|--------------|--------|
| BUG-PRM-001 | **CRITICAL** | `prm_tenant_domains.db_password` stored as plaintext VARCHAR(255) | Add `encrypted` cast to Domain model; expand column to VARCHAR(500) | ❌ Open |
| BUG-PRM-002 | **HIGH** | `is_super_admin` mass-assignable in User model | Move to `$guarded`; create Artisan command for promotion | ❌ Open |
| BUG-PRM-003 | **MEDIUM** | `$request->all()` in `TenantController::update()` | Replace with `$request->validated()` | ❌ Open |
| BUG-PRM-004 | FIXED | MigrateDatabase step was commented out | Fixed — tenants:migrate via Artisan::call() | ✅ Resolved |
| BUG-PRM-005 | **HIGH** | Test routes accessible in production | Remove or environment-gate test routes | ❌ Open |
| BUG-PRM-006 | **MEDIUM** | `completeTenantSetup()` uses wrong Gate: `prime.tenant-group.update` | Change to `prime.tenant.update` | ❌ Open |
| BUG-PRM-007 | **MEDIUM** | Duplicate model: `Modules/Prime/Models/DropdownNeed.php` (outside `app/`) | Delete stale root-level Models directory copy | ❌ Open |
| BUG-PRM-008 | **LOW** | `UserController::index()` uses `rand()` for stats and hardcodes `$totalRoles = 100` | Replace with real queries | ❌ Open |
| BUG-PRM-009 | **MEDIUM** | `RolePermissionController::destroy()` calls `$role->save()` without deleting | Implement soft-delete properly | ❌ Open |
| BUG-PRM-010 | **MEDIUM** | `usersByRole()` does not filter by role — returns all users | Implement `User::role($role)->get()` | ❌ Open |

### Appendix C: Tenant Setup Status Values

| Status Value | Description |
|-------------|-------------|
| `pending` | Tenant created; job is queued but not yet started |
| `creating_database` | Stage 1: DB creation in progress |
| `running_migrations` | Stage 2: Tenant migrations running (shows per-migration progress) |
| `creating_root_user` | Stage 3: Root admin user being created in tenant context |
| `adding_organization` | Stage 4: Organization seed record being added |
| `completed` | All 4 stages successful; tenant is ready for plan assignment |
| `failed` | Exception occurred at a stage; progress frozen at last completed % |

### Appendix D: Permission Naming Convention

All central permissions follow the pattern: `{module}.{feature}.{action}`

| Example | Module | Feature | Action |
|---------|--------|---------|--------|
| `prime.tenant.create` | prime | tenant | create |
| `prime.tenant.viewAny` | prime | tenant | viewAny |
| `prime.tenant.update` | prime | tenant | update |
| `prime.tenant.delete` | prime | tenant | delete |
| `prime.role-permission.viewAny` | prime | role-permission | viewAny |
| `prime.user.create` | prime | user | create |
| `prime.dashboard.viewAny` | prime | dashboard | viewAny |
| `prime.sales-plan-mgmt.create` | prime | sales-plan-mgmt | create |

### Appendix E: DDL Issues Summary

| Issue ID | Table | Severity | Description |
|----------|-------|----------|-------------|
| DB-01 | `prm_tenant_domains` | **P0** | `db_password` plaintext — must encrypt |
| DB-02 | `prm_plans` | **P1** | `billing_cycle_id SMALLINT` (signed) vs `prm_billing_cycles.id SMALLINT UNSIGNED` — type mismatch |
| DB-03 | `prm_billing_cycles` | **P1** | No `deleted_at` column but model uses SoftDeletes |
| DB-04 | `prm_tenant_plan_rates` | **P2** | Missing `is_active` and `created_by` per project standards |
| DB-05 | `prm_module_plan_jnt` + `prm_tenant_plan_module_jnt` | **P2** | FK to `glb_modules` which is a VIEW — MySQL FK enforcement unreliable |
| DB-06 | `prm_tenant_plan_billing_schedule` | **P2** | Cross-module circular FK to `bil_tenant_invoices` |
| DB-07 | `prm_tenant_groups` | **P3** | Missing `created_by` column per project standards |

---

## 16. V1 → V2 Delta Summary

### 16.1 New Sections in V2

| Section | Added In V2 | Description |
|---------|:-----------:|-------------|
| 1.3 Module Statistics table | 🆕 | Verified artifact counts from code audit |
| 1.4 Critical Issues Register | 🆕 | Consolidated bug tracker with 10 items |
| FR-PRM-11: Platform Dashboard | 🆕 | Full breakdown of dashboard metrics and data sources |
| FR-PRM-12: Activity Logs | 🆕 | Explicit requirement for log coverage |
| Section 5 (all tables) | Expanded | Full column-level DDL spec for all 10 prm_* tables |
| Section 7 (UI Screen Inventory) | Expanded | Complete view list (84 files), field mapping for create/edit forms |
| Section 9.4 Billing State Machine | 🆕 | schedule → invoice status transitions |
| Section 12.2 Missing Tests | Expanded | 12 specific missing test files with priorities |
| Section 15 Appendices D, E | 🆕 | Permission naming convention table; DDL issues summary |

### 16.2 Gaps Promoted from Gap Analysis to FR Items

| Gap Analysis Issue | FR Item | Priority |
|-------------------|---------|----------|
| DB-01: `db_password` plaintext | REQ-PRM-01.10 | P0 |
| SEC-01: `completeTenantSetup()` wrong Gate | BR-PRM-13 + BUG-PRM-006 | P1 |
| SEC-02: `getPermissions()` no Gate | REQ-PRM-08.7 | P0 |
| SEC-04/SEC-05: Test routes in production | REQ-PRM-06.5/06.6 | P1 |
| SVC-01: No `TenantCreationService` | BUG-PRM-005 + NFR-PRM-12 | P1 |
| FRQ-01: No FormRequest for RolePermissionController | REQ-PRM-08.8 | P1 |
| MDL-01: `is_super_admin` mass-assignable | REQ-PRM-07.4 | P0 |
| MDL-02: Cross-module bil_* model ownership | NFR-PRM-13 | P1 |
| MDL-03: Duplicate DropdownNeed.php | BUG-PRM-007 | P2 |
| RT-01: Duplicate routes prime./global-master. | BUG-PRM-008 + REQ-PRM-09.7 | P2 |
| INP-01: `$request->all()` in TenantController | BUG-PRM-003 + NFR-PRM-04 | P2 |
| TST-01: No feature tests for tenant creation | Section 12.2 | P0 |
| TST-02: No test for TenantPlanAssigner | Section 12.2 | P1 |

### 16.3 Existing V1 Content Retained in V2

All V1 content is preserved and expanded:
- FR-PRM-01 through FR-PRM-10 retained with enhanced Requirements tables and Acceptance Criteria
- All business rules (BR-PRM-01 through BR-PRM-10) retained; 3 new rules added (BR-PRM-11, 12, 13)
- All NFRs retained; 5 new NFRs added
- All V1 appendices retained; 2 new appendices added (D, E)
- Data model section expanded from summary to full column-level specification for all tables

### 16.4 Status Change Summary

| FR | V1 Status | V2 Status | Reason |
|----|-----------|-----------|--------|
| FR-PRM-01 (Tenant Onboarding) | Partially described | Fully specified with 10 sub-requirements | Gap analysis revealed missing re-trigger capability and password security |
| FR-PRM-05 (Billing) | 🟡 Partial | 🟡 Partial (more detail) | `GenerateInvoicesCommand` still missing |
| FR-PRM-08 (RBAC) | Not explicit | Full FR with 10 sub-requirements | Gap analysis revealed getPermissions authorization gap |
| FR-PRM-11 (Dashboard) | Implicit in V1 | ✅ Explicitly documented | Dashboard implementation is complete and solid |
| FR-PRM-12 (Activity Logs) | Mentioned briefly | Explicit requirements | |

---

*Document generated by Claude Code (Automated) from code audit of `Modules/Prime/` as of 2026-03-22, with DDL from `prime_db_v2.sql`, gap analysis from `Prime_Deep_Gap_Analysis.md`, and V1 baseline from `PRM_Prime_Requirement.md`.*
