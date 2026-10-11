# Prime-AI Behavioural Assessment Module — Solution Design

**Document ID:** BHA-SD-V2
**Version:** 2.0
**Status:** Draft for Technical Review
**Date:** 2026-09-05
**Module:** BehaviouralAssessment (`Modules\BehaviouralAssessment`)
**Stack:** Laravel 12 · PHP 8.3 · MySQL 8.0.16+ · stancl/tenancy v3.9 (database-per-tenant) · Blade + Alpine.js + AdminLTE

**Governed by:** `Behavioural_Assess_BRD_v3.md` (v3.0)
**Realised by:** `Behavioural_Assess_DDL_v7.0.sql` (v7.0)
**Supersedes:** the design content embedded in `LMS_BehaviouralAssess_DDL_v2.sql` headers and `BA_FeatureSpec.md`

---

## 0. Document Control

### 0.1 What this document is

BRD v3 decides **what the business needs**. This document decides **how the system works and how it is built**. The DDL decides **how the information is stored**.

Every business rule in BRD v3 is traced here to a component, a table and an enforcement point. Where a rule can be enforced in more than one place, this document says which place is authoritative and why.

### 0.2 The evidence this design is built on

This is not a greenfield design. Three inputs constrain it:

| Input | What it tells us |
|---|---|
| **The live module** — 16 models, 16 tenant migrations, 12 controllers, 17 policies, 65 views, 5 seeders, 1 service | What already works and must keep working |
| **`LMS_BehaviouralAssess_DDL_v2.sql`** — 16 tables, 6 layers | The schema we are evolving from |
| **The 2026-06-29 technical audit** — Health 57/100 Amber, 30 BRs assessed: 15 enforced, 6 partial, **9 missing** | Where the current design actually fails, with evidence |

The audit is the most important of the three, because it identifies a pattern rather than a list of bugs.

### 0.3 The pattern the audit revealed

> *"The lock guard checks `assessment.status === 'locked'`, but NO code ever sets that status. Period `lock()` updates only the period row. Net effect: 'locked' periods don't actually freeze ratings, and approved scores can be silently edited out of sync with the cache and the audit trail."* — BUG-BA-001

