# Dashboard — Business Requirements

## 1. What This Screen Does

The Parent Portal Dashboard (`/parent-portal/`) is the landing page that greets every parent after login. It shows a unified snapshot of the currently active child's school life — attendance percentage, today's timetable cells, pending homework (top 5), upcoming exams (top 5), fee summary (total, paid, due), leave application counts, and recent notifications (top 5). A child-switcher widget in the header (or sidebar) lets the parent change the active child without logging out, and all data refreshes for the newly selected child.

The **My Children** page (`/parent-portal/children`) complements the dashboard by presenting a full list of all children linked to the parent, each showing name, class-section, and subjects studied.

---

## 2. When This Screen Is Used

- **After login** — The dashboard is the default landing page after authentication
- **Monitoring daily** — Parents check attendance status, today's timetable, and pending homework
- **Fee tracking** — Parents review outstanding fee balance and upcoming due dates
- **Leave overview** — Parents see how many leave applications are pending or submitted
- **Notification check** — Parents see recent school notifications at a glance
- **Switching child context** — Parents of multiple children switch the active child to view data for a different child
- **Viewing all children** — Parents visit My Children to see the full list of linked children and their class-section information

---

## 3. Who Can Access This Screen

- **Parent / Guardian** — Full access to own linked children's data only
- **System** — Aggregates data from multiple modules; no administrative access

No explicit Gate policy exists in the code (`ParentChildPolicy` is MISSING — P0 gap). All data is read-only for the parent. The system enforces child ownership via `ParentContextService` which checks the `std_student_guardian_jnt.can_access_parent_portal` flag on every request.

---

## 4. How This Screen Works — Step by Step

### 4.1 Dashboard Load

1. Parent authenticates and lands at `/parent-portal/`
2. `ParentDashboardController@index` is invoked
3. `ParentContextService::resolveChild($request)` determines the active child:
   - If the parent has only one linked child, that child is used directly (no session write needed)
   - If the parent has multiple children, the active child is read from `ppt_parent_sessions.active_student_id` (DB-persisted, not PHP session)
   - If no session row exists, the first child in the list is used as default
   - If the parent has no linked children with `can_access_parent_portal = 1`, the system redirects to the `/no-access` page
4. The controller loads the child's current academic session with class-section relationship
5. Six data widgets are computed sequentially:

   **Attendance %:**
   - Queries `std_attendance` for the child filtered by `academic_session_id`
   - Computes total record count and present count (status in `['Present', 'P', 'present']`)
   - Rounds percentage to nearest integer
   - If no academic session is assigned, shows 0%

   **Today's Timetable:**
   - Queries `TimetableCell` through timetable activity (class_id + section_id match)
   - Filters to published/active timetables (status in `['ACTIVE', 'GENERATED', 'PUBLISHED']`)
   - Filters to `day_of_week` matching today's day
   - Filters out break periods
   - Orders by `period_ord`; eager-loads subject, teachers, period, room
   - Returns 0 to N cells for today

   **Pending Homework (top 5):**
   - Finds all homework IDs already submitted by the child via `HomeworkSubmission`
   - Queries published homework for the child's class-section, excluding submitted IDs
   - Orders by `due_date` ascending; limits to 5
   - Returns pending count + top 5 items

   **Upcoming Exams (top 5):**
   - Queries `ExamAllocation` for CLASS, SECTION, or STUDENT allocation types matching the child
   - Filters to future-dated exams (scheduled date or exam start date > now)
   - Sorts by scheduled date; limits to 5
   - Returns upcoming count + top 5 items

   **Fee Summary:**
   - Uses the child's current fee assignment
   - Sums `total_amount`, `paid_amount`, `balance_amount` across all invoices
   - Counts invoices not yet in paid status (case-insensitive)
   - If no fee assignment exists, shows 0.0 for all values

   **Leave Counts:**
   - Queries `LeaveApplication` for the child, excluding cancelled status
   - Computes total count and pending count (status in SUBMITTED, UNDER_REVIEW, INFO_REQUESTED, DOC_REQUESTED)

   **Recent Notifications (top 5):**
   - Gets the parent user's notifications (Laravel Notifiable trait)
   - Limits to 5 most recent

