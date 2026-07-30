# Prime (PRM) — Tenant Management Requirement Document

## 1. Module / Feature

| Attribute | Value |
|-----------|-------|
| **Module** | Prime (PRM) |
| **Feature** | Tenant Management |
| **Sub-Features** | Tenant CRUD, DB Provisioning, Plan Assignment, Board Assignment, Module Toggling, Academic Rollover, Archive Access, Status Management |
| **Prefix** | `prm_` |
| **DB Layer** | prime_db (`prm_tenant`, `prm_tenant_domains`, `prm_tenant_plan_jnt`, `prm_tenant_plan_rates`, `prm_tenant_plan_module_jnt`, `prm_tenant_plan_billing_schedule`, `bil_tenant_invoices`) |
| **Tenant Scope** | Central domain only |

## 2. Controller & Route(s)

### 2.1 TenantController

**File:** `Modules/Prime/app/Http/Controllers/TenantController.php` (~1030 lines)

| Method | HTTP | Route Name | Gate | Description |
|--------|------|-----------|------|-------------|
| `index()` | GET | `central.prime.tenant.index` | `prime.tenant.viewAny` | Paginated list of live tenants |
| `create()` | GET | `central.prime.tenant.create` | `prime.tenant.create` | Show tenant creation form with groups, sessions, boards |
| `store()` | POST | `central.prime.tenant.store` | `prime.tenant.create` | Create tenant, set domain, dispatch SetupTenantDatabase job, send mails |
| `show()` | GET | `central.prime.tenant.show` | `prime.tenant.view` | Redirect to completeTenantSetup |
| `edit()` | GET | `central.prime.tenant.edit` | `prime.tenant.update` | Show edit form |
| `update()` | PUT/PATCH | `central.prime.tenant.update` | `prime.tenant.update` | Update tenant + domain; sync to tenant DB if setup completed |
| `destroy()` | DELETE | `central.prime.tenant.destroy` | `prime.tenant.delete` | Soft-delete + deactivate + send notification |
| `trashedTenant()` | GET | `central.prime.tenant.trashed` | `prime.tenant.restore` | List soft-deleted tenants |
| `restore()` | GET | `central.prime.tenant.restore` | `prime.tenant.restore` | Restore + reactivate soft-deleted tenant |
| `forceDelete()` | DELETE | `central.prime.tenant.forceDelete` | `prime.tenant.forceDelete` | Drop DB, remove storage, delete archives, force-delete record |
| `toggleStatus()` | POST | `central.prime.tenant.toggleStatus` | `prime.tenant.update` | Toggle is_active via AJAX; send notification email |
| `completeTenantSetup()` | GET | `central.prime.tenant.completeTenantSetup` | `prime.tenant.update` | Full setup view with plans, modules, boards, sessions, archive, backup |
| `setupProgress()` | GET | `central.prime.tenant.setupProgress` | `prime.tenant.view` | Show setup progress polling page |
| `setupStatus()` | GET | `central.prime.tenant.setupStatus` | `prime.tenant.view` | JSON endpoint returning setup_status, setup_progress, setup_message |
| `updateTenantPlan()` | POST | `central.prime.tenant.updateTenantPlan` | `prime.tenant.update` | Assign plan: 5-step transaction (plan, rate, modules, schedules, notification) |
| `tenantPlanToggleStatus()` | POST | `central.prime.tenant.tenantPlanToggleStatus` | `prime.tenant.update` | Toggle TenantPlan is_active via AJAX; clear module cache |
| `assignBoards()` | POST | `central.prime.tenant.assignBoards` | `prime.tenant.update` | Assign boards to tenant for a given academic session |
| `tenantModuleToggle()` | POST | `central.prime.tenant.tenantModuleToggle` | `prime.tenant.update` | Toggle TenantPlanModule is_active via AJAX; clear module cache |
| `startRollover()` | POST | `central.prime.tenant.startRollover` | `prime.tenant.update` | Dispatch AcademicSessionRolloverJob for manual session rollover |
| `rolloverStatus()` | GET | `central.prime.tenant.rolloverStatus` | `prime.tenant.view` | JSON endpoint for rollover progress |
| `requestArchiveAccess()` | POST | `central.prime.tenant.archive.requestAccess` | `prime.tenant.update` | Submit archive access request |
| `approveArchiveAccess()` | POST | `central.prime.tenant.archive.approveAccess` | `prime.tenant.update` | Approve pending archive access request |
| `revokeArchiveAccess()` | POST | `central.prime.tenant.archive.revokeAccess` | `prime.tenant.update` | Revoke approved archive access request |
| `resetSetup()` | POST | `central.prime.tenant.resetSetup` | `prime.tenant.update` | Reset failed/completed setup; drop DB; re-dispatch SetupTenantDatabase |

