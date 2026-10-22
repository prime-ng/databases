# Module Knowledge: Dashboard (DSH)
# Last Updated: 2026-06-29 (SEEDED from scratch — verified against live tree at /Users/bkwork/Herd/prime_ai/Modules/Dashboard)
# Completion Status: ~55–60% (full controller/view scaffold + 17 live-wired aggregation endpoints; 8 role/area dashboards still render hardcoded dummy data; 0 own tables; 0 tests; permission not seeded)

---

## Module Identity

| Item | Value |
|------|-------|
| Module Name | Dashboard |
| Module Code | DSH |
| Table prefix | `dsh_` — **NONE EXIST** (module owns zero tables; pure read/aggregation layer) |
| Layer | TENANT (tenant routes) + reads PRIME (`prm_*`, `bil_*`) and GLOBAL (`glb_*`) cross-DB |
| Module type | **Aggregation / read-only presentation module** — no DDL, no migrations, no models, no writes |

> **Architectural note:** Dashboard is unlike every other module in the platform. It defines **no schema** and persists **no data**. It is a read-only "window" that aggregates counts, sums, and recent-record lists from ~28 other modules' tables (across all three database layers) and renders them as KPI tiles, charts, and tables. Every claim about "its data" is really a claim about a *source* module's table.

---

## Module Facts (verified against filesystem 2026-06-29)

| Item | Value |
|------|-------|
| Migrations | **0** — only `.gitkeep` in `database/migrations/` |
| Models | **0** — no `app/Models/` directory exists |
| Own DDL | **0** — no `dsh_*` tables anywhere in `0-DDL_Masters/` (confirmed via grep on `tenant_db_v4.sql`) |
| Controllers | **26 PHP files** = 1 abstract base (`BaseDashboardController`) + 1 main (`DashboardController`) + 24 area/role sub-controllers |
| Blade Views | **85** (`.blade.php`): 25 top-level `dashboard.blade.php`/sub-pages + ~56 `partials/_*.blade.php` + 4 shared `components/` (stat-card variants, master layout) + `index.blade.php` |
| Routes (web) | 1 root `/dashboard` + 24 named routes under `dashboard.` prefix (15 area hubs + 4 foundational sub-pages + 8 role dashboards + 1 all-notifications) |
| Routes (api) | 1 `apiResource('dashboards', DashboardController::class)` under `/v1` (auth:sanctum) — **scaffold only; DashboardController has no resource CRUD methods, only `index()`** |
| Services | **0** — no `Services/` directory; aggregation logic lives inline in controllers |
| FormRequests | **0** (read-only module — no input forms) |
| Policies | **0** — no Dashboard policy; access controlled via `Gate::authorize('tenant.dashboard.viewAny')` and `hasRole()` checks |
| Events / Listeners / Jobs / Commands | **0** of each |
| Seeders | 1 (`DashboardDatabaseSeeder` — empty default stub) |
| Tests | **0** — `tests/Feature` and `tests/Unit` contain only `.gitkeep` |
| Providers | 3 (`DashboardServiceProvider`, `EventServiceProvider`, `RouteServiceProvider`) |
| FRD | **Generated 2026-06-29** → `4-Requirement_Module_wise/0-FRD_Documents/DSH_FRD_Complete_2026-06-29.md` |

---

## Endpoint Inventory (25 dashboards)

