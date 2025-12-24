# TIMETABLE MODULE - DATABASE SCHEMA EXPLANATION
## Document Version: 1.0
**Last Updated:** December 14, 2025

---

## OVERVIEW

This document provides comprehensive database schema documentation for the Timetable Module, including table structures, relationships, constraints, indexes, and seed data. The schema is designed for MySQL 8.x and follows the existing ERP database conventions.

### Schema Architecture

The timetable module consists of 12 core tables organized into logical groups:

1. **Master Data Tables** (4 tables)
   - `tim_timetable_mode`
   - `tim_period_type`
   - `tim_teacher_assignment_role`
   - `tim_period_set`

2. **Configuration Tables** (3 tables)
   - `tim_period_set_period`
   - `tim_class_mode_rule`
   - `tim_class_group_requirement`

3. **Scheduling Tables** (4 tables)
   - `tim_class_subgroup`
   - `tt_class_subgroup_member`
   - `tim_generation_run`
   - `tt_timetable_cell`

4. **Assignment & Tracking Tables** (2 tables)
   - `tim_timetable_cell_teacher`
   - `tim_substitution_log`

5. **Constraint Engine** (1 table)
   - `tim_constraint`

---

## TABLE DETAILS

### 1. tim_timetable_mode
**Purpose:** Defines different timetable modes like Regular, Exam, Special Event etc.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `code` (VARCHAR 20) - Unique code like 'REGULAR', 'EXAM'
- `name` (VARCHAR 100) - Human-readable name
- `has_exam` (TINYINT) - Whether this mode includes exam periods
- `has_teaching` (TINYINT) - Whether this mode includes teaching periods

**Relationships:**
- Referenced by: `tim_class_mode_rule.mode_id`
- Referenced by: `tim_generation_run.mode_id`

**Growth Considerations:**
- Low growth (typically 3-5 modes per school)
- Static data, rarely changes
- Suitable for caching

**Indexes:**
```sql
UNIQUE KEY `uq_timetable_mode_code` (`code`)
```

---

### 2. tim_period_type
**Purpose:** Defines different types of periods like Teaching, Examination, Break, Assembly etc.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `code` (VARCHAR 20) - Unique code like 'TEACHING', 'EXAMINATION'
- `name` (VARCHAR 50) - Human-readable name
- `counts_as_teaching` (TINYINT) - Whether this period type counts as teaching
- `counts_as_exam` (TINYINT) - Whether this period type counts as examination

**Relationships:**
- Referenced by: `tim_period_set_period.period_type_id`

**Growth Considerations:**
- Very low growth (typically 4-6 period types)
- Static master data
- Perfect for enum conversion in future

**Indexes:**
```sql
UNIQUE KEY `uq_period_type_code` (`code`)
```

---

### 3. tim_teacher_assignment_role
**Purpose:** Defines different teacher assignment roles like Primary Instructor, Assistant Instructor, Substitute etc.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `code` (VARCHAR 20) - Unique code like 'PRIMARY_INSTRUCTOR'
- `name` (VARCHAR 100) - Human-readable name
- `is_primary_instructor` (TINYINT) - Whether this is primary instructor role
- `counts_for_workload` (TINYINT) - Whether this counts for workload calculations
- `allows_overlap` (TINYINT) - Whether this role allows overlapping assignments

**Relationships:**
- Referenced by: `tim_timetable_cell_teacher.assignment_role_id`

**Growth Considerations:**
- Low growth (typically 3-5 roles)
- Static master data
- Used in many-to-many assignments

**Indexes:**
```sql
UNIQUE KEY `uq_teacher_assignment_role_code` (`code`)
```

---

### 4. tim_period_set
**Purpose:** Defines different period sets like Normal Day, Exam Day, Half Day etc.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `code` (VARCHAR 20) - Unique code like "NORMAL_8P", "EXAM_3P"
- `name` (VARCHAR 100) - Human-readable name
- `description` (VARCHAR 255) - Detailed description

