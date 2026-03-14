# TIMETABLE GENERATION PROCESS FLOW - ENHANCED v2.0
════════════════════════════════════════════════════


## PHASE 0: PRE-REQUISITES SETUP (One-time)
══════════════════════════════════════════════════
### 0.1 System Configuration
    ├── Set tt_config parameters with validation rules
    │   ├── total_periods_per_day (8-12)
    │   ├── school_open_days_per_week (5-7)
    │   ├── min_periods_per_teacher (15-20)
    │   └── max_periods_per_teacher (40-48)
    ├── Define tt_shift (Morning/Afternoon/Evening) with time slots
    ├── Define tt_day_type with metadata (color_code, icon, working_flag)
    │   ├── STUDY_DAY (is_working=1, reduced_periods=0)
    │   ├── EXAM_DAY (is_working=1, reduced_periods=1)
    │   ├── HOLIDAY (is_working=0, reduced_periods=0)
    │   ├── PTM_DAY (is_working=1, reduced_periods=1)
    │   └── SPORTS_DAY (is_working=1, reduced_periods=1)
    ├── Define tt_period_type with workload calculation
    │   ├── TEACHING (counts_as_workload=1, workload_factor=1.0)
    │   ├── LAB (counts_as_workload=1, workload_factor=1.5)
    │   ├── BREAK (counts_as_workload=0)
    │   ├── LUNCH (counts_as_workload=0)
    │   ├── ASSEMBLY (counts_as_workload=0.5)
    │   └── FREE_PERIOD (counts_as_workload=0)
    └── Define tt_teacher_assignment_role with workload factors
        ├── PRIMARY (workload_factor=1.0, is_primary=1)
        ├── ASSISTANT (workload_factor=0.5, is_primary=0)
        ├── CO_TEACHER (workload_factor=0.3, allows_overlap=1)
        └── SUBSTITUTE (workload_factor=0.8, is_primary=0)

### 0.2 Master Data Validation & Setup
    ├── Validate and Import/Setup sch_buildings with unique codes
    ├── Validate and Import/Setup sch_rooms_type with resource requirements
    ├── Validate and Import/Setup sch_rooms with capacity and equipment tracking
    │   ├── Generate room_code automatically (Building_Floor_Room)
    │   ├── Set capacity limits and max_occupancy
    │   └── Define room_tags (Projector, SmartBoard, AC, Lab_Equipment)
    ├── Validate and Import/Setup sch_subjects with difficulty_index
    │   ├── Core subjects (Maths, Science) → difficulty_index = 8-10
    │   ├── Languages → difficulty_index = 5-7
    │   └── Co-curricular → difficulty_index = 2-4
    ├── Validate and Import/Setup sch_study_formats
    │   ├── LECTURE (duration=1, requires_room=1, requires_teacher=1)
    │   ├── LAB (duration=2, requires_room=1, requires_teacher=1)
    │   ├── PRACTICAL (duration=2, requires_room=1, requires_teacher=1)
    │   └── ACTIVITY (duration=1, requires_room=0, requires_teacher=0.5)
    ├── Validate and Import/Setup sch_subject_study_format_jnt
    │   └── Create unique subj_stdformat_code (e.g., 'SCI_LAC', 'MAT_LAB')
    ├── Validate and Import/Setup sch_classes with ordinal
    ├── Validate and Import/Setup sch_sections with code (A,B,C)
    ├── Validate and Import/Setup sch_class_section_jnt
    │   ├── Generate class_section_code (e.g., '10_A', '12_B')
    │   ├── Assign class_teacher and assistant teacher
    │   └── Set capacity and actual_total_student
    ├── Validate and Import/Setup sch_employees with emp_code
    ├── Validate and Import/Setup sch_teachers_profile
    │   ├── Set teacher_availability (max/min periods)
    │   ├── Define preferred_shift
    │   └── Set specialization and competency levels
    └── Validate and Import/Setup sch_class_groups_jnt
        ├── Generate unique code (Class+Section+Subject+StudyFormat+Type)
        └── Link to required_room_type and class_house_room

### 0.3 Pre-requisite Validation Report
    ├── Generate validation report for all master data
    ├── Identify missing critical data
    ├── Flag data inconsistencies
    └── Block timetable generation if validation fails


## PHASE 1: ACADEMIC TERM & TIMETABLE TYPE SETUP
═════════════════════════════════════════════════════
### 1.1 Academic Term Setup with Validation
    ├── Create/Select Academic Term (sch_academic_term)
    ├── Validate no overlapping terms in same academic session
    ├── Set term dates with business rules
    │   ├── term_start_date < term_end_date
    │   ├── total_teaching_days <= total_days_in_term
    │   └── periods_per_day consistent across term
    ├── Calculate total teaching days, periods per day / week
    ├── Set week_start_day (1=Monday, 7=Sunday) ISO standard
    └── Mark current term with unique constraint (only one current per session)

### 1.2 Timetable Type Definition with Versioning
    ├── Create tt_timetable_type with effective date range
    │   ├── STANDARD (regular teaching days)
    │   ├── EXAM (exam schedule with reduced periods)
    │   ├── HALF_DAY (special events)
    │   ├── UNIT_TEST-1 (subject-specific tests)
    │   └── FINAL_EXAM (comprehensive exam schedule)
    ├── Validate no overlapping effective dates for same shift
    ├── Set shift_id, school_start_time, school_end_time
    ├── Define max_weekly_periods_per_teacher (default: 48)
    ├── Define min_weekly_periods_per_teacher (default: 15)
    └── Set is_default flag (only one default per academic session)

### 1.3 Period Set Definition with Validation
    ├── Create tt_period_set with different configurations
    │   ├── 'STANDARD_8P' (8 periods: 6 teaching + 2 breaks)
    │   ├── 'HALF_DAY_4P' (4 periods: 3 teaching + 1 break)
    │   ├── 'TODDLER_6P' (6 periods: 5 teaching + 1 lunch)
    │   ├── 'EXAM_3P' (3 periods: all exam)
    │   └── 'SPORTS_DAY_5P' (5 periods: 3 teaching + 2 sports)
    ├── Validate total_periods consistency
    ├── Define tt_period_set_period_jnt with strict ordering
    │   ├── period_ord (1..n) unique per set
    │   ├── start_time < end_time for each period
    │   ├── consecutive periods have no gaps
    │   └── period_type_id must be valid
    ├── Calculate duration_minutes automatically
    └── Set is_default flag for standard period set

### 1.4 Calendar Setup with Multi-day Type Support
    ├── Define tt_school_days (weekly schedule template)
    │   ├── Map to ISO weekdays (1-7)
    │   └── Set is_school_day flag for each weekday
    ├── Generate tt_working_day for entire term
    │   ├── Bulk insert all dates in term range
    │   ├── Set default day_type1_id = STUDY_DAY
    │   └── Allow multiple day types per date (day_type1..4)
    ├── Apply special day overrides
    │   ├── Mark holidays (is_school_day=0)
    │   ├── Mark exam days (day_type2_id = EXAM_DAY)
    │   ├── Mark sports days (day_type1_id = SPORTS_DAY)
    │   └── Override period_set_id for special days
    └── Set tt_class_working_day_jnt for class-specific exceptions
        ├── Classes with exams vs regular classes on same date
        ├── Half-day for specific classes only
        └── PTM day for parent-teacher meetings

### 1.5 Class Timetable Type Mapping
    ├── Map classes to timetable types (tt_class_timetable_type_jnt)
    ├── Support applies_to_all_sections flag
    │   ├── If 1: one record for all sections
    │   └── If 0: individual records per section
    ├── Assign period_set_id to each class+section
    ├── Validate no conflicting period sets for same class+section
    ├── Set effective_from and effective_to dates
    └── Calculate weekly teaching/exam/free period counts from period_set

### 1.6 Validation & Reporting
    ├── Generate calendar validation report
    ├── Identify missing working days
    ├── Flag inconsistent period set assignments
    └── Confirm all classes have valid timetable type


## PHASE 2: REQUIREMENT GENERATION (Enhanced with Batch Processing)
═══════════════════════════════════════════════════════════════════
### 2.1 Slot Requirement Generation (Bulk Insert)
    ├── TRUNCATE tt_slot_requirement for target term+type
    ├── Step 1: INSERT where applies_to_all_sections=0
    │   ├── Select from tt_class_timetable_type_jnt
    │   ├── Direct insert for each record
    │   └── Calculate weekly slots from period_set
    ├── Step 2: INSERT where applies_to_all_sections=1 (Batch process)
    │   ├── Loop through classes in chunks of 100
    │   │   ├── Select all sections for each class
    │   │   ├── Create slot requirement per section
    │   │   └── Bulk insert 100 records at a time
    │   └── Track progress with batch counter
    ├── Update class_house_room_id from sch_class_section_jnt
    ├── Calculate slot distribution metrics
    │   ├── weekly_total_slots = periods_per_day × working_days
    │   ├── weekly_teaching_slots = teaching_periods × working_days
    │   ├── weekly_exam_slots = exam_periods × working_days
    │   └── weekly_free_slots = free_periods × working_days
    └── Generate slot requirement summary report

