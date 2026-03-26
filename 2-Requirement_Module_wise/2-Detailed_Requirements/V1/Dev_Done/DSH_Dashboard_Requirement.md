# Dashboard Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** DSH | **Module Path:** `Modules/Dashboard`
**Module Type:** Other (Cross-Module Aggregator) | **Database:** N/A (no dedicated tables)
**Table Prefix:** N/A | **Processing Mode:** FULL
**RBS Reference:** N/A

---

## 1. EXECUTIVE SUMMARY

### 1.1 Purpose

The Dashboard module serves as the primary landing screen for authenticated users of the Prime-AI tenant application. It acts as a cross-module aggregator, surfacing key operational metrics, alerts, and navigational entry points from all other modules in a single, role-aware view. It is the first screen a School Admin, Teacher, Student, or Parent encounters after login.

### 1.2 Scope

The module currently provides routing scaffolding and view stubs for six functional sub-dashboards (Core Configuration, Foundational Setup, Admission & Student Management, School Setup, Operation Management, Support Management). It also exposes a top-level `GET /dashboard` route that is the default post-login redirect. No dynamic data is currently injected — all widgets show static hardcoded placeholder values copied from AdminLTE demo templates.

### 1.3 Module Statistics

| Item | Count |
|---|---|
| Controllers | 1 (`DashboardController`) |
| Models | 0 |
| Services | 0 |
| FormRequests | 0 |
| Tests | 0 |
| Views | 8 (1 `index.blade.php` stub + 6 sub-dashboard views + 1 layout master) |
| Web Routes | 7 (1 root + 6 sub-dashboard GET routes) |
| API Routes | 1 (`apiResource` — non-functional) |
| Migrations | 0 |
| Seeders | 1 (empty `DashboardDatabaseSeeder`) |

### 1.4 Implementation Status

| Area | Status | Notes |
|---|---|---|
| Routing scaffold | Done | Routes registered in `tenant.php` |
| Controller methods | Partial (~35%) | 7 methods exist; all return views with no data |
| View layouts | Done | Views use correct `x-backend.layouts.app` component |
| Dynamic data | Not started | All values are static/hardcoded |
| Authorization (Gates/Policies) | Not started | Zero middleware or Gate checks on any method |
| Role-based views | Not started | Single undifferentiated view for all roles |
| Widget data services | Not started | No services, no queries |
| API endpoints | Not started | `apiResource` registered but controller has no API methods |

---

## 2. MODULE OVERVIEW

### 2.1 Business Purpose

Indian K-12 school administrators, teachers, students, and parents need a single-pane-of-glass view to monitor school operations without navigating deep into each functional module. The Dashboard provides:

- An at-a-glance operational health check (attendance, fees, exam schedule)
- Notification/alert surfacing (pending approvals, upcoming events)
- Quick navigation shortcuts to key module functions
- Role-differentiated information density (admin sees financials; teacher sees class schedule; student/parent see personal academic progress)

### 2.2 Key Features Summary

**Planned (not yet implemented):**

1. Tenant Admin Dashboard — school-wide operational KPIs
2. Teacher Dashboard — class/subject-specific metrics
3. Student Dashboard — personal academic progress, upcoming assignments, fee status
4. Parent Dashboard — child-centric academic and financial view
5. Sub-dashboards by functional domain (Core Config, Foundational Setup, Admission, School Setup, Operations, Support)
6. Role-aware widget visibility via RBAC

**Currently implemented (stub only):**

- Static AdminLTE demo template with hardcoded "New Orders", "Bounce Rate", "User Registrations", "Unique Visitors" widgets (irrelevant to school context)
- Revenue chart placeholder and Direct Chat placeholder (demo content from AdminLTE)
- Six sub-dashboard routes returning identical static views

### 2.3 Menu Navigation Path

