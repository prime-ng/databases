# DSH — Dashboard
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL
**Module Code:** DSH | **Scope:** Tenant | **Table Prefix:** None (stateless aggregator)
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x | **Module Path:** `Modules/Dashboard`

---

## 1. Executive Summary

The Dashboard module is the primary landing screen for every authenticated user in the Prime-AI tenant application. It is a cross-module read aggregator — it owns no tables but queries data from every functional module to produce role-specific KPI dashboards for School Admins, Teachers, Students, Parents, Accountants, Transport Managers, Librarians, and Hostel Wardens.

**Current state (V1 audit):** The module is approximately 35% complete. Routing scaffolding and view stubs exist, but all dashboard views display static AdminLTE demo content ("New Orders", "Bounce Rate", "User Registrations") with zero real school data. There is zero authorization on all seven controller methods — any authenticated user can access any sub-dashboard regardless of role. The main `index()` method returns a wrong view path (`backend.v1.dashboard.index`) while all other methods correctly use the module-namespaced path.

**V2 objective:** Define the complete role-based dashboard system including DashboardService architecture, per-role widget inventory, caching strategy (Redis + Laravel Cache), Gate-based widget visibility, AJAX lazy-loading for heavy charts, mobile-responsive layout, and full API surface for mobile app support.

### 1.1 V1 Critical Bugs (Must Fix Before Any Feature Work)

| Bug ID | File | Issue | Fix |
|--------|------|--------|-----|
| BUG-001 | `DashboardController.php:11` | `index()` returns `backend.v1.dashboard.index` (non-module path) | Change to `dashboard::index` |
| BUG-002 | `DashboardController.php` | ZERO `Gate::authorize` calls on all 7 methods | Add `$this->authorize()` to each method |
| BUG-003 | All sub-dashboard views | Byte-for-byte AdminLTE demo content — "New Orders", "Bounce Rate", "Direct Chat" hardcoded | Replace with school-domain widgets |
| BUG-004 | `routes/tenant.php:544` | Duplicate `dashboard` named route inside global-master prefix (uses `SystemConfigController`) | Remove or rename the conflicting route |
| BUG-005 | `routes/web.php` | Dashboard routes also declared under central domain using `PrimeController` | Consolidate; central domain does not serve tenant dashboards |

### 1.2 Module Scorecard (Current vs Target)

| Area | Current Score | V2 Target |
|------|--------------|-----------|
| Route Integrity | 6/10 | 9/10 |
| Controller Quality | 3/10 | 9/10 |
| Security / Authorization | 1/10 | 10/10 |
| Dynamic Data | 0/10 | 9/10 |
| Performance / Caching | 7/10 (no queries = fast) | 8/10 (cached queries) |
| Test Coverage | 0/10 | 7/10 |
| Architecture | 4/10 | 9/10 |
| **Overall** | **3.4/10** | **8.7/10** |

---

## 2. Module Overview

### 2.1 Role-Based Dashboard Variants

The dashboard must detect the authenticated user's primary role and render the appropriate view with role-scoped data. Nine distinct dashboard variants are required:

| Variant | Primary Role | Key Concern |
|---------|-------------|-------------|
| School Admin | `school-admin` | School-wide operational health, finance, HR |
| Principal | `principal` | Academic performance, staff, exam overview |
| Class Teacher | `class-teacher` | Class attendance, homework, today's timetable |
| Subject Teacher | `subject-teacher` | Subject-wise quiz/exam queue, homework grading |
| Student | `student` | Personal timetable, assignments, fee dues, scores |
| Parent | `parent` | Child's attendance, fees, communications, multi-child |
| Accountant | `accountant` | Fee collection, pending dues, invoices |
| Transport Manager | `transport-manager` | Active routes, vehicle status, student allocation |
| Librarian | `librarian` | Issued books, overdue returns, stock alerts |
| Hostel Warden | `hostel-warden` | Room occupancy, attendance, mess dues |

**Resolution logic** (in priority order):
1. Tenant Super Admin → School Admin view
2. `hasRole('principal')` → Principal view
3. `hasRole('accountant')` → Accountant view
4. `hasRole('transport-manager')` → Transport view
5. `hasRole('librarian')` → Librarian view
6. `hasRole('hostel-warden')` → Hostel Warden view
7. `hasRole('teacher')` → Teacher view (class or subject based on assignment)
8. `hasRole('student')` → Student view
9. `hasRole('parent')` → Parent view
10. Default fallback → Generic info page with "Contact admin" guidance

### 2.2 Sub-Domain Dashboards (Domain-Specific Drill-Downs)

In addition to role dashboards, six sub-domain drill-down dashboards provide functional area summaries for admin-level users:

| Route | Domain | Intended Audience |
|-------|--------|------------------|
| `/dashboard/core-configuration` | System/module setup status | School Admin, IT Manager |
| `/dashboard/foundational-setup` | Infrastructure & class setup | School Admin, Principal |
| `/dashboard/admission-student-management` | Admissions pipeline & student data | Admissions Officer, Principal |
| `/dashboard/school-setup` | Staff, departments, profile completeness | School Admin |
| `/dashboard/operation-management` | Timetable, exams, transport | Operations Manager |
| `/dashboard/support-management` | Complaints, library, HPC | Support Staff, Admin |

### 2.3 Architecture Overview

```
Request → DashboardController
             │
             ├─ resolveUserRole() → role string
             │
             ├─ DashboardService::getDataForRole($user, $role)
             │       │
             │       ├─ Cache::remember("dash.{role}.{userId}.{today}", 900, fn)
             │       │
             │       └─ WidgetDataRepository queries:
             │              AttendanceRepository, FeeRepository,
             │              ExamRepository, TimetableRepository,
             │              NotificationRepository, HomeworkRepository
             │
             └─ return view("dashboard::{role}.index", compact('data'))
```

**Key architectural components to create:**
- `Modules/Dashboard/app/Services/DashboardService.php` — role dispatcher + cache manager
- `Modules/Dashboard/app/Repositories/WidgetDataRepository.php` — all DB queries
- `Modules/Dashboard/app/Policies/DashboardPolicy.php` — per-section gates
- `Modules/Dashboard/app/Http/Controllers/DashboardApiController.php` — JSON API for mobile
- `Modules/Dashboard/resources/views/{role}/index.blade.php` — one view per role
- `Modules/Dashboard/resources/views/components/widgets/` — reusable Blade components

---

## 3. Stakeholders & Roles

