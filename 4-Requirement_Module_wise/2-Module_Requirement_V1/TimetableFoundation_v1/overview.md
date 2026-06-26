# TimetableFoundation — Module Overview

## What It Does
TimetableFoundation is the shared infrastructure module that provides all prerequisite data, configuration masters, and resource management for both SmartTimetable (AI generation) and StandardTimetable (manual placement). Every timetable in the system — whether AI-generated or manually built — depends on TimetableFoundation for its foundational data structures.

## Module Architecture
TimetableFoundation sits as the base layer in a 3-tier timetable stack:

```
SmartTimetable (AI-generation engine)     StandardTimetable (manual placement)
         |                                         |
         +------------------+----------------------+
                            |
              TimetableFoundation (shared infrastructure)
                            |
               SchoolSetup, Prime (lower modules)
```

## Controllers (27)
- `ActivityController` — Activity definition, batch generation, priority, activity teachers
- `SubActivityDetailController` — Per-period sub-activity planning
- `TimetableController` — Shared timetable CRUD operations
- `TimetableTypeController` — Timetable type definitions
- `ClassTimetableTypeController` — Class-to-timetable-type assignments
- `AcademicTermController` — Academic term management
- `SchoolDayController` — School day definitions
- `DayTypeController` — Day type classifications (holiday, working, etc.)
- `WorkingDayController` — Working day calendar with AJAX operations
- `ClassWorkingDayController` — Class-specific working day overrides
- `SchoolShiftController` — School shift management
- `PeriodTypeController` — Period type definitions (lecture, lab, break, etc.)
- `PeriodConfigController` — Master timeslot grid configuration
- `PeriodSetController` — Period set grouping and sync operations
- `PeriodSetPeriodController` — Period-to-set mapping
- `TeacherAssignmentRoleController` — Teacher role assignments
- `TeacherAvailabilityController` — Teacher availability ratio and calendar
- `TeacherAvailabilityLogController` — Teacher availability change tracking
- `RoomAvailabilityController` — Room availability ratio and calendar
- `ConfigController` — Timetable configuration settings
- `PriorityConfigController` — Priority configuration management
- `RequirementConsolidationController` — Requirement consolidation generation
- `SlotRequirementController` — Slot requirement management
- `ClassSubjectSubgroupController` — Class-subject subgroup management
- `SchoolTimingProfileController` — School timing profiles
- `TimingProfileController` — Timing profile management
- `TimetableFoundationController` — Main menu navigation and pages

## Models (34)

| Model | Table | Purpose |
|---|---|---|
| `Activity` | `tt_activities` | Teaching activity (class+section+subject+teacher) |
| `ActivityPriority` | `tt_activity_priorities` | Priority ranking for activities |
| `ActivityTeacher` | `tt_activity_teachers` | Teacher-to-activity pivot |
| `AcademicTerm` | `tt_academic_terms` | Academic term definitions |
| `Timetable` | `tt_timetables` | Timetable header (shared) |
| `TimetableType` | `tt_timetable_types` | Timetable type classification |
| `TimetableCell` | `tt_timetable_cells` | Individual cell placement |
| `TimetableCellTeacher` | `tt_timetable_cell_teachers` | Teacher-to-cell pivot |
| `ClassTimetableType` | `tt_class_timetable_types` | Class-to-timetable-type assignment |
| `SchoolDay` | `tt_school_days` | School day definitions |
| `DayType` | `tt_day_types` | Day type classifications |
| `WorkingDay` | `tt_working_days` | Calendar of working days |
| `ClassWorkingDay` | `tt_class_working_days` | Class-specific working day overrides |
| `SchoolShift` | `tt_shifts` | School shift definitions |
| `PeriodType` | `tt_period_types` | Period type (lecture/lab/break) |
| `PeriodConfig` | `tt_period_configs` | Timeslot grid configuration |
| `PeriodSet` | `tt_period_sets` | Period set grouping |
| `PeriodSetPeriod` | `tt_period_set_periods` | Period-to-set mapping |
| `Config` | `tt_configs` | Timetable configuration settings |
| `PriorityConfig` | `tt_priority_configs` | Priority configuration |
| `TeacherAssignmentRole` | `tt_teacher_assignment_roles` | Teacher role assignments |
| `TeacherAvailability` | `tt_teacher_availabilities` | Teacher availability records |
| `TeacherAvailabilityLog` | `tt_teacher_availability_logs` | Teacher availability change log |
| `RoomAvailability` | `tt_room_availabilities` | Room availability records |
| `RoomAvailabilityDetail` | `tt_room_availability_details` | Per-period room availability |
| `SlotRequirement` | `tt_slot_requirements` | Slot requirement definitions |
| `RequirementConsolidation` | `tt_requirement_consolidations` | Consolidated requirement records |
| `ClassSubjectGroup` | `tt_class_subject_groups` | Class-subject groupings |
| `ClassSubjectSubgroup` | `tt_class_subject_subgroups` | Class-subject subgroupings |
| `ClassRequirementGroup` | `tt_class_requirement_groups` | Class requirement groups |
| `ClassRequirementSubgroup` | `tt_class_requirement_subgroups` | Class requirement subgroups |
| `SubActivity` | `tt_sub_activities` | Sub-activity definitions |
| `SubActivityDetail` | `tt_sub_activity_details` | Per-period sub-activity planning |
| `SchoolTimingProfile` | `tt_school_timing_profiles` | School timing profiles |

## Views
172 Blade files covering all CRUD screens, menu pages, partials for pre-requisites setup, configuration, masters, requirements, preparation, reports, and resource availability.

## Permissions (24 policies)
AcademicTermPolicy, ActivityPolicy, ClassSubgroupPolicy, DayPolicy, PeriodPolicy, and 19 other policies scoped to individual entities.

## Integration With Other Modules
| Module | What It Provides | What Foundation Needs |
|---|---|---|
| SchoolSetup | ClassSection, Room, Subject | Classes, sections, rooms, subjects for activities |
| Prime | AcademicSession | Session context for activities/scheduling |
| StudentProfile | Teacher/Staff | Teacher assignment to activities |
| SmartTimetable | Uses Foundation data for generation | Full activity + availability + period data |
| StandardTimetable | Uses Foundation data for manual placement | Full activity + availability + period data |
