# Refined & Enhanced List of Constraints
----------------------------------------

Below is the enhanced list of constraints with proper categorization, priority weighting, and implementation feasibility. This refined list follows academic scheduling best practices and aligns with FET (Free Timetabling Software) architecture.

## A1: CONSTRAINTS CLASSIFICATION FRAMEWORK
------------------------------------------
```text
CONSTRAINT HIERARCHY:
├── LEVEL 1: HARD CONSTRAINTS (Must be satisfied - 100% mandatory)
├── LEVEL 2: STRONG CONSTRAINTS (Should be satisfied - Weight 80-99%)
├── LEVEL 3: MEDIUM CONSTRAINTS (Nice to have - Weight 40-79%)
├── LEVEL 4: SOFT CONSTRAINTS (Preferential - Weight 1-39%)
└── LEVEL 5: OPTIMIZATION GOALS (Minimize/Maximize targets)
```

## A2: COMPREHENSIVE CONSTRAINT CATALOG
--------------------------------------
### A2.1 TEACHER-RELATED CONSTRAINTS

| ID  |Constraint Name                  |Category       |Scope       | Level  |Weight|Parameters|Implementation Stage|
|-----|---------------------------------|---------------|------------|--------|------|------------------------------------------------------------------------------|---------------------|
| T01 |Teacher Unavailability           | TEACHER       |INDIVIDUAL  | HARD   |  100 |teacher_id, day_of_week[], period_ord[], start_date, end_date, is_recurring   |Teacher Availability
| T02 |Max Daily Workload               | TEACHER       |INDIVIDUAL  | HARD   |  100 |teacher_id, max_periods_per_day (default: 8)                                  |Teacher Availability
| T03 |Max Weekly Workload              | TEACHER       |INDIVIDUAL  | HARD   |  100 |teacher_id, max_periods_per_week (default: 48)                                |Teacher Availability
| T04 |Min Daily Workload               | TEACHER       |INDIVIDUAL  | STRONG |   90 |teacher_id, min_periods_per_day (default: 1)                                  |Teacher Availability
| T05 |Min Weekly Workload              | TEACHER       |INDIVIDUAL  | STRONG |   90 |teacher_id, min_periods_per_week (default: 15)                                |Teacher Availability
| T06 |Max Consecutive Periods          | TEACHER       |INDIVIDUAL  | STRONG |   85 |teacher_id, max_consecutive (default: 3)                                      |Activity Placement
| T07 |Min Gap Between Periods          | TEACHER       |INDIVIDUAL  | MEDIUM |   70 |teacher_id, min_gap_minutes (default: 0)                                      |Activity Placement
| T08 |Preferred Time Slots             | TEACHER       |INDIVIDUAL  | SOFT   |   40 |teacher_id, preferred_periods_json                                            |Activity Placement
| T09 |Avoid Time Slots                 | TEACHER       |INDIVIDUAL  | MEDIUM |   60 |teacher_id, avoid_periods_json                                                |Activity Placement
| T10 |Max Free Periods Per Day         | TEACHER       |INDIVIDUAL  | MEDIUM |   65 |teacher_id, max_free_periods_per_day (default: 3)                             |Post-Placement
| T11 |Max Free Periods Per Week        | TEACHER       |INDIVIDUAL  | MEDIUM |   60 |teacher_id, max_free_periods_per_week (default: 10)                           |Post-Placement
| T12 |Min Free Periods Per Day         | TEACHER       |INDIVIDUAL  | SOFT   |   30 |teacher_id, min_free_periods_per_day (default: 1)                             |Post-Placement
| T13 |Class Teacher First Period       | TEACHER       |INDIVIDUAL  | MEDIUM |   75 |teacher_id, class_id, section_id                                              |Activity Placement
| T14 |Teacher Pair Mutex               | TEACHER       |PAIR        | STRONG |   95 |teacher1_id, teacher2_id, day_of_week, period_ord                             |Conflict Detection
| T15 |Teacher Building Change Limit    | TEACHER       |INDIVIDUAL  | SOFT   |   40 |teacher_id, max_building_changes_per_day (default: 2)                         |Post-Placement
| T16 |Teacher Room Change Limit        | TEACHER       |INDIVIDUAL  | SOFT   |   35 |teacher_id, max_room_changes_per_day (default: 3)                             |Post-Placement
| T17 |Teacher Break Requirement        | TEACHER       |INDIVIDUAL  | MEDIUM |   50 |teacher_id, min_break_after_periods (default: 4), break_duration (default: 1) |Activity Placement
| T18 |Teacher Subject Specialization   | TEACHER       |INDIVIDUAL  | HARD   |  100 |teacher_id, subject_study_format_id, proficiency_min (default: 70%)           |Teacher Eligibility