**Relationships:**
- Referenced by: `tim_period_set_period.period_set_id`
- Referenced by: `tim_class_mode_rule.period_set_id`
- Referenced by: `tim_generation_run.period_set_id`

**Growth Considerations:**
- Low growth (typically 4-8 period sets per school)
- Configurable per school
- Referenced frequently during scheduling

**Indexes:**
```sql
UNIQUE KEY `uq_period_set_code` (`code`)
```

---

### 5. tim_period_set_period
**Purpose:** Defines individual periods within a period set with their timing and type.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `period_set_id` (BIGINT FK) - Reference to period set
- `period_ord` (TINYINT) - Ordinal number within the set (1, 2, 3...)
- `code` (VARCHAR 10) - Short code like "P1", "P2", "BREAK"
- `name` (VARCHAR 50) - Human-readable name
- `start_time` (TIME) - Period start time
- `end_time` (TIME) - Period end time
- `period_type_id` (BIGINT FK) - Reference to period type

**Relationships:**
- References: `tim_period_set.id`
- References: `tim_period_type.id`

**Growth Considerations:**
- Medium growth (8-12 periods per set × 4-8 sets = ~50-100 records)
- Static within academic year
- Critical for scheduling logic

**Indexes:**
```sql
UNIQUE KEY `uq_psp_set_ord` (`period_set_id`,`period_ord`)
KEY `idx_psp_period_set` (`period_set_id`)
KEY `idx_psp_period_type` (`period_type_id`)
```

---

### 6. tim_class_mode_rule
**Purpose:** Links classes to timetable modes with specific period sets and rules.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `class_id` (BIGINT FK) - Reference to sch_classes
- `mode_id` (BIGINT FK) - Reference to tim_timetable_mode
- `period_set_id` (BIGINT FK) - Reference to tim_period_set
- `allow_teaching_periods` (TINYINT) - Whether teaching periods allowed
- `allow_exam_periods` (TINYINT) - Whether exam periods allowed
- `exam_period_count` (TINYINT) - Number of exam periods if allowed

**Relationships:**
- References: `tim_timetable_mode.id`
- References: `tim_period_set.id`

**Growth Considerations:**
- Medium growth (classes × modes, typically 12 classes × 3 modes = 36 records)
- Configuration data
- Critical for mode-specific scheduling

**Indexes:**
```sql
UNIQUE KEY `uq_cmr_class_mode` (`class_id`,`mode_id`)
KEY `idx_cmr_mode` (`mode_id`)
KEY `idx_cmr_period_set` (`period_set_id`)
```

---

### 7. tim_class_group_requirement
**Purpose:** Defines timetable requirements for each class group (weekly periods, daily limits, etc.).

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `class_group_id` (BIGINT FK) - Reference to sch_class_groups_jnt
- `weekly_periods` (TINYINT) - Total periods required per week
- `max_per_day` (TINYINT) - Maximum periods allowed per day
- `min_gap_periods` (TINYINT) - Minimum gap between sessions
- `allow_consecutive` (TINYINT) - Whether consecutive periods allowed

**Relationships:**
- References: `sch_class_groups_jnt.id`

**Growth Considerations:**
- Medium growth (one per class group, typically 50-200 records)
- Configuration data
- Used in constraint evaluation

**Indexes:**
```sql
UNIQUE KEY `uq_cgr_class_group` (`class_group_id`)
```

---

### 8. tim_class_subgroup
**Purpose:** Defines subgroups within class groups for combined or split classes.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `class_group_id` (BIGINT FK) - Reference to sch_class_groups_jnt
- `code` (VARCHAR 20) - Unique code within class group
- `name` (VARCHAR 100) - Human-readable name
- `student_count` (INT) - Number of students in subgroup
- `is_shared_across_classes` (TINYINT) - Whether shared across classes

