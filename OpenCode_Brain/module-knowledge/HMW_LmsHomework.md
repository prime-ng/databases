# Module Knowledge — LmsHomework (HMW)

> Seeded 2026-06-29 by Business Analyst (pa-business-analyst). Source of truth for accumulated
> knowledge on the LmsHomework module. Counts verified against the live tree
> (`/Users/bkwork/Herd/prime_ai/Modules/LmsHomework`), DDL v5, and central tenant migrations.
> Every schema claim three-way reconciled (DDL ↔ migration ↔ model).

---

## Module Facts

| Fact | Value |
|------|-------|
| Module Name | LmsHomework |
| Module Code | HMW |
| Table Prefix | `lms_` (**SHARED** prefix — see "Prefix Sharing" below) |
| DB Layer | Tenant (`tenant_db`) — database-per-tenant, no `tenant_id` column |
| Homework-owned tables | **3**: `lms_homework`, `lms_homework_assignment`, `lms_homework_submissions` |
| Canonical module DDL | `{DEV_MODULE_DDL_DIR}/LmsHomework_DDL_v5.sql` (v5, 2026-03-25) |
| Migrations | **3** in central `database/migrations/tenant/` (dated 2026_06_16) — NOT in module dir |
| Controllers | **2**: `LmsHomeworkController` (~2361 lines), `HomeworkSubmissionController` |
| Models | **3**: `Homework`, `HomeworkAssignment`, `HomeworkSubmission` |
| FormRequests | **3**: `HomeworkRequest`, `HomeworkSubmissionRequest`, `HomeworkReviewRequest` |
| Services | **2**: `HomeworkQueryService`, `LmsStorageService` |
| Policies | **5**: `HomeworkPolicy`, `HomeworkSubmissionPolicy`, `HomeworkAssignmentTrackingPolicy`, `HomeworkDashboardPolicy`, `HomeworkSummaryPolicy` (in module's own `app/Policies/`) |
| Console commands | **2**: `UpdateHomeworkStatus` (`tenant:homework:update-status`), `ReleaseScheduledHomework` (`tenant:homework:release-scheduled`) |
| Observers | **1**: `SyllabusScheduleObserver` (listens to `SyllabusSchedule@updated`) |
| Providers | **3**: `LmsHomeworkServiceProvider`, `EventServiceProvider`, `RouteServiceProvider` |
| Support | **1**: `HomeworkDropdownKeys` (dropdown key constants) |
| Seeders | **2**: `LmsHomeworkDatabaseSeeder`, `LmsHomeworkSeeder` |
| Blade views | **20** (analytics, home-work x5, assignment x3, submission x5, paper-check x2, summary, lmshome-work, index, master layout) |
| Tests | **1** feature: `HomeworkSchedulingTest` (Unit dir empty) |
| Routes | `routes/web.php` (rich: `home-works` resource + assignments + paper-check + `homework-submission` resource) + `routes/api.php` (apiResource `lmshomeworks` — see anomaly A7) |
| FRD status | FRD + Complete Analysis Pack created 2026-06-29 (see FRD Summary) |
| Completion estimate | ~70% (live code is well ahead of the V2 requirement doc; see "Status vs V2") |

### Prefix Sharing (CRITICAL — read before attributing tables)
The `lms_` prefix is shared across **LmsExam (EXM)**, **LmsQuiz (QUZ)**, **LmsQuests (QST)**, **LmsHomework (HMW)** and historically the **EventEngine / Rule Engine**. Only these three tables belong to HMW:
`lms_homework`, `lms_homework_assignment`, `lms_homework_submissions`.
The Rule-Engine system tables (`sys_trigger_event`, `sys_action_type`, `sys_rule_engine_config`,
`sys_rule_action_map`, `sys_rule_execution_log`) use the `sys_` prefix and are owned by
EventEngine / SystemConfig — **NOT** HMW. (The V2 requirement doc wrongly attributes them to HMW;
the live module no longer contains those controllers/models.)

---

## DDL Table Inventory (three-way reconciled: DDL v5 ↔ migration ↔ model)

### 1. `lms_homework` — homework template/definition
One row = one homework task for a class-section-subject. Created DRAFT; on publish bulk-creates
assignment rows. Model `Homework` (`InteractsWithMedia`, `SoftDeletes`).
Key columns: academic_session_id, class_id, section_id (NULL=all sections), subject_id, lesson_id,
topic_id, schedule_id, title, description (LONGTEXT NOT NULL), hw_attachment_media_id (JSON),
submission_type_id (→dropdown), is_gradable, max_marks, passing_marks, difficulty_level_id,
auto_publish_score, assign_date, due_date, allow_late_submission, **release_condition (ENUM)**,
release_scheduled_date, status_id (→dropdown DRAFT/PUBLISHED/ARCHIVED), audit cols.

### 2. `lms_homework_assignment` — per-student assignment record
One row per student per published homework. Model `HomeworkAssignment` (`SoftDeletes`).
UNIQUE(homework_id, student_id). Tracks release (is_released/released_at), per-student due_date
override, per-student allow_late_submission override (+reason/by/at), view tracking
(viewed_at/view_count), notification timestamps (student/parent/reminder), status_id (→dropdown:
PENDING_RELEASE/ASSIGNED/VIEWED/SUBMITTED/LATE_SUBMITTED/GRADED/OVERDUE/EXEMPTED), assigned_by.
> NOTE: V2 doc claimed this table was "missing from DDL" — **that is now stale**. DDL v5 (ADD/NEW)
> defines it and a migration creates it. Confirmed present across all three layers.

### 3. `lms_homework_submissions` — student submission + evaluation
1:1 to assignment (UNIQUE on assignment_id, per DDL CHG-1, changed from (homework_id, student_id)).
Model `HomeworkSubmission` (`InteractsWithMedia`, `SoftDeletes`). Columns: assignment_id,
homework_id, student_id, submission_text, sub_attachment_media_id (JSON), submitted_at, is_late,
resubmission_count, status_id (SUBMITTED/UNDER_REVIEW/GRADED/REJECTED/RESUBMIT_REQUESTED),
is_resubmission_requested, marks_obtained, teacher_feedback, graded_by, graded_at,
score_published_at, audit cols.

---

## Known Gaps & Open Issues

### Schema / reconciliation anomalies (DDL ↔ migration ↔ model)
- **[A-DDL-1] DDL column typo:** `lms_homework.realease_condition` is misspelled in DDL v5 (line 66).
  Migration + model spell it `release_condition`. RECONCILE: **`release_condition` ENUM string is
  authoritative** (migration + model agree).
- **[A-DDL-2] Dangling FK in DDL:** `fk_hw_release_cond` (and `fk_hwa_release_cond`) reference a
  `release_condition_id` column that does not exist (the column is the ENUM `release_condition`).
  These FK clauses would fail on a literal DDL run. Migration omits them (no FK on release_condition).
- **[A-DDL-3] Dropdown table name divergence:** DDL FKs target `sys_dropdown_table`; migrations target
  `sys_dropdowns`. Live runtime uses `sys_dropdowns` (Prime\Models\Dropdown). Treat `sys_dropdowns`
  as authoritative for live code.
- **[A-DDL-4] `hw_attachment_media_id`:** DDL declares `Json UNSIGNED` (invalid qualifier). Migration
  = nullable `json`; model casts `array`. RECONCILE: nullable JSON array of file-metadata objects.
- **[A-DDL-5] `academic_session_id` type:** DDL = `INT UNSIGNED`; migration = `unsignedSmallInteger`.
  Minor type divergence vs FK target `sch_org_academic_sessions_jnt`.
- **[A-DDL-6] `is_resubmission_requested`:** DDL + migration declare `INT UNSIGNED NOT NULL` with **no
  default**; model casts `boolean`. Inserts must set it explicitly (controller does) or fail.

### Functional / behavioural gaps
- **[A-FN-1] Late-submission policy not hard-blocked:** `is_late` is computed at submit time, but a
  late submission is **not rejected** when effective `allow_late_submission = 0`. (V2 BR-03 still open.)
- **[A-FN-2] Notification delivery is orphaned:** Every `Notification::create(...)` across the
  controller and the `ReleaseScheduledHomework` command has its companion `NotificationTarget::create`
  block **commented out**. Notifications are created with no recipients → never delivered. Systemic.
- **[A-FN-3] ON_TOPIC_COMPLETE auto-release is dead:** `SyllabusScheduleObserver` matches dropdown key
  `homework_status` and status values `'RELEASED'`/`'PENDING'` — but HMW statuses are
  DRAFT/PUBLISHED/ARCHIVED and the key is `lms_homework.status_id`. The observer's query never matches,
  so topic-completion release never fires.
- **[A-FN-4] Dropdown-key inconsistency:** `HomeworkDropdownKeys::ASSIGNMENT_STATUS` =
  `lms_homework_assignment.status_id` (canonical), but `ASSIGNMENT_STATUS_ALT` =
  `lms_homework.homework_assignment_status`. Commands (`UpdateHomeworkStatus`,
  `ReleaseScheduledHomework`) query the ALT key — risk of mismatched/empty status resolution.

### Authorization anomalies
- **[A-AUTH-1] Permission-string mismatch (defense-in-depth break):** Routes + controller `Gate::authorize`
  + all 5 policies use `tenant.home-work.*` and `tenant.home-work-submission.*` (hyphenated). But
  `HomeworkRequest::authorize()` checks `tenant.homework.create|update` (no hyphen),
  `HomeworkSubmissionRequest` checks `tenant.homework-submission.create|update`, and
  `HomeworkReviewRequest` checks `grade-homework`. The FormRequest permission strings differ from the
  controller/policy strings — the two layers guard against different (possibly nonexistent) permissions.
- **[A-AUTH-2] Multiple policies bound to one model:** `LmsHomeworkServiceProvider::registerPolicies()`
  calls `Gate::policy(Homework::class, ...)` **three times** (HomeworkPolicy, HomeworkDashboardPolicy,
  HomeworkSummaryPolicy). Laravel keeps only the **last** registration; HomeworkPolicy &
  HomeworkDashboardPolicy are effectively overridden for model-resolved gates. (Controller uses string
  gates `tenant.home-work.*`, so impact is limited, but the binding is misleading.)
- **[A-AUTH-3] EventEngine mis-bind note (not in this module):** EventEngine elsewhere binds to a
  nonexistent `RuleEngineConfigPolicy`. Confirmed **no** such reference exists inside LmsHomework.
  Flagged per instruction; do NOT fix from here.

### Dead code / structural
- **[A-CODE-1] Stale dead imports:** `Homework.php` imports `TriggerEvent`, `ActionType`,
  `RuleEngineConfig` (and `HomeworkRequest`, `Gate`, `Auth`) — the three Rule-Engine model files
  **do not exist** in this module (leftover from the Rule Engine that moved to EventEngine). Unused.
- **[A-CODE-2] Module migrations empty:** `LmsHomeworkServiceProvider::boot()` calls
  `loadMigrationsFrom(module database/migrations)` but that dir only has `.gitkeep`; the real
  migrations live in central `database/migrations/tenant/`.
- **[A-CODE-3] API route likely non-functional:** `routes/api.php` registers
  `apiResource('lmshomeworks', LmsHomeworkController::class)` but the controller's `index/store/...`
  return Blade views / web redirects (not JSON resource responses). The API surface is effectively unused.
- **[A-CODE-4] `seedTestData()`** is a fixture-seeding controller method gated by
  `tenant.home-work.update` — development helper left in production controller.

---

### Technical Auditor confirmations & NEW findings (2026-06-29, Mode X — Health 60/100, no P0, DEPLOY GO)
All BA-flagged anomalies (A-DDL-1..6, A-FN-1..4, A-AUTH-1/2, A-CODE-1..4) were **re-verified against live code and confirmed accurate**. Issue codes assigned in the audit report:
- **BUG-HMW-001 (P1, NEW):** `publish():886-921` computes `$isReleased/$releasedAt/$statusId` for the scheduled/on-topic branch but the `updateOrCreate` payload hardcodes `is_released=true / released_at=now() / status_id=ASSIGNED` → **release_condition is ignored; all assignments released immediately** at publish. Breaks BR-011/012 (DDL spec v5:309-311).
- **SEC-HMW-001 (P1):** A-AUTH-1 confirmed; FormRequest permission strings (`tenant.homework*`, `grade-homework`) found defined **nowhere** in seeders → `can()` fails closed for non-super-admins (escalates A-AUTH-1).
- **BUG-HMW-005 (P1, NEW):** `UpdateHomeworkStatus` is scheduled (`routes/console.php:51`) but has **no per-tenant tenancy loop** (runs in CENTRAL ctx vs `ReleaseScheduledHomework` which loops `Tenant::all()`) AND reads the `ASSIGNMENT_STATUS_ALT` key where no statuses live → overdue marking doubly dead (A-FN-4 + tenancy).
- **VAL-HMW-001 (P2, NEW):** `assignmentsGrade():1401` and `saveCheck():1904` validate marks min:0 with **no max** → BR-031 enforced only on the `review()` path.
- **BUG-HMW-006 (P2, NEW):** `store()`/`update()` call `syncAssignments()` unconditionally → IMMEDIATE homework auto-publishes at creation, undermining BR-005/007.
- **DATA-HMW-001 (P2, NEW):** migration `release_condition` ENUM **default = `ON_TOPIC_COMPLETE`** (the dead path); should be `IMMEDIATE`.
- **BUG-HMW-007 (P2, NEW):** `assignmentsIndex():1359` status filter uses `Dropdown::where('type', ...)` (wrong column) → always empty.
- Confirmed strengths (better than platform baseline): 0 `$request->all()` (D25), 0 bare-`true` FormRequests (D30), `DB::transaction`+`lockForUpdate` on submission uniqueness (BR-024), full web tenancy stack on the module RSP.

### Snapshot corrections (live-only facts)
- The two commands **ARE scheduled** centrally at `routes/console.php:50-51` (everyMinute, withoutOverlapping) — but `tenant:homework:update-status` lacks per-tenant init so it is ineffective (BUG-HMW-005).
- Migration default for `release_condition` is `ON_TOPIC_COMPLETE` (not noted previously).

## Design Decisions (observed in code/DDL)
- **D-HMW-1 (per D28):** Homework files use the LMS cloud-storage path template
  `lms_homework_upload_path` = `lms-homework/{session_code}/{class_section_id}/{homework_id}/{student_id}/{uploader}`
  resolved via `LmsStorageService::buildPath()`. Tenant UUID prepended by app, not stored in template.
- **D-HMW-2:** Dual file-storage model — new uploads go to JSON columns (`hw_attachment_media_id`,
  `sub_attachment_media_id`) via `LmsStorageService`; legacy files via Spatie Media Library collections
  (`homework_files`, `homework_submission_files`). Accessors merge both sources.
- **D-HMW-3:** Effective due date = `COALESCE(assignment.due_date, homework.due_date)`; effective late
  policy = `COALESCE(assignment.allow_late_submission, homework.allow_late_submission)` (handled in app).
- **D-HMW-4:** Submission is 1:1 to assignment (UNIQUE assignment_id). Resubmission updates the same row
  (`updateOrCreate` + `resubmission_count++`), not a new row.
- **D-HMW-5 (per D29 tension):** `release_condition` is a hard MySQL ENUM (IMMEDIATE / ON_TOPIC_COMPLETE
  / ON_SCHEDULED_DATE), which violates the "prefer sys_dropdown_table" rule. The dangling
  `release_condition_id` FK in DDL hints the original intent was a dropdown FK; never implemented.
- **D-HMW-6:** Status fields (homework/assignment/submission) are `sys_dropdowns` FK driven (D29 OK),
  keyed via `HomeworkDropdownKeys`. `ensureHomeworkStatusesExist()` self-seeds DRAFT/PUBLISHED/ARCHIVED.

## Status vs V2 Requirement (V2 is stale in key areas)
The live code is materially ahead of `HMW_LmsHomework_Requirement.md` (V2, 2026-03-26):
- `lms_homework_assignment` table now EXISTS (DDL v5 + migration) — V2 said missing.
- `release_condition` resolved to a working ENUM column — V2 flagged it as broken schema mismatch.
- `review()` now HAS `Gate::authorize('tenant.home-work-submission.update')` + `HomeworkReviewRequest`
  + `activityLog` — V2 flagged it as zero-auth critical bug.
- `store()` now uses `$request->validated()`, `DB::transaction`, and `lockForUpdate()` on the
  assignment — V2 flagged raw-request / no-transaction bugs.
- The Rule Engine (TriggerEvent/ActionType/RuleEngineConfig + 5 sys_ tables) has been **removed** from
  this module (moved to EventEngine); only stale imports remain.
Still open from V2: late-submission hard block (A-FN-1), notification targeting (A-FN-2),
test coverage (1 test), student/parent portal (StudentPortal module owns those).

---

## Cross-Module Dependencies
| Direction | Module | What |
|-----------|--------|------|
| Inbound (reads) | SchoolSetup | `sch_classes`, `sch_sections`, `sch_subjects`, `sch_org_academic_sessions_jnt`, `sch_class_section_jnt`, `sch_subject_groups`, `sch_class_groups_jnt` |
| Inbound (reads) | Syllabus | `slb_lessons`, `slb_topics`, `slb_complexity_level`, `slb_syllabus_schedule` (topic-complete trigger) |
| Inbound (reads) | StudentProfile | `std_students` (+ academic session/class-section enrollment for publish) |
| Inbound (reads) | Prime | `sys_dropdowns` (Dropdown), `sys_users`, `sys_media` |
| Outbound (writes) | Notification | Creates `ntf_*` Notification rows on lifecycle events (targets currently commented out — A-FN-2) |
| Runtime | Scheduler | Console commands for scheduled release + overdue marking |
| Runtime (planned) | StudentPortal / ParentPortal | Student submission UI + parent visibility (not in this module) |
| Runtime (legacy) | EventEngine | Owns the Rule-Engine `sys_*` tables; stale HMW imports reference removed models |

---

## FRD Summary
| Item | Value |
|------|-------|
| FRD file | `4-Requirement_Module_wise/0-FRD_Documents/HMW_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD is Section A) |
| Date | 2026-06-29 |
| Functional Requirements (REQ-) | 22 |
| Business Rules (BR-) | 49 |
| Workflows | 5 |
| Reports (RPT-) | 4 |
| Enhancements (ENH-) | 8 |
| Priority split | P0 = 6 · P1 = 12 · P2 = 4 |

## Pending Next Steps (downstream handoffs)
1. DDL Schema Gap Analysis (DB Architect / Technical Auditor) — verify the 3 tables vs FRD §10.1.
2. Application Code Gap Analysis (Technical Auditor, Mode B) — REQ coverage in controllers/views.
3. Business-Rule Enforcement audit (Technical Auditor, Mode C) — confirm BR-HMW-* enforcement; prioritise
   A-FN-1 (late block), A-FN-2 (notification targeting), A-AUTH-1 (permission-string mismatch).
4. Completion scoring (Status_Analyzer, 6-dim).
5. Test coverage gap (Testing Architect) — module has 1 test against 22 REQs.

## Version History
| Version | Date | Change | Agent |
|---------|------|--------|-------|
| 1.0 | 2026-06-29 | Seeded from live code, DDL v5, migrations, V2 + V1 screen specs. Three-way reconciled. FRD Complete Pack created. | Business Analyst |
| 1.1 | 2026-06-29 | Mode X Complete Audit appended: confirmed all BA anomalies + 5 NEW findings (BUG-HMW-001/005/006/007, VAL-HMW-001, DATA-HMW-001). Health 60/100, no P0, DEPLOY GO. Report at `3-Audit_Reports/V1_Jun-2026/LmsHomework_Complete_Audit_2026-06-29.md`. | Technical Auditor |
