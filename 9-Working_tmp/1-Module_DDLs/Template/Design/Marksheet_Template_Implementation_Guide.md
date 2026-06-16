# Marksheet Template Integration - Implementation Guide

> **Cross-Module Integration:** MarksheetGeneration (MSG) + Template (TMP)
> **Version:** 1.0 - April 2026
> **Author:** Brijesh (Enterprise Architect)
> **Source DDLs:** MSG_DDL_v1.sql (23 tables), tmp_Config_DDL_v5.sql (6 tables)

---

## 1. Executive Summary

This guide defines the end-to-end implementation for generating and displaying student marksheets using two independent modules:

| Module | Responsibility | Tables Used |
|--------|---------------|-------------|
| **MarksheetGeneration (MSG)** | Data computation - creates the marksheet data (marks, grades, ranks, promotion) | 23 `msh_*` tables |
| **Template (TMP)** | Visual presentation - provides the template design and layout for displaying/printing the marksheet | 6 `tmp_*` tables |

**Key Architectural Principle:** These modules are **NOT FK-coupled**. They are combined at render time by the service layer. MSG owns the data; TMP owns the presentation.

```
  +--------------------------+          +-------------------------+
  |  MSG Module              |          |  TMP Module             |
  |  (Data Engine)           |          |  (Presentation Engine)  |
  |                          |          |                         |
  |  Configuration           |          |  Template Type          |
  |    + Weightages          |          |    + Purpose            |
  |    + Grading             |          |    + Variables          |
  |    + Pass Criteria       |          |    + Canvas/HTML        |
  |                          |          |                         |
  |  Computation             |          |  Assignment             |
  |    + Exam Marks          |          |    + Class Scope        |
  |    + IA Marks            |          |    + Group Scope        |
  |    + Co-Scholastic       |          |    + School-Wide        |
  |    + Attendance          |          |                         |
  |                          |          |                         |
  |  Results                 |          |                         |
  |    + Student Results     |          |                         |
  |    + Subject Results     |          |                         |
  |    + Ranks & Promotion   |          |                         |
  +-----------+--------------+          +------------+------------+
              |                                      |
              |        +------------------------+    |
              +------->|  Marksheet Render       |<--+
                       |  Service Layer          |
                       |                         |
                       |  1. Resolve Template    |
                       |  2. Fetch MSG Data      |
                       |  3. Map Variables       |
                       |  4. Render HTML/PDF     |
                       +------------------------+
```

---

## 2. Complete End-to-End Flow

### 2.1 High-Level Lifecycle

The marksheet lifecycle spans both modules across 6 phases:

```
  PHASE 1              PHASE 2              PHASE 3             PHASE 4
  MSG Setup            TMP Setup            MSG Computation     TMP Resolution
  ──────────           ─────────            ───────────────     ──────────────
  Configure            Design               Compute marks       Resolve template
  marksheet            template             & grades            for class
  templates            layout                                   
  (data rules)         (visual design)                          

        |                   |                     |                    |
        v                   v                     v                    v
  ┌───────────┐     ┌───────────────┐     ┌───────────────┐    ┌─────────────┐
  │ msh_config│     │ tmp_templates │     │ msh_student_  │    │ tmp_template│
  │ _templates│     │ (canvas_json, │     │ results       │    │ _assignments│
  │           │     │  html_content)│     │ msh_student_  │    │ (scope      │
  │ msh_class │     │ tmp_template_ │     │ subject_      │    │  resolution)│
  │ _config_  │     │ variables     │     │ results       │    │             │
  │ jnt       │     │ tmp_template_ │     │ msh_student_  │    │             │
  │           │     │ assignments   │     │ subject_exam_ │    │             │
  └─────┬─────┘     └───────┬───────┘     │ marks         │    └──────┬──────┘
        │                   │             └───────┬───────┘           │
        │                   │                     │                   │
        v                   v                     v                   v
  ┌───────────────────────────────────────────────────────────────────────────┐
  │                     PHASE 5: RENDER (Service Layer)                       │
  │                                                                           │
  │  1. Get schedule_id + student_id + class_id                               │
  │  2. Resolve MSG config template   (msh_class_config_jnt)                  │
  │  3. Resolve TMP visual template   (tmp_template_assignments)              │
  │  4. Fetch computed results        (msh_student_results + subject_results) │
  │  5. Build variable context map    (MSG data → TMP variable names)         │
  │  6. Render template               (replace {{placeholders}} with data)    │
  │  7. Return HTML or generate PDF                                           │
  └───────────────────────────────────────────────────────────┬───────────────┘
                                                              │
                                                              v
                                                    PHASE 6: DISPLAY
                                                    ─────────────────
                                                    Student Portal
                                                    Teacher View
                                                    PDF Download
                                                    Print
```

### 2.2 Phase-by-Phase Detail

---

## 3. PHASE 1 - MSG Configuration (Data Rules)

> **Who:** School Admin | **When:** Start of academic session | **Frequency:** Once per session

This phase sets up **what** data the marksheet contains and **how** marks are computed.

### 3.1 Configuration Sequence

```
  Step 1: Define Marksheet Types (if not already done)
  ┌────────────────────────────────────────────────────────┐
  │  TABLE: msh_marksheet_types                            │
  │  Examples:                                             │
  │    UNIT_TEST  → "Unit Test Result"                     │
  │    TERM1      → "Term-1 Report Card"                   │
  │    ANNUAL     → "Annual Report Card"                   │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 2: Define Class Groups      │
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: msh_class_groups + msh_class_group_items_jnt   │
  │  Examples:                                             │
  │    PRIMARY      → Class 1, 2, 3, 4, 5                  │
  │    MIDDLE       → Class 6, 7, 8                        │
  │    SECONDARY    → Class 9, 10                          │
  │    SR_SECONDARY → Class 11, 12                         │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 3: Create Exam Groups       │
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: msh_exam_groups + msh_exam_group_items_jnt     │
  │  Examples:                                             │
  │    TERM1 (Apr-Sep) → [UT-1, UT-2, Half-Yearly]         │
  │    TERM2 (Oct-Mar) → [UT-3, UT-4, Annual Exam]         │
  │    ANNUAL          → [All 6 exam types]                │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 4: Create Config Templates  │
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: msh_config_templates                           │
  │  Links: marksheet_type + exam_group + grading_schema   │
  │  Rules: passing_percentage, compartment_max_failures,  │
  │         is_best_of_n_enabled, best_of_n_count          │
  │                                                        │
  │  Example: "CBSE Secondary Term-1 Template 2025-26"     │
  │    marksheet_type = TERM1                              │
  │    exam_group     = TERM1 (UT-1 + UT-2 + HY)           │
  │    grading_schema = CBSE (A1/A2/B1/B2/C1/C2/D/E)       │
  │    passing_%      = 33.00                              │
  │    compartment    = max 2 subjects                     │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 5: Configure Components     │
  ┌────────────────────────────────▼────────────────────────┐
  │  TABLE: msh_template_scholastic_components              │
  │    Exam=80%, Homework=10%, Quiz=5%, Quest=5%            │
  │    (Must sum to 100%)                                   │
  │                                                         │
  │  TABLE: msh_template_exam_weightages                    │
  │    UT-1=10%, UT-2=10%, Half-Yearly=80%                  │
  │    (Must sum to 100%)                                   │
  │                                                         │
  │  TABLE: msh_template_ia_components                      │
  │    Notebook=5, Subject Enrichment=5                     │
  │                                                         │
  │  TABLE: msh_template_coscholastic_components            │
  │    Work Education (3-point), Art (3-point),             │
  │    Health & PE (3-point), Discipline (BA-linked)        │
  └─────────────────────────────────┬───────────────────────┘
                                    │
  Step 6: Assign Template to Classes│
  ┌─────────────────────────────────▼───────────────────────┐
  │  TABLE: msh_class_config_jnt                            │
  │    config_template → class_group_id = SECONDARY         │
  │    (or override: config_template → class_id = Class 10) │
  │                                                         │
  │  TABLE: msh_subject_practical_configs                   │
  │    Class 9 Science: Theory=70, Practical=30             │
  └─────────────────────────────────────────────────────────┘
```

---

## 4. PHASE 2 - TMP Configuration (Visual Design)

> **Who:** School Admin / Template Designer | **When:** Anytime before marksheet display | **Frequency:** Once per template design

This phase sets up **how** the marksheet looks visually.

### 4.1 Template Design Sequence

