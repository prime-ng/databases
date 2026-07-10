# Prime (PRM) — Feature Inventory

**Module:** Prime | **Code:** PRM | **Registry PREFIX (hint):** `prm_` | **Folder:** `Modules/Prime` | **DDL:** `_prime_db_v4.sql` (registry `_prime_db_` auto-corrected)
**Generated:** 2026-Jul-10 | **Mode:** module (feature discovery) → per-feature 7-artifact generation → report roll-up
**DB scope:** CENTRAL / core (`prime_db`). Central console — `InitializeTenancyByDomain` does NOT apply. **No tenant init.** Browser host `http://127.0.0.1:8000`.

---

## Feature-discovery basis (no requirement folder exists)

There is **NO** `Prime_v1/` (or any `*rime*`) requirement/screen folder under
`4-Requirement_Module_wise/2-Module_Requirement_V1/`. Per the loader rule, the feature list is
**derived from real registered routes + controllers + models + DDL**, and the basis is documented here.

Sources read:
- App-level central routes: `prime_ai/routes/web.php` (route groups `central.` → `prime.` prefix `prime`, and `system-config.` prefix `system-config`). Prime module `routes/web.php` only holds the public/auth routes (`prime.index`, `prime.login`, `prime.logout`) — **all feature routes live in the app-level `routes/web.php`** (constraint #24).
- Controllers: `Modules/Prime/app/Http/Controllers/*` (22 controllers).
- Models `$table`: `Modules/Prime/app/Models/*` (DDL prefix verified per model).
- DDL: `_prime_db_v4.sql` (prm_/sys_/bil_), `_global_db_v4.sql` (glb_).
- Audit: `3-Audit_Reports/V1_Jun-2026/Prime_Complete_Audit_2026-06-29.md` (PRM-prefixed defects).

## Prefix verification (registry `prm_` is a HINT — DDL wins)

The Prime **console manages tables across three schemas**. DDL-verified primary-table prefixes:

| Prefix | Schema / DDL | Screens |
|--------|--------------|---------|
| `prm_` | `_prime_db_v4.sql` (central) | TenantGroup, Tenant, TenantDomain, TenantManagement, SalesPlanAndModuleMgmt |
| `sys_` | `_prime_db_v4.sql` (central, PG+tenant shared) | User, RolePermission, UserRolePrm, Setting, Dropdown, DropdownNeed, DropdownMgmt, ActivityLog |
| `glb_` | `_global_db_v4.sql` (global master) | Board, AcademicSession, SessionBoardSetup, Menu, Language |
| (none) | Laravel notifications / mail (no domain table) | Email, Notification |

> **FLAG (registry vs DDL):** the registry lists Prime `PREFIX=prm_`, but **8 in-scope screens are `sys_` and 5 are `glb_`**. The DDL-verified prefix is used for each artifact's file prefix per HARD RULE 4.

## Scope exclusions

- **Billing (bil_ area) — EXCLUDED (already generated).** `TestCases/Billing/` already holds the 9-feature single-file
  suite (BillingCycle, ConsolidatedPayment, EmailSchedule, GatewayIntegration, Invoicing, InvoicingAuditLog,
  InvoicingPayment, PaymentReconciliation, Subscription), mirroring the committed
  `prime_testing/tests/Browser/Modules/Prime/Billing/*` siblings. The `bil_*` tables (`bil_tenant_invoices`,
  `bil_tenant_invoicing_modules_jnt`, `bil_tenant_invoicing_payments`, `bil_tenant_invoicing_audit_logs`,
  `bil_tenant_email_schedules`) and the Prime models `TenantInvoice*`/`TenantInvoicingPayment`/`TenantInvoicingAuditLog`
  are the Billing sub-area — **not regenerated here.**
- **Other modules routed under the central group but NOT owned by Prime — EXCLUDED:** GlobalMaster (Country/State/City/District/GlobalMaster/Plan/GeographySetup/Module), Documentation (Category/Article/Controller), Scheduler. These use `Modules\GlobalMaster\…` / `Modules\Documentation\…` / `Modules\Scheduler\…` controllers, not Prime.

---

## In-scope Prime feature list (20 screens)

Order: masters → children → junctions → transactional → composite/report last.

| # | Feature (PascalCase) | Controller | Primary table | Prefix (DDL-verified) | DDL file | Type | Route name group | Output folder |
|---|----------------------|------------|---------------|------------------------|----------|------|------------------|---------------|
| 1 | TenantGroup | TenantGroupController | `prm_tenant_groups` | `prm_` | _prime_db_v4 | CRUD master | `central.prime.tenant-group.*` | `Prime/TenantGroup/` |
| 2 | Board | BoardController | `glb_boards` | `glb_` | _global_db_v4 | CRUD master | `central.prime.board.*` | `Prime/Board/` |
| 3 | AcademicSession | AcademicSessionController | `glb_academic_sessions` | `glb_` | _global_db_v4 | CRUD master | `central.prime.academic-session.*` | `Prime/AcademicSession/` |
| 4 | Language | LanguageController | `glb_languages` (VIEW in prime_db) | `glb_` | _global_db_v4 | CRUD (read-mostly over VIEW) | `central.prime.language.*` | `Prime/Language/` |
| 5 | Menu | MenuController | `glb_menus` | `glb_` | _global_db_v4 | CRUD master (tree) | `central.system-config.menu.*` | `Prime/Menu/` |
| 6 | Setting | SettingController | `sys_settings` | `sys_` | _prime_db_v4 | CRUD master | `central.system-config.setting.*` | `Prime/Setting/` |
| 7 | Dropdown | DropdownController | `sys_dropdown_table` | `sys_` | _prime_db_v4 | CRUD master | `central.prime.dropdown.*` | `Prime/Dropdown/` |
| 8 | DropdownNeed | DropdownNeedController | `sys_dropdown_needs` | `sys_` | _prime_db_v4 | CRUD master + AJAX cascade | `central.prime.dropdown-need.*` | `Prime/DropdownNeed/` |
| 9 | SalesPlanAndModuleMgmt | SalesPlanAndModuleMgmtController | `prm_plans` (+ `prm_module_plan_jnt`) | `prm_` | _prime_db_v4 | CRUD master (plan+modules) | `central.prime.sales-plan-mgmt.*` | `Prime/SalesPlanAndModuleMgmt/` |
| 10 | TenantGroup→Tenant→… | — | — | — | — | — | — | — |
| 10 | Tenant | TenantController | `prm_tenant` | `prm_` | _prime_db_v4 | CRUD child + provisioning workflow (BC-SM) | `central.prime.tenant.*` | `Prime/Tenant/` |
| 11 | TenantDomain | TenantDomainController | `prm_tenant_domains` | `prm_` | _prime_db_v4 | CRUD child | `central.prime.tenant-domain.*` | `Prime/TenantDomain/` |
| 12 | User | UserController | `sys_users` | `sys_` | _prime_db_v4 | CRUD child | `central.prime.user.*` | `Prime/User/` |
| 13 | RolePermission | RolePermissionController | `sys_roles` / `sys_permissions` | `sys_` | _prime_db_v4 | CRUD + permission matrix | `central.prime.role-permission.*` | `Prime/RolePermission/` |
| 14 | UserRolePrm | UserRolePrmController | `sys_model_has_roles_jnt` | `sys_` | _prime_db_v4 | junction (user↔role) | `central.prime.user-role-prm.*` | `Prime/UserRolePrm/` |
| 15 | SessionBoardSetup | SessionBoardSetupController | `glb_academic_sessions` + `glb_boards` | `glb_` | _global_db_v4 | composite CRUD | `central.prime.session-board-setup.*` | `Prime/SessionBoardSetup/` |
| 16 | DropdownMgmt | DropdownMgmtController | `sys_dropdown_needs`/`sys_dropdown_table` | `sys_` | _prime_db_v4 | composite CRUD | `central.prime.dropdown-mgmt.*` | `Prime/DropdownMgmt/` |
| 17 | TenantManagement | TenantManagementController | `prm_tenant` (read composite) | `prm_` | _prime_db_v4 | read/composite dashboard | `central.prime.tenant-management.*` | `Prime/TenantManagement/` |
| 18 | ActivityLog | ActivityLogController | `sys_central_activity_logs` | `sys_` | central migration (no DDL — constraint #25) | read-only log | `central.prime.activity-log.*` | `Prime/ActivityLog/` |
| 19 | Email | EmailController | (no table — test/send mail) | n/a | — | action (light) | `central.dashboard.*email` | `Prime/Email/` |
| 20 | Notification | NotificationController | Laravel `notifications` (morph) | n/a | — | read/action (light) | `central.dashboard.*notification*` | `Prime/Notification/` |

*(Row 10 duplicate header is a formatting artifact; the operative Tenant row is #10.)*

## Known source defects to map (from `Prime_Complete_Audit_2026-06-29.md`) — PRM prefix ONLY

| Defect | Sev | Feature to prove it in |
|--------|-----|------------------------|
| BUG-PRM-001 | P0 | TenantDomain (db_password plaintext, no encrypted cast) |
| SEC-PRM-003 | P0 | User (is_super_admin escalation via update `$request->only`) |
| SEC-PRM-001 | P0 | RolePermission (`getPermissions()` ungated) |
| GAP-PRM-003 | P0 | Tenant (SetupTenantDatabase hardcoded root password — provisioning) |
| BUG-PRM-002 / FILL-PRM-001 | P0/P2 | User (`is_super_admin`,`super_admin_flag`,`remember_token` in `$fillable`) |
| BUG-PRM-006 | P1 | Tenant (wrong gate `prime.tenant-group.update` on completeTenantSetup/toggleStatus/tenantPlanToggleStatus) |
| SEC-PRM-002 | P1 | Email / Notification (debug routes in prod, no env guard) |
| GAP-PRM-001 | P1 | Tenant / SalesPlan (GenerateInvoicesCommand missing) |
| BUG-PRM-010 | P1 | User (`usersByRole()` ignores role param) |
| SEC-PRM-004 / TEN-PRM-001 | P1 | DropdownNeed (`filterOptions()` ungated; `initialize()` without `end()`) |
| BUG-PRM-011 | P1 | AcademicSession / SessionBoardSetup (policy double-registration overwrites AcademicSessionPolicy) |
| GAP-PRM-004 | P1 | User (LoginMail not sent to new user on store) |
| MIG-PRM-001 | P1 | Tenant (down() drops `tenants` not `prm_tenant`) |
| D25-PRM-001 | P2 | AcademicSession (`$request->all()` in store/update) |
| D25-PRM-002 | P2 | TenantGroup (`$request->all()` in update only) |
| BUG-PRM-009 | P2 | User / TenantManagement (index rand()/stub stats) |
| BUG-PRM-STUB-001 | P2 | Tenant (`destroy()` empty stub on live route) |
| BUG-PRM-DUP | P2 | DropdownNeed (stale root-level `Models/DropdownNeed.php`) |
| PERF-PRM-001/002 | P2 | DropdownNeed / Menu (raw SHOW queries; Navbar N+1) |
| DEP-PRM-001 | P3 | RolePermission (imports SchoolSetup RolePermissionRequest) |

## DDL / feature gaps flagged

- **G-INV-1:** No Prime requirement/screen folder exists → feature list derived from source (documented above).
- **G-INV-2 (registry prefix):** Registry `PREFIX=prm_` is inaccurate for 13/20 screens (`sys_`×8, `glb_`×5). DDL-verified prefixes used.
- **G-INV-3 (glb_ ownership):** Board / AcademicSession / SessionBoardSetup / Menu / Language have primary tables in `_global_db_v4.sql` (global_master), surfaced as VIEWs/cross-schema reads in `prime_db`. `test_01` asserts via `Schema::hasTable/hasColumns` against the live central connection, not a prm_ DDL file.
- **G-INV-4 (ActivityLog no DDL):** `sys_central_activity_logs` has **no consolidated DDL** (central migration only, constraint #25). `test_01` uses `Schema::hasTable` + model `$fillable`, not a DDL-file `assertStringContainsString`.
- **G-INV-5 (Email/Notification tableless):** no domain table; artifacts are read/action-focused (send, mark-read, list), not a CRUD matrix. SEC-PRM-002 (debug routes in prod) proved as a documented DEV defect.
- **G-INV-6 (TenantManagement/DropdownMgmt composite):** read/composite screens over existing tables — lighter, render/filter/permission focused.
