# LMS Documentation — Summary Index
**Generated:** 2026-03-19
**v3 Updated:** 2026-03-19 (all review comments resolved)
**v3 Patch — 2026-03-20 (1):** Syllabus module — grouped listing requirement added for Cognitive Skills and Question Type Specificity tabs (Section 1.21 in lms_requirements.md; Section 2.1-A in lms_rules_conditions.md)
**v3 Patch — 2026-03-20 (2):** Syllabus module — two new index-screen requirements added: (a) Syllabus Lesson Topic Release Control (Section 1.22), (b) Lesson Planning Date Range (Section 1.23). Corresponding rules added in lms_rules_conditions.md Sections 2.1-B and 2.1-C.
**Platform:** Prime-AI ERP + LMS + LXP (Multi-Tenant SaaS, Indian K-12 Schools)
**Tech Stack:** PHP 8.2+ / Laravel 12.0 / MySQL 8.x / stancl/tenancy v3.9 / nwidart/laravel-modules v12.0

---

## Generated Files

| File | Format | Purpose | Size (approx) |
|---|---|---|---|
| `lms_requirements.md` | Markdown | Master requirements document — all 6 modules, 20 sections each | ~600 KB |
| `lms_rules_conditions.md` | Markdown | Tabular rules, validations, CRUD conditions, permissions, workflows | ~80 KB |
| `lms_code_review.md` | Markdown | Module-wise focused code review with severity ratings and file references | ~80 KB |
| `lms_requirements.html` | HTML | Styled, navigable version of the requirements document with sidebar | ~100 KB |
| `lms_summary_index.md` | Markdown | This file — navigation index | — |

