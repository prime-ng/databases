# Known Bugs, Security Issues, Performance Issues & Roadmap

> **Last Updated:** 2026-03-12
> **Source:** `04_Bug_Report.md`, `05_Performance_Bottlenecks.md`, `06_Security_Audit.md`, `10_N_Plus_One_Query_Report.md`, `13_Master_Improvement_Roadmap.md`
> **Total Issues: 127** (25 critical, 41 high, 41 medium, 20 low)

---

## CRITICAL BUGS (Must Fix Immediately)

### BUG-001: Missing Model Imports in AppServiceProvider (Runtime Crash)
- **File:** `app/Providers/AppServiceProvider.php` lines 525, 537, 538, 547
- **Problem:** `TptVehicleFuel`, `AttendanceDevice`, `TptFineMaster` used in `Gate::policy()` but never imported. Causes fatal `Class not found` on any authorization check hitting these policies.
- **Fix:** Add `use Modules\Transport\Models\TptVehicleFuel;` etc.

### BUG-002: Duplicate Policy Registrations (Authorization Silently Broken)
- **File:** `app/Providers/AppServiceProvider.php`
- **Problem:** `Gate::policy()` maps one model to one policy — the LAST registration wins. Multiple models registered multiple times, silently overwriting correct policies:
  - `QuestionBank::class` × 3 — `QuestionBankPolicy` silently lost
  - `Vehicle::class` × 5 — `VehiclePolicy` silently lost
  - `Section::class` × 3 — `SectionPolicy` silently lost
  - `BookAuthors::class` mapped to `CircularGoalsPolicy` (copy-paste error)
  - `BokBook::class` mapped to `HpcParametersPolicy` (copy-paste error)
  - Also affected: `Competencie`, `PickupPoint`, `TptTrip`, `ClassSection`, `DropdownNeed`, `InvoicingPayment`
- **Impact:** Authorization for QB CRUD, Vehicle CRUD, Section CRUD is effectively broken
- **Fix:** Redesign policy mapping — use `Gate::define()` or fix to single registration per model

### BUG-004: Tenant Migration Pipeline Commented Out (Tenant Onboarding Broken)
- **File:** `app/Providers/TenancyServiceProvider.php` lines 33-36
- **Problem:** `MigrateDatabase`, `CreateRootUser`, `AddOrganizationDetails`, `SeedDatabase` are ALL commented out in `TenantCreated` event. New tenants get empty databases with no schema and no root user.
- **Fix:** Uncomment at minimum `MigrateDatabase` and `CreateRootUser`

---

## HIGH BUGS

### BUG-005: Wrong Permission Check in TenantController
- **File:** `Modules/Prime/app/Http/Controllers/TenantController.php` lines 77, 88, 116, 345
- **Problem:** Uses `Gate::authorize('prime.tenant-group.update')` instead of `prime.tenant.update`. Users with tenant-group permission but NOT tenant permission can edit tenants.
- **Fix:** Change to `Gate::authorize('prime.tenant.update')` in all tenant-editing methods

---

## MEDIUM BUGS

### BUG-003: SQL Injection via Incorrect DB::raw Usage
- **File:** `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php` line 394
- **Problem:** `->update(['ordinal' => -1 * DB::raw('id')])` — multiplication with DB::raw() produces string concatenation, not intended SQL
- **Fix:** Use `->update(['ordinal' => DB::raw('-1 * id')])`

### BUG-007: Null Pointer in Student::currentFeeAssignment()
- **File:** `Modules/StudentProfile/app/Models/Student.php` line 214
- **Problem:** `AcademicSession::current()->first()->id` crashes if no current session exists. Called from relationship definition — any eager/lazy load crashes.
- **Fix:** `AcademicSession::current()->first()?->id`

---

## LOW BUGS

