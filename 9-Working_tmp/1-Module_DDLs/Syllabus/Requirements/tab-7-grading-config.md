# Syllabus Tab 7: Grading Configuration

This tab configures how student performance is categorized and how grades or divisions are awarded. It supports board-specific grading bands, multiple classification systems across different class ranges, and AI-driven intervention semantics.

---

## How It Works

The screen has two sections: Performance Categories and Grade/Division Master.

The Performance Categories section lists classification bands such as Topper, Excellent, Good, Average, Below Average, Need Improvement, and Poor. Each category has a numeric level (1-5), a minimum and maximum percentage range, a display order, a color code for visual representation in reports, and an icon code. Each category also has AI semantics: a severity level (Low, Medium, High, Critical) and a default AI action (Accelerate, Progress, Practice, Remediate, Escalate). The auto-retest flag tells the system whether to automatically generate a retest for students falling in this category.

Performance categories can be scoped at the SCHOOL level (applies to all classes) or the CLASS level (different bands for different classes). System-defined categories cannot be edited. Schools can add custom categories with their own percentage ranges.

The Grade/Division Master section manages letter grades (A, B, C, etc.) and divisions (First Division, Second Division, etc.). Each entry specifies whether it is a GRADE or DIVISION type, the percentage range, the board code (CBSE, ICSE, STATE), and the academic session. Like performance categories, entries can be scoped at SCHOOL, BOARD, or CLASS level. The `is_locked` flag prevents editing after results have been published.

---

## Important Business Rules

- Percentage ranges within the same scope must not overlap. The application layer enforces this by checking existing ranges before creating or updating a category.
- Percentage ranges do not need to cover the full 0-100% spectrum. Gaps between ranges mean no category applies to students falling in that gap.
- System-defined categories (`is_system_defined = 1`) cannot be edited or deleted by schools.
- Categories with `auto_retest_required = 1` trigger automatic test generation for students falling in that band.
- The AI severity and default action fields drive the system's recommendation engine: CRITICAL severity with ESCALATE action flags the student for intervention.
- Grade/division entries with `is_locked = 1` cannot have their percentage ranges modified. The lock is applied after results are published for the session.
- A school can have different grading systems for different class ranges. For example, classes 1-3 might use Emerging/Developing/Proficient, classes 4-8 use Good/Average/Below Average, and classes 9-12 use Topper/Excellent/Good/Average/Division-based bands.
- The unique constraint on (code, grading_type, scope, class_id) prevents duplicate entries for the same scope.
- When `scope = SCHOOL`, the `class_id` must be NULL. When `scope = CLASS`, the `class_id` must be set.

---

## Database Columns & Behavior

### slb_performance_categories
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique code per scope. VARCHAR(20). Example: TOPPER, EXCELLENT. Unique composite with scope.
- `name` — Display name. VARCHAR(100).
- `description` — Explanation. VARCHAR(255), nullable.
- `level` — Numeric level 1-5 (1 = highest, 5 = lowest). TINYINT UNSIGNED.
- `min_percentage` — Lower bound of the range. DECIMAL(5,2). Must be less than max_percentage.
- `max_percentage` — Upper bound of the range. DECIMAL(5,2).
- `ai_severity` — AI intervention severity. ENUM('LOW','MEDIUM','HIGH','CRITICAL'). Default LOW.
- `ai_default_action` — Recommended AI action. ENUM('ACCELERATE','PROGRESS','PRACTICE','REMEDIATE','ESCALATE').
- `display_order` — Sort order in dropdowns and reports. SMALLINT UNSIGNED, default 1.
- `color_code` — Hex color for visual display. VARCHAR(10), nullable.
- `icon_code` — Icon identifier. VARCHAR(50), nullable.
- `scope` — SCHOOL (all classes) or CLASS (specific class). ENUM('SCHOOL','CLASS'), default SCHOOL.
- `class_id` — Required when scope = CLASS. INT UNSIGNED FK to sch_classes, nullable.
- `is_system_defined` — Whether PG Team defined this. TINYINT(1), default 1.
- `auto_retest_required` — Auto-generate retest flag. TINYINT(1), default 0.
- `is_active` — Soft delete flag. TINYINT(1), default 1.
- CHECK constraint: min_percentage < max_percentage.