### 2.2 Class Requirement Groups/Subgroups (Enhanced)
    ├── INSERT into tt_class_requirement_groups (is_compulsory=1)
    │   ├── Copy from sch_class_groups_jnt with is_compulsory=1
    │   └── Generate unique code if not present
    ├── INSERT into tt_class_requirement_subgroups (is_compulsory=0)
    │   ├── Copy from sch_class_groups_jnt with is_compulsory=0
    │   └── Set is_shared_across_sections flag
    ├── UPDATE class_house_room_id from sch_class_section_jnt
    │   ├── Join on class_id and section_id
    │   └── Use LEFT JOIN to handle NULL sections
    ├── UPDATE student_count with actual enrollment (Optimized)
    │   ├── For groups: UPDATE from sch_class_section_jnt.actual_total_student
    │   ├── For subgroups: Complex COUNT with joins
    │   │   ├── COUNT std_student_academic_sessions
    │   │   ├── JOIN sch_subject_group_subject_jnt
    │   │   ├── JOIN sch_subject_groups
    │   │   └── WHERE subject_study_format_id matches
    │   └── Use batch updates of 500 records
    ├── UPDATE eligible_teacher_count (Performance Optimized)
    │   ├── From sch_teacher_capabilities with date range check
    │   ├── effective_from <= term_start_date
    │   ├── effective_to >= term_end_date
    │   └── COUNT DISTINCT teacher_profile_id
    └── Generate requirement statistics
        ├── Total groups and subgroups
        ├── Coverage percentage
        └── Missing teacher alerts

### 2.3 Requirement Consolidation (Transaction-based)
    ├── TRUNCATE tt_requirement_consolidation
    ├── BEGIN TRANSACTION
    │   ├── Step 1: INSERT from tt_class_requirement_groups
    │   │   ├── Select all fields with JOIN to sch_class_groups_jnt
    │   │   ├── Include period requirements from source
    │   │   └── Set academic_term_id and timetable_type_id
    │   ├── Step 2: INSERT from tt_class_requirement_subgroups
    │   │   ├── Include is_shared_across_sections/classes flags
    │   │   └── Same field mapping as groups
    │   ├── Step 3: Calculate derived metrics
    │   │   ├── resource_scarcity_index = 1/eligible_teacher_count
    │   │   ├── teacher_scarcity_index = required_weekly_periods / avg_teacher_load
    │   │   └── preliminary_difficulty = (100 - (eligible_teacher_count * 20))
    │   └── COMMIT
    └── Handle exceptions with rollback and logging

### 2.4 User Modification Interface
    ├── Present editable fields to user
    │   ├── preferred_periods_json (multi-select periods)
    │   ├── avoid_periods_json (multi-select periods to avoid)
    │   ├── spread_evenly (boolean)
    │   ├── preferred_days_json (multi-select days)
    │   ├── avoid_days_json (multi-select days)
    │   └── manual_priority_override (1-100)
    ├── Validate user inputs
    │   ├── No conflicting preferences (same period in both)
    │   ├── Preferred periods within available slots
    │   └── Priority between 1-100
    └── Save to tt_requirement_consolidation_details

### 2.5 Requirement Validation & Sign-off
    ├── Generate requirement summary report
    │   ├── Total periods required vs available
    │   ├── Teacher requirement distribution
    │   ├── Room requirement summary
    │   └── Potential constraint conflicts
    ├── Flag requirements with issues
    │   ├── No eligible teachers
    │   ├── Insufficient room capacity
    │   └── Over-allocated periods
    └── Require user confirmation before proceeding


## PHASE 3: RESOURCE AVAILABILITY PREPARATION (Enhanced)
══════════════════════════════════════════════════════════
### 3.1 Teacher Availability (Optimized Bulk Operations)
    ├── TRUNCATE tt_teacher_availability
    ├── Step 1: Bulk INSERT with LEFT JOIN
    │   ├── FROM tt_requirement_consolidation (base)
    │   ├── LEFT JOIN sch_teacher_capabilities (matching teachers)
    │   │   ├── ON class_id, subject_study_format_id
    │   │   └── effective_from <= timetable_end_date
    │   │   └── effective_to >= timetable_start_date
    │   ├── LEFT JOIN sch_teachers_profile (teacher details)
    │   ├── Include all availability metrics
    │   └── Use INSERT SELECT for performance
    ├── Step 2: Calculate allocated periods (Batch Update)
    │   ├── UPDATE max_allocated_periods_weekly
    │   │   └── SUM(required_weekly_periods) OVER (PARTITION BY teacher_id)
    │   ├── UPDATE min_allocated_periods_weekly
    │   │   └── MAX(required_weekly_periods) OVER (PARTITION BY teacher_id, class_id)
    │   └── Use window functions for efficiency
    ├── Step 3: Calculate availability scores
    │   ├── min_teacher_availability_score = 
    │   │   (min_available_periods_weekly / NULLIF(min_allocated_periods_weekly, 0)) * 100
    │   ├── max_teacher_availability_score = 
    │   │   (max_available_periods_weekly / NULLIF(max_allocated_periods_weekly, 0)) * 100
    │   └── weighted_availability_score = 
    │       (min_score * 0.3) + (max_score * 0.7)
    ├── Step 4: Apply teacher unavailability constraints
    │   ├── UPDATE availability based on tt_teacher_unavailable
    │   │   ├── Mark specific periods as unavailable
    │   │   └── Reduce available period counts
    │   └── Handle recurring unavailability patterns
    └── Step 5: Generate teacher availability heatmap
        ├── Visual representation per teacher
        ├── Free periods distribution
        └── Workload balance indicators

### 3.2 Room Availability (Enhanced)
    ├── TRUNCATE tt_room_availability
    ├── INSERT room availability with capacity tracking
    │   ├── FROM sch_rooms with room_type details
    │   ├── Calculate total_rooms_in_category
    │   ├── Set overall_availability_status
    │   └── Flag class_house_rooms
    ├── Calculate room capacity metrics
    │   ├── capacity vs max_limit
    │   ├── current_occupancy tracking
    │   └── utilization_target
    ├── Apply room unavailability (tt_room_unavailable)
    │   ├── Mark specific periods unavailable
    │   ├── Handle maintenance schedules
    │   └── Apply recurring patterns
    └── Generate room utilization forecast

### 3.3 Constraint Application (Comprehensive)
    ├── Load tt_constraint_category_scope (system-defined)
    │   ├── Categories: TEACHER, CLASS, ACTIVITY, ROOM, STUDENT, GLOBAL
    │   └── Scopes: GLOBAL, INDIVIDUAL, GROUP, PAIR
    ├── Load tt_constraint_type with parameter schemas
    │   ├── TEACHER_MAX_DAILY (hard, weight=100)
    │   ├── TEACHER_MAX_WEEKLY (hard, weight=100)
    │   ├── CLASS_MAX_PER_DAY (hard, weight=100)
    │   ├── ACTIVITY_CONSECUTIVE (hard, weight=100)
    │   ├── TEACHER_PREFERRED_TIME (soft, weight=40)
    │   └── 50+ constraint types from refined list
    ├── Apply tt_constraint instances
    │   ├── Validate parameters against schema
    │   ├── Check effective dates
    │   └── Calculate impact_score
    ├── Apply tt_teacher_unavailable (specialized)
    │   ├── Create constraint for each unavailability
    │   └── Link to parent constraint
    ├── Apply tt_room_unavailable (specialized)
    └── Generate constraint summary
        ├── Hard constraints count
        ├── Soft constraints count
        └── Estimated difficulty impact

### 3.4 Resource Scoring & Prioritization
    ├── Calculate teacher preference scores
    │   ├── is_primary_teacher → +30 points
    │   ├── is_preferred_teacher → +20 points
    │   ├── proficiency_percentage → direct score
    │   └── historical_success_ratio → weight factor
    ├── Calculate room suitability scores
    │   ├── capacity_match → (student_count / capacity) * 100
    │   ├── equipment_match → based on required tags
    │   └── location_score → building proximity
    └── Update tt_teacher_availability with final scores

### 3.5 Availability Validation Report
    ├── Teacher coverage analysis
    │   ├── Teachers with insufficient availability
    │   ├── Over-allocated teachers
    │   └── Under-utilized teachers
    ├── Room coverage analysis
    │   ├── Room types with shortage
    │   ├── Peak usage predictions
    │   └── Capacity constraints
    └── Constraint impact assessment
        ├── Most restrictive constraints
        ├── Potential conflict hotspots
        └── Generation difficulty prediction


