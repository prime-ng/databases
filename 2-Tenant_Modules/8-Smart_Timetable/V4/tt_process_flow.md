# COMPLETE PROCESS FLOW SEQUENCE


```test
┌─────────────────────────────────────────────────────────────────────────────┐
│                    TIMETABLE GENERATION PROCESS FLOW                        │
└─────────────────────────────────────────────────────────────────────────────┘

PHASE 0: PRE-REQUISITES SETUP (One-time)
═══════════════════════════════════════════════════════════════════════════════
0.1 System Configuration
    ├── Set tt_config parameters
    ├── Define tt_shift (Morning/Afternoon/Evening)
    ├── Define tt_day_type (Working/Holiday/Exam/Special)
    ├── Define tt_period_type (Teaching/Break/Lunch/Assembly)
    └── Define tt_teacher_assignment_role (Primary/Assistant/Substitute)

0.2 Master Data Setup
    ├── Import/Setup sch_buildings, sch_rooms_type, sch_rooms
    ├── Import/Setup sch_subjects, sch_study_formats, sch_subject_study_format_jnt
    ├── Import/Setup sch_classes, sch_sections, sch_class_section_jnt
    ├── Import/Setup sch_employees, sch_teachers_profile
    └── Import/Setup sch_subject_groups, sch_class_groups_jnt


PHASE 1: ACADEMIC TERM & TIMETABLE TYPE SETUP
═══════════════════════════════════════════════════════════════════════════════
1.1 Academic Term Setup
    ├── Create/Select Academic Term (sch_academic_term)
    ├── Set term dates, total teaching days, periods per day
    └── Mark current term (is_current = 1)

1.2 Timetable Type Definition
    ├── Create tt_timetable_type (Standard/Exam/Half-Day)
    ├── Create tt_period_set for each type
    ├── Define tt_period_set_period_jnt (period order, timing)
    └── Map classes to timetable types (tt_class_timetable_type_jnt)

1.3 Calendar Setup
    ├── Define tt_school_days (weekly schedule)
    ├── Mark tt_working_day for entire term
    └── Set tt_class_working_day_jnt for special cases


PHASE 2: REQUIREMENT GENERATION
═══════════════════════════════════════════════════════════════════════════════
2.1 Slot Requirement Generation
    ├── TRUNCATE tt_slot_requirement
    ├── INSERT from tt_class_timetable_type_jnt (applies_to_all_sections=0)
    ├── INSERT from tt_class_timetable_type_jnt (applies_to_all_sections=1)
    │   └── Loop through sch_class_section_jnt for each class
    └── Update activity_id later when activities are created

2.2 Class Requirement Groups/Subgroups
    ├── INSERT into tt_class_requirement_groups (from sch_class_groups_jnt)
    ├── INSERT into tt_class_requirement_subgroups (from sch_class_groups_jnt)
    ├── UPDATE class_house_room_id from sch_class_section_jnt
    ├── UPDATE student_count from std_student_academic_sessions
    └── UPDATE eligible_teacher_count from sch_teacher_capabilities

2.3 Requirement Consolidation
    ├── TRUNCATE tt_requirement_consolidation
    ├── INSERT from tt_class_requirement_groups
    ├── INSERT from tt_class_requirement_subgroups
    └── User modifies: preferred_periods_json, avoid_periods_json, spread_evenly


PHASE 3: RESOURCE AVAILABILITY PREPARATION
═══════════════════════════════════════════════════════════════════════════════
3.1 Teacher Availability
    ├── TRUNCATE tt_teacher_availability
    ├── INSERT with LEFT JOIN from:
    │   ├── tt_requirement_consolidation (base requirements)
    │   ├── sch_teacher_capabilities (matching teachers)
    │   └── sch_teacher_profile (teacher details)
    │
    ├── UPDATE max_allocated_periods_weekly:
    │   └── SUM(required_weekly_periods) across ALL sections
    │
    ├── UPDATE min_allocated_periods_weekly:
    │   └── MAX(required_weekly_periods) per class+subject_study_format
    │
    ├── CALCULATE min_teacher_availability_score:
    │   └── (min_available_periods_weekly / min_allocated_periods_weekly) * 100
    │
    └── CALCULATE max_teacher_availability_score:
        └── (max_available_periods_weekly / max_allocated_periods_weekly) * 100

3.2 Room Availability
    ├── TRUNCATE tt_room_availability
    └── INSERT room availability based on room types and capacities

3.3 Constraint Application
    ├── Load tt_constraint_category_scope
    ├── Load tt_constraint_type
    ├── Apply tt_constraint (time/space constraints)
    ├── Apply tt_teacher_unavailable (teacher specific)
    └── Apply tt_room_unavailable (room specific)


PHASE 4: Validation (Requirement vs. Availability)
═══════════════════════════════════════════════════════════════════════════════
4.1 Validate Cross-Date Conflict
    ├── Re-Calculate Available No of Rooms for each Room Type
    ├── Calculate Available Rooms for each Room Type
    ├── Mark tt_working_day for entire term
    └── Set tt_class_working_day_jnt for special cases

4.2 Validate Teachers Availability
    ├── Create tt_teacher_availability
    ├── Calculate max_available_periods_weekly & min_available_periods_weekly
    ├── Calculate min_teacher_availability_score & max_teacher_availability_score
    ├── Calculate weekly Class wise per Subject Period Requirement
    ├── Calculate weekly Class wise per Subject Period Availability
    ├── Compare Class+Subject wise Period Requirement vs. Availability 
    ├── Calculate weekly Class+Subject 'Period Availability Score' (Availability / Requirement)
    └── If Period Availability Score < 1, then Vaidation Status will be Failed

4.3 Validate Rooms Availability
    ├── Re-Calculate Available No of Rooms for each Room Type
    ├── Calculate Available Rooms for each Room Type
    ├── Mark tt_working_day for entire term
    └── Set tt_class_working_day_jnt for special cases


PHASE 5: ACTIVITY CREATION & PRIORITIZATION
═══════════════════════════════════════════════════════════════════════════════
5.1 Activity Generation
    ├── TRUNCATE tt_activity
    ├── INSERT from tt_requirement_consolidation
    ├── Calculate difficulty_score:
    │   ├── eligible_teacher_count < 3 → +30 points
    │   ├── is_compulsory = 1 → +20 points
    │   ├── required_weekly_periods > 4 → +15 points
    │   ├── compulsory_specific_room_type = 1 → +15 points
    │   └── has time constraints → +20 points
    └── Calculate priority_score (0-100)

5.2 Activity Prioritization Formula
    ├── resource_scarcity = (required_resources / available_resources)
    ├── teacher_scarcity = (required_teachers / available_teachers)
    ├── rigidity_score = (allowed_slots / total_slots)
    ├── workload_balance = (current_load / max_load)
    └── FINAL_PRIORITY = (
        (resource_scarcity * 25) +
        (teacher_scarcity * 25) +
        ((1 - rigidity_score) * 20) +
        (workload_balance * 15) +
        (subject_difficulty_index * 15)
    )

5.3 Sub-Activity Creation (if needed)
    ├── Create tt_sub_activity for split activities
    └── Link to parent activity

5.4 Activity-Teacher Mapping
    └── INSERT into tt_activity_teacher (eligible teachers with roles)


PHASE 6: TIMETABLE GENERATION
═══════════════════════════════════════════════════════════════════════════════
6.1 Generation Queue
    ├── INSERT into tt_generation_queue
    └── Select tt_generation_strategy

6.2 Generation Run
    ├── CREATE tt_timetable record (status = 'DRAFT')
    ├── CREATE tt_generation_run (status = 'QUEUED')
    ├── Process queue (async job)
    └── Update generation_run status as processing

6.3 Algorithm Execution (FET-based recursive swapping)
    ├── Sort activities by difficulty_score (highest first)
    ├── For each activity:
    │   ├── Find available slots (respecting constraints)
    │   ├── If slot available → place activity
    │   ├── If no slot available:
    │   │   ├── Identify conflicting activities
    │   │   ├── Try recursive swapping (max depth = 14)
    │   │   ├── If successful → place and continue
    │   │   └── If failed → add to conflict list
    │   └── Track in tt_conflict_detection
    │
    ├── Log constraint violations in tt_constraint_violation
    └── Record resource bookings in tt_resource_booking

6.4 Generation Completion
    ├── Update tt_timetable with stats
    ├── Update tt_generation_run with results
    ├── Populate tt_timetable_cell with placements
    ├── Populate tt_timetable_cell_teacher with teacher assignments
    └── Update generation_queue status = 'COMPLETED'


PHASE 7: POST-GENERATION PROCESSING
═══════════════════════════════════════════════════════════════════════════════
7.1 Analytics & Reporting
    ├── Calculate teacher_workload in tt_teacher_workload
    ├── Create daily snapshots in tt_analytics_daily_snapshot
    ├── Update performance metrics
    └── Generate reports

7.2 Manual Refinement
    ├── User can lock/unlock cells (tt_timetable_cell.is_locked)
    ├── Manual adjustments via UI
    └── Track changes in tt_change_log

7.3 Publication
    ├── Update tt_timetable.status = 'PUBLISHED'
    ├── Set published_at and published_by
    └── Generate HTML/XML/CSV outputs


PHASE 8: SUBSTITUTION MANAGEMENT
═══════════════════════════════════════════════════════════════════════════════
8.1 Absence Recording
    ├── Create tt_teacher_absence record
    └── Mark substitution_required = 1

8.2 Substitution Finder (Real-time)
    ├── Identify affected cells from tt_timetable_cell
    ├── Query eligible teachers:
    │   ├── Same subject_study_format qualification
    │   ├── Available at that time slot
    │   ├── Not exceeding max_allocated_periods_weekly
    │   └── No conflicting assignments
    │
    ├── Calculate compatibility scores:
    │   ├── proficiency_percentage (40%)
    │   ├── historical_success_ratio (30%)
    │   ├── teaching_experience_months (15%)
    │   └── student_feedback_score (15%)
    │
    ├── Generate recommendations in tt_substitution_recommendation
    └── Insert into tt_substitution_log when assigned

8.3 Pattern Learning
    ├── Record successful substitutions in tt_substitution_pattern
    └── Update historical_success_ratio for ML improvement
```

