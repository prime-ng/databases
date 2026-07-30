# TimetableFoundation Module — Business Requirements Overview

## Module Purpose

The TimetableFoundation module is the shared infrastructure layer that provides all prerequisite data, configuration masters, and resource management for both SmartTimetable (AI generation) and StandardTimetable (manual placement). Every timetable in the system — whether AI-generated or manually built — depends on TimetableFoundation for its foundational data structures.

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

The module owns all `tt_*` migrations and provides the authoritative data contract that the schedulers consume. It does not generate or display timetables; it ensures all scheduling inputs — periods, shifts, working days, activities, teacher availability, room availability, and requirements — exist and are validated before generation begins.

## Default Data Load

The TimetableFoundation entry screen is a static menu-driven page. No database queries are executed on page load. The user navigates to any of 7 main menu pages, each of which loads its own data via dedicated controllers and AJAX endpoints.

The 7 main menu pages are:
1. Pre-Requisites Setup
2. Timetable Configuration
3. Timetable Masters
4. Timetable Requirement
5. Resource Availability
6. Timetable Preparation
7. Reports and Logs

---

## Pre-Requisites Setup — Read-Only Reference Data

This page displays read-only reference data sourced entirely from the SchoolSetup and StaffProfile modules. No create, edit, or delete operations are permitted here — the data is consumed from upstream modules.

**Sub-tabs / Sections:**

| Section | Data Displayed | Source Module |
|---------|---------------|---------------|
| Buildings | Building name, code, type, floor count, room count | SchoolSetup |
| Room Types | Room type code, name, capacity range, class-house flag | SchoolSetup |
| Rooms | Room name, building, room type, capacity, lab flag, availability | SchoolSetup |
| Teacher Profiles | Teacher name, subject specialisation, shift preference, employment nature | StaffProfile |
| Classes & Sections | Class name, section codes, total sections per class | SchoolSetup |
| Subjects & Formats | Subject name, code, study formats available (Lecture, Lab, Practical, etc.) | SchoolSetup |
| School Class Groups | Group name, classes in group, subjects mapped, weekly period counts | SchoolSetup |

---

## Timetable Configuration — System Settings

This page manages global system settings that govern timetable behaviour across the school.

**Tab 1 — Timetable Config (`tt_configs`)**
Key-value configuration store for timetable-wide settings. Keys are system-defined and immutable; values are inline-editable based on the `tenant_can_modify` flag. Supports value types: STRING, NUMBER, BOOLEAN, DATE, TIME, DATETIME, JSON. Used by SmartTimetable solver for parameters like max teacher weekly periods.

**Tab 2 — Academic Terms (`sch_academic_term`)**
Academic term/quarter/semester structure within a school session. Defines term start/end dates, teaching days, exam days, period counts per day, and travel/resting gap rules. Date overlap validation enforced across terms in the same session. Term counters auto-update when working day types change.

**Tab 3 — Generation Strategy (`tt_generation_strategies`)**
Algorithm configuration for the SmartTimetable solver. Supports algorithm types: Recursive, Genetic, Simulated Annealing, Tabu Search, Hybrid. Each strategy defines parameters such as max recursive depth, population size, cooling rate, timeout, and activity sorting method. Only one strategy may be the default at any time.

---

## Timetable Masters — Core Entity Definitions

This page contains all master entity definitions that collectively define the school's timetable structure. It is the largest page with the most sub-tabs.

**Tab 1 — Shifts (`tt_shifts`)**
School operational shifts: Morning, Afternoon, Evening. Defines shift code, name, ordinal, default start/end time. Shift code, name, and ordinal each enforce unique constraints.

**Tab 2 — Day Types (`tt_day_types`)**
Day type classifications: STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY. Each day type defines whether it is a working day and whether it has reduced periods.

**Tab 3 — Period Types (`tt_period_types`)**
Period type definitions: THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE. Controls scheduling behaviour via flags: is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period. Includes colour code and icon for UI display.

