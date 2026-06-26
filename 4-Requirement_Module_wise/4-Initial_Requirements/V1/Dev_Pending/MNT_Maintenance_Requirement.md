# Maintenance Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Greenfield RBS-Only)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** MNT | **Module Path:** `Modules/Maintenance`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `mnt_*` | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module Y — Maintenance & Facility Helpdesk (lines 4347–4376)

> **GREENFIELD MODULE** — No code, no DDL, no tests exist. All features are 📐 Proposed. This document defines the complete functional specification to guide development from scratch.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Actors](#3-stakeholders--actors)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Executive Summary

### 1.1 Purpose

The Maintenance module provides a structured facility helpdesk and preventive maintenance system for Indian K-12 schools on the Prime-AI platform. It enables staff and students to raise maintenance tickets (plumbing, electrical, IT, carpentry, cleaning), auto-assigns tickets to available technicians based on skill and location, tracks work progress with time logging and photo evidence, manages preventive maintenance schedules for critical assets, and maintains AMC (Annual Maintenance Contract) records for vendor-serviced equipment.

### 1.2 Scope

This module covers:
- Asset/facility register: catalogue of maintainable school assets (buildings, equipment, infrastructure)
- Asset categories for classification (Electrical, Plumbing, IT, Civil, Sports, HVAC, Fire Safety)
- Maintenance ticket lifecycle: raise → assign → accept → in-progress → resolved → closed
- Auto-priority assignment based on category/keyword rules (e.g., "water leakage" = High priority)
- Technician skill-based auto-assignment with workload balancing
- Ticket progress tracking: status updates, time logging, parts used, before/after photos
- Preventive maintenance (PM) schedules: asset-linked recurring checklists
- PM work order auto-generation based on recurrence schedule
- AMC contracts: vendor-linked service contracts with expiry tracking
- Work orders for external vendor repairs
- Reports: open tickets by category, SLA performance, technician productivity, asset health

Out of scope for this version: physical spare parts inventory management (link to Inventory module when built), IoT sensor-based predictive maintenance.

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.Y*) | 2 (F.Y1.1, F.Y1.2, F.Y2.1) |
| RBS Tasks | 4 |
| RBS Sub-tasks | 8 (ST.Y1.1.1.1–ST.Y2.1.2.2) |
| Proposed DB Tables (mnt_*) | 9 |
| Proposed Named Routes | ~58 |
| Proposed Blade Views | ~30 |
| Proposed Controllers | 8 |
| Proposed Models | 9 |
| Proposed Services | 3 |
| Proposed FormRequests | 8 |
| Proposed Policies | 8 |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 9 tables to be created |
| Models | ❌ Not Started | 9 models |
| Controllers | ❌ Not Started | 8 controllers |
| Services | ❌ Not Started | TicketService, AssignmentService, PmScheduleService |
| Views | ❌ Not Started | ~30 blade views |
| Routes | ❌ Not Started | ~58 named routes |
| Tests | ❌ Not Started | Feature + Unit tests |

**Overall Implementation: 0%** (Greenfield)

---

## 2. Module Overview

### 2.1 Business Purpose

Indian school buildings — especially older institutions — require constant maintenance: electrical faults, plumbing issues, broken furniture, IT equipment failures, sports ground upkeep, and classroom repairs. Without a digital system, requests are made verbally or via WhatsApp, accountability is zero, and issues remain unresolved for weeks. Preventive maintenance (generator service, fire extinguisher checks, AC cleaning) is skipped due to lack of scheduling.

The Maintenance module solves:
1. **Structured ticketing** — every issue gets a ticket number; there is a clear owner and timeline
2. **Smart auto-assignment** — tickets are routed to the right technician automatically based on skill
3. **Progress visibility** — requester can see ticket status in real-time; no need to follow up verbally
4. **Evidence trail** — before/after photos, time logs, and parts used documented on every ticket
5. **Preventive maintenance** — critical assets have scheduled checklists preventing costly breakdowns
6. **AMC tracking** — vendor contracts (HVAC, lifts, generators) tracked with expiry alerts
7. **Asset health reports** — school management sees asset condition and maintenance costs

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Asset Category Management | Categories: Electrical, Plumbing, IT, Civil, HVAC, Sports, Fire Safety | F.Y1.1 | 📐 Proposed |
| Asset Register | School asset inventory with location and condition tracking | Beyond RBS | 📐 Proposed |
| Ticket Creation | Staff/student raises ticket with category, location, photo | ST.Y1.1.1.1–2 | 📐 Proposed |
| Auto Priority Assignment | Rule-based priority from category/keyword (e.g., "water leakage"=High) | ST.Y1.1.2.1 | 📐 Proposed |
| Manual Priority Override | Admin overrides auto-assigned priority | ST.Y1.1.2.2 | 📐 Proposed |
| Auto Technician Assignment | Route to available technician by skill + location | ST.Y1.2.1.1 | 📐 Proposed |
| Assignment Notification | Push notification to technician's app on assignment | ST.Y1.2.1.2 | 📐 Proposed |
| Ticket Status Updates | Technician: Accepted→In Progress→On Hold→Resolved | ST.Y1.2.2.1 | 📐 Proposed |
| Time & Parts Logging | Log time spent, parts used, resolution notes, before/after photos | ST.Y1.2.2.2 | 📐 Proposed |
| PM Checklist Management | Define PM tasks per asset with recurrence | ST.Y2.1.1.1–2 | 📐 Proposed |
| PM Work Order Generation | Auto-generate work orders based on PM schedule | ST.Y2.1.2.1–2 | 📐 Proposed |
| AMC Contract Tracking | Vendor AMC records with expiry alerts | Beyond RBS | 📐 Proposed |
| Work Orders | Formal work orders for external vendor repairs | Beyond RBS | 📐 Proposed |
| Dashboard & Reports | Open tickets, SLA, technician productivity, asset health | Beyond RBS | 📐 Proposed |

