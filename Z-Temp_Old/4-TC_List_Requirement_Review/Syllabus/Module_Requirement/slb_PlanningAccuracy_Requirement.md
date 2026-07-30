# Planning Accuracy Report — Business Requirements

## What This Screen Does

The Planning Accuracy report evaluates the sheer efficiency and realism of the school's academic planning. It acts as a post-mortem tool, comparing the theoretical Planned Target Dates with the Actual Completion Dates across the entire school.

By highlighting massive variances, such as teachers consistently needing 10 periods for a chapter that the HOD stubbornly planned for 5 periods, it identifies structural flaws in the syllabus timeline. This empowers the school to create a vastly improved, data-driven schedule for the next academic year.

---
## Default Data Load

The Report screens (Dashboard, Progress Tracker, Coverage Audit, Resource Matrix, Planning Accuracy) are all rendered by SyllabusController@report() (GET /syllabus/report). They load shared dropdowns (classes, subjects, academic sessions) plus tab-specific queries against slb_syllabus_schedule with filters for academic_session_id, class_id, and subject_id. Dashboard uses aggregation queries; Progress/Coverage/Resource/Accuracy use paginated queries (10/page).

---


## When This Screen Is Used

- End of Year Review during curriculum review meetings to analyze why certain subjects couldn't finish their syllabus before the final exams
- Teacher Appraisals when evaluating a teacher's performance, pacing, and ability to stick to deadlines
- Structural Bottleneck Identification to identify inherently difficult chapters that are universally delayed across all classroom sections

---


## Key Metrics and Visualizations

**Average Variance Metric**
A core numerical output subtracts the Scheduled End Date from the Actual Completion Date. Positive numbers indicate delays, while negative numbers indicate early completion, such as +4.2 Days or -1.5 Days.

**Pace Categorization Bar Chart**
Groups topics and teachers into predefined behavioral buckets, categorizing their pace as Fast-tracked, On Time, Delayed, or Severely Delayed.

**Seasonal Delay Heatmap**
A visual grid with Months on one axis and Subjects on the other. The cells are colored based on delay severity. This helps spot external systemic issues, such as observing that almost all subjects get severely delayed in November due to Annual Day practice.

---


## Business Rules and Conditions

**Contextual Aggregation Logic**
The report must allow pivoting the variance data by different dimensions to find the root cause of delays. If a specific topic like Calculus Integration is delayed by an average of 6 days across all teachers, the system highlights it as a Planning Fault, meaning the administration didn't allocate enough time for a difficult subject. Conversely, if Calculus is finished on time by 4 teachers but delayed by 12 days by Mr. Smith, the system highlights it as an Execution Fault, meaning Mr. Smith has pacing issues.

**Proxy Teacher Accountability**
Because the system tracks the Actual Taught By teacher separately from the Assigned teacher, the report accurately attributes the variance to the teacher who actually delivered the content. If a substitute teacher took over and rushed the syllabus, the variance is logged against the substitute, not the absent primary teacher.

**Outlier Exclusion**
The calculation engine should ideally offer a toggle to exclude statistical anomalies, such as a topic marked complete 60 days late because the teacher simply forgot to click the button in the app, rather than actually teaching it 60 days late.

---


## Workflow Steps

**Adjusting Annual Plans**
At the end of the year, the Principal opens the Planning Accuracy report to prepare for the new academic calendar. The report highlights a massive anomaly showing that across all 5 sections of Class 10 Math, the chapter Surface Areas and Volumes took an average of 14 days longer than planned. The Principal drills down, pivoting the data by Teacher. They see that every single math teacher was flagged as Delayed for this chapter. The Principal concludes this is a structural planning fault, not teacher incompetence. In the next academic year, the Principal instructs the Math HOD to allocate 15 planned periods instead of 10 for this specific chapter.

---


## Example Scenario

During annual appraisals, an HOD looks at the Planning Accuracy report for a junior teacher, Mr. Sharma. 

The report shows Mr. Sharma has a highly negative variance, consistently finishing his Science syllabus 2 to 3 weeks ahead of schedule. While this looks like efficiency, the HOD cross-references this with the Exam Module and sees his students are scoring terribly. The HOD uses this undeniable data to advise Mr. Sharma during his appraisal, pointing out that the data shows he is rushing the syllabus. He needs to slow his pace, utilize the allocated time fully, and spend more periods on concept revision rather than just racing to finish the book.

---


## Related Screens

- **Lesson Date Planning** — The source screen providing the baseline Scheduled End Date and Planned Periods
- **Progress Tracker** — The source providing the Actual Completion Date

---


## Requirements