> *"Severe-incident parent notification is entirely absent. `grep -rn "Notification|notify|dispatch|event(" app/` returns zero. `parent_notification_threshold` is dead config and `is_notified` is never written."* — SEC-BA-001

Read together, these are not two coding oversights. They share a cause: **the schema expressed intent that it gave the application no way to keep.**

- A single `status` column on a period, with no relationship to the rows it was supposed to freeze, made the lock cascade something a developer had to remember. They did not.
- A single `is_notified BOOLEAN` on an incident, with no row representing the obligation, made notification something a developer had to remember. They did not.

The design principle that follows from this governs the whole document:

> **T-01 — If a rule matters, give it a row, a constraint or a trigger. A rule that lives only in a developer's memory of the spec will be missing from the code, and nothing will notice.**

### 0.4 Design tenets

| # | Tenet | Consequence |
|---|---|---|
| T-01 | Enforce structurally, not by convention | FSMs, immutability and lock cascade are database triggers, not code comments (§7) |
| T-02 | Append, never overwrite | Follow-ups, progress notes, status history and audit are insert-only (§6.3) |
| T-03 | A published number must be reproducible forever | Framework snapshots + per-rating value snapshots (§8) |
| T-04 | An obligation is a row, not a boolean | The notification outbox (§10) |
| T-05 | Read from the cache; compute in a job | No report touches `ba_assessment_ratings` (§9) |
| T-06 | Thresholds are policy, not constants | Every analytical threshold is a configured percentage of scale range (§11.4) |
| T-07 | Sensitive reads are events | Witness statements, exports and demographic runs are audited on read (§12) |
| T-08 | Advise, do not block, on matters of judgement | Reviewer quality signals prompt; they never prevent approval (§5.4) |

### 0.5 Table prefix

**`ba_`.** The live migrations, all 16 Eloquent models and the 24 v1 screen specs use `ba_`. Only `2-DDL_Tenant_Consolidated/BehaviouralAssess_DDL_v2.sql` uses `bha_`, and the 2026-06-29 verification already ruled that document stale. That file should be retired (NFR-17); it is the only artefact in the repository that would send an auditor looking for tables that do not exist.

---

## 1. Solution Overview

### 1.1 In one paragraph

The Behavioural Assessment module is a Laravel module inside the Prime-AI tenant application. Administrators define a behavioural framework — a rating scale, categories, criteria, weights and class applicability — and open an assessment period. Teachers fill a student × criterion grid that auto-saves; supervisors review, approve and lock. Locking freezes the assessments, the ratings and the framework itself, then a queued job computes and caches per-category and overall scores which the Exam/Result module pulls when asked. Independently of all this, staff log behavioural incidents with severity, location, evidence and witnesses; each incident runs a lifecycle to a documented resolution, carrying interventions that have an owner, a due date and an outcome. Crossing a severity or repeat-count threshold writes a notification obligation that the Notification module fulfils and that the school can see succeed or fail. Everything sensitive is audited, including reads.

### 1.2 Context

```
 ┌──────────────────────────────────────────────────────────────────────────────┐
 │                          PRIME-AI TENANT APPLICATION                         │
 │                                                                              │
 │   SchoolSetup    StudentProfile    Notification    LmsExam/Result   Media    │
 │       │                │                ▲               ▲            ▲       │
 │       │ read           │ read           │ obligation    │ pull       │ refs  │
 │       ▼                ▼                │               │            │       │
 │  ┌────────────────────────────────────────────────────────────────────────┐  │
 │  │                  BEHAVIOURAL ASSESSMENT MODULE  (ba_*)                 │  │
 │  │                                                                        │  │
 │  │   Framework      Assessment      Scoring       Incidents     Analytics │  │
 │  │   masters   ──▶  workflow   ──▶  engine   ◀──  & cases   ──▶ & reports │  │
 │  │                                                                        │  │
 │  │   Policies (17) · Services · Jobs (queued) · Events · Observers        │  │
 │  └────────────────────────────────────────────────────────────────────────┘  │
 │                              tenant_db  (one per school)                     │
 └──────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Boundaries

| Boundary | Rule |
|---|---|
| Writes | BA writes only to `ba_*`. Never to `sch_*`, `std_*`, `exm_*`, `sys_*` |
| Result integration | **Pull.** `BehaviouralScoreService::getBulkScores()` is called by Result; BA never pushes |
| Notification | BA writes the obligation to `ba_notifications`; the Notification module delivers and updates status |
| Media | BA stores media references; bytes live in Prime-AI media storage |
| Tenancy | Database-per-tenant. **No `tenant_id` column in any `ba_*` table.** No cross-database FK |

---

## 2. Architecture

### 2.1 Layers

```
   HTTP  ──▶  Controllers (thin)  ──▶  Services (all business logic)  ──▶  Models  ──▶  MySQL
                     │                        │                                        │
              FormRequests               Jobs / Events                          Triggers, CHECKs,
              (validation)              (async work)                            FKs, UNIQUEs
                     │                        │                                        │
                 Policies                 Listeners                              (last line of
              (authorisation)          (Notification, Audit)                       defence)
```

**The controller layer is thin by rule.** The audit flagged fat-controller risk: 12 controllers, 1 service, and audit logging written inline in controllers. Every behavioural rule in this design lives in a service; a controller resolves the request, calls one service method, and returns a response.

### 2.2 Service inventory

| Service | Responsibility | Replaces |
|---|---|---|
| `BaFrameworkService` | Scales, levels, categories, criteria, class mapping, class-scale override. Enforces in-use immutability | inline controller logic |
| `BaConfigService` | Session configuration; copy-forward from previous session; resolves effective policy values | inline |
| `BaPeriodService` | Period FSM; **lock cascade**; snapshot capture | inline |
| `BaAssessmentService` | Create, autosave, completeness check, FSM transitions, send-back | inline |
| `BaRatingService` | Grid load, bulk upsert, value snapshot, editability guard | inline |
| `BehaviouralScoreService` | Computation pipeline, grade mapping, cache upsert, `getBulkScores()` | **existing — retained, extended** |
| `BaIncidentService` | Incident creation, immutability guard, lifecycle FSM, severity escalation | inline |
| `BaWitnessService` | Witness records, statement access control, freeze | inline |
| `BaInterventionService` | Assignment, progress, completion, cancellation, overdue detection | inline |
| `BaNotificationService` | Threshold and escalation evaluation, obligation writing, retry | **absent today** |
| `BaAuditService` | Structured audit writes, including read events | inline (unstructured) |
| `BaReportService` | Report queries; sync vs async routing; anonymisation | inline |
| `BaDashboardService` | KPI assembly from cached data only | inline |
| `BaCommentBankService` | Template retrieval, placeholder substitution | new |

### 2.3 Jobs

| Job | Trigger | Why queued |
|---|---|---|
| `ComputeStudentScoresJob` | Assessment approved | Isolates a slow path from the reviewer's request |
| `ComputeSchoolScoresJob` | Period lock, or admin recompute | 2,000 students × 58 criteria will time out in-request. The audit flagged synchronous recompute as a P1 |
| `CaptureFrameworkSnapshotJob` | Period lock (runs before compute) | Snapshot must be sealed before any score references it |
| `DispatchNotificationJob` | Outbox row created | Delivery is an external call and must be retryable |
| `EscalationCheckJob` | Negative incident created | Windowed count over incident history |
| `GenerateReportExportJob` | Export above threshold | BR-BA-087 |
| `ArchiveAuditLogJob` | Explicit admin action only | Never scheduled — BR-BA-093 forbids silent purge |
| `OverdueInterventionSweepJob` | Nightly | Produces overdue notifications and dashboard state |

### 2.4 Events and listeners

| Event | Listeners |
|---|---|
| `AssessmentSubmitted` | Notify reviewer · write status history |
| `AssessmentApproved` | `ComputeStudentScoresJob` · status history · audit |
| `AssessmentSentBack` | Notify teacher · status history · audit |
| `PeriodLocked` | `CaptureFrameworkSnapshotJob` → `ComputeSchoolScoresJob` · audit |
| `IncidentCreated` | `BaNotificationService::evaluate()` · `EscalationCheckJob` · audit |
| `IncidentSeverityEscalated` | Re-evaluate notification · audit |
| `InterventionAssigned` | Notify owner · audit |
| `InterventionOverdue` | Notify owner and supervisor |
| `WitnessStatementRead` | Audit (read event) |
| `ReportExported` | Audit (disclosure event) |

> Today `EventServiceProvider::$listen` is empty and no event is dispatched anywhere. This table is the wiring that has to exist for BR-BA-013, BR-BA-045 and REQ-BA-013 to be true.

### 2.5 Authorisation

The 17 existing policies are retained and extended. Two additions are structural:

1. **Relationship checks, not just role checks.** `BaAssessmentPolicy::update()` must verify the actor *owns* the assessment, not merely that they are a teacher. BR-BA-094 requires role **and** relationship.
2. **Field-level gates.** Witness statement text is gated by `BaWitnessPolicy::viewStatement()`, separate from `view()`. A class teacher may see that there were three witnesses and may not see what they said.

---

## 3. The Data Model

### 3.1 Table inventory — 16 → 29

| Layer | Tables | New in v7.0 |
|---|---|---|
| **1 — Foundation** | `ba_rating_scales` · `ba_categories` · `ba_interventions` · `ba_comment_bank` | `ba_comment_bank` |
| **2 — Master detail** | `ba_rating_levels` · `ba_criteria` | — |
| **3 — Setup** | `ba_class_category_jnt` · `ba_class_scale_jnt` · `ba_assessment_periods` · `ba_config` · `ba_framework_snapshots` | `ba_class_scale_jnt`, `ba_framework_snapshots` |
| **4 — Workflow headers** | `ba_assessments` · `ba_assessment_status_history` · `ba_audit_log` · `ba_audit_log_archive` | `ba_assessment_status_history`, `ba_audit_log_archive` |
| **5 — Core transactions** | `ba_assessment_ratings` · `ba_student_remarks` · `ba_computed_scores` · `ba_computed_overall` · `ba_score_runs` · `ba_incidents` | `ba_computed_overall`, `ba_score_runs` |
| **6 — Incident detail** | `ba_incident_witnesses_jnt` · `ba_incident_intervention_jnt` · `ba_incident_attachments` · `ba_incident_followups` · `ba_intervention_progress` | `ba_incident_attachments`, `ba_incident_followups`, `ba_intervention_progress` |
| **7 — Operations** | `ba_notifications` · `ba_report_exports` · `ba_behaviour_points` | all three |

**29 tables. 13 new, 16 evolved, 0 removed.** No table from v2 is dropped, so migration is additive.

### 3.2 Why each new table exists

| Table | Exists because |
|---|---|
| `ba_comment_bank` | BRD v2 §32 described the Comment Bank with no storage anywhere |
| `ba_class_scale_jnt` | D-02 — a per-class scale override without duplicating configuration |
| `ba_framework_snapshots` | D-07 — BRD v2 §98 called historical integrity "one of the most important requirements" and it had no mechanism |
| `ba_assessment_status_history` | REQ-BA-022 — the field-level audit log answers "what changed"; this answers "who moved this, when, why" |
| `ba_computed_overall` | v2 stored the overall on "the first category row", which depends on row order and breaks when a category is deactivated |
| `ba_score_runs` | BR-BA-063 — a score that cannot state its provenance cannot be defended to a parent |
| `ba_incident_attachments` | REQ-BA-024 — `attachments_json` cannot be indexed, counted or permission-checked per file |
| `ba_incident_followups` | REQ-BA-025 — the audit found a single TEXT column being overwritten with each new note |
| `ba_intervention_progress` | BR-BA-081 — progress must accumulate |
| `ba_notifications` | REQ-BA-017 — a boolean cannot represent a failed delivery, so failures were invisible |
| `ba_report_exports` | BR-BA-087 and BR-BA-096 — an export of behavioural data is a disclosure event |
| `ba_behaviour_points` | D-09 — a defined, auditable mechanism for schools that want incidents to count, off by default |
| `ba_audit_log_archive` | BR-BA-093 — archival without deletion |

### 3.3 Corrections to existing tables

| Table | Correction | Why |
|---|---|---|
| **all** | `created_by` / `updated_by`: `BIGINT UNSIGNED` → **`INT UNSIGNED`**; a real FK to `sys_users` is added on `created_by` (not on `updated_by`, which would double the index count across 29 tables for no query benefit; `ba_audit_log` is exempted for the same reason at 500k rows/session) | `sys_users.id` is `INT UNSIGNED`. The columns were four bytes wider than the values they held and could not be constrained |
| **all** | `deleted_at` → `TIMESTAMP(6)`, plus a generated `uq_guard` column in every soft-delete-sensitive UNIQUE key | §3.4 |
| `ba_rating_scales` | `is_default_flag` generated column with a UNIQUE key | BR-BA-028 — multiple defaults were possible |
| `ba_rating_scales` | `is_locked`, `locked_at` | BR-BA-029 — freeze numeric shape once in use |
| `ba_categories` | `code`; `depth` guard | BR-BA-034 |
| `ba_criteria` | `code` unique within category | v1 screen spec asked for it |
| `ba_interventions` | `code`, `default_due_days`, `requires_owner`, `requires_parent_meeting` | D-01 |
| `ba_assessment_periods` | CHECK on date coherence; FSM trigger; `closed_by/at`, `locked_by/at`, `snapshot_id` | BR-BA-041, BR-BA-044, BR-BA-045 |
| `ba_config` | 5 settings → ~35, grouped by policy area | BRD §22 |
| `ba_assessments` | `assessment_scope`, `subject_id`, `submitted_by`, `approved_by/at`, `locked_by/at`, `sent_back_count`, `last_autosaved_at`, `completion_percent`, `snapshot_id` | D-03, BR-BA-050, BR-BA-054 |
| `ba_assessment_ratings` | `rating_value` snapshot; lock trigger | BR-BA-057, BR-BA-045 |
| `ba_incidents` | `incident_no`, `status`, `resolved_by/at`, `closure_notes`, `cancellation_reason`, 4 new locations, immutability trigger, severity CHECK | D-06, BR-BA-066, BR-BA-071 |
| `ba_incident_witnesses_jnt` | **`statement`**, `statement_recorded_by/at`, `is_confidential`, `frozen_at` | The requirement had no column at all |
| `ba_incident_intervention_jnt` | `assigned_to`, `scheduled_date`, `status`, `started_at`, `completed_on`, `completion_notes`, `cancellation_reason`, `outcome` | D-01 |
| `ba_audit_log` | Entity type extended to 10 values; `ip_address`, `user_agent`, `reason` | REQ-BA-026, BR-BA-092 |

### 3.4 Soft deletion and uniqueness — the pattern

This deserves its own section because getting it wrong produced real 500s in production (DATA-BA-004) and because the two obvious fixes are both wrong.

**The problem.** A class-category mapping is soft-deleted. The administrator re-creates it. `UNIQUE(class_id, category_id)` rejects the insert, because the soft-deleted row is still physically present.

**Wrong fix 1 — add `deleted_at` to the key.** `UNIQUE(class_id, category_id, deleted_at)`. MySQL treats every `NULL` as distinct in a unique index, so *every live row becomes unique regardless of its natural key.* The constraint silently stops enforcing anything. This is worse than the bug, because nothing fails.

**Wrong fix 2 — drop the constraint and check in code.** Two concurrent requests both pass the check and both insert.

**The pattern used throughout v7.0:**

```sql
`deleted_at`  TIMESTAMP(6) NULL DEFAULT NULL,
`uq_guard`    TIMESTAMP(6) GENERATED ALWAYS AS
                (IFNULL(`deleted_at`, '1970-01-01 00:00:00.000000')) STORED,
UNIQUE KEY `uq_ba_class_cat` (`class_id`, `category_id`, `uq_guard`)
```

Every live row carries the same sentinel, so the natural key is enforced among live rows exactly as intended. Every deleted row carries its own deletion instant, so any number of deleted rows may share the natural key.

`TIMESTAMP(6)` rather than `TIMESTAMP` is deliberate: at second precision, two soft-deletes of the same natural key within the same second would collide. Microsecond precision removes the case entirely. This is applied to **all** `ba_*` tables, not only the ones with unique keys, so the module is internally consistent and a developer never has to check which convention a given table follows.

### 3.5 Key type discipline

Cross-module identifiers must match the tables they reference. Verified against the tenant DDL:

| Referenced | Type | Used in BA as |
|---|---|---|
| `std_students.id` | `INT UNSIGNED` | `student_id`, `witness_id` (student) |
| `sch_employees.id` | `INT UNSIGNED` | `teacher_id`, `reviewed_by`, `reported_by`, `assigned_to`, `witness_id` (staff) |
| `sch_class_section_jnt.id` | `INT UNSIGNED` | `class_section_id` |
| `sch_classes.id` | `INT UNSIGNED` | `class_id` |
| `sch_subjects.id` | `INT UNSIGNED` | `subject_id` |
| `sch_org_academic_sessions_jnt.id` | `SMALLINT UNSIGNED` | `academic_session_id` |
| `sch_academic_term.id` | `SMALLINT UNSIGNED` | `academic_term_id` |
| **`sys_users.id`** | **`INT UNSIGNED`** | `created_by`, `updated_by`, `changed_by` — **was `BIGINT` in v2** |

`ba_*` primary keys stay `BIGINT UNSIGNED` — `ba_assessment_ratings` alone reaches ~460,000 rows per session, and a multi-year tenant will pass the `INT` range on audit rows.

---

## 4. The Framework and Its History

### 4.1 Resolving the applicable framework

```
resolveFramework(class_id, period_id):
    if period.status == 'locked':
        return snapshot(period.snapshot_id)          # BR-BA-046 — history reads its snapshot
    scale  := ba_class_scale_jnt[class_id] ?? ba_config[period.session].rating_scale_id
    cats   := ba_class_category_jnt[class_id] where is_active
    if cats is empty: cats := all active categories  # BR-BA-009 — permissive fallback
    return { scale, levels(scale), cats, criteria(cats) where is_active }
```

Two rules are load-bearing here. The **permissive fallback** is what stops an unconfigured school seeing an empty grid — the audit found it missing. The **snapshot branch** is what stops last night's weight edit from rewriting last September's report card.

### 4.2 The snapshot

Captured by `CaptureFrameworkSnapshotJob` at period lock, before any score is computed.

| Field | Content |
|---|---|
| `period_id` | The period frozen |
| `version` | 1 for the first lock; incremented on re-lock after a reopen |
| `scale_json` | Scale attributes and every level with label, value and order |
| `categories_json` | Every applicable category: id, code, name, polarity, weight, parent |
| `criteria_json` | Every applicable criterion: id, code, name, weight, category |
| `class_map_json` | The class → category mapping in force |
| `config_json` | Aggregation method, normalisation base, integration settings |
| `checksum` | SHA-256 over the canonical JSON |

The **checksum** exists so that BR-BA-064 is testable: recompute a locked period, and if the snapshot checksum differs from the one the score run recorded, the discrepancy is reported rather than silently written.

The snapshot has no update path. `ba_framework_snapshots` carries no `updated_at` and no `deleted_at`, and a trigger rejects `UPDATE` and `DELETE`.

### 4.3 In-use immutability

A scale becomes locked (`is_locked = 1`) the first time a rating references one of its levels. From then on `min_rating`, `max_rating` and every level `numeric_value` are frozen; labels and descriptions remain editable, because renaming "Good" to "Meets Expectations" changes no arithmetic.

This is enforced by trigger, not by service code. It is exactly the class of rule (BR-BA-029, found unenforced) that a developer forgets on the third screen that touches the table.

---

## 5. The Assessment Workflow

### 5.1 Period state machine

| From | To | Action | Guard |
|---|---|---|---|
| open | closed | `close()` | Admin/Principal |
| closed | open | `reopen()` | Admin/Principal; audited with reason |
| closed | locked | `lock()` | Admin/Principal; all assessments reviewed or locked |
| open | locked | — | **Rejected** |
| locked | * | — | **Rejected — terminal** |

Enforced by `trg_ba_period_status_bu`, which raises `SIGNAL SQLSTATE '45000'` on any transition not in this table. Service code performs the same check first, so users get a clean message; the trigger exists so that a background job, a console command, a data fix or a future developer cannot bypass it.

### 5.2 The lock cascade

```
BaPeriodService::lock(period):
    assert period.status == 'closed'
    assert no assessment in ('draft','submitted')        # nothing half-done gets frozen
    transaction:
        snapshot := CaptureFrameworkSnapshot(period)     # sealed first
        period.snapshot_id := snapshot.id
        UPDATE ba_assessments
           SET status='locked', locked_at=NOW(), locked_by=:actor, snapshot_id=:snapshot
         WHERE period_id=:period AND status='reviewed'
        period.status := 'locked'
        audit(period, 'status', 'closed', 'locked')
    dispatch ComputeSchoolScoresJob(period)
```

Ratings need no update: `trg_ba_rating_biu` reads the parent assessment's status and rejects any write when it is `locked`, or when the period is `closed` or `locked`. **The lock is enforced where the write happens, not where the lock is set.** That is the difference between this design and the one the audit found broken.

### 5.3 Assessment state machine

| From | To | Action | Guard |
|---|---|---|---|
| draft | submitted | `submit()` | Owner; grid complete (BR-BA-053); period open; `is_review_required = 1` |
| draft | reviewed | `submit()` | Same, but `is_review_required = 0` (BR-BA-025) |
| submitted | reviewed | `approve()` | Reviewer role |
| submitted | draft | `sendBack()` | Reviewer; remark mandatory |
| reviewed | draft | `sendBack()` | Principal only; remark mandatory; audited |
| reviewed | locked | `lock()` | Principal, period lock, or `auto_lock_on_approval` |
| locked | * | — | **Rejected** |

Every transition writes `ba_assessment_status_history` — from, to, actor, timestamp, remark. `sendBack()` increments `sent_back_count`.

### 5.4 Reviewer quality signals

Computed on demand when a submission is opened, from the cohort's other submissions in the same period. All five are advisory (T-08).

| Signal | Computation |
|---|---|
| Flat-line | `stddev(rating_value) < 0.15 × scale_range` across the whole grid |
| Cohort outlier | `abs(this_teacher_mean − other_teachers_mean) > 0.20 × scale_range` for the same students |
| Score/remark mismatch | Rating in the bottom band with a remark whose sentiment classifies positive, or the reverse |
| Missing explanation | A rating at either extreme with no criterion remark |
| Late | `submitted_at > period.deadline` |

### 5.5 The rating grid

**Load** (`BaRatingService::loadGrid`): one query for the roster, one for the framework, one for existing ratings keyed `student_id:criterion_id`. Three queries regardless of grid size — never one per cell.

**Save**: batched `INSERT … ON DUPLICATE KEY UPDATE` against `UNIQUE(assessment_id, student_id, criterion_id)`, sending only dirty cells. Each row carries `rating_level_id` **and** `rating_value` resolved at save time (BR-BA-057).

**Auto-save**: every `autosave_interval_seconds` (default 30) and on cell blur. Draft auto-saves write no audit rows (BR-BA-055) — auditing them would bury the changes that matter under thousands that do not. The audit trail begins at submit.

**Completion**: `completion_percent` is maintained on the assessment header on each save, so "My Assessments" and the dashboard read a number instead of counting cells.

---

## 6. Incidents and Cases

### 6.1 Incident lifecycle

```
[OPEN] ──▶ [UNDER_REVIEW] ──▶ [ACTION_TAKEN] ──▶ [RESOLVED] ──▶ [CLOSED]
   └──────────────┴──────────────────┴────────────────┴──────────▶ [CANCELLED]
```

Guards, enforced in `BaIncidentService` and mirrored in `trg_ba_incident_bu`:

- `→ resolved` requires, for `major` and `critical`, that every linked intervention is `completed` or `cancelled` (BR-BA-067).
- `→ closed` requires a closure note (BR-BA-068).
- `→ cancelled` requires a cancellation reason (BR-BA-072).
- A positive incident may go `open → closed` directly (BR-BA-069).

### 6.2 Immutability and its one exception

`trg_ba_incident_bu` rejects any change to `student_id`, `incident_date`, `incident_type`, `description` or `location` once the row exists.

`severity` is the exception. Investigation frequently reveals that an incident logged as `moderate` was in fact `major`, and forcing a cancel-and-re-raise there would destroy the witness statements and interventions already attached. So severity may be escalated — never reduced — by an Admin or Principal, with a reason, an audit row carrying old and new values, and a re-evaluation of the notification threshold (BR-BA-073, BR-BA-084).

The trigger permits the column to change; the service enforces who may do it and that the new value is higher.

### 6.3 Append-only sub-records

Three child tables replace what were overwritable text columns:

| Table | Replaces | Rule |
|---|---|---|
| `ba_incident_followups` | `follow_up_notes TEXT` | Insert-only. The incident keeps `is_follow_up_required` and the *next* `follow_up_date` |
| `ba_intervention_progress` | nothing — progress had nowhere to live | Insert-only, authored and timestamped |
| `ba_assessment_status_history` | nothing | Insert-only |

Each is protected by an `UPDATE`/`DELETE` rejecting trigger. The audit's BUG-BA-009 was precisely that each new follow-up note overwrote the last — the history of what a school did about a child is the part that must survive.

### 6.4 Interventions as cases

```
[ASSIGNED] ──▶ [IN_PROGRESS] ──▶ [COMPLETED]      (completion_notes + completed_on required)
     └──────────────┴──────────▶ [CANCELLED]      (cancellation_reason required)
```

`scheduled_date` defaults to `incident_date + interventions.default_due_days`. `assigned_to` is mandatory when the master sets `requires_owner`.

**Overdue** is derived, not stored: `status IN ('assigned','in_progress') AND scheduled_date < CURDATE()`. `v_ba_open_interventions` exposes it and `OverdueInterventionSweepJob` notifies on it nightly. Storing an `is_overdue` flag would require a job to keep it true, and a flag that depends on a job is a flag that will be wrong.

### 6.5 Witness statements

Statement text is the module's most sensitive field. Three controls:

1. **Access** — `BaWitnessPolicy::viewStatement()`, separate from `view()`. HOD, Counsellor, Principal only. `is_confidential = 1` narrows it further to Principal and Counsellor.
2. **Read auditing** — every statement read writes `ba_audit_log` with `entity_type = 'witness_read'`. A disclosure that nobody can reconstruct is not a controlled disclosure.
3. **Freeze** — when the incident reaches `closed` and `freeze_witness_on_closure` is on, `frozen_at` is set and the trigger rejects further writes. A statement editable after the case concludes has no evidential value.

---

## 7. Database-Level Enforcement

### 7.1 Why triggers

Application-layer enforcement failed for nine of thirty business rules. The failures were not incompetence; they were the predictable result of a schema that let a rule be forgotten. Rules that are **invariants of the data** rather than decisions about a workflow belong in the database, where a console command, a queued job, a seeder, a data-fix script and a future developer are all equally bound.

The division used throughout:

| Enforce in | Kind of rule | Example |
|---|---|---|
| **Database** (CHECK / UNIQUE / FK / trigger) | Invariants — never true, regardless of who is asking | Negative incidents have severity; locked assessments do not change; audit rows are not updated |
| **Service** | Workflow and permission — depends on actor, config and context | Who may reopen a period; whether review is required; whether a grid is complete |
| **FormRequest** | Shape and range of input | Description length; date not in the future |
| **Policy** | Authorisation | Who may read a witness statement |

Service checks run first so users see clean messages. Database checks are the backstop, not the user experience.

### 7.2 CHECK constraints (MySQL 8.0.16+)

| Table | Constraint |
|---|---|
| `ba_rating_scales` | `max_rating > min_rating`; `min_rating >= 0` |
| `ba_rating_levels` | `numeric_value >= 0` (range against the parent scale is a trigger — CHECK cannot read another row) |
| `ba_categories`, `ba_criteria` | `weight BETWEEN 0 AND 100` |
| `ba_assessment_periods` | `end_date >= start_date`; `deadline >= end_date` |
| `ba_config` | `weightage_percent BETWEEN 0 AND 100`; `is_result_integration_enabled = 0 OR weightage_percent BETWEEN 5 AND 20`; every percentage threshold `BETWEEN 0 AND 100`; `incident_escalation_count >= 1` |
| `ba_incidents` | **severity parity** — negative requires severity, positive forbids it; `closure_notes` required when `status = 'closed'`; `cancellation_reason` required when `status = 'cancelled'` |
| `ba_incident_intervention_jnt` | `completed` requires `completed_on` **and** `completion_notes`; `cancelled` requires `cancellation_reason`; `completed_on >= scheduled_date - 365` sanity bound |
| `ba_incident_witnesses_jnt` | statement length within 10–500 when present |
| `ba_computed_scores` | `numeric_score >= 0` |
| `ba_behaviour_points` | `points <> 0` |

### 7.3 Triggers

| Trigger | Enforces | BRD rule |
|---|---|---|
| `trg_ba_scale_default_bi/bu` | (generated `is_default_flag` + UNIQUE does this declaratively) | BR-BA-028 |
| `trg_ba_scale_locked_bu` | Numeric shape frozen once in use | BR-BA-029 |
| `trg_ba_level_range_bi/bu` | `numeric_value` within the parent scale's range | BR-BA-027 |
| `trg_ba_period_status_bu` | Period FSM legality | BR-BA-044 |
| `trg_ba_assessment_status_bu` | Assessment FSM legality; locked is terminal | BR-BA-052, BR-BA-010 |
| `trg_ba_rating_bi` / `trg_ba_rating_bu` / `trg_ba_rating_bd` | No write when the assessment is locked or the period is closed/locked | **BR-BA-045, BUG-BA-001** |
| `trg_ba_remark_bu` | Same guard for student remarks | BR-BA-045 |
| `trg_ba_incident_bu` | Core-field immutability; severity may only escalate | BR-BA-008, BR-BA-073 |
| `trg_ba_witness_bu` | Frozen witnesses reject writes | BR-BA-077 |
| `trg_ba_audit_bu` / `trg_ba_audit_bd` | Audit log is insert-only | BR-BA-012 |
| `trg_ba_snapshot_bu` / `trg_ba_snapshot_bd` | Snapshots are immutable | BR-BA-047 |
| `trg_ba_followup_bu/bd`, `trg_ba_progress_bu/bd`, `trg_ba_status_hist_bu/bd` | Append-only logs | BR-BA-081 |
| `trg_ba_incident_no_bi` | Generates `INC-YYYY-NNNNNN` if not supplied | BR-BA §42 |

All triggers raise `SIGNAL SQLSTATE '45000'` with a message prefixed `BA:` so the application can map them to user-facing text.

**They are isolated in Section 20 of the DDL.** A deployment that prefers application-only enforcement can omit that section; the tables, keys and CHECKs remain valid. The recommendation is to keep them, on the evidence of what happened without them.

### 7.4 Indexing

| Table | Index | Serves |
|---|---|---|
| `ba_assessment_ratings` | `(assessment_id, student_id, criterion_id)` UNIQUE | Grid upsert |
| | `(student_id, criterion_id)` | Multi-teacher averaging |
| | `(criterion_id, rating_value)` | Category performance analytics |
| `ba_assessments` | `(period_id, status)` | Review queue |
| | `(teacher_id, period_id)` | My Assessments |
| `ba_computed_scores` | `(student_id, period_id)` UNIQUE-prefix | Student report |
| | `(period_id, category_id)` | Category summary |
| `ba_computed_overall` | `(period_id, overall_score)` | Class ranking, at-risk |
| `ba_incidents` | `(student_id, incident_date)` | Timeline, escalation window |
| | `(status, severity)` | Open-case dashboard |
| | `(incident_date, location)` | Hotspot analysis |
| `ba_incident_intervention_jnt` | `(assigned_to, status, scheduled_date)` | Owner worklist, overdue sweep |
| `ba_notifications` | `(status, created_at)` | Outbox processing |
| `ba_audit_log` | `(entity_type, entity_id)` · `(changed_at)` · `(changed_by)` | Audit report, retention |

**Partitioning** is not applied in v7.0. At the projected ~460k ratings and ~500k audit rows per session, correct indexes are sufficient and partitioning adds operational cost with no benefit. Revisit if a tenant exceeds 10,000 students or five years of retained audit.

### 7.5 Views

| View | Purpose |
|---|---|
| `v_ba_student_period_scores` | Overall + per-category scores for a student-period, denormalised for the Student Report |
| `v_ba_assessment_progress` | Per assessment: expected cells, rated cells, completion %, status, days to deadline |
| `v_ba_open_interventions` | Open and in-progress interventions with a derived `is_overdue` and days overdue |
| `v_ba_incident_summary` | Incident counts by student, type, severity and status over the active session |
| `v_ba_at_risk_students` | Students meeting the configured at-risk rule, with the reason that triggered it |

Views encapsulate the rules that would otherwise be re-derived (and re-derived differently) in each of five reports.

---

## 8. The Scoring Engine

### 8.1 Algorithm

```
computeStudentScore(student, period):
    fw := resolveFramework(student.class, period)        # snapshot if locked
    for each criterion c in fw.criteria:
        ratings := ba_assessment_ratings
                   where student=student and criterion=c
                     and assessment.period=period
                     and assessment.status in ('reviewed','locked')
        if ratings is empty: continue                    # BR-BA-060 — exclude, never zero
        raw := AVG(ratings.rating_value)                 # BR-BA-006, uses the stored snapshot value
        if c.category.polarity = 'negative':
            raw := (fw.scale.max + fw.scale.min) - raw   # BR-BA-007 — generalised
        criterion_score[c] := raw
        teacher_count[c]   := COUNT(ratings)

    for each category cat in fw.categories:
        rated := criteria of cat present in criterion_score
        if count(rated) / count(active criteria of cat) < min_coverage:
            category_score[cat] := INSUFFICIENT_DATA     # BR-BA-061
            continue
        category_score[cat] := Σ(criterion_score[c] × c.weight) / Σ(c.weight)   for c in rated

    scored := categories with a numeric score
    switch fw.config.aggregation_method:
        'average'           : overall := AVG(category_score[scored])
        'weighted_average'  : overall := Σ(category_score[c] × c.weight) / Σ(c.weight)
        'separate_display'  : overall := NULL
    grade := mapToLevelBand(overall, fw.scale)           # BR-BA-062

    UPSERT ba_computed_scores  (student, category, period)
    UPSERT ba_computed_overall (student, period)
```

### 8.2 The polarity correction

DDL v2 and BRD v2 both specify `inverted = (max + 1) − raw`. The generalised form is `(max + min) − raw`.

| Scale | v2 formula, raw = 5 | v7 formula, raw = 5 | Correct? |
|---|---|---|---|
| 1–5 | `6 − 5 = 1` | `6 − 5 = 1` | Both correct |
| 1–3, raw = 3 | `4 − 3 = 1` | `4 − 3 = 1` | Both correct |
| **0–4**, raw = 4 | `5 − 4 = 1` | `4 − 4 = 0` | **v2 wrong** — a worst rating scores 1, so negative categories sit a point above positive ones |
| **2–6**, raw = 6 | `7 − 6 = 1` | `8 − 6 = 2` | **v2 wrong** — result falls below the scale minimum |

Every 1-based scale reduces to the old formula, so **no existing school's numbers change**. This is a latent defect fix, not a policy change.

### 8.3 Normalisation for result integration

```
normalised = (overall − scale.min) / (scale.max − scale.min) × normalisation_base
Final      = Academic × (1 − w) + normalised × w        w = weightage_percent / 100
```

`getBulkScores(period, student[])` returns rows only for **locked** periods with `is_result_integration_enabled = 1` (BR-BA-049). Anything else returns empty rather than a provisional number, because a provisional number that reaches a report card is indistinguishable from a final one.

### 8.4 Provenance

Every run writes `ba_score_runs`: trigger source, actor, period, snapshot id and checksum, students processed, scores written, duration, status, and any error. `ba_computed_scores.score_run_id` points at the run that produced it.

This is what makes BR-BA-064 testable: recompute a locked period, compare against the stored run, and any divergence is reported as a defect rather than silently overwriting a published score.

---

## 9. Reporting

### 9.1 Read discipline

**No report reads `ba_assessment_ratings`.** All ten reports read `ba_computed_scores`, `ba_computed_overall`, the five views, or `ba_incidents` and its children. The single exception is the Student Report's criterion-level detail panel, which reads ratings for **one student in one period** — a bounded query on the primary key path.

### 9.2 Synchronous vs asynchronous

```
estimated_rows := estimate(filters)
if estimated_rows <= config.export_async_row_threshold:   # default 1000
     render inline
else:
     write ba_report_exports (status='queued')
     dispatch GenerateReportExportJob
     notify user in-app when ready
```

Every export writes `ba_report_exports` regardless of size: report, filters, requester, row count, format, status, file reference and expiry. This satisfies BR-BA-087 (performance) and BR-BA-096 (an export of behavioural data is a disclosure event) with one mechanism.

### 9.3 Derived analytics

| Metric | Formula | Configured by |
|---|---|---|
| Period delta | `current_overall − previous_overall` | — |
| Trend band | improving if `Δ > trend_improve_percent × range`; stable if `abs(Δ) ≤ trend_stable_percent × range`; else declining | `trend_improve_percent` (7.5), `trend_stable_percent` (5.0) |
| At risk | `overall < at_risk_score_percent × range + scale.min` **OR** negative incidents in term `>= at_risk_incident_count` | 50.0, 2 |
| Teacher consistency | `stddev(rating_value)` per teacher per category; warn above `consistency_sd_percent × range` | 30.0 |
| Resolution rate | closed or resolved incidents / total incidents in window | — |
| Days to resolution | `AVG(resolved_at − incident_date)` | — |

All defaults reproduce the familiar 5-point behaviour exactly: 50% of a 1–5 range is 2.5; 7.5% of a range of 4 is 0.30; 5% is 0.20; 30% is 1.20. A school on a 3-point scale inherits the same *policy* rather than the same *numbers*.

### 9.4 Anonymisation

Anonymised mode replaces names and identifiers with stable per-report pseudonyms (`Student A`, `Student B`), suppresses admission and roll numbers, and suppresses any group with fewer than five members. Applied at the query layer, so an anonymised export cannot accidentally carry identity in a column nobody displayed.

---

## 10. Notification

### 10.1 The outbox

```
IncidentCreated
   ├─ BaNotificationService::evaluate(incident)
   │     severity >= config.parent_notification_threshold?  → obligations per recipient flags
   │     severity == 'critical'?                            → principal, unconditionally
   │     already notified for this incident+trigger?        → suppress (BR-BA-084)
   └─ EscalationCheckJob(student)
         count negative incidents in the rolling window
         >= config.incident_escalation_count?               → escalation obligations
```

Each obligation is a row in `ba_notifications`:

`event_type` · `entity_type` + `entity_id` · `recipient_type` (parent / employee / role) · `recipient_id` · `channel` (email / sms / push / in_app) · `payload_json` · `status` (pending / sent / failed / suppressed) · `attempt_count` · `last_attempt_at` · `sent_at` · `failure_reason`.

`DispatchNotificationJob` hands the row to the Notification module and writes back the outcome. Failures are retried with backoff to a bounded attempt count, then left `failed` and surfaced on screen 28.

### 10.2 Why this replaces `is_notified`

A boolean can express "we tried and it worked". It cannot express "we tried three times, the parent's number is wrong, and nobody knows". The second state is the one that matters: a school believing a parent was informed about a serious incident, when they were not, is worse than a school knowing the message failed.

`ba_incidents.is_notified` is retained as a denormalised convenience for list rendering, maintained from the outbox. The outbox is authoritative.

---

## 11. Configuration

### 11.1 Resolution order

```
effective_value(setting, class?) :=
     ba_class_scale_jnt[class]              # rating scale only
  ?? ba_config[current_session][setting]
  ?? module default (code constant)
```

`ba_config` is auto-created for a session on first access using module defaults, then editable. A new session offers "copy settings from previous session" as the first action.

### 11.2 Groups

Scale · Workflow · Scoring · Result integration · Notification · Escalation · Incident policy · Analytics thresholds · Privacy and retention · Features · Performance. Full list in BRD v3 §22.

### 11.3 Feature flags

| Flag | Default | Effect when off |
|---|---|---|
| `is_review_required` | 1 | `submit()` goes straight to `reviewed` |
| `auto_lock_on_approval` | 0 | Approval leaves the assessment at `reviewed` |
| `is_result_integration_enabled` | 0 | `getBulkScores()` returns empty |
| `is_comment_bank_enabled` | 1 | The insert control is hidden |
| `is_behaviour_points_enabled` | **0** | No points are written; the ledger stays empty |
| `principal_daily_digest` | 0 | No digest job runs |
| `freeze_witness_on_closure` | 1 | Witnesses stay editable after closure |

### 11.4 Scale-relative thresholds

```
scale_range := scale.max − scale.min
absolute    := scale.min + (percent / 100) × scale_range     # for score thresholds
absolute    := (percent / 100) × scale_range                 # for deltas and dispersion
```

Every analytical threshold is stored as a percentage and converted at use. This is the difference between a policy ("flag the bottom half of the range") and a constant (2.5), and it is why the module survives a school changing its scale.

---

## 12. Security and Privacy

### 12.1 Enforcement points

| Concern | Where |
|---|---|
| Authentication, tenancy | Module `RouteServiceProvider::map()` — the full stack (`web`, `InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`, `auth`, `verified`) lives there, **not** in `web.php`. A prior audit finding that routes were unprotected was a false positive for exactly this reason |
| Role authorisation | Policies |
| Relationship authorisation | Policies, using resolved class/section/child relationships |
| Field-level | `viewStatement()`, `viewDemographics()`, `viewAudit()` |
| Data isolation | Database-per-tenant. No `tenant_id`, no cross-database FK |

### 12.2 Audited entity types

`assessment` · `assessment_rating` · `incident` · `intervention` · `witness` · `witness_read` · `config` · `framework` · `period` · `export`.

The last four did not exist in v2 and were exactly the activities BRD v2 §85 expected to be discoverable in the audit report.

### 12.3 Read auditing

Three read operations write audit rows: witness statement access, report export, and demographic analytics runs. Each is a disclosure of sensitive student information to a person, and a disclosure that leaves no trace is not a controlled one.

### 12.4 Retention

`audit_retention_months` (default 36) governs eligibility. `ArchiveAuditLogJob` moves eligible rows to `ba_audit_log_archive` **only when an administrator runs it**, and writes an audit row recording what was archived. There is no scheduled purge; BR-BA-093 forbids silent deletion of a compliance record.

---

## 13. Migration from DDL v2 to v7.0

### 13.1 Shape

Additive. No table dropped, no column dropped, no rename. Existing rows remain valid.

### 13.2 Steps

| # | Step | Notes |
|---|---|---|
| 1 | Create the 13 new tables | No dependency on existing data |
| 2 | Add new columns to the 16 existing tables, all nullable or defaulted | Zero-downtime on MySQL 8 for the additive cases |
| 3 | Backfill `ba_assessment_ratings.rating_value` from `ba_rating_levels.numeric_value` | Batched. The only large-table backfill |
| 4 | Backfill `ba_incidents.incident_no` in `incident_date, id` order | Deterministic and stable |
| 5 | Backfill `ba_incidents.status`: `closed` where a follow-up exists and is past, else `open` | Documented approximation; historical incidents have no recorded lifecycle to recover |
| 6 | Migrate `attachments_json` → `ba_incident_attachments` | One row per array element |
| 7 | Migrate `follow_up_notes` → one `ba_incident_followups` row per incident | Prior content becomes the first entry, dated from `follow_up_date` or `updated_at` |
| 8 | Split `ba_computed_scores.overall_score` → `ba_computed_overall` | One row per student-period, taken from the row that currently holds the overall |
| 9 | Alter `created_by`/`updated_by` to `INT UNSIGNED`; add FKs to `sys_users` | **Verify no value exceeds `INT UNSIGNED` first.** With `sys_users.id` being `INT UNSIGNED`, none can, but verify before altering |
| 10 | Alter `deleted_at` to `TIMESTAMP(6)`; add `uq_guard` generated columns; rebuild unique keys | Requires a table rebuild; run in a maintenance window |
| 11 | Seed the Comment Bank and the 3 new interventions | Idempotent by code |
| 12 | Create views | — |
| 13 | Create triggers | **Last.** Creating them earlier would block the backfills above |
| 14 | Set `ba_rating_scales.is_locked = 1` for any scale with existing ratings | Applies BR-BA-029 to history |
| 15 | Capture a retrospective framework snapshot for each already-locked period | Best-effort from current masters, flagged `is_retrospective = 1` so nobody mistakes it for a true freeze |

### 13.3 Honest limits of the migration

Two things cannot be recovered, and pretending otherwise would be worse than saying so:

1. **Historical incident lifecycle.** Incidents created before v7.0 never had a status. Step 5 infers one from follow-up data. Where inference is impossible the incident lands in `open`, which is truthful — nobody knows whether it was resolved.
2. **Retrospective snapshots are not freezes.** A snapshot taken today for a period locked six months ago records *today's* framework. If a weight changed in between, that period's history is already unrecoverable. The `is_retrospective` flag exists so this is visible in the data rather than assumed away. From v7.0 forward, snapshots are genuine.

### 13.4 Rollback

Steps 1–8 and 11–13 are reversible: drop new objects, restore JSON columns from the relational rows. Steps 9, 10 and 14 require a restore from backup. Take one before step 9.

---

## 14. Implementation Roadmap

| Phase | Scope | Closes |
|---|---|---|
| **P1 — Integrity** | Schema migration, triggers, CHECKs, lock cascade, FSM enforcement, `sys_users` type fix, unique-key rebuild | BUG-BA-001, BUG-BA-002, DATA-BA-001/004, BR-BA-010/028/029/044/045/052 |
| **P2 — Missing obligations** | Notification outbox, escalation, `DispatchNotificationJob`, outbox screen, the 3 missing FormRequests, wire events and listeners | SEC-BA-001, BR-BA-013/083/084, REQ-BA-017/028 |
| **P3 — History** | Framework snapshots, rating value snapshot, score runs, `ba_computed_overall`, queued recompute | BR-BA-046/047/057/063/064, REQ-BA-013/021/027 |
| **P4 — Cases** | Intervention case management, incident lifecycle, follow-up log, attachments, witness statements, progress log | D-01, D-06, REQ-BA-015/016/024/025 |
| **P5 — Insight** | Reviewer signals, at-risk register, trend bands, async export, anonymisation, dashboard rebuild on cached reads | REQ-BA-023/029, BR-BA-086/087/088/089 |
| **P6 — Assurance** | Test suite. **There are currently 0 tests** against a module with immutable audit, polarity inversion, weighted averaging, four state machines and incident immutability | AC-01 … AC-35 |

P1 and P2 are not optional and are not sequenced for convenience: until they land, a locked period does not freeze anything and no parent is ever notified of a serious incident.

---

## 15. Testing Strategy

| Layer | Coverage |
|---|---|
| **Unit** | Polarity inversion across 1–5, 1–3, **0–4** and 2–6 scales · weighted averaging · unrated-cell exclusion · minimum coverage · grade mapping · normalisation · threshold conversion at three scale ranges |
| **Feature** | All four FSMs including every rejected transition · lock cascade · incident immutability and permitted severity escalation · outbox creation and suppression · escalation windowing · witness access denial and read auditing · soft-delete re-creation |
| **Database** | Every trigger's rejection path, driven by raw SQL that bypasses the model layer entirely — this is the only way to prove the backstop works |
| **Policy** | The full §6 visibility matrix, one test per cell |
| **Browser (Dusk)** | Grid entry, auto-save, forced-close recovery, submit validation, review and send-back, incident creation with attachment |
| **Performance** | 2,000 students seeded: dashboard p95, grid load, school-wide recompute, 5,000-row export |

The database-layer tests matter most. Every rule in §7.3 exists because the equivalent application-layer rule was already written once, believed, and found missing.

---

## 16. Screen Inventory

| # | Screen | Primary roles | Reads |
|---|---|---|---|
| 01 | Dashboard | All | Cached scores, views |
| 02 | Rating Scales | Admin | Masters |
| 03 | Categories & Criteria | Admin | Masters |
| 04 | Interventions | Admin | Masters |
| 05 | Class Mapping | Admin | Masters |
| 06 | Assessment Periods | Admin | Periods |
| 07 | Configuration | Admin | Config |
| 08 | My Assessments | Teacher | `v_ba_assessment_progress` |
| 09 | Ratings Grid | Teacher | Ratings |
| 10 | Student Remarks | Teacher | Remarks, Comment Bank |
| 11 | Review Queue | HOD, Principal | Assessments + quality signals |
| 12 | Incident Log | Teacher, HOD, Counsellor | Incidents |
| 13 | Witnesses | HOD, Counsellor, Principal | Witnesses |
| 14 | Interventions Applied | HOD, Counsellor | Applied interventions |
| 15–19 | Reports Hub + 4 reports | Per report | Cached |
| 20–24 | 5 standalone reports | Per report | Cached |
| **25** | **Comment Bank** | Admin | Masters |
| **26** | **Framework Snapshots** | Admin (read-only) | Snapshots |
| **27** | **Intervention Worklist** | Owner, Counsellor | `v_ba_open_interventions` |
| **28** | **Notification Outbox** | Admin, Principal | `ba_notifications` |

---

## 17. Non-Functional Design

### 17.1 Meeting the performance targets

| NFR | Target | How |
|---|---|---|
| NFR-01 | Dashboard p95 < 2s | Cached tables and views only; no raw aggregation; KPI counts from indexed views |
| NFR-02 | Grid load < 3s | Three queries total; roster and framework cached per request |
| NFR-03 | Auto-save < 500ms | Batched upsert of dirty cells only |
| NFR-04 | Report < 5s | Computed cache; covering indexes |
| NFR-06 | Recompute < 10 min | Queued; chunked by class-section; single-pass aggregate per student |
| NFR-08 | Ratings table | Reached only by the compute job and one bounded student-detail query |

### 17.2 Sizing (per tenant per session, 2,000 students)

| Table | Rows | Note |
|---|---|---|
| `ba_assessment_ratings` | ~460,000 | Dominant |
| `ba_audit_log` | ~500,000 | Grows across sessions until archived |
| `ba_computed_scores` | ~72,000 | |
| `ba_assessments` | ~1,600 | |
| `ba_incidents` | ~3,000 | |
| `ba_notifications` | ~2,000 | |

### 17.3 Data lifecycle

| Data | Policy |
|---|---|
| Ratings, scores, remarks | Retained for the life of the tenant |
| Incidents and cases | Retained for the life of the tenant |
| Audit log | `audit_retention_months` (36), then archivable by explicit action |
| Export files | Purged after `export_expiry_days` (7); the `ba_report_exports` row is retained as the disclosure record |
| Snapshots | Never deleted |

---

## 18. Decisions Owned by This Document

Business decisions were made in BRD v3 §24. These are technical decisions this design owns.

| # | Decision | Rationale |
|---|---|---|
| SD-01 | **Database triggers enforce invariants** | Nine of thirty business rules were unenforced in application code. Invariants belong where nothing can bypass them |
| SD-02 | **Triggers are isolated in DDL Section 20** | A deployment may omit them; the schema stays valid. Enforcement should be a visible choice, not a hidden dependency |
| SD-03 | **`TIMESTAMP(6)` + generated `uq_guard` for soft-delete uniqueness** | The two obvious alternatives either break re-creation or silently stop enforcing (§3.4) |
| SD-04 | **Overall score gets its own table** | Storing it on "the first category row" depends on row order and breaks when a category is deactivated |
| SD-05 | **Overdue is derived, never stored** | A flag that depends on a nightly job is a flag that is wrong between runs |
| SD-06 | **Rating stores its numeric value** | Makes a rating self-describing and a locked period reproducible even if a level is later deleted |
| SD-07 | **Snapshots carry a checksum** | Makes "a locked period recomputes identically" a testable assertion rather than a hope |
| SD-08 | **`is_notified` retained but not authoritative** | Cheap denormalisation for list rendering; the outbox is the truth |
| SD-09 | **No partitioning in v7.0** | Correct indexes suffice at projected volume; revisit above 10,000 students |
| SD-10 | **`ba_*` primary keys stay `BIGINT`, cross-module FKs match their source types** | Ratings and audit will exceed `INT`; cross-module columns must match or they cannot be constrained |
| SD-11 | **Draft auto-saves are not audited** | Auditing every 30-second save buries the changes that matter under thousands that do not |
| SD-12 | **Quality signals advise, never block** | Grading is professional judgement. A system that blocks approval on a statistical outlier teaches teachers to grade to the middle, which destroys the data |
| SD-13 | **Retrospective snapshots are flagged** | A snapshot taken today for a period locked months ago is not a freeze. The flag makes that visible rather than assumed |

---

## 19. Open Items

None blocking. Three items are deliberately deferred with an owner and a trigger.

| # | Item | Deferred until | Why |
|---|---|---|---|
| O-01 | Partitioning `ba_assessment_ratings` and `ba_audit_log` | A tenant exceeds 10,000 students or 5 years of retained audit | Operational cost with no current benefit (SD-09) |
| O-02 | Clinical counselling notes (ENH-BA-021) | A privacy and legal review completes | Clinical confidentiality is a different standard from disciplinary record-keeping and probably needs separate storage, not a flag |
| O-03 | Predictive at-risk scoring (ENH-BA-025) | A school and its board explicitly ask for it | Technically feasible on this data. Acting on a prediction about which children will misbehave is a decision a school should take deliberately, not one that arrives as a feature |

---

## 20. Traceability — BRD v3 to Design

| BRD area | Rules | Design section | Enforcement |
|---|---|---|---|
| Framework masters | BR-026…036 | §4 | CHECK, UNIQUE, triggers |
| Class applicability | BR-009, 040 | §4.1 | Service |
| Period lifecycle | BR-041…045 | §5.1, §5.2 | Trigger + service |
| Framework history | BR-046, 047, 100 | §4.2 | Immutable table + trigger |
| Assessment workflow | BR-050…058 | §5.3 | Trigger + service + status history |
| Rating entry | BR-005, 056, 057 | §5.5 | UNIQUE + trigger |
| Scoring | BR-006, 007, 059…064 | §8 | Service + score runs |
| Result integration | BR-017, 023, 024, 049 | §8.3 | Service, pull-only |
| Incidents | BR-008, 065…073 | §6.1, §6.2 | CHECK + trigger |
| Evidence and follow-up | BR-074, REQ-024/025 | §6.3 | Append-only tables |
| Witnesses | BR-019, 031, 075…077 | §6.5 | Policy + trigger + read audit |
| Interventions | BR-078…082 | §6.4 | CHECK + service |
| Notification | BR-013, 083, 084 | §10 | Outbox + job |
| Dashboard | BR-085, 086 | §9.1 | Cached reads |
| Reporting | BR-087…091 | §9 | Service + views |
| Audit | BR-012, 092, 093 | §12.2, §12.4 | Insert-only trigger |
| Privacy | BR-019, 032, 094…097 | §12 | Policies + read audit |
| Integrity | BR-098…100 | §3.4, §7 | UNIQUE + FK + trigger |

---

## 21. Design Principles — the short version

1. **If a rule matters, give it a row, a constraint or a trigger.** Nine of thirty rules lived only in a specification and nine of thirty were missing from the code. That correlation is the whole story.
2. **A published number must be reproducible forever.** Snapshot the framework, store the value, record the run.
3. **An obligation is a row, not a boolean.** A boolean cannot represent a failure, so failures become invisible.
4. **Append, never overwrite.** What a school did about a child is exactly the part that must survive.
5. **Read from the cache; compute in a job.** Half a million ratings per session decide this.
6. **Thresholds are policy, not constants.** 2.5 is a number about one scale; 50% is a policy about any scale.
7. **Advise on judgement; enforce on invariants.** Block a locked edit. Never block a teacher's professional opinion.
8. **Say what the migration cannot recover.** A retrospective snapshot is not a freeze, and the data should say so.

---

**End of `Solution_Design_v2.md`**
