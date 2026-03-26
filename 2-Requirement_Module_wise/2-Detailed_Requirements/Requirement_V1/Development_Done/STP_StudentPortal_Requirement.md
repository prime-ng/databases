# StudentPortal Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** STP | **Module Path:** `Modules/StudentPortal`
**Module Type:** Tenant Module | **Database:** `tenant_{uuid}`
**Table Prefix:** `std_*` (shared with StudentProfile) | **Completion:** ~25%
**RBS Reference:** Module E — Student Information System (lines 2203–2282) + Module Z (partial)

---

> **CRITICAL SECURITY NOTICE:** This module has a confirmed **IDOR (Insecure Direct Object Reference) vulnerability** on invoice and payment endpoints. Students can access other students' fee invoices by manipulating the invoice `{id}` parameter. Zero Gate authorization exists in any of the 3 controllers. This must be treated as a P0 security defect requiring immediate remediation before production deployment.

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

StudentPortal is the **student-facing self-service interface** of Prime-AI. It provides a dedicated portal where students (and their parents/guardians, when parent portal access is granted) can view their academic information, pay fee invoices, access notifications, submit complaints, and track their school activities without requiring access to the administrative backend.

The portal operates on the same tenant infrastructure as the admin interface but renders a completely different UI experience tailored for students.

### 1.2 Module Position in the Platform

```
Actor               Module                  Role
──────────────────────────────────────────────────────────────────────
Student / Parent    StudentPortal (STP)     Self-service portal
Admin / Teacher     StudentProfile (STD)    Student record management
Admin / Accountant  StudentFee (FIN)        Fee management backend
System              Payment module          Razorpay gateway integration
System              Notification module     SMS/email/push alerts
System              Complaint module        Complaint routing engine
```

### 1.3 Module Characteristics

| Attribute            | Value                                                             |
|----------------------|-------------------------------------------------------------------|
| Laravel Module       | `nwidart/laravel-modules` v12, name `StudentPortal`               |
| Namespace            | `Modules\StudentPortal`                                           |
| Module Code          | STP                                                               |
| Domain               | Tenant (school-specific subdomain) — student-facing pages         |
| DB Connection        | `tenant` (tenant_{uuid})                                          |
| Table Prefix         | `std_*` (shared with StudentProfile)                              |
| Auth                 | Laravel Auth (STUDENT user_type) — Spatie Gates NOT used — P0 gap |
| Controllers          | 3 (StudentPortalController, StudentPortalComplaintController, NotificationController) |
| Models               | 0 (uses models from StudentProfile and StudentFee modules)         |
| Services             | 0                                                                 |
| FormRequests         | 0 (validation inline — P1 gap)                                    |
| Tests                | 7 (3 Feature + 3 Unit + 1 Pest config)                            |
| Screens Built        | 3 of 27 designed screens (11% complete)                           |
| Payment Gateway      | Razorpay (via Payment module)                                     |

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Student login / authentication (shared Laravel Auth with `user_type = STUDENT`)
- Student dashboard (overview, recent notifications, fee summary)
- Academic information view (profile, attendance, health profile, guardian info, fee details)
- Fee invoice view and online payment initiation via Razorpay
- Notification listing (all, unread, mark read, mark all read)
- Complaint submission and listing (student-specific complaints via Complaint module)
- Account settings (profile, security, notification preferences, billing/payments summary)

### 2.2 Out of Scope (Pending — Not Yet Built)

- Timetable view (SmartTimetable integration)
- Homework listing and submission (LmsHomework integration)
- Quiz / Assessment results (LmsQuiz / LmsQuests integration)
- Exam schedule and results (LmsExam integration)
- Attendance report view (detailed monthly/yearly)
- Subject-wise progress tracker
- Library card / book borrowing history
- Transport route information
- Document download (TC, marksheets)
- Certificate request submission
- Parent-specific portal view (separate from student view)
- Push notifications / mobile app integration
- Chat / messaging with teachers

### 2.3 Module Dependencies

| Dependency              | Direction  | Purpose                                              |
|-------------------------|------------|------------------------------------------------------|
| StudentProfile (STD)    | Incoming   | Student, Guardian, AcademicSession, HealthProfile    |
| StudentFee (FIN)        | Incoming   | FeeStudentAssignment, FeeInvoice models for fee view |
| Payment module          | Outgoing   | PaymentService for Razorpay order creation           |
| Notification module     | Incoming   | User notifications (read, mark-read)                 |
| Complaint module        | Outgoing   | Complaint, ComplaintCategory models                  |
| SmartTimetable          | Planned    | Timetable view (not yet integrated)                  |
| LmsHomework             | Planned    | Homework view (not yet integrated)                   |

