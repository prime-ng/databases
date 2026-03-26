# STP — Student Portal Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to complete and harden the **STP (StudentPortal)** module using `STP_StudentPortal_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**⚠️ IMPORTANT — This is an EXISTING module (~55% complete), NOT greenfield.**
- Phase 2 covers Security & Architecture Layer (FormRequests, Policies, Services, security fix recipes) — NOT DDL (module has zero owned tables).
- Read the existing code in `{LARAVEL_REPO}/Modules/StudentPortal/` before generating any output.

**Output Files:**
1. `STP_FeatureSpec.md` — Complete Feature Specification + Current-State Audit
2. `STP_Security_Arch.md` — FormRequests, Policies, Services + Security Fix Recipes
3. `STP_Dev_Plan.md` — Completion Development Plan (P0 → P1 → P2 → P3)

**Developer:** Brijesh
**Module:** StudentPortal — Student-facing self-service portal for Indian K-12 schools.
**Existing code:** 7 controllers (1,317 lines), 57 Blade views, 55+ routes. ZERO services, ZERO FormRequests, ZERO policies.
**Owned tables:** NONE — STP has no `stp_*` tables; all data read from 30+ external module tables.

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = STP
MODULE            = StudentPortal
MODULE_DIR        = Modules/StudentPortal/
BRANCH            = Brijesh_Main
DB_TABLE_PREFIX   = stp_                           # Module has NO owned tables; prefix reserved
DATABASE_NAME     = tenant_db
COMPLETION        = ~55%                           # Current completion state

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/StudentPortal/2-Claude_Plan
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/STP_StudentPortal_Requirement.md

FEATURE_FILE      = STP_FeatureSpec.md
SECURITY_FILE     = STP_Security_Arch.md
DEV_PLAN_FILE     = STP_Dev_Plan.md

STP_MODULE_DIR    = {LARAVEL_REPO}/Modules/StudentPortal/
CONTROLLERS_DIR   = {STP_MODULE_DIR}/app/Http/Controllers/
ROUTES_FILE       = {STP_MODULE_DIR}/routes/web.php
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads existing code + requirement files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — STP (STUDENT PORTAL) MODULE

### What This Module Does

StudentPortal is the **student-facing self-service interface** of Prime-AI. It provides enrolled students (and optionally their parents/guardians) access to: academic profile, timetable, attendance, homework/quiz/quest/exam schedule, fee invoices + Razorpay payment, syllabus progress, teacher directory, progress card (HPC), performance analytics, recommendations, library catalog and borrowed books, transport allocation, health records, notice board, complaint submission, notifications, account settings, and digital ID card — all through a dedicated portal separate from the admin backend.

### Current State (~55% complete as of 2026-03-26)