## 3. Business Rules

| BR ID | Rule | Enforcement |
|-------|------|-------------|
| BR-PRM-001 | School access requires active status AND active plan subscription | `Tenant::canAccess()` |
| BR-PRM-002 | Only one active subscription per school per plan | DB generated column + unique constraint (`prm_tenant_plan_jnt.current_flag`) |
| BR-PRM-003 | Active academic session required before plan assignment | Controller check — throws RuntimeException |
| BR-PRM-004 | Billing window clamped to active academic session bounds; no overlap = warning | Controller logic in `updateTenantPlan()` |
| BR-PRM-005 | On re-assignment, existing module entries soft-deactivated, never deleted | Controller logic |
| BR-PRM-006 | Database password must be encrypted at rest | Domain model `SafeEncrypted` cast |
| BR-PRM-008 | Provisioning task runs once ($tries=1); failed = manual re-trigger only | Job configuration |
| BR-PRM-009 | Root user password must be randomly generated | Provisioning Stage 3 |
| BR-PRM-010 | Tenant model must implement TenantWithDatabase, HasDatabase, HasDomains | Model declaration |
| BR-PRM-011 | Allowed module list via three-condition intersection | `Tenant::allowedModuleIds()` |
| BR-PRM-013 | Completing setup requires `prime.tenant.update` | Gate check |
| BR-PRM-015 | Billing cycle determines schedule recurrence | Schedule generation loop |
| BR-PRM-016 | Invoice generated flag prevents duplicates | Schedule entry `bill_generated` flag |
| BR-PRM-017 | Invoice due date = invoice date + credit days | DDL computed / logic |
| BR-PRM-023 | All state-changing operations must produce activity log entry | activityLog() helper |

## 4. Technical Implementation

### 4.1 Tenant Creation (`store()`)

| Step | Action |
|------|--------|
| 1 | Validate via `TenantRequest` — includes tenant_group_id, code, short_name, name, domain, city_id, established_date, academic_session_id, board_id |
| 2 | Remove domain/backup fields not on prm_tenant table |
| 3 | Set defaults: `is_active = 0`, `setup_status = 'pending'`, `setup_progress = 0`, `setup_message = 'Queued for setup...'` |
| 4 | Create tenant record via `Tenant::create()` |
| 5 | Set custom database name: `$tenant->setInternal('db_name', $tenant->generateDatabaseName())` |
| 6 | Create domain record: `$fullDomain = $request->input('domain') . '.' . config('app.domain')` |
| 7 | Dispatch `SetupTenantDatabase` job asynchronously |
| 8 | Send welcome email to tenant email via `TenantRegisteredMail` |
| 9 | Notify all active super admins via `TenantRegisteredNotification` |
| 10 | Log activity: "New school '{$tenant->name}' registered. Database setup queued." |
| 11 | Redirect to setup progress page |

**Validation (TenantRequest):**

| Field | Rules |
|-------|-------|
| tenant_group_id | Required, exists:prm_tenant_groups,id |
| code | Required, max:20, unique:prm_tenant |
| short_name | Required, max:50, unique:prm_tenant |
| name | Required, max:150, unique:prm_tenant |
| domain | Required, max:20, alpha_dash |
| full_domain | Required, unique:prm_tenant_domains.domain |
| email | Nullable, email, max:100, unique |
| city_id | Required, exists:glb_cities |
| established_date | Required, date |
| academic_session_id | Required, exists:glb_academic_sessions |
| board_id | Required, exists:glb_boards |
| backup_service | Required, in: configured services |
| backup_bucket_path | Required, string, max:200 |

