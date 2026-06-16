# SmartTimetable Module - Database Design Guide

> **Module:** SmartTimetable (TT)
> **Table Prefix:** `tt_*` (module-owned), `sch_*` / `std_*` (referenced from other modules)
> **Total Tables:** 44 (23 module-owned + 21 reference tables)
> **Database:** tenant_db (one per tenant, no tenant_id columns)
> **DDL Version:** 7.7 - April 2026
> **Based on:** tt_timetable_ddl_v7.7.sql

---

## 1. Table Relationship Diagram

```
|  =====================================================================================
|  EXTERNAL / REFERENCE TABLES (Read-Only - TT never modifies these)
|  =====================================================================================
|
|  sch_organizations ──────────────────────┐
|  sch_org_academic_sessions_jnt ──────────┤
|  sch_board_organization_jnt ─────────────┤
|  sch_classes ────────────────────────────┤
|  sch_sections ───────────────────────────┤
|  sch_class_section_jnt ──────────────────┤
|  sch_subject_types ──────────────────────┤
|  sch_study_formats ──────────────────────┤
|  sch_subjects ───────────────────────────┤──── Referenced via Foreign Keys
|  sch_subject_study_format_jnt ───────────┤
|  sch_class_groups_jnt ───────────────────┤
|  sch_subject_groups ─────────────────────┤
|  sch_subject_group_subject_jnt ──────────┤
|  sch_buildings ──────────────────────────┤
|  sch_rooms_type ─────────────────────────┤
|  sch_rooms ──────────────────────────────┤
|  sch_employees ──────────────────────────┤
|  sch_teacher_profile ────────────────────┤
|  sch_teacher_capabilities ───────────────┤
|  std_students ───────────────────────────┤
|  std_student_academic_sessions ──────────┘
|
|  =====================================================================================
|  SECTION 0: CONFIGURATION (Admin/System setup)
|  =====================================================================================
|
|  ┌─────────────────────────────────────┐  ┌──────────────────────────────┐  ┌─────────────────────────────────┐
|  │  [S0-1] sch_academic_term           │  │  [S0-2] tt_config            │  │  [S0-3] tt_generation_strategy  │
|  │                                     │  │                              │  │                                 │
|  │  PK: id                             │  │  PK: id                      │  │  PK: id                         │
|  │  UQ: session + term_code            │  │  UQ: key, ordinal            │  │  UQ: code                       │
|  │  FK → sch_org_academic_sessions_jnt │  │  ~12-14 config rows          │  │  RECURSIVE, GENETIC,            │
|  │  ~2-4 rows/session                  │  │  Edit-only (no add/delete)   │  │  SIMULATED_ANNEALING,           │
|  │  SUMMER, WINTER, Q1-Q4              │  │                              │  │  TABU_SEARCH, HYBRID            │
|  └──────────┬──────────────────────────┘  └──────────────────────────────┘  └────────────┬────────────────────┘
|             │                                                                            │
|             │ (academic_term_id used throughout)                                         │ (strategy_id)
|             │                                                                            │
|  =====================================================================================   │
|  SECTION 1: MASTER TABLES (Foundation data)                                              │
|  =====================================================================================   │
|                                                                                          │
|  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐            │
|  │[S1-1] tt_shift       │  │[S1-2] tt_day_type    │  │[S1-3] tt_period_type │            │
|  │ PK: id               │  │ PK: id               │  │ PK: id               │            │
|  │ UQ: code, name       │  │ UQ: code, name       │  │ UQ: code             │            │
|  │ MORNING, AFTERNOON,  │  │ STUDY, HOLIDAY,      │  │ TEACHING, BREAK,     │            │
|  │ EVENING              │  │ EXAM, SPECIAL,       │  │ LUNCH, ASSEMBLY,     │            │
|  │ ~3-4 rows            │  │ PTM_DAY, SPORTS_DAY  │  │ FREE, RECESS, EXAM   │            │
|  └────┬─────────────────┘  └───────┬──────────────┘  └────┬─────────────────┘            │
|       │                            │                      │                              │
|       │                            │                      │                              │
|  ┌────▼─────────────────────────┐  │  ┌───────────────────▼──────────────────────────┐   │
|  │[S1-5] tt_school_days         │  │  │[S1-8] tt_period_config (NEW v7.7)            │   │
|  │ PK: id                       │  │  │ PK: id                                       │   │
|  │ UQ: code, day_of_week        │  │  │ UQ: shift_id + slot_ord                      │   │
|  │ MON-SUN with is_school_day   │  │  │ FK → tt_shift, tt_period_type                │   │
|  │ 7 rows                       │  │  │ Fixed daily timing grid per shift             │   │
|  └──────────────────────────────┘  │  │ ~12-15 rows/shift                             │   │
|                                    │  │ GENERATED: duration_minutes                   │   │
|  ┌─────────────────────────────────▼──┴──────────────────────────────────────────────┐   │
|  │[S1-6] tt_working_day                                                               │   │
|  │ PK: id   UQ: date                                                                 │   │
|  │ FK → tt_day_type (x4 slots: day_type1..4 for multi-activity days)                 │   │
|  │ Calendar-level school open/closed status                                           │   │
|  │ ~180-250 rows/session                                                              │   │
|  └──────────┬────────────────────────────────────────────────────────────────────────┘   │
|             │                                                                            │
|  ┌──────────▼────────────────────────────────────────────────────────────────────────┐   │
|  │[S1-7] tt_class_working_day_jnt                                                     │   │
|  │ PK: id   UQ: class_id + working_day_id                                            │   │
|  │ FK → tt_working_day, sch_classes, sch_sections                                     │   │
|  │ Class-level override (exam for one class, normal study for another)                │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  ┌────────────────────────────────────────────┐                                          │
|  │[S1-4] tt_teacher_assignment_role            │                                          │
|  │ PK: id   UQ: code                          │                                          │
|  │ PRIMARY, ASSISTANT, CO_TEACHER,             │                                          │
|  │ SUBSTITUTE, TRAINEE                         │                                          │
|  │ workload_factor for weighted calculations   │                                          │
|  └─────────────────────────────────────────┬──┘                                          │
|                                            │                                              │
|  ┌─────────────────────────────────────────│──────────────────────────────────────────┐   │
|  │[S1-9] tt_period_set (MODIFIED v7.7)     │                                          │   │
|  │ PK: id   UQ: code                       │                                          │   │
|  │ FK → tt_shift (NEW v7.7)                │                                          │   │
|  │ from_period_ord, to_period_ord (NEW)    │                                          │   │
|  │ REMOVED: day_start_time, day_end_time   │                                          │   │
|  │ Defines WHICH period range a class uses │                                          │   │
|  │ e.g. STANDARD_8P, TODDLER_6P           │                                          │   │
|  └────┬───────────────────────────────────┘│                                          │   │
|       │                                    │                                              │
|  ┌────▼──────────────────────────────────────────────────────────────────────────────┐   │
|  │[S1-10] tt_period_set_period_jnt (MODIFIED v7.7)                                    │   │
|  │ PK: id   UQ: period_set_id + period_ord, period_set_id + period_config_id         │   │
|  │ FK → tt_period_set, tt_period_config (NEW v7.7), tt_period_type                   │   │
|  │ REMOVED: start_time, end_time, duration_minutes                                   │   │
|  │ Maps which slots from tt_period_config are included in each set                    │   │
|  │ Can override period_type per set (e.g. TEACHING → FREE for some class groups)     │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  ┌──────────────────────────────────────────┐  ┌──────────────────────────────────────┐  │
|  │[S1-11] tt_timetable_type                 │  │[S1-12] tt_class_timetable_type_jnt   │  │
|  │ PK: id   UQ: code                        │  │ PK: id                               │  │
|  │ FK → tt_shift                             │  │ FK → tt_timetable_type, sch_classes, │  │
|  │ STANDARD, UNIT_TEST, HALF_DAY,           │  │      sch_sections, tt_period_set,    │  │
|  │ HALF_YEARLY, FINAL_EXAM                  │  │      sch_academic_term               │  │
|  │ has_exam, has_teaching flags              │  │ Rules per class: period counts,      │  │
|  │ effective date range                      │  │ exam/teaching/free periods           │  │
|  └──────────────────────────────────────────┘  └──────────────────────────────────────┘  │
|                                                                                          │
|  =====================================================================================   │
|  SECTION 2: REQUIREMENT (Building the scheduling demand)                                 │
|  =====================================================================================   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S2-1] tt_slot_requirement                                                          │   │
|  │ PK: id   UQ: timetable_type_id + class_timetable_type_id + class_id + section_id  │   │
|  │ FK → sch_academic_term, tt_timetable_type, tt_class_timetable_type_jnt,           │   │
|  │      sch_classes, sch_sections, sch_rooms, tt_activity                             │   │
|  │ Slot counts per class+section: total, teaching, exam, free                         │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S2-2] tt_class_requirement_groups                                                  │   │
|  │ PK: id   UQ: code, class+section+subject_study_format                             │   │
|  │ FK → sch_class_groups, sch_classes, sch_sections, sch_subjects,                    │   │
|  │      sch_study_formats, sch_subject_types, sch_subject_study_format_jnt,           │   │
|  │      sch_rooms_type, sch_rooms                                                     │   │
|  │ One row per Class+Section+Subject+StudyFormat combination                          │   │
|  │ student_count, eligible_teacher_count                                              │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S2-3] tt_class_requirement_subgroups                                               │   │
|  │ PK: id   UQ: code, class+section+subject_study_format                             │   │
|  │ Similar structure to requirement_groups but for optional subgroups                 │   │
|  │ is_shared_across_sections, is_shared_across_classes                                │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S2-4] tt_requirement_consolidation                                                 │   │
|  │ PK: id   UQ: term + tt_type + group + subgroup                                    │   │
|  │ FK → sch_academic_term, tt_timetable_type, sch_class_groups_jnt,                  │   │
|  │      tt_requirement_subgroups, sch_classes, sch_sections, sch_subjects,            │   │
|  │      sch_study_formats, sch_subject_types, sch_rooms_type, sch_rooms              │   │
|  │ Merged view with EDITABLE scheduling parameters:                                  │   │
|  │   required_weekly_periods, min/max per day, consecutive rules,                    │   │
|  │   preferred_periods_json, avoid_periods_json, spread_evenly, room requirements    │   │
|  │ CHECK: exactly one of group or subgroup is set                                    │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  =====================================================================================   │
|  SECTION 3: CONSTRAINT ENGINE                                                            │
|  =====================================================================================   │
|                                                                                          │
|  ┌──────────────────────────────────────────────────┐                                    │
|  │[S3-1] tt_constraint_category_scope               │                                    │
|  │ PK: id   UQ: type + code                         │                                    │
|  │ ENUM type: CATEGORY or SCOPE                      │                                    │
|  │ Categories: PERIOD, ROOM, TEACHER, CLASS, etc.    │                                    │
|  │ Scopes: GLOBAL, TEACHER, ROOM, ACTIVITY, etc.    │                                    │
|  │ Defined by PRIME, user can only change name       │                                    │
|  └──────────┬───────────────────────────────────────┘                                    │
|             │                                                                            │
|  ┌──────────▼───────────────────────────────────────┐                                    │
|  │[S3-2] tt_constraint_type (Template)              │                                    │
|  │ PK: id   UQ: code                                │                                    │
|  │ FK → tt_constraint_category_scope (x2: category, │                                    │
|  │      scope)                                       │                                    │
|  │ param_schema (JSON schema), default_weight,       │                                    │
|  │ is_hard_constraint, is_system                     │                                    │
|  └──────────┬───────────────────────────────────────┘                                    │
|             │                                                                            │
|  ┌──────────▼───────────────────────────────────────┐                                    │
|  │[S3-3] tt_constraint (Instance)                   │                                    │
|  │ PK: id                                            │                                    │
|  │ FK → tt_constraint_type, tt_constraint_category_  │                                    │
|  │      scope (target_type)                          │                                    │
|  │ params_json, is_hard, weight, applicable_days,    │                                    │
|  │ impact_score, effective date range                │                                    │
|  └──────────┬───────────────────────────────────────┘                                    │
|             │                                                                            │
|  ┌──────────▼──────────────────────┐  ┌──────────────────────────────────┐               │
|  │[S3-4] tt_teacher_unavailable    │  │[S3-5] tt_room_unavailable        │               │
|  │ PK: id                          │  │ PK: id                           │               │
|  │ FK → sch_teachers, tt_constraint│  │ FK → sch_rooms, tt_constraint    │               │
|  │ Day, period, recurring rules    │  │ Day, period, date range          │               │
|  │ is_recurring + frequency        │  │ is_recurring flag                │               │
|  └─────────────────────────────────┘  └──────────────────────────────────┘               │
|                                                                                          │
|  =====================================================================================   │
|  SECTION 4: RESOURCE AVAILABILITY                                                        │
|  =====================================================================================   │
|                                                                                          │
|  ┌──────────────────────────────────────────────────────────────────────────────────┐    │
|  │[S4-1] tt_teacher_availability (Header)                                           │    │
|  │ PK: id   UQ: requirement_consolidation_id + teacher_profile_id                   │    │
|  │ FK → tt_requirement_consolidation, sch_classes, sch_sections,                    │    │
|  │      sch_study_formats, sch_teacher_profile, tt_activity                         │    │
|  │ Skill scores, preference scores, priority overrides, historical feedback         │    │
|  │ GENERATED: available_for_full_timetable_duration, no_of_days_not_available       │    │
|  │ Calculated: min/max_teacher_availability_score                                   │    │
|  └────┬─────────────────────────────────────────────────────────────────────────────┘    │
|       │                                                                                  │
|  ┌────▼─────────────────────────────────────────────────────────────────────────────┐    │
|  │[S4-2] tt_teacher_availability_detail (Grid: day x period)                         │    │
|  │ PK: id   UQ: teacher_profile_id + day_number + period_number                     │    │
|  │ FK → tt_teacher_availability, sch_teacher_profile, sch_classes,                   │    │
|  │      sch_sections, sch_study_formats, tt_activity                                │    │
|  │ Status per slot: Available, Unavailable, Assigned, Free Period                    │    │
|  └───────────────────────────────────────────────────────────────────────────────────┘    │
|                                                                                          │
|  ┌──────────────────────────────────────────────────────────────────────────────────┐    │
|  │[S4-3] tt_room_availability (Header)                                              │    │
|  │ PK: id                                                                            │    │
|  │ FK → sch_rooms, sch_rooms_type, sch_classes, sch_sections, tt_activity            │    │
|  │ can_be_assigned_for: lecture, practical, exam, activity, sports                   │    │
|  │ is_class_house_room flag with CHECK constraint                                    │    │
|  └────┬─────────────────────────────────────────────────────────────────────────────┘    │
|       │                                                                                  │
|  ┌────▼─────────────────────────────────────────────────────────────────────────────┐    │
|  │[S4-4] tt_room_availability_detail (Grid: day x period)                            │    │
|  │ PK: id                                                                            │    │
|  │ FK → tt_room_availability, sch_rooms, sch_rooms_type, sch_classes,                │    │
|  │      sch_sections, sch_study_formats, tt_activity                                │    │
|  │ Status per slot: Available, Unavailable, Assigned                                 │    │
|  └───────────────────────────────────────────────────────────────────────────────────┘    │
|                                                                                          │
|  =====================================================================================   │
|  SECTION 5: PREPARATION (Pre-generation data assembly)                                   │
|  =====================================================================================   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S5-1] tt_priority_config                                                           │   │
|  │ PK: id   UQ: priority_type + priority_name                                        │   │
|  │ FK → tt_requirement_consolidation                                                  │   │
|  │ Calculated scores: teacher_scarcity_index, weekly_load_ratio,                     │   │
|  │   average_teacher_availability_ratio, rigidity_score, resource_scarcity,          │   │
|  │   subject_difficulty_index                                                         │   │
|  └───────────────────────────────────────────────────────────────────────────────────┘   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S5-2] tt_activity (The core schedulable unit)                                      │   │
|  │ PK: id   UQ: code                                                                 │   │
|  │ FK → sch_academic_term, tt_timetable_type, sch_class_groups_jnt,                  │   │
|  │      sch_classes, sch_sections, sch_subjects, sch_study_formats,                   │   │
|  │      sch_subject_types, sch_rooms_type, sch_rooms, sys_users                      │   │
|  │ GENERATED: total_periods = duration_periods * weekly_periods                       │   │
|  │ Scheduling params, room requirements, difficulty scores                            │   │
|  │ Status: DRAFT → ACTIVE → LOCKED → ARCHIVED                                       │   │
|  └────┬──────────────────────────────────────────────────────────────────────────────┘   │
|       │                                                                                  │
|       ├──────────────────────────────────────────────┐                                   │
|       │                                              │                                   │
|  ┌────▼──────────────────────────────┐  ┌────────────▼───────────────────────────────┐   │
|  │[S5-3] tt_sub_activity             │  │[S5-5] tt_activity_teacher                  │   │
|  │ PK: id                            │  │ PK: id   UQ: activity_id + teacher_id      │   │
|  │ FK → tt_activity (parent),        │  │ FK → tt_activity, sch_teachers,            │   │
|  │      tt_class_requirement_        │  │      tt_teacher_assignment_role     ────────┤───┤
|  │      subgroups, sch_classes,      │  │ is_required, ordinal                        │   │
|  │      sch_sections                 │  └────────────────────────────────────────────┘   │
|  │ For multi-period activities       │                                                   │
|  │ same_day_as_parent,               │  ┌────────────────────────────────────────────┐   │
|  │ consecutive_with_previous         │  │[S5-4] tt_activity_priority                 │   │
|  └───────────────────────────────────┘  │ PK: id   UQ: activity_id                  │   │
|                                         │ FK → tt_activity                            │   │
|                                         │ priority_score (0-100), reason              │   │
|                                         └────────────────────────────────────────────┘   │
|                                                                                          │
|  =====================================================================================   │
|  SECTION 6: GENERATION & STORAGE                                                         │
|  =====================================================================================   │
|                                                                                          │
|  ┌───────────────────────────────────────────────────────────────────────────────────┐   │
|  │[S6-1] tt_timetable (Container / Version)                                           │   │
|  │ PK: id   UQ: code                                                                 │   │
|  │ FK → sch_org_academic_sessions_jnt, sch_academic_term, tt_timetable_type,         │   │
|  │      tt_period_set, tt_timetable (parent_timetable_id), tt_generation_strategy, ──┤───┘
|  │      sys_users (published_by, created_by)                                          │
|  │ Lifecycle: DRAFT → GENERATING → GENERATED → PUBLISHED → ARCHIVED                 │
|  │ Scores: quality_score, teacher_satisfaction_score, room_utilization_score          │
|  │ version, parent_timetable_id for lineage                                          │
|  └────┬───────────────────────────┬─────────────────────┬────────────────────────────┘
|       │                           │                     │
|  ┌────▼───────────────────────┐   │  ┌──────────────────▼──────────────────────────┐
|  │[S6-4] tt_generation_run    │   │  │[S6-2] tt_conflict_detection                 │
|  │ PK: id                     │   │  │ PK: id                                      │
|  │ UQ: timetable_id + run_no  │   │  │ FK → tt_timetable                           │
|  │ FK → tt_timetable,         │   │  │ REAL_TIME, BATCH, VALIDATION, GENERATION    │
|  │      tt_generation_strategy│   │  │ hard/soft conflict counts                    │
|  │      sys_users (triggered) │   │  │ conflicts_json, resolution_suggestions_json │
|  │ Status: QUEUED → RUNNING → │   │  └─────────────────────────────────────────────┘
|  │   COMPLETED / FAILED /     │   │
|  │   CANCELLED                │   │  ┌──────────────────────────────────────────────┐
|  │ activities_total/placed/   │   │  │[S6-3] tt_resource_booking                    │
|  │   failed, violations count │   │  │ PK: id                                       │
|  └────────────────────────────┘   │  │ Resource: ROOM, LAB, TEACHER, EQUIPMENT,     │
|                                   │  │   SPORTS, SPECIAL                             │
|  ┌────────────────────────────┐   │  │ Status: BOOKED → IN_USE → COMPLETED/CANCELLED│
|  │[S6-5] tt_constraint_       │   │  └──────────────────────────────────────────────┘
|  │       violation             │   │
|  │ PK: id                     │   │
|  │ FK → tt_timetable,         │   │
|  │      tt_constraint         │   │
|  │ HARD / SOFT type            │   │
|  │ violation_count, details    │   │
|  └─────────────────────────────┘   │
|                                    │
|  ┌─────────────────────────────────▼─────────────────────────────────────────────────┐
|  │[S6-6] tt_timetable_cell (The actual grid)                                         │
|  │ PK: id   UQ: timetable_id + day_of_week + period_ord + class_group + subgroup    │
|  │ FK → tt_timetable, tt_generation_run, sch_class_groups_jnt,                       │
|  │      tt_requirement_subgroups, tt_activity, tt_sub_activity,                      │
|  │      sch_rooms, sys_users (locked_by)                                             │
|  │ Source: AUTO, MANUAL, SWAP, LOCK                                                  │
|  │ is_locked, has_conflict, conflict_details_json                                    │
|  │ CHECK: exactly one of class_group_id or class_subgroup_id                         │
|  └────┬──────────────────────────────────────────────────────────────────────────────┘
|       │
|  ┌────▼──────────────────────────────────────────────────────────────────────────────┐
|  │[S6-7] tt_timetable_cell_teacher                                                    │
|  │ PK: id   UQ: cell_id + teacher_id                                                 │
|  │ FK → tt_timetable_cell, sch_teachers, tt_teacher_assignment_role                  │
|  │ is_substitute flag                                                                 │
|  │ Multiple teachers per cell (team teaching, co-teaching)                            │
|  └───────────────────────────────────────────────────────────────────────────────────┘
|
|  =====================================================================================
|  SECTION 8: REPORTS
|  =====================================================================================
|
|  ┌───────────────────────────────────────────────────────────────────────────────────┐
|  │[S8-1] tt_teacher_workload                                                          │
|  │ PK: id   UQ: teacher_id + academic_session_id + timetable_id                      │
|  │ FK → sch_teachers, sch_org_academic_sessions_jnt, tt_timetable                    │
|  │ weekly_periods_assigned/max/min, utilization_percent,                              │
|  │ gap_periods_total, consecutive_max                                                 │
|  │ daily_distribution_json, subjects_assigned_json, classes_assigned_json             │
|  └───────────────────────────────────────────────────────────────────────────────────┘
|
|  =====================================================================================
|  SECTION 9: AUDIT
|  =====================================================================================
|
|  ┌───────────────────────────────────────────────────────────────────────────────────┐
|  │[S9-1] tt_change_log                                                                │
|  │ PK: id                                                                             │
|  │ FK → tt_timetable, tt_timetable_cell, sys_users (changed_by)                      │
|  │ change_type: CREATE, UPDATE, DELETE, LOCK, UNLOCK, SWAP, SUBSTITUTE               │
|  │ old_values_json, new_values_json, reason                                           │
|  └───────────────────────────────────────────────────────────────────────────────────┘
|
|  =====================================================================================
|  SECTION 10: SUBSTITUTION
|  =====================================================================================
|
|  ┌───────────────────────────────────┐  ┌───────────────────────────────────────────┐
|  │[S10-1] tt_teacher_absence         │  │[S10-2] tt_substitution_log                │
|  │ PK: id                            │  │ PK: id                                    │
|  │ UQ: teacher_id + absence_date     │  │ FK → tt_teacher_absence,                 │
|  │ FK → sch_teachers, sys_users      │  │      tt_timetable_cell, sch_teachers (x2: │
|  │ LEAVE, SICK, TRAINING,            │  │      absent, substitute), sys_users       │
|  │ OFFICIAL_DUTY, OTHER              │  │ assignment_method: AUTO, MANUAL, SWAP     │
|  │ Status: PENDING → APPROVED /      │  │ Status: ASSIGNED → COMPLETED / CANCELLED  │
|  │   REJECTED / CANCELLED            │  │ notified_at, accepted_at, completed_at    │
|  │ substitution_required/completed   │  │ feedback                                  │
|  └───────────────────────────────────┘  └───────────────────────────────────────────┘
```

