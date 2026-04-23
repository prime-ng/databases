# Modules Map — nwidart/laravel-modules v12.0

## Module Management Commands
```bash
# Create new module
php artisan module:make ModuleName

# Enable/disable
php artisan module:enable ModuleName
php artisan module:disable ModuleName

# Generate components
php artisan module:make-controller ControllerName ModuleName
php artisan module:make-model ModelName ModuleName
php artisan module:make-migration migration_name ModuleName
php artisan module:make-seeder SeederName ModuleName
php artisan module:make-request RequestName ModuleName
php artisan module:make-resource ResourceName ModuleName
php artisan module:make-policy PolicyName ModuleName
php artisan module:make-provider ProviderName ModuleName
php artisan module:make-middleware MiddlewareName ModuleName

# Run module migrations
php artisan module:migrate ModuleName
php artisan module:migrate-rollback ModuleName

# Seed
php artisan module:seed ModuleName
```

## Module Autoloading
- PSR-4 autoloading via each module's `composer.json`
- Service providers registered in `module.json`
- Each module has: `ModuleServiceProvider`, `RouteServiceProvider`, `EventServiceProvider`

## Standard Module Folder Structure
```
Modules/ModuleName/
├── app/
│   ├── Exceptions/
│   ├── Http/
│   │   ├── Controllers/
│   │   ├── Requests/
│   │   └── Middleware/
│   ├── Models/
│   ├── Services/
│   ├── Jobs/
│   ├── Providers/
│   │   ├── ModuleNameServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   └── EventServiceProvider.php
│   └── Emails/
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/
│   └── views/
├── routes/
│   ├── api.php
│   └── web.php
├── tests/
├── config/
├── composer.json
├── module.json
└── vite.config.js
```

## All Modules (37)
> **Audited:** 2026-04-09 against `prime_ai` / branch `student-portal` (code-only re-count).
> Previous audit: 2026-04-02 against `prime_ai` / branch current. Prior: 2026-03-22 on `prime_ai_tarun`.
> Controllers counted recursively under `app/Http/Controllers/`.
> Services count = unique .php files under `app/Services/` (recursive).
> Route lines = sum of line counts across all `*.php` in `Modules/{Name}/routes/` (web.php + api.php).
> Tests = files inside each module's own `tests/` folder only (excludes central `tests/Unit|Feature|Browser/`).

### Global Statistics (2026-04-09 re-count)
| Metric | Count | Δ vs 2026-04-02 |
|--------|-------|-----------------|
| Total Modules | 37 (5 central + 32 tenant, Feedback DDL-only) | — |
| Total Models | 616 | −51 (previous total was inconsistent with row-sum) |
| Total Controllers | 467 | −39 (previous total inconsistent with row-sum) |
| Total Services | 194 (SmartTimetable: 108, HrStaff: 15, Inventory: 14, Hpc: 10, Library: 9, Cafeteria/Admission: 6, FrontOffice: 4, TimetableFoundation/Certificate: 3, others) | −32 |
| Total Views | 2,569 blade files | +316 |
| Total FormRequests | 288 | −4 |
| Total Policies | ~230 (not re-counted — last audit 2026-03-22) | — |
| Tenant Migrations | 375 files in `database/migrations/tenant/` | +26 |
| Module Route Lines | 5,384 across all `routes/*.php` in module dirs | +1,827 (prev count was only counting a subset of files) |
| Module-level Test Files | 80 (excludes central tests/Unit|Feature|Browser/) | −17 (likely previous over-count — some central files were previously attributed here) |
| Total Jobs | 8 (Billing, Certificate, FrontOffice, Hpc, Inventory, Prime, SmartTimetable, Vendor — 1 each) | −3 |
| EnsureTenantHasModule usage | 1 (across entire tenant.php) | — |

