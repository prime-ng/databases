# Feedback (FBK) — Complete Analysis Pack & FRD

**Module:** Feedback | **Code:** FBK | **Prefix:** `fbk_` | **DB layer:** Tenant (per-school)
**Date:** 2026-06-29 | **Author:** Business Analyst
**Sources read:** live code (`Modules/Feedback`), tenant migrations (`*fbk*`, 12), models (11), services (6),
seeders (4), DDL v3 (canonical) + v2/v1 (narrative), AI_Brain decisions **D27** (Feedback schema) & **D29** (ENUM→dropdown).
**Mode:** Complete Analysis Pack (FRD-first; every artifact reuses the IDs assigned here — do not renumber).

> **This file is the single source of truth for Feedback requirement IDs.** The downstream DDL gap,
> code audit, status scoring and test design reuse the `REQ-/BR-/RPT-` IDs below. The machine-readable
> coverage contract is **Section 10**.

> **Register note:** Sections 1–9, RTM, Conditions, Process Flows, FSM, NFR, Risk, Prioritization,
> Stories and Reporting are **business language**. The Data Dictionary *technical view* (Section 5T)
> and the Dependency Map are the only **technical-register** sections.

---

## Index / Table of Contents

**FRD core (business)**
- Section 1 — Module Overview
- Section 2 — User Roles & Access
- Section 3 — Functional Requirements (REQ-FBK-001 … 015)
- Section 4 — Business Rules Register (BR-FBK-001 … 022)
- Section 5 — Data Requirements (business view) + **5T** technical view
- Section 6 — Workflows
- Section 7 — Reporting & Analytics (RPT-FBK-001 … 006)
- Section 8 — Future Enhancement Log (ENH-FBK-001 …)
- Section 9 — Non-Functional Requirements
- Section 10 — Gap Analysis Readiness Index (downstream contract)

**Analysis Pack (references the IDs above)**
- Section 11 — Requirements Traceability Matrix (RTM)
- Section 12 — Requirement Conditions Catalog + Validation & Edge-Case Catalog
- Section 13 — Process Flows + State Machine (FSM) Catalog
- Section 14 — Cross-Module Dependency Map
- Section 15 — NFR Catalog + Risk Register
- Section 16 — Prioritization (MoSCoW) + Effort Estimation & Sprint Tasks
- Section 17 — User Stories (Gherkin) + KPI Catalog
- Section 18 — Anomalies & Open Questions

---

# Section 1 — Module Overview

## 1.1 Purpose
The Feedback module lets a school **collect, manage and analyse structured feedback** across many
relationships — not just students rating teachers, but parents, teachers and administrators rating a wide
range of people and services (teachers, fellow students, transport drivers, canteen and library staff,
hostel wardens, departments, and self-reflection). Feedback is gathered in time-boxed **cycles**, answered
against reusable **question templates**, and rolled up into **summaries** that protect respondent identity.

## 1.2 Business Value
- Operationalises **NEP-2020** feedback expectations: teachers evaluate every student they teach, and
  students give anonymous peer feedback within their class-section.
- Gives leadership a single, consistent instrument to measure service quality (teaching, transport, canteen,
  library, hostel) instead of one-off surveys.
- Protects minors and honest respondents through **hardcoded anonymity** for peer feedback and a
  **minimum-response threshold** before any summary is shown to the person being rated.
- Preserves the integrity of historical analytics by **snapshotting** question wording, weighting and
  category at the moment of submission, so later template edits never rewrite past results.

## 1.3 Scope

**In scope**
- Configuration masters: who can be rated (Target Types), which feedback flows are allowed (Relationship
  Types), and question themes (Categories).
- Reusable feedback Templates and their Questions (rating, Likert, emoji, yes/no, multiple-choice, free text),
  with weighting and reverse scoring.
- Feedback Cycles with a lifecycle (Draft → Active → Closed → Published → Cancelled) and per-cycle defaults
  for anonymity and visibility threshold.
- Multiple feedback flows running inside one cycle, each with its own template, anonymity and target scope.
- Building the eligible-target list automatically (from school relationships) or manually.
- Eligibility checking so a respondent can only rate people they are genuinely connected to.
- Response capture (save draft, submit, withdraw) with per-question answers.
- Server-side overall-rating calculation, anonymity / k-anonymity enforcement, and materialised summaries
  with publish control.
- A dashboard with participation and rating analytics.
- **Consent Forms (cross-module sub-area):** admin authoring and results review of digital consent forms
  sent to parents — *the data is owned by the Parent Portal* (see Anomaly A1).

**Out of scope**
- Anonymous public/website feedback or external survey tools (the module is identity-aware internally).
- Front-office visitor/complaint feedback (`fof_feedback_*` belongs to the FrontOffice module — Anomaly A2).
- Payroll/appraisal outcomes — Feedback supplies inputs to a performance review, it does not run HR appraisals.
- Cross-school / multi-tenant benchmarking — all data is **isolated per school** (database-per-tenant).
- Automatic disciplinary action based on feedback scores.

## 1.4 Terminology
| Term | Meaning (business) |
|------|--------------------|
| **Respondent** | The person giving feedback (Student, Parent, Teacher, Staff, Admin, or Self). |
| **Target** | The person, role or service being rated (a teacher, a peer student, a driver, a department…). |
| **Target Type** | A configurable kind of thing that can be rated (e.g., Class Teacher, Subject Teacher, Transport Driver, Department). |
| **Relationship Type** | An allowed combination of *who rates whom, in what context* — acts as the permission whitelist for a feedback flow. |
| **Context** | The link that must exist for eligibility (shared class-section, subject, transport route, hostel, department, or none). |
| **Template** | A reusable, versioned set of questions used to collect one kind of feedback. |
| **Feedback Cycle** | A dated window during which one or more feedback flows are open for submission. |
| **Feedback Flow / Cycle Feedback Type** | One (relationship + template) pairing inside a cycle. |
| **Anonymity to target** | Whether the person being rated can see who gave the feedback. |
| **Visibility threshold (k-anonymity)** | Minimum number of responses before a summary may be shown to the target (default 3). |
| **Summary** | The aggregated, publishable result for a target in a feedback flow. |
| **Self-reflection** | A flow where the respondent rates themselves. |
| **Consent Form** | A digital approval request sent to parents (cross-module; Parent Portal data). |

---

# Section 2 — User Roles & Access

