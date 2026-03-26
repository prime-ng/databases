# Prime Module — Requirement Specification Document
**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Module Code:** PRM | **Module Type:** Central Module (prime_db)
**Table Prefix:** `prm_*`, `bil_*`, `sys_*` | **Processing Mode:** FULL
**RBS Reference:** Module A — Tenant & System Management

---

## 1. Executive Summary

The Prime module is the central platform management layer for Prime-AI SaaS. It operates on the `prime_db` database (not tenant-isolated) and governs the entire multi-tenant lifecycle: tenant onboarding, plan subscription, module licensing, billing schedule generation, central RBAC, and global master data management. Unlike tenant modules, Prime operates on a dedicated central domain and is accessible only to Prime (PrimeGurukul) super admins.

**Implementation Statistics:**
- Controllers: 21 (AcademicSessionController, ActivityLogController, BoardController, DropdownController, DropdownMgmtController, DropdownNeedController, EmailController, LanguageController, MenuController, NotificationController, PrimeAuthController, PrimeController, RolePermissionController, SalesPlanAndModuleMgmtController, SessionBoardSetupController, SettingController, TenantController, TenantGroupController, TenantManagementController, UserController, UserRolePrmController)
- Models: 21+ (in `app/Models/` and root `Models/`)
- Services: 1 (TenantPlanAssigner)
- FormRequests: 7 (AcademicSessionRequest, BoardRequest, DropdownRequest, TenantGroupRequest, TenantPlanRequest, TenantRequest, UserRequest)
- Tests: 9 (Feature: SettingModelTest; Unit: ArchitectureTest, ControllerAuthTest, FormRequestValidationTest, MigrationSchemaTest, ModelStructureTest, PolicyPermissionTest, SettingModelTest, SoftDeleteStatusTest)
- Completion: ~70%

**Issues Identified:**
1. **BUG-PRM-001 — `db_password` PLAINTEXT IN DOMAIN MODEL:** `prm_tenant_domains` stores `db_password` as `VARCHAR(255)` with no encryption. Database passwords for tenant schemas are accessible in plaintext to anyone with prime_db read access.
2. **BUG-PRM-002 — `is_super_admin` MASS-ASSIGNABLE:** In `SetupTenantDatabase`, `User::create(['is_super_admin' => true, ...])` creates the root tenant user with a hardcoded `is_super_admin = true` — this field must be protected from mass assignment.
3. **BUG-PRM-003 — `$request->all()` IN 5 CONTROLLERS:** `TenantController::update()` uses `$request->all()` instead of `$request->validated()`, bypassing FormRequest validation and allowing mass assignment of unvalidated fields.
4. **BUG-PRM-004 (NOTED, FIXED):** The `MigrateDatabase` step was previously commented out — this was resolved; `SetupTenantDatabase` job now runs `tenants:migrate` via `Artisan::call()`.

---

## 2. Module Overview

### 2.1 Business Purpose

Prime is the SaaS platform management console for PrimeGurukul (the software company). It enables:
- Onboarding new school tenants (create isolated database + migrate + seed root user + org)
- Managing subscription plans and module licensing
- Generating billing schedules and invoices
- Centralized role/permission management for central (prime) users
- Global master data management (boards, languages, dropdowns, menus, modules)
- Academic session and setup configuration

### 2.2 Architecture

Prime operates on a **dedicated central domain** (configured as `config('app.domain')`). All Prime routes are domain-scoped:

```php
Route::domain(config('app.domain'))->name("central.")->group(function () { ... });
```

This ensures tenant users cannot access Prime management pages, as their requests are routed to their subdomain (e.g., `schoolname.primeai.app`), not the central domain.

### 2.3 Three-Layer Database Context

| Layer | Database | Prefix | Prime Module Scope |
|-------|----------|--------|-------------------|
| Global | global_db | glb_* | Read-only (boards, modules, languages) |
| Central | prime_db | prm_*, bil_*, sys_* | Full ownership |
| Tenant | tenant_{uuid} | All prefixes | Create/migrate/seed via SetupTenantDatabase |

### 2.4 Menu Path

`Central Domain (primeai.app) > Prime Dashboard`
- Tenant Management
  - Tenant Groups
  - Tenants
  - Setup Progress
  - Plan & Module Assignment
- Plans & Modules
  - Plan Management
  - Module Management
- Billing
  - Billing Cycles
  - Invoices
- Configuration
  - Academic Sessions
  - Boards
  - Languages
  - Menus
  - Dropdowns
  - Settings
- User Management
  - Central Users
  - Roles & Permissions
- Logs
  - Activity Logs
  - Email Logs

---

## 3. Stakeholders & Actors