## PHASE 4: Validation (Requirement vs. Availability) - ENHANCED
══════════════════════════════════════════════════════════════════════════════
### 4.1 Comprehensive Validation Framework
    ├── Create validation session record
    │   ├── session_id, timestamp
    │   ├── validation scope (full/partial)
    │   └── validation parameters
    ├── Run parallel validation checks
    │   ├── Teacher availability check
    │   ├── Room availability check
    │   ├── Constraint compatibility check
    │   └── Resource capacity check
    └── Track validation progress

### 4.2 Validate Teachers Availability (Enhanced)
    ├── Calculate teacher effective availability
    │   ├── In `sch_teacher_capabilities` check effective_from vs timetable dates
    │   ├── CASE WHEN effective_from > timetable_end_date → 'NOT_AVAILABLE'
    │   ├── CASE WHEN effective_to < timetable_end_date AND effective_to > start_date → 'PARTIAL_AVAILABLE'
    │   ├── CASE WHEN effective_to < timetable_start_date → 'FULLY_AVAILABLE'
    │   └── Store availability_status in tt_teacher_availability
    ├── Calculate max/min available periods with constraints
    │   ├── Subtract unavailable periods from tt_teacher_unavailable
    │   ├── Consider part-time status
    │   └── Account for preferred shift limitations
    ├── Calculate Class+Subject wise Period Requirement vs Availability
    │   ├── GROUP BY class_id, subject_study_format_id
    │   ├── SUM required_weekly_periods as total_required
    │   ├── SUM max_available_periods as total_available
    │   └── Calculate coverage_ratio = total_available / total_required
    ├── Calculate Period Availability Score
    │   ├── availability_score = (available_periods / required_periods) * 100
    │   ├── IF availability_score < 100 → 'PARTIAL_COVERAGE'
    │   ├── IF availability_score < 70 → 'CRITICAL_SHORTAGE'
    │   └── IF availability_score = 0 → 'NO_COVERAGE' (Validation Failed)
    └── Generate teacher validation matrix
        ├── Teacher vs Subject heatmap
        ├── Availability timeline
        └── Gap analysis

### 4.3 Validate Rooms Availability (Enhanced)
    ├── Calculate available rooms per room type
    │   ├── COUNT rooms by room_type_id
    │   ├── Subtract rooms under maintenance
    │   └── Consider concurrent usage limits
    ├── Calculate room requirement per period
    │   ├── For each period slot, count activities requiring rooms
    │   ├── GROUP BY room_type_id, day_of_week, period_ord
    │   └── Identify peak demand periods
    ├── Room capacity validation
    │   ├── Compare student_count vs room.capacity
    │   ├── Flag rooms where student_count > capacity
    │   └── Suggest alternative room types
    └── Generate room validation report
        ├── Room type shortage periods
        ├── Capacity violation alerts
        └── Utilization projections

### 4.4 Constraint Compatibility Check
    ├── Validate constraint combinations
    │   ├── Check for conflicting constraints on same target
    │   ├── Identify mutually exclusive constraints
    │   └── Flag impossible constraint combinations
    ├── Calculate constraint satisfaction feasibility
    │   ├── For each activity, count applicable constraints
    │   ├── Estimate minimum slots required vs available
    │   └── Predict constraint violation probability
    └── Generate constraint compatibility matrix

### 4.5 Validation Scoring & Decision
    ├── Calculate Overall Validation Score
    │   ├── Teacher availability weight: 40%
    │   ├── Room availability weight: 30%
    │   ├── Constraint compatibility weight: 20%
    │   └── Resource capacity weight: 10%
    ├── Determine Validation Status
    │   ├── PASSED (score >= 90 AND no critical failures)
    │   ├── PASSED_WITH_WARNINGS (score >= 70 AND no hard failures)
    │   ├── FAILED (score < 70 OR any critical failure)
    │   └── BLOCKED (fatal errors preventing generation)
    ├── Generate Validation Report with Recommendations
    │   ├── List all failures with severity
    │   ├── Provide resolution suggestions
    │   │   ├── Adjust teacher assignments
    │   │   ├── Modify room allocations
    │   │   ├── Relax constraints
    │   │   └── Split activities
    │   └── Estimate required changes
    └── Update validation_status in tt_timetable

### 4.6 Manual Intervention & Resolution
    ├── If validation FAILED:
    │   ├── Present detailed validation report to user
    │   ├── Allow manual overrides with justification
    │   │   ├── Force proceed despite warnings
    │   │   ├── Temporarily disable certain constraints
    │   │   └── Adjust resource availability manually
    │   ├── Track all overrides in validation log
    │   └── Re-run validation after changes
    └── If validation PASSED:
        ├── Lock validation results
        ├── Proceed to Activity Creation
        └── Store validation snapshot for audit


## PHASE 5: ACTIVITY CREATION & PRIORITIZATION (Enhanced with Scoring)
══════════════════════════════════════════════════════════════════════════════
### 5.1 Activity Generation (Bulk Optimized)
    ├── TRUNCATE tt_activity for target term+type
    ├── BEGIN TRANSACTION
    │   ├── INSERT from tt_requirement_consolidation
    │   │   ├── Map all requirement fields
    │   │   ├── Generate unique UUID and code
    │   │   ├── Set default status = 'DRAFT'
    │   │   └── Calculate base fields
    │   ├── Calculate duration_periods from study_format
    │   │   ├── LECTURE/THEORY → duration=1
    │   │   ├── LAB/PRACTICAL → duration=2
    │   │   └── ACTIVITY/SPORTS → duration=1
    │   ├── Set weekly_occurrences = required_weekly_periods / duration_periods
    │   ├── Calculate total_periods = duration_periods * weekly_occurrences
    │   └── COMMIT
    └── Generate activity summary
        ├── Total activities created
        ├── Split by subject type
        └── Duration distribution

### 5.2 Difficulty Score Calculation (Enhanced Formula)
    ├── Calculate Teacher Scarcity Component (35%)
    │   ├── eligible_teacher_count < 3 → +30 points × 0.35
    │   ├── eligible_teacher_count = 3-4 → +20 points × 0.35
    │   ├── eligible_teacher_count = 5-6 → +10 points × 0.35
    │   └── eligible_teacher_count > 6 → +5 points × 0.35
    ├── Calculate Compulsory Component (20%)
    │   ├── is_compulsory = 1 → +20 points × 0.20
    │   └── is_compulsory = 0 → 0 points
    ├── Calculate Workload Component (15%)
    │   ├── required_weekly_periods > 6 → +25 points × 0.15
    │   ├── required_weekly_periods > 4 → +20 points × 0.15
    │   ├── required_weekly_periods > 2 → +15 points × 0.15
    │   └── required_weekly_periods <= 2 → +5 points × 0.15
    ├── Calculate Room Requirement Component (15%)
    │   ├── compulsory_specific_room_type = 1 → +20 points × 0.15
    │   ├── required_room_id IS NOT NULL → +15 points × 0.15
    │   └── no room requirement → 0 points
    ├── Calculate Constraint Component (15%)
    │   ├── Count constraints affecting this activity
    │   ├── constraint_count > 5 → +25 points × 0.15
    │   ├── constraint_count > 3 → +15 points × 0.15
    │   ├── constraint_count > 1 → +10 points × 0.15
    │   └── constraint_count = 0 → 0 points
    └── FINAL_DIFFICULTY = SUM(all components) capped at 100

### 5.3 Priority Score Calculation (Multi-factor)
    ├── resource_scarcity = (required_resources / NULLIF(available_resources, 0))
    │   ├── Calculate from room availability
    │   ├── Normalize to 0-100 scale
    │   └── Weight: 25%
    ├── teacher_scarcity = (required_teachers / NULLIF(available_teachers, 0))
    │   ├── Based on eligible_teacher_count
    │   ├── 1/eligible_teacher_count normalized
    │   └── Weight: 25%
    ├── rigidity_score = (allowed_slots / NULLIF(total_slots, 0))
    │   ├── allowed_slots from preferred_periods_json
    │   ├── total_slots = working_days × periods_per_day
    │   └── Weight: 20% (inverse: 1 - rigidity_score)
    ├── workload_balance = (current_load / NULLIF(max_load, 0))
    │   ├── Based on teacher workload distribution
    │   └── Weight: 15%
    ├── subject_difficulty_index (from master)
    │   ├── 1-10 scale normalized to 0-100
    │   └── Weight: 15%
    └── FINAL_PRIORITY = (
            (resource_scarcity * 25) +
            (teacher_scarcity * 25) +
            ((1 - rigidity_score) * 20) +
            (workload_balance * 15) +
            (subject_difficulty_index * 15)
        ) / 100  (result 0-100)

### 5.4 Activity Prioritization & Sorting
    ├── Calculate priority for all activities (batch update)
    │   ├── UPDATE tt_activity SET calculated_priority = [formula]
    │   └── Allow manual_priority override
    ├── Set final_priority = COALESCE(manual_priority, calculated_priority)
    ├── Sort activities for generation
    │   ├── Primary sort: difficulty_score DESC
    │   ├── Secondary sort: final_priority DESC
    │   └── Tertiary sort: required_weekly_periods DESC
    └── Store sorting order for generation queue

