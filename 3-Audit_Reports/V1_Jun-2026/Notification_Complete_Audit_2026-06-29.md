# Technical Audit Report — Notification Module (NTF)
**Mode:** X (Complete — A + B + C + G + Scoped D)
**Date:** 2026-06-29
**Auditor:** pa-technical-auditor
**Module:** Notification | Code: NTF | Prefix: `ntf_`
**Codebase branch:** main @ b6f5e5d16

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Health Score | **34 / 100** |
| Verdict | **NO-GO** |
| P0 Findings | **8** |
| P1 Findings | **12** |
| P2 Findings | **13** |
| P3 Findings | **3** |
| REQ Coverage (42 total) | 1 Working / ~22 Partial / 11 Not Started / 3 Broken |
| BR Violations (13 total) | 3 Violated / 7 Not Enforced / 1 Partial / 2 Satisfied |
| Tests | **0** |

The Notification module is structurally present (15-table schema, 12 controllers, 15 models, 11 FormRequests, ~66 views) but is not safe to deploy in its current state. Eight P0 findings collectively render the module non-functional in production:

- Every authorization check in every controller uses the wrong Gate prefix (`prime.*` instead of `tenant.*`) — all tenant users are silently unauthorized on 100% of NTF actions.
- The delivery dispatch pipeline has no execution vehicle: `ProcessNotificationJob` does not exist, and its dispatch call is commented out.
- `canBeProcessed()` is called on the `Notification` model but the method does not exist — any `process()` call throws a PHP Fatal error.
- Provider API credentials are stored as plaintext despite column names (`api_key_encrypted`) and BR-NTF-011 requiring encryption.
- `Tenant::all()` and `Tenant::get()` appear in five controllers, querying `prime_db.tenants` from a tenant context — cross-DB data exposure.
- `ntf_delivery_logs` has two NOT NULL columns (`provider_id`, `resolved_user_id`) but the delivery service passes nullable values — every delivery log INSERT fails at runtime.

Only in-app notification delivery (via `InAppSystemNotification`) is operationally functional.

---

## Module Snapshot (at audit time)

| Property | Value |
|----------|-------|
| Laravel Module Dir | `Modules/Notification/` |
| Route File | `Modules/Notification/routes/web.php` (~104 lines, all active) |
| Route Prefix | `/notification/*` |
| RSP Web Middleware | InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified — CORRECT |
| RSP API Middleware | `api` only — tenancy stack missing (API routes currently empty) |
| Tenant Migrations | 15 create + 4 alter (`2026_06_16_111135` through `2026-06-24`) |
| Policy | `PrimeNotificationPolicy.php` — name and prefix both wrong |
| Services | `NotificationService.php` only; no `RecipientResolutionService` |
| Jobs | 0 — `ProcessNotificationJob` does NOT exist |
| Events / Listeners | 1 each: `SystemNotificationTriggered` / `ProcessSystemNotification` (ShouldQueue) |
| Tests | 0 |
| FRD | `NTF_FRD_Complete_2026-06-29.md` — 42 REQs, 13 BRs, 4 RPTs, 7 ENHs |

---

## Layer-by-Layer Audit

### Layer 1 — DDL Schema (Three-Way Reconcile: DDL spec ↔ Migration ↔ Model)

**15 tables — migration order:** `ntf_channel_master` → `ntf_notification_threads` → `ntf_target_groups` → `ntf_user_devices` → `ntf_provider_master` → `ntf_templates` → `ntf_notifications` → `ntf_notification_channels` → `ntf_notification_targets` → `ntf_resolved_recipients` → `ntf_delivery_queue` → `ntf_user_preferences` → `ntf_notification_thread_members` → `ntf_schedule_audit` → `ntf_delivery_logs`

**Three-way reconcile findings:**

| Table | Status | Mismatch |
|-------|--------|----------|
| ntf_channel_master | PASS | — |
| ntf_provider_master | FAIL | No `created_by` column in migration; no `encrypted` cast in model for `api_key_encrypted`/`api_secret_encrypted` |
| ntf_notifications | PASS | `softDeletes()` present; migration and model aligned |
| ntf_delivery_logs | FAIL | `provider_id` NOT NULL in migration but `logDelivery($providerId = nullable)` in service; `resolved_user_id` NOT NULL but service passes `$payload['user_id'] ?? null` |
| ntf_templates | FAIL | `dlt_template_id` column required by BR-NTF-010 and REQ-NTF-011 but absent from migration |
| ntf_user_devices | FAIL | Missing `deleted_at` (`softDeletes()` absent) — cannot purge stale device tokens |
| ntf_resolved_recipients | WARN | FK references `sys_user` (singular); convention is `sys_users` (plural) |

**D29 ENUM count:** 10 of 15 migrations use `->enum()` (platform pattern — 10 tables affected: channel_master, notification_threads, target_groups, user_devices, provider_master, templates, notifications ×3, delivery_logs, delivery_queue, schedule_audit). Values should be sys_dropdown FK lookups per D29.

**sys_dropdowns FK validation:** Confirmed correct — `sys_dropdowns` is a tenant table (renamed from `sys_dropdown_table` per migration `2026_06_15_145407`, D-MSH-009). FKs in `ntf_notifications`, `ntf_delivery_logs` referencing `sys_dropdowns` are valid tenant-scoped FKs.

---

### Layer 2 — Migrations