| Actor | Role | Access |
|-------|------|--------|
| Prime Super Admin | Full platform control | All Prime module features |
| Prime Sales/Operations | Tenant onboarding, plan assignment | Tenant + Plan management |
| Prime Finance | Billing, invoices | Billing module |
| Tenant Admin | No access to Prime | Cannot access central domain |
| System/Queue Worker | Database setup, migrations | `SetupTenantDatabase` job |

---

## 4. Functional Requirements

### FR-PRM-01: Tenant Registration & Onboarding

**RBS Ref:** F.A1.1 — Tenant Creation; F.A1.2 — Subscription Assignment

**REQ-PRM-01.1 — Tenant Record Creation**
- Admin shall create a tenant with: `tenant_group_id`, `code` (unique), `short_name`, `name`, `udise_code`, `affiliation_no`, `email`, `website_url`, `address_1`, `address_2`, `area`, `city_id`, `pincode`, `phone_1`, `phone_2`, `whatsapp_number`, `longitude`, `latitude`, `locale`, `currency`, `established_date`.
- On creation, tenant `is_active = false` and `setup_status = 'pending'`.
- A domain record is created: `$subdomain . '.' . config('app.domain')`.
- A registration confirmation email is sent to `$tenant->email` via `TenantRegisteredMail`.
- All Prime super admins are notified via `TenantRegisteredNotification`.

**REQ-PRM-01.2 — Automated Database Setup Pipeline**
- After tenant creation, `SetupTenantDatabase::dispatch($tenant->id)` is queued asynchronously.
- The job runs with `$tries = 1`, `$timeout = 600` seconds.
- Pipeline stages:

| Stage | Progress | Action |
|-------|----------|--------|
| CreateDatabase | 0% → 5% | `$tenant->database()->manager()->createDatabase($tenant)` |
| RunMigrations | 5% → 88% | `Artisan::call('tenants:migrate', ['--tenants' => [$tenant->id]])` |
| CreateRootUser | 88% → 93% | `User::create(['name' => 'Root User', 'email' => 'root@tenant.com', 'is_super_admin' => true, ...])` inside `$tenant->run()` |
| AddOrganization | 93% → 99% | `Organization::create([...copies of tenant data...])` inside `$tenant->run()` |
| Completed | 100% | Super admin notification via `TenantSetupCompletedNotification` |
| Failed | N% | `TenantSetupFailedNotification` dispatched, progress frozen at failure point |

- Progress is written to `prm_tenant` table directly via `DB::connection('central')` to avoid tenant context interference.
- Migration progress uses `MigrationStarted` / `MigrationEnded` events to track per-migration progress.

**REQ-PRM-01.3 — Setup Progress Monitoring**
- `GET /tenant/{id}/setup-progress` renders a polling view.
- `GET /tenant/{id}/setup-status` returns JSON: `{ status, progress, message, name }`.
- The view polls every N seconds until `status = 'completed'` or `status = 'failed'`.

**Acceptance Criteria:**
- Given valid tenant creation request, job is dispatched, domain is created, email is sent, admin is redirected to setup progress page.
- Given job completes: tenant `setup_status = 'completed'`, `setup_progress = 100`, root user exists in tenant DB.
- Given job fails at migration step: tenant `setup_status = 'failed'` with progress at last completed percentage.
- Given progress API is polled, returns current status JSON without authentication bypass.

**Current Implementation:**
- `TenantController::store()` — fully implemented with domain creation, email, notification, and job dispatch.
- `SetupTenantDatabase` job — fully implemented with 4-stage pipeline and event-based migration progress.
- `setupProgress()` and `setupStatus()` — both implemented.

---

### FR-PRM-02: Tenant Group Management

**RBS Ref:** F.A1.1

**REQ-PRM-02.1 — Tenant Groups**
- Tenants are organized into groups (e.g., school chains, managing trusts).
- Group fields: `code`, `short_name`, `name`, `city_id`, `email`, `website_url`, `address_1`, `address_2`, `pincode`.
- Each tenant must belong to exactly one group.

**Current Implementation:**
- `TenantGroupController` with full CRUD.
- `TenantGroup` model with `TenantGroupRequest` validation.
- `TenantGroupCreatedMail` email notification.

---

### FR-PRM-03: Subscription Plan Management

**RBS Ref:** F.A2.1 — Feature Toggles / Enable/Disable Modules

**REQ-PRM-03.1 — Plan Definition**
- Plans have: `plan_code` (+ `version` — composite unique), `name`, `description`, `billing_cycle_id`, `price_monthly`, `price_quarterly`, `price_yearly`, `currency`, `trial_days`.
- A plan lists the modules included via `prm_module_plan_jnt`.

