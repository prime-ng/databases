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

## All Modules (47)
> **Audited:** 2026-07-24 against `prime_ai` / branch `main` (Phase-1 code-only re-count, Tier-6 Full Scan).
> Previous audit: 2026-06-21 against `prime_ai` / branch `Brijesh`. Prior: 2026-04-09 against `prime_ai` / branch `student-portal`; 2026-04-02 against `prime_ai`.
> **+2 modules vs 2026-06-21:** `Maintenance` (backup/restore subsystem split out of SystemConfig — `sys_backup_*`/`sys_restore_*` tables) and `TenantCore` (centralized tenant `ActivityLog` — 2 ctrl, 1 mdl).
> All 47 modules are enabled (`module.json` active — none disabled).
> Controllers counted recursively under `app/Http/Controllers/`.
> Services count = unique .php files under `app/Services/` (recursive).
> Route lines = sum of line counts across all `*.php` in `Modules/{Name}/routes/` (web.php + api.php).
> Tests = files inside each module's own `tests/` folder only (excludes central `tests/Unit|Feature|Browser/`).

### Global Statistics (2026-07-24 re-count — branch `main`)
| Metric | Count | Δ vs 2026-06-21 (branch `Brijesh`) |
|--------|-------|-----------------|
| Total Modules | 47 (5 central + 42 tenant) | +2 (Maintenance, TenantCore) |
| Total Models | 758 | −48 (branch delta: main vs Brijesh — Dashboard/others differ; no sub-dir models, maxdepth1==recursive) |
| Total Controllers | 751 | +4 |
| Total Services | 344 | +26 |
| Total Views | 3,749 blade files | −15 |
| Total FormRequests | 513 | +62 |
| Total Policies | 496 (actual re-count under `app/Policies/`) | +266 vs prior ~230 estimate |
| Tenant Migrations | 728 files in `database/migrations/tenant/` | +120 |
| Module-local Migrations | 59 (Prime 29, GlobalMaster 17, Maintenance 5, Documentation 3, Scheduler 2, LmsHomework 2, HrStaff 1) | — |
| Central Migrations (`database/migrations/*.php`) | 15 | — |
| Module Route Lines | 7,905 across all `routes/*.php` in module dirs | −410 |
| Total Seeders | 311 | — |
| Total Jobs | 18 (Billing, Certificate, FrontOffice, Hostel×2, Hpc, Inventory, Maintenance, MarksheetGeneration, Notification×2, Payment, Prime, Ptm, QuestionBank, SmartTimetable, StudentFee, Vendor) | +5 (Maintenance, Ptm, QuestionBank, Notification 2nd, StudentFee added; SystemConfig job moved to Maintenance) |
| EnsureTenantHasModule usage | 5 route files use `EnsureTenantHasModule`/`module:` alias | +4 (improvement — was 1) |

> **Branch note:** This re-count is on `main`; the 2026-06-21 figures were on `Brijesh`. Model/view/route-line decreases are branch divergence, NOT regressions — treat `main` as the current source of truth. Deep-audit %s (Phase 2 / Mode X) are unaffected by these structural counts.

### Central-Scoped Modules (run on central domain, access prime_db/global_db)
| Module | Controllers | Models | Services | Requests | Views | Seeders | Route Lines | Tests | Description |
|--------|-------------|--------|----------|----------|-------|---------|-------------|-------|-------------|
| **Prime** | 22 | 27 | 1 | 7 | 97 | 2 | 244 | 9 | Tenant CRUD, plans, billing, users, roles, modules, menus, geography |
| **GlobalMaster** | 15 | 12 | 0 | 10 | 55 | 3 | 52 | 4 | Countries, states, cities, boards, languages, plans, dropdowns |
| **SystemConfig** | 13 | 8 | 2 | 4 | 36 | 2 | 50 | 1 | Settings, menus, translations. **~65-70% complete** (BA 2026-06-30). 5 P0 gaps. ~46 hrs. FRD: `SYS_FRD_2026-06-30.md`. |
| **Billing** | 7 | 6 | 0 | 3 | 43 | 1 | 18 | 1 | Invoice generation, payment tracking, billing cycles |
| **Documentation** | 3 | 2 | 0 | 2 | 15 | 3 | 16 | 1 | Knowledge base, help docs |

