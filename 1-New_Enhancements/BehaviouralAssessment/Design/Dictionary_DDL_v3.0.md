# Prime-AI Behavioural Assessment Module — Data Dictionary

**Document ID:** BHA-DD-V3.0
**Version:** 1.0
**Date:** 2026-09-09
**Describes:** `BehaviouralAssess_DDL_v3.0.sql` — 29 tables, 5 views, 22 triggers
**Database:** `tenant_db` — one database per tenant · MySQL 8.0.16+ · InnoDB · utf8mb4
**Prefix:** `ba_`

**Companion documents:** `Behavioural_Assess_BRD_v3.md` (what the business needs) · `Solution_Design_v2.md` (how it works)

---

## How to read this dictionary

Every table has the same four parts:

| Part | What it tells you |
|---|---|
| **What it is for** | Plain-English purpose, in two or three sentences |
| **Example row** | Realistic data, so the shape of the table is obvious at a glance |
| **Columns** | Every column: type, nullability, meaning, and an example value |
| **Keys & rules** | Unique keys, foreign keys, CHECK constraints, triggers, and behaviour worth knowing |

### Notation

| Symbol | Meaning |
|---|---|
| **PK** | Primary key |
| **UK** | Part of a unique key |
| **FK** | Foreign key — the parent table is named |
| **GEN** | Generated column. MySQL calculates it; **you never write to it** |
| **CACHE** | Derived from `ba_assessment_ratings` by a job. Rebuildable, never authoritative |
| **FROZEN** | Captured at a moment in time and never read back from the master |
| **TRG** | Protected by a database trigger — see §Triggers |
| ✔ / — | Column allows NULL / does not allow NULL |

---

## What this module is for

It joins two things most schools keep in different places:

| | **Periodic assessment** | **Incident management** |
|---|---|---|
| Trigger | Planned, at set times | Event-driven, any time |
| Subject | A whole class | One student |
| Produces | **A number** | **A documented case with an owner and an outcome** |
| Tables | `ba_assessments` → `ba_assessment_ratings` | `ba_incidents` → `ba_incident_intervention_jnt` |

The deliverable is a **longitudinal behavioural-development record**, not a marks-entry screen.

---

## The governing principle

> **If a rule matters, give it a row, a constraint or a trigger.**
> A rule that lives only in a developer's memory of the spec will be missing from the code, and nothing will notice.

This schema exists because the previous version expressed intent it gave the application no way to keep. Two examples, both found in a real audit:

| What the old schema had | What actually happened |
|---|---|
| A `status` column on a period, with no relationship to the rows it was meant to freeze | **"Locked" periods froze nothing.** Approved scores could be edited out of sync with the cache and the audit trail |
| An `is_notified` boolean on an incident | **No parent was ever notified.** The column was never written, the threshold setting was dead config, and nothing failed |

Both are fixed here structurally — the lock is checked **where the write happens** (§Triggers 5), and the notification is **a row with a status** (`ba_notifications`).

---

## Patterns used throughout — explained once

### 1. The audit columns

Most tables carry these. They are described here and **not repeated** in each table below.

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `created_by` | INT UNSIGNED | — | Who created the row. FK → `sys_users.id` | `14` |
| `updated_by` | INT UNSIGNED | — | Who last changed it. FK → `sys_users.id` | `22` |
| `created_at` | TIMESTAMP | ✔ | When created | `2026-09-09 10:14:22` |
| `updated_at` | TIMESTAMP | ✔ | When last changed | `2026-09-09 16:02:05` |
| `deleted_at` | DATETIME(6) | ✔ | **Soft delete.** NULL = live. A date = hidden but retained | `NULL` |
| `is_active` | TINYINT(1) | — | Selectable / in use. Distinct from deleted | `1` |

> **`created_by` carries a foreign key; `updated_by` does not.** Adding a second index to `sys_users` on every one of 29 tables costs storage and write throughput to answer a question nothing asks. `ba_audit_log` is exempt from even the first, because `created_by` there always equals `changed_by`, which is already indexed — and that table reaches ~500,000 rows per session.

### 2. `uq_guard` — soft delete that still enforces uniqueness

```sql
`deleted_at`  DATETIME(6) NULL DEFAULT NULL,
`uq_guard`    DATETIME(6) GENERATED ALWAYS AS
                (IFNULL(`deleted_at`,'1970-01-01 00:00:00.000000')) STORED,
UNIQUE KEY (`code`, `uq_guard`)
```

**The problem.** A class-category mapping is soft-deleted. The administrator re-creates it. `UNIQUE(class_id, category_id)` rejects the insert, because the deleted row is still physically there.

**Two obvious fixes, both wrong:**

| Attempt | Why it fails |
|---|---|
| Add `deleted_at` to the key | MySQL treats every `NULL` as distinct, so **every live row becomes unique regardless of its natural key.** The constraint silently stops enforcing anything — worse than the bug, because nothing fails |
| Drop the constraint, check in code | Two concurrent requests both pass the check and both insert |

**How `uq_guard` works.** Every live row carries the same sentinel, so the natural key is enforced among live rows exactly as intended. Every deleted row carries its own deletion instant, so any number of deleted rows may share the natural key.

**Why `DATETIME(6)` and not `TIMESTAMP`:**
- microsecond precision removes the case where two soft-deletes of the same key inside one second would collide;
- a `TIMESTAMP → DATETIME` conversion is time-zone dependent, which MySQL **rejects** in a stored generated column;
- `TIMESTAMP` cannot represent `'1970-01-01 00:00:00'` — that is its zero value — so the sentinel would be invalid.

> **`uq_guard` is described here once and not repeated per table.** Where a table's unique key depends on it, that table's *Keys & rules* names it. It is `GENERATED … STORED`: **never write to it.**

### 3. Tables that deliberately have NO `deleted_at`

Eight tables are insert-only or append-only by design, because a soft delete would be a way of unsaying something that was said:

`ba_audit_log` · `ba_audit_log_archive` · `ba_framework_snapshots` · `ba_assessment_status_history` · `ba_incident_followups` · `ba_intervention_progress` · `ba_score_runs` · `ba_behaviour_points`

Their UPDATE and DELETE paths are closed by triggers.

### 4. Key type discipline

Cross-module identifiers must match the tables they reference. Verified against the tenant DDL:

| Referenced table | PK type | Used in BA as |
|---|---|---|
| `std_students` | `INT UNSIGNED` | `student_id`, `witness_id` (student) |
| `sch_employees` | `INT UNSIGNED` | `teacher_id`, `reported_by`, `assigned_to`, `recorded_by`, `witness_id` (staff) |
| `sch_class_section_jnt` | `INT UNSIGNED` | `class_section_id` |
| `sch_classes` | `INT UNSIGNED` | `class_id` |
| `sch_subjects` | `INT UNSIGNED` | `subject_id` |
| `sch_org_academic_sessions_jnt` | `SMALLINT UNSIGNED` | `academic_session_id` |
| `sch_academic_term` | `SMALLINT UNSIGNED` | `academic_term_id` |
| **`sys_users`** | **`INT UNSIGNED`** | `created_by`, `updated_by`, `changed_by`, `actor_id` |

> **`sys_users.id` is `INT UNSIGNED`, not `BIGINT`.** The previous version declared every `created_by` as `BIGINT UNSIGNED` — four bytes wider than the values it held, and impossible to constrain with a foreign key. Corrected throughout.

`ba_*` primary keys stay `BIGINT UNSIGNED`: `ba_assessment_ratings` alone reaches ~460,000 rows per session.

### 5. No `tenant_id`, anywhere

This module lives in `tenant_db` — **one database per school**. There is no `tenant_id` column in any `ba_*` table, and no cross-database foreign key.

---

## Behavioural-assessment terms, plainly

| Term | What it means | Table |
|---|---|---|
| **Rating scale** | The measuring instrument: a 5-point scale, a 3-point scale | `ba_rating_scales` |
| **Rating level** | One step on that scale: "Outstanding" = 5.0 | `ba_rating_levels` |
| **Category** | A behavioural domain: "Classroom Engagement", "Disruptive Behaviours" | `ba_categories` |
| **Criterion** | One observable behaviour inside a category | `ba_criteria` |
| **Polarity** | Whether high is good (`positive`) or bad (`negative`) | `ba_categories.polarity` |
| **Period** | The window in which assessment happens: Term 1, Monthly — August | `ba_assessment_periods` |
| **Assessment** | One teacher's evaluation of one class-section for one period | `ba_assessments` |
| **Rating** | One grid cell: this student, this criterion, this level | `ba_assessment_ratings` |
| **Framework snapshot** | The frozen scale, categories, criteria and weights a locked period was scored against | `ba_framework_snapshots` |
| **Incident** | A behavioural event, positive or negative, with a lifecycle | `ba_incidents` |
| **Intervention** | What the school did about it — with an owner, a due date and an outcome | `ba_incident_intervention_jnt` |
| **Escalation** | N negative incidents within a rolling window triggers a wider alert | `ba_config.incident_escalation_count` |

---

## A worked example — one term, end to end

A Grade 8-A student is assessed, an incident is logged, and both are traced to conclusion. This touches 17 tables.

| # | What happens | Table | Key data |
|---:|---|---|---|
| 1 | Admin confirms the 5-point scale for the session | `ba_config` | `rating_scale_id = 1` |
| 2 | Grades 1–2 are put on a 3-point scale instead | `ba_class_scale_jnt` | class 1 → scale 2 |
| 3 | Grade 8 is mapped to 9 categories | `ba_class_category_jnt` | 9 rows |
| 4 | "Term 2 Assessment" is opened | `ba_assessment_periods` | 01 Sep – 30 Nov, deadline 05 Dec |
| 5 | Mrs Rao starts her 8-A assessment | `ba_assessments` | draft, 0% complete |
| 6 | She rates 40 students × 30 criteria | `ba_assessment_ratings` | 1,200 rows, each with `rating_value` |
| 7 | She writes one remark per student, from the bank | `ba_student_remarks` + `ba_comment_bank` | 40 rows |
| 8 | She submits; the grid is complete | `ba_assessment_status_history` | draft → submitted |
| 9 | The HOD approves | `ba_assessment_status_history` | submitted → reviewed |
| 10 | A student shouts at a classmate in the corridor | `ba_incidents` | `INC-2026-000417`, major |
| 11 | Two witnesses give statements | `ba_incident_witnesses_jnt` | restricted read |
| 12 | A photo of the damaged door is attached | `ba_incident_attachments` | staff-only |
| 13 | Parents are notified — severity ≥ threshold | `ba_notifications` | pending → sent |
| 14 | A counselling referral is assigned with a due date | `ba_incident_intervention_jnt` | owner, due 20 Nov |
| 15 | The counsellor logs two progress notes | `ba_intervention_progress` | append-only |
| 16 | It completes; the case resolves, then closes | `ba_incidents` | action_taken → resolved → closed |
| 17 | The period is locked | `ba_assessment_periods` | closed → locked |
| 18 | The framework is frozen | `ba_framework_snapshots` | checksum `9f2c1a…` |
| 19 | Scores are computed | `ba_computed_scores` + `ba_computed_overall` | 9 category rows + 1 overall |
| 20 | The run is provenanced | `ba_score_runs` | 40 students, 4.8s |
| 21 | Everything sensitive is audited | `ba_audit_log` | including witness-statement reads |

### What the numbers actually do

```
Raw ratings for ONE student, ONE criterion, from THREE teachers
     Mrs Rao 4.0 · Mr Khan 3.0 · Mrs Iyer 4.0
          ↓  average across teachers
     criterion_score = 3.67          teacher_count = 3

Negative category? Invert it:
     "Disruptive Behaviours" rated 5.0 (worst) on a 1–5 scale
     inverted = (max + min) − raw = (5 + 1) − 5 = 1.0
          ↓  so a HIGH final score always means GOOD behaviour

Weighted average of criterion scores → category score → ba_computed_scores
Weighted average of category scores  → overall score  → ba_computed_overall
          ↓
     grade mapped from the scale's level bands → "Very Good"
```

> **The inversion formula is `(max + min) − raw`, not `(max + 1) − raw`.** The older form is only correct when the scale starts at 1. On a 0–4 scale it makes the worst possible rating score 1 instead of 0, putting every negative category a point above every positive one for the whole school. Every 1-based scale gives the same answer under both, so **no existing school's numbers change** — this is a latent defect fix, not a policy change.

---

# SECTION 1 — Foundation Masters

## 1.1 `ba_rating_scales`

### What it is for
The measuring instrument. A scale is an ordered set of levels with labels and numeric values. One scale is active per academic session; a class may override it.

`min_rating` and `max_rating` drive three things: normalisation to a 0–100 range for report-card integration, the negative-polarity inversion, and validation that every level falls inside the scale.