**What Works (✅ 22 screens):**
- Dashboard (fully populated: attendance stats, today's timetable, pending homework, upcoming exams, fee summary)
- Timetable grid, Attendance page (grouped by month), Syllabus Progress, My Teachers
- Exam Schedule, LMS Hub (homework + exams + quizzes + quests aggregated), Fee Summary
- Health Records, Progress Card (HPC reports — view only, no PDF link), Performance Analytics
- Recommendations, Library catalog + My Borrowed Books, Transport Info
- Study Resources, Prescribed Books, Notice Board, Student ID Card, Notifications, Complaints

**What Is Partially Broken (🟡 8 screens):**
- Academic Information — some nested data partially loaded
- Invoice View / Fee Payment — IDOR partially fixed but `proceedPayment()` still vulnerable
- Results — shows exam schedule but no actual marks/grades
- Homework — list exists but no submission endpoint
- Quiz / Quest — views exist but no routes wired
- Account Settings — 3 of 6 tabs are view-only stubs

**What Is Missing (❌ 5 screens):**
- Leave Application — stub view, no form or endpoint
- School Calendar — stub view, no data source
- Hostel Info — stub view, no data (HST module pending)
- Online Exam Player — view file exists, no route or controller
- API endpoints — module `api.php` is empty

### Critical Security Issues

```
P0 IDOR — proceedPayment():
  POST /student-portal/pay-due-amount/proceed-payment
  Receives `payable_id` from client — NO server-side ownership check.
  Fix: FeeInvoice::whereHas('feeStudentAssignment',
         fn($q) => $q->where('student_id', auth()->user()->student->id)
       )->findOrFail($request->payable_id);

P0 Missing EnsureTenantHasModule:
  None of the portal routes have EnsureTenantHasModule:StudentPortal middleware.

P0 Zero Gate/Policy calls:
  7 controllers, zero Gate::authorize() or $this->authorize() calls.
  Role middleware at route group level is the ONLY RBAC boundary.

P1 Hard-coded dropdown ID 104:
  StudentPortalComplaintController.php lines 73 and 125:
  `if ($request->complainant_type_id == 104)` — must use key-based lookup.

P1 PaymentGateway::all() → ::active()->get():
  payDueAmount() returns all gateways including disabled ones.

P1 Typo: currentFeeAssignemnt → currentFeeAssignment:
  Student model relationship misspelled; used in 3 controller methods.

P1 mark-read via GET → should be POST/PATCH:
  notifications/{id}/mark-read is a GET route — vulnerable to pre-fetch attacks.
```

### Architecture Decisions
- **Single Laravel module** (`Modules\StudentPortal`) — 7 controllers, all portal screens in one module
- Stancl/tenancy v3.9 — `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` in middleware stack
- Route prefix: `student-portal/` | Route name prefix: `student-portal.`
- Middleware applied at RouteServiceProvider: `auth → verified → role:Student|Parent` (Spatie)
- **Missing middleware:** `EnsureTenantHasModule:StudentPortal` (P0 fix required)
- Rate limiting: `throttle:5,2` on login POST; `throttle:3,5` on payment initiation (to be added)
- Layout: `studentportal::components.layouts.master` — completely separate from admin layout
- **Zero owned tables** — STP reads from 30+ tables across 15 modules (STD, FIN, CMP, SYS, TT, EXM, HMW, QUZ, QST, SLB, HPC, REC, LIB, TPT, BOK, PAY)
- Payment: routes through `PaymentService::createPayment()` → Razorpay (Payment module)
- Notifications: Laravel Notifiable trait on `sys_users` — `auth()->user()->notifications()`

### Module Scale
| Artifact | Current | Target (after completion) |
|---|---|---|
| Controllers | 7 (1,317 lines) | 7 (refactored — split StudentPortalController) |
| Services | 0 | 1 (StudentPortalService) |
| FormRequests | 0 | 4 minimum (StoreComplaintRequest, ProcessPaymentRequest, LeaveApplicationRequest, PasswordChangeRequest) |
| Policies | 0 | 1 (StudentPortalPolicy with 3 methods) |
| Blade views | 57 | ~65 (add missing screens + partial completions) |
| Routes | 55+ web + 0 API | 65+ web + 9 API |
| Tables owned | 0 | 0 (no new tables planned in V2) |
| Test files | 7 (scaffolding only) | 15+ (security + functional + regression) |
| Completion | ~55% | ~100% |

### Tables Consumed (Read or Write via External Models — 30 tables)

**STD Module (StudentProfile):**
`std_students`, `std_student_profiles`, `std_student_addresses`, `std_guardians`, `std_student_guardian_jnt`, `std_student_academic_sessions`, `std_health_profiles`, `std_student_attendance`

**FIN Module (StudentFee):**
`fee_student_assignments`, `fee_invoices`

**System Modules:**
`sys_users`, `sys_dropdowns`, `sys_notifications`

**CMP Module (Complaint):**
`cmp_complaints`, `cmp_complaint_categories`

**Timetable:**
`tt_timetable_cells`, `tt_school_days`

**LMS Modules:**
`exm_exam_allocations`, `hmw_homeworks`, `hmw_homework_submissions`, `quz_quiz_allocations`, `qst_quest_allocations`

**Content Modules:**
`slb_syllabus_schedules`, `hpc_reports`, `rec_student_recommendations`

**Library / Transport / Books:**
`lib_book_masters`, `lib_members`, `lib_transactions`, `tpt_student_allocation_jnt`, `bok_books`, `bok_book_class_subjects`

**Payment:**
`pay_payment_gateways`

### Key Student Data Relationship Chain
```
auth()->user() [sys_users]
    └── student [std_students]
         ├── profile [std_student_profiles]
         ├── addresses [std_student_addresses]
         ├── studentGuardianJnts [std_student_guardian_jnt]
         │    └── guardian [std_guardians]
         ├── sessions [std_student_academic_sessions] → classSection → class + section
         ├── currentSession() — returns latest active session
         ├── currentFeeAssignment [fee_student_assignments]  ← note: currently typo 'Assignemnt'
         │    ├── feeStructure.details.head
         │    └── invoices [fee_invoices]
         └── healthProfile [std_health_profiles]
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary source** — STP v2 requirement (Sections 1–16, 30 FRs, Mode: FULL)
2. `{AI_BRAIN}/memory/project-context.md` — Project context
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. **Read all 7 existing controllers:**
   - `{CONTROLLERS_DIR}/StudentPortalController.php`
   - `{CONTROLLERS_DIR}/StudentPortalComplaintController.php`
   - `{CONTROLLERS_DIR}/NotificationController.php`
   - `{CONTROLLERS_DIR}/StudentLmsController.php`
   - `{CONTROLLERS_DIR}/StudentProgressController.php`
   - `{CONTROLLERS_DIR}/StudentTeachersController.php`
   - `{CONTROLLERS_DIR}/StudentTimetableController.php`
6. `{ROUTES_FILE}` — All current web routes
7. `{TENANT_DDL}` — Verify external table column names used in existing code (fee_invoices, std_students, etc.)

### Phase 1 Task — Generate `STP_FeatureSpec.md`

Generate a comprehensive feature specification document. This is both a current-state audit AND a forward-looking spec. Organise into 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix (stp_), module type
- In-scope features (verbatim from req v2 Section 4 — all 30 FRs)
- Out-of-scope: admin backend student management (owned by STD); fee management (owned by FIN); payment processing logic (owned by Payment module); complaint routing engine (owned by CMP)
- Module scale table (controllers / services / FormRequests / policies / views / routes — current and target)
- Note that STP owns ZERO database tables; all reads from external module models

#### Section 2 — Screens Inventory (All 35 Screens)
For each screen, provide:
| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|

Use three status categories: ✅ Built | 🟡 Partial | ❌ Stub/Missing

For each 🟡 or ❌ screen document specifically what is missing and cite the FR-STP-xx reference.

Group screens by area:
- **Auth & Navigation** (Login, Dashboard, Account Settings)
- **Academic** (Academic Info, Fee Summary, Invoice View, Fee Payment)
- **Schedule & Learning** (Timetable, Attendance, Exam Schedule, Results, LMS Hub, Homework, Quiz, Quest, Online Exam)
- **Progress** (Syllabus, Progress Card, Performance Analytics, Recommendations)
- **People & Resources** (My Teachers, Library, Prescribed Books, Study Resources)
- **Student Info** (Health Records, ID Card, Transport, Hostel)
- **Communication** (Notifications, Notice Board, Complaints)
- **Pending** (Leave Application, School Calendar)

#### Section 3 — Security Audit Matrix
Reproduce the V2 security audit table from req Section 15.2 with current status.
Then add a "Fix Required" column with the specific code change needed for each FAIL/PARTIAL entry:

| Check | Current Status | Fix Required | FR/BR Reference |
|---|---|---|---|

Critical items to highlight with ⚠️ marker:
- IDOR proceedPayment: `payable_id` unverified — exact fix recipe (BR.STP.8.1.3)
- EnsureTenantHasModule: missing from route group
- Zero Gate::authorize() calls — policy layer absent
- Hard-coded dropdown ID 104 in StudentPortalComplaintController
- PaymentGateway::all() should be ::active()->get()
- Typo currentFeeAssignemnt (note: check if `fee_invoices` has direct `student_id` column — if not, upgrade guard to `whereHas('feeStudentAssignment')`)
- notifications mark-read via GET (should be POST/PATCH)

#### Section 4 — Business Rules (All 20 rules)
For each rule, state:
- Rule ID (BR.STP.8.x.y — use exact IDs from req v2 Section 8)
- Rule text
- Current enforcement status: ✅ Enforced | 🟡 Partial | ❌ Missing
- Enforcement point: `middleware` | `policy` | `service_layer` | `form_validation` | `db_constraint`
- What code change enforces it (if missing)

Groups:
1. Data Isolation (BR.STP.8.1.1 to BR.STP.8.1.6) — 6 rules
2. Fee Payment (BR.STP.8.2.1 to BR.STP.8.2.5) — 5 rules
3. Timetable (BR.STP.8.3.1 to BR.STP.8.3.3) — 3 rules
4. Attendance (BR.STP.8.4.1 to BR.STP.8.4.2) — 2 rules
5. Complaint (BR.STP.8.5.1 to BR.STP.8.5.3) — 3 rules
6. LMS Access (BR.STP.8.6.1 to BR.STP.8.6.3) — 3 rules

Critical rules to emphasise:
- BR.STP.8.1.1: Student sees ONLY own data — zero cross-student access
- BR.STP.8.1.2: Invoice ownership via feeStudentAssignment chain (NOT direct student_id on fee_invoices — verify column existence)
- BR.STP.8.1.3: `payable_id` ownership check in proceedPayment — server-side only
- BR.STP.8.1.4: Guardian `can_access_parent_portal=1` in std_student_guardian_jnt
- BR.STP.8.2.1: Only Payable invoices can be paid (Published/Partially Paid/Overdue)
- BR.STP.8.2.5: Rate limiting on payment initiation (throttle:3,5)

#### Section 5 — Workflow Diagrams (3 FSMs / Workflows)
For each workflow:
- Step-by-step flow with ← CURRENT STATUS notation
- Security check points highlighted with ⚠️
- The missing/broken steps clearly marked with ❌ MISSING

Workflows to document:
1. **Fee Payment Workflow** — Student → pay-now → select gateway → proceed-payment → Razorpay → webhook → status update. Mark the missing `payable_id` ownership check step.
2. **Complaint Submission Workflow** — Create form → AJAX subcategory → POST → validation → Complaint::create. Mark hard-coded ID 104, $request->merge() anti-pattern.
3. **Dashboard Data Aggregation Workflow** — Auth → student → currentSession → 5 parallel data loads → render. Mark N+1 consolidation opportunity.

#### Section 6 — Functional Requirements Summary (30 FRs)
For each FR-STP-01 to FR-STP-30:
| FR ID | Name | Status | Controller@Method | Tables Used | Key Gaps | Priority |
|---|---|---|---|---|---|---|

Group by status (✅ Implemented | 🟡 Partial | ❌ Stub/Missing).

#### Section 7 — External Module Dependencies Matrix
For each external module STP depends on:
| Module | Direction | Tables/Models Used | STP Method(s) | FK Chain |
|---|---|---|---|---|

Document the Student model relationship chain (auth()->user() → student → profile → session → feeAssignment) in full, noting the `currentFeeAssignemnt` typo location.

Also note cross-module IDOR risk points:
- `fee_invoices`: ownership via `feeStudentAssignment` chain (not direct `student_id` — verify)
- `cmp_complaints`: scoped to `created_by = Auth::id()` (correct)
- `sys_notifications`: scoped via Laravel Notifiable `auth()->user()->notifications()` (correct)

#### Section 8 — Service Architecture (Target State — 1 service needed)
Define the planned `StudentPortalService`:
```
Service:     StudentPortalService
File:        Modules/StudentPortal/app/Services/StudentPortalService.php
Namespace:   Modules\StudentPortal\app\Services
Purpose:     Extract dashboard aggregation + heavy controller logic

Key Methods:
  getDashboardData(Student $student): array
    └── Loads: attendance stats, today's timetable, pending homework (5), upcoming exams (5), fee summary, notifications (10); all in one eager-load chain to prevent N+1
  getAttendanceSummary(Student $student, int $sessionId): array
    └── Total/present/absent/late/leave counts + percentage; grouped by month
  getFeeSummary(Student $student): array
    └── All invoices for current fee assignment; total/paid/due/pending count
  getSyllabusProgress(Student $student, int $classId, int $sectionId, int $sessionId): array
    └── Topics grouped by subject; per-topic status (completed/in_progress/upcoming from date comparison)
```

Note: Controllers should remain thin — call StudentPortalService and pass result to view. No business logic in controller methods.

#### Section 9 — FormRequest Architecture (Target State — 4+ required)
For each planned FormRequest:
| Class | Controller Method | authorize() logic | Key Rules |
|---|---|---|---|

Minimum required (P1):
1. `StoreComplaintRequest` — `authorize()`: `auth()->user()->hasRole('Student')` | rules: target_type_id exists, complainant_type_id exists, category_id exists, description required + `strip_tags()` sanitization, attachment: nullable + mimes:jpg,jpeg,png,pdf + max:5120
2. `ProcessPaymentRequest` — `authorize()`: ownership check via feeStudentAssignment chain | rules: amount numeric + min:0.01 + max=invoice balance, payable_type in:fee_invoice, payable_id exists + ownership verified, gateway required + active
3. `LeaveApplicationRequest` — (P2) rules: leave_type required, start_date required date + after_or_equal:today, end_date required + after_or_equal:start_date, reason required + max:1000, attachment nullable + mimes:jpg,jpeg,png,pdf + max:5120
4. `PasswordChangeRequest` — (P2) rules: current_password required, password confirmed + min:8 + mixed case

#### Section 10 — Policy Architecture (Target State — 1 policy)
Define `StudentPortalPolicy`:
| Method | Arguments | Authorization Logic |
|---|---|---|
| `viewInvoice(User $user, FeeInvoice $invoice)` | user, invoice | Check invoice belongs to student via feeStudentAssignment chain |
| `payInvoice(User $user, FeeInvoice $invoice)` | user, invoice | viewInvoice + invoice status is payable (Published/Partially Paid/Overdue) + balance > 0 |
| `createComplaint(User $user)` | user | user has Student role |

Note: Policy must be registered in `StudentPortalServiceProvider`:
```php
Gate::policy(FeeInvoice::class, StudentPortalPolicy::class);
```

#### Section 11 — Test Plan Outline
From req v2 Section 12:

**P0 Security Tests (5 scenarios — T-STP-001 to T-STP-005):**
| ID | Scenario | Expected |
|---|---|---|
(All 5 IDOR and auth bypass scenarios from req Section 12.2)

**P1 Functional Tests (9 scenarios — T-STP-010 to T-STP-018):**
(All from req Section 12.2)

**P2 Regression Tests (6 scenarios — T-STP-020 to T-STP-025):**
(All from req Section 12.2)

**Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// Student user factory: user with Spatie role 'Student' + linked std_students record
// Parent user factory: user with role 'Parent' + linked via std_student_guardian_jnt (can_access_parent_portal=1)
// Admin factory: user without Student/Parent role — must be blocked from portal
// Event::fake() for notification tests
// Razorpay: use mock PaymentService (bind interface → mock in test)
// IDOR tests: two students A and B; student A attempts to access B's resource
```

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `STP_FeatureSpec.md` | `{OUTPUT_DIR}/STP_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 35 screens inventoried in Section 2 with correct status (22 ✅, 8 🟡, 5 ❌)
- [ ] All 20 business rules (BR.STP.8.x.y) in Section 4 with current enforcement status and fix
- [ ] IDOR proceedPayment (BR.STP.8.1.3) explicitly documented with exact fix recipe in Section 3
- [ ] Security audit table in Section 3 matches req v2 Section 15.2 + adds "Fix Required" column
- [ ] All 3 workflows in Section 5 with ⚠️ markers on security check points
- [ ] All 30 FRs (FR-STP-01 to FR-STP-30) in Section 6 with status and controller mapping
- [ ] Student model relationship chain documented in full in Section 7 with typo location noted
- [ ] `currentFeeAssignemnt` typo documented with required fix in Section 7 and Section 3
- [ ] StudentPortalService design with `getDashboardData()` N+1 consolidation approach in Section 8
- [ ] All 4 FormRequest classes designed with `authorize()` logic in Section 9
- [ ] StudentPortalPolicy designed with 3 methods in Section 10
- [ ] P0 security tests (T-STP-001 to T-STP-005) fully documented in Section 11
- [ ] `EnsureTenantHasModule:StudentPortal` middleware gap explicitly noted
- [ ] Hard-coded dropdown ID 104 fix recipe documented
- [ ] `PaymentGateway::all()` → `::active()->get()` fix documented
- [ ] Zero scaffold stub methods issue documented (7 unused methods in StudentPortalController)
- [ ] `notifications/mark-read` GET → POST/PATCH fix documented with CSRF bypass risk explanation
- [ ] **No new stp_* tables planned** — confirmed explicitly in Section 1

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification + Audit) complete. Output saved to `{OUTPUT_DIR}/STP_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Security & Architecture Layer

> **Why Phase 2 is different from other modules:** STP has ZERO owned tables — no DDL or migrations are needed. Instead, Phase 2 designs and generates the missing authorization/service code layer that the existing controllers are missing.

### Phase 2 Input Files
1. `{OUTPUT_DIR}/STP_FeatureSpec.md` — Security audit (Section 3), FormRequest designs (Section 9), Policy designs (Section 10), Service designs (Section 8)
2. `{REQUIREMENT_FILE}` — Section 14 (suggestions S-STP-01 to S-STP-25 — code snippets included)
3. All 7 existing controller files — read the actual current code before generating fixes
4. `{AI_BRAIN}/agents/db-architect.md` — Not needed for DDL, but read for conventions if cross-module patterns referenced

### Phase 2A Task — Generate `STP_Security_Arch.md` Part 1: Security Fixes

Generate a **ready-to-apply security fix document**. For each P0/P1 issue:

---

**Fix 1 — IDOR in `proceedPayment()` (P0 — CRITICAL)**

File: `{CONTROLLERS_DIR}/StudentPortalController.php`
Method: `proceedPayment(Request $request)`

Current code pattern (do NOT reproduce in full — summarise the gap):
```
// Missing: payable_id ownership verification before PaymentService::createPayment()
```

Target code (generate full replacement):
```php
public function proceedPayment(ProcessPaymentRequest $request)
{
    // ProcessPaymentRequest::authorize() verifies ownership — see Phase 2B FormRequest
    // ProcessPaymentRequest::rules() validates amount, gateway

    $student = auth()->user()->student;
    $invoice = FeeInvoice::whereHas('feeStudentAssignment',
        fn($q) => $q->where('student_id', $student->id)
    )->findOrFail($request->payable_id);

    // Verify invoice is payable
    abort_if(!in_array($invoice->status, ['Published', 'Partially Paid', 'Overdue']), 422, 'Invoice is not payable');
    abort_if($invoice->balance_amount <= 0, 422, 'Invoice already paid');

    $payment = PaymentService::createPayment([
        'amount'        => $request->amount,
        'payable_type'  => $request->payable_type,
        'payable_id'    => $invoice->id,  // Use verified ID, not client-submitted
        'gateway'       => $request->gateway,
        'student_id'    => $student->id,
    ]);

    return redirect()->route('payment::razorpay.process-payment', $payment);
}
```

**Fix 2 — Verify viewInvoice / payDueAmount ownership guard (P0)**

File: `{CONTROLLERS_DIR}/StudentPortalController.php`
Check: Does `fee_invoices` table have a direct `student_id` column?
- Read `{TENANT_DDL}` and grep for `CREATE TABLE fee_invoices` to confirm column presence.
- If `student_id` exists: current `->where('student_id', $student->id)->findOrFail($id)` is correct.
- If NOT: replace with `whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $student->id))`.

Generate the safe universal guard (works regardless of column presence):
```php
private function findStudentInvoice(int $invoiceId): FeeInvoice
{
    $student = auth()->user()->student;
    return FeeInvoice::whereHas('feeStudentAssignment',
        fn($q) => $q->where('student_id', $student->id)
    )->findOrFail($invoiceId);
}
```
Apply to both `viewInvoice()` and `payDueAmount()`.

**Fix 3 — Add EnsureTenantHasModule middleware (P0)**

File: `{STP_MODULE_DIR}/app/Providers/RouteServiceProvider.php`
Generate the middleware registration code to add `EnsureTenantHasModule:StudentPortal` to the web route group middleware array.

**Fix 4 — Fix hard-coded dropdown ID 104 (P1)**

File: `{CONTROLLERS_DIR}/StudentPortalComplaintController.php`
Lines: 73 and 125
Generate full replacement using key-based lookup:
```php
// In __construct() or a helper method:
private function getStudentComplainantTypeId(): int
{
    return (int) \DB::table('sys_dropdowns')
        ->where('key', 'COMPLAINANT_STUDENT')
        ->value('id');
}
// Replace literal 104 comparisons with: $this->getStudentComplainantTypeId()
```

**Fix 5 — PaymentGateway::all() → ::active()->get() (P1)**

File: `{CONTROLLERS_DIR}/StudentPortalController.php`
Method: `payDueAmount()`
Generate the one-line change.

**Fix 6 — Fix typo currentFeeAssignemnt (P1)**

File: STD module's `Student` model (NOT in STP — provide instructions only)
Change relationship method name `currentFeeAssignemnt` → `currentFeeAssignment`.
Also update all 3 call sites in StudentPortalController.php.

**Fix 7 — Change mark-read from GET to POST/PATCH (P1)**

File: `{ROUTES_FILE}` and `{CONTROLLERS_DIR}/NotificationController.php`
Generate the route change and controller update with CSRF verification note.

**Fix 8 — Add EnsureTenantHasModule to portal route group (P0)**

Generate the RouteServiceProvider or web.php middleware addition.

**Fix 9 — Add rate limiting to payment route (P1)**

Generate: `Route::post('pay-due-amount/proceed-payment', ...)->middleware('throttle:3,5')`

**Fix 10 — Remove scaffold stub methods from StudentPortalController (P1)**

List the 7 stub methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) and confirm they should be removed. Generate the clean controller excerpt without these methods.

