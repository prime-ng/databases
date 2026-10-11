# StudentPortal — StudentAttempt Module Development Guide

**Module Code:** SPT-ATTEMPT
**DDL Source:** `StudentAttempt_ddl_v3.sql`
**MRD Source:** `STP_StudentPortal_Requirement.md` (V2)
**Generated:** 2026-04-02
**Platform:** Prime-AI — Multi-Tenant SaaS for Indian K-12 Schools

---

## Table of Contents

1. [Module Overview](#section-1-module-overview)
2. [Database Layer Guide](#section-2-database-layer-guide)
3. [Model Layer Guide](#section-3-model-layer-guide)
4. [Business Logic Layer](#section-4-business-logic-layer)
5. [API / Controller Layer](#section-5-api--controller-layer)
6. [Authorization Layer](#section-6-authorization-layer)
7. [Frontend Guide](#section-7-frontend-guide)
8. [Events, Notifications & Jobs](#section-8-events-notifications--jobs)
9. [Testing Strategy](#section-9-testing-strategy)
10. [Implementation Roadmap](#section-10-implementation-roadmap)

---

## SECTION 1: MODULE OVERVIEW

### 1.1 Module Identity

| Attribute | Value |
|---|---|
| Module Name | StudentPortal — StudentAttempt |
| Module Code | SPT-ATTEMPT |
| Laravel Module | `Modules/StudentPortal/` (nwidart/laravel-modules v12) |
| Namespace | `Modules\StudentPortal` |
| App | Tenant App only (school subdomain) |
| Database | `tenant_db` exclusively |
| Table Prefix | `lms_` (shared with LMS modules) |
| Route Prefix | `student-portal/` |

### 1.2 Purpose

The StudentAttempt sub-system of the StudentPortal module enables students to **take quizzes, quests, and online exams** directly from their portal, tracks every question response in real time, auto-saves progress to enable crash recovery, and exposes published results, grades, and grievance submission. It also provides teachers the database layer to enter marks for offline exams. The 10 tables in this schema form the **execution and results backbone** of the LMS student-facing experience.

### 1.3 Database Involved

| Database | Role |
|---|---|
| `tenant_db` | All 10 tables live here — one per-school database |
| `prime_db` | Not involved |
| `global_db` | Not involved |

### 1.4 Key User Roles

| Role | Interactions |
|---|---|
| **Student** | Start attempts, submit answers, view results, submit grievances |
| **Parent** | View child's results and attempt history (read-only) |
| **Teacher** | Evaluate descriptive answers, enter offline marks, review grievances |
| **Admin** | Publish results, manage grievances, override marks |
| **System** | Auto-submit on timeout, auto-evaluate MCQ, compute scores/ranks |

### 1.5 Module Dependencies

| Dependency Module | Tables Used | Relationship |
|---|---|---|
| **StudentProfile** | `std_students` | Every attempt record is owned by a student |
| **SystemConfig** | `sys_users`, `sys_media` | Evaluators, uploaded answer sheets/attachments |
| **LmsQuiz** | `lms_quizzes`, `lms_quiz_allocations` | Quiz attempts reference quiz and its allocation |
| **LmsQuests** | `lms_quests`, `lms_quest_allocations` | Quest attempts reference quest and its allocation |
| **LmsExam** | `lms_exams`, `lms_exam_papers`, `lms_exam_paper_sets`, `lms_exam_allocations` | Exam attempts reference the full exam hierarchy |
| **QuestionBank** | `qns_questions_bank`, `qns_question_options` | Answers reference questions and their options |
| **HPC** | Reads `lms_exam_results` | Progress cards pull exam result data |

---

## SECTION 2: DATABASE LAYER GUIDE

### 2.1 Entity-Relationship Summary

#### All 10 Tables

| # | Table | Purpose |
|---|---|---|
| 1 | `lms_quiz_quest_attempts` | One row per student attempt at a Quiz or Quest. Tracks status, timing, proctoring data, and final score. |
| 2 | `lms_quiz_quest_attempt_answers` | Per-question response for a quiz/quest attempt. Supports all question types. Evaluation fields track grading. |
| 3 | `lms_quiz_quest_results` | Final published result after full evaluation. One row per attempt. Drives StudentPortal "My Results". |
| 4 | `lms_exam_attempts` | One row per student attempt at an exam paper (ONLINE or OFFLINE). Enforces one attempt per paper per student. |
| 5 | `lms_exam_attempt_answers` | Per-question response for an exam attempt. Used for ONLINE mode and OFFLINE QUESTION_WISE mode. |
| 6 | `lms_exam_marks_entry` | Bulk total marks entry by teacher for OFFLINE exams in BULK_TOTAL mode. |
| 7 | `lms_exam_results` | Final consolidated exam result. Drives StudentPortal results view and HPC integration. |
| 8 | `lms_exam_grievances` | Student re-evaluation requests on published results. Tracks review workflow and mark revisions. |
| 9 | `lms_attempt_activity_logs` | Append-only proctoring/behavioral event log. Covers QUIZ, QUEST, and EXAM attempt types. |
| 10 | `lms_attempt_checkpoints` | UPSERT save-state for in-progress attempts. Enables resume after browser crash or network loss. |

#### Relationships

```
std_students (1)
    ├──< lms_quiz_quest_attempts (M) — student takes multiple quiz/quest attempts
    │        ├──< lms_quiz_quest_attempt_answers (M) — one answer per question per attempt
    │        └── lms_quiz_quest_results (1) — one result per attempt (after evaluation)
    │
    ├──< lms_exam_attempts (M) — one per paper per student (UNIQUE enforced)
    │        ├──< lms_exam_attempt_answers (M) — one answer per question per attempt
    │        ├── lms_exam_marks_entry (1) — only for OFFLINE BULK_TOTAL mode
    │        └── lms_exam_results (1) — final result per paper per student
    │                 └──< lms_exam_grievances (M) — student raises grievances on result
    │
lms_attempt_activity_logs (polymorphic on attempt_type+attempt_id)
lms_attempt_checkpoints (polymorphic on attempt_type+attempt_id)

lms_quiz_quest_attempts links to:
    lms_quizzes (QUIZ type)     via quiz_id
    lms_quests  (QUEST type)    via quest_id
    lms_quiz_allocations        via quiz_allocation_id
    lms_quest_allocations       via quest_allocation_id

lms_exam_attempts links to:
    lms_exam_papers             via exam_paper_id
    lms_exam_paper_sets         via paper_set_id
    lms_exam_allocations        via allocation_id

lms_exam_results links to:
    lms_exams                   via exam_id (denormalized)
    lms_exam_papers             via exam_paper_id
    lms_exam_attempts           via attempt_id
```

**Polymorphic relationships:**
- `lms_attempt_activity_logs`: `(attempt_type ENUM + attempt_id INT)` → points to `lms_quiz_quest_attempts` OR `lms_exam_attempts`
- `lms_attempt_checkpoints`: same pattern as activity logs

**Self-referencing:** None.

---

### 2.2 Migration Instructions

#### Migration Execution Order (dependency tree)

```
Phase 1 — No internal deps (can run in any order):
  1.  create_lms_quiz_quest_attempts_table
  2.  create_lms_exam_attempts_table

Phase 2 — Depends on Phase 1:
  3.  create_lms_quiz_quest_attempt_answers_table  (needs lms_quiz_quest_attempts)
  4.  create_lms_quiz_quest_results_table          (needs lms_quiz_quest_attempts)
  5.  create_lms_exam_attempt_answers_table        (needs lms_exam_attempts)
  6.  create_lms_exam_marks_entry_table            (needs lms_exam_attempts)

Phase 3 — Depends on Phase 1 + 2:
  7.  create_lms_exam_results_table                (needs lms_exams, lms_exam_papers, lms_exam_attempts)

Phase 4 — Depends on Phase 3:
  8.  create_lms_exam_grievances_table             (needs lms_exam_results)

Phase 5 — No internal deps (polymorphic):
  9.  create_lms_attempt_activity_logs_table
  10. create_lms_attempt_checkpoints_table
```

#### Table 1: `lms_quiz_quest_attempts`

**Migration file:** `2026_04_02_100000_create_lms_quiz_quest_attempts_table.php`

```php
Schema::create('lms_quiz_quest_attempts', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('student_id');
    $table->enum('assessment_type', ['QUIZ', 'QUEST']);
    $table->unsignedBigInteger('quiz_id')->nullable();
    $table->unsignedBigInteger('quest_id')->nullable();
    $table->unsignedBigInteger('quiz_allocation_id')->nullable();
    $table->unsignedBigInteger('quest_allocation_id')->nullable();
    $table->unsignedTinyInteger('attempt_number')->default(1);
    $table->dateTime('started_at')->nullable();
    $table->dateTime('submitted_at')->nullable();
    $table->dateTime('auto_submitted_at')->nullable();
    $table->unsignedInteger('time_taken_seconds')->default(0);
    $table->enum('status', ['NOT_STARTED','IN_PROGRESS','SUBMITTED','TIMEOUT','ABANDONED','CANCELLED','REASSIGNED'])->default('NOT_STARTED');
    $table->decimal('score_obtained', 8, 2)->nullable();
    $table->decimal('max_score', 8, 2)->nullable();
    $table->decimal('percentage', 5, 2)->nullable();
    $table->tinyInteger('is_passed')->nullable();
    $table->text('teacher_feedback')->nullable();
    $table->string('ip_address', 45)->nullable();
    $table->text('browser_agent')->nullable();
    $table->json('device_info')->nullable();
    $table->unsignedInteger('violation_count')->default(0);
    $table->tinyInteger('is_active')->default(1);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->primary('id');
    // Two separate UNIQUEs — MySQL NULLs are not equal so quest rows (quiz_id=NULL)
    // are automatically excluded from the quiz UNIQUE and vice versa.
    $table->unique(['student_id', 'quiz_id',  'attempt_number'], 'uq_qqat_student_quiz_attempt');
    $table->unique(['student_id', 'quest_id', 'attempt_number'], 'uq_qqat_student_quest_attempt');
    $table->index(['student_id'], 'idx_qqat_student');
    $table->index(['assessment_type', 'quiz_id'], 'idx_qqat_quiz');
    $table->index(['assessment_type', 'quest_id'], 'idx_qqat_quest');
    $table->index('quiz_allocation_id', 'idx_qqat_quiz_alloc');
    $table->index('quest_allocation_id', 'idx_qqat_quest_alloc');
    $table->index('status', 'idx_qqat_status');
    $table->index('is_active', 'idx_qqat_is_active');

    $table->foreign('student_id')->references('id')->on('std_students')->onDelete('restrict');
    $table->foreign('quiz_id')->references('id')->on('lms_quizzes')->onDelete('restrict');
    $table->foreign('quest_id')->references('id')->on('lms_quests')->onDelete('restrict');
    $table->foreign('quiz_allocation_id')->references('id')->on('lms_quiz_allocations')->onDelete('set null');
    $table->foreign('quest_allocation_id')->references('id')->on('lms_quest_allocations')->onDelete('set null');
});
```

#### Table 2: `lms_quiz_quest_attempt_answers`

**Migration file:** `2026_04_02_100100_create_lms_quiz_quest_attempt_answers_table.php`

```php
Schema::create('lms_quiz_quest_attempt_answers', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('attempt_id');
    $table->unsignedBigInteger('question_id');
    $table->unsignedBigInteger('question_type_id')->nullable();
    $table->unsignedBigInteger('selected_option_id')->nullable();
    $table->json('selected_option_ids')->nullable();
    $table->text('answer_text')->nullable();
    $table->unsignedBigInteger('attachment_id')->nullable();
    $table->decimal('marks_obtained', 5, 2)->default(0.00);
    $table->decimal('max_marks', 5, 2)->nullable();
    $table->tinyInteger('is_correct')->nullable();
    $table->tinyInteger('is_evaluated')->default(0);
    $table->unsignedBigInteger('evaluated_by')->nullable();
    $table->string('evaluation_remarks', 255)->nullable();
    $table->dateTime('evaluated_at')->nullable();
    $table->unsignedInteger('time_spent_seconds')->default(0);
    $table->unsignedSmallInteger('change_count')->default(0);
    $table->tinyInteger('is_active')->default(1);
    $table->timestamps();
    $table->softDeletes();

    $table->unique(['attempt_id', 'question_id'], 'uq_qqans_attempt_question');
    $table->index('attempt_id', 'idx_qqans_attempt');
    $table->index('question_id', 'idx_qqans_question');
    $table->index('is_evaluated', 'idx_qqans_is_evaluated');

    $table->foreign('attempt_id')->references('id')->on('lms_quiz_quest_attempts')->onDelete('cascade');
    $table->foreign('question_id')->references('id')->on('qns_questions_bank')->onDelete('restrict');
    $table->foreign('selected_option_id')->references('id')->on('qns_question_options')->onDelete('set null');
    $table->foreign('evaluated_by')->references('id')->on('sys_users')->onDelete('set null');
});
```

#### Table 3: `lms_quiz_quest_results`

**Migration file:** `2026_04_02_100200_create_lms_quiz_quest_results_table.php`

```php
Schema::create('lms_quiz_quest_results', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('attempt_id');
    $table->unsignedBigInteger('student_id');
    $table->enum('assessment_type', ['QUIZ', 'QUEST']);
    $table->unsignedBigInteger('assessment_id');   // Cached polymorphic reference
    $table->decimal('total_marks_obtained', 8, 2)->default(0.00);
    $table->decimal('max_marks', 8, 2)->default(0.00);
    $table->decimal('percentage', 5, 2)->default(0.00);
    $table->string('grade_obtained', 10)->nullable();
    $table->tinyInteger('is_passed')->default(0);
    $table->unsignedInteger('rank_in_class')->nullable();
    $table->decimal('percentile', 5, 2)->nullable();
    $table->tinyInteger('is_published')->default(0);
    $table->dateTime('published_at')->nullable();
    $table->text('teacher_remarks')->nullable();
    $table->tinyInteger('is_active')->default(1);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->unique('attempt_id', 'uq_qqres_attempt');
    $table->index('student_id', 'idx_qqres_student');
    $table->index(['assessment_type', 'assessment_id'], 'idx_qqres_assessment');
    $table->index('is_published', 'idx_qqres_is_published');

    $table->foreign('attempt_id')->references('id')->on('lms_quiz_quest_attempts')->onDelete('cascade');
    $table->foreign('student_id')->references('id')->on('std_students')->onDelete('restrict');
});
```

#### Table 4: `lms_exam_attempts`

**Migration file:** `2026_04_02_100300_create_lms_exam_attempts_table.php`

```php
Schema::create('lms_exam_attempts', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('exam_paper_id');
    $table->unsignedBigInteger('paper_set_id');
    $table->unsignedBigInteger('allocation_id')->nullable();
    $table->unsignedBigInteger('student_id');
    $table->enum('attempt_mode', ['ONLINE', 'OFFLINE'])->default('ONLINE');
    $table->dateTime('actual_started_time')->nullable();
    $table->dateTime('actual_end_time')->nullable();
    $table->unsignedInteger('actual_time_taken_seconds')->default(0);
    $table->enum('status', ['NOT_STARTED','IN_PROGRESS','SUBMITTED','EVALUATION_PENDING','EVALUATED','RESULT_PUBLISHED','ABSENT','CANCELLED'])->default('NOT_STARTED');
    $table->tinyInteger('is_present_offline')->default(1);
    $table->string('answer_sheet_number', 50)->nullable();
    $table->unsignedBigInteger('offline_paper_uploaded_id')->nullable();
    $table->string('ip_address', 45)->nullable();
    $table->text('browser_agent')->nullable();
    $table->json('device_info')->nullable();
    $table->unsignedInteger('violation_count')->default(0);
    $table->tinyInteger('is_active')->default(1);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->unique(['exam_paper_id', 'student_id'], 'uq_exatt_paper_student');
    $table->index('student_id', 'idx_exatt_student');
    $table->index('exam_paper_id', 'idx_exatt_paper');
    $table->index('paper_set_id', 'idx_exatt_set');
    $table->index('allocation_id', 'idx_exatt_allocation');
    $table->index('status', 'idx_exatt_status');

    $table->foreign('exam_paper_id')->references('id')->on('lms_exam_papers')->onDelete('restrict');
    $table->foreign('paper_set_id')->references('id')->on('lms_exam_paper_sets')->onDelete('restrict');
    $table->foreign('student_id')->references('id')->on('std_students')->onDelete('restrict');
    $table->foreign('allocation_id')->references('id')->on('lms_exam_allocations')->onDelete('set null');
});
```

#### Table 5: `lms_exam_attempt_answers`

**Migration file:** `2026_04_02_100400_create_lms_exam_attempt_answers_table.php`

```php
Schema::create('lms_exam_attempt_answers', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('attempt_id');
    $table->unsignedBigInteger('question_id');
    $table->unsignedBigInteger('question_type_id')->nullable();
    $table->unsignedBigInteger('selected_option_id')->nullable();
    $table->json('selected_option_ids')->nullable();
    $table->text('descriptive_answer')->nullable();
    $table->unsignedBigInteger('attachment_id')->nullable();
    $table->decimal('marks_obtained', 5, 2)->default(0.00);
    $table->decimal('max_marks', 5, 2)->nullable();
    $table->tinyInteger('is_correct')->nullable();
    $table->tinyInteger('is_evaluated')->default(0);
    $table->unsignedBigInteger('evaluated_by')->nullable();
    $table->text('evaluation_remarks')->nullable();
    $table->dateTime('evaluated_at')->nullable();
    $table->unsignedInteger('time_spent_seconds')->default(0);
    $table->unsignedSmallInteger('change_count')->default(0);
    $table->tinyInteger('is_active')->default(1);
    $table->timestamps();
    $table->softDeletes();

    $table->unique(['attempt_id', 'question_id'], 'uq_exans_attempt_question');
    $table->index('attempt_id', 'idx_exans_attempt');
    $table->index('question_id', 'idx_exans_question');
    $table->index('is_evaluated', 'idx_exans_is_evaluated');

    $table->foreign('attempt_id')->references('id')->on('lms_exam_attempts')->onDelete('cascade');
    $table->foreign('question_id')->references('id')->on('qns_questions_bank')->onDelete('restrict');
    $table->foreign('selected_option_id')->references('id')->on('qns_question_options')->onDelete('set null');
    $table->foreign('evaluated_by')->references('id')->on('sys_users')->onDelete('set null');
});
```

#### Table 6: `lms_exam_marks_entry`

**Migration file:** `2026_04_02_100500_create_lms_exam_marks_entry_table.php`

```php
Schema::create('lms_exam_marks_entry', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('attempt_id');
    $table->decimal('total_marks_obtained', 8, 2)->default(0.00);
    $table->string('remarks', 255)->nullable();
    $table->unsignedBigInteger('entered_by');
    $table->dateTime('entered_at')->useCurrent();
    $table->tinyInteger('is_active')->default(1);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->unique('attempt_id', 'uq_exme_attempt');
    $table->index('entered_by', 'idx_exme_entered_by');

    $table->foreign('attempt_id')->references('id')->on('lms_exam_attempts')->onDelete('cascade');
    $table->foreign('entered_by')->references('id')->on('sys_users')->onDelete('restrict');
});
```

#### Table 7: `lms_exam_results`

**Migration file:** `2026_04_02_100600_create_lms_exam_results_table.php`

```php
Schema::create('lms_exam_results', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('exam_id');
    $table->unsignedBigInteger('exam_paper_id');
    $table->unsignedBigInteger('student_id');
    $table->unsignedBigInteger('attempt_id')->nullable();
    $table->decimal('total_marks_possible', 8, 2)->default(0.00);
    $table->decimal('total_marks_obtained', 8, 2)->default(0.00);
    $table->decimal('percentage', 5, 2)->default(0.00);
    $table->string('grade_obtained', 10)->nullable();
    $table->string('division', 20)->nullable();
    $table->enum('result_status', ['PASS','FAIL','ABSENT','WITHHELD'])->default('PASS');
    $table->unsignedInteger('rank_in_class')->nullable();
    $table->decimal('percentile', 5, 2)->nullable();
    $table->tinyInteger('is_published')->default(0);
    $table->dateTime('published_at')->nullable();
    $table->text('teacher_remarks')->nullable();
    $table->string('report_card_path', 500)->nullable();
    $table->tinyInteger('is_active')->default(1);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->unique(['exam_paper_id', 'student_id'], 'uq_exres_paper_student');
    $table->index('exam_id', 'idx_exres_exam');
    $table->index('student_id', 'idx_exres_student');
    $table->index('attempt_id', 'idx_exres_attempt');
    $table->index('is_published', 'idx_exres_is_published');
    $table->index('result_status', 'idx_exres_result_status');

    $table->foreign('exam_id')->references('id')->on('lms_exams')->onDelete('restrict');
    $table->foreign('exam_paper_id')->references('id')->on('lms_exam_papers')->onDelete('restrict');
    $table->foreign('student_id')->references('id')->on('std_students')->onDelete('restrict');
    $table->foreign('attempt_id')->references('id')->on('lms_exam_attempts')->onDelete('set null');
});
```

#### Table 8: `lms_exam_grievances`

**Migration file:** `2026_04_02_100700_create_lms_exam_grievances_table.php`

```php
Schema::create('lms_exam_grievances', function (Blueprint $table) {
    $table->id();
    $table->unsignedBigInteger('exam_result_id');
    $table->unsignedBigInteger('student_id');
    $table->unsignedBigInteger('question_id')->nullable();
    $table->enum('grievance_type', ['MARKING_ERROR','QUESTION_ERROR','OUT_OF_SYLLABUS','OTHER'])->default('OTHER');
    $table->text('grievance_text');
    $table->enum('status', ['OPEN','UNDER_REVIEW','RESOLVED','REJECTED'])->default('OPEN');
    $table->unsignedBigInteger('reviewer_id')->nullable();
    $table->text('resolution_remarks')->nullable();
    $table->dateTime('resolved_at')->nullable();
    $table->tinyInteger('marks_changed')->default(0);
    $table->decimal('old_marks', 5, 2)->nullable();
    $table->decimal('new_marks', 5, 2)->nullable();
    $table->tinyInteger('is_active')->default(1);
    $table->unsignedBigInteger('created_by')->nullable();
    $table->timestamps();
    $table->softDeletes();

    $table->index('exam_result_id', 'idx_exgrv_result');
    $table->index('student_id', 'idx_exgrv_student');
    $table->index('status', 'idx_exgrv_status');

    $table->foreign('exam_result_id')->references('id')->on('lms_exam_results')->onDelete('cascade');
    $table->foreign('student_id')->references('id')->on('std_students')->onDelete('restrict');
    $table->foreign('question_id')->references('id')->on('qns_questions_bank')->onDelete('set null');
    $table->foreign('reviewer_id')->references('id')->on('sys_users')->onDelete('set null');
});
```

#### Table 9: `lms_attempt_activity_logs`

**Migration file:** `2026_04_02_100800_create_lms_attempt_activity_logs_table.php`

```php
Schema::create('lms_attempt_activity_logs', function (Blueprint $table) {
    $table->id();
    $table->enum('attempt_type', ['QUIZ', 'QUEST', 'EXAM']);
    $table->unsignedBigInteger('attempt_id');
    $table->enum('event_type', [
        'FOCUS_LOST','FULLSCREEN_EXIT','BROWSER_RESIZE','KEY_PRESS_BLOCKED',
        'MOUSE_LEAVE','IP_CHANGE','TAB_SWITCH','COPY_PASTE_DETECTED',
        'CONTEXT_MENU_OPENED','DEVTOOLS_DETECTED','WINDOW_BLUR','NETWORK_DISCONNECT'
    ]);
    $table->json('event_data')->nullable();
    $table->dateTime('occurred_at')->useCurrent();
    $table->tinyInteger('is_active')->default(1);
    $table->timestamps();
    // No softDeletes — immutable audit log

    $table->index(['attempt_type', 'attempt_id'], 'idx_aal_attempt');
    $table->index('event_type', 'idx_aal_event_type');
    $table->index('occurred_at', 'idx_aal_occurred_at');
    // No FK — polymorphic reference
});
```

#### Table 10: `lms_attempt_checkpoints`

**Migration file:** `2026_04_02_100900_create_lms_attempt_checkpoints_table.php`

```php
Schema::create('lms_attempt_checkpoints', function (Blueprint $table) {
    $table->id();
    $table->enum('attempt_type', ['QUIZ', 'QUEST', 'EXAM']);
    $table->unsignedBigInteger('attempt_id');
    $table->unsignedSmallInteger('current_question_idx')->default(0);
    $table->unsignedBigInteger('last_question_id')->nullable();
    $table->json('answered_question_ids')->nullable();
    $table->json('flagged_question_ids')->nullable();
    $table->json('checkpoint_data')->nullable();
    $table->dateTime('saved_at')->useCurrent();
    $table->tinyInteger('is_active')->default(1);
    $table->timestamps();
    // No softDeletes — ephemeral, deleted on submission

    $table->unique(['attempt_type', 'attempt_id'], 'uq_chk_attempt');
    $table->index(['attempt_type', 'attempt_id'], 'idx_chk_attempt');
});
```

---

### 2.3 Seeder & Factory Requirements

#### Seeders Needed

No master/lookup data in these tables — all rows are generated at runtime by students taking assessments. **No seeders required.**

#### Factories Needed (for testing)

| Factory | Key Faker Rules |
|---|---|
| `QuizQuestAttemptFactory` | `assessment_type` random QUIZ/QUEST, `status` random, `attempt_number` 1-3, `score_obtained` 0-100, realistic `started_at`/`submitted_at` diff |
| `QuizQuestAttemptAnswerFactory` | `marks_obtained` 0-`max_marks`, `is_correct` random 0/1/null, `time_spent_seconds` 10-300 |
| `QuizQuestResultFactory` | `percentage` computed from marks, `is_passed` based on percentage ≥ 40 |
| `ExamAttemptFactory` | `attempt_mode` random ONLINE/OFFLINE, `status` random, realistic timing |
| `ExamAttemptAnswerFactory` | Same pattern as quiz/quest answer factory |
| `ExamMarksEntryFactory` | `total_marks_obtained` 0-100, `entered_by` a teacher user ID |
| `ExamResultFactory` | `result_status` weighted (60% PASS), `is_published` random |
| `ExamGrievanceFactory` | `status` OPEN by default, `grievance_type` random |
| `AttemptActivityLogFactory` | `event_type` random from enum, `occurred_at` during attempt window |
| `AttemptCheckpointFactory` | `current_question_idx` 0-20, `checkpoint_data` minimal JSON |

---

### ⚠️ GAPS & WARNINGS

| Gap | Description | Impact | Recommendation |
|---|---|---|---|
| **G-01** | No `academic_year_id` or `academic_session_id` on attempt/result tables | Cannot filter results by academic year without joining through exam/quiz chain | 📐 Add `academic_session_id` to `lms_exam_results` and `lms_quiz_quest_results` for direct scoping |
| **G-02** | `lms_quiz_quest_results.assessment_id` is polymorphic (no FK constraint) | Referential integrity not enforced at DB level | Accept as design trade-off; enforce in application layer |
| **G-03** | `lms_attempt_checkpoints` has no FK on `attempt_id` (polymorphic) | Stale checkpoints if attempt is deleted | Application must delete checkpoint when attempt is submitted/deleted |
| **G-04** | `lms_exam_results` does not have `academic_session_id` directly | HPC module needs session-scoped results | 📐 Add denormalized `academic_session_id` or join via `lms_exams` |
| **G-05** | MRD FR-STP-17 requires results with marks — currently `lms_exam_results` exists but no controller/service reads it yet | Portal results page shows no marks | Next implementation phase must wire `ExamResultService` to the results view |
| ~~**G-06**~~ | ~~`lms_quiz_quest_attempts` UNIQUE key and two indexes referenced non-existent `assessment_id`/`allocation_id` columns (v3 uses `quiz_id`/`quest_id`)~~ | ~~Migration would fail on UNIQUE key~~ | ✅ **FIXED in v3 DDL (2026-04-02):** Replaced broken `uq_qqat_student_assessment_attempt(assessment_id)` with two separate UNIQUEs — `uq_qqat_student_quiz_attempt(student_id, quiz_id, attempt_number)` + `uq_qqat_student_quest_attempt(student_id, quest_id, attempt_number)`. Fixed `idx_qqat_assessment` and `idx_qqat_allocation` to reference explicit columns. Fixed `ConSTRAINT` typo. |
| **G-07** | No `homework` attempt tracking in this schema | MRD FR-STP-16 requires homework submission — handled by `lms_homework_submissions` in LmsHomework module | Ensure `HomeworkSubmission` model is accessible from StudentPortal controller |

---

## SECTION 3: MODEL LAYER GUIDE

### 3.1 Model: `QuizQuestAttempt`

**File:** `Modules/StudentPortal/app/Models/QuizQuestAttempt.php`

```php
class QuizQuestAttempt extends Model
{
    use SoftDeletes, HasFactory;

    protected $table = 'lms_quiz_quest_attempts';
    protected $primaryKey = 'id';

    protected $fillable = [
        'student_id', 'assessment_type', 'quiz_id', 'quest_id',
        'quiz_allocation_id', 'quest_allocation_id', 'attempt_number',
        'started_at', 'submitted_at', 'auto_submitted_at', 'time_taken_seconds',
        'status', 'score_obtained', 'max_score', 'percentage', 'is_passed',
        'teacher_feedback', 'ip_address', 'browser_agent', 'device_info',
        'violation_count', 'is_active', 'created_by',
    ];

    protected $casts = [
        'device_info'        => 'array',
        'started_at'         => 'datetime',
        'submitted_at'       => 'datetime',
        'auto_submitted_at'  => 'datetime',
        'score_obtained'     => 'decimal:2',
        'max_score'          => 'decimal:2',
        'percentage'         => 'decimal:2',
        'is_passed'          => 'boolean',
        'is_active'          => 'boolean',
        'violation_count'    => 'integer',
    ];
}
```

**Relationships:**

```php
// Belongs to
public function student(): BelongsTo
{
    return $this->belongsTo(\App\Models\Student::class, 'student_id', 'id');
}

public function quiz(): BelongsTo
{
    return $this->belongsTo(\Modules\LmsQuiz\Models\Quiz::class, 'quiz_id', 'id');
}

public function quest(): BelongsTo
{
    return $this->belongsTo(\Modules\LmsQuests\Models\Quest::class, 'quest_id', 'id');
}

public function quizAllocation(): BelongsTo
{
    return $this->belongsTo(\Modules\LmsQuiz\Models\QuizAllocation::class, 'quiz_allocation_id', 'id');
}

public function questAllocation(): BelongsTo
{
    return $this->belongsTo(\Modules\LmsQuests\Models\QuestAllocation::class, 'quest_allocation_id', 'id');
}

// Has many
public function answers(): HasMany
{
    return $this->hasMany(QuizQuestAttemptAnswer::class, 'attempt_id', 'id');
}

// Has one
public function result(): HasOne
{
    return $this->hasOne(QuizQuestResult::class, 'attempt_id', 'id');
}
```

**Scopes:**

```php
public function scopeActive(Builder $query): Builder
{
    return $query->where('is_active', 1)->whereNull('deleted_at');
}

public function scopeForStudent(Builder $query, int $studentId): Builder
{
    return $query->where('student_id', $studentId);
}

public function scopeByStatus(Builder $query, string $status): Builder
{
    return $query->where('status', $status);
}

public function scopeQuiz(Builder $query): Builder
{
    return $query->where('assessment_type', 'QUIZ');
}

public function scopeQuest(Builder $query): Builder
{
    return $query->where('assessment_type', 'QUEST');
}

public function scopePublishedResults(Builder $query): Builder
{
    return $query->whereHas('result', fn($q) => $q->where('is_published', 1));
}
```

**Accessors:**

```php
// Returns the assessment model (Quiz or Quest) dynamically
public function getAssessmentAttribute()
{
    return $this->assessment_type === 'QUIZ' ? $this->quiz : $this->quest;
}

// Returns the allocation model dynamically
public function getAllocationAttribute()
{
    return $this->assessment_type === 'QUIZ' ? $this->quizAllocation : $this->questAllocation;
}

// Returns human-readable status label
public function getStatusLabelAttribute(): string
{
    return match($this->status) {
        'NOT_STARTED'  => 'Not Started',
        'IN_PROGRESS'  => 'In Progress',
        'SUBMITTED'    => 'Submitted',
        'TIMEOUT'      => 'Timed Out',
        'ABANDONED'    => 'Abandoned',
        'CANCELLED'    => 'Cancelled',
        'REASSIGNED'   => 'Reassigned',
        default        => $this->status,
    };
}
```

**Observer/Events:**

```php
// AttemptObserver
public function creating(QuizQuestAttempt $attempt): void
{
    $attempt->created_by = auth()->id();
    // Auto-increment attempt_number
    $max = QuizQuestAttempt::where('student_id', $attempt->student_id)
        ->where('assessment_type', $attempt->assessment_type)
        ->where('quiz_id', $attempt->quiz_id)
        ->where('quest_id', $attempt->quest_id)
        ->max('attempt_number');
    $attempt->attempt_number = ($max ?? 0) + 1;
}
```

---

### 3.2 Model: `QuizQuestAttemptAnswer`

**File:** `Modules/StudentPortal/app/Models/QuizQuestAttemptAnswer.php`

```php
protected $table   = 'lms_quiz_quest_attempt_answers';
protected $fillable = [
    'attempt_id', 'question_id', 'question_type_id',
    'selected_option_id', 'selected_option_ids', 'answer_text', 'attachment_id',
    'marks_obtained', 'max_marks', 'is_correct', 'is_evaluated',
    'evaluated_by', 'evaluation_remarks', 'evaluated_at',
    'time_spent_seconds', 'change_count', 'is_active',
];
protected $casts = [
    'selected_option_ids' => 'array',
    'marks_obtained'      => 'decimal:2',
    'max_marks'           => 'decimal:2',
    'is_correct'          => 'boolean',    // Note: nullable boolean
    'is_evaluated'        => 'boolean',
    'is_active'           => 'boolean',
    'evaluated_at'        => 'datetime',
];
```

**Relationships:**
```php
public function attempt(): BelongsTo  // → QuizQuestAttempt
public function question(): BelongsTo // → \Modules\QuestionBank\Models\QuestionBank
public function selectedOption(): BelongsTo // → \Modules\QuestionBank\Models\QuestionOption
public function evaluator(): BelongsTo  // → \App\Models\User (sys_users)
```

**Scopes:**
```php
public function scopePending(Builder $query): Builder    // is_evaluated = 0
public function scopeEvaluated(Builder $query): Builder  // is_evaluated = 1
```

---

### 3.3 Model: `QuizQuestResult`

**File:** `Modules/StudentPortal/app/Models/QuizQuestResult.php`

```php
protected $table   = 'lms_quiz_quest_results';
protected $casts   = [
    'total_marks_obtained' => 'decimal:2',
    'max_marks'            => 'decimal:2',
    'percentage'           => 'decimal:2',
    'percentile'           => 'decimal:2',
    'is_passed'            => 'boolean',
    'is_published'         => 'boolean',
    'published_at'         => 'datetime',
    'is_active'            => 'boolean',
];
```

**Relationships:**
```php
public function attempt(): BelongsTo  // → QuizQuestAttempt
public function student(): BelongsTo  // → Student
```

**Scopes:**
```php
public function scopePublished(Builder $query): Builder   // is_published = 1
public function scopeForStudent(Builder $query, int $id): Builder
public function scopeQuiz(Builder $query): Builder        // assessment_type = QUIZ
public function scopeQuest(Builder $query): Builder       // assessment_type = QUEST
```

---

### 3.4 Model: `ExamAttempt`

**File:** `Modules/StudentPortal/app/Models/ExamAttempt.php`

```php
protected $table   = 'lms_exam_attempts';
protected $casts   = [
    'device_info'               => 'array',
    'actual_started_time'       => 'datetime',
    'actual_end_time'           => 'datetime',
    'is_present_offline'        => 'boolean',
    'is_active'                 => 'boolean',
    'violation_count'           => 'integer',
    'actual_time_taken_seconds' => 'integer',
];
```

**Relationships:**
```php
public function examPaper(): BelongsTo           // → \Modules\LmsExam\Models\ExamPaper
public function paperSet(): BelongsTo            // → \Modules\LmsExam\Models\ExamPaperSet
public function allocation(): BelongsTo          // → \Modules\LmsExam\Models\ExamAllocation
public function student(): BelongsTo             // → Student
public function answers(): HasMany               // → ExamAttemptAnswer
public function marksEntry(): HasOne             // → ExamMarksEntry
public function result(): HasOne                 // → ExamResult (via exam_paper_id+student_id)
```

**Scopes:**
```php
public function scopeOnline(Builder $query): Builder
public function scopeOffline(Builder $query): Builder
public function scopeByStatus(Builder $query, string $status): Builder
public function scopeForStudent(Builder $query, int $id): Builder
```

---

### 3.5 Model: `ExamAttemptAnswer`

**File:** `Modules/StudentPortal/app/Models/ExamAttemptAnswer.php`

```php
protected $table   = 'lms_exam_attempt_answers';
// Casts, fillable identical pattern to QuizQuestAttemptAnswer
// Relationships: attempt → ExamAttempt, question, selectedOption, evaluator
```

---

### 3.6 Model: `ExamMarksEntry`

**File:** `Modules/StudentPortal/app/Models/ExamMarksEntry.php`

```php
protected $table   = 'lms_exam_marks_entry';
protected $casts   = [
    'total_marks_obtained' => 'decimal:2',
    'entered_at'           => 'datetime',
    'is_active'            => 'boolean',
];
// Relationships: attempt → ExamAttempt, enterer → User
```

---

### 3.7 Model: `ExamResult`

**File:** `Modules/StudentPortal/app/Models/ExamResult.php`

```php
protected $table   = 'lms_exam_results';
protected $casts   = [
    'total_marks_possible' => 'decimal:2',
    'total_marks_obtained' => 'decimal:2',
    'percentage'           => 'decimal:2',
    'percentile'           => 'decimal:2',
    'is_published'         => 'boolean',
    'published_at'         => 'datetime',
    'result_status'        => ResultStatus::class,  // 📐 Backed enum
    'is_active'            => 'boolean',
];
```

**Relationships:**
```php
public function exam(): BelongsTo         // → \Modules\LmsExam\Models\Exam
public function examPaper(): BelongsTo    // → \Modules\LmsExam\Models\ExamPaper
public function student(): BelongsTo      // → Student
public function attempt(): BelongsTo      // → ExamAttempt (nullable)
public function grievances(): HasMany     // → ExamGrievance
```

**Scopes:**
```php
public function scopePublished(Builder $query): Builder
public function scopeForStudent(Builder $query, int $id): Builder
public function scopeForExam(Builder $query, int $examId): Builder
public function scopePassed(Builder $query): Builder   // result_status = PASS
public function scopeFailed(Builder $query): Builder   // result_status = FAIL
```

---

### 3.8 Model: `ExamGrievance`

**File:** `Modules/StudentPortal/app/Models/ExamGrievance.php`

```php
protected $table   = 'lms_exam_grievances';
// Relationships: examResult, student, question, reviewer
// Scopes: scopeOpen, scopeUnderReview, scopeResolved, scopeRejected
```

---

### 3.9 Model: `AttemptActivityLog`

**File:** `Modules/StudentPortal/app/Models/AttemptActivityLog.php`

```php
protected $table    = 'lms_attempt_activity_logs';
// No SoftDeletes trait — immutable
protected $casts    = [
    'event_data'  => 'array',
    'occurred_at' => 'datetime',
    'is_active'   => 'boolean',
];
// No FK relationships — polymorphic; use morphTo pattern or manual resolution
```

---

### 3.10 Model: `AttemptCheckpoint`

**File:** `Modules/StudentPortal/app/Models/AttemptCheckpoint.php`

```php
protected $table    = 'lms_attempt_checkpoints';
// No SoftDeletes — ephemeral
protected $casts    = [
    'answered_question_ids' => 'array',
    'flagged_question_ids'  => 'array',
    'checkpoint_data'       => 'array',
    'saved_at'              => 'datetime',
    'is_active'             => 'boolean',
];
```

---

## SECTION 4: BUSINESS LOGIC LAYER

### 4.1 Service Classes

#### `QuizQuestAttemptService`

**File:** `Modules/StudentPortal/app/Services/QuizQuestAttemptService.php`

| Method | Signature | Description |
|---|---|---|
| `startAttempt` | `startAttempt(Student $student, string $type, int $assessmentId, int $allocationId): QuizQuestAttempt` | Creates attempt record, validates max_attempts not exceeded, sets status=IN_PROGRESS, logs device info |
| `saveAnswer` | `saveAnswer(int $attemptId, int $questionId, array $response, int $timeSpent): QuizQuestAttemptAnswer` | Upserts answer row (UPDATE if exists), increments change_count, updates checkpoint |
| `submitAttempt` | `submitAttempt(int $attemptId): QuizQuestAttempt` | Sets status=SUBMITTED, sets submitted_at, calculates time_taken_seconds, triggers auto-evaluation for MCQ |
| `autoSubmitOnTimeout` | `autoSubmitOnTimeout(int $attemptId): void` | Called by scheduler; sets status=TIMEOUT, auto_submitted_at=now(), triggers evaluation |
| `autoEvaluateMcq` | `autoEvaluateMcq(int $attemptId): void` | Loops answers, checks selected_option_id/ids against correct options, sets is_correct, marks_obtained, is_evaluated=1 |
| `computeResult` | `computeResult(int $attemptId): QuizQuestResult` | Sums marks, calculates percentage, determines is_passed vs passing_percentage, creates/updates result record |
| `publishResult` | `publishResult(int $resultId): QuizQuestResult` | Sets is_published=1, published_at=now(), dispatches ResultPublishedEvent |
| `abandonAttempt` | `abandonAttempt(int $attemptId): void` | Sets status=ABANDONED; called when student explicitly exits |

**Business Rules enforced:**
- `BR-QQ-01`: Cannot start new attempt if `attempt_number > allow_multiple_attempts.max_attempts` — throws `AttemptLimitExceededException`
- `BR-QQ-02`: Cannot submit an attempt not in IN_PROGRESS status
- `BR-QQ-03`: Only MCQ answers are auto-evaluated; descriptive answers remain is_evaluated=0 (require teacher review)
- `BR-QQ-04`: Scoring — for negative marking: `marks_obtained = is_correct ? max_marks : -negative_marks`
- `BR-QQ-05`: `computeResult` is idempotent — safe to call multiple times (uses updateOrCreate)

---

#### `ExamAttemptService`

**File:** `Modules/StudentPortal/app/Services/ExamAttemptService.php`

| Method | Signature | Description |
|---|---|---|
| `startOnlineExam` | `startOnlineExam(Student $student, int $paperId, int $setId, int $allocationId, Request $request): ExamAttempt` | Creates attempt (ONLINE), validates allocation, records IP/device, sets status=IN_PROGRESS |
| `saveExamAnswer` | `saveExamAnswer(int $attemptId, int $questionId, array $response, int $timeSpent): ExamAttemptAnswer` | Upserts answer, updates checkpoint |
| `submitOnlineExam` | `submitOnlineExam(int $attemptId): ExamAttempt` | Sets status=SUBMITTED, calculates time, triggers MCQ auto-evaluation |
| `autoSubmitExpired` | `autoSubmitExpired(int $attemptId): void` | Scheduler-triggered; marks TIMEOUT and runs auto-eval |
| `recordOfflineAttempt` | `recordOfflineAttempt(int $paperId, int $studentId, array $data): ExamAttempt` | Creates OFFLINE attempt with is_present_offline and answer_sheet_number |
| `enterBulkMarks` | `enterBulkMarks(int $attemptId, float $marks, string $remarks, int $teacherId): ExamMarksEntry` | Creates/updates ExamMarksEntry, wraps in DB::transaction |
| `enterQuestionWiseMarks` | `enterQuestionWiseMarks(int $attemptId, array $answers, int $teacherId): void` | Bulk upserts answer marks for offline QUESTION_WISE mode |
| `generateResult` | `generateResult(int $attemptId): ExamResult` | Aggregates marks (from answers OR bulk entry), applies grading schema, creates ExamResult |
| `publishResult` | `publishResult(int $resultId): ExamResult` | Sets is_published=1, dispatches ExamResultPublishedEvent |
| `markAbsent` | `markAbsent(int $paperId, int $studentId): ExamAttempt` | Creates attempt with status=ABSENT |

**Business Rules enforced:**
- `BR-EX-01`: One attempt per paper per student (enforced by UNIQUE key; service catches `UniqueConstraintViolationException`)
- `BR-EX-02`: Online exam timer — `actual_end_time - actual_started_time` must not exceed `exam_paper.duration_minutes * 60`
- `BR-EX-03`: OFFLINE BULK_TOTAL — `total_marks_obtained` ≤ `exam_paper.total_marks`
- `BR-EX-04`: `generateResult` always wraps in `DB::transaction()` to ensure atomicity
- `BR-EX-05`: Published results cannot be un-published (guard in `publishResult`)
- `BR-EX-06`: `markAbsent` only allowed when attempt doesn't already exist for this student+paper

---

#### `GrievanceService`

**File:** `Modules/StudentPortal/app/Services/GrievanceService.php`

| Method | Signature | Description |
|---|---|---|
| `submitGrievance` | `submitGrievance(Student $student, int $resultId, array $data): ExamGrievance` | Validates result belongs to student, creates grievance with status=OPEN |
| `reviewGrievance` | `reviewGrievance(int $grievanceId, int $reviewerId, string $status, string $remarks): ExamGrievance` | Updates status, records resolver, sets resolved_at if RESOLVED/REJECTED |
| `adjustMarks` | `adjustMarks(int $grievanceId, float $newMarks): void` | Updates marks on `lms_exam_results`, sets marks_changed=1, old_marks, new_marks. Wraps in `DB::transaction()`. Dispatches MarksAdjustedEvent. |

**Business Rules:**
- `BR-GR-01`: Student can only raise grievance on their own result — validated via `student_id` ownership check
- `BR-GR-02`: Grievance can only be raised on a published result
- `BR-GR-03`: `adjustMarks` — `new_marks` must be ≤ `exam_paper.total_marks`; must be ≥ 0

---

#### `AttemptProctoringService`

**File:** `Modules/StudentPortal/app/Services/AttemptProctoringService.php`

| Method | Signature | Description |
|---|---|---|
| `logEvent` | `logEvent(string $type, int $attemptId, string $event, array $data): void` | Appends row to `lms_attempt_activity_logs` |
| `incrementViolation` | `incrementViolation(string $type, int $attemptId): int` | Increments violation_count on attempt, returns new count |
| `shouldAutoSubmit` | `shouldAutoSubmit(string $type, int $attemptId, int $maxViolations): bool` | Returns true if violation_count ≥ max threshold |

---

#### `CheckpointService`

**File:** `Modules/StudentPortal/app/Services/CheckpointService.php`

| Method | Signature | Description |
|---|---|---|
| `save` | `save(string $type, int $attemptId, array $state): AttemptCheckpoint` | UPSERT checkpoint row with current state snapshot |
| `restore` | `restore(string $type, int $attemptId): ?array` | Returns checkpoint_data JSON or null if no checkpoint |
| `clear` | `clear(string $type, int $attemptId): void` | Deletes checkpoint row on submission (hard delete — ephemeral) |

---

### 4.2 Business Rule Summary

| # | Rule | Where Enforced |
|---|---|---|
| BR-QQ-01 | Max attempts per quiz/quest per student | `QuizQuestAttemptService::startAttempt()` |
| BR-QQ-02 | Only IN_PROGRESS attempts can be submitted | `QuizQuestAttemptService::submitAttempt()` |
| BR-QQ-03 | MCQ auto-evaluated; descriptive requires teacher | `QuizQuestAttemptService::autoEvaluateMcq()` |
| BR-QQ-04 | Negative marking deducts marks for wrong MCQ | `QuizQuestAttemptService::autoEvaluateMcq()` |
| BR-EX-01 | One exam attempt per paper per student | DB UNIQUE + `ExamAttemptService::startOnlineExam()` |
| BR-EX-02 | Online exam respects duration_minutes | `ExamAttemptService::autoSubmitExpired()` (scheduler) |
| BR-EX-03 | Offline bulk marks ≤ total_marks | `ExamAttemptService::enterBulkMarks()` FormRequest |
| BR-EX-04 | Result generation atomic | `DB::transaction()` in `generateResult()` |
| BR-EX-05 | Published results cannot be un-published | `ExamAttemptService::publishResult()` guard |
| BR-GR-01 | Student may only grieve their own result | `GrievanceService::submitGrievance()` ownership check |
| BR-GR-02 | Grievance only on published result | `GrievanceService::submitGrievance()` check |
| BR-ST-01 | Student sees only own data (IDOR prevention) | All service methods scope by `auth()->user()->student->id` |
| BR-ST-02 | Quiz/Quest only accessible if allocation exists and cut_off_date not passed | `QuizQuestAttemptService::startAttempt()` |

---

## SECTION 5: API / CONTROLLER LAYER

### 5.1 Route Definitions

All routes: prefix `student-portal/`, name prefix `student-portal.`, middleware: `web, InitializeTenancyByDomain, PreventAccessFromCentralDomains, EnsureTenantIsActive, auth, verified, role:Student|Parent, EnsureTenantHasModule:StudentPortal`

#### Quiz / Quest Routes

| Method | URI | Controller@Method | Name | Description |
|---|---|---|---|---|
| POST | `student-portal/quiz/{quiz}/start` | QuizPlayerController@start | `student-portal.quiz.start` | Start or resume a quiz attempt |
| POST | `student-portal/quiz/attempt/{attempt}/answer` | QuizPlayerController@saveAnswer | `student-portal.quiz.answer` | Auto-save a single answer |
| POST | `student-portal/quiz/attempt/{attempt}/submit` | QuizPlayerController@submit | `student-portal.quiz.submit` | Submit completed quiz |
| GET | `student-portal/quiz/attempt/{attempt}/result` | QuizPlayerController@result | `student-portal.quiz.result` | View result after submission |
| POST | `student-portal/quiz/attempt/{attempt}/checkpoint` | QuizPlayerController@checkpoint | `student-portal.quiz.checkpoint` | Save session checkpoint (AJAX) |
| POST | `student-portal/quest/{quest}/start` | QuestPlayerController@start | `student-portal.quest.start` | Start or resume a quest attempt |
| POST | `student-portal/quest/attempt/{attempt}/answer` | QuestPlayerController@saveAnswer | `student-portal.quest.answer` | Auto-save quest answer |
| POST | `student-portal/quest/attempt/{attempt}/submit` | QuestPlayerController@submit | `student-portal.quest.submit` | Submit completed quest |

#### Exam Routes

| Method | URI | Controller@Method | Name | Description |
|---|---|---|---|---|
| GET | `student-portal/exam/{allocation}/take` | ExamPlayerController@show | `student-portal.exam.show` | Pre-exam info page (ONLINE) |
| POST | `student-portal/exam/{allocation}/start` | ExamPlayerController@start | `student-portal.exam.start` | Begin online exam |
| POST | `student-portal/exam/attempt/{attempt}/answer` | ExamPlayerController@saveAnswer | `student-portal.exam.answer` | Auto-save exam answer (AJAX) |
| POST | `student-portal/exam/attempt/{attempt}/submit` | ExamPlayerController@submit | `student-portal.exam.submit` | Submit exam |
| POST | `student-portal/exam/attempt/{attempt}/proctor-event` | ExamPlayerController@proctoringEvent | `student-portal.exam.proctor` | Log proctoring violation (AJAX) |
| GET | `student-portal/exam/{allocation}/result` | ExamPlayerController@result | `student-portal.exam.result` | View published result |

#### Results & Grievances

| Method | URI | Controller@Method | Name | Description |
|---|---|---|---|---|
| GET | `student-portal/results` | StudentResultController@index | `student-portal.results.index` | All published results (quiz+quest+exam) |
| GET | `student-portal/results/exam/{result}` | StudentResultController@examDetail | `student-portal.results.exam` | Detailed exam result with per-subject breakdown |
| POST | `student-portal/results/{result}/grievance` | StudentGrievanceController@store | `student-portal.grievance.store` | Submit re-evaluation request |
| GET | `student-portal/grievances` | StudentGrievanceController@index | `student-portal.grievance.index` | View own grievances |

---

### 5.2 Controller Guide

#### `QuizPlayerController`

**File:** `Modules/StudentPortal/app/Http/Controllers/QuizPlayerController.php`

```php
class QuizPlayerController extends Controller
{
    public function __construct(
        private QuizQuestAttemptService $attemptService,
        private CheckpointService $checkpointService,
    ) {}

    // start() — validates student has access to quiz via allocation
    // Gets or creates attempt (supports resume)
    // Returns JSON: { attempt_id, questions[], checkpoint? }

    // saveAnswer() — delegates to $this->attemptService->saveAnswer()
    // Updates checkpoint via $this->checkpointService->save()
    // Returns JSON: { success: true }

    // submit() — delegates to $this->attemptService->submitAttempt()
    // Clears checkpoint
    // Returns JSON: { result_id } or redirect to result page

    // checkpoint() — saves checkpoint state (AJAX only)
    // Returns JSON: { saved_at }
}
```

**Authorization:** All methods `authorize('attempt', $quiz)` — see Section 6.

---

#### `ExamPlayerController`

**File:** `Modules/StudentPortal/app/Http/Controllers/ExamPlayerController.php`

```php
// show()  — Exam landing page (ONLINE only). Shows exam info, rules, start button.
// start() — Validates allocation active, not already attempted, within scheduled window.
//            Creates attempt. Loads paper set questions shuffled by paper_set.shuffle_questions flag.
//            Returns view: online-exam/player
// saveAnswer() — AJAX endpoint. Calls ExamAttemptService::saveExamAnswer()
// submit() — AJAX/form POST. Calls ExamAttemptService::submitOnlineExam()
//             Clears checkpoint. Returns JSON {redirect_url}
// proctoringEvent() — AJAX. Calls AttemptProctoringService::logEvent() + incrementViolation()
//                     If violation_count >= threshold, auto-submits.
// result() — Gate: result must be published. Returns view: results/exam-detail
```

---

### 5.3 Form Requests

#### `StartQuizAttemptRequest`

```php
public function rules(): array
{
    return [
        'quiz_id'          => 'required|integer|exists:lms_quizzes,id',
        'allocation_id'    => 'required|integer|exists:lms_quiz_allocations,id',
    ];
}
public function authorize(): bool
{
    // Check allocation belongs to student's class/section/group or student directly
    // Check cut_off_date not passed
    // Check quiz is_active and status=PUBLISHED
    return /* custom ownership check */;
}
```

#### `SaveAnswerRequest`

```php
public function rules(): array
{
    return [
        'question_id'         => 'required|integer|exists:qns_questions_bank,id',
        'selected_option_id'  => 'nullable|integer|exists:qns_question_options,id',
        'selected_option_ids' => 'nullable|array',
        'selected_option_ids.*' => 'integer|exists:qns_question_options,id',
        'answer_text'         => 'nullable|string|max:5000',
        'time_spent_seconds'  => 'nullable|integer|min:0|max:86400',
    ];
}
```

#### `SubmitExamRequest`

```php
public function rules(): array
{
    return [
        'attempt_id' => 'required|integer|exists:lms_exam_attempts,id',
    ];
}
public function authorize(): bool
{
    $attempt = ExamAttempt::findOrFail($this->attempt_id);
    // Ensure attempt belongs to authenticated student
    return $attempt->student_id === auth()->user()->student->id;
}
```

#### `StoreGrievanceRequest`

```php
public function rules(): array
{
    return [
        'grievance_type' => 'required|in:MARKING_ERROR,QUESTION_ERROR,OUT_OF_SYLLABUS,OTHER',
        'grievance_text' => 'required|string|min:20|max:2000',
        'question_id'    => 'nullable|integer|exists:qns_questions_bank,id',
    ];
}
```

#### `EnterBulkMarksRequest`

```php
public function rules(): array
{
    return [
        'total_marks_obtained' => 'required|numeric|min:0',
        'remarks'              => 'nullable|string|max:255',
    ];
}
// Custom rule: total_marks_obtained <= exam_paper.total_marks (cross-field)
```

---

### 5.4 API Resources

#### `QuizQuestAttemptResource`

```php
public function toArray($request): array
{
    return [
        'id'             => $this->id,
        'assessment_type'=> $this->assessment_type,
        'attempt_number' => $this->attempt_number,
        'status'         => $this->status,
        'status_label'   => $this->status_label,
        'started_at'     => $this->started_at?->toISOString(),
        'submitted_at'   => $this->submitted_at?->toISOString(),
        'time_taken'     => $this->time_taken_seconds,
        'score'          => $this->score_obtained,
        'percentage'     => $this->percentage,
        'is_passed'      => $this->is_passed,
        'result'         => $this->when(
            $this->relationLoaded('result') && $this->result?->is_published,
            fn() => new QuizQuestResultResource($this->result)
        ),
    ];
}
```

#### `ExamResultResource`

```php
public function toArray($request): array
{
    return [
        'id'                   => $this->id,
        'exam_paper'           => new ExamPaperResource($this->whenLoaded('examPaper')),
        'total_marks_possible' => $this->total_marks_possible,
        'total_marks_obtained' => $this->total_marks_obtained,
        'percentage'           => $this->percentage,
        'grade'                => $this->grade_obtained,
        'division'             => $this->division,
        'result_status'        => $this->result_status,
        'rank_in_class'        => $this->rank_in_class,
        'is_published'         => $this->is_published,
        'published_at'         => $this->published_at?->toISOString(),
        'teacher_remarks'      => $this->teacher_remarks,
        'grievances'           => ExamGrievanceResource::collection($this->whenLoaded('grievances')),
    ];
}
```

---

## SECTION 6: AUTHORIZATION LAYER

### 6.1 Policies

#### `QuizAttemptPolicy`

**File:** `Modules/StudentPortal/app/Policies/QuizAttemptPolicy.php`

| Method | Logic |
|---|---|
| `create` | User is Student + allocation targets student's class/section/student + cut_off_date not passed + attempt_number ≤ max_attempts |
| `view` | `$attempt->student_id === $user->student->id` |
| `submit` | `$attempt->student_id === $user->student->id && $attempt->status === 'IN_PROGRESS'` |
| `viewResult` | `$attempt->student_id === $user->student->id && $attempt->result->is_published` |

#### `ExamAttemptPolicy`

**File:** `Modules/StudentPortal/app/Policies/ExamAttemptPolicy.php`

| Method | Logic |
|---|---|
| `create` | Student + allocation matches + scheduled window active + no prior attempt |
| `view` | `$attempt->student_id === $user->student->id` |
| `submit` | `$attempt->student_id === $user->student->id && $attempt->status === 'IN_PROGRESS'` |

#### `ExamResultPolicy`

| Method | Logic |
|---|---|
| `view` | `$result->student_id === $user->student->id && $result->is_published` OR parent with `can_access_parent_portal=1` linked to that student |

#### `ExamGrievancePolicy`

| Method | Logic |
|---|---|
| `create` | `$result->student_id === $user->student->id && $result->is_published` |
| `view` | `$grievance->student_id === $user->student->id` |

---

### 6.2 Permissions Matrix

| Permission | Student | Parent | Teacher | Admin |
|---|---|---|---|---|
| `stp.attempt.create` | ✅ | ❌ | ❌ | ❌ |
| `stp.attempt.view` | Own only | Child only | ❌ | ✅ |
| `stp.attempt.submit` | Own only | ❌ | ❌ | ❌ |
| `stp.result.view` | Own + published | Child + published | ❌ | ✅ |
| `stp.result.publish` | ❌ | ❌ | ✅ | ✅ |
| `stp.grievance.create` | Own result | ❌ | ❌ | ❌ |
| `stp.grievance.review` | ❌ | ❌ | ✅ | ✅ |
| `stp.marks.enter` | ❌ | ❌ | ✅ | ✅ |

---

## SECTION 7: FRONTEND GUIDE

### 7.1 Page / Component Inventory

| Component | Type | File Path | Description |
|---|---|---|---|
| `QuizPlayer` | Full page | `resources/views/studentportal/quiz/player.blade.php` | Online quiz interface with question navigation, timer, auto-save |
| `QuestPlayer` | Full page | `resources/views/studentportal/quest/player.blade.php` | Quest interface (same structure as quiz player) |
| `ExamPlayer` | Full page | `resources/views/studentportal/exam/player.blade.php` | Online exam interface with proctoring, fullscreen enforcement |
| `ExamPreInfo` | Full page | `resources/views/studentportal/exam/pre-info.blade.php` | Pre-exam rules/info page before starting |
| `ResultsIndex` | Full page | `resources/views/studentportal/results/index.blade.php` | Aggregated results list (quiz + quest + exam) |
| `ExamResultDetail` | Full page | `resources/views/studentportal/results/exam-detail.blade.php` | Detailed exam result with subject breakdown |
| `GrievanceForm` | Modal | `resources/views/studentportal/grievance/create.blade.php` | Grievance submission modal |
| `GrievanceList` | Full page | `resources/views/studentportal/grievance/index.blade.php` | Student's own grievances with status |

---

### 7.2 Component Specifications

#### Online Exam / Quiz Player (Alpine.js)

```html
<div x-data="examPlayer({
    attemptId: {{ $attempt->id }},
    questions: {{ $questions->toJson() }},
    durationSeconds: {{ $durationSeconds }},
    checkpointUrl: '{{ route('student-portal.exam.checkpoint', $attempt) }}',
    answerUrl: '{{ route('student-portal.exam.answer', $attempt) }}',
    submitUrl: '{{ route('student-portal.exam.submit', $attempt) }}',
    proctoringUrl: '{{ route('student-portal.exam.proctor', $attempt) }}',
})" @keydown.window="blockKeys($event)"
   x-init="init()"
   @visibilitychange.document="handleVisibilityChange()"
   @beforeunload.window="handleUnload($event)">

    <!-- Timer display -->
    <div x-text="formatTime(timeLeft)" :class="{ 'text-red-600': timeLeft < 300 }"></div>

    <!-- Question navigation -->
    <!-- Answer form (MCQ/Multi-MCQ/Descriptive/File) -->
    <!-- Flag/un-flag button -->
    <!-- Previous / Next navigation -->
    <!-- Submit button with confirmation modal -->
</div>
```

**Alpine.js Component (`examPlayer`):**

```javascript
Alpine.data('examPlayer', (config) => ({
    currentIdx: 0,
    answers: {},          // { question_id: response }
    flagged: [],          // array of question_ids
    timeLeft: config.durationSeconds,
    timer: null,
    autoSaveInterval: null,
    AUTOSAVE_INTERVAL_MS: 30000,   // 30 seconds
    MAX_VIOLATIONS: 5,
    violations: 0,

    init() {
        this.restoreCheckpoint();
        this.startTimer();
        this.startAutoSave();
        this.enterFullscreen();
        this.bindProctoringEvents();
    },

    restoreCheckpoint() {
        // AJAX GET checkpoint, populate answers[] and flagged[]
    },

    startTimer() {
        this.timer = setInterval(() => {
            this.timeLeft--;
            if (this.timeLeft <= 0) this.autoSubmit();
        }, 1000);
    },

    startAutoSave() {
        this.autoSaveInterval = setInterval(() => {
            this.saveCheckpoint();
        }, this.AUTOSAVE_INTERVAL_MS);
    },

    async selectAnswer(questionId, value, type) {
        this.answers[questionId] = value;
        await this.postAnswer(questionId, value, type);
    },

    async postAnswer(questionId, value, type) {
        await fetch(config.answerUrl, {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]').content, 'Content-Type': 'application/json' },
            body: JSON.stringify({ question_id: questionId, ...this.buildPayload(value, type) })
        });
    },

    async saveCheckpoint() {
        await fetch(config.checkpointUrl, {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': '...', 'Content-Type': 'application/json' },
            body: JSON.stringify({
                current_question_idx: this.currentIdx,
                answered_question_ids: Object.keys(this.answers),
                flagged_question_ids: this.flagged,
                checkpoint_data: this.answers,
            })
        });
    },

    bindProctoringEvents() {
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) this.logProctoringEvent('FOCUS_LOST');
        });
        document.addEventListener('fullscreenchange', () => {
            if (!document.fullscreenElement) this.logProctoringEvent('FULLSCREEN_EXIT');
        });
        document.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            this.logProctoringEvent('CONTEXT_MENU_OPENED');
        });
    },

    async logProctoringEvent(eventType) {
        const res = await fetch(config.proctoringUrl, {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': '...', 'Content-Type': 'application/json' },
            body: JSON.stringify({ event_type: eventType })
        });
        const data = await res.json();
        this.violations = data.violation_count;
        if (data.auto_submit) this.autoSubmit();
    },

    async autoSubmit() {
        clearInterval(this.timer);
        clearInterval(this.autoSaveInterval);
        await fetch(config.submitUrl, { method: 'POST', headers: { 'X-CSRF-TOKEN': '...' } });
        window.location.href = data.redirect_url;
    },
}));
```

---

### 7.3 Blade View Structure

```
studentportal::components.layouts.master
    └── studentportal::quiz.player
    └── studentportal::exam.player
         ├── _question-mcq.blade.php
         ├── _question-multi-mcq.blade.php
         ├── _question-descriptive.blade.php
         └── _question-file-upload.blade.php
    └── studentportal::results.index
    └── studentportal::results.exam-detail
         └── _grievance-modal.blade.php
```

---

## SECTION 8: EVENTS, NOTIFICATIONS & JOBS

### 8.1 Events

| Event Class | When Fires | Payload | Listeners |
|---|---|---|---|
| `QuizAttemptStarted` | Student starts quiz/quest attempt | `$attempt` | Log, CacheInvalidation |
| `QuizAttemptSubmitted` | Student submits attempt | `$attempt` | `TriggerAutoEvaluationJob`, Log |
| `QuizResultPublished` | Teacher/admin publishes result | `$result` | `NotifyStudentResultReadyNotification` |
| `ExamAttemptSubmitted` | Student submits online exam | `$attempt` | `TriggerExamAutoEvaluationJob`, Log |
| `ExamResultPublished` | Result is published | `$result` | `NotifyStudentExamResultNotification`, HPC cache invalidation |
| `ExamGrievanceSubmitted` | Student submits grievance | `$grievance` | `NotifyTeacherGrievanceNotification` |
| `ExamGrievanceResolved` | Teacher resolves grievance | `$grievance` | `NotifyStudentGrievanceResolvedNotification` |

---

### 8.2 Notifications

| Notification | Recipient | Channels | Trigger |
|---|---|---|---|
| `ExamResultPublishedNotification` | Student | database, SMS | `ExamResultPublished` event |
| `QuizResultPublishedNotification` | Student | database | `QuizResultPublished` event |
| `GrievanceReceivedNotification` | Teacher/Admin | database | `ExamGrievanceSubmitted` event |
| `GrievanceResolvedNotification` | Student | database, SMS | `ExamGrievanceResolved` event |

---

### 8.3 Queued Jobs

| Job | Purpose | Queue | Timeout | Retries |
|---|---|---|---|---|
| `AutoEvaluateQuizAttemptJob` | Auto-grade MCQ answers for quiz/quest | `evaluation` | 120s | 2 |
| `AutoEvaluateExamAttemptJob` | Auto-grade MCQ answers for exam | `evaluation` | 300s | 2 |
| `AutoSubmitExpiredAttemptsJob` | Scheduler — find expired IN_PROGRESS, trigger auto-submit | `scheduler` | 60s | 1 |
| `ComputeRankAndPercentileJob` | After all results generated, compute rank_in_class and percentile | `analytics` | 300s | 1 |

**Scheduler entry (in `Console/Kernel.php`):**
```php
$schedule->job(new AutoSubmitExpiredAttemptsJob)->everyMinute();
```

---

## SECTION 9: TESTING STRATEGY

### 9.1 Feature Tests

| Test Method | What It Validates | Setup |
|---|---|---|
| `test_student_can_start_quiz_attempt` | Creates attempt, status=IN_PROGRESS, attempt_number=1 | Student, Quiz, QuizAllocation factory |
| `test_student_cannot_exceed_max_attempts` | Throws `AttemptLimitExceededException` on attempt N+1 | Existing N attempts |
| `test_student_can_save_answer_autosave` | Upserts answer row, checkpoint updated | Active attempt |
| `test_submit_quiz_triggers_auto_evaluation` | MCQ is_correct set, marks_obtained computed | Attempt with MCQ answers |
| `test_negative_marking_deducts_marks` | Wrong MCQ answer → negative marks_obtained | Quiz with negative_marks > 0 |
| `test_student_cannot_view_unpublished_result` | 403 on result access before is_published=1 | Unpublished result |
| `test_student_can_view_published_result` | 200 returns result data | Published result |
| `test_exam_attempt_unique_per_paper_per_student` | Second start attempt throws 409 | Existing exam attempt |
| `test_offline_bulk_marks_entry` | Creates ExamMarksEntry, marks_obtained stored | Teacher, ExamAttempt |
| `test_exam_result_generated_correctly` | percentage, grade_obtained, result_status computed | ExamAttempt + answers or marks entry |
| `test_student_can_submit_grievance` | Creates grievance with status=OPEN | Published result owned by student |
| `test_student_cannot_grieve_another_students_result` | 403 | Different student's result |
| `test_proctoring_event_logged` | Row in activity_logs, violation_count incremented | Active exam attempt |
| `test_auto_submit_on_max_violations` | status=SUBMITTED on violation_count >= threshold | Attempt with violations |
| `test_checkpoint_saved_and_restored` | UPSERT, restore returns correct JSON | Active attempt |
| `test_parent_can_view_childs_published_result` | 200 for parent with can_access_parent_portal=1 | Guardian junction record |

---

### 9.2 Unit Tests

| Test | Target |
|---|---|
| `QuizQuestAttemptService::autoEvaluateMcq` | MCQ correct/incorrect/negative marking logic |
| `ExamAttemptService::generateResult` | Marks aggregation, grade computation, pass/fail |
| `GrievanceService::adjustMarks` | old_marks captured, new_marks saved, result updated |
| `CheckpointService::save` | UPSERT behavior — second save overwrites first |
| `AttemptActivityLog` model | `is_active` scope, no softDeletes trait |
| `QuizQuestAttempt` model | `getAssessmentAttribute` returns Quiz or Quest based on type |
| `ExamResult` model | `scopePublished` filters correctly |

---

### 9.3 Edge Cases

| Edge Case | Test Scenario | Expected Outcome |
|---|---|---|
| Student starts attempt, browser closes mid-exam | Checkpoint restored on next load | `restore()` returns last saved state |
| Clock skew — student submits after duration expires | `actual_time_taken_seconds` > duration; still accepted (scheduler handles hard cutoff) | Attempt submitted, not rejected |
| Student A submits grievance with result_id of Student B | 403 Forbidden | Ownership check in GrievanceService + Policy |
| Teacher enters bulk marks 110 / 100 total | 422 Validation error | `EnterBulkMarksRequest` max:exam_paper.total_marks |
| Result published, then teacher adjusts marks via grievance | `lms_exam_results.total_marks_obtained` updated atomically | `DB::transaction()` in `adjustMarks()` |
| Quiz allows 3 attempts; student already at 3 | 422 "Max attempts reached" | `BR-QQ-01` in `startAttempt()` |
| Tenant isolation: Student from School A queries School B attempt | 0 results | Tenant DB isolation (stancl/tenancy) |
| Concurrent duplicate exam start (race condition) | One succeeds, second gets `UniqueConstraintViolationException` → 409 | `try/catch` in `startOnlineExam()` |

---

## SECTION 10: IMPLEMENTATION ROADMAP

### 10.1 Phase Breakdown

#### Phase 1 — Foundation (Database)
- Create 10 tenant migration files in execution order
- Create 10 Eloquent models with fillable, casts, relationships, scopes
- Create 10 factories with realistic faker data
- Run `php artisan tenants:migrate` on dev tenant

**Estimated:** 2 developer-days

---

#### Phase 2 — Core Logic (Services)
- `QuizQuestAttemptService` — start, save, submit, auto-eval, compute result, publish
- `ExamAttemptService` — online start, offline record, bulk marks, question-wise marks, generate result, publish
- `GrievanceService` — submit, review, adjust marks
- `AttemptProctoringService` — log event, increment violation, auto-submit check
- `CheckpointService` — save, restore, clear
- Unit tests for all service methods

**Estimated:** 3 developer-days
**High Risk:** Negative marking logic, concurrent attempt prevention, atomic result generation

---

#### Phase 3 — API Layer
- Form Request classes (StartQuizAttemptRequest, SaveAnswerRequest, SubmitExamRequest, StoreGrievanceRequest, EnterBulkMarksRequest)
- Controllers (QuizPlayerController, QuestPlayerController, ExamPlayerController, StudentResultController, StudentGrievanceController)
- API Resources (QuizQuestAttemptResource, ExamResultResource, ExamGrievanceResource)
- Policies (QuizAttemptPolicy, ExamAttemptPolicy, ExamResultPolicy, ExamGrievancePolicy)
- Register routes in `routes/tenant.php`
- Register policies in `AuthServiceProvider`

**Estimated:** 2 developer-days

---

#### Phase 4 — Frontend
- Quiz/Quest player view with Alpine.js (question navigation, timer, auto-save, submit)
- Online exam player view (proctoring: fullscreen, focus detection, context-menu block)
- Results index page (aggregated quiz + quest + exam)
- Exam result detail page with subject breakdown
- Grievance submission modal + list page
- Checkpoint restore logic on page load

**Estimated:** 4 developer-days
**High Risk:** Proctoring detection (fullscreen, tab visibility, devtools) varies by browser

---

#### Phase 5 — Events & Async
- Events: QuizAttemptSubmitted, ExamResultPublished, ExamGrievanceSubmitted, ExamGrievanceResolved
- Notifications: ExamResultPublishedNotification, GrievanceResolvedNotification
- Jobs: AutoEvaluateQuizAttemptJob, AutoEvaluateExamAttemptJob, AutoSubmitExpiredAttemptsJob, ComputeRankAndPercentileJob
- Scheduler registration

**Estimated:** 2 developer-days

---

#### Phase 6 — Testing & QA
- Feature tests (16 scenarios from Section 9.1)
- Unit tests (7 scenarios from Section 9.2)
- Edge case tests (8 scenarios from Section 9.3)
- Tenant isolation verification
- Security review (IDOR checks for all attempt/result lookups)

**Estimated:** 2 developer-days

---

### 10.2 Estimated Effort Summary

| Phase | Work | Days | Risk |
|---|---|---|---|
| 1 | Migrations + Models + Factories | 2 | Low |
| 2 | Service Layer | 3 | **High** |
| 3 | Controllers + Routes + Policies | 2 | Medium |
| 4 | Frontend (Alpine.js player) | 4 | **High** |
| 5 | Events + Jobs + Notifications | 2 | Medium |
| 6 | Testing + QA | 2 | Low |
| **Total** | | **15 developer-days** | |

---

### 10.3 Developer Checklist

#### Foundation
- [ ] 10 migration files created and run on dev tenant (`php artisan tenants:migrate`)
- [ ] All 10 models: `$table`, `$fillable`, `$casts`, relationships, scopes
- [ ] Factories for all 10 models with realistic data

#### Business Logic
- [ ] `QuizQuestAttemptService` — all 8 methods implemented and unit tested
- [ ] `ExamAttemptService` — all 10 methods implemented and unit tested
- [ ] `GrievanceService` — all 3 methods
- [ ] `AttemptProctoringService` — log, increment, auto-submit threshold
- [ ] `CheckpointService` — save, restore, clear

#### API Layer
- [ ] 5 FormRequest classes with `rules()` and `authorize()`
- [ ] 5 Controller classes using thin-controller pattern (delegate to service)
- [ ] 4 Policy classes registered in `AuthServiceProvider`
- [ ] Routes registered in `routes/tenant.php` under student-portal middleware group
- [ ] API Resources for all response shapes

#### Frontend
- [ ] Quiz/Quest player page wired end-to-end (start → answer → submit → result)
- [ ] Online exam player with proctoring (fullscreen, focus loss, context-menu, auto-submit)
- [ ] Auto-save every 30 seconds (checkpoint)
- [ ] Session restore from checkpoint on page reload
- [ ] Results index showing all 3 assessment types
- [ ] Exam result detail with per-question breakdown
- [ ] Grievance submission modal + status list

#### Async & Events
- [ ] Auto-evaluation jobs dispatched on submission
- [ ] `AutoSubmitExpiredAttemptsJob` registered in scheduler
- [ ] Result published notification sent to student (database + SMS)
- [ ] Grievance resolved notification sent to student

#### Security & QA
- [ ] Every controller method verifies student owns the resource (no IDOR)
- [ ] `EnsureTenantHasModule:StudentPortal` middleware on all routes
- [ ] Tenant isolation verified — Student A cannot query Student B's attempts
- [ ] 16 feature tests passing
- [ ] 7 unit tests passing
- [ ] 8 edge case tests passing
- [ ] Code reviewed against MRD Section 8 (Business Rules) — all BR-* checked

---

*End of Development Guide*
*Generated: 2026-04-02 | DDL: StudentAttempt_ddl_v3.sql | MRD: STP_StudentPortal_Requirement.md V2*
