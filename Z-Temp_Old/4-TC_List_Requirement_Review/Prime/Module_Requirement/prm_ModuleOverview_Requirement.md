# Prime (PRM) — Module Overview & Requirement Document

## 1. Module Overview

| Attribute | Value |
|-----------|-------|
| **Module Name** | Prime |
| **Module Code** | PRM |
| **Table Prefix** | `prm_` |
| **Database Layer** | prime_db (owns prm_* and bil_* schemas); reads global_db |
| **Module Type** | Central Platform Administration (SaaS Operations Console) |
| **Tenant Scope** | Central domain only — NOT tenant-scoped |
| **Framework** | Laravel 12 · nwidart/laravel-modules |
| **Primary Controller** | `Modules/Prime/app/Http/Controllers/` multiple controllers |
| **Model Namespace** | `Modules\Prime\Models` |
| **Route Prefix** | `/prime` (authenticated), `/login`, `/otp-challenge` (guest/auth mixed) |

## 2. Module Purpose

The Prime module is the SaaS operations console for **PrimeGurukul** (the software company). It governs the complete lifecycle of school customers on the platform: onboarding a new school, provisioning its isolated database, assigning subscription plans, controlling which application modules the school can access, generating billing schedules, managing platform staff, and maintaining the reference data that every school module consumes.

## 3. Business Value

| Value Driver | Outcome |
|-------------|---------|
| Automated School Onboarding | A new school's fully isolated database, with all migrations and an initial admin user, is provisioned without manual DBA intervention |
| Module Licensing Control | Schools access only the modules they have subscribed to; oversubscription is structurally prevented |
| Billing Accuracy | Pre-scheduled billing entries eliminate missed invoices and manual billing calendar management |
| Security Isolation | Central domain routing ensures school staff can never access the PrimeGurukul management console |
| Centralised Reference Data | Boards, academic sessions, and dropdown values managed once flow to all schools immediately |

## 4. Scope

### 4.1 In Scope
- School (tenant) onboarding, database provisioning, and domain management
- Subscription plan catalogue with module licensing
- Billing schedule generation feeding the Billing module
- Central platform staff management (users, roles, permissions)
- Global reference data: education boards, languages, academic sessions, dropdown definitions, menus, platform settings
- Platform monitoring dashboard and activity audit logs
- Platform authentication (PrimeGurukul staff login on central domain)

### 4.2 Out of Scope
- School-level user and teacher management (SchoolSetup module)
- Fee collection and payment gateway processing (StudentFee and Payment modules)
- Invoice payment recording and collection follow-up (Billing module)
- Any feature accessible on a school's subdomain
- Student data, academic records, or curriculum content

## 5. Functional Requirements (12 REQs from FRD)

