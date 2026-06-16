# HPC Tab 10: Configuration

This tab provides centralized management of the system-level configuration items that drive the HPC module. It brings together three key configuration areas: ability parameters (the three NEP-mandated assessment dimensions), performance descriptors (the three proficiency levels), and learning activity types (the master list of activity categories). Changes made here affect all other HPC tabs.

---

## How It Works

The screen is divided into three configuration panels, each functioning independently.

**Ability Parameters:** This panel lists the three ability parameters: Awareness, Sensitivity, and Creativity. Each entry shows the code, name, and description. The user can edit the name and description of existing parameters, but cannot add new parameters or delete the existing ones, as these three are mandated by the NEP framework. Parameters can be deactivated if needed for specific academic sessions.

**Performance Descriptors:** This panel lists the three performance levels: Beginner (ordinal 1), Proficient (ordinal 2), and Advanced (ordinal 3). Each entry shows the code, ordinal position, and description. Similar to ability parameters, these three levels are fixed by the NEP framework. The user can edit descriptions but cannot add, remove, or reorder the levels. The ordinal value determines the hierarchy — Advanced is always higher than Proficient, which is always higher than Beginner.

**Learning Activity Types:** This panel lists all available activity types such as Project, Observation, Field Work, Group Work, Art, Sport, and Discussion. Unlike the other two panels, this list is extensible. Users can add new activity types, edit existing ones, or deactivate types that should no longer be available. Each type requires a unique code, a display name, and a description. Deactivated types are excluded from dropdown selections in Tab 7 (Learning Activities) but existing references in evaluations are preserved.

---

## Important Business Rules

- The three ability parameters (Awareness, Sensitivity, Creativity) and three performance descriptors (Beginner, Proficient, Advanced) are system-defined and cannot be created or deleted by the user. Only their names and descriptions can be edited.
- Ability parameter codes must remain as AWARENESS, SENSITIVITY, CREATIVITY. These values are referenced programmatically throughout the module.
- Performance descriptor ordinals must remain as 1 (Beginner), 2 (Proficient), 3 (Advanced). These ordinals are used in scoring calculations.
- Learning activity types are fully user-manageable. New types can be added and existing ones can be modified or deactivated.
- Activity type codes must be unique. Once created, a code cannot be changed because it may be referenced programmatically.
- Deactivating an ability parameter or performance descriptor does not affect existing student evaluations — they retain their stored values. Only new evaluations are restricted from using deactivated entries.
- Deleting a learning activity type is blocked if any learning activity references it. Deactivation is the recommended approach.
- All configuration changes are logged with timestamps. There is no version history or audit trail for individual field changes.

---

## Database Columns & Behavior

### hpc_ability_parameters
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Fixed code. One of: AWARENESS, SENSITIVITY, CREATIVITY. VARCHAR(20) NOT NULL. UNIQUE.
- `name` — Display name. Editable by the user. VARCHAR(100) NOT NULL.
- `description` — Optional description of the parameter. VARCHAR(500). NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

### hpc_performance_descriptors
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Fixed code. One of: BEGINNER, PROFICIENT, ADVANCED. VARCHAR(20) NOT NULL. UNIQUE.
- `ordinal` — Numeric hierarchy. 1=Beginner, 2=Proficient, 3=Advanced. TINYINT UNSIGNED NOT NULL.
- `description` — Optional description of the level. VARCHAR(500). NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

### hpc_learning_activity_type
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `code` — Unique activity type code. Examples: PROJECT, OBSERVATION, FIELD_WORK, GROUP_WORK, ART, SPORT, DISCUSSION. VARCHAR(30) NOT NULL. UNIQUE.
- `name` — Display name. VARCHAR(100) NOT NULL.
- `description` — Description of this activity type. VARCHAR(255) NOT NULL.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

---

## Deep Analysis

### Business Workflows & State Machines
- **Three-panel independent CRUD:** Ability Parameters, Performance Descriptors, and Learning Activity Types are managed independently in three separate panels. Changes in one panel do not affect the others — except that Activity Types created here are consumed by Tab 7 and Tab 6.
- **Fixed vs. Extensible governance:** Ability Parameters (3) and Performance Descriptors (3) are NEP-mandated and immutable in count. Only names and descriptions can be edited. Activity Types are fully user-manageable — create, edit, deactivate.
- **Deactivation semantics:** Deactivating an Ability Parameter or Performance Descriptor does not affect existing evaluations — they retain stored values. Only new evaluations are restricted from using deactivated entries. This is critical for mid-session configuration changes.
- **Programmatic code reference:** Codes like AWARENESS, SENSITIVITY, CREATIVITY, BEGINNER, PROFICIENT, ADVANCED are referenced programmatically in evaluation logic. Once created, these codes cannot be changed. The UI must restrict code editing after initial creation.

### Validation Rules & Edge Cases
- **Three-parameter invariant:** The system must enforce that exactly three Ability Parameters and three Performance Descriptors exist at all times. If a deactivation reduces the count below three for new evaluations, the evaluation grid in Tab 6 will have missing rows.
- **Ordinal hierarchy enforcement:** Performance Descriptor ordinals must remain 1→2→3 (Beginner→Proficient→Advanced). The ordinal hierarchy is used in scoring calculations (Advanced > Proficient > Beginner). Changing an ordinal would break scoring logic.
- **Activity type code immutability:** Once created, an Activity Type code cannot be changed because it may be referenced programmatically. The UI should disable the code field on edit.
- **Delete protection for referenced types:** An Activity Type cannot be deleted if any `hpc_learning_activities` record references it. The system should display a count of dependent activities before blocking the delete.
- **Empty state per panel:** If no Activity Types exist, the third panel shows an empty state with a CTA to create the first type. Ability Parameters and Performance Descriptors should never be empty after seeding.
- **Mid-session deactivation warning:** Deactivating a parameter or descriptor mid-academic-session should trigger a confirmation: "Existing evaluations will retain this value. New evaluations will not show this option."

### Integration Points
- **`hpc_student_evaluation`** (Tab 6) — Consumes both Ability Parameters (as evaluation grid rows) and Performance Descriptors (as dropdown values). Changes here affect the available options in Tab 6.
- **`hpc_learning_activities`** (Tab 7) — Activity Types defined here are used as the `activity_type_id` FK in learning activities. Changing a type name updates the label in Tab 7 dropdowns.
- **`hpc_ability_parameters`** — Referenced by `hpc_student_evaluation` FK. Deactivating a parameter here removes it from new evaluations but preserves historical data.
- **`hpc_performance_descriptors`** — Referenced by `hpc_student_evaluation` FK. The ordinal is used in score calculations in the backend.
- **`hpc_learning_activity_type`** — Shared across Tabs 7 and 10. Any CRUD operation in either tab syncs to the same table.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View all configurations | ✅ | ✅ | ✅ | ✅ |
| Edit Ability Parameter name/desc | ❌ | ❌ | ❌ | ✅ |
| Edit Performance Descriptor desc | ❌ | ❌ | ❌ | ✅ |
| Create Activity Type | ❌ | ❌ | ✅ | ✅ |
| Edit Activity Type | ❌ | ❌ | ✅ | ✅ |
| Deactivate Activity Type | ❌ | ❌ | ✅ | ✅ |
| Delete Activity Type | ❌ | ❌ | ❌ | ✅ |
| Deactivate Parameter/Descriptor | ❌ | ❌ | ❌ | ✅ |