---

## 3. Actors and User Roles

| Actor                 | Access Level                                                                    |
|-----------------------|---------------------------------------------------------------------------------|
| Student               | Primary actor. Full access to own portal data; zero access to other students'   |
| Parent / Guardian     | Portal access when `can_access_parent_portal = 1` in guardian junction; reads child's data |
| School Admin          | Manages student login credentials; grants/revokes portal access                 |

### 3.1 Authentication Model

- Student portal uses the same Laravel Auth (`sys_users` table) as admin users
- Student accounts have `user_type = 'STUDENT'` in `sys_users`
- Portal login is available at `student-portal/login` (unauthenticated route)
- After login, the standard `auth + verified` middleware stack applies

---

## 4. Functional Requirements

### 4.1 Student Login (Built — Screen 1)

**REF: ST.E5.1.1.1 to ST.E5.1.2.2**

- `ST.STP.4.1.1` — Student authenticates using email/username and password
- `ST.STP.4.1.2` — Login form rendered at `/student-portal/login` (custom view `studentportal::auth.login`)
- `ST.STP.4.1.3` — Failed login shows validation errors; successful login redirects to dashboard
- `ST.STP.4.1.4` — "Forgot password" flow uses standard Laravel password reset

### 4.2 Student Dashboard (Built — Screen 2)

**REF: Module Z — Student Portal Dashboard**

- `ST.STP.4.2.1` — After login, student lands on `/student-portal/dashboard`
- `ST.STP.4.2.2` — Dashboard displays latest notifications (paginated, 10 per page) from `auth()->user()->notifications()`
- `ST.STP.4.2.3` — Dashboard must show quick stats: attendance percentage, outstanding fee amount, pending homework count — **PARTIALLY BUILT** (notifications shown; other stats not yet integrated)
- `ST.STP.4.2.4` — Quick navigation cards/tiles to major portal sections

### 4.3 Academic Information View (Built — Screen 3)

**REF: ST.E1.1.2.1, ST.E2.1.1.1, ST.E3.2.1.1, ST.E4.1.1.1**

- `ST.STP.4.3.1` — Full student profile display: personal details, guardian information, addresses, academic session (class, section, roll number)
- `ST.STP.4.3.2` — Health profile summary: blood group, allergies, chronic conditions
- `ST.STP.4.3.3` — Fee assignment overview: current fee structure, opted heads, total fee amount
- `ST.STP.4.3.4` — Invoice list: latest invoice displayed prominently; older invoices in chronological list (newest first)
- `ST.STP.4.3.5` — Attendance records partial view — rendered in `_attendance-records.blade.php` but data binding not complete
- `ST.STP.4.3.6` — Academic performance partial view — rendered in `_academic-performance.blade.php` but exam data not integrated

### 4.4 Fee Invoice View (Built — Screen 3a)

**REF: ST.J3.1.2.1, ST.J3.2.1.1**

- `ST.STP.4.4.1` — Student can view individual invoice at `/student-portal/view-invoice/{invoice}`
- `ST.STP.4.4.2` — Invoice detail shows: invoice number, date, due date, base amount, concession, fine, tax, total, paid amount, balance due, status
- `ST.STP.4.4.3` — Invoice view uses `FeeInvoice::findOrFail($id)` — **IDOR VULNERABILITY: no ownership check**

### 4.5 Fee Payment (Built — Screen 3b)

**REF: ST.J3.2.1.1, ST.J3.2.1.2**

- `ST.STP.4.5.1` — Student initiates payment from `/student-portal/pay-due-amount/pay-now/{invoice}`
- `ST.STP.4.5.2` — Payment gateway selection (currently shows all gateways via `PaymentGateway::all()` — should filter to `active()`)
- `ST.STP.4.5.3` — Proceed payment POSTs to `proceedPayment`: validates amount, payable_type, payable_id, gateway
- `ST.STP.4.5.4` — Payment routed through `PaymentService::createPayment()` → returns Razorpay checkout data
- `ST.STP.4.5.5` — Student redirected to `payment::razorpay.process-payment` view with checkout script
- `ST.STP.4.5.6` — **IDOR VULNERABILITY: `payable_id` accepted from request without validating it belongs to authenticated student**

