# BehaviouralAssessment — Complete Analysis Pack (FRD + Full BA Suite)
**Module:** Behavioural Assessment | **Code:** BA (legacy/doc code BHA) | **Live table prefix:** `ba_` | **Database layer:** Tenant (school) | **Date:** 2026-06-29
**Author:** Business Analyst (AI_Brain) | **Register:** Business language throughout, except the explicitly technical Data Dictionary (§13) and Dependency Map (§14).
**Sources read:** 24 V1 screen specs (`2-Module_Requirement_V1/BehaviouralAssessment_v2/`), 16 live tenant migrations (`Modules/BehaviouralAssessment/database/migrations/tenant/`), 16 Eloquent models, `BehaviouralScoreService`, routes, policies, and `BehaviouralAssess_DDL_v2.sql` (reference; stale `bha_` prefix). No consolidated V2 requirement exists.

> **Single source of truth.** This file assigns the canonical `REQ-/BR-/RPT-/ENH-` IDs the downstream DB Architect, Technical Auditor, Status_Analyzer, and Testing Architect reuse. **Never renumber.**
>
> **Schema-prefix note (load-bearing):** The live module uses the **`ba_`** prefix (confirmed by 16 tenant migrations + all 16 models + the V1 screen specs). The standalone DDL doc still uses `bha_` and is divergent/stale. All technical sections below use `ba_`.

---

## Section 0 — Index / Table of Contents
1. Module Overview (Purpose, Value, Scope, Terminology)
2. User Roles & Access (Actors, Role–Feature Matrix)
3. Functional Requirements (REQ-BA-001…018)
4. Business Rules Register (BR-BA-001…030)
5. Data Requirements (entities + privacy)
6. Workflows (6) & Exception Paths
7. Reporting & Analytics (RPT-BA-001…010) + KPI Catalog
8. Future Enhancement Log (ENH-BA-001…004)
9. Non-Functional Requirements (NFR-BA-001…012)
10. Gap Analysis Readiness Index (coverage table + totals)
11. Requirements Traceability Matrix (RTM)
12. Requirement Conditions Catalog + Validation & Edge-Case Catalog
13. Data Dictionary (technical register)
14. Cross-Module Dependency Map (technical register)
15. State Machine (FSM) Catalog
16. Risk Register (RISK-BA-001…008)
17. Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks
18. User Stories (Gherkin) for P0/P1 requirements

---

## Section 1 — Module Overview

### 1.1 Purpose
The Behavioural Assessment module lets a school systematically track, evaluate, and report student conduct and character development. It replaces subjective, ad-hoc feedback with a standardized, criteria-based framework: the school defines behavioural categories (e.g., Classroom Engagement, Respect, Leadership) and observable criteria under each, teachers rate students periodically using a configurable rating scale, behavioural scores are computed and (optionally) folded into the report card, and individual positive/negative incidents are logged with witnesses, interventions, and follow-up.

### 1.2 Business Value
- Gives parents and teachers a consistent, evidence-based picture of a child's behaviour each term, supporting Parent-Teacher Meetings and report cards.
- Satisfies CBSE/ICSE Continuous & Comprehensive Evaluation (CCE) expectations for co-scholastic assessment and a tamper-proof audit trail.
- Surfaces early-warning patterns (repeat incidents, hotspot locations, declining categories) so the school can intervene before issues escalate.
- Optionally contributes a weighted behavioural component (5–20%) to the final academic result, recognising holistic development per NEP-2020.

### 1.3 Scope

**In scope**
- Configuration of rating scales and their levels; behavioural categories and criteria (with positive/negative polarity and weighting); intervention master list.
- Mapping which categories apply to which class (grade level).
- Assessment periods (data-entry windows) with an open → closed → locked lifecycle.
- Per-school, per-session module configuration (active scale, result-integration toggle and weightage, aggregation method, parent-notification severity threshold).
- Teacher rating entry via a student × criterion grid with auto-save; overall per-student remarks.
- A review/approval workflow (submit → review/approve → lock) with send-back.
- Behavioural score computation (multi-teacher averaging, negative-polarity inversion, weighted category and overall scores, grade mapping) cached for fast retrieval.
- Incident logging (positive reinforcement / negative incident) with severity, location, witnesses, applied interventions, follow-up, and attachments.
- Severe-incident parent notification (severity-threshold driven).
- Pull-based integration that exposes behavioural scores to the Exam/Result module.
- An immutable audit trail of rating changes, status transitions, and incident edits.
- A dashboard plus a reports hub and standalone analytical reports (student, class, period, category, incident).

**Out of scope**
- Academic marks/grades (owned by Exam/Quiz/Marksheet modules); BA only *contributes* a behavioural component.
- Attendance tracking (separate module).
- Cross-school/cross-tenant benchmarking — data is isolated per school.
- Parent-side data entry or appeals workflow (parents are notified/viewers only).
- Disciplinary case management beyond the incident + intervention + follow-up record (no formal hearing/tribunal workflow).
- Automated counsellor case-load management.

### 1.4 Terminology
| Term | Meaning |
|------|---------|
| Rating Scale | The measurement instrument (e.g., "5-Point Behavioural Scale") with ordered levels and a numeric range; one scale is active per session. |
| Rating Level | A single step within a scale (e.g., "Outstanding" = 5) with a numeric value used in scoring. |
| Category | A top-level behavioural domain (e.g., "Leadership"); carries a **polarity** (positive or negative) and a proportional **weight**. |
| Polarity | Whether higher ratings are good (positive) or bad (negative). Negative categories are **inverted** during scoring. |
| Criterion | A single observable behaviour within a category, the thing a teacher actually rates. |
| Assessment Period | A time window (e.g., "Term 1 Assessment") during which teachers enter ratings; has its own open/closed/locked lifecycle. |
| Assessment | One teacher's submission for one class-section in one period (the parent of all that teacher's rating cells). |
| Computed Score | A cached behavioural score per student per category (and an overall score) for a period. |
| Incident | An ad-hoc behavioural event (positive or negative) logged for one student, independent of the rating grid. |
| Intervention | A standardized action taken in response to an incident (reward / corrective / counselling). |
| Result Integration | The optional inclusion of behavioural scores in the academic report card at a configured weightage. |
| Audit Trail | The tamper-proof, insert-only log of who changed what and when. |

---

## Section 2 — User Roles & Access

### 2.1 Actors
| Actor | Description |
|-------|-------------|
| School Admin / Principal | Configures scales, categories, criteria, interventions, class mappings, periods, and module settings. Reviews audit logs and analytics. Can act as final reviewer. |
| Class Teacher | Assesses all categories for all students in their own section; writes overall remarks; logs incidents; generates student report cards. |
| Subject Teacher | Rates students only on the categories mapped to their class; logs incidents/achievements; adds remarks. |
| Behavioural Counsellor / HOD | Reviews and approves/locks submitted assessments (Review Queue); tracks escalated incidents; coordinates interventions. |
| Parent | Recipient of severe-incident notifications and viewer of the student behavioural report (read-only). |
| Exam/Result module (system actor) | Pulls computed behavioural scores for report-card aggregation when integration is enabled. |

