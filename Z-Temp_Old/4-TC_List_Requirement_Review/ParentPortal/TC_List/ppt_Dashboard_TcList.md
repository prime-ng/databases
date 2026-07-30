# ppt_Dashboard_TcList

## Module: ParentPortal → Dashboard (including My Children & Child Switcher)

---

## 1. Feature Information

| Item | Details |
|---|---|
| Module | ParentPortal (PPT) |
| Tab Group | Dashboard |
| Features | Dashboard landing page (attendance %, today timetable, pending homework 5, upcoming exams 5, fee summary, leave counts, recent notifications 5), My Children page (full child list with class/section/subjects), Child Switcher (AJAX POST) |
| URL(s) | `GET /parent-portal/` (dashboard), `GET /parent-portal/children` (My Children), `POST /parent-portal/switch-child` (Child Switcher) |
| Controller | `Modules\ParentPortal\Http\Controllers\ParentDashboardController` (@index, @children, @switchChild) |
| Service | `Modules\ParentPortal\Services\ParentContextService` |
| FormRequest | `Modules\ParentPortal\Http\Requests\SwitchChildParentDashboardRequest` |
| Model(s) | `ParentSession` (ppt_parent_sessions), `Student`, `Guardian`, `StudentGuardianJnt` |
| External Models | `StudentAttendance`, `TimetableCell`, `Homework`, `HomeworkSubmission`, `ExamAllocation`, `FeeInvoice`, `LeaveApplication` |
| Permission Gates | None — ParentChildPolicy MISSING (P0 gap); protection via ParentContextService |
| Soft Deletes | Not applicable (read-only data aggregation) |
| Events | `activityLog()` on dashboard view, children view, child switch |

---

## 2. Pre-conditions

- Authenticated parent session with at least one linked child (`std_student_guardian_jnt.can_access_parent_portal = 1`)
- For multi-child tests: at least two linked children with `can_access_parent_portal = 1`
- For single-child tests: exactly one linked child
- For no-access tests: authenticated parent with zero linked children
- For IDOR tests: a student record NOT linked to the authenticated parent
- For widget-specific tests: attendance records, timetable cells, homework, exams, fee invoices, leave applications, and notifications exist in their respective modules for the test child
- For child switch tests: `ppt_parent_sessions` may or may not have a row for the guardian

---

## 3. Default Data Load

### 3.1 Dashboard (`index()`)

| Widget | Data Source | Query Scope | Pagination |
|---|---|---|---|
| Attendance % | `StudentAttendance::where('student_id', $child->id)->where('academic_session_id', ...)` | Current academic session | None (aggregate count) |
| Today's Timetable | `TimetableCell::whereHas('activity', class+section)->whereHas('timetable', status)->where('day_of_week', today)` | Active/PUBLISHED timetables, non-break | None (filtered collection) |
| Pending Homework (5) | `Homework::published()->where(class+section)->whereNotIn('id', submittedIds)->orderBy('due_date')->limit(5)` | Current class-section | Limit 5 |
| Upcoming Exams (5) | `ExamAllocation::where(class/section/student match)->future dates->sortBy()->take(5)` | Current child | Limit 5 |
| Fee Summary | `FeeInvoice::where('fee_assignment_id', $child->currentFeeAssignment?->id)` | Current fee assignment | None (sum aggregates) |
| Leave Counts | `LeaveApplication::where('student_id', $child->id)->whereNotIn('status', [CANCELLED])` | All child leaves | None (count) |
| Recent Notifications (5) | `$request->user()->notifications()->take(5)` | Parent user | Limit 5 |

### 3.2 My Children (`children()`)

| Data | Source | Query Scope |
|---|---|---|
| Child list | `ParentContextService::getAccessibleChildren()` | All students linked via guardian→student junction with `can_access_parent_portal = 1` |
| Active child ID | `ParentContextService::resolveChild()` or `$children->first()->id` | Single fallback if resolution fails |
| Subjects by class | `sch_subject_groups` → `sch_subject_group_subject_jnt` → `sch_subjects` (distinct by class_id) | Classes of linked children |

### 3.3 Child Switcher (`switchChild()`)

| Parameter | Source | Validation |
|---|---|---|
| `student_id` | POST body | required, integer, exists:std_students,id |

---

## 4. BC-DB — Database Schema

### 4.1 `ppt_parent_sessions` — Per-Device Portal Session