### Example row

```
code        : 5_POINT
name        : "5-Point Behavioural Scale"
grade_type  : letter
min_rating  : 1.00      max_rating : 5.00
is_default  : 1
is_locked   : 1         locked_at  : 2026-09-14 11:02
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1` |
| `code` | VARCHAR(30) | — | **UK** (with `uq_guard`). Machine identifier | `5_POINT` |
| `name` | VARCHAR(100) | — | Display name | `5-Point Behavioural Scale` |
| `description` | TEXT | ✔ | What this scale is for | `Default behavioural scale` |
| `grade_type` | ENUM | — | `letter` (A+/A/B), `numeric` (5/4/3), `descriptive` (words). **How the UI renders a mapped grade** | `letter` |
| `min_rating` | DECIMAL(4,2) | — | Lowest value on the scale | `1.00` |
| `max_rating` | DECIMAL(4,2) | — | Highest value | `5.00` |
| `is_default` | TINYINT(1) | — | The school's preferred scale | `1` |
| `is_locked` | TINYINT(1) | — | **Set the first time a rating references one of this scale's levels.** From then on `min_rating`, `max_rating` and every level value are frozen | `1` |
| `locked_at` | TIMESTAMP | ✔ | When it locked | `2026-09-14 11:02` |
| `is_default_flag` | TINYINT UNSIGNED | ✔ | **GEN + UK.** `1` when default and live, else `NULL`. **MySQL treats NULLs as distinct in a unique index, which is exactly what makes this work: at most one row can hold the value 1** | `1` |

### Keys & rules

- `UNIQUE (code, uq_guard)` · `UNIQUE (is_default_flag)` — **at most one default scale, enforced by the database rather than by convention.** The previous version allowed several.
- `CHECK (max_rating > min_rating AND min_rating >= 0)`.
- **TRG `trg_ba_scale_locked_bu`** — once `is_locked = 1`, the numeric range cannot change. Labels and descriptions remain editable: renaming "Good" to "Meets Expectations" changes no arithmetic.

## 1.2 `ba_categories`

### What it is for
Broad behavioural domains. Nine are seeded: five positive, four negative.

### Example rows

| code | name | polarity | weight | sort_order | is_system |
|---|---|---|---:|---:|:---:|
| `CLS_ENG` | Classroom Engagement | `positive` | 100.00 | 1 | 1 |
| `RES_RSP` | Respect and Responsibility | `positive` | 100.00 | 2 | 1 |
| `DISRUPT` | Disruptive Behaviours | **`negative`** | 100.00 | 6 | 1 |
| `AGGRESS` | Aggressive or Bullying Behaviours | **`negative`** | 100.00 | 7 | 1 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `6` |
| `parent_id` | BIGINT UNSIGNED | ✔ | Self-FK, `ON DELETE SET NULL`. **NULL = top level. Maximum depth is 2** — deeper trees make weighting unexplainable to the teachers who have to use it | `NULL` |
| `code` | VARCHAR(30) | — | **UK** (with `uq_guard`) | `DISRUPT` |
| `name` | VARCHAR(100) | — | Display name | `Disruptive Behaviours` |
| `description` | TEXT | ✔ | What this domain covers | `Behaviours that hinder learning` |
| `polarity` | ENUM | — | **`positive`** (higher is better) or **`negative`** (inverted at computation) | `negative` |
| `weight` | DECIMAL(5,2) | — | **Proportional, normalised at computation.** Nine categories at 100 each means one ninth apiece, not 900% | `100.00` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order | `6` |
| `is_system` | TINYINT(1) | — | **Seeded categories are protected from deletion** | `1` |

### Keys & rules

`UNIQUE (code, uq_guard)` · `CHECK (weight BETWEEN 0 AND 100)`.

> **Weights are proportional on purpose.** The UI shows both the entered weight and its *effective percentage* of the current total, so an administrator can see that four categories at 100 each are 25% apiece. The engine never depends on somebody keeping a running total correct.

## 1.3 `ba_interventions`

### What it is for
The master list of actions a school can take in response to an incident. Twelve are seeded.

### Example rows

| code | name | intervention_type | default_due_days | requires_owner | requires_parent_meeting |
|---|---|---|---:|:---:|:---:|
| `AWARD_CERT` | Award/Certificate | `reward` | 14 | 0 | 0 |
| `VERBAL_WARN` | Verbal Warning | `corrective` | 1 | 1 | 0 |
| `SUSPENSION` | Suspension | `corrective` | 3 | 1 | **1** |
| `COUNS_REF` | Counselling Referral | `counselling` | 14 | 1 | 0 |
| `BEHAV_CONTRACT` | Behaviour Contract | `corrective` | 30 | 1 | **1** |
| `RESTORATIVE` | Restorative Conversation | `counselling` | 7 | 1 | 0 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `9` |
| `code` | VARCHAR(30) | — | **UK** (with `uq_guard`) | `COUNS_REF` |
| `name` | VARCHAR(100) | — | Display name | `Counselling Referral` |
| `description` | TEXT | ✔ | What it involves | `Referral to the school counsellor` |
| `intervention_type` | ENUM | — | **`reward`, `corrective`, `counselling`.** The canonical three. "Reinforcement" and "Supportive" are UI aliases, not stored values | `counselling` |
| `default_due_days` | SMALLINT UNSIGNED | — | **Seeds `scheduled_date` = incident date + this** | `14` |
| `requires_owner` | TINYINT(1) | — | **When 1, `assigned_to` is mandatory on application.** An intervention nobody owns does not happen | `1` |
| `requires_parent_meeting` | TINYINT(1) | — | Raises a parent notification obligation | `0` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order | `9` |
| `is_system` | TINYINT(1) | — | Seeded; protected | `1` |

### Keys & rules
`UNIQUE (code, uq_guard)`. **A `reward` may only be applied to a positive incident and a `corrective` only to a negative one** — enforced in `BaInterventionService`.

## 1.4 `ba_comment_bank`

### What it is for
Reusable narrative templates, so remarks are professional and consistent **without becoming identical on thirty report cards**.

### Example rows

| code | sentiment | applies_to | template_text |
|---|---|---|---|
| `OV_POS_01` | `positive` | `overall_remark` | `{student} has had an excellent term. {he_she} engages readily…` |
| `OV_DEV_01` | `developmental` | `overall_remark` | `{student} has found parts of this term difficult. With support around self-regulation…` |
| `CR_ENG_DEV` | `developmental` | `criterion_remark` | `{student} has the ideas but rarely offers them. Encouraging {him_her} to speak first…` |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4` |
| `category_id` | BIGINT UNSIGNED | ✔ | FK → `ba_categories`, `ON DELETE SET NULL`. **Optional scope to one behavioural domain** | `1` |
| `code` | VARCHAR(40) | — | **UK** (with `uq_guard`) | `OV_DEV_01` |
| `sentiment` | ENUM | — | `positive`, `neutral`, `developmental` | `developmental` |
| `applies_to` | ENUM | — | `criterion_remark`, `overall_remark`, `both` | `overall_remark` |
| `template_text` | VARCHAR(1000) | — | **Placeholders: `{student}`, `{he_she}`, `{him_her}`, `{his_her}`** | `{student} has found…` |
| `usage_count` | INT UNSIGNED | — | **Analytics only — never affects output** | `18` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order | `4` |
| `is_system` | TINYINT(1) | — | Seeded; protected | `1` |

### Keys & rules

`UNIQUE (code, uq_guard)` · `CHECK (CHAR_LENGTH(template_text) >= 10)`.

**Two rules matter here:**

1. **Insert, then own.** A template is a starting point. The inserted text is fully editable and is stored as the teacher's own words.
2. **Pronouns default to neutral.** `{he_she}` resolves from StudentProfile; where gender is unrecorded or "prefer not to say", the neutral form (*they* / *their*) is used. **A wrong guess misgenders a real child on a document their parents will read.**

---

# SECTION 2 — Master Detail

## 2.1 `ba_rating_levels`

### What it is for
The ordered levels within a scale. `sort_order = 1` is the **lowest** (worst).

### Example rows — the seeded 5-point scale

| sort_order | label | numeric_value | grade_label | description |
|:---:|---|---:|---|---|
| 1 | Unsatisfactory | 1.00 | `D` | Consistently falls short of expectations |
| 2 | Needs Improvement | 2.00 | `C` | Occasionally meets expectations |
| 3 | Good | 3.00 | `B` | Generally meets expectations |
| 4 | Very Good | 4.00 | `A` | Frequently exceeds expectations |
| 5 | Outstanding | 5.00 | `A+` | Consistently exceeds expectations |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4` |
| `rating_scale_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_rating_scales`, `ON DELETE CASCADE` | `1` |
| `label` | VARCHAR(50) | — | **UK.** What the teacher picks from the dropdown | `Very Good` |
| `numeric_value` | DECIMAL(4,2) | — | **UK. The number that feeds computation.** Must lie inside the parent scale's range | `4.00` |
| `description` | VARCHAR(255) | ✔ | What this level means, to steer consistency between teachers | `Frequently exceeds expectations` |
| `grade_label` | VARCHAR(5) | ✔ | Optional report-card band | `A` |
| `sort_order` | TINYINT UNSIGNED | — | **UK. 1 = lowest** | `4` |

### Keys & rules

- **Three unique keys per scale:** `sort_order`, `label` and `numeric_value`. Two levels called "Good", or two both worth 3.0, make a grid ambiguous to the teacher and the average meaningless.
- `CHECK (numeric_value >= 0)`.
- **TRG `trg_ba_level_range_bi` / `_bu`** — `numeric_value` must fall inside the parent scale's `[min_rating, max_rating]`. **A CHECK constraint cannot express this**, because it would have to read another row. The update trigger also blocks a value change once the scale is locked.

## 2.2 `ba_criteria`

### What it is for
The observable behaviours within a category. **58 are seeded** across the nine default categories.

### Example rows — Classroom Engagement (8 criteria)

| code | name | weight |
|---|---|---:|
| `CLS_ENG_01` | Active participation in class discussions and oral activities | 12.50 |
| `CLS_ENG_02` | Asking thoughtful, relevant, and clarifying questions | 12.50 |
| `CLS_ENG_04` | Completing classwork, assignments, and homework on time and with care | 12.50 |
| `CLS_ENG_08` | Responding constructively to teacher feedback and corrections | 12.50 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4` |
| `category_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_categories`, `ON DELETE CASCADE` | `1` |
| `code` | VARCHAR(30) | — | **UK** (with category and `uq_guard`) | `CLS_ENG_04` |
| `name` | VARCHAR(255) | — | **The observable behaviour**, phrased so two teachers would agree on what they saw | `Completing classwork… on time` |
| `description` | TEXT | ✔ | Further guidance | `Includes homework submitted late` |
| `weight` | DECIMAL(5,2) | — | Proportional within the category. `100 / 8 = 12.50` | `12.50` |
| `sort_order` | SMALLINT UNSIGNED | — | Display order in the grid | `4` |
| `is_system` | TINYINT(1) | — | Seeded; protected | `1` |

### Keys & rules

`UNIQUE (category_id, code, uq_guard)` · `CHECK (weight BETWEEN 0 AND 100)`.

> **There is no per-criterion `max_score`, deliberately.** The rating range belongs to the **scale**. A per-criterion maximum would let two columns of the same grid use different ranges, which teachers cannot reason about and which breaks averaging. A criterion's influence is expressed through its **weight**.

---

# SECTION 3 — Setup and Applicability

## 3.1 `ba_class_category_jnt`

### What it is for
Which behavioural categories apply to which class, so a **Grade 1 grid does not contain "Academic Misconduct"**.

### Example rows

| class_id | category_id | is_active |
|---|---|:---:|
| 1 (Grade 1) | Classroom Engagement | 1 |
| 1 (Grade 1) | Respect and Responsibility | 1 |
| 10 (Grade 10) | Academic Misconduct | 1 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `112` |
| `class_id` | INT UNSIGNED | — | **UK.** FK → `sch_classes`, `ON DELETE CASCADE`. Cross-module, read-only | `8` |
| `category_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_categories`, `ON DELETE CASCADE` | `6` |

### Keys & rules

`UNIQUE (class_id, category_id, uq_guard)`.

> **The permissive fallback is the whole rule.** If a class has **no** mapping rows at all, **every active category applies**. This is deliberate: a school that has not configured mapping yet must still be able to assess. The audit found this fallback missing, which produced empty grids and blocked teachers entirely. Once a class has at least one mapping, only mapped categories apply. **Do not "helpfully" seed a row per class** — the distinction between *no rows* and *some rows* is the mechanism.

## 3.2 `ba_class_scale_jnt`

### What it is for
An **optional** per-class override of the session's rating scale. A Montessori-style 3-point scale for Grades 1–2 alongside a 5-point scale for Grades 6–12.

### Example rows

| academic_session_id | class_id | rating_scale_id | reason |
|---:|---|---|---|
| 3 | 1 (Grade 1) | 2 (3-Point) | Age-appropriate for early years |
| 3 | 2 (Grade 2) | 2 (3-Point) | Age-appropriate for early years |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `2` |
| `academic_session_id` | SMALLINT UNSIGNED | — | **UK.** FK → `sch_org_academic_sessions_jnt`, `ON DELETE CASCADE` | `3` |
| `class_id` | INT UNSIGNED | — | **UK.** FK → `sch_classes`, `ON DELETE CASCADE` | `1` |
| `rating_scale_id` | BIGINT UNSIGNED | — | FK → `ba_rating_scales`, `ON DELETE RESTRICT`. **Overrides `ba_config` for this class** | `2` |
| `reason` | VARCHAR(255) | ✔ | **Why this class differs** — shown on the Configuration screen | `Age-appropriate for early years` |

### Keys & rules

`UNIQUE (academic_session_id, class_id, uq_guard)`.

**Resolution order:** `ba_class_scale_jnt[class]` → `ba_config[session].rating_scale_id`. **This table is empty in most tenants**, and the simple case stays simple.

> **One consequence for reporting.** Overall scores from two different scales are **not directly comparable**. Any cross-class report must normalise to 0–100 first, which is why `v_ba_student_period_scores` exposes both the raw score and the normalised one.

## 3.3 `ba_assessment_periods`

### What it is for
The windows in which structured assessment happens: "Term 2 Assessment", "Monthly — August".

### The lifecycle

```
        ┌──────────── reopen() ────────────┐
        ▼                                  │
     [OPEN] ──── close() ────▶ [CLOSED] ──── lock() ────▶ [LOCKED]   terminal

     open → locked    REJECTED. A period must be closed before it is locked.
     locked → *       REJECTED. Terminal.