### 2.2 Role–Feature Matrix (C=Create, R=Read, U=Update, D=Delete/Archive, A=Approve)
| Feature | Admin/Principal | Class Teacher | Subject Teacher | Counsellor/HOD | Parent |
|---------|:---:|:---:|:---:|:---:|:---:|
| Rating Scales / Levels (REQ-BA-001) | C R U D | R | R | R | — |
| Categories / Criteria (REQ-BA-002) | C R U D | R | R | R | — |
| Interventions master (REQ-BA-003) | C R U D | R | R | R | — |
| Class–Category mapping (REQ-BA-004) | C R U D | R | R | R | — |
| Assessment Periods (REQ-BA-005) | C R U D + lifecycle | R | R | R | — |
| Module Configuration (REQ-BA-006) | C R U | R | R | R | — |
| My Assessments / Ratings entry (REQ-BA-007/008) | R | C R U (own) | C R U (own) | R | — |
| Student Remarks (REQ-BA-009) | R | C R U (own) | C R U (own) | R | — |
| Review / Approve / Lock (REQ-BA-010) | A | — | — | A | — |
| Score computation / recompute (REQ-BA-011) | trigger | — | — | trigger | — |
| Incident logging (REQ-BA-012/013/014) | C R U D | C R U (own) | C R U (own) | C R U | — |
| Result integration (REQ-BA-016) | configure | — | — | — | — |
| Audit Trail (REQ-BA-017) | R | — | — | R | — |
| Dashboard & Reports (REQ-BA-018, §7) | R | R (own scope) | R (own scope) | R | R (own child) |

> Authorization is enforced by the module's 17 policies. Data is isolated per school (database-per-tenant); no cross-school visibility.

---

## Section 3 — Functional Requirements

> Format per requirement: ID · Priority · Tags · Description · Actors · key BRs · Acceptance Criteria (YES/NO testable). Priority: Core (P0) / Standard (P1) / Enhanced (P2).

### REQ-BA-001 — Rating Scale & Level Management
**Priority:** Core (P0) · **Tags:** [CONFIGURATION][DATA_ENTRY]
Admin defines one or more rating scales, each with a code, name, grade type (letter/numeric/descriptive), a numeric range (min/max), and an ordered set of levels (label + numeric value). One scale is marked default. Scales and levels can be activated/deactivated, soft-deleted, and restored.
**Actors:** Initiates — Admin; Views — all staff. **BRs:** BR-BA-001, BR-BA-002, BR-BA-003, BR-BA-028.
**Acceptance Criteria:**
- Creating a scale requires code, name, grade type, min and max; min < max — else rejected.
- Each level's numeric value falls within the parent scale's [min, max]; two levels cannot share a sort position within a scale.
- Exactly one scale can be the default at a time.
- Deleting a scale soft-deletes its levels; a scale referenced by an active config cannot be force-deleted.

### REQ-BA-002 — Category & Criteria Management
**Priority:** Core (P0) · **Tags:** [CONFIGURATION][DATA_ENTRY]
Admin manages behavioural categories (name, description, polarity, weight, sort order, optional parent for sub-categories) and the criteria under each (name, description, weight, sort order). Categories/criteria can be reordered, toggled active, soft-deleted, and restored.
**Actors:** Initiates — Admin; Views — all staff. **BRs:** BR-BA-004, BR-BA-005, BR-BA-006, BR-BA-029.
**Acceptance Criteria:**
- A category must specify polarity (positive or negative); criteria inherit the parent's polarity (no separate field).
- Deleting a category cascades to its criteria; a criterion that already has ratings cannot be deleted (must be deactivated).
- Reordering persists the new sort order.

### REQ-BA-003 — Intervention Master Management
**Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
Admin maintains the master list of interventions, each typed reward / corrective / counselling, with description and display order. Schools may add custom interventions beyond the 9 seeded.
**Actors:** Initiates — Admin; Views — staff. **BRs:** BR-BA-007, BR-BA-030.
**Acceptance Criteria:**
- An intervention requires a name and a valid type.
- An intervention already linked to an incident cannot be deleted (must be deactivated).

### REQ-BA-004 — Class–Category Mapping
**Priority:** Standard (P1) · **Tags:** [CONFIGURATION]
Admin maps which categories apply to which class (grade level), so different age groups are assessed on different behaviours.
**Actors:** Initiates — Admin. **BRs:** BR-BA-008, BR-BA-009.
**Acceptance Criteria:**
- A (class, category) pair cannot be mapped twice.
- If a class has no mappings, all active categories apply to it (permissive default).
- The ratings grid for a class shows only criteria of its mapped categories.

### REQ-BA-005 — Assessment Period Management
**Priority:** Core (P0) · **Tags:** [CONFIGURATION][WORKFLOW]
Admin defines assessment periods within an academic session: name, start/end dates, submission deadline, and an optional link to an exam term. Periods move through open → closed → locked, and can be reopened from closed.
**Actors:** Initiates — Admin. **BRs:** BR-BA-010, BR-BA-011, BR-BA-012, BR-BA-026.
**Acceptance Criteria:**
- Start date < end date; deadline ≥ end date — else rejected.
- A period must belong to an academic session; the term link is optional.
- Closing a period blocks new assessments but leaves existing drafts editable; locking computes/finalises scores and blocks all edits.
- A locked period can only be reached from closed; locked is terminal (no reopen).

### REQ-BA-006 — Module Configuration
**Priority:** Core (P0) · **Tags:** [CONFIGURATION]
Admin configures the module per academic session: active rating scale, whether behavioural scores integrate into the report card (and at what weightage 5–20%), the aggregation method, and the parent-notification severity threshold. One configuration per session.
**Actors:** Initiates — Admin. **BRs:** BR-BA-013, BR-BA-014, BR-BA-015, BR-BA-016.
**Acceptance Criteria:**
- Exactly one configuration exists per academic session.
- The active rating scale cannot be changed once any rating has been recorded for that session.
- Weightage is accepted only within 5.0–20.0%.
- A configuration is auto-created with defaults (integration OFF) on first access if none exists.

### REQ-BA-007 — My Assessments (Teacher Hub)
**Priority:** Standard (P1) · **Tags:** [DASHBOARD][WORKFLOW]
A teacher sees the class-sections and periods they are responsible for, each assessment's status (draft/submitted/reviewed/locked), completion progress, and deadlines, with search/filter, and launches the ratings grid from here.
**Actors:** Initiates — Class/Subject Teacher. **BRs:** BR-BA-017.
**Acceptance Criteria:**
- A teacher sees only their own assessments; teacher-class responsibility is resolved from SchoolSetup (class-teacher and timetable allocations), not stored in BA.
- Each row shows status and progress; a locked or past-deadline assessment opens read-only.

### REQ-BA-008 — Ratings Grid Data Entry
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW]
The core entry screen: students as rows, mapped criteria as columns; each cell is a rating-level selection. Partial entry is allowed; values auto-save (~every 30s / on change); a live per-student rolling average is shown; an optional per-criterion remark can be added.
**Actors:** Initiates — Class/Subject Teacher. **BRs:** BR-BA-018, BR-BA-019, BR-BA-020, BR-BA-021, BR-BA-027.
**Acceptance Criteria:**
- One rating per student per criterion per assessment (re-rating overwrites).
- Unrated cells are permitted while in draft (stored as "not rated").
- Auto-save persists changes without a full submit; the UI confirms saved state.
- If the assessment is submitted/reviewed/locked or the period deadline has passed, the grid is read-only and save requests are rejected.
- Only one assessment can exist per teacher × class-section × period.

### REQ-BA-009 — Student Remarks
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
After rating, the teacher writes one holistic remark per student per assessment; it appears on the behavioural report and parent view.
**Actors:** Initiates — Teacher. **BRs:** BR-BA-022.
**Acceptance Criteria:**
- One overall remark per student per assessment (updating overwrites).
- Remarks become read-only once the assessment is submitted/locked.