### Group A — Live-wired (query real DB via `safeCount`/`safeSum`/`DB::table`) — 17 endpoints
| Endpoint | Controller | Render source |
|----------|-----------|---------------|
| `/dashboard` (main School Admin) | `DashboardController@index` | **live** — 21 KPI counts + students-per-class chart + staff/infra breakdown + timetable pipeline % |
| `dashboard.core-configuration` | `CoreConfiguration...` | live |
| `dashboard.foundational-setup` | `FoundationalSetup@index` | live (sessions/terms/users) |
| `dashboard.foundational-setup.school-profile` | `FoundationalSetup@schoolProfile` | live — cross-DB (`sch_organizations`, `glb_cities`, `prm_tenant`, `prm_plans`) |
| `dashboard.foundational-setup.session-board` | `FoundationalSetup@sessionBoard` | live — cross-DB (`glb_academic_sessions`, `glb_boards`, `sch_*_jnt`) |
| `dashboard.foundational-setup.billing` | `FoundationalSetup@billing` | live — cross-DB (`prm_tenant`, `prm_plans`, `bil_tenant_invoices`, `prm_billing_cycles`, `prm_tenant_plan_billing_schedules`) |
| `dashboard.admission-student-management` | `AdmissionStudentManagement...` | live |
| `dashboard.school-setup` | `SchoolSetup...` | live |
| `dashboard.operation-management` | `OperationManagement...` | live |
| `dashboard.support-management` | `SupportManagement...` | live |
| `dashboard.communication-management` | `CommunicationManagement...` | live |
| `dashboard.staff-management` | `StaffManagement...` | live |
| `dashboard.finance` | `Finance...` | live |
| `dashboard.lms` | `Lms...` | live |
| `dashboard.academic-management` | `AcademicManagement...` | live |
| `dashboard.exam-assessment` | `ExamAssessment...` | live |
| `dashboard.timetable-management` | `TimetableManagement...` | live |
| `dashboard.front-desk` | `FrontDesk...` | live |
| `dashboard.portal` | `Portal...` | live |

### Group B — Dummy/hardcoded data (NOT DB-wired; "DB wiring is a separate phase") — 8 endpoints
| Endpoint | Controller | Role gate |
|----------|-----------|-----------|
| `dashboard.principal.index` | `Principal...` | `hasRole('Principal')` |
| `dashboard.teacher.index` | `Teacher...` | `hasRole('Teacher')` |
| `dashboard.accounts.index` | `Accounts...` | `hasRole('Accounts')` |
| `dashboard.inventory.index` | `Inventory...` | (Gate-level) |
| `dashboard.transport.index` | `Transport...` | `hasRole('Transport')` |
| `dashboard.library.index` | `Library...` | `hasRole('Librarian')` |
| `dashboard.management.index` | `Management...` | `hasRole('Management')` |
| `dashboard.superadmin.index` | `SuperAdmin...` | `hasRole('SuperAdmin')` — central/platform health, all dummy |

### Group C — Hybrid / cross-module
| Endpoint | Notes |
|----------|-------|
| `dashboard.general.index` | `GeneralDashboardController` — real user name/role from `Auth`, but aggregate counts hardcoded |
| `dashboard.all-notifications` | delegates to `Modules\GlobalMaster\...\NotificationController@allNotifications` (cross-module reuse) |

---

## Access-Control Pattern

- **15 area-hub endpoints** authorize with `Gate::authorize('tenant.dashboard.viewAny')`.
- **7 role dashboards** use `abort_unless(auth()->user()?->hasRole('<Role>'), 403)` — roles enforced: `Principal`, `Teacher`, `Accounts`, `Transport`, `Librarian`, `SuperAdmin`, `Management`.
- Main `/dashboard` redirects `Student`/`Parent` roles to `student-portal.dashboard` (target route confirmed to exist: `Modules/StudentPortal/routes/web.php`).
- Tenancy middleware (`InitializeTenancyByDomain`, `PreventAccessFromCentralDomains`, `EnsureTenantIsActive`) applied at `RouteServiceProvider`; all routes `auth` + `verified`.

---

## Data Dependencies (the defining characteristic of this module)

Dashboard reads from **~80 tables across ~28 modules and all 3 DB layers**. No writes anywhere.

