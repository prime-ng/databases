# MNT — Maintenance Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY

---

## 1. Executive Summary

The Maintenance Management module provides a structured, digitised facility maintenance system for Indian K-12 schools on the Prime-AI platform. It replaces informal verbal/WhatsApp-based reporting with a ticketed helpdesk, auto-assignment routing, SLA enforcement, preventive maintenance scheduling, AMC contract tracking, and management-level reporting.

V2 expands on V1 by adding QR-code scan-to-report for assets, mobile-optimised field-staff views, spare-parts cost linkage to INV module, asset depreciation tracking, escalation rules for overdue work orders, and a maintenance calendar view. All features are greenfield (📐 Proposed) since no code exists.

**V1 → V2 key additions:** QR codes on assets, depreciation tracking, breakdown history table, SLA escalation levels, mobile API for field staff, maintenance calendar, and integration scaffolding for INV (spare parts) and FAC (cost posting).

---

## 2. Module Overview

### 2.1 Business Context

| Attribute | Value |
|---|---|
| Module Code | MNT |
| Module Name | Maintenance Management |
| Laravel Module Path | `Modules/Maintenance` |
| Table Prefix | `mnt_` |
| Database | tenant_db (per-school) |
| RBS Reference | Module Y — Maintenance & Facility Helpdesk (F.Y1.1, F.Y1.2, F.Y2.1) |
| Priority | P4 |
| Complexity | Medium |
| Implementation Status | 0% — Greenfield |

### 2.2 Feature Summary

| Feature Area | RBS Ref | Priority | Status |
|---|---|---|---|
| Asset Category Management | F.Y1.1 | Critical | 📐 Proposed |
| Asset Register with QR Code | Beyond RBS | High | 📐 Proposed |
| Asset Depreciation Tracking | Beyond RBS | Medium | 📐 Proposed |
| Maintenance Ticket Creation | ST.Y1.1.1.1-2 | Critical | 📐 Proposed |
| Auto Priority via Keywords | ST.Y1.1.2.1 | Critical | 📐 Proposed |
| Manual Priority Override | ST.Y1.1.2.2 | High | 📐 Proposed |
| Technician Auto-Assignment | ST.Y1.2.1.1 | Critical | 📐 Proposed |
| Assignment Notifications | ST.Y1.2.1.2 | High | 📐 Proposed |
| Ticket Status Lifecycle | ST.Y1.2.2.1 | Critical | 📐 Proposed |
| Time & Parts Logging | ST.Y1.2.2.2 | High | 📐 Proposed |
| Before/After Photo Evidence | ST.Y1.2.2.2 | High | 📐 Proposed |
| SLA Tracking & Breach Alerts | Beyond RBS | High | 📐 Proposed |
| SLA Escalation Levels | 🆕 New in V2 | High | 📐 Proposed |
| Preventive Maintenance Schedules | ST.Y2.1.1.1-2 | High | 📐 Proposed |
| PM Work Order Auto-Generation | ST.Y2.1.2.1-2 | High | 📐 Proposed |
| AMC Contract Management | Beyond RBS | High | 📐 Proposed |
| External Vendor Work Orders | Beyond RBS | Medium | 📐 Proposed |
| QR Code Scan-to-Report | 🆕 New in V2 | Medium | 📐 Proposed |
| Breakdown History per Asset | 🆕 New in V2 | Medium | 📐 Proposed |
| Maintenance Cost per Asset | 🆕 New in V2 | Medium | 📐 Proposed |
| Spare Parts INV Integration | 🆕 New in V2 | Medium | 📐 Proposed |
| Mobile Field-Staff Interface | 🆕 New in V2 | High | 📐 Proposed |
| Maintenance Calendar View | 🆕 New in V2 | Medium | 📐 Proposed |
| Dashboard KPIs & Reports | Beyond RBS | Medium | 📐 Proposed |

### 2.3 Menu Navigation

```
School Admin Panel
└── Maintenance [/maintenance]
    ├── Dashboard              [/maintenance/dashboard]
    ├── Setup
    │   ├── Asset Categories   [/maintenance/asset-categories]
    │   └── Assets             [/maintenance/assets]
    ├── Tickets
    │   ├── Raise Ticket       [/maintenance/tickets/create]
    │   ├── All Tickets        [/maintenance/tickets]
    │   └── My Tickets         [/maintenance/tickets?filter=mine]
    ├── Work Orders            [/maintenance/work-orders]
    ├── Preventive Maintenance
    │   ├── PM Schedules       [/maintenance/pm-schedules]
    │   └── PM Work Orders     [/maintenance/pm-work-orders]
    ├── AMC Contracts          [/maintenance/amc-contracts]
    ├── Calendar               [/maintenance/calendar]
    └── Reports
        ├── Ticket Summary     [/maintenance/reports/ticket-summary]
        ├── SLA Report         [/maintenance/reports/sla]
        ├── Asset History      [/maintenance/reports/asset-history]
        ├── PM Compliance      [/maintenance/reports/pm-compliance]
        └── Technician Report  [/maintenance/reports/technician]
```

### 2.4 Module Architecture

```
Modules/Maintenance/
├── app/
│   ├── Http/Controllers/
│   │   ├── MaintenanceController.php        # Dashboard + calendar
│   │   ├── AssetCategoryController.php      # Category CRUD + keyword rules
│   │   ├── AssetController.php              # Asset CRUD + QR + depreciation
│   │   ├── TicketController.php             # Ticket lifecycle
│   │   ├── WorkOrderController.php          # External vendor work orders
│   │   ├── PmScheduleController.php         # PM schedules + checklists
│   │   ├── AmcContractController.php        # AMC contracts
│   │   └── MaintenanceReportController.php  # All reports
│   ├── Http/Controllers/Api/
│   │   └── MobileMaintenanceController.php  # Mobile API for field staff
│   ├── Models/
│   │   ├── AssetCategory.php, Asset.php, AssetDepreciation.php
│   │   ├── Ticket.php, TicketAssignment.php, TicketTimeLog.php
│   │   ├── BreakdownHistory.php, WorkOrder.php
│   │   ├── PmSchedule.php, PmWorkOrder.php, AmcContract.php
│   ├── Services/
│   │   ├── TicketService.php           # Priority, auto-assign, transitions
│   │   ├── AssignmentService.php       # Workload + skill matching
│   │   ├── PmScheduleService.php       # PM work order generation
│   │   ├── EscalationService.php       # 🆕 SLA escalation levels
│   │   └── DepreciationService.php     # 🆕 Asset depreciation calc
│   ├── Jobs/
│   │   ├── GeneratePmWorkOrdersJob.php
│   │   ├── CheckSlaBreachesJob.php
│   │   └── SendAmcExpiryAlertsJob.php
│   └── Policies/ (11 policies)
├── database/migrations/ (12 migrations)
├── resources/views/maintenance/
└── routes/ (web.php + api.php)
```

---

## 3. Stakeholders & Roles

| Actor | Permissions in MNT |
|---|---|
| School Admin | Full access — all CRUD, reports, settings, AMC, work orders |
| Principal | View all tickets and reports; approve high-priority escalations |
| Admin/Office Staff | Raise tickets, assign work orders, view all tickets |
| Teacher | Raise tickets for own classroom/equipment |
| Student | Raise tickets for common areas via portal (limited fields) |
| Maintenance Incharge | Manage all tickets, assign technicians, PM schedules, AMC |
| Technician (Internal) | Accept/update/resolve tickets assigned to them; complete PM work orders |
| Vendor/Contractor | Referenced on AMC contracts and external work orders (no login) |
| System | Auto-assign priority, generate PM work orders, send SLA/AMC alerts |

---

## 4. Functional Requirements

---