### slb_grade_division_master
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Grade/division code. VARCHAR(20). Example: A, B, 1ST, 2ND.
- `name` — Display name. VARCHAR(100). Example: Grade A, First Division.
- `description` — Explanation. VARCHAR(255), nullable.
- `grading_type` — GRADE (letter) or DIVISION (rank). ENUM('GRADE','DIVISION').
- `min_percentage` — Lower bound. DECIMAL(5,2).
- `max_percentage` — Upper bound. DECIMAL(5,2).
- `board_code` — Applicable board. VARCHAR(50), nullable. Example: CBSE, ICSE, STATE.
- `academic_session_id` — Session this applies to. INT UNSIGNED, nullable. FK to sch_org_academic_sessions_jnt.
- `display_order` — Sort order. SMALLINT UNSIGNED, default 1.
- `color_code` — Hex color. VARCHAR(10), nullable.
- `scope` — SCHOOL, BOARD, or CLASS. ENUM('SCHOOL','BOARD','CLASS'), default SCHOOL.
- `class_id` — Required when scope = CLASS. INT UNSIGNED FK to sch_classes, nullable.
- `is_locked` — Prevents editing after publishing. TINYINT(1), default 0.
- `is_active` — Soft delete flag. TINYINT(1), default 1.
- Unique constraint on (code, grading_type, scope, class_id).
- Unique constraint on (scope, class_id, min_percentage, max_percentage) to prevent duplicate ranges.
- CHECK constraint: min_percentage < max_percentage.

---

## Deep Analysis

### Business Workflows & State Machines
- **Performance Category CRUD** — create/edit with `code`, `name`, `level`, `min_percentage`, `max_percentage`, `ai_severity`, `ai_default_action`, `scope`, `class_id` — validate non-overlapping ranges per scope — INSERT/UPDATE.
- **Grade/Division Master CRUD** — create/edit with `code`, `grading_type` (GRADE/DIVISION), percentage range, `board_code`, `session`, `scope`, `class_id` — validate range overlap — lock after publishing.
- **Lock after publishing** — set `is_locked = 1` — all further edits blocked; unlock only by Super Admin.
- **State machine**: Performance categories — ACTIVE or SOFT-DELETED. Grade/Division entries — ACTIVE — LOCKED (irreversible at school level).

### Validation Rules & Edge Cases
- **Range overlap (performance categories)** — application layer query: `SELECT 1 FROM slb_performance_categories WHERE :new_min <= max_percentage AND :new_max >= min_percentage AND scope = :scope AND (class_id = :cid OR class_id IS NULL) AND is_active = 1 LIMIT 1` — reject if row exists.
- **Range overlap (grade/division)** — same pattern; DB does NOT enforce — app layer only.
- **Scope consistency** — when `scope = SCHOOL`, `class_id` MUST be NULL; when `scope = CLASS` or `BOARD`, `class_id` MUST be set. Application validates before INSERT/UPDATE.
- **Incomplete coverage** — ranges do not need to cover 0-100%; gaps are valid (no category applies to students in the gap).
- **Locked entries** — `is_locked = 1` must be checked at app layer before any edit; locked entries can only be unlocked by a privileged user.
- **System-defined** — `is_system_defined = 1` rows cannot be edited or deleted by school; app layer enforced.
- **Auto-retest** — teachers must be notified when a student falls into a category with `auto_retest_required = 1`.
- **AI action semantics** — `CRITICAL` severity with `ESCALATE` action must trigger intervention workflow in the AI engine.

### Integration Points
- **Student report cards** — reads performance categories and grade/division tables for grade calculation.
- **AI recommendation engine** — reads `ai_severity` and `ai_default_action` for intervention suggestions.
- **Auto-retest system** — triggers automatic test generation for categories with `auto_retest_required = 1`.
- `sch_classes` — class scope reference (FK).
- `sch_org_academic_sessions_jnt` — academic session scope for grade/division.
- **Exam/assessment results module** — reads grading config to compute final grades.

### Permissions Matrix
| Role | Manage Categories | Manage Grades/Divisions | Lock/Unlock | Delete System-Defined | Delete Custom |
|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ❌ (can lock own, not unlock) | ❌ | ✅ |
| Curriculum Coordinator | ✅ (custom only) | ✅ (custom only) | ❌ | ❌ | ✅ (own) |
| Teacher | ❌ | ❌ | ❌ | ❌ | ❌ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ |
