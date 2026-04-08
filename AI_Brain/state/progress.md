# Development Progress Tracker

> **Last full audit:** 2026-04-02 against `prime_ai` (branch current). Previous: 2026-03-22 on `prime_ai_tarun`.
> **Deep code audit:** 2026-04-02 — 8-agent parallel scan of all 37 modules. Routes→controller mapping, security, performance, validation, dead code. Results in `AI_Brain/lessons/known-issues.md` section "Deep Audit — 2026-04-02".
> **Global stats (2026-04-02):** 37 modules | 349 tenant migrations | 667 models | 506 controllers | 226 services | 2,253 views | 292 FormRequests | 97 module-level test files | 3,557 module route lines
> **Security note:** Only 1 `EnsureTenantHasModule` usage across entire tenant.php. 13 seeder routes with NO auth. 7 HPC controllers missing imports (fatal). Payment webhook behind auth (always 401). Library IS wired into tenant.php (was missing, now confirmed present).
> **Deep Gap Analysis:** Full 29-module gap analysis completed 2026-03-22. Reports in `{GAP_ANALYSIS_MODULE_WISE}/2026Mar22/`. Summary: ~950+ issues, ~140 P0 critical. Deep code audit 2026-04-02 found 14 P0 fatal, 10 P0 data-leak, 24 P1 auth-bypass, 16 P2 perf/val issues across all modules.

## V2 Requirement Documents — 2026-03-26

> **Completed:** All 46 modules + 3 summary files written to `{OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/`
> **Batch tracking:** `V2/_batch_progress.md` — 49 files, all 10 batches ✅ Done
> **Modes:** 24 modules FULL (read V1 + gap analysis + DDL + code) | 22 modules RBS_ONLY (greenfield)

### Key new findings from V2 generation (not in prior gap analysis)

| Module | Finding | Severity |
|--------|---------|----------|
| QNS | **Hardcoded OpenAI `sk-proj-*` + Gemini `AIzaSyD-*` API keys in source** — ROTATE IMMEDIATELY | P0 |
| PAY | Three different broken prefixes: `ptm_`, `pmt_`, and no prefix — zero DDL in tenant_db_v2.sql | P0 |
| STP | Completion revised 25%→63%; `proceedPayment` IDOR still unpatched; hard-coded dropdown ID 104 | P0 |
| HMW | `lms_homework_assignment` table missing from DDL — `publish()` crashes; `release_condition` vs `release_condition_id` mismatch | P1 |
| SLK | `bok_book_topic_mapping` table missing from DDL; `BookAuthors::index()` queries books not authors; cross-layer `Modules\Prime\Models\AcademicSession` | P1 |
| TTS | Completion revised 5%→15-20%; BUG-TTS-001: `whereIn('id')` should be `whereIn('teacher_id')` in conflict check | P1 |
| DOC | Two XSS paths: `{!! content !!}` render + JS `innerHTML` after `atob()` decode; `doc_articles` missing `sort_order` column | P1 |
| LIB | 22 controllers import `Modules\Vendor\Models\Vendor` (cross-layer); module IS in tenant.php (V1 wrong) | P1 |
| SCH | `RolePermissionController::destroy()` calls `$role->save()` not `$role->delete()` — roles never deleted | P1 |
| EXM | `dd($e)` at `LmsExamController.php:565`; 10 Gate calls commented in ExamBlueprintController; 10 in ExamScopeController | P1 |
| CMP | DDL FK: TINYINT→INT on `is_medical_check_required`; index references non-existent `status` column | P2 |
| NTF | Gate prefix `prime.*` used instead of `tenant.*` on all notification routes | P1 |
| HPC | 5 DDL tables missing (`hpc_credit_config` etc.); FK points to `slb_circular_goals` instead of `hpc_circular_goals` | P2 |

---

## Module Completion Summary (audited 2026-03-22)

> Completion % based ONLY on what routes, models, controllers, services, and tests actually exist in code.
> Does NOT count as "complete" if controllers exist but have zero auth, empty stubs, or critical bugs.

### Central-Scoped Modules (deep-audited 2026-04-02)