## 2.1 Actors
| Actor | Description | Typical actions |
|-------|-------------|-----------------|
| **School Admin / Principal** | Owns configuration and the cycle lifecycle; sees full (non-anonymised) data for audit. | Manage masters, templates, cycles, flows, populate targets, publish summaries, view everything. |
| **Teacher** | Gives feedback (peer review, teacher→student NEP flow) and *receives* feedback summaries. | Submit assigned feedback; view own summaries (subject to threshold). |
| **Student** | Gives feedback on teachers, peers and services; may receive teacher→student feedback. | Submit/draft/withdraw responses; view feedback addressed to them where allowed. |
| **Parent / Guardian** | Gives feedback about their child's teachers and school services. | Submit responses for flows they are eligible for; respond to consent forms. |
| **Non-teaching Staff** | May be a target (driver, canteen, library, hostel, security, nursing, lab, coach) and occasionally a respondent. | Receive summaries; submit where configured. |
| **System (scheduler / services)** | Automated lifecycle and computation. | Open/close cycles by date; recompute summaries and participation counts. |

## 2.2 Role–Feature Matrix (high level)
| Feature area | Admin/Principal | Teacher | Student | Parent | Staff |
|--------------|:---:|:---:|:---:|:---:|:---:|
| Manage masters (Target/Relationship/Category) | C/R/U/D | — | — | — | — |
| Author templates & questions | C/R/U/D | — | — | — | — |
| Create & run cycles, configure flows | C/R/U/D | — | — | — | — |
| Populate / edit cycle targets | C/R/U | — | — | — | — |
| Submit feedback (eligible flows) | (test) | ✔ | ✔ | ✔ | ✔ (if configured) |
| Withdraw own response (before close) | — | ✔ | ✔ | ✔ | ✔ |
| View own received summary (≥ threshold) | full | ✔ | ✔ | — | ✔ |
| Publish summaries | ✔ | — | — | — | — |
| See respondent identity on anonymous feedback | ✔ (audit) | ✖ | ✖ | ✖ | ✖ |
| Consent Forms — author / review results | ✔ | — | — | (respond only) | — |

> Authorization in code is gated by `tenant.feedback.*` and `tenant.consent-forms.*` permissions
> (technical detail; see Open Question Q4 on whether these permission rows are seeded).

---

# Section 3 — Functional Requirements

> Priority: **Core (P0)** / **Standard (P1)** / **Enhanced (P2)**. Tags from the controlled vocabulary.

### REQ-FBK-001 — Target Type Management `[CONFIGURATION]` — P0
**Description.** Admin maintains the catalogue of *kinds of things that can be rated* (e.g., Class Teacher,
Subject Teacher, Student, Peer Student, Transport Driver, Canteen Staff, Library Staff, Hostel Warden,
Department). Each target type records which base entity it points to and whether it is an individual or an
aggregate (e.g., a department).
**Actors.** Initiates/Processes: Admin. Views: Admin.
**Business rules.** BR-FBK-020, BR-FBK-021.
**Acceptance criteria.**
- A target type can be created with a unique code, display name, icon and order, and marked individual or aggregate.
- A target type cannot be deleted while a relationship type, category or active cycle references it (blocked, not cascaded).
- Inactivating a target type hides it from new configuration but does not alter historical responses.
- A soft-deleted target type can be restored.

### REQ-FBK-002 — Relationship Type Management (feedback-flow whitelist) `[CONFIGURATION][APPROVAL]` — P0
**Description.** Admin defines which feedback flows are permitted as *(respondent kind × target type × context)*
tuples — e.g., "Student → Class Teacher within the same class-section", "Teacher → Student (subject & class)",
"Student → Peer Student (same class-section)". Each tuple carries flags for peer, self, NEP-2020-mandated, and a
recommended anonymity default.
**Actors.** Admin.
**Business rules.** BR-FBK-002, BR-FBK-006, BR-FBK-007, BR-FBK-008.
**Acceptance criteria.**
- A relationship type stores respondent kind, target type, required context, and the peer/self/NEP/anonymity flags.
- Peer and self relationships default to anonymous and cannot be set non-anonymous (child-safety lock).
- A flow not represented by an active relationship type cannot be added to a cycle.
- NEP-2020 flows are identifiable for compliance reporting.

### REQ-FBK-003 — Feedback Category Management `[CONFIGURATION]` — P1
**Description.** Admin maintains question themes (Teaching Quality, Communication, Hygiene, Safety, Punctuality,
Peer Cooperation…), optionally scoped to a target type.
**Actors.** Admin.
**Acceptance criteria.**
- Category created with unique code, name, optional target-type scope and display order.
- A category in use by questions is detached (not cascaded) when deleted; historical answers keep their snapshot category.

### REQ-FBK-004 — Feedback Template Authoring (versioning & locking) `[CONFIGURATION]` — P0
**Description.** Admin builds reusable templates for one target type, choosing the overall-rating method
(weighted average / simple average / manual only / none) and rating scale maximum. A template can be reused
across multiple relationship flows of the same target type. Templates are versioned and **lock once a cycle
that uses them goes live**; to change a locked template the admin clones it to a new version.
**Actors.** Admin.
**Business rules.** BR-FBK-018.
**Acceptance criteria.**
- A template can be created, edited, cloned and soft-deleted; clone produces an unlocked new version.
- While locked, the template's questions cannot be added, edited, reordered or removed.
- The applicable relationship flows can be listed on the template.

### REQ-FBK-005 — Template Question Management `[CONFIGURATION]` — P0
**Description.** Within an unlocked template, admin manages questions: text, help text, category, type
(5/10-point rating, Likert-5, emoji-5, yes/no, multiple-choice, free text), required flag, weight, reverse
scoring, choice options, display order and respondent-kind filter.
**Actors.** Admin.
**Business rules.** BR-FBK-013, BR-FBK-014, BR-FBK-018.
**Acceptance criteria.**
- Questions can be created, edited, reordered and removed only while the template is unlocked.
- Multiple-choice questions store their options with numeric values for aggregation.
- A reverse-scored question is flagged so scoring inverts it.

### REQ-FBK-006 — Feedback Cycle Management & Lifecycle `[WORKFLOW]` — P0
**Description.** Admin creates a feedback cycle for an academic session with a name, optional term label, a
start and end date, instructions, and default anonymity/visibility settings. The cycle moves through
Draft → Active → Closed → Published, and may be Cancelled.
**Actors.** Admin (transitions); System (date-driven open/close).
**Business rules.** BR-FBK-001, BR-FBK-015, BR-FBK-022.
**Acceptance criteria.**
- A cycle can be created and edited only while in Draft; once Active, only allowed transitions apply.
- Feedback can be submitted only when the cycle is Active and the current date is within the window.
- Closing a cycle stops new submissions; publishing makes eligible summaries visible to targets.
- A cancelled cycle accepts no submissions and shows no summaries.
- A cycle with submitted responses cannot be hard-deleted (blocked).