### FR-MNT-01: Asset Category Management
**RBS Ref:** F.Y1.1 | **Priority:** Critical | **Status:** 📐 Proposed | **Tables:** `mnt_asset_categories`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-01.1 | Create/edit/delete asset categories | name (unique, max 100), code, default_priority ENUM, sla_hours (default resolution time) |
| REQ-MNT-01.2 | Auto-assign role per category | auto_assign_role_id FK→sys_roles; tickets in this category auto-routed to this role |
| REQ-MNT-01.3 | Priority keyword rules (JSON) | priority_keywords_json: `{"Critical":["flood","fire"],"High":["leakage","short circuit"]}` |
| REQ-MNT-01.4 | SLA escalation levels (🆕 V2) | sla_escalation_json: `{"L1":{"after_hours":4,"notify_role":"maintenance-incharge"},"L2":{"after_hours":8,"notify_role":"principal"}}` |
| REQ-MNT-01.5 | Soft delete + restore | Deleted categories cannot be assigned to new tickets; existing tickets retain category |

**Acceptance Criteria:**
- [ ] ST.Y1.1.1.1 — Electrical, Plumbing, IT, Carpenter, Cleaning, HVAC, Fire Safety categories available as seeds
- [ ] Keyword-based priority escalation fires correctly on ticket creation
- [ ] Deleting a category with active tickets is blocked with validation error

---

### FR-MNT-02: Asset Register
**Priority:** High | **Status:** 📐 Proposed | **Tables:** `mnt_assets`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-02.1 | Create asset with location | name, category_id, location_building/floor/room, purchase_date, purchase_cost, warranty_expiry_date, current_condition ENUM |
| REQ-MNT-02.2 | Auto-generate asset code | Format: MNT-AST-XXXXXX (sequential, lock-for-update) |
| REQ-MNT-02.3 | QR code generation (🆕 V2) | On save, generate QR code embedding `/maintenance/tickets/create?asset_id={id}`; store as sys_media; printable label view |
| REQ-MNT-02.4 | QR code scan-to-report (🆕 V2) | Mobile user scans QR → redirected to ticket create form with asset pre-filled; works without login if configured |
| REQ-MNT-02.5 | Asset condition tracking | current_condition updated on PM work order completion and manual override |
| REQ-MNT-02.6 | Breakdown history view (🆕 V2) | Per-asset view showing all tickets, PM work orders, and work orders chronologically with total cost |
| REQ-MNT-02.7 | Photo attachment | Asset photo stored via sys_media |

**Acceptance Criteria:**
- [ ] QR code image generated and downloadable for each asset
- [ ] Scanning QR on mobile opens ticket creation pre-filled with asset details
- [ ] Asset maintenance cost total visible on asset show page

---

### FR-MNT-03: Asset Depreciation Tracking (🆕 New in V2)
**Priority:** Medium | **Status:** 📐 Proposed | **Tables:** `mnt_asset_depreciation`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-03.1 | Define depreciation method | Per asset: Straight Line (SLM) or Written Down Value (WDV); useful_life_years, salvage_value |
| REQ-MNT-03.2 | Annual depreciation calculation | DepreciationService calculates yearly charge; records in mnt_asset_depreciation |
| REQ-MNT-03.3 | Current book value display | book_value = purchase_cost − accumulated_depreciation; shown on asset record |
| REQ-MNT-03.4 | FAC module integration scaffold | Depreciation entries can be posted to FAC journal (future hook) |

**Acceptance Criteria:**
- [ ] SLM: annual charge = (purchase_cost − salvage_value) / useful_life_years
- [ ] WDV: annual charge = book_value × depreciation_rate%
- [ ] Accumulated depreciation and current book value visible on asset detail page

---

### FR-MNT-04: Maintenance Ticket Creation
**RBS Ref:** T.Y1.1.1 | **Priority:** Critical | **Status:** 📐 Proposed | **Tables:** `mnt_tickets`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-04.1 | Staff/student raises ticket | title (max 200), category_id, asset_id (optional), description (min 20 chars), location_building (required), floor, room, up to 5 photos |
| REQ-MNT-04.2 | Auto ticket number | MNT-YYYY-XXXXXXXX; sequential with DB lock-for-update |
| REQ-MNT-04.3 | SLA due time set on creation | sla_due_at = created_at + category.sla_hours |
| REQ-MNT-04.4 | Auto priority from keywords | TicketService scans description against category.priority_keywords_json; Critical > High > Medium > Low; fall back to category.default_priority |
| REQ-MNT-04.5 | Manual priority override | Admin/Maintenance Incharge can override; override reason logged; re-triggers assignment if escalated to Critical |
| REQ-MNT-04.6 | QR-prefilled creation (🆕 V2) | GET /maintenance/tickets/create?asset_id=X pre-fills asset and location from asset record |

**Acceptance Criteria:**
- [ ] ST.Y1.1.1.1 — Staff/student selects category; description and location entered
- [ ] ST.Y1.1.1.2 — Photos uploadable; location (Room/Building) specified
- [ ] ST.Y1.1.2.1 — "water leakage" → priority auto-set to High
- [ ] ST.Y1.1.2.2 — Admin can manually override priority with reason

---

### FR-MNT-05: Technician Assignment
**RBS Ref:** T.Y1.2.1 | **Priority:** Critical | **Status:** 📐 Proposed | **Tables:** `mnt_ticket_assignments`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-05.1 | Auto-assignment on ticket creation | AssignmentService: filter sys_users by category.auto_assign_role_id; exclude unavailable; score by open_ticket_count ASC + location match bonus; assign top scorer |
| REQ-MNT-05.2 | Unassigned fallback | If no technician available, ticket stays Open; Maintenance Incharge notified for manual assignment |
| REQ-MNT-05.3 | Manual assignment/reassignment | Maintenance Incharge assigns/reassigns; previous assignment record marked Reassigned; reason logged |
| REQ-MNT-05.4 | Assignment notification | Push notification: "New ticket: [Title] — [Location] — Priority: [Level]" via Notification module |

**Acceptance Criteria:**
- [ ] ST.Y1.2.1.1 — Auto-assign picks technician with lowest open-ticket count in matching role
- [ ] ST.Y1.2.1.2 — Push notification dispatched to assigned technician

---

### FR-MNT-06: Ticket Status Lifecycle & SLA
**RBS Ref:** T.Y1.2.2 | **Priority:** Critical | **Status:** 📐 Proposed | **Tables:** `mnt_tickets`, `mnt_ticket_time_logs`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-06.1 | Ticket status state machine | Open → Accepted → In_Progress → (On_Hold ↔ In_Progress) → Resolved → Closed; Cancelled allowed from any pre-Resolved state by admin |
| REQ-MNT-06.2 | Resolution notes required | PUT /status with status=Resolved must include resolution_notes; 422 if missing |
| REQ-MNT-06.3 | Before/after photo enforcement | before photos required on In_Progress transition; after photos required on Resolved (configurable sys_school_settings) |
| REQ-MNT-06.4 | Time & parts logging | Technician logs work_date, start_time, end_time, hours_spent, work_description, parts_used (free-text), parts_cost; updates ticket totals |
| REQ-MNT-06.5 | SLA breach detection | Scheduled job (CheckSlaBreachesJob) runs every 30 min; sets is_sla_breached=1 when sla_due_at < NOW and status not Resolved/Closed |
| REQ-MNT-06.6 | SLA escalation levels (🆕 V2) | EscalationService checks category.sla_escalation_json; fires escalation notifications at L1/L2 thresholds; logs to sys_activity_logs |
| REQ-MNT-06.7 | Requester rating on closure | On Closed, requester receives in-app prompt for 1–5 star rating + feedback |
| REQ-MNT-06.8 | Requester notification on resolved | System notifies ticket requester when status changes to Resolved |

**Acceptance Criteria:**
- [ ] ST.Y1.2.2.1 — Technician can update: Accepted, In_Progress, On_Hold, Resolved
- [ ] ST.Y1.2.2.2 — Time spent, parts used, resolution notes, and photos logged
- [ ] Invalid state transitions return 422 with descriptive error
- [ ] SLA breach sets is_sla_breached=1 within 30 minutes of threshold crossing

---

