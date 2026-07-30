# Resource Matrix Report — Business Requirements

## What This Screen Does

The Resource Matrix is an operational auditing report that cross-references the theoretical syllabus with physical and digital assets. It helps the school ensure that every planned lesson actually has the necessary study materials, like PDFs and Videos, and assessment materials, like Question Banks, attached to it before the term begins.

It acts as a quality assurance tool, preventing situations where a teacher arrives in class only to realize the smartboard video for that topic hasn't been uploaded yet or students have no homework assigned.

---
## Default Data Load

The Report screens (Dashboard, Progress Tracker, Coverage Audit, Resource Matrix, Planning Accuracy) are all rendered by SyllabusController@report() (GET /syllabus/report). They load shared dropdowns (classes, subjects, academic sessions) plus tab-specific queries against slb_syllabus_schedule with filters for academic_session_id, class_id, and subject_id. Dashboard uses aggregation queries; Progress/Coverage/Resource/Accuracy use paginated queries (10/page).

---


## When This Screen Is Used

- Summer Break Preparation used by Heads of Departments before the academic year starts to verify that teachers have uploaded all required study materials to the system
- Digital Content Audits used by the IT or Content team to identify missing PDFs, broken video links, or empty question banks
- Flipped Classroom Planning used to ensure that students have pre-reading materials available before a topic is scheduled to be taught

---


## Key Fields and Columns in the Report

**Topic Context**
Columns for Class, Subject, Lesson Name, and Topic Name identify exactly where the resources should be attached.

**Dynamic Resource Counters**
The Video Count displays the total number of video links attached to the topic. The Document Count displays the total number of PDF or Word documents attached. The URL Count displays the total number of external web links attached. The Question Bank Count displays the total number of assessable questions currently tagged to this specific topic in the central Question Bank.

**Status and Health Indicator**
A Status Badge provides a system-calculated health indicator, categorizing the topic as Resource Rich in Green, Adequate in Yellow, or Deficient in Red.

---


## Business Rules and Conditions

**Deep Document Parsing**
To generate this report efficiently, the system must deeply scan the resource attachments stored against both Lessons and Topics. It must categorize the attachments into videos, documents, and links, count the occurrences of each type, and output them to the grid columns to provide a clear summary without requiring manual checking.

**Deficiency Logic based on Assessability**
The report's Health Indicator must be intelligent. It checks whether a topic is marked as Assessable in the master setup. If an assessable topic has a Question Bank Count of zero, the Resource Matrix flags this topic as critically deficient due to missing questions. However, if a topic is explicitly marked as non-assessable, such as an introductory welcome topic, a zero Question Bank Count is perfectly acceptable and does not trigger a deficiency warning.

**Aggregate Roll-up**
The user must be able to view this matrix at the broad Lesson level. The system will sum up the Video, Document, and Question counts of all child topics to give an overall health score for the entire chapter.

---


## Workflow Steps

**Auditing Missing Content**
The Science HOD opens the Resource Matrix report during the summer break. They filter the report for Class 9 Physics. The matrix loads, showing that Chapter 1 has 5 Videos, 2 PDFs, and 50 Questions, earning a Green Resource Rich status badge. However, Chapter 3 has 0 Videos, 0 PDFs, and only 2 Questions, causing the status badge to flash Red for Deficient. The HOD clicks the Export Missing Resources List button. They email this generated list to the Physics department, mandating them to upload content and questions for Chapter 3 before the school reopens.

---


## Example Scenario

A school mandates a modern Flipped Classroom model, where students must watch a conceptual video at home before coming to physical class to discuss it. 

To ensure this model doesn't fail, the Academic Coordinator uses the Resource Matrix. They apply a custom filter to show all topics where the Video Count is zero. The system instantly generates a list of 40 topics across various subjects that lack video content. The Coordinator exports this list and tasks the IT multimedia team to source, record, and upload videos for these exact 40 topics, guaranteeing the Flipped Classroom model operates smoothly.

---


## Related Screens

- **Topics Master and Lessons Master** — The source screens where the resources are actually uploaded and stored
- **Question Bank Module** — The source module queried to calculate the Question Bank Count

