# Marksheet Generation Module - Database Design Guide

> **Module:** MarksheetGeneration (MSG)  
> **Table Prefix:** `msh_*`  
> **Total Tables:** 23  
> **Database:** tenant_db (one per tenant, no tenant_id columns)  
> **DDL Version:** 1.0 - April 2026  
> **Based on:** MSG_DDL_v1.sql

---

## 1. Table Relationship Diagram

```
│  =====================================================================================
│  EXTERNAL TABLES (Read-Only - MSG never modifies these)
│  =====================================================================================
│
│  sch_classes ─────────────────────────┐
│  sch_sections ────────────────────────┤
│  sch_class_section_jnt ───────────────┤
│  sch_subjects ────────────────────────┤
│  sch_org_academic_sessions_jnt ───────┤──── Referenced via Foreign Keys
│  std_students ────────────────────────┤
│  sys_users ───────────────────────────┤
│  sys_dropdown_table ──────────────────┤
│  slb_grade_division_master ───────────┤
│  lms_exam_types ──────────────────────┤
│  lms_exam_results ────────────────────┘
│
│  =====================================================================================
│  SECTION 1: MASTER TABLES (Foundation - no FK to other msh_* tables)
│  =====================================================================================
│
│  ┌──────────────────────────────┐  ┌──────────────────────────────┐   ┌───────────────────────────────┐
│  │  [T1] msh_marksheet_types    │  │  [T2] msh_source_components  │   │  [T3] msh_ia_component_types  │
│  │                              │  │                              │   │                               │
│  │                              │  │                              │   │  PK: id                       │
│  │  PK: id                      │  │  PK: id                      │   │  UQ: code                     │
│  │  UQ: code                    │  │  UQ: code                    │   │  ~4-6 rows/school             │
│  │  ~5-8 rows/school            │  │  4 rows (seeded/fixed)       │   │  NOTEBOOK, SUB_ENRICHMENT     │
│  │  e.g. UNIT_TEST, TERM1,      │  │  EXAM, HOMEWORK,             │   │  PERIODIC_ASSESS,             │
│  │  ANNUAL                      │  │  QUIZ, QUEST                 │   │  PARTICIPATION                │
│  └──────────┬───────────────────┘  └──────────────┬───────────────┘   └──────────────┬────────────────┘
│             │                                     │                                  │
│             │                                     │                                  │
│  ===========│=====================================│==================================│=================
│  SECTION 2: CONFIGURATION TABLES (Admin setup before generation)                     │
│  ===========│=====================================│==================================│=================
│             │                                     │                                  │
│             │    ┌────────────────────────────────────────────────────────────────────────────────────────┐
│             │    │  [T8] msh_config_templates                                                             │
│             │    │  PK: id    UQ: academic_session_id + code                                              │
│             │    │  ~3-6 rows/session                                                                     │
│             │    │                                                                                        │
│             │    │  FK → sch_org_academic_sessions_jnt.id (academic_session_id)                           │
│             ├───>│  FK → msh_marksheet_types.id          (marksheet_type_id)                              │
│             │    │  FK → msh_exam_groups.id               (exam_group_id)                                 │
│             │    │  FK → slb_grade_division_master.id      (grading_schema_id)                            │
│             │    │                                                                                        │
│             │    │  Fields: code, name, board_code, passing_percentage,                                   │
│             │    │  compartment_max_failures, is_best_of_n_enabled, best_of_n_count,                      │
│             │    │  is_locked                                                                             │
│             │    └───┬───────────────────────────┬───────────────────────┬───────────────────────┬────────┘
│             │        │                           │                       │                       │
│             │        │                           │                       │                       │
│             │   ┌────▼──────────────┐ ┌──────────▼──────────┐ ┌──────────▼───────────┐ ┌─────────▼─────────────┐
│             │   │[T9] msh_template_ │ │[T10] msh_template_  │ │[T11] msh_template_   │ │[T12] msh_template_    │
│             │   │scholastic_        │ │ exam_weightages     │ │ ia_components        │ │coscholastic_          │
│             │   │components         │ │                     │ │                      │ │components             │
│             │   │                   │ │                     │ │                      │ │                       │
│             │   │FK→config_tmpl     │ │FK→config_tmpl       │ │FK→config_tmpl        │ │FK→config_tmpl         │
│             │   │FK→msh_source_     │ │FK→lms_exam_types    │ │FK→msh_ia_component_  │ │                       │
│             │   │components         │ │                     │ │ types                │ │Fields: name, code,    │
│             │   │                   │ │                     │ │                      │ │grading_scale,         │
│             │   │weightage_%        │ │weightage_%          │ │                      │ │is_ba_linked           │
│             │   │must sum=100       │ │must sum=100         │ │max_marks per subject │ │                       │
│             │   │                   │ │                     │ │                      │ │~3-5/template          │
│             │   │ ~3-4/tmpl         │ │~3-6/template        │ │                      │ │                       │
│             │   │                   │ │                     │ │~2-4/template         │ │                       │
│             │   └───────────────────┘ └─────────────────────┘ └────────────┬─────────┘ └──────┬────────────────┘
│             │                                                              │                  │
│             │                                                              │(FK used in       │(FK used in
│             │                                                              │Result Tables)    │ Result Tables)
│             │                                                              │                  │
│  ───────────│──────────────────────────────────────────────────────────────│──────────────────│────────────────
│             │                                                              │                  │
│  ┌────────────────────────────────────────────────┐                        │                  │
│  │  [T4] msh_class_groups                         │                        │                  │
│  │  PK: id    UQ: code                            │                        │                  │
│  │  ~3-5 rows/school                              │                        │                  │
│  │  PRIMARY, MIDDLE,                              │                        │                  │
│  │  SECONDARY                                     │                        │                  │
│  └──────┬─────────────────────────────────┬───────┘                        │                  │
│         │                                 │                                │                  │
│    ┌────▼──────────────────────────┐ ┌────▼──────────────────────────┐     │                  │
│    │[T5] msh_class_group_items_jnt │ │[T13] msh_class_config_jnt     │     │                  │
│    │                               │ │                               │     │                  │
│                                    │ │FK → msh_config_templates.id   │     │                  │
│    │                               │ │FK → sch_classes.id (direct)   │     │                  │
│    │                               │ │FK → msh_class_groups.id (grp) │     │                  │
│    │FK→class_                      │ │                               │     │                  │
│    │ groups                        │ │CHECK: exactly one of class_id │     │                  │
│    │FK→sch_                        │ │   or class_group_id is set    │     │                  │
│    │ classes                       │ │~10-20/session                 │     │                  │
│    │                               │ └───────────────────────────────┘     │                  │
│    │~15-20/                        │                                       │                  │
│    │ school                        │ ┌───────────────────────────────┐     │                  │
│    └───────────────────────────────┘ │[T14] msh_subject_practical_   │     │                  │
│                                      │      configs                  │     │                  │
│  ┌───────────────────────────────────│                               │     │                  │
│  │                                   │FK → sch_org_academic_sessions │     │                  │
│  │                                   │FK → sch_classes.id            │     │                  │
│  │                                   │FK → sch_subjects.id           │     │                  │
│  │                                   │                               │     │                  │
│  │                                   │theory_max + practical_max     │     │                  │
│  │                                   │~5-15/school                   │     │                  │
│  │                                   └───────────────────────────────┘     │                  │
│  │                                                                         │                  │
│  │    ┌──────────────────────────────────────────┐                         │                  │
│  │    │  [T6] msh_exam_groups                    │                         │                  │
│  │    │  PK: id                                  │                         │                  │
│  │    │  UQ: session + code                      │                         │                  │
│  │    │  FK → sch_org_academic_sessions_jnt      │                         │                  │
│  │    │                                          │                         │                  │
│  │    │  ~2-4 rows/session                       │                         │                  │
│  │    │  e.g. TERM1, TERM2,                      │                         │                  │
│  │    │  ANNUAL                                  │                         │                  │
│  │    └──────┬───────────────────────────────────┘                         │                  │
│  │           │                                                             │                  │
│  │    ┌──────▼───────────────────────────────────┐                         │                  │
│  │    │[T7] msh_exam_group_items_jnt             │                         │                  │
│  │    │                                          │                         │                  │
│  │    │FK → msh_exam_groups                      │                         │                  │
│  │    │FK → lms_exam_types                       │                         │                  │
│  │    │~6-12/session                             │                         │                  │
│  │    └──────────────────────────────────────────┘                         │                  │
│  │                                                                         │                  │
│  │                                                                         │                  │
│  │======================================================================== │                  │
│  │  SECTION 3: SCHEDULE TABLES (When & for whom marksheets are generated)  │                  │
│  │======================================================================== │                  │
│  │                                                                         │                  │
│  │  ┌──────────────────────────────────────────────┐                       │                  │
│  │  │  [T15] msh_marksheet_schedules               │                       │                  │
│  │  │  PK: id    UQ: academic_session_id + code    │                       │                  │
│  │  │                                              │                       │                  │
│  │  │  FK → msh_config_templates.id                │                       │                  │
│  │  │  FK → sch_org_academic_sessions_jnt.id       │                       │                  │
│  │  │  FK → sys_dropdown_table.id (status_id)      │                       │                  │
│  │  │                                              │                       │                  │
│  │  │  Lifecycle: DRAFT → COMPUTED → REVIEWED      │                       │                  │
│  │  │             → PUBLISHED → LOCKED             │                       │                  │
│  │  │                                              │                       │                  │
│  │  │  Lock/Unlock tracking with reason            │                       │                  │
│  │  │  ~4-10/session                               │                       │                  │
│  │  └───┬──────────────────────────────────────────┘                       │                  │
│  │      │                                                                  │                  │
│  │ ┌────▼─────────────────────┐                                            │                  │
│  │ │[T16] msh_schedule_       │                                            │                  │
│  │ │      class_jnt           │                                            │                  │
│  │ │FK → msh_marksheet_       │                                            │                  │
│  │ │   schedules              │                                            │                  │
│  │ │FK → sch_class_section_jnt│                                            │                  │
│  │ │~5-20/schedule            │                                            │                  │
│  │ └──────────────────────────┘                                            │                  │
│  │                                                                         │                  │
│  │                                                                         │                  │
│  │==================================================================       │                  │
│  │ SECTION 4: RESULT TABLES (Computed by ComputeMarksheetJob)              │                  │
│  │==================================================================       │                  │
│  │                                                                         │                  │
│  │  ┌────────────────────────────────────────────────────────────────────────────────────────────┐
│  │  │  [T17] msh_student_results  (AGGREGATE — one row per student per schedule)                 │
│  │  │  PK: id    UQ: schedule_id + student_id                                                    │
│  │  │                                                                                            │
│  │  │  FK → msh_marksheet_schedules.id                                                           │
│  │  │  FK → std_students.id                                                                      │
│  │  │  FK → sch_class_section_jnt.id (denormalized)                                              │
│  │  │                                                                                            │
│  │  │  grand_total, grand_max, overall_percentage, overall_grade, division                       │
│  │  │  rank_in_section, rank_in_class                                                            │
│  │  │  total_subjects, subjects_passed, subjects_failed                                          │
│  │  │  promotion_status: PROMOTED / DETAINED / COMPARTMENT / PLACED                              │
│  │  │  result_status: DECLARED / WITHHELD                                                        │
│  │  │  ~500-2000/schedule                                                                        │
│  │  └────────────────────────────────────────────────────────────────────────────────────────────┘
│  │                │
│  │                │ (student_id + schedule_id)
│  │                │
│  │  ┌─────────────▼────────────────────────────────────────────────────────────────────┐
│  │  │  [T18] msh_student_subject_results  (PER-SUBJECT — one row per student-subject)  │
│  │  │  PK: id    UQ: schedule_id + student_id + subject_id                             │
│  │  │                                                                                  │
│  │  │  FK → msh_marksheet_schedules.id                                                 │
│  │  │  FK → std_students.id                                                            │
│  │  │  FK → sch_subjects.id                                                            │
│  │  │                                                                                  │
│  │  │  exam_weighted_total, theory_marks, practical_marks                              │
│  │  │  homework_score, quiz_score, quest_score, ia_total                               │
│  │  │  subject_total, subject_max, subject_percentage, subject_grade, is_passed        │
│  │  │  ~3K-15K/schedule                                                                │
│  │  └──────────────────────────────────────────────────────────────────────────────────┘
│  │                   │
│  │                   │ (Feeds from the 4 detail tables below)
│  │                   │
│  │    ┌──────────────┼──────────────────┬──────────────────┬──────────────────┐
│  │    │              │                  │                  │                  │
│  │    ▼              ▼                  ▼                  ▼                  ▼
│  │  ┌───────────┐ ┌────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────────┐
│  │  │[T19] msh_ │ │[T20] msh_  │ │[T21] msh_      │ │[T22] msh_      │ │[T23] msh_      │
│  │  │student_   │ │student_    │ │student_        │ │student_        │ │computation_    │
│  │  │subject_   │ │ia_marks    │ │coscholastic_   │ │attendance      │ │logs            │
│  │  │exam_marks │ │            │ │results         │ │                │ │                │
│  │  │           │ │FK→schedule │ │                │ │FK→schedule     │ │FK→schedule     │
│  │  │FK→schedule│ │FK→student  │ │FK→schedule     │ │FK→student      │ │                │
│  │  │FK→student │ │FK→subject  │ │FK→student      │ │                │ │action:         │
│  │  │FK→subject │ │FK→msh_tmpl_│ │FK→msh_tmpl_    │ │total_working_  │ │COMPUTE,        │
│  │  │FK→lms_exam│ │  ia_comps  │◄┤  coscholastic_ │ │  days          │ │RECOMPUTE,      │
│  │  │  _types   │ │            │ │  components    │ │days_present    │ │PUBLISH,        │
│  │  │           │ │marks_      │ │                │ │                │ │UNLOCK, LOCK    │
│  │  │marks_     │ │obtained    │ │grade (A/B/C)   │ │Phase 1: manual │ │                │
│  │  │obtained   │ │max_marks   │ │remarks         │ │Phase 2: auto   │ │Immutable       │
│  │  │max_marks  │ │entered_by  │ │is_auto_from_ba │ │                │ │audit trail     │
│  │  │result_    │ │entered_at  │ │entered_by      │ │~500-2K/sched.  │ │                │
│  │  │status     │ │            │ │                │ │                │ │~10-30/session  │
│  │  │exam_      │ │~6K-20K/    │ │~1.5K-3K/       │ └────────────────┘ └────────────────┘
│  │  │result_id  │ │ schedule   │ │ schedule       │
│  │  │(traceabil)│ │            │ │                │
│  │  │           │ │Teacher     │ │Class teacher   │
│  │  │~15K-80K/  │ │manual entry│ │entry or auto   │
│  │  │ schedule  │ │            │ │from BA module  │
│  │  └───────────┘ └────────────┘ └────────────────┘
```