**Tenant Application:**
- Root: `POST-LOGIN REDIRECT → /dashboard` (main index)
- `Dashboard > Core Configuration`
- `Dashboard > Foundational Setup`
- `Dashboard > Admission & Student Management`
- `Dashboard > School Setup`
- `Dashboard > Operation Management`
- `Dashboard > Support Management`

### 2.4 Module Architecture (Actual Folder Structure)

```
Modules/Dashboard/
├── app/
│   ├── Http/Controllers/
│   │   └── DashboardController.php          (7 methods, no data injection)
│   └── Providers/
│       ├── DashboardServiceProvider.php
│       ├── EventServiceProvider.php
│       └── RouteServiceProvider.php
├── config/
│   └── config.php                           (name: 'Dashboard' only)
├── database/
│   └── seeders/
│       └── DashboardDatabaseSeeder.php      (empty)
├── resources/views/
│   ├── index.blade.php                      (stub: "Hello World" placeholder)
│   ├── components/layouts/master.blade.php  (module-level layout — not used by routes)
│   ├── core-configuration/dashboard.blade.php
│   ├── foundational-setup/dashboard.blade.php
│   ├── admission-student-management/dashboard.blade.php
│   ├── school-setup/dashboard.blade.php
│   ├── operation-management/dashboard.blade.php
│   └── support-management/dashboard.blade.php
└── routes/
    ├── web.php                              (resource route — not integrated into tenant.php)
    └── api.php                              (apiResource — non-functional)
```

**Note:** The controller's `index()` method returns `view('backend.v1.dashboard.index')` — a path **outside** the module (in the main `resources/views/backend/v1/dashboard/index.blade.php`), NOT `dashboard::index`. This is a known architectural inconsistency.

---

## 3. STAKEHOLDERS & ACTORS

| Actor | Role | Dashboard Needs |
|---|---|---|
| School Admin / Principal | Primary dashboard consumer | Financial KPIs, attendance %, exam schedule, pending approvals, staff headcount, student count |
| Class Teacher | Daily operations | Today's timetable, attendance pending, homework assignments, exam schedule |
| Subject Teacher | Subject-focused | Subject-wise homework pending, quiz results, exam grading queue |
| Student | Self-monitoring | Today's classes, pending assignments, recent exam scores, fee dues, notifications |
| Parent | Child monitoring | Child's attendance, fee dues, recent exam results, upcoming events |
| Super Admin (Prime-AI) | Platform oversight | Tenant health check — handled in prime_db; out of scope for this module |

---

## 4. FUNCTIONAL REQUIREMENTS

### 4.1 Main Tenant Admin Dashboard (FR-DSH-001 through FR-DSH-010)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DSH-001 | Display total enrolled students (current academic session) | High | Not done |
| FR-DSH-002 | Display today's attendance percentage (school-wide) | High | Not done |
| FR-DSH-003 | Display today's staff attendance / absent count | High | Not done |
| FR-DSH-004 | Display fee collection summary: collected vs pending for current month | High | Not done |
| FR-DSH-005 | Display upcoming exam schedule (next 7 days) | Medium | Not done |
| FR-DSH-006 | Display today's timetable highlights (periods happening now / next) | Medium | Not done |
| FR-DSH-007 | Display recent notifications (unread count + top 5 list) | High | Not done |
| FR-DSH-008 | Display pending approvals (leave requests, complaints, etc.) | Medium | Not done |
| FR-DSH-009 | Display upcoming events / school calendar items (next 7 days) | Medium | Not done |
| FR-DSH-010 | Quick-access links to high-frequency module actions | Medium | Not done |

### 4.2 Teacher Dashboard (FR-DSH-011 through FR-DSH-015)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DSH-011 | Display teacher's today timetable (periods, subjects, sections) | High | Not done |
| FR-DSH-012 | Display attendance marking status (completed vs pending periods today) | High | Not done |
| FR-DSH-013 | Display pending homework grading count | Medium | Not done |
| FR-DSH-014 | Display upcoming exams for teacher's assigned subjects | Medium | Not done |
| FR-DSH-015 | Display unread notifications | High | Not done |