```

| State | Effect |
|---|---|
| **open** | Assessments may be created and edited |
| **closed** | No new assessments; existing ones may complete review; scores may be computed |
| **locked** | **Everything beneath is frozen, and the framework snapshot is taken** |

### Example row

```
academic_session_id 3 · academic_term_id 6
name       : "Term 2 Assessment"
start_date 2026-09-01 · end_date 2026-11-30 · deadline 2026-12-05
status     : locked
closed_by 22 · closed_at 2026-12-06 10:00
locked_by 3  · locked_at 2026-12-08 16:40
reopen_count : 0
snapshot_id  : 14
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `30` |
| `academic_session_id` | SMALLINT UNSIGNED | — | **UK.** FK → `sch_org_academic_sessions_jnt`, `ON DELETE RESTRICT` | `3` |
| `academic_term_id` | SMALLINT UNSIGNED | ✔ | FK → `sch_academic_term`, `ON DELETE SET NULL`. **NULL = an independent cycle**, not tied to an exam term | `6` |
| `name` | VARCHAR(100) | — | **UK** (with session and `uq_guard`) | `Term 2 Assessment` |
| `start_date` / `end_date` | DATE | — | The assessment window | `2026-09-01` / `2026-11-30` |
| `deadline` | DATE | — | **Teacher submission deadline. Must be ≥ `end_date`** | `2026-12-05` |
| `status` | ENUM | — | `open`, `closed`, `locked` | `locked` |
| `closed_by` / `closed_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. Who closed it | `22` |
| `locked_by` / `locked_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. **Who made it final** | `3` |
| `reopen_count` | SMALLINT UNSIGNED | — | **A reopened period is an exception worth counting.** Four reopens is a control problem, and this makes it visible | `0` |
| `snapshot_id` | BIGINT UNSIGNED | ✔ | FK → `ba_framework_snapshots`, added in the deferred block. **The framework frozen for this period** | `14` |

### Keys & rules

- `UNIQUE (academic_session_id, name, uq_guard)`
- `CHECK (end_date >= start_date)` · `CHECK (deadline >= end_date)`
- **TRG `trg_ba_period_status_bu`** enumerates the legal transitions and rejects everything else. The previous version shipped the inverse: `open → locked` was allowed, `locked → closed` was allowed, and no `close()` existed at all, so `open → closed` was unreachable.
- **Locking cascades.** `BaPeriodService::lock()` sets every reviewed assessment to `locked` and seals a snapshot. Ratings need no update — the rating triggers read this period on every write. **The lock is enforced where the write happens, not where the lock is set.**

## 3.4 `ba_config` — one policy record per session

### What it is for
Every behavioural policy decision the school makes, scoped to an academic session. The previous version had five settings; the screens described about thirty-five, so most were hard-coded somewhere or simply absent.

### Why every threshold is a percentage

**This is the most important thing to understand about this table.** The earlier specification proposed *at-risk below 2.5/5* and *a consistency warning above an SD of 1.20*. Both are 5-point constants:

| Scale | `2.5` flags… |
|---|---|
| 1–5 | the bottom ~37% — as intended |
| 1–3 | almost nobody |
| 1–10 | almost everybody |

Stored as a **percentage of scale range**, the same *policy* travels across scales:

```
score threshold : absolute = scale.min + (percent / 100) × (scale.max − scale.min)
delta / spread  : absolute =              (percent / 100) × (scale.max − scale.min)
```

The defaults reproduce the familiar 5-point behaviour **exactly**: `37.50%` of a 1–5 range is 2.50 · `7.50%` of a range of 4 is 0.30 · `5.00%` is 0.20 · `30.00%` is 1.20.

### Columns — grouped by policy area

| Column | Type | Null | Meaning | Default |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | |
| `academic_session_id` | SMALLINT UNSIGNED | — | **UK.** FK → `sch_org_academic_sessions_jnt`, `ON DELETE RESTRICT`. **One config per session** | |
| `rating_scale_id` | BIGINT UNSIGNED | — | FK → `ba_rating_scales`, `ON DELETE RESTRICT`. Session default | |
| **— workflow —** | | | | |
| `is_review_required` | TINYINT(1) | — | **`0` ⇒ `submit()` goes straight to `reviewed`.** Small schools with no HOD layer are not forced through an empty queue | `1` |
| `auto_lock_on_approval` | TINYINT(1) | — | One UI action, **still two separately recorded events** | `0` |
| `autosave_interval_seconds` | SMALLINT UNSIGNED | — | Grid auto-save cadence | `30` |
| `min_coverage_percent` | DECIMAL(5,2) | — | **Below this proportion of a category's criteria rated, the category reports insufficient data rather than a number.** A category score from one criterion out of eight is not a measurement | `50.00` |
| **— scoring —** | | | | |
| `aggregation_method` | ENUM | — | `average`, `weighted_average`, `separate_display` (no overall number at all) | `weighted_average` |
| `normalisation_base` | DECIMAL(6,2) | — | The scale scores normalise to for integration | `100.00` |
| **— result integration —** | | | | |
| `is_result_integration_enabled` | TINYINT(1) | — | **OFF by default.** Behaviour contributes to the academic result only when deliberately enabled | `0` |
| `weightage_percent` | DECIMAL(4,1) | — | **Must be 5.0–20.0 when integration is on** | `10.0` |
| **— notification —** | | | | |
| `parent_notification_threshold` | ENUM | — | `minor`, `moderate`, `major`, `critical`. Minimum severity that notifies parents | `moderate` |
| `notify_parent` | TINYINT(1) | — | Recipient flag | `1` |
| `notify_class_teacher` | TINYINT(1) | — | Recipient flag | `1` |
| `notify_hod` | TINYINT(1) | — | Recipient flag | `0` |
| `notify_principal` | TINYINT(1) | — | Recipient flag | `0` |
| `notify_positive_incidents` | TINYINT(1) | — | **Recognition should travel as readily as reprimand** | `1` |
| `notification_channels_json` | JSON | ✔ | e.g. `["in_app","email","sms"]` | `NULL` |
| `principal_daily_digest` | TINYINT(1) | — | One summary rather than many alerts | `0` |
| **— escalation —** | | | | |
| `incident_escalation_count` | TINYINT UNSIGNED | — | **N negative incidents…** | `3` |
| `incident_escalation_window_days` | SMALLINT UNSIGNED | — | **…within this rolling window triggers escalation.** This is what makes repeat low-level behaviour visible before it becomes serious | `30` |
| **— incident policy —** | | | | |
| `incident_backdating_days` | TINYINT UNSIGNED | — | **A default, not a hard rule.** An admin may override it with an audited reason, because a genuinely late disclosure must remain recordable | `7` |
| `incident_desc_min_length` | SMALLINT UNSIGNED | — | Minimum description length | `20` |
| `incident_desc_max_length` | SMALLINT UNSIGNED | — | Maximum description length | `1000` |
| `witness_stmt_min_length` | SMALLINT UNSIGNED | — | Minimum statement length | `10` |
| `witness_stmt_max_length` | SMALLINT UNSIGNED | — | Maximum statement length | `500` |
| `freeze_witness_on_closure` | TINYINT(1) | — | **Witness records become read-only when the case closes.** A statement revisable afterwards has no evidential value | `1` |
| **— analytical thresholds, all percent of scale range —** | | | | |
| `at_risk_score_percent` | DECIMAL(5,2) | — | **= 2.50 on a 1–5 scale** | `37.50` |
| `at_risk_incident_count` | TINYINT UNSIGNED | — | Negative incidents in the term that also flag at-risk | `2` |
| `trend_improve_percent` | DECIMAL(5,2) | — | **= 0.30 on a 1–5 scale.** Above this delta, "improving" | `7.50` |
| `trend_stable_percent` | DECIMAL(5,2) | — | **= 0.20 on a 1–5 scale.** Within this, "stable" | `5.00` |
| `consistency_sd_percent` | DECIMAL(5,2) | — | **= 1.20 on a 1–5 scale.** Above this SD, a teacher-calibration prompt | `30.00` |
| `max_trend_lines` | TINYINT UNSIGNED | — | Chart clutter limit on Period Progress | `5` |
| **— privacy and retention —** | | | | |
| `allowed_demographics_json` | JSON | ✔ | **NULL = demographic analytics DISABLED.** Equity monitoring is legitimate; unrestricted demographic behavioural profiling is not | `NULL` |
| `min_group_size_for_analytics` | TINYINT UNSIGNED | — | **Small-cell suppression.** A "group" of two children is an identification, not a statistic | `5` |
| `audit_retention_months` | SMALLINT UNSIGNED | — | **Eligibility only — archival is an explicit administrative action, never a silent purge** | `36` |
| **— features —** | | | | |
| `is_comment_bank_enabled` | TINYINT(1) | — | Show the template insert control | `1` |
| `is_behaviour_points_enabled` | TINYINT(1) | — | **OFF. Incidents do not affect scores unless a school chooses it** | `0` |
| **— performance —** | | | | |
| `export_async_row_threshold` | INT UNSIGNED | — | Above this row count, an export is queued | `1000` |
| `export_expiry_days` | SMALLINT UNSIGNED | — | How long a generated file is kept | `7` |

### Keys & rules

| Constraint | What it enforces |
|---|---|
| `UNIQUE (academic_session_id, uq_guard)` | One config per session |
| `chk_ba_config_weightage` | `weightage_percent` 0–100, **and** 5.0–20.0 whenever integration is enabled |
| `chk_ba_config_percents` | All five analytical percentages between 0 and 100 |
| `chk_ba_config_escalation` | Count and window are both ≥ 1 |
| `chk_ba_config_desc_len` | Description max > min |
| `chk_ba_config_stmt_len` | Statement max > min |

## 3.5 `ba_framework_snapshots`

### What it is for

**The frozen behavioural framework a locked period was scored against.**

Without this table, an administrator adjusting a category weight in March silently rewrites what a September report card *meant*. A parent-facing historical grade has to stay explainable, and *"we changed the weights since then"* is not an explanation anyone can act on.

### Example row