**19 migrations total (15 create, 4 alter):**
- All create migrations batch-dated `2026_06_16` — clean single-day scaffold
- Alter migrations: UUID fix, nullable columns, `notification_status_id` nullable, unique constraint on `ntf_channel_master` (2026-06-24)
- Migration ordering: correct (channel_master before provider_master before notifications)
- Rollback down() methods present on all migrations reviewed

**Issues:**
- `ntf_delivery_logs.provider_id` is NOT NULL with FK to `ntf_provider_master` — but `NotificationService::logDelivery()` accepts `?int $providerId` and the service may pass null when no provider is selected for in-app delivery. Runtime INSERT will fail with errno 1048 (Column 'provider_id' cannot be null). (MIG-NTF-001, P0)
- `ntf_delivery_logs.resolved_user_id` is NOT NULL — but `logDelivery()` passes `$payload['user_id'] ?? null`. When payload has no user_id, INSERT fails. (MIG-NTF-002, P0)

---

### Layer 3 — Eloquent Models

**15 models reviewed: ChannelMaster, DeliveryQueue, Notification, NotificationChannel, NotificationDeliveryLog, NotificationTarget, NotificationTemplate, NotificationThread, NotificationThreadMember, ProviderMaster, ResolvedRecipient, ScheduleAudit, TargetGroup, UserDevice, UserPreference**

**Positive findings:**
- `$fillable` defined on all models reviewed (no `$guarded = []`)
- Date/boolean/decimal/array casts comprehensive on Notification, NotificationDeliveryLog
- SoftDeletes trait present on Notification (matching migration `softDeletes()`)

**Issues:**

| Code | Severity | Model | Issue |
|------|----------|-------|-------|
| BUG-NTF-011 | P0 | Notification.php | `canBeProcessed()` method absent; called at `NotificationManageController.php:556` → PHP Fatal |
| BUG-NTF-009 | P1 | Notification.php:92 | `getRouteKeyName()` returns `'notification_uuid'` but all controllers use `findOrFail($id)` with integer — route model binding broken |
| BUG-NTF-010 | P1 | Notification.php:154,178 | `resolvedRecipients()` and `logs()` commented out — these relationships are referenced in FRD delivery tracking |
| SEC-NTF-001 | P0 | ProviderMaster.php | `api_key_encrypted` and `api_secret_encrypted` in `$fillable` but `$casts` has no `'encrypted'` entry — credentials stored as plaintext despite column names; violates BR-NTF-011 |
| TEN-NTF-002 | P1 | Notification.php, NotificationDeliveryLog.php | Both import `Modules\GlobalMaster\Models\Dropdown` for status relationships — Dropdown model queries `global_db`; from tenant context, this hits wrong DB |
| ORM-NTF-001 | P2 | Notification.php | `scopeReadyToDispatch()` uses `whereIn('dropdown_key', ['DRAFT', 'SCHEDULED'])` — DRAFT notifications must never be dispatched (BR-NTF-001); scope is semantically wrong |

---

### Layer 4 — Controllers & Authorization

**12 controllers audited: NotificationManageController, ChannelMasterController, ProviderMasterController, TemplateController, DeliveryQueueController, ResolvedRecipientController, NotificationTargetController, NotificationThreadController, ScheduleAuditController, TargetGroupController, NotificationThreadMemberController, UserPreferenceController**

**BUG-NTF-003 (P0) — Platform-wide wrong Gate prefix in ALL 12 controllers:**

Every `Gate::authorize()` call uses `prime.*` prefix instead of `tenant.*`. Sample evidence:
- `NotificationManageController`: `Gate::authorize('prime.notification.viewAny')` line 32; `'prime.notification.create'` line 270; `'prime.notification.update'` line 366
- `ProviderMasterController`: `Gate::authorize('prime.provider-master.viewAny')` line 19; `'prime.provider-master.create'` line 113
- `ChannelMasterController`: `Gate::authorize('prime.channel-master.create')` line 119

Tenant users have no `prime.*` permissions. Every Gate check returns an unauthorized response, meaning every NTF action is either silently unauthorized or (where middleware is applied) returns 403 to every tenant user.

**BUG-NTF-007 (P1):** `NotificationManageController::create()` (line 228) and `edit()` (line 337) have no `Gate::authorize()` call at all — accessible by any authenticated user.

**Additional controller issues:**

| Code | Severity | Controller:Line | Issue |
|------|----------|-----------------|-------|
| BUG-NTF-005 | P0 | NotificationManageController.php:579 | `// ProcessNotificationJob::dispatch($notification);` — delivery trigger commented out |
| TEN-NTF-001 | P0 | NotificationManageController:243, TemplateController:288/382/445, ResolvedRecipientController:285, NotificationThreadController:283, UserPreferenceController:218 | `Tenant::all()` / `Tenant::get()` from `Modules\Prime\Models\Tenant` — queries `prime_db.tenants` from within a tenant DB context; exposes full tenant list |
| BUG-NTF-004 | P1 | NotificationManageController.php:274,371 | `store()` and `update()` use `$request->tenant_id`, `$request->title` etc. instead of `$request->validated()` — FormRequest validation bypassed |
| PERF-NTF-002 | P2 | NotificationManageController.php:428 | `Schema::hasColumn($notification->getTable(), 'is_active')` in `destroy()` — hot-path introspection, expensive per-request |
| PERF-NTF-003 | P2 | NotificationManageController.php:230 | `NotificationTemplate::all()` — unbounded query loading all templates |
| BUG-NTF-012 | P3 | ChannelMasterController.php:411 | Circular fallback check validates only self-reference; BR-NTF-013 requires depth-5 traversal |