### 4.2 Database Name Generation

```
Pattern: <sanitized_short_name>_<20-char-uuid-part>_<6-digit-session-code>
Example: greenwood_int_abc123def456_202526
```

### 4.3 Setup Progress Polling

| Endpoint | Response |
|----------|----------|
| `GET /tenant/setup-status/{id}` | `{ status, progress, message, name }` |
| Frontend polls at intervals ≤ 5 seconds | Uses AJAX to update progress bar |

### 4.4 Plan Assignment (`updateTenantPlan()`) — 5-Step Transaction

| Step | Action |
|------|--------|
| 1 | **Tenant Plan**: Create or update `prm_tenant_plan_jnt` (firstOrNew + fill + save) |
| 2 | **Rate Card**: Create `prm_tenant_plan_rates` record with pricing, discounts, taxes, credit days |
| 3 | **Module Assignment**: Soft-deactivate existing TenantPlanModule rows; insert/update selected modules |
| 4 | **Billing Schedules**: Soft-deactivate existing schedules; generate new schedule entries for the clamped billing window |
| 5 | **Notification**: Queue TenantNotificationMail to tenant email |

**Validation (TenantPlanRequest):**

| Field | Rules |
|-------|-------|
| plan_id | Required, exists:prm_plans |
| included_modules | Nullable, array, each integer, distinct, exists:glb_modules |
| is_subscribed | Required, in:0,1 |
| auto_renew | Required, in:0,1 |
| start_date | Nullable, date |
| end_date | Nullable, date, after_or_equal:start_date |
| billing_cycle_id | Required |
| monthly_rate | Required, numeric, min:0 |
| rate_per_cycle | Required, numeric, min:0 |

### 4.5 Board Assignment (`assignBoards()`)

| Step | Action |
|------|--------|
| 1 | Validate academic_session_id (required, integer) and board_ids (required, array, min:1) |
| 2 | Run inside tenant's database context |
| 3 | Verify the academic session exists in the tenant's DB (`sch_org_academic_sessions_jnt`) |
| 4 | Delete existing board associations for that session |
| 5 | Insert new board associations into `sch_board_organization_jnt` |

### 4.6 Archive Access Request Workflow

| Method | Action |
|--------|--------|
| `requestArchiveAccess()` | Calls `ArchiveAccessRequestService::requestAccess()` with live tenant and archive tenant |
| `approveArchiveAccess()` | Find pending request; call `service->approve()` |
| `revokeArchiveAccess()` | Find approved request; call `service->revoke()` |

### 4.7 Academic Rollover

| Method | Action |
|--------|--------|
| `startRollover()` | Validate tenant is live; dispatch `AcademicSessionRolloverJob` with next_session_id and copy_files flag |
| `rolloverStatus()` | Return JSON with rollover_status, rollover_progress, rollover_message |

**Preconditions for rollover:**
- Tenant must be live (`$tenant->isLive()`)
- Redirect with error if not live: "Rollover can only be started for a live tenant."

### 4.8 Reset Setup

| Method | Action |
|--------|--------|
| `resetSetup()` | Only allowed when setup_status is 'failed' or 'completed' |
| Drop tenant database if exists |
| Remove public symlink if created |
| Reset status to 'pending', progress to 0 |
| Clear allowed modules cache |
| Re-dispatch SetupTenantDatabase job with reset flag |

### 4.9 Soft-Delete & Force-Delete

**Soft-delete (destroy):**
- Sets `is_active = false`
- Calls `$tenant->delete()`
- Sends deactivation email
- Logs activity

**Restore:**
- Restores soft-deleted record
- Sets `is_active = true`
- Sends restoration email
- Logs activity

