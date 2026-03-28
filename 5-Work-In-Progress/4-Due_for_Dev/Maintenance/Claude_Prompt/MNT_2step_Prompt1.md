# MNT — Maintenance Management Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **MNT (Maintenance)** module using `MNT_Maintenance_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `MNT_FeatureSpec.md` — Feature Specification
2. `MNT_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `MNT_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** Maintenance Management — Complete facility maintenance system for Indian K-12 schools.
Tables: `mnt_*` (11 tables covering asset categories, assets, depreciation, tickets, assignments, time logs, breakdown history, PM schedules, PM work orders, AMC contracts, external work orders).

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = MNT
MODULE            = Maintenance
MODULE_DIR        = Modules/Maintenance/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = Y                              # Maintenance & Facility Helpdesk in RBS v4.0
DB_TABLE_PREFIX   = mnt_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/Maintenance/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/MNT_Maintenance_Requirement.md

FEATURE_FILE      = MNT_FeatureSpec.md
DDL_FILE_NAME     = MNT_DDL_v1.sql
DEV_PLAN_FILE     = MNT_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — MNT (MAINTENANCE) MODULE

### What This Module Does

The Maintenance module provides a **structured, digitised facility maintenance system** for Indian K-12 schools on the Prime-AI SaaS platform. It replaces informal WhatsApp/verbal reporting with a ticketed helpdesk, automated technician assignment, SLA enforcement with escalation levels, preventive maintenance scheduling with auto-generated work orders, AMC contract tracking, external vendor work orders with DomPDF printing, QR-code scan-to-report for assets, asset depreciation tracking, breakdown history, and management-level reporting.

**L1 — Asset Category Management:**
- Category with name, code, `default_priority` ENUM, `sla_hours`, `auto_assign_role_id` (FK→sys_roles)
- `priority_keywords_json`: case-insensitive keyword → priority mapping (e.g., "flood" → Critical)
- `sla_escalation_json` (V2): multi-level escalation config (L1 = after X hrs → notify mnt-incharge; L2 = after Y hrs → notify principal)
- 9 seeded categories: Electrical, Plumbing, IT/Computer, Carpentry, Cleaning, HVAC, Fire Safety, Civil/Structural, Sports/Ground

**L2 — Asset Register:**
- Asset with `asset_code` (MNT-AST-XXXXXX, DB lock-for-update), location (building/floor/room), purchase_cost, warranty_expiry_date, `current_condition` ENUM
- QR code auto-generated on first save via SimpleSoftwareIO/simple-qrcode; stored as `sys_media`; scan → `/maintenance/tickets/create?asset_id={id}`
- Depreciation fields (V2): `depreciation_method` (SLM/WDV), `salvage_value`, `useful_life_years`, `depreciation_rate`, `accumulated_depreciation`, `current_book_value`
- `total_maintenance_cost` (V2): accumulated from ticket parts + work order actuals; recalculated on close/complete

**L3 — Asset Depreciation (V2):**
- `mnt_asset_depreciation`: one record per `(asset_id, financial_year)` — UNIQUE constraint
- SLM: `annual_charge = (purchase_cost − salvage_value) / useful_life_years`
- WDV: `annual_charge = opening_book_value × depreciation_rate / 100`
- `DepreciationService` performs calculation; FAC module hook scaffold for journal posting

**L4 — Maintenance Ticket Lifecycle:**
- Ticket number: `MNT-YYYY-XXXXXXXX` (4-digit year + 8-digit sequence, DB lock-for-update)
- `sla_due_at = created_at + category.sla_hours` (clock hours; business-hours mode in V3)
- Auto-priority from `priority_keywords_json`: `TicketService` scans description; Critical > High > Medium > Low; falls back to `category.default_priority`
- 7-state FSM: `Open → Accepted → In_Progress ↔ On_Hold → Resolved → Closed`; `Cancelled` from any pre-Resolved state (admin only)
- Before photos required on `In_Progress` transition; after photos required on `Resolved` (configurable via `sys_school_settings.mnt_require_photos`)
- `resolution_notes` (min 20 chars) mandatory on `Resolved` transition (BR-MNT-004)
- On `Resolved` with `asset_id`: auto-insert `mnt_breakdown_history` record (BR-MNT-014)

**L5 — Technician Assignment:**
- `AssignmentService`: filter by `category.auto_assign_role_id`; score by `open_ticket_count ASC` + location match bonus; assign top scorer
- On no match: ticket stays `Open`; Maintenance Incharge notified for manual assignment (BR-MNT-005)
- `mnt_ticket_assignments`: full history — `is_current=1` marks active assignment; reassignment logs previous with reason

**L6 — SLA & Escalation:**
- `CheckSlaBreachesJob` (every 30 min): sets `is_sla_breached=1` when `sla_due_at < NOW` and status not Resolved/Closed
- `EscalationService` (V2): reads `category.sla_escalation_json`; fires L1 notification at L1 threshold, L2 at L2; sets `ticket.escalation_level` flag; logs to `sys_activity_logs`

**L7 — Preventive Maintenance:**
- `mnt_pm_schedules`: `recurrence` ENUM (Daily/Weekly/Monthly/Quarterly/Yearly), `checklist_items_json`, `next_due_date`
- `GeneratePmWorkOrdersJob` (daily 06:00): creates `mnt_pm_work_orders` for due schedules; BR-MNT-006: skip if pending/in-progress WO already exists
- Technician completes checklist items → when all checked → status=Completed → updates `asset.last_pm_date` + `current_condition`
- `MarkOverduePmWorkOrdersJob` (daily 07:00): sets Overdue if `due_date < today` and status ∈ {Pending, In_Progress}

**L8 — AMC Contracts & Work Orders:**
- `mnt_amc_contracts`: `covered_assets_ids_json`, `renewal_alert_sent_60/30/7` flags
- `SendAmcExpiryAlertsJob` (daily 08:00): fires alerts at exactly 60, 30, 7 days — once per threshold (BR-MNT-007)
- `mnt_work_orders`: optional FK to `mnt_tickets` + `mnt_amc_contracts`; DomPDF PDF print
- On WO completion: `actual_cost` captured; `asset.total_maintenance_cost` recalculated (BR-MNT-012)
- FAC cost posting scaffold: hook on completion for future journal entry

