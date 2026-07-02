# SLB — Syllabus Management
## Complete Analysis Pack
**Module Code:** SLB | **Generated:** 2026-06-30 | **Status:** Initial Release
**Mode:** Complete Analysis Pack (BA Agent v2, Mode X)
**FRD Reference:** SLB_FRD_2026-06-30.md

> This document is the consolidated pack. It assumes SLB_FRD_2026-06-30.md has been read first. Sections here extend, not replace, the FRD.

---

## Part A — Requirements Traceability Matrix (RTM)

### A.1 RTM — REQ to Implementation

| REQ-ID | Requirement | Controller(s) | Key Method(s) | FormRequest | Model(s) | Policy | Route | Status |
|--------|------------|--------------|---------------|-------------|---------|--------|-------|--------|
| REQ-SLB-001 | Lesson Management | LessonController | index, store, update, destroy, restore, forceDelete, toggleStatus, updateOrder | LessonRequest, UpdateLessonRequest | Lesson | LessonPolicy | lesson.* | 90% |
| REQ-SLB-002 | Topic Hierarchy | TopicController | index, store, update, destroy, restore, forceDelete, updateHierarchy, dragUpdate | TopicRequest | Topic | TopicPolicy | topic.* | 85% (destroy P0 bug) |
| REQ-SLB-003 | Competency Framework | CompetencieController | index, store, update, destroy, updateHierarchy, getParentCompetencies | CompetencyRequest | Competencie | CompetenciePolicy | competencies.* | 70% (P0 security gaps) |
| REQ-SLB-004 | Topic-Competency Mapping | TopicCompetencyController | index, store, destroy, toggleStatus | TopicCompetencyRequest | TopicCompetency | — | topic-competency.* | 70% |
| REQ-SLB-005 | Bloom's & Reference Data | BloomTaxonomyController, CognitiveSkillController, QuestionTypeController, QuestionTypeSpecificityController, ComplexityLevelController | index, store, update, destroy, restore, forceDelete | Per-entity requests | Per-entity models | Per-entity policies | bloom-taxonomy.*, cognitive-skill.*, etc. | 95% |
| REQ-SLB-006 | Syllabus Schedule & Delivery | SyllabusScheduleController, SyllabusController | index, store, update, destroy, markComplete | SyllabusScheduleRequest | SyllabusSchedule | SyllabusSchedulePolicy | syllabus-schedule.* | 85% |
| REQ-SLB-007 | Schedule Lock | SyllabusController | toggleLock | — | SyllabusSchedule | — | planning.toggleLock | 90% |
| REQ-SLB-008 | Lesson Sequencing & Periods | SyllabusController | saveSequencing, planning | — | SyllabusSchedule, PeriodsAllocation | — | planning.saveSequencing | 85% |
| REQ-SLB-009 | Auto-Scheduling | SyllabusController | autoSchedule | — | SyllabusSchedule | — | planning.autoSchedule | 80% |
| REQ-SLB-010 | LMS Resource Release | TopicController, ReleaseLmsResources (Artisan) | toggleReleaseStatus, handle | — | SyllabusSchedule | — | topic.toggleReleaseStatus | 75% |
| REQ-SLB-011 | Performance Categories | PerformanceCategoryController | index, store, update, destroy, restore | PerformanceCategoryRequest | PerformanceCategory | PerformanceCategoryPolicy | performance-category.* | 65% |
| REQ-SLB-012 | Grade Divisions | GradeDivisionController | index, store, update, destroy, restore | GradeDivisionRequest | GradeDivisionMaster | GradeDivisionPolicy | grade-division.* | 60% |
| REQ-SLB-013 | Study Notes | — | — | — | Study notes models (Notes, NotesFiles, NotesDownloads, NotesRatings) | — | — | 30% (tables only) |
| REQ-SLB-014 | Coverage Analytics | SyllabusController | report | — | SyllabusSchedule, Topic, Lesson | — | report.index | 70% |
| REQ-SLB-015 | Module Configuration Settings | SyllabusController | saveSetting | — | SchoolConfig (sch_config) | — | planning.saveSetting | 80% |

### A.2 RTM — BR to REQ

| BR-ID | Business Rule | Linked REQ | Linked Tests |
|-------|--------------|-----------|-------------|
| BR-SLB-001 | Lesson code uniqueness auto-generation | REQ-SLB-001 | NONE |
| BR-SLB-002 | Topic level = parent level + 1 | REQ-SLB-002 | NONE |
| BR-SLB-003 | Cannot change level when children exist | REQ-SLB-002 | NONE |
| BR-SLB-004 | Circular competency parent prevention | REQ-SLB-003 | NONE |
| BR-SLB-005 | Topic with active quizzes blocks force-delete | REQ-SLB-002 | NONE |
| BR-SLB-006 | Topic-competency mapping uniqueness | REQ-SLB-004 | NONE |
| BR-SLB-007 | Performance category range non-overlap | REQ-SLB-011 | NONE |
| BR-SLB-008 | Bloom LOT (1-3) / HOT (4-6) split | REQ-SLB-005, REQ-SLB-014 | NONE |
| BR-SLB-009 | Textbook reference mandatory on lesson | REQ-SLB-001 | NONE |
| BR-SLB-010 | System-defined records locked | REQ-SLB-001, REQ-SLB-011 | NONE |
| BR-SLB-011 | Grade division locked after publish | REQ-SLB-012 | NONE |
| BR-SLB-012 | analytics_code immutable | REQ-SLB-002 | NONE |
| BR-SLB-013 | scheduled_year_week YYYYWW format | REQ-SLB-001 | NONE |
| BR-SLB-014 | Materialized path auto-computed on create | REQ-SLB-002 | NONE |
| BR-SLB-015 | Competency controller must use validated() | REQ-SLB-003 | NONE |
| BR-SLB-016 | Period limits validation on sequencing | REQ-SLB-008 | NONE |
| BR-SLB-017 | Locked schedule not modified by bulk ops | REQ-SLB-007, REQ-SLB-009 | NONE |
| BR-SLB-018 | Release level uniqueness across resource types | REQ-SLB-010, REQ-SLB-015 | NONE |
| BR-SLB-019 | Coverage = is_active=1 / total × 100 | REQ-SLB-006, REQ-SLB-014 | NONE |
| BR-SLB-020 | destroy() must soft-delete (P0 bug — uses forceDelete) | REQ-SLB-002 | NONE |
| BR-SLB-021 | markComplete records taught_by_teacher_id | REQ-SLB-006 | NONE |
| BR-SLB-022 | Release is section-scoped | REQ-SLB-010 | NONE |
| BR-SLB-023 | Grade division range non-overlap | REQ-SLB-012 | NONE |
| BR-SLB-024 | Topic parent must be same lesson, level N-1 | REQ-SLB-002 | NONE |

### A.3 RTM — RPT to REQ and Data Sources

| RPT-ID | Report Name | Source Table(s) | Source Method | Linked REQ |
|--------|------------|----------------|---------------|-----------|
| RPT-SLB-001 | Coverage Dashboard | slb_syllabus_schedule, slb_topics, slb_lessons | report() → Dashboard tab | REQ-SLB-014 |
| RPT-SLB-002 | Progress Tracker | slb_syllabus_schedule, slb_lessons, sch_classes, sch_subjects | report() → Progress Tracker tab | REQ-SLB-014 |
| RPT-SLB-003 | Coverage Audit | slb_syllabus_schedule, slb_topics, slb_competencies | report() → Coverage Audit tab | REQ-SLB-014 |
| RPT-SLB-004 | Resource Matrix | slb_syllabus_schedule, slb_topic_competencies (proxy) | report() → Resource Matrix tab | REQ-SLB-014 |
| RPT-SLB-005 | Planning Accuracy | slb_syllabus_schedule, sch_teachers | report() → Planning Accuracy tab | REQ-SLB-014 |
| RPT-SLB-006 | Bloom Distribution | slb_bloom_taxonomies, slb_topics | bloom() | REQ-SLB-005 |