### Simplified Relationship Summary

```
|  sch_academic_term ──────────────────────┐
|  tt_config (settings) ───────────────────┤
|  tt_generation_strategy ─────────────────┤
|                                          │
|  tt_shift ──┬─► tt_period_config ────────┤
|             └─► tt_period_set ──► tt_period_set_period_jnt
|                                          │
|  tt_day_type ──► tt_working_day ──► tt_class_working_day_jnt
|                                          │
|  tt_timetable_type ──► tt_class_timetable_type_jnt
|                                          │
|                     ┌────────────────────┘
|                     ▼
|  tt_slot_requirement
|  tt_class_requirement_groups ────┐
|  tt_class_requirement_subgroups ─┤
|                                  ▼
|  tt_requirement_consolidation ────► tt_priority_config
|                                  │
|                                  ▼
|  tt_teacher_availability ──► tt_teacher_availability_detail
|  tt_room_availability ───► tt_room_availability_detail
|                                  │
|                                  ▼
|  tt_activity ──┬─► tt_sub_activity
|                ├─► tt_activity_priority
|                └─► tt_activity_teacher
|                                  │
|                                  ▼
|  tt_timetable ──┬─► tt_generation_run
|                 ├─► tt_conflict_detection
|                 ├─► tt_resource_booking
|                 ├─► tt_constraint_violation
|                 └─► tt_timetable_cell ──► tt_timetable_cell_teacher
|                                  │
|                                  ▼
|  tt_teacher_workload    tt_change_log
|  tt_teacher_absence ──► tt_substitution_log
|
|  CONSTRAINT ENGINE (orthogonal):
|  tt_constraint_category_scope ──► tt_constraint_type ──► tt_constraint
|                                                          ├─► tt_teacher_unavailable
|                                                          └─► tt_room_unavailable
```

---

## 2. Purpose of Each Table (Why Each Table is Required)

### Section 0: Configuration Tables (3 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S0-1 | **sch_academic_term** | Schools divide the academic year into terms/quarters (Summer, Winter, Q1-Q4). Timetables are generated per term because teaching requirements, exam schedules, and working days change between terms. Without this, the system could not scope timetable generation to a specific time period. Shared with School_Setup and Lesson Planning modules. |
| S0-2 | **tt_config** | Central key-value configuration store for the timetable module. Stores settings like total periods per day, school open days per week, break counts, min/max student counts for subgroups, and teacher allocation limits. These are edit-only (no add/delete) because the application code references specific keys. Values are typed (STRING, NUMBER, BOOLEAN, etc.) for runtime validation. |
| S0-3 | **tt_generation_strategy** | Timetable generation is an NP-hard problem. Different algorithms work better for different school sizes and constraint profiles. This table stores algorithm configurations (RECURSIVE, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID) with their tuning parameters (recursion depth, population size, cooling rate, timeout). Allows the school to pick and tune the best strategy without code changes. |

### Section 1: Master Tables (12 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S1-1 | **tt_shift** | Schools may operate in multiple shifts (Morning 7:30-14:45, Afternoon 12:00-17:00). Shifts define when different groups of students attend. Period timings differ by shift. Without this, a school running morning and afternoon batches would have no way to separate their timing grids. |
| S1-2 | **tt_day_type** | Not all school days are the same. Some are STUDY days, some are EXAM days, some are PTM (Parent-Teacher Meeting) days, some are SPORTS_DAY. Day types carry behavioral flags: `is_working_day` (is school open?) and `reduced_periods` (fewer periods than normal?). The generation engine needs this to know which days are schedulable and how many periods are available. |
| S1-3 | **tt_period_type** | A period is not just "a time slot." It can be a TEACHING period, a BREAK, LUNCH, ASSEMBLY, EXAM slot, RECESS, or FREE period. Each type carries behavioral flags: `is_schedulable` (can an activity be placed here?), `counts_as_teaching` (does it count toward teacher workload?), `counts_as_workload`, `is_break`, `is_free_period`. The algorithm uses these flags to decide where activities can be placed. |
| S1-4 | **tt_teacher_assignment_role** | A cell in the timetable can have multiple teachers. The PRIMARY teacher leads the class. An ASSISTANT helps. A CO_TEACHER shares equal responsibility. A SUBSTITUTE replaces an absent teacher. A TRAINEE observes. Each role has a `workload_factor` (e.g., 1.00 for primary, 0.50 for assistant) that feeds into workload calculations. |
| S1-5 | **tt_school_days** | Defines the 7 days of the week with `is_school_day` flag. Some schools operate Mon-Fri (5 days), others Mon-Sat (6 days). This table is the foundation for building the weekly timetable grid. The `day_of_week` (1-7) is used as the column axis of the timetable. |
| S1-6 | **tt_working_day** | The school calendar. Each row is a specific date in the academic session with its type(s). A single date can have up to 4 day types simultaneously (e.g., day_type1=EXAM + day_type2=STUDY for a day where some classes have exams while others study). This is the authoritative source for "is school open on date X and what kind of day is it?" |
| S1-7 | **tt_class_working_day_jnt** | Class-level override of the school calendar. On April 15, Class 10 may have an exam (is_exam_day=1) while Class 5 has a normal study day (is_study_day=1). Without this table, all classes would be forced to have the same day type, which does not match reality. |
| S1-8 | **tt_period_config** | **NEW in v7.7.** The school's single fixed daily timing grid per shift. Defines that Slot 1 is Assembly 07:30-07:45, Slot 2 is Period 1 07:45-08:30, Slot 4 is Short Break 09:15-09:30, and so on. This is the centralized "bell schedule." Before v7.7, each period set stored its own timings, allowing inconsistencies. Now all classes share the same timing grid; only the range of periods they attend differs. |
| S1-9 | **tt_period_set** | **MODIFIED in v7.7.** A period set defines WHICH range of the timing grid a class group uses. Lower classes (1st-2nd) might use slots 3-11 (skipping early assembly and late periods), while higher classes use all 12 slots. The `from_period_ord` and `to_period_ord` reference `tt_period_config.slot_ord`. Also stores summary counts: total_periods, teaching_periods, exam_periods, free_periods, break counts. |
| S1-10 | **tt_period_set_period_jnt** | **MODIFIED in v7.7.** Maps which individual timeslots from `tt_period_config` are included in each period set. Allows type override -- a TEACHING slot in the master grid can be marked as FREE for a specific class group's period set. Timing is inherited from `tt_period_config`, not stored locally. |
| S1-11 | **tt_timetable_type** | Schools create different timetables for different purposes. A "STANDARD" timetable is for regular days. A "UNIT_TEST-1" timetable has exam periods. A "HALF_DAY" timetable has reduced periods. Each type has an effective date range and flags for has_exam, has_teaching. This lets the school maintain multiple active timetable configurations. |
| S1-12 | **tt_class_timetable_type_jnt** | Assigns a timetable type and period set to each class(+section). Class 10-A uses the STANDARD timetable type with STANDARD_8P period set. Class LKG-A uses STANDARD with TODDLER_6P. Also stores per-class overrides: weekly exam/teaching/free period counts. The `applies_to_all_sections` flag with CHECK constraint ensures data consistency when a rule is class-wide vs section-specific. |

### Section 2: Requirement Tables (4 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S2-1 | **tt_slot_requirement** | Computed slot counts per class+section for a given timetable type. Answers: "How many total/teaching/exam/free slots does Class 5-A have per week?" This is derived from `tt_class_timetable_type_jnt` and `tt_timetable_type`. It is a calculation table (no audit fields) that feeds the generation engine. |
| S2-2 | **tt_class_requirement_groups** | The first layer of the three-layer requirement model. One row per Class+Section+Subject+StudyFormat combination. E.g., "Class 10-A, Science, Lecture" is one group. Copies structural data from `sch_class_groups_jnt` and enriches it with `student_count` and `eligible_teacher_count`. This is the demand side: what needs to be scheduled. |
| S2-3 | **tt_class_requirement_subgroups** | The second layer. When a subject needs to be split into subgroups (e.g., Science Lab requires splitting 40 students into 2 batches of 20), this table defines those subgroups. The `is_shared_across_sections` flag enables resource sharing (one lab session serving students from both 10-A and 10-B). Without subgroups, the system could not handle practical/lab splitting or optional subject grouping. |
| S2-4 | **tt_requirement_consolidation** | The third and final layer. Merges groups and subgroups into a single consolidated view with **editable scheduling parameters**. The admin can set `required_weekly_periods`, `min/max_periods_per_day`, `allow_consecutive_periods`, `preferred_periods_json`, `avoid_periods_json`, `spread_evenly`, and room requirements. This is the last human touchpoint before the data flows into activity creation. A CHECK constraint ensures each row maps to exactly one group OR one subgroup (not both). |

### Section 3: Constraint Engine (5 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S3-1 | **tt_constraint_category_scope** | Shared lookup for both constraint categories and scopes using a `type` ENUM (CATEGORY or SCOPE). Categories define WHAT the constraint is about (PERIOD, ROOM, TEACHER, CLASS, SUBJECT, etc.). Scopes define WHERE it applies (GLOBAL, per-TEACHER, per-ROOM, per-ACTIVITY, per-CLASS, etc.). Defined by PRIME (system), the user can only rename them. This separation enables a generic, extensible constraint system. |
| S3-2 | **tt_constraint_type** | The constraint template library. E.g., "TEACHER_NOT_AVAILABLE", "MIN_DAYS_BETWEEN", "SAME_STARTING_TIME". Each type has a `param_schema` (JSON Schema) that defines what parameters instances must provide. `default_weight`, `is_hard_constraint` give defaults. `is_system` distinguishes built-in constraints from school-defined ones. New constraint types can be added without code changes. |
| S3-3 | **tt_constraint** | A concrete constraint instance. E.g., "Teacher Sharma is unavailable on Wednesdays Period 3" or "Class 12 Physics Lab must be in Period 5-6." References a `constraint_type_id` for the template, a `target_type` + `target_id` for who/what it applies to, and `params_json` for the specific parameters. `is_hard` determines if the constraint is inviolable or just a preference (with weight). |
| S3-4 | **tt_teacher_unavailable** | Specialized constraint for teacher unavailability. One row per teacher per unavailable day+period combination. Supports recurring patterns (Daily, Weekly, Monthly, Yearly) and date ranges. Linked back to `tt_constraint` for unified constraint processing. The generation engine checks this before assigning a teacher to any slot. |
| S3-5 | **tt_room_unavailable** | Same concept as teacher unavailability but for rooms. A room might be unavailable on Tuesdays (maintenance), or for specific periods (used for exams). Linked to `tt_constraint` for unified processing. |

### Section 4: Resource Availability Tables (4 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S4-1 | **tt_teacher_availability** | Master availability record per teacher per requirement consolidation item. Aggregates data from `sch_teacher_profile` (skills, shift preference, workload limits) and `sch_teacher_capabilities` (proficiency, competency level, scarcity index). Includes calculated fields: `available_for_full_timetable_duration` (GENERATED), `no_of_days_not_available` (GENERATED). The priority system uses `preference_score`, `override_priority`, `historical_success_ratio`, and `last_allocation_score` to rank teachers for assignment. |
| S4-2 | **tt_teacher_availability_detail** | Day-by-period-by-teacher grid. Shows whether a teacher is Available, Unavailable, Assigned, or in a Free Period for each slot. When a teacher is Assigned, the `assigned_class_id`, `assigned_section_id`, and `assigned_subject_study_format_id` fields show what they are teaching. This is the real-time snapshot that the generation engine consults. |
| S4-3 | **tt_room_availability** | Room-level availability status. Each room has one header row with overall status (Available, Unavailable, Partially Available, Assigned), usage flags (can_be_assigned_for_lecture, practical, exam, activity, sports), capacity, and whether it is a class house room. The `is_class_house_room` flag with CHECK constraint ensures home rooms are always assigned to their class. |
| S4-4 | **tt_room_availability_detail** | Day-by-period-by-room grid. Shows which room is Available, Unavailable, or Assigned for each slot, and if assigned, to which class+section+subject. Mirrors `tt_teacher_availability_detail` but for rooms. |