### REQ-BA-010 — Review, Approval & Locking Workflow
**Priority:** Core (P0) · **Tags:** [APPROVAL][WORKFLOW]
Teachers submit completed assessments; the reviewer (Principal/HOD/Counsellor) sees a review queue, opens a submission, and either approves it (which triggers score computation) or sends it back to draft with remarks. Approved assessments are locked when the period locks.
**Actors:** Initiates — Teacher (submit); Processes — Reviewer (approve/send-back/lock). **BRs:** BR-BA-023, BR-BA-024, BR-BA-025, BR-BA-026.
**Acceptance Criteria:**
- Submit is allowed only from draft; approve only from submitted; send-back from submitted or reviewed returns to draft and requires reviewer remarks.
- Approval records reviewer and timestamp and triggers (re)computation for the class-section/period.
- When the approval workflow is disabled in configuration, a teacher submission is treated as approved/published directly.
- Status transitions are recorded in the audit trail.

### REQ-BA-011 — Behavioural Score Computation
**Priority:** Core (P0) · **Tags:** [CALCULATION][SCHEDULED]
The system computes scores from raw ratings: average each criterion across all teachers who rated it, invert negative-polarity criteria, weight-average criteria into category scores, weight-average categories into an overall score per the configured aggregation method, map to a grade, and cache the result per student/category/period.
**Actors:** Initiates — system (on approval) or Admin (manual recompute). **BRs:** BR-BA-001(inversion), BR-BA-019, BR-BA-020, BR-BA-021.
**Acceptance Criteria:**
- For a negative category, a worst raw rating yields the lowest contribution (inverted = max+1 − raw).
- Where multiple teachers rated the same student-criterion, the average is used.
- Category score = weighted average of its criterion scores by criterion weight; overall = weighted average of category scores by category weight (or simple average / separate display per configuration).
- Recomputation upserts the cache (no duplicate rows per student/category/period) and records when it was computed.

### REQ-BA-012 — Incident Logging
**Priority:** Core (P0) · **Tags:** [DATA_ENTRY][WORKFLOW][NOTIFICATION]
Staff log a positive reinforcement or negative incident for a student: date/time, type, severity (negative only), description, location, optional category/criterion link, free-text intervention notes, attachments, and follow-up scheduling. Core fields are immutable after creation; only follow-up fields remain editable.
**Actors:** Initiates — Teacher/Counsellor. **BRs:** BR-BA-013(notify), BR-BA-031… see Conditions; core: incident immutability + severity rules. **BRs:** BR-BA-013, and incident rules in §4/§12.
**Acceptance Criteria:**
- A negative incident requires a severity; a positive incident has no severity.
- After creation, student/date/type/severity/description/location cannot be changed; follow-up notes/date and notification flag can.
- Follow-up notes are appended (not overwritten); each addition is timestamped within the text.
- Creating an incident at or above the configured severity threshold queues a parent notification and sets the notified flag when sent.

### REQ-BA-013 — Incident Witnesses
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
Staff attach witnesses (students or staff) to an incident for corroboration.
**Actors:** Initiates — Teacher/Counsellor. **BRs:** BR-BA-027(witness uniqueness in §12).
**Acceptance Criteria:**
- The same person cannot be added twice as a witness on the same incident.
- A witness must reference a real student or employee (validated at the application layer; no database foreign key).
- Removing an incident removes its witnesses.

### REQ-BA-014 — Incident Interventions Applied
**Priority:** Standard (P1) · **Tags:** [DATA_ENTRY]
Staff link one or more interventions from the master list to an incident, each with optional context notes.
**Actors:** Initiates — Teacher/Counsellor. **BRs:** BR-BA-030.
**Acceptance Criteria:**
- The same intervention cannot be linked twice to the same incident.
- Free-text intervention notes on the incident and structured interventions can both be used.
- An intervention in use cannot be deleted from the master list.

### REQ-BA-015 — Severe-Incident Parent Notification
**Priority:** Standard (P1) · **Tags:** [NOTIFICATION][INTEGRATION]
When an incident meets/exceeds the configured severity threshold, the system notifies the parent via the Notification module and marks the incident as notified.
**Actors:** Initiates — system. **BRs:** BR-BA-013.
**Acceptance Criteria:**
- Threshold "moderate" notifies for moderate/major/critical; "critical" notifies only for critical, etc.
- Positive incidents never trigger a severity notification.
- The notified flag prevents duplicate alerts for the same incident.

### REQ-BA-016 — Result/Report-Card Integration (Pull-Based)
**Priority:** Core (P0) · **Tags:** [INTEGRATION][CALCULATION]
When integration is enabled for the session, the Exam/Result module pulls cached behavioural scores and blends them into the final result at the configured weightage. BA never writes to exam tables.
**Actors:** Processes — Exam/Result (consumer); Configures — Admin. **BRs:** BR-BA-014, BR-BA-015.
**Acceptance Criteria:**
- With integration OFF (default), no behavioural component is contributed.
- With integration ON, the behavioural contribution equals the normalised behavioural score × weightage% (5–20%).
- Scores are served from the cache (not recomputed at read time).

### REQ-BA-017 — Immutable Audit Trail
**Priority:** Core (P0) · **Tags:** [WORKFLOW][REPORT]
Every rating change, assessment status transition, and incident edit is recorded in an insert-only audit log capturing entity, field, old/new value, who, and when. The log can be viewed/filtered but never edited or deleted.
**Actors:** Initiates — system; Views — Admin/Counsellor. **BRs:** BR-BA-024.
**Acceptance Criteria:**
- Audit rows are never updated or deleted (no update/delete path exists).
- A rating change records both old and new values and the user.
- The audit view can filter by entity, user, and date range.

### REQ-BA-018 — Dashboard & Analytics Home
**Priority:** Standard (P1) · **Tags:** [DASHBOARD][REPORT]
A landing dashboard shows incident-frequency charts, pending-evaluation counts, recent activity, and behavioural trend highlights scoped to the user's role.
**Actors:** Views — Admin/Teacher/Counsellor. **BRs:** —.
**Acceptance Criteria:**
- A teacher's dashboard is scoped to their assessments; an admin sees school-wide figures.
- Counts (pending reviews, open follow-ups) reconcile with the underlying records.

---

## Section 4 — Business Rules Register