---

## Part B — Business Rules Register + Requirement Conditions Catalog

### B.1 Requirement Conditions Catalog

Conditions are platform-wide behaviours that apply to this module.

| Condition Code | Condition | Applies To | Enforcement Layer |
|---------------|-----------|-----------|------------------|
| CON-SLB-001 | All data mutations require a valid auth session (auth middleware); unauthenticated requests return 401/403 | All controllers | Middleware (global) |
| CON-SLB-002 | Tenant isolation: all database queries are scoped to the active tenant's database connection; global tables are never written in Syllabus controllers | All data operations | stancl/tenancy v3.9 database-per-tenant |
| CON-SLB-003 | Soft-delete pattern: all destroy() methods call delete() for SoftDeletes models; forceDelete() is available only via explicit route | Lesson, Topic, SyllabusSchedule, Competencie | Application layer (currently P0 bug in TopicController::destroy()) |
| CON-SLB-004 | All write operations use $request->validated() for input access; $request->all() is never used in store/update methods | All controllers | FormRequest + Application layer (currently violated in CompetencieController) |
| CON-SLB-005 | Gate::authorize() is called at the start of each controller method; no method is gate-free except public AJAX helpers that return non-sensitive data | All controllers | Authorization layer (currently violated in CompetencieController — ZERO auth) |
| CON-SLB-006 | FormRequest::authorize() must not hardcode true; it must return a Gate or Policy check | All FormRequests | Application layer (D30 systemic pattern) |
| CON-SLB-007 | EnsureTenantHasModule middleware must be active on all module routes to prevent tenants without the Syllabus feature from accessing endpoints | Route group | Middleware (status post-migration: unverified) |
| CON-SLB-008 | ActivityLog must be written on all data mutations (create, update, delete, restore) using the activityLog helper | All data mutations | Helper (activityLog.php) |
| CON-SLB-009 | No raw SQL queries; all database access uses Eloquent ORM or Query Builder with parameterized bindings | All data operations | Code review gate |
| CON-SLB-010 | Multi-tenancy cron (ReleaseLmsResources): must initialise Tenancy context per tenant before reading tenant-scoped data; must end tenancy before moving to next tenant | ReleaseLmsResources Artisan command | Application layer (correctly implemented) |

### B.2 Validation Catalog (Edge Cases)

| Validation ID | Scenario | Expected Behaviour | Current Behaviour | Gap? |
|--------------|----------|-------------------|------------------|------|
| VAL-SLB-001 | Create topic with parent in different lesson | Reject with "Parent must belong to the same lesson" | Should reject — verify controller implementation | Verify |
| VAL-SLB-002 | Set topic level to 0 when parent is set | Reject — level-0 topics cannot have parents | Should reject — verify | Verify |
| VAL-SLB-003 | Create topic when max level exceeded | Reject — level must exist in topic_level_types | Verify controller checks level type table | Verify |
| VAL-SLB-004 | Delete topic with children | Reject with clear message | V2 spec: should block; verify TopicController::destroy() pre-check | Verify |
| VAL-SLB-005 | Delete lesson with linked topics | Should require force-delete or reject with dependency count | Unverified | Verify |
| VAL-SLB-006 | Bulk import: duplicate lesson code in same file | Row-level error on the duplicate; valid rows still import | Two-step validate-then-commit handles this | OK |
| VAL-SLB-007 | Competency circular parent (A → B → A through 3 nodes) | Reject with "Circular dependency detected" | Only 1-level check implemented; deep circular missing | GAP |
| VAL-SLB-008 | Release level setting: set Homework and Quiz to same level | Reject with "Homework and Quiz release levels must be different" | Implemented in saveSetting() | OK |
| VAL-SLB-009 | Save sequencing: planned_periods exceeds daily limit | Reject with period limit error per row | Implemented in saveSequencing() | OK |
| VAL-SLB-010 | Auto-schedule: topic with planned_periods = 0 | Skip (no dates assigned); continue to next topic | Implemented | OK |
| VAL-SLB-011 | Mark complete on already-released topic | Idempotent; re-marks without error | SyllabusScheduleController::markComplete — verify idempotency | Verify |
| VAL-SLB-012 | Toggle lock on a released topic | Should be permitted — lock is date-freeze, not release-freeze | Verify no guard against releasing locked topics | Verify |
| VAL-SLB-013 | Performance category range: 90-100 already exists; try to create 85-95 | Reject with overlap error | BR-SLB-007 requires service check; not yet implemented | GAP |
| VAL-SLB-014 | Grade division range: overlapping ranges within same scope | Reject with overlap error | BR-SLB-023 requires service check; not yet implemented | GAP |
| VAL-SLB-015 | Restore a soft-deleted topic when its parent was force-deleted | Restore places topic at orphaned state (parent_id FK broken) | No guard implemented | GAP |
| VAL-SLB-016 | Bloom taxonomy level change — would it affect existing topic-competency mappings? | UI-level warning; no hard block | Not implemented | GAP (informational) |
| VAL-SLB-017 | Lesson with is_system_defined = 1 — edit attempt | Reject with "System-defined lessons cannot be modified" | BR-SLB-010 — not yet implemented in LessonController | GAP |

---

## Part C — Process Flows and FSM Catalog

### C.1 Finite State Machine: Syllabus Schedule Entry

```
States:
  UNSCHEDULED   → Created from lesson sequencing; no dates yet
  SCHEDULED     → Has planned_start_date, planned_end_date, assigned_teacher
  LOCKED        → is_locked = 1 (dates frozen; can still be released)
  RELEASED      → is_active = 1; topic marked as taught

Transitions:
  UNSCHEDULED   ──[saveSequencing]──→  UNSCHEDULED (with ordinal + planned_periods)
  UNSCHEDULED   ──[saveScheduling / autoSchedule]──→  SCHEDULED
  SCHEDULED     ──[toggleLock ON]──→   LOCKED
  LOCKED        ──[toggleLock OFF]──→  SCHEDULED
  SCHEDULED     ──[markComplete / toggleRelease]──→  RELEASED
  LOCKED        ──[markComplete / toggleRelease]──→  RELEASED (lock does not prevent release)
  RELEASED      ──[toggleRelease OFF]──→  SCHEDULED (or LOCKED if was locked before)
  RELEASED      ──[autoSchedule re-run]──→  RELEASED (no date change; cron skips released entries?)
  Any State     ──[soft-delete]──→  TRASH
  TRASH         ──[restore]──→  Previous state
  TRASH         ──[force-delete]──→  DELETED (permanent)

Terminal State: DELETED

Guards:
  LOCKED state: saveScheduling and autoSchedule cannot change dates (skip guard)
  RELEASED state: LMS homework/quiz/quest visible to students in the section
  TRASH state: not counted in coverage calculations

Open Question: Does autoSchedule recalculate dates for RELEASED entries that are NOT locked?
Current code: autoSchedule skips entries where is_locked = true only; does not check is_active.
Risk: Recalculating dates on already-released topics would create a data consistency issue.
```

### C.2 Finite State Machine: Competency

```
States:
  ACTIVE    → Can be mapped to topics; visible in topic-competency selector
  INACTIVE  → Hidden from topic-competency selector; existing mappings still valid
  TRASH     → Soft-deleted; not visible anywhere
  DELETED   → Permanent (force-delete)

Transitions:
  ACTIVE    ──[toggleStatus OFF]──→  INACTIVE
  INACTIVE  ──[toggleStatus ON]──→   ACTIVE
  ACTIVE / INACTIVE  ──[destroy()]──→  TRASH
  TRASH     ──[restore()]──→  ACTIVE
  TRASH     ──[forceDelete()]──→  DELETED

Guard: destroy() blocked if active topic-competency mappings exist

CURRENT BUG: Competencie model lacks SoftDeletes trait. destroy() will hard-delete.
```

### C.3 Process Flow: Lesson Import (Bulk)

```
Actor: Academic Coordinator

1. Navigate to /syllabus/master → Lessons tab → Import
2. Download template (CSV/XLSX with required columns)
3. Fill template (Class, Subject, Lesson Name, Textbook, Duration, Objectives, etc.)
4. Upload file → POST /lesson/validate-file
5. System runs dry-run validation (LessonImport):
   a. Row count check (max 500)
   b. Required field check per row
   c. Class/Subject existence check
   d. Textbook existence check
   e. Duplicate code check (would-be code already in DB)
6. If errors: return validation report with row numbers and messages → User fixes
7. If clean: Show preview table with row count
8. Click "Start Import" → POST /lesson/start-import
9. System commits all rows; returns success + error count
10. Lesson codes auto-generated for committed rows

Error Handling: Per-row error tracking; partial import not supported (all-or-nothing per clean batch)
```

### C.4 Process Flow: Coverage Report — Report Tab

```
Actor: School Admin / Academic Coordinator / Teacher

GET /syllabus/report?tab=dashboard&class_id=X&subject_id=Y&session_id=Z

SyllabusController::report()
1. Validate tab parameter (dashboard | progress_tracker | coverage_audit | resource_matrix | planning_accuracy | trend)
2. Load session + class + subject filter
3. Switch on tab:
   DASHBOARD:
     - Single SQL: group by class/section, count total, count is_active=1, overdue (past end date + not released)
     - subjectCoverage: group by subject, calculate %
     - trendData: last 15 days, count releases per day
     - classProgress: group by class
     - statusDistribution: total / released / overdue / on-track
     - teacherPerformance: join to teachers, count on-time (released before planned_end_date), rank top 10
   PROGRESS_TRACKER:
     - Group by class_id, section_id, subject_id
     - Count total, count released, count overdue
     - Paginate
   COVERAGE_AUDIT:
     - Join schedule → topic → competency
     - Paginate with planned dates
     - [V1 SPEC: Bloom depth, competency breakdown — NOT YET IMPLEMENTED]
   RESOURCE_MATRIX:
     - Join schedule → topic → competencies (count as proxy for QB)
     - [VIDEO/PDF COUNTS ALWAYS 0 — slb_study_materials not implemented]
   PLANNING_ACCURACY:
     - DATEDIFF(NOW(), planned_end_date) as variance_days where is_active = 1
     - Categorise: 0 = on-time, 1–3 = slightly late, 4+ = very late

4. Return view with all computed datasets
```

---

## Part D — Data Dictionary

### D.1 slb_lessons

| Column | Type | Nullable | FK | Business Meaning |
|--------|------|----------|-----|------------------|
| id | BIGINT UNSIGNED PK | No | — | Surrogate PK |
| lesson_code | VARCHAR | No | — | Auto-generated unique code; immutable after create |
| lesson_name | VARCHAR | No | — | Full chapter name |
| lesson_short_name | VARCHAR | Yes | — | Abbreviated name for compact UI |
| academic_session_id | BIGINT | No | sch_academic_sessions | Academic year scope |
| class_id | BIGINT | No | sch_classes | Target grade/class |
| subject_id | BIGINT | No | sch_subjects | Target subject |
| textbook_id | BIGINT | No | slb_books / bok_books (TBD) | Required textbook reference |
| sequence_number | INT | No | — | Display ordinal within class+subject |
| description | TEXT | Yes | — | Chapter summary |
| learning_objectives | JSON | Yes | — | Array of stated learning goals |
| prerequisites | JSON | Yes | — | Array of prerequisite lesson IDs |
| estimated_periods | DECIMAL | Yes | — | Planned teaching duration in periods |
| subject_weightage | DECIMAL | Yes | — | % contribution to subject marks |
| nep_alignment_code | VARCHAR | Yes | — | NEP 2020 framework code |
| scheduled_year_week | INT | Yes | — | YYYYWW format target delivery week |
| is_active | TINYINT(1) | No DEFAULT 1 | — | Visibility flag |
| is_system_defined | TINYINT(1) | No DEFAULT 0 | — | Lock flag for national curriculum lessons |
| created_by | BIGINT | Yes | sys_users | Creator |
| updated_by | BIGINT | Yes | sys_users | Last editor |
| deleted_at | TIMESTAMP | Yes | — | SoftDeletes (NULL = not deleted) |
| created_at | TIMESTAMP | No | — | |
| updated_at | TIMESTAMP | No | — | |

**Indexes:** lesson_code (UNIQUE), class_id, subject_id, academic_session_id, deleted_at

### D.2 slb_topics

| Column | Type | Nullable | FK | Business Meaning |
|--------|------|----------|-----|------------------|
| id | BIGINT UNSIGNED PK | No | — | Surrogate PK |
| topic_code | VARCHAR | No | — | Auto-generated hierarchical code |
| analytics_code | VARCHAR | No | — | Immutable stable cross-year identifier |
| topic_name | VARCHAR | No | — | Topic label |
| lesson_id | BIGINT | No | slb_lessons | Parent lesson |
| parent_topic_id | BIGINT | Yes | slb_topics (self) | Parent in tree (null = root) |
| level | TINYINT | No | — | 0 = Topic, 1 = Sub-Topic, etc. |
| topic_level_type_id | BIGINT | Yes | slb_topic_level_types | Level type reference |
| path | VARCHAR | No DEFAULT '/tmp/' | — | Materialized path; auto-set in created() hook |
| duration_minutes | INT | Yes | — | Estimated teaching time |
| learning_objectives | JSON | Yes | — | Array of objectives |
| keywords | JSON | Yes | — | Search keywords |
| sequence_order | INT | Yes | — | Display order within lesson |
| is_assessable | TINYINT(1) | No DEFAULT 1 | — | Whether questions can be linked |
| can_use_for_syllabus_status | TINYINT(1) | No DEFAULT 1 | — | Included in coverage count |
| is_active | TINYINT(1) | No DEFAULT 1 | — | Visibility flag |
| created_by | BIGINT | Yes | sys_users | Creator |
| updated_by | BIGINT | Yes | sys_users | Last editor |
| deleted_at | TIMESTAMP | Yes | — | SoftDeletes |
| created_at | TIMESTAMP | No | — | |
| updated_at | TIMESTAMP | No | — | |

**Indexes:** topic_code, analytics_code, lesson_id, parent_topic_id, level, path

### D.3 slb_syllabus_schedule

| Column | Type | Nullable | FK | Business Meaning |
|--------|------|----------|-----|------------------|
| id | BIGINT UNSIGNED PK | No | — | |
| academic_session_id | BIGINT | No | sch_academic_sessions | Session scope |
| class_id | BIGINT | No | sch_classes | Class scope |
| section_id | BIGINT | No | sch_sections | Section scope |
| subject_id | BIGINT | No | sch_subjects | Subject scope |
| lesson_id | BIGINT | No | slb_lessons | Lesson reference |
| topic_id | BIGINT | No | slb_topics | Specific topic being scheduled |
| topic_level_type_id | BIGINT | Yes | slb_topic_level_types | Level type of the topic |
| planned_start_date | DATE | Yes | — | Scheduled start |
| planned_end_date | DATE | Yes | — | Scheduled end |
| planned_periods | DECIMAL(5,2) | Yes | — | Period allocation (fractional) |
| assigned_teacher_id | BIGINT | Yes | sch_teachers | Scheduled teacher |
| taught_by_teacher_id | BIGINT | Yes | sch_teachers | Actual delivering teacher |
| priority | ENUM('HIGH','MEDIUM','LOW') | Yes DEFAULT 'MEDIUM' | — | Planning priority |
| ordinal | INT | Yes | — | Teaching sequence order |
| is_active | TINYINT(1) | No DEFAULT 0 | — | Release/completion flag (0 = pending, 1 = released/taught) |
| is_locked | TINYINT(1) | No DEFAULT 0 | — | Date-freeze flag (new, June 27 2026) |
| is_status | TINYINT(1) | Yes | — | General active/inactive toggle |
| notes | TEXT | Yes | — | Scheduling notes |
| created_by | BIGINT | Yes | sys_users | |
| updated_by | BIGINT | Yes | sys_users | |
| deleted_at | TIMESTAMP | Yes | — | SoftDeletes |
| created_at | TIMESTAMP | No | — | |
| updated_at | TIMESTAMP | No | — | |

**Indexes:** academic_session_id, class_id, section_id, subject_id, topic_id, is_active, is_locked

### D.4 slb_competencies

| Column | Type | Nullable | FK | Business Meaning |
|--------|------|----------|-----|------------------|
| id | BIGINT UNSIGNED PK | No | — | |
| competency_code | VARCHAR | No | — | Unique code within class+subject |
| competency_name | VARCHAR | No | — | Skill/knowledge label |
| competency_type_id | BIGINT | No | slb_competency_types | KNOWLEDGE / SKILL / ATTITUDE |
| domain | ENUM('COGNITIVE','AFFECTIVE','PSYCHOMOTOR') | Yes | — | Learning domain |
| parent_id | BIGINT | Yes | slb_competencies (self) | Parent competency |
| path | VARCHAR | Yes | — | Materialized path |
| level | TINYINT | Yes DEFAULT 0 | — | Hierarchy depth |
| nep_framework_code | VARCHAR | Yes | — | NEP 2020 reference |
| ncf_alignment_code | VARCHAR | Yes | — | NCF code |
| learning_outcome_code | VARCHAR | Yes | — | Board learning outcome ref |
| is_active | TINYINT(1) | No DEFAULT 1 | — | Visibility |
| deleted_at | TIMESTAMP | Yes | — | SoftDeletes (CURRENTLY MISSING from Competencie model — P0 bug) |
| created_at | TIMESTAMP | No | — | |
| updated_at | TIMESTAMP | No | — | |

### D.5 slb_bloom_taxonomies

| Column | Type | Nullable | Business Meaning |
|--------|------|----------|-----------------|
| id | BIGINT UNSIGNED PK | No | |
| bloom_level | TINYINT | No | 1–6 (1=Remember … 6=Create) |
| bloom_name | VARCHAR | No | Level name |
| thinking_order | ENUM('LOT','HOT') | No | Lower/Higher Order Thinking |
| description | TEXT | Yes | What this level assesses |
| action_verbs | JSON | Yes | Example verbs for this level (Write, List, Explain…) |
| is_active | TINYINT(1) | No DEFAULT 1 | |
| deleted_at | TIMESTAMP | Yes | SoftDeletes |

### D.6 slb_performance_categories

| Column | Type | Nullable | Business Meaning |
|--------|------|----------|-----------------|
| id | BIGINT UNSIGNED PK | No | |
| category_name | VARCHAR | No | e.g., TOPPER, EXCELLENT |
| category_code | VARCHAR | No | Short code |
| min_percentage | DECIMAL(5,2) | No | Band lower bound |
| max_percentage | DECIMAL(5,2) | No | Band upper bound |
| scope | ENUM('SCHOOL','BOARD','CLASS') | No | Applicability scope |
| class_id | BIGINT | Yes | Class scope override |
| ai_severity | ENUM('LOW','MEDIUM','HIGH','CRITICAL') | No | HPC/Recommendation urgency |
| ai_action | ENUM('ACCELERATE','PROGRESS','PRACTICE','REMEDIATE','ESCALATE') | No | AI intervention action |
| auto_retest_required | TINYINT(1) | No DEFAULT 0 | Trigger auto-retest |
| colour_code | VARCHAR | Yes | Hex colour |
| is_system_defined | TINYINT(1) | No DEFAULT 0 | Lock from school edits |
| is_active | TINYINT(1) | No DEFAULT 1 | |
| deleted_at | TIMESTAMP | Yes | SoftDeletes |

### D.7 slb_grade_division_masters

| Column | Type | Nullable | Business Meaning |
|--------|------|----------|-----------------|
| id | BIGINT UNSIGNED PK | No | |
| division_name | VARCHAR | No | e.g., A+, First Division |
| grading_type | ENUM('GRADE','DIVISION') | No | Grade (A/B/C) or Division (First/Second) |
| min_percentage | DECIMAL(5,2) | No | |
| max_percentage | DECIMAL(5,2) | No | |
| scope | ENUM('SCHOOL','BOARD','CLASS') | No | |
| board_code | VARCHAR | Yes | If scope = BOARD |
| class_id | BIGINT | Yes | If scope = CLASS |
| is_locked | TINYINT(1) | No DEFAULT 0 | Lock after results published |
| is_active | TINYINT(1) | No DEFAULT 1 | |
| deleted_at | TIMESTAMP | Yes | SoftDeletes |

### D.8 slb_syllabus_periods_allocation (new, June 2026)

| Column | Type | Nullable | Business Meaning |
|--------|------|----------|-----------------|
| id | BIGINT UNSIGNED PK | No | |
| date | DATE | No | Calendar date |
| academic_session_id | BIGINT | No | |
| class_id | BIGINT | No | |
| section_id | BIGINT | No | |
| subject_id | BIGINT | No | |
| periods_per_day | DECIMAL | No | Teaching periods available per day |
| periods_per_week | DECIMAL | No | Weekly total |
| is_school_open | TINYINT(1) | No DEFAULT 1 | Whether school teaches on this date |
| created_at | TIMESTAMP | No | |
| updated_at | TIMESTAMP | No | |

### D.9 Cross-Module Dependency Map

| SLB Entity | Dependency Direction | External Module | External Entity | Relationship |
|-----------|---------------------|----------------|----------------|-------------|
| slb_lessons | Reads | SchoolSetup | sch_academic_sessions | Lesson scoped to session |
| slb_lessons | Reads | SchoolSetup | sch_classes | Lesson scoped to class |
| slb_lessons | Reads | SchoolSetup | sch_subjects | Lesson scoped to subject |
| slb_lessons | Reads | SyllabusBooks | slb_books / bok_books (ambiguous) | Textbook reference |
| slb_topics | Reads | QuestionBank | qns_questions | Active quiz link check before delete |
| slb_syllabus_schedule | Reads | SchoolSetup | sch_sections, sch_teachers | Scheduling scope |
| slb_syllabus_schedule | Writes | LmsHomework | homework assignments (is_released) | Homework release on is_active = 1 |
| slb_syllabus_schedule | Writes | LmsQuiz | quiz allocations (is_active) | Quiz release on is_active = 1 |
| slb_syllabus_schedule | Writes | LmsQuests | quest allocations (is_active) | Quest release on is_active = 1 |
| slb_performance_categories | Reads by | HPC | hpc_interventions | Intervention category thresholds |
| slb_performance_categories | Reads by | Recommendation | rec_recommendations | Recommendation trigger severity |
| slb_topics | Reads by | QuestionBank | qns_questions.topic_id | Topic-level question linkage |
| slb_topics | Reads by | LmsExam | exm_papers (topic scope) | Exam paper topic filter |
| slb_bloom_taxonomies | Reads by | QuestionBank | qns_questions.bloom_id | Question cognitive level tagging |
| slb_competencies | Reads by | QuestionBank | qns_question_competencies | Question competency tagging |
| slb_grade_division_masters | Reads by | MarksheetGeneration | msh_* (grade classification) | Grade band for result classification |

---

## Part E — NFR Catalog and Risk Register

### E.1 NFR Catalog

| NFR-ID | Category | Requirement | Measure | Priority |
|--------|---------|------------|---------|---------|
| NFR-SLB-001 | Performance | Topic tree load (getTopicsByLesson) | < 500ms for 200 topics via materialized path | P1 |
| NFR-SLB-002 | Performance | Coverage dashboard stats | < 1,000ms via single aggregation query | P1 |
| NFR-SLB-003 | Performance | Bulk lesson import (500 rows) | < 30 seconds end-to-end | P1 |
| NFR-SLB-004 | Performance | Competency tree (3 levels) | < 300ms; recursive query depth must be bounded | P1 |
| NFR-SLB-005 | Performance | Nightly cron (all tenants, all schedules) | < 10 minutes total; per-tenant < 30 seconds | P2 |
| NFR-SLB-006 | Security | All controller methods gated | 100% Gate::authorize() coverage | P0 |
| NFR-SLB-007 | Security | No raw request data | $request->validated() in all store/update | P0 |
| NFR-SLB-008 | Security | EnsureTenantHasModule active | Verified on route group after migration | P0 |
| NFR-SLB-009 | Usability | Drag-and-drop latency | Client-side response < 200ms; async save | P2 |
| NFR-SLB-010 | Usability | Import error report | Row-level messages with row numbers | P1 |
| NFR-SLB-011 | Reliability | Cron per-tenant isolation | Failure in one tenant must not abort the batch | P1 (implemented correctly) |
| NFR-SLB-012 | Data Integrity | Soft-delete universality | No hard-delete except via explicit force-delete route | P0 |
| NFR-SLB-013 | Data Integrity | Analytics code stability | analytics_code never changes after first insert | P0 |
| NFR-SLB-014 | Maintainability | Zero duplicate policies | 3 duplicate pairs must be resolved | P3 |
| NFR-SLB-015 | Testability | Minimum test coverage | Pest unit tests for all BR- items (currently 0 tests) | P1 |

### E.2 Risk Register

| Risk-ID | Risk | Severity | Likelihood | Impact | Mitigation |
|---------|------|---------|-----------|--------|-----------|
| RSK-SLB-001 | CompetencieController ZERO auth — any authenticated tenant user can create/edit/delete competencies without permission | CRITICAL | Certain (code confirmed) | High | Fix: Add Gate::authorize() to all 9 methods; use validated() |
| RSK-SLB-002 | TopicController::destroy() calls forceDelete — permanent topic loss on delete click | CRITICAL | Certain (code confirmed) | High | Fix: Change destroy() to call $topic->delete(); move force-delete to explicit route |
| RSK-SLB-003 | Competencie model lacks SoftDeletes — destroy() cannot soft-delete even if fixed | HIGH | Certain (model confirmed) | Medium | Fix: Add SoftDeletes trait + deleted_at column migration |
| RSK-SLB-004 | EnsureTenantHasModule middleware status unverified post-route migration | HIGH | Unknown (code unread) | Medium | Check SyllabusServiceProvider for middleware array; add if missing |
| RSK-SLB-005 | ReleaseLmsResources cron has no date filter — processes ALL schedule entries on every run | MEDIUM | Certain (code confirmed) | Medium | Add date range filter: only process entries where planned_end_date <= today or is_active = 1 already |
| RSK-SLB-006 | Performance category range overlap not enforced by app or DB | MEDIUM | Likely (service missing) | Medium | Implement overlap check service in PerformanceCategoryController |
| RSK-SLB-007 | Grade division range overlap not enforced | MEDIUM | Likely (service missing) | Medium | Same as above for GradeDivisionController |
| RSK-SLB-008 | autoSchedule may recalculate dates for released topics (is_active = 1) — consistency risk | MEDIUM | Likely (code unguarded) | Medium | Add guard: skip if is_active = 1 in autoSchedule loop |
| RSK-SLB-009 | orphaned topics on parent force-delete then child restore | LOW | Unlikely in normal use | Low | Pre-check parent existence before restore; return informative error |
| RSK-SLB-010 | slb_books vs bok_books ambiguity — lesson textbook FK target unclear | LOW | Certain (ambiguous in code) | Low | Resolve: choose one authoritative table; update FK and migration comment |
| RSK-SLB-011 | Three duplicate policy pairs never get cleaned — wrong policy enforced for some routes | LOW | Possible | Low | Remove duplicate pairs; unify routing to correct policy |
| RSK-SLB-012 | Study Notes subsystem has no controller/routes — 4 tables completely unused | LOW | Certain (confirmed) | Low | Build StudyNotesController and routes in next sprint |
| RSK-SLB-013 | FormRequest::authorize() hardcodes true (D30 systemic) — FormRequests provide no auth | MEDIUM | Likely per platform pattern | Medium | Fix all Syllabus FormRequests to use Gate check in authorize() |
| RSK-SLB-014 | Deep circular competency prevention missing — only one-level check implemented | LOW | Possible in edge cases | Low | Implement recursive ancestor check before setting parent |

---

## Part F — Prioritization and Effort Estimation

### F.1 MoSCoW Classification