---

### Phase 2B Task — Generate `STP_Security_Arch.md` Part 2: FormRequests

For each of the 4 FormRequest classes, generate full class code:

**1. `StoreComplaintRequest`**
```php
namespace Modules\StudentPortal\app\Http\Requests;

class StoreComplaintRequest extends FormRequest
{
    public function authorize(): bool
    {
        return auth()->check() && auth()->user()->hasRole('Student');
    }

    public function rules(): array
    {
        return [
            'target_type_id'         => ['required', 'exists:sys_dropdowns,id'],
            'complainant_type_id'    => ['required', 'exists:sys_dropdowns,id'],
            'category_id'            => ['required', 'exists:cmp_complaint_categories,id'],
            'subcategory_id'         => ['nullable', 'exists:cmp_complaint_categories,id'],
            'description'            => ['required', 'string', 'max:2000'],
            'attachment'             => ['nullable', 'file', 'mimes:jpg,jpeg,png,pdf', 'max:5120'],
        ];
    }

    protected function prepareForValidation(): void
    {
        // Sanitize description to strip HTML tags (BR.STP.8.5.1 — no HTML injection)
        $this->merge(['description' => strip_tags($this->description)]);
    }
}
```

**2. `ProcessPaymentRequest`**

Full class with:
- `authorize()`: checks invoice ownership via feeStudentAssignment chain (so controller does NOT need to repeat the check)
- `rules()`: amount (numeric, min:0.01), payable_type (in:fee_invoice), payable_id (required|integer — ownership in authorize()), gateway (required|exists:pay_payment_gateways,id + active scope)
- Custom `messages()` for clear student-facing error text
- Note the interplay with IDOR Fix 1: authorize() verifies ownership; controller uses the verified model

