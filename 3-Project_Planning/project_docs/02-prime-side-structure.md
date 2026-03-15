# Prime (Central) Side — Structure Guide

## What is Prime Side

Prime is the super-admin/owner panel of the entire SaaS platform. It manages:
- Tenant (school) creation and management
- Billing and subscriptions
- Global master data (countries, states, boards, plans)
- System configuration (menus, settings)
- User roles and permissions at platform level

## Prime Modules

| Module | Controllers | Models | Purpose |
|--------|-------------|--------|---------|
| **Prime** | 22 | 27 | Tenant CRUD, plans, billing, users, roles, modules, menus, geography |
| **GlobalMaster** | 15 | 12 | Countries, states, cities, boards, languages, plans, dropdowns |
| **SystemConfig** | 3 | 3 | Settings, menus, translations |
| **Billing** | 6 | 6 | Invoice generation, payment tracking, billing cycles |
| **Documentation** | 3 | 2 | Knowledge base, help docs |

## Folder Structure — Prime Module

```
Modules/Prime/
├── app/
│   ├── Http/
│   │   └── Controllers/         <- 22 controllers
│   ├── Models/                  <- 27 models
│   └── Providers/
├── database/
│   └── migrations/              <- 37 prime-specific migrations
├── resources/
│   └── views/                   <- 24 view folders
│       ├── academic-session/
│       ├── activity-log/
│       ├── auth/
│       ├── board/
│       ├── components/layouts/
│       ├── core-configuration/
│       ├── dropdown/
│       ├── dropdown-need/
│       ├── dropdown-need-mgmt/
│       ├── email/
│       ├── foundational-setup/
│       ├── language/
│       ├── menu/
│       ├── notification/
│       ├── prime/
│       ├── role-permission/
│       ├── sales-plan-and-module-mgmt/
│       ├── session-board-setup/
│       ├── setting/
│       ├── subscription-billing/
│       ├── tenant/
│       ├── tenant-group/
│       ├── tenant-management/
│       ├── user/
│       └── user-role-permission/
├── routes/
│   ├── web.php                  <- Module-level prime routes
│   └── api.php
└── module.json
```

## Route Registration — Prime

- Module routes defined in: `Modules/Prime/routes/web.php`
- All controllers also imported and routes re-registered in: `routes/web.php`
- `routes/web.php` is the MASTER central route file
- Domain binding: `Route::domain(env('APP_DOMAIN'))->name("central-127.0.0.1.")`

## Migration Location — Prime

| Location | Purpose | Command |
|----------|---------|---------|
| `Modules/Prime/database/migrations/` | Prime/billing specific tables (37 files) | `php artisan migrate` |
| `database/migrations/` | Core framework tables (5 files: cache, jobs, sessions) | `php artisan migrate` |

## Prime Controllers (22)

```
AcademicSessionController       ActivityLogController
BoardController                 DropdownController
DropdownMgmtController          DropdownNeedController
EmailController                 LanguageController
MenuController                  NotificationController
PrimeAuthController             PrimeController
RolePermissionController        SalesPlanAndModuleMgmtController
SessionBoardSetupController     SettingController
TenantController                TenantGroupController
TenantManagementController      UserController
UserRolePrmController
```

## Prime Models (27)

```
AcademicSession    ActivityLog         Board              Domain
Dropdown           DropdownMgmtModel   DropdownNeed       DropdownNeedDropdown
DropdownNeedTableJnt Language          Media              Menu
MenuModule         Permission          Role               Setting
Tenant             TenantGroup         TenantInvoice      TenantInvoiceModule
TenantInvoicingAuditLog               TenantInvoicingPayment
TenantPlan         TenantPlanBillingSchedule              TenantPlanModule
TenantPlanRate     User
```

## Billing Controllers (6)

```
BillingCycleController          BillingManagementController
InvoicingAuditLogController     InvoicingController
InvoicingPaymentController      SubscriptionController
```

## GlobalMaster Controllers (15)

```
AcademicSessionController  ActivityLogController     CityController
CountryController          DistrictController        DropdownController
GeographySetupController   GlobalMasterController    LanguageController
ModuleController           NotificationController    OrganizationController
PlanController             SessionBoardSetupController StateController
```

## SystemConfig Controllers (3)

```
MenuController    SettingController    SystemConfigController
```