| Actor | Role Code | Dashboard Needs | Data Sensitivity |
|-------|-----------|-----------------|-----------------|
| School Admin / IT Admin | `school-admin` | All KPIs, finance, staff, student count, system health | High — sees financials |
| Principal | `principal` | Academic performance, exam results, attendance trends | High |
| Class Teacher | `class-teacher` | Today's timetable, attendance status, homework queue | Medium |
| Subject Teacher | `subject-teacher` | Quiz/exam grading queue, subject homework | Medium |
| Student | `student` | Personal schedule, grades, fee dues, notifications | Medium — own data only |
| Parent | `parent` | Child's academics, fee dues, school communications | Medium — child's data only |
| Accountant | `accountant` | Fee KPIs, collection summary, pending invoices | High — full fee data |
| Transport Manager | `transport-manager` | Route status, vehicle tracking, student allocations | Medium |
| Librarian | `librarian` | Book circulation, overdue, catalog status | Low |
| Hostel Warden | `hostel-warden` | Room allocation, night attendance, mess dues | Medium |
| Prime Admin (SaaS) | N/A | Handled in `prime_db` — out of tenant scope | N/A |

---

## 4. Functional Requirements

### FR-DSH-01: Role-Based Dashboard View Dispatch
**Status:** ❌ Not Started
**Priority:** P0 — Critical

The `DashboardController@index` method must detect the authenticated user's primary role and return the role-appropriate view with injected data. A single generic static view for all roles is not acceptable.

**Acceptance criteria:**
- School Admin sees financial KPIs, student count, staff count, pending approvals
- Teacher sees today's timetable, attendance pending count, homework grading queue
- Student sees personal timetable, pending assignments, recent scores, fee dues
- Parent sees child's attendance %, fee dues, recent communications
- Unauthenticated request redirects to login (302)
- User with no matching role sees a safe fallback "Contact Administrator" page

### FR-DSH-02: School Admin KPI Widgets
**Status:** ❌ Not Started
**Priority:** P0

| Widget ID | Widget Name | Data Source | Update Frequency |
|-----------|-------------|-------------|-----------------|
| W-ADM-01 | Total Enrolled Students | `std_students` (current `sch_org_academic_sessions_jnt`) | Daily cache |
| W-ADM-02 | Today's Student Attendance % | `std_student_attendance` WHERE `date = today` | 30-min cache |
| W-ADM-03 | Today's Staff Attendance | `std_student_attendance` (staff type) or `sch_employees` + leave | 30-min cache |
| W-ADM-04 | Fee Collected This Month | `fee_transactions` WHERE `created_at` in current month | 15-min cache |
| W-ADM-05 | Total Fee Pending | `fee_invoices` WHERE `status != paid`, sum `balance_amount` | 15-min cache |
| W-ADM-06 | Upcoming Exams (7 days) | `lms_exams` WHERE `exam_date BETWEEN today AND today+7` | 1-hour cache |
| W-ADM-07 | Unread Notifications Count | `ntf_notifications` WHERE `user_id = auth()->id()` AND `read_at IS NULL` | Real-time (no cache) |
| W-ADM-08 | Pending Complaints (Open) | `cmp_complaints` WHERE `status = 'open'` | 30-min cache |
| W-ADM-09 | Monthly Attendance Trend Chart | `std_student_attendance` aggregate by day, current month | Daily cache |
| W-ADM-10 | Fee Collection Trend Chart | `fee_transactions` aggregate by week, current term | Daily cache |
| W-ADM-11 | Class-wise Student Strength | `std_student_academic_sessions` JOIN `sch_classes` | Daily cache |
| W-ADM-12 | Recent Activity Feed | `sys_activity_logs` LIMIT 10 ORDER BY `created_at DESC` | No cache |
| W-ADM-13 | Quick Actions Bar | Navigation links: Mark Attendance, Add Student, Create Exam | Static |
| W-ADM-14 | School Setup Completion % | Count completed config entities vs expected total | Daily cache |

### FR-DSH-03: Principal Dashboard KPI Widgets
**Status:** ❌ Not Started
**Priority:** P1

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-PRI-01 | School-wide Attendance Today | `std_student_attendance` aggregated |
| W-PRI-02 | Academic Performance Summary | `lms_student_attempts` latest exam average by class |
| W-PRI-03 | Upcoming Exams | `lms_exams` next 14 days |
| W-PRI-04 | Staff Present Today | `sch_employees` cross `sch_leave_config` |
| W-PRI-05 | Pending Approvals | Leave requests, complaints escalated |
| W-PRI-06 | Notice Board | Latest `ntf_notifications` school-wide (type = announcement) |

### FR-DSH-04: Teacher Dashboard KPI Widgets
**Status:** ❌ Not Started
**Priority:** P0

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-TCH-01 | Today's Timetable | `tt_timetable_cells` JOIN periods for teacher's `sch_employees.id` |
| W-TCH-02 | Attendance Pending Today | Periods today where `std_student_attendance` not yet marked |
| W-TCH-03 | Homework Grading Queue | `lms_homework_submissions` WHERE `graded = false` for teacher's classes |
| W-TCH-04 | Upcoming Exams (My Subjects) | `lms_exams` JOIN `lms_exam_scopes` for teacher's subjects |
| W-TCH-05 | Unread Notifications | `ntf_notifications` unread for teacher |
| W-TCH-06 | Quick Actions | Mark Attendance (link), Grade Homework, View Schedule |

### FR-DSH-05: Student Dashboard KPI Widgets
**Status:** ❌ Not Started
**Priority:** P0

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-STD-01 | Today's Timetable | `tt_timetable_cells` for student's `sch_class_section_jnt` |
| W-STD-02 | This Month's Attendance % | `std_student_attendance` WHERE `student_id = auth_student`, current month |
| W-STD-03 | Pending Homework | `lms_homework` WHERE due_date >= today, class/section match |
| W-STD-04 | Recent Exam Scores | `lms_student_attempts` latest 5 for student |
| W-STD-05 | Upcoming Exams | `lms_exams` + `lms_exam_allocations` for student's group |
| W-STD-06 | Fee Due Amount | `fee_invoices` WHERE student_id = student, status != 'paid' |
| W-STD-07 | School Announcements | `ntf_notifications` WHERE type = 'announcement' LIMIT 5 |

### FR-DSH-06: Parent Dashboard KPI Widgets
**Status:** ❌ Not Started
**Priority:** P1

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-PAR-01 | Child Selector | `std_student_guardian_jnt` WHERE guardian_id = auth parent; dropdown if multiple |
| W-PAR-02 | Child's Attendance This Month | `std_student_attendance` for selected child |
| W-PAR-03 | Child's Recent Exam Results | `lms_student_attempts` for selected child |
| W-PAR-04 | Child's Fee Dues | `fee_invoices` for selected child |
| W-PAR-05 | School Communications | `ntf_notifications` targeted at parent/guardian |
| W-PAR-06 | Upcoming Events | School-wide announcements and exam schedule |

### FR-DSH-07: Accountant Dashboard KPI Widgets
**Status:** ❌ Not Started
**Priority:** P1

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-ACC-01 | Total Fee Collected Today | `fee_transactions` WHERE `DATE(created_at) = today` |
| W-ACC-02 | Total Fee Collected This Month | `fee_transactions` monthly aggregate |
| W-ACC-03 | Total Outstanding Dues | `fee_invoices` WHERE `status != 'paid'` SUM `balance_amount` |
| W-ACC-04 | Defaulters Count | Students with overdue `fee_installments` |
| W-ACC-05 | Fee Collection Trend | Weekly bar chart from `fee_transactions` |
| W-ACC-06 | Recent Transactions | `fee_transactions` LIMIT 10 latest |
| W-ACC-07 | Quick Actions | Generate Invoice, Record Payment, View Defaulters |