### 2.3 Menu Navigation Path

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
    │   └── My Tickets         [/maintenance/tickets?mine=1]
    ├── Work Orders            [/maintenance/work-orders]
    ├── Preventive Maintenance
    │   ├── PM Schedules       [/maintenance/pm-schedules]
    │   └── PM Work Orders     [/maintenance/pm-work-orders]
    ├── AMC Contracts          [/maintenance/amc-contracts]
    └── Reports
        ├── Ticket Summary     [/maintenance/reports/ticket-summary]
        ├── SLA Report         [/maintenance/reports/sla]
        └── Technician Report  [/maintenance/reports/technician]
```

### 2.4 Module Architecture

```
Modules/Maintenance/
├── app/
│   ├── Http/Controllers/
│   │   ├── MaintenanceController.php        # Dashboard + module root
│   │   ├── AssetCategoryController.php      # Asset category CRUD
│   │   ├── AssetController.php              # Asset register CRUD
│   │   ├── TicketController.php             # Ticket CRUD + lifecycle
│   │   ├── WorkOrderController.php          # Work order management
│   │   ├── PmScheduleController.php         # PM schedule + checklist
│   │   ├── AmcContractController.php        # AMC contract management
│   │   └── MaintenanceReportController.php  # Reports
│   ├── Models/
│   │   ├── AssetCategory.php
│   │   ├── Asset.php
│   │   ├── Ticket.php
│   │   ├── TicketAssignment.php
│   │   ├── TicketTimeLog.php
│   │   ├── WorkOrder.php
│   │   ├── PmSchedule.php
│   │   ├── PmWorkOrder.php
│   │   └── AmcContract.php
│   ├── Services/
│   │   ├── TicketService.php                # Priority rules, auto-assign, status transitions
│   │   ├── AssignmentService.php            # Technician workload + skill matching
│   │   └── PmScheduleService.php            # PM work order generation (scheduled job)
│   ├── Policies/ (8 policies)
│   └── Providers/
├── database/migrations/ (9 migrations)
├── resources/views/maintenance/
│   ├── dashboard.blade.php
│   ├── asset-categories/ (create, edit, index, show, trash)
│   ├── assets/           (create, edit, index, show, trash)
│   ├── tickets/          (create, edit, index, show, my-tickets)
│   ├── work-orders/      (create, edit, index, show)
│   ├── pm-schedules/     (create, edit, index, show)
│   ├── pm-work-orders/   (index, show)
│   ├── amc-contracts/    (create, edit, index, show, trash)
│   └── reports/          (ticket-summary, sla, technician)
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. Stakeholders & Actors

| Actor | Role in Maintenance Module | Permissions |
|---|---|---|
| School Admin | Full access: configure assets, view all tickets, reports, AMC | All permissions |
| Principal | View all tickets, approve high-priority escalations | view all, approve |
| Admin/Office Staff | Raise tickets on behalf of department, assign work orders | create, assign |
| Teacher | Raise tickets for classroom/equipment issues | create (own) |
| Student | Raise tickets via portal for common area issues | create (own, limited) |
| Maintenance Incharge | Manage all tickets, assign technicians, PM schedules | manage tickets, PM, AMC |
| Technician (Internal) | Accept, update, close tickets assigned to them | update (assigned only) |
| Vendor/Contractor | External party assigned via AMC/work orders | via work order only |
| System | Auto-assign priority, generate PM work orders, send expiry alerts | system actor |

---

## 4. Functional Requirements

---

### FR-MNT-001: Asset Category Management (F.Y1.1 — prerequisite)

**RBS Reference:** F.Y1.1 — Issue Reporting (category selection prerequisite)
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `mnt_asset_categories`

#### Requirements

**REQ-MNT-001.1: Create Asset Category**
| Attribute | Detail |
|---|---|
| Description | Admin creates maintenance categories (e.g., Electrical, Plumbing, IT, Carpenter, Cleaning, HVAC, Fire Safety) |
| Actors | School Admin, Maintenance Incharge |
| Preconditions | `tenant.mnt-asset-category.create` permission |
| Input | name (required, max 100, unique), code (optional, unique), description, default_priority (ENUM: Low/Medium/High/Critical), sla_hours (default resolution time in hours), auto_assign_role_id (FK sys_roles — role for auto-assignment), is_active |
| Processing | Validate uniqueness; create record; log activity |
| Output | Category in list; used in ticket creation dropdown |
| Status | 📐 Proposed |

**REQ-MNT-001.2: Priority Keyword Rules**
| Attribute | Detail |
|---|---|
| Description | Admin configures keywords that auto-escalate priority for tickets in this category |
| Input | priority_keywords_json (e.g., {"High": ["water leakage", "short circuit", "fire"], "Critical": ["flooding", "electrocution"]}) |
| Processing | Stored as JSON in category record; TicketService scans description for keywords on ticket creation |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Y1.1.1.1 — Categories Electrical, Plumbing, Carpenter, IT, Cleaning available
- [ ] Keyword-based priority escalation configured per category

---

### FR-MNT-002: Asset Register (Beyond RBS)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `mnt_assets`

#### Requirements

