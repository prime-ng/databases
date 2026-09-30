# Prime-AI Behavioural Assessment Module — Detailed Business Requirements Document

**Document Type:** Business Requirements Document (BRD)  
**Module:** Behavioural Assessment  
**Application:** Prime-AI Main Application  
**Target Domain:** Indian K-12 School Management  
**Source DDL:** `LMS_BehaviouralAssess_DDL_v2.sql` — Version 2.0, April 2026  
**Source BRD:** `_BRD_BehaviouralAssessment.md`  

> This document consolidates and expands the two supplied Behavioural Assessment artifacts into a single business-focused requirements baseline. It deliberately preserves source terminology and explicitly identifies areas where the BRD and current DDL describe different levels of functionality.

---

## 1. Executive Summary

The Behavioural Assessment Module provides Prime-AI schools with a structured, consistent and auditable way to assess student behaviour and behavioural development. It combines **periodic criteria-based assessment** with **event-driven behavioural incident management**.

The module is intended to move behavioural evaluation away from unstructured subjective comments toward a framework in which behavioural expectations are defined as categories and observable criteria, teachers use controlled rating levels, supervisors review submissions, scores are calculated consistently, and incidents/interventions provide supporting evidence.

The module is therefore more than a marks-entry facility. It is a longitudinal behavioural-development record covering:

- behavioural standards and criteria;
- rating scales;
- class applicability;
- assessment periods;
- teacher assessments;
- student ratings;
- qualitative remarks;
- review and approval;
- computed scores;
- incidents;
- witnesses;
- interventions;
- follow-up;
- parent notification;
- audit history;
- student/class/category/period analytics;
- integration with academic results.

---

# Part I — Business Context

## 2. Module Purpose

The module shall enable a school to:

1. Define behavioural categories and observable criteria.
2. Configure one or more behavioural rating scales.
3. Define ordered rating levels with numeric values.
4. Map behavioural categories to applicable school classes.
5. Define assessment periods within academic sessions.
6. Configure how behavioural scores are aggregated.
7. Allow authorized teachers to assess students through a structured grid.
8. Capture per-criterion and overall student remarks.
9. Submit assessments for supervisory review.
10. Return assessments for correction where required.
11. Finalize and lock approved assessments.
12. Calculate criterion, category and overall scores.
13. Average ratings where multiple teachers assess the same criterion.
14. Normalize negative behavioural categories.
15. Cache finalized/computed scores for reporting.
16. Log positive and negative behavioural incidents.
17. Record severity, location, witnesses, evidence and follow-up.
18. Associate standardized interventions with incidents.
19. Track intervention progress where the richer workflow is enabled.
20. Trigger parent notifications according to configured thresholds.
21. Generate student, class, category, period and incident reports.
22. Maintain an immutable audit trail.
23. Provide finalized behavioural scores to the Exam/Result area without BA directly modifying academic-result tables.

## 3. Business Problems Addressed

### 3.1 Subjective Behaviour Assessment
Schools need common behavioural language and observable criteria rather than arbitrary grades.

### 3.2 Teacher-to-Teacher Inconsistency
Different teachers may grade behaviour differently. Controlled scales, weights, review and statistical analysis support standardization.

### 3.3 Lack of Evidence
A score alone may not explain behaviour. Remarks, incidents, witnesses and interventions provide context.

### 3.4 Lack of Longitudinal Visibility
Schools need to identify improvement, decline and stability across terms/months.

### 3.5 Weak Intervention Tracking
An incident should be connected to what the school actually did in response and whether the action was completed.

### 3.6 Difficult Parent Conversations
Parent meetings benefit from objective scores, narrative comments and evidence-backed incident history.

### 3.7 Accountability and Auditability
Behavioural records are sensitive and changes must be traceable.

---

# Part II — Users and Responsibilities

## 4. User Roles

| Role | Primary Activities |
|---|---|
| Admin / Principal | Configure scales, categories, criteria, periods, interventions and module settings; review analytics and audits |
| Class Teacher | Conduct periodic assessments, enter remarks, review class behaviour and access permitted reports |
| Subject Teacher | Rate applicable criteria and record positive/negative incidents |
| HOD / Coordinator | Review submissions, send back corrections, approve/lock assessments and analyze cohorts |
| Behavioural Counsellor | Review incidents, coordinate interventions and examine behavioural progress |
| Parent / Guardian | View permitted finalized behavioural information |
| Student | May receive a permitted progress-oriented behavioural view |