| Column | Data Type | Nullable | Default | Notes |
|---|---|---|---|---|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| guardian_id | INT UNSIGNED | NOT NULL | — | FK → std_guardians.id CASCADE |
| active_student_id | INT UNSIGNED | YES | NULL | FK → std_students.id SET NULL |
| device_token_fcm | VARCHAR(255) | YES | NULL | Android FCM push token |
| device_token_apns | VARCHAR(255) | YES | NULL | iOS APNs push token |
| device_token_webpush | TEXT | YES | NULL | Web Push subscription JSON |
| device_type | ENUM('Android','iOS','Web','Unknown') | NOT NULL | 'Unknown' | Device classification |
| notification_preferences_json | JSON | YES | NULL | Per-alert-type channel toggles |
| quiet_hours_start | TIME | YES | NULL | Non-urgent notification buffer start |
| quiet_hours_end | TIME | YES | NULL | Non-urgent notification buffer end |
| last_active_at | TIMESTAMP | YES | NULL | Last portal interaction |
| is_active | TINYINT(1) | NOT NULL | 1 | 0 = logged out |
| created_by | BIGINT UNSIGNED | YES | NULL | Creator reference |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | Update time |

**Indexes:** PRIMARY KEY (`id`), UNIQUE (`guardian_id`, `device_token_fcm`), INDEX (`guardian_id`), INDEX (`active_student_id`), INDEX (`is_active`)

### 4.2 Key External Tables Referenced

| Table | Columns Used | Relationship |
|---|---|---|
| `std_students` | id, is_active | Active child identity |
| `std_guardians` | id, user_id | Guardian→user linkage |
| `std_student_guardian_jnt` | guardian_id, student_id, can_access_parent_portal | Ownership junction |
| `std_attendance` | student_id, academic_session_id, status, attendance_date | Attendance data |
| `tt_timetable_cells` | id, timetable_id, day_of_week, period_ord, is_break | Today's timetable |
| `hmw_assignments` | id, class_id, section_id, due_date | Homework records |
| `hmw_submissions` | homework_id, student_id | Submission status |
| `exm_exam_allocations` | id, allocation_type, class_id, section_id, student_id, scheduled_date | Exam schedule |
| `fin_fee_invoices` | fee_assignment_id, total_amount, paid_amount, balance_amount, status | Fee data |

---

## 5. BC-VAL — Validation Rules

### 5.1 SwitchChildParentDashboardRequest

| Field | Rules | Error Message |
|---|---|---|
| student_id | required, integer, exists:std_students,id | "The student id field is required." / "The selected student id is invalid." |

### 5.2 Controller Guards (Not FormRequest)

| Condition | Check | Behaviour |
|---|---|---|
| Parent has 0 accessible children | `ParentContextService::resolveChild()` | `abort(redirect()->route('parent-portal.no-access'))` |
| Switch to unlinked child | `ParentContextService::assertCanAccess()` | `abort(403, 'You are not authorised to view this child\'s data.')` |
| Single-child shortcut | `$children->count() === 1` | Returns child directly without session write |

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method | Status | Notes |
|---|---|---|---|
| N/A | index() | NO GATE | No `ParentChildPolicy` — P0 gap. Protection via `ParentContextService::resolveChild()` only |
| N/A | children() | NO GATE | Same — service-level ownership check only |
| N/A | switchChild() | NO GATE | Same — `assertCanAccess()` called inside `setActiveChild()` |

**Key Gap:** No `Gate::authorize()` or `$this->authorize()` call exists in any of the three controller methods. All authorization relies on `ParentContextService` being invoked. If a future modification removes or bypasses the service call, data would be exposed.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|---|---|---|
| BC-BIZ-01 | Multi-Child Resolution Order | resolveChild(): single child → return directly; multiple → read from `ppt_parent_sessions.active_student_id` or default to first; none → redirect no-access |
| BC-BIZ-02 | DB-Persisted Active Child | `setActiveChild()` writes to `ppt_parent_sessions.active_student_id`, NOT PHP session — survives browser refresh and device switch |
| BC-BIZ-03 | Child Ownership Assertion | `assertCanAccess()` checks `std_student_guardian_jnt` for guardian_id + student_id + can_access_parent_portal = 1 |
| BC-BIZ-04 | Dashboard Widget Data | 6 independent queries (attendance, timetable, homework, exams, fees, leave) + notifications — no batch service |
| BC-BIZ-05 | Activity Logging | Every dashboard view, children view, and child switch is logged via `activityLog()` with student context |
| BC-BIZ-06 | Subject Loading for Children | Children page loads subject names per class through 3-join query: subject_groups → subject_group_subject_jnt → subjects, distinct by class_id |
| BC-BIZ-07 | Fee Invoice Status Check | Fee pending invoices counted as `whereNotIn('status', ['paid', 'PAID', 'Paid'])` — case-insensitive comparison |
| BC-BIZ-08 | Attendance Status Normalization | Present check includes `['Present', 'P', 'present']` — handles multiple status conventions |
| BC-BIZ-09 | Exam Future-Date Filter | `scheduled_date ?? examPaper.exam.start_date` must be future (`Carbon::parse()->isFuture()`) |
| BC-BIZ-10 | Fallback on Child Resolution Failure | If `resolveChild()` throws, `children()` catches and uses `$children->first()->id` as activeId |