### Section 5: Preparation Tables (5 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S5-1 | **tt_priority_config** | Calculates scheduling priority scores for each requirement. Uses formulas for: `teacher_scarcity_index` (fewer qualified teachers = higher priority), `weekly_load_ratio` (more periods needed = higher priority), `rigidity_score` (fewer valid slots = must be placed first), `resource_scarcity` (one lab for 8 sections = must be placed early), `subject_difficulty_index` (Physics/Chemistry before Art). These scores determine the order in which the algorithm places activities. |
| S5-2 | **tt_activity** | The core schedulable unit. One activity = one Class+Section+Subject+StudyFormat that needs to be placed on the timetable. Contains all scheduling parameters (weekly periods, min/max per day, consecutive rules, preferred/avoid slots), room requirements, difficulty scores, and teacher availability scores. `duration_periods` handles multi-period activities (Labs = 2 periods). The GENERATED column `total_periods = duration_periods * weekly_periods` gives the total slots needed. |
| S5-3 | **tt_sub_activity** | For activities that span multiple periods (e.g., a 2-period lab). Each sub-activity represents one period of the multi-period block. `same_day_as_parent` and `consecutive_with_previous` flags enforce that lab periods stay together. Without this, the engine could not model "Lab must be 2 consecutive periods." |
| S5-4 | **tt_activity_priority** | Stores the final calculated priority score for each activity. Separating priority from the activity table allows recalculation without touching activity records. The `priority_reason` field provides human-readable explanation for audit. |
| S5-5 | **tt_activity_teacher** | Maps which teachers can teach which activities, with their assignment role (PRIMARY, ASSISTANT, etc.). `is_required` distinguishes mandatory teachers from optional ones. `ordinal` sets preference order. This is the teacher-to-activity assignment that the generation engine uses to populate `tt_timetable_cell_teacher`. |

### Section 6: Generation & Storage Tables (7 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S6-1 | **tt_timetable** | The timetable container/version. Each row is a complete timetable with lifecycle status (DRAFT, GENERATING, GENERATED, PUBLISHED, ARCHIVED), quality scores, and metadata. `parent_timetable_id` creates a version chain so the school can track how timetable V2 evolved from V1. `generation_method` (MANUAL, SEMI_AUTO, FULL_AUTO) records how it was created. Once PUBLISHED, the timetable is visible to all users. |
| S6-2 | **tt_conflict_detection** | Logs every conflict detection event: during generation (GENERATION), during manual edits (REAL_TIME), periodic checks (BATCH), or before publishing (VALIDATION). Stores hard vs soft conflict counts and resolution suggestions in JSON. Critical for the "real-time conflict detection capabilities" requirement. |
| S6-3 | **tt_resource_booking** | Tracks resource utilization across the school. Resources include ROOM, LAB, TEACHER, EQUIPMENT, SPORTS, SPECIAL. Each booking has a status lifecycle (BOOKED, IN_USE, COMPLETED, CANCELLED). This is the source-of-truth for "is Room X available at Time Y?" Used by the generation engine and also for ad-hoc bookings (events, exams, maintenance). |
| S6-4 | **tt_generation_run** | Audit trail of each generation attempt. Tracks run_number, start/finish times, status (QUEUED, RUNNING, COMPLETED, FAILED, CANCELLED), algorithm parameters, and results (activities_total/placed/failed, hard/soft violations, soft_score). When generation fails, `error_message` captures the reason. Enables comparison between runs. |
| S6-5 | **tt_constraint_violation** | Records which constraints were violated in a specific timetable version. One row per timetable+constraint combination with violation count and details JSON. Separated from the timetable table to allow detailed constraint-by-constraint analysis. |
| S6-6 | **tt_timetable_cell** | The actual timetable grid. Each row is one cell: a specific day + period + class_group/subgroup in a timetable version. Contains the assigned activity, sub-activity, room, and source (AUTO/MANUAL/SWAP/LOCK). `is_locked` prevents the algorithm from moving a manually-placed cell. `has_conflict` flags cells that violate constraints. This is the highest-volume table in the module. |
| S6-7 | **tt_timetable_cell_teacher** | Which teachers are assigned to each timetable cell. Separated from `tt_timetable_cell` because a cell can have multiple teachers (team teaching, co-teaching). Each row records the teacher, their assignment role, and whether they are a substitute. |

### Section 8: Reports (1 Table)

| # | Table | Why It Exists |
|---|-------|---------------|
| S8-1 | **tt_teacher_workload** | Pre-computed analytics per teacher per timetable. Stores `weekly_periods_assigned` vs min/max allowed, `utilization_percent`, `gap_periods_total` (idle periods between classes), and `consecutive_max` (longest teaching streak without break). JSON fields store daily distribution and subject/class assignments. Used for the Teacher Workload Analysis report. Recalculated whenever the timetable changes. |

### Section 9: Audit (1 Table)

| # | Table | Why It Exists |
|---|-------|---------------|
| S9-1 | **tt_change_log** | Immutable audit trail of every timetable modification. Records CREATE, UPDATE, DELETE, LOCK, UNLOCK, SWAP, and SUBSTITUTE actions with `old_values_json` and `new_values_json` for before/after comparison. Required for accountability: if a parent complains that their child's Physics class was moved, this log shows who moved it, when, and why. |

### Section 10: Substitution Tables (2 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| S10-1 | **tt_teacher_absence** | Records teacher absences with type (LEAVE, SICK, TRAINING, OFFICIAL_DUTY, OTHER), approval workflow (PENDING, APPROVED, REJECTED, CANCELLED), and substitution tracking flags. When a teacher is absent, the school needs to know which periods need substitutes. The `substitution_required` and `substitution_completed` flags drive the substitution workflow. |
| S10-2 | **tt_substitution_log** | Tracks every substitution event: which cell was affected, who was absent, who substituted, how they were assigned (AUTO, MANUAL, SWAP), and the lifecycle (ASSIGNED, COMPLETED, CANCELLED). Includes notification tracking (`notified_at`, `accepted_at`) and `feedback` for quality improvement. |

### Section 11: Reference Tables (21 Tables from Other Modules)

| # | Table | Module | Why TT References It |
|---|-------|--------|---------------------|
| R1 | **sch_organizations** | School Setup | School identity and metadata. Single-record table for the tenant. |
| R2 | **sch_org_academic_sessions_jnt** | School Setup | Academic session scoping. Timetables are created within a session. |
| R3 | **sch_board_organization_jnt** | School Setup | Board association (CBSE, ICSE, State). Influences timetable rules. |
| R4 | **sch_classes** | School Setup | Class list (1st, 2nd, ..., 12th). The Y-axis of the timetable. |
| R5 | **sch_sections** | School Setup | Section list (A, B, C, D). Combined with class to form the scheduling unit. |
| R6 | **sch_class_section_jnt** | School Setup | Class+Section combinations with capacity, actual student count, class teacher assignment, and home room assignment. Core scheduling unit. |
| R7 | **sch_subject_types** | School Setup | Subject classification (MAJOR, MINOR, OPTIONAL, ACTIVITY, SPORTS). Used for constraint rules like "Major subjects should be in morning periods." |
| R8 | **sch_study_formats** | School Setup | Teaching format (LECTURE, LAB, PRACTICAL, TUTORIAL, SEMINAR, WORKSHOP, GROUP_DISCUSSION). Determines room requirements and period duration. |
| R9 | **sch_subjects** | School Setup | Subject list (Science, Math, English, etc.). The "what" being taught. |
| R10 | **sch_subject_study_format_jnt** | School Setup | Subject+StudyFormat combinations (Science Lecture, Science Lab). Carries room requirements: `compulsory_specific_room_type`, `required_room_type_id`. |
| R11 | **sch_class_groups_jnt** | School Setup | The fundamental demand unit: Class+Section+Subject+StudyFormat+SubjectType. E.g., "10th-A Science Lecture Major." Carries scheduling parameters (required_weekly_periods, priority_score, room requirements). |
| R12 | **sch_subject_groups** | School Setup | Stream/subject groupings for student enrollment (e.g., "7th Science", "7th Commerce"). Used to determine student counts per subject combination. |
| R13 | **sch_subject_group_subject_jnt** | School Setup | Maps which class_groups belong to which subject_groups. Used to count students enrolled in each subject combination. |
| R14 | **sch_buildings** | Infrastructure | Building list (Junior Wing, Senior Wing). Rooms belong to buildings. |
| R15 | **sch_rooms_type** | Infrastructure | Room categories (Science Lab, Computer Lab, House Room, Cricket Ground). Carries `room_count_in_category` for scarcity calculations. |
| R16 | **sch_rooms** | Infrastructure | Individual rooms with building, type, capacity, and capability flags (can_host_lecture, can_host_practical, can_host_exam, can_host_activity, can_host_sports). The assignable resource. |
| R17 | **sch_employees** | HR | Employee records with qualifications, experience, and certifications. Base table for all staff. |
| R18 | **sch_teacher_profile** | HR | Teaching-specific profile: employment nature, scheduling constraints (max/min periods weekly), lab certification, multi-class capability, substitution availability, performance rating. One record per teacher. |
| R19 | **sch_teacher_capabilities** | HR | Per-teacher-per-class-per-subject proficiency: what can this teacher teach, how well, and at what priority? Carries `proficiency_percentage`, `competancy_level`, `scarcity_index`, `allocation_strictness`. The core input for teacher assignment intelligence. |
| R20 | **std_students** | Student | Student records. Used for student counts in scheduling calculations. |
| R21 | **std_student_academic_sessions** | Student | Student-to-class-section-to-subject-group mapping per session. Used to count how many students are in each subject combination, which determines subgroup sizing. |

---

## 3. Field Details per Table

### S0-1: sch_academic_term

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | SMALLINT UNSIGNED PK | Auto | Primary key |
| `academic_session_id` | INT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id`. Scopes to session |
| `academic_year_start_date` | DATE | Yes | Academic year start (e.g., 2024-01-01) |
| `academic_year_end_date` | DATE | Yes | Academic year end (e.g., 2024-12-31) |
| `total_terms_in_academic_session` | TINYINT UNSIGNED | Yes | Number of terms in the session (1, 2, 3, or 4) |
| `term_ordinal` | TINYINT UNSIGNED | Yes | Term sequence order (1, 2, 3, 4) |
| `term_code` | VARCHAR(20) | Yes | Machine-readable code: SUMMER, WINTER, Q1-Q4 |
| `term_name` | VARCHAR(100) | Yes | Display name: Summer Term, Winter Term |
| `term_start_date` | DATE | Yes | When this term begins |
| `term_end_date` | DATE | Yes | When this term ends |
| `term_total_teaching_days` | TINYINT UNSIGNED | No (default 5) | Teaching days in term (excluding exam days) |
| `term_total_exam_days` | TINYINT UNSIGNED | No (default 2) | Exam days in term (excluding teaching days) |
| `term_week_start_day` | TINYINT UNSIGNED | Yes | Which day of week the term starts (1-6) |
| `term_total_periods_per_day` | TINYINT UNSIGNED | Yes | Total periods per day (includes teaching + breaks + lunch) |
| `term_total_teaching_periods_per_day` | TINYINT UNSIGNED | Yes | Teaching-only periods per day |
| `term_min_resting_periods_per_day` | TINYINT UNSIGNED | Yes | Minimum break periods between classes |
| `term_max_resting_periods_per_day` | TINYINT UNSIGNED | Yes | Maximum break periods between classes |
| `term_travel_minutes_between_classes` | TINYINT UNSIGNED | Yes | Travel time in minutes between rooms (e.g., 5, 10, 15) |
| `is_current` | BOOLEAN | No (default FALSE) | Whether this is the current term |
| `current_flag` | TINYINT(1) | GENERATED STORED | `CASE WHEN is_current=1 THEN 1 ELSE NULL END`. Unique constraint ensures only one current term |
| `settings_json` | JSON | No | Additional term-specific settings |
| `is_active` | BOOLEAN | No (default TRUE) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

**Unique constraints:** `current_flag` (only one current term), `academic_session_id + term_code`.

### S0-2: tt_config

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | SMALLINT UNSIGNED PK | Auto | Primary key |
| `ordinal` | INT UNSIGNED | Yes (default 1) | Display order in settings screen |
| `key` | VARCHAR(150) UQ | Yes | Machine-readable key. **Cannot be edited by user.** e.g., `total_number_of_period_per_day` |
| `key_name` | VARCHAR(150) | Yes | Human-readable label. Can be edited. e.g., "Total Number of Period per Day" |
| `value` | VARCHAR(512) | Yes | Configuration value. Can be edited |
| `value_type` | ENUM | Yes | Data type: STRING, NUMBER, BOOLEAN, DATE, TIME, DATETIME, JSON |
| `description` | VARCHAR(255) | Yes | Explanation of what this setting controls |
| `additional_info` | JSON | No | Extra metadata about the setting |
| `tenant_can_modify` | TINYINT(1) | Yes (default 0) | Whether the school admin can change this value |
| `mandatory` | TINYINT(1) | Yes (default 1) | Whether this setting must have a value |
| `used_by_app` | TINYINT(1) | Yes (default 1) | Whether the application code references this key |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `deleted_at` | TIMESTAMP | No | Soft delete |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

**Unique constraints:** `ordinal`, `key`.
**Business rule:** Only edit functionality. No add/delete allowed. `key` field is not displayed on edit screen.

### S0-3: tt_generation_strategy

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | SMALLINT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(20) UQ | Yes | Machine-readable code |
| `name` | VARCHAR(100) | Yes | Display name |
| `description` | VARCHAR(255) | No | Explains the algorithm |
| `algorithm_type` | ENUM | No (default RECURSIVE) | RECURSIVE, GENETIC, SIMULATED_ANNEALING, TABU_SEARCH, HYBRID |
| `max_recursive_depth` | INT UNSIGNED | No (default 14) | For RECURSIVE algorithm: how deep to search |
| `max_placement_attempts` | INT UNSIGNED | No (default 2000) | For RECURSIVE: max placement tries |
| `tabu_size` | INT UNSIGNED | No (default 100) | For TABU_SEARCH: memory list size |
| `cooling_rate` | DECIMAL(5,2) | No (default 0.95) | For SIMULATED_ANNEALING: temperature reduction rate |
| `population_size` | INT UNSIGNED | No (default 50) | For GENETIC: number of candidate solutions |
| `generations` | INT UNSIGNED | No (default 100) | For GENETIC: number of evolution iterations |
| `activity_sorting_method` | ENUM | No (default LESS_TEACHER_FIRST) | LESS_TEACHER_FIRST, DIFFICULTY_FIRST, CONSTRAINT_COUNT, DURATION_FIRST, RANDOM |
| `timeout_seconds` | INT UNSIGNED | No (default 300) | Maximum generation time (5 minutes default) |
| `parameters_json` | JSON | No | Additional algorithm-specific parameters |
| `is_default` | TINYINT(1) | No (default 0) | Whether this is the default strategy |
| `is_active` | TINYINT(1) | No (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

### S1-1: tt_shift

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | TINYINT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(20) UQ | Yes | MORNING, AFTERNOON, EVENING |
| `name` | VARCHAR(100) UQ | Yes | Display name |
| `description` | VARCHAR(255) | No | Details |
| `default_start_time` | TIME | No | Default shift start (e.g., 07:30) |
| `default_end_time` | TIME | No | Default shift end (e.g., 14:45) |
| `ordinal` | TINYINT UNSIGNED | No (default 1) | Display order |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraints:** `ordinal`, `code`, `name`.

### S1-2: tt_day_type

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | TINYINT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(20) UQ | Yes | STUDY, HOLIDAY, EXAM, SPECIAL, PTM_DAY, SPORTS_DAY, ANNUAL_DAY |
| `name` | VARCHAR(100) UQ | Yes | Display name |
| `description` | VARCHAR(255) | No | Details |
| `is_working_day` | TINYINT(1) | Yes (default 1) | 1=school open, 0=school closed |
| `reduced_periods` | TINYINT(1) | Yes (default 0) | 1=fewer periods than normal (e.g., Sports Day may have 4 periods) |
| `ordinal` | TINYINT UNSIGNED | No (default 1) | Display order |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraints:** `ordinal`, `code`, `name`.

### S1-3: tt_period_type

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | TINYINT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | THEORY, TEACHING, PRACTICAL, BREAK, LUNCH, ASSEMBLY, EXAM, RECESS, FREE |
| `name` | VARCHAR(100) | Yes | Display name |
| `description` | VARCHAR(255) | No | Details |
| `color_code` | VARCHAR(10) | No | Hex color for UI (e.g., #FF0000) |
| `icon` | VARCHAR(50) | No | FontAwesome icon class (e.g., fa-solid fa-chalkboard-teacher) |
| `is_schedulable` | TINYINT(1) | Yes (default 1) | 1=activities can be placed here |
| `counts_as_teaching` | TINYINT(1) | Yes (default 0) | 1=counted in teaching period totals |
| `counts_as_workload` | TINYINT(1) | Yes (default 0) | 1=counted in teacher workload calculations |
| `is_break` | TINYINT(1) | Yes (default 0) | 1=this is a break period |
| `is_free_period` | TINYINT(1) | Yes (default 0) | 1=this is a free period |
| `ordinal` | TINYINT UNSIGNED | No (default 1) | Display order |
| `duration_minutes` | INT UNSIGNED | No (default 30) | Default duration in minutes |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraints:** `ordinal`, `code`.

### S1-4: tt_teacher_assignment_role

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | TINYINT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | PRIMARY, ASSISTANT, CO_TEACHER, SUBSTITUTE, TRAINEE |
| `name` | VARCHAR(100) | Yes | Display name |
| `description` | VARCHAR(255) | No | Details |
| `is_primary_instructor` | TINYINT(1) | Yes (default 0) | 1=this role is the lead teacher |
| `counts_for_workload` | TINYINT(1) | Yes (default 0) | 1=counts toward teacher workload |
| `allows_overlap` | TINYINT(1) | Yes (default 0) | 1=teacher can have overlapping assignments in this role |
| `workload_factor` | DECIMAL(5,2) | No (default 1.00) | Multiplier for workload calculation (0.25 for trainee, 1.00 for primary) |
| `ordinal` | TINYINT UNSIGNED | No (default 1) | Display order |
| `is_system` | TINYINT(1) | No (default 1) | 1=system role, cannot be deleted |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S1-5: tt_school_days

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | TINYINT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(10) UQ | Yes | MON, TUE, WED, THU, FRI, SAT, SUN |
| `name` | VARCHAR(20) | Yes | Monday, Tuesday, etc. |
| `short_name` | VARCHAR(5) | Yes | Mon, Tue, etc. |
| `day_of_week` | TINYINT UNSIGNED UQ | Yes | 1-7 (ISO 8601) |
| `ordinal` | TINYINT UNSIGNED | Yes | Display order |
| `is_school_day` | TINYINT(1) | Yes (default 1) | 1=school open, 0=closed (e.g., Sunday=0) |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraints:** `code`, `day_of_week`.

### S1-6: tt_working_day

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_session_id` | INT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `date` | DATE UQ | Yes | The calendar date |
| `day_type1_id` | TINYINT UNSIGNED | Yes | FK to `tt_day_type.id`. Primary day type |
| `day_type2_id` | TINYINT UNSIGNED | No | FK to `tt_day_type.id`. Secondary day type (multi-activity days) |
| `day_type3_id` | TINYINT UNSIGNED | No | FK to `tt_day_type.id`. Tertiary day type |
| `day_type4_id` | TINYINT UNSIGNED | No | FK to `tt_day_type.id`. Quaternary day type |
| `is_school_day` | TINYINT(1) | Yes (default 1) | 1=school open |
| `remarks` | VARCHAR(255) | No | Notes about the day |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Business rules:** Changing a day to Holiday must update `sch_academic_term.term_total_teaching_days`. Up to 4 day types can coexist on one date (e.g., Exam + Study).