## 5. Role-Based Visibility

- Administrators and counsellors may operate at school-wide scope.
- Class teachers operate primarily within their assigned class/section scope.
- Subject teachers operate within their assigned teaching scope.
- Witness statements are more restricted than ordinary incident metadata.
- Parent-facing reports must not expose draft/unapproved behavioural grades.

---

# Part III — Functional Structure

## 6. Module Menus and Screens

### Dashboard
- Dashboard

### Masters
- Rating Scales
- Categories & Criteria
- Interventions

### Setup
- Class Mapping
- Assessment Periods
- Configuration

### Assessments
- My Assessments
- Ratings
- Remarks
- Review Queue

### Incidents
- Incident Log
- Witnesses
- Interventions Applied

### Reports Hub
- Student Scores
- Category Summary
- Period Report
- Audit Trail
- Incident Summary

### Standalone Reports
- Student Report
- Class Analysis
- Period Progress
- Category Performance
- Incident Report

---

# Part IV — Core Behavioural Model

## 7. Behavioural Hierarchy

The primary structured model is:

**Category → Criterion → Rating Level → Student Rating**

A category describes a broad behavioural domain. A criterion describes an observable behaviour. A rating level expresses the observed degree of that behaviour. The numeric value supports aggregation.

## 8. Positive and Negative Polarity

Categories may be **positive** or **negative**.

For positive categories, higher ratings represent better behaviour.

For negative categories, the supplied scoring design reverses the raw value:

`inverted_score = (max_scale_value + 1) - raw_score`

This keeps the final score direction consistent: a higher final behavioural score represents better behavioural standing.

## 9. Periodic Assessment vs Incident

### Periodic Assessment

- planned;
- period-based;
- criteria-driven;
- normally covers a section/cohort;
- generates quantitative behavioural scores.

### Incident

- event-driven;
- individual;
- can occur independently of an assessment period;
- records a concrete behavioural event;
- may include severity, witnesses, interventions and follow-up;
- does not directly modify the computed rating score in the current DDL design.

---

# Part V — Master Requirements

## 10. Rating Scale Management

Schools shall be able to maintain multiple rating scales, such as:

- 5-point behavioural scale;
- 3-point scale;
- descriptive scale.

The current DDL supports selecting the active scale through session-level configuration.

### Scale information

- code;
- name;
- description;
- grade type;
- minimum rating;
- maximum rating;
- default indicator;
- active/inactive state.

### Business rules

- At least two rating levels should be supported.
- The supplied BRD proposes a maximum of ten levels.
- Level numeric values must fall inside the scale range.
- Level labels and numeric values should be unique within a scale.
- Historical scales must remain available for historical records even after deactivation.

## 11. Rating Levels

Each scale shall have ordered levels with:

- label;
- numeric value;
- description;
- sort order;
- active status.

Example five-point scale:

| Order | Level | Numeric Value |
|---:|---|---:|
| 1 | Unsatisfactory | 1 |
| 2 | Needs Improvement | 2 |
| 3 | Good | 3 |
| 4 | Very Good | 4 |
| 5 | Outstanding | 5 |

## 12. Category Management

Categories represent broad behavioural domains. The supplied default framework includes:

**Positive:**

1. Classroom Engagement
2. Respect & Responsibility
3. Cooperation & Collaboration
4. Emotional & Social Development
5. Leadership & Initiative

**Negative:**

6. Disruptive Behaviours
7. Aggressive/Bullying
8. Academic Misconduct
9. Health & Safety Violations

The supplied DDL describes 58 criteria across the nine seeded categories.

## 13. Category Hierarchy

Categories may have a parent category, allowing sub-categories for finer behavioural organization.

## 14. Category Weight

Category weights are proportional in the current DDL. They do not have to total 100; the aggregation engine normalizes them against the total applicable weight.

## 15. Criteria Management

Each criterion shall belong to a category and represent an observable behaviour.

Criteria support:

- name;
- description;
- weight;
- display order;
- active/inactive state.

The supplied screen BRD additionally describes criterion codes and maximum score. The current DDL instead derives the rating range from the selected rating scale. This should be standardized in the final product definition.

## 16. Criteria Weighting

The richer screen BRD proposes that active criterion weightages under a category total 100% when weighted grading is enabled. The DDL uses proportional weights.

The final product should therefore clearly define whether 100% is a presentation/validation convention or a strict storage rule.

