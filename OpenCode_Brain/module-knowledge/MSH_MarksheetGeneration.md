# Module Knowledge — MarksheetGeneration (MSH)

> Seeded 2026-06-29 by Business Analyst (pa-business-analyst) from live code, consolidated DDL,
> tenant migrations, models, services, seeders, and the legacy design pack (D32 / MSG_RequirementSpec).
> All counts verified against the filesystem on 2026-06-29.

---

## Module Facts

| Fact | Value | Source / Verification |
|------|-------|------------------------|
| Module name | MarksheetGeneration | `Modules/MarksheetGeneration` |
| Module code | **MSH** | `0-Prime_Ai_Detail/module_list.md` (authoritative) |
| Table prefix | `msh_` | DDL + migrations |
| Module type | Tenant (database-per-tenant, no `tenant_id` column) | D-MSG-001 |
| Layer / DB | `tenant_db` | — |
| Route prefix | `/marksheet-generation/*` (web), `/v1/marksheetgenerations` (api) | `routes/web.php`, `routes/api.php` |
| DDL tables | **23** `msh_*` tables | end-of-file table summary in DDL + 23 migration files |
| Migrations | 23 files in `database/migrations/tenant/` (`2026_06_16_115725..115747_create_msh_*`) | module's own `database/migrations/` is EMPTY (central path used) |
| Controllers | 21 | `app/Http/Controllers/` |
| Models | 24 | `app/Models/` |
| Services | 33 (`.php`, recursive — incl. `Computation/` + `ScoreReaders/`) | `app/Services/` |
| FormRequests | 19 | `app/Http/Requests/` |
| Policies | 18 (module-local, registered in `MarksheetGenerationServiceProvider`) | `app/Policies/` |
| Jobs | 1 (`ComputeMarksheetJob`) | `app/Jobs/` |
| Events | 1 (`ComputationCompleted`) | `app/Events/` |
| Exports | 2 (`MarksheetScheduleExport`, `StudentResultExport`) | `app/Exports/` |
| Seeders | 4 | `database/seeders/` |
| Views | 98 blade files | `resources/views/` |
| Route lines | 180 (web + api) | — |
| Tests | 10 module-level (`tests/`) + 2 central tests referencing the module | — |
| FRD | `4-Requirement_Module_wise/0-FRD_Documents/MSH_FRD_Complete_2026-06-29.md` (Complete Analysis Pack, this seeding session) | — |

### ⚠ Code/Prefix naming note
- The **module code is `MSH`** per `module_list.md` (the single source of truth) and the `msh_` prefix.
- The legacy design pack (`MSG_RequirementSpec.md`, `MarksheetGeneration_DDL_v1.sql`, decision **D32**) labels the
  module **`MSG`**. `MSG` = legacy doc code only; `MSH` = canonical. They refer to the same module. The legacy
  rule IDs `BR-MSG-NNN` / `FR-MSG-NNN` are retained inside source docs but the FRD renumbers to `REQ-MSH-`/`BR-MSH-`.

---

## DDL Table Inventory (23 tables)

> DDL: `2-DDL_Tenant_Consolidated/MarksheetGeneration_DDL_v1.sql`.
> NOTE: the DDL header line ("22 tables") and the Section-2 header ("10 configuration tables") are **stale**;
> the authoritative end-of-file table summary lists **23** tables (config block is actually 11). 23 migrations confirm 23.

**Masters (3)** — reference/lookup, no FK to other msh_ tables:
1. `msh_marksheet_types` — school-configurable marksheet types (Unit Test, Term-1, Annual). Seeded: UNIT_TEST, TERM1, ANNUAL.
2. `msh_source_components` — fixed lookup of scoring sources. Seeded 4: EXAM (`is_mandatory=1`), HOMEWORK, QUIZ, QUEST.
3. `msh_ia_component_types` — Internal Assessment types. Seeded 4: NOTEBOOK, SUB_ENRICHMENT, PERIODIC_ASSESS, PARTICIPATION.

