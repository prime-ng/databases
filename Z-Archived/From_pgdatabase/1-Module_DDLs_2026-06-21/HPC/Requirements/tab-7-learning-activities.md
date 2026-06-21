# HPC Tab 7: Learning Activities

This tab manages the learning activities that serve as evidence for student evaluations in the HPC module. A learning activity is a specific task or exercise assigned to a topic — such as a project, group discussion, field work, or art activity. Each activity has a type drawn from a master list, a description, and an expected outcome.

---

## How It Works

The screen is divided into two sections. The top section lists all activity types in a master table. Each type has a code (e.g., PROJECT, OBSERVATION, FIELD_WORK, GROUP_WORK, ART, SPORT, DISCUSSION), a display name, and a description. The user can add new activity types, edit existing ones, or deactivate types that should no longer be available for selection. These activity types are system-level and apply across all classes and subjects.

The bottom section lists the actual learning activities. The user selects a topic from a class-subject-topic hierarchy (class → subject → lesson → topic). Once a topic is selected, all activities linked to that topic are displayed in a table. Each row shows the activity type, the description of the activity, and the expected outcome.

The user can add a new activity by selecting an activity type from the dropdown (populated from the master list), writing a description of what the student should do, and describing the expected learning outcome. Multiple activities can be linked to the same topic. Activities can also be edited or soft-deleted.

Learning activities created here become available as evidence sources when teachers perform student evaluations in Tab 6. When a teacher selects "Activity" as the evidence type, the evidence_id dropdown is populated from these learning activities for the relevant topic.

---

## Important Business Rules

- Activity type codes must be unique across the system. No two types can share the same code.
- Each activity type must have a non-empty name and description.
- Activity types cannot be deleted if they are referenced by one or more learning activities. They can only be deactivated (is_active = 0).
- A learning activity must belong to exactly one topic. It cannot exist independently.
- The same topic can have multiple activities of the same or different types — there is no restriction.
- Activity descriptions and expected outcomes support free-text entry. Both fields are optional individually, but at least one must be provided when creating an activity.
- Deactivating an activity type automatically marks all linked learning activities as inactive.
- Activities use soft delete. Deleted activities are excluded from the evidence dropdown in Tab 6.

---

## Database Columns & Behavior

### hpc_learning_activity_type
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique type code. Options: PROJECT, OBSERVATION, FIELD_WORK, GROUP_WORK, ART, SPORT, DISCUSSION. VARCHAR(30) NOT NULL. UNIQUE.
- `name` — Display name for the type. VARCHAR(100) NOT NULL.
- `description` — Explanation of what this activity type involves. VARCHAR(255) NOT NULL.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

### hpc_learning_activities
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `topic_id` — FK to slb_topics. The topic this activity is linked to. INT UNSIGNED NOT NULL.
- `activity_type_id` — FK to hpc_learning_activity_type. The type of activity. INT UNSIGNED NOT NULL.
- `description` — Detailed description of the activity. TEXT NOT NULL.
- `expected_outcome` — Description of the expected learning outcome. TEXT. NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

---

## Deep Analysis

### Business Workflows & State Machines
- **Dual-panel workflow:** The top panel manages the activity type master list (system-level codes). The bottom panel manages the actual learning activities linked to topics. Changes in the top panel (e.g., deactivating a type) cascade to the bottom panel.
- **Activity-to-Topic linking:** A learning activity must belong to exactly one topic. The user navigates a class → subject → lesson → topic hierarchy to select the target topic, then adds activities. Activities are the leaf nodes in this hierarchy.
- **Evidence source flow:** Activities created here become available as evidence sources in Tab 6 (Student Evaluation). When a teacher selects "Activity" as evidence type, the evidence_id dropdown is populated from `hpc_learning_activities` filtered by the relevant topic.
- **Type deactivation cascade:** Deactivating an activity type (`is_active = 0`) automatically marks all linked learning activities as inactive. This prevents them from appearing in the evidence dropdown but preserves historical evaluation links.

### Validation Rules & Edge Cases
- **Unique type code enforcement:** Activity type codes (PROJECT, OBSERVATION, etc.) must be unique. Once created, a code cannot be changed because it may be referenced programmatically in the evidence flow.
- **At-least-one-field rule:** When creating an activity, at least one of `description` or `expected_outcome` must be provided. Both are optional individually but cannot both be empty.
- **Delete protection for types:** An activity type cannot be deleted (soft or hard) if any learning activity references it. Only deactivation is allowed. The UI should show the count of dependent activities before deactivation.
- **Topic selection prerequisite:** The user must select a topic before the activity list and "Add Activity" button become available. The initial state shows a prompt: "Select a topic to manage activities."
- **Empty state per topic:** A topic can have zero activities. The activity table shows an empty state with a CTA to add the first activity.
- **Multiple activities per topic:** No restriction on quantity or type. A topic can have 10+ activities, all of the same type or mixed.

### Integration Points
- **`slb_topics`** — The parent entity for all activities. If a topic is deleted from the syllabus, its linked activities lose context but remain in the database (soft-delete recommended).
- **`hpc_learning_activity_type`** — Shared reference table. Activity type names/codes are used in dropdowns across Tabs 7 and 10.
- **`hpc_student_evaluation`** (Tab 6) — Consumes activities as evidence. The `evidence_id` FK in evaluations links back to `hpc_learning_activities.id`.
- **`hpc_configuration`** (Tab 10) — The activity type master list is also configurable from Tab 10. Changes made in either tab sync to the same table.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View activity types | ✅ | ✅ | ✅ | ✅ |
| View learning activities | Own subjects only | Own class only | All | All |
| Create activity type | ❌ | ❌ | ✅ | ✅ |
| Create learning activity | Own subjects only | Own class only | ✅ | ✅ |
| Edit activity | Own only | Own class only | All | All |
| Delete (soft) activity | Own only | Own class only | All | All |
| Deactivate activity type | ❌ | ❌ | ✅ | ✅ |