6. An activity log entry is created: "Viewed dashboard" with student_id, student_name, module, and route
7. The data is passed to the `parentportal::dashboard.index` Blade view

### 4.2 My Children Page

1. Parent navigates to `/parent-portal/children`
2. `ParentDashboardController@children` is invoked
3. `ParentContextService::getAccessibleChildren($request->user())` returns all Student records linked to this parent with `can_access_parent_portal = 1`
4. The active child is resolved via `resolveChild()` — if resolution fails, the first child's ID is used
5. Data is eager-loaded: current semester, class-section class, class-section section, academic session
6. Subject names per class are fetched through `sch_subject_groups` → `sch_subject_group_subject_jnt` → `sch_subjects` — grouped by `class_id`
7. An activity log entry is created: "Viewed children list" with student context
8. Data is passed to the `parentportal::children.index` Blade view

### 4.3 Child Switcher (AJAX)

1. Parent clicks a child card or uses a header dropdown to switch the active child
2. A POST request is sent to `/parent-portal/switch-child` with `student_id` in the request body
3. `SwitchChildParentDashboardRequest` validates the input
4. `ParentContextService::setActiveChild()` is called:
   - Validates the parent is linked to the target student via `assertCanAccess()`
   - Updates `ppt_parent_sessions.active_student_id` and `last_active_at`
5. On success, JSON `{status: true, message: "Child switched."}` is returned
6. The front-end reloads the page to refresh all data for the new child
7. On failure (e.g., parent not linked to student), HTTP 422 or 403 is returned
8. An activity log entry is created: "Switched active child" with student context

---

## 5. Validation Rules

### 5.1 SwitchChildParentDashboardRequest

| Field | Rule | Error Message |
|---|---|---|
| `student_id` | required, integer, exists:std_students,id | "The student id field is required." / "The selected student id is invalid." |

### 5.2 Controller-level Guards

| Condition | Guard | Behaviour |
|---|---|---|
| Parent has no linked children | `ParentContextService::resolveChild()` | Redirect to `/no-access` |
| Parent tries to switch to unlinked child | `ParentContextService::assertCanAccess()` | HTTP 403 "You are not authorised to view this child's data." |
| Invalid month format in attendance filter | ParentAttendanceController | HTTP 422 "Invalid month format" |

---

## 6. Business Rules and Conditions

### Rule BR-PPT-001: Child Data Scoping
All dashboard data exclusively belongs to the parent's linked children — no data from other students is ever accessible. Enforced by `ParentContextService` at every endpoint.

### Rule BR-PPT-010: Active Child Persisted in DB
Active child selection is stored in `ppt_parent_sessions.active_student_id` (not PHP session only) — this enables multi-device sync and survives session expiry.

### Rule BR-PPT-012: Every Data Endpoint Verifies Child Ownership
Every controller method uses `ParentContextService::resolveChild()` or `assertCanAccess()` to verify the parent→child link before returning any data.

### Rule: Dashboard Aggregation ≤ 5 Batch Queries
Dashboard data is gathered in separate queries (not a single aggregation service) — attendance, timetable, homework, exams, fees, leave, notifications each fire independently.

### Rule: No Dashboard Cache Implemented
The current implementation does NOT cache dashboard data. Non-real-time data (homework count, test scores) could benefit from 5-minute TTL caching per FRD recommendation, but this is not yet implemented.

### Rule: Read-Only Data
All dashboard widgets display data obtained from read-only queries. The parent cannot modify attendance, homework, fee structures, or timetable data from the dashboard.

---

## 7. Business Rules Summary

| Rule | What It Means |
|---|---|
| BR-PPT-001 | Data scoped to parent's linked children only |
| BR-PPT-010 | Active child persisted in `ppt_parent_sessions` for multi-device sync |
| BR-PPT-012 | Child ownership verified on every endpoint |
| No Cache | Dashboard data not cached (FRD recommends 5-min TTL for non-realtime data) |
| Read-Only | Parent cannot modify any dashboard data |