**Force-delete:**
- Drops tenant database
- Removes public symlink
- Deletes tenant storage directory
- Deletes archived storage directories
- Iterates archive tenants: drops archive DB, deletes storage, deletes domains, deletes archive access requests, force-deletes archive records
- Force-deletes the live tenant record
- Sends permanent deletion email
- Logs activity

### 4.10 Status Toggles

| Toggle | Endpoint | Action |
|--------|----------|--------|
| `toggleStatus()` | POST `/tenant/{tenant}/toggle-status` | Toggle `is_active` on prm_tenant; send activation/deactivation email |
| `tenantPlanToggleStatus()` | POST `/tenant/plan/{tenant_plan}/toggle-status` | Toggle `is_active` on prm_tenant_plan_jnt; clear allowed module cache |
| `tenantModuleToggle()` | POST `/tenant/module/{tenantPlanModule}/toggle` | Toggle `is_active` on prm_tenant_plan_module_jnt; clear allowed module cache |

### 4.11 Models Used

| Model | Table | Relationships |
|-------|-------|-------------|
| `Tenant` | `prm_tenant` | tenantGroup, parentTenant, archiveTenants, archiveAccessRequests, city, tenantPlans, billingSchedules, invoices, domains |
| `TenantPlan` | `prm_tenant_plan_jnt` | plan, tenantPlanRates, tenantPlanModules |
| `TenantPlanRate` | `prm_tenant_plan_rates` | billingCycle |
| `TenantPlanModule` | `prm_tenant_plan_module_jnt` | module, menus |
| `TenantPlanBillingSchedule` | `prm_tenant_plan_billing_schedule` | billingCycle |
| `TenantInvoice` | `bil_tenant_invoices` | tenant |
| `TenantArchiveAccessRequest` | (prm_tenant_archive_access_requests) | requester, approver |
| `TenantGroup` | `prm_tenant_groups` | tenants, liveTenants |
| `AcademicSession` | `sys_academic_sessions` | — |
| `Domain` | `prm_tenant_domains` | tenant |
| `Plan` | `prm_plans` | modules |
| `Module` | `glb_modules` | menus |
| `BillingCycle` | `prm_billing_cycles` | — |
| `Board` | `glb_boards` | — |
| `BackupRun` | (maintenance) | — |
| `RestoreLog` | (maintenance) | — |

### 4.12 Jobs & Mails

| Job/Mail | Trigger | Description |
|----------|---------|-------------|
| `SetupTenantDatabase` | Tenant creation | Async: creates DB, runs migrations, seeds root user + org |
| `AcademicSessionRolloverJob` | Manual rollover start | Async: performs academic session rollover for a tenant |
| `TenantRegisteredMail` | Tenant creation | Welcome email to tenant |
| `TenantRegisteredNotification` | Tenant creation | In-app notification to super admins |
| `TenantNotificationMail` | Various (plan update, toggle, delete, restore) | Notification email to tenant |

## 5. Permissions

| Permission | Methods |
|-----------|---------|
| `prime.tenant.viewAny` | index |
| `prime.tenant.view` | show, setupProgress, setupStatus, rolloverStatus |
| `prime.tenant.create` | create, store |
| `prime.tenant.update` | edit, update, completeTenantSetup, toggleStatus, updateTenantPlan, tenantPlanToggleStatus, assignBoards, tenantModuleToggle, startRollover, requestArchiveAccess, approveArchiveAccess, revokeArchiveAccess, resetSetup |
| `prime.tenant.delete` | destroy |
| `prime.tenant.restore` | trashedTenant, restore |
| `prime.tenant.forceDelete` | forceDelete |

## 6. Validation & Error Messages