### Tenant-Scoped Modules (run on tenant domain, access tenant_db)
> Audited 2026-04-02. Tests column = files inside `Modules/{Name}/tests/` only (module-level tests). Central tests (Unit/Feature/Browser) are tracked separately in state/progress.md.

| Module | Controllers | Models | Services | Requests | Views | Jobs | Seeders | Route Lines | Tests | Description |
|--------|-------------|--------|----------|----------|-------|------|---------|-------------|-------|-------------|
| **SchoolSetup** | 70 | 69 | 3 | 31 | 357 | 0 | 8 | 823 | 0 | School structure, classes, sections, subjects, teachers, rooms, buildings. Employee leave management DDL (25 tables). PTM DDL v2 (10 tables). **~62% complete** (BA 2026-06-30). 4 P0 gaps. ~49 dev-days to close. `is_super_admin` in User model `$fillable` — P0 priv-esc. FRD: `SCH_FRD_2026-06-30.md`. |
| **SmartTimetable** | 18 | 63 | 111 | 13 | 178 | 1 | 14 | 188 | 0 | AI timetable: FET solver, 24 Hard + 60+ Soft constraint classes, analytics, refinement, substitution. **~68% complete** (BA 2026-06-30). 5 P0 gaps. 192 hrs to close. FRD: `STT_FRD_2026-06-30.md`. |
| **TimetableFoundation** | 27 | 34 | 5 | 4 | 172 | 0 | 1 | 333 | 7 | Shared timetable config: period sets, day types, configurations, academic terms. **~68% complete** (BA 2026-06-30). 4 P0 gaps, ~70 hrs. Mandatory infrastructure for STT and TTS. 19 of 23 policies unregistered (P0 — Gate::policy() duplicate overwrites). Prefix: `tt_*`. FRD: `TTF_FRD_2026-06-30.md`. |
| **Transport** | 32 | 36 | 0 | 20 | 151 | 0 | 2 | 364 | 0 | Vehicles, routes, trips, drivers, pickup points, student allocation, inspections |
| **Hpc** | 23 | 32 | 10 | 14 | 242 | 1 | 0 | 270 | 0 | Holistic Progress Card: 4 PDF templates, approval workflow, student/parent/peer portals |
| **Library** | 39 | 51 | 12 | 27 | 210 | 0 | 3 | 401 | 0 | Book catalog, members, transactions, fines, reservations, digital resources, reports |
| **StudentProfile** | 9 | 19 | 1 | 1 | 70 | 0 | 1 | 215 | 0 | Student CRUD, guardians, attendance, medical incidents; Leave subsystem (models only, no routes). **Completion TBD** (BA 2026-06-30). 3 P0 gaps. ~59 dev-days. `is_super_admin` in User model `$fillable` — P0 priv-esc. FRD: `STD_FRD_2026-06-30.md`. |
| **StudentFee** | 15 | 24 | 3 | 0 | 89 | 0 | 1 | 151 | 24 | Fee heads, invoices, receipts, concessions, scholarships, fines, assignments. **~78% complete** (BA 2026-06-30). 9 P0 gaps (highest count across all 13 modules). ~32 dev-days. FRD: `FIN_FRD_2026-06-30.md`. |
| **Syllabus** | 15 | 22 | 1 | 15 | 90 | 0 | 1 | 183 | 0 | Lessons, topics, competencies, bloom taxonomy, cognitive skills, schedules. **~78% complete** (BA 2026-06-30). 6 P0 gaps. 15 FormRequests with `authorize(){return true;}` (D30 pattern). FRD: `SLB_FRD_2026-06-30.md`. |
| **QuestionBank** | 7 | 16 | 2 | 6 | 45 | 0 | 1 | 116 | 0 | Questions with bloom/cognitive/complexity tagging, AI generation, search. Stats spec: `51-QuestionBank/DDL/statistics_help.md`. **~50% complete** (BA 2026-06-30). 6 P0 gaps. ~112 hrs. QuestionBankPolicy dead — overwritten by duplicate Gate::policy() registration. FRD: `QNS_FRD_2026-06-30.md`. |
| **LmsExam** | 13 | 13 | 11 | 12 | 91 | 0 | 3 | 214 | 0 | Exam blueprints, paper sets, allocations, scopes, student groups; GrievanceReviewController; PaperSetQuestionController; ExamQueryService |
| **LmsQuiz** | 6 | 6 | 7 | 5 | 42 | 0 | 1 | 94 | 0 | Quizzes, questions, allocations, assessment types, difficulty distribution |
| **LmsHomework** | 2 | 3 | 2 | 3 | 20 | 0 | 1 | 67 | 1 | Homework, submissions, action types, trigger events, rule engine |
| **LmsQuests** | 4 | 4 | 5 | 4 | 30 | 0 | 1 | 85 | 0 | Quests, questions, scopes, allocations |
| **Notification** | 12 | 14 | 2 | 10 | 64 | 0 | 1 | 119 | 0 | Channels, templates, targets, delivery; routes currently COMMENTED OUT |
| **Complaint** | 10 | 6 | 2 | 2 | 36 | 0 | 1 | 220 | 0 | Complaints, categories, actions, SLA, AI insights, dashboard |
| **Vendor** | 8 | 8 | 0 | 3 | 42 | 1 | 2 | 84 | 0 | Vendors, agreements, invoices, payments, inspections. **~50% complete**. Mode X Audit 2026-06-30: **Health 35/100 — NO-GO**. 4×P0: EnsureTenantHasModule absent; `pan_number`/`bank_account_no` plaintext (DPDPA); `balance_due` plain DECIMAL (DDL says GENERATED STORED — stale DB column); payment race condition (no lockForUpdate). 8×P1 incl. SendVendorInvoiceEmailJob (no tenancy, no retry, sends to admin), generateMultiple() failure masking, missing toggleStatus method, Transport hard-import in VndAgreement. CLEARED: all 14+ VendorInvoiceController Gate calls now active; GAP-VND-05/24 cleared. ABOVE BASELINE: 7 policies, zero duplicate kills. No FRD exists. Report: `Vendor_Complete_Audit_2026-06-30.md`. |
| **Payment** | 4 | 8 | 4 | 3 | 9 | 1 | 1 | 52 | 8 | Payment gateway (Razorpay), processing, callbacks |
| **Recommendation** | 10 | 10 | 1 | 18 | 49 | 0 | 1 | 111 | 0 | Rules, materials, student recommendations |
| **SyllabusBooks** | 11 | 13 | 3 | 8 | 30 | 0 | 1 | 112 | 0 | Books, book-topic mapping, authors. **~70-75% complete** (BA 2026-06-30). 5 P0 gaps. 3 controllers import `Modules\Prime\Models\AcademicSession` (prime_db) instead of tenant `OrganizationAcademicSession` — P0 cross-layer data isolation breach. FRD: `SLK_FRD_2026-06-30.md`. |
| **Accounting** | 21 | 25 | 7 | 17 | 141 | 0 | 2 | 228 | 14 | Tally-inspired voucher engine, chart of accounts, ledgers, journal entries |
| **StandardTimetable** | 1 | 0 | 0 | 0 | 3 | 0 | 1 | 38 | 0 | Standard timetable views (skeleton). **~15% complete** (BA 2026-06-30). 5 P0 gaps. ~150 hrs. Near-greenfield — requires TimetableFoundation (TTF) as mandatory infrastructure. FRD: `TTS_FRD_2026-06-30.md`. |
| **StudentPortal** | 37 | 11 | 1 | 5 | 98 | 0 | 1 | 304 | 9 | Student-facing portal. 37 controllers (major growth). Includes Api/ and Mobile/ sub-dirs. **~75-80% complete** (BA 2026-06-30). 4 P0 gaps. ~77.5 hrs. Confirmed ACTIVE — was incorrectly labelled "Pending" in CLAUDE.md. FRD: `STP_FRD_2026-06-30.md`. |
| **Dashboard** | 26 | 0 | 0 | 0 | 85 | 0 | 1 | 142 | 0 | Admin dashboards — major growth (was 1 ctrl, now 26) |
| **Scheduler** | 1 | 2 | 2 | 1 | 6 | 0 | 1 | 14 | 1 | Job scheduling |
| **EventEngine** | 4 | 3 | 0 | 3 | 17 | 0 | 1 | 39 | 0 | Cross-module event system (~20% done) |
| **Admission** | 18 | 20 | 6 | 24 | 84 | 0 | 3 | 259 | 0 | Enquiry→application→shortlist→enroll funnel. All 18 controllers routed. **Prompt:** `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/ADM_2step_Prompt1.md` |
| **Cafeteria** | 16 | 21 | 6 | 19 | 95 | 0 | 6 | 189 | 0 | POS counter, meal cards, FSSAI compliance. **Prompt:** `5-Work-In-Progress/Cafeteria/1-Claude_Prompt/CAF_2step_Prompt1.md` |
| **Certificate** | 10 | 10 | 3 | 10 | 39 | 1 | 4 | 142 | 0 | Bonafide/TC/Character/Achievement/ID cert lifecycle, HMAC-SHA256 QR. **Prompt:** `5-Work-In-Progress/Certificates/1-Claude_Prompt/CRT_2step_Prompt1.md` |
| **FrontOffice** | 21 | 22 | 4 | 10 | 118 | 1 | 3 | 310 | 0 | Reception, postal register, circulars, gate pass, early departure. **Prompt:** `5-Work-In-Progress/FrontOffice/1-Claude_Prompt/FOF_2step_Prompt1.md` |
| **HrStaff** | 22 | 33 | 15 | 23 | 93 | 0 | 9 | 242 | 0 | HR + Payroll. PF/ESI/TDS, leave FSM, payroll integration. **Prompt:** `5-Work-In-Progress/HrStaff/1-Claude_Prompt/HRS_2step_Prompt1.md` |
| **Inventory** | 20 | 28 | 14 | 18 | 77 | 1 | 5 | 229 | 0 | GRN, stock issue, reorder, vendor integration. **Prompt:** `5-Work-In-Progress/22-Inventory/1-Claude_Prompt/INV_2step_Prompt1.md` |
| **Template** | 5 | 6 | 3 | 10 | 31 | 0 | 4 | 63 | 0 | Visual template builder (canvas/HTML). Platform rendering engine: consumed by MSH, STD, FIN, EXM, CRT. Stateless singleton via `TemplateEngine::render()`. **~68% complete**. Mode X Audit 2026-06-30: **Health 40/100 — NO-GO**. 3×P0: EnsureTenantHasModule absent; `class_group_id` fallback missing from `resolveTemplate()` (group-scoped assignments silently fail); `value_type` column missing from `tmp_template_variables` migration (image/html rendering permanently broken). 7×P1 incl. SQL injection in DB introspection endpoints (SEC-TMP-01), cross-tenant schema leak via getDatabases() (SEC-TMP-02), missing uploadImage Gate (SEC-TMP-03). CLEARED: GAP-TMP-07 (config/template.php exists), GAP-TMP-10 (compound unique in StoreTemplateVariableRequest confirmed). Prefix: `tmp_*`. FRD: `TMP_FRD_2026-06-30.md`. Report: `TMP_Template_Complete_Audit_2026-06-30.md`. |
| **MarksheetGeneration** | 21 | 24 | 33 | 19 | 98 | 1 | 4 | 180 | 0 | **Graduated from DDL-only (2026-06-21).** Marksheet computation & result storage (`msh_*`, 23 tables). Full code scaffold now present. DDL: `1-DDL_Tenant_Modules/55h-MarksheetGeneration/`. |
| **Feedback** | 10 | 11 | 6 | 1 | 51 | 0 | 4 | 171 | 0 | **Graduated from DDL-only (2026-06-21).** Generic cross-entity feedback (`fbk_*`, 11 tables). Code scaffold now present. DDL: `1-DDL_Tenant_Modules/39-Feedback/StudentFeedback_ddl_v2.sql`. |
| **Hostel** | 53 | 44 | 22 | 38 | 278 | 2 | 8 | 573 | 0 | **NEW (2026-06-21).** Hostel Management — buildings, floors, rooms, beds, allotments, attendance, mess, fee, complaints, sick bay. 36-table DDL (HST_DDL_v3.sql). Prefix: `hst_`. **Prompt:** `5-Work-In-Progress/Hostel/1-Claude_Prompt/HST_2step_Prompt1.md` |
| **ParentPortal** | 28 | 6 | 1 | 0 | 45 | 0 | 1 | 267 | 0 | **NEW (2026-06-21).** Parent Portal — attendance, results, homework, fees, timetable, leave, notifications for linked children. OTP login. Prefix: `ppt_`. **Prompt:** `5-Work-In-Progress/ParentPortal/1-Claude_Prompt/PPT_2step_Prompt1.md` |
| **BehaviouralAssessment** | 12 | 16 | **1** | 5 | 65 | 0 | 4 | 119 | 0 | Student behavioral assessment (`bha_*`). 16 tables (DDL v2, 6 dep layers). 24 screen specs in `2-Module_Requirement_V1/BehaviouralAssessment_v2/` — no consolidated V2 req. 0 tests (critical gap). Only `BehaviouralScoreService` exists (corrected from 4). ComputeSchoolScoresJob missing. 3 FormRequests missing. ~50–55% complete. Knowledge: `AI_Brain/module-knowledge/BHA_BehaviouralAssessment.md`. FRD pending. |
| **CommonChat** | 15 | 9 | 1 | 5 | 19 | 0 | 1 | 121 | 0 | **NEW (2026-06-21).** Standalone direct-messaging and group-chat for all registered users within a school tenant. |
| **Ptm** | 11 | 9 | 6 | 20 | 58 | 0 | 1 | 103 | 0 | **NEW (2026-06-21).** Parent-Teacher Meeting scheduling. Previously a sub-module DDL of SchoolSetup (ptm_setup_ddl_v2.sql), now a standalone module. Prefix: `ptm_`. |
| **Maintenance** | 4 | 3 | 6 | 3 | 9 | 1 | — | 45 | 2 | **NEW (2026-07-24).** System Maintenance — Backup & Restore, scheduled backups, remote path/all-tenants support. Split out of SystemConfig's BackupController subsystem (addresses SEC-SYS-28/29/30). 5 module-local migrations: `sys_backup_runs`, `sys_backup_schedules`, `sys_restore_logs`. Prefix: `sys_backup_*`/`sys_restore_*`. Job: backup runner. **Deep audit pending.** |
| **TenantCore** | 2 | 1 | 0 | 0 | 3 | 0 | — | 16 | 0 | **NEW (2026-07-24).** Centralized tenant `ActivityLog` (ActivityLogController + TenantCoreController). Infrastructure module — likely intended to consolidate the per-module activityLog pattern. `priority: 0`, empty description. **Deep audit pending.** |

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