## 17. Intervention Master

The module shall maintain standardized interventions.

Current DDL types:

- Reward
- Corrective
- Counselling

The supplied screen BRD uses closely related terms such as Reinforcement and Supportive. The UI vocabulary should be standardized.

Default intervention examples include:

- Award/Certificate
- Public Recognition
- Extra Privileges
- Verbal Warning
- Written Warning
- Detention
- Suspension
- Parent Meeting
- Counselling Referral

---

# Part VI — Academic Setup

## 18. Class-to-Category Mapping

Administrators shall map categories to school classes so age-appropriate behavioural expectations can be used.

Example:

- Grade 1 may use engagement, respect and cooperation categories.
- Grade 10 may additionally use academic misconduct and other mature behavioural domains.

## 19. Mapping Fallback

The supplied DDL specifies a permissive fallback: if no class mappings exist for a class, all categories apply.

## 20. Assessment Periods

Assessment periods define the time windows for structured behavioural evaluation.

A period contains:

- academic session;
- optional academic term;
- name;
- start date;
- end date;
- teacher deadline;
- lifecycle status.

## 21. Period Lifecycle

`Open → Closed → Locked`

### Open
Teachers can create and edit assessments.

### Closed
New assessments cannot be created; existing records may continue through the defined review workflow.

### Locked
The period is finalized and assessment editing is prohibited.

## 22. Session Configuration

One configuration record exists per academic session in the current DDL.

It controls:

- active rating scale;
- result integration switch;
- behavioural result weightage;
- aggregation method;
- parent notification threshold.

## 23. Result Integration Configuration

Behavioural contribution to academic result is optional and defaults to disabled.

The supplied configuration permits 5–20% weightage when enabled.

Conceptually:

`Final = Academic × (1 - w) + Behavioural_Normalized × w`

The BA module exposes scores to the result layer rather than directly modifying result tables.

---

# Part VII — Assessment Workflow

## 24. Assessment Header

An assessment represents a teacher's evaluation for one:

- period;
- class-section;
- teacher.

The current DDL prevents duplicate teacher/class-section/period assessment headers.

## 25. Teacher Assignment Resolution

The BA module does not maintain a separate teacher-assignment master. It resolves class-teacher and subject-teacher context from existing SchoolSetup/timetable information.

## 26. Assessment Status

`Draft → Submitted → Reviewed → Locked`

### Draft
Teacher enters or edits ratings.

### Submitted
Teacher has completed the submission and it enters review where review is enabled.

### Reviewed
Supervisor/HOD approves it.

### Locked
The assessment becomes immutable/final.

## 27. Send Back

A reviewer may return a submission to Draft with reviewer remarks. The teacher corrects the assessment and resubmits it.

## 28. Auto-Save

The supplied DDL specification describes approximately 30-second auto-save during grid entry to reduce data-loss risk.

---

# Part VIII — Rating Entry

## 29. Rating Grid

The primary teacher interface is a student-by-criterion grid. Each populated cell represents one rating fact.

Teachers shall be able to:

- see applicable students;
- see applicable criteria;
- select configured rating levels;
- optionally enter criterion remarks;
- move efficiently through the grid;
- save progress automatically;
- submit when complete.

## 30. Rating Uniqueness

A student/criterion combination may occur once within a teacher assessment. Re-entry updates the existing rating rather than creating a duplicate.

## 31. Overall Student Remarks

Each student may have one holistic remark per teacher assessment. This is distinct from per-criterion remarks.

## 32. Comment Bank

The supplied BRD describes a Comment Bank helper that can insert standardized narrative templates, replace a student placeholder, and allow teacher customization.

This feature supports consistent, professional behavioural language while preserving teacher-authored context.

---

# Part IX — Review and Quality Control

## 33. Review Queue

The Review Queue is the quality-control workspace for submitted assessments.

Reviewers should be able to:

- filter by period/class/section/teacher;
- inspect ratings;
- inspect remarks;
- approve;
- send back with feedback.

## 34. Review Quality Checks

Reviewers should check:

- completeness;
- rating consistency;
- unusual grading patterns;
- alignment between ratings and remarks;
- professional language;
- obvious contradictions.

## 35. Approval and Locking

The source artifacts describe both `Reviewed` and `Locked` states, while the screen BRD sometimes presents "Approve & Lock" as a single UI action.

The final product must define whether approval and locking are separate business events or one UI operation that performs both state transitions.

