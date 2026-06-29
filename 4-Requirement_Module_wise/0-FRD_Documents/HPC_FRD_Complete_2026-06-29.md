# HPC — Holistic Progress Card | Complete Analysis Pack (FRD + full BA suite)
**Module Code:** HPC | **Scope:** Tenant (database-per-school) | **Prefix:** `hpc_`
**Date:** 2026-06-29 | **Author:** Business Analyst
**Sources read:** V2 Requirement (`HPC_Hpc_Requirement.md`, 76 KB), V1 screen specs (`HPC_v2/` 10 tabs),
canonical DDL (`HPC_DDL_v2.sql`), tenant migrations (`database/migrations/tenant/*hpc*`), live module
code (`Modules/Hpc/` — 11 controllers, 16 models, 10 services, 192 views), Module Knowledge
(`HPC_Hpc.md`, re-verified 2026-06-29).
**Register:** Business language in §1–§9 and narrative sections; technical register confined to the
Data Dictionary technical view and the Dependency Map.

> **This is the single source of truth.** REQ-/BR-/RPT- IDs assigned here are stable and MUST be
> reused (never renumbered) by all downstream audits. A note on brownfield status: HPC is a partly
> built module; each requirement carries a **Build Status** (Built / Partial / Not Built) reflecting
> the live code, so the audit can separate "what is specified" from "what exists".

---

## Section 0 — Index / Table of Contents

| # | Section |
|---|---------|
| FRD §1 | Module Overview (purpose, value, scope, terminology) |
| FRD §2 | User Roles & Access |
| FRD §3 | Functional Requirements (REQ-HPC-001…019) |
| FRD §4 | Business Rules Register (BR-HPC-001…016) |
| FRD §5 | Data Requirements |
| FRD §6 | Workflows |
| FRD §7 | Reporting & Analytics (RPT-HPC-001…006) |
| FRD §8 | Future Enhancement Log (ENH-) |
| FRD §9 | Non-Functional Requirements |
| FRD §10 | Gap Analysis Readiness Index |
| Pack A | Requirements Traceability Matrix (RTM) |
| Pack B | Requirement Conditions Catalog + Validation & Edge-Case Catalog |
| Pack C | Process Flows + State Machine (FSM) Catalog |
| Pack D | Data Dictionary (business + technical) + Cross-Module Dependency Map |
| Pack E | NFR Catalog + Risk Register |
| Pack F | Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks |
| Pack G | User Stories (Gherkin) + Reporting/KPI Spec |
| Pack H | Feature Specification (key screens) |
| Pack I | Module Knowledge reference |

---

# FRD §1 — Module Overview

## 1.1 Purpose
The Holistic Progress Card module produces and manages each student's **Holistic Progress Card** — a
multi-dimensional assessment report aligned to India's NEP 2020 / PARAKH framework. It replaces the
traditional marks-only report card with a card that captures academic performance, life skills,
social-emotional growth, co-curricular participation, and observations gathered from four
contributors: the **teacher**, the **student** (self-reflection), the **parent/guardian**, and
**peer classmates**. The module coordinates this multi-contributor data entry, routes each card
through a formal approval workflow, produces a printable card, and distributes the finished card to
guardians.

## 1.2 Business Value
- **Compliance:** Delivers the NEP 2020 holistic report card schools are now required to issue.
- **360° view of the child:** Combines voices of teacher, student, parent and peers in one card.
- **Reduced manual effort:** Card structure is fully configurable, so a school changes its card
  layout without engineering work; attendance and learning data pre-fill automatically.
- **Governance:** A draft → review → publish workflow ensures the principal and administration sign
  off before a card reaches a parent.

## 1.3 Scope

### In Scope
- Configuring the four grade-band card templates (Foundational, Preparatory, Middle, Secondary) and
  their pages, sections, scored items, and grids.
- Teacher data-entry card with auto-filled attendance and (when available) learning data.
- Student self-assessment, parent observation (via secure link), and peer evaluation contributions.
- A six-stage approval workflow (draft, submitted, under review, finalised, published, archived).
- Printable card generation — single student and bulk (zipped) — plus emailed view-links to guardians.
- Attendance working-day configuration and month-wise attendance aggregation (April–March year).
- An activity-assessment overview consolidating multi-contributor progress.

### Out of Scope
- Marks/grade computation and aggregation across scoring modules — owned by Marksheet Generation.
- Subject syllabus and competency authoring — owned by the Syllabus module (HPC only references it).
- Question bank authoring — owned by Question Bank.
- Fee, transport, hostel, or any non-assessment student data.
- Cross-school / platform-level reporting — HPC data is isolated per school (database-per-tenant).
- **Curriculum-analytics tooling** (learning-outcome→question mapping, knowledge-graph validation,
  syllabus-coverage snapshots) is *specified* (REQ-HPC-002…006) but **not built in this module** and
  is treated as future/greenfield.

## 1.4 Terminology
| Term | Meaning |
|------|---------|
| Holistic Progress Card (HPC) | The NEP-aligned multi-dimensional student report this module produces |
| Card Template | The reusable definition of one grade band's card — its pages, sections and scored items |
| Grade Band | One of four NEP stages: Foundational (Pre-primary–G2), Preparatory (G3–5), Middle (G6–8), Secondary (G9–12) |
| Rubric / Scored Item | A single assessable field on the card (a descriptor, level, or value) |
| Contributor / Actor | A person who fills part of the card: Teacher, Student, Parent, or Peer |
| Card Status | The workflow stage of a student's card (Draft … Archived) |
| Parent Link | A secure, time-limited web link letting a guardian fill their section without logging in |
| Peer Cycle | One round of peer evaluation; templates define 1–9 cycles |
| Working Days | The configured number of school days per month used to compute attendance percentage |
| NCrF Credits | National Credit Framework credits derived from the student's grade level |

---

# FRD §2 — User Roles & Access

## 2.1 Actors
| Actor | Description |
|-------|-------------|
| Class Teacher | Primary author of the card; enters assessments, generates and emails the card |
| Student | Fills self-reflection / goals sections (Middle & Secondary cards) and acts as a peer reviewer |
| Parent / Guardian | Fills home-observation sections via a secure link; no system login |
| Peer (classmate) | Completes assigned peer-evaluation sections |
| Principal | Reviews submitted cards; approves or sends them back |
| School Admin | Publishes approved cards; archives; dispatches bulk emails |
| System | Aggregates attendance, computes credits, pre-fills learning data |