| Module | Code Exists | Completion | Key Gaps (updated 2026-04-02 deep audit) |
|--------|------------|------------|----------|
| **Prime** | 22 ctrl, 27 mdl, 1 svc, 7 req | **~65%** | `is_super_admin` + `remember_token` in User $fillable; UserController passes is_super_admin via $request->only(); $request->all() in 6+ controllers despite FormRequest injected; TenantController::show()/destroy() empty; api.php apiResource points to stub; 5 controllers with 24+ stub methods |
| **GlobalMaster** | 15 ctrl, 12 mdl, 0 svc, 10 req | **~50%** | `$request->all()` in 12 places; GlobalMasterController/OrganizationController all stubs; LanguageController uses `global-master.*` permission prefix (mismatch with seeded); N+1 in DropdownController::index(); AcademicSessionController::destroy() condition logically inverted; double activityLog() in State/Module controllers |
| **SystemConfig** | 4 ctrl, 3 mdl, 0 svc, 1 req | **~40%** | ZERO auth on SystemConfigController (7 methods); MenuSyncController auth check COMMENTED OUT (any user truncates menus); MenuController 5 stubs; SettingController returns raw $request object; wasted Setting::all() query |
| **Billing** | 7 ctrl, 6 mdl, 0 svc, 3 req, 1 job | **~55%** | **No try/catch on DB transaction in payment processing** — failures corrupt invoice state; both store() and consolidatedStore() affected; BillingManagementController::store() no ownership check on planRateId; Tenant::get()+User::get() unbounded on every page; 15+ stub methods; printData() calls isNotEmpty() on float (crash) |
| **Documentation** | 3 ctrl, 2 mdl, 0 svc, 2 req | **~60%** | Gate permission mismatch (.store vs .create); XSS risk on Summernote; 20MB upload limit excessive; DocumentationController (only routed one) is mostly stubs; Article/Category controllers well-built but unrouted |

### Tenant-Scoped Modules — School Administration (deep-audited 2026-04-02)

| Module | Code Exists | Completion | Key Gaps (updated 2026-04-02 deep audit) |
|--------|------------|------------|----------|
| **SchoolSetup** | 41 ctrl, 42 mdl, 0 svc, 27 req | **~40%** | is_super_admin writable via UserController + in User $fillable + in UserRequest; SchoolSetupController all stubs; 3 routes → missing methods (trashedClassSubgroup, assignSubjects, StudyFormat); 5 backup controller files; student routes all commented out; rand() returns fake dashboard data; $request->all() in OrganizationController/GroupController |
| **StudentProfile** | 5 ctrl, 14 mdl, 0 svc, 0 req | **~30%** | is_super_admin writable in student login creation; **Gate facade not imported in AttendanceController** — all Gate calls fatal; StudentReportController zero auth on PII reports; module web.php registers only stub controller; storeBulkAttendance validation fully commented out; 0 FormRequests |
| **Transport** | 31 ctrl, 36 mdl, 0 svc, 18 req | **~40%** | Module web.php registers 0 tenant routes; `tested.*` permission typo blocks AttendanceDeviceController; updateLastSeen() publicly accessible (no auth); **Aadhaar/PAN stored plaintext** (IT Act violation); TptVehicleServiceRequestController zero auth + zero validation; 3 different permission prefixes (tenant.*/tested.*/transport.*) |
| **StudentFee** | 15 ctrl, 23 mdl, 0 svc, 0 req | **~50%** | 14 seeder methods (~1,200 lines) in production controller; StudentFeeController zero Gate auth; module web.php registers only stub; FeeInvoiceController IDOR (student_assignment_id unchecked); N+1 in bulk invoice generation; 0 FormRequests for financial data |
| **Vendor** | 7 ctrl, 8 mdl, 0 svc, 3 req, 1 job | **~53%** | VendorPaymentController missing create/store/show → 3 routes 500; VendorController::index() Gate commented out; wrong Gate prefix on VndUsageLogController + VendorPaymentController; module web.php bypasses tenancy |
| **Complaint** | 8 ctrl, 6 mdl, 2 svc, 0 req | **~30%** | **6 routes point to non-existent methods** (trashed/restore/forceDelete/toggleStatus) → 500; 3 controllers zero Gate; dropdown queries use literal `dummy_table_name` key → always empty; module web.php bypasses tenancy; double-validate in store() |
| **Notification** | 12 ctrl, 14 mdl, 2 svc, 10 req | **~35%** | **ALL controllers use `prime.*` Gate prefix** — every tenant check returns 403; **Tenant::all() in tenant context** → cross-tenant data leak; 2 controllers don't exist on disk; routes partially commented out; $request->all() mass-assigned |
| **Payment** | 2 ctrl, 5 mdl, 2 svc, 1 req | **~45%** | **Webhook behind auth middleware** — all gateway callbacks return 401; payable_type accepts arbitrary class name (no allowlist); duplicate index routes |
| **Dashboard** | 1 ctrl, 0 mdl, 0 svc, 0 req | **~25%** | ZERO authorization on entire controller; Schema::getColumnListing() fires 28+ DB introspection queries per page; 6 sub-dashboards are empty stubs; crosses to GlobalMaster NotificationController |
| **Scheduler** | 1 ctrl, 2 mdl, 2 svc, 1 req | **~25%** | **No tenancy middleware in RSP** — runs on wrong database; zero Gate auth; store() redirects to non-existent route; show/edit/update/destroy stubs; cron_expression no format validation |
| **StudentPortal** | 7 ctrl, 0 mdl, 0 svc, 0 req | **~55%** | **P0 IDOR in proceedPayment** (payable_id unverified); zero Gate::authorize() in all 7 controllers; ComplaintController show/edit/update/destroy empty; schoolCalendar()/applyLeave() return empty views; PaymentGateway::all() exposes API keys; 7 scaffolded stubs never routed. **Prompt ready:** `5-Work-In-Progress/StudentPortal/1-Claude_Prompt/STP_2step_Prompt1.md` |

