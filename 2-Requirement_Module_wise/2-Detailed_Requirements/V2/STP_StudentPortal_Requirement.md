# STP — Student Portal
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

> **CRITICAL SECURITY NOTICE — RESIDUAL IDOR:** `proceedPayment()` still accepts `payable_id` from the client without validating it belongs to the authenticated student. `viewInvoice()` and `payDueAmount()` have been partially fixed with `where('student_id', ...)` scoping, but this is insufficient — `FeeInvoice` may not have a direct `student_id` column; the correct guard is via `feeStudentAssignment`. Zero `Gate::authorize()` or `$this->authorize()` calls exist anywhere in the module's 7 controllers. Role middleware (`role:Student|Parent`) is applied at the RouteServiceProvider level — this is the only RBAC boundary currently in place.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders and Roles](#3-stakeholders-and-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API Endpoints and Routes](#6-api-endpoints-and-routes)
7. [UI Screens](#7-ui-screens)
8. [Business Rules](#8-business-rules)
9. [Workflows](#9-workflows)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Dependencies](#11-dependencies)
12. [Test Scenarios](#12-test-scenarios)
13. [Glossary](#13-glossary)
14. [Suggestions](#14-suggestions)
15. [Appendices](#15-appendices)
16. [V1 to V2 Delta](#16-v1-to-v2-delta)

---

## 1. Executive Summary

The Student Portal (STP) module is the **student-facing self-service interface** of Prime-AI. It allows enrolled students (and optionally their parents/guardians) to access academic information, view timetables, track homework and assignments, view exam schedules and results, pay fee invoices online, monitor attendance, access library records, download progress cards, view transport allocations, and raise complaints — all through a dedicated portal separate from the administrative backend.

**Current Completion (as of 2026-03-26):** ~55%

Since V1 (gap analysis date: 2026-03-22), development has progressed substantially. The module now has **7 controllers** (up from 3), **55+ routes** covering 35+ distinct pages, and **57 Blade view files** (up from ~20). The dashboard is fully populated with real data: attendance stats, today's timetable, pending homework, upcoming exams, and fee summary are all live. Timetable, attendance, syllabus progress, LMS (homework/quiz/quest/exam), teachers directory, transport, library, progress card, recommendations, and fee summary screens are now built but carry varying degrees of business-logic completeness.

**Remaining critical gaps:**
- IDOR vulnerability in `proceedPayment()` — `payable_id` not validated server-side
- Zero `Gate::authorize()` or policy-based authorization in any controller
- No `FormRequest` classes (7 controllers use inline validation or none)
- No `Service` classes (business logic lives in controllers)
- No `EnsureTenantHasModule` middleware
- Scaffold stub methods (`index`, `create`, `store`, `show`, `edit`, `update`, `destroy`) still exist in `StudentPortalController`
- Leave application, school calendar, hostel, online exam, quiz/quest player screens are stubs (view-only, no data)
- Hard-coded dropdown ID `104` in `StudentPortalComplaintController`
- `test-notification` route must be removed (not yet confirmed removed)

**Risk Level:** HIGH (security) | **Estimated Remaining Effort:** ~15 person-days

---

## 2. Module Overview

### 2.1 Purpose

StudentPortal provides a **student-facing self-service interface** operating on the tenant's domain. It renders a dedicated UI experience with its own layout (`studentportal::components.layouts.master`) completely separate from the admin backend. Students authenticate via the same `sys_users` table but are restricted to portal routes via the `role:Student|Parent` Spatie middleware.

### 2.2 Module Characteristics

| Attribute            | Value                                                                                                           |
|----------------------|-----------------------------------------------------------------------------------------------------------------|
| Laravel Module       | `nwidart/laravel-modules` v12, name `StudentPortal`                                                             |
| Namespace            | `Modules\StudentPortal`                                                                                         |
| Module Code          | STP                                                                                                             |
| Domain               | Tenant (school-specific subdomain) — student-facing pages                                                       |
| DB Connection        | `tenant` (tenant_{uuid})                                                                                        |
| Table Prefix         | `stp_` (own tables: none — reads from std_, fee_, cmp_, lib_, tpt_)                                             |
| Auth Guard           | Laravel Auth — `role:Student|Parent` Spatie middleware                                                          |
| Controllers          | 7 (`StudentPortalController`, `StudentPortalComplaintController`, `NotificationController`,                     |
|                      | `StudentLmsController`, `StudentProgressController`, `StudentTeachersController`, `StudentTimetableController`) |
| Models               | 0 (uses models from external modules)                                                                           |
| Services             | 0 (all logic in controllers)                                                                                    |
| FormRequests         | 0 (inline validation or none)                                                                                   |
| Middleware           | `role:Student|Parent` at RouteServiceProvider; no `EnsureTenantHasModule`                                       |
| Tests                | 7 files (3 Feature + 3 Unit + 1 Pest config) — basic scaffolding only                                           |
| Blade Views          | 57 files across 30 directories                                                                                  |
| Route Count          | 55+ named routes under prefix `student-portal.`                                                                 |
| Payment Gateway      | Razorpay (via Payment module — `PaymentService::createPayment()`)                                               |
| Completion           | ~55%                                                                                                            |
|----------------------|-----------------------------------------------------------------------------------------------------------------|

### 2.3 Module Position in the Platform

```
Actor               Module                  Role
──────────────────────────────────────────────────────────────────────
Student             StudentPortal (STP)     Self-service portal (primary actor)
Parent / Guardian   StudentPortal (STP)     Child data viewer (role: Parent)
Admin / Teacher     StudentProfile (STD)    Student record management (backend)
Admin / Accountant  StudentFee (FIN)        Fee management backend
System              Payment module          Razorpay gateway integration
System              Notification module     SMS/email/push alerts
System              Complaint module        Complaint routing engine
```

---

## 3. Stakeholders and Roles

| Actor              | Role Code | Access Level                                                                                |
|--------------------|-----------|-------------------------------------------------------------------------------------------|
| Student            | Student   | Primary actor. Full access to own portal data; zero access to other students' data         |
| Parent / Guardian  | Parent    | Portal access when `can_access_parent_portal = 1` in guardian junction; reads child's data |
| School Admin       | Admin     | Manages student login credentials; grants/revokes portal access                            |

### 3.1 Authentication Model

- Student/Parent portal uses the same Laravel Auth (`sys_users` table) as admin users
- Student accounts: `user_type = 'STUDENT'`; parent accounts: `user_type = 'PARENT'` (or Spatie role `Student` / `Parent`)
- Portal route group has `role:Student|Parent` middleware applied at `RouteServiceProvider`
- After login, student lands on `student-portal/dashboard`
- Unauthenticated access to `student-portal/login` is public (no middleware)
- Standard Laravel password reset flow available

### 3.2 Proposed: Dedicated Student Auth Guard

📐 A dedicated `student` guard using `sys_users` with a scope filter (`user_type IN ('STUDENT','PARENT')`) is recommended to fully isolate portal session from admin sessions. Until then, Spatie `role:Student|Parent` is the only role gate.

---

## 4. Functional Requirements

### FR-STP-01: Student Login
**Status:** ✅ Implemented

- `ST.STP.4.1.1` — Student authenticates via email/username and password at `/student-portal/login`
- `ST.STP.4.1.2` — Login renders `studentportal::auth.login` view (separate from admin login)
- `ST.STP.4.1.3` — Failed login shows validation errors; successful login redirects to `student-portal.dashboard`
- `ST.STP.4.1.4` — "Forgot password" uses standard Laravel password reset
- `ST.STP.4.1.5` — 📐 Rate limiting (max 5 attempts / 2 min) to be applied via `throttle:5,2` middleware on login POST

### FR-STP-02: Student Dashboard
**Status:** ✅ Implemented (data fully populated since V1)

- `ST.STP.4.2.1` — After login, student lands on `/student-portal/dashboard`
- `ST.STP.4.2.2` — Dashboard displays attendance stats: total days, present count, attendance percentage (from `std_student_attendance`)
- `ST.STP.4.2.3` — Dashboard displays today's timetable cells from `tt_timetable_cells` filtered by student's class+section and current day-of-week
- `ST.STP.4.2.4` — Dashboard shows pending homework count (published homework not yet submitted by this student) — top 5 items shown
- `ST.STP.4.2.5` — Dashboard shows upcoming exam count and next 5 exams from `ExamAllocation` (CLASS + SECTION + STUDENT allocations)
- `ST.STP.4.2.6` — Dashboard shows fee summary: total fee, paid amount, outstanding balance, count of pending invoices
- `ST.STP.4.2.7` — Dashboard shows latest 10 notifications (paginated)
- `ST.STP.4.2.8` — Quick navigation tiles to major portal sections
- `ST.STP.4.2.9` — 📐 N+1 risk: `student->currentSession()` with multiple nested eager loads should be consolidated into one query chain with `with([...])`

### FR-STP-03: Academic Information
**Status:** 🟡 Partial (profile, guardian, health, fee loaded; attendance/exam partials exist as blade but data now available via dedicated routes)

- `ST.STP.4.3.1` — Full student profile: personal details, guardian info, addresses, academic session (class, section, roll number)
- `ST.STP.4.3.2` — Health profile summary: blood group, allergies, chronic conditions
- `ST.STP.4.3.3` — Fee assignment overview: current fee structure, opted heads, total fee amount
- `ST.STP.4.3.4` — Invoice list: latest invoice displayed prominently; older invoices in descending order
- `ST.STP.4.3.5` — `_attendance-records.blade.php` partial exists — now populated via the dedicated `/my-attendance` route (FR-STP-07)
- `ST.STP.4.3.6` — `_academic-performance.blade.php` partial exists — exam data available via `/results` and `/exam-schedule` routes

### FR-STP-04: Fee Invoice View
**Status:** 🟡 Partial (IDOR partially fixed; residual gap in proceedPayment)

- `ST.STP.4.4.1` — Student views individual invoice at `/student-portal/view-invoice/{invoice}`
- `ST.STP.4.4.2` — `viewInvoice()` now scopes query with `->where('student_id', auth()->user()->student->id)` — partial IDOR fix
- `ST.STP.4.4.3` — Invoice detail shows: invoice number, date, due date, base amount, concession, fine, tax, total, paid amount, balance due, status
- `ST.STP.4.4.4` — 📐 **Recommended fix:** Use `FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $studentId))->findOrFail($id)` to guard against cases where `student_id` column may not exist directly on `fee_invoices`

### FR-STP-05: Fee Payment
**Status:** 🟡 Partial (IDOR remains in proceedPayment)

- `ST.STP.4.5.1` — Payment initiated at `/student-portal/pay-due-amount/pay-now/{invoice}`
- `ST.STP.4.5.2` — `payDueAmount()` scoped with `->where('student_id', ...)` — partial IDOR fix
- `ST.STP.4.5.3` — Payment gateway list: uses `PaymentGateway::all()` — should be `PaymentGateway::active()->get()`
- `ST.STP.4.5.4` — `proceedPayment()` POSTs to `/student-portal/pay-due-amount/proceed-payment`; validates `amount`, `payable_type`, `payable_id`, `gateway` inline — **`payable_id` has no ownership check — IDOR still present**
- `ST.STP.4.5.5` — Routes through `PaymentService::createPayment()` → Razorpay checkout
- `ST.STP.4.5.6` — Redirect to `payment::razorpay.process-payment` with checkout script

### FR-STP-06: Fee Summary Page
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.6.1` — Dedicated fee summary at `/student-portal/fee-summary`
- `ST.STP.4.6.2` — Shows all invoices for current fee assignment, sorted by descending ID
- `ST.STP.4.6.3` — Displays fee structure details, opted heads, total, paid, and balance

### FR-STP-07: Attendance View
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.7.1` — Full attendance history at `/student-portal/my-attendance`
- `ST.STP.4.7.2` — Reads from `std_student_attendance` filtered by `student_id` and current `academic_session_id`
- `ST.STP.4.7.3` — Summary counts: total, present, absent, late, leave, percentage
- `ST.STP.4.7.4` — Grouped by month (e.g., "March 2026") for calendar-style display
- `ST.STP.4.7.5` — 📐 Missing: date filter/range picker; currently loads all records at once — should paginate or limit to current session

### FR-STP-08: Timetable View
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.8.1` — Weekly timetable grid at `/student-portal/my-timetable`
- `ST.STP.4.8.2` — Reads from `tt_timetable_cells` scoped to student's class + section, timetable status `ACTIVE|GENERATED|PUBLISHED`
- `ST.STP.4.8.3` — Grid built as `[day_of_week][period_ord] => TimetableCell`
- `ST.STP.4.8.4` — Displays: subject, teacher name, room, study format, subject type
- `ST.STP.4.8.5` — School days from `tt_school_days` (is_school_day=true, ordered by ordinal)
- `ST.STP.4.8.6` — Handles case where student has no session (renders `noSession` state)

### FR-STP-09: Exam Schedule
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.9.1` — Exam schedule at `/student-portal/exam-schedule`
- `ST.STP.4.9.2` — Shows ExamAllocations targeting student's class, section, or directly
- `ST.STP.4.9.3` — Partitioned into three groups: `upcoming` (future), `today`, `concluded` (past)
- `ST.STP.4.9.4` — Filtered to PUBLISHED status only
- `ST.STP.4.9.5` — Sorted by `scheduled_date` or `examPaper.exam.start_date`

### FR-STP-10: Results View
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.10.1` — Past exam results at `/student-portal/results`
- `ST.STP.4.10.2` — Shows ExamAllocations that are published and in the past
- `ST.STP.4.10.3` — 📐 Missing: actual marks/scores display — `ExamAllocation` alone does not carry result data; this requires integration with `ExamResult` or equivalent model from LmsExam module

### FR-STP-11: My Learning (LMS Hub)
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.11.1` — Unified learning hub at `/student-portal/my-learning`
- `ST.STP.4.11.2` — Displays: Homework (published, not submitted, due-date ordered), Exams, Quizzes (via `QuizAllocation`), Quests (via `QuestAllocation`)
- `ST.STP.4.11.3` — Homework filtered to student's class+section; submissions scoped to current user
- `ST.STP.4.11.4` — Quiz/Quest allocations: class, section, and student-level targeting supported
- `ST.STP.4.11.5` — Comment in code notes `Homework::scopePublished()` has a broken PHP 8.4 type hint — inlined as workaround
- `ST.STP.4.11.6` — 📐 Missing: homework submission action from this screen; quiz/quest player links

### FR-STP-12: Homework List
**Status:** ✅ Implemented (view exists: `homework/index.blade.php`)

- `ST.STP.4.12.1` — Dedicated homework view at `/student-portal/homework` — 📐 route not confirmed in web.php; may be served via my-learning
- `ST.STP.4.12.2` — 📐 Missing: homework submission endpoint and file upload

### FR-STP-13: Syllabus Progress
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.13.1` — Syllabus coverage at `/student-portal/syllabus-progress`
- `ST.STP.4.13.2` — Reads `slb_syllabus_schedules` for student's class+section+session
- `ST.STP.4.13.3` — Topics grouped by subject; per-topic status: `completed`, `in_progress`, `upcoming` (derived from scheduled dates vs today)
- `ST.STP.4.13.4` — Subject-level percentage computed as `(completed / total) × 100`

### FR-STP-14: My Teachers
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.14.1` — Teachers directory at `/student-portal/my-teachers`
- `ST.STP.4.14.2` — Built from active timetable cells for student's class+section
- `ST.STP.4.14.3` — Each teacher entry shows: subjects taught, days active, period schedule
- `ST.STP.4.14.4` — Schedule grid: `teacher_id → day_of_week → [period labels]`

### FR-STP-15: Progress Card (HPC)
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.15.1` — Published HPC reports at `/student-portal/progress-card`
- `ST.STP.4.15.2` — Reads `hpc_reports` where `student_id = student.id` and `status = 'Published'`
- `ST.STP.4.15.3` — Shows report with academic session, template, and term info
- `ST.STP.4.15.4` — 📐 Missing: PDF download button for each report (HPC module generates PDFs via DomPDF)

### FR-STP-16: Performance Analytics
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.16.1` — Analytics view at `/student-portal/performance-analytics`
- `ST.STP.4.16.2` — Monthly attendance stats: total/present/absent per month
- `ST.STP.4.16.3` — Exam summary stats: total, upcoming, concluded counts
- `ST.STP.4.16.4` — Overall attendance percentage
- `ST.STP.4.16.5` — 📐 Missing: subject-wise performance charts; quiz/assignment scores aggregation

### FR-STP-17: Recommendations
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.17.1` — Personalized recommendations at `/student-portal/my-recommendations`
- `ST.STP.4.17.2` — Reads `StudentRecommendation` where `student_id = student.id` and `is_active = 1`
- `ST.STP.4.17.3` — Paginated (15 per page), ordered by `assigned_at` descending

### FR-STP-18: Library
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.18.1` — Library catalog at `/student-portal/library` (non-reference books, paginated 24 per page)
- `ST.STP.4.18.2` — My borrowed books at `/student-portal/library/my-books` — via `LibMember` lookup then `LibTransaction`
- `ST.STP.4.18.3` — Shows: book title, copy, issue date, return date, status
- `ST.STP.4.18.4` — 📐 Missing: book reservation/request functionality

### FR-STP-19: Transport Information
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.19.1` — Transport details at `/student-portal/transport`
- `ST.STP.4.19.2` — Reads `TptStudentAllocationJnt` for current student (active_status = true)
- `ST.STP.4.19.3` — Shows pickup route, drop route, pickup stop, drop stop
- `ST.STP.4.19.4` — Renders null-safe state when no allocation found

### FR-STP-20: Health Records
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.20.1` — Health records at `/student-portal/health-records`
- `ST.STP.4.20.2` — Reads `student.healthProfile` relationship
- `ST.STP.4.20.3` — Shows blood group, allergies, chronic conditions, emergency contact

### FR-STP-21: Student ID Card
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.21.1` — Digital ID card at `/student-portal/student-id-card`
- `ST.STP.4.21.2` — Loads full student profile with guardian, health, session, and class/section info
- `ST.STP.4.21.3` — 📐 Missing: downloadable PDF version of ID card

### FR-STP-22: Study Resources and Prescribed Books
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.22.1` — Study resources at `/student-portal/study-resources` — book catalog for student's class via `BookClassSubject`
- `ST.STP.4.22.2` — Prescribed books at `/student-portal/prescribed-books` — subject-grouped book list

### FR-STP-23: Notice Board
**Status:** ✅ Implemented (new since V1)

- `ST.STP.4.23.1` — Notice board at `/student-portal/notice-board` — renders notifications (paginated 20 per page)
- `ST.STP.4.23.2` — 📐 Notice board should pull from a dedicated announcement/notice model (e.g., `sch_notices`), not from the notification inbox

### FR-STP-24: School Calendar
**Status:** ❌ Stub view only

- `ST.STP.4.24.1` — Route `/student-portal/school-calendar` renders `studentportal::calendar.index` — no data loaded
- `ST.STP.4.24.2` — 📐 Should display academic calendar events from school setup module

### FR-STP-25: Leave Application
**Status:** ❌ Stub view only

- `ST.STP.4.25.1` — Route `/student-portal/apply-leave` renders `studentportal::leave.index` — no data or form handling
- `ST.STP.4.25.2` — 📐 Requires leave application form, submission endpoint, and leave approval workflow

### FR-STP-26: Hostel
**Status:** ❌ Stub view only

- `ST.STP.4.26.1` — Route `/student-portal/hostel` renders `studentportal::hostel.index` — no data loaded
- `ST.STP.4.26.2` — 📐 Should display hostel room allocation, mess schedule (when Hostel module is complete)

### FR-STP-27: Notifications
**Status:** ✅ Implemented

- `ST.STP.4.27.1` — All notifications at `/student-portal/all-notifications` (paginated)
- `ST.STP.4.27.2` — Mark individual read: `GET student-portal/notifications/{id}/mark-read`
- `ST.STP.4.27.3` — Mark all read: `POST student-portal/notifications/mark-all-read`
- `ST.STP.4.27.4` — 📐 `mark-read` should be POST/PATCH (not GET) to comply with REST semantics and avoid CSRF bypass via pre-fetching

### FR-STP-28: Complaints
**Status:** ✅ Implemented

- `ST.STP.4.28.1` — Complaint listing (own complaints only, `created_by = Auth::id()`) at `student-portal/complaint`
- `ST.STP.4.28.2` — Submit complaint at `student-portal/complaint/create` + POST `student-portal/complaint`
- `ST.STP.4.28.3` — AJAX subcategory lookup: `GET student-portal/complaint/ajax/subcategories/{category}`
- `ST.STP.4.28.4` — AJAX category meta: `GET student-portal/complaint/ajax/subcategory-meta/{category}`
- `ST.STP.4.28.5` — Hard-coded dropdown lookup ID `104` at lines 73 and 125 in `StudentPortalComplaintController.php` — must be replaced with config key or `sys_dropdowns` `key`-based lookup
- `ST.STP.4.28.6` — Complaint listing not paginated — `Complaint::where('created_by', ...)->get()` — must be paginated
- `ST.STP.4.28.7` — `$request->merge()` used to inject DB values into request — should move to FormRequest or Service

### FR-STP-29: Account Settings
**Status:** 🟡 Partial (tab structure built; backend stubs only)

- `ST.STP.4.29.1` — Account page at `/student-portal/account` with tabbed interface
- `ST.STP.4.29.2` — Profile information tab: loads full student profile chain
- `ST.STP.4.29.3` — Security settings tab: view exists (`_security-settings.blade.php`) but password change not implemented
- `ST.STP.4.29.4` — Notification settings tab: view exists but no backend handling
- `ST.STP.4.29.5` — Privacy settings tab: view exists but no backend handling
- `ST.STP.4.29.6` — Billing and payments tab: partial — fee invoice summary shown

### FR-STP-30: Online Exam / Quiz / Quest Players
**Status:** ❌ Views exist as stubs; no routes wired

- `ST.STP.4.30.1` — `online-exam/index.blade.php`, `quiz/index.blade.php`, `quest/index.blade.php` exist
- `ST.STP.4.30.2` — No routes or controller methods handle these screens
- `ST.STP.4.30.3` — 📐 Should integrate with LmsQuiz and LmsQuests modules for in-portal assessment delivery

---

## 5. Data Model

### 5.1 STP-Owned Tables

**StudentPortal has zero owned database tables.** The module is a read-focused portal that reads exclusively from other modules' tables. No `stp_` prefix tables exist in `tenant_db_v2.sql`.

### 5.2 Tables Consumed (Read or Write via External Models)

| Table                              | Module        | Access Pattern                                         |
|------------------------------------|---------------|--------------------------------------------------------|
| `sys_users`                        | SystemConfig  | Auth user; photo, email                                |
| `std_students`                     | StudentProfile| Core student entity                                    |
| `std_student_profiles`             | StudentProfile| Extended personal profile                              |
| `std_student_addresses`            | StudentProfile| Permanent/correspondence address                       |
| `std_guardians`                    | StudentProfile| Guardian details                                       |
| `std_student_guardian_jnt`         | StudentProfile| Student-guardian relationship flags                    |
| `std_student_academic_sessions`    | StudentProfile| Current class, section, roll number                    |
| `std_health_profiles`              | StudentProfile| Blood group, allergies                                 |
| `std_student_attendance`           | StudentProfile| Attendance records                                     |
| `fee_student_assignments`          | StudentFee    | Fee structure for current session                      |
| `fee_invoices`                     | StudentFee    | Invoice view and payment                               |
| `cmp_complaints`                   | Complaint     | Complaint submission/listing                           |
| `cmp_complaint_categories`         | Complaint     | Category/subcategory lookup                            |
| `sys_dropdowns`                    | SystemConfig  | Dropdown values for complaint form (hardcoded ID 104)  |
| `sys_notifications`                | Notification  | Laravel Notifiable notifications                       |
| `tt_timetable_cells`               | TimetableFoundation | Weekly timetable grid                            |
| `tt_school_days`                   | TimetableFoundation | School day names/ordinals                        |
| `exm_exam_allocations`             | LmsExam       | Exam schedule and results                              |
| `hmw_homeworks`                    | LmsHomework   | Homework assignments                                   |
| `hmw_homework_submissions`         | LmsHomework   | Submission tracking                                    |
| `quz_quiz_allocations`             | LmsQuiz       | Quiz allocations to class/section/student              |
| `qst_quest_allocations`            | LmsQuests     | Quest allocations                                      |
| `slb_syllabus_schedules`           | Syllabus      | Topic-level syllabus schedule                          |
| `hpc_reports`                      | HPC           | Published progress cards                               |
| `rec_student_recommendations`      | Recommendation| Personalized learning recommendations                  |
| `lib_book_masters`                 | Library       | Library book catalog                                   |
| `lib_members`                      | Library       | Library membership                                     |
| `lib_transactions`                 | Library       | Book borrowing history                                 |
| `tpt_student_allocation_jnt`       | Transport     | Student transport route allocation                     |
| `bok_books`                        | SyllabusBooks | Prescribed book catalog                                |
| `bok_book_class_subjects`          | SyllabusBooks | Book-class-subject mapping                             |
| `pay_payment_gateways`             | Payment       | Gateway config (should filter to active only)          |

### 5.3 Key Relationship Chain

```
auth()->user() [sys_users]
    └── student [std_students]
         ├── profile [std_student_profiles]
         ├── addresses [std_student_addresses]
         ├── studentGuardianJnts [std_student_guardian_jnt]
         │    └── guardian [std_guardians]
         ├── sessions [std_student_academic_sessions]
         │    └── classSection → class + section
         ├── currentSession() — returns latest active session
         ├── currentFeeAssignemnt [fee_student_assignments]  ← note: typo in model name
         │    ├── feeStructure.details.head
         │    └── invoices [fee_invoices]
         └── healthProfile [std_health_profiles]
```

**Known typo:** The relationship on `Student` model is named `currentFeeAssignemnt` (missing letter) — referenced in 3 controller methods. Must be corrected to `currentFeeAssignment`.

---

## 6. API Endpoints and Routes

### 6.1 Web Routes (Implemented — 55+ routes)

All routes share prefix `student-portal/`, name prefix `student-portal.`, and middleware:
`web → InitializeTenancyByDomain → PreventAccessFromCentralDomains → EnsureTenantIsActive → auth → verified → role:Student|Parent`

| Method | URI                                                  | Name                                  | Controller::Method                  | Status      |
|--------|------------------------------------------------------|---------------------------------------|-------------------------------------|-------------|
| GET    | `student-portal/dashboard`                           | `student-portal.dashboard`            | StudentPortalController@dashboard   | ✅           |
| GET    | `student-portal/account`                             | `student-portal.account`              | StudentPortalController@account     | 🟡 Partial  |
| GET    | `student-portal/academic-information`                | `student-portal.academic-information` | StudentPortalController@academicInformation | ✅  |
| GET    | `student-portal/view-invoice/{invoice}`              | `student-portal.view-invoice`         | StudentPortalController@viewInvoice | 🟡 IDOR partial fix |
| GET    | `student-portal/pay-due-amount/pay-now/{invoice}`    | `student-portal.pay-due-amount`       | StudentPortalController@payDueAmount| 🟡 IDOR partial fix |
| POST   | `student-portal/pay-due-amount/proceed-payment`      | `student-portal.proceed-payment`      | StudentPortalController@proceedPayment | 🟡 IDOR remaining |
| GET    | `student-portal/my-timetable`                        | `student-portal.my-timetable`         | StudentTimetableController@index    | ✅           |
| GET    | `student-portal/my-attendance`                       | `student-portal.my-attendance`        | StudentProgressController@attendance | ✅          |
| GET    | `student-portal/syllabus-progress`                   | `student-portal.syllabus-progress`    | StudentProgressController@syllabusProgress | ✅   |
| GET    | `student-portal/results`                             | `student-portal.results`              | StudentPortalController@results     | ✅           |
| GET    | `student-portal/my-teachers`                         | `student-portal.my-teachers`          | StudentTeachersController@index     | ✅           |
| GET    | `student-portal/health-records`                      | `student-portal.health-records`       | StudentPortalController@healthRecords | ✅         |
| GET    | `student-portal/progress-card`                       | `student-portal.progress-card`        | StudentPortalController@progressCard | ✅          |
| GET    | `student-portal/performance-analytics`               | `student-portal.performance-analytics`| StudentPortalController@performanceAnalytics | ✅  |
| GET    | `student-portal/my-recommendations`                  | `student-portal.my-recommendations`   | StudentPortalController@myRecommendations | ✅    |
| GET    | `student-portal/my-learning`                         | `student-portal.my-learning`          | StudentLmsController@index          | ✅           |
| GET    | `student-portal/exam-schedule`                       | `student-portal.exam-schedule`        | StudentPortalController@examSchedule | ✅          |
| GET    | `student-portal/fee-summary`                         | `student-portal.fee-summary`          | StudentPortalController@feeSummary  | ✅           |
| GET    | `student-portal/notice-board`                        | `student-portal.notice-board`         | StudentPortalController@noticeBoard | 🟡 Uses notifications, not notices |
| GET    | `student-portal/study-resources`                     | `student-portal.study-resources`      | StudentPortalController@studyResources | ✅        |
| GET    | `student-portal/prescribed-books`                    | `student-portal.prescribed-books`     | StudentPortalController@prescribedBooks | ✅       |
| GET    | `student-portal/library`                             | `student-portal.library`              | StudentPortalController@library     | ✅           |
| GET    | `student-portal/library/my-books`                    | `student-portal.library.my-books`     | StudentPortalController@libraryMyBooks | ✅        |
| GET    | `student-portal/school-calendar`                     | `student-portal.school-calendar`      | StudentPortalController@schoolCalendar | ❌ Stub    |
| GET    | `student-portal/student-id-card`                     | `student-portal.student-id-card`      | StudentPortalController@idCard      | ✅           |
| GET    | `student-portal/apply-leave`                         | `student-portal.apply-leave`          | StudentPortalController@applyLeave  | ❌ Stub      |
| GET    | `student-portal/transport`                           | `student-portal.transport`            | StudentPortalController@transport   | ✅           |
| GET    | `student-portal/hostel`                              | `student-portal.hostel`               | StudentPortalController@hostel      | ❌ Stub      |
| GET/POST/PUT/... | `student-portal/complaint` (resource)      | `student-portal.complaint.*`          | StudentPortalComplaintController    | ✅           |
| GET    | `student-portal/complaint/ajax/subcategories/{c}`    | `student-portal.complaint.subCategories` | ComplaintController@getCategories | ✅          |
| GET    | `student-portal/complaint/ajax/subcategory-meta/{c}` | `student-portal.complaint.categoryMeta` | ComplaintController@getCategoryMeta | ✅         |
| GET    | `student-portal/all-notifications`                   | `student-portal.all-notifications`    | NotificationController@allNotifications | ✅        |
| POST   | `student-portal/notifications/mark-all-read`         | `student-portal.notifications.mark-all-read` | NotificationController@markAllRead | ✅   |
| GET    | `student-portal/notifications/{id}/mark-read`        | `student-portal.notifications.mark-read` | NotificationController@markRead  | 🟡 Should be POST/PATCH |

### 6.2 API Routes (Planned — Not Yet Implemented)

No API endpoints exist. Module `api.php` routes file is empty.

| Method | Endpoint                               | Description                        | Status |
|--------|----------------------------------------|------------------------------------|--------|
| GET    | `/api/v1/portal/profile`               | Student profile data               | 📐     |
| GET    | `/api/v1/portal/invoices`              | Student invoice list               | 📐     |
| POST   | `/api/v1/portal/pay`                   | Initiate payment                   | 📐     |
| GET    | `/api/v1/portal/timetable`             | Current week timetable             | 📐     |
| GET    | `/api/v1/portal/attendance`            | Attendance summary                 | 📐     |
| GET    | `/api/v1/portal/notifications`         | Notification list                  | 📐     |
| POST   | `/api/v1/portal/notifications/read`    | Mark notification(s) read          | 📐     |
| GET    | `/api/v1/portal/homework`              | Pending homework list              | 📐     |
| GET    | `/api/v1/portal/exams`                 | Exam schedule                      | 📐     |

---

## 7. UI Screens

### 7.1 Screen Inventory (35 screens — actual view files mapped)

V1 described 27 designed screens; actual view directory reveals 35+ distinct pages.

| # | Screen Name                 | Route                                    | Blade View                                  | Status       |
|---|-----------------------------|------------------------------------------|---------------------------------------------|--------------|
| 1 | Student Login               | `student-portal/login` (public)          | `auth/login`                                | ✅           |
| 2 | Dashboard                   | `student-portal/dashboard`               | `dashboard/index`                           | ✅           |
| 3 | Academic Information        | `student-portal/academic-information`    | `academic-information/details`              | 🟡 Partial  |
| 4 | Invoice View                | `student-portal/view-invoice/{id}`       | `academic-information/invoice`              | 🟡 IDOR     |
| 5 | Fee Payment Page            | `student-portal/pay-due-amount/pay-now/{id}` | `academic-information/payment-page`     | 🟡 IDOR     |
| 6 | Fee Summary                 | `student-portal/fee-summary`             | `fee/summary`                               | ✅           |
| 7 | My Timetable                | `student-portal/my-timetable`            | `timetable/index`                           | ✅           |
| 8 | My Attendance               | `student-portal/my-attendance`           | `attendance/index`                          | ✅           |
| 9 | Syllabus Progress           | `student-portal/syllabus-progress`       | `syllabus/progress`                         | ✅           |
| 10 | Exam Schedule              | `student-portal/exam-schedule`           | `exams/schedule`                            | ✅           |
| 11 | Results                    | `student-portal/results`                 | `results/index`                             | 🟡 No marks |
| 12 | My Learning Hub            | `student-portal/my-learning`             | `learning/index`                            | ✅           |
| 13 | Homework List              | (via learning hub or `/homework`)        | `homework/index`                            | 🟡 No submission |
| 14 | Quiz List                  | (via learning hub or `/quiz`)            | `quiz/index`                                | ❌ Stub      |
| 15 | Quest List                 | (via learning hub or `/quest`)           | `quest/index`                               | ❌ Stub      |
| 16 | Online Exam Player         | (no route wired)                         | `online-exam/index`                         | ❌ Stub      |
| 17 | My Teachers                | `student-portal/my-teachers`             | `teachers/index`                            | ✅           |
| 18 | Health Records             | `student-portal/health-records`          | `health/index`                              | ✅           |
| 19 | Progress Card              | `student-portal/progress-card`           | `reports/progress-card`                     | ✅ No PDF    |
| 20 | Performance Analytics      | `student-portal/performance-analytics`   | `reports/analytics`                         | ✅           |
| 21 | My Recommendations         | `student-portal/my-recommendations`      | `reports/recommendations`                   | ✅           |
| 22 | Library Catalog            | `student-portal/library`                 | `library/index`                             | ✅           |
| 23 | My Borrowed Books          | `student-portal/library/my-books`        | `library/my-books`                          | ✅           |
| 24 | Transport Info             | `student-portal/transport`               | `transport/index`                           | ✅           |
| 25 | Study Resources            | `student-portal/study-resources`         | `resources/index`                           | ✅           |
| 26 | Prescribed Books           | `student-portal/prescribed-books`        | `resources/prescribed-books`                | ✅           |
| 27 | Notice Board               | `student-portal/notice-board`            | `notice-board/index`                        | 🟡 Wrong source |
| 28 | School Calendar            | `student-portal/school-calendar`         | `calendar/index`                            | ❌ Stub      |
| 29 | Student ID Card            | `student-portal/student-id-card`         | `id-card/index`                             | ✅ No PDF    |
| 30 | Apply Leave                | `student-portal/apply-leave`             | `leave/index`                               | ❌ Stub      |
| 31 | Hostel Info                | `student-portal/hostel`                  | `hostel/index`                              | ❌ Stub      |
| 32 | Notifications              | `student-portal/all-notifications`       | `notification/index`                        | ✅           |
| 33 | Complaints                 | `student-portal/complaint`               | `complaint/index` + `complaint/create`      | ✅           |
| 34 | Account Settings           | `student-portal/account`                 | `account/index` (6 partial tabs)            | 🟡 Partial  |
| 35 | Coming Soon                | (fallback)                               | `coming-soon`                               | ✅ (placeholder) |

**Summary:** 22 ✅ | 8 🟡 | 5 ❌

---

## 8. Business Rules

### 8.1 Data Isolation (Critical — Security)

- `BR.STP.8.1.1` — A student may only view their own invoices, profile data, attendance, and fee information. Any cross-student access is a critical security violation (IDOR).
- `BR.STP.8.1.2` — Invoice ownership must be verified via the fee assignment chain: `FeeInvoice::whereHas('feeStudentAssignment', fn($q) => $q->where('student_id', $student->id))->findOrFail($id)` — direct `where('student_id', ...)` on `fee_invoices` may fail if `fee_invoices` does not have a direct `student_id` column.
- `BR.STP.8.1.3` — `proceedPayment()` must verify `payable_id` belongs to the authenticated student before creating a Razorpay order. Server-side only — never trust the client-submitted `payable_id`.
- `BR.STP.8.1.4` — A guardian with `can_access_parent_portal = 1` in `std_student_guardian_jnt` may view their linked child's data only; must not view unrelated students' data.
- `BR.STP.8.1.5` — Notification `mark-read` must verify the notification belongs to `auth()->user()` before updating.
- `BR.STP.8.1.6` — Complaint listing must always scope to `created_by = Auth::id()` (currently correct).

### 8.2 Fee Payment Rules

- `BR.STP.8.2.1` — Student can only pay invoices in "Published", "Partially Paid", or "Overdue" status; "Paid" and "Cancelled" invoices must render read-only
- `BR.STP.8.2.2` — Minimum payment = INR 1; maximum = remaining balance (`total_amount - paid_amount`)
- `BR.STP.8.2.3` — Gateway selection must use `PaymentGateway::active()->get()` — not `::all()`
- `BR.STP.8.2.4` — Failed/cancelled Razorpay payments must not update invoice status; only webhook callback triggers status change
- `BR.STP.8.2.5` — Rate limiting on payment initiation: max 3 attempts per 5 minutes per user

### 8.3 Timetable Rules

- `BR.STP.8.3.1` — Only timetables with status `ACTIVE`, `GENERATED`, or `PUBLISHED` are shown to students
- `BR.STP.8.3.2` — Timetable is read-only from the portal; no edit capability
- `BR.STP.8.3.3` — Break/non-teaching cells are filtered out (`filter(fn($c) => !$c->is_break)`)

### 8.4 Attendance Rules

- `BR.STP.8.4.1` — Attendance is read-only; student cannot self-mark attendance
- `BR.STP.8.4.2` — Attendance status values recognized: `Present/P/present`, `Absent/A/absent`, `Late/L/late`, `Leave/leave/On Leave` — inconsistent casing should be normalized at the `StudentAttendance` model level

### 8.5 Complaint Rules

- `BR.STP.8.5.1` — Student can create complaints and view own complaints; cannot edit or delete after submission
- `BR.STP.8.5.2` — `complainant_user_id` must be forced to `Auth::id()` — must not accept arbitrary user IDs from client
- `BR.STP.8.5.3` — Hard-coded dropdown ID `104` must be replaced with a queryable constant (e.g., `sys_dropdowns` where `key = 'COMPLAINANT_STUDENT'`)

### 8.6 LMS Access Rules

- `BR.STP.8.6.1` — Homework shown to student must be PUBLISHED and assigned to their class+section
- `BR.STP.8.6.2` — Quiz/quest allocations must respect `cut_off_date` — expired assignments must not appear
- `BR.STP.8.6.3` — Exam allocations shown must be PUBLISHED and match CLASS, SECTION, or STUDENT-level targeting

---

## 9. Workflows

### 9.1 Fee Payment Workflow

```
Student → /pay-due-amount/pay-now/{id}
  → [SERVER] FeeInvoice::where('student_id', student->id)->findOrFail($id)  ← verify ownership
  → Render payment-page with active gateways
  → Student selects gateway + amount
  → POST /pay-due-amount/proceed-payment
      → [SERVER] Validate: amount, payable_type, payable_id, gateway
      → [SERVER] *** VERIFY payable_id belongs to student *** ← MISSING
      → PaymentService::createPayment([...])
      → Return Razorpay checkout data
  → Redirect to payment::razorpay.process-payment
  → Razorpay JS handles card/UPI capture
  → Razorpay webhook → update invoice status → notify student
```

### 9.2 Complaint Submission Workflow

```
Student → /complaint/create
  → Load: target types, complainant types (sys_dropdowns)
  → Load: ComplaintCategories (active)
  → Student fills form; selects category → AJAX loads subcategories
  → POST /complaint
      → [SERVER] Inline $request->validate([...])
      → [SERVER] $request->merge() injects DB-resolved values ← anti-pattern
      → Complaint::create([...]) with created_by = Auth::id()
      → Redirect with success flash
```

### 9.3 Dashboard Data Aggregation Workflow

```
Student → /dashboard
  → Load auth()->user()->student
  → Load currentSession() with classSection
  → Parallel data loads:
      ├── Attendance: StudentAttendance count (total + present)
      ├── Timetable: TimetableCell for today's day_of_week
      ├── Homework: published, not submitted, due-date sorted (limit 5)
      ├── Exams: ExamAllocation PUBLISHED, future, sorted (limit 5 shown, total count)
      └── Fee: fee assignment invoices sum (total, paid, due, pending count)
  → Load notifications (paginate 10)
  → Render dashboard/index view
```

---

## 10. Non-Functional Requirements

### 10.1 Performance

- `NFR.STP.10.1.1` — Dashboard must load within 2 seconds; eager-load all relationships in one chain to prevent N+1
- `NFR.STP.10.1.2` — Dashboard currently executes multiple separate queries for timetable, homework, exams, fee — should be consolidated with `with([])` eager loading
- `NFR.STP.10.1.3` — Complaint index must paginate (currently `->get()` without limit)
- `NFR.STP.10.1.4` — Library catalog: paginated at 24 per page (implemented)
- `NFR.STP.10.1.5` — Notification list: paginated at 10 per page on dashboard, 20 on notice board (implemented)
- `NFR.STP.10.1.6` — Attendance view: large datasets should paginate or be limited to current academic session (already scoped to session)

### 10.2 Security

- `NFR.STP.10.2.1` — **P0: Fix `proceedPayment()` IDOR** — `payable_id` must be server-side verified
- `NFR.STP.10.2.2` — `EnsureTenantHasModule` middleware must be applied to the portal route group
- `NFR.STP.10.2.3` — CSRF protection applies to all POST routes via web middleware (currently correct)
- `NFR.STP.10.2.4` — File uploads in complaint must validate: `mimes:jpg,jpeg,png,pdf`, `max:5120` (5 MB)
- `NFR.STP.10.2.5` — Session timeout for student portal: 30 minutes recommended (vs admin: 60 minutes)
- `NFR.STP.10.2.6` — Rate limiting on payment initiation: `throttle:3,5` (3 per 5 minutes)
- `NFR.STP.10.2.7` — `notifications/{id}/mark-read` should be POST/PATCH to prevent pre-fetch attacks
- `NFR.STP.10.2.8` — Complaint `description` field should sanitize HTML (strip tags or use `htmlspecialchars`)
- `NFR.STP.10.2.9` — No stack traces visible to students; all exceptions must render student-friendly error pages
- `NFR.STP.10.2.10` — Fee pages must not store card details; Razorpay tokenization handles PCI compliance

### 10.3 Usability

- `NFR.STP.10.3.1` — Portal must be fully responsive (Bootstrap 5 / AdminLTE 4 base)
- `NFR.STP.10.3.2` — All error messages must be student-friendly
- `NFR.STP.10.3.3` — Payment status feedback must be immediate (webhook + callback)
- `NFR.STP.10.3.4` — Timetable grid should highlight the current day column
- `NFR.STP.10.3.5` — Dashboard attendance/fee summary cards must show clear visual indicators (color-coded badges)

### 10.4 Compliance

- `NFR.STP.10.4.1` — Fee payment pages must comply with Razorpay's PCI DSS requirements
- `NFR.STP.10.4.2` — Guardian portal access must respect `can_access_parent_portal` flag in `std_student_guardian_jnt`
- `NFR.STP.10.4.3` — Student data access must respect Indian DPDP Act 2023 requirements (data minimization, no unauthorized cross-student access)

---

## 11. Dependencies

### 11.1 Module Dependencies

| Module                  | Direction | Purpose                                                   | Status     |
|-------------------------|-----------|-----------------------------------------------------------|------------|
| StudentProfile (STD)    | Incoming  | `Student`, `StudentProfile`, `StudentAttendance`, `Guardian`, `AcademicSession`, `HealthProfile` models | Required  |
| StudentFee (FIN)        | Incoming  | `FeeInvoice`, `FeeStudentAssignment` for fee view/payment | Required   |
| Payment                 | Outgoing  | `PaymentService::createPayment()` for Razorpay checkout   | Required   |
| Notification            | Incoming  | `auth()->user()->notifications()` via Notifiable          | Required   |
| Complaint (CMP)         | Outgoing  | `Complaint`, `ComplaintCategory` models                   | Required   |
| TimetableFoundation     | Incoming  | `TimetableCell`, `SchoolDay` for timetable grid           | Required   |
| LmsExam                 | Incoming  | `ExamAllocation` for exam schedule and results            | Required   |
| LmsHomework             | Incoming  | `Homework`, `HomeworkSubmission`                          | Required   |
| LmsQuiz                 | Incoming  | `QuizAllocation` for quiz listing                         | Required   |
| LmsQuests               | Incoming  | `QuestAllocation` for quest listing                       | Required   |
| Syllabus (SLB)          | Incoming  | `SyllabusSchedule` for syllabus progress                  | Required   |
| HPC                     | Incoming  | `HpcReport` for progress cards                            | Required   |
| Recommendation (REC)    | Incoming  | `StudentRecommendation` for personalized content          | Required   |
| Library (LIB)           | Incoming  | `LibBookMaster`, `LibMember`, `LibTransaction`            | Required   |
| Transport (TPT)         | Incoming  | `TptStudentAllocationJnt` for transport info              | Required   |
| SyllabusBooks (BOK)     | Incoming  | `BokBook`, `BookClassSubject` for prescribed books        | Required   |
| Hostel (HST)            | Incoming  | Hostel allocation (planned — Hostel module pending)       | Planned    |
| Maintenance (MNT)       | N/A       | No current integration                                    | N/A        |

### 11.2 Infrastructure Dependencies

| Dependency              | Purpose                                                   |
|-------------------------|-----------------------------------------------------------|
| Stancl Tenancy v3.9     | `InitializeTenancyByDomain` + `PreventAccessFromCentralDomains` |
| Spatie Laravel-Permission | `role:Student|Parent` middleware                        |
| Razorpay PHP SDK        | Payment order creation                                    |
| Laravel Notifiable      | Notification trait on `sys_users`                        |

---

## 12. Test Scenarios

### 12.1 Existing Tests (7 files — basic scaffolding)

| File                                              | Type    | Current Coverage                                  |
|---------------------------------------------------|---------|---------------------------------------------------|
| `tests/Feature/StudentPortalControllerTest.php`   | Feature | Basic HTTP response checks for dashboard, account  |
| `tests/Feature/ComplaintControllerTest.php`       | Feature | Basic HTTP response for complaint create/store     |
| `tests/Feature/NotificationControllerTest.php`    | Feature | Basic HTTP response for notification listing       |
| `tests/Unit/StudentPortalControllerTest.php`      | Unit    | Controller instantiation checks                    |
| `tests/Unit/ComplaintControllerTest.php`          | Unit    | Complaint controller unit checks                   |
| `tests/Unit/NotificationControllerTest.php`       | Unit    | Notification controller unit checks                |
| `tests/Pest.php`                                  | Config  | Pest configuration                                 |

### 12.2 Required Tests (Missing — by Priority)

#### P0 Security Tests
| ID        | Scenario                                                                                | Expected Result                                          |
|-----------|-----------------------------------------------------------------------------------------|----------------------------------------------------------|
| T-STP-001 | Student A calls `GET /student-portal/view-invoice/{B_invoice_id}` (student B's invoice) | 404 or 403 — must not return invoice data                |
| T-STP-002 | Student A POSTs `proceed-payment` with `payable_id` = student B's invoice ID           | 403 Forbidden or 422 Unprocessable — payment must fail   |
| T-STP-003 | Admin user (non-student) calls `GET /student-portal/dashboard`                         | Redirect or 403 — must not serve portal                  |
| T-STP-004 | Unauthenticated call to `GET /student-portal/dashboard`                                 | Redirect to login                                        |
| T-STP-005 | Student marks another user's notification as read                                       | 403 or no-op                                             |

#### P1 Functional Tests
| ID        | Scenario                                                                                | Expected Result                                          |
|-----------|-----------------------------------------------------------------------------------------|----------------------------------------------------------|
| T-STP-010 | Student with active session sees timetable grid with correct subjects                  | Grid populated; break cells excluded                     |
| T-STP-011 | Student with no session sees timetable with `noSession` flag                           | View renders; no error                                   |
| T-STP-012 | Dashboard fee summary shows correct total/paid/due for student                         | Correct numeric values                                   |
| T-STP-013 | Dashboard pending homework count matches unsubmitted published homework                | Count accurate                                           |
| T-STP-014 | Attendance page groups records by month correctly                                       | Group keys match "March 2026" format                     |
| T-STP-015 | Complaint is created with `created_by = auth()->id()`                                  | Complaint stored; complainant_user_id is auth user       |
| T-STP-016 | Complaint listing shows only own complaints                                             | Other students' complaints not visible                   |
| T-STP-017 | PaymentGateway listing shows only active gateways                                      | Disabled gateways excluded from payment page             |
| T-STP-018 | `mark-all-read` marks only authenticated user's notifications                          | Other users' notifications unaffected                    |

#### P2 Regression / Completeness Tests
| ID        | Scenario                                                                                | Expected Result                                          |
|-----------|-----------------------------------------------------------------------------------------|----------------------------------------------------------|
| T-STP-020 | Syllabus progress shows correct `completed/in_progress/upcoming` per topic              | Status derived correctly from scheduled dates            |
| T-STP-021 | My teachers page builds correct unique teacher list from timetable cells               | No duplicate teachers; subject+day data correct          |
| T-STP-022 | Library my-books shows `null` state for student with no library membership             | Empty state rendered; no exception                       |
| T-STP-023 | Transport page shows `null` state for student with no transport allocation             | Empty state rendered                                     |
| T-STP-024 | Progress card shows only `Published` status reports for the student                    | Draft/unpublished reports excluded                       |
| T-STP-025 | `EnsureTenantHasModule` blocks portal access when STP module is disabled for tenant    | Redirect or 403                                          |

---

## 13. Glossary

| Term                       | Definition                                                                                             |
|----------------------------|--------------------------------------------------------------------------------------------------------|
| IDOR                        | Insecure Direct Object Reference — vulnerability where an attacker can access another user's resources by manipulating an ID parameter |
| Student Portal             | The STP module — student-facing web interface separate from the admin backend                          |
| Tenant                     | A single school instance with its own isolated database (`tenant_{uuid}`)                              |
| Gate / Policy              | Laravel authorization primitives (`Gate::authorize()`, `$this->authorize()`, `$this->can()`)           |
| FormRequest                | Laravel's typed request class providing authorization (`authorize()`) and validation (`rules()`)       |
| Spatie Role                | A named role managed by `spatie/laravel-permission` — `Student` and `Parent` roles gate portal access  |
| `role:Student|Parent`      | Spatie middleware syntax meaning "user must have role Student OR Parent"                                |
| EnsureTenantHasModule      | Custom middleware checking that the current tenant's subscription includes the StudentPortal module     |
| `currentFeeAssignemnt`     | Typo in `Student` model relationship name — should be `currentFeeAssignment`                           |
| HPC                        | Holistic Progress Card — report card module; publishes PDF progress cards per student                  |
| ExamAllocation             | Record linking an exam paper to a class, section, or individual student                                |
| QuizAllocation             | Record linking a quiz to a class, section, or student                                                  |
| QuestAllocation            | Record linking a quest (gamified learning path) to a class, section, or student                        |
| `payable_id`               | The database ID of the resource being paid (typically a `FeeInvoice` record)                           |
| is_break                   | Boolean flag on `TimetableCell` indicating a non-teaching break period                                 |
| `can_access_parent_portal` | Boolean flag on `std_student_guardian_jnt` — grants guardian access to view child's portal data        |

---

## 14. Suggestions

### 14.1 P0 — Fix Immediately (Before Any Production Deployment)

**S-STP-01: Fix IDOR in `proceedPayment()`**
Add server-side ownership check before calling `PaymentService::createPayment()`:
```php
$invoice = FeeInvoice::whereHas('feeStudentAssignment',
    fn($q) => $q->where('student_id', auth()->user()->student->id)
)->findOrFail($request->payable_id);
abort_if($invoice->balance_amount <= 0, 422, 'Invoice already paid');
```

**S-STP-02: Verify `viewInvoice` / `payDueAmount` ownership guard is correct**
Current guard: `FeeInvoice::where('student_id', auth()->user()->student->id)->findOrFail($id)`. Confirm `fee_invoices` table has a direct `student_id` column. If not (i.e., ownership is via `fee_student_assignments`), switch to:
```php
FeeInvoice::whereHas('feeStudentAssignment',
    fn($q) => $q->where('student_id', auth()->user()->student->id)
)->findOrFail($id);
```

**S-STP-03: Add `EnsureTenantHasModule` middleware to portal route group**
In `RouteServiceProvider::mapWebRoutes()`, add `EnsureTenantHasModule:StudentPortal` to the middleware array.

**S-STP-04: Remove or gate the `test-notification` route**
Verify the `test-notification` route has been removed from `routes/tenant.php`. If it must remain, wrap in `App::environment('local')` check.

### 14.2 P1 — High Priority (Current Sprint)

**S-STP-05: Create `FormRequest` classes**
Minimum required:
- `StoreComplaintRequest` — rules for target_type_id, complainant_type_id, category_id, subcategory_id, description, attachment; `authorize()` returns `auth()->user()->hasRole('Student')`
- `ProcessPaymentRequest` — rules for amount (min:0.01), payable_type, payable_id (with custom ownership validation), gateway

**S-STP-06: Replace hard-coded dropdown ID `104` in `StudentPortalComplaintController`**
Lines 73 and 125 compare `$request->complainant_type_id` to integer `104`. Replace with:
```php
$studentType = \DB::table('sys_dropdowns')->where('key', 'COMPLAINANT_STUDENT')->value('id');
if ((int)$request->complainant_type_id === $studentType) { ... }
```
Or better: move the entire lookup into `StoreComplaintRequest`.

**S-STP-07: Fix `PaymentGateway::all()` → `PaymentGateway::active()->get()`**
In `payDueAmount()` method of `StudentPortalController`.

**S-STP-08: Fix typo `currentFeeAssignemnt` → `currentFeeAssignment`**
The relationship method on the `Student` model is misspelled. Three controller methods use it. Fix the relationship name and update all callers.

**S-STP-09: Paginate complaint index**
`Complaint::where('created_by', Auth::id())->get()` → add `->paginate(15)` and pass `->withQueryString()`.

**S-STP-10: Change `notifications/{id}/mark-read` from GET to POST/PATCH**
Prevents browser pre-fetchers (e.g., link scanners) from inadvertently marking notifications as read.

**S-STP-11: Remove scaffold stub methods from `StudentPortalController`**
Methods `index()`, `create()`, `store()`, `show()`, `edit()`, `update()`, `destroy()` at the bottom of the file are unused scaffold remnants. Remove them to reduce confusion and dead routes.

### 14.3 P2 — Medium Priority (Next Sprint)

**S-STP-12: Extract a `StudentPortalService` class**
Move dashboard aggregation logic (attendance stats, timetable, homework, exam, fee queries) into a dedicated `StudentPortalService`. The `dashboard()` method is currently 110+ lines.

**S-STP-13: Implement leave application workflow**
`/student-portal/apply-leave` currently returns a stub view. Implement:
- Leave application form (reason, start/end date, type, attachment)
- `StoreLeaveApplicationRequest`
- Store to an appropriate model (e.g., `std_leave_applications` — may require new table)
- Leave approval status display

**S-STP-14: Implement school calendar**
`/student-portal/school-calendar` currently returns a stub. Implement FullCalendar.js integration reading from school holiday/event tables.

**S-STP-15: Implement account settings backend**
Three tabs are view-only stubs:
- Password change: POST `/student-portal/account/password` → `Hash::check()` old + `Hash::make()` new
- Notification preferences: store channel toggles per user
- Privacy settings: store data visibility flags

**S-STP-16: Implement homework submission from portal**
Current `homework/index.blade.php` exists but there is no submission route. Add:
- `POST student-portal/homework/{homework}/submit` — `HomeworkSubmission::create([...])`
- File upload support
- Submission status display

**S-STP-17: Implement results with actual marks**
`/student-portal/results` shows concluded exam allocations but no marks. Integrate with `ExamResult` or equivalent model from LmsExam to display obtained marks, percentage, grade.

**S-STP-18: Wire quiz/quest player screens**
`quiz/index.blade.php` and `quest/index.blade.php` exist but have no routes. Add:
- `GET student-portal/quiz` → list assigned quizzes with status
- `GET student-portal/quest` → list assigned quests
- Link to quiz/quest player (may redirect to LmsQuiz/LmsQuests module URLs)

**S-STP-19: Fix notice board to use announcement model**
`/student-portal/notice-board` currently shows from `auth()->user()->notifications()`. Should display from a dedicated notice/announcement model (e.g., `sch_notices` or `sys_announcements`).

**S-STP-20: Add PDF download for progress card and ID card**
Progress card: link to HPC module's PDF generation route per report.
ID card: add a `/student-portal/student-id-card/download` route that generates a minimal PDF (via DomPDF).

### 14.4 P3 — Backlog

**S-STP-21: REST API for mobile/PWA**
Implement API endpoints (section 6.2) secured with `auth:sanctum`, returning JSON for mobile app or PWA integration.

**S-STP-22: Parent dashboard separation**
Currently Parent role users see the same dashboard as students. Build a separate parent view that:
- Lists linked children (from `std_student_guardian_jnt` where `can_access_parent_portal = 1`)
- Allows switching between children
- Shows aggregated data for selected child

**S-STP-23: Hostel integration**
Wire `/student-portal/hostel` when the Hostel module is complete. Show room number, block, floor, mess schedule, roommates.

**S-STP-24: Push notifications / FCM**
Add Firebase Cloud Messaging support for mobile push notifications alongside existing Laravel database notifications.

**S-STP-25: Add `Gate::authorize()` or `$this->authorize()` calls**
Even with Spatie middleware at the route group level, individual controller actions should use policy-based authorization for per-resource ownership checks. Create `StudentPortalPolicy` with methods:
- `viewInvoice(User $user, FeeInvoice $invoice)` — checks ownership
- `payInvoice(User $user, FeeInvoice $invoice)` — checks ownership + payable status
- `createComplaint(User $user)` — checks user is Student role

---

## 15. Appendices

### 15.1 Controller Summary (7 controllers — 1,317 lines total)

| Controller                         | Lines | Methods                                               |
|------------------------------------|-------|-------------------------------------------------------|
| `StudentPortalController`          | 558   | login, dashboard, account, academicInformation, feeSummary, healthRecords, examSchedule, idCard, viewInvoice, payDueAmount, proceedPayment, results, noticeBoard, studyResources, prescribedBooks, library, libraryMyBooks, schoolCalendar, applyLeave, transport, hostel, progressCard, performanceAnalytics, myRecommendations + 7 stubs |
| `StudentPortalComplaintController` | 248   | index, create, store, show, edit, update, destroy, getCategories, getCategoryMeta |
| `NotificationController`           | 71    | allNotifications, markAllRead, markRead               |
| `StudentLmsController`             | 105   | index (homework + exams + quizzes + quests)           |
| `StudentProgressController`        | 137   | attendance, syllabusProgress                          |
| `StudentTeachersController`        | 115   | index                                                 |
| `StudentTimetableController`       | 83    | index                                                 |

### 15.2 Security Audit Summary

| Check                             | V1 Status | V2 Status     | Notes                                              |
|-----------------------------------|-----------|---------------|----------------------------------------------------|
| CSRF Protection                   | PASS      | PASS          | Web middleware applied                             |
| Auth Middleware                   | PASS      | PASS          | Applied                                            |
| Role-Based Access (Student only)  | FAIL      | PASS          | `role:Student|Parent` in RouteServiceProvider      |
| EnsureTenantHasModule             | FAIL      | FAIL          | Still missing                                      |
| IDOR — viewInvoice                | FAIL      | PARTIAL       | `where('student_id', ...)` added — verify column  |
| IDOR — payDueAmount               | FAIL      | PARTIAL       | `where('student_id', ...)` added — verify column  |
| IDOR — proceedPayment             | FAIL      | FAIL          | `payable_id` still unchecked                       |
| Gate/Policy                       | FAIL      | FAIL          | Zero `Gate::authorize()` calls                     |
| FormRequest                       | FAIL      | FAIL          | Zero FormRequest classes                           |
| PaymentGateway filter             | FAIL      | FAIL          | Still `::all()` not `::active()`                   |
| Hard-coded dropdown ID 104        | FAIL      | FAIL          | Still present                                      |
| Test notification route           | FAIL      | UNKNOWN       | Not confirmed removed                              |
| SQL Injection                     | PASS      | PASS          | Eloquent only                                      |
| XSS                               | PASS      | PASS          | Blade escaping                                     |
| Complaint description HTML        | WARN      | WARN          | Arbitrary HTML accepted                            |
| File upload validation            | WARN      | WARN          | Needs review                                       |

### 15.3 View File Count by Category

| Category             | File Count |
|----------------------|-----------|
| Academic Information | 10        |
| Account (tabs)       | 7         |
| Attendance           | 1         |
| Auth                 | 1         |
| Calendar             | 1         |
| Complaint            | 2         |
| Components/Layout    | 1         |
| Dashboard            | 1         |
| Exams                | 1         |
| Fee                  | 1         |
| Health               | 1         |
| Homework             | 1         |
| Hostel               | 1         |
| ID Card              | 1         |
| Learning (LMS hub)   | 5         |
| Leave                | 1         |
| Library              | 2         |
| Notice Board         | 1         |
| Notification         | 4         |
| Online Exam          | 1         |
| Quest                | 1         |
| Quiz                 | 1         |
| Reports              | 3         |
| Resources            | 2         |
| Results              | 1         |
| Syllabus             | 1         |
| Teachers             | 1         |
| Timetable            | 1         |
| Transport            | 1         |
| Misc (index, coming-soon) | 2   |
| **Total**            | **57**    |

---

## 16. V1 to V2 Delta

### 16.1 What Changed Since V1 (2026-03-22 → 2026-03-26)

| Area                    | V1 State                                          | V2 State                                               |
|-------------------------|---------------------------------------------------|--------------------------------------------------------|
| Controller count        | 3                                                 | 7 (+4 new controllers)                                 |
| Route count             | ~15                                               | ~55 routes across 35+ screens                         |
| Blade view count        | ~20                                               | 57                                                     |
| Screen count (built)    | 3 of 27 (11%)                                     | ~22 of 35 (63%)                                        |
| Dashboard data          | Notifications only; stats missing                 | Fully populated: attendance, timetable, homework, exams, fee |
| Timetable               | Missing                                           | Built (`StudentTimetableController`) ✅                 |
| Attendance              | Partial template only                             | Built (`StudentProgressController@attendance`) ✅       |
| LMS Hub                 | Missing                                           | Built (`StudentLmsController`) ✅                       |
| Syllabus Progress       | Missing                                           | Built (`StudentProgressController@syllabusProgress`) ✅ |
| My Teachers             | Missing                                           | Built (`StudentTeachersController`) ✅                  |
| Transport               | Missing                                           | Built ✅                                                |
| Library                 | Missing                                           | Built (catalog + my books) ✅                           |
| Progress Card (HPC)     | Missing                                           | Built ✅                                                |
| Exam Schedule           | Missing                                           | Built ✅                                                |
| Results                 | Missing                                           | Built (schedule only — no marks) 🟡                    |
| Fee Summary             | Inline in academic-information only               | Dedicated `/fee-summary` route ✅                       |
| Health Records          | Within academic-information                       | Dedicated `/health-records` route ✅                    |
| ID Card                 | Missing                                           | Built ✅                                                |
| Recommendations         | Missing                                           | Built ✅                                                |
| Study Resources         | Missing                                           | Built ✅                                                |
| Role middleware         | MISSING (any auth user could access)              | `role:Student|Parent` in RouteServiceProvider ✅        |
| IDOR viewInvoice        | `findOrFail($id)` — no ownership check            | `where('student_id', ...)->findOrFail($id)` — partial fix 🟡 |
| IDOR payDueAmount       | `findOrFail($id)` — no ownership check            | `where('student_id', ...)->findOrFail($id)` — partial fix 🟡 |
| IDOR proceedPayment     | No check                                          | No check — still a P0 vulnerability ❌                  |
| Gate/Policy             | Zero calls                                        | Zero calls — still missing ❌                           |
| FormRequests            | Zero                                              | Zero — still missing ❌                                 |
| Services                | Zero                                              | Zero — still missing ❌                                 |
| proceedPayment HTTP     | GET (wrong)                                       | Changed to POST ✅                                      |
| Leave application       | Missing                                           | Route exists; stub view only ❌                          |
| School calendar         | Missing                                           | Route exists; stub view only ❌                          |
| Hostel                  | Missing                                           | Route exists; stub view only ❌                          |
| Online exam player      | Missing                                           | View exists; no route or controller ❌                   |
| Quiz/Quest player       | Missing                                           | Views exist; no routes wired ❌                          |

### 16.2 Screen Count Reconciliation

- V1 documented: 27 designed screens
- V2 actual view directories: 35 distinct screens (some added during development)
- Screens ✅ fully built: ~22
- Screens 🟡 partial: ~8
- Screens ❌ stub/missing: ~5

### 16.3 Estimated Remaining Effort

| Priority | Remaining Work                                                         | Effort (person-days) |
|----------|------------------------------------------------------------------------|---------------------|
| P0       | IDOR fix in proceedPayment; verify viewInvoice guard; EnsureTenantHasModule | 1 |
| P1       | FormRequests (2); fix hard-coded ID 104; fix PaymentGateway::all(); paginate complaints; fix typo; remove stubs | 3 |
| P2       | Leave application; school calendar; account settings backend (3 tabs); homework submission; results with marks; quiz/quest routes; notice board fix | 7 |
| P3       | REST API; parent dashboard; hostel integration; push notifications; PDF downloads | 4 |
| **Total**|                                                                        | **~15**             |
