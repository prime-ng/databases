# MSG — MarksheetGeneration Data Dictionary
**Version:** 1.0 | **Date:** 2026-04-13 | **Tables:** 23 | **Prefix:** `msh_*`

---

## Table Index

| # | Table | Domain | Purpose | Est. Rows/School/Year |
|---|---|---|---|---|
| 1 | `msh_marksheet_types` | Master | School-configurable marksheet types | 5-8 |
| 2 | `msh_source_components` | Master | Fixed assessment sources (seeded) | 4 |
| 3 | `msh_ia_component_types` | Master | IA component types (seeded + extensible) | 4-6 |
| 4 | `msh_class_groups` | Configuration | Marksheet class grouping | 3-5 |
| 5 | `msh_class_group_items_jnt` | Configuration | Classes in class groups | 15-20 |
| 6 | `msh_exam_groups` | Configuration | Exam term grouping | 2-4 |
| 7 | `msh_exam_group_items_jnt` | Configuration | Exam types in groups | 6-12 |
| 8 | `msh_config_templates` | Configuration | Marksheet config blueprint | 3-6 |
| 9 | `msh_template_scholastic_components` | Configuration | Source component weightages | 8-24 |
| 10 | `msh_template_exam_weightages` | Configuration | Per-exam weightages | 9-36 |
| 11 | `msh_template_ia_components` | Configuration | IA definitions per template | 6-24 |
| 12 | `msh_template_coscholastic_components` | Configuration | Co-scholastic areas per template | 9-30 |
| 13 | `msh_class_config_jnt` | Configuration | Template ↔ class/group assignment | 10-20 |
| 14 | `msh_subject_practical_configs` | Configuration | Theory/Practical split | 5-15 |
| 15 | `msh_marksheet_schedules` | Schedule | Marksheet generation events | 4-10 |
| 16 | `msh_schedule_class_jnt` | Schedule | Class-sections per schedule | 10-60 |
| 17 | `msh_student_results` | Result | Aggregate per-student results | 2K-8K |
| 18 | `msh_student_subject_results` | Result | Per-subject per-student | 12K-60K |
| 19 | `msh_student_subject_exam_marks` | Result | Exam marks matrix | 60K-400K |
| 20 | `msh_student_ia_marks` | Result | IA marks per student/subject | 24K-120K |
| 21 | `msh_student_coscholastic_results` | Result | Co-Scholastic grades | 6K-20K |
| 22 | `msh_student_attendance` | Result | Attendance summary | 2K-8K |
| 23 | `msh_computation_logs` | Audit | Computation audit trail | 10-30 |

---

## Detailed Table Definitions

---

### Table 1: `msh_marksheet_types`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Master
Purpose:     School-configurable marksheet types (Unit Test, Term-1, Annual)
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| code | VARCHAR(30) | NO | — | — | Machine-readable code (UNIT_TEST, TERM1, ANNUAL) |
| name | VARCHAR(100) | NO | — | — | Display name |
| description | VARCHAR(255) | YES | NULL | — | Optional description |
| display_order | SMALLINT UNSIGNED | NO | 1 | — | Sort order in UI |
| is_active | TINYINT(1) | NO | 1 | — | Soft active flag |
| created_by | INT UNSIGNED | NO | — | sys_users.id | Creator |
| updated_by | INT UNSIGNED | YES | NULL | sys_users.id | Last editor |

**Indexes:**
| Name | Columns | Type | Purpose |
|---|---|---|---|
| PRIMARY | id | PK | — |
| uq_msh_mt_code | code | UNIQUE | No duplicate type codes |

**Sample Data:**
| id | code | name | display_order |
|---|---|---|---|
| 1 | UNIT_TEST | Unit Test Result | 1 |
| 2 | TERM1 | Term-1 Report Card | 2 |
| 3 | ANNUAL | Annual Report Card | 3 |

---

### Table 2: `msh_source_components`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Master
Purpose:     Fixed lookup of assessment sources (seeded at tenant onboarding)
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| code | VARCHAR(30) | NO | — | — | EXAM, HOMEWORK, QUIZ, QUEST |
| name | VARCHAR(100) | NO | — | — | Display name |
| is_mandatory | TINYINT(1) | NO | 0 | — | 1 for Exam (always required) |

