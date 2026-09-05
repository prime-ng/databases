# Prime-AI Behavioural Assessment Module — Business Requirements Document

**Document ID:** BHA-BRD-V3
**Version:** 3.0
**Status:** Approved-for-Design baseline
**Date:** 2026-09-05
**Module:** BehaviouralAssessment (`Modules\BehaviouralAssessment`)
**Application:** Prime-AI Main Application — Indian K-12 School Management
**Database:** `tenant_db` (database-per-tenant; no `tenant_id` column)
**Table prefix:** `ba_*`

**Supersedes:** `BehaviouralAssessment_BRD_v2.md` (v2.0) and `BehaviouralAssessment_BRD_v1.md` (v1.0, 24 screen specs)
**Realised by:** `Solution_Design_v2.md` (solution) → `Behavioural_Assess_DDL_v7.0.sql` (physical schema)

---

## 0. Document Control

### 0.1 Position in the document set

| Layer | Document | Answers |
|---|---|---|
| Business — screens | `BehaviouralAssessment_BRD_v1.md` | What does each of the 24 screens do (retained as UI reference) |
| Business — baseline | `BehaviouralAssessment_BRD_v2.md` | Consolidated requirements; **ended with 8 unresolved product decisions** |
| **Business — this document** | **`Behavioural_Assess_BRD_v3.md`** | **What the business needs, decided. No open questions carried forward.** |
| Solution | `Solution_Design_v2.md` | How the system works and how it is built |
| Physical | `Behavioural_Assess_DDL_v7.0.sql` | How the information is stored |

### 0.2 Why v3 exists

BRD v2 did its job: it consolidated v1's 24 screen specs against the v2 DDL and, crucially, it **named the contradictions** rather than papering over them. It closed with *Part XXIII — Requirements Requiring Explicit Product Decisions* (8 items) and a 24-line review checklist.

A document that ends in questions cannot govern a schema. **v3 answers every one of them.** Each answer is recorded in §24 as a numbered decision with its rationale and its consequence in the schema.

v3 also incorporates two bodies of evidence that v2 did not have in front of it:

1. **The live implementation.** The module is ~55–60% built: 16 models, 16 tenant migrations, 12 controllers, 17 policies, 65 Blade views, 5 seeders, 1 service. Requirements are written against what exists, not against a greenfield.
2. **The 2026-06-29 technical audit** (Health 57/100 Amber, `BehaviouralAssessment_Complete_Audit_2026-06-29.md`). Of 30 business rules, **15 were enforced, 6 partial, 9 missing**. The audit's P1 findings are not "bugs to fix later" — several of them exist *because the schema gave the application no way to enforce the rule*. Those are corrected here as requirements.

### 0.3 What changed from v2

| # | Change | Driver |
|---|---|---|
| C-01 | **All 8 open decisions resolved** (§24). No item is deferred | v2 Part XXIII |
| C-02 | **Intervention becomes a tracked case**, not a checkbox: owner, due date, status, progress log, completion/cancellation evidence | v2 §62–63; v1 Screen 14 |
| C-03 | **Incident gains a formal lifecycle** `open → under_review → action_taken → resolved → closed` | v2 §107 |
| C-04 | **Historical integrity is now a hard requirement.** A locked period freezes the behavioural framework it was scored against | v2 §98, §108 — "one of the most important requirements" |
| C-05 | **Parent notification is specified as a delivery obligation with an auditable outbox**, not a boolean | Audit SEC-BA-001 — notification was found *entirely absent*; `is_notified` was never written |
| C-06 | **Period lock must cascade to assessments and ratings** | Audit BUG-BA-001 — "locked" periods did not actually freeze anything |
| C-07 | **Period and assessment state machines are specified as legal-transition tables** | Audit BUG-BA-002 — `open→locked` was possible, `open→closed` was unreachable |
| C-08 | **Approval and locking are separate business events**, with an optional combined UI action | v2 §35, §105 |
| C-09 | **Review can be switched off per session** (small schools), publishing on submit | BR-BA-025, found unimplemented |
| C-10 | **Count-based escalation** ("3 incidents in 30 days") added alongside severity-based notification | ENH-BA-001; v1 Configuration screen |
| C-11 | **Every statistical threshold is stored as a percentage of the active scale**, not an absolute like 2.5 or 1.20 | v2 §80, §82 — thresholds were hard-coded to a 5-point scale |
| C-12 | **Follow-up notes become an append-only log**; witness statements become first-class, permissioned and freezable | Audit BUG-BA-009 (notes overwritten); v2 §56–59 (statement text had no column at all) |
| C-13 | **Comment Bank promoted from "helper idea" to a specified master** | v2 §32 |
| C-14 | **Optional Behaviour Points ledger** so a school may, if it chooses, let incidents affect standing — off by default | v2 §109 |
| C-15 | **Severity vocabulary fixed** to `minor / moderate / major / critical`, with a documented UI alias map | v2 §48, §106 |
| C-16 | Success criteria replaced by **measurable acceptance criteria** (§26) | — |

### 0.4 Identifier policy

Identifiers assigned in the 2026-06-29 FRD are **stable and must not be renumbered**: `REQ-BA-001…018`, `BR-BA-001…030`, `RPT-BA-001…010`, `ENH-BA-001…004`. v3 extends each range upward and reuses no retired number. A rule marked *(v3)* is new; a rule marked *(v3-rev)* existed but is restated with a decided meaning.

---

# Part I — Business Context

## 1. Executive Summary

The Behavioural Assessment Module gives a school a structured, consistent and auditable way to describe, measure, evidence and act on student behaviour. It joins two things most schools keep apart:

- **Periodic assessment** — planned, criteria-based, cohort-wide, produces a number.
- **Incident management** — event-driven, individual, produces a documented case with an owner and an outcome.

The module exists to move behavioural evaluation away from an unstructured comment box and toward a framework in which expectations are named, ratings are controlled, submissions are reviewed, scores are computed the same way every time, and every serious event has a traceable response.

The deliverable is a **longitudinal behavioural-development record**, not a marks-entry screen.

## 2. Module Purpose

The module shall enable a school to:

1. Define behavioural categories and observable criteria, with polarity and weight.
2. Configure one or more rating scales with ordered, numerically valued levels.
3. Choose the scale that applies to a session, and optionally override it for a class band.
4. Map categories to classes so expectations are age-appropriate.
5. Define assessment periods within an academic session, with deadlines and a lifecycle.
6. Let authorised teachers assess students through a student × criterion grid, with auto-save.
7. Capture per-criterion remarks and one holistic remark per student, aided by a Comment Bank.
8. Route submissions through supervisory review, with send-back and reviewer feedback.
9. Finalise, lock and freeze approved assessments so history cannot silently change.
10. Compute criterion, category and overall scores consistently, averaging across teachers and normalising negative categories.
11. Cache computed scores for reporting, with full recomputation provenance.
12. Log positive and negative behavioural incidents with severity, location, evidence and witnesses.
13. Run each incident through a lifecycle to a documented resolution.
14. Assign interventions to a named owner with a due date, and track them to completion or justified cancellation.
15. Notify parents and school leadership when severity or repeat-count thresholds are met, and prove the notification was attempted.
16. Report at student, class, category, period and incident level, with anonymised variants and asynchronous export for large result sets.
17. Maintain an immutable audit trail with a defined retention policy.
18. Expose finalised behavioural scores to the Exam/Result area **without BA writing to any academic-result table**.

## 3. Business Problems Addressed

| # | Problem | How the module addresses it |
|---|---|---|
| P-01 | **Behaviour is described subjectively.** "Good boy, needs improvement." | Named categories, observable criteria, controlled rating levels |
| P-02 | **Teachers grade differently.** One teacher's 4 is another's 2. | Multi-teacher averaging, review workflow, per-teacher consistency (SD) analytics |
| P-03 | **A score has no evidence behind it.** | Per-criterion remarks, incidents, witnesses, attachments, interventions |
| P-04 | **No longitudinal view.** Nobody can say whether a child improved. | Period-over-period deltas, trend bands, progress charts |
| P-05 | **Incidents go nowhere.** An event is logged; nothing records what the school did. | Incident lifecycle + intervention case management with owner, due date and outcome |
| P-06 | **Parent conversations are anecdotal and adversarial.** | An evidence-backed student dossier for PTMs |
| P-07 | **Sensitive records change without trace.** | Immutable audit log; lock cascade; frozen framework snapshots |
| P-08 | **Repeat low-level behaviour is invisible** until it becomes serious. | Count-based escalation across a rolling window (C-10) |
| P-09 | **Reports slow the system down** at scale. | Materialised score cache; asynchronous export above a configured row threshold |

## 4. Scope

### 4.1 In scope

Behavioural framework masters · rating scales · class applicability · assessment periods · session configuration · teacher assessment and rating entry · review and approval · score computation and caching · incident logging, witnesses, evidence and lifecycle · intervention case management · notification triggering and delivery record · dashboard · 10 reports · audit trail · pull-based result integration.

### 4.2 Out of scope

- **Attendance, discipline registers and leave** — separate modules.
- **Actual message delivery.** BA raises the obligation and records the outcome; the Notification module sends. BA implements no SMTP/SMS/push transport.
- **File storage.** BA holds references; Prime-AI media storage holds bytes.
- **Academic marks and result publication.** BA never writes `exm_*`.
- **Counselling case notes of a clinical nature.** Out of scope pending a separate privacy review (see §28 ENH-BA-021).
- **Student self-assessment and peer assessment.** Proposed as an enhancement (§28 ENH-BA-012), not part of this baseline.

### 4.3 Assumptions

| # | Assumption |
|---|---|
| A-01 | SchoolSetup, StudentProfile and Notification modules are live and authoritative |
| A-02 | Teacher-to-class assignment is resolved from SchoolSetup/timetable; BA maintains no assignment master |
| A-03 | One academic session is current at a time; sessions do not overlap |
| A-04 | MySQL 8.0.16 or later (CHECK constraints are only enforced from that version) |
| A-05 | A school's behavioural framework is stable *within* a period; changes take effect from the next period |

---

# Part II — Users and Responsibilities

## 5. User Roles

| Role | Primary activities | Scope |
|---|---|---|
| Admin / Principal | Configure scales, categories, criteria, class mapping, periods, interventions, notification policy; view everything; run audits | School-wide |
| Class Teacher | Conduct periodic assessments for own class-sections, enter remarks, log incidents, view own-class reports | Assigned class-sections |
| Subject Teacher | Rate applicable criteria for taught cohorts; log incidents | Assigned teaching scope |
| HOD / Coordinator | Review and approve/send back submissions; cohort analytics; own interventions | Department / assigned classes |
| Behavioural Counsellor | Review incidents, own and progress interventions, read witness statements, view at-risk registers | School-wide, incident domain |
| Parent / Guardian | View finalised, permitted behavioural information for own child | Own child |
| Student | Optional progress-oriented self view | Own record |

