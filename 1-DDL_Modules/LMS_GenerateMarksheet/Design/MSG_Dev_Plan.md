# MSG — MarksheetGeneration Module: Development Plan
**Version:** 1.0 | **Date:** 2026-04-13 | **Branch:** `marksheet-generation`

---

## Section 1 — Module Overview

| Item | Value |
|---|---|
| Module Name | MarksheetGeneration |
| Module Code | MSG |
| Branch | `marksheet-generation` |
| DB Prefix | `msh_*` |
| Module Type | Tenant |
| Tables | 23 |
| Controllers | 10 (estimated) |
| Models | 23 (one per table) |
| Services | 4 main + 6 score readers = 10 |
| Jobs | 1 (`ComputeMarksheetJob`) |
| FormRequests | ~18 |
| Policies | ~8 |
| Livewire Components | 2 (computation progress, result review grid) |
| Blade Views | ~18 |
| Test Files | ~10 (Pest, ~50 tests) |
| Migrations | 23 |
| Seeders | 1 (`MarksheetGenerationDatabaseSeeder`) |
| Estimated Complexity | **High** |

---

## Section 2 — Pre-Development Checklist

All items MUST be resolved before Sprint 1 begins.

### 2.1 Schema Verifications (run against actual tenant DB)

- [ ] **V-01:** `lms_exam_papers.mode` column exists as `ENUM('ONLINE','OFFLINE')` in actual migration
- [ ] **V-02:** `lms_exam_results.result_status` has values `PASS`, `FAIL`, `ABSENT`, `WITHHELD`
- [ ] **V-03:** `lms_exam_results.is_published` column exists (TINYINT)
- [ ] **V-04:** `lms_exam_types.code` values match expected codes (UT-1, UT-2, HY-EXAM, ANNUAL-EXAM, etc.)
- [ ] **V-05:** `lms_quiz_quest_results.assessment_type` ENUM('QUIZ','QUEST') and `assessment_id` (polymorphic INT) exist
- [ ] **V-06:** `lms_quiz_quest_results.is_published` column exists
- [ ] **V-07:** `lms_homework_submissions.marks_obtained` (DECIMAL 5,2) exists and `lms_homework.is_gradable` exists
- [ ] **V-08:** `slb_grade_division_master` has columns: `code`, `grading_type` ENUM('GRADE','DIVISION'), `min_percentage`, `max_percentage`, `board_code`, `scope`, `class_id`
- [ ] **V-09:** `sch_org_academic_sessions_jnt.id` is `SMALLINT UNSIGNED` (not INT)
- [ ] **V-10:** `sch_class_section_jnt` has `class_teacher_id` FK (for resolving class teacher for co-scholastic entry)

### 2.2 Open Questions (from Phase 1 Section 11)

| # | Question | Decision Needed From | Impact |
|---|---|---|---|
| Q-01 | `msh_source_components` — fixed 4 rows or school-extensible? | Brijesh | If extensible, add CRUD screen |
| Q-02 | Student with ZERO graded HW/Quiz — score = NULL or 0? | Brijesh | Affects computation logic |
| Q-03 | Best-of-N for unit tests — include in Sprint 1 or defer? | Brijesh | Adds ~2 days to Sprint 3 if included |
| Q-04 | IA marks entry — this module owns it (confirmed)? | Brijesh | Affects Sprint 2 scope |
| Q-05 | Attendance module (`att_*`) — exists or manual only? | Brijesh | Manual entry in Phase 1 |
| Q-06 | Co-Scholastic entry — this module owns it (confirmed)? | Brijesh | Affects Sprint 2 scope |
| Q-08 | Student subject list — from `sch_class_groups_jnt` or another source? | Brijesh | Critical for computation |
| **Q-13** | **Theory vs Practical paper — no `is_practical` flag on `lms_exam_papers`. Add flag or use convention?** | **Brijesh + LmsExam owner** | **Blocks practical split computation** |

### 2.3 Pre-Requisites (from other modules)

- [ ] **P-01:** LmsExam module must have exam results published (`lms_exam_results.is_published = 1`) for the target exams before computation can run
- [ ] **P-02:** SchoolSetup must have classes, sections, class-section junctions, and subjects configured for the academic session
- [ ] **P-03:** Students must be enrolled in `std_student_academic_sessions` for the target session
- [ ] **P-04:** `slb_grade_division_master` must have grading entries seeded (at least CBSE 9-point scale)
- [ ] **P-05:** `lms_exam_types` must have exam types seeded (UT-1, UT-2, UT-3, UT-4, HY-EXAM, ANNUAL-EXAM)
- [ ] **P-06:** BehaviouralAssessment module: `BehaviouralScoreService` interface must exist (even if stub) for co-scholastic Discipline grade

---

## Section 3 — Service Architecture

### 3.1 Main Services (4)