**Seed Data (4 rows — fixed):**
| id | code | name | is_mandatory |
|---|---|---|---|
| 1 | EXAM | Examination | 1 |
| 2 | HOMEWORK | Homework | 0 |
| 3 | QUIZ | Quiz | 0 |
| 4 | QUEST | Quest | 0 |

---

### Table 8: `msh_config_templates`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Configuration
Purpose:     Reusable marksheet configuration blueprint per academic session
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| academic_session_id | SMALLINT UNSIGNED | NO | — | sch_org_academic_sessions_jnt.id | Academic session |
| marksheet_type_id | INT UNSIGNED | NO | — | msh_marksheet_types.id | Which marksheet type |
| exam_group_id | INT UNSIGNED | NO | — | msh_exam_groups.id | Which exams covered |
| grading_schema_id | INT UNSIGNED | YES | NULL | slb_grade_division_master.id | Grading schema |
| code | VARCHAR(50) | NO | — | — | Template code |
| name | VARCHAR(150) | NO | — | — | Template display name |
| board_code | VARCHAR(50) | YES | NULL | — | CBSE, ICSE, STATE, CUSTOM |
| passing_percentage | DECIMAL(5,2) | NO | 33.00 | — | Min % to pass a subject |
| compartment_max_failures | TINYINT UNSIGNED | NO | 2 | — | Max fails for compartment |
| is_best_of_n_enabled | TINYINT(1) | NO | 0 | — | Best-of-N toggle |
| best_of_n_count | TINYINT UNSIGNED | YES | NULL | — | How many to pick |
| is_locked | TINYINT(1) | NO | 0 | — | Immutable after publication |

**Sample Data:**
| id | code | name | board_code | passing_percentage | exam_group_id |
|---|---|---|---|---|---|
| 1 | CBSE_SEC_T1_2025 | CBSE Secondary Term-1 2025-26 | CBSE | 33.00 | 1 |
| 2 | CBSE_PRI_ANN_2025 | CBSE Primary Annual 2025-26 | CBSE | 33.00 | 3 |

---

### Table 15: `msh_marksheet_schedules`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Schedule
Purpose:     Defines a marksheet generation event (trigger for computation)
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| config_template_id | INT UNSIGNED | NO | — | msh_config_templates.id | Which template drives this |
| academic_session_id | SMALLINT UNSIGNED | NO | — | sch_org_academic_sessions_jnt.id | Session |
| code | VARCHAR(50) | NO | — | — | Schedule code |
| name | VARCHAR(150) | NO | — | — | Display name |
| status_id | INT UNSIGNED | NO | — | sys_dropdown_table.id | DRAFT/COMPUTED/REVIEWED/PUBLISHED/LOCKED |
| last_computed_at | DATETIME | YES | NULL | — | Last successful computation |
| total_students | INT UNSIGNED | YES | NULL | — | Populated after computation |
| is_locked | TINYINT(1) | NO | 0 | — | Publication lock flag |
| unlock_reason | TEXT | YES | NULL | — | Required when admin unlocks |

**Status Lifecycle:**
```
DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED
                      ↑                     │
                      └──── UNLOCK ─────────┘
```

**sys_dropdown_table seed (key: `msh_marksheet_schedules.status_id`):**
| ordinal | value | description |
|---|---|---|
| 1 | DRAFT | Schedule created, not yet computed |
| 2 | COMPUTED | Results computed, awaiting review |
| 3 | REVIEWED | Results reviewed by principal/teacher |
| 4 | PUBLISHED | Visible to students and parents |
| 5 | LOCKED | Permanently frozen (archive) |

---

