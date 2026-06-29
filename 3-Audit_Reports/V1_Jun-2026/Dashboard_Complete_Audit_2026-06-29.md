## Complete Audit — Dashboard (DSH) — 2026-06-29      (Mode X: A+B+C+G + scoped D)

**Module:** Dashboard · **Code:** DSH · **Prefix:** `dsh_` (zero own tables — pure read-aggregation)
**App dir:** `/Users/bkwork/Herd/prime_ai/Modules/Dashboard`
**Baseline (B/C):** `4-Requirement_Module_wise/0-FRD_Documents/DSH_FRD_Complete_2026-06-29.md` (REQ/BR/RPT IDs reused, not renumbered)
**Auditor:** Technical Auditor (read-only). Live code is authoritative; module-knowledge used as hint and corrected below.

---

### Executive Summary
Dashboard is the platform's only schema-less module: 0 tables, 0 migrations, 0 models, 0 jobs, 0 FormRequests, 0 tests — 26 controllers that read-aggregate ~80 source tables across 3 DB layers and render 25 dashboards. The worst finding is an **authorization layer that fails the very feature it guards**: 4 of the 7 role dashboards check Spatie roles that no seeder ever creates (`Accounts`/`Transport`/`Management`/`SuperAdmin`), so they 403 to *everyone* (including the real platform operator), and the 15 area hubs gate on `tenant.dashboard.viewAny`, a permission no seeder defines, so they are inaccessible to all non-super-admin staff. There is **no P0** (read-only, fails closed, no cross-tenant leak, no write/data-corruption path, no deploy-blocker migration), so health is **uncapped at ~65/100 (Amber)**. **Deploy verdict: GO for platform deploy / NO-GO for "dashboard feature ready"** — most dashboards are functionally unreachable by their intended audience until the access defects are fixed.

### Health Score
Weighted index = **65.5 / 100 (Amber)**. No P0 → no cap applied.
Dominant drags: Layer 5 Authorization (Red, weight 14) and Layer 9 Performance (Red, weight 7). Tenancy (L6) and Validation (L7) are Green by virtue of the read-only design.

### Deploy Gate Verdict (Mode G)
**GO (platform) — but the Dashboard feature is NOT release-ready.**
- No P0, no committed secret in this module, no cross-tenant path, no module migration (nothing to break `tenants:migrate`).
- Blocking items for *feature* readiness (not platform deploy): **BUG-DSH-007** (4 role dashboards permanently 403) and **SEC-DSH-009** (15 hubs inaccessible — permission unseeded). Until these are fixed, ~19 of 25 dashboards do not render for normal staff.
- Layer 6/8/10/12 gates: tenancy reads are connection-scoped and safe; no jobs; no secrets; no route closures in this module; api routes are read-only behind `auth:sanctum` + tenancy.

---

### P0 Findings
**None.** Read-only module: fails closed on authorization, performs no writes, leaks no cross-tenant data, ships no migration, embeds no production secret.

---

### P1 Findings

```
[BUG-DSH-007] Severity: P1 | Role-name drift — 4 of 7 role dashboards gate on Spatie roles that no seeder creates (permanent 403)
- Location:
    Modules/Dashboard/app/Http/Controllers/Accounts/AccountsDashboardController.php:16     abort_unless(...hasRole('Accounts'),403)
    Modules/Dashboard/app/Http/Controllers/Transport/TransportDashboardController.php:16    abort_unless(...hasRole('Transport'),403)
    Modules/Dashboard/app/Http/Controllers/Management/ManagementDashboardController.php:17   abort_unless(...hasRole('Management'),403)
    Modules/Dashboard/app/Http/Controllers/SuperAdmin/SuperAdminDashboardController.php:16   abort_unless(...hasRole('SuperAdmin'),403)
- Evidence: canonical tenant roles seeded by database/seeders/TenantRolePermissionSeeder.php:20-74 are exactly:
    Super Admin, School Admin, Principal, Vice Principal, Teacher, Staff, Accountant, Librarian, Parent, Student.
    'Accounts' (seeded role is 'Accountant'), 'Transport', 'Management', 'SuperAdmin' (seeded role is 'Super Admin' WITH a space)
    are NOT seeded as Spatie roles anywhere (grep Role::create/firstOrCreate across database/ + Modules/*/database/ = 0 hits).
- Why it's a risk: hasRole() against a non-existent role always returns false → these 4 dashboards 403 for every user. The
    Gate::before super-admin bypass (app/Providers/AppServiceProvider.php:65-73) does NOT help: abort_unless(hasRole()) is a direct
    role check, not a Gate ability, so even a real 'Super Admin' user is 403'd off /dashboard/superadmin. Feature is dead on arrival.
- Fix: align the strings to the seeded role names — 'Accounts' → 'Accountant'; 'SuperAdmin' → 'Super Admin'; seed (or pick existing)
    roles for the Transport/Management dashboards, or gate them on a permission instead of a bespoke role.
- Confidence: High
- Systemic? : module-local (a role-name-vs-gate drift class; sibling to D24 permission-prefix chaos)
```