**Configuration (11)** — school admin sets up before generation:
4. `msh_class_groups` — marksheet-specific class grouping (Primary/Middle/Secondary). Separate from timetable `sch_class_groups_jnt` (D-MSG-003).
5. `msh_class_group_items_jnt` — classes ↔ class group (FK `sch_classes`).
6. `msh_exam_groups` — group exam types into terms (Term-1, Annual); has `start_date`/`end_date` for HW/Quiz/Quest range.
7. `msh_exam_group_items_jnt` — exam group ↔ `lms_exam_types`.
8. `msh_config_templates` — reusable blueprint: links exam group + grading schema (`slb_grade_division_master`); holds `passing_percentage`, `compartment_max_failures`, `is_best_of_n_enabled`/`best_of_n_count`, `is_locked`, `board_code`.
9. `msh_template_scholastic_components` — source components + weightage per template (sum must = 100).
10. `msh_template_exam_weightages` — per-exam-type weightage within the Exam component (sum must = 100).
11. `msh_template_ia_components` — IA component max marks per template.
12. `msh_template_coscholastic_components` — co-scholastic areas (Work Ed, Art, Health & PE, Discipline); `grading_scale` (3/5-point), `is_ba_linked`.
13. `msh_class_config_jnt` — assigns template to class (direct) OR class-group (inherited); CHECK enforces exactly one target; direct overrides group.
14. `msh_subject_practical_configs` — theory/practical max-marks split per class-subject.

**Schedule (2)** — defines when/for whom:
15. `msh_marksheet_schedules` — a generation event; `status_id` FK → dropdown; lock/unlock fields; `last_computed_at`, `total_students`.
16. `msh_schedule_class_jnt` — class-sections (`sch_class_section_jnt`) included in a schedule.

**Result (6)** — system-computed (written by ComputeMarksheetJob):
17. `msh_student_results` — aggregate per student per schedule: grand total/max, %, overall grade, division, rank_in_section/class, promotion_status, result_status (DECLARED/WITHHELD).
18. `msh_student_subject_results` — per-subject result: exam weighted, theory/practical, HW/Quiz/Quest/IA, subject total/max/%/grade, is_passed.
19. `msh_student_subject_exam_marks` — **core matrix** (student × subject × exam-type), raw marks + result_status + `exam_result_id` traceability. Highest volume (~15K–80K rows/schedule; ~60K–400K rows/school/year).
20. `msh_student_ia_marks` — IA marks (teacher entry).
21. `msh_student_coscholastic_results` — co-scholastic grades (teacher entry; Discipline auto from BA if `is_auto_from_ba`).
22. `msh_student_attendance` — working days vs present per student per schedule (manual Phase 1; auto Phase 2).

**Audit (1)** — immutable:
23. `msh_computation_logs` — one row per COMPUTE/RECOMPUTE/PUBLISH/UNLOCK/LOCK run; **no `deleted_at`** (immutable).

### Three-way reconcile (DDL ↔ migration ↔ model) — verified 2026-06-29
- **FK column types MATCH DDL** in the live migrations: FK columns use `unsignedInteger` (INT UNSIGNED) and
  `academic_session_id` uses `unsignedSmallInteger` (SMALLINT UNSIGNED), matching the DDL PK targets. The
  systemic `unsignedBigInteger` drift recorded in the April 2026 in-repo audit (`AUDIT_REPORT.md`, findings
  MSG-P0-S-001..024) has been **resolved** in current code. No leftover `repoint_*`/`fix_msh_*` corrective migrations.
- **Dropdown table name divergence:** DDL FK comments reference `sys_dropdown_table`; the live migration + seeder +
  models use **`sys_dropdowns`** (the real tenant table). The DDL text is stale on this name; code is correct.
- `msh_class_config_jnt` XOR CHECK (`class_id` xor `class_group_id`) is present in the DDL; enforce/verify at app layer.
- No ENUM columns anywhere in the `msh_*` migrations (D-MSG-002 upheld); status/type via `sys_dropdowns` or lookup tables.

---

## Status Lifecycle (FSM)

`msh_marksheet_schedules.status_id` (driven by `sys_dropdowns`, key `msh_marksheet_schedules.status_id`):

`DRAFT → COMPUTED → REVIEWED → PUBLISHED → LOCKED`, plus `PUBLISHED/REVIEWED → (unlock) → COMPUTED`.

Implemented in `MarksheetScheduleLifecycleService`:
- `review()` — guards status == COMPUTED → REVIEWED (+ audit log row).
- `publish()` — guards status == REVIEWED → PUBLISHED, **and calls `config->lockTemplate()`** (BR-MSG-027 enforced),
  inside a DB transaction (+ audit log).