### Simplified Relationship Summary

```
│  msh_marksheet_types ─────────────────┐
│  msh_source_components ───────────────┤
│  msh_ia_component_types ──────────────┤
│                                       ▼
│                              msh_config_templates ─────────┐
│                                       │                    │
│            ┌──────────────────────────┼──────────┐         │
│            ▼                          ▼          ▼         │
│  msh_template_scholastic_  msh_template_     msh_template_ │
│  components                exam_weightages   ia_components │
│                                                  │         │
│  msh_template_coscholastic_components ──┐        │         │
│                                         │        │         │
│  msh_class_config_jnt ◄─── msh_config_templates  │         │
│  msh_class_groups ──► msh_class_group_items_jnt  │         │
│  msh_exam_groups ──► msh_exam_group_items_jnt    │         │
│                                                  │         │
│                                       ┌──────────┘         │
│                                       ▼                    ▼
│                              msh_marksheet_schedules ◄─────┘
│                                       │
│                    ┌──────────────────┼──────────────────────┐
│                    ▼                  ▼                      ▼
│          msh_schedule_     msh_student_results    msh_computation_logs
│          class_jnt                │
│                                   ▼
│                      msh_student_subject_results
│                                   │
│                    ┌──────────────┼────────────────┐
│                    ▼              ▼                ▼
│          msh_student_     msh_student_    msh_student_
│          subject_exam_    ia_marks        coscholastic_results
│          marks
│                                          msh_student_attendance
```

