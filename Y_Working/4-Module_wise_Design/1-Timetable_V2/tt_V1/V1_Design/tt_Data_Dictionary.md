# Timetable Module - Data Dictionary (v6.0)

**Document Version:** 1.0  
**Schema Version:** 6.0  
**Database:** Tenant DB  
**Prefix:** `tt_` (Timetable Module)

---

## Section 0: Master Configuration

### 1. Shifts (`tt_shift`)
**Purpose:** Defines operational shifts (e.g., Morning, Afternoon).  
**Relationships:** Referenced by `tt_timetable_type`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(20) | Unique, Not Null | Short code (e.g., 'MORNING') |
| name | VARCHAR(100) | Unique, Not Null | Full name (e.g., 'Morning Shift') |
| description | VARCHAR(255) | Nullable | Optional details |
| default_start_time | TIME | Nullable | Standard start time |
| default_end_time | TIME | Nullable | Standard end time |
| ordinal | SMALLINT | Default 1 | Display order |
| is_active | TINYINT(1) | Default 1 | Active status |

### 2. Day Types (`tt_day_type`)
**Purpose:** Categorizes days (Regular, Exam, Half-Day).  
**Relationships:** Referenced by `tt_working_day`, `tt_timetable_type`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(20) | Unique, Not Null | e.g., 'REGULAR', 'EXAM' |
| name | VARCHAR(100) | Unique, Not Null | e.g., 'Regular Teaching Day' |
| is_working_day | TINYINT(1) | Default 1 | Is attendance required? |
| reduced_periods | TINYINT(1) | Default 0 | Does it have fewer periods? |

### 3. School Days (`tt_school_days`)
**Purpose:** Defines standard days of the week (Mon-Sun).  
**Relationships:** Used for recurring logic.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(10) | Unique | e.g., 'MON', 'TUE' |
| name | VARCHAR(20) | Not Null | e.g., 'Monday' |
| day_of_week | TINYINT | Unique | 1=Monday, 7=Sunday |
| is_school_day | TINYINT(1) | Default 1 | Is it normally open? |

### 4. Working Days (`tt_working_day`)
**Purpose:** Calendar overrides for specific dates.  
**Relationships:** Links to `tt_day_type`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| date | DATE | Unique | Specific calendar date |
| day_type_id | BIGINT UNSIGNED | FK -> tt_day_type | Type of day (Exam/Regular) |
| is_school_day | TINYINT(1) | Default 1 | Is school open? |
| remarks | VARCHAR(255) | Nullable | e.g., 'Sports Day' |

### 5. Period Types (`tt_period_type`)
**Purpose:** Classifies time slots (Teaching, Break, Assembly).  
**Relationships:** Referenced by `tt_period_set_period_jnt`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(30) | Unique | e.g., 'TEACHING', 'LUNCH' |
| name | VARCHAR(100) | Not Null | e.g., 'Teaching Period' |
| is_schedulable | TINYINT(1) | Default 1 | Can activities be placed? |
| counts_as_teaching | TINYINT(1) | Default 0 | Counts towards workload? |
| is_break | TINYINT(1) | Default 0 | Is it a break? |

### 6. Assignment Roles (`tt_teacher_assignment_role`)
**Purpose:** Defines teacher roles in a class (Primary, Assistant).  
**Relationships:** Referenced by `tt_activity_teacher`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(30) | Unique | e.g., 'PRIMARY', 'ASSISTANT' |
| is_primary_instructor | TINYINT(1) | Default 0 | Is main teacher? |
| workload_factor | DECIMAL(3,2) | Default 1.00 | Multiplier for workload calc |

---

## Section 1: Period Sets

### 7. Period Sets (`tt_period_set`)
**Purpose:** Defines a template of periods (e.g., "Regular 8-Period Day").  
**Relationships:** Parent of `tt_period_set_period_jnt`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(30) | Unique | e.g., 'REGULAR_8P' |
| total_periods | TINYINT | Not Null | Total slots count |
| teaching_periods | TINYINT | Not Null | Count of teaching slots |
| start_time | TIME | Not Null | Day start |
| end_time | TIME | Not Null | Day end |

### 8. Period Definitions (`tt_period_set_period_jnt`)
**Purpose:** Individual periods within a set.  
**Relationships:** Links `tt_period_set` to `tt_period_type`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| period_set_id | BIGINT UNSIGNED | FK -> tt_period_set | Parent Set |
| period_type_id | BIGINT UNSIGNED | FK -> tt_period_type | Type (Break/Teach) |
| period_ord | TINYINT | Not Null | Sequence (1, 2, 3...) |
| start_time | TIME | Not Null | Slot start |
| end_time | TIME | Not Null | Slot end |
| duration_minutes | SMALLINT | Generated | Length in minutes |

---

## Section 2: Timetable Configuration

