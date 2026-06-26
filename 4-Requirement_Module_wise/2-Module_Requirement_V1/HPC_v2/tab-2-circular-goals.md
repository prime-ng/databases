# HPC Tab 2: Circular Goals

This tab manages the Circular Goals as defined by NEP 2020 and PARAKH guidelines. A circular goal represents a broad educational objective that the school must work toward — for example, "Environmental Awareness" or "Constitutional Values." Each goal is linked to one or more competencies from the syllabus, creating a direct line from national policy goals down to classroom teaching.

---

## How It Works

The user sees a list of all circular goals defined for the school. Each row shows the goal code, name, the class it applies to, the NEP reference document it comes from, and whether it is currently active. The user can search by code or name to quickly find a specific goal.

Clicking a goal opens a detail panel where the user can view and edit the goal's metadata — name, description, class, NEP reference — and most importantly, map competencies to the goal. Competencies are drawn from the existing syllabus competency bank (slb_competencies). The user selects competencies from a dropdown, and marks one as "Primary" if desired.

A goal can have many competencies mapped to it. The mapping table shows each competency's code, name, and whether it is the primary competency. The user can add new mappings or remove existing ones. Soft-deleted mappings are preserved in the database but hidden from the active view.

---

## Important Business Rules

- A circular goal code must be unique across the entire system. Duplicate codes are rejected.
- A goal must be assigned to exactly one class. If a goal applies to multiple classes, the user must create separate entries for each class.
- A competency can be mapped to multiple goals. There is no restriction on cross-goal sharing.
- Each goal-competency pair can have only one entry. Duplicate mappings are prevented by a unique constraint.
- Only one competency per goal can be marked as primary at any time. If the user marks a different competency as primary, the previous primary is automatically demoted.
- Goals and mappings use soft delete. Deactivated records remain in the database but are excluded from the active user interface.
- A goal cannot be deleted if it has active competency mappings. The user must remove all mappings first.

---

## Database Columns & Behavior

### hpc_circular_goals
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique identifier for the goal. Maximum 50 characters. UNIQUE. VARCHAR(50) NOT NULL.
- `name` — Display name of the goal. VARCHAR(150) NOT NULL.
- `class_id` — FK to sch_classes. Determines which class this goal applies to. INT UNSIGNED NOT NULL.
- `description` — Free-text description of the goal. TEXT. NULL allowed.
- `nep_reference` — Reference to the NEP/PARAKH document or clause. VARCHAR(100). NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. Auto-updates on change. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. NULL means active. TIMESTAMP.

### hpc_circular_goal_competency_jnt
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `circular_goal_id` — FK to hpc_circular_goals. INT UNSIGNED NOT NULL.
- `competency_id` — FK to slb_competencies. INT UNSIGNED NOT NULL.
- `is_primary` — Marks this competency as the primary for the goal. Only one per goal can be 1. TINYINT(1), default 0.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

---

## Deep Analysis

### Business Workflows & State Machines
- **Goal-to-Competency mapping workflow:** User creates/imports a circular goal, then maps competencies from the syllabus competency bank. Mapping can happen in any order — goals can exist without competencies, but competencies cannot be mapped without a goal.
- **Primary competency toggle:** Only one competency per goal can be flagged as primary. If user marks a different competency as primary, the system must auto-demote the previous primary within the same goal. This is a single-row update with a transactional check.
- **Soft-delete workflow:** Deactivating a goal cascades to its competency mappings (soft delete). However, a goal with active mappings cannot be deleted — the user must remove mappings first. This creates a two-step teardown process.

### Validation Rules & Edge Cases
- **Unique code enforcement:** `code` has a UNIQUE constraint at the database level. The UI must validate uniqueness before submission to avoid a 500 error on duplicate.
- **Single-class constraint:** A goal is assigned to exactly one class. If the same NEP goal applies to multiple classes, the user must create N separate records. The system should not auto-duplicate.
- **Cross-goal competency sharing:** A competency can be mapped to multiple goals concurrently. No restriction — but the UI must handle the case where a competency is the primary for two different goals.
- **Empty mappings state:** A goal can exist with zero competency mappings. The mapping panel shows an empty state with a CTA to add the first mapping.
- **Duplicate mapping prevention:** The unique constraint on (`circular_goal_id`, `competency_id`) prevents double-linking. The UI should grey out already-mapped competencies in the dropdown.

### Integration Points
- **`sch_classes`** — Goal-to-class assignment FK. Filtering and listing depend on class master data.
- **`slb_competencies`** — The competency bank. Any change to competency names/codes here reflects in the mapping panel of this tab.
- **`sys_dropdown_table`** — NEP reference document types could be stored here for the dropdown.
- **NEP/PARAKH document references** — External references stored as free-text (`nep_reference`). No FK enforcement.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View goals | ✅ | ✅ | ✅ | ✅ |
| Create goal | ❌ | ❌ | ✅ | ✅ |
| Edit goal metadata | ❌ | ❌ | ✅ | ✅ |
| Map/unmap competencies | ❌ | ❌ | ✅ | ✅ |
| Toggle primary competency | ❌ | ❌ | ✅ | ✅ |
| Delete (soft) goal | ❌ | ❌ | ✅ | ✅ |
| Import goals from NEP | ❌ | ❌ | ❌ | ✅ |