### 5.5 Sub-Activity Creation (if needed)
    ├── Identify activities requiring splitting
    │   ├── duration_periods > 1 (e.g., Lab = 2 periods)
    │   ├── split_allowed = 1
    │   └── is_shared_across_sections = 1
    ├── Create tt_sub_activity records
    │   ├── Link to parent_activity_id
    │   ├── Set ordinal for sequencing
    │   ├── Generate unique code
    │   └── Define relationship rules
    │       ├── same_day_as_parent
    │       ├── consecutive_with_previous
    │       └── min_gap_from_previous
    └── Update parent activity: have_sub_activity = 1

### 5.6 Activity-Teacher Mapping
    ├── INSERT into tt_activity_teacher
    │   ├── FROM tt_teacher_availability
    │   ├── Map eligible teachers with roles
    │   ├── Set is_required based on constraints
    │   └── Calculate preference_score
    └── Generate teacher-activity matrix
        ├── Primary teachers per activity
        ├── Backup teachers
        └── Substitution candidates

### 5.7 Activity-Room Mapping
    ├── Identify room requirements per activity
    │   ├── compulsory_specific_room_type
    │   ├── required_room_id
    │   └── preferred_room_ids_json
    ├── Calculate eligible_room_count
    ├── Calculate room_availability_score
    └── Store in activity record

### 5.8 Activity Validation & Readiness Check
    ├── Verify each activity has:
    │   ├── At least one eligible teacher
    │   ├── Room availability if required
    │   ├── Valid duration and period requirements
    │   └── No constraint violations
    ├── Flag problematic activities
    │   ├── No teacher → CRITICAL
    │   ├── No room → HIGH
    │   ├── Over-constrained → MEDIUM
    │   └── Preference conflicts → LOW
    └── Generate activity readiness report
        ├── Ready for generation
        ├── Needs attention
        └── Blocked activities


## PHASE 6: TIMETABLE GENERATION (Enhanced with Multi-Algorithm)
══════════════════════════════════════════════════════════════════════════════
### 6.1 Generation Queue Management
    ├── INSERT into tt_generation_queue
    │   ├── Generate unique UUID
    │   ├── Link to timetable_id
    │   ├── Set priority based on requirements
    │   ├── Calculate estimated complexity
    │   │   ├── activity_count
    │   │   ├── constraint_count
    │   │   └── teacher_scarcity_index
    │   └── Set status = 'QUEUED'
    ├── Select tt_generation_strategy based on complexity
    │   ├── activity_count < 500 → 'RECURSIVE_FAST'
    │   ├── activity_count 500-1000 → 'HYBRID_BALANCED'
    │   ├── activity_count > 1000 → 'GENETIC_THOROUGH'
    │   └── complex_constraints > 50 → 'TABU_OPTIMIZED'
    └── Assign to queue worker (Laravel Job)

### 6.2 Generation Run Initialization
    ├── CREATE tt_timetable record (status = 'DRAFT')
    ├── CREATE tt_generation_run
    │   ├── status = 'QUEUED'
    │   ├── strategy_id from selected strategy
    │   ├── algorithm_version
    │   ├── params_json with strategy parameters
    │   └── triggered_by = current_user
    ├── Update generation_queue status = 'PROCESSING'
    ├── Lock timetable to prevent concurrent modifications
    └── Initialize metrics tracking
        ├── start_time
        ├── activities_total
        ├── placement_attempts = 0
        └── swaps_performed = 0

### 6.3 Algorithm Execution - PHASE 1: Initial Placement (Recursive CSP)
    ├── Load activities sorted by difficulty_score DESC
    ├── Load time slots (days × periods) from period_set
    ├── Load all constraints into memory (cached)
    ├── Initialize data structures
    │   ├── assignments array
    │   ├── conflicts array
    │   ├── forward_checking table
    │   └── domain_wipes counter
    ├── For each activity in sorted order:
    │   ├── Find available slots (forward checking)
    │   │   ├── Apply all constraints
    │   │   ├── Check teacher availability
    │   │   ├── Check room availability
    │   │   └── Filter by preferences
    │   ├── Score available slots
    │   │   ├── preference_match (40%)
    │   │   ├── teacher_preference (30%)
    │   │   ├── room_suitability (20%)
    │   │   └── workload_balance (10%)
    │   ├── If slot available:
    │   │   ├── Place activity in best slot
    │   │   ├── Update forward checking tables
    │   │   ├── Increment placement_attempts
    │   │   └── Continue to next activity
    │   ├── If no slot available:
    │   │   ├── Identify conflicting activities
    │   │   ├── Try recursive swapping (max depth = strategy.max_recursive_depth)
    │   │   │   ├── Select conflict candidates
    │   │   │   ├── Temporarily remove placed activity
    │   │   │   ├── Try placing current activity
    │   │   │   ├── If successful, re-place removed activity
    │   │   │   ├── If failed, try next candidate
    │   │   │   └── Increment swaps_performed
    │   │   ├── If swap successful:
    │   │   │   ├── Update assignments
    │   │   │   └── Continue
    │   │   └── If swap failed:
    │   │       ├── Add to conflict list
    │   │       ├── Log conflict details
    │   │       └── Continue to next activity
    │   └── Track progress (update generation_run.progress_percentage)
    ├── After initial placement:
    │   ├── Calculate placement_rate = (activities_placed / activities_total) × 100
    │   ├── If placement_rate < 70%:
    │   │   ├── Log as 'CRITICAL_PLACEMENT_ISSUE'
    │   │   └── Trigger advanced conflict resolution
    │   └── Store intermediate results
    └── Update generation_run stats

### 6.4 Algorithm Execution - PHASE 2: Conflict Resolution (Tabu Search)
    ├── IF conflicts exist AND strategy.algorithm_type IN ('TABU_SEARCH', 'HYBRID')
    ├── Initialize Tabu Search
    │   ├── tabu_list = [] (size = strategy.tabu_size)
    │   ├── current_solution = assignments from Phase 1
    │   ├── best_solution = current_solution
    │   ├── best_score = evaluate_solution(current_solution)
    │   └── iteration = 0
    ├── WHILE iteration < strategy.max_iterations AND conflicts remain:
    │   ├── Generate neighborhood
    │   │   ├── Focus on conflicting activities
    │   │   ├── Generate alternative placements
    │   │   └── Limit to max 50 neighbors per iteration
    │   ├── Evaluate neighbors (skip tabu moves unless aspiration)
    │   │   ├── Calculate neighbor_score
    │   │   ├── Check if move is in tabu_list
    │   │   ├── Apply aspiration if better than best
    │   │   └── Select best non-tabu neighbor
    │   ├── Apply best move
    │   │   ├── Update current_solution
    │   │   ├── Add move to tabu_list
    │   │   ├── Update conflicts list
    │   │   └── Increment swaps_performed
    │   ├── Check for improvement
    │   │   ├── IF neighbor_score > best_score:
    │   │   │   ├── best_solution = current_solution
    │   │   │   ├── best_score = neighbor_score
    │   │   │   └── reset_stagnation_counter
    │   │   └── ELSE:
    │   │       └── increment_stagnation_counter
    │   ├── IF stagnation_counter > 50:
    │   │   ├── Apply diversification (random shake)
    │   │   └── reset_stagnation_counter
    │   ├── iteration++
    │   └── Update progress (40-60%)
    ├── After Tabu Search:
    │   ├── conflicts_resolved = initial_conflicts - current_conflicts
    │   ├── resolution_rate = (conflicts_resolved / initial_conflicts) × 100
    │   └── Update generation_run with results
    └── Store best_solution as current assignments

### 6.5 Algorithm Execution - PHASE 3: Optimization (Simulated Annealing)
    ├── IF strategy.algorithm_type IN ('SIMULATED_ANNEALING', 'HYBRID')
    ├── Initialize Simulated Annealing
    │   ├── current_solution = assignments from Phase 2
    │   ├── current_score = evaluate_solution(current_solution)
    │   ├── best_solution = current_solution
    │   ├── best_score = current_score
    │   ├── temperature = strategy.initial_temperature (default: 100.0)
    │   ├── min_temperature = strategy.min_temperature (default: 1.0)
    │   └── cooling_rate = strategy.cooling_rate (default: 0.95)
    ├── WHILE temperature > min_temperature:
    │   ├── FOR i = 1 TO strategy.iterations_per_temp (default: 100):
    │   │   ├── Generate neighbor (random swap of two activities)
    │   │   │   ├── Select two random activities
    │   │   │   ├── Check if swap is valid
    │   │   │   └── Create neighbor_solution
    │   │   ├── neighbor_score = evaluate_solution(neighbor_solution)
    │   │   ├── delta = neighbor_score - current_score
    │   │   ├── IF delta > 0:
    │   │   │   ├── current_solution = neighbor_solution
    │   │   │   ├── current_score = neighbor_score
    │   │   │   ├── IF neighbor_score > best_score:
    │   │   │   │   ├── best_solution = neighbor_solution
    │   │   │   │   └── best_score = neighbor_score
    │   │   │   └── increment_improvements
    │   │   └── ELSE:
    │   │       ├── probability = exp(delta / temperature)
    │   │       ├── IF random() < probability:
    │   │       │   ├── current_solution = neighbor_solution
    │   │       │   └── current_score = neighbor_score
    │   │       └── increment_attempts
    │   ├── temperature = temperature * cooling_rate
    │   └── Update progress (60-80%)
    ├── After Simulated Annealing:
    │   ├── improvement = ((best_score - initial_score) / initial_score) × 100
    │   └── Update generation_run with optimization metrics
    └── Set assignments = best_solution