**Tab 4 — Teacher Assignment Roles (`tt_teacher_assignment_roles`)**
Role definitions for teacher assignments: PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE. Controls workload factor (0.25–3.00), allows_overlap flag (for library/special teachers handling multiple classes in parallel), and is_primary_instructor flag.

**Tab 5 — School Days (`tt_school_days`)**
Reference data for the 7 days of the week (MON–SUN). Each day has a code, name, short name, day_of_week ordinal, and is_school_day flag. This is seeded reference data — 7 rows only.

**Tab 6 — Working Days (`tt_working_days`)**
Calendar of working days for the academic session. Each date has up to 4 simultaneous day types (e.g., Exam + Study, PTM + Study). FullCalendar widget for visual date editing. "Initialise Calendar" button auto-generates records for the entire session range.

**Tab 7 — Class Working Days (`tt_class_working_days_jnt`)**
Class-specific working day overrides. Allows per-class exception flags: is_exam_day, is_ptm_day, is_half_day, is_holiday, is_study_day. Scoped to a class+section+date combination.

**Tab 8 — Period Configs (`tt_period_configs`)**
Centralised school-wide period timeslot master (v7.7 design). Defines the SINGLE fixed daily timeslot grid per shift. All period timings (start_time, end_time, duration_minutes) are defined here and inherited by period sets. Duration is database-computed (GENERATED STORED).

**Tab 9 — Period Sets (`tt_period_sets`)**
Defines WHICH period range a class group uses from the master period config grid. Specifies shift_id, from_period_ord, to_period_ord, total_periods, teaching_periods, exam_periods, free_periods. Only one period set may be the default.

**Tab 10 — Period Set Periods (`tt_period_set_periods_jnt`)**
Maps which timeslots from tt_period_configs are included in each period set. Timing is inherited from the period config; period type can be overridden per set if needed. Local ordinal within the set defines display sequence.

**Tab 11 — Timetable Types (`tt_timetable_types`)**
Timetable type classifications: STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM. Each type is linked to a shift and has effective date range, school start/end time, and flags for has_teaching and has_exam. School time overlap validation enforced per shift.

**Tab 12 — Class Timetable Types (`tt_class_timetable_types_jnt`)**
Assigns timetable types to specific classes and sections with a linked period set. Supports "applies_to_all_sections" flag for blanket coverage or specific section assignment. Includes weekly period counts derived from the period set.

**Tab 13 — Timing Profiles (`tt_timing_profiles`)**
Effective date range plus period set linking for defining timing profiles that vary by season or examination period.

**Tab 14 — School Timing Profiles (`tt_school_timing_profiles`)**
School-level timing profile overrides. Currently implemented with a SchoolShift alias workaround pending dedicated model creation.

---

## Timetable Requirement — Scheduling Inputs

This page defines what needs to be scheduled — the core input data for timetable generation.

**Tab 1 — Slot Requirements (`tt_slot_requirements`)**
Per-class-section-timetable-type-term slot definitions. Records the weekly total slots, teaching slots, exam slots, and free slots for each class+section combination. "Generate Slot Requirements" button auto-creates records from class-timetable-type assignments.

**Tab 2 — Requirement Groups (`tt_class_requirement_groups`)**
Class requirement group definitions. Each group links a class, section, subject, study format, and subject type together. Stores student count (from class-section-junction), eligible teacher count, required room type, and class house room. AJAX toggle for sharing configuration.

**Tab 3 — Requirement Subgroups (`tt_class_requirement_subgroups`)**
Subgroup breakdown within requirement groups. Supports sharing flags: is_shared_across_sections, is_shared_across_classes. Student count and eligible teacher count are fetched from upstream data. Used for merged sections or cross-class subject groups.

**Tab 4 — Requirement Consolidation (`tt_requirement_consolidations`)**
The most critical tab — consolidates all requirement data into actionable records per class-section-subject-study-format-term. Editable fields: required_weekly_periods, min/max periods per week/day, consecutive period rules, preferred/avoid periods (JSON), spread_evenly flag, compulsory_room_type. "Generate Requirements" button creates records in bulk. Colour-coded gap indicator (red = under-allocated, green = balanced, yellow = over-allocated). Statistics summary panel.

