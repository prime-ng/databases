# Schema vs Laravel Cross-Reference Analysis
**Date:** 2026-03-01
**Schema Source:** `1-master_dbs/1-DDL_schema/tenant_db.sql` + `2-Tenant_Modules/*/DDL/*.sql`
**Laravel Source:** `/Users/bkwork/Herd/laravel/Modules/*/app/Models/`

---

## Executive Summary

| Finding | Count | Severity |
|---------|-------|----------|
| SmartTimetable: All tt_ tables Singular in schema, Plural in Laravel | 20+ tables | CRITICAL |
| HPC: Table names differ between schema and Laravel | 2 tables | CRITICAL |
| tenant_db.sql incomplete — 6+ modules not yet merged | ~80 tables | HIGH |
| Notification: ntf_templates vs ntf_notification_templates | 1 table | HIGH |
| Transport: 8 Laravel models have no schema table | 8 models | HIGH |
| SmartTimetable: 8 Laravel tables not in any schema | 8 tables | HIGH |
| 2 SmartTimetable models use wrong table prefix (no tt_) | 2 models | MEDIUM |
| StudentFee: Singular/plural mismatches | 5 tables | MEDIUM |
| SyllabusBooks + Syllabus share the same tables | 6 tables | MEDIUM |
| SchoolSetup contains backup/stale models | 3 models | LOW |

---

## CRITICAL Issues

### 1. SmartTimetable — Singular (Schema) vs Plural (Laravel)

The **entire SmartTimetable module** has a systematic naming mismatch. Schema uses SINGULAR, Laravel models use PLURAL.

| Schema Table (tenant_db.sql) | Laravel Model | Laravel $table |
|-----------------------------|---------------|----------------|
| `tt_activity` | Activity | `tt_activities` ❌ |
| `tt_activity_teacher` | ActivityTeacher | `tt_activity_teachers` ❌ |
| `tt_change_log` | ChangeLog | `tt_change_logs` ❌ |
| `tt_class_mode_rule` | ClassModeRule | `tt_class_mode_rules` ❌ |
| `tt_class_subgroup` | ClassSubjectSubgroup | `tt_class_subject_subgroups` ❌ (also name diff) |
| `tt_class_subgroup_member` | ClassSubgroupMember | `tt_class_subgroup_members` ❌ |
| `tt_constraint` | Constraint | `tt_constraints` ❌ |
| `tt_constraint_type` | ConstraintType | `tt_constraint_types` ❌ |
| `tt_constraint_violation` | ConstraintViolation | `tt_constraint_violations` ❌ |
| `tt_day_type` | DayType | `tt_day_types` ❌ |
| `tt_generation_run` | GenerationRun | `tt_generation_runs` ❌ |
| `tt_period_set` | PeriodSet | `tt_period_sets` ❌ |
| `tt_period_type` | PeriodType | `tt_period_types` ❌ |
| `tt_room_unavailable` | RoomUnavailable | `tt_room_unavailables` ❌ |
| `tt_school_days` | SchoolDay | `tt_school_days` ✅ |
| `tt_shift` | SchoolShift | `tt_shifts` ❌ (also model name differs) |
| `tt_sub_activity` | SubActivity | `tt_sub_activities` ❌ |
| `tt_substitution_log` | SubstitutionLog | `tt_substitution_logs` ❌ |
| `tt_teacher_absence` | TeacherAbsences | `tt_teacher_absences` ❌ |
| `tt_teacher_assignment_role` | TeacherAssignmentRole | `tt_teacher_assignment_roles` ❌ |
| `tt_teacher_unavailable` | TeacherUnavailable | `tt_teacher_unavailables` ❌ |
| `tt_teacher_workload` | TeacherWorkload | `tt_teacher_workloads` ❌ |
| `tt_timetable` | Timetable | `tt_timetables` ❌ |
| `tt_timetable_cell` | TimetableCell | `tt_timetable_cells` ❌ |
| `tt_timetable_cell_teacher` | TimetableCellTeacher | `tt_timetable_cell_teachers` ❌ |
| `tt_timetable_type` | TimetableType | `tt_timetable_types` ❌ |
| `tt_period_set_period_jnt` | PeriodSetPeriod | `tt_period_set_period_jnt` ✅ |
| `tt_working_day` | WorkingDay | `tt_working_day` ✅ |