---

### Layer 5 — FormRequests

**11 FormRequests:** DeliveryQueueRequest, NotificationRequest, NotificationTargetRequest, NotificationThreadMemberRequest, NotificationThreadRequest, ProviderMasterRequest, ResolvedRecipientRequest, ScheduleAuditRequest, TargetGroupRequest, TemplateRequest, UserPreferenceRequest

**Authorization audit:**

| Request | authorize() | Issue |
|---------|-------------|-------|
| NotificationRequest | `auth()->user()->can('prime.notification.create')` | Wrong prefix (VAL-NTF-002) |
| DeliveryQueueRequest | `auth()->user()->can('prime.notification.delivery-queue.create')` | Wrong prefix (VAL-NTF-002) |
| TemplateRequest | `auth()->user()->can('prime.notification.template.create')` | Wrong prefix (VAL-NTF-002) |
| ResolvedRecipientRequest | `auth()->user()->can('prime.notification.resolved-recipient.create')` | Wrong prefix (VAL-NTF-002) |
| NotificationTargetRequest | `return true;` | D30 pattern (VAL-NTF-001) |
| NotificationThreadMemberRequest | `return true;` | D30 pattern (VAL-NTF-001) |
| NotificationThreadRequest | `return true;` | D30 pattern (VAL-NTF-001) |
| ProviderMasterRequest | `return true;` | D30 pattern (VAL-NTF-001) |
| ScheduleAuditRequest | `return true;` | D30 pattern (VAL-NTF-001) |
| UserPreferenceRequest | `return true;` | D30 pattern (VAL-NTF-001) |

6 of 11 FormRequests return bare `true` (D30 platform pattern — above platform baseline of 90% for this module).

**VAL-NTF-003 (P2):** `NotificationRequest::rules()` validates `tenant_id` with `'exists:tenants,id'` — the `tenants` table is in `prime_db`, not the tenant's database. Cross-DB `exists:` rule will fail with "Table not found" in tenant context.

---

### Layer 6 — Route & Middleware

**Web routes (RSP):** Full tenancy middleware stack confirmed in `RouteServiceProvider.php`:
`InitializeTenancyByDomain` → `PreventAccessFromCentralDomains` → `EnsureTenantIsActive` → `auth` → `verified`
Result: **CLEAN**

**API routes (RSP):** `Route::middleware('api')` only — no tenancy initialization. API routes file exists (`routes/api.php`) but contains only a placeholder `auth:sanctum` group with no routes. Low-impact currently but must be fixed before any API routes are added.

**Route inventory:** `web.php` has 12 controller imports; all routes active including `schedule-audit` resource at line 104.

**EnsureTenantHasModule middleware:** Not present in RSP — module-level entitlement not enforced.

---

### Layer 7 — Services & Business Logic

**NotificationService.php** (only service):

**Positive:** Event-driven pipeline correctly wired — `SystemNotificationTriggered` → `ProcessSystemNotification` (ShouldQueue) → `NotificationService::trigger()`. `sendEmail()` call is active (was previously commented out; now fixed). `InAppSystemNotification` working end-to-end.

**Issues:**

| Code | Severity | Service:Line | Issue |
|------|----------|--------------|-------|
| TEN-NTF-003 | P1 | NotificationService.php:204 | `Dropdown::query()` from `Modules\GlobalMaster\Models\Dropdown` — queries `global_db` from tenant service context for delivery status lookup |
| JOB-NTF-001 | P1 | Listeners/ProcessSystemNotification.php | Implements `ShouldQueue` — when dispatched to queue worker, tenancy context is lost; `handle()` does not re-initialize tenancy; `NotificationService::trigger()` will query wrong DB |
| MIG-NTF-001 | P0 | NotificationService.php:200-228 | `logDelivery()` early-returns if `$resolvedRecipientId` is null (line 200-202) — delivery never logged for email triggers without explicit recipient ID; when it does write, `provider_id` (NOT NULL) may be null → INSERT failure |
| — | P1 | NotificationService.php:39-44 | Template lookup uses `is_active=true` but does NOT check approval status → dispatches Pending/Draft templates; violates BR-NTF-005 |
| — | P2 | NotificationService.php:28 | Notification dispatched to channels without checking `is_opted_in` on `UserPreference` — BR-NTF-002 opt-out not enforced |
| — | P2 | NotificationService.php | No quiet hours check (BR-NTF-003), no rate limit check (BR-NTF-007), no expiry check (BR-NTF-012) |

**Missing services:**
- `RecipientResolutionService` — does not exist; CLASS/SECTION/GROUP targeting cannot expand to individual recipients (ARCH-NTF-002)
- No rate limiter service
- No DLT compliance service

---

### Layer 8 — Queue & Jobs

**ProcessNotificationJob:** Does not exist anywhere in the codebase (confirmed via module structure listing). The dispatch call in `NotificationManageController.php:579` is commented out. Without this job, the manual notification dispatch pipeline has zero execution vehicle.

**ProcessSystemNotification listener:** Implements `ShouldQueue` with `tries=3`, `backoff=10`, `timeout=120` — good configuration. However, `handle()` calls `NotificationService::trigger()` without reinitializing tenancy context. When the Laravel queue worker processes this job, `tenancy()->tenant()` is null — all DB queries target the wrong database or fail.

**No artisan command:** `notifications:process-due` does not exist. Scheduled and recurring notifications cannot fire without a command that is registered with the Laravel scheduler.

---

### Layer 9 — Policies

**Single policy:** `Modules/Notification/app/Policies/PrimeNotificationPolicy.php`

Name is wrong (`PrimeNotificationPolicy` instead of `NotificationPolicy`) and prefix is `prime.notification.*` instead of `tenant.notification.*`. The entire policy file is misaligned with the tenancy model.

---

### Layer 10 — Seeders & Permissions

**Seeders present:** ChannelSeeder, ProviderSeeder, TargetGroupsSeeder, TemplatesSeeder, DatabaseSeeder. Seeders exist for configuration data.

**Permission seeding:** D39 platform pattern — no dedicated NTF permission seeder observed. If permissions with prefix `tenant.notification.*` are not seeded in `prime_db.permissions`, all Gate checks will fail even after the prefix is corrected.

---

### Layer 11 — Tenancy Isolation

**Cross-layer import inventory:**

| File | Import | Cross-DB risk |
|------|--------|--------------|
| NotificationManageController.php | `Modules\Prime\Models\Tenant` | P0: queries prime_db.tenants |
| TemplateController.php | `Modules\Prime\Models\Tenant` | P0: 3 call sites |
| ResolvedRecipientController.php | `Modules\Prime\Models\Tenant` | P0 |
| NotificationThreadController.php | `Modules\Prime\Models\Tenant` | P0 |
| UserPreferenceController.php | `Modules\Prime\Models\Tenant` | P0 |
| Notification.php (model) | `Modules\GlobalMaster\Models\Dropdown` | P1: relationships hit global_db |
| NotificationDeliveryLog.php | `Modules\GlobalMaster\Models\Dropdown` | P1: status() relationship |
| NotificationService.php | `Modules\GlobalMaster\Models\Dropdown` | P1: logDelivery() status lookup |

`Modules\Notification\Models\Notification.php` also imports `Modules\Prime\Models\Tenant` for the `tenant()` relationship — in a database-per-tenant architecture, querying the central tenants table to resolve the "owning tenant" within the tenant's own DB is architecturally redundant.

**TEN-NTF-001 (P0):** The `Tenant::all()` pattern exposes the full list of tenants (all schools) to any user who triggers the create/edit views for notifications, templates, resolved recipients, threads, or user preferences. This is a cross-tenant data leak.

---

### Layer 12 — Frontend / Views

~66 Blade views confirmed via module knowledge. Views exist for: channel master, provider master, templates (including approval workflow views), notifications (create/edit/index/show), target groups, delivery queue, resolved recipients, notification threads, schedule audit.

**Missing views:**
- Notification inbox (bell widget + inbox list) — REQ-NTF-030/031/032
- User preference self-service UI (routes exist but not confirmed functional due to Gate prefix bug)
- Device registration UI

**Functional concern:** Because ALL Gate checks use the wrong prefix, every authenticated page load that goes through `Gate::authorize()` will return 403 to tenant users — rendering the entire UI inaccessible despite views existing.

---

## Mode B — FRD Gap Analysis (42 REQs)

| REQ | Priority | Status | Evidence |
|-----|----------|--------|---------|
| REQ-NTF-001 | P0 | Partial | Controller + views exist; Gate prefix broken (BUG-NTF-003) |
| REQ-NTF-002 | P0 | Partial | updateStatus route active; Gate prefix wrong |
| REQ-NTF-003 | P0 | Partial/BROKEN | Controller exists; no `encrypted` cast on credentials (SEC-NTF-001, BR-NTF-011 violated) |
| REQ-NTF-004 | P1 | Not Started | No "Test Connection" action in routes or controller |
| REQ-NTF-005 | P0 | Not Started | No `dlt_sender_id` on provider; DLT sender enforcement not implemented |
| REQ-NTF-006 | P0 | Partial | TemplateController + views + routes active; Gate prefix broken |
| REQ-NTF-007 | P0 | Partial | Approve route exists; template status not checked at dispatch (BR-NTF-005 violated) |
| REQ-NTF-008 | P0 | Working | `NotificationTemplate::render()` confirmed functional |
| REQ-NTF-009 | P1 | Partial | Unique constraint migration added 2026-06-24; version selection at dispatch not verified |
| REQ-NTF-010 | P2 | Not Started | No language field in templates (acceptable for P2) |
| REQ-NTF-011 | P0 | Not Started | `dlt_template_id` column missing from `ntf_templates` (DDL-NTF-001) |
| REQ-NTF-012 | P0 | Partial | Controller exists; Gate broken; $request->field not ->validated() (BUG-NTF-004) |
| REQ-NTF-013 | P1 | Partial | Schema supports scheduled_at; no process-due command to fire it |
| REQ-NTF-014 | P1 | Partial | Schema supports recurring_expression; no process-due command |
| REQ-NTF-015 | P1 | Not Implemented | No 100-recipient check in create(); BR-NTF-009 not enforced |
| REQ-NTF-016 | P0 | Partial | updateStatus route exists; Gate broken |
| REQ-NTF-017 | P1 | Partial | Restore/forceDelete routes exist; Gate broken |
| REQ-NTF-018 | P0 | BROKEN | ProcessNotificationJob missing + dispatch commented out (BUG-NTF-005, ARCH-NTF-001) |
| REQ-NTF-019 | P0 | Not Implemented | RecipientResolutionService missing; opt-out not checked (BR-NTF-002) |
| REQ-NTF-020 | P1 | Not Implemented | Quiet hours schema exists; no enforcement in service (BR-NTF-003) |
| REQ-NTF-021 | P0 | Partial | sendEmail() active; delivery log INSERT fails (MIG-NTF-001/002) |
| REQ-NTF-022 | P0 | Not Started | SMS adapter is switch/default stub only |
| REQ-NTF-023 | P0 | Not Started | Push dispatch stubbed; FCM token exists; dispatch not implemented |
| REQ-NTF-024 | P1 | Not Started | WhatsApp not implemented |
| REQ-NTF-025 | P0 | Working | InAppSystemNotification active and functional |
| REQ-NTF-026 | P0 | BROKEN | Delivery log writes fail at runtime (NOT NULL constraint mismatch MIG-NTF-001/002) |
| REQ-NTF-027 | P1 | Partial | DeliveryQueueController + views; Gate broken |
| REQ-NTF-028 | P0 | Not Implemented | Rate limit columns exist; no enforcement code |
| REQ-NTF-029 | P0 | Partial | No destroy route confirmed for delivery logs; append-only model enforced by convention |
| REQ-NTF-030 | P0 | Not Started | No inbox views or API endpoints |
| REQ-NTF-031 | P0 | Not Started | No mark-read endpoint or view |
| REQ-NTF-032 | P1 | Not Started | No bell counter widget |
| REQ-NTF-033 | P1 | Partial | UserPreferenceController + schema; FormRequest authorize() = true; Gate broken |
| REQ-NTF-034 | P1 | Partial | Quiet hours schema exists; preference controller exists; not enforced at dispatch |
| REQ-NTF-035 | P1 | Partial | UserDevice model exists; no dedicated API endpoint for token registration |
| REQ-NTF-036 | P1 | Partial | NotificationThreadController + schema + routes active |
| REQ-NTF-037 | P1 | Partial | Thread management routes exist; Gate broken |
| REQ-NTF-038 | P1 | Partial | Broadcast thread type supported in schema |
| REQ-NTF-039 | P1 | Partial | NotificationThreadMemberController + routes; FormRequest authorize()=true |
| REQ-NTF-040 | P1 | Partial | ScheduleAuditController + views + routes all present |
| REQ-NTF-041 | P1 | Partial | Schema supports audit; no process-due command to create records |
| REQ-NTF-042 | P1 | Partial | Schedule audit view controller active; Gate broken |