```
period_id 30 · version 1
scale_json      : {"code":"5_POINT","min":1,"max":5,"levels":[…5 levels…]}
categories_json : [{"id":1,"code":"CLS_ENG","polarity":"positive","weight":100},…]
criteria_json   : [{"id":1,"code":"CLS_ENG_01","weight":12.5,"category_id":1},…]
class_map_json  : {"8":[1,2,3,4,5,6,7,8,9]}
config_json     : {"aggregation_method":"weighted_average","normalisation_base":100}
checksum        : 9f2c1a8b…
is_retrospective: 0
captured_at     : 2026-12-08 16:40
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `14` |
| `period_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_assessment_periods`, `ON DELETE RESTRICT` | `30` |
| `version` | SMALLINT UNSIGNED | — | **UK. Incremented when a reopened period is re-locked.** Version 1 is retained | `1` |
| `scale_json` | JSON | — | The scale and **every level** with label, value and order | `{"code":"5_POINT",…}` |
| `categories_json` | JSON | — | Every applicable category: id, code, name, polarity, weight, parent | `[{…}]` |
| `criteria_json` | JSON | — | Every applicable criterion: id, code, name, weight, category | `[{…}]` |
| `class_map_json` | JSON | ✔ | The class → category mapping in force | `{"8":[1,2,…]}` |
| `config_json` | JSON | — | Aggregation method, normalisation base, integration settings | `{…}` |
| `checksum` | CHAR(64) | — | **SHA-256 over the canonical JSON. This is what makes "a locked period recomputes identically" a TESTABLE assertion** rather than a hope | `9f2c1a8b…` |
| `is_retrospective` | TINYINT(1) | — | **An honesty flag.** A snapshot taken during migration for a period locked six months ago records *today's* framework, not the one in force then. **If a weight changed in between, that history is already unrecoverable** — and this flag says so in the data rather than assuming it away | `0` |
| `captured_by` | INT UNSIGNED | ✔ | FK → `sys_users`. **NULL = a system job** | `NULL` |
| `captured_at` | TIMESTAMP | — | When the snapshot was sealed | `2026-12-08 16:40` |

### Keys & rules

`UNIQUE (period_id, version)`. **No `updated_at`, no `deleted_at`.**

**TRG `trg_ba_snapshot_bu` / `_bd`** reject UPDATE and DELETE outright. A locked period depends on its snapshot; deleting one would make that period's history unreadable.

---

# SECTION 4 — Workflow Headers and Audit

## 4.1 `ba_assessments`

### What it is for
One teacher's evaluation of one class-section for one period. The header holds the workflow; the numbers live in `ba_assessment_ratings`.

### The lifecycle

```
                      ┌──── sendBack() ────┐
                      │                    │
 [DRAFT] ──submit()──▶ [SUBMITTED] ──approve()──▶ [REVIEWED] ──lock()──▶ [LOCKED]
    ▲                       │                         │                  terminal
    └──────── sendBack() ───┘◀────────────────────────┘

 When is_review_required = 0, submit() goes DRAFT → REVIEWED directly.
```

### Example row

```
period_id 30 · teacher_id 88 (Mrs Rao) · class_section_id 41 (8-A)
assessment_scope : class_teacher     subject_id : NULL
status           : locked
completion_percent : 100.00
last_autosaved_at  : 2026-12-04 15:22
submitted_by 88 · submitted_at 2026-12-04 15:40
approved_by 22 · approved_at 2026-12-05 09:10      ← who accepted the content
locked_by 3    · locked_at 2026-12-08 16:40        ← who made it final
sent_back_count : 1      last_sent_back_at : 2026-12-02 11:05
snapshot_id : 14
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4412` |
| `period_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_assessment_periods`, `ON DELETE RESTRICT` | `30` |
| `teacher_id` | INT UNSIGNED | — | **UK.** FK → `sch_employees`, `ON DELETE RESTRICT`. The assessor | `88` |
| `class_section_id` | INT UNSIGNED | — | **UK.** FK → `sch_class_section_jnt`, `ON DELETE RESTRICT` | `41` |
| `assessment_scope` | ENUM | — | **`class_teacher` or `subject_teacher`.** Makes "who rated this child, in what capacity" answerable, and lets a school later weight the class teacher's view differently without a schema change | `class_teacher` |
| `subject_id` | INT UNSIGNED | ✔ | FK → `sch_subjects`, `ON DELETE SET NULL`. **Required for subject scope** | `NULL` |
| `status` | ENUM | — | `draft`, `submitted`, `reviewed`, `locked` | `locked` |
| `completion_percent` | DECIMAL(5,2) | — | **Maintained on every save, so My Assessments and the dashboard read a number instead of counting half a million cells** | `100.00` |
| `last_autosaved_at` | TIMESTAMP | ✔ | Shown as "last saved" in the grid | `2026-12-04 15:22` |
| `submitted_by` / `submitted_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. Who submitted | `88` |
| `reviewed_by` / `reviewed_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. Retained name from the previous version | `22` |
| `approved_by` / `approved_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. **Who accepted the CONTENT** | `22` |
| `locked_by` / `locked_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. **Who made it FINAL** | `3` |
| `reviewer_remarks` | TEXT | ✔ | **Mandatory on send-back** | `Remarks contradict ratings…` |
| `sent_back_count` | TINYINT UNSIGNED | — | **Visible to the reviewer. A third send-back is a coaching signal, not a data problem** | `1` |
| `last_sent_back_at` | TIMESTAMP | ✔ | When it last bounced | `2026-12-02 11:05` |
| `snapshot_id` | BIGINT UNSIGNED | ✔ | FK → `ba_framework_snapshots`, `ON DELETE SET NULL`. The framework frozen at lock | `14` |

### Keys & rules

- `UNIQUE (teacher_id, class_section_id, period_id, uq_guard)` — **a teacher cannot hold two assessments for the same class-section and period.**
- `CHECK (completion_percent BETWEEN 0 AND 100)` · `CHECK` — subject scope requires a `subject_id`.
- **TRG `trg_ba_assessment_status_bu`** enforces the legal transitions and makes `locked` terminal.

> **Why `approved_by` and `locked_by` are separate columns.** *Approve* means "a supervisor accepts this content". *Lock* means "this is final and immutable". They are frequently different people with different accountability, and collapsing them makes "who approved this?" versus "who made it final?" unanswerable. A school wanting one click sets `auto_lock_on_approval`; **both events are still recorded distinctly.**

## 4.2 `ba_assessment_status_history`

### What it is for

**Who moved this, when, and why.** This is *not* a duplicate of `ba_audit_log` — the two answer different questions:

| Table | Answers |
|---|---|
| `ba_audit_log` | **"What changed"** — field-level, across ten entity types |
| `ba_assessment_status_history` | **"Who moved this, when, and why"** — workflow-level, one entity |

The Review Queue reads it to show how long a submission has waited and how often it has bounced. Deriving that from a generic field-level log means parsing it for a specific narrative, and every screen would do it slightly differently.

### Example rows

| from_status | to_status | action | remark | actor_id |
|---|---|---|---|---:|
| — | `draft` | `create` | — | 88 |
| `draft` | `submitted` | `submit` | — | 88 |
| `submitted` | `draft` | `send_back` | **Remarks contradict ratings for 4 students** | 22 |
| `draft` | `submitted` | `submit` | — | 88 |
| `submitted` | `reviewed` | `approve` | — | 22 |
| `reviewed` | `locked` | `lock` | — | 3 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `18820` |
| `assessment_id` | BIGINT UNSIGNED | — | FK → `ba_assessments`, `ON DELETE CASCADE` | `4412` |
| `from_status` | ENUM | ✔ | **NULL on creation** | `submitted` |
| `to_status` | ENUM | — | Where it moved to | `draft` |
| `action` | ENUM | — | `create`, `submit`, `approve`, `send_back`, `lock`, **`auto_publish`** (submitted when review is disabled) | `send_back` |
| `remark` | TEXT | ✔ | **Mandatory for `send_back`** | `Remarks contradict ratings` |
| `actor_id` | INT UNSIGNED | — | FK → `sys_users`, `ON DELETE RESTRICT`. Who did it | `22` |
| `ip_address` | VARBINARY(16) | ✔ | **`INET6_ATON` form — 16 bytes holds IPv6** | `0x…` |
| `changed_at` | TIMESTAMP(6) | — | **Microsecond precision: ordering within one transaction matters** | `2026-12-02 11:05:12.418` |

### Keys & rules

`CHECK (action <> 'send_back' OR remark IS NOT NULL)`.

**TRG `trg_ba_status_hist_bu` / `_bd`** — append-only. No update, no delete.

## 4.3 `ba_audit_log`

### What it is for
The immutable field-level change record. **Insert-only.**

### Example rows

| entity_type | entity_id | field_name | old_value | new_value | reason |
|---|---:|---|---|---|---|
| `assessment_rating` | 210441 | `rating_level_id` | `3` | `4` | — |
| `incident` | 417 | `severity` | `moderate` | `major` | **Investigation showed physical contact** |
| `period` | 30 | `status` | `locked` | `closed` | **Late disclosure needs a back-dated entry** |
| **`witness_read`** | 88 | `statement` | — | — | — |
| **`export`** | 12 | `Student Scores` | — | `412 rows` | — |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `992104` |
| `entity_type` | ENUM | — | **Ten values:** `assessment`, `assessment_rating`, `incident`, `intervention`, `witness`, **`witness_read`**, `config`, `framework`, `period`, **`export`** | `incident` |
| `entity_id` | BIGINT UNSIGNED | — | The row affected | `417` |
| `field_name` | VARCHAR(64) | — | The column changed, **or the read action for read events** | `severity` |
| `old_value` / `new_value` | VARCHAR(500) | ✔ | Before and after | `moderate` / `major` |
| `reason` | VARCHAR(500) | ✔ | **Required for severity escalation and period reopen.** An audit row saying *what* changed without *why* is half a record | `Investigation showed contact` |
| `changed_by` | INT UNSIGNED | — | FK → `sys_users`, `ON DELETE RESTRICT` | `3` |
| `ip_address` | VARBINARY(16) | ✔ | `INET6_ATON` form | `0x…` |
| `user_agent` | VARCHAR(255) | ✔ | Browser or CLI signature | `Mozilla/5.0 …` |
| `changed_at` | TIMESTAMP(6) | — | Microsecond precision | `2026-11-14 10:22:07.418` |

### Keys & rules

**TRG `trg_ba_audit_bu` / `_bd`** — the audit log is insert-only and cannot be deleted. Use the archival process.

> **Three of the ten entity types are READ events, not writes.** `witness_read` and `export` record disclosures of sensitive student information to a person. **A disclosure nobody can reconstruct is not a controlled disclosure.** The previous version audited three entity types and recorded no configuration, framework, period or export activity at all — precisely the activities the screens expected to be discoverable.

## 4.4 `ba_audit_log_archive`

### What it is for
Identical shape to `ba_audit_log`. Rows move here when an administrator **explicitly** runs the archival job for records older than `audit_retention_months`.

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK.** The original audit id, preserved | `880214` |
| `entity_type` | VARCHAR(30) | — | **VARCHAR, not ENUM** — so a later ENUM change cannot invalidate archived history | `incident` |
| `entity_id` | BIGINT UNSIGNED | — | The row affected | `417` |
| `field_name` | VARCHAR(64) | — | The column changed | `severity` |
| `old_value` / `new_value` / `reason` | VARCHAR(500) | ✔ | As archived | `moderate` / `major` |
| `changed_by` | INT UNSIGNED | — | Who made the change | `3` |
| `ip_address` / `user_agent` | VARBINARY(16) / VARCHAR(255) | ✔ | As archived | `0x…` |
| `changed_at` | TIMESTAMP(6) | — | The original timestamp | `2023-11-14 10:22:07.418` |
| `archived_at` | TIMESTAMP | — | When it was moved here | `2026-12-01 02:00` |
| `archived_by` | INT UNSIGNED | — | **The administrator who ran the archival** | `3` |

### Keys & rules

> **There is no scheduled purge.** Deleting a compliance record because a timer expired is not a retention policy; it is data loss with a cron entry. Archival is an administrative act, it is itself audited, and the rows stay queryable.

---

# SECTION 5 — Core Transactions

## 5.1 `ba_assessment_ratings` — the core fact table

### What it is for

**One row per grid cell: student × criterion × assessment.** Roughly **460,000 rows per tenant per session** (2,000 students × 58 criteria × 4 periods). Every behavioural number in the system traces back to this table, and every reporting path must reach it through the computed cache rather than directly.

### Example rows — part of one grid

| assessment_id | student_id | criterion_id | rating_level_id | rating_value | remark |
|---:|---:|---|---:|---:|---|
| 4412 | 4471 | `CLS_ENG_01` | 4 (Very Good) | **4.00** | — |
| 4412 | 4471 | `CLS_ENG_04` | 2 (Needs Improvement) | **2.00** | Homework often late |
| 4412 | 4471 | `DISRUPT_01` | 5 (Outstanding) | **5.00** | *(worst on a negative category)* |
| 4412 | 4472 | `CLS_ENG_01` | NULL | **NULL** | — *(not yet rated)* |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `210441` |
| `assessment_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_assessments`, `ON DELETE CASCADE` | `4412` |
| `student_id` | INT UNSIGNED | — | **UK.** FK → `std_students`, `ON DELETE RESTRICT` | `4471` |
| `criterion_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_criteria`, `ON DELETE RESTRICT` | `4` |
| `rating_level_id` | BIGINT UNSIGNED | ✔ | FK → `ba_rating_levels`, `ON DELETE SET NULL`. **The level selected; NULL = not yet rated** | `4` |
| `rating_value` | DECIMAL(4,2) | ✔ | **FROZEN. The number the teacher meant, captured at save** | `4.00` |
| `remark` | VARCHAR(500) | ✔ | Optional per-criterion remark | `Homework often late` |
| `rated_at` | TIMESTAMP | ✔ | When the cell was last given a value | `2026-12-04 15:20` |

### Keys & rules

- `UNIQUE (assessment_id, student_id, criterion_id, uq_guard)` — **one rating per cell.** Re-entry updates.
- `CHECK (rating_value IS NULL OR rating_value >= 0)` · `CHECK (rating_level_id IS NULL OR rating_value IS NOT NULL)` — **you cannot pick a level without storing its value.**
- `idx_ba_rating_avg (student_id, criterion_id, rating_value)` — the multi-teacher averaging index.
- **TRG `trg_ba_rating_bi` / `_bu` / `_bd`** — no write when the assessment is `locked`, or when its period is `closed` or `locked`. **This is the lock cascade, and it is the single most important trigger in the file.**

> ### Why `rating_value` exists — the defect it fixes
>
> The previous version stored only `rating_level_id`, with `ON DELETE SET NULL`. Delete a rating level and **every rating that used it silently became "not rated"** — a locked, published assessment quietly lost data, and the next recomputation produced different numbers with no error anywhere.
>
> Storing the number makes a rating **self-describing**:
> - a locked period recomputes identically forever;
> - the level may be renamed, reordered, deactivated or deleted without touching history;
> - the averaging query reads one column instead of joining to levels 460,000 times.
>
> `rating_level_id` is kept for display ("Very Good") and for editability while the period is open.

> **An unrated cell contributes to neither numerator nor denominator.** A NULL `rating_value` means *"not observed"*, never zero. Treating it as zero punishes a student for a teacher's omission.

## 5.2 `ba_student_remarks`

### What it is for
One holistic remark per student per assessment. **Distinct from the per-criterion remark on a rating:** that one explains a cell, this one describes the child.

### Example row

```
assessment_id 4412 · student_id 4471
remark_text : "Ravi has had a mixed term. He engages readily in discussion and is
               unfailingly courteous, but homework is frequently late. The agreed
               diary check with his parents has begun to help."