### FR-MNT-07: Preventive Maintenance Schedules
**RBS Ref:** F.Y2.1, T.Y2.1.1 | **Priority:** High | **Status:** 📐 Proposed | **Tables:** `mnt_pm_schedules`, `mnt_pm_work_orders`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-07.1 | Create PM schedule for asset | asset_id, title, description, checklist_items_json (array of task strings, min 1), recurrence ENUM (Daily/Weekly/Monthly/Quarterly/Yearly), recurrence_day, start_date, assign_to_role_id, estimated_hours |
| REQ-MNT-07.2 | Calculate next_due_date | On save: next_due_date = start_date; on WO generation: advance by recurrence interval |
| REQ-MNT-07.3 | PM work order auto-generation | GeneratePmWorkOrdersJob (daily): query active schedules WHERE next_due_date <= today AND no pending WO exists; create mnt_pm_work_orders; auto-assign technician by role; notify |
| REQ-MNT-07.4 | Only one pending WO per schedule | BR-MNT-006: if a Pending/In_Progress WO already exists for a schedule, skip generation |
| REQ-MNT-07.5 | PM WO checklist completion | Technician marks each checklist item as completed with optional notes; when all complete → status=Completed; updates asset.last_pm_date and current_condition |
| REQ-MNT-07.6 | Overdue PM WO marking | CheckSlaBreachesJob also marks PM WOs as Overdue if due_date < today and not Completed |

**Acceptance Criteria:**
- [ ] ST.Y2.1.1.1 — PM checklist for generator, fire extinguisher, AC created with recurrence
- [ ] ST.Y2.1.1.2 — Recurrence options: Daily, Weekly, Monthly, Quarterly, Yearly
- [ ] ST.Y2.1.2.1 — Work orders auto-generated daily when due_date reached
- [ ] ST.Y2.1.2.2 — Work orders assigned; checklist completion tracked; asset health updated

---

### FR-MNT-08: AMC Contract Management
**Priority:** High | **Status:** 📐 Proposed | **Tables:** `mnt_amc_contracts`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-08.1 | Create AMC contract | vendor_id (FK vnd_vendors or free-text), contract_title, scope_description, covered_assets_ids_json, start_date, end_date, contract_value, payment_frequency, visit_frequency, vendor_contact, contract document upload |
| REQ-MNT-08.2 | AMC expiry alerts | SendAmcExpiryAlertsJob (daily): alert at 60, 30, and 7 days before end_date; each fires once (tracked via renewal_alert_sent_* flags); dispatch to Maintenance Incharge role |
| REQ-MNT-08.3 | AMC status management | status ENUM: Active/Expired/Cancelled/Pending_Renewal; auto-set to Expired when end_date < today |
| REQ-MNT-08.4 | Asset linkage | AMC covered_assets_ids_json links to mnt_assets; asset.amc_contract_id updated on contract creation |

**Acceptance Criteria:**
- [ ] Expiry alert notification fired exactly once at 60, 30, and 7 days
- [ ] Status auto-transitions to Expired after end_date
- [ ] Covered assets shown on AMC detail with link to asset records

---

### FR-MNT-09: External Vendor Work Orders
**Priority:** Medium | **Status:** 📐 Proposed | **Tables:** `mnt_work_orders`

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-09.1 | Create work order | wo_number (MNT-WO-XXXXXX), optional ticket_id source, optional amc_contract_id, vendor_id/name, work_description, scheduled_date, estimated_cost, purchase_order_number |
| REQ-MNT-09.2 | WO status lifecycle | Draft → Issued → In_Progress → Completed / Cancelled |
| REQ-MNT-09.3 | Actual cost capture | On completion, enter actual_cost and completed_date |
| REQ-MNT-09.4 | FAC cost posting scaffold (🆕 V2) | On WO completion, generate cost entry hook for FAC module (debit Maintenance Expense) |
| REQ-MNT-09.5 | PDF work order print | DomPDF: work order PDF with school header, vendor details, scope, cost, PO number |

**Acceptance Criteria:**
- [ ] WO linked to originating ticket shows ticket number
- [ ] WO cost rolled up to asset maintenance cost total
- [ ] PDF printable from WO detail page

---

### FR-MNT-10: Maintenance Calendar (🆕 New in V2)
**Priority:** Medium | **Status:** 📐 Proposed

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-10.1 | Monthly calendar view | Calendar showing PM WO due dates, vendor WO scheduled dates, AMC visit dates as colour-coded events |
| REQ-MNT-10.2 | Filter by type | Filter: Preventive / Corrective / Vendor / All |
| REQ-MNT-10.3 | Click through | Click on calendar event opens PM WO / WO detail |

---

### FR-MNT-11: Dashboard & Reports
**Priority:** Medium | **Status:** 📐 Proposed

| Req ID | Description | Key Detail |
|---|---|---|
| REQ-MNT-11.1 | Dashboard KPIs | Open tickets by priority, SLA breached count, tickets resolved today, PM WOs due this week, AMC expiring in 60 days, technician workload chart |
| REQ-MNT-11.2 | Ticket summary report | Date-range counts by category, priority, status; exportable to CSV |
| REQ-MNT-11.3 | SLA performance report | % tickets resolved within SLA; avg resolution time; breach breakdown by category |
| REQ-MNT-11.4 | Technician productivity report | Per technician: assigned, resolved, avg resolution time, hours logged |
| REQ-MNT-11.5 | Asset maintenance history (🆕 V2) | Per asset: all tickets, PM WOs, vendor WOs, total maintenance cost, breakdown frequency |
| REQ-MNT-11.6 | PM compliance report | PM WOs: scheduled vs completed vs overdue per asset per period |

---

## 5. Data Model

### 5.1 New Tables (`mnt_*` prefix)