- System must load accuracy data under the `teacher_accuracy` tab on `report.index` (route: `GET /report`, name: `report.index`)
- System must compute `$accuracyData` from `SyllabusSchedule` via `$applyFilters` closure, selecting raw `DATEDIFF(updated_at, scheduled_end_date) as variance_days`
- System must only include records where `is_active = 1` AND `scheduled_end_date IS NOT NULL`
- System must eager-load `class`, `subject`, `lesson`, `topic`, `assignedTeacher.user` relationships
- System must paginate with 10 per page using page name `accuracy_page`
- System must compute `$accuracyBreakdown` aggregate (full dataset, not paginated):
  - `on_time`: count where `DATEDIFF(updated_at, scheduled_end_date) <= 0`
  - `slightly_late`: count where variance between 1 and 3 days
  - `very_late`: count where variance >= 4 days
- System must compute `$teacherPerformance` top 10 ranking: group by `assigned_teacher_id`, calculate on-time completion percentage, sort by accuracy descending
- System must compute `$onTimeCount` as count of accuracy rows with variance <= 0
- System must compute `$avgVariance` as average of variance_days (one decimal place)
- System must check `tenant.view-teacher-accuracy.viewAny` permission via `SyllabusReportPolicy::viewTeacherAccuracy()`
- View partial: `resources/views/report/partials/teacher_accuracy.blade.php`

---


## Who Can Access This Screen

- **Principal** — School-wide accuracy report across all teachers and subjects
- **Academic Director** — Full access for end-of-year curriculum planning
- **Head of Department** — Department-filtered view for teacher appraisals and subject planning
- **Teacher** — Self-service view showing only their own pacing variance and categorization

All access is gated by `SyllabusReportPolicy::viewTeacherAccuracy()` which checks `tenant.view-teacher-accuracy.viewAny`.

---


## How This Screen Works — Logic Flow (Non-Technical)

The Planning Accuracy report is a read-only tab rendered by `SyllabusController@report()`. The controller builds `$accuracyData` by querying `SyllabusSchedule` with the `$applyFilters` closure, selecting `DATEDIFF(slb_syllabus_schedule.updated_at, slb_syllabus_schedule.scheduled_end_date) as variance_days`. Only active records (`is_active = 1`) with a non-null `scheduled_end_date` are included. The query eager-loads teacher info via `assignedTeacher.user` to display teacher names. Simultaneously, the controller runs a separate aggregate query (`$accuracyBreakdown`) on the full (unpaginated) scoped dataset to compute on-time, slightly-late, and very-late counts for a donut chart. Teacher ranking (`$teacherPerformance`) groups by `assigned_teacher_id`, determines on-time completion rate, and returns the top 10 teachers sorted by accuracy. Post-query, `$onTimeCount` and `$avgVariance` are computed from the paginated collection for summary cards.

---


## Validate Before Save

**Skip Validate Before Save** — This screen is a read-only accuracy report.

---


## Error Handling and Validation Messages

- **Insufficient Data Warning:** "Some topics are missing planned end dates. Accuracy data may be incomplete. Please verify Lesson Date Planning entries."
- **No Completion Data Error:** "No completed topics found for the selected filters. Accuracy analysis requires topics that have been marked as taught."
- **Outlier Exclusion Notice:** "Extreme outliers (variances beyond [threshold] days) have been excluded from the visualisations. Toggle outlier exclusion in settings to include them."
- **Pivot Refresh Delay:** "Recalculating averages for the new pivot dimension. Please wait..."

---


## Success Scenarios

- At the end of the year, the Principal identifies that "Calculus Integration" is universally delayed by an average of 6 days across all 5 sections, confirming a structural planning fault. The Principal allocates more periods for Calculus in the next year's plan.
- An HOD uses the Pace Categorization Bar Chart during appraisals to show that a junior teacher is consistently in the "Severely Delayed" bucket, triggering a structured mentoring program.
- The system's seasonal heatmap reveals that almost all subjects show a red spike in November. The Principal realises this is due to Annual Day practice and adjusts the next year's calendar accordingly.

---


## Failure Scenarios

- The report shows a teacher with a +60-day variance because they forgot to mark a topic complete months after teaching it. The outlier exclusion toggle removes this data point, but if the toggle was off, it would skew the entire department's average.
- The heatmap is blank for several months because topics were not assigned target end dates in the Lesson Date Planning screen, meaning no baseline exists for variance calculation.
- A teacher's variance is incorrectly attributed to a substitute teacher because the Actual Taught By field was not updated when the substitute took the class, leading to an inaccurate performance review.

---


## Dependencies module and tables

| Module | Tables |
|--------|--------|
| Syllabus Core | `slb_syllabus_schedule` (primary data source) |
| Syllabus / Lesson Planning | `slb_lessons`, `slb_topics` |
| Teacher Management | `sch_employees` (via `assigned_teacher_id`) |
| Academic Setup | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