## 6. Role-Based Visibility Matrix

`F` = full · `L` = limited/redacted · `—` = no access

| Information | Admin/Principal | Class Teacher | Subject Teacher | HOD | Counsellor | Parent | Student |
|---|---|---|---|---|---|---|---|
| Draft ratings | F | F (own) | F (own) | L (in review) | — | — | — |
| Finalised scores | F | F (own class) | L | F | F | F (own child) | L (own) |
| Per-criterion remarks | F | F (own class) | L | F | F | L | — |
| Overall student remark | F | F (own class) | — | F | F | F (own child) | L |
| Incident metadata | F | F (own class) | L (own reports) | F | F | L (own child) | — |
| Incident description | F | F (own class) | L (own reports) | F | F | L (own child) | — |
| **Witness statement text** | F | — | — | F | F | — | — |
| Intervention detail | F | L | — | F | F | L (own child) | — |
| Audit trail | F | — | — | L | L | — | — |
| Cohort analytics | F | F (own class) | L | F | F | — | — |
| Anonymised analytics | F | F | F | F | F | — | — |

**REQ-BA-019 (v3) — Enforced visibility.** Every screen and every report shall enforce this matrix server-side. Client-side hiding alone is not compliance.

**BR-BA-031 (v3) — Witness statements are elevated.** Statement text is readable only by HOD, Counsellor and Principal-level roles. Every read of statement text is written to the audit log.

**BR-BA-032 (v3) — Parents see finalised only.** No draft, submitted or sent-back score, and no unresolved incident narrative, is exposed on a parent-facing surface.

---

# Part III — Functional Structure

## 7. Menus and Screens

The 24 screens of BRD v1 are retained. v3 adds four.

| Group | Screen | Status |
|---|---|---|
| Dashboard | 01 Dashboard | Retained |
| Masters | 02 Rating Scales · 03 Categories & Criteria · 04 Interventions | Retained |
| Masters | **25 Comment Bank** | **New (C-13)** |
| Setup | 05 Class Mapping · 06 Assessment Periods · 07 Configuration | Retained |
| Setup | **26 Framework Snapshots** (read-only history viewer) | **New (C-04)** |
| Assessments | 08 My Assessments · 09 Ratings · 10 Remarks · 11 Review Queue | Retained |
| Incidents | 12 Incident Log · 13 Witnesses · 14 Interventions Applied | Retained |
| Incidents | **27 Intervention Worklist** (my open cases, by due date) | **New (C-02)** |
| Reports Hub | 15 Reports Hub · 16 Student Scores · 17 Category Summary · 18 Period Report · 19 Audit Trail | Retained |
| Standalone | 20 Student Report · 21 Class Analysis · 22 Period Progress · 23 Category Performance · 24 Incident Report | Retained |
| Ops | **28 Notification Outbox** (delivery status, retry) | **New (C-05)** |

---

# Part IV — Core Behavioural Model

## 8. The Hierarchy

```
Rating Scale ── Rating Levels
                     │ (selected value)
                     ▼
Category ──▶ Criterion ──▶ Student Rating ──▶ Criterion Score ──▶ Category Score ──▶ Overall Score ──▶ Grade
  │                                              (avg across teachers, polarity-normalised)
  └── polarity (positive | negative)
  └── weight
```

**A category** is a behavioural domain. **A criterion** is an observable behaviour within it. **A rating level** is the observed degree. **The numeric value** is what makes it computable.

## 9. Polarity

**BR-BA-007 (v3-rev) — Negative-category normalisation.**

For a positive category, a higher rating is better. For a negative category the raw value is inverted so that direction is consistent across the whole framework:

```
inverted_score = (scale_max + scale_min) - raw_score
```

> **Correction to v2 §8.** BRD v2 and DDL v2 both state `(max + 1) - raw`. That formula is only correct when `scale_min = 1`. For a scale running 0–4 it produces values in 1–5, silently shifting negative categories one point above positive ones. The generalised form `(max + min) - raw` reduces to `(max + 1) - raw` for every 1-based scale, so **no existing 5-point or 3-point school is affected**, and 0-based or 2-based scales become correct. This is a defect fix, not a policy change.

## 10. Periodic Assessment vs Incident

| | Periodic Assessment | Incident |
|---|---|---|
| Trigger | Planned, period-bound | Event-driven, any time |
| Subject | A cohort | One student |
| Produces | A number | A documented case |
| Framework link | Mandatory (criterion) | Optional (category/criterion) |
| Affects the score | Yes | **No, unless Behaviour Points are enabled** (§24 D-09) |
| Lifecycle | draft → submitted → reviewed → locked | open → under_review → action_taken → resolved → closed |

---

# Part V — Master Requirements

## 11. Rating Scales

**REQ-BA-001 — Configurable rating scales.** A school shall maintain one or more scales.

Scale attributes: `code`, `name`, `description`, `grade_type` (letter | numeric | descriptive), `min_rating`, `max_rating`, `is_default`, `is_active`.

| Rule | Statement |
|---|---|
| BR-BA-026 | A scale shall have at least 2 and at most 10 levels |
| BR-BA-027 | `max_rating > min_rating`; every level's `numeric_value` shall lie within `[min_rating, max_rating]` |
| BR-BA-028 (v3-rev) | **At most one scale may be `is_default` at any time.** Enforced by the database, not by convention — the audit found multiple defaults were possible |
| BR-BA-029 (v3-rev) | **A scale in use is immutable in its numeric shape.** Once any rating exists against a scale's levels, `min_rating`, `max_rating` and every level's `numeric_value` are frozen. Labels and descriptions remain editable |
| BR-BA-033 (v3) | Level `label` and `numeric_value` are each unique within a scale |
| BR-BA-016 | A scale may be deactivated but never destroyed while historical ratings reference it |

**Default seed — 5-Point Behavioural Scale** (`5_POINT`, letter, 1.0–5.0):

| Order | Level | Value |
|---:|---|---:|
| 1 | Unsatisfactory | 1.0 |
| 2 | Needs Improvement | 2.0 |
| 3 | Good | 3.0 |
| 4 | Very Good | 4.0 |
| 5 | Outstanding | 5.0 |

## 12. Categories

**REQ-BA-002 — Behavioural categories.** Categories carry `code`, `name`, `description`, `polarity`, `weight`, `sort_order`, optional `parent_id`, `is_active`.

**Seeded framework — 9 categories, 58 criteria:**

| # | Category | Polarity | Criteria |
|---:|---|---|---:|
| 1 | Classroom Engagement | positive | 8 |
| 2 | Respect and Responsibility | positive | 8 |
| 3 | Cooperation and Collaboration | positive | 7 |
| 4 | Emotional and Social Development | positive | 6 |
| 5 | Leadership and Initiative | positive | 6 |
| 6 | Disruptive Behaviours | negative | 7 |
| 7 | Aggressive or Bullying Behaviours | negative | 6 |
| 8 | Academic Misconduct | negative | 6 |
| 9 | Health and Safety Violations | negative | 4 |
| | **Total** | | **58** |

**BR-BA-034 (v3) — Hierarchy depth.** Category nesting is limited to two levels (parent → child). A child category may not itself be a parent. Deeper trees make weighting unexplainable to teachers.

**BR-BA-035 (v3) — Leaf-only criteria.** Criteria attach only to leaf categories. A parent category's score is the weighted roll-up of its children.

## 13. Weighting

**BR-BA-036 (v3) — Weights are proportional, normalised at computation.**

Weights need not total 100. The engine normalises against the sum of *applicable, active* weights:

```
category_contribution = category_score × (category_weight / Σ applicable category weights)
```

The UI shall display each weight both as entered and as its **effective percentage** of the current total, so an administrator can see that four categories at 100 each are 25% apiece.

> **Resolution of v2 §16.** The "criteria must total 100%" statement in the v1 screen spec is a **presentation and validation convention, not a storage rule**. The screen may warn when a category's criteria do not total 100; it shall not block saving, and the engine never depends on it.

## 14. Criteria

Criterion attributes: `code` (unique within category), `name`, `description`, `weight`, `sort_order`, `is_active`.

> **Resolution of v2 §15.** v1 proposed a per-criterion `max_score`. **Rejected.** The rating range belongs to the scale; a per-criterion maximum would let two criteria in the same grid use different ranges, which teachers cannot reason about and which breaks averaging. A criterion's influence is expressed through its **weight**.

## 15. Interventions Master

**REQ-BA-003 — Intervention master.** Attributes: `code`, `name`, `description`, `intervention_type`, `default_due_days`, `requires_owner`, `requires_parent_meeting`, `sort_order`, `is_active`.

**Canonical types:** `reward` · `corrective` · `counselling`.

> **Resolution of v2 §17.** v1's "Reinforcement" and "Supportive" are **display aliases**, not separate types. UI copy may use them; the stored vocabulary is the canonical three.

**Seeded interventions (12 — 9 original + 3 added in v3):**

| Type | Interventions |
|---|---|
| reward | Award/Certificate · Public Recognition · Extra Privileges |
| corrective | Verbal Warning · Written Warning · Detention · Suspension · **Behaviour Contract** *(v3)* |
| counselling | Parent Meeting · Counselling Referral · **Restorative Conversation** *(v3)* · **Peer Mediation** *(v3)* |

**BR-BA-037 (v3) — Type must match incident polarity.** A `reward` intervention may only be applied to a positive incident; `corrective` only to a negative incident. `counselling` applies to either.

## 16. Comment Bank *(new — C-13)*

**REQ-BA-020 (v3) — Comment Bank.** A master of reusable narrative templates so remarks are professional and consistent without becoming identical.

| Attribute | Purpose |
|---|---|
| `category_id` | Optional — scopes a template to a behavioural domain |
| `sentiment` | `positive` · `neutral` · `developmental` |
| `template_text` | Text containing `{student}`, `{he_she}`, `{him_her}`, `{his_her}` placeholders |
| `applies_to` | `criterion_remark` · `overall_remark` · `both` |
| `is_system` | System templates are protected from deletion |

**BR-BA-038 (v3) — Insert, then own.** A template is a starting point. Inserted text is fully editable and is stored as the teacher's own words; the module records which template seeded it for analytics only.

**BR-BA-039 (v3) — Placeholder substitution.** `{student}` resolves to the student's preferred/first name at insertion time. Gender pronouns resolve from StudentProfile; where gender is unrecorded or "Prefer not to say", the neutral form (`they` / `their`) is used.

---

# Part VI — Academic Setup

## 17. Class-to-Category Mapping

**REQ-BA-004 — Class applicability.** Administrators map categories to classes so a Grade 1 grid does not contain Academic Misconduct.

**BR-BA-009 (v3-rev) — Permissive fallback.** If a class has **no** mappings at all, **all active categories apply**. This is deliberate: a school that has not yet configured mapping must still be able to assess. The audit found this fallback missing, which produced empty grids. Once a class has at least one mapping, only mapped categories apply.