### 6.6 Algorithm Execution - PHASE 4: Global Optimization (Genetic Algorithm)
    ├── IF strategy.algorithm_type IN ('GENETIC', 'HYBRID') AND 
    │    (activity_count > 1000 OR improvement < 5%)
    ├── Initialize Genetic Algorithm
    │   ├── population_size = strategy.population_size (default: 50)
    │   ├── generations = strategy.generations (default: 100)
    │   ├── mutation_rate = strategy.mutation_rate (default: 0.1)
    │   ├── crossover_rate = strategy.crossover_rate (default: 0.8)
    │   ├── elite_count = strategy.elite_count (default: 5)
    │   ├── Initialize population from current solution + variations
    │   └── Evaluate fitness for all individuals
    ├── FOR generation = 1 TO generations:
    │   ├── Selection (Tournament selection)
    │   │   ├── Select parents based on fitness
    │   │   └── Keep elite individuals
    │   ├── Crossover (Order-based crossover for timetables)
    │   │   ├── With probability crossover_rate
    │   │   ├── Create offspring from parents
    │   │   └── Ensure valid timetables
    │   ├── Mutation (Swap mutation)
    │   │   ├── With probability mutation_rate
    │   │   ├── Randomly swap activities
    │   │   └── Validate after mutation
    │   ├── Evaluate new population
    │   │   ├── Calculate fitness scores
    │   │   ├── Track best fitness
    │   │   └── Calculate diversity metrics
    │   ├── Replace population
    │   │   ├── Replace least fit with offspring
    │   │   └── Maintain population size
    │   └── Update progress (80-95%)
    ├── After Genetic Algorithm:
    │   ├── Select best individual
    │   ├── Calculate final_fitness
    │   └── Update generation_run with GA metrics
    └── Set assignments = best_individual

### 6.7 Solution Evaluation Function
    ├── Calculate Hard Constraint Score (Must be 0)
    │   ├── For each hard constraint
    │   ├── Count violations
    │   ├── IF violations > 0: score = -1000 × violations
    │   └── ELSE: proceed to soft constraints
    ├── Calculate Soft Constraint Score (Weighted)
    │   ├── teacher_preferences_satisfied (weight × satisfaction_rate)
    │   ├── room_preferences_satisfied (weight × satisfaction_rate)
    │   ├── workload_balance_score (weight × balance_rate)
    │   ├── student_gap_minimization (weight × gap_score)
    │   └── subject_distribution_score (weight × distribution_rate)
    ├── Calculate Optimization Goals
    │   ├── teacher_utilization_rate
    │   ├── room_utilization_rate
    │   └── overall_compactness_score
    └── Return total_score (0-10000 scale)

### 6.8 Conflict Detection & Logging
    ├── Track all conflicts in tt_conflict_detection
    │   ├── conflict_type (HARD/SOFT)
    │   ├── conflicting_activities
    │   ├── resource_conflicts
    │   ├── time_slot_conflicts
    │   └── constraint_violations
    ├── For each unresolved conflict:
    │   ├── Analyze root cause
    │   ├── Suggest resolution options
    │   │   ├── Swap with another activity
    │   │   ├── Move to different day
    │   │   ├── Split activity
    │   │   └── Relax constraint
    │   └── Store suggestions in resolution_suggestions_json
    └── Update conflict statistics

### 6.9 Constraint Violation Tracking
    ├── For each constraint:
    │   ├── Check if violated in final solution
    │   ├── Count violations
    │   ├── Record violation details
    │   └── Store in tt_constraint_violation
    ├── Categorize violations
    │   ├── HARD: Must be fixed before publication
    │   ├── SOFT: Can be accepted with justification
    │   └── OPTIMIZATION: Targets not met
    └── Calculate violation impact score

### 6.10 Resource Booking Recording
    ├── For each placed activity:
    │   ├── Create tt_resource_booking records
    │   │   ├── resource_type = 'TEACHER'
    │   │   ├── resource_id = teacher_id
    │   │   ├── booking_date, day_of_week, period_ord
    │   │   └── status = 'BOOKED'
    │   ├── Create room booking if applicable
    │   │   ├── resource_type = 'ROOM'
    │   │   ├── resource_id = room_id
    │   │   └── same time slot details
    │   └── Link to timetable_cell_id
    └── Update resource availability

### 6.11 Generation Completion & Stats
    ├── Update tt_generation_run
    │   ├── status = 'COMPLETED' (or 'FAILED')
    │   ├── finished_at = NOW()
    │   ├── activities_placed = COUNT(placed)
    │   ├── activities_failed = COUNT(conflicts)
    │   ├── hard_violations = COUNT(hard)
    │   ├── soft_violations = COUNT(soft)
    │   ├── soft_score = calculated_score
    │   └── stats_json with all metrics
    ├── Populate tt_timetable_cell
    │   ├── Create cell for each placed activity
    │   │   ├── timetable_id, generation_run_id
    │   │   ├── day_of_week, period_ord
    │   │   ├── activity_id, class_id, section_id
    │   │   ├── room_id, subject_study_format_id
    │   │   └── source = 'AUTO'
    │   └── Bulk insert for performance
    ├── Populate tt_timetable_cell_teacher
    │   ├── Link teachers to cells
    │   └── Set assignment_role_id
    ├── Update tt_timetable
    │   ├── status = 'GENERATED'
    │   ├── generated_at = NOW()
    │   ├── total_activities = activities_total
    │   ├── placed_activities = activities_placed
    │   ├── failed_activities = activities_failed
    │   ├── hard_violations, soft_violations
    │   ├── quality_score = calculated
    │   └── stats_json with generation summary
    └── Update generation_queue status = 'COMPLETED'


## PHASE 7: POST-GENERATION PROCESSING (Enhanced Analytics)
══════════════════════════════════════════════════════════════════════════════
### 7.1 Teacher Workload Analysis
    ├── Calculate teacher_workload in tt_teacher_workload
    │   ├── weekly_periods_assigned per teacher
    │   ├── daily_distribution_json
    │   ├── subjects_assigned_json
    │   ├── classes_assigned_json
    │   ├── utilization_percent = (assigned / max) × 100
    │   ├── gap_periods_total (free periods)
    │   ├── consecutive_max (max consecutive periods)
    │   └── preference_satisfaction_rate
    ├── Generate teacher workload dashboard
    │   ├── Overload alerts (>90% utilization)
    │   ├── Underload alerts (<50% utilization)
    │   ├── Gap analysis (too many/too few gaps)
    │   └── Distribution visualization
    └── Store last_calculated_at timestamp

### 7.2 Room Utilization Analysis
    ├── Calculate room_utilization in tt_room_utilization
    │   ├── total_periods_available = working_days × periods_per_day
    │   ├── total_periods_used = COUNT(bookings)
    │   ├── utilization_percent = (used / available) × 100
    │   ├── usage_by_type (lecture/lab/exam/activity)
    │   ├── avg_occupancy_rate = (avg_students / capacity) × 100
    │   ├── peak_usage_day (day with highest usage)
    │   └── peak_usage_period (period with highest usage)
    ├── Generate room utilization dashboard
    │   ├── Underutilized rooms (<60% utilization)
    │   ├── Overutilized rooms (>90% utilization)
    │   ├── Peak demand periods
    │   └── Capacity utilization heatmap
    └── Store last_calculated_at timestamp

### 7.3 Constraint Violation Analysis
    ├── Aggregate violations from tt_constraint_violation
    │   ├── Group by constraint_type
    │   ├── Count occurrences
    │   ├── Calculate severity distribution
    │   └── Identify most violated constraints
    ├── Generate violation report
    │   ├── Hard violations requiring attention
    │   ├── Soft violations for optimization
    │   └── Pattern analysis (time/day patterns)
    └── Store violation_summary in tt_timetable

### 7.4 Daily Snapshots
    ├── Create tt_analytics_daily_snapshot for each day
    │   ├── snapshot_date, academic_session_id
    │   ├── total_teachers_present
    │   ├── total_teachers_absent
    │   ├── total_classes_conducted
    │   ├── total_periods_scheduled
    │   ├── total_substitutions
    │   ├── violations_detected
    │   └── snapshot_data_json (detailed metrics)
    └── Store for trend analysis