## 36. Parent Visibility

Draft and submitted-but-unapproved scores must not be presented as finalized parent-facing results.

---

# Part X — Score Computation

## 37. Computation Pipeline

The supplied DDL defines the following calculation flow:

```text
Raw teacher ratings
        ↓
Group by student + criterion + period
        ↓
Average across teachers
        ↓
Invert negative-polarity values
        ↓
Weighted category score
        ↓
Weighted/simple overall score
        ↓
Grade mapping
        ↓
Cached computed score
```

## 38. Multi-Teacher Averaging

If multiple teachers rate the same student on the same criterion in the same period, the numeric values are averaged.

## 39. Negative Polarity

Negative categories use the configured maximum rating to invert the raw value so the final score direction remains consistent.

## 40. Category Aggregation

`Category Score = Weighted Average(Criterion Scores, Criterion Weights)`

## 41. Overall Aggregation

The configuration supports:

- average;
- weighted average;
- separate display.

## 42. Grade Mapping

The current DDL derives grade mapping from the rating scale and rating-level numeric boundaries rather than the older JSON-boundary approach.

## 43. Computed Score Cache

`ba_computed_scores` is intended as a materialized/cache layer for fast reporting.

It stores category scores and an overall score/grade representation for the student-period result.

## 44. Recalculation

Scores may be recomputed after assessment approval or through a manual/admin computation process. The supplied DDL describes queued school-wide computation for large datasets.

---

# Part XI — Incident Management

## 45. Incident Purpose

Incident logging captures concrete behavioural events separately from periodic assessments.

## 46. Positive Incidents

Examples:

- helping peers;
- leadership;
- exceptional initiative;
- achievements;
- positive school contributions.

## 47. Negative Incidents

Examples:

- disruption;
- aggression;
- bullying;
- academic misconduct;
- safety violations.

Negative incidents require severity in the current DDL.

## 48. Severity

Current DDL levels:

- minor;
- moderate;
- major;
- critical.

The supplied screen BRD sometimes calls these Info/Low/Medium/High. One canonical vocabulary should be chosen for the product.

## 49. Incident Date and Time

Incidents store date and optional time. The screen BRD additionally proposes preventing future dates and restricting delayed entry to seven days. This seven-day rule should be confirmed as school policy before implementation.

## 50. Incident Location

Supported locations include:

- classroom;
- playground;
- corridor;
- lab;
- transport;
- canteen;
- library;
- other.

Location enables hotspot analysis.

## 51. Incident Description

The description records the factual event narrative. The screen BRD proposes 20–1000 characters; this should be finalized as a product validation rule.

## 52. Incident Category/Criterion Link

An incident may optionally link to a behavioural category and criterion to connect event evidence with the structured behavioural framework.

## 53. Incident Immutability

The DDL specifies that core incident facts are immutable after creation:

- student;
- incident date;
- incident type;
- severity;
- description;
- location.

Follow-up information and notification state remain updateable according to service rules.

## 54. Attachments

Incidents may contain references to uploaded evidence such as photographs. The current DDL uses an `attachments_json` structure rather than a separate relational attachment table.

---

# Part XII — Witnesses

## 55. Witness Types

A witness may be:

- another student;
- a staff member.

The current DDL uses a type-plus-ID polymorphic reference and validates the target at the application layer.

## 56. Witness Statements

Witness records should capture a factual statement. The supplied BRD proposes a 10–500 character range.

## 57. Self-Witness Rule

The student who is the subject of the incident cannot be added as their own witness.

## 58. Witness Security

Witness statements are sensitive. The supplied BRD restricts statement text to HOD, counsellor and principal-level users.

## 59. Witness Freeze

The supplied BRD requires witness records to freeze after the associated case is closed/resolved under its defined conditions.

---

# Part XIII — Interventions and Case Resolution

## 60. Intervention Application

One incident may have multiple interventions.

Examples:

- Written Warning + Parent Meeting;
- Counselling Referral + Follow-up;
- Reward + Public Recognition.

## 61. Intervention Notes

Each incident-intervention relationship may contain contextual notes explaining what was done.

## 62. Rich Intervention Lifecycle

The supplied screen BRD describes:

`Assigned → In Progress → Completed / Cancelled`

It also describes:

- assigned staff;
- scheduled date;
- completion date;
- progress notes;
- cancellation justification.