**REQ-MNT-002.1: Create Asset Record**
| Attribute | Detail |
|---|---|
| Description | Admin maintains a register of maintainable school assets linked to location |
| Actors | School Admin, Maintenance Incharge |
| Preconditions | Asset category exists; `tenant.mnt-asset.create` permission |
| Input | name (required), category_id (FK mnt_asset_categories), asset_code (unique, system-generated or manual), location_building, location_floor, location_room, purchase_date, purchase_cost (decimal), warranty_expiry_date, current_condition (ENUM: Good/Fair/Poor/Critical), notes |
| Processing | Create record; auto-assign asset_code if not provided (MNT-AST-XXXXXX) |
| Output | Asset in register; can be linked to PM schedules and AMC contracts |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Assets can be linked to PM schedules (one-to-many)
- [ ] Asset condition tracked and visible on dashboard

---

### FR-MNT-003: Maintenance Ticket Creation (F.Y1.1 — T.Y1.1.1)

**RBS Reference:** T.Y1.1.1 — Create Maintenance Ticket
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `mnt_tickets`

#### Requirements

**REQ-MNT-003.1: Create Maintenance Ticket (ST.Y1.1.1.1–2)**
| Attribute | Detail |
|---|---|
| Description | Any authorised staff member or student raises a maintenance issue ticket |
| Actors | School Admin, Teacher, Staff, Student (limited) |
| Preconditions | Asset categories exist; `tenant.mnt-ticket.create` permission |
| Input | title (required, max 200), category_id (FK mnt_asset_categories), asset_id (optional FK mnt_assets), description (text, required), location_building (required), location_floor, location_room, photos[] (up to 5 images via sys_media), requested_date (defaults to today) |
| Processing | 1) Auto-assign ticket_number (MNT-YYYY-XXXXXXXX, lock-for-update + serial); 2) Check category.priority_keywords_json against description — escalate priority if keyword found; 3) Assign priority = keyword-matched priority OR category.default_priority; 4) status = Open; 5) Trigger auto-assignment (AssignmentService); 6) Notify assigned technician |
| Output | Ticket created; assignment made; ticket number shown in success message |
| Status | 📐 Proposed |

**REQ-MNT-003.2: Auto Priority (ST.Y1.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | System scans ticket description for priority keywords and upgrades priority |
| Processing | TicketService: foreach priority_level (Critical > High > Medium > Low): if any keyword in description → set priority = that level; break; fall back to category.default_priority |
| Status | 📐 Proposed |

**REQ-MNT-003.3: Manual Priority Override (ST.Y1.1.2.2)**
| Attribute | Detail |
|---|---|
| Description | Admin or Maintenance Incharge can override the auto-assigned priority |
| Actors | School Admin, Maintenance Incharge |
| Processing | PUT /maintenance/tickets/{id}/priority; log reason for override in ticket_notes; fires reassignment if priority changed to Critical |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Y1.1.1.1 — Staff/student selects category; description and location entered
- [ ] ST.Y1.1.1.2 — Photos can be uploaded; location (Room/Building) specified
- [ ] ST.Y1.1.2.1 — "water leakage" → priority auto-set to High
- [ ] ST.Y1.1.2.2 — Admin can manually override priority

---

### FR-MNT-004: Technician Assignment (F.Y1.2 — T.Y1.2.1)

**RBS Reference:** T.Y1.2.1 — Assign to Technician
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `mnt_tickets`, `mnt_ticket_assignments`

#### Requirements

**REQ-MNT-004.1: Auto Technician Assignment (ST.Y1.2.1.1)**
| Attribute | Detail |
|---|---|
| Description | System automatically assigns ticket to the best-available technician based on skill and workload |
| Processing | AssignmentService: 1) Filter sys_users by role matching category.auto_assign_role_id; 2) Exclude technicians with status=Unavailable or on leave; 3) Score by: (a) open_ticket_count ASC (workload), (b) location match bonus; 4) Assign top-scored technician; create mnt_ticket_assignments record |
| Output | Technician assigned; assignment visible on ticket |
| Status | 📐 Proposed |

**REQ-MNT-004.2: Manual Assignment / Reassignment**
| Attribute | Detail |
|---|---|
| Description | Maintenance Incharge manually assigns or reassigns ticket to a specific technician |
| Actors | School Admin, Maintenance Incharge |
| Input | ticket_id, assign_to_user_id, notes (reason for assignment/reassignment) |
| Processing | Create new mnt_ticket_assignments record (mark previous as Reassigned); log assignment event |
| Status | 📐 Proposed |

**REQ-MNT-004.3: Assignment Notification (ST.Y1.2.1.2)**
| Attribute | Detail |
|---|---|
| Description | Assigned technician receives immediate in-app push notification on assignment |
| Processing | Dispatch via Notification module: "New ticket assigned: [Title] — Location: [Room, Building] — Priority: [Level]" |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Y1.2.1.1 — Auto-assign based on skill (role match) and location
- [ ] ST.Y1.2.1.2 — Push notification sent to technician on assignment

---

### FR-MNT-005: Ticket Progress Tracking (F.Y1.2 — T.Y1.2.2)

**RBS Reference:** T.Y1.2.2 — Track Progress
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `mnt_tickets`, `mnt_ticket_time_logs`

#### Requirements

**REQ-MNT-005.1: Technician Status Updates (ST.Y1.2.2.1)**
| Attribute | Detail |
|---|---|
| Description | Assigned technician updates ticket status as work progresses |
| Actors | Technician |
| Preconditions | Ticket assigned to this technician; `tenant.mnt-ticket.update` permission |
| Allowed Transitions | Open → Accepted; Accepted → In_Progress; In_Progress → On_Hold; In_Progress → Resolved; On_Hold → In_Progress; Resolved → Closed (by admin) |
| Processing | Validate allowed transition (state machine); update status; log transition event; if Resolved: require resolution_notes; notify ticket requester |
| Status | 📐 Proposed |