### Tenant-Scoped Modules — Academic & Curriculum (deep-audited 2026-04-02)

| Module | Code Exists | Completion | Key Gaps (updated 2026-04-02 deep audit) |
|--------|------------|------------|----------|
| **Syllabus** | 15 ctrl, 22 mdl, 1 svc, 14 req | **~55%** | 14 controllers not routed (only SyllabusController has routes); CompetencieController 6 methods zero Gate + $request->all(); Competencie model missing SoftDeletes; N+1 in getCompetencyTree() recursive children; getLevelLabel() fires DB query per tree node; TopicCompetencyController::update() no validation; wrong permission names (tenant.subject.* used on non-subject controllers) |
| **SyllabusBooks** | 4 ctrl, 6 mdl, 0 svc, 3 req | **~55%** | **Only routed controller has empty store/update/destroy** — routes do nothing; BookTopicMappingController::index() crashes (undefined variable); AuthorController::store()/update() missing Gate; **Cross-layer: BookController queries Prime\AcademicSession from tenant context** |
| **QuestionBank** | 7 ctrl, 17 mdl, 0 svc, 6 req | **~45%** | API keys FIXED (now env()); **generateQuestions() permanently returns demo data** — real AI path unreachable dead code; AIQuestionGeneratorController entire controller zero auth; startImport() missing Gate; 6 controllers unrouted |
| **LmsExam** | 11 ctrl, 11 mdl, 0 svc, 11 req | **~58%** | **dd($e) at store():577 renders DB::rollBack() unreachable**; ExamStudentGroupMemberController::toggleStatus() missing → 500; ExamStudentGroupMemberController::store() no FormRequest/validation; 9 unbounded queries on index; toggleStatus() missing Gate on 2 controllers |
| **LmsQuiz** | 5 ctrl, 6 mdl, 0 svc, 5 req | **~72%** | Gate calls NOW active on all methods (BUG-LMS-005 FIXED for Quiz); route prefix typo `lms-quize`; store() no DB transaction; unused `$original = clone $quiz`; student attempt tracking absent |
| **LmsHomework** | 2 ctrl, 3 mdl, 0 svc, 3 req | **~52%** | HoemworkData $request param FIXED; review() Gate FIXED; **NEW: show() has no auth (IDOR)**; 4 unused imports; unbounded Student::get() and HomeworkAssignment::get() in 3 methods; student submission portal missing |
| **LmsQuests** | 4 ctrl, 4 mdl, 0 svc, 4 req | **~52%** | **Gate still commented in index()** (BUG-LMS-005 confirmed); **getTopics() method missing → 500**; no DB transactions on writes; student quest player absent |
| **Recommendation** | 10 ctrl, 11 mdl, 0 svc, 0 req | **~39%** | **Gate::any() without abort(403)** — auth checks don't block; **StudentRecommendationController uses .create for delete/restore/forceDelete**; show()/edit() wrong permission; uses App\Models\User (wrong namespace); store/update/destroy empty stubs; 4 inconsistent permission prefixes |