**3. `LeaveApplicationRequest`** (P2 — document design, generation optional)

Design: leave_type required, start_date/end_date date validation, reason required + max:1000, attachment nullable + file validation

**4. `PasswordChangeRequest`** (P2 — document design, generation optional)

Design: current_password (verified against Hash::check), password required + confirmed + min:8

---

### Phase 2C Task — Generate `STP_Security_Arch.md` Part 3: Policy & Service

**StudentPortalPolicy** — full class code:
```php
namespace Modules\StudentPortal\app\Policies;

class StudentPortalPolicy
{
    public function viewInvoice(User $user, FeeInvoice $invoice): bool
    {
        // Check via feeStudentAssignment chain (safe regardless of direct student_id column)
        return $invoice->feeStudentAssignment()
            ->where('student_id', $user->student->id)
            ->exists();
    }

    public function payInvoice(User $user, FeeInvoice $invoice): bool
    {
        return $this->viewInvoice($user, $invoice)
            && in_array($invoice->status, ['Published', 'Partially Paid', 'Overdue'])
            && $invoice->balance_amount > 0;
    }

    public function createComplaint(User $user): bool
    {
        return $user->hasRole('Student');
    }
}
```

Also generate ServiceProvider registration snippet:
```php
Gate::policy(FeeInvoice::class, StudentPortalPolicy::class);
```