### Planned Modules (Requirements Complete, Development NOT YET Started)
> Modules below have NO code yet. Modules that had code scaffolded are in the main table above (Accounting, HrStaff, Inventory, Hostel, Certificate, ParentPortal, Cafeteria, FrontOffice, Admission all graduated to main table by 2026-06-21).

| Prefix | Module | V2 Req Doc | Tables | Notes |
|--------|--------|-----------|--------|-------|
| `com_` | **Communication** | `V2/COM_Communication_Requirement.md` | 14 com_* | DLT-compliant SMS, 7-state delivery FSM |
| `lxp_` | **LearningExperience** | `V2/LXP_Lxp_Requirement.md` | 19 lxp_* | Personalized paths, gamification, mentorship |
| `pan_` | **PredictiveAnalytics** | `V2/PAN_PredictiveAnalytics_Requirement.md` | 12 pan_* | Dropout/fee/attendance prediction, PAN→REC pipeline |
| `vsm_` | **VisitorSecurity** | `V2/VSM_VisitorSecurity_Requirement.md` | 13 vsm_* | Gate security, contractor access, lockdown mode. UUID gate pass tokens, immutable audit logs. **Prompt ready:** `5-Work-In-Progress/VisitorSecurity/1-Claude_Prompt/VSM_2step_Prompt1.md` |
| `mnt_` | **Maintenance** | `V2/MNT_Maintenance_Requirement.md` | 11 mnt_* | Ticketed facility helpdesk + PM + AMC. Immutable: mnt_asset_depreciation, mnt_breakdown_history. **Prompt ready:** `5-Work-In-Progress/Maintenance/1-Claude_Prompt/MNT_2step_Prompt1.md` |
| `att_` | **Attendance** | `V2/ATT_Attendance_Requirement.md` | 14 att_* | Supersedes STD's zero-auth AttendanceController |
| `acd_` | **Academics** | `V2/ACD_Academics_Requirement.md` | 31 acd_* | Lesson plans, teaching diary, academic alerts |
| `exa_` | **Examination** | `V2/EXA_Examination_Requirement.md` | 22 exa_* | Offline exams, mark entry, report cards (distinct from EXM) |

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

