# ppt_Homework_TcList

## Module: ParentPortal → Homework → Homework & Assignments (Read-Only)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | ParentPortal |
| Tab Group | Homework |
| Feature | Homework & Assignments (Read-Only View) |
| URL(s) | `GET /parent-portal/homework` (route: `parent-portal.homework.index`)<br>`GET /parent-portal/homework/{id}` (route: `parent-portal.homework.show`) |
| Controller | `Modules\ParentPortal\Http\Controllers\ParentHomeworkController` |
| Model(s) | `Modules\LmsHomework\Models\HomeworkAssignment` (table: `hmw_assignments`) |
| FormRequest | None (no POST/PUT actions) |
| Policy / Permissions | No explicit policy — scoped via `ParentContextService::resolveChild()` |
| Soft Deletes | Yes (`HomeworkAssignment` uses `SoftDeletes`) |
| Activity Log | `activityLog()` calls in `index()` and `show()` with action "Viewed" |
| View(s) | `parentportal::homework.index`, `parentportal::homework.show` |

---

## 2. Pre-conditions

- Parent must be authenticated and logged into a tenant (school)
- Parent must have at least one linked child with `can_access_parent_portal = 1` in `std_student_guardian_jnt`
- Tenant must have `LmsHomework` module active (data sourced from `hmw_assignments` + `hmw_submissions`)
- At least one `HomeworkAssignment` record must exist for the active child with `is_released = true` and `is_active = true`
- Dusk environment: `DUSK_TENANT_URL`, `DUSK_GUARDIAN_EMAIL`, `DUSK_GUARDIAN_PASSWORD`

---

## 3. Default Data Load

When the page loads via `ParentHomeworkController@index()`:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| All Assignments | `HomeworkAssignment` | `where('student_id', $child->id)->where('is_released', true)->where('is_active', true)->with(['homework.subject','homework.difficultyLevel','submission'])->orderBy('due_date')` | `is_released=1`, `is_active=1`, student_id | None (full set) |
| Pending Bucket | In-memory filter | `->filter(fn($a) => $a->submission === null && $a->due_date >= now())` | No submission, due in future | None |
| Overdue Bucket | In-memory filter | `->filter(fn($a) => $a->submission === null && $a->due_date < now())` | No submission, due past | None |
| Submitted Bucket | In-memory filter | `->filter(fn($a) => $a->submission !== null)` | Has submission | None |
| Graded Bucket | In-memory filter | `->filter(fn($a) => $a->submission !== null && $a->submission->marks_obtained !== null)` | Has submission with marks | None |
| All Bucket | Full collection | All assignments after null-homework filter | None | None |

> **Note:** The initial `$tab` parameter defaults to `'pending'`. Bucket counts are passed to the view for tab badges.

---

## 4. Test Data Strategy

- Create `HomeworkAssignment` records directly via the `HomeworkAssignment` factory or DB seed (this is a read-only feature)
- Ensure assignments cover all five bucket conditions:
  - Pending: `submission_id = null`, `due_date > now()`
  - Overdue: `submission_id = null`, `due_date < now()`
  - Submitted: `submission_id = not null`, `marks_obtained = null`
  - Graded: `submission_id = not null`, `marks_obtained = not null`
- Create assignments with orphaned `homework_id` (null relation) to verify the `->filter(fn($a) => $a->homework !== null)` guard
- Use a unique student per parent for child-switch testing
- Pre-test cleanup: Deactivate or soft-delete test assignments after verification

---

## 5. Business Conditions

### 5.1 Database Schema — `hmw_assignments` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | homework_id | INT UNSIGNED FK | NOT NULL, FK → `lms_homework.id` ON DELETE CASCADE |
| BC-DB-03 | student_id | INT UNSIGNED FK | NOT NULL, FK → `std_students.id` ON DELETE CASCADE |
| BC-DB-04 | is_released | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-06 | due_date | DATETIME | NOT NULL |
| BC-DB-07 | created_at | TIMESTAMP | NULL |
| BC-DB-08 | updated_at | TIMESTAMP | NULL |
| BC-DB-09 | deleted_at | TIMESTAMP | NULL |

### 5.2 Authorization

