# VisitorSecurity Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Greenfield RBS-Only)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** VSM | **Module Path:** `Modules/VisitorSecurity`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `vsm_*` | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module X — Visitor & Security Management (lines 4313–4346)

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

The VisitorSecurity module provides comprehensive gate security and visitor management for Indian K-12 schools on the Prime-AI platform. It digitises the full visitor lifecycle: pre-registration, walk-in registration with photo and ID capture, QR code gate pass generation, check-in/check-out logging, real-time campus occupancy monitoring, guard shift management, security patrol rounds, emergency broadcast alerts, and visitor blacklist management.

### 1.2 Scope

This module covers:
- Visitor pre-registration (host initiates; visitor receives QR code via SMS/email)
- Walk-in visitor registration at reception/gate kiosk (photo capture, ID proof scan)
- QR code scanning at gate: check-in with live photo capture and badge printing
- Check-out: scan on exit, flag overdue visitors (exceeded expected duration)
- Real-time campus dashboard: live visitor count, check-in list, restricted zone alerts
- Guard shift management: shift scheduling, check-in/check-out for guards
- Security patrol rounds: define checkpoints, log patrols with timestamp and location
- Blacklist management: flag visitors to block entry and alert security
- Emergency alert broadcast: lockdown/evacuation alerts to all staff via Notification module
- Automated headcount/roll call trigger during emergency
- Reports: visitor logs, frequency analysis, guard attendance

Out of scope for this version: CCTV DVR/NVR integration (hardware), biometric integration, automated face recognition.

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.X*) | 3 (F.X1.1, F.X2.1, F.X3.1, F.X3.2) |
| RBS Tasks | 5 |
| RBS Sub-tasks | 10 (ST.X1.1.1.1–ST.X3.2.1.2) |
| Proposed DB Tables (vsm_*) | 9 |
| Proposed Named Routes | ~55 |
| Proposed Blade Views | ~25 |
| Proposed Controllers | 7 |
| Proposed Models | 9 |
| Proposed Services | 3 |
| Proposed FormRequests | 7 |
| Proposed Policies | 7 |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 9 tables to be created |
| Models | ❌ Not Started | 9 models |
| Controllers | ❌ Not Started | 7 controllers |
| Services | ❌ Not Started | VisitorService, SecurityAlertService, PatrolService |
| Views | ❌ Not Started | ~25 blade views |
| Routes | ❌ Not Started | ~55 named routes |
| Tests | ❌ Not Started | Feature + Unit tests |

**Overall Implementation: 0%** (Greenfield)

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools have stringent security concerns: unauthorised adult entry, student safety during school hours, unknown visitor access to classrooms, child pickup by unauthorised persons, and emergency evacuation coordination. Manual visitor registers at the gate are error-prone, lose records, and provide no real-time visibility.

The VisitorSecurity module solves:
1. **Verified entry** — every visitor is registered with photo, ID proof, and declared purpose; a time-limited QR gate pass is issued
2. **Host notification** — teacher/staff receiving the visitor gets notified immediately on visitor arrival
3. **Real-time monitoring** — security office sees live count and list of all visitors currently on campus
4. **Overdue alerts** — visitors who have not checked out beyond expected duration are flagged automatically
5. **Blacklist enforcement** — known unwanted persons are flagged on entry attempt
6. **Guard accountability** — shift management and patrol round logging creates audit trail
7. **Emergency response** — one-click emergency broadcast to all staff; automated headcount initiation

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Visitor Pre-Registration | Host pre-registers visitor; QR sent via SMS/email | F.X1.1, T.X1.1.1, ST.X1.1.1.1 | 📐 Proposed |
| Walk-in Registration | Reception/kiosk: capture visitor details, photo, ID | T.X1.1.2, ST.X1.1.2.1–2 | 📐 Proposed |
| QR Gate Pass | Auto-generate QR code pass for pre-reg and walk-in | ST.X1.1.1.2 | 📐 Proposed |
| Check-in at Gate | Security scans QR, records check-in time, live photo, badge | ST.X2.1.1.1–2 | 📐 Proposed |
| Check-out at Gate | Scan on exit, record check-out, flag overdue | ST.X2.1.2.1–2 | 📐 Proposed |
| Real-time Campus Dashboard | Live visitor count, current check-ins, restricted zones | ST.X3.1.1.1–2 | 📐 Proposed |
| Emergency Alert Broadcast | Lockdown/evacuation SMS/app alert to all staff | ST.X3.2.1.1 | 📐 Proposed |
| Automated Headcount | Roll call / headcount initiated via system | ST.X3.2.1.2 | 📐 Proposed |
| Guard Shift Management | Shift scheduling, guard clock-in/clock-out | Beyond RBS | 📐 Proposed |
| Patrol Rounds | Checkpoint-based patrol logging | Beyond RBS | 📐 Proposed |
| Blacklist Management | Flag visitors for blocked entry | Beyond RBS | 📐 Proposed |
| Visitor Reports | Daily log, frequency, overdue incidents, guard attendance | Beyond RBS | 📐 Proposed |