---

## 2. Purpose of Each Table (Why Each Table is Required)

### Section 1: Master Tables (3 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| T1 | **msh_marksheet_types** | Schools issue different kinds of result documents. A "Unit Test" marksheet has different columns than an "Annual Report Card." This table lets each school define their own marksheet categories. Without it, the system would have to hardcode marksheet variations. |
| T2 | **msh_source_components** | A marksheet doesn't just show exam marks. Homework, quizzes, and quests also contribute to the final score. This table lists the 4 assessment sources (EXAM, HOMEWORK, QUIZ, QUEST) so the template can pick which ones to include and what weight each carries. It is **seeded at onboarding** and EXAM is always mandatory. |
| T3 | **msh_ia_component_types** | Internal Assessment (IA) is a CBSE/ICSE requirement. Students get separate marks for Notebook maintenance, Subject Enrichment activities, Periodic Assessment, and class Participation. This table defines those IA categories so teachers know what to evaluate. Schools can add custom IA types. |

### Section 2: Configuration Tables (10 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| T4 | **msh_class_groups** | Different class levels (Primary 1-5, Middle 6-8, Secondary 9-10) have completely different marksheet formats. This table groups classes into levels so one template can be assigned to an entire group instead of class-by-class. Kept separate from `sch_class_groups_jnt` because timetable grouping has different rules. |
| T5 | **msh_class_group_items_jnt** | Junction table that maps which individual classes (`sch_classes`) belong to which marksheet class group. E.g., Class 1, Class 2, Class 3, Class 4, Class 5 all belong to "Primary" group. |
| T6 | **msh_exam_groups** | A term-end marksheet combines results from multiple exams. "Term-1" might include UT-1 + UT-2 + Half-Yearly. This table defines those logical groupings of exams within an academic session. The `start_date`/`end_date` are also used to filter homework/quiz/quest data for that term period. |
| T7 | **msh_exam_group_items_jnt** | Junction table mapping which `lms_exam_types` (UT-1, UT-2, HY, etc.) belong to each exam group, with a `display_order` to control column sequence on the marksheet. |
| T8 | **msh_config_templates** | The central configuration table. A template is a complete marksheet recipe: it ties together the marksheet type, exam group, grading schema, passing criteria, and best-of-N rules. Schools create ~3-6 templates per session (e.g., "CBSE Secondary Term-1", "Primary Annual"). Once a template is linked to a published schedule, it becomes **locked** (immutable). |
| T9 | **msh_template_scholastic_components** | Defines how much each assessment source weighs in the final score for a given template. E.g., Exam=80%, Homework=10%, Quiz=5%, Quest=5%. Business rule: all weightages must sum to exactly 100%. |
| T10 | **msh_template_exam_weightages** | Within the Exam component itself, each exam type has a different weight. E.g., UT-1=10%, UT-2=10%, Half-Yearly=80%. These must also sum to 100%. This two-level weightage system (component-level, then exam-level) gives fine-grained control. |
| T11 | **msh_template_ia_components** | Defines which IA component types apply to a specific template and the max marks for each. E.g., for a CBSE Secondary template: Notebook=5, Subject Enrichment=5. These max marks are per subject. |
| T12 | **msh_template_coscholastic_components** | Defines co-scholastic (non-academic) areas evaluated on the marksheet. E.g., Work Education, Art Education, Health & Physical Education, Discipline. Each area has its own grading scale (3-point A/B/C or 5-point A-E). The `is_ba_linked` flag enables auto-population from the Behavioural Assessment module. |
| T13 | **msh_class_config_jnt** | Assigns a config template to either a specific class (direct) or a class group (inherited). A CHECK constraint ensures exactly one target is set. Direct class assignment **overrides** group-level assignment, giving flexibility for exceptions. |
| T14 | **msh_subject_practical_configs** | Some subjects (Science, Computer Science) have a theory-practical split. This table defines the mark distribution per class-subject combination. E.g., Class 9 Science: Theory=70, Practical=30. Only subjects with practicals need rows here. |

### Section 3: Schedule Tables (2 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| T15 | **msh_marksheet_schedules** | A "schedule" is a marksheet generation event - the trigger point that says "generate report cards for these classes using this template." It tracks the full lifecycle from DRAFT through COMPUTED, REVIEWED, PUBLISHED, to LOCKED. Includes lock/unlock audit fields. This is the operational heartbeat of the module. |
| T16 | **msh_schedule_class_jnt** | Junction that specifies which class-sections are included in a particular schedule. A Term-1 schedule for Secondary might include Class 9-A, 9-B, 10-A, 10-B. |

### Section 4: Result Tables (6 Tables)

| # | Table | Why It Exists |
|---|-------|---------------|
| T17 | **msh_student_results** | The **aggregate result** per student per schedule. Contains the grand total, overall percentage, overall grade, division (First/Second/Third), rank (section-wise and class-wise), promotion status (Promoted/Detained/Compartment/Placed), and result declaration status. This is what appears at the bottom of a report card. |
| T18 | **msh_student_subject_results** | The **per-subject result** per student. Contains the weighted exam total, theory/practical split, homework/quiz/quest scores, IA total, subject total, subject grade, and pass/fail flag. This is the main body of the report card showing each subject row. |
| T19 | **msh_student_subject_exam_marks** | The **raw exam marks matrix** - each cell in the marksheet grid. One row per student x subject x exam-type. E.g., Student "Rahul", Subject "Mathematics", Exam "UT-1" = 45/50. Includes `exam_result_id` for traceability back to `lms_exam_results`. This is the highest-volume table (~15K-80K rows per schedule). |
| T20 | **msh_student_ia_marks** | Internal Assessment marks entered manually by subject teachers. One row per student x subject x IA component. E.g., Student "Rahul", Subject "Science", Component "Notebook" = 4/5. Tracks which teacher entered the marks and when. |
| T21 | **msh_student_coscholastic_results** | Co-scholastic grades entered by the class teacher. E.g., Student "Rahul", Area "Health & PE" = Grade "A". The `is_auto_from_ba` flag marks grades that were auto-populated from the Behavioural Assessment module (for areas like Discipline). |
| T22 | **msh_student_attendance** | Attendance summary printed on the marksheet. Contains total working days and days present. Phase 1 is manual entry by the class teacher. Phase 2 will auto-populate from the Attendance module. |

