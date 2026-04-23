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

### D12: Database Queue Driver (Current)
- **Why:** Simpler infrastructure for initial deployment. No Redis dependency needed.
- **Future:** Will migrate to Redis queue driver when scaling requires it.

### D17: SmartTimetable Constraint Model/Migration Mismatches — Audit & Fix Strategy
- **Mismatch A:** ConstraintCategory/ConstraintScope pointed to non-existent tables. **Fix:** Both now use `tt_constraint_category_scope` with `addGlobalScope` for `type`. ConstraintCategoryScope is the raw combined-table model.
- **Mismatch B:** ConstraintType fillable had columns not in DB (`is_hard_capable`, `parameter_schema`, etc.). **Fix:** Migration 1 adds them additively; old `is_hard_constraint`/`param_schema` kept.
- **Mismatch C:** Constraint model column names differed from DB (`academic_term_id` vs `academic_session_id`, etc.). **Fix (model-side):** Updated model to use actual DB column names. Migration 2 adds alias columns for compat.
- **Rule:** Corrective migrations are additive only — no drops, no renames.

### D16: SmartTimetable Constraint Management — Static Catalogue View Pattern
- **Why:** The constraint management page is a documentation/configuration catalogue, not CRUD over a single DB table. Different tabs represent different constraint categories each with different columns and semantics.
- **Pattern:** One route + one controller method returning 8 empty `collect()` vars. Index blade uses 8-tab nav-tab. Each tab `@include`s its own `partials/{slug}/_list.blade.php`. Static `@php` sample rows in each partial — replace with DB data when constraint engine is wired.
- **PHP Class column (db-constraints tab):** Badge `Registered` (bg-primary) if wired in `CONSTRAINT_CLASS_MAP`, `Not wired` (bg-warning text-dark) if not.
- **Read-only tabs:** `engine-rules` (always-on hardcoded, no Add/Trash) and `activity-constraints` (fields on `tt_activities`, no Action col).

### D18: HPC CRUD Data Auto-Mapping into PDFs — `HpcPdfDataService` + `$hpcData` Variable Pattern
- **Why:** 10 CRUD modules (Circular Goals, Evaluations, Syllabus Coverage, etc.) store data separately from the teacher-entered `$savedValues`. 8 of 10 have multi-row list data that cannot fit into single `html_object_name` keys. Needed a way to auto-display CRUD data in PDFs without manual teacher re-entry.
- **Pattern (Approach B — Minimal Blade Change):** `HpcPdfDataService::getData()` fetches all CRUD data into a single `$hpcData` array. Controller passes it alongside `$savedValues` (never merged). Blade templates extract into local vars with safe `?? collect()` defaults. A shared `_crud_sections.blade.php` partial renders tables after existing form sections, guarded by `@if($isPdf)` + `@if($collection->isNotEmpty())`.
- **Alternative rejected (Approach A):** Augmenting `$savedValues` directly — rejected because multi-row list data cannot fit into single `html_object_name` fields.
- **Key rule:** Service never throws. All `Throwable` caught, empty defaults returned. PDF generation must never crash due to CRUD data failure.

### D19: HPC Queued Email to Guardians — Job-Based PDF Generation + Email Pattern
- **Why:** PDF generation (DomPDF) for 30-46 page reports takes 5-30 seconds. Synchronous email would block the HTTP request. Needed background processing with tenant context restoration.
- **Pattern:** `SendHpcReportEmail` Job implements `ShouldQueue`. Controller dispatches with `$studentId`, `$academicTermId`, `$tenantId` (string only, not model). Job re-initializes tenancy via `tenancy()->initialize($tenantId)` with `try/finally { tenancy()->end() }`. Mailable does NOT implement `ShouldQueue` — Job handles queuing, Mailable sends synchronously inside Job. Uses `Mail::to()->send()` not `Mail::queue()`.
- **Pre-flight checks:** Controller validates student exists, template resolves, guardian emails exist BEFORE dispatching. Returns JSON with guardian count.
- **Trade-off:** `buildPdf()` and `minifyHtml()` changed from `private` to `public` on HpcController so Job can call them. Cleaner alternative (future): extract to `HpcReportService`.

### D22: HPC Email — Link-Based Instead of PDF Attachment (2026-03-21, Developer Change)
- **Why:** PDF generation in the Job was slow (5-30s per student), consumed 512MB memory, and produced large email attachments that some providers rejected.
- **New pattern:** Job now sends a signed URL link (`Crypt::encryptString` for student_id) to guardians. Guardian clicks link → views report in browser. No PDF generated in Job.
- **Supersedes D19:** Job no longer calls `HpcReportService::buildPdf()`. Timeout reduced from 300s to 120s. All Storage/View/HpcReport imports removed from Job.
- **Trade-off:** Guardian must have internet access to view report (can't view offline from email). PDF still available via on-demand browser generation.
- **Verify:** `route('hpc.hpc-form.view')` must accept encrypted student_id parameter.

### D20: HPC Gap Analysis Findings — Revised Completion Model (2026-03-16)
- **Why:** Previous estimates (73%) only counted template structure + CRUD completion. Comprehensive gap analysis against official NEP 2020 PDFs (138 pages, 4 templates) and implementation blueprint (20 screens) revealed that multi-actor data collection (student/parent/peer), approval workflows, and 12 of 20 screens are NOT STARTED.
- **Finding:** Template structure is 100% complete (all 138 pages seeded with correct html_object_names). Web form and PDF generation are 90%. But data can only be entered by teachers — 64 of 138 pages (46%) should be filled by students, parents, or peers.
- **Revised estimate:** ~40% overall. Need ~13 developer-weeks to reach full implementation.
- **Reference:** `{HPC_GAP_ANALYSIS}`

### D-TMP-001: Template Output Config — Cross-Module FK to msh_class_groups
- **Decision (2026-04-16):** `tmp_template_assignments.class_group_id` references `msh_class_groups.id` directly (cross-module FK: Template → MarksheetGeneration).
- **Why:** The class grouping concept (Primary 1-5, Secondary 6-12) is identical between MSG and Template output. Creating a duplicate `sch_class_groups` table would cause data drift and maintenance burden. Template only READs `msh_class_groups`, never writes — no write coupling.
- **Trade-off:** Creates a dependency between Template and MSG modules. If more modules need class grouping in future, promote `msh_class_groups` to `sch_class_groups` via migration.

### D-TMP-002: Template Output Config — Separate tmp_template_purposes Table (Not tmp_templates.type)
- **Decision (2026-04-16):** A dedicated `tmp_template_purposes` lookup table is used instead of relying on `tmp_templates.type`.
- **Why:** The existing `type` column is free-text `VARCHAR(255)`, nullable, with no validation or uniqueness. It cannot reliably enforce purpose-based assignment. The `type` column continues as a user-friendly categorization label; `tmp_template_purposes` provides the system-enforced purpose registry with UNIQUE codes.

### D-TMP-003: Template Output Config — scope_hash Generated Column for Uniqueness
- **Decision (2026-04-16):** A `STORED` generated column `scope_hash` on `tmp_template_assignments` enforces uniqueness across all scope types via a single UNIQUE index.
- **Why:** MySQL treats NULLs as distinct in UNIQUE indexes, so a composite UNIQUE on `(purpose_id, session_id, class_id, class_group_id)` would allow duplicate school-wide assignments (both NULLs). The `scope_hash` generates a deterministic string (`"purpose:session:C{id}|G{id}|SCHOOL"`) enabling database-enforced uniqueness for all three scope types.
- **Trade-off:** Soft-deleted rows retain their `scope_hash`, blocking new assignments for the same scope. To reassign, restore+update the old record or force-delete it.

### D-TMP-004: Template Output Config — No FK Coupling to msh_config_templates
- **Decision (2026-04-16):** `tmp_template_assignments` does NOT reference `msh_config_templates.id`.
- **Why:** Template visual assignment (HOW the marksheet looks) and marksheet computation config (WHAT scores are computed) are separate concerns. They are resolved independently at render time and combined by the service layer. FK coupling would create an unnecessary bidirectional dependency.

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

### D21: Accounting — Tally-Inspired Voucher Engine (3 Separate Modules)
- **Decision (2026-03-20):** Build custom Tally-Prime-inspired double-entry system. Three SEPARATE Laravel modules: `Modules/Accounting/` (acc_), `Modules/Payroll/` (prl_), `Modules/Inventory/` (inv_).
- **Why:** Schools use Tally Prime for CA filing. Voucher-based model (not journal-entry) mirrors Tally concepts. Separate modules enable independent deployment.
- **Key architecture:** Accounting owns `acc_vouchers` + `acc_voucher_items`. Payroll & Inventory consume via `VoucherServiceInterface`. Every transaction = Dr + Cr entries.
- **Old DDL:** 31 acc_* tables in tenant_db_v2.sql are UNUSED initial drafts with zero development — replaced entirely by new 21-table voucher schema.
- **sch_employees reuse:** Enhanced via ALTER TABLE (14 payroll columns) — NOT duplicated as acc_employees.
- **sch_categories = employee groups:** Existing table used for staff grouping. Payroll extends via `prl_category_statutory_config` (PF/ESI/PT flags) instead of creating duplicate sch_employee_groups.
- **Tally mapping:** `acc_tally_ledger_mappings` table maps our ledgers to Tally names for XML export/import.
- **Transport integration:** Transport fee charges/collections flow through voucher engine same as StudentFee.
- **Reference:** `1-DDL_Tenant_Modules/20-Account/Claude_Plan/Initial_Plan_v4.md`

### Pending: Redis Migration
- When to move queue, cache, and session drivers from database to Redis
- Dependent on production traffic patterns