### 4.3 Student Dashboard (FR-DSH-016 through FR-DSH-020)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DSH-016 | Display student's today timetable | High | Not done |
| FR-DSH-017 | Display pending/recent homework assignments | High | Not done |
| FR-DSH-018 | Display recent exam results / upcoming exams | Medium | Not done |
| FR-DSH-019 | Display fee due amount and due date | High | Not done |
| FR-DSH-020 | Display school announcements / notifications | Medium | Not done |

### 4.4 Parent Dashboard (FR-DSH-021 through FR-DSH-025)

| ID | Requirement | Priority | Status |
|---|---|---|---|
| FR-DSH-021 | Display child's attendance summary (current month %) | High | Not done |
| FR-DSH-022 | Display child's recent exam performance | Medium | Not done |
| FR-DSH-023 | Display fee dues for the child | High | Not done |
| FR-DSH-024 | Display school notices / communications | Medium | Not done |
| FR-DSH-025 | Support multi-child selection if parent has more than one child | Medium | Not done |

### 4.5 Sub-Domain Dashboards (FR-DSH-026 through FR-DSH-031)

| ID | Dashboard | Requirement |
|---|---|---|
| FR-DSH-026 | Core Configuration | Setup completion indicators (academic session configured, class setup, subject setup) |
| FR-DSH-027 | Foundational Setup | Board/medium/section setup status, infrastructure completeness |
| FR-DSH-028 | Admission & Student Mgmt | New admissions (today/this month), pending admissions in pipeline, dropout count |
| FR-DSH-029 | School Setup | Profile completion %, staff count, class-section count |
| FR-DSH-030 | Operation Management | Timetable status, exam schedule status, transport active routes |
| FR-DSH-031 | Support Management | Open complaints count, pending library returns, HPC pending count |

### 4.6 Known Gaps and Issues

| Issue | Severity | Description |
|---|---|---|
| Wrong view path in `index()` | Critical | Returns `backend.v1.dashboard.index` (outside module) instead of `dashboard::index` |
| Zero authorization | Critical | No `Gate::authorize()`, no role middleware, no permission checks on any dashboard method |
| All content is static | Critical | All views contain hardcoded demo data from AdminLTE ("New Orders", "Bounce Rate") — not school data |
| `apiResource` registered but empty | High | `api.php` registers an `apiResource` but the controller has no API-oriented methods |
| All sub-dashboard views are identical | High | All 6 sub-dashboard blade files are byte-for-byte identical copies of the same AdminLTE demo template |
| Module-level `web.php` not integrated | Medium | `routes/web.php` registers `Route::resource('dashboards', ...)` but is separate from `tenant.php` integration |
| Module layout not used | Low | `components/layouts/master.blade.php` is defined but no view uses it |

---

## 5. DATA MODEL & ENTITY SPECIFICATION

The Dashboard module has no dedicated database tables. All data is read from other module tables. Below is the cross-module data map required to power each widget.

### 5.1 Admin Dashboard Data Sources

| Widget | Source Table(s) | Query Description |
|---|---|---|
| Total Students | `std_student_profiles` | `COUNT` where `is_active=true`, joined to current `academic_term_id` |
| Today Attendance % | `std_attendances` | `COUNT present / COUNT total` where `date = today` |
| Staff Attendance | `std_attendances` (staff type) | Similar but for staff users |
| Fee Collection | `fin_fee_collections` | Sum `paid_amount` where `payment_date` in current month |
| Fee Pending | `fin_student_fee_dues` | Sum `due_amount` where `status != paid` |
| Upcoming Exams | `exm_exam_schedules` | `WHERE exam_date BETWEEN today AND today+7` |
| Notifications | `sys_notifications` | `WHERE notifiable_id = auth()->id() AND read_at IS NULL LIMIT 5` |
| Pending Approvals | Various | Leave: `std_leave_requests WHERE status=pending`; Complaints: `cmp_complaints WHERE status=open` |
| Events | `sch_events` or equivalent | Events in next 7 days for the school |

### 5.2 Teacher Dashboard Data Sources

| Widget | Source Table(s) | Query Description |
|---|---|---|
| Today's Timetable | `tt_timetable_cells` | Joined to teacher → periods for today |
| Attendance Pending | `std_attendances` | Periods today where attendance not yet marked |
| Pending Homework | `lms_homework_submissions` | Submitted but not graded for teacher's classes |
| Upcoming Exams | `exm_exam_schedules` | Subject matches teacher's subjects |

### 5.3 Student/Parent Data Sources

| Widget | Source Table(s) | Query Description |
|---|---|---|
| Today's Timetable | `tt_timetable_cells` | By class_id + section_id for the student |
| Attendance % | `std_attendances` | Current month, student_id |
| Pending Homework | `lms_homework_assignments` | Due date >= today for student's class |
| Exam Results | `exm_student_results` | Latest 5 for student |
| Fee Dues | `fin_student_fee_dues` | Unpaid for student |

---

## 6. API & ROUTE SPECIFICATION

### 6.1 Registered Web Routes (tenant.php)

| # | Method | URI | Controller Method | Route Name | Auth | Status |
|---|---|---|---|---|---|---|
| 1 | GET | `/dashboard` | `DashboardController@index` | `dashboard` | auth, verified | Stub (wrong view path) |
| 2 | GET | `/dashboard/core-configuration` | `DashboardController@coreConfiguration` | `dashboard.core-configuration` | auth, verified | Stub (static) |
| 3 | GET | `/dashboard/foundational-setup` | `DashboardController@foundationSetup` | `dashboard.foundational-setup` | auth, verified | Stub (static) |
| 4 | GET | `/dashboard/admission-student-management` | `DashboardController@admissionStudentManagement` | `dashboard.admission-student-management` | auth, verified | Stub (static) |
| 5 | GET | `/dashboard/school-setup` | `DashboardController@schoolSetup` | `dashboard.school-setup` | auth, verified | Stub (static) |
| 6 | GET | `/dashboard/operation-management` | `DashboardController@operationManagement` | `dashboard.operation-management` | auth, verified | Stub (static) |
| 7 | GET | `/dashboard/support-management` | `DashboardController@supportManagement` | `dashboard.support-management` | auth, verified | Stub (static) |

**Note:** Two additional notification-related routes are registered under the `dashboard.*` prefix:

| # | Method | URI | Controller Method | Route Name |
|---|---|---|---|---|
| 8 | GET | `/dashboard/test-notification` | `NotificationController@testNotification` | `dashboard.test-notification` |
| 9 | GET | `/dashboard/all-notifications` | `NotificationController@allNotifications` | `dashboard.all-notifications` |

### 6.2 Module-Level Web Routes (Modules/Dashboard/routes/web.php — separate, possibly not loaded)

| Method | URI | Route Name |
|---|---|---|
| GET/POST/PUT/PATCH/DELETE | `/dashboards/{dashboard}` | `dashboard.*` (resource) |

### 6.3 API Routes (Modules/Dashboard/routes/api.php — non-functional)

| Method | URI | Auth |
|---|---|---|
| GET/POST/PUT/PATCH/DELETE | `/api/v1/dashboards/{dashboard}` | `auth:sanctum` |

### 6.4 Required Future API Endpoints

| Method | URI | Purpose |
|---|---|---|
| GET | `/api/v1/dashboard/admin` | Admin KPI widget data (JSON) |
| GET | `/api/v1/dashboard/teacher` | Teacher daily schedule + pending tasks |
| GET | `/api/v1/dashboard/student` | Student personal data |
| GET | `/api/v1/dashboard/parent` | Parent child-centric data |
| GET | `/api/v1/dashboard/notifications` | Unread notifications for current user |

---

## 7. UI SCREEN INVENTORY & FIELD MAPPING

### 7.1 Screen: Main Dashboard (index) — Current State

**Route:** `GET /dashboard`
**View:** `backend.v1.dashboard.index` (non-module path — known bug)
**Layout:** `x-backend.layouts.app`

| Widget | Current Value | Required Value |
|---|---|---|
| Box 1 (primary) | "New Orders: 150" | Total Students (current session) |
| Box 2 (success) | "Bounce Rate: 53%" | Today's Attendance % |
| Box 3 (warning) | "User Registrations: 44" | Fee Collected This Month |
| Box 4 (danger) | "Unique Visitors: 65" | Pending Fee Amount |
| Chart | "Sales Value" (empty chart div `#revenue-chart`) | Monthly Fee Collection Trend |
| Chat Panel | AdminLTE demo chat (static) | School Announcements / Notifications |
| Map | World map (`#world-map`) | Not applicable — remove |

### 7.2 Screen: Sub-Domain Dashboards (core-configuration, foundational-setup, etc.)

**Current State:** All 6 sub-dashboard views are byte-for-byte identical to the main dashboard — same AdminLTE demo content, same hardcoded static values, no relevance to their intended domain.

**Required State (per sub-dashboard):**

| Sub-Dashboard | Required Widgets |
|---|---|
| Core Configuration | Academic session active?, Current term dates, Board/medium setup status, Number of active classes, Number of subjects configured |
| Foundational Setup | Infrastructure rooms count, School buildings count, Transport routes active |
| Admission & Student Mgmt | New admissions this month, Total active students, Class-wise strength chart, Recent admissions list |
| School Setup | School profile completion %, Staff count (active), Department count, Class-section count |
| Operation Management | Timetable generated (Y/N), Active exam schedules, Library books issued today, Transport routes operating |
| Support Management | Open complaints, Pending vendor POs, Library overdue count, Recent activity log |

---

## 8. BUSINESS RULES & DOMAIN CONSTRAINTS

| ID | Rule |
|---|---|
| BR-DSH-001 | The dashboard must always display data scoped to the **current tenant** (tenant_db isolation). Cross-tenant data must never appear. |
| BR-DSH-002 | All KPI widgets must reflect the **current academic term** (active `academic_term_id`). If no session is active, widgets must show a "No active session" state. |
| BR-DSH-003 | The dashboard view must be **role-aware**: admin sees financials and all KPIs; teacher sees only their own class/subject data; student/parent see only their personal data. |
| BR-DSH-004 | Attendance % widget must only compute from **marked attendance records** — not from enrolled count alone. |
| BR-DSH-005 | Fee collection widget must show **INR amounts** with proper formatting (Indian numbering: lakhs, crores). |
| BR-DSH-006 | Quick-access links must only render if the user has permission to access the linked module (`Gate::check`). |
| BR-DSH-007 | The dashboard must handle empty/new-tenant gracefully — if no students are enrolled or no session is active, show appropriate empty states rather than zero or error. |
| BR-DSH-008 | Dashboard data must be **cached per user per day** to prevent repeated heavy cross-module queries. Cache should be invalidated when relevant module data changes. |

---

## 9. WORKFLOW & STATE MACHINE DEFINITIONS

The Dashboard module itself has no state machine. It is a read-only aggregator. However, it interacts with the following workflows:

| Module | Dashboard Interaction |
|---|---|
| Attendance | Triggers attendance % recalculation on dashboard cache invalidation |
| Fee Management | Fee collection widget updates when payment is recorded |
| Notifications | Unread count badge updates in real-time or on page refresh |
| Exam Management | Upcoming exam widget pulls from active exam schedule |

**Dashboard Loading Sequence:**

1. User logs in → redirected to `/dashboard`
2. `DashboardController@index` resolves user's primary role (Admin / Teacher / Student / Parent)
3. Role-specific service method is called (e.g., `DashboardService::getAdminData($tenant)`)
4. Data is fetched from relevant module tables (with cache check)
5. Appropriate blade view is rendered with data
6. Future: AJAX/API polling for real-time widgets (notifications, attendance)

