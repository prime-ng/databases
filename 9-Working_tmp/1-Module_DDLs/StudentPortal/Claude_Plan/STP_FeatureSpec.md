# STP — Student Portal
## Feature Specification + Current-State Audit
**Version:** 1.0 | **Generated:** 2026-03-27 | **Source:** STP_StudentPortal_Requirement.md v2.0 + Code Audit
**Developer:** Brijesh

---

> **⚠️ CODE AUDIT DISCREPANCY — READ FIRST**
> The requirement document (v2) describes the module as ~55% complete with 7 controllers, 57 views, and 55+ routes **as of 2026-03-26**. The actual committed code on branch `Brijesh_Main` (audited 2026-03-27) matches the **V1 state**: 3 controllers, ~26 blade views, and approximately 15 routes wired in `routes/tenant.php`. The 4 additional controllers (`StudentLmsController`, `StudentProgressController`, `StudentTeachersController`, `StudentTimetableController`) do NOT exist in the repository. The feature spec below uses the requirement as the target state while flagging actual vs documented code where they diverge.

---

## Table of Contents

1. [Module Identity & Scope](#1-module-identity--scope)
2. [Screens Inventory (35 Screens)](#2-screens-inventory-35-screens)
3. [Security Audit Matrix](#3-security-audit-matrix)
4. [Business Rules (20 Rules)](#4-business-rules-20-rules)
5. [Workflow Diagrams](#5-workflow-diagrams)
6. [Functional Requirements Summary (30 FRs)](#6-functional-requirements-summary-30-frs)
7. [External Module Dependencies Matrix](#7-external-module-dependencies-matrix)
8. [Service Architecture (Target)](#8-service-architecture-target)
9. [FormRequest Architecture (Target)](#9-formrequest-architecture-target)
10. [Policy Architecture (Target)](#10-policy-architecture-target)
11. [Test Plan Outline](#11-test-plan-outline)

---

## 1. Module Identity & Scope

### 1.1 Identity

| Attribute            | Value                                                                |
|----------------------|----------------------------------------------------------------------|
| Module Code          | `STP`                                                                |
| Module Name          | `StudentPortal`                                                      |
| Namespace            | `Modules\StudentPortal`                                              |
| Laravel Module       | `nwidart/laravel-modules` v12                                        |
| Route Prefix         | `student-portal/`                                                    |
| Route Name Prefix    | `student-portal.`                                                    |
| DB Prefix            | `stp_` (reserved — module owns **zero** tables)                      |
| Database             | `tenant` connection (`tenant_{uuid}`)                                |
| DB Layer             | `tenant_db`                                                          |
| Module Type          | Tenant — school-specific, student-facing portal                      |
| Auth Guard           | Laravel Auth — `role:Student|Parent` Spatie middleware               |
| Layout               | `studentportal::components.layouts.master` (separate from admin)     |
| Payment              | Razorpay via `Payment\Services\PaymentService::createPayment()`      |
| Completion (actual)  | ~20% (3 controllers, 15 routes committed) — see discrepancy note above |
| Completion (req v2)  | ~55% (7 controllers, 55+ routes, 57 views as described in req)       |

### 1.2 In-Scope Features (30 FRs)

All 30 FRs from req v2 Section 4:

| FR | Feature |
|----|---------|
| FR-STP-01 | Student Login |
| FR-STP-02 | Student Dashboard |
| FR-STP-03 | Academic Information |
| FR-STP-04 | Fee Invoice View |
| FR-STP-05 | Fee Payment |
| FR-STP-06 | Fee Summary Page |
| FR-STP-07 | Attendance View |
| FR-STP-08 | Timetable View |
| FR-STP-09 | Exam Schedule |
| FR-STP-10 | Results View |
| FR-STP-11 | My Learning (LMS Hub) |
| FR-STP-12 | Homework List |
| FR-STP-13 | Syllabus Progress |
| FR-STP-14 | My Teachers |
| FR-STP-15 | Progress Card (HPC) |
| FR-STP-16 | Performance Analytics |
| FR-STP-17 | Recommendations |
| FR-STP-18 | Library |
| FR-STP-19 | Transport Information |
| FR-STP-20 | Health Records |
| FR-STP-21 | Student ID Card |
| FR-STP-22 | Study Resources & Prescribed Books |
| FR-STP-23 | Notice Board |
| FR-STP-24 | School Calendar |
| FR-STP-25 | Leave Application |
| FR-STP-26 | Hostel Info |
| FR-STP-27 | Notifications |
| FR-STP-28 | Complaints |
| FR-STP-29 | Account Settings |
| FR-STP-30 | Online Exam / Quiz / Quest Players |

### 1.3 Out-of-Scope

| Area | Owned By |
|------|----------|
| Admin backend student record management | STD (StudentProfile) |
| Fee structure and invoice creation | FIN (StudentFee) |
| Payment processing logic and webhooks | Payment module |
| Complaint routing, assignment, resolution | CMP (Complaint) |
| LMS content authoring | LmsHomework / LmsQuiz / LmsQuests |

### 1.4 Module Scale

| Artifact | Current (Committed) | Req V2 Description | Target (Completion) |
|---|---|---|---|
| Controllers | 3 | 7 (1,317 lines) | 7 (refactored — split StudentPortalController) |
| Services | 0 | 0 | 1 (`StudentPortalService`) |
| FormRequests | 0 | 0 | 4+ minimum |
| Policies | 0 | 0 | 1 (`StudentPortalPolicy`) |
| Blade views | ~26 | 57 | ~65 |
| Routes (web) | ~15 | 55+ | 65+ |
| Routes (API) | 0 | 0 | 9 |
| Tables owned | 0 | 0 | 0 |
| Test files | 7 (scaffolding) | 7 (scaffolding) | 15+ |

### 1.5 Zero Owned Tables

STP has **no `stp_*` tables** in `tenant_db`. All data is read from (or written to) external module tables via their Eloquent models. No DDL migrations are needed for the STP module.

---

## 2. Screens Inventory (35 Screens)

Status key: ✅ Built | 🟡 Partial | ❌ Stub/Missing

**Note:** "Built" status is per the requirement v2 description. Actual committed code covers fewer screens — see Section 1.4 discrepancy note.

### Auth & Navigation

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 1 | Student Login | `GET student-portal/login` (public) | `auth/login` | ✅ | Rate limiting `throttle:5,2` not yet applied to login POST (FR-STP-01.5) |
| 2 | Dashboard | `GET student-portal/dashboard` | `dashboard/index` | ✅ | N+1 risk — multiple separate queries; `StudentPortalService::getDashboardData()` consolidation needed |
| 34 | Account Settings | `GET student-portal/account` | `account/index` (6 tab partials) | 🟡 | 3 tabs are view-only stubs: Security (no password change), Notification settings (no backend), Privacy settings (no backend) — FR-STP-29 |

### Academic

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 3 | Academic Information | `GET student-portal/academic-information` | `academic-information/details` | 🟡 | Uses `currentFeeAssignemnt` typo. Attendance/exam partials exist in view but data served from dedicated routes |
| 4 | Invoice View | `GET student-portal/view-invoice/{id}` | `academic-information/invoice` | 🟡 | ⚠️ **P0 IDOR**: `where('student_id', ...)` on `fee_invoices` is broken — `fee_invoices` has NO `student_id` column (confirmed in DDL). Fix: `whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', ...))` |
| 5 | Fee Payment Page | `GET student-portal/pay-due-amount/pay-now/{id}` | `academic-information/payment-page` | 🟡 | ⚠️ **P0 IDOR**: same broken guard as viewInvoice. `PaymentGateway::all()` should be `::active()->get()` |
| 6 | Fee Summary | `GET student-portal/fee-summary` | `fee/summary` | ✅ | Not yet committed (per code audit) |

### Schedule & Learning

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 7 | My Timetable | `GET student-portal/my-timetable` | `timetable/index` | ✅ | `StudentTimetableController` not yet committed |
| 8 | My Attendance | `GET student-portal/my-attendance` | `attendance/index` | ✅ | Missing date filter/range picker; `StudentProgressController` not yet committed |
| 9 | Syllabus Progress | `GET student-portal/syllabus-progress` | `syllabus/progress` | ✅ | `StudentProgressController` not yet committed |
| 10 | Exam Schedule | `GET student-portal/exam-schedule` | `exams/schedule` | ✅ | Filtered to PUBLISHED only; not yet committed |
| 11 | Results | `GET student-portal/results` | `results/index` | 🟡 | Shows concluded exam allocations; **no actual marks/grades** — requires `ExamResult` model integration (FR-STP-10.3) |
| 12 | My Learning Hub | `GET student-portal/my-learning` | `learning/index` | ✅ | Missing: homework submission; quiz/quest player links. `StudentLmsController` not yet committed |
| 13 | Homework List | (via learning hub or `/homework`) | `homework/index` | 🟡 | View exists; **no submission endpoint or file upload** (FR-STP-12.2) |
| 14 | Quiz List | (no route wired) | `quiz/index` | ❌ | View file exists; no routes or controller method (FR-STP-30) |
| 15 | Quest List | (no route wired) | `quest/index` | ❌ | View file exists; no routes or controller method (FR-STP-30) |
| 16 | Online Exam Player | (no route wired) | `online-exam/index` | ❌ | View file exists; no route or controller (FR-STP-30) |

### Progress

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 17 | My Teachers | `GET student-portal/my-teachers` | `teachers/index` | ✅ | `StudentTeachersController` not yet committed |
| 18 | Health Records | `GET student-portal/health-records` | `health/index` | ✅ | Not yet committed |
| 19 | Progress Card | `GET student-portal/progress-card` | `reports/progress-card` | ✅ | **Missing: PDF download button** per report (FR-STP-15.4) |
| 20 | Performance Analytics | `GET student-portal/performance-analytics` | `reports/analytics` | ✅ | Missing: subject-wise performance charts; quiz/assignment score aggregation |
| 21 | My Recommendations | `GET student-portal/my-recommendations` | `reports/recommendations` | ✅ | Not yet committed |

### People & Resources

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 22 | Library Catalog | `GET student-portal/library` | `library/index` | ✅ | Not yet committed |
| 23 | My Borrowed Books | `GET student-portal/library/my-books` | `library/my-books` | ✅ | Not yet committed |
| 25 | Study Resources | `GET student-portal/study-resources` | `resources/index` | ✅ | Not yet committed |
| 26 | Prescribed Books | `GET student-portal/prescribed-books` | `resources/prescribed-books` | ✅ | Not yet committed |

### Student Info

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 24 | Transport Info | `GET student-portal/transport` | `transport/index` | ✅ | Not yet committed |
| 29 | Student ID Card | `GET student-portal/student-id-card` | `id-card/index` | ✅ | **Missing: PDF download** (FR-STP-21.3) |
| 31 | Hostel Info | `GET student-portal/hostel` | `hostel/index` | ❌ | Stub — Hostel module pending (FR-STP-26) |

### Communication

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 32 | Notifications | `GET student-portal/all-notifications` | `notification/index` | ✅ | `mark-read` is GET — should be POST/PATCH (FR-STP-27.4) |
| 27 | Notice Board | `GET student-portal/notice-board` | `notice-board/index` | 🟡 | ⚠️ Wrong data source: reads from `sys_notifications` (user inbox) — should read from a dedicated announcement/notice model (FR-STP-23.2) |
| 33 | Complaints | `GET/POST student-portal/complaint` | `complaint/index` + `complaint/create` | ✅ | Hard-coded ID `104`; `created_by`-scoped listing correct but not paginated (FR-STP-28.5, 28.6) |

### Pending

| # | Screen Name | Route | View File | Status | Missing/Broken Items |
|---|---|---|---|---|---|
| 28 | School Calendar | `GET student-portal/school-calendar` | `calendar/index` | ❌ | Stub view; no data source wired (FR-STP-24) |
| 30 | Apply Leave | `GET student-portal/apply-leave` | `leave/index` | ❌ | Stub view; no form or endpoint (FR-STP-25) |

**Screen Summary: 22 ✅ | 8 🟡 | 5 ❌** (per requirement v2 description)

---

## 3. Security Audit Matrix

| Check | Current Status | Fix Required | FR/BR Reference |
|---|---|---|---|
| CSRF Protection | ✅ PASS | None — web middleware applied | — |
| Auth Middleware | ✅ PASS | Applied at route group | — |
| Role-Based Access (Student\|Parent) | ✅ PASS | `role:Student\|Parent` in tenant.php route group | FR-STP-01 |
| ⚠️ EnsureTenantHasModule | ❌ FAIL | Add `EnsureTenantHasModule:StudentPortal` to the portal route group middleware stack in `routes/tenant.php` | NFR.STP.10.2.2 |
| ⚠️ IDOR — viewInvoice | ❌ FAIL (was PARTIAL) | Current `->where('student_id', ...)` on `fee_invoices` is BROKEN — `fee_invoices` has NO `student_id` column (DDL confirmed). Fix: `FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', auth()->user()->student->id))->findOrFail($id)` | BR.STP.8.1.1, BR.STP.8.1.2 |
| ⚠️ IDOR — payDueAmount | ❌ FAIL (was PARTIAL) | Same broken guard as viewInvoice. Apply identical `whereHas` fix | BR.STP.8.1.1, BR.STP.8.1.2 |
| ⚠️ IDOR — proceedPayment | ❌ FAIL | `payable_id` submitted from client with zero server-side ownership check. Fix: before calling `PaymentService::createPayment()`, resolve the invoice: `$invoice = FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', auth()->user()->student->id))->findOrFail($request->payable_id); abort_if($invoice->balance_amount <= 0, 422, 'Invoice already paid');` | BR.STP.8.1.3, NFR.STP.10.2.1 |
| ⚠️ Gate/Policy calls | ❌ FAIL | Zero `Gate::authorize()` or `$this->authorize()` calls across all 3+ controllers. Create `StudentPortalPolicy` and register in `StudentPortalServiceProvider` | NFR.STP.10.2, S-STP-25 |
| ⚠️ FormRequest classes | ❌ FAIL | Zero FormRequest classes; inline validation or none. Create minimum 4 FormRequests (see Section 9) | S-STP-05 |
| ⚠️ PaymentGateway filter | ❌ FAIL | `payDueAmount()` uses `PaymentGateway::all()` — returns disabled gateways. Fix: `PaymentGateway::active()->get()` | BR.STP.8.2.3 |
| ⚠️ Hard-coded dropdown ID 104 | ❌ FAIL | `StudentPortalComplaintController` lines 73 and 125: `(int) $request->complainant_type_id === 104`. Fix: `$studentType = DB::table('sys_dropdowns')->where('key', 'COMPLAINANT_STUDENT')->value('id');` | BR.STP.8.5.3, S-STP-06 |
| ⚠️ test-notification route | ❌ UNKNOWN | `Route::get('test-notification', ...)` present in `routes/tenant.php` line 349. Must be removed or gated with `App::environment('local')` | S-STP-04 |
| Notifications mark-read (GET) | 🟡 WARN | `notifications/{id}/mark-read` is GET — vulnerable to prefetch attacks. Change to POST/PATCH | BR.STP.8.1.5, NFR.STP.10.2.7 |
| Complaint description HTML | 🟡 WARN | `description` field accepts arbitrary HTML. Add `strip_tags()` in `StoreComplaintRequest::prepareForValidation()` | NFR.STP.10.2.8 |
| File upload validation | 🟡 WARN | `complaint_img` upload has no explicit mime/size validation in current code. Add `mimes:jpg,jpeg,png,pdf\|max:5120` in FormRequest | NFR.STP.10.2.4 |
| SQL Injection | ✅ PASS | Eloquent ORM only; no raw queries | — |
| XSS | ✅ PASS | Blade `{{ }}` escaping applied | — |
| proceedPayment HTTP method | ✅ PASS (partially) | Committed code shows `Route::get(...)` for proceed-payment — **must be changed to POST** | — |
| Rate limiting — login | ❌ MISSING | No `throttle:5,2` on login POST | NFR.STP.10.2, FR-STP-01.5 |
| Rate limiting — payment | ❌ MISSING | No `throttle:3,5` on payment initiation route | BR.STP.8.2.5, NFR.STP.10.2.6 |

---

## 4. Business Rules (20 Rules)

### Group 1: Data Isolation (BR.STP.8.1.1 to BR.STP.8.1.6)

| Rule ID | Rule Text | Enforcement Status | Enforcement Point | Fix Required |
|---|---|---|---|---|
| BR.STP.8.1.1 | Student sees ONLY own data — zero cross-student access | ❌ Missing | `policy` | Create `StudentPortalPolicy`; call `$this->authorize('viewInvoice', $invoice)` in viewInvoice/payDueAmount |
| BR.STP.8.1.2 | Invoice ownership via `feeStudentAssignment` chain — NOT direct `student_id` on `fee_invoices` | ❌ Broken | `service_layer` / `policy` | Current guard `->where('student_id', ...)` is broken (column does not exist). Replace with `whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $student->id))` |
| BR.STP.8.1.3 | `payable_id` in `proceedPayment()` must be server-side verified before payment creation | ❌ Missing | `form_validation` / `service_layer` | Add ownership resolution in `ProcessPaymentRequest::authorize()` or at top of `proceedPayment()` |
| BR.STP.8.1.4 | Guardian with `can_access_parent_portal = 1` may only view linked child's data | 🟡 Partial | `middleware` | Role `Parent` middleware applied but no per-resource check linking parent to specific student |
| BR.STP.8.1.5 | Notification `mark-read` must verify notification belongs to `auth()->user()` | ✅ Enforced | `service_layer` | `auth()->user()->notifications()->findOrFail($id)` scopes correctly |
| BR.STP.8.1.6 | Complaint listing scoped to `created_by = Auth::id()` | ✅ Enforced | `service_layer` | Already correct in `StudentPortalComplaintController@index` |

### Group 2: Fee Payment (BR.STP.8.2.1 to BR.STP.8.2.5)

| Rule ID | Rule Text | Enforcement Status | Enforcement Point | Fix Required |
|---|---|---|---|---|
| BR.STP.8.2.1 | Only Payable invoices can be paid (Published / Partially Paid / Overdue); Paid and Cancelled are read-only | ❌ Missing | `policy` / `form_validation` | Add to `StudentPortalPolicy::payInvoice()`: check `in_array($invoice->status, ['Published','Partially Paid','Overdue'])` |
| BR.STP.8.2.2 | Min payment = INR 1; Max = `balance_amount` | 🟡 Partial | `form_validation` | `min:0.01` exists; `max` not validated against invoice balance. Add custom rule in `ProcessPaymentRequest` |
| BR.STP.8.2.3 | Gateway selection uses `PaymentGateway::active()->get()` only | ❌ Missing | `service_layer` | Replace `PaymentGateway::all()` → `PaymentGateway::active()->get()` in `payDueAmount()` |
| BR.STP.8.2.4 | Failed/cancelled payments must NOT update invoice status | ✅ Enforced | `db_constraint` | Webhook-driven; payment module handles; portal does not write invoice status |
| BR.STP.8.2.5 | Rate limiting: max 3 payment initiations per 5 minutes per user | ❌ Missing | `middleware` | Add `throttle:3,5` to `proceed-payment` route |

### Group 3: Timetable (BR.STP.8.3.1 to BR.STP.8.3.3)

| Rule ID | Rule Text | Enforcement Status | Enforcement Point | Fix Required |
|---|---|---|---|---|
| BR.STP.8.3.1 | Only timetables with status ACTIVE, GENERATED, or PUBLISHED are shown | ✅ Enforced (req) | `service_layer` | Status filter in `StudentTimetableController` (not yet committed) |
| BR.STP.8.3.2 | Timetable is read-only | ✅ Enforced | `middleware` | No write routes exist |
| BR.STP.8.3.3 | Break/non-teaching cells filtered out (`filter(fn($c) => !$c->is_break)`) | ✅ Enforced (req) | `service_layer` | Filter in controller (not yet committed) |

### Group 4: Attendance (BR.STP.8.4.1 to BR.STP.8.4.2)

| Rule ID | Rule Text | Enforcement Status | Enforcement Point | Fix Required |
|---|---|---|---|---|
| BR.STP.8.4.1 | Attendance is read-only; student cannot self-mark | ✅ Enforced | `middleware` | No write routes |
| BR.STP.8.4.2 | Attendance status values normalized (Present/P/present, Absent/A/absent, Late/L/late, Leave/leave) | ❌ Missing | `service_layer` | Add normalizer in `StudentAttendance` model accessor or in `StudentPortalService::getAttendanceSummary()` |

### Group 5: Complaint (BR.STP.8.5.1 to BR.STP.8.5.3)

| Rule ID | Rule Text | Enforcement Status | Enforcement Point | Fix Required |
|---|---|---|---|---|
| BR.STP.8.5.1 | Student can create and view own complaints; cannot edit/delete after submission | ✅ Enforced | `service_layer` | `created_by = Auth::id()` scope on listing; no edit/delete routes exposed |
| BR.STP.8.5.2 | `complainant_user_id` must be forced to `Auth::id()` | ❌ Missing | `form_validation` | Currently accepts client-submitted value; must hardcode to `auth()->id()` in FormRequest or service |
| BR.STP.8.5.3 | Hard-coded dropdown ID `104` replaced with key-based lookup | ❌ Missing | `service_layer` | See fix in Section 3 |

### Group 6: LMS Access (BR.STP.8.6.1 to BR.STP.8.6.3)

| Rule ID | Rule Text | Enforcement Status | Enforcement Point | Fix Required |
|---|---|---|---|---|
| BR.STP.8.6.1 | Homework shown to student must be PUBLISHED and assigned to their class+section | ✅ Enforced (req) | `service_layer` | Filter in `StudentLmsController` (not yet committed) |
| BR.STP.8.6.2 | Quiz/quest allocations respect `cut_off_date` — expired not shown | ✅ Enforced (req) | `service_layer` | Filter in `StudentLmsController` (not yet committed) |
| BR.STP.8.6.3 | Exam allocations must be PUBLISHED and match CLASS/SECTION/STUDENT targeting | ✅ Enforced (req) | `service_layer` | Filter in `StudentPortalController@examSchedule` (not yet committed) |

---

## 5. Workflow Diagrams

### 5.1 Fee Payment Workflow

```
Student → GET /pay-due-amount/pay-now/{id}
  → [SERVER] ⚠️ BROKEN GUARD: FeeInvoice::where('student_id', student->id)->findOrFail($id)
             fee_invoices has NO student_id column — this will throw QueryException or silently fail
             ← REQUIRED FIX: FeeInvoice::whereHas('feeStudentAssignment',
                  fn($q) => $q->where('student_id', student->id))->findOrFail($id)
  → Check invoice.status in [Published, Partially Paid, Overdue]  ← MISSING
  → ⚠️ PaymentGateway::all()  ← MUST BE ::active()->get()
  → Render academic-information/payment-page (gateway list, amount input)
  → Student selects gateway + enters amount
  → POST /pay-due-amount/proceed-payment  ← NOTE: currently committed as GET — MUST FIX
      → [SERVER] Inline validate: amount (min:0.01), payable_type, payable_id, gateway
      → ⚠️ ZERO ownership check on payable_id  ← P0 IDOR GAP
                 ← REQUIRED FIX: $invoice = FeeInvoice::whereHas('feeStudentAssignment',
                      fn($q) => $q->where('student_id', auth()->user()->student->id))
                      ->findOrFail($request->payable_id);
                    abort_if($invoice->balance_amount <= 0, 422, 'Invoice already paid');
      → PaymentService::createPayment([payable_type, payable_id, gateway, amount, currency])
      → Return checkout_data
  → Redirect to payment::razorpay.process-payment
  → Razorpay JS handles card/UPI capture
  → Razorpay webhook → update invoice status → notify student (handled by Payment module)
```

### 5.2 Complaint Submission Workflow

```
Student → GET /complaint/create
  → Load: ComplaintCategories (active parents) — correct
  → ⚠️ Load: User::select('id','name')->get()  ← loads ALL system users — should be scoped or removed
  → Student fills form; selects category
  → AJAX GET /complaint/ajax/subcategories/{category} → returns children (correct)
  → AJAX GET /complaint/ajax/subcategory-meta/{category} → returns severity/priority (correct)
  → POST /complaint
      → ⚠️ $request->merge([...]) injects DB-resolved dropdown IDs into request  ← anti-pattern
         Should move to StoreComplaintRequest::prepareForValidation()
      → Inline $request->validate([...]) — adequate but should be FormRequest
      → ⚠️ Hard-coded: if ((int) $request->complainant_type_id === 104)  ← FAIL
         Fix: resolve via DB::table('sys_dropdowns')->where('key','COMPLAINANT_STUDENT')->value('id')
      → ⚠️ complainant_user_id accepted from client  ← must be forced to auth()->id()
      → Ticket number auto-generated (CMP-YYYY-NNNNNN) — correct with lockForUpdate
      → Complaint::create([...]) with created_by = auth()->id() — correct
      → Media upload via Spatie — correct
      → Redirect with success flash
```

### 5.3 Dashboard Data Aggregation Workflow

```
Student → GET /dashboard
  → auth()->user()->notifications()->latest()->paginate(10)  ← in StudentPortalController@dashboard
  ← NOTE: Committed dashboard loads ONLY notifications; all other data (attendance, timetable,
           homework, exams, fee) described as "fully populated" in req v2 is in uncommitted code
  ← CURRENT COMMITTED STATE: dashboard passes only $notifications to view
  ← TARGET STATE (per req v2):
      ├── Load student + currentSession (with classSection, class, section)
      ├── Attendance: StudentAttendance count (total + present) for current session
      ├── Timetable: TimetableCell for today's day_of_week (status: ACTIVE|GENERATED|PUBLISHED)
      ├── Homework: published, not submitted by student, due-date sorted, limit 5
      ├── Exams: ExamAllocation PUBLISHED, future, CLASS+SECTION+STUDENT scope, limit 5
      └── Fee: currentFeeAssignment invoices sum (total, paid, due, pending count)
  → Load notifications (paginate 10)
  → Render dashboard/index view

  ⚠️ N+1 RISK: All data loads should be consolidated in StudentPortalService::getDashboardData()
               using a single eager-load chain, not separate controller queries
```

---

## 6. Functional Requirements Summary (30 FRs)

| FR ID | Name | Status | Controller@Method | Tables Used | Key Gaps | Priority |
|---|---|---|---|---|---|---|
| FR-STP-01 | Student Login | ✅ | `StudentPortalController@login` | `sys_users` | Rate limiting missing | P1 |
| FR-STP-02 | Student Dashboard | 🟡 | `StudentPortalController@dashboard` | `sys_users`, `sys_notifications` | Only notifications loaded; attendance/timetable/homework/exams/fee in uncommitted code; N+1 risk | P1 |
| FR-STP-03 | Academic Information | 🟡 | `StudentPortalController@academicInformation` | `std_students`, `std_student_profiles`, `std_guardians`, `fee_student_assignments`, `fee_invoices` | `currentFeeAssignemnt` typo; IDOR risk in invoice chain | P0 |
| FR-STP-04 | Fee Invoice View | ❌ BROKEN | `StudentPortalController@viewInvoice` | `fee_invoices` | BROKEN guard — `fee_invoices` has no `student_id` column | P0 |
| FR-STP-05 | Fee Payment | ❌ BROKEN | `StudentPortalController@payDueAmount`, `@proceedPayment` | `fee_invoices`, `pay_payment_gateways` | BROKEN guard; `::all()` gateways; proceedPayment IDOR; route is GET not POST | P0 |
| FR-STP-06 | Fee Summary | ✅ (req) | `StudentPortalController@feeSummary` | `fee_student_assignments`, `fee_invoices` | Not yet committed | P1 |
| FR-STP-07 | Attendance View | ✅ (req) | `StudentProgressController@attendance` | `std_student_attendance` | Controller not committed; date filter missing | P1 |
| FR-STP-08 | Timetable View | ✅ (req) | `StudentTimetableController@index` | `tt_timetable_cells`, `tt_school_days` | Controller not committed | P1 |
| FR-STP-09 | Exam Schedule | ✅ (req) | `StudentPortalController@examSchedule` | `exm_exam_allocations` | Method not committed | P1 |
| FR-STP-10 | Results View | 🟡 | `StudentPortalController@results` | `exm_exam_allocations` | No actual marks/grades; requires `ExamResult` integration | P2 |
| FR-STP-11 | My Learning Hub | ✅ (req) | `StudentLmsController@index` | `hmw_homeworks`, `hmw_homework_submissions`, `exm_exam_allocations`, `quz_quiz_allocations`, `qst_quest_allocations` | Controller not committed; submission links missing | P1 |
| FR-STP-12 | Homework List | 🟡 | (via learning hub) | `hmw_homeworks`, `hmw_homework_submissions` | No submission endpoint | P2 |
| FR-STP-13 | Syllabus Progress | ✅ (req) | `StudentProgressController@syllabusProgress` | `slb_syllabus_schedules` | Controller not committed | P1 |
| FR-STP-14 | My Teachers | ✅ (req) | `StudentTeachersController@index` | `tt_timetable_cells` | Controller not committed | P1 |
| FR-STP-15 | Progress Card | ✅ (req) | `StudentPortalController@progressCard` | `hpc_reports` | Method not committed; PDF download missing | P2 |
| FR-STP-16 | Performance Analytics | ✅ (req) | `StudentPortalController@performanceAnalytics` | `std_student_attendance`, `exm_exam_allocations` | Method not committed; subject charts missing | P2 |
| FR-STP-17 | Recommendations | ✅ (req) | `StudentPortalController@myRecommendations` | `rec_student_recommendations` | Method not committed | P2 |
| FR-STP-18 | Library | ✅ (req) | `StudentPortalController@library`, `@libraryMyBooks` | `lib_book_masters`, `lib_members`, `lib_transactions` | Methods not committed; reservation missing | P2 |
| FR-STP-19 | Transport Info | ✅ (req) | `StudentPortalController@transport` | `tpt_student_allocation_jnt` | Method not committed | P2 |
| FR-STP-20 | Health Records | ✅ (req) | `StudentPortalController@healthRecords` | `std_health_profiles` | Method not committed | P2 |
| FR-STP-21 | Student ID Card | ✅ (req) | `StudentPortalController@idCard` | `std_students`, `std_student_profiles` | Method not committed; PDF download missing | P2 |
| FR-STP-22 | Study Resources & Books | ✅ (req) | `StudentPortalController@studyResources`, `@prescribedBooks` | `bok_books`, `bok_book_class_subjects` | Methods not committed | P2 |
| FR-STP-23 | Notice Board | 🟡 | `StudentPortalController@noticeBoard` | `sys_notifications` (wrong source) | Wrong data source — should be `sch_notices` or `sys_announcements` | P2 |
| FR-STP-24 | School Calendar | ❌ | `StudentPortalController@schoolCalendar` | None yet | Stub view; no data source | P3 |
| FR-STP-25 | Leave Application | ❌ | `StudentPortalController@applyLeave` | None yet | Stub view; no form, endpoint, or model | P2 |
| FR-STP-26 | Hostel Info | ❌ | `StudentPortalController@hostel` | Hostel module pending | Stub view; depends on pending HST module | P3 |
| FR-STP-27 | Notifications | ✅ | `NotificationController@allNotifications`, `@markRead`, `@markAllRead` | `sys_notifications` | `mark-read` is GET (should be POST/PATCH) | P1 |
| FR-STP-28 | Complaints | ✅ | `StudentPortalComplaintController@index`, `@create`, `@store` | `cmp_complaints`, `cmp_complaint_categories`, `sys_dropdowns` | Hard-coded ID 104; not paginated; `complainant_user_id` client-injectable | P1 |
| FR-STP-29 | Account Settings | 🟡 | `StudentPortalController@account` | `std_students`, `std_student_profiles` | 3 tabs are stubs: password change, notification prefs, privacy | P2 |
| FR-STP-30 | Online Exam/Quiz/Quest Players | ❌ | No controller methods | None yet | Views exist; no routes wired | P3 |

---

## 7. External Module Dependencies Matrix

| Module | Direction | Tables/Models Used | STP Method(s) | FK Chain | IDOR Risk |
|---|---|---|---|---|---|
| StudentProfile (STD) | Incoming | `std_students`, `std_student_profiles`, `std_student_addresses`, `std_guardians`, `std_student_guardian_jnt`, `std_student_academic_sessions`, `std_health_profiles`, `std_student_attendance` | `dashboard`, `account`, `academicInformation`, `attendance`, `healthRecords`, `idCard` | `user → student → profile/addresses/sessions/healthProfile` | Medium — ensure all queries scope to `auth()->user()->student->id` |
| StudentFee (FIN) | Incoming | `fee_student_assignments`, `fee_invoices` | `academicInformation`, `viewInvoice`, `payDueAmount`, `proceedPayment`, `feeSummary` | `student → feeAssignment → invoices` | **P0 CRITICAL** — `fee_invoices` has no `student_id`; ownership is via `feeStudentAssignment` chain only |
| Payment | Outgoing | `pay_payment_gateways` (read), creates payment order | `payDueAmount`, `proceedPayment` | N/A — calls `PaymentService::createPayment()` | High — `payable_id` must be server-validated before hand-off to PaymentService |
| Notification | Incoming | `sys_notifications` (via Laravel Notifiable) | `dashboard`, `allNotifications`, `markRead`, `markAllRead` | `user → notifications()` | Low — scoped via `auth()->user()->notifications()` (correct) |
| Complaint (CMP) | Outgoing | `cmp_complaints` (write), `cmp_complaint_categories` (read) | `complaint.index`, `complaint.store`, AJAX endpoints | `complaint.created_by = Auth::id()` | Low — write scoped to auth user; listing scoped to `created_by` |
| TimetableFoundation | Incoming | `tt_timetable_cells`, `tt_school_days` | `timetable`, `dashboard` (today's cells), `myTeachers` | `timetable_cells.class_id + section_id = student.currentSession.class+section` | Low — read-only, scoped to student's class+section |
| LmsExam | Incoming | `exm_exam_allocations` | `examSchedule`, `results`, `dashboard` | `exam_allocations.target_type + target_id = student/class/section` | Low — PUBLISHED filter applied |
| LmsHomework | Incoming | `hmw_homeworks`, `hmw_homework_submissions` | `myLearning`, `homework` | `homeworks.class_id + section_id + submissions.student_id` | Low — filtered to class+section |
| LmsQuiz | Incoming | `quz_quiz_allocations` | `myLearning`, `quiz` (planned) | `quiz_allocations.target = class/section/student` | Low |
| LmsQuests | Incoming | `qst_quest_allocations` | `myLearning`, `quest` (planned) | `quest_allocations.target = class/section/student` | Low |
| Syllabus (SLB) | Incoming | `slb_syllabus_schedules` | `syllabusProgress` | `schedules.class_id + section_id + academic_session_id` | Low |
| HPC | Incoming | `hpc_reports` | `progressCard` | `hpc_reports.student_id = student->id AND status = 'Published'` | Low |
| Recommendation (REC) | Incoming | `rec_student_recommendations` | `myRecommendations` | `student_recommendations.student_id = student->id` | Low |
| Library (LIB) | Incoming | `lib_book_masters`, `lib_members`, `lib_transactions` | `library`, `libraryMyBooks` | `lib_members.student_id → lib_transactions` | Low |
| Transport (TPT) | Incoming | `tpt_student_allocation_jnt` | `transport` | `allocation.student_id = student->id AND active_status = true` | Low |
| SyllabusBooks (BOK) | Incoming | `bok_books`, `bok_book_class_subjects` | `studyResources`, `prescribedBooks` | `book_class_subjects.class_id = student.currentSession.class_id` | Low |
| Hostel (HST) | Incoming | Pending | `hostel` | Pending | N/A |

### 7.1 Student Model Relationship Chain (Full)

```
auth()->user() [sys_users]
    └── student [std_students]              → $user->student
         ├── profile [std_student_profiles] → $user->student->profile
         ├── addresses [std_student_addresses]
         ├── studentGuardianJnts [std_student_guardian_jnt]
         │    └── guardian [std_guardians]
         ├── sessions [std_student_academic_sessions]
         │    └── classSection → class (sch_classes) + section (sch_sections)
         ├── currentSession() — returns latest active std_student_academic_sessions
         ├── currentFeeAssignemnt  ← ⚠️ TYPO in Student model — missing 'g'
         │    → CORRECT NAME: currentFeeAssignment
         │    → Used in: StudentPortalController@academicInformation (lines 55, 59)
         │    ├── feeStructure.details.head
         │    └── invoices [fee_invoices]   ← NO student_id on fee_invoices table
         │         → ownership: fee_invoices.student_assignment_id → fee_student_assignments.student_id
         ├── feeAssignment [fee_student_assignments]   ← separate relationship
         ├── healthProfile [std_health_profiles]
         └── studentDetail [? - exact model TBD]
```

**Typo Location:** `Student` model method `currentFeeAssignemnt()` — must be renamed to `currentFeeAssignment`. Update all callers:
- `StudentPortalController.php` line 55: `'student.currentFeeAssignemnt.feeStructure.details.head'`
- `StudentPortalController.php` line 56: `'student.currentFeeAssignemnt.invoices'`
- `StudentPortalController.php` line 59: `$user->student->currentFeeAssignemnt`

---

## 8. Service Architecture (Target)

### StudentPortalService

```
File:      Modules/StudentPortal/app/Services/StudentPortalService.php
Namespace: Modules\StudentPortal\app\Services
Purpose:   Consolidate dashboard aggregation, attendance summary, fee summary, and
           syllabus progress logic out of fat controller into dedicated service
```

| Method | Signature | Purpose | N+1 Fix |
|---|---|---|---|
| `getDashboardData` | `getDashboardData(Student $student): array` | Loads all 5 dashboard data sets in one eager-load chain | Replaces 5+ separate queries in `dashboard()` with single `with([...])` chain |
| `getAttendanceSummary` | `getAttendanceSummary(Student $student, int $sessionId): array` | Total/present/absent/late/leave counts + %; grouped by month | Eager-load attendance once; group in PHP |
| `getFeeSummary` | `getFeeSummary(Student $student): array` | All invoices for current fee assignment; total/paid/due/count | Loads via `feeStudentAssignment.invoices` relationship |
| `getSyllabusProgress` | `getSyllabusProgress(Student $student, int $classId, int $sectionId, int $sessionId): array` | Topics grouped by subject; per-topic status from date comparison | Eager-load schedules once; derive status in PHP |

**getDashboardData internals:**
```php
// Single eager-load — no N+1
$student->loadMissing([
    'currentSession.classSection.class',
    'currentSession.classSection.section',
    'currentFeeAssignment.invoices',
    'healthProfile',
]);
// Then separate scoped queries for:
// - Attendance count (aggregate)
// - Today's timetable cells (TimetableCell WHERE day_of_week = today, class_id, section_id, status IN [...])
// - Pending homework 5 (Homework WHERE class+section, published, not submitted, limit 5)
// - Upcoming exams 5 (ExamAllocation WHERE target=class/section/student, PUBLISHED, future, limit 5)
// These 4 queries are unavoidable cross-module lookups; wrap in parallel using eager-load hints
```

**Controllers must remain thin:** Call `StudentPortalService` and pass result to view. Zero business logic in controller methods after refactor.

---

## 9. FormRequest Architecture (Target)

| Class | File | Controller Method | `authorize()` Logic | Priority |
|---|---|---|---|---|
| `StoreComplaintRequest` | `app/Http/Requests/StoreComplaintRequest.php` | `StudentPortalComplaintController@store` | `auth()->user()->hasRole('Student')` | P1 |
| `ProcessPaymentRequest` | `app/Http/Requests/ProcessPaymentRequest.php` | `StudentPortalController@proceedPayment` | FeeInvoice ownership check via `feeStudentAssignment` chain | P0 |
| `LeaveApplicationRequest` | `app/Http/Requests/LeaveApplicationRequest.php` | (future) `StudentPortalController@storeLeave` | `auth()->user()->hasRole('Student\|Parent')` | P2 |
| `PasswordChangeRequest` | `app/Http/Requests/PasswordChangeRequest.php` | (future) `StudentPortalController@changePassword` | `auth()->check()` | P2 |

### StoreComplaintRequest Rules

```php
public function authorize(): bool {
    return auth()->user()->hasRole('Student');
}

public function prepareForValidation(): void {
    // Move $request->merge() out of controller — resolve dropdown IDs here
    $this->merge([
        'complainant_type_id' => DB::table('sys_dropdowns')
            ->where('key', 'complainant_type')
            ->where('value', $this->complainant_type_id)
            ->value('id'),
        'target_type_id' => DB::table('sys_dropdowns')
            ->where('key', 'target_user_type')
            ->where('value', $this->target_type_id)
            ->value('id'),
        'complainant_user_id' => auth()->id(),  // Force to auth user — never trust client
        'description' => strip_tags($this->description),  // Sanitize HTML
    ]);
}

public function rules(): array {
    return [
        'target_type_id'      => 'required|exists:sys_dropdowns,id',
        'complainant_type_id' => 'required|exists:sys_dropdowns,id',
        'category_id'         => 'required|exists:cmp_complaint_categories,id',
        'subcategory_id'      => 'nullable|exists:cmp_complaint_categories,id',
        'severity_level_id'   => 'required',
        'title'               => 'required|string|max:200',
        'description'         => 'nullable|string|max:5000',
        'location_details'    => 'nullable|string|max:255',
        'incident_date'       => 'nullable|date',
        'complaint_img'       => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120',
    ];
}
```

### ProcessPaymentRequest Rules

```php
public function authorize(): bool {
    // Ownership verified here — not in controller
    $student = auth()->user()->student;
    $invoice = FeeInvoice::whereHas('feeStudentAssignment',
        fn($q) => $q->where('student_id', $student->id)
    )->find($this->payable_id);

    if (!$invoice) return false;
    if ($invoice->balance_amount <= 0) abort(422, 'Invoice already paid');
    if (!in_array($invoice->status, ['Published', 'Partially Paid', 'Overdue'])) return false;

    // Share resolved invoice with controller
    $this->merge(['_resolved_invoice' => $invoice]);
    return true;
}

public function rules(): array {
    return [
        'amount'       => ['required', 'numeric', 'min:0.01',
                           Rule::when(fn() => $this->_resolved_invoice,
                               'max:' . $this->_resolved_invoice->balance_amount)],
        'payable_type' => 'required|string|in:fee_invoice',
        'payable_id'   => 'required|integer',
        'gateway'      => 'required|string|in:razorpay,stripe,paytm,phonepe',
    ];
}
```

---

## 10. Policy Architecture (Target)

### StudentPortalPolicy

```
File:      Modules/StudentPortal/app/Policies/StudentPortalPolicy.php
Namespace: Modules\StudentPortal\app\Policies
Register:  StudentPortalServiceProvider — Gate::policy(FeeInvoice::class, StudentPortalPolicy::class)
```

| Method | Signature | Authorization Logic |
|---|---|---|
| `viewInvoice` | `viewInvoice(User $user, FeeInvoice $invoice): bool` | Check invoice belongs to student: `FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $user->student->id))->where('id', $invoice->id)->exists()` |
| `payInvoice` | `payInvoice(User $user, FeeInvoice $invoice): bool` | `viewInvoice($user, $invoice)` AND `in_array($invoice->status, ['Published','Partially Paid','Overdue'])` AND `$invoice->balance_amount > 0` |
| `createComplaint` | `createComplaint(User $user): bool` | `$user->hasRole('Student')` |

**Controller usage:**
```php
// In StudentPortalController@viewInvoice:
$this->authorize('viewInvoice', $feeInvoice);

// In StudentPortalController@payDueAmount + proceedPayment:
$this->authorize('payInvoice', $feeInvoice);
```

**Registration in StudentPortalServiceProvider:**
```php
use Illuminate\Support\Facades\Gate;
use Modules\StudentFee\Models\FeeInvoice;
use Modules\StudentPortal\Policies\StudentPortalPolicy;

public function boot(): void {
    Gate::policy(FeeInvoice::class, StudentPortalPolicy::class);
}
```

---

## 11. Test Plan Outline

### 11.1 Test Setup

```php
// tests/Pest.php — already exists in module
uses(Tests\TestCase::class, RefreshDatabase::class)->in('Feature');

// Factory helpers needed:
// StudentFactory: User with Spatie role 'Student' + linked std_students record
// ParentFactory: User with role 'Parent' + linked via std_student_guardian_jnt (can_access_parent_portal=1)
// AdminFactory: User with 'Admin' role — must be BLOCKED from portal routes
// Event::fake() for notification tests
// Mock PaymentService — bind interface → mock in test AppServiceProvider
// IDOR tests: two students A and B; student A attempts to access B's resources
```

### 11.2 P0 Security Tests

| ID | Scenario | Expected Result | FR/BR Reference |
|---|---|---|---|
| T-STP-001 | Student A calls `GET /student-portal/view-invoice/{B_invoice_id}` (student B's invoice) | 404 or 403 — must not return invoice data | BR.STP.8.1.1, BR.STP.8.1.2 |
| T-STP-002 | Student A POSTs `proceed-payment` with `payable_id` = student B's invoice ID | 403 Forbidden or 422 Unprocessable — payment must fail | BR.STP.8.1.3 |
| T-STP-003 | Admin user (non-student) calls `GET /student-portal/dashboard` | Redirect or 403 — must not serve portal | FR-STP-01 |
| T-STP-004 | Unauthenticated call to `GET /student-portal/dashboard` | Redirect to login | FR-STP-01 |
| T-STP-005 | Student marks another user's notification as read | 403 or 404 | BR.STP.8.1.5 |

### 11.3 P1 Functional Tests

| ID | Scenario | Expected Result | FR Reference |
|---|---|---|---|
| T-STP-010 | Student with active session sees timetable grid with correct subjects | Grid populated; break cells excluded | FR-STP-08 |
| T-STP-011 | Student with no session sees timetable with `noSession` flag | View renders; no exception | FR-STP-08 |
| T-STP-012 | Dashboard fee summary shows correct total/paid/due | Correct numeric values | FR-STP-02 |
| T-STP-013 | Dashboard pending homework count matches unsubmitted published homework | Count accurate | FR-STP-02 |
| T-STP-014 | Attendance page groups records by month correctly | Group keys match "March 2026" format | FR-STP-07 |
| T-STP-015 | Complaint is created with `created_by = auth()->id()` and `complainant_user_id = auth()->id()` | Complaint stored; both fields locked to auth user | FR-STP-28 |
| T-STP-016 | Complaint listing shows only own complaints | Other students' complaints not visible | FR-STP-28, BR.STP.8.1.6 |
| T-STP-017 | Payment page shows only active gateways | Disabled gateways excluded | BR.STP.8.2.3 |
| T-STP-018 | `mark-all-read` marks only authenticated user's notifications | Other users' notifications unaffected | BR.STP.8.1.5 |

### 11.4 P2 Regression Tests

| ID | Scenario | Expected Result | FR Reference |
|---|---|---|---|
| T-STP-020 | Syllabus progress shows correct completed/in_progress/upcoming per topic | Status derived correctly from scheduled dates vs today | FR-STP-13 |
| T-STP-021 | My teachers page shows unique teacher list from timetable cells | No duplicate teachers; subject+day data correct | FR-STP-14 |
| T-STP-022 | Library my-books shows empty state for student with no library membership | Empty state rendered; no exception | FR-STP-18 |
| T-STP-023 | Transport page shows empty state for student with no allocation | Empty state rendered | FR-STP-19 |
| T-STP-024 | Progress card shows only `Published` status reports | Draft/unpublished reports excluded | FR-STP-15 |
| T-STP-025 | `EnsureTenantHasModule` blocks portal access when STP module is disabled for tenant | Redirect or 403 | NFR.STP.10.2.2 |

---

## Appendix A — Priority Summary (Action Items)

### P0 — Fix Before Any Production Deployment

| # | Issue | File | Fix |
|---|---|---|---|
| P0-01 | IDOR: `viewInvoice()` — broken guard (`student_id` does not exist on `fee_invoices`) | `StudentPortalController.php` | Replace `->where('student_id', ...)` with `->whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $student->id))` |
| P0-02 | IDOR: `payDueAmount()` — same broken guard | `StudentPortalController.php` | Same fix as P0-01 |
| P0-03 | IDOR: `proceedPayment()` — zero ownership check on `payable_id` | `StudentPortalController.php` | Add `FeeInvoice::whereHas(...)` resolution before `PaymentService::createPayment()` |
| P0-04 | `proceed-payment` route is GET not POST | `routes/tenant.php` | Change to `Route::post(...)` |
| P0-05 | `EnsureTenantHasModule` middleware missing from portal route group | `routes/tenant.php` | Add to middleware array |
| P0-06 | `test-notification` route exposed in production | `routes/tenant.php` | Remove or wrap in `App::environment('local')` |

### P1 — Current Sprint

| # | Issue | Fix |
|---|---|---|
| P1-01 | Typo `currentFeeAssignemnt` in Student model + 3 controller callers | Rename to `currentFeeAssignment` |
| P1-02 | `PaymentGateway::all()` shows disabled gateways | → `::active()->get()` |
| P1-03 | Hard-coded dropdown ID `104` | Replace with key-based lookup |
| P1-04 | `complainant_user_id` client-injectable | Force to `auth()->id()` in FormRequest |
| P1-05 | Complaint listing not paginated | Add `->paginate(15)` |
| P1-06 | `mark-read` is GET not POST | Change to POST/PATCH |
| P1-07 | Create `StoreComplaintRequest` + `ProcessPaymentRequest` | See Section 9 |
| P1-08 | Remove scaffold stubs from `StudentPortalController` | Delete `index/create/store/show/edit/update/destroy` methods |
| P1-09 | Commit/implement 4 missing controllers | `StudentLmsController`, `StudentProgressController`, `StudentTeachersController`, `StudentTimetableController` |
| P1-10 | Wire all 55+ routes in `routes/tenant.php` | Per Section 6 route table in requirement |

### P2 — Next Sprint

| # | Feature |
|---|---|
| P2-01 | `StudentPortalService` — extract dashboard + attendance + fee + syllabus logic |
| P2-02 | `StudentPortalPolicy` — `viewInvoice`, `payInvoice`, `createComplaint` |
| P2-03 | Leave application form + endpoint + `LeaveApplicationRequest` |
| P2-04 | School calendar (FullCalendar.js + data source) |
| P2-05 | Account settings backend: password change, notification prefs, privacy |
| P2-06 | Homework submission endpoint from portal |
| P2-07 | Results with actual marks (ExamResult model integration) |
| P2-08 | Wire quiz + quest list screens with routes |
| P2-09 | Fix notice board data source (sys_announcements or sch_notices) |
| P2-10 | PDF download for progress card + ID card |

### P3 — Backlog

| # | Feature |
|---|---|
| P3-01 | REST API (9 endpoints — Section 6.2 of requirement) |
| P3-02 | Parent dashboard separation (child-switcher) |
| P3-03 | Hostel info integration (when HST module complete) |
| P3-04 | Push notifications (FCM) |
| P3-05 | Rate limiting: `throttle:5,2` on login POST; `throttle:3,5` on payment |