```
Service:     MarksheetConfigService
File:        Modules/MarksheetGeneration/app/Services/MarksheetConfigService.php
Namespace:   Modules\MarksheetGeneration\app\Services
Depends on:  —
Fires:       —

Key Methods:
  createTemplate(array $data): ConfigTemplate
    └── Creates template + validates exam_group linkage + grading schema existence
  updateTemplate(int $id, array $data): ConfigTemplate
    └── Updates template. Fails if is_locked = 1 (BR-MSG-027)
  addScholasticComponent(int $templateId, int $componentId, float $weightage): void
    └── Adds source component. Validates sum ≤ 100
  setExamWeightages(int $templateId, array $weightages): void
    └── Sets per-exam-type weightages. Validates sum = 100 (BR-MSG-003)
  assignTemplateToClass(int $templateId, int $classId): void
    └── Direct class assignment (overrides group)
  assignTemplateToGroup(int $templateId, int $groupId): void
    └── Group-level assignment (fallback)
  resolveTemplateForClass(int $classId, int $sessionId): ?ConfigTemplate
    └── Direct class → group inheritance → NULL (BR-MSG-005)
  lockTemplate(int $templateId): void
    └── Sets is_locked = 1. Called when schedule is published.
```

```
Service:     MarksheetComputationService
File:        Modules/MarksheetGeneration/app/Services/MarksheetComputationService.php
Namespace:   Modules\MarksheetGeneration\app\Services
Depends on:  ExamScoreReader, HomeworkScoreReader, QuizScoreReader,
             QuestScoreReader, BehaviouralScoreReader, AttendanceReader,
             MarksheetConfigService
Fires:       ComputationCompleted event

Key Methods:
  computeForSchedule(int $scheduleId): ComputationResult
    └── Main orchestrator. Validates pre-conditions, dispatches per-class-section.
        Returns { total_students, total_errors, duration_seconds }
  computeForClassSection(Schedule $schedule, int $classSectionId): void
    └── Loads students, resolves subjects, calls score readers, applies weightages,
        computes grades/rank/division/promotion. Chunked (50 students per batch).
  computeSubjectTotal(StudentSubjectContext $ctx): SubjectResult
    └── Aggregates exam + HW + Quiz + Quest + IA for one student-subject
  computeOverallResult(int $scheduleId, int $studentId): StudentResult
    └── Grand total, percentage, grade, division, promotion status
  computeRanks(int $scheduleId, int $classSectionId): void
    └── Dense ranking by grand_total DESC within class-section
  recompute(int $scheduleId): ComputationResult
    └── Deletes existing results, re-runs computation. Only if schedule unlocked.
```

```
Service:     MarksheetPublicationService
File:        Modules/MarksheetGeneration/app/Services/MarksheetPublicationService.php
Namespace:   Modules\MarksheetGeneration\app\Services
Depends on:  MarksheetConfigService
Fires:       MarksheetPublished, MarksheetUnlocked events

Key Methods:
  markAsReviewed(int $scheduleId): void
    └── Status COMPUTED → REVIEWED. Requires principal/coordinator role.
  publish(int $scheduleId): void
    └── Status REVIEWED → PUBLISHED. Locks template (BR-MSG-027). Notifies stakeholders.
  lock(int $scheduleId): void
    └── Status PUBLISHED → LOCKED. Final freeze.
  unlock(int $scheduleId, string $reason): void
    └── Status PUBLISHED/LOCKED → COMPUTED. Requires admin role.
        Writes reason to msh_computation_logs. (BR-MSG-017)
```

```
Service:     MarksheetPdfService
File:        Modules/MarksheetGeneration/app/Services/MarksheetPdfService.php
Namespace:   Modules\MarksheetGeneration\app\Services
Depends on:  —
Fires:       —

Key Methods:
  generateForStudent(int $scheduleId, int $studentId): string
    └── Returns PDF content (DomPDF). Inline styles, table layout.
        Includes: school header, scholastic matrix, co-scholastic, attendance,
        rank, division, promotion, signature placeholder.
  generateBulkForClassSection(int $scheduleId, int $classSectionId): string
    └── Returns ZIP of individual student PDFs.
  getSchoolHeader(): array
    └── Fetches school name, logo (base64), board affiliation from SchoolSetup config.
```

### 3.2 Score Reader Services (6)

All readers implement a common interface:

```php
interface ScoreReaderInterface
{
    /**
     * @return array<int, ScoreResult> Keyed by student_id
     * ScoreResult = { raw_score: ?float, max_score: ?float, count_items: int, has_absent: bool }
     */
    public function getScores(
        int $classSectionId,
        int $subjectId,
        int $academicSessionId,
        ?string $fromDate = null,
        ?string $toDate = null
    ): array;
}
```

| # | Service | Source Table | Key Filter |
|---|---|---|---|
| 1 | `ExamScoreReader` | `lms_exam_results` via `lms_exam_papers` → `lms_exams` | exam_type_id, subject_id, is_published=1 |
| 2 | `HomeworkScoreReader` | `lms_homework_submissions` via `lms_homework` | class_id, subject_id, status=GRADED, due_date in range |
| 3 | `QuizScoreReader` | `lms_quiz_quest_results` | assessment_type='QUIZ', subject via lms_quizzes, is_published=1 |
| 4 | `QuestScoreReader` | `lms_quiz_quest_results` | assessment_type='QUEST', subject via lms_quests, is_published=1 |
| 5 | `BehaviouralScoreReader` | via `BehaviouralScoreService` API | ba_config.is_result_integration_enabled=true |
| 6 | `AttendanceReader` | `msh_student_attendance` (Phase 1: manual) | schedule_id, student_id |

---