## 2.2 Role–Feature Matrix (Build Status in brackets)
| Feature | Teacher | Student | Parent | Peer | Principal | Admin |
|---------|:-------:|:------:|:------:|:----:|:---------:|:-----:|
| Configure card templates [Built] | View | — | — | — | — | Manage |
| Teacher data entry [Built] | Create/Edit | — | — | — | View | View |
| Student self-assessment [Partial] | View | Fill | — | — | View | View |
| Parent input via link [Partial] | Generate link | — | Fill | — | View | View |
| Peer evaluation [Partial] | Assign | Review | — | Fill | View | View |
| Generate card (single/bulk) [Built] | Yes | — | — | — | — | Yes |
| Approval workflow [Built] | Submit | — | — | — | Review/Send-back/Approve | Publish/Archive |
| Email distribution [Built] | Single | — | — | — | — | Bulk |
| Attendance config [Built] | — | — | — | — | — | Manage |
| Activity overview [Partial] | View | — | — | — | View | View |

> Authorization today is enforced by inline permission checks (`tenant.hpc.*`, `tenant.hpc-student.*`),
> not by Policy classes. See Risk RISK-HPC-002.

---

# FRD §3 — Functional Requirements

> Each requirement: ID, Priority (P0 Core / P1 Standard / P2 Enhanced), Category Tags, Build Status,
> business description, business rules, acceptance criteria. Sub-points use `.n`.

### REQ-HPC-001 — Card Template Management `[CONFIGURATION]` — P0 — **Built**
**Description.** The school can define and maintain the four grade-band card templates. Each template
is a four-level structure: the card itself → its pages → sections within a page → scored items within
a section (plus optional grid tables). Templates are fully data-driven: changing a card's layout never
requires engineering work.
- .1 Maintain card templates (code, version, title, applicable grades, active flag).
- .2 Maintain pages (order, help text, "has items" indicator).
- .3 Maintain sections within pages (code, order, "has items" indicator).
- .4 Maintain scored items / rubrics (mandatory, visible, printable flags).
- .5 Maintain the individual scored fields, each with a unique field key and an input type.
- .6 Soft-delete, restore, permanently delete, and activate/deactivate any template element.
**Rules:** BR-HPC-001, BR-HPC-013, BR-HPC-014. **Acceptance:** A configured template renders the
teacher card without code changes; a deactivated template is not offered for new cards; a deleted
template is recoverable from trash until permanently removed.

### REQ-HPC-002 — Assessment Parameter Configuration `[CONFIGURATION]` — P1 — **Not Built**
**Description.** The school can define the holistic ability parameters and the performance descriptors
(the rating language, e.g. "Beginning / Developing / Proficient") used across cards.
**Rules:** BR-HPC-003. **Acceptance:** Defined parameters and descriptors are selectable on scored
items. *Status note: specified in V2/V1; no supporting tables, models, or screens exist in code.*

### REQ-HPC-003 — Circular Goals & Competency Mapping `[CONFIGURATION]` — P2 — **Not Built**
**Description.** Map curricular goals to competencies so card outcomes can be traced to the curriculum.
**Rules:** BR-HPC-003. **Acceptance:** A goal links to one or more competencies. *Status note: not
implemented in HPC; competency data lives in the Syllabus module.*

### REQ-HPC-004 — Learning Outcomes & Question Mapping `[CONFIGURATION]` — P2 — **Not Built**
**Description.** Define learning outcomes and weight them against question-bank items.
**Acceptance:** An outcome can be linked to questions with weightage. *Status note: not implemented.*

### REQ-HPC-005 — Learning Activities `[CONFIGURATION]` — P2 — **Not Built**
**Description.** Catalogue learning activities (by type) usable as evidence on the card.
**Acceptance:** Activities can be created and typed. *Status note: not implemented.*

### REQ-HPC-006 — Curriculum Analytics Tools `[REPORT]` — P2 — **Not Built**
**Description.** Knowledge-graph validation, topic equivalency, and syllabus-coverage snapshots that
inform holistic assessment.
**Acceptance:** Coverage and integrity insights are produced. *Status note: specification only.*

### REQ-HPC-007 — Student Holistic Evaluation (ASC) `[DATA_ENTRY]` — P1 — **Not Built**
**Description.** Capture a structured holistic evaluation per student against the ASC ability
framework, feeding the card.
**Rules:** BR-HPC-003. **Acceptance:** An evaluation record exists per student/term and maps into the
card. *Status note: mapping service stub exists; no evaluation table/model.*

### REQ-HPC-008 — Teacher Data Entry Card `[DATA_ENTRY]` — P0 — **Built**
**Description.** A multi-page web card lets the class teacher enter all teacher-owned content for one
student. The card's pages and fields are generated entirely from the selected template. Attendance is
pre-filled automatically; learning data from the LMS pre-fills where available.
- .1 The system resolves the correct template from the student's grade band.
- .2 The card renders one tab per template page; sections and scored items appear in configured order.
- .3 Saving stores header data on the card record and each field's value in the field-value store,
  so any template works without structural changes.
- .4 Seven input types are supported (number, text, yes/no, choice, image, file, structured note).
- .5 Learning data (exam/quiz/homework) pre-fills when those modules have data; if absent the card
  opens with empty learning sections (no error).
- .6 Month-wise attendance pre-fills using the configured working days.
- .7 NCrF credits are computed from the student's grade level.
- .8 At most one card per student per term is maintained.
**Rules:** BR-HPC-001, BR-HPC-002, BR-HPC-003, BR-HPC-007, BR-HPC-008, BR-HPC-012, BR-HPC-015.
**Acceptance:** A teacher opens a student's card, sees pre-filled attendance, edits fields, saves, and
re-opening shows the saved values; saving a second time updates the same card rather than creating a
duplicate.

