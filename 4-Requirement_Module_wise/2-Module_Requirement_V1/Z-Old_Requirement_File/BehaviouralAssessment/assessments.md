# Assessments (Teacher Entry) — Requirements

## What It Does
The core assessment workflow where teachers rate students on behavioural criteria. Teachers enter ratings via a grid interface (students × criteria), supporting draft auto-save, bulk rating, and explicit submission. Includes review workflow by Principal/HOD.

## Database Fields

### `ba_assessments`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `period_id` | BIGINT UNSIGNED | FK → `ba_assessment_periods.id`. `ON DELETE RESTRICT`. |
| `teacher_id` | INT UNSIGNED | FK → `sch_employees.id` (cross-module). Assessing teacher. |
| `class_section_id` | INT UNSIGNED | FK → `sch_class_section_jnt.id` (cross-module). Class+section assessed. |
| `status` | ENUM('draft','submitted','reviewed','locked') | Default `'draft'`. Assessment workflow status. |
| `submitted_at` | TIMESTAMP | Nullable. When teacher submitted. |
| `reviewed_by` | INT UNSIGNED | Nullable FK → `sch_employees.id`. Reviewer. |
| `reviewed_at` | TIMESTAMP | Nullable. When reviewed. |
| `reviewer_remarks` | TEXT | Nullable. Remarks when sent back. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique Constraints:**
- `uq_ba_assessment` — `(teacher_id, class_section_id, period_id)`: one assessment per teacher per class-section per period.

### `ba_assessment_ratings`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `assessment_id` | BIGINT UNSIGNED | FK → `ba_assessments.id`. Parent assessment. `ON DELETE CASCADE`. |
| `student_id` | INT UNSIGNED | FK → `std_students.id` (cross-module). Student being rated. |
| `criterion_id` | BIGINT UNSIGNED | FK → `ba_criteria.id`. Criterion being rated. |
| `rating_level_id` | BIGINT UNSIGNED | Nullable FK → `ba_rating_levels.id`. Selected level; NULL = not rated. |
| `remark` | VARCHAR(500) | Nullable. Per-criterion remark for this student. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique Constraints:**
- `uq_ba_rating` — `(assessment_id, student_id, criterion_id)`: one rating per student per criterion per assessment.

### `ba_student_remarks`

| Field | Type | Conditions |
|---|---|---|
| `id` | BIGINT UNSIGNED PK | Auto-increment |
| `assessment_id` | BIGINT UNSIGNED | FK → `ba_assessments.id`. Parent assessment. |
| `student_id` | INT UNSIGNED | FK → `std_students.id` (cross-module). |
| `remark_text` | TEXT | Required. Teacher's overall behavioural remark for this student. |
| `is_active` | BOOLEAN | Default `1`. |
| `created_by` / `updated_by` | BIGINT UNSIGNED | FK → `sys_users.id`. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

**Unique Constraints:**
- `uq_ba_remark` — `(assessment_id, student_id)`: one overall remark per student per assessment.

## Business Rules

**Teacher Assignment Resolution (BR-BA-010)**
- **Class Teacher**: Resolved from `sch_class_section_jnt.class_teacher_id`. Assesses ALL categories for students in their section.
- **Subject Teacher**: Resolved from timetable allocations. Assesses ONLY categories mapped to their class via `ba_class_category_jnt`.

**Assessment Grid**
- Students as rows, criteria as columns (filtered by class-category mapping and teacher type).
- Each cell is a dropdown with the active rating scale's levels.
- Colour-coded: green (high) → yellow (medium) → red (low) based on numeric_value.

**Auto-Save (BR-BA-014)**
- Draft auto-saves every 30 seconds via `wire:poll.30s`.
- Uses bulk upsert: no completeness validation required.
- Visual indicator: "Draft saved" / "Saving..." / "Unsaved changes".

**Bulk Rating**
- Apply the same rating level to ALL students for a single criterion at once.
- Useful for quick entry (e.g., "Everyone gets 'Good' on Attendance").

**Assessment Workflow (FSM)**
```
draft ──submit()──▶ submitted ──approve()──▶ reviewed ──lock()──▶ locked
   ▲                     │                       │
   └──── sendBack() ─────┘                       │
   └──── sendBack() ─────────────────────────────┘
```

| Transition | Trigger | Pre-conditions | Side Effects |
|---|---|---|---|
| `draft → submitted` | Teacher clicks "Submit" | All criteria rated for all active students | `submitted_at` set; `AssessmentSubmitted` event → notification to Principal/HOD |
| `submitted → draft` | Principal "Send Back" | `reviewer_remarks` required | `AssessmentSentBack` event → teacher notification |
| `submitted → reviewed` | Principal "Approve" | Reviewer has `ba.review.approve` permission | `AssessmentApproved` event → triggers score recomputation |
| `reviewed → draft` | Principal "Send Back" | `reviewer_remarks` required | Clears reviewer fields |
| `reviewed → locked` | Period lock | Period status = `locked` | No further edits; scores finalised |

**Multi-Teacher Averaging (BR-BA-004)**
- When multiple teachers assess the same student on the same criterion in the same period, ratings are averaged during score computation.

## CRUD Operations

**Create**
- Route: `GET /behavioural-assessment/assessments/create` → select period + class-section
- Submit: `POST /behavioural-assessment/assessments` → creates `ba_assessments` header + pre-generates empty rating rows for all students × applicable criteria

**List (Teacher)**
- Route: `GET /behavioural-assessment/assessments` → "My Assessments" with status badges, completion percentage, period name

**View**
- Route: `GET /behavioural-assessment/assessments/{assessment}` → read-only grid (for non-owner) or editable grid (for owner)

**Auto-Save**
- Route: `POST /behavioural-assessment/assessments/{assessment}/auto-save` → bulk upsert ratings without validation

**Bulk Rate**
- Route: `POST /behavioural-assessment/assessments/{assessment}/bulk-rate` → applies one level to all students for one criterion

**Submit**
- Route: `POST /behavioural-assessment/assessments/{assessment}/submit` → validates completeness → transitions to submitted

## Permissions

| Operation | Permission Key |
|---|---|
| View assessments tab | `tenant.ba.assessment.viewAny` |
| View assessment details | `tenant.ba.assessment.viewAny` |
| Create assessment | `tenant.ba.assessment.create` |
| Edit ratings (draft) | `tenant.ba.assessment.create` |
| Submit assessment | `tenant.ba.assessment.submit` |