| BC ID | Rule | Expected Behavior |
|-------|------|-------------------|
| BC-AUTH-01 | Guest access | Redirect to login |
| BC-AUTH-02 | No linked children | `resolveChild()` throws/redirects — see no-access page |
| BC-AUTH-03 | Assignment belongs to wrong child | `show()` returns 404 (`firstOrFail` scoped to child) |
| BC-AUTH-04 | Released assignments only | Non-released assignments excluded from index |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Default tab is 'pending' | First load shows pending assignments |
| BC-BIZ-02 | No assignments at all | All buckets empty; proper empty states rendered |
| BC-BIZ-03 | Bucket with 0 items | Count badge shows 0; tab content area shows "No assignments" |
| BC-BIZ-04 | Orphaned homework (null relation) | Assignment excluded from all buckets |
| BC-BIZ-05 | Assignment show — correct child | Detail page renders with full assignment + attachments |
| BC-BIZ-06 | Assignment show — wrong child ID | HTTP 404 (firstOrFail scoped to child) |
| BC-BIZ-07 | Due date boundary (exactly now) | Assignment falls into Pending (>= now) |
| BC-BIZ-08 | Activity log on index | sys_activity_logs contains "Viewed homework list" entry |
| BC-BIZ-09 | Activity log on show | sys_activity_logs contains "Viewed homework assignment" entry |
| BC-BIZ-10 | Multiple children — switch child | Homework list reloads for new active child |

### 5.4 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | homework_id | lms_homework | CASCADE |
| BC-REF-02 | student_id | std_students | CASCADE |

---

## 6. Test Scenarios

| TC ID | Scenario | Description | Priority |
|-------|----------|-------------|----------|
| TC-HW-001 | Load homework list (default tab) | Verify pending tab is default and all 5 buckets are present | P0 |
| TC-HW-002 | All buckets populated | Create at least 1 assignment in each status; verify counts and badges | P1 |
| TC-HW-003 | Empty homework list | Parent with no assignments sees empty state, no crash | P1 |
| TC-HW-004 | View assignment detail | Click assignment → detail page shows title, subject, due date, attachments | P0 |
| TC-HW-005 | View assignment — wrong child ID | Attempt to access assignment belonging to another child → 404 | P0 |
| TC-HW-006 | Orphaned homework filtered out | Create assignment with deleted homework → excluded from index | P2 |
| TC-HW-007 | Non-released assignment hidden | `is_released = false` → not visible | P1 |
| TC-HW-008 | Activity logging verified | Check sys_activity_logs after index and show | P1 |
| TC-HW-009 | Tab parameter respects query string | `?tab=overdue` shows overdue tab | P1 |
| TC-HW-010 | Attachment download | Verify media attachment link renders on show page | P2 |

---

## 7. Test Cases

| TC ID | Test Case | Steps | Expected Result |
|-------|-----------|-------|-----------------|
| TC-HW-001-01 | Verify homework index loads with pending tab | 1. Login as parent<br>2. Navigate to `/parent-portal/homework`<br>3. Observe default tab | Default tab is "Pending" with 5 bucket tabs visible |
| TC-HW-001-02 | Verify all 5 bucket counts correct | 1. Create 1 pending, 1 overdue, 1 submitted, 1 graded assignment<br>2. Navigate to homework index<br>3. Check badge counts | Counts match: Pending=1, Overdue=1, Submitted=1, Graded=1, All=4 |
| TC-HW-002-01 | Pending bucket shows non-submitted future assignments | 1. Create assignment with due_date in future, no submission<br>2. Navigate to Pending tab<br>3. Verify assignment listed | Pending tab shows exactly 1 item with blue "Pending" badge |
| TC-HW-002-02 | Overdue bucket shows non-submitted past assignments | 1. Create assignment with due_date in past, no submission<br>2. Navigate to Overdue tab<br>3. Verify assignment listed | Overdue tab shows exactly 1 item with red "Overdue" badge |
| TC-HW-002-03 | Submitted bucket shows submitted ungraded assignments | 1. Create assignment with submission, marks_obtained=null<br>2. Navigate to Submitted tab<br>3. Verify assignment listed | Submitted tab shows exactly 1 item with amber "Submitted" badge |
| TC-HW-002-04 | Graded bucket shows graded assignments | 1. Create assignment with submission, marks_obtained=18<br>2. Navigate to Graded tab<br>3. Verify assignment listed, marks shown | Graded tab shows exactly 1 item with green "Graded" badge, marks 18 |
| TC-HW-003-01 | Empty homework list | 1. Ensure no assignments for active child<br>2. Navigate to homework index<br>3. Observe all tabs | All tabs show "No assignments" message; no 500 error |
| TC-HW-004-01 | View assignment detail | 1. Click on a pending assignment<br>2. Observe detail page | Page shows: title, subject, description, due date, difficulty level, attachments |
| TC-HW-004-02 | Attachments visible | 1. Create assignment with 1 media attachment<br>2. Navigate to show page<br>3. Look for download links | Attachment file(s) visible and downloadable |
| TC-HW-005-01 | Wrong child — 404 | 1. Get assignment ID for a different student<br>2. Attempt `/parent-portal/homework/{other_child_id}`<br>3. Observe response | HTTP 404 returned |
| TC-HW-006-01 | Orphaned assignment hidden | 1. Create assignment with homework_id pointing to deleted homework<br>2. Navigate to index<br>3. Check all buckets | Assignment not present in any bucket |
| TC-HW-007-01 | Non-released assignment invisible | 1. Create assignment with is_released=0<br>2. Navigate to index | Assignment not shown |
| TC-HW-008-01 | Activity log entry for index | 1. Navigate to homework index<br>2. Query sys_activity_logs for current user + route | Entry found with message "Viewed homework list" and student_id |
| TC-HW-008-02 | Activity log entry for show | 1. Navigate to homework show<br>2. Query sys_activity_logs for current user + route | Entry found with message "Viewed homework assignment" and assignment ID |
| TC-HW-009-01 | Tab query parameter | 1. Navigate to `/parent-portal/homework?tab=overdue`<br>2. Observe active tab | Overdue tab is selected on page load |