```
  Step 1: Verify Template Type Exists
  ┌────────────────────────────────────────────────────────┐
  │  TABLE: tmp_templates_type                             │
  │  Check: MARKSHEET type exists (seeded at onboarding)   │
  │  ► id=1, name='MARKSHEET', is_active=1                 │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 2: Verify Purpose Exists    │
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: tmp_template_purposes                          │
  │  Check: MARKSHEET_PRINT purpose exists (seeded)        │
  │  ► code='MARKSHEET_PRINT', scope_type=CLASS_SCOPED     │
  │                                                        │
  │  CLASS_SCOPED means: supports class, class-group,      │
  │  AND school-wide template assignment                   │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 3: Define Template Variables│
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: tmp_template_variables                         │
  │  Scope: template_type_id = MARKSHEET                   │
  │                                                        │
  │  See Section 6 for complete variable list.             │
  │  Variables are type-scoped, so all MARKSHEET templates │
  │  share the same variable pool.                         │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 4: Create Template Design   │
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: tmp_templates                                  │
  │                                                        │
  │  ► code = 'CBSE_SEC_MARKSHEET_V1'                      │
  │  ► name = 'CBSE Secondary Marksheet Template'          │
  │  ► type_id = MARKSHEET                                 │
  │  ► canvas_json = { ... drag-drop layout positions }    │
  │  ► html_content = '<div class="marksheet">             │
  │      <h1>{{school_name}}</h1>                          │
  │      <img src="{{school_logo}}">                       │
  │      <p>Student: {{student_name}}</p>                  │
  │      <p>Class: {{class_name}} - {{section_name}}</p>   │
  │      <table>{{subject_marks_table}}</table>            │
  │      <p>Total: {{grand_total}} / {{grand_max}}</p>     │
  │      <p>Grade: {{overall_grade}}</p>                   │
  │      ...'                                              │
  │  ► is_active = 1                                       │
  └────────────────────────────────┬───────────────────────┘
                                   │
  Step 5: Map Variables to Template│
  ┌────────────────────────────────▼─────────────────────────┐
  │  TABLE: tmp_templates_variables_jnt                      │
  │                                                          │
  │  Map each variable to this specific template:            │
  │  ► template_id = CBSE_SEC_MARKSHEET_V1                   │
  │  ► variable_id = student_name (display_order=1)          │
  │  ► variable_id = class_name   (display_order=2)          │
  │  ► variable_id = grand_total  (display_order=3)          │
  │  ► ...                                                   │
  │                                                          │
  │  Can set default_value for fallback:                     │
  │  ► variable_id = school_logo, default_value='default.png'│
  └────────────────────────────────┬─────────────────────────┘
                                   │
  Step 6: Assign Template to Scope │
  ┌────────────────────────────────▼───────────────────────┐
  │  TABLE: tmp_template_assignments                       │
  │                                                        │
  │  ► template_id         = CBSE_SEC_MARKSHEET_V1         │
  │  ► purpose_id          = MARKSHEET_PRINT               │
  │  ► academic_session_id = 2025-26 session               │
  │                                                        │
  │  Scope options (pick one):                             │
  │    A) class_id = Class 10        (direct, highest)     │
  │    B) class_group_id = SECONDARY (group, fallback)     │
  │    C) both NULL                  (school-wide, lowest) │
  │                                                        │
  │  scope_hash auto-generates:                            │
  │    A) "1:3:C10"                                        │
  │    B) "1:3:G2"                                         │
  │    C) "1:3:SCHOOL"                                     │
  │  (Enforces uniqueness across scope types)              │
  └────────────────────────────────────────────────────────┘
```

### 4.2 Multiple Template Designs per School

A school can create different visual templates for different class groups:

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  Template Assignments for Session 2025-26:                              │
  │                                                                         │
  │  MARKSHEET_PRINT + Session 2025-26:                                     │
  │  ┌──────────────────────────────────────────────────────────────────┐   │
  │  │  PRIMARY (Class 1-5):                                            │   │
  │  │    → tmp_templates.code = 'PRIMARY_MARKSHEET_V1'                 │   │
  │  │    → Colorful design, star ratings, smiley faces                 │   │
  │  │    → scope: class_group_id = PRIMARY                             │   │
  │  └──────────────────────────────────────────────────────────────────┘   │
  │  ┌──────────────────────────────────────────────────────────────────┐   │
  │  │  MIDDLE (Class 6-8):                                             │   │
  │  │    → tmp_templates.code = 'MIDDLE_MARKSHEET_V1'                  │   │
  │  │    → Standard marks table, grade column                          │   │
  │  │    → scope: class_group_id = MIDDLE                              │   │
  │  └──────────────────────────────────────────────────────────────────┘   │
  │  ┌──────────────────────────────────────────────────────────────────┐   │
  │  │  SECONDARY (Class 9-10):                                         │   │
  │  │    → tmp_templates.code = 'CBSE_SEC_MARKSHEET_V1'                │   │
  │  │    → CBSE format with theory/practical split, IA columns         │   │
  │  │    → scope: class_group_id = SECONDARY                           │   │
  │  └──────────────────────────────────────────────────────────────────┘   │
  │  ┌──────────────────────────────────────────────────────────────────┐   │
  │  │  Class 10 Override:                                              │   │
  │  │    → tmp_templates.code = 'CLASS10_BOARD_MARKSHEET_V1'           │   │
  │  │    → Board exam format (different from regular SECONDARY)        │   │
  │  │    → scope: class_id = Class 10 (overrides SECONDARY group)      │   │
  │  └──────────────────────────────────────────────────────────────────┘   │
  └─────────────────────────────────────────────────────────────────────────┘
```

---

## 5. PHASE 3 - MSG Computation (Data Creation)

> **Who:** Admin triggers | **When:** After teachers enter all marks | **Frequency:** Per schedule

This phase computes the actual marksheet data. It is fully within the MSG module.

### 5.1 Pre-Computation Checklist

Before computation can run, these must be complete:

```
  PREREQUISITE CHECKLIST:
  ┌──────────────────────────────────────────────────────────────────────┐
  │  [x] Exam results entered in lms_exam_results (LMS Module)           │
  │  [x] IA marks entered by subject teachers (msh_student_ia_marks)     │
  │  [x] Co-scholastic grades entered by class teacher                   │
  │      (msh_student_coscholastic_results)                              │
  │  [x] Attendance summary entered (msh_student_attendance)             │
  │  [x] Schedule created in DRAFT status                                │
  │  [x] Class-sections assigned to schedule                             │
  └──────────────────────────────────────────────────────────────────────┘
```

### 5.2 Computation Pipeline (ComputeMarksheetJob)

```
  Admin clicks "Compute" on schedule
           │
           ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │  1. PULL exam marks from lms_exam_results                            │
  │     → WRITE to msh_student_subject_exam_marks                        │
  │     (stores marks + exam_result_id for traceability)                 │
  │                                                                      │
  │  2. APPLY exam-type weightages                                       │
  │     → UT-1(10%) + UT-2(10%) + HY(80%) = exam_weighted_total          │
  │     → If best-of-N: pick top N unit test scores only                 │
  │                                                                      │
  │  3. APPLY theory/practical split (if subject has practical)          │
  │     → Split exam_weighted_total into theory_marks + practical_marks  │
  │                                                                      │
  │  4. FETCH homework/quiz/quest scores from LMS modules                │
  │     → Filtered by exam_group date range (start_date..end_date)       │
  │                                                                      │
  │  5. READ IA marks (already entered by teachers)                      │
  │     → Sum into ia_total per subject                                  │
  │                                                                      │
  │  6. APPLY component weightages                                       │
  │     → Exam(80%) + HW(10%) + Quiz(5%) + Quest(5%)                     │
  │     → WRITE to msh_student_subject_results                           │
  │     → Look up grade from slb_grade_division_master                   │
  │     → Determine pass/fail (>= passing_percentage)                    │
  │                                                                      │
  │  7. AGGREGATE across all subjects per student                        │
  │     → grand_total, grand_max, overall_percentage, overall_grade      │
  │     → subjects_passed, subjects_failed                               │
  │     → promotion_status (PROMOTED/DETAINED/COMPARTMENT)               │
  │     → WRITE to msh_student_results                                   │
  │                                                                      │
  │  8. COMPUTE ranks (dense ranking by percentage)                      │
  │     → rank_in_section, rank_in_class                                 │
  │     → UPDATE msh_student_results                                     │
  │                                                                      │
  │  9. UPDATE schedule status → COMPUTED                                │
  │     → Log to msh_computation_logs                                    │
  └──────────────────────────────────────────────────────────────────────┘