**Relationships:**
- References: `sch_class_groups_jnt.id`
- Referenced by: `tt_class_subgroup_member.class_subgroup_id`
- Referenced by: `tt_timetable_cell.class_subgroup_id`

**Growth Considerations:**
- High growth (multiple subgroups per class group, potentially 200-1000 records)
- Dynamic data
- Critical for combined class scheduling

**Indexes:**
```sql
UNIQUE KEY `uq_tim_group_code` (`class_group_id`,`code`)
KEY `idx_subgroup_class_group` (`class_group_id`)
```

---

### 9. tt_class_subgroup_member
**Purpose:** Links classes and sections to class subgroups.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `class_subgroup_id` (BIGINT FK) - Reference to tim_class_subgroup
- `class_id` (BIGINT FK) - Reference to sch_classes
- `section_id` (BIGINT FK) - Reference to sch_sections
- `is_primary` (TINYINT) - Whether this is the primary class

**Relationships:**
- References: `tim_class_subgroup.id`
- References: `sch_classes.id`
- References: `sch_sections.id`

**Growth Considerations:**
- High growth (multiple members per subgroup, potentially 500-2000 records)
- Junction table
- Used in complex scheduling scenarios

**Indexes:**
```sql
UNIQUE KEY `uq_csm_subgroup_class_section` (`class_subgroup_id`, `class_id`, `section_id`)
KEY `idx_csm_subgroup` (`class_subgroup_id`)
KEY `idx_csm_class` (`class_id`)
KEY `idx_csm_section` (`section_id`)
```

---

### 10. tim_generation_run
**Purpose:** Logs each timetable generation run with parameters and status.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `mode_id` (BIGINT FK) - Reference to tim_timetable_mode
- `period_set_id` (BIGINT FK) - Reference to tim_period_set
- `started_at` (DATETIME) - When generation started
- `finished_at` (DATETIME) - When generation finished
- `status` (ENUM) - RUNNING, SUCCESS, FAILED, CANCELLED
- `params_json` (JSON) - Generation parameters
- `stats_json` (JSON) - Generation statistics

**Relationships:**
- References: `tim_timetable_mode.id`
- References: `tim_period_set.id`
- Referenced by: `tt_timetable_cell.generation_run_id`

**Growth Considerations:**
- Medium growth (one per generation run, potentially 50-200 per year)
- Audit trail
- Used for rollback and analytics

**Indexes:**
```sql
KEY `idx_gr_mode` (`mode_id`)
KEY `idx_gr_period_set` (`period_set_id`)
KEY `idx_gr_started_at` (`started_at`)
```

---

### 11. tt_timetable_cell
**Purpose:** Represents individual timetable cells (periods) assigned to class groups on specific dates.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `generation_run_id` (BIGINT FK) - Reference to tim_generation_run
- `class_group_id` (BIGINT FK) - Reference to sch_class_groups_jnt (nullable)
- `class_subgroup_id` (BIGINT FK) - Reference to tim_class_subgroup (nullable)
- `date` (DATE) - Date of the timetable cell
- `period_ord` (TINYINT) - Ordinal number of the period
- `room_id` (BIGINT FK) - Reference to sch_rooms (nullable)
- `locked` (TINYINT) - Whether cell is locked from changes

**Relationships:**
- References: `tim_generation_run.id`
- References: `sch_class_groups_jnt.id`
- References: `tim_class_subgroup.id`
- Referenced by: `tim_timetable_cell_teacher.cell_id`
- Referenced by: `tim_substitution_log.cell_id`

**Growth Considerations:**
- Very high growth (classes × periods × days, potentially 10,000-50,000 records per generation)
- Core scheduling data
- Requires efficient indexing

**Indexes:**
```sql
KEY `idx_tc_generation_run` (`generation_run_id`)
KEY `idx_tc_class_group` (`class_group_id`)
KEY `idx_tc_class_subgroup` (`class_subgroup_id`)
KEY `idx_tc_date` (`date`)
KEY `idx_tc_room` (`room_id`)
COMPOSITE KEY `idx_tc_date_period` (`date`, `period_ord`)
```