| Scenario | Message |
|----------|---------|
| Plan assignment — no active session | "No active academic session found." (RuntimeException) |
| Plan assignment — invalid tenant | "Invalid tenant." (ValidationException) |
| Plan assignment — no plan_id | "Plan id is required." (ValidationException) |
| Plan assignment — billing window outside session | Warning: "No billing periods fall within the current academic session." |
| Board assignment — no boards selected | "Please select at least one board." |
| Board assignment — invalid session | "Invalid academic session for this tenant." (ValidationException) |
| Rollover — tenant not live | "Rollover can only be started for a live tenant." |
| Reset setup — wrong status | "Setup can only be reset when it has failed or already completed." |
| Force-delete failure | "Failed to permanently delete tenant: {message}" |
| Soft-delete success | flash('trashed.tenant') |
| Restore success | flash('restored.tenant') |
| Force-delete success | flash('force_deleted.tenant') |
| Toggle status success | flash('status_updated.tenant') |
| Toggle status failure | flash('status_switch_failed.tenent') |
| Plan toggle enable | "Plan enabled — menus visible." |
| Plan toggle disable | "Plan disabled — menus hidden." |
| Module toggle enable | "Module enabled" |
| Module toggle disable | "Module disabled" |
| Archive request success | "Archive access request submitted." |
| Archive approve success | "Archive access approved." |
| Archive revoke success | "Archive access revoked." |

## 7. Feature Dependencies

| Dependency | Type | Purpose |
|-----------|------|---------|
| `SetupTenantDatabase` Job | Job | Async database provisioning |
| `AcademicSessionRolloverJob` | Job | Async session rollover |
| `ArchiveAccessRequestService` | Service | Archive access management |
| `TenantRequest` | FormRequest | Tenant creation/update validation |
| `TenantPlanRequest` | FormRequest | Plan assignment validation |
| `TenantRegisteredMail` | Mail | Welcome email |
| `TenantNotificationMail` | Mail | Notification emails (plan, status, delete, restore) |
| `TenantRegisteredNotification` | Notification | In-app notification to super admins |
| `Spatie MediaLibrary` | Package | School logo upload and conversion |
| `stancl/tenancy` | Package | Database-per-tenant isolation |

## 8. Acceptance Criteria

| AC ID | Criteria |
|-------|----------|
| AC-001-01 | Given a completed school registration form, the system creates the school record with setup status "Pending" and active status "Inactive", creates the school domain record, dispatches the database provisioning task, sends a welcome email to the school's email address, and redirects the admin to the setup progress view |
| AC-001-02 | Given the provisioning task completes all four stages successfully, the school's database exists, setup status shows "Completed", setup progress shows 100%, a root administrator user exists in the school's database, and an initial organisation record exists in the school's database |
| AC-001-03 | Given the provisioning task fails at any stage, setup status shows "Failed", setup progress is frozen at the last completed percentage, and a failure notification is sent to all Super Admins |
| AC-001-04 | Given a school is fully provisioned, the setup progress view is accessible by polling the status endpoint, and a Platform Manager can see the current stage and percentage without refreshing the page |
| AC-001-05 | Given the school domain is changed after creation, the platform's routing resolves the new domain for all future school requests |
| AC-001-06 | Given a Platform Manager without the "Manage Tenants" permission attempts to create a school, the system returns a 403 Access Denied response |
| AC-004-01 | Given a monthly billing subscription, the system generates exactly the expected number of billing schedule entries |
| AC-004-02 | Given a subscription date range that falls entirely outside the current academic session, the system returns a warning and creates no billing schedule entries |
| AC-004-03 | Given a failure at any of the five steps within the plan assignment transaction, all steps are rolled back |
| AC-004-04 | Given a plan re-assignment, previously active module entries are soft-deactivated and new module entries are added; old billing schedule entries are soft-deactivated |
| AC-004-05 | Given no active academic session exists, the plan assignment is blocked with a clear business-language error message |
| AC-004-06 | Given a user without the correct permission for plan assignment, the system returns 403 |

## 9. Workflows

### WF-1: School Onboarding & Database Provisioning