### 4.6 Notifications (Built — Screen 4)

**REF: ST.E5.2.1.1, ST.E5.2.1.2**

- `ST.STP.4.6.1` — List all notifications at `student-portal/all-notifications` (paginated)
- `ST.STP.4.6.2` — Mark individual notification as read: `GET student-portal/notifications/{id}/mark-read`
- `ST.STP.4.6.3` — Mark all notifications as read: `POST student-portal/notifications/mark-all-read`
- `ST.STP.4.6.4` — Test notification route (`test-notification`) — must be removed from production routes
- `ST.STP.4.6.5` — Notification card shows: title, message, type, time elapsed, read/unread indicator

### 4.7 Complaint Submission (Built — Screen 5)

**REF: Module D — Front Office & Communication D3**

- `ST.STP.4.7.1` — Student submits complaint at `student-portal/complaint/create`
- `ST.STP.4.7.2` — Complaint form: target type, complainant type (from sys_dropdowns lookup), category (from ComplaintCategory), subcategory, description, attachment
- `ST.STP.4.7.3` — Subcategory AJAX endpoint: `GET student-portal/complaint/ajax/subcategories/{category}`
- `ST.STP.4.7.4` — Category meta AJAX endpoint: `GET student-portal/complaint/ajax/subcategory-meta/{category}`
- `ST.STP.4.7.5` — Complaint listing shows only student's own complaints (`where('created_by', Auth::id())`)
- `ST.STP.4.7.6` — Student cannot view, edit, or delete other students' complaints (correct — filtered by creator)

### 4.8 Account Settings (Built — Screen 6)

**REF: ST.E1.1.2.1, ST.E5.1.2.1**

- `ST.STP.4.8.1` — Account page at `student-portal/account` renders tabbed interface with:
  - Profile information (personal data from Student + StudentProfile)
  - Security settings (password change — **not yet implemented**)
  - Notification settings (preferences — **not yet implemented**)
  - Privacy settings (**not yet implemented**)
  - Billing & payments summary (fee invoice list — **partial**)
- `ST.STP.4.8.2` — Loads student with full relationship chain: user, profile, addresses, guardian junctions, sessions, studentDetail

### 4.9 Timetable View (MISSING — Screen 7)

**REF: Smart Timetable Module integration**

- `ST.STP.4.9.1` — Display student's daily/weekly timetable from SmartTimetable module — **NOT BUILT**
- `ST.STP.4.9.2` — Show current day's schedule highlighted — **NOT BUILT**

### 4.10 Homework View (MISSING — Screen 8)

**REF: LmsHomework Module integration**

- `ST.STP.4.10.1` — List pending homework assignments for student's class/section — **NOT BUILT**
- `ST.STP.4.10.2` — Allow submission of homework with file attachment — **NOT BUILT**
- `ST.STP.4.10.3` — Show submission history and teacher feedback — **NOT BUILT**

### 4.11 Results / Exam View (MISSING — Screen 9)

**REF: LmsExam, LmsQuiz Modules**

- `ST.STP.4.11.1` — Display exam schedule for the academic session — **NOT BUILT**
- `ST.STP.4.11.2` — Display result cards and marksheets — **NOT BUILT**
- `ST.STP.4.11.3` — Show quiz/assessment scores — **NOT BUILT**

### 4.12 Attendance Report View (MISSING — Screen 10)

**REF: ST.E3.2.1.1, ST.E3.2.1.2**

- `ST.STP.4.12.1` — Monthly attendance summary with calendar view — **NOT BUILT** (partial template exists)
- `ST.STP.4.12.2` — Show cumulative attendance percentage and leave balance — **NOT BUILT**

---

## 5. Data Model

### 5.1 Tables Used (No Portal-Specific Tables)

StudentPortal does not own any database tables. It reads data exclusively from other modules' tables.

| Table (Module)                    | Usage in Portal                               |
|-----------------------------------|-----------------------------------------------|
| `sys_users` (SystemConfig)        | Authentication, profile photo, email          |
| `std_students` (StudentProfile)   | Core student entity                           |
| `std_student_profiles` (STD)      | Extended personal profile                     |
| `std_student_addresses` (STD)     | Permanent/correspondence address              |
| `std_guardians` (STD)             | Guardian details                              |
| `std_student_guardian_jnt` (STD)  | Student-guardian relationship flags           |
| `std_student_academic_sessions` (STD) | Current class, section, roll number       |
| `std_health_profiles` (STD)       | Blood group, allergies display                |
| `fee_student_assignments` (FIN)   | Fee structure for current session             |
| `fee_invoices` (FIN)              | Invoice listing and detail view               |
| `cmp_complaints` (Complaint)      | Student complaint submission and listing      |
| Notification tables (Notification)| User notifications                            |

