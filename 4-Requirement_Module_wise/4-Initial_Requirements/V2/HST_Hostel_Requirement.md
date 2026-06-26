# Hostel Module — Requirement Specification Document v2
**Version:** 2.0  |  **Date:** 2026-03-26  |  **Author:** Claude Code (Automated)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HST  |  **Module Path:** `📐 Proposed: Modules/Hostel/`
**Module Type:** Tenant  |  **Database:** `📐 Proposed: tenant_db`
**Table Prefix:** `hst_*`  |  **Processing Mode:** RBS_ONLY
**RBS Reference:** K (Hostel Management)  |  **RBS Version:** v4.0
**V1 Baseline:** `2-Requirement_Module_wise/2-Detailed_Requirements/V1/Dev_Pending/HST_Hostel_Requirement.md`
**Gap Analysis:** N/A (Greenfield module)
**Generation Batch:** 8/10

> All features are **❌ Not Started**. All proposed items are marked **📐**.

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model — Proposed DDL](#5-data-model--proposed-ddl)
6. [Routes](#6-routes)
7. [Non-Functional Requirements](#7-non-functional-requirements)
8. [Business Rules](#8-business-rules)
9. [Workflows](#9-workflows)
10. [Authorization and RBAC](#10-authorization-and-rbac)
11. [Integration Points](#11-integration-points)
12. [Service Layer Architecture](#12-service-layer-architecture)
13. [Test Coverage](#13-test-coverage)
14. [Implementation Status](#14-implementation-status)
15. [Known Issues and Technical Debt](#15-known-issues-and-technical-debt)
16. [Development Priorities and Recommendations](#16-development-priorities-and-recommendations)

---

## 1. Module Overview

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Hostel Management |
| Module Code | HST |
| nwidart Module Namespace | `📐 Modules\Hostel` |
| Module Path | `📐 Modules/Hostel/` |
| Route Prefix | `📐 hostel/` |
| Route Name Prefix | `📐 hostel.` |
| DB Table Prefix | `hst_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `📐 routes/tenant.php` |
| RBS Reference | K — Hostel Management (K1–K6) |
| Status | 📐 Greenfield — Not Started |

### 1.2 Module Scale (Proposed)

| Metric | Count |
|---|---|
| Controllers | 📐 15 |
| Models | 📐 20 |
| Services | 📐 7 |
| FormRequests | 📐 18 |
| Policies | 📐 12 |
| DDL Tables | 📐 20 (`hst_*` prefix) |
| Views (Blade) | 📐 ~65 templates |
| Seeders | 📐 2 (RoomTypes, IncidentTypes) |
| Events | 📐 4 |
| Jobs (Queued) | 📐 2 |

### 1.3 V1 → V2 Delta Summary

| Area | V1 (2026-03-25) | V2 Addition |
|---|---|---|
| Tables | 15 | 20 (+5: `hst_fee_structures`, `hst_special_diets`, `hst_warden_assignments`, `hst_visitor_log`, `hst_sick_bay_log`) |
| Sub-modules | K1–K4 (partial K5) | K1–K6 fully specified + Warden Mgmt + Visitor Log + Medical/Sick Bay |
| Routes | ~40 | ~65 |
| Workflows | Leave pass only | 4 full workflows (Allocation, Leave, Complaint, Sick Bay) |
| Integration | 4 touch-points | 7 touch-points (added Complaint, HPC, Notification detail) |

---

## 2. Business Context

### 2.1 Business Purpose

Residential schools (boarding schools) in India house 50–2,000 students on campus. The Hostel module solves:

1. **Room & Bed Tracking**: Centralized allocation; vacancy and waitlist management; room-type-based billing.
2. **Student Safety**: Daily roll call (morning / evening / night) is a legal and safety requirement. Late entries and unexplained absences must be flagged immediately and parents notified.
3. **Leave Pass Control**: Students leaving campus require formal leave passes with guardian authorization; the system enforces the approval chain.
4. **Discipline Records**: Incident tracking required for CBSE boarding inspection; 3+ incidents triggers automatic escalation to Principal.
5. **Mess Visibility**: Weekly menu planning, special diet assignment, meal attendance — monthly mess count feeds into billing.
6. **Hostel Fee Recovery**: Room rent, mess charges, electricity, laundry, and security deposit systematically linked to StudentFee module.
7. **Occupancy Analytics**: Occupancy rates by building/floor/room type for infrastructure planning and fee revision.
8. **Warden Hierarchy**: Chief Warden → Block Warden → Floor Incharge — each with scoped access to their assigned areas only.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| School Admin / Principal | Full hostel access; policy configuration; final escalation |
| Chief Warden | Full hostel operations; approve/reject leave passes; incident escalation |
| Block Warden / Assistant Warden | Block-level attendance, leave pass approval, incident recording |
| Mess Supervisor | Meal plan setup, weekly menu, mess attendance marking |
| Accountant | Hostel fee view, prorated calculation review, defaulter report |
| Medical / Sick Bay Staff | Sick bay admission, discharge, basic health notes |
| Student (Portal — Phase 2) | View own allotment, apply for leave pass, view mess menu |
| Parent (Portal — Phase 2) | View child's leave pass status, receive alerts, view attendance |

### 2.3 Indian Residential School Context

- **Hostel Types**: Boys' Hostel, Girls' Hostel (strictly segregated); mixed only for day-boarding edge cases
- **Boarding Population**: 50–2,000 boarders depending on school tier
- **Warden Hierarchy**: Chief Warden → Block Warden → Floor Incharge (often teaching staff on rotation)
- **Attendance Cadence**: 3 roll calls daily — morning assembly (06:30), dinner (19:00), lights-out check (21:30)
- **Leave Types**: Weekly home leave, emergency leave, medical leave, festival/vacation leave
- **Mess Structure**: Centralised mess; breakfast + lunch + dinner + snacks; special diets for diabetic, Jain, allergies, religious fasting
- **Fee Components**: Room rent (by room type), mess charges (per meal plan), electricity/water, laundry, security deposit
- **Hostel Inventory**: Each room has beds, mattresses, study tables, chairs, cupboards — damage reporting required
- **Sick Bay**: Small medical room on hostel premises for minor illness; serious cases referred to hospital
- **Visitor Register**: Parents/guardians visiting on visiting days recorded; outsider entry controlled
- **Regulatory Context**: CBSE boarding school inspection requires attendance registers, leave registers, incident logs, and occupancy reports

---

## 3. Scope and Boundaries

### 3.1 In Scope

- Hostel infrastructure: buildings, floors, rooms, beds (Building → Floor → Room → Bed hierarchy)
- Gender-based allocation restrictions (boys'/girls' hostel)
- Room type configuration (single, double, triple, dormitory) with capacity rules and fee rates
- Student allotment to specific beds with academic year scoping
- Room change request workflow (student request → warden approval → transfer execution)
- Warden assignment: chief warden to hostel, block warden to block, with scoped data access
- Daily attendance (morning/evening/night) with shift-wise marking and bulk-mark capability
- In-out movement register (gate pass: departure time, return time, destination)
- Leave pass workflow: application → parent/guardian consent → warden approval → execution → return confirmation
- Late return detection and automatic incident creation
- Mess meal plan (weekly menu per hostel per academic session)
- Special diet assignment per student (diabetic, Jain, gluten-free, religious, allergies)
- Mess attendance marking per meal per student (opt-out auto-applied on approved leave)
- Hostel fee structure: room-type rates, mess rates, ancillary charges per academic session
- Prorated fee calculation for mid-month allotment, room change, or mid-month vacating
- Fee integration: push hostel fee demand to StudentFee module (fin_fee_head_master)
- Hostel complaint register: maintenance requests, complaint tracking (parallel to Complaint module)
- Discipline incident management with severity classification and escalation
- Warning letter PDF generation (DomPDF)
- Parent notification: on check-in, check-out, leave approval, late return, incident (moderate/serious), attendance below threshold
- Room inventory tracking: furniture, fixtures, condition, damage reporting, cost recovery
- Visitor log: parents/guardians visiting on designated visiting days
- Medical / sick bay log: admission, discharge, diagnosis, basic treatment notes
- Dashboard: live occupancy, today's attendance summary, pending leave passes, open incidents, pending returns, sick bay occupancy
- Reports: 12 report types with PDF/CSV export

### 3.2 Out of Scope

- Student academic profile, class, marks — **StudentProfile module** (`std_*`)
- School fee collection, payment gateway, receipts — **StudentFee module** (`fin_*`)
- Full medical records, hospital visits, health conditions — **HPC module** (sick bay log is HST-internal; serious cases link to HPC)
- School canteen for day scholars — **Mess Management module** (`mes_*`) when applicable
- Campus-wide visitor management — **Frontdesk module** (`fnt_*`)
- Staff accommodation / quarters management
- CCTV / access control hardware integration
- Laundry management beyond simple fee charging

---

## 4. Functional Requirements

### 4.1 K1 — Room & Bed Management

**RBS Ref:** K1 — Building → Floor → Room → Bed hierarchy with occupancy tracking

#### FR-HST-001: Building / Hostel Configuration 📐

- 📐 **Create Hostel/Building**: Name (required, max 150 chars), type (`boys` / `girls` / `mixed`), address (VARCHAR 500), total capacity (auto-computed from beds or manually overridden), chief warden assignment (FK → sys_users, nullable), contact phone, facilities list (JSON array — WiFi, Common Room, Indoor Sports, Medical Room, Laundry, etc.)
- 📐 **Multiple Hostels**: A school may operate multiple hostels (separate boys'/girls' buildings; old block/new block)
- 📐 **Hostel Deactivation**: Soft-delete with audit log; blocked if active allotments exist
- 📐 **Capacity Auto-Compute**: `total_capacity` recomputed whenever beds are added/removed/changed to maintenance

#### FR-HST-002: Floor Management 📐

- 📐 **Create Floor**: Floor number (1-based), display name (e.g., "Ground Floor", "First Floor"), hostel reference, floor incharge assignment (FK → sys_users, nullable)
- 📐 **Floor within Hostel**: Floors belong directly to hostels (RBS v4 hierarchy: Building → Floor → Room → Bed — no intermediate "Block" required; blocks are modelled as separate hostels or as floors with a `wing` label)
- 📐 **Floor Deactivation**: Soft delete; blocked if active rooms on floor

#### FR-HST-003: Room Setup 📐

- 📐 **Create Room**: Room number (unique within hostel+floor), floor reference, room type (single/double/triple/dormitory), capacity (beds), amenities JSON (AC, attached bath, ceiling fan, window, WiFi port), status (available/full/maintenance)
- 📐 **Gender Restriction**: Room inherits hostel gender; boys' hostel rooms cannot be allotted to girls
- 📐 **Priority Flags**: Medical priority, senior students, merit allocation flags (JSON)
- 📐 **Room Status Auto-Update**: Status → `full` when `current_occupancy >= capacity`; → `available` when occupancy drops below capacity
- 📐 **Room Type Master**: Configurable room types seeded as system reference; schools may add custom types via settings

#### FR-HST-004: Bed Management 📐

- 📐 **Create Bed**: Bed label within room (e.g., Bed A, Bed 1), condition (good/fair/poor/under_maintenance)
- 📐 **Bed Status Tracking**: `available` → `occupied` on allotment; `occupied` → `available` on vacating; manual `maintenance` flag
- 📐 **Maintenance Flag**: Mark individual beds as under maintenance; blocked from new allotments

| RBS Sub-Task | Status |
|---|---|
| ST.K1.1 — Define building name, type, address | 📐 Not Started |
| ST.K1.2 — Assign chief warden | 📐 Not Started |
| ST.K1.3 — Define floors within building | 📐 Not Started |
| ST.K1.4 — Define room number/type/capacity | 📐 Not Started |
| ST.K1.5 — Set gender restriction on rooms | 📐 Not Started |
| ST.K1.6 — Create and label beds | 📐 Not Started |
| ST.K1.7 — Track bed availability status | 📐 Not Started |

---

### 4.2 K2 — Student Room Allocation

**RBS Ref:** K2 — Assign students to rooms, roommate management, room swap/transfer

#### FR-HST-005: Student Bed Allotment 📐

- 📐 **Allot Student to Bed**: Select student (FK → std_students), hostel → floor → room → bed, allotment date, academic session scoping, meal plan selection, status = `active`
- 📐 **Availability Check**: System prevents double-allotment — one active allotment per bed at a time; also prevents student from having two active allotments
- 📐 **Gender Validation**: Student gender (from std_students) must match hostel type before allotment is created
- 📐 **Fee Auto-Calculation**: On allotment, `HostelFeeService` computes applicable hostel fee (room rate + mess rate + ancillary) and pushes to StudentFee module
- 📐 **Vacating**: Record vacating date, reason; bed status → available; allotment status → `vacated`; prorated refund triggered if mid-month
- 📐 **Transfer**: Move student to another bed; old allotment → `transferred`; new allotment created; fee differential calculated
- 📐 **Academic Year Reset**: Bulk-vacate wizard with confirmation dialog; creates audit log entry; cannot be undone
- 📐 **Waitlist**: If preferred room is full, student can be placed on waitlist; auto-notified when bed becomes available

#### FR-HST-006: Room Change Request Workflow 📐

- 📐 **Submit Request**: Student/staff submits room change request — current allotment, preferred target room (optional), reason (text)
- 📐 **Warden Review**: Block Warden or Chief Warden approves or rejects; rejection requires reason text
- 📐 **On Approval**: System calls `AllotmentService::transfer()` — vacates old bed, creates new allotment in target bed; fee recalculation triggered
- 📐 **History**: Full history of room change requests per student per academic year

| RBS Sub-Task | Status |
|---|---|
| ST.K2.1 — Select student and assign bed | 📐 Not Started |
| ST.K2.2 — Enforce gender validation | 📐 Not Started |
| ST.K2.3 — Vacate allotment | 📐 Not Started |
| ST.K2.4 — Transfer to different room | 📐 Not Started |
| ST.K2.5 — Room change request workflow | 📐 Not Started |
| ST.K2.6 — Academic year bulk reset | 📐 Not Started |
| ST.K2.7 — Waitlist management | 📐 Not Started |

---

### 4.3 K3 — Hostel Attendance

**RBS Ref:** K3 — Daily check-in/out, leave tracking (weekend/home leave)

#### FR-HST-007: Hostel Daily Roll Call Attendance 📐

- 📐 **Create Attendance Session**: For a hostel, on a specific date, for a shift (morning/evening/night); marked by named warden; one session per (hostel, date, shift) — duplicate blocked
- 📐 **Mark Attendance**: Per student — present / absent / leave (on approved leave pass) / home (weekend home leave) / late
- 📐 **Late Entry Remarks**: Capture textual remarks for late arrivals; timestamp of actual check-in
- 📐 **Bulk Mark Present**: Mark all active boarders present, then individually correct exceptions (efficiency for large hostels)
- 📐 **Attendance Lock**: Once saved, editable only by Chief Warden within 24 hours; locked thereafter
- 📐 **Absent Alert**: Students marked absent (not on leave) trigger immediate notification to parent and alert on warden dashboard
- 📐 **Attendance Threshold Alert**: Students with attendance below configurable threshold (default 90%) over trailing 30 days highlighted on dashboard
- 📐 **Summary Statistics**: `hst_attendance` session record stores `present_count`, `absent_count`, `leave_count`, `late_count` (computed at save time to avoid aggregation on every report load)

#### FR-HST-008: In-Out Movement Register 📐

- 📐 **Log Out-Movement**: Record student, out-time, destination, expected return time, gate pass issued by (warden)
- 📐 **Log In-Movement**: Record actual return time when student returns to hostel
- 📐 **Pending Returns Dashboard**: Real-time list of students who went out and have not returned past expected return time; parent notification triggered if overdue by configurable threshold (default 30 min)
- 📐 **Movement Register Report**: Date-wise, student-wise log of all movements with out/in times

| RBS Sub-Task | Status |
|---|---|
| ST.K3.1 — Create shift attendance session | 📐 Not Started |
| ST.K3.2 — Mark present/absent/leave/late | 📐 Not Started |
| ST.K3.3 — Capture late entry remarks | 📐 Not Started |
| ST.K3.4 — Attendance threshold alert | 📐 Not Started |
| ST.K3.5 — In-out movement log | 📐 Not Started |
| ST.K3.6 — Pending returns alert | 📐 Not Started |

---

### 4.4 K3b — Leave Pass Management

**RBS Ref:** K3 (extended) — leave tracking, weekend/home leave

#### FR-HST-009: Leave Pass Workflow 📐

- 📐 **Apply for Leave**: Student or staff on behalf — from_date, to_date, destination, purpose, guardian contact during leave, leave type (home/emergency/medical/festival/vacation)
- 📐 **Status FSM**: `pending` → `approved` / `rejected`; `approved` → `returned` / `cancelled`
- 📐 **Warden Approval**: Block Warden or Chief Warden approves/rejects with remarks; rejection requires reason
- 📐 **Parent Notification on Approval**: SMS/push notification to parent/guardian with leave details (from_date, to_date, destination)
- 📐 **Attendance Auto-Mark**: All shifts during leave period auto-marked as `leave` in `hst_attendance_entries` when leave is approved
- 📐 **Mess Auto Opt-Out**: Meals during leave period auto-marked `on_leave` in `hst_mess_attendance` when leave is approved
- 📐 **Return Confirmation**: Warden marks student as `returned` on actual return date; late return (actual_return_date > to_date) automatically creates an incident record of type `late_arrival` (BR-HST-012)
- 📐 **Leave Pass Print**: Generate printable PDF gate pass (DomPDF) with student details, leave dates, destination, approving warden signature line
- 📐 **Leave Register**: Complete history per student per academic year; exportable as PDF with warden signature

---

### 4.5 K4 — Mess Management

**RBS Ref:** K4 — Menu planning (weekly rotation), meal tracking, dietary preferences

#### FR-HST-010: Weekly Mess Menu Planning 📐

- 📐 **Define Weekly Menu**: For each hostel, for each week (Monday-anchored week_start_date), for each day (Mon–Sun), for each meal (breakfast/lunch/dinner/snacks) — specify menu description
- 📐 **Weekly Template Reuse**: Copy previous week's menu as template; override individual days/meals
- 📐 **Special Diet Flag**: Mark if special diet option is available for a given meal; describe the special diet being offered
- 📐 **Menu Publication**: Menu can be published (visible to students/parents via portal) or kept draft

#### FR-HST-011: Special Diet Assignment 📐

- 📐 **Assign Special Diet**: Per student, assign one or more diet types — Diabetic, Jain Vegetarian, Gluten-Free, Religious Fasting (specify days/period), Nut Allergy, other custom
- 📐 **Effective Period**: Diet assignment has start/end date; auto-expires or can be made permanent for academic year
- 📐 **Warden Alert**: At each meal, if special diet student is present, kitchen must be alerted — shown as flag in mess attendance marking UI

#### FR-HST-012: Mess Attendance Marking 📐

- 📐 **Mark Meal Attendance**: Per meal per day per student — present / absent / on_leave / opted_out
- 📐 **Special Diet Served Flag**: When marking special diet student as present, warden confirms whether special diet was served; description of special diet served recorded
- 📐 **Auto-Absent on Leave**: Leave pass approval automatically marks meals as `on_leave` for leave period
- 📐 **Monthly Mess Summary**: Total meals consumed per student per month — feeds into mess charge calculation; available as report and exportable CSV

| RBS Sub-Task | Status |
|---|---|
| ST.K4.1 — Define weekly meal plan | 📐 Not Started |
| ST.K4.2 — Assign special diet per student | 📐 Not Started |
| ST.K4.3 — Mark meal attendance | 📐 Not Started |
| ST.K4.4 — Special diet served confirmation | 📐 Not Started |
| ST.K4.5 — Monthly mess report | 📐 Not Started |

---

### 4.6 K5 — Hostel Fee Integration

**RBS Ref:** K5 — Link to Fee module for room-type based hostel charges

#### FR-HST-013: Hostel Fee Structure Configuration 📐

- 📐 **Fee Structure per Room Type**: For each academic session, per hostel, per room type — define monthly rates: room rent, mess charge (full board/partial), electricity charge, laundry charge, security deposit (one-time)
- 📐 **Mess Plan Variants**: Full board (3 meals), partial lunch-only, dinner-only — each with distinct monthly rate
- 📐 **Annual / Quarterly / Monthly Billing Frequency**: Configurable per hostel setting; system converts to daily rate for proration
- 📐 **Effective Dates**: Fee structures have `effective_from` / `effective_to` dates; multiple can exist per session to handle mid-year revisions

#### FR-HST-014: Fee Assignment on Allotment 📐

- 📐 **Auto-Calculate Fee**: On bed allotment, `HostelFeeService` looks up active fee structure for room type + meal plan → computes total monthly charge
- 📐 **Prorated Allotment Fee**: If allotment date is not 1st of month, charge = (daily_rate × remaining days in month)
- 📐 **Prorated Room Change Fee**: On room transfer, compute credit for old room (remaining days × old daily rate) and charge for new room (remaining days × new daily rate)
- 📐 **Prorated Vacating Refund**: If student vacates mid-month, calculate refund amount for unused days
- 📐 **Push to StudentFee Module**: Hostel fee demand pushed to `fin_fee_head_master` / fee demand tables in StudentFee module via `HostelFeeService` (service-to-service call within tenant context)
- 📐 **Fee Defaulter View**: Students with outstanding hostel fee balance; warden can view before approving leave pass (BR-HST-019)

| RBS Sub-Task | Status |
|---|---|
| ST.K5.1 — Configure room-type fee rates | 📐 Not Started |
| ST.K5.2 — Configure mess charge variants | 📐 Not Started |
| ST.K5.3 — Auto-assign fee on allotment | 📐 Not Started |
| ST.K5.4 — Prorated fee calculation | 📐 Not Started |
| ST.K5.5 — Push demand to StudentFee | 📐 Not Started |
| ST.K5.6 — Fee defaulter report | 📐 Not Started |

---

### 4.7 K6 — Hostel Complaint Register

**RBS Ref:** K6 — Maintenance requests, complaint tracking

#### FR-HST-015: Hostel Complaint Register 📐

- 📐 **Lodge Complaint/Request**: Student or staff lodges complaint — category (maintenance/electrical/plumbing/cleanliness/security/other), subject, description, room reference, photos (via sys_media)
- 📐 **Status Workflow**: `open` → `in_progress` → `resolved` / `escalated`
- 📐 **Assignment**: Complaint assigned to responsible staff member (maintenance warden or specific staff)
- 📐 **Resolution Notes**: Assigned staff enters resolution notes; resolved date recorded
- 📐 **Escalation**: Unresolved complaints older than configurable SLA (default 48 hours) auto-escalated to Chief Warden
- 📐 **Distinction from Complaint Module**: Hostel-internal maintenance/complaint register (`hst_complaints`) is separate from the school-wide Complaint module (`cmp_*`); hostel complaints are hostel-operation-specific and managed by warden staff
- 📐 **Complaint Register Report**: Open/resolved complaints by category and date range; average resolution time

| RBS Sub-Task | Status |
|---|---|
| ST.K6.1 — Lodge maintenance/complaint | 📐 Not Started |
| ST.K6.2 — Assign to responsible staff | 📐 Not Started |
| ST.K6.3 — Track resolution status | 📐 Not Started |
| ST.K6.4 — SLA-based auto-escalation | 📐 Not Started |

---

### 4.8 Warden Management

#### FR-HST-016: Warden Assignment and Scoped Access 📐

- 📐 **Chief Warden Assignment**: Assign a `sys_users` record as chief warden of a hostel; one chief warden per hostel at a time (previous assignment auto-ended)
- 📐 **Block/Floor Warden Assignment**: Assign one or more wardens to specific floors; warden assignment has `effective_from` / `effective_to` dates to handle rotation (staff on hostel duty rotate monthly/term)
- 📐 **Warden Scope Enforcement**: Block warden can only view and manage students, attendance, leave passes, and incidents for floors they are currently assigned to; Chief Warden has full hostel-wide access
- 📐 **Warden Assignment History**: Track historical assignments per hostel/floor; know which warden was on duty on any past date (important for incident accountability)
- 📐 **On-Duty Warden**: Current on-duty warden per shift per hostel displayed on dashboard; attendance sessions auto-attributed to on-duty warden

---

### 4.9 Visitor Log

#### FR-HST-017: Hostel Visitor Register 📐

- 📐 **Log Visitor**: Visitor name, relationship to student (parent/guardian/relative/other), student being visited, date, in-time, out-time, purpose, visitor ID proof type and number (masked)
- 📐 **Visiting Day Enforcement**: Configurable visiting days/hours per hostel (e.g., every Sunday 10:00–13:00); system warns if visit logged outside visiting hours (override by warden)
- 📐 **Visitor Pass**: Optional printable visitor pass generated per visit
- 📐 **Visitor Register Report**: Date-wise, student-wise visitor log; exportable CSV

---

### 4.10 Medical / Sick Bay

#### FR-HST-018: Sick Bay Admission and Discharge 📐

- 📐 **Admit Student to Sick Bay**: Student, admission date/time, presenting symptoms, initial diagnosis (text), attending staff (nurse/warden)
- 📐 **Sick Bay Occupancy**: Track current sick bay occupancy; beds available in sick bay defined as a configuration setting
- 📐 **Treatment Notes**: Basic treatment administered, medication given (text), next review scheduled
- 📐 **Discharge**: Record discharge date/time, discharge notes, follow-up instructions
- 📐 **Parent Notification**: On admission to sick bay, parent/guardian auto-notified (SMS/push)
- 📐 **Hospital Referral Flag**: If student referred to hospital, flag set; case linked to HPC module for detailed medical follow-up
- 📐 **Attendance Auto-Mark**: Students admitted to sick bay auto-marked as `sick_bay` in hostel attendance for the admission period
- 📐 **Sick Bay Register Report**: Admissions/discharges by date range; students with recurring sick bay visits

| RBS Sub-Task | Status |
|---|---|
| ST.SB.1 — Admit student to sick bay | 📐 Not Started |
| ST.SB.2 — Record treatment notes | 📐 Not Started |
| ST.SB.3 — Discharge with notes | 📐 Not Started |
| ST.SB.4 — Parent notification on admission | 📐 Not Started |
| ST.SB.5 — Attendance auto-mark for sick bay | 📐 Not Started |

---

### 4.11 Room Inventory Management

#### FR-HST-019: Room Inventory Tracking 📐

- 📐 **Assign Items to Room**: Record furniture/fixtures per room — beds, mattresses, study tables, chairs, cupboards, mirrors, fans, tubelights — with quantity and condition (good/fair/poor)
- 📐 **Condition History**: Each condition update creates a timestamped history record
- 📐 **Annual Inventory Audit**: Generate discrepancy report (items present vs items recorded per room)
- 📐 **Damage Reporting**: Log damaged item — description, date discovered, current occupants at time of discovery, estimated repair/replacement cost, responsible student (if identified)
- 📐 **Repair Workflow**: Status: `pending` → `under_repair` → `repaired` / `written_off`
- 📐 **Charge Recovery**: Damage cost linked to responsible student; `HostelFeeService` can push damage charge to StudentFee module as an ad-hoc fee item

---

### 4.12 Reports and Dashboard

#### FR-HST-020: Hostel Dashboard 📐

- 📐 **Live Occupancy Summary**: Total beds / occupied beds / vacant beds / under maintenance by hostel and totals
- 📐 **Today's Attendance Summary**: Present / absent / on-leave / late counts for today's most recent shift; visual progress bar
- 📐 **Pending Leave Passes**: Count + list of pending approval leave passes; quick approve/reject from dashboard
- 📐 **Pending Returns**: Students not yet returned past expected return time; alert count
- 📐 **Open Incidents**: Count of open/unresolved incidents by severity
- 📐 **Sick Bay Occupancy**: Current students in sick bay; bed availability
- 📐 **Attendance Compliance**: Students below attendance threshold — count and quick-view list
- 📐 **Fee Defaulters**: Students with outstanding hostel fee (count; link to full report)

#### FR-HST-021: Hostel Reports 📐

| Report Name | Description | Filters | Export |
|---|---|---|---|
| Occupancy Report | Current bed occupancy by hostel/floor/room | Hostel, Floor, Date | PDF, CSV |
| Room Utilization Report | Room-wise occupancy % over time | Date Range, Hostel | CSV |
| Attendance Report | Student-wise or date-wise attendance summary | Student, Date Range, Shift | PDF, CSV |
| Leave Register | All leave passes with status | Student, Date Range, Status, Type | PDF, CSV |
| Movement Register | In-out log for gate passes | Date, Hostel | CSV |
| Fee Defaulter Report | Students with outstanding hostel fee | Hostel, Academic Session | CSV |
| Incident Register | All incidents by severity and type | Date Range, Student, Severity | PDF, CSV |
| Mess Attendance Report | Monthly meal consumption per student | Student, Month, Meal Type | PDF, CSV |
| Room Inventory Report | Furniture/fixtures with condition by room | Hostel, Floor, Room | CSV |
| Damage Report | Open damage records with costs | Status, Date Range | CSV |
| Visitor Register | Hostel visitor log | Date Range, Student, Hostel | CSV |
| Sick Bay Report | Admissions/discharges summary | Date Range, Student | CSV |

---

## 5. Data Model — Proposed DDL

All tables use prefix `hst_*`. All tables include standard audit columns on every row:
`id BIGINT UNSIGNED PK`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK → sys_users`, `created_at TIMESTAMP`, `updated_at TIMESTAMP`, `deleted_at TIMESTAMP NULL`.

---

### 5.1 hst_hostels 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| name | VARCHAR(150) | NOT NULL | Hostel/building name |
| type | ENUM('boys','girls','mixed') | NOT NULL | Gender type |
| code | VARCHAR(20) | NULL UNIQUE | Short code (e.g., BH1, GH1) |
| warden_id | BIGINT UNSIGNED | NULL FK → sys_users | Chief Warden (current) |
| total_capacity | SMALLINT UNSIGNED | DEFAULT 0 | Total beds (auto-computed trigger or service) |
| current_occupancy | SMALLINT UNSIGNED | DEFAULT 0 | Occupied beds (auto-computed) |
| sick_bay_capacity | TINYINT UNSIGNED | DEFAULT 5 | Sick bay bed count |
| address | VARCHAR(500) | NULL | Physical location |
| contact_phone | VARCHAR(20) | NULL | Hostel contact number |
| visiting_days_json | JSON | NULL | Visiting day/hour config |
| facilities_json | JSON | NULL | Array of facility names |
| + standard audit columns | | | |

---

### 5.2 hst_floors 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Parent hostel |
| floor_number | TINYINT | NOT NULL | Floor number (0 = Ground) |
| display_name | VARCHAR(100) | NULL | "Ground Floor", "First Floor", etc. |
| floor_incharge_id | BIGINT UNSIGNED | NULL FK → sys_users | Floor incharge (current) |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, floor_number)`

---

### 5.3 hst_rooms 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| floor_id | BIGINT UNSIGNED | NOT NULL FK → hst_floors | Parent floor |
| room_number | VARCHAR(20) | NOT NULL | Room number/label |
| room_type | ENUM('single','double','triple','dormitory') | NOT NULL | Room type |
| capacity | TINYINT UNSIGNED | NOT NULL | Total beds in room |
| current_occupancy | TINYINT UNSIGNED | DEFAULT 0 | Currently occupied beds |
| status | ENUM('available','full','maintenance') | DEFAULT 'available' | Room availability |
| amenities_json | JSON | NULL | AC, attached bath, fan, etc. |
| priority_flags_json | JSON | NULL | medical, senior, merit flags |
| notes | VARCHAR(500) | NULL | Admin notes |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (floor_id, room_number)`

---

### 5.4 hst_beds 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| room_id | BIGINT UNSIGNED | NOT NULL FK → hst_rooms | Parent room |
| bed_label | VARCHAR(20) | NOT NULL | Bed A, Bed 1, etc. |
| status | ENUM('available','occupied','maintenance') | DEFAULT 'available' | Bed status |
| condition | ENUM('good','fair','poor') | DEFAULT 'good' | Physical condition |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (room_id, bed_label)`

---

### 5.5 hst_warden_assignments 📐

Tracks the rotation of wardens across floors with effective date ranges.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel context |
| floor_id | BIGINT UNSIGNED | NULL FK → hst_floors | Floor (NULL = hostel-level/chief warden) |
| user_id | BIGINT UNSIGNED | NOT NULL FK → sys_users | Staff assigned as warden |
| assignment_type | ENUM('chief','block','floor','assistant') | NOT NULL | Role type |
| effective_from | DATE | NOT NULL | Assignment start date |
| effective_to | DATE | NULL | Assignment end date (NULL = current) |
| remarks | VARCHAR(300) | NULL | Rotation notes |
| + standard audit columns | | | |

**Index:** `(hostel_id, floor_id, effective_to)` for current-warden lookup

---

### 5.6 hst_allotments 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| bed_id | BIGINT UNSIGNED | NOT NULL FK → hst_beds | Assigned bed |
| academic_session_id | BIGINT UNSIGNED | NOT NULL FK → sch_academic_sessions | Academic year |
| allotment_date | DATE | NOT NULL | Date of allotment |
| vacating_date | DATE | NULL | Date vacated (NULL = currently active) |
| meal_plan | ENUM('full_board','lunch_only','dinner_only','none') | DEFAULT 'full_board' | Meal plan selected |
| status | ENUM('active','vacated','transferred','waitlisted') | DEFAULT 'active' | Allotment lifecycle status |
| remarks | VARCHAR(500) | NULL | Notes |
| + standard audit columns | | | |

**Application Rule:** Only one record with `status = 'active'` per `bed_id` at any time (enforced in `AllotmentService` before INSERT; also enforced via partial unique index in MySQL 8 using generated column).

**Index:** `INDEX (student_id, status)`, `INDEX (bed_id, status)`

---

### 5.7 hst_room_change_requests 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Requesting student |
| from_allotment_id | BIGINT UNSIGNED | NOT NULL FK → hst_allotments | Current allotment |
| requested_room_id | BIGINT UNSIGNED | NULL FK → hst_rooms | Preferred target room |
| reason | TEXT | NOT NULL | Reason for request |
| status | ENUM('pending','approved','rejected') | DEFAULT 'pending' | Request status |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Approving warden |
| approved_at | TIMESTAMP | NULL | Approval timestamp |
| rejection_reason | TEXT | NULL | Rejection notes |
| new_allotment_id | BIGINT UNSIGNED | NULL FK → hst_allotments | Created on approval |
| + standard audit columns | | | |

---

### 5.8 hst_attendance 📐

Session-level record (one per hostel per date per shift).

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| attendance_date | DATE | NOT NULL | Roll call date |
| shift | ENUM('morning','evening','night') | NOT NULL | Shift |
| marked_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Warden who marked |
| present_count | SMALLINT UNSIGNED | DEFAULT 0 | Pre-computed present count |
| absent_count | SMALLINT UNSIGNED | DEFAULT 0 | Pre-computed absent count |
| leave_count | SMALLINT UNSIGNED | DEFAULT 0 | Pre-computed on-leave count |
| late_count | SMALLINT UNSIGNED | DEFAULT 0 | Pre-computed late count |
| is_locked | TINYINT(1) | DEFAULT 0 | Locked after 24h |
| remarks | VARCHAR(500) | NULL | Session-level notes |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, attendance_date, shift)`

---

### 5.9 hst_attendance_entries 📐

Per-student row within an attendance session.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| attendance_id | BIGINT UNSIGNED | NOT NULL FK → hst_attendance CASCADE DELETE | Parent session |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| status | ENUM('present','absent','leave','home','late','sick_bay') | NOT NULL | Status |
| late_remarks | VARCHAR(255) | NULL | Remarks for late/absent |
| check_in_time | TIME | NULL | Actual check-in time (for late entries) |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (attendance_id, student_id)`

---

### 5.10 hst_movement_log 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| movement_date | DATE | NOT NULL | Date of movement |
| out_time | TIME | NOT NULL | Departure time |
| in_time | TIME | NULL | Actual return (NULL = not yet returned) |
| expected_return_time | TIME | NULL | Expected return time |
| destination | VARCHAR(255) | NOT NULL | Destination/reason |
| purpose | VARCHAR(500) | NULL | Additional purpose details |
| gate_pass_issued_by | BIGINT UNSIGNED | NULL FK → sys_users | Warden who issued pass |
| overdue_notified | TINYINT(1) | DEFAULT 0 | Overdue notification sent |
| + standard audit columns | | | |

**Index:** `INDEX (hostel_id, movement_date)`, `INDEX (student_id, in_time)` (for pending returns query)

---

### 5.11 hst_leave_passes 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| allotment_id | BIGINT UNSIGNED | NOT NULL FK → hst_allotments | Active allotment at time of application |
| leave_type | ENUM('home','emergency','medical','festival','vacation','other') | NOT NULL | Leave type |
| from_date | DATE | NOT NULL | Leave start |
| to_date | DATE | NOT NULL | Leave end (>= from_date) |
| destination | VARCHAR(255) | NOT NULL | Leave destination |
| purpose | VARCHAR(500) | NOT NULL | Purpose |
| guardian_contact | VARCHAR(20) | NULL | Guardian contact during leave |
| applied_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Staff who created application |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Approving warden |
| approved_at | TIMESTAMP | NULL | Approval timestamp |
| status | ENUM('pending','approved','rejected','returned','cancelled') | DEFAULT 'pending' | Leave status FSM |
| rejection_reason | TEXT | NULL | Rejection explanation |
| actual_return_date | DATE | NULL | Actual return date (filled on return confirmation) |
| late_return_incident_id | BIGINT UNSIGNED | NULL FK → hst_incidents | Auto-created incident if late |
| parent_notified | TINYINT(1) | DEFAULT 0 | Parent notification sent flag |
| + standard audit columns | | | |

---

### 5.12 hst_incidents 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student involved |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| incident_date | DATE | NOT NULL | Date of incident |
| incident_time | TIME | NULL | Time of incident |
| incident_type | VARCHAR(100) | NOT NULL | late_arrival / rule_violation / property_damage / misconduct / other |
| description | TEXT | NOT NULL | Detailed description |
| severity | ENUM('minor','moderate','serious') | NOT NULL | Severity |
| action_taken | TEXT | NULL | Action taken |
| reported_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Warden who reported |
| is_escalated | TINYINT(1) | DEFAULT 0 | Escalated to Principal |
| escalated_at | TIMESTAMP | NULL | Escalation timestamp |
| warning_letter_sent | TINYINT(1) | DEFAULT 0 | Warning letter generated |
| parent_notified | TINYINT(1) | DEFAULT 0 | Parent notification sent |
| is_auto_generated | TINYINT(1) | DEFAULT 0 | Auto-created (e.g., late return) |
| + standard audit columns | | | |

---

### 5.13 hst_incident_media 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| incident_id | BIGINT UNSIGNED | NOT NULL FK → hst_incidents CASCADE DELETE | Parent incident |
| media_id | BIGINT UNSIGNED | NOT NULL FK → sys_media | Attached file |
| media_type | VARCHAR(50) | NULL | photo / document / witness_statement |
| + standard audit columns | | | |

---

### 5.14 hst_fee_structures 📐

Per room type per hostel per academic session.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| academic_session_id | BIGINT UNSIGNED | NOT NULL FK → sch_academic_sessions | Academic session |
| room_type | ENUM('single','double','triple','dormitory') | NOT NULL | Room type |
| meal_plan | ENUM('full_board','lunch_only','dinner_only','none') | NOT NULL | Meal plan variant |
| room_rent_monthly | DECIMAL(10,2) | NOT NULL DEFAULT 0 | Monthly room rent |
| mess_charge_monthly | DECIMAL(10,2) | NOT NULL DEFAULT 0 | Monthly mess charge |
| electricity_charge_monthly | DECIMAL(10,2) | DEFAULT 0 | Electricity/water charge |
| laundry_charge_monthly | DECIMAL(10,2) | DEFAULT 0 | Laundry charge |
| security_deposit | DECIMAL(10,2) | DEFAULT 0 | One-time security deposit |
| effective_from | DATE | NOT NULL | Fee effective start date |
| effective_to | DATE | NULL | Fee effective end date |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, academic_session_id, room_type, meal_plan, effective_from)`

---

### 5.15 hst_special_diets 📐

Per-student diet assignments.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel context |
| diet_type | ENUM('diabetic','jain_vegetarian','gluten_free','nut_allergy','religious_fasting','custom') | NOT NULL | Diet category |
| custom_description | VARCHAR(300) | NULL | Description for 'custom' type |
| fasting_days_json | JSON | NULL | Specific fasting days/periods for religious fasting |
| effective_from | DATE | NOT NULL | Diet start date |
| effective_to | DATE | NULL | Diet end date (NULL = ongoing for academic year) |
| prescribed_by | VARCHAR(150) | NULL | Doctor/authority who prescribed |
| + standard audit columns | | | |

---

### 5.16 hst_mess_weekly_menus 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| academic_session_id | BIGINT UNSIGNED | NOT NULL FK → sch_academic_sessions | Academic session |
| week_start_date | DATE | NOT NULL | Monday of the week |
| day_of_week | TINYINT UNSIGNED | NOT NULL | 1=Mon … 7=Sun |
| meal_type | ENUM('breakfast','lunch','dinner','snacks') | NOT NULL | Meal time |
| menu_description | TEXT | NULL | Menu items |
| is_special_diet_available | TINYINT(1) | DEFAULT 0 | Special diet option available |
| special_diet_description | VARCHAR(500) | NULL | Special diet offered |
| is_published | TINYINT(1) | DEFAULT 0 | Published (visible to portal) |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, week_start_date, day_of_week, meal_type)`

---

### 5.17 hst_mess_attendance 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| attendance_date | DATE | NOT NULL | Date |
| meal_type | ENUM('breakfast','lunch','dinner','snacks') | NOT NULL | Meal |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| status | ENUM('present','absent','on_leave','opted_out') | NOT NULL | Meal attendance status |
| is_special_diet_served | TINYINT(1) | DEFAULT 0 | Special diet was served |
| special_diet_served_desc | VARCHAR(255) | NULL | What special diet was served |
| marked_by | BIGINT UNSIGNED | NULL FK → sys_users | Mess supervisor |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, attendance_date, meal_type, student_id)`

---

### 5.18 hst_complaints 📐

Hostel-internal maintenance and service complaint register.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| room_id | BIGINT UNSIGNED | NULL FK → hst_rooms | Room related to complaint |
| reported_by_student_id | BIGINT UNSIGNED | NULL FK → std_students | Student who reported |
| reported_by_user_id | BIGINT UNSIGNED | NULL FK → sys_users | Staff who reported |
| category | ENUM('maintenance','electrical','plumbing','cleanliness','security','food','other') | NOT NULL | Category |
| subject | VARCHAR(255) | NOT NULL | Short subject line |
| description | TEXT | NOT NULL | Detailed description |
| priority | ENUM('low','medium','high','urgent') | DEFAULT 'medium' | Priority |
| status | ENUM('open','in_progress','resolved','escalated','closed') | DEFAULT 'open' | Status |
| assigned_to | BIGINT UNSIGNED | NULL FK → sys_users | Staff assigned |
| resolution_notes | TEXT | NULL | Resolution description |
| resolved_at | TIMESTAMP | NULL | Resolution timestamp |
| sla_due_at | TIMESTAMP | NULL | SLA deadline (computed on creation) |
| is_escalated | TINYINT(1) | DEFAULT 0 | Escalated flag |
| escalated_at | TIMESTAMP | NULL | Escalation timestamp |
| + standard audit columns | | | |

---

### 5.19 hst_visitor_log 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel visited |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student being visited |
| visitor_name | VARCHAR(150) | NOT NULL | Visitor full name |
| relationship | ENUM('parent','guardian','sibling','relative','other') | NOT NULL | Relationship to student |
| visitor_phone | VARCHAR(20) | NULL | Visitor contact number |
| id_proof_type | VARCHAR(50) | NULL | Aadhaar / PAN / Passport / DL |
| id_proof_number_masked | VARCHAR(30) | NULL | Last 4 digits only |
| visit_date | DATE | NOT NULL | Date of visit |
| in_time | TIME | NOT NULL | Check-in time |
| out_time | TIME | NULL | Check-out time (NULL = still inside) |
| purpose | VARCHAR(300) | NULL | Purpose of visit |
| allowed_by | BIGINT UNSIGNED | NULL FK → sys_users | Warden who authorised |
| is_outside_visiting_hours | TINYINT(1) | DEFAULT 0 | Visit outside configured hours |
| override_reason | VARCHAR(300) | NULL | Warden reason for out-of-hours override |
| + standard audit columns | | | |

**Index:** `INDEX (hostel_id, visit_date)`, `INDEX (student_id)`

---

### 5.20 hst_sick_bay_log 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| admission_datetime | DATETIME | NOT NULL | Admission date and time |
| discharge_datetime | DATETIME | NULL | Discharge date and time (NULL = current inpatient) |
| presenting_symptoms | TEXT | NOT NULL | Symptoms on admission |
| initial_diagnosis | VARCHAR(500) | NULL | Initial assessment |
| treatment_notes | TEXT | NULL | Treatment/medication administered |
| attending_staff_id | BIGINT UNSIGNED | NULL FK → sys_users | Nurse/warden attending |
| discharge_notes | TEXT | NULL | Discharge instructions |
| is_hospital_referred | TINYINT(1) | DEFAULT 0 | Referred to hospital |
| hpc_record_id | BIGINT UNSIGNED | NULL | FK reference to HPC module record (if referred) |
| parent_notified | TINYINT(1) | DEFAULT 0 | Parent notification sent |
| + standard audit columns | | | |

**Index:** `INDEX (hostel_id, admission_datetime)`, `INDEX (student_id)`, `INDEX (discharge_datetime)` (for current inpatients: WHERE discharge_datetime IS NULL)

---

### 5.21 hst_room_inventory 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | Primary key |
| room_id | BIGINT UNSIGNED | NOT NULL FK → hst_rooms | Room |
| item_name | VARCHAR(150) | NOT NULL | Bed / Mattress / Study Table / Chair / Cupboard |
| quantity | TINYINT UNSIGNED | DEFAULT 1 | Count of this item in room |
| condition | ENUM('good','fair','poor','under_repair','disposed') | DEFAULT 'good' | Current condition |
| last_inspected_at | DATE | NULL | Last inspection date |
| damage_description | TEXT | NULL | Damage description |
| estimated_repair_cost | DECIMAL(10,2) | NULL | Repair/replacement cost |
| repair_status | ENUM('none','pending','under_repair','repaired','written_off') | DEFAULT 'none' | Repair workflow status |
| responsible_student_id | BIGINT UNSIGNED | NULL FK → std_students | Student found responsible |
| charge_pushed_to_fee | TINYINT(1) | DEFAULT 0 | Damage charge pushed to StudentFee |
| + standard audit columns | | | |

---

### 5.22 Cross-Module FK Dependencies

| FK Column | References | Module Owner |
|---|---|---|
| `std_students.id` | All `student_id` columns | StudentProfile |
| `sch_academic_sessions.id` | `hst_allotments`, `hst_mess_weekly_menus`, `hst_fee_structures` | SchoolSetup |
| `sys_users.id` | All warden, approved_by, marked_by, created_by columns | System |
| `sys_media.id` | `hst_incident_media.media_id` | System |
| `fin_fee_head_master.id` | (via service, no direct FK) | StudentFee |

---

## 6. Routes

All routes registered in `routes/tenant.php` under prefix `hostel/` with `auth` + `verified` middleware. Route name prefix: `hostel.`

### 6.1 Infrastructure Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET | `hostel/dashboard` | `HstDashboardController@index` | `hostel.dashboard` |
| GET/POST | `hostel/hostels` | `HostelController@index/store` | `hostel.hostels.index/store` |
| GET/PUT/DELETE | `hostel/hostels/{hostel}` | `HostelController@show/update/destroy` | `hostel.hostels.show/update/destroy` |
| POST | `hostel/hostels/{hostel}/toggle-status` | `HostelController@toggleStatus` | `hostel.hostels.toggle-status` |
| GET/POST | `hostel/floors` | `FloorController@index/store` | `hostel.floors.index/store` |
| GET/PUT/DELETE | `hostel/floors/{floor}` | `FloorController@show/update/destroy` | `hostel.floors.show/update/destroy` |
| GET/POST | `hostel/rooms` | `RoomController@index/store` | `hostel.rooms.index/store` |
| GET/PUT/DELETE | `hostel/rooms/{room}` | `RoomController@show/update/destroy` | `hostel.rooms.show/update/destroy` |
| POST | `hostel/rooms/{room}/toggle-status` | `RoomController@toggleStatus` | `hostel.rooms.toggle-status` |
| GET/POST | `hostel/beds` | `BedController@index/store` | `hostel.beds.index/store` |
| GET/PUT/DELETE | `hostel/beds/{bed}` | `BedController@show/update/destroy` | `hostel.beds.show/update/destroy` |

### 6.2 Warden Assignment Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/warden-assignments` | `WardenAssignmentController@index/store` | `hostel.wardens.index/store` |
| GET/PUT | `hostel/warden-assignments/{assignment}` | `WardenAssignmentController@show/update` | `hostel.wardens.show/update` |
| POST | `hostel/warden-assignments/{assignment}/end` | `WardenAssignmentController@end` | `hostel.wardens.end` |

### 6.3 Allotment Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/allotments` | `AllotmentController@index/store` | `hostel.allotments.index/store` |
| GET/PUT | `hostel/allotments/{allotment}` | `AllotmentController@show/update` | `hostel.allotments.show/update` |
| POST | `hostel/allotments/{allotment}/vacate` | `AllotmentController@vacate` | `hostel.allotments.vacate` |
| POST | `hostel/allotments/{allotment}/transfer` | `AllotmentController@transfer` | `hostel.allotments.transfer` |
| POST | `hostel/allotments/bulk-vacate` | `AllotmentController@bulkVacate` | `hostel.allotments.bulk-vacate` |
| GET | `hostel/allotments/availability` | `AllotmentController@availability` | `hostel.allotments.availability` |
| GET/POST | `hostel/room-change-requests` | `RoomChangeRequestController@index/store` | `hostel.rcr.index/store` |
| GET | `hostel/room-change-requests/{rcr}` | `RoomChangeRequestController@show` | `hostel.rcr.show` |
| POST | `hostel/room-change-requests/{rcr}/approve` | `RoomChangeRequestController@approve` | `hostel.rcr.approve` |
| POST | `hostel/room-change-requests/{rcr}/reject` | `RoomChangeRequestController@reject` | `hostel.rcr.reject` |

### 6.4 Attendance Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/attendance` | `HstAttendanceController@index/store` | `hostel.attendance.index/store` |
| GET/PUT | `hostel/attendance/{session}` | `HstAttendanceController@show/update` | `hostel.attendance.show/update` |
| GET/POST | `hostel/attendance/{session}/entries` | `HstAttendanceController@entries/storeEntries` | `hostel.attendance.entries/store-entries` |
| POST | `hostel/attendance/{session}/bulk-mark` | `HstAttendanceController@bulkMark` | `hostel.attendance.bulk-mark` |
| POST | `hostel/attendance/{session}/lock` | `HstAttendanceController@lock` | `hostel.attendance.lock` |
| GET/POST | `hostel/movement-log` | `MovementLogController@index/store` | `hostel.movement.index/store` |
| POST | `hostel/movement-log/{log}/return` | `MovementLogController@recordReturn` | `hostel.movement.return` |
| GET | `hostel/movement-log/pending` | `MovementLogController@pendingReturns` | `hostel.movement.pending` |

### 6.5 Leave Pass Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/leave-passes` | `LeavePassController@index/store` | `hostel.leave.index/store` |
| GET/PUT | `hostel/leave-passes/{pass}` | `LeavePassController@show/update` | `hostel.leave.show/update` |
| POST | `hostel/leave-passes/{pass}/approve` | `LeavePassController@approve` | `hostel.leave.approve` |
| POST | `hostel/leave-passes/{pass}/reject` | `LeavePassController@reject` | `hostel.leave.reject` |
| POST | `hostel/leave-passes/{pass}/return` | `LeavePassController@markReturned` | `hostel.leave.return` |
| POST | `hostel/leave-passes/{pass}/cancel` | `LeavePassController@cancel` | `hostel.leave.cancel` |
| GET | `hostel/leave-passes/{pass}/print` | `LeavePassController@print` | `hostel.leave.print` |
| GET | `hostel/leave-passes/calendar` | `LeavePassController@calendar` | `hostel.leave.calendar` |

### 6.6 Incident Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/incidents` | `IncidentController@index/store` | `hostel.incidents.index/store` |
| GET/PUT | `hostel/incidents/{incident}` | `IncidentController@show/update` | `hostel.incidents.show/update` |
| POST | `hostel/incidents/{incident}/escalate` | `IncidentController@escalate` | `hostel.incidents.escalate` |
| GET | `hostel/incidents/{incident}/warning-letter` | `IncidentController@printWarningLetter` | `hostel.incidents.warning-letter` |
| POST | `hostel/incidents/{incident}/notify-parent` | `IncidentController@notifyParent` | `hostel.incidents.notify-parent` |
| POST/DELETE | `hostel/incidents/{incident}/media` | `IncidentController@storeMedia/destroyMedia` | `hostel.incidents.media.*` |

### 6.7 Mess Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/mess/menus` | `MessMenuController@index/store` | `hostel.mess.menus.index/store` |
| GET/PUT/DELETE | `hostel/mess/menus/{menu}` | `MessMenuController@show/update/destroy` | `hostel.mess.menus.show/update/destroy` |
| POST | `hostel/mess/menus/copy-week` | `MessMenuController@copyWeek` | `hostel.mess.menus.copy-week` |
| GET/POST | `hostel/mess/special-diets` | `SpecialDietController@index/store` | `hostel.mess.diets.index/store` |
| GET/PUT/DELETE | `hostel/mess/special-diets/{diet}` | `SpecialDietController@show/update/destroy` | `hostel.mess.diets.show/update/destroy` |
| GET/POST | `hostel/mess/attendance` | `MessAttendanceController@index/store` | `hostel.mess.attendance.index/store` |
| POST | `hostel/mess/attendance/bulk` | `MessAttendanceController@bulkStore` | `hostel.mess.attendance.bulk` |
| GET | `hostel/mess/attendance/report` | `MessAttendanceController@monthlyReport` | `hostel.mess.attendance.report` |

### 6.8 Hostel Fee Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/fee-structures` | `HstFeeController@index/store` | `hostel.fee.index/store` |
| GET/PUT/DELETE | `hostel/fee-structures/{structure}` | `HstFeeController@show/update/destroy` | `hostel.fee.show/update/destroy` |
| GET | `hostel/fee-structures/calculate` | `HstFeeController@calculate` | `hostel.fee.calculate` |
| GET | `hostel/fee-structures/defaulters` | `HstFeeController@defaulters` | `hostel.fee.defaulters` |

### 6.9 Hostel Complaint Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/complaints` | `HstComplaintController@index/store` | `hostel.complaints.index/store` |
| GET/PUT | `hostel/complaints/{complaint}` | `HstComplaintController@show/update` | `hostel.complaints.show/update` |
| POST | `hostel/complaints/{complaint}/assign` | `HstComplaintController@assign` | `hostel.complaints.assign` |
| POST | `hostel/complaints/{complaint}/resolve` | `HstComplaintController@resolve` | `hostel.complaints.resolve` |
| POST | `hostel/complaints/{complaint}/escalate` | `HstComplaintController@escalate` | `hostel.complaints.escalate` |

### 6.10 Visitor Log Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/visitors` | `VisitorLogController@index/store` | `hostel.visitors.index/store` |
| GET/PUT | `hostel/visitors/{visitor}` | `VisitorLogController@show/update` | `hostel.visitors.show/update` |
| POST | `hostel/visitors/{visitor}/checkout` | `VisitorLogController@checkout` | `hostel.visitors.checkout` |

### 6.11 Sick Bay Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET/POST | `hostel/sick-bay` | `SickBayController@index/store` | `hostel.sickbay.index/store` |
| GET/PUT | `hostel/sick-bay/{log}` | `SickBayController@show/update` | `hostel.sickbay.show/update` |
| POST | `hostel/sick-bay/{log}/discharge` | `SickBayController@discharge` | `hostel.sickbay.discharge` |
| GET | `hostel/sick-bay/current` | `SickBayController@current` | `hostel.sickbay.current` |

### 6.12 Report Routes 📐

| Method | URI | Controller@Action | Route Name |
|---|---|---|---|
| GET | `hostel/reports/occupancy` | `HstReportController@occupancy` | `hostel.reports.occupancy` |
| GET | `hostel/reports/attendance` | `HstReportController@attendance` | `hostel.reports.attendance` |
| GET | `hostel/reports/leave-register` | `HstReportController@leaveRegister` | `hostel.reports.leave-register` |
| GET | `hostel/reports/movement` | `HstReportController@movement` | `hostel.reports.movement` |
| GET | `hostel/reports/fee-defaulters` | `HstReportController@feeDefaulters` | `hostel.reports.fee-defaulters` |
| GET | `hostel/reports/incidents` | `HstReportController@incidents` | `hostel.reports.incidents` |
| GET | `hostel/reports/mess-attendance` | `HstReportController@messAttendance` | `hostel.reports.mess-attendance` |
| GET | `hostel/reports/room-inventory` | `HstReportController@roomInventory` | `hostel.reports.room-inventory` |
| GET | `hostel/reports/visitors` | `HstReportController@visitors` | `hostel.reports.visitors` |
| GET | `hostel/reports/sick-bay` | `HstReportController@sickBay` | `hostel.reports.sick-bay` |
| GET | `hostel/reports/{type}/export` | `HstReportController@export` | `hostel.reports.export` |

---

## 7. Non-Functional Requirements

### 7.1 Performance 📐

- 📐 Hostel attendance marking for 500 students must complete (bulk save to DB) within 3 seconds
- 📐 Occupancy dashboard must load within 2 seconds using pre-computed counts stored in `hst_hostels.current_occupancy` and `hst_attendance.present_count` (not aggregated on every load)
- 📐 Mess attendance bulk mark for 300 students × 1 meal must complete within 2 seconds
- 📐 Movement pending-returns query must use an indexed query: `WHERE hostel_id = ? AND in_time IS NULL AND movement_date = ?`
- 📐 Attendance session must be idempotent on save — no duplicate entries even on double-submit (enforced by `UNIQUE (hostel_id, attendance_date, shift)`)

### 7.2 Reliability 📐

- 📐 Leave pass approval triggers parent notification — dispatch via queued Job (not inline) so UI is not blocked; failure in notification must not roll back the leave pass approval
- 📐 Sick bay admission parent notification similarly dispatched via queue
- 📐 SLA escalation for hostel complaints runs via Laravel scheduled job (`SendHstComplaintEscalationJob`) on hourly schedule

### 7.3 Data Integrity 📐

- 📐 No `tenant_id` column on any `hst_*` table — data isolation at database level via stancl/tenancy
- 📐 One active allotment per bed: enforced in `AllotmentService` with a DB-level partial unique index via generated column `gen_active_bed BIGINT AS (IF(status='active', bed_id, NULL)) STORED` + `UNIQUE (gen_active_bed)` on `hst_allotments`
- 📐 One active allotment per student: enforced in `AllotmentService` similarly
- 📐 Leave pass `to_date >= from_date`: FormRequest validation
- 📐 Gender match between student and hostel type: `AllotmentService` validates before INSERT
- 📐 Attendance lock: `is_locked = 1` prevents UPDATE after 24 hours except by Chief Warden role

### 7.4 Security 📐

- 📐 All routes protected by `auth` middleware under tenant context
- 📐 Gate/Policy-based permissions for every controller action
- 📐 Block Warden scoped access enforced via `HostelScope` applied by `WardenScopeMiddleware` on warden routes
- 📐 Visitor ID proof numbers stored masked (last 4 digits only); full number never stored
- 📐 Parent notifications contain only the target student's data — no cross-student exposure

### 7.5 Accessibility 📐

- 📐 Attendance marking UI designed for tablet/mobile use (wardens typically use tablets during roll call)
- 📐 Mess attendance marking supports bulk mark with one-tap exception marking
- 📐 All PDF exports (leave pass, warning letter) must render correctly on A4 with DomPDF

---

## 8. Business Rules

| Rule ID | Description |
|---|---|
| BR-HST-001 | A bed can have only one `active` allotment at a time — enforced in `AllotmentService` before INSERT |
| BR-HST-002 | A student can have only one `active` allotment at a time — same service-level check |
| BR-HST-003 | Gender restriction: student gender must match hostel type (`boys`/`girls`) before allotment |
| BR-HST-004 | Leave pass `to_date` must be >= `from_date` (FormRequest validation) |
| BR-HST-005 | Leave pass approval auto-marks all shifts during leave period as `leave` in `hst_attendance_entries` |
| BR-HST-006 | Leave pass approval auto-marks all meals during leave period as `on_leave` in `hst_mess_attendance` |
| BR-HST-007 | Attendance session is unique per `(hostel_id, attendance_date, shift)` — duplicate creation returns existing session |
| BR-HST-008 | Moderate and Serious incidents must trigger parent notification dispatch (queued) automatically |
| BR-HST-009 | Hostel deactivation is blocked if any active allotments exist in that hostel |
| BR-HST-010 | Room status auto-updates: `full` when `current_occupancy >= capacity`; `available` when drops below |
| BR-HST-011 | Prorated fee = `(monthly_rate / 30) × remaining_days_in_month` |
| BR-HST-012 | Late return: if `actual_return_date > to_date` on leave pass, `LeavePassService::markReturned()` auto-creates an `hst_incidents` record with `incident_type = 'late_arrival'` and `is_auto_generated = 1` |
| BR-HST-013 | Warden scoped access: block/floor wardens see only their assigned hostels/floors |
| BR-HST-014 | Academic year reset (bulk-vacate) requires explicit typed confirmation; all changes logged in `sys_activity_logs` |
| BR-HST-015 | Hostel fee structure must exist for the room type and meal plan before allotment can be created |
| BR-HST-016 | Student admitted to sick bay is auto-marked `sick_bay` in hostel attendance for admission period |
| BR-HST-017 | Student absent from roll call (not on leave, not in sick bay) triggers parent notification |
| BR-HST-018 | Students with hostel attendance below threshold (configurable, default 90%) are flagged on dashboard |
| BR-HST-019 | Warden may view fee defaulters before approving leave pass; system shows outstanding balance as advisory (not a hard block by default; can be configured as hard block) |
| BR-HST-020 | Hostel complaint SLA breach (configurable, default 48 hours for high/urgent) triggers auto-escalation |
| BR-HST-021 | Visitor entry outside configured visiting hours requires warden override with reason |
| BR-HST-022 | A student with 3 or more incidents in the current academic year is flagged as `repeated_offender` on dashboard |

---

## 9. Workflows

### 9.1 Student Room Allocation Workflow 📐

```
[Admin/Warden]
    │
    ├─1. Search student (std_students) by name/admission no
    ├─2. Verify gender matches hostel type (AllotmentService::validateGender)
    ├─3. Browse hostel → floor → room → bed availability
    ├─4. Select available bed
    ├─5. Select meal plan (full_board / lunch_only / dinner_only / none)
    ├─6. Set allotment date
    ├─7. AllotmentService::create() called:
    │       ├─ Validate: bed status = 'available'
    │       ├─ Validate: no active allotment for this bed
    │       ├─ Validate: no active allotment for this student
    │       ├─ Validate: gender match
    │       ├─ Validate: fee structure exists for room_type + meal_plan
    │       ├─ INSERT hst_allotments (status = 'active')
    │       ├─ UPDATE hst_beds.status = 'occupied'
    │       ├─ UPDATE hst_rooms.current_occupancy + 1
    │       ├─ UPDATE room status to 'full' if capacity reached
    │       └─ HostelFeeService::calculateAndPush() → StudentFee module
    └─8. Confirmation + allotment card displayed
```

### 9.2 Leave Pass Approval Workflow 📐

```
[Student/Staff]
    │
    ├─1. Submit leave pass application
    │       Fields: leave_type, from_date, to_date, destination, purpose, guardian_contact
    │
[Block Warden / Chief Warden]
    │
    ├─2. Review pending leave pass (dashboard list)
    ├─3a. APPROVE:
    │       ├─ LeavePassService::approve($pass, $warden)
    │       ├─ UPDATE hst_leave_passes: status='approved', approved_by, approved_at
    │       ├─ markAttendanceForLeave(): INSERT/UPDATE hst_attendance_entries status='leave'
    │       │     for all (hostel, date, shift) sessions in date range
    │       ├─ markMessAttendanceForLeave(): INSERT/UPDATE hst_mess_attendance status='on_leave'
    │       │     for all meals in date range
    │       ├─ Dispatch: SendLeavePassApprovalNotification job → parent SMS/push
    │       └─ Return: leave pass PDF available for print
    │
    ├─3b. REJECT:
    │       ├─ UPDATE hst_leave_passes: status='rejected', rejection_reason
    │       └─ Notify applicant staff
    │
[Warden — on student's return]
    │
    ├─4. Mark student as RETURNED:
    │       ├─ LeavePassService::markReturned($pass, $actual_return_date)
    │       ├─ UPDATE hst_leave_passes: status='returned', actual_return_date
    │       ├─ If actual_return_date > to_date:
    │       │     └─ IncidentService::createAutoIncident(type='late_arrival', student, hostel)
    │       └─ Parent notification: student returned safely
```

### 9.3 Room Change Request Workflow 📐

```
[Student / Staff on behalf]
    │
    ├─1. Submit hst_room_change_requests
    │       Fields: from_allotment_id, requested_room_id (optional), reason
    │
[Block Warden / Chief Warden]
    │
    ├─2. Review request
    ├─3a. APPROVE:
    │       ├─ Identify target bed (warden selects if student left it optional)
    │       ├─ AllotmentService::transfer($oldAllotment, $targetBed)
    │       │       ├─ UPDATE old allotment: status='transferred', vacating_date=today
    │       │       ├─ UPDATE old bed: status='available'
    │       │       ├─ UPDATE old room: current_occupancy - 1
    │       │       ├─ INSERT new allotment: status='active'
    │       │       ├─ UPDATE new bed: status='occupied'
    │       │       ├─ UPDATE new room: current_occupancy + 1
    │       │       └─ HostelFeeService::calculateRoomChangeDifferential()
    │       ├─ UPDATE request: status='approved', new_allotment_id
    │       └─ Notify student/staff
    │
    └─3b. REJECT:
            └─ UPDATE request: status='rejected', rejection_reason
```

### 9.4 Sick Bay Admission Workflow 📐

```
[Medical Staff / Warden]
    │
    ├─1. Admit student to sick bay
    │       Fields: student_id, admission_datetime, presenting_symptoms, initial_diagnosis
    │       Check: sick bay not at capacity (hst_hostels.sick_bay_capacity)
    │
    ├─2. Auto-mark hostel attendance 'sick_bay' for current shift and future shifts
    │       during expected admission period (or until discharge)
    │
    ├─3. Dispatch: SendSickBayAdmissionNotification job → parent SMS/push
    │
[Medical Staff / Warden — on recovery]
    │
    ├─4. Update treatment notes periodically
    │
    ├─5a. DISCHARGE (recovered):
    │       ├─ UPDATE hst_sick_bay_log: discharge_datetime, discharge_notes
    │       ├─ Resume normal attendance auto-marking
    │       └─ Parent notification: student discharged
    │
    └─5b. HOSPITAL REFERRAL:
            ├─ SET is_hospital_referred = 1
            ├─ Link to HPC module record (hpc_record_id)
            └─ Parent notification: referred to hospital
```

---

## 10. Authorization and RBAC

### 10.1 Permission Strings 📐

```
hostel.hostel.viewAny
hostel.hostel.create
hostel.hostel.update
hostel.hostel.delete
hostel.floor.viewAny
hostel.floor.create
hostel.floor.update
hostel.room.viewAny
hostel.room.create
hostel.room.update
hostel.bed.viewAny
hostel.bed.create
hostel.bed.update
hostel.warden.manage
hostel.allotment.viewAny
hostel.allotment.create
hostel.allotment.transfer
hostel.allotment.vacate
hostel.allotment.bulk-vacate
hostel.rcr.viewAny
hostel.rcr.approve
hostel.leave.viewAny
hostel.leave.create
hostel.leave.approve
hostel.leave.print
hostel.attendance.viewAny
hostel.attendance.create
hostel.attendance.update
hostel.attendance.lock
hostel.movement.manage
hostel.incident.viewAny
hostel.incident.create
hostel.incident.escalate
hostel.incident.warning-letter
hostel.mess.menu.manage
hostel.mess.diet.manage
hostel.mess.attendance.mark
hostel.fee.viewAny
hostel.fee.manage
hostel.complaint.viewAny
hostel.complaint.create
hostel.complaint.manage
hostel.visitor.manage
hostel.sickbay.manage
hostel.inventory.manage
hostel.report.view
hostel.report.export
```

### 10.2 Role-Permission Matrix 📐

| Permission Area | School Admin | Chief Warden | Block/Floor Warden | Mess Supervisor | Accountant | Medical Staff |
|---|---|---|---|---|---|---|
| Hostel / Floor / Room / Bed Setup | Full | View | View | View | View | View |
| Warden Assignment | Full | View | View | — | — | — |
| Student Allotment | Full | Full | Own floor | — | View | — |
| Room Change Requests | Full | Approve | Own floor approve | — | — | — |
| Leave Pass | Full | Approve all | Own floor approve | — | View | — |
| Attendance | Full | Full | Own floor | — | — | — |
| Movement Log | Full | Full | Own floor | — | — | — |
| Mess Menu & Special Diets | Full | Full | View | Full | — | View |
| Mess Attendance | Full | Full | View | Full | — | — |
| Incidents | Full | Full | Own floor | — | — | — |
| Hostel Complaint | Full | Full | Own floor | Own floor | — | — |
| Visitor Log | Full | Full | Own floor | — | — | — |
| Sick Bay | Full | Full | View | — | — | Full |
| Fee Structure | Full | View | — | — | Full | — |
| Room Inventory | Full | Full | Own floor | — | — | — |
| Reports | Full | Full | Own floor | Mess only | Fee/Defaulter | Sick Bay |

### 10.3 Proposed Policies 📐

`HostelPolicy`, `FloorPolicy`, `RoomPolicy`, `BedPolicy`, `AllotmentPolicy`, `LeavePassPolicy`, `AttendancePolicy`, `IncidentPolicy`, `MessMenuPolicy`, `HstComplaintPolicy`, `VisitorLogPolicy`, `SickBayPolicy`

---

## 11. Integration Points

### 11.1 Inbound Dependencies

| Module | Table/Service | Used By HST For |
|---|---|---|
| StudentProfile (`std_*`) | `std_students` | Student FK in all allocation, attendance, leave, incident tables |
| SchoolSetup (`sch_*`) | `sch_academic_sessions` | Academic session scoping on allotments, fee structures, menus |
| System | `sys_users` | Warden staff references (warden_id, approved_by, created_by) |
| System | `sys_media` | Incident photo/document attachments via `hst_incident_media` |
| System | `sys_activity_logs` | Audit trail for bulk-vacate, allotment changes, leave approvals |

### 11.2 Outbound Integrations

| Event | Target Module | Mechanism | Description |
|---|---|---|---|
| Bed allotted | StudentFee (`fin_*`) | `HostelFeeService::pushFeeDemand()` — direct service call within tenant | Hostel fee demand pushed to fin_fee_head_master; room rent + mess + ancillary as separate fee items |
| Room change | StudentFee (`fin_*`) | `HostelFeeService::calculateRoomChangeDifferential()` | Credit old room, charge new room for remaining month days |
| Vacating mid-month | StudentFee (`fin_*`) | `HostelFeeService::calculateVacatingRefund()` | Prorated refund pushed to StudentFee as credit note |
| Damage charge recovery | StudentFee (`fin_*`) | `HostelFeeService::pushDamageCharge()` | Ad-hoc charge item for responsible student |
| Leave pass approved | Notification module | `event(new LeavePassApproved($pass))` → queued listener | Parent SMS/push: leave dates, destination, approving warden |
| Incident (moderate/serious) | Notification module | `event(new HostelIncidentRecorded($incident))` → queued listener | Parent SMS/push: incident summary, action taken |
| Absent from roll call | Notification module | `event(new HostelAbsenceDetected($entry))` → queued listener | Parent SMS/push: student absent at roll call |
| Sick bay admission | Notification module | `event(new SickBayAdmissionRecorded($log))` → queued listener | Parent SMS/push: student admitted to sick bay |
| Hospital referral | HPC module | `hst_sick_bay_log.hpc_record_id` set; HPC module reads on link | Detailed medical follow-up in HPC; sick bay record links to HPC case |
| Attendance below threshold | Notification module | Scheduled job `SendAttendanceThresholdAlerts` (daily) | Parent notification: attendance warning |

### 11.3 Notification Events Detail 📐

| Event Class | Payload | Notification Channels |
|---|---|---|
| `LeavePassApproved` | student, from_date, to_date, destination, warden_name | SMS, Push, Email (configurable) |
| `LeavePassRejected` | student, rejection_reason | SMS, Push |
| `StudentReturned` | student, actual_return_date, is_late | SMS, Push |
| `HostelIncidentRecorded` | student, incident_type, severity, action_taken | SMS, Push (for moderate/serious) |
| `HostelAbsenceDetected` | student, date, shift, hostel | SMS, Push |
| `SickBayAdmissionRecorded` | student, admission_time, symptoms | SMS, Push |
| `SickBayDischarged` | student, discharge_time | SMS, Push |

---

## 12. Service Layer Architecture

### 12.1 Proposed Services 📐

| Service | Responsibility |
|---|---|
| 📐 `AllotmentService` | Create allotment, validate bed availability + gender + fee structure, update bed/room occupancy, transfer, bulk-vacate |
| 📐 `LeavePassService` | Approval workflow, auto-mark attendance and mess attendance, dispatch parent notifications, mark returned, detect late return and create auto-incident |
| 📐 `HstAttendanceService` | Create session, bulk-mark entries, compute summary counts, validate uniqueness, lock session |
| 📐 `IncidentService` | Record incident, classify severity, trigger notifications, escalate to principal, generate warning letter PDF via DomPDF |
| 📐 `HostelFeeService` | Look up fee structure for room type + meal plan, calculate monthly charge, calculate prorated amounts for mid-month events, push fee demand to StudentFee module |
| 📐 `HstComplaintService` | Create complaint, compute SLA due_at, assign to staff, resolve, escalate overdue complaints |
| 📐 `SickBayService` | Admit student, auto-mark attendance as sick_bay, dispatch admission notification, discharge, flag hospital referral |

### 12.2 Proposed Controllers 📐

| Controller | Screens Managed |
|---|---|
| 📐 `HstDashboardController` | Dashboard — occupancy, today's attendance, pending passes, open incidents, sick bay |
| 📐 `HostelController` | Hostel CRUD + facility management |
| 📐 `FloorController` | Floor CRUD |
| 📐 `RoomController` | Room CRUD + status toggle |
| 📐 `BedController` | Bed CRUD + maintenance flag |
| 📐 `WardenAssignmentController` | Warden assignments + history |
| 📐 `AllotmentController` | Allotment CRUD + vacate + transfer + bulk-vacate + availability check |
| 📐 `RoomChangeRequestController` | Room change request + approval/rejection workflow |
| 📐 `HstAttendanceController` | Attendance session + bulk mark + lock |
| 📐 `MovementLogController` | In-out movement register + pending returns |
| 📐 `LeavePassController` | Leave pass CRUD + approve + return + print + calendar view |
| 📐 `IncidentController` | Incident CRUD + escalate + warning letter + parent notify |
| 📐 `MessMenuController` | Weekly menu setup + copy-week |
| 📐 `SpecialDietController` | Special diet assignment per student |
| 📐 `MessAttendanceController` | Meal attendance marking + monthly report |
| 📐 `HstFeeController` | Fee structure CRUD + calculate + defaulters |
| 📐 `HstComplaintController` | Hostel complaint register + assign + resolve + escalate |
| 📐 `VisitorLogController` | Visitor register + checkout |
| 📐 `SickBayController` | Sick bay admissions + discharge + current occupancy |
| 📐 `HstReportController` | All 12 report types + export |

### 12.3 Proposed FormRequests 📐

`StoreHostelRequest`, `StoreFloorRequest`, `StoreRoomRequest`, `StoreBedRequest`,
`StoreWardenAssignmentRequest`, `StoreAllotmentRequest`, `TransferAllotmentRequest`,
`BulkVacateRequest`, `StoreRoomChangeRequest`, `StoreHstAttendanceRequest`,
`BulkMarkAttendanceRequest`, `StoreMovementLogRequest`, `StoreLeavePassRequest`,
`ApproveLeavePassRequest`, `MarkReturnedRequest`, `StoreIncidentRequest`,
`StoreMessMenuRequest`, `StoreSpecialDietRequest`, `StoreMessAttendanceRequest`,
`BulkMessAttendanceRequest`, `StoreHstFeeStructureRequest`, `StoreHstComplaintRequest`,
`ResolveComplaintRequest`, `StoreVisitorLogRequest`, `StoreSickBayRequest`,
`DischargeSickBayRequest`, `StoreRoomInventoryRequest`

### 12.4 Proposed Events and Jobs 📐

**Events:**
- `LeavePassApproved`, `LeavePassRejected`, `StudentReturned`
- `HostelIncidentRecorded`, `HostelAbsenceDetected`
- `SickBayAdmissionRecorded`, `SickBayDischarged`

**Queued Jobs:**
- `SendHstNotificationJob` — generic notification dispatcher used by all events above
- `SendHstComplaintEscalationJob` — runs hourly via Laravel scheduler; checks SLA breach and escalates

---

## 13. Test Coverage

### 13.1 Proposed Feature Tests 📐

| Test Class | Test Scenarios |
|---|---|
| 📐 `HostelInfrastructureTest` | Create hostel, create floor, create room, create beds; gender type on hostel; capacity auto-update; deactivation blocked with active allotments |
| 📐 `AllotmentTest` | Allot student to bed; prevent double-allotment on same bed; prevent two active allotments per student; gender mismatch rejection; vacate bed reverts status; transfer executes correctly; bulk-vacate with audit log |
| 📐 `RoomChangeRequestTest` | Submit request; approve executes transfer; reject returns reason; fee recalculation on approval |
| 📐 `LeavePassTest` | Apply leave pass; approve dispatches notification; attendance auto-marked on approval; mess auto-marked on approval; mark returned; late return auto-creates incident; cancel |
| 📐 `HstAttendanceTest` | Create session; bulk mark present; mark individual exceptions; prevent duplicate session; summary counts computed; lock after 24h |
| 📐 `IncidentTest` | Record minor incident (no auto-notification); record moderate (notification dispatched); record serious (notification + escalation prompt); auto-incident from late return |
| 📐 `MessMenuTest` | Create weekly menu; duplicate prevention; copy-week function; special diet assignment; auto-absent on leave approval |
| 📐 `HstFeeTest` | Configure fee structure; calculate monthly fee on allotment; prorated mid-month allotment; prorated vacating refund; room change differential |
| 📐 `HstComplaintTest` | Lodge complaint; assign to staff; resolve; SLA breach escalation |
| 📐 `SickBayTest` | Admit student; attendance auto-marked sick_bay; parent notification dispatched; discharge; hospital referral flag |
| 📐 `VisitorLogTest` | Log visitor; checkout; out-of-hours override requires reason |

### 13.2 Proposed Unit Tests 📐

| Test Class | Scenarios |
|---|---|
| 📐 `AllotmentServiceTest` | Bed availability check logic; gender validation; double-allotment detection |
| 📐 `LeavePassServiceTest` | Date range calculation for attendance auto-mark; late return detection logic |
| 📐 `HostelFeeServiceTest` | Prorated calculation: mid-month allotment, mid-month vacate, room change differential |
| 📐 `HstComplaintServiceTest` | SLA due_at computation for different priority levels |

---

## 14. Implementation Status

| Component | Status |
|---|---|
| Module directory structure (`Modules/Hostel/`) | ❌ Not Started |
| DDL Migrations (20 tables) | ❌ Not Started |
| Eloquent Models (20) | ❌ Not Started |
| Controllers (20) | ❌ Not Started |
| Services (7) | ❌ Not Started |
| FormRequests (27) | ❌ Not Started |
| Policies (12) | ❌ Not Started |
| Blade Views (~65) | ❌ Not Started |
| Seeders (2 — RoomTypes, IncidentTypes) | ❌ Not Started |
| Routes (tenant.php — ~65 routes) | ❌ Not Started |
| Events (7) | ❌ Not Started |
| Queued Jobs (2) | ❌ Not Started |
| Leave Pass PDF Print (DomPDF) | ❌ Not Started |
| Warning Letter PDF (DomPDF) | ❌ Not Started |
| Parent Notification Events | ❌ Not Started |
| StudentFee Integration (`HostelFeeService`) | ❌ Not Started |
| HPC Module Link (sick bay referral) | ❌ Not Started |
| Feature Tests (11 test classes) | ❌ Not Started |
| Unit Tests (4 test classes) | ❌ Not Started |
| Dashboard Charts (occupancy trend) | ❌ Not Started |

---

## 15. Known Issues and Technical Debt

### 15.1 Pre-Development Clarifications Required

1. **Academic Session FK**: Verify exact table name — `sch_academic_sessions` vs `sch_academic_terms` vs `sch_sessions` in the current tenant DDL (`1-master_dbs/1-DDL_schema/tenant_db.sql`) before writing migrations. Use confirmed name exclusively.

2. **Student FK Table**: Confirmed as `std_students` per project conventions. Do not reference `students` or `sch_students`.

3. **StudentFee Integration Mechanism**: The service-to-service call between `HostelFeeService` and StudentFee module needs formal interface definition. Options: (a) direct Eloquent INSERT into `fin_fee_demands` table, (b) event-based (`HostelFeeAssigned` event listened by StudentFee), (c) formal service interface class. Decide before Phase 5 build begins.

4. **HPC Module Interface for Sick Bay Referral**: `hst_sick_bay_log.hpc_record_id` stores a reference to the HPC module record. The mechanism for creating the HPC record (auto-create vs manual link) must be defined when HPC module is built. For now the column is nullable; link is manual.

5. **Mess vs `mes_*` Module Overlap**: Hostel mess (hst_mess_*) is treated as HST-internal in this document. If a separate `mes_*` Mess Management module is built for school canteen, review table ownership. The `hst_mess_*` tables remain exclusive to hostel boarders.

6. **Partial Unique Index for Active Allotments**: MySQL 8.x supports partial indexes via generated columns. The implementation `gen_active_bed AS (IF(status='active', bed_id, NULL)) STORED` + `UNIQUE (gen_active_bed)` needs to be tested with soft-deleted rows (deleted_at is not NULL). The generated column expression must also include a null-out for soft-deleted rows.

7. **Notification Module Interface**: Events listed in Section 11 require the Notification module to have listeners registered for `LeavePassApproved`, `HostelIncidentRecorded`, etc. Coordinate with Notification module developer on event class contracts.

### 15.2 Design Gaps to Resolve

- **Warden Rotation Alerts**: When a warden assignment expires (`effective_to = today`), the hostel should not be left without a floor warden. A scheduled check should alert the admin if any floor has no current warden assignment.
- **Leave Pass Calendar View**: Planned as a high-value UI feature (calendar showing who is on leave on any day); route is proposed (`hostel.leave.calendar`) but view spec is deferred to UI phase.
- **Waitlist Auto-Promotion**: When a bed becomes available and a waitlisted student exists, who gets the notification and how is the promotion managed? Manual trigger by warden is the initial approach; auto-promotion via job is a Phase 2 enhancement.
- **Mess Charge Calculation Frequency**: Monthly mess charge is computed from `hst_mess_attendance` count. The trigger for pushing this to StudentFee (end of month, manual trigger, or real-time deduction) needs definition.
- **Repeated Offender Threshold**: BR-HST-022 says 3+ incidents = flagged. This threshold should be configurable per school via `sys_settings` rather than hard-coded.
- **Room Inventory Link to Accounting**: Damage charge recovery calls `HostelFeeService::pushDamageCharge()` but the target in StudentFee module (which fee head, which demand type) must be specified.

---

## 16. Development Priorities and Recommendations

### 16.1 Phased Development Sequence

Build in this order to respect FK dependencies and deliver working value early:

| Phase | Components | Deliverable |
|---|---|---|
| Phase 1 — Infrastructure | `hst_hostels`, `hst_floors`, `hst_rooms`, `hst_beds` + controllers + seeders + basic dashboard | Hostel setup screens; room/bed browser |
| Phase 2 — Warden & Allotment | `hst_warden_assignments`, `hst_allotments`, `hst_room_change_requests` + `AllotmentService` | Full allocation workflow; gender validation; scoped warden access |
| Phase 3 — Attendance & Movement | `hst_attendance`, `hst_attendance_entries`, `hst_movement_log` + `HstAttendanceService` | Daily roll call; in-out gate pass register |
| Phase 4 — Leave Pass | `hst_leave_passes` + `LeavePassService` + notification events | Leave pass workflow; auto-attendance mark; parent notifications |
| Phase 5 — Fee Structure | `hst_fee_structures` + `HostelFeeService` + StudentFee integration | Hostel fee calculation; fee demand push |
| Phase 6 — Discipline | `hst_incidents`, `hst_incident_media` + `IncidentService` + DomPDF warning letter | Incident register; warning letter; escalation |
| Phase 7 — Mess | `hst_mess_weekly_menus`, `hst_special_diets`, `hst_mess_attendance` + controllers | Mess menu; special diet; meal attendance |
| Phase 8 — Support Features | `hst_complaints`, `hst_visitor_log`, `hst_sick_bay_log`, `hst_room_inventory` + services | Complaint register; visitor log; sick bay; room inventory |
| Phase 9 — Reports & Analytics | `HstReportController` all 12 reports + dashboard analytics + export | Full reporting suite; occupancy analytics |

### 16.2 Key Recommendations

- **Implement Scoped Warden Access Early**: The `WardenScopeMiddleware` + `HostelScope` must be built in Phase 1/2 to avoid retrofitting across all subsequent features. Every warden-facing controller action must apply the scope.
- **Attendance Caching**: Store `present_count`, `absent_count`, `leave_count`, `late_count` in `hst_attendance` session record at save time (not computed on every report load) — critical for 500+ student hostels.
- **Idempotent Attendance Submit**: The attendance save endpoint must use `upsert()` semantics — re-submitting the same (attendance_id, student_id) must UPDATE not INSERT DUPLICATE. Handle via `updateOrCreate()` in service.
- **Queue Configuration**: All parent notification jobs and the complaint escalation job must run on a dedicated queue (`hostel`) separate from the default queue to prevent blocking other modules.
- **Academic Year Reset Wizard**: Bulk-vacate is a high-risk, one-time operation per year. Build with: explicit confirmation step (type "CONFIRM" text), dry-run preview showing affected students, full audit log in `sys_activity_logs`, and email receipt to admin.
- **Leave Calendar View**: Calendar showing who is on leave on any date is a high-value UI feature — plan view infrastructure early even if populated in Phase 4.
- **Mobile-First Attendance UI**: Wardens mark attendance on tablets during physical roll call. Design the attendance marking view for mobile-first layout; pre-load the student list for offline resilience (service worker or simple form caching).
- **Merge Mess with Hostel**: Keep all `hst_mess_*` tables in HST module. Do not split to `mes_*` unless a separate standalone canteen module is definitively required. Review `mes_*` directory for overlap before starting Phase 7.

---

*Document Version 2.0 | Generated 2026-03-26 | Processing Mode: RBS_ONLY | All features ❌ Not Started*