### FR-DSH-08: Transport Manager Dashboard
**Status:** ❌ Not Started (VendorDashboardController exists as a reference pattern)
**Priority:** P2

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-TPT-01 | Active Routes Today | `tpt_route` WHERE `is_active = 1` |
| W-TPT-02 | Students Allocated | `tpt_student_route_allocation_jnt` COUNT |
| W-TPT-03 | Driver Attendance Today | `tpt_driver_attendance` WHERE `date = today` |
| W-TPT-04 | Vehicle Status | `tpt_vehicle` active vs maintenance |
| W-TPT-05 | Recent Trip Logs | `tpt_trip` + `tpt_trip_stop_detail` latest |

### FR-DSH-09: Librarian Dashboard
**Status:** ❌ Not Started
**Priority:** P2

| Widget ID | Widget Name | Data Source |
|-----------|-------------|-------------|
| W-LIB-01 | Books Issued Today | `lib_*` issue tables WHERE `issue_date = today` |
| W-LIB-02 | Overdue Returns | `lib_*` WHERE `due_date < today` AND `returned = false` |
| W-LIB-03 | Total Books in Stock | `lib_*` catalog table |
| W-LIB-04 | Recent Transactions | Issue/return log |

### FR-DSH-10: Sub-Domain Dashboards (Core Config, Foundational, etc.)
**Status:** 🟡 Routes exist; views are static AdminLTE demo clones
**Priority:** P1

Each sub-domain dashboard must show functional-area KPIs, not generic placeholders. All 6 must be protected by role-based authorization — only school admin and above can access these.

| Sub-Domain | Required Widgets |
|------------|-----------------|
| Core Configuration | Active academic session, current term dates, board/medium setup status, subjects configured count, active modules list |
| Foundational Setup | Buildings count, rooms count, classes configured, sections configured, timetable generated status |
| Admission & Student Mgmt | New admissions this month, total active students, class-wise strength chart, pending admission enquiries |
| School Setup | School profile completion %, active staff count, department count, designation count |
| Operation Management | Timetable generated (Y/N + coverage %), active exam schedules, transport routes operating, library books issued today |
| Support Management | Open complaints count by severity, pending vendor POs, overdue library books, recent activity log |

### FR-DSH-11: Quick Action Shortcuts
**Status:** ❌ Not Started
**Priority:** P1

Each role dashboard must include a Quick Actions section rendering role-relevant shortcut links. Links must only render if `Gate::check` passes for the target module permission.

| Role | Quick Actions |
|------|--------------|
| School Admin | Add Student, Mark Attendance, Create Exam, View Reports, Add Staff |
| Teacher | Mark Attendance, Grade Homework, View Timetable, Create Quiz |
| Student | View Timetable, Submit Assignment, Pay Fee (link to portal), View Results |
| Parent | View Child's Attendance, Pay Fee, Contact Teacher, Download Report Card |
| Accountant | Record Payment, Generate Invoice, View Defaulters |

### FR-DSH-12: Notification Feed Widget
**Status:** ❌ Not Started
**Priority:** P0

- Display last 5 unread notifications from `ntf_notifications` for `auth()->id()`
- Show unread count badge in widget header
- "Mark all read" action triggers `ntf_notifications` bulk update via AJAX
- "View all" link → `/dashboard/all-notifications` (route already registered)
- Poll or Server-Sent Events for real-time badge update (see NFR-DSH-05)

### FR-DSH-13: Configurable Widget Layout (Personalization)
**Status:** 📐 Proposed (New in V2)
**Priority:** P3 — Future enhancement

- Store widget visibility preferences in `sys_settings` with key pattern `dashboard.widgets.{role}.{userId}`
- Admin can toggle widget visibility via a "Customize Dashboard" modal
- Drag-and-drop reorder via SortableJS (persist order in same settings store)
- Default layout defined in `config/dashboard.php` per role
- Per-school customization (school admin overrides default layout for all teachers)

### FR-DSH-14: Onboarding Setup Checklist (New Tenant)
**Status:** 📐 Proposed (New in V2)
**Priority:** P2

- When a new tenant has < 5 entities configured, show a "Setup Checklist" banner at the top of admin dashboard
- Checklist items: Academic Session, Board/Medium, Classes, Subjects, Staff, Students
- Each item shows completion status and links to the configuration screen
- Dismissed once all items are complete or admin manually dismisses
- Persistence: `sys_settings` key `dashboard.setup_checklist.dismissed`

---

## 5. Data Model

### 5.1 Dashboard Tables

The Dashboard module has no dedicated database tables. It is a stateless read aggregator. All data is read from other module tables using optimized queries with Redis caching.

**Optional future table (Phase 2):**
```sql
-- dash_widget_preferences (not in current DDL — proposed for Phase 2)
-- Stores per-user widget layout preferences
-- Can be deferred in favor of sys_settings JSON approach (Phase 1)
```

**Phase 1 alternative (use existing `sys_settings` table):**
```
sys_settings.key   = 'dashboard.layout.{role}.{userId}'
sys_settings.value = JSON array of widget order/visibility
```

### 5.2 Cross-Module Data Sources (Corrected Table Names)

V1 used assumed table names. Below are the verified actual table names from `tenant_db_v2.sql`:

| Widget Area | Actual Table Name(s) | Key Columns |
|-------------|---------------------|-------------|
| Students enrolled | `std_students`, `std_student_academic_sessions` | `academic_session_id`, `is_active` |
| Student profiles | `std_student_profiles` | `student_id`, `class_id`, `section_id` |
| Student attendance | `std_student_attendance` | `student_id`, `date`, `status` |
| Attendance corrections | `std_attendance_corrections` | `student_id`, `original_date` |
| Fee collection | `fee_transactions` | `amount`, `created_at`, `status` |
| Fee invoices / dues | `fee_invoices` | `student_id`, `balance_amount`, `status` |
| Fee installments | `fee_installments` | `due_date`, `paid_amount` |
| Fee receipts | `fee_receipts` | `transaction_id`, `receipt_no` |
| Exams | `lms_exams` | `exam_date`, `status`, `title` |
| Exam allocations | `lms_exam_allocations` | `student_group_id`, `exam_id` |
| Student exam attempts | `lms_student_attempts` | `student_id`, `exam_id`, `score` |
| Homework | `lms_homework` | `class_id`, `due_date`, `subject_id` |
| Homework submissions | `lms_homework_submissions` | `student_id`, `graded`, `submitted_at` |
| Notifications | `ntf_notifications` | `user_id`, `read_at`, `type`, `data` |
| Complaints | `cmp_complaints` | `status`, `severity`, `created_at` |
| Timetable cells | `tt_timetable_cells` (SmartTimetable) | `class_id`, `section_id`, `day_id`, `period_id` |
| Teachers | `sch_employees`, `sch_teacher_profile` | `user_id`, `employee_type` |
| Academic sessions | `sch_org_academic_sessions_jnt` | `organization_id`, `is_active` |
| Classes | `sch_classes`, `sch_class_section_jnt` | `class_id`, `section_id` |
| Transport routes | `tpt_route` | `is_active`, `route_name` |
| Driver attendance | `tpt_driver_attendance` | `driver_id`, `date`, `status` |
| Student route allocation | `tpt_student_route_allocation_jnt` | `student_id`, `route_id` |
| Activity logs | `sys_activity_logs` (via Spatie) | `log_name`, `created_at`, `causer_id` |
| Guardians | `std_guardians`, `std_student_guardian_jnt` | `user_id`, `student_id` |