---

## 8. Known Issues

| Issue ID | Description | Severity | Status |
|---|---|---|---|
| KI-PPT-DASH-01 | **ParentChildPolicy MISSING:** No Laravel Policy exists for parent→child ownership. All protection is at the service layer only. Any controller method that omits the `resolveChild()` call would expose data. | P0 (Critical) | ⬜ Not Started |
| KI-PPT-DASH-02 | **No Dashboard Caching:** FRD recommends 5-minute TTL for non-real-time widgets (homework count, exam scores). Current implementation queries DB on every load. | P2 (Low) | ⬜ Not Started |
| KI-PPT-DASH-03 | **IDOR Attempts Not Logged:** When `assertCanAccess()` returns 403, the attempt is not recorded in `sys_activity_logs`. | P1 (Medium) | ⬜ Not Started |
| KI-PPT-DASH-04 | **No Authorization Gates on Controllers:** No `Gate::authorize()` or `$this->authorize()` in any dashboard method. Relies entirely on developer discipline to call `ParentContextService`. | P0 (Critical) | ⬜ Not Started |
| KI-PPT-DASH-05 | **Fee Invoice Status Check Not Normalised:** `whereNotIn('status', ['paid', 'PAID', 'Paid'])` uses hardcoded status values — may miss other paid conventions from StudentFee module. | P2 (Low) | ⬜ Not Started |
| KI-PPT-DASH-06 | **Attendance Status Values Hardcoded:** Present check uses `['Present', 'P', 'present']` — hardcoded without reference to a config or enum. | P2 (Low) | ⬜ Not Started |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|---|---|---|---|---|
| GET | `/parent-portal/` | `parent-portal.dashboard` | `ParentDashboardController@index` | web, tenant, auth, verified, ParentPortal |
| GET | `/parent-portal/children` | `parent-portal.children` | `ParentDashboardController@children` | web, tenant, auth, verified, ParentPortal |
| POST | `/parent-portal/switch-child` | `parent-portal.switch-child` | `ParentDashboardController@switchChild` | web, tenant, auth, verified, ParentPortal |
| GET | `/parent-portal/no-access` | `parent-portal.no-access` | Closure: `fn () => view(...)` | web, tenant, auth, verified, ParentPortal |

**Middleware stack (applied by RouteServiceProvider):**
1. `web` — Laravel web middleware group
2. `InitializeTenancyByDomain` — stancl/tenancy domain resolution
3. `PreventAccessFromCentralDomains` — central domain block
4. `EnsureTenantIsActive` — tenant active check
5. `auth` — authenticated user required
6. `verified` — email verified (if enabled)
7. `ParentPortalMiddleware` — module-specific (device/context checks)

---

## 10. Execution Status

| Item | Status | Notes |
|---|---|---|
| Controller Implementation | ✅ Complete | All 3 methods implemented: index (247 lines), children (85 lines), switchChild (21 lines) |
| Views | ✅ Complete | `parentportal::dashboard.index`, `parentportal::children.index` exist |
| FormRequest | ✅ Complete | `SwitchChildParentDashboardRequest` exists |
| Service Layer | ✅ Complete | `ParentContextService` fully implements child resolution, ownership assertion, and device token registration |
| Route Registration | ✅ Complete | All 3 routes registered with correct middleware |
| Activity Logging | ✅ Complete | Dashboard view, children view, and switch event all logged |
| Authorization Policy | ❌ **MISSING (P0)** | No `ParentChildPolicy` — service-layer check only |
| Caching | ❌ Not Implemented | FRD recommends 5-min TTL caching |
| IDOR Attempt Logging | ❌ Not Implemented | 403 attempts not recorded |
| Pest Tests | ❌ Not Written | No test coverage for dashboard, children, or switch |
| Front-end Child Switcher UI | ⬜ Partial | Route handler exists; front-end widget implementation status unknown |