### Architecture Decisions
- **Single Laravel module** (`Modules\Maintenance`) — all 8 sub-modules in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `maintenance/` | Route name prefix: `mnt.`
- Mobile API: `auth:sanctum`, prefix `/api/v1/maintenance` — 9 endpoints for field staff
- SimpleSoftwareIO/simple-qrcode — already installed (used by Transport module); QR stored to `sys_media`
- DomPDF (`barryvdh/laravel-dompdf`) — already installed (used by HPC/CRT); used for work order PDF print
- Vendor data: references `vnd_vendors` (Vendor module); no vendor master duplication
- INV spare parts: `parts_used` free-text for now; FK integration point documented for INV module
- FAC cost posting: hook scaffold in `WorkOrderController` for future `acc_journal_entries` FK

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 8 web + 1 mobile API = 9 |
| Models | 11 |
| Services | 5 (TicketService, AssignmentService, PmScheduleService, EscalationService, DepreciationService) |
| FormRequests | 11 (from req spec Section 15) |
| Policies | 11 |
| Jobs | 4 scheduled jobs |
| mnt_* tables | 11 |
| Blade views (estimated) | ~35 |
| Web routes | ~55 |
| Mobile API routes | ~9 |

### Complete Table Inventory

**Asset Management (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `mnt_asset_categories` | Category master | UNIQUE `(name)`; UNIQUE `(code)` nullable |
| 2 | `mnt_assets` | Asset register | UNIQUE `(asset_code)`; FK → mnt_asset_categories |
| 3 | `mnt_asset_depreciation` | Annual depreciation records | UNIQUE `(asset_id, financial_year)` |

**Ticket Management (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 4 | `mnt_tickets` | Corrective maintenance tickets | UNIQUE `(ticket_number)`; INDEX `(status, priority)`, `(assigned_to_user_id, status)`, `(category_id, status)`, `(sla_due_at)`, `(is_sla_breached, status)` |
| 5 | `mnt_ticket_assignments` | Assignment history | INDEX `(ticket_id, is_current)` |
| 6 | `mnt_ticket_time_logs` | Time and parts per ticket | INDEX `(ticket_id)` |
| 7 | `mnt_breakdown_history` | Auto-populated on asset ticket resolution | INDEX `(asset_id, breakdown_date)` |

**Preventive Maintenance (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 8 | `mnt_pm_schedules` | PM schedule definitions | FK → mnt_assets |
| 9 | `mnt_pm_work_orders` | Auto-generated PM WOs | INDEX `(pm_schedule_id, status)` |

**Contracts & Work Orders (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 10 | `mnt_amc_contracts` | AMC contracts | UNIQUE `(contract_number)` nullable |
| 11 | `mnt_work_orders` | External vendor work orders | UNIQUE `(wo_number)` |

**Existing Tables REUSED (Maintenance reads from; never modifies schema unless documented):**
| Table | Source | Maintenance Usage |
|---|---|---|
| `vnd_vendors` | Vendor (VND) | AMC vendor, work order vendor |
| `sys_users` | System | Technician assignments, requester, created_by, approved_by |
| `sys_roles` | System | Category auto-assignment role, escalation notify role |
| `sys_media` | System | Before/after photos (polymorphic), QR code storage, contract documents, asset photos |
| `sys_activity_logs` | System | All audit events: transitions, assignments, priority overrides, escalations |
| `sys_school_settings` | SchoolSetup (SCH) | Timezone (SLA calc), `mnt_require_photos` setting |
| `ntf_notifications` | Notification (NTF) | Assignment alerts, SLA/escalation alerts, AMC expiry alerts, requester status updates |

### Cross-Module Integration (Post-Hooks & Event Scaffold)
```
On Ticket Resolved (with asset_id set):
  → Insert mnt_breakdown_history (downtime_hours = resolved_at − created_at)
  → Done inside TicketService::updateStatus() post-hook (BR-MNT-014)

On Ticket Closed:
  → Recalculate asset.total_maintenance_cost (BR-MNT-012)
  → Send rating prompt to requester via NTF module

On Work Order Completed:
  → Recalculate asset.total_maintenance_cost (BR-MNT-012)
  → FAC cost posting hook scaffold (debit Maintenance Expense) — future integration

On Asset Depreciation Calculated:
  → FAC journal hook scaffold (mnt_asset_depreciation.posted_to_fac flag)

On AMC Alert:
  → Notification dispatch via NTF module (NTF module owns listener)
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — MNT v2 requirement (11 FRs, Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: vnd_vendors, sys_users, sys_roles, sys_media, sys_school_settings (use exact column names in spec)

### Phase 1 Task — Generate `MNT_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope sub-modules (L1–L8 verbatim from req v2 Section 2.2)
- Out-of-scope: student management (std_*), fee management (fin_*), HR leave calendar (V3 future), INV parts deduction (future), FAC journal posting (scaffold only)
- Module scale table (controller / model / service / job / FormRequest / policy / table / view counts)

#### Section 2 — Entity Inventory (All 11 Tables)
For each `mnt_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Asset Management** (mnt_asset_categories, mnt_assets, mnt_asset_depreciation)
- **Ticket Management** (mnt_tickets, mnt_ticket_assignments, mnt_ticket_time_logs, mnt_breakdown_history)
- **Preventive Maintenance** (mnt_pm_schedules, mnt_pm_work_orders)
- **Contracts & Work Orders** (mnt_amc_contracts, mnt_work_orders)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 11 tables grouped by layer (mnt_* vs cross-module reads from vnd_*/sys_*).
Use `→` for FK direction (child → parent).

Critical cross-module FKs to highlight:
- `mnt_asset_categories.auto_assign_role_id → sys_roles.id` (nullable)
- `mnt_assets.category_id → mnt_asset_categories.id`
- `mnt_assets.amc_contract_id → mnt_amc_contracts.id` (nullable — circular: assets can reference AMC; AMC stores asset IDs in JSON)
- `mnt_assets.qr_code_media_id → sys_media.id` (nullable)
- `mnt_tickets.assigned_to_user_id → sys_users.id` (nullable)
- `mnt_ticket_assignments.assigned_to_user_id → sys_users.id`
- `mnt_breakdown_history.ticket_id → mnt_tickets.id` (nullable)
- `mnt_asset_depreciation.asset_id → mnt_assets.id` with UNIQUE `(asset_id, financial_year)`
- `mnt_pm_schedules.asset_id → mnt_assets.id`
- `mnt_pm_work_orders.pm_schedule_id → mnt_pm_schedules.id`
- `mnt_amc_contracts.vendor_id → vnd_vendors.id` (nullable — vendor may be free-text)
- `mnt_work_orders.ticket_id → mnt_tickets.id` (nullable)

#### Section 4 — Business Rules (16 rules)
For each rule, state:
- Rule ID (BR-MNT-001 to BR-MNT-016)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event` | `scheduled_job`

Critical rules to emphasise:
- BR-MNT-001: Ticket number MNT-YYYY-XXXXXXXX — DB lock-for-update prevents duplicates
- BR-MNT-003: Status transitions strictly enforced as state machine; invalid transitions return HTTP 422
- BR-MNT-004: `resolution_notes` (min 20 chars) mandatory on Resolved transition — form_validation
- BR-MNT-006: PM WO generation skipped if Pending/In_Progress WO already exists for same schedule
- BR-MNT-007: AMC alerts fire exactly once at 60/30/7 days — tracked by `renewal_alert_sent_*` flags
- BR-MNT-008: Technician can only view/update tickets where `is_current=1` AND `assigned_to_user_id = auth()->id()` — TicketPolicy
- BR-MNT-011: SLA escalation levels — EscalationService reads `sla_escalation_json`; sets `escalation_level` flag
- BR-MNT-012: `asset.total_maintenance_cost` recalculated on ticket close and WO completion
- BR-MNT-014: On ticket Resolved with asset_id: auto-insert `mnt_breakdown_history`; `downtime_hours = resolved_at − created_at`
- BR-MNT-015: QR code auto-generated on first asset save; regenerated if `asset_code` changes
- BR-MNT-016: `mnt_asset_depreciation` UNIQUE `(asset_id, financial_year)` — running twice for same year = validation error
- **No `tenant_id` column** — isolation at DB level via stancl/tenancy

#### Section 5 — Workflow State Machines (4 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, notifications, post-hooks)

FSMs to document:
1. **Ticket Lifecycle FSM** — `Open → Accepted → In_Progress ↔ On_Hold → Resolved → Closed`; `Cancelled` from Open/Accepted/In_Progress/On_Hold (admin only)
   - On Accepted: assignment logged; requester notified
   - On In_Progress: before photos required (if setting enabled); requester notified
   - On Resolved: after photos required; resolution_notes mandatory; `mnt_breakdown_history` auto-inserted if asset_id set; requester notified
   - On Closed: rating prompt queued; `total_maintenance_cost` recalculated on asset
2. **PM Work Order FSM** — `Pending → In_Progress → Completed`; Overdue (daily cron); Cancelled (admin)
   - On Completed: `asset.last_pm_date` updated; `asset.current_condition` updated; `pm_schedule.next_due_date` advanced
3. **AMC Expiry Alert Flow** — daily cron queries Active contracts; fires alert at 60/30/7 days exactly once; auto-sets status=Expired when `end_date < NOW`
4. **QR Scan-to-Report Flow** — scan QR → GET `/maintenance/tickets/create?asset_id={id}` → pre-fill asset + location → `TicketService::create()` → keyword priority → auto-assign → notify technician

#### Section 6 — Functional Requirements Summary (11 FRs)
For each FR-MNT-01 to FR-MNT-11:
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by sub-module (L1–L8 per req v2 Sections 4.1–4.11).

#### Section 7 — Permission Matrix
| Permission Slug | Admin | Principal | Admin/Office Staff | Teacher/Student | Maint Incharge | Technician |
|---|---|---|---|---|---|---|

Derive from req v2 Section 15.3. Include all 13 permission slugs from:
- `tenant.mnt-asset-category.view/manage`
- `tenant.mnt-asset.view/manage`
- `tenant.mnt-ticket.create/view/update/manage`
- `tenant.mnt-pm-schedule.manage`
- `tenant.mnt-pm-work-order.update`
- `tenant.mnt-amc-contract.manage`
- `tenant.mnt-work-order.manage`
- `tenant.mnt-report.view`

Which Policy class enforces each permission (11 policies from req v2 Section 2.4).

#### Section 8 — Service Architecture (5 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\Maintenance\app\Services
Depends on:  [other services it calls]
Fires:       [events/notifications it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **TicketService** — `createTicket()` (keyword priority + auto-assign + SLA calc), `updateStatus()` (state machine + photo enforcement + breakdown history hook), `manualAssign()`, `overridePriority()`, `storeTimeLog()`, `rate()`
2. **AssignmentService** — `autoAssign(Ticket $ticket): ?User` (role filter + open-ticket score + location bonus), `manualReassign()`, `getWorkloadByRole()`
3. **PmScheduleService** — `generateWorkOrders()` (daily batch — BR-MNT-006 duplicate check), `completeWorkOrder(PmWorkOrder $wo, array $checklistData): void` (all items completed → asset update + next_due_date advance), `markOverdue()`
4. **EscalationService** (V2) — `checkEscalations(Ticket $ticket): void` (reads `sla_escalation_json`; fires L1/L2 notifications; updates `escalation_level`); called by `CheckSlaBreachesJob`
5. **DepreciationService** (V2) — `calculateSLM(Asset $asset, string $financialYear): AssetDepreciation`, `calculateWDV(Asset $asset, string $financialYear): AssetDepreciation`, `recalculateBookValue(Asset $asset): void`; UNIQUE constraint prevents double-calculation per year (BR-MNT-016)

Include the ticket creation sequence as inline pseudocode in `TicketService`:
```
createTicket(array $data, User $requester): Ticket
  Step 1: DB transaction begins
  Step 2: Determine priority
           → TicketService::resolvePriority($data['description'], $category)
           → Case-insensitive LIKE scan against priority_keywords_json (BR-MNT-009)
           → Critical > High > Medium > Low fallback to category.default_priority
  Step 3: Calculate sla_due_at = now() + category.sla_hours (in hours) (BR-MNT-002)
  Step 4: Lock-for-update serial counter → generate ticket_number MNT-YYYY-XXXXXXXX (BR-MNT-001)
  Step 5: Create mnt_tickets row (status=Open, priority_source set)
  Step 6: DB transaction commits
  Step 7: AssignmentService::autoAssign($ticket) — runs outside transaction
  Step 8: If assigned: create mnt_ticket_assignments (is_current=1); notify technician via NTF
  Step 9: If unassigned: notify Maintenance Incharge (BR-MNT-005)
  Step 10: Log to sys_activity_logs
```

#### Section 9 — Integration Contracts (5 events/hooks)
For each integration point:
| Event / Hook | Fired By | Listener / Target | Payload | Action |
|---|---|---|---|---|
- Assignment notification → NTF module → Technician: "New ticket: {title} — {location} — Priority: {level}"
- SLA breach notification → NTF module → Maintenance Incharge (L1), Principal (L2)
- AMC expiry alert → NTF module → Maintenance Incharge: 60/30/7 days warning
- Breakdown history hook → `TicketService::updateStatus()` → `mnt_breakdown_history` insert (direct, not event)
- FAC cost posting scaffold → `WorkOrderController::complete()` → stub method (future integration)

Document notification payload structure for assignment notification and SLA escalation L1/L2.

#### Section 10 — Non-Functional Requirements
From req v2 Section 10, add an "Implementation Note" column:
- Ticket list (< 2s for 10,000 tickets): composite indexes `(status, priority)` + `(assigned_to_user_id, status)`
- Ticket number concurrency: `lockForUpdate()` in DB transaction (BR-MNT-001)
- Mobile API JSON < 20 KB per page: paginated + select() only necessary fields in `MobileMaintenanceController`
- SLA timezone: `Carbon::now($timezone)` where timezone from `sys_school_settings`
- Work order PDF: DomPDF with school header + logo; A4 portrait
- QR code: SimpleSoftwareIO/simple-qrcode → PNG stored to sys_media; print-ready at 300dpi equivalent
- Queue for notifications: database driver by default; Redis recommended for production
- 100,000-row ticket table: all dashboard queries use indexed columns; no full-table scans

#### Section 11 — Test Plan Outline
From req v2 Section 12 (20 test scenarios):

**Feature Tests (Pest) — 11 test files:**
| File | Key Scenarios |
|---|---|
(List files covering: ticket creation/priority, auto-assignment, status transitions, SLA breach, SLA escalation, PM WO generation, AMC expiry alert, technician authorization, QR code generation, breakdown history, work order cost rollup)

**Unit Tests (PHPUnit) — 3 test files:**
| File | Key Scenarios |
|---|---|
- `AssetDepreciationTest` — SLM annual charge formula; WDV annual charge formula; UNIQUE constraint blocks same year
- `KeywordPriorityTest` — case-insensitive match; Critical > High precedence; fallback to default
- `SlaCalculationTest` — sla_due_at computed correctly; timezone-aware with Carbon

**Policy Tests:**
- `TicketPolicyTest` — Technician cannot update ticket assigned to another; Admin can update any; Teacher can only create (not manage)

**Test Data:**
- Required seeders for test DB: MntAssetCategorySeeder (9 categories)
- Required factories: AssetCategoryFactory, AssetFactory, TicketFactory, PmScheduleFactory, PmWorkOrderFactory
- Mock strategy: `Queue::fake()` for jobs (GeneratePmWorkOrdersJob, CheckSlaBreachesJob, SendAmcExpiryAlertsJob); `Event::fake()` for notification triggers; `Storage::fake()` for QR code + photo tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `MNT_FeatureSpec.md` | `{OUTPUT_DIR}/MNT_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 11 mnt_* tables appear in Section 2 entity inventory
- [ ] All 11 FRs (MNT-01 to MNT-11) appear in Section 6
- [ ] All 16 business rules (BR-MNT-001 to BR-MNT-016) in Section 4 with enforcement point
- [ ] All 4 FSMs documented with ASCII state diagram and side effects
- [ ] All 5 services listed with key method signatures in Section 8
- [ ] Ticket creation 10-step pseudocode present in TicketService
- [ ] BR-MNT-001 (ticket number lock-for-update) explicitly documented
- [ ] BR-MNT-003 (state machine enforcement, HTTP 422 on invalid) explicitly documented
- [ ] BR-MNT-004 (resolution_notes mandatory on Resolved, min 20 chars) explicitly documented
- [ ] BR-MNT-006 (PM WO duplicate skip) explicitly documented in PmScheduleService
- [ ] BR-MNT-007 (AMC alert fires once per threshold — renewal_alert_sent_* flags) explicitly documented
- [ ] BR-MNT-011 (SLA escalation levels — sla_escalation_json → escalation_level flag) in EscalationService
- [ ] BR-MNT-014 (breakdown history auto-insert on Resolved with asset_id) in TicketService
- [ ] BR-MNT-015 (QR auto-generated on first save) in AssetController
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] `mnt_asset_depreciation` UNIQUE `(asset_id, financial_year)` noted
- [ ] Permission matrix covers Admin / Principal / Office Staff / Teacher/Student / Maint Incharge / Technician roles
- [ ] All cross-module column names verified against tenant_db_v2.sql (use EXACT names from DDL)

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/MNT_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/MNT_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Sections 5.2–5.6 (canonical column definitions for all 11 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`MNT_DDL_v1.sql`)

Generate CREATE TABLE statements for all 11 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**

1. Table prefix: `mnt_` for all tables — no exceptions
2. Every table MUST include: `id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
   - **EXCEPTION:** `mnt_asset_depreciation` and `mnt_breakdown_history` — NO `deleted_at` (immutable audit records; see rule 14)
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (not applicable to MNT — no pure junction tables)
5. JSON columns: suffix `_json` (e.g. `priority_keywords_json`, `sla_escalation_json`, `checklist_items_json`, `checklist_completion_json`, `covered_assets_ids_json`)
6. Boolean flag columns: prefix `is_` or `has_` (e.g. `is_sla_breached`, `is_current`, `renewal_alert_sent_*`)
7. All FK references: `BIGINT UNSIGNED` for sys_* cross-module FKs; `INT UNSIGNED` for mnt_* internal FKs (PKs are INT UNSIGNED per DDL rule 2)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_mnt_{tableshort}_{column}` (e.g. `fk_mnt_ast_category_id`)
12. **Do NOT recreate vnd_*, sys_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `mnt_asset_depreciation`: NO `is_active`, NO `updated_by`, NO `deleted_at` — immutable annual record; only `created_by`, `created_at`, `updated_at`. `mnt_breakdown_history`: NO `is_active`, NO `deleted_at` — immutable event log; standard `created_by`, `created_at`, `updated_at`.

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No mnt_* dependencies (may reference sys_*/vnd_* only):
  `mnt_asset_categories` (→ sys_roles nullable)

Layer 2 — Depends on Layer 1 + cross-module:
  `mnt_amc_contracts` (→ vnd_vendors nullable)
  [Note: mnt_assets references mnt_amc_contracts; mnt_amc_contracts comes before mnt_assets to break the potential circular dependency — covered_assets_ids_json is JSON not FK]

Layer 3 — Depends on Layer 1 + Layer 2:
  `mnt_assets` (→ mnt_asset_categories + mnt_amc_contracts nullable + sys_media nullable × 2)

Layer 4 — Depends on Layer 3:
  `mnt_asset_depreciation` (→ mnt_assets) [UNIQUE: asset_id, financial_year],
  `mnt_pm_schedules` (→ mnt_assets + mnt_asset_categories nullable + sys_roles nullable)

Layer 5 — Depends on Layer 3 (tickets reference categories + assets):
  `mnt_tickets` (→ mnt_asset_categories + mnt_assets nullable + sys_users × 2)

Layer 6 — Depends on Layer 5:
  `mnt_ticket_assignments` (→ mnt_tickets + sys_users × 2),
  `mnt_ticket_time_logs` (→ mnt_tickets + sys_users),
  `mnt_breakdown_history` (→ mnt_assets + mnt_tickets nullable)

Layer 7 — Depends on Layer 4 + Layer 5:
  `mnt_pm_work_orders` (→ mnt_pm_schedules + mnt_assets + sys_users nullable),
  `mnt_work_orders` (→ mnt_tickets nullable + mnt_amc_contracts nullable + sys_users nullable + vnd_vendors nullable)

**Critical unique constraints to include:**
```sql
-- mnt_asset_categories
UNIQUE KEY uq_mnt_ac_name (name)
UNIQUE KEY uq_mnt_ac_code (code)   -- nullable, allows multiple NULLs

-- mnt_assets
UNIQUE KEY uq_mnt_ast_asset_code (asset_code)

-- mnt_asset_depreciation
UNIQUE KEY uq_mnt_adep_asset_year (asset_id, financial_year)

-- mnt_tickets
UNIQUE KEY uq_mnt_tkt_ticket_number (ticket_number)

-- mnt_amc_contracts
UNIQUE KEY uq_mnt_amc_contract_number (contract_number)   -- nullable

-- mnt_work_orders
UNIQUE KEY uq_mnt_wo_number (wo_number)
```

**ENUM values (exact, to match application code):**
```
mnt_asset_categories.default_priority:   'Low','Medium','High','Critical'
mnt_assets.current_condition:            'Good','Fair','Poor','Critical','Decommissioned'
mnt_assets.depreciation_method:         'SLM','WDV'    -- NULL if not set
mnt_asset_depreciation.method:          'SLM','WDV'
mnt_tickets.priority:                   'Low','Medium','High','Critical'
mnt_tickets.priority_source:            'Auto_Keyword','Auto_Category','Manual_Override'
mnt_tickets.status:                     'Open','Accepted','In_Progress','On_Hold','Resolved','Closed','Cancelled'
mnt_ticket_assignments.assignment_type: 'Auto','Manual','Reassigned'
mnt_pm_schedules.recurrence:            'Daily','Weekly','Monthly','Quarterly','Yearly'
mnt_pm_work_orders.status:              'Pending','In_Progress','Completed','Overdue','Cancelled'
mnt_amc_contracts.status:               'Active','Expired','Cancelled','Pending_Renewal'
mnt_amc_contracts.payment_frequency:    'Monthly','Quarterly','Half_Yearly','Yearly'
mnt_work_orders.status:                 'Draft','Issued','In_Progress','Completed','Cancelled'
```

**Critical columns to get right:**
- `mnt_tickets.sla_due_at`: `TIMESTAMP NULL` — set on creation = created_at + sla_hours
- `mnt_tickets.is_sla_breached`: `TINYINT(1) NOT NULL DEFAULT 0` — set by CheckSlaBreachesJob
- `mnt_tickets.escalation_level`: `TINYINT UNSIGNED NOT NULL DEFAULT 0` (V2: 0=none, 1=L1, 2=L2)
- `mnt_ticket_assignments.is_current`: `TINYINT(1) NOT NULL DEFAULT 1` — only one active assignment per ticket
- `mnt_assets.total_maintenance_cost`: `DECIMAL(12,2) NOT NULL DEFAULT 0.00` — accumulated, recalculated on ticket close/WO completion
- `mnt_assets.qr_code_media_id`: `INT UNSIGNED NULL FK→sys_media` — populated on first asset save
- `mnt_amc_contracts.renewal_alert_sent_60`: `TINYINT(1) NOT NULL DEFAULT 0` (and `_30`, `_7`) — idempotency flags
- `mnt_pm_schedules.checklist_items_json`: `JSON NOT NULL` — array of task strings, min 1 item
- `mnt_pm_work_orders.checklist_completion_json`: `JSON NULL` — per-item completion status + notes
- `mnt_asset_depreciation.posted_to_fac`: `TINYINT(1) NOT NULL DEFAULT 0` — FAC integration scaffold flag

**File header comment to include:**
```sql
-- =============================================================================
-- MNT — Maintenance Management Module DDL
-- Module: Maintenance (Modules\Maintenance)
-- Table Prefix: mnt_* (11 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: MNT_Maintenance_Requirement.md v2
-- Sub-Modules: L1 Asset Categories, L2 Asset Register, L3 Depreciation,
--              L4 Tickets, L5 Assignment, L6 SLA/Escalation,
--              L7 Preventive Maintenance, L8 AMC + Work Orders
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`MNT_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_mnt_tables.php`.
- `up()`: creates all 11 tables in Layer 1 → Layer 7 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 7 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, JSON with `->json()`, decimal with `->decimal()`
- All FK constraints added in `up()` using `$table->foreign()`
- Note: `mnt_asset_depreciation` and `mnt_breakdown_history` — do NOT add `$table->softDeletes()` (DDL rule 14)

### Phase 2C Task — Generate Seeders (2 seeders + 1 runner)

Namespace: `Modules\Maintenance\Database\Seeders`

**1. `MntAssetCategorySeeder.php`** — 9 seeded categories from req v2 Section 15.1:
```
Electrical      | code: ELEC | default_priority: Medium | sla_hours: 8
                | High keywords: short circuit, no power, power failure, tripping
                | Critical keywords: electrocution, fire, sparks

Plumbing        | code: PLMB | default_priority: Medium | sla_hours: 12
                | High keywords: water leakage, tap dripping, drain blocked
                | Critical keywords: flooding, burst pipe, sewage overflow

IT/Computer     | code: ITCP | default_priority: Medium | sla_hours: 24
                | High keywords: system not working, printer down, projector
                | Critical keywords: server down, internet down

Carpentry       | code: CRPT | default_priority: Low | sla_hours: 48
                | High keywords: broken furniture, door stuck, window broken

Cleaning        | code: CLNG | default_priority: Low | sla_hours: 4
                | High keywords: not cleaned, dirty
                | Critical keywords: biohazard, vomit, spillage

HVAC            | code: HVAC | default_priority: Medium | sla_hours: 24
                | High keywords: AC not cooling, AC dripping
                | Critical keywords: AC not working at all, fire from AC

Fire Safety     | code: FIRE | default_priority: High | sla_hours: 4
                | High keywords: extinguisher expired, alarm fault
                | Critical keywords: fire detected, smoke alarm

Civil/Structural| code: CVIL | default_priority: Medium | sla_hours: 48
                | High keywords: crack in wall, ceiling damage
                | Critical keywords: roof collapse risk, structural damage

Sports/Ground   | code: SPRT | default_priority: Low | sla_hours: 72
                | High keywords: equipment damaged, ground waterlogged
```
Note: `priority_keywords_json` stored as `{"High":["keyword1","keyword2"],"Critical":["keyword3"]}`.
`sla_escalation_json` can be NULL in seeds; admin configures per school.
`auto_assign_role_id` = NULL in seeds; admin maps roles per school.

**2. `MntSeederRunner.php`** (Master seeder, calls all in order):
```php
$this->call([
    MntAssetCategorySeeder::class,   // no dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `MNT_DDL_v1.sql` | `{OUTPUT_DIR}/MNT_DDL_v1.sql` |
| `MNT_Migration.php` | `{OUTPUT_DIR}/MNT_Migration.php` |
| `MNT_TableSummary.md` | `{OUTPUT_DIR}/MNT_TableSummary.md` |
| `Seeders/MntAssetCategorySeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/MntSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 11 mnt_* tables exist in DDL (3 asset + 4 ticket + 2 PM + 2 contracts = 11 ✓)
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on 9 regular tables
- [ ] `mnt_asset_depreciation`: NO `is_active`, NO `updated_by`, NO `deleted_at` (DDL rule 14)
- [ ] `mnt_breakdown_history`: NO `is_active`, NO `deleted_at` (DDL rule 14)
- [ ] `mnt_tickets` has all 5 composite indexes: `(status, priority)`, `(assigned_to_user_id, status)`, `(category_id, status)`, `(sla_due_at)`, `(is_sla_breached, status)`
- [ ] `mnt_asset_depreciation` UNIQUE on `(asset_id, financial_year)`
- [ ] `mnt_tickets.sla_due_at` is TIMESTAMP NULL
- [ ] `mnt_tickets.escalation_level` is TINYINT UNSIGNED DEFAULT 0
- [ ] `mnt_amc_contracts` has three `renewal_alert_sent_*` TINYINT columns (60, 30, 7)
- [ ] `mnt_pm_schedules.checklist_items_json` is JSON NOT NULL
- [ ] `mnt_pm_work_orders.checklist_completion_json` is JSON NULL
- [ ] **No `tenant_id` column** on any table
- [ ] All unique constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_mnt_` convention throughout
- [ ] MntAssetCategorySeeder has all 9 categories with correct SLA hours and keyword JSON
- [ ] `priority_keywords_json` format: `{"High":[...],"Critical":[...]}` (Critical and High only; no Low/Medium keywords)
- [ ] `MNT_TableSummary.md` has one-line description for all 11 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `MNT_DDL_v1.sql` + Migration + 2 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/MNT_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 12 (tests), Section 15.4 (implementation phases), Section 15.3 (permission slugs)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `MNT_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 6. For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (9 total, from req v2 Section 2.4):
1. `MaintenanceController` — dashboard (KPI aggregates), calendar (monthly event JSON)
2. `AssetCategoryController` — index, store, show, update, destroy, toggle (PATCH)
3. `AssetController` — index, store, show, update, destroy, qrCode (GET — download QR), depreciation (GET), storeDepreciation (POST)
4. `TicketController` — index, create, store, show, update, updateStatus (PATCH), updatePriority (PATCH), assign (POST), storeTimeLog (POST), rate (POST)
5. `WorkOrderController` — index, store, show, update, updateStatus (PATCH), pdf (GET — DomPDF)
6. `PmScheduleController` — index, store, show, update, destroy, generateNow (POST — force WO), workOrderIndex (GET), workOrderShow (GET), updateChecklist (PATCH)
7. `AmcContractController` — index, store, show, update, destroy, renew (PATCH)
8. `MaintenanceReportController` — ticketSummary, sla, technician, assetHistory, pmCompliance
9. `MobileMaintenanceController` (Api/) — myTickets, ticketDetail, updateStatus (PATCH), addTimeLog (POST), uploadPhotos (POST), myPmWorkOrders, updateChecklist (PATCH), qrLookup (GET), quickCreate (POST)

#### Section 2 — Service Inventory (5 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events/notifications fired
- Other services called (dependency graph)

Include the ticket creation 10-step pseudocode for `TicketService::createTicket()` as documented in Phase 1 Section 8.

Include the SLA escalation pseudocode for `EscalationService::checkEscalations()`:
```
checkEscalations(Ticket $ticket): void
  Step 1: Load category.sla_escalation_json; if NULL → return
  Step 2: ticket_age_hours = now() − ticket.created_at (in hours)
  Step 3: If L2 defined AND ticket_age_hours > L2.after_hours AND ticket.escalation_level < 2:
           → Dispatch notification to L2.notify_role
           → Update ticket.escalation_level = 2
           → Log to sys_activity_logs (event=escalation, properties={level:2, after_hours: X})
           → Return (L2 subsumes L1)
  Step 4: If L1 defined AND ticket_age_hours > L1.after_hours AND ticket.escalation_level < 1:
           → Dispatch notification to L1.notify_role
           → Update ticket.escalation_level = 1
           → Log to sys_activity_logs (event=escalation, properties={level:1, after_hours: X})
```

Include the PM work order generation pseudocode for `PmScheduleService::generateWorkOrders()`:
```
generateWorkOrders(): int  // returns count of WOs created
  Step 1: $dueSchedules = PmSchedule::active()->where('next_due_date', '<=', today())->get()
  Step 2: foreach $schedule:
    Step 2a: Check for existing Pending/In_Progress WO (BR-MNT-006)
             → If exists: skip this schedule
    Step 2b: DB transaction begins
    Step 2c: AssignmentService::autoAssignPmWo($schedule) → User|null
    Step 2d: Create mnt_pm_work_orders (status=Pending, due_date=$schedule->next_due_date)
    Step 2e: Advance $schedule->next_due_date by recurrence interval
    Step 2f: DB transaction commits
    Step 2g: Notify assigned technician (or Maintenance Incharge if unassigned)
  Step 3: Return count of created WOs
```

#### Section 3 — FormRequest Inventory (11 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

11 total:
- `StoreAssetCategoryRequest` — name required unique mnt_asset_categories, code nullable unique max 20, default_priority valid enum, sla_hours integer min 1, auto_assign_role_id nullable exists sys_roles, priority_keywords_json nullable JSON
- `StoreAssetRequest` — name required max 150, category_id exists mnt_asset_categories, location_building nullable, purchase_date nullable date, purchase_cost nullable decimal, depreciation_method nullable enum (SLM/WDV), useful_life_years nullable integer 1–50 (required_if:depreciation_method,SLM), salvage_value nullable decimal (required_if:depreciation_method,SLM), depreciation_rate nullable decimal 0–100 (required_if:depreciation_method,WDV)
- `StoreTicketRequest` — title required max 200, category_id exists + is_active, description required min 20, location_building required, asset_id nullable exists mnt_assets
- `UpdateTicketStatusRequest` — status required valid enum, resolution_notes required_if:status,Resolved min 20 (BR-MNT-004), before_photos required_if:status,In_Progress (when school setting enabled), after_photos required_if:status,Resolved (when school setting enabled)
- `AssignTicketRequest` — user_id required exists sys_users, reason nullable string
- `OverridePriorityRequest` — priority required valid enum, override_reason required string min 10
- `StoreTimeLogRequest` — work_date required date, start_time required, end_time required after:start_time, parts_used nullable, parts_cost nullable decimal min 0
- `StorePmScheduleRequest` — asset_id exists mnt_assets, title required, recurrence valid enum, checklist_items_json required JSON array min 1 item, start_date required date, assign_to_role_id nullable exists sys_roles, estimated_hours nullable decimal min 0.5
- `StoreAmcContractRequest` — contract_title required, start_date required date, end_date required date after:start_date, contract_value decimal min 0, vendor_id nullable exists vnd_vendors
- `StoreWorkOrderRequest` — work_description required, scheduled_date required date, estimated_cost decimal min 0, vendor_id nullable exists vnd_vendors, ticket_id nullable exists mnt_tickets
- `StoreAssetDepreciationRequest` — financial_year required regex `/^\d{4}-\d{4}$/`, method required valid enum, opening_book_value required decimal min 0, depreciation_rate required decimal 0–100 (unique per asset_id + financial_year — BR-MNT-016)

#### Section 4 — Blade View Inventory (~35 views)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and screen counts (from req v2 Section 7 SCR-MNT-01 to SCR-MNT-25):
- Dashboard + Calendar: 2 views (SCR-MNT-01, SCR-MNT-02)
- Asset Categories: 2 views — list, form (SCR-MNT-03, SCR-MNT-04)
- Assets: 3 views — list, detail (with tabs: history/depreciation/cost), create/edit (SCR-MNT-05 to SCR-MNT-07)
- Tickets: 3 views — list, create, detail + status modal (SCR-MNT-08 to SCR-MNT-11)
- PM Schedules: 2 views — list, form (SCR-MNT-12, SCR-MNT-13)
- PM Work Orders: 2 views — list, detail with checklist (SCR-MNT-14, SCR-MNT-15)
- AMC Contracts: 2 views — list (expiry badge), form (SCR-MNT-16, SCR-MNT-17)
- Work Orders: 3 views — list, form, detail/PDF (SCR-MNT-18 to SCR-MNT-20)
- Reports: 5 views (SCR-MNT-21 to SCR-MNT-25)
- Shared partials: ~5 partials (pagination, status badge, priority badge, SLA breach highlight, ticket timeline)

For key screens document:
- Ticket Detail (SCR-MNT-10) — status timeline, assignment history, time logs tab, before/after photo tabs, rating widget (shown on Closed)
- PM Work Order Detail (SCR-MNT-15) — checklist table with completion checkboxes + notes per item; hours spent entry; all items checked → Completed button enabled
- Asset Detail (SCR-MNT-06) — Breakdown History tab (mnt_breakdown_history), PM History tab (mnt_pm_work_orders), Cost Summary tab (total_maintenance_cost breakdown), depreciation schedule modal

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by section (6.1 Web Routes, 6.2 Mobile API Routes). Count total routes at the end (target ~64).
- Web routes middleware: `['auth', 'verified', 'tenant', 'EnsureTenantHasModule:Maintenance']`
- Mobile API routes middleware: `['auth:sanctum', 'tenant', 'EnsureTenantHasModule:Maintenance']`

#### Section 6 — Implementation Phases (11 phases per req v2 Section 15.4)

For each phase, provide a detailed sprint plan:

**Phase 1 — Foundation: Migrations, Models, Seeders:**
Files: 12 migrations, 11 Models, Module service providers, MntAssetCategorySeeder, MntSeederRunner
Tests: model factory setup

**Phase 2 — Categories & Assets:**
FRs: MNT-01, MNT-02 (partial)
Files: AssetCategoryController (CRUD + keyword rules + escalation JSON), AssetController (CRUD + QR generation via SimpleSoftwareIO), FormRequests: StoreAssetCategoryRequest, StoreAssetRequest
Tests: AssetCategoryTest (keyword JSON stored + retrieved), AssetCreationTest (QR generated on save)

**Phase 3 — Ticketing Core:**
FRs: MNT-04, MNT-05
Files: TicketController (CRUD), TicketService (10-step createTicket — keyword priority + SLA calc + auto-assign), AssignmentService (score-based assignment), FormRequests: StoreTicketRequest, AssignTicketRequest
Tests: TicketCreationTest (keyword → priority), AutoAssignmentTest (workload score, fallback)

**Phase 4 — Ticket Lifecycle & SLA:**
FRs: MNT-06
Files: TicketController::updateStatus() + updatePriority() + storeTimeLog(), UpdateTicketStatusRequest, OverridePriorityRequest, StoreTimeLogRequest, Jobs: CheckSlaBreachesJob (every 30 min)
Tests: TicketStatusTransitionTest (valid/invalid transitions), SlaBreachTest (is_sla_breached flag), ResolutionNotesTest

**Phase 5 — Dashboard, Escalation, Breakdown History:**
FRs: MNT-06 (escalation), MNT-11 (dashboard KPIs)
Files: MaintenanceController (dashboard KPIs + calendar data), EscalationService, mnt_breakdown_history auto-insert hook in TicketService
Tests: SlaEscalationTest (L1/L2 escalation_level flags), BreakdownHistoryTest (auto-insert on Resolved)

**Phase 6 — PM Schedules & Work Orders:**
FRs: MNT-07
Files: PmScheduleController (full + generateNow), PmScheduleService (generateWorkOrders + completeWorkOrder), MarkOverduePmWorkOrdersJob, FormRequests: StorePmScheduleRequest
Tests: PmWorkOrderGenerationTest, PmWorkOrderDuplicateTest, PmChecklistCompletionTest

**Phase 7 — AMC Contracts:**
FRs: MNT-08
Files: AmcContractController (full + renew), SendAmcExpiryAlertsJob, FormRequests: StoreAmcContractRequest
Tests: AmcExpiryAlertTest (fires once per threshold, renewal_alert_sent flags)

**Phase 8 — External Work Orders:**
FRs: MNT-09
Files: WorkOrderController (full + DomPDF pdf()), StoreWorkOrderRequest, asset.total_maintenance_cost recalculation on WO completion (BR-MNT-012)
Tests: WorkOrderCostTest (cost rollup to asset total)

**Phase 9 — Asset Depreciation:**
FRs: MNT-03
Files: AssetController::depreciation() + storeDepreciation(), DepreciationService (calculateSLM + calculateWDV), StoreAssetDepreciationRequest
Tests: AssetDepreciationTest (SLM formula, WDV formula, duplicate year blocked)

**Phase 10 — Reports & Calendar:**
FRs: MNT-10, MNT-11
Files: MaintenanceReportController (5 reports + CSV exports), MaintenanceController::calendar() (JSON endpoint for calendar events), all 5 report views, calendar view with JS calendar library
Tests: CertificateReportTest (report data structure, CSV export)

**Phase 11 — Mobile API:**
FRs: MNT-04, MNT-06, MNT-07 (mobile surfaces)
Files: MobileMaintenanceController (9 endpoints), mobile-optimised blade views (if needed)
Tests: MobileApiTest (ticket status update, checklist update, QR lookup, quick create)

#### Section 7 — Seeder Execution Order

```
php artisan module:seed Maintenance --class=MntSeederRunner
  ↓ MntAssetCategorySeeder    (no dependencies — seeds 9 categories with keyword JSON)
```

For test runs: use `MntAssetCategorySeeder` as minimum (needed for all ticket + assignment tests).

Artisan scheduled commands (register in `routes/console.php`):
```
GeneratePmWorkOrdersJob::dispatch()     → daily at 06:00
CheckSlaBreachesJob::dispatch()         → every 30 minutes
SendAmcExpiryAlertsJob::dispatch()      → daily at 08:00
MarkOverduePmWorkOrdersJob::dispatch()  → daily at 07:00
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// Queue::fake() for all 4 job tests
// Notification::fake() for assignment/SLA/AMC alert tests
// Storage::fake() for QR code + before/after photo tests
// Carbon::setTestNow() for SLA breach and AMC expiry date tests
```

**Minimum Test Coverage Targets:**
- BR-MNT-001 (ticket number lock-for-update): concurrent creation produces unique numbers
- BR-MNT-003 (state machine): all valid transitions succeed; invalid transitions return 422
- BR-MNT-004 (resolution_notes mandatory): missing notes on Resolved → 422
- BR-MNT-006 (PM WO duplicate): second WO not created when Pending WO exists
- BR-MNT-007 (AMC alerts once per threshold): `renewal_alert_sent_30` flag prevents double-fire
- BR-MNT-008 (technician auth): technician cannot update ticket assigned to another → 403
- BR-MNT-011 (escalation level): L1 notification after L1.after_hours; escalation_level=1 set
- BR-MNT-014 (breakdown history): ticket with asset_id resolved → mnt_breakdown_history inserted
- BR-MNT-016 (depreciation unique): duplicate year raises validation error

**Feature Test File Summary (from req v2 Section 12 T1–T20):**
List all 11 feature test files with file path, test count, and mapping to T1–T20 scenarios.

**Unit Test File Summary:**
List 3 unit test files: AssetDepreciationTest (SLM + WDV formulas), KeywordPriorityTest (case-insensitive scan), SlaCalculationTest (timezone-aware sla_due_at).

**Factory Requirements:**
```
AssetCategoryFactory   — generates category with priority_keywords_json, sla_hours
AssetFactory           — generates asset with asset_code, category_id, current_condition
TicketFactory          — generates ticket_number (MNT-YYYY-NNN), status=Open, priority
PmScheduleFactory      — generates schedule with checklist_items_json array, recurrence, next_due_date
PmWorkOrderFactory     — generates WO linked to pm_schedule, status=Pending
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `MNT_Dev_Plan.md` | `{OUTPUT_DIR}/MNT_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 9 controllers listed with all methods
- [ ] All 5 services listed with at minimum 3 key method signatures each
- [ ] TicketService::createTicket() 10-step pseudocode present
- [ ] EscalationService::checkEscalations() pseudocode present
- [ ] PmScheduleService::generateWorkOrders() pseudocode present
- [ ] All 11 FormRequests listed with their key validation rules
- [ ] All 11 FRs (MNT-01 to MNT-11) appear in at least one implementation phase
- [ ] All 11 implementation phases have: FRs covered, files to create, test count
- [ ] All 4 Artisan scheduled jobs listed with their schedule (06:00, every 30 min, 08:00, 07:00)
- [ ] Route list consolidated with middleware and FR reference (~64 routes total)
- [ ] Mobile API routes explicitly marked with `auth:sanctum` middleware
- [ ] View count per sub-module totals approximately 35
- [ ] Test strategy includes Queue::fake() for all 4 jobs
- [ ] Test strategy includes Carbon::setTestNow() for SLA breach + AMC expiry date tests
- [ ] BR-MNT-003 (invalid transition → 422) test explicitly referenced
- [ ] BR-MNT-007 (AMC alert idempotency) test explicitly referenced
- [ ] `mnt_tickets` has NO delete route (soft delete only; tickets are always retained)

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `MNT_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/MNT_FeatureSpec.md`
2. `{OUTPUT_DIR}/MNT_DDL_v1.sql` + Migration + 2 Seeders
3. `{OUTPUT_DIR}/MNT_Dev_Plan.md`
Development lifecycle for MNT (Maintenance) module is ready to begin."

---

## QUICK REFERENCE — MNT Module Tables vs Controllers vs Services

| Domain | mnt_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Asset Categories | mnt_asset_categories | AssetCategoryController | — (direct in controller) |
| Asset Register | mnt_assets | AssetController | DepreciationService (QR in AssetController) |
| Depreciation | mnt_asset_depreciation | AssetController (depreciation routes) | DepreciationService |
| Tickets | mnt_tickets, mnt_ticket_assignments, mnt_ticket_time_logs | TicketController | TicketService, AssignmentService, EscalationService |
| Breakdown History | mnt_breakdown_history | (no direct routes — auto-populated) | TicketService (post-hook) |
| PM Schedules & WOs | mnt_pm_schedules, mnt_pm_work_orders | PmScheduleController | PmScheduleService |
| AMC Contracts | mnt_amc_contracts | AmcContractController | — (direct in controller + Job) |
| Work Orders | mnt_work_orders | WorkOrderController | — (direct in controller) |
| Reports + Calendar | (reads all mnt_* tables) | MaintenanceReportController, MaintenanceController | — (direct queries) |
| Mobile API | (reads/writes mnt_tickets + mnt_pm_work_orders) | MobileMaintenanceController | TicketService, PmScheduleService |