**BR-BA-040 (v3) — Mapping changes are forward-only.** Changing a mapping never alters an already-locked period; the frozen framework snapshot governs history (§21).

## 18. Assessment Periods

**REQ-BA-005 — Assessment periods.** A period carries `academic_session_id`, optional `academic_term_id`, `name`, `start_date`, `end_date`, `deadline`, `status`.

| Rule | Statement |
|---|---|
| BR-BA-041 (v3) | `end_date >= start_date` and `deadline >= end_date` |
| BR-BA-042 (v3) | Two periods within one session may not have identical names |
| BR-BA-043 (v3) | Period date ranges within a session **may** overlap (a monthly and a termly cycle can run together), but a warning is shown |

## 19. Period Lifecycle *(C-07)*

```
        ┌────────── reopen() ──────────┐
        ▼                              │
     [OPEN] ──── close() ────▶ [CLOSED] ──── lock() ────▶ [LOCKED]  (terminal)
```

**BR-BA-044 (v3) — Legal transitions only.**

| From | To | Action | Allowed |
|---|---|---|---|
| open | closed | `close()` | Yes |
| closed | open | `reopen()` | Yes — Admin/Principal only, audited |
| closed | locked | `lock()` | Yes |
| open | locked | — | **No.** A period must be closed before it is locked |
| locked | anything | — | **No.** Terminal |

> The audit found the reverse of this table implemented: `open → locked` was permitted, `locked → closed` was permitted, and no `close()` action existed at all, making `open → closed` unreachable. The state machine is now normative and enforced at the database level.

| State | Effect |
|---|---|
| **Open** | Assessments may be created and edited |
| **Closed** | No new assessments; existing ones may complete review; scores may be computed |
| **Locked** | Everything below is frozen (§20); the framework snapshot is taken |

## 20. Lock Cascade *(C-06)*

**BR-BA-045 (v3) — Locking a period locks everything beneath it.**

```
lock(period)
   ├─ every assessment in the period  → status = locked, locked_at set
   ├─ every rating under those assessments → immutable
   ├─ every student remark under them → immutable
   └─ the framework snapshot           → taken and sealed
```

> This is the single most consequential correction in v3. The audit's BUG-BA-001 reads: *"The lock guard checks `assessment.status === 'locked'`, but no code ever sets that status — period `lock()` updates only the period row. Net effect: locked periods don't freeze ratings, and approved scores can be silently edited out of sync with the cache and the audit trail."* A published score that can change without trace is a compliance failure, not an inconvenience.

## 21. Framework Snapshot *(C-04)*

**REQ-BA-021 (v3) — Frozen framework.** At the moment a period is locked, the module captures the complete framework the period was scored against: the active scale and its levels, every applicable category and criterion with its weight and polarity, the class-category mapping, and the aggregation settings.

**BR-BA-046 (v3) — History is read through its snapshot.** Any report, recomputation or export of a locked period resolves names, weights and scale values **from the snapshot**, never from the live masters.

**BR-BA-047 (v3) — Snapshots are immutable.** A snapshot has no update path. Re-locking after a reopen creates a new snapshot version; the old one is retained.

> **Resolution of v2 §98/§108.** v2 called this "one of the most important requirements to address" and left it open. Without it, an administrator adjusting a weight in March silently rewrites what a September report card meant. A parent-facing historical grade must remain explainable.

## 22. Session Configuration

**REQ-BA-006 — One configuration per academic session.** v3 expands `ba_config` from 5 settings to a full policy record. Grouped:

| Group | Settings |
|---|---|
| **Scale** | active `rating_scale_id`; optional per-class overrides (§24 D-02) |
| **Workflow** | `is_review_required` (D-04) · `auto_lock_on_approval` (D-03) · `autosave_interval_seconds` (default 30) |
| **Scoring** | `aggregation_method` (average \| weighted_average \| separate_display) · `normalisation_base` |
| **Result integration** | `is_result_integration_enabled` (default **off**) · `weightage_percent` (5–20 when on) |
| **Notification** | `parent_notification_threshold` · recipient flags (parent / class teacher / HOD / principal) · `notification_channels_json` · `principal_daily_digest` |
| **Escalation** | `incident_escalation_count` (default 3) · `incident_escalation_window_days` (default 30) |
| **Incident policy** | `incident_backdating_days` (default 7) · description min/max length (20/1000) · witness statement min/max (10/500) |
| **Analytics thresholds** | `at_risk_score_percent` · `at_risk_incident_count` · `trend_improve_percent` · `trend_stable_percent` · `consistency_sd_percent` |
| **Privacy / retention** | `allowed_demographics_json` · `audit_retention_months` (default 36) · `freeze_witness_on_closure` |
| **Features** | `is_comment_bank_enabled` · `is_behaviour_points_enabled` (default **off**) |
| **Performance** | `export_async_row_threshold` (default 1000) |

**BR-BA-048 (v3) — Thresholds are scale-relative.** Every analytical threshold is stored as a **percentage of the active scale's range**, never as an absolute score.

> **Resolution of v2 §80/§82.** v2 proposed at-risk below `2.5/5` and a consistency warning above an SD of `1.20`. Both are 5-point constants. On a 3-point scale, 2.5 flags almost nobody; on a 10-point scale it flags almost everybody. Stored as percentages — at-risk at 50% of range, SD warning at 30% of range — the same policy travels across scales. Default values are chosen to reproduce the familiar 5-point behaviour exactly.

**BR-BA-002 — Session scoping.** Configuration is per academic session. A new session starts from the previous session's settings as a copyable draft.

## 23. Result Integration

**REQ-BA-007 — Optional weighted contribution.** Default **off**.

```
Final = Academic × (1 − w) + Behavioural_normalised × w      where w = weightage_percent / 100
Behavioural_normalised = (overall_score − scale_min) / (scale_max − scale_min) × normalisation_base
```

**BR-BA-017 — Module boundary.** BA exposes finalised scores through a read service. **BA never writes to `exm_*` or any academic-result table.** Integration is pull-based.

**BR-BA-049 (v3) — Only locked periods are integrable.** A period that is not locked returns no score to the result layer, regardless of configuration.

---

# Part VII — Assessment Workflow

## 24. Assessment Header

An assessment is one **teacher × class-section × period** evaluation.

**BR-BA-004 — Uniqueness.** A teacher may not hold two assessments for the same class-section and period.

**BR-BA-050 (v3) — Assessment scope.** An assessment records whether it was raised as `class_teacher` or `subject_teacher` scope, and for subject scope, which subject. This matters for multi-teacher averaging: it lets a school later choose to weight the class teacher's view differently (§28 ENH-BA-009) and it makes "who rated this child" answerable.

## 25. Teacher Assignment Resolution

**BR-BA-051 (v3) — No assignment master in BA.** Eligibility is resolved from SchoolSetup and timetable data at the moment the assessment is created, and the resolved teacher and class-section are then held on the assessment. A later timetable change does not orphan or retro-assign completed work.

## 26. Assessment Lifecycle *(C-07, C-08)*

```
                          ┌──── sendBack() ────┐
                          │                    │
   [DRAFT] ──submit()──▶ [SUBMITTED] ──approve()──▶ [REVIEWED] ──lock()──▶ [LOCKED]
      ▲                       │                        │                    (terminal)
      └──────── sendBack() ───┘◀───────────────────────┘
```

**BR-BA-052 (v3) — Legal transitions only.**

| From | To | Action | Who |
|---|---|---|---|
| draft | submitted | `submit()` | Owning teacher |
| submitted | reviewed | `approve()` | HOD / Principal |
| submitted | draft | `sendBack()` | HOD / Principal — reviewer remark **mandatory** |
| reviewed | draft | `sendBack()` | Principal only — reviewer remark mandatory, audited |
| reviewed | locked | `lock()` | Principal, or automatically via period lock, or automatically when `auto_lock_on_approval` is on |
| locked | * | — | **Blocked** |

**BR-BA-053 (v3) — Submit requires completeness.** A submission is rejected unless every applicable student × criterion cell carries a rating. Partial submission is a data-quality hole that review cannot repair, because a reviewer cannot tell an unrated cell from an unobserved one.

**BR-BA-025 (v3-rev) — Review is optional per session.** When `is_review_required = 0`, `submit()` transitions **draft → reviewed** directly and, if `auto_lock_on_approval` is on, onward to locked. Small schools with no HOD layer are not forced through an empty queue.

> The audit found BR-BA-025 had no config flag and no branch anywhere in the code. It is now explicit.

**REQ-BA-022 (v3) — Status history.** Every transition is recorded with actor, timestamp, from-state, to-state and remark. The Review Queue and the Student Report both read from it. This is separate from the field-level audit log and answers a different question: *not "what changed" but "who moved this, when, and why".*

## 27. Send-Back

**BR-BA-054 (v3) — Send-back preserves work.** Returning an assessment to draft never clears ratings or remarks. The teacher corrects and resubmits. `sent_back_count` increments and is visible to the reviewer, because a third send-back is a coaching signal, not a data problem.

## 28. Auto-Save

**REQ-BA-008 — Auto-save.** The rating grid auto-saves at the configured interval (default 30s) and on cell blur. The screen displays the last-saved time. Auto-save writes ratings only; it never changes status.

**BR-BA-055 (v3) — Auto-save is silent on the audit trail.** Intermediate auto-saves within a draft do not each produce an audit row; the audit records the value at submit and every change thereafter. Otherwise a single grid session generates thousands of meaningless audit rows and the real changes become unfindable.

---

# Part VIII — Rating Entry

## 29. The Rating Grid

**REQ-BA-009 — Student × criterion grid.** Rows are students; columns are criteria grouped under their categories. Each cell is one rating fact.

Requirements: applicable students only · applicable criteria only (per class mapping) · configured rating levels only · optional per-criterion remark · keyboard navigation across the grid · fill-column and fill-row helpers · per-student completion indicator · auto-save.

**BR-BA-005 — Rating uniqueness.** One rating per student × criterion × assessment. Re-entry updates.

**BR-BA-056 (v3) — Frozen grid.** The grid renders read-only whenever the assessment is `locked`, or its period is `closed` or `locked`, or the current user is not the owning teacher.

## 30. Remarks

**REQ-BA-010 — Two remark levels.** A per-criterion remark (≤500 chars) and one holistic per-student remark per assessment. Both may be seeded from the Comment Bank.

## 31. Rating Value Snapshot

**BR-BA-057 (v3) — A rating stores the number it meant.** Alongside the selected `rating_level_id`, each rating stores the level's `numeric_value` as it was at the time of rating.

> Today, deleting a rating level sets `rating_level_id` to NULL and the rating silently becomes "not rated" — a locked, published assessment loses data. Storing the value makes a rating self-describing and lets a locked assessment be recomputed identically forever.

---

# Part IX — Review and Quality Control

## 32. Review Queue