### 2.3 Menu Navigation Path

```
School Admin Panel
└── Visitor & Security [/visitor-security]
    ├── Dashboard              [/visitor-security/dashboard]
    ├── Visitor Management
    │   ├── Register Visitor   [/visitor-security/visitors/create]
    │   ├── All Visitors       [/visitor-security/visitors]
    │   └── Blacklist          [/visitor-security/blacklist]
    ├── Gate Activity
    │   ├── Check-in           [/visitor-security/gate/checkin]
    │   └── Today's Log        [/visitor-security/visits]
    ├── Guard Management
    │   ├── Guard Shifts       [/visitor-security/guard-shifts]
    │   └── Patrol Rounds      [/visitor-security/patrol-rounds]
    ├── Emergency
    │   └── Emergency Protocols [/visitor-security/emergency-protocols]
    └── Reports
        ├── Visitor Log Report  [/visitor-security/reports/visitor-log]
        └── Guard Attendance    [/visitor-security/reports/guard-attendance]
```

### 2.4 Module Architecture

```
Modules/VisitorSecurity/
├── app/
│   ├── Http/Controllers/
│   │   ├── VisitorSecurityController.php     # Dashboard + module root
│   │   ├── VisitorController.php             # Visitor registration CRUD
│   │   ├── VisitController.php               # Visit lifecycle: checkin/checkout
│   │   ├── GatePassController.php            # QR gate pass generation
│   │   ├── GuardShiftController.php          # Guard shift management
│   │   ├── PatrolController.php              # Patrol rounds management
│   │   └── EmergencyController.php           # Emergency alerts + headcount
│   ├── Models/
│   │   ├── Visitor.php
│   │   ├── Visit.php
│   │   ├── GatePass.php
│   │   ├── GuardShift.php
│   │   ├── PatrolRound.php
│   │   ├── PatrolCheckpoint.php
│   │   ├── EmergencyProtocol.php
│   │   ├── EmergencyEvent.php
│   │   └── Blacklist.php
│   ├── Services/
│   │   ├── VisitorService.php                # Registration, QR gen, check-in/out logic
│   │   ├── SecurityAlertService.php          # Emergency broadcast, overdue flagging
│   │   └── PatrolService.php                 # Patrol scheduling, checkpoint logging
│   ├── Policies/ (7 policies)
│   └── Providers/
├── database/migrations/ (9 migrations)
├── resources/views/visitor-security/
│   ├── dashboard.blade.php
│   ├── visitors/    (create, edit, index, show, pre-register)
│   ├── visits/      (index, show, checkin, checkout, today)
│   ├── gate-passes/ (show, scan-qr)
│   ├── guard-shifts/(create, edit, index, show)
│   ├── patrol-rounds/ (create, index, show)
│   ├── emergency/   (protocols/create/index, broadcast)
│   ├── blacklist/   (create, edit, index)
│   └── reports/     (visitor-log, guard-attendance)
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. Stakeholders & Actors

| Actor | Role in VisitorSecurity Module | Permissions |
|---|---|---|
| School Admin | Full access: configuration, reports, emergency management | All permissions |
| Principal | View all visits, initiate emergency, approve pre-registrations | view all, emergency, approve |
| Reception Staff | Register visitors, process check-ins, issue gate passes | register, checkin/checkout |
| Security Guard | Scan QR at gate, log patrol rounds, update shift attendance | gate scan, patrol, shift log |
| Teacher/Staff | Pre-register expected visitors (e.g., parent for PTM) | pre-register own visitors |
| System | Auto-flag overdue visitors, generate reorder alerts, send notifications | system actor |
| Visitor | Receives QR gate pass via SMS/email (external party) | — |

---

## 4. Functional Requirements

---

### FR-VSM-001: Visitor Pre-Registration (F.X1.1 — T.X1.1.1)

**RBS Reference:** T.X1.1.1 — Visitor Pre-Registration
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `vsm_visitors`, `vsm_visits`, `vsm_gate_passes`

#### Requirements

**REQ-VSM-001.1: Host Pre-Registers Visitor (ST.X1.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | A staff member (teacher/admin) pre-registers an expected visitor with their details |
| Actors | School Admin, Teacher/Staff |
| Preconditions | Authenticated with `tenant.vsm-visitor.pre-register` permission |
| Input | visitor_name (required), visitor_mobile (required, validated), id_type (ENUM: Aadhar/DrivingLicense/Passport/VoterID/Other), id_number (optional), purpose (ENUM: PTM/Admission/Meeting/Delivery/Maintenance/Other + custom text), host_staff_id (FK sys_users), expected_date (required, future), expected_time, vehicle_number (optional), company_name (optional) |
| Processing | 1) Check blacklist — block if visitor mobile/name matches blacklist entry; 2) Create or find `vsm_visitors` record (match by mobile_no); 3) Create `vsm_visits` record with status=Pre-Registered; 4) Generate QR gate pass via SimpleSoftwareIO; 5) Save gate pass to `vsm_gate_passes`; 6) Send QR via SMS to visitor_mobile and email if provided |
| Output | Pre-registration confirmation; QR code sent to visitor |
| Status | 📐 Proposed |

**REQ-VSM-001.2: Walk-in Visitor Registration (ST.X1.1.2.1–2)**
| Attribute | Detail |
|---|---|
| Description | Reception staff registers walk-in visitor at front desk or kiosk |
| Actors | Reception Staff |
| Input | All pre-registration fields + photo_capture (webcam/upload via sys_media) + id_proof_scan (image upload via sys_media) |
| Processing | Create `vsm_visitors`; create `vsm_visits` with status=Registered (walk-in); generate gate pass QR; notify host via in-app notification |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.X1.1.1.1 — Host can pre-register visitor with name, phone, purpose, vehicle
- [ ] ST.X1.1.1.2 — QR gate pass sent to visitor via SMS/email
- [ ] ST.X1.1.2.1 — Walk-in visitors registered at reception/kiosk
- [ ] ST.X1.1.2.2 — Visitor photo and ID proof captured

---

### FR-VSM-002: Gate Check-in (F.X2.1 — T.X2.1.1)

**RBS Reference:** T.X2.1.1 — Process Visitor Entry
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `vsm_visits`, `vsm_gate_passes`

#### Requirements

**REQ-VSM-002.1: QR Scan at Gate (ST.X2.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Security guard scans visitor's QR code (pre-reg or walk-in generated) to process gate entry |
| Actors | Security Guard, Reception Staff |
| Preconditions | `tenant.vsm-visit.checkin` permission; device with camera or QR scanner |
| Input | QR code scan (resolves to gate_pass_token) |
| Processing | 1) Decode token → retrieve vsm_gate_passes record; 2) Validate: not expired, status=Issued, visit not already checked-in; 3) Check blacklist by visitor mobile/name — alert if matched; 4) Update `vsm_visits.checkin_time = NOW()`; 5) Update `vsm_visits.status = Checked_In`; 6) Capture live gate photo (optional webcam); 7) Update gate pass status=Used; 8) Notify host: "[Visitor Name] has arrived and checked in." |
| Output | Check-in confirmed; badge print triggered; host notified |
| Status | 📐 Proposed |

**REQ-VSM-002.2: Manual Check-in (Fallback)**
| Attribute | Detail |
|---|---|
| Description | When QR scan fails, guard can manually search visitor by name/mobile and check in |
| Processing | Search vsm_visitors by mobile_no or name; select matching visit; process check-in as above |
| Status | 📐 Proposed |

**REQ-VSM-002.3: Temporary Badge Print (ST.X2.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | System generates a printable temporary visitor badge on check-in |
| Processing | DomPDF renders badge: visitor name, photo, purpose, host name, check-in time, gate pass number, valid until time (expected_duration + check-in time) |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.X2.1.1.1 — Security scans QR code at gate; check-in recorded
- [ ] ST.X2.1.1.2 — Check-in time, live photo, badge printed at gate

---

### FR-VSM-003: Gate Check-out (F.X2.1 — T.X2.1.2)

**RBS Reference:** T.X2.1.2 — Visitor Exit
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `vsm_visits`

#### Requirements

**REQ-VSM-003.1: Check-out on Exit (ST.X2.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | Guard scans badge/QR on visitor exit to record check-out time |
| Actors | Security Guard, Reception Staff |
| Input | QR scan or manual visitor search |
| Processing | Update `vsm_visits.checkout_time = NOW()`; status=Checked_Out; calculate `duration_minutes`; update gate pass status=Closed |
| Output | Check-out confirmed; visit duration recorded |
| Status | 📐 Proposed |

**REQ-VSM-003.2: Overdue Visitor Flagging (ST.X2.1.2.2)**
| Attribute | Detail |
|---|---|
| Description | Visitors still on campus beyond their expected duration are automatically flagged |
| Processing | Scheduled job (every 15 minutes): query visits with status=Checked_In AND checkin_time + expected_duration_minutes < NOW(); update `is_overdue=1`; send alert to security desk in-app notification |
| Output | Overdue visitors appear with red badge on dashboard |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.X2.1.2.1 — Check-out time recorded on badge/QR scan
- [ ] ST.X2.1.2.2 — Overdue visitors flagged automatically

---

### FR-VSM-004: Real-time Campus Dashboard (F.X3.1)

**RBS Reference:** F.X3.1 — Real-time Dashboard; T.X3.1.1 — Monitor Campus Activity
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `vsm_visits` (read aggregation), `vsm_blacklist`

#### Requirements

**REQ-VSM-004.1: Live Visitor Count & List (ST.X3.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Security office screen shows real-time count of visitors currently on campus |
| Actors | School Admin, Principal, Reception Staff, Security Guard |
| Processing | Aggregate vsm_visits WHERE status=Checked_In; show total count prominently; list all checked-in visitors: name, photo, purpose, host, check-in time, expected check-out time |
| Output | Auto-refreshing dashboard (every 60 seconds or SSE push) |
| Status | 📐 Proposed |

**REQ-VSM-004.2: Overdue & Restricted Zone Alerts (ST.X3.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | Dashboard highlights visitors with expired expected duration or flagged in restricted zones |
| Processing | Overdue count badge; list of overdue visitors with elapsed time; restricted zone flag if purpose=Delivery but visitor location logged as academic block |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.X3.1.1.1 — Live count of visitors on campus displayed on dashboard
- [ ] ST.X3.1.1.2 — Overdue and restricted-zone visitors highlighted

---

### FR-VSM-005: Emergency Alert System (F.X3.2)

**RBS Reference:** F.X3.2 — Emergency Alerts; T.X3.2.1 — Broadcast Emergency
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `vsm_emergency_protocols`, `vsm_emergency_events`

#### Requirements

**REQ-VSM-005.1: Broadcast Emergency Alert (ST.X3.2.1.1)**
| Attribute | Detail |
|---|---|
| Description | Admin or Principal triggers an instant emergency broadcast to all active staff |
| Actors | School Admin, Principal |
| Preconditions | `tenant.vsm-emergency.broadcast` permission |
| Input | emergency_type (ENUM: Lockdown/Fire/Earthquake/MedicalEmergency/Evacuation/Other), message (text, max 500), affected_zones (optional text) |
| Processing | 1) Create `vsm_emergency_events` record; 2) Dispatch via Notification module: SMS to all active staff mobile numbers + in-app push to all logged-in staff; 3) Log broadcast timestamp, triggered_by |
| Output | Alert dispatched; log entry created with delivery confirmation count |
| Status | 📐 Proposed |

**REQ-VSM-005.2: Automated Headcount Initiation (ST.X3.2.1.2)**
| Attribute | Detail |
|---|---|
| Description | System initiates a roll call / headcount when emergency is declared |
| Processing | On emergency event creation, query all students with present_today=true from attendance module; generate class-wise headcount list for class teachers; dispatch in-app task to each class teacher: "Report headcount for [Class] [Section]"; track response: teacher marks count as Safe/Missing/Unknown |
| Status | 📐 Proposed |

**REQ-VSM-005.3: Emergency Protocol Management**
| Attribute | Detail |
|---|---|
| Description | Admin configures standard emergency protocols (e.g., fire evacuation procedure) |
| Input | protocol_type, title, description (step-by-step instructions), responsible_roles (JSON array), media_files (SOPs, maps) |
| Processing | CRUD; protocols retrieved on emergency broadcast for reference |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.X3.2.1.1 — Instant SMS/app alert sent to all staff on emergency broadcast
- [ ] ST.X3.2.1.2 — Automated headcount/roll call initiated via system

---

### FR-VSM-006: Guard Shift Management (Beyond RBS)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `vsm_guard_shifts`

#### Requirements

**REQ-VSM-006.1: Guard Shift Scheduling**
| Attribute | Detail |
|---|---|
| Description | Admin schedules security guards to duty shifts |
| Actors | School Admin |
| Input | guard_user_id (FK sys_users — staff with guard role), shift_date, shift_start_time, shift_end_time, post (gate/patrol/block), notes |
| Processing | Create shift; validate no overlapping shift for same guard on same date |
| Status | 📐 Proposed |

**REQ-VSM-006.2: Guard Attendance (Clock-in/Clock-out)**
| Attribute | Detail |
|---|---|
| Description | Guard logs actual shift start and end on their device |
| Processing | Guard checks in to shift → records `actual_start_time`; checks out → records `actual_end_time`; calculate overtime/shortage |
| Status | 📐 Proposed |

---

### FR-VSM-007: Security Patrol Rounds (Beyond RBS)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `vsm_patrol_checkpoints`, `vsm_patrol_rounds`

#### Requirements

**REQ-VSM-007.1: Define Patrol Checkpoints**
| Attribute | Detail |
|---|---|
| Description | Admin defines campus checkpoints for security patrol rounds |
| Input | checkpoint_name, location_description, floor, building, qr_code (generated), sequence_order |
| Processing | Create checkpoint; generate QR code for physical placement at location |
| Status | 📐 Proposed |

**REQ-VSM-007.2: Log Patrol Round**
| Attribute | Detail |
|---|---|
| Description | Guard scans checkpoint QRs during patrol to prove physical presence |
| Input | guard_user_id, patrol_start_time, checkpoint scans (checkpoint_id, scan_time) |
| Processing | Create patrol round record; log each checkpoint scan with timestamp; calculate round completion % (checkpoints scanned / total checkpoints); flag missed checkpoints |
| Status | 📐 Proposed |

---

### FR-VSM-008: Blacklist Management (Beyond RBS)

**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `vsm_blacklist`

#### Requirements

**REQ-VSM-008.1: Add Visitor to Blacklist**
| Attribute | Detail |
|---|---|
| Description | Admin flags a person as blacklisted to block future entry and alert security |
| Actors | School Admin, Principal |
| Input | name (required), mobile_no (optional), id_type + id_number (optional), photo (optional), reason (text required), blacklisted_by, valid_until (optional — permanent by default) |
| Processing | Create blacklist entry; all future registration attempts matching mobile_no or id_number trigger an alert to security |
| Status | 📐 Proposed |

**REQ-VSM-008.2: Blacklist Check on Registration**
| Attribute | Detail |
|---|---|
| Description | On any visitor registration, system checks blacklist by mobile_no and id_number |
| Processing | If match found: block registration; display alert to reception staff with blacklist reason; log blacklist_hit in vsm_visits |
| Status | 📐 Proposed |

---

## 5. Data Model

### 5.1 Proposed Tables

> All tables use standard audit columns: `id`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK→sys_users`, `created_at`, `updated_at`, `deleted_at`.

