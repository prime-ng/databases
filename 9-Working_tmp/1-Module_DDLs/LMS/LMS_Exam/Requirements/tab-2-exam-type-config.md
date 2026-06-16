# LMS Exam Tab 2: Exam Type Configuration

This tab allows administrators to define and manage the types of exams that the school conducts — such as Unit Test 1, Unit Test 2, Half Yearly Exam, Annual Exam, Pre-Board, and so on. These exam types serve as a master list that is referenced when creating actual exams in Tab 3.

---

## How It Works

The screen displays a table listing all existing exam types. Each row shows the code (e.g., UT-1), the full name (e.g., Unit Test 1), a brief description, and an Active/Inactive status toggle. An "Add New" button at the top opens a modal or inline form where the admin can enter a unique code, name, and description.

When the admin edits an existing exam type, they can change the name, description, and active status. The code is immutable after creation because it is used as a unique identifier across the system. An inactive exam type cannot be selected when creating a new exam, but it does not affect already-created exams that reference it.

A search bar filters the list by code or name. Pagination is provided if there are more than 20 entries.

---

## Important Business Rules

- The `code` field is unique across all exam types and cannot be changed after creation.
- An exam type can be deactivated (is_active = 0) but never deleted, to preserve historical exam data.
- Deactivated exam types are hidden from the dropdown in Exam Creation but remain visible in this tab with a visual "Inactive" badge.
- At least one exam type must exist before any exam can be created.
- Common seed data includes: UT-1, UT-2, UT-3, UT-4, HY-EXAM, ANNUAL-EXAM, PRE-BOARD. Schools can add custom types.
- The system does not enforce any particular ordering of exam types; schools arrange them as needed.

---

## Database Columns & Behavior

### lms_exam_types
- `id` — INT UNSIGNED PK, auto-increment. Internal identifier.
- `code` — VARCHAR(50), unique. Business key shown in dropdowns (e.g., 'UT-1', 'HY-EXAM'). Immutable after create.
- `name` — VARCHAR(100). Display name shown in UI (e.g., 'Unit Test 1', 'Half Yearly Exam').
- `description` — VARCHAR(255), nullable. Optional free-text explanation of the exam type.
- `is_active` — TINYINT(1), default 1. Controls visibility in exam creation dropdowns.
- `created_at` — TIMESTAMP, auto-set on insert.
- `updated_at` — TIMESTAMP, auto-updated on change.
- `deleted_at` — TIMESTAMP, nullable. Soft delete — not used in normal operation; records remain.

---

## Deep Analysis

### Business Workflows & State Machines

The exam type configuration follows a simple CRUD lifecycle: CREATE → READ → UPDATE → DEACTIVATE. There is no multi-step workflow or state machine — an exam type is either `is_active = 1` (available for selection in Exam Creation) or `is_active = 0` (hidden from dropdowns, but still visible here with an "Inactive" badge). The `code` field is immutable after creation, serving as a business-level surrogate key referenced in dropdowns and seed data. Deactivation is a soft-toggle; deletion is prohibited to preserve referential integrity with existing exams that reference the type.

### Validation Rules & Edge Cases

- **Unique code constraint:** The `code` column has a UNIQUE index. Duplicate code entry is rejected at the database level with a human-readable error.
- **Code immutability:** On edit, the code field must be rendered as read-only. Any attempt to POST a changed code must be silently ignored or rejected.
- **Deactivation guard:** Deactivating (is_active = 0) is always allowed. No checks exist on whether exams reference the type — historical exams continue to reference it via FK.
- **Minimum seed requirement:** At least one exam type must exist before any exam can be created (checked in Tab 3). The UI should display a warning if no active exam types exist.
- **Empty search results:** When filtering by code/name yields zero results, a "No exam types found" message is shown with a suggestion to add a new type.
- **Edge case — all types deactivated:** If all exam types are deactivated, the Exam Creation dropdown shows empty with a message linking back to this tab.

### Integration Points

- **FK consumed by:** `lms_exams.exam_type_id` → `lms_exam_types.id`. Changes to `is_active` affect dropdown visibility in Tab 3 but do not cascade to existing exams.
- **Module dependencies:** Standalone within LMS module. No external FKs point to this table from other modules.
- **Events emitted:** No explicit events; changes to `is_active` could optionally trigger a cache invalidation for exam-type dropdowns.

### Permissions Matrix

| Action | Role | Permission Key |
|---|---|---|
| List exam types | Admin | `lms.exam.types.list` |
| Create exam type | Admin | `lms.exam.types.create` |
| Edit exam type | Admin | `lms.exam.types.edit` |
| Deactivate exam type | Admin | `lms.exam.types.deactivate` |
| View inactive types | Admin | `lms.exam.types.view.inactive` |
| Search/filter types | Admin | `lms.exam.types.search` |