---

## 11. Test Case Summary

### 11.1 Dashboard — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-DASH-P01 | Dashboard | Positive | Dashboard loads for single-child parent | 5 |
| TC-PPT-DASH-P02 | Dashboard | Positive | Dashboard loads for multi-child parent with active child from session | 5 |
| TC-PPT-DASH-P03 | Dashboard | Positive | Attendance % widget displays correctly (100% present) | 4 |
| TC-PPT-DASH-P04 | Dashboard | Positive | Attendance % widget displays correctly (mixed statuses) | 4 |
| TC-PPT-DASH-P05 | Dashboard | Positive | Today's timetable widget shows cells for current day | 4 |
| TC-PPT-DASH-P06 | Dashboard | Positive | Today's timetable widget excludes break periods | 3 |
| TC-PPT-DASH-P07 | Dashboard | Positive | Pending homework widget shows top 5 items ordered by due_date | 5 |
| TC-PPT-DASH-P08 | Dashboard | Positive | Pending homework count excludes submitted homework | 4 |
| TC-PPT-DASH-P09 | Dashboard | Positive | Upcoming exams widget shows top 5 items sorted by date | 5 |
| TC-PPT-DASH-P10 | Dashboard | Positive | Upcoming exams widget excludes past exams | 3 |
| TC-PPT-DASH-P11 | Dashboard | Positive | Fee summary shows total, paid, due amounts and pending invoice count | 5 |
| TC-PPT-DASH-P12 | Dashboard | Positive | Fee summary shows 0 values when no fee assignment exists | 3 |
| TC-PPT-DASH-P13 | Dashboard | Positive | Leave count shows total and pending count | 4 |
| TC-PPT-DASH-P14 | Dashboard | Positive | Leave count excludes cancelled leaves | 3 |
| TC-PPT-DASH-P15 | Dashboard | Positive | Recent notifications shows 5 most recent items | 4 |
| TC-PPT-DASH-P16 | Dashboard | Positive | Activity log created on dashboard view | 3 |
| TC-PPT-DASH-P17 | Dashboard | Positive | Dashboard shows correct data after switching active child | 3 |

### 11.2 Dashboard — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-DASH-N01 | Dashboard | Negative | Parent with no linked children sees no-access page | 3 |
| TC-PPT-DASH-N02 | Dashboard | Negative | Parent with no academic session sees 0% attendance, empty widgets | 4 |
| TC-PPT-DASH-N03 | Dashboard | Negative | Dashboard renders without timetable cells (no timetable published) | 3 |

### 11.3 My Children — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-CHILD-P01 | My Children | Positive | Children page lists all linked children with name and class-section | 4 |
| TC-PPT-CHILD-P02 | My Children | Positive | Children page shows subject names per class | 4 |
| TC-PPT-CHILD-P03 | My Children | Positive | Children page resolves active child and highlights it | 4 |
| TC-PPT-CHILD-P04 | My Children | Positive | Activity log created on children page view | 3 |

### 11.4 My Children — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-CHILD-N01 | My Children | Negative | Parent with no linked children sees empty list (not crash) | 3 |

### 11.5 Child Switcher — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-SWITCH-P01 | Child Switcher | Positive | POST to switch-child with valid student_id returns JSON success | 4 |
| TC-PPT-SWITCH-P02 | Child Switcher | Positive | ppt_parent_sessions.active_student_id updated after switch | 4 |
| TC-PPT-SWITCH-P03 | Child Switcher | Positive | Dashboard shows new child's data after switch and page reload | 4 |
| TC-PPT-SWITCH-P04 | Child Switcher | Positive | Switch persists after browser refresh (DB-stored) | 4 |
| TC-PPT-SWITCH-P05 | Child Switcher | Positive | Activity log created on child switch | 3 |
| TC-PPT-SWITCH-P06 | Child Switcher | Positive | Multiple sequential switches all succeed | 4 |