---

## 8. Known Issues

| # | Issue | Severity | Status | Notes |
|---|-------|----------|--------|-------|
| 1 | ParentChildPolicy MISSING | P0 | ⬜ Open | No global ownership policy; relies on `resolveChild()` + scoped queries |
| 2 | No overdue push notification | P2 | ⬜ Open | Parents must visit portal to see overdue assignments |
| 3 | No pagination on assignments | P2 | ⬜ Open | All assignments loaded in one query; potential memory issue for large sets |
| 4 | No search or filter controls | P2 | ⬜ Open | Parents cannot search by subject or date range |

---

## 9. Route Reference

| Method | URI | Name | Controller@Method | Middleware |
|--------|-----|------|-------------------|------------|
| GET | `/parent-portal/homework` | `parent-portal.homework.index` | ParentHomeworkController@index | web, auth, tenant, verified, ParentPortalMiddleware |
| GET | `/parent-portal/homework/{id}` | `parent-portal.homework.show` | ParentHomeworkController@show | web, auth, tenant, verified, ParentPortalMiddleware |

---

## 10. Execution Status

| TC ID | Test Case | Status (⬜/🟨/🟩/🟥) | Tester | Date | Remarks |
|-------|-----------|----------------------|--------|------|---------|
| TC-HW-001-01 | Verify homework index loads with pending tab | ⬜ | — | — | — |
| TC-HW-001-02 | Verify all 5 bucket counts correct | ⬜ | — | — | — |
| TC-HW-002-01 | Pending bucket shows non-submitted future assignments | ⬜ | — | — | — |
| TC-HW-002-02 | Overdue bucket shows non-submitted past assignments | ⬜ | — | — | — |
| TC-HW-002-03 | Submitted bucket shows submitted ungraded assignments | ⬜ | — | — | — |
| TC-HW-002-04 | Graded bucket shows graded assignments | ⬜ | — | — | — |
| TC-HW-003-01 | Empty homework list | ⬜ | — | — | — |
| TC-HW-004-01 | View assignment detail | ⬜ | — | — | — |
| TC-HW-004-02 | Attachments visible | ⬜ | — | — | — |
| TC-HW-005-01 | Wrong child — 404 | ⬜ | — | — | — |
| TC-HW-006-01 | Orphaned assignment hidden | ⬜ | — | — | — |
| TC-HW-007-01 | Non-released assignment invisible | ⬜ | — | — | — |
| TC-HW-008-01 | Activity log entry for index | ⬜ | — | — | — |
| TC-HW-008-02 | Activity log entry for show | ⬜ | — | — | — |
| TC-HW-009-01 | Tab query parameter | ⬜ | — | — | — |

---

*End of ppt_Homework_TcList.md*