comment_template_id : 4      ← which template seeded it (analytics only)
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `8812` |
| `assessment_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_assessments`, `ON DELETE CASCADE` | `4412` |
| `student_id` | INT UNSIGNED | — | **UK.** FK → `std_students`, `ON DELETE RESTRICT` | `4471` |
| `remark_text` | TEXT | — | **The teacher's own words.** The bank may have seeded it; the text is theirs | `Ravi has had a mixed term…` |
| `comment_template_id` | BIGINT UNSIGNED | ✔ | FK → `ba_comment_bank`, `ON DELETE SET NULL`. **Analytics only** — which template was used, never what is displayed | `4` |

### Keys & rules

`UNIQUE (assessment_id, student_id, uq_guard)` — one holistic remark per student per assessment.

**TRG `trg_ba_remark_bu`** — no update when the parent assessment is `locked`.

## 5.3 `ba_computed_scores` — per-category cache

### What it is for
**CACHE.** The computed score for one student, one category, one period. Reporting reads this; it never aggregates raw ratings.

### Example rows — one student, one period

| category_id | numeric_score | normalised_score | grade | criteria_rated | criteria_applicable | teacher_count | is_insufficient_data |
|---|---:|---:|---|---:|---:|---:|:---:|
| Classroom Engagement | 3.625 | 65.625 | `B` | 8 | 8 | 3 | 0 |
| Respect and Responsibility | 4.250 | 81.250 | `A` | 8 | 8 | 3 | 0 |
| Disruptive Behaviours *(negative, inverted)* | 4.000 | 75.000 | `A` | 7 | 7 | 2 | 0 |
| Leadership and Initiative | **NULL** | NULL | NULL | 1 | 6 | 1 | **1** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `72001` |
| `student_id` | INT UNSIGNED | — | **UK.** FK → `std_students`, `ON DELETE RESTRICT` | `4471` |
| `category_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_categories`, `ON DELETE RESTRICT` | `1` |
| `period_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_assessment_periods`, `ON DELETE RESTRICT` | `30` |
| `numeric_score` | DECIMAL(6,3) | ✔ | The category score. **NULL when `is_insufficient_data = 1`** | `3.625` |
| `normalised_score` | DECIMAL(6,3) | ✔ | **0 … `normalisation_base`. Scale-independent**, so two classes on different scales can be compared | `65.625` |
| `grade` | VARCHAR(5) | ✔ | Mapped from the scale's level bands | `B` |
| `criteria_rated` | SMALLINT UNSIGNED | — | **Coverage numerator** | `8` |
| `criteria_applicable` | SMALLINT UNSIGNED | — | **Coverage denominator** | `8` |
| `teacher_count` | TINYINT UNSIGNED | — | **How many teachers contributed.** Lets a report say "averaged across 3 teachers" | `3` |
| `is_insufficient_data` | TINYINT(1) | — | **Set when coverage is below `min_coverage_percent`.** Reporting "insufficient data" is better than reporting a number, because a number invites comparison | `0` |
| `score_run_id` | BIGINT UNSIGNED | ✔ | FK → `ba_score_runs`, added in the deferred block. **Provenance** | `991` |
| `computed_at` | TIMESTAMP | — | When this figure was produced | `2026-12-08 16:42` |

### Keys & rules

- `UNIQUE (student_id, category_id, period_id, uq_guard)`
- `CHECK (numeric_score IS NULL OR numeric_score >= 0)` · `CHECK (is_insufficient_data = 0 OR numeric_score IS NULL)`

> **`overall_score` is NOT in this table.** The previous version stored the overall "on the first category row per student-period". That makes the overall depend on row ordering, breaks when the first category is deactivated, and forces every overall query to guess which row is authoritative. The overall now has its own table.

## 5.4 `ba_computed_overall`

### What it is for
**One row per student per period: the overall behavioural standing**, with the trend and at-risk flag computed once and read everywhere.

### Example row

```
student_id 4471 · period_id 30
overall_score    : 3.958      normalised_score : 73.958
overall_grade    : B
categories_scored: 8          ← one category had insufficient data
previous_overall : 3.604
score_delta      : 0.354      ← above 7.5% of range (0.30) ⇒ improving
trend            : improving
is_at_risk       : 0
at_risk_reason   : NULL
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4471030` |
| `student_id` | INT UNSIGNED | — | **UK.** FK → `std_students`, `ON DELETE RESTRICT` | `4471` |
| `period_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_assessment_periods`, `ON DELETE RESTRICT` | `30` |
| `overall_score` | DECIMAL(6,3) | ✔ | **NULL when `aggregation_method = 'separate_display'`** — some schools deliberately publish no single number | `3.958` |
| `normalised_score` | DECIMAL(6,3) | ✔ | **What result integration consumes** | `73.958` |
| `overall_grade` | VARCHAR(5) | ✔ | Mapped grade | `B` |
| `categories_scored` | SMALLINT UNSIGNED | — | How many categories produced a number | `8` |
| `previous_overall` | DECIMAL(6,3) | ✔ | **Previous period, same student** | `3.604` |
| `score_delta` | DECIMAL(6,3) | ✔ | `overall − previous_overall` | `0.354` |
| `trend` | ENUM | — | `improving`, `stable`, `declining`, **`no_baseline`** (no previous period to compare) | `improving` |
| `is_at_risk` | TINYINT(1) | — | **The composite rule, evaluated at compute time:** score below `at_risk_score_percent` of range **OR** at least `at_risk_incident_count` negative incidents this term | `0` |
| `at_risk_reason` | VARCHAR(255) | ✔ | **Which limb fired — score, incidents, or both.** "At risk" without a reason is not actionable | `NULL` |
| `score_run_id` | BIGINT UNSIGNED | ✔ | FK → `ba_score_runs`. Provenance | `991` |
| `computed_at` | TIMESTAMP | — | When produced | `2026-12-08 16:42` |

### Keys & rules

`UNIQUE (student_id, period_id, uq_guard)`.

> **`previous_overall`, `score_delta` and `trend` are denormalised on purpose.** Period Progress, Class Analysis, the dashboard and the Student Report all need the same delta. Computing it in four places produces four slightly different answers the first time somebody changes a threshold. These are written by the same score run that writes the score, so they cannot drift.

## 5.5 `ba_score_runs`

### What it is for

**Provenance for every score computation.** A behavioural score reaches a report card and then a parent-teacher meeting. When a parent asks how it was arrived at, *"the system calculated it"* is not an answer.

### Example row

```
period_id 30
trigger_source    : period_locked      triggered_by : NULL (system)
snapshot_id 14 · snapshot_checksum 9f2c1a8b…
students_processed 40 · scores_written 361
status            : completed_with_warnings
warning_json      : {"insufficient_data":[{"student":4471,"category":5}]}
started_at 2026-12-08 16:40:11.204 · finished_at 16:40:16.042 · duration_ms 4838
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `991` |
| `period_id` | BIGINT UNSIGNED | — | FK → `ba_assessment_periods`, `ON DELETE CASCADE` | `30` |
| `trigger_source` | ENUM | — | `assessment_approved`, `period_locked`, `manual_admin`, `migration`, `scheduled` | `period_locked` |
| `triggered_by` | INT UNSIGNED | ✔ | FK → `sys_users`. **NULL = a system job** | `NULL` |
| `snapshot_id` | BIGINT UNSIGNED | ✔ | FK → `ba_framework_snapshots`. **NULL for an open period** | `14` |
| `snapshot_checksum` | CHAR(64) | ✔ | **Copied at run time. This is what makes "a locked period recomputes identically" testable** — recompute, compare, and report a divergence rather than silently overwriting a published score | `9f2c1a8b…` |
| `students_processed` | INT UNSIGNED | — | How many students | `40` |
| `scores_written` | INT UNSIGNED | — | How many score rows | `361` |
| `status` | ENUM | — | `running`, `completed`, `failed`, **`completed_with_warnings`** | `completed_with_warnings` |
| `warning_json` | JSON | ✔ | **e.g. which students had insufficient data.** A warning count is not actionable; a list is | `{"insufficient_data":[…]}` |
| `error_message` | TEXT | ✔ | Failure detail | `NULL` |
| `started_at` / `finished_at` | TIMESTAMP(3) | — / ✔ | Millisecond precision | `16:40:11.204` |
| `duration_ms` | INT UNSIGNED | ✔ | How long it took | `4838` |

### Keys & rules
Insert-only in practice — no `updated_at`, no `deleted_at`.

## 5.6 `ba_incidents`

### What it is for
Behavioural events, **positive or negative**, recorded independently of assessment periods — with a lifecycle, so the module records not just that something happened but **what the school did about it.**

### The lifecycle

```
[OPEN] ──▶ [UNDER_REVIEW] ──▶ [ACTION_TAKEN] ──▶ [RESOLVED] ──▶ [CLOSED]
   └──────────────┴──────────────────┴────────────────┴──────────▶ [CANCELLED]
                                                          (reason mandatory)

A POSITIVE incident may go open → closed directly.
```

### Example row

```
incident_no   : INC-2026-000417
student_id 4471 · reported_by 88
category_id 7 (Aggressive or Bullying) · criterion_id 42
incident_date 2026-11-12 · incident_time 11:40
incident_type : negative_incident
severity      : major        original_severity : moderate    ← escalated
description   : "Shouted at a classmate in the main corridor and pushed a door
                 hard enough to crack the panel. Two pupils witnessed it."