---

## Resource Availability — Teacher & Room Matrices

This page captures teacher and room availability data used by the solver to place activities in valid time slots.

**Tab 1 — Teacher Availability (`tt_teacher_availabilities`, `tt_teacher_availability_details`)**
Two-level UI: (a) Master list of teachers with availability summary (max/min weekly periods, allocation strictness, priority weight); (b) Per-slot matrix grid (rows = periods, columns = days Mon–Sat). Each cell toggles between Available/Unavailable via colour-coded single-click. "Generate Teacher Availability" button creates default records from requirement consolidations. Database-computed fields: available_for_full_timetable_duration (GENERATED STORED), no_of_days_not_available (GENERATED STORED).

**Tab 2 — Teacher Availability Log (`tt_teacher_availability_logs`)**
Audit log recording all changes to teacher availability. Read-only DataTable with columns: Teacher Name, Changed By, Changed Date, Day, Period, Old Value, New Value, Reason. Filterable by teacher and date range.

**Tab 3 — Room Availability (`tt_room_availabilities`, `tt_room_availability_details`)**
Similar to teacher availability but scoped to rooms. Room selector with room type filter → per-slot matrix grid. Tracks overall_availability_status (Available, Unavailable, Partially Available, Assigned), capacity, max_limit, and room usage flags (lecture, practical, exam, activity, sports). "Generate Room Availability" button creates default records.

---

## Timetable Preparation — Activity Planning

This page defines the teaching activities that will be scheduled by the solver.

**Tab 1 — Activities (`tt_activities`)**
Core activity records representing unique class-section-subject-study-format combinations per academic term. Each activity defines: required_weekly_periods, min/max periods per week/day, consecutive period rules, split_allowed, priority, difficulty_score, room requirements (room type, specific room), and status (DRAFT → ACTIVE → ARCHIVED). "Generate All Activities" batch process creates activities from requirement consolidations with progress bar polling. Inline AJAX priority update.

**Tab 2 — Sub-Activities (`tt_sub_activities`, `tt_sub_activity_details`)**
Per-period sub-activity planning within a parent activity. Supports merged sections/subgroups. Sub-activity details define per-period teacher assignment, room assignment, time slot, and assignment status (UNASSIGNED → TEACHER_ASSIGNED → ROOM_ASSIGNED → FULLY_ASSIGNED). Seeding functionality for batch creation of detail records.

**Tab 3 — Activity Teacher Mapping (`tt_activity_teachers`)**
Maps teachers to activities with specific assignment roles (PRIMARY, ASSISTANT, CO_TEACHER, etc.). Each mapping has an ordinal for ordering and an is_required flag for mandatory teacher assignment. Unique constraint on (activity_id, teacher_id).

**Tab 4 — Priority Config (`tt_priority_configs`)**
Automatic priority scoring for requirement consolidations. Calculates: teacher_scarcity_index, weekly_load_ratio, average_teacher_availability_ratio, rigidity_score, resource_scarcity, and subject_difficulty_index. These scores drive the solver's activity sequencing. "Recalculate" button refreshes all scores.

---

## Reports and Logs — Analytics

This page provides read-only analytics and timetable display data for the school management.

**Class-Wise Timetable** — Grid display of scheduled periods per class+section, showing subject, teacher, and room for each slot. Filterable by academic term and timetable type.

**Teacher-Wise Timetable** — Per-teacher schedule grid showing their assigned periods across the week with class, subject, and room details.

**Room Utilisation Analysis** — Percentage of available teaching slots that are scheduled in each room. Rooms below 50% highlighted yellow; above 90% highlighted red.

**Teacher Workload Analysis** — Summary of allocated periods vs max configured weekly periods per teacher. Over 100% = overloaded (red). Under 70% = under-loaded (yellow).