**StudentPortalService** — skeleton class with full method signatures and docblocks:
- `getDashboardData(Student $student): array` — consolidated eager-load query
- `getAttendanceSummary(Student $student, int $sessionId): array`
- `getFeeSummary(Student $student): array`
- `getSyllabusProgress(Student $student, int $classId, int $sectionId, int $sessionId): array`

For `getDashboardData()` generate the consolidated `with([...])` chain:
```php
$student->load([
    'currentSession.classSection.class',
    'currentSession.classSection.section',
    'currentFeeAssignment.invoices',
    'healthProfile',
]);
// Then: attendance, timetable, homework, exams loaded separately with scoped queries
```

---

### Phase 2 Output Files
| File | Location |
|---|---|
| `STP_Security_Arch.md` | `{OUTPUT_DIR}/STP_Security_Arch.md` |

### Phase 2 Quality Gate
- [ ] All 10 security fixes generated with complete replacement code (not just description)
- [ ] `proceedPayment()` IDOR fix includes server-side ownership check via feeStudentAssignment chain
- [ ] `findStudentInvoice()` private helper generated — safe regardless of fee_invoices.student_id column presence
- [ ] TENANT_DDL grep result for `fee_invoices` documented — confirm whether direct `student_id` column exists
- [ ] `EnsureTenantHasModule:StudentPortal` middleware addition code generated
- [ ] Hard-coded dropdown ID 104 replaced with `sys_dropdowns` key-based lookup code
- [ ] All 4 FormRequest classes generated with full `authorize()` + `rules()` + `prepareForValidation()` methods
- [ ] `StoreComplaintRequest` includes `strip_tags()` in `prepareForValidation()` (HTML injection prevention)
- [ ] `ProcessPaymentRequest::authorize()` performs ownership check (removes IDOR from controller)
- [ ] `StudentPortalPolicy` generated with 3 methods + ServiceProvider registration snippet
- [ ] `StudentPortalService::getDashboardData()` consolidated eager-load chain generated
- [ ] Rate limiting `throttle:3,5` on payment route generated
- [ ] Scaffold stub methods removal documented (7 methods: index, create, store, show, edit, update, destroy)
- [ ] mark-read route change (GET → POST/PATCH) generated with updated NotificationController method
- [ ] `PaymentGateway::all()` → `::active()->get()` one-line change generated
- [ ] Typo fix `currentFeeAssignemnt` → `currentFeeAssignment` documented with all 3 call sites in controllers