### Section 5: Audit Table (1 Table)

| # | Table | Why It Exists |
|---|-------|---------------|
| T23 | **msh_computation_logs** | Immutable audit trail of every computation event. Logs COMPUTE, RECOMPUTE, PUBLISH, UNLOCK, and LOCK actions with timestamps, duration, student count, error count, and error details (JSON). Critical for accountability - if marks are disputed, this log shows exactly when computation happened, who triggered it, and whether errors occurred. Has **no `deleted_at`** - records cannot be soft-deleted. |

---

## 3. Field Details per Table

### T1: msh_marksheet_types

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | Machine-readable identifier. Used in code logic. E.g., `UNIT_TEST`, `TERM1`, `ANNUAL` |
| `name` | VARCHAR(100) | Yes | Human-readable display name. Shown on UI and printed marksheet header |
| `description` | VARCHAR(255) | No | Optional elaboration for admin reference |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Controls sort order in dropdown menus |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle. 0 = hidden from dropdowns but data preserved |
| `created_by` | INT UNSIGNED | Yes | FK to `sys_users.id`. Who created this record |
| `updated_by` | INT UNSIGNED | No | FK to `sys_users.id`. Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto-managed |
| `updated_at` | TIMESTAMP | No | Laravel auto-managed |
| `deleted_at` | TIMESTAMP | No | Soft delete (Laravel SoftDeletes trait) |

### T2: msh_source_components

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | `EXAM`, `HOMEWORK`, `QUIZ`, `QUEST` |
| `name` | VARCHAR(100) | Yes | Display name |
| `description` | VARCHAR(255) | No | Describes the source component |
| `is_mandatory` | TINYINT(1) | Yes (default 0) | 1 for EXAM - always required in every template |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Sort order |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T3: msh_ia_component_types

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | `NOTEBOOK`, `SUB_ENRICHMENT`, `PERIODIC_ASSESS`, `PARTICIPATION` |
| `name` | VARCHAR(100) | Yes | Display name shown to teachers during marks entry |
| `description` | VARCHAR(255) | No | Explains what the IA component evaluates |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Column order on marksheet |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T4: msh_class_groups

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `code` | VARCHAR(30) UQ | Yes | `PRIMARY`, `MIDDLE`, `SECONDARY`, `SR_SECONDARY` |
| `name` | VARCHAR(100) | Yes | Display name. E.g., "Primary (1-5)" |
| `description` | VARCHAR(255) | No | Details about the group |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Sort order |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T5: msh_class_group_items_jnt

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `class_group_id` | INT UNSIGNED | Yes | FK to `msh_class_groups.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `class_group_id` + `class_id` (a class can only belong to one group).

### T6: msh_exam_groups

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_session_id` | SMALLINT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id`. Scopes group to a session |
| `code` | VARCHAR(30) | Yes | `TERM1`, `TERM2`, `ANNUAL` |
| `name` | VARCHAR(100) | Yes | Display name. "Term-1", "Annual" |
| `description` | VARCHAR(255) | No | Details |
| `start_date` | DATE | No | Term start date. Used to filter HW/Quiz/Quest records that fall in this period |
| `end_date` | DATE | No | Term end date. Same filtering use |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `academic_session_id` + `code`.

### T7: msh_exam_group_items_jnt

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `exam_group_id` | INT UNSIGNED | Yes | FK to `msh_exam_groups.id` |
| `exam_type_id` | INT UNSIGNED | Yes | FK to `lms_exam_types.id`. E.g., UT-1, UT-2, HY-EXAM |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Column order on the marksheet |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `exam_group_id` + `exam_type_id`.

### T8: msh_config_templates

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_session_id` | SMALLINT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `marksheet_type_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_types.id`. What kind of marksheet |
| `exam_group_id` | INT UNSIGNED | Yes | FK to `msh_exam_groups.id`. Which exams are included |
| `grading_schema_id` | INT UNSIGNED | No | FK to `slb_grade_division_master.id`. Grading lookup (A1, A2, B1...) |
| `code` | VARCHAR(50) | Yes | Unique code within session. E.g., `CBSE_SEC_TERM1_2025` |
| `name` | VARCHAR(150) | Yes | Full descriptive name |
| `description` | VARCHAR(500) | No | Detailed description |
| `board_code` | VARCHAR(50) | No | Informational: CBSE, ICSE, STATE, CUSTOM. Guides UI defaults |
| `passing_percentage` | DECIMAL(5,2) | Yes (default 33.00) | Minimum % to pass a subject |
| `compartment_max_failures` | TINYINT UNSIGNED | Yes (default 2) | Max subjects a student can fail and still get "Compartment" instead of "Detained" |
| `is_best_of_n_enabled` | TINYINT(1) | Yes (default 0) | If 1, only best N unit test scores count |
| `best_of_n_count` | TINYINT UNSIGNED | No | How many best scores to pick. E.g., best 2 out of 4 UTs |
| `is_locked` | TINYINT(1) | Yes (default 0) | 1 = linked to published schedule, cannot be edited |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `academic_session_id` + `code`.

### T9: msh_template_scholastic_components

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `config_template_id` | INT UNSIGNED | Yes | FK to `msh_config_templates.id` |
| `source_component_id` | INT UNSIGNED | Yes | FK to `msh_source_components.id` |
| `weightage_percent` | DECIMAL(5,2) | Yes | Percentage contribution. E.g., Exam=80.00, HW=10.00 |
| `max_marks` | DECIMAL(8,2) | No | Optional cap on marks this component can contribute |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Business Rule:** Sum of `weightage_percent` across all rows for a template MUST = 100.00.

### T10: msh_template_exam_weightages

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `config_template_id` | INT UNSIGNED | Yes | FK to `msh_config_templates.id` |
| `exam_type_id` | INT UNSIGNED | Yes | FK to `lms_exam_types.id` |
| `weightage_percent` | DECIMAL(5,2) | Yes | E.g., UT-1=10.00, UT-2=10.00, HY=80.00 |
| `max_marks` | DECIMAL(8,2) | No | Max marks for this exam type (from exam paper) |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Business Rule:** Sum of `weightage_percent` for a template MUST = 100.00.

### T11: msh_template_ia_components

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `config_template_id` | INT UNSIGNED | Yes | FK to `msh_config_templates.id` |
| `ia_component_type_id` | INT UNSIGNED | Yes | FK to `msh_ia_component_types.id` |
| `max_marks` | DECIMAL(5,2) | Yes | Max marks per subject for this IA component. E.g., Notebook=5.00 |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Column order |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T12: msh_template_coscholastic_components

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `config_template_id` | INT UNSIGNED | Yes | FK to `msh_config_templates.id` |
| `name` | VARCHAR(100) | Yes | Area name. E.g., "Work Education", "Art Education" |
| `code` | VARCHAR(30) | Yes | Machine code. `WORK_ED`, `ART_ED`, `HEALTH_PE`, `DISCIPLINE` |
| `grading_scale` | VARCHAR(50) | Yes (default '3_POINT') | `3_POINT` (A/B/C) or `5_POINT` (A/B/C/D/E) |
| `is_ba_linked` | TINYINT(1) | Yes (default 0) | 1 = auto-populate from BehaviouralAssessment module |
| `display_order` | SMALLINT UNSIGNED | Yes (default 1) | Row order on marksheet |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `config_template_id` + `code`.

