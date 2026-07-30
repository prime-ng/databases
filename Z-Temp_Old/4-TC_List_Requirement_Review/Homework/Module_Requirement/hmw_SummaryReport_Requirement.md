# Homework Summary Report — Business Requirements

## What This Screen Does

The Homework Summary Report gives teachers and administrators a per-homework breakdown of submission and grading progress. While the Analytics Dashboard shows high-level numbers (like total submissions across all homework), this screen shows the same kind of data but broken down homework by homework — like a report card for each homework assignment.

For every homework in the list, the summary shows four key numbers:
1. **Assigned:** How many students were assigned this homework (total assignment records created).
2. **Submitted:** How many of those students actually submitted their work.
3. **Checked (Graded):** How many submissions have been graded by the teacher.
4. **Reassigned (Resubmission Requested):** How many students were asked to redo their work.

These four numbers give a complete picture of each homework's lifecycle at a glance. A teacher can quickly see which homework have low submission rates (many assigned but few submitted), which ones have a grading backlog (many submitted but few checked), and which ones have students who need to resubmit (reassigned count).

The screen is filterable by class, section, subject, and date range, and searchable by homework title or topic name. This makes it easy to narrow down to specific areas of concern.

---

## When This Screen Is Used

- **Per-Homework Progress Check:** A teacher wants to see the submission and grading status for a specific homework.
- **Identifying Problem Homework:** An administrator wants to find homework with unusually low submission rates or high resubmission rates.
- **Grading Backlog Management:** A HOD wants to identify teachers who have a large number of graded submissions pending.
- **End-of-Term Review:** An Academic Coordinator reviews the summary to evaluate overall homework completion rates for the term.
- **Parent-Teacher Meeting Preparation:** A teacher prints or reviews the summary to discuss homework performance with parents.

---

## Default Data Load

When a teacher navigates to the Summary tab, the system loads all homework records that have associated assignment data. Each row in the table shows: the homework title (with topic name below), the subject, the class and section, and the four key counts (Assigned, Submitted, Checked, Reassigned). The list is paginated at 20 items per page and ordered with the most recent homework first.

A filter bar at the top allows the teacher to narrow down results by Class, Section, Subject, and Date Range. A search box lets them type a homework title or topic name to find specific entries.

---

## Key Metrics at a Glance

**Homework Title and Topic**
Each row starts with the homework title in bold text. Below it, if the homework was linked to a syllabus topic, the topic name is shown in smaller grey text. This helps teachers quickly identify what each homework covers.

**Subject and Class/Section**
The subject name is displayed along with the target class and optional section. This provides context for where the homework was assigned.

**Assigned Count**
This is the total number of students who received this homework. It matches the number of assignment records created when the homework was published. For example, if the homework was published to a class of 35 students, the assigned count is 35.

**Submitted Count**
This is the number of students who actually submitted their work. A submitted count significantly lower than the assigned count indicates a problem with submission compliance.

**Checked (Graded) Count**
This is the number of submissions that have been graded by the teacher. A checked count significantly lower than the submitted count indicates a grading backlog — the teacher has not yet graded all the submissions.

**Reassigned (Resubmission Requested) Count**
This is the number of students who were asked to resubmit their work. A high resubmission count might indicate that the homework was too difficult or that the instructions were unclear.

---

## Business Rules and Conditions

**Assigned Count:** Count of HomeworkAssignment records for this homework. This equals the number of enrolled students at the time of publishing (or the total after any re-publishes).

**Submitted Count:** Count of assignments that have a related submission record where submitted_at is not null. This means the student has actually submitted work, not just viewed the assignment.

**Checked Count:** Count of assignments whose related submission has a graded_at timestamp (not null). This means the teacher has graded the submission.

**Reassigned Count:** Count of assignments whose related submission has is_resubmission_requested set to true. This means the teacher asked the student to redo the work.

**Only Active Homework Is Shown**
The summary only includes homework where is_active = 1. Inactive or soft-deleted homework is excluded from the report.

**Filters Apply to All Counts Consistently**
When a filter is selected (for example, choosing Class 10), the system first finds all homework that match the filter. Then it computes the four counts for only those homework. The counts are always consistent — the submitted count for a homework can never exceed its assigned count, and the checked count can never exceed the submitted count.

---

## Example Scenario

**Scenario: End-of-Week Homework Review**

Ms. Sharma is the HOD for the Science department. She opens the Summary tab to review homework progress across all Science classes for the week. She filters by Subject: Science and Date Range: This Week.

She sees 8 homework entries. She quickly scans the numbers:

| Homework | Assigned | Submitted | Checked | Reassigned |
|----------|----------|-----------|---------|------------|
| Chemical Reactions (8-A) | 35 | 30 | 28 | 1 |
| Quadratic Equations (10-B) | 38 | 20 | 15 | 0 |
| Photosynthesis (7-A) | 32 | 30 | 30 | 2 |
| ... | ... | ... | ... | ... |