| Source module | Tables read (sample) |
|---------------|----------------------|
| SchoolSetup (`sch_`) | sch_students(via std), sch_teachers, sch_employees, sch_classes, sch_class_section_jnt, sch_subjects, sch_subject_groups, sch_rooms, sch_room_types, sch_buildings, sch_departments, sch_designations, sch_academic_term, sch_org_academic_sessions_jnt, sch_organizations, sch_board_organization_jnt |
| StudentProfile (`std_`) | std_students |
| SmartTimetable (`tt_`) | tt_activities, tt_timetables, tt_class_requirement_groups, tt_requirement_consolidations, tt_teacher_availabilities, tt_slot_requirements, tt_period_sets, tt_generation_runs, tt_teacher_workloads, tt_timetable_cells |
| Admission (`adm_`) | adm_applications, adm_cycles, adm_enquiries |
| Complaint (`cmp_`) | cmp_complaints |
| Notification (`ntf_`) | ntf_notifications |
| Hpc (`hpc_`) | hpc_reports |
| LMS (`lms_`) | lms_exams, lms_quizzes, lms_quests, lms_homeworks, lms_exam_attempts, lms_exam_grievances |
| Accounting (`acc_`) | acc_financial_years, acc_ledgers, acc_vouchers |
| StudentFee (`fin_`) | fin_fee_invoices, fin_fee_receipts, fin_fee_structure_masters, fin_fee_concession_types |
| Certificate (`crt_`) | crt_issued_certificates, crt_requests, crt_templates |
| Behaviour (`beh_`) | beh_assessments |
| Library/Books (`bok_`) | bok_books |
| Cafeteria (`caf_`) | caf_orders, caf_meal_cards, caf_menu_items |
| Feedback (`fbk_`) | fbk_cycles, fbk_responses, fbk_templates |
| FrontOffice (`fof_`) | fof_visitors, fof_enquiries, fof_call_logs, fof_lost_found_items, fof_postal_registers |
| HrStaff (`hrs_`) | hrs_leave_applications, hrs_leave_types |
| Inventory (`inv_`) | inv_purchase_orders, inv_stock_items |
| Marksheet (`msg_`) | msg_marksheet_schedules |
| Payroll (`pay_`) | pay_salary_structures |
| PTM (`ptm_`) | ptm_events, ptm_assignments, ptm_slots, ptm_slot_bookings, ptm_blockouts, ptm_batches_template, ptm_event_class_section_jnt |
| QuestionBank (`qns_`) | qns_questions |
| Recommendation (`rec_`) | rec_recommendations |
| Syllabus (`slb_`) | slb_syllabuses |
| Transport (`tpt_`) | tpt_routes, tpt_vehicles |
| Vendor (`vnd_`) | vnd_vendors |
| System (`sys_`) | sys_users, sys_activity_logs, sys_dropdowns, sys_settings + `roles`, `permissions` (Spatie) |
| Global layer (`glb_`, conn `global_master_mysql`) | glb_cities, glb_academic_sessions, glb_boards |
| Prime layer (`prm_`/`bil_`, conn `mysql`) | prm_tenant, prm_plans, prm_tenant_plan_jnt, prm_billing_cycles, prm_tenant_plan_billing_schedules, bil_tenant_invoices |

**Resilience pattern:** `BaseDashboardController::safeCount()` / `safeSum()` wrap every query in try/catch, return `0` on failure, and auto-exclude soft-deleted rows (`whereNull('deleted_at')` when the column exists via `Schema::getColumnListing`). This means a missing/renamed source table degrades a tile to `0` rather than throwing — good for resilience, but **silently hides data-source breakage** (no logging on catch).

---

## Known Gaps & Open Issues

### P0
- **None blocking** (read-only module; no data-integrity risk).

### P1 — CONFIRMED by Technical Auditor (Mode X, 2026-06-29)
- **BUG-DSH-007 — Role-name drift (NEW, confirmed):** 4 of 7 role dashboards gate on Spatie roles that NO seeder creates → permanent 403 for everyone (incl. the real platform operator). `AccountsDashboardController:16` checks `hasRole('Accounts')` but seeded role is `Accountant`; `SuperAdminDashboardController:16` checks `'SuperAdmin'` but seeded role is `'Super Admin'` (space); `Transport`/`Management` roles are not seeded at all. Canonical roles: `database/seeders/TenantRolePermissionSeeder.php:20-74`. The AppServiceProvider Gate::before super-admin bypass does NOT help (abort_unless is a direct role check). Fix: align strings / seed roles.
- **SEC-DSH-008 — Foundational-Setup detail pages UNGATED (NEW, confirmed):** `schoolProfile()`/`sessionBoard()`/`billing()` (`FoundationalSetupDashboardController.php:56,109,164`) carry NO `Gate::authorize` (only `index():18` does). Any authenticated+verified tenant user can read plan/trial/invoices/next-bill (Confidential). Fix: add the gate to all 3 sub-pages.
- **SEC-DSH-009 — `tenant.dashboard.viewAny` permission is NOT seeded anywhere** (grep across `database/`, `app/`, all `Modules/*/database/seeders/` = 0). Spatie `register_permission_check_method=true` (config/permission.php:104); super-admin `Gate::before` (AppServiceProvider:65-73) bypasses only super admins → all 15 area-hub dashboards 403/500 for normal staff. **Seed it + grant to staff roles.**
- **8 of 25 dashboards render hardcoded dummy data** (Principal, Teacher, Accounts, Inventory, Transport, Library, Management, SuperAdmin). Controllers themselves carry inline `// dummy data — DB wiring is a separate phase` notes. These are presentation-complete but data-incomplete.
- **No academic-year/session scoping** in the live aggregations — counts are tenant-wide, not session-filtered. For a K-12 platform where almost all data is session-scoped, dashboards likely over-count across historical sessions. Confirm intended behaviour.

### P2
- **Silent failure** — `safeCount`/`safeSum` catch blocks swallow exceptions with no logging; a renamed source table shows `0` indefinitely with no alert.
- **API resource is a stub** — `apiResource('dashboards', ...)` is declared but `DashboardController` implements only `index()` (Blade), not the 7 REST methods; calling `store/show/update/destroy` would 500/404.
- **0 tests** — no coverage that role gates, redirects, or aggregation tiles behave.
- **Main view lives outside the module** — `DashboardController@index` renders `backend.v1.dashboard.index` (app-level `resources/views/backend/v1/dashboard/index.blade.php`), while all sub-dashboards render `dashboard::*` (module views). Inconsistent view ownership.

---

## Design Decisions Observed

| # | Decision | Evidence |
|---|----------|----------|
| DSH-D1 | Dashboard owns no schema; it is a pure read-aggregation layer over other modules. | 0 migrations / 0 models / 0 `dsh_` tables |
| DSH-D2 | Resilient aggregation: every cross-module read is try/catch-guarded and soft-delete aware, returning 0 on failure. | `BaseDashboardController` |
| DSH-D3 | Two access models coexist: permission-gated area hubs (`tenant.dashboard.viewAny`) vs role-gated role dashboards (`hasRole`). | controllers |
| DSH-D4 | Role dashboards (Principal/Teacher/etc.) shipped UI-first with dummy data, DB wiring deferred to a later phase. | inline code comments |
| DSH-D5 | Cross-DB reads are explicit per connection: `global_master_mysql` for `glb_*`, `mysql` for `prm_*`/`bil_*`, default (tenant) for everything else. | `FoundationalSetupDashboardController` |

---

## Cross-Module Dependencies

- **Inbound (Dashboard reads from):** ~28 modules — see Data Dependencies table. Dashboard is a pure consumer.
- **Outbound (Dashboard feeds):** none — it produces no events, writes no tables, exposes no services consumed by others.
- **Direct reuse:** `dashboard.all-notifications` delegates to `Modules\GlobalMaster\...\NotificationController@allNotifications`.
- **Redirect dependency:** main dashboard redirects Student/Parent → `student-portal.dashboard` (StudentPortal module).

---

## Lessons Learned