The current DDL junction table does not contain all of these workflow attributes. Therefore this is a significant business requirement to preserve and reconcile in the next schema revision.

## 63. Intervention Completion

The supplied BRD proposes that completion require a completion date and meaningful closing notes. High-severity cases may not be resolved until required intervention handling is completed or cancelled with justification.

## 64. Follow-Up

Incidents may require follow-up, with:

- follow-up required flag;
- follow-up date;
- appendable follow-up notes.

---

# Part XIV — Notifications

## 65. Parent Notification Threshold

The configured severity threshold determines when an incident triggers the parent notification process.

Possible thresholds:

- minor;
- moderate;
- major;
- critical.

## 66. Notification Process

Conceptually:

```text
Incident created
      ↓
Check severity against configured threshold
      ↓
Raise notification event
      ↓
Notification module sends configured alert
      ↓
Store notification-sent state
```

## 67. High-Severity Internal Alerts

The screen BRD proposes high-severity notifications to relevant school leadership and, where enabled, parents.

The exact recipient matrix should be governed by the Prime-AI Notification module and school policy.

---

# Part XV — Dashboard

## 68. Dashboard Purpose

The dashboard provides a high-level operational and behavioural view for school leaders, counsellors, HODs and teachers.

## 69. KPI Cards

The supplied BRD identifies:

- active assessment period and remaining days;
- assessment completion percentage;
- incidents logged during the week;
- active interventions.

## 70. Charts

The dashboard may include:

- incident severity distribution;
- positive vs disciplinary incident trend;
- category-wise averages.

## 71. Alerts

The dashboard should surface:

- recent severe incidents;
- pending approvals;
- repeated disciplinary incidents;
- assessment deadlines.

## 72. Drill-Down

Users should be able to move from dashboard metrics into filtered Review Queue, Incident Log or Student Report views.

## 73. Performance

The supplied BRD targets approximately two seconds for normal dashboard page loading by relying on computed/cached data rather than expensive raw-rating aggregation on every request.

---

# Part XVI — Reporting

## 74. Reports Hub

The Reports Hub centralizes behavioural reports and exports.

Common filters include:

- academic session;
- assessment period;
- class;
- section;
- student;
- incident type;
- severity;
- date range.

## 75. Large Export Handling

The supplied BRD proposes background generation for exports above approximately 1,000 rows, followed by an in-app notification when the file is ready.

## 76. Student Scores Report

Provides student-wise category and overall behavioural results for a selected cohort.

Possible columns:

- roll number;
- admission number;
- student name;
- category scores;
- overall average;
- grading status;
- teacher/context.

## 77. Category Summary

Provides cohort-level category analytics including:

- students evaluated;
- category average;
- strongest criterion;
- weakest criterion;
- distribution by behavioural performance bucket.

An anonymized version is required by the supplied BRD for general staff-level sharing.

## 78. Period Report

Compares scores across periods and displays score delta.

`Score Delta = Current Period Average - Previous Period Average`

Positive values indicate improvement; negative values indicate decline.

The supplied BRD proposes directional thresholds around ±0.30 and a stability band around ±0.20. These should be configurable rather than permanently hard-coded.

## 79. Student Report

The Student Report is the holistic behavioural dossier containing:

- identity information;
- overall score;
- category scores;
- criterion ratings;
- remarks;
- positive incidents;
- negative incidents;
- interventions;
- progress context.

It is intended for parent-teacher meetings, report cards and disciplinary reviews.

## 80. Class Analysis

Class Analysis provides:

- cohort distribution;
- category heatmap;
- top performers;
- at-risk students;
- section averages.

The supplied BRD proposes an at-risk rule based on either a composite average below 2.5/5 or at least two negative incidents in the active term. This should be configurable and scale-aware.

## 81. Period Progress

Period Progress visualizes behavioural performance over consecutive periods.

It may show:

- composite trend;
- selected category trends;
- intervention completion markers;
- high-severity incident markers;
- starting/ending score;
- total progress delta.

The supplied BRD limits simultaneous category trend lines to five to avoid chart clutter.

## 82. Category Performance

Category Performance provides advanced statistical analysis:

- average;
- standard deviation;
- score distribution;
- teacher grading consistency;
- demographic splits where permitted;
- academic correlation.

The supplied BRD proposes a standard-deviation warning above 1.20 on a five-point scale. This should be normalized/configurable for other rating scales.

## 83. Incident Report

The Incident Report provides:

- weekly incident frequency;
- severity distribution;
- category distribution;
- top infraction triggers;
- witness counts;
- interventions and outcomes;
- incident detail grid.

---

# Part XVII — Audit and Compliance

## 84. Audit Trail

The audit trail records sensitive changes to behavioural information.

The supplied DDL describes `ba_audit_log` as immutable, with no update/delete timestamps.

## 85. Audited Events

The current design includes:

- assessment rating changes;
- assessment status transitions;
- incident changes.

The screen BRD additionally expects configuration and lock/change activities to be discoverable through the audit report.

## 86. Audit Details

A rating-change audit should identify:

- affected criterion;
- old value;
- new value;
- user;
- timestamp.

The supplied screen BRD also expects IP address visibility in audit reporting.

## 87. Audit Retention

The screen BRD proposes archiving/pruning audit records older than three years. This is a policy/compliance decision and should be formally approved before being made mandatory.

---

# Part XVIII — Privacy and Security

## 88. Behavioural Data Sensitivity

Behavioural records are sensitive student records and should be protected by role and purpose.

## 89. Information Sensitivity Levels

The system should distinguish access to:

- scores;
- teacher remarks;
- incident descriptions;
- witness statements;
- intervention details;
- audit information.

## 90. Parent Data

Parents should receive only finalized information permitted by school policy.

## 91. Anonymized Analytics

Cohort-level reports intended for general discussion should avoid unnecessary student identity exposure.

---

# Part XIX — Cross-Module Integration

## 92. SchoolSetup

The module depends on existing SchoolSetup entities for:

- students;
- employees;
- classes;
- class sections;
- academic sessions;
- academic terms;
- teacher assignment context.

BA should not duplicate these authoritative masters.

## 93. Exam/Result

The Result/Exam area consumes computed behavioural scores through the defined score-service concept.

BA remains responsible for behavioural data and does not directly write academic result tables.

## 94. Notification

Incident notification should use the central Notification capability rather than implementing a separate notification engine inside BA.

## 95. Media Storage

Incident evidence references may be stored through the Prime-AI media-storage mechanism.

---

# Part XX — Data Integrity Requirements

## 96. Master Deactivation

Historical masters should normally be deactivated rather than physically removed when historical assessments depend upon them.

## 97. Duplicate Prevention

The business model must prevent duplicate:

- scale levels within a scale;
- class/category mappings;
- teacher/class-section/period assessments;
- student/criterion ratings within an assessment;
- student remarks within an assessment;
- student/category/period computed scores;
- incident/witness links;
- incident/intervention links.

## 98. Historical Integrity

Changing a current category, criterion, scale level or weight must not silently alter the interpretation of finalized historical assessments.

This is one of the most important requirements to address in the next schema revision.

---

# Part XXI — End-to-End Workflows

## 99. New Academic Session

```text
Create/activate academic session
        ↓
Configure behavioural scale
        ↓
Review categories + criteria
        ↓
Map categories to classes
        ↓
Configure interventions
        ↓
Configure notification policy
        ↓
Create assessment periods
        ↓
Open assessment period
```

## 100. Teacher Assessment

```text
My Assessments
      ↓
Select class + section + period
      ↓
Load applicable categories/criteria
      ↓
Rate students
      ↓
Add criterion remarks
      ↓
Add overall remarks
      ↓
Auto-save
      ↓
Submit
```

## 101. Review

```text
Submitted
   ↓
Review Queue
   ├── Approve
   │     ↓
   │   Compute
   │     ↓
   │   Finalize/Lock
   │
   └── Send Back
         ↓
       Draft
         ↓
       Correct
         ↓
       Resubmit
```

## 102. Incident

```text
Behavioural event
      ↓
Incident Log
      ↓
Type + category + severity + description + location
      ↓
Evidence / witnesses
      ↓
Intervention(s)
      ↓
Notification if threshold met
      ↓
Follow-up
      ↓
Completion / resolution
```

---

# Part XXII — Business Rules Catalogue

## BR-BA-001 — Standardized Rating
Teachers shall use configured rating levels.

## BR-BA-002 — Session Configuration
Behavioural configuration is maintained in academic-session context.

## BR-BA-003 — Class Applicability
Only applicable categories should appear for a class according to mapping rules.

## BR-BA-004 — Assessment Uniqueness
A teacher cannot create duplicate class-section-period assessments.

## BR-BA-005 — Rating Uniqueness
A student/criterion can occur once per teacher assessment.