| ID | Feature / Fix | MoSCoW | Complexity | Effort (days) | Sprint |
|----|--------------|--------|-----------|--------------|-------|
| P0-SLB-001 | Fix: Add Gate::authorize() to all CompetencieController methods | MUST | Low | 0.5 | Sprint 1 |
| P0-SLB-002 | Fix: Use $request->validated() in CompetencieController::store() and update() | MUST | Low | 0.25 | Sprint 1 |
| P0-SLB-003 | Fix: Change TopicController::destroy() from forceDelete() to delete() | MUST | Low | 0.25 | Sprint 1 |
| P0-SLB-004 | Fix: Add SoftDeletes trait to Competencie model + migration for deleted_at | MUST | Low | 0.5 | Sprint 1 |
| P0-SLB-005 | Fix: Verify and add EnsureTenantHasModule middleware in SyllabusServiceProvider | MUST | Low | 0.5 | Sprint 1 |
| P0-SLB-006 | Fix: Add Gate::authorize() to remaining TopicController methods (~22 methods) | MUST | Medium | 1.0 | Sprint 1 |
| P0-SLB-007 | Fix: Fix all FormRequest::authorize() from hardcoded true to real Gate check | MUST | Medium | 1.5 | Sprint 1 |
| P1-SLB-001 | Fix: Add date filter to ReleaseLmsResources cron (no all-schedules scan) | SHOULD | Low | 0.5 | Sprint 2 |
| P1-SLB-002 | Fix: Add guard in autoSchedule to skip is_active = 1 entries | SHOULD | Low | 0.25 | Sprint 2 |
| P1-SLB-003 | Implement: Performance category range overlap validation service | SHOULD | Medium | 1.0 | Sprint 2 |
| P1-SLB-004 | Implement: Grade division range overlap validation service | SHOULD | Medium | 1.0 | Sprint 2 |
| P1-SLB-005 | Implement: Deep circular competency detection in service method | SHOULD | Medium | 1.0 | Sprint 2 |
| P1-SLB-006 | Implement: Study Notes CRUD controller + routes (StudyNotesController) | SHOULD | Medium | 2.0 | Sprint 3 |
| P1-SLB-007 | Implement: Report export (Excel/PDF) for all report tabs | SHOULD | Medium | 2.0 | Sprint 3 |
| P1-SLB-008 | Implement: is_system_defined guard in LessonController (update/delete block) | SHOULD | Low | 0.5 | Sprint 2 |
| P2-SLB-001 | Implement: Advanced Coverage Audit — Bloom radar chart, NEP compliance | COULD | High | 4.0 | Sprint 4 |
| P2-SLB-002 | Implement: Planning Accuracy teacher-level attribution and contextual fault detection | COULD | High | 3.0 | Sprint 4 |
| P2-SLB-003 | Resolve: slb_books vs bok_books FK ambiguity — choose one | COULD | Low | 0.5 | Sprint 2 |
| P2-SLB-004 | Implement: Notifications on topic release (push to students/parents) | COULD | Medium | 2.0 | Sprint 4 |
| P3-SLB-001 | Clean up: Remove 3 duplicate policy pairs | WON'T (this sprint) | Low | 0.5 | Backlog |
| P3-SLB-002 | Rename: Competencie → Competency throughout module | WON'T (this sprint) | Low | 1.0 | Backlog |
| P3-SLB-003 | Implement: REST API for Student/Parent Portal | WON'T (this sprint) | High | 5.0 | Backlog |
| P3-SLB-004 | Implement: NEP Compliance Ledger export | WON'T (this sprint) | Medium | 2.0 | Backlog |

**Sprint 1 Total Effort (P0 fixes):** ~4.5 developer-days
**Sprint 2 Total Effort (validations + guards):** ~4.75 developer-days
**Sprint 3 Total Effort (new features):** ~4.5 developer-days
**Sprint 4 Total Effort (advanced analytics):** ~9 developer-days
**Backlog Total:** ~8.5 developer-days

---

## Part G — User Stories

### US-SLB-001: Create a New Lesson
**As an Academic Coordinator**, I want to create a lesson for a class and subject so that I can organise the curriculum chapter-by-chapter for the academic session.

**Acceptance Criteria:**
- I can select the Academic Session, Class, Subject, and Textbook
- The system auto-generates the lesson code; I do not type it manually
- I can set learning objectives as a list
- I can order the lesson relative to other lessons for the same class+subject
- The lesson is immediately visible in the Lesson Sequencing tab for scheduling

---

### US-SLB-002: Build the Topic Tree
**As a Subject Teacher**, I want to add topics, sub-topics, and mini-topics under each lesson so that the curriculum hierarchy is structured for period planning and student tracking.

**Acceptance Criteria:**
- I can add a root topic (level 0) under a lesson
- I can add sub-topics under any existing topic (one level deeper)
- The tree is displayed visually with expand/collapse; I can drag to reorder
- Each topic gets a stable analytics_code I cannot change
- Deleting a topic with children is blocked; I must delete children first

---

### US-SLB-003: Sequence Topics for Teaching
**As a Subject Teacher**, I want to arrange topics in the order I plan to teach them and assign how many periods I need for each, so I can plan the term's teaching schedule.

**Acceptance Criteria:**
- I can drag topics in the Lesson Sequencing tab to reorder them
- I set a planned_periods count for each topic
- The system warns me if any topic exceeds the daily period limit
- The system warns me if the total periods exceed the weekly limit
- I can save and come back to adjust sequencing before scheduling dates

---

### US-SLB-004: Auto-Schedule the Term
**As an Academic Coordinator**, I want to provide a start date and have the system calculate when each topic will be taught, so I do not have to manually enter dates for 200+ schedule entries.

**Acceptance Criteria:**
- I enter a start date in the Date Planning tab and click Auto-Schedule
- The system distributes topics across teaching days based on periods-per-day
- Topics with planned_periods = 0 are skipped
- Locked entries retain their existing dates
- I review the calculated dates before saving; I can adjust individual entries manually

---

### US-SLB-005: Lock a Confirmed Schedule Entry
**As an Academic Coordinator**, I want to lock a topic's schedule dates after confirming them with the Principal, so that auto-schedule re-runs or bulk edits do not accidentally overwrite confirmed plans.

**Acceptance Criteria:**
- I click the lock icon on a schedule row
- The row shows a lock indicator; the dates cannot be changed by auto-schedule or bulk-edit
- I can unlock the row at any time (if I have lesson-update permission)
- Locking does not prevent the teacher from marking the topic as released

---

### US-SLB-006: Release a Topic After Teaching
**As a Subject Teacher**, I want to mark a topic as taught so that my students can immediately access the linked homework, quizzes, and quests for that topic.

**Acceptance Criteria:**
- I open the Topic Release Control tab and find my class section
- I toggle the release switch for the topic I just finished teaching
- The system shows a success message; the homework/quiz/quest becomes visible to students
- The syllabus coverage percentage updates on the dashboard
- If no LMS resources are linked, the release still succeeds (no error)

---

### US-SLB-007: View Coverage Dashboard
**As a Principal**, I want to see at a glance which classes are on-track and which are at risk, so I can intervene before the end of term.

**Acceptance Criteria:**
- The dashboard shows overall school coverage percentage as a dial/progress indicator
- A table lists each class section: total topics, released topics, overdue topics, coverage %
- Sections more than 5% below expected coverage are highlighted in red
- Teacher accuracy ranking shows the top 10 teachers by on-time release rate
- All data refreshes when I change the Academic Session or Class filter

---

### US-SLB-008: Configure LMS Release Levels
**As a School Administrator**, I want to set which topic hierarchy level triggers release of homework, quizzes, and quests separately, so I can align LMS gating with my school's teaching practice.

**Acceptance Criteria:**
- I open Syllabus Settings from the Planning tab
- I set one hierarchy level each for Homework Release, Quiz Release, and Quest Release
- If I try to set two resource types to the same level, the system rejects it with a clear message
- After saving, the nightly cron and manual toggles both use the new settings immediately

---

## Part H — KPI and Reporting Specification

### H.1 Key Performance Indicators