## Section 4 — Sprint-by-Sprint Development Plan

### Sprint 1 — Foundation & Configuration (2 weeks)

**Goal:** Module scaffolding, all 23 migrations, models, seeders, and the core configuration UI.

| # | Task | Est. | Deliverable |
|---|---|---|---|
| 1.1 | Module scaffolding: `php artisan module:make MarksheetGeneration` | 0.5d | Module structure |
| 1.2 | Create 23 tenant migrations in dependency order | 1d | `database/migrations/tenant/` |
| 1.3 | Create 23 Models with relationships, SoftDeletes, fillable, casts | 2d | `app/Models/` |
| 1.4 | Create Seeder: msh_source_components (4), msh_ia_component_types (4), sys_dropdown_table entries | 0.5d | `database/seeders/` |
| 1.5 | `MarksheetConfigService` — template CRUD, scholastic component + exam weightage management | 2d | `app/Services/MarksheetConfigService.php` |
| 1.6 | `ConfigTemplateController` + 4 FormRequests + Policy | 1.5d | Controllers, Requests, Policy |
| 1.7 | SC-MSG-01: Marksheet Type Master (CRUD) | 0.5d | Blade views |
| 1.8 | SC-MSG-03: Config Template Builder (create/edit, add components, weightage validation) | 1d | Blade views |
| 1.9 | SC-MSG-04: Exam Weightage Setup (per-exam % within Exam component) | 0.5d | Blade views |
| 1.10 | Tests: ConfigTemplateTest (6 tests) | 0.5d | Pest tests |

**Sprint 1 Exit Criteria:**
- [ ] All 23 tables created via `php artisan tenants:migrate`
- [ ] Seeders run successfully
- [ ] Config template CRUD works end-to-end
- [ ] Weightage sum validation enforced (sum = 100%)
- [ ] 6 Pest tests pass

---

### Sprint 2 — Class Groups, Exam Groups, IA, Co-Scholastic (1.5 weeks)

**Goal:** Complete all configuration screens. After Sprint 2, school admin can fully configure marksheet.

| # | Task | Est. | Deliverable |
|---|---|---|---|
| 2.1 | SC-MSG-07a: Class Group Management (CRUD + class assignment) | 1d | Views + Controller |
| 2.2 | SC-MSG-02: Exam Group Setup (create group + select exam types) | 1d | Views + Controller |
| 2.3 | SC-MSG-05: IA Component Setup (per template) | 0.5d | Views |
| 2.4 | SC-MSG-06: Co-Scholastic Area Setup (per template, BA linkage toggle) | 0.5d | Views |
| 2.5 | SC-MSG-07: Class/Group Template Assignment (with inheritance display) | 1d | Views + Controller |
| 2.6 | SC-MSG-08: Practical Config (class-subject grid, theory/practical split) | 1d | Views + Controller |
| 2.7 | `MarksheetConfigService` extension: class group CRUD, exam group CRUD, practical config, IA config | 1.5d | Service methods |
| 2.8 | Tests: ClassGroupTest (4), ExamGroupTest (4), PracticalConfigTest (4) | 0.5d | Pest tests |

**Sprint 2 Exit Criteria:**
- [ ] Admin can create class groups and assign classes
- [ ] Admin can create exam groups with exam types
- [ ] Admin can configure IA components and co-scholastic areas
- [ ] Admin can assign template to class or class-group
- [ ] Practical config works with theory/practical split validation
- [ ] 12 Pest tests pass

---

### Sprint 3 — Computation Engine (2.5 weeks)

**Goal:** Build the core result computation pipeline. This is the most complex sprint.

| # | Task | Est. | Deliverable |
|---|---|---|---|
| 3.1 | `ExamScoreReader` service (reads lms_exam_results via paper → exam → type joins) | 1.5d | Service |
| 3.2 | `HomeworkScoreReader` service (reads lms_homework_submissions, date range filter) | 0.5d | Service |
| 3.3 | `QuizScoreReader` + `QuestScoreReader` services (lms_quiz_quest_results, polymorphic join) | 1d | 2 Services |
| 3.4 | `BehaviouralScoreReader` service (delegates to BehaviouralScoreService — interface + stub) | 0.5d | Service + Interface |
| 3.5 | `AttendanceReader` service (reads msh_student_attendance) | 0.25d | Service |
| 3.6 | `MarksheetComputationService` — full algorithm (Steps A-G from RequirementSpec Section 10) | 3d | Core service |
| 3.7 | `ComputeMarksheetJob` — queued job, chunked per class-section, progress tracking | 1d | Job |
| 3.8 | SC-MSG-10: Marksheet Schedule Setup (create schedule, select class-sections) | 1d | Views + Controller |
| 3.9 | SC-MSG-09: Marksheet Schedule Dashboard (list, status, action buttons) | 0.5d | Views |
| 3.10 | SC-MSG-11: Computation Progress (Livewire polling, real-time job status) | 1d | Livewire component |
| 3.11 | SC-MSG-12a: IA Marks Entry grid (teacher enters per student per subject per IA component) | 1d | Views |
| 3.12 | SC-MSG-06a: Co-Scholastic Entry grid (class teacher enters A/B/C per student) | 0.5d | Views |
| 3.13 | SC-MSG-09a: Attendance Entry (working days + days present per student) | 0.5d | Views |
| 3.14 | Tests: ComputationTest (12 tests — all 5 sources, absent, null, BA disabled, rank, grade) | 1d | Pest tests |