| BR ID | Rule (business statement) | Type | Trigger | Enforcement Point | Priority |
|-------|---------------------------|------|---------|-------------------|----------|
| BR-BA-001 | Negative-polarity scores are inverted: inverted = (scale max + 1) − raw rating. | Calculation | Score computation | BehaviouralScoreService | P0 |
| BR-BA-002 | A rating scale's min must be less than its max. | Validation | Scale create/update | Rating Scale screen | P0 |
| BR-BA-003 | Each level's numeric value lies within the scale's [min, max]; level positions are unique within a scale. | Validation | Level create/update | Rating Scale screen | P0 |
| BR-BA-004 | A category must declare a polarity (positive/negative); criteria inherit it. | Validation | Category create | Categories screen | P0 |
| BR-BA-005 | Deleting a category soft-deletes its criteria (cascade). | Workflow | Category delete | Categories screen | P1 |
| BR-BA-006 | A criterion that already has ratings cannot be deleted; deactivate instead. | Workflow | Criterion delete | Categories screen | P0 |
| BR-BA-007 | An intervention must have a valid type (reward/corrective/counselling). | Validation | Intervention create | Interventions screen | P1 |
| BR-BA-008 | A (class, category) mapping must be unique. | Validation | Class mapping create | Class Mapping screen | P1 |
| BR-BA-009 | A class with no category mapping is assessed on all active categories (permissive default). | Workflow | Grid build | Ratings grid | P1 |
| BR-BA-010 | Period start < end; deadline ≥ end. | Validation | Period create/update | Periods screen | P0 |
| BR-BA-011 | A period must belong to an academic session; term link is optional. | Validation | Period create | Periods screen | P0 |
| BR-BA-012 | Closing a period blocks new assessments; existing drafts stay editable; locking blocks all edits. | Workflow | Period close/lock | Periods lifecycle | P0 |
| BR-BA-013 | An incident at/above the configured severity threshold triggers a parent notification (positive incidents never do). | Workflow/Notification | Incident create | Incident service | P0 |
| BR-BA-014 | Behavioural scores contribute to the report card only when result integration is enabled for the session. | Workflow | Result aggregation | Config + integration API | P0 |
| BR-BA-015 | Result weightage must be between 5.0% and 20.0%. | Validation | Config save | Configuration screen | P0 |
| BR-BA-016 | Exactly one configuration may exist per academic session. | Validation | Config create | Configuration screen | P0 |
| BR-BA-017 | A teacher may view/edit only their own assessments. | Permission | Assessment access | Policies | P0 |
| BR-BA-018 | Only one assessment per teacher × class-section × period. | Validation/Concurrency | Assessment create | Assessment header | P0 |
| BR-BA-019 | One rating per student per criterion per assessment; re-rating overwrites. | Validation | Rating save | Ratings grid (upsert) | P0 |
| BR-BA-020 | Unrated cells are allowed while the assessment is in draft. | Validation | Rating save | Ratings grid | P1 |
| BR-BA-021 | Where multiple teachers rate the same student-criterion, the average is used in computation. | Calculation | Score computation | BehaviouralScoreService | P0 |
| BR-BA-022 | One overall remark per student per assessment; updating overwrites. | Validation | Remark save | Remarks screen | P1 |
| BR-BA-023 | Submit only from draft; approve only from submitted; send-back (to draft) only from submitted/reviewed and requires remarks. | Workflow | Status change | Review Queue | P0 |
| BR-BA-024 | Every rating change and status transition writes an immutable audit entry. | Workflow | Rating/status change | Audit log (insert-only) | P0 |
| BR-BA-025 | If the approval workflow is disabled in config, a teacher submission publishes directly (treated as approved). | Workflow | Submit | Review/Config | P1 |
| BR-BA-026 | A submitted/reviewed/locked assessment, or one in a closed/locked or past-deadline period, is read-only. | Workflow/Concurrency | Edit attempt | Ratings grid / Period | P0 |
| BR-BA-027 | The same person cannot be a witness twice on one incident; witness references are validated at the application layer (no DB FK). | Validation | Witness add | Witnesses screen | P1 |
| BR-BA-028 | Exactly one rating scale can be the school default at a time. | Validation | Scale default toggle | Rating Scale screen | P1 |
| BR-BA-029 | The active rating scale cannot be changed once any rating exists for the session. | Workflow | Config save | Configuration screen | P0 |
| BR-BA-030 | An intervention linked to any incident cannot be deleted; deactivate instead. | Workflow | Intervention delete | Interventions screen | P1 |

> Incident core-field immutability (only follow-up fields editable post-creation; negative incidents require severity) is catalogued in §12 (Conditions) and enforced by REQ-BA-012 acceptance criteria.

---

## Section 5 — Data Requirements (Business Entities + Privacy)

| Entity (business) | Holds | Privacy class |
|-------------------|-------|---------------|
| Rating Scale / Rating Level | Measurement instrument and its steps | Internal |
| Category / Criterion | Behavioural domains and observable behaviours; polarity, weight | Internal |
| Intervention | Standardized response actions | Internal |
| Class–Category Mapping | Which categories apply to which grade | Internal |
| Assessment Period | Data-entry windows, deadlines, lifecycle | Internal |
| Module Configuration | Active scale, integration toggle/weightage, aggregation, notification threshold | Internal |
| Assessment | Teacher submission header, status, reviewer remarks | Confidential |
| Rating | Per-student per-criterion rating + remark | **Sensitive (about a minor)** |
| Student Remark | Holistic behavioural remark per student | **Sensitive (about a minor)** |
| Computed Score | Cached behavioural scores/grades per student | **Sensitive (about a minor)** |
| Incident | Behavioural event: type, severity, description, location, attachments, follow-up | **Sensitive (about a minor)** |
| Incident Witness | Students/staff who witnessed an incident | **Sensitive** |
| Incident Intervention | Actions applied to an incident | Confidential |
| Audit Entry | Who changed what, when (immutable) | Confidential |

All student-related records are isolated per school (database-per-tenant) and term/session-scoped. Behavioural data about minors is treated as Sensitive: visible only to the child's teachers, the reviewer/counsellor, the admin, and the child's own parent.

---

## Section 6 — Workflows & Exception Paths

**WF-1 — School setup (once per session).** Admin creates/activates a rating scale + levels → defines categories + criteria → registers interventions → maps categories to classes → creates the module configuration (active scale, integration, threshold). *Exception:* attempting to switch the active scale after ratings exist → blocked with message (BR-BA-029).

**WF-2 — Open assessment period.** Admin creates a period (dates, deadline, optional term) and sets it open. *Exception:* deadline earlier than end date → rejected (BR-BA-010).

**WF-3 — Teacher rating entry.** Teacher opens My Assessments → launches grid → rates students cell-by-cell with auto-save and live averages → optionally writes per-criterion remarks → writes overall remarks → submits. *Exception:* period closed/locked or deadline passed → grid read-only (BR-BA-026). *Notification:* on submit, reviewer is alerted (when events wired).

**WF-4 — Review & approval.** Reviewer opens the review queue → reviews a submission → approves (records reviewer + timestamp, triggers computation) OR sends back to draft with remarks. *Exception:* send-back without remarks → rejected (BR-BA-023). *Bypass:* if approval workflow disabled, submission auto-publishes (BR-BA-025).

| Step | Recipient | Channel | Message |
|------|-----------|---------|---------|
| Submit | Reviewer | In-app/email | "Assessment for {Class-Section}, {Period} submitted for review by {Teacher}." |
| Send-back | Teacher | In-app/email | "Your assessment for {Class-Section} was returned for revision: {reviewer remarks}." |
| Approved + locked | Teacher | In-app | "Your assessment for {Class-Section}, {Period} has been approved and locked." |

**WF-5 — Score computation.** On approval (or manual recompute), the system averages ratings across teachers, inverts negatives, weights criteria→category→overall, maps grades, and upserts the cache. *Exception:* a student with no ratings is skipped (no score row). *Performance risk:* runs synchronously today — large schools risk timeout (see RISK-BA-003 / ENH-BA-003).

**WF-6 — Incident logging & follow-up.** Staff log an incident (with severity for negatives) → add witnesses + interventions → if severity ≥ threshold, parent is notified → optionally schedule follow-up → later append follow-up notes. *Exception:* attempt to edit a core field after creation → blocked (REQ-BA-012); negative incident without severity → rejected.

| Step | Recipient | Channel | Message |
|------|-----------|---------|---------|
| Severe incident | Parent | Email/SMS (via Notification) | "An incident involving {Student} was recorded on {date}. Please contact the school." |
| Follow-up due | Reporting staff | Dashboard reminder | "Follow-up for incident on {date} is due {follow_up_date}." |

---

## Section 7 — Reporting & Analytics + KPI Catalog