### 5.3 Caching Strategy

```
Cache Key Pattern:  dash.{role}.{tenantId}.{userId}.{date}
Cache Driver:       Redis (preferred) / Database (fallback)
TTL by widget:
  - Student/staff counts:     86400s (daily)
  - Attendance %:             1800s  (30 min)
  - Fee KPIs:                 900s   (15 min)
  - Exam schedule:            3600s  (1 hour)
  - Timetable today:          3600s  (1 hour)
  - Notifications unread:     0      (no cache — live query)
  - Activity log:             0      (no cache — live query)
  - Charts (trend data):      86400s (daily)

Cache Invalidation Events (via Model Observer or Event Listener):
  - StudentEnrolled            → invalidate dash.admin.*
  - AttendanceMarked           → invalidate dash.admin.*, dash.teacher.{teacherId}.*
  - FeePaymentRecorded         → invalidate dash.admin.*, dash.accountant.*
  - HomeworkSubmitted          → invalidate dash.teacher.{teacherId}.*
  - ComplaintCreated           → invalidate dash.admin.*
```

---

## 6. API Endpoints & Routes

### 6.1 Existing Web Routes (Tenant — All Under `auth`, `verified` Middleware)

| # | Method | URI | Controller Method | Route Name | Auth Status | V2 Status |
|---|--------|-----|------------------|------------|-------------|-----------|
| 1 | GET | `/dashboard` | `DashboardController@index` | `dashboard` | auth+verified | ❌ Fix view path + add Gate |
| 2 | GET | `/dashboard/core-configuration` | `DashboardController@coreConfiguration` | `dashboard.core-configuration` | auth+verified | ❌ Add Gate + real data |
| 3 | GET | `/dashboard/foundational-setup` | `DashboardController@foundationSetup` | `dashboard.foundational-setup` | auth+verified | ❌ Add Gate + real data |
| 4 | GET | `/dashboard/admission-student-management` | `DashboardController@admissionStudentManagement` | `dashboard.admission-student-management` | auth+verified | ❌ Add Gate + real data |
| 5 | GET | `/dashboard/school-setup` | `DashboardController@schoolSetup` | `dashboard.school-setup` | auth+verified | ❌ Add Gate + real data |
| 6 | GET | `/dashboard/operation-management` | `DashboardController@operationManagement` | `dashboard.operationManagement` | auth+verified | ❌ Add Gate + real data |
| 7 | GET | `/dashboard/support-management` | `DashboardController@supportManagement` | `dashboard.support-management` | auth+verified | ❌ Add Gate + real data |
| 8 | GET | `/dashboard/all-notifications` | `NotificationController@allNotifications` | `dashboard.all-notifications` | auth+verified | 🟡 Check implementation |

### 6.2 New Web Routes Required (V2)

| # | Method | URI | Controller | Purpose |
|---|--------|-----|-----------|---------|
| 9 | GET | `/dashboard/notifications/mark-all-read` | `DashboardController@markAllRead` | Mark all notifications read via AJAX |
| 10 | GET | `/dashboard/widgets/{widget}/refresh` | `DashboardController@refreshWidget` | AJAX lazy-load individual widget data |
| 11 | POST | `/dashboard/preferences` | `DashboardController@savePreferences` | Save widget layout preferences |

### 6.3 New API Endpoints Required (V2) — Mobile App Support

| # | Method | URI | Auth | Response |
|---|--------|-----|------|----------|
| 1 | GET | `/api/v1/dashboard` | `auth:sanctum` | Role-dispatched KPI data (JSON) |
| 2 | GET | `/api/v1/dashboard/admin` | `auth:sanctum` | Admin KPI widgets (JSON) |
| 3 | GET | `/api/v1/dashboard/teacher` | `auth:sanctum` | Teacher daily data (JSON) |
| 4 | GET | `/api/v1/dashboard/student` | `auth:sanctum` | Student personal data (JSON) |
| 5 | GET | `/api/v1/dashboard/parent` | `auth:sanctum` | Parent child-centric data (JSON) |
| 6 | GET | `/api/v1/dashboard/notifications` | `auth:sanctum` | Unread notifications list |
| 7 | POST | `/api/v1/dashboard/notifications/read` | `auth:sanctum` | Mark notification(s) as read |
| 8 | GET | `/api/v1/dashboard/widgets/{widget}` | `auth:sanctum` | Single widget data refresh |

**Standard JSON response envelope:**
```json
{
  "success": true,
  "role": "school-admin",
  "cached_at": "2026-03-26T10:00:00Z",
  "data": { ... }
}
```

### 6.4 Route Conflict to Resolve

`routes/tenant.php:544` registers `Route::get('dashboard', [SystemConfigController::class, 'index'])->name('dashboard')` inside the `global-master` prefix group. This conflicts with the main dashboard route at line 315. The route inside the global-master group must be renamed (e.g., `system-config.index`) to eliminate the ambiguity.

---

## 7. UI Screens

### 7.1 Screen: School Admin Dashboard
**Route:** `GET /dashboard` (for role `school-admin`)
**View:** `dashboard::admin.index`

**Layout (Bootstrap 5 / AdminLTE grid):**
```
Row 1: [W-ADM-01 Students] [W-ADM-02 Attendance%] [W-ADM-04 Fee Collected] [W-ADM-05 Fee Pending]
Row 2: [W-ADM-09 Attendance Trend Chart (col-8)] [W-ADM-08 Pending Complaints (col-4)]
Row 3: [W-ADM-10 Fee Collection Trend (col-7)] [W-ADM-12 Recent Activity Feed (col-5)]
Row 4: [W-ADM-06 Upcoming Exams (col-4)] [W-ADM-07 Notifications (col-4)] [W-ADM-13 Quick Actions (col-4)]
Row 5 (new tenant only): [W-ADM-14 Setup Checklist Banner (col-12)]
```

**Widget design pattern (Blade component):**
```blade
<x-dashboard.widget.stat-box
    title="Total Students"
    :value="$data['students_count']"
    icon="fa-users"
    color="primary"
    route="{{ route('student-management.index') }}"
/>
```

### 7.2 Screen: Teacher Dashboard
**Route:** `GET /dashboard` (for role `teacher`)
**View:** `dashboard::teacher.index`