### BUG-006: Syntax Error in SmartTimetableController
- **File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php` line 104
- **Problem:** `/$activities = Activity::with(...)` — leading `/` causes PHP parse error
- **Fix:** Remove leading `/`

### BUG-008: Duplicate Entries in User $fillable
- **File:** `app/Models/User.php` lines 36-53
- **Problem:** `user_type` appears twice (lines 37 and 43), `two_factor_auth_enabled` appears twice (lines 44 and 51)
- **Fix:** Remove duplicate entries

---

## CRITICAL SECURITY ISSUES (Immediate Action Required)

### SEC-002: Privilege Escalation via User $fillable
- **File:** `app/Models/User.php`
- **Problem:** `is_super_admin`, `super_admin_flag`, `remember_token`, `password` are in `$fillable`. Any controller using `$request->all()` allows privilege escalation.
- **OWASP:** A01 — Broken Access Control
- **Fix:** Remove `is_super_admin`, `super_admin_flag`, `remember_token` from `$fillable`

### SEC-004: Payment Webhook Behind Auth Middleware (Payments Always Fail)
- **File:** `routes/tenant.php` line 295
- **Problem:** Razorpay webhooks are server-to-server — cannot authenticate as user. Webhook route inside `auth` middleware group → ALL payment callbacks fail with 401/302.
- **OWASP:** A07 — Authentication Failures
- **Fix:** Move webhook route OUTSIDE auth middleware group; rely on signature verification

### SEC-005: Webhook Signature Bypass via Gateway Parameter
- **File:** `Modules/Payment/app/Http/Controllers/PaymentController.php` lines 74-92
- **Problem:** Signature verification only runs for `$gateway === 'razorpay'`. Attacker can POST to `/payment/webhook/anything_else` to skip verification and inject fake payment events.
- **OWASP:** A02 — Cryptographic Failures
- **Fix:** Whitelist allowed gateways; reject unknown values

### SEC-008: Unauthenticated Seeder Route Exposed
- **File:** `routes/tenant.php` line 2627
- **Problem:** `Route::get('seeder/run', [SeederController::class, 'run'])` — NO auth middleware. Anyone can call this URL and insert data into the database.
- **OWASP:** A01 — Broken Access Control
- **Fix:** Remove route entirely, or protect with auth + super-admin role check

---

## HIGH SECURITY ISSUES

### SEC-001: Mass Assignment in TenantController
- **File:** `Modules/Prime/app/Http/Controllers/TenantController.php` lines 53, 90
- **Problem:** `$request->all()` used instead of `$request->validated()` despite TenantRequest being type-hinted
- **Fix:** Change `$request->all()` → `$request->validated()`

### SEC-003: Super Admin Gate Bypass (Combined with SEC-002 = Full Platform Access)
- **File:** `app/Providers/AppServiceProvider.php` lines 371-375
- **Problem:** `Gate::before()` returns `true` for Super Admin, bypassing ALL checks. Combined with SEC-002, mass-assigning `is_super_admin` = platform takeover.
- **Fix:** Tighten Gate::before() callback

### SEC-009: SmartTimetableController — Zero Authorization
- **File:** `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php`
- **Problem:** 2,958-line controller with ZERO `Gate::authorize()` calls. Any authenticated user can generate/modify/delete timetables.
- **Fix:** Add `Gate::authorize()` to all 22 public methods

### SEC-011: env() in Route File Breaks After Config Cache
- **File:** `routes/web.php` line 62
- **Problem:** `Route::domain(env('APP_DOMAIN'))` — after `config:cache`, `env()` returns null, breaking ALL central admin routes
- **Fix:** Change to `config('app.domain')` and add APP_DOMAIN to config/app.php

---

## MEDIUM SECURITY ISSUES

### SEC-006: Stack Trace Leaked in API Response
- **File:** `Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php` line 920
- **Problem:** `env('APP_DEBUG')` used to conditionally expose `$e->getTraceAsString()` in API responses
- **Fix:** Use `config('app.debug')`, never expose stack traces in production

### SEC-007: Mass Assignment in MenuController
- **File:** `Modules/SystemConfig/app/Http/Controllers/MenuController.php` line 127
- **Fix:** Change `$menu->update($request->all())` → `$menu->update($request->validated())`

### SEC-010: Debug/Test Routes in Production
- **File:** `routes/tenant.php` lines 281, 310, 1237, 1733
- **Problem:** `GET test-notification`, `GET /seeder` (StudentFeeController::seederFunction), `GET test-seeder` (SmartTimetableController::seederTest)
- **Fix:** Remove all test/debug routes

### SEC-012: Webhook Stores Raw Payload Before Verification (DoS Vector)
- **File:** `Modules/Payment/app/Http/Controllers/PaymentController.php` lines 61-65
- **Problem:** `PaymentWebhook::create()` called BEFORE signature verification — attacker floods DB with fake webhook records
- **Fix:** Move `PaymentWebhook::create()` to AFTER successful signature verification

---

## CRITICAL PERFORMANCE ISSUES

### CACHE-001: Zero Application-Level Caching (ENTIRE APPLICATION)
- **Problem:** Only 4 `Cache::` usages exist (none in controllers). Every page load re-queries all reference data from DB.
- **Affected Data:** Dropdowns (16 queries in ComplaintController alone), academic sessions, room types, study formats, subject types, settings, permissions
- **Fix:** Implement `Cache::remember()` for: dropdowns (1h TTL), academic sessions, room types, settings, study formats

### PERF-001: SchoolClassController::index() — 15+ Queries Per Request
- **File:** `Modules/SchoolSetup/app/Http/Controllers/SchoolClassController.php` lines 95-293
- **Problem:** Loads all tab data (sections, rooms, teachers, subjects, etc.) on every request even if user views one tab
- **Fix:** AJAX-loaded tabs — each tab loads its data only when activated

### PERF-010: storeBulkAttendance() — updateOrCreate in Loop (HIGH DAILY USE)
- **File:** `Modules/StudentProfile/app/Http/Controllers/AttendanceController.php` lines 311-337
- **Problem:** `updateOrCreate` called for EACH student — 40 students = 40-80 queries. Called daily for every class.
- **Fix:** Use `DB::upsert()` for bulk attendance saving

### PERF-005: Model::all() — 110+ Instances
- **Problem:** `Student::all()`, `User::all()`, `TptTrip::all()` with thousands of records cause memory exhaustion
- **Worst offenders:** DepartmentSlaController (9 full table scans per request), StudentAllocationController (`Student::all()`), LiveTripController (`TptTrip::all()`)
- **Fix:** Use `->select(['id', 'name'])->get()` for dropdowns, paginate listings, AJAX search for large tables

---

## HIGH PERFORMANCE ISSUES

### N1-007: ComplaintController — DB Query Per Complaint (1000 queries/page)
- **File:** `Modules/Complaint/app/Http/Controllers/ComplaintController.php`
- **Problem:** For EACH complaint: 1 dropdown query + 1 lazy-load = 2N+1 queries. Complaints loaded TWICE (duplicate). 500 complaints = 1001 queries.
- **Fix:** `Complaint::with('category')->paginate(20)` + pre-load status dropdown map

### N1-011: TripController::bulkApprove() — 4+ Lazy Loads Per Trip
- **File:** `Modules/Transport/app/Http/Controllers/TripController.php` lines 596-599
- **Problem:** `$trip->routeScheduler->vehicle->vendor->agreement->agreementSingleItem` — 4+ lazy loads per trip. 20 trips = 80+ queries.
- **Fix:** Eager load the full chain with `with(['routeScheduler.vehicle.vendor.agreement.agreementSingleItem'])`

### PERF-006: QuestionBank Import — 1 Query Per Excel Row
- **File:** `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php`
- **Problem:** `LOWER()` duplicate check per row — 500 questions = 500 queries. `LOWER()` also prevents index usage.
- **Fix:** Pre-load existing question contents into memory, check in-memory

### PERF-007: ActivityController::generateActivities() — Nested Loop Queries
- **File:** `Modules/SmartTimetable/app/Http/Controllers/ActivityController.php` lines 164-289
- **Problem:** For each requirement: lazy-loaded roomType, rooms, updateOrCreate. 200 requirements = 800+ queries.
- **Fix:** Pre-load all TeacherAvailability + room counts; bulk upsert instead of updateOrCreate in loop

### IDX-002: Missing Index on std_student_academic_sessions.is_current (HIGH)
- **Problem:** `->where('is_current', 1)` used heavily across AttendanceController, StudentController — no index
- **Fix:** `$table->index(['is_current', 'class_section_id']);` composite index

### PERF-008 / PERF-009: ActivityScoreService Batch Updates (200 UPDATE queries)
- **File:** `Modules/SmartTimetable/app/Services/ActivityScoreService.php`
- **Problem:** `recalculateForTerm()` fires 1 UPDATE per activity. `countConstraintsForActivity()` fires 3 COUNT queries per activity. 200 activities = 800+ queries.
- **Fix:** Calculate scores in memory; use bulk update via `upsert()` or CASE statement

---

## HPC MODULE — Issues & Roadmap (added 2026-03-16 from comprehensive gap analysis)

> **Source:** `{HPC_GAP_ANALYSIS}`
> **Total Issues: 20** (4 security, 14 bugs, 2 performance) — ALL OPEN

### Security Issues

| Code | Severity | Description |
|------|----------|-------------|
| SEC-HPC-001 | **CRITICAL** | 13/15 HpcController methods have zero authorization — any authenticated user can view/edit/generate/download any student's HPC |
| SEC-HPC-002 | HIGH | 7/14 FormRequests return `true` in authorize() — store/update unprotected on 10 CRUD controllers |
| SEC-HPC-003 | HIGH | No EnsureTenantHasModule middleware on HPC route group — accessible without subscription |
| SEC-HPC-004 | HIGH | Module web.php/api.php register routes outside tenancy middleware — bypasses all tenant isolation |

### Bugs

| Code | Severity | Description |
|------|----------|-------------|
| BUG-HPC-001 | HIGH | 4 template controller imports missing in tenant.php → 500 on all template CRUD routes |
| BUG-HPC-003 | HIGH | Garbled permission string `tenant.hpc-templates.viHpcTemplatesRequest ew` in show() → always 403 |
| BUG-HPC-004 | HIGH | Global AcademicSession used in tenant controllers — cross-layer data leak |
| BUG-HPC-005 | MED | 3 routes point to non-existent HpcController methods → 500 BadMethodCallException |
| BUG-HPC-006 | MED | HpcTemplates model uses uppercase class refs (HPCTemplateSections) — breaks on Linux |
| BUG-HPC-007 | MED | StudentHpcSnapshot imports wrong Student model (SchoolSetup instead of StudentProfile) |
| BUG-HPC-008 | MED | Orphan `LearningActivityController` import in tenant.php — may cause autoload error |
| BUG-HPC-009 | MED | All trash/view routes shadowed by Resource show route — unreachable |
| BUG-HPC-010 | LOW | Duplicate table prefix on 2 models (hpc_hpc_levels, hpc_student_hpc_snapshot) |
| BUG-HPC-011 | LOW | 18/26 models missing created_by from $fillable — audit trail FK never set |
| BUG-HPC-012 | LOW | LearningOutcomesController imports Prime\Dropdown — cross-layer |
| BUG-HPC-013 | LOW | ZIP files never cleaned up — storage bloat over time |
| BUG-HPC-014 | LOW | Individual PDF URLs use tenant_asset() — may not resolve in all deployment configs |

### Performance Issues

| Code | Severity | Description |
|------|----------|-------------|
| PERF-HPC-001 | MED | generateReportPdf() N+1 — per-student loop queries for attendance/siblings without batching |
| PERF-HPC-002 | MED | 15× duplicated ~70-line index() query block across all controllers — fires ~15 queries per request |

### HPC Roadmap (4-Sprint Plan)

| Sprint | Scope | Duration | Key Items |
|--------|-------|----------|-----------|
| Sprint 1 | P0+P1: Security & Critical Bugs | ~2 days | SEC-HPC-001 (auth on 13 methods), SEC-HPC-002 (fix 7 FormRequests), SEC-HPC-003 (add module middleware), SEC-HPC-004 (remove scaffold routes), BUG-HPC-001 (add 4 imports) |
| Sprint 2 | P2: Workflows & Data Flow | ~3 weeks | Approval workflow (Draft→Review→Final→Published), Eval-to-Report auto-feed, LMS/Exam integration, Attendance manager screen, Role-based section locking |
| Sprint 3 | P3: Multi-Actor Data Collection | ~3 weeks | Student self-service portal (35 sections), Parent data collection (9 sections), Peer assessment workflow (14 sections), Credit framework calculator |
| Sprint 4 | P3: Remaining Screens & Integration | ~3 weeks | 12 unstarted blueprint screens, 15 Schema-2 migration files, Performance fixes, Test suite, Final 8 remaining bugs |

---

## MASTER IMPROVEMENT ROADMAP

### Phase 1: Critical — Week 1 (~2-3 days effort)
1. Remove `is_super_admin`, `super_admin_flag`, `remember_token` from User `$fillable` (SEC-002) — 15 min
2. Move payment webhook route outside auth middleware (SEC-004) — 15 min
3. Add gateway whitelist in webhook handler (SEC-005) — 30 min
4. Remove/protect `seeder/run` route (SEC-008) — 15 min
5. Fix `$request->all()` → `$request->validated()` in TenantController (SEC-001) — 15 min
6. Add `Gate::authorize()` to all SmartTimetableController methods (SEC-009) — 2 hours
7. Move PaymentWebhook::create() after signature verification (SEC-012) — 15 min
8. Change `env('APP_DOMAIN')` → `config('app.domain')` in routes/web.php (SEC-011) — 30 min
9. Add missing model imports in AppServiceProvider: TptVehicleFuel, AttendanceDevice, TptFineMaster (BUG-001) — 15 min
10. Fix duplicate policy registrations (BUG-002) — 4 hours
11. Uncomment MigrateDatabase + CreateRootUser in TenancyServiceProvider (BUG-004) — 15 min
12. Fix wrong permission `prime.tenant-group.update` → `prime.tenant.update` (BUG-005) — 15 min
13. Add null-safe in Student::currentFeeAssignment() (BUG-007) — 5 min
14. Remove `dd()` calls from ComplaintController lines 393, 819 and LmsExamController — 5 min
15. Remove all test/debug routes from tenant.php (SEC-010) — 30 min

### Phase 2: High — Week 2-4 (~2-3 weeks effort)
16. Fix DDL syntax errors in prime_db_v2.sql (12 issues)
17. Fix FK references to non-existent tables
18. Implement caching for: dropdowns (1h TTL), academic sessions, room types, settings, permissions
19. Fix critical N+1 issues: ComplaintController, TripController::bulkApprove, AttendanceController bulk save, QuestionBank import
20. Add composite index on `std_student_academic_sessions(is_current, class_section_id)`
21. Delete all backup/copy files: `PaymentController copy.php`, `Tenant.bk`, backup configs, `_Backup` models, `EXTRA_delete_10_02/` directory

### Phase 3: Medium — Week 5-10 (~5-6 weeks effort)
22. Split SmartTimetableController (2958 lines) into 5 controllers + 3 services
23. Split StudentController into 6 controllers
24. Extract ActivityGenerationService from ActivityController
25. Convert SchoolClassController::index and NotificationManageController::index to AJAX tabs
26. Replace all `Model::all()` with filtered/paginated queries (110+ instances)
27. Fix ActivityScoreService batch operations (bulk update instead of loop)
28. Extract boilerplate into traits: activity logging, change tracking, toggle status
29. Resolve SchoolSetup ↔ SmartTimetable circular dependency
30. Replace session storage with DB-backed temporary storage for timetable generation

### Phase 4: Low — Week 11+ (~4-5 weeks effort)
31. Standardize ENUM columns to FK references to `sys_dropdown_table`
32. Add missing DB indexes (IDX-001 to IDX-009)
33. Add comprehensive test suite (critical paths: tenant isolation, payment, timetable, RBAC, fee calculation)
34. Add event-driven cross-module communication (StudentEnrolled, FeePaymentCompleted, TimetablePublished, etc.)
35. Add API documentation (OpenAPI/Swagger)
36. Add API response transformers (Laravel API Resources)
37. Fix `#tanent` typo across codebase