### 7.5 Performance Metrics Dashboard
    ├── Overall timetable quality score
    │   ├── Teacher satisfaction (40%)
    │   ├── Room utilization (30%)
    │   ├── Constraint satisfaction (20%)
    │   └── Balance metrics (10%)
    ├── Comparative analysis
    │   ├── vs previous timetables
    │   ├── vs benchmarks
    │   └── vs targets
    └── Export to various formats (PDF, Excel, JSON)

### 7.6 Report Generation
    ├── Class-wise Timetable Report
    │   ├── Daily schedule view
    │   ├── Weekly overview
    │   └── Subject distribution
    ├── Teacher-wise Timetable Report
    │   ├── Daily schedule
    │   ├── Weekly workload
    │   └── Free periods
    ├── Room-wise Timetable Report
    │   ├── Daily occupancy
    │   ├── Weekly utilization
    │   └── Booking details
    └── Export options (HTML, PDF, CSV, XML)


## PHASE 8: MANUAL REFINEMENT (Enhanced with Impact Analysis)
══════════════════════════════════════════════════════════════════════════════
### 8.1 Timetable Viewing Interface
    ├── Multiple view options
    │   ├── Teacher-wise view
    │   │   ├── Daily schedule cards
    │   │   ├── Weekly grid
    │   │   ├── Workload summary
    │   │   └── Free period highlights
    │   ├── Class-wise view
    │   │   ├── Daily timetable
    │   │   ├── Subject distribution
    │   │   ├── Teacher allocation
    │   │   └── Room assignments
    │   ├── Room-wise view
    │   │   ├── Daily occupancy grid
    │   │   ├── Utilization charts
    │   │   └── Booking details
    │   ├── Subject-wise view
    │   │   ├── Distribution across classes
    │   │   ├── Teacher allocation
    │   │   └── Room requirements
    │   └── Day-wise view
    │       ├── School-wide overview
    │       ├── Period-by-period
    │       └── Resource allocation
    ├── Interactive features
    │   ├── Drag-and-drop movements
    │   ├── Conflict highlighting
    │   ├── Tooltip information
    │   └── Filter and search
    └── Color coding system
        ├── Subject-based colors
        ├── Teacher-based colors
        ├── Conflict indicators
        └── Lock indicators

### 8.2 Cell Lock/Unlock Management
    ├── User can lock/unlock cells (tt_timetable_cell.is_locked)
    │   ├── Lock single cell
    │   ├── Lock entire day for class/teacher
    │   ├── Lock by pattern (e.g., all Maths periods)
    │   └── Batch lock operations
    ├── Lock validation rules
    │   ├── Cannot lock already locked cell
    │   ├── Lock requires reason (optional)
    │   ├── Lock expiry optional
    │   └── Lock hierarchy (admin override)
    └── Track lock metadata
        ├── locked_by (user_id)
        ├── locked_at (timestamp)
        └── lock_reason (text)

### 8.3 Manual Adjustments with Impact Analysis
    ├── User initiates change (drag & drop)
    ├── System performs impact analysis before applying
    │   ├── Check teacher availability at new slot
    │   │   ├── Is teacher free?
    │   │   ├── Within workload limits?
    │   │   └── Any unavailability constraints?
    │   ├── Check room availability at new slot
    │   │   ├── Is room free?
    │   │   ├── Capacity sufficient?
    │   │   └── Room type compatible?
    │   ├── Check constraint violations
    │   │   ├── Hard constraints (must not violate)
    │   │   ├── Soft constraints (calculate impact)
    │   │   └── Chain reactions (if swap needed)
    │   ├── Identify affected parties
    │   │   ├── Teacher (new/old)
    │   │   ├── Class (new/old)
    │   │   ├── Room (new/old)
    │   │   └── Other activities impacted
    │   └── Calculate new scores
    │       ├── Before vs After comparison
    │       ├── Quality score delta
    │       └── Conflict risk assessment
    ├── Present impact report to user
    │   ├── Green (safe change)
    │   ├── Yellow (warning but allowed)
    │   ├── Red (blocked change)
    │   └── Recommendations for alternatives
    ├── User confirms or cancels
    └── If confirmed:
        ├── Apply change
        ├── Update all related records
        ├── Create change log entry
        └── Trigger re-validation

### 8.4 Batch Operations
    ├── Swap activities
    │   ├── Simple swap between two cells
    │   ├── Complex swap with validation
    │   ├── Chain swap (A→B, B→C, C→A)
    │   └── Batch swap multiple activities
    ├── Move activities
    │   ├── Single activity move
    │   ├── Move all activities of a teacher
    │   ├── Move all activities of a class
    │   └── Shift entire day
    ├── Substitute teacher
    │   ├── Replace teacher in selected cells
    │   ├── Auto-find best substitute
    │   └── Bulk substitution
    └── Apply preferences
        ├── Apply preferred periods
        ├── Apply avoid periods
        └── Optimize distribution

### 8.5 Change Tracking & Audit
    ├── Create tt_change_log entry for every change
    │   ├── change_type (UPDATE/SWAP/LOCK/SUBSTITUTE)
    │   ├── change_date, timestamp
    │   ├── old_values_json (snapshot before)
    │   ├── new_values_json (snapshot after)
    │   ├── reason (user-provided)
    │   ├── changed_by (user_id)
    │   └── metadata_json (additional context)
    ├── Support undo/redo operations
    │   ├── Track change sequence
    │   ├── Store reverse operations
    │   └── Allow rollback to version
    └── Version history
        ├── View change history
        ├── Compare versions
        └── Restore previous version

### 8.6 Conflict Resolution Workflow
    ├── Identify conflicts after manual changes
    │   ├── Real-time conflict detection
    │   ├── Highlight conflicting cells
    │   └── Group related conflicts
    ├── Present resolution options
    │   ├── Auto-resolve suggestions
    │   │   ├── Swap with another activity
    │   │   ├── Move to alternative slot
    │   │   ├── Split activity
    │   │   └── Relax constraint (with approval)
    │   ├── Manual resolution
    │   │   ├── Choose from alternatives
    │   │   ├── Override with justification
    │   │   └── Escalate to approver
    │   └── Each option shows impact
    ├── User selects resolution
    ├── Apply changes
    └── Log resolution in tt_conflict_detection

### 8.7 Re-validation After Changes
    ├── Trigger automatic re-validation
    │   ├── After each significant change
    │   ├── Batch after multiple changes
    │   └── On demand by user
    ├── Run validation checks
    │   ├── Hard constraint validation
    │   ├── Soft constraint scoring
    │   ├── Resource availability check
    │   └── Conflict detection
    ├── Update validation status
    │   ├── Passed (no hard violations)
    │   ├── Warning (soft violations)
    │   └── Failed (hard violations)
    └── Generate validation report

### 8.8 Locking & Freezing
    ├── User can lock/unlock cells
    │   ├── Individual cell lock
    │   ├── Batch lock (select multiple)
    │   ├── Lock by pattern
    │   └── Lock with expiry
    ├── Freeze entire timetable section
    │   ├── Freeze a day
    │   ├── Freeze teacher schedule
    │   ├── Freeze class schedule
    │   └── Freeze with approval workflow
    └── Track lock hierarchy
        ├── User locks
        ├── Admin overrides
        └── System locks (generated)


## PHASE 9: PUBLICATION & APPROVAL WORKFLOW
══════════════════════════════════════════════════════════════════════════════
### 9.1 Pre-Publication Quality Check
    ├── Run final validation suite
    │   ├── Hard constraint check (must be 0)
    │   ├── Soft constraint score calculation
    │   ├── Resource conflict check
    │   ├── Completeness check (all activities placed)
    │   └── Consistency check (no orphaned records)
    ├── Calculate final quality metrics
    │   ├── overall_quality_score (0-100)
    │   ├── teacher_satisfaction_score
    │   ├── room_utilization_score
    │   ├── constraint_satisfaction_rate
    │   └── comparison_with_targets
    ├── Generate pre-publication report
    │   ├── Summary of violations
    │   ├── Risk assessment
    │   ├── Recommendations
    │   └── Sign-off requirements
    └── Update tt_timetable.validation_status

### 9.2 Approval Workflow
    ├── Define approval hierarchy
    │   ├── Level 1: Timetable Coordinator
    │   ├── Level 2: Academic Head
    │   ├── Level 3: Principal
    │   └── Level 4: Management (if required)
    ├── Route for approvals based on:
    │   ├── Quality score thresholds
    │   ├── Number of violations
    │   ├── Overrides applied
    │   └── Manual changes count
    ├── For each approver:
    │   ├── Send notification
    │   ├── Provide approval dashboard
    │   │   ├── Timetable views
    │   │   ├── Validation reports
    │   │   ├── Change logs
    │   │   └── Comparison with previous
    │   ├── Approve/Reject/Request Changes
    │   ├── Add comments/conditions
    │   └── Track decision in approval log
    └── Update approval status
        ├── PENDING_APPROVAL
        ├── APPROVED
        ├── REJECTED
        ├── CHANGES_REQUESTED
        └── PARTIALLY_APPROVED