### S1-7: tt_class_working_day_jnt

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_session_id` | INT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `date` | DATE | Yes | The calendar date |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` (NULL = all sections) |
| `working_day_id` | INT UNSIGNED | Yes | FK to `tt_working_day.id` |
| `is_exam_day` | TINYINT(1) | Yes (default 0) | Class-level exam flag |
| `is_ptm_day` | TINYINT(1) | Yes (default 0) | Class-level PTM flag |
| `is_half_day` | TINYINT(1) | Yes (default 0) | Class-level half day flag |
| `is_holiday` | TINYINT(1) | Yes (default 0) | Class-level holiday flag |
| `is_study_day` | TINYINT(1) | Yes (default 1) | Class-level study flag |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `class_id + working_day_id`.

### S1-8: tt_period_config (NEW v7.7)

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `shift_id` | TINYINT UNSIGNED | Yes | FK to `tt_shift.id`. Timeslots can differ by shift |
| `slot_ord` | TINYINT UNSIGNED | Yes | Sequential order within day for this shift: 1, 2, 3, ..., 12 |
| `code` | VARCHAR(20) | Yes | Machine-readable code: SLOT-01, SLOT-02, ..., SLOT-12 |
| `short_name` | VARCHAR(50) | Yes | Display label: Assembly, Period 1, Short Break, Lunch |
| `period_type_id` | TINYINT UNSIGNED | Yes | FK to `tt_period_type.id`. Default type for this slot |
| `start_time` | TIME | Yes | Fixed start time (e.g., 07:45:00) |
| `end_time` | TIME | Yes | Fixed end time (e.g., 08:30:00) |
| `duration_minutes` | SMALLINT UNSIGNED | GENERATED STORED | `TIMESTAMPDIFF(MINUTE, start_time, end_time)`. Auto-calculated |
| `is_teaching_slot` | TINYINT(1) | Yes (default 0) | 1=teaching period (for quick filtering) |
| `display_order` | TINYINT UNSIGNED | Yes (default 1) | UI display order (may differ from slot_ord) |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraints:** `shift_id + slot_ord`, `shift_id + code`.
**CHECK constraint:** `end_time > start_time`.
**Volume:** ~12-15 rows per shift (8 teaching + 1 lunch + 2-3 breaks + 1 assembly).

### S1-9: tt_period_set (MODIFIED v7.7)

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | STANDARD_8P, TODDLER_6P, HALF_DAY_4P, etc. |
| `name` | VARCHAR(100) | Yes | Display name |
| `description` | VARCHAR(255) | No | Details |
| `shift_id` | TINYINT UNSIGNED | Yes | FK to `tt_shift.id`. **NEW in v7.7.** Which shift timing grid |
| `from_period_ord` | TINYINT UNSIGNED | Yes | **NEW in v7.7.** First slot_ord from tt_period_config |
| `to_period_ord` | TINYINT UNSIGNED | Yes | **NEW in v7.7.** Last slot_ord from tt_period_config |
| `total_periods` | TINYINT UNSIGNED | Yes | Total period count (e.g., 8, 6) |
| `teaching_periods` | TINYINT UNSIGNED | Yes | Teaching period count |
| `exam_periods` | TINYINT UNSIGNED | Yes | Exam period count |
| `free_periods` | TINYINT UNSIGNED | Yes | Free period count |
| `assembly_periods` | TINYINT UNSIGNED | Yes | Assembly period count |
| `short_break_periods` | TINYINT UNSIGNED | Yes | Short break count |
| `lunch_break_periods` | TINYINT UNSIGNED | Yes | Lunch break count |
| `is_default` | TINYINT(1) | No (default 0) | Default period set |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**CHECK constraint:** `to_period_ord >= from_period_ord`.
**REMOVED in v7.7:** `day_start_time`, `day_end_time` (now derived from `tt_period_config` via from/to_period_ord).

### S1-10: tt_period_set_period_jnt (MODIFIED v7.7)

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `period_set_id` | INT UNSIGNED | Yes | FK to `tt_period_set.id` |
| `period_config_id` | INT UNSIGNED | Yes | **NEW in v7.7.** FK to `tt_period_config.id`. Timing inherited from here |
| `period_ord` | TINYINT UNSIGNED | Yes | Ordinal within this period set (local sequence 1, 2, 3...) |
| `code` | VARCHAR(20) | Yes | Period code within this set: P-1, P-2, BRK, LUNCH |
| `short_name` | VARCHAR(50) | Yes | Display name within this set |
| `period_type_id` | INT UNSIGNED | Yes | FK to `tt_period_type.id`. Can override tt_period_config default |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraints:** `period_set_id + period_ord`, `period_set_id + code`, `period_set_id + period_config_id`.
**REMOVED in v7.7:** `start_time`, `end_time`, `duration_minutes` (now from `tt_period_config`).

### S1-11: tt_timetable_type

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | STANDARD, UNIT_TEST-1, HALF_DAY, HALF_YEARLY, FINAL_EXAM |
| `name` | VARCHAR(100) | Yes | Display name |
| `description` | VARCHAR(255) | No | Details |
| `shift_id` | INT UNSIGNED | No | FK to `tt_shift.id` |
| `effective_from_date` | DATE | No | When this timetable type becomes active |
| `effective_to_date` | DATE | No | When this timetable type expires |
| `school_start_time` | TIME | No | School start time for this type |
| `school_end_time` | TIME | No | School end time for this type |
| `has_exam` | TINYINT(1) | Yes (default 0) | Whether this type includes exam periods |
| `has_teaching` | TINYINT(1) | Yes (default 1) | Whether this type includes teaching periods |
| `ordinal` | SMALLINT UNSIGNED | No (default 1) | Display order |
| `is_default` | TINYINT(1) | No (default 0) | Default timetable type |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**CHECK constraint:** `school_end_time > school_start_time` AND `effective_from_date <= effective_to_date`.
**Business rule:** Application must prevent overlapping school start/end times for the same shift.

### S1-12: tt_class_timetable_type_jnt

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_term_id` | INT UNSIGNED | No | FK to `sch_academic_term.id` |
| `timetable_type_id` | INT UNSIGNED | Yes | FK to `tt_timetable_type.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` (NULL if all sections) |
| `period_set_id` | INT UNSIGNED | Yes | FK to `tt_period_set.id` |
| `applies_to_all_sections` | TINYINT(1) | Yes (default 1) | 1=same for all sections of class |
| `has_teaching` | TINYINT(1) | Yes (default 1) | Whether this class has teaching |
| `has_exam` | TINYINT(1) | Yes (default 0) | Whether this class has exams |
| `weekly_exam_period_count` | TINYINT UNSIGNED | No | From tt_period_set |
| `weekly_teaching_period_count` | TINYINT UNSIGNED | No | From tt_period_set |
| `weekly_free_period_count` | TINYINT UNSIGNED | No | From tt_period_set |
| `effective_from` | DATE | No | When assignment starts |
| `effective_to` | DATE | No | When assignment ends |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**CHECK constraints:** `effective_from < effective_to`. Section/applies_to_all_sections consistency: `(section_id IS NULL AND applies_to_all_sections = 1) OR (section_id IS NOT NULL AND applies_to_all_sections = 0)`.

### S2-1: tt_slot_requirement

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_term_id` | INT UNSIGNED | Yes | FK to `sch_academic_term.id` |
| `timetable_type_id` | INT UNSIGNED | Yes | FK to `tt_timetable_type.id` |
| `class_timetable_type_id` | INT UNSIGNED | Yes | FK to `tt_class_timetable_type_jnt.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | Yes | FK to `sch_sections.id` |
| `class_house_room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` |
| `weekly_total_slots` | TINYINT UNSIGNED | Yes | Total slots per week |
| `weekly_teaching_slots` | TINYINT UNSIGNED | Yes | Teaching slots per week |
| `weekly_exam_slots` | TINYINT UNSIGNED | Yes | Exam slots per week |
| `weekly_free_slots` | TINYINT UNSIGNED | Yes | Free slots per week |
| `activity_id` | INT UNSIGNED | No | FK to `tt_activity.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |

**Note:** No audit fields (created_at, updated_at). This is a calculation table.

### S2-2: tt_class_requirement_groups

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | CHAR(50) UQ | Yes | Copied from sch_class_groups_jnt.code |
| `name` | VARCHAR(100) | Yes | Copied from sch_class_groups_jnt.name |
| `class_group_id` | INT UNSIGNED | Yes | FK to `sch_class_groups.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `study_format_id` | INT UNSIGNED | Yes | FK to `sch_study_formats.id` |
| `subject_type_id` | INT UNSIGNED | Yes | FK to `sch_subject_types.id` |
| `subject_study_format_id` | INT UNSIGNED | Yes | FK to `sch_subject_study_format_jnt.id` |
| `class_house_room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` |
| `student_count` | INT UNSIGNED | No | Fetched from sch_class_section_jnt.actual_total_student |
| `eligible_teacher_count` | INT UNSIGNED | No | Counted from teacher profiles |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `deleted_at` | TIMESTAMP | No | Soft delete |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

**Unique constraints:** `code`, `class_id + section_id + subject_study_format_id`.

### S2-3: tt_class_requirement_subgroups

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(50) UQ | Yes | Subgroup code |
| `name` | VARCHAR(100) | Yes | Display name |
| `class_group_id` | INT UNSIGNED | Yes | FK to `sch_class_groups.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `study_format_id` | INT UNSIGNED | Yes | FK to `sch_study_formats.id` |
| `subject_type_id` | INT UNSIGNED | Yes | FK to `sch_subject_types.id` |
| `subject_study_format_id` | INT UNSIGNED | Yes | FK to `sch_subject_study_format_jnt.id` |
| `class_house_room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` |
| `student_count` | INT UNSIGNED | No | Number of students in this subgroup |
| `eligible_teacher_count` | INT UNSIGNED | No | Teachers available for this subgroup |
| `is_shared_across_sections` | TINYINT(1) | Yes (default 0) | Whether subgroup spans sections (editable) |
| `is_shared_across_classes` | TINYINT(1) | Yes (default 0) | Whether subgroup spans classes (editable) |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Student count calculation:** Count students from `std_student_academic_sessions` where matching subject_group/class/section.

### S2-4: tt_requirement_consolidation

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_term_id` | INT UNSIGNED | Yes | FK to `sch_academic_term.id` |
| `timetable_type_id` | INT UNSIGNED | Yes | FK to `tt_timetable_type.id` |
| `class_requirement_group_id` | INT UNSIGNED | Conditional | FK to `sch_class_groups_jnt.id` |
| `class_requirement_subgroup_id` | INT UNSIGNED | Conditional | FK to `tt_requirement_subgroups.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `study_format_id` | INT UNSIGNED | Yes | FK to `sch_study_formats.id` |
| `subject_type_id` | INT UNSIGNED | Yes | FK to `sch_subject_types.id` |
| `subject_study_format_id` | INT UNSIGNED | Yes | FK to `sch_subject_study_format_jnt.id` |
| `class_house_room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` (non-editable) |
| `student_count` | INT UNSIGNED | No | Non-editable, fetched from groups/subgroups |
| `eligible_teacher_count` | INT UNSIGNED | No | Non-editable |
| `is_compulsory` | TINYINT(1) | Yes (default 1) | **Editable.** Whether this requirement must be scheduled |
| `required_weekly_periods` | TINYINT UNSIGNED | Yes (default 1) | **Editable.** Total periods per week |
| `min_periods_required_per_week` | TINYINT UNSIGNED | No | **Editable.** Minimum weekly periods |
| `max_periods_required_per_week` | TINYINT UNSIGNED | No | **Editable.** Maximum weekly periods |
| `min_periods_required_per_day` | TINYINT UNSIGNED | No | **Editable.** Minimum daily periods |
| `max_periods_required_per_day` | TINYINT UNSIGNED | No | **Editable.** Maximum daily periods |
| `min_gap_between_periods` | TINYINT UNSIGNED | No | **Editable.** Minimum gap |
| `required_consecutive_periods` | TINYINT UNSIGNED | No | **Editable.** Required consecutive count |
| `min_required_consecutive_periods` | TINYINT UNSIGNED | No | **Editable.** Minimum consecutive count |
| `allow_consecutive_periods` | TINYINT(1) | Yes (default 0) | **Editable.** Whether consecutive allowed |
| `max_consecutive_periods` | TINYINT UNSIGNED | No (default 2) | **Editable.** Maximum consecutive |
| `class_priority_score` | TINYINT UNSIGNED | No | Priority score from sch_class_group |
| `preferred_periods_json` | JSON | No | **Editable.** Preferred period slots (multi-select saved as JSON) |
| `avoid_periods_json` | JSON | No | **Editable.** Periods to avoid |
| `spread_evenly` | TINYINT(1) | No (default 1) | **Editable.** Whether periods should be distributed evenly across days |
| `is_shared_across_sections` | TINYINT(1) | Yes (default 0) | **Editable.** Cross-section sharing |
| `is_shared_across_classes` | TINYINT(1) | Yes (default 0) | **Editable.** Cross-class sharing |
| `compulsory_specific_room_type` | TINYINT(1) | Yes (default 0) | Whether specific room type is required |
| `required_room_type_id` | INT UNSIGNED | Yes | FK to `sch_rooms_type.id` |
| `required_room_id` | INT UNSIGNED | No | FK to `sch_rooms.id` (optional specific room) |
| `is_active` | TINYINT(1) UNSIGNED | Yes (default 1) | Soft toggle |

**Unique constraint:** `academic_term_id + timetable_type_id + class_requirement_group_id + class_requirement_subgroup_id`.
**CHECK constraint:** Exactly one of `class_requirement_group_id` or `class_requirement_subgroup_id` must be non-NULL.

### S3-1: tt_constraint_category_scope

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `type` | ENUM('CATEGORY','SCOPE') | Yes | Whether this row is a category or a scope |
| `code` | VARCHAR(30) | Yes | Machine-readable code (not user-editable) |
| `name` | VARCHAR(100) | Yes | Display name (user can change) |
| `description` | VARCHAR(255) | No | Details |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `type + code`.
**Seeded categories:** PERIOD, ROOM, TEACHER, CLASS, CLASS+SECTION, SUBJECT, STUDY_FORMAT, SUBJECT_STUDY_FORMAT, SUBJECT_TYPE, ACTIVITY.
**Seeded scopes:** GLOBAL, TEACHER, ROOM, ACTIVITY, CLASS, CLASS+SECTION, CLASS+SUBJECT+STUDY_FORMAT, SUBJECT+STUDY_FORMAT, SUBJECT, CLASS_GROUP, CLASS_SUBGROUP.