**Layout:**
```
Row 1: [W-TCH-01 Today's Timetable — full width timeline view]
Row 2: [W-TCH-02 Attendance Pending (col-4)] [W-TCH-03 Grading Queue (col-4)] [W-TCH-05 Notifications (col-4)]
Row 3: [W-TCH-04 Upcoming Exams (col-6)] [W-TCH-06 Quick Actions (col-6)]
```

**Today's Timetable Widget:** Horizontal timeline showing periods (e.g., P1 Math-9A, P2 Science-10B) with visual highlight on current period. Periods where attendance not yet marked shown with amber indicator.

### 7.3 Screen: Student Dashboard
**Route:** `GET /dashboard` (for role `student`)
**View:** `dashboard::student.index`

**Layout:**
```
Row 1: [W-STD-02 Attendance% (col-3)] [W-STD-03 Pending HW (col-3)] [W-STD-06 Fee Due (col-3)] [W-STD-07 Announcements (col-3)]
Row 2: [W-STD-01 Today's Timetable — full width]
Row 3: [W-STD-04 Recent Exam Scores (col-6)] [W-STD-05 Upcoming Exams (col-6)]
```

### 7.4 Screen: Parent Dashboard
**Route:** `GET /dashboard` (for role `parent`)
**View:** `dashboard::parent.index`

**Multi-child support:** If parent has multiple children in `std_student_guardian_jnt`, show a child selector tab strip at the top. All widgets below refresh for the selected child (AJAX or page parameter).

**Layout:**
```
Row 0 (multi-child): [Child Selector Tabs]
Row 1: [W-PAR-02 Attendance% (col-3)] [W-PAR-03 Last Exam Score (col-3)] [W-PAR-04 Fee Due (col-3)] [W-PAR-06 Upcoming Events (col-3)]
Row 2: [W-PAR-05 School Communications (col-12)]
```

### 7.5 Screen: Accountant Dashboard
**Route:** `GET /dashboard` (for role `accountant`)
**View:** `dashboard::accountant.index`

**Layout:**
```
Row 1: [W-ACC-01 Collected Today (col-3)] [W-ACC-02 Collected Month (col-3)] [W-ACC-03 Outstanding (col-3)] [W-ACC-04 Defaulters (col-3)]
Row 2: [W-ACC-05 Collection Trend Chart (col-8)] [W-ACC-07 Quick Actions (col-4)]
Row 3: [W-ACC-06 Recent Transactions — full width table]
```

### 7.6 Screen: Core Configuration Sub-Dashboard
**Route:** `GET /dashboard/core-configuration`
**View:** `dashboard::core-configuration.dashboard`
**Authorization:** `school-admin` or `principal` only

**Widgets:**
- Active academic session name + term dates
- Board/medium configured (Yes/No badges)
- Classes configured count vs expected
- Subjects configured count
- Active modules list (licensed modules)
- System health indicators (DB, cache, queue status)

### 7.7 Sub-Dashboard Screens (Foundational, Admission, School Setup, Operations, Support)

Each follows the same pattern: role-gated, data driven from respective module tables, uses `<x-dashboard.widget.stat-box>` components. Refer to FR-DSH-10 for widget inventory per sub-domain.

---

## 8. Business Rules

| ID | Rule |
|----|------|
| BR-DSH-01 | Dashboard data must always be scoped to the current tenant (`tenant_id` context via stancl/tenancy). Cross-tenant data must never appear. |
| BR-DSH-02 | All KPI widgets must reflect the **current active academic session** (`sch_org_academic_sessions_jnt` WHERE `is_active = 1`). If no active session exists, widgets display "No Active Session" empty state — not zero or error. |
| BR-DSH-03 | Role dispatch uses the user's **primary role** (highest privilege role in the RBAC stack). A user with both `teacher` and `class-teacher` roles gets the class-teacher view. |
| BR-DSH-04 | Financial widgets (fee collected, outstanding dues) are visible only to `school-admin`, `principal`, and `accountant` roles. Teachers, students, and parents see only their own relevant fee data. |
| BR-DSH-05 | Attendance % widget computes only from records where `std_student_attendance.status` is explicitly set. It does not infer "present" from absence of a record. |
| BR-DSH-06 | Fee amounts must be displayed in INR with Indian number formatting (e.g., ₹1,25,000 not ₹125,000). |
| BR-DSH-07 | Quick-action links must be rendered conditionally: `@can('prime.{module}.{action}')` Blade directive must wrap every action link. Links for modules the user has no permission to access must not render at all. |
| BR-DSH-08 | For Parent dashboard, if a guardian has multiple children in `std_student_guardian_jnt`, the system defaults to the first child (by enrollment date) and provides a child-selector UI. |
| BR-DSH-09 | Dashboard cache keys must include `tenantId` to prevent cross-tenant cache collision in shared Redis environments: key = `dash.{role}.{tenantId}.{userId}.{Y-m-d}`. |
| BR-DSH-10 | Sub-domain dashboards (`/dashboard/core-configuration` etc.) are accessible only to users with the `prime.dashboard.view-admin-sections` permission. Students and Parents must receive 403 on access attempts. |
| BR-DSH-11 | The "New Tenant Onboarding Checklist" banner is shown when: the school has fewer than 3 classes configured AND the setup checklist has not been dismissed in `sys_settings`. |
| BR-DSH-12 | All chart data (attendance trend, fee trend) must include zero-value days in the dataset — do not skip days with no records. This prevents misleading gap lines in trend charts. |

---

## 9. Workflows

### 9.1 Dashboard Page Load Workflow

```
1. User hits GET /dashboard (authenticated, verified)
2. DashboardController@index fires
3. Gate::authorize('prime.dashboard.view') — 403 if fails
4. $role = resolveUserRole(auth()->user())
5. $data = DashboardService::getDataForRole($user, $role)
   ├─ Check Cache::get("dash.{role}.{tenantId}.{userId}.{today}")
   ├─ Cache HIT → return cached array
   └─ Cache MISS:
       ├─ Call role-specific repository methods (DB queries)
       ├─ Transform to widget-ready arrays
       └─ Cache::put(key, data, ttl)
6. return view("dashboard::{role}.index", compact('data'))
7. Blade renders static widgets immediately
8. JavaScript initiates AJAX calls for heavy/real-time widgets:
   ├─ /dashboard/widgets/notifications → unread count badge
   ├─ /dashboard/widgets/attendance-trend → Chart.js data
   └─ /dashboard/widgets/fee-trend → Chart.js data
```

### 9.2 Cache Invalidation Workflow

```
Module event fires (e.g., AttendanceMarked)
   ↓
Dashboard Event Listener (DashboardCacheInvalidationListener)
   ↓
Determine affected cache keys:
   - AttendanceMarked → ['dash.admin.*', 'dash.teacher.{id}.*']
   - FeePaymentRecorded → ['dash.admin.*', 'dash.accountant.*']
   - ComplaintCreated → ['dash.admin.*']
   ↓
Cache::tags(['dashboard', 'attendance'])->flush()
  (uses Redis tag-based invalidation)
  OR
Cache::forget("dash.admin.{tenantId}.*") for non-Redis driver
```