```

### 5.3 Result Data Structure After Computation

After computation, the data stored across MSG result tables for ONE student looks like:

```
  Student: Rahul (Class 9-A, Schedule: TERM1_SEC_2025)
  ═══════════════════════════════════════════════════════════════════════

  msh_student_results (1 row):
  ┌───────────────────────────────────────────────────────────────────┐
  │  grand_total       = 458.50                                       │
  │  grand_max         = 600.00                                       │
  │  overall_percentage= 76.42                                        │
  │  overall_grade     = B1                                           │
  │  division          = First Division                               │
  │  rank_in_section   = 5                                            │
  │  rank_in_class     = 12                                           │
  │  total_subjects    = 6                                            │
  │  subjects_passed   = 6                                            │
  │  subjects_failed   = 0                                            │
  │  promotion_status  = PROMOTED                                     │
  │  result_status     = DECLARED                                     │
  └───────────────────────────────────────────────────────────────────┘

  msh_student_subject_results (6 rows, one per subject):
  ┌────────────┬──────────┬─────────┬────────┬────┬────┬──────┬──────┬───────┬──────┐
  │ Subject    │ Exam Wtd │ Theory  │ Pract  │ HW │Quiz│Quest │ IA   │ Total │Grade │
  ├────────────┼──────────┼─────────┼────────┼────┼────┼──────┼──────┼───────┼──────┤
  │ Maths      │ 66.90    │ NULL    │ NULL   │8.50│4.50│ 3.90 │ 9.00 │ 92.80 │ A1   │
  │ Science    │ 58.40    │ 42.00   │ 16.40  │7.20│3.80│ 3.50 │ 8.00 │ 80.90 │ A2   │
  │ English    │ 55.20    │ NULL    │ NULL   │6.80│4.00│ 3.20 │ 7.50 │ 76.70 │ B1   │
  │ Hindi      │ 52.10    │ NULL    │ NULL   │7.50│3.50│ 3.00 │ 8.50 │ 74.60 │ B1   │
  │ Social Sc  │ 48.30    │ NULL    │ NULL   │8.00│4.20│ 3.60 │ 7.00 │ 71.10 │ B2   │
  │ Computer   │ 45.60    │ 28.00   │ 17.60  │6.50│3.80│ 3.50 │ 8.00 │ 62.40 │ C1   │
  └────────────┴──────────┴─────────┴────────┴────┴────┴──────┴──────┴───────┴──────┘

  msh_student_subject_exam_marks (18 rows, 6 subjects x 3 exam types):
  ┌────────────┬──────────┬──────────┬────────────┐
  │ Subject    │ UT-1     │ UT-2     │ Half-Yearly│
  ├────────────┼──────────┼──────────┼────────────┤
  │ Maths      │ 45/50    │ 48/50    │ 72/80      │
  │ Science    │ 40/50    │ 42/50    │ 62/80      │
  │ ...        │ ...      │ ...      │ ...        │
  └────────────┴──────────┴──────────┴────────────┘

  msh_student_ia_marks (12 rows, 6 subjects x 2 IA components):
  ┌────────────┬────────────────┬──────────────────┐
  │ Subject    │ Notebook (5)   │ Enrichment (5)   │
  ├────────────┼────────────────┼──────────────────┤
  │ Maths      │ 5/5            │ 4/5              │
  │ Science    │ 4/5            │ 4/5              │
  │ ...        │ ...            │ ...              │
  └────────────┴────────────────┴──────────────────┘

  msh_student_coscholastic_results (4 rows):
  ┌─────────────────────┬───────┬──────────┐
  │ Area                │ Grade │ Source   │
  ├─────────────────────┼───────┼──────────┤
  │ Work Education      │ A     │ Teacher  │
  │ Art Education       │ B     │ Teacher  │
  │ Health & PE         │ A     │ Teacher  │
  │ Discipline          │ A     │ Auto (BA)│
  └─────────────────────┴───────┴──────────┘

  msh_student_attendance (1 row):
  ┌──────────────────────┬──────────────┐
  │ Total Working Days   │ Days Present │
  ├──────────────────────┼──────────────┤
  │ 120                  │ 112          │
  └──────────────────────┴──────────────┘
```

---

## 6. PHASE 4 - Template Variable Mapping (MSG Data -> TMP Variables)

### 6.1 Complete Variable Definition for MARKSHEET Type

These variables are defined in `tmp_template_variables` with `template_type_id = MARKSHEET`:

#### 6.1.1 Student Information Variables (Auto-Resolved)

| # | Variable Name | db_name | table_name | field_name | Resolution | Description |
|---|--------------|---------|------------|------------|------------|-------------|
| 1 | `student_name` | tenant_db | std_students | full_name | Auto | Student's full name |
| 2 | `father_name` | tenant_db | std_students | father_name | Auto | Father's name |
| 3 | `mother_name` | tenant_db | std_students | mother_name | Auto | Mother's name |
| 4 | `date_of_birth` | tenant_db | std_students | date_of_birth | Auto | Student DOB |
| 5 | `admission_no` | tenant_db | std_students | admission_no | Auto | Admission number |
| 6 | `roll_number` | tenant_db | std_students | roll_number | Auto | Roll number |
| 7 | `student_photo` | tenant_db | std_students | photo_path | Auto | Student photo URL |

#### 6.1.2 School Information Variables (Auto-Resolved)

| # | Variable Name | db_name | table_name | field_name | Resolution | Description |
|---|--------------|---------|------------|------------|------------|-------------|
| 8 | `school_name` | tenant_db | sch_schools | name | Auto | School name |
| 9 | `school_logo` | tenant_db | sch_schools | logo_path | Auto | School logo URL |
| 10 | `school_address` | tenant_db | sch_schools | address | Auto | School address |
| 11 | `school_affiliation` | tenant_db | sch_schools | affiliation_no | Auto | Board affiliation no. |

#### 6.1.3 Class/Section Variables (Auto-Resolved)

| # | Variable Name | db_name | table_name | field_name | Resolution | Description |
|---|--------------|---------|------------|------------|------------|-------------|
| 12 | `class_name` | tenant_db | sch_classes | name | Auto | Class name (e.g. "9") |
| 13 | `section_name` | tenant_db | sch_sections | name | Auto | Section name (e.g. "A") |

#### 6.1.4 Marksheet Header Variables (Manual - from MSG)

| # | Variable Name | db_name | table_name | field_name | Resolution | Source |
|---|--------------|---------|------------|------------|------------|--------|
| 14 | `marksheet_title` | NULL | NULL | NULL | Manual | msh_marksheet_types.name |
| 15 | `academic_session` | NULL | NULL | NULL | Manual | sch_org_academic_sessions_jnt display |
| 16 | `exam_group_name` | NULL | NULL | NULL | Manual | msh_exam_groups.name |
| 17 | `schedule_date` | NULL | NULL | NULL | Manual | msh_marksheet_schedules.schedule_date |

#### 6.1.5 Subject Marks Variables (Manual - from MSG computation)

| # | Variable Name | db_name | table_name | field_name | Resolution | Source |
|---|--------------|---------|------------|------------|------------|--------|
| 18 | `subject_marks_table` | NULL | NULL | NULL | Manual | Built from msh_student_subject_results + msh_student_subject_exam_marks |
| 19 | `ia_marks_section` | NULL | NULL | NULL | Manual | Built from msh_student_ia_marks |
| 20 | `coscholastic_section` | NULL | NULL | NULL | Manual | Built from msh_student_coscholastic_results |

#### 6.1.6 Aggregate Result Variables (Manual - from MSG computation)

| # | Variable Name | db_name | table_name | field_name | Resolution | Source |
|---|--------------|---------|------------|------------|------------|--------|
| 21 | `grand_total` | NULL | NULL | NULL | Manual | msh_student_results.grand_total |
| 22 | `grand_max` | NULL | NULL | NULL | Manual | msh_student_results.grand_max |
| 23 | `overall_percentage` | NULL | NULL | NULL | Manual | msh_student_results.overall_percentage |
| 24 | `overall_grade` | NULL | NULL | NULL | Manual | msh_student_results.overall_grade |
| 25 | `division` | NULL | NULL | NULL | Manual | msh_student_results.division |
| 26 | `rank_in_section` | NULL | NULL | NULL | Manual | msh_student_results.rank_in_section |
| 27 | `rank_in_class` | NULL | NULL | NULL | Manual | msh_student_results.rank_in_class |
| 28 | `promotion_status` | NULL | NULL | NULL | Manual | msh_student_results.promotion_status |
| 29 | `result_status` | NULL | NULL | NULL | Manual | msh_student_results.result_status |

#### 6.1.7 Attendance Variables (Manual - from MSG)

| # | Variable Name | db_name | table_name | field_name | Resolution | Source |
|---|--------------|---------|------------|------------|------------|--------|
| 30 | `total_working_days` | NULL | NULL | NULL | Manual | msh_student_attendance.total_working_days |
| 31 | `days_present` | NULL | NULL | NULL | Manual | msh_student_attendance.days_present |

#### 6.1.8 Signature / Footer Variables (Manual)

| # | Variable Name | db_name | table_name | field_name | Resolution | Source |
|---|--------------|---------|------------|------------|------------|--------|
| 32 | `class_teacher_name` | NULL | NULL | NULL | Manual | Resolved from teacher assignment |
| 33 | `principal_name` | NULL | NULL | NULL | Manual | School admin config |
| 34 | `print_date` | NULL | NULL | NULL | Manual | Current date at render time |

### 6.2 Seed SQL for MARKSHEET Variables

```sql
-- Get MARKSHEET type_id
SET @marksheet_type = (SELECT id FROM tmp_templates_type WHERE name = 'MARKSHEET' LIMIT 1);

