# Development Progress Tracker

> **Last full audit:** 2026-03-22 against `prime_ai_tarun` (branch `Brijesh_SmartTimetable`)
> **Global stats:** 30 modules | 3176 lines in tenant.php | 1613 Route:: calls | 319 tenant migrations | 230 policies | 464 models | 339 controllers | 137 services | 2036 views | 190 FormRequests | 134 test files
> **Security note:** Only 1 `EnsureTenantHasModule` usage across entire tenant.php. Library has 0 refs in tenant.php. Notification routes ALL commented out.
> **Deep Gap Analysis:** Full 29-module gap analysis completed 2026-03-22. Reports in `{GAP_ANALYSIS_MODULE_WISE}/2026Mar22/`. Summary: ~950+ issues, ~140 P0 critical.

---

## Module Completion Summary (audited 2026-03-22)

> Completion % based ONLY on what routes, models, controllers, services, and tests actually exist in code.
> Does NOT count as "complete" if controllers exist but have zero auth, empty stubs, or critical bugs.

### Central-Scoped Modules

| Module | Code Exists | Completion | Key Gaps |
|--------|------------|------------|----------|
| **Prime** | 21 ctrl, 27 mdl, 1 svc, 7 req | **~70%** | `db_password` plaintext in Domain model; 8 controllers with stub methods; `is_super_admin` mass-assignable; `$request->all()` in 5 controllers |
| **GlobalMaster** | 15 ctrl, 12 mdl, 0 svc, 10 req | **~55%** | `$request->all()` in 12 places; GlobalMasterController zero auth on 7 stubs; wrong permission on ModuleController::show(); no services |
| **SystemConfig** | 4 ctrl, 3 mdl, 0 svc, 1 req | **~50%** | ZERO auth on all 7 methods in SystemConfigController; MenuController `$request->all()`; create() empty stub |
| **Billing** | 6 ctrl, 6 mdl, 0 svc, 3 req, 1 job | **~55%** | Duplicate policies; FK column mismatch; no try/catch on payment processing; 4 stubs |
| **Documentation** | 3 ctrl, 2 mdl, 0 svc, 2 req | **~65%** | Gate permission mismatch (singular vs plural); XSS risk on Summernote content; oversized file uploads |

### Tenant-Scoped Modules — School Administration

| Module | Code Exists | Completion | Key Gaps |
|--------|------------|------------|----------|
| **SchoolSetup** | 40 ctrl, 42 mdl, 0 svc, 27 req | **~55%** | `is_super_admin` settable via UserController; 5+ stub controllers; PHP concat crash; 15+ unprotected methods; zero services for 40 controllers |
| **StudentProfile** | 5 ctrl, 14 mdl, 0 svc, 0 req | **~50%** | `is_super_admin` writable from student login; AttendanceController zero auth; 0 FormRequests; StudentProfileController empty stub |
| **Transport** | 31 ctrl, 36 mdl, 0 svc, 18 req | **~55%** | 5 controllers zero auth; AttendanceDevice `tested.*` typo breaks all Gates; PII unencrypted (Aadhaar, PAN); zero services for 31 controllers |
| **Vendor** | 7 ctrl, 8 mdl, 0 svc, 3 req, 1 job | **~53%** | 6/7 controllers NOT registered in routes; VendorInvoiceController zero auth on 14 methods; financial data unencrypted |
| **Complaint** | 8 ctrl, 6 mdl, 2 svc, 0 req | **~40%** | `dd()` in production store/filter; 3 stub controllers; zero FormRequests; hardcoded dropdown IDs |
| **Notification** | 12 ctrl, 14 mdl, 2 svc, 10 req | **~50%** | ALL routes COMMENTED OUT (module inaccessible); template send is stub; Gate prefix `prime.*` instead of `tenant.*` |
| **Payment** | 2 ctrl, 5 mdl, 2 svc, 1 req | **~45%** | NO DDL schema for `ptm_*` tables; webhook behind auth middleware (always 401); Payment model is stub; gateway credentials unencrypted |
| **Dashboard** | 1 ctrl, 0 mdl, 0 svc, 0 req | **~35%** | ZERO authorization in entire module; returns non-module view path; zero dynamic data |
| **Scheduler** | 1 ctrl, 2 mdl, 2 svc, 1 req | **~40%** | Zero auth on entire controller; empty update/destroy methods; Schedule model missing SoftDeletes |
| **StudentPortal** | 3 ctrl, 0 mdl, 0 svc, 0 req | **~25%** | IDOR vulnerability on invoice/payment; zero Gate in entire module; only 3 of 27 designed screens built |

