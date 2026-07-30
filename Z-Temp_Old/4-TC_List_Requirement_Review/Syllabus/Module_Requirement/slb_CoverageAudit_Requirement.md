# Coverage Audit Report — Business Requirements

## What This Screen Does

The Coverage Audit report is the most advanced, compliance-focused analytics tool in the system. It shifts the educational focus from counting how many chapters were finished to evaluating what mental skills the students actually developed.

By analyzing the complex links between Topics, Competencies, and Bloom's Taxonomy, this report visually demonstrates the school's adherence to modern educational mandates like the National Education Policy. It proves to external boards that the school is not just doing rote memorization, but is actively delivering higher-order thinking skills.

---
## Default Data Load

The Report screens (Dashboard, Progress Tracker, Coverage Audit, Resource Matrix, Planning Accuracy) are all rendered by SyllabusController@report() (GET /syllabus/report). They load shared dropdowns (classes, subjects, academic sessions) plus tab-specific queries against slb_syllabus_schedule with filters for academic_session_id, class_id, and subject_id. Dashboard uses aggregation queries; Progress/Coverage/Resource/Accuracy use paginated queries (10/page).

---


## When This Screen Is Used

- Accreditation Inspections during school audits to provide undeniable, data-backed proof of curriculum depth
- Curriculum Review by Academic Directors at the end of the year to ensure the syllabus isn't overly focused on simple knowledge but includes skill and attitude development
- Teacher Training identifying if certain departments are completely ignoring practical or emotional domains in their lesson plans

---


## Key Visualizations and Metrics

**Cognitive Domain Radar Chart**
A radial spider web chart plots the spread of taught topics across Bloom's 6 levels, from Remembering to Creating. It visually highlights if a school's teaching is heavily skewed towards one side, exposing gaps in higher-order thinking.

**Competency Type Breakdown**
A donut chart shows the percentage of the delivered syllabus dedicated to high-level categories like KNOWLEDGE, SKILL, and ATTITUDE.

**NEP Framework Compliance Ledger**
A tabular list of specific NEP or NCF framework codes, such as Critical Thinking NEP-4.1, mapped directly to the exact lessons and topics that covered them in the classroom.

**Deficient or Uncovered Competencies Alert**
A critical Red Flag list showing skills that were officially defined by the school, but currently have zero topics mapped to them across the entire year's syllabus, warning the administration of neglected learning goals.

---


## Business Rules and Conditions

**Advanced Weightage-Based Calculation**
The audit does not simply count the number of topics; it calculates a weighted score. If a massive topic that takes 20 periods to teach is mapped to Analytical Thinking, that competency gets a massive mathematical boost in the radar chart. Conversely, if a tiny 1-period topic is mapped to Recall, it barely registers. The formula multiplies the importance of the topic by the importance of the competency to derive the true delivery depth.

**Real-time Dynamic Context Auditing**
The report must respond to real-time delivery status. If a user filters the report by Taught Topics Only, the radar chart instantly redraws. It excludes all future planned topics and shows the cognitive depth of exactly what has been physically delivered to the students up to today's date.

**Primary vs Secondary Competency Filtering**
The interface should provide a toggle to either Analyze Primary Competencies Only or Include Secondary Competencies. This allows the user to either show a highly focused report based only on the main goal of each lesson, or a broad overview of all touched skills.

---


## Workflow Steps

**Auditing Departmental Compliance**
The Academic Director opens the Coverage Audit screen. They select School-Wide View for the current academic session and filter by Taught Topics Only. The system generates the Bloom Taxonomy Radar Chart, and the Director notices the web is heavily pulled towards Remembering and Understanding. Identifying this massive gap in higher-order thinking, they drill down into the English Subject. They find that almost zero topics are mapped to Creating or Evaluating. The Director mandates the English HOD to instantly redesign the Term 2 syllabus to include more creative writing topics to balance the radar chart.

---


## Example Scenario

An external school inspector visits the campus to audit NEP 2020 compliance. They demand to know how the school is integrating Experiential Learning and Vocational Skills into standard subjects like Science and Math.