### Tenant-Scoped Modules — Timetable & HPC (deep-audited 2026-04-02)

| Module | Code Exists | Completion | Key Gaps (updated 2026-04-02 deep audit) |
|--------|------------|------------|----------|
| **SmartTimetable** | 19 ctrl, 65 mdl, 108 svc, 7 req, 177 views, 14 seeders | **~58%** | **generateForClassSection missing → 500**; API controller zero Gate; ParallelGroupController bypasses tenancy stack; SubstitutionService crash (undefined $candidates) + Carbon API misuse (now()->parse()); God controller 3,501 lines + 8 unused imports; createConstraintManager() all 12 constraints commented out; index() fires 14+ unbounded queries; viewAndRefinement() loads all cells unbounded; 0 tests. **Full doc:** `5-Work-In-Progress/2-In-Progress/SmartTimetable/SmartTimetable_Module_Documentation.md` |
| **TimetableFoundation** | 24 ctrl, 32 mdl, 3 svc, 4 req | **~65%** | **2 routes → missing methods (generateAllActivities, getBatchGenerationProgress) → 500**; generateActivities runs 400+ updateOrCreate in web request; ClassWorkingDayController up to 10,000 upserts in single request; EnsureTenantHasModule missing; 20/24 controllers use inline validation; eligible_teacher_count hardcoded to 1 |
| **StandardTimetable** | 1 ctrl, 0 mdl, 0 svc, 0 req | **~5%** | Module skeleton — **controller file doesn't exist** despite being imported in tenant.php (fatal) |
| **Hpc** | 23 ctrl, 32 mdl, 10 svc, 14 req | **~59%** | **7 controllers used in routes without `use` imports** (fatal, tenant.php:2565–2604); HpcController store/update/destroy empty stubs; 15 queries per tab via HpcIndexDataTrait; public PDF route without auth. Most HPC sprint fixes (2026-03-17) still valid but 3 new controller imports regressed. |
| **Library** | 26 ctrl, 35 mdl, 9 svc, 19 req | **~45%** | IS wired into tenant.php (confirmed present at lines 2770+); No Gate on index() across 14 controllers; $request->all() in 5 controllers; User::all() in 20+ methods; 5 commented dd() calls |

### Accounting & Supporting Modules (deep-audited 2026-04-02)

| Module | Code Exists | Completion | Key Gaps (updated 2026-04-02 deep audit) |
|--------|------------|------------|----------|
| **Accounting** | 18 ctrl, 21 mdl, 0 svc, 15 req, 14 tests | **~40%** | Scaffolding 85% done but core operations 30%: matchEntry/unmatchEntry route wildcard mismatch → 500; runDepreciation missing {fixed_asset} in route → 500; ExpenseClaim race condition (count+1); Dashboard 6 unbounded queries + 12-query monthly loop; autoMatch/importStatement/postNow/runDepreciation are stubs returning false positives |

### Newly Scaffolded Modules (deep-audited 2026-04-02) — Scaffold Done, Partial Implementation

> % based on file counts + business logic verification. ~15% = scaffold + stubs. ~20% = scaffold + some real logic.

| Module | Code Exists | Completion | Notes (updated 2026-04-02 deep audit) |
|--------|------------|------------|-------|
| **Admission** | 15 ctrl, 20 mdl, 6 svc, 17 req, 34 views, 166 route lines | **~18%** | Has real pipeline logic via AdmissionPipelineService. **No Gate::authorize()** — auth deferred to service layer only. Prompt ready. |
| **Cafeteria** | 16 ctrl, 21 mdl, 6 svc, 16 req, 54 views, 148 route lines | **~18%** | OrderController has real logic via OrderService. **Student IDOR in apiIndex()** — student_id from query string unverified. No Gate. Prompt ready. |
| **Certificate** | 9 ctrl, 10 mdl, 3 svc, 10 req, 33 views, 1 job, 123 route lines | **~15%** | Scaffold stubs only. No real implementation. Prompt ready. |
| **FrontOffice** | 20 ctrl, 22 mdl, 4 svc, 3 req, 61 views, 1 job, 172 route lines | **~12%** | Scaffold stubs only. Only 3 FormRequests for 20 controllers. Prompt ready. |
| **HrStaff** | 22 ctrl, 33 mdl, 15 svc, 23 req, 75 views, 195 route lines | **~20%** | PayrollController well-implemented with Gate + FormRequests + service layer. **Arbitrary column override risk via field_name** in override(). Prompt ready. |
| **Inventory** | 20 ctrl, 28 mdl, 7 svc, 13 req, 51 views, 1 job, 176 route lines | **~15%** | Mix of scaffold and partial. No dd/secrets found. Prompt ready. |
| **EventEngine** | 4 ctrl, 3 mdl, 0 svc, 3 req, 17 views, 16 route lines | **~20%** | 3 CRUD sub-controllers well-implemented with Gate. **EventEngineController zero auth**; **No tenancy middleware in RSP** — runs on wrong DB; rule firing engine doesn't exist (config UI only); isset() vs filled() filter bug |

---

## Requirements Complete — Development Pending