---

## 8. Error Messages

| Scenario | Error Message / Behaviour |
|---|---|
| No linked children | Redirect to `/no-access` screen with contact-school message |
| Switch to unlinked child | HTTP 403 "You are not authorised to view this child's data." |
| Invalid student_id in switch POST | Validation error: "The selected student id is invalid." |
| Missing student_id in switch POST | Validation error: "The student id field is required." |
| Child resolution fails (unexpected) | Caught by `ParentContextService`; first child used as fallback |
| No academic session assigned | Attendance shows 0%; timetable/homework/exam widgets are empty |

---

## 9. Success Scenarios

- **Parent with one child logs in**: Dashboard shows the single child's data immediately — attendance %, today's cells, pending homework, upcoming exams, fee summary, leave counts, recent notifications.
- **Parent with two children logs in**: Dashboard shows the last-active child's data. The child card/sidebar shows both children. The parent clicks the other child — POST to `/switch-child` succeeds; page reloads with the new child's data.
- **Parent switches child and refreshes the browser**: The active child persists (DB-stored) — the dashboard still shows the switched child's data after reload.
- **No homework pending**: "Pending Homework" widget shows 0 items with an appropriate empty-state message.
- **All fees paid**: Fee summary shows total = paid, due = 0, with a "No pending dues" message.

---

## 10. Failure Scenarios

- **Parent with no linked children accesses dashboard**: Receives redirect to `/no-access` — shows a clear "You do not have access to any children. Please contact the school." message. No crash or 500 error.
- **Parent attempts to switch to a non-existent student_id**: FormRequest validation rejects with "The selected student id is invalid." No system error.
- **Parent attempts to switch to another family's child (IDOR attempt)**: `ParentContextService::assertCanAccess()` throws HTTP 403. The attempt is NOT currently logged to the audit log (gap — IDOR attempts should be logged).
- **Database connection fails**: Laravel exception handling returns a 500 error page — no graceful degradation for infrastructure failures.

---

## 11. Example Scenario

Mrs. Sharma logs into the Parent Portal. She has two children: Aarav (Class 7A) and Priya (Class 5B).

1. **Dashboard loads**: The system checks `ppt_parent_sessions` — the last active child was Aarav. His dashboard shows:
   - Attendance: 92% (present 138 of 150 working days)
   - Today's timetable: 4 cells — Math (Mr. Verma), Science (Ms. Patel), Hindi (Mr. Singh), PE (Mr. Khan)
   - Pending homework: 2 items — Math homework due tomorrow, Science project due Friday
   - Upcoming exams: 1 exam — Half-Yearly Math exam on 2026-09-15
   - Fee summary: Total ₹45,000 — Paid ₹30,000 — Due ₹15,000 (2 invoices unpaid)
   - Leave: 1 pending application (family wedding)
   - Notifications: 3 unread — Fee reminder, Sports Day circular, PTM announcement