### Central-Scoped Modules (run on central domain, access prime_db/global_db)
| Module | Controllers | Models | Services | Requests | Views | Seeders | Route Lines | Tests | Description |
|--------|-------------|--------|----------|----------|-------|---------|-------------|-------|-------------|
| **Prime** | 22 | 27 | 1 | 7 | 97 | 2 | 244 | 9 | Tenant CRUD, plans, billing, users, roles, modules, menus, geography |
| **GlobalMaster** | 15 | 12 | 0 | 10 | 55 | 3 | 52 | 4 | Countries, states, cities, boards, languages, plans, dropdowns |
| **SystemConfig** | 4 | 3 | 0 | 1 | 8 | 2 | 29 | 1 | Settings, menus, translations |
| **Billing** | 7 | 6 | 0 | 3 | 43 | 1 | 18 | 1 | Invoice generation, payment tracking, billing cycles |
| **Documentation** | 3 | 2 | 0 | 2 | 15 | 3 | 16 | 1 | Knowledge base, help docs |

### Tenant-Scoped Modules (run on tenant domain, access tenant_db)
> Audited 2026-04-02. Tests column = files inside `Modules/{Name}/tests/` only (module-level tests). Central tests (Unit/Feature/Browser) are tracked separately in state/progress.md.

| Module | Controllers | Models | Services | Requests | Views | Jobs | Seeders | Route Lines | Tests | Description |
|--------|-------------|--------|----------|----------|-------|------|---------|-------------|-------|-------------|
| **SchoolSetup** | 41 | 42 | 0 | 27 | 223 | 0 | 7 | 585 | 0 | School structure, classes, sections, subjects, teachers, rooms, buildings |
| **SmartTimetable** | 19 | 65 | 108 | 7 | 177 | 1 | 14 | 41 | 0 | AI timetable: FET solver, 24 Hard + 60+ Soft constraint classes, analytics, refinement, substitution |
| **TimetableFoundation** | 24 | 32 | 3 | 4 | 158 | 0 | 1 | 294 | 7 | Shared timetable config: period sets, day types, configurations, academic terms |
| **Transport** | 31 | 36 | 0 | 20 | 151 | 0 | 1 | 296 | 0 | Vehicles, routes, trips, drivers, pickup points, student allocation, inspections |
| **Hpc** | 23 | 32 | 10 | 14 | 242 | 1 | 0 | 270 | 0 | Holistic Progress Card: 4 PDF templates, approval workflow, student/parent/peer portals |
| **Library** | 26 | 35 | 9 | 19 | 140 | 0 | 1 | 274 | 0 | Book catalog, members, transactions, fines, reservations, digital resources, reports |
| **StudentProfile** | 5 | 18 | 1 | 0 | 45 | 0 | 1 | 162 | 0 | Student CRUD, guardians, attendance, medical incidents; +Leave* models (LeaveApplication/Type/Document/Remark — 4 new models since 2026-04-02) |
| **StudentFee** | 15 | 23 | 0 | 0 | 89 | 0 | 1 | 151 | 24 | Fee heads, invoices, receipts, concessions, scholarships, fines, assignments |
| **Syllabus** | 15 | 22 | 1 | 14 | 90 | 0 | 1 | 183 | 0 | Lessons, topics, competencies, bloom taxonomy, cognitive skills, schedules |
| **QuestionBank** | 7 | 16 | 0 | 6 | 38 | 0 | 1 | 96 | 0 | Questions with bloom/cognitive/complexity tagging, AI generation, search. **Stats spec (2026-04-10):** `1-DDL_Tenant_Modules/51-QuestionBank/DDL/statistics_help.md` — full CTT/IRT calculation contract for all 6 metrics in `qns_question_statistics` (difficulty_index, discrimination_index, guessing_factor, min/max/avg_time_taken_seconds, total_attempts). See D31. |
| **LmsExam** | 13 | 11 | 1 | 11 | 73 | 0 | 2 | 170 | 0 | Exam blueprints, paper sets, allocations, scopes, student groups; +GrievanceReviewController, +PaperSetQuestionController, +ExamQueryService, +LmsExamPaperCheckSeeder |
| **LmsQuiz** | 6 | 6 | 1 | 5 | 39 | 0 | 1 | 84 | 0 | Quizzes, questions, allocations, assessment types, difficulty distribution |
| **LmsHomework** | 2 | 3 | 1 | 3 | 20 | 0 | 1 | 65 | 1 | Homework, submissions, action types, trigger events, rule engine |
| **LmsQuests** | 4 | 4 | 1 | 4 | 27 | 0 | 1 | 77 | 0 | Quests, questions, scopes, allocations |
| **Notification** | 12 | 14 | 2 | 10 | 64 | 0 | 1 | 119 | 0 | Channels, templates, targets, delivery; routes currently COMMENTED OUT |
| **Complaint** | 8 | 6 | 2 | 0 | 34 | 0 | 1 | 187 | 0 | Complaints, categories, actions, SLA, AI insights, dashboard |
| **Vendor** | 8 | 8 | 0 | 3 | 42 | 1 | 2 | 84 | 0 | Vendors, agreements, invoices, payments, inspections |
| **Payment** | 2 | 5 | 2 | 1 | 9 | 0 | 1 | 27 | 8 | Payment gateway (Razorpay), processing, callbacks |
| **Recommendation** | 10 | 11 | 0 | 0 | 53 | 0 | 1 | 101 | 0 | Rules, materials, student recommendations |
| **SyllabusBooks** | 4 | 6 | 0 | 3 | 17 | 0 | 1 | 59 | 0 | Books, book-topic mapping, authors |
| **Accounting** | 18 | 21 | 0 | 15 | 124 | 0 | 2 | 202 | 14 | Tally-inspired voucher engine, chart of accounts, ledgers, journal entries |
| **StandardTimetable** | 1 | 0 | 0 | 0 | 3 | 0 | 1 | 38 | 0 | Standard timetable views (skeleton) |
| **StudentPortal** | 14 | 11 | 1 | 5 | 80 | 0 | 1 | 170 | 9 | Student-facing portal — significant growth since 2026-04-02 (was 7/0/0/0). 14 controllers (Notification, ParentResults, ExamAttempt, Grievance, Homework, Leave, Lms, Complaint, Progress, QuestAttempt, QuizAttempt, Teachers, Timetable, Portal). 11 own models (ExamAttempt, QuizQuestAttempt, AttemptActivityLog, AttemptCheckpoint, ExamMarksEntry, ExamResult, ExamGrievance, etc.). 5 FormRequests (RespondToLeaveRemark, SaveAnswer, StartAttempt, StoreLeaveApplication, SubmitAttempt). 1 AllocationService. **Prompt:** `5-Work-In-Progress/StudentPortal/1-Claude_Prompt/STP_2step_Prompt1.md` |
| **Dashboard** | 1 | 0 | 0 | 0 | 8 | 0 | 1 | 39 | 0 | Admin dashboards |
| **Scheduler** | 1 | 2 | 2 | 1 | 6 | 0 | 1 | 14 | 1 | Job scheduling |
| **EventEngine** | 4 | 3 | 0 | 3 | 17 | 0 | 1 | 39 | 0 | Cross-module event system (~20% done) |
| **Admission** | 15 | 20 | 6 | 20 | 46 | 0 | 3 | 220 | 0 | Enquiry→application→shortlist→enroll funnel. Scaffold complete; +3 FormRequests and +12 views since 2026-04-02. **Prompt:** `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/ADM_2step_Prompt1.md` |
| **Cafeteria** | 16 | 21 | 6 | 16 | 62 | 0 | 3 | 169 | 0 | POS counter, meal cards, FSSAI compliance. Scaffold complete. **Prompt:** `5-Work-In-Progress/Cafeteria/1-Claude_Prompt/CAF_2step_Prompt1.md` |
| **Certificate** | 9 | 10 | 3 | 10 | 36 | 1 | 4 | 134 | 0 | Bonafide/TC/Character/Achievement/ID cert lifecycle, HMAC-SHA256 QR. Scaffold complete. **Prompt:** `5-Work-In-Progress/Certificates/1-Claude_Prompt/CRT_2step_Prompt1.md` |
| **FrontOffice** | 20 | 22 | 4 | 3 | 78 | 1 | 3 | 223 | 0 | Reception, postal register, circulars, gate pass, early departure. Scaffold complete. **Prompt:** `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/FOF_2step_Prompt1.md` |
| **HrStaff** | 22 | 33 | 15 | 23 | 92 | 0 | 9 | 240 | 0 | HR + Payroll. PF/ESI/TDS, leave FSM, payroll integration. Scaffold complete. **Prompt:** `5-Work-In-Progress/HrStaff/1-Claude_Prompt/HRS_2step_Prompt1.md` |
| **Inventory** | 20 | 28 | 14 | 18 | 68 | 1 | 5 | 212 | 0 | GRN, stock issue, reorder, vendor integration. Services nearly doubled (7→14): Asset, Godown, GrnPosting, InventoryReport, PurchaseOrder, PurchaseRequisition, Quotation, RateContract, ReorderAlert, StockAdjustment, StockGroup, StockIssue, StockLedger, StockValuation. **Prompt:** `5-Work-In-Progress/22-Inventory/1-Claude_Prompt/INV_2step_Prompt1.md` |
| **Template** | 1 | 1 | 0 | 2 | 11 | 0 | 1 | 16 | 0 | Visual template builder (canvas/HTML). `tmp_templates` exists (Model + Controller + Routes + Views). Template Output Config DDL designed (2026-04-16): `tmp_template_purposes` + `tmp_template_assignments`. tmp_templates migration MISSING. |
| **MarksheetGeneration** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **DDL ONLY (2026-04-13)** — Marksheet computation & result storage (`msh_*`, 23 tables). Config templates, exam groups, class groups, student results, IA marks, co-scholastic. DDL: `1-DDL_Tenant_Modules/LMS_MarksheetGeneration/DDL/MSG_DDL_v1.sql`. Code not yet implemented. |
| **Feedback** | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | **DDL ONLY (2026-04-09)** — Generic cross-entity feedback module (`fbk_*`, 11 tables). Supports Student/Parent→Teacher, NEP 2020 Teacher→Student, NEP 2020 Student→Peer, Student→non-teaching staff (Transport/Canteen/Library/Hostel/Security/Coach), Admin→Teacher, Teacher 360°, Self-Reflection. DDL: `1-DDL_Tenant_Modules/39-Feedback/StudentFeedback_ddl_v2.sql`. Code not yet implemented. |