**After Phase 2, STOP and say:**
"Phase 2 (Security & Architecture Layer) complete. Output: `STP_Security_Arch.md` with 10 security fixes + 4 FormRequests + 1 Policy + 1 Service. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/STP_FeatureSpec.md` — Screen inventory (Section 2), BR status (Section 4), FR list (Section 6), Service design (Section 8)
2. `{OUTPUT_DIR}/STP_Security_Arch.md` — Fix list and FormRequest/Policy/Service code
3. `{REQUIREMENT_FILE}` — Section 14 (S-STP-01 to S-STP-25 suggestions in priority order)
4. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules

### Phase 3 Task — Generate `STP_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each of the 7 controllers, provide:
| Controller Class | File Path | Lines (current) | Methods | Status |
|---|---|---|---|---|

For `StudentPortalController` (558 lines — the mega-controller), note:
- Which methods should be refactored to use StudentPortalService
- Which 7 stub methods must be removed
- Which methods need ProcessPaymentRequest / StudentPortalPolicy added

For `StudentPortalComplaintController` (248 lines):
- Needs StoreComplaintRequest; hard-coded 104 fix; pagination fix; $request->merge() anti-pattern fix

For `NotificationController` (71 lines):
- mark-read: GET → POST/PATCH; verify notification ownership before mark-read

For each controller list:
- All routes it serves (method + URI + route name)
- Current issues (from Phase 1 Section 3 security audit)
- Required changes

#### Section 2 — Service Inventory (1 service)

Full `StudentPortalService` specification:
- Constructor dependencies
- All public methods with signature, 1-line description, and which controller method(s) it replaces
- The consolidated eager-load pattern for getDashboardData()
- Performance note: current dashboard runs ~6 separate queries; target: 1 eager-load chain + 4 scoped queries

#### Section 3 — FormRequest Inventory (4 FormRequests)

For each FormRequest:
| Class | Controller Method | authorize() Logic | Key Rules |
|---|---|---|---|

Reference Phase 2B code; add notes on where each replaces inline `$request->validate()` or no-validation patterns.

#### Section 4 — Blade View Inventory (57 existing + additions)

For each screen area, list all view files and their current status.
Flag views that need data source changes:
- `notice-board/index.blade.php` — should use announcement/notice model, not auth()->user()->notifications()
- `results/index.blade.php` — needs ExamResult model integration for marks/grades
- `quiz/index.blade.php`, `quest/index.blade.php` — need routes wired
- `leave/index.blade.php` — needs form + POST endpoint

