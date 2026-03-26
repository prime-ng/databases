# Hostel Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Greenfield RBS-Only)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** HST | **Module Path:** `Modules/Hostel/`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `hst_*`
**Processing Mode:** RBS_ONLY — Greenfield (No code, no DDL exists)
**RBS Reference:** Module O — Hostel Management (36 sub-tasks, lines 3334–3430)

> All features are **❌ Not Started**. All proposed items are marked **📐**.

---

## Table of Contents

1. [Module Overview](#1-module-overview)
2. [Business Context](#2-business-context)
3. [Scope and Boundaries](#3-scope-and-boundaries)
4. [Functional Requirements](#4-functional-requirements)
5. [Non-Functional Requirements](#5-non-functional-requirements)
6. [Database Schema](#6-database-schema)
7. [API and Routes](#7-api-and-routes)
8. [Business Rules](#8-business-rules)
9. [Authorization and RBAC](#9-authorization-and-rbac)
10. [Service Layer Architecture](#10-service-layer-architecture)
11. [Integration Points](#11-integration-points)
12. [Test Coverage](#12-test-coverage)
13. [Implementation Status](#13-implementation-status)
14. [Known Issues and Technical Debt](#14-known-issues-and-technical-debt)
15. [Development Priorities and Recommendations](#15-development-priorities-and-recommendations)

---

## 1. Module Overview

The Hostel module is a comprehensive residential management system for Indian boarding schools (residential/convent schools) operating on the Prime-AI SaaS ERP platform. It manages the complete lifecycle of hostel operations — from infrastructure setup and student room allotment to daily attendance, leave passes, mess meal tracking, hostel fee management, discipline incident recording, and occupancy analytics.

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Hostel Management |
| Module Code | HST |
| nwidart Module Namespace | `Modules\Hostel` |
| Module Path | `Modules/Hostel/` |
| Route Prefix | `hostel/` |
| Route Name Prefix | `hostel.` |
| DB Table Prefix | `hst_*` |
| Module Type | Tenant (per-school, database-per-tenant via stancl/tenancy v3.9) |
| Registered In | `routes/tenant.php` |
| Status | 📐 Greenfield — Not Started |

### 1.2 Module Scale (Proposed)

| Metric | Count |
|---|---|
| Controllers | 📐 12 |
| Models | 📐 15 |
| Services | 📐 5 |
| FormRequests | 📐 14 |
| Policies | 📐 10 |
| DDL Tables | 📐 15 (`hst_*` prefix) |
| Views | 📐 ~55 Blade templates |
| Seeders | 📐 1 (Room Types) |

---

## 2. Business Context

### 2.1 Business Purpose

Residential schools (boarding schools) in India house hundreds to thousands of students on campus. Managing this operation manually via registers and paper forms is error-prone, slow, and creates compliance and safety risks. The Hostel module solves:

1. **Room & Bed Tracking**: Schools cannot efficiently allocate beds, track vacancies, or manage room changes without a centralized system.
2. **Student Safety**: Daily attendance at morning, evening, and night roll calls is a legal and safety requirement. Late entries and unexplained absences must be recorded immediately.
3. **Leave Pass Control**: Students leaving campus on weekends or holidays require formal leave passes with guardian authorization; paper passes go missing.
4. **Discipline Records**: Incident tracking is required by management and sometimes by CBSE/state board inspection.
5. **Mess/Meal Visibility**: Monthly meal attendance feeds into mess billing. Special diet tracking is a medical/allergy requirement.
6. **Hostel Fee Recovery**: Hostel charges (room rent, mess charges, electricity) must be systematically tracked and linked to the school fee management system.
7. **Occupancy Analytics**: School management needs occupancy rates by block/floor/room type to plan infrastructure and justify fee revisions.

### 2.2 Primary Users

| Role | Primary Actions |
|---|---|
| School Admin / Principal | Full hostel access; policy configuration |
| Hostel Warden (Chief) | Full hostel operations; approval authority |
| Block Warden / Assistant Warden | Block-level attendance, leave pass approval, incident recording |
| Mess Supervisor | Meal plan setup, mess attendance marking |
| Accountant | Hostel fee view, prorated calculations |
| Student (Portal — future) | View own allotment, apply for leave pass |
| Parent (Portal — future) | View child's leave pass status, receive alerts |

### 2.3 Indian Residential School Context

- **Hostel Types**: Boys' Hostel, Girls' Hostel (strictly segregated in Indian schools), Mixed (rare, usually day-boarding)
- **Boarding School Population**: 50 to 2,000 boarders depending on school size
- **Warden Hierarchy**: Chief Warden → Block Warden → Floor Incharge (typically teaching staff on rotation)
- **Attendance Cadence**: 3 times daily (morning assembly, dinner roll call, lights-out check) — called "Roll Call"
- **Leave Types**: Weekly home leave, emergency leave, medical leave, vacation leave
- **Mess Structure**: Centralized mess serving breakfast, lunch, and dinner; special diets for medical/religious reasons (diabetic, Jain, allergies, fasting)
- **Hostel Fee Components**: Room rent (by room type), mess charges (per meal plan), electricity/water charges, laundry charges, security deposit
- **Hostel Inventory**: Each room has beds, mattresses, study tables, chairs, cupboards — damage reporting is a routine requirement
- **Regulatory Context**: CBSE boarding schools must submit hostel inspection reports; state government boarding schemes require attendance and fee records
- **Academic Year Reset**: Room allotments typically expire at academic year end; new allotments issued fresh each year

---

## 3. Scope and Boundaries

### 3.1 In-Scope Features

- Hostel infrastructure setup: hostels, blocks, floors, rooms, beds
- Gender-based allocation restrictions (boys/girls hostel)
- Room type configuration (single, double, dormitory) with capacity rules
- Student allotment to specific beds with academic year scoping
- Room change request workflow (student request → warden approval)
- Warden assignment: chief warden to hostel, block warden to block
- Daily attendance (morning / evening / night) with shift-wise marking
- In-out movement register (departure time, return time, purpose)
- Leave pass workflow: application → parent/guardian consent → warden approval → execution → return
- Leave pass status: pending, approved, rejected, returned (student back)
- Discipline and incident management with severity classification
- Warning letter generation and parent notification on incidents
- Mess meal plan definition and weekly menu setup
- Special diet assignment per student
- Mess attendance marking per meal per student
- Hostel-related fee configuration (room type rates, mess rates)
- Prorated fee calculation for mid-month allotment or room change
- Hostel inventory items per room (beds, furniture) with damage reporting
- Reports: Occupancy, Attendance (student-wise, date-wise), Leave Register, Fee Defaulters, Incident Register, Room Utilization
- Dashboard: live occupancy stats, today's attendance summary, pending leave passes, open incidents

### 3.2 Out of Scope

- Student academic profile, class, and marks — handled by **StudentProfile module** (`std_*`)
- School fee collection (payment gateway, receipts) — handled by **StudentFee module** (`fin_*`)
- Visitor management (external visitors to school campus) — handled by **Frontdesk module**
- School canteen / cafeteria for day-scholars — handled by **Mess Management module** (`mes_*`) when applicable
- Medical records, hospital visits — handled by **Health & Physical Condition (HPC) module**
- Staff accommodation (if school provides staff quarters) — not in scope for this module
- CCTV / access control hardware integration

---

## 4. Functional Requirements

### 4.1 O1 — Hostel & Room Setup

**RBS Ref:** F.O1.1 — Hostel Configuration, F.O1.2 — Room Setup

#### FR-HST-001: Hostel Configuration 📐

- 📐 **Create Hostel**: Name (required, max 150 chars), type (boys / girls / mixed), address, total capacity (computed or manually set), warden assignment (FK → sys_users), contact phone, facilities list (JSON array — e.g., WiFi, Common Room, Indoor Sports, Medical Room, Laundry)
- 📐 **Facilities Management**: Define available facilities per hostel; rules for facility usage (e.g., WiFi access hours)
- 📐 **Multiple Hostels**: A school may operate multiple hostels (separate boys' and girls' buildings; old block and new block)
- 📐 **Hostel Deactivation**: Soft-delete with audit log; active allotments prevent deactivation

#### FR-HST-002: Block and Floor Management 📐

- 📐 **Create Block**: Block name, hostel reference, number of floors, block warden assignment (FK → sys_users, nullable)
- 📐 **Floor Organization**: Blocks have multiple floors; rooms are on floors
- 📐 **Block Warden**: Each block can have a designated warden for daily management

#### FR-HST-003: Room Setup 📐

- 📐 **Create Room**: Room number (required, unique within block), floor number, room type (single / double / dormitory), total capacity (beds), amenities JSON (e.g., attached bathroom, AC, ceiling fan, window), current occupancy (computed from active allotments)
- 📐 **Gender Restriction**: Room inherits hostel's gender type; boys' hostel rooms cannot be allotted to girls
- 📐 **Priority Allocation Rules**: Priority flags for rooms — e.g., medical priority, senior students, merit-based
- 📐 **Room Status**: Available, Full, Under Maintenance

#### FR-HST-004: Bed Management 📐

- 📐 **Create Bed**: Bed number within room (e.g., Bed A, Bed B, Bed 1, Bed 2), status (available / occupied / under maintenance)
- 📐 **Bed Status Tracking**: Status auto-updates: available → occupied on allotment, occupied → available on vacating
- 📐 **Maintenance Flag**: Mark individual beds as under maintenance (damaged, repairs pending)

| RBS Sub-Task | Status |
|---|---|
| ST.O1.1.1.1 — Define hostel name & address | 📐 Not Started |
| ST.O1.1.1.2 — Assign warden & contact details | 📐 Not Started |
| ST.O1.1.2.1 — List available facilities | 📐 Not Started |
| ST.O1.1.2.2 — Define facility usage rules | 📐 Not Started |
| ST.O1.2.1.1 — Define room number/type | 📐 Not Started |
| ST.O1.2.1.2 — Set room capacity | 📐 Not Started |
| ST.O1.2.2.1 — Set gender-based restrictions | 📐 Not Started |
| ST.O1.2.2.2 — Set priority allocation rules | 📐 Not Started |

### 4.2 O2 — Student Allotment & Movement

**RBS Ref:** F.O2.1 — Room Allotment, F.O2.2 — Room Change Requests

#### FR-HST-005: Student Bed Allotment 📐

- 📐 **Allot Student to Bed**: Select student (FK → std_students), select hostel > block > room > bed, allotment date, academic session/year scoping, status = 'active'
- 📐 **Availability Check**: System prevents double-allotment — a bed cannot be assigned to two students simultaneously
- 📐 **Gender Validation**: Student's gender must match hostel type; girls cannot be allotted to boys' hostels
- 📐 **Vacating**: Record vacating date; bed status reverts to 'available'; allotment status = 'vacated'
- 📐 **Transfer**: Move student to another bed within same or different hostel; old allotment marked 'transferred'; new allotment created
- 📐 **Academic Year Reset**: Bulk vacate all allotments at year-end; bulk re-allotment wizard for new year

#### FR-HST-006: Room Change Request Workflow 📐

- 📐 **Student/Parent Room Change Request**: Student submits room change request with reason; target room optional
- 📐 **Warden Review**: Block Warden or Chief Warden approves or rejects; rejection requires reason
- 📐 **On Approval**: System executes transfer — vacates old bed, allots to new bed
- 📐 **Request History**: Full history of room change requests per student per academic year

| RBS Sub-Task | Status |
|---|---|
| ST.O2.1.1.1 — Select student | 📐 Not Started |
| ST.O2.1.1.2 — Assign room & bed number | 📐 Not Started |
| ST.O2.2.1.1 — Record room change reason | 📐 Not Started |
| ST.O2.2.1.2 — Approve/Reject request | 📐 Not Started |

### 4.3 O3 — Attendance & In-Out Register

**RBS Ref:** F.O3.1 — Daily Attendance, F.O3.2 — In-Out Register

#### FR-HST-007: Hostel Daily Attendance 📐

- 📐 **Attendance Session**: Create an attendance session for a hostel, on a specific date, for a shift (morning / evening / night), marked by a warden
- 📐 **Mark Attendance**: Per student, mark status: present / absent / leave (on approved leave pass) / home (home weekend)
- 📐 **Late Entry Remarks**: Capture textual remarks when marking late arrival for a student
- 📐 **Bulk Mark**: Mark all as present, then individually update exceptions (efficiency feature)
- 📐 **Prevent Duplicate**: One attendance session per (hostel, date, shift) — cannot be created twice
- 📐 **Attendance Lock**: Once marked and saved, attendance can only be edited by Warden (Chief) within 24 hours

#### FR-HST-008: In-Out Movement Register 📐

- 📐 **Log Out-Movement**: Record student out-time, destination/reason, expected return time
- 📐 **Log In-Movement**: Record actual return time when student comes back
- 📐 **Pending Returns**: Dashboard alert for students who went out but have not returned past expected time
- 📐 **Movement Register Report**: Date-wise, student-wise log of all movements

| RBS Sub-Task | Status |
|---|---|
| ST.O3.1.1.1 — Mark present/absent | 📐 Not Started |
| ST.O3.1.1.2 — Capture late entry remarks | 📐 Not Started |
| ST.O3.2.1.1 — Record out-time & reason | 📐 Not Started |
| ST.O3.2.1.2 — Record in-time | 📐 Not Started |

### 4.4 O4 — Mess Management (Hostel-side)

**RBS Ref:** F.O4.1 — Meal Planning, F.O4.2 — Mess Attendance

#### FR-HST-009: Mess Meal Plan & Menu 📐

- 📐 **Weekly Menu Setup**: Define meal plan for each week — for each day (Mon–Sun), for each meal (breakfast / lunch / dinner / snacks), specify menu items
- 📐 **Special Diet Assignment**: Assign special diet categories per student — Diabetic, Jain Vegetarian, Gluten-Free, Religious Fasting, Allergies (specify); special diet schedules maintained separately
- 📐 **Meal Plan Scheduling**: Menu can be set per academic session; weekly template reused across weeks with override capability

#### FR-HST-010: Mess Attendance 📐

- 📐 **Mark Meal Attendance**: Per meal per day, record each student's meal consumption status (present / absent)
- 📐 **Special Diet Served**: Flag when special diet was served to eligible student; record actual special diet served
- 📐 **Monthly Mess Report**: Total meals consumed per student per month — feeds into mess charge calculation for billing
- 📐 **Opt-Out Tracking**: Students on approved leave automatically marked absent for meals during leave period

| RBS Sub-Task | Status |
|---|---|
| ST.O4.1.1.1 — Set meal plan for week | 📐 Not Started |
| ST.O4.1.1.2 — Assign special diet schedules | 📐 Not Started |
| ST.O4.2.1.1 — Track meal consumption | 📐 Not Started |
| ST.O4.2.1.2 — Record special diet served | 📐 Not Started |

### 4.5 O5 — Hostel Fee Management

**RBS Ref:** F.O5.1 — Fee Assignment, F.O5.2 — Fee Adjustments

#### FR-HST-011: Hostel Fee Configuration 📐

- 📐 **Fee Structure Setup**: Define fee rates per room type (single / double / dormitory) per academic session — e.g., Single Room: INR 3,000/month, Double Room: INR 2,000/month
- 📐 **Mess Charges**: Configure mess charge per meal plan type — e.g., Full Board: INR 2,500/month; Partial (lunch only): INR 1,000/month
- 📐 **Other Components**: Electricity/water charge, laundry charge, security deposit (one-time) configurable per hostel

#### FR-HST-012: Fee Assignment to Students 📐

- 📐 **Assign Hostel Fee**: When a student is allotted a bed, system auto-calculates applicable hostel fee based on room type and selected meal plan
- 📐 **Apply Mess Charges**: Mess charges added to hostel fee invoice
- 📐 **Fee Integration**: Hostel fee components pushed to StudentFee module for inclusion in overall fee demand
- 📐 **Fee Defaulter Tracking**: Students with outstanding hostel fee balances identified; warden can view defaulters before approving leave passes

#### FR-HST-013: Prorated Fee Calculation 📐

- 📐 **Mid-Month Allotment**: Student allotted on the 15th of the month — charge for remaining days only (daily rate = monthly rate / 30 × remaining days)
- 📐 **Room Change Proration**: On room change, calculate difference between old room rate and new room rate for remaining days in month; charge/credit accordingly
- 📐 **Vacating Refund**: If student vacates mid-month, calculate refund for unused days

| RBS Sub-Task | Status |
|---|---|
| ST.O5.1.1.1 — Select student & room type | 📐 Not Started |
| ST.O5.1.1.2 — Apply mess charges | 📐 Not Started |
| ST.O5.2.1.1 — Calculate partial month fee | 📐 Not Started |
| ST.O5.2.1.2 — Apply room change difference | 📐 Not Started |

### 4.6 O5b — Leave Pass Management

**RBS Ref:** (Implied from O3 and attendance context — leave pass is a core hostel function)

#### FR-HST-014: Leave Pass Workflow 📐

- 📐 **Apply for Leave Pass**: Student (or staff on behalf) creates leave pass application — from date, to date, destination, purpose, emergency contact/guardian contact
- 📐 **Status Workflow**: Pending → Approved / Rejected → Returned (student back on campus)
- 📐 **Warden Approval**: Block Warden or Chief Warden approves/rejects with remarks; rejected applications require reason
- 📐 **Parent Notification**: On leave pass approval, send notification (SMS/push) to parent/guardian with leave details
- 📐 **Attendance Auto-Mark**: Approved leave pass auto-marks student as 'on leave' in attendance for leave period
- 📐 **Mess Opt-Out**: Meals auto-marked absent during leave period, reducing mess charges
- 📐 **Return Confirmation**: Warden marks student as 'returned' on actual return; late return flagged if after to_date
- 📐 **Leave Register**: Complete leave pass history per student per academic year, exportable as PDF

### 4.7 O6 — Discipline & Incident Management

**RBS Ref:** F.O6.1 — Discipline Tracking, F.O6.2 — Action Workflow

#### FR-HST-015: Incident Recording 📐

- 📐 **Record Incident**: Student, hostel, incident date and time, incident type (late arrival, rule violation, property damage, misconduct, other), detailed description
- 📐 **Severity Classification**: Minor, Moderate, Serious — severity drives workflow escalation
- 📐 **Supporting Documents**: Attach files (photos, witness statements) via `sys_media`
- 📐 **Action Taken**: Record action taken: verbal warning, written warning, parent notification, suspension, fine

#### FR-HST-016: Discipline Action Workflow 📐

- 📐 **Issue Warning Letter**: Generate PDF warning letter (DomPDF) for student; signed by Chief Warden; includes incident details and consequence statement
- 📐 **Parent Notification on Incident**: For Moderate/Serious incidents, auto-send notification to parent/guardian with summary of incident and action taken
- 📐 **Escalation**: Serious incidents escalated to Principal; system records escalation status
- 📐 **Incident Register Report**: Date-wise, student-wise, severity-wise incident report with filter options

| RBS Sub-Task | Status |
|---|---|
| ST.O6.1.1.1 — Enter incident description | 📐 Not Started |
| ST.O6.1.1.2 — Attach supporting documents | 📐 Not Started |
| ST.O6.2.1.1 — Send warning letter | 📐 Not Started |
| ST.O6.2.1.2 — Notify parents | 📐 Not Started |

### 4.8 O7 — Hostel Inventory Management

**RBS Ref:** F.O7.1 — Inventory Tracking, F.O7.2 — Damage Reporting

#### FR-HST-017: Room Inventory Tracking 📐

- 📐 **Assign Items to Rooms**: Record furniture and fixtures assigned to each room — beds, mattresses, study tables, chairs, cupboards, mirrors, fans — with quantity and condition (Good / Fair / Poor)
- 📐 **Item Condition Update**: Update condition periodically; track condition history
- 📐 **Inventory Audit**: Annual physical check of room items; generate discrepancy report (items present vs items recorded)

#### FR-HST-018: Damage Reporting 📐

- 📐 **Log Damage**: Record damaged item, room, date discovered, description of damage, current student occupying room at time of discovery
- 📐 **Cost Estimation**: Enter estimated repair or replacement cost; link to student for potential charge recovery
- 📐 **Repair Status**: Pending, Under Repair, Repaired, Written Off
- 📐 **Fine/Charge Recovery**: Link damage cost to student fee module for charge recovery if student is found responsible

| RBS Sub-Task | Status |
|---|---|
| ST.O7.1.1.1 — Add beds/mattresses/tables | 📐 Not Started |
| ST.O7.1.1.2 — Assign condition status | 📐 Not Started |
| ST.O7.2.1.1 — Log damaged item | 📐 Not Started |
| ST.O7.2.1.2 — Estimate repair cost | 📐 Not Started |

### 4.9 O8 — Reports & Analytics

**RBS Ref:** F.O8.1 — Hostel Reports, F.O8.2 — Analytics

#### FR-HST-019: Hostel Reports 📐

| Report Name | Description | Filters | Export |
|---|---|---|---|
| Occupancy Report | Current bed occupancy by hostel / block / room | Hostel, Block, Date | PDF, CSV |
| Room Utilization Report | Room-wise occupancy % over time | Date Range, Hostel | CSV |
| Attendance Report | Student-wise or date-wise attendance summary | Student, Date Range, Shift | PDF, CSV |
| Leave Register | All leave passes with status | Student, Date Range, Status | PDF, CSV |
| Fee Defaulter Report | Students with outstanding hostel fee | Hostel, Academic Session | CSV |
| Incident Register | All incidents by severity and type | Date Range, Student, Severity | PDF, CSV |
| Mess Attendance Report | Monthly meal consumption per student | Student, Month | PDF, CSV |
| Movement Register | In-out log for students | Date, Hostel | CSV |
| Room Inventory Report | Furniture/fixtures with condition by room | Hostel, Block, Room | CSV |
| Damage Report | Open damage records with estimated costs | Status, Date Range | CSV |

#### FR-HST-020: Analytics & Predictions 📐

- 📐 **Occupancy Trend**: Monthly occupancy percentage over academic year — bar/line chart on dashboard
- 📐 **Peak Usage Months**: Identify months with highest and lowest occupancy (correlates with exam seasons, festivals)
- 📐 **Room Demand Forecast**: Based on current enrollment trends and historical data, suggest room demand for next academic year
- 📐 **Repeated Offenders**: Students with 3+ incidents in an academic year flagged on dashboard
- 📐 **Attendance Compliance**: Students with attendance < threshold (e.g., < 90%) over last 30 days highlighted

| RBS Sub-Task | Status |
|---|---|
| ST.O8.1.1.1 — Hostel occupancy report | 📐 Not Started |
| ST.O8.1.1.2 — Room utilization report | 📐 Not Started |
| ST.O8.2.1.1 — Forecast room demand | 📐 Not Started |
| ST.O8.2.1.2 — Identify peak usage months | 📐 Not Started |

---

## 5. Non-Functional Requirements

### 5.1 Performance
- 📐 Hostel attendance marking for 500 students must complete (save to DB) within 3 seconds
- 📐 Occupancy dashboard must load within 2 seconds using cached or computed counts
- 📐 Attendance is a daily, time-sensitive operation — marking UI must work offline-capable (PWA or minimal JS fallback)

### 5.2 Reliability
- 📐 Leave pass approval triggers parent notification — notification dispatch must be async (queued) to not block UI
- 📐 Attendance session must be idempotent on save — no duplicate entries even on double-submit

### 5.3 Data Integrity
- 📐 No `tenant_id` column on any `hst_*` table — data isolation at database level
- 📐 A bed can have only one active allotment at a time — enforced by UNIQUE constraint on (bed_id) WHERE status = 'active' (application-level check + DB unique index)
- 📐 Leave pass dates must be validated: to_date >= from_date
- 📐 Soft delete with `deleted_at` on all tables — data never physically deleted

### 5.4 Security
- 📐 All routes protected by `auth` middleware under tenant context
- 📐 Gate-based permissions for every controller action (see Section 9)
- 📐 Warden staff can only see hostels/blocks they are assigned to (scoped access)
- 📐 Parent notifications contain student-specific data — must not expose other students' info

---

## 6. Database Schema

All 15 tables use the `hst_*` prefix. All tables include standard audit columns: `id` (BIGINT UNSIGNED PK), `is_active` (TINYINT(1) DEFAULT 1), `created_by` (BIGINT UNSIGNED NULL FK → sys_users), `created_at`, `updated_at`, `deleted_at`.

### 6.1 hst_hostels 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| name | VARCHAR(150) | NOT NULL | Hostel name (e.g., "Boys' Hostel Block A") |
| type | ENUM('boys','girls','mixed') | NOT NULL | Gender type |
| warden_id | BIGINT UNSIGNED | NULL FK → sys_users | Chief Warden assigned |
| total_capacity | INT | NULL | Total beds (computed or manually set) |
| address | VARCHAR(500) | NULL | Physical location/address |
| contact_phone | VARCHAR(20) | NULL | Hostel contact number |
| facilities_json | JSON | NULL | Array of facility names |
| + standard audit columns | | | |

### 6.2 hst_blocks 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Parent hostel |
| name | VARCHAR(100) | NOT NULL | Block name (e.g., "Block A", "North Wing") |
| floor_count | TINYINT | DEFAULT 1 | Number of floors in this block |
| block_warden_id | BIGINT UNSIGNED | NULL FK → sys_users | Block-level warden |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, name)`

### 6.3 hst_rooms 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| block_id | BIGINT UNSIGNED | NOT NULL FK → hst_blocks | Parent block |
| room_number | VARCHAR(20) | NOT NULL | Room number (e.g., "101", "A-12") |
| floor_no | TINYINT | NOT NULL | Floor number |
| room_type | ENUM('single','double','triple','dormitory') | NOT NULL | Room type |
| capacity | TINYINT | NOT NULL | Total beds in room |
| current_occupancy | TINYINT | DEFAULT 0 | Occupied beds (computed from active allotments) |
| amenities_json | JSON | NULL | Array of amenities (AC, attached bath, etc.) |
| status | ENUM('available','full','maintenance') | DEFAULT 'available' | Room availability status |
| priority_flags_json | JSON | NULL | Priority rules (medical, senior, merit) |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (block_id, room_number)`

### 6.4 hst_beds 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| room_id | BIGINT UNSIGNED | NOT NULL FK → hst_rooms | Parent room |
| bed_number | VARCHAR(10) | NOT NULL | Bed identifier (e.g., "A", "B", "Bed 1") |
| status | ENUM('available','occupied','maintenance') | DEFAULT 'available' | Current bed status |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (room_id, bed_number)`

### 6.5 hst_allotments 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student being allotted |
| bed_id | BIGINT UNSIGNED | NOT NULL FK → hst_beds | Bed assigned |
| allotment_date | DATE | NOT NULL | Date of allotment |
| vacating_date | DATE | NULL | Date of vacating (NULL = currently occupied) |
| academic_session_id | BIGINT UNSIGNED | NOT NULL FK → sch_academic_sessions | Academic year scoping |
| status | ENUM('active','vacated','transferred') | DEFAULT 'active' | Allotment lifecycle |
| remarks | VARCHAR(500) | NULL | Notes |
| + standard audit columns | | | |

**Note:** Application must enforce only one `status = 'active'` record per `bed_id` at any time.

### 6.6 hst_room_change_requests 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Requesting student |
| from_allotment_id | BIGINT UNSIGNED | NOT NULL FK → hst_allotments | Current allotment |
| requested_room_id | BIGINT UNSIGNED | NULL FK → hst_rooms | Preferred target room (optional) |
| reason | TEXT | NOT NULL | Reason for change |
| status | ENUM('pending','approved','rejected') | DEFAULT 'pending' | Request status |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Warden who approved |
| approved_at | TIMESTAMP | NULL | Approval timestamp |
| rejection_reason | TEXT | NULL | Rejection notes |
| new_allotment_id | BIGINT UNSIGNED | NULL FK → hst_allotments | New allotment created on approval |
| + standard audit columns | | | |

### 6.7 hst_attendance 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel for this session |
| attendance_date | DATE | NOT NULL | Date of attendance |
| shift | ENUM('morning','evening','night') | NOT NULL | Shift / roll call time |
| marked_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Warden who marked |
| remarks | VARCHAR(500) | NULL | Session-level notes |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, attendance_date, shift)` — prevents duplicate sessions

### 6.8 hst_attendance_entries 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| attendance_id | BIGINT UNSIGNED | NOT NULL FK → hst_attendance (CASCADE DELETE) | Parent session |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| status | ENUM('present','absent','leave','home','late') | NOT NULL | Attendance status |
| late_remarks | VARCHAR(255) | NULL | Remarks for late entry |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (attendance_id, student_id)`

### 6.9 hst_movement_log 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| movement_date | DATE | NOT NULL | Date of movement |
| out_time | TIME | NOT NULL | Departure time |
| in_time | TIME | NULL | Actual return time (NULL = not yet returned) |
| expected_return_time | TIME | NULL | Expected return time |
| destination | VARCHAR(255) | NOT NULL | Destination / reason |
| purpose | VARCHAR(500) | NULL | Additional purpose details |
| gate_pass_issued_by | BIGINT UNSIGNED | NULL FK → sys_users | Warden who issued pass |
| + standard audit columns | | | |

### 6.10 hst_leave_passes 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| allotment_id | BIGINT UNSIGNED | NOT NULL FK → hst_allotments | Current allotment (for hostel context) |
| from_date | DATE | NOT NULL | Leave start date |
| to_date | DATE | NOT NULL | Leave end date |
| destination | VARCHAR(255) | NOT NULL | Leave destination |
| purpose | VARCHAR(500) | NOT NULL | Purpose of leave |
| guardian_contact | VARCHAR(20) | NULL | Guardian phone during leave |
| applied_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Staff who submitted application |
| approved_by | BIGINT UNSIGNED | NULL FK → sys_users | Warden who approved |
| approved_at | TIMESTAMP | NULL | Approval timestamp |
| status | ENUM('pending','approved','rejected','returned','cancelled') | DEFAULT 'pending' | Leave pass status |
| rejection_reason | TEXT | NULL | Rejection explanation |
| actual_return_date | DATE | NULL | Actual return date |
| + standard audit columns | | | |

### 6.11 hst_incidents 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student involved |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel where incident occurred |
| incident_date | DATE | NOT NULL | Date of incident |
| incident_time | TIME | NULL | Time of incident |
| incident_type | VARCHAR(100) | NOT NULL | Type (late arrival, rule violation, property damage, misconduct, other) |
| description | TEXT | NOT NULL | Detailed description |
| severity | ENUM('minor','moderate','serious') | NOT NULL | Severity classification |
| action_taken | TEXT | NULL | Action taken (warning, suspension, etc.) |
| reported_by | BIGINT UNSIGNED | NOT NULL FK → sys_users | Warden who reported |
| is_escalated | TINYINT(1) | DEFAULT 0 | Escalated to Principal |
| escalated_at | TIMESTAMP | NULL | Escalation timestamp |
| warning_letter_sent | TINYINT(1) | DEFAULT 0 | Warning letter generated and sent |
| parent_notified | TINYINT(1) | DEFAULT 0 | Parent notification sent |
| + standard audit columns | | | |

### 6.12 hst_incident_media 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| incident_id | BIGINT UNSIGNED | NOT NULL FK → hst_incidents (CASCADE DELETE) | Parent incident |
| media_id | BIGINT UNSIGNED | NOT NULL FK → sys_media | Attached file |
| media_type | VARCHAR(50) | NULL | Description (photo, document, witness statement) |
| + standard audit columns | | | |

### 6.13 hst_mess_weekly_menus 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| academic_session_id | BIGINT UNSIGNED | NOT NULL FK → sch_academic_sessions | Academic year |
| week_start_date | DATE | NOT NULL | Monday of the week |
| day_of_week | TINYINT | NOT NULL | 1=Mon to 7=Sun |
| meal_type | ENUM('breakfast','lunch','dinner','snacks') | NOT NULL | Meal time |
| menu_description | TEXT | NULL | What is being served |
| is_special_diet_available | TINYINT(1) | DEFAULT 0 | Special diet option available this meal |
| special_diet_description | VARCHAR(500) | NULL | Description of special diet offered |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, week_start_date, day_of_week, meal_type)`

### 6.14 hst_mess_attendance 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NOT NULL FK → hst_hostels | Hostel |
| attendance_date | DATE | NOT NULL | Date |
| meal_type | ENUM('breakfast','lunch','dinner','snacks') | NOT NULL | Meal |
| student_id | BIGINT UNSIGNED | NOT NULL FK → std_students | Student |
| status | ENUM('present','absent','on_leave','opted_out') | NOT NULL | Meal attendance |
| is_special_diet_served | TINYINT(1) | DEFAULT 0 | Special diet was served |
| special_diet_served_description | VARCHAR(255) | NULL | Details of special diet served |
| marked_by | BIGINT UNSIGNED | NULL FK → sys_users | Mess supervisor |
| + standard audit columns | | | |

**Unique Constraint:** `UNIQUE (hostel_id, attendance_date, meal_type, student_id)`

### 6.15 hst_room_inventory 📐

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK | Primary key |
| room_id | BIGINT UNSIGNED | NOT NULL FK → hst_rooms | Room |
| item_name | VARCHAR(150) | NOT NULL | Item name (Bed, Mattress, Study Table, Chair, Cupboard) |
| quantity | TINYINT | DEFAULT 1 | Number of such items in room |
| condition | ENUM('good','fair','poor','under_repair','disposed') | DEFAULT 'good' | Current condition |
| last_inspected_at | DATE | NULL | Date of last physical inspection |
| damage_description | TEXT | NULL | Description if damaged |
| estimated_repair_cost | DECIMAL(10,2) | NULL | Repair/replacement cost estimate |
| repair_status | ENUM('none','pending','under_repair','repaired','written_off') | DEFAULT 'none' | Repair workflow |
| responsible_student_id | BIGINT UNSIGNED | NULL FK → std_students | Student found responsible for damage |
| + standard audit columns | | | |

### 6.16 Cross-Module FK Dependencies

| FK Column | References | Module Owner |
|---|---|---|
| `std_students.id` | All student_id columns across all tables | StudentProfile |
| `sch_academic_sessions.id` | `hst_allotments.academic_session_id`, `hst_mess_weekly_menus.academic_session_id` | SchoolSetup |
| `sys_users.id` | All warden, approved_by, marked_by, created_by columns | System |
| `sys_media.id` | `hst_incident_media.media_id` | System |

---

## 7. API and Routes

All routes registered in `routes/tenant.php` under the `hostel/` prefix with `auth` + tenant middleware.

### 7.1 Infrastructure Setup Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/hostels` | GET/POST | HostelController | index, store |
| `hostel/hostels/{id}` | GET/PUT/DELETE | HostelController | show, update, destroy |
| `hostel/hostels/{id}/toggle-status` | POST | HostelController | toggleStatus |
| `hostel/blocks` | GET/POST | BlockController | index, store |
| `hostel/blocks/{id}` | GET/PUT/DELETE | BlockController | show, update, destroy |
| `hostel/rooms` | GET/POST | RoomController | index, store |
| `hostel/rooms/{id}` | GET/PUT/DELETE | RoomController | show, update, destroy |
| `hostel/rooms/{id}/toggle-status` | POST | RoomController | toggleStatus |
| `hostel/beds` | GET/POST | BedController | index, store |
| `hostel/beds/{id}` | GET/PUT/DELETE | BedController | show, update, destroy |

### 7.2 Allotment Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/allotments` | GET/POST | AllotmentController | index, store |
| `hostel/allotments/{id}` | GET/PUT | AllotmentController | show, update |
| `hostel/allotments/{id}/vacate` | POST | AllotmentController | vacate |
| `hostel/allotments/{id}/transfer` | POST | AllotmentController | transfer |
| `hostel/allotments/bulk-vacate` | POST | AllotmentController | bulkVacate |
| `hostel/room-change-requests` | GET/POST | RoomChangeRequestController | index, store |
| `hostel/room-change-requests/{id}` | GET | RoomChangeRequestController | show |
| `hostel/room-change-requests/{id}/approve` | POST | RoomChangeRequestController | approve |
| `hostel/room-change-requests/{id}/reject` | POST | RoomChangeRequestController | reject |

### 7.3 Attendance Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/attendance` | GET/POST | HstAttendanceController | index, store |
| `hostel/attendance/{id}` | GET/PUT | HstAttendanceController | show, update |
| `hostel/attendance/{id}/entries` | GET/POST | HstAttendanceController | entries, storeEntries |
| `hostel/movement-log` | GET/POST | MovementLogController | index, store |
| `hostel/movement-log/{id}/return` | POST | MovementLogController | recordReturn |
| `hostel/movement-log/pending` | GET | MovementLogController | pendingReturns |

### 7.4 Leave Pass Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/leave-passes` | GET/POST | LeavePassController | index, store |
| `hostel/leave-passes/{id}` | GET/PUT | LeavePassController | show, update |
| `hostel/leave-passes/{id}/approve` | POST | LeavePassController | approve |
| `hostel/leave-passes/{id}/reject` | POST | LeavePassController | reject |
| `hostel/leave-passes/{id}/return` | POST | LeavePassController | markReturned |
| `hostel/leave-passes/{id}/cancel` | POST | LeavePassController | cancel |
| `hostel/leave-passes/{id}/print` | GET | LeavePassController | print |

### 7.5 Discipline Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/incidents` | GET/POST | IncidentController | index, store |
| `hostel/incidents/{id}` | GET/PUT | IncidentController | show, update |
| `hostel/incidents/{id}/escalate` | POST | IncidentController | escalate |
| `hostel/incidents/{id}/warning-letter` | GET | IncidentController | printWarningLetter |
| `hostel/incidents/{id}/notify-parent` | POST | IncidentController | notifyParent |
| `hostel/incidents/{id}/media` | POST/DELETE | IncidentController | storeMedia, destroyMedia |

### 7.6 Mess Management Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/mess/weekly-menus` | GET/POST | MessMenuController | index, store |
| `hostel/mess/weekly-menus/{id}` | GET/PUT/DELETE | MessMenuController | show, update, destroy |
| `hostel/mess/attendance` | GET/POST | MessAttendanceController | index, store |
| `hostel/mess/attendance/bulk` | POST | MessAttendanceController | bulkStore |
| `hostel/mess/attendance/report` | GET | MessAttendanceController | monthlyReport |

### 7.7 Reports and Dashboard Routes 📐

| Route Pattern | Method | Controller | Action |
|---|---|---|---|
| `hostel/dashboard` | GET | HstDashboardController | index |
| `hostel/reports/occupancy` | GET | HstReportController | occupancy |
| `hostel/reports/attendance` | GET | HstReportController | attendance |
| `hostel/reports/leave-register` | GET | HstReportController | leaveRegister |
| `hostel/reports/fee-defaulters` | GET | HstReportController | feeDefaulters |
| `hostel/reports/incidents` | GET | HstReportController | incidents |
| `hostel/reports/mess-attendance` | GET | HstReportController | messAttendance |
| `hostel/reports/room-inventory` | GET | HstReportController | roomInventory |
| `hostel/reports/{type}/export` | GET | HstReportController | export |

---

## 8. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-HST-001 | A bed can have only one active allotment at a time — application-level check enforced before creating allotment |
| BR-HST-002 | Gender restriction: boys cannot be allotted to girls' hostels and vice versa |
| BR-HST-003 | Leave pass `to_date` must be >= `from_date` |
| BR-HST-004 | Leave pass auto-marks student attendance as 'leave' for all shifts during the leave period |
| BR-HST-005 | Meal attendance for leave period is auto-marked 'on_leave' when leave pass is approved |
| BR-HST-006 | Attendance session is unique per (hostel, date, shift) — duplicate session creation blocked |
| BR-HST-007 | Room change on approval: old allotment status → 'transferred'; new allotment created with status 'active' |
| BR-HST-008 | Moderate and Serious incidents must auto-send parent notification |
| BR-HST-009 | Hostel deactivation is blocked if there are active allotments in that hostel |
| BR-HST-010 | Room status auto-updates: 'full' when current_occupancy >= capacity; 'available' when occupancy < capacity |
| BR-HST-011 | Prorated fee = (Monthly Rate / 30) × Number of Remaining Days in Month at time of allotment |
| BR-HST-012 | Late return (actual_return_date > to_date on leave pass) triggers an automatic incident record of type 'late arrival' |
| BR-HST-013 | Warden can only manage allotments, attendance, and leave passes for hostels/blocks they are assigned to |
| BR-HST-014 | No `tenant_id` column — data isolation at database level per tenant |
| BR-HST-015 | Academic year reset: bulk-vacate action must require explicit confirmation; irreversible operation |

---

## 9. Authorization and RBAC

### 9.1 Permission Strings

```
hostel.hostel.viewAny
hostel.hostel.create
hostel.hostel.update
hostel.hostel.delete
hostel.block.viewAny
hostel.block.create
hostel.block.update
hostel.room.viewAny
hostel.room.create
hostel.room.update
hostel.bed.viewAny
hostel.bed.create
hostel.allotment.viewAny
hostel.allotment.create
hostel.allotment.transfer
hostel.allotment.vacate
hostel.leave-pass.viewAny
hostel.leave-pass.create
hostel.leave-pass.approve
hostel.attendance.viewAny
hostel.attendance.create
hostel.attendance.update
hostel.incident.viewAny
hostel.incident.create
hostel.incident.escalate
hostel.mess.menu.manage
hostel.mess.attendance.mark
hostel.room-inventory.manage
hostel.report.view
```

### 9.2 Role-Permission Matrix

| Permission Area | School Admin | Chief Warden | Block Warden | Mess Supervisor | Accountant |
|---|---|---|---|---|---|
| Hostel / Block / Room / Bed Setup | Full | View | View | View | View |
| Student Allotment | Full | Full | Own Block | View | View |
| Leave Pass | Full | Full (approve) | Own Block (approve) | View | View |
| Attendance | Full | Full | Own Block | View | View |
| Mess Menu & Attendance | Full | Full | View | Full | View |
| Incidents | Full | Full | Own Block | View | View |
| Room Inventory | Full | Full | Own Block | View | View |
| Reports | Full | Full | Own Block | Mess only | Fee/Defaulter |

---

## 10. Service Layer Architecture

### 10.1 Proposed Services 📐

| Service | Responsibility |
|---|---|
| 📐 `AllotmentService` | Create allotment, validate bed availability, enforce gender restriction, update bed status, handle transfer and bulk-vacate |
| 📐 `LeavePassService` | Leave pass approval workflow, auto-mark attendance as 'on leave', auto-mark mess attendance as 'on_leave', send parent notification, handle return confirmation and late-return incident creation |
| 📐 `HostelAttendanceService` | Create attendance session, bulk-mark entries, validate uniqueness, handle late-entry rules, generate attendance summaries |
| 📐 `IncidentService` | Record incident, trigger parent notification for moderate/serious, escalate to principal, generate warning letter PDF via DomPDF |
| 📐 `HostelFeeService` | Calculate hostel fee on allotment (room rate + mess rate), calculate prorated fee for mid-month allotment or room change, push fee demand to StudentFee module |

### 10.2 Proposed Controllers 📐

| Controller | Screens Managed |
|---|---|
| 📐 `HstDashboardController` | Dashboard — occupancy stats, today's attendance summary, pending leave passes, open incidents, pending returns |
| 📐 `HostelController` | Hostel CRUD + facility management |
| 📐 `BlockController` | Block CRUD + floor management |
| 📐 `RoomController` | Room CRUD + status management |
| 📐 `BedController` | Bed CRUD + maintenance flag |
| 📐 `AllotmentController` | Allotment CRUD + vacate + transfer + bulk-vacate |
| 📐 `RoomChangeRequestController` | Room change request + approval/rejection workflow |
| 📐 `HstAttendanceController` | Attendance session + per-student entry marking |
| 📐 `MovementLogController` | In-out movement register + pending returns dashboard |
| 📐 `LeavePassController` | Leave pass CRUD + approval + return + print |
| 📐 `IncidentController` | Incident CRUD + escalate + warning letter print + parent notify |
| 📐 `MessMenuController` | Weekly menu setup |
| 📐 `MessAttendanceController` | Meal attendance marking + monthly report |
| 📐 `HstReportController` | All reports + export |

### 10.3 Proposed FormRequests 📐

`StoreHostelRequest`, `StoreBlockRequest`, `StoreRoomRequest`, `StoreBedRequest`, `StoreAllotmentRequest`, `StoreRoomChangeRequest`, `StoreLeavePassRequest`, `StoreHstAttendanceRequest`, `StoreMovementLogRequest`, `StoreIncidentRequest`, `StoreMessMenuRequest`, `StoreMessAttendanceRequest`, `StoreRoomInventoryRequest`, `ApproveLeavePassRequest`

---

## 11. Integration Points

| Direction | Source Event | Target | Mechanism |
|---|---|---|---|
| 📐 Allotment → StudentFee | Bed allotted | Hostel fee demand added to student fee | `HostelFeeService` → StudentFee module fee demand creation |
| 📐 Leave Pass Approved → Notification | Leave pass approved | Parent/guardian notification (SMS/Push) with leave details | `event(new LeavePassApproved($leavePass))` → Notification module |
| 📐 Leave Pass → Attendance | Leave pass approved | Attendance auto-marked as 'leave' for all shifts in date range | `LeavePassService::markAttendanceForLeave()` |
| 📐 Leave Pass → Mess | Leave pass approved | Mess attendance auto-marked 'on_leave' for date range | `LeavePassService::markMessAttendanceForLeave()` |
| 📐 Incident (Moderate/Serious) → Notification | Incident recorded | Parent notification dispatched | `event(new HostelIncidentRecorded($incident))` → Notification module |
| 📐 Late Return → Incident | Actual return > to_date | Auto-create incident of type 'late arrival' | `LeavePassService::markReturned()` checks late return |
| 📐 Hostel → StudentProfile | Allotment | References `std_students` for student data | FK reference |
| 📐 Hostel → SchoolSetup | Academic session scope | References `sch_academic_sessions` | FK reference |
| 📐 Hostel → SystemMedia | Incident attachments | Uses `sys_media` for file storage | FK reference via `hst_incident_media` |

---

## 12. Test Coverage

### 12.1 Proposed Feature Tests 📐

| Test Class | Test Scenarios |
|---|---|
| 📐 `HostelInfrastructureTest` | Create hostel, create block, create room, create beds, gender restriction on setup |
| 📐 `AllotmentTest` | Allot student to bed, prevent double-allotment, gender validation, vacate bed, transfer student, bulk vacate |
| 📐 `LeavePassTest` | Apply leave pass, approve pass, reject pass, attendance auto-marked, mess auto-marked, mark returned, late return creates incident |
| 📐 `HstAttendanceTest` | Create session, mark attendance, prevent duplicate session, bulk mark present then update exceptions |
| 📐 `IncidentTest` | Record minor incident, record serious incident (parent notification triggered), escalate to principal, generate warning letter |
| 📐 `RoomChangeRequestTest` | Submit request, approve executes transfer, reject returns reason |
| 📐 `MessMenuTest` | Create weekly menu, duplicate prevention, special diet assignment |

### 12.2 Proposed Unit Tests 📐

| Test Class | Scenarios |
|---|---|
| 📐 `AllotmentServiceTest` | Bed availability check, gender validation logic |
| 📐 `LeavePassServiceTest` | Attendance date range calculation, late return detection |
| 📐 `HostelFeeServiceTest` | Prorated fee calculation for mid-month allotment |

---

## 13. Implementation Status

| Component | Status |
|---|---|
| Module Directory Structure | ❌ Not Started |
| Database Migrations (15 tables) | ❌ Not Started |
| Eloquent Models (15) | ❌ Not Started |
| Controllers (14) | ❌ Not Started |
| Services (5) | ❌ Not Started |
| FormRequests (14) | ❌ Not Started |
| Blade Views (~55) | ❌ Not Started |
| Seeders (1) | ❌ Not Started |
| Routes (tenant.php) | ❌ Not Started |
| Policies (10) | ❌ Not Started |
| Feature Tests | ❌ Not Started |
| Unit Tests | ❌ Not Started |
| Leave Pass PDF Print | ❌ Not Started |
| Warning Letter PDF (DomPDF) | ❌ Not Started |
| Parent Notification Events | ❌ Not Started |
| StudentFee Integration | ❌ Not Started |

---

## 14. Known Issues and Technical Debt

### 14.1 Pre-Development Clarifications Required

1. **Academic Session Reference**: The FK `sch_academic_sessions.id` must be confirmed against the actual table name in the tenant DDL — some versions use `sch_academic_terms` or `sch_sessions`. Verify before writing migrations.
2. **Student FK Table**: Confirm exact table name: `std_students` per stated DDL conventions. Use this exclusively — do not reference `students` or `sch_students`.
3. **StudentFee Integration**: The mechanism for pushing hostel fee to StudentFee module (service interface, event, or direct DB call) must be decided in coordination with the StudentFee module developer.
4. **Mess Module Overlap**: The Mess Management module (`mes_*`, directory `67-MessManagement_`) may overlap with hostel mess functionality. Clarify whether hostel mess is managed entirely within HST module or delegates to `mes_*` module. This document treats mess as HST-internal.
5. **Bed Double-Allotment Prevention**: The DB does not enforce a unique constraint on active allotments per bed (application-level only) because `status` is part of the uniqueness condition. Consider adding a partial unique index or `CHECK` constraint in MySQL 8.x.

### 14.2 Design Gaps to Resolve

- **Visitor Management in Hostel Context**: Hostel visitors (parents visiting students on visiting day) could be tracked here, but Frontdesk module is mentioned in scope boundaries. This overlap needs resolution.
- **Medical Room / Sick Bay**: No table for tracking students admitted to hostel sick bay; this may need a simple admission/discharge log in future.
- **Fee Component Table**: No dedicated `hst_fee_structures` table is designed here. If complex fee structure per room type and session is needed, a separate fee setup table should be added.
- **Room Inventory Link to Accounting**: Damage cost recovery linking to student fee module is mentioned but the exact service interface is not designed.

---

## 15. Development Priorities and Recommendations

### 15.1 Development Sequence

Build in this order to respect FK dependencies:

1. **Phase 1 — Infrastructure** (self-contained): `hst_hostels`, `hst_blocks`, `hst_rooms`, `hst_beds` + controllers, seeders
2. **Phase 2 — Allotment** (requires std_students, sch_academic_sessions): `hst_allotments`, `hst_room_change_requests` + AllotmentService
3. **Phase 3 — Attendance & Movement**: `hst_attendance`, `hst_attendance_entries`, `hst_movement_log` + HostelAttendanceService
4. **Phase 4 — Leave Pass** (requires Phase 2 + 3): `hst_leave_passes` + LeavePassService + notification events
5. **Phase 5 — Discipline**: `hst_incidents`, `hst_incident_media` + IncidentService + DomPDF warning letter
6. **Phase 6 — Mess**: `hst_mess_weekly_menus`, `hst_mess_attendance` + MessMenuController
7. **Phase 7 — Room Inventory**: `hst_room_inventory` + damage workflow
8. **Phase 8 — Fee Integration & Reports**: HostelFeeService + HstReportController + dashboard analytics

### 15.2 Key Recommendations

- **Merge Mess with Hostel**: Keep mess management tables in `hst_*` prefix; the separate `mes_*` module (`67-MessManagement_`) should be reviewed for overlap before development begins
- **Implement Scoped Warden Access**: Block Wardens should see only their own block's data — implement a `HostelScope` or middleware-based filter early in development to avoid retrofitting
- **Attendance Caching**: Hostel attendance for 500+ students should compute summary stats (present count, absent count, on-leave count) at save time and store in the `hst_attendance` session record to avoid expensive aggregation queries on every report load
- **Academic Year Reset Wizard**: Bulk-vacate + bulk-allot wizard is a high-priority feature for school start of year — build early and with a clear confirmation + audit log
- **Leave Pass Calendar View**: A calendar showing who is on leave on any given day is a high-value UI feature for wardens; plan for it in views
- **RBS Source**: Module O — 36 sub-tasks fully mapped to FRs in this document

---

*Document Version 1.0 | Generated 2026-03-25 | RBS_ONLY Mode | All features ❌ Not Started*