**Action Required:** Decide on ONE naming convention — either update the schema to use plural OR update all Laravel `$table` definitions to singular. Schema should be the source of truth.

---

### 2. HPC — Table Name Differences

| Schema Table | Laravel Model | Laravel $table | Issue |
|-------------|---------------|----------------|-------|
| `hpc_hpc_parameters` | HpcParameters | `hpc_ability_parameters` | ❌ Different name |
| `hpc_student_hpc_evaluation` | StudentHpcEvaluation | `hpc_student_evaluation` | ❌ Different name |

**Action Required:** Either rename the Laravel `$table` to match schema, or update schema to match Laravel.

---

## HIGH Severity Issues

### 3. tenant_db.sql Is Incomplete — Modules Not Yet Merged

The `tenant_db.sql` is the consolidated master schema, but these modules have **separate DDL files** that have **not yet been merged** into tenant_db.sql:

| Module | DDL File (latest) | Tables |
|--------|------------------|--------|
| LMS Exam | `16-LMS/5-LMS_Exam/LMS_Exam_ddl_v5.sql` | 11 tables (`lms_exam_*`) |
| LMS Homework | `16-LMS/2-LMS_Homework/LMS_Homework_DDL_v2.sql` | `lms_homework`, `lms_homework_submissions`, etc. |
| LMS Quiz | `16-LMS/3-LMS_Quiz/LMS_Quiz_ddl_v2.sql` | `lms_quizzes`, `lms_quiz_*` |
| LMS Quest | `16-LMS/4-LMS_Quest/LMS_Quest_ddl_v2.sql` | `lms_quests`, `lms_quest_*` |
| Student Fees | `19-Student_Fees_Module/DDL/Student_Fee_Module_v4.sql` | 23 tables (`fee_*`) |
| School Setup | `3-School_Setup/DDLs/*.sql` | 18+ tables (`sch_buildings`, `sch_classes`, `sch_subjects`, etc.) |
| Library | `18-Library/DDL/Library_ddl_v1.sql` | `lib_*` tables |
| Accounting | `20-Accounting/DDL/Accounting_ddl_v1.sql` | `acc_*` tables |
| FrontDesk | `15-Frontdesk_mgmt/DDL/FrontDesk_v1.0.sql` | `fnt_*` tables |

**Action Required:** After finalizing each module's DDL, merge into `tenant_db.sql`.

---

### 4. Notification — Table Name Mismatch + Missing Tables

| Schema Table | Laravel $table | Status |
|-------------|----------------|--------|
| `ntf_templates` | `ntf_notification_templates` | ❌ Name mismatch |
| *(not in schema)* | `ntf_delivery_queue` | ❌ Missing from schema |
| *(not in schema)* | `ntf_notification_threads` | ❌ Missing from schema |
| *(not in schema)* | `ntf_notification_thread_members` | ❌ Missing from schema |
| *(not in schema)* | `ntf_provider_master` | ❌ Missing from schema |
| *(not in schema)* | `ntf_target_groups` | ❌ Missing from schema |
| *(not in schema)* | `ntf_user_devices` | ❌ Missing from schema |

The latest Notification DDL is `7-Notification/V2/Notification_ddl_v3.sql` — verify if these tables are there and merge into tenant_db.sql.

---

### 5. Transport — Laravel Models With No Schema Tables

These Laravel models in the Transport module point to tables that **do not exist anywhere in the schema**:

| Laravel Model | $table | Notes |
|--------------|--------|-------|
| MlModels | *(none)* | ML prediction models |
| MlModelFeatures | *(none)* | ML feature store |
| TptGpsAlerts | *(none)* | GPS alert tracking |
| TptGpsTripLog | *(none)* | GPS trip data |
| TptFeatureStore | *(none)* | Feature engineering store |
| TptModelRecommendations | *(none)* | AI recommendations |
| TptRecommendationHistory | *(none)* | Recommendation history |
| TptStudentEventLog | *(none)* | Student event log |
| TptNotificationLog | *(no $table)* | Transport notifications |

**Also:** Schema has `tpt_notification_log` table but no Laravel model maps to it.

**Action Required:** Determine if these ML/GPS features are planned. If yes, add tables to schema. If no, remove the model files.

---

### 6. SmartTimetable — Laravel Tables Not in Schema

These Laravel models reference tables that **don't exist in any schema file**:

| Laravel Model | Laravel $table | Notes |
|--------------|----------------|-------|
| TtConfig | `tt_config` | System config table |
| TtGenerationStrategy | `tt_generation_strategy` | Generation strategy |
| ConflictDetection | `tt_conflict_detections` | Conflict tracking |
| RequirementConsolidation | `tt_requirement_consolidations` | Req. consolidation |
| ResourceBooking | `tt_resource_bookings` | Room/resource booking |
| SlotRequirement | `tt_slot_requirements` | Slot requirements |
| ConstraintCategoryScope | `tt_constraint_category_scope` | Constraint scoping |
| ClassSubjectGroup | `tt_class_subject_groups` | Subject grouping |

Schema has `tt_class_group_requirement` with no corresponding Laravel model.

**Action Required:** Update schema to include these new tables OR align with schema's `tt_class_group_requirement`.

---

## MEDIUM Severity Issues

### 7. Two SmartTimetable Models Use Wrong Table Prefix

| Laravel Model | Laravel $table | Should Be |
|--------------|----------------|-----------|
| ClassWorkingDay | `class_working_days` | `tt_class_working_days` |
| TeacherAvailabilityLog | `teacher_availability_logs` | `tt_teacher_availability_logs` |

These are missing the `tt_` prefix — they will query or create tables in a wrong location.

---

### 8. StudentFee — Singular/Plural Mismatches

Schema (from `Student_Fee_Module_v4.sql`) uses singular, Laravel models use plural:

| Schema Table | Laravel $table | Issue |
|-------------|----------------|-------|
| `fee_head_master` | `fee_head_masters` | ❌ |
| `fee_group_master` | `fee_group_masters` | ❌ |
| `fee_name_removal_log` | `fee_name_removal_logs` | ❌ |
| `fee_scholarship_approval_history` | `fee_scholarship_approval_histories` | ❌ |
| `fee_structure_master` | `fee_structure_masters` | ❌ |

**Also in schema but NOT in Laravel models:**
- `fee_concession_applicable_heads` — no model
- `fee_defaulter_history` — no model
- `fee_payment_reconciliation` — no model
- `fee_refunds` — no model

---

### 9. SyllabusBooks + Syllabus — Shared Table Overlap

Both modules reference the SAME schema tables:

| Table | Syllabus Module | SyllabusBooks Module |
|-------|----------------|---------------------|
| `slb_books` | Book model | BokBook model |
| `slb_book_authors` | BookAuthor model | BookAuthors model |
| `slb_book_class_subject_jnt` | BookClassSubject model | BookClassSubject model |
| `slb_book_topic_mapping` | BookTopicMapping model | — |
| `bok_book_topic_mapping` | — | BookTopicMapping model |

**Issues:**
- `slb_book_topic_mapping` (schema) vs `bok_book_topic_mapping` (SyllabusBooks) — different prefix!
- Same tables managed by two modules creates ownership confusion
- `SyllabusBooks|MediaFiles|media_files` — should be `sys_media`, not `media_files`

---

## LOW Severity Issues

### 10. SchoolSetup — Stale Backup Models

These backup model files should be removed from the module:

| Model File | $table | Notes |
|-----------|--------|-------|
| Student_Backup_04_12_2025.php | `std_students` | Old backup |
| StudentAcademicSession_Backup_04_12_2025.php | `std_student_academic_sessions_jnt` | Old backup |
| StudentDetail_Backup_04_12_2025.php | `std_student_detail` | Old backup |

These belong in StudentProfile module, not SchoolSetup.

---

## Module-by-Module Alignment Status

