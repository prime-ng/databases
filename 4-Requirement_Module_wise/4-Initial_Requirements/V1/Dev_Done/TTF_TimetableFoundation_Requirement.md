# TimetableFoundation Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Automated Extraction)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** TTF | **Module Path:** `Modules/TimetableFoundation`
**Module Type:** Tenant (Per-School) | **Database:** tenant_{uuid}
**Table Prefix:** `tt_*` (shared with SmartTimetable module) | **Processing Mode:** FULL
**RBS Reference:** Module G — Advanced Timetable Management (Foundation/Configuration sections)

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Scope and Boundaries](#2-scope-and-boundaries)
3. [Actors and User Roles](#3-actors-and-user-roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Module Overview

### 1.1 Purpose

TimetableFoundation is the **configuration and master data module** that provides all prerequisite data required before a timetable can be generated. It is the mandatory setup layer that SmartTimetable and StandardTimetable modules consume.

Without TimetableFoundation being fully configured, the SmartTimetable scheduler cannot run. TimetableFoundation defines:
- **What time does school happen?** — Shifts, period sets, day start/end times
- **What kind of day is it?** — Day types, working days, school day calendar
- **What are the requirements?** — Slot requirements, requirement groups, consolidation records, activities
- **Who is available?** — Teacher availability windows, room availability
- **What are the rules?** — Timetable configuration parameters, generation strategies, constraint catalog

### 1.2 Relationship with SmartTimetable

```
TimetableFoundation (TTF)         SmartTimetable (STT)
────────────────────────────────────────────────────────
Setup phase (pre-generation)  →   Generation + Management
tt_config                     →   SmartTimetableController reads
tt_period_set + periods        →   FET solver uses for time slots
tt_activity                    →   Placement engine works on activities
tt_teacher_availability        →   Constraint validation
tt_generation_strategy         →   Algorithm selection
tt_constraint_type             →   Constraint seeding
```

### 1.3 Module Position in the Platform

```
Platform Layer     Module                  Database
──────────────────────────────────────────────────────
Tenant (Per-School)  TimetableFoundation   tenant_{uuid}
                     (TTF)                  tt_config
                                            tt_period_set + _period_jnt
                                            tt_shift, tt_day_type
                                            tt_teacher_availability
                                            tt_activity + _teacher
                                            ... (50+ tt_* tables)
```

### 1.4 Module Characteristics

| Attribute          | Value                                                      |
|--------------------|------------------------------------------------------------|
| Laravel Module     | `nwidart/laravel-modules` v12, name `TimetableFoundation`  |
| Namespace          | `Modules\TimetableFoundation`                              |
| Module Code        | TTF                                                        |
| Domain             | Tenant (school-specific)                                   |
| DB Connection      | `tenant_mysql` (tenant_{uuid})                             |
| Table Prefix       | `tt_*` (shared with SmartTimetable)                        |
| Auth               | `Gate::authorize('timetable-foundation.viewAny')` in main pages; EnsureTenantHasModule MISSING on 100+ routes |
| Frontend           | Bootstrap 5 + AdminLTE 4                                   |
| Completion Status  | ~68%                                                       |
| Controllers        | 24                                                         |
| Models             | 32                                                         |
| Services           | 3                                                          |
| FormRequests       | 4                                                          |
| Tests              | 7 (module-level in Feature/ and Unit/)                     |
| Routes             | 254 lines (largest route file in project)                  |

### 1.5 Seven Menu Pages Architecture

TimetableFoundation organizes its UI into 7 main pages served by `TimetableFoundationController`, each page containing multiple tabs:

| Page | Route | Tabs |
|------|-------|------|
| 1. Pre-Requisites Setup | `pre-requisites-setup` | Buildings, Room Types, Rooms, Teacher Profiles, Class & Section, Subjects & Study Formats, School Class Groups |
| 2. Timetable Configuration | `timetable-configuration` | Timetable Config, Academic Terms, Generation Strategy |
| 3. Timetable Masters | `timetable-masters` | Shift, Day Type, Period Type, Teacher Roles, School Days, Working Days, Class Working Days, Period Sets, Timetable Types, Class Timetables |
| 4. Timetable Requirement | `timetable-requirement` | Slot Requirement, Class Requirement Groups, Class Requirement Sub-Groups, Requirement Consolidation |
| 5. Resource Availability | `resource-availability` | Teachers Availability, Teachers Availability Log, Rooms Availability |
| 6. Timetable Preparation | `timetable-preparation` | Activities, Sub-Activities, Activity Teacher Mapping |
| 7. Reports & Logs | `reports-and-logs` | Class-wise, Teacher-wise, Room-wise, Teacher Workload, Room Utilization |

---

## 2. Scope and Boundaries

### 2.1 In Scope

- Timetable configuration key-value parameters (`tt_config`)
- School shift definitions (MORNING, AFTERNOON, EVENING)
- Day type master (STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY)
- Period type master (TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE)
- Period set definitions with individual period time slots
- Working day definitions and class-specific working day overrides
- School day calendar (which specific days are which types)
- Timetable type master (STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM)
- Class-timetable-type assignment (which timetable type applies to which class for which academic term)
- Slot requirements (total available slots per class-timetable-type combination)
- Class requirement groups and sub-groups (for subject group elective handling)
- Requirement consolidation (final normalized requirement record per class-subject-studyformat)
- Academic term management (Quarter 1, Semester 1, Annual — scoped to academic session)
- Generation strategy configuration (algorithm parameters for SmartTimetable)
- Teacher availability with detailed per-day/per-period slot availability
- Teacher availability logging (history of availability changes)
- Room availability (which rooms are available when)
- Activity master (the central entity: class + subject + teacher + required periods per week)
- Activity teacher assignments (which teachers are assigned to activities)
- Sub-activity management
- Teacher assignment role master
- Class-subject subgroup management (for split groups)
- Reports page (reads from SmartTimetable analytics services)

### 2.2 Out of Scope

- Timetable generation and optimization algorithms (handled in `SmartTimetable` module)
- Manual timetable editing / cell swapping (handled in `SmartTimetable` module)
- Substitution management (handled in `SmartTimetable` module)
- Standard timetable viewing (handled in `SmartTimetable` StandardTimetableController)
- School buildings and room CRUD (handled in `SchoolSetup` module; TTF page 1 only reads this data)
- Class and section CRUD (handled in `SchoolSetup`)
- Subject CRUD (handled in `SchoolSetup`)
- Teacher profile CRUD (handled in `StaffProfile`)

### 2.3 RBS Reference Mapping

| RBS Section | RBS Feature | TimetableFoundation Coverage |
|-------------|-------------|------------------------------|
| G1.1 — Class & Section Setup | F.G1.1.1 (Configure Academic Structure) | Pre-Requisites Setup page — reads SchoolSetup data |
| G1.2 — Subject Mapping | F.G1.2.1.3 (Set weekly periods) | `tt_requirement_consolidation.required_weekly_periods` |
| G2.1 — Teacher Constraints | F.G2.1.1 (Define Teacher Availability) | `tt_teacher_availability` + `tt_teacher_availability_detail` |
| G2.1 — Teacher Preferences | F.G2.1.2 (Preferred/Restricted periods) | `tt_teacher_availability.is_primary_teacher`, `preferred_shift` |
| G3.1 — Room Configuration | F.G3.1.1 (Define Room Details) | `tt_room_availability` + `tt_room_availability_detail` |
| G4.1 — Hard Constraints | F.G4.1.1 (Mandatory Rules) | `tt_constraint_type` catalog (reference data) |
| G5.1 — Scheduler Engine | F.G5.1.1 (Generate Timetable) | `tt_generation_strategy` algorithm parameters |
| G9.2 — AI Insights | F.G9.2.1 (Optimization Suggestions) | Reports page reads SmartTimetable analytics |

---

## 3. Actors and User Roles

### 3.1 Primary Actors

| Actor | Description | Access Level |
|-------|-------------|--------------|
| School Admin | Tenant administrator | Full access to all TimetableFoundation setup pages |
| Academic Coordinator | Manages academic structure | Full CRUD on requirements, activities, availability |
| Timetable Manager | Dedicated timetable staff | Full CRUD on all TTF data; primary user |
| Principal | Reviews configuration | ViewAny only |
| Teacher | Views own availability | Read-only on own availability record |

### 3.2 Permissions

Main gate permission: `timetable-foundation.viewAny` — used by `TimetableFoundationController` for all 7 page methods.

Individual resource controllers use (target state, not fully implemented):
- `timetable-foundation.config.*`, `timetable-foundation.academic-term.*`
- `timetable-foundation.period-set.*`, `timetable-foundation.day-type.*`
- `timetable-foundation.activity.*`, `timetable-foundation.teacher-availability.*`

---

## 4. Functional Requirements

### 4.1 Timetable Configuration (FR-TTF-01)

**FR-TTF-01.1 — View Configuration**
- Display all `tt_config` key-value parameters in a table
- Group by category; show description, value type, mandatory flag
- Configuration page is Page 2 of the TTF menu

**FR-TTF-01.2 — Edit Configuration Value**
- `tenant_can_modify = 1` records: tenant can edit value
- `tenant_can_modify = 0` records: read-only display (system-defined)
- `key` field is immutable; only `value` and `key_name` are editable
- Type-aware editing: NUMBER shows numeric input, BOOLEAN shows toggle, TIME shows time picker

**FR-TTF-01.3 — Key Configuration Parameters**
- `total_number_of_period_per_day`: how many periods per school day
- `default_school_open_days_per_week`: 5 or 6 (Mon-Fri vs Mon-Sat)
- `max_weekly_periods_can_be_allocated_to_teacher`: teacher workload cap
- `min_weekly_periods_can_be_allocated_to_teacher`: minimum load
- `minimum_student_required_for_class_subgroup`: split group threshold
- `week-start_day`: which day is considered day 1 (MONDAY typically)
- `default_number_of_short_breaks_daily_before_lunch` / `after_lunch`

### 4.2 Academic Term Management (FR-TTF-02)

**FR-TTF-02.1 — Create Academic Term**
- Link an academic term to an academic session (`sch_academic_sessions`)
- Fields: term_name, term_type (QUARTER/SEMESTER/ANNUAL/TRIMESTER), start_date, end_date, academic_session_id
- Academic terms scope all timetables — a timetable is generated per academic term

**FR-TTF-02.2 — Academic Term Lifecycle**
- Full CRUD with soft delete
- Only one term should be "active" at a time per academic session (application-level rule)

**FR-TTF-02.3 — Academic Term Used By**
- `tt_class_timetable_type_jnt.academic_term_id` — determines which timetable type applies when
- `tt_requirement_consolidation.academic_term_id` — scopes requirements to a term
- `tt_activity.academic_term_id` — activities are term-scoped
- `tt_timetable.academic_term_id` — generated timetable linked to term

### 4.3 Generation Strategy Management (FR-TTF-03)

**FR-TTF-03.1 — Define Generation Strategy**
- Strategy records define algorithm parameters for the SmartTimetable generation engine
- Algorithm types: RECURSIVE, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID
- Parameters: max_recursive_depth, max_placement_attempts, tabu_size, cooling_rate, population_size, generations, timeout_seconds
- `activity_sorting_method`: LESS_TEACHER_FIRST, DIFFICULTY_FIRST, CONSTRAINT_COUNT, DURATION_FIRST, RANDOM
- `parameters_json`: additional algorithm-specific parameters

**FR-TTF-03.2 — Default Strategy**
- `is_default = 1` marks the strategy used when no override is specified
- Only one strategy should be default at a time (application rule, no DB UNIQUE constraint)

### 4.4 Shift Management (FR-TTF-04)

**FR-TTF-04.1 — Define Shifts**
- School shifts: MORNING, TODDLER, AFTERNOON, EVENING
- Fields: code (unique), name, description, default_start_time, default_end_time, ordinal
- Ordinal determines display order; UNIQUE ordinal constraint

**FR-TTF-04.2 — Shift Usage**
- `tt_timetable_type.shift_id` — a timetable type belongs to a shift
- `tt_teacher_availability.preferred_shift` — teacher shift preference

### 4.5 Day Type Management (FR-TTF-05)

**FR-TTF-05.1 — Define Day Types**
- Types: STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY
- Fields: code (unique), name, description, is_working_day, reduced_periods (flag), ordinal
- `is_working_day`: determines if timetable periods are scheduled on this day type
- `reduced_periods`: flag for days with fewer periods than normal (e.g. Sports Day)

**FR-TTF-05.2 — Day Type Usage**
- `tt_working_day.day_type_id` — each working day record has up to 4 day type associations (primary + alternates)
- `tt_class_working_day_jnt` — class-specific day type overrides

### 4.6 Period Type Management (FR-TTF-06)

**FR-TTF-06.1 — Define Period Types**
- Types: THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE
- Fields: code (unique), name, color_code, icon, is_schedulable, counts_as_teaching, counts_as_workload, is_break, is_free_period, ordinal, duration_minutes
- `is_schedulable`: whether this period type can have subjects allocated
- `counts_as_teaching`: whether this period counts in teacher's teaching load
- `counts_as_workload`: whether this period counts in teacher's workload calculation

### 4.7 Period Set Management (FR-TTF-07)

**FR-TTF-07.1 — Define Period Set**
- A period set defines the time-slot structure for a school day
- Fields: code (unique), name, total_periods, teaching_periods, exam_periods, free_periods, assembly_periods, short_break_periods, lunch_break_periods, day_start_time, day_end_time, is_default
- Example period sets: STANDARD_8P (8 periods), HALF_DAY_4P (4 periods), TODDLER_6P (6 periods)

**FR-TTF-07.2 — Define Period Slots within a Period Set**
- Each slot in `tt_period_set_period_jnt`: period_ord (sequence), code, short_name, period_type_id, start_time, end_time
- `duration_minutes` is a GENERATED COLUMN: `TIMESTAMPDIFF(MINUTE, start_time, end_time)` — auto-calculated, not stored by application
- CHECK CONSTRAINT: `end_time > start_time`
- UNIQUE on (period_set_id, period_ord) and (period_set_id, code)
- Example: P-1 08:00-08:45, BRK 08:45-09:00, P-2 09:00-09:45, ...

**FR-TTF-07.3 — Period Set Assignment**
- Period sets are assigned to class-timetable-type combinations via `tt_class_timetable_type_jnt`
- Different classes can have different period sets (e.g., nursery has 6 periods, high school has 8)

### 4.8 Working Day & School Day Management (FR-TTF-08)

**FR-TTF-08.1 — School Days**
- `tt_school_days`: the 7-day week definition (Monday through Sunday)
- Fields: day_number (1-7), day_name, is_default_working, ordinal

**FR-TTF-08.2 — Working Day Configuration**
- `tt_working_day`: school-specific working day configuration with day type assignments
- Up to 4 day types per working day record (primary day_type_id + day_type_id_2/3/4 for alternative scenarios)

**FR-TTF-08.3 — Class Working Day Override**
- `tt_class_working_day_jnt`: class-specific working day overrides
- Links academic_session, class, section, working_day for targeted exceptions
- E.g., Class 12 has exam on a day that Class 6 has normal teaching

### 4.9 Timetable Type Management (FR-TTF-09)

**FR-TTF-09.1 — Define Timetable Type**
- Types represent scheduling modes: STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM
- Fields: code (unique), name, shift_id, effective_from_date, effective_to_date, school_start_time, school_end_time, has_exam, has_teaching, ordinal, is_default
- `has_exam` and `has_teaching` flags control what can be scheduled

**FR-TTF-09.2 — Class-Timetable-Type Assignment**
- Link each class/section to a timetable type for a specific academic term
- Table: `tt_class_timetable_type_jnt`
- `applies_to_all_sections`: if 1, the assignment covers all sections of the class
- Contains weekly period counts: teaching, exam, free
- Effective date range scoping

### 4.10 Teacher Availability (FR-TTF-10)

**FR-TTF-10.1 — Teacher Availability Record**
- `tt_teacher_availability`: comprehensive availability and preference record per teacher per class-subject-studyformat
- Key fields: requirement_consolidation_id, class_id, section_id, subject_study_format_id, teacher_profile_id
- Workload parameters: required_weekly_periods, max/min_available_periods_weekly, max/min_allocated_periods_weekly
- Skill/preference: is_full_time, preferred_shift, certified_for_lab, can_be_used_for_substitution
- Generated columns: `available_for_full_timetable_duration` (STORED computed) and `no_of_days_not_available` (STORED computed)
- Priority parameters: priority_order, priority_weight, scarcity_index, allocation_strictness (Hard/Medium/Soft)
- Historical: historical_success_ratio, last_allocation_score

**FR-TTF-10.2 — Teacher Availability Detail (Slot-Level)**
- `tt_teacher_availability_detail`: per-day per-period slot availability matrix
- Fields: day_number (1-7), period_number, can_be_assigned, availability_for_period (Available/Unavailable/Assigned/Free Period)
- Used by constraint engine during generation to determine if a teacher can be placed in a slot

**FR-TTF-10.3 — Teacher Availability Log**
- `tt_teacher_availability_log`: history of all changes to teacher availability
- Provides audit trail for availability changes

**FR-TTF-10.4 — Room Availability**
- `tt_room_availability`: room-level availability record
- `tt_room_availability_detail`: per-slot room availability matrix
- Used by constraint engine to prevent room double-booking

### 4.11 Requirement Consolidation (FR-TTF-11)

**FR-TTF-11.1 — Slot Requirement**
- `tt_slot_requirement`: computed summary of total available teaching slots per class-timetable-type per term
- Derived from `tt_class_timetable_type_jnt` and `tt_timetable_type`

**FR-TTF-11.2 — Class Requirement Groups**
- `tt_class_requirement_groups`: defines subject groupings for elective/option subjects
- Used when a group of students takes one subject from a set of options

**FR-TTF-11.3 — Class Requirement Sub-Groups**
- `tt_class_requirement_subgroups`: further subdivision of requirement groups

**FR-TTF-11.4 — Requirement Consolidation**
- `tt_requirement_consolidation`: the normalized, final requirement record fed into the timetable generator
- Contains: academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format, subject_type, required_room_type, required_room, required_weekly_periods
- This is the "line item" that the FET solver processes — one record per class-subject-studyformat combination
- Managed via `RequirementConsolidationController`

### 4.12 Activity Management (FR-TTF-12)

**FR-TTF-12.1 — Activity**
- `tt_activity`: the core entity for timetable generation — represents one teaching slot assignment
- Fields: academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format, subjectStudyFormat, subject_type, required_room_type, required_weekly_periods
- Activities are what the scheduler places into time slots
- `ActivityController` manages full CRUD with rich eager loading

**FR-TTF-12.2 — Activity Teacher Assignment**
- `tt_activity_teacher`: links one or more teachers to an activity
- Fields: activity_id, teacher_id (FK to sch_teachers), assignment_role_id
- Multiple teachers can be assigned to one activity (e.g., lab practicals with assistant)
- Managed via activity teacher mapping tab

**FR-TTF-12.3 — Sub-Activity**
- `tt_sub_activity`: represents a subdivision of an activity (e.g., a practical within a science activity)
- Used for split-class scenarios

**FR-TTF-12.4 — Activity Priority**
- `tt_activity_priority`: priority configuration for activities
- Higher priority activities are placed first by the scheduling algorithm

### 4.13 Teacher Assignment Role (FR-TTF-13)

**FR-TTF-13.1 — Define Assignment Roles**
- Roles: LEAD_TEACHER, ASSISTANT_TEACHER, LAB_ASSISTANT, SUBSTITUTE
- Used in `tt_activity_teacher.assignment_role_id`
- Managed via `TeacherAssignmentRoleController`

### 4.14 Class-Subject Subgroup (FR-TTF-14)

**FR-TTF-14.1 — Subgroup Management**
- `ClassSubjectSubgroup` model manages `tt_class_subject_subgroups` (or similar table)
- Handles split-class scenarios where a class section is divided into subgroups for certain subjects
- Linked to class, section, and subject group via `classSubjectGroup`
- Managed via `ClassSubjectSubgroupController`

---

## 5. Data Model

### 5.1 Foundation Tables (Masters)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_config` | Timetable configuration parameters | key (unique), value, value_type ENUM, tenant_can_modify |
| `tt_generation_strategy` | Algorithm parameters | code (unique), algorithm_type ENUM, max_recursive_depth, tabu_size, cooling_rate, timeout_seconds |
| `tt_shift` | School shift definitions | code (unique), name, default_start_time, default_end_time, ordinal |
| `tt_day_type` | Types of school days | code (unique), name, is_working_day, reduced_periods |
| `tt_period_type` | Period classification | code (unique), name, is_schedulable, counts_as_teaching, counts_as_workload, is_break, duration_minutes |
| `tt_teacher_assignment_role` | Teacher roles in activities | code, name |
| `tt_school_days` | 7-day week reference | day_number (1-7), day_name, is_default_working |

### 5.2 Configuration Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_period_set` | Period set header | code (unique), total_periods, teaching_periods, day_start_time, day_end_time, is_default |
| `tt_period_set_period_jnt` | Individual period time slots | period_set_id, period_ord, start_time, end_time, period_type_id, duration_minutes (GENERATED) |
| `tt_working_day` | Working day configuration | day_type_id (×4 — primary + alternates) |
| `tt_class_working_day_jnt` | Class-level working day overrides | academic_session_id, class_id, section_id, working_day_id |
| `tt_timetable_type` | Timetable mode definitions | code (unique), shift_id, effective_from/to_date, has_exam, has_teaching |
| `tt_class_timetable_type_jnt` | Class ↔ timetable type assignment | academic_term_id, timetable_type_id, class_id, section_id, period_set_id, applies_to_all_sections |
| `tt_academic_term` (AcademicTerm) | Academic term definitions | academic_session_id, term_name, term_type ENUM, start_date, end_date |

### 5.3 Requirement Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_slot_requirement` | Available slot summary | academic_term_id, timetable_type_id, class_timetable_type_id, class_id, section_id |
| `tt_class_requirement_groups` | Subject group definitions | class_id, section_id, academic_term_id |
| `tt_class_requirement_subgroups` | Sub-group divisions | class_requirement_group_id, class_id, section_id |
| `tt_requirement_consolidation` | Normalized generation input | academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, required_weekly_periods |
| `tt_constraint_category_scope` | Constraint categorization | (scope/target reference data) |
| `tt_constraint_type` | Constraint type catalog | code, name, is_hard, scope |

### 5.4 Availability Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_teacher_availability` | Teacher availability master | teacher_profile_id, requirement_consolidation_id, max/min_allocated_periods_weekly, allocation_strictness ENUM, priority_weight, scarcity_index; GENERATED: available_for_full_timetable_duration, no_of_days_not_available |
| `tt_teacher_availability_detail` | Per-slot availability matrix | teacher_profile_id, day_number (1-7), period_number, can_be_assigned, availability_for_period ENUM |
| `tt_room_availability` | Room availability master | room_id, rooms_type_id |
| `tt_room_availability_detail` | Per-slot room availability | room_availability_id, day_number, period_number |

### 5.5 Activity Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `tt_activity` | Core scheduling entity | academic_term_id, timetable_type_id, class_id, section_id, subject_id, study_format_id, required_weekly_periods |
| `tt_activity_teacher` | Teacher ↔ Activity | activity_id, teacher_id, assignment_role_id |
| `tt_sub_activity` | Sub-activity (split class) | activity_id (parent reference) |
| `tt_activity_priority` | Activity priority config | activity_id, priority_level |

### 5.6 Models (32 total)

| Model | Table | Notes |
|-------|-------|-------|
| `AcademicTerm` | `tt_academic_terms` (or `sch_academic_terms`) | Has academicSession BelongsTo |
| `Activity` | `tt_activity` | Central model with 10+ BelongsTo relations |
| `ActivityTeacher` | `tt_activity_teacher` | Junction: activity + teacher + role |
| `ActivityPriority` | `tt_activity_priority` | Priority configuration |
| `ClassSubjectGroup` | (subgroup grouping) | Elective group master |
| `ClassSubjectSubgroup` | (subgroup detail) | Sub-group under group |
| `ClassSubgroupMember` | (subgroup membership) | Students in subgroups |
| `ClassModeRule` | (class mode) | Class scheduling mode rules |
| `ClassRequirementGroup` | `tt_class_requirement_groups` | Requirement groups |
| `ClassRequirementSubgroup` | `tt_class_requirement_subgroups` | Requirement sub-groups |
| `ClassTimetableType` | `tt_class_timetable_type_jnt` | Class-to-timetable-type |
| `ClassWorkingDay` | `tt_class_working_day_jnt` | Class working day overrides |
| `Config` | `tt_config` | Configuration key-value |
| `DayType` | `tt_day_type` | Day type master |
| `PeriodSet` | `tt_period_set` | Period set header |
| `PeriodSetPeriod` | `tt_period_set_period_jnt` | Individual period slots |
| `PeriodType` | `tt_period_type` | Period type master |
| `RequirementConsolidation` | `tt_requirement_consolidation` | Normalized requirements |
| `RoomAvailability` | `tt_room_availability` | Room availability master |
| `RoomAvailabilityDetail` | `tt_room_availability_detail` | Per-slot room availability |
| `SchoolDay` | `tt_school_days` | 7-day week reference |
| `SchoolShift` | `tt_shift` | Shift master |
| `SlotRequirement` | `tt_slot_requirement` | Slot availability summary |
| `SubActivity` | `tt_sub_activity` | Sub-activity |
| `TeacherAssignmentRole` | `tt_teacher_assignment_role` | Assignment role master |
| `TeacherAvailablity` | `tt_teacher_availability` | (note: typo in model name) Teacher availability |
| `TeacherAvailabilityLog` | `tt_teacher_availability_log` | Change history |
| `Timetable` | `tt_timetable` | Generated timetable header |
| `TimetableCell` | `tt_timetable_cell` | Individual cell in grid |
| `TimetableCellTeacher` | `tt_timetable_cell_teacher` | Teacher assigned to cell |
| `TimetableType` | `tt_timetable_type` | Timetable type master |
| `WorkingDay` | `tt_working_day` | Working day config |

---

## 6. Controller & Route Inventory

### 6.1 Main Hub Controller

| Controller | Pages Served | Auth |
|-----------|-------------|------|
| `TimetableFoundationController` | All 7 menu pages (7 methods) | `Gate::authorize('timetable-foundation.viewAny')` on each page method |

### 6.2 Individual Resource Controllers (24 total)

| Controller | Resource | Auth Status |
|-----------|---------|-------------|
| `ConfigController` | tt_config | Unknown |
| `AcademicTermController` | tt_academic_terms | Unknown |
| `TimetableTypeController` | tt_timetable_type | Unknown |
| `PeriodSetController` | tt_period_set | Unknown |
| `PeriodSetPeriodController` | tt_period_set_period_jnt | Unknown |
| `PeriodTypeController` | tt_period_type | Unknown |
| `DayTypeController` | tt_day_type | Unknown |
| `SchoolShiftController` | tt_shift | Unknown |
| `SchoolDayController` | tt_school_days | Unknown |
| `WorkingDayController` | tt_working_day | Unknown |
| `ClassWorkingDayController` | tt_class_working_day_jnt | Unknown |
| `ClassTimetableTypeController` | tt_class_timetable_type_jnt | Unknown |
| `TeacherAssignmentRoleController` | tt_teacher_assignment_role | Unknown |
| `TeacherAvailabilityController` | tt_teacher_availability | Unknown |
| `TeacherAvailabilityLogController` | tt_teacher_availability_log | Unknown |
| `RoomAvailabilityController` | tt_room_availability | Unknown |
| `ActivityController` | tt_activity | Gate checks present (inferred from controller code) |
| `SlotRequirementController` | tt_slot_requirement | Unknown |
| `RequirementConsolidationController` | tt_requirement_consolidation | Unknown |
| `ClassSubjectSubgroupController` | subgroup tables | Unknown |
| `TimetableController` | tt_timetable | Unknown |
| `TimingProfileController` | timing profiles | Unknown |
| `SchoolTimingProfileController` | school timing | Unknown |
| `ClassSubjectGroupController` | (imported from SchoolSetup) | Unknown |

### 6.3 Services (3)

| Service | Purpose |
|---------|---------|
| `SubActivityService` | Sub-activity management logic |
| `RoomAvailabilityService` | Room availability calculation and validation |
| A third service (TBD) | Unknown from available inspection |

### 6.4 Route File — 254 Lines (Largest in Project)

- Route prefix: `timetable-foundation` (registered via RouteServiceProvider)
- Route name prefix: `timetable-foundation.*`
- All routes under `auth` + `verified` middleware at minimum
- **CRITICAL ISSUE:** `EnsureTenantHasModule` middleware is MISSING from 100+ routes

---

## 7. Form Request Validation Rules

### 7.1 Implemented FormRequests (4)

| FormRequest | Controller | Key Rules |
|-------------|-----------|-----------|
| (FormRequest 1 of 4) | Unknown | (details not extracted) |
| (FormRequest 2 of 4) | Unknown | (details not extracted) |
| (FormRequest 3 of 4) | Unknown | (details not extracted) |
| (FormRequest 4 of 4) | Unknown | (details not extracted) |

### 7.2 Required FormRequests (Missing)

Based on the controllers present, FormRequests are needed for:
- `AcademicTermRequest` — term_name, term_type, start_date, end_date validation
- `PeriodSetRequest` — total_periods, day_start_time, day_end_time
- `PeriodSlotRequest` — start_time, end_time (end > start), period_type_id
- `ActivityRequest` — academic_term_id, class_id, subject_id, required_weekly_periods
- `TeacherAvailabilityRequest` — teacher_profile_id, max/min_allocated_periods_weekly
- `RequirementConsolidationRequest` — all FK validations

---

## 8. Business Rules

**BR-TTF-01:** A period slot's `end_time` must be greater than `start_time`. This is enforced by a DB CHECK CONSTRAINT (`chk_psp_time`) on `tt_period_set_period_jnt`.

**BR-TTF-02:** `tt_timetable_type` school start/end times must not overlap for the same shift (application-level check required — no DB constraint).

**BR-TTF-03:** The `duration_minutes` column on `tt_period_set_period_jnt` is a MySQL GENERATED STORED column — the application must never try to write this field. It auto-computes as `TIMESTAMPDIFF(MINUTE, start_time, end_time)`.

**BR-TTF-04:** When `tt_class_timetable_type_jnt.applies_to_all_sections = 1`, `section_id` must be NULL. When `applies_to_all_sections = 0`, `section_id` must be set. DB CHECK constraint enforces this: `(section_id IS NULL AND applies_to_all_sections = 1) OR (section_id IS NOT NULL AND applies_to_all_sections = 0)`.

**BR-TTF-05:** Academic terms have date ranges. Overlapping terms for the same academic session should be prevented at the application level.

**BR-TTF-06:** `tt_generation_strategy.is_default = 1` should be unique — only one default strategy at a time. No DB UNIQUE constraint exists; application must enforce.

**BR-TTF-07:** `tt_teacher_availability.available_for_full_timetable_duration` is a STORED GENERATED column (`IF(teacher_available_from_date <= timetable_start_date, 1, 0)`). Application must not write this field.

**BR-TTF-08:** `tt_teacher_availability.no_of_days_not_available` is a STORED GENERATED column (`GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))`). Application must not write this field.

**BR-TTF-09:** `tt_period_set.is_default = 1` should indicate the default period set. Application must enforce uniqueness.

**BR-TTF-10:** Teacher availability detail slots are unique per teacher per day per period: UNIQUE KEY `uq_ta_class_wise` (teacher_profile_id, day_number, period_number). Attempting to insert duplicate slot availability raises a DB error.

**BR-TTF-11:** Category menus and `tt_config` keys are system-managed. Tenant users with `tenant_can_modify = 0` must not be able to alter these configuration values.

---

## 9. Permission & Authorization Model

### 9.1 Current Implementation

- `TimetableFoundationController` pages: `Gate::authorize('timetable-foundation.viewAny')` present on all 7 page methods — PROTECTED

- Individual resource controllers: auth status is mostly unknown from code inspection; partial Gate checks exist on some

- **CRITICAL MISSING:** `EnsureTenantHasModule` middleware is absent from 100+ routes in the 254-line routes file. This middleware ensures the tenant has the TimetableFoundation module licensed before access is granted. Without it, tenants who have not purchased the timetable module can still access all endpoints directly.

### 9.2 Required `EnsureTenantHasModule` Middleware

All routes in the TimetableFoundation route file must be wrapped in:
```php
Route::middleware(['auth', 'verified', 'EnsureTenantHasModule:TimetableFoundation'])
    ->prefix('timetable-foundation')
    ->group(function () {
        // all routes here
    });
```

### 9.3 Required Gate Permissions

| Resource | Required Permissions |
|----------|---------------------|
| Config | `timetable-foundation.config.viewAny`, `.update` |
| Academic Term | `timetable-foundation.academic-term.viewAny`, `.create`, `.update`, `.delete` |
| Period Set | `timetable-foundation.period-set.viewAny`, `.create`, `.update`, `.delete` |
| Activity | `timetable-foundation.activity.viewAny`, `.create`, `.update`, `.delete` |
| Teacher Availability | `timetable-foundation.teacher-availability.viewAny`, `.create`, `.update` |
| Requirement | `timetable-foundation.requirement.viewAny`, `.create`, `.update`, `.delete` |

---

## 10. Tests Inventory

### 10.1 Current State — 7 Tests

| Test File | Type | Location |
|-----------|------|---------|
| `RouteAuthenticationTest.php` | Feature | `tests/Feature/` |
| `ControllerAuthTest.php` | Feature | `tests/Feature/` |
| `FormRequestValidationTest.php` | Feature | `tests/Feature/` |
| `ModelStructureTest.php` | Feature | `tests/Feature/` |
| `PolicyTest.php` | Feature | `tests/Feature/` |
| `ServiceTest.php` | Feature | `tests/Feature/` |
| (1 Unit test file) | Unit | `tests/Unit/` |

### 10.2 Test Coverage Assessment

The test files exist but the scope and pass/fail state of each test is unknown without running them. The naming suggests:
- `RouteAuthenticationTest`: verifies routes require authentication
- `ControllerAuthTest`: verifies Gate checks on controller methods
- `FormRequestValidationTest`: validates FormRequest rules
- `ModelStructureTest`: verifies model relationships and casts
- `PolicyTest`: verifies policy authorization
- `ServiceTest`: verifies service method behavior

### 10.3 High-Priority Missing Tests

| Test Scenario | Priority |
|--------------|----------|
| Verify `EnsureTenantHasModule` blocks access for unlicensed tenants | CRITICAL |
| Period slot `end_time > start_time` validation | HIGH |
| Generated columns (duration_minutes, available_for_full_timetable_duration) are not writable | HIGH |
| Class-timetable-type applies_to_all_sections constraint | HIGH |
| Teacher availability slot uniqueness | MEDIUM |

---

## 11. Known Issues & Technical Debt

### 11.1 Critical Issues

**ISSUE-TTF-01 [CRITICAL]:** `EnsureTenantHasModule` middleware is missing from 100+ routes in the route file (254 lines). Tenants without a timetable license can access all timetable foundation setup pages and APIs directly.

**ISSUE-TTF-02 [HIGH]:** The routes file has 254 lines — the largest in the project. This indicates the routes are not properly grouped with shared middleware. A single top-level group wrapping all routes with the `EnsureTenantHasModule` middleware would resolve both ISSUE-TTF-01 and reduce route file complexity.

### 11.2 Code Quality

**ISSUE-TTF-03 [MEDIUM]:** `TeacherAvailablity` model name contains a typo — should be `TeacherAvailability`. This typo is present in both the model filename and class name. Fixing requires a search-and-replace across all files that reference this model.

**ISSUE-TTF-04 [MEDIUM]:** Only 4 FormRequests exist for 24 controllers. The majority of controllers lack structured validation, relying on inline `$request->validate()` at best or no validation at worst.

**ISSUE-TTF-05 [LOW]:** `ClassSubjectGroupController` is imported from `Modules\SchoolSetup\Http\Controllers` (confirmed in route file imports) instead of being a native TTF controller. This cross-module controller usage creates a tight coupling between TTF and SchoolSetup.

### 11.3 Missing Features

**ISSUE-TTF-06 [MEDIUM]:** The `tt_constraint_type` table exists in the schema (constraint type catalog seeded by SmartTimetable stage 2) but there is no dedicated `ConstraintTypeController` in TimetableFoundation for viewing/editing constraint catalog entries.

**ISSUE-TTF-07 [MEDIUM]:** `tt_teacher_unavailable` and `tt_room_unavailable` tables exist in the schema (temporary unavailability: sick leave, room maintenance) but no corresponding controllers or routes appear in TimetableFoundation.

---

## 12. API Endpoints

No dedicated REST API currently. Timetable API is handled by `TimetableApiController` in the SmartTimetable module.

### 12.1 Key AJAX Endpoints (Web Routes)

| Method | Route Pattern | Description |
|--------|--------------|-------------|
| GET | `timetable-foundation/period-set/...` | Fetch period sets for selection |
| GET | `timetable-foundation/academic-term/...` | Fetch academic terms |
| GET | `timetable-foundation/activity/...` | Fetch activities |
| POST | `timetable-foundation/teacher-availability/...` | Save availability data |
| GET | `timetable-foundation/requirement-consolidation/...` | Fetch consolidation records |

---

## 13. Non-Functional Requirements

### 13.1 Performance

- `TimetableFoundationController::timetableMasters()` page loads all shifts, day types, period types, working days, period sets, timetable types, and class timetables — should complete within 800ms with eager loading
- `TimetableFoundationController::timetablePreparation()` loads all activities with 10+ relationships eagerly — should complete within 1500ms for schools with up to 200 activities

### 13.2 Data Integrity

- Generated columns (`duration_minutes`, `available_for_full_timetable_duration`, `no_of_days_not_available`) must never be written by the application. MySQL enforces this at DB level.
- DB CHECK constraints protect: period time ordering, timetable type time ordering, class-timetable-type applies_to_all_sections rule

### 13.3 Scalability

- Period set periods are the atomic time units for the entire timetable system. A school with 10 period sets × 10 periods each = 100 period slot records. This is small and performant.
- Teacher availability detail matrix (7 days × 8 periods × N teachers) could be 56×N rows for a school with 50 teachers = 2,800 rows. Indexed on (teacher_profile_id, day_number, period_number).

### 13.4 Consistency

- All configurations in TimetableFoundation must be complete and consistent before SmartTimetable generation is triggered. The SmartTimetable ValidationService should verify TTF data completeness as part of pre-generation validation.

---

## 14. Integration Points

| Module | Integration Type | Description |
|--------|-----------------|-------------|
| `SchoolSetup` | Consumer (reads data) | TTF Pre-Req page displays SchoolSetup data: buildings, rooms, room types, classes, sections, subjects |
| `StaffProfile` | Consumer (reads data) | TTF displays teacher profiles from staff profile module |
| `SmartTimetable` | Producer (provides config) | SmartTimetable reads all tt_* tables managed by TTF; generation depends on TTF data being complete |
| `StandardTimetable` | Producer (provides config) | Standard timetable display reads from TTF for period set/timetable type context |
| `Syllabus` | Cross-reference | Academic terms in TTF align with lesson scheduling in Syllabus module |
| `Auth` | RBAC | Spatie permissions gate access; `EnsureTenantHasModule` controls module licensing |
| `TimetableApiController` (SmartTimetable) | Consumer | REST API reads activities, availability, period sets from TTF tables |

---

## 15. Pending Work & Gap Analysis

### 15.1 Completion Status: ~68%

| Feature Area | Status | Gap Description |
|-------------|--------|-----------------|
| Timetable Config Management | 80% | View works; edit/save needs verification |
| Academic Term CRUD | 85% | Mostly complete; auth verification needed |
| Generation Strategy CRUD | 85% | Mostly complete |
| Shift / Day Type / Period Type | 90% | Well-implemented master data management |
| Period Set + Slots | 85% | CRUD works; generated column handling needs verification |
| Working Day / School Day | 80% | Basic management present |
| Timetable Type + Class Assignment | 80% | Complex junction; date range overlap check missing |
| Teacher Availability | 70% | Master record + detail; per-slot matrix UI completeness unknown |
| Room Availability | 65% | Master + detail; completeness unknown |
| Slot Requirement | 65% | Computation and display |
| Requirement Groups/Subgroups | 60% | Controllers present; full UI unknown |
| Requirement Consolidation | 70% | Core CRUD; complex FK management |
| Activity + Teacher Assignment | 75% | Controller and view present with rich eager loading |
| Sub-Activity | 55% | Service exists; full UI unknown |
| Class-Subject Subgroup | 60% | Controller present |
| EnsureTenantHasModule | 0% | COMPLETELY MISSING from all 100+ routes |
| FormRequests (complete coverage) | 17% | Only 4 of ~24 controllers have FormRequests |
| Service Layer (complete) | ~30% | 3 services; more needed |
| Test Coverage (complete) | ~40% | 7 tests; EnsureTenantHasModule tests missing |
| Constraint Type Catalog UI | 0% | Table exists; no UI controller |

### 15.2 Priority Remediation Items

1. **[P0 — CRITICAL]** Add `EnsureTenantHasModule:TimetableFoundation` middleware to ALL routes in the TTF route file — wrap in a single top-level group
2. **[P1]** Add auth Gate checks to all 24 individual resource controllers (most are unverified)
3. **[P1]** Create FormRequests for all major controllers (AcademicTermRequest, PeriodSetRequest, ActivityRequest, RequirementConsolidationRequest, TeacherAvailabilityRequest)
4. **[P1]** Fix `TeacherAvailablity` model typo → `TeacherAvailability` across all files
5. **[P2]** Add `tt_teacher_unavailable` and `tt_room_unavailable` controller + routes for temporary unavailability
6. **[P2]** Add Constraint Type catalog viewer (read-only list of `tt_constraint_type` entries)
7. **[P2]** Add application-level validation for overlapping `tt_timetable_type` school start/end times per shift
8. **[P3]** Consolidate 254-line routes file into properly-grouped middleware blocks
9. **[P3]** Add tests for EnsureTenantHasModule enforcement and generated column immutability