**Summary:** 1 Working / ~22 Partial (most blocked by Gate prefix bug) / 11 Not Started / 3 Broken

---

## Mode C — Business Rules Enforcement (13 BRs)

| BR | Status | Finding | Severity |
|----|--------|---------|---------|
| BR-NTF-001 | VIOLATED | `Notification::scopeReadyToDispatch()` includes `DRAFT` in whereIn — DRAFT notifications can be queued (ORM-NTF-001) | P0 |
| BR-NTF-002 | NOT ENFORCED | `RecipientResolutionService` missing; `NotificationService::trigger()` does not check `UserPreference.is_opted_in` | P0 |
| BR-NTF-003 | NOT ENFORCED | No quiet hours check anywhere in the delivery pipeline | P1 |
| BR-NTF-004 | PARTIAL | `is_system` column exists in `ntf_templates`; enforcement in `TemplateController` not confirmed in this audit | P1 |
| BR-NTF-005 | NOT ENFORCED | `NotificationService::trigger()` selects template with `where('is_active', true)` only — does NOT check approval status; Draft/Pending templates can be dispatched | P0 |
| BR-NTF-006 | SATISFIED | `NotificationService::trigger()` returns silently (no exception) when no notification matches event code | — |
| BR-NTF-007 | NOT IMPLEMENTED | Rate limit columns (`rate_limit_per_minute`, `daily_cap`, `monthly_cap`) exist in schema; dispatch code does not check or enforce them | P1 |
| BR-NTF-008 | PARTIAL | No DELETE route confirmed for delivery logs; model has no guard preventing update; immutability by convention only | P1 |
| BR-NTF-009 | NOT IMPLEMENTED | No 100-recipient check in `NotificationManageController::store()`; bulk promotional notifications enter dispatch without approval | P1 |
| BR-NTF-010 | NOT IMPLEMENTED | DLT Template ID enforcement: `dlt_template_id` column missing from `ntf_templates`; SMS adapter is stub only | P0 |
| BR-NTF-011 | VIOLATED | `ProviderMaster.$casts` has no `encrypted` entry for `api_key_encrypted`/`api_secret_encrypted` — credentials stored plaintext | P0 |
| BR-NTF-012 | NOT IMPLEMENTED | No expiry check in `NotificationService` or in any dispatch path; `expires_at` exists in schema but is never read | P1 |
| BR-NTF-013 | PARTIAL | `ChannelMasterController::validateCircularFallback()` checks only direct self-reference (depth 1); BR requires depth-5 traversal | P1 |

**BR violations with P0 impact: 4 (BR-NTF-001, BR-NTF-002, BR-NTF-005, BR-NTF-011)**

---

## Mode G — Deploy Gate