### 9.3 Parent Child-Switch Workflow

```
1. Parent opens /dashboard
2. DashboardService queries std_student_guardian_jnt → finds 2 children
3. Child selector tabs rendered with child names
4. Parent clicks second child tab
5. AJAX GET /dashboard/widgets/student-data?child_id={id}
6. DashboardController@refreshWidget validates child belongs to parent
7. Returns widget HTML partial for second child
8. JavaScript swaps widget content in DOM
```

### 9.4 Notification Mark-Read Workflow

```
1. User clicks "Mark all read" in notification widget
2. AJAX POST /dashboard/notifications/mark-all-read (CSRF token included)
3. DashboardController calls NotificationService::markAllRead(auth()->id())
4. Updates ntf_notifications SET read_at = NOW() WHERE user_id = ?
5. Returns JSON { success: true, unread_count: 0 }
6. Frontend updates badge to 0
```

---

## 10. Non-Functional Requirements

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-DSH-01 | Performance | Dashboard page must achieve Time-to-First-Byte < 500ms and full load < 2000ms. Achieved via Redis caching for aggregated KPIs and lazy-loaded charts. |
| NFR-DSH-02 | Security | All 7 web routes and all API endpoints must be protected by both authentication middleware (`auth`, `verified`) AND explicit `Gate::authorize` calls inside the controller. |
| NFR-DSH-03 | Security — Data Isolation | No dashboard route may ever return data from a different tenant. Tenant context provided by stancl/tenancy must be active before any query executes. |
| NFR-DSH-04 | Security — CSRF | All AJAX POST/PATCH calls from dashboard (mark-read, save-preferences) must include the Laravel CSRF token in the `X-CSRF-TOKEN` header. |
| NFR-DSH-05 | Real-time Notifications | Unread notification badge should update within 30 seconds of a new notification arriving. Implementation options (in preference order): Laravel Echo + Pusher/Soketi, SSE polling every 30s, or simple JS polling every 30s with `/api/v1/dashboard/notifications`. |
| NFR-DSH-06 | Scalability | Widget queries must use database indexes. Key required indexes: `std_student_attendance(date, status)`, `fee_transactions(created_at)`, `ntf_notifications(user_id, read_at)`. Avoid N+1 — use `DB::select()` aggregate queries, not Eloquent collection loops. |
| NFR-DSH-07 | Mobile Responsiveness | Dashboard must render correctly on 375px–1920px viewports. Each widget card stacks vertically on mobile. Charts must resize responsively via Chart.js `maintainAspectRatio: false`. |
| NFR-DSH-08 | Accessibility | Widget stat-boxes must include `aria-label` attributes. Color is not the only indicator (e.g., overdue fee box must also have text, not just red color). |
| NFR-DSH-09 | Testability | `DashboardService` must be injectable via constructor. All DB queries must go through `WidgetDataRepository` which can be mocked in tests. Controller must accept injected service, not call `new DashboardService()` directly. |
| NFR-DSH-10 | Cache Resilience | If Redis is unavailable, dashboard must degrade gracefully — run live DB queries without caching (add `try/catch` around cache calls). Never show a 500 error to the user due to cache failure. |
| NFR-DSH-11 | Empty State Handling | Every widget must define an explicit empty state: no data = message card, not zero or blank. Example: "No attendance marked today" rather than "0%". |

---

## 11. Cross-Module Dependencies