| RPT ID | Report | Purpose | Audience | Filters | Export |
|--------|--------|---------|----------|---------|--------|
| RPT-BA-001 | Student Scores Report | Student-wise composite + per-category scores for a period | Admin/Teacher | Class, section, period | CSV/Excel |
| RPT-BA-002 | Category Summary | Aggregated category statistics class-wise | Admin/HOD | Class, period, category | CSV/Excel |
| RPT-BA-003 | Period Report | Compare scores across periods/terms | Admin/HOD | Class, periods | CSV/Excel |
| RPT-BA-004 | Audit Trail Report | Who modified scores/status/config and when | Admin/Counsellor | Entity, user, date range | CSV/Excel |
| RPT-BA-005 | Student Report Card (Behavioural) | Holistic card: category scores, grades, remarks, incidents | Teacher/Parent | Student, period | PDF |
| RPT-BA-006 | Class Analysis | Comparative view across a section to spot outliers | Teacher/HOD | Class, section, period | PDF/Excel |
| RPT-BA-007 | Period Progress | Trend of a student/class across periods | Teacher/HOD | Student/class, periods | PDF |
| RPT-BA-008 | Category Performance | Mean/variance/std-dev per category | HOD/Admin | Class, period | Excel |
| RPT-BA-009 | Incident Report | Incident frequency, severity mix, location hotspots, outcomes | Admin/Counsellor | Date range, type, severity, location | CSV/Excel |
| RPT-BA-010 | Dashboard Analytics | Live charts: pending evaluations, incident frequency, trends | Admin/Teacher/HOD | Role scope | on-screen |

**KPI Catalog**
| KPI | Definition (business) | Source | Cadence |
|-----|-----------------------|--------|---------|
| Assessment completion rate | Submitted assessments ÷ expected assessments for a period | Assessments | Per period |
| Average behavioural score | Mean overall computed score for a class/school | Computed scores | Per period |
| Incident rate | Incidents per 100 students | Incidents | Monthly |
| Severe-incident share | Major+critical ÷ total negative incidents | Incidents | Monthly |
| Follow-up closure rate | Closed follow-ups ÷ follow-ups required | Incidents | Monthly |
| Review turnaround | Avg days from submit to approve | Assessments | Per period |

---

## Section 8 — Future Enhancement Log

| ENH ID | Enhancement | Basis | Notes |
|--------|-------------|-------|-------|
| ENH-BA-001 | Count-based incident escalation threshold (e.g., 3 negative incidents → auto counsellor alert) | V1 Configuration screen describes it; **not in live `ba_config`** (only severity threshold exists) | Add config field + escalation evaluator; promote to REQ on approval. |
| ENH-BA-002 | Multi-channel notification settings (Email HOD on submission, Daily Digest to Principal) | V1 Configuration screen checkbox group; not in schema | Extend config + Notification integration. |
| ENH-BA-003 | Queued `ComputeSchoolScoresJob` for school-wide recompute | Design intent; recompute is synchronous today | Move heavy recompute off-request to avoid timeouts (RISK-BA-003). |
| ENH-BA-004 | Wire `AssessmentApproved` / `IncidentCreated` events + listeners | `EventServiceProvider.$listen` empty; no observers | Decouple notifications/recompute from controllers; ensures triggers fire reliably. |

---

## Section 9 — Non-Functional Requirements

| NFR ID | Category | Requirement | Threshold |
|--------|----------|-------------|-----------|
| NFR-BA-001 | Performance | Ratings grid auto-save round-trip | < 1s typical |
| NFR-BA-002 | Performance | Behavioural score read for report card | O(1) cached lookup per student-period |
| NFR-BA-003 | Performance | School-wide recompute (large school ~5,000 students) | ≤ 30s, ideally queued (ENH-BA-003) |
| NFR-BA-004 | Scalability | Core rating fact volume | ~120,000 rows / 2,000-student school / year — indexed for student+criterion+assessment lookups |
| NFR-BA-005 | Security | Per-school data isolation | No cross-tenant access (database-per-tenant) |
| NFR-BA-006 | Security | Behavioural data about minors | Sensitive; restricted to child's staff, reviewer, admin, own parent |
| NFR-BA-007 | Compliance | Audit immutability for CBSE/ICSE CCE | Audit log insert-only; no update/delete path |
| NFR-BA-008 | Usability | Grid keyboard navigation + saved-state indicator | Full arrow/tab navigation; explicit "saved" feedback |
| NFR-BA-009 | Reliability | No data loss on session drop | Auto-save persists partial entry |
| NFR-BA-010 | Integrity | Active scale immutable after ratings exist | Enforced (BR-BA-029) |
| NFR-BA-011 | Availability | Reports/exports generate without blocking entry | Async/streamed for large exports |
| NFR-BA-012 | Maintainability | Live schema and DDL doc must agree | Regenerate DDL doc to `ba_` (resolve `bha_` divergence) |

---

## Section 10 — Gap Analysis Readiness Index

### 10.1 Coverage Table (downstream contract — Yes/No flags)
| Requirement ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|----------------|---------|----------|------|:---:|:---:|:---:|:---:|:---:|
| REQ-BA-001 | Rating Scale & Levels | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-BA-002 | Categories & Criteria | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-BA-003 | Interventions master | P1 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-BA-004 | Class–Category mapping | P1 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-BA-005 | Assessment Periods | P0 | CONFIG/WF | Yes | Yes | Yes | No | Yes |
| REQ-BA-006 | Module Configuration | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-BA-007 | My Assessments hub | P1 | DASH/WF | Yes | Yes | Yes | No | Yes |
| REQ-BA-008 | Ratings grid entry | P0 | DATA/WF | Yes | Yes | Yes | No | Yes |
| REQ-BA-009 | Student Remarks | P1 | DATA | Yes | Yes | Yes | No | Yes |
| REQ-BA-010 | Review/Approve/Lock | P0 | APPROVAL/WF | Yes | Yes | Yes | Yes | Yes |
| REQ-BA-011 | Score computation | P0 | CALC/SCHED | Yes | No | Yes | No | Yes |
| REQ-BA-012 | Incident logging | P0 | DATA/WF/NOTIF | Yes | Yes | Yes | Yes | Yes |
| REQ-BA-013 | Incident witnesses | P1 | DATA | Yes | Yes | Yes | No | Yes |
| REQ-BA-014 | Interventions applied | P1 | DATA | Yes | Yes | Yes | No | Yes |
| REQ-BA-015 | Severe-incident notification | P1 | NOTIF/INT | No | No | Yes | Yes | Yes |
| REQ-BA-016 | Result integration | P0 | INT/CALC | Yes | Yes | Yes | No | Yes |
| REQ-BA-017 | Immutable audit trail | P0 | WF/REPORT | Yes | Yes | Yes | No | Yes |
| REQ-BA-018 | Dashboard & analytics | P1 | DASH/REPORT | No | Yes | Yes | No | Yes |

### 10.2 Business-Rule Coverage
30 business rules (BR-BA-001…030) — 17 P0, 13 P1. Each maps to a screen/workflow enforcement point (see §4). Incident immutability and severity-required rules additionally enforced via REQ-BA-012 acceptance criteria + §12.

### 10.3 Report Coverage
10 reports (RPT-BA-001…010). 9 have backing data (computed scores / incidents / audit); RPT-BA-010 is a live aggregation view.

### 10.4 Totals (reconciled)
- **Functional Requirements:** 18 — **P0 = 10** (001,002,005,006,008,010,011,012,016,017), **P1 = 8** (003,004,007,009,013,014,015,018), **P2 = 0**. The 4 enhancements (ENH-BA-001…004) are the P2-tier backlog.
- **Business Rules:** 30 (P0 = 17, P1 = 13).
- **Reports:** 10.
- **Enhancements:** 4 (ENH-BA-001…004) — all P2.
- **Workflows:** 6 · **FSMs:** 2 · **NFRs:** 12 · **Risks:** 8 · **User Stories:** see §18.

