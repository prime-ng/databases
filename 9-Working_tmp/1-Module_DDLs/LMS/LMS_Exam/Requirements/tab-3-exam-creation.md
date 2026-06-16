# LMS Exam Tab 3: Exam Creation

This tab is where the teacher or admin creates a new exam event. An exam is the top-level container — it defines what kind of exam it is (e.g., Unit Test 1), which class and academic session it belongs to, its schedule, and how results will be published. Each exam can have multiple papers (one per subject), and each paper can have multiple sets.

---

## How It Works

The user starts by clicking "Create Exam" which opens a form. They select the academic session, class, and exam type (from the types configured in Tab 2). The system auto-generates a unique exam code based on the selections (e.g., EXAM_2025_ANNUAL). The user provides a title and optional description.

Next, they set the exam date range — a start date and end date. They select a grading schema (such as A, B, C, D or divisions like Distinction, First Class) from a predefined grade division master. The user then chooses the result publishing mode: Immediate (results shown right after evaluation), Scheduled (results released at a specific date/time), or Manual (admin triggers publication).

Once saved, the exam is created in DRAFT status. The user can then proceed to Tab 4 to add papers and blueprints, or Tab 5 to set up questions.

---

## Important Business Rules

- An exam must have a unique combination of academic session, class, and exam type — you cannot create two Unit Test 1 exams for the same class in the same session.
- The exam code is auto-generated but can be manually overridden if needed. Duplicate codes are rejected.
- The start_date must be on or before the end_date. Both must fall within the selected academic session's date range.
- The grading schema is optional. If not set, the school's default grading schema is used at result time.
- The exam status starts at DRAFT and transitions to PUBLISHED when the exam is made visible to students. It can later move to CONCLUDED, then ARCHIVED.
- Once an exam has allocations or student attempts, its class and session cannot be changed.
- Result publishing mode affects only online exams and teacher-evaluated offline exams.

---

## Database Columns & Behavior

### lms_exams
- `id` — INT UNSIGNED PK, auto-increment.
- `uuid` — BINARY(16), unique. Globally unique identifier for API/sync operations.
- `academic_session_id` — INT UNSIGNED FK to glb_academic_sessions.id. Scopes the exam to a session year.
- `class_id` — INT UNSIGNED FK to sch_classes.id. The target class for this exam.
- `exam_type_id` — INT UNSIGNED FK to lms_exam_types.id. Links to the exam type master.
- `code` — VARCHAR(50), unique. Business code for the exam.
- `title` — VARCHAR(150). Display title of the exam.
- `description` — TEXT, nullable. Optional notes about the exam.
- `start_date` — DATE. First day of the exam period.
- `end_date` — DATE. Last day of the exam period.
- `grading_schema_id` — INT UNSIGNED FK to slb_grade_division_master, nullable. Grading scale for results.
- `status_id` — INT UNSIGNED FK to lms_exam_status_events.id. Tracks lifecycle: DRAFT, PUBLISHED, CONCLUDED, ARCHIVED.
- `result_published` — ENUM('IMMEDIATE','SCHEDULED','MANUAL'), default 'MANUAL'. Controls result release timing.
- `scheduled_result_at` — DATETIME, nullable. Used when result_published is SCHEDULED.
- `is_result_published` — TINYINT(1), default 0. Set to 1 when results are released.
- `created_by` — INT UNSIGNED FK to sys_users.id. Tracks who created the exam.
- `is_active` — TINYINT(1), default 1. Soft disable flag.
- `created_at`, `updated_at`, `deleted_at` — Standard audit timestamps.

---

## Deep Analysis

### Business Workflows & State Machines

The exam lifecycle follows a strict state machine with four primary statuses:

```
DRAFT ──► PUBLISHED ──► CONCLUDED ──► ARCHIVED
  │                        │
  └── (edit allowed)       └── (no further changes)
```

- **DRAFT:** Initial state on creation. Exam details (title, dates, grading schema, publishing mode) are editable. Papers, blueprints, and questions can be added. Allocations are not yet possible.
- **PUBLISHED:** Exam is visible to students. Only non-structural fields (description, instructions) remain editable. `class_id` and `academic_session_id` become immutable once any allocation or student attempt exists.
- **CONCLUDED:** All papers have been conducted. Result computation can begin. No further schedule or allocation changes allowed.
- **ARCHIVED:** Final state. Exam is read-only. Used for record-keeping.

The `result_published` mode (IMMEDIATE/SCHEDULED/MANUAL) is orthogonal to the main state machine and controls result release timing independently.

### Validation Rules & Edge Cases

- **Unique combination constraint:** The unique index on `(academic_session_id, class_id, exam_type_id)` prevents duplicate exams. Attempting to create a second UT-1 for the same class and session is rejected.
- **Date range validation:** `start_date <= end_date` and both must fall within the academic session's date range. If the session's start/end change after exam creation, a warning should flag out-of-range dates.
- **Auto-generated exam code:** Format like `EXAM_{SESSION}_{TYPE}`. Must be unique. If the generated code collides (unlikely given the unique combo constraint), a suffix is appended.
- **Manual code override:** User can override the auto-generated code, but duplicate codes are still rejected by the `uq_exam_code` unique index.
- **Grading schema optional:** If `grading_schema_id` is NULL, the system uses the school's default grading schema at result computation time. The default schema must exist; if not, result computation is blocked.
- **Publishing mode edge cases:** SCHEDULED mode requires `scheduled_result_at` to be in the future. MANUAL mode requires no date. IMMEDIATE mode publishes results as soon as computation completes.

### Integration Points

- **FKs:** `academic_session_id` → `glb_academic_sessions.id`, `class_id` → `sch_classes.id`, `exam_type_id` → `lms_exam_types.id`, `grading_schema_id` → `slb_grade_division_master.id`, `status_id` → `lms_exam_status_events.id`, `created_by` → `sys_users.id`.
- **Module dependencies:** GLB (academic sessions), SCH (classes), SLB (grading schemas), LMS (exam types, status events), SYS (users).
- **Events emitted:** Status transitions (DRAFT → PUBLISHED, etc.) are logged in `lms_exam_status_events` via an observer/listener. The `uuid` (BINARY(16)) enables API/sync external integrations.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| Create exam | Teacher, Admin | `lms.exam.create` |
| Edit exam (DRAFT) | Teacher, Admin | `lms.exam.edit` |
| Edit exam (PUBLISHED, non-structural) | Admin only | `lms.exam.edit.published` |
| Publish exam (DRAFT → PUBLISHED) | Teacher, Admin | `lms.exam.publish` |
| Conclude exam (PUBLISHED → CONCLUDED) | Admin, Principal | `lms.exam.conclude` |
| Archive exam (CONCLUDED → ARCHIVED) | Admin | `lms.exam.archive` |
| Delete exam (DRAFT only) | Teacher, Admin | `lms.exam.delete` |
| View exam details | Teacher, Admin, Principal | `lms.exam.view` |