---

## 10. NON-FUNCTIONAL REQUIREMENTS

| ID | Category | Requirement |
|---|---|---|
| NFR-DSH-001 | Performance | Dashboard must load within 2 seconds. Use caching (`Cache::remember`) with 15-minute TTL for aggregated KPIs. |
| NFR-DSH-002 | Security | All routes must be protected by `auth` + `verified` middleware. Sensitive financial data must additionally check `Gate::authorize`. |
| NFR-DSH-003 | Security | No sensitive data (student PII, exact fee amounts) should be exposed to unauthorized roles. |
| NFR-DSH-004 | Scalability | Widget queries must use database indexes. Avoid N+1 queries — use eager loading for relationships. |
| NFR-DSH-005 | Responsiveness | Dashboard must be mobile-responsive (Bootstrap 5 grid — currently satisfied by AdminLTE layout). |
| NFR-DSH-006 | Accessibility | Widget labels must be descriptive. Color alone should not convey meaning (e.g., red box for fee overdue must also have text). |
| NFR-DSH-007 | Maintainability | Each widget should be a separate Blade component or `@include` partial, not one monolithic view. |
| NFR-DSH-008 | Testability | `DashboardService` should be injectable and separately testable from the controller. |

---

## 11. CROSS-MODULE DEPENDENCIES

| Module Code | Dependency Type | Usage |
|---|---|---|
| STD (Student Management) | Data Read | `std_student_profiles` — total students, class-wise count |
| STD Attendance | Data Read | `std_attendances` — daily attendance % |
| FIN (Fee Management) | Data Read | `fin_fee_collections`, `fin_student_fee_dues` — fee KPIs |
| EXM (Exam) | Data Read | `exm_exam_schedules`, `exm_student_results` |
| TT (Timetable) | Data Read | `tt_timetable_cells` — today's schedule |
| LMS-HW (Homework) | Data Read | Pending homework count |
| NTF (Notifications) | Data Read + Write | Unread notification count; mark-read on click |
| CMP (Complaints) | Data Read | Open complaints count for admin |
| LIB (Library) | Data Read | Overdue books, today's issues |
| TPT (Transport) | Data Read | Active routes count |
| SYS (System Config) | Data Read | User roles, permissions for widget visibility gating |
| SCH (School Setup) | Data Read | School profile, active academic term |

---

## 12. TEST CASE REFERENCE & COVERAGE

**Current test coverage: 0 tests (0 test files in module).**

### 12.1 Recommended Test Cases

| ID | Type | Scenario | Expected Outcome |
|---|---|---|---|
| TC-DSH-001 | Feature | Admin loads `/dashboard` | 200 response, admin-specific widgets visible |
| TC-DSH-002 | Feature | Teacher loads `/dashboard` | 200 response, teacher-specific widgets visible; financial widgets absent |
| TC-DSH-003 | Feature | Student loads `/dashboard` | 200 response, student-personal widgets; no admin/teacher widgets |
| TC-DSH-004 | Feature | Unauthenticated user requests `/dashboard` | Redirected to login (302) |
| TC-DSH-005 | Feature | Admin dashboard with no active academic term | Returns "No active session" empty state, no error |
| TC-DSH-006 | Unit | `DashboardService::getAdminData()` returns correct structure | Array contains `students_count`, `attendance_percent`, `fee_collected` keys |
| TC-DSH-007 | Unit | `DashboardService::getAdminData()` uses cache | Second call returns cached result without DB query |
| TC-DSH-008 | Feature | Sub-dashboard `core-configuration` route | 200, correct breadcrumb, widgets scoped to Core Config domain |
| TC-DSH-009 | Security | Cross-tenant data isolation | Admin of Tenant A cannot see Tenant B's student count |
| TC-DSH-010 | Performance | Admin dashboard load time | Response generated in < 2000ms |

