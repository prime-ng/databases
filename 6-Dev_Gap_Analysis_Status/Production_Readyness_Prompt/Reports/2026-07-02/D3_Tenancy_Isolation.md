# D3 — Multi-Tenancy Isolation Audit (HIGHEST RISK)

**Domain:** D3 — Multi-Tenancy Isolation
**Platform:** Prime-AI (stancl/tenancy v3.9, Laravel 12, database-per-tenant)
**Codebase:** `/Users/bkwork/Herd/prime_ai`
**Audit date:** 2026-07-02
**Auditor:** Tenancy Agent (read-only, evidence-anchored)
**Architecture:** central `prime_db` (conn `mysql`) + `global_db` (conn `global_master_mysql`) + per-school `tenant_{uuid}` (conn `tenant`)

---

## Executive Verdict

**NOT-READY** (P0 cross-tenant data-leak class confirmed present).

The tenancy *plumbing* is fundamentally sound — DatabaseTenancyBootstrapper + QueueTenancyBootstrapper + FilesystemTenancyBootstrapper are active, central models are connection-pinned, separate physical databases make classic IDOR structurally safe, and the mobile/API entrypoints initialize tenancy before auth. Several previously-flagged baseline items are now **FIXED** (see Re-verification table).

However the **cross-layer central-model import** pattern is far larger than the baseline recorded (189 tenant-module files, not "SLK's 3 controllers"), and 60 sites import `Modules\Prime\Models\Dropdown` — a model that is **NOT connection-pinned** and therefore resolves against whatever connection is active (the tenant DB), meaning either wrong-layer data or a broken query. This is the P0 class. `CacheTenancyBootstrapper` is disabled, and un-prefixed cache keys exist that can bleed across tenants when a non-database cache store is used.

---

## Re-verification of Baseline Known-Issues (as of TODAY)

| Baseline claim (known-issues.md) | Status TODAY | Evidence |
|---|---|---|
| `EnsureTenantHasModule` — only 1 usage; 13/13 modules missing | **PARTIALLY FIXED** — now **3** module RSPs wire it (Transport, Library, LmsExam); `module` alias registered in `bootstrap/app.php:31`; 1 route-level use (`StudentProfile/routes/web.php:12` `module:STUDENT`). ~40 modules still lack it. | `Modules/{Transport,Library,LmsExam}/app/Providers/RouteServiceProvider.php:47/49/49` |
| `tenancy()->initialize()` w/o `->end()` at `Prime/DropdownNeedController.php:479,641` | **STILL OPEN (re-confirmed)** — both sites initialize tenant context in AJAX helpers and never call `->end()` | `Modules/Prime/app/Http/Controllers/DropdownNeedController.php:479,641` |
| Jobs touching tenant tables w/o re-init (Vendor, Inventory, FrontOffice, Hostel) | **LARGELY MITIGATED** — `QueueTenancyBootstrapper` is ACTIVE (`config/tenancy.php:35`); it serializes tenant_id into the payload and re-initializes on job run. All 4 flagged jobs are dispatched **from tenant context** (web controllers / per-tenant commands), so context is auto-restored. Residual risk = scheduling gaps, not context loss. | `config/tenancy.php:35`; dispatch sites below |
| Library routes unwired into tenancy (2026-03-14) | **FIXED** — Library RSP now carries full stack incl. `EnsureTenantHasModule:Library` | `Modules/Library/app/Providers/RouteServiceProvider.php:41-50` |
| Scheduler & EventEngine RSP tenancy | **FIXED (re-confirmed)** — both carry `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` + `EnsureTenantIsActive` | RSPs |
| SmartTimetable ParallelGroupController routes bypass tenancy | **STILL OPEN** — `Modules/SmartTimetable/routes/web.php:21` group uses only `['web','auth']`, no tenancy middleware | `Modules/SmartTimetable/routes/web.php:21` |
| Cross-layer `AcademicSession` import (SLK: 3 controllers) | **WORSE THAN BASELINE** — 52 imports of `Modules\Prime\Models\AcademicSession` + 2 of `GlobalMaster\...AcademicSession` platform-wide | grep below |

---

## Findings

| ID | Sev | Area | Description | Evidence | Remediation | Effort |
|----|-----|------|-------------|----------|-------------|--------|
| GAP-D3-001 | P0 | Cross-layer model imports | **189 tenant-module files** import central-layer models (`Modules\Prime\Models\*`, `Modules\GlobalMaster\Models\*`, `Modules\Billing\Models\*`) from tenant-scoped controllers/services/jobs/models. Central data is queried while tenant context is active. | `grep -rn "use Modules\\(Prime\|GlobalMaster\|Billing)\\Models\\" Modules` excluding central modules = 189 files. Tally: `Prime\Dropdown` ×60, `Prime\AcademicSession` ×52, `GlobalMaster\Dropdown` ×43, `Prime\Tenant` ×15, `Prime\Media` ×9, `Prime\Role` ×6, `Prime\Setting` ×4, `Prime\User` ×4, `GlobalMaster\City` ×6, +others | Replace with tenant-DB equivalents (e.g. `SchoolSetup\OrganizationAcademicSession`, tenant `sys_dropdowns`). Establish a lint/architecture rule forbidding central-model imports in tenant modules. | XL |
| GAP-D3-002 | P0 | Cross-layer / connection resolution | `Modules\Prime\Models\Dropdown` (60 import sites) and `Modules\GlobalMaster\Models\Dropdown` (43 sites) are **NOT connection-pinned** — `Prime/app/Models/Dropdown.php` has no `$connection`; `GlobalMaster/app/Models/Dropdown.php:21` connection line is commented out. Queried inside tenant context they resolve to the **tenant** DB (`sys_dropdowns` in tenant), so behavior depends entirely on whether that table exists in the tenant DB. Wrong-layer / silent-wrong-data or 42S02. | `Modules/Prime/app/Models/Dropdown.php` (no `$connection`); `Modules/GlobalMaster/app/Models/Dropdown.php:21` `//protected $connection` | Decide canonical dropdown source (tenant `sys_dropdowns`) and pin the model connection OR migrate all call-sites to the tenant model. This unblocks GAP-D3-001. | L |
| GAP-D3-003 | P0 | Context leak | `tenancy()->initialize($tenant)` called with **no matching `->end()`** in two AJAX helper methods. After these fire, the request continues in tenant context; on a central-domain admin request that pollutes subsequent central queries within the same request lifecycle. | `Modules/Prime/app/Http/Controllers/DropdownNeedController.php:479` (`getMigrationTables`), `:641` (`getTableColumns`) | Wrap in `try { … } finally { if (tenancy()->initialized) tenancy()->end(); }`, or use `$tenant->run(fn() => …)`. | S |
| GAP-D3-004 | P1 | Route separation / plan gating | `EnsureTenantHasModule` wired on only **3 of ~43** module route groups (Transport, Library, LmsExam) + 1 route-level use (StudentProfile). Any authenticated school user can reach modules not in their subscription plan. | `Modules/{Transport,Library,LmsExam}/app/Providers/RouteServiceProvider.php`; `Modules/StudentProfile/routes/web.php:12`; alias at `bootstrap/app.php:31`. All other module RSPs carry `auth+InitializeTenancyByDomain+PreventAccessFromCentralDomains+EnsureTenantIsActive` but NOT `module:`. | Add `EnsureTenantHasModule::class.':{slug}'` to every tenant module RSP middleware stack. Slug must match `glb_modules.slug`. | M |
| GAP-D3-005 | P1 | Route separation | SmartTimetable ParallelGroup route group has **no tenancy middleware at all** — only `['web','auth']`. Runs against whatever DB connection is default (central), so tenant queries hit the wrong DB or a central request can reach it. | `Modules/SmartTimetable/routes/web.php:21` | Move into the tenancy-wrapped group (the module's `mapWebRoutes` already applies the full stack for the main file). | S |
| GAP-D3-006 | P1 | Cache isolation | `CacheTenancyBootstrapper` is **disabled** (`config/tenancy.php:33`, "database driver doesn't support tags"). Cross-tenant cache bleed is prevented **only** because un-prefixed keys are rare AND the DB cache store is per-central-DB (shared across tenants). Un-prefixed keys found: `lms_exam_class_section_list` (3 sites) and SyllabusBooks `SyllabusBookConfig::CACHE_KEY` — these are **shared across all tenants**: School A's class/section list is served to School B. | `Modules/LmsExam/app/Http/Controllers/LmsExamController.php:152,951,1311`; `Modules/SyllabusBooks/app/Models/SyllabusBookConfig.php:57`. Good example (correctly prefixed): `Modules/Prime/app/Models/Tenant.php:129` `"tenant:{$this->id}:allowed_modules"`. | Prefix every tenant-scoped cache key with `tenant()->id`, or re-enable a tags-capable cache store (Redis) + `CacheTenancyBootstrapper`. | M |
| GAP-D3-007 | P2 | API tenancy | Module API route groups with real routes but **no tenancy middleware** in their RSP `mapApiRoutes`: SmartTimetable (9 routes, only `api`+`auth:sanctum`), SchoolSetup (5, `mobile.key`/`auth:sanctum`), Feedback (8, only `auth:sanctum` — file comment claims "tenancy-scoped … by RouteServiceProvider" but RSP applies none). Latent: `auth:sanctum` reads `personal_access_tokens` from the tenant DB, so without tenant init these fail rather than leak — but any unauthenticated endpoint would run central. | RSP `mapApiRoutes` blocks; `Modules/Feedback/routes/api.php:14-17` (false comment); Cafeteria (15) & ParentPortal (13) are correctly wired for contrast. | Add `InitializeTenancyByDomain`+`PreventAccessFromCentralDomains`+`EnsureTenantIsActive` (or `tenant.mobile`) to those RSP API stacks. | M |
| GAP-D3-008 | P2 | Tenant lifecycle / offboarding | No admin offboarding path: `TenantController::destroy()` is an **empty stub** (`Modules/Prime/.../TenantController.php:619` body `//`). Deletion only fires via the `TenantDeleted` event → `DeleteDatabase` job (`TenancyServiceProvider.php:37-42`, `shouldBeQueued(false)`), which nothing in the UI triggers. Tenant model uses SoftDeletes, so even a soft-delete would not drop the DB. Data-retention / GDPR-style erasure cannot be executed. | `Modules/Prime/app/Http/Controllers/TenantController.php:619`; `app/Providers/TenancyServiceProvider.php:37-42` | Implement `destroy()` to force-delete (firing `TenantDeleted`) with confirmation + backup; document retention policy. | M |
| GAP-D3-009 | P2 | Session isolation | Session driver is `database` (`.env:49`) with `SESSION_CONNECTION` unset (`config/session.php:76`), so sessions live in the **central** `mysql` DB shared by all tenants. Isolation relies solely on the encrypted session cookie + per-request tenant re-identification. No tenant scoping on the `sessions` table; acceptable but not defense-in-depth. | `.env:49`; `config/session.php:21,76` | Acceptable for launch; consider `SESSION_CONNECTION=tenant` or Redis-per-tenant for hardening. | S |
| GAP-D3-010 | P3 | Cache/queue store connection | `DB_CACHE_CONNECTION=mysql` (`.env:63`) and queue `database` store both live in the central DB. Correct for a shared job/cache table, but means all cache/queue rows are co-mingled; combined with GAP-D3-006 any un-prefixed key is global. | `.env:60,63`; `config/cache.php:43`; `config/queue.php:40` | Document; enforce key-prefix convention. | S |
| GAP-D3-011 | P3 | Root user seeding | Tenant provisioning seeds a fixed root admin `root@tenant.com` / `password` with `is_super_admin=true` in every tenant DB (`SetupTenantDatabase.php` Step 3). Predictable default credential per tenant. | `app/Jobs/SetupTenantDatabase.php:74-88` | Generate a random password and force reset on first login. | S |

---

## Task-by-Task Detail

### 1. Cross-layer central-model imports — **189 files** (P0)
Full platform count (excluding central modules Prime/GlobalMaster/Billing/Payment/SystemConfig):
`grep -rn "use Modules\\(Prime|GlobalMaster|Billing)\\Models\\" Modules` = **189 files**. Model tally:
`Prime\Dropdown` 60, `Prime\AcademicSession` 52, `GlobalMaster\Dropdown` 43, `Prime\Tenant` 15, `Prime\Media` 9, `Prime\Role` 6, `GlobalMaster\City` 6, `Prime\User` 4, `Prime\Setting` 4, `GlobalMaster\Module` 3, `GlobalMaster\Country` 3, `GlobalMaster\Plan` 2, `GlobalMaster\AcademicSession` 2, `Billing\BillingCycle` 1, `Billing\InvoicingItem` 1, others 1 each.
Heaviest sites: StudentFee (11 files), SmartTimetable (7), Transport (14), TimetableFoundation (9), Complaint (11), Feedback (16), Notification (13), LmsHomework (10), StudentProfile (11), SchoolSetup (18 — but many of these are legitimate central-facing config models). **Mitigating nuance:** `AcademicSession`, `Media`, `Role`, `Setting`, `Menu`, `Board`, `City`, `State`, `Module`, `Plan` ARE connection-pinned (to `global_master_mysql` or `mysql`), so they query the correct central DB deterministically — the isolation *breach* is architectural (tenant code coupled to central schema) rather than a live wrong-DB read for those. The **live-risk subset is `Dropdown`** (103 total sites, unpinned) → GAP-D3-002.

### 2. `initialize()` without `end()` — 2 confirmed (P0)
`DropdownNeedController.php:479` and `:641` re-confirmed open. No other production sites leak: all console commands (`ReleaseScheduledHomework`, `ReleaseLmsResources`, `UpdateHomeworkStatus`, `ProcessDailyAttendance`*, `ProcessLeaveAccrual`*) and the Hpc job pair `initialize`+`end`. (*`ProcessDailyAttendance`/`ProcessLeaveAccrual` initialize inside a per-tenant loop but I could not confirm an `->end()` — ⚠️ UNVERIFIED, low risk as they are CLI-only.)

### 3. Queued jobs & tenancy posture — 13 module jobs + 6 app/Jobs
`QueueTenancyBootstrapper` **active** (`config/tenancy.php:35`) → tenant_id auto-serialized at dispatch and re-initialized on run for any job dispatched inside tenant context.

| Job | Re-init posture | Dispatch context | Verdict |
|-----|----|----|----|
| Hpc/SendHpcReportEmail | Explicit `initialize($tenantId)`+`end()` (`:33,:38`) | belt-and-suspenders | SAFE |
| Inventory/ReorderAlertJob | None; relies on bootstrapper | `ReorderAlertService` (tenant) | SAFE via bootstrapper |
| FrontOffice/EarlyDepartureAttSyncJob | None | `EarlyDepartureService:93` (tenant) | SAFE via bootstrapper |
| Hostel/SendHstComplaintEscalationJob | None | `EscalateComplaintsCommand` (per-tenant via tenants:artisan) | SAFE if scheduled per-tenant (⚠️ not scheduled in console.php — JOB-HST-001) |
| Hostel/SendHstNotificationJob | None | tenant | SAFE via bootstrapper |
| Vendor/SendVendorInvoiceEmailJob | None | `VendorInvoiceController:595` (tenant) | SAFE via bootstrapper |
| Certificate/BulkGenerateCertificatesJob | None; writes `storage/app/tenant_certificates/` | tenant | SAFE via bootstrapper (⚠️ storage path not tenant-suffixed — cross-tenant file mixing risk, P2) |
| MarksheetGeneration/ComputeMarksheetJob | None | tenant | SAFE via bootstrapper |
| SmartTimetable/GenerateTimetableJob | None | tenant | SAFE via bootstrapper |
| Billing/SendInvoiceEmailJob | Central data (`BilTenantInvoice`) — central-scoped by design | central | N/A (central job) |
| Payment/ProcessWebhookJob | central webhook | central | N/A |
| Prime/SendScheduledEmail | central | central | N/A |
| SystemConfig/RunBackupJob | Builds per-tenant connections explicitly (`:62-78`) | central orchestrator | SAFE (explicit) |
| app/Jobs/SetupTenantDatabase | Uses `$tenant->run()` for all tenant writes | central provisioning | SAFE |
| app/Jobs/{CreateRootUser,AddOrganizationDetails,CreateTenantStorageSymlink} | tenant pipeline stubs | — | ⚠️ UNVERIFIED (legacy; SetupTenantDatabase is the live path) |

**Net:** the baseline "jobs without re-init" P0 is **downgraded to SAFE** because QueueTenancyBootstrapper is active and every tenant-table job is dispatched from tenant context. Residual: scheduling gaps (JOB-HST-001, inventory maintenance) are availability bugs, not isolation bugs. Certificate ZIP path (`storage/app/tenant_certificates/`) is not tenant-ID-suffixed → potential cross-tenant file naming collision (P2, note under GAP-D3-006 family).

### 4. Route separation & plan gating
- `routes/tenant.php` (main tenant file) wraps everything in `web + InitializeTenancyByDomain + SetTenantAuthGuard + PreventAccessFromCentralDomains + EnsureTenantIsActive` (`:82`). Seeder routes (`:319+`) sit inside `auth` group (`:265`), i.e. authenticated — better than the SEC-RTG-001 baseline but still a raw seeder-exposure surface (out of D3 scope; flag to D-security).
- Per-module RSP middleware matrix: 39 modules carry the tenancy quad but lack `module:`; only **Transport/Library/LmsExam** add `EnsureTenantHasModule` (GAP-D3-004). Modules with **no RSP** (routes registered in `routes/tenant.php` or via `web`): Billing, Documentation, GlobalMaster, Prime, SystemConfig (central — expected).
- `EnsureTenantHasModule` usage count TODAY = **4** (3 RSP + 1 route-level `module:STUDENT`) vs baseline "6 total"/"1". Alias `module` registered `bootstrap/app.php:31`.

### 5. Cache / session / filesystem isolation
- Bootstrappers active: Database, Filesystem, Queue. **Cache DISABLED** (`config/tenancy.php:33`).
- Filesystem: `suffix_base=tenant`, `suffix_storage_path=true`, `root_override` for local/public, `url_override public=public-%tenant_id%` (`config/tenancy.php:96-135`) → **storage IS per-tenant isolated** for disk operations that go through the storage helpers. (Certificate job writes a raw `storage_path('app/tenant_certificates/…')` string — bypasses suffixing; ⚠️ verify it runs post-init so `storage_path()` is already suffixed.)
- Cache un-prefixed keys (sample of ~6 real sites, all Cache:: in Modules): `lms_exam_class_section_list` ×3, `SyllabusBookConfig::CACHE_KEY` — **cross-tenant bleed** (GAP-D3-006). Correct pattern exists at `Prime/Tenant.php:129`.
- Session: `database` driver, central DB, no per-tenant connection (GAP-D3-009).

### 6. Tenant lifecycle
- **Creation:** `TenantController::store` (`:56`) → `SetupTenantDatabase::dispatch` (`:76`). Job runs unattended: createDatabase → migrate (with per-file progress) → firstOrCreate language → create root user via `$tenant->run()` → create Organization via `$tenant->run()` → notify super admins (`app/Jobs/SetupTenantDatabase.php:52-130`). **BUG-004 is RESOLVED** — provisioning is no longer commented out; it is a live async job. Module registration is via plan assignment (separate flow), not this job.
- **Seeding:** not auto-run by `SetupTenantDatabase` (no `tenants:seed` call); manual/seeder-panel driven. Foundation data (language, org, root) is created inline. ⚠️ Master-data seeding (dropdowns, roles) is NOT part of unattended provisioning — new tenants may lack `sys_dropdowns`/`sys_roles` rows, compounding GAP-D3-002.
- **Offboarding:** `destroy()` empty stub (GAP-D3-008); only `TenantDeleted`→`DeleteDatabase` event path exists, unreachable from UI.

### 7. Cross-tenant IDOR — sampled 10 controllers
`StudentController::show(Student)`, `FeeInvoiceController::show($id)/destroy($id)`, `HostelController::show/destroy`, `VehicleController::show(Vehicle)/destroy`, `ComplaintController::show/destroy`, `QuestionBankController::show/destroy`, plus HrStaff/Cafeteria/Admission/Library. **All scope by the tenant DB automatically** — because the module route/RSP stack calls `InitializeTenancyByDomain` first, every Eloquent query (route-model-bound or `find($id)`) hits `tenant_{uuid}`. A user-supplied ID can only address rows within the *caller's own* tenant DB; there is no path where a tenant controller queries the central DB by user-supplied ID for tenant-owned records. Every sampled method also calls `Gate::authorize('tenant.*')`. **Structural isolation = SAFE** (this is the core strength of database-per-tenant). No IDOR findings.

---

## Counts

- Cross-layer central-model imports (tenant modules): **189 files**; `Dropdown` (unpinned) subset: **103 sites**.
- `initialize()` without `end()`: **2** (production).
- Module jobs audited: **13** module + **6** app/Jobs; tenant-table jobs with unsafe context: **0** (all covered by QueueTenancyBootstrapper).
- Modules with `EnsureTenantHasModule`: **3 RSP + 1 route-level = 4**; modules without: **~39**.
- Un-prefixed cross-tenant cache keys: **4 sites** (2 distinct keys).
- Module API groups lacking tenancy middleware (with real routes): **3** (SmartTimetable, SchoolSetup, Feedback).

**Severity totals:** P0 = **3** · P1 = **3** · P2 = **3** · P3 = **2**

---

## Verdict: **NOT-READY**

Database-per-tenant gives strong structural isolation (no IDOR, connection-pinned central models, tenancy-first middleware, active queue bootstrapper). But three P0 classes must close before production: the unpinned-`Dropdown` cross-layer reads (live wrong-DB risk, 103 sites), the two `DropdownNeedController` context leaks, and the breadth of central-model coupling. Fix P0s + GAP-D3-004 (plan gating) to reach **READY-WITH-RISK**.