### 9. Timetable Types (`tt_timetable_type`)
**Purpose:** master template linking Shift, Period Set, and Day Type.  
**Relationships:** Used by `tt_class_mode_rule`, `tt_timetable`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(30) | Unique | e.g., 'MORNING_REGULAR' |
| shift_id | BIGINT UNSIGNED | FK -> tt_shift | Associated shift |
| default_period_set_id | BIGINT UNSIGNED | FK -> tt_period_set | Default structure |
| day_type_id | BIGINT UNSIGNED | FK -> tt_day_type | Associated day type |
| effective_from_date | DATE | Nullable | Seasonal start |
| effective_to_date | DATE | Nullable | Seasonal end |

---

## Section 3: Grouping & Requirements

### 10. Class Mode Rules (`tt_class_mode_rule`)
**Purpose:** Assigns timetable types to classes for a session.  
**Relationships:** Links Class -> Timetable Type.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| class_id | INT UNSIGNED | FK -> sch_classes | Target Class |
| timetable_type_id | BIGINT UNSIGNED | FK -> tt_timetable_type | Assigned Mode |
| allow_exam | TINYINT(1) | Default 0 | Is exam mode? |

### 11. Class Subgroups (`tt_class_subgroup`)
**Purpose:** Defines subsets of students (Optional Subjects, Hobby Clubs).  
**Relationships:** Used in `tt_activity`, `tt_class_group_requirement`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(50) | Unique | e.g., '10-CS-OPT' |
| subgroup_type | ENUM | Not Null | Optional, Hobby, Skill, etc. |
| class_group_id | BIGINT UNSIGNED | FK -> sch_class_groups | Optional link to main group |

### 12. Requirements (`tt_class_group_requirement`)
**Purpose:** Defines period quotas (e.g., 5 Math periods/week).  
**Relationships:** Links Group/Subgroup -> Session.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| class_group_id | BIGINT UNSIGNED | FK | Target Main Group |
| class_subgroup_id | BIGINT UNSIGNED | FK | Target Subgroup |
| weekly_periods | TINYINT | Not Null | Required count |
| max_per_day | TINYINT | Nullable | Constraint |

### 13. Subgroup Members (`tt_class_subgroup_member`)
**Purpose:** Mapping of Classes/Sections to Subgroups.  
**Relationships:** Links Subgroup -> Class/Section.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| class_subgroup_id | BIGINT UNSIGNED | FK | Parent Subgroup |
| class_id | INT UNSIGNED | FK | Member Class |
| section_id | INT UNSIGNED | FK | Member Section |

---

## Section 4: Activities

### 14. Activity (`tt_activity`)
**Purpose:** Represents a schedulable unit (Lesson).  
**Relationships:** Core entity for scheduling.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| code | VARCHAR(50) | Unique | Logic code |
| subject_id | BIGINT UNSIGNED | FK | Subject |
| duration_periods | TINYINT | Default 1 | Consecutive slots needed |
| total_periods | SMALLINT | Generated | duration * weekly_periods |
| preferred_room_ids | JSON | Nullable | List of preferred rooms |

### 15. Activity Teacher (`tt_activity_teacher`)
**Purpose:** Assigns teachers to activities.  
**Relationships:** Many-to-Many Activity <-> Teacher.
| Column | Type | Constraints | Description |
|---|---|---|---|
| activity_id | BIGINT UNSIGNED | FK | Parent Activity |
| teacher_id | BIGINT UNSIGNED | FK | Assigned Teacher |
| assignment_role_id | BIGINT UNSIGNED | FK | Role (Primary/Support) |

### 16. Sub-Activity (`tt_sub_activity`)
**Purpose:** Breaks complex activities into smaller units for algorithm.  
**Relationships:** Child of `tt_activity`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| parent_activity_id | BIGINT UNSIGNED | FK | Parent |
| duration_periods | TINYINT | Default 1 | Length of this chunk |

---

## Section 5: Constraints

### 17. Constraint Types (`tt_constraint_type`)
**Purpose:** Definition of constraint rules (e.g., "Max Gaps").  
**Relationships:** Parent of `tt_constraint`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| code | VARCHAR(60) | Unique | System code |
| category | ENUM | Not Null | Time, Space, Teacher... |
| default_weight | TINYINT | Default 100 | Hardness score |

### 18. Constraints (`tt_constraint`)
**Purpose:** Instantiated constraints for specific targets.  
**Relationships:** Links logic to targets.
| Column | Type | Constraints | Description |
|---|---|---|---|
| constraint_type_id | BIGINT UNSIGNED | FK | Rule Type |
| target_type | ENUM | Not Null | Teacher, Class, Room... |
| target_id | BIGINT UNSIGNED | Nullable | Specific target ID |
| is_hard | TINYINT(1) | Default 0 | Hard vs Soft constraint |