| Gate | Result | Evidence |
|------|--------|---------|
| PHP syntax / parse | PASS | No parse errors in reviewed files |
| Module route registration | PASS | web.php fully populated; RSP wires routes |
| Tenancy middleware (web) | PASS | Full stack in RSP confirmed |
| Tenancy middleware (API) | WARN | API routes file has placeholder only; tenancy stack absent (no routes yet) |
| Migration integrity | CONDITIONAL | 19 migrations exist and are ordered; but NOT NULL mismatch in delivery_logs will cause runtime failures |
| Gate authorization | FAIL | All 12 controllers + 4 FormRequests use `prime.*` prefix → 100% of actions unauthorized for tenant users |
| PHP Fatal errors | FAIL | `canBeProcessed()` called on Notification model; method does not exist → Fatal on any process() call |
| Tests | FAIL | 0 tests (0 feature, 0 unit) |
| Critical missing class | FAIL | `ProcessNotificationJob` class does not exist; dispatch is commented out |
| Delivery log writes | FAIL | NOT NULL constraint mismatch means every delivery log INSERT fails at runtime |

**VERDICT: NO-GO** (5 hard failures; remediation required before any deployment)

---

## Mode D — Systemic Pattern Scorecard (NTF scope)

| Pattern | Baseline | NTF Exposure | Delta vs Baseline |
|---------|----------|-------------|-------------------|
| D25 (`$request->all()` mass-assign) | 24 sites platform | 2 sites (store/update in NotificationManageController) | Below baseline; contained |
| D29 ENUM in tenant migrations | ~476 platform | 15 ENUM columns across 10 of 15 tables | Proportionate to module size |
| D30 FormRequest authorize()=true | 437/485 (90%) | 6/11 (55%) | Below platform average (positive) |
| D24 Permission prefix chaos | ~50 sites | ALL 12 controllers + 4 FormRequests + 1 policy | Most severe instance in platform |
| D17 $fillable vs migration mismatch | 66 models | 0 confirmed (ProviderMaster `created_by` missing but not in $fillable) | Clean |
| D38 SoftDeletes vs DDL | Open | 1 instance: UserDevice (model has no SoftDeletes but table concept needs it) | 1 instance |
| D39 Permissions never seeded | Open | tenant.notification.* permissions not confirmed seeded | Likely pattern violation |
| Cross-layer model import (TEN) | — | 8 import sites (5 controllers + 3 models) | Above average severity |
| Jobs without tenancy re-init | Vendor/Inventory/Hostel | NTF listener (ProcessSystemNotification) | New instance |

**NTF is the most extreme case of D24 (permission prefix chaos) seen in the platform.** All other modules have partial prefix issues; NTF has 100% wrong prefix across every authorization primitive.

---

## Complete Finding Register

### P0 — Production Blockers

| Code | Type | Location | Description |
|------|------|----------|-------------|
| BUG-NTF-003 | Bug | All 12 controllers | ALL Gate::authorize() calls use `prime.*` prefix; correct is `tenant.*`; 100% of NTF actions unauthorized for tenant users |
| BUG-NTF-005 | Bug | NotificationManageController.php:579 | `ProcessNotificationJob::dispatch($notification)` commented out — notifications can never be triggered from UI |
| BUG-NTF-011 | Bug | Notification.php model | `canBeProcessed()` method does not exist; called at controller:556 → PHP Fatal on any process() request |
| ARCH-NTF-001 | Architecture | `Modules/Notification/app/Jobs/` | `ProcessNotificationJob` class does not exist — entire delivery pipeline has no execution vehicle |
| TEN-NTF-001 | Tenancy | 5 controllers (7 call sites) | `Tenant::all()`/`Tenant::get()` from `Modules\Prime\Models\Tenant` in tenant context — queries prime_db; cross-tenant data leak |
| SEC-NTF-001 | Security | ProviderMaster.php / ntf_provider_master | `api_key_encrypted` and `api_secret_encrypted` in `$fillable` with no `encrypted` cast → credentials stored as plaintext; BR-NTF-011 violated |
| MIG-NTF-001 | Migration | ntf_delivery_logs + NotificationService.php | `provider_id` NOT NULL in migration; `logDelivery(?int $providerId)` passes null for in-app delivery → every delivery log INSERT fails with errno 1048 |
| MIG-NTF-002 | Migration | ntf_delivery_logs + NotificationService.php | `resolved_user_id` NOT NULL in migration; `logDelivery()` passes `$payload['user_id'] ?? null` → INSERT fails when user_id absent |

### P1 — Fix Before Beta

| Code | Type | Location | Description |
|------|------|----------|-------------|
| BUG-NTF-004 | Bug | NotificationManageController.php:274,371 | `store()`/`update()` use `$request->tenant_id`, `$request->title` etc. (not `$request->validated()`) — FormRequest validation result bypassed |
| BUG-NTF-007 | Bug | NotificationManageController.php:228,337 | `create()` and `edit()` have no `Gate::authorize()` — any authenticated user can access these views |
| BUG-NTF-009 | Bug | Notification.php:92 | `getRouteKeyName()` returns `'notification_uuid'` but controllers use `findOrFail($id)` with integer → route model binding conflict |
| BUG-NTF-010 | Bug | Notification.php:154,178 | `resolvedRecipients()` and `logs()` relationships commented out |
| TEN-NTF-002 | Tenancy | Notification.php, NotificationDeliveryLog.php | `Modules\GlobalMaster\Models\Dropdown` imported for status/priority relationships → relationship queries hit global_db from tenant context |
| TEN-NTF-003 | Tenancy | NotificationService.php:204 | `Dropdown::query()` (GlobalMaster) for delivery status ID lookup in `logDelivery()` → cross-DB from service |
| VAL-NTF-001 | Validation | 6 FormRequests | `authorize()` returns bare `true` in NotificationTargetRequest, NotificationThreadMemberRequest, NotificationThreadRequest, ProviderMasterRequest, ScheduleAuditRequest, UserPreferenceRequest (D30 pattern) |
| VAL-NTF-002 | Validation | 4 FormRequests | NotificationRequest, DeliveryQueueRequest, TemplateRequest, ResolvedRecipientRequest use `prime.*` prefix in authorize() — same wrong-prefix bug as controllers |
| JOB-NTF-001 | Queue | ProcessSystemNotification.php | `ShouldQueue` listener calls `NotificationService::trigger()` without tenancy re-initialization; queued execution runs without tenant DB context |
| ARCH-NTF-002 | Architecture | `Modules/Notification/app/Services/` | `RecipientResolutionService` does not exist — CLASS/SECTION/GROUP targets cannot be expanded to individual recipients; opt-out enforcement impossible |
| ARCH-NTF-003 | Architecture | `resources/views/` | Notification inbox (bell widget + inbox list) absent — REQ-NTF-030/031/032 not started |
| ARCH-NTF-004 | Architecture | `Modules/Notification/app/Console/` | `notifications:process-due` artisan command does not exist — scheduled/recurring notifications cannot fire |