INSERT INTO `tmp_template_variables`
  (`template_type_id`, `name`, `description`, `db_name`, `table_name`, `field_name`, `is_active`)
VALUES
  -- Student Info (Auto-resolved)
  (@marksheet_type, 'student_name',       'Student full name',                'tenant_db', 'std_students',   'full_name',       1),
  (@marksheet_type, 'father_name',        'Father name',                      'tenant_db', 'std_students',   'father_name',     1),
  (@marksheet_type, 'mother_name',        'Mother name',                      'tenant_db', 'std_students',   'mother_name',     1),
  (@marksheet_type, 'date_of_birth',      'Student date of birth',            'tenant_db', 'std_students',   'date_of_birth',   1),
  (@marksheet_type, 'admission_no',       'Admission number',                 'tenant_db', 'std_students',   'admission_no',    1),
  (@marksheet_type, 'roll_number',        'Roll number',                      'tenant_db', 'std_students',   'roll_number',     1),
  (@marksheet_type, 'student_photo',      'Student photo URL',                'tenant_db', 'std_students',   'photo_path',      1),
  -- School Info (Auto-resolved)
  (@marksheet_type, 'school_name',        'School name',                      'tenant_db', 'sch_schools',    'name',            1),
  (@marksheet_type, 'school_logo',        'School logo URL',                  'tenant_db', 'sch_schools',    'logo_path',       1),
  (@marksheet_type, 'school_address',     'School address',                   'tenant_db', 'sch_schools',    'address',         1),
  (@marksheet_type, 'school_affiliation', 'Board affiliation number',         'tenant_db', 'sch_schools',    'affiliation_no',  1),
  -- Class Info (Auto-resolved)
  (@marksheet_type, 'class_name',         'Class name',                       'tenant_db', 'sch_classes',    'name',            1),
  (@marksheet_type, 'section_name',       'Section name',                     'tenant_db', 'sch_sections',   'name',            1),
  -- Marksheet Header (Manual - from MSG)
  (@marksheet_type, 'marksheet_title',    'Marksheet type display name',       NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'academic_session',   'Academic session display',          NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'exam_group_name',    'Exam group name (Term-1, etc.)',    NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'schedule_date',      'Marksheet issue date',              NULL,        NULL,             NULL,              1),
  -- Subject Marks (Manual - built by renderer)
  (@marksheet_type, 'subject_marks_table','HTML table of subject-wise marks',  NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'ia_marks_section',   'HTML for IA marks section',         NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'coscholastic_section','HTML for co-scholastic grades',    NULL,        NULL,             NULL,              1),
  -- Aggregate Results (Manual - from MSG)
  (@marksheet_type, 'grand_total',        'Grand total marks',                 NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'grand_max',          'Grand total max marks',             NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'overall_percentage', 'Overall percentage',                NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'overall_grade',      'Overall grade',                     NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'division',           'Division (First, Second, etc.)',    NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'rank_in_section',    'Rank within section',               NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'rank_in_class',      'Rank within class',                 NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'promotion_status',   'Promotion status',                  NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'result_status',      'DECLARED or WITHHELD',              NULL,        NULL,             NULL,              1),
  -- Attendance (Manual - from MSG)
  (@marksheet_type, 'total_working_days', 'Total working days in period',      NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'days_present',       'Days student was present',          NULL,        NULL,             NULL,              1),
  -- Footer (Manual)
  (@marksheet_type, 'class_teacher_name', 'Class teacher name',                NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'principal_name',     'Principal name',                    NULL,        NULL,             NULL,              1),
  (@marksheet_type, 'print_date',         'Date of printing',                  NULL,        NULL,             NULL,              1);
```

---

## 7. PHASE 5 - Render Pipeline (Service Layer Integration)

### 7.1 Architecture Overview

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │                    MarksheetRenderService                            │
  │                                                                      │
  │  Input:  schedule_id, student_id                                    │
  │  Output: Rendered HTML or PDF                                       │
  │                                                                      │
  │  Dependencies:                                                      │
  │    - MarksheetResultRepository  (reads MSG result tables)           │
  │    - TemplateResolverService    (resolves TMP template)             │
  │    - TemplateRendererService    (replaces variables, generates PDF) │
  └──────────────────────────────────────────────────────────────────────┘
```

### 7.2 Step-by-Step Render Flow

```
  INPUT: schedule_id = 42, student_id = 1001
  ═════════════════════════════════════════════════════════════════

  STEP 1: Load Schedule Context
  ┌───────────────────────────────────────────────────────────────┐
  │  Query: msh_marksheet_schedules WHERE id = 42                 │
  │                                                               │
  │  Validate:                                                    │
  │    - status_id must be PUBLISHED or LOCKED                    │
  │    - (Student/parent can only view published marksheets)      │
  │    - (Teacher can view COMPUTED and above)                    │
  │                                                               │
  │  Extract:                                                     │
  │    - config_template_id → to get MSG config                   │
  │    - academic_session_id → to resolve TMP template            │
  └───────────────────────────────────────┬───────────────────────┘
                                          │
  STEP 2: Get Student's Class             │
  ┌───────────────────────────────────────▼───────────────────────┐
  │  Query: msh_student_results                                   │
  │    WHERE schedule_id = 42 AND student_id = 1001               │
  │                                                               │
  │  Extract:                                                     │
  │    - class_section_id → resolve class_id via                  │
  │      sch_class_section_jnt                                    │
  │                                                               │
  │  Validate:                                                    │
  │    - result_status must be DECLARED (not WITHHELD)            │
  └───────────────────────────────────────┬───────────────────────┘
                                          │
  STEP 3: Resolve Visual Template (TMP)   │
  ┌───────────────────────────────────────▼───────────────────────┐
  │  Use template resolution priority chain:                      │
  │                                                               │
  │  Priority 1: Direct class match                               │
  │    SELECT ta.template_id                                      │
  │    FROM tmp_template_assignments ta                           │
  │    JOIN tmp_template_purposes tp ON tp.id = ta.purpose_id     │
  │    WHERE tp.code = 'MARKSHEET_PRINT'                          │
  │      AND ta.academic_session_id = @session_id                 │
  │      AND ta.class_id = @class_id                              │
  │      AND ta.is_active = 1 AND ta.deleted_at IS NULL           │
  │                                                               │
  │  Priority 2: Class group match (if no direct match)           │
  │    ... JOIN msh_class_group_items_jnt cgi                     │
  │    WHERE cgi.class_id = @class_id                             │
  │      AND ta.class_group_id = cgi.class_group_id               │
  │                                                               │
  │  Priority 3: School-wide fallback                             │
  │    ... WHERE ta.class_id IS NULL                              │
  │      AND ta.class_group_id IS NULL                            │
  │                                                               │
  │  Result: template_id with canvas_json + html_content          │
  └───────────────────────────────────────┬───────────────────────┘
                                          │
  STEP 4: Fetch All MSG Data              │
  ┌───────────────────────────────────────▼───────────────────────┐
  │  Parallel queries to MSG result tables:                       │
  │                                                               │
  │  A) msh_student_results                                       │
  │     → grand_total, overall_%, grade, rank, promotion          │
  │                                                               │
  │  B) msh_student_subject_results                               │
  │     → per-subject: exam_wtd, theory, practical, HW, Quiz,     │
  │       Quest, IA, total, grade, pass/fail                      │
  │                                                               │
  │  C) msh_student_subject_exam_marks                            │
  │     → raw marks per exam-type per subject                     │
  │                                                               │
  │  D) msh_student_ia_marks                                      │
  │     → IA component marks per subject                          │
  │                                                               │
  │  E) msh_student_coscholastic_results                          │
  │     → co-scholastic grades per area                           │
  │                                                               │
  │  F) msh_student_attendance                                    │
  │     → working days, days present                              │
  │                                                               │
  │  G) msh_config_templates (+ child tables)                     │
  │     → exam group name, marksheet type name                    │
  └───────────────────────────────────────┬───────────────────────┘
                                          │
  STEP 5: Build Variable Context Map      │
  ┌───────────────────────────────────────▼───────────────────────┐
  │  Build associative array mapping variable names to values:    │
  │                                                               │
  │  $context = [                                                 │
  │    // Auto-resolved by TMP engine (entity_id = student_id)    │
  │    'student_name'     => (auto from std_students),            │
  │    'class_name'       => (auto from sch_classes),             │
  │    'school_name'      => (auto from sch_schools),             │
  │                                                               │
  │    // Manual - from MSG data                                  │
  │    'marksheet_title'  => 'Term-1 Report Card',                │
  │    'academic_session' => '2025-26',                           │
  │    'grand_total'      => '458.50',                            │
  │    'overall_percentage'=> '76.42',                            │
  │    'overall_grade'    => 'B1',                                │
  │    'rank_in_section'  => '5',                                 │
  │    'promotion_status' => 'PROMOTED',                          │
  │    'total_working_days'=> '120',                              │
  │    'days_present'     => '112',                               │
  │                                                               │
  │    // Complex HTML blocks (built by renderer)                 │
  │    'subject_marks_table' => '<table>...</table>',             │
  │    'ia_marks_section'    => '<table>...</table>',             │
  │    'coscholastic_section'=> '<table>...</table>',             │
  │    'print_date'          => '2026-04-18',                     │
  │  ];                                                           │
  └───────────────────────────────────────┬───────────────────────┘
                                          │
  STEP 6: Render Template                 │
  ┌───────────────────────────────────────▼───────────────────────┐
  │  Load html_content from tmp_templates                         │
  │  Load variable mappings from tmp_templates_variables_jnt      │
  │                                                               │
  │  For each mapped variable:                                    │
  │    1. If auto-resolvable (table_name + field_name set):       │
  │       → Query DB to get value                                 │
  │    2. If manual (table_name is NULL):                         │
  │       → Use value from $context array                         │
  │    3. If value is NULL:                                       │
  │       → Use default_value from junction table                 │
  │       → If still NULL, use empty string                       │
  │                                                               │
  │  Replace all {{variable_name}} placeholders in html_content   │
  │                                                               │
  │  Return: fully rendered HTML string                           │
  └───────────────────────────────────────┬───────────────────────┘
                                          │
  STEP 7: Output                          │
  ┌───────────────────────────────────────▼───────────────────────┐
  │  Option A: Return HTML for browser display                    │
  │  Option B: Generate PDF (via DomPDF / wkhtmltopdf)            │
  │  Option C: Batch PDF for class (loop through students)        │
  └───────────────────────────────────────────────────────────────┘
```