### 5.2 Key Relationships (Read-Only from Portal)

```
auth()->user() [sys_users]
    └── student [std_students]
         ├── profile [std_student_profiles]
         ├── addresses [std_student_addresses]
         ├── studentGuardianJnts [std_student_guardian_jnt]
         │    └── guardian [std_guardians]
         ├── sessions [std_student_academic_sessions]
         │    └── classSection → class + section
         ├── currentFeeAssignment [fee_student_assignments]
         │    ├── feeStructure.details.head [fee_structure_details → fee_head_master]
         │    └── invoices [fee_invoices]
         └── healthProfile [std_health_profiles]
```

---

## 6. Controller & Route Inventory

### 6.1 Controllers (3 of planned ~10)

| Controller                          | Responsibility                                        | Built Status |
|-------------------------------------|-------------------------------------------------------|:---:|
| `StudentPortalController`           | Login, dashboard, account, academic info, fee payment | Built        |
| `StudentPortalComplaintController`  | Complaint CRUD + AJAX subcategory lookup              | Built        |
| `NotificationController`            | Notification listing, mark read, mark all read        | Built        |
| TimetablePortalController           | Student timetable view                                | MISSING      |
| HomeworkPortalController            | Homework list and submission                          | MISSING      |
| ExamPortalController                | Exam schedule and results                             | MISSING      |
| AttendancePortalController          | Attendance report view                                | MISSING      |
| QuizPortalController                | Quiz/assessment history                               | MISSING      |
| LibraryPortalController             | Library borrowing history                             | MISSING      |
| DocumentPortalController            | TC and certificate download                           | MISSING      |

### 6.2 Route Inventory (Implemented)

All routes under prefix `student-portal/`, middleware `auth + verified`:

| Method | Route                                              | Controller Method     | Auth Guard              |
|--------|----------------------------------------------------|-----------------------|-------------------------|
| GET    | `student-portal/login` (no middleware)             | `login`               | Public                  |
| GET    | `student-portal/dashboard`                         | `dashboard`           | auth + verified         |
| GET    | `student-portal/account`                           | `account`             | auth + verified         |
| GET    | `student-portal/academic-information`              | `academicInformation` | auth + verified         |
| GET    | `student-portal/view-invoice/{invoice}`            | `viewInvoice`         | auth + verified — IDOR  |
| GET    | `student-portal/pay-due-amount/pay-now/{invoice}`  | `payDueAmount`        | auth + verified — IDOR  |
| GET    | `student-portal/pay-due-amount/proceed-payment`    | `proceedPayment`      | auth + verified — IDOR  |
| GET    | `student-portal/complaint`                         | `index`               | auth + verified         |
| GET    | `student-portal/complaint/create`                  | `create`              | auth + verified         |
| POST   | `student-portal/complaint`                         | `store`               | auth + verified         |
| GET    | `student-portal/complaint/ajax/subcategories/{c}`  | `getCategories`       | auth + verified         |
| GET    | `student-portal/all-notifications`                 | `allNotifications`    | auth + verified         |
| POST   | `student-portal/notifications/mark-all-read`       | `markAllRead`         | auth + verified         |
| GET    | `student-portal/notifications/{id}/mark-read`      | `markRead`            | auth + verified         |
| GET    | `student-portal/test-notification`                 | `testNotification`    | auth + verified — REMOVE|

---

## 7. Form Request Validation Rules

**CRITICAL GAP: 0 FormRequest classes exist. All validation is inline.**

### 7.1 ProceedPaymentRequest (to be created)
```
amount:       required|numeric|min:0.01
payable_type: required|string
payable_id:   required|integer|[custom: must belong to authenticated student]
gateway:      required|string|in:razorpay,stripe,paytm,phonepe
```

