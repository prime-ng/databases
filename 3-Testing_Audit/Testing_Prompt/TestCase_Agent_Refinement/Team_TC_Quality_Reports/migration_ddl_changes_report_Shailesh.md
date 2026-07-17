# Migration DDL Schema Changes Report

This report documents the schema migration fixes applied to resolve the incompatible foreign key constraint error (**SQLSTATE[HY000]: General error: 3780**) on the `subject_id` column.

## 🔍 Root Cause Analysis
The primary key `id` in the `sch_subjects` table is defined as:
```php
$table->id(); // Generates BIGINT UNSIGNED
```
However, multiple referencing tables defined their foreign key column `subject_id` as:
```php
$table->unsignedInteger('subject_id'); // Generates INT UNSIGNED
```
In MySQL, foreign key constraints require referencing and referenced columns to have identical data types and sizes. Thus, `subject_id` must be updated to `unsignedBigInteger` (`BIGINT UNSIGNED`) across all affected tables.

---

## 🛠️ Summary of Required Changes

All the following files are located under: `database/migrations/tenant/`

| # | Migration File | Table | Line | Original Column Definition | Updated Column Definition |
|---|----------------|-------|------|----------------------------|---------------------------|
| 1 | [2026_06_15_145711_create_slb_lessons_table.php](database/migrations/tenant/2026_06_15_145711_create_slb_lessons_table.php#L38) | `slb_lessons` | 38 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 2 | [2026_06_15_145712_create_slb_competencies_table.php](database/migrations/tenant/2026_06_15_145712_create_slb_competencies_table.php#L34) | `slb_competencies` | 34 | `$table->unsignedInteger('subject_id')->nullable();` | `$table->unsignedBigInteger('subject_id')->nullable();` |
| 3 | [2026_06_15_145814_create_slb_topics_table.php](database/migrations/tenant/2026_06_15_145814_create_slb_topics_table.php#L43) | `slb_topics` | 43 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 4 | [2026_06_15_145815_create_slb_syllabus_schedule_table.php](database/migrations/tenant/2026_06_15_145815_create_slb_syllabus_schedule_table.php#L34) | `slb_syllabus_schedule` | 34 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 5 | [2026_06_15_145821_create_slb_book_class_subject_jnt_table.php](database/migrations/tenant/2026_06_15_145821_create_slb_book_class_subject_jnt_table.php#L26) | `slb_book_class_subject_jnt` | 26 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 6 | [2026_06_15_145823_create_slb_notes_table.php](database/migrations/tenant/2026_06_15_145823_create_slb_notes_table.php#L36) | `slb_notes` | 36 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 7 | [2026_06_15_150107_create_sch_class_group_subject_options_jnt_table.php](database/migrations/tenant/2026_06_15_150107_create_sch_class_group_subject_options_jnt_table.php#L31) | `sch_class_group_subject_options_jnt` | 31 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 8 | [2026_06_15_150108_create_sch_subject_study_format_jnt_table.php](database/migrations/tenant/2026_06_15_150108_create_sch_subject_study_format_jnt_table.php#L28) | `sch_subject_study_format_jnt` | 28 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 9 | [2026_06_15_150111_create_sch_subject_group_subject_jnt_table.php](database/migrations/tenant/2026_06_15_150111_create_sch_subject_group_subject_jnt_table.php#L25) | `sch_subject_group_subject_jnt` | 25 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 10 | [2026_06_15_150343_create_lms_quizzes_table.php](database/migrations/tenant/2026_06_15_150343_create_lms_quizzes_table.php#L51) | `lms_quizzes` | 51 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 11 | [2026_06_15_150344_create_lms_quests_table.php](database/migrations/tenant/2026_06_15_150344_create_lms_quests_table.php#L49) | `lms_quests` | 49 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 12 | [2026_06_15_151316_create_std_student_opted_subjects_table.php](database/migrations/tenant/2026_06_15_151316_create_std_student_opted_subjects_table.php#L22) | `std_student_opted_subjects` | 22 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 13 | [2026_06_15_151318_create_qns_questions_bank_table.php](database/migrations/tenant/2026_06_15_151318_create_qns_questions_bank_table.php#L47) | `qns_questions_bank` | 47 | `$table->unsignedInteger('subject_id')->nullable();` | `$table->unsignedBigInteger('subject_id')->nullable();` |
| 14 | [2026_06_15_151406_create_lib_book_subject_jnt_table.php](database/migrations/tenant/2026_06_15_151406_create_lib_book_subject_jnt_table.php#L24) | `lib_book_subject_jnt` | 24 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 15 | [2026_06_15_151407_create_lib_curricular_alignment_table.php](database/migrations/tenant/2026_06_15_151407_create_lib_curricular_alignment_table.php#L34) | `lib_curricular_alignment` | 34 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 16 | [2026_06_16_112705_create_lms_exam_papers_table.php](database/migrations/tenant/2026_06_16_112705_create_lms_exam_papers_table.php#L47) | `lms_exam_papers` | 47 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 17 | [2026_06_16_115730_create_msh_subject_practical_configs_table.php](database/migrations/tenant/2026_06_16_115730_create_msh_subject_practical_configs_table.php#L30) | `msh_subject_practical_configs` | 30 | `$table->unsignedInteger('subject_id')->comment('...');` | `$table->unsignedBigInteger('subject_id')->comment('...');` |
| 18 | [2026_06_16_115744_create_msh_student_subject_exam_marks_table.php](database/migrations/tenant/2026_06_16_115744_create_msh_student_subject_exam_marks_table.php#L31) | `msh_student_subject_exam_marks` | 31 | `$table->unsignedInteger('subject_id')->comment('...');` | `$table->unsignedBigInteger('subject_id')->comment('...');` |
| 19 | [2026_06_16_115745_create_msh_student_subject_results_table.php](database/migrations/tenant/2026_06_16_115745_create_msh_student_subject_results_table.php#L39) | `msh_student_subject_results` | 39 | `$table->unsignedInteger('subject_id')->comment('...');` | `$table->unsignedBigInteger('subject_id')->comment('...');` |
| 20 | [2026_06_16_115747_create_msh_student_ia_marks_table.php](database/migrations/tenant/2026_06_16_115747_create_msh_student_ia_marks_table.php#L31) | `msh_student_ia_marks` | 31 | `$table->unsignedInteger('subject_id')->comment('...');` | `$table->unsignedBigInteger('subject_id')->comment('...');` |
| 21 | [2026_06_16_122811_create_lms_homework_table.php](database/migrations/tenant/2026_06_16_122811_create_lms_homework_table.php#L39) | `lms_homework` | 39 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 22 | [2026_06_16_122812_create_lms_homework_assignment_table.php](database/migrations/tenant/2026_06_16_122812_create_lms_homework_assignment_table.php#L44) | `lms_homework_assignment` | 44 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 23 | [2026_06_16_130058_create_rec_recommendation_materials_table.php](database/migrations/tenant/2026_06_16_130058_create_rec_recommendation_materials_table.php#L39) | `rec_recommendation_materials` | 39 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |
| 24 | [2026_06_16_130100_create_rec_recommendation_rules_table.php](database/migrations/tenant/2026_06_16_130100_create_rec_recommendation_rules_table.php#L29) | `rec_recommendation_rules` | 29 | `$table->unsignedInteger('subject_id')->nullable();` | `$table->unsignedBigInteger('subject_id')->nullable();` |
| 25 | [2026_06_16_152630_create_tt_activity_table.php](database/migrations/tenant/2026_06_16_152630_create_tt_activity_table.php#L66) | `tt_activities` | 66 | `$table->unsignedInteger('subject_id')->nullable();` | `$table->unsignedBigInteger('subject_id')->nullable();` |
| 26 | [2026_06_27_000001_create_slb_syllabus_periods_allocation_table.php](database/migrations/tenant/2026_06_27_000001_create_slb_syllabus_periods_allocation_table.php#L18) | `slb_syllabus_periods_allocation` | 18 | `$table->unsignedInteger('subject_id');` | `$table->unsignedBigInteger('subject_id');` |

---
*Report generated on 2026-07-15.*