### 7.3 Laravel Service Implementation

```php
<?php

namespace Modules\Template\Services;

use Modules\Template\Models\Template;
use Modules\Template\Models\TemplateAssignment;
use Modules\MarksheetGeneration\Models\MarksheetSchedule;
use Modules\MarksheetGeneration\Models\StudentResult;
use Modules\MarksheetGeneration\Models\StudentSubjectResult;
use Modules\MarksheetGeneration\Models\StudentSubjectExamMark;
use Modules\MarksheetGeneration\Models\StudentIaMark;
use Modules\MarksheetGeneration\Models\StudentCoscholasticResult;
use Modules\MarksheetGeneration\Models\StudentAttendance;

class MarksheetRenderService
{
    public function __construct(
        private TemplateResolverService $templateResolver,
        private TemplateRendererService $templateRenderer,
        private MarksheetDataService $dataService,
    ) {}

    /**
     * Render marksheet for a single student.
     *
     * @param int $scheduleId  msh_marksheet_schedules.id
     * @param int $studentId   std_students.id
     * @return string          Rendered HTML
     */
    public function renderForStudent(int $scheduleId, int $studentId): string
    {
        // Step 1: Load schedule and validate status
        $schedule = MarksheetSchedule::with([
            'configTemplate.marksheetType',
            'configTemplate.examGroup',
        ])->findOrFail($scheduleId);

        $this->validateScheduleAccess($schedule);

        // Step 2: Get student result and class info
        $studentResult = StudentResult::where('schedule_id', $scheduleId)
            ->where('student_id', $studentId)
            ->firstOrFail();

        $this->validateResultDeclared($studentResult);

        $classId = $this->resolveClassId($studentResult->class_section_id);

        // Step 3: Resolve visual template
        $template = $this->templateResolver->resolve(
            purposeCode: 'MARKSHEET_PRINT',
            sessionId: $schedule->academic_session_id,
            classId: $classId,
        );

        // Step 4: Fetch all MSG data
        $msgData = $this->dataService->fetchStudentMarksheetData(
            $scheduleId, $studentId
        );

        // Step 5: Build context map
        $context = $this->buildContext($schedule, $studentResult, $msgData);

        // Step 6: Render
        return $this->templateRenderer->render($template, $context);
    }

    /**
     * Build the variable context from MSG data.
     */
    private function buildContext(
        MarksheetSchedule $schedule,
        StudentResult $result,
        array $msgData,
    ): array {
        return [
            // Entity IDs for auto-resolution
            'entity_id'        => $result->student_id,
            'class_id'         => $this->resolveClassId($result->class_section_id),
            'school_id'        => tenant('school_id'),

            // Header (from MSG config)
            'marksheet_title'  => $schedule->configTemplate->marksheetType->name,
            'academic_session' => $schedule->academicSession->display_name,
            'exam_group_name'  => $schedule->configTemplate->examGroup->name,
            'schedule_date'    => $schedule->schedule_date?->format('d-m-Y') ?? '',

            // Aggregate results
            'grand_total'        => $result->grand_total,
            'grand_max'          => $result->grand_max,
            'overall_percentage' => $result->overall_percentage,
            'overall_grade'      => $result->overall_grade,
            'division'           => $result->division,
            'rank_in_section'    => $result->rank_in_section,
            'rank_in_class'      => $result->rank_in_class,
            'promotion_status'   => $result->promotion_status,
            'result_status'      => $result->result_status,

            // Complex HTML blocks
            'subject_marks_table'  => $this->buildSubjectMarksHtml($msgData),
            'ia_marks_section'     => $this->buildIaMarksHtml($msgData),
            'coscholastic_section' => $this->buildCoscholasticHtml($msgData),

            // Attendance
            'total_working_days' => $msgData['attendance']->total_working_days ?? '',
            'days_present'       => $msgData['attendance']->days_present ?? '',

            // Footer
            'class_teacher_name' => $this->resolveClassTeacher($result->class_section_id),
            'principal_name'     => $this->resolvePrincipal(),
            'print_date'         => now()->format('d-m-Y'),
        ];
    }
}
```

### 7.4 Template Resolver Service

```php
<?php

namespace Modules\Template\Services;

use Modules\Template\Models\Template;
use Modules\Template\Models\TemplateAssignment;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class TemplateResolverService
{
    /**
     * Resolve the best-matching template using the 3-step
     * priority chain: Class -> Class Group -> School-Wide.
     */
    public function resolve(string $purposeCode, int $sessionId, int $classId): Template
    {
        $templateId = TemplateAssignment::query()
            ->select('tmp_template_assignments.template_id')
            ->join('tmp_template_purposes', 'tmp_template_purposes.id', '=', 'tmp_template_assignments.purpose_id')
            ->leftJoin('msh_class_group_items_jnt', function ($join) use ($classId) {
                $join->on('msh_class_group_items_jnt.class_group_id', '=', 'tmp_template_assignments.class_group_id')
                     ->where('msh_class_group_items_jnt.class_id', $classId)
                     ->where('msh_class_group_items_jnt.is_active', 1)
                     ->whereNull('msh_class_group_items_jnt.deleted_at');
            })
            ->where('tmp_template_purposes.code', $purposeCode)
            ->where('tmp_template_assignments.academic_session_id', $sessionId)
            ->where('tmp_template_assignments.is_active', 1)
            ->whereNull('tmp_template_assignments.deleted_at')
            ->where(function ($q) use ($classId) {
                $q->where('tmp_template_assignments.class_id', $classId)
                  ->orWhere(function ($q2) {
                      $q2->whereNull('tmp_template_assignments.class_id')
                         ->whereNotNull('msh_class_group_items_jnt.id');
                  })
                  ->orWhere(function ($q3) {
                      $q3->whereNull('tmp_template_assignments.class_id')
                         ->whereNull('tmp_template_assignments.class_group_id');
                  });
            })
            ->orderByRaw("
                CASE
                    WHEN tmp_template_assignments.class_id = ? THEN 1
                    WHEN tmp_template_assignments.class_id IS NULL
                         AND msh_class_group_items_jnt.id IS NOT NULL THEN 2
                    ELSE 3
                END
            ", [$classId])
            ->limit(1)
            ->value('template_id');

        if (! $templateId) {
            throw new ModelNotFoundException(
                "No MARKSHEET_PRINT template configured for class_id={$classId} "
                . "in session_id={$sessionId}"
            );
        }

        return Template::with(['variables' => function ($q) {
            $q->orderBy('tmp_templates_variables_jnt.display_order');
        }])->findOrFail($templateId);
    }
}
```