---

#### 📐 `vsm_visitors`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | Full visitor name |
| mobile_no | VARCHAR(20) | NOT NULL | Primary identifier |
| email | VARCHAR(100) | NULL | |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | NULL | |
| id_number | VARCHAR(50) | NULL | |
| company_name | VARCHAR(150) | NULL | |
| photo_media_id | INT UNSIGNED | NULL FK→sys_media | Visitor photo |
| id_proof_media_id | INT UNSIGNED | NULL FK→sys_media | ID proof scan |
| visit_count | INT UNSIGNED | DEFAULT 0 | Total visits (denormalised) |
| is_blacklisted | TINYINT(1) | DEFAULT 0 | Cache flag from vsm_blacklist |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

INDEX on `(mobile_no)`, `(id_number)`

---

#### 📐 `vsm_visits`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| visit_number | VARCHAR(30) | NOT NULL UNIQUE | Format: VSM-YYYYMMDD-XXXX |
| visitor_id | INT UNSIGNED | NOT NULL FK→vsm_visitors | |
| host_user_id | INT UNSIGNED | NULL FK→sys_users | Staff being visited |
| purpose | ENUM('PTM','Admission','Meeting','Delivery','Maintenance','Interview','Other') | NOT NULL | |
| purpose_detail | VARCHAR(255) | NULL | Custom purpose description |
| expected_date | DATE | NOT NULL | |
| expected_time | TIME | NULL | |
| expected_duration_minutes | SMALLINT UNSIGNED | DEFAULT 60 | Allowed time on campus |
| vehicle_number | VARCHAR(20) | NULL | |
| checkin_time | TIMESTAMP | NULL | |
| checkin_photo_media_id | INT UNSIGNED | NULL FK→sys_media | Live gate photo on checkin |
| checkout_time | TIMESTAMP | NULL | |
| duration_minutes | SMALLINT UNSIGNED | NULL | Calculated on checkout |
| status | ENUM('Pre_Registered','Registered','Checked_In','Checked_Out','No_Show','Cancelled') | DEFAULT 'Registered' | |
| is_overdue | TINYINT(1) | DEFAULT 0 | Flagged by scheduled job |
| blacklist_hit | TINYINT(1) | DEFAULT 0 | Was this visitor on blacklist |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