```
[SEC-DSH-008] Severity: P1 | Foundational-Setup detail pages have NO authorization — confidential billing/plan/invoice data readable by any authenticated staff user
- Location: Modules/Dashboard/app/Http/Controllers/FoundationalSetup/FoundationalSetupDashboardController.php
    index():18      -> Gate::authorize('tenant.dashboard.viewAny');   (gated)
    schoolProfile():56  -> NO Gate/authorize        (reads sch_organizations, glb_cities, prm_tenant, prm_plans, plan/trial/auto_renew)
    sessionBoard():109  -> NO Gate/authorize         (reads glb_academic_sessions, glb_boards, sch_*_jnt)
    billing():164       -> NO Gate/authorize         (reads prm_tenant, prm_plans, prm_billing_cycles, bil_tenant_invoices, billing schedules)
- Evidence: only index() carries Gate::authorize(); the three sub-page actions routed at routes/web.php:43-48 carry none, behind only
    auth+verified. FRD marks Billing/Subscription data 'Confidential' (Section 5.1; RPT-DSH-007; BR-DSH-017/018/019).
- Why it's a risk: any authenticated, email-verified user on the tenant domain — regardless of dashboard permission or role — can open
    /dashboard/foundational-setup/{school-profile,session-board,billing} and read the school's plan, trial flag, invoices and next bill.
    Broken access control on confidential financial data (within-tenant over-exposure). Not cross-tenant (queries are tenant()-scoped),
    hence P1 not P0.
- Fix: add Gate::authorize('tenant.dashboard.viewAny') (or a billing-specific permission) at the top of schoolProfile(), sessionBoard(), billing().
- Confidence: High
- Systemic? : module-local
```

```
[SEC-DSH-009] Severity: P1 | 'tenant.dashboard.viewAny' permission is never seeded → all 15 area hubs inaccessible to non-super-admin staff
- Location: referenced by 16 hub controllers (e.g. Finance/FinanceDashboardController.php:17, Lms/LmsDashboardController.php:17,
    FoundationalSetup/...:18). Defined/seeded by: NONE.
- Evidence: grep 'dashboard.viewAny' / 'tenant.dashboard' across database/, Modules/*/database/, app/ = 0 seeding hits (only the
    controller call-sites). config/permission.php:104 'register_permission_check_method' => true (Spatie registers a Gate::before that
    resolves abilities to permissions). AppServiceProvider.php:65-73 bypasses only when is_super_admin && super_admin_flag, or role
    'Super Admin'.
- Why it's a risk: for any non-super-admin (School Admin, Principal, Accountant, etc.) the ability resolves to a permission that does not
    exist → access denied (clean 403, or PermissionDoesNotExist→500 depending on Spatie path). The hub feature — explicitly meant for
    'all staff roles' / 'any holder of the view-dashboards permission' (FRD REQ-DSH-002/009) — is unusable by its intended audience.
- Fix: seed permission 'tenant.dashboard.viewAny' (guard web) in TenantRolePermissionSeeder and grant it to School Admin / staff roles;
    confirm the Gate::before resolution path. (Tracks RISK-DSH-001, REQ-DSH-009, Sprint task #1.)
- Confidence: High
- Systemic? : sibling to the "Gate string with no matching seeder" trap noted in module-knowledge Lessons.
```

---

### P2 Findings