- `unlock($reason)` — requires reason → flips to COMPUTED, sets `unlock_reason`/`unlocked_by`/`unlocked_at`, writes
  `msh_computation_logs` UNLOCK row (BR-MSG-017 enforced).
- `lock()` — guards status == PUBLISHED → LOCKED.

---

## Computation Engine

- `MarksheetScheduleController::compute` → dispatches `ComputeMarksheetJob` (queued, `ShouldQueue`).
- `ComputeMarksheetJob`: `$tries = 1` (no auto-retry — partial state would linger), carries `triggeredByUserId`,
  and implements `failed(Throwable)` to close the open computation-log row as FAILED.
- `MarksheetComputationService::computeForSchedule($scheduleId, $triggeredByUserId)`:
  - Per class-section, resolves template (direct → group), loads students/subjects, persists results in a transaction.
  - **`created_by`/`updated_by` propagate the real `triggeredByUserId`** (the April-audit hardcoded `created_by=1`
    defect is fixed).
  - `result_status` on aggregate results is left **NULL at compute time**, set to `DECLARED` on publish.
  - Helpers: `Computation/GradeResolver`, `PracticalSplitter`, `RankCalculator`, `WeightageApplier`
    (+ DTOs: `ComputationResult`, `GradeBand`, `StudentSubjectContext`, `SubjectResult`).
- ScoreReaders (read-only, one per source): `ExamScoreReader`, `HomeworkScoreReader`, `QuizScoreReader`,
  `QuestScoreReader`, `BehaviouralScoreReader`, `AttendanceReader` (+ `ScoreReaderInterface`, `ScoreResult`,
  `AttendanceRecord`, `Concerns/ResolvesClassEnrollment`). **Zero writes to source modules** — boundary clean (D-MSG-004).

---

## Cross-Module Dependencies (read-only — MSH never writes these)

| Direction | Module | Data | Mechanism |
|-----------|--------|------|-----------|
| Inbound | LmsExam | `lms_exam_results` (per-paper scores), `lms_exam_papers`, `lms_exams`, `lms_exam_types` | read query (ExamScoreReader) |
| Inbound | LmsHomework | `lms_homework_submissions.marks_obtained` (graded, date-ranged) | read query |
| Inbound | LmsQuiz / LmsQuests | `lms_quiz_quest_results` (assessment_type QUIZ/QUEST) | read query |
| Inbound | BehaviouralAssessment | behavioural score for Co-Scholastic Discipline (when `is_ba_linked`) | reader/service |
| Inbound | SchoolSetup | `sch_classes`, `sch_sections`, `sch_class_section_jnt`, `sch_subjects`, academic session | read query |
| Inbound | Syllabus | `slb_grade_division_master` (grading/division bands) | read query |
| Inbound | StudentProfile | `std_students`, enrolment / academic session | read query |
| Inbound | SystemConfig | `sys_dropdowns` (schedule status master), `sys_users` | read query |
| Inbound | Template | `MARKSHEET_PRINT` template render for PDF/print HTML | `Template::render()` |
| Outbound | StudentPortal / ParentPortal | published `msh_student_results` / `msh_student_subject_results` | read by those portals |
| Outbound | Notification | publish event → notify teachers/students/parents | event (planned) |

---

## Known Gaps & Open Issues

**Open design question (carry-forward):**
- **Q-13 (P1, highest legacy risk): theory/practical paper identification.** `lms_exam_papers` has no `is_practical`
  flag. Resolution adopted: match paper `total_marks` against `msh_subject_practical_configs.theory_max_marks` /
  `practical_max_marks`. Brittle if a school's theory and practical papers share the same max marks — verify in audit.

**Implementation gaps to confirm in technical audit (per BR coverage):**
- BR-MSH (BA → Co-Scholastic Discipline auto-feed): `BehaviouralScoreReader` + `is_ba_linked` flag exist; confirm the
  end-to-end auto-population path and the `ba_config.is_result_integration_enabled` gate.
- Attendance auto-feed: `msh_student_attendance` + `AttendanceReader` exist; the dedicated `att_*` module is not built,
  so Phase-1 manual entry is the live path.
