---
name: LMS Modules Deep Knowledge
description: Tables, key fields, schema facts, model relationships, critical bugs, and cross-module dependencies for 6 LMS modules (Syllabus, LmsQuiz, LmsQuests, LmsExam, LmsHomework, QuestionBank)
type: reference
---

# LMS Modules — Deep Knowledge Reference

> **Source:** LMS documentation v4 from `{DB_REPO}/7-Work_on_Modules/LMS/v4/`
> **Last Updated:** 2026-03-21

## Module Overview

| Module | Tables | Route Prefix | Status | Critical Issues |
|---|---|---|---|---|
| Syllabus | `slb_*` (15 tables) | `/syllabus/*` | ~100% | CR-003 (policies may now exist — verify) |
| LmsQuiz | `lms_quizzes`, `lms_assessment_types`, `lms_difficulty_distribution_configs` | `/lms-quize/*` | ~90% | CR-008 (no `exists` on academic_session_id) |
| LmsQuests | `lms_quests`, `lms_quest_scopes`, `lms_quest_questions`, `lms_quest_allocations` | `/lms-quests/*` | ~85% | CR-010 (academic fields nullable/unvalidated) |
| LmsExam | `lms_exams`, `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_blueprints`, `lms_exam_scopes`, `lms_exam_allocations` + 5 more | `/lms-exam/*` | ~90% | CR-007 (null->code TypeError), CR-009, CR-031 |
| LmsHomework | `lms_homework`, `lms_homework_submissions`, `lms_rule_engine_configs`, `lms_trigger_events`, `lms_action_type` | `/lms-home-work/*` | ~80% | CR-002 (no HomeworkPolicy), CR-006 |
| QuestionBank | `qns_questions_bank`, `qns_question_options`, `qns_media_store`, `qns_question_media_jnt` + 8 inferred | `/question-bank/*` | ~85% | CR-001 (API keys hardcoded) |

**Totals:** 47 controllers, 64 models, ~190 routes, 22 policies found (10+ missing), 43 code review issues.

## Syllabus Module

**Key tables:** `slb_lessons`, `slb_topics`, `slb_bloom_taxonomy`, `slb_cognitive_skills`, `slb_competencies`, `slb_complexity_level`, `slb_question_types`, `slb_ques_type_specificities`, `slb_performance_categories`, `slb_grade_division_master`, `slb_syllabus_schedule`, `slb_topic_competency`, `slb_topic_dependencies`, `slb_study_materials`, `slb_topic_level_types`

**Schema facts:**
- `slb_lessons`: unique per (academic_session_id + class_id + subject_id + name); batch-created via `lessons[]` array
- `slb_topics`: self-referencing via `parent_id`; materialized path in `path` column; `level` auto-computed from parent
- Topic code auto-generated: e.g. `GR5_MATH_L1_TOP01_SUB01`; unique with retry loop
- `resources_json` on lessons: typed URLs (video, pdf, link, document, image, audio, ppt)
- `scheduled_year_week`: integer format YYYYWW (202001–210052)

**Critical bugs:** CR-005 was false alarm (Lesson.php import is correct). CR-003 (missing LessonPolicy/TopicPolicy) may now be resolved — verify registration in AppServiceProvider.

## LmsQuiz Module

**Key tables:** `lms_quizzes`, `lms_assessment_types`, `lms_difficulty_distribution_configs`, `lms_difficulty_distribution_details` (child), `lms_quiz_allocations`

**Schema facts:**
- Quiz status: `DRAFT` -> `PUBLISHED` -> `ARCHIVED` (no back-transition enforcement)
- `difficulty_config_id` FK optional; `ignore_difficulty_config` boolean to bypass
- Allocation types: CLASS, SECTION, GROUP, STUDENT; `due_date` required, `cut_off_date` >= due_date
- Route typo: `/lms-quize/` (not `/lms-quiz/`)

