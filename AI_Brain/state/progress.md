# Development Progress Tracker

## Completed Modules (100%)

### Core Platform
- [x] **Prime** — Tenant management, plans, billing, users, roles, modules, menus, geography
- [x] **GlobalMaster** — Countries, states, cities, boards, languages, plans, dropdowns
- [x] **SystemConfig** — Settings, menus, translations
- [x] **Billing** — Invoice generation, payment tracking, billing cycles
- [x] **Dashboard** — Admin dashboards
- [x] **Documentation** — Knowledge base, help docs

### School Administration
- [x] **SchoolSetup** — Classes, sections, subjects, teachers, rooms, buildings, departments, designations
- [x] **StudentProfile** — Student data, health profiles, documents, attendance, guardians
- [x] **Transport** — Vehicles, routes, trips, driver attendance, student boarding, fees, maintenance
- [x] **Vendor** — Vendor management, agreements, items, invoices, payments
- [x] **Complaint** — Categories, SLA, actions, AI insights, medical checks
- [x] **Notification** — Multi-channel notifications, templates, delivery logs
- [x] **Payment** — Razorpay integration, payment processing
- [x] **Scheduler** — Job scheduling

### Academic & Curriculum
- [x] **Syllabus** — Lessons, topics, competencies, Bloom taxonomy, cognitive skills
- [x] **SyllabusBooks** — Textbooks, authors, topic mappings
- [x] **QuestionBank** — Questions, tags, versions, statistics, AI generation

### Timetable
- [x] **SmartTimetable** — All 10 stages + Parallel Periods feature complete:
  - Stage 1: Schema & Foundation (28 table renames, 47 models)
  - Stage 2: Seeders (9 config seeders)
  - Stage 3: Validation Framework
  - Stage 4: Activity & Generation Updates (v7.6 column renames)
  - Stage 5: Advanced Generation (TabuSearch, SimulatedAnnealing, ConflictDetection)
  - Stage 6: Post-Generation Analytics (AnalyticsService, CSV exports)
  - Stage 7: Manual Refinement (RefinementService, swap/move/lock)
  - Stage 8: Substitution Management (SubstitutionService, pattern learning)
  - Stage 9: API & Integration (REST API, Standard Timetable views)
  - Stage 10: Testing & Cleanup (Form Requests, Pest tests)
  - **Parallel Periods** (2026-03-14): Schema, Models, UI, Solver (anchor/sibling backtrack + rescue pass), Constraint Engine, Pre/Post-Gen validation, soft constraint wiring, 9 unit tests — 100% complete

---

## Partially Complete (45–72%) — Deep-audited 2026-03-14