### 9.3 Publication
    ├── Update tt_timetable.status = 'PUBLISHED'
    ├── Set published_at = NOW()
    ├── Set published_by = current_user
    ├── Generate publication version
    │   ├── Increment version number
    │   ├── Create snapshot of published version
    │   └── Archive previous version if exists
    ├── Generate publication artifacts
    │   ├── HTML outputs (for web viewing)
    │   │   ├── Teacher view
    │   │   ├── Class view
    │   │   ├── Room view
    │   │   └── Combined view
    │   ├── PDF outputs (for printing)
    │   │   ├── Individual teacher schedules
    │   │   ├── Class timetables
    │   │   ├── Room booking schedules
    │   │   └── School master timetable
    │   ├── CSV/Excel exports (for analysis)
    │   │   ├── Raw data export
    │   │   ├── Pivot tables
    │   │   └── Analytics data
    │   └── XML/JSON exports (for integration)
    │       ├── API format
    │       ├── Integration with other systems
    │       └── Backup format
    └── Store artifacts in media library

### 9.4 Notification & Distribution
    ├── Identify notification recipients
    │   ├── All teachers
    │   ├── Class teachers
    │   ├── Department heads
    │   ├── Admin staff
    │   └── Students/Parents (via parent portal)
    ├── Send notifications
    │   ├── Email with personalized schedule
    │   ├── SMS for critical changes
    │   ├── Push notifications (mobile app)
    │   ├── In-app notifications
    │   └── Digest for multiple recipients
    ├── Provide access mechanisms
    │   ├── Web portal login
    │   ├── Mobile app
    │   ├── Printable format
    │   └── Calendar integration (ICS files)
    └── Track notification delivery
        ├── sent_at
        ├── delivered_at
        ├── opened_at
        └── read_receipt (if available)

### 9.5 Post-Publication Support
    ├── Enable feedback mechanism
    │   ├── Report issues
    │   ├── Request changes
    │   ├── Suggest improvements
    │   └── Track resolution
    ├── Handle change requests
    │   ├── Evaluate impact
    │   ├── Route for approval
    │   ├── Apply if approved
    │   └── Notify affected parties
    └── Monitor usage
        ├── Access logs
        ├── Download statistics
        ├── Issue reports
        └── Satisfaction surveys


## PHASE 10: SUBSTITUTION MANAGEMENT (Enhanced with ML)
══════════════════════════════════════════════════════════════════════════════
### 10.1 Absence Recording
    ├── Create tt_teacher_absence record
    │   ├── teacher_id, absence_date
    │   ├── absence_type (LEAVE/SICK/TRAINING/DUTY)
    │   ├── start_period, end_period (or full_day)
    │   ├── reason, document_proof
    │   ├── contact_during_absence
    │   ├── status (PENDING/APPROVED/REJECTED)
    │   └── substitution_required = 1
    ├── Approval workflow for absence
    │   ├── Notify approver
    │   ├── Approve/Reject with comments
    │   ├── Update status
    │   └── Notify teacher of decision
    └── Auto-detect conflicts
        ├── Check for overlapping absences
        ├── Check for critical coverage issues
        └── Flag for immediate attention

### 10.2 Affected Cell Identification
    ├── Query tt_timetable_cell for affected periods
    │   ├── WHERE teacher_id = absent_teacher
    │   ├── AND date = absence_date
    │   ├── AND period_ord BETWEEN start_period AND end_period
    │   └── AND is_active = 1
    ├── Group cells by:
    │   ├── class_id, section_id
    │   ├── subject_study_format_id
    │   ├── day_of_week, period_ord
    │   └── activity_id
    ├── Calculate impact score
    │   ├── Number of classes affected
    │   ├── Critical subjects affected
    │   ├── Exam/Test impact
    │   └── Chain reaction potential
    └── Prioritize substitution needs

### 10.3 Eligible Teacher Search (Multi-factor)
    ├── Query eligible teachers from sch_teacher_capabilities
    │   ├── Same subject_study_format_id
    │   ├── class_id in capabilities or general
    │   ├── effective_from <= absence_date
    │   ├── effective_to >= absence_date
    │   └── is_active = 1
    ├── Filter by availability at that time slot
    │   ├── Check tt_teacher_availability_detail
    │   ├── No existing assignment at that time
    │   ├── Not absent themselves
    │   └── Available for substitution (can_be_used_for_substitution)
    ├── Filter by workload limits
    │   ├── Not exceeding max_allocated_periods_weekly
    │   ├── Daily load within limits
    │   └── Gap requirements satisfied
    ├── Check for conflicts
    │   ├── No conflicting assignments
    │   ├── No overlapping classes
    │   └── Room availability if needed
    └── Score each candidate (0-100)

### 10.4 Compatibility Scoring (Enhanced)
    ├── Proficiency Score (35%)
    │   ├── proficiency_percentage (direct)
    │   ├── competency_level mapping
    │   │   ├── Expert → 100
    │   │   ├── Advanced → 85
    │   │   ├── Intermediate → 70
    │   │   ├── Basic → 50
    │   │   └── Facilitator → 30
    │   └── is_primary_subject → +20 points
    ├── Historical Success Score (25%)
    │   ├── historical_success_ratio from profile
    │   ├── last_allocation_score from previous
    │   └── pattern_match_score from ML
    ├── Experience Score (15%)
    │   ├── teaching_experience_months normalized
    │   ├── years at this school
    │   └── familiarity with class
    ├── Availability Score (15%)
    │   ├── current_workload vs max
    │   ├── free_periods_remaining
    │   └── distance from current location
    └── Preference Score (10%)
        ├── preferred_subjects_match
        ├── preferred_classes_match
        ├── preferred_shifts_match
        └── previous_substitution_success

### 10.5 ML-Based Pattern Learning
    ├── Load historical substitution patterns
    │   ├── tt_substitution_pattern table
    │   ├── Group by (subject, class, teacher combinations)
    │   └── Calculate success_rate
    ├── Apply pattern matching
    │   ├── Find similar past substitutions
    │   ├── Weight by recency and success
    │   ├── Adjust scores based on patterns
    │   └── Boost scores for proven combinations
    ├── Update pattern database
    │   ├── Record successful substitutions
    │   ├── Update success_count, total_count
    │   ├── Recalculate success_rate
    │   └── Store context factors
    └── Continuous learning
        ├── Track substitution effectiveness
        ├── Gather feedback ratings
        ├── Identify best-fit scenarios
        └── Improve scoring algorithm

### 10.6 Recommendation Generation
    ├── Generate tt_substitution_recommendation for each affected cell
    │   ├── teacher_absence_id, cell_id
    │   ├── recommended_teacher_id
    │   ├── all component scores
    │   ├── overall_compatibility_score
    │   ├── compatibility_factors_json
    │   ├── conflicts_json (if any)
    │   └── ranking (1 = best)
    ├── Sort recommendations by score
    │   ├── Primary sort: overall_compatibility_score DESC
    │   ├── Secondary sort: proficiency_score DESC
    │   └── Tertiary sort: availability_score DESC
    ├── Present recommendations to user
    │   ├── Top 3-5 recommendations per cell
    │   ├── Visual comparison of options
    │   ├── Pros and cons for each
    │   └── Estimated success probability
    └── Allow manual override
        ├── User can select any eligible teacher
        ├── Can ignore recommendations
        ├── Must provide reason for override
        └── Track override patterns

### 10.7 Substitution Assignment
    ├── User selects substitute teacher
    │   ├── From recommendations
    │   ├── Manual selection
    │   └── Bulk assignment (multiple cells)
    ├── Create tt_substitution_log entry
    │   ├── teacher_absence_id, cell_id
    │   ├── substitution_date
    │   ├── absent_teacher_id, substitute_teacher_id
    │   ├── original_teacher_id (if different)
    │   ├── assignment_method (AUTO/MANUAL/SWAP)
    │   ├── reason (user-provided)
    │   ├── status = 'ASSIGNED'
    │   ├── notified_at = NOW()
    │   └── assigned_by = current_user
    ├── Update timetable
    │   ├── Update tt_timetable_cell_teacher
    │   │   ├── Set is_substitute = 1
    │   │   ├── Link to substitution_log_id
    │   │   └── Update teacher_id
    │   ├── Mark cell as has_conflict = 0 (if resolved)
    │   └── Add change_log entry
    ├── Send notifications
    │   ├── To substitute teacher
    │   ├── To absent teacher
    │   ├── To class teacher (if applicable)
    │   └── To admin (if configured)
    └── Track acceptance
        ├── accepted_at (if substitute accepts)
        ├── rejected_at (if declines)
        ├── completed_at (after class)
        └── feedback (from substitute/class)