### REQ-FBK-007 — Cycle Feedback Type (flow) Configuration `[CONFIGURATION][WORKFLOW]` — P0
**Description.** Within a Draft cycle, admin adds one or more feedback flows, each pairing an allowed
relationship type with a template, and setting per-flow anonymity, visibility threshold, draft/withdrawal
permissions, target scope, and whether targets are populated automatically or manually.
**Actors.** Admin.
**Business rules.** BR-FBK-002, BR-FBK-007, BR-FBK-010.
**Acceptance criteria.**
- A flow links a relationship type + a template whose target type matches.
- The same relationship type cannot be added twice to one cycle.
- Flows can only be added/edited while the cycle is Draft.
- An omitted scope means "all eligible targets".

### REQ-FBK-008 — Target Population & Participation Tracking `[WORKFLOW][SCHEDULED]` — P0
**Description.** For each flow, the eligible targets are enumerated — automatically by walking the school's
relationships (class teachers, subject teachers, peers, route staff, etc.) or manually by the admin. Expected,
received and submitted counts are maintained per target for participation reporting.
**Actors.** Admin (manual / trigger); System (auto-populate & counters).
**Business rules.** BR-FBK-009, BR-FBK-019.
**Acceptance criteria.**
- Auto-population creates one target row per eligible target with the correct context (class-section/subject/etc.).
- Manual mode lets the admin choose specific targets.
- Submitting or withdrawing a response updates the target's received/submitted counts.

### REQ-FBK-009 — Eligibility Resolution `[WORKFLOW]` — P0
**Description.** The system determines, for a logged-in respondent and a flow, exactly which targets they may
rate, based on the flow's required context (shared class-section, subject, transport route, hostel, department,
or none) and the respondent's own records.
**Actors.** System; consumed by Student/Parent/Teacher/Staff.
**Business rules.** BR-FBK-002, BR-FBK-003, BR-FBK-004, BR-FBK-005, BR-FBK-006.
**Acceptance criteria.**
- A student sees only teachers/peers/services connected to their current class-section/subject/route.
- A parent must be a portal-enabled guardian of the child the feedback concerns.
- A teacher→student flow only lists students the teacher actually teaches.
- A peer flow never lists the respondent themselves.

### REQ-FBK-010 — Response Submission (draft / submit / withdraw) `[DATA_ENTRY][WORKFLOW]` — P0
**Description.** An eligible respondent answers the template's questions for a chosen target, optionally saving
a draft, then submits. A submitted response is locked from editing but may be withdrawn before the cycle closes
(if the flow allows). The system prevents duplicate submissions for the same respondent–target–context.
**Actors.** Student, Parent, Teacher, Staff.
**Business rules.** BR-FBK-001, BR-FBK-016, BR-FBK-017, BR-FBK-020, BR-FBK-021.
**Acceptance criteria.**
- All required questions must be answered before submit; drafts may be partial.
- A second submission for the same target/context is rejected (one response per pairing).
- A submitted response cannot be edited; it can be withdrawn with a reason before cycle close if withdrawal is allowed.
- The respondent's class-section/subject context is locked onto the response at submit time.

### REQ-FBK-011 — Anonymity & k-Anonymity Enforcement `[WORKFLOW]` — P0
**Description.** The system enforces who may see respondent identity. Peer and self feedback are always
anonymous to the target; other flows follow the configured anonymity flag. A target may only see a summary once
the response count reaches the visibility threshold. Admins retain full visibility for audit.
**Actors.** System; Target (limited); Admin (full).
**Business rules.** BR-FBK-007, BR-FBK-008, BR-FBK-009 (k), BR-FBK-010, BR-FBK-011.
**Acceptance criteria.**
- When a flow is anonymous, no target-facing screen or summary reveals respondent identity.
- Peer/NEP-peer anonymity cannot be overridden even by an admin setting.
- A summary is withheld from the target while its response count is below the threshold.
- An admin can always view full identity for abuse-prevention.

### REQ-FBK-012 — Summary Aggregation & Publishing `[REPORT][WORKFLOW]` — P0
**Description.** The system computes a materialised summary per target per flow: participation rate, average
rating, rating distribution, per-category averages, per-respondent-kind averages, and highlighted comments.
Summaries recompute on each submit/withdraw and on cycle close, and are released to targets when the admin
publishes (and the threshold is met).
**Actors.** System (compute); Admin (publish); Target (view).
**Business rules.** BR-FBK-012, BR-FBK-013, BR-FBK-019, BR-FBK-010.
**Acceptance criteria.**
- Overall and category averages use the template's rating method and respect reverse scoring.
- Only numeric question types contribute to averages; free-text/yes-no are excluded from rating averages.
- Publishing a cycle/summary makes results visible to targets that meet the threshold.

### REQ-FBK-013 — Consent Form Authoring (cross-module) `[DATA_ENTRY][NOTIFICATION]` — P1
**Description.** Admin/communication staff create digital consent forms targeted at a class/section and send
them to parents for approval. *(The underlying consent data is owned by the Parent Portal module; Feedback
provides the staff-side authoring and listing UI — see Anomaly A1.)*
**Actors.** Admin / Communication staff.
**Acceptance criteria.**
- A consent form can be created with a title, body, target class/section, and active flag.
- Forms can be listed, filtered by class and status, edited, toggled, soft-deleted and restored.

### REQ-FBK-014 — Consent Form Responses Review (cross-module) `[REPORT]` — P1
**Description.** Staff review parent responses to a consent form, including which guardian responded for which
student and the response counts.
**Actors.** Admin / Communication staff.
**Acceptance criteria.**
- A form shows its response list with student and guardian attribution and a total count.
- Response data is read from the Parent Portal store.

### REQ-FBK-015 — Feedback Dashboard & Analytics `[DASHBOARD][REPORT]` — P1
**Description.** A landing dashboard and analytics views surface cycles, participation, and published summary
analytics for the school.
**Actors.** Admin (full); Teacher/Staff (own).
**Acceptance criteria.**
- The dashboard lists cycles with status and participation at a glance.
- Analytics views render summary aggregates respecting anonymity and the visibility threshold.

---

# Section 4 — Business Rules Register

> Reuses the canonical R1–R22 rules from the DDL design (D27). IDs are stable (`BR-FBK-001` ↔ R1, …).
> Type ∈ Validation / Workflow / Permission / Calculation / Concurrency.