INDEX on `(expected_date, status)`, `(visitor_id)`, `(host_user_id)`

---

#### 📐 `vsm_gate_passes`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| visit_id | INT UNSIGNED | NOT NULL FK→vsm_visits | |
| visitor_id | INT UNSIGNED | NOT NULL FK→vsm_visitors | |
| pass_token | VARCHAR(100) | NOT NULL UNIQUE | Unique token encoded in QR |
| qr_code_path | VARCHAR(255) | NULL | Stored QR image path |
| status | ENUM('Issued','Used','Expired','Revoked') | DEFAULT 'Issued' | |
| issued_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| expires_at | TIMESTAMP | NOT NULL | issued_at + 24 hours or end of expected_date |
| used_at | TIMESTAMP | NULL | When scanned at gate |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

UNIQUE KEY `uq_vsm_gate_pass_visit` (`visit_id`)

---

#### 📐 `vsm_guard_shifts`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| guard_user_id | INT UNSIGNED | NOT NULL FK→sys_users | Staff assigned as guard |
| shift_date | DATE | NOT NULL | |
| shift_start_time | TIME | NOT NULL | |
| shift_end_time | TIME | NOT NULL | |
| post | VARCHAR(100) | NOT NULL | e.g., Main Gate, Back Gate, Academic Block |
| actual_start_time | TIMESTAMP | NULL | Guard clock-in |
| actual_end_time | TIMESTAMP | NULL | Guard clock-out |
| attendance_status | ENUM('Scheduled','Present','Absent','Late','Early_Departure') | DEFAULT 'Scheduled' | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