New views to create:
- `api/` (not blade — REST API endpoints for Phase P3 REST API work)
- `account/_change-password.blade.php` (partial — complete the tab)
- `account/_notification-preferences.blade.php` (partial — complete the tab)

#### Section 5 — Complete Route List

Consolidate all 55+ existing web routes into a single table:
| Method | URI | Route Name | Controller@method | Status | Notes |
|---|---|---|---|---|---|

Add planned routes:
- `POST student-portal/notifications/{id}/mark-read` (replaces current GET)
- `POST student-portal/homework/{homework}/submit` (P2)
- `GET student-portal/quiz` / `GET student-portal/quest` (P2)
- `GET student-portal/student-id-card/download` (P2 — DomPDF)
- `GET student-portal/progress-card/{report}/download` (P2 — link to HPC module PDF)
- 9 planned API routes from req Section 6.2 (P3)

Middleware additions:
- Add `EnsureTenantHasModule:StudentPortal` to entire route group
- Add `throttle:5,2` to login POST
- Add `throttle:3,5` to proceed-payment POST
- Change mark-read from GET → POST with `throttle:5,1`

#### Section 6 — Implementation Phases (4 priority phases)

**Phase P0 — Security Critical (1 person-day — deploy immediately)**
FRs addressed: FR-STP-04, FR-STP-05 (IDOR fixes)
Files to change:
- `StudentPortalController.php` — proceedPayment() IDOR fix + findStudentInvoice() helper + PaymentGateway::active()
- `RouteServiceProvider.php` — Add EnsureTenantHasModule:StudentPortal + throttle:3,5 on payment
- `ProcessPaymentRequest.php` — CREATE new file
- `StudentPortalPolicy.php` — CREATE new file
- `StudentPortalServiceProvider.php` — Register policy
- Remove `test-notification` route if present
- Tests: T-STP-001, T-STP-002, T-STP-003, T-STP-004, T-STP-005 (all P0 security tests)

**Phase P1 — High Priority Quality Fixes (3 person-days)**
FRs addressed: FR-STP-28 (complaint), FR-STP-27 (notifications), FR-STP-05 (gateway fix)
Files to change:
- `StudentPortalController.php` — Remove 7 stub methods; fix typo callers; fix PaymentGateway::all()
- `StudentPortalComplaintController.php` — StoreComplaintRequest; fix ID 104; paginate complaints; fix $request->merge() anti-pattern
- `NotificationController.php` — Change mark-read to POST/PATCH; add ownership check
- `StudentPortalService.php` — CREATE; move dashboard aggregation from controller
- `StoreComplaintRequest.php` — CREATE
- STD module `Student.php` — Fix typo currentFeeAssignemnt → currentFeeAssignment (coordinate with STD team)
- Routes/web.php — Update mark-read to POST; add throttle:5,2 to login
- Tests: T-STP-010 to T-STP-018 (P1 functional tests)

**Phase P2 — Completeness (7 person-days)**
FRs addressed: FR-STP-10 (results with marks), FR-STP-12 (homework submission), FR-STP-24 (calendar), FR-STP-25 (leave), FR-STP-29 (account settings backend), FR-STP-30 (quiz/quest)
Files to create/change:
- `StudentPortalController.php` — results() method: integrate ExamResult model for marks
- Homework: `POST student-portal/homework/{homework}/submit` route + controller method + HomeworkSubmission::create()
- `LeaveApplicationRequest.php` — CREATE
- Leave controller method: `storeLeave()` — form save (may require new `std_leave_applications` table — check if exists in tenant_db)
- Quiz/Quest routes: `GET student-portal/quiz` + `GET student-portal/quest` with proper controller methods
- Account settings: password change (PasswordChangeRequest + Hash::check), notification preferences, privacy settings
- Notice board fix: query `sch_notices` or `sys_announcements` instead of user notifications
- Progress card PDF: link to HPC module PDF route per report
- ID card download: `/student-portal/student-id-card/download` → DomPDF minimal PDF
- Tests: T-STP-020 to T-STP-025 (P2 regression tests)