---

## Module Completion Status Index (2026-06-30 BA Complete Analysis Packs)

> Source: `pa-business-analyst` Complete Analysis Pack Mode runs on 2026-06-30.
> FRDs saved to `0-FRD_Documents/{CODE}_FRD_2026-06-30.md`.
> Complete Analysis Packs saved to `0-FRD_Documents/{CODE}_FRD_Complete_2026-06-30.md`.
> "P0 gaps" = critical blockers (security, data integrity, compliance). "Effort" = remaining dev work.

| Code | Module | Completion | P0 Gaps | Effort Remaining | Notable Finding |
|------|--------|-----------|---------|------------------|-----------------|
| SCH | SchoolSetup | 62% | 4 | ~49 dev-days | `is_super_admin` in `$fillable` — P0 priv-esc |
| STT | SmartTimetable | 68% | 5 | 192 hrs | FET solver untested, gate calls absent |
| TTS | StandardTimetable | 15% | 5 | ~150 hrs | Near-greenfield; depends on TTF |
| TTF | TimetableFoundation | 68% | 4 | ~70 hrs | 19 of 23 policies dead (duplicate Gate registration) |
| STP | StudentPortal | 75-80% | 4 | ~77.5 hrs | Confirmed ACTIVE — was wrongly "Pending" in CLAUDE.md |
| FIN | StudentFee | 78% | 9 | ~32 dev-days | Highest P0 count in batch; zero-auth on financial routes |
| STD | StudentProfile | TBD | 3 | ~59 dev-days | `is_super_admin` in `$fillable`; attendance controller zero-auth |
| SLK | SyllabusBooks | 70-75% | 5 | — | 3 controllers import Prime `AcademicSession` (wrong DB layer) |
| SLB | Syllabus | 78% | 6 | — | 15 FormRequests with `authorize(){return true;}` |
| QNS | QuestionBank | 50% | 6 | ~112 hrs | `QuestionBankPolicy` dead due to duplicate Gate::policy() call |
| TMP | Template | ~68% (**NO-GO** 40/100) | 3 | — | Mode X 2026-06-30: `value_type` missing → image/html rendering broken; `class_group_id` fallback absent; SQL injection in DB introspection |
| SYS | SystemConfig | 65-70% | 5 | ~46 hrs | Central module; menus/settings/translations |
| VND | Vendor | ~50% (**NO-GO** 35/100) | 4 | — | Mode X 2026-06-30: `balance_due` plain vs GENERATED STORED; PAN/bank plaintext; payment race condition; Transport hard-import in VndAgreement |

### Cross-Cutting Systemic Gaps (confirmed 13/13 modules, 2026-06-30)
1. `EnsureTenantHasModule` middleware absent from all route groups
2. `Gate::authorize()` absent or commented out — policies exist but are never called
3. `FormRequest::authorize(){ return true; }` hardcoded (D30 pattern)
4. Zero test coverage across most modules
5. PII plaintext storage (VND confirmed; audit others)
6. Cross-layer `AcademicSession` import (SLK confirmed; check all modules)
7. `is_super_admin` in User model `$fillable` (SCH + STD confirmed)
8. Duplicate `Gate::policy()` registration silently kills valid policies (QNS + TTF confirmed)