| Module Code | Module Name | Dependency Type | Dashboard Usage |
|-------------|-------------|-----------------|-----------------|
| SYS | System Config | Read | `sys_permissions`, `sys_roles`, `sys_settings` — user roles, widget preferences |
| SCH | School Setup | Read | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_sections`, `sch_employees`, `sch_buildings`, `sch_rooms` |
| STD | Student Management | Read | `std_students`, `std_student_profiles`, `std_student_academic_sessions`, `std_student_attendance`, `std_guardians`, `std_student_guardian_jnt` |
| FIN | Student Fee Mgmt | Read | `fee_transactions`, `fee_invoices`, `fee_installments`, `fee_receipts` |
| LMS-EXM | LMS Exam | Read | `lms_exams`, `lms_exam_allocations`, `lms_student_attempts`, `lms_exam_scopes` |
| LMS-HW | LMS Homework | Read | `lms_homework`, `lms_homework_submissions` |
| LMS-QUZ | LMS Quiz | Read | `lms_quizzes`, `lms_quiz_allocations`, `lms_quiz_quest_attempts` |
| TT | Smart Timetable | Read | `tt_timetable_cells` — today's schedule for teacher/student |
| NTF | Notifications | Read+Write | `ntf_notifications` — unread feed; mark-read writes back |
| CMP | Complaints | Read | `cmp_complaints` — open count for admin |
| LIB | Library | Read | `lib_*` tables — issued/overdue counts |
| TPT | Transport | Read | `tpt_route`, `tpt_driver_attendance`, `tpt_student_route_allocation_jnt` |
| VND | Vendor | None | VendorDashboardController exists independently; not aggregated into main dashboard |
| HPC | HPC | Read | HPC pending count for admin (optional widget) |

**Dependency Risk:** Dashboard has the broadest read dependency footprint of any module. If any source module's schema changes (table rename, column rename), the `WidgetDataRepository` queries must be updated. V2 implementation must use named constants or Repository methods — never inline raw table names in controller.

---

## 12. Test Scenarios

### 12.1 Feature Tests

| ID | Scenario | Expected Outcome |
|----|----------|-----------------|
| TC-DSH-01 | Unauthenticated GET `/dashboard` | 302 redirect to `/login` |
| TC-DSH-02 | Authenticated school-admin GET `/dashboard` | 200, view `dashboard::admin.index`, contains `students_count` key in view data |
| TC-DSH-03 | Authenticated teacher GET `/dashboard` | 200, view `dashboard::teacher.index`, contains `todays_timetable` key |
| TC-DSH-04 | Authenticated student GET `/dashboard` | 200, view `dashboard::student.index`, contains `attendance_percent`, `fee_due` |
| TC-DSH-05 | Authenticated parent (single child) GET `/dashboard` | 200, view `dashboard::parent.index`, contains child's data, no child-selector tabs |
| TC-DSH-06 | Authenticated parent (two children) GET `/dashboard` | 200, child-selector tabs visible with both children's names |
| TC-DSH-07 | Student GET `/dashboard/core-configuration` | 403 Forbidden (student has no admin permission) |
| TC-DSH-08 | Admin GET `/dashboard/core-configuration` | 200, contains academic session widget data |
| TC-DSH-09 | Admin dashboard with no active academic session | 200, widgets show "No Active Session" message, no errors thrown |
| TC-DSH-10 | New tenant (0 classes configured) GET `/dashboard` | 200, setup checklist banner visible |
| TC-DSH-11 | AJAX GET `/dashboard/widgets/notifications` | JSON response, contains `unread_count` and `notifications` array |
| TC-DSH-12 | POST `/dashboard/notifications/mark-all-read` without CSRF | 419 CSRF token mismatch |
| TC-DSH-13 | Accountant GET `/dashboard` | 200, view `dashboard::accountant.index`, `fee_collected_today` visible |
| TC-DSH-14 | Admin dashboard data is cached on second request | Second DB query count = 0 (cache hit); first = N queries |
| TC-DSH-15 | API GET `/api/v1/dashboard` without Sanctum token | 401 Unauthorized |
| TC-DSH-16 | API GET `/api/v1/dashboard` with valid Sanctum token | 200, JSON with `role`, `data`, `success: true` |

### 12.2 Unit Tests

| ID | Scenario | Expected Outcome |
|----|----------|-----------------|
| TC-DSH-U01 | `DashboardService::resolveUserRole()` for admin user | Returns `'school-admin'` |
| TC-DSH-U02 | `DashboardService::resolveUserRole()` for user with no role | Returns `'default'` |
| TC-DSH-U03 | `WidgetDataRepository::getStudentsCount()` with mocked DB | Returns integer |
| TC-DSH-U04 | `DashboardService::getDataForRole()` calls cache first | `Cache::remember` called; DB not hit on cache hit |
| TC-DSH-U05 | `DashboardService::getDataForRole()` with `school-admin` role | Returns array with keys: `students_count`, `attendance_percent`, `fee_collected`, `fee_pending` |
| TC-DSH-U06 | Cache key generation includes tenant ID | Key format `dash.school-admin.{tenantId}.{userId}.{date}` |

### 12.3 Security Tests

| ID | Scenario | Expected Outcome |
|----|----------|-----------------|
| TC-DSH-S01 | Cross-tenant data isolation | Admin of Tenant A cannot see Tenant B student count |
| TC-DSH-S02 | Student accessing `/dashboard/core-configuration` | 403 |
| TC-DSH-S03 | Parent accessing `/dashboard/school-setup` | 403 |
| TC-DSH-S04 | Teacher accessing fee collection widget via API | API returns empty/hidden data for fee widget |

---

## 13. Glossary

| Term | Definition |
|------|-----------|
| KPI | Key Performance Indicator — a metric widget on the dashboard |
| Widget | A self-contained UI card displaying a single metric or visualization |
| Tenant | A school instance with its own isolated MySQL database (`tenant_{uuid}`) |
| Academic Session | An academic year (e.g., 2025-26), managed in `sch_org_academic_sessions_jnt` |
| Academic Term | A subdivision of a session (e.g., Term 1, Term 2) within the academic session |
| Sub-dashboard | A domain-specific dashboard page for a functional area (e.g., Admission, Finance) |
| Role Dispatch | The process of detecting user role and returning the role-appropriate dashboard view |
| DashboardService | A Laravel Service class responsible for aggregating multi-module data for the dashboard |
| WidgetDataRepository | A Repository class encapsulating all dashboard DB queries, injectable and mockable |
| Cache Invalidation | Clearing cached dashboard data when source module data changes (via Events/Observers) |
| Redis Tag | A Redis cache grouping mechanism enabling bulk invalidation of related keys |
| AdminLTE | The Bootstrap-based admin UI template used across the Prime-AI backend |
| Stateless Aggregator | A module with no own DB tables that only reads data from other modules |
| CSRF | Cross-Site Request Forgery protection — required on all non-GET AJAX calls |
| SSE | Server-Sent Events — a web technology for real-time server-to-client push |

---

## 14. Suggestions

1. **Implement `DashboardService` as the single entry point** for all dashboard data. Controller should contain zero DB queries — only call `DashboardService::getDataForRole($user, $role)`. This enables full unit testability and future mobile API reuse.

2. **Use Blade components for every widget** — `<x-dashboard.widget.stat-box>`, `<x-dashboard.widget.trend-chart>`, `<x-dashboard.widget.notification-feed>`. This enables widget reuse across role dashboards and sub-domain dashboards without duplication.

3. **Fix BUG-001 immediately** (wrong view path in `index()`) — this is a one-line change but causes the main dashboard to render outside the module's view namespace, which breaks theming isolation.

4. **Add `DashboardPolicy`** with methods: `viewAdminDashboard`, `viewCoreConfiguration`, `viewFoundationalSetup`, `viewAdmissions`, `viewSchoolSetup`, `viewOperations`, `viewSupport`. Register in `AuthServiceProvider`. Every controller method calls `$this->authorize('{ability}', Dashboard::class)`.

5. **Lazy-load all chart widgets** via AJAX after initial page paint. The stat-box widgets (student count, attendance %, fee totals) render synchronously from cached data; charts (trend lines, bar graphs) load asynchronously to prevent perceived slowness.

6. **Replace the AdminLTE "Direct Chat" widget** with a real School Announcements feed from `ntf_notifications WHERE type = 'announcement'`. The Direct Chat is an AdminLTE demo artifact that has no backend and no relevance to school operations.

7. **Remove the world map widget** (`#world-map`) entirely. It serves no purpose in a single-school tenant context.

8. **Consolidate conflicting dashboard routes** — the `dashboard` named route is currently duplicated (line 315 and line 544 of `tenant.php`, the latter inside global-master prefix). This must be resolved before production deployment.

9. **Consider a `dash_widget_preferences` table** (Phase 2) for persistent drag-and-drop layout customization, rather than `sys_settings` JSON. A dedicated table enables indexed lookups and per-role defaults managed from an admin UI.

10. **Add Redis health check** to the Dashboard boot flow. If Redis is unreachable, fall back to array cache driver and log a warning. Never let a cache infrastructure failure cause a dashboard 500 error.

11. **Design chart data API for time zone awareness** — Indian schools operate in IST (UTC+5:30). All `DATE(created_at)` queries in dashboard must use `CONVERT_TZ` or set `DB::statement("SET time_zone='+05:30'")` at connection time.

12. **Consider a `dashboard_health_check` scheduled job** that pre-warms the cache for all active tenants at 6:00 AM IST daily, so the first admin login does not trigger a cold-cache aggregation.

---

## 15. Appendices

### 15.1 Current File Inventory

| File | Path | Status |
|------|------|--------|
| DashboardController (module) | `Modules/Dashboard/app/Http/Controllers/DashboardController.php` | 38 lines, 7 methods, zero auth |
| DashboardController (legacy) | `app/Http/Controllers/V1/DashboardController.php` | 16 lines, duplicate, unused |
| index view (module) | `Modules/Dashboard/resources/views/index.blade.php` | "Hello World" stub |
| index view (backend) | `resources/views/backend/v1/dashboard/index.blade.php` | Tab template scaffold (not school-specific) |
| core-configuration view | `Modules/Dashboard/resources/views/core-configuration/dashboard.blade.php` | AdminLTE demo content |
| All 5 other sub-dashboard views | `Modules/Dashboard/resources/views/*/dashboard.blade.php` | Identical AdminLTE demo clones |
| DashboardDatabaseSeeder | `Modules/Dashboard/database/seeders/DashboardDatabaseSeeder.php` | Empty |
| Module routes/web.php | `Modules/Dashboard/routes/web.php` | Registers resource route, not used |
| Module routes/api.php | `Modules/Dashboard/routes/api.php` | Registers apiResource, non-functional |

