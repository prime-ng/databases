# TimetableFoundation — Activity Management

## What It Does
Activity management is the core of timetable preparation. An activity represents a teaching assignment — a specific subject taught to a specific class-section by a specific teacher for a specific study format (lecture, lab, tutorial) with a defined number of weekly periods. Activities can be generated in batch from curriculum requirements, prioritised, assigned to teachers, and split into sub-activities for detailed period-level planning.

## Tenant Admin Context
Curriculum coordinators define class-subject-format combinations. Academic heads assign teachers to activities. Administrators set activity priorities, batch-generate activities from subject allocations, and manage sub-activity details for complex scheduling (e.g., a 3-period lab vs a 1-period lecture).

## Database Tables Read / Written

| Table | Fields Used |
|---|---|
| `tt_activities` | `id`, `class_id`, `section_id`, `subject_id`, `study_format_id`, `subject_type_id`, `teacher_id`, `academic_term_id`, `weekly_periods`, `priority_id`, `status`, `is_active` |
| `tt_activity_teachers` | `activity_id`, `teacher_id`, `is_primary`, `allocation_pct` |
| `tt_activity_priorities` | `id`, `name`, `level`, `color`, `is_active` |
| `tt_sub_activities` | `id`, `activity_id`, `name`, `periods_per_week`, `study_format_id`, `teacher_id`, `is_active` |
| `tt_sub_activity_details` | `id`, `sub_activity_id`, `day_of_week`, `period_ord`, `duration_periods`, `room_id`, `notes` |

## Business Rules
1. **Activity uniqueness**: A class+section+subject+study_format combination should be unique within an academic term.
2. **Weekly periods**: Total weekly periods across sub-activities should match the parent activity's `weekly_periods`.
3. **Teacher assignment**: Activities can have multiple teachers via the `activity_teachers` pivot with allocation percentage.
4. **Batch generation**: Activities can be auto-generated from `ClassSubjectGroup` + `SlotRequirement` data, creating one activity per class-section-subject-format combination.
5. **Priority system**: Activities are ranked by priority (color-coded: Critical, High, Normal, Low). Priority influences solver behaviour (high-priority activities placed first).
6. **Sub-activity splitting**: A single activity (e.g., "Maths — 5 periods/week") can be split into sub-activities (e.g., "Maths Lecture — 3 periods", "Maths Lab — 2 periods") for granular scheduling.
7. **Sub-activity details**: Each sub-activity can specify day, period, duration, and room preferences for semi-automated placement.

## Process Flow: Activity Lifecycle
### Creation
1. Admin navigates to Activity Management → Create
2. Selects class, section, subject, study format, academic term
3. Optionally assigns teacher(s) via `activity_teachers` pivot
4. Sets weekly periods count and priority
5. Saves activity record

### Batch Generation
1. Admin generates activities from curriculum requirements
2. System reads `ClassSubjectGroup` + `SlotRequirement` records
3. Creates one activity per class-section-subject-format combination with default weekly periods
4. Activities are created in DRAFT status for teacher assignment

### Sub-Activity Planning
1. Admin selects an activity → Sub-Activity tab
2. Creates sub-activities (e.g., split 5 periods into 3+2)
3. For each sub-activity, optionally specifies day+period+room preferences
4. Sub-activity details feed into the solver as hints/constraints

### Priority Management
1. Admin sets priority per activity from predefined levels
2. Priority influences solver generation order
3. Priority can be bulk-updated for related activities

## CRUD Operations
- **Create**: Activity, activity teachers (pivot), sub-activities, sub-activity details
- **Read**: Activity list with filters (class, section, subject, teacher, status), priority levels
- **Update**: Activity attributes, teacher assignments, priority, sub-activity details
- **Delete**: Activity (with cascade to sub-activities), teacher pivot

## Permissions
- **Admin**: Full CRUD on activities, sub-activities, priorities
- **Teacher**: View assigned activities only