### REQ-HPC-009 — Student Self-Assessment Portal `[DATA_ENTRY]` — P1 — **Partial (no data store)**
**Description.** Middle and Secondary students see a dashboard of cards awaiting their input and fill
their self-reflection, goals and aspirations sections; only student-owned fields are editable.
- .1 Student dashboard lists pending cards with completion percentage.
- .2 Student fills and saves their sections; progress is tracked.
- .3 A goals-and-aspirations wizard is available for Secondary cards.
- .4 On final submission the student's section is locked as complete.
**Rules:** BR-HPC-003, BR-HPC-016. **Acceptance:** A student edits only their own fields; submitted
sections cannot be re-edited. *Status note: controllers, services and views exist, but the
student-submission table is missing, so saving currently fails at the data layer (GAP-DB-005).*

### REQ-HPC-010 — Parent Input Collection `[DATA_ENTRY][INTEGRATION]` — P1 — **Partial (no data store)**
**Description.** The teacher generates a secure, time-limited link that lets a guardian complete the
parent-observation sections without logging in. The guardian sees a simple dashboard, fills the form,
and submits.
- .1 Teacher generates a parent link for a card.
- .2 Guardian opens the link (no login) to a parent dashboard showing card status and any comments.
- .3 Guardian fills and submits parent-owned sections.
- .4 The link expires after seven days and cannot be reused once completed.
- .5 Teacher can view parent completion status.
**Rules:** BR-HPC-003, BR-HPC-005. **Acceptance:** A valid, unexpired, uncompleted link opens the
form; an expired or already-completed link shows an "expired" page and rejects submissions.
*Status note: token table missing (GAP-DB-004b), so link generation/validation fails at the data layer.*

### REQ-HPC-011 — Peer Assessment Workflow `[WORKFLOW][DATA_ENTRY]` — P1 — **Partial (no data store)**
**Description.** The teacher assigns peer reviewers; assigned students complete peer-evaluation
sections across the template's cycles. Assignment avoids self-review and reciprocal (A↔B) pairings.
- .1 Teacher triggers peer assignment for a card; the system auto-assigns reviewers.
- .2 Each assigned student sees a peer-review form for their assignee.
- .3 Peer responses are saved per cycle.
- .4 Teacher can view peer completion status.
**Rules:** BR-HPC-003, BR-HPC-006. **Acceptance:** No student is assigned to review themselves; if A
reviews B, B is not assigned to review A in the same cycle. *Status note: assignment/response tables
missing (GAP-DB-004c/d), so the feature fails at the data layer.*

### REQ-HPC-012 — Card Generation (Printable) `[REPORT]` — P0 — **Built**
**Description.** Produce a print-ready card for a single student or for a batch of students (delivered
as a downloadable archive). Output uses the four template-specific layouts and reflects all saved data.
- .1 Generate a single student's card on demand.
- .2 Generate cards for many students; package them into one downloadable archive.
- .3 Bulk generation is limited to 50 students per request (interim performance guard).
- .4 The archive download sanitises the requested file name.
**Rules:** BR-HPC-009, BR-HPC-011. **Acceptance:** A generated card shows the student's saved values
in the correct layout; a bulk request over 50 students is rejected with a clear message; an archive
file name containing unsafe characters is rejected.

### REQ-HPC-013 — Approval Workflow `[WORKFLOW][APPROVAL]` — P0 — **Built**
**Description.** Each card moves through Draft → Submitted → Under Review → Finalised → Published →
Archived. The teacher submits; the principal reviews, approves, or sends back (with a comment); the
admin publishes and may archive. Published and archived are terminal.
- .1 Teacher submits a draft card for review.
- .2 Principal starts review.
- .3 Principal approves (recording reviewer and time).
- .4 Principal sends back with a mandatory comment (to submitted or draft).
- .5 Admin publishes an approved card (recording publisher and time).
- .6 Admin archives a card (terminal).
- .7 The current status and the allowed next steps are viewable at any time.
- .8 Any disallowed transition is rejected with a clear message.
- .9 Status changes raise notifications to the relevant contributors. *(Enhancement — currently
  unimplemented stubs; see ENH-HPC-001.)*
**Rules:** BR-HPC-004. **Acceptance:** A card cannot skip stages; published/archived cards cannot be
edited or rolled back; sending back without a comment is refused.

### REQ-HPC-014 — Email Distribution `[NOTIFICATION][INTEGRATION]` — P0 — **Built**
**Description.** Guardians receive an email containing a secure **link to view** the card (not a PDF
attachment) plus an access code. Sending is queued; a single card or a batch can be dispatched.
- .1 Send a single card's link to its guardians.
- .2 Send a batch; report how many were sent and any per-student warnings.
- .3 Guardians without an email address are skipped with a logged warning.
- .4 The emailed link is access-controlled and shows a 30-day validity notice.
**Rules:** BR-HPC-010. **Acceptance:** A queued email is sent per guardian with a working view-link;
guardians lacking an email are skipped, not errored.

### REQ-HPC-015 — Student Card Snapshot `[REPORT]` — P2 — **Not Built**
**Description.** Store an immutable point-in-time snapshot of a published card per student/year for
historical comparison.
**Acceptance:** A snapshot is generated once and not overwritten. *Status note: model exists, table
missing (GAP-DB-006); no screen.*

### REQ-HPC-016 — Attendance Configuration & Aggregation `[CONFIGURATION]` — P1 — **Built**
**Description.** The admin configures the number of working days per month; the system aggregates each
student's monthly attendance (April–March academic year) for display on the card.
- .1 Configure working days per month.
- .2 View an attendance summary.
- .3 Attendance is aggregated at card load and recomputed at card generation.
**Rules:** BR-HPC-007. **Acceptance:** Changing working days changes the computed attendance
percentage; aggregation follows the April-to-March year.

### REQ-HPC-017 — NCrF Credit Calculation `[CALCULATION][CONFIGURATION]` — P1 — **Partial (calc only)**
**Description.** Compute National Credit Framework credits from the student's grade level for inclusion
on the card; allow school-specific overrides per grade.
**Rules:** BR-HPC-012. **Acceptance:** With no overrides, national default credits apply; an override
for a grade replaces the default. *Status note: calculation service exists with built-in national
defaults; the override configuration table/screen does not exist (GAP-DB-002), so overrides cannot
yet be entered.*

### REQ-HPC-018 — Activity Assessment Overview `[DASHBOARD][REPORT]` — P2 — **Partial**
**Description.** A consolidated view of a card's multi-contributor progress (teacher, student, parent,
peer) and activity assessment status.
**Acceptance:** The overview reflects each contributor's completion. *Status note: view exists but
depends on the missing parent/peer tables for complete data.*

