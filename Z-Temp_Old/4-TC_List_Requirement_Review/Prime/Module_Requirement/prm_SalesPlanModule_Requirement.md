# Prime — Sales Plan & Module Management

**Feature:** Sales Plan & Module Management | **REQ-ID:** REQ-PRM-003 / REQ-PRM-004 | **Priority:** P0 (MUST)

---

## 1. Description

The Sales Plan & Module Management feature provides a combined tabbed interface for managing the subscription plan catalogue and its associated reference data. It consolidates three management areas into a single view with separate tabs: **Billing Cycles** (recurrence periods), **Modules** (application module registry), and **Plans** (pricing tiers with linked modules). Platform Managers can define billing cycles (monthly, quarterly, yearly, one-time), manage the global module registry, and create/edit subscription plans that link modules with pricing.

**Key Capabilities:**
- Billing cycle management: short_name, name, months_count, is_recurring, description
- Module management with search and status filtering, displaying associated menus
- Plan management with search and status filtering, displaying linked modules and billing cycle
- Separate pagination per tab with query string preservation and URL fragments
- Search across all three entity types with status filters

---

## 2. Controller & Model

| Artifact | Path | Lines | Status |
|----------|------|:-----:|--------|
| Controller | `Modules/Prime/app/Http/Controllers/SalesPlanAndModuleMgmtController.php` | 144 | PARTIAL |
| Model (Module) | `Modules\GlobalMaster\Models\Module` | — | EXISTS |
| Model (BillingCycle) | `Modules\Billing\Models\BillingCycle` | — | EXISTS |
| Model (Plan) | `Modules\GlobalMaster\Models\Plan` | — | EXISTS |
| View (index) | `prime::sales-plan-and-module-mgmt.index` | — | EXISTS |

**Note:** This controller currently implements only the `index()` method fully. All resource methods (`create`, `store`, `show`, `edit`, `update`, `destroy`) are stubs with only Gate checks — actual CRUD operations are handled by separate controllers or are not yet implemented.

---

## 3. Routes

| Method | URI | Action | Permission | Status |
|--------|-----|--------|------------|--------|
| GET | `/prime/sales-plan-mgmt` | `index` | `prime.sale-plan-module-mgmt.viewAny` | ✅ Gate check present |
| GET | `/prime/sales-plan-mgmt/create` | `create` | `prime.sale-plan-module-mgmt.create` | ✅ Gate check present (stub) |
| POST | `/prime/sales-plan-mgmt` | `store` | `prime.sale-plan-module-mgmt.create` | ✅ Gate check present (stub) |
| GET | `/prime/sales-plan-mgmt/{sales_plan_mgmt}` | `show` | `prime.sale-plan-module-mgmt.view` | ✅ Gate check present (stub) |
| GET | `/prime/sales-plan-mgmt/{sales_plan_mgmt}/edit` | `edit` | `prime.sale-plan-module-mgmt.update` | ✅ Gate check present (stub) |
| PUT | `/prime/sales-plan-mgmt/{sales_plan_mgmt}` | `update` | `prime.sale-plan-module-mgmt.update` | ✅ Gate check present (stub) |
| DELETE | `/prime/sales-plan-mgmt/{sales_plan_mgmt}` | `destroy` | `prime.sale-plan-module-mgmt.delete` | ✅ Gate check present (stub) |

---

## 4. Data Model

### 4.1 Billing Cycle (`prm_billing_cycles` — prime_db)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | SMALLINT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `short_name` | VARCHAR(50) | ✅ | — | UNIQUE; e.g. 'MONTHLY', 'QUARTERLY', 'YEARLY', 'ONE_TIME' |
| `name` | VARCHAR(50) | ✅ | — | Human-readable name |
| `months_count` | TINYINT UNSIGNED | ✅ | — | Number of months in cycle |
| `description` | VARCHAR(255) | — | NULL | — |
| `is_recurring` | TINYINT(1) | ✅ | 1 | Whether cycle repeats |
| `is_active` | TINYINT(1) | ✅ | 1 | — |

### 4.2 Module (`glb_modules` — global_master database, accessed via view)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `name` | VARCHAR(100) | ✅ | — | Module name |
| `description` | VARCHAR(255) | — | NULL | — |
| `version` | VARCHAR(20) | — | NULL | Module version |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

**Relations:** Has many `menus` (via `glb_menu_model_jnt` junction)

### 4.3 Plan (`prm_plans` — prime_db)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `plan_code` | VARCHAR(20) | ✅ | — | UNIQUE with version |
| `version` | INT UNSIGNED | ✅ | 0 | Incrementing version number |
| `name` | VARCHAR(100) | ✅ | — | Plan name |
| `description` | VARCHAR(255) | — | NULL | — |
| `billing_cycle_id` | SMALLINT | ✅ | — | FK → prm_billing_cycles.id |
| `price_monthly` | DECIMAL(12,2) | — | NULL | Monthly price |
| `price_quarterly` | DECIMAL(12,2) | — | NULL | Quarterly price |
| `price_yearly` | DECIMAL(12,2) | — | NULL | Yearly price |
| `currency` | CHAR(3) | ✅ | 'INR' | — |
| `trial_days` | INT UNSIGNED | ✅ | 0 | Trial period in days |
| `is_active` | TINYINT(1) | ✅ | 1 | — |
| `deleted_at` | TIMESTAMP | — | NULL | Soft delete |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

