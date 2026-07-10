# D7 — Performance & Scale Audit (Production Readiness)

**Date:** 2026-07-02 | **Scope:** /Users/bkwork/Herd/prime_ai — 45 modules, multi-tenant (stancl/tenancy), target ~50 tenants × 1–2k students
**Method:** READ-ONLY. Grep-derived counts platform-wide; method-level inspection sample-based (6 low-scoring modules + top grep offenders). Line numbers verified against source on audit date.

---

## Verdict: **NOT-READY**

3 findings guarantee request timeout/OOM on realistic school data (inline timetable solver, 5-minute report page, 512MB inline PDF build). 10 P1 hot-path N+1/unbounded-query findings scale linearly (or worse) with student count. Infrastructure (session/cache/queue all on MySQL) compounds every finding at 50 tenants.

| Severity | Count |
|----------|-------|
| P0 | 3 |
| P1 | 10 |
| P2 | 5 |
| P3 | 2 |
| **Total** | **20** |

---

## Platform-Wide Counts (grep-derived)

| Metric | Count |
|--------|-------|
| `::all()` in module controllers | 150 |
| `->get()` in module controllers | 3,268 |
| `->paginate(` in module controllers | 1,354 |
| `index()` methods (all modules) | 643 |
| — index() using paginate | 263 (171 paginate-only + 92 paginate+get for filters) |
| — index() fetching via get()/all() ONLY (unpaginated) | **90 (25.5% of data-fetching index methods)** |
| — index() delegating (no direct fetch) | 290 |
| Unpaginated index/list/report/dashboard methods (AST-ish scan) | **159 methods, 367 unbounded get()/all() calls** |
| `Schema::hasColumn/hasTable/getColumnListing` outside migrations/tests | **23 call sites** |
| `Cache::` call sites (app + Modules, excl. tests) | 32 (9 module files + 6 app files) |
| Job classes platform-wide | 21 (5 are tenant-setup/test jobs) |
| `dispatch(` call sites | 42 |
| Inline `Pdf::loadView/loadHTML` sites | 49 (13 modules) |
| Inline `Excel::` sites | 21 download/store + 6 `Excel::import` in controllers |
| Notification classes / implementing ShouldQueue | 10 / **0** |
| `set_time_limit()`/`ini_set('memory_limit')` in request code | 9 sites |

**Eager-load ratios today (with()/get() in controllers)** — improved vs baseline: Hpc 1.49 (was 0.04 — note: baseline measured whole module incl. services), QuestionBank 0.57 (0.43), LmsQuiz 0.65 (0.48), Complaint 0.73, SchoolSetup 1.57, Library 2.08, Prime 1.58, TimetableFoundation 0.91, Transport 1.14. Hpc's heavy risk has moved into `HpcReportService` (see GAP-D7-003).

---

## Findings