**Core Tables:** `tt_timetables`, `tt_timetable_cells`, `tt_timetable_cell_teachers`, `tt_teacher_workloads`

---

## Requirements

- The system MUST provide shared infrastructure for both AI-generated and manually-placed timetables, ensuring all `tt_*` data structures are available before scheduler execution
- The system MUST support a six-step pre-generation setup workflow: Pre-Requisites → Configuration → Masters → Requirements → Resource Availability → Activity Planning
- The system MUST enforce data integrity through DB-level constraints (CHECK, UNIQUE, FOREIGN KEY, GENERATED STORED columns) and application-level validation (FormRequests with cross-field rules)
- The system MUST maintain unique constraint enforcement on shift code/name/ordinal, period slot positions, teacher-day-period availability slots, and activity-code across all entities
- The system MUST provide AJAX-driven interactive UIs including FullCalendar for working days, colour-coded teacher availability matrices, inline-editable requirement consolidation grids, and batch generation progress polling
- The system MUST support soft-delete and full audit logging across all timetable entities with trash/restore/force-delete workflows and change-log tracking for timetable cell modifications
- The system MUST enforce role-based access control through Laravel Policies for all 23+ entity types and EnsureTenantHasModule middleware on all routes
- The system MUST provide batch generation capabilities for activities, requirements, teacher availability, and room availability with duplicate prevention and rate limiting on generation endpoints
- The system MUST support the DRAFT → GENERATED → PUBLISHED → ARCHIVED lifecycle for timetable records and DRAFT → ACTIVE → ARCHIVED lifecycle for activity records
- The system MUST enable schools to configure per-class period ranges from a centralised school-wide timeslot grid, ensuring period timings are consistent across all classes within a shift
- The system MUST provide read-only analytics reports (class-wise timetable, teacher-wise timetable, room utilisation, teacher workload analysis) with print and export capabilities

---

## Dependencies module and tables

### Primary Tables