```
[DATA-DSH-001] Severity: P2 | Resilient reads swallow all exceptions with zero logging — broken/renamed source tables degrade to 0 silently and indefinitely
- Location: Modules/Dashboard/app/Http/Controllers/BaseDashboardController.php:31-33 (safeCount catch), :50-52 (safeSum catch);
    plus ~every inline try/catch in FoundationalSetupDashboardController (e.g. :36, :46, :61, :70, :88, :98) and across sub-controllers.
- Evidence:  } catch (\Exception $e) { return 0; }   — no Log::*, no rethrow, no telemetry.
- Why it's a risk: REQ-DSH-008/BR-DSH-004 intentionally degrade a failed source to 0 (good resilience), but with NO logging a renamed or
    dropped source table shows a believable 0 forever with no alert — stakeholders read fabricated zeros as fact (RISK-DSH-004). The
    129 safeCount/safeSum call-sites all share this blind spot.
- Fix: Log::warning() the caught exception (table + message) before returning 0 (ENH-DSH-004); optionally emit a metric.
- Confidence: High
- Systemic? : module-local (intersects platform's silent-catch habit)
```

```
[DATA-DSH-002] Severity: P2 | No academic-session/year scoping on any aggregation → cross-session over-counting on multi-year tenants
- Location: DashboardController.php:31-55 (loadStats — std_students, lms_exams/quizzes/quests/homeworks, hpc_reports, etc.) and every
    hub controller's counts.
- Evidence: safeCount('std_students'), safeCount('lms_exams',['is_active'=>1]) — no academic_session_id / year filter anywhere.
- Why it's a risk: in a K-12 platform where almost all data is session-scoped, tenant-wide counts accumulate across historical sessions,
    so "Total Students", LMS counts and KPIs over-report for any tenant past its first year (RISK-DSH-003, ENH-DSH-003).
- Fix: introduce a current-session filter (resolve current session once, apply to session-scoped counts). Confirm intended behaviour first.
- Confidence: High
- Systemic? : module-local
```

> **PERF (no new code — already registered):** `BaseDashboardController::safeCount/safeSum` call `Schema::getColumnListing($table)` on
> every invocation (BaseDashboardController.php:27,46), firing an `information_schema` introspection query per tile per load, per tenant,
> uncached — across **129 call-sites**. This is already **PERF-DSH-001 / PERF-DSH-005** in known-issues; **confirmed still present**, no
> new code assigned. Fix: cache the column list per (connection,table) for the request, or pass a `hasSoftDeletes` flag from the caller.

> **BUG (no new code — already registered):** `routes/api.php:7` `apiResource('dashboards', DashboardController::class)` registers 7 REST
> routes but `DashboardController` implements only `index()` → store/show/update/destroy throw `BadMethodCallException` (500). Already
> **BUG-DSH-006**; confirmed. (REQ-DSH-012 scaffold; ENH-DSH-007: implement read-only or remove.) `index()` itself returns a Blade view,
> which is wrong for a JSON/sanctum API surface — note for ENH-DSH-007.

> **DEAD (no new code — already registered):** 8 controllers serve entirely hardcoded dummy data (Principal/Teacher/Accounts/Inventory/
> Library/Management/Transport/SuperAdmin), each labelled inline `// dummy data — DB wiring is a separate phase`
> (PrincipalDashboardController.php:29 et al.). Already **DEAD-DSH-001**; confirmed. (REQ-DSH-004/005 PARTIAL; ENH-DSH-001/002.)

---

### P3 Findings

- **Main dashboard view ownership inconsistency.** `DashboardController@index` renders app-level `view('backend.v1.dashboard.index')`
  (DashboardController.php:26; file exists at `resources/views/backend/v1/dashboard/index.blade.php`) while all 24 sub-dashboards render
  module views `view('dashboard::...')`. Split ownership; maintainability only. **P3.**
- **Zero tests.** `Modules/Dashboard/tests/{Unit,Feature}` contain only `.gitkeep`. No coverage of role gates, the Student/Parent redirect,
  resilient-zero behaviour, or tile counts — exactly the regressions this audit found (role drift, unguarded sub-pages) would have been
  caught by a gate test. **P3 (escalates to P2 once BUG-DSH-007/SEC-DSH-008/009 are fixed — add regression tests).**
- **API route group omits `EnsureTenantIsActive`.** RouteServiceProvider.php:54-63 (`mapApiRoutes`) applies tenancy init + central-domain
  guard but not the active-tenant gate that web routes get (:39-47). Low risk (read-only, behind sanctum). **P3.**

---

### Layer Health Summary

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | 🟢 Green | N/A — module owns no schema (0 `dsh_*` tables, confirmed). |
| 2 Migration↔Model↔DDL | 🟢 Green | N/A — 0 migrations / 0 models. (DDL-master staleness noted below, not a DSH defect.) |
| 3 Model & ORM | 🟢 Green | N/A — no models; all reads via `DB::table()`. |
| 4 Code Quality | 🟡 Amber | 8 dummy-data controllers (DEAD-DSH-001); split view ownership (P3). |
| 5 Authorization | 🔴 Red | Role-name drift kills 4 dashboards (BUG-DSH-007); 3 unguarded billing sub-pages (SEC-DSH-008); hub permission unseeded (SEC-DSH-009). |
| 6 Multi-Tenancy | 🟢 Green | Cross-DB reads connection-scoped (`mysql`, `global_master_mysql`); no `initialize()`/`end()` leak; tenant()-scoped; no jobs. |
| 7 Input Validation / Mass-assign | 🟢 Green | No input, no writes, no `$request->all()`, no FormRequests — read-only by design. |
| 8 Data Integrity / Tx | 🟡 Amber | No writes (no Tx needed); but silent-zero hides breakage (DATA-DSH-001) + no session scoping (DATA-DSH-002). |
| 9 Performance | 🔴 Red | `Schema::getColumnListing` per safeCount (PERF-DSH-001/005); ~80 uncached reads/load. |
| 10 Queue/Job/Scheduler | 🟢 Green | No jobs, listeners, or scheduled commands. |
| 11 Frontend/Blade | 🟢 Green | No raw user-string output flagged; chart payloads only (spot review). |
| 12 Deployment | 🟡 Amber | apiResource stub 500s (BUG-DSH-006); 0 tests; otherwise deploys cleanly, no secrets/migrations. |

### STEP 1 Reading-Discipline Output

**Three-way reconcile (schema):** N/A for owned schema (none). For the cross-DB **source** tables the module reads, a reconcile of code
vs DDL-master vs live migration surfaced one **false positive avoided**:

| Concern | DDL master (`prime_db_v4.sql`) | Live migration / model | Dashboard code | Verdict |
|---|---|---|---|---|
| Billing-schedule table name | `prm_tenant_plan_billing_schedule` (singular) | `prm_tenant_plan_billing_schedules` (plural) — `Modules/Prime/database/migrations/2025_12_02_051744_*` + `Prime/app/Models/TenantPlanBillingSchedule.php:15` | `prm_tenant_plan_billing_schedules` (plural) — FoundationalSetupDashboardController.php:213 | **Code is correct vs the live schema.** The DDL master is stale (singular). NOT a DSH finding; flag the DDL-master drift to DB Architect. |

Cross-DB source tables spot-verified to exist in the live/prime/global schema: `prm_tenant`, `prm_plans`, `prm_tenant_plan_jnt`,
`prm_billing_cycles`, `prm_tenant_plan_billing_schedules`, `bil_tenant_invoices`, `glb_cities`, `glb_academic_sessions`, `glb_boards`.

**Snapshot corrections (module-knowledge was right on the big items, refined here):**
- module-knowledge listed the permission-unseeded and dummy-data items as P1/P2 hints — **confirmed against live code** and promoted to coded findings.
- module-knowledge did **not** catch the **role-name drift** (BUG-DSH-007) or the **unguarded Foundational-Setup sub-pages** (SEC-DSH-008) — both newly confirmed here.
- Stale known-issues entries reconciled (see Systemic/Reconciliation note below): the live controllers DO now carry role/Gate checks, so the older "no authorization in any controller" entries are partially superseded.

### FRD Gap Summary (Mode B)