> Authoritative REQ priority split (from §10.1): **P0 = 10, P1 = 8, P2 = 0** across 18 requirements; the 4 enhancements are the P2-tier backlog.

---

## Section 11 — Requirements Traceability Matrix (RTM)

| REQ-ID | BR refs | Screen(s) | Workflow | Report(s) | Live Code Status | Gap |
|--------|---------|-----------|----------|-----------|------------------|-----|
| REQ-BA-001 | 002,003,028 | Rating-Scales(02) | WF-1 | — | Controller+Model+Request+Policy present | Tests missing |
| REQ-BA-002 | 004,005,006,029 | Categories(03) | WF-1 | — | Present (reorder, criteria sub-routes) | Tests missing |
| REQ-BA-003 | 007,030 | Interventions(04) | WF-1 | — | Present | Tests missing |
| REQ-BA-004 | 008,009 | Class-Mapping(05) | WF-1 | — | Controller+Policy present | **No FormRequest**; tests missing |
| REQ-BA-005 | 010,011,012,026 | Periods(06) | WF-2 | — | Present (lock/unlock routes) | Tests missing |
| REQ-BA-006 | 013,014,015,016,029 | Configuration(07) | WF-1 | — | Present | Tests; verify scale-lock rule |
| REQ-BA-007 | 017 | My-Assessments(08) | WF-3 | — | Present (read scope) | Tests missing |
| REQ-BA-008 | 018,019,020,021,027 | Ratings(09) | WF-3 | — | Present (auto-save, bulk-rate) | **No FormRequest**; tests missing |
| REQ-BA-009 | 022 | Remarks(10) | WF-3 | — | Present | Tests missing |
| REQ-BA-010 | 023,024,025,026 | Review-Queue(11) | WF-4 | — | Present (submit/approve/send-back) | **No FormRequest**; verify auto-publish path; tests |
| REQ-BA-011 | 001,019,020,021 | — | WF-5 | — | BehaviouralScoreService present | **Synchronous (no job/event)**; tests missing |
| REQ-BA-012 | 013 + §12 | Incident-Log(12) | WF-6 | RPT-BA-009 | Controller+Model present | **No FormRequest**; verify immutability enforcement; tests |
| REQ-BA-013 | 027 | Witnesses(13) | WF-6 | — | Present | App-layer witness validation to verify; tests |
| REQ-BA-014 | 030 | Interventions-Applied(14) | WF-6 | — | Present (add/remove routes) | Tests missing |
| REQ-BA-015 | 013 | — | WF-6 | — | Inline in controller | **Event not wired**; verify it fires; tests |
| REQ-BA-016 | 014,015 | Configuration(07) | WF-5 | RPT-BA-001 | getBulkScores present | Consumer-side untested |
| REQ-BA-017 | 024 | Audit-Trail(19) | WF-3/4 | RPT-BA-004 | Model immutable; inline writes | **No observer** (inline only) — verify completeness; tests |
| REQ-BA-018 | — | Dashboard(01) | — | RPT-BA-010 | Present | Tests missing |

> RTM rows = 18 = §10.4 REQ total. Reports referenced reconcile to §7.

---

## Section 12 — Requirement Conditions Catalog + Validation & Edge-Case Catalog

### 12.1 Conditions Catalog (keyed to BR-IDs)
| Condition (=BR) | Entity/Field | Condition (business) | Type | Trigger | On-violation |
|-----------------|--------------|----------------------|------|---------|--------------|
| BR-BA-002 | Scale min/max | min < max | Validation | Save | Reject with message |
| BR-BA-003 | Level numeric value | within [min,max]; unique position | Validation | Save | Reject |
| BR-BA-010 | Period dates | start<end; deadline≥end | Validation | Save | Reject |
| BR-BA-015 | Weightage | 5.0 ≤ w ≤ 20.0 | Validation | Save | Reject |
| BR-BA-016 | Config/session | one per session | Validation | Create | Reject duplicate |
| BR-BA-018 | Assessment key | unique (teacher,class-section,period) | Concurrency | Create | Reject/return existing |
| BR-BA-019 | Rating key | unique (assessment,student,criterion) | Validation | Save | Upsert (overwrite) |
| BR-BA-026 | Edit window | not submitted/locked & deadline not passed | Workflow | Edit | Read-only / reject |
| BR-BA-029 | Active scale | no ratings exist for session | Workflow | Config save | Lock dropdown / reject |
| INC-1 | Incident severity | required when type=negative; null when positive | Validation | Create | Reject |
| INC-2 | Incident core fields | immutable post-creation | Workflow | Update | Reject (only follow-up editable) |
| BR-BA-027 | Witness | unique per incident; real student/staff | Validation | Add | Reject |

### 12.2 Validation & Edge-Case Catalog
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency |
|------------|-------|---------|----------|------------|-------------|
| Scale min/max | 1.0/5.0 | 5.0/1.0 | min=max (reject) | missing (reject) | — |
| Weightage | 10.0 | 25.0 | 5.0 & 20.0 ok; 4.9/20.1 reject | default 10 if config auto-created | — |
| Rating cell | a valid level | level from other scale | unrated allowed in draft | NULL = not rated | two teachers rate same cell → averaged |
| Period lock | closed→locked | open→locked (reject) | — | — | concurrent submit during close |
| Assessment create | new combo | duplicate combo | — | — | two requests for same combo → unique key blocks 2nd |
| Incident severity | "major" (negative) | "major" on positive | "critical" always notifies | positive severity null | duplicate notification prevented by notified flag |
| Audit entry | insert | update/delete attempt | — | old_value null on first record | — |

---

## Section 13 — Data Dictionary (TECHNICAL register — live `ba_` prefix)

> Three-way reconciled DDL doc ↔ migration ↔ model. **Live prefix `ba_`** (migrations + models). The DDL doc's `bha_` is stale. Structures match column-for-column; only the prefix differs.