| Table Name | Description | Module Area |
|-----------|-------------|-------------|
| `tt_configs` | Timetable configuration key-value store with type-aware editable values | Configuration |
| `tt_generation_strategies` | Algorithm configuration for SmartTimetable solver | Configuration |
| `tt_shifts` | School operational shift definitions (Morning, Afternoon, Evening) | Masters |
| `tt_day_types` | Day type classifications (Study, Holiday, Exam, Special, etc.) | Masters |
| `tt_period_types` | Period type definitions (Theory, Break, Lunch, Lab, Free, etc.) | Masters |
| `tt_teacher_assignment_roles` | Teacher role definitions (Primary, Assistant, Co-Teacher, etc.) | Masters |
| `tt_school_days` | Reference data for 7 days of the week (MON–SUN) | Masters |
| `tt_working_days` | Calendar of working days with up to 4 simultaneous day types | Masters |
| `tt_class_working_days_jnt` | Class-specific working day overrides and exception flags | Masters |
| `tt_period_configs` | Centralised school-wide period timeslot master per shift | Masters |
| `tt_period_sets` | Period set definitions (which period range a class group uses) | Masters |
| `tt_period_set_periods_jnt` | Junction mapping period config timeslots to period sets | Masters |
| `tt_timetable_types` | Timetable type classifications (Standard, Half-Day, Exam, etc.) | Masters |
| `tt_class_timetable_types_jnt` | Class-to-timetable-type assignments with period set linking | Masters |
| `tt_slot_requirements` | Per-class-section-timetable-type-term slot availability definitions | Requirement |
| `tt_class_requirement_groups` | Class requirement group definitions with subject and room mapping | Requirement |
| `tt_class_requirement_subgroups` | Subgroup breakdown with sharing flags across sections/classes | Requirement |
| `tt_requirement_consolidations` | Consolidated requirement records with editable scheduling parameters | Requirement |
| `tt_constraint_category_scopes` | Constraint category and scope definitions (system-defined) | Constraint Engine |
| `tt_constraint_types` | Constraint type definitions with weight and parameter schema | Constraint Engine |
| `tt_constraints` | Applied constraint records for timetable generation | Constraint Engine |
| `tt_teacher_unavailabilities` | Teacher unavailability records with recurring frequency support | Constraint Engine |
| `tt_room_unavailabilities` | Room unavailability records with period range support | Constraint Engine |
| `tt_teacher_availabilities` | Teacher availability records with skill, preference, and scoring data | Resource Availability |
| `tt_teacher_availability_details` | Per-day-per-period teacher availability slot matrix | Resource Availability |
| `tt_room_availabilities` | Room availability records with capacity and usage type flags | Resource Availability |
| `tt_room_availability_details` | Per-day-per-period room availability slot matrix | Resource Availability |
| `tt_priority_configs` | Auto-calculated priority scores for requirement consolidations | Preparation |
| `tt_activities` | Core teaching activity records (class-section-subject-study-format per term) | Preparation |
| `tt_sub_activities` | Sub-activity breakdown for merged sections/subgroups | Preparation |
| `tt_sub_activity_details` | Per-period sub-activity teacher and room assignment details | Preparation |
| `tt_activity_priorities` | Activity priority scoring for solver sequencing | Preparation |
| `tt_activity_teachers` | Teacher-to-activity mapping with assignment roles | Preparation |
| `tt_timetables` | Timetable header records with status lifecycle (DRAFT→GENERATED→PUBLISHED→ARCHIVED) | Generation |
| `tt_conflict_detections` | Real-time conflict detection and resolution tracking | Generation |
| `tt_resource_bookings` | Resource booking and allocation tracking for rooms, labs, equipment | Generation |
| `tt_generation_runs` | Timetable generation run tracking with algorithm version and scores | Generation |
| `tt_constraint_violations` | Hard and soft constraint violation records per generation | Generation |
| `tt_timetable_cells` | Individual timetable cell placements with lock and conflict tracking | Generation |
| `tt_timetable_cell_teachers` | Teacher-to-cell pivot with assignment role and substitute flags | Generation |
| `tt_teacher_workloads` | Per-teacher workload analytics with utilisation percentages | Reports |
| `tt_change_logs` | Audit log for timetable cell changes (create, update, lock, swap, substitute) | Audit |
| `tt_teacher_absences` | Teacher absence records with approval workflow and substitution flags | Substitution |
| `tt_substitution_logs` | Substitution assignment tracking with notification and acceptance timestamps | Substitution |

### External Module Dependencies

| Module | Nature of Dependency |
|--------|---------------------|
| **SchoolSetup** | Required — Provides Classes (`sch_classes`), Sections (`sch_sections`), Subjects (`sch_subjects`), Study Formats (`sch_study_formats`), Rooms (`sch_rooms`), Room Types (`sch_rooms_type`), Buildings (`sch_buildings`), Subject Types (`sch_subject_types`), Subject-Study-Format junctions, Class-Section junctions, Class Groups, Subject Groups |
| **Prime / GlobalMaster** | Required — Provides Academic Sessions (`glb_academic_sessions`, `sch_org_academic_sessions_jnt`) for session-level scoping of all timetable data |
| **StaffProfile** | Required — Provides Teacher Profiles (`sch_teacher_profile`), Employee data (`sch_employees`), Teacher capabilities and availability preferences |
| **SmartTimetable** | Optional — Reads TTF data for AI timetable generation; consumes all `tt_*` tables as solver input; owns `TtGenerationStrategyController` (architectural gap — controller lives in STT module) |
| **StandardTimetable** | Optional — Reads TTF data for manual timetable placement; consumes period sets, period types, timetable types, and timetable cells |
| **Syllabus** | Optional — Reads Academic Terms (`sch_academic_term`) for syllabus scheduling alignment |
| **MarksheetGeneration** | Optional — Reads Academic Terms (`sch_academic_term`) for marksheet scoping |
| **ParentPortal** | Optional — Reads timetable display data (`tt_timetable_cells`) for parent-facing timetable views |