**REQ-BA-011 — Review workspace.** Filterable by period, class, section, teacher and status; shows submission date, completion, days-waiting and send-back count.

Reviewer actions: inspect ratings and remarks · **approve** · **send back with mandatory feedback** · **approve & lock** (when `auto_lock_on_approval` is on).

## 33. Quality Signals

**REQ-BA-023 (v3) — Reviewer assistance.** The queue surfaces, per submission:

| Signal | Meaning |
|---|---|
| Flat-line grading | The teacher gave one value to almost every cell |
| Outlier vs cohort | This teacher's mean is far from other teachers' mean for the same students |
| Score/remark mismatch | A low rating paired with a wholly positive remark, or the reverse |
| Missing remarks | Cells rated at the extremes with no explanation |
| Late submission | Submitted after the deadline |

These are **advisory prompts, not blocks**. They tell a reviewer where to look. A reviewer who disagrees approves anyway.

## 34. Approval and Locking *(D-03)*

**BR-BA-058 (v3) — Two events, one optional button.** *Approve* means "a supervisor accepts this content". *Lock* means "this is final and immutable". They are separate business events, separately timestamped and separately attributed. A school that wants one click enables `auto_lock_on_approval`; the two events are still recorded distinctly.

> **Resolution of v2 §35/§105.** Collapsing them in storage would make it impossible to answer "who approved this?" versus "who made it final?" — different people with different accountability.

---

# Part X — Score Computation

## 35. Pipeline

```
ba_assessment_ratings  (raw, per teacher)
      │  filter: assessment.status IN (reviewed, locked)
      ▼
GROUP BY student, criterion  →  AVG(numeric_value) across teachers
      ▼
polarity normalisation:  negative → (max + min) − value
      ▼
GROUP BY category  →  Σ(criterion_score × criterion_weight) / Σ(criterion_weight)
      ▼
overall  →  per aggregation_method over category scores and category weights
      ▼
grade mapping from the active scale's level bands
      ▼
UPSERT ba_computed_scores (per category) + ba_computed_overall (per student-period)
```

**BR-BA-059 (v3) — Only accepted work is scored.** Draft and submitted-but-unapproved ratings never enter computation. When review is disabled, `submit()` produces `reviewed`, so the rule holds unchanged.

**BR-BA-006 — Multi-teacher averaging.** Where several authorised teachers rate the same student on the same criterion in the same period, the values are averaged, and the contributing teacher count is stored so a report can show "averaged across 3 teachers".

**BR-BA-060 (v3) — Unrated cells are excluded, not zeroed.** A criterion nobody rated contributes nothing to numerator or denominator. Treating it as zero would punish a student for a teacher's omission.

**BR-BA-061 (v3) — Minimum evidence.** If fewer than a configured proportion of a category's applicable criteria are rated, the category score is stored as `insufficient_data` rather than as a number. A category score derived from one criterion out of eight is not a measurement.

## 36. Overall Aggregation

| Method | Behaviour |
|---|---|
| `average` | Unweighted mean of category scores |
| `weighted_average` | Weighted by normalised category weights (default) |
| `separate_display` | No overall number is produced; categories are reported individually |

## 37. Grade Mapping

**BR-BA-062 (v3) — Grades come from the scale.** A computed score maps to the label of the nearest level band of the active scale. There is no separate grade-boundary configuration; a single source removes the class of bug where boundaries and levels disagree.

## 38. Score Cache and Recomputation

**REQ-BA-012 — Materialised cache.** Reporting reads `ba_computed_scores` / `ba_computed_overall`; it never aggregates raw ratings at query time.

> **Correction to the v2 data model.** DDL v2 stored the overall score on "the first category row per student-period". That makes the overall depend on row ordering, breaks when the first category is deactivated, and forces every overall query to guess which row is authoritative. v3 gives the overall its own table with a clean `UNIQUE(student, period)`.

**REQ-BA-013 — Recomputation.** Triggered on approval, on lock, and on demand by an administrator. School-wide recomputation runs **as a queued background job**, never in-request.

**BR-BA-063 (v3) — Every computation is provenanced.** Each run records what triggered it, who, when, which period, how many students, how long it took, and which framework snapshot was in force. A score whose provenance cannot be stated cannot be defended to a parent.

**BR-BA-064 (v3) — Locked periods recompute identically.** Recomputing a locked period uses its snapshot and its stored rating values, so it must reproduce the same numbers. Any divergence is a defect and is reported, not silently written.

---

# Part XI — Incident Management

## 39. Purpose and Types

**REQ-BA-014 — Incident logging.** Concrete behavioural events, positive or negative, recorded independently of assessment periods.

| Type | Examples |
|---|---|
| `positive_reinforcement` | Helping peers · leadership shown · exceptional initiative · achievement · contribution to school life |
| `negative_incident` | Disruption · aggression · bullying · academic misconduct · safety violation |

## 40. Severity *(D-05)*

**Canonical stored vocabulary:** `minor` · `moderate` · `major` · `critical`.

| Stored | UI alias (v1 screens) | Typical response |
|---|---|---|
| minor | Info | Logged; teacher-level correction |
| moderate | Low | Parent informed; corrective intervention |
| major | Medium | Parent meeting; HOD involvement; follow-up required |
| critical | High | Principal involvement; formal case; mandatory follow-up |

**BR-BA-065 (v3) — One vocabulary.** The four canonical values are what is stored, reported, exported and thresholded. The aliases are presentation only, defined once in a display map.

**INC-1 / BR-BA-066 (v3-rev) — Severity presence.** A negative incident **must** carry a severity. A positive incident **must not**. Enforced by the database.

## 41. Incident Lifecycle *(C-03, D-06)*

```
[OPEN] ──▶ [UNDER_REVIEW] ──▶ [ACTION_TAKEN] ──▶ [RESOLVED] ──▶ [CLOSED]
   │              │                  │                │
   └──────────────┴──────────────────┴────────────────┴──▶ [CANCELLED]  (with reason)
```

| State | Meaning |
|---|---|
| `open` | Logged; nobody has picked it up |
| `under_review` | A responsible person is investigating |
| `action_taken` | One or more interventions have been assigned |
| `resolved` | All required interventions are completed or justifiably cancelled; an outcome is recorded |
| `closed` | Signed off; the record is frozen |
| `cancelled` | Logged in error or withdrawn; reason mandatory; never deleted |

**BR-BA-067 (v3) — Resolution requires completion.** An incident of `major` or `critical` severity may not reach `resolved` while any linked intervention is still `assigned` or `in_progress`. Every such intervention must be `completed` or `cancelled` with a stated reason.

**BR-BA-068 (v3) — Closure requires an outcome.** Moving to `closed` requires a closure note. "Resolved" with an empty explanation is how a discipline record becomes useless a year later.

**BR-BA-069 (v3) — Positive incidents close simply.** A positive incident may move `open → closed` directly once any reward intervention is completed.

> **Resolution of v2 §107.** v2 asked whether incidents need a formal lifecycle. They do. Without one, the module records that something happened and never records that anything was done — which is precisely problem P-05.

## 42. Incident Data

| Field | Rule |
|---|---|
| `incident_no` *(v3)* | System-generated human reference, e.g. `INC-2026-000417`. Unique. Used in letters, meetings and cross-references |
| `student_id` | Mandatory |
| `incident_date` | Mandatory; **may not be in the future**; may not be earlier than `incident_backdating_days` before today (default 7) — Admin may override with a reason, audited |
| `incident_time` | Optional |
| `incident_type` | Mandatory |
| `severity` | Per BR-BA-066 |
| `description` | Mandatory; length between the configured min and max (default 20–1000) |
| `location` | classroom · playground · corridor · lab · transport · canteen · library · assembly *(v3)* · sports_ground *(v3)* · hostel *(v3)* · online *(v3)* · other |
| `category_id` / `criterion_id` | Optional link to the framework |
| `reported_by` | Mandatory |
| `status` | Per §41 |
| `is_follow_up_required`, `follow_up_date` | Mandatory when severity is `major` or `critical` |

**BR-BA-070 (v3) — Backdating is a policy, not a constant.** The 7-day limit of v1 becomes a configured value with an audited administrative override, because a genuinely late report (a child discloses a bullying incident from last month) must remain recordable.

> **Resolution of v2 §49.** v2 flagged the 7-day rule as "to be confirmed as school policy". It is confirmed — as a *default*, not a hard-coded rule.

**BR-BA-071 (v3) — Cyber and off-site incidents.** The `online` location covers cyber-bullying and incidents on school digital platforms; `transport` and `hostel` cover off-campus school responsibility. Omitting these forces real incidents into "other", where they disappear from hotspot analysis.

## 43. Immutability

**BR-BA-008 (v3-rev) — Core facts are immutable.** After creation, these may not change: `student_id`, `incident_date`, `incident_type`, `severity`, `description`, `location`.

Mutable: status, follow-up fields, notification state, resolution and closure fields, links to witnesses/interventions/attachments.

**BR-BA-072 (v3) — Correction by cancellation.** A materially wrong incident is `cancelled` with a reason and a new one is raised. Records are never edited into a different truth and never hard-deleted.

**BR-BA-073 (v3) — Severity escalation is an exception, formally handled.** Where investigation shows an incident is more serious than first logged, an Admin/Principal may escalate severity. This is the one permitted exception to core immutability: it requires a reason, is written to the audit log with old and new values, and re-evaluates the notification threshold.

## 44. Evidence and Attachments

**REQ-BA-024 (v3) — Relational attachments.** Attachments become rows, not a JSON blob: media reference, original filename, MIME type, size, uploader, timestamp and an optional caption.

> DDL v2 used `attachments_json`. That cannot be indexed, counted, permission-checked per file, or reconciled against media storage when a file is purged. "How many incidents have photographic evidence?" should be a query, not a scan.

**BR-BA-074 (v3) — Attachment access follows incident access,** with the additional rule that evidence on a case involving multiple students is visible only to staff roles, never to any parent.

## 45. Follow-Up

**REQ-BA-025 (v3) — Follow-up is an append-only log.** Each follow-up entry carries its own date, author, note and outcome. The incident retains `is_follow_up_required` and the *next* `follow_up_date`.

> DDL v2 had a single `follow_up_notes TEXT`. The audit recorded that each new note overwrote the last. The history of what a school did about a child's behaviour is exactly the part that must not be overwritten.

---

# Part XII — Witnesses

## 46. Witness Records

**REQ-BA-015 — Witnesses.** A witness is a student or a staff member.

| Field | Rule |
|---|---|
| `witness_type` | `student` \| `staff` |
| `witness_id` | Polymorphic; validated at the application layer against the correct master |
| **`statement`** *(v3)* | The factual account, between the configured min and max (default 10–500) |
| `statement_recorded_by`, `statement_recorded_at` *(v3)* | Who took the statement and when |
| `is_confidential` *(v3)* | Restricts visibility further, to Principal and Counsellor only |
| `frozen_at` *(v3)* | Set when the case closes |