### S3-2: tt_constraint_type

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(60) UQ | Yes | TEACHER_NOT_AVAILABLE, MIN_DAYS_BETWEEN, SAME_STARTING_TIME, etc. |
| `name` | VARCHAR(150) | Yes | Display name (user can change) |
| `description` | VARCHAR(255) | No | Details |
| `category_id` | INT UNSIGNED | Yes | FK to `tt_constraint_category_scope.id` (where type=CATEGORY) |
| `applicable_to` | ENUM('ALL','SPECIFIC') | No (default ALL) | Whether applicable to all or specific targets |
| `scope_id` | INT UNSIGNED | Yes | FK to `tt_constraint_category_scope.id` (where type=SCOPE) |
| `target_id_required` | TINYINT(1) | Yes (default 0) | Whether target_id must be provided in instances |
| `default_weight` | TINYINT UNSIGNED | No (default 100) | Default weight for instances |
| `is_hard_constraint` | TINYINT(1) | No (default 1) | Whether this type can be a hard constraint |
| `param_schema` | JSON | No | JSON Schema defining required parameters |
| `is_system` | TINYINT(1) | No (default 1) | 1=system constraint, user cannot delete |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S3-3: tt_constraint

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `constraint_type_id` | INT UNSIGNED | Yes | FK to `tt_constraint_type.id` |
| `name` | VARCHAR(200) | No | Instance-specific label |
| `description` | VARCHAR(500) | No | Details |
| `academic_term_id` | INT UNSIGNED | No | FK to `sch_academic_term.id` |
| `target_type` | INT UNSIGNED | Yes | FK to `tt_constraint_category_scope.id` (whom this applies to) |
| `target_id` | INT UNSIGNED | No | FK to target entity (specific teacher, class, or room ID) |
| `is_hard` | TINYINT(1) | Yes (default 0) | 1=inviolable hard constraint |
| `weight` | TINYINT UNSIGNED | Yes (default 100) | Soft constraint weight (1-100) |
| `params_json` | JSON | Yes | Parameters for this constraint instance |
| `effective_from` | DATE | No | When constraint starts |
| `effective_to` | DATE | No | When constraint expires |
| `apply_for_all_days` | TINYINT(1) | Yes (default 1) | 1=applies every day |
| `applicable_days` | JSON | No | JSON array of days (if not all days) |
| `impact_score` | TINYINT UNSIGNED | No (default 50) | Estimated difficulty impact (1-100) |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S3-4: tt_teacher_unavailable

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `constraint_id` | INT UNSIGNED | No | FK to `tt_constraint.id` |
| `unavailable_for_all_days` | TINYINT(1) | Yes (default 0) | 1=unavailable every day in date range |
| `day_of_week` | ENUM | Yes (default Monday) | Monday through Sunday |
| `unavailable_for_all_periods` | TINYINT(1) | Yes (default 0) | 1=unavailable all periods |
| `period_no` | TINYINT UNSIGNED | No | Specific period (one record per unavailable period) |
| `is_recurring` | TINYINT(1) | No (default 1) | 1=repeats on schedule |
| `recurring_frequency` | ENUM | No (default Daily) | Daily, Weekly, Monthly, Yearly |
| `start_date` | DATE | No | Start of unavailability range |
| `end_date` | DATE | No | End of unavailability range |
| `reason` | VARCHAR(255) | No | Why the teacher is unavailable |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S3-5: tt_room_unavailable

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` |
| `constraint_id` | INT UNSIGNED | No | FK to `tt_constraint.id` |
| `day_of_week` | TINYINT UNSIGNED | Yes | 1=Monday, ..., 7=Sunday (ISO 8601) |
| `period_ord` | TINYINT UNSIGNED | No | Specific period ordinal |
| `start_date` | DATE | No | Start of unavailability range |
| `end_date` | DATE | No | End of unavailability range |
| `reason` | VARCHAR(255) | No | Why the room is unavailable |
| `is_recurring` | TINYINT(1) | No (default 1) | 1=repeats |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S4-1: tt_teacher_availability

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `requirement_consolidation_id` | INT UNSIGNED | Yes | FK to `tt_requirement_consolidation.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `subject_study_format_id` | INT UNSIGNED | Yes | FK to `sch_study_formats.id` |
| `teacher_profile_id` | INT UNSIGNED | Yes | FK to `sch_teacher_profile.id` |
| `required_weekly_periods` | TINYINT UNSIGNED | Yes (default 1) | Periods needed per week |
| `is_full_time` | TINYINT(1) | No (default 1) | From sch_teacher_profile |
| `preferred_shift` | INT UNSIGNED | No | FK to `tt_shift.id` |
| `capable_handling_multiple_classes` | TINYINT(1) | No (default 0) | From profile |
| `can_be_used_for_substitution` | TINYINT(1) | No (default 1) | From profile |
| `certified_for_lab` | TINYINT(1) | No (default 0) | Lab certification |
| `max_available_periods_weekly` | TINYINT UNSIGNED | No (default 48) | From profile |
| `min_available_periods_weekly` | TINYINT UNSIGNED | No (default 36) | From profile |
| `max_allocated_periods_weekly` | TINYINT UNSIGNED | No (default 1) | Auto-calculated |
| `min_allocated_periods_weekly` | TINYINT UNSIGNED | No (default 1) | Auto-calculated |
| `can_be_split_across_sections` | TINYINT(1) | No (default 0) | From profile |
| `proficiency_percentage` | TINYINT UNSIGNED | No | 1-100, from capabilities |
| `teaching_experience_months` | SMALLINT UNSIGNED | No | From capabilities |
| `is_primary_subject` | TINYINT(1) | Yes (default 1) | From capabilities |
| `competancy_level` | ENUM | No (default Basic) | Facilitator, Basic, Intermediate, Advanced, Expert |
| `priority_order` | INT UNSIGNED | No | Teacher priority for this class+subject |
| `priority_weight` | TINYINT UNSIGNED | No | Manual/computed weight (1-10) |
| `scarcity_index` | TINYINT UNSIGNED | No | 1=abundant, 10=very rare |
| `is_hard_constraint` | TINYINT(1) | No (default 0) | If true, cannot be violated |
| `allocation_strictness` | ENUM | No (default Medium) | Hard, Medium, Soft |
| `override_priority` | TINYINT UNSIGNED | No | Admin override |
| `override_reason` | VARCHAR(255) | No | Why admin overrode priority |
| `historical_success_ratio` | TINYINT UNSIGNED | No | 1-100 past success rate |
| `last_allocation_score` | TINYINT UNSIGNED | No | Score from last generation run |
| `is_primary_teacher` | TINYINT(1) | Yes (default 1) | School preference |
| `is_preferred_teacher` | TINYINT(1) | Yes (default 0) | School preference |
| `preference_score` | TINYINT UNSIGNED | No | 1-100 preference score |
| `teacher_profile_from_date` | DATE | No | From sch_teacher_profile.effective_from |
| `teacher_profile_to_date` | DATE | No | From sch_teacher_profile.effective_to |
| `teacher_available_from_date` | DATE | No | From sch_teacher_capabilities.effective_from |
| `timetable_start_date` | DATE | No | From tt_timetable.start_date |
| `timetable_end_date` | DATE | No | From tt_timetable.end_date |
| `available_for_full_timetable_duration` | TINYINT(1) | GENERATED STORED | `IF(teacher_available_from_date <= timetable_start_date, 1, 0)` |
| `no_of_days_not_available` | INT | GENERATED STORED | `GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))` |
| `min_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | No (default 1) | Calculated availability score |
| `max_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | No (default 1) | Calculated availability score |
| `activity_id` | INT UNSIGNED | No | FK to `tt_activity.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |

**Unique constraint:** `requirement_consolidation_id + teacher_profile_id`.

### S4-2: tt_teacher_availability_detail

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `teacher_availability_id` | INT UNSIGNED | Yes | FK to `tt_teacher_availability.id` |
| `teacher_profile_id` | INT UNSIGNED | Yes | FK to `sch_teacher_profile.id` |
| `day_number` | TINYINT UNSIGNED | Yes | 1-7 day number |
| `day_name` | VARCHAR(10) | Yes | Day name |
| `period_number` | TINYINT UNSIGNED | Yes | 1-8 period number |
| `can_be_assigned` | TINYINT(1) | Yes (default 1) | 1=available for assignment |
| `availability_for_period` | ENUM | Yes (default Available) | Available, Unavailable, Assigned, Free Period |
| `assigned_class_id` | INT UNSIGNED | No | FK to `sch_classes.id` (if Assigned) |
| `assigned_section_id` | INT UNSIGNED | No | FK to `sch_sections.id` (if Assigned) |
| `assigned_subject_study_format_id` | INT UNSIGNED | No | FK to `sch_study_formats.id` (if Assigned) |
| `teacher_available_from_date` | DATE | No | From capabilities effective_from |
| `activity_id` | INT UNSIGNED | No | FK to `tt_activity.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |

**Unique constraint:** `teacher_profile_id + day_number + period_number`.

### S4-3: tt_room_availability

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` |
| `rooms_type_id` | INT UNSIGNED | Yes | FK to `sch_rooms_type.id` |
| `total_rooms_in_category` | SMALLINT UNSIGNED | Yes | From sch_rooms_type.room_count_in_category |
| `can_be_assigned` | TINYINT(1) | Yes (default 1) | 1=available |
| `overall_availability_status` | ENUM | Yes (default Available) | Available, Unavailable, Partially Available, Assigned |
| `available_for_full_timetable_duration` | TINYINT(1) | Yes (default 1) | 1=available for entire period |
| `is_class_house_room` | TINYINT(1) | Yes (default 0) | 1=this is a home room |
| `house_room_class_id` | INT UNSIGNED | No | FK to `sch_classes.id` |
| `house_room_section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `activity_id` | INT UNSIGNED | No | FK to `tt_activity.id` |
| `capacity` | INT UNSIGNED | No | Seating capacity |
| `max_limit` | INT UNSIGNED | No | Maximum student count |
| `can_be_assigned_for_lecture` | TINYINT(1) | Yes (default 1) | Room can host lectures |
| `can_be_assigned_for_practical` | TINYINT(1) | Yes (default 1) | Room can host practicals |
| `can_be_assigned_for_exam` | TINYINT(1) | Yes (default 1) | Room can host exams |
| `can_be_assigned_for_activity` | TINYINT(1) | Yes (default 1) | Room can host activities |
| `can_be_assigned_for_sports` | TINYINT(1) | Yes (default 1) | Room can host sports |
| `timetable_start_time` | TIME | Yes | From tt_timetable_type.effective_from_date |
| `timetable_end_time` | TIME | Yes | From tt_timetable_type.effective_to_date |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |

**CHECK constraint:** `(is_class_house_room = 1 AND house_room_class_id IS NOT NULL AND house_room_section_id IS NOT NULL) OR (is_class_house_room = 0)`.

### S4-4: tt_room_availability_detail

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `room_availability_id` | INT UNSIGNED | Yes | FK to `tt_room_availability.id` |
| `room_id` | INT UNSIGNED | Yes | FK to `sch_rooms.id` |
| `room_type_id` | INT UNSIGNED | Yes | FK to `sch_rooms_type.id` |
| `day_number` | TINYINT UNSIGNED | Yes | 1-7 day number |
| `day_name` | VARCHAR(10) | Yes | Day name |
| `period_number` | TINYINT UNSIGNED | Yes | 1-8 period number |
| `availability_for_period` | ENUM | Yes (default Available) | Available, Unavailable, Assigned |
| `assigned_class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `assigned_section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `assigned_subject_study_format_id` | INT UNSIGNED | Yes | FK to `sch_study_formats.id` |
| `room_available_from_date` | DATE | No | From sch_rooms.room_available_from_date |
| `activity_id` | INT UNSIGNED | No | FK to `tt_activity.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |

### S5-1: tt_priority_config

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `requirement_consolidation_id` | INT UNSIGNED | Yes | FK to `tt_requirement_consolidation.id` |
| `tot_students` | INT UNSIGNED | No | Total students in this requirement |
| `teacher_scarcity_index` | DECIMAL(7,2) UNSIGNED | No (default 1) | Fewer qualified teachers = higher value |
| `weekly_load_ratio` | DECIMAL(7,2) UNSIGNED | No (default 1) | Required periods / total periods ratio |
| `average_teacher_availability_ratio` | DECIMAL(7,2) UNSIGNED | No (default 1) | TAR = allocated / available * 100 |
| `rigidity_score` | DECIMAL(7,2) UNSIGNED | No (default 1) | Allowed slots / total slots |
| `resource_scarcity` | DECIMAL(7,2) UNSIGNED | No (default 1) | Required resources / available resources |
| `subject_difficulty_index` | DECIMAL(7,2) UNSIGNED | No (default 1) | Harder subjects get higher value |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |

### S5-2: tt_activity

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(50) UQ | Yes | From groups/subgroups code |
| `name` | VARCHAR(200) | Yes | From groups/subgroups name |
| `academic_term_id` | INT UNSIGNED | Yes | FK to `sch_academic_term.id` |
| `timetable_type_id` | INT UNSIGNED | Yes | FK to `tt_timetable_type.id` |
| `activity_group_id` | INT UNSIGNED | No | FK to `sch_class_groups_jnt.id` |
| `have_sub_activity` | TINYINT(1) | Yes (default 0) | 1=has sub-activities |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | No | FK to `sch_sections.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `study_format_id` | INT UNSIGNED | Yes | FK to `sch_study_formats.id` |
| `subject_type_id` | INT UNSIGNED | Yes | FK to `sch_subject_types.id` |
| `subject_study_format_id` | INT UNSIGNED | Yes | FK to `sch_subject_study_format_jnt.id` |
| `required_weekly_periods` | TINYINT UNSIGNED | Yes (default 1) | Periods per week |
| `min_periods_per_week` | TINYINT UNSIGNED | No | Minimum weekly |
| `max_periods_per_week` | TINYINT UNSIGNED | No | Maximum weekly |
| `max_per_day` | TINYINT UNSIGNED | No | Maximum daily |
| `min_per_day` | TINYINT UNSIGNED | No | Minimum daily |
| `min_gap_periods` | TINYINT UNSIGNED | No | Minimum gap |
| `allow_consecutive` | TINYINT(1) | Yes (default 0) | Allow consecutive |
| `max_consecutive` | TINYINT UNSIGNED | No (default 2) | Max consecutive |
| `preferred_periods_json` | JSON | No | Preferred slots |
| `avoid_periods_json` | JSON | No | Slots to avoid |
| `spread_evenly` | TINYINT(1) | No (default 1) | Even daily spread |
| `eligible_teacher_count` | INT UNSIGNED | No | Available teachers |
| `min_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | No (default 1) | Availability score |
| `max_teacher_availability_score` | DECIMAL(7,2) UNSIGNED | No (default 1) | Availability score |
| `duration_periods` | TINYINT UNSIGNED | Yes (default 1) | Periods per occurrence (Labs=2) |
| `weekly_periods` | TINYINT UNSIGNED | Yes (default 1) | Times per week |
| `total_periods` | SMALLINT UNSIGNED | GENERATED STORED | `duration_periods * weekly_periods` |
| `split_allowed` | TINYINT(1) | No (default 0) | Can split across non-consecutive slots |
| `is_compulsory` | TINYINT(1) | No (default 1) | Must be scheduled |
| `priority` | TINYINT UNSIGNED | No (default 50) | Scheduling priority (0-100) |
| `difficulty_score` | TINYINT UNSIGNED | No (default 50) | Higher = harder to schedule |
| `compulsory_specific_room_type` | TINYINT(1) | Yes (default 0) | Specific room type required |
| `required_room_type_id` | INT UNSIGNED | Yes | FK to `sch_rooms_type.id` |
| `required_room_id` | INT UNSIGNED | No | FK to `sch_rooms.id` (optional) |
| `requires_room` | TINYINT(1) | No (default 1) | Whether room is needed |
| `preferred_room_type_id` | INT UNSIGNED | No | FK to `sch_rooms_type.id` |
| `preferred_room_ids` | JSON | No | Preferred rooms list |
| `difficulty_score_calculated` | TINYINT UNSIGNED | No (default 50) | Auto-calculated difficulty |
| `teacher_availability_score` | TINYINT UNSIGNED | No (default 100) | Auto-calculated |
| `room_availability_score` | TINYINT UNSIGNED | No (default 100) | Auto-calculated |
| `constraint_count` | SMALLINT UNSIGNED | No (default 0) | Constraints affecting this activity |
| `preferred_time_slots_json` | JSON | No | Preferred time slots |
| `avoid_time_slots_json` | JSON | No | Time slots to avoid |
| `status` | ENUM | Yes (default ACTIVE) | DRAFT, ACTIVE, LOCKED, ARCHIVED |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**CHECK constraint:** Exactly one of `class_group_id` or `class_subgroup_id` must be non-NULL.

### S5-3: tt_sub_activity

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `parent_activity_id` | INT UNSIGNED | Yes | FK to `tt_activity.id` |
| `class_requirement_subgroups` | INT UNSIGNED | Yes | FK to `tt_class_requirement_subgroups.id` |
| `ordinal` | TINYINT UNSIGNED | Yes | Order within parent activity |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `section_id` | INT UNSIGNED | Yes | FK to `sch_sections.id` |
| `duration_periods` | TINYINT UNSIGNED | Yes (default 1) | Duration in periods |
| `same_day_as_parent` | TINYINT(1) | No (default 0) | Must be on same day as parent |
| `consecutive_with_previous` | TINYINT(1) | No (default 0) | Must follow previous sub-activity immediately |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `parent_activity_id + ordinal`.

### S5-4: tt_activity_priority

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `activity_id` | INT UNSIGNED UQ | Yes | FK to `tt_activity.id` |
| `priority_score` | DECIMAL(5,2) | Yes | 0.00 to 100.00 |
| `priority_reason` | TEXT | No | Human-readable explanation |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S5-5: tt_activity_teacher

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `activity_id` | INT UNSIGNED | Yes | FK to `tt_activity.id` |
| `teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `assignment_role_id` | INT UNSIGNED | Yes | FK to `tt_teacher_assignment_role.id` |
| `is_required` | TINYINT(1) | No (default 1) | 1=mandatory teacher for this activity |
| `ordinal` | TINYINT UNSIGNED | No (default 1) | Preference order |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `activity_id + teacher_id`.

