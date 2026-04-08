# LMS Modules — Rules, Conditions, Permissions, Workflows
**Generated:** 2026-03-19
**Source:** Code inspection — all items derived from code unless noted.

---

## TABLE OF CONTENTS
1. [Validation Rules — All Modules](#1-validation-rules)
2. [CRUD Conditions — All Modules](#2-crud-conditions)
3. [Business Rules — All Modules](#3-business-rules)
4. [Permission / Policy Matrix](#4-permission--policy-matrix)
5. [Workflow / Status Lifecycle](#5-workflow--status-lifecycle)
6. [Allocation Rules](#6-allocation-rules)
7. [Date / Time Rules](#7-date--time-rules)
8. [Auto-Generation Rules](#8-auto-generation-rules)
9. [Module Dependency Rules](#9-module-dependency-rules)
10. [Common Platform Rules](#10-common-platform-rules)

---

## 1. VALIDATION RULES

### 1.1 Syllabus — LessonRequest
| Field | Rule | Source |
|---|---|---|
| academic_session_id | required, integer, exists:sch_org_academic_sessions_jnt | LessonRequest.php |
| class_id | required, integer, exists:sch_classes | LessonRequest.php |
| subject_id | required, integer, exists:sch_subjects | LessonRequest.php |
| lessons | required, array, min:1 | LessonRequest.php |
| lessons.*.name | required, string, max:150, unique per session+class+subject (custom closure) | LessonRequest.php |
| lessons.*.code | required, string, max:20, globally unique (custom closure) | LessonRequest.php |
| lessons.*.ordinal | required, integer, min:1, unique per session+class+subject (custom closure) | LessonRequest.php |
| lessons.*.short_name | nullable, string, max:50 | LessonRequest.php |
| lessons.*.description | nullable, string, max:255 | LessonRequest.php |
| lessons.*.learning_objectives | nullable, string | LessonRequest.php |
| lessons.*.estimated_periods | nullable, integer, min:1 | LessonRequest.php |
| lessons.*.weightage_in_subject | nullable, numeric, min:0, max:100 | LessonRequest.php |
| lessons.*.nep_alignment | nullable, string, max:100 | LessonRequest.php |
| lessons.*.scheduled_year_week | nullable, integer, min:202001, max:210052 | LessonRequest.php |
| lessons.*.resources.*.type | required_with_resource, in:video,pdf,link,document,image,audio,ppt | LessonRequest.php |
| lessons.*.resources.*.title | required_with_resource, string, max:200 | LessonRequest.php |
| lessons.*.resources.*.url | required_with_resource, url, max:500 | LessonRequest.php |
| lessons.*.resources.*.description | nullable, string, max:500 | LessonRequest.php |

### 1.2 Syllabus — TopicRequest
| Field | Rule | Source |
|---|---|---|
| class_id | required, integer, exists:sch_classes | TopicRequest.php |
| subject_id | required, integer, exists:sch_subjects | TopicRequest.php |
| lesson_id | required, integer, exists:slb_lessons | TopicRequest.php |
| parent_id | nullable, integer, exists:slb_topics | TopicRequest.php |
| name | required, string, max:150, unique per (lesson+parent) ignoring self | TopicRequest.php |
| level | nullable, integer, min:0, max:TopicLevelType.max_level | TopicRequest.php |
| duration_minutes | nullable, integer, min:1 | TopicRequest.php |
| is_active | required, boolean | TopicRequest.php |
| id | nullable, integer, exists:slb_topics (for update) | TopicRequest.php |

### 1.3 LmsQuiz — QuizRequest
| Field | Rule | Source |
|---|---|---|
| academic_session_id | required (NO exists validation — gap) | QuizRequest.php |
| class_id | required, exists:sch_classes | QuizRequest.php |
| subject_id | required, exists:sch_subjects | QuizRequest.php |
| lesson_id | required, exists:slb_lessons | QuizRequest.php |
| title | required, string, max:100 | QuizRequest.php |
| quiz_type_id | required, exists:lms_assessment_types | QuizRequest.php |
| scope_topic_id | nullable, exists:slb_topics | QuizRequest.php |
| status | required, in:DRAFT,PUBLISHED,ARCHIVED | QuizRequest.php |
| duration_minutes | nullable, integer, min:1, max:600 | QuizRequest.php |
| total_marks | required, numeric, min:0 | QuizRequest.php |
| total_questions | required, integer, min:0 | QuizRequest.php |
| passing_percentage | required, numeric, min:0, max:100 | QuizRequest.php |
| allow_multiple_attempts | boolean | QuizRequest.php |
| max_attempts | required_if:allow_multiple_attempts=true, integer, min:1, max:10 | QuizRequest.php |
| negative_marks | required, numeric, min:0, max:99.99 | QuizRequest.php |
| difficulty_config_id | nullable, exists:lms_difficulty_distribution_configs | QuizRequest.php |
| created_by | nullable, exists:sys_users | QuizRequest.php |

### 1.4 LmsQuests — QuestRequest
| Field | Rule | Gap vs QuizRequest |
|---|---|---|
| title | required, string, max:255 | Quiz: max:100 |
| quest_type_id | required, exists:lms_assessment_types | Consistent |
| status | required, in:DRAFT,PUBLISHED,ARCHIVED | Consistent |
| academic_session_id | nullable, string — GAP: no required, no exists | Quiz has required |
| class_id | nullable, string — GAP: no required, no exists | Quiz has required+exists |
| subject_id | nullable, string — GAP | Quiz has required+exists |
| lesson_id | nullable, string — GAP | Quiz has required+exists |
| duration_minutes | nullable, integer, min:1, max:300 | Quiz allows max:600 |
| total_marks | required, numeric, min:0 | Consistent |
| total_questions | required, integer, min:0 | Consistent |
| passing_percentage | required, numeric, min:0, max:100 | Consistent |
| max_attempts | required_if:allow_multiple_attempts=true, 1-10 | Consistent |
| negative_marks | required, numeric, min:0, max:99.99 | Consistent |
| pending | boolean — UNIQUE to Quest | Not in Quiz |

### 1.5 LmsQuests — QuestAllocationRequest
| Field | Rule | Source |
|---|---|---|
| quest_id | required, exists:lms_quests, must be active (custom) | QuestAllocationRequest.php |
| allocation_type | required, in:CLASS,SECTION,GROUP,STUDENT | QuestAllocationRequest.php |
| target_id | required, integer, min:1, exists in target table (dynamic by type) | QuestAllocationRequest.php |
| due_date | required, date, after_or_equal:now, max 2 years in future | QuestAllocationRequest.php |
| cut_off_date | nullable, date, after_or_equal:due_date, max 2 years | QuestAllocationRequest.php |
| is_auto_publish_result | boolean | QuestAllocationRequest.php |
| result_publish_date | nullable, after_or_equal:due_date, prohibited_unless:is_auto_publish_result=true | QuestAllocationRequest.php |
| is_active | boolean | QuestAllocationRequest.php |

Target table resolution by allocation_type:
- CLASS → sch_classes
- SECTION → sch_sections
- GROUP → sch_entity_groups
- STUDENT → std_students (also checks is_active=true, deleted_at IS NULL)

### 1.6 LmsExam — ExamRequest
| Field | Rule | Source |
|---|---|---|
| academic_session_id | required (NO exists — gap) | ExamRequest.php |
| class_id | required, exists:sch_classes | ExamRequest.php |
| exam_type_id | required, exists:lms_exam_types, unique per (session+class) ignoring self | ExamRequest.php |
| code | nullable, string, max:50, unique ignoring self | ExamRequest.php |
| title | required, string, max:150 | ExamRequest.php |
| start_date | required, date, before_or_equal:end_date | ExamRequest.php |
| end_date | required, date, after_or_equal:start_date | ExamRequest.php |
| grading_schema_id | nullable, exists:slb_grade_division_master | ExamRequest.php |
| status_id | required, exists:lms_exam_status_events | ExamRequest.php |
| is_active | boolean | ExamRequest.php |

### 1.7 LmsExam — ExamPaperRequest
| Field | Rule | Source |
|---|---|---|
| exam_id | required, exists:lms_exams | ExamPaperRequest.php |
| class_id | required, exists:sch_classes | ExamPaperRequest.php |
| subject_id | required, exists:sch_subjects | ExamPaperRequest.php |
| paper_code | required, string, max:50, unique per exam ignoring self | ExamPaperRequest.php |
| title | required, string, max:150 | ExamPaperRequest.php |
| mode | required, in:ONLINE,OFFLINE | ExamPaperRequest.php |
| total_marks | required, numeric, min:0, max:999999.99 | ExamPaperRequest.php |
| passing_percentage | required, numeric, min:0, max:100 | ExamPaperRequest.php |
| duration_minutes | nullable, integer, min:1, max:1440 | ExamPaperRequest.php |
| show_result_type | required_if:mode=ONLINE, in:IMMEDIATE,SCHEDULED,MANUAL | ExamPaperRequest.php |
| scheduled_result_at | nullable, required_if:show_result_type=SCHEDULED, date, after:now | ExamPaperRequest.php |
| offline_entry_mode | required_if:mode=OFFLINE, in:BULK_TOTAL,QUESTION_WISE | ExamPaperRequest.php |
| status_id | required, exists:lms_exam_status_events | ExamPaperRequest.php |

### 1.8 LmsExam — ExamAllocationRequest
| Field | Rule | Source |
|---|---|---|
| exam_paper_id | required, exists:lms_exam_papers | ExamAllocationRequest.php |
| paper_set_id | required, exists:lms_exam_paper_sets | ExamAllocationRequest.php |
| allocation_type | required, in:CLASS,SECTION,EXAM_GROUP,STUDENT | ExamAllocationRequest.php |
| class_id | required, exists:sch_classes | ExamAllocationRequest.php |
| section_id | required if type=SECTION, exists:sch_sections | ExamAllocationRequest.php |
| exam_group_id | required if type=EXAM_GROUP, exists:lms_exam_student_groups | ExamAllocationRequest.php |
| student_id | required if type=STUDENT, exists:std_students | ExamAllocationRequest.php |
| scheduled_start_time | required, date_format:H:i | ExamAllocationRequest.php |
| scheduled_end_time | required, date_format:H:i, after:scheduled_start_time | ExamAllocationRequest.php |
| location | nullable, string, max:100 | ExamAllocationRequest.php |
| scheduled_date | optional, date (if filled) | ExamAllocationRequest.php |

### 1.9 LmsHomework — HomeworkRequest
| Field | Rule | Source |
|---|---|---|
| class_id | required, exists:sch_classes | HomeworkRequest.php |
| section_id | nullable, exists:sch_sections | HomeworkRequest.php |
| subject_id | required, exists:sch_subjects | HomeworkRequest.php |
| topic_id | nullable, exists:slb_topics | HomeworkRequest.php |
| lesson_id | nullable, exists:slb_lessons | HomeworkRequest.php |
| title | required, string, max:255 | HomeworkRequest.php |
| description | required, string | HomeworkRequest.php |
| submission_type_id | required, exists:sys_dropdowns | HomeworkRequest.php |
| is_gradable | boolean | HomeworkRequest.php |
| max_marks | nullable, numeric, min:0, max:999.99 | HomeworkRequest.php |
| passing_marks | nullable, numeric, min:0, max:999.99, lte:max_marks | HomeworkRequest.php |
| difficulty_level_id | nullable, exists:slb_complexity_level | HomeworkRequest.php |
| assign_date | required, date, after_or_equal:today (create) OR just date (update) | HomeworkRequest.php |
| due_date | required, date, after:assign_date | HomeworkRequest.php |
| allow_late_submission | boolean | HomeworkRequest.php |
| auto_publish_score | boolean | HomeworkRequest.php |
| release_condition_id | nullable, exists:sys_dropdowns | HomeworkRequest.php |
| status_id | required, exists:sys_dropdowns | HomeworkRequest.php |
| is_active | boolean | HomeworkRequest.php |
| academic_session_id | NOT in request — GAP (in model fillable but not validated) | Derived from code |

---

## 2. CRUD CONDITIONS

### 2.1 Syllabus Module
| Entity | Create Condition | Edit Condition | Delete Condition | Restore Condition | Force Delete |
|---|---|---|---|---|---|
| Lesson | Auth + (no explicit policy found) | Auth + (no explicit policy found) | Soft delete only | If soft-deleted | Auth |
| Topic | Auth + (no explicit policy found) | Auth + (no explicit policy found) | Children warning missing | If soft-deleted | Auth |
| BloomTaxonomy | Auth | Auth | Soft delete | If soft-deleted | Auth |
| QuestionType | Auth | Auth | Soft delete | If soft-deleted | Auth |
| SyllabusSchedule | Auth | Auth | Soft delete | If soft-deleted | Auth |

### 2.2 LmsQuiz Module
| Entity | Create | Edit | Delete | Restore | Force Delete |
|---|---|---|---|---|---|
| Quiz | `tenant.quize.create` | `tenant.quize.update` (no publish guard) | `tenant.quize.delete` | `tenant.quize.restore` | `tenant.quize.forceDelete` |
| QuizAllocation | No policy found | No policy found | No policy found | No policy found | No policy found |
| QuizQuestion | No policy found | No policy found | No policy found | No policy found | No policy found |
| AssessmentType | Auth (no policy found) | Auth | Auth | Auth | Auth |
| DifficultyConfig | Auth | Auth | Auth | Auth | Auth |

### 2.3 LmsQuests Module
| Entity | Create | Edit | Delete | Restore | Force Delete | Publish | Duplicate |
|---|---|---|---|---|---|---|---|
| Quest | `tenant.quest.create` | `tenant.quest.update` | `tenant.quest.delete` | `tenant.quest.restore` | `tenant.quest.forceDelete` | `tenant.quest.publish` + canPublish() | `tenant.quest.duplicate` |
| QuestScope | `tenant.quest-scope.*` | Same | Same | Same | Same | N/A | N/A |
| QuestQuestion | `tenant.quest-question.*` | Same | Same | Same | Same | N/A | N/A |
| QuestAllocation | `tenant.quest-allocation.*` | Same | Same | Same | Same | N/A | N/A |

**Quest canPublish() conditions:**
1. questQuestions().count() > 0
2. questQuestions().count() === total_questions
3. validateSettings() returns empty array
4. academic_session_id, class_id, subject_id, lesson_id all set

### 2.4 LmsExam Module
| Entity | Create | Edit | Delete | Restore | Force Delete | Extra |
|---|---|---|---|---|---|---|
| Exam | `tenant.exam.create` | `tenant.exam.update` | `tenant.exam.delete` | `tenant.exam.restore` | `tenant.exam.forceDelete` | import, export, print |
| ExamPaper | `tenant.exam-paper.*` | Same | Same | Same | Same | - |
| ExamScope | `tenant.exam-scope.*` | Same | Same | Same | Same | - |
| ExamBlueprint | `tenant.exam-blueprint.*` | Same | Same | Same | Same | - |
| ExamPaperSet | `tenant.paper-set.*` | Same | Same | Same | Same | - |
| PaperSetQuestion | `tenant.paper-set-question.*` | Same | Same | Same | Same | bulk-store, bulk-destroy, update-ordinal, update-marks, update-compulsory |
| ExamStudentGroup | `tenant.exam-student-group.*` | Same | Same | Same | Same | - |
| ExamGroupMember | `tenant.exam-group-member.*` | Same | Same | Same | Same | getGroupDetails |
| ExamAllocation | `tenant.exam-allocation.*` | Same | Same | Same | Same | paperSets, sections, examGroups, students AJAX |
| ExamType | `tenant.exam-type.*` | Same | Same | Same | Same | - |
| ExamStatusEvent | `tenant.exam-status-event.*` | Same | Same | Same | Same | - |

### 2.5 LmsHomework Module
| Entity | Create | Edit | Delete | Notes |
|---|---|---|---|---|
| Homework | Auth (NO POLICY) | Auth + isEditable() = status is DRAFT | Auth + isDeletable() = 0 submissions | GAP: no policy |
| HomeworkSubmission | Auth (NO POLICY) | Auth | Auth | GAP: no policy |
| TriggerEvent | Auth | Auth | Auth | - |
| ActionType | Auth | Auth | Auth | - |
| RuleEngineConfig | Auth | Auth | Auth | - |

**isEditable():** `status_id == config('lmshomework.status.draft')`
**isDeletable():** `submission_count == 0`

### 2.6 QuestionBank Module
| Entity | Create | Edit | Delete | Notes |
|---|---|---|---|---|
| QuestionBank | `tenant.question-bank.create` | `tenant.question-bank.update` | `tenant.question-bank.delete` | No review gate on edit |
| QuestionMediaStore | `tenant.question-media-store.*` | Same | Same | - |
| QuestionStatistic | `tenant.question-statistic.*` | Same | Same | - |
| QuestionTag | `tenant.question-tag.*` | Same | Same | - |
| QuestionUsageType | `tenant.question-usage-type.*` | Same | Same | - |
| QuestionVersion | `tenant.question-version.*` | Same | Same | - |
| AI Generate | Auth (no explicit policy on generator endpoints) | N/A | N/A | API keys hardcoded |

---

## 3. BUSINESS RULES

### 3.1 Syllabus Rules
| # | Rule | Source |
|---|---|---|
| S1 | Lesson name is unique per (academic_session + class + subject) | LessonRequest |
| S2 | Lesson code is globally unique | LessonRequest |
| S3 | Lesson ordinal is unique per (academic_session + class + subject) | LessonRequest |
| S4 | Topic name is unique per (lesson + parent) | TopicRequest |
| S5 | Topic level auto-computed: parent.level + 1, or 0 for root | Topic.php booted() |
| S6 | Topic path uses materialized path with TEMP placeholder on create | Topic.php booted() |
| S7 | Topic code auto-generated hierarchically with retry loop for uniqueness | Topic.php |
| S8 | Resource URL type must be one of: video, pdf, link, document, image, audio, ppt | LessonRequest |
| S9 | Resource URLs must be valid HTTP/HTTPS URLs | LessonRequest |
| S10 | Lessons submitted as batch array (lessons[]) in one POST | LessonRequest |

### 3.2 Quiz Rules
| # | Rule | Source |
|---|---|---|
| Q1 | max_attempts required when allow_multiple_attempts = true | QuizRequest |
| Q2 | Quiz available to students only when status=PUBLISHED AND is_active=true | Quiz.isAvailable() |
| Q3 | Quiz code globally unique; auto-generated from hierarchy + random suffix | Quiz.php boot() |
| Q4 | duration_minutes: 1-600 | QuizRequest |
| Q5 | negative_marks: 0-99.99 | QuizRequest |
| Q6 | passing_percentage: 0-100 | QuizRequest |
| Q7 | academic_session_id not validated with exists (gap) | QuizRequest |

### 3.3 Quest Rules
| # | Rule | Source |
|---|---|---|
| QS1 | Quest can only be published if canPublish() returns true | Quest.php |
| QS2 | canPublish requires: questions > 0, count matches total_questions, settings valid, academic hierarchy complete | Quest.php |
| QS3 | Duplicate sets title + " (Copy)", status = DRAFT | Quest.php |
| QS4 | Quest allocation target must be active | QuestAllocationRequest |
| QS5 | Due date must be future (after_or_equal:now) | QuestAllocationRequest |
| QS6 | Cut-off date must be >= due_date | QuestAllocationRequest |
| QS7 | Result publish date only allowed when is_auto_publish_result = true | QuestAllocationRequest |
| QS8 | All allocation dates capped at 2 years in future | QuestAllocationRequest |
| QS9 | Academic hierarchy fields are nullable in QuestRequest (gap vs Quiz) | QuestRequest |
| QS10 | duration_minutes max: 300 (Quiz allows 600) | QuestRequest |
| QS11 | pending flag is boolean, unique to Quest, purpose undefined | QuestRequest |

### 3.4 Exam Rules
| # | Rule | Source |
|---|---|---|
| E1 | exam_type unique per (academic_session + class) | ExamRequest |
| E2 | start_date must be <= end_date | ExamRequest |
| E3 | end_date must be >= start_date | ExamRequest |
| E4 | ONLINE paper: show_result_type required | ExamPaperRequest |
| E5 | ONLINE paper with SCHEDULED result: scheduled_result_at required and must be after:now | ExamPaperRequest |
| E6 | OFFLINE paper: offline_entry_mode required | ExamPaperRequest |
| E7 | paper_code unique per exam | ExamPaperRequest |
| E8 | Allocation end_time must be after start_time | ExamAllocationRequest |
| E9 | SECTION allocation requires section_id | ExamAllocationRequest |
| E10 | EXAM_GROUP allocation requires exam_group_id | ExamAllocationRequest |
| E11 | STUDENT allocation requires student_id | ExamAllocationRequest |
| E12 | Exam code auto-generated from session+class+examType+random | Exam.php boot() |
| E13 | Status stored as FK to lms_exam_status_events (dynamic) | Exam.php |

### 3.5 Homework Rules
| # | Rule | Source |
|---|---|---|
| HW1 | assign_date >= today on create; any date on update | HomeworkRequest |
| HW2 | due_date > assign_date | HomeworkRequest |
| HW3 | passing_marks <= max_marks | HomeworkRequest (lte:max_marks) |
| HW4 | Homework deletable only when submission_count == 0 | Homework.isDeletable() |
| HW5 | Homework editable only when status = DRAFT | Homework.isEditable() |
| HW6 | is_late on submission derived from submitted_at > homework.due_date | HomeworkSubmission model |
| HW7 | File submissions via Spatie MediaLibrary collection: homework_submission_files | HomeworkSubmission.php |
| HW8 | Rule engine scoped to applicable_class_group_id | RuleEngineConfig.php |
| HW9 | academic_session_id not validated in request (gap) | HomeworkRequest — gap |

### 3.6 QuestionBank Rules
| # | Rule | Source |
|---|---|---|
| QB1 | UUID stored as binary bytes; accessor returns readable UUID via BIN_TO_UUID | QuestionBank.php |
| QB2 | for_quiz, for_assessment, for_exam flags control module-level availability | QuestionBank.php scopes |
| QB3 | availability: GLOBAL/SCHOOL_ONLY/CLASS_ONLY controls cross-tenant access | QuestionBank.php scopes |
| QB4 | created_by_AI=true marks AI-generated questions | QuestionBank.php |
| QB5 | Only APPROVED questions should appear in assessments (gap: not enforced in routes) | Inferred from scopeApproved |
| QB6 | Questions can be linked to multiple topics via QuestionTopicJnt | QuestionBank.php |
| QB7 | AI keys hardcoded in controller — CRITICAL SECURITY GAP | AIQuestionGeneratorController.php |
| QB8 | Both AI providers inactive by default | AIQuestionGeneratorController.php |

---

## 4. PERMISSION / POLICY MATRIX

### 4.1 Quiz Permissions (QuizPolicy)
| Permission String | Controller Action |
|---|---|
| `tenant.quize.viewAny` | index() |
| `tenant.quize.view` | show() |
| `tenant.quize.create` | store() |
| `tenant.quize.update` | update() |
| `tenant.quize.delete` | destroy() |
| `tenant.quize.restore` | restore() |
| `tenant.quize.forceDelete` | forceDelete() |
| `tenant.quize.status` | toggleStatus() |

### 4.2 Quest Permissions (QuestPolicy)
| Permission String | Controller Action |
|---|---|
| `tenant.quest.viewAny` | index() |
| `tenant.quest.view` | show() |
| `tenant.quest.create` | store() |
| `tenant.quest.update` | update() |
| `tenant.quest.delete` | destroy() |
| `tenant.quest.restore` | restore() |
| `tenant.quest.forceDelete` | forceDelete() |
| `tenant.quest.status` | toggleStatus() |
| `tenant.quest.duplicate` | duplicate() |
| `tenant.quest.publish` | publish() |
| `tenant.quest.archive` | archive() |
| `tenant.quest.manageQuestions` | QuestQuestionController actions |
| `tenant.quest.manageAllocations` | QuestAllocationController actions |

### 4.3 Exam Permissions (ExamPolicy)
| Permission String | Action |
|---|---|
| `tenant.exam.viewAny` | index() |
| `tenant.exam.view` | show() |
| `tenant.exam.status` | toggleStatus() |
| `tenant.exam.create` | store() |
| `tenant.exam.update` | update() |
| `tenant.exam.delete` | destroy() |
| `tenant.exam.restore` | restore() |
| `tenant.exam.forceDelete` | forceDelete() |
| `tenant.exam.import` | (not yet implemented) |
| `tenant.exam.export` | (not yet implemented) |
| `tenant.exam.print` | (not yet implemented) |

### 4.4 QuestionBank Permissions (QuestionBankPolicy)
| Permission String | Action |
|---|---|
| `tenant.question-bank.viewAny` | index() |
| `tenant.question-bank.view` | show() |
| `tenant.question-bank.create` | store() |
| `tenant.question-bank.update` | update() |
| `tenant.question-bank.delete` | destroy() |
| `tenant.question-bank.restore` | restore() |
| `tenant.question-bank.forceDelete` | forceDelete() |
| `tenant.question-bank.status` | toggleStatus() |
| `tenant.question-bank.print` | print() |

### 4.5 QuesTypeSpecificity / SyllabusSchedule Permissions
| Permission String | Action | Note |
|---|---|---|
| `tenant.ques-type-specificity.viewAny` | index() | Policy file named SyllabusSchedulePolicy |
| `tenant.ques-type-specificity.view` | show() | |
| `tenant.ques-type-specificity.create` | store() | |
| `tenant.ques-type-specificity.update` | update() | |
| `tenant.ques-type-specificity.delete` | destroy() | |
| `tenant.ques-type-specificity.restore` | restore() | |
| `tenant.ques-type-specificity.forceDelete` | forceDelete() | |
| `tenant.ques-type-specificity.status` | toggleStatus() | |

### 4.6 Policy Gaps Summary
| Module | Missing Policies |
|---|---|
| Syllabus | LessonPolicy, TopicPolicy, BloomTaxonomyPolicy, CognitiveSkillPolicy, CompetencyPolicy, ComplexityLevelPolicy, PerformanceCategoryPolicy, GradeDivisionPolicy |
| LmsQuiz | QuizAllocationPolicy, QuizQuestionPolicy, AssessmentTypePolicy, DifficultyDistributionConfigPolicy |
| LmsHomework | HomeworkPolicy (CRITICAL), HomeworkSubmissionPolicy, TriggerEventPolicy, ActionTypePolicy, RuleEngineConfigPolicy |

---

## 5. WORKFLOW / STATUS LIFECYCLE

### 5.1 Quiz Lifecycle
```
DRAFT ──► PUBLISHED ──► ARCHIVED
  │                         ▲
  └─────────────────────────┘ (no enforcement found)
```
- No code prevents moving from PUBLISHED back to DRAFT
- No code prevents editing a PUBLISHED quiz
- `is_active` flag independent of status; both must be true for student access

### 5.2 Quest Lifecycle
```
DRAFT ──► (canPublish() check) ──► PUBLISHED ──► ARCHIVED
  ▲                                      │
  └──────── restoreQuest() ◄─────────────┘
```
- `canPublish()` validates questions, count, settings, hierarchy
- `publish()` sets status=PUBLISHED, published_at=now()
- `archive()` sets status=ARCHIVED, is_active=false
- `restoreQuest()` sets status=DRAFT, is_active=true
- `pending` flag exists but lifecycle meaning undefined

### 5.3 Exam Lifecycle
```
DRAFT ──► PUBLISHED ──► CONCLUDED ──► ARCHIVED
```
- Status stored as FK to `lms_exam_status_events` table
- Status transitions are configurable (no hard-coded ENUM on the model itself)
- No state machine enforcement found in code

### 5.4 Exam Paper Lifecycle
- Same status tracking via `status_id` → `lms_exam_status_events`
- ONLINE/OFFLINE mode affects which fields are required

### 5.5 Homework Lifecycle
```
DRAFT ──► PUBLISHED ──► (students submit) ──► GRADED
```
- Status stored via `status_id` FK to `sys_dropdowns`
- isEditable() = status is DRAFT
- isDeletable() = no submissions

### 5.6 Homework Submission Lifecycle
```
SUBMITTED ──► GRADED (teacher reviews via review endpoint)
```
- `is_late` = submitted_at > homework.due_date
- marks_obtained set on grading
- teacher_feedback provided on grading

### 5.7 Question Review Lifecycle
```
DRAFT ──► PENDING_REVIEW ──► APPROVED
                          └──► REJECTED ──► DRAFT (rework)
```
- `ques_reviewed_status`, `ques_reviewed_by`, `ques_reviewed_at` track review
- No code-enforced transitions found

---

## 6. ALLOCATION RULES

### 6.1 Common Allocation Types (Quiz, Quest, Exam)
| Type | Required Field | Target Table |
|---|---|---|
| CLASS | class_id | sch_classes |
| SECTION | section_id (+ class_id) | sch_sections |
| GROUP / EXAM_GROUP | group_id / exam_group_id | sch_entity_groups / lms_exam_student_groups |
| STUDENT | student_id | std_students |

### 6.2 Quiz Allocation Special Rules
- Uses polymorphic `(target_table_name, target_id)` — non-standard morph columns
- `published_at` controls when quiz becomes visible
- `due_date`: submission deadline
- `cut_off_date`: final access deadline
- `is_auto_publish_result` + `result_publish_date`: controls result release

### 6.3 Quest Allocation Special Rules
- Target must be active (`is_active = true`) — validated in request
- `due_date` must be future date
- `cut_off_date >= due_date`
- `result_publish_date >= due_date`, only when auto_publish_result=true
- All dates: max 2 years in future

### 6.4 Exam Allocation Special Rules
- Must specify `exam_paper_id` AND `paper_set_id`
- `scheduled_start_time` and `scheduled_end_time` required (H:i format)
- `scheduled_date` optional (defaults to exam's start_date)
- `location` optional (max 100 chars)

---

## 7. DATE / TIME RULES

| Rule | Field | Module | Source |
|---|---|---|---|
| Lesson scheduled_year_week format: YYYYWW | scheduled_year_week | Syllabus | LessonRequest |
| Range: 202001-210052 | scheduled_year_week | Syllabus | LessonRequest |
| assign_date >= today on CREATE | assign_date | Homework | HomeworkRequest |
| assign_date can be past on UPDATE | assign_date | Homework | HomeworkRequest |
| due_date > assign_date | due_date | Homework | HomeworkRequest |
| due_date >= now on CREATE | due_date | Quest allocation | QuestAllocationRequest |
| cut_off_date >= due_date | cut_off_date | Quest allocation | QuestAllocationRequest |
| result_publish_date >= due_date | result_publish_date | Quest allocation | QuestAllocationRequest |
| All allocation dates max 2 years | all dates | Quest allocation | QuestAllocationRequest |
| Exam start_date <= end_date | start_date | Exam | ExamRequest |
| scheduled_result_at > now | scheduled_result_at | ExamPaper | ExamPaperRequest |
| scheduled_end_time > scheduled_start_time (H:i) | times | Exam allocation | ExamAllocationRequest |

---

## 8. AUTO-GENERATION RULES

### 8.1 Lesson
- No auto-code generation (code required manually in batch form)

### 8.2 Topic Code
Pattern: `{CLASS_CODE}_{SUBJECT_CODE}_{LESSON_CODE}_{LEVEL_PREFIX}{NN}`
Level prefixes: TOP (0), SUB (1), MIN (2), SMT (3), MIC (4), NAN (5), ULT (6)
Sub-topic: `{PARENT_CODE}_{LEVEL_PREFIX}{NN}`
- NN is 2-digit, incremented from existing max
- Retry loop ensures uniqueness

### 8.3 Quiz Code
Pattern: `QUIZ_{SESSION_CODE}_{CLASS_CODE}_{SUBJECT_CODE}_{LESSON_CODE}_{TOPIC_CODE_8CHARS}_{RANDOM_4}`
- GEN used when any part is unavailable
- Uniqueness ensured via counter suffix

### 8.4 Quest Code
Pattern: `QUEST_{SESSION_CODE}_{CLASS_CODE}_{SUBJECT_CODE}_{LESSON_CODE}_{RANDOM_6}`
- Uniqueness ensured via counter suffix
- Duplicate: code + `_COPY`

### 8.5 Exam Code
Pattern: `EXAM_{SESSION_CODE}_{CLASS_CODE}_{EXAM_TYPE_CODE}_{RANDOM_6}`
- Uniqueness ensured via counter suffix
- On update: if code changed and conflicts, appends `_{RANDOM_4}`

### 8.6 Question Bank UUID
- `Str::uuid()->getBytes()` — binary UUID
- Accessor: `BIN_TO_UUID(?)` MySQL function call
- Not compatible with SQLite

---

## 9. MODULE DEPENDENCY RULES

| Module | Depends On | Key Entities Used |
|---|---|---|
| Syllabus | SchoolSetup | SchoolClass, Subject, Section, OrganizationAcademicSession |
| Syllabus | SyllabusBooks | BokBook |
| Syllabus | Prime | User |
| LmsQuiz | Syllabus | Lesson, Topic, ComplexityLevel |
| LmsQuiz | SchoolSetup | SchoolClass, Subject, Section, EntityGroup |
| LmsQuiz | QuestionBank | qns_questions_bank |
| LmsQuiz | Prime | AcademicSession, User |
| LmsQuiz | StudentProfile | Student |
| LmsQuests | LmsQuiz | lms_assessment_types, lms_difficulty_distribution_configs |
| LmsQuests | Syllabus, SchoolSetup, QuestionBank, Prime, StudentProfile | (same as Quiz) |
| LmsExam | Syllabus | Lesson, Topic, QuestionType, GradeDivisionMaster |
| LmsExam | SchoolSetup | SchoolClass, Subject, Section |
| LmsExam | QuestionBank | questions |
| LmsExam | LmsQuiz | DifficultyDistributionConfig |
| LmsExam | Prime | AcademicSession, User |
| LmsExam | StudentProfile | Student |
| LmsHomework | Syllabus | Topic, Lesson, ComplexityLevel |
| LmsHomework | SchoolSetup | SchoolClass, Section, SchClassGroupsJnt |
| LmsHomework | StudentProfile | Student |
| LmsHomework | Prime | User, Dropdown |
| LmsHomework | GlobalMaster | Dropdown (HomeworkSubmission) |
| QuestionBank | Syllabus | QuestionType, BloomTaxonomy, CognitiveSkill, ComplexityLevel, QueTypeSpecificity, Topic, Lesson, Competencie, PerformanceCategory, Book |
| QuestionBank | SchoolSetup | SchoolClass, Subject, Section, EntityGroup |
| QuestionBank | StudentProfile | Student |
| QuestionBank | Prime | User |
| QuestionBank | SyllabusBooks | Book |

---

## 10. COMMON PLATFORM RULES

| # | Rule | Applies To |
|---|---|---|
| P1 | All routes require `auth` + `verified` middleware | All 6 modules |
| P2 | Soft delete available on all main entities | All 6 modules |
| P3 | Restore available after soft delete | All 6 modules |
| P4 | Force delete for permanent removal | All 6 modules |
| P5 | Toggle status endpoint on all entities | All 6 modules |
| P6 | Trash view for soft-deleted records | All 6 modules |
| P7 | is_active flag independent of deleted_at | All 6 modules |
| P8 | All modules are tenant-scoped (multi-tenancy) | All 6 modules |
| P9 | Table prefix conventions enforced (slb_, lms_, qns_) | All 6 modules |
| P10 | UUID auto-generated on create for most entities | All 6 modules |
| P11 | created_by, updated_by audit fields on key entities | All 6 modules |
| P12 | Policy permissions follow pattern: tenant.{resource}.{action} | All 6 modules |
| P13 | AJAX cascade: sections → subject-groups → subjects → lessons → topics | Quiz, Quest, Exam, QB |
| P14 | Bulk store/destroy for question assignment | Quiz, Quest, Exam |
| P15 | Update ordinal (reorder) for questions | Quiz, Quest, Exam |
| P16 | Update marks (mark override per question) | Quiz, Quest, Exam |

---

## ADDENDUM — DIFFICULTY LEVEL ENGINE RULES
**Added:** 2026-03-19 (Round 2 code inspection)
**Source:** DifficultyDistributionConfigController, QuizQuestionController, PaperSetQuestionController, ExamPaperController, ExamPaperRequest, DifficultyDistributionConfigRequest — all derived from code.

---

### 11. DIFFICULTY DISTRIBUTION CONFIG — VALIDATION RULES

| Field | Rule | Source |
|---|---|---|
| code | required, string, max:50, globally unique in `lms_difficulty_distribution_configs` (ignore self on update) | DifficultyDistributionConfigRequest |
| name | required, string, max:100 | DifficultyDistributionConfigRequest |
| description | nullable, string, max:255 | DifficultyDistributionConfigRequest |
| usage_type_id | required, exists:qns_question_usage_type | DifficultyDistributionConfigRequest |
| is_active | sometimes, boolean | DifficultyDistributionConfigRequest |
| rules | required, array, min:1 (at least one rule row must be submitted) | DifficultyDistributionConfigRequest |
| rules.*.question_type_id | required, exists:slb_question_types | DifficultyDistributionConfigRequest |
| rules.*.complexity_level_id | required, exists:slb_complexity_level | DifficultyDistributionConfigRequest |
| rules.*.bloom_id | nullable, exists:slb_bloom_taxonomy | DifficultyDistributionConfigRequest |
| rules.*.cognitive_skill_id | nullable, exists:slb_cognitive_skill | DifficultyDistributionConfigRequest |
| rules.*.ques_type_specificity_id | nullable, exists:slb_ques_type_specificity | DifficultyDistributionConfigRequest |
| rules.*.min_percentage | required, numeric, min:0, max:100 | DifficultyDistributionConfigRequest |
| rules.*.max_percentage | required, numeric, min:0, max:100 | DifficultyDistributionConfigRequest |
| rules.*.marks_per_question | nullable, numeric, min:0 | DifficultyDistributionConfigRequest |
| rules.*.is_active | sometimes, boolean | DifficultyDistributionConfigRequest |
| Cross-field | max_percentage must be >= min_percentage (withValidator after-hook) | DifficultyDistributionConfigRequest |

**prepareForValidation normalization:**
- Empty strings for `bloom_id`, `cognitive_skill_id`, `ques_type_specificity_id` are converted to `null`
- `is_active` on each rule defaults to `true` if not submitted

---

### 12. DIFFICULTY DISTRIBUTION — CRUD CONDITIONS

| Entity | Create Condition | Edit Condition | Delete (Soft) | Force Delete | Restore |
|---|---|---|---|---|---|
| DifficultyDistributionConfig | `tenant.difficulty-config.create` | `tenant.difficulty-config.update` | `tenant.difficulty-config.delete` + sets is_active=false | `tenant.difficulty-config.forceDelete` + blocked if any Quiz uses it | `tenant.difficulty-config.restore` + sets is_active=true |
| DifficultyDistributionDetail | Created as child in Config's store/update transaction | Hard-deleted and re-created on every Config update | No direct soft delete | forceDeleted by Config forceDelete | N/A (re-created with parent) |

**forceDelete blocking rule:** If `Quiz.where('difficulty_config_id', $config->id)->exists()` returns true, force delete is blocked with error: "This difficulty configuration is currently used by one or more quizzes."

---

### 13. DIFFICULTY DISTRIBUTION — EXAM PAPER FIELDS

| Field | Rule | Source |
|---|---|---|
| difficulty_config_id | nullable, exists:lms_difficulty_distribution_configs | ExamPaperRequest |
| ignore_difficulty_config | boolean | ExamPaperRequest (prepareForValidation) |
| only_unused_questions | boolean | ExamPaperRequest |
| only_authorised_questions | boolean | ExamPaperRequest |

---

### 14. DIFFICULTY VALIDATION RULES AT QUESTION-ADD TIME (LmsQuiz + LmsExam)

These rules apply when `bulkStore` is called to add questions to a Quiz or Exam Paper Set.

| # | Rule | Mode | Source |
|---|---|---|---|
| DV1 | If `quiz.only_unused_questions = true`: any question found in `qns_question_usage_log` (for QUIZ context) → blocked with 422 | Hard block | QuizQuestionController.bulkStore |
| DV2 | If `quiz.only_authorised_questions = true`: any question with `for_quiz = 0` → blocked with 422 | Hard block | QuizQuestionController.bulkStore |
| DV3 | If `quiz.scope_topic_id` is set: questions with `topic_id ≠ scope_topic_id` → blocked with 422 | Hard block | QuizQuestionController.bulkStore |
| DV4 | If `quiz.difficulty_config_id` set AND `ignore_difficulty_config = false` AND distribution violated → blocked with 422 | Hard block (strict mode) | QuizQuestionController.validateDifficultyDistribution |
| DV5 | If `quiz.difficulty_config_id` set AND `ignore_difficulty_config = true` AND distribution violated → allowed with warning response | Soft warning | QuizQuestionController.bulkStore |
| DV6 | If `quiz.total_questions > 0` AND `(existing + new) > total_questions` → blocked with 422 | Hard block | QuizQuestionController.bulkStore |
| DV7 | Questions already in the quiz are excluded from search results | Filter | QuizQuestionController.search |
| DV8 | Same rules DV1-DV7 apply to Exam PaperSet (via PaperSetQuestionController) | Hard block | PaperSetQuestionController.bulkStore |

---

### 15. DIFFICULTY DISTRIBUTION ALGORITHM RULES

| # | Rule | Source |
|---|---|---|
| DA1 | If no active DifficultyDistributionDetail rows for the config → validation passes (no rules = no restriction) | QuizQuestionController.validateDifficultyDistribution |
| DA2 | `calculationBase = max(quiz.total_questions, currentTotalCount)` — uses declared total when available | QuizQuestionController |
| DA3 | PATH A (simple rules only — no optional fields): groups new questions by `question_type_id + complexity_level_id`. Unmatched combos → fail immediately | QuizQuestionController |
| DA4 | PATH B (complex rules with optional fields): matches each question using `findDifficultyRuleMatch()` which uses nullable-tolerant matching: exact on type+complexity, optional on bloom+cognitive+specificity | QuizQuestionController |
| DA5 | maxAllowed = `ceil(calculationBase × max_percentage / 100)` | QuizQuestionController |
| DA6 | minAllowed = `floor(calculationBase × min_percentage / 100)` — computed but NOT enforced server-side at add-time | QuizQuestionController |
| DA7 | Check: `(existing + new) > maxAllowed` → fail. Does NOT check `< minAllowed` — min is advisory only | QuizQuestionController |
| DA8 | Marks override: if matching rule has `marks_per_question != null`, that value is stored as `QuizQuestion.marks_override` | QuizQuestionController.bulkStore |
| DA9 | On bulkDestroy, `qns_question_usage_log` rows are `forceDelete()`-ed (permanent removal, no soft delete) | QuizQuestionController.bulkDestroy |
| DA10 | Ordinals are recalculated after bulkDestroy to keep sequential ordering | QuizQuestionController.recalculateOrdinals |

---

### 16. DIFFICULTY LEVEL USAGE BY MODULE

| Module | Difficulty Feature | Implementation | Level |
|---|---|---|---|
| LmsQuiz | Full difficulty config + distribution validation + marks override | DifficultyDistributionConfig FK on lms_quizzes, `ignore_difficulty_config` flag | Full engine |
| LmsExam | Same config (cross-module FK), same validation via PaperSetQuestionController | `difficulty_config_id` + `ignore_difficulty_config` on lms_exam_papers | Full engine |
| LmsHomework | Simple difficulty label only | `difficulty_level_id` FK → `slb_complexity_level` (nullable) | Label only |
| LmsQuests | No difficulty config found (QuestQuestion controller not inspected fully) | Not present in Quest model fillable or QuestRequest | None / needs confirmation |
| Syllabus | Complexity Level master CRUD (`slb_complexity_level`) — source for all labels | Managed in Syllabus module | Master data |
| QuestionBank | Stores difficulty attributes per question: `complexity_level_id`, `bloom_id`, `cognitive_skill_id`, `ques_type_specificity_id` | On `qns_questions_bank` table | Per-question attributes |

---

### 17. EXAM BLUEPRINT RULES

| # | Rule | Source |
|---|---|---|
| EB1 | Blueprint belongs to an ExamPaper (`exam_paper_id` required, exists:lms_exam_papers) | ExamBlueprintRequest |
| EB2 | `section_name` max 50 chars, required | ExamBlueprintRequest |
| EB3 | `question_type_id` nullable — a section can be question-type agnostic | ExamBlueprintRequest |
| EB4 | `ordinal` required, min:1 — controls display order of sections | ExamBlueprintRequest |
| EB5 | `marks_per_question` nullable — if null, marks set individually per question | ExamBlueprintRequest |
| EB6 | `total_marks` must equal `total_questions × marks_per_question` in theory — NO code enforcement found | needs confirmation |
| EB7 | All Gate::authorize() calls in ExamBlueprintController are commented out — no authorization | derived from code (CRITICAL GAP) |
| EB8 | Blueprint section counts are advisory only — no server-side enforcement against PaperSetQuestion actual counts | derived from code |