| REQ ID | Feature | Priority | Tags | Description |
|--------|---------|----------|------|-------------|
| REQ-PRM-001 | School Tenant Registration & Automated Database Provisioning | P0 (Core) | WORKFLOW, DATA_ENTRY, INTEGRATION | Platform Manager registers a new school; system creates record + asynchronously provisions isolated DB with migrations, seeds root user + org, notifies parties |
| REQ-PRM-002 | School Group Management | P0 (Core) | DATA_ENTRY | Schools organised into groups representing chains/trusts; every school belongs to exactly one group; groups can be deactivated/soft-deleted |
| REQ-PRM-003 | Subscription Plan Catalogue Management | P0 (Core) | CONFIGURATION, DATA_ENTRY | Platform admins define pricing tier catalogue with module inclusions at three recurrence points; plans are versioned |
| REQ-PRM-004 | Tenant Plan Subscription & Billing Schedule Generation | P0 (Core) | WORKFLOW, DATA_ENTRY, INTEGRATION | Platform Manager assigns plan to school; system performs 5-step transactional process: subscription, rate card, modules, billing calendar |
| REQ-PRM-005 | Billing Schedule to Invoice Pipeline | P1 (Standard) | SCHEDULED, WORKFLOW, INTEGRATION | Scheduled command processes billing schedule entries to generate platform invoices with full financial breakdown |
| REQ-PRM-006 | Central Platform Authentication | P0 (Core) | WORKFLOW | Platform staff login via central domain using email + password; domain-scoped authentication with optional 2FA OTP |
| REQ-PRM-007 | Central Staff User Management | P0 (Core) | DATA_ENTRY | Super Admins manage platform staff accounts: create, assign roles, deactivate, soft-delete, restore |
| REQ-PRM-008 | Role and Permission Management | P0 (Core) | CONFIGURATION | Super Admins create/manage central platform roles with permissions following "module.feature.action" pattern |
| REQ-PRM-009 | Global Reference Data Management | P0 (Core) | CONFIGURATION, DATA_ENTRY | Prime owns reference data: boards, languages, academic sessions, dropdown definitions, navigation menus |
| REQ-PRM-010 | Platform Settings | P0 (Core) | CONFIGURATION | Platform IT/Ops manages key-value platform settings: mail config, SMS provider, platform-wide options |
| REQ-PRM-011 | Platform Dashboard and Analytics | P1 (Standard) | DASHBOARD, REPORT | At-a-glance view of platform health: school counts, revenue, subscription distribution, charts, activity logs |
| REQ-PRM-012 | Activity Log and Monitoring | P1 (Standard) | REPORT | All state-changing operations recorded in activity log with actor, timestamp, and description |

## 6. Primary Actors / User Roles

| Actor | Type | Description |
|-------|------|-------------|
| Platform Super Admin | Internal | Full access to all Prime features; set only via database direct operation |
| Platform Manager | Internal | Manages school onboarding, plan assignments, and tenant group records |
| Platform Finance | Internal | Views billing schedules and invoice status; does not modify plans |
| Platform IT / Ops | Internal | Manages settings, menus, dropdowns, reference data |
| Queue Worker | System | Automated process that executes the school database provisioning job |
| School Admin (Tenant) | External | Has no access to Prime; routes at their own subdomain only |

## 7. Role-Feature Access Matrix

| Feature | Super Admin | Platform Manager | Platform Finance | Platform IT/Ops |
|---------|:-----------:|:----------------:|:----------------:|:---------------:|
| School Group CRUD | Full | Full | View only | No |
| School Tenant CRUD + Onboarding | Full | Full | View only | No |
| Plan Management | Full | Full | View only | No |
| Plan Assignment to School | Full | Full | No | No |
| Billing Schedule View | Full | Full | Full | No |
| Platform User CRUD | Full | No | No | No |
| Role and Permission Management | Full | No | No | No |
| Global Reference Data (Boards, Sessions, Dropdowns) | Full | Full | No | Full |
| Platform Settings | Full | No | No | Full |
| Platform Dashboard | Full | Full | Full | View only |
| Activity Log View | Full | Full | No | No |

## 8. Business Rules Register

| BR ID | Rule Summary | Type | Priority | Enforcement |
|-------|-------------|------|----------|-------------|
| BR-PRM-001 | School access requires active status AND active plan subscription | Permission | P0 | `Tenant::canAccess()` method |
| BR-PRM-002 | Only one active subscription per school per plan | Validation | P0 | DB generated column + unique constraint |
| BR-PRM-003 | Active academic session required before plan assignment | Validation | P0 | Plan Assignment Service |
| BR-PRM-004 | Billing window clamped to active academic session bounds | Calculation | P0 | Plan Assignment workflow |
| BR-PRM-005 | On re-assignment, existing module entries soft-deactivated (never deleted) | Workflow | P0 | Plan Assignment Service |
| BR-PRM-006 | Database password must be stored encrypted at rest | Validation | P0 | Domain model encrypted cast |
| BR-PRM-007 | Super Admin flag not settable via web form/API | Permission | P0 | User model guarded field |
| BR-PRM-008 | Provisioning task runs exactly once per dispatch | Workflow | P1 | Job configuration ($tries=1) |
| BR-PRM-009 | Root user password must be randomly generated, not hardcoded | Validation | P0 | Provisioning Stage 3 |
| BR-PRM-010 | Tenant must implement TenantWithDatabase, HasDatabase, HasDomains | Validation | P0 | Model class declaration |
| BR-PRM-011 | Allowed module list = plan modules ∩ active TenantPlanModules ∩ global module registry | Calculation | P0 | `Tenant::allowedModuleIds()` |
| BR-PRM-012 | Plan edits must create new version, not overwrite | Workflow | P1 | Plan management controller |
| BR-PRM-013 | Completing setup requires Manage Tenant permission, not Manage Tenant Group | Permission | P1 | Authorization gate check |
| BR-PRM-014 | Group cannot be deleted while it has active school records | Validation | P1 | Controller soft-delete logic |
| BR-PRM-015 | Billing cycle determines schedule recurrence | Calculation | P0 | Plan Assignment Service |
| BR-PRM-016 | Billing entry generates invoice only once | Validation | P1 | Scheduled command logic |
| BR-PRM-017 | Invoice due date = invoice date + credit days | Calculation | P1 | Invoice generation logic |
| BR-PRM-018 | Test/debug routes not accessible in production | Permission | P1 | Route file / environment gate |
| BR-PRM-019 | New platform user receives login credentials email | Workflow | P0 | UserController store action |
| BR-PRM-020 | Permission data returned only to authenticated+authorised users | Permission | P0 | Role management controller |
| BR-PRM-021 | Exactly one academic session may be marked current at any time | Validation | P0 | AcademicSession model |
| BR-PRM-022 | Settings search results require View Settings permission | Permission | P2 | Settings controller |
| BR-PRM-023 | All state-changing operations must produce activity log entry | Workflow | P1 | activityLog() helper |

## 9. Data Requirements

### 9.1 Tables in prime_db (prm_ prefix)

| Table | Business Entity | Key Columns |
|-------|----------------|-------------|
| `prm_tenant_groups` | School Group | code, short_name (UNIQUE), name, city_id |
| `prm_tenant` | School / Tenant | code (UNIQUE), tenant_group_id, setup_status, setup_progress, is_active |
| `prm_tenant_domains` | School Domain | domain, db_name, db_password (encrypted), tenant_id |
| `prm_billing_cycles` | Billing Cycle | short_name (UNIQUE), months_count, is_recurring |
| `prm_plans` | Subscription Plan | plan_code + version (UNIQUE), billing_cycle_id |
| `prm_module_plan_jnt` | Plan-Module Map | plan_id, module_id, is_active |
| `prm_tenant_plan_jnt` | Plan Subscription | tenant_id, plan_id, is_subscribed, status |
| `prm_tenant_plan_rates` | Rate Card | tenant_plan_id, start_date, end_date, billing_cycle_id |
| `prm_tenant_plan_module_jnt` | Licensed Modules | module_id, tenant_plan_id, is_active |
| `prm_tenant_plan_billing_schedule` | Billing Schedule | schedule_billing_date, bill_generated, generated_invoice_id |
| `bil_tenant_invoices` | Platform Invoice | invoice_number (UNIQUE), net_payable_amount, status |
| `bil_tenant_invoicing_modules_jnt` | Invoice Modules | invoice_id, module_id |
| `bil_tenant_invoicing_payments` | Invoice Payment | invoice_id, payment_date, amount |
| `bil_tenant_invoicing_audit_logs` | Invoice Audit History | invoice_id, action_type, performed_by |
| `sys_users` | Platform User | email (UNIQUE), is_super_admin (guarded) |
| `sys_roles` | Platform Role | Spatie Permission roles table |
| `sys_permissions` | Permission | Spatie Permission permissions table |
| `sys_settings` | Platform Settings | key (UNIQUE), value, type |
| `sys_dropdown_table` | Dropdown Values | key, ordinal, value |
| `sys_dropdown_needs` | Dropdown Needs | db_type, table_name, column_name |
| `sys_academic_sessions` | Academic Sessions | start_date, end_date, is_current |
| `sys_activity_logs` | Activity Log | user_id, subject_type, subject_id, event |
| `sys_media` | Media Files | model_type, model_id, collection_name |

### 9.2 Views in prime_db (from global_db)

| View | Source |
|------|--------|
| `glb_countries` | global_master.glb_countries |
| `glb_states` | global_master.glb_states |
| `glb_districts` | global_master.glb_districts |
| `glb_cities` | global_master.glb_cities |
| `glb_languages` | global_master.glb_languages |
| `glb_menus` | global_master.glb_menus |
| `glb_modules` | global_master.glb_modules |
| `glb_menu_model_jnt` | global_master.glb_menu_model_jnt |
| `glb_translations` | global_master.glb_translations |

## 10. Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `global_db` (global_master) | Database | glb_cities, glb_modules, glb_boards, glb_menus, glb_languages — FK references and views |
| `stancl/tenancy` v3.9 | Package | Database-per-tenant isolation, domain routing, HasDatabase / HasDomains interfaces |
| `spatie/laravel-permission` v6.21 | Package | RBAC infrastructure on sys_roles / sys_permissions |
| `spatie/laravel-medialibrary` | Package | School logo upload with size conversions (small/medium/large) |
| Laravel Queue | Framework | Async job dispatching for SetupTenantDatabase |
| Laravel Mail | Framework | TenantRegisteredMail, TenantGroupCreatedMail, LoginNotification |
| Billing module | Module | Shared bil_tenant_invoices table; billing schedule consumed downstream |
| All tenant modules (40+) | Modules | Consume provisioned database, allowed module list, dropdowns, sessions, boards |

## 11. Workflows

| Workflow | Trigger | End State |
|----------|---------|-----------|
| WF-1: School Onboarding & Database Provisioning | Platform Manager submits Create School form | Setup Completed or Failed |
| WF-2: Plan Subscription & Billing Schedule | Platform Manager submits plan assignment form | Plan Assigned + Schedule Generated or Rollback |
| WF-3: Automated Invoice Generation | Scheduled command runs (daily) | All qualifying schedule entries invoiced |
| WF-4: Platform Role Permission Assignment | Super Admin saves role with updated permissions | Role's permission set updated |

## 12. Reports & Analytics

| Report ID | Name | Audience | Frequency |
|-----------|------|----------|-----------|
| RPT-PRM-001 | Monthly Revenue Trend | Platform Finance, Super Admin | On dashboard load (12-month chart) |
| RPT-PRM-002 | School Registration Trend | Super Admin, Platform Manager | On dashboard load (12-month chart) |
| RPT-PRM-003 | Overdue Invoice List | Platform Finance, Super Admin | On dashboard load (top 10) |
| RPT-PRM-004 | Tenant Onboarding Status Report | Platform Manager, Super Admin | On demand |
| RPT-PRM-005 | Activity Audit Log | Super Admin, Platform Manager | On demand (filterable) |

## 13. Permissions

| Permission | Description |
|-----------|-------------|
| `prime.dashboard.viewAny` | View platform dashboard |
| `prime.tenant.viewAny` | View tenant list |
| `prime.tenant.view` | View tenant details |
| `prime.tenant.create` | Create new tenant |
| `prime.tenant.update` | Update tenant details, assign plans, toggle status |
| `prime.tenant.delete` | Soft-delete tenant |
| `prime.tenant.restore` | Restore soft-deleted tenant |
| `prime.tenant.forceDelete` | Permanently delete tenant |
| `prime.tenant-group.viewAny` | View tenant group list |
| `prime.tenant-group.view` | View tenant group details |
| `prime.tenant-group.create` | Create tenant group |
| `prime.tenant-group.update` | Update tenant group |
| `prime.tenant-group.delete` | Delete tenant group |
| `prime.tenant-group.restore` | Restore deleted tenant group |
| `prime.tenant-group.forceDelete` | Permanently delete tenant group |
| `prime.tenant-domain.viewAny` | View tenant domain list |
| `prime.tenant-domain.view` | View tenant domain details |
| `prime.tenant-domain.create` | Create tenant domain |
| `prime.tenant-domain.update` | Update tenant domain |
| `prime.tenant-domain.delete` | Delete tenant domain |

