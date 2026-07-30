# Progress Tracker — Business Requirements

## What This Screen Does

The Progress Tracker is a highly detailed, tabular report that breaks down syllabus completion at the most granular level possible. While the Overview Dashboard shows high-level gauges and pie charts, the Progress Tracker lists every single Lesson, Topic, and Micro-Topic, showing exactly when it was planned versus when it was actually taught.

It serves as the ultimate ledger of academic delivery, holding teachers accountable for their daily pacing.

---
## Default Data Load

The Report screens (Dashboard, Progress Tracker, Coverage Audit, Resource Matrix, Planning Accuracy) are all rendered by SyllabusController@report() (GET /syllabus/report). They load shared dropdowns (classes, subjects, academic sessions) plus tab-specific queries against slb_syllabus_schedule with filters for academic_session_id, class_id, and subject_id. Dashboard uses aggregation queries; Progress/Coverage/Resource/Accuracy use paginated queries (10/page).

---


## When This Screen Is Used

- Weekly Academic Reviews used by Heads of Departments during weekly meetings to review exactly what was covered in classrooms last week
- Exam Preparation used by the Examination Department to confirm which topics can be safely included in the upcoming unit tests without asking students questions on untaught material
- Self-Assessment used by Teachers to review their own historical teaching pace and plan the upcoming week

---


## Key Fields and Columns in the Report

**Context and Entity Details**
Columns for Class, Section, and Subject identify the specific classroom. Columns showing the Assigned Teacher versus the Actual Teacher highlight proxy situations where a substitute took the class.

**Deep Content Breakdown**
The Lesson Name shows the broad chapter. The Topic Name is displayed with hierarchical indents to visually show depth, such as Sub-topics nested under Topics. A Topic Level column explicitly indicates if it is a Root, Sub, or Micro topic.

**Crucial Schedule Metrics**
Target Start Date and Target End Date are pulled directly from the Syllabus Schedule planner. The Actual Completion Date records the exact date and time when the teacher marked the topic as completed in their app. Planned Periods shows how many classes were originally allocated for this topic.

**Status and Variance Indicators**
A Status column displays visual colored badges such as Green for Completed or Red for Overdue. A Variance column provides a calculated number showing the difference in days between the Target End Date and the Actual Completion Date, indicating exactly how many days early or late the topic was finished.

---


## Business Rules and Conditions

**Hierarchical Roll-up Status Calculation**
The status of a parent Lesson is dynamically derived from its child Topics. A Lesson can only show as Completed if 100% of its active child Topics are marked completed by the teacher. If 8 out of 10 topics are done, the Lesson must show In Progress at 80%. The report logic must automatically aggregate the statuses up the hierarchy.

**Strict Filter Dependencies**
To prevent the report from loading millions of rows and crashing, the interface must enforce a strict, step-by-step filtering process. The user must select the Academic Session, then the Class, and then the Subject. The dropdowns must cascade, meaning selecting a Class filters the available Subjects. The report should only generate after these mandatory parameters are provided.

**Exclusion of Non-Trackable Content**
The report generation process must explicitly filter out any topics that are marked as optional or not trackable in the master setup. Including optional topics would falsely skew the percentage completion metrics.

---


## Workflow Steps

**Generating a Departmental Review Report**
The Science HOD opens the Progress Tracker. They apply filters for Class 12, Subject Chemistry, and Section A. The table displays all Chapters. The HOD clicks the expand icon next to Organic Chemistry, and the table reveals 15 granular sub-topics. 14 rows are highlighted Green for Completed, but the final topic is highlighted Red for Overdue by 4 days. The HOD clicks the Export to PDF button to download this detailed tabular view for their meeting with the Chemistry teacher.

---


## Example Scenario

Two weeks before the Final Exams, the Exam Coordinator needs to set the question paper. They open the Progress Tracker, filter for all subjects in Class 9, and generate a Pending Topics Report. 

This generates a PDF listing every single topic across Math, Science, and English that has not yet been marked completed by the teachers. The Coordinator sends this PDF to all teachers with a strict mandate stating that they have 5 days to complete these specific topics, otherwise they will be excluded from the Final Exam blueprint.

---


## Related Screens