### P2 — Fix Before GA

| Code | Type | Location | Description |
|------|------|----------|-------------|
| ORM-NTF-001 | ORM | Notification.php | `scopeReadyToDispatch()` incorrectly includes `DRAFT` — only APPROVED/SCHEDULED should be queued; violates BR-NTF-001 |
| VAL-NTF-003 | Validation | NotificationRequest.php | `exists:tenants,id` validation rule targets prime_db.tenants from tenant context → cross-DB rule fails |
| PERF-NTF-001 | Performance | NotificationManageController::index() | God-method loading 8+ queries; refactor to tabbed AJAX (existing finding) |
| PERF-NTF-002 | Performance | NotificationManageController.php:428 | `Schema::hasColumn()` introspection in `destroy()` hot path — expensive on every delete |
| PERF-NTF-003 | Performance | NotificationManageController.php:230 | `NotificationTemplate::all()` unbounded query in create/edit |
| DDL-NTF-001 | DDL | ntf_templates migration | `dlt_template_id VARCHAR(50)` column missing — DLT compliance (BR-NTF-010, REQ-NTF-011) blocked |
| DDL-NTF-002 | DDL | ntf_user_devices migration | `deleted_at` missing from `ntf_user_devices` — stale device tokens cannot be soft-deleted |
| DDL-NTF-003 | DDL | ntf_user_devices, ntf_resolved_recipients | FK column references `sys_user` (singular); convention is `sys_users` (plural) |
| DAT-NTF-001 | DDL | 10 migrations | 15 ENUM columns across 10 of 15 tables violate D29 — values should be `sys_dropdown` FK |
| IMPL-NTF-001 | Implementation | NotificationService.php | SMS delivery is a `switch/default` stub — no adapter for MSG91/Twilio |
| IMPL-NTF-002 | Implementation | NotificationService.php | Push (FCM) delivery not implemented despite device token model existing |
| IMPL-NTF-003 | Implementation | NotificationService.php | WhatsApp delivery not implemented |
| IMPL-NTF-004 | Implementation | NotificationService.php:200 | `logDelivery()` early-returns if no `$resolvedRecipientId` — delivery log not written for many trigger paths |

### P3 — Clean Up

| Code | Type | Location | Description |
|------|------|----------|-------------|
| BUG-NTF-012 | Bug | ChannelMasterController.php:411 | Circular fallback validates self-reference only (depth 1); BR-NTF-013 requires depth-5 traversal |
| DEAD-NTF-001 | Code | Notification.php | `use Modules\Notification\Models\Template;` imported but appears unused (template() uses `NotificationTemplate::class`) |
| CODE-NTF-001 | Test | `tests/Feature/`, `tests/Unit/` | 0 tests exist for any NTF functionality |

---

## Health Score Calculation

| Layer | Weight | Score | Rationale |
|-------|--------|-------|-----------|
| Tenancy | 15 | 3 | 8 cross-DB import sites; Tenant::all() in 5 controllers; Dropdown queries from global_db |
| Authorization | 14 | 1 | 100% of Gate calls wrong prefix; 6/11 FormRequests bare true; 4/11 wrong prefix; policy misnamed |
| Data Integrity | 13 | 4 | Plaintext credentials; delivery_log NOT NULL mismatch; opt-out unenforced; BR-NTF-001 scope bug |
| Validation | 11 | 3 | 6 bare-true FormRequests; 4 wrong-prefix; $request->field not ->validated(); cross-DB exists: rule |
| Deployment | 10 | 5 | Web RSP correct; PHP Fatal on process(); 0 tests; canBeProcessed() missing |
| Migration | 9 | 5 | 19 migrations exist and ordered; delivery_log NOT NULL mismatch; D29 ENUMs |
| DDL | 7 | 4 | 15-table schema well-designed; missing dlt_template_id, deleted_at on user_devices; FK naming |
| Performance | 7 | 4 | God-method index; Schema::hasColumn() in hot path; Template::all() unbounded |
| Queue | 6 | 1 | ProcessNotificationJob missing; ShouldQueue listener no tenancy re-init |
| Code Quality | 4 | 2 | Structured code; commented-out critical paths; dead relationships; stale imports |
| ORM | 2 | 1 | scopeReadyToDispatch() includes DRAFT (wrong); cross-layer Dropdown relationships |
| Frontend | 2 | 1 | ~66 views exist; inbox/bell missing; Gate prefix blocks all UI access |