> All tables: standard audit columns `id PK AUTO_INCREMENT`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK→sys_users`, `created_at TIMESTAMP`, `updated_at TIMESTAMP`, `deleted_at TIMESTAMP NULL` (where applicable).

| Table | Status | Description | Key Columns |
|---|---|---|---|
| `mnt_asset_categories` | 📐 New | Maintenance categories (Electrical, Plumbing, IT…) | name, code, default_priority, sla_hours, auto_assign_role_id, priority_keywords_json, sla_escalation_json |
| `mnt_assets` | 📐 New | School asset register | asset_code, name, category_id, location_*, purchase_cost, warranty_expiry_date, current_condition, last_pm_date, amc_contract_id, qr_code_media_id |
| `mnt_asset_depreciation` | 📐 New (🆕 V2) | Annual depreciation records per asset | asset_id, financial_year, method (SLM/WDV), opening_book_value, depreciation_rate, annual_charge, closing_book_value, posted_to_fac |
| `mnt_tickets` | 📐 New | Corrective maintenance tickets | ticket_number, title, category_id, asset_id, priority, priority_source, status, requester_user_id, assigned_to_user_id, sla_due_at, is_sla_breached, total_hours_logged, total_parts_cost, requester_rating |
| `mnt_ticket_assignments` | 📐 New | Assignment history per ticket | ticket_id, assigned_to_user_id, assigned_by_user_id, assignment_type, is_current, assigned_at, released_at |
| `mnt_ticket_time_logs` | 📐 New | Time and parts logging per ticket | ticket_id, logged_by_user_id, work_date, start_time, end_time, hours_spent, parts_used, parts_cost |
| `mnt_breakdown_history` | 📐 New (🆕 V2) | Denormalised breakdown log per asset | asset_id, ticket_id, breakdown_date, resolved_date, downtime_hours, root_cause, cost_incurred |
| `mnt_pm_schedules` | 📐 New | Preventive maintenance schedules | asset_id, title, recurrence, recurrence_day, checklist_items_json, start_date, next_due_date, assign_to_role_id, estimated_hours, category_id |
| `mnt_pm_work_orders` | 📐 New | Auto-generated PM work orders | pm_schedule_id, asset_id, wo_number, due_date, assigned_to_user_id, status, checklist_completion_json, completed_at, hours_spent |
| `mnt_amc_contracts` | 📐 New | Annual Maintenance Contracts with vendors | contract_number, contract_title, vendor_id, covered_assets_ids_json, start_date, end_date, contract_value, payment_frequency, visit_frequency, status, renewal_alert_sent_* |
| `mnt_work_orders` | 📐 New | External vendor work orders | wo_number, ticket_id, amc_contract_id, vendor_id, work_description, scheduled_date, estimated_cost, actual_cost, purchase_order_number, status |

### 5.2 Table Detail — `mnt_asset_categories`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL UNIQUE | |
| code | VARCHAR(20) | UNIQUE NULL | |
| description | TEXT | NULL | |
| default_priority | ENUM('Low','Medium','High','Critical') | DEFAULT 'Medium' | |
| sla_hours | SMALLINT UNSIGNED | DEFAULT 24 | Target resolution hours |
| auto_assign_role_id | INT UNSIGNED | NULL FK→sys_roles | |
| priority_keywords_json | JSON | NULL | `{"High":["leakage"],"Critical":["flood"]}` |
| sla_escalation_json | JSON | NULL | 🆕 `{"L1":{"after_hours":4,"notify":"mnt-incharge"},"L2":{"after_hours":8,"notify":"principal"}}` |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

### 5.3 Table Detail — `mnt_assets`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| asset_code | VARCHAR(30) | NOT NULL UNIQUE | MNT-AST-XXXXXX |
| name | VARCHAR(150) | NOT NULL | |
| category_id | INT UNSIGNED | NOT NULL FK→mnt_asset_categories | |
| location_building | VARCHAR(100) | NULL | |
| location_floor | VARCHAR(20) | NULL | |
| location_room | VARCHAR(50) | NULL | |
| purchase_date | DATE | NULL | |
| purchase_cost | DECIMAL(12,2) | NULL | |
| salvage_value | DECIMAL(12,2) | NULL | 🆕 For depreciation |
| useful_life_years | TINYINT UNSIGNED | NULL | 🆕 For depreciation |
| depreciation_method | ENUM('SLM','WDV') | NULL | 🆕 |
| depreciation_rate | DECIMAL(5,2) | NULL | 🆕 % for WDV |
| accumulated_depreciation | DECIMAL(12,2) | DEFAULT 0.00 | 🆕 |
| current_book_value | DECIMAL(12,2) | NULL | 🆕 Generated/updated |
| warranty_expiry_date | DATE | NULL | |
| current_condition | ENUM('Good','Fair','Poor','Critical','Decommissioned') | DEFAULT 'Good' | |
| last_pm_date | DATE | NULL | |
| next_pm_due_date | DATE | NULL | |
| amc_contract_id | INT UNSIGNED | NULL FK→mnt_amc_contracts | |
| total_maintenance_cost | DECIMAL(12,2) | DEFAULT 0.00 | 🆕 Accumulated from tickets + WOs |
| qr_code_media_id | INT UNSIGNED | NULL FK→sys_media | 🆕 |
| photo_media_id | INT UNSIGNED | NULL FK→sys_media | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by / created_at / updated_at / deleted_at | — | — | Standard audit |

### 5.4 Table Detail — `mnt_tickets`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| ticket_number | VARCHAR(30) | NOT NULL UNIQUE | MNT-YYYY-XXXXXXXX |
| title | VARCHAR(200) | NOT NULL | |
| category_id | INT UNSIGNED | NOT NULL FK→mnt_asset_categories | |
| asset_id | INT UNSIGNED | NULL FK→mnt_assets | |
| description | TEXT | NOT NULL | |
| location_building | VARCHAR(100) | NOT NULL | |
| location_floor | VARCHAR(20) | NULL | |
| location_room | VARCHAR(50) | NULL | |
| priority | ENUM('Low','Medium','High','Critical') | NOT NULL | |
| priority_source | ENUM('Auto_Keyword','Auto_Category','Manual_Override') | DEFAULT 'Auto_Category' | |
| status | ENUM('Open','Accepted','In_Progress','On_Hold','Resolved','Closed','Cancelled') | DEFAULT 'Open' | |
| requester_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| assigned_to_user_id | INT UNSIGNED | NULL FK→sys_users | |
| requested_date | DATE | NOT NULL | |
| accepted_at | TIMESTAMP | NULL | |
| resolved_at | TIMESTAMP | NULL | |
| closed_at | TIMESTAMP | NULL | |
| sla_due_at | TIMESTAMP | NULL | requested_date + sla_hours |
| is_sla_breached | TINYINT(1) | DEFAULT 0 | |
| escalation_level | TINYINT UNSIGNED | DEFAULT 0 | 🆕 0=none, 1=L1, 2=L2 |
| resolution_notes | TEXT | NULL | |
| total_hours_logged | DECIMAL(6,2) | DEFAULT 0.00 | |
| total_parts_cost | DECIMAL(10,2) | DEFAULT 0.00 | |
| requester_rating | TINYINT UNSIGNED | NULL | 1–5 stars |
| requester_feedback | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by / created_at / updated_at / deleted_at | — | — | |

**Indexes:** `(status, priority)`, `(assigned_to_user_id, status)`, `(category_id, status)`, `(sla_due_at)`, `(is_sla_breached, status)`

### 5.5 Table Detail — `mnt_asset_depreciation` (🆕 V2)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| asset_id | INT UNSIGNED | NOT NULL FK→mnt_assets | |
| financial_year | VARCHAR(9) | NOT NULL | e.g., `2025-2026` |
| method | ENUM('SLM','WDV') | NOT NULL | |
| opening_book_value | DECIMAL(12,2) | NOT NULL | |
| depreciation_rate | DECIMAL(5,2) | NOT NULL | % |
| annual_charge | DECIMAL(12,2) | NOT NULL | |
| closing_book_value | DECIMAL(12,2) | NOT NULL | |
| posted_to_fac | TINYINT(1) | DEFAULT 0 | |
| fac_journal_id | INT UNSIGNED | NULL | FK→acc_journal_entries (future) |
| created_at / updated_at | TIMESTAMP | | |
| UNIQUE | (asset_id, financial_year) | | |

### 5.6 Table Detail — `mnt_breakdown_history` (🆕 V2)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| asset_id | INT UNSIGNED | NOT NULL FK→mnt_assets | |
| ticket_id | INT UNSIGNED | NULL FK→mnt_tickets | Source corrective ticket |
| breakdown_date | DATE | NOT NULL | |
| resolved_date | DATE | NULL | |
| downtime_hours | DECIMAL(6,2) | NULL | |
| root_cause | TEXT | NULL | |
| cost_incurred | DECIMAL(10,2) | DEFAULT 0.00 | |
| created_at / updated_at | TIMESTAMP | | |

**Index:** `(asset_id, breakdown_date)`

### 5.7 Entity Relationships

```
mnt_asset_categories ─── [FK category_id] ─── mnt_assets ─── mnt_pm_schedules ─── mnt_pm_work_orders
                                │                    │
                                │               mnt_asset_depreciation (🆕)
                                │               mnt_breakdown_history (🆕)
                                │
                         mnt_amc_contracts ─── [FK vendor_id] ─── vnd_vendors
                                │
                         mnt_assets.amc_contract_id

mnt_tickets ─── [FK category_id] ─── mnt_asset_categories
    │  └─── [FK asset_id] ─── mnt_assets
    ├── mnt_ticket_assignments ─── sys_users (technician)
    ├── mnt_ticket_time_logs ─── sys_users
    └── sys_media (before/after photos, polymorphic)

mnt_work_orders ─── [optional FK] ─── mnt_tickets
               └── [optional FK] ─── mnt_amc_contracts
