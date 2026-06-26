# TimetableFoundation — Class Subject Groups & Subgroups

## What It Does
Defines groupings of subjects within a class for scheduling purposes. Subject groups allow related subjects to be scheduled together (e.g., all Science subjects in the morning). Subgroups split a class into smaller groups for different subjects (e.g., half class takes Art while other half takes Music).

## Tenant Admin Context
Curriculum planners define which subjects are grouped together and how classes are split into subgroups for elective or optional subjects. These groupings drive activity generation and constraint-based scheduling.

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_class_subject_groups` | `id`, `class_id`, `academic_session_id`, `group_name`, `total_periods`, `is_active` |
| `tt_class_subject_subgroups` | `id`, `group_id`, `section_id`, `subject_id`, `periods`, `is_active` |
| `tt_class_requirement_groups` | `id`, `class_id`, `group_type`, `name`, `total_weekly_periods`, `is_active` |
| `tt_class_requirement_subgroups` | `id`, `requirement_group_id`, `section_id`, `subject_id`, `periods_per_week`, `is_active` |
| `tt_class_mode_rules` | `id`, `class_id`, `rule_type`, `configuration` (JSON) |
| `tt_class_subgroup_members` | `id`, `subgroup_id`, `student_id` |

## Business Rules
1. **Subject groups**: Subjects with shared scheduling properties are grouped (e.g., Languages, Sciences, Arts).
2. **Subgroups**: A class can be split into subgroups for parallel scheduling — Art half vs Music half at the same time.
3. **Requirement groups**: Define per-group period requirements (e.g., Languages require 10 periods/week total).
4. **Subgroup members**: When subgroups are student-based, individual student membership is tracked.
5. **Mode rules**: Define scheduling modes per class — e.g., "Morning Academics, Afternoon Activities".

## Process Flow: Subject Group Lifecycle
1. Admin defines subject groups for a class (e.g., Core, Electives, Remedial).
2. Within each group, admin specifies subgroup splits (if any) with section+subject+periods.
3. Requirement groups aggregate period requirements per subject across sections.
4. Activity generation reads groups and subgroups to create activities.
5. The solver uses groups for parallel scheduling constraints.

## CRUD Operations
- **Create/Read/Update/Delete**: Class subject groups, subgroups, requirement groups, mode rules

## Permissions
- **Admin**: Full CRUD