## 14. MUST Requirements (12 Minimum Viable Requirements)

| # | MUST Requirement | Criteria |
|---|-----------------|----------|
| M001 | Platform staff must be able to authenticate via email+password on the central domain with optional 2FA OTP | REQ-PRM-006 |
| M002 | Platform Manager must be able to register a new school with async database provisioning | REQ-PRM-001 |
| M003 | Setup progress must be pollable in real-time via a status endpoint | REQ-PRM-001 (AC-001-04) |
| M004 | Platform Manager must be able to organise schools into groups using CRUD operations | REQ-PRM-002 |
| M005 | Platform must support a subscription plan catalogue with module assignment | REQ-PRM-003 |
| M006 | Platform Manager must be able to assign a plan to a school generating billing schedules | REQ-PRM-004 |
| M007 | Platform Super Admin must be able to manage platform staff (users, roles, permissions) | REQ-PRM-007, REQ-PRM-008 |
| M008 | Platform must manage global reference data (boards, academic sessions, dropdowns) | REQ-PRM-009 |
| M009 | Platform must support key-value settings management | REQ-PRM-010 |
| M010 | Platform dashboard must display active tenant count, revenue, overdue invoices, charts + trend data | REQ-PRM-011 |
| M011 | All state-changing operations must be recorded in the activity log | REQ-PRM-012 |
| M012 | School domains must be manageable to support tenant subdomain routing | TenantDomainController |

## 15. Non-Functional Requirements

| NFR ID | Category | Requirement | Priority |
|--------|----------|-------------|----------|
| NFR-PRM-001 | Security | Database credentials encrypted at rest | P0 |
| NFR-PRM-002 | Security | Super Admin flag not settable via web/API | P0 |
| NFR-PRM-003 | Security | Role permission endpoint requires auth+authz | P0 |
| NFR-PRM-004 | Security | All controllers use validated() not request->all() | P1 |
| NFR-PRM-005 | Security | Test/debug routes not reachable in production | P1 |
| NFR-PRM-006 | Security | Complete tenant setup requires correct Manage Tenant permission | P1 |
| NFR-PRM-007 | Security | Sensitive settings values not returned in plaintext | P1 |
| NFR-PRM-008 | Performance | Dashboard page load < 3 seconds | P2 |
| NFR-PRM-009 | Performance | Setup status polling < 500 ms | P1 |
| NFR-PRM-010 | Scalability | Provisioning job: 512 MB RAM, 600s timeout | P1 |
| NFR-PRM-011 | Reliability | Invoice generation command idempotent | P1 |
| NFR-PRM-012 | Isolation | Central domain routes inaccessible from school subdomains | P0 |
| NFR-PRM-013 | Audit | All state-changing operations logged within 1s | P1 |
| NFR-PRM-014 | Usability | Setup progress provides real-time feedback (≤5s polling) | P1 |
| NFR-PRM-015 | Usability | Delete blocked by dependency shows business-language error | P1 |

## 16. Future Enhancements

| ENH ID | Enhancement | Priority |
|--------|-------------|----------|
| ENH-PRM-001 | Re-trigger Failed Setup UI button | P1 |
| ENH-PRM-002 | Secure Root Password Generation with email delivery | P1 |
| ENH-PRM-003 | Plan Version Management UX | P2 |
| ENH-PRM-004 | GenerateInvoicesCommand artisan command | P1 |
| ENH-PRM-005 | Two-Factor Authentication (full flow) | P2 |
| ENH-PRM-006 | Dashboard Query Caching (15-min TTL) | P2 |
| ENH-PRM-007 | Explicit Tenant Activation Gate | P2 |
| ENH-PRM-008 | TenantCreationService refactoring | P2 |