- [x] **HRS — HR & Payroll** (0% code, module not created) — Planning complete 2026-03-26. `Modules\HrStaff`. Dual prefix: `hrs_*` (23 tables) + `pay_*` (10 tables). Payroll merged into HrStaff (v2 decision). Outputs: `HRS_FeatureSpec.md`, `HRS_DDL_v1.sql` + migration + 7 seeders, `HRS_Dev_Plan.md`. 20 controllers, 15 services, 30 FormRequests, ~110 views, 102 routes, 6 implementation phases (Sprint 1–12), 22 feature tests + 7 unit test files planned.
- [x] **Inventory** (0% code, module not created) — Prompt ready 2026-03-26. `Modules\Inventory`. Prefix: `inv_*` (28 tables). 18 controllers, 7 services, 13 FormRequests, ~65 views, ~65 routes, 4 seeders + runner, 10 implementation layers. Prompt: `5-Work-In-Progress/22-Inventory/1-Claude_Prompt/INV_2step_Prompt1.md`.
- [x] **FrontOffice / FOF** (0% code, module not created) — Prompt ready 2026-03-26. `Modules\FrontOffice`. Prefix: `fof_*` (22 tables). 16 controllers, 5 services (VisitorService, GatePassService, CircularService, CertificateIssuanceService, EarlyDepartureService), ~75 web routes, ~12 API routes. Key: DomPDF certificates, ATT sync (EarlyDepartureAttSyncJob — 3 retries), public feedback token URL (no auth), fof:flag-overstay Artisan daily. Prompt: `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/FOF_2step_Prompt1.md`.
- [x] **AdmissionMgmt / ADM** (0% code, module not created) — Prompt ready 2026-03-26. `Modules\Admission`. Prefix: `adm_*` (20 tables). 14 controllers, 6 services (AdmissionPipelineService, MeritListService, EnrollmentService, TransferCertificateService, PromotionService, AdmissionAnalyticsService), ~65 web routes, ~20 API routes. Key: atomic enrollment DB::transaction (sys_users + std_students + std_student_academic_sessions), payment webhook outside auth middleware (signature-verified only, idempotent), NEP 2020 entrance test compliance, QR-code TC. Prompt: `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/ADM_2step_Prompt1.md`.
- [x] **Hostel / HST** (0% code, module not created) — Prompt ready 2026-03-26. `Modules\Hostel`. Prefix: `hst_*` (21 tables — spec says 20, DDL has 21). 20 controllers, 7 services (AllotmentService, LeavePassService, HstAttendanceService, IncidentService, HostelFeeService, HstComplaintService, SickBayService), ~65 routes. Key: dual generated-column UNIQUE on hst_allotments (active-bed + active-student), leave approval in DB::transaction (3 ops atomic), WardenScopeMiddleware, hst_sick_bay_log.hpc_record_id soft FK (no constraint), HostelFeeService service-to-service only (no FK to fin_*), DomPDF (leave pass PDF + warning letter). Prompt: `5-Work-In-Progress/Hostel/1-Claude_Prompt/HST_2step_Prompt1.md`.
- [x] **StudentPortal / STP** (~55% code, existing module) — Completion prompt ready 2026-03-26. `Modules\StudentPortal`. Prefix: stp_* (ZERO owned tables — reads 30+ tables from 15 modules). 7 existing controllers (1,317 lines), 57 views, 35 screens, 55+ routes, 0 services/FormRequests/policies. P0: IDOR in proceedPayment + EnsureTenantHasModule missing + zero Gate calls. P1: hard-coded dropdown ID 104, PaymentGateway::all(), currentFeeAssignemnt typo, mark-read GET→POST. Phase 2 of prompt = Security & Architecture (FormRequests + Policy + Service) NOT DDL. ~15 person-days to complete. Prompt: `5-Work-In-Progress/StudentPortal/1-Claude_Prompt/STP_2step_Prompt1.md`.
- [x] **Cafeteria / CAF** (0% code, module not created) — Prompt ready 2026-03-26. `Modules\Cafeteria`. Prefix: `caf_*` (21 tables). 16 controllers, 6 services (MenuService, OrderService, MealCardService, PosService, StockService, ReportService), ~77 routes (62 web + 15 API), 16 FormRequests, 14 policies, ~50 views. Key: ALL caf_* PKs INT UNSIGNED (not BIGINT); atomic balance deduction via SELECT...FOR UPDATE; Razorpay webhook idempotent (razorpay_payment_id UNIQUE, outside auth); HST bridge (auto mess enrollment on hostel admission); INV bridge (optional PR on stock reorder); SimpleSoftwareIO/simple-qrcode; DomPDF (kitchen sheet, card statement, FSSAI audit). Prompt: `5-Work-In-Progress/Cafeteria/1-Claude_Prompt/CAF_2step_Prompt1.md`.
- [x] **ParentPortal / PPT** (0% code, module not created) — Prompt ready 2026-03-26. `Modules\ParentPortal`. Prefix: `ppt_*` (6 tables). 16 controllers, 5 services (ParentDashboardService, FeePaymentService, MessagingService, NotificationPreferenceService, PtmSchedulingService), 9 FormRequests, 3 policies, custom `parent.portal` middleware, ~75 web + ~18 API routes (~93 total), ~45 views, 38 screens. P0: ParentChildPolicy on every data endpoint (IDOR prevention); parent.portal middleware returns 404 not 403; active_student_id stored in DB for multi-device sync; OTP max 3/hr + max 3 attempts + 30-min lockout; Razorpay payment_reference UNIQUE nullable (idempotency). Phase 2 = DDL (6 tables) + Authorization Architecture (middleware + policies + FormRequests + service skeletons). ~21 person-days to build (P0:2 + P1:5 + P2:5 + P3:4 + architecture:5). Prompt: `5-Work-In-Progress/ParentPortal/1-Claude_Prompt/PPT_2step_Prompt1.md`.
- [x] **Maintenance / MNT** (0% code, module not created) — Prompt ready 2026-03-27. `Modules\Maintenance`. Prefix: `mnt_*` (11 tables). 9 controllers (8 web + 1 mobile API), 5 services (TicketService, AssignmentService, PmScheduleService, EscalationService, DepreciationService), 11 FormRequests, 11 policies, 4 jobs, ~55 web + ~9 API routes, ~35 views, 25 screens. Key: ticket number lock-for-update (BR-MNT-001); 7-state ticket FSM (BR-MNT-003); SLA escalation levels via sla_escalation_json (BR-MNT-011); QR auto-generated on asset save via SimpleSoftwareIO (BR-MNT-015); breakdown history auto-inserted on Resolved (BR-MNT-014); AMC alert idempotency flags (BR-MNT-007); mnt_asset_depreciation + mnt_breakdown_history NO deleted_at (immutable); DomPDF work order PDF; mobile API 9 endpoints. 4 scheduled jobs: GeneratePmWorkOrdersJob (daily 06:00), CheckSlaBreachesJob (every 30 min), SendAmcExpiryAlertsJob (daily 08:00), MarkOverduePmWorkOrdersJob (daily 07:00). 2 seeders: 9 asset categories with keyword JSON. 11 implementation phases. Prompt: `5-Work-In-Progress/Maintenance/1-Claude_Prompt/MNT_2step_Prompt1.md`.
- [x] **Certificate / CRT** (0% code, module not created) — Prompt ready 2026-03-27. `Modules\Certificate`. Prefix: `crt_*` (10 tables). 9 controllers, 3 services (CertificateGenerationService, QrVerificationService, DmsService), 10 FormRequests, 8 policies, 1 job (BulkGenerateCertificatesJob), ~58 web + 2 API routes, ~30 views, 26 screens. Key: HMAC-SHA256 verification_hash on every cert (APP_KEY); QR via SimpleSoftwareIO → no-login public /verify/{hash}; DomPDF PDFs; TC fee-clear gate (BR-CRT-001); TC writes std_students.tc_issued=true (BR-CRT-011 direct write); serial counter SELECT FOR UPDATE (BR-CRT-015); bulk > 200 = queue mandatory (BR-CRT-009); crt_template_versions NO deleted_at (immutable); public verification DTO exposes first name + last initial only (BR-CRT-010). 2 seeders: 5 types + 5 starter templates. 4 implementation phases: P1 (types/templates/DDL), P2 (requests/generation/QR), P3 (TC/bulk/ID cards), P4 (DMS/reports/portal). Prompt: `5-Work-In-Progress/Certificates/1-Claude_Prompt/CRT_2step_Prompt1.md`.
- [x] **VisitorSecurity / VSM** (0% code, module not created) — Prompt ready 2026-03-27. `Modules\VisitorSecurity`. Prefix: `vsm_*` (13 tables in 4 domain groups: Visitor Core, Access Control, Guard Operations, Emergency+CCTV). 9 controllers (8 web + 1 API Report), 4 services (VisitorService, SecurityAlertService, PatrolService, ContractorAccessService), 10 FormRequests, 8 policies, ~70 web + 12 API routes, ~32 views, 25 screens (SCR-VSM-01 to SCR-VSM-25). Key: UUID v4 gate pass tokens (Str::uuid() — never sequential, BR-VSM-002); DB::transaction+lockForUpdate on check-in (BR-VSM-003 race condition); emergency broadcast on dedicated 'emergency' queue (bypasses rate limiting, 3 retries); 4 scheduled jobs (FlagOverdueVisitorsJob every 15 min, ExpireGatePassesJob hourly, ExpireBlacklistEntriesJob daily midnight, ExpireContractorPassesJob daily 00:01); SimpleSoftwareIO/simple-qrcode for gate passes + patrol checkpoints; DomPDF for visitor badges + reports; vsm_patrol_checkpoint_log + vsm_cctv_events NO updated_at/deleted_at (immutable); public gate pass scan URL (no auth); CCTV webhook (no auth + X-CCTV-Secret header); 2 seeders (VsmEmergencyProtocolSeeder + VsmPatrolCheckpointSeeder). All vsm_* PKs BIGINT UNSIGNED. Prompt: `5-Work-In-Progress/VisitorSecurity/1-Claude_Prompt/VSM_2step_Prompt1.md`.