### 11.6 Child Switcher — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-PPT-SWITCH-N01 | Child Switcher | Negative | POST with missing student_id returns 422 validation error | 2 |
| TC-PPT-SWITCH-N02 | Child Switcher | Negative | POST with non-existent student_id returns 422 validation error | 2 |
| TC-PPT-SWITCH-N03 | Child Switcher | Negative | POST with unlinked child's student_id returns 403 | 3 |
| TC-PPT-SWITCH-N04 | Child Switcher | Negative | Unauthenticated POST redirects to login | 2 |

### 11.7 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|---|---|---|---|---|
| TC-CR-DASH-01 | Code Review | Review | index() — child resolution via ParentContextService | 4 |
| TC-CR-DASH-02 | Code Review | Review | index() — attendance % computation logic | 6 |
| TC-CR-DASH-03 | Code Review | Review | index() — today's timetable query scope | 5 |
| TC-CR-DASH-04 | Code Review | Review | index() — pending homework query with submission exclusion | 5 |
| TC-CR-DASH-05 | Code Review | Review | index() — upcoming exams future-date filter | 5 |
| TC-CR-DASH-06 | Code Review | Review | index() — fee summary aggregation | 4 |
| TC-CR-DASH-07 | Code Review | Review | index() — leave count status filter | 3 |
| TC-CR-DASH-08 | Code Review | Review | children() — accessible children query | 3 |
| TC-CR-DASH-09 | Code Review | Review | children() — subject loading via 3-join query | 5 |
| TC-CR-DASH-10 | Code Review | Review | switchChild() — SwitchChildParentDashboardRequest validation | 3 |
| TC-CR-DASH-11 | Code Review | Review | switchChild() — error handling with try/catch and JSON response | 4 |
| TC-CR-DASH-12 | Code Review | Review | ParentContextService.resolveChild() — resolution order FSM | 6 |
| TC-CR-DASH-13 | Code Review | Review | ParentContextService.setActiveChild() — ownership assertion | 4 |
| TC-CR-DASH-14 | Code Review | Review | ParentContextService.assertCanAccess() — 403 abort logic | 4 |
| TC-CR-DASH-15 | Code Review | Review | ParentContextService.getOrCreateSession() — session creation logic | 5 |

---

## 12. Test Case Steps

### 12.1 Dashboard Positive Steps

#### TC-PPT-DASH-P01: Dashboard loads for single-child parent

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as parent with exactly one linked child having `can_access_parent_portal = 1` | Authenticated |
| 2 | Navigate to `GET /parent-portal/` | Dashboard page loads |
| 3 | Verify `ParentContextService.resolveChild()` returns the single child directly | Single child shortcut used |
| 4 | Verify all 6 widgets render (attendance %, timetable, homework, exams, fees, leave) + notifications | All sections present |
| 5 | Verify no errors in browser console or Laravel log | Clean load |

#### TC-PPT-DASH-P02: Dashboard loads for multi-child parent with active child from session

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as parent with 2+ linked children | Authenticated |
| 2 | Ensure `ppt_parent_sessions` has `active_student_id` set to a specific child | Session row exists |
| 3 | Navigate to `GET /parent-portal/` | Dashboard loads |
| 4 | Verify the dashboard data corresponds to the child in `active_student_id` | Correct child's data shown |
| 5 | Verify session `last_active_at` is updated | Session touched |

#### TC-PPT-DASH-P03: Attendance % widget — 100% present

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create attendance records for child: 20 records all with status='Present' within academic session | 20 present records |
| 2 | Load dashboard | Attendance widget renders |
| 3 | Verify `attendancePresent = 20`, `attendanceTotal = 20` | 20/20 |
| 4 | Verify `attendancePct = 100` | 100% |

#### TC-PPT-DASH-P04: Attendance % widget — mixed statuses

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create attendance records: 15 Present, 3 Absent, 2 Leave within academic session | 20 records |
| 2 | Load dashboard | Widget renders |
| 3 | Verify `attendancePresent = 15`, `attendanceTotal = 20` | 15/20 |
| 4 | Verify `attendancePct = 75` | 75% |

#### TC-PPT-DASH-P05: Today's timetable widget

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable cells for child's class-section for today's `day_of_week` with PUBLISHED status | 4 cells created |
| 2 | Load dashboard | Timetable widget renders |
| 3 | Verify 4 cells shown with subject, teacher, period, room info | All cells displayed |
| 4 | Verify cells ordered by `period_ord` ascending | Correct order |