### 7.5 Marksheet Data Service

```php
<?php

namespace Modules\Template\Services;

use Modules\MarksheetGeneration\Models\StudentResult;
use Modules\MarksheetGeneration\Models\StudentSubjectResult;
use Modules\MarksheetGeneration\Models\StudentSubjectExamMark;
use Modules\MarksheetGeneration\Models\StudentIaMark;
use Modules\MarksheetGeneration\Models\StudentCoscholasticResult;
use Modules\MarksheetGeneration\Models\StudentAttendance;

class MarksheetDataService
{
    /**
     * Fetch all MSG result data needed for marksheet rendering.
     */
    public function fetchStudentMarksheetData(int $scheduleId, int $studentId): array
    {
        return [
            'result' => StudentResult::where('schedule_id', $scheduleId)
                ->where('student_id', $studentId)
                ->firstOrFail(),

            'subject_results' => StudentSubjectResult::where('schedule_id', $scheduleId)
                ->where('student_id', $studentId)
                ->join('sch_subjects', 'sch_subjects.id', '=', 'msh_student_subject_results.subject_id')
                ->orderBy('sch_subjects.display_order')
                ->get(),

            'exam_marks' => StudentSubjectExamMark::where('schedule_id', $scheduleId)
                ->where('student_id', $studentId)
                ->join('lms_exam_types', 'lms_exam_types.id', '=', 'msh_student_subject_exam_marks.exam_type_id')
                ->orderBy('lms_exam_types.display_order')
                ->get()
                ->groupBy('subject_id'),

            'ia_marks' => StudentIaMark::where('schedule_id', $scheduleId)
                ->where('student_id', $studentId)
                ->get()
                ->groupBy('subject_id'),

            'coscholastic' => StudentCoscholasticResult::where('schedule_id', $scheduleId)
                ->where('student_id', $studentId)
                ->join('msh_template_coscholastic_components', 'msh_template_coscholastic_components.id', '=',
                    'msh_student_coscholastic_results.coscholastic_component_id')
                ->orderBy('msh_template_coscholastic_components.display_order')
                ->get(),

            'attendance' => StudentAttendance::where('schedule_id', $scheduleId)
                ->where('student_id', $studentId)
                ->first(),
        ];
    }
}
```

---

## 8. PHASE 6 - Display & Access Control

### 8.1 Who Can View What

| Role | Can View When | Scope | Actions |
|------|--------------|-------|---------|
| **Student** | Schedule status = PUBLISHED or LOCKED | Own marksheet only | View, Download PDF |
| **Parent** | Schedule status = PUBLISHED or LOCKED | Own child's marksheet only | View, Download PDF |
| **Class Teacher** | Schedule status >= COMPUTED | Own class-section students | View, Download individual/batch PDF |
| **Subject Teacher** | Schedule status >= COMPUTED | Own subject results only | View subject-wise results |
| **Admin** | Any status | All students in schedule | View, Download, Batch Print, Manage lifecycle |
| **Principal** | Schedule status >= REVIEWED | All students | View, Approve, Download |

### 8.2 Schedule Status vs Access Matrix

```
  ┌───────────┬──────────┬───────────┬──────────┬───────────┬──────────┐
  │ Status    │ Student  │ Parent    │ Teacher  │ Admin     │Principal │
  ├───────────┼──────────┼───────────┼──────────┼───────────┼──────────┤
  │ DRAFT     │    -     │     -     │    -     │ Config    │    -     │
  │ COMPUTED  │    -     │     -     │  View    │ View+Edit │    -     │
  │ REVIEWED  │    -     │     -     │  View    │ View      │ Approve  │
  │ PUBLISHED │  View    │   View    │  View    │ View      │  View    │
  │ LOCKED    │  View    │   View    │  View    │ View      │  View    │
  └───────────┴──────────┴───────────┴──────────┴───────────┴──────────┘
```

### 8.3 API Endpoints

```
  ┌─────────────────────────────────────────────────────────────────────────┐
  │  STUDENT / PARENT ENDPOINTS                                             │
  ├─────────────────────────────────────────────────────────────────────────┤
  │                                                                        │
  │  GET /api/marksheet/my-results                                         │
  │    → List available published marksheets for logged-in student         │
  │    → Returns: schedule_id, marksheet_title, exam_group,                │
  │               schedule_date, overall_grade, promotion_status           │
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/view                                 │
  │    → Rendered marksheet HTML for logged-in student                     │
  │    → Uses: MarksheetRenderService::renderForStudent()                  │
  │    → Auth: student can only view own result                            │
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/pdf                                  │
  │    → Download marksheet as PDF for logged-in student                   │
  │    → Uses: Same render pipeline + DomPDF/wkhtmltopdf                   │
  │                                                                        │
  ├────────────────────────────────────────────────────────────────────────┤
  │  TEACHER ENDPOINTS                                                     │
  ├────────────────────────────────────────────────────────────────────────┤
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/class/{class_section_id}             │
  │    → Summary of all student results in a class-section                 │
  │    → Auth: class teacher can view own class; subject teacher limited   │
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/student/{student_id}/view            │
  │    → Rendered marksheet HTML for specific student                      │
  │    → Auth: teacher must teach this class-section                       │
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/class/{class_section_id}/batch-pdf   │
  │    → Batch download all marksheets for a class-section                 │
  │    → Returns: merged PDF (one page per student)                        │
  │                                                                        │
  ├────────────────────────────────────────────────────────────────────────┤
  │  ADMIN ENDPOINTS                                                       │
  ├────────────────────────────────────────────────────────────────────────┤
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/students                             │
  │    → Paginated list of all students + aggregate results                │
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/student/{student_id}/view            │
  │    → Full rendered marksheet for any student                           │
  │                                                                        │
  │  GET /api/marksheet/{schedule_id}/batch-pdf                            │
  │    → Batch PDF for entire schedule (all class-sections)                │
  │    → Returns: queued job ID (async for large batches)                  │
  │                                                                        │
  │  POST /api/marksheet/{schedule_id}/publish                             │
  │    → Publish schedule (REVIEWED → PUBLISHED)                           │
  │                                                                        │
  │  POST /api/marksheet/{schedule_id}/lock                                │
  │    → Lock schedule (PUBLISHED → LOCKED)                                │
  │                                                                        │
  └────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Subject Marks Table Builder

The `{{subject_marks_table}}` variable requires building a dynamic HTML table from MSG data. This is the most complex part of the rendering.

### 9.1 Table Structure (CBSE Secondary Format)

```
  ┌───────────────────────────────────────────────────────────────────────────────────────┐
  │                          SCHOLASTIC AREAS                                             │
  ├──────────┬────────┬────────┬────────┬──────┬──────┬──────┬────────┬───────┬───────────┤
  │          │ Unit   │ Unit   │ Half   │ Exam │      │      │        │       │           │
  │ Subject  │ Test-1 │ Test-2 │ Yearly │ Wtd  │  HW  │ Quiz │ Quest  │  IA   │ Subject   │
  │          │ (50)   │ (50)   │ (80)   │ Total│      │      │        │ Total │ Total/Grd │
  ├──────────┼────────┼────────┼────────┼──────┼──────┼──────┼────────┼───────┼───────────┤
  │ Maths    │ 45     │ 48     │ 72     │66.90 │ 8.50 │ 4.50 │  3.90  │  9.00 │ 92.80/A1  │
  │ Science  │ 40     │ 42     │ 62     │58.40 │ 7.20 │ 3.80 │  3.50  │  8.00 │ 80.90/A2  │
  │  Theory  │        │        │  42    │      │      │      │        │       │           │
  │  Pract.  │        │        │  20    │      │      │      │        │       │           │
  │ English  │ 38     │ 40     │ 58     │55.20 │ 6.80 │ 4.00 │  3.20  │  7.50 │ 76.70/B1  │
  │ Hindi    │ 35     │ 38     │ 55     │52.10 │ 7.50 │ 3.50 │  3.00  │  8.50 │ 74.60/B1  │
  │ Soc. Sc. │ 32     │ 36     │ 50     │48.30 │ 8.00 │ 4.20 │  3.60  │  7.00 │ 71.10/B2  │
  │ Computer │ 30     │ 34     │ 46     │45.60 │ 6.50 │ 3.80 │  3.50  │  8.00 │ 62.40/C1  │
  │  Theory  │        │        │  28    │      │      │      │        │       │           │
  │  Pract.  │        │        │  18    │      │      │      │        │       │           │
  ├──────────┴────────┴────────┴────────┴──────┴──────┴──────┴────────┴───────┼───────────┤
  │  GRAND TOTAL                                                              │ 458.50    │
  │  PERCENTAGE                                                               │ 76.42%    │
  │  GRADE                                                                    │ B1        │
  │  RESULT                                                                   │ PASS      │
  └───────────────────────────────────────────────────────────────────────────┴───────────┘