### Table 17: `msh_student_results`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Result
Purpose:     Aggregate result per student per schedule (grand total, rank, promotion)
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| schedule_id | INT UNSIGNED | NO | — | msh_marksheet_schedules.id | Which schedule |
| student_id | INT UNSIGNED | NO | — | std_students.id | Which student |
| class_section_id | INT UNSIGNED | NO | — | sch_class_section_jnt.id | Denormalized for query |
| grand_total | DECIMAL(8,2) | YES | NULL | — | Sum of all subject totals |
| grand_max | DECIMAL(8,2) | YES | NULL | — | Sum of all subject max marks |
| overall_percentage | DECIMAL(5,2) | YES | NULL | — | grand_total / grand_max * 100 |
| overall_grade | VARCHAR(10) | YES | NULL | — | A1, A2, B1, etc. |
| division | VARCHAR(30) | YES | NULL | — | First, Second, Third, Pass, Fail |
| rank_in_section | INT UNSIGNED | YES | NULL | — | Rank within class-section |
| rank_in_class | INT UNSIGNED | YES | NULL | — | Rank within entire class |
| total_subjects | TINYINT UNSIGNED | YES | NULL | — | Total subjects assessed |
| subjects_passed | TINYINT UNSIGNED | YES | NULL | — | Count passed |
| subjects_failed | TINYINT UNSIGNED | YES | NULL | — | Count failed |
| promotion_status | VARCHAR(30) | YES | NULL | — | PROMOTED/DETAINED/COMPARTMENT/PLACED |
| result_status | VARCHAR(20) | YES | NULL | — | DECLARED/WITHHELD |

**Sample Data:**
| schedule_id | student_id | grand_total | overall_percentage | overall_grade | rank_in_section | promotion_status |
|---|---|---|---|---|---|---|
| 1 | 101 | 487.50 | 81.25 | A2 | 3 | PROMOTED |
| 1 | 102 | 312.00 | 52.00 | C1 | 28 | PROMOTED |
| 1 | 103 | NULL | NULL | NULL | NULL | WITHHELD |

---

### Table 18: `msh_student_subject_results`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Result
Purpose:     Per-subject result per student (component breakdown + total + grade)
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| schedule_id | INT UNSIGNED | NO | — | msh_marksheet_schedules.id | Schedule |
| student_id | INT UNSIGNED | NO | — | std_students.id | Student |
| subject_id | INT UNSIGNED | NO | — | sch_subjects.id | Subject |
| exam_weighted_total | DECIMAL(8,2) | YES | NULL | — | Weighted exam total |
| theory_marks | DECIMAL(8,2) | YES | NULL | — | Theory portion (NULL if no practical) |
| practical_marks | DECIMAL(8,2) | YES | NULL | — | Practical portion (NULL if no practical) |
| homework_score | DECIMAL(8,2) | YES | NULL | — | Homework component |
| quiz_score | DECIMAL(8,2) | YES | NULL | — | Quiz component |
| quest_score | DECIMAL(8,2) | YES | NULL | — | Quest component |
| ia_total | DECIMAL(8,2) | YES | NULL | — | Sum of IA marks |
| subject_total | DECIMAL(8,2) | YES | NULL | — | All components combined |
| subject_max | DECIMAL(8,2) | YES | NULL | — | Max possible |
| subject_percentage | DECIMAL(5,2) | YES | NULL | — | Percentage |
| subject_grade | VARCHAR(10) | YES | NULL | — | Grade (A1, A2, etc.) |
| is_passed | TINYINT(1) | YES | NULL | — | 1=pass, 0=fail |

**Sample Data:**
| student_id | subject_id | exam_weighted_total | theory_marks | practical_marks | ia_total | subject_total | subject_grade | is_passed |
|---|---|---|---|---|---|---|---|---|
| 101 | 5 (Science) | 64.00 | 52.00 | 25.00 | 8.00 | 97.00 | A1 | 1 |
| 101 | 3 (Math) | 58.00 | NULL | NULL | 7.00 | 65.00 | B2 | 1 |
| 102 | 5 (Science) | NULL | NULL | NULL | NULL | NULL | AB | NULL |

---

### Table 19: `msh_student_subject_exam_marks`
```
Schema:      tenant_db
Module:      MarksheetGeneration
Domain:      Result
Purpose:     Raw exam marks matrix — the cells of the marksheet table (student × subject × exam)
```