### 15.2 Files to Create in V2 Implementation

| File | Purpose |
|------|---------|
| `Modules/Dashboard/app/Services/DashboardService.php` | Role dispatch + cache management |
| `Modules/Dashboard/app/Repositories/WidgetDataRepository.php` | All dashboard DB queries |
| `Modules/Dashboard/app/Policies/DashboardPolicy.php` | Gate abilities per section |
| `Modules/Dashboard/app/Http/Controllers/DashboardApiController.php` | JSON API for mobile |
| `Modules/Dashboard/resources/views/admin/index.blade.php` | School admin dashboard |
| `Modules/Dashboard/resources/views/teacher/index.blade.php` | Teacher dashboard |
| `Modules/Dashboard/resources/views/student/index.blade.php` | Student dashboard |
| `Modules/Dashboard/resources/views/parent/index.blade.php` | Parent dashboard |
| `Modules/Dashboard/resources/views/accountant/index.blade.php` | Accountant dashboard |
| `Modules/Dashboard/resources/views/components/widgets/stat-box.blade.php` | Reusable stat widget |
| `Modules/Dashboard/resources/views/components/widgets/trend-chart.blade.php` | Reusable chart widget |
| `Modules/Dashboard/resources/views/components/widgets/notification-feed.blade.php` | Notification widget |
| `Modules/Dashboard/tests/Feature/DashboardAuthTest.php` | Route auth + role tests |
| `Modules/Dashboard/tests/Feature/DashboardDataTest.php` | Widget data integration tests |
| `Modules/Dashboard/tests/Unit/DashboardServiceTest.php` | Service unit tests |
| `Modules/Dashboard/tests/Unit/WidgetDataRepositoryTest.php` | Repository unit tests |

### 15.3 Priority Fix Plan (V2 Implementation Order)

**P0 — Critical (implement before anything else):**
1. Fix `index()` view path → `dashboard::index` (15 min)
2. Add `Gate::authorize` to all 7 controller methods (1 hour)
3. Create `DashboardPolicy` (2 hours)
4. Resolve duplicate/conflicting named routes (1 hour)

**P1 — High (core feature delivery):**
5. Create `DashboardService` + `WidgetDataRepository` (4 hours)
6. Implement School Admin dashboard with real data (6 hours)
7. Implement Teacher dashboard with real data (4 hours)
8. Implement Student dashboard with real data (4 hours)
9. Implement role-based view dispatch in `DashboardController@index` (2 hours)
10. Build reusable Blade widget components (3 hours)

**P2 — Medium (complete dashboard suite):**
11. Implement Parent dashboard (multi-child support) (5 hours)
12. Implement Accountant dashboard (3 hours)
13. Fix all 6 sub-domain dashboards with real widgets (6 hours)
14. Implement notification mark-read AJAX (2 hours)
15. Add Redis caching with cache invalidation listeners (4 hours)

**P3 — Low (enhancement):**
16. Transport Manager + Librarian dashboards (4 hours)
17. Onboarding setup checklist widget (3 hours)
18. Chart lazy-loading AJAX (2 hours)
19. Mobile API endpoints (DashboardApiController) (4 hours)
20. Write full test suite (8 hours)

**Estimated total effort:** ~72 hours (about 9 developer-days)

---

## 16. V1 to V2 Delta

### New in V2 (not present in V1)

| ID | Addition |
|----|----------|
| 🆕 | Accountant Dashboard variant (FR-DSH-07) |
| 🆕 | Transport Manager Dashboard variant (FR-DSH-08) |
| 🆕 | Librarian Dashboard variant (FR-DSH-09) |
| 🆕 | Hostel Warden Dashboard variant (mentioned in role table) |
| 🆕 | Principal Dashboard variant (FR-DSH-03) |
| 🆕 | Multi-child parent selector (FR-DSH-06 W-PAR-01 + workflow 9.3) |
| 🆕 | Cache invalidation strategy with Redis tags (Section 5.3) |
| 🆕 | Notification mark-all-read AJAX workflow (workflow 9.4) |
| 🆕 | New tenant onboarding checklist widget (FR-DSH-14) |
| 🆕 | Configurable widget layout via sys_settings (FR-DSH-13) |
| 🆕 | `WidgetDataRepository` pattern (Section 2.3, Section 15.2) |
| 🆕 | Mobile API endpoints (Section 6.3) |
| 🆕 | Corrected actual DDL table names for all data sources (Section 5.2) |
| 🆕 | Route conflict analysis and resolution (Section 6.4, BUG-004, BUG-005) |
| 🆕 | IST timezone handling requirement (Suggestion 11) |
| 🆕 | Cache pre-warming job concept (Suggestion 12) |
| 📐 | DashboardApiController for mobile (Section 6.3) |
| 📐 | Server-Sent Events / push for notification badge (NFR-DSH-05) |
| 📐 | `dash_widget_preferences` table (future Phase 2, Section 5.1) |

### Updated from V1 (corrections and expansions)

| Area | V1 | V2 |
|------|----|----|
| Data source table names | Assumed names (`fin_fee_collections`, `std_attendances`, `exm_exam_schedules`) | Corrected to actual DDL names (`fee_transactions`, `std_student_attendance`, `lms_exams`) |
| Dashboard variants | 4 roles (Admin, Teacher, Student, Parent) | 9 roles (added Accountant, Transport, Librarian, Hostel Warden, Principal) |
| Authorization model | Generic `Gate::authorize` recommendation | Full `DashboardPolicy` with per-section abilities |
| Caching strategy | Generic `Cache::remember` recommendation | Full Redis tag-based strategy with TTL per widget type and cache key format |
| Route analysis | Listed routes | Added conflict analysis (BUG-004, BUG-005) referencing exact tenant.php line numbers |
| Widget inventory | High-level list | Full widget tables with Widget ID, data source, key columns, and update frequency |
| Test cases | 10 basic tests | 26 tests across Feature, Unit, and Security categories |
| Sub-dashboard content | Generic widget list | Specific widgets per sub-domain tied to actual module tables |

### Retained from V1 (unchanged)

- Business rules BR-DSH-01 through BR-DSH-08 (all retained, BR-DSH-09 through BR-DSH-12 added)
- Core architecture: no dedicated DB tables (stateless aggregator)
- Module folder structure and provider registration
- NFRs NFR-DSH-01 through NFR-DSH-08 (all retained, NFR-DSH-09 through NFR-DSH-11 added)
- Cross-module dependency list (expanded with corrected table names)
- Priority fix order: BUG-001 (view path) → BUG-002 (auth) → DashboardService → role views