- [2026-06-29 | business-analyst] Dashboard is the platform's only schema-less module — treat every "field" as a borrowed read from a source module; the real risk surface is *coupling to ~80 tables across 3 DB layers*, not its own data.
- [2026-06-29 | business-analyst] The seeded "completion" of an aggregation module is misleading: scaffold + views are ~100% present, but 1/3 of dashboards (8/25) are dummy-data shells. Always classify endpoints live-vs-dummy by grepping for `safeCount|safeSum|DB::table` vs `dummy`.
- [2026-06-29 | business-analyst] `tenant.dashboard.viewAny` is referenced by 15 controllers but seeded by none — a permission that no seeder creates is a silent 403 trap; flag any `Gate::authorize` string that has no matching seeder entry.
- [2026-06-29 | Technical Auditor] **Role-name-vs-gate drift is a distinct, high-value defect class:** `hasRole('Accounts')`/`'SuperAdmin'`/`'Transport'`/`'Management'` reference roles the seeder never creates (canonical are `Accountant`, `Super Admin`, etc.) → the dashboards 403 permanently and silently. Always cross-check every `hasRole('X')`/`abort_unless` string against `TenantRolePermissionSeeder` role names; `abort_unless(hasRole())` is NOT covered by the Gate::before super-admin bypass.
- [2026-06-29 | Technical Auditor] **Per-method authz, not per-controller:** counting "1 gate per controller" hid that `FoundationalSetupDashboardController` has 4 routed actions but only `index()` is gated — the 3 confidential billing sub-pages are open. Audit authorization per ROUTED METHOD, not per file.
- [2026-06-29 | Technical Auditor] Reading-discipline win: Dashboard's `prm_tenant_plan_billing_schedules` (plural) matches the LIVE migration/model; the DDL master `prime_db_v4.sql` is stale (singular `...schedule`). Live schema wins — would have been a false-positive "missing table" finding.

---

## FRD Summary

| Item | Value |
|------|-------|
| FRD File | `4-Requirement_Module_wise/0-FRD_Documents/DSH_FRD_Complete_2026-06-29.md` (Complete Analysis Pack — single consolidated file) |
| Date | 2026-06-29 |
| Functional Requirements (REQ-DSH) | **12** |
| Business Rules (BR-DSH) | **24** |
| Workflows | **3** (Render-aggregate, Role routing & redirect, Resilient degradation) |
| Reports / Analytics views (RPT-DSH) | **11** |
| Enhancements (ENH-DSH) | **8** |
| Priority split | P0 = 5 · P1 = 5 · P2 = 2 |
| Status | Draft (first FRD for this module; no prior FRD superseded) |

---

## Pending Next Steps

1. DDL Schema Gap Analysis — N/A (module owns no schema); instead validate that all ~80 source tables it reads exist in current DDL.
2. Application Code Gap (Technical Auditor, Mode B) — verify `tenant.dashboard.viewAny` seeding, wire the 8 dummy dashboards, decide API-resource fate.
3. Business-Rule Enforcement (Mode C) — confirm role gates + Student/Parent redirect + soft-delete exclusion.
4. Test Coverage Gap (Testing Architect) — 0 tests today; add role-gate + redirect + tile-aggregation tests.

---

## Version History

| Date | Agent | Change |
|------|-------|--------|
| 2026-06-29 | business-analyst | SEEDED from scratch against live tree; produced Complete FRD; recorded live-vs-dummy endpoint split, ~80-table dependency map, and permission-seeding anomaly. |
| 2026-06-29 | Technical Auditor | Mode X Complete Audit → `3-Audit_Reports/V1_Jun-2026/Dashboard_Complete_Audit_2026-06-29.md`. Health 65/100 (no P0). New: BUG-DSH-007 (role-name drift, 4 dashboards 403), SEC-DSH-008 (Foundational sub-pages ungated), SEC-DSH-009 (permission unseeded), DATA-DSH-001 (silent catch, no logging), DATA-DSH-002 (no session scoping). Confirmed existing PERF-DSH-001/005, BUG-DSH-006, DEAD-DSH-001. Reconciled stale SEC-DSH-002/006/007. |