**Relations:** Belongs to `billingCycle`; belongs to many `modules` (via `prm_module_plan_jnt`)

### 4.4 Plan-Module Junction (`prm_module_plan_jnt` — prime_db)

| Column | Type | Required | Default | Notes |
|--------|------|:--------:|:-------:|-------|
| `id` | INT UNSIGNED AUTO_INCREMENT | ✅ | — | Primary key |
| `plan_id` | INT UNSIGNED | ✅ | — | FK → prm_plans.id ON DELETE CASCADE |
| `module_id` | INT UNSIGNED | ✅ | — | FK → glb_modules.id |
| `is_active` | TINYINT(1) UNSIGNED | ✅ | — | Active flag |
| `created_at` | TIMESTAMP | — | — | — |
| `updated_at` | TIMESTAMP | — | — | — |

---

## 5. Controller Implementation Details

### 5.1 `index(Request $request)`

- **Gate:** `Gate::authorize('prime.sale-plan-module-mgmt.viewAny')`
- **Modules Tab:**
  - Query: `Module::with('menus')`
  - Search: Filters by `name`, `description`, `version` (LIKE %search%)
  - Status filter: `is_active` (0 or 1)
  - Pagination: 10 per page, page name `modules_page`, fragment `#modules`
- **Billing Cycles Tab:**
  - Query: `BillingCycle::query()`
  - Search: Filters by `short_name`, `name`, `description`; numeric search also matches `months_count`
  - Status filter: `is_active` (0 or 1)
  - Pagination: 10 per page, page name `billing_page`, fragment `#billing`
  - Order: `latest()`
- **Plans Tab:**
  - Query: `Plan::with(['modules', 'billingCycle'])`
  - Search: Filters by `plan_code`, `name`, `description`, `version`, `currency`; numeric search also matches `trial_days`
  - Status filter: `is_active` (0 or 1)
  - Pagination: 10 per page, page name `plans_page`, fragment `#plans`
- **View:** `prime::sales-plan-and-module-mgmt.index` with `compact('modules', 'billingCycles', 'plans')`

### 5.2 Stub Methods

| Method | Action |
|--------|--------|
| `create()` | Gate check only; returns `view('prime::create')` |
| `store($request)` | Gate check only; no-op body |
| `show($id)` | Gate check only; returns `view('prime::show')` |
| `edit($id)` | Gate check only; returns `view('prime::edit')` |
| `update($request, $id)` | Gate check only; no-op body |
| `destroy($id)` | Gate check only; no-op body |

---

## 6. Business Rules

| BR-ID | Rule | Verification |
|-------|------|:-----------:|
| BR-PRM-012 | Plan edits must create a new version, not overwrite | ❌ **Not enforced** — controller has stub update method |
| BR-PRM-015 | Billing cycle determines schedule entry recurrence | ✅ Billing cycle entity exists with months_count |
| BR-PRM-011 | Allowed module list derived from plan-module intersection | ✅ Module-plan junction table exists |

---

## 7. Security Rules

| Rule | Implementation |
|------|---------------|
| Gate check on `viewAny` | ✅ `index()` |
| Gate check on `create` | ✅ `create()`, `store()` (stubs) |
| Gate check on `view` | ✅ `show()` (stub) |
| Gate check on `update` | ✅ `edit()`, `update()` (stubs) |
| Gate check on `delete` | ✅ `destroy()` (stub) |

---

## 8. Gaps & Known Issues

| # | Issue | Impact | Severity | Status |
|---|-------|--------|:--------:|:------:|
| 1 | All CRUD operations (create, store, show, edit, update, destroy) are stubs — no actual business logic | Feature gap | P1 — High | ⬜ |
| 2 | Plan versioning not enforced (BR-PRM-012) — editing a plan overwrites existing record | Business rule gap | P1 — High | ⬜ |
| 3 | No Form Request validation for plan/billing-cycle/module operations | Architecture gap | P2 — Medium | ⬜ |
| 4 | No `SoftDeletes` on `prm_billing_cycles` — violates project convention | DDL gap | P2 — Low | ⬜ |
| 5 | `billing_cycle_id` column type mismatch in DDL (SMALLINT vs SMALLINT UNSIGNED) | Schema inconsistency | P2 — Low | ⬜ |
| 6 | No feature tests exist | Testing gap | P1 — High | ⬜ |

---

## 9. FRD References

| Reference | Source | Summary |
|-----------|--------|---------|
| REQ-PRM-003 | FRD §1.3 | Subscription Plan Catalogue Management — pricing tiers, module inclusions |
| REQ-PRM-004 | FRD §1.3 | Tenant Plan Subscription and Billing Schedule Generation |
| BR-PRM-012 | FRD §1.4 | Plan edit creates new version |
| BR-PRM-015 | FRD §1.4 | Billing cycle determines recurrence |
| US-PRM-003 | FRD §8.1 | User story for subscription plan management |

---

## 10. Change Log

| Version | Date | Author | Description |
|---------|------|--------|-------------|
| V1 | — | — | — |
| V2 | — | — | — |