**Difficulty engine (5-step add-time validation):**
1. Check `ignore_difficulty_config` flag
2. Load config + detail rows
3. Calculate current distribution percentages
4. PATH A (calculationBase=percentage) vs PATH B (calculationBase=marks)
5. Enforce max_percentage; min_percentage computed but NOT enforced (CR-032)

**Critical bugs:** CR-008 (`academic_session_id` has no `exists` validation), CR-032 (min_percentage not enforced), CR-033 (difficulty validation skipped at publish time)

## LmsQuests Module

**Key tables:** `lms_quests`, `lms_quest_scopes`, `lms_quest_questions`, `lms_quest_allocations`

**Schema facts:**
- Structurally mirrors Quiz + adds `pending` boolean (lifecycle meaning undefined) and `published_at`
- `canPublish()` guards: validates questions exist, count matches, settings complete, hierarchy set
- `publish()` sets status=PUBLISHED + published_at; `archive()` sets ARCHIVED + is_active=false
- `restoreQuest()` resets to DRAFT + is_active=true
- Quest Scope = lesson+topic boundary definitions per quest
- `duplicate()` method for cloning quests

**Critical bugs:** CR-010 (academic_session_id, class_id, subject_id, lesson_id all `nullable|string` — should be `required|integer|exists`; breaks canPublish()), route duplication in tenant.php (lines 608 and 632-651)

## LmsExam Module

**Key tables:** `lms_exams`, `lms_exam_types`, `lms_exam_status_events`, `lms_exam_papers`, `lms_exam_scopes`, `lms_exam_blueprints`, `lms_exam_paper_sets`, `lms_paper_set_questions`, `lms_exam_student_groups`, `lms_exam_student_group_members`, `lms_exam_allocations`

**Flow:** Exam -> ExamPaper (per subject, ONLINE/OFFLINE) -> PaperSet (versioned question set) -> PaperSetQuestion

**Schema facts:**
- 11 controllers, 11 models — most complex LMS module
- Status via FK to `lms_exam_status_events` (configurable, not hard-coded ENUM)
- ExamPaper `mode`: ONLINE or OFFLINE; `show_result_type`: IMMEDIATE/SCHEDULED/MANUAL (ONLINE only)
- ExamBlueprint: section-wise marking scheme (planning only — advisory, not enforced)
- ExamScope: lesson+topic+question_type coverage (target counts not enforced server-side, CR-035)
- ExamPaper uses `difficulty_config_id` cross-module FK to LmsQuiz's `lms_difficulty_distribution_configs`
- `exam_type_id` unique per (academic_session_id + class_id) — one exam type per class per session

**Critical bugs:** CR-007 (`Exam.generateExamCode()` — `null->code` TypeError; fix: `?->`), CR-009 (no `exists` on academic_session_id), CR-031 (all `Gate::authorize()` commented out in ExamBlueprintController), CR-034 (difficulty validation skipped at publish), CR-035 (ExamScope targets not enforced)

## LmsHomework Module

**Key tables:** `lms_homework`, `lms_homework_submissions`, `lms_trigger_events`, `lms_action_type`, `lms_rule_engine_configs`

**Schema facts:**
- Homework assigned to class+section with `assign_date` and `due_date`
- `submission_type_id`, `status_id`, `release_condition_id` all FK to `sys_dropdowns`
- `difficulty_level_id` FK to `slb_complexity_level` (simple label — no distribution engine)
- Submission: `is_late` = submitted_at > homework.due_date; file uploads via Spatie Media Library
- `isEditable()` = status is DRAFT; `isDeletable()` = no submissions exist
- Rule engine: TriggerEvent (e.g. HOMEWORK_SUBMITTED) -> ActionType (e.g. NOTIFY_TEACHER) -> RuleEngineConfig (maps trigger to action for a class group)

**Critical bugs:** CR-002 (no HomeworkPolicy — any auth user can CRUD all homework), CR-006 (`Homework.php` line 71: `SchAcademicSession::class` undefined — should be `OrganizationAcademicSession::class`)

## QuestionBank Module