UNIQUE KEY `uq_vsm_guard_shift` (`guard_user_id`, `shift_date`, `shift_start_time`)

---

#### 📐 `vsm_patrol_checkpoints`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., Lab Block Entrance |
| location_description | TEXT | NULL | |
| building | VARCHAR(100) | NULL | |
| floor | VARCHAR(20) | NULL | |
| sequence_order | TINYINT UNSIGNED | DEFAULT 0 | Order in patrol route |
| qr_token | VARCHAR(100) | NOT NULL UNIQUE | QR code placed at location |
| qr_code_path | VARCHAR(255) | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `vsm_patrol_rounds`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| guard_user_id | INT UNSIGNED | NOT NULL FK→sys_users | |
| guard_shift_id | INT UNSIGNED | NULL FK→vsm_guard_shifts | |
| patrol_start_time | TIMESTAMP | NOT NULL | |
| patrol_end_time | TIMESTAMP | NULL | |
| checkpoints_total | TINYINT UNSIGNED | DEFAULT 0 | Total defined checkpoints |
| checkpoints_completed | TINYINT UNSIGNED | DEFAULT 0 | Checkpoints scanned |
| completion_pct | DECIMAL(5,2) | DEFAULT 0.00 | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

---

#### 📐 `vsm_patrol_checkpoint_log` (junction: patrol scan log)

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| patrol_round_id | INT UNSIGNED | NOT NULL FK→vsm_patrol_rounds | |
| checkpoint_id | INT UNSIGNED | NOT NULL FK→vsm_patrol_checkpoints | |
| scanned_at | TIMESTAMP | NOT NULL | |
| notes | TEXT | NULL | |
| created_at | TIMESTAMP | | |