---

## 13. GLOSSARY & TERMINOLOGY

| Term | Definition |
|---|---|
| KPI | Key Performance Indicator — a metric widget on the dashboard |
| Tenant | A school instance with its own isolated database (`tenant_{uuid}`) |
| Academic Term | The active period configuration for a school year (e.g., 2025-26 Term 1) |
| Sub-dashboard | A domain-specific dashboard page for a particular functional area (e.g., Admission, Finance) |
| Widget | A self-contained UI card displaying a single metric or data visualization |
| Role-based View | A dashboard view that changes content based on the authenticated user's RBAC role |
| AdminLTE | The Bootstrap-based admin template used across the Prime-AI backend |
| Cross-module Aggregator | A module that does not own its own data but reads and summarizes data from many other modules |

---

## 14. ADDITIONAL SUGGESTIONS

> This section contains analyst recommendations only.

1. **Create a `DashboardService` class** with methods: `getAdminKpis()`, `getTeacherKpis()`, `getStudentKpis()`, `getParentKpis()`. Inject via constructor for testability.

2. **Implement role-based view dispatch** in `DashboardController@index`: detect user role using `auth()->user()->hasRole(...)` and return role-specific views.

3. **Fix the `index()` view path bug** immediately: `view('backend.v1.dashboard.index')` should be `view('dashboard::index')` or the module-aware correct path.

4. **Add `Gate::authorize` to all controller methods** before any data is fetched. Suggested permission: `prime.dashboard.view`.

5. **Use Blade components for widgets** to enable reuse across sub-dashboards: `<x-dashboard.widget.stat-box>`, `<x-dashboard.widget.fee-summary>`.

6. **Cache aggregated data** using `Cache::remember("dashboard.admin.{$tenantId}", 900, fn() => ...)` to avoid repeated cross-module joins on every page load.

7. **Replace the Direct Chat widget** with a real School Notices / Circular summary widget. The Direct Chat is an AdminLTE demo artifact with no backend.

8. **Expose a dedicated API endpoint** for each role's dashboard data to support future mobile app integration.

9. **Consider lazy-loading heavy widgets** (fee charts, attendance trend) via AJAX after initial page paint to improve perceived load performance.

10. **Add a "Setup Progress" checklist** for new tenants whose modules are not yet configured — guide admin to complete onboarding steps in sequence.

11. **Register `sort_order` / widget personalization** in a future `sys_user_preferences` table so admins can pin/reorder dashboard widgets.

---

## 15. APPENDICES

### 15.1 Current Route-to-View Mapping

| Route | Controller Method | View Returned | Correct? |
|---|---|---|---|
| `GET /dashboard` | `index()` | `backend.v1.dashboard.index` | No — should be `dashboard::index` |
| `GET /dashboard/core-configuration` | `coreConfiguration()` | `dashboard::core-configuration.dashboard` | Yes |
| `GET /dashboard/foundational-setup` | `foundationSetup()` | `dashboard::foundational-setup.dashboard` | Yes |
| `GET /dashboard/admission-student-management` | `admissionStudentManagement()` | `dashboard::admission-student-management.dashboard` | Yes |
| `GET /dashboard/school-setup` | `schoolSetup()` | `dashboard::school-setup.dashboard` | Yes |
| `GET /dashboard/operation-management` | `operationManagement()` | `dashboard::operation-management.dashboard` | Yes |
| `GET /dashboard/support-management` | `supportManagement()` | `dashboard::support-management.dashboard` | Yes |

### 15.2 Priority Implementation Order

1. Fix wrong view path in `index()` method
2. Add authorization to all controller methods
3. Implement `DashboardService` with admin KPIs
4. Build admin dashboard with real data (replace static AdminLTE demo content)
5. Implement role-based view dispatch
6. Build teacher, student, parent dashboards
7. Implement sub-domain dashboards with relevant widgets
8. Add caching layer
9. Write test cases