**REQ-PRM-03.2 — Billing Cycles**
- Predefined billing cycles in `prm_billing_cycles`: `short_name` (MONTHLY/QUARTERLY/YEARLY/ONE_TIME), `months_count`, `is_recurring`.

**Current Implementation:**
- `SalesPlanAndModuleMgmtController` manages plans and module-plan associations.
- `prm_plans`, `prm_module_plan_jnt`, `prm_billing_cycles` tables defined in DDL.

---

### FR-PRM-04: Tenant Plan Assignment

**RBS Ref:** F.A1.2 — Subscription Assignment / Billing Cycle Setup

**REQ-PRM-04.1 — TenantPlanAssigner Service**
The `TenantPlanAssigner::assign(Tenant $tenant, array $data): TenantPlan` service handles plan subscription in a database transaction. It performs 5 atomic steps:

1. **Tenant Plan (`prm_tenant_plan_jnt`):** `firstOrNew` by `(tenant_id, plan_id)`. Sets `is_subscribed`, `is_trial`, `auto_renew`, `automatic_billing`, `status`, `is_active`. A generated column `current_flag` enforces uniqueness: only one active plan subscription per tenant per plan.

2. **Plan Rate (`prm_tenant_plan_rates`):** Creates rate record with `start_date`, `end_date`, `billing_cycle_id`, `billing_cycle_day` (= day of month from start_date), `monthly_rate`, `rate_per_cycle`, `currency`, `min_billing_qty`. Also records discount fields (percent, amount, remark), extra charges, 4 tax types (tax1–tax4 with percent and remark), `credit_days`.

3. **Module Assignment (`prm_tenant_plan_module_jnt`):** Soft-disables all existing module rows, then `updateOrCreate` for each module in `included_modules`. History is preserved — no rows deleted.

4. **Billing Schedules (`prm_tenant_plan_billing_schedule`):** Generates one schedule entry per billing cycle period between `start_date` and `end_date`. Each entry has `schedule_billing_date`, `billing_start_date`, `billing_end_date`, `bill_generated = false`. Existing schedules are soft-disabled, not deleted.

5. **Transaction guarantee:** All 5 steps wrapped in `DB::transaction()`. Failure rolls back all changes.

**REQ-PRM-04.2 — Complete Tenant Setup UI**
- `completeTenantSetup(Tenant $tenant)` renders the plan assignment form.
- Loads: `Module::all()`, `Plan::all()`, tenant's existing plans with module associations and billing schedules.

**Acceptance Criteria:**
- Given valid plan assignment: TenantPlan, TenantPlanRate, 12 TenantPlanBillingSchedule (monthly for 1 year) records created in one transaction.
- Given plan assignment fails at step 4: database is rolled back to pre-assignment state.
- Given module deactivated: `prm_tenant_plan_module_jnt.is_active = 0` but row retained for history.

**Current Implementation:**
- `TenantPlanAssigner` service — fully implemented.
- `TenantController::updateTenantPlan()` — fully implemented with billing window clamping to academic session.
- Both controller method and service implement the same logic — the service version is cleaner and preferred.

---

### FR-PRM-05: Billing & Invoice Management

**RBS Ref:** F.A1.2 — Billing Cycle Setup

**REQ-PRM-05.1 — Invoice Generation**
- `bil_tenant_invoices` stores generated invoices with full billing breakdown: `sub_total`, `discount_percent`, `discount_amount`, `extra_charges`, `tax1_percent` through `tax4_percent` with amounts, `total_tax_amount`, `net_payable_amount`, `paid_amount`.
- Invoice number is auto-generated (unique).
- Invoice date = day after `billing_end_date`.
- `payment_due_date` = invoice date + `credit_days`.

**REQ-PRM-05.2 — Invoice Module Association**
- `bil_tenant_invoicing_modules_jnt` records which modules were active during the billing period.

**Current Implementation:**
- `TenantInvoice`, `TenantInvoiceModule`, `TenantInvoicingAuditLog`, `TenantInvoicingPayment` models exist.
- No dedicated invoice generation controller found — appears to be generated by billing schedule processing.

---

### FR-PRM-06: Authentication & Authorization (Central)

**RBS Ref:** F.A3.1, F.A3.2

**REQ-PRM-06.1 — Central Login**
- Prime users authenticate via `PrimeAuthController` on the central domain.
- Login: `POST /login` with email/password.
- Logout: `POST /logout`.
- Session is scoped to the central domain only.

**REQ-PRM-06.2 — Central RBAC**
- Roles and permissions use Spatie Permission v6.21.
- `RolePermissionController` manages role/permission CRUD.
- Policies use `prime.*` gate prefix (correct for central module).
- `UserRolePrmController` handles user-role assignments.