#### TC-PPT-DASH-P06: Today's timetable excludes breaks

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create timetable cells for today: 5 regular cells + 1 break cell (`is_break = true`) | 6 cells |
| 2 | Load dashboard | Timetable widget renders |
| 3 | Verify only 5 cells shown (break excluded) | Break filtered out |

#### TC-PPT-DASH-P07: Pending homework — top 5 by due_date

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 8 homework items for child's class-section with various due_dates, all PUBLISHED | 8 homework items |
| 2 | Ensure child has not submitted any of these | No submissions |
| 3 | Load dashboard | Homework widget renders |
| 4 | Verify only 5 items shown (LIMIT 5) | 5 homework items |
| 5 | Verify items ordered by `due_date` ascending | Earliest due first |

#### TC-PPT-DASH-P08: Pending homework excludes submitted

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 3 homework items (HW1, HW2, HW3) for child's class-section | 3 homework items |
| 2 | Create a submission record for HW1 linked to the child | HW1 submitted |
| 3 | Load dashboard | 2 homework items shown (HW2, HW3) |
| 4 | Verify `pendingHomeworkCount = 2` | Count correct |

#### TC-PPT-DASH-P09: Upcoming exams — top 5 sorted by date

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 6 future-dated exam allocations for the child | 6 exams |
| 2 | Load dashboard | Upcoming exams widget renders |
| 3 | Verify 5 items shown (LIMIT 5) | 5 exams |
| 4 | Verify exams sorted by scheduled_date ascending | Earliest first |
| 5 | Verify `upcomingExamCount = 6` | Total count correct |

#### TC-PPT-DASH-P10: Upcoming exams excludes past exams

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 2 future-dated + 3 past-dated exam allocations | 5 total |
| 2 | Load dashboard | Upcoming exams widget renders |
| 3 | Verify only the 2 future exams shown | Past exams filtered out |

#### TC-PPT-DASH-P11: Fee summary with values

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Assign fee assignment to child with 3 invoices: total=₹45,000, paid=₹25,000, balance=₹20,000 | Fee data exists |
| 2 | Set 2 invoices as unpaid, 1 as paid | Mixed statuses |
| 3 | Load dashboard | Fee widget renders |
| 4 | Verify `feeTotal = 45000`, `feePaid = 25000`, `feeDue = 20000` | Aggregates correct |
| 5 | Verify `feePendingInvoices = 2` | 2 unpaid invoices |

#### TC-PPT-DASH-P12: Fee summary — no fee assignment

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure child has no current fee assignment | No fee data |
| 2 | Load dashboard | Fee widget renders |
| 3 | Verify `feeTotal = 0`, `feePaid = 0`, `feeDue = 0`, `feePendingInvoices = 0` | All zeros |

#### TC-PPT-DASH-P13: Leave counts

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 3 leave applications for child: 1 Pending, 1 Approved, 1 Submitted | 3 leaves |
| 2 | Load dashboard | Leave widget renders |
| 3 | Verify `leaveCount = 3` | Total count correct |
| 4 | Verify `leavePendingCount` includes Pending + Submitted statuses | Pending count correct |

#### TC-PPT-DASH-P14: Leave counts — excludes cancelled

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 2 active leaves + 1 cancelled leave for child | 3 total |
| 2 | Load dashboard | 2 leaves counted |
| 3 | Verify `leaveCount = 2` | Cancelled excluded |

#### TC-PPT-DASH-P15: Recent notifications — top 5

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Create 7 notifications for parent user | 7 notifications |
| 2 | Load dashboard | Notification widget renders |
| 3 | Verify 5 notifications shown | LIMIT 5 applied |
| 4 | Verify notifications are 5 most recent (by created_at descending) | Most recent shown |

#### TC-PPT-DASH-P16: Activity log on dashboard view

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load dashboard | Page renders |
| 2 | Query `sys_activity_logs` for action='Viewed' with route='parent-portal.dashboard' | Log entry exists |
| 3 | Verify log contains student_id, student_name, module='ParentPortal' | Context logged |

#### TC-PPT-DASH-P17: Dashboard shows correct data after child switch

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Parent has Child A (attendance=90%) and Child B (attendance=75%) | Two children |
| 2 | Load dashboard — currently showing Child A | Child A data shown |
| 3 | POST `/parent-portal/switch-child` with Child B's student_id | Success |
| 4 | Reload dashboard | Shows Child B's 75% attendance |

### 12.2 Dashboard Negative Steps