| KPI | Formula | Scope | Update Frequency | Owner |
|-----|---------|-------|-----------------|-------|
| Syllabus Coverage % | (Released Schedule Entries / Total Schedule Entries) × 100 | Per academic session, class, subject | On each topic release | Teacher → HOD |
| Overdue Topics | Count of entries where planned_end_date < today AND is_active = 0 | Per section, per subject | Daily (or on page load) | HOD → Principal |
| On-Time Delivery Rate (Teacher) | (Topics released on or before planned_end_date) / (Total released topics) × 100 | Per teacher, per session | On each topic release | HOD |
| Planning Accuracy Score | Average variance days across released topics in scope (negative = ahead, positive = delayed) | Per section, per term | End of term | Academic Coordinator |
| LOT/HOT Ratio | Count(topics at Bloom level ≥ 4) / Count(all topics) × 100 | Per class, per subject | On competency mapping save | Academic Coordinator |
| Resource Health | Count(topics with question_bank_count ≥ 3) / Count(assessable topics) × 100 | Per lesson | On question creation | IT Content Team |

### H.2 Report Frequency and Audience Matrix

| Report | Daily | Weekly | Monthly | Term End | On-Demand | Principal | HOD | Teacher | Admin |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Coverage Dashboard | - | Rec | - | - | Yes | Yes | Yes | Yes (own) | Yes |
| Progress Tracker | - | Rec | - | - | Yes | Yes | Yes | Yes (own) | Yes |
| Coverage Audit | - | - | - | Rec | Yes | Yes | Yes | No | Yes |
| Resource Matrix | - | - | Rec | - | Yes | Yes | Yes | No | Yes |
| Planning Accuracy | - | - | - | Yes | Yes | Yes | Yes | Yes (own) | Yes |
| Bloom Distribution | - | - | Rec | - | Yes | Yes | Yes | No | Yes |

---

## Part I — Gap Analysis

### I.1 Feature Gap Summary

| Gap-ID | Gap Description | Severity | Root Cause | Fix Owner | Sprint |
|--------|----------------|---------|------------|-----------|-------|
| GAP-SLB-001 | CompetencieController has ZERO Gate::authorize() calls — all 9 methods publicly accessible to any authenticated user | P0 Security | V2 noted as SEC-01; never fixed | Backend Dev | Sprint 1 |
| GAP-SLB-002 | CompetencieController::store() and update() use raw $request->all() instead of $request->validated() | P0 Security | D25 systemic pattern | Backend Dev | Sprint 1 |
| GAP-SLB-003 | TopicController::destroy() calls forceDelete() instead of delete() — permanent data loss on every delete | P0 Bug | Code error | Backend Dev | Sprint 1 |
| GAP-SLB-004 | Competencie model lacks SoftDeletes trait and deleted_at column | P0 Bug | Model incomplete | Backend Dev | Sprint 1 |
| GAP-SLB-005 | EnsureTenantHasModule middleware presence unverified after route migration to web.php | P0 Security | Migration side-effect | Backend Dev | Sprint 1 |
| GAP-SLB-006 | 15 FormRequests: authorize() returns hardcoded true (D30 systemic pattern) | P0 Security | Platform-wide gap | Backend Dev | Sprint 1 |
| GAP-SLB-007 | autoSchedule does not guard against recalculating dates for already-released entries (is_active = 1) | P1 Bug | Logic omission | Backend Dev | Sprint 2 |
| GAP-SLB-008 | ReleaseLmsResources cron lacks date filter — processes ALL schedule entries for ALL tenants on every run (potential performance/cost issue at scale) | P1 Performance | Logic omission | Backend Dev | Sprint 2 |
| GAP-SLB-009 | Performance category percentage range overlap not enforced (BR-SLB-007) | P1 Validation | Service layer missing | Backend Dev | Sprint 2 |
| GAP-SLB-010 | Grade division percentage range overlap not enforced (BR-SLB-023) | P1 Validation | Service layer missing | Backend Dev | Sprint 2 |
| GAP-SLB-011 | Deep circular competency detection missing — only direct circular (A→B where B=A) checked; 3-node+ cycles pass | P1 Validation | Incomplete implementation | Backend Dev | Sprint 2 |
| GAP-SLB-012 | is_system_defined guard missing in LessonController — system-defined lessons can be edited/deleted (BR-SLB-010) | P1 Bug | Guard not implemented | Backend Dev | Sprint 2 |
| GAP-SLB-013 | Coverage Audit tab: V1 spec requires Bloom radar chart, weighted competency analysis, NEP compliance ledger — report() only shows basic schedule list | P2 Feature | Not implemented post-V1 | Backend Dev + Frontend | Sprint 4 |
| GAP-SLB-014 | Resource Matrix: video, PDF, image counts always 0 — study materials not implemented; question count is proxy only | P2 Feature | StudyMaterial model exists; controller/routes not built | Backend Dev | Sprint 3 |
| GAP-SLB-015 | Planning Accuracy: teacher-level fault attribution (Planning Fault vs Execution Fault from V1 spec) not implemented | P2 Feature | V1 advanced spec not yet implemented | Backend Dev | Sprint 4 |
| GAP-SLB-016 | Study Notes subsystem: 4 tables exist (slb_notes, slb_notes_files, slb_notes_downloads, slb_notes_ratings); controller and routes completely missing | P1 Feature | Routes/controller not built | Backend Dev | Sprint 3 |
| GAP-SLB-017 | Export to PDF/Excel: UI placeholders exist for all reports; no backend export implementation | P1 Feature | Not built | Backend Dev | Sprint 3 |
| GAP-SLB-018 | Coverage formula divergence: V2 specified coverage = (topics with taught_by_teacher_id SET AND can_use_for_syllabus_status = 1) / total; implementation uses is_active = 1 on schedule | Informational | Design decision diverged from spec | Acknowledge + document | — |
| GAP-SLB-019 | slb_books vs bok_books FK ambiguity: lesson textbook FK target unclear (migration creates slb_books; SyllabusController imports BokBook model from SyllabusBooks) | P2 Architecture | Module boundary not resolved | DB Architect | Sprint 2 |
| GAP-SLB-020 | 3 duplicate policy pairs: CompetenciePolicy/CompetencyPolicy, GradeDivisionMasterPolicy/GradeDivisionPolicy, QuesTypeSpecificityPolicy/QueTypeSpecifityPolicy | P3 Maintenance | Never cleaned up | Backend Dev | Backlog |
| GAP-SLB-021 | 0 Pest test files — no automated test coverage for any business rule or integration | P1 Quality | Platform-wide gap for this module | Test Agent | Sprint 3 |
| GAP-SLB-022 | scheduled_year_week format (YYYYWW) not explicitly validated in FormRequest — invalid values stored silently | P2 Validation | Validation omission | Backend Dev | Sprint 2 |

### I.2 Gap Severity Count

| Severity | Count |
|---------|-------|
| P0 (Critical — must fix before any feature work) | 6 (GAP-001 to 006) |
| P1 (Should fix this release) | 8 (GAP-007 to 012, 016, 017, 021) |
| P2 (Fix in next release) | 7 (GAP-013, 014, 015, 018, 019, 022) |
| P3 (Backlog/housekeeping) | 2 (GAP-020, cleanup) |
| Informational (acknowledged design divergence) | 1 (GAP-018) |
| **Total** | **22 gaps** |

### I.3 Implementation Completeness Estimate

