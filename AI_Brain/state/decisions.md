# Architectural Decisions Log

## Confirmed Decisions

### D1: Multi-Tenancy — stancl/tenancy v3.9 with Database-per-Tenant
- **Why:** Complete data isolation for each school. Regulatory compliance for Indian schools (data sovereignty). Simpler backup/restore per tenant. No risk of cross-tenant data leakage.
- **Trade-off:** Higher infrastructure cost (one DB per school), more complex migration management.
- **Alternative considered:** Shared DB with `tenant_id` column — rejected due to data isolation requirements.

### D2: Modular Architecture — nwidart/laravel-modules v12.0
- **Why:** ~40 planned modules. Each module is self-contained with its own models, controllers, routes, migrations. Enables independent development and testing. Clear separation of concerns.
- **Trade-off:** Slightly more boilerplate per module, module interdependency management needed.

### D3: 3-Layer Database Architecture
- **Why:** Separation of shared reference data (global_db), SaaS management (prime_db), and school data (tenant_db). Global masters shared without duplication. Central billing independent of tenant databases.
- **global_db:** Countries, states, boards, languages, menus, modules
- **prime_db:** Tenants, plans, billing, central users/roles
- **tenant_db:** Per-school everything (students, teachers, timetable, fees, etc.)

### D4: RBAC — Spatie Laravel Permission v6.21
- **Why:** Mature, well-documented, polymorphic role/permission assignment. Supports both central and tenant-scoped roles. Gate and middleware integration.
- **Implementation:** Roles and permissions exist in BOTH central (prime_db) and tenant (tenant_db) databases.

### D5: UUID-based Tenant Identification
- **Why:** Prevents enumeration attacks, globally unique across all environments, no conflicts during tenant migration.
- **Generator:** `Stancl\Tenancy\UUIDGenerator`

### D6: Domain-based Tenant Routing
- **Why:** Each school gets its own subdomain (e.g., `schoolname.prime-ai.com`). Clean URL structure, easy to manage with DNS.
- **Middleware:** `InitializeTenancyByDomain`

### D7: Table Prefix Convention
- **Why:** With 368+ tables in tenant_db, prefixes provide immediate module identification. `tt_` for timetable, `std_` for students, `sch_` for school setup, etc.
- **Junction tables:** Suffixed with `_jnt` for easy identification.

### D8: Soft Deletes Everywhere
- **Why:** Audit trail requirements. Schools need to recover accidentally deleted records. Regulatory compliance for attendance and exam records.
- **Implementation:** `is_active` boolean + `deleted_at` timestamp on every table.

### D9: DomPDF for PDF Generation
- **Why:** No external service dependency, works server-side, sufficient for report cards, fee receipts, and HPC documents.
- **Package:** `barryvdh/laravel-dompdf` v3.1

### D10: Razorpay for Payment Processing
- **Why:** Most popular payment gateway in India. Supports UPI, cards, net banking, wallets. Well-documented PHP SDK.
- **Package:** `razorpay/razorpay` v2.9

### D11: SmartTimetable — FET-inspired Solver
- **Why:** FET (Free Timetabling Software) algorithm is proven for school timetabling. CSP backtracking with greedy fallback, rescue pass, and forced placement. Handles complex constraints.
- **Architecture:** Activity-based scheduling with 10-stage implementation plan.

### D13: HPC PDF — Merged Single-File DomPDF Template Pattern
- **Why:** DomPDF cannot resolve Blade components (`<x-hpc-form.*>`), Bootstrap classes, flexbox/grid, or JavaScript. A single self-contained Blade file with all logic inlined is required.
- **Pattern:** One merged `*_pdf.blade.php` per HPC template form. Contains: `$css` array, helper closures (`$getStudentValue`, `$shouldCheckGrade`, `$renderItem`), full `<!DOCTYPE html>` document, `@foreach($sortedParts as $part)` main loop, per-page `@if($part->page_no == N)` blocks, page breaks via `<div style="{{ $css['page'] }}"></div>`.
- **Components location:** `resources/views/components/hpc-form/` (6 components: activity-tab, student-self-reflection, peer-feedback, tab-eight-teacher-feedback, performance-card, self-assessment)
- **Emoji:** `asset('emoji/happy.png')`, `asset('emoji/no.png')`, `asset('emoji/not_sure.png')`, `asset('emoji/sometimes.png')` — local public folder files
- **Layout rule:** Use `<table>` for all multi-column layouts (no flexbox/grid in DomPDF)
- **Files created:** first_pdf (Template 1, Grades 3-5 — DomPDF-fixed R1+R2 2026-03-14/15), second_pdf (Template 2, Grades 3-5 variant — DomPDF-fixed R1+R2 2026-03-14/15), third_pdf (Template 3, Grades 6-8, 46 pages — DomPDF-fixed 2026-03-14), fourth_pdf (Template 4, Grades 9-12, 44 pages — DomPDF-fixed 2026-03-14)
- **HPC shared tabbed index pattern:** All 15 HPC controllers render the same `hpc::hpc.index` view with different active tabs. Each controller's `index()` loads data for ALL tabs (~15 queries per request). This is an intentional design choice for the tab-based UI but causes significant performance overhead. Should be refactored to AJAX-loaded tabs.
- **HPC report save pattern:** `HpcReportService::saveReport()` uses a delete-then-reinsert strategy inside a DB transaction — it force-deletes ALL existing HpcReportItem and HpcReportTable rows for a report, then bulk-inserts fresh rows from form data (batches of 200 with per-row retry). This is intentional to avoid complex merge logic but means partial saves are all-or-nothing.