2. **Switch to Priya**: Mrs. Sharma clicks Priya's card in the sidebar. A POST request to `/switch-child` with `student_id=Priya's ID` updates `ppt_parent_sessions.active_student_id`. The page reloads and now shows Priya's data:
   - Attendance: 97%, different timetable, 0 pending homework, etc.

3. **Refresh browser**: The active child stays as Priya because the selection is DB-persisted.

---

## 12. Related Screens

| Screen | Route | Relationship |
|---|---|---|
| Attendance Calendar | `/parent-portal/attendance/` | Deep-link from dashboard attendance % widget |
| Homework List | `/parent-portal/homework/` | Deep-link from pending homework widget |
| Exam Results | `/parent-portal/results/` | Deep-link from upcoming exams widget |
| Fee Invoices | `/parent-portal/fees/` | Deep-link from fee summary widget |
| Leave Applications | `/parent-portal/leave/` | Deep-link from leave count widget |
| Notifications | `/parent-portal/notifications/` | Deep-link from recent notifications |
| My Children | `/parent-portal/children` | Full list view of all linked children |

---

## 13. How Other Parts of the System Depend on This Screen

| Area | What It Needs From Dashboard |
|---|---|
| **My Children page** | Uses `ParentContextService::getAccessibleChildren()` — same child resolution logic |
| **Child Switcher** | Active child selection is used by ALL other portal screens to scope their data |
| **Activity Log** | Dashboard view and child-switch events are recorded in `sys_activity_logs` |
| **ppt_parent_sessions** | Active child selection is persisted to this table for multi-device sync |
| **StudentProfile** | Student data, guardian links, and `can_access_parent_portal` flag drive ownership checks |

---

## 14. Dependencies

| Dependency | Type | Purpose |
|---|---|---|
| `ParentContextService` | Internal service | Child resolution, ownership assertion, active child persistence |
| `SwitchChildParentDashboardRequest` | FormRequest | Validates student_id on child switch |
| `ParentSession` (ppt_parent_sessions) | Model | Stores active_student_id, device tokens, last_active_at |
| `StudentAttendance` (std_attendance) | External model | Attendance percentage computation |
| `TimetableCell` (tt_timetable_cells) | External model | Today's timetable cells |
| `Homework` (hmw_assignments) | External model | Pending homework list |
| `HomeworkSubmission` (hmw_submissions) | External model | Submitted homework exclusion |
| `ExamAllocation` (exm_allocations) | External model | Upcoming exams list |
| `FeeInvoice` (fin_fee_invoices) | External model | Fee summary computation |
| `LeaveApplication` (student_leave_applications) | External model | Leave counts |
| `StudentProfile` / `Guardian` / `StudentGuardianJnt` | External models | Child ownership chain |
| `activityLog()` | Global helper | Audit logging |

---

## 15. State Machine

### Dashboard Load FSM

| Step | Event | Guard | Result |
|---|---|---|---|
| 1 | Parent navigates to `/parent-portal/` | Authenticated | Dashboard begins loading |
| 2 | Resolve active child | Parent has >= 1 linked child with can_access=1 | Child resolved; data loaded |
| 2a | Resolve active child | Parent has 0 linked children | Redirect to `/no-access` |
| 3 | Resolve active child | Single child | Child used directly |
| 3a | Resolve active child | Multiple children | Read from `ppt_parent_sessions.active_student_id` |
| 3b | Resolve active child | No session row exists | Default to first child |
| 4 | Load dashboard widgets | Child + session available | All 6 widgets computed |
| 5 | Render view | Widget data collected | Dashboard displayed |

### Child Switcher FSM

| From State | Event | Guard | To State | Side-Effects |
|---|---|---|---|---|
| Active Child A | POST /switch-child | Parent linked to Child B | Active Child B | `ppt_parent_sessions.active_student_id` updated; page reloaded |
| Active Child A | POST /switch-child | Parent NOT linked to Child B | Active Child A (unchanged) | HTTP 403; no change |
| Active Child A | POST /switch-child | Invalid student_id | Active Child A (unchanged) | HTTP 422 validation error |

---

## 16. Notes and Gaps

| # | Note | Impact |
|---|---|---|
| 1 | **ParentChildPolicy MISSING (P0 gap):** No Laravel Policy or Gate exists for parent→child ownership. The check is enforced at the service level (`ParentContextService::assertCanAccess()`) but not via a reusable Policy that could be applied globally via `Gate::policy()` or controller middleware. | IDOR vulnerability if any controller method bypasses the context service. Every data endpoint must independently call `resolveChild()`. |
| 2 | **No dashboard caching:** FRD recommends 5-minute TTL caching for non-real-time data (homework count, test scores). Current implementation queries the database on every page load. | Higher database load under concurrent parent usage. |
| 3 | **IDOR attempts not logged:** When `assertCanAccess()` throws 403, the attempt is not recorded in `sys_activity_logs`. This reduces audit trail for security monitoring. | Missing forensic evidence for unauthorized access attempts. |
| 4 | **No explicit authorization Gate on controllers:** The controller constructor or methods do not invoke `$this->authorize()` or Gate checks. All protection relies on `ParentContextService` being called. | If a future code change omits the context service call, data would leak. |