### S6-1: tt_timetable

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(50) UQ | Yes | TT_2025_26_V1, TT_EXAM_OCT_2025, etc. |
| `name` | VARCHAR(200) | Yes | Display name |
| `description` | TEXT | No | Detailed description |
| `academic_session_id` | INT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `academic_term_id` | INT UNSIGNED | Yes | FK to `sch_academic_term.id` |
| `timetable_type_id` | INT UNSIGNED | Yes | FK to `tt_timetable_type.id` |
| `period_set_id` | INT UNSIGNED | Yes | FK to `tt_period_set.id` |
| `effective_from` | DATE | Yes | Start date |
| `effective_to` | DATE | No | End date |
| `generation_method` | ENUM | Yes (default MANUAL) | MANUAL, SEMI_AUTO, FULL_AUTO |
| `generation_strategy_id` | INT UNSIGNED | No | FK to `tt_generation_strategy.id` |
| `version` | SMALLINT UNSIGNED | Yes (default 1) | Version number |
| `parent_timetable_id` | INT UNSIGNED | No | FK to `tt_timetable.id` (self-reference for versioning) |
| `status` | ENUM | Yes (default DRAFT) | DRAFT, GENERATING, GENERATED, PUBLISHED, ARCHIVED |
| `published_at` | TIMESTAMP | No | When published |
| `published_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `last_optimized_at` | TIMESTAMP | No | When last optimized |
| `constraint_violations` | INT UNSIGNED | No (default 0) | Total violations |
| `soft_score` | DECIMAL(8,2) | No | Soft constraint satisfaction score |
| `optimization_cycles` | INT UNSIGNED | No (default 0) | Number of optimization rounds |
| `quality_score` | DECIMAL(5,2) | No | Overall quality (0-100) |
| `teacher_satisfaction_score` | DECIMAL(5,2) | No | Teacher preference satisfaction |
| `room_utilization_score` | DECIMAL(5,2) | No | Room utilization efficiency |
| `stats_json` | JSON | No | Additional statistics |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S6-2: tt_conflict_detection

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `timetable_id` | INT UNSIGNED | Yes | FK to `tt_timetable.id` |
| `detection_type` | ENUM | Yes | REAL_TIME, BATCH, VALIDATION, GENERATION |
| `detected_at` | TIMESTAMP | No (default CURRENT_TIMESTAMP) | When detected |
| `conflict_count` | INT UNSIGNED | No (default 0) | Total conflicts |
| `hard_conflicts` | INT UNSIGNED | No (default 0) | Hard constraint violations |
| `soft_conflicts` | INT UNSIGNED | No (default 0) | Soft constraint violations |
| `conflicts_json` | JSON | No | Detailed conflict descriptions |
| `resolution_suggestions_json` | JSON | No | Suggested fixes |
| `resolved_at` | TIMESTAMP | No | When resolved |
| `is_active` | TINYINT(1) | No (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

### S6-3: tt_resource_booking

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `resource_type` | ENUM | Yes | ROOM, LAB, TEACHER, EQUIPMENT, SPORTS, SPECIAL |
| `resource_id` | INT UNSIGNED | Yes | FK to resource entity |
| `booking_date` | DATE | Yes | Booking date |
| `day_of_week` | TINYINT UNSIGNED | No | Day of week |
| `period_ord` | TINYINT UNSIGNED | No | Period ordinal |
| `start_time` | TIME | No | Start time |
| `end_time` | TIME | No | End time |
| `booked_for_type` | ENUM | Yes | ACTIVITY, EXAM, EVENT, MAINTENANCE |
| `booked_for_id` | INT UNSIGNED | Yes | FK to booking entity |
| `purpose` | VARCHAR(500) | No | Booking purpose |
| `supervisor_id` | INT UNSIGNED | No | FK to `sch_teachers.id` |
| `status` | ENUM | No (default BOOKED) | BOOKED, IN_USE, COMPLETED, CANCELLED |
| `is_active` | TINYINT UNSIGNED | No (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

### S6-4: tt_generation_run

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `timetable_id` | INT UNSIGNED | Yes | FK to `tt_timetable.id` |
| `run_number` | INT UNSIGNED | Yes (default 1) | Sequential run number |
| `started_at` | TIMESTAMP | Yes | When started |
| `finished_at` | TIMESTAMP | No | When finished |
| `status` | ENUM | Yes (default QUEUED) | QUEUED, RUNNING, COMPLETED, FAILED, CANCELLED |
| `strategy_id` | INT UNSIGNED | No | FK to `tt_generation_strategy.id` |
| `algorithm_version` | VARCHAR(20) | No | Algorithm version used |
| `max_recursion_depth` | INT UNSIGNED | No (default 14) | Max recursion depth |
| `max_placement_attempts` | INT UNSIGNED | No | Max placement attempts |
| `retry_count` | TINYINT UNSIGNED | No (default 0) | Retry count |
| `params_json` | JSON | No | Parameters used |
| `activities_total` | INT UNSIGNED | No (default 0) | Total activities |
| `activities_placed` | INT UNSIGNED | No (default 0) | Successfully placed |
| `activities_failed` | INT UNSIGNED | No (default 0) | Failed to place |
| `hard_violations` | INT UNSIGNED | No (default 0) | Hard violations |
| `soft_violations` | INT UNSIGNED | No (default 0) | Soft violations |
| `soft_score` | DECIMAL(10,4) | No | Optimization score |
| `stats_json` | JSON | No | Run statistics |
| `error_message` | TEXT | No | Error details on failure |
| `triggered_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `timetable_id + run_number`.

### S6-5: tt_constraint_violation

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `timetable_id` | INT UNSIGNED | Yes | FK to `tt_timetable.id` |
| `constraint_id` | INT UNSIGNED | Yes | FK to `tt_constraint.id` |
| `violation_type` | ENUM('HARD','SOFT') | Yes | Type of violation |
| `violation_count` | INT UNSIGNED | Yes | Number of violations |
| `violation_details` | JSON | No | Details |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |

### S6-6: tt_timetable_cell

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `timetable_id` | INT UNSIGNED | Yes | FK to `tt_timetable.id` |
| `generation_run_id` | INT UNSIGNED | No | FK to `tt_generation_run.id` |
| `day_of_week` | TINYINT UNSIGNED | Yes | Day of week (1-7) |
| `period_ord` | TINYINT UNSIGNED | Yes | Period ordinal |
| `cell_date` | DATE | No | Specific date (for date-based timetables) |
| `class_group_id` | INT UNSIGNED | Conditional | FK to `sch_class_groups_jnt.id` |
| `class_subgroup_id` | INT UNSIGNED | Conditional | FK to `tt_requirement_subgroups.id` |
| `activity_id` | INT UNSIGNED | No | FK to `tt_activity.id` |
| `sub_activity_id` | INT UNSIGNED | No | FK to `tt_sub_activity.id` |
| `room_id` | INT UNSIGNED | No | FK to `sch_rooms.id` |
| `source` | ENUM | Yes (default AUTO) | AUTO, MANUAL, SWAP, LOCK |
| `is_locked` | TINYINT(1) | Yes (default 0) | 1=cell cannot be moved by algorithm |
| `locked_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `locked_at` | TIMESTAMP | No | When locked |
| `has_conflict` | TINYINT(1) | No (default 0) | 1=cell has constraint violations |
| `conflict_details_json` | JSON | No | Conflict details |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `timetable_id + day_of_week + period_ord + class_group_id + class_subgroup_id`.
**CHECK constraint:** Exactly one of `class_group_id` or `class_subgroup_id` must be non-NULL.

### S6-7: tt_timetable_cell_teacher

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `cell_id` | INT UNSIGNED | Yes | FK to `tt_timetable_cell.id` |
| `teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `assignment_role_id` | INT UNSIGNED | Yes | FK to `tt_teacher_assignment_role.id` |
| `is_substitute` | TINYINT(1) | No (default 0) | 1=substitute teacher |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `cell_id + teacher_id`.

### S8-1: tt_teacher_workload

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `academic_session_id` | INT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `timetable_id` | INT UNSIGNED | No | FK to `tt_timetable.id` |
| `weekly_periods_assigned` | SMALLINT UNSIGNED | No (default 0) | Periods assigned |
| `weekly_periods_max` | SMALLINT UNSIGNED | No | Maximum allowed |
| `weekly_periods_min` | SMALLINT UNSIGNED | No | Minimum allowed |
| `daily_distribution_json` | JSON | No | Periods per day breakdown |
| `subjects_assigned_json` | JSON | No | Subjects list |
| `classes_assigned_json` | JSON | No | Classes list |
| `utilization_percent` | DECIMAL(5,2) | No | assigned / max * 100 |
| `gap_periods_total` | SMALLINT UNSIGNED | No (default 0) | Total idle periods between classes |
| `consecutive_max` | TINYINT UNSIGNED | No (default 0) | Longest consecutive teaching streak |
| `last_calculated_at` | TIMESTAMP | No | When last recalculated |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `teacher_id + academic_session_id + timetable_id`.

### S9-1: tt_change_log

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `timetable_id` | INT UNSIGNED | Yes | FK to `tt_timetable.id` |
| `cell_id` | INT UNSIGNED | No | FK to `tt_timetable_cell.id` |
| `change_type` | ENUM | Yes | CREATE, UPDATE, DELETE, LOCK, UNLOCK, SWAP, SUBSTITUTE |
| `change_date` | DATE | Yes | When the change occurred |
| `old_values_json` | JSON | No | Before state |
| `new_values_json` | JSON | No | After state |
| `reason` | VARCHAR(500) | No | Why the change was made |
| `changed_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### S10-1: tt_teacher_absence

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `absence_date` | DATE | Yes | Date of absence |
| `absence_type` | ENUM | Yes | LEAVE, SICK, TRAINING, OFFICIAL_DUTY, OTHER |
| `start_period` | TINYINT UNSIGNED | No | First period absent (NULL = all day) |
| `end_period` | TINYINT UNSIGNED | No | Last period absent |
| `reason` | VARCHAR(500) | No | Reason for absence |
| `status` | ENUM | Yes (default PENDING) | PENDING, APPROVED, REJECTED, CANCELLED |
| `approved_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `approved_at` | TIMESTAMP | No | Approval timestamp |
| `substitution_required` | TINYINT(1) | No (default 1) | 1=needs substitute |
| `substitution_completed` | TINYINT(1) | No (default 0) | 1=substitution assigned |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `teacher_id + absence_date`.

### S10-2: tt_substitution_log

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `teacher_absence_id` | INT UNSIGNED | No | FK to `tt_teacher_absence.id` |
| `cell_id` | INT UNSIGNED | Yes | FK to `tt_timetable_cell.id` |
| `substitution_date` | DATE | Yes | Date of substitution |
| `absent_teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `substitute_teacher_id` | INT UNSIGNED | Yes | FK to `sch_teachers.id` |
| `assignment_method` | ENUM | Yes (default MANUAL) | AUTO, MANUAL, SWAP |
| `reason` | VARCHAR(500) | No | Substitution reason |
| `status` | ENUM | Yes (default ASSIGNED) | ASSIGNED, COMPLETED, CANCELLED |
| `notified_at` | TIMESTAMP | No | When substitute was notified |
| `accepted_at` | TIMESTAMP | No | When substitute accepted |
| `completed_at` | TIMESTAMP | No | When period was completed |
| `feedback` | TEXT | No | Post-substitution feedback |
| `assigned_by` | INT UNSIGNED | No | FK to `sys_users.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_at` | TIMESTAMP | No | Auto-managed |
| `updated_at` | TIMESTAMP | No | Auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### Section 11: Reference Tables (Summarized)

These tables are owned by other modules. Only key fields relevant to the timetable module are listed.

| Table | Key Fields Used by TT |
|-------|----------------------|
| **sch_organizations** | `id`, `code`, `name` -- School identity |
| **sch_org_academic_sessions_jnt** | `id`, `short_name`, `start_date`, `end_date`, `is_current` -- Session scoping |
| **sch_board_organization_jnt** | `id`, `board_id` -- Board association |
| **sch_classes** | `id`, `ordinal`, `code`, `short_name`, `name` -- Class list |
| **sch_sections** | `id`, `ordinal`, `code`, `short_name`, `name` -- Section list |
| **sch_class_section_jnt** | `id`, `class_id`, `section_id`, `code`, `capacity`, `actual_total_student`, `class_teacher_id`, `class_house_room_id`, `total_periods_daily` |
| **sch_subject_types** | `id`, `code`, `short_name` -- MAJOR, MINOR, OPTIONAL, ACTIVITY, SPORTS |
| **sch_study_formats** | `id`, `code`, `short_name` -- LECTURE, LAB, PRACTICAL, TUTORIAL, etc. |
| **sch_subjects** | `id`, `code`, `short_name`, `name` |
| **sch_subject_study_format_jnt** | `id`, `subject_id`, `study_format_id`, `subject_type_id`, `code`, `compulsory_specific_room_type`, `required_room_type_id`, `required_room_id` |
| **sch_class_groups_jnt** | `id`, `class_id`, `section_id`, `subject_study_format_id`, `code`, `is_compulsory`, `required_weekly_periods`, scheduling params, room requirements |
| **sch_subject_groups** | `id`, `class_id`, `section_id`, `code`, `registered_students_count` |
| **sch_subject_group_subject_jnt** | `id`, `subject_group_id`, `class_group_id`, `subject_id` |
| **sch_buildings** | `id`, `code`, `short_name`, `name` |
| **sch_rooms_type** | `id`, `code`, `short_name`, `class_house_room`, `room_count_in_category` |
| **sch_rooms** | `id`, `building_id`, `room_type_id`, `code`, `capacity`, `max_limit`, capability flags, `room_available_from_date` |
| **sch_employees** | `id`, `user_id`, `emp_code`, `is_teacher`, `joining_date`, qualifications JSON |
| **sch_teacher_profile** | `id`, `employee_id`, `is_full_time`, `preferred_shift`, scheduling constraints (max/min periods), `certified_for_lab`, performance fields |
| **sch_teacher_capabilities** | `id`, `teacher_profile_id`, `class_id`, `subject_study_format_id`, `proficiency_percentage`, `competancy_level`, `scarcity_index`, `allocation_strictness`, priority fields |
| **std_students** | `id`, `user_id`, `admission_no`, `first_name`, `gender`, `dob` |
| **std_student_academic_sessions** | `id`, `student_id`, `academic_session_id`, `class_section_id`, `subject_group_id`, `count_for_timetable` |

---

## 4. Data Capturing Flow

The data flow follows a strict sequence organized into 10 phases. Each phase builds on the previous.

### Phase 1: Pre-Requisite Setup (System Admin / School Admin)

```
  STEP 1.1 -- Infrastructure Setup (Other Modules)
  +--------------------------------------------------------------------+
  |  These tables are populated in School Setup module BEFORE           |
  |  the Timetable module can be used:                                 |
  |                                                                    |
  |  > sch_organizations: 1 row (school identity)                     |
  |  > sch_org_academic_sessions_jnt: ~1-3 rows                       |
  |  > sch_classes: ~15-20 rows (BV1, BV2, 1st through 12th)         |
  |  > sch_sections: ~4-6 rows (A, B, C, D)                          |
  |  > sch_class_section_jnt: ~40-80 rows (all class+section combos)  |
  |  > sch_subject_types: ~5 rows (MAJOR, MINOR, OPTIONAL, etc.)     |
  |  > sch_study_formats: ~8 rows (LECTURE, LAB, PRACTICAL, etc.)     |
  |  > sch_subjects: ~15-25 rows (Science, Math, English, etc.)       |
  |  > sch_subject_study_format_jnt: ~30-50 rows                     |
  |  > sch_class_groups_jnt: ~200-400 rows (the demand matrix)        |
  |  > sch_subject_groups + sch_subject_group_subject_jnt             |
  |  > sch_buildings + sch_rooms_type + sch_rooms                     |
  |  > sch_employees + sch_teacher_profile + sch_teacher_capabilities |
  |  > std_students + std_student_academic_sessions                    |
  +--------------------------------------------------------------------+
```

### Phase 2: Timetable Configuration (School Admin)

```
  STEP 2.1 -- Seed Timetable Settings
  +--------------------------------------------------------------------+
  |  > tt_config: Insert ~12-14 config key-value pairs                 |
  |    - total_number_of_period_per_day = 8                            |
  |    - default_school_open_days_per_week = 6                         |
  |    - min/max student for subgroups                                 |
  |    - max/min weekly periods for teacher                            |
  |    - week_start_day = MONDAY                                       |
  +--------------------------------------------------------------------+
          |
          v
  STEP 2.2 -- Define Academic Terms
  +--------------------------------------------------------------------+
  |  > sch_academic_term: Insert ~2-4 rows for the session             |
  |    - TERM-1 (Apr 1 - Sep 30, 5 teaching days/week, 8 periods)    |
  |    - TERM-2 (Oct 1 - Mar 31, 5 teaching days/week, 8 periods)    |
  |    - Set term_total_teaching_periods_per_day,                      |
  |      term_min_resting_periods_per_day,                             |
  |      term_travel_minutes_between_classes                           |
  +--------------------------------------------------------------------+
          |
          v
  STEP 2.3 -- Configure Generation Strategy
  +--------------------------------------------------------------------+
  |  > tt_generation_strategy: Insert ~2-3 strategies                  |
  |    - RECURSIVE_DEFAULT (is_default=1, depth=14, attempts=2000)    |
  |    - GENETIC_LARGE (population=100, generations=500)               |
  |    - HYBRID (for complex schools)                                  |
  +--------------------------------------------------------------------+
```

### Phase 3: Master Data Setup (School Admin)

```
  STEP 3.1 -- Define Shifts, Day Types, Period Types
  +--------------------------------------------------------------------+
  |  > tt_shift: Insert ~2-3 rows                                      |
  |    - MORNING (07:30 - 14:45)                                       |
  |    - AFTERNOON (12:00 - 17:00) -- if applicable                   |
  |                                                                    |
  |  > tt_day_type: Insert ~6-8 rows                                   |
  |    - STUDY (working=1), HOLIDAY (working=0),                       |
  |      EXAM (working=1), PTM_DAY (working=1, reduced=1), etc.       |
  |                                                                    |
  |  > tt_period_type: Insert ~8-10 rows                               |
  |    - TEACHING (schedulable=1, workload=1)                          |
  |    - BREAK (schedulable=0, is_break=1)                             |
  |    - LUNCH (schedulable=0, is_break=1)                             |
  |    - ASSEMBLY (schedulable=0)                                      |
  |    - FREE (schedulable=0, is_free=1)                               |
  |                                                                    |
  |  > tt_teacher_assignment_role: Insert ~5 rows                      |
  |    - PRIMARY (factor=1.00), ASSISTANT (factor=0.50),               |
  |      CO_TEACHER (factor=0.75), SUBSTITUTE, TRAINEE                |
  +--------------------------------------------------------------------+
          |
          v
  STEP 3.2 -- Define School Calendar
  +--------------------------------------------------------------------+
  |  > tt_school_days: Insert 7 rows (Mon-Sun with is_school_day)      |
  |                                                                    |
  |  > tt_working_day: Insert ~180-250 rows                            |
  |    - One row per date in the academic session                      |
  |    - Mark holidays, exam days, special days                        |
  |                                                                    |
  |  > tt_class_working_day_jnt: Insert overrides as needed            |
  |    - Class 10 has exam on Apr 15, Class 5 has normal study         |
  +--------------------------------------------------------------------+
          |
          v
  STEP 3.3 -- Define Period Configuration (v7.7)
  +--------------------------------------------------------------------+
  |  > tt_period_config: Insert ~12-15 rows per shift                  |
  |    - MORNING shift:                                                |
  |      SLOT-01: Assembly    07:30-07:45  (ASSEMBLY)                  |
  |      SLOT-02: Period 1    07:45-08:30  (TEACHING)                  |
  |      SLOT-03: Period 2    08:30-09:15  (TEACHING)                  |
  |      SLOT-04: Short Brk   09:15-09:30  (BREAK)                    |
  |      SLOT-05: Period 3    09:30-10:15  (TEACHING)                  |
  |      SLOT-06: Period 4    10:15-11:00  (TEACHING)                  |
  |      SLOT-07: Lunch       11:00-11:30  (LUNCH)                     |
  |      SLOT-08: Period 5    11:30-12:15  (TEACHING)                  |
  |      SLOT-09: Period 6    12:15-13:00  (TEACHING)                  |
  |      SLOT-10: Short Brk   13:00-13:15  (BREAK)                    |
  |      SLOT-11: Period 7    13:15-14:00  (TEACHING)                  |
  |      SLOT-12: Period 8    14:00-14:45  (TEACHING)                  |
  |                                                                    |
  |  > tt_period_set: Insert ~3-5 sets                                 |
  |    - STANDARD_8P: shift=MORNING, from_ord=1, to_ord=12            |
  |    - TODDLER_6P:  shift=MORNING, from_ord=3, to_ord=11            |
  |    - HALF_DAY_4P: shift=MORNING, from_ord=1, to_ord=7             |
  |                                                                    |
  |  > tt_period_set_period_jnt: Map slots to sets                     |
  |    - STANDARD_8P includes all 12 slots                             |
  |    - TODDLER_6P includes slots 3-11 only                          |
  +--------------------------------------------------------------------+
          |
          v
  STEP 3.4 -- Define Timetable Types & Class Assignments
  +--------------------------------------------------------------------+
  |  > tt_timetable_type: Insert ~3-5 types                            |
  |    - STANDARD (has_teaching=1, has_exam=0)                         |
  |    - UNIT_TEST-1 (has_teaching=1, has_exam=1)                      |
  |    - HALF_YEARLY (has_teaching=0, has_exam=1)                      |
  |                                                                    |
  |  > tt_class_timetable_type_jnt: Assign to each class              |
  |    - Class 10-A: STANDARD + STANDARD_8P                            |
  |    - Class LKG-A: STANDARD + TODDLER_6P                           |
  |    - Class 10-A during exams: UNIT_TEST + STANDARD_8P              |
  +--------------------------------------------------------------------+