---

### 12. tim_timetable_cell_teacher
**Purpose:** Links teachers to timetable cells with their assignment roles.

**Key Fields:**
- `cell_id` (BIGINT) - FK to tt_timetable_cell
- `teacher_id` (BIGINT) - FK to sch_users
- `assignment_role_id` (BIGINT) - FK to tim_teacher_assignment_role

**Relationships:**
- References: `tt_timetable_cell.id`
- References: `tim_teacher_assignment_role.id`

**Growth Considerations:**
- Very high growth (potentially 2-3× timetable cells)
- Many-to-many junction
- Critical for teacher workload calculations

**Indexes:**
```sql
PRIMARY KEY (`cell_id`,`teacher_id`)
KEY `idx_tct_cell` (`cell_id`)
KEY `idx_tct_teacher` (`teacher_id`)
KEY `idx_tct_assignment_role` (`assignment_role_id`)
```

---

### 13. tim_substitution_log
**Purpose:** Logs substitutions made for absent teachers.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `cell_id` (BIGINT FK) - Reference to tt_timetable_cell
- `absent_teacher_id` (BIGINT) - FK to sch_users
- `substitute_teacher_id` (BIGINT) - FK to sch_users
- `substituted_at` (TIMESTAMP) - When substitution occurred
- `reason` (VARCHAR 255) - Reason for substitution

**Relationships:**
- References: `tt_timetable_cell.id`

**Growth Considerations:**
- Medium growth (substitutions are exceptions, potentially 100-500 per year)
- Audit trail
- Used for attendance and reporting

**Indexes:**
```sql
KEY `idx_sub_cell` (`cell_id`)
KEY `idx_sub_absent_teacher` (`absent_teacher_id`)
KEY `idx_sub_substitute_teacher` (`substitute_teacher_id`)
KEY `idx_sub_substituted_at` (`substituted_at`)
```

---

### 14. tim_constraint
**Purpose:** Generic constraint engine for all timetable constraints.

**Key Fields:**
- `id` (BIGINT PRIMARY KEY) - Auto-incrementing identifier
- `target_type` (ENUM) - TEACHER, CLASS_GROUP, ROOM, GLOBAL
- `target_id` (BIGINT) - FK to relevant table (nullable for GLOBAL)
- `is_hard` (TINYINT) - Whether this is a hard constraint
- `weight` (TINYINT) - Weight for soft constraints
- `rule_json` (JSON) - Constraint rule definition

**Relationships:**
- Dynamic FK based on target_type

**Growth Considerations:**
- Medium growth (potentially 200-1000 constraints per school)
- Highly dynamic
- Requires JSON querying capabilities

**Indexes:**
```sql
KEY `idx_constraint_target` (`target_type`, `target_id`)
KEY `idx_constraint_active` (`is_active`)
```

---

## COMPOSITE INDEXES

```sql
-- For timetable cell queries (most frequent)
CREATE INDEX idx_tc_date_period_room ON tt_timetable_cell (`date`, `period_ord`, `room_id`);
CREATE INDEX idx_tc_generation_class ON tt_timetable_cell (`generation_run_id`, `class_group_id`);

-- For teacher workload calculations
CREATE INDEX idx_tct_teacher_date ON tim_timetable_cell_teacher (`teacher_id`, `cell_id`);

-- For constraint evaluation
CREATE INDEX idx_constraint_type_target ON tim_constraint (`target_type`, `target_id`, `is_active`);

-- For subgroup member queries
CREATE INDEX idx_csm_class_section ON tt_class_subgroup_member (`class_id`, `section_id`);
```

---

## SEED DATA