> DDL v2 declared witnesses but had **no column to hold a statement**, while BRD v2 §56 specified statement length limits and BRD v2 §58 specified who may read them. The requirement had no storage. It does now.

**BR-BA-019 — Elevated access.** Statement text is restricted to HOD, Counsellor and Principal roles. Reads are audited.

**BR-BA-075 (v3) — No self-witness.** The student who is the subject of an incident cannot be a witness to it.

**BR-BA-076 (v3) — No duplicate witness.** A person appears at most once per incident. Attempting to add them again updates the existing statement rather than failing.

**BR-BA-077 (v3) — Freeze on closure.** When `freeze_witness_on_closure` is enabled and the incident reaches `closed`, witness records become read-only. A statement that can be revised after a case concludes has no evidential value.

---

# Part XIII — Interventions as Cases *(C-02, D-01)*

## 47. Applied Intervention

**REQ-BA-016 (v3-rev) — An applied intervention is a tracked case.** One incident may carry several; each is independently owned and tracked.

| Field | Rule |
|---|---|
| `incident_id`, `intervention_id` | The what |
| `assigned_to` *(v3)* | Responsible staff member. Mandatory when the master sets `requires_owner` |
| `scheduled_date` *(v3)* | Due date. Defaults to incident date + the master's `default_due_days` |
| `status` *(v3)* | `assigned` → `in_progress` → `completed` \| `cancelled` |
| `started_at`, `completed_on` *(v3)* | Actual dates |
| `completion_notes` *(v3)* | Mandatory to complete |
| `cancellation_reason` *(v3)* | Mandatory to cancel |
| `outcome` *(v3)* | `effective` \| `partially_effective` \| `not_effective` \| `not_assessed` |
| `notes` | Context at assignment time |

## 48. Intervention Lifecycle

```
[ASSIGNED] ──▶ [IN_PROGRESS] ──▶ [COMPLETED]
     │                │
     └────────────────┴──────────▶ [CANCELLED]  (reason mandatory)
```

**BR-BA-078 (v3) — Completion requires evidence.** `completed` requires a completion date and a completion note.
**BR-BA-079 (v3) — Cancellation requires justification.** `cancelled` requires a reason.
**BR-BA-080 (v3) — Overdue is visible.** An intervention past its scheduled date and not completed is *overdue*, and appears on the owner's worklist, the dashboard alerts and the principal's digest.
**BR-BA-081 (v3) — Progress is append-only.** Progress notes accumulate with author and timestamp; none is overwritten.
**BR-BA-082 (v3) — Effectiveness is optional but prompted.** Outcome may be left `not_assessed`; the module asks for it at completion. Over time this makes "which interventions actually work in this school" answerable — see §28 ENH-BA-013.

> **Resolution of v2 §62/§103.** v2 identified this as "a significant business requirement to preserve and reconcile in the next schema revision", because the v1 screens described a full case-management workflow while the junction table stored only a note. v3 resolves it in favour of the business requirement.

---

# Part XIV — Notification and Escalation *(C-05, C-10)*

## 49. Triggers

| # | Trigger | Recipients |
|---|---|---|
| N-01 | Incident severity ≥ `parent_notification_threshold` | Per configured recipient flags |
| N-02 | A student reaches `incident_escalation_count` negative incidents within `incident_escalation_window_days` | Class teacher, HOD, Counsellor, Principal |
| N-03 | Severity `critical` | Principal immediately, regardless of threshold |
| N-04 | Assessment deadline approaching / passed | Owning teachers, then HOD |
| N-05 | Intervention overdue | Owner, then their supervisor |
| N-06 | Daily digest, when enabled | Principal |
| N-07 | Positive incident (opt-in) | Parents — recognition should travel as readily as reprimand |

## 50. Delivery Obligation

**REQ-BA-017 (v3-rev) — An auditable outbox.** When a trigger fires, BA writes a notification obligation: event, incident or entity reference, recipient role and identity, channel, payload, status (`pending` / `sent` / `failed` / `suppressed`), attempt count, sent timestamp and failure reason. The Notification module performs delivery and updates the record.

**BR-BA-013 (v3-rev) — Thresholds trigger obligations, not messages.** BA's responsibility ends at recording the obligation and its outcome.

**BR-BA-083 (v3) — A failed notification is a visible operational fact.** Failures appear on the Notification Outbox screen and can be retried. A parent alert that silently failed is worse than none, because the school believes the parent was told.

**BR-BA-084 (v3) — No duplicate alerts.** Re-saving an incident does not re-notify. Only a severity escalation (BR-BA-073) re-evaluates the threshold, and then only if the new severity crosses it and the previous notification did not.

> **Resolution of the audit's SEC-BA-001.** The finding was blunt: *"Severe-incident parent notification is entirely absent. `grep -rn "Notification|notify|dispatch|event(" app/` returns zero. `parent_notification_threshold` is dead config and `is_notified` is never written."* A boolean gave the requirement nowhere to live. An outbox with a status makes both the obligation and its failure impossible to lose.

---

# Part XV — Dashboard

**REQ-BA-018 — Role-aware dashboard.**

**KPI cards:** active period and days remaining · assessment completion % · incidents this week (positive / negative split) · open interventions, of which overdue · students currently at risk.

**Charts:** severity distribution · positive vs negative trend over the session · category averages for the cohort · incident hotspots by location.

**Alerts:** recent `major`/`critical` incidents · pending approvals ageing · overdue interventions · students crossing the escalation count · approaching deadlines · failed notifications.

**BR-BA-085 (v3) — Drill-down everywhere.** Every KPI and every chart segment links to the filtered list behind it.

**BR-BA-086 (v3) — Cached reads only.** The dashboard reads computed and cached data. Target: **p95 under 2 seconds** at 2,000 students.

---

# Part XVI — Reporting

## 51. Reports Hub

**RPT-BA-001…010** — Student Scores · Category Summary · Period Report · Audit Trail · Incident Summary · Student Report · Class Analysis · Period Progress · Category Performance · Incident Report.

Common filters: session · period · class · section · student · incident type · severity · date range · category.

**BR-BA-087 (v3) — Large exports run asynchronously.** Above `export_async_row_threshold` rows (default 1,000) the export is queued and the user is notified in-app when the file is ready. Export requests, their parameters, requester and outcome are recorded — an export of behavioural data is itself a disclosure event.

**BR-BA-020 — Anonymised variants.** Cohort reports offer an anonymised mode that suppresses names and identifiers, for staff-room discussion and board reporting.

## 52. Report Definitions

| ID | Report | Content |
|---|---|---|
| RPT-BA-001 | Student Scores | Roll no, admission no, name, category scores, overall, grade, teachers contributing |
| RPT-BA-002 | Category Summary | Students evaluated, category average, strongest and weakest criterion, distribution buckets |
| RPT-BA-003 | Period Report | Current vs previous period, `Δ = current − previous`, direction band |
| RPT-BA-004 | Audit Trail | Entity, field, old → new, actor, timestamp, IP |
| RPT-BA-005 | Incident Summary | Frequency, severity mix, category mix, top locations, resolution rate, average days to resolution |
| RPT-BA-006 | Student Report | Full dossier: identity, overall, category scores, criterion ratings, remarks, incidents both polarities, interventions and outcomes, trend |
| RPT-BA-007 | Class Analysis | Distribution, category heatmap, top performers, at-risk register, section comparison |
| RPT-BA-008 | Period Progress | Up to 5 category trend lines, intervention completion markers, severe-incident markers, start/end score, total delta |
| RPT-BA-009 | Category Performance | Mean, SD, distribution, teacher consistency, permitted demographic splits, academic correlation |
| RPT-BA-010 | Incident Report | Weekly frequency, severity and category distribution, top triggers, witness counts, intervention outcomes, detail grid |

**BR-BA-088 (v3) — Trend bands are configured, not constant.**

| Band | Default | Meaning |
|---|---|---|
| Improving | `Δ > +7.5%` of scale range | +0.30 on a 5-point scale |
| Stable | `|Δ| ≤ 5%` of scale range | ±0.20 on a 5-point scale |
| Declining | `Δ < −7.5%` of scale range | −0.30 on a 5-point scale |

**BR-BA-089 (v3) — At-risk is a configured composite.** A student is at risk when the overall score is below `at_risk_score_percent` of scale range (default 50%, i.e. 2.5/5) **or** they have at least `at_risk_incident_count` negative incidents in the active term (default 2).

**BR-BA-090 (v3) — Teacher consistency is advisory and private.** Grading-consistency analytics (SD above `consistency_sd_percent`) are visible to Principal and HOD only, are framed as a prompt for calibration, and are never surfaced on any teacher-facing or parent-facing screen. This is a professional-development instrument, not a performance metric.

**BR-BA-091 (v3) — Demographic analytics are opt-in and permissioned.** Only dimensions listed in `allowed_demographics_json` may be used, only Principal-level roles may run them, cells below a minimum group size are suppressed, and every run is audited.

> **Resolution of v2 §110.** Gender-wise and enrolment-type behavioural comparisons are legitimate for equity monitoring and dangerous as a default. Off unless deliberately enabled, restricted, and small-cell suppressed.

---

# Part XVII — Audit and Compliance

**REQ-BA-026 (v3) — Immutable audit trail.** Insert-only. No update path, no soft delete.

**Audited entities:** assessment ratings · assessments (status transitions and lock) · incidents (including severity escalation) · interventions (status transitions) · configuration changes · rating scale and framework master changes · period lifecycle actions · witness statement reads · report exports · demographic analytics runs.

> v2 §85 noted that the DDL audited three entity types while the screens expected configuration and lock activity to be discoverable. The entity list above is now the requirement.

**BR-BA-012 — Insert-only.** Enforced at the database level.

**BR-BA-092 (v3) — Every audit row carries actor, timestamp, IP and user agent.**

**BR-BA-093 (v3) — Retention is configured, archival is explicit.** Records older than `audit_retention_months` (default 36) may be archived by an explicit administrative action, never by an automatic purge. Archival is itself audited.

> **Resolution of v2 §87.** v2 proposed a 3-year prune and correctly flagged it as a policy decision. Resolved as: 36-month default, no silent deletion.

---

# Part XVIII — Privacy and Security

| Rule | Statement |
|---|---|
| BR-BA-094 (v3) | Behavioural records are sensitive student data. Access is by role **and** by relationship (own class, own child, own case) |
| BR-BA-095 (v3) | Sensitivity tiers, most to least restricted: witness statements → incident descriptions → intervention details → teacher remarks → scores → anonymised aggregates |
| BR-BA-032 | Parents see finalised information only |
| BR-BA-020 | Aggregate reports offer anonymisation |
| BR-BA-096 (v3) | Every export and every witness-statement read is logged as a disclosure event |
| BR-BA-097 (v3) | A student's behavioural record follows them across sessions and is never deleted while enrolled; on exit it is retained per school policy and excluded from operational reporting |