---


## Requirements

- System must load resource matrix data under the `resource_matrix` tab on `report.index` (route: `GET /report`, name: `report.index`)
- System must compute `$matrixData` from `SyllabusSchedule` via `$applyFilters` closure with eager-loaded `class`, `subject`, `lesson`, `topic.competencies` relationships
- System must compute `$resourceMeta` as a collection keyed by `topic.id` containing resource counts: `video`, `pdf`, `image` (all defaulting to 0) and `ques` (count of competencies — no dedicated resource/study_materials table exists in current migrations)
- System must paginate `$matrixData` with 10 per page using page name `matrix_page`
- System must check `tenant.view-resource-matrix.viewAny` permission via `SyllabusReportPolicy::viewResourceMatrix()`
- View partial: `resources/views/report/partials/resource_matrix.blade.php`

---


## Who Can Access This Screen

- **Principal** — School-wide resource audit access
- **Academic Director** — Full access for content quality assurance
- **Head of Department** — Access limited to their department's subjects for pre-term preparation
- **IT / Content Team** — Operational access for uploading and verifying digital assets
- **Teacher** — View-only access to their own lessons' resource status

All access is gated by `SyllabusReportPolicy::viewResourceMatrix()` which checks `tenant.view-resource-matrix.viewAny`.

---


## How This Screen Works — Logic Flow (Non-Technical)

The Resource Matrix is a read-only tab rendered by `SyllabusController@report()`. The controller queries `SyllabusSchedule` with the `$applyFilters` closure and eager-loads `topic.competencies` (since the dedicated `slb_study_materials` table does not exist in current migrations). After fetching `$matrixData`, the controller computes `$resourceMeta` by mapping each topic to an array with `video`, `pdf`, `image` (all hardcoded to 0) and `ques` (count of related competencies). The view partial at `resources/views/report/partials/resource_matrix.blade.php` receives both `$matrixData` (paginated schedule rows) and `$resourceMeta` (resource counts keyed by topic ID) to render the auditing grid.

---


## Validate Before Save

**Skip Validate Before Save** — This screen is a read-only resource audit.

---


## Error Handling and Validation Messages

- **No Resources Found:** "No resources found for the selected filters. The syllabus may not have been set up for this class and subject yet."
- **Missing Question Bank Module:** "Question Bank Count is unavailable. Please ensure the Question Bank module is active and tagged to topics."
- **Export Warning:** "Exporting the complete resource list may take time for large data sets. Consider filtering by a specific subject."
- **Broken Link Detection Notice:** "Some video or URL resources may be inaccessible. The system reports counts based on stored links and does not validate link availability."

---


## Success Scenarios

- Before the academic year starts, the Science HOD filters for Class 9 Physics and finds Chapter 3 has 0 videos, 0 PDFs, and 2 questions. The system flags it as Deficient. The HOD exports the missing resources list and tasks the Physics department to upload content before school reopens.
- The IT Content Team uses the matrix to verify all 40 identified topics without video content now have videos uploaded after a summer project. The status badges for those topics change from Deficient to Resource Rich.
- An Academic Coordinator confirms that all assessable topics across Class 10 have at least 10 questions each, greenlighting the upcoming unit tests.

---


## Failure Scenarios

- A topic is flagged as Deficient for having zero questions, but it is a non-assessable introductory topic. The deficiency logic incorrectly triggered because the "Assessable" flag was not set in the Topics Master, requiring a data correction.
- The report shows zero resources for a lesson that actually has resources attached, because the resources were uploaded against the parent lesson only, but the scan logic only checked child topics, missing the lesson-level attachments.
- The Question Bank Count shows 0 for all topics because the Question Bank module integration is not yet configured, causing every assessable topic to be flagged as Deficient and rendering the report unusable until the integration is set up.

---


## Dependencies module and tables

| Module | Tables |
|--------|--------|
| Syllabus Core | `slb_syllabus_schedule` (primary data source) |
| Syllabus / Topic Master | `slb_lessons`, `slb_topics`, `slb_topic_competency` |
| Competency Master | `slb_competencies` |
| Academic Setup | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