### T13: msh_class_config_jnt

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `config_template_id` | INT UNSIGNED | Yes | FK to `msh_config_templates.id` |
| `class_id` | INT UNSIGNED | Conditional | FK to `sch_classes.id`. Direct assignment (priority) |
| `class_group_id` | INT UNSIGNED | Conditional | FK to `msh_class_groups.id`. Group-level fallback |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**CHECK constraint:** Exactly one of `class_id` or `class_group_id` must be non-NULL.

### T14: msh_subject_practical_configs

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `academic_session_id` | SMALLINT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `class_id` | INT UNSIGNED | Yes | FK to `sch_classes.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `has_practical` | TINYINT(1) | Yes (default 1) | Flag confirming practical component exists |
| `theory_max_marks` | DECIMAL(5,2) | Yes | Theory portion. E.g., 70.00 |
| `practical_max_marks` | DECIMAL(5,2) | Yes | Practical portion. E.g., 30.00 |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

**Unique constraint:** `academic_session_id` + `class_id` + `subject_id`.

### T15: msh_marksheet_schedules

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `config_template_id` | INT UNSIGNED | Yes | FK to `msh_config_templates.id` |
| `academic_session_id` | SMALLINT UNSIGNED | Yes | FK to `sch_org_academic_sessions_jnt.id` |
| `code` | VARCHAR(50) | Yes | E.g., `TERM1_SEC_2025` |
| `name` | VARCHAR(150) | Yes | Full name for display |
| `schedule_date` | DATE | No | Target date for issuing marksheets |
| `status_id` | INT UNSIGNED | Yes | FK to `sys_dropdown_table.id`. Lifecycle stage |
| `last_computed_at` | DATETIME | No | Timestamp of last successful computation run |
| `total_students` | INT UNSIGNED | No | Populated after computation |
| `is_locked` | TINYINT(1) | Yes (default 0) | Lock flag |
| `locked_at` | DATETIME | No | When locked |
| `locked_by` | INT UNSIGNED | No | FK to `sys_users.id`. Who locked |
| `unlock_reason` | TEXT | No | Mandatory reason text when admin unlocks a published schedule |
| `unlocked_at` | DATETIME | No | When unlocked |
| `unlocked_by` | INT UNSIGNED | No | FK to `sys_users.id`. Who unlocked |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T16: msh_schedule_class_jnt

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `class_section_id` | INT UNSIGNED | Yes | FK to `sch_class_section_jnt.id` |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T17: msh_student_results

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `student_id` | INT UNSIGNED | Yes | FK to `std_students.id` |
| `class_section_id` | INT UNSIGNED | Yes | FK to `sch_class_section_jnt.id` (denormalized for fast queries) |
| `grand_total` | DECIMAL(8,2) | No | Sum of all subject totals |
| `grand_max` | DECIMAL(8,2) | No | Sum of all subject max marks |
| `overall_percentage` | DECIMAL(5,2) | No | `grand_total / grand_max * 100` |
| `overall_grade` | VARCHAR(10) | No | Looked up from `slb_grade_division_master` |
| `division` | VARCHAR(30) | No | First Division, Second Division, etc. |
| `rank_in_section` | INT UNSIGNED | No | Dense rank within class-section |
| `rank_in_class` | INT UNSIGNED | No | Dense rank across all sections of the class |
| `total_subjects` | TINYINT UNSIGNED | No | Total subjects the student had |
| `subjects_passed` | TINYINT UNSIGNED | No | Count of passed subjects |
| `subjects_failed` | TINYINT UNSIGNED | No | Count of failed subjects |
| `promotion_status` | VARCHAR(30) | No | `PROMOTED`, `DETAINED`, `COMPARTMENT`, `PLACED` |
| `result_status` | VARCHAR(20) | No | `DECLARED` or `WITHHELD` |
| `withheld_reason` | VARCHAR(255) | No | Reason if result is withheld |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T18: msh_student_subject_results

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `student_id` | INT UNSIGNED | Yes | FK to `std_students.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `exam_weighted_total` | DECIMAL(8,2) | No | Weighted sum of all exam marks for this subject |
| `theory_marks` | DECIMAL(8,2) | No | Theory portion after exam weightage. NULL if no practical |
| `practical_marks` | DECIMAL(8,2) | No | Practical portion. NULL if no practical split |
| `homework_score` | DECIMAL(8,2) | No | Homework component score |
| `quiz_score` | DECIMAL(8,2) | No | Quiz component score |
| `quest_score` | DECIMAL(8,2) | No | Quest component score |
| `ia_total` | DECIMAL(8,2) | No | Sum of all IA component marks |
| `subject_total` | DECIMAL(8,2) | No | All components combined |
| `subject_max` | DECIMAL(8,2) | No | Maximum possible marks |
| `subject_percentage` | DECIMAL(5,2) | No | `subject_total / subject_max * 100` |
| `subject_grade` | VARCHAR(10) | No | From `slb_grade_division_master` |
| `is_passed` | TINYINT(1) | No | 1=pass, 0=fail, NULL=not computed |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T19: msh_student_subject_exam_marks

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `student_id` | INT UNSIGNED | Yes | FK to `std_students.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `exam_type_id` | INT UNSIGNED | Yes | FK to `lms_exam_types.id` |
| `marks_obtained` | DECIMAL(8,2) | No | Marks scored. NULL = not attempted or ABSENT |
| `max_marks` | DECIMAL(8,2) | No | Max possible marks |
| `result_status` | VARCHAR(20) | No | `PASS`, `FAIL`, `ABSENT`, `WITHHELD` |
| `exam_result_id` | INT UNSIGNED | No | FK to `lms_exam_results.id`. Traceability back to source |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T20: msh_student_ia_marks

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `student_id` | INT UNSIGNED | Yes | FK to `std_students.id` |
| `subject_id` | INT UNSIGNED | Yes | FK to `sch_subjects.id` |
| `ia_component_id` | INT UNSIGNED | Yes | FK to `msh_template_ia_components.id` |
| `marks_obtained` | DECIMAL(5,2) | No | Teacher-entered marks. NULL = not yet entered |
| `max_marks` | DECIMAL(5,2) | Yes | Copied from `msh_template_ia_components.max_marks` |
| `entered_by` | INT UNSIGNED | No | FK to `sys_users.id`. The teacher who entered |
| `entered_at` | DATETIME | No | When marks were entered |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T21: msh_student_coscholastic_results

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `student_id` | INT UNSIGNED | Yes | FK to `std_students.id` |
| `coscholastic_component_id` | INT UNSIGNED | Yes | FK to `msh_template_coscholastic_components.id` |
| `grade` | VARCHAR(10) | No | Grade value: A, B, C, D, E |
| `remarks` | VARCHAR(255) | No | Optional teacher remarks |
| `entered_by` | INT UNSIGNED | No | FK to `sys_users.id`. NULL if auto-populated from BA |
| `entered_at` | DATETIME | No | When grade was entered |
| `is_auto_from_ba` | TINYINT(1) | Yes (default 0) | 1 if auto-populated from BehaviouralAssessment |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T22: msh_student_attendance

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `student_id` | INT UNSIGNED | Yes | FK to `std_students.id` |
| `total_working_days` | SMALLINT UNSIGNED | No | Total working days in the term/year |
| `days_present` | SMALLINT UNSIGNED | No | Days student attended |
| `entered_by` | INT UNSIGNED | No | FK to `sys_users.id`. NULL if auto from attendance module |
| `is_auto_populated` | TINYINT(1) | Yes (default 0) | 1 if fetched from Attendance module |
| `is_active` | TINYINT(1) | Yes (default 1) | Soft toggle |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `updated_by` | INT UNSIGNED | No | Last modifier |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |
| `deleted_at` | TIMESTAMP | No | Soft delete |

### T23: msh_computation_logs

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `id` | INT UNSIGNED PK | Auto | Primary key |
| `schedule_id` | INT UNSIGNED | Yes | FK to `msh_marksheet_schedules.id` |
| `action` | VARCHAR(30) | Yes | `COMPUTE`, `RECOMPUTE`, `PUBLISH`, `UNLOCK`, `LOCK` |
| `triggered_by` | INT UNSIGNED | Yes | FK to `sys_users.id`. Who initiated the action |
| `started_at` | DATETIME | Yes | When computation started |
| `completed_at` | DATETIME | No | When computation finished. NULL if still running |
| `duration_seconds` | INT UNSIGNED | No | Total time taken |
| `total_students` | INT UNSIGNED | No | Students processed in this run |
| `total_errors` | INT UNSIGNED | No (default 0) | Count of errors encountered |
| `status` | VARCHAR(20) | Yes (default 'IN_PROGRESS') | `IN_PROGRESS`, `SUCCESS`, `FAILED`, `PARTIAL` |
| `error_log` | TEXT | No | JSON array of error messages |
| `remarks` | TEXT | No | Unlock reason, recomputation notes |
| `is_active` | TINYINT(1) | Yes (default 1) | Active flag |
| `created_by` | INT UNSIGNED | Yes | Who created |
| `created_at` | TIMESTAMP | No | Laravel auto |
| `updated_at` | TIMESTAMP | No | Laravel auto |

**Note:** No `deleted_at` column. This is an immutable audit log - records are never soft-deleted.

---

## 4. Data Capturing Flow

The data flow follows a strict sequence. Each phase must be completed before the next can begin.

### Phase 1: One-Time Setup (System Admin / Super Admin)

```
  STEP 1.1 ─ Seed Master Data
  ┌────────────────────────────────────────────────────────────────────┐
  │  Run MarksheetGenerationDatabaseSeeder.php                         │
  │                                                                    │
  │  ► msh_source_components: Insert 4 rows                            │
  │    - EXAM (is_mandatory=1), HOMEWORK, QUIZ, QUEST                  │
  │                                                                    │
  │  ► msh_ia_component_types: Insert 4 rows                           │
  │    - NOTEBOOK, SUB_ENRICHMENT, PERIODIC_ASSESS, PARTICIPATION      │
  │                                                                    │
  │  ► sys_dropdown_table: Insert 5 status values                      │
  │    - Key: 'msh_marksheet_schedules.status_id'                      │
  │    - Values: DRAFT, COMPUTED, REVIEWED, PUBLISHED, LOCKED          │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 1.2 ─ Define Marksheet Types (School Admin)
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_marksheet_types: Insert ~5-8 rows                           │
  │    - UNIT_TEST, TERM1, TERM2, ANNUAL, etc.                         │
  │    - Set code, name, display_order                                 │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 1.3 ─ Define Class Groups (School Admin)
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_class_groups: Insert ~3-5 rows                              │
  │    - PRIMARY, MIDDLE, SECONDARY, SR_SECONDARY                      │
  │                                                                    │
  │  ► msh_class_group_items_jnt: Map classes to groups                │
  │    - Class 1-5 → PRIMARY                                           │
  │    - Class 6-8 → MIDDLE                                            │
  │    - Class 9-10 → SECONDARY                                        │
  │    - Class 11-12 → SR_SECONDARY                                    │
  └────────────────────────────────────────────────────────────────────┘