### REQ-HPC-019 — Curriculum Change Request Workflow `[WORKFLOW]` — P2 — **Not Built**
**Description.** Allow a structured request-and-approval flow for curriculum changes (Draft →
Submitted → Approved/Rejected).
**Acceptance:** A request moves through its states with approver sign-off. *Status note: a table was
created by migration but there is no model, controller, screen, or service — it is an orphan.*

---

# FRD §4 — Business Rules Register

| BR ID | Rule (business statement) | Type | Trigger | Enforcement point |
|-------|---------------------------|------|---------|-------------------|
| BR-HPC-001 | The card template is chosen from the student's grade level; changing the student's class mid-term does not automatically re-assign the template | Workflow | Card open / template resolve | Template resolution in teacher card |
| BR-HPC-002 | At most one card exists per student per academic term | Validation | Card save | Unique constraint + save-or-update logic |
| BR-HPC-003 | Each section/field belongs to one contributor role; values submitted for fields not owned by the acting role are discarded and logged | Permission | Any contributor save | Role field-filter service |
| BR-HPC-004 | A card may only move along defined workflow transitions; disallowed moves are refused; Published and Archived are terminal | Workflow | Workflow action | Workflow service |
| BR-HPC-005 | A parent link expires seven days after creation and cannot be reused after completion; every open and submit re-checks expiry and completion | Validation | Parent link open/submit | Parent form service |
| BR-HPC-006 | Peer assignment must never assign a student to review themselves, nor create reciprocal (A↔B) pairs within a cycle | Validation | Peer auto-assign | Peer assignment service |
| BR-HPC-007 | Attendance is aggregated on an April-to-March academic year and recomputed both at card load and at card generation | Calculation | Card load / generation | Attendance service |
| BR-HPC-008 | If learning-data modules are absent or empty, the card opens with empty learning sections and no error | Workflow | Card load | LMS integration service (graceful fallback) |
| BR-HPC-009 | A bulk card-generation request is limited to 50 students | Validation | Bulk generate | Card generation action |
| BR-HPC-010 | Guardian emails carry a secure view-link and access code, never a file attachment | Workflow | Email dispatch | Email job |
| BR-HPC-011 | An archive download must reject any file name containing characters outside letters, digits, underscore, hyphen, and dot | Validation | Archive download | Download action |
| BR-HPC-012 | When a school has no credit overrides, national default credits apply; an override replaces the default for that grade | Calculation | Credit calculation | Credit calculator service |
| BR-HPC-013 | A template element in trash is recoverable until permanently deleted; permanent delete is irreversible | Workflow | Template delete/restore | Template controllers |
| BR-HPC-014 | A deactivated template is not offered for new cards but existing cards built on it remain valid | Validation | Template select | Template management |
| BR-HPC-015 | A published or archived card is read-only; its data cannot be edited by any contributor | Permission | Any edit attempt | Workflow + save guards |
| BR-HPC-016 | A contributor's section, once submitted as complete, cannot be re-edited by that contributor | Workflow | Section submit | Student/parent/peer submit actions |

---

# FRD §5 — Data Requirements

| Entity (business) | Purpose | Privacy | Build |
|-------------------|---------|---------|-------|
| Card Template (and pages, sections, scored items, grids) | Reusable definition of each grade band's card | Internal | Built |
| Student Card | One student's card for a term: header, status, audit trail | Confidential | Built |
| Card Field Values | The saved value of each scored field on a card | Confidential | Built |
| Card Grid Values | Saved grid/table cell values on a card | Confidential | Built |
| Parent Link | Secure time-limited guardian access token | Sensitive | **Missing table** |
| Peer Assignment / Peer Response | Who reviews whom, and their answers | Confidential | **Missing tables** |
| Student Self-Submission | Student-entered section data | Confidential | **Missing table** |
| Card Snapshot | Immutable historical copy of a published card | Confidential | **Missing table** |
| Working-Days Configuration | Per-month school working days | Internal | Built (in settings) |
| Assessment Parameters / Descriptors / Goals / Outcomes / Activities / Evaluation | Curriculum-analytics layer | Internal | **Not built** |

Privacy: card content is **Confidential** (child academic & behavioural data); parent links are
**Sensitive** (unauthenticated access vector). All HPC data is isolated per school (database-per-tenant).

---

# FRD §6 — Workflows

### Workflow 1 — Card Approval (Built)
**Trigger:** Teacher completes data entry. **End states:** Published / Archived.
**Swimlanes:** Teacher | Principal | Admin | System.
1. Teacher submits the card → status **Submitted** (records submit time).
2. Principal starts review → **Under Review**.
3. Decision — Principal approves → **Finalised** (records reviewer + time) OR sends back (with
   mandatory comment) → **Submitted** or **Draft**.
4. Admin publishes the finalised card → **Published** (records publisher + time).
5. Admin may archive → **Archived** (terminal).
**Exception paths:** disallowed transition → refused with message; send-back without comment → refused.
**Notifications:** on each status change, notify the relevant contributor *(ENH-HPC-001 — not yet built)*.

### Workflow 2 — Parent Input via Link (Partial)
**Trigger:** Teacher generates a parent link. **End states:** Completed / Expired.
1. Teacher generates link → guardian receives URL.
2. Guardian opens link → system validates not expired and not completed.
3. Guardian fills and submits → parent section locked complete.
**Exception paths:** expired or completed link → "expired" page, submission refused.
**Notifications:** none defined today.

### Workflow 3 — Peer Assessment (Partial)
**Trigger:** Teacher triggers peer assignment. **End states:** All cycles completed.
1. System auto-assigns reviewers honouring no-self / no-reciprocal rules.
2. Each reviewer completes their peer form per cycle.
3. Teacher monitors completion.
**Exception paths:** insufficient eligible peers → assignment reports shortfall.

### Workflow 4 — Bulk Card Generation & Distribution (Built)
**Trigger:** Teacher/Admin requests bulk generation. **End:** Archive downloaded / emails queued.
1. Validate ≤ 50 students.
2. Generate each card; package into one archive; stream download (file deleted after send).
3. Optionally dispatch guardian view-link emails (queued), skipping guardians without email.
**Exception paths:** over-limit → refused; per-student generation error → collected and reported.