| REQ | Feature | Code status (live) | Gap / finding |
|-----|---------|--------------------|---------------|
| REQ-DSH-001 | Main landing dashboard | DONE (live) | Ungated for all staff — by FRD design (landing for all staff); Student/Parent redirect present (DashboardController.php:18). |
| REQ-DSH-002 | 15 area hubs | **BLOCKED** | Permission unseeded → inaccessible to non-super-admins (SEC-DSH-009). |
| REQ-DSH-003 | Foundational detail pages | DONE but UNGATED | Confidential data exposed (SEC-DSH-008). |
| REQ-DSH-004 | 6 role dashboards | PARTIAL (dummy) + **BROKEN access** | DEAD-DSH-001 (dummy) + BUG-DSH-007 (Accounts/Transport/Management 403). |
| REQ-DSH-005 | Platform health | PARTIAL (dummy) + **BROKEN access** | DEAD-DSH-001 + BUG-DSH-007 ('SuperAdmin' role unseeded → 403). |
| REQ-DSH-006 | Student/Parent redirect | DONE | `hasAnyRole(['Student','Parent'])` → redirect (DashboardController.php:18-20). ✓ |
| REQ-DSH-007 | Consolidated notifications | DONE (delegated) | Routes to GlobalMaster NotificationController@allNotifications. ✓ |
| REQ-DSH-008 | Resilient aggregation | DONE | safeCount/safeSum try/catch + soft-delete aware ✓; logging gap (DATA-DSH-001). |
| REQ-DSH-009 | Access enforcement | PARTIAL | Auth/verified/tenancy ✓; permission unseeded (SEC-DSH-009); role drift (BUG-DSH-007); sub-pages ungated (SEC-DSH-008). |
| REQ-DSH-010 | Timetable readiness % | DONE (live) | DashboardController.php:84-94, stages-with-data ÷ total. ✓ |
| REQ-DSH-011 | Cross-layer billing read | DONE (live) | Cross-DB reads work against live schema (page is ungated — SEC-DSH-008). |
| REQ-DSH-012 | Dashboard data API (scaffold) | NOT STARTED (stub) | BUG-DSH-006 (non-index verbs 500); ENH-DSH-007. |

### Business-Rule Enforcement (Mode C)

| BR | Type | Enforcement location | Status | Link |
|----|------|----------------------|--------|------|
| BR-DSH-001 read-only | Workflow | no write paths in any controller | ENFORCED | — |
| BR-DSH-002 current-school only | Permission | tenant connection (default) | ENFORCED | — |
| BR-DSH-003 exclude soft-deleted | Calculation | BaseDashboardController:27,46 (`whereNull('deleted_at')` when column exists) | ENFORCED | — |
| BR-DSH-004 source-fail → 0 | Workflow | safeCount/safeSum catch | ENFORCED (no logging) | DATA-DSH-001 |
| BR-DSH-005 Student/Parent redirect | Workflow | DashboardController:18 | ENFORCED | — |
| BR-DSH-006 hub permission | Permission | `Gate::authorize('tenant.dashboard.viewAny')` ×15 | **PARTIAL** — permission unseeded | SEC-DSH-009 |
| BR-DSH-007 role dashboard = matching role | Permission | abort_unless(hasRole()) ×7 | **PARTIAL** — 4 reference unseeded roles | BUG-DSH-007 |
| BR-DSH-008 authenticated+verified | Permission | `auth`+`verified` middleware (web.php:32,34) | ENFORCED | — |
| BR-DSH-009 active tenancy | Permission | RSP web stack (InitializeTenancyByDomain/PreventAccessFromCentralDomains/EnsureTenantIsActive) | ENFORCED (web); api omits EnsureTenantIsActive | P3 note |
| BR-DSH-010 chart active sections only | Calculation | DashboardController:64 (`where('cs.is_active',1)`) | ENFORCED | — |
| BR-DSH-011 Other Staff = staff−teachers ≥0 | Calculation | DashboardController:74 (`max(0,...)`) | ENFORCED | — |
| BR-DSH-012 readiness % | Calculation | DashboardController:92-94 | ENFORCED | — |
| BR-DSH-013 current-session figures | Calculation | FoundationalSetup:22 (`['is_current'=>1]`) | ENFORCED | — |
| BR-DSH-014 active-user counts | Calculation | FoundationalSetup:27 (`['is_active'=>1]`) | ENFORCED | — |
| BR-DSH-015 capped recent lists, newest-first | Validation | FoundationalSetup:44-45 (limit 5, orderByDesc), :206 (limit 8) | ENFORCED | — |
| BR-DSH-016 city from global master | Calculation | FoundationalSetup:66-70 (`global_master_mysql`.glb_cities) | ENFORCED | — |
| BR-DSH-017 billing by tenant identity, empty if unresolved | Workflow | FoundationalSetup:173-176 (`tenant()?->getTenantKey()` guard) | ENFORCED | — |
| BR-DSH-018 active plan = subscribed | Validation | FoundationalSetup:95 (`is_subscribed=1`) | ENFORCED | — |
| BR-DSH-019 next bill = earliest future ungenerated active | Calculation | FoundationalSetup:213-218 (`bill_generated=0`,`is_active=1`,orderBy date) | ENFORCED | — |
| BR-DSH-020 active LMS counts | Calculation | DashboardController:48-51 (`is_active=1`) | ENFORCED | — |
| BR-DSH-021 pending/open statuses | Calculation | DashboardController:52-53 (`EVALUATION_PENDING`/`OPEN`) | ENFORCED (string status — verify constants) | — |
| BR-DSH-022 only current user's notifications | Permission | delegated to GlobalMaster NotificationController | ENFORCED (delegated — verify in GlobalMaster) | — |
| BR-DSH-023 cards link only to real routes | Validation | DashboardController:107-157 (static card config) | **AT RISK** — hardcoded route names not validated; if a target route is renamed the card 500s on click. P3. | — |
| BR-DSH-024 point-in-time, no cache | Workflow | all controllers (no cache) | ENFORCED | — |