```

### Phase 2: Session-Level Configuration (School Admin, start of academic year)

```
  STEP 2.1 ─ Create Exam Groups
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_exam_groups: Insert ~2-4 rows for the session               │
  │    - TERM1 (start_date: Apr 1, end_date: Sep 30)                   │
  │    - TERM2 (start_date: Oct 1, end_date: Mar 31)                   │
  │    - ANNUAL (start_date: Apr 1, end_date: Mar 31)                  │
  │                                                                    │
  │  ► msh_exam_group_items_jnt: Map exam types to groups              │
  │    - TERM1 → [UT-1, UT-2, Half-Yearly]                             │
  │    - TERM2 → [UT-3, UT-4, Annual Exam]                             │
  │    - ANNUAL → [All 6 exam types]                                   │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 2.2 ─ Create Config Templates
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_config_templates: Insert ~3-6 rows                          │
  │    - Link: marksheet_type + exam_group + grading_schema            │
  │    - Set: passing_percentage, compartment rules, best-of-N         │
  │    - E.g.: "CBSE Secondary Term-1" uses TERM1 exam group,          │
  │            CBSE grading, 33% pass, max 2 compartment subjects      │
  │                                                                    │
  │  ► msh_template_scholastic_components: Add weightages              │
  │    - Exam=80%, Homework=10%, Quiz=5%, Quest=5%                     │
  │    - MUST sum to 100%                                              │
  │                                                                    │
  │  ► msh_template_exam_weightages: Add per-exam weightages           │
  │    - UT-1=10%, UT-2=10%, Half-Yearly=80%                           │
  │    - MUST sum to 100%                                              │
  │                                                                    │
  │  ► msh_template_ia_components: Define IA marks structure           │
  │    - Notebook=5, Subject Enrichment=5                              │
  │                                                                    │
  │  ► msh_template_coscholastic_components: Define co-scholastic      │
  │    - Work Education (3-point), Art Education (3-point),            │
  │      Health & PE (3-point), Discipline (3-point, BA-linked)        │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 2.3 ─ Assign Templates to Classes
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_class_config_jnt: Link templates to targets                 │
  │    - "CBSE Secondary Term-1" → class_group_id = SECONDARY          │
  │    - OR override: "CBSE Secondary Term-1" → class_id = Class 10    │
  │    (Direct class assignment overrides group-level)                 │
  │                                                                    │
  │  ► msh_subject_practical_configs: Set theory/practical split       │
  │    - Class 9 Science: Theory=70, Practical=30                      │
  │    - Class 10 Computer: Theory=60, Practical=40                    │
  │    (Only for subjects with practicals)                             │
  └────────────────────────────────────────────────────────────────────┘
```

### Phase 3: Pre-Computation Data Entry (Teachers, before marksheet generation)

```
  STEP 3.1 ─ Exam Results (Prerequisite - done in LMS Exam Module)
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► lms_exam_results must be populated for all exam types           │
  │    in the exam group before computation can run.                   │
  │    (This happens in the LMS Exam module, not in MSG)               │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 3.2 ─ Teacher Enters IA Marks
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► Subject teachers enter IA marks via UI (SC-MSG-12a screen)      │
  │  ► msh_student_ia_marks: One row per student × subject × IA comp   │
  │    - E.g.: Rahul, Maths, Notebook = 4/5                            │
  │    - Tracks entered_by (teacher) and entered_at                    │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 3.3 ─ Class Teacher Enters Co-Scholastic Grades
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_student_coscholastic_results:                               │
  │    - Class teacher assigns grades for each co-scholastic area      │
  │    - Discipline may auto-populate from BA module (is_auto_from_ba) │
  │    - E.g.: Rahul, Health & PE = Grade A                            │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 3.4 ─ Enter Attendance Summary
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_student_attendance:                                         │
  │    - Phase 1: Class teacher manually enters working days + present │
  │    - Phase 2: Auto-fetched from Attendance module                  │
  └────────────────────────────────────────────────────────────────────┘