- **Overview Dashboard** — Gives the high-level graphical summary of this exact tabular data
- **Lesson Date Planning** — The absolute source of truth for the Target Date columns shown in this report

---


## Requirements

- System must load progress data under the `syllabus_progress` tab on `report.index` (route: `GET /report`, name: `report.index`)
- System must compute `$progressData` from `SyllabusSchedule` via `$applyFilters` closure with `selectRaw` aggregation:
  - `class_id`, `subject_id`
  - `total_topics`: `COUNT(*)`
  - `completed_topics`: `SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END)`
  - `overdue_topics`: `SUM(CASE WHEN is_active = 0 AND scheduled_end_date < NOW() THEN 1 ELSE 0 END)`
  - `total_periods`: `SUM(COALESCE(planned_periods, 0))`
- System must group results by `class_id`, `subject_id`
- System must eager-load `class` and `subject` relationships
- System must paginate with 10 per page using page name `progress_page`
- System must check `tenant.view-syllabus-progress.viewAny` permission via `SyllabusReportPolicy::viewSyllabusProgress()`
- View partial: `resources/views/report/partials/progress.blade.php`

---


## Who Can Access This Screen

- **Principal** — Access to all classes and sections across the school
- **Academic Director** — Full access for curriculum monitoring and exam preparation
- **Head of Department** — Access limited to their department's subjects and sections
- **Teacher** — Access to their own assigned sections and subjects only
- **Exam Coordinator** — Read-only access for exam blueprint preparation

All access is gated by `SyllabusReportPolicy::viewSyllabusProgress()` which checks `tenant.view-syllabus-progress.viewAny`.

---


## How This Screen Works — Logic Flow (Non-Technical)

The Progress Tracker is a read-only tab rendered by `SyllabusController@report()`. The controller builds `$progressData` by querying `SyllabusSchedule` with the `$applyFilters` closure and a `selectRaw` aggregation. The query groups by `class_id` and `subject_id` to produce a row per class-subject combination, showing total topics, completed topics, overdue topics, and total planned periods. The `$applyFilters` closure conditionally adds `WHERE` clauses for `academic_session_id`, `class_id`, and `subject_id` query parameters. The `class` and `subject` relationships are eager-loaded to display names in the table. Results are paginated at 10 per page with the page name `progress_page`.

---


## Validate Before Save

**Skip Validate Before Save** — This screen is a read-only progress tracker.

---


## Error Handling and Validation Messages

- **Filter Required:** "Please select Academic Session, Class, and Subject to generate the report."
- **No Data Message:** "No topics found for the selected filters. Please check if lesson plans have been created for this class and subject."
- **Export Failed:** "Export failed. The data set may be too large. Try filtering to a narrower scope and export again."
- **Session Expiry Warning:** "Your session may time out while loading large data sets. Consider narrowing your filter selection to improve performance."

---


## Success Scenarios

- An Exam Coordinator generates a Pending Topics Report two weeks before exams and exports a PDF listing all uncompleted topics across Class 9 subjects. Teachers use this list to prioritise coverage before the exam blueprint is finalised.
- An HOD views the Chemistry section during a weekly review and sees Topic "Organic Chemistry — Nomenclature" is red and overdue by 4 days. They speak to the teacher, who confirms it was taught but not marked complete. The teacher marks it, and the status updates instantly.
- A Teacher uses the tracker for self-assessment, sees their Personal Pacing bar at 78% versus the school average of 82%, and adjusts their upcoming lesson plans to close the gap.

---


## Failure Scenarios

- A user selects Class 10 but forgets to select Subject, and the report does not generate. The strict filter dependency prevents the table from loading, ensuring the system does not crash from querying millions of rows.
- A Lesson shows as Overdue even though all its topics are complete because one micro-topic was not marked complete, demonstrating the strict hierarchical roll-up logic.
- A teacher views their section but sees zero topics because the system administrator has not created the Lesson Date Planning entries for that session, meaning no planned dates exist to compare against.

---


## Dependencies module and tables

| Module | Tables |
|--------|--------|
| Syllabus Core | `slb_syllabus_schedule` (primary aggregation source) |
| Syllabus / Topic Master | `slb_lessons`, `slb_topics` |
| Academic Setup | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