**Sprint 3 Exit Criteria:**
- [ ] All 6 score readers work against test data
- [ ] Computation job completes for 100-student class in < 15 seconds
- [ ] Subject-wise, exam-wise marks matrix populated correctly
- [ ] Grades computed from `slb_grade_division_master`
- [ ] Rank computed (dense ranking)
- [ ] Promotion status derived (passed/failed/compartment)
- [ ] ABSENT and WITHHELD handled correctly (shown as AB/WH, not zero)
- [ ] IA marks and co-scholastic grades enterable by teacher
- [ ] 12 Pest tests pass

---

### Sprint 4 — Review, Publication & PDF (2 weeks)

**Goal:** Complete the result review workflow, publication lifecycle, and PDF generation.

| # | Task | Est. | Deliverable |
|---|---|---|---|
| 4.1 | `MarksheetPublicationService` — review, publish, lock, unlock + audit | 1.5d | Service |
| 4.2 | SC-MSG-12: Result Review Grid (Livewire: Student × Subject × Exam matrix, highlight anomalies) | 2d | Livewire component |
| 4.3 | SC-MSG-13: Individual Student Marksheet Preview (full marksheet layout matching PDF format) | 1d | Blade view |
| 4.4 | SC-MSG-14: Publication & Lock screen (publish, lock, unlock with reason) | 1d | Views + Controller |
| 4.5 | `MarksheetPdfService` — DomPDF template (inline styles, table layout, school header, signature) | 2d | Service + Blade template |
| 4.6 | SC-MSG-15: PDF Download (individual + bulk ZIP) | 0.5d | Controller method |
| 4.7 | Events: ComputationCompleted, MarksheetPublished, MarksheetUnlocked → Notification listeners | 1d | Events + Listeners |
| 4.8 | Tests: PublicationTest (5), PdfTest (4) | 1d | Pest tests |

**Sprint 4 Exit Criteria:**
- [ ] Principal can review computed results in matrix grid
- [ ] Publish/Lock/Unlock lifecycle works with audit trail
- [ ] Template locked on publish (BR-MSG-027)
- [ ] Unlock requires reason, writes to msh_computation_logs
- [ ] PDF marksheet generated for individual student (matches CBSE pattern)
- [ ] Bulk PDF download as ZIP works
- [ ] Notifications sent on publish
- [ ] 9 Pest tests pass

---

### Sprint 5 — Portal Integration & Polish (1 week)

**Goal:** Student/Parent portal views, edge case handling, and final testing.

| # | Task | Est. | Deliverable |
|---|---|---|---|
| 5.1 | StudentPortal: marksheet list + view endpoint (read-only, scoped to own student_id) | 1d | Controller + Views |
| 5.2 | ParentPortal: marksheet list + view endpoint (read-only, scoped to linked children) | 1d | Controller + Views |
| 5.3 | PDF download for student/parent (signed URL: `URL::temporarySignedRoute`) | 0.5d | Route + Controller |
| 5.4 | Edge cases: student with no exam results, student transferred mid-term, subject with 0 students | 0.5d | Service fixes |
| 5.5 | End-to-end integration test (full flow: config → compute → review → publish → portal view) | 1d | Pest test |
| 5.6 | Route registration in module's `web.php` with proper middleware and prefix | 0.5d | Routes |

**Sprint 5 Exit Criteria:**
- [ ] Student sees own published marksheets on portal
- [ ] Parent sees child's marksheets on portal
- [ ] PDF download uses signed URLs (expires 24h)
- [ ] No IDOR — student cannot see another student's marksheet
- [ ] Full end-to-end test passes
- [ ] All ~50 Pest tests pass

---

## Section 5 — File Structure

```
Modules/MarksheetGeneration/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── MarksheetTypeController.php
│   │   │   ├── ClassGroupController.php
│   │   │   ├── ExamGroupController.php
│   │   │   ├── ConfigTemplateController.php
│   │   │   ├── PracticalConfigController.php
│   │   │   ├── MarksheetScheduleController.php
│   │   │   ├── ComputationController.php
│   │   │   ├── ResultReviewController.php
│   │   │   ├── PublicationController.php
│   │   │   └── MarksheetPdfController.php
│   │   └── Requests/
│   │       ├── StoreMarksheetTypeRequest.php
│   │       ├── UpdateMarksheetTypeRequest.php
│   │       ├── StoreClassGroupRequest.php
│   │       ├── StoreExamGroupRequest.php
│   │       ├── StoreConfigTemplateRequest.php
│   │       ├── UpdateConfigTemplateRequest.php
│   │       ├── SetScholasticComponentsRequest.php
│   │       ├── SetExamWeightagesRequest.php
│   │       ├── SetIaComponentsRequest.php
│   │       ├── SetCoscholasticComponentsRequest.php
│   │       ├── AssignTemplateRequest.php
│   │       ├── StorePracticalConfigRequest.php
│   │       ├── StoreScheduleRequest.php
│   │       ├── TriggerComputationRequest.php
│   │       ├── UnlockScheduleRequest.php
│   │       ├── StoreIaMarksRequest.php
│   │       ├── StoreCoscholasticGradesRequest.php
│   │       └── StoreAttendanceRequest.php
│   ├── Jobs/
│   │   └── ComputeMarksheetJob.php
│   ├── Events/
│   │   ├── ComputationCompleted.php
│   │   ├── MarksheetPublished.php
│   │   └── MarksheetUnlocked.php
│   ├── Listeners/
│   │   ├── NotifyOnComputationCompleted.php
│   │   ├── NotifyOnMarksheetPublished.php
│   │   └── LogMarksheetUnlock.php
│   ├── Contracts/
│   │   └── ScoreReaderInterface.php
│   ├── Models/
│   │   ├── MarksheetType.php
│   │   ├── SourceComponent.php
│   │   ├── IaComponentType.php
│   │   ├── ClassGroup.php
│   │   ├── ClassGroupItem.php
│   │   ├── ExamGroup.php
│   │   ├── ExamGroupItem.php
│   │   ├── ConfigTemplate.php
│   │   ├── TemplateScholasticComponent.php
│   │   ├── TemplateExamWeightage.php
│   │   ├── TemplateIaComponent.php
│   │   ├── TemplateCoscholasticComponent.php
│   │   ├── ClassConfig.php
│   │   ├── SubjectPracticalConfig.php
│   │   ├── MarksheetSchedule.php
│   │   ├── ScheduleClass.php
│   │   ├── StudentResult.php
│   │   ├── StudentSubjectResult.php
│   │   ├── StudentSubjectExamMarks.php
│   │   ├── StudentIaMarks.php
│   │   ├── StudentCoscholasticResult.php
│   │   ├── StudentAttendance.php
│   │   └── ComputationLog.php
│   ├── Policies/
│   │   ├── ConfigTemplatePolicy.php
│   │   ├── MarksheetSchedulePolicy.php
│   │   ├── StudentResultPolicy.php
│   │   ├── ClassGroupPolicy.php
│   │   ├── ExamGroupPolicy.php
│   │   ├── PracticalConfigPolicy.php
│   │   ├── IaMarksPolicy.php
│   │   └── PublicationPolicy.php
│   ├── Services/
│   │   ├── MarksheetConfigService.php
│   │   ├── MarksheetComputationService.php
│   │   ├── MarksheetPublicationService.php
│   │   ├── MarksheetPdfService.php
│   │   └── ScoreReaders/
│   │       ├── ExamScoreReader.php
│   │       ├── HomeworkScoreReader.php
│   │       ├── QuizScoreReader.php
│   │       ├── QuestScoreReader.php
│   │       ├── BehaviouralScoreReader.php
│   │       └── AttendanceReader.php
│   └── Providers/
│       ├── MarksheetGenerationServiceProvider.php
│       ├── RouteServiceProvider.php
│       └── EventServiceProvider.php
├── database/
│   ├── migrations/ (empty — tenant migrations go in database/migrations/tenant/)
│   └── seeders/
│       └── MarksheetGenerationDatabaseSeeder.php
├── resources/
│   └── views/
│       ├── marksheet-types/
│       │   ├── index.blade.php
│       │   └── create-edit.blade.php
│       ├── class-groups/
│       │   ├── index.blade.php
│       │   └── create-edit.blade.php
│       ├── exam-groups/
│       │   ├── index.blade.php
│       │   └── create-edit.blade.php
│       ├── config-templates/
│       │   ├── index.blade.php
│       │   ├── create-edit.blade.php
│       │   ├── exam-weightages.blade.php
│       │   ├── ia-components.blade.php
│       │   └── coscholastic.blade.php
│       ├── class-assignment/
│       │   └── index.blade.php
│       ├── practical-config/
│       │   └── index.blade.php
│       ├── schedules/
│       │   ├── index.blade.php
│       │   ├── create-edit.blade.php
│       │   └── computation-progress.blade.php
│       ├── results/
│       │   ├── review-grid.blade.php
│       │   ├── student-preview.blade.php
│       │   └── publication.blade.php
│       ├── entry/
│       │   ├── ia-marks.blade.php
│       │   ├── coscholastic.blade.php
│       │   └── attendance.blade.php
│       └── pdf/
│           └── marksheet_pdf.blade.php
├── routes/
│   └── web.php
├── tests/
│   └── Feature/
│       ├── ConfigTemplateTest.php
│       ├── ClassGroupTest.php
│       ├── ExamGroupTest.php
│       ├── PracticalConfigTest.php
│       ├── MarksheetScheduleTest.php
│       ├── ComputationTest.php
│       ├── PublicationTest.php
│       ├── PdfTest.php
│       ├── IaMarksTest.php
│       └── EndToEndTest.php
├── config/
├── composer.json
├── module.json
└── vite.config.js
```

---

## Section 6 — Permission Matrix