### Key Metrics
| Metric | Current | Target (Phase 2) | Target (Phase 4) |
|--------|---------|------------------|------------------|
| Critical security issues | 4 | 0 | 0 |
| Active `dd()` in production | 3 | 0 | 0 |
| Application cache usage | 0 | 5+ layers | 10+ layers |
| Controllers > 500 lines | 5 | 3 | 0 |
| Modules with services | 6 | 8 | 12+ |
| Test coverage | ~0% | 10% | 40%+ |
| N+1 query issues | 13 | 5 | 0 |
| Model::all() instances | 110+ | 50 | <10 |
| Dead code files | 27+ | 0 | 0 |

---

## Missing Features (Not in Codebase)

| Feature | Priority | Notes |
|---------|----------|-------|
| Student Portal (full UI) | HIGH | 3 controllers exist but no views |
| Result/Report Card Generation | HIGH | Exam papers exist but no result compilation |
| Fee Payment End-to-End | HIGH | SEC-004 breaks all Razorpay webhooks currently |
| SMS Notifications | HIGH | Channel defined but stubbed |
| LMS Grading (auto-grading, grade book) | MEDIUM | Quizzes/exams created but no grading |
| Parent Portal | MEDIUM | Parent role exists but no dedicated views |
| Formal Admission Workflow | MEDIUM | No inquiry→application→test→selection pipeline |
| Library Management | MEDIUM | DB tables exist, stub controller only |
| Push Notifications | LOW | Channel defined but stubbed |
| Hostel/Canteen Modules | LOW | Prefixes reserved, no modules |
| Analytics Dashboards | LOW | No personalized learning analytics |
| Academic Calendar | LOW | Sessions exist, no event calendar |
| Certificate/TC Generation | LOW | Documents exist, no template generator |
| Online Classroom (Zoom/Meet) | LOW | No integration |