## BR-BA-006 — Multi-Teacher Averaging
Ratings from multiple authorized teachers can be averaged for the same student/criterion/period.

## BR-BA-007 — Negative Polarity
Negative categories are normalized through inversion.

## BR-BA-008 — Incident Core Immutability
Core incident facts cannot be silently altered after creation.

## BR-BA-009 — Review Control
Submitted assessments enter review when approval is enabled.

## BR-BA-010 — Lock Protection
Locked assessments cannot be edited.

## BR-BA-011 — Parent Finalization
Parent-facing results display finalized behavioural information only.

## BR-BA-012 — Immutable Audit
Audit records are insert-only from the application perspective.

## BR-BA-013 — Incident Notification
Incidents meeting the configured threshold trigger notification processing.

## BR-BA-014 — Follow-Up
Follow-up-required incidents expose follow-up tasks and dates.

## BR-BA-015 — Intervention Tracking
Applied interventions should be traceable through their lifecycle where that workflow is enabled.

## BR-BA-016 — Historical Preservation
Deactivation does not destroy historical behavioural evidence.

## BR-BA-017 — Module Boundary
BA does not directly modify authoritative SchoolSetup or Exam/Result transactional data.

## BR-BA-018 — Cached Reporting
Heavy reporting should preferentially use computed/cached data.

## BR-BA-019 — Sensitive Witness Data
Witness statements require elevated authorization.

## BR-BA-020 — Privacy-Aware Reporting
Aggregate reports may be anonymized where identity is unnecessary.

---

# Part XXIII — Requirements Requiring Explicit Product Decisions

## 103. Intervention Lifecycle vs Current DDL

The supplied screen BRD expects assigned staff, scheduled date, status, progress notes, completion date and cancellation justification. The current DDL does not represent all of these fields.

**Decision required:** retain the richer intervention case-management workflow and redesign the schema accordingly.

## 104. Rating Scale Granularity

The current DDL supports one active rating scale through session configuration. Some BRD examples discuss different scales for different age groups.

**Decision required:** one scale per session, or scale by class/class-group.

## 105. Approval vs Locking

The DDL has separate Reviewed and Locked states; some UI descriptions combine them.

**Decision required:** define exact state transitions and permissions.

## 106. Severity Vocabulary

DDL: minor/moderate/major/critical.  
Screen BRD: Info/Low/Medium/High.

**Decision required:** select one canonical terminology and define UI aliases if necessary.

## 107. Incident Resolution Lifecycle

The screen BRD implies incident closure/resolution, while the DDL mainly stores the event and follow-up fields.

**Decision required:** determine whether incident status itself requires a formal lifecycle.

## 108. Historical Master Versioning

Shared master records with active/inactive flags may not be enough to preserve exact historical definitions after weight/text/scale changes.

**Decision required:** determine whether finalized assessments must snapshot the applicable behavioural framework.

## 109. Incident Effect on Score

The current DDL explicitly keeps incidents separate from numeric score computation.

**Decision required:** retain this separation unless school policy later explicitly requires incident penalties/rewards to affect numerical scores.

## 110. Demographic Analytics

The supplied BRD describes gender-wise and enrolment-type comparisons.

**Decision required:** approve which demographic dimensions may be used and ensure privacy/role restrictions are applied.

---

# Part XXIV — Success Criteria

The module is successful when:

1. Teachers can assess behaviour using a consistent framework.
2. Schools can configure rating scales and behavioural criteria.
3. Categories can be targeted appropriately by class.
4. Assessment periods can be opened, closed and locked.
5. Teachers can enter large grids without unacceptable data-loss risk.
6. Supervisors can review and return submissions.
7. Scores are calculated consistently.
8. Negative categories are normalized correctly.
9. Multiple teacher assessments can be combined.
10. Incidents can be recorded independently from periodic assessment.
11. Serious incidents can include witnesses and evidence.
12. Interventions can be tracked through completion.
13. Parent notifications follow configured policy.
14. Behavioural progress is visible across periods.
15. Reports support individual and cohort analysis.
16. Sensitive information is role-protected.
17. Audit history provides accountability.
18. Result integration is available without tight database coupling.
19. Historical records remain meaningful after master changes.
20. Dashboard and report performance remains acceptable at school scale.

---

# Part XXV — DDL Coverage Summary

The supplied DDL defines **16 BA tables** across six dependency layers.