---

#### 📐 `vsm_emergency_protocols`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| protocol_type | ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other') | NOT NULL | |
| title | VARCHAR(200) | NOT NULL | |
| description | TEXT | NOT NULL | Step-by-step SOPs |
| responsible_roles_json | JSON | NULL | Array of role slugs |
| media_ids_json | JSON | NULL | Array of sys_media.id (maps, SOPs) |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `vsm_blacklist`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | |
| mobile_no | VARCHAR(20) | NULL | Match key |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | NULL | |
| id_number | VARCHAR(50) | NULL | Match key |
| photo_media_id | INT UNSIGNED | NULL FK→sys_media | |
| reason | TEXT | NOT NULL | Why blacklisted |
| blacklisted_by | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| valid_until | DATE | NULL | NULL = permanent |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

INDEX on `(mobile_no)`, `(id_number)` for fast blacklist check

---

### 5.2 Entity Relationships

```
vsm_visitors ──────── vsm_visits ──────── vsm_gate_passes
                          │
                     host_user_id ──── sys_users (staff)
                          │
                     checkin_photo_media_id ──── sys_media

vsm_guard_shifts ──── sys_users (guard)
        │
vsm_patrol_rounds ──── vsm_patrol_checkpoint_log ──── vsm_patrol_checkpoints

vsm_emergency_protocols  (standalone configuration)

vsm_blacklist  (checked against vsm_visitors on registration)
```

---

## 6. Controller & Route Inventory

| Controller | Route Prefix | Named Prefix | Key Methods |
|---|---|---|---|
| 📐 VisitorSecurityController | /visitor-security | vsm | dashboard, index |
| 📐 VisitorController | /visitor-security/visitors | vsm.visitors | index, create, store, show, edit, update, destroy, preRegister, sendQr |
| 📐 VisitController | /visitor-security/visits | vsm.visits | index, show, today, checkin, processCheckin, checkout, processCheckout |
| 📐 GatePassController | /visitor-security/gate-passes | vsm.gate-passes | show, scan, generate, revoke |
| 📐 GuardShiftController | /visitor-security/guard-shifts | vsm.guard-shifts | CRUD + clockIn, clockOut |
| 📐 PatrolController | /visitor-security/patrol-rounds | vsm.patrol | index, create, store, show, scanCheckpoint, complete |
| 📐 EmergencyController | /visitor-security/emergency | vsm.emergency | index, create, store, broadcast, headcount, protocols CRUD |