**Current Implementation:**
- `PrimeAuthController` — login/logout implemented.
- Guest and auth middleware groups applied correctly in `web.php`.
- `Permission`, `Role` models extending Spatie models.

---

### FR-PRM-07: User Management (Central)

**RBS Ref:** F.A4.1, F.A4.2

**REQ-PRM-07.1 — Central User CRUD**
- `UserController` manages Prime/PrimeGurukul users (not tenant users).
- User fields validated by `UserRequest`.
- `LoginMail` sent on user creation.

**REQ-PRM-07.2 — Super Admin Flag**
- `is_super_admin` boolean field on `sys_user` (central).
- **BUG-PRM-002:** `is_super_admin` must not be mass-assignable. Must be in `$guarded` or excluded from `$fillable` in User model. Manual DB-level promotion only.

---

### FR-PRM-08: Global Master Data

**RBS Ref:** F.A7.1

**REQ-PRM-08.1 — Boards**
- CBSE, ICSE, IB, Cambridge, State Boards managed via `BoardController`.
- Validated by `BoardRequest`.

**REQ-PRM-08.2 — Languages**
- Language master via `LanguageController`.

**REQ-PRM-08.3 — Academic Sessions**
- `AcademicSessionController` manages academic year records.
- `AcademicSession::current()` scope used throughout the platform for context.
- Required for `TenantPlanAssigner` — throws `RuntimeException` if no active session.

**REQ-PRM-08.4 — Dropdown Management**
- Three controllers: `DropdownController` (central lookup), `DropdownMgmtController` (management), `DropdownNeedController` (defines which dropdowns each feature needs).
- Dropdowns feed `sys_dropdown_table` used across all modules.

**REQ-PRM-08.5 — Menu Management**
- `MenuController` manages the hierarchical menu structure (`glb_menus`/`glb_menu_modules`).
- Menus are linked to modules; module-plan associations determine which menu items appear per tenant.

---

### FR-PRM-09: Settings & Configuration

**RBS Ref:** F.A7.1

**REQ-PRM-09.1 — System Settings**
- `SettingController` manages key-value system settings (SMTP config, SMS provider, general options).
- `Setting` model with get/set interface.

---

### FR-PRM-10: Activity Logs & Monitoring

**RBS Ref:** F.A6.1

**REQ-PRM-10.1 — Activity Log Viewer**
- `ActivityLogController` displays `sys_activity_logs` entries.
- Logs are written via the global `activityLog()` helper.

---

## 5. Data Model

### 5.1 Table: `prm_tenant_groups`

| Column | Type | Constraints |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| code | VARCHAR(20) | |
| short_name | VARCHAR(50) | UNIQUE |
| name | VARCHAR(150) | |
| city_id | INT UNSIGNED | FK → glb_cities |
| email | VARCHAR(100) NULL | |
| is_active | TINYINT(1) | DEFAULT 1 |
| deleted_at | TIMESTAMP NULL | |

### 5.2 Table: `prm_tenant`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | (Integer — NOTE: stancl/tenancy typically uses UUID; needs clarification) |
| tenant_group_id | INT UNSIGNED | FK → prm_tenant_groups |
| code | VARCHAR(20) | UNIQUE |
| short_name | VARCHAR(50) | |
| name | VARCHAR(150) | |
| udise_code | VARCHAR(30) NULL | Government UDISE identifier |
| affiliation_no | VARCHAR(60) NULL | Board affiliation number |
| email / website_url | VARCHAR | |
| address_1/2, area | VARCHAR | |
| city_id | INT UNSIGNED | FK → glb_cities |
| locale | VARCHAR(16) | DEFAULT 'en_IN' |
| currency | VARCHAR(8) | DEFAULT 'INR' |
| is_active | TINYINT(1) | |
| setup_status | VARCHAR | creating_database / running_migrations / creating_root_user / adding_organization / completed / failed |
| setup_progress | INT | 0–100 |
| setup_message | VARCHAR | Human-readable status |
| deleted_at | TIMESTAMP NULL | |

**Tenant model custom columns declared via `getCustomColumns()` for stancl/tenancy compatibility.**

### 5.3 Table: `prm_tenant_domains`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | FK → prm_tenant |
| domain | VARCHAR(255) | Full domain: `schoolname.primeai.app` |
| db_name | VARCHAR(100) | Tenant database name |
| db_host | VARCHAR(200) | Database host |
| db_port | VARCHAR(10) | DEFAULT '3306' |
| db_username | VARCHAR(100) | Database username |
| **db_password** | **VARCHAR(255)** | **PLAINTEXT — CRITICAL SECURITY ISSUE** |
| is_active | TINYINT(1) | |

