# Syllabus Tab 9: Version Governance

This tab manages lesson version control and curriculum change requests. It ensures traceability of syllabus changes across academic years and provides a formal approval workflow for curriculum modifications.

---

## How It Works

The screen has two sections: Lesson Version Control and Curriculum Change Requests.

The Lesson Version Control section displays a history of each lesson across academic sessions. When a lesson is first imported from an NCERT or board curriculum, it is created with status IMPORTED and version v1.0. The import records the curriculum authority (NCERT, CBSE, ICSE, STATE_BOARD, or OTHER), the board code, the book reference, book edition, and publisher. Once the syllabus is finalized for the session, the system locks the lesson by changing its status to LOCKED and recording the lock date. Locked lessons cannot be edited.

In the next academic year, if a new NCERT edition is released, the system creates a new lesson version (v2.0) linked to the previous lesson via `derived_from_lesson_id`. The old version is marked DEPRECATED. The status lifecycle is: IMPORTED → ACTIVE → LOCKED → DEPRECATED (and optionally ARCHIVED).

The Curriculum Change Requests section provides a formal workflow for proposing changes to the syllabus during an active session. A user can submit a change request targeting a subject, lesson, topic, or competency. The request specifies the change type (ADD, UPDATE, DELETE), a summary of the change, and an impact analysis (stored as JSON for flexibility). The request moves through a workflow: DRAFT → SUBMITTED → APPROVED → REJECTED. Only approved changes are applied to the curriculum.

---

## Important Business Rules

- Once a lesson is LOCKED, no edits are allowed at the application layer even if the database permits it. The `is_editable` flag is always 0 for system-defined lessons.
- A lesson cannot transition directly from IMPORTED to DEPRECATED. It must go through ACTIVE and then LOCKED first.
- The status transition is unidirectional: IMPORTED → ACTIVE → LOCKED → DEPRECATED. LOCKED can also go to ARCHIVED. Reversal is not permitted.
- The unique constraint on (lesson_id, academic_session_id, lesson_version) prevents duplicate version entries for the same lesson in the same session.
- When a system-defined lesson is imported, `is_system_defined = 1` and `is_editable = 0`. School-created lessons have `is_system_defined = 0` and `is_editable = 1`.
- Curriculum change requests in DRAFT status can be edited. Once SUBMITTED, only the status can be changed (by an approver).
- The `impact_analysis` JSON field can contain any structured data — affected student count, assessment impact, resource requirements, etc.
- Deleted curriculum change requests are soft-deleted and remain in the database for audit purposes.
- Only users with appropriate permission can approve or reject change requests. Requestors cannot approve their own requests.

---

## Database Columns & Behavior

### hpc_lesson_version_control
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `lesson_id` — FK to slb_lessons. INT UNSIGNED. CASCADE on delete.
- `academic_session_id` — Session this version applies to. INT UNSIGNED FK to sch_org_academic_sessions_jnt.
- `curriculum_authority` — Source authority. ENUM('NCERT','CBSE','ICSE','STATE_BOARD','OTHER'). Default NCERT.
- `board_code` — Board identifier. VARCHAR(50), nullable. Example: CBSE, ICSE, STATE-UK.
- `book_id` — Reference to book master. INT UNSIGNED, nullable.
- `book_title` — Book title (audit-friendly redundancy). VARCHAR(255), nullable.
- `book_edition` — Edition identifier. VARCHAR(100), nullable. Example: "2024 Edition".
- `publisher` — Publisher name. VARCHAR(150), default 'NCERT'.
- `lesson_version` — Version identifier. VARCHAR(20). Example: v1.0, v2.0.
- `derived_from_lesson_id` — Previous version reference. INT UNSIGNED FK to slb_lessons. SET NULL on delete. Nullable.
- `status` — Governance state. ENUM('IMPORTED','ACTIVE','LOCKED','DEPRECATED','ARCHIVED'). Default IMPORTED.
- `is_editable` — Editable flag. TINYINT(1), default 0.
- `is_system_defined` — System-defined flag. TINYINT(1), default 1.
- `imported_on` — Date of import. DATE, nullable.
- `locked_on` — Date of lock. DATE, nullable.
- `remarks` — Audit remarks. VARCHAR(500), nullable.
- Unique constraint on (lesson_id, academic_session_id, lesson_version).