| Table | Key columns | Notes |
|-------|-------------|-------|
| `ba_rating_scales` | id, code, name, grade_type, min_rating(3,1), max_rating(3,1), is_default, is_active, soft-delete | One active per session via `ba_config` |
| `ba_rating_levels` | id, rating_scale_id→ba_rating_scales (CASCADE), label, numeric_value(3,1), sort_order; UNIQUE(scale,sort_order) | Feeds computation |
| `ba_categories` | id, parent_id→self (SET NULL), name, polarity ENUM(positive,negative), weight(5,2), sort_order | Self-ref hierarchy |
| `ba_criteria` | id, category_id→ba_categories (CASCADE), name, weight(5,2), sort_order | Ratings RESTRICT delete |
| `ba_interventions` | id, name, intervention_type ENUM(reward,corrective,counselling), sort_order | RESTRICT delete if used |
| `ba_class_category_jnt` | id, class_id→sch_classes (CASCADE), category_id→ba_categories (CASCADE); UNIQUE(class_id,category_id) | Permissive default |
| `ba_assessment_periods` | id, academic_session_id→sch_org_academic_sessions_jnt (RESTRICT), academic_term_id→sch_academic_term (SET NULL, nullable), start_date, end_date, deadline, status ENUM(open,closed,locked) | Lifecycle |
| `ba_config` | id, academic_session_id→sessions (RESTRICT, UNIQUE), rating_scale_id→ba_rating_scales (constrained), is_result_integration_enabled, weightage_percent(4,1) def 10.0, aggregation_method ENUM(average,separate_display,weighted_average), parent_notification_threshold ENUM(minor,moderate,major,critical) | One per session; **no count-escalation field** (see ENH-BA-001) |
| `ba_assessments` | id, period_id→periods (RESTRICT), teacher_id→sch_employees (RESTRICT), class_section_id→sch_class_section_jnt (RESTRICT), status ENUM(draft,submitted,reviewed,locked), submitted_at, reviewed_by→sch_employees (SET NULL), reviewed_at, reviewer_remarks; UNIQUE(teacher,class_section,period) | FSM header |
| `ba_audit_log` | id, entity_type ENUM(assessment_rating,assessment,incident), entity_id, field_name, old_value, new_value, changed_by, changed_at; **model `$timestamps=false`, no updated_at/deleted_at** | IMMUTABLE; polymorphic |
| `ba_assessment_ratings` | id, assessment_id→assessments (CASCADE), student_id→std_students (RESTRICT), criterion_id→ba_criteria (RESTRICT), rating_level_id→ba_rating_levels (SET NULL, nullable=not rated), remark; UNIQUE(assessment,student,criterion) | Core fact table |
| `ba_student_remarks` | id, assessment_id→assessments (CASCADE), student_id→std_students (RESTRICT), remark_text; UNIQUE(assessment,student) | Holistic remark |
| `ba_computed_scores` | id, student_id→std_students (RESTRICT), category_id→ba_categories (RESTRICT), period_id→periods (RESTRICT), numeric_score(5,2), grade, overall_score(5,2) (first row), overall_grade, computed_at; UNIQUE(student,category,period) | Materialised cache; UPSERT |
| `ba_incidents` | id, student_id→std_students (RESTRICT), reported_by→sch_employees (RESTRICT), category_id (SET NULL), criterion_id (SET NULL), incident_date, incident_time, incident_type ENUM(positive_reinforcement,negative_incident), severity ENUM(minor,moderate,major,critical) nullable, description, location ENUM(8 values), intervention_notes, is_follow_up_required, follow_up_date, follow_up_notes, attachments_json, is_notified | Core fields immutable (app-layer) |
| `ba_incident_witnesses_jnt` | id, incident_id→incidents (CASCADE), witness_type ENUM(student,staff), witness_id (no DB FK — polymorphic); UNIQUE(incident,witness_type,witness_id) | App-layer integrity |
| `ba_incident_intervention_jnt` | id, incident_id→incidents (CASCADE), intervention_id→ba_interventions (RESTRICT), notes; UNIQUE(incident,intervention) | N:M |

All tables carry `is_active`, `created_by`/`updated_by` (sys_users.id), `created_at`/`updated_at`, and (except `ba_audit_log`) `deleted_at`. No `tenant_id` column (database-per-tenant).

---

## Section 14 — Cross-Module Dependency Map (TECHNICAL register)

**Inbound (BA reads, never writes):**
| Source module | Entity | Why |
|---------------|--------|-----|
| StudentProfile | `std_students` | Student being rated / incident subject / witness |
| SchoolSetup | `sch_employees` | Teacher (assessor), reviewer, reporter, staff witness |
| SchoolSetup | `sch_class_section_jnt` | Class+section scope of an assessment |
| SchoolSetup | `sch_classes` | Class–category applicability mapping |
| SchoolSetup | `sch_org_academic_sessions_jnt` | Session scoping (periods, config) |
| SchoolSetup | `sch_academic_term` | Optional period→term link |
| System | `sys_users` | created_by/updated_by/changed_by audit columns |

**Outbound (BA feeds):**
| Target module | Mechanism | What |
|---------------|-----------|------|
| Exam/Result | Service call `BehaviouralScoreService::getBulkScores($studentIds,$periodId)` (pull) | Cached behavioural scores for weighted result integration; gated by `ba_config.is_result_integration_enabled` |
| Notification | Severe-incident alert (intended via `IncidentCreated` event; **currently inline**) | Parent notification when severity ≥ threshold |
| Report card / Parent portal | Read of computed scores + remarks + incidents | Behavioural section of the student report card |

**Integration risks:** events not wired (`EventServiceProvider.$listen=[]`); recompute synchronous; verify notification + recompute actually fire from controllers (Technical Auditor Mode C).

---

## Section 15 — State Machine (FSM) Catalog

**FSM-1 — Assessment** (`ba_assessments.status`)
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| draft | submit() | grid sufficiently complete | submitted | submitted_at set; reviewer notified; audit entry |
| submitted | approve() | reviewer authorised | reviewed | reviewed_by/at set; **score computation triggered**; audit |
| submitted/reviewed | sendBack() | reviewer remarks present | draft | reviewer_remarks set; teacher notified; audit |
| reviewed | lock() | period locking | locked | terminal; audit |
Terminal: locked. Illegal (must block): draft→reviewed, draft→locked, submitted→locked, any edit of a locked assessment.

**FSM-2 — Assessment Period** (`ba_assessment_periods.status`)
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| open | close() | — | closed | new assessments blocked; drafts editable |
| closed | reopen() | — | open | entry resumes |
| closed | lock() | — | locked | scores finalised/cached; all edits blocked |
Terminal: locked. Illegal: open→locked (must close first), locked→anything.

---

## Section 16 — Risk Register

| Risk ID | Risk | Cat | L | I | Mitigation | Trigger |
|---------|------|-----|---|---|------------|---------|
| RISK-BA-001 | Stale DDL doc (`bha_`) vs live (`ba_`) misleads downstream agents | Tech-debt | H | M | Regenerate DDL doc from migrations; retire `bha_` doc | Any audit citing `bha_` tables |
| RISK-BA-002 | Zero tests on compliance-critical logic (audit immutability, inversion, FSM) | Quality | H | H | Testing Architect priority pack | Defect in scoring/audit |
| RISK-BA-003 | Synchronous school-wide recompute times out for large schools | Performance | M | H | Build queued ComputeSchoolScoresJob (ENH-BA-003) | Recompute > 30s |
| RISK-BA-004 | Parent notification / recompute may not fire (events unwired) | Functional | M | H | Verify inline triggers; wire events (ENH-BA-004) | Missing notifications |
| RISK-BA-005 | Missing FormRequests (rating/incident/mapping) → invalid data | Data integrity | M | M | Add `BaAssessmentRequest`/`BaIncidentRequest`/`BaClassCategoryRequest` | Bad rows / negative incident w/o severity |
| RISK-BA-006 | Active-scale change mid-session corrupts score interpretation | Data integrity | L | H | Enforce BR-BA-029 lock | Scale change attempt after ratings |
| RISK-BA-007 | Polymorphic witness has no DB FK → orphan references | Data integrity | M | L | App-layer existence validation | Deleted student/staff referenced |
| RISK-BA-008 | Sensitive minor data exposure across roles | Privacy/Compliance | L | H | Policy coverage + per-tenant isolation | Unauthorised access attempt |

---

## Section 17 — Prioritization (MoSCoW) + Effort Estimation

### 17.1 MoSCoW
- **Must (P0):** REQ-BA-001,002,005,006,008,010,011,012,016,017 (config foundation, periods, grid entry, review/approve, computation, incidents, result integration, audit).
- **Should (P1):** REQ-BA-003,004,007,009,013,014,015,018.
- **Could (P2 / backlog):** ENH-BA-001…004.
- **Won't (this release):** parent self-service appeals; cross-tenant benchmarking; formal disciplinary tribunal workflow.

### 17.2 Effort Estimation & Sprint Tasks (remaining work; most build exists)
| # | Task | Type | Effort(h) | Depends on | Sprint |
|---|------|------|-----------|------------|--------|
| 1 | Regenerate DDL doc to `ba_` from migrations | Schema/Doc | 3 | — | S1 |
| 2 | `BaAssessmentRequest` (rating save/submit/approve/send-back) | Backend | 6 | REQ-BA-008/010 | S1 |
| 3 | `BaIncidentRequest` (severity-required-when-negative; immutability) | Backend | 5 | REQ-BA-012 | S1 |
| 4 | `BaClassCategoryRequest` | Backend | 2 | REQ-BA-004 | S1 |
| 5 | `ComputeSchoolScoresJob` (queued) + manual recompute wiring | Backend/Integration | 8 | REQ-BA-011 | S2 |
| 6 | Wire `AssessmentApproved` + `IncidentCreated` events/listeners | Integration | 6 | REQ-BA-010/015 | S2 |
| 7 | Tests: polarity inversion + weighted avg | Testing | 8 | REQ-BA-011 | S2 |
| 8 | Tests: immutable audit + incident immutability | Testing | 6 | REQ-BA-017/012 | S2 |
| 9 | Tests: FSM transitions (assessment + period) | Testing | 6 | REQ-BA-010/005 | S3 |
| 10 | Verify/enforce active-scale lock (BR-BA-029) + tests | Backend/Testing | 4 | REQ-BA-006 | S3 |
| 11 | Reports/exports completeness pass (RPT-BA-001…009) | Backend/Frontend | 10 | §7 | S3 |
*Assumes schema + controllers + views already exist (verified).* 

---

## Section 18 — User Stories (Gherkin) — P0/P1

**US-BA-001 (REQ-BA-008, P0)** — As a Class Teacher, I want to rate students on each criterion in a grid so that I can record behaviour efficiently.
- Scenario happy: Given an open period and my draft assessment, When I select a level in a cell and tab away, Then it auto-saves and the student's rolling average updates.
- Scenario boundary: Given some cells unrated, When I leave the grid in draft, Then unrated cells are stored as "not rated" without error.
- Scenario permission-denied: Given an assessment that is submitted/locked or past deadline, When I try to edit a cell, Then the grid is read-only and the save is rejected.
- DoD: one rating per student/criterion (upsert); change written to audit log; teacher-scoped.

**US-BA-002 (REQ-BA-010, P0)** — As an HOD, I want to approve or send back submissions so that grades are quality-checked before publishing.
- Scenario approve: Given a submitted assessment, When I approve it, Then status→reviewed, reviewer+timestamp recorded, and computation is triggered.
- Scenario send-back: Given a submitted assessment, When I send it back without remarks, Then it is rejected; with remarks, status→draft and the teacher is notified.
- Scenario bypass: Given approval workflow disabled, When a teacher submits, Then the assessment publishes directly.
- DoD: transitions audited; notifications fired.

**US-BA-003 (REQ-BA-011, P0)** — As the System, I want to compute weighted behavioural scores so reports are accurate.
- Scenario inversion: Given a negative category, When a student is rated worst (max), Then the inverted contribution is lowest (max+1−raw).
- Scenario multi-teacher: Given two teachers rated the same student-criterion, When scores compute, Then the average is used.
- DoD: cache upserted (no duplicates); grade mapped; computed_at set.

**US-BA-004 (REQ-BA-012, P0)** — As a Teacher, I want to log an incident so behaviour is documented.
- Scenario negative: Given type=negative, When I omit severity, Then it is rejected.
- Scenario immutability: Given a saved incident, When I try to change its description, Then it is blocked; follow-up notes append.
- Scenario notify: Given severity ≥ threshold, When I save, Then a parent notification is queued and the incident marked notified.
- DoD: witnesses/interventions linkable; change audited.

**US-BA-005 (REQ-BA-006, P0)** — As an Admin, I want to configure the module per session so policies apply school-wide.
- Scenario integration: Given integration ON at 10%, When results aggregate, Then behavioural contributes 10%.
- Scenario scale-lock: Given ratings already exist, When I try to change the active scale, Then it is blocked with a message.
- DoD: one config per session; weightage 5–20 enforced.

**US-BA-006 (REQ-BA-005, P0)** — As an Admin, I want period lifecycle control so data entry windows are governed.
- Scenario lock: Given a closed period, When I lock it, Then scores finalise and edits are blocked.
- Scenario reopen: Given a closed period, When I reopen it, Then teachers can edit drafts again.
- DoD: open→locked blocked; deadline≥end enforced.

**US-BA-007 (REQ-BA-001, P0)** — As an Admin, I want to manage rating scales/levels so scoring is standardized.
- Scenario: Given a scale 1.0–5.0, When I add a level with value 6.0, Then it is rejected. DoD: one default; positions unique.

**US-BA-008 (REQ-BA-002, P0)** — As an Admin, I want categories/criteria with polarity/weight so scores reflect intent.
- Scenario: Given a criterion with ratings, When I delete it, Then it is blocked (deactivate instead). DoD: cascade on category delete.

**US-BA-009 (REQ-BA-016, P0)** — As the Exam module, I want to pull behavioural scores so the report card includes them.
- Scenario: Given integration OFF, When I pull, Then no behavioural component is contributed. DoD: O(1) cached read.

**US-BA-010 (REQ-BA-017, P0)** — As an Auditor, I want an immutable trail so compliance is provable.
- Scenario: Given an audit entry, When anyone tries to edit/delete it, Then there is no path to do so. DoD: filter by entity/user/date.

**US-BA-011 (REQ-BA-004, P1)** — As an Admin, I want to map categories to classes so younger grades aren't assessed on senior-only behaviours.
- Scenario: Given no mapping for a class, When the grid builds, Then all active categories apply. DoD: no duplicate mapping.

**US-BA-012 (REQ-BA-009, P1)** — As a Teacher, I want one holistic remark per student so the report card reads well.
- Scenario: Given a submitted assessment, When I edit a remark, Then it is read-only. DoD: one remark per student/assessment.

**US-BA-013 (REQ-BA-013, P1)** — As a Teacher, I want to add witnesses to an incident so it is corroborated.
- Scenario: Given a witness already added, When I add the same person again, Then it is rejected. DoD: app-layer existence check.

**US-BA-014 (REQ-BA-014, P1)** — As a Counsellor, I want to record interventions applied so outcomes are tracked.
- Scenario: Given an intervention already linked, When I link it again, Then it is rejected. DoD: notes per application.

**US-BA-015 (REQ-BA-015, P1)** — As a Parent, I want to be notified of a severe incident so I can engage.
- Scenario: Given a critical incident, When it is logged, Then I receive a notification. DoD: positive incidents never notify; no duplicate alerts.

**US-BA-016 (REQ-BA-007, P1)** — As a Teacher, I want a My Assessments hub so I can track what I owe.
- Scenario: Given another teacher's assessment, When I view my hub, Then I do not see it. DoD: status+progress shown.

**US-BA-017 (REQ-BA-003, P1)** — As an Admin, I want to manage interventions so responses are standardized.
- Scenario: Given an intervention in use, When I delete it, Then it is blocked. DoD: typed reward/corrective/counselling.

**US-BA-018 (REQ-BA-018, P1)** — As an Admin, I want a dashboard so I see pending reviews and incident trends at a glance.
- Scenario: Given pending reviews exist, When I open the dashboard, Then the count matches the review queue. DoD: role-scoped.

---

*End of BHA Complete Analysis Pack — 2026-06-29. IDs are canonical; downstream agents must reuse, not renumber.*
</content>