| ID | Rule (business) | Type | Trigger | Enforcement point | Pri |
|----|-----------------|------|---------|-------------------|-----|
| BR-FBK-001 | Feedback may be submitted only when the cycle is Active and today is within its start/end window. | Workflow | On submit/draft | Response submission (REQ-010) | P0 |
| BR-FBK-002 | Eligibility follows the flow's required context (class-section / subject / both / transport route / hostel / department / none / custom). | Validation | On listing targets & submit | Eligibility (REQ-009) | P0 |
| BR-FBK-003 | A student respondent must be the logged-in student rating from their own identity. | Permission | On submit | Eligibility (REQ-009) | P0 |
| BR-FBK-004 | A parent respondent must be a guardian of the child, with parent-portal access enabled. | Permission | On submit | Eligibility (REQ-009) | P0 |
| BR-FBK-005 | A teacher respondent must actually teach the target (verified via their teaching assignments). | Permission | On submit | Eligibility (REQ-009) | P0 |
| BR-FBK-006 | In a peer flow the respondent and target share a class-section and cannot be the same person. | Validation | On listing & submit | Eligibility (REQ-009) | P0 |
| BR-FBK-007 | Peer relationships default to anonymous to the target. | Workflow | On flow config | Relationship/Flow config (REQ-002/007) | P0 |
| BR-FBK-008 | Peer / NEP-2020 peer feedback must never expose respondent identity, regardless of admin settings (child-safety lock). | Permission | On any target-facing read | Anonymity (REQ-011) | P0 |
| BR-FBK-009 | A summary is withheld from the target until its response count reaches the visibility threshold (default 3). | Workflow | On summary read | Anonymity/Summary (REQ-011/012) | P0 |
| BR-FBK-010 | Target-facing reads must never return respondent-identity fields when the flow is anonymous. | Permission | On dashboard/summary read | Anonymity (REQ-011) | P0 |
| BR-FBK-011 | Admin/Principal may always see full respondent identity for audit/abuse-prevention. | Permission | On admin read | Anonymity (REQ-011) | P0 |
| BR-FBK-012 | Overall rating is computed server-side by the template's method: weighted average, simple average, manual-only (none computed), or none. | Calculation | On submit | Response/Summary (REQ-010/012) | P0 |
| BR-FBK-013 | Reverse-scored questions are inverted (scale_max + 1 − raw value) before aggregation. | Calculation | On submit/aggregate | Response/Summary | P0 |
| BR-FBK-014 | Only numeric question types contribute to rating averages; free-text and yes/no are excluded. | Calculation | On aggregate | Summary (REQ-012) | P0 |
| BR-FBK-015 | Cycle lifecycle: Draft → Active → Closed → Published → (Cancelled); only these transitions are legal. | Workflow | On transition | Cycle FSM (REQ-006) | P0 |
| BR-FBK-016 | Response lifecycle: Draft → Submitted → (Withdrawn); a Submitted response cannot be edited, only withdrawn. | Workflow | On status change | Response FSM (REQ-010) | P0 |
| BR-FBK-017 | A response may be withdrawn only before the cycle closes, and only if the flow allows withdrawal. | Workflow | On withdraw | Response (REQ-010) | P1 |
| BR-FBK-018 | A template locks on first use by an activated cycle; locked-template questions cannot change — clone to a new version to edit. | Workflow | On cycle activate / template edit | Template (REQ-004/005) | P0 |
| BR-FBK-019 | On every submit/withdraw, the affected summary and the target's participation counters must be recomputed. | Workflow | On submit/withdraw | Summary/Target (REQ-008/012) | P0 |
| BR-FBK-020 | Exactly one respondent identity (student / guardian / employee) must be populated to match the respondent kind. | Validation | On submit | Response (REQ-010) | P0 |
| BR-FBK-021 | Exactly one target identity (user / student / employee / department) must be populated per the target type. | Validation | On submit | Response (REQ-010) | P0 |
| BR-FBK-022 | The cycle's academic session must match the respondent's locked academic-session context (when present). | Validation | On submit | Response (REQ-010) | P1 |
| BR-FBK-023 | One response per (respondent × target × context) within a flow — duplicates are rejected. | Concurrency | On submit | Response unique constraint (REQ-010) | P0 |

> BR-FBK-023 is the de-dup invariant enforced by the unique index on `fbk_responses`; contended resource =
> the (respondent, target, context) submission slot.

---

# Section 5 — Data Requirements (business view)

| Business entity | What it holds | Key attributes (business) | Privacy |
|-----------------|---------------|---------------------------|---------|
| Target Type | Kinds of people/services that can be rated | code, name, icon, individual vs aggregate, linked entity | Public |
| Relationship Type | Allowed feedback flows | respondent kind, target type, required context, peer/self/NEP flags, default anonymity | Public |
| Category | Question themes | code, name, optional target-type scope, order | Public |
| Template | Reusable question set | name, target type, rating method, scale max, version, locked flag | Internal |
| Question | A question in a template | text, type, category, weight, reverse-scored, options, required | Internal |
| Cycle | Feedback window | name, academic session, term, start/end dates, status, anonymity & threshold defaults, instructions | Internal |
| Feedback Flow (Cycle Feedback Type) | A flow inside a cycle | relationship + template, anonymity, threshold, scope, auto/manual population | Internal |
| Cycle Target | An eligible target in a flow | target identity, context (class/subject), expected/received/submitted counts | Confidential |
| Response | A single submission | respondent, target, context, overall rating, comment, anonymity snapshot, status, timestamps | **Sensitive** (links respondent ↔ target) |
| Answer | One question answer | question snapshot, rating / boolean / option / text / emoji value | **Sensitive** |
| Summary | Aggregated result per target/flow | participation, averages, distributions, category & respondent-kind breakdowns, highlighted comments, publish flag | Confidential |
| Consent Form *(Parent Portal)* | Digital consent request | title, body, class/section, active flag | Internal |
| Consent Response *(Parent Portal)* | Parent's reply | student, guardian, decision/timestamp | Confidential (PII) |

**Privacy & scoping notes.** Responses and answers are **Sensitive** — they tie an identifiable respondent to
an identifiable target and must honour anonymity (BR-008/010) and the k-anonymity threshold (BR-009). All data
is **isolated per school** (database-per-tenant; there is no cross-tenant view). Cycles are **academic-session
scoped** — always filter by session.

## Section 5T — Data Dictionary (technical view) — *technical register*

> Canonical schema = **DDL v3** (ENUM-free). Every former ENUM is a `*_id` FK into `sys_dropdown_table`
> (D29). Live migrations, models and `FbkDropdownSeeder` all agree.

| # | Table | Notable columns | Dropdown-FK (`sys_dropdown_table`) columns | Polymorphic / generated |
|---|-------|-----------------|--------------------------------------------|--------------------------|
| 1 | `fbk_target_types` | code, name, `is_individual`, `linked_entity_table` | `linked_entity_table` (ENUM retained in v2; key in v3) | — |
| 2 | `fbk_relationship_types` | `target_type_id`→`fbk_target_types`, peer/self/NEP/anon flags | `respondent_kind_id`, `context_required_id` | — |
| 3 | `fbk_categories` | `applicable_target_type_id` | — | — |
| 4 | `fbk_templates` | `target_type_id`, `rating_scale_max`, `version`, `is_locked`, `applicable_relationship_codes_json` | `respondent_kind_id`, `overall_rating_method_id` | — |
| 5 | `fbk_questions` | `template_id`, `category_id`, weight, `is_reverse_scored`, `options_json` | `respondent_kind_id`, `question_type_id` | — |
| 6 | `fbk_cycles` | `academic_session_id`→`sch_org_academic_sessions_jnt`, dates, threshold/anon defaults | `status_id` | — |
| 7 | `fbk_cycle_feedback_types` | `cycle_id`, `relationship_type_id`, `template_id`, `min_responses_for_visibility`, `allow_draft_save`, `allow_withdrawal`, `target_population_mode` | `scope_type_id` (**nullable** via 2026_04_09_200000) | — |
| 8 | `fbk_cycle_targets` | `cycle_id`, `cycle_feedback_type_id`, context (`class_section_id`,`subject_id`,`tt_activity_id`,`context_json`), participation counters | — | 4 target FKs (user/student/employee/department) |
| 9 | `fbk_responses` | snapshots (`template_id`,`relationship_type_id`), `overall_rating`, `is_anonymous_to_target`, submit/withdraw audit | `respondent_kind_id`, `status_id` | 3 respondent FKs + always `respondent_user_id`; 4 target FKs; **7 generated `_uq` COALESCE cols** + dedup UNIQUE `uq_fbk_r_dedup` |
| 10 | `fbk_answers` | `response_id`, `question_id`, snapshots, `rating_value`/`boolean_answer`/`selected_option_*`/`text_answer`/`emoji_value` | `question_type_snapshot` | UNIQUE (`response_id`,`question_id`) |
| 11 | `fbk_summary` | participation %, averages, `*_json` distributions, `is_published` | — | 4 target FKs; **6 generated `_uq` cols** + dedup UNIQUE `uq_fbk_s_dedup` |

**External FKs:** `sys_users`, `sys_dropdown_table`, `sch_employees`, `sch_class_section_jnt`, `sch_subjects`,
`sch_departments`, `sch_org_academic_sessions_jnt`, `std_students`, `std_guardians`,
`std_student_academic_sessions`, `tt_activity`/`tt_activity_teacher`.

---

# Section 6 — Workflows

**WF-1 Configure & launch a cycle.** Admin sets up masters → builds template(s) → creates Draft cycle → adds
feedback flows → populates targets (auto/manual) → activates. *Exception:* activating locks the templates in
use; if a template needs changes the admin must clone-and-version (BR-018). *Notification:* cycle-open alert to
eligible respondents.

**WF-2 Submit feedback.** Respondent opens the cycle → sees eligible flows/targets (REQ-009) → answers → saves
draft or submits. *Exceptions:* outside window → blocked (BR-001); duplicate → rejected (BR-023); missing
required answers → blocked. *Side-effect:* participation counters + summary recompute (BR-019).

**WF-3 Withdraw.** Respondent withdraws a submitted response with a reason before close, if allowed (BR-017).
*Side-effect:* counters/summary recompute.

**WF-4 Close & publish.** System closes the cycle on end date (BR-015) → summaries finalise → admin publishes →
targets meeting the threshold can view their summary (BR-009/010). *Exception:* below-threshold targets see a
"insufficient responses" state, never raw data.

**WF-5 Consent form (cross-module).** Staff author a consent form → it is delivered to parents (Parent Portal) →
parents respond → staff review results. *Exception:* inactive/soft-deleted forms accept no responses.

**Notifications (to confirm wiring — see Q3):** cycle-open, reminder before close, summary-published.

---

# Section 7 — Reporting & Analytics

| ID | Report | Audience | Frequency | Contents | Filters | Export |
|----|--------|----------|-----------|----------|---------|--------|
| RPT-FBK-001 | Target Feedback Summary | Target (self) + Admin | Per cycle | Average rating, category breakdown, rating distribution, highlighted comments | Cycle, flow | PDF |
| RPT-FBK-002 | Participation / Completion | Admin | Live + per cycle | Expected vs received vs submitted per flow/target; participation rate | Cycle, flow, class | Excel/CSV |
| RPT-FBK-003 | Cycle Dashboard | Admin | Live | Cycles by status, overall participation, top/bottom rated targets | Session, status | Screen |
| RPT-FBK-004 | NEP-2020 Compliance | Admin/Principal | Per cycle | Coverage of mandated flows (Teacher→Student, Peer) and completion | Session, flow | PDF/Excel |
| RPT-FBK-005 | Comment Highlights | Target + Admin | Per cycle | Top positive / top concern comments (anonymised) | Cycle, target | Screen/PDF |
| RPT-FBK-006 | Consent Form Responses | Admin/Staff | Live | Responses per form with student/guardian attribution + counts | Form, class, status | Excel/CSV |

---

# Section 8 — Future Enhancement Log

| ID | Enhancement | Notes | Pri |
|----|-------------|-------|-----|
| ENH-FBK-001 | Notification integration for cycle-open / reminder / publish | EventServiceProvider is empty today; wire to Notification + EventEngine | P1 |
| ENH-FBK-002 | Scheduled auto-transition of cycle status by date | Confirm/own a scheduler job for Draft→Active→Closed | P1 |
| ENH-FBK-003 | Cross-cycle trend analytics per target | Compare a teacher/service across sessions | P2 |
| ENH-FBK-004 | Sentiment analysis on free-text comments | AI highlight extraction beyond manual top-comment lists | P2 |
| ENH-FBK-005 | Self-reflection flow UI | Schema supports `is_self_relationship`; confirm dedicated UI | P2 |
| ENH-FBK-006 | Relocate Consent Forms to a clear owner module | Resolve Feedback↔ParentPortal boundary (A1) | P1 |

---

# Section 9 — Non-Functional Requirements (summary; detailed in Section 15)

- **9.1 Performance.** Eligible-target listing and submission must remain responsive for large cohorts
  (500+-student schools, class-wide peer flows producing N×(N−1) eligible pairs). Summaries are materialised to
  keep dashboards fast.
- **9.2 Security & Privacy.** Anonymity (BR-008/010) and k-anonymity (BR-009) are mandatory and child-safety
  critical; admin-only identity reveal is auditable; data is per-school isolated.
- **9.3 Usability.** Tabbed admin workspace (cycles/templates/responses/analytics/setup); clear empty/insufficient
  -responses states; draft-save to avoid data loss.

---

# Section 10 — Gap Analysis Readiness Index (downstream contract)

## 10.1 Coverage table
| REQ ID | Feature | Priority | Tags | DDL Entity Needed | Screen Needed | API Needed | Notification Needed | Test Case Needed |
|--------|---------|----------|------|:---:|:---:|:---:|:---:|:---:|
| REQ-FBK-001 | Target Type Management | P0 | CONFIGURATION | Yes | Yes | Yes | No | Yes |
| REQ-FBK-002 | Relationship Type Management | P0 | CONFIGURATION,APPROVAL | Yes | Yes | Yes | No | Yes |
| REQ-FBK-003 | Category Management | P1 | CONFIGURATION | Yes | Yes | Yes | No | Yes |
| REQ-FBK-004 | Template Authoring | P0 | CONFIGURATION | Yes | Yes | Yes | No | Yes |
| REQ-FBK-005 | Question Management | P0 | CONFIGURATION | Yes | Yes | Yes | No | Yes |
| REQ-FBK-006 | Cycle Management & FSM | P0 | WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-FBK-007 | Cycle Feedback Type Config | P0 | CONFIGURATION,WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-FBK-008 | Target Population & Tracking | P0 | WORKFLOW,SCHEDULED | Yes | Yes | Yes | No | Yes |
| REQ-FBK-009 | Eligibility Resolution | P0 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-FBK-010 | Response Submission | P0 | DATA_ENTRY,WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-FBK-011 | Anonymity & k-Anonymity | P0 | WORKFLOW | Yes | Yes | Yes | No | Yes |
| REQ-FBK-012 | Summary Aggregation & Publishing | P0 | REPORT,WORKFLOW | Yes | Yes | Yes | Yes | Yes |
| REQ-FBK-013 | Consent Form Authoring | P1 | DATA_ENTRY,NOTIFICATION | Yes (PPT) | Yes | Yes | Yes | Yes |
| REQ-FBK-014 | Consent Form Responses Review | P1 | REPORT | Yes (PPT) | Yes | Yes | No | Yes |
| REQ-FBK-015 | Dashboard & Analytics | P1 | DASHBOARD,REPORT | No | Yes | Yes | No | Yes |

## 10.2 BR coverage
23 business rules (BR-FBK-001…023). Types: Validation 6, Workflow 8, Permission 5, Calculation 3, Concurrency 1.
Critical/child-safety: BR-008, BR-009, BR-010, BR-011.

## 10.3 Report coverage
6 reports (RPT-FBK-001…006). RPT-006 reads Parent Portal data (cross-module).

## 10.4 Totals (reconciled)
- **Functional requirements:** 15 — **P0 = 10**, **P1 = 5**, P2 = 0.
- **Business rules:** 23.
- **Reports:** 6.
- **Workflows:** 5.
- **Enhancements:** 6.

---

# Section 11 — Requirements Traceability Matrix (RTM)