| Permission String | Super Admin | Principal | Coordinator | Class Teacher | Subject Teacher | Student | Parent |
|---|---|---|---|---|---|---|---|
| `msg.config.view` | Yes | Yes | Yes | No | No | No | No |
| `msg.config.create` | Yes | Yes | No | No | No | No | No |
| `msg.config.update` | Yes | Yes | No | No | No | No | No |
| `msg.config.delete` | Yes | No | No | No | No | No | No |
| `msg.class-group.manage` | Yes | Yes | No | No | No | No | No |
| `msg.exam-group.manage` | Yes | Yes | Yes | No | No | No | No |
| `msg.practical.manage` | Yes | Yes | Yes | No | No | No | No |
| `msg.schedule.view` | Yes | Yes | Yes | Yes | No | No | No |
| `msg.schedule.create` | Yes | Yes | No | No | No | No | No |
| `msg.schedule.update` | Yes | Yes | No | No | No | No | No |
| `msg.compute.trigger` | Yes | Yes | No | No | No | No | No |
| `msg.compute.progress` | Yes | Yes | Yes | Yes | No | No | No |
| `msg.ia.entry` | Yes | Yes | Yes | Yes | Yes | No | No |
| `msg.coscholastic.entry` | Yes | Yes | Yes | Yes | No | No | No |
| `msg.attendance.entry` | Yes | Yes | Yes | Yes | No | No | No |
| `msg.review.view` | Yes | Yes | Yes | Yes | No | No | No |
| `msg.publish.execute` | Yes | Yes | No | No | No | No | No |
| `msg.publish.lock` | Yes | Yes | No | No | No | No | No |
| `msg.publish.unlock` | Yes | No | No | No | No | No | No |
| `msg.report.class` | Yes | Yes | Yes | Yes | No | No | No |
| `msg.report.student` | Yes | Yes | Yes | Yes | Yes | **Own only** | **Child only** |
| `msg.report.download` | Yes | Yes | Yes | Yes | Yes | **Own only** | **Child only** |

---

## Section 7 — Test Plan

| # | File | Tests | Key Scenarios |
|---|---|---|---|
| 1 | `ConfigTemplateTest` | 6 | CRUD, weightage sum validation (=100%), immutability when locked, grading schema link |
| 2 | `ClassGroupTest` | 4 | CRUD groups, add/remove classes, no duplicate class across groups |
| 3 | `ExamGroupTest` | 4 | CRUD groups, add/remove exam types, session scoping |
| 4 | `PracticalConfigTest` | 4 | Create, theory+practical sum validation, subject without practical, session scoping |
| 5 | `MarksheetScheduleTest` | 6 | CRUD, status transitions (DRAFT→COMPUTED→REVIEWED→PUBLISHED→LOCKED), linked exam group |
| 6 | `ComputationTest` | 12 | All 5 sources; ABSENT → NULL; WITHHELD → WH; BA disabled → excluded; homework NULL → component NULL; rank computation; grade from slb_grade_division_master; theory-practical split; promotion status |
| 7 | `PublicationTest` | 5 | Publish locks template; Lock marks frozen; Unlock requires reason + audit log; Re-publish after recompute; Status guards |
| 8 | `PdfTest` | 4 | Generate individual PDF; school header present; absent shows "AB"; bulk ZIP generation |
| 9 | `IaMarksTest` | 3 | Enter marks; validate ≤ max; marks reflected in subject total after recompute |
| 10 | `EndToEndTest` | 3 | Full flow: config → schedule → compute → review → publish → student portal view; parent portal view; PDF download |
| | **Total** | **~51** | |

---

## Section 8 — Cross-Module Dependencies & Risks

| Dependency | Module | Risk Level | Mitigation |
|---|---|---|---|
| `lms_exam_results` structure | LmsExam | Medium | Verify in Pre-Dev V-01 to V-04. If columns differ, adapt ExamScoreReader |
| `lms_exam_papers.mode` distinguishes Online/Offline | LmsExam | Low | Transparent to marksheet — both produce lms_exam_results |
| **No `is_practical` flag on `lms_exam_papers`** | LmsExam | **High** | **Q-13 must be resolved. Options: (a) add migration for is_practical flag, (b) use paper title convention, (c) use msh_subject_practical_configs to identify practical subjects and match by subject_id** |
| `lms_quiz_quest_results.assessment_id` is polymorphic | LmsQuiz/Quest | Medium | Conditional join based on assessment_type. Test with actual data |
| `BehaviouralScoreService` may not exist yet | BehaviouralAssessment | Medium | Define interface (`ScoreReaderInterface`). Implement stub that returns NULL. Wire up when BA module is built |
| `slb_grade_division_master` must have seed data | Syllabus | Medium | Check P-04. If empty, grading fails gracefully (NULL grade) |
| `sch_class_groups_jnt` is NOT class grouping | SchoolSetup | Resolved | Created `msh_class_groups` (our own table) |
| Attendance module (`att_*`) not yet built | Attendance | Low | Manual entry in `msh_student_attendance`. Phase 2: auto-populate |
| StudentPortal/ParentPortal readiness | StudentPortal | Low | Expose API endpoints in Sprint 5. Works independently of portal status |

### Recommended resolution for Q-13 (Theory vs Practical paper):

**Option C (recommended):** Use `msh_subject_practical_configs` to know which subjects have practicals. For those subjects, fetch ALL `lms_exam_results` for the student-subject-exam combination. If there are 2 papers for the same subject in the same exam (one theory, one practical), match by `lms_exam_papers.total_marks` against `theory_max_marks` / `practical_max_marks` from the config. This avoids needing a flag on `lms_exam_papers`.