**Estimated total named routes:** ~55

---

## 7. Form Request Validation Rules

| FormRequest | Key Rules |
|---|---|
| 📐 StoreVisitorRequest | name required\|max:150; mobile_no required\|digits_between:10,15; id_type nullable\|in:Aadhar,... |
| 📐 PreRegisterVisitRequest | visitor_name required; visitor_mobile required; purpose required\|in:PTM,...; host_staff_id required\|exists:sys_users,id; expected_date required\|date\|after_or_equal:today |
| 📐 ProcessCheckinRequest | pass_token required\|max:100 OR visit_id required\|exists:vsm_visits,id |
| 📐 ProcessCheckoutRequest | visit_id required\|exists:vsm_visits,id\|where status=Checked_In |
| 📐 StoreGuardShiftRequest | guard_user_id required\|exists:sys_users,id; shift_date required\|date; shift_start_time required\|date_format:H:i; shift_end_time required\|date_format:H:i\|after:shift_start_time |
| 📐 BroadcastEmergencyRequest | emergency_type required\|in:Lockdown,Fire,...; message required\|max:500 |
| 📐 StoreBlacklistRequest | name required\|max:150; reason required\|max:1000; mobile_no nullable\|digits_between:10,15 |

---

## 8. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-VSM-001 | Blacklist check is mandatory on every visitor registration (pre-reg and walk-in). Match by mobile_no OR id_number. |
| BR-VSM-002 | Gate pass token is cryptographically unique (UUID v4) and expires at end of expected_date or after 24 hours, whichever is earlier. |
| BR-VSM-003 | A visitor can only have one active (status=Checked_In) visit at a time. Attempting a second check-in for the same visitor on the same day requires supervisor override. |
| BR-VSM-004 | Overdue flagging runs every 15 minutes via a scheduled job. A visitor is overdue when checkin_time + expected_duration_minutes < NOW() AND status=Checked_In. |
| BR-VSM-005 | Emergency broadcast triggers notification dispatch to ALL active sys_users with role=Staff or role=Teacher via both SMS and in-app push. |
| BR-VSM-006 | Patrol round completion is calculated as (checkpoints_completed / checkpoints_total) × 100. A round below 80% completion is marked as Incomplete. |
| BR-VSM-007 | Guard shift attendance_status auto-updates to Late if actual_start_time > shift_start_time + 15 minutes. |
| BR-VSM-008 | Host notification is sent immediately on visitor check-in via the Notification module. |
| BR-VSM-009 | Visitor photo and ID proof are stored in sys_media with model_type=VisitorSecurity\Visitor and model_id=visitor_id. |

---

## 9. Permission & Authorization Model

| Permission Slug | Description |
|---|---|
| tenant.vsm-visitor.view | View visitor records |
| tenant.vsm-visitor.create | Register visitors |
| tenant.vsm-visitor.pre-register | Pre-register expected visitors |
| tenant.vsm-visitor.update | Edit visitor records |
| tenant.vsm-visit.checkin | Process gate check-in |
| tenant.vsm-visit.checkout | Process gate check-out |
| tenant.vsm-visit.view | View visit logs |
| tenant.vsm-guard-shift.manage | Schedule and manage guard shifts |
| tenant.vsm-patrol.manage | Manage patrol rounds |
| tenant.vsm-blacklist.manage | Add/remove from blacklist |
| tenant.vsm-emergency.broadcast | Trigger emergency alerts |
| tenant.vsm-report.view | View security reports |

**Role Assignments:**
- School Admin: all vsm permissions
- Principal: view, pre-register, emergency.broadcast, report.view
- Reception Staff: visitor.create, visitor.pre-register, visit.checkin, visit.checkout, visit.view
- Security Guard: visit.checkin, visit.checkout, patrol.manage (own)
- Teacher/Staff: visitor.pre-register (own visits)

---

## 10. Tests Inventory

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | 📐 VisitorRegistrationTest | Feature | Walk-in registration; photo upload; blacklist check | Critical |
| 2 | 📐 PreRegistrationQrTest | Feature | Pre-register; QR generated; SMS dispatched | High |
| 3 | 📐 GateCheckinTest | Feature | QR scan → check-in recorded; host notified | Critical |
| 4 | 📐 GateCheckoutTest | Feature | Checkout scan → duration calculated | High |
| 5 | 📐 OverdueFlaggingTest | Feature | Visitor not checked out after expected time → is_overdue=1 | High |
| 6 | 📐 BlacklistBlockTest | Feature | Visitor with blacklisted mobile → registration blocked | Critical |
| 7 | 📐 EmergencyBroadcastTest | Feature | Emergency alert dispatched to all active staff | High |
| 8 | 📐 PatrolRoundTest | Feature | Checkpoint scan sequence → completion % calculated | Medium |
| 9 | 📐 GuardShiftAttendanceTest | Feature | Clock-in after shift_start + 15 min → status=Late | Medium |
| 10 | 📐 DuplicateCheckinBlockTest | Feature | Second check-in attempt for same visitor rejected | High |