---

# FRD §7 — Reporting & Analytics

| RPT ID | Report | Audience | Frequency | Contents | Export | Build |
|--------|--------|----------|-----------|----------|--------|-------|
| RPT-HPC-001 | Single Student Card | Teacher, Guardian | On demand | Full holistic card for one student/term | PDF | Built |
| RPT-HPC-002 | Bulk Card Pack | Teacher, Admin | On demand | Many students' cards in one archive | ZIP of PDFs | Built |
| RPT-HPC-003 | Attendance Summary | Teacher, Admin | On demand | Month-wise attendance vs working days | Screen | Built |
| RPT-HPC-004 | Activity Assessment Overview | Teacher, Principal | On demand | Multi-contributor completion & activity status | Screen | Partial |
| RPT-HPC-005 | Workflow Status | Teacher, Principal, Admin | On demand | Current stage, audit trail, allowed next steps | Screen/JSON | Built |
| RPT-HPC-006 | Contributor Completion (Parent/Peer) | Teacher | On demand | Parent/peer link & assignment completion | Screen | Partial (depends on missing tables) |

---

# FRD §8 — Future Enhancement Log

| ENH ID | Enhancement | Origin | Promote-to |
|--------|-------------|--------|-----------|
| ENH-HPC-001 | Workflow status-change notifications (email/in-app) to contributors | V2 FR-013.9 | REQ-HPC-013.9 |
| ENH-HPC-002 | Rate-limit and cap (100/req) on bulk email dispatch | V2 FR-014.9 | REQ-HPC-014 |
| ENH-HPC-003 | Move bulk card generation to a background job (remove 50-student cap) | V2 FR-012 | REQ-HPC-012 |
| ENH-HPC-004 | Card-template layout caching for performance | NFR | NFR-HPC-05 |
| ENH-HPC-005 | Snapshot trend-comparison view across years | V2 FR-015.4 | REQ-HPC-015 |
| ENH-HPC-006 | Build the curriculum-analytics layer (parameters, goals, outcomes, evaluation, coverage) | V2 FR-002…007 | REQ-HPC-002…007 |

---

# FRD §9 — Non-Functional Requirements

## 9.1 Performance
- Bulk card generation must complete within the request budget; until backgrounded, a 50-student cap
  applies (BR-HPC-009). Template hierarchies should be cached to avoid repeated structural reads.
## 9.2 Security
- All authenticated HPC features must be gated by the HPC module entitlement and per-action
  permissions. The public card-view and parent-link routes are the primary exposure surface and must
  enforce access controls on every request (see Risk Register). **Card generation currently lacks an
  authorization check (BUG-HPC-016) — a P0 defect.**
- Card data is child academic data (Confidential); parent links are Sensitive and time-limited.
## 9.3 Usability
- The teacher card must render correctly for all four grade-band templates with no per-template code.
- Empty states (no learning data, no attendance) must degrade gracefully without errors.
## 9.4 Multi-tenancy
- All HPC data is isolated per school (database-per-tenant); no cross-school access or reporting.
## 9.5 Scalability
- Designed for whole-class and whole-grade batch generation (hundreds of students per academic year).

---

# FRD §10 — Gap Analysis Readiness Index

## 10.1 Requirement Coverage Table
| REQ ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|--------|---------|----------|------|:-----------------:|:-------------:|:----------:|:-------------------:|:----------------:|
| REQ-HPC-001 | Template Mgmt | P0 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HPC-002 | Param Config | P1 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HPC-003 | Circular Goals | P2 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HPC-004 | Learning Outcomes | P2 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HPC-005 | Learning Activities | P2 | CONFIG | Yes | Yes | Yes | No | Yes |
| REQ-HPC-006 | Curriculum Analytics | P2 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HPC-007 | Student Evaluation | P1 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-HPC-008 | Teacher Card | P0 | DATA_ENTRY | Yes | Yes | Yes | No | Yes |
| REQ-HPC-009 | Student Self-Assess | P1 | DATA_ENTRY | Yes | Yes | Yes | Yes | Yes |
| REQ-HPC-010 | Parent Input | P1 | DATA_ENTRY/INTEGRATION | Yes | Yes | Yes | Yes | Yes |
| REQ-HPC-011 | Peer Assessment | P1 | WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-HPC-012 | Card Generation | P0 | REPORT | No | Yes | Yes | No | Yes |
| REQ-HPC-013 | Approval Workflow | P0 | WORKFLOW/APPROVAL | Yes | Yes | Yes | Yes | Yes |
| REQ-HPC-014 | Email Distribution | P0 | NOTIFICATION | No | No | Yes | Yes | Yes |
| REQ-HPC-015 | Card Snapshot | P2 | REPORT | Yes | Yes | Yes | No | Yes |
| REQ-HPC-016 | Attendance Config | P1 | CONFIG | No | Yes | Yes | No | Yes |
| REQ-HPC-017 | NCrF Credits | P1 | CALCULATION | Yes | Yes | Yes | No | Yes |
| REQ-HPC-018 | Activity Overview | P2 | DASHBOARD | No | Yes | Yes | No | Yes |
| REQ-HPC-019 | Curriculum Change Req | P2 | WORKFLOW | Yes | Yes | Yes | Yes | Yes |

## 10.2 Business Rule Coverage
16 business rules (BR-HPC-001…016). Types: Validation 6, Workflow 6, Permission 2, Calculation 3
(BR-007/012 overlap calc+config). Each rule maps to ≥1 REQ in the RTM (Pack A).

## 10.3 Report Coverage
6 reports (RPT-HPC-001…006): 2 built PDF outputs, 1 built screen, 2 partial screens, 1 built status view.

## 10.4 Totals
- **Functional Requirements:** 19 (REQ-HPC-001…019)
- **Business Rules:** 16 (BR-HPC-001…016)
- **Reports:** 6 (RPT-HPC-001…006)
- **Enhancements:** 6 (ENH-HPC-001…006)
- **Priority split:** P0 = 5 (REQ-001, 008, 012, 013, 014) · P1 = 6 (REQ-002, 007, 009, 010, 011, 016, 017 → note 7) · P2 = 7 (REQ-003, 004, 005, 006, 015, 018, 019)
  - Recount: **P0 = 5, P1 = 7 (002,007,009,010,011,016,017), P2 = 7 (003,004,005,006,015,018,019)** → 5+7+7 = 19 ✓