**Observations:**
1. "Chemical Reactions" has 35 assigned, 30 submitted, 28 checked, 1 reassigned — good progress.
2. "Quadratic Equations" has 38 assigned, only 20 submitted, and 15 checked. The submission rate is low (53%). Ms. Sharma notes this and will discuss with the teacher.
3. "Photosynthesis" has all 30 submissions checked, but 2 were reassigned — she will check whether the resubmissions have been completed.

**Action Taken:**
Ms. Sharma clicks on "Quadratic Equations" to investigate further. She sees that the due date has not passed yet, so some students may still submit. She decides to send a reminder to the Class 10-B teacher about the low submission rate.

---

## Related Screens

- **Homework Analytics Dashboard** — Shows high-level aggregated metrics (complementary to this per-homework view).
- **Homework Management** — Where homework details can be viewed and edited.
- **Assignment Tracking** — Shows per-student assignment details for a specific homework.

---

## Requirements

**Controller:** Modules\LmsHomework\Http\Controllers\LmsHomeworkController
- Logic is embedded in index() when 	ab === 'home_work_summary'
- Also has a standalone summary() method that returns the same data
- Filter flow: Build a HomeworkAssignment query with filters → extract matching homework_id values → query Homework with withCount for the four aggregate columns

**Models Used:**
- HomeworkAssignment (lms_homework_assignment) — Used for the initial filtered query to get matching homework IDs
- Homework (lms_homework) — Main query with withCount for assignments_count, submitted_count, checked_count, reassigned_count

**Policy:** HomeworkSummaryPolicy (permission group: 	enant.home-work-summary.*)
- Note: This policy exists on disk but is NOT registered in the ServiceProvider. Authorization works at runtime because Gate::authorize() uses string-based permission checks against the user's role/permissions, not against a policy class.

**Routes:**
- Default: Handled via index() with 	ab=home_work_summary parameter
- Standalone: GET /summary → LmsHomeworkController@summary()

**Tab Integration:**
- Tab ID: home_work_summary
- Tab permission: 	enant.home-work-summary.viewAny
- Guard: @can('tenant.home-work-summary.viewAny') around @include('lmshomework::summary.index')

---

## Who Can Access This Screen

| Role | What They Can See | Permission Needed |
|------|------------------|-------------------|
| Teacher | Summary for their own classes and homework | 	enant.home-work-summary.viewAny |
| School Admin | Summary for all homework across all classes | 	enant.home-work-summary.viewAny |

---

## How This Screen Works — Logic Flow (Non-Technical)

When a user clicks on the Summary tab, the system first checks whether any filters are active. It builds a query on the HomeworkAssignment table (not the Homework table directly) because the assignment table contains the denormalized class, section, and subject fields needed for filtering.

The system applies any active filters (class, section, subject, date range) and a search term if provided. From this filtered query, it extracts a list of unique homework IDs. Then it queries the Homework table for only those IDs, requesting four additional counts using sub-queries:
1. Total assignments (simple count of related assignment records)
2. Submitted assignments (count of assignments where a submission exists with a submitted_at timestamp)
3. Checked assignments (count of assignments whose submission has a graded_at timestamp)
4. Reassigned assignments (count of assignments whose submission has the resubmission flag set to true)

The results are sorted with the newest homework first and paginated at 20 per page. The system renders the tab content within the hub view.

When the user applies a filter or changes the search term, the page reloads with the new parameters, and the entire query runs again with the updated conditions.

---

## Error Handling and Validation Messages

| Scenario | What the User Sees | Type |
|----------|-------------------|------|
| No homework matches the selected filters | "No records found." message displayed in the table | Informational — empty state |
| Invalid date range | "Please select a valid date range." | Validation |

---

## Success Scenarios

**SC-001 — Summary Loads with Correct Data**
Ms. Sharma opens the Summary tab. The table loads with 15 homework entries, each showing correct assigned/submitted/checked/reassigned counts. The numbers are consistent (submitted ≤ assigned, checked ≤ submitted).

**SC-002 — Filters Work Correctly**
Ms. Sharma filters by Class 10 and Subject Science. The table updates to show only Science homework for Class 10, each with correct counts.

**SC-003 — Search Finds Specific Homework**
Ms. Sharma types "Chemical" in the search box. The table updates to show only homework with "Chemical" in the title or topic name.

**SC-004 — Empty State for New Class**
A new class with no homework shows an empty table with "No records found." — no errors, just a clean empty state.

---

## Failure Scenarios

**FC-001 — User Without Permission**
If a user does not have the 	enant.home-work-summary.viewAny permission, the Summary tab is hidden from the hub view. If they try to access it via direct URL, they receive a 403 Forbidden error.

**FC-002 — Homework with Zero Assignments**
A homework that was created but never published has zero assignments. The summary row shows 0 for all four counts. This is correct behavior — the homework was never assigned to any students.

---

## Dependencies module and tables

| Module | Tables Used | Why |
|--------|-------------|-----|
| LmsHomework | lms_homework, lms_homework_assignment, lms_homework_submissions | All four summary counts are computed from these tables |
| SchoolSetup | sch_classes, sch_sections, sch_subjects | Filter dropdowns and display names |
| Syllabus | slb_topics | Topic name display and topic search |