### A2.2 CLASS/GROUP-RELATED CONSTRAINTS

| ID  |Constraint Name	                |Category       |Scope	     | Level  |Weight| Parameters	                                                                   | Implementation Stage
|-----|---------------------------------|---------------|------------|--------|------|-------------------------------------------------------------------------------|---------------------|
| C01 |Max Periods Per Day	            | CLASS	        | INDIVIDUAL | HARD	  | 100  | class_id, section_id, max_periods_per_day	                                   | Slot Requirement
| C02 |Min Periods Per Day	            | CLASS	        | INDIVIDUAL | HARD	  | 100  | class_id, section_id, min_periods_per_day	                                   | Slot Requirement
| C03 |Max Consecutive Teaching Periods	| CLASS	        | INDIVIDUAL | MEDIUM |  70	 | class_id, section_id, max_consecutive (default: 3)	                           | Activity Placement
| C04 |Min Gap Between Subjects	        | CLASS	        | INDIVIDUAL | MEDIUM |  65  | class_id, section_id, min_gap_periods (default: 1)	                           | Activity Placement
| C05 |Subject Spread Evenly	          | CLASS+SUBJECT	| INDIVIDUAL | MEDIUM |  75	 | class_id, section_id, subject_study_format_id	                               | Activity Placement
| C06 |Max Same Subject Per Day	        | CLASS+SUBJECT	| INDIVIDUAL | MEDIUM |  80	 | class_id, section_id, subject_study_format_id, max_per_day (default: 2)	     | Activity Placement
| C07 |Preferred Subject Order	        | CLASS+SUBJECT	| INDIVIDUAL | SOFT   |  40	 | class_id, section_id, subject_study_format_id, preferred_period_ord[]	       | Activity Placement
| C08 |Avoid Subject Consecutive	      | CLASS+SUBJECT	| INDIVIDUAL | MEDIUM |  60	 | class_id, section_id, subject_study_format_id	                               | Activity Placement
| C09 |Subject Time Window	            | CLASS+SUBJECT	| INDIVIDUAL | STRONG |  85	 | class_id, section_id, subject_study_format_id, allowed_period_range_from / to | Activity Placement
| C10 |Subject Day Restriction	        | CLASS+SUBJECT	| INDIVIDUAL | STRONG |  90	 | class_id, section_id, subject_study_format_id, allowed_days_of_week[]	       | Activity Placement
| C11 |Max Minor Subjects Per Day	      | CLASS	        | INDIVIDUAL | MEDIUM |  70	 | class_id, section_id, max_minor_subjects_per_day (default: 2)	               | Activity Placement
| C12 |Subject Group Mutex	            | CLASS	        | GROUP	     | STRONG |  95	 | class_id, section_id, subject_study_format_id[], mutually_exclusive_days[]	   | Conflict Detection
| C13 |Subject Group Concurrency	      | CLASS	        | GROUP	     | STRONG |  95  | class_id, section_id, subject_study_format_id[], must_run_parallel	           | Activity Placement