### 5.4 Table: `prm_plans`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| plan_code | VARCHAR(20) | UNIQUE with version |
| version | INT UNSIGNED | DEFAULT 0 |
| name | VARCHAR(100) | |
| billing_cycle_id | SMALLINT | FK → prm_billing_cycles |
| price_monthly / price_quarterly / price_yearly | DECIMAL(12,2) | |
| currency | CHAR(3) | DEFAULT 'INR' |
| trial_days | INT UNSIGNED | DEFAULT 0 |

### 5.5 Table: `prm_tenant_plan_jnt`

| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED PK | |
| tenant_id | INT UNSIGNED | FK → prm_tenant |
| plan_id | INT UNSIGNED | FK → prm_plans |
| is_subscribed | TINYINT(1) | |
| is_trial | TINYINT(1) | |
| auto_renew | TINYINT(1) | |
| automatic_billing | TINYINT(1) | |
| status | VARCHAR(20) | ACTIVE/SUSPENDED/CANCELED/EXPIRED |
| current_flag | INT GENERATED | `CASE WHEN is_subscribed=1 THEN tenant_id ELSE NULL END` — enforces one active plan per tenant |
| UNIQUE KEY | (current_flag, plan_id) | |

### 5.6 Table: `prm_tenant_plan_rates`

| Column | Description |
|--------|-------------|
| tenant_plan_id | FK → prm_tenant_plan_jnt |
| start_date / end_date | Plan validity window |
| billing_cycle_id | FK → prm_billing_cycles |
| billing_cycle_day | Day of month for billing |
| monthly_rate | Base rate per month |
| rate_per_cycle | Rate per billing cycle |
| discount_percent / discount_amount | |
| tax1–tax4 percent + remark | 4 configurable tax types |
| credit_days | Days before payment is due |

### 5.7 Table: `prm_tenant_plan_module_jnt`

Junction between `prm_tenant_plan_jnt` and `glb_modules`. Soft-disables on change.

### 5.8 Table: `prm_tenant_plan_billing_schedule`

| Column | Description |
|--------|-------------|
| tenant_plan_id | FK → prm_tenant_plan_jnt |
| tenant_id | FK → prm_tenant |
| billing_cycle_id | FK → prm_billing_cycles |
| schedule_billing_date | Date to bill |
| billing_start_date / billing_end_date | Period covered |
| bill_generated | TINYINT(1) DEFAULT 0 |
| generated_invoice_id | FK → bil_tenant_invoices (nullable) |

### 5.9 Table: `bil_tenant_invoices`

Full billing invoice with amounts, taxes, discount, payment due date, status tracking.

| Key Fields | Description |
|-----------|-------------|
| invoice_no | Auto-generated, UNIQUE |
| billing_start_date / billing_end_date | |
| sub_total | Base amount |
| discount_percent / discount_amount | |
| tax1–tax4 percent, remark, amount | |
| total_tax_amount | |
| net_payable_amount | |
| paid_amount | |
| payment_due_date | invoice_date + credit_days |
| status | PENDING/PAID/OVERDUE/CANCELLED |

### 5.10 Table: `prm_billing_cycles`

Lookup table: MONTHLY (1 month), QUARTERLY (3), YEARLY (12), ONE_TIME (0, non-recurring).

---

## 6. API & Route Specification

### 6.1 Current Routes (`routes/web.php`)

```php
Route::domain(config('app.domain'))->name("central.")->group(function () {
    Route::get('/', [PrimeController::class, 'index'])->name('prime.index');
    Route::get('/dashboard', [PrimeController::class, 'dashboard'])
         ->middleware(['auth', 'verified'])->name('prime.dashboard');

    Route::middleware('guest')->name('prime.')->group(function () {
        Route::get('login', [PrimeAuthController::class, 'index']);
        Route::post('login', [PrimeAuthController::class, 'login'])->name('login');
    });
    Route::middleware('auth')->name('prime.')->group(function () {
        Route::post('logout', [PrimeAuthController::class, 'logout'])->name('logout');
    });
});
```

**Note:** Only auth, dashboard, and public routes are in `web.php`. All other routes are defined in `routes/Navbar.php` (if present) or loaded via `RouteServiceProvider`.

### 6.2 Key Route Groups Expected