| ID | Sev | Module/Area | Description | Evidence (file:line) | Remediation | Effort |
|----|-----|-------------|-------------|----------------------|-------------|--------|
| GAP-D7-001 | **P0** | SmartTimetable | 4,447-line PrimeSolver constraint solver runs **synchronously inside HTTP POST** with a 5-minute cache lock and `set_time_limit($maxTimeSeconds)`. Guaranteed FPM/proxy timeout on a full school; blocks a worker for minutes; concurrent tenants serialize on lock/stale-lock recovery code. | `Modules/SmartTimetable/app/Http/Controllers/SmartTimetableController.php:2542` (`generateWithPrime()`), `:2548` (5-min lock), `:2649` (`set_time_limit`), `:2787` (`new PrimeSolver` + `solve()` inline); `TimetableGenerationController.php:441,561`; route `Modules/SmartTimetable/routes/web.php:50` | Dispatch `GenerateTimetableJob` (already exists: `Modules/SmartTimetable/app/Jobs/GenerateTimetableJob.php`) and poll status — the API route already has a `/generate/{runId}/status` pattern (`routes/api.php:14`); make web path use it | M |
| GAP-D7-002 | **P0** | LmsQuiz | Quiz report page self-declares 5-minute runtime: `set_time_limit(300); // Heavy reporting page`. index() executes **23 unbounded get()/all()** across tabs (all subjects, subject groups, `Quiz::where(...)->get()` for whole class, lessons/topics/sub/mini/micro-topic trees). Guaranteed timeout/heavy load on realistic quiz volume; on a hot teacher path. | `Modules/LmsQuiz/app/Http/Controllers/LmsQuizReportController.php:37` (`index()`), `:40` (`set_time_limit(300)`), `:45-85+` (unbounded gets) | Precompute report aggregates in a queued job or scheduled rollup table; paginate/lazy-load per tab via AJAX; cache dropdown datasets | L |
| GAP-D7-003 | **P0** | Hpc | HPC report PDF built inline with `ini_set('memory_limit','512M'); set_time_limit(300)` + dompdf `loadHTML` — invoked from the **parent portal request path**. Multi-page HPC card × dompdf = OOM/timeout on realistic data; 512MB × concurrent parents = server OOM. | `Modules/Hpc/app/Services/HpcReportService.php:844-845` (`buildPdf()`); caller `Modules/Hpc/app/Http/Controllers/ParentHpcFormController.php:104`; also `HpcActivityAssessmentController.php:17-19` | Queue PDF generation (cf. existing `SendHpcReportEmail` job), store to disk, serve download link; never raise memory_limit in web workers | M |
| GAP-D7-004 | P1 | Transport | Finance leakage report runs a `StudentPayLog::where(...)` query **per student session inside `->map()`** — 1–2k extra queries per report render. | `Modules/Transport/app/Http/Controllers/TransportReportController.php:806-809` (`getFinanceLeakageReport()`) | Pre-aggregate pay logs with one grouped query keyed by student_session_id | S |
| GAP-D7-005 | P1 | Transport | Universal transport report: `TptStudentFeeCollection::whereHas()` per allocation inside nested `->map()` (routes × allocations = compound N+1). | `Modules/Transport/app/Http/Controllers/TransportReportController.php:1101-1105` (`getUniversalTransportReport()`, outer map `:1070`) | Batch-fetch collections keyed by allocation_id before mapping | S |
| GAP-D7-006 | P1 | Transport | `getFilterData()` — called on **every report AJAX request** — issues 8 unbounded gets incl. `Student::select(...)->get()` (all 1–2k students) plus all routes/vehicles/shifts/pickup points/drivers/classes. | `Modules/Transport/app/Http/Controllers/TransportReportController.php:347-356` | Cache filter datasets (tenant-scoped, invalidate on write); make student picker a searched AJAX endpoint | S |
| GAP-D7-007 | P1 | Transport | Dashboard + trip management: `TripMgmtController::index()` does 8 unbounded reference gets; dashboard `getTripChartData()` runs 4 count queries per day of range (120 queries / 30 days); `getMaintenanceAlerts()` fetches all vehicles unbounded twice; `getActiveRoutes()` N+1 on non-eager-loaded `route->shift`; `getTripExecutionReport()` maps relations not in the initial `->with()`. | `Modules/Transport/app/Http/Controllers/TripMgmtController.php:72-79`; `TransportDashboardController.php:96-110, 189-213, 225, 241`; `TransportReportController.php:682, 689-729` | Single grouped-by-date query for chart; add missing `->with()`; cache reference data | M |
| GAP-D7-008 | P1 | QuestionBank | Single-question `show()` loads **17 entire tables** into memory for edit dropdowns: `Student::where('is_active',1)->get()` (all students), all topics, lessons, users, media store, books, tags — 21 unbounded gets per question view. Hot path for question authors/reviewers. | `Modules/QuestionBank/app/Http/Controllers/QuestionBankController.php:1437` (`show()`), `:1466-1490` | Convert dropdowns to searched AJAX selects; cache small taxonomies; never load students/users wholesale | M |
| GAP-D7-009 | P1 | StudentProfile | Attendance create page loads **every active student** with 3 eager relations (`StudentAcademicSession::with(['student','classSection.class','classSection.section'])->get()`) just to build a dropdown; `StdLeaveController::index()` runs 11 unbounded gets across tabs. Attendance is the hottest daily path in a school. | `Modules/StudentProfile/app/Http/Controllers/AttendanceController.php:26-33` (create page); `StdLeaveController.php:23` (`index()`) | Scope student fetch to selected class-section (AJAX); lazy-load per-tab data | S |
| GAP-D7-010 | P1 | Complaint | (D10 score 40) Hotspot report executes 3 queries per hotspot row inside `map()`; escalation heatmap runs a `sys_dropdowns` lookup **per complaint** in a loop; list view repeats a per-row status query; `index()` also does `DepartmentSla::all()` + `ComplaintCategory::all()`. | `Modules/Complaint/app/Http/Controllers/ComplaintReportController.php:436-458` (`getComplainantHotspotReport()`); `ComplaintController.php:1061-1066` (`getComplaintsWithEscalation()`), `:125,138` (`index()`); `app/Services/ComplaintDashboardService.php:154-158` (loop at `:138-151`) | Pre-fetch `sys_dropdowns` as keyed map once per request; aggregate hotspot stats in grouped queries | S |
| GAP-D7-011 | P1 | Library | (D10 score 40) Fine trend analysis runs 2 queries per month × 13 months = **26 queries per dashboard load**; membership breakdown counts per type in a loop; dashboard member segments run `LibMember::count()` inside `map()`; category analysis iterates categories→books→copies→transactions in nested PHP loops instead of aggregation. | `Modules/Library/app/Services/LibFineReportService.php:326-345` (`getTrendAnalysis()`), `:204-209`; `MasterDashboardService.php:573-584` (`getMemberSegments()`); `LibCirculationReportService.php:295-306` | Replace with single GROUP BY month/type aggregation queries | S |
| GAP-D7-012 | P1 | Platform-wide | **90 index() methods return unpaginated get()/all(); 159 index/list/report/dashboard methods carry 367 unbounded fetches.** Top offenders beyond those above: `LmsExam/ExamAdvancedReportController.php:37` index() 9 gets; `ParentPortal/ParentHostelController.php:29` 7 gets; `Ptm/PtmManagementController.php:30` 6; `QuestionBank/AIQuestionGeneratorController.php:57` 6; `ParentPortal/ParentLeaveController.php:29` 5; `Syllabus/TopicController.php:34` 5; `Accounting/AccDashboardController.php:39` 8 gets/1 limit; `StudentPortal/StudentLmsController.php:19` 4; `SchoolSetup/TeacherController.php:105` show() 4; `StudentProfile/StudentReportController.php:68,252` 3 each. (StudentController::index itself paginates correctly — `StudentController.php:153,204,248`.) | Scan output retained in audit notes; per-file evidence as listed | Adopt a rule: index/list = paginate or explicit limit; reference dropdowns = cached or AJAX-searched | L |
| GAP-D7-013 | P1 | TimetableFoundation | (D10 score 67) `generateActivities()` hard-deletes all activities then regenerates for the whole school **inline** under `set_time_limit(300)`; a mid-request timeout leaves activities truncated. Edit/create forms load 5+ master tables via `::all()`. | `Modules/TimetableFoundation/app/Http/Controllers/ActivityController.php:52-56` (`generateActivities()`); `RequirementConsolidationController.php:39-41, 295-303`; `TimetableController.php:79-87` (`show()` loads all timetables) | Queue generation; wrap delete+regen so a job failure can roll back; cache master data | M |
| GAP-D7-014 | P2 | Imports | 6 `Excel::import` calls run inline in controllers (question bank, transport fee master, student allocation, library book master, syllabus lessons/topics). A 2k-row student-allocation or book import will exceed 30s FPM default. | `QuestionBank/QuestionBankController.php:218`; `Transport/FeeMasterController.php:427`, `StudentAllocationController.php:473`; `Library/LibBookMasterController.php:709`; `Syllabus/LessonController.php:1041`, `TopicController.php:279` | Use maatwebsite `ShouldQueue`/`WithChunkReading` imports | S |
| GAP-D7-015 | P2 | PDF/Excel exports | 49 inline dompdf sites + 21 inline Excel exports across 13 modules; only 6 domain jobs queue heavy work (`ComputeMarksheetJob`, `BulkGenerateCertificatesJob`, `SendInvoiceEmailJob`, `RunBackupJob`, `GenerateTimetableJob`, `SendHpcReportEmail`). Single receipts are fine; full-dataset report PDFs (Hostel occupancy/attendance/fee reports) block workers. | `Modules/Hostel/app/Http/Controllers/HostelFeeReportController.php:65`, `HostelOccupancyReportController.php:154`, `HostelAttendanceReportController.php:154`; module counts: Billing 5, StudentPortal 4, Hostel 3, Cafeteria 3, Admission 3 (grep) | Queue any PDF/export over a bounded dataset; keep single-record receipts inline | M |
| GAP-D7-016 | P2 | Notifications | **0 of 10 Notification classes implement ShouldQueue**; `Notification::send()` fan-out to all admins runs synchronously over Gmail SMTP (`MAIL_MAILER=smtp`, `smtp.gmail.com`) inside complaint submission and Prime tenant/user creation — each mail adds ~0.5–2s of SMTP latency to the user's request. | `Modules/Complaint/app/Http/Controllers/ComplaintController.php:403`; `Mobile/ComplaintMobileController.php:416`; `Modules/Prime/app/Http/Controllers/UserController.php:98`, `TenantController.php:85`, `TenantGroupController.php:62`; classes in `app/Notifications/` (none ShouldQueue) | Add `implements ShouldQueue` to all mail-channel notifications | S |
| GAP-D7-017 | P2 | Schema introspection | 23 request-path `Schema::hasTable/hasColumn/getColumnListing` call sites = per-request `information_schema` hits. Worst: `BaseDashboardController` runs `getColumnListing` twice on **every dashboard request**; `SelectOrgGroup` Blade component runs `hasTable` per render; 7 sites in Hostel services; `MarksheetComputationService` 3 sites; `StudentController.php:3567`. | `Modules/Dashboard/app/Http/Controllers/BaseDashboardController.php:27,46`; `app/View/Components/Backend/Form/SelectOrgGroup.php:22`; `Modules/Hostel/app/Services/{LeavePassService.php:108,209,260, IncidentService.php:178, HostelFeeService.php:108,211,225, HstAttendanceService.php:145}`; `MarksheetGeneration/app/Services/MarksheetComputationService.php:209,294,338`; `SmartTimetable/TimetableMenuController.php:53`; `SchoolSetup/app/Models/Organization.php:74`; full list in audit | Remove existence checks (schema is migration-guaranteed) or cache results per tenant | S |
| GAP-D7-018 | P2 | Infrastructure | `.env`: `SESSION_DRIVER=database`, `CACHE_STORE=database`, `QUEUE_CONNECTION=database`. At 50 tenants: every request = session SELECT + UPDATE on MySQL (row contention on `sessions` table), every cache op is a MySQL round-trip, queue workers poll MySQL. **laravel/horizon ^5.45 is installed but non-functional on a database queue.** Note: menus/permissions deliberately bypass this via `Cache::store('file')` — per-server, breaks on multi-server deploy. | `/Users/bkwork/Herd/prime_ai/.env` (SESSION_DRIVER/CACHE_STORE/QUEUE_CONNECTION=database); `composer.json` (`laravel/horizon: ^5.45`); `config/session.php:89` | Move session+cache+queue to **Redis** (phpredis), run queues under Horizon; keep tenant-aware cache prefixes | S |
| GAP-D7-019 | P3 | Settings | `sys_settings()` helper is an uncached `DB::table('sys_settings')` query per call — only 5 call sites today, but the pattern invites growth. | `app/Helpers/helpers.php:57-63` | `Cache::remember` per tenant with observer invalidation | S |
| GAP-D7-020 | P3 | Admin sync ops | Permission sync and menu sync run inline with `set_time_limit(300)`/`(120)` — admin-only and infrequent, but 9 total `set_time_limit` sites indicate normalized long-request culture. | `Modules/SchoolSetup/app/Http/Controllers/PermissionSyncController.php:23`; `Modules/SystemConfig/app/Http/Controllers/MenuSyncController.php:70,2346` | Queue sync operations; treat any new `set_time_limit` as a review blocker | S |