#### TC-PPT-DASH-N01: No linked children — no-access redirect

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as parent with zero linked children (no `std_student_guardian_jnt` rows with `can_access_parent_portal = 1`) | Authenticated |
| 2 | Navigate to `GET /parent-portal/` | Redirected to `/parent-portal/no-access` |
| 3 | Verify no-access page shows clear message with contact instructions | Empty state handled gracefully |

#### TC-PPT-DASH-N02: No academic session — empty widgets

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure child has no `currentSession` or no `academic_session_id` | No session |
| 2 | Load dashboard | Dashboard loads without error |
| 3 | Verify attendancePct = 0, todayCells empty, pendingHomework empty, upcomingExams empty | Graceful empty states |

#### TC-PPT-DASH-N03: No timetable published

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Ensure no timetable cells exist for child's class-section (or only draft timetables) | No active timetable |
| 2 | Load dashboard | Dashboard loads without error |
| 3 | Verify timetable widget shows empty state (no cells) | Graceful empty state |

### 12.3 My Children Positive Steps

#### TC-PPT-CHILD-P01: Children page lists all linked children

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Parent has 3 linked children with `can_access_parent_portal = 1` | 3 children |
| 2 | Navigate to `GET /parent-portal/children` | Children page loads |
| 3 | Verify 3 child cards shown | All children listed |
| 4 | Verify each card shows name, class, section info | Data visible |

#### TC-PPT-CHILD-P02: Children page shows subjects per class

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Child A is in Class 7 with subjects: Math, Science, English | Subject group configured |
| 2 | Navigate to children page | Page loads |
| 3 | Verify Child A's section shows "Math, Science, English" subjects | Subjects displayed |
| 4 | Verify subject query uses distinct names (no duplicates) | Distinct subjects |

#### TC-PPT-CHILD-P03: Active child highlighted

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Parent has 2 children; `ppt_parent_sessions.active_student_id` = Child A | Active child set |
| 2 | Navigate to children page | Page loads |
| 3 | Verify `activeId` matches Child A's ID | Correct child highlighted |
| 4 | Verify the active child card has a visual indicator (highlight/selected state) | Visual cue present |

#### TC-PPT-CHILD-P04: Activity log on children page

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Navigate to children page | Page loads |
| 2 | Query activity log for 'Viewed children list' | Log entry exists |
| 3 | Verify student context data logged | Context recorded |

### 12.4 My Children Negative Steps

#### TC-PPT-CHILD-N01: No linked children — empty list

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Log in as parent with zero linked children (or only children with `can_access_parent_portal = 0`) | Authenticated |
| 2 | Navigate to `/parent-portal/children` | Page loads |
| 3 | Verify empty children list with appropriate message (no crash) | Graceful empty state |

### 12.5 Child Switcher Positive Steps

#### TC-PPT-SWITCH-P01: Valid child switch

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST `/parent-portal/switch-child` with `student_id` = valid linked child ID | Request sent |
| 2 | Verify JSON response: `{"status": true, "message": "Child switched."}` | Success |
| 3 | Verify HTTP status = 200 | OK |
| 4 | Verify response is JSON (`Content-Type: application/json`) | JSON response |

#### TC-PPT-SWITCH-P02: Session updated after switch

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Record current `active_student_id` in `ppt_parent_sessions` | Old value noted |
| 2 | POST switch-child with a different child's ID | Success |
| 3 | Query `ppt_parent_sessions` for guardian | `active_student_id` updated to new child's ID |
| 4 | Verify `last_active_at` is updated to current time | Timestamp refreshed |

#### TC-PPT-SWITCH-P03: Dashboard shows new child data after switch + reload

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Load dashboard (Child A data showing) | Initial state |
| 2 | POST switch-child with Child B's ID | Success |
| 3 | Reload `GET /parent-portal/` | Dashboard loads |
| 4 | Verify dashboard data corresponds to Child B (e.g., attendance %, homework) | Child B data |

#### TC-PPT-SWITCH-P04: Switch persists after browser refresh

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST switch-child with Child B's ID | Success |
| 2 | Close browser tab, open new tab, navigate to dashboard | Dashboard loads |
| 3 | Verify dashboard shows Child B's data (not Child A's) | Persisted selection |