```

### Phase 4: Requirement Building (Auto-generated + Admin review)

```
  STEP 4.1 -- Compute Slot Requirements
  +--------------------------------------------------------------------+
  |  > tt_slot_requirement: Auto-generated from class_timetable_type   |
  |    - Class 10-A: 48 total, 40 teaching, 0 exam, 8 free            |
  |    - Class LKG-A: 30 total, 24 teaching, 0 exam, 6 free           |
  +--------------------------------------------------------------------+
          |
          v
  STEP 4.2 -- Build Requirement Groups (Auto-generated from sch_class_groups_jnt)
  +--------------------------------------------------------------------+
  |  > tt_class_requirement_groups: One row per                        |
  |    Class+Section+Subject+StudyFormat combination                   |
  |    - 10th-A Science Lecture Major (student_count=40)               |
  |    - 10th-A Science Lab Major (student_count=40)                   |
  |    - 10th-A Math Lecture Major (student_count=40)                  |
  +--------------------------------------------------------------------+
          |
          v
  STEP 4.3 -- Define Subgroups (Admin, for labs/optionals)
  +--------------------------------------------------------------------+
  |  > tt_class_requirement_subgroups: Split groups into subgroups     |
  |    - 10th-A Science Lab Batch-1 (student_count=20)                 |
  |    - 10th-A Science Lab Batch-2 (student_count=20)                 |
  |    - Set is_shared_across_sections if batches span sections        |
  +--------------------------------------------------------------------+
          |
          v
  STEP 4.4 -- Consolidate Requirements (Admin edits scheduling params)
  +--------------------------------------------------------------------+
  |  > tt_requirement_consolidation: Merged view with EDITABLE params  |
  |    - 10th-A Science Lecture: weekly=5, max_day=2, spread_evenly=1  |
  |    - 10th-A Science Lab: weekly=2, consecutive=2, room=SCI_LAB     |
  |    - Admin adjusts preferred_periods_json, avoid_periods_json      |
  +--------------------------------------------------------------------+
```

### Phase 5: Constraint Setup (School Admin)

```
  STEP 5.1 -- Review Constraint Categories & Scopes (System-defined)
  +--------------------------------------------------------------------+
  |  > tt_constraint_category_scope: Pre-seeded by PRIME               |
  |    - Categories: PERIOD, ROOM, TEACHER, CLASS, SUBJECT, etc.       |
  |    - Scopes: GLOBAL, TEACHER, ROOM, ACTIVITY, CLASS, etc.         |
  |    - Admin can only rename, not add/delete                         |
  +--------------------------------------------------------------------+
          |
          v
  STEP 5.2 -- Review Constraint Types (System-defined)
  +--------------------------------------------------------------------+
  |  > tt_constraint_type: Pre-seeded templates                        |
  |    - TEACHER_NOT_AVAILABLE (category=TEACHER, scope=TEACHER)       |
  |    - MAX_DAILY_PERIODS (category=CLASS, scope=CLASS+SECTION)       |
  |    - MIN_DAYS_BETWEEN (category=SUBJECT, scope=ACTIVITY)           |
  |    - Each has param_schema defining required parameters            |
  +--------------------------------------------------------------------+
          |
          v
  STEP 5.3 -- Create Constraint Instances (Admin)
  +--------------------------------------------------------------------+
  |  > tt_constraint: Admin creates specific rules                     |
  |    - "Mrs. Sharma unavailable Wednesdays" (hard)                   |
  |    - "Physics Lab must be in Period 5-6" (hard)                    |
  |    - "Avoid Math after lunch" (soft, weight=60)                    |
  |    - "Major subjects should be in morning" (soft, weight=80)       |
  |                                                                    |
  |  > tt_teacher_unavailable: Detailed teacher blocks                 |
  |    - Teacher X: Wednesday, Period 3, Weekly recurring               |
  |                                                                    |
  |  > tt_room_unavailable: Detailed room blocks                       |
  |    - Science Lab: Tuesday, all periods, for maintenance             |
  +--------------------------------------------------------------------+
```

### Phase 6: Resource Availability (Auto-generated + Admin review)

```
  STEP 6.1 -- Build Teacher Availability Matrix
  +--------------------------------------------------------------------+
  |  > tt_teacher_availability: One header per teacher per requirement  |
  |    - Pulls skill data from sch_teacher_profile                     |
  |    - Pulls capability data from sch_teacher_capabilities           |
  |    - Calculates availability scores                                |
  |    - Auto-calculates GENERATED columns:                            |
  |      available_for_full_timetable_duration,                        |
  |      no_of_days_not_available                                      |
  |                                                                    |
  |  > tt_teacher_availability_detail: Day x Period grid per teacher   |
  |    - Initial status: Available for all school day+period combos    |
  |    - Marks Unavailable based on tt_teacher_unavailable             |
  |    - Updates to Assigned as generation proceeds                    |
  +--------------------------------------------------------------------+
          |
          v
  STEP 6.2 -- Build Room Availability Matrix
  +--------------------------------------------------------------------+
  |  > tt_room_availability: One header per room                       |
  |    - Pulls room data from sch_rooms                                |
  |    - Sets capability flags based on room type                      |
  |    - Identifies class house rooms                                  |
  |                                                                    |
  |  > tt_room_availability_detail: Day x Period grid per room         |
  |    - Initial status: Available for all school day+period combos    |
  |    - Marks Unavailable based on tt_room_unavailable                |
  |    - Updates to Assigned as generation proceeds                    |
  +--------------------------------------------------------------------+
```

### Phase 7: Activity Preparation (Auto-generated + Admin review)

```
  STEP 7.1 -- Calculate Priority Scores
  +--------------------------------------------------------------------+
  |  > tt_priority_config: Auto-calculated per requirement             |
  |    - teacher_scarcity_index: fewer teachers = higher priority      |
  |    - weekly_load_ratio: more periods needed = higher priority      |
  |    - rigidity_score: fewer valid slots = must place first          |
  |    - resource_scarcity: limited rooms = place early                |
  |    - subject_difficulty_index: hard subjects = morning             |
  +--------------------------------------------------------------------+
          |
          v
  STEP 7.2 -- Create Activities
  +--------------------------------------------------------------------+
  |  > tt_activity: One per schedulable unit                           |
  |    - Auto-created from tt_requirement_consolidation                |
  |    - Inherits scheduling params, room requirements                 |
  |    - Calculates difficulty_score, constraint_count                 |
  |    - GENERATED: total_periods = duration_periods * weekly_periods  |
  |                                                                    |
  |  > tt_sub_activity: For multi-period activities                    |
  |    - Science Lab: 2 sub-activities, consecutive_with_previous=1    |
  +--------------------------------------------------------------------+
          |
          v
  STEP 7.3 -- Calculate Activity Priorities
  +--------------------------------------------------------------------+
  |  > tt_activity_priority: Final priority score per activity         |
  |    - Combines all priority factors into one score (0-100)          |
  |    - priority_reason explains the calculation                      |
  +--------------------------------------------------------------------+
          |
          v
  STEP 7.4 -- Assign Teachers to Activities
  +--------------------------------------------------------------------+
  |  > tt_activity_teacher: Map teachers to activities                 |
  |    - Auto-assigned from tt_teacher_availability rankings           |
  |    - Admin can override assignments                                |
  |    - Set assignment_role (PRIMARY, ASSISTANT, etc.)                 |
  |    - is_required=1 for mandatory teachers                          |
  +--------------------------------------------------------------------+
```

### Phase 8: Timetable Generation (Admin triggers, algorithm executes)

```
  STEP 8.1 -- Create Timetable Container
  +--------------------------------------------------------------------+
  |  > tt_timetable: Create in DRAFT status                            |
  |    - Link: academic_session, term, type, period_set, strategy      |
  |    - Set effective_from, effective_to                               |
  |    - generation_method = FULL_AUTO / SEMI_AUTO / MANUAL            |
  |    - version = 1 (or increment from parent)                        |
  +--------------------------------------------------------------------+
          |
          v
  STEP 8.2 -- Execute Generation Run
  +--------------------------------------------------------------------+
  |  Admin clicks "Generate" --> Status changes to GENERATING          |
  |                                                                    |
  |  > tt_generation_run: Create QUEUED entry                          |
  |    - status: QUEUED --> RUNNING                                    |
  |                                                                    |
  |  Algorithm proceeds:                                               |
  |    1. Sort activities by priority (difficulty_score DESC)          |
  |    2. For each activity in priority order:                         |
  |       a. Find valid day+period slots (respecting constraints)      |
  |       b. Check teacher availability                                |
  |       c. Check room availability                                   |
  |       d. Place activity in best slot                               |
  |       e. WRITE to tt_timetable_cell                                |
  |       f. WRITE to tt_timetable_cell_teacher                        |
  |       g. UPDATE tt_teacher_availability_detail (Assigned)          |
  |       h. UPDATE tt_room_availability_detail (Assigned)             |
  |       i. WRITE to tt_resource_booking                              |
  |       j. CHECK constraints, log violations                         |
  |    3. If backtracking needed (RECURSIVE):                          |
  |       - Undo last placement, try next option                       |
  |       - Respect max_recursion_depth                                |
  |                                                                    |
  |  > tt_constraint_violation: Log all violations                     |
  |  > tt_conflict_detection: Log detection events                     |
  |                                                                    |
  |  > tt_generation_run: Update status                                |
  |    - COMPLETED (activities_placed, soft_score)                     |
  |    - FAILED (error_message)                                        |
  |                                                                    |
  |  > tt_timetable: status --> GENERATED                              |
  |    - Set quality_score, teacher_satisfaction_score,                 |
  |      room_utilization_score, soft_score                            |
  +--------------------------------------------------------------------+
```

### Phase 9: Refinement & Publication (Admin / Principal)

```
  STEP 9.1 -- Review & Manual Refinement
  +--------------------------------------------------------------------+
  |  > Admin reviews generated timetable in UI                         |
  |    - View by: Teacher / Class / Room / Subject / Day               |
  |  > Manual adjustments:                                             |
  |    - SWAP two cells (source=SWAP)                                  |
  |    - MANUAL placement (source=MANUAL)                              |
  |    - LOCK cells to prevent algorithm changes (is_locked=1)         |
  |  > tt_timetable_cell: Updated per change                          |
  |  > tt_change_log: Every change recorded                            |
  |  > tt_conflict_detection: Real-time check on each edit             |
  |                                                                    |
  |  > If major issues: Re-run generation (back to Step 8.2)          |
  |    - New run_number, locked cells preserved                        |
  +--------------------------------------------------------------------+
          |
          v
  STEP 9.2 -- Calculate Workload Reports
  +--------------------------------------------------------------------+
  |  > tt_teacher_workload: Auto-calculated from timetable_cell        |
  |    - weekly_periods_assigned, utilization_percent                   |
  |    - gap_periods_total, consecutive_max                            |
  |    - daily_distribution_json, subjects/classes JSON                 |
  +--------------------------------------------------------------------+
          |
          v
  STEP 9.3 -- Publish
  +--------------------------------------------------------------------+
  |  > Admin publishes the timetable                                   |
  |  > tt_timetable: status --> PUBLISHED                              |
  |    - published_at, published_by recorded                           |
  |  > Timetable becomes visible to teachers, students, parents        |
  |  > tt_change_log: LOCK action logged                               |
  +--------------------------------------------------------------------+
```

### Phase 10: Ongoing Operations (Substitution)

```
  STEP 10.1 -- Record Teacher Absence
  +--------------------------------------------------------------------+
  |  > tt_teacher_absence: Teacher/Admin reports absence               |
  |    - teacher_id, absence_date, absence_type, reason                |
  |    - status: PENDING --> APPROVED (by admin)                       |
  |    - substitution_required = 1                                     |
  +--------------------------------------------------------------------+
          |
          v
  STEP 10.2 -- Assign Substitute
  +--------------------------------------------------------------------+
  |  > System identifies affected tt_timetable_cell rows               |
  |  > Finds available substitute teachers (from availability detail)  |
  |                                                                    |
  |  > tt_substitution_log: Create assignment                          |
  |    - absent_teacher_id, substitute_teacher_id                      |
  |    - assignment_method: AUTO (system suggests) or MANUAL (admin)   |
  |    - status: ASSIGNED                                              |
  |    - notified_at: when notification sent                           |
  |                                                                    |
  |  > tt_timetable_cell_teacher: Add substitute row                   |
  |    - is_substitute = 1                                             |
  |                                                                    |
  |  > tt_change_log: SUBSTITUTE action logged                         |
  |  > tt_teacher_absence: substitution_completed = 1                  |
  +--------------------------------------------------------------------+
          |
          v
  STEP 10.3 -- Complete & Feedback
  +--------------------------------------------------------------------+
  |  > After period ends:                                              |
  |  > tt_substitution_log: status --> COMPLETED                       |
  |    - completed_at, feedback recorded                               |
  |  > tt_resource_booking: status --> COMPLETED                       |
  +--------------------------------------------------------------------+
```

### Complete Timetable Lifecycle State Machine

```
                +----------+
                |   DRAFT  |  (Container created, parameters set)
                +-----+----+
                      | Admin clicks "Generate"
                      v
                +------------+
                | GENERATING |  (Algorithm running)
                +-----+------+
                      | Algorithm completes
                      v
                +------------+
         +------| GENERATED  |<--------------+
         |      +-----+------+               |
         |            | Admin refines        | Manual refinement
         |            | & approves           | or re-generation
         |            v                      |
         |      +------------+               |
         |      | GENERATED  |---------------+
         |      | (refined)  |
         |      +-----+------+
         |            | Admin publishes
         |            v
         |      +------------+
         |      | PUBLISHED  |  (Visible to all users)
         |      +-----+------+
         |            | Superseded by new version
         |            v
         |      +------------+
         |      |  ARCHIVED  |  (Historical, read-only)
         |      +------------+
         |
         +---> Parent for next version (parent_timetable_id)
```

---

## 5. Important Design Details

### 5.1 Key Design Decisions

| Decision ID | Rule | Rationale |
|-------------|------|-----------|
| D-TT-001 | No `tenant_id` column in any table | stancl/tenancy v3.9 uses database-per-tenant. Each tenant has its own database, so tenant_id is implicit. |
| D-TT-002 | Uses ENUMs for fixed, small-cardinality fields | Unlike the MSG module which avoids ENUMs entirely, the TT module uses ENUMs for algorithm_type, status fields, absence_type, etc. These are values that change extremely rarely and benefit from database-level validation. |
| D-TT-003 | Separate tt_period_config from tt_period_set | Schools have ONE timing grid per shift but different classes use different subsets of that grid. Centralizing timings in tt_period_config and referencing via ordinal ranges in tt_period_set prevents timing inconsistencies. |
| D-TT-004 | Three-layer requirement model (groups -> subgroups -> consolidation) | Groups capture the full demand matrix from sch_class_groups_jnt. Subgroups enable splitting for labs/optionals. Consolidation provides the editable merge point. This separation keeps auto-generated data clean while giving admins control over scheduling parameters. |
| D-TT-005 | Constraint engine uses Category+Scope+Type+Instance pattern | Categories and scopes are system-defined (extensible without code changes). Types are templates with JSON param_schema. Instances carry actual parameters. This 4-layer pattern makes the constraint system fully generic and extensible. |
| D-TT-006 | Activity as the atomic scheduling unit | An activity is the smallest unit the algorithm places on the grid. It encapsulates class+section+subject+study_format+scheduling_params+room_requirements. Sub-activities handle multi-period blocks. This clean abstraction simplifies the generation algorithm. |
| D-TT-007 | Timetable versioning via parent_timetable_id | Instead of modifying a published timetable, the school creates a new version. The parent link creates an auditable lineage. Old versions are ARCHIVED, not deleted. |
| D-TT-008 | Cell-teacher separation (tt_timetable_cell_teacher) | A single cell (day+period+class) can have multiple teachers (team teaching, co-teaching, substitute alongside primary). Normalizing this into a separate table avoids fixed-width multi-teacher columns. |

### 5.2 v7.7 Period Config Enhancement

The centralized timeslot design was introduced in v7.7 to solve a real problem: before v7.7, each period set stored its own start_time/end_time, which allowed inconsistencies (Period 3 could be 09:30-10:15 for one class group but 09:45-10:30 for another, even though the school bell rings at the same time for everyone).

```
  BEFORE v7.7:
  +---------------------+     +---------------------------+
  | tt_period_set       |     | tt_period_set_period_jnt  |
  |---------------------|     |---------------------------|
  | day_start_time      |     | start_time    <-- REMOVED |
  | day_end_time        |     | end_time      <-- REMOVED |
  +---------------------+     | duration_min  <-- REMOVED |
                              +---------------------------+

  AFTER v7.7:
  +------------------+     +---------------------+     +---------------------------+
  | tt_period_config |     | tt_period_set       |     | tt_period_set_period_jnt  |
  |  (NEW)           |<----| shift_id    (NEW)   |     | period_config_id  (NEW)   |
  |  shift_id        |     | from_period_ord(NEW)|     | Timing INHERITED from     |
  |  slot_ord        |     | to_period_ord (NEW) |     | tt_period_config          |
  |  start_time      |     +---------------------+     +---------------------------+
  |  end_time         |
  |  duration (GEN)  |
  +------------------+

  How it works:
  1. tt_period_config defines 12 slots for MORNING shift with fixed timings
  2. tt_period_set STANDARD_8P says "use slots 1-12"
  3. tt_period_set TODDLER_6P says "use slots 3-11"
  4. tt_period_set_period_jnt maps which config slots are in each set
  5. Period 3 is ALWAYS 09:30-10:15 regardless of which class uses it