```

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (tenant middleware)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | /maintenance/dashboard | MaintenanceController@dashboard | mnt.view | Dashboard KPIs |
| GET | /maintenance/calendar | MaintenanceController@calendar | mnt.view | 🆕 Maintenance calendar |
| GET | /maintenance/asset-categories | AssetCategoryController@index | mnt.view | List categories |
| POST | /maintenance/asset-categories | AssetCategoryController@store | mnt.manage | Create category |
| GET | /maintenance/asset-categories/{id} | AssetCategoryController@show | mnt.view | Show category |
| PUT | /maintenance/asset-categories/{id} | AssetCategoryController@update | mnt.manage | Update category |
| DELETE | /maintenance/asset-categories/{id} | AssetCategoryController@destroy | mnt.manage | Soft delete |
| PATCH | /maintenance/asset-categories/{id}/toggle | AssetCategoryController@toggle | mnt.manage | Toggle active |
| GET | /maintenance/assets | AssetController@index | mnt.view | Asset register list |
| POST | /maintenance/assets | AssetController@store | mnt.manage | Create asset |
| GET | /maintenance/assets/{id} | AssetController@show | mnt.view | Asset detail + history |
| PUT | /maintenance/assets/{id} | AssetController@update | mnt.manage | Update asset |
| DELETE | /maintenance/assets/{id} | AssetController@destroy | mnt.manage | Soft delete |
| GET | /maintenance/assets/{id}/qr | AssetController@qrCode | mnt.view | 🆕 Download QR code |
| GET | /maintenance/assets/{id}/depreciation | AssetController@depreciation | mnt.view | 🆕 Depreciation schedule |
| POST | /maintenance/assets/{id}/depreciation | AssetController@storeDepreciation | mnt.manage | 🆕 Record depreciation year |
| GET | /maintenance/tickets | TicketController@index | mnt.view | All tickets (filtered) |
| POST | /maintenance/tickets | TicketController@store | mnt.create | Create ticket |
| GET | /maintenance/tickets/create | TicketController@create | mnt.create | Create form (QR-prefill) |
| GET | /maintenance/tickets/{id} | TicketController@show | mnt.view | Ticket detail |
| PUT | /maintenance/tickets/{id} | TicketController@update | mnt.update | Update ticket fields |
| PATCH | /maintenance/tickets/{id}/status | TicketController@updateStatus | mnt.update | Status transition |
| PATCH | /maintenance/tickets/{id}/priority | TicketController@updatePriority | mnt.manage | Manual priority override |
| POST | /maintenance/tickets/{id}/assign | TicketController@assign | mnt.manage | Manual assignment |
| POST | /maintenance/tickets/{id}/time-log | TicketController@storeTimeLog | mnt.update | Add time log entry |
| POST | /maintenance/tickets/{id}/rate | TicketController@rate | mnt.create | Requester rates ticket |
| GET | /maintenance/work-orders | WorkOrderController@index | mnt.view | Work order list |
| POST | /maintenance/work-orders | WorkOrderController@store | mnt.manage | Create work order |
| GET | /maintenance/work-orders/{id} | WorkOrderController@show | mnt.view | WO detail |
| PUT | /maintenance/work-orders/{id} | WorkOrderController@update | mnt.manage | Update WO |
| PATCH | /maintenance/work-orders/{id}/status | WorkOrderController@updateStatus | mnt.manage | WO status change |
| GET | /maintenance/work-orders/{id}/pdf | WorkOrderController@pdf | mnt.view | PDF work order |
| GET | /maintenance/pm-schedules | PmScheduleController@index | mnt.view | PM schedule list |
| POST | /maintenance/pm-schedules | PmScheduleController@store | mnt.manage | Create PM schedule |
| GET | /maintenance/pm-schedules/{id} | PmScheduleController@show | mnt.view | PM schedule detail |
| PUT | /maintenance/pm-schedules/{id} | PmScheduleController@update | mnt.manage | Update schedule |
| DELETE | /maintenance/pm-schedules/{id} | PmScheduleController@destroy | mnt.manage | Soft delete |
| POST | /maintenance/pm-schedules/{id}/generate | PmScheduleController@generateNow | mnt.manage | Force-generate WO now |
| GET | /maintenance/pm-work-orders | PmScheduleController@workOrderIndex | mnt.view | PM WO list |
| GET | /maintenance/pm-work-orders/{id} | PmScheduleController@workOrderShow | mnt.view | PM WO detail |
| PATCH | /maintenance/pm-work-orders/{id}/checklist | PmScheduleController@updateChecklist | mnt.update | Update checklist |
| GET | /maintenance/amc-contracts | AmcContractController@index | mnt.view | AMC list |
| POST | /maintenance/amc-contracts | AmcContractController@store | mnt.manage | Create AMC |
| GET | /maintenance/amc-contracts/{id} | AmcContractController@show | mnt.view | AMC detail |
| PUT | /maintenance/amc-contracts/{id} | AmcContractController@update | mnt.manage | Update AMC |
| DELETE | /maintenance/amc-contracts/{id} | AmcContractController@destroy | mnt.manage | Soft delete |
| PATCH | /maintenance/amc-contracts/{id}/renew | AmcContractController@renew | mnt.manage | Renew contract |
| GET | /maintenance/reports/ticket-summary | MaintenanceReportController@ticketSummary | mnt.report | Ticket summary |
| GET | /maintenance/reports/sla | MaintenanceReportController@sla | mnt.report | SLA performance |
| GET | /maintenance/reports/technician | MaintenanceReportController@technician | mnt.report | Technician productivity |
| GET | /maintenance/reports/asset-history | MaintenanceReportController@assetHistory | mnt.report | 🆕 Asset maintenance history |
| GET | /maintenance/reports/pm-compliance | MaintenanceReportController@pmCompliance | mnt.report | PM compliance |

**Estimated web routes total: ~55**

### 6.2 Mobile API Routes (auth:sanctum, prefix `/api/v1/maintenance`)

| Method | URI | Controller@Method | Description |
|---|---|---|---|
| GET | /tickets | MobileMaintenanceController@myTickets | Technician's assigned open tickets |
| GET | /tickets/{id} | MobileMaintenanceController@ticketDetail | Ticket details with checklist |
| PATCH | /tickets/{id}/status | MobileMaintenanceController@updateStatus | Update ticket status (mobile) |
| POST | /tickets/{id}/time-log | MobileMaintenanceController@addTimeLog | Log time from mobile |
| POST | /tickets/{id}/photos | MobileMaintenanceController@uploadPhotos | 🆕 Upload before/after photos |
| GET | /pm-work-orders | MobileMaintenanceController@myPmWorkOrders | Technician's PM WOs |
| PATCH | /pm-work-orders/{id}/checklist | MobileMaintenanceController@updateChecklist | Complete PM checklist items |
| GET | /assets/qr-lookup | MobileMaintenanceController@qrLookup | 🆕 Look up asset by asset_code (QR scan) |
| POST | /tickets/quick-create | MobileMaintenanceController@quickCreate | 🆕 Create ticket from QR scan |

**Estimated API routes total: ~9**

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Description |
|---|---|---|---|
| SCR-MNT-01 | Dashboard | mnt.dashboard | KPI cards, open ticket counts by priority, SLA breach count, PM due this week, technician workload chart |
| SCR-MNT-02 | Calendar (🆕) | mnt.calendar | Monthly calendar with PM WO due dates, vendor WO dates, AMC visit dates |
| SCR-MNT-03 | Asset Category List | mnt.asset-categories.index | Table list with SLA hours, default priority, active/inactive toggle |
| SCR-MNT-04 | Asset Category Form | mnt.asset-categories.create/edit | Name, code, default priority, SLA hours, keyword rules editor (JSON), escalation levels editor |
| SCR-MNT-05 | Asset Register List | mnt.assets.index | Filterable table: category, condition, location; includes QR code download button per row |
| SCR-MNT-06 | Asset Detail | mnt.assets.show | Asset info, current condition, book value (🆕), QR code preview, breakdown history tab (🆕), PM history tab, cost summary tab (🆕) |
| SCR-MNT-07 | Asset Create/Edit | mnt.assets.create/edit | All asset fields + depreciation settings (🆕) |
| SCR-MNT-08 | Ticket List | mnt.tickets.index | Filterable by status, priority, category, technician, date; SLA breach highlighted in red |
| SCR-MNT-09 | Ticket Create | mnt.tickets.create | Category select → keyword hint shown; location fields; asset lookup (🆕 QR prefill); photo upload |
| SCR-MNT-10 | Ticket Detail | mnt.tickets.show | Full ticket info, status timeline, assignment history, time logs, before/after photos, rating widget (on Closed) |
| SCR-MNT-11 | Ticket Status Update | (modal on detail) | Inline modal: status dropdown, resolution notes (required on Resolved), photo upload |
| SCR-MNT-12 | PM Schedule List | mnt.pm-schedules.index | List of active PM schedules with asset name, recurrence, next due date, last generated date |
| SCR-MNT-13 | PM Schedule Form | mnt.pm-schedules.create/edit | Asset select, recurrence settings, checklist items builder (add/remove rows) |
| SCR-MNT-14 | PM Work Order List | mnt.pm-work-orders.index | Filterable: status, asset, date; overdue highlighted |
| SCR-MNT-15 | PM Work Order Detail | mnt.pm-work-orders.show | Checklist with completion checkboxes and notes per item; hours spent entry |
| SCR-MNT-16 | AMC Contract List | mnt.amc-contracts.index | List with expiry date, days remaining badge (🟡 <30, 🔴 <7), covered assets |
| SCR-MNT-17 | AMC Contract Form | mnt.amc-contracts.create/edit | Vendor fields, date range, covered assets multi-select, document upload |
| SCR-MNT-18 | Work Order List | mnt.work-orders.index | Vendor WOs list; filterable by status |
| SCR-MNT-19 | Work Order Form | mnt.work-orders.create/edit | Link to ticket/AMC, vendor details, cost fields |
| SCR-MNT-20 | Work Order Detail/PDF | mnt.work-orders.show | Full WO with PDF print button |
| SCR-MNT-21 | Ticket Summary Report | mnt.reports.ticket-summary | Date-range bar charts + table; CSV export |
| SCR-MNT-22 | SLA Performance Report | mnt.reports.sla | % within SLA, avg resolution time by category; breach trend chart |
| SCR-MNT-23 | Technician Report | mnt.reports.technician | Per-technician table: assigned, resolved, avg time, hours logged |
| SCR-MNT-24 | Asset History Report (🆕) | mnt.reports.asset-history | Asset selector → chronological event timeline + total cost |
| SCR-MNT-25 | PM Compliance Report | mnt.reports.pm-compliance | Scheduled vs completed vs overdue PM WOs per asset per period |

---

## 8. Business Rules

| Rule ID | Description |
|---|---|
| BR-MNT-001 | Ticket number auto-generated as MNT-YYYY-XXXXXXXX (4-digit year + 8-digit zero-padded serial); DB lock-for-update prevents duplicates under concurrent creation. |
| BR-MNT-002 | sla_due_at = ticket.created_at + category.sla_hours (clock hours for V2; business-hours mode configurable for V3). |
| BR-MNT-003 | Status transitions enforced as strict state machine: Open→Accepted→In_Progress→(On_Hold↔In_Progress)→Resolved→Closed. Cancelled is allowed from Open/Accepted/In_Progress/On_Hold by admin only. Invalid transitions return HTTP 422. |
| BR-MNT-004 | Resolution notes (min 20 chars) are mandatory when transitioning status to Resolved. |
| BR-MNT-005 | Auto-assignment may leave ticket unassigned if no technician role matches or all are unavailable. Ticket remains Open; Maintenance Incharge notified immediately for manual assignment. |
| BR-MNT-006 | PM work order generation: only one Pending or In_Progress WO per pm_schedule at a time. If an unresolved WO exists, generation is skipped for that schedule. |
| BR-MNT-007 | AMC expiry alerts fire at exactly 60, 30, and 7 calendar days before end_date. Each threshold fires once per contract (tracked by renewal_alert_sent_60/30/7 flags). |
| BR-MNT-008 | Technician can view/update only tickets where mnt_ticket_assignments.is_current=1 AND assigned_to_user_id = auth user. School Admin and Maintenance Incharge can update any ticket. |
| BR-MNT-009 | Keyword priority matching: case-insensitive LIKE scan of ticket.description against category.priority_keywords_json; Critical takes precedence over High over Medium over Low. |
| BR-MNT-010 | Before photos are required when status changes to In_Progress; after photos are required on Resolved. Both requirements are configurable via sys_school_settings (mnt_require_photos). |
| BR-MNT-011 | (🆕 V2) SLA escalation levels: EscalationService reads category.sla_escalation_json after each SLA breach check. If ticket age exceeds L1.after_hours and escalation_level < 1, notify L1 role and set escalation_level=1. Repeat for L2. |
| BR-MNT-012 | (🆕 V2) Asset total_maintenance_cost = SUM(ticket.total_parts_cost for linked asset) + SUM(work_order.actual_cost for linked asset). Recalculated on ticket close and WO completion. |
| BR-MNT-013 | (🆕 V2) PM WO marked Overdue automatically if due_date < TODAY and status ∈ (Pending, In_Progress). Batch update runs in daily cron. |
| BR-MNT-014 | (🆕 V2) When an asset ticket is Resolved, a record is inserted/updated in mnt_breakdown_history (only if asset_id is set). downtime_hours = resolved_at − created_at in hours. |
| BR-MNT-015 | (🆕 V2) QR code is auto-generated using SimpleSoftwareIO/simple-qrcode package on first save of an asset; regenerated if asset_code changes. |
| BR-MNT-016 | Asset depreciation unique constraint: one record per (asset_id, financial_year). Running DepreciationService twice for same year returns validation error. |

---

## 9. Workflow Diagrams (FSM Descriptions)

### 9.1 Ticket Lifecycle FSM

```
[Open] ──(Auto/Manual Assign)──→ [Accepted] ──(Start Work)──→ [In_Progress]
  │                                                                  │      │
  │                                                           (Hold) │      │ (Resume)
  │                                                            ↓     │      ↑
  │                                                        [On_Hold]─┘      │
  │                                                                  │      │
  │                                                           (Resolve)     │
  └──(Admin Cancel)──→ [Cancelled]                             ↓
                                                          [Resolved]
                                                               │
                                                       (Admin Close)
                                                               ↓
                                                          [Closed]