### A2.3 ACTIVITY/SUBJECT STUDY FORMAT CONSTRAINTS
| ID |Constraint Name                   |Category       |Scope       | Level  |Weight|Parameters                                                                     |Implementation Stage|
|----|----------------------------------|---------------|------------|--------|------|-------------------------------------------------------------------------------|--------------------|
|A01 |Required Consecutive Periods      |ACTIVITY       |INDIVIDUAL  | HARD   | 100  |activity_id, required_consecutive_periods (default: 2)                         |Activity Definition
|A02 |Max Consecutive Periods	          |ACTIVITY       |INDIVIDUAL  | HARD   | 100  |activity_id, max_consecutive_periods                                           |Activity Definition
|A03 |Fixed Duration	                  |ACTIVITY       |INDIVIDUAL  | HARD   | 100  |activity_id, duration_periods (default: 1)                                     |Activity Definition
|A04 |Preferred Room Type	              |ACTIVITY       |INDIVIDUAL  | MEDIUM |  65  |activity_id, preferred_room_type_id                                            |Room Allocation
|A05 |Required Room Type	              |ACTIVITY       |INDIVIDUAL  | HARD   | 100  |activity_id, required_room_type_id                                             |Room Allocation
|A06 |Required Room	                    |ACTIVITY       |INDIVIDUAL  | HARD   | 100  |activity_id, required_room_id                                                  |Room Allocation
|A07 |Preferred Start Time  	          |ACTIVITY       |INDIVIDUAL  | SOFT   |  40  |activity_id, preferred_periods_json                                            |Activity Placement
|A08 |Avoid Start Time	                |ACTIVITY       |INDIVIDUAL  | MEDIUM |  60  |activity_id, avoid_periods_json                                                |Activity Placement
|A09 |Same Start Time Group	            |ACTIVITY       |GROUP       | STRONG |  95  |activity_id[], same_start_time_required                                        |Conflict Detection
|A10 |Ordered Consecutive	              |ACTIVITY       |GROUP       | STRONG |  90  |activity_id[], ordered_sequence_required                                       |Activity Placement
|A11 |Min Gap Between Activities	      |ACTIVITY       |PAIR	       | MEDIUM |  70  |activity1_id, activity2_id, min_gap_periods                                    |Activity Placement
|A12 |Max Days Between Activities	      |ACTIVITY       |PAIR	       | MEDIUM |  65  |activity1_id, activity2_id, max_days_between                                   |Activity Placement
|A13 |Same Day Group	                  |ACTIVITY       |GROUP       | STRONG |  85  |activity_id[], same_day_required                                               |Activity Placement
|A14 |Different Day Group	              |ACTIVITY       |GROUP       | STRONG |  80  |activity_id[], different_day_required                                          |Activity Placement


### A2.4 ROOM/RESOURCE CONSTRAINTS
|ID	|Constraint Name	                  |Category       |Scope	     |Level   |Weight|Parameters	                                                                   |Implementation Stage
|---|-----------------------------------|---------------|------------|--------|------|-------------------------------------------------------------------------------|---------------------
|R01|Room Unavailability                |ROOM	          |INDIVIDUAL  |HARD    | 100  |room_id, day_of_week[], period_ord[], start_date, end_date                     |Room Availability
|R02|Room Capacity Limit                |ROOM	          |INDIVIDUAL  |HARD    | 100  |room_id, max_capacity	                                                         |Room Allocation
|R03|Room Type Capacity	                |ROOM_TYPE	    |GROUP       |HARD    | 100  |room_type_id, max_concurrent_usage	                                           |Room Availability
|R04|Preferred Room for Subject	        |ACTIVITY+ROOM  |INDIVIDUAL  |SOFT    |  30  |activity_id, preferred_room_ids_json	                                         |Room Allocation
|R05|Room Equipment Requirement	        |ROOM	          |INDIVIDUAL  |STRONG  |  90  |room_id, required_equipment_json	                                             |Room Availability
|R06|Max Room Changes Per Day           |CLASS	        |INDIVIDUAL  |SOFT    |  40  |class_id, section_id, max_room_changes_per_day	                               |Post-Placement
|R07|Room Exclusive Usage               |ROOM	          |INDIVIDUAL  |HARD    | 100  |room_id, exclusive_to_activity_id	                                             |Room Allocation
|R08|Building Travel Time               |BUILDING	      |GLOBAL      |MEDIUM  |  70  |building1_id, building2_id, travel_time_minutes	                               |Post-Placement
|R09|Lab Reservation                    |ROOM_TYPE      |GLOBAL      |HARD    | 100  |room_type_id, reserved_for_subject_study_format_id[]	                         |Room Availability