```

### 5.3 Constraint Engine Architecture

The constraint engine follows a 4-layer pattern:

```
  Layer 1: CATEGORY + SCOPE (tt_constraint_category_scope)
  +----------------------------------------------------------+
  | What?              | Where?                               |
  | PERIOD             | GLOBAL                               |
  | ROOM               | TEACHER (specific teacher)           |
  | TEACHER            | ROOM (specific room)                 |
  | CLASS              | ACTIVITY (specific activity)         |
  | CLASS+SECTION      | CLASS (all activities for a class)   |
  | SUBJECT            | CLASS+SECTION                        |
  | STUDY_FORMAT       | CLASS+SUBJECT+STUDY_FORMAT           |
  | SUBJECT_TYPE       | CLASS_GROUP                          |
  | ACTIVITY           | CLASS_SUBGROUP                       |
  +----------------------------------------------------------+

  Layer 2: TYPE (tt_constraint_type) -- The template
  +----------------------------------------------------------+
  | code                    | category  | scope     | schema  |
  | TEACHER_NOT_AVAILABLE   | TEACHER   | TEACHER   | {...}   |
  | MAX_DAILY_PERIODS       | CLASS     | CLASS+SEC | {...}   |
  | MIN_DAYS_BETWEEN        | SUBJECT   | ACTIVITY  | {...}   |
  | SAME_STARTING_TIME      | CLASS     | GLOBAL    | {...}   |
  | ROOM_CAPACITY_LIMIT     | ROOM      | ROOM      | {...}   |
  +----------------------------------------------------------+

  Layer 3: INSTANCE (tt_constraint) -- The applied rule
  +----------------------------------------------------------+
  | type                  | target          | params          |
  | TEACHER_NOT_AVAILABLE | Teacher Sharma  | {day: "Wed",    |
  |                       |                 |  period: 3}     |
  | MAX_DAILY_PERIODS     | Class 10-A      | {max: 2,        |
  |                       |                 |  subject: "SCI"}|
  +----------------------------------------------------------+

  Layer 4: SPECIALIZED (tt_teacher_unavailable, tt_room_unavailable)
  +----------------------------------------------------------+
  | Detailed per-slot unavailability with recurring rules     |
  | Linked to Layer 3 via constraint_id FK                    |
  +----------------------------------------------------------+
```

### 5.4 Activity Model

```
  tt_requirement_consolidation (the demand)
          |
          v
  tt_activity (the schedulable unit)
  +----------------------------------------------------------+
  | One activity = one Class+Section+Subject+StudyFormat      |
  |                                                           |
  | Key attributes:                                           |
  |   required_weekly_periods = 5 (how many slots per week)   |
  |   duration_periods = 1 (normal) or 2 (lab)               |
  |   weekly_periods = 5 (times per week)                     |
  |   total_periods = 5 (GENERATED: 1 * 5)                   |
  |                                                           |
  | For a 2-period lab scheduled 2x per week:                 |
  |   duration_periods = 2                                    |
  |   weekly_periods = 2                                      |
  |   total_periods = 4 (GENERATED: 2 * 2)                   |
  +----------------------------------------------------------+
          |
          +---> tt_sub_activity (for multi-period blocks)
          |     [Lab Period 1] same_day=1, consecutive=0
          |     [Lab Period 2] same_day=1, consecutive=1
          |
          +---> tt_activity_teacher (who can teach it)
          |     [Mrs. Sharma] role=PRIMARY, is_required=1
          |     [Mr. Gupta]   role=ASSISTANT, is_required=0
          |
          +---> tt_activity_priority (scheduling order)
                [score=87.50] "Physics Lab: high scarcity, limited rooms"
```

### 5.5 Generation Strategy Options

| Strategy | Best For | Key Parameters |
|----------|----------|---------------|
| RECURSIVE | Small schools (<500 students, <200 activities) | `max_recursive_depth=14`, `max_placement_attempts=2000` |
| GENETIC | Large schools with many soft constraints | `population_size=50`, `generations=100` |
| SIMULATED_ANNEALING | Schools needing gradual optimization | `cooling_rate=0.95` |
| TABU_SEARCH | Schools with many hard constraints | `tabu_size=100` |
| HYBRID | Complex schools (multiple shifts, many exceptions) | Combines multiple algorithms |

Activity sorting methods determine placement order:
- **LESS_TEACHER_FIRST**: Activities with fewer available teachers go first (scarce resources first)
- **DIFFICULTY_FIRST**: Highest difficulty_score first
- **CONSTRAINT_COUNT**: Most constrained activities first
- **DURATION_FIRST**: Multi-period activities first (harder to fit)
- **RANDOM**: Random order (for genetic algorithm diversity)

### 5.6 Timetable Lifecycle

```
  DRAFT          -- Container created, parameters configured
       |
  GENERATING     -- Algorithm running (tt_generation_run in RUNNING status)
       |
  GENERATED      -- Algorithm completed, timetable populated
       |         -- Manual refinement happens here (SWAP, MANUAL, LOCK)
       |         -- Can re-generate (new run_number, locked cells preserved)
       |
  PUBLISHED      -- Visible to teachers, students, parents
       |         -- published_at, published_by recorded
       |
  ARCHIVED       -- Superseded by new version
                 -- parent_timetable_id links to successor
                 -- Read-only, preserved for audit
```

### 5.7 Resource Booking Model

`tt_resource_booking` is the universal resource occupancy ledger:

```
  Resource Types:     ROOM | LAB | TEACHER | EQUIPMENT | SPORTS | SPECIAL
  Booking Types:      ACTIVITY | EXAM | EVENT | MAINTENANCE
  Status Lifecycle:   BOOKED --> IN_USE --> COMPLETED | CANCELLED

  Query: "Is Science Lab available Tuesday Period 5?"
  --> SELECT * FROM tt_resource_booking
      WHERE resource_type = 'LAB'
        AND resource_id = 42
        AND booking_date = '2025-07-15'
        AND period_ord = 5
        AND status IN ('BOOKED', 'IN_USE')
```

### 5.8 Teacher Availability Scoring Formulas

```
  Teacher Availability Ratio (TAR):
  TAR = (Total weekly assigned Periods / Total weekly available Periods) * 100

  Example: Teacher can take 36 periods/week, assigned 8 subjects across classes
  TAR = (8 / 36) * 100 = 22.22%

  Last Allocation Score (used for ranking):
  last_allocation_score = (proficiency_percentage * 0.4)
                        + (load_balance * 0.3)
                        + (strictness_match * 0.2)
                        + (historical_success_ratio * 0.1)

  Generated Columns:
  available_for_full_timetable_duration =
    IF(teacher_available_from_date <= timetable_start_date, 1, 0)

  no_of_days_not_available =
    GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))
```

### 5.9 Volume Estimates

For a typical school with 40 classes (15 class levels x ~3 sections), 20 subjects, 60 teachers, 6 working days, 8 periods/day:

| Table | Formula | Estimated Rows |
|-------|---------|----------------|
| tt_period_config | 12 slots x 1 shift | ~12 |
| tt_period_set | ~3-5 sets | ~4 |
| tt_period_set_period_jnt | 12 x 4 sets | ~48 |
| tt_school_days | 7 days | 7 |
| tt_working_day | ~240 dates/session | ~240 |
| tt_class_working_day_jnt | 40 classes x ~10 overrides | ~400 |
| tt_class_requirement_groups | 40 classes x 8 subjects x 1.2 formats | ~380 |
| tt_requirement_consolidation | ~380 (mirrors groups + subgroups) | ~400 |
| tt_teacher_availability | 60 teachers x ~6 subjects each | ~360 |
| tt_teacher_availability_detail | 360 x 6 days x 8 periods | ~17,280 |
| tt_room_availability | ~50 rooms | ~50 |
| tt_room_availability_detail | 50 x 6 days x 8 periods | ~2,400 |
| tt_activity | ~400 activities | ~400 |
| tt_activity_teacher | 400 x ~1.5 teachers/activity | ~600 |
| tt_timetable_cell | 40 classes x 6 days x 8 periods | ~1,920 |
| tt_timetable_cell_teacher | ~1,920 x 1.1 teachers/cell | ~2,112 |
| tt_constraint | ~50-200 rules | ~100 |
| tt_teacher_workload | 60 teachers x 1 timetable | ~60 |
| **Total per timetable version** | | **~26,000** |

### 5.10 Indexing Strategy

Key indexes designed for common query patterns:

| Query Pattern | Index Used |
|---------------|-----------|
| "Show timetable for Class 10-A" | `uq_cell_tt_day_period_group` (timetable_id, day, period, class_group) |
| "Show all classes for Teacher X on Monday" | `idx_cct_teacher` (teacher_id) + join to cell |
| "Find available slots for an activity" | `idx_cell_day_period` (day_of_week, period_ord) |
| "List all activities by difficulty" | `idx_activity_difficulty` (difficulty_score, constraint_count) |
| "Find activities for generation" | `idx_activity_generation` (term, difficulty, status, is_active) |
| "Check teacher availability grid" | `uq_ta_class_wise` (teacher, day, period) |
| "Check room availability" | `uq_ra_class_wise` (room, type, class, section, etc.) |
| "List constraint violations" | `idx_cv_timetable` (timetable_id) |
| "Find generation runs for a timetable" | `uq_gr_tt_run` (timetable_id, run_number) |
| "Substitution history for a date" | `idx_sub_date` (substitution_date) |
| "Change log for a timetable" | `idx_cl_timetable` (timetable_id) + `idx_cl_date` (change_date) |
| "Period config for a shift" | `uq_pc_shift_ord` (shift_id, slot_ord) |
| "Teaching slots for quick filter" | `idx_pc_teaching` (shift_id, is_teaching_slot) |

### 5.11 Naming Conventions

| Convention | Example | Meaning |
|------------|---------|---------|
| `tt_` prefix | `tt_timetable_cell` | Table belongs to SmartTimetable module |
| `sch_` prefix | `sch_classes` | Table belongs to School Setup module (reference) |
| `std_` prefix | `std_students` | Table belongs to Student module (reference) |
| `_jnt` suffix | `tt_period_set_period_jnt` | Junction table (many-to-many relationship) |
| `uq_` prefix | `uq_pc_shift_ord` | Unique key constraint |
| `fk_` prefix | `fk_pc_shift` | Foreign key constraint |
| `idx_` prefix | `idx_pc_teaching` | Index (non-unique) |
| `chk_` prefix | `chk_pc_time` | CHECK constraint |
| `_ord` suffix | `slot_ord`, `period_ord` | Ordinal/sequence number field |
| `_json` suffix | `params_json`, `stats_json` | JSON-typed field |
| `_id` suffix | `shift_id`, `teacher_id` | Foreign key reference field |

### 5.12 Soft Delete Strategy

- All tt_* module tables have a `deleted_at` column for Laravel SoftDeletes
- `tt_constraint_violation` and `tt_conflict_detection` do NOT have `deleted_at` -- they are operational logs
- Reference tables (sch_*, std_*) have their own soft delete policies managed by their owning modules
- IMPORTANT: Unique constraints interact with soft deletes. A soft-deleted record still occupies the unique key slot in MySQL. The application must use `whereNull('deleted_at')` scoping or consider composite unique indexes that include `deleted_at`

### 5.13 GENERATED (Stored) Columns

Several tables use MySQL GENERATED ALWAYS AS ... STORED columns to auto-calculate values:

| Table | Column | Formula |
|-------|--------|---------|
| `sch_academic_term` | `current_flag` | `CASE WHEN is_current=1 THEN 1 ELSE NULL END` |
| `tt_period_config` | `duration_minutes` | `TIMESTAMPDIFF(MINUTE, start_time, end_time)` |
| `tt_activity` | `total_periods` | `duration_periods * weekly_periods` |
| `tt_teacher_availability` | `available_for_full_timetable_duration` | `IF(teacher_available_from_date <= timetable_start_date, 1, 0)` |
| `tt_teacher_availability` | `no_of_days_not_available` | `GREATEST(0, DATEDIFF(teacher_available_from_date, timetable_start_date))` |
| `sch_teacher_capabilities` | `active_flag` | `CASE WHEN is_active=1 THEN 1 ELSE NULL END` |

These columns are STORED (not VIRTUAL), meaning they are persisted on disk and can be indexed.

---

## 6. Seeder Data Reference

### tt_config (~12-14 rows, seeded at module activation)

| ordinal | key | value | value_type |
|---------|-----|-------|------------|
| 1 | total_number_of_period_per_day | 8 | NUMBER |
| 2 | default_school_open_days_per_week | 6 | NUMBER |
| 3 | default_school_closed_days_per_week | 1 | NUMBER |
| 4 | default_number_of_short_breaks_daily_before_lunch | 1 | NUMBER |
| 5 | default_number_of_short_breaks_daily_after_lunch | 1 | NUMBER |
| 6 | default_total_number_of_short_breaks_daily | 2 | NUMBER |
| 7 | default_total_number_of_period_before_lunch | 4 | NUMBER |
| 8 | default_total_number_of_period_after_lunch | 4 | NUMBER |
| 9 | minimum_student_required_for_class_subgroup | 10 | NUMBER |
| 10 | maximum_student_required_for_class_subgroup | 25 | NUMBER |
| 11 | max_weekly_periods_can_be_allocated_to_teacher | 8 | NUMBER |
| 12 | min_weekly_periods_can_be_allocated_to_teacher | 8 | NUMBER |
| 13 | week-start_day | MONDAY | STRING |

### tt_shift (~3-4 rows)

| code | name | default_start_time | default_end_time |
|------|------|--------------------|------------------|
| MORNING | Morning Shift | 07:30 | 14:45 |
| TODLER | Toddler Shift | 08:00 | 12:00 |
| AFTERNOON | Afternoon Shift | 12:00 | 17:00 |
| EVENING | Evening Shift | 14:00 | 19:00 |

### tt_day_type (~6-8 rows)

| code | name | is_working_day | reduced_periods |
|------|------|----------------|-----------------|
| STUDY | Study Day | 1 | 0 |
| HOLIDAY | Holiday | 0 | 0 |
| EXAM | Exam Day | 1 | 0 |
| SPECIAL | Special Day | 1 | 1 |
| PTM_DAY | Parent Teacher Meeting | 1 | 1 |
| SPORTS_DAY | Sports Day | 1 | 1 |
| ANNUAL_DAY | Annual Day | 1 | 1 |

### tt_period_type (~8-10 rows)

| code | name | is_schedulable | counts_as_teaching | is_break |
|------|------|---------------|-------------------|----------|
| TEACHING | Teaching Period | 1 | 1 | 0 |
| THEORY | Theory Period | 1 | 1 | 0 |
| PRACTICAL | Practical Period | 1 | 1 | 0 |
| BREAK | Short Break | 0 | 0 | 1 |
| LUNCH | Lunch Break | 0 | 0 | 1 |
| ASSEMBLY | Assembly | 0 | 0 | 0 |
| EXAM | Exam Period | 1 | 0 | 0 |
| RECESS | Recess | 0 | 0 | 1 |
| FREE | Free Period | 0 | 0 | 0 |

### tt_teacher_assignment_role (~5 rows)

| code | name | is_primary_instructor | workload_factor |
|------|------|-----------------------|-----------------|
| PRIMARY | Primary Teacher | 1 | 1.00 |
| ASSISTANT | Assistant Teacher | 0 | 0.50 |
| CO_TEACHER | Co-Teacher | 0 | 0.75 |
| SUBSTITUTE | Substitute Teacher | 0 | 1.00 |
| TRAINEE | Trainee Teacher | 0 | 0.25 |

### tt_constraint_category_scope (seeded by PRIME)

**Categories:**

| type | code | name |
|------|------|------|
| CATEGORY | PERIOD | Period |
| CATEGORY | ROOM | Room |
| CATEGORY | TEACHER | Teacher |
| CATEGORY | CLASS | Class |
| CATEGORY | CLASS_SECTION | Class + Section |
| CATEGORY | SUBJECT | Subject |
| CATEGORY | STUDY_FORMAT | Study Format |
| CATEGORY | SUBJECT_STUDY_FORMAT | Subject Study Format |
| CATEGORY | SUBJECT_TYPE | Subject Type |
| CATEGORY | ACTIVITY | Activity |

**Scopes:**

| type | code | name |
|------|------|------|
| SCOPE | GLOBAL | Global |
| SCOPE | TEACHER | Teacher |
| SCOPE | ROOM | Room |
| SCOPE | ACTIVITY | Activity |
| SCOPE | CLASS | Class |
| SCOPE | CLASS_SECTION | Class + Section |
| SCOPE | CLASS_SUBJECT_STUDY_FORMAT | Class + Subject + Study Format |
| SCOPE | SUBJECT_STUDY_FORMAT | Subject + Study Format |
| SCOPE | SUBJECT | Subject |
| SCOPE | CLASS_GROUP | Class Group |
| SCOPE | CLASS_SUBGROUP | Class Subgroup |

### tt_generation_strategy (~2-3 rows)

| code | algorithm_type | max_recursive_depth | timeout_seconds | activity_sorting_method |
|------|---------------|--------------------|-----------------|-----------------------|
| RECURSIVE_DEFAULT | RECURSIVE | 14 | 300 | LESS_TEACHER_FIRST |
| GENETIC_LARGE | GENETIC | - | 600 | DIFFICULTY_FIRST |
| HYBRID_COMPLEX | HYBRID | 10 | 900 | CONSTRAINT_COUNT |
