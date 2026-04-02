# PRIME-AI TIMETABLE MODULE — COMPLETE PROCESS FLOW v1.0
════════════════════════════════════════════════════════════
Module: TimetableFoundation + SmartTimetable
Routes: /timetable-foundation/* + /smart-timetable/*
Tables: tt_* (~45 tables) + sch_* (shared with SchoolSetup)
Date: 2026-03-31

## Overview — Two Modules, One Pipeline

TimetableFoundation owns: config, master data, period sets, calendar, activities, slot requirements, resource availability
SmartTimetable owns: constraint engine, parallel groups, generation strategy, FET solver, refinement, substitution, analytics, approval

Both modules share: tt_timetables, tt_timetable_cells, tt_timetable_cell_teachers, tt_school_days, tt_activities, tt_activity_teachers

Flow: Foundation Setup → Requirement Generation → Constraint Setup → Generation (Smart or Manual) → Post-Processing → Refinement → Publication


═══════════════════════════════════════════════════════════════════════════════
## PHASE 0: SYSTEM PREREQUISITES SETUP (One-Time, TimetableFoundation)
═══════════════════════════════════════════════════════════════════════════════
Route: timetable-foundation/pre-requisites-setup
Controller: TimetableFoundationController::preRequisitesSetup()
Menu tab: Pre-Requisites Setup

### 0.1 Timetable System Configuration (tt_config)
    ├── Access via TimetableFoundationController::timetableConfiguration()
    ├── ConfigController::index() loads all config keys
    ├── Config table: tt_config
    │   ├── key (unique identifier, e.g. 'max_periods_per_teacher')
    │   ├── value (current value)
    │   ├── value_type (integer/string/boolean/json)
    │   ├── tenant_can_modify (boolean — which settings school can change)
    │   └── mandatory (boolean — system blocks generation if NULL)
    ├── Critical config keys for generation:
    │   ├── max_periods_per_teacher_per_day
    │   ├── min_periods_per_teacher_per_week
    │   ├── max_periods_per_teacher_per_week
    │   ├── allow_teacher_overlap (boolean)
    │   └── allow_room_double_booking (boolean)
    ├── User action: Review and update values via ConfigController::edit() + update()
    └── Soft-delete supported → ConfigController::trashed() / restore() / forceDelete()

### 0.2 School Shift Definition (tt_shifts)
    ├── SchoolShiftController::index() + create() + store()
    ├── Table: tt_shifts
    │   ├── name (Morning / Afternoon / Evening)
    │   ├── ordinal (unique — enforced via migration 2026_03_28)
    │   ├── start_time, end_time
    │   └── is_active
    ├── Unique ordinal constraint added via migration 2026_03_28_100000
    ├── Required before creating Period Sets and Timetable Types
    └── Soft-delete supported

### 0.3 Day Type Definition (tt_day_types)
    ├── DayTypeController::index() + create() + store()
    ├── Table: tt_day_types
    │   ├── code (STUDY_DAY / EXAM_DAY / HOLIDAY / PTM_DAY / SPORTS_DAY)
    │   ├── name, color_code
    │   ├── is_working (boolean — affects period scheduling)
    │   └── is_active
    ├── Day types assigned to individual working days in Phase 1.4
    └── Soft-delete supported

### 0.4 Period Type Definition (tt_period_types)
    ├── PeriodTypeController::index() + create() + store()
    ├── Table: tt_period_types
    │   ├── code (TEACHING / BREAK / LUNCH / ASSEMBLY / EXAM / FREE / LAB)
    │   ├── name, color_code
    │   ├── counts_as_workload (boolean)
    │   └── is_active
    ├── Each period in a Period Set is assigned one period_type_id
    └── Soft-delete supported

### 0.5 Teacher Assignment Role Definition (tt_teacher_assignment_roles)
    ├── TeacherAssignmentRoleController::index() + create() + store()
    ├── Table: tt_teacher_assignment_roles
    │   ├── code (PRIMARY / ASSISTANT / CO_TEACHER / SUBSTITUTE)
    │   ├── name
    │   ├── workload_factor (float — e.g. 1.0 for primary, 0.5 for assistant)
    │   ├── is_primary (boolean)
    │   └── is_active
    ├── Used when mapping teachers to activities (tt_activity_teachers)
    └── Used again in cell-teacher mapping (tt_timetable_cell_teachers)

### 0.6 SchoolSetup Master Data Verification (sch_* tables)
    ├── TimetableFoundation DEPENDS on these SchoolSetup entities:
    │   ├── sch_buildings → rooms grouped by building
    │   ├── sch_room_types → room classification (Classroom / Lab / Hall)
    │   ├── sch_rooms → individual rooms (capacity, room_type_id, building_id)
    │   ├── sch_classes → class definitions (ordinal, name, code)
    │   ├── sch_sections → section definitions (code A/B/C)
    │   ├── sch_class_section_jnt → valid class+section pairs with class_house_room_id
    │   ├── sch_subjects → subject definitions with difficulty_index
    │   ├── sch_study_formats → LECTURE / LAB / PRACTICAL / ACTIVITY
    │   ├── sch_subject_study_format_jnt → subject × study_format (with duration)
    │   ├── sch_class_groups_jnt → subject groups per class (is_compulsory flag)
    │   ├── sch_employees → staff records
    │   └── sch_teachers_profile → teacher profiles with max/min periods
    ├── User must verify all sch_* data before generating timetable
    └── No TimetableFoundation controller manages sch_* — handled by SchoolSetup module


═══════════════════════════════════════════════════════════════════════════════
## PHASE 1: ACADEMIC TERM & TIMETABLE STRUCTURE SETUP (TimetableFoundation)
═══════════════════════════════════════════════════════════════════════════════
Route: timetable-foundation/timetable-configuration
Controller: TimetableFoundationController::timetableConfiguration()
Menu tab: Timetable Configuration

### 1.1 Academic Term Setup (sch_academic_term)
    ├── AcademicTermController::index() + create() + store()
    ├── Table: sch_academic_term (SchoolSetup module table — shared)
    │   ├── term_name (e.g. "Term 1 2025-26")
    │   ├── academic_session_id (FK → sch_academic_sessions)
    │   ├── term_start_date, term_end_date
    │   ├── total_teaching_days (calculated)
    │   ├── is_current (boolean — unique per session)
    │   └── is_active
    ├── Business rules enforced:
    │   ├── term_start_date < term_end_date
    │   ├── Only one is_current=1 per academic_session_id
    │   └── No overlapping date ranges within same session
    ├── academic_term_id is a foreign key across all timetable tables
    ├── Resolve current term: AcademicTerm::where('is_current', true)->firstOrFail()
    └── Soft-delete supported

### 1.2 Timetable Type Definition (tt_timetable_types)
    ├── TimetableTypeController::index() + create() + store()
    ├── Table: tt_timetable_types
    │   ├── code (STANDARD / EXAM / HALF_DAY / UNIT_TEST)
    │   ├── name
    │   ├── is_default (boolean — one default per system)
    │   └── is_active
    ├── Each timetable generated is associated with one timetable_type_id
    ├── Used as filter throughout generation pipeline
    └── Soft-delete supported

### 1.3 Period Set Definition (tt_period_sets + tt_period_set_period_jnt)
    ├── PeriodSetController::index() + create() + store()
    │   ├── Table: tt_period_sets
    │   │   ├── name (e.g. 'STANDARD_8P', 'TODDLER_6P')
    │   │   ├── shift_id (FK → tt_shifts)
    │   │   ├── total_periods (calculated from jnt table)
    │   │   ├── is_default (boolean)
    │   │   └── is_active
    │   └── Soft-delete supported
    ├── PeriodSetPeriodController::index() + create() + store()
    │   ├── Table: tt_period_set_period_jnt
    │   │   ├── period_set_id (FK → tt_period_sets)
    │   │   ├── period_ord (1..n, unique per set — ordering column)
    │   │   ├── code (e.g. P1, P2, SBREAK, LUNCH)
    │   │   ├── period_type_id (FK → tt_period_types)
    │   │   ├── start_time, end_time
    │   │   ├── duration_minutes (calculated)
    │   │   └── is_active
    │   ├── period_ord is the key column used in tt_timetable_cells
    │   └── addPeriodToOrganization() → bulk-adds standard period sets
    ├── CRITICAL: Each class-section is mapped to exactly one period_set_id
    ├── CRITICAL: Generator filters periods by period_set_id — never load all period sets
    └── Multiple period sets supported (e.g. Grades 1-5 = 5 periods, Grades 6-12 = 8 periods)

### 1.4 School Days Configuration (tt_school_days)
    ├── SchoolDayController::index() + create() + store()
    ├── Table: tt_school_days
    │   ├── name (Monday / Tuesday / ... / Sunday)
    │   ├── short_name (Mon / Tue / ...)
    │   ├── day_of_week (1=Monday .. 7=Sunday ISO)
    │   ├── is_school_day (boolean — marks working weekdays)
    │   ├── ordinal (for display ordering)
    │   └── is_active
    ├── Scopes available on SchoolDay model:
    │   ├── schoolDays() → where('is_school_day', true)
    │   └── ordered() → orderBy('ordinal')
    └── Used by FETSolver to build slot grid: days × periods

### 1.5 Working Day Calendar (tt_working_day)
    ├── WorkingDayController::index() with AJAX operations
    ├── Table: tt_working_day
    │   ├── academic_term_id (FK → sch_academic_term)
    │   ├── date (actual calendar date)
    │   ├── school_day_id (FK → tt_school_days — day of week template)
    │   ├── day_type_id (FK → tt_day_types — default STUDY_DAY)
    │   ├── is_school_day (overrideable per date)
    │   └── is_active
    ├── AJAX operations:
    │   ├── ajaxInitializeWorkingDays() → bulk-generates all dates in term range
    │   ├── ajaxStore() → add individual day override
    │   ├── ajaxEdit() → update a specific day
    │   ├── ajaxClearWorkingDays() → reset all to defaults
    │   └── eventFeed() → FullCalendar JSON feed for calendar view
    ├── Special day overrides:
    │   ├── Set is_school_day=0 for holidays
    │   ├── Override day_type_id for exam days / sports days
    │   └── Override period_set_id for half-day schedules
    └── Used by generator to determine which days to schedule

### 1.6 Class-Specific Working Day Exceptions (tt_class_working_days)
    ├── ClassWorkingDayController with AJAX operations
    ├── Table: tt_class_working_days
    │   ├── class_id (FK → sch_classes)
    │   ├── working_day_id (FK → tt_working_day)
    │   └── is_active
    ├── FK fix applied via migration 2026_03_28_000001
    ├── ajaxInitialize() → bulk-creates from working days for a class
    ├── eventFeed() → FullCalendar feed for class-specific calendar
    ├── workingDayFeed() → alternate calendar format
    └── Allows: Gr 10-12 has exams while Gr 1-5 has regular classes

### 1.7 Class → Timetable Type Mapping (tt_class_timetable_type_jnt)
    ├── ClassTimetableTypeController::index() + create() + store()
    ├── Table: tt_class_timetable_type_jnt
    │   ├── class_id (FK → sch_classes)
    │   ├── section_id (FK → sch_sections — NULLABLE since migration 2026_03_28)
    │   ├── timetable_type_id (FK → tt_timetable_types)
    │   ├── period_set_id (FK → tt_period_sets) ← KEY: determines columns in timetable
    │   ├── academic_term_id (FK → sch_academic_term)
    │   ├── applies_to_all_sections (boolean)
    │   │   ├── true → one record applies to all sections of this class
    │   │   └── false → individual record per section
    │   ├── weekly_teaching_slots (calculated from period_set)
    │   ├── weekly_exam_slots (calculated from period_set)
    │   ├── weekly_free_slots (calculated from period_set)
    │   └── is_active
    ├── getSectionsByClass() → AJAX endpoint for section dropdown population
    ├── CRITICAL: period_set_id here drives which period columns show in timetable view
    └── Soft-delete supported

### 1.8 Timing Profiles (tt_timing_profiles + tt_school_timing_profiles)
    ├── TimingProfileController + SchoolTimingProfileController
    ├── Table: tt_timing_profiles — reusable timing configurations
    ├── Table: tt_school_timing_profiles — assignment of timing profiles to shifts/days
    └── Optional: used when shift timings vary by day type


═══════════════════════════════════════════════════════════════════════════════
## PHASE 2: REQUIREMENT GENERATION (TimetableFoundation)
═══════════════════════════════════════════════════════════════════════════════
Route: timetable-foundation/timetable-requirement
Controller: TimetableFoundationController::timetableRequirement()
Menu tab: Timetable Requirement

### 2.1 Class Subject Groups (tt_class_subject_groups via sch_class_groups_jnt)
    ├── TimetableFoundationController::generateClassGroups()
    │   └── Route: POST timetable-foundation/generate-class-groups
    ├── Source table: sch_class_groups_jnt (SchoolSetup)
    │   ├── class_id, section_id
    │   ├── subject_study_format_id (FK → sch_subject_study_format_jnt)
    │   ├── required_weekly_periods
    │   ├── is_compulsory (boolean — compulsory vs optional/elective)
    │   ├── required_room_type_id
    │   └── class_house_room_id
    ├── Destination: tt_class_subject_groups
    │   └── Maps directly from sch_class_groups_jnt with timetable context
    ├── is_compulsory=1 → goes to tt_class_subject_groups (main groups)
    └── is_compulsory=0 → goes to tt_class_subject_subgroups (optional groups)

### 2.2 Class Subject Subgroups (tt_class_subject_subgroups)
    ├── ClassSubjectSubgroupController::index() + create() + store()
    ├── Table: tt_class_subject_subgroups
    │   ├── class_id, section_id (FK from sch)
    │   ├── subject_study_format_id
    │   ├── required_weekly_periods
    │   ├── is_shared_across_sections (boolean — e.g. Hindi elective across A+B)
    │   └── is_active
    ├── getSectionsByClass() → AJAX for section filter
    ├── ajaxToggleSharing() → toggle is_shared_across_sections
    └── Soft-delete supported

### 2.3 Requirement Consolidation (tt_class_subject_groups → tt_class_subject_subgroups)
    ├── RequirementConsolidationController::generateRequirements()
    │   └── Route: POST timetable-foundation/requirement-consolidation/generate
    ├── Consolidates groups + subgroups into unified requirement list
    ├── Updates derived metrics per requirement:
    │   ├── student_count → from sch_class_section_jnt.actual_total_student
    │   ├── eligible_teacher_count → from sch_teacher_capabilities (date-filtered)
    │   └── class_house_room_id → from sch_class_section_jnt
    ├── getRequirementsStats() → summary endpoint for UI dashboard
    ├── ajaxInlineUpdate() → inline edit of individual requirements
    ├── updatePeriods() → update required_weekly_periods for a requirement
    └── User can override:
        ├── preferred_periods_json (which periods preferred for this subject)
        ├── avoid_periods_json (which periods to avoid)
        ├── spread_evenly (boolean — distribute across all days)
        └── manual_priority_override (1-100)

### 2.4 Slot Requirement Generation (tt_slot_requirements)
    ├── SlotRequirementController::generateSlotRequirement()
    │   └── Route: POST timetable-foundation/slot-requirement/generateSlotRequirement
    ├── Table: tt_slot_requirements
    │   ├── timetable_type_id (FK → tt_timetable_types)
    │   ├── class_timetable_type_id (FK → tt_class_timetable_type_jnt)
    │   ├── class_id (FK → sch_classes)
    │   ├── section_id (FK → sch_sections)
    │   ├── academic_term_id (FK → sch_academic_term)
    │   ├── activity_id (nullable — for activity-specific slot caps)
    │   ├── class_house_room_id (nullable)
    │   ├── weekly_total_slots (total scheduling slots per week)
    │   ├── weekly_teaching_slots (teaching periods per week)
    │   ├── weekly_exam_slots (exam periods per week)
    │   ├── weekly_free_slots (free/assembly periods per week)
    │   ├── daily_slots_distribution_json (JSON — per-day slot caps)
    │   │   └── Format: {"Monday": 6, "Tuesday": 8, "Wednesday": 6, ...}
    │   │   └── Keys match tt_school_days.name exactly
    │   └── is_active
    ├── SoftDeletes added via migration 2026_03_31_000002
    ├── daily_slots_distribution_json added via migration 2026_03_31_000001
    ├── Validation: weekly_total_slots = teaching + exam + free (isValid() method)
    ├── Edit per-row daily caps:
    │   ├── SlotRequirementController::edit() → loads $schoolDays
    │   └── Route: timetable-foundation/slot-requirement/{id}/edit
    ├── List view: grouped by academic_term → timetable_type
    │   ├── "Set" badge (green) if daily_slots_distribution_json not empty
    │   └── "Not set" badge (yellow) if no per-day caps configured
    └── Generated in bulk for selected term + timetable type (TRUNCATE + INSERT)

### 2.5 Activity Generation (tt_activities)
    ├── ActivityController::generateActivities() or generateAllActivities()
    │   ├── generateActivities() → for specific class/section
    │   └── generateAllActivities() → bulk for entire term + type
    ├── Table: tt_activities
    │   ├── timetable_type_id, academic_term_id
    │   ├── class_id, section_id
    │   ├── subject_study_format_id (FK → sch_subject_study_format_jnt)
    │   ├── duration_periods (1 for lecture, 2 for lab/practical)
    │   ├── weekly_occurrences (how many times per week)
    │   ├── total_periods (duration × weekly_occurrences)
    │   ├── is_compulsory (inherited from requirement)
    │   ├── class_house_room_id (specific room assignment)
    │   ├── required_room_type_id
    │   ├── is_active
    │   └── have_sub_activity (boolean)
    ├── getBatchGenerationProgress() → polling endpoint for bulk generation UI
    ├── SubActivityService handles sub-activity creation
    │   ├── Table: tt_sub_activities
    │   │   ├── parent_activity_id (FK → tt_activities)
    │   │   ├── ordinal (ordering within parent)
    │   │   └── relationship rules (same_day, consecutive, min_gap)
    │   └── Created when duration_periods > 1
    ├── ActivityController::toggleStatus() → activate/deactivate individual activities
    └── Soft-delete supported → trashedActivity() / restore() / forceDelete()

### 2.6 Activity-Teacher Mapping (tt_activity_teachers)
    ├── ActivityTeacher managed via ActivityController or TeacherAvailabilityController
    ├── Table: tt_activity_teachers
    │   ├── activity_id (FK → tt_activities)
    │   ├── teacher_id (FK → sch_teachers_profile)
    │   ├── teacher_assignment_role_id (FK → tt_teacher_assignment_roles)
    │   ├── assignment_type (AUTO / MANUAL)
    │   ├── is_required (boolean — hard-assign vs preferred)
    │   └── preference_score (0-100)
    ├── Multiple teachers can be assigned per activity (primary + assistants)
    ├── FETSolver reads this to determine which teacher goes in each cell
    └── If no teacher assigned → activity cannot be placed by solver


═══════════════════════════════════════════════════════════════════════════════
## PHASE 3: RESOURCE AVAILABILITY SETUP (TimetableFoundation)
═══════════════════════════════════════════════════════════════════════════════
Route: timetable-foundation/resource-availability
Controller: TimetableFoundationController::resourceAvailability()
Menu tab: Resource Availability

### 3.1 Teacher Availability (tt_teacher_availabilities)
    ├── TeacherAvailabilityController::generateTeacherAvailability()
    ├── Table: tt_teacher_availabilities
    │   ├── teacher_id (FK → sch_teachers_profile)
    │   ├── academic_term_id
    │   ├── max_available_periods_weekly
    │   ├── min_available_periods_weekly
    │   ├── max_periods_per_day
    │   ├── availability_type (FULL / PART_TIME / VISITING)
    │   ├── preferred_shift_id (FK → tt_shifts)
    │   └── is_active
    ├── TeacherAvailabilityLogController tracks audit trail
    │   └── Table: tt_teacher_availability_logs
    │       ├── teacher_id, log_type (CREATED/UPDATED/DELETED)
    │       ├── old_value_json, new_value_json
    │       └── changed_by (user_id)
    └── SmartTimetable extends this via tt_teacher_availability_details
        ├── Table: tt_teacher_availability_details
        │   ├── teacher_id, school_day_id, period_id
        │   └── is_available (boolean per period)
        └── Populated via migration 2026_03_24_100005

### 3.2 Teacher Unavailability Blocks (SmartTimetable)
    ├── TeacherUnavailableController::index() + create() + store()
    │   └── Route: smart-timetable/teacher-unavailable/*
    ├── Table: tt_teacher_unavailables
    │   ├── teacher_id (FK → sch_teachers_profile)
    │   ├── start_date, end_date (or single date)
    │   ├── period_ids_json (which periods blocked on those dates)
    │   ├── reason (text)
    │   ├── duration (FULL_DAY / PARTIAL)
    │   └── is_active
    ├── Migration 2026_03_31_000001 added missing columns
    ├── FETSolver reads these as hard blocks on teacher availability
    └── Soft-delete supported

### 3.3 Room Availability (tt_room_availability + tt_room_availability_detail)
    ├── RoomAvailabilityController::generate()
    ├── Table: tt_room_availability
    │   ├── room_id (FK → sch_rooms)
    │   ├── academic_term_id
    │   ├── overall_availability_status (AVAILABLE / PARTIAL / UNAVAILABLE)
    │   ├── is_class_house_room (boolean)
    │   └── is_active
    ├── Table: tt_room_availability_detail
    │   ├── room_id, school_day_id, period_id
    │   └── is_available (boolean per period per day)
    ├── RoomUnavailableController handles specific blocks
    │   └── Route: smart-timetable/room-unavailable/*
    │   └── Table: tt_room_unavailables
    │       ├── room_id, start_date, end_date
    │       ├── period_ids_json
    │       └── reason
    └── RoomAvailabilityService::generate() → bulk-generates availability records

### 3.4 Generation Strategy Configuration (SmartTimetable)
    ├── TtGenerationStrategyController::index() + create() + store()
    │   └── Route: timetable-foundation/generation-strategies/*
    ├── Table: tt_generation_strategies
    │   ├── name, code
    │   ├── algorithm_type (RECURSIVE / GENETIC / SIMULATED_ANNEALING / TABU_SEARCH / HYBRID)
    │   ├── max_recursive_depth (default: 3 for backtracking)
    │   ├── max_placement_attempts (total attempts before declaring failure)
    │   ├── tabu_size (for tabu search)
    │   ├── cooling_rate (for simulated annealing — default 0.95)
    │   ├── population_size (for genetic algorithm — default 50)
    │   ├── generations (for genetic — default 100)
    │   ├── activity_sorting_method (DIFFICULTY_DESC / PRIORITY_DESC / RANDOM)
    │   ├── timeout_seconds
    │   ├── parameters_json (additional algorithm parameters)
    │   ├── is_default (boolean — toggleDefault() endpoint)
    │   └── is_active
    └── toggleDefault() → sets one strategy as default, unsets others


═══════════════════════════════════════════════════════════════════════════════
## PHASE 4: CONSTRAINT ENGINE SETUP (SmartTimetable)
═══════════════════════════════════════════════════════════════════════════════
Route: smart-timetable/constraint-engine
Controller: TimetableMenuController::constraintEngine()
Menu tab: Constraint Engine

### 4.1 Constraint Category & Scope (tt_constraint_category_scope)
    ├── ConstraintCategoryController + ConstraintScopeController
    ├── CRITICAL: Both Category and Scope share table tt_constraint_category_scope
    │   └── Differentiated by 'type' ENUM column (CATEGORY / SCOPE)
    │   └── Do NOT create separate tables — this is D16 decision
    ├── Categories: TEACHER / CLASS / ACTIVITY / ROOM / STUDENT / GLOBAL
    ├── Scopes: GLOBAL / INDIVIDUAL / GROUP / PAIR
    └── System-seeded — school customizes individual constraints, not categories

### 4.2 Constraint Type Definition (tt_constraint_types)
    ├── ConstraintTypeController::index() + create() + store()
    ├── Table: tt_constraint_types
    │   ├── code (e.g. TEACHER_MAX_DAILY, CLASS_MAX_PER_DAY, ACTIVITY_PREFERRED_TIME)
    │   ├── name, description
    │   ├── category_id (FK → tt_constraint_category_scope where type=CATEGORY)
    │   ├── scope_id (FK → tt_constraint_category_scope where type=SCOPE)
    │   ├── is_hard (boolean — hard=must satisfy, soft=try to satisfy)
    │   ├── default_weight (0-100)
    │   ├── parameters_schema_json (JSON schema for valid parameters)
    │   └── is_active
    └── 50+ constraint types available in system

### 4.3 Individual Constraint Instances (tt_constraints)
    ├── ConstraintController::createByCategory() → category-specific creation form
    │   └── Route: smart-timetable/constraint/create/{category} (MUST come before resource route)
    ├── ConstraintController::editByCategory() → category-specific edit form
    │   └── Route: smart-timetable/constraint/{id}/edit/{category}
    ├── Table: tt_constraints
    │   ├── constraint_type_id (FK → tt_constraint_types)
    │   ├── academic_session_id (NOT academic_term_id — actual column name)
    │   ├── target_type (TEACHER / CLASS / ROOM / ACTIVITY / GLOBAL)
    │   ├── target_id (ID of the specific target entity)
    │   ├── category_id (denormalized from constraint_type)
    │   ├── is_hard (can override type default)
    │   ├── weight (0-100)
    │   ├── effective_from (NOT effective_from_date — actual column name)
    │   ├── effective_to
    │   ├── applies_to_days_json (NOT applicable_days_json — actual column name)
    │   ├── parameters_json (must match constraint_type.parameters_schema_json)
    │   └── is_active
    ├── Migration 2026_03_31_000002 added missing columns
    ├── Migration 2026_03_31_000003 fixed target_type column type
    └── Constraint Activity Tab (in view):
        ├── Shows Activity records, NOT Constraint records
        └── Read-only view — not a constraint editing interface

### 4.4 Parallel Group Management (SmartTimetable)
    ├── ParallelGroupController::index() + create() + store()
    │   └── Route: smart-timetable/parallel-group/*
    ├── Table: tt_parallel_group
    │   ├── code, name
    │   ├── group_type (PARALLEL_SECTION / OPTIONAL / SKILL / HOBBY / CUSTOM)
    │   ├── coordination_type (SAME_TIME / SAME_DAY / SAME_PERIOD_RANGE)
    │   ├── requires_same_teacher (boolean)
    │   ├── requires_same_room_type (boolean)
    │   ├── scheduling_priority
    │   ├── is_hard_constraint (boolean)
    │   ├── weight (for soft constraint scoring)
    │   └── is_active
    ├── Table: tt_parallel_group_activity (junction)
    │   ├── parallel_group_id (FK → tt_parallel_group)
    │   ├── activity_id (FK → tt_activities)
    │   └── is_anchor (boolean — anchor placed first, siblings follow)
    ├── autoDetect() → auto-detects parallel sections from activities
    ├── addActivities() → adds activities to a group
    ├── removeActivity() → removes one activity from group
    ├── setAnchor() → marks one activity as anchor for placement order
    ├── FETSolver behavior with parallel groups (D14):
    │   ├── Anchor activity placed first in best available slot
    │   ├── Sibling activities must follow in same time slot
    │   ├── Non-anchor activities SKIPPED (not blocked) until anchor placed
    │   └── Sibling classKey comes from sibling activity, NOT from anchor


═══════════════════════════════════════════════════════════════════════════════
## PHASE 5: TIMETABLE PREPARATION (TimetableFoundation)
═══════════════════════════════════════════════════════════════════════════════
Route: timetable-foundation/timetable-preparation
Controller: TimetableFoundationController::timetablePreparation()
Menu tab: Timetable Preparation

### 5.1 Timetable Record Creation (tt_timetables)
    ├── TimetableController::create() + store()
    ├── Table: tt_timetables
    │   ├── timetable_type_id (FK → tt_timetable_types)
    │   ├── period_set_id (FK → tt_period_sets) ← drives period columns in all views
    │   ├── academic_term_id (FK → sch_academic_term)
    │   ├── generation_method (MANUAL / SMART / HYBRID)
    │   ├── status (DRAFT / GENERATED / PUBLISHED / ARCHIVED)
    │   ├── is_published (boolean)
    │   ├── published_at (nullable timestamp)
    │   ├── generated_at (nullable timestamp)
    │   ├── total_activities, placed_activities, failed_activities
    │   ├── hard_violations, soft_violations
    │   ├── quality_score (0-100)
    │   └── stats_json (generation summary)
    ├── One timetable record = one grid (term + type + period_set combination)
    └── Multiple timetables can exist (different terms or types)

### 5.2 Pre-Generation Validation Checklist
    ├── Teacher coverage check
    │   ├── Every activity must have at least one teacher in tt_activity_teachers
    │   └── Teacher must have valid tt_teacher_availabilities record
    ├── Room availability check
    │   ├── Activities with required_room_type_id must have matching rooms
    │   └── Room must have is_available=true in tt_room_availability
    ├── Constraint validity check
    │   ├── No conflicting hard constraints on same target
    │   └── parameters_json validated against parameters_schema_json
    ├── Slot requirement check
    │   ├── All class-sections have slot requirements generated
    │   └── weekly_total_slots == teaching + exam + free for each row
    ├── Activity completeness check
    │   ├── All requirements in tt_class_subject_groups have activities generated
    │   └── No activities with duration=0 or weekly_occurrences=0
    └── Period set assignment check
        ├── All class-sections in tt_class_timetable_type_jnt have period_set_id
        └── Period set has > 0 active teaching periods


═══════════════════════════════════════════════════════════════════════════════
## PHASE 6A: SMART TIMETABLE GENERATION (SmartTimetable — FETSolver)
═══════════════════════════════════════════════════════════════════════════════
Route: POST smart-timetable/smart-timetable/generate/generate-fet
Controller: SmartTimetableController::generateWithFET()
Service: FETSolver (CSP Backtracking Solver)

### 6A.1 Pre-Generation Data Loading (SmartTimetableController::generateWithFET)
    ├── Validate inputs:
    │   ├── academic_term_id (required)
    │   ├── timetable_type_id (required)
    │   └── period_set_id (required) ← used to filter periods
    ├── Load school days: SchoolDay::schoolDays()->get()
    ├── Load periods: loadPeriodSet((int) $validated['period_set_id'])
    │   ├── Filters by period_set_id — never loads all period sets
    │   └── PeriodSetPeriod::where('period_set_id', $id)->orderBy('period_ord')->get()
    ├── Load activities with eager relations:
    │   ├── tt_activities with teachers, subActivities, parallelGroupActivity
    │   └── Filter: academic_term_id + timetable_type_id + is_active
    ├── Load parallel groups:
    │   ├── tt_parallel_group with activities (is_anchor flag)
    │   └── Build anchor-sibling maps in memory
    ├── Load slot requirements map (Check ⑨ daily cap enforcement):
    │   ├── SlotRequirement::where(academic_term_id, timetable_type_id, is_active)
    │   ├── Filter: whereNotNull('daily_slots_distribution_json')
    │   ├── Map to: ['classKey' => daily_slots_distribution_json]
    │   └── classKey format: class->code . '-' . section->code (e.g. "9A-A")
    ├── Create tt_generation_run record:
    │   ├── status = 'RUNNING'
    │   ├── generation_method = 'FET'
    │   └── triggered_by = auth()->id()
    └── Instantiate FETSolver with:
        ├── $activities, $days, $periods
        ├── $parallelGroups
        └── 'slot_requirements_map' => $slotReqMap

### 6A.2 FETSolver Initialization
    ├── FETSolver::__construct($activities, $days, $periods, $options)
    ├── Internal data structures initialized:
    │   ├── $slots[] — all possible (day, period) combinations
    │   ├── $activityMap[] — keyed by activity_id
    │   ├── $parallelGroupMap[] — anchor → sibling activity mappings
    │   ├── $dailySlotCapByClassKey[] — from slot_requirements_map option
    │   └── $dayIdToName[] — from $days->keyBy('id')->map(fn($d) => $d->name)
    ├── initializeParallelGroups() — builds anchor/sibling index
    ├── Activities sorted by difficulty_score DESC before solving
    └── $context object initialized:
        ├── $context->occupied[classKey][dayId][periodId] = activity_id
        ├── $context->teacherBusy[teacherId][dayId][periodId] = activity_id
        └── $context->roomBusy[roomId][dayId][periodId] = activity_id

### 6A.3 FETSolver — Core Placement Loop
    ├── For each activity in difficulty-sorted order:
    │   ├── If activity is parallel-group non-anchor → SKIP (await anchor)
    │   ├── For each candidate slot (day × period combinations):
    │   │   └── Call isBasicSlotAvailable($activity, $slot, $context, $duration)
    │   ├── If valid slot found → simulatePlacement() → mark context occupied
    │   ├── If no slot found → backtrack to previous activity (max depth from strategy)
    │   └── After anchor placed → immediately place siblings in same slot

### 6A.4 FETSolver — isBasicSlotAvailable() — The Hard-Block Gate
    ├── Check ①: Period exists in the slot grid (period_ord in loaded periods)
    ├── Check ②: Per-activity daily cap (same subject max per day from constraints)
    ├── Check ③: Teacher not already busy (context->teacherBusy check)
    ├── Check ④: Teacher unavailability (tt_teacher_unavailables date+period blocks)
    ├── Check ⑤: Room not double-booked (context->roomBusy check)
    ├── Check ⑥: Class-specific working day (tt_class_working_days)
    ├── Check ⑦: Class not double-booked (context->occupied check)
    ├── Check ⑧: Hard constraints from tt_constraints
    │   ├── Loaded by DatabaseConstraintService → FETConstraintBridge
    │   └── ConstraintManager::checkHardConstraints()
    ├── Check ⑨: Daily total slot cap from SlotRequirement.daily_slots_distribution_json
    │   ├── Get classKey = class->code . '-' . section->code
    │   ├── Get dayName = dayIdToName[slot->dayId]
    │   ├── Get cap = dailySlotCapByClassKey[classKey][dayName] (null = no limit)
    │   ├── Get alreadyPlaced = count(context->occupied[classKey][dayId] ?? [])
    │   └── Block if: alreadyPlaced + duration > cap
    └── All checks must PASS → return true (slot is available)

### 6A.5 FETSolver — simulatePlacement()
    ├── Writes to $context->occupied[classKey][dayId][periodId]
    ├── Writes to $context->teacherBusy[teacherId][dayId][periodId]
    ├── Writes to $context->roomBusy[roomId][dayId][periodId] (if room assigned)
    ├── Context cloned per backtrack branch (isolated state for recursion)
    └── Returns updated context on success

### 6A.6 FETSolver — Greedy Fallback + Rescue Pass
    ├── If CSP backtracking exhausted max_recursive_depth:
    │   ├── Greedy fallback: place in first available slot ignoring soft constraints
    │   └── Log as 'GREEDY_PLACED' in generation run
    ├── Rescue pass: after main loop, retry failed activities one more time
    │   ├── Temporarily relax some soft constraints
    │   └── Force-place if rescue option enabled in strategy
    └── Forced placement: last resort for critical activities
        ├── Displace existing non-locked activity to make room
        └── Log displaced activity for re-scheduling

### 6A.7 Generation Run Recording (tt_generation_runs)
    ├── Table: tt_generation_runs
    │   ├── timetable_id (FK → tt_timetables)
    │   ├── status (QUEUED / RUNNING / COMPLETED / FAILED / PARTIAL)
    │   ├── generation_method (FET / RANDOM / MANUAL)
    │   ├── algorithm_used (from tt_generation_strategies)
    │   ├── total_activities
    │   ├── placed_activities
    │   ├── placements_percentage (placed / total × 100)
    │   ├── constraint_violations (count of hard violations)
    │   ├── execution_time_seconds
    │   ├── started_at, finished_at
    │   ├── error_message (if failed)
    │   └── stats_json (per-activity placement details)
    └── Updated at completion via TimetableStorageService

### 6A.8 Timetable Cell Storage (TimetableStorageService)
    ├── Atomic DB transaction for all cell inserts
    ├── Inserts into tt_timetable_cells:
    │   ├── timetable_id (FK → tt_timetables)
    │   ├── generation_run_id (FK → tt_generation_runs)
    │   ├── class_id, section_id
    │   ├── school_day_id (FK → tt_school_days)
    │   ├── period_ord (NOT period_id — ordinal from period set)
    │   ├── activity_id (FK → tt_activities)
    │   ├── room_id (nullable FK → sch_rooms)
    │   ├── source (AUTO / MANUAL / SWAP / RESCUE / FORCED)
    │   ├── is_locked (boolean — default false)
    │   └── is_active
    ├── Inserts into tt_timetable_cell_teachers:
    │   ├── timetable_cell_id (FK → tt_timetable_cells)
    │   ├── teacher_id (FK → sch_teachers_profile)
    │   └── teacher_assignment_role_id
    ├── Updates tt_timetables:
    │   ├── status = 'GENERATED'
    │   ├── generated_at = NOW()
    │   ├── placed_activities count
    │   └── quality_score (calculated)
    └── Rolls back all on any error


═══════════════════════════════════════════════════════════════════════════════
## PHASE 6B: MANUAL TIMETABLE CREATION (SmartTimetable — TimetablePreviewController)
═══════════════════════════════════════════════════════════════════════════════
Route: GET smart-timetable/smart-timetable/preview/{timetable}
Controller: SmartTimetableController::preview() (also TimetablePreviewController)

### 6B.1 Preview Grid Loading
    ├── Load timetable record: Timetable::findOrFail($timetable->id)
    ├── Load school days: SchoolDay::schoolDays()->ordered()->get()
    ├── Load periods (FILTERED by timetable's period_set_id):
    │   └── PeriodSetPeriod::where('period_set_id', $timetable->period_set_id)
    │        →where('is_active', true)->orderBy('period_ord')->get()
    ├── Load existing cells:
    │   └── TimetableCell::where('timetable_id', $id)
    │        →with(['activity', 'room', 'teachers', 'section', 'class'])->get()
    ├── Build cell grid: indexed by [classKey][dayId][period_ord]
    └── Load available activities for manual placement (unplaced)

### 6B.2 Manual Cell Placement
    ├── POST smart-timetable/smart-timetable/place-cell
    ├── TimetablePreviewController::placeCell()
    ├── Validates:
    │   ├── Slot is not already occupied
    │   ├── Teacher is not busy at this slot
    │   └── Room is not double-booked
    ├── Creates tt_timetable_cells record (source = 'MANUAL')
    ├── Creates tt_timetable_cell_teachers record
    └── Returns success + updated cell data for UI

### 6B.3 Manual Cell Removal
    ├── POST smart-timetable/smart-timetable/remove-cell
    ├── TimetablePreviewController::removeCell()
    ├── Checks is_locked → blocks removal of locked cells
    └── Soft-deletes tt_timetable_cells record


═══════════════════════════════════════════════════════════════════════════════
## PHASE 7: POST-GENERATION PROCESSING (SmartTimetable)
═══════════════════════════════════════════════════════════════════════════════

### 7.1 Constraint Violation Recording (tt_constraint_violations)
    ├── After generation, solver logs all violations
    ├── Table: tt_constraint_violations
    │   ├── timetable_id, generation_run_id
    │   ├── constraint_id (FK → tt_constraints)
    │   ├── violation_type (HARD / SOFT)
    │   ├── severity (CRITICAL / HIGH / MEDIUM / LOW)
    │   ├── activity_id (which activity caused violation)
    │   ├── day_id, period_ord (where violation occurred)
    │   ├── details_json (full violation context)
    │   └── is_resolved (boolean)
    └── Queryable via AnalyticsController::violations()

### 7.2 Teacher Workload Calculation (tt_teacher_workloads)
    ├── Calculated post-generation by AnalyticsService
    ├── Table: tt_teacher_workloads
    │   ├── timetable_id (FK → tt_timetables)
    │   ├── teacher_id (FK → sch_teachers_profile)
    │   ├── teaching_hours (total per week)
    │   ├── daily_hours_json (hours per day)
    │   ├── subjects_json (list of subjects assigned)
    │   ├── classes_json (list of classes assigned)
    │   ├── span_minutes (first period to last period gap)
    │   ├── gap_periods (free periods between lessons)
    │   ├── utilization_percent (assigned / max × 100)
    │   └── last_calculated_at
    ├── AnalyticsController::workload() → workload dashboard
    └── Alerts generated for:
        ├── Over-allocated teachers (utilization > 90%)
        └── Under-allocated teachers (utilization < 50%)

### 7.3 Room Utilization Calculation (tt_room_utilizations)
    ├── Calculated post-generation by AnalyticsService
    ├── Table: tt_room_utilizations
    │   ├── timetable_id, room_id
    │   ├── total_periods_available (working_days × periods_per_day)
    │   ├── total_periods_used (from tt_timetable_cells count)
    │   ├── utilization_percent
    │   ├── usage_by_type_json (lecture / lab / exam breakdown)
    │   ├── avg_occupancy_rate (avg students / room capacity)
    │   ├── peak_usage_day, peak_usage_period
    │   └── last_calculated_at
    └── AnalyticsController::utilization() → room utilization dashboard

### 7.4 Daily Analytics Snapshots (tt_analytics_daily_snapshots)
    ├── Table: tt_analytics_daily_snapshots
    │   ├── snapshot_date
    │   ├── academic_session_id, timetable_id
    │   ├── total_teachers_scheduled
    │   ├── total_classes_conducted
    │   ├── total_periods_scheduled
    │   ├── total_substitutions
    │   ├── violations_detected
    │   └── snapshot_data_json
    └── Used for trend analysis across weeks/terms

### 7.5 Generation Quality Score
    ├── Calculated at end of TimetableStorageService::store()
    ├── Quality score formula:
    │   ├── Teacher satisfaction score (40%) — preference constraints satisfied
    │   ├── Room utilization score (30%) — avg utilization in healthy range
    │   ├── Constraint satisfaction rate (20%) — soft constraints met
    │   └── Balance metrics (10%) — workload distribution evenness
    ├── Stored in tt_timetables.quality_score
    └── Shown in timetable list and reports


═══════════════════════════════════════════════════════════════════════════════
## PHASE 8: VIEW & REFINEMENT (SmartTimetable)
═══════════════════════════════════════════════════════════════════════════════
Route: smart-timetable/view-and-refinement
Controller: TimetableMenuController::viewAndRefinement()
Secondary: TimetablePageController::timetableOperation()

### 8.1 Timetable View Options
    ├── Class-wise view (TimetablePageController::timetableMaster())
    │   ├── Rows = class-sections, Columns = days × periods
    │   ├── Periods filtered by timetable.period_set_id (CRITICAL — fixed bug)
    │   └── Shows subject, teacher, room per cell
    ├── Teacher-wise view
    │   ├── One teacher's schedule across all classes
    │   └── Free period highlighting
    ├── Room-wise view
    │   ├── Room occupancy by day and period
    │   └── Utilization percentage
    ├── Day-wise view
    │   └── School-wide view for one specific day
    └── Color coding: subject-based / teacher-based / conflict-highlighted

### 8.2 Manual Refinement Operations (RefinementController)
    ├── Swap: POST smart-timetable/refinement/swap
    │   ├── RefinementController::swap()
    │   ├── Swaps two cells (A→B, B→A)
    │   ├── Pre-swap impact analysis via impact()
    │   └── Validates both directions before applying
    ├── Move: POST smart-timetable/refinement/move
    │   ├── RefinementController::move()
    │   ├── Moves one cell to empty slot
    │   └── Validates teacher/room availability at target
    ├── Lock/Unlock: POST smart-timetable/refinement/lock
    │   ├── RefinementController::toggleLock()
    │   ├── Sets tt_timetable_cells.is_locked = true/false
    │   └── Locked cells cannot be moved, swapped, or removed
    ├── Candidates: GET smart-timetable/refinement/candidates/{cellId}
    │   ├── RefinementController::candidates()
    │   └── Returns valid swap/move targets for a given cell
    └── Impact Analysis: GET smart-timetable/refinement/impact/{cellId}
        ├── RefinementController::impact()
        ├── ImpactAnalysisSession + ImpactAnalysisDetail tables
        └── Returns: teacher workload delta, constraint violations delta, quality score delta

### 8.3 Change Tracking (tt_change_logs)
    ├── Every manual change creates a tt_change_logs entry
    ├── Table: tt_change_logs
    │   ├── timetable_id, timetable_cell_id
    │   ├── change_type (PLACE / REMOVE / SWAP / MOVE / LOCK / UNLOCK / SUBSTITUTE)
    │   ├── old_values_json (cell state before change)
    │   ├── new_values_json (cell state after change)
    │   ├── changed_by (user_id)
    │   ├── reason (user-provided text)
    │   └── metadata_json
    └── Queryable in Reports & Logs view

### 8.4 Conflict Detection & Resolution
    ├── ConflictDetection table: tt_conflict_detections
    ├── ConflictResolutionSession table: tt_conflict_resolution_sessions
    ├── ConflictResolutionOption table: tt_conflict_resolution_options
    ├── Conflicts detected:
    │   ├── REAL-TIME: on each manual swap/move
    │   ├── ON-DEMAND: via re-validation trigger
    │   └── POST-GENERATION: after solver completes
    └── Resolution options presented: auto-swap, move, constraint relaxation

### 8.5 Batch Operations (BatchOperation + BatchOperationItem)
    ├── Table: tt_batch_operations — tracks bulk operation sessions
    ├── Table: tt_batch_operation_items — individual items in batch
    ├── Supported batch operations:
    │   ├── Bulk lock by class/teacher/day/pattern
    │   ├── Bulk substitute teacher across all periods
    │   └── Bulk move entire day for a class
    └── Progress tracked per batch_operation_id

### 8.6 Re-Validation After Changes
    ├── RevalidationSchedule table: tt_revalidation_schedules
    ├── RevalidationTrigger table: tt_revalidation_triggers
    ├── Triggers:
    │   ├── After each significant manual change
    │   ├── After batch operation completes
    │   └── On-demand by user
    └── Re-runs all hard constraint checks + updates quality_score


═══════════════════════════════════════════════════════════════════════════════
## PHASE 9: PUBLICATION & APPROVAL (SmartTimetable)
═══════════════════════════════════════════════════════════════════════════════

### 9.1 Pre-Publication Quality Check
    ├── Run full validation suite before publication:
    │   ├── hard_violations count must be 0
    │   ├── All activities placed (placed_activities = total_activities)
    │   ├── No orphaned timetable_cell_teachers records
    │   └── All rooms valid (room_id in tt_timetable_cells → sch_rooms)
    ├── Final quality_score calculated
    └── tt_timetable.validation_status updated

### 9.2 Approval Workflow (tt_approval_requests)
    ├── Table: tt_approval_requests
    │   ├── timetable_id, request_type (PUBLISH / MAJOR_CHANGE)
    │   ├── status (PENDING_APPROVAL / APPROVED / REJECTED / CHANGES_REQUESTED)
    │   ├── requested_by (user_id)
    │   └── notes_json
    ├── Table: tt_approval_levels — hierarchy definition
    ├── Table: tt_approval_workflows — workflow definitions
    ├── Table: tt_approval_decisions
    │   ├── approval_request_id, approver_id
    │   ├── decision (APPROVED / REJECTED / ABSTAINED)
    │   └── comments
    └── Table: tt_approval_notifications — notification records

### 9.3 Publication
    ├── POST smart-timetable/timetable/{id}/publish
    ├── TimetablePublishController::publishTimetable()
    ├── Actions:
    │   ├── tt_timetables.status → 'PUBLISHED'
    │   ├── tt_timetables.is_published → true
    │   ├── tt_timetables.published_at → NOW()
    │   └── tt_timetables.published_by → auth()->id()
    ├── Generates publication artifacts:
    │   ├── TimetableExportController::exportPdf() → class-wise PDF
    │   ├── TimetableExportController::exportTeacherPdf() → teacher-wise PDF
    │   └── TimetableExportController::exportExcel() → raw data export
    └── Unpublish: POST smart-timetable/timetable/{id}/unpublish
        └── Reverts status to 'GENERATED'

### 9.4 Export Formats
    ├── PDF: Route smart-timetable/export/pdf/{timetableId}
    │   ├── DomPDF rendering
    │   ├── One page per class-section
    │   └── No flexbox/grid — table layout only (DomPDF rule)
    ├── Teacher PDF: Route smart-timetable/export/teacher-pdf/{timetableId}
    │   └── One page per teacher
    └── Excel: Route smart-timetable/export/excel/{timetableId}
        └── Maatwebsite Excel with ShouldQueue for large schools


═══════════════════════════════════════════════════════════════════════════════
## PHASE 10: SUBSTITUTION MANAGEMENT (SmartTimetable)
═══════════════════════════════════════════════════════════════════════════════
Route: smart-timetable/substitute-management
Controller: TimetableMenuController::substituteManagement()
Menu tab: Substitute Management

### 10.1 Absence Reporting (tt_teacher_absences)
    ├── POST smart-timetable/substitution/absence
    ├── SubstitutionController::reportAbsence()
    ├── Table: tt_teacher_absences
    │   ├── teacher_id, absence_date
    │   ├── absence_type (LEAVE / SICK / TRAINING / ON_DUTY)
    │   ├── start_period_ord, end_period_ord (or full_day flag)
    │   ├── reason, document_proof (media library)
    │   ├── status (REPORTED / APPROVED / REJECTED)
    │   └── reported_by (user_id)
    ├── Approve: POST smart-timetable/teacher-absence/{id}/approve
    └── Reject: POST smart-timetable/teacher-absence/{id}/reject

### 10.2 Substitute Finding
    ├── GET smart-timetable/substitution/candidates/{cellId}/{date}
    ├── SubstitutionController::candidates()
    ├── Finds eligible substitutes:
    │   ├── Teacher must be free at this period on this date
    │   ├── Teacher must have capability for this subject (sch_teacher_capabilities)
    │   ├── Teacher must not have approved absence on this date
    │   └── Scored by: subject_match + workload_balance + preference
    ├── SubstitutionPattern table: tt_substitution_patterns
    │   └── Historical patterns for smart suggestions
    └── SubstitutionRecommendation table: tt_substitution_recommendations
        └── AI/rule-based recommendations

### 10.3 Substitution Assignment (tt_substitution_logs)
    ├── POST smart-timetable/substitution/assign (manual)
    ├── POST smart-timetable/substitution/auto-assign (automatic best match)
    ├── Table: tt_substitution_logs
    │   ├── original_teacher_id, replacement_teacher_id
    │   ├── timetable_cell_id, absence_date
    │   ├── status (ASSIGNED / NOTIFIED / CONFIRMED / COMPLETED)
    │   └── assigned_by (user_id)
    ├── POST smart-timetable/substitution-log/{id}/notify → marks as NOTIFIED
    └── History: GET smart-timetable/substitution/history/{teacherId}


═══════════════════════════════════════════════════════════════════════════════
## PHASE 11: ANALYTICS & REPORTS (SmartTimetable + TimetableFoundation)
═══════════════════════════════════════════════════════════════════════════════
Route: smart-timetable/reports-and-logs (SmartTimetable)
Route: timetable-foundation/reports-and-logs (TimetableFoundation)

### 11.1 Analytics Dashboard (SmartTimetable AnalyticsController)
    ├── GET smart-timetable/analytics/ → overall dashboard
    ├── GET smart-timetable/analytics/workload → teacher workload analysis
    │   └── Data: tt_teacher_workloads with utilization bars
    ├── GET smart-timetable/analytics/utilization → room utilization
    │   └── Data: tt_room_utilizations with heatmap
    ├── GET smart-timetable/analytics/violations → constraint violations
    │   └── Data: tt_constraint_violations grouped by severity
    ├── GET smart-timetable/analytics/distribution → subject distribution
    │   └── Data: tt_timetable_cells grouped by subject across classes
    └── GET smart-timetable/analytics/export/{type} → export analytics

### 11.2 What-If Scenario Planning
    ├── WhatIfScenario table: tt_what_if_scenarios
    │   ├── scenario_name, description
    │   ├── base_timetable_id
    │   └── scenario_parameters_json (e.g. "remove teacher X")
    └── VersionComparison + VersionComparisonDetail tables
        ├── Compare two timetable versions
        └── Show delta: which cells changed, quality score diff

### 11.3 TimetableFoundation Reports
    ├── TimetableFoundationController::reportsAndLogs()
    ├── Reports available:
    │   ├── Slot Requirement Summary (class-wise weekly slot distribution)
    │   ├── Activity Coverage Report (activities vs requirements)
    │   ├── Teacher Availability Summary (by teacher, term)
    │   └── Constraint Summary (count by type, category)
    └── AnalyticsService provides underlying data aggregation


═══════════════════════════════════════════════════════════════════════════════
## DEPENDENCIES MAP
═══════════════════════════════════════════════════════════════════════════════

### External Dependencies (SchoolSetup → TimetableFoundation)
    ├── sch_classes → tt_activities.class_id, tt_slot_requirements.class_id
    ├── sch_sections → tt_activities.section_id, tt_slot_requirements.section_id
    ├── sch_class_section_jnt → tt_slot_requirements.class_house_room_id
    ├── sch_subjects → via sch_subject_study_format_jnt → tt_activities
    ├── sch_study_formats → activity duration (LAB=2 periods, LECTURE=1)
    ├── sch_subject_study_format_jnt → tt_activities.subject_study_format_id
    ├── sch_class_groups_jnt → source for requirement generation
    ├── sch_teachers_profile → tt_activity_teachers.teacher_id
    ├── sch_teacher_capabilities → teacher eligibility check for activities
    ├── sch_rooms → tt_timetable_cells.room_id
    ├── sch_room_types → room matching for activities requiring specific rooms
    └── sch_academic_term → tt_slot_requirements.academic_term_id

### TimetableFoundation → SmartTimetable Dependencies
    ├── tt_timetables → SmartTimetable reads for generation context
    ├── tt_activities → FETSolver core input
    ├── tt_activity_teachers → teacher assignment to activities
    ├── tt_slot_requirements → daily cap enforcement in FETSolver
    ├── tt_school_days → slot grid rows (days)
    ├── tt_period_set_period_jnt → slot grid columns (periods)
    ├── tt_class_timetable_type_jnt → period_set_id per class
    ├── tt_working_day → which dates are schedulable
    ├── tt_class_working_days → class-specific date overrides
    ├── tt_teacher_availabilities → teacher max/min periods
    └── tt_room_availability → room is_available flags

### SmartTimetable Internal Dependencies (Generation Order)
    ├── tt_generation_strategies → strategy parameters for FETSolver
    ├── tt_constraints → hard/soft rules loaded by ConstraintManager
    ├── tt_teacher_unavailables → teacher block periods (Check ④)
    ├── tt_room_unavailables → room block periods (Check ⑤)
    ├── tt_parallel_group + tt_parallel_group_activity → anchor/sibling placement
    └── tt_generation_runs → runtime tracking, updated throughout

### Post-Generation Dependencies (generation → analytics)
    ├── tt_timetable_cells → source for all workload/utilization analysis
    ├── tt_timetable_cell_teachers → teacher-cell joins for workload calc
    ├── tt_generation_runs → source for generation metrics in reports
    └── tt_constraint_violations → source for violation analytics


═══════════════════════════════════════════════════════════════════════════════
## CRITICAL TECHNICAL RULES & GOTCHAS
═══════════════════════════════════════════════════════════════════════════════

### Period Set Filtering (FIXED BUG — must maintain)
    ├── ALWAYS filter PeriodSetPeriod by period_set_id — never load all
    ├── preview() uses: $timetable->period_set_id (from loaded timetable record)
    ├── generateWithFET() uses: $validated['period_set_id']
    └── TimetablePageController already filters correctly — match this pattern

### classKey Format (FETSolver)
    ├── Format: class->code . '-' . section->code
    ├── Example: "9A-A" (class code + dash + section code)
    ├── Used as key in: $context->occupied, $dailySlotCapByClassKey
    └── Must be consistent — never use class name or section name

### Daily Slots Cap Check ⑨ (implemented 2026-03-31)
    ├── $alreadyPlaced = count($context->occupied[$classKey][$dayId] ?? [])
    ├── Block condition: $alreadyPlaced + $duration > $cap
    ├── Uses $duration (not 1) to handle 2-period lab activities correctly
    └── Keys in daily_slots_distribution_json must match tt_school_days.name exactly

### Constraint Table Column Names (D17 — verified)
    ├── Use 'academic_session_id' NOT 'academic_term_id' in tt_constraints
    ├── Use 'effective_from' NOT 'effective_from_date'
    ├── Use 'applies_to_days_json' NOT 'applicable_days_json'
    └── Use 'target_type' (ENUM) NOT 'target_type_id' (integer)

### Parallel Group Placement (D14)
    ├── Anchor activity placed first
    ├── Non-anchor siblings: SKIP (not block) until anchor placed
    ├── Sibling classKey = sibling's own class→code + '-' + section→code
    └── Never use anchor's classKey for sibling placement

### SoftDeletes Requirement
    ├── ALL models must use SoftDeletes trait
    ├── ALL tables must have deleted_at column in migration
    └── DB::table() bypasses soft-delete scope — use Model::query() instead

### Migrations (additive only — D17)
    ├── NEVER modify existing migrations
    ├── Always create new additive migrations for schema changes
    ├── Use Schema::hasColumn() guards for idempotency
    └── Tenant migrations → database/migrations/tenant/ only


═══════════════════════════════════════════════════════════════════════════════
## COMPLETE TABLE INVENTORY (tt_* tables in generation pipeline order)
═══════════════════════════════════════════════════════════════════════════════

### Phase 0-1 (Foundation Config)
    tt_config                          → system configuration key-value pairs
    tt_shifts                          → school shift definitions
    tt_day_types                       → day classifications (study/holiday/exam)
    tt_period_types                    → period classifications (teaching/break/etc)
    tt_teacher_assignment_roles        → teacher role types in activities
    tt_school_days                     → weekly day template (Mon-Sun)
    tt_timetable_types                 → timetable type definitions
    tt_period_sets                     → named collections of periods
    tt_period_set_period_jnt           → periods within each set (with ordinal)
    tt_timing_profiles                 → period timing configurations
    tt_school_timing_profiles          → timing assignments to shifts

### Phase 1-2 (Term & Requirements)
    sch_academic_term                  → academic term (shared with SchoolSetup)
    tt_class_timetable_type_jnt        → class → timetable type + period set mapping
    tt_working_day                     → calendar dates within term
    tt_class_working_days              → class-specific working day overrides
    tt_class_subject_groups            → compulsory requirement groups per class
    tt_class_subject_subgroups         → optional/elective requirement subgroups
    tt_class_subgroup_members          → student membership in subgroups
    tt_slot_requirements               → weekly slot caps per class-section-term
    tt_activities                      → schedulable lesson/activity records
    tt_activity_teachers               → teacher assignments to activities
    tt_sub_activities                  → sub-divisions of multi-period activities
    tt_activity_priorities             → priority weightings for activity sorting

### Phase 3 (Resource Availability)
    tt_teacher_availabilities          → teacher period budgets per term
    tt_teacher_availability_logs       → audit log of availability changes
    tt_teacher_availability_details    → per-period availability flags
    tt_room_availability               → room availability master records
    tt_room_availability_detail        → per-period room availability flags
    tt_generation_strategies           → algorithm configuration presets

### Phase 4 (Constraint Engine)
    tt_constraint_category_scope       → categories AND scopes (type ENUM)
    tt_constraint_types                → constraint type definitions
    tt_constraints                     → active constraint instances
    tt_teacher_unavailables            → teacher block periods
    tt_room_unavailables               → room block periods
    tt_parallel_group                  → parallel scheduling groups
    tt_parallel_group_activity         → activities in parallel groups (is_anchor)

### Phase 5 (Timetable Record)
    tt_timetables                      → timetable header records

### Phase 6 (Generation Output)
    tt_generation_runs                 → generation session tracking
    tt_generation_queues               → background job queue records
    tt_timetable_cells                 → placed period cells (grid output)
    tt_timetable_cell_teachers         → teacher assignments to cells

### Phase 7 (Post-Generation Analytics)
    tt_constraint_violations           → recorded constraint violations
    tt_teacher_workloads               → teacher workload analytics
    tt_room_utilizations               → room utilization analytics
    tt_analytics_daily_snapshots       → daily metric snapshots
    tt_optimization_runs               → post-generation optimization sessions
    tt_optimization_iterations         → optimization iteration records
    tt_optimization_moves              → moves made during optimization
    tt_priority_configs                → priority configurations

### Phase 8 (Refinement)
    tt_change_logs                     → audit log of manual changes
    tt_conflict_detections             → detected conflicts
    tt_conflict_resolution_sessions    → conflict resolution sessions
    tt_conflict_resolution_options     → proposed resolution options
    tt_batch_operations                → bulk operation sessions
    tt_batch_operation_items           → items within batch operations
    tt_revalidation_schedules          → revalidation scheduling
    tt_revalidation_triggers           → revalidation event triggers
    tt_impact_analysis_sessions        → impact analysis sessions
    tt_impact_analysis_details         → impact analysis detail records
    tt_resource_bookings               → resource reservation records

### Phase 9 (Publication & Approval)
    tt_approval_requests               → approval workflow requests
    tt_approval_levels                 → approval hierarchy definitions
    tt_approval_workflows              → workflow definitions
    tt_approval_decisions              → individual approval decisions
    tt_approval_notifications          → approval notification records

### Phase 10 (Substitution)
    tt_teacher_absences                → teacher absence records
    tt_substitution_logs               → substitution assignments
    tt_substitution_patterns           → historical substitution patterns
    tt_substitution_recommendations    → AI-based substitution suggestions

### Phase 11 (Advanced Analytics & ML)
    tt_version_comparisons             → timetable version comparison sessions
    tt_version_comparison_details      → per-cell version differences
    tt_what_if_scenarios               → hypothetical scenario planning
    tt_ml_models                       → trained ML model metadata
    tt_training_data                   → ML training datasets
    tt_pattern_results                 → pattern detection output
    tt_prediction_logs                 → ML prediction logs
    tt_feature_importances             → ML feature importance data
    tt_escalation_rules                → escalation rule definitions
    tt_escalation_logs                 → escalation event logs