```

### 9.2 Builder Service

```php
<?php

namespace Modules\Template\Services;

class SubjectMarksTableBuilder
{
    /**
     * Build the subject marks HTML table from MSG data.
     */
    public function build(array $msgData, array $configContext): string
    {
        $subjectResults = $msgData['subject_results'];
        $examMarks      = $msgData['exam_marks'];       // grouped by subject_id
        $iaMarks        = $msgData['ia_marks'];          // grouped by subject_id
        $examTypes      = $configContext['exam_types'];  // ordered exam types in group
        $hasIa          = $configContext['has_ia'];       // whether template has IA
        $practicalMap   = $configContext['practical_map'];// subject_id -> has_practical

        $html = '<table class="marksheet-table">';
        $html .= $this->buildHeader($examTypes, $hasIa);

        foreach ($subjectResults as $sr) {
            $subjectExamMarks = $examMarks[$sr->subject_id] ?? collect();
            $subjectIaMarks   = $iaMarks[$sr->subject_id] ?? collect();
            $hasPractical     = $practicalMap[$sr->subject_id] ?? false;

            $html .= $this->buildSubjectRow(
                $sr, $subjectExamMarks, $subjectIaMarks,
                $examTypes, $hasIa, $hasPractical
            );
        }

        $html .= '</table>';
        return $html;
    }

    private function buildHeader(array $examTypes, bool $hasIa): string
    {
        $html = '<thead><tr>';
        $html .= '<th>Subject</th>';

        foreach ($examTypes as $et) {
            $html .= '<th>' . e($et->name) . '</th>';
        }

        $html .= '<th>Exam Wtd</th>';
        $html .= '<th>HW</th><th>Quiz</th><th>Quest</th>';

        if ($hasIa) {
            $html .= '<th>IA Total</th>';
        }

        $html .= '<th>Total</th><th>Grade</th>';
        $html .= '</tr></thead>';

        return $html;
    }

    private function buildSubjectRow(
        $sr, $examMarks, $iaMarks, $examTypes, $hasIa, $hasPractical
    ): string {
        $html = '<tr>';
        $html .= '<td>' . e($sr->subject_name) . '</td>';

        // Exam marks per type
        foreach ($examTypes as $et) {
            $mark = $examMarks->firstWhere('exam_type_id', $et->id);
            $html .= '<td>' . ($mark ? $mark->marks_obtained ?? 'AB' : '-') . '</td>';
        }

        $html .= '<td>' . $sr->exam_weighted_total . '</td>';
        $html .= '<td>' . $sr->homework_score . '</td>';
        $html .= '<td>' . $sr->quiz_score . '</td>';
        $html .= '<td>' . $sr->quest_score . '</td>';

        if ($hasIa) {
            $html .= '<td>' . $sr->ia_total . '</td>';
        }

        $html .= '<td>' . $sr->subject_total . '</td>';
        $html .= '<td>' . $sr->subject_grade . '</td>';
        $html .= '</tr>';

        // Theory/Practical sub-rows if applicable
        if ($hasPractical) {
            $html .= '<tr class="sub-row">';
            $html .= '<td class="indent">Theory</td>';
            $html .= '<td colspan="' . count($examTypes) . '"></td>';
            $html .= '<td>' . $sr->theory_marks . '</td>';
            $html .= '<td colspan="' . ($hasIa ? 5 : 4) . '"></td>';
            $html .= '</tr>';
            $html .= '<tr class="sub-row">';
            $html .= '<td class="indent">Practical</td>';
            $html .= '<td colspan="' . count($examTypes) . '"></td>';
            $html .= '<td>' . $sr->practical_marks . '</td>';
            $html .= '<td colspan="' . ($hasIa ? 5 : 4) . '"></td>';
            $html .= '</tr>';
        }

        return $html;
    }
}
```

---

## 10. Batch PDF Generation

### 10.1 Batch Processing Flow

```
  Admin selects: "Download All Marksheets for Term-1 Secondary"
           │
           ▼
  ┌──────────────────────────────────────────────────────────────────────┐
  │  BatchMarksheetPdfJob (Queued)                                       │
  │                                                                      │
  │  Input: schedule_id, class_section_ids (optional filter)             │
  │                                                                      │
  │  1. Get all students in schedule                                     │
  │     → msh_student_results WHERE schedule_id = X                      │
  │       AND result_status = 'DECLARED'                                 │
  │     → ORDER BY class_section_id, rank_in_section                     │
  │                                                                      │
  │  2. For each student:                                                │
  │     → MarksheetRenderService::renderForStudent()                     │
  │     → Collect rendered HTML pages                                    │
  │                                                                      │
  │  3. Merge all HTML pages into single PDF                             │
  │     → Page break between students                                    │
  │     → css: @media print { .student-page { page-break-after: always }}│
  │                                                                      │
  │  4. Store PDF in tmp storage                                         │
  │     → Notify admin via push notification                             │
  │     → Provide download link (time-limited)                           │
  │                                                                      │
  │  Volume: ~500 students × ~2 seconds/render = ~17 minutes             │
  │  Strategy: chunk processing (50 students per chunk)                  │
  └──────────────────────────────────────────────────────────────────────┘
```

### 10.2 Performance Optimization

| Strategy | Implementation | Impact |
|----------|---------------|--------|
| **Eager Loading** | Load all MSG data in bulk before render loop | Avoids N+1 queries per student |
| **Chunked Processing** | Process 50 students at a time | Prevents memory overflow |
| **Cached Template** | Load template + variables once, reuse for all students | Avoids repeated template resolution |
| **Pre-built Config Context** | Compute exam types, practical map once | Same config for all students in schedule |
| **Queue Worker** | Use dedicated queue for batch PDF | Non-blocking for admin UI |
| **Progress Tracking** | Update job progress in cache/DB | Admin sees % complete |

---

## 11. Cross-Module Data Flow Diagram

```
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │                        CROSS-MODULE DATA FLOW                                │
  │                                                                              │
  │                                                                              │
  │   LMS Module                MSG Module                  TMP Module           │
  │   (Source Data)             (Data Engine)               (Presentation)       │
  │                                                                              │
  │   lms_exam_results ────────► msh_student_subject_       tmp_templates_type   │
  │   lms_exam_types ──────────►   exam_marks               tmp_template_        │
  │   lms_exam_papers              │                          purposes           │
  │                                │ compute                 tmp_templates       │
  │   LMS Homework ────────────►   │                         tmp_template_       │
  │   LMS Quiz ────────────────►   │                          variables          │
  │   LMS Quest ───────────────►   ▼                         tmp_templates_      │
  │                            msh_student_subject_           variables_jnt      │
  │                              results                     tmp_template_       │
  │                                │                          assignments        │
  │                                │ aggregate                    │              │
  │                                ▼                              │              │
  │                            msh_student_results                │              │
  │                                │                              │              │
  │                                │                              │              │
  │   Behavioural ─────────────► msh_student_                     │              │
  │   Assessment                   coscholastic_results           │              │
  │                                                               │              │
  │   Attendance Module ───────► msh_student_attendance           │              │
  │   (Phase 2)                                                   │              │
  │                                                               │              │
  │                                                               │              │
  │               ┌────────────────────────────────────────────────┘             │
  │               │                                                              │
  │               ▼                                                              │
  │   ┌───────────────────────────────────────────────────────────────────────┐  │
  │   │                   RENDER SERVICE LAYER                                │  │
  │   │                                                                       │  │
  │   │   1. Resolve Template  ← tmp_template_assignments                     │  │
  │   │   2. Fetch MSG Data    ← msh_student_results + subject_results +      │  │
  │   │                          exam_marks + ia_marks + coscholastic +       │  │
  │   │                          attendance                                   │  │
  │   │   3. Auto-Resolve Vars ← std_students, sch_classes, sch_schools       │  │
  │   │   4. Manual Vars       ← MSG computed data                            │  │
  │   │   5. Replace {{vars}}  ← tmp_templates.html_content                   │  │
  │   │   6. Generate Output   → HTML / PDF                                   │  │
  │   └───────────────────────────────────────────────────────────────────────┘  │
  │                                                                              │
  │   External Read-Only:                                                        │
  │     sch_classes, sch_sections, sch_class_section_jnt, sch_subjects,          │
  │     sch_org_academic_sessions_jnt, std_students, sys_users,                  │
  │     sys_dropdown_table, slb_grade_division_master, msh_class_groups          │
  └──────────────────────────────────────────────────────────────────────────────┘