- [ ] **LmsQuiz** (~72%) — Admin CRUD works; auth gap (Gate commented out in index); student attempt/tracking absent
- [ ] **LmsQuests** (~68%) — Auth gap (Gate commented out in index); student progress tracking and adaptive path absent
- [ ] **Recommendation** (~65%) — 3 empty stubs on RecommendationController; wrong permissions on 8/9 StudentRecommendation routes; broken `exists:users` validation; no Form Requests; no EnsureTenantHasModule
- [ ] **LmsExam** (~65%) — `dd($e)` in prod store(); 2 controllers (Blueprint, Scope) have all Gate calls commented out; no EnsureTenantHasModule; answer submission & grading absent
- [ ] **StudentFee** (~60%) — Missing `FeeConcessionController` (imported but doesn't exist); exposed seeder route with no auth; permission prefix mismatch (`student-fee.*` vs `studentfee.*`) on 3 controllers; no Form Requests; N+1 in bulk invoice/assignment generation; no EnsureTenantHasModule
- [ ] **LmsHomework** (~60%) — Fatal crash: `HoemworkData()` missing `$request` param; `review()` has no auth or validation; no EnsureTenantHasModule
- [ ] **Hpc** (~60%) — Deep-audited 2026-03-14. 15 controllers, 26 models, 1 service (HpcReportService 788 lines), 14 FormRequests, 4 PDF templates complete. **Critical blockers:** SEC-HPC-001 (HpcController zero auth on 12/13 methods); BUG-HPC-001 (4 template controller imports missing → 500s); BUG-HPC-006 (uppercase class refs break on Linux); SEC-HPC-003 (no EnsureTenantHasModule). See known-issues.md for full list of 18 issues.
- [ ] **Library** (~45%) — NOT wired into tenant.php at all; 7 controllers with zero authorization; 5 stub methods on only registered route; N+1 in ReservationController; Prime\Setting cross-layer import; permission namespace mismatch in LibTransactionController

---

## In Progress / Partial

- [ ] **StudentPortal** (~25%) — Dashboard, complaints, notifications wired; missing: academic transcript, timetable view, homework, quiz taking, fee view, parent portal
- [ ] **Standard Timetable** (~70%) — Standard views and scheduling
- [ ] **Event Engine** (~20%) — Cross-module event system

---

## Pending Modules

- [ ] **Behavioral Assessment** — Student behavior tracking and analysis
- [ ] **Analytical Reports** — Cross-module analytics and reporting
- [ ] **Student/Parent Portal** — Student and parent facing portal
- [ ] **Accounting** — Double-entry bookkeeping, financial reports
- [ ] **HR & Payroll** — Staff payroll, leave management
- [ ] **Inventory Management** — School inventory tracking
- [ ] **Hostel Management** — Hostel rooms, allocation, fees
- [ ] **Mess/Canteen** — Meal planning, attendance, billing
- [ ] **Admission Enquiry** — Online admission process
- [ ] **Visitor Management** — Visitor registration, tracking
- [ ] **FrontDesk** — Reception management
- [ ] **Template & Certificate** — Dynamic certificate generation
- [ ] **Help Desk** — Support ticket system
- [ ] **Library** — Book circulation, fines (module exists, features pending)

---

## Testing Progress

### Infrastructure (done)
- [x] `phpunit.xml` — updated with all 16 module test suites
- [x] `.ai/memory/testing-strategy.md` — full testing strategy documented
- [x] `.ai/agents/test-agent.md` — Pest 4.x patterns and cheatsheet
- [x] `.ai/templates/test-unit.md` — unit test boilerplate
- [x] `.ai/templates/test-feature-central.md` — central feature test boilerplate
- [x] `.ai/templates/test-feature-tenant.md` — tenant feature test boilerplate

### Tests Written

| Model / Area | Module | Unit Tests | DB Tests | HTTP Tests | Total |
|-------------|--------|-----------|----------|------------|-------|
| `Student` | StudentProfile | 4 ✅ | — | — | 4 |
| `Setting` (Prime) | Prime | 16 ✅ | 14 ✅ | ❌ no routes | 30 |
| `TimetableSolution::isPlaced()` | SmartTimetable | 4 ✅ | — | — | 4 |
| Parallel group backtrack + rescue | SmartTimetable | 5 ✅ | — | — | 5 |

### Tests Pending
- All other models (to be added as we go)
- HTTP Feature tests for Setting (routes not defined in SystemConfig/routes/web.php)
- TenantTestCase base class (needed for tenant-scoped HTTP tests)

## Current Work
- [x] HPC Module deep audit complete (2026-03-14) — 18 issues logged (4 critical security, 12 bugs, 2 perf)
- [x] HPC fourth_pdf.blade.php DomPDF compatibility fix (2026-03-14) — all display:flex/grid/box-shadow/emoji/overflow-x:auto/transform:rotate converted to table-based layouts
- [x] HPC first_pdf.blade.php — 6 issues fixed (2026-03-14):
  - Fix 1: Icon table overflow — assess_content width:100%, inner icon tables width=100%, cells width=33%, icon sizes 28px→22px (self/peer/resource)
  - Fix 2: Teacher Feedback page-break split — single section_container replaced with 3 blocks (Block A: header+circle+notes, Block B: self+peer keep-together, Block C: parents+comments keep-together)
  - Fix 3: Circle label % positions → px (sky left:120px, mountain left:130px, stream left:110px, levels top:96px); letterPos feedback left:78px→left:104px
  - Fix 4: Page 15 summary circles 230px→190px (summary_circle_container); page-break-before:always wrapper added
  - Fix 5: Blank trailing page — removed window.print() script block (DomPDF-incompatible)
  - Fix 6: ZIP download URL — replaced tenant_asset() with route('hpc.download.zip'); added downloadZip() controller method; added route in web.php
- [x] HPC fourth_pdf.blade.php — 10 issues fixed (2026-03-14):
  - Fix 1 (CRASH): </div> → </td> at line 525 in goals section — "Parent table not found" error eliminated
  - Fix 2 (STRUCTURAL): Added </div>{{-- close page-container --}} before @endforeach at line 5407 — every loop iteration's page-container div now properly closed
  - Fix 3 (STRUCTURAL): Deleted duplicate @if($part->page_no == 16) block (125 lines) — page 16 now renders once
  - Fix 4: Added width="100%" to: 2 inner checkbox tables (668,1281); future plan table (1213); rating circles table (1430); all CSS-only width tables (15 occurrences with style="width:100%;border-collapse:collapse;")
  - Fix 5: photo_box $css key overflow:hidden removed
  - Fix 6: Student photo getFirstMediaUrl() → base64 data URI with getFirstMedia()->getPath() + file_exists() guard
  - Fix 7: Replaced 4 <ol>/<ul> instances with table-based/div numbered lists — career aspirations (463), support grid (574), teacher instructions (2916), learner instructions (3000), peer instructions (~2970), pfSectionData notes (~4469)
  - Fix 8: Removed display:inline-block from all 20 <div> elements using perl regex (left <span> elements unchanged)
  - Fix 9: Removed page-break-inside:avoid from 5+ tall section-block divs (16px: 4 occurrences; 15px: triple-feedback pages)
  - Fix 10: window.print() <script> block after </html> removed
- [x] HPC third_pdf.blade.php — 13 issues fixed (2026-03-14):
  - Fix 1 (CRASH): display:inline on performance card table → removed, added width=100% and width:33% on each td
  - Fix 2 (CRASH): 3 credit tables missing HTML width attribute → added width="100%" to all <table style="{{ $css['c_table'] }}">
  - Fix 3 (CRASH): 2 inner emoji option tables CSS-only width → changed to HTML width="100%" attribute
  - Fix 4 (CRASH): 4 inner checkbox tables (lines 727,876,906,936) missing width → added width="100%" to all
  - Fix 5 (CRASH): Approach "Other" table missing width → added width="100%"
  - Fix 6: overflow:hidden removed from 6 locations (goals/competencies/approach divs, activity/assessment tds, observations div)
  - Fix 7: overflow:hidden removed from 2 emoji circle containers (self-reflection + peer feedback)
  - Fix 8: photo_box $css key overflow:hidden removed
  - Fix 9: Student photo getFirstMediaUrl() → getFirstMedia()->getPath() + base64_encode with file_exists() guard
  - Fix 10: page-break-inside:avoid removed from 3 outer domain wrappers (line 855 inline, lines 1119+1352 concatenation, line 1723 str_replace)
  - Fix 11: Assessment rubric <th> explicit widths added (40%/20%/20%/20%) in both @if and @else branches
  - Fix 12: page-break-inside:avoid wrappers added around questions table and progress grid in self-reflection AND peer feedback sections
  - Fix 13: window.print() <script> block after </html> removed
- [x] HPC second_pdf.blade.php — Round 1: 10 issues fixed (2026-03-14):
  - Fix 1 (CRASH): Undefined $emojiUrls — defined with base64 data URIs for 5 icons (family/star/balloon/rocket/books) using file_exists() guard + asset() fallback
  - Fix 2 (CRASH): display:inline-flex in curricular goals + competencies loops — replaced with display:inline-table <table> layouts (18px×18px checkbox cell + label td)
  - Fix 3: overflow:hidden on subject-page containers (pages 8,11,14,17,20,23) — removed (DomPDF ignores, breaks border-radius)
  - Fix 4: !important on self-assessment cell borders — removed; padding 20px→12px/8px; font-size 14px→13px on question td
  - Fix 5: Family photo via tenant_asset() HTTP URL — replaced with storage_path() + base64_encode + file_exists() + try/catch(Throwable) guard
  - Fix 6: Emoji 42px→32px in $emojiImgMap; dynamic option cell width via intval(100/max(1,count($displayOptions)))%; added selection border styling
  - Fix 7: Page 2 page-break splits — removed page-break-inside:avoid from outer div + 2-col table; changed 3-col cellspacing 8→6; moved avoid to each column <td>
  - Fix 8: Teacher Feedback page-break — removed outer avoid; added page-break-inside:avoid wrappers around Observational Notes @foreach and Challenges/Solutions div
  - Fix 9: min-height reduction — activity/assessment textareas 100px→60px (replace_all); rubric cells 70px→40px
  - Fix 10: Blank trailing page — removed window.print() script block
- [x] HPC second_pdf.blade.php — Round 2: 10 issues fixed (2026-03-14, v3_06 prompt):
  - Fix 7A: $css['page'] contradictory → removed page-break-inside:avoid and height:0
  - Fix 7A/7D: $css['section_container'] → removed page-break-inside:avoid; $css['display_value'/'disp_chk'/'photo_box'/'res_check'/'res_check_sel'] → removed display:inline-block, overflow:hidden, line-height from circles
  - Fix 2: $emojiUrls fallback → replaced asset() HTTP fallback with emoji/ folder base64 fallback (no HTTP URLs)
  - Fix 7B: style block .page-break → removed !important from page-break-after and page-break-inside
  - Fix 7D: Removed page-break-inside:avoid from family photo div (441), About Me+My Family wrappers (461+501), 3-column tds (527+545+563), observational notes+challenges wrappers (1720+1736)
  - Fix 5+6: Removed inline page-break-inside:avoid from outer wrappers on pages 4,5,6 (lines 684+770+867)
  - Fix 4: ALL 5 emoji circle divs (lines 648,734,820,957,1112) → replaced overflow:hidden div with border-radius:50% table (DomPDF-safe)
  - Fix 7D: Checkbox flex divs (lines 1140+1149) → replaced display:flex with table-based layout
  - Fix 8A+8B+8C+8D: Performance pages 26-28 — flex descriptor row→table, subject block+page-break-inside:avoid, flex notes→table, checkmark asset()→$checkImg base64
  - Fix 9: page-break-before:always wrapper on performance section; Fix 7C: @loop->last page break guard; Fix 10: page-break-before:always on page 30, separator between Grade4/Grade5, explicit col widths (8%/40%/28%/24%), removed !important from inline borders

## Recently Completed (2026-03-14, Parallel Periods Steps 4–9)
- [x] SmartTimetable — Parallel Periods full implementation complete
  - **Step 4 (Constraint Engine):** `ParallelPeriodConstraint.php` created; `ConstraintFactory` mapped `PARALLEL_PERIODS`; `ConstraintTypeSeeder` entry added
  - **Step 5 (Pre-Gen Validation):** `SmartTimetableController::generateWithFET()` validates anchor count, duration consistency, teacher conflicts before solving
  - **Step 6 (Post-Gen Verification):** Post-gen pass checks all parallel group members landed on same day+period; `$parallelViolations[]` built and stored in session
  - **Next Prompt 1 (Soft Constraints):** `evaluateSoftConstraints()` wired into `scoreSlotForActivity()` in `FETSolver` with 0.5× weight multiplier + verbose logging
  - **Bug Fix:** `TimetableSolution::remove()` used wrong key (`$activity->id`) — fixed to use `$activity->instance_id ?? $activity->id`, matching `place()`
  - **Step 9 (Tests):** 2 Pest 4.x unit test files, 9 tests, 23 assertions — all passing
    - `tests/Unit/SmartTimetable/TimetableSolutionIsPlacedTest.php` — 4 tests for `isPlaced()` lifecycle
    - `tests/Unit/SmartTimetable/ParallelGroupBacktrackTest.php` — 5 tests for anchor/sibling + rescue pass

## Recently Completed (2026-03-12, Phase 3 — Constraint CRUD)
- [x] SmartTimetable — Constraint Management Full CRUD (Phase 3)
  - **3A:** `constraintManagement()` — real Eloquent queries, 6 paginated vars (teacherConstraints, classConstraints, roomConstraints, dbConstraints, globalConstraints, interActivityConstraints) + activityConstraintSummary
  - **3B:** `ConstraintController::createByCategory()` + `editByCategory()` — category-specific entity loading + view resolution via `match($categoryCode)`
  - **3C:** 2 new routes before `Route::resource`: `constraint.createByCategory`, `constraint.editByCategory`
  - **3D:** All 7 list partials replaced — removed static `$sampleRows`, wired Eloquent `@forelse` loops + pagination + real route links:
    - `teacher-constraints/_list.blade.php` → `$teacherConstraints`
    - `class-constraints/_list.blade.php` → `$classConstraints`
    - `room-constraints/_list.blade.php` → `$roomConstraints`
    - `db-constraints/_list.blade.php` → `$dbConstraints` (PHP Class badge via `parameter_schema`)
    - `global-policies/_list.blade.php` → `$globalConstraints`
    - `inter-activity/_list.blade.php` → `$interActivityConstraints`
    - `activity-constraints/_list.blade.php` → `$activityConstraintSummary` (Activity records, read-only)
  - **3E+:** 12 new create/edit views under `constraint-management/`:
    - `teacher/create.blade.php` + `teacher/edit.blade.php`
    - `class/create.blade.php` + `class/edit.blade.php`
    - `room/create.blade.php` + `room/edit.blade.php`
    - `global/create.blade.php` + `global/edit.blade.php`
    - `inter-activity/create.blade.php` + `inter-activity/edit.blade.php`
    - `db/create.blade.php` + `db/edit.blade.php` (generic fallback with explicit target_type select)
  - **3F:** `ConstraintController::store()` + `update()` — full business rules (GLOBAL target_id check, hard weight check, params_json normalization, inter-activity target_activity_id merge, category anchor redirect)
  - **3G:** `StoreConstraintRequest` + `UpdateConstraintRequest` — full validation rules + JSON withValidator
  - **Model fixes:** Added `TARGET_TYPES` constant to `Constraint`; removed `'target_type' => 'integer'` cast

## Recently Completed
- [x] SmartTimetable — Constraint Management Backend Wiring (2026-03-12)
  - Route: `GET smart-timetable/constraint-management` added to `routes/tenant.php` at line 1756, named `smart-timetable-management.constraint-management`
  - `constraintManagement()` updated with real DB queries: `Constraint`, `ConstraintType`, `ConstraintCategory`, `ConstraintScope`, `TeacherUnavailable`, `RoomUnavailable`, `ConstraintTargetType`
  - Added 3 use imports to SmartTimetableController: `ConstraintCategory`, `ConstraintScope`, `ConstraintTargetType`
  - **Model fixes:**
    - `ConstraintCategory` — table fixed to `tt_constraint_category_scope`, global scope `where type=CATEGORY`, `$attributes=['type'=>'CATEGORY']`, creating hook, removed `is_system`/`ordinal` was kept (added via mig3), added SoftDeletes
    - `ConstraintScope` — table fixed to `tt_constraint_category_scope`, global scope `where type=SCOPE`, removed `target_type_required`/`target_id_required`/`is_system`, added SoftDeletes
    - `Constraint` — all Mismatch C column names fixed: `academic_term_id`→`academic_session_id`, `effective_from_date`→`effective_from`, `effective_to_date`→`effective_to`, `applicable_days_json`→`applies_to_days_json`, `target_type_id`→`target_type`; added `targetType()` BelongsTo; updated `scopeForTerm`, `scopeForTarget`, `appliesOnDate()`; added `status` to fillable
    - `ConstraintType` — no changes needed (fillable already correct for post-migration state)
  - **Migrations (additive, no drops):**
    - `2026_03_12_100001_fix_constraint_types_column_names.php` — adds `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `applicable_target_types`, `constraint_level` to `tt_constraint_types`
    - `2026_03_12_100002_fix_constraints_column_names.php` — adds alias columns `academic_term_id`, `effective_from_date`, `effective_to_date`, `applicable_days_json`, `target_type_id` to `tt_constraints`
    - `2026_03_12_100003_add_missing_columns_to_constraint_category_scope.php` — adds `ordinal`, `icon` to `tt_constraint_category_scope`
- [x] SmartTimetable — Constraint Management View (2026-03-12)
  - Route: `GET smart-timetable/constraints` → `SmartTimetableController@constraintManagement` (named `smart-timetable.constraint-management.index`) [SUPERSEDED — see above for correct route]
  - Controller method: `constraintManagement()` — passes 8 empty `collect()` vars to view [SUPERSEDED — now loads real data]
  - Index blade: `constraint-management/index.blade.php` — 8-tab nav-tab layout, `@include`s each partial
  - 8 partial `_list.blade.php` files under `constraint-management/partials/{slug}/`:
    - `engine-rules` — 5 sample rows (A1–A5), read-only (no Action col, no Add/Trash btns), info alert, filter by FETSolver/RoomAllocationPass
    - `teacher-constraints` — 5 sample rows (B1.1–B1.7), filter by scope (INDIVIDUAL/GLOBAL) + Hard/Soft
    - `class-constraints` — 5 sample rows (C1.1–C1.17), filter by scope (PER_CLASS/GLOBAL) + Hard/Soft
    - `activity-constraints` — 5 sample rows (D1–D17), read-only, filter by input_type
    - `room-constraints` — 5 sample rows (E1.1–E3.1), filter by category (ROOM_AVAILABILITY/TEACHER_ROOM/STUDENT_ROOM/SUBJECT_ROOM) + Hard/Soft
    - `db-constraints` — 5 sample rows (F1–F20), PHP Class column badge: `Registered` (blue) if wired, `Not wired` (yellow) if not; filter by category + wired status
    - `global-policies` — 5 sample rows (G1–G8), Constraint column has name + desc subtitle, filter by Hard/Soft
    - `inter-activity` — 5 sample rows (H1–H15), columns: Code | Constraint | Hard/Soft | Params, filter by Hard/Soft
- [x] StudentProfile Dusk Browser Tests — 5 test files (2026-03-12)
  - `tests/Browser/Modules/StudentProfile/Testcases/StudentCreateTest.php` — 16 tests, full 6-tab create flow
  - `tests/Browser/Modules/StudentProfile/Testcases/StudentEditTest.php` — 13 tests, edit/update coverage
  - `tests/Browser/Modules/StudentProfile/Testcases/BulkAttendanceTest.php` — 9 tests, bulk/individual attendance
  - `tests/Browser/Modules/StudentProfile/Testcases/StudentCompleteProfileTest.php` — 10 tests, `getNextIncompleteTabForCreate()` logic
  - `tests/Browser/Modules/StudentProfile/Testcases/MedicalIncidentTest.php` — 27 tests, full CRUD + toggles + soft-delete/restore/force-delete
- [x] AI Brain — Full documentation ingestion & memory rebuild (2026-03-12)
  - Read 23 docs: `Project_Documentation/` (10 files) + `Requir_Enhancements/` (13 files)
  - Created `.ai/memory/db-schema.md` — canonical v2 DDL paths, all table prefixes, CHANGELOG summary
  - Created `.ai/memory/architecture.md` — request flow, module dependency graph, service layer state, patterns
  - Created `.ai/memory/known-bugs-and-roadmap.md` — 8 bugs, 12 security issues, 13 N+1s, 4-phase roadmap
  - Created `.ai/memory/MEMORY.md` — full index of all brain files + critical bug quick-reference
  - Updated `project-context.md`, `modules-map.md`, `tenancy-map.md`, `known-issues.md`
  - Updated cross-session memory: DB schema now points to v2 files, critical bugs listed
  - DB Schema canonical files: `global_db_v2.sql`, `prime_db_v2.sql`, `tenant_db_v2.sql` in `1-master_dbs/1-DDLs/`
- [x] SmartTimetable Parallel Period Configuration — Steps 1-3 (2026-03-12)
  - Migrations: `tt_parallel_group`, `tt_parallel_group_activity`
  - Models: `ParallelGroup`, `ParallelGroupActivity`; updated `Activity` model with `parallelGroups()`, `isInParallelGroup()`
  - Controller: `ParallelGroupController` (CRUD + addActivities, removeActivity, setAnchor, autoDetect)
  - Views: index, create, edit, show (with AJAX)
  - Routes: 11 routes in `routes/web.php`
  - Solver: `FETSolver` parallel group maps, anchor/sibling placement in backtrack + greedy
  - `SmartTimetableController::generateWithFET()` loads and passes parallel groups to solver
  - Task plan: `/databases/2-Tenant_Modules/8-Smart_Timetable/Claude_Context/2026Mar11_ParallelPeriod_Tasks.md`
- [x] Testing framework setup and brain documentation (2026-03-11)
- [x] Setting model unit + DB tests — 30 tests, 44 assertions, 100% pass (2026-03-11)
- [x] DB Schema validation & enhancement (2026-03-12) — static MySQL analysis on all 3 DDL files; created global_db_v2.sql, prime_db_v2.sql, tenant_db_v2.sql, tenant_db_corrected.sql in `/databases/1-master_dbs/1-DDLs/`; created CHANGELOG.md documenting all changes
- [x] HPC third_pdf.blade.php (2026-03-12) — created `Modules/Hpc/resources/views/hpc_form/pdf/third_pdf.blade.php` merging all 46 thred_form partials; all Blade components inlined; DomPDF-compatible; covers Grades 6-8