If the school creates separate exam papers for theory and practical (e.g., "Science Theory" and "Science Practical"), they will have different `lms_exam_papers` rows with different `total_marks`. The service matches:
- Paper with `total_marks = 70` → theory (matches `theory_max_marks = 70` from config)
- Paper with `total_marks = 30` → practical (matches `practical_max_marks = 30` from config)

---

## Section 9 — Security Checklist

| # | Check | Owner | Sprint |
|---|---|---|---|
| SEC-MSG-001 | Every controller method has `Gate::authorize()` | Dev | All sprints |
| SEC-MSG-002 | All FormRequests have `authorize()` with real Gate check (NOT hardcoded `true`) | Dev | All sprints |
| SEC-MSG-003 | Student marksheet access scoped to own `student_id` via `StudentResultPolicy` | Dev | Sprint 5 |
| SEC-MSG-004 | Parent access scoped to linked children only via `StudentResultPolicy` | Dev | Sprint 5 |
| SEC-MSG-005 | Published lock enforced at service layer (`MarksheetPublicationService`), not just UI | Dev | Sprint 4 |
| SEC-MSG-006 | Admin unlock requires mandatory reason (stored in `msh_computation_logs.remarks`) | Dev | Sprint 4 |
| SEC-MSG-007 | PDF download URLs use `URL::temporarySignedRoute` (24h expiry) | Dev | Sprint 5 |
| SEC-MSG-008 | No raw SQL — use Eloquent throughout | Dev | All sprints |
| SEC-MSG-009 | Score readers validate `is_published = 1` before reading results | Dev | Sprint 3 |
| SEC-MSG-010 | Template immutability: `is_locked = 1` prevents update after schedule published | Dev | Sprint 4 |
| SEC-MSG-011 | Concurrent computation guard: DB lock on `msh_marksheet_schedules.status_id` | Dev | Sprint 3 |
| SEC-MSG-012 | IA marks / Co-Scholastic entry: teacher can only enter for their assigned class-section | Dev | Sprint 3 |

---

## Section 10 — Migration Plan (Dependency Order)

| Step | Migration File | Table | Dependencies |
|---|---|---|---|
| 1 | `2026_04_13_000001_create_msh_marksheet_types_table.php` | `msh_marksheet_types` | None |
| 2 | `2026_04_13_000002_create_msh_source_components_table.php` | `msh_source_components` | None |
| 3 | `2026_04_13_000003_create_msh_ia_component_types_table.php` | `msh_ia_component_types` | None |
| 4 | `2026_04_13_000004_create_msh_class_groups_table.php` | `msh_class_groups` | None |
| 5 | `2026_04_13_000005_create_msh_class_group_items_jnt_table.php` | `msh_class_group_items_jnt` | #4 + `sch_classes` |
| 6 | `2026_04_13_000006_create_msh_exam_groups_table.php` | `msh_exam_groups` | `sch_org_academic_sessions_jnt` |
| 7 | `2026_04_13_000007_create_msh_exam_group_items_jnt_table.php` | `msh_exam_group_items_jnt` | #6 + `lms_exam_types` |
| 8 | `2026_04_13_000008_create_msh_config_templates_table.php` | `msh_config_templates` | #1, #6, `sch_org_academic_sessions_jnt`, `slb_grade_division_master` |
| 9 | `2026_04_13_000009_create_msh_template_scholastic_components_table.php` | `msh_template_scholastic_components` | #8, #2 |
| 10 | `2026_04_13_000010_create_msh_template_exam_weightages_table.php` | `msh_template_exam_weightages` | #8, `lms_exam_types` |
| 11 | `2026_04_13_000011_create_msh_template_ia_components_table.php` | `msh_template_ia_components` | #8, #3 |
| 12 | `2026_04_13_000012_create_msh_template_coscholastic_components_table.php` | `msh_template_coscholastic_components` | #8 |
| 13 | `2026_04_13_000013_create_msh_class_config_jnt_table.php` | `msh_class_config_jnt` | #8, #4, `sch_classes` |
| 14 | `2026_04_13_000014_create_msh_subject_practical_configs_table.php` | `msh_subject_practical_configs` | `sch_org_academic_sessions_jnt`, `sch_classes`, `sch_subjects` |
| 15 | `2026_04_13_000015_create_msh_marksheet_schedules_table.php` | `msh_marksheet_schedules` | #8, `sch_org_academic_sessions_jnt`, `sys_dropdown_table` |
| 16 | `2026_04_13_000016_create_msh_schedule_class_jnt_table.php` | `msh_schedule_class_jnt` | #15, `sch_class_section_jnt` |
| 17 | `2026_04_13_000017_create_msh_student_results_table.php` | `msh_student_results` | #15, `std_students`, `sch_class_section_jnt` |
| 18 | `2026_04_13_000018_create_msh_student_subject_results_table.php` | `msh_student_subject_results` | #15, `std_students`, `sch_subjects` |
| 19 | `2026_04_13_000019_create_msh_student_subject_exam_marks_table.php` | `msh_student_subject_exam_marks` | #15, `std_students`, `sch_subjects`, `lms_exam_types` |
| 20 | `2026_04_13_000020_create_msh_student_ia_marks_table.php` | `msh_student_ia_marks` | #15, #11, `std_students`, `sch_subjects` |
| 21 | `2026_04_13_000021_create_msh_student_coscholastic_results_table.php` | `msh_student_coscholastic_results` | #15, #12, `std_students` |
| 22 | `2026_04_13_000022_create_msh_student_attendance_table.php` | `msh_student_attendance` | #15, `std_students` |
| 23 | `2026_04_13_000023_create_msh_computation_logs_table.php` | `msh_computation_logs` | #15 |