#### TC-PPT-SWITCH-P05: Activity log on switch

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST switch-child with valid ID | Success |
| 2 | Query activity log for action='Switched' | Log entry exists |
| 3 | Verify log contains student_id, student_name, module='ParentPortal', route='parent-portal.switch-child' | Context recorded |

#### TC-PPT-SWITCH-P06: Multiple sequential switches

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Parent has 3 children: A, B, C | 3 children |
| 2 | Switch to B → success → switch to C → success → switch to A → success | All succeed |
| 3 | Verify final active child = A | All three worked |

### 12.6 Child Switcher Negative Steps

#### TC-PPT-SWITCH-N01: Missing student_id

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST `/parent-portal/switch-child` with empty body (no student_id) | Request sent |
| 2 | Verify HTTP 422 with validation error: "The student id field is required." | Validation error |

#### TC-PPT-SWITCH-N02: Non-existent student_id

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST `/parent-portal/switch-child` with `student_id = 99999` (non-existent) | Request sent |
| 2 | Verify HTTP 422: "The selected student id is invalid." | Validation error |

#### TC-PPT-SWITCH-N03: Unlinked child — 403

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST `/parent-portal/switch-child` with `student_id` of a child NOT linked to this parent | Request sent |
| 2 | Verify HTTP 403: "You are not authorised to view this child's data." | Forbidden |

#### TC-PPT-SWITCH-N04: Unauthenticated — redirect to login

| Step # | Action | Expected Result |
|---|---|---|
| 1 | POST `/parent-portal/switch-child` without authentication | Not authenticated |
| 2 | Verify redirect to `/login` | Auth guard triggered |

### 12.7 Code Review Steps

#### TC-CR-DASH-01: index() — child resolution

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$this->context->resolveChild($request)` at top of method | Child resolved |
| 2 | Review that all subsequent queries use `$child->id` for scoping | Child ID used |
| 3 | Review fallback: if no child, system flow | Redirect/no-access handled |
| 4 | Review activity log call at end of method | Logged |

#### TC-CR-DASH-02: index() — attendance % computation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$session?->academic_session_id` guard | Session check |
| 2 | Review StudentAttendance query with student_id + academic_session_id | Filtered query |
| 3 | Review present status filter: `['Present', 'P', 'present']` | Status normalization |
| 4 | Review percentage computation: `round(($present / $total) * 100)` | Percentage calc |
| 5 | Review division by zero guard: `$total > 0 ? ... : 0` | Safe division |
| 6 | Review default values of 0 when session is null | Initial values |

#### TC-CR-DASH-03: index() — timetable query

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$session?->classSection` guard | Section check |
| 2 | Review `TimetableCell::whereHas('activity', class+section)` | Activity filter |
| 3 | Review status filter: `['ACTIVE', 'GENERATED', 'PUBLISHED']` | Status filter |
| 4 | Review `where('day_of_week', now()->dayOfWeek)` | Today filter |
| 5 | Review `->filter(fn ($c) => !$c->is_break)` | Break exclusion |

#### TC-CR-DASH-06: index() — fee summary aggregation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `$child->currentFeeAssignemnt` (note: typo in property name 'Assignemnt' vs 'Assignment') | Typo present |
| 2 | Review sum of total_amount, paid_amount, balance_amount across invoices | Aggregate sums |
| 3 | Review pending invoice count: `->whereNotIn('status', ['paid', 'PAID', 'Paid'])` | Case-insensitive filter |
| 4 | Review float casting: `(float) $invoices->sum(...)` | Type casting |

#### TC-CR-DASH-13: ParentContextService.setActiveChild() — ownership assertion

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `Student::findOrFail($studentId)` | Student exists |
| 2 | Review `$this->assertCanAccess($request->user(), $student)` | Ownership check |
| 3 | Review `$session->update(['active_student_id' => $studentId, 'last_active_at' => now()])` | Session update |
| 4 | Review `ParentSession::getOrCreateSession()` for guardian without session | Session created if missing |

#### TC-CR-DASH-15: ParentContextService.getOrCreateSession() — session creation

| Step # | Action | Expected Result |
|---|---|---|
| 1 | Review `where('guardian_id', $guardian->id)->where('is_active', true)->latest()->first()` | Finds latest active session |
| 2 | Review `if ($session) { update last_active_at; return }` | Existing session refreshed |
| 3 | Review `ParentSession::create([...])` for new session | New session created |
| 4 | Review `device_type = 'Web'` default | Web default |
| 5 | Review `is_active = true` on create | Active by default |