### 7.2 StoreComplaintRequest (to be created)
```
target_type_id:      required|exists:sys_dropdowns,id
complainant_type_id: required|exists:sys_dropdowns,id
category_id:         required|exists:cmp_complaint_categories,id
subcategory_id:      nullable|exists:cmp_complaint_categories,id
description:         required|string|min:20|max:2000
attachment:          nullable|file|mimes:jpg,jpeg,png,pdf|max:5120
```

---

## 8. Business Rules

### 8.1 Data Isolation (Critical)

- `BR.STP.8.1.1` — A student may only view their own invoices, profile data, attendance, and fee information. Any cross-student access is a security violation.
- `BR.STP.8.1.2` — Invoice/payment ownership must be verified: `FeeInvoice::where('id', $id)->whereHas('studentAssignment', fn($q) => $q->where('student_id', auth()->user()->student->id))->firstOrFail()`
- `BR.STP.8.1.3` — Payment amount submitted by student (`payable_id`) must be validated against the authenticated student's invoice records — server-side; never trust client-submitted `payable_id`
- `BR.STP.8.1.4` — A guardian with `can_access_parent_portal = 1` may view their linked child's data only

### 8.2 Fee Payment Rules

- `BR.STP.8.2.1` — Student can only pay invoices in "Published", "Partially Paid", or "Overdue" status; "Paid" and "Cancelled" invoices must show read-only view
- `BR.STP.8.2.2` — Minimum payment amount = INR 1; maximum = remaining balance (`total_amount - paid_amount`)
- `BR.STP.8.2.3` — Gateway selection must be filtered to active gateways only (`PaymentGateway::active()->get()` — currently using `::all()`)
- `BR.STP.8.2.4` — Failed/cancelled payments must not update invoice status; only Razorpay webhook confirmation triggers status update

### 8.3 Notification Rules

- `BR.STP.8.3.1` — Notifications fetched via `auth()->user()->notifications()` using Laravel's built-in Notifiable trait
- `BR.STP.8.3.2` — Mark-read must validate that the notification belongs to the authenticated user before updating
- `BR.STP.8.3.3` — Notification count badge on dashboard must show unread count from `unreadNotifications()->count()`

### 8.4 Complaint Rules

- `BR.STP.8.4.1` — Student can view, create complaints; cannot edit or delete after submission
- `BR.STP.8.4.2` — Student complaint listing filtered by `created_by = Auth::id()` (currently correct)
- `BR.STP.8.4.3` — Target type and complainant type must resolve via sys_dropdowns lookup before storing

---

## 9. Permission & Authorization Model

### 9.1 Current State

**CRITICAL FINDING: Zero `Gate::authorize()` calls exist in any of the 3 StudentPortal controllers.**

The module relies entirely on the `auth + verified` middleware, which only confirms that a logged-in, email-verified user is making the request. There is no check that:
1. The authenticated user is a STUDENT (`user_type = 'STUDENT'`)
2. The resource being accessed belongs to the authenticated student
3. The student's access is currently enabled (`is_active = 1`, no suspension)

### 9.2 Required Authorization Checks

| Endpoint                             | Required Check                                         |
|--------------------------------------|--------------------------------------------------------|
| All portal routes                    | `user_type = 'STUDENT'` or `user_type = 'GUARDIAN'`   |
| `viewInvoice($id)`                   | Invoice belongs to `auth()->user()->student`           |
| `payDueAmount($id)`                  | Invoice belongs to `auth()->user()->student`           |
| `proceedPayment()`                   | `payable_id` invoice belongs to `auth()->user()->student` |
| `notifications/{id}/mark-read`       | Notification belongs to `auth()->user()`               |

### 9.3 Recommended Implementation

Create a `StudentPortal` middleware that:
- Checks `auth()->user()->user_type === 'STUDENT'`
- Redirects non-students to admin login if they try to access portal routes

Create a `StudentPolicy` (or inline checks) that verifies invoice ownership before any fee-related action.

---

## 10. Tests Inventory

### 10.1 Existing Tests (7 tests)

| Test File                              | Type    | Coverage                                               |
|----------------------------------------|---------|--------------------------------------------------------|
| `StudentPortalControllerTest` (Feature)| Feature | Basic HTTP response checks for dashboard, account routes |
| `ComplaintControllerTest` (Feature)    | Feature | Basic HTTP response for complaint create/store         |
| `NotificationControllerTest` (Feature) | Feature | Basic HTTP response for notification listing           |
| `StudentPortalControllerTest` (Unit)   | Unit    | Controller instantiation checks                        |
| `ComplaintControllerTest` (Unit)       | Unit    | Complaint controller unit tests                        |
| `NotificationControllerTest` (Unit)    | Unit    | Notification controller unit tests                     |
| `Pest.php`                             | Config  | Pest test configuration                                |