---

## Section 11 — Integration Events

| Event | Fired By | Listener | Payload | Action |
|---|---|---|---|---|
| `ComputationCompleted` | `MarksheetComputationService` | `NotifyOnComputationCompleted` | `schedule_id`, `total_students`, `total_errors`, `duration_seconds` | Notify principal/coordinator that results are ready for review |
| `MarksheetPublished` | `MarksheetPublicationService` | `NotifyOnMarksheetPublished` | `schedule_id`, `class_section_ids[]` | Notify class teachers, students, parents that marksheets are available |
| `MarksheetUnlocked` | `MarksheetPublicationService` | `LogMarksheetUnlock` | `schedule_id`, `unlocked_by`, `reason` | Write audit entry to `msh_computation_logs`. Notify principal |

---

## Section 12 — Key Routes

```php
// Modules/MarksheetGeneration/routes/web.php

Route::middleware(['auth', 'verified'])->prefix('marksheet-generation')->name('marksheet-generation.')->group(function () {

    // Masters & Configuration
    Route::resource('marksheet-types', MarksheetTypeController::class);
    Route::resource('class-groups', ClassGroupController::class);
    Route::resource('exam-groups', ExamGroupController::class);
    Route::resource('config-templates', ConfigTemplateController::class);
    Route::post('config-templates/{template}/scholastic-components', [ConfigTemplateController::class, 'setScholasticComponents']);
    Route::post('config-templates/{template}/exam-weightages', [ConfigTemplateController::class, 'setExamWeightages']);
    Route::post('config-templates/{template}/ia-components', [ConfigTemplateController::class, 'setIaComponents']);
    Route::post('config-templates/{template}/coscholastic', [ConfigTemplateController::class, 'setCoscholasticComponents']);
    Route::post('config-templates/{template}/assign', [ConfigTemplateController::class, 'assignToClass']);
    Route::resource('practical-configs', PracticalConfigController::class);

    // Schedules & Computation
    Route::resource('schedules', MarksheetScheduleController::class);
    Route::post('schedules/{schedule}/compute', [ComputationController::class, 'trigger'])->name('schedules.compute');
    Route::get('schedules/{schedule}/progress', [ComputationController::class, 'progress'])->name('schedules.progress');

    // Data Entry (IA, Co-Scholastic, Attendance)
    Route::get('schedules/{schedule}/ia-marks/{classSection}', [ResultReviewController::class, 'iaMarksForm'])->name('schedules.ia-marks');
    Route::post('schedules/{schedule}/ia-marks/{classSection}', [ResultReviewController::class, 'storeIaMarks']);
    Route::get('schedules/{schedule}/coscholastic/{classSection}', [ResultReviewController::class, 'coscholasticForm'])->name('schedules.coscholastic');
    Route::post('schedules/{schedule}/coscholastic/{classSection}', [ResultReviewController::class, 'storeCoscholasticGrades']);
    Route::get('schedules/{schedule}/attendance/{classSection}', [ResultReviewController::class, 'attendanceForm'])->name('schedules.attendance');
    Route::post('schedules/{schedule}/attendance/{classSection}', [ResultReviewController::class, 'storeAttendance']);

    // Review & Publication
    Route::get('schedules/{schedule}/review/{classSection}', [ResultReviewController::class, 'reviewGrid'])->name('schedules.review');
    Route::get('schedules/{schedule}/student/{student}', [ResultReviewController::class, 'studentPreview'])->name('schedules.student-preview');
    Route::post('schedules/{schedule}/publish', [PublicationController::class, 'publish'])->name('schedules.publish');
    Route::post('schedules/{schedule}/lock', [PublicationController::class, 'lock'])->name('schedules.lock');
    Route::post('schedules/{schedule}/unlock', [PublicationController::class, 'unlock'])->name('schedules.unlock');

    // PDF
    Route::get('schedules/{schedule}/pdf/{student}', [MarksheetPdfController::class, 'downloadStudent'])->name('schedules.pdf.student');
    Route::get('schedules/{schedule}/pdf-bulk/{classSection}', [MarksheetPdfController::class, 'downloadBulk'])->name('schedules.pdf.bulk');
});
```

---

**PHASE 3 COMPLETE.** All output files generated:

| # | File | Location |
|---|---|---|
| 1 | `MSG_RequirementSpec.md` | `{OUTPUT_DIR}/MSG_RequirementSpec.md` |
| 2 | `MSG_DDL_v1.sql` | `{OUTPUT_DIR}/MSG_DDL_v1.sql` |
| 3 | `MSG_DataDictionary.md` | `{OUTPUT_DIR}/MSG_DataDictionary.md` |
| 4 | `MSG_Dev_Plan.md` | `{OUTPUT_DIR}/MSG_Dev_Plan.md` |

**Review all 4 files and confirm before starting implementation.**