### Route & Policy Registration Architecture (Post-Migration 2026-04-02)

> Migration prompt: `databases/5-Work-In-Progress/1-Completed/Update_Route_Permission_AllModules/migrate-module-routes-policies_v2.md`
> Executed on: `prime_ai_shailesh` repo (Shailesh's working copy), 2026-04-02
> Verified: `tenant.php` reduced from 3,039 → 224 lines; `AppServiceProvider.php` from ~923 → 127 lines

**Canonical route file per tenant module:** `Modules/{ModuleName}/routes/web.php`

**Canonical policy file per tenant module:** `Modules/{ModuleName}/app/Providers/{ModuleName}ServiceProvider.php`
- Each module's `{Module}ServiceProvider::boot()` calls `$this->registerPolicies()`
- `registerPolicies()` method holds all `Gate::policy(Model::class, Policy::class)` for that module

**`routes/tenant.php` — remaining contents (224 lines, post-migration):**
- Full tenancy middleware wrapper: `web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive`
- Auth routes: login, register, forgot-password, reset-password, email-verification, logout
- 1 cross-module route: `school-setup.student.create1` (uses `StudentController` from StudentProfile)
- Empty standard-timetable group (placeholder)
- ⚠️ **14 seeder routes with NO auth** (lines 207–224) — P0 SEC-RTG-001 still open
- All other module route groups replaced with comments: `// {Module} routes → Modules/{Module}/routes/web.php`

**`app/Providers/AppServiceProvider.php` — remaining contents (127 lines, post-migration):**
- All `Gate::policy(...)` calls replaced with comments: `// {Module} policies → Modules/{Module}/app/Providers/{Module}ServiceProvider.php`
- Cross-module policies only (if any) remain in AppServiceProvider

**Module RSP loading:** Each module's `RouteServiceProvider` loads `Modules/{Module}/routes/web.php`.
> ⚠️ RSP tenancy middleware gap (D23) still applies — Scheduler and EventEngine RSPs apply only `web` middleware, no `InitializeTenancyByDomain`.

---

### Key Module Routes

| Module | Route Prefix | Key Endpoints |
|--------|-------------|---------------|
| Prime (Central) | `/prime/*` | tenants, users, roles, billing, boards, academic-sessions, dropdowns |
| GlobalMaster (Central) | `/global-master/*` | countries, states, cities, boards, languages, modules, plans |
| Billing (Central) | `/billing/*` | billing-management, subscription, invoicing-payment, billing-cycle |
| Accounting | `/accounting/*` | chart-of-accounts, ledgers, vouchers, journal-entries, reports |
| SchoolSetup | `/school-setup/*` | organization, class, section, subject, teacher, room, building, department, designation |
| SmartTimetable | `/smart-timetable/*` | timetable, activity, period-set, constraint, teacher-availability, school-day, tt-config |
| TimetableFoundation | `/timetable-foundation/*` | period-sets, day-types, configurations, academic-terms, generation-strategies |
| StudentProfile | `/student/*` | students, attendance, medical-incident, reports |
| Feedback (planned) | `/feedback/*` | cycles, templates, questions, responses, summary — generic cross-entity feedback (NEP 2020) |
| StudentFee | `/student-fee/*` | fee-head-master, fee-invoice, fee-receipt, concession, scholarship, fine |
| Transport | `/transport/*` | vehicle, route, trip, driver-helper, pickup-point, student-allocation, vehicle-inspection |
| Syllabus | `/syllabus/*` | lesson, topic, competency, bloom-taxonomy, cognitive-skill, study-material |
| QuestionBank | `/question-bank/*` | questions, tags, statistics, AI generation |
| LmsExam | `/exam/*` | exams, papers, allocations, blueprints |
| LmsQuiz | `/quiz/*` | quizzes, questions, allocations |
| LmsHomework | `/homework/*` | homework, submissions, rules |
| LmsQuests | `/quests/*` | quests, questions, scopes |
| HPC | `/hpc/*` | hpc, templates, hpc-form, generate-report, circular-goals, learning-outcomes, hpc-parameters, student-hpc-evaluation, learning-activities |
| Complaint | `/complaint/*` | complaints, categories, actions, sla, dashboard |
| Notification | `/notification/*` | channels, templates, targets, delivery |
| Vendor | `/vendor/*` | vendors, agreements, invoices, payments |
| Payment | `/payment/*` | payment processing, gateway config |
| Recommendation | `/recommendation/*` | rules, materials, student-recommendations |
| StudentPortal | `/student-portal/*` | dashboard, academic-info, payments |
| SystemConfig | `/system-config/*` | settings, menus |

### Planned Modules (Requirements Complete, Development Pending)
| Prefix | Module | Code | V2 Req Doc | Tables | Notes |
|--------|--------|------|-----------|--------|-------|
| `acc_` | **FinanceAccounting** | `Modules/Accounting/` (partial — 18 ctrl, 21 mdl, ~30%) | `V2/FAC_FinanceAccounting_Requirement.md` | 21 acc_* + 3 proposed | Tally-inspired voucher engine. Code uses `acc_*` prefix not `fac_*`. |
| `hrs_` | **HrStaff** | Not created | `V2/HRS_HrStaff_Requirement.md` | 15 hrs_* | PF/ESI/TDS compliance, leave FSM, payroll integration |
| `inv_` | **Inventory** | Not created | `V2/INV_Inventory_Requirement.md` | 28 inv_* | 65 routes, 5 FSMs, D21 event contracts. **Prompt ready:** `5-Work-In-Progress/22-Inventory/1-Claude_Prompt/INV_2step_Prompt1.md` |
| `hst_` | **Hostel** | Not created | `V2/HST_Hostel_Requirement.md` | 21 hst_* (spec says 20; DDL Section 5 has 21 incl. hst_room_inventory) | Building→Floor→Room→Bed hierarchy, warden rotation, 7 services, dual active-allotment UNIQUE constraints, leave-pass approval in DB::transaction. **Prompt ready:** `5-Work-In-Progress/Hostel/1-Claude_Prompt/HST_2step_Prompt1.md` |
| `com_` | **Communication** | Not created | `V2/COM_Communication_Requirement.md` | 14 com_* | DLT-compliant SMS, 7-state delivery FSM |
| `lxp_` | **LearningExperience** | Not created | `V2/LXP_Lxp_Requirement.md` | 19 lxp_* | Personalized paths, gamification, mentorship |
| `pan_` | **PredictiveAnalytics** | Not created | `V2/PAN_PredictiveAnalytics_Requirement.md` | 12 pan_* | Dropout/fee/attendance prediction, PAN→REC pipeline |
| `crt_` | **Certificate** | Not created | `V2/CRT_Certificate_Requirement.md` | 10 crt_* | End-to-end certificate lifecycle (Bonafide, TC, Character, Achievement, ID Cards). HMAC-SHA256 verification hash on every cert (APP_KEY). QR via SimpleSoftwareIO → no-login public `/verify/{hash}` endpoint. DomPDF for all PDFs. TC fee-clear gate (BR-CRT-001: blocks if fin_fee_dues > 0). TC → writes `std_students.tc_issued=true` + status=withdrawn (BR-CRT-011 — direct write, not event). Serial counter uses SELECT FOR UPDATE (BR-CRT-015: race condition prevention). Bulk generation > 200 = queue mandatory (BR-CRT-009); BulkGenerateCertificatesJob + `crt_bulk_jobs` tracker. `crt_template_versions`: NO deleted_at (immutable archive). All crt_* PKs BIGINT UNSIGNED. 9 controllers, 3 services (CertificateGenerationService, QrVerificationService, DmsService), 10 FormRequests, 8 policies, 1 job, ~58 web + 2 API routes, ~30 views, 26 screens. 2 seeders: CrtCertificateTypeSeeder (5 types) + CrtTemplateSeeder (5 starter templates). Public verification: response DTO exposes first name + last initial only (BR-CRT-010). **Prompt ready:** `5-Work-In-Progress/Certificates/1-Claude_Prompt/CRT_2step_Prompt1.md` |
| `ppt_` | **ParentPortal** | Not created | `V2/PPT_ParentPortal_Requirement.md` | 6 ppt_* | OTP login, multi-child (active_student_id in ppt_parent_sessions DB — not PHP session), PTM scheduling, PWA push (FCM/APNs/WebPush). P0 IDOR: ParentChildPolicy on EVERY data endpoint (BR-PPT-012). Custom `parent.portal` middleware (user_type=PARENT + guardian + child access — returns 404 not 403). All ppt_* PKs INT UNSIGNED. Razorpay idempotent (payment_reference UNIQUE nullable). DomPDF for receipts + signed URLs for document downloads (24h via Storage::temporaryUrl()). Counsellor reports default-hidden (school setting gate). 16 controllers, 5 services, 9 FormRequests, 3 policies, ~75 web + ~18 API routes, ~45 views, 38 screens, 6 ppt_* tables. **Prompt ready:** `5-Work-In-Progress/ParentPortal/1-Claude_Prompt/PPT_2step_Prompt1.md` |
| `caf_` | **Cafeteria** | Not created | `V2/CAF_Cafeteria_Requirement.md` | 21 caf_* | POS counter, FSSAI compliance, QR meal scan. All caf_* PKs INT UNSIGNED (not BIGINT). Atomic balance deduction SELECT...FOR UPDATE. Razorpay webhook idempotent (razorpay_payment_id UNIQUE). HST bridge (auto mess enrollment). INV bridge (PR on reorder). SimpleSoftwareIO/simple-qrcode for QR. **Prompt ready:** `5-Work-In-Progress/Cafeteria/1-Claude_Prompt/CAF_2step_Prompt1.md` |
| `vsm_` | **VisitorSecurity** | Not created | `V2/VSM_VisitorSecurity_Requirement.md` | 13 vsm_* | Gate security, contractor access, lockdown mode. 4 domain groups: Visitor Core (vsm_visitors, vsm_visits, vsm_gate_passes), Access Control (vsm_contractors, vsm_pickup_auth, vsm_blacklist), Guard Ops (vsm_guard_shifts, vsm_patrol_checkpoints, vsm_patrol_rounds, vsm_patrol_checkpoint_log), Emergency+CCTV (vsm_emergency_protocols, vsm_emergency_events, vsm_cctv_events). All vsm_* PKs BIGINT UNSIGNED. UUID v4 gate pass tokens (Str::uuid() — never sequential, BR-VSM-002). DB::transaction+lockForUpdate on check-in (BR-VSM-003 race condition). vsm_patrol_checkpoint_log + vsm_cctv_events: NO updated_at, NO deleted_at (immutable audit logs). 4 services: VisitorService, SecurityAlertService (dedicated 'emergency' queue, bypasses rate limiting), PatrolService, ContractorAccessService. 4 scheduled jobs: FlagOverdueVisitorsJob (every 15 min), ExpireGatePassesJob (hourly), ExpireBlacklistEntriesJob (daily midnight), ExpireContractorPassesJob (daily 00:01). SimpleSoftwareIO/simple-qrcode for gate passes + patrol QR. DomPDF for visitor badges + reports. 2 seeders: VsmEmergencyProtocolSeeder (5 SOP templates) + VsmPatrolCheckpointSeeder (4 checkpoints). Public gate pass scan route (no auth). CCTV webhook POST (no auth + X-CCTV-Secret header). 9 controllers, 10 FormRequests, 8 policies, ~70 web + 12 API routes, ~32 views, 25 screens. **Prompt ready:** `5-Work-In-Progress/VisitorSecurity/1-Claude_Prompt/VSM_2step_Prompt1.md` |
| `mnt_` | **Maintenance** | Not created | `V2/MNT_Maintenance_Requirement.md` | 11 mnt_* | Ticketed facility helpdesk + PM + AMC. 4 domain groups: Asset Mgmt (mnt_asset_categories, mnt_assets, mnt_asset_depreciation), Tickets (mnt_tickets, mnt_ticket_assignments, mnt_ticket_time_logs, mnt_breakdown_history), PM (mnt_pm_schedules, mnt_pm_work_orders), Contracts (mnt_amc_contracts, mnt_work_orders). All mnt_* PKs INT UNSIGNED. mnt_asset_depreciation + mnt_breakdown_history: NO deleted_at (immutable records). Ticket number MNT-YYYY-XXXXXXXX via DB lock-for-update (BR-MNT-001). SLA escalation levels via sla_escalation_json on categories (BR-MNT-011); EscalationService sets escalation_level flag. QR auto-generated on asset save via SimpleSoftwareIO (BR-MNT-015). Breakdown history auto-inserted on Resolved with asset_id (BR-MNT-014). AMC alerts fire once per threshold — renewal_alert_sent_60/30/7 flags (BR-MNT-007). DomPDF for work order PDF. Mobile API 9 endpoints (auth:sanctum). 4 scheduled jobs: GeneratePmWorkOrdersJob (daily 06:00), CheckSlaBreachesJob (every 30 min), SendAmcExpiryAlertsJob (daily 08:00), MarkOverduePmWorkOrdersJob (daily 07:00). 9 controllers (8 web + 1 mobile API), 5 services (TicketService, AssignmentService, PmScheduleService, EscalationService, DepreciationService), 11 FormRequests, 11 policies, ~55 web + ~9 API routes, ~35 views, 25 screens. 2 seeders: MntAssetCategorySeeder (9 categories with keyword JSON). **Prompt ready:** `5-Work-In-Progress/Maintenance/1-Claude_Prompt/MNT_2step_Prompt1.md` |
| `adm_` | **Admission** | Not created | `V2/ADM_Admission_Requirement.md` | 20 adm_* | Enquiry→application→shortlist→enroll funnel. Atomic enrollment via DB::transaction (sys_users + std_students + std_student_academic_sessions). Payment webhook idempotent (Razorpay/PayU). **Prompt ready:** `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/ADM_2step_Prompt1.md` |
| `att_` | **Attendance** | Not created (basic in STD) | `V2/ATT_Attendance_Requirement.md` | 14 att_* | Supersedes STD's zero-auth AttendanceController |
| `acd_` | **Academics** | Not created | `V2/ACD_Academics_Requirement.md` | 31 acd_* | Lesson plans, teaching diary, academic alerts |
| `exa_` | **Examination** | Not created | `V2/EXA_Examination_Requirement.md` | 22 exa_* | Offline exams, mark entry, report cards (distinct from EXM) |
| `fof_` | **FrontOffice** | Not created | `V2/FOF_FrontOffice_Requirement.md` | 22 fof_* | Reception, postal register, circulars, certificates (DomPDF), early departure ATT sync, public feedback token URL. **Prompt ready:** `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/FOF_2step_Prompt1.md` |

### Key Architecture: Voucher Engine (shared by Accounting, Payroll, Inventory)
- Accounting owns `acc_vouchers` + `acc_voucher_items` (double-entry Dr/Cr)
- Payroll fires `PayrollApproved` event → Accounting creates Payroll Journal Voucher
- Inventory fires `GrnAccepted`/`StockIssued` events → Accounting creates Purchase/Stock Journal Vouchers
- StudentFee fires `FeePaymentReceived` → Accounting creates Receipt Voucher
- Transport fires `TransportFeeCharged` → Accounting creates Sales Voucher
- Shared contract: `VoucherServiceInterface` in Accounting module

> **V2 Requirement Library:** All 46 modules have V2 requirement documents in `{REQUIRE_DETAIL_V2}/`.
> See `{REQUIRE_DETAIL_V2}/_00_Master_Requirement_Index_2026-03-26.md` for full index.
> See `{REQUIRE_DETAIL_V2}/_01_Cross_Module_Dependencies_2026-03-26.md` for dependency map.
> See `{REQUIRE_DETAIL_V2}/_02_RBS_Coverage_Report_2026-03-26.md` for RBS coverage analysis.

### API Endpoints
All module APIs follow: `auth:sanctum` + `/v1/{module_plural}` + standard apiResource CRUD (index, store, show, update, destroy)
Modules WITHOUT active API routes: Billing, Notification, Vendor, LmsExam, LmsHomework, LmsQuests, Recommendation, SyllabusBooks, Documentation, Scheduler, SystemConfig