```

Transitions that fire notifications:
- Open → Accepted: requester notified
- Assigned: technician notified
- In_Progress: requester notified
- Resolved: requester notified (with rating prompt queued for Closed)
- Closed: rating/feedback notification sent to requester

### 9.2 PM Work Order Lifecycle FSM

```
[Schedule Due] ──(GeneratePmWorkOrdersJob)──→ [Pending]
                                                   │
                                          (Technician starts)
                                                   ↓
                                             [In_Progress]
                                                   │
                                      (All checklist items checked)
                                                   ↓
                                            [Completed]

If due_date passed and status ∈ {Pending, In_Progress}: → [Overdue]  (daily cron)
Admin can cancel at any point: → [Cancelled]
```

### 9.3 AMC Expiry Alert Flow

```
Daily cron: SendAmcExpiryAlertsJob
└── Query contracts WHERE status=Active AND end_date BETWEEN NOW AND NOW+60d
    ├── end_date ≤ NOW+7d  AND renewal_alert_sent_7=0  → send alert; flag=1
    ├── end_date ≤ NOW+30d AND renewal_alert_sent_30=0 → send alert; flag=1
    └── end_date ≤ NOW+60d AND renewal_alert_sent_60=0 → send alert; flag=1

Query contracts WHERE end_date < NOW AND status=Active
└── Update status=Expired
```

### 9.4 QR Code Scan-to-Report Flow (🆕 V2)

```
Field Staff scans QR code on asset label
    ↓
Mobile browser: GET /maintenance/tickets/create?asset_id={id}
    ↓
[Logged in?]
  YES → Ticket form pre-filled: asset, location from mnt_assets
  NO  → Redirect to login (or guest-report if enabled in settings)
    ↓
Staff fills title + description → submits
    ↓