**Phase P3 — REST API + Enhancements (4 person-days)**
FRs addressed: REST API for mobile/PWA (req Section 6.2)
Files to create:
- `{STP_MODULE_DIR}/routes/api.php` — populate with 9 API endpoints
- API controller methods (add to existing controllers or new `StudentPortalApiController`): profile, invoices, pay, timetable, attendance, notifications (list + mark-read), homework, exams
- Middleware: `auth:sanctum` + `role:Student|Parent`
- Tests: API feature tests for auth:sanctum + IDOR (student A cannot access student B's API data)
- Parent dashboard separation (FR implied by req Section 14.4 S-STP-22)
- Push notifications / FCM (S-STP-24)

#### Section 7 — Seeder Execution Order

STP has NO owned tables and therefore NO seeders. This section documents test data requirements instead:

```
Test data requirements for each phase:

Phase P0 tests require:
  - 2 student users (Student A + Student B) with distinct std_students records
  - FeeInvoice records belonging to Student A (not Student B)
  - Active PaymentGateway record in pay_payment_gateways
  - fee_student_assignments linking FeeInvoice to Student A

Phase P1 tests require:
  - Complaint categories in cmp_complaint_categories
  - sys_dropdowns record with key='COMPLAINANT_STUDENT'
  - sys_notifications records for auth user

Phase P2 tests require:
  - ExamAllocation records linked to student's class+section
  - Homework records linked to student's class+section (published)
  - slb_syllabus_schedules records for syllabusProgress test
```

Note on leave application: Check `{TENANT_DDL}` for existence of `std_leave_applications` table. If absent, Phase P2 leave functionality requires a new migration — document the required columns and flag for review before implementation.

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// Student factory: user + Spatie role 'Student' + std_students record
// Parent factory: user + role 'Parent' + std_student_guardian_jnt (can_access_parent_portal=1)
// Admin factory: user + role 'Admin' (must be blocked from portal routes)
// For IDOR tests: StudentA and StudentB — separate users with separate invoice records
// PaymentService: bind mock in AppServiceProvider for testing: app()->bind(PaymentService::class, MockPaymentService::class)
// Notification::fake() for notification tests
// Queue::fake() where jobs are involved
```

**P0 Security Test Patterns:**
```
IDOR test pattern:
  $studentA = Student::factory()->create();
  $studentB = Student::factory()->create();
  $invoice  = FeeInvoice::factory()->for($studentB)->create();
  $this->actingAs($studentA->user)
       ->post(route('student-portal.proceed-payment'), ['payable_id' => $invoice->id, ...])
       ->assertForbidden();  // 403 or 422
```

**Minimum Coverage Targets:**
- All 5 P0 security tests must PASS before any P1 work proceeds
- IDOR: student A cannot view/pay student B's invoice under any circumstance
- EnsureTenantHasModule: disabled module returns 403
- Unauthenticated: all portal routes redirect to login
- Admin user (non-Student): portal routes return 403
- Guardian `can_access_parent_portal=0`: cannot access child's data via parent role
- Rate limiting: payment throttle test (mock throttle middleware in test)

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `STP_Dev_Plan.md` | `{OUTPUT_DIR}/STP_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 7 controllers listed with all methods + status + required changes
- [ ] `StudentPortalService` listed with all 4 method signatures and which controller methods they replace
- [ ] Dashboard N+1 fix documented: current ~6 queries → target: consolidated eager-load chain
- [ ] All 4 FormRequests listed with `authorize()` logic and key validation rules
- [ ] All 4 implementation phases have: files to change, FRs covered, test scenarios
- [ ] P0 phase is deployable in isolation (no P1/P2 dependencies)
- [ ] IDOR fix in P0 phase includes both `proceedPayment()` fix AND `findStudentInvoice()` helper
- [ ] Leave application (P2) documents: check for `std_leave_applications` table first; may require new migration
- [ ] Notice board fix (P2) documents: target data source (sch_notices or sys_announcements — verify table name in TENANT_DDL)
- [ ] Quiz/Quest routes (P2) explicitly listed with controller method design
- [ ] API routes section lists all 9 endpoints from req Section 6.2
- [ ] Test data requirements documented per phase (no seeders for STP)
- [ ] IDOR test pattern (student A vs student B) documented in Section 8
- [ ] `EnsureTenantHasModule:StudentPortal` confirmed in P0 phase route group
- [ ] Scaffold stub removal (7 methods) explicitly in P1 phase
- [ ] All 25 suggestions (S-STP-01 to S-STP-25) assigned to a phase or backlog
- [ ] Route count totals documented (~65 web + 9 API = ~74 after completion)

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `STP_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/STP_FeatureSpec.md` — Full audit + forward spec
2. `{OUTPUT_DIR}/STP_Security_Arch.md` — Security fixes + FormRequests + Policy + Service code
3. `{OUTPUT_DIR}/STP_Dev_Plan.md` — P0 → P1 → P2 → P3 completion plan
StudentPortal completion plan is ready. Deploy P0 security fixes first before any other work."

---

## QUICK REFERENCE — STP Module Controllers vs Services vs Views

| Area | Controller(s) | Service | Key Tables Read | Status |
|---|---|---|---|---|
| Dashboard | StudentPortalController@dashboard | StudentPortalService@getDashboardData | std_students, std_student_attendance, tt_timetable_cells, hmw_homeworks, exm_exam_allocations, fee_invoices | ✅ Data live — needs N+1 fix |
| Fee / Payment | StudentPortalController@viewInvoice, payDueAmount, proceedPayment | StudentPortalService@getFeeSummary | fee_invoices, fee_student_assignments, pay_payment_gateways | 🟡 **IDOR P0** |
| Timetable | StudentTimetableController@index | — | tt_timetable_cells, tt_school_days | ✅ |
| Attendance | StudentProgressController@attendance | StudentPortalService@getAttendanceSummary | std_student_attendance | ✅ |
| LMS Hub | StudentLmsController@index | — | hmw_homeworks, exm_exam_allocations, quz_quiz_allocations, qst_quest_allocations | ✅ list only — no submission |
| Syllabus | StudentProgressController@syllabusProgress | StudentPortalService@getSyllabusProgress | slb_syllabus_schedules | ✅ |
| Teachers | StudentTeachersController@index | — | tt_timetable_cells | ✅ |
| Notifications | NotificationController | — | sys_notifications (via Notifiable) | 🟡 mark-read HTTP method |
| Complaints | StudentPortalComplaintController | — | cmp_complaints, cmp_complaint_categories, sys_dropdowns | 🟡 hardcoded ID + no paginate |
| Library | StudentPortalController@library, libraryMyBooks | — | lib_book_masters, lib_members, lib_transactions | ✅ |
| Transport | StudentPortalController@transport | — | tpt_student_allocation_jnt | ✅ |
| Progress Card | StudentPortalController@progressCard | — | hpc_reports | ✅ — no PDF |
| Recommendations | StudentPortalController@myRecommendations | — | rec_student_recommendations | ✅ |
| Account | StudentPortalController@account | — | sys_users | 🟡 tabs incomplete |
| Leave / Calendar / Hostel | StudentPortalController stubs | — | TBD | ❌ stubs |
| REST API | (none yet) | — | All portal tables | ❌ empty api.php |