### hpc_curriculum_change_request
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `entity_type` — Entity being changed. ENUM('SUBJECT','LESSON','TOPIC','COMPETENCY').
- `entity_id` — ID of the entity. INT UNSIGNED.
- `change_type` — Type of change. ENUM('ADD','UPDATE','DELETE').
- `change_summary` — Description of the change. VARCHAR(500), nullable.
- `impact_analysis` — JSON data for impact assessment. JSON, nullable.
- `status` — Workflow status. ENUM('DRAFT','SUBMITTED','APPROVED','REJECTED'). Default DRAFT.
- `requested_by` — User who submitted the request. INT UNSIGNED, nullable.
- `requested_at` — Timestamp of submission. TIMESTAMP, default CURRENT_TIMESTAMP.
- `is_active` — Soft delete flag. TINYINT(1), default 1.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamps.

---

## Deep Analysis

### Business Workflows & State Machines
- **Lesson Version Lifecycle** → IMPORTED (from NCERT/board) → ACTIVE (curriculum coordinator activates) → LOCKED (session finalized; no edits) → DEPRECATED (superseded by newer version) → ARCHIVED (optional terminal state).
- **Transitions**: IMPORTED→ACTIVE, ACTIVE→LOCKED, LOCKED→DEPRECATED, LOCKED→ARCHIVED. Reversals are NOT permitted. IMPORTED→DEPRECATED also NOT permitted.
- **New Edition Import** → when new NCERT edition released → create new lesson → INSERT with `lesson_version = v2.0`, `derived_from_lesson_id = old_id` → mark old version as DEPRECATED.
- **Change Request Workflow** → DRAFT (editable) → SUBMITTED (locked for editing) → APPROVED (changes applied) or REJECTED (changes denied).
- **State machine (change requests)**: DRAFT ↔ (edit) → SUBMITTED → APPROVED / REJECTED (terminal). No reversal from APPROVED/REJECTED back to DRAFT/SUBMITTED.

### Validation Rules & Edge Cases
- **Status transitions** — application must enforce unidirectional rules: no IMPORTED→DEPRECATED, no LOCKED→ACTIVE.
- **Locked lessons** — `is_editable = 0` for system-defined lessons; app layer must block all UPDATE/DELETE requests when `is_editable = 0`.
- **Version uniqueness** — `UNIQUE (lesson_id, academic_session_id, lesson_version)` prevents duplicate version rows.
- **Self-approval prevention** — change request `requested_by` cannot be the same user who approves/rejects; enforced at app layer.
- **DRAFT editing** — only DRAFT status requests can be edited; SUBMITTED and beyond are read-only.
- **Impact analysis JSON** — no schema enforced; application parses structured data.
- **Soft delete** — `deleted_at` on change requests for audit; DB retains the record.
- **`derived_from_lesson_id`** — SET NULL on old lesson delete; reference is optional.

### Integration Points
- `slb_lessons` — lesson FK; CASCADE on delete for version control; SET NULL for derived_from.
- `sch_org_academic_sessions_jnt` — session FK.
- **School academic session rollover process** — triggers version status changes during year-end migration.
- **Audit/compliance module** — reads version history and change request logs for board inspections.
- **Notification system** — notifies approvers when a change request is SUBMITTED; notifies requestor when APPROVED/REJECTED.

### Permissions Matrix
| Role | Import Lesson | Activate | Lock | Deprecate/Archive | Manage Change Requests | Approve/Reject |
|---|---|---|---|---|---|---|
| Super Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| School Admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Curriculum Coordinator | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Teacher | ❌ | ❌ | ❌ | ❌ | ✅ (create/submit own) | ❌ |
| Student/Parent | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| PG Team (DB Import) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