location      : corridor
status        : closed
is_follow_up_required 1 · follow_up_date 2026-12-10
resolved_by 31 · resolved_at 2026-11-28 · closed_at 2026-12-02
closure_notes : "Restorative conversation held. No recurrence in three weeks."
severity_escalated_at 2026-11-13 09:15
is_notified   : 1
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `417` |
| `incident_no` | VARCHAR(20) | — | **UK.** `INC-YYYY-NNNNNN`. **DEFAULT is empty string so the trigger can fill it under STRICT mode.** A human reference people can quote in a letter or a meeting | `INC-2026-000417` |
| `student_id` | INT UNSIGNED | — | FK → `std_students`, `ON DELETE RESTRICT`. **IMMUTABLE** | `4471` |
| `reported_by` | INT UNSIGNED | — | FK → `sch_employees`, `ON DELETE RESTRICT` | `88` |
| `category_id` | BIGINT UNSIGNED | ✔ | FK → `ba_categories`, `ON DELETE SET NULL`. Optional link to the framework | `7` |
| `criterion_id` | BIGINT UNSIGNED | ✔ | FK → `ba_criteria`, `ON DELETE SET NULL` | `42` |
| `incident_date` | DATE | — | **IMMUTABLE. Not in the future. Backdating limited by config** | `2026-11-12` |
| `incident_time` | TIME | ✔ | Optional. **Feeds time-of-day pattern analysis** | `11:40` |
| `incident_type` | ENUM | — | **IMMUTABLE.** `positive_reinforcement` or `negative_incident` | `negative_incident` |
| `severity` | ENUM | ✔ | `minor`, `moderate`, `major`, `critical`. **Required for negative, forbidden for positive. May ESCALATE only** | `major` |
| `description` | TEXT | — | **IMMUTABLE.** Length bounded by config | `Shouted at a classmate…` |
| `location` | ENUM | — | 12 values: `classroom`, `playground`, `corridor`, `lab`, `transport`, `canteen`, `library`, **`assembly`**, **`sports_ground`**, **`hostel`**, **`online`**, `other`. The last four were added because cyber-bullying and off-campus incidents were previously forced into "other", where they vanished from hotspot analysis | `corridor` |
| `status` | ENUM | — | `open`, `under_review`, `action_taken`, `resolved`, `closed`, `cancelled` | `closed` |
| `intervention_notes` | TEXT | ✔ | Free text. **The tracked cases live in the junction table** | `NULL` |
| `is_follow_up_required` | TINYINT(1) | — | **Mandatory for `major` and `critical`** | `1` |
| `follow_up_date` | DATE | ✔ | **The NEXT follow-up. The history is in `ba_incident_followups`** | `2026-12-10` |
| `resolved_by` / `resolved_at` | INT UNSIGNED / TIMESTAMP | ✔ | FK → `sch_employees`. Who resolved it | `31` |
| `closure_notes` | TEXT | ✔ | **Mandatory to close.** "Resolved" with an empty explanation is how a discipline record becomes useless a year later | `Restorative conversation held…` |
| `closed_at` | TIMESTAMP | ✔ | When signed off | `2026-12-02` |
| `cancellation_reason` | VARCHAR(500) | ✔ | **Mandatory to cancel** | `NULL` |
| `severity_escalated_at` | TIMESTAMP | ✔ | **When severity was raised — the one permitted core-field change** | `2026-11-13 09:15` |
| `original_severity` | ENUM | ✔ | **What it was first logged as** | `moderate` |
| `is_backdated_override` | TINYINT(1) | — | An admin overrode the backdating window | `0` |
| `is_notified` | TINYINT(1) | — | **Denormalised convenience for list rendering. `ba_notifications` is authoritative** | `1` |

### Keys & rules

| Constraint | What it enforces |
|---|---|
| `UNIQUE (incident_no, uq_guard)` | One incident number |
| `chk_ba_incident_severity` | **Negative requires severity; positive forbids it.** Enforced by the database, not by hope |
| `chk_ba_incident_closure` | Closing requires a closure note of at least 5 characters |
| `chk_ba_incident_cancel` | Cancelling requires a reason of at least 5 characters |
| `chk_ba_incident_followup` | `is_follow_up_required = 1` requires a `follow_up_date` |
| `idx_ba_incident_escal (student_id, incident_type, incident_date)` | The escalation window count |
| `idx_ba_incident_hotspot (incident_date, location)` | Hotspot analysis |

**Triggers:**

- **`trg_ba_incident_no_bi`** generates `INC-YYYY-NNNNNN` when the application has not supplied one.
- **`trg_ba_incident_bu`** rejects any change to `student_id`, `incident_date`, `incident_type`, `description` or `location`, and refuses to reopen a cancelled incident.

> ### Immutability, and its one exception
>
> Core facts are frozen after creation. **Severity is the exception**, and deliberately so: investigation frequently shows that an incident logged as `moderate` was in fact `major`, and forcing cancel-and-re-raise there would **destroy the witness statements and interventions already attached.**
>
> So severity may be **escalated — never reduced** — by an Admin or Principal, with a reason, an audit row carrying old and new values, and a re-evaluation of the notification threshold. The trigger permits the column to move; the service enforces who may do it and that the new value is higher.
>
> **A materially wrong incident is cancelled with a reason and re-raised.** Records are never edited into a different truth and never hard-deleted.

---

# SECTION 6 — Incident Detail

## 6.1 `ba_incident_witnesses_jnt`

### What it is for
Who saw it, and **what they said**.

### Example rows

| witness_type | witness_id | statement | is_confidential | frozen_at |
|---|---:|---|:---:|---|
| `student` | 4490 | "Ravi shouted at Aman and then pushed the door very hard." | 0 | 2026-12-02 |
| `staff` | 91 | "I was 10 metres away. I heard raised voices and saw the door swing." | 0 | 2026-12-02 |
| `student` | 4502 | *(restricted — Principal and Counsellor only)* | **1** | 2026-12-02 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `881` |
| `incident_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_incidents`, `ON DELETE CASCADE` | `417` |
| `witness_type` | ENUM | — | **UK.** `student` or `staff` | `student` |
| `witness_id` | INT UNSIGNED | — | **UK. Polymorphic — `std_students.id` or `sch_employees.id` depending on type, so NO database foreign key.** The application validates it against the correct master | `4490` |
| `statement` | VARCHAR(500) | ✔ | **The factual account. RESTRICTED READ** — see below | `Ravi shouted at Aman…` |
| `is_confidential` | TINYINT(1) | — | **Narrows access further, to Principal and Counsellor only** | `0` |
| `statement_recorded_by` | INT UNSIGNED | ✔ | FK → `sch_employees`, `ON DELETE SET NULL`. **Who took the statement** | `91` |
| `statement_recorded_at` | TIMESTAMP | ✔ | When | `2026-11-12 13:20` |
| `frozen_at` | TIMESTAMP | ✔ | **Set on case closure when `freeze_witness_on_closure` is on** | `2026-12-02` |

### Keys & rules

- `UNIQUE (incident_id, witness_type, witness_id, uq_guard)` — **one witness record per person per incident.**
- `CHECK (statement IS NULL OR CHAR_LENGTH(statement) BETWEEN 10 AND 500)`.
- **TRG `trg_ba_witness_bu`** — a frozen witness record rejects further writes.
- **The subject student cannot witness their own incident** — enforced in `BaWitnessService`, which is the only place that knows the incident's `student_id` at insert time.

> ### Witness statements are the most sensitive field in the module
>
> **The previous version declared this table with `witness_type` and `witness_id` and NO COLUMN TO HOLD A STATEMENT** — while the requirements specified statement length limits and who may read them. The requirement had nowhere to live, so it could not be built. This is the clearest single example of the pattern this schema revision exists to correct.
>
> Three controls now apply:
>
> | Control | How |
> |---|---|
> | **Access** | `viewStatement()` is a separate policy check from `view()`. HOD, Counsellor and Principal only. A class teacher may see *that* there were three witnesses and may not see *what they said* |
> | **Audited on read** | Every statement read writes `ba_audit_log` with `entity_type = 'witness_read'`. **A disclosure nobody can reconstruct is not a controlled disclosure** |
> | **Frozen on closure** | `frozen_at` plus a trigger. A statement revisable after the case concludes has no evidential value |
>
> **On the polymorphic `witness_id`:** the alternative is two nullable FK columns plus a CHECK that exactly one is populated — more correct, but it makes every query branch. This is a documented trade; revisit if witness data ever needs bulk joining.

## 6.2 `ba_incident_intervention_jnt` — interventions as tracked cases

### What it is for

**What the school actually did, with an owner, a due date and an outcome.** The previous version stored an incident id, an intervention id and a note — nothing else. An intervention nobody owns and nothing tracks is a checkbox, not a response, and *"incidents go nowhere"* is the single business problem this module exists to solve.

### The lifecycle

```
[ASSIGNED] ──▶ [IN_PROGRESS] ──▶ [COMPLETED]      completed_on + completion_notes required
     └──────────────┴──────────▶ [CANCELLED]      cancellation_reason required
```

### Example row

```
incident_id 417 · intervention_id 9 (Counselling Referral)
assigned_to 31 (Mrs Nair, counsellor) · assigned_by 22
scheduled_date 2026-11-26        ← incident date + default_due_days (14)
status         : completed
started_at 2026-11-15 10:00 · completed_on 2026-11-26
completion_notes : "Three sessions held. Ravi identified the trigger himself and
                    agreed a step-away strategy with his form tutor."
outcome        : effective
notes          : "Referred same day given the door damage."
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1120` |
| `incident_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_incidents`, `ON DELETE CASCADE` | `417` |
| `intervention_id` | BIGINT UNSIGNED | — | **UK.** FK → `ba_interventions`, `ON DELETE RESTRICT` | `9` |
| `assigned_to` | INT UNSIGNED | ✔ | FK → `sch_employees`, `ON DELETE SET NULL`. **Mandatory when the master sets `requires_owner`** | `31` |
| `assigned_by` | INT UNSIGNED | ✔ | FK → `sch_employees`, `ON DELETE SET NULL`. Who assigned it | `22` |
| `scheduled_date` | DATE | ✔ | **The due date. Defaults to incident date + the master's `default_due_days`** | `2026-11-26` |
| `status` | ENUM | — | `assigned`, `in_progress`, `completed`, `cancelled` | `completed` |
| `started_at` | TIMESTAMP | ✔ | When work actually began | `2026-11-15 10:00` |
| `completed_on` | DATE | ✔ | **Mandatory to complete** | `2026-11-26` |
| `completion_notes` | TEXT | ✔ | **Mandatory to complete, minimum 5 characters** | `Three sessions held…` |
| `cancellation_reason` | VARCHAR(500) | ✔ | **Mandatory to cancel, minimum 5 characters** | `NULL` |
| `outcome` | ENUM | — | `effective`, `partially_effective`, `not_effective`, **`not_assessed`** (the default). **Prompted at completion, optional to record** | `effective` |
| `notes` | VARCHAR(500) | ✔ | Context recorded at assignment time | `Referred same day…` |

### Keys & rules

- `UNIQUE (incident_id, intervention_id, uq_guard)`
- `chk_ba_ii_completed` — **completing requires both a date and a note.**
- `chk_ba_ii_cancelled` — **cancelling requires a reason.**
- `idx_ba_ii_worklist (assigned_to, status, scheduled_date)` — the owner worklist and the overdue sweep.
- `idx_ba_ii_interv (intervention_id, outcome)` — effectiveness analytics.

> **Overdue is DERIVED, never stored:** `status IN ('assigned','in_progress') AND scheduled_date < CURDATE()`. A stored `is_overdue` flag would need a nightly job to keep it true, and **a flag that depends on a job is a flag that is wrong between runs.** `v_ba_open_interventions` exposes it.

> **Why `outcome` matters more than it looks.** Over two sessions it makes *"which interventions actually work in THIS school"* answerable — schools apply detention because they always have. It is confounded by severity and by which students receive which intervention, so it must be presented as a prompt for discussion, **never as a causal claim.**

## 6.3 `ba_intervention_progress`

### What it is for
**Append-only progress log** for an applied intervention. Progress had nowhere to live in the previous version: there was one `notes` column, so the second update overwrote the first.

### Example rows

| progress_date | note | status_at_entry | recorded_by |
|---|---|---|---:|
| 2026-11-15 | First session. Ravi defensive; mostly listening. | `in_progress` | 31 |
| 2026-11-20 | Second session. Identified the trigger himself. | `in_progress` | 31 |
| 2026-11-26 | Third session. Agreed a step-away strategy with his tutor. | `completed` | 31 |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `3312` |
| `incident_intervention_id` | BIGINT UNSIGNED | — | FK → `ba_incident_intervention_jnt`, `ON DELETE CASCADE` | `1120` |
| `progress_date` | DATE | — | The date this entry is about | `2026-11-20` |
| `note` | TEXT | — | **What happened. Minimum 5 characters** | `Second session. Identified…` |
| `status_at_entry` | ENUM | — | **The intervention's status when this note was written.** Lets the timeline be read without inferring state | `in_progress` |
| `recorded_by` | INT UNSIGNED | — | FK → `sch_employees`, `ON DELETE RESTRICT` | `31` |
| `recorded_at` | TIMESTAMP(3) | — | Millisecond precision | `2026-11-20 14:02:11.420` |

### Keys & rules

`CHECK (CHAR_LENGTH(note) >= 5)`.

**TRG `trg_ba_progress_bu` / `_bd`** — append-only. **What a school actually did, step by step, is exactly the part that must accumulate.**

## 6.4 `ba_incident_followups`

### What it is for
**Append-only follow-up log.** The previous version had one `follow_up_notes TEXT` column on the incident, and the audit recorded that **each new note overwrote the last.**

### Example rows

| followup_date | note | outcome | next_followup_date |
|---|---|---|---|
| 2026-11-19 | Checked with form tutor. No further incidents. | `improved` | 2026-11-26 |
| 2026-11-26 | Spoke to Ravi and to Aman separately. Both settled. | `improved` | 2026-12-10 |
| 2026-12-10 | Three weeks clear. Closing the follow-up cycle. | `improved` | NULL |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `4410` |
| `incident_id` | BIGINT UNSIGNED | — | FK → `ba_incidents`, `ON DELETE CASCADE` | `417` |
| `followup_date` | DATE | — | When this follow-up happened | `2026-11-26` |
| `note` | TEXT | — | **What was found. Minimum 5 characters** | `Spoke to Ravi and to Aman…` |
| `outcome` | ENUM | — | `improved`, `no_change`, `deteriorated`, `not_assessed` | `improved` |
| `next_followup_date` | DATE | ✔ | **Written back to `ba_incidents.follow_up_date` by the service** | `2026-12-10` |
| `recorded_by` | INT UNSIGNED | — | FK → `sch_employees`, `ON DELETE RESTRICT` | `31` |
| `recorded_at` | TIMESTAMP(3) | — | Millisecond precision | `2026-11-26 16:40:02.118` |

### Keys & rules

`CHECK (CHAR_LENGTH(note) >= 5)`.

**TRG `trg_ba_followup_bu` / `_bd`** — append-only. **The history of what a school did about a child's behaviour is the part that gets read in a disciplinary review, a parent dispute or a transfer certificate two years later.**

## 6.5 `ba_incident_attachments`

### What it is for
**Relational evidence**, replacing the `attachments_json` column of the previous version.

### Example rows

| original_name | mime_type | file_size_bytes | caption | is_staff_only |
|---|---|---:|---|:---:|
| `corridor-door-damage.jpg` | `image/jpeg` | 184,320 | Cracked panel, lower right | 0 |
| `witness-statements-signed.pdf` | `application/pdf` | 92,118 | Both statements, countersigned | **1** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `771` |
| `incident_id` | BIGINT UNSIGNED | — | FK → `ba_incidents`, `ON DELETE CASCADE` | `417` |
| `media_id` | BIGINT UNSIGNED | ✔ | **Reference into Prime-AI media storage.** The bytes live there, not here | `9912` |
| `file_path` | VARCHAR(500) | ✔ | **Fallback path when media storage is not in use** | `NULL` |
| `original_name` | VARCHAR(255) | — | The filename as uploaded | `corridor-door-damage.jpg` |
| `mime_type` | VARCHAR(100) | — | Content type | `image/jpeg` |
| `file_size_bytes` | INT UNSIGNED | — | Size | `184320` |
| `caption` | VARCHAR(255) | ✔ | What the evidence shows | `Cracked panel, lower right` |
| `is_staff_only` | TINYINT(1) | — | **Evidence on a case involving several students is visible to staff roles only, never to any parent** | `0` |
| `uploaded_by` | INT UNSIGNED | — | FK → `sch_employees`, `ON DELETE RESTRICT` | `91` |
| `uploaded_at` | TIMESTAMP | — | When | `2026-11-12 13:40` |

### Keys & rules

`CHECK (media_id IS NOT NULL OR file_path IS NOT NULL)` — **an attachment row must point at something.**

> **Why a table rather than JSON.** A JSON array cannot be indexed, counted, permission-checked per file, or reconciled against media storage when a file is purged. *"How many incidents have photographic evidence?"* and *"which evidence files reference a media id that no longer exists?"* should be queries, not scans of every incident row.

---

# SECTION 7 — Operations

## 7.1 `ba_notifications` — the outbox

### What it is for

**The most important addition in this version.** The audit finding it answers was blunt:

> *"Severe-incident parent notification is entirely absent. A grep for `Notification|notify|dispatch|event(` across the application returns zero. `parent_notification_threshold` is dead config and `is_notified` is never written."*

The requirement was in the specification, in the requirements document, and on the Configuration screen. **It was never built, and nothing noticed — because a boolean gave the obligation nowhere to live.**

A boolean can express *"we tried and it worked"*. It cannot express *"we tried three times, the parent's number is wrong, and nobody knows"* — **and that is the state that matters.** A school believing a parent was informed about a serious incident, when they were not, is worse than a school knowing the message failed.

### Example rows — one major incident

| event_type | recipient_type | recipient_id | channel | status | failure_reason |
|---|---|---:|---|---|---|
| `incident_severity` | `parent` | 4471 | `sms` | **`failed`** | Invalid mobile number on file |
| `incident_severity` | `parent` | 4471 | `email` | `sent` | — |
| `incident_severity` | `employee` | 88 | `in_app` | `sent` | — |
| `incident_escalation` | `role` | — (`principal`) | `email` | `sent` | — |
| `incident_severity` | `parent` | 4471 | `sms` | **`suppressed`** | Duplicate — already notified |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `7781` |
| `event_type` | ENUM | — | 11 values: `incident_severity`, `incident_escalation`, `incident_critical`, `positive_incident`, `assessment_deadline`, `assessment_overdue`, `intervention_assigned`, `intervention_overdue`, `review_pending`, `daily_digest`, `export_ready` | `incident_severity` |
| `entity_type` | ENUM | — | `incident`, `assessment`, `intervention`, `period`, `export`, `student` | `incident` |
| `entity_id` | BIGINT UNSIGNED | — | Which record it concerns | `417` |
| `dedupe_key` | VARCHAR(120) | — | **UK** (with channel and `uq_guard`). `event_type + entity + recipient + severity-at-trigger`. **Re-saving an incident cannot produce a second alert, and a retry storm or a double-clicked button cannot send a parent the same message twice** | `inc:417:sev:parent:4471:major` |
| `recipient_type` | ENUM | — | `parent`, `employee`, `role` | `parent` |
| `recipient_id` | INT UNSIGNED | ✔ | **`std_students.id` for parent-of-student; `sch_employees.id` for employee** | `4471` |
| `recipient_role` | VARCHAR(50) | ✔ | Used when `recipient_type = 'role'` | `NULL` |
| `channel` | ENUM | — | **UK.** `in_app`, `email`, `sms`, `push` | `sms` |
| `subject` | VARCHAR(255) | ✔ | The headline | `Behavioural incident — Ravi Kumar` |
| `payload_json` | JSON | ✔ | **Rendered variables handed to the Notification module** | `{"student":"Ravi",…}` |
| `status` | ENUM | — | `pending`, `sent`, **`failed`**, **`suppressed`** | `failed` |
| `attempt_count` | TINYINT UNSIGNED | — | Retries so far, **bounded** | `3` |
| `last_attempt_at` | TIMESTAMP | ✔ | Most recent attempt | `2026-11-12 14:05` |
| `sent_at` | TIMESTAMP | ✔ | When it actually went | `NULL` |
| `failure_reason` | VARCHAR(500) | ✔ | **Visible on the Outbox screen — a silent failure is the danger** | `Invalid mobile number on file` |
| `suppress_reason` | VARCHAR(255) | ✔ | e.g. duplicate, channel disabled, no contact on file | `NULL` |

### Keys & rules

- `UNIQUE (dedupe_key, channel, uq_guard)` — **deduplication enforced by the database, not by a service check.**
- `CHECK (status <> 'failed' OR failure_reason IS NOT NULL)` — **a failure must say why.**
- `CHECK (recipient_id IS NOT NULL OR recipient_role IS NOT NULL)` — a notification must have somebody to reach.
- `idx_ba_notif_queue (status, created_at)` — outbox processing.

**BA's responsibility ends at recording the obligation and its outcome. It implements no transport.**

## 7.2 `ba_report_exports`

### What it is for

One table serving two purposes that turn out to be the same purpose:

| Purpose | How |
|---|---|
| **Performance** | Above `export_async_row_threshold` rows, the export is queued and the user is notified when it is ready |
| **Compliance** | **An export of student behavioural records is a DISCLOSURE EVENT.** Who took what data, with which filters, when, and in what format is exactly what an audit asks for |

**Every export is recorded regardless of size**, so the disclosure record has no gap for small ones.

### Example row

```
report_code  : RPT-BA-001      report_name : "Student Scores"
filters_json : {"period_id":30,"class_section_id":41,"include_remarks":true}
format       : xlsx            is_anonymised : 0
row_count    : 412             mode : async
status       : ready
file_path    : storage/ba-exports/rpt-001-20261209-0042.xlsx
requested_by 22 · requested_at 2026-12-09 09:14
completed_at 09:14:48 · expires_at 2026-12-16
ip_address   : 192.168.1.42
```

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `42` |
| `report_code` | VARCHAR(40) | — | `RPT-BA-001` … `RPT-BA-010` | `RPT-BA-001` |
| `report_name` | VARCHAR(120) | — | Display name | `Student Scores` |
| `filters_json` | JSON | ✔ | **Exactly what was asked for — this is the disclosure SCOPE** | `{"period_id":30,…}` |
| `format` | ENUM | — | `pdf`, `xlsx`, `csv` | `xlsx` |
| `is_anonymised` | TINYINT(1) | — | **Whether the identity-suppressing variant was used** | `0` |
| `row_count` | INT UNSIGNED | ✔ | How many rows left the building | `412` |
| `mode` | ENUM | — | `sync` or `async` | `async` |
| `status` | ENUM | — | `queued`, `generating`, `ready`, `failed`, **`expired`** | `ready` |
| `file_path` | VARCHAR(500) | ✔ | Where the generated file is | `storage/ba-exports/…xlsx` |
| `file_size_bytes` | INT UNSIGNED | ✔ | Size | `184320` |
| `error_message` | TEXT | ✔ | Failure detail | `NULL` |
| `requested_by` | INT UNSIGNED | — | FK → `sys_users`, `ON DELETE RESTRICT`. **Who took the data** | `22` |
| `requested_at` | TIMESTAMP | — | When | `2026-12-09 09:14` |
| `completed_at` | TIMESTAMP | ✔ | When the file was ready | `2026-12-09 09:14:48` |
| `expires_at` | TIMESTAMP | ✔ | **The FILE expires; this ROW is retained.** The record of the disclosure must outlive the file | `2026-12-16` |
| `ip_address` | VARBINARY(16) | ✔ | `INET6_ATON` form | `0x…` |

## 7.3 `ba_behaviour_points` — optional, off by default

### What it is for

An **optional** incident-driven merit/demerit ledger. **Disabled by default** (`ba_config.is_behaviour_points_enabled = 0`). When off, this table stays empty and nothing reads it. **Periodic scores are unaffected either way.**

### Why it exists at all

Two schools will give opposite answers to *"should incidents affect the behavioural score?"*, both defensibly:

| Position | Reasoning |
|---|---|
| **Keep the score clean** (default) | It preserves the distinction between a **measurement** (observed behaviour against criteria) and an **event** (something that happened once). It also stops the score reacting to *reporting rate* rather than to behaviour: a diligent teacher who logs everything would otherwise depress their whole class |
| **Let incidents count** | A school running a house-points or merit system genuinely wants this, **and will build it in a spreadsheet if the module refuses** |

So: off by default, with a defined and auditable mechanism for the school that turns it on — rather than an undefined one that appears in Excel.

### Example rows

| points | reason | entry_type | incident_id | reverses_id |
|---:|---|---|---:|---:|
| −10 | Corridor aggression — INC-2026-000417 | `incident` | 417 | — |
| +5 | Helped a Year 7 pupil who had fallen | `incident` | 431 | — |
| +3 | House captain nomination | `manual` | NULL | — |
| **+10** | Reversal: incident 417 cancelled on appeal | **`reversal`** | NULL | **1120** |

### Columns

| Column | Type | Null | Meaning | Example |
|---|---|:---:|---|---|
| `id` | BIGINT UNSIGNED | — | **PK** | `1121` |
| `student_id` | INT UNSIGNED | — | FK → `std_students`, `ON DELETE RESTRICT` | `4471` |
| `academic_session_id` | SMALLINT UNSIGNED | — | FK → `sch_org_academic_sessions_jnt`, `ON DELETE RESTRICT` | `3` |
| `incident_id` | BIGINT UNSIGNED | ✔ | FK → `ba_incidents`, `ON DELETE SET NULL`. **NULL for a manual award or a reversal** | `417` |
| `points` | SMALLINT | — | **Positive = merit, negative = demerit. NEVER zero** | `-10` |
| `reason` | VARCHAR(255) | — | Why | `Corridor aggression — INC-…` |
| `entry_type` | ENUM | — | `incident`, `manual`, **`reversal`** | `incident` |
| `reverses_id` | BIGINT UNSIGNED | ✔ | Self-FK, `ON DELETE SET NULL`. **The entry this one compensates** | `NULL` |
| `awarded_by` | INT UNSIGNED | — | FK → `sch_employees`, `ON DELETE RESTRICT` | `88` |
| `awarded_at` | TIMESTAMP | — | When | `2026-11-12 14:00` |

### Keys & rules

`CHECK (points <> 0)` — a zero-point entry means nothing.

**Append-only in practice.** Entries are reversed by a compensating row, never edited — which is why `points` may be negative and why the service has no update path. **Points NEVER modify `ba_computed_scores`;** they are reported alongside it as a separate standing.

---

# Views — 5 read-only reports

Each view exists so that a rule lives in **one** place rather than being re-derived, slightly differently, in each of ten reports.

## `v_ba_student_period_scores`

**Overall plus per-category scores for a student-period**, denormalised for the Student Report. Carries the period status and the at-risk reason alongside, so a report needs one query rather than four.

| Returns | Why it is there |
|---|---|
| `overall_score`, `overall_normalised`, `overall_grade` | The headline |
| `score_delta`, `trend`, `is_at_risk`, `at_risk_reason` | The movement and the flag |
| `category_score`, `category_normalised`, `category_grade`, `polarity` | One row per category |
| `is_insufficient_data`, `teacher_count`, `criteria_rated`, `criteria_applicable` | **The confidence behind each figure** |
| `period_status` | So a report can say whether these numbers are final |

## `v_ba_assessment_progress`

**Completion state per assessment.** Reads the stored `completion_percent` rather than counting cells — which is the whole reason that column exists.

| Returns | Why it is there |
|---|---|
| `completion_percent`, `status`, `sent_back_count` | Where each teacher is |
| `days_to_deadline` | Computed from the period deadline |
| `is_overdue` | Still draft, and the deadline has passed |
| `was_late` | Submitted after the deadline — a separate fact from overdue |

## `v_ba_open_interventions` — the owner worklist

**`is_overdue` and `days_overdue` are DERIVED here, never stored.** A stored flag would depend on a nightly job to keep it true, and would therefore be wrong between runs.

| Returns | Why it is there |
|---|---|
| `incident_no`, `severity`, `incident_status` | Context for the owner |
| `intervention_name`, `intervention_type` | What was asked for |
| `assigned_to`, `scheduled_date` | Who and by when |
| `is_overdue`, `days_overdue` | **Computed from `CURDATE()` at read time** |

## `v_ba_incident_summary`

**Per-student incident counts.** Feeds the at-risk rule, the dashboard and Class Analysis, **so all three necessarily agree.**

| Returns | Why it is there |
|---|---|
| `total_incidents`, `negative_count`, `positive_count` | The balance matters — a child with 4 positive and 1 negative is not a problem |
| `minor_count`, `moderate_count`, `major_count`, `critical_count` | Severity mix |
| `open_count`, `resolved_count` | Is anything still unhandled |
| `last_incident_date` | Recency |
| `avg_days_to_resolution` | **How quickly this school actually responds** |

Cancelled incidents are excluded.

## `v_ba_at_risk_students`

The composite at-risk rule, **joined to the incident side so the reason is legible without a second query.**

| Returns | Why it is there |
|---|---|
| `overall_score`, `normalised_score`, `trend`, `score_delta` | The academic-behavioural picture |
| `negative_incidents`, `major_incidents`, `critical_incidents` | The event picture |
| `at_risk_reason` | **Which limb of the rule fired** |

---

# Triggers — 22 database-level guards

## Why they exist

The 2026-06-29 audit assessed 30 business rules against the live code: **15 enforced, 6 partial, 9 missing.** The missing nine were not obscure. They included *"locked assessments cannot be edited"*, *"a scale in use cannot change shape"*, *"the permissive class-mapping default"*, and *"severe incidents notify parents"*.

Every one had been written down, agreed, and then **simply not built — and nothing failed, so nothing noticed.**

The triggers below make the **invariants** unbypassable. They bind a controller, a queued job, a console command, a seeder, a data-fix script and a future developer equally. Service code performs the same checks first, so users get clean messages; **these are the backstop, not the user experience.**

## What is enforced where

| Layer | Kind of rule | Example |
|---|---|---|
| **Database** | **Invariants** — never true, regardless of who is asking | Negative incidents have severity · locked assessments do not change · audit rows are not updated |
| **Service** | Workflow and permission — depends on actor and config | Who may reopen a period · whether review is required · whether a grid is complete |
| **FormRequest** | Shape and range of input | Description length · date not in the future |
| **Policy** | Authorisation | Who may read a witness statement |

## The 22 triggers

| # | Trigger | On | Enforces |
|---:|---|---|---|
| 1 | `trg_ba_scale_locked_bu` | `ba_rating_scales` BU | **A scale in use is numerically frozen.** Min, max and level values cannot change once ratings exist |
| 2 | `trg_ba_level_range_bi` | `ba_rating_levels` BI | **Level value must fall inside the parent scale's range.** A CHECK cannot express this — it would have to read another row |
| 3 | `trg_ba_level_range_bu` | `ba_rating_levels` BU | The same, plus: no value change once the scale is locked |
| 4 | `trg_ba_period_status_bu` | `ba_assessment_periods` BU | **The period FSM.** `open ⇄ closed → locked`; `open → locked` rejected; `locked` terminal |
| 5 | `trg_ba_assessment_status_bu` | `ba_assessments` BU | **The assessment FSM, and `locked` is terminal** |
| 6 | `trg_ba_rating_bi` | `ba_assessment_ratings` BI | **THE LOCK CASCADE.** No insert when the assessment is locked or the period is closed/locked |
| 7 | `trg_ba_rating_bu` | `ba_assessment_ratings` BU | No update when the assessment or period is locked |
| 8 | `trg_ba_rating_bd` | `ba_assessment_ratings` BD | No delete under a locked assessment |
| 9 | `trg_ba_remark_bu` | `ba_student_remarks` BU | No update under a locked assessment |
| 10 | `trg_ba_incident_no_bi` | `ba_incidents` BI | Generates `INC-YYYY-NNNNNN` when not supplied |
| 11 | `trg_ba_incident_bu` | `ba_incidents` BU | **Core-field immutability**, and a cancelled incident cannot be reopened |
| 12 | `trg_ba_witness_bu` | `ba_incident_witnesses_jnt` BU | A frozen witness record rejects writes |
| 13–14 | `trg_ba_audit_bu` / `_bd` | `ba_audit_log` | **Insert-only.** No update, no delete |
| 15–16 | `trg_ba_snapshot_bu` / `_bd` | `ba_framework_snapshots` | **Immutable.** Re-lock to create a new version |
| 17–18 | `trg_ba_status_hist_bu` / `_bd` | `ba_assessment_status_history` | Append-only |
| 19–20 | `trg_ba_followup_bu` / `_bd` | `ba_incident_followups` | Append-only |
| 21–22 | `trg_ba_progress_bu` / `_bd` | `ba_intervention_progress` | Append-only |

All raise `SIGNAL SQLSTATE '45000'` with a message prefixed `BA:` so the application can map it to user-facing text.

## Trigger 6 is the important one

```
BEFORE INSERT ON ba_assessment_ratings
  read the parent assessment AND its period
  if assessment.status = 'locked' OR period.status IN ('closed','locked')
     → SIGNAL 'BA: ratings cannot be added…'
```

**The previous version checked `assessment.status === 'locked'` in the UI, and no code ever set that status.** Period `lock()` updated only the period row. So "locked" periods froze nothing, and approved scores could be edited out of sync with the cache and the audit trail.

**The fix is not to remember to set a flag. It is to check the parent at the point of write.** A rating cannot be written when its assessment is locked or its period is closed — no matter who is writing, or from where.

## Omitting the trigger section

The triggers live in Section 20 of the DDL, on their own. **A deployment that prefers application-only enforcement can omit that section** and every table, key, foreign key and CHECK stays valid — the schema will load and work.

It will also reproduce exactly the conditions under which nine agreed rules went missing. **The recommendation is to keep them.**

---

# Quick reference

## Where does each business question live?

| Question | Tables |
|---|---|
| What scale does Grade 1 use? | `ba_class_scale_jnt` → else `ba_config.rating_scale_id` |
| Which categories apply to Grade 8? | `ba_class_category_jnt` — **and if no rows, ALL of them** |
| Has Mrs Rao finished her grid? | `ba_assessments.completion_percent` |
| Who sent this assessment back, and why? | `ba_assessment_status_history` |
| **What did this student score, and can I trust it?** | `ba_computed_overall` + `ba_computed_scores.is_insufficient_data` |
| How was that score arrived at? | `ba_score_runs` + `ba_framework_snapshots` |
| Is this child improving? | `ba_computed_overall.trend` and `score_delta` |
| Who is at risk, and why? | `v_ba_at_risk_students.at_risk_reason` |
| What happened in the corridor on 12 November? | `ba_incidents` |
| Who saw it? | `ba_incident_witnesses_jnt` — **restricted read** |
| **What did we actually do about it?** | `ba_incident_intervention_jnt` + `ba_intervention_progress` |
| Did it work? | `ba_incident_intervention_jnt.outcome` |
| Did the parents get told? | `ba_notifications` — **including whether it failed** |
| Is this child's behaviour escalating? | `ba_config.incident_escalation_count` over `idx_ba_incident_escal` |
| Where do incidents cluster? | `idx_ba_incident_hotspot (incident_date, location)` |
| Who exported student behavioural data? | `ba_report_exports` |
| Who read a witness statement? | `ba_audit_log` where `entity_type = 'witness_read'` |

## Table count by section

| Section | Tables |
|---|---:|
| 1 · Foundation masters | 4 |
| 2 · Master detail | 2 |
| 3 · Setup and applicability | 5 |
| 4 · Workflow headers and audit | 4 |
| 5 · Core transactions | 6 |
| 6 · Incident detail | 5 |
| 7 · Operations | 3 |
| **Total** | **29 tables, 5 views, 22 triggers** |

## The eight append-only tables

| Table | Holds | Protected by |
|---|---|---|
| `ba_audit_log` | Field-level changes, including read events | Triggers 13–14 |
| `ba_audit_log_archive` | Archived audit rows | No update path |
| `ba_framework_snapshots` | The frozen framework per locked period | Triggers 15–16 |
| `ba_assessment_status_history` | Who moved this, when, why | Triggers 17–18 |
| `ba_incident_followups` | What the school found, over time | Triggers 19–20 |
| `ba_intervention_progress` | What the school did, step by step | Triggers 21–22 |
| `ba_score_runs` | Computation provenance | No update path |
| `ba_behaviour_points` | Merit / demerit ledger | Reversed, never edited |

## Ten things that are easy to get wrong

| # | Trap | The rule |
|---|---|---|
| 1 | Writing to `uq_guard` or `is_default_flag` | **They are GENERATED.** MySQL maintains them |
| 2 | Adding `deleted_at` to a unique key to make it soft-delete aware | **It silently stops enforcing anything.** Use `uq_guard` |
| 3 | Editing a locked assessment's ratings | **Blocked at the database.** Triggers 6–9 |
| 4 | Expecting `(max + 1) − raw` for negative polarity | **It is `(max + min) − raw`.** Identical on 1-based scales, correct on 0-based ones |
| 5 | Treating an unrated cell as zero | **NULL means "not observed".** It changes neither numerator nor denominator |
| 6 | Looking for `overall_score` on `ba_computed_scores` | **It lives in `ba_computed_overall`**, with its own clean unique key |
| 7 | Reading a rating's value from `ba_rating_levels` | **Use `ba_assessment_ratings.rating_value`** — frozen at save, so history survives a level being deleted |
| 8 | Reporting a locked period's scores from the live masters | **Read the framework snapshot.** Live weights have moved on |
| 9 | Trusting `ba_incidents.is_notified` | **`ba_notifications` is authoritative.** The boolean is a denormalised convenience |
| 10 | Storing `is_overdue` on an intervention | **Derive it.** A flag that depends on a nightly job is wrong between runs |

## The one thing to verify on first run

This schema uses **stored generated columns as foreign-key parents** — `ba_machines`-style patterns do not appear here, but `uq_guard` participates in unique keys that other tables reference through composite parents. The generated-column behaviour relied on is:

| Assumption | Status |
|---|---|
| A stored generated column may participate in a UNIQUE key | **Standard MySQL behaviour** |
| A generated column's expression must be deterministic | **Why `deleted_at` is `DATETIME(6)` and not `TIMESTAMP`** — a TIMESTAMP→DATETIME conversion is time-zone dependent and MySQL rejects it |
| `CHECK` constraints are enforced | **Requires MySQL 8.0.16 or later.** On an older server every CHECK in this file is parsed and ignored — silently |

**If the target server is below 8.0.16, roughly fifteen integrity rules in this schema become decorative.** Confirm the version before the first install.

---

**End of `Dictionary_DDL_v3.0.md`**