- **Build split:** Built = 7 (001, 008, 012, 013, 014, 016, + RPT core) · Partial = 5 (009, 010, 011, 017, 018) · Not Built = 7 (002, 003, 004, 005, 006, 007, 015, 019 → 8). Recount: Built 6 (001,008,012,013,014,016), Partial 5 (009,010,011,017,018), Not Built 8 (002,003,004,005,006,007,015,019) → 6+5+8 = 19 ✓

---

# Pack A — Requirements Traceability Matrix (RTM)

| REQ | BR refs | Screen(s) | Workflow | Report | Code Status | Primary Gap |
|-----|---------|-----------|----------|--------|-------------|-------------|
| REQ-HPC-001 | 001,013,014 | Template CRUD screens | — | — | Built | none material |
| REQ-HPC-002 | 003 | (none) | — | — | Not Built | no table/screen |
| REQ-HPC-003 | 003 | (none) | — | — | Not Built | no table |
| REQ-HPC-004 | — | (none) | — | — | Not Built | no table |
| REQ-HPC-005 | — | (none) | — | — | Not Built | no table |
| REQ-HPC-006 | — | (none) | — | RPT-006? | Not Built | no table |
| REQ-HPC-007 | 003 | (none) | — | — | Not Built | no evaluation table |
| REQ-HPC-008 | 001,002,003,007,008,012,015 | Teacher card (4 form sets) | WF1 | RPT-001/003 | Built | controller size |
| REQ-HPC-009 | 003,016 | Student dashboard/form/goals | — | — | Partial | GAP-DB-005 (no table) |
| REQ-HPC-010 | 003,005 | Parent dashboard/form/expired/thank-you | WF2 | RPT-006 | Partial | GAP-DB-004b (no table) |
| REQ-HPC-011 | 003,006 | Peer review form | WF3 | RPT-006 | Partial | GAP-DB-004c/d (no tables) |
| REQ-HPC-012 | 009,011 | (action) | WF4 | RPT-001/002 | Built | sync 50 cap; BUG-HPC-016 |
| REQ-HPC-013 | 004,015 | Workflow status | WF1 | RPT-005 | Built | no notifications |
| REQ-HPC-014 | 010 | (action) | WF4 | — | Built | no rate-limit |
| REQ-HPC-015 | — | (none) | — | — | Not Built | GAP-DB-006 (no table) |
| REQ-HPC-016 | 007 | Attendance config/summary | — | RPT-003 | Built | none material |
| REQ-HPC-017 | 012 | (none for override) | — | — | Partial | GAP-DB-002 (no config table) |
| REQ-HPC-018 | — | Activity overview | — | RPT-004 | Partial | depends on missing tables |
| REQ-HPC-019 | — | (none) | — | — | Not Built | orphan table, no code |

> Test ref column intentionally empty — there are **zero** automated tests in the module today; every
> row is a test-coverage gap (handoff to Testing Architect).

---

# Pack B — Requirement Conditions Catalog + Validation & Edge-Case Catalog

### B.1 Conditions Catalog (keyed to BR IDs)
| Condition (=BR) | Entity/Field | Condition (business) | Type | On-violation |
|-----------------|--------------|----------------------|------|--------------|
| BR-HPC-002 | Card (student, term) | Only one card per student per term | Validation | Update existing instead of creating duplicate |
| BR-HPC-003 | Any contributor field | Field must belong to acting role | Permission | Discard + log unauthorised field |
| BR-HPC-004 | Card status | Transition must be in the allowed set | Workflow | Refuse with message |
| BR-HPC-005 | Parent link | Not expired AND not completed | Validation | Show expired page; refuse submit |
| BR-HPC-006 | Peer assignment | No self / no reciprocal pair | Validation | Re-shuffle / report shortfall |
| BR-HPC-009 | Bulk request | ≤ 50 students | Validation | Refuse over-limit request |
| BR-HPC-011 | Archive file name | Only `[A-Za-z0-9_.-]` | Validation | Reject with 400 |
| BR-HPC-015 | Published/archived card | Read-only | Permission | Refuse edits |
| BR-HPC-016 | Submitted section | Locked after submit | Workflow | Refuse re-edit |

### B.2 Validation & Edge-Case Catalog
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency |
|------------|-------|---------|----------|------------|-------------|
| Card per student/term | one save | second create | exactly one | no card yet → create | two teachers saving same card → last write / update-or-create guards |
| Parent link | day 1–7, uncompleted | day 8+ | exactly day 7 23:59 | missing token → 404 | two opens of same link → completion check |
| Peer assignment | distinct reviewer | self-review | min eligible peers | class of 1 → cannot assign | concurrent assign → idempotent |
| Bulk generate | 50 students | 51 students | exactly 50 | 0 students → refuse | parallel bulk → independent archives |
| Archive download | `card_123.zip` | `../../etc/passwd` | single dot ok | empty name → 400 | concurrent download → file-per-request |
| Attendance % | working days set | working days 0 | 100% present | no attendance rows → 0/blank | config edit during generation → recompute uses latest |
| Workflow transition | draft→submitted | published→draft | review→back | no card → 404 | double-submit → second refused (not in draft) |

---

# Pack C — Process Flows + State Machine (FSM) Catalog

(Process flows are detailed in FRD §6.) FSMs:

### FSM 1 — Card Status
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| draft | submit | teacher owns card | submitted | record submit time |
| submitted | review | principal | under_review | — |
| under_review | approve | principal | final | record reviewer + time |
| under_review | send-back | comment present | submitted/draft | record comment |
| final | publish | admin | published | record publisher + time; (notify — ENH) |
| published | archive | admin | archived | terminal |
**Terminal:** published, archived. **Illegal (must block):** any skip, any rollback from published/archived.

### FSM 2 — Parent Link
| From | Event | Guard | To |
|------|-------|-------|----|
| pending | open/submit | not expired & not completed | pending/completed |
| pending | time passes | past 7 days | expired |
**Terminal:** completed, expired. *(Backing table missing.)*

### FSM 3 — Peer Assignment
pending → in_progress → completed (terminal). *(Backing table missing.)*

### FSM 4 — Curriculum Change Request *(orphan, no code)*
DRAFT → SUBMITTED → APPROVED/REJECTED (terminal).