---

# Part XIX — Cross-Module Integration

| Module | Tables consumed | Direction | Notes |
|---|---|---|---|
| StudentProfile | `std_students` (INT UNSIGNED) | Read | Student, incident subject, student witness |
| SchoolSetup | `sch_employees` (INT UNSIGNED) | Read | Teacher, reviewer, reporter, intervention owner, staff witness |
| SchoolSetup | `sch_class_section_jnt` (INT UNSIGNED) | Read | Assessment scope |
| SchoolSetup | `sch_classes` (INT UNSIGNED) | Read | Category applicability |
| SchoolSetup | `sch_subjects` (INT UNSIGNED) | Read | Subject-teacher assessment scope *(v3)* |
| SchoolSetup | `sch_org_academic_sessions_jnt` (SMALLINT UNSIGNED) | Read | Session scoping |
| SchoolSetup | `sch_academic_term` (SMALLINT UNSIGNED) | Read | Optional period → term link |
| SystemConfig | `sys_users` (**INT UNSIGNED**) | Read | Actor on every row |
| LmsExam / Result | — | **Consumer** | Pulls finalised scores; BA writes nothing |
| Notification | — | **Consumer** | Delivers what BA's outbox obliges |
| Media storage | — | Read/Write refs | BA stores references only |

> **Type correction (v3).** DDL v2 declared `created_by` and `updated_by` as `BIGINT UNSIGNED` while `sys_users.id` is `INT UNSIGNED`. There is no foreign key today, so nothing fails loudly — the columns are simply four bytes wider than the values they hold and cannot be constrained. v7.0 corrects both to `INT UNSIGNED` and adds a real foreign key on `created_by`.

**BR-BA-017 — Module boundary.** BA never writes to any table outside `ba_*`.

---

# Part XX — Data Integrity

**BR-BA-098 (v3) — Deactivate, do not delete.** A master referenced by historical data may be deactivated. Physical deletion is blocked.

**BR-BA-030 (v3-rev) — Delete guards.** Blocked while dependents exist: a scale with ratings · a category with criteria carrying ratings · a criterion with ratings · a period with assessments · an intervention that has been applied · a rating level that has been selected.

**BR-BA-099 (v3) — Uniqueness survives soft deletion.** Every unique constraint remains enforced among live rows while permitting repeated soft-deleted rows with the same natural key.

> The audit logged 500-level failures where a soft-deleted row collided with a re-created one (DATA-BA-004). A naive `UNIQUE` over a soft-deleted table either blocks legitimate re-creation or, if `deleted_at` is added to the key, silently stops enforcing anything, because MySQL treats each NULL as distinct. The solution is specified in the solution design.

**Duplicates prevented:** scale levels within a scale (by order, by label, by value) · class-category mappings · teacher/class-section/period assessments · student/criterion ratings within an assessment · student remarks within an assessment · student/category/period computed scores · student/period overall scores · incident witnesses · incident interventions · incident numbers.

**BR-BA-100 (v3) — Historical integrity.** Changing a live master never alters the meaning of a locked assessment (§21).

---

# Part XXI — End-to-End Workflows

## W-1 — New Academic Session

```
Activate session → copy previous configuration → confirm rating scale
   → review categories & criteria → map categories to classes
   → review interventions & comment bank → set notification and escalation policy
   → create assessment periods → open the first period
```

## W-2 — Teacher Assessment

```
My Assessments → select class-section + period → grid loads applicable students × criteria
   → rate (auto-save every 30s) → add criterion remarks → add overall remarks (Comment Bank)
   → completeness check → Submit
        ├─ review required     → Submitted → Review Queue
        └─ review not required → Reviewed → (auto-lock if configured)
```

## W-3 — Review

```
Review Queue → open submission → quality signals shown → inspect
   ├─ Approve            → Reviewed → compute scores
   │      └─ auto_lock_on_approval → Locked
   └─ Send Back (remark) → Draft → teacher corrects → resubmit
```

## W-4 — Period Close

```
Deadline passes → chase incomplete teachers → close period
   → resolve outstanding reviews → compute all → lock period
        → cascade lock to assessments and ratings
        → take framework snapshot
        → publish to Result layer (if integration enabled)
```

## W-5 — Incident to Resolution

```
Event → log incident (type, severity, description, location, framework link)
   → attach evidence → add witnesses and statements
   → threshold check → notification obligation raised
   → assign intervention(s): owner + due date
   → progress notes → complete (notes + outcome) or cancel (reason)
   → follow-up entries
   → Resolved (all interventions closed out) → Closed (closure note)
```

## W-6 — Escalation

```
Negative incident logged
   → count this student's negative incidents in the rolling window
   → count >= incident_escalation_count
        → escalation notification to class teacher, HOD, counsellor, principal
        → student appears on the at-risk register
        → counsellor review recommended
```

---

# Part XXII — Business Rules Catalogue

**BR-BA-001…030** are carried forward from the FRD with their original numbers. Rules marked *(v3-rev)* have a decided meaning in this document; *(v3)* rules are new.

| ID | Rule |
|---|---|
| BR-BA-001 | Teachers rate only with configured rating levels |
| BR-BA-002 | Configuration is scoped to an academic session |
| BR-BA-003 | Only class-applicable categories appear in a grid |
| BR-BA-004 | No duplicate teacher × class-section × period assessment |
| BR-BA-005 | One rating per student × criterion × assessment |
| BR-BA-006 | Multi-teacher ratings are averaged |
| BR-BA-007 *(v3-rev)* | Negative categories normalise as `(max + min) − raw` |
| BR-BA-008 *(v3-rev)* | Incident core facts are immutable |
| BR-BA-009 *(v3-rev)* | Unmapped class ⇒ all active categories apply |
| BR-BA-010 | Locked assessments cannot be edited |
| BR-BA-011 | Parent surfaces show finalised data only |
| BR-BA-012 | The audit log is insert-only |
| BR-BA-013 *(v3-rev)* | Threshold breach raises a notification obligation |
| BR-BA-014 | Follow-up-required incidents expose follow-up tasks and dates |
| BR-BA-015 | Applied interventions are traceable through their lifecycle |
| BR-BA-016 | Deactivation preserves historical evidence |
| BR-BA-017 | BA writes nothing outside `ba_*` |
| BR-BA-018 | Heavy reporting uses cached data |
| BR-BA-019 | Witness statements require elevated authorisation |
| BR-BA-020 | Aggregate reports may be anonymised |
| BR-BA-021 | Scale levels are ordered and uniquely positioned |
| BR-BA-022 | Period dates must be coherent |
| BR-BA-023 | Result integration is off by default |
| BR-BA-024 | Weightage is 5–20% when integration is enabled |
| BR-BA-025 *(v3-rev)* | Review may be disabled per session; submit then publishes |
| BR-BA-026 | A scale has 2–10 levels |
| BR-BA-027 | Level values lie within the scale range |
| BR-BA-028 *(v3-rev)* | At most one default scale, enforced by the database |
| BR-BA-029 *(v3-rev)* | A scale in use is numerically frozen |
| BR-BA-030 *(v3-rev)* | Delete guards on all referenced masters |
| BR-BA-031 | Witness statement access is elevated and audited |
| BR-BA-032 | Parents never see draft or unapproved data |
| BR-BA-033 | Level label and value are unique within a scale |
| BR-BA-034 | Category hierarchy is at most two levels |
| BR-BA-035 | Criteria attach only to leaf categories |
| BR-BA-036 | Weights are proportional and normalised at computation |
| BR-BA-037 | Intervention type must match incident polarity |
| BR-BA-038 | Comment Bank text is a starting point, owned by the teacher |
| BR-BA-039 | Placeholders resolve to name and neutral pronouns by default |
| BR-BA-040 | Mapping changes are forward-only |
| BR-BA-041 | `end_date >= start_date`, `deadline >= end_date` |
| BR-BA-042 | Period names are unique within a session |
| BR-BA-043 | Overlapping periods are allowed but warned |
| BR-BA-044 | Period FSM: open ⇄ closed → locked; open → locked forbidden |
| BR-BA-045 | Period lock cascades to assessments and ratings |
| BR-BA-046 | Locked history is read through its framework snapshot |
| BR-BA-047 | Snapshots are immutable and versioned |
| BR-BA-048 | Analytical thresholds are percentages of scale range |
| BR-BA-049 | Only locked periods are integrable into results |
| BR-BA-050 | Assessment records its scope and subject |
| BR-BA-051 | Teacher eligibility resolved at creation, then held |
| BR-BA-052 | Assessment FSM transitions are enumerated and enforced |
| BR-BA-053 | Submission requires a complete grid |
| BR-BA-054 | Send-back preserves work; count is visible |
| BR-BA-055 | Draft auto-saves do not each create audit rows |
| BR-BA-056 | The grid is read-only when locked, closed or not owned |
| BR-BA-057 | A rating stores the numeric value it meant |
| BR-BA-058 | Approve and lock are distinct events |
| BR-BA-059 | Only reviewed or locked ratings are scored |
| BR-BA-060 | Unrated cells are excluded, never zeroed |
| BR-BA-061 | Below minimum coverage, a category reports insufficient data |
| BR-BA-062 | Grades derive from the active scale's level bands |
| BR-BA-063 | Every computation run is provenanced |
| BR-BA-064 | Locked periods recompute identically |
| BR-BA-065 | One canonical severity vocabulary; aliases are display-only |
| BR-BA-066 *(v3-rev)* | Negative requires severity; positive forbids it |
| BR-BA-067 | Major/critical resolution requires all interventions closed out |
| BR-BA-068 | Closure requires a closure note |
| BR-BA-069 | Positive incidents may close directly |
| BR-BA-070 | Backdating window is configured, override is audited |
| BR-BA-071 | Online, hostel, assembly and sports locations are supported |
| BR-BA-072 | Corrections happen by cancellation and re-raise |
| BR-BA-073 | Severity escalation is the one permitted core-field exception |
| BR-BA-074 | Attachment access follows incident access, staff-only on multi-student cases |
| BR-BA-075 | The subject student cannot witness their own incident |
| BR-BA-076 | One witness record per person per incident |
| BR-BA-077 | Witnesses freeze on closure when configured |
| BR-BA-078 | Completion requires date and notes |
| BR-BA-079 | Cancellation requires a reason |
| BR-BA-080 | Overdue interventions are surfaced |
| BR-BA-081 | Progress notes are append-only |
| BR-BA-082 | Effectiveness is prompted at completion, optional to record |
| BR-BA-083 | Failed notifications are visible and retryable |
| BR-BA-084 | No duplicate alerts; only escalation re-evaluates |
| BR-BA-085 | Every dashboard metric drills down |
| BR-BA-086 | Dashboard reads cached data; p95 < 2s |
| BR-BA-087 | Large exports are asynchronous and recorded |
| BR-BA-088 | Trend bands are configured percentages |
| BR-BA-089 | At-risk is a configured composite rule |
| BR-BA-090 | Teacher consistency analytics are advisory and restricted |
| BR-BA-091 | Demographic analytics are opt-in, restricted, small-cell suppressed |
| BR-BA-092 | Audit rows carry actor, time, IP and user agent |
| BR-BA-093 | Retention configured; archival explicit and audited |
| BR-BA-094 | Access is by role and by relationship |
| BR-BA-095 | Sensitivity tiers are defined and enforced |
| BR-BA-096 | Exports and statement reads are disclosure events |
| BR-BA-097 | Records persist across sessions; never deleted while enrolled |
| BR-BA-098 | Deactivate rather than delete |
| BR-BA-099 | Uniqueness holds among live rows despite soft deletion |
| BR-BA-100 | Live master changes never alter locked history |