**Output folder:** `C:\laragon\www\prime_db\pgdatabase\7-Work_on_Modules\LMS\`

---

## Modules Covered

| # | Module | Path | Table Prefix | Route Prefix | Completion |
|---|---|---|---|---|---|
| 1 | Syllabus | `Modules/Syllabus/` | `slb_*` | `/syllabus/*` | ~100% |
| 2 | LmsQuiz | `Modules/LmsQuiz/` | `lms_quizzes*` | `/lms-quize/*` | ~90% |
| 3 | LmsQuests | `Modules/LmsQuests/` | `lms_quests*` | `/lms-quests/*` | ~85% |
| 4 | LmsExam | `Modules/LmsExam/` | `lms_exam*` | `/lms-exam/*` | ~90% |
| 5 | LmsHomework | `Modules/LmsHomework/` | `lms_homework*` | `/lms-home-work/*` | ~80% |
| 6 | QuestionBank | `Modules/QuestionBank/` | `qns_*` | `/question-bank/*` | ~85% |

---

## Source Files Inspected

### Module Directories
- `C:\laragon\www\prime_ai\prime_ai\Modules\Syllabus\`
- `C:\laragon\www\prime_ai\prime_ai\Modules\LmsQuiz\`
- `C:\laragon\www\prime_ai\prime_ai\Modules\LmsQuests\`
- `C:\laragon\www\prime_ai\prime_ai\Modules\LmsExam\`
- `C:\laragon\www\prime_ai\prime_ai\Modules\LmsHomework\`
- `C:\laragon\www\prime_ai\prime_ai\Modules\QuestionBank\`

### Routes
- `C:\laragon\www\prime_ai\prime_ai\routes\tenant.php` (lines 159-1111, 490-740, 894-960 — LMS sections)

### Policies Inspected
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuizPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestionBankPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\SyllabusSchedulePolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestAllocationPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestQuestionPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamAllocationPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamPaperPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamPaperSetPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamStatusEventPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamStudentGroupPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamStudentGroupMemberPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\ExamTypePolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\PaperSetQuestionPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestionMediaStorePolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestionStatisticPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestionTagPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestionUsageLogPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\QuestionUsageTypePolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\AIQuestionPolicy.php`
- `C:\laragon\www\prime_ai\prime_ai\app\Policies\AiQuestionGeneratorPolicy.php`

### Migrations Inspected (Tenant)
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2025_12_22_124231_create_slb_complexity_levels_table.bk`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2025_12_22_124334_create_slb_question_types_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_06_172432_create_question_banks_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_12_132528_create_qns_question_options_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_12_133104_create_qns_media_store_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_12_133105_create_qns_question_media_jnt_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_15_162042_create_slb_syllabus_schedule_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_23_231503_create_lms_trigger_events_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_24_132344_create_lms_action_type_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_24_155514_create_lms_rule_engine_configs_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_24_174023_create_lms_homework_table.php`
- `C:\laragon\www\prime_ai\prime_ai\database\migrations\tenant\2026_01_24_174706_create_lms_homework_submissions_table.php`

### Key Model Files Read
- `Modules/Syllabus/app/Models/Topic.php`
- `Modules/Syllabus/app/Models/Lesson.php`
- `Modules/LmsQuiz/app/Models/Quiz.php`
- `Modules/LmsQuiz/app/Models/QuizAllocation.php`
- `Modules/LmsQuiz/app/Models/DifficultyDistributionConfig.php`
- `Modules/LmsQuests/app/Models/Quest.php`
- `Modules/LmsExam/app/Models/Exam.php`
- `Modules/LmsExam/app/Models/ExamPaper.php`
- `Modules/LmsExam/app/Models/ExamAllocation.php`
- `Modules/LmsExam/app/Models/ExamBlueprint.php`
- `Modules/LmsExam/app/Models/ExamScope.php`
- `Modules/LmsHomework/app/Models/Homework.php`
- `Modules/LmsHomework/app/Models/HomeworkSubmission.php`
- `Modules/LmsHomework/app/Models/RuleEngineConfig.php`
- `Modules/QuestionBank/app/Models/QuestionBank.php`

### Key Request Files Read
- `Modules/Syllabus/app/Http/Requests/LessonRequest.php`
- `Modules/Syllabus/app/Http/Requests/TopicRequest.php`
- `Modules/LmsQuiz/app/Http/Requests/QuizRequest.php`
- `Modules/LmsQuests/app/Http/Requests/QuestRequest.php`
- `Modules/LmsQuests/app/Http/Requests/QuestAllocationRequest.php`
- `Modules/LmsExam/app/Http/Requests/ExamRequest.php`
- `Modules/LmsExam/app/Http/Requests/ExamPaperRequest.php`
- `Modules/LmsExam/app/Http/Requests/ExamAllocationRequest.php`
- `Modules/LmsHomework/app/Http/Requests/HomeworkRequest.php`

### Controller Files Read (partial)
- `Modules/QuestionBank/app/Http/Controllers/AIQuestionGeneratorController.php`

---

## Excel File
- **Path:** `C:\laragon\www\LMS_Shailesh.xlsx`
- **Status:** File confirmed as `Microsoft Excel 2007+` format (binary XLSX)
- **Parsed:** No — binary XLSX requires a spreadsheet parser (PhpSpreadsheet or similar). A bash tool cannot extract content from binary XLSX.
- **Impact:** All requirements in this documentation set are labeled **"derived from code"**. Sections that would reference Excel data are labeled **N/A**.
- **Recommendation:** To incorporate Excel content, run `php artisan tinker` with PhpSpreadsheet to extract sheet data, then re-run analysis.

---

## Navigation Links

### Quick Access to Key Sections

**Requirements Document (`lms_requirements.md`):**
- [Syllabus Module — Section 1](lms_requirements.md#1-syllabus-module)
- [Syllabus — Grouped Listing Requirement — Section 1.21](lms_requirements.md#121-documentation-addendum--grouped-listing-requirement-for-cognitive-skills-and-question-type-specificity-tabs)
- [Syllabus — Lesson Topic Release Control — Section 1.22](lms_requirements.md#122-documentation-addendum--syllabus-lesson-topic-release-control-index-screen)
- [Syllabus — Lesson Planning Date Range — Section 1.23](lms_requirements.md#123-documentation-addendum--lesson-planning-date-range-index-screen)
- [LmsQuiz Module — Section 2](lms_requirements.md#2-lmsquiz-module)
- [LmsQuests Module — Section 3](lms_requirements.md#3-lmsquests-module)
- [LmsExam Module — Section 4](lms_requirements.md#4-lmsexam-module)
- [LmsHomework Module — Section 5](lms_requirements.md#5-lmshomework-module)
- [QuestionBank Module — Section 6](lms_requirements.md#6-questionbank-module)
- [Executive Summary](lms_requirements.md#executive-summary)
- [Overall Suggestions](lms_requirements.md#overall-suggestions)

**Rules & Conditions (`lms_rules_conditions.md`):**
- [Syllabus Grouped Listing Conditions — Section 2.1-A](lms_rules_conditions.md#21-a-syllabus-module--grouped-listing-view-conditions-new-requirement--documentation-addendum)
- [Syllabus — Release Control Rules — Section 2.1-B](lms_rules_conditions.md#21-b-syllabus-module--syllabus-lesson-topic-release-control-new-requirement--documentation-addendum)
- [Syllabus — Lesson Planning Date Range Rules — Section 2.1-C](lms_rules_conditions.md#21-c-syllabus-module--lesson-planning-date-range-new-requirement--documentation-addendum)
- [Validation Rules](lms_rules_conditions.md#1-validation-rules)
- [CRUD Conditions](lms_rules_conditions.md#2-crud-conditions)
- [Business Rules](lms_rules_conditions.md#3-business-rules)
- [Permission Matrix](lms_rules_conditions.md#4-permission--policy-matrix)
- [Workflow / Status Lifecycle](lms_rules_conditions.md#5-workflow--status-lifecycle)
- [Allocation Rules](lms_rules_conditions.md#6-allocation-rules)
- [Auto-Generation Rules](lms_rules_conditions.md#8-auto-generation-rules)

**Code Review (`lms_code_review.md`):**
- [All Issues Quick Reference](lms_code_review.md#quick-reference--all-issues)
- [Syllabus Review](lms_code_review.md#1-syllabus-module--code-review)
- [LmsQuiz Review](lms_code_review.md#2-lmsquiz-module--code-review)
- [LmsQuests Review](lms_code_review.md#3-lmsquests-module--code-review)
- [LmsExam Review](lms_code_review.md#4-lmsexam-module--code-review)
- [LmsHomework Review](lms_code_review.md#5-lmshomework-module--code-review)
- [QuestionBank Review](lms_code_review.md#6-questionbank-module--code-review)
- [Cross-Module Issues](lms_code_review.md#7-cross-module-issues)
- [Summary Recommendations](lms_code_review.md#8-summary-recommendations)

**HTML Version:**
- Open `lms_requirements.html` in any browser for navigable, styled version

---

## Issue Summary by Severity

| Severity | Count | Issues |
|---|---|---|
| CRITICAL | 2 | CR-001 (API keys), CR-002 (No HomeworkPolicy) |
| HIGH | 9 | CR-003, CR-004, CR-005, CR-006, CR-007, CR-008, CR-009, CR-010, CR-011, CR-012 |
| MEDIUM | 8 | CR-013, CR-014, CR-015, CR-016, CR-017, CR-018, CR-019, CR-020, CR-021, CR-022 |
| LOW | 9 | CR-023, CR-024, CR-025, CR-026, CR-027, CR-028, CR-029, CR-030 + XM-001..XM-005 |

---

## Statistics

| Metric | Count |
|---|---|
| Total modules documented | 6 |
| Total controllers across modules | 47 |
| Total models across modules | 64 |
| Total request classes | 40+ |
| Total routes | ~190 |
| Total policies found | 22 |
| Total policies missing (gap) | 10+ |
| Total code review issues | 30 + 5 cross-module |
| Total business rules documented | 60+ |
| Total validation rules documented | 80+ |
| Migrations found for LMS tables | 12 |

---

## How to Use This Documentation

1. **For new feature development**: Start with `lms_requirements.md` → find the module → read sections 1.7 (Functional Requirements), 1.8 (Business Rules), 1.9 (Validation Rules)
2. **For code review**: Use `lms_code_review.md` → filter by severity → address CRITICAL first
3. **For permission setup**: Use `lms_rules_conditions.md` → Section 4 (Permission Matrix)
4. **For workflow design**: Use `lms_rules_conditions.md` → Section 5 (Workflow Lifecycle)
5. **For client presentation**: Use `lms_requirements.html` (browser-based, styled, with sidebar navigation)
6. **For understanding module relationships**: Use `lms_rules_conditions.md` → Section 9 (Module Dependency Rules)

---

*Generated by code inspection on 2026-03-19. All content derived from code analysis. Excel source file (`LMS_Shailesh.xlsx`) present but not parseable without a spreadsheet library.*

---

## Documentation Update — Round 2
**Date:** 2026-03-19 (same session, deep difficulty-level pass)
**Method:** Code inspection of DifficultyDistributionConfigController, QuizQuestionController, PaperSetQuestionController, ExamPaperController, ExamBlueprintController, ExamPaper model, Quiz model, ExamBlueprint model, DifficultyDistributionConfigRequest, ExamPaperRequest, PaperSetQuestion model, and Blade views for exam-paper and paper-set-question.

### What Was Added

#### lms_requirements.md — Addendum Sections A1–A9
| Section | Content |
|---|---|
| A1 | Difficulty Engine Overview — how the engine works across modules, opt-in nature, ignore flag behavior |
| A2 | DifficultyDistributionConfig entity — all fields, relationships, CRUD lifecycle, permissions table |
| A3 | DifficultyDistributionDetail entity — all fields, nullable optional fields, cross-field validation |
| A4 | LmsQuiz question builder difficulty logic — search filters, rule fetch, 5-step add-time validation, algorithm walkthrough, marks override, usage logging |
| A5 | LmsExam exam paper difficulty fields — cross-module FK from LmsQuiz, PaperSetQuestion builder logic |
| A6 | ExamBlueprint entity — purpose, all fields, CRITICAL authorization gap (all gates commented out), planning-only nature |
| A7 | ExamScope entity — purpose, advisory-only target counts, UI vs server-side enforcement gap |
| A8 | LmsHomework difficulty — simple label only (difficulty_level_id FK to slb_complexity_level) |
| A9 | Difficulty gaps table — 10 gaps catalogued by module, severity, source type |

#### lms_rules_conditions.md — Sections 11–17
| Section | Content |
|---|---|
| 11 | DifficultyDistributionConfig validation rules — all fields, cross-field rule, prepareForValidation notes |
| 12 | Difficulty Distribution CRUD conditions — create/edit/delete/forceDelete/restore with blocking conditions |
| 13 | Exam Paper difficulty fields — ExamPaperRequest validation for difficulty_config_id, ignore flag, unused/authorised flags |
| 14 | Difficulty validation rules at add-time (DV1–DV8) — the 5-step check sequence for Quiz and Exam Paper |
| 15 | Difficulty distribution algorithm rules (DA1–DA10) — calculationBase, PATH A vs PATH B, max enforcement, min gap, marks override, usage log behavior |
| 16 | Difficulty level usage by module — comparison table across all 6 modules |
| 17 | ExamBlueprint rules (EB1–EB8) — validation rules and enforcement gaps |

#### lms_code_review.md — CR-031 through CR-043
| Finding | Severity | Description |
|---|---|---|
| CR-031 | CRITICAL | ExamBlueprintController: all Gate::authorize() commented out |
| CR-032 | HIGH | min_percentage computed but never enforced at add-time |
| CR-033 | HIGH | Difficulty validation skipped at quiz publish time |
| CR-034 | HIGH | Same publish-time gap in LmsExam |
| CR-035 | HIGH | ExamScope target counts not enforced server-side |
| CR-036 | MEDIUM | No cross-validation between Blueprint sections and PaperSetQuestion actual counts |
| CR-037 | MEDIUM | DifficultyDistributionDetail rows hard-deleted on every update — audit trail lost |
| CR-038 | MEDIUM | Soft-delete on Config does not cascade to Detail rows |
| CR-039 | MEDIUM | ignore_difficulty_config read from eager-loaded relation — null safety gap |
| CR-040 | MEDIUM | LmsExam cross-module dependency on LmsQuiz for difficulty config (undocumented) |
| CR-041 | LOW | PATH A vs PATH B detection edge case with mixed rule configs |
| CR-042 | LOW | String '1' used instead of boolean for is_active filter (inconsistency) |
| CR-043 | LOW | QuestionUsageLog forceDeleted on removal — undermines unused-questions filter |

### Updated Issue Counts

| Severity | Previous | Added | Total |
|---|---|---|---|
| CRITICAL | 2 | 1 (CR-031) | 3 |
| HIGH | 10 | 4 (CR-032, 033, 034, 035) | 14 |
| MEDIUM | 10 | 5 (CR-036, 037, 038, 039, 040) | 15 |
| LOW | 9 | 3 (CR-041, 042, 043) | 12+ |

### New Source Files Inspected in Round 2
- `Modules/LmsQuiz/app/Models/DifficultyDistributionConfig.php`
- `Modules/LmsQuiz/app/Models/DifficultyDistributionDetail.php`
- `Modules/LmsQuiz/app/Http/Controllers/DifficultyDistributionConfigController.php`
- `Modules/LmsQuiz/app/Http/Controllers/QuizQuestionController.php` (full file)
- `Modules/LmsQuiz/app/Http/Requests/DifficultyDistributionConfigRequest.php`
- `Modules/LmsQuiz/app/Models/Quiz.php` (partial — fillable/difficulty fields)
- `Modules/LmsExam/app/Models/ExamPaper.php`
- `Modules/LmsExam/app/Models/ExamBlueprint.php`
- `Modules/LmsExam/app/Models/ExamPaperSet.php`
- `Modules/LmsExam/app/Models/PaperSetQuestion.php`
- `Modules/LmsExam/app/Http/Controllers/ExamPaperController.php`
- `Modules/LmsExam/app/Http/Controllers/ExamBlueprintController.php`
- `Modules/LmsExam/app/Http/Controllers/PaperSetQuestionController.php`
- `Modules/LmsExam/app/Http/Requests/ExamPaperRequest.php`
- `Modules/LmsExam/app/Http/Requests/ExamBlueprintRequest.php`
- `Modules/LmsExam/resources/views/exam-paper/create.blade.php` (partial — difficulty fields)
- `Modules/LmsExam/resources/views/exam-paper/edit.blade.php` (partial)
- `Modules/LmsExam/resources/views/exam-paper/show.blade.php` (partial)
- `Modules/LmsExam/resources/views/paper-set-question/create.blade.php` (partial — difficulty UI panel)
- `Modules/LmsHomework/resources/views/home-work/create.blade.php` (partial)
- `routes/tenant.php` (difficulty route section lines 677-701)

### Items Needing Confirmation
- Whether LmsQuests (QuestQuestion builder) has any difficulty distribution config support — not found in Quest model fillable or QuestRequest, likely absent (needs confirmation)
- Whether any migration exists for `lms_difficulty_distribution_configs` or `lms_difficulty_distribution_details` — no migration files found in `database/migrations/tenant/` matching these table names (possible they were created via SQL DDL or are in a module migration not yet located)
- Whether ExamBlueprintPolicy exists — not found in the policies directory scan
