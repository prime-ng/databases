# Homework & Assignments — Parent Portal (Read-Only)

## What This Screen Does

The Homework & Assignments screen in the Parent Portal gives parents a read-only view of all homework and assignments given to their active child. It is a monitoring and oversight tool — parents can see what homework has been assigned, whether it is pending, submitted, overdue, or graded, and view the details of any specific assignment. They cannot create, edit, submit, or grade homework from this portal.

The screen pulls all its data from the `LmsHomework` module (specifically `hmw_assignments` and `hmw_submissions`). Every assignment shown here is gated by the `is_released` flag — only assignments that the teacher has explicitly released to the student are visible. Each assignment is linked to a specific homework record from `lms_homework`, which provides the subject, title, description, due date, difficulty level, and any attached reference files.

---

## When This Screen Is Used

- **End of Day Check:** A parent wants to see what homework their child was assigned today and what the due dates look like for the week ahead.
- **Submission Follow-Up:** A parent checks whether their child has submitted an assignment that was due yesterday.
- **Overdue Awareness:** A parent sees a red "Overdue" badge and can discuss with their child why the homework was not submitted on time.
- **Graded Work Review:** A parent checks the marks their child received on a recently graded assignment and sees the teacher's feedback.

---

## Default Data Load

When the parent navigates to the Homework tab, the system loads their active child's `ParentContextService::resolveChild()` and fetches all released and active `HomeworkAssignment` records for that child. These are bucketed into five categories:

- **Pending (default tab):** Assignments with no submission and due date in the future.
- **Overdue:** Assignments with no submission and due date in the past.
- **Submitted:** Assignments with a submission record (regardless of grading status).
- **Graded:** Assignments with submission where `marks_obtained` is set.
- **All:** Every assignment without filtering.

Each bucket is pre-computed on the server and passed to the view, so the parent can switch between tabs without a page reload. A count badge is shown for each tab.

---

## Key Fields at a Glance

**Subject** — Every assignment belongs to a school subject (e.g., Mathematics, Science, English). The subject name is pulled from the homework's relationship chain: `HomeworkAssignment → homework → subject → name`.

**Title & Description** — The homework title (e.g., "Chapter 5: Chemical Reactions — Practice Questions") is the primary label. The description provides the detailed instructions the teacher wrote. Both are read-only.

**Due Date** — The date by which the assignment must be submitted. Assignments past due with no submission are flagged "Overdue". The list is ordered by `due_date` ascending.

**Status Badges** — Each assignment gets a status badge computed client-side from bucket membership:
- **Pending** (blue): Not yet submitted, due date in the future.
- **Overdue** (red): Not yet submitted, due date has passed.
- **Submitted** (amber): Submission exists but not yet graded.
- **Graded** (green): Submission exists with marks obtained.

**Difficulty Level** — Shows Easy, Medium, or Hard based on the homework's linked difficulty level.

**Attachments** — On the detail view (`show`), the parent can see and download any reference files the teacher attached (stored via Spatie Media Library in the `homework_files` collection).

---

## Business Rules and Conditions

**Read-Only by Design — No Submit Action**
This feature is a pure read-aggregation over `LmsHomework` data. The parent cannot submit homework on behalf of the child, cannot extend due dates, and cannot contact the teacher from this screen. All such actions must happen through the child's Student Portal or the school admin.

**Data Source Is Released Assignments Only**
The query filters `HomeworkAssignment` where `is_released = true` and `is_active = true`. If a teacher has saved a homework as a draft or published it but not yet released individual assignments, the parent will not see it. This matches exactly what the child sees in their Student Portal (`StudentLmsController`).

**Five Pre-Computed Buckets**
All five buckets (Pending, Overdue, Submitted, Graded, All) are computed server-side using Eloquent collection filtering. The view receives fully filtered collections; no additional client-side filtering calls the server. This ensures fast tab switching.

**No Custom Validation Rules**
This controller does not process any user input besides the query string `tab` parameter (default: `pending`). There is no FormRequest, no POST handler, and no data mutation. The `tab` parameter is passed directly to the view for initial tab selection; the view handles tab switching client-side.

**No Pagination**
The full set of assignments is loaded in one query and filtered in-memory. This is acceptable because the expected volume of assignments per child per academic session is under 100.

---

## Workflow Steps

**Viewing the Homework List**
The parent navigates to Homework from the Parent Portal sidebar. The system calls `ParentHomeworkController::index()`, which resolves the active child via `ParentContextService`, queries all released assignments, buckets them, and renders the view. The parent sees the Pending tab by default.

**Switching Between Tabs**
The parent clicks a tab (Pending, Overdue, Submitted, Graded, or All). Since all five buckets are already loaded in the page data, tab switching happens entirely in the browser via JavaScript — no additional server request is made. The count badge next to each tab updates in real-time based on the pre-loaded data.

**Viewing Assignment Details**
The parent clicks an assignment to open `ParentHomeworkController::show($id)`. The system verifies that the assignment belongs to the active child (`student_id` match), loads the assignment with its subject, difficulty level, submission, and media attachments, and renders the detail view. The parent can see the full description, due date, submission status, and any attached files.

---

## Example Scenario

**Scenario: End-of-Day Homework Check**

Mrs. Kapoor logs into the Parent Portal after dinner to check if her daughter Ananya (Grade 7-A) has homework to complete. She clicks the Homework tab. The screen shows the Pending tab by default, listing three assignments:

1. **Mathematics** — "Chapter 12: Algebra Exercise 12.3" — Due: 25 July 2026
2. **Science** — "Diagram of Human Heart" — Due: 26 July 2026
3. **English** — "Book Report on The Hobbit" — Due: 28 July 2026

Each assignment shows a blue "Pending" badge. The Overdue tab has 0 items. The Submitted tab shows one item: "History — Mughal Empire Timeline" with an amber "Submitted" badge (not yet graded).

Mrs. Kapoor clicks the Mathematics assignment to see the details: the teacher's description, a note that the submission type is "Text," and a reference PDF titled "Algebra_Worksheet.pdf" which she can download to help Ananya practice.

The next morning, she sees that the History assignment has moved from Submitted to Graded — it now shows a green "Graded" badge with a score of 18/20.

---

## Related Screens

- **Parent Dashboard** (homework count widget linking to Homework tab)
- **Homework Detail View** (accessed by clicking any assignment)
- **Student Portal Homework** (mirrors same data for the child's view)

---

## Business Conditions

### 5.1 Database Schema — `hmw_assignments` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-02 | homework_id | INT UNSIGNED FK | NOT NULL, FK → `lms_homework.id` |
| BC-DB-03 | student_id | INT UNSIGNED FK | NOT NULL, FK → `std_students.id` |
| BC-DB-04 | is_released | TINYINT(1) | NOT NULL, DEFAULT 0 |
| BC-DB-05 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-06 | due_date | DATETIME | NOT NULL |
| BC-DB-07 | created_at | TIMESTAMP | NULL |
| BC-DB-08 | updated_at | TIMESTAMP | NULL |
| BC-DB-09 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.2 Database Schema — `hmw_submissions` (Read-Only)

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-10 | id | INT UNSIGNED PK | Auto-increment |
| BC-DB-11 | homework_assignment_id | INT UNSIGNED FK | NOT NULL, FK → `hmw_assignments.id` |
| BC-DB-12 | marks_obtained | DECIMAL(5,2) | NULL |
| BC-DB-13 | submitted_at | DATETIME | NOT NULL |
| BC-DB-14 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-15 | deleted_at | TIMESTAMP | NULL (soft delete) |

### 5.3 Authorization

| BC ID | Rule | Behavior |
|-------|------|----------|
| BC-AUTH-01 | Parent must be authenticated | Unauthenticated → redirect to login |
| BC-AUTH-02 | Child ownership check | `ParentContextService::resolveChild()` enforces guardian→child linkage |
| BC-AUTH-03 | Assignment ownership | `show()` verifies `student_id` matches active child ID |
| BC-AUTH-04 | Released assignments only | Query filters `is_released = true` |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Tab parameter defaults to 'pending' | If no `?tab=` query, show pending assignments |
| BC-BIZ-02 | Bucket empty state | Tab with 0 items shows "No assignments" message |
| BC-BIZ-03 | Orphaned homework | Assignments with `homework_id` pointing to a deleted homework are filtered out (null check) |
| BC-BIZ-04 | Assignment not found or wrong child | `show()` returns 404 via `firstOrFail()` if ID does not belong to this child |
| BC-BIZ-05 | Activity logged | Every `index()` and `show()` call logs a "Viewed" entry in `sys_activity_logs` |
| BC-BIZ-06 | Due date comparison | Overdue bucket uses `due_date < now()` (Carbon comparison) |
| BC-BIZ-07 | Submission existence check | `$a->submission !== null` determines Submitted/Graded vs Pending/Overdue |

### 5.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | homework_id | lms_homework | CASCADE |
| BC-REF-02 | student_id | std_students | CASCADE |
| BC-REF-03 | homework_assignment_id | hmw_assignments | CASCADE |

---

## Validation Rules

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | tab (query) | in:pending,overdue,submitted,graded,all (server passes raw to view) | N/A — tab switching is client-side |
| BC-VAL-02 | id (route) | exists:hmw_assignments,id with student_id scope | 404 via `firstOrFail()` |

---

## V1/V2 Gaps

| Gap | Type | Description | Impact |
|-----|------|-------------|--------|
| ParentChildPolicy MISSING | P0 Security | No global ownership policy applied to HomeworkController; relies on `resolveChild()` + manual `student_id` check in `show()` | Low — both `index()` and `show()` verify child ownership |
| No overdue push notification | P2 Enhancement | BR-PPT-007 implies overdue notification, but no push is implemented from the controller | Parents must visit portal to see overdue status |

---

## Module Integration

| Integration | Direction | Details |
|-------------|-----------|---------|
| LmsHomework | Read | `HomeworkAssignment` model, `Homework` model with subject, difficulty level |
| ParentContextService | Read | Child resolution by guardian→student linkage |
| Spatie Media Library | Read | `homework_files` collection for attachment downloads |
| sys_activity_logs | Write | Audit log on every view |

---

## Known Limitations

- No sorting, filtering, or search controls in the view — assignments are ordered by `due_date` ascending
- No pagination — all assignments loaded in one query
- No submit action — parent cannot submit homework on child's behalf
- No teacher contact from this screen — messaging is a separate feature

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-07-23 | AI | Initial requirement doc from live code audit + FRD analysis |

---

*End of ppt_Homework_Requirement.md*