---

# Part XXIII — Requirements Catalogue

| ID | Requirement | Priority |
|---|---|---|
| REQ-BA-001 | Configurable rating scales and levels | P0 |
| REQ-BA-002 | Behavioural categories and criteria | P0 |
| REQ-BA-003 | Intervention master | P0 |
| REQ-BA-004 | Class-to-category mapping | P0 |
| REQ-BA-005 | Assessment periods with lifecycle | P0 |
| REQ-BA-006 | Session configuration | P0 |
| REQ-BA-007 | Optional weighted result integration | P1 |
| REQ-BA-008 | Auto-saving rating grid | P0 |
| REQ-BA-009 | Student × criterion grid entry | P0 |
| REQ-BA-010 | Criterion and overall remarks | P0 |
| REQ-BA-011 | Review queue with approve / send back | P0 |
| REQ-BA-012 | Materialised score cache | P0 |
| REQ-BA-013 | Queued recomputation | P1 |
| REQ-BA-014 | Incident logging | P0 |
| REQ-BA-015 | Witnesses with statements | P1 |
| REQ-BA-016 *(v3-rev)* | Intervention case management | P0 |
| REQ-BA-017 *(v3-rev)* | Notification outbox with delivery status | P0 |
| REQ-BA-018 | Role-aware dashboard | P1 |
| REQ-BA-019 *(v3)* | Server-enforced visibility matrix | P0 |
| REQ-BA-020 *(v3)* | Comment Bank | P2 |
| REQ-BA-021 *(v3)* | Framework snapshot on period lock | P0 |
| REQ-BA-022 *(v3)* | Assessment status history | P1 |
| REQ-BA-023 *(v3)* | Reviewer quality signals | P2 |
| REQ-BA-024 *(v3)* | Relational incident attachments | P1 |
| REQ-BA-025 *(v3)* | Append-only follow-up log | P1 |
| REQ-BA-026 *(v3)* | Extended immutable audit trail | P0 |
| REQ-BA-027 *(v3)* | Recomputation provenance | P1 |
| REQ-BA-028 *(v3)* | Count-based escalation | P1 |
| REQ-BA-029 *(v3)* | Asynchronous export with disclosure record | P2 |
| REQ-BA-030 *(v3)* | Optional behaviour points ledger | P3 |

---

# Part XXIV — Decisions (resolving BRD v2 Part XXIII)

| # | Question from v2 | **Decision** | Rationale | Schema consequence |
|---|---|---|---|---|
| **D-01** | §103 Intervention lifecycle vs DDL | **Adopt the full case-management workflow.** Owner, due date, status, progress log, completion and cancellation evidence, outcome | An intervention nobody owns and nothing tracks is a checkbox, not a response. This is problem P-05, the module's stated reason for existing | `ba_incident_intervention_jnt` extended; `ba_intervention_progress` added |
| **D-02** | §104 One scale per session, or per class | **Session default, with an optional per-class override.** | A single scale suits most schools and keeps cross-class comparison meaningful. A Montessori-style 3-point scale for Grades 1–2 alongside a 5-point scale for Grades 6–12 is a real need. Making the override optional means the simple case stays simple | `ba_class_scale_jnt` added |
| **D-03** | §105 Approval vs locking | **Two distinct business events; one optional combined UI action** (`auto_lock_on_approval`) | Different accountability. "Who approved this?" and "who made it final?" must both be answerable | `approved_by/at` and `locked_by/at` separately on `ba_assessments`; config flag |
| **D-04** | Review mandatory? | **Configurable per session** (`is_review_required`) | BR-BA-025 already required it and was never built. Small schools have no HOD layer | Config flag; `submit()` branches |
| **D-05** | §106 Severity vocabulary | **`minor / moderate / major / critical` is canonical.** Info/Low/Medium/High are display aliases | Two vocabularies in one product guarantees mismatched thresholds and unusable exports | Enum unchanged; alias map documented, not stored |
| **D-06** | §107 Incident resolution lifecycle | **Yes — a six-state lifecycle** | Without it the module records the event and never records the response | `status`, `resolved_by/at`, `closure_notes` on `ba_incidents` |
| **D-07** | §108 Historical master versioning | **Yes — snapshot the framework at period lock, and store the numeric value on each rating** | A weight edited in March must not rewrite what a September report card meant | `ba_framework_snapshots`; `rating_value_snapshot` on ratings |
| **D-08** | §110 Demographic analytics | **Permitted, but opt-in, role-restricted, small-cell suppressed and audited** | Equity monitoring is legitimate; unrestricted demographic behavioural profiling is not | `allowed_demographics_json`; audit entity type |
| **D-09** | §109 May incidents affect scores | **No by default. Optional ledger, off unless a school enables it** | Two schools will want opposite answers. Keeping the periodic score clean by default preserves the distinction between measurement and event, while `ba_behaviour_points` gives the other school a defined, auditable mechanism instead of an ad-hoc one | `ba_behaviour_points` + `is_behaviour_points_enabled` |
| **D-10** | §16 Criteria weights total 100? | **Presentation convention, warn only. Storage is proportional** | The engine must never depend on administrators keeping a running total correct | No constraint; UI shows effective % |
| **D-11** | §15 Per-criterion max score | **Rejected.** The scale owns the range | Mixed ranges in one grid are unreadable and break averaging | Not added |
| **D-12** | §49 7-day backdating | **Default 7 days, configurable, with an audited administrative override** | A delayed disclosure must remain recordable | `incident_backdating_days` |
| **D-13** | §87 Audit retention | **36 months default; archival is an explicit, audited administrative action** | No silent deletion of a compliance record | `audit_retention_months`; archive table |
| **D-14** | Table prefix | **`ba_` is retained** | The live migrations, all 16 models and the v1 screen specs use `ba_`. Only the stale consolidated DDL doc says `bha_`, and the 2026-06-29 verification already ruled against it. Renaming 16 tables to satisfy a document would break working code | Prefix `ba_`; the `bha_` document should be retired. See §25.3 |

---

# Part XXV — Non-Functional Requirements

## 25.1 Performance

| ID | Requirement | Target |
|---|---|---|
| NFR-01 | Dashboard load | p95 < 2s at 2,000 students |
| NFR-02 | Rating grid load (40 students × 30 criteria) | p95 < 3s |
| NFR-03 | Auto-save round trip | < 500ms |
| NFR-04 | Report render up to 1,000 rows | p95 < 5s |
| NFR-05 | Exports above the threshold | Queued; user notified on completion |
| NFR-06 | School-wide recomputation, 2,000 students | Queued; < 10 minutes |
| NFR-07 | Student Report (full dossier) | p95 < 4s |

## 25.2 Volume (planning basis, per tenant per session)

| Entity | Estimate |
|---|---|
| Students | 2,000 |
| Criteria | 58 |
| Periods | 4 |
| Assessments | ~1,600 |
| **Ratings** | **~460,000** — the dominant table |
| Computed category scores | ~72,000 |
| Incidents | ~3,000 |
| Audit rows | ~500,000 |

**NFR-08 — Design for the ratings table.** At roughly half a million rows per session, `ba_assessment_ratings` governs the module's performance. Every reporting path must reach it through the computed cache, never directly.

## 25.3 Other

| ID | Requirement |
|---|---|
| NFR-09 | MySQL 8.0.16+ (CHECK constraints enforced); InnoDB; utf8mb4 / utf8mb4_unicode_ci |
| NFR-10 | Database-per-tenant. **No `tenant_id` column anywhere in `ba_*`** |
| NFR-11 | No cross-database foreign keys |
| NFR-12 | Every table carries `is_active`, `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at` — except the audit log, which is insert-only |
| NFR-13 | All screens usable on tablet; the rating grid is the priority target |
| NFR-14 | Full keyboard navigation in the rating grid |
| NFR-15 | Unrecoverable loss of in-progress grid work is unacceptable — auto-save plus local draft recovery |
| NFR-16 | All user-facing labels are translatable; criteria and category names are school-authored content |
| NFR-17 | **The `bha_`-prefixed consolidated DDL document is stale and must be retired** to prevent downstream audits chasing tables that do not exist |

---

# Part XXVI — Acceptance Criteria

The module is accepted when each of the following is demonstrable:

| # | Criterion | Verified by |
|---|---|---|
| AC-01 | A teacher completes a 40 × 30 grid with no data loss across a forced browser close | Manual + Dusk |
| AC-02 | A submission with any unrated applicable cell is rejected | Automated |
| AC-03 | Send-back preserves every rating and remark | Automated |
| AC-04 | With `is_review_required = 0`, submit yields `reviewed` | Automated |
| AC-05 | Locking a period sets every child assessment to `locked` and every rating becomes unwritable | Automated |
| AC-06 | Editing a locked assessment fails at the database level, not only in the UI | Automated |
| AC-07 | Recomputing a locked period reproduces byte-identical scores | Automated |
| AC-08 | A negative-category rating of 5 on a 1–5 scale yields a normalised 1 | Unit |
| AC-09 | The same rating on a 0–4 scale yields 0 (not 1) | Unit |
| AC-10 | A criterion rated by three teachers averages correctly and reports the teacher count | Unit |
| AC-11 | An unrated criterion changes neither numerator nor denominator | Unit |
| AC-12 | Deleting a rating level does not alter any locked score | Automated |
| AC-13 | Changing a category weight does not alter any locked period's report | Automated |
| AC-14 | A negative incident without severity is rejected by the database | Automated |
| AC-15 | A positive incident with severity is rejected by the database | Automated |
| AC-16 | Editing an incident's description after creation fails | Automated |
| AC-17 | Severity escalation succeeds, writes audit and re-evaluates notification | Automated |
| AC-18 | A `critical` incident produces a `pending` outbox row within one second | Automated |
| AC-19 | A failed notification appears on the outbox screen and can be retried | Manual |
| AC-20 | Re-saving an incident produces no second notification | Automated |
| AC-21 | A third negative incident within 30 days triggers escalation | Automated |
| AC-22 | A `major` incident cannot be resolved with an open intervention | Automated |
| AC-23 | Completing an intervention without notes fails | Automated |
| AC-24 | An overdue intervention appears on the owner's worklist | Manual |
| AC-25 | A class teacher cannot read a witness statement | Automated |
| AC-26 | Reading a witness statement writes an audit row | Automated |
| AC-27 | A parent sees no draft score anywhere | Manual + automated |
| AC-28 | Two scales cannot both be default | Automated |
| AC-29 | A scale's min/max cannot change once ratings exist | Automated |
| AC-30 | A soft-deleted mapping can be re-created with the same natural key | Automated |
| AC-31 | An audit row cannot be updated or deleted | Automated |
| AC-32 | A 1,500-row export is queued rather than rendered inline | Automated |
| AC-33 | Dashboard p95 < 2s with 2,000 students seeded | Load test |
| AC-34 | At-risk and trend thresholds behave equivalently on a 3-point and a 5-point scale | Unit |
| AC-35 | Result integration returns nothing for an unlocked period | Automated |