### A2.5 STUDENT GROUP CONSTRAINTS
|ID	 |Constraint Name	                  |Category       |Scope       |Level   |Weight|Parameters                                                                     |Implementation Stage
|----|----------------------------------|---------------|------------|--------|------|-------------------------------------------------------------------------------|---------------------
|S01 |Max Gaps Per Day	                | STUDENT_GROUP |INDIVIDUAL  |MEDIUM  |  60  |class_id, section_id, max_gaps_per_day (default: 2)                            |Post-Placement
|S02 |Max Gaps Per Week	                | STUDENT_GROUP |INDIVIDUAL  |MEDIUM  |  55  |class_id, section_id, max_gaps_per_week (default: 8)                           |Post-Placement
|S03 |No First Period Gap	              | STUDENT_GROUP |INDIVIDUAL  |MEDIUM  |  65  |class_id, section_id                                                           |Activity Placement
|S04 |Min Teaching Periods Per Day      | STUDENT_GROUP |INDIVIDUAL  |HARD    | 100  |class_id, section_id, min_teaching_periods_per_day                             |Slot Requirement
|S05 |School Day Span Limit	            | STUDENT_GROUP |INDIVIDUAL  |MEDIUM  |  70  |class_id, section_id, max_school_day_span_minutes                              |Post-Placement
|S06 |Subject Overlap Prevention        | STUDENT_GROUP |INDIVIDUAL  |HARD    | 100  |class_id, section_id, subject_study_format_id[]                                |Conflict Detection
|S07 |Parallel Group Requirement        | STUDENT_GROUP |GROUP       |STRONG  |  95  |class_section_ids[], subject_study_format_id                                   |Activity Placement


###     A2.6 GLOBAL/SYSTEM CONSTRAINTS
|ID	 |Constraint Name	                  |Category       |Scope	      |Level  |Weight|Parameters	                                                                   |Implementation Stage
|----|----------------------------------|---------------|-------------|-------|------|-------------------------------------------------------------------------------|---------------------
|G01 |School Working Days               |GLOBAL         |GLOBAL	      |HARD   |  100 |academic_term_id, working_days_of_week[]	                                     |Calendar Setup
|G02 |School Holidays                   |GLOBAL         |GLOBAL	      |HARD   |  100 |academic_term_id, holiday_dates[]	                                             |Calendar Setup
|G03 |Special Day Schedule              |GLOBAL         |GLOBAL	      |HARD   |  100 |date, period_set_id	                                                           |Calendar Setup
|G04 |Assembly Schedule	                |GLOBAL         |GLOBAL	      |HARD   |  100 |day_of_week[], period_ord, duration	                                           |Period Set
|G05 |Break Schedule	                  |GLOBAL         |GLOBAL	      |HARD   |  100 |day_of_week[], period_ord, duration, type (LUNCH/SHORT_BREAK)                  |Period Set



### A3: CONSTRAINT METADATA & PARAMETER SCHEMA
For each constraint type, we need a JSON schema definition:

```json
{
  "T02": {
    "name": "Max Daily Workload",
    "parameter_schema": {
      "max_periods_per_day": {
        "type": "integer",
        "minimum": 1,
        "maximum": 12,
        "default": 8
      },
      "applicable_days": {
        "type": "array",
        "items": {"type": "integer", "minimum": 1, "maximum": 7},
        "default": [1,2,3,4,5,6,7]
      }
    },
    "validation_rules": {
      "conflict_check": "teacher_per_day_count <= max_periods_per_day",
      "severity": "hard"
    }
  }
}
```

### A4: CONSTRAINT PRIORITIZATION FOR IMPLEMENTATION
#### PHASE 1 IMPLEMENTATION (CORE HARD CONSTRAINTS)

 - T01, T02, T03, T18 (Teacher unavailability and workload limits)
 - C01, C02 (Class period limits)
 - A01, A02, A03, A05, A06 (Activity duration and room requirements)
 - R01, R02, R03 (Room availability and capacity)
 - S04, S06 (Student group teaching requirements and conflict prevention)
 - G01, G02, G03, G04, G05 (School calendar and schedule)

#### PHASE 2 IMPLEMENTATION (STRONG CONSTRAINTS)

 - T04, T05, T06, T14 (Teacher workload optimization)
 - C09, C10, C12, C13 (Subject scheduling rules)
 - A09, A10, A13, A14 (Activity grouping rules)
 - R05, R09 (Resource specialization)

#### PHASE 3 IMPLEMENTATION (MEDIUM/SOFT CONSTRAINTS)

 - T07, T08, T09, T10, T11, T12, T15, T16, T17 (Teacher preferences)
 - C03, C04, C05, C06, C08, C11 (Class optimization)
 - A04, A07, A08, A11, A12 (Activity preferences)
 - R04, R06, R08 (Room optimization)
 - S01, S02, S03, S05 (Student experience optimization)



## B: Refine Constraint Tables in SECTION 3: CONSTRAINT ENGINE
Based on the refined constraint list above, here's the enhanced database schema for the constraint engine:

```sql