```
// Tenant Management
GET/POST        /tenants                                   → TenantController
GET/POST/PUT    /tenants/{tenant}/complete-setup            → TenantController@completeTenantSetup
POST            /tenants/{tenant}/update-plan               → TenantController@updateTenantPlan
GET             /tenants/{tenant}/setup-progress            → TenantController@setupProgress
GET             /tenants/{tenant}/setup-status              → TenantController@setupStatus (JSON API)
POST            /tenants/{tenant}/toggle-status             → TenantController@toggleStatus

// Tenant Groups
GET/POST/PUT    /tenant-groups                             → TenantGroupController

// Plans & Modules
GET/POST/PUT    /plans                                     → SalesPlanAndModuleMgmtController

// Billing
GET             /invoices                                  → (TenantManagementController?)

// Academic Sessions
GET/POST/PUT    /academic-sessions                         → AcademicSessionController

// Boards & Languages
GET/POST/PUT    /boards                                    → BoardController
GET/POST/PUT    /languages                                 → LanguageController

// Dropdowns
GET/POST/PUT    /dropdowns                                 → DropdownController

// Menus
GET/POST/PUT    /menus                                     → MenuController

// Settings
GET/POST        /settings                                  → SettingController

// Central Users & Roles
GET/POST/PUT    /users                                     → UserController
GET/POST/PUT    /roles                                     → RolePermissionController
GET/POST/PUT    /user-roles                                → UserRolePrmController

// Activity Logs
GET             /activity-logs                             → ActivityLogController
```

---

## 7. UI Screen Inventory

| Screen | Controller | Status |
|--------|-----------|--------|
| Prime Landing Page | PrimeController@index | Implemented |
| Prime Dashboard | PrimeController@dashboard | Implemented |
| Login | PrimeAuthController | Implemented |
| Tenant List | TenantController@index | Implemented |
| Create Tenant | TenantController@create | Implemented |
| Tenant Setup Progress | TenantController@setupProgress | Implemented |
| Complete Tenant Setup (Plan) | TenantController@completeTenantSetup | Implemented |
| Tenant Groups | TenantGroupController | Implemented |
| Plans & Modules | SalesPlanAndModuleMgmtController | Implemented |
| Billing Schedules | TenantController | Partial |
| Invoices | TenantManagementController | Partial |
| Academic Sessions | AcademicSessionController | Implemented |
| Boards | BoardController | Implemented |
| Languages | LanguageController | Implemented |
| Dropdowns | DropdownController/Mgmt | Implemented |
| Menus | MenuController | Implemented |
| Settings | SettingController | Implemented |
| Central Users | UserController | Implemented |
| Roles & Permissions | RolePermissionController | Implemented |
| Activity Logs | ActivityLogController | Implemented |

---

## 8. Business Rules & Domain Constraints

**BR-PRM-01:** A tenant can only be accessed (tenant domain routing) if `is_active = true` AND `tenantPlans()->exists()`. The `Tenant::canAccess()` method enforces this.

**BR-PRM-02:** The `current_flag` generated column on `prm_tenant_plan_jnt` enforces that only one plan subscription can be `is_subscribed = 1` per tenant per plan at any time. Attempting to subscribe a second time creates a new row or updates existing.

**BR-PRM-03:** An active academic session must exist before plan assignment. `TenantPlanAssigner` throws `RuntimeException('No active academic session found.')` if none exists.

**BR-PRM-04:** Billing schedule generation clamps the billing window to the current academic session boundaries: `billingWindowStart = max(start_date, session.start_date)`, `billingWindowEnd = min(end_date, session.end_date)`. If the window is empty, a warning redirect is returned.

**BR-PRM-05:** Module deactivation on a tenant plan is soft — rows are set `is_active = false`, never deleted. This preserves billing history of which modules were active during previous periods.

**BR-PRM-06:** `db_password` in `prm_tenant_domains` must be encrypted. Plaintext database passwords in a SaaS central database are a critical security exposure.

**BR-PRM-07:** `is_super_admin` flag on `sys_user` (central) must not be settable via any web form or API. Promotion to super admin must occur via direct database operation or a dedicated, separately-gated management command.

**BR-PRM-08:** The `SetupTenantDatabase` job has `$tries = 1` — it does not auto-retry on failure. Failed setups must be re-triggered manually via an admin action (re-dispatch job).

**BR-PRM-09:** Root tenant user created during setup uses hardcoded credentials (`root@tenant.com` / `password`). This is a security concern. These credentials must be changed on first login. Consider generating a random password and emailing it to the school admin.

**BR-PRM-10:** Tenant domain routing requires stancl/tenancy v3.9. The `Tenant` model extends `BaseTenant` and implements `TenantWithDatabase`, `HasDatabase`, `HasDomains`.

---

## 9. Workflow & State Machines

### 9.1 Tenant Onboarding Workflow