---

# Part XXVII — Traceability

| Capability | Data area | Key rules |
|---|---|---|
| Rating scales and levels | `ba_rating_scales`, `ba_rating_levels` | BR-026…029, 033 |
| Categories and criteria | `ba_categories`, `ba_criteria` | BR-034…036 |
| Class applicability | `ba_class_category_jnt` | BR-009, 040 |
| Per-class scale override | `ba_class_scale_jnt` *(v3)* | D-02 |
| Periods | `ba_assessment_periods` | BR-041…045 |
| Session configuration | `ba_config` | BR-002, 048 |
| Framework snapshot | `ba_framework_snapshots` *(v3)* | BR-046, 047, 100 |
| Assessments | `ba_assessments` | BR-004, 050…058 |
| Status history | `ba_assessment_status_history` *(v3)* | REQ-BA-022 |
| Ratings | `ba_assessment_ratings` | BR-005, 057, 059…061 |
| Remarks | `ba_student_remarks` | REQ-BA-010 |
| Comment Bank | `ba_comment_bank` *(v3)* | BR-038, 039 |
| Category scores | `ba_computed_scores` | BR-018, 062 |
| Overall scores | `ba_computed_overall` *(v3)* | BR-018, 064 |
| Computation provenance | `ba_score_runs` *(v3)* | BR-063, 064 |
| Incidents | `ba_incidents` | BR-008, 065…073 |
| Attachments | `ba_incident_attachments` *(v3)* | BR-074 |
| Follow-up log | `ba_incident_followups` *(v3)* | REQ-BA-025 |
| Witnesses | `ba_incident_witnesses_jnt` | BR-019, 031, 075…077 |
| Applied interventions | `ba_incident_intervention_jnt` | BR-078…082 |
| Intervention progress | `ba_intervention_progress` *(v3)* | BR-081 |
| Notifications | `ba_notifications` *(v3)* | BR-013, 083, 084 |
| Exports | `ba_report_exports` *(v3)* | BR-087, 096 |
| Behaviour points | `ba_behaviour_points` *(v3)* | D-09 |
| Audit | `ba_audit_log`, `ba_audit_log_archive` *(v3)* | BR-012, 092, 093 |

---

# Part XXVIII — Enhancements

> The sections above are the agreed baseline. This section is **advisory**: additional functionality worth considering, with an honest note on what each costs. Nothing here is required for v7.0 to be complete, and each item is separable. Ordered by my assessment of value-to-effort.

## Tier 1 — Recommend for the next release

### ENH-BA-001 — Repeat-behaviour escalation *(promoted into the baseline)*
Already adopted as REQ-BA-028. Recorded here for traceability with its original ID.

### ENH-BA-002 — Multi-channel, multi-recipient notification policy *(promoted into the baseline)*
Already adopted as REQ-BA-017. Recorded here for traceability.

### ENH-BA-005 — Behaviour Improvement Plan (BIP)
A named, time-boxed plan for a student who repeatedly crosses the at-risk line: goals expressed as target scores on specific criteria, a review cadence, an owner, participating staff, and parent acknowledgement. Each review records progress against goals and the plan closes as met, partially met or not met.

*Why:* This is what a school does after the third counselling referral, and today it lives in a Word document on a counsellor's laptop. It also turns the at-risk register from a list into a workflow.
*Cost:* Two tables and a screen. Moderate.
*Depends on:* intervention case management (D-01), at-risk register.

### ENH-BA-006 — Positive-recognition programme
Points, badges or house points awarded for positive incidents, with class and house leaderboards and a termly recognition report.

*Why:* The module currently makes it far easier to record what a child did wrong than what they did right. A behavioural system that only counts failures shapes a school culture that only notices failures. This is the cheapest way to correct that asymmetry.
*Cost:* Small — it reuses `ba_behaviour_points` (already in the schema, positive side) plus a leaderboard view.
*Caution:* Leaderboards must be opt-in per school and should be at class or house level, not individual ranking. Publicly ranking children by behaviour is a different, worse product.

### ENH-BA-007 — Parent acknowledgement
A parent notified about a `major` or `critical` incident can acknowledge it in the portal; the acknowledgement, its timestamp and any parent comment are stored against the incident.

*Why:* "We informed the parents" is currently unfalsifiable. An acknowledgement closes the loop and is the single most useful artefact in a disputed disciplinary case.
*Cost:* Small — three columns and a ParentPortal screen.

### ENH-BA-008 — Bulk and template-driven grid entry
"Apply this rating to the whole column", "copy last period's ratings as a starting point", and a saved per-teacher default pattern.

*Why:* A teacher facing 40 × 30 = 1,200 cells four times a year will otherwise find a way to make it fast that you did not design, and it will be worse than the one you did.
*Caution:* Copy-forward makes flat-line grading easier. Pair it with the reviewer quality signals (REQ-BA-023) and record on the assessment that copy-forward was used.

## Tier 2 — Strong candidates

### ENH-BA-009 — Weighted teacher opinion
Let a school weight the class teacher's ratings above subject teachers' in the multi-teacher average, configurably.

*Why:* A class teacher observes a child across the whole day; a subject teacher sees them for four periods a week. Averaging them equally is a defensible default but not obviously the right one.
*Cost:* One config field and a change to one query. The schema already carries assessment scope (BR-BA-050).

### ENH-BA-010 — Criterion-level trend
Trend analysis is currently at category and overall level. Criterion-level trend answers the question a parent actually asks: *"Is he still not bringing his books?"*
*Cost:* Reporting only; the data already exists.

### ENH-BA-011 — Incident pattern detection
Flag patterns rather than counts: same location repeatedly, same period of the day, same peer group, clustering after a specific trigger.

*Why:* Three incidents in the corridor between periods 3 and 4 is a supervision problem, not three student problems. This turns the module from a record of children into a diagnostic for the school.
*Cost:* Moderate — an analytical job plus a dashboard panel.

### ENH-BA-012 — Student self-assessment and peer feedback
The same criteria rated by the student themselves, shown alongside the teacher view.

*Why:* The gap between self-perception and observed behaviour is often the most useful thing in the entire dossier, and self-assessment is explicitly encouraged by CBSE's holistic-progress framing.
*Cost:* Moderate. Needs a separate assessment scope, careful visibility rules, and a decision on whether self-ratings ever affect the computed score (recommendation: never).
*Caution:* Peer rating of behaviour is a bullying vector. If implemented at all, it should be structured positive-only nomination, never numeric rating of a peer.

### ENH-BA-013 — Intervention effectiveness analytics
Aggregate the `outcome` field: which interventions, for which categories, at which severities, are followed by measurable improvement.

*Why:* Schools apply detention because they always have. After two sessions of data, this tells them whether it works in their school. The outcome field is already in the baseline schema, so this is pure analysis.
*Cost:* Low — reporting only.
*Caution:* Confounded by severity and by which students receive which intervention. Present as a prompt for discussion, never as a causal claim.

### ENH-BA-014 — Report-card narrative generation
Assemble a behavioural paragraph from category scores, notable incidents and the Comment Bank, for teacher review and editing.

*Why:* Report-card comment writing is one of the most disliked tasks in a school year.
*Caution:* It must be a draft the teacher owns and edits, never auto-published. A parent receiving a machine-written description of their child that no teacher read is a serious failure of trust.

## Tier 3 — Worth having, lower urgency

| ID | Enhancement | Note |
|---|---|---|
| ENH-BA-003 | Configurable grade-band labels per scale | Currently derived from levels; some boards want distinct report-card bands |
| ENH-BA-004 | Bulk import of categories and criteria from CSV | Useful during onboarding of a school with an existing framework |
| ENH-BA-015 | Mobile incident capture with photo | Log an incident from a phone in the corridor, when it happens and while it is accurate |
| ENH-BA-016 | Anonymous student reporting channel for bullying | High value, and needs its own safeguarding review before design |
| ENH-BA-017 | Framework templates by board (CBSE / ICSE / IB / State) | Ship credible starting frameworks rather than one generic set |
| ENH-BA-018 | Cohort benchmarking across sessions | "Is this year's Grade 7 harder than last year's, or is it this teacher?" |
| ENH-BA-019 | Attendance and academic correlation | Behavioural decline often trails attendance decline; the leading indicator is useful |
| ENH-BA-020 | PTM pack generation | One PDF per student for a parent evening, generated in bulk |
| ENH-BA-021 | Counsellor case notes with clinical confidentiality | **Needs a privacy and legal review first.** Clinical notes have a different confidentiality standard from disciplinary records and probably need separate storage, not a flag on an existing table |
| ENH-BA-022 | Behavioural certificates and conduct letters | Schools issue these for transfers and admissions; generating them from real data beats retyping |
| ENH-BA-023 | Configurable workflow beyond the fixed FSM | Only if several schools genuinely need different routes. Configurable workflow engines are expensive and are usually a way of avoiding a decision |
| ENH-BA-024 | Offline rating entry with sync | Real need in schools with unreliable connectivity; conflict resolution makes it costly |
| ENH-BA-025 | Predictive at-risk scoring | Technically feasible on this data. **Recommend deferring.** Predicting which children will misbehave, and acting on the prediction, is a decision a school should make deliberately and with its board — not one that arrives as a feature |

## Enhancements deliberately **not** recommended

| Idea | Why not |
|---|---|
| Publishing individual behaviour rankings to students or parents | Behavioural comparison between named children is harmful and invites disputes the school cannot win |
| Automatic disciplinary action on threshold breach | Consequences must involve human judgement. The system should raise the case, never impose the penalty |
| Making incidents affect the periodic score by default | Double-counts the same behaviour, and makes a measurement instrument react to reporting rate rather than to behaviour. Kept available but off (D-09) |
| Teacher performance metrics derived from grading consistency | Guarantees that teachers grade to the middle to avoid being flagged, which destroys the data. Consistency analytics stay advisory (BR-BA-090) |

---

**End of `Behavioural_Assess_BRD_v3.md`**