**DomPDF Hard Constraints (enforced — do NOT violate in any `*_pdf.blade.php`):**
1. **CRASH** — `display:inline` on `<table>` → *"Min/max width is undefined for table rows"*. Remove it; use parent `<td style="text-align:right">` for alignment.
2. **CRASH** — Nested `<table>` without `width="100%"` HTML attribute inside `<td>` → same crash. Every `<table>` must have `<table width="100%" ...>`.
3. **CRASH** — Wrong closing tag (`</div>` where `</td>` expected) inside `<table><tr>` → *"Parent table not found for table cell"*. Always verify table cell closing tags.
4. **STRUCTURAL** — `<div class="page-container">` opened in `@foreach` but never closed before `@endforeach` → all pages nest. Must add `</div>{{-- close page-container --}}` before `@endforeach`.
5. **STRUCTURAL** — Duplicate `@if($part->page_no == N)` blocks (orphan outside loop) → page renders twice. Search for all occurrences before writing any new page block.
6. **IMAGE** — `getFirstMediaUrl()` / `tenant_asset()` / HTTP URLs in `<img src>` → blank (DomPDF blocks remote). Must use base64 data URIs via `file_get_contents(getPath())`.
7. **LAYOUT** — `overflow:hidden` on `<div>` → silently ignored or mis-clips. Remove from all containers; use padding instead.
8. **LAYOUT** — `display:inline-block` on `<div>` → silently ignored. Use `<table>` for side-by-side layouts.
9. **LAYOUT** — `<ol>/<ul>` inside `<td>` → unreliable markers/overflow. Replace with manual `{{ $idx+1 }}. {{ $item }}` divs or inner `<table width="100%">`.
10. **LAYOUT** — `page-break-inside:avoid` on containers taller than one page → overridden by DomPDF. Only use on small atomic units; remove from full-section wrappers.
11. **JAVASCRIPT** — Any `<script>` block in the template is ignored by DomPDF. Remove `window.onload` / `window.print()` scripts.

### D15: DB Schema — v2 Enhanced DDLs as Single Source of Truth
- **Why:** Original DDLs had syntax errors, missing FKs, inconsistent naming, duplicate columns. Engineering audit identified 51+ issues in tenant_db alone. Consolidated + corrected into 3 v2 files.
- **Canonical files:** `global_db_v2.sql`, `prime_db_v2.sql`, `tenant_db_v2.sql` in `{DDL_DIR}/`
- **NEVER use:** Any other DDL file — `Old_DDLs/`, `2-Prime_Modules/`, `2-Tenant_Modules/`, `Working/`, or non-v2 root files
- **CHANGELOG:** Was in `{DDL_DIR}/CHANGELOG.md` (now archived) — documented all changes from v1 → v2