```
[Admin fills Create Tenant form]
       ↓
[TenantController::store()]
  - Create prm_tenant (is_active=0, setup_status='pending')
  - Create prm_tenant_domains record
  - Send TenantRegisteredMail to tenant email
  - Send TenantRegisteredNotification to all super admins
  - Dispatch SetupTenantDatabase::dispatch($tenant->id)
  - Redirect to setup-progress page
       ↓
[Queue Worker: SetupTenantDatabase::handle()]
  Step 1: CreateDatabase (2% → 5%)
       ↓
  Step 2: RunMigrations (5% → 88%) — tracks per-migration via MigrationEnded events
       ↓
  Step 3: CreateRootUser (88% → 93%)
       ↓
  Step 4: AddOrganization (93% → 99%)
       ↓
  Step 5: Complete (100%)
  - Super admins notified via TenantSetupCompletedNotification

[Admin monitors: setup-progress view polls setup-status API]
[On 100%: Admin proceeds to completeTenantSetup — plan assignment]
```

### 9.2 Plan Assignment Workflow

```
[Admin opens complete-setup page]
  - Selects plan, billing cycle, modules
  - Sets start_date, end_date, rates, taxes, discounts
       ↓
[TenantController::updateTenantPlan()]
  - DB::transaction() wraps all 5 TenantPlanAssigner steps
  Step 1: prm_tenant_plan_jnt (firstOrNew)
  Step 2: prm_tenant_plan_rates (create rate record)
  Step 3: prm_tenant_plan_module_jnt (soft-disable old, add new)
  Step 4: prm_tenant_plan_billing_schedule (soft-disable old, add new schedule entries)
  - Commit or rollback
```

### 9.3 Tenant Status Machine

```
INACTIVE (pending) → [Setup job completes] → INACTIVE (completed) → [Admin activates] → ACTIVE
                   → [Setup job fails] → INACTIVE (failed)
ACTIVE → [Admin deactivates] → INACTIVE
ACTIVE → [Plan expires/suspended] → SUSPENDED
```

---

## 10. Non-Functional Requirements

**NFR-PRM-01 (Security — P0):** `prm_tenant_domains.db_password` must be encrypted at rest using Laravel `Crypt` or an equivalent encryption mechanism. This column contains database credentials for ALL tenant schemas.

**NFR-PRM-02 (Security — P1):** The `is_super_admin` column on central `sys_user` must be excluded from `$fillable` (placed in `$guarded`) in the User model. Mass assignment via `User::create(['is_super_admin' => true, ...])` in `SetupTenantDatabase` uses a controlled context (`$tenant->run()`), but the model-level protection must be enforced.

**NFR-PRM-03 (Scalability):** `SetupTenantDatabase` runs up to ~297 tenant migrations within a 600-second window. For large migration sets, progress tracking via `MigrationEnded` events (updating DB on every 5th migration) is a reasonable balance. Monitor DB write frequency if migration count grows significantly.

**NFR-PRM-04 (Domain Isolation):** Central domain routing (`Route::domain(config('app.domain'))`) ensures tenant requests never reach Prime routes. Tenant domain routing (via stancl/tenancy middleware) ensures Prime routes are not accessible from tenant subdomains.

**NFR-PRM-05 (Audit Trail):** All tenant create/update/plan-change operations must call `activityLog()` helper to write to `sys_activity_logs`. Currently implemented in `store()` but may be missing from other methods.

**NFR-PRM-06 (Availability):** The setup progress API (`/tenants/{id}/setup-status`) must have low latency as it is polled frequently from the progress page. It should be a simple DB read with no heavy computation.

---

## 11. Cross-Module Dependencies

| Dependency | Direction | Purpose |
|-----------|-----------|---------|
| global_db (glb_*) | Consumes | `glb_modules`, `glb_menus`, `glb_cities`, `glb_countries`, `glb_boards` |
| stancl/tenancy v3.9 | Infrastructure | Tenant model, database routing, domain routing |
| Spatie Permission v6.21 | Infrastructure | Central RBAC — roles and permissions |
| spatie/laravel-medialibrary | Infrastructure | Tenant logo via `registerMediaCollections()` |
| Billing module | Owns | `bil_tenant_invoices`, invoice generation |
| SystemConfig (sys_*) | Owns | Dropdown management, activity logs, media |
| All tenant modules | Creates | Via `SetupTenantDatabase` job (runs all tenant migrations) |
| Laravel Queue | Infrastructure | Async tenant database setup |
| Laravel Mail | Infrastructure | `TenantRegisteredMail`, `LoginMail` |

---

## 12. Test Coverage

**Current Tests (9 files, all in Prime module):**

| Test File | Type | Purpose |
|-----------|------|---------|
| SettingModelTest.php (Feature) | Feature | Setting model read/write |
| ArchitectureTest.php | Unit | Code architecture conventions |
| ControllerAuthTest.php | Unit | All controllers require auth |
| FormRequestValidationTest.php | Unit | FormRequest validation rules |
| MigrationSchemaTest.php | Unit | Migration file structure |
| ModelStructureTest.php | Unit | Model fillable/guarded/casts |
| PolicyPermissionTest.php | Unit | Policy permission strings |
| SettingModelTest.php (Unit) | Unit | Setting model unit tests |
| SoftDeleteStatusTest.php | Unit | Soft delete + is_active consistency |