| Module | Schema Tables | Laravel Models | Alignment |
|--------|--------------|----------------|-----------|
| Prime | prime_db.sql (complete) | 27 models | ✅ Good |
| Billing | prime_db.sql (complete) | 6 models | ✅ Good |
| GlobalMaster | global_db.sql (complete) | 12 models | ✅ Good |
| Complaint | tenant_db.sql (6 tables) | 6 models | ✅ Good |
| Vendor | tenant_db.sql (7 tables) | 8 models | ✅ Good |
| Recommendation | tenant_db.sql (10 tables) | 11 models | ✅ Good |
| QuestionBank | tenant_db.sql (13 tables) | 17 models | ✅ Good |
| StudentProfile | tenant_db.sql (14 tables) | 14 models | ✅ Good |
| Syllabus | tenant_db.sql (14 tables) | 22 models | ⚠️ Book tables shared with SyllabusBooks |
| HPC | tenant_db.sql (14 tables) | 15 models | ⚠️ 2 table name mismatches |
| Notification | tenant_db.sql (8 tables) | 14 models | ⚠️ 1 name mismatch + 6 missing schema tables |
| SchoolSetup | DDL files (18 tables) | 42 models | ⚠️ Not merged to tenant_db.sql + backup models |
| Transport | tenant_db.sql (22 tables) | 36 models | ⚠️ 9 models without schema tables |
| StudentFee | DDL file (23 tables) | 20 models | ⚠️ Not merged to tenant_db.sql + 5 name mismatches + 4 missing models |
| LmsExam | DDL file (11 tables) | 11 models | ⚠️ Not merged to tenant_db.sql |
| LmsHomework | DDL file (5+ tables) | 5 models | ⚠️ Not merged to tenant_db.sql |
| LmsQuiz | DDL file (6+ tables) | 6 models | ⚠️ Not merged to tenant_db.sql |
| LmsQuests | DDL file (4+ tables) | 4 models | ⚠️ Not merged to tenant_db.sql |
| SmartTimetable | tenant_db.sql (28 tables) | 41 models | ❌ All table names mismatched (singular vs plural) |
| SyllabusBooks | DDL file / tenant_db.sql | 6 models | ⚠️ Shared tables with Syllabus + wrong prefix |
| Library | DDL file (lib_*) | 1 model | ❌ No schema-model alignment at all |
| Payment | *(no schema)* | 5 models | ❌ No schema tables defined |
| Scheduler | *(laravel default)* | 2 models | ⚠️ Uses Laravel's default `schedules` table |
| Documentation | *(doc_*)* | 2 models | ⚠️ No schema file found |
| SystemConfig | global_db.sql | 3 models | ✅ Good |
| Dashboard | *(no tables)* | 0 models | ✅ N/A |
| StudentPortal | *(no tables)* | 0 models | ✅ N/A |

---

## Schema Tables With No Laravel Module (Pending Modules)

These tables exist in schema/DDL files but have **no Laravel module yet**:

| Table Prefix | Module Name | Status |
|-------------|-------------|--------|
| `acc_*` | Accounting | DDL exists (`Accounting_ddl_v1.sql`), no Laravel module |
| `fnt_*` | FrontDesk | DDL exists (`FrontDesk_v1.0.sql`), no Laravel module |
| `lib_*` | Library | DDL exists (`Library_ddl_v1.sql`), only skeleton module |
| `hpc_curriculum_change_request` | HPC | In schema, no model |
| `hpc_lesson_version_control` | HPC | In schema, no model |
| `sch_board_organization_jnt` | SchoolSetup | In schema, no model |
| `tpt_notification_log` | Transport | In schema, no model |

**Pending modules with NO schema yet:**
- Behavioral Assessment (`beh_*`)
- Hostel Management (`hos_*`)
- Mess/Canteen (`mes_*`)
- HR & Payroll
- Inventory Management
- Admission Enquiry
- Visitor Management

---

## Priority Action Items

### Immediate (Before Writing Migrations)
1. **Resolve SmartTimetable naming** — pick singular OR plural for all `tt_*` tables and make both schema and Laravel consistent
2. **Fix HPC table names** — `hpc_ability_parameters` → `hpc_hpc_parameters` (or vice versa)
3. **Fix 2 wrong prefixes** — `class_working_days` → `tt_class_working_days`, `teacher_availability_logs` → `tt_teacher_availability_logs`
4. **Fix Notification** — `ntf_notification_templates` → `ntf_templates` (or vice versa)

### Short Term (Schema Consolidation)
5. **Merge into tenant_db.sql:** LmsExam, LmsHomework, LmsQuiz, LmsQuests, StudentFee, SchoolSetup DDLs
6. **Add missing schema tables:** Notification threads/providers, SmartTimetable new tables
7. **Remove backup models** from SchoolSetup module

### Medium Term (Completeness)
8. **Define schema for Payment module** (`ptm_*` tables)
9. **Resolve SyllabusBooks/Syllabus overlap** — decide ownership of book tables
10. **Create schema for Transport ML/GPS tables** or remove those model files
11. **Finalize Library module** DDL and create models