**Raw total: 3+1+4+3+5+5+4+4+1+2+1+1 = 34 / 100**

P0 cap: 40. Raw (34) < cap (40) → **Health Score: 34 / 100**

---

## GO / NO-GO Decision

**VERDICT: NO-GO**

Blocking conditions (must ALL be resolved before re-gate):

1. BUG-NTF-003 — Fix Gate prefix: global find-replace `prime.notification` → `tenant.notification`, `prime.channel-master` → `tenant.channel-master`, etc. in all 12 controllers + 4 FormRequests + 1 policy
2. BUG-NTF-011 + ARCH-NTF-001 — Add `canBeProcessed()` to Notification model AND create `ProcessNotificationJob` class
3. BUG-NTF-005 — Uncomment `ProcessNotificationJob::dispatch($notification)` at line 579
4. SEC-NTF-001 — Add `'api_key_encrypted' => 'encrypted', 'api_secret_encrypted' => 'encrypted'` to `ProviderMaster.$casts`
5. TEN-NTF-001 — Remove `Tenant::all()`/`Tenant::get()` from all 5 controllers (pass tenant context from auth if needed)
6. MIG-NTF-001 + MIG-NTF-002 — Fix `ntf_delivery_logs` to make `provider_id` and `resolved_user_id` nullable, OR ensure the service always provides these values
7. JOB-NTF-001 — Add tenancy re-initialization in `ProcessSystemNotification::handle()` before calling NotificationService

---

## Remediation Plan

### Sprint P0 (Must fix before any testing — ~3 days)

1. **Gate prefix fix** — Global search-replace in `Modules/Notification/app/Http/Controllers/`, `app/Http/Requests/`, `app/Policies/`. All `prime.*` → `tenant.*`
2. **Add `canBeProcessed()` to `Notification` model** — Check status is APPROVED or SCHEDULED; return boolean
3. **Create `ProcessNotificationJob`** — Implement `ShouldQueue`; re-initialize tenancy via `TenancyAwareJob` or explicit `tenancy()->initialize($tenant)` in `handle()`; call delivery pipeline
4. **Uncomment dispatch** — `ProcessNotificationJob::dispatch($notification)` at line 579
5. **Add `encrypted` casts** — `ProviderMaster.$casts`: `api_key_encrypted`, `api_secret_encrypted`
6. **Remove Tenant::all() calls** — Replace with `auth()->user()->tenant_id` or equivalent tenant-scoped approach in all 5 controllers
7. **Fix delivery_log NOT NULL** — Migration: make `provider_id` and `resolved_user_id` nullable in `ntf_delivery_logs`; OR update `logDelivery()` to guard against null and skip insert gracefully

### Sprint P1 (~5 days)

8. Replace `$request->field` with `$request->validated()` in store/update
9. Add `Gate::authorize()` to `create()` and `edit()` in NotificationManageController
10. Fix `getRouteKeyName()` conflict — controllers should use `findOrFail($id)` consistently
11. Uncomment `resolvedRecipients()` and `logs()` relationships in Notification model
12. Replace `Modules\GlobalMaster\Models\Dropdown` with tenant-scoped `sys_dropdown` lookup
13. Fix `ProcessSystemNotification` listener — add tenancy re-init in `handle()`
14. Fix 6 bare-true FormRequests — add appropriate `tenant.*` permission checks
15. Create `RecipientResolutionService` with opt-out check and quiet hours deferral
16. Create `notifications:process-due` artisan command
17. Enforce template approval status check in `NotificationService::trigger()`
18. Fix `scopeReadyToDispatch()` — remove DRAFT from whereIn (only APPROVED/SCHEDULED)
19. Seed `tenant.notification.*` permissions

### Sprint P2 (~5 days)

20. Add migration: `dlt_template_id` to `ntf_templates`, `deleted_at` to `ntf_user_devices`, fix FK naming
21. Implement SMS adapter (MSG91/Twilio)
22. Implement Push (FCM) adapter
23. Build notification inbox views (bell widget + inbox list)
24. Add rate limiting enforcement in delivery pipeline
25. Add bulk promotional approval check (>100 recipients)
26. Write P0 feature tests (minimum 14 test classes covering dispatch pipeline, auth, tenant isolation)

---

## Verified Good (No action needed)

- Web RSP tenancy middleware stack: InitializeTenancyByDomain + PreventAccessFromCentralDomains + EnsureTenantIsActive + auth + verified — correct
- `InAppSystemNotification` delivery path: fully functional end-to-end
- `sendEmail()` call: active (was previously commented out; now fixed)
- `ScheduleAuditController` and routes: both present and active (stale module-knowledge note corrected)
- `SystemNotificationTriggered` event + `ProcessSystemNotification` listener: correct event-driven wiring (ShouldQueue correctly configured)
- `ntf_channel_master` unique constraint: migration added 2026-06-24 ✓
- `sys_dropdowns` FK in tenant tables: confirmed tenant table (D-MSH-009) — no cross-DB FK ✓
- Template render `{{key}}` and `{{ key }}` forms: both supported by `NotificationTemplate::render()`
- Worker locking in `ntf_delivery_queue` (`locked_by`/`locked_at`): schema supports horizontal scaling ✓
- `ntf_delivery_logs` append-only intent: no delete route confirmed ✓

---

*Report end.*