| Feature Area | V2 Estimate | Actual (2026-06-30) | Delta | Notes |
|-------------|:-----------:|:------------------:|:-----:|-------|
| Lesson Management | 85% | 90% | +5% | UpdateLessonRequest added; system-defined guard still missing |
| Topic Hierarchy | 80% | 85% | +5% | P0 bug: destroy() calls forceDelete |
| Competency Framework | 50% | 70% | +20% | auth/validation gaps remain P0 |
| Topic-Competency Mapping | 60% | 70% | +10% | Basic CRUD complete |
| Bloom's / Reference Data | 90% | 95% | +5% | Near complete |
| Syllabus Schedule & Delivery | 75% | 85% | +10% | markComplete working; cron guard missing |
| Schedule Lock | 0% (not in V2) | 90% | NEW | June 27 2026 feature |
| Lesson Sequencing & Periods | 0% (not in V2) | 85% | NEW | saveSequencing with period validation |
| Auto-Scheduling | 0% (not in V2) | 80% | NEW | autoSchedule working; released-entry guard missing |
| LMS Resource Release | 0% (not in V2) | 75% | NEW | Cron exists; date filter missing |
| Performance Categories | 60% | 65% | +5% | Range overlap guard missing |
| Grade Divisions | 55% | 60% | +5% | Range overlap guard missing |
| Study Notes | 0% | 30% | +30% | Tables only; no controller/routes |
| Coverage Analytics Dashboard | 0% (V2 said stub) | 70% | +70% | MAJOR: report() fully implemented June 2026 |
| Module Configuration Settings | 0% (not in V2) | 80% | NEW | saveSetting endpoint complete |
| **Overall Weighted Average** | ~55% | **~78%** | +23% | Major uplift from June 2026 commit |

---

## Part J — Feature Specification

### FSPEC-SLB-001: Schedule Lock Toggle

**Feature Name:** Schedule Lock
**Implemented In:** SyllabusController::toggleLock(); SyllabusSchedule::is_locked
**Route:** POST /syllabus/planning/{id}/toggle-lock
**Permission Required:** tenant.lesson.update
**Blade Location:** syllabus::planning (Topic Release Control or Date Planning tab — verify exact tab)

**Behaviour:**
1. Request comes in with schedule entry ID in the URL
2. Controller checks Gate::authorize('tenant.lesson.update')
3. Loads SyllabusSchedule by ID
4. Flips is_locked: `$schedule->is_locked = !$schedule->is_locked`
5. Saves and returns JSON with new state

**Downstream Effects:**
- saveScheduling() checks `if ($row['is_locked']) continue;` before updating dates
- autoSchedule() skips entries with `is_locked = true` in the returned JSON

**Edge Cases:**
- Toggling lock on an entry with is_active = 1 (already released): permitted — lock only controls dates, not release state
- Bulk save after individual locks: only affects unlocked entries

**Open Question:** Does the UI require a confirm dialog before locking? V1 spec is silent on this.

---

### FSPEC-SLB-002: LMS Resource Release Cron (ReleaseLmsResources)

**Feature Name:** Automated Nightly Resource Release
**Artisan Command:** tenant:syllabus:release-resources
**File:** Modules/Syllabus/app/Console/ReleaseLmsResources.php
**Registered In:** routes/console.php (schedule hourly / nightly — verify exact frequency)

**Algorithm:**
```
foreach Tenant::all() as $tenant:
  initializeTenancy($tenant)
  $homeworkLevel = sch_config.get('syllabus_homework_release_level')
  $quizLevel = sch_config.get('syllabus_quiz_release_level')
  $questLevel = sch_config.get('syllabus_quest_release_level')

  $schedules = SyllabusSchedule::with('topicLevelType')->get()

  foreach $schedules as $schedule:
    if $schedule->topicLevelType->level_value == $homeworkLevel:
      TopicReleaseControlService::syncHomeworkPublic($schedule, is_public: $schedule->is_active)
    if $schedule->topicLevelType->level_value == $quizLevel:
      TopicReleaseControlService::syncQuizPublic($schedule, is_public: $schedule->is_active)
    if $schedule->topicLevelType->level_value == $questLevel:
      TopicReleaseControlService::syncQuestPublic($schedule, is_public: $schedule->is_active)

  endTenancy()
```

**Known Issues (from GAP-SLB-008):**
- No date filter: processes ALL schedule entries (past, present, future) on every run
- At scale (1000 tenants × 5000 schedules): could process 5M rows per run
- Fix: Add `->where('planned_end_date', '<=', now())` or `->where('is_active', 1)` to limit to actionable entries

**Integration Points:**
- LmsHomework: sets `hw_assignments.is_released = $is_public` for entries linked to the topic at the section level
- LmsQuiz: sets `quz_quiz_allocations.is_active = $is_public`
- LmsQuests: sets quest allocation is_active

---

### FSPEC-SLB-003: Coverage Analytics — report() Method Overview

**Route:** GET /syllabus/report
**Controller Method:** SyllabusController::report()
**Blade:** syllabus::report.index (with multiple tabs)

**Tab Implementations (confirmed in code):**

| Tab | Query Type | Output | Gap vs V1 Spec |
|-----|-----------|--------|---------------|
| Dashboard | Aggregation SQL: GROUP BY class+section+subject | stats cards, bar chart, pie chart, trend chart, teacher ranking | Missing: NEP radar, lagging-section alert threshold |
| Progress Tracker | GROUP BY class+section+subject, PAGINATE | Table with total/released/overdue | Missing: assessability filter (can_use_for_syllabus_status check) |
| Coverage Audit | JOIN schedule→topic, PAGINATE | Basic schedule list with dates | Missing: Bloom depth, competency breakdown, NEP ledger |
| Resource Matrix | JOIN schedule→topic→competencies, PAGINATE | Topic rows with competency_count as QB proxy | Missing: actual video/pdf/image counts (StudyMaterial not built) |
| Planning Accuracy | DATEDIFF(NOW(), planned_end_date) WHERE is_active = 1 | Variance table per entry | Missing: teacher fault attribution, outlier exclusion |
| Trend Data | COUNT releases by date, last 15 days | Chart data | Implemented |

---

## Part K — Module Knowledge Update Summary

The SLB_Syllabus.md module knowledge file at `/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SLB_Syllabus.md` was last updated 2026-06-30 (v1.0 initial seed).

**Key facts added/corrected by this Complete Analysis Pack:**
1. SyllabusController is NOT an empty stub — ~1776 lines, fully implemented (planning/report/scheduling/toggleLock)
2. Overall implementation estimate revised from ~55% (V2) to ~78% (this pack)
3. 7 new extended tables documented since V2: slb_config, slb_entity_groups, slb_syllabus_periods_allocation, slb_notes, slb_notes_files, slb_notes_downloads, slb_notes_ratings
4. ReleaseLmsResources artisan command documented (cron, tenant-loop, TopicReleaseControlService)
5. PeriodsAllocation model documented (new)
6. Schedule Lock (is_locked field, toggleLock endpoint) documented (new, June 27 2026)
7. 22 gaps catalogued (P0 through P3) with sprint assignments
8. 24 business rules formalized (BR-SLB-001 through BR-SLB-024)
9. 10 future enhancements logged (ENH-SLB-001 through ENH-SLB-010)
10. Coverage formula divergence documented as informational gap (GAP-SLB-018)
11. slb_books vs bok_books ambiguity flagged as P2 architecture gap (GAP-SLB-019)

---

*Complete Analysis Pack Generated: 2026-06-30*
*Agent: Business Analyst (pa-business-analyst) | Mode: X (Complete Analysis Pack)*
*Source FRD: SLB_FRD_2026-06-30.md*
*Module Knowledge: /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/module-knowledge/SLB_Syllabus.md*