### 10.2 Critical Tests Missing

- IDOR security test: confirm student A cannot access student B's invoice
- Authorization test: confirm non-STUDENT user cannot access portal routes
- Fee payment flow test: Razorpay order creation and webhook processing
- Complaint isolation test: student sees only own complaints
- Notification ownership test: mark-read validates notification ownership

---

## 11. Known Issues & Technical Debt

### 11.1 P0 — Critical Security Issues

| Issue                               | Severity | Detail                                                                                                                                                                                         |
|-------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **IDOR on invoice view**            | P0       | `viewInvoice($id)` does `FeeInvoice::findOrFail($id)`. Student A can access Student B's invoice by changing the `{invoice}` parameter. Fix: `FeeInvoice::whereHas('studentAssignment', fn($q) => $q->where('student_id', auth()->user()->student->id))->findOrFail($id)` |
| **IDOR on payment initiation**      | P0       | `payDueAmount($id)` and `proceedPayment()` accept `payable_id` from user input without ownership verification. A student can initiate a payment against another student's invoice. Fix: validate `payable_id` against authenticated student's assignments. |
| **No student-type guard on routes** | P0       | Any authenticated user (teacher, admin, staff) can access `student-portal/*` routes. A teacher could pay fee on behalf of a student from their own session. Fix: add `StudentPortalMiddleware` checking `user_type = STUDENT`. |
| **test-notification route in production** | P1  | `GET student-portal/test-notification` should be conditional on `App::environment('local')` or removed entirely.                                                                               |

### 11.2 P1 — High-Priority Issues

| Issue                               | Severity | Detail                                                                               |
|-------------------------------------|----------|--------------------------------------------------------------------------------------|
| **0 FormRequest classes**           | P1       | Inline validation in all controllers                                                 |
| **0 Gate::authorize() calls**       | P1       | No RBAC enforcement; auth middleware is the only protection                          |
| **PaymentGateway::all() instead of ::active()** | P1 | Payment page shows all configured gateways including disabled ones           |
| **3 of 27 screens built (11%)**     | P1       | Module is critically incomplete for production; timetable, homework, results, attendance all missing |

### 11.3 P2 — Medium Priority

| Issue                               | Detail                                                                         |
|-------------------------------------|--------------------------------------------------------------------------------|
| No parent portal separation         | Parents and students share the same portal; no separate guardian dashboard     |
| Attendance data not bound to view   | `_attendance-records.blade.php` partial exists but data not loaded in controller |
| Academic performance not integrated | `_academic-performance.blade.php` partial exists but exam data not integrated  |
| Password change not implemented     | Security settings tab in account page is a static placeholder                  |
| Module-level `web.php` routes unused | `Modules/StudentPortal/routes/web.php` has only `resource` route; actual routes are in main `tenant.php` |

---

## 12. API Endpoints

Currently, no API endpoints exist. The StudentPortal module has an `api.php` routes file at module level but it is empty.

**Planned (missing — required for mobile app / parent app):**

| Method | Endpoint                               | Description                        |
|--------|----------------------------------------|------------------------------------|
| GET    | `/api/v1/portal/profile`               | Student profile data               |
| GET    | `/api/v1/portal/invoices`              | Student invoice list               |
| POST   | `/api/v1/portal/pay`                   | Initiate payment                   |
| GET    | `/api/v1/portal/timetable`             | Current week timetable             |
| GET    | `/api/v1/portal/attendance`            | Attendance summary                 |
| GET    | `/api/v1/portal/notifications`         | Notification list                  |
| POST   | `/api/v1/portal/notifications/read`    | Mark notification read             |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- Dashboard must load within 2 seconds; all relationships should be eager-loaded in a single query chain
- Invoice list must paginate (currently not paginated on `academicInformation` — loads all invoices for assignment)
- Notification list: paginated at 10 per page (already implemented)

### 13.2 Security

- IDOR fixes (P0) must be deployed before any public-facing use
- CSRF protection applies to all POST/PUT routes via web middleware
- File uploads in complaint must be virus-scanned or at minimum extension-validated
- Session timeout should be shorter for student portal (30 minutes recommended) vs admin (60 minutes)
- Rate limiting on payment initiation: max 3 attempts per 5 minutes per user