| Step | Actor | Action |
|------|-------|--------|
| 1 | Platform Manager | Fills and submits Create School form |
| 2 | System | Validates form; creates record (Pending, Inactive) + domain |
| 3 | System | Dispatches SetupTenantDatabase to queue |
| 4 | System | Sends welcome email + Super Admin notification |
| 5 | System | Redirects to Setup Progress view |
| 6 | Queue Worker | Stage 1: Creates DB (0%→5%) |
| 7 | Queue Worker | Stage 2: Runs migrations (5%→88%) |
| 8 | Queue Worker | Stage 3: Creates root user (88%→93%) |
| 9 | Queue Worker | Stage 4: Creates org record (93%→99%→100%) |
| 10 | System | Notifies Super Admins on completion or failure |

### WF-2: Plan Subscription & Billing Schedule

| Step | Actor | Action |
|------|-------|--------|
| 1 | Platform Manager | Selects plan, cycle, dates, rate card, modules |
| 2 | System | Validates; resolves active academic session |
| 3 | System | Clamps billing window to session bounds |
| 4 | System | Transaction: Step 1 — record subscription |
| 5 | System | Step 2 — create rate card |
| 6 | System | Step 3 — soft-deactivate modules, create new |
| 7 | System | Step 4 — soft-deactivate schedules, generate new |
| 8 | System | Commit; send notification; redirect with success |

## 10. Edge Cases & Error Handling

| Scenario | Expected Behaviour |
|----------|-------------------|
| Duplicate tenant code during creation | Unique constraint violation; validation error returned |
| Tenant creation with non-existent city_id | Foreign key constraint prevents creation |
| SetupTenantDatabase job fails | Status set to "Failed"; progress frozen; notification sent to Super Admins |
| Reset setup for non-failed/completed tenant | Validation error: only failed/completed setups can be reset |
| Force-delete tenant with active archive tenants | All archive tenants force-deleted recursively |
| Plan assignment with end_date before start_date | Validation error: "end_date must be after or equal to start_date" |
| Module toggle on non-existent TenantPlanModule | 404 from route-model binding |
| Board assignment with non-existent board_id | Validation error: invalid board selected |
| Archive access request for non-existent archive tenant | 404 from route-model binding |
| Rollover for non-live tenant | Error: "Rollover can only be started for a live tenant." |
| Duplicate domain on tenant creation | Validation error: "This sub-domain is already taken" |

## 11. Future Enhancements

| ENH ID | Enhancement | Details |
|--------|-------------|---------|
| ENH-PRM-001 | Re-trigger Failed Setup UI | Reset button on setup progress view when failed |
| ENH-PRM-002 | Secure Root Password Generation | Replace hardcoded default with Str::password(16) |
| ENH-PRM-004 | GenerateInvoicesCommand | Scheduled command to convert billing schedules to invoices |
| ENH-PRM-007 | Explicit Tenant Activation Gate | Separate activate step after plan assignment |
| ENH-PRM-008 | TenantCreationService Refactoring | Extract from controller into dedicated service |

## 12. State Machines

### FSM-PRM-001 — Tenant Setup Status

| From | Event | Guard | To | Side Effects |
|------|-------|-------|----|-------------|
| New | Create School form | Validated | Pending | Domain + job dispatched |
| Pending | Stage 1 start | Job dequeued | Creating DB | Progress 0→5% |
| Creating DB | DB created | Success | Running Migrations | Progress advances |
| Running Migrations | All done | ~600 success | Creating Root User | Progress 88% |
| Creating Root User | User created | Success | Adding Organisation | Progress 93% |
| Adding Organisation | Org created | Success | Completed | Progress 100%; notify |
| Any intermediate | Exception | Error thrown | Failed | Progress frozen; notify |
| Failed | Re-trigger | Admin action | Pending | Reset + re-dispatch |
| Completed | Plan assignment + activate | is_active=true | Accessible | School goes live |

### FSM-PRM-002 — Plan Subscription Status

| From | Event | Guard | To | Side Effects |
|------|-------|-------|----|-------------|
| New | Plan assigned | Transaction commits | Active | Module access + schedule |
| Active | Suspend | Admin action | Suspended | No module access |
| Active | End date / cancel | Date/admin | Expired/Cancelled | Access removed |
| Suspended | Reinstate | Admin action | Active | Access restored |