---

## 11. Known Issues & Technical Debt

| ID | Issue | Severity | Notes |
|---|---|---|---|
| 📐 | Live photo capture via webcam requires browser getUserMedia API — needs HTTPS in production | High | Enforce HTTPS; fallback to manual photo upload |
| 📐 | QR scan at gate requires device with camera — tablet/kiosk setup needed | Medium | Webcam fallback for desktops |
| 📐 | Badge printing requires physical printer integration — browser print() fallback | Medium | DomPDF for PDF badge; browser print |
| 📐 | Overdue job must handle timezone correctly for school timezone | High | Use school timezone from sys_school_settings |
| 📐 | Emergency SMS bulk dispatch may hit Twilio/SMS gateway rate limits | Medium | Queue in batches; use Notification module queue |

---

## 12. API Endpoints

| Method | URI | Name | Description |
|---|---|---|---|
| 📐 POST | /api/v1/vsm/checkin | api.vsm.checkin | QR scan check-in (kiosk/tablet) |
| 📐 POST | /api/v1/vsm/checkout | api.vsm.checkout | QR scan check-out |
| 📐 GET | /api/v1/vsm/dashboard | api.vsm.dashboard | Live campus stats (JSON) |
| 📐 POST | /api/v1/vsm/patrol/scan | api.vsm.patrol.scan | Guard scans checkpoint QR |
| 📐 GET | /api/v1/vsm/visitors/search | api.vsm.visitors.search | Search visitor by mobile/name |

All API endpoints: middleware `auth:sanctum`, prefix `/api/v1/vsm`

---

## 13. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Dashboard live count query must complete in < 1 second using indexed status+date query |
| Security | Gate pass token must be UUID v4 — not sequential IDs. Tokens expire strictly by timestamp. |
| Concurrency | Check-in must use DB transaction + row lock to prevent dual check-in race condition |
| Availability | Emergency broadcast must work even if web interface is slow — dedicated fast route |
| Privacy | Visitor ID proof images stored with access control; not publicly accessible |
| Audit | Every check-in, check-out, and emergency event must be logged in sys_activity_logs |
| QR Codes | Generated via SimpleSoftwareIO/simple-qrcode; embedded in SMS as hosted URL |

---

## 14. Integration Points

| Module | Integration Type | Details |
|---|---|---|
| Notification (ntf_*) | Dispatch | Host arrival notification, emergency broadcast, overdue alerts |
| StudentProfile (std_*) | Read | Student headcount during emergency uses std_student attendance |
| SchoolSetup (sch_*) | Read | Academic terms, school timezone from sys_school_settings |
| sys_media | Write | Visitor photos, ID proof scans, patrol checkpoint QR images |
| sys_users | Read FK | Guard assignments, host staff lookups |
| ParentPortal (PPT) | Read | Parents pre-registered by school for PTM visits linked to guardian profile |

---

## 15. Pending Work & Gap Analysis

### 15.1 Development Roadmap

| Phase | Tasks | Priority |
|---|---|---|
| Phase 1 — Setup | Migrations (9 tables), Models (9), Providers | Critical |
| Phase 2 — Visitor Registration | Visitor CRUD, pre-registration, walk-in, blacklist check | Critical |
| Phase 3 — Gate Operations | Gate pass QR, check-in, check-out, badge print | Critical |
| Phase 4 — Dashboard | Real-time campus dashboard, overdue flagging job | Critical |
| Phase 5 — Emergency | Emergency protocols CRUD, broadcast, headcount initiation | High |
| Phase 6 — Guard Management | Guard shift scheduling, clock-in/out, patrol rounds | High |
| Phase 7 — Blacklist | Blacklist CRUD, match engine on registration | High |
| Phase 8 — Reports | Visitor log, frequency, guard attendance reports | Medium |

### 15.2 Open Design Decisions

| Decision | Options | Recommendation |
|---|---|---|
| Gate pass QR delivery | SMS only vs SMS+email vs WhatsApp | SMS + email (Notification module handles channel routing) |
| Badge printing | DomPDF PDF + browser print vs thermal printer ZPL | DomPDF PDF (hardware-agnostic) |
| Live dashboard refresh | Polling (60s) vs Server-Sent Events (SSE) | Start with polling; SSE in future |
| Emergency headcount | In-app task to teachers vs dedicated headcount screen | Dedicated headcount screen with teacher response collection |

---

*RBS Reference: Module X — Visitor & Security Management (ST.X1.1.1.1 – ST.X3.2.1.2)*
*Document generated: 2026-03-25 | Status: Greenfield — All features 📐 Proposed*