| REQ ID | Feature | BR refs | Screen(s) | Workflow | Report(s) | Code status (live) | Gap |
|--------|---------|---------|-----------|----------|-----------|--------------------|-----|
| REQ-FBK-001 | Target Types | 020,021 | setup/target-types | WF-1 | — | Built (FbkTargetTypeController, FbkTargetType) | Tests, policy seed (Q4) |
| REQ-FBK-002 | Relationship Types | 002,006,007,008 | setup/relationship-types | WF-1 | RPT-004 | Built (FbkRelationshipTypeController) | Tests |
| REQ-FBK-003 | Categories | — | setup/categories | WF-1 | — | Built (FbkCategoryController) | Tests |
| REQ-FBK-004 | Templates | 018 | templates/* | WF-1 | — | Built (FbkTemplateController + FbkTemplateService) | Tests |
| REQ-FBK-005 | Questions | 013,014,018 | templates partials | WF-1 | — | Built (template question routes) | Tests |
| REQ-FBK-006 | Cycles & FSM | 001,015,022 | cycles/* | WF-1,WF-4 | RPT-003 | Built (FbkCycleController + FbkCycleService) | Scheduler (Q2) |
| REQ-FBK-007 | Cycle flows | 002,007,010 | cycle-feedback-types | WF-1 | — | Built (FbkCycleFeedbackTypeController) | Tests |
| REQ-FBK-008 | Target population | 009,019 | cycle target partials | WF-1 | RPT-002 | Built (populateTargets + counters) | Scheduler (Q2) |
| REQ-FBK-009 | Eligibility | 002,003,004,005,006 | respond/* | WF-2 | — | Built (FbkEligibilityService, 444 LOC) | Audit context resolvers |
| REQ-FBK-010 | Response submit | 001,016,017,020,021,023 | respond/form | WF-2,WF-3 | — | Built (FbkResponseController + FbkResponseService) | Tests |
| REQ-FBK-011 | Anonymity/k-anon | 007,008,009,010,011 | (cross-cutting) | WF-4 | RPT-001,005 | Built (FbkAnonymityService) | Audit enforcement (Q1) |
| REQ-FBK-012 | Summary/publish | 012,013,019,010 | analytics partials | WF-2,WF-4 | RPT-001,003,005 | Built (FbkSummaryService) | Recompute trigger (Q3) |
| REQ-FBK-013 | Consent authoring | — | consent-forms/admin/* | WF-5 | — | Built (ConsentFormController → PPT models) | Boundary (A1) |
| REQ-FBK-014 | Consent responses | — | consent-forms/admin/responses | WF-5 | RPT-006 | Built | Boundary (A1) |
| REQ-FBK-015 | Dashboard/analytics | — | dashboard, pages/analytics | — | RPT-003 | Built (FbkDashboardController, FbkMenuController) | Tests |

> RTM rows reconcile to §10.4 (15 REQ, 23 BR, 6 RPT). Code-status reflects this session's read of the live tree;
> the deep code/security verification is the Technical Auditor's job.

---

# Section 12 — Requirement Conditions Catalog + Validation & Edge-Case Catalog

## 12.1 Conditions Catalog (keyed to BR IDs)
| Condition (=BR) | Entity/Field | Condition (business) | Type | On violation |
|-----------------|--------------|----------------------|------|--------------|
| BR-FBK-001 | Cycle.window/status | submit only when Active & in window | Validation | Block submit; "cycle not open" |
| BR-FBK-002 | Flow.context | respondent–target must satisfy required context | Validation | Target not listed / submit rejected |
| BR-FBK-006 | Peer pairing | respondent ≠ target; same class-section | Validation | Self excluded; cross-section excluded |
| BR-FBK-008 | Anonymity (peer) | never expose identity | Permission | Suppress identity fields |
| BR-FBK-009 | Summary threshold | count ≥ min_responses_for_visibility | Workflow | Withhold summary; show "insufficient responses" |
| BR-FBK-018 | Template.is_locked | locked → no question edits | Workflow | Block edit; require clone |
| BR-FBK-020/021 | Identity pointers | exactly one respondent & one target id | Validation | Reject submit |
| BR-FBK-023 | Dedup slot | one response per pairing | Concurrency | Reject duplicate (unique constraint) |

## 12.2 Validation & Edge-Case Catalog (selected)
| Field/Rule | Valid | Invalid | Boundary | Empty/null | Concurrency |
|------------|-------|---------|----------|-----------|-------------|
| Required answer | all required answered | required missing on submit | last required just answered | draft with blanks allowed | — |
| Duplicate submission | first submit succeeds | second submit same pairing | — | — | two tabs submit → only one wins (BR-023) |
| Withdrawal window | withdraw before close | withdraw after close | exactly at end-date boundary | — | withdraw + close race → close wins |
| Visibility threshold | count = 3 shows | count = 2 hidden | count crosses 3 on a submit | 0 responses hidden | concurrent submits update count once each |
| Reverse scoring | inverted before avg | raw used (bug) | scale max value | no numeric Qs → no avg | — |
| Template lock | clone to edit | edit locked template | lock on first activation | unlocked draft editable | activation locks mid-edit |

---

# Section 13 — Process Flows + State Machine (FSM) Catalog

## 13.1 Process Flows
See Section 6 (WF-1…WF-5) — each with trigger, steps, exception path and notifications.

## 13.2 FSM — Feedback Cycle (driven by `sys_dropdown_table` key `fbk_cycles.status`, per D29)
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| Draft | Activate (admin / on start_date) | flows configured; targets populated | Active | lock templates in use (BR-018); notify respondents |
| Draft | Cancel | — | Cancelled | none |
| Active | Close (admin / on end_date) | — | Closed | stop submissions; finalise summaries |
| Active | Cancel | — | Cancelled | discard open submissions from publishing |
| Closed | Publish | summaries computed | Published | release summaries to eligible targets (BR-009) |
| Closed | Cancel | — | Cancelled | none |
**Terminal:** Published, Cancelled. **Illegal (must block):** Draft→Closed, Draft→Published, Active→Published, any →Draft.

## 13.3 FSM — Response (`fbk_responses.status`)
| From | Event | Guard | To | Side-effects |
|------|-------|-------|----|--------------|
| (none) | Save draft | eligible; cycle Active | Draft | upsert answers |
| Draft | Submit | all required answered | Submitted | compute overall_rating (BR-012/013/014); recompute summary + counters (BR-019) |
| Submitted | Withdraw | before close & flow allows (BR-017) | Withdrawn | recompute summary + counters |
**Terminal:** Withdrawn. **Illegal:** edit a Submitted response; Submitted→Draft.

---

# Section 14 — Cross-Module Dependency Map — *technical register*

**Inbound (Feedback reads):**
| Source module | Data/Entity | Why |
|---------------|-------------|-----|
| SchoolSetup | classes, sections, `sch_class_section_jnt`, subjects, departments, employees, academic sessions | target identity + eligibility context |
| StudentProfile | `std_students`, `std_guardians`, `std_student_guardian_jnt`, `std_student_academic_sessions` | respondent identity, parent-link, student context |
| SmartTimetable | `tt_activity`, `tt_activity_teacher` | subject-teacher eligibility & teacher→student pairs |
| Transport / Hostel | route / hostel context (`context_json`) | staff-feedback eligibility |
| SystemConfig | `sys_users`, `sys_dropdown_table` | login identity + all status/kind/type value sets |

**Outbound (Feedback should feed):**
| Target module | Mechanism | What |
|---------------|-----------|------|
| Notification (+ EventEngine) | event/job | cycle-open, reminder, summary-published *(currently unwired — ENH-001)* |
| Scheduler | scheduled job | date-driven cycle transitions *(verify — Q2)* |

**Crossover:** ParentPortal owns `ppt_consent_forms` / `ppt_consent_form_responses`; Feedback's
`ConsentFormController` uses `Modules\ParentPortal\Models\ConsentForm(Response)` (Anomaly A1).

---

# Section 15 — NFR Catalog + Risk Register

## 15.1 NFR Catalog
| NFR ID | Category | Requirement (measurable) | Threshold |
|--------|----------|--------------------------|-----------|
| NFR-FBK-001 | Performance | Eligible-target listing for a 500-student peer flow returns within interactive time | < 2 s p95 |
| NFR-FBK-002 | Performance | Dashboards read from materialised summaries, not live aggregation | summary read O(1) per target |
| NFR-FBK-003 | Security/Privacy | Anonymous flows never leak respondent identity to targets | 0 identity fields in target-facing payloads |
| NFR-FBK-004 | Privacy | k-anonymity threshold enforced before any target-facing summary | default 3, configurable per flow |
| NFR-FBK-005 | Scalability | One cycle supports many concurrent flows and large target sets | ≥ 10 flows, ≥ 5k targets/cycle |
| NFR-FBK-006 | Compliance | NEP-2020 mandated flows trackable for coverage | RPT-FBK-004 |
| NFR-FBK-007 | Integrity | Exactly-once response per pairing under concurrency | DB unique constraint (BR-023) |
| NFR-FBK-008 | Tenancy | All data isolated per school | no cross-tenant reads |

## 15.2 Risk Register
| Risk ID | Risk | Cat | L | I | Mitigation | Trigger |
|---------|------|-----|---|---|------------|---------|
| RISK-FBK-001 | Anonymity leak deanonymises a minor (peer feedback) | Privacy/Safety | M | H | Hardcode BR-008/010; admin audit only; tests | any target-facing identity field |
| RISK-FBK-002 | Summary shown below threshold reveals small-group identity | Privacy | M | H | Enforce BR-009 on every read | summary view count < k |
| RISK-FBK-003 | Permissions not seeded → authorization fails or over-permits | Security | M | H | Confirm `tenant.feedback.*` seeding (Q4) | Gate::authorize unresolved |
| RISK-FBK-004 | Cycle never auto-transitions (no scheduler) → cycles stuck | Operational | M | M | Own/verify scheduled transitions (Q2) | Active cycle past end-date |
| RISK-FBK-005 | Summary/counters drift if recompute not invoked on withdraw | Data quality | M | M | Verify BR-019 inline calls (Q3) | counts ≠ response totals |
| RISK-FBK-006 | Consent Form module-boundary confusion (ownership) | Architecture | H | M | Decide owner (A1, ENH-006) | duplicate consent UIs |

---

# Section 16 — Prioritization + Effort Estimation

## 16.1 MoSCoW
- **Must (P0):** REQ-001,002,004,005,006,007,008,009,010,011,012 — the configuration→cycle→submit→summary spine and all child-safety rules.
- **Should (P1):** REQ-003 (Categories), 013/014 (Consent), 015 (Dashboard).
- **Could (P2):** ENH items (notifications, scheduler ownership, trends, sentiment, self-reflection UI).
- **Won't (now):** cross-tenant benchmarking, public anonymous surveys.

## 16.2 Effort & Sprint Tasks (verification/closure, since most is built)
| # | Task | Type | Effort (h) | Depends on | Sprint |
|---|------|------|-----------|------------|--------|
| 1 | Audit eligibility resolvers vs BR-002..006 for every context | Backend/Testing | 10 | REQ-009 | S1 |
| 2 | Verify anonymity + k-anonymity on all target-facing reads | Backend/Testing | 8 | REQ-011 | S1 |
| 3 | Confirm/seed `tenant.feedback.*` & `tenant.consent-forms.*` permissions | Backend | 4 | Q4 | S1 |
| 4 | Confirm summary/counter recompute on submit & withdraw | Backend | 4 | REQ-012 | S1 |
| 5 | Own/verify scheduled cycle transitions | Integration | 6 | Q2 | S2 |
| 6 | Wire Notification events (cycle-open/reminder/publish) | Integration | 8 | ENH-001 | S2 |
| 7 | Pest tests for FSMs, dedup, scoring, anonymity | Testing | 16 | all | S2 |
| 8 | Resolve Consent Form module ownership | Architecture | 4 | A1 | S2 |
> Assumes the v3 schema/migrations are correct (confirmed this session); +N h if migration corrections arise.

---

# Section 17 — User Stories (Gherkin) + KPI Catalog

## 17.1 User Stories (one per P0/P1 spine REQ; link to REQ IDs)
**US-FBK-001 (REQ-010, P0).** As a Student, I want to submit anonymous feedback on my class teacher so that I can be honest without fear.
- Given an Active cycle with a Student→Class-Teacher flow I am eligible for, When I answer all required questions and submit, Then my response is saved once and my class teacher cannot see my identity.
- Given I already submitted for that teacher, When I submit again, Then the system rejects the duplicate.
- Given the cycle has closed, When I open the form, Then submission is disabled.
- Given no eligible targets, When I open the cycle, Then I see an empty-state message.

**US-FBK-002 (REQ-009/011, P0).** As a Student, I want to give peer feedback so that NEP-2020 peer evaluation is captured anonymously.
- Given a peer flow in my class-section, When I view targets, Then I see classmates but never myself.
- Given I submit peer feedback, When my classmate views their summary, Then identities are never shown and the summary appears only once ≥ 3 responses exist.
- Given an admin tries to disable peer anonymity, When they save, Then the system prevents it.

**US-FBK-003 (REQ-006/012, P0).** As an Admin, I want to run a cycle and publish summaries so that staff get actionable, privacy-safe results.
- Given a Draft cycle with flows and targets, When I activate it, Then templates in use lock and respondents can submit.
- Given the cycle closed, When I publish, Then targets meeting the threshold can view their summary.
- Given a target with 2 responses, When they view, Then they see "insufficient responses", not data.

**US-FBK-004 (REQ-004/005, P0).** As an Admin, I want versioned, lockable templates so that mid-cycle edits never corrupt analytics.
- Given a template used by an active cycle, When I edit its questions, Then editing is blocked and I am offered clone-to-new-version.
- Given a cloned template, When I edit it, Then changes apply only to future cycles.

**US-FBK-005 (REQ-008, P0).** As an Admin, I want eligible targets populated automatically so that I don't enumerate thousands of pairs by hand.
- Given an auto-population flow, When I trigger it, Then one target row per eligible target with correct context is created.
- Given submissions arrive, When I view participation, Then expected/received/submitted counts are accurate.

**US-FBK-006 (REQ-013/014, P1).** As Communication staff, I want to send and review consent forms so that parental approvals are tracked digitally.
- Given a consent form for a class, When parents respond, Then I can review responses with student/guardian attribution and totals.
- Given an inactive form, When a parent opens it, Then no response is accepted.

## 17.2 KPI Catalog
| KPI | Definition (business) | Source | Target | Cadence |
|-----|-----------------------|--------|--------|---------|
| Participation rate | received ÷ expected per flow | fbk_cycle_targets counters | ≥ 70% | per cycle |
| NEP-2020 coverage | mandated flows run ÷ classes | cycles × flows | 100% | per session |
| Anonymity incidents | identity leaks reported | audit | 0 | continuous |
| Below-threshold suppression | summaries withheld < k | summary reads | tracked | per cycle |
| Average target rating | mean overall_rating per target type | fbk_summary | trend up | per cycle |

---

# Section 18 — Anomalies & Open Questions

**Anomalies (verified facts)**
- **A1 — Consent Form cross-module ownership.** `Modules/Feedback` hosts `ConsentFormController` + admin Blade
  views, but the models and tables are ParentPortal's (`ppt_consent_forms`, `ppt_consent_form_responses`).
  Documented here as REQ-013/014 but flagged for the Enterprise Architect to assign a clean owner.
- **A2 — `fof_feedback_*` is not this module.** FrontOffice owns those tables (`fof_` prefix); excluded from FBK.
- **A3 — Canonical schema is v3, not v2.** `modules-map.md` cites the v2 DDL as the scaffold basis, but the
  live migrations/models/dropdown-seeder follow the ENUM-free **v3** (D29). This FRD uses v3.

**Open questions (for downstream agents)**
- **Q1.** Confirm anonymity/k-anonymity is enforced on *every* target-facing read path (not just the service) — Technical Auditor.
- **Q2.** Is there a scheduled job that transitions cycle status by date, or is it manual-only today? — verify with Scheduler module.
- **Q3.** Confirm summary + participation recompute (BR-019) fires on both submit and withdraw (EventServiceProvider is empty).
- **Q4.** Are `tenant.feedback.*` / `tenant.consent-forms.*` permissions seeded anywhere? None found in `database/seeders`/`app` this session.
- **Q5.** Test coverage: no Feedback test files were observed — confirm zero and prioritise (Testing Architect).

---

*End of FBK Complete Analysis Pack. IDs assigned here are stable; downstream gap/audit/test artifacts must reuse them.*