**REQ-MNT-005.2: Time & Parts Logging (ST.Y1.2.2.2)**
| Attribute | Detail |
|---|---|
| Description | Technician logs time spent and materials/parts used while working on ticket |
| Actors | Technician, Maintenance Incharge |
| Input | ticket_id, logged_by (user_id), start_time, end_time, hours_spent (calculated), work_description, parts_used (text — free-form until Inventory module), parts_cost (decimal) |
| Processing | Create mnt_ticket_time_logs record; update ticket.total_hours_logged and total_parts_cost |
| Status | 📐 Proposed |

**REQ-MNT-005.3: Before/After Photo Upload (ST.Y1.2.2.2)**
| Attribute | Detail |
|---|---|
| Description | Technician attaches before (problem) and after (resolved) photos to ticket |
| Processing | Upload to sys_media with model_type=Maintenance\Ticket, model_id=ticket_id, collection_name=before/after |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Y1.2.2.1 — Technician can update status: Accepted, In Progress, On Hold, Resolved
- [ ] ST.Y1.2.2.2 — Time spent, parts used, resolution notes, and before/after photos logged

---

### FR-MNT-006: Preventive Maintenance Schedules (F.Y2.1)

**RBS Reference:** F.Y2.1 — Schedule PM Tasks; T.Y2.1.1 — Define PM Checklist
**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `mnt_pm_schedules`, `mnt_pm_work_orders`

#### Requirements