```

### Phase 4: Schedule & Compute (Admin triggers)

```
  STEP 4.1 ─ Create Marksheet Schedule
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► msh_marksheet_schedules: Create schedule in DRAFT status        │
  │    - Link to config_template, set academic_session                 │
  │    - Schedule date (when to issue)                                 │
  │                                                                    │
  │  ► msh_schedule_class_jnt: Select class-sections for this batch    │
  │    - E.g.: Class 9-A, 9-B, 10-A, 10-B                              │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 4.2 ─ Run Computation (ComputeMarksheetJob)
  ┌────────────────────────────────────────────────────────────────────┐
  │  Admin clicks "Compute" → Dispatches ComputeMarksheetJob           │
  │                                                                    │
  │  ► msh_computation_logs: Create IN_PROGRESS log entry              │
  │                                                                    │
  │  For each student in the schedule's class-sections:                │
  │                                                                    │
  │    1. PULL exam marks from lms_exam_results                        │
  │       → WRITE to msh_student_subject_exam_marks (T19)              │
  │       (copies marks + stores exam_result_id for traceability)      │
  │                                                                    │
  │    2. APPLY exam weightages (from T10)                             │
  │       → If best-of-N enabled, select top N unit test scores        │
  │       → Compute exam_weighted_total per subject                    │
  │                                                                    │
  │    3. APPLY theory/practical split (from T14)                      │
  │       → Split exam_weighted_total into theory + practical          │
  │                                                                    │
  │    4. FETCH homework/quiz/quest scores from LMS modules            │
  │       (filtered by exam group date range)                          │
  │                                                                    │
  │    5. READ IA marks (from T20 - already entered by teachers)       │
  │       → Sum into ia_total                                          │
  │                                                                    │
  │    6. APPLY component weightages (from T9)                         │
  │       → Combine: exam(80%) + homework(10%) + quiz(5%) + quest(5%)  │
  │       → WRITE to msh_student_subject_results (T18)                 │
  │       → Look up grade from slb_grade_division_master               │
  │       → Determine pass/fail using passing_percentage               │
  │                                                                    │
  │    7. AGGREGATE across all subjects                                │
  │       → grand_total, grand_max, overall_percentage, overall_grade  │
  │       → Count subjects_passed / subjects_failed                    │
  │       → Determine promotion_status based on compartment rules      │
  │       → WRITE to msh_student_results (T17)                         │
  │                                                                    │
  │  After all students processed:                                     │
  │    8. COMPUTE ranks (dense ranking by percentage)                  │
  │       → rank_in_section, rank_in_class                             │
  │       → UPDATE msh_student_results                                 │
  │                                                                    │
  │  ► msh_computation_logs: Update to SUCCESS/FAILED/PARTIAL          │
  │  ► msh_marksheet_schedules: Update status → COMPUTED               │
  │    Set last_computed_at, total_students                            │
  └────────────────────────────────────────────────────────────────────┘
```

### Phase 5: Review & Publish (Admin / Principal)

```
  STEP 5.1 ─ Review
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► Admin/Principal reviews computed results on screen              │
  │  ► Can withhold individual student results                         │
  │    → msh_student_results.result_status = 'WITHHELD'                │
  │    → msh_student_results.withheld_reason = '...'                   │
  │  ► If corrections needed → RECOMPUTE (back to Step 4.2)            │
  │  ► msh_marksheet_schedules: Update status → REVIEWED               │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 5.2 ─ Publish
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► Admin publishes the schedule                                    │
  │  ► msh_marksheet_schedules: status → PUBLISHED                     │
  │  ► msh_config_templates: is_locked → 1 (template becomes frozen)   │
  │  ► msh_computation_logs: PUBLISH action logged                     │
  │  ► Marksheets now visible to students/parents (via portal)         │
  │  ► PDF generation available                                        │
  └────────────────────────────────────────────────────────────────────┘
          │
          ▼
  STEP 5.3 ─ Lock (Final)
  ┌────────────────────────────────────────────────────────────────────┐
  │  ► After distribution, admin locks the schedule                    │
  │  ► msh_marksheet_schedules: status → LOCKED, is_locked → 1         │
  │  ► locked_at, locked_by recorded                                   │
  │  ► No further modifications possible unless unlocked               │
  │                                                                    │
  │  ► Unlock (exceptional):                                           │
  │    - Admin must provide mandatory unlock_reason                    │
  │    - unlocked_at, unlocked_by recorded                             │
  │    - msh_computation_logs: UNLOCK action logged                    │
  │    - Schedule goes back to COMPUTED for re-review                  │
  └────────────────────────────────────────────────────────────────────┘
```

### Complete Lifecycle State Machine

```
                ┌───────────┐
                │   DRAFT   │  (Schedule created, class-sections assigned)
                └─────┬─────┘
                      │ Admin clicks "Compute"
                      ▼
                ┌───────────┐
         ┌──────│ COMPUTED  │◄──────────────┐
         │      └─────┬─────┘               │
         │            │ Admin approves       │ Corrections needed
         │            ▼                      │ → Recompute
         │      ┌───────────┐               │
         │      │ REVIEWED  │───────────────┘
         │      └─────┬─────┘
         │            │ Admin publishes
         │            ▼
         │      ┌───────────┐
         │      │ PUBLISHED │  (Visible to students/parents)
         │      └─────┬─────┘
         │            │ Admin locks
         │            ▼
         │      ┌───────────┐
         │      │  LOCKED   │  (Immutable — final state)
         │      └─────┬─────┘
         │            │ Exceptional unlock (with reason)
         │            │
         └────────────┘  (Back to COMPUTED for re-review)
```

---

## 5. Important Design Details

### 5.1 Key Design Decisions

| Decision ID | Rule | Rationale |
|-------------|------|-----------|
| D-MSG-001 | No `tenant_id` column in any table | stancl/tenancy v3.9 uses database-per-tenant. Each tenant has its own database, so tenant_id is implicit. |
| D-MSG-002 | No ENUMs anywhere | All status/type fields use `sys_dropdown_table` or dedicated lookup tables. This avoids MySQL ALTER TABLE for adding new values. |
| D-MSG-003 | `msh_class_groups` is separate from `sch_class_groups_jnt` | Timetable class groupings serve a different purpose (scheduling). Marksheet groupings are about report format. Coupling them would create unwanted dependencies. |
| D-MSG-004 | Online/Offline exam transparency | Both online and offline exams write to `lms_exam_results`. MSG reads from that single source. No special handling needed. |
| D-MSG-005 | Subject-wise result is the core table | `msh_student_subject_results` (T18) is the primary data table. `msh_student_results` (T17) is a computed aggregate. |
| D-MSG-006 | IA marks are owned by MSG | Internal Assessment marks are entered directly in this module by teachers, not pulled from LMS. This is because IA is marksheet-specific. |
| D-MSG-007 | Co-Scholastic grades are owned by MSG | Like IA, co-scholastic grades are entered in this module, with optional auto-population from BehaviouralAssessment. |

### 5.2 Two-Level Weightage System

The weightage calculation works at two levels:

```
  Level 1: Component Weightages (T9: msh_template_scholastic_components)
  ┌───────────────┬──────────────┐
  │ Component     │ Weightage %  │
  ├───────────────┼──────────────┤
  │ Exam          │ 80.00%       │  ← Sum must = 100%
  │ Homework      │ 10.00%       │
  │ Quiz          │  5.00%       │
  │ Quest         │  5.00%       │
  └───────────────┴──────────────┘

  Level 2: Exam-Type Weightages (T10: msh_template_exam_weightages)
  ┌───────────────┬──────────────┐
  │ Exam Type     │ Weightage %  │
  ├───────────────┼──────────────┤
  │ UT-1          │ 10.00%       │  ← Sum must = 100%
  │ UT-2          │ 10.00%       │    (within the Exam component)
  │ Half-Yearly   │ 80.00%       │
  └───────────────┴──────────────┘

  Final Computation Example (Subject: Mathematics, Student: Rahul):
  ─────────────────────────────────────────────────────────────────
  UT-1:  45/50  → weighted = 45 * 10% = 4.50
  UT-2:  48/50  → weighted = 48 * 10% = 4.80
  HY:    72/80  → weighted = 72 * 80% = 57.60
                              Exam total = 66.90
                              Exam component = 66.90 * 80% = 53.52

  Homework avg:  85%  → of 10 max   = 8.50 * 10%  = 0.85
  Quiz avg:      90%  → of 5 max    = 4.50 *  5%  = 0.225
  Quest avg:     78%  → of 5 max    = 3.90 *  5%  = 0.195

  Subject Total = 53.52 + 0.85 + 0.225 + 0.195 = 54.79 / max marks