---

## Task-Specific Answers

### 5. Caching state
- **32 total `Cache::` sites** (23 in 9 module files, 8 in app, +1 command lock). Half are `Cache::lock()` (timetable concurrency), not data caching.
- **Menus/sidebar: CACHED (good).** `app/View/Components/Backend/Partials/Navbar.php:76` and `Sidebar.php:88-90` (+ Prime variants) use `Cache::store('file')->remember(..., 86400)` with a `perms_ver_{tenant}` version key bumped on role/permission changes (`RolePermissionController.php:72,300,318`; `UserController.php:177`; `MyAccountController.php:107`) and a `MenuObserver` flushing the menu tree.
- **spatie/laravel-permission: CONFIGURED** — `config/permission.php:186-200`: 24h expiration, `'store' => 'file'` (deliberately bypassing the slow database cache store).
- **Settings: NOT cached** (`sys_settings()` — GAP-D7-019). Beyond menus/permissions and 3 `Cache::remember` sites (SyllabusBookConfig, LmsExamController class-section list ×3, Library circulation), the 45-module data layer is effectively uncached.

### 7. Driver assessment
Database session driver at 50 tenants ≈ 2 extra MySQL round-trips + row lock per request on one shared `sessions` table in the central DB; database cache makes every "cache hit" a query; database queue polling competes with tenant traffic. **Recommended: Redis for all three**; Horizon is already in composer and would immediately provide queue visibility.

### Positives (credit where due)
- 263 index() methods paginate correctly; StudentController (4,222-line god object) paginates its main lists.
- SchoolSetup (D10 40) and Library controllers show strong eager-load discipline today (ratios 1.57 / 2.08) — their remaining issues are loop-aggregation patterns in services, not classic N+1.
- Marksheet computation, bulk certificates, invoice emails, backups, and timetable generation all HAVE queued jobs — the P0s are web paths that bypass them.

---

*Audit artifacts: grep counts reproducible via commands recorded in session; sample-based method inspection covered Complaint, SchoolSetup, Library, Prime, TimetableFoundation, Transport + top-40 grep offenders.*