### D14: SmartTimetable Parallel Periods — Anchor-Based Solver Pattern
- **Why:** Activities across sections (Hobby, Skill, Optional) must run simultaneously. FETSolver needs to treat these as atomic units.
- **Pattern:** One activity in the group is the "anchor" (`is_anchor=1` in `tt_parallel_group_activity`). When the anchor is placed during backtracking, all non-anchor siblings are immediately placed at the same day+period. Non-anchor members encountered in the ordering are skipped until their anchor is placed (force-assigned to anchor's slot).
- **Tables:** `tt_parallel_group` (group config) + `tt_parallel_group_activity` (junction with `is_anchor` flag)
- **Solver changes:** `orderActivitiesByDifficulty()` boosts parallel members +20000 (anchors +5000 extra); `backtrack()` handles anchor→sibling atomic placement with rollback; `generateGreedySolution()` places siblings immediately after anchor.
- **Full implementation complete (2026-03-14):** Constraint Engine (ParallelPeriodConstraint, ConstraintFactory, ConstraintTypeSeeder), Pre-Gen Validation in SmartTimetableController, Post-Gen Verification + session key `generated_parallel_violations`, soft constraint wiring (see D18), bug fix in TimetableSolution::remove(), 9 unit tests passing.

### D18: SmartTimetable — Soft Constraint Wiring in FETSolver
- **Why:** `ConstraintManager::evaluateSoftConstraints()` was fully implemented but never called — soft preferences (preferred times, preferred rooms, etc.) had zero effect on slot scoring.
- **Pattern:** Called inside `scoreSlotForActivity()` after all spread/distribution logic. Returns 0–100 sum of satisfied soft constraint weights. Applied at 0.5× multiplier (`$score += (int) round($softScore * 0.5)`) so soft constraints influence but never dominate the existing [-50, +40] hard score range.
- **Safety:** Wrapped in `try/catch(\Throwable)` so any ConstraintManager exception degrades gracefully (logs warning, skips contribution). Verbose-logged when `$verboseLogging` is enabled.
- **File:** `FETSolver::scoreSlotForActivity()` (after spread_evenly block, before `return $score`).

### D12: Database Queue Driver (Current)
- **Why:** Simpler infrastructure for initial deployment. No Redis dependency needed.
- **Future:** Will migrate to Redis queue driver when scaling requires it.

### D17: SmartTimetable Constraint Model/Migration Mismatches — Audit & Fix Strategy
- **Mismatch A:** `ConstraintCategory::$table` pointed to `tt_constraint_categories` and `ConstraintScope::$table` pointed to `tt_constraint_scopes` — neither table exists. The actual migration created one shared table `tt_constraint_category_scope` with a `type` ENUM. **Fix:** Both models now point to `tt_constraint_category_scope` with `addGlobalScope` filtering by `type`. `ConstraintCategoryScope` model remains as the raw combined-table model.
- **Mismatch B:** `ConstraintType` model had `is_hard_capable`, `is_soft_capable`, `parameter_schema`, `applicable_target_types`, `constraint_level` in fillable — none existed in DB. **Fix:** Migration 1 adds these columns additively. Model unchanged (already correct for post-migration state). Old columns `is_hard_constraint` and `param_schema` kept.
- **Mismatch C:** `Constraint` model had `academic_term_id`/`effective_from_date`/`effective_to_date`/`applicable_days_json`/`target_type_id` — DB has `academic_session_id`/`effective_from`/`effective_to`/`applies_to_days_json`/`target_type`. **Fix (model-side):** Updated model fillable/casts/scopes/helpers to use actual DB column names. Migration 2 adds the original model-named alias columns for backward compat.
- **Rule:** All corrective migrations are additive only (no drops, no renames) to protect existing tenant data.

### D16: SmartTimetable Constraint Management — Full CRUD with Category-Specific Views (UPDATED)
- **Why:** Constraint management page shows live DB data per category. All configurable constraints write to one table `tt_constraints`, differentiated by `constraintType.category.code` relationship chain.
- **Index pattern:** `constraintManagement()` runs 6 paginated queries (teacher/class/room/db/global/inter-activity), each filtered by `whereHas('constraintType.category', code)`. Activity tab shows Activity records (`$activityConstraintSummary`), not Constraint records.
- **CRUD routing:** Two extra routes before `Route::resource('constraint', ...)`: `GET /constraint/category/{categoryCode}/create` → `createByCategory()`, `GET /constraint/{constraint}/category-edit` → `editByCategory()`. These must come BEFORE the resource to avoid route conflicts.
- **Category-specific views:** `createByCategory()` / `editByCategory()` resolve view via `match($categoryCode)` → `constraint-management/{slug}/create|edit.blade.php`. Each view loads category-relevant dropdowns (teachers/classes/rooms/activities). All store/update goes to same `ConstraintController::store()` / `update()` endpoint.
- **Hidden fields pattern:** All category forms pass `<input type="hidden" name="category_code" value="...">` and `<input type="hidden" name="target_type" value="...">` so the controller knows which anchor to redirect to and which target validation to apply.
- **PHP Class column (db-constraints tab):** Badge `Registered` (bg-primary) if `constraintType->parameter_schema` is non-null; `Not wired` (bg-warning) otherwise.
- **Engine rules tab:** Info alert + no Add/Trash/Action buttons — always-on hardcoded rules.
- **Activity constraints tab:** Read-only list (link to activity edit) — fields on `tt_activities`, not separate constraint records.
- **Redirect anchors:** After store/update, redirect to `constraint-management#{category}-pane` using `match($category_code)` anchor map.

### D19: SmartTimetable — Full Constraint Architecture (P09–P13, 2026-03-17)
- **Why:** Previous constraint system had only 13 PHP classes and ~30/155 rules enforced. FETSolver scored slots with only spread/distribution heuristics. No registry, no evaluator, no formal context.
- **Architecture (implemented in P01–P21):**
  - `ConstraintRegistry` — plugin system for registering constraint classes by code. Three-step resolution: Registry → CONSTRAINT_CLASS_MAP → infer → Generic fallback.
  - `ConstraintEvaluator` — parallel evaluation engine with group support (MUTEX/CONCURRENT/ORDERED). **WARNING:** Not yet wired into generation path — `FETSolver` still uses `ConstraintManager` directly.
  - `ConstraintContext` — value object for evaluation context (occupied, teacherOccupied, periods, days). **WARNING:** Only used in `FETConstraintBridge`, not in actual `ConstraintManager` calls which use raw `\stdClass`.
  - `ConstraintFactory` — creates constraint instances from DB records with JSON parameter validation.
  - `TimetableConstraint` interface — `passes(Slot, Activity, $context): bool`, `getDescription()`, `getWeight()`, `isRelevant()`.
  - 22 Hard constraint classes in `Constraints/Hard/` (teacher, class, room, activity, global, inter-activity).
  - 55+ Soft constraint classes in `Constraints/Soft/` (teacher, class, room, inter-activity preferences).
  - `SmartTimetableServiceProvider` registers all constraints via `registerConstraints()` method.
  - `ConstraintTypeSeeder` expanded to 212 entries with full parameter schemas.
- **Known issues:** FETConstraintBridge passes bare context (BUG-TT-002); gap calculations mix period_id/index (BUG-TT-003); ConstraintManager and ConstraintEvaluator duplicate logic (CODE-TT-002); legacy interfaces orphaned (CODE-TT-001).

### D20: SmartTimetable — Service Layer Decomposition (P14–P17, 2026-03-17)
- **Why:** SmartTimetableController was 3037 lines. New dedicated services and controllers extract analytics, refinement, substitution, and API concerns.
- **Pattern:** Each feature area gets its own Controller+Service pair. Controllers handle auth (Gate::authorize) and validation. Services contain business logic.
  - `AnalyticsController` + `AnalyticsService` — workload, utilization, violations, CSV exports
  - `RefinementController` + `RefinementService` — swap/move/lock cells, impact analysis, change logs
  - `SubstitutionController` + `SubstitutionService` — absence reporting, candidate scoring, auto-assignment
  - `TimetableApiController` — REST API (auth:sanctum) for external integrations
  - `GenerateTimetableJob` — async generation with status polling
  - `RoomChangeTrackingService` — room/building change violation detection
- **Known issues:** SubstitutionService crashes (BUG-TT-004/005), Job missing tenant context (BUG-TT-006), API zero auth (BUG-TT-001).

### D21: SmartTimetable — Comprehensive Reverse-Engineering Documentation (2026-03-31)
- **Why:** Module had grown to 449 files across 20 controllers, 63 models, 108 services, and 176 views with no centralized documentation. New developers and AI agents needed a complete reference to understand the module without reading source code.
- **Output:** `5-Work-In-Progress/2-In-Progress/SmartTimetable/SmartTimetable_Module_Documentation.md` — 4,621 lines, 31 sections covering: terminology (30+ terms), design intent (from 19 design docs), file inventory, routes (60+ web + 11 API), user workflow (11 phases), screen walkthroughs (15 screens), database schema (43+ tables with column details), data flows (24 operations), FET algorithm (complete pseudocode), constraint engine (24 hard + 60 soft classes), conflict detection, refinement, substitution, gap analysis.
- **Key findings:** Module at ~60% completion. 125/155 designed constraints not yet implemented. 17/20 controllers lack authorization. Phases 6-8 (Analytics/Publish/Substitution) mostly unstarted. 0 module-level tests.
- **Reference:** Generated from DDL v7.6 + 19 design documents + full code read of all 449 module files.

### D26: Employee Leave Management — Schema Design (2026-04-08)
- **File:** `1-DDL_Tenant_Modules/12-SchoolSetup/DDL/Employee_setup_ddl_v2.sql`
- **Pattern basis:** Modelled on `std_leave_*` tables (StudentProfile v1.5), extended for multi-level approval.
- **8 new tables (all `sch_*` prefix, tenant DB):**
  - `sch_leave_approval_policies` — Named policy matched by role/dept/designation/leave-type (nullable = wildcard); `priority` field breaks ties (higher = more specific wins).
  - `sch_leave_approval_policy_levels` — Ordered approval levels (L1→L2→…) with `approval_mode` (ANY_ONE | ALL) and `escalation_after_hours` per level.
  - `sch_leave_approval_level_approvers` — Authorised approvers per level via `approver_type` ENUM: USER / ROLE / DESIGNATION / DEPARTMENT_HEAD / REPORTING_TO. REPORTING_TO resolved at runtime from `sch_employees_profile.reporting_to`.
  - `sch_employee_leave_applications` — Core request; `approval_policy_id` + `current_level_number` locked at submission (policy changes mid-flight don't affect open apps).
  - `sch_employee_leave_approvals` — Per-level per-approver action trail; `escalation_deadline` indexed for scheduler queries; `action` ENUM: Pending / Approved / Rejected / Info_Requested / Doc_Requested / Escalated / Skipped.
  - `sch_employee_leave_application_docs` — Supporting documents; `is_in_response_to_request` + `request_remark_id` link uploads to specific Doc_Request remarks.
  - `sch_employee_leave_application_remarks` — Threaded communication (Approver ↔ Employee) + automatic FSM audit log (Status_Change type auto-inserted on every state transition). Threaded via `parent_remark_id`, resolved via `is_resolved`.
  - `sch_employee_leave_balance` — Live balance ledger; `available_balance` is a `GENERATED ALWAYS AS` computed column (opening + carry_forward − used). `total_pending` tracks in-flight applications. Application layer deducts on Approved, releases on Rejected/Cancelled.
- **Leave balance source:** `sch_leave_config` (existing v1 table) drives `opening_balance` on year initialization; `max_carry_forward` from `sch_leave_config` caps carry-forward at year-end.
- **Status FSM:** Draft → Submitted → Under Review → Info Requested | Doc Requested | Escalated → Approved / Rejected / Cancelled.
- **Multi-level escalation:** `sch_employee_leave_approvals.escalation_deadline` is set at routing time. A scheduler job queries `WHERE action = 'Pending' AND escalation_deadline < NOW()`, fires escalation: marks row as Escalated, routes to next level.
- **Trade-offs:** Policy snapshot at submission (not live policy) means stable audit trail. Approved_days can differ from total_days (partial approval). `sch_employee_leave_balance` has `manual_adjustment` for admin corrections without breaking the computed column.

### D27: Generic Feedback Module — Schema Design (2026-04-09)
- **Module:** `39-Feedback` (new dedicated module folder, moved out of StudentProfile on 2026-04-09)
- **Prefix:** `fbk_*` (tenant DB)
- **Files:**
  - `1-DDL_Tenant_Modules/39-Feedback/StudentFeedback_ddl_v1.sql` — Student/Parent → Teacher only (initial scope)
  - `1-DDL_Tenant_Modules/39-Feedback/StudentFeedback_ddl_v2.sql` — Generic cross-entity module (superseded by v3)
  - `{DB_REPO}/1-Module_DDLs/Feedback/StudentFeedback_ddl_v3.sql` — ENUM-free rebuild of v2 using sys_dropdown_table (current; see D29)
- **Evolution:** v1 was hardcoded to Student/Parent → Teacher (using `std_teacher_feedback_*` prefix). User asked to generalise it to support (a) any non-teaching staff (Transport, Canteen, Library, Hostel, Security, Lab, Sports, Admin) and (b) NEP 2020 mandated flows (Teacher → Student evaluation, Student → Peer Student). v2 replaces v1.
- **v2 architecture — 11 tables:**
  - **Reference masters (3):** `fbk_target_types`, `fbk_relationship_types`, `fbk_categories`
  - **Template layer (2):** `fbk_templates`, `fbk_questions`
  - **Cycle layer (3):** `fbk_cycles`, `fbk_cycle_feedback_types` (one cycle = many flows), `fbk_cycle_targets`
  - **Transactional (3):** `fbk_responses`, `fbk_answers`, `fbk_summary`
- **Polymorphic pattern:** Target identity uses 4 nullable FKs (`target_user_id`, `target_student_id`, `target_employee_id`, `target_department_id`) driven by `fbk_target_types.linked_entity_table`. Respondent identity uses 3 nullable FKs (`respondent_student_id`, `respondent_guardian_id`, `respondent_employee_id`) plus always-populated `respondent_user_id`. Preserves FK integrity vs. traditional `(type,id)` polymorphic.
- **Dedup with nullable FKs:** 7 generated `_uq` columns on `fbk_responses` (`COALESCE(col, 0)`) make the UNIQUE index work across nullable polymorphic pointers. Same pattern on `fbk_summary` (6 cols).
- **Reference-table-driven types:** `fbk_target_types` and `fbk_relationship_types` are master tables (not ENUMs) so schools can add new kinds without schema changes.
- **NEP 2020 support:**
  - `TEACHER_TO_STUDENT` relationship (teacher rates each student they teach; context via `tt_activity_id`)
  - `STUDENT_TO_PEER_STUDENT` relationship (peer feedback within same class-section) with **hardcoded anonymity** — rules R7-R8 block admins from disabling peer anonymity (child safety)
  - `nep_2020_mandated` flag on `fbk_relationship_types` for compliance reporting
- **k-Anonymity enforcement:** `min_responses_for_visibility` (default 3) on `fbk_cycle_feedback_types` — summary withheld from target if response count below threshold (prevents deanonymization of small groups).
- **Template reuse:** One "Teacher Evaluation Template" can serve `STUDENT_TO_CLASS_TEACHER`, `STUDENT_TO_SUBJECT_TEACHER`, `PARENT_TO_CLASS_TEACHER`, `PARENT_TO_SUBJECT_TEACHER` via `applicable_relationship_codes_json`.
- **Snapshot strategy:** `fbk_answers` snapshots `question_type`, `category_id`, `weight` at submission time so template edits post-submission don't corrupt analytics.
- **22 business rules documented** in file footer covering: eligibility resolution, anonymity enforcement, rating calculation (Weighted_Average/Simple_Average/Manual_Only/None), reverse scoring, cycle FSM (Draft→Active→Closed→Published→Cancelled), response FSM (Draft→Submitted→Withdrawn), template locking, incremental summary recomputation, and integrity checks.
- **12 use cases mapped** in file footer including NEP 2020 Teacher→Student, Peer feedback, Transport/Canteen/Library/Hostel staff, Admin→Teacher performance review, Teacher peer 360°, and Self-Reflection.

### D28: LMS Cloud Storage Path Configuration — Design Advisory (2026-04-09)
- **Context:** User is planning a separate cloud storage server for LMS file uploads (Quest answer images, Exam answer sheets 15-20 pages, Homework submissions). Scale estimate: ~430,000 files/year/tenant.
- **No file created** — advisory/design discussion only. Implementation to follow.
- **Recommended folder hierarchy:** `{TENANT_UUID}/{module}/{session_code}/{class_section_id}/{assessment_id}/{student_id}/{uploader}/`
  - **Session first, student later** — optimises for the dominant access pattern (teacher reviewing all submissions for one assessment in one LIST call)
  - **`student_id` (not `sas_id`)** — stable across years for student portfolio
  - **`session_code` like `2025-26`** (not integer session_id) — human-readable for storage browsing, year-end archival
  - **`{uploader}`** = `student` or `teacher` subfolder — separates original submission from checked copy
- **Config storage pattern:**
  - **`.env`:** server infrastructure (`LMS_STORAGE_DRIVER`, `LMS_STORAGE_ENDPOINT`, `LMS_STORAGE_BUCKET`, credentials)
  - **`sch_config` keys** (path templates with `{placeholders}`):
    - `lms_quest_upload_path` = `lms-quest/{session_code}/{class_section_id}/{quest_id}/{student_id}/{uploader}`
    - `lms_exam_online_upload_path` = `lms-exam-online/{session_code}/{class_section_id}/{exam_id}/{student_id}/{uploader}`
    - `lms_exam_offline_upload_path` = `lms-exam-offline/{session_code}/{class_section_id}/{exam_id}/{student_id}/{uploader}`
    - `lms_homework_upload_path` = `lms-homework/{session_code}/{class_section_id}/{homework_id}/{student_id}/{uploader}`
  - **Tenant UUID is prepended by app code** from `tenant()->id`, not stored in the template

### D29: Avoid MySQL ENUM — Use sys_dropdown_table for Semi-Open Value Sets (2026-04-09)
- **Rule:** MySQL `ENUM(...)` is allowed ONLY when the option set is genuinely fixed by code and can never be extended without an application release. Every other "pick-from-a-list" column must FK to `sys_dropdown_table` via an `_id` column.
- **Why:** ENUM locks option sets at the DDL level. Any addition/rename requires a schema migration against every tenant DB, code changes to validate the new value, and cannot be done by PG-Admin or school admins at runtime. The generic dropdown system (`sys_dropdown_needs` + `sys_dropdown_table` + `sys_dropdown_need_table_jnt`, already in `tenant_db_v2.sql`) was built exactly for this — it gives each (table, column) pair a registered "need" and a value set that is extensible without touching DDL.
- **Decision criteria:**
  - ✅ **Use ENUM:** Binary flags that are code-gated (even then, `TINYINT(1)` boolean is preferred). E.g. truly inviolable sentinels.
  - ✅ **Use TINYINT(1) boolean:** Any Auto/Manual, On/Off, Yes/No pair. Don't make a 2-row dropdown.
  - ✅ **Use sys_dropdown_table FK:** Status FSMs, actor kinds, question types, scope/context resolvers, rating methods, category-like lookups — anything that a PM, PG-Admin, or future release might want to extend without a schema migration. Even status FSMs qualify: the DB shouldn't constrain what the app's state machine chooses to support.
- **Naming convention:**
  - Column: `{logical_name}_id` (e.g. `respondent_kind_id`, not `respondent_kind`)
  - Dropdown `key`: `{table_name}.{column_name}` using the *logical* column name without the `_id` suffix (e.g. key `fbk_responses.respondent_kind` for column `fbk_responses.respondent_kind_id`). Matches existing tenant_db_v2 examples (`tpt_vehicle.vehicle_type`, `cmp_complaint_actions.action_type`, etc.).
  - Add one `sys_dropdown_needs` row per (db_type, table, column).
  - FK constraint: `REFERENCES sys_dropdown_table (id) ON DELETE RESTRICT`
  - Index the `_id` column if it appears in WHERE/JOIN paths.
- **Snapshot columns:** Tables that snapshot a typed value at submission time (e.g. `fbk_answers.question_type_id_snapshot`) also FK to `sys_dropdown_table`. Dropdown rows referenced by snapshots must NEVER be hard-deleted — soft-deactivate with `is_active = 0` only, so historical rows remain resolvable.
- **Form Request validation rule (app-level):** For any `*_id` column that points to `sys_dropdown_table`, validate that the selected row has the expected `key`. Otherwise two columns with different semantic meanings could accept each other's values.
- **Reference implementation:** `StudentFeedback_ddl_v3.sql` — rebuilds v2's Feedback module with all 13 ENUMs converted. Only 1 of the 13 became a TINYINT boolean (`target_population_mode` → `is_auto_populated_targets`); the other 12 became FK to sys_dropdown_table. See SECTION 0 of that file for a complete seed manifest.
- **Supersedes:** Prior convention in `AI_Brain/memory/db-schema.md` line 268 (`Enums: ENUM() for fixed sets`) — that line has been updated to reflect D29.

---

## Future Decisions (Pending)

### Pending: Event Engine Architecture
- Need to decide: Event-driven vs scheduled polling for cross-module communication
- Status: Module at 20% completion

### Pending: Analytics Pipeline
- Need to decide: Real-time vs batch processing for student analytics
- Options: Laravel Jobs + Cache vs dedicated analytics service

### Pending: Student/Parent Portal
- Need to decide: Same Laravel app with role-based views vs separate SPA
- Options: Blade views vs Vue.js/React SPA

### Pending: Accounting Module
- Need to decide: Build custom vs integrate with existing accounting software
- Double-entry bookkeeping requirements

### Pending: Redis Migration
- When to move queue, cache, and session drivers from database to Redis
- Dependent on production traffic patterns

---

## Architectural Issues Discovered — Deep Audit 2026-04-02

### D22: Route Registration Architecture — Module-Owned Routes (RESOLVED 2026-04-02)
- **Discovery (2026-04-02):** 3 routing layers overlapped: `routes/tenant.php` (tenancy middleware), module `routes/web.php` (loaded by module RSP, often without tenancy middleware), central `routes/web.php`.
- **Resolution:** Migration prompt `databases/5-Work-In-Progress/1-Completed/Update_Route_Permission_AllModules/migrate-module-routes-policies_v2.md` executed on `prime_ai_shailesh` 2026-04-02.
- **New canonical architecture:**
  - **Tenant module routes:** `Modules/{ModuleName}/routes/web.php` — each module owns its routes entirely
  - **Gate policies:** `Modules/{ModuleName}/app/Providers/{ModuleName}ServiceProvider.php` → `registerPolicies()` method
  - **`routes/tenant.php`** (224 lines): auth routes only + 1 cross-module route + seeder routes (still P0 SEC-RTG-001) + tenancy middleware wrapper
  - **`AppServiceProvider.php`** (127 lines): module policy blocks removed; cross-module-only policies remain
- **Status:** ✅ RESOLVED in `prime_ai_shailesh`. Remaining risk: module RSP tenancy middleware (D23 still open).

### D23: RSP Tenancy Middleware — 2 Modules Missing Entirely
- **Discovery:** Scheduler and EventEngine RSPs apply only `Route::middleware('web')` — no `InitializeTenancyByDomain`, no `PreventAccessFromCentralDomains`. SmartTimetable RSP missing tenancy on ParallelGroupController.
- **Impact:** All routes served by these RSPs operate without tenant DB context — queries hit central database or fail.
- **Decision needed:** Add full tenancy middleware stack (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`) to all tenant module RSPs.
- **Status:** Identified, not yet fixed.

### D24: Permission Naming Taxonomy — 5 Conflicting Prefixes
- **Discovery:** Five different Gate permission prefixes coexist: `tenant.*` (standard), `prime.*` (Notification module — wrong context), `global-master.*` (GlobalMaster Language), `vendor.*` (VndUsageLog/VendorPayment), `transport.*` (TripController). Additionally, `tested.*` in Transport AttendanceDevice is a typo.
- **Impact:** Policies defined under one prefix are invisible to Gates checking another. Auth silently fails (403) or silently passes depending on how `Gate::authorize()` handles missing policies.
- **Decision needed:** Standardize to `tenant.*` for all tenant-scoped modules and `prime.*` for all central modules. No exceptions.
- **Status:** Identified, not yet fixed.

### D25: $request->all() vs $request->validated() — Systemic Pattern
- **Discovery:** 30+ controllers across 12+ modules inject FormRequest classes but call `$request->all()` instead of `$request->validated()`, bypassing the validation result entirely. This is the single most widespread vulnerability pattern.
- **Impact:** Extra fields submitted in the request body bypass validation rules and flow directly into `Model::create()` / `->update()`, enabling mass-assignment attacks even with FormRequests in place.
- **Decision needed:** Project-wide find-and-replace of `$request->all()` with `$request->validated()` in all controllers that inject FormRequest types. Add a custom PHPStan/Larastan rule to flag this pattern.
- **Status:** Identified, not yet fixed.

### D30: FormRequest authorize() returning hardcoded `true` — Second Systemic Pattern (2026-04-09)
- **Discovery (Phase 2, 2026-04-09):** FormRequest `authorize()` methods returning hardcoded `return true` (or bare `auth()->check()` with no resource ownership check) is the second platform-wide vulnerability pattern, parallel to D25. Confirmed across:
  - **Inventory:** ALL 18 FormRequests (SEC-INV-001) — financial requests (StorePurchaseOrderRequest, StoreGrnRequest, StoreStockIssueRequest, StoreStockAdjustmentRequest, StoreQuotationRequest, etc.) all relay on controller Gate checks only.
  - **LmsExam:** PaperSetQuestionRequest (SEC-EXM-006).
  - **StudentPortal:** StartAttemptRequest returns bare `auth()->check()` without validating student owns the assessment_id (SEC-STP-010).
  - **Hpc (FIXED earlier):** Previously had 7 FormRequests returning true — sprint fixed 2026-03-17.
  - **Complaint, Notification, Syllabus** — prior audits identified similar patterns (still open).
- **Impact:** Defense-in-depth collapses to a single layer. If controller-side `Gate::authorize()` is ever commented out, skipped, or bypassed (e.g. via a new controller method that forgets to re-add it), the FormRequest provides zero safety net. Several modules already have commented Gates (Vendor SEC-VND-005, LmsQuests SEC-QZT-002, HPC BUG-HPC-016) — the FormRequest fallback has silently been the only protection layer, and in these cases there is no protection at all.
- **Rule:** Every FormRequest `authorize()` method MUST return a `Gate::allows()` / `Gate::check()` call that matches the route's permission string. Controllers must still keep their `Gate::authorize()` calls — this is defense-in-depth, not either/or.
- **Decision:** Project-wide sweep required. Add a custom Larastan rule to flag any FormRequest where `authorize()` returns a boolean literal. **Status:** Identified platform-wide, not yet fixed.

### D32: MarksheetGeneration Module — Architecture & Schema Design (2026-04-13)
- **Context:** Prime-AI has 5 independent scoring modules (LmsExam, LmsHomework, LmsQuiz, LmsQuest, BehaviouralAssessment) but no consolidated marksheet engine. Indian K-12 schools require CBSE/ICSE/State Board-compliant report cards with subject-wise, exam-wise mark matrices, theory-practical splits, Internal Assessment, Co-Scholastic grades, attendance, rank, division, and promotion status.
- **Decision:** New tenant module `Modules\MarksheetGeneration` with prefix `msh_*` (23 tables). Read-only integration with all 5 source modules — MSG never writes to `lms_*`, `ba_*`, `sch_*`, or `std_*` tables.
- **Key design choices:**
  - D-MSG-001: No `tenant_id` column (database-per-tenant, standard)
  - D-MSG-002: No ENUMs anywhere — all status/type fields use `sys_dropdown_table` (per D29)
  - D-MSG-003: `msh_class_groups` is a NEW table separate from `sch_class_groups_jnt` (which is timetable-specific, not simple class grouping)
  - D-MSG-004: Online/Offline exam distinction transparent at marksheet level — both paper modes produce `lms_exam_results`, paper mode (`lms_exam_papers.mode`) is irrelevant for marks aggregation
  - D-MSG-005: Absent flag read from `lms_exam_results.result_status = 'ABSENT'` (NOT from `lms_exam_marks_entry` which has no such flag)
  - D-MSG-006: IA marks (Notebook, Subject Enrichment) owned by MSG module (teacher entry via UI), not sourced from other modules
  - D-MSG-007: Co-Scholastic grades (Work Ed, Art, Health & PE) owned by MSG module; Discipline grade auto-populated from BA module if configured
  - D-MSG-008: Theory vs Practical paper identification — no `is_practical` flag on `lms_exam_papers`. Resolution: match by `total_marks` against `msh_subject_practical_configs.theory_max_marks` / `practical_max_marks` (Open Question Q-13)
- **Schema:** 3 masters + 10 config + 2 schedule + 6 result + 1 audit = 23 tables. Core table: `msh_student_subject_exam_marks` (highest volume: ~60K-400K rows/school/year)
- **Output files:** `{OLD_REPO}/1-DDL_Tenant_Modules/55h-MarksheetGeneration/` → `MSG_RequirementSpec.md`, `MSG_DDL_v1.sql`, `MSG_DataDictionary.md`, `MSG_Dev_Plan.md`
- **Sprint plan:** 5 sprints / ~9.5 weeks. Sprint 3 (Computation Engine) is critical path.
- **Open Questions (13):** Listed in MSG_RequirementSpec.md Section 11. Q-13 (theory/practical paper identification) is the highest-risk item.

### D31: QuestionBank `qns_question_statistics` — Formal Calculation Specification (2026-04-10)
- **Context:** The `qns_question_statistics` table (`1-DDL_Tenant_Modules/51-QuestionBank/DDL/Question_Bank_ddl_v1.2.sql:209`) holds 6 computed metrics (`difficulty_index`, `discrimination_index`, `guessing_factor`, `min/max/avg_time_taken_seconds`, `total_attempts`) with only one-line inline comments and a header note *"Required a backend Service to calculate the statistics"*. No psychometric formula was specified. This left the backend service owner with no contract.
- **Decision:** Formal calculation spec written to **`1-DDL_Tenant_Modules/51-QuestionBank/DDL/statistics_help.md`** as the authoritative backend-service contract. Any change to the DDL or to the spec must move in lockstep.
- **Formulas chosen (CTT / IRT conventions):**
  - `difficulty_index` = `100 × Σ(correct) / n` (p-value, stored as 0–100 percent)
  - `discrimination_index` = `100 × (p_upper27 − p_lower27)` (Kelley D-index; negative value = mis-keyed question → auto-flag for review)
  - `guessing_factor` (**MCQ only**) = empirical `100 × p_lower27` when `total_attempts ≥ 30`, else baseline `100 / k` where `k = active option count`. IRT 3PL c-parameter analogue.
  - `min_time_taken_seconds` = `MIN(time_spent) WHERE is_correct=1 AND t>0` — topper's time, anti-cheat floor
  - `max_time_taken_seconds` = `MAX(time_spent) WHERE t>0 AND t < 3×expected_time` — outlier-guarded
  - `avg_time_taken_seconds` = `ROUND(AVG(time_spent))` — same outlier guard
  - `total_attempts` = `COUNT(evaluated, non-null is_correct)`
  - `last_computed_at` = `NOW()` (unconditional on every upsert, even no-op ones)
- **Source tables (unified via view `v_qns_answer_feed`):** `lms_quiz_quest_attempt_answers` + `lms_quiz_quest_results` UNION `lms_exam_attempt_answers` + `lms_exam_results`, filtered by `is_evaluated=1 AND is_correct IS NOT NULL AND is_active=1`. `lms_exam_marks_entry` (BULK_TOTAL offline mode) is **excluded** — no per-question data exists.
- **27% Kelley cut-point** used for both `discrimination_index` and `guessing_factor` so one ranked pass serves both metrics.
- **MCQ gate for guessing_factor:** only compute when `qns_questions_bank.question_type_id` resolves to `SINGLE_MCQ` or `MULTI_MCQ` in `slb_question_types`. For all other question types, leave `guessing_factor = NULL`.
- **Upsert semantics:** table has `UNIQUE KEY uq_qstats_q (question_bank_id)` — service MUST `INSERT ... ON DUPLICATE KEY UPDATE` (or Eloquent `updateOrCreate`), never blind INSERT.
- **DDL inconsistency flagged:** `max_time_taken_seconds` column name says "maximum" but inline comment says "average time" — the column name is authoritative; the comment should be corrected in the next DDL revision (v1.3).
- **Feed-forward hook:** after computation, the service writes `qns_question_performance_category_jnt` rows (`recommendation_type = REVISION | PRACTICE | CHALLENGE`) based on the interpretation bands — closes the loop into the Recommendation module per `Question_Bank_ddl_v1.2.sql:243–245`.
- **Owner:** `Modules\QuestionBank\Services\QuestionStatisticsService` (not yet implemented — module currently at ~75% per known-issues.md, with AI controller auth issues still open).
- **Scheduling:** nightly job via `Modules\Scheduler`; delta-check `last_computed_at` against `MAX(evaluated_at)` from both answer tables to avoid recomputing untouched questions.
- **Transactionality:** wrap each question's 6-metric computation in a single `START TRANSACTION WITH CONSISTENT SNAPSHOT` read so all metrics reflect the same row set — prevents drift when students submit mid-computation.