The Principal opens the Coverage Audit screen, selects Class 10, and generates the NEP Alignment Report. The system's algorithm parses the NEP framework codes mapped to the topics taught. It instantly outputs a document detailing exactly which chapters, on which dates, fulfilled specific experiential clauses, impressing the inspector with automated, undeniable proof of compliance without needing to manually collate teacher lesson plans.

---


## Related Screens

- **Topic-Competency Mapping** — The foundational mapping matrix that feeds data to this report
- **Bloom Taxonomy & Competencies Master** — Provides the hierarchy and labels used in the charts

---


## Requirements

- System must load coverage audit data as a paginated tabular list under `coverage_audit` tab on `report.index`
- System must fetch `$auditData` from `SyllabusSchedule` model (`slb_syllabus_schedule`) filtered by `academic_session_id`, `class_id`, `subject_id` via `$applyFilters` closure in `SyllabusController@report()`
- System must eager-load `class`, `subject`, `lesson`, `topic` relationships on `$auditData`
- System must only include records where `scheduled_start_date` is NOT NULL
- System must order results by `scheduled_start_date` ascending
- System must paginate results with 10 per page using page name `audit_page`
- System must check `tenant.view-coverage-audit.viewAny` permission via `SyllabusReportPolicy`
- View partial must be rendered at `resources/views/report/partials/coverage.blade.php`

---


## Who Can Access This Screen

- **Principal** — Full school-wide access with all filters available
- **Academic Director** — Cross-departmental access for curriculum audits
- **Head of Department** — Access limited to subjects under their department
- **Teachers** — View-only access limited to their own assigned subjects and sections

All access is gated by `SyllabusReportPolicy::viewCoverageAudit()` which checks `tenant.view-coverage-audit.viewAny`.

---


## How This Screen Works — Logic Flow (Non-Technical)

The Coverage Audit report is a read-only tab rendered by `SyllabusController@report()` (route: `GET /report`, name: `report.index`). The user selects optional filters (academic session, class, subject) from the global filter bar and clicks Generate Report. The controller applies these filters via a `$applyFilters` closure to a `SyllabusSchedule` query, filtering only rows where `scheduled_start_date` is not null. Results are ordered by `scheduled_start_date` ascending and paginated (10 per page, `audit_page`). The view partial `resources/views/report/partials/coverage.blade.php` is included inside the tab container only when the authenticated user has the `tenant.view-coverage-audit.viewAny` permission. Since the tab component uses `href`-based navigation, switching tabs triggers a full page reload with the `tab` query parameter.

---


## Validate Before Save

**Skip Validate Before Save** — This screen is a read-only analytics report.

---


## Error Handling and Validation Messages

- **No Data Error:** "No topics found for the selected filters. Please widen your selection or check if topics have been mapped for this session."
- **Filter Dependency Warning:** "Please select Academic Session, Class, and Subject before generating the report."
- **Incomplete Mapping Warning:** "Some competencies have no topics mapped. Deficiency alerts have been generated."
- **Export Failure:** "Report export failed. Please try again or contact your system administrator."

---


## Success Scenarios

- A Principal successfully generates a school-wide compliance report and exports it as a PDF for accreditation inspection, showing balanced Bloom's coverage across all subjects.
- An Academic Director identifies a department lacking higher-order thinking topics and initiates a curriculum redesign based on the radar chart evidence.
- The system automatically flags five competencies with zero mapped topics, prompting the curriculum committee to add new topics for the next term.

---


## Failure Scenarios

- The report loads with zero data because no topic-competency mappings exist for the selected academic session, requiring the user to first set up mappings in the Topic-Competency Mapping screen.
- The NEP compliance ledger shows 0% because the school has not attached any NEP framework codes to their topic-competency links, requiring administrative setup before meaningful compliance data is visible.
- The radar chart displays skewed results because a teacher mistakenly assigned an extremely high weightage to a minor topic, requiring correction in the Topic Master.

---


## Dependencies module and tables

| Module | Tables |
|--------|--------|
| Syllabus Core | `slb_syllabus_schedule`, `slb_lessons`, `slb_topics` |
| Competency Master | `slb_competencies`, `slb_competency_type`, `slb_bloom_level` |
| Academic Setup | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