### Tenant-Scoped Modules — Academic & Curriculum

| Module | Code Exists | Completion | Key Gaps |
|--------|------------|------------|----------|
| **Syllabus** | 15 ctrl, 22 mdl, 0 svc, 14 req | **~55%** | CompetencieController ZERO auth + `$request->all()`; Competencie model missing SoftDeletes; TopicController hard deletes |
| **SyllabusBooks** | 4 ctrl, 6 mdl, 0 svc, 3 req | **~55%** | SyllabusBooksController empty stub; BookTopicMappingController zero auth; central AcademicSession cross-layer |
| **QuestionBank** | 7 ctrl, 17 mdl, 0 svc, 6 req | **~45%** | **HARDCODED API KEYS (OpenAI + Gemini) — ROTATE IMMEDIATELY**; AIQuestionGenerator zero auth; generateQuestions() returns demo data only |
| **LmsExam** | 11 ctrl, 11 mdl, 0 svc, 11 req | **~65%** | `dd($e)` in store(); 2 controllers Gate disabled; no EnsureTenantHasModule; student grading absent |
| **LmsQuiz** | 5 ctrl, 6 mdl, 0 svc, 5 req | **~70%** | Gate commented out in index(); route prefix typo `lms-quize`; student attempt tracking absent |
| **LmsHomework** | 5 ctrl, 5 mdl, 0 svc, 5 req | **~60%** | **FATAL: `HoemworkData()` missing `$request` parameter**; review() zero auth/validation; no EnsureTenantHasModule |
| **LmsQuests** | 4 ctrl, 4 mdl, 0 svc, 4 req | **~60%** | Gate commented in index(); student-facing functionality completely absent; no EnsureTenantHasModule |
| **Recommendation** | 10 ctrl, 11 mdl, 0 svc, 0 req | **~39%** | Gate::any() not enforcing auth; 4 different permission naming patterns; zero FormRequests; 3 empty stubs |

### Tenant-Scoped Modules — Timetable & HPC

| Module | Code Exists | Completion | Key Gaps |
|--------|------------|------------|----------|
| **SmartTimetable** | 12 ctrl, 62 mdl, 106 svc, 7 req | **~48%** | God controller (3,245 lines); constraint engine structure built but FETConstraintBridge context broken; 12 bugs (BUG-TT-001–012); no EnsureTenantHasModule; API zero auth |
| **TimetableFoundation** | 24 ctrl, 32 mdl, 3 svc, 4 req | **~68%** | EnsureTenantHasModule missing on 100+ routes; largest route file (262 lines) |
| **StandardTimetable** | 1 ctrl, 0 mdl, 0 svc, 0 req | **~5%** | Module skeleton — 1 controller with 1 method, zero models/services/views |
| **Hpc** | 22 ctrl, 32 mdl, 10 svc, 14 req | **~59%** | God controller (2,610 lines); no EnsureTenantHasModule; public PDF route; 9 missing FormRequests |
| **Library** | 26 ctrl, 35 mdl, 9 svc, 19 req | **~45%** | NOT wired into tenant.php at all; 7 controllers zero auth; `$request->all()` in 5 controllers; cross-layer import |

### New Module

| Module | Code Exists | Completion | Key Gaps |
|--------|------------|------------|----------|
| **Accounting** | 18 ctrl, 21 mdl, 0 svc, 15 req | **~30%** | NEW — Tally-inspired voucher engine. Controllers and models scaffolded. 21 tenant migrations. 14 test files. Zero services yet. Needs integration with Payroll/Inventory via VoucherServiceInterface. |

---

## Requirements Complete — Development Pending

- [ ] **Payroll** (0% code, module not created) — Requirements v4 complete. 19 new `prl_` tables. 11 controllers, 6 services planned.
- [ ] **Inventory** (0% code, module not created) — Requirements v4 complete. 19 new `inv_` tables. 14 controllers, 6 services planned.

## Pending Modules

- [ ] **Behavioral Assessment** — Student behavior tracking and analysis
- [ ] **Analytical Reports** — Cross-module analytics and reporting
- [ ] **Hostel Management** — Hostel rooms, allocation, fees
- [ ] **Mess/Canteen** — Meal planning, attendance, billing
- [ ] **Admission Enquiry** — Online admission process
- [ ] **Visitor Management** — Visitor registration, tracking
- [ ] **FrontDesk** — Reception management
- [ ] **Template & Certificate** — Dynamic certificate generation
- [ ] **Help Desk** — Support ticket system

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