---

# Pack D — Data Dictionary + Cross-Module Dependency Map

### D.1 Data Dictionary — Business View
| Business field | Meaning | Required | Privacy |
|----------------|---------|----------|---------|
| Template / Page / Section / Item | Card structure definition | Yes | Internal |
| Card header | Student, term, session, template, status | Yes | Confidential |
| Card field value | One scored field's value | Per template | Confidential |
| Card grid value | Grid cell value | Per template | Confidential |
| Workflow audit | Submit/review/publish actor + time + comments | System | Internal |
| Parent link | Token, expiry, completed time | Yes | Sensitive |
| Peer assignment/response | Reviewer↔reviewee, answers, cycle | Yes | Confidential |
| Working days config | Per-month school days | Yes | Internal |

### D.2 Data Dictionary — Technical View (technical register)
| Table | Status | Notes |
|-------|--------|-------|
| `hpc_templates`, `hpc_template_parts`, `hpc_template_parts_items`, `hpc_template_sections`, `hpc_template_section_items`, `hpc_template_section_table`, `hpc_template_rubrics`, `hpc_template_rubric_items` | DDL+migration+model ✓ | Template hierarchy |
| `hpc_reports` | DDL+migration+model ✓ | Header; status ENUM vs 6-state model mismatch (GAP-DB-003); workflow audit columns to confirm |
| `hpc_report_items`, `hpc_report_table` | DDL+migration+model ✓ | Field-value + grid stores |
| `hpc_parent_form_tokens` | model only ✗ | GAP-DB-004b — no migration/DDL |
| `hpc_peer_assignments`, `hpc_peer_responses` | model only ✗ | GAP-DB-004c/d |
| `student_form_submissions` | model only ✗ | GAP-DB-005 — also lacks `hpc_` prefix |
| `hpc_student_hpc_snapshot` | model only ✗ | GAP-DB-006 |
| `hpc_curriculum_change_request`, `hpc_lesson_version_control` | migration only ✗ | orphan; no model/controller |
| credit-config / curriculum-analytics tables | spec only ✗ | not migrated, not modelled |

### D.3 Cross-Module Dependency Map
**Inbound (HPC reads):**
| Source | Data | Why |
|--------|------|-----|
| SchoolSetup | classes, sections, subjects, terms, academic sessions | template mapping, term/year scoping |
| StudentProfile | students, attendance, guardians | card subject, attendance %, guardian email |
| SystemConfig | users, dropdowns, settings | authorship, domain values, working-days config |
| LMS (Exam/Quiz/Homework) | scores (soft, graceful fallback) | pre-fill learning sections |

**Outbound (HPC produces):**
| Target | Mechanism | What |
|--------|-----------|------|
| Email/Queue | queued job | guardian view-link emails |
| Media library | file collection | uploaded evidence on cards |
| File storage | ZIP stream | bulk card archive (deleted after download) |

---

# Pack E — NFR Catalog + Risk Register

### E.1 NFR Catalog
| NFR ID | Category | Requirement | Threshold |
|--------|----------|-------------|-----------|
| NFR-HPC-01 | Performance | Bulk generation within request budget | ≤ 50 students until backgrounded |
| NFR-HPC-02 | Performance | Cache template structure | avoid per-render structural reads |
| NFR-HPC-03 | Maintainability | Decompose the oversized card controller | split into focused controllers |
| NFR-HPC-04 | Security | Module entitlement + per-action permission on all authenticated routes | 100% of routes |
| NFR-HPC-05 | Security | Public card-view & parent-link routes enforce access every request | every GET/POST |
| NFR-HPC-06 | Privacy | Card data isolated per school | no cross-tenant access |
| NFR-HPC-07 | Quality | Automated test coverage for core services & workflow | ≥ 60% services |
| NFR-HPC-08 | Usability | All 4 templates render with graceful empty states | no errors on missing data |

### E.2 Risk Register
| Risk ID | Risk | Likelihood | Impact | Mitigation |
|---------|------|:----------:|:------:|------------|
| RISK-HPC-001 | Multi-actor features (student/parent/peer/snapshot) fail at runtime — backing tables missing | H | H | Create migrations (GAP-DB-004/005/006) before enabling features |
| RISK-HPC-002 | Authorization is inline-string based with no Policy layer; one missing check = bypass (BUG-HPC-016) | H | H | Add missing gate to card generation; consider Policy classes / FormRequests |
| RISK-HPC-003 | Public card-view & parent-link routes are unauthenticated exposure surface | M | H | Enforce entitlement + token re-validation on every request; rate-limit |
| RISK-HPC-004 | Workflow status ENUM in schema lags the 6-state model | M | M | Reconcile schema; add missing audit columns |
| RISK-HPC-005 | Zero automated tests on a partly built, complex module | H | M | Build feature tests for built features first (workflow, save, PDF) |
| RISK-HPC-006 | Oversized single controller raises regression risk on every change | M | M | Decompose; introduce factory for PDF layout selection |
| RISK-HPC-007 | Orphan tables / unbuilt analytics create false "done" impression | M | M | This FRD's Build Status flags resolve the ambiguity |

---

# Pack F — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks

### F.1 MoSCoW
- **Must:** Fix BUG-HPC-016; create missing tables for REQ-009/010/011 (P0 data-integrity); confirm
  entitlement/auth on public routes; reconcile workflow schema (REQ-013).
- **Should:** Credit-override config (REQ-017); snapshot table (REQ-015); FormRequests; notifications
  (ENH-HPC-001); rate-limit bulk email (ENH-HPC-002); feature tests.
- **Could:** Controller decomposition; PDF-layout factory; background bulk generation (ENH-HPC-003).
- **Won't (this release):** Curriculum-analytics layer (REQ-002…007); curriculum-change workflow
  (REQ-019).