### 13.3 Usability

- Portal must be responsive (Bootstrap 5 — AdminLTE 4 base already applied)
- All error messages must be student-friendly (no technical stack traces)
- Payment status feedback must be immediate (webhook + polling or Razorpay JS callback)

### 13.4 Compliance

- Fee payment pages must not store card details; Razorpay tokenization handles this
- Parent/guardian portal access must respect `can_access_parent_portal` flag in `std_student_guardian_jnt`

---

## 14. Integration Points

| Module                  | Integration Method            | Data Flow                                             |
|-------------------------|-------------------------------|-------------------------------------------------------|
| StudentProfile (STD)    | Eloquent relationships via User model | `auth()->user()->student` chain for all student data |
| StudentFee (FIN)        | Direct model import `FeeInvoice` | Invoice view and payment flow                         |
| Payment module          | `PaymentService::createPayment()` | Razorpay order creation; webhook for callback        |
| Notification module     | `auth()->user()->notifications()` | Laravel Notifiable trait on User model               |
| Complaint module        | `Complaint`, `ComplaintCategory` models | Complaint CRUD                             |
| SmartTimetable          | Planned: `TimetableApiController` REST API | Student timetable view (not built)      |
| LmsHomework             | Planned: Direct model query   | Homework listing by class/section/student (not built) |

---

## 15. Pending Work & Gap Analysis

### 15.1 Screen Completion Status (3 of 27 Built)

| Screen                          | Status        | Notes                                                  |
|---------------------------------|---------------|--------------------------------------------------------|
| 1. Student Login                | Built         | Custom login view exists                               |
| 2. Student Dashboard            | Partial       | Notifications shown; stats widgets missing             |
| 3. Academic Information         | Partial       | Profile, guardian, fee, health shown; attendance and exam data not bound |
| 3a. Invoice View                | Built (IDOR)  | Must fix IDOR before production                        |
| 3b. Fee Payment                 | Built (IDOR)  | Must fix IDOR; active gateway filter missing           |
| 4. Notifications                | Built         | Full CRUD notifications; test route must be removed    |
| 5. Complaint                    | Built         | Index + create + store with AJAX category lookup       |
| 6. Account Settings             | Partial       | Tab structure built; content stubs for security/privacy/notifications |
| 7. Timetable View               | Missing       |                                                        |
| 8. Homework List                | Missing       |                                                        |
| 9. Homework Submission          | Missing       |                                                        |
| 10. Exam Schedule               | Missing       |                                                        |
| 11. Exam Results                | Missing       |                                                        |
| 12. Quiz History                | Missing       |                                                        |
| 13. Attendance Monthly View     | Missing       |                                                        |
| 14. Attendance Yearly Summary   | Missing       |                                                        |
| 15. Library Card View           | Missing       |                                                        |
| 16. Transport Route Info        | Missing       |                                                        |
| 17. Document Download           | Missing       |                                                        |
| 18. Certificate Request         | Missing       |                                                        |
| 19. Parent Dashboard            | Missing       |                                                        |
| 20. Password Change             | Missing       | Security settings tab is placeholder                   |
| 21. Notification Settings       | Missing       | Notification settings tab is placeholder               |
| 22. Privacy Settings            | Missing       | Privacy settings tab is placeholder                    |
| 23. Subject-wise Progress       | Missing       |                                                        |
| 24. Syllabus Coverage View      | Missing       |                                                        |
| 25. Recommendation View         | Missing       |                                                        |
| 26. Behavioral Assessment View  | Missing       |                                                        |
| 27. Mobile App / PWA            | Missing       |                                                        |

### 15.2 Priority Remediation Order

1. **P0 — IDOR fixes** on invoice view, payment initiation, and payment proceed endpoints
2. **P0 — Student-type middleware** to restrict portal routes to STUDENT users only
3. **P1 — Remove test-notification route** from production
4. **P1 — Fix PaymentGateway::all() → ::active()**
5. **P1 — Create FormRequest classes** for complaint and payment endpoints
6. **P1 — Build Attendance view** (data exists in StudentProfile models)
7. **P1 — Build Timetable view** (SmartTimetable API available)
8. **P2 — Build Homework view** (LmsHomework module integration)
9. **P2 — Build Exam/Results view** (LmsExam integration)
10. **P3 — Build remaining 19 screens**