### 19. Teacher Unavailable (`tt_teacher_unavailable`)
**Purpose:** Specific blocked slots for teachers.  
**Relationships:** Teacher -> Day/Period.
| Column | Type | Constraints | Description |
|---|---|---|---|
| teacher_id | BIGINT UNSIGNED | FK | Target Teacher |
| day_of_week | TINYINT | Not Null | 1-7 |
| period_ord | TINYINT | Nullable | Specific slot (Null=All day) |

### 20. Room Unavailable (`tt_room_unavailable`)
**Purpose:** Specific blocked slots for rooms.  
**Relationships:** Room -> Day/Period.
| Column | Type | Constraints | Description |
|---|---|---|---|
| room_id | INT UNSIGNED | FK | Target Room |

---

## Section 6: Timetable Storage

### 21. Timetable (`tt_timetable`)
**Purpose:** Header for a generated timetable version.  
**Relationships:** Parent of `tt_timetable_cell`.
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK, Auto Inc | Unique Identifier |
| name | VARCHAR(200) | Not Null | Display Name |
| status | ENUM | Not Null | Draft, Published |
| constraint_violations | INT | Default 0 | Health score |

### 22. Generation Run (`tt_generation_run`)
**Purpose:** Log of an algorithmic generation attempt.  
**Relationships:** Links to Timetable.
| Column | Type | Constraints | Description |
|---|---|---|---|
| run_number | INT | Not Null | Iteration count |
| status | ENUM | Not Null | Queued, Running, Completed |
| soft_score | DECIMAL | Nullable | Quality metric |

### 23. Timetable Cell (`tt_timetable_cell`)
**Purpose:** The actual atomic scheduled slot.  
**Relationships:** Links Time -> Activity -> Room.
| Column | Type | Constraints | Description |
|---|---|---|---|
| timetable_id | BIGINT UNSIGNED | FK | Parent Timetable |
| day_of_week | TINYINT | Not Null | Day |
| period_ord | TINYINT | Not Null | Period |
| activity_id | BIGINT UNSIGNED | FK | What is happening |
| room_id | INT UNSIGNED | FK | Where |
| is_locked | TINYINT(1) | Default 0 | Manual override lock |

### 24. Cell Teacher (`tt_timetable_cell_teacher`)
**Purpose:** Teachers assigned to a specific scheduled cell.  
**Relationships:** Cell -> Teacher.
| Column | Type | Constraints | Description |
|---|---|---|---|
| cell_id | BIGINT UNSIGNED | FK | Parent Slot |
| teacher_id | BIGINT UNSIGNED | FK | Actually present teacher |
| is_substitute | TINYINT(1) | Default 0 | Is this a sub? |

### 25. Constraint Violations (`tt_constraint_violation`)
**Purpose:** Detailed log of specific constraint breaches per timetable.
| Column | Type | Constraints | Description |
|---|---|---|---|
| timetable_id | BIGINT UNSIGNED | FK | Parent |
| constraint_id | BIGINT UNSIGNED | FK | Broken Rule |
| violation_type | ENUM | Hard/Soft | Severity |

---

## Section 7: Substitution

### 26. Teacher Absence (`tt_teacher_absence`)
**Purpose:** Records approved leaves requiring cover.  
**Relationships:** Teacher -> Date.
| Column | Type | Constraints | Description |
|---|---|---|---|
| teacher_id | BIGINT UNSIGNED | FK | Who is away |
| absence_date | DATE | Not Null | When |
| substitution_required | TINYINT(1) | Default 1 | Need cover? |

### 27. Substitution Log (`tt_substitution_log`)
**Purpose:** Tracks the assignment of a substitute to a cell.  
**Relationships:** Absence -> Cell -> Substitute.
| Column | Type | Constraints | Description |
|---|---|---|---|
| teacher_absence_id | BIGINT UNSIGNED | FK | Triggering absence |
| cell_id | BIGINT UNSIGNED | FK | Slot being covered |
| absent_teacher_id | BIGINT UNSIGNED | FK | Original Teacher |
| substitute_teacher_id | BIGINT UNSIGNED | FK | New Teacher |
| status | ENUM | Not Null | Assigned, Completed |

---

## Section 8 & 9: Analytics & Workload

### 28. Workload (`tt_teacher_workload`)
**Purpose:** Aggregated stats on teacher load.  
**Relationships:** Teacher -> Session.
| Column | Type | Constraints | Description |
|---|---|---|---|
| teacher_id | BIGINT UNSIGNED | FK | Target |
| weekly_periods_assigned | SMALLINT | Default 0 | Current Load |
| utilization_percent | DECIMAL | Nullable | Load / Max |

### 29. Change Log (`tt_change_log`)
**Purpose:** Audit trail for timetable modifications.  
**Relationships:** Timetable -> Cell.
| Column | Type | Constraints | Description |
|---|---|---|---|
| table_id | BIGINT UNSIGNED | FK | Target Timetable |
| change_type | ENUM | Not Null | Create/Swap/Sub |
| old_values_json | JSON | Nullable | Snapshot before |
| new_values_json | JSON | Nullable | Snapshot after |