## Pending Modules

- [ ] **Behavioral Assessment** — Student behavior tracking and analysis
- [ ] **Analytical Reports** — Cross-module analytics and reporting
- [x] **Hostel Management (HST)** — Prompt ready. See "Requirements Complete" above.
- [x] **Mess/Canteen (CAF)** — Prompt ready. See "Requirements Complete" above.
- [x] **Admission Enquiry (ADM)** — Prompt ready. See "Requirements Complete" above.
- [x] **VisitorSecurity (VSM)** — Prompt ready. See "Requirements Complete" above.
- [x] **FrontDesk (FOF)** — Prompt ready. See "Requirements Complete" above.
- [x] **Certificate / CRT** — Prompt ready. See "Requirements Complete" above.
- [x] **Maintenance / MNT** — Prompt ready. See "Requirements Complete" above.
- [ ] **Help Desk** — Support ticket system
- [x] **Student/Parent Portal (STP + PPT)** — Both prompts ready. See "Requirements Complete" above.

---

## Testing Progress

### Infrastructure (done)
- [x] `phpunit.xml` — updated with all module test suites
- [x] `AI_Brain/memory/testing-strategy.md` — full testing strategy documented
- [x] `AI_Brain/agents/test-agent.md` — Pest 4.x patterns and cheatsheet
- [x] `AI_Brain/templates/test-unit.md` — unit test boilerplate
- [x] `AI_Brain/templates/test-feature-central.md` — central feature test boilerplate
- [x] `AI_Brain/templates/test-feature-tenant.md` — tenant feature test boilerplate