```

---

## 12. Implementation Checklist

### 12.1 Phase 1: MSG Configuration (Prerequisites - Already Done)

- [x] MSG DDL deployed (23 msh_* tables)
- [x] MSG seeders run (source_components, ia_component_types, status values)
- [x] MSG design guide created (db_design_guide.md)

### 12.2 Phase 2: TMP Configuration (Prerequisites - Already Done)

- [x] TMP DDL deployed (6 tmp_* tables)
- [x] TMP seeders run (template_types, purposes, scope_types)
- [x] TMP implementation guide created

### 12.3 Phase 3: Integration Implementation (To Build)

| # | Task | Module | Files to Create/Modify |
|---|------|--------|----------------------|
| 1 | Seed MARKSHEET variables | TMP | `MarksheetVariableSeeder.php` (uses SQL from Section 6.2) |
| 2 | Create marksheet template design | TMP | Admin UI for template designer (canvas_json + html_content) |
| 3 | Assign template to classes | TMP | Admin UI for tmp_template_assignments |
| 4 | Build MarksheetDataService | MSG | `Modules/MarksheetGeneration/Services/MarksheetDataService.php` |
| 5 | Build TemplateResolverService | TMP | `Modules/Template/Services/TemplateResolverService.php` |
| 6 | Build TemplateRendererService | TMP | `Modules/Template/Services/TemplateRendererService.php` |
| 7 | Build SubjectMarksTableBuilder | TMP | `Modules/Template/Services/SubjectMarksTableBuilder.php` |
| 8 | Build MarksheetRenderService | TMP | `Modules/Template/Services/MarksheetRenderService.php` |
| 9 | Create Student API endpoints | TMP | `MarksheetViewController.php` (routes + controller) |
| 10 | Create Teacher API endpoints | TMP | `MarksheetViewController.php` (class view + batch) |
| 11 | Create Admin API endpoints | MSG | `MarksheetAdminController.php` (lifecycle management) |
| 12 | Build BatchMarksheetPdfJob | TMP | `Modules/Template/Jobs/BatchMarksheetPdfJob.php` |
| 13 | Access control middleware | Both | Role-based access per Section 8.1 |
| 14 | Student portal marksheet page | Frontend | Blade/Vue component for marksheet view |
| 15 | Teacher marksheet dashboard | Frontend | Class-wise result summary + individual view |

### 12.4 Service Registration

```php
// Modules/Template/Providers/TemplateServiceProvider.php

public function register(): void
{
    $this->app->singleton(TemplateResolverService::class);
    $this->app->singleton(TemplateRendererService::class);
    $this->app->singleton(SubjectMarksTableBuilder::class);
    $this->app->singleton(MarksheetRenderService::class, function ($app) {
        return new MarksheetRenderService(
            $app->make(TemplateResolverService::class),
            $app->make(TemplateRendererService::class),
            $app->make(MarksheetDataService::class),
        );
    });
}
```

---

## 13. Key Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D-INT-001 | MSG and TMP are NOT FK-coupled | Independence: either module can be updated without affecting the other. Template design changes don't require MSG schema changes. |
| D-INT-002 | Template resolution uses 3-level priority | Flexibility: school-wide default, class-group override, class-specific override. Same pattern as msh_class_config_jnt. |
| D-INT-003 | Complex HTML sections (subject_marks_table) are built by service layer, not stored as variables | Dynamic: table structure depends on exam types, number of subjects, practical flags -- varies per student/template. |
| D-INT-004 | Auto-resolve for static data, manual for computed data | Efficiency: student name doesn't change per marksheet type, but marks are specific to the schedule computation. |
| D-INT-005 | Batch PDF uses queued job | Performance: 500+ students cannot be rendered synchronously. Queue worker processes in background with progress tracking. |
| D-INT-006 | Access control is schedule-status-based | Security: students can only see PUBLISHED/LOCKED marksheets. Teachers can see COMPUTED+. Admin sees all. |
| D-INT-007 | Template variables are type-scoped, not template-scoped | Reuse: all MARKSHEET templates share the same variable pool. Different layouts can use different subsets via the junction table. |

---

## 14. Error Handling & Edge Cases

### 14.1 Common Error Scenarios

| Scenario | Error | Resolution |
|----------|-------|------------|
| No template assigned for class | `ModelNotFoundException` | Show error: "No marksheet template configured for this class. Contact admin." |
| Schedule not yet PUBLISHED | `AccessDeniedException` | Student portal: hide marksheet. Teacher: show with "PREVIEW" watermark. |
| Student result WITHHELD | `ResultWithheldException` | Show message: "Result withheld. Contact school administration." |
| Missing IA marks for student | Render with empty cells | Computation handles NULL gracefully; template shows "-" |
| Template has no html_content | `InvalidTemplateException` | Validation during template activation prevents this |
| Variable not in context | Use `default_value` from junction | Falls back to empty string if no default |

### 14.2 Data Integrity Checks (Pre-Render)

```php
// Validate before rendering
public function validateRenderReadiness(int $scheduleId): array
{
    $errors = [];

    $schedule = MarksheetSchedule::find($scheduleId);

    // Check schedule exists and is computed
    if (! $schedule || $schedule->status < 'COMPUTED') {
        $errors[] = 'Schedule not yet computed';
    }

    // Check template assignment exists
    $classIds = $schedule->classJunctions->pluck('class_section.class_id')->unique();
    foreach ($classIds as $classId) {
        try {
            $this->templateResolver->resolve('MARKSHEET_PRINT', $schedule->academic_session_id, $classId);
        } catch (ModelNotFoundException $e) {
            $errors[] = "No template assigned for class_id={$classId}";
        }
    }

    // Check all students have results
    $studentCount = $schedule->studentResults()->count();
    if ($studentCount === 0) {
        $errors[] = 'No student results found';
    }

    return $errors;
}
```

---

## 15. Summary: Two Modules, One Marksheet

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                                                                     │
  │              THE MARKSHEET EQUATION                                 │
  │                                                                     │
  │     ┌──────────────────────┐   ┌──────────────────────┐             │
  │     │                      │   │                      │             │
  │     │    MSG Module        │   │    TMP Module        │             │
  │     │                      │   │                      │             │
  │     │  "What data does     │   │  "How does the       │             │
  │     │   the marksheet      │ + │   marksheet look     │             │
  │     │   contain?"          │   │   when displayed?"   │             │
  │     │                      │   │                      │             │
  │     │  Configuration       │   │  Template Design     │             │
  │     │  Computation         │   │  Variable Mapping    │             │
  │     │  Results Storage     │   │  Scope Assignment    │             │
  │     │                      │   │                      │             │
  │     └──────────┬───────────┘   └──────────┬───────────┘             │
  │                │                          │                         │
  │                │     Service Layer        │                         │
  │                └───────────┐  ┌───────────┘                         │
  │                            ▼  ▼                                     │
  │                   ┌─────────────────┐                               │
  │                   │                 │                               │
  │                   │  RENDERED       │                               │
  │                   │  MARKSHEET      │                               │
  │                   │                 │                               │
  │                   │  HTML / PDF     │                               │
  │                   │                 │                               │
  │                   └─────────────────┘                               │
  │                                                                     │
  └─────────────────────────────────────────────────────────────────────┘
```

---

> **Next Steps:**
> 1. Seed MARKSHEET variables (Section 6.2 SQL)
> 2. Build template designer UI (canvas editor for marksheet layout)
> 3. Implement MarksheetRenderService + TemplateResolverService
> 4. Create student/teacher API endpoints
> 5. Build student portal marksheet view page