**REQ-MNT-006.1: Create PM Schedule (ST.Y2.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Admin defines preventive maintenance schedule for an asset with a checklist of tasks |
| Actors | School Admin, Maintenance Incharge |
| Preconditions | Asset exists; `tenant.mnt-pm-schedule.create` permission |
| Input | asset_id (FK mnt_assets), title (required), description, checklist_items_json (array of checklist task texts), recurrence (ENUM: Weekly/Monthly/Quarterly/Yearly), recurrence_day (e.g., 1 for Monthly=1st of month), start_date, assign_to_role_id (FK sys_roles), estimated_hours, is_active |
| Processing | Create PM schedule; calculate next_due_date based on start_date and recurrence |
| Output | PM schedule active; first work order generated |
| Status | 📐 Proposed |

**REQ-MNT-006.2: PM Work Order Generation (ST.Y2.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | System auto-generates PM work orders based on PM schedule recurrence |
| Processing | PmScheduleService (scheduled daily): query active pm_schedules WHERE next_due_date <= NOW(); for each: create mnt_pm_work_orders record; auto-assign to technician by assign_to_role_id; send notification; update schedule.next_due_date += recurrence interval; update schedule.last_generated_at |
| Status | 📐 Proposed |

**REQ-MNT-006.3: Track PM Work Order Completion (ST.Y2.1.2.2)**
| Attribute | Detail |
|---|---|
| Description | Technician marks PM work order checklist items as completed and closes work order |
| Actors | Technician |
| Input | pm_work_order_id, For each checklist item: is_completed (bool), notes (optional) |
| Processing | Update checklist_completion_json; if all items complete → status=Completed; update asset.last_pm_date, asset.current_condition |
| Output | PM work order closed; asset health updated |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.Y2.1.1.1 — PM checklist for generator, fire extinguisher, AC created with recurrence
- [ ] ST.Y2.1.1.2 — Recurrence options: Weekly, Monthly, Quarterly, Yearly
- [ ] ST.Y2.1.2.1 — Work orders auto-generated on schedule
- [ ] ST.Y2.1.2.2 — Work orders assigned and completion tracked

---

### FR-MNT-007: AMC Contract Management (Beyond RBS)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `mnt_amc_contracts`

#### Requirements

**REQ-MNT-007.1: Create AMC Contract**
| Attribute | Detail |
|---|---|
| Description | Admin records Annual Maintenance Contracts with vendors for school assets/systems |
| Actors | School Admin, Maintenance Incharge |
| Input | vendor_id (FK vnd_vendors), contract_title, scope_description (text), covered_assets_ids_json (array of mnt_assets.id), start_date (required), end_date (required), contract_value (decimal), payment_frequency (ENUM: Monthly/Quarterly/Yearly/One-time), visit_frequency (ENUM: Monthly/Quarterly/Weekly/On-demand), vendor_contact_name, vendor_contact_mobile, contract_document_media_id (FK sys_media) |
| Processing | Create contract; calculate days_until_expiry; if end_date within 30 days, flag for expiry alert |
| Output | AMC contract active; expiry date visible on dashboard |
| Status | 📐 Proposed |

**REQ-MNT-007.2: AMC Expiry Alerts**
| Attribute | Detail |
|---|---|
| Description | System alerts Maintenance Incharge 60 days, 30 days, and 7 days before AMC expiry |
| Processing | Scheduled job: query contracts WHERE end_date BETWEEN NOW() AND NOW() + 60 days AND last_alert_sent_days NOT IN (60,30,7); dispatch notification to Maintenance Incharge role; log alert sent |
| Status | 📐 Proposed |

---

### FR-MNT-008: Work Orders for External Vendors (Beyond RBS)

**Priority:** 🟡 Medium
**Status:** 📐 Proposed
**Table(s):** `mnt_work_orders`

#### Requirements

**REQ-MNT-008.1: Create Work Order**
| Attribute | Detail |
|---|---|
| Description | Maintenance Incharge creates a formal work order for external vendor to carry out repairs |
| Actors | School Admin, Maintenance Incharge |
| Input | ticket_id (optional — links to originating ticket), amc_contract_id (optional), vendor_id (FK vnd_vendors), work_description (required), scheduled_date, estimated_cost, purchase_order_number (optional), status (ENUM: Draft/Issued/In_Progress/Completed/Cancelled) |
| Processing | Create work order; auto-generate wo_number (MNT-WO-XXXXXX); notify vendor contact |
| Status | 📐 Proposed |

---

### FR-MNT-009: Maintenance Dashboard & Reports (Beyond RBS)

**Priority:** 🟡 Medium
**Status:** 📐 Proposed

#### Requirements

**REQ-MNT-009.1: Dashboard KPIs**
| Metric | Detail |
|---|---|
| Open Tickets | Count by priority (Critical/High/Medium/Low) with trend |
| SLA Breached | Tickets past expected resolution time |
| Tickets Resolved Today | Today's closed count |
| PM Due This Week | PM work orders due in next 7 days |
| AMC Expiring Soon | Contracts expiring in 60 days |
| Technician Workload | Open tickets per technician (bar chart) |

**REQ-MNT-009.2: Standard Reports**
| Report | Description |
|---|---|
| Ticket Summary Report | Date-range ticket counts by category, priority, status |
| SLA Performance Report | % tickets resolved within SLA; avg resolution time |
| Technician Productivity | Tickets per technician: assigned, resolved, avg resolution time |
| Asset Maintenance History | Per-asset: all tickets, PM work orders, cost summary |
| PM Compliance Report | PM work orders: scheduled vs completed vs overdue |

---

## 5. Data Model

### 5.1 Proposed Tables

> All tables use standard audit columns: `id`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK→sys_users`, `created_at`, `updated_at`, `deleted_at`.

---

#### 📐 `mnt_asset_categories`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL UNIQUE | Category name |
| code | VARCHAR(20) | UNIQUE NULL | Short code |
| description | TEXT | NULL | |
| default_priority | ENUM('Low','Medium','High','Critical') | DEFAULT 'Medium' | |
| sla_hours | SMALLINT UNSIGNED | DEFAULT 24 | Target resolution hours |
| auto_assign_role_id | INT UNSIGNED | NULL FK→sys_roles | Default assignment role |
| priority_keywords_json | JSON | NULL | {"High": ["water leakage",...], "Critical":[...]} |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `mnt_assets`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| asset_code | VARCHAR(30) | NOT NULL UNIQUE | MNT-AST-XXXXXX |
| name | VARCHAR(150) | NOT NULL | Asset name |
| category_id | INT UNSIGNED | NOT NULL FK→mnt_asset_categories | |
| location_building | VARCHAR(100) | NULL | |
| location_floor | VARCHAR(20) | NULL | |
| location_room | VARCHAR(50) | NULL | |
| purchase_date | DATE | NULL | |
| purchase_cost | DECIMAL(12,2) | NULL | |
| warranty_expiry_date | DATE | NULL | |
| current_condition | ENUM('Good','Fair','Poor','Critical','Decommissioned') | DEFAULT 'Good' | |
| last_pm_date | DATE | NULL | Updated on PM work order completion |
| next_pm_due_date | DATE | NULL | Calculated from PM schedule |
| amc_contract_id | INT UNSIGNED | NULL FK→mnt_amc_contracts | Active AMC if any |
| notes | TEXT | NULL | |
| photo_media_id | INT UNSIGNED | NULL FK→sys_media | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `mnt_tickets`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| ticket_number | VARCHAR(30) | NOT NULL UNIQUE | MNT-YYYY-XXXXXXXX |
| title | VARCHAR(200) | NOT NULL | |
| category_id | INT UNSIGNED | NOT NULL FK→mnt_asset_categories | |
| asset_id | INT UNSIGNED | NULL FK→mnt_assets | Specific asset if known |
| description | TEXT | NOT NULL | |
| location_building | VARCHAR(100) | NOT NULL | |
| location_floor | VARCHAR(20) | NULL | |
| location_room | VARCHAR(50) | NULL | |
| priority | ENUM('Low','Medium','High','Critical') | NOT NULL | |
| priority_source | ENUM('Auto_Keyword','Auto_Category','Manual_Override') | DEFAULT 'Auto_Category' | |
| status | ENUM('Open','Accepted','In_Progress','On_Hold','Resolved','Closed','Cancelled') | DEFAULT 'Open' | |
| requester_user_id | INT UNSIGNED | NOT NULL FK→sys_users | Who raised the ticket |
| assigned_to_user_id | INT UNSIGNED | NULL FK→sys_users | Current technician |
| requested_date | DATE | NOT NULL | |
| accepted_at | TIMESTAMP | NULL | |
| resolved_at | TIMESTAMP | NULL | |
| closed_at | TIMESTAMP | NULL | |
| sla_due_at | TIMESTAMP | NULL | requested_date + category.sla_hours |
| is_sla_breached | TINYINT(1) | DEFAULT 0 | |
| resolution_notes | TEXT | NULL | |
| total_hours_logged | DECIMAL(6,2) | DEFAULT 0.00 | |
| total_parts_cost | DECIMAL(10,2) | DEFAULT 0.00 | |
| requester_rating | TINYINT UNSIGNED | NULL | 1–5 star rating from requester |
| requester_feedback | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

INDEX on `(status, priority)`, `(assigned_to_user_id, status)`, `(category_id, status)`, `(sla_due_at)`

---

#### 📐 `mnt_ticket_assignments`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| ticket_id | INT UNSIGNED | NOT NULL FK→mnt_tickets | |
| assigned_to_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| assigned_by_user_id | INT UNSIGNED | NULL FK→sys_users | NULL = system auto-assign |
| assignment_type | ENUM('Auto','Manual','Reassigned') | DEFAULT 'Auto' | |
| notes | TEXT | NULL | |
| is_current | TINYINT(1) | DEFAULT 1 | Only one current assignment per ticket |
| assigned_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| released_at | TIMESTAMP | NULL | When reassigned |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

INDEX on `(ticket_id, is_current)`, `(assigned_to_user_id, is_current)`

---

#### 📐 `mnt_ticket_time_logs`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| ticket_id | INT UNSIGNED | NOT NULL FK→mnt_tickets | |
| logged_by_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| work_date | DATE | NOT NULL | |
| start_time | TIME | NULL | |
| end_time | TIME | NULL | |
| hours_spent | DECIMAL(5,2) | NOT NULL | |
| work_description | TEXT | NULL | |
| parts_used | TEXT | NULL | Free-form until Inventory module |
| parts_cost | DECIMAL(10,2) | DEFAULT 0.00 | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

---

#### 📐 `mnt_pm_schedules`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| asset_id | INT UNSIGNED | NOT NULL FK→mnt_assets | |
| title | VARCHAR(200) | NOT NULL | |
| description | TEXT | NULL | |
| checklist_items_json | JSON | NOT NULL | Array of checklist task strings |
| recurrence | ENUM('Daily','Weekly','Monthly','Quarterly','Yearly') | NOT NULL | |
| recurrence_day | TINYINT UNSIGNED | NULL | Day of week/month for schedule |
| start_date | DATE | NOT NULL | |
| next_due_date | DATE | NOT NULL | |
| last_generated_at | DATE | NULL | |
| assign_to_role_id | INT UNSIGNED | NULL FK→sys_roles | |
| estimated_hours | DECIMAL(4,2) | NULL | |
| category_id | INT UNSIGNED | NOT NULL FK→mnt_asset_categories | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `mnt_pm_work_orders`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| pm_schedule_id | INT UNSIGNED | NOT NULL FK→mnt_pm_schedules | |
| asset_id | INT UNSIGNED | NOT NULL FK→mnt_assets | |
| wo_number | VARCHAR(30) | NOT NULL UNIQUE | MNT-PM-XXXXXX |
| due_date | DATE | NOT NULL | |
| assigned_to_user_id | INT UNSIGNED | NULL FK→sys_users | |
| status | ENUM('Pending','In_Progress','Completed','Overdue','Cancelled') | DEFAULT 'Pending' | |
| checklist_completion_json | JSON | NULL | {item_index: {completed, notes}} |
| completed_at | TIMESTAMP | NULL | |
| completed_by_user_id | INT UNSIGNED | NULL FK→sys_users | |
| hours_spent | DECIMAL(5,2) | NULL | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `mnt_amc_contracts`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| contract_number | VARCHAR(50) | NOT NULL UNIQUE | |
| contract_title | VARCHAR(200) | NOT NULL | |
| vendor_id | INT UNSIGNED | NULL FK→vnd_vendors | |
| vendor_name | VARCHAR(150) | NULL | Denorm if vendor module not used |
| vendor_contact_name | VARCHAR(100) | NULL | |
| vendor_contact_mobile | VARCHAR(20) | NULL | |
| scope_description | TEXT | NULL | What is covered |
| covered_assets_ids_json | JSON | NULL | Array of mnt_assets.id |
| start_date | DATE | NOT NULL | |
| end_date | DATE | NOT NULL | |
| contract_value | DECIMAL(12,2) | NULL | |
| payment_frequency | ENUM('Monthly','Quarterly','Yearly','One_time') | NULL | |
| visit_frequency | ENUM('Weekly','Monthly','Quarterly','On_demand') | NULL | |
| contract_document_media_id | INT UNSIGNED | NULL FK→sys_media | |
| status | ENUM('Active','Expired','Cancelled','Pending_Renewal') | DEFAULT 'Active' | |
| renewal_alert_sent_60 | TINYINT(1) | DEFAULT 0 | |
| renewal_alert_sent_30 | TINYINT(1) | DEFAULT 0 | |
| renewal_alert_sent_7 | TINYINT(1) | DEFAULT 0 | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `mnt_work_orders`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| wo_number | VARCHAR(30) | NOT NULL UNIQUE | MNT-WO-XXXXXX |
| ticket_id | INT UNSIGNED | NULL FK→mnt_tickets | Source ticket if any |
| amc_contract_id | INT UNSIGNED | NULL FK→mnt_amc_contracts | |
| vendor_id | INT UNSIGNED | NULL FK→vnd_vendors | |
| vendor_name | VARCHAR(150) | NULL | Denorm fallback |
| work_description | TEXT | NOT NULL | |
| scheduled_date | DATE | NULL | |
| completed_date | DATE | NULL | |
| estimated_cost | DECIMAL(10,2) | NULL | |
| actual_cost | DECIMAL(10,2) | NULL | |
| purchase_order_number | VARCHAR(50) | NULL | |
| status | ENUM('Draft','Issued','In_Progress','Completed','Cancelled') | DEFAULT 'Draft' | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

### 5.2 Entity Relationships

```
mnt_asset_categories ──── mnt_assets ──── mnt_pm_schedules ──── mnt_pm_work_orders
                               │
                          mnt_amc_contracts ──── vnd_vendors
                               │
mnt_tickets ────────────── mnt_asset_categories
     │
     ├── mnt_ticket_assignments ──── sys_users (technician)
     ├── mnt_ticket_time_logs ──── sys_users
     └── sys_media (before/after photos)

mnt_work_orders ──── mnt_tickets (optional source)
                └──── mnt_amc_contracts
```

---

## 6. Controller & Route Inventory

| Controller | Route Prefix | Named Prefix | Key Methods |
|---|---|---|---|
| 📐 MaintenanceController | /maintenance | mnt | dashboard, index |
| 📐 AssetCategoryController | /maintenance/asset-categories | mnt.asset-categories | CRUD + toggleStatus |
| 📐 AssetController | /maintenance/assets | mnt.assets | CRUD + condition update |
| 📐 TicketController | /maintenance/tickets | mnt.tickets | CRUD + updateStatus, updatePriority, addTimeLog, rateTicket, assign |
| 📐 WorkOrderController | /maintenance/work-orders | mnt.work-orders | CRUD + updateStatus |
| 📐 PmScheduleController | /maintenance/pm-schedules | mnt.pm-schedules | CRUD + generateWorkOrder, viewWorkOrders |
| 📐 AmcContractController | /maintenance/amc-contracts | mnt.amc-contracts | CRUD + renewContract |
| 📐 MaintenanceReportController | /maintenance/reports | mnt.reports | ticketSummary, sla, technician, assetHistory, pmCompliance |

**Estimated total named routes:** ~58

---

## 7. Form Request Validation Rules

| FormRequest | Key Rules |
|---|---|
| 📐 StoreAssetCategoryRequest | name required\|max:100\|unique; sla_hours required\|integer\|min:1; default_priority required\|in:Low,Medium,High,Critical |
| 📐 StoreAssetRequest | name required\|max:150; category_id required\|exists:mnt_asset_categories,id; asset_code nullable\|unique:mnt_assets,asset_code |
| 📐 StoreTicketRequest | title required\|max:200; category_id required\|exists:mnt_asset_categories,id; description required\|min:20; location_building required |
| 📐 UpdateTicketStatusRequest | status required\|in:Accepted,In_Progress,On_Hold,Resolved; resolution_notes required_if:status,Resolved |
| 📐 StoreTimeLogRequest | ticket_id required\|exists:mnt_tickets,id; hours_spent required\|numeric\|min:0.25\|max:24; work_date required\|date\|lte:today |
| 📐 StorePmScheduleRequest | asset_id required\|exists:mnt_assets,id; recurrence required\|in:Daily,Weekly,Monthly,Quarterly,Yearly; start_date required\|date; checklist_items_json required\|array\|min:1 |
| 📐 StoreAmcContractRequest | vendor_name required\|max:150; start_date required\|date; end_date required\|date\|after:start_date; contract_value nullable\|numeric\|min:0 |
| 📐 AssignTicketRequest | ticket_id required\|exists:mnt_tickets,id; assign_to_user_id required\|exists:sys_users,id |

---

## 8. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-MNT-001 | Ticket number is auto-generated in format MNT-YYYY-XXXXXXXX with sequential serial and lock-for-update to prevent duplicates. |
| BR-MNT-002 | SLA due time = ticket.requested_date + category.sla_hours. Scheduled job checks every hour and sets is_sla_breached=1 when SLA due time is past and ticket not Resolved/Closed. |
| BR-MNT-003 | Status transitions are enforced as a state machine: Open→Accepted→In_Progress→(On_Hold↔In_Progress)→Resolved→Closed. Invalid transitions are rejected with 422. |
| BR-MNT-004 | Resolution notes are required when status is updated to Resolved. |
| BR-MNT-005 | Auto-assignment may leave ticket unassigned if no technician is available; ticket stays in Open status and Maintenance Incharge is notified for manual assignment. |
| BR-MNT-006 | PM work orders auto-generated daily for schedules with next_due_date <= today. Only one pending PM work order can exist per pm_schedule at a time. |
| BR-MNT-007 | AMC expiry alerts fire at 60, 30, and 7 days before end_date. Each alert fires only once (tracked via renewal_alert_sent_* flags). |
| BR-MNT-008 | Technician can only update tickets assigned to them (is_current=1 in mnt_ticket_assignments). Admin/Maintenance Incharge can update any ticket. |
| BR-MNT-009 | Keyword priority matching uses case-insensitive LIKE matching against ticket description text. Critical takes precedence over High over Medium over Low. |
| BR-MNT-010 | Before photos are required when status changes to In_Progress; after photos are required when status changes to Resolved. (Configurable per school setting.) |

---

## 9. Permission & Authorization Model

| Permission Slug | Description |
|---|---|
| tenant.mnt-asset-category.view | View asset categories |
| tenant.mnt-asset-category.manage | Create/edit/delete categories |
| tenant.mnt-asset.view | View asset register |
| tenant.mnt-asset.manage | Create/edit/delete assets |
| tenant.mnt-ticket.create | Raise maintenance tickets |
| tenant.mnt-ticket.view | View all tickets |
| tenant.mnt-ticket.update | Update tickets (own assignments) |
| tenant.mnt-ticket.manage | Update any ticket, assign, override priority |
| tenant.mnt-pm-schedule.manage | Create/edit PM schedules |
| tenant.mnt-amc-contract.manage | Create/edit AMC contracts |
| tenant.mnt-work-order.manage | Create/manage work orders |
| tenant.mnt-report.view | View maintenance reports |

**Role Assignments:**
- School Admin: all mnt permissions
- Maintenance Incharge: all mnt permissions except some admin-only settings
- Technician: ticket.view (assigned), ticket.update (assigned), pm-work-order (own)
- Teacher/Staff: ticket.create (own tickets)
- Student: ticket.create (limited — common areas only)

---

## 10. Tests Inventory

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | 📐 TicketCreationTest | Feature | Create ticket; auto priority from keyword | Critical |
| 2 | 📐 AutoAssignmentTest | Feature | Ticket assigned to role-matching technician with lowest workload | High |
| 3 | 📐 TicketStatusTransitionTest | Feature | Valid and invalid state transitions enforced | Critical |
| 4 | 📐 SlaBreachTest | Feature | SLA timer crosses; is_sla_breached set to 1 | High |
| 5 | 📐 TimeLogTest | Feature | Time log adds to ticket.total_hours_logged | High |
| 6 | 📐 PmWorkOrderGenerationTest | Feature | PM schedule next_due_date past → work order auto-created | High |
| 7 | 📐 AmcExpiryAlertTest | Feature | AMC expiry within 30 days → alert notification dispatched | Medium |
| 8 | 📐 ResolutionNotesRequiredTest | Feature | Resolve status without notes → rejected 422 | High |
| 9 | 📐 TechnicianAuthorizationTest | Feature | Technician cannot update ticket assigned to another technician | Critical |
| 10 | 📐 PmChecklistCompletionTest | Feature | All checklist items complete → work order status=Completed | Medium |

---

## 11. Known Issues & Technical Debt

| ID | Issue | Severity | Notes |
|---|---|---|---|
| 📐 | Parts used tracking is free-text; no actual deduction from inventory | Medium | Link to Inventory module when built |
| 📐 | Auto-assignment does not check guard/technician leave calendar | Medium | Integrate with HR leave module when built |
| 📐 | SLA breach job must use school timezone from sys_school_settings | High | Timezone-aware Carbon calculations required |
| 📐 | Keyword matching is basic LIKE; no stemming or NLP | Low | Acceptable for v1; NLP in future version |
| 📐 | mnt_work_orders vendor_name denorm field may go out of sync with vnd_vendors | Low | Use vendor_id FK when Vendor module confirmed |

---

## 12. API Endpoints

| Method | URI | Name | Description |
|---|---|---|---|
| 📐 GET | /api/v1/maintenance/tickets | api.mnt.tickets.index | List tickets (technician's own) |
| 📐 PUT | /api/v1/maintenance/tickets/{id}/status | api.mnt.tickets.status | Update ticket status (mobile app) |
| 📐 POST | /api/v1/maintenance/tickets/{id}/time-log | api.mnt.tickets.timelog | Add time log entry |
| 📐 GET | /api/v1/maintenance/pm-work-orders | api.mnt.pm.index | List PM work orders for technician |
| 📐 PUT | /api/v1/maintenance/pm-work-orders/{id}/complete | api.mnt.pm.complete | Complete PM work order |

All API endpoints: middleware `auth:sanctum`, prefix `/api/v1/maintenance`

---

## 13. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Ticket list with filters must load in < 2 seconds for up to 10,000 tickets (indexed query) |
| Concurrency | Ticket number generation uses DB lock to prevent duplicate ticket_numbers under concurrent creation |
| Security | Technician can only view/update tickets assigned to them; gate enforced via Policy |
| Audit | All status transitions and assignments logged to sys_activity_logs |
| PDF | Ticket work order and PM work order printable via DomPDF |
| Scalability | Composite index on (status, priority) for dashboard KPI queries |
| Notifications | All technician assignment and SLA breach notifications dispatched via Notification module queue |

---

## 14. Integration Points

| Module | Integration Type | Details |
|---|---|---|
| Notification (ntf_*) | Dispatch | Assignment alerts, SLA breach alerts, AMC expiry alerts |
| Vendor (vnd_*) | Read FK | Vendor linked to AMC contracts and external work orders |
| SchoolSetup (sch_*) | Read | School timezone for SLA calculations |
| sys_media | Write | Before/after photos stored via sys_media |
| sys_users | Read FK | Technician assignments, requester tracking |
| sys_roles | Read | Auto-assignment by role (mnt_asset_categories.auto_assign_role_id) |
| Inventory (future) | Future FK | Parts used in tickets linked to inventory deduction |
| StudentPortal (STP) | Future | Students raise maintenance requests via portal |

---

## 15. Pending Work & Gap Analysis

### 15.1 Development Roadmap

| Phase | Tasks | Priority |
|---|---|---|
| Phase 1 — Setup | Migrations (9 tables), Models (9), Providers | Critical |
| Phase 2 — Categories & Assets | AssetCategory CRUD with keyword rules, Asset register | Critical |
| Phase 3 — Ticketing Core | Ticket CRUD, auto-priority, auto-assignment, notifications | Critical |
| Phase 4 — Ticket Lifecycle | Status transitions, time logging, before/after photos | Critical |
| Phase 5 — Dashboard | KPI dashboard, SLA breach job, overdue alerts | High |
| Phase 6 — PM Schedules | PM schedule CRUD, work order generation job | High |
| Phase 7 — AMC Contracts | AMC CRUD, expiry alert job | High |
| Phase 8 — Work Orders | External vendor work orders | Medium |
| Phase 9 — Reports | Ticket summary, SLA, technician productivity reports | Medium |

### 15.2 Open Design Decisions

| Decision | Options | Recommendation |
|---|---|---|
| Photo upload required on status change | Mandatory vs optional | Configurable per school via sys_school_settings |
| Requester rating | Yes/No after ticket closure | Yes — simple 1-5 star rating on closure notification |
| PM auto-assignment | By role vs by specific user | By role (auto_assign_role_id) with workload balancing |
| SLA calculation basis | Hours from requested_date vs business hours only | Clock hours for v1; business-hours option in v2 |

---

*RBS Reference: Module Y — Maintenance & Facility Helpdesk (ST.Y1.1.1.1 – ST.Y2.1.2.2)*
*Document generated: 2026-03-25 | Status: Greenfield — All features 📐 Proposed*