**Missing Tests:**

| Test | Priority |
|------|----------|
| TenantOnboardingTest (Feature) | P0 — entire onboarding pipeline |
| SetupTenantDatabaseJobTest | P0 — 4-stage job pipeline |
| TenantPlanAssignerTest | P1 — plan assignment transaction |
| BillingScheduleGenerationTest | P1 — schedule generation accuracy |
| TenantDomainRoutingTest | P1 — stancl/tenancy routing |
| TenantCanAccessTest | P1 — access control checks |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| Tenant | A school/organization that subscribes to Prime-AI |
| Tenant Group | A managing trust or group that owns multiple schools |
| Plan | A subscription tier defining included modules and pricing |
| Tenant Plan | A specific plan subscription for a specific tenant |
| Billing Schedule | Pre-generated list of future billing dates for a subscription |
| Academic Session | A school year period (e.g., April 2025 – March 2026) |
| Central Domain | The main Prime-AI management domain (primeai.app) |
| TenantWithDatabase | stancl/tenancy interface enabling per-tenant database isolation |
| Root User | The first admin user automatically created in a tenant database during setup |
| current_flag | Generated column that prevents duplicate active subscriptions |

---

## 14. Additional Suggestions (Analyst Notes)

**Priority 0 — Security:**
1. **Encrypt `db_password` in `prm_tenant_domains`** — Use `Crypt::encryptString()` in the Domain model's `setDbPasswordAttribute()` accessor. Decrypt in `getDbPasswordAttribute()`. Update all existing records.
2. **Protect `is_super_admin` from mass assignment** — Add it to `$guarded` in the User model (or remove from `$fillable`). The one legitimate use in `SetupTenantDatabase` must use `DB::table()` directly or `User::forceCreate()`.
3. **Replace `$request->all()` with `$request->validated()`** in `TenantController::update()` and all other controllers using `$request->all()`.

**Priority 1 — Completeness:**
4. **Invoice generation automation** — Build a scheduled command that checks `prm_tenant_plan_billing_schedule` for `bill_generated = false` and `schedule_billing_date <= today`, generates `bil_tenant_invoices`, and marks `bill_generated = true`.
5. **Tenant re-setup capability** — If `setup_status = 'failed'`, admin should be able to re-dispatch `SetupTenantDatabase` from the UI.
6. **Random root password generation** — Instead of hardcoded `password`, generate a random secure password and email it to the tenant admin.

**Priority 2 — UX/Process:**
7. **Tenant activation gate** — After setup completes and plan is assigned, add an explicit "Activate Tenant" button that sets `is_active = 1` and sends a welcome email with the tenant subdomain URL.
8. **Plan version management** — When a plan is updated, create a new `version` instead of modifying the existing plan. This preserves historical billing accuracy.

---

## 15. Appendices

### Appendix A: Key File Paths

| File | Path |
|------|------|
| TenantController | `Modules/Prime/app/Http/Controllers/TenantController.php` |
| TenantPlanAssigner | `Modules/Prime/app/Services/TenantPlanAssigner.php` |
| Tenant Model | `Modules/Prime/app/Models/Tenant.php` |
| Domain Model | `Modules/Prime/app/Models/Domain.php` |
| SetupTenantDatabase Job | `app/Jobs/SetupTenantDatabase.php` |
| Prime Routes | `Modules/Prime/routes/web.php` |
| Prime DDL | `prime_db_v2.sql` (lines 317–600) |

### Appendix B: Known Bugs Register

| Bug ID | Severity | Description | Fix |
|--------|----------|-------------|-----|
| BUG-PRM-001 | CRITICAL | `db_password` stored plaintext | Encrypt with Crypt::encryptString() |
| BUG-PRM-002 | HIGH | `is_super_admin` mass-assignable | Add to $guarded in User model |
| BUG-PRM-003 | MEDIUM | `$request->all()` in TenantController::update() | Use `$request->validated()` |
| BUG-PRM-004 | FIXED | MigrateDatabase step was commented out | Fixed — tenants:migrate via Artisan |

### Appendix C: Tenant Setup Status Values

| Status | Description |
|--------|-------------|
| pending | Tenant created, job queued |
| creating_database | Step 1 in progress |
| running_migrations | Step 2 in progress (tracks per-migration) |
| creating_root_user | Step 3 in progress |
| adding_organization | Step 4 in progress |
| completed | All 4 steps done, tenant ready |
| failed | An exception occurred — check logs |