### Systemic-Pattern Scorecard (Mode D — scoped to DSH)

| Pattern | Present? | Count | vs baseline |
|---------|----------|-------|-------------|
| D17 fillable→missing column | N/A | 0 models | — |
| D24 permission-prefix chaos/typos | Partial | 1 prefix (`tenant.`) — consistent, but the ability is unseeded (SEC-DSH-009) | better than norm on prefix consistency |
| D25 `$request->all()` mass-assign | Absent | 0 | below baseline (read-only) |
| D29 `->enum()` in migrations | N/A | 0 migrations | — |
| D30 FormRequest `authorize(){return true;}` | N/A | 0 FormRequests | — |
| D36 GENERATED columns degraded | N/A | no schema | — |
| Layer 2.5 cross-DB / missing-FK target | N/A (no own FKs) | cross-DB *reads* present, connection-scoped & safe | — |
| Layer 6.2 `initialize()` without `end()` | Absent | 0 (uses `tenant()` helper + `DB::connection()`) | clean |
| Layer 10.1 jobs without tenancy/retry | N/A | 0 jobs | — |
| TEN-RTG-001 module-subscription middleware | Present (web) | EnsureTenantIsActive on web; **absent on api** | minor (P3) |
| Role-name-vs-gate drift (new local pattern) | **Present** | 4 dashboards | new — see BUG-DSH-007 |

### vs Platform Baseline
- **Below the norm (good)** on the platform's worst systemic patterns: 0 of D25 (24 platform sites), 0 of D30 (437/485 platform), 0 of D29 (~476 platform), 0 cross-DB FK blockers, 0 jobs-without-tenancy — all because the module is read-only and schema-less.
- **At/below norm** on authorization: unlike the "64 write controllers with zero authz" baseline, every controller here carries an authz primitive — but they are mis-wired (unseeded permission / unseeded roles), a *correctness* failure rather than an *absence* failure.
- **Worse than ideal** on performance (Schema introspection per read) — comparable to the Hostel/Marksheet `Schema::hasTable()` runtime-flag anti-pattern called out in Layer 9.4.

### Recommended Fix Order (unblock-the-most-first)
1. **SEC-DSH-009** — seed `tenant.dashboard.viewAny` (+ grant to staff roles). Unblocks all 15 hubs. (3h, Sprint 1)
2. **BUG-DSH-007** — fix the 4 role-name strings / seed the missing roles. Unblocks 4 role dashboards. (low effort, high impact)
3. **SEC-DSH-008** — add `Gate::authorize` to the 3 Foundational-Setup sub-pages. Closes confidential-data exposure. (low effort)
4. **DATA-DSH-001** — log caught aggregation failures (ENH-DSH-004). (4h)
5. **DATA-DSH-002** — add current-session scoping to aggregations (confirm intent first; ENH-DSH-003). (16h)
6. **PERF-DSH-001/005** — cache `getColumnListing` per request / pass soft-delete flag.
7. **BUG-DSH-006** — implement read-only API or remove the apiResource (ENH-DSH-007).
8. **Tests** — add gate/redirect/resilient-zero regression tests (would have caught 1–3).

---
*Mode X complete. No P0 → health uncapped at 65/100 (Amber). Platform deploy: GO. Dashboard feature: NO-GO until items 1–3 land.*
*New codes assigned this pass: BUG-DSH-007, SEC-DSH-008, SEC-DSH-009, DATA-DSH-001, DATA-DSH-002. Existing codes confirmed (not duplicated): PERF-DSH-001/005, BUG-DSH-006, DEAD-DSH-001.*