- `rank_in_class` (cross-section) vs `rank_in_section`: confirm both are populated (April audit had class-rank stubbed).
- PDF: **not DomPDF.** `StudentResultController::downloadPdf` redirects to the browser print page (`?download=1&auto=1`,
  html2pdf.js) using the Template module's `MARKSHEET_PRINT` render — deliberate (DomPDF had Hindi/image issues). Confirm
  bulk ZIP export path.

**Stale artifact warning:**
- `Modules/MarksheetGeneration/AUDIT_REPORT.md` (dated 2026-04-18, 79 findings / 35 P0) **predates** the current code.
  Many of its P0 items (schema FK drift, hardcoded `created_by=1`, missing template lock, missing unlock reason+audit,
  missing review action, no `failed()` handler, Best-of-N missing, weightage-sum validation missing) are **resolved**
  in the live tree. Treat it as historical; re-audit against current code before acting on any finding.

---

## Design Decisions (from D32 / MSG_RequirementSpec)

- **D-MSG-001** No `tenant_id` (database-per-tenant).
- **D-MSG-002** No ENUMs — `sys_dropdowns` / lookup tables (D29).
- **D-MSG-003** `msh_class_groups` is a NEW table, separate from timetable `sch_class_groups_jnt`.
- **D-MSG-004** Online/Offline exams transparent — both read from `lms_exam_results`; paper mode irrelevant.
- **D-MSG-005** Absent read from `lms_exam_results.result_status = 'ABSENT'` → marks NULL, shown "AB".
- **D-MSG-006** IA marks owned by MSH (teacher entry), not sourced elsewhere.
- **D-MSG-007** Co-Scholastic owned by MSH; Discipline auto-populated from BA when linked.
- **D-MSG-008** Theory/Practical paper split via `total_marks` matching against practical config (Q-13).

---

## FRD Summary

- **File:** `4-Requirement_Module_wise/0-FRD_Documents/MSH_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — FRD is Section 1 spine; RTM, BR register, conditions, workflows, FSM, data dictionary, dependency map, NFR, risk, prioritization, sprint tasks, user stories, reports as subsequent `## Section`s).
- **Counts:** 18 functional requirements (REQ-MSH-001..018), 30 business rules (BR-MSH-001..030), 6 workflows,
  5 reports (RPT-MSH-001..005), 6 enhancements (ENH-MSH-001..006).
- **Priority split:** P0 = 10, P1 = 6, P2 = 2.
- A standalone FRD file (`MSH_FRD_2026-06-29.md`) was not generated separately — the Complete file carries the full
  10-section FRD as its lead sections per the Complete Analysis Pack convention.

---

## Pending Next Steps (post-FRD handoffs)

1. DDL Schema gap analysis (DB Architect / Technical Auditor Mode A) — confirm 23 tables, XOR CHECK, dropdown FK name.
2. Application Code gap (Technical Auditor Mode B, FRD-driven) — re-audit against current code (supersede 2026-04-18 report).
3. Business-Rule enforcement (Mode C) — verify BR-MSH-001..030, esp. weightage-sum=100, Best-of-N, elective resolution, Q-13 split.
4. Completion scoring (Status_Analyzer, 6-dim).
5. Test coverage gap (Testing Architect) — 10 module tests exist (HappyPath compute, BestOfN, weightage sum, withhold, score-reader contract); map to acceptance criteria.

---

## Lessons Learned

- [2026-06-29 | Business Analyst] MSH live code is materially ahead of its in-repo `AUDIT_REPORT.md` (2026-04-18). Always
  verify the lifecycle service, computation service, and migration FK types against the current tree before trusting an
  audit dated weeks earlier — the schema-drift and computation P0s were already fixed.
- [2026-06-29 | Business Analyst] Module code is **MSH** (module_list.md) but every legacy design artifact says **MSG**.
  Carry the alias explicitly so downstream agents don't treat them as two modules.
- [2026-06-29 | Business Analyst] The DDL's own header/section table counts ("22", "10 config") disagree with its
  end-of-file summary and the migration count — trust the migration count (23) + end summary, not the prose headers.
- [2026-06-29 | Business Analyst] PDF is intentionally NOT DomPDF here (Hindi/image issues) — it routes through the
  Template module + browser html2pdf.js. Don't flag "missing DomPDF" as a defect.

---

## Version History

| Date | Change | Agent |
|------|--------|-------|
| 2026-06-29 | Seeded from live code + DDL + migrations + design pack; FRD Complete pack produced. | Business Analyst |