| Layer | Tables | Business Purpose |
|---|---|---|
| 1 | `ba_rating_scales`, `ba_categories`, `ba_interventions` | Foundation masters |
| 2 | `ba_rating_levels`, `ba_criteria` | Master details |
| 3 | `ba_class_category_jnt`, `ba_assessment_periods`, `ba_config` | Applicability and setup |
| 4 | `ba_assessments`, `ba_audit_log` | Assessment workflow and audit |
| 5 | `ba_assessment_ratings`, `ba_student_remarks`, `ba_computed_scores`, `ba_incidents` | Core transactions |
| 6 | `ba_incident_witnesses_jnt`, `ba_incident_intervention_jnt` | Incident relationships |

## Current Table Inventory

- `ba_rating_scales`
- `ba_categories`
- `ba_interventions`
- `ba_rating_levels`
- `ba_criteria`
- `ba_class_category_jnt`
- `ba_assessment_periods`
- `ba_config`
- `ba_assessments`
- `ba_audit_log`
- `ba_assessment_ratings`
- `ba_student_remarks`
- `ba_computed_scores`
- `ba_incidents`
- `ba_incident_witnesses_jnt`
- `ba_incident_intervention_jnt`

---

# Part XXVI — Business-to-Data Traceability

| Capability | Current Data Area |
|---|---|
| Rating scales | `ba_rating_scales` |
| Rating levels | `ba_rating_levels` |
| Categories | `ba_categories` |
| Criteria | `ba_criteria` |
| Class applicability | `ba_class_category_jnt` |
| Assessment periods | `ba_assessment_periods` |
| Session configuration | `ba_config` |
| Teacher assessments | `ba_assessments` |
| Student ratings | `ba_assessment_ratings` |
| Student remarks | `ba_student_remarks` |
| Computed scores | `ba_computed_scores` |
| Incidents | `ba_incidents` |
| Witnesses | `ba_incident_witnesses_jnt` |
| Intervention master/application | `ba_interventions`, `ba_incident_intervention_jnt` |
| Audit | `ba_audit_log` |

---

# Part XXVII — Recommended Final Review Checklist

Before using this BRD as the basis for final DDL redesign, approve:

- [ ] One rating scale per session vs class-specific scales.
- [ ] Canonical severity terminology.
- [ ] Intervention lifecycle and assignment model.
- [ ] Incident resolution lifecycle.
- [ ] Assigned-staff requirements for interventions.
- [ ] Completion/cancellation requirements.
- [ ] Parent notification recipients and channels.
- [ ] Seven-day delayed incident-entry policy.
- [ ] Exact description/remark validation limits.
- [ ] Criterion and category weight rules.
- [ ] Historical master versioning/snapshot requirements.
- [ ] Approval vs locking state model.
- [ ] Parent visibility rules.
- [ ] Student self-service scope.
- [ ] Audit retention period.
- [ ] At-risk thresholds.
- [ ] Period trend thresholds.
- [ ] Statistical standardization thresholds.
- [ ] Permitted demographic analytics.
- [ ] Academic correlation policy.
- [ ] Comment Bank scope.
- [ ] Whether incidents can ever influence numeric scores.
- [ ] Whether intervention effectiveness must be measured formally.
- [ ] Exact export formats and privacy rules.

---

# Part XXVIII — Final Business Vision

The Prime-AI Behavioural Assessment Module should become a **structured behavioural development platform**, not merely a behaviour-mark entry screen.

It should allow schools to:

- define clear behavioural expectations;
- assess students consistently;
- recognize positive behaviour;
- document negative behaviour objectively;
- capture supporting evidence;
- coordinate interventions;
- monitor follow-up;
- engage parents appropriately;
- identify longitudinal trends;
- detect grading inconsistency;
- protect sensitive student information;
- preserve an auditable historical record;
- and complement academic performance with meaningful behavioural insight.

> **Core principle:** Behavioural assessment should provide evidence-based insight into student development, not merely produce a grade.

---

# Source Boundary

This BRD is based on the two supplied artifacts only:

- `LMS_BehaviouralAssess_DDL_v2.sql`
- `_BRD_BehaviouralAssessment.md`

Where the source BRD contains richer UI/workflow expectations than the current DDL, those expectations have been retained as business requirements and flagged for schema reconciliation rather than silently discarded. Where the sources use different terminology or thresholds, the discrepancy is explicitly called out for product-owner confirmation.