**Key tables:** `qns_questions_bank`, `qns_question_options`, `qns_media_store`, `qns_question_media_jnt`, `qns_question_tags`, `qns_question_tag_jnt`, `qns_question_topic_jnt`, `qns_question_statistics`, `qns_question_versions`, `qns_question_usage_types`, `qns_question_usage_logs`, `qns_question_review_logs`

**Schema facts:**
- UUID stored as `binary(16)` with BIN_TO_UUID accessor
- Question status: DRAFT -> PENDING_REVIEW -> APPROVED / REJECTED -> DRAFT (rework)
- `scopeApproved()` exists but NOT applied in quiz/quest/exam search endpoints (gap)
- Availability: GLOBAL / SCHOOL_ONLY / CLASS_ONLY
- Flags: `for_quiz`, `for_assessment`, `for_exam` — control which builders can see the question
- AI: ChatGPT (GPT-4o-mini) + Gemini (gemini-2.0-flash); two-step: generate -> save/download CSV
- CSV import: validate-file -> start-import two-step process
- Search filters: bloom_id, cognitive_skill_id, complexity_level_id, question_type_id, ques_type_specificity_id, topic hierarchy, status, availability, ownership

**Critical bugs:** CR-001 (API keys for OpenAI + Gemini hardcoded in `AIQuestionGeneratorController.php` — accepted as intentional/temporary), CR-043 (QuestionUsageLog forceDeleted on removal — undermines unused-questions filter)

## Cross-Module Dependencies

```
SchoolSetup ─────────────────────────────────┐
SyllabusBooks ──┐                            │
                ▼                            ▼
           Syllabus ◄──────── QuestionBank ◄─┤
               │                   ▲         │
               ▼                   │         │
           LmsQuiz ────────────────┤         │
               │                   │         │
               ▼                   │         │
           LmsQuests ──────────────┘         │
                                             │
           LmsExam ──► LmsQuiz (difficulty)  │
               │       QuestionBank ◄────────┘
               ▼
           StudentProfile (allocations)

           LmsHomework ──► Syllabus, SchoolSetup, StudentProfile
```

Key FK dependencies:
- **LmsExam -> LmsQuiz:** `difficulty_config_id` FK to `lms_difficulty_distribution_configs` (cross-module, CR-040)
- **LmsQuests -> LmsQuiz:** shares `lms_assessment_types` and `lms_difficulty_distribution_configs`
- **All LMS -> Syllabus:** lessons, topics, complexity levels, bloom taxonomy, question types
- **All LMS -> SchoolSetup:** classes, sections, subjects, academic sessions
- **Quiz/Quest/Exam -> QuestionBank:** question sourcing via `qns_questions_bank`

## Status Lifecycles (All Modules)

| Module | Lifecycle | Enforcement |
|---|---|---|
| Quiz | DRAFT -> PUBLISHED -> ARCHIVED | None (can edit published) |
| Quest | DRAFT -> PUBLISHED -> ARCHIVED | `canPublish()` guards on publish |
| Exam | DRAFT -> PUBLISHED -> CONCLUDED -> ARCHIVED | Status via FK (configurable) |
| Homework | DRAFT -> PUBLISHED -> GRADED | `isEditable()` / `isDeletable()` |
| Question | DRAFT -> PENDING_REVIEW -> APPROVED/REJECTED | No server enforcement |

## Reference File Locations

| File | Path |
|---|---|
| Summary Index | `{DB_REPO}/7-Work_on_Modules/LMS/v4/lms_summary_index.md` |
| Master Requirements | `{DB_REPO}/7-Work_on_Modules/LMS/v4/lms_requirements.md` |
| Rules & Conditions | `{DB_REPO}/7-Work_on_Modules/LMS/v4/lms_rules_conditions.md` |
| Code Review | `{DB_REPO}/7-Work_on_Modules/LMS/v4/lms_code_review.md` |
| Quiz Conditions | `{DB_REPO}/7-Work_on_Modules/LMS/LMS_Quiz_Conditions.md` |

`{DB_REPO}` = `/Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase`