### Test File Inventory (audited 2026-03-22)

| Location | Module | Files | What It Covers |
|----------|--------|-------|----------------|
| `tests/Unit/Central/` | Prime | 5 | Setting model (16 unit + 14 DB tests) |
| `tests/Unit/SmartTimetable/` | SmartTimetable | 6 | TimetableSolution::isPlaced, parallel group backtrack |
| `tests/Unit/Hpc/` | Hpc | 6 | HpcWorkflow, SectionRole, Report, Attendance, Credit, DataMapping services |
| `tests/Unit/StudentProfile/` | StudentProfile | 1 | Student model |
| `tests/Feature/SmartTimetable/` | SmartTimetable | 1 | ConstraintManager feature test |
| `tests/Feature/Hpc/` | Hpc | 1 | HPC authorization test |
| `tests/Browser/Modules/Class&SubjectMgmt/` | SchoolSetup | 9 | Browser CRUD tests |
| `tests/Browser/Modules/Complaint/` | Complaint | 4 | Browser CRUD tests |
| `tests/Browser/Modules/HPC/` | Hpc | 1 | HPC parameters CRUD |
| `tests/Browser/Modules/Library/` | Library | 15 | Browser CRUD tests |
| `tests/Browser/Modules/StudentProfile/` | StudentProfile | 5 | Browser CRUD tests |
| `Modules/Accounting/tests/` | Accounting | 14 | Module-level tests |
| `Modules/StudentFee/tests/` | StudentFee | 24 | Module-level tests |
| `Modules/Prime/tests/` | Prime | 9 | Module-level tests |
| `Modules/TimetableFoundation/tests/` | TimetableFoundation | 7 | Module-level tests |
| `Modules/Payment/tests/` | Payment | 8 | Module-level tests |
| `Modules/StudentPortal/tests/` | StudentPortal | 7 | Module-level tests |
| `Modules/GlobalMaster/tests/` | GlobalMaster | 4 | Module-level tests |
| **Other module tests/** | Various | 1 each | Billing, Documentation, Scheduler, SystemConfig (minimal) |

**Total: 134 test files across the project.**
**Modules with 0 test files:** SchoolSetup, Transport, Syllabus, QuestionBank, LmsExam, LmsQuiz, LmsHomework, LmsQuests, Notification, Vendor, Recommendation, SyllabusBooks, SmartTimetable (module-level), Hpc (module-level), StandardTimetable, Dashboard.

---

## Platform-Wide P0 Security Issues (from Gap Analysis 2026-03-22)

1. **ROTATE** QuestionBank API keys (OpenAI `sk-proj-...` + Gemini `AIzaSyD-...`) — exposed in source
2. Remove `is_super_admin` from User `$fillable` (SchoolSetup UserController, StudentProfile StudentController)
3. Remove `dd()` from Complaint and LmsExam production code
4. Fix Payment webhook — move route outside `auth` middleware
5. Remove StudentFee seeder route (`GET /student-fee/seeder`)
6. Add `EnsureTenantHasModule` to all 30 module route groups (currently only 1 usage)
7. Fix StudentPortal IDOR on invoice/payment endpoints