### 10.8 Post-Substitution Workflow
    ├── Track substitution effectiveness
    │   ├── Class feedback
    │   ├── Teacher feedback
    │   ├── Student performance impact
    │   └── Overall satisfaction rating
    ├── Update historical data
    │   ├── Update teacher historical_success_ratio
    │   ├── Update substitution_pattern
    │   │   ├── Increment total_count
    │   │   ├── Increment success_count if successful
    │   │   └── Recalculate success_rate
    │   └── Store effectiveness rating
    ├── Handle declined substitutions
    │   ├── Auto-find next best candidate
    │   ├── Escalate to admin
    │   └── Trigger contingency plan
    └── Generate substitution reports
        ├── Daily substitution summary
        ├── Teacher substitution history
        ├── Pattern analysis
        └── Effectiveness metrics

### 10.9 Emergency Substitution Handling
    ├── Same-day absence (urgent)
    │   ├── Immediate notification to all eligible
    │   ├── First-come-first-served basis
    │   ├── Auto-assign if configured
    │   └── Escalate to on-call substitute
    ├── Multiple absences same day
    │   ├── Prioritize critical subjects
    │   ├── Balance workload across substitutes
    │   ├── Consider class continuity
    │   └── Alert admin if shortage
    └── No substitute found
        ├── Class merge options
        ├── Self-study arrangements
        ├── Supervisor coverage
        └── Emergency protocol

### 10.10 Analytics & Reporting
    ├── Substitution metrics dashboard
    │   ├── Substitution rate (per day/week)
    │   ├── Success rate
    │   ├── Average response time
    │   ├── Most substituted subjects
    │   ├── Most reliable substitutes
    │   └── Cost impact (if applicable)
    ├── Teacher absence patterns
    │   ├── Frequent absentees
    │   ├── Seasonal patterns
    │   ├── Day-of-week patterns
    │   └── Subject correlation
    ├── Recommendation accuracy
    │   ├── Selection rate of recommendations
    │   ├── Success rate by recommendation rank
    │   └── ML improvement tracking
    └── Export reports
        ├── Daily substitution log
        ├── Monthly summary
        ├── Annual trends
        └── Compliance reporting


## PHASE 11: ARCHIVAL & VERSION MANAGEMENT
══════════════════════════════════════════════════════════════════════════════
### 11.1 Timetable Versioning
    ├── Each generation creates new version
    │   ├── version number increments
    │   ├── parent_timetable_id links to previous
    │   └── version metadata stored
    ├── Track version history
    │   ├── creation_date, created_by
    │   ├── changes_summary
    │   ├── key_metrics comparison
    │   └── approval_history
    └── Version comparison tools
        ├── Side-by-side view
        ├── Diff highlighting
        ├── Metric comparison
        └── Change impact analysis

### 11.2 Archival Process
    ├── Automatic archival rules
    │   ├── Archive after term end + 30 days
    │   ├── Keep last 3 versions active
    │   ├── Archive on status change to 'ARCHIVED'
    │   └── Manual archive trigger
    ├── Archive data
    │   ├── Compress JSON data
    │   ├── Move to archive tables
    │   ├── Create archive manifest
    │   └── Update references
    └── Archive restoration
        ├── Restore to active tables
        ├── View archive without restore
        ├── Compare with current
        └── Export archive

### 11.3 Data Retention & Cleanup
    ├── Retention policies
    │   ├── Active timetables: current term
    │   ├── Recent versions: last 3 terms
    │   ├── Archived: 3 years
    │   └── Historical: 7 years (cold storage)
    ├── Cleanup jobs
    │   ├── Remove temporary data
    │   ├── Purge old logs
    │   ├── Archive completed runs
    │   └── Compress historical data
    └── Compliance checks
        ├── GDPR compliance
        ├── Data minimization
        ├── Audit trail retention
        └── Backup verification


## PHASE 12: CONTINUOUS IMPROVEMENT & OPTIMIZATION
══════════════════════════════════════════════════════════════════════════════
### 12.1 Performance Monitoring
    ├── Track generation metrics
    │   ├── Generation time by strategy
    │   ├── Success rate by complexity
    │   ├── Bottleneck identification
    │   └── Resource usage patterns
    ├── User interaction metrics
    │   ├── Manual changes frequency
    │   ├── Most common adjustments
    │   ├── Conflict resolution patterns
    │   └── Feature usage analytics
    └── System health monitoring
        ├── Queue performance
        ├── Database query optimization
        ├── Cache effectiveness
        └── Error rate tracking

### 12.2 Algorithm Tuning
    ├── A/B testing framework
    │   ├── Test different strategies
    │   ├── Compare results
    │   ├── Statistical analysis
    │   └── Automated winner selection
    ├── Parameter optimization
    │   ├── Genetic algorithm for meta-optimization
    │   ├── Grid search for best parameters
    │   ├── Adaptive parameter adjustment
    │   └── Learning from historical results
    └── Strategy selection improvement
        ├── ML-based strategy recommendation
        ├── Complexity prediction
        ├── Resource requirement estimation
        └── Success probability prediction

### 12.3 Feedback Integration
    ├── Collect feedback from stakeholders
    │   ├── Teacher satisfaction surveys
    │   ├── Student feedback
    │   ├── Admin usability feedback
    │   └── Parent comments
    ├── Analyze feedback patterns
    │   ├── Common complaints
    │   ├── Feature requests
    │   ├── Usability issues
    │   └── Success stories
    └── Incorporate into system
        ├── Adjust constraint weights
        ├── Modify scoring formulas
        ├── Update UI/UX
        └── Enhance algorithms

### 12.4 System Evolution
    ├── Regular updates
    │   ├── New constraint types
    │   ├── Enhanced algorithms
    │   ├── Improved ML models
    │   └── UI enhancements
    ├── Feature roadmap
    │   ├── Predictive scheduling
    │   ├── Real-time collaboration
    │   ├── Mobile-first design
    │   └── AI-assisted optimization
    └── Continuous deployment
        ├── Zero-downtime updates
        ├── Rollback capability
        ├── Feature flags
        └── Gradual rollout






--------------------------------------------------------------------------------------------------------------------
## FUTURE ENHANCEMENTS
--------------------------------------------------------------------------------------------------------------------

### 13.1 Future Enhancements
    ├── AI-Driven Personalization
    │   ├── Adaptive scheduling
    │   ├── AI-powered recommendations
    │   ├── Smart conflict resolution
    │   └── Predictive maintenance
    ├── Enhanced Collaboration
    │   ├── Real-time collaboration
    │   ├── Group scheduling
    │   ├── Shared calendars
    │   └── Mobile-first design
    └── Future-proof architecture
        ├── Microservices for scalability
        ├── Containerization for portability
        ├── Cloud-native features
        └── AI/ML integration

### 13.2 Security Enhancements
    ├── Data encryption
    │   ├── End-to-end encryption
    │   ├── Database encryption
    │   ├── File encryption
    │   └── Sensitive data masking
    ├── Access control
    │   ├── Role-based access control
    │   ├── Multi-factor authentication
    │   ├── Activity logging
    │   └── Audit trails
    └── Compliance
        ├── GDPR compliance
        ├── Data minimization
        ├── Audit trail retention
        └── Backup verification

### 13.3 Performance Enhancements
    ├── Caching strategies
    │   ├── In-memory caching
    │   ├── Database indexing
    │   ├── Query optimization
    │   └── Data partitioning
    ├── Load balancing
    │   ├── Horizontal scaling
    │   ├── Vertical scaling
    │   ├── Load distribution
    │   └── Failover mechanisms
    └── Resource optimization
        ├── Memory management
        ├── CPU optimization
        ├── Disk space management
        └── Network optimization

### 13.4 Cost Optimization
    ├── Resource allocation
    │   ├── Dynamic scaling
    │   ├── Load-based scaling
    │   ├── Resource pooling
    │   └── Cost-aware scheduling
    ├── Cost tracking
    │   ├── Usage monitoring
    │   ├── Cost analysis
    │   ├── Budget management
    │   └── Resource optimization
    └── Cost reduction
        ├── Resource optimization
        ├── Load balancing
        ├── Cost-aware scheduling
        └── Resource pooling

### 13.5 Future Enhancements
    ├── AI/ML integration
    │   ├── AI-powered recommendations
    │   ├── AI-powered conflict resolution
    │   ├── AI-powered optimization
    │   └── AI-powered prediction
    ├── Enhanced collaboration
    │   ├── Real-time collaboration
    │   ├── Group scheduling
    │   ├── Shared calendars
    │   └── Mobile-first design
    └── Future-proof architecture
        ├── Microservices for scalability
        ├── Containerization for portability
        ├── Cloud-native features
        └── AI/ML integration