TicketService: keyword check → priority → auto-assign → notify technician
```

---

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Ticket list with all filters must load in < 2 s for up to 10,000 tickets; ensured by composite indexes on (status, priority) and (assigned_to_user_id, status). |
| Mobile | Mobile API responses include only necessary fields; JSON response < 20 KB per ticket list page (20 items). SCR-MNT-09/11/15 blade views are fully responsive for 375px+ viewport. |
| Concurrency | Ticket number generation uses DB-level lock (`lockForUpdate`) inside a transaction to prevent duplicate numbers under concurrent creation. |
| Security | Technician data access gated via TicketPolicy and PmWorkOrderPolicy; technicians cannot view or modify unassigned tickets. |
| Audit Trail | All status transitions, assignments, priority overrides, and escalations written to sys_activity_logs (subject_type, subject_id, event, properties JSON). |
| PDF | Work orders (corrective and PM) printable via DomPDF. School header, logo, and contact included. |
| Timezone | All SLA calculations use school timezone from sys_school_settings (Carbon::now($timezone)). |
| Scalability | mnt_tickets indexes support 100,000-row tables without full-table scans for dashboard queries. |
| Queues | Assignment notifications, SLA breach alerts, and AMC expiry notifications dispatched via Laravel Queue (database driver by default; Redis recommended for production). |
| QR Code | SimpleSoftwareIO/simple-qrcode (or equivalent) generates PNG QR; stored to sys_media. Print-ready label view at 300dpi equivalent. |

---

## 11. Module Dependencies

| Dependency | Type | Direction | Details |
|---|---|---|---|
| `sys_users` | Read FK | Inbound | Technician assignments, requester, created_by |
| `sys_roles` | Read FK | Inbound | Auto-assignment by role (category.auto_assign_role_id) |
| `sys_media` | Write | Outbound | Before/after photos, QR codes, contract documents, asset photos |
| `sys_activity_logs` | Write | Outbound | All audit events |
| `ntf_notifications` (NTF) | Dispatch | Outbound | Assignment alerts, SLA/escalation alerts, AMC expiry alerts, requester updates |
| `vnd_vendors` (VND) | Read FK | Inbound | Vendor linked to AMC contracts and external work orders |
| `sch_school_settings` (SCH) | Read | Inbound | Timezone (SLA calc), mnt_require_photos setting |
| `inv_items` / `inv_stock_entries` (INV) | Future FK | Outbound | 🆕 Parts used in tickets linked to inventory deduction when INV module built |
| `acc_journal_entries` (FAC) | Future FK | Outbound | 🆕 Depreciation and WO cost posted to FAC journal when built |
| `stp_student` (STP) | Future | Inbound | 🆕 Students raise maintenance requests via Student Portal |

---

## 12. Test Scenarios

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | TicketCreationTest | Feature | Create ticket; description contains "water leakage" → priority auto-set to High | Critical |
| 2 | TicketCreationTest | Feature | Create ticket; no keyword match → priority = category.default_priority | High |
| 3 | AutoAssignmentTest | Feature | Two technicians in matching role; ticket assigned to one with fewer open tickets | High |
| 4 | AutoAssignmentTest | Feature | No technician available → ticket unassigned; Maintenance Incharge notified | High |
| 5 | TicketStatusTransitionTest | Feature | Valid transitions succeed (Open→Accepted→In_Progress→Resolved→Closed) | Critical |
| 6 | TicketStatusTransitionTest | Feature | Invalid transition (Open→Resolved) returns 422 | Critical |
| 7 | SlaBreachTest | Feature | Ticket sla_due_at in past → is_sla_breached=1 after CheckSlaBreachesJob runs | High |
| 8 | SlaEscalationTest | Feature | 🆕 Ticket breached SLA for L1.after_hours → L1 notification dispatched; escalation_level=1 | High |
| 9 | ResolutionNotesTest | Feature | Status update to Resolved without resolution_notes → 422 | High |
| 10 | TimeLogTest | Feature | Time log entry added → ticket.total_hours_logged updated correctly | High |
| 11 | PmWorkOrderGenerationTest | Feature | PM schedule next_due_date = today → WO auto-created by job | High |
| 12 | PmWorkOrderDuplicateTest | Feature | Pending WO already exists → second WO not created for same schedule | High |
| 13 | PmChecklistCompletionTest | Feature | All checklist items marked complete → WO status=Completed; asset.last_pm_date updated | Medium |
| 14 | AmcExpiryAlertTest | Feature | AMC end_date 30 days away; job runs → alert dispatched exactly once | Medium |
| 15 | TechnicianAuthorizationTest | Feature | Technician attempts to update ticket assigned to another → 403 | Critical |
| 16 | AssetDepreciationTest | Unit | 🆕 SLM: annual_charge = (purchase_cost − salvage_value) / useful_life_years | Medium |
| 17 | AssetDepreciationTest | Unit | 🆕 WDV: annual_charge = opening_book_value × depreciation_rate / 100 | Medium |
| 18 | QrCodeTest | Feature | 🆕 Asset saved → qr_code_media_id populated; QR content decodes to correct URL | Medium |
| 19 | BreakdownHistoryTest | Feature | 🆕 Ticket with asset_id resolved → mnt_breakdown_history record inserted | Medium |
| 20 | WorkOrderCostTest | Feature | WO completed with actual_cost → asset.total_maintenance_cost updated | Medium |

---

## 13. Glossary

| Term | Definition |
|---|---|
| AMC | Annual Maintenance Contract — a service contract with an external vendor for periodic servicing of equipment |
| Asset | Any school-owned physical item tracked in the maintenance system (equipment, furniture, infrastructure) |
| Asset Code | Unique identifier for an asset, format MNT-AST-XXXXXX |
| Book Value | purchase_cost minus accumulated depreciation at a point in time |
| Corrective Maintenance | Reactive repair work initiated by a maintenance ticket |
| Escalation Level | 🆕 Stage of SLA escalation (L1 = Maintenance Incharge notified; L2 = Principal notified) after extended SLA breach |
| PM | Preventive Maintenance — scheduled upkeep to prevent breakdowns |
| PM Schedule | A recurring checklist assigned to an asset (e.g., monthly AC filter cleaning) |
| PM Work Order | Auto-generated work order from a PM schedule when its due date is reached |
| Priority | Urgency level: Low / Medium / High / Critical — can be auto-set from keywords or manually overridden |
| QR Code | 🆕 Quick Response code attached to physical asset; scanning opens ticket creation pre-filled for that asset |
| Requester | Staff member or student who raised the maintenance ticket |
| SLA | Service Level Agreement — target resolution time (in hours) per asset category |
| SLA Breach | When a ticket is not Resolved by its sla_due_at timestamp |
| SLM | Straight Line Method — depreciation method where equal charge applied each year |
| Technician | Internal maintenance staff assigned to resolve tickets |
| WDV | Written Down Value method — depreciation applied as a % of remaining book value each year |
| Work Order | Formal document issued to an external vendor for repair or maintenance work |

---

## 14. Suggestions & Improvements

| # | Area | Suggestion | Rationale |
|---|---|---|---|
| S-01 | QR Code label printing | Add a "Print Asset Labels" bulk action on the asset list — generates a PDF sheet of QR labels (asset name, code, QR image, location) | Reduces manual effort for tagging 100+ assets |
| S-02 | Mobile-first ticket creation | Design SCR-MNT-09 with large tap targets and camera-based photo upload as primary action; description field supports voice-to-text on mobile | Field staff often use phones while at the problem location |
| S-03 | Spare parts catalogue integration | When INV module is ready, replace parts_used free-text with an autocomplete linked to inv_items; auto-deduct from inventory on ticket close | Enables accurate parts cost tracking and reorder alerts |
| S-04 | Technician availability calendar | Add a per-technician availability schedule (linked to HR leave) so AssignmentService excludes technicians on leave | Prevents assigning tickets to absent technicians |
| S-05 | Recurring SLA targets by priority | Allow per-priority SLA overrides within a category (e.g., Critical = 2 hrs, High = 8 hrs, Medium = 24 hrs) rather than a single sla_hours per category | More granular SLA management for critical incidents |
| S-06 | Predictive breakdown alerts | Feed breakdown history frequency data to PAN (Predictive Analytics) module: if an asset has >3 breakdowns in 90 days, flag for replacement consideration | Proactive asset management |
| S-07 | Requester SMS notification | On ticket creation and on Resolved status, send SMS to requester's mobile (via NTF SMS gateway) — useful for non-app users like parents raising issues | Higher notification reach |
| S-08 | Work order approval workflow | Add an approval step for work orders above a configurable cost threshold (e.g., WOs > ₹10,000 require Principal approval before Issued status) | Financial control over outsourced maintenance |
| S-09 | Maintenance cost budget tracking | Add a monthly/annual maintenance budget per category; dashboard shows budget vs actual spend | Enables proactive budget management |
| S-10 | Asset lifecycle stages | Extend current_condition ENUM with lifecycle stages (New → In_Use → Requires_Service → End_of_Life → Decommissioned) and a formal decommission workflow | Cleaner asset lifecycle governance |

---

## 15. Appendices

### 15.1 Suggested Seeder Data — Asset Categories

| Name | Code | Default Priority | SLA Hours | Keywords (High) | Keywords (Critical) |
|---|---|---|---|---|---|
| Electrical | ELEC | Medium | 8 | short circuit, no power, power failure, tripping | electrocution, fire, sparks |
| Plumbing | PLMB | Medium | 12 | water leakage, tap dripping, drain blocked | flooding, burst pipe, sewage overflow |
| IT/Computer | ITCP | Medium | 24 | system not working, printer down, projector | server down, internet down |
| Carpentry | CRPT | Low | 48 | broken furniture, door stuck, window broken | — |
| Cleaning | CLNG | Low | 4 | not cleaned, dirty | biohazard, vomit, spillage |
| HVAC | HVAC | Medium | 24 | AC not cooling, AC dripping | AC not working at all, fire from AC |
| Fire Safety | FIRE | High | 4 | extinguisher expired, alarm fault | fire detected, smoke alarm |
| Civil/Structural | CVIL | Medium | 48 | crack in wall, ceiling damage | roof collapse risk, structural damage |
| Sports/Ground | SPRT | Low | 72 | equipment damaged, ground waterlogged | — |

### 15.2 Scheduled Jobs Summary

| Job Class | Schedule | Purpose |
|---|---|---|
| `GeneratePmWorkOrdersJob` | Daily at 06:00 | Generate PM work orders for due schedules |
| `CheckSlaBreachesJob` | Every 30 minutes | Set is_sla_breached, trigger escalation levels |
| `SendAmcExpiryAlertsJob` | Daily at 08:00 | Send AMC expiry alerts at 60/30/7-day thresholds |
| `MarkOverduePmWorkOrdersJob` | Daily at 07:00 | Mark PM WOs as Overdue if due_date < today |

### 15.3 Permission Slugs

| Permission Slug | Assigned To |
|---|---|
| `tenant.mnt-asset-category.view` | All roles with maintenance access |
| `tenant.mnt-asset-category.manage` | Admin, Maintenance Incharge |
| `tenant.mnt-asset.view` | Admin, Maintenance Incharge, Technician |
| `tenant.mnt-asset.manage` | Admin, Maintenance Incharge |
| `tenant.mnt-ticket.create` | Admin, Maintenance Incharge, Teacher, Staff, Student (limited) |
| `tenant.mnt-ticket.view` | Admin, Maintenance Incharge, Technician (own) |
| `tenant.mnt-ticket.update` | Technician (assigned), Admin, Maintenance Incharge |
| `tenant.mnt-ticket.manage` | Admin, Maintenance Incharge |
| `tenant.mnt-pm-schedule.manage` | Admin, Maintenance Incharge |
| `tenant.mnt-pm-work-order.update` | Technician (assigned), Admin, Maintenance Incharge |
| `tenant.mnt-amc-contract.manage` | Admin, Maintenance Incharge |
| `tenant.mnt-work-order.manage` | Admin, Maintenance Incharge |
| `tenant.mnt-report.view` | Admin, Principal, Maintenance Incharge |

### 15.4 Implementation Phases

| Phase | Deliverables | Priority |
|---|---|---|
| Phase 1 — Foundation | 12 migrations, 11 Models, Module providers, seeders (asset categories) | Critical |
| Phase 2 — Categories & Assets | AssetCategoryController (CRUD + keywords + escalation), AssetController (CRUD + QR) | Critical |
| Phase 3 — Ticketing Core | TicketController (CRUD), TicketService (priority + auto-assign), assignment notification | Critical |
| Phase 4 — Ticket Lifecycle | Status state machine, time logs, photo enforcement, SLA breach job | Critical |
| Phase 5 — Dashboard | KPI dashboard, escalation service, SLA breach alerts, overdue PM job | High |
| Phase 6 — PM Schedules | PmScheduleController, GeneratePmWorkOrdersJob, PM WO checklist completion | High |
| Phase 7 — AMC Contracts | AmcContractController, SendAmcExpiryAlertsJob, AMC renewal workflow | High |
| Phase 8 — Work Orders | WorkOrderController, PDF work order, cost rollup to asset | Medium |
| Phase 9 — Depreciation | DepreciationService, AssetDepreciation model, FAC hook scaffold | Medium |
| Phase 10 — Reports & Calendar | All 5 reports, maintenance calendar, CSV exports | Medium |
| Phase 11 — Mobile API | MobileMaintenanceController, QR lookup endpoint, mobile-optimised views | Medium |

---

## 16. V1 → V2 Delta

### 16.1 What V1 Had

V1 covered the core ticket management lifecycle (create, assign, update status, time log, before/after photos), preventive maintenance schedules and work order generation, AMC contract tracking with expiry alerts, external vendor work orders, and a basic dashboard with 3 report types. 9 tables with ~58 routes.

### 16.2 What V2 Adds (🆕)

| Addition | Impact |
|---|---|
| `mnt_asset_depreciation` table | +1 table; supports SLM and WDV depreciation recording per financial year |
| `mnt_breakdown_history` table | +1 table; auto-populated on ticket resolution for assets; enables breakdown frequency analysis |
| `sla_escalation_json` on categories | +1 column; supports multi-level SLA escalation notifications (L1 = Maint Incharge, L2 = Principal) |
| `escalation_level` on tickets | +1 column; tracks current escalation stage |
| `total_maintenance_cost` on assets | +1 column; running total recalculated on ticket close and WO completion |
| `qr_code_media_id` on assets | +1 column; QR code auto-generated on asset save |
| Asset depreciation fields on `mnt_assets` | +5 columns: salvage_value, useful_life_years, depreciation_method, depreciation_rate, accumulated_depreciation, current_book_value |
| `DepreciationService` | New service for SLM/WDV calculation |
| `EscalationService` | New service for multi-level SLA escalation |
| `MobileMaintenanceController` (API) | New controller with 9 mobile-optimised endpoints for field staff |
| Maintenance calendar view | New SCR-MNT-02; shows PM WOs, vendor WOs, AMC visits on monthly calendar |
| Asset history report | New SCR-MNT-24; per-asset chronological breakdown + cost report |
| QR scan-to-report flow | End-to-end: QR generated → scan on mobile → pre-filled ticket creation |
| `MarkOverduePmWorkOrdersJob` | New scheduled job; auto-marks PM WOs as Overdue |
| Work order PDF | DomPDF work order print added to WorkOrderController |
| FAC cost posting scaffold | Work order completion hooks for future FAC journal integration |
| INV spare parts scaffold | parts_used column retained as free-text; FK integration point documented for INV module |
| `Daily` recurrence option for PM | Added Daily to PM schedule recurrence ENUM (V1 had Weekly/Monthly/Quarterly/Yearly only) |
| Table count | V1: 9 tables → V2: 11 tables (+mnt_asset_depreciation, +mnt_breakdown_history) |
| Route count | V1: ~58 web + 5 API → V2: ~55 web + 9 API = ~64 total |
| Screen count | V1: ~22 screens → V2: 25 screens (+Calendar, +Asset History Report, +depreciation modal) |

### 16.3 V1 Items Retained Unchanged

- Asset category CRUD with keyword priority rules
- Asset register CRUD with condition tracking and photo
- Full ticket lifecycle state machine (Open→Accepted→In_Progress→On_Hold→Resolved→Closed)
- Auto-assignment (AssignmentService: role + workload score)
- Time & parts logging (mnt_ticket_time_logs)
- Before/after photo enforcement (configurable)
- SLA breach detection (CheckSlaBreachesJob, is_sla_breached flag)
- Requester 1–5 star rating on ticket close
- PM schedule CRUD with recurrence and checklist_items_json
- PM work order auto-generation (GeneratePmWorkOrdersJob)
- PM work order checklist completion updating asset.last_pm_date
- AMC contract CRUD with 60/30/7-day expiry alerts
- External vendor work order CRUD
- 5 report types (Ticket Summary, SLA Performance, Technician Productivity, PM Compliance)
- All business rules BR-MNT-001 through BR-MNT-010
- All permission slugs from V1 (extended in V2)
- All 10 test scenarios from V1 (extended to 20 in V2)

---

*Document generated: 2026-03-26 | Author: Claude Code (RBS_ONLY mode) | Next review: before Phase 1 development kickoff*