```

### 5.3 Best-of-N Logic

When `is_best_of_n_enabled = 1` in the config template:

- Only the top N unit test scores are considered (e.g., best 2 out of 4 UTs)
- The remaining UT scores are excluded from the exam weighted calculation
- This is configured per template, so different class groups can have different rules
- The computation job must sort UT marks and pick only the best `best_of_n_count`

### 5.4 Promotion Status Logic

```
  subjects_failed = 0                              → PROMOTED
  subjects_failed > 0 AND
    subjects_failed <= compartment_max_failures     → COMPARTMENT
  subjects_failed > compartment_max_failures        → DETAINED
  Manual override by admin                          → PLACED
```

### 5.5 Lock Guard / Immutability Rules

- When a schedule is **PUBLISHED**, the linked `msh_config_templates.is_locked` becomes 1
- A locked template cannot be edited (business rule BR-MSG-027)
- Unlocking a LOCKED schedule requires:
  - A mandatory `unlock_reason` (TEXT, cannot be empty)
  - `unlocked_by` and `unlocked_at` are recorded
  - An UNLOCK entry is written to `msh_computation_logs`
  - The schedule returns to COMPUTED status

### 5.6 Cross-Module Dependencies (Read-Only)

MSG reads from these external tables but **never writes** to them:

| External Table | What MSG reads | In which step |
|----------------|---------------|---------------|
| `sch_classes` | Class list for grouping and assignment | Setup (T5, T13, T14) |
| `sch_sections` | Section list | Indirect via `sch_class_section_jnt` |
| `sch_class_section_jnt` | Class-section combinations | Schedule (T16), Results (T17) |
| `sch_subjects` | Subject list | Practical config (T14), Results (T18-T20) |
| `sch_org_academic_sessions_jnt` | Academic session for scoping | Exam groups (T6), Templates (T8), Schedules (T15) |
| `std_students` | Student list for result generation | All result tables (T17-T22) |
| `sys_users` | User IDs for audit fields | All tables (created_by, updated_by, entered_by) |
| `sys_dropdown_table` | Schedule status values | Schedule (T15) |
| `slb_grade_division_master` | Grade lookup (percentage → grade) | Template (T8), Computation |
| `lms_exam_types` | Exam type definitions | Exam groups (T7), Weightages (T10), Marks (T19) |
| `lms_exam_results` | Raw exam marks (the primary data source) | Computation → T19 |

### 5.7 Volume Estimation per Schedule

For a typical school with 500 students, 8 subjects, 3 exam types, 3 IA components:

| Table | Formula | Estimated Rows |
|-------|---------|----------------|
| T17: student_results | 500 students | 500 |
| T18: student_subject_results | 500 x 8 subjects | 4,000 |
| T19: student_subject_exam_marks | 500 x 8 x 3 exams | 12,000 |
| T20: student_ia_marks | 500 x 8 x 3 IA components | 12,000 |
| T21: student_coscholastic_results | 500 x 4 areas | 2,000 |
| T22: student_attendance | 500 students | 500 |
| **Total per schedule** | | **~31,000** |
| **Per session (4 schedules)** | | **~124,000** |

### 5.8 Indexing Strategy

Key indexes designed for common query patterns:

| Query Pattern | Index Used |
|---------------|-----------|
| "Show all results for a schedule" | PK on schedule_id (cascading) |
| "Show all results for a student" | `idx_msh_sr_student`, `idx_msh_ssr_student` |
| "Rank students in a section" | `idx_msh_sr_rank` (schedule_id, class_section_id, rank_in_section) |
| "Get marks for a subject across an exam group" | `idx_msh_ssem_subject`, `idx_msh_ssem_exam_type` |
| "Find schedule by session + code" | `uq_msh_ms_session_code` |
| "Find template by session + code" | `uq_msh_ct_session_code` |

### 5.9 Soft Delete Strategy

- All tables except T23 (`msh_computation_logs`) have a `deleted_at` column for Laravel SoftDeletes
- T23 is an **immutable audit log** - records are never deleted
- Soft deletes preserve historical data while hiding records from normal queries
- IMPORTANT: Unique constraints interact with soft deletes - a soft-deleted record still occupies the unique key slot in MySQL. Use `whereNull('deleted_at')` scoping or consider unique index on non-deleted rows only

### 5.10 Naming Conventions Used

| Convention | Example | Meaning |
|------------|---------|---------|
| `msh_` prefix | `msh_student_results` | All tables belong to MarksheetGeneration module |
| `_jnt` suffix | `msh_class_group_items_jnt` | Junction table (many-to-many relationship) |
| `uq_` prefix | `uq_msh_sr_schedule_student` | Unique key constraint |
| `fk_` prefix | `fk_msh_sr_schedule` | Foreign key constraint |
| `idx_` prefix | `idx_msh_sr_rank` | Index (non-unique) |
| `chk_` prefix | `chk_msh_ccj_target` | CHECK constraint |

---

## 6. Seeder Data Reference

### msh_source_components (4 rows - seeded at onboarding)

| code | name | is_mandatory |
|------|------|-------------|
| EXAM | Examination | 1 |
| HOMEWORK | Homework | 0 |
| QUIZ | Quiz | 0 |
| QUEST | Quest | 0 |

### msh_ia_component_types (4 rows - seeded, school can add more)

| code | name |
|------|------|
| NOTEBOOK | Notebook Submission |
| SUB_ENRICHMENT | Subject Enrichment Activity |
| PERIODIC_ASSESS | Periodic Assessment |
| PARTICIPATION | Class Participation |

### sys_dropdown_table entries for schedule status

| key | value | display_order |
|-----|-------|---------------|
| msh_marksheet_schedules.status_id | DRAFT | 1 |
| msh_marksheet_schedules.status_id | COMPUTED | 2 |
| msh_marksheet_schedules.status_id | REVIEWED | 3 |
| msh_marksheet_schedules.status_id | PUBLISHED | 4 |
| msh_marksheet_schedules.status_id | LOCKED | 5 |