### Timetable Modes
```sql
INSERT INTO `tim_timetable_mode` (`code`, `name`, `description`, `has_exam`, `has_teaching`, `is_active`) VALUES
('REGULAR', 'Regular Timetable', 'Standard teaching timetable', 0, 1, 1),
('EXAM', 'Examination Timetable', 'Examination periods only', 1, 0, 1),
('SPECIAL_EVENT', 'Special Event', 'Holidays, events, special schedules', 0, 0, 1);
```

### Period Types
```sql
INSERT INTO `tim_period_type` (`code`, `name`, `description`, `counts_as_teaching`, `counts_as_exam`, `is_active`) VALUES
('TEACHING', 'Teaching Period', 'Regular teaching period', 1, 0, 1),
('EXAMINATION', 'Examination Period', 'Examination period', 0, 1, 1),
('BREAK', 'Break Period', 'Break between periods', 0, 0, 1),
('ASSEMBLY', 'Assembly', 'School assembly', 0, 0, 1),
('LUNCH', 'Lunch Break', 'Lunch period', 0, 0, 1);
```

### Teacher Assignment Roles
```sql
INSERT INTO `tim_teacher_assignment_role` (`code`, `name`, `description`, `is_primary_instructor`, `counts_for_workload`, `allows_overlap`, `is_active`) VALUES
('PRIMARY_INSTRUCTOR', 'Primary Instructor', 'Main teacher for the period', 1, 1, 0, 1),
('ASSISTANT_INSTRUCTOR', 'Assistant Instructor', 'Assistant teacher', 0, 1, 0, 1),
('SUBSTITUTE', 'Substitute Teacher', 'Replacement teacher', 0, 1, 1, 1);
```

### Sample Period Sets
```sql
INSERT INTO `tim_period_set` (`code`, `name`, `description`, `is_active`) VALUES
('NORMAL_8P', 'Normal Day 8 Periods', 'Standard school day with 8 periods', 1),
('EXAM_3P', 'Examination Day 3 Periods', 'Exam day with 3 exam periods', 1),
('HALF_DAY_4P', 'Half Day 4 Periods', 'Half day schedule', 1),
('TODDLER_6P', 'Toddler Day 6 Periods', 'Toddler schedule with shorter periods', 1);
```

---

## SCHEMA VALIDATION

### Foreign Key Constraints
- All FK constraints properly defined with CASCADE/RESTRICT as appropriate
- Composite primary keys used for junction tables
- Unique constraints prevent data duplication

### Data Types
- BIGINT for all ID fields (future-proofing)
- VARCHAR lengths appropriate for expected data
- TINYINT for boolean flags
- ENUM for status fields
- JSON for flexible constraint definitions
- TIMESTAMP/DATETIME for temporal data

### Soft Delete Pattern
- `is_deleted` TINYINT fields on all transactional tables
- `deleted_at` TIMESTAMP fields for audit trail
- `is_active` TINYINT for logical activation/deactivation

### Indexing Strategy
- Primary keys automatically indexed
- Foreign keys indexed for join performance
- Composite indexes for common query patterns
- Date/time indexes for temporal queries

---

## PERFORMANCE CONSIDERATIONS

### Query Optimization
1. **Timetable Cell Queries**: Most frequent - optimized with composite indexes
2. **Teacher Workload**: Daily aggregations - indexed by teacher and date
3. **Constraint Evaluation**: JSON queries - requires MySQL 8.x JSON functions
4. **Generation Runs**: Audit queries - indexed by status and timestamps

### Partitioning Strategy (Future)
- `tt_timetable_cell`: Partition by date ranges (monthly/academic year)
- `tim_substitution_log`: Partition by academic year
- `tim_generation_run`: Partition by year

### Caching Strategy
- Master data (modes, types, roles): Application cache
- Active constraints: Redis cache with TTL
- Current timetable: Memory cache during generation

---

**Document Created By:** ERP Architect GPT  
**Last Reviewed:** December 14, 2025  
**Next Review Date:** March 14, 2026  
**Version Control:** Initial creation