### F.2 Effort Estimation & Sprint Tasks
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------:|------------|--------|
| 1 | Add gate to card generation (BUG-HPC-016) | Backend | 1 | — | 1 |
| 2 | Migrations: parent tokens, peer assignments/responses, student submissions | Schema | 8 | — | 1 |
| 3 | Migration: card snapshot | Schema | 3 | — | 1 |
| 4 | Reconcile `hpc_reports` status + audit columns | Schema | 4 | — | 1 |
| 5 | Confirm/add module entitlement + secure public routes | Backend | 4 | — | 1 |
| 6 | FormRequests for inline-validated actions | Backend | 8 | 1 | 2 |
| 7 | Workflow status-change notifications | Backend/Integration | 10 | 4 | 2 |
| 8 | Rate-limit bulk email | Backend | 3 | — | 2 |
| 9 | Credit-override config table + screen | Schema/Full-stack | 12 | — | 2 |
| 10 | Feature tests for built features (workflow, save, PDF, attendance) | Testing | 24 | 1–5 | 2-3 |
| 11 | Background bulk generation job | Backend | 12 | 2 | 3 |
| 12 | Controller decomposition + PDF factory | Refactor | 18 | 10 | 3 |
> Assumes the central tenant migration set is the schema source of truth; +effort if DDL doc must
> also be regenerated. Curriculum-analytics build is a separate epic, not estimated here.

---

# Pack G — User Stories (Gherkin) + Reporting/KPI Spec

### G.1 User Stories (P0/P1)
**US-HPC-001 (REQ-008, P0)** — As a Class Teacher, I want to fill a student's card so the holistic
report can be produced.
- Happy: Given a student in a graded class, When I open the card, Then attendance is pre-filled and I
  can edit and save teacher fields.
- Boundary: Given I save twice, Then the same card is updated, not duplicated.
- Permission: Given I lack the create permission, When I open the card, Then access is refused.
- Empty: Given no learning data, Then learning sections appear empty with no error.

**US-HPC-002 (REQ-013, P0)** — As a Principal, I want to review and approve or send back cards.
- Happy: Given a submitted card, When I approve, Then it becomes finalised with my name and time.
- Exception: Given I send back, When I omit a comment, Then the action is refused.
- Permission: Given I lack review permission, Then the action is refused.

**US-HPC-003 (REQ-012, P0)** — As a Teacher, I want to generate cards in bulk.
- Happy: Given ≤50 selected students, Then I receive one archive of their cards.
- Boundary: Given 51 students, Then the request is refused with a clear message.
- Security: Given I am authenticated, Then generation must still verify my permission *(today's gap —
  BUG-HPC-016)*.

**US-HPC-004 (REQ-014, P0)** — As an Admin, I want guardians emailed a secure view-link.
- Happy: Given a published card, Then each guardian receives a view-link email.
- Edge: Given a guardian without an email, Then they are skipped and a warning is logged.

**US-HPC-005 (REQ-010, P1)** — As a Parent, I want to fill my section via a secure link without logging in.
- Happy: Given a valid link, Then I can fill and submit my section.
- Exception: Given an expired or completed link, Then I see an expired page and cannot submit.

**US-HPC-006 (REQ-011, P1)** — As a Teacher, I want peers auto-assigned fairly.
- Happy: Given a class, Then no student reviews themselves and no reciprocal pairs are created.
- Boundary: Given too few peers, Then a shortfall is reported.

**US-HPC-007 (REQ-009, P1)** — As a Student, I want to complete my self-assessment.
- Happy: Given a pending card, Then I edit only my fields and submit.
- Permission: Given I try to edit teacher fields, Then those values are discarded.

**US-HPC-008 (REQ-016, P1)** — As an Admin, I want to configure working days so attendance % is correct.
- Happy: Given I set working days, Then the card's attendance percentage reflects them.

**US-HPC-009 (REQ-017, P1)** — As an Admin, I want grade-wise credit overrides.
- Happy: Given no override, Then national defaults apply; given an override, Then it replaces the default.

### G.2 KPI / Metrics Catalog
| KPI | Definition (business) | Source | Cadence |
|-----|-----------------------|--------|---------|
| Card completion rate | Published cards ÷ enrolled students per term | card status | per term |
| Contributor completion | % of parent/peer/student sections completed | section flags | per term |
| Time-to-publish | Days from submit to publish | workflow audit | per term |
| Attendance coverage | Students with computed attendance ÷ total | attendance | monthly |

---

# Pack H — Feature Specification (key built screens)

### Screen: Teacher Data Entry Card (REQ-008)
- **Layout:** tabbed — one tab per template page; sections and scored items rendered in order.
- **Actions:** Save (per page / whole), Generate PDF, Send Email, View Workflow, Submit.
- **Pre-fill:** attendance (month-wise), learning data (when present), NCrF credits.
- **Empty states:** missing learning data → empty sections; no attendance → blank/zero.
- **Permissions:** teacher create/update; principal/admin view.

### Screen: Card Template Management (REQ-001)
- **Layout:** index list + create/edit/show/trash per level (template, parts, sections, rubrics).
- **Actions:** Create, Edit, Show, Soft-delete, Restore, Force-delete, Toggle active.
- **Empty state:** "No templates configured."
- **Permissions:** admin manage; teacher view.

### Screen: Workflow Status (REQ-013 / RPT-005)
- **Contents:** current stage, audit trail, allowed next actions.
- **Actions:** Submit / Review / Approve / Send-back / Publish / Archive (role-gated).

### Screen: Attendance Configuration (REQ-016)
- **Layout:** per-month working-days inputs (Apr–Mar) + summary.
- **Actions:** Save config; view summary.

### Screen (Partial): Parent Dashboard/Form, Student Dashboard/Form/Goals, Peer Review
- Views exist; **blocked at the data layer** by missing tables (GAP-DB-004/005). Document as partial.

---

# Pack I — Module Knowledge Reference

Authoritative module knowledge (counts, three-way DDL↔migration↔model reconciliation, security
findings, design decisions, pending steps) is maintained at
`AI_Brain/module-knowledge/HPC_Hpc.md` (re-verified & corrected 2026-06-29). This FRD and that file
were updated together; the Requirement Conditions Catalog (Pack B.1) is the canonical condition set —
the `5-Requirement_Conditions/HPC_Conditions.md` location may point back here.

**Headline reconciliation:** 11 controllers · 16 models · 10 services · 4 FormRequests · 0 policies ·
192 views · 0 tests. Of 19 documented features only 6 are end-to-end built; 5 are partial (coded
against missing tables); 8 are not built. **BUG-HPC-016 (card generation missing authorization) is
confirmed OPEN and is the top P0.**

---

*End of HPC Complete Analysis Pack — 2026-06-29.*
</content>