| Column | Data Type | Nullable | Default | FK Reference | Business Meaning |
|---|---|---|---|---|---|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| schedule_id | INT UNSIGNED | NO | — | msh_marksheet_schedules.id | Schedule |
| student_id | INT UNSIGNED | NO | — | std_students.id | Student |
| subject_id | INT UNSIGNED | NO | — | sch_subjects.id | Subject |
| exam_type_id | INT UNSIGNED | NO | — | lms_exam_types.id | UT-1, UT-2, HY-EXAM, etc. |
| marks_obtained | DECIMAL(8,2) | YES | NULL | — | Marks. NULL = absent |
| max_marks | DECIMAL(8,2) | YES | NULL | — | Max possible for this exam-subject |
| result_status | VARCHAR(20) | YES | NULL | — | PASS/FAIL/ABSENT/WITHHELD |
| exam_result_id | INT UNSIGNED | YES | NULL | lms_exam_results.id | Source traceability |

**Sample Data (Term-1 marksheet, Student 101, Science subject):**
| student_id | subject_id | exam_type_id | marks_obtained | max_marks | result_status |
|---|---|---|---|---|---|
| 101 | 5 | 1 (UT-1) | 8.00 | 10.00 | PASS |
| 101 | 5 | 2 (UT-2) | 7.00 | 10.00 | PASS |
| 101 | 5 | 5 (HY-EXAM) | 52.00 | 70.00 | PASS |

---

## Entity Relationship Diagram (Text-Based)

```
MASTERS (no FK deps within msh_*):
  msh_marksheet_types
  msh_source_components
  msh_ia_component_types

CONFIGURATION:
  msh_class_groups
    ← msh_class_group_items_jnt → sch_classes
    ← msh_class_config_jnt → msh_config_templates

  msh_exam_groups → sch_org_academic_sessions_jnt
    ← msh_exam_group_items_jnt → lms_exam_types

  msh_config_templates → sch_org_academic_sessions_jnt
                       → msh_marksheet_types
                       → msh_exam_groups
                       → slb_grade_division_master
    ← msh_template_scholastic_components → msh_source_components
    ← msh_template_exam_weightages → lms_exam_types
    ← msh_template_ia_components → msh_ia_component_types
    ← msh_template_coscholastic_components
    ← msh_class_config_jnt → sch_classes / msh_class_groups

  msh_subject_practical_configs → sch_org_academic_sessions_jnt
                                → sch_classes
                                → sch_subjects

SCHEDULE:
  msh_marksheet_schedules → msh_config_templates
                          → sch_org_academic_sessions_jnt
                          → sys_dropdown_table (status)
    ← msh_schedule_class_jnt → sch_class_section_jnt

RESULTS (all → msh_marksheet_schedules, → std_students):
  msh_student_results → sch_class_section_jnt
  msh_student_subject_results → sch_subjects
  msh_student_subject_exam_marks → sch_subjects, lms_exam_types, lms_exam_results
  msh_student_ia_marks → sch_subjects, msh_template_ia_components
  msh_student_coscholastic_results → msh_template_coscholastic_components
  msh_student_attendance

AUDIT:
  msh_computation_logs → msh_marksheet_schedules
```

---

## Cross-Module FK Type Reference

| External Table | PK Type | Used In |
|---|---|---|
| `sch_classes.id` | INT UNSIGNED | class_group_items_jnt, class_config_jnt, subject_practical_configs |
| `sch_sections.id` | INT UNSIGNED | — (not directly referenced) |
| `sch_class_section_jnt.id` | INT UNSIGNED | schedule_class_jnt, student_results |
| `sch_subjects.id` | INT UNSIGNED | subject_practical_configs, student_subject_results, student_subject_exam_marks, student_ia_marks |
| `sch_org_academic_sessions_jnt.id` | SMALLINT UNSIGNED | exam_groups, config_templates, marksheet_schedules, subject_practical_configs |
| `std_students.id` | INT UNSIGNED | all 6 result tables |
| `sys_users.id` | INT UNSIGNED | created_by, updated_by across all tables |
| `sys_dropdown_table.id` | INT UNSIGNED | marksheet_schedules.status_id |
| `slb_grade_division_master.id` | INT UNSIGNED | config_templates.grading_schema_id |
| `lms_exam_types.id` | INT UNSIGNED | exam_group_items_jnt, template_exam_weightages, student_subject_exam_marks |
| `lms_exam_results.id` | INT UNSIGNED | student_subject_exam_marks.exam_result_id (traceability) |
