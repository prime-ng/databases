# VSM — Visitor & Security Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Roles](#3-stakeholders--roles)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [API Endpoints & Routes](#6-api-endpoints--routes)
7. [UI Screens](#7-ui-screens)
8. [Business Rules](#8-business-rules)
9. [Workflow Diagrams](#9-workflow-diagrams)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Module Dependencies](#11-module-dependencies)
12. [Test Scenarios](#12-test-scenarios)
13. [Glossary](#13-glossary)
14. [Suggestions & Improvements](#14-suggestions--improvements)
15. [Appendices](#15-appendices)
16. [V1 → V2 Delta](#16-v1--v2-delta)

---

## 1. Executive Summary

The **VSM (Visitor & Security Management)** module provides comprehensive gate security and visitor management for Indian K-12 schools on the Prime-AI platform. It digitises the entire visitor lifecycle — from pre-registration and walk-in registration through QR code gate pass issuance, check-in/check-out logging, host notifications, blacklist enforcement, student pickup authorisation, contractor access management, guard shift scheduling, security patrol rounds, and emergency lockdown broadcasts.

Indian schools face acute security concerns: unauthorised adult access during school hours, child pickup by unverified persons, contractor/vendor access to restricted areas, and emergency evacuation coordination. Manual visitor registers are error-prone, lose records, and provide zero real-time visibility.

This is a **greenfield module** — no code, migrations, or tests exist. All features are 📐 Proposed and all tables are new.

### 1.1 Module Statistics

| Metric | V1 Count | V2 Count |
|---|---|---|
| DB Tables (vsm_*) | 9 | 13 |
| Named Web Routes | ~55 | ~70 |
| Named API Routes | 5 | 12 |
| Controllers | 7 | 8 |
| Services | 3 | 4 |
| Models | 9 | 13 |
| Blade Views | ~25 | ~32 |
| FormRequests | 7 | 10 |
| Functional Requirements | 8 | 14 |

### 1.2 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 13 tables to be created |
| Models | ❌ Not Started | 13 models |
| Controllers | ❌ Not Started | 8 controllers |
| Services | ❌ Not Started | 4 services |
| Views | ❌ Not Started | ~32 blade views |
| Routes (web + api) | ❌ Not Started | ~82 named routes |
| Tests | ❌ Not Started | Feature + Unit tests |

**Overall Implementation: 0%** (Greenfield — RBS_ONLY)

---

## 2. Module Overview

### 2.1 Business Context

| Problem | Solution |
|---|---|
| Unknown visitors accessing campus unverified | Walk-in/pre-registration with photo + ID proof capture |
| Teachers unaware when expected visitor arrives | Real-time host notification on check-in |
| No visibility into who is currently on campus | Live campus dashboard with occupancy count |
| Visitors overstaying without exit recorded | Automated overdue flagging every 15 minutes |
| Child pickup by unrecognised adults | Guardian pickup authorisation workflow |
| Blacklisted persons gaining entry | Blacklist check on every registration attempt |
| No audit trail for guard duty | Guard shift scheduling + patrol round logging |
| Emergency with no structured response | One-click broadcast + automated headcount initiation |
| Contractor/vendor unrestricted access | Contractor access management with zone restrictions |
| Repeat visitor detection | Visitor history with visit_count and pattern tracking |

### 2.2 Module Placement

| Attribute | Value |
|---|---|
| Module Code | VSM |
| Module Name | Visitor & Security Management |
| Laravel Module Path | `Modules/VisitorSecurity` |
| Table Prefix | `vsm_` |
| DB Scope | tenant_db (per-school isolated) |
| RBS Code | Module X (RBS Spec v2) |
| Menu Path | School Admin → Visitor & Security |
| Priority | P4 |
| Complexity | Medium |

### 2.3 Menu Navigation

```
Visitor & Security  [/visitor-security]
├── Dashboard                          [/visitor-security/dashboard]
├── Visitor Management
│   ├── Register Walk-in               [/visitor-security/visitors/create]
│   ├── Pre-Register Visitor           [/visitor-security/visitors/pre-register]
│   ├── All Visitors                   [/visitor-security/visitors]
│   ├── Pickup Authorisation           [/visitor-security/pickup-auth]
│   └── Blacklist                      [/visitor-security/blacklist]
├── Gate Activity
│   ├── Check-in                       [/visitor-security/gate/checkin]
│   ├── Check-out                      [/visitor-security/gate/checkout]
│   └── Today's Log                    [/visitor-security/visits]
├── Contractor & Vendor Access         [/visitor-security/contractors]
├── Guard Management
│   ├── Guard Shifts                   [/visitor-security/guard-shifts]
│   └── Patrol Rounds                  [/visitor-security/patrol-rounds]
├── Emergency
│   ├── Broadcast Alert                [/visitor-security/emergency/broadcast]
│   ├── Active Events                  [/visitor-security/emergency]
│   └── Protocols                      [/visitor-security/emergency/protocols]
└── Reports
    ├── Visitor Log                    [/visitor-security/reports/visitor-log]
    ├── Frequent Visitors              [/visitor-security/reports/frequent-visitors]
    └── Guard Attendance               [/visitor-security/reports/guard-attendance]
```

### 2.4 Module Directory Structure

```
Modules/VisitorSecurity/
├── app/
│   ├── Http/Controllers/
│   │   ├── VisitorSecurityController.php     # Dashboard + module root
│   │   ├── VisitorController.php             # Visitor registration + pickup auth
│   │   ├── VisitController.php               # Visit lifecycle: checkin/checkout
│   │   ├── GatePassController.php            # QR gate pass generation + scan
│   │   ├── ContractorController.php          # Contractor/vendor access (NEW in V2)
│   │   ├── GuardShiftController.php          # Guard shift management
│   │   ├── PatrolController.php              # Patrol rounds + checkpoints
│   │   └── EmergencyController.php           # Emergency alerts + headcount
│   ├── Models/ (13 models)
│   ├── Services/
│   │   ├── VisitorService.php                # Registration, QR gen, check-in/out
│   │   ├── SecurityAlertService.php          # Emergency broadcast, overdue flagging
│   │   ├── PatrolService.php                 # Patrol scheduling, checkpoint logging
│   │   └── ContractorAccessService.php       # Contractor access rules (NEW in V2)
│   ├── Policies/ (8 policies)
│   └── Providers/
├── database/migrations/ (13 migrations)
├── resources/views/visitor-security/ (~32 views)
└── routes/ (api.php, web.php)
```

---

## 3. Stakeholders & Roles

| Actor | Role in VSM | Key Permissions |
|---|---|---|
| School Admin | Full access: configuration, reports, emergency management | All vsm.* permissions |
| Principal | View all visits, trigger emergency, approve pre-registrations | view-all, emergency.broadcast, report.view |
| Reception Staff | Walk-in + pre-registration, check-in/out, issue gate passes | visitor.create, visit.checkin, visit.checkout |
| Security Guard | QR scan at gate, log patrol rounds, update shift attendance | visit.checkin, visit.checkout, patrol.manage |
| Teacher / Staff | Pre-register expected visitors (e.g., parent for PTM) | visitor.pre-register (own visits only) |
| Parent / Guardian | Authorised pickup; may be pre-registered by school | External; receives QR via SMS |
| Contractor / Vendor | Receives time-bound access pass for work zones | External; vsm_contractors record |
| System (Scheduler) | Auto-flags overdue visitors, sends notifications | Internal job actor |
| Visitor | Receives QR gate pass via SMS/email | External |

---

## 4. Functional Requirements

---

### FR-VSM-01: Visitor Pre-Registration
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** T.X1.1.1

| Attribute | Detail |
|---|---|
| Description | A staff member (teacher/admin) pre-registers an expected visitor; the visitor receives a QR gate pass via SMS/email before arriving |
| Actors | School Admin, Teacher/Staff |
| Input | visitor_name, visitor_mobile, id_type, id_number (opt), purpose (ENUM), purpose_detail (opt), host_staff_id, expected_date, expected_time, expected_duration_minutes, vehicle_number (opt), company_name (opt) |
| Processing | 1) Check vsm_blacklist (mobile_no OR id_number match → block); 2) Upsert vsm_visitors by mobile_no; 3) Create vsm_visits (status=Pre_Registered); 4) Generate UUID v4 pass_token; 5) Render QR via SimpleSoftwareIO; 6) Store in vsm_gate_passes; 7) Dispatch SMS + email via Notification module |
| Output | Confirmation screen with QR preview; QR sent to visitor |

**Acceptance Criteria:**
- [ ] Host pre-registers visitor with name, phone, purpose, host, expected date
- [ ] QR gate pass generated and dispatched via SMS/email
- [ ] Blacklist check blocks registration if mobile_no or id_number matches

---

### FR-VSM-02: Walk-in Visitor Registration
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** T.X1.1.2

| Attribute | Detail |
|---|---|
| Description | Reception staff registers walk-in visitor at front desk; photo and ID proof captured |
| Actors | Reception Staff, School Admin |
| Input | All pre-registration fields + photo_capture (webcam/file → sys_media) + id_proof_scan (image → sys_media) |
| Processing | Create vsm_visitors (or match by mobile_no); create vsm_visits (status=Registered); blacklist check; generate gate pass; notify host in-app |
| Output | Gate pass QR shown on screen; printable badge available |

**Acceptance Criteria:**
- [ ] Walk-in registered with photo and ID proof
- [ ] Gate pass QR generated immediately
- [ ] Host receives in-app notification of visitor arrival

---

### FR-VSM-03: Gate Check-in
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** T.X2.1.1

| Attribute | Detail |
|---|---|
| Description | Security guard scans visitor's QR code at gate to record entry |
| Actors | Security Guard, Reception Staff |
| Input | QR scan (pass_token) OR manual search by visitor name/mobile |
| Processing | 1) Decode token → vsm_gate_passes; 2) Validate: status=Issued, not expired, visit not already checked-in; 3) Blacklist re-check; 4) Set vsm_visits.checkin_time=NOW(), status=Checked_In; 5) Mark gate pass status=Used; 6) Capture optional live gate photo; 7) Notify host via Notification module |
| Output | Check-in confirmed; badge PDF triggered; host notified |

**Acceptance Criteria:**
- [ ] QR scan records check-in time
- [ ] Blacklist match at gate triggers alert to security
- [ ] Host notification dispatched on check-in
- [ ] Printable visitor badge generated (DomPDF)

---

### FR-VSM-04: Gate Check-out
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** T.X2.1.2

| Attribute | Detail |
|---|---|
| Description | Guard scans badge/QR on visitor exit; duration calculated; overdue visitors flagged |
| Actors | Security Guard, Reception Staff |
| Processing | Set vsm_visits.checkout_time=NOW(), status=Checked_Out; calculate duration_minutes; mark gate pass status=Closed; clear is_overdue if set |
| Overdue Job | Scheduled every 15 min: flag visits where checkin_time + expected_duration_minutes < NOW() AND status=Checked_In; send security desk in-app alert |

**Acceptance Criteria:**
- [ ] Check-out time and duration recorded
- [ ] Overdue visitors flagged automatically by scheduler
- [ ] Overdue visitors shown with red indicator on dashboard

---

### FR-VSM-05: Real-time Campus Dashboard
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.X3.1 / T.X3.1.1

| Attribute | Detail |
|---|---|
| Description | Security office screen showing live visitor count, current check-in list, overdue alerts, and campus occupancy summary |
| Actors | School Admin, Principal, Reception Staff, Security Guard |
| Processing | Aggregate vsm_visits WHERE status=Checked_In; overdue count; repeat visitor count today; last 5 check-in events; dashboard auto-refreshes every 60 seconds (or SSE) |

**Dashboard Widgets:**

| Widget | Data Source | Refresh |
|---|---|---|
| Visitors On Campus (count) | vsm_visits WHERE status=Checked_In | 60s |
| Overdue Visitors (count + list) | vsm_visits WHERE is_overdue=1 AND status=Checked_In | 60s |
| Today's Total Visitors | vsm_visits WHERE DATE(expected_date)=today | 60s |
| Blacklist Hits Today | vsm_visits WHERE blacklist_hit=1 AND DATE(checkin_time)=today | 60s |
| Recent Check-ins (last 5) | vsm_visits ordered by checkin_time DESC | 60s |
| Pending Pre-Registrations | vsm_visits WHERE status=Pre_Registered AND expected_date=today | 60s |

**Acceptance Criteria:**
- [ ] Live visitor count displayed
- [ ] Overdue visitors highlighted in red
- [ ] Dashboard auto-refreshes

---

### FR-VSM-06: Emergency Alert System
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.X3.2 / T.X3.2.1

| Attribute | Detail |
|---|---|
| Description | Admin or Principal triggers instant emergency broadcast; automated headcount initiation |
| Actors | School Admin, Principal |
| Input | emergency_type (ENUM: Lockdown/Fire/Earthquake/MedicalEmergency/Evacuation/Other), message (max 500), affected_zones (opt) |
| Processing | 1) Create vsm_emergency_events; 2) Dispatch SMS to ALL active staff mobiles + in-app push; 3) If type=Lockdown: set vsm_emergency_events.is_lockdown_active=true (blocks new gate pass generation); 4) Initiate headcount: query present students from ATT module; dispatch per-section headcount task to class teachers |
| Lockdown Mode | When is_lockdown_active=true: gate pass generation disabled; check-in screen shows LOCKDOWN banner |

**Acceptance Criteria:**
- [ ] Emergency SMS + in-app alert sent to all active staff
- [ ] Automated headcount task dispatched to class teachers
- [ ] Lockdown mode disables new gate pass generation

---

### FR-VSM-07: Student Pickup Authorisation
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** BR-M-002 (RBS Spec)

| Attribute | Detail |
|---|---|
| Description | Verify that a person picking up a student is an authorised guardian before releasing the student |
| Actors | Reception Staff, Security Guard |
| Input | student_id, guardian_name, guardian_mobile, guardian_id_proof (photo), relationship |
| Processing | 1) Look up std_student_guardians (or equivalent) to check authorised pickup list; 2) If match: log vsm_visits with purpose=StudentPickup, link student_id; mark authorised=true; 3) If no match: require supervisor override + photo capture + reason logging |
| Output | Authorised pickup logged; unauthorised attempt alerts security head |

**Acceptance Criteria:**
- [ ] Authorised guardian verified against student's guardian list
- [ ] Unauthorised pickup attempt logged and supervisor alerted
- [ ] Pickup record linked to student ID

---

### FR-VSM-08: Contractor & Vendor Access Management
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** V2 Enhancement

| Attribute | Detail |
|---|---|
| Description | Manage contractor/vendor entries with work order, access zones, and time-bound passes |
| Actors | School Admin, Reception Staff |
| Input | contractor_name, company_name, mobile_no, work_order_no, work_description, allowed_zones (JSON), access_from (date), access_until (date), entry_days_json (Mon–Sat flags), id_proof |
| Processing | Create vsm_contractors record; generate recurring or single-use access token; check against blacklist; notify admin on each entry |
| Special Rules | Contractor access auto-expires on access_until date; multi-day access generates single reusable pass token valid within date range |

**Acceptance Criteria:**
- [ ] Contractor registered with work order and access zone restrictions
- [ ] Multi-day pass token generated for date-range access
- [ ] Access auto-expires after access_until date

---

### FR-VSM-09: Visitor Blacklist Management
**Status:** 📐 Proposed | **Priority:** High

| Attribute | Detail |
|---|---|
| Description | Admin flags a person as blacklisted; system blocks entry and alerts security on any future registration attempt |
| Actors | School Admin, Principal |
| Input | name, mobile_no (opt), id_type + id_number (opt), photo (opt), reason (required), valid_until (opt — NULL = permanent) |
| Processing | Create vsm_blacklist entry; all future registrations matching mobile_no OR id_number trigger alert + block |

**Acceptance Criteria:**
- [ ] Blacklisted person blocked on registration attempt
- [ ] Alert shown to reception staff with blacklist reason
- [ ] Blacklist_hit flag recorded on vsm_visits

---

### FR-VSM-10: Guard Shift Management
**Status:** 📐 Proposed | **Priority:** High

| Attribute | Detail |
|---|---|
| Description | Admin schedules guards to shifts; guards clock in/out; attendance auto-calculated |
| Input | guard_user_id, shift_date, shift_start_time, shift_end_time, post (gate/patrol/block) |
| Clock-in/out | Guard records actual_start_time / actual_end_time; attendance_status auto-set: Late if actual_start > shift_start + 15 min; Early_Departure if actual_end < shift_end - 15 min |

**Acceptance Criteria:**
- [ ] Guard shift scheduled without overlap for same guard
- [ ] Clock-in sets attendance_status; auto-marks Late
- [ ] Guard attendance report available by date range

---

### FR-VSM-11: Security Patrol Rounds
**Status:** 📐 Proposed | **Priority:** High

| Attribute | Detail |
|---|---|
| Description | Guard scans checkpoint QR codes during patrol to prove physical presence; completion % tracked |
| Checkpoint Setup | Admin defines campus checkpoints with name, location, building, floor, sequence; QR code placed at physical location |
| Patrol Logging | Guard starts round → scans each checkpoint QR → system records timestamp per scan; completion % = (scanned / total) × 100 |
| Incomplete Round | < 80% completion flagged as Incomplete; admin alerted |

**Acceptance Criteria:**
- [ ] Checkpoint QR scan logged with timestamp
- [ ] Completion percentage calculated
- [ ] Rounds below 80% flagged as Incomplete

---

### FR-VSM-12: Repeat Visitor Detection
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** V2 Enhancement

| Attribute | Detail |
|---|---|
| Description | System identifies frequent visitors and surfaces their history for quick re-registration |
| Processing | On registration, match mobile_no in vsm_visitors; if visit_count > 0: show "Returning visitor" badge with last visit date and purpose; auto-fill known fields (name, id_type, company) |
| Frequent Visitor Report | Top visitors by frequency; flag visitors with > N visits per month for review |

---

### FR-VSM-13: CCTV Integration Hooks
**Status:** 📐 Proposed | **Priority:** Low | **RBS Ref:** V2 Enhancement

| Attribute | Detail |
|---|---|
| Description | Webhook endpoints to receive camera trigger events (motion detection, gate open) from third-party CCTV systems |
| Processing | POST /api/v1/vsm/cctv/event: receive {camera_id, event_type, timestamp, snapshot_url}; create vsm_cctv_events record; link to active visit if gate camera during check-in window |
| Note | Hardware integration is out of scope; only webhook ingestion layer provided |

---

### FR-VSM-14: Visitor Log Reports
**Status:** 📐 Proposed | **Priority:** Medium

| Report | Filters | Export |
|---|---|---|
| Daily Visitor Log | Date, gate, purpose, status | PDF, CSV |
| Frequent Visitors | Date range, min visit count | CSV |
| Overdue Incidents | Date range | CSV |
| Guard Attendance | Date range, guard name | PDF, CSV |
| Blacklist Hits | Date range | CSV |
| Contractor Access Log | Date range, company | CSV |

---

## 5. Data Model

### 5.1 New Tables (vsm_* prefix)

> Standard audit columns on all tables: `id BIGINT UNSIGNED PK AUTO_INCREMENT`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK→sys_users`, `created_at TIMESTAMP`, `updated_at TIMESTAMP`, `deleted_at TIMESTAMP NULL`.

| Table | Status | Description |
|---|---|---|
| `vsm_visitors` | 📐 New | Master visitor profile (matches by mobile_no) |
| `vsm_visits` | 📐 New | Per-visit record: purpose, checkin/out, status |
| `vsm_gate_passes` | 📐 New | QR gate pass tokens (one per visit) |
| `vsm_contractors` | 📐 New | Contractor/vendor multi-day access records |
| `vsm_pickup_auth` | 📐 New | Student pickup authorisation log |
| `vsm_blacklist` | 📐 New | Blacklisted persons |
| `vsm_guard_shifts` | 📐 New | Guard shift schedules and attendance |
| `vsm_patrol_checkpoints` | 📐 New | Campus patrol checkpoint definitions |
| `vsm_patrol_rounds` | 📐 New | Per-patrol-round summary |
| `vsm_patrol_checkpoint_log` | 📐 New | Per-checkpoint scan within a round |
| `vsm_emergency_protocols` | 📐 New | SOP templates per emergency type |
| `vsm_emergency_events` | 📐 New | Active emergency events log |
| `vsm_cctv_events` | 📐 New | Inbound webhook events from CCTV systems |

---

#### 📐 `vsm_visitors`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | Full visitor name |
| mobile_no | VARCHAR(20) | NOT NULL | Primary match key |
| email | VARCHAR(100) | NULL | |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | NULL | |
| id_number | VARCHAR(50) | NULL | Secondary match key |
| company_name | VARCHAR(150) | NULL | |
| photo_media_id | BIGINT UNSIGNED | NULL FK→sys_media | Visitor photo |
| id_proof_media_id | BIGINT UNSIGNED | NULL FK→sys_media | ID proof scan |
| visit_count | INT UNSIGNED | DEFAULT 0 | Denormalised total visits |
| is_blacklisted | TINYINT(1) | DEFAULT 0 | Cache flag from vsm_blacklist |

INDEX: `(mobile_no)`, `(id_number)`

---

#### 📐 `vsm_visits`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| visit_number | VARCHAR(30) | NOT NULL UNIQUE | Format: VSM-YYYYMMDD-XXXX |
| visitor_id | BIGINT UNSIGNED | NOT NULL FK→vsm_visitors | |
| host_user_id | BIGINT UNSIGNED | NULL FK→sys_users | Staff being visited |
| purpose | ENUM('PTM','Admission','Meeting','Delivery','Maintenance','Interview','StudentPickup','Contractor','Other') | NOT NULL | |
| purpose_detail | VARCHAR(255) | NULL | |
| expected_date | DATE | NOT NULL | |
| expected_time | TIME | NULL | |
| expected_duration_minutes | SMALLINT UNSIGNED | DEFAULT 60 | |
| vehicle_number | VARCHAR(20) | NULL | |
| gate_assigned | VARCHAR(50) | NULL | Main Gate / Back Gate etc. |
| checkin_time | TIMESTAMP | NULL | |
| checkin_photo_media_id | BIGINT UNSIGNED | NULL FK→sys_media | Live gate photo |
| checkout_time | TIMESTAMP | NULL | |
| duration_minutes | SMALLINT UNSIGNED | NULL | Calculated on checkout |
| status | ENUM('Pre_Registered','Registered','Checked_In','Checked_Out','No_Show','Cancelled') | DEFAULT 'Registered' | |
| is_overdue | TINYINT(1) | DEFAULT 0 | Flagged by scheduler |
| blacklist_hit | TINYINT(1) | DEFAULT 0 | Match found on registration |
| notes | TEXT | NULL | |

INDEX: `(expected_date, status)`, `(visitor_id)`, `(host_user_id)`, `(checkin_time)`

---

#### 📐 `vsm_gate_passes`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| visit_id | BIGINT UNSIGNED | NOT NULL UNIQUE FK→vsm_visits | One pass per visit |
| visitor_id | BIGINT UNSIGNED | NOT NULL FK→vsm_visitors | |
| pass_token | VARCHAR(100) | NOT NULL UNIQUE | UUID v4 encoded in QR |
| qr_code_path | VARCHAR(255) | NULL | Stored QR image path |
| status | ENUM('Issued','Used','Expired','Revoked') | DEFAULT 'Issued' | |
| issued_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| expires_at | TIMESTAMP | NOT NULL | issued_at + 24 h or end of expected_date |
| used_at | TIMESTAMP | NULL | When scanned at gate |

---

#### 📐 `vsm_contractors`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| contractor_name | VARCHAR(150) | NOT NULL | |
| company_name | VARCHAR(150) | NULL | |
| mobile_no | VARCHAR(20) | NOT NULL | |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | NULL | |
| id_number | VARCHAR(50) | NULL | |
| photo_media_id | BIGINT UNSIGNED | NULL FK→sys_media | |
| work_order_no | VARCHAR(100) | NULL | |
| work_description | TEXT | NULL | |
| allowed_zones_json | JSON | NULL | Array of zone names |
| access_from | DATE | NOT NULL | |
| access_until | DATE | NOT NULL | |
| entry_days_json | JSON | NULL | e.g., ["Mon","Tue","Wed"] |
| pass_token | VARCHAR(100) | NOT NULL UNIQUE | Reusable within date range |
| pass_status | ENUM('Active','Expired','Revoked') | DEFAULT 'Active' | |
| entry_count | INT UNSIGNED | DEFAULT 0 | |

INDEX: `(mobile_no)`, `(access_from, access_until)`, `(pass_status)`

---

#### 📐 `vsm_pickup_auth`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| visit_id | BIGINT UNSIGNED | NOT NULL FK→vsm_visits | |
| student_id | BIGINT UNSIGNED | NOT NULL FK→std_students | Student being picked up |
| guardian_name | VARCHAR(150) | NOT NULL | |
| guardian_mobile | VARCHAR(20) | NOT NULL | |
| relationship | VARCHAR(50) | NULL | Father/Mother/Uncle etc. |
| is_authorised | TINYINT(1) | NOT NULL | Match found in guardian list |
| id_proof_media_id | BIGINT UNSIGNED | NULL FK→sys_media | Guardian ID proof |
| override_by | BIGINT UNSIGNED | NULL FK→sys_users | Supervisor who overrode |
| override_reason | TEXT | NULL | |
| processed_by | BIGINT UNSIGNED | NOT NULL FK→sys_users | Reception staff |

INDEX: `(student_id)`, `(visit_id)`

---

#### 📐 `vsm_blacklist`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | |
| mobile_no | VARCHAR(20) | NULL | Match key |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | NULL | |
| id_number | VARCHAR(50) | NULL | Match key |
| photo_media_id | BIGINT UNSIGNED | NULL FK→sys_media | |
| reason | TEXT | NOT NULL | Why blacklisted |
| blacklisted_by | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| valid_until | DATE | NULL | NULL = permanent |

INDEX: `(mobile_no)`, `(id_number)`

---

#### 📐 `vsm_guard_shifts`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| guard_user_id | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| shift_date | DATE | NOT NULL | |
| shift_start_time | TIME | NOT NULL | |
| shift_end_time | TIME | NOT NULL | |
| post | VARCHAR(100) | NOT NULL | Main Gate / Back Gate etc. |
| actual_start_time | TIMESTAMP | NULL | Clock-in |
| actual_end_time | TIMESTAMP | NULL | Clock-out |
| attendance_status | ENUM('Scheduled','Present','Absent','Late','Early_Departure') | DEFAULT 'Scheduled' | |
| notes | TEXT | NULL | |

UNIQUE KEY `uq_vsm_guard_shift` (`guard_user_id`, `shift_date`, `shift_start_time`)

---

#### 📐 `vsm_patrol_checkpoints`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., Lab Block Entrance |
| location_description | TEXT | NULL | |
| building | VARCHAR(100) | NULL | |
| floor | VARCHAR(20) | NULL | |
| sequence_order | TINYINT UNSIGNED | DEFAULT 0 | Order in patrol route |
| qr_token | VARCHAR(100) | NOT NULL UNIQUE | QR placed at location |
| qr_code_path | VARCHAR(255) | NULL | |

---

#### 📐 `vsm_patrol_rounds`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| guard_user_id | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| guard_shift_id | BIGINT UNSIGNED | NULL FK→vsm_guard_shifts | |
| patrol_start_time | TIMESTAMP | NOT NULL | |
| patrol_end_time | TIMESTAMP | NULL | |
| checkpoints_total | TINYINT UNSIGNED | DEFAULT 0 | |
| checkpoints_completed | TINYINT UNSIGNED | DEFAULT 0 | |
| completion_pct | DECIMAL(5,2) | DEFAULT 0.00 | |
| status | ENUM('In_Progress','Completed','Incomplete') | DEFAULT 'In_Progress' | |
| notes | TEXT | NULL | |

---

#### 📐 `vsm_patrol_checkpoint_log`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| patrol_round_id | BIGINT UNSIGNED | NOT NULL FK→vsm_patrol_rounds | |
| checkpoint_id | BIGINT UNSIGNED | NOT NULL FK→vsm_patrol_checkpoints | |
| scanned_at | TIMESTAMP | NOT NULL | |
| notes | TEXT | NULL | |
| created_at | TIMESTAMP | | |

---

#### 📐 `vsm_emergency_protocols`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| protocol_type | ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other') | NOT NULL | |
| title | VARCHAR(200) | NOT NULL | |
| description | TEXT | NOT NULL | Step-by-step SOPs |
| responsible_roles_json | JSON | NULL | Array of role slugs |
| media_ids_json | JSON | NULL | sys_media IDs (maps, SOPs) |

---

#### 📐 `vsm_emergency_events`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| emergency_type | ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other') | NOT NULL | |
| protocol_id | BIGINT UNSIGNED | NULL FK→vsm_emergency_protocols | |
| message | TEXT | NOT NULL | |
| affected_zones | VARCHAR(500) | NULL | |
| triggered_by | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| triggered_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| resolved_at | TIMESTAMP | NULL | |
| is_lockdown_active | TINYINT(1) | DEFAULT 0 | Blocks gate pass generation |
| notification_count | INT UNSIGNED | DEFAULT 0 | Staff notified count |
| headcount_initiated | TINYINT(1) | DEFAULT 0 | |

---

#### 📐 `vsm_cctv_events`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | BIGINT UNSIGNED | PK AUTO_INCREMENT | |
| camera_id | VARCHAR(100) | NOT NULL | External camera identifier |
| event_type | VARCHAR(100) | NOT NULL | e.g., motion_detected, gate_open |
| event_timestamp | TIMESTAMP | NOT NULL | |
| snapshot_url | VARCHAR(500) | NULL | External URL from CCTV system |
| linked_visit_id | BIGINT UNSIGNED | NULL FK→vsm_visits | Auto-linked if gate camera |
| raw_payload_json | JSON | NULL | Full webhook payload |
| created_at | TIMESTAMP | | |

INDEX: `(camera_id, event_timestamp)`

---

### 5.2 Entity Relationships

```
vsm_visitors ──1:N── vsm_visits ──1:1── vsm_gate_passes
                         │
                    host_user_id ────── sys_users
                         │
                    checkin_photo_media_id ─── sys_media
                         │
                    vsm_pickup_auth ─── std_students

vsm_contractors  (standalone, own pass_token)

vsm_blacklist  (checked against vsm_visitors.mobile_no / id_number)

vsm_guard_shifts ──── sys_users
        │
vsm_patrol_rounds ──1:N── vsm_patrol_checkpoint_log ──── vsm_patrol_checkpoints

vsm_emergency_protocols (templates)
vsm_emergency_events ──── vsm_emergency_protocols (opt ref)
                       ──── sys_users (triggered_by)

vsm_cctv_events ──── vsm_visits (opt link)
```

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (tenant middleware)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | /visitor-security/dashboard | VisitorSecurityController@dashboard | Admin,Principal,Reception,Guard | Module dashboard |
| GET | /visitor-security/visitors | VisitorController@index | vsm-visitor.view | List all visitors |
| GET | /visitor-security/visitors/create | VisitorController@create | vsm-visitor.create | Walk-in registration form |
| POST | /visitor-security/visitors | VisitorController@store | vsm-visitor.create | Store walk-in visitor |
| GET | /visitor-security/visitors/pre-register | VisitorController@preRegister | vsm-visitor.pre-register | Pre-registration form |
| POST | /visitor-security/visitors/pre-register | VisitorController@storePreRegister | vsm-visitor.pre-register | Store pre-registration |
| GET | /visitor-security/visitors/{visitor} | VisitorController@show | vsm-visitor.view | Visitor profile + history |
| GET | /visitor-security/visitors/{visitor}/edit | VisitorController@edit | vsm-visitor.update | Edit visitor form |
| PUT | /visitor-security/visitors/{visitor} | VisitorController@update | vsm-visitor.update | Update visitor |
| DELETE | /visitor-security/visitors/{visitor} | VisitorController@destroy | vsm-visitor.delete | Soft delete visitor |
| POST | /visitor-security/visitors/{visitor}/send-qr | VisitorController@sendQr | vsm-visitor.create | Resend QR pass |
| GET | /visitor-security/visits | VisitController@index | vsm-visit.view | All visits log |
| GET | /visitor-security/visits/today | VisitController@today | vsm-visit.view | Today's visit log |
| GET | /visitor-security/visits/{visit} | VisitController@show | vsm-visit.view | Visit detail |
| GET | /visitor-security/gate/checkin | VisitController@checkin | vsm-visit.checkin | QR scan check-in screen |
| POST | /visitor-security/gate/checkin | VisitController@processCheckin | vsm-visit.checkin | Process check-in |
| GET | /visitor-security/gate/checkout | VisitController@checkout | vsm-visit.checkout | Check-out screen |
| POST | /visitor-security/gate/checkout | VisitController@processCheckout | vsm-visit.checkout | Process check-out |
| GET | /visitor-security/gate-passes/{pass}/badge | GatePassController@badge | vsm-visit.checkin | Print visitor badge PDF |
| POST | /visitor-security/gate-passes/{pass}/revoke | GatePassController@revoke | vsm-visitor.update | Revoke gate pass |
| GET | /visitor-security/pickup-auth | VisitorController@pickupIndex | vsm-visitor.view | Pickup authorisation list |
| POST | /visitor-security/pickup-auth | VisitorController@processPickup | vsm-visitor.create | Process student pickup |
| GET | /visitor-security/contractors | ContractorController@index | vsm-contractor.view | Contractor list |
| GET | /visitor-security/contractors/create | ContractorController@create | vsm-contractor.manage | Create contractor |
| POST | /visitor-security/contractors | ContractorController@store | vsm-contractor.manage | Store contractor |
| GET | /visitor-security/contractors/{contractor} | ContractorController@show | vsm-contractor.view | Contractor detail |
| PUT | /visitor-security/contractors/{contractor} | ContractorController@update | vsm-contractor.manage | Update contractor |
| POST | /visitor-security/contractors/{contractor}/revoke | ContractorController@revoke | vsm-contractor.manage | Revoke access |
| GET | /visitor-security/blacklist | VisitorController@blacklistIndex | vsm-blacklist.manage | Blacklist list |
| POST | /visitor-security/blacklist | VisitorController@blacklistStore | vsm-blacklist.manage | Add to blacklist |
| DELETE | /visitor-security/blacklist/{entry} | VisitorController@blacklistDestroy | vsm-blacklist.manage | Remove from blacklist |
| GET | /visitor-security/guard-shifts | GuardShiftController@index | vsm-guard-shift.manage | Guard shifts list |
| GET | /visitor-security/guard-shifts/create | GuardShiftController@create | vsm-guard-shift.manage | Create shift form |
| POST | /visitor-security/guard-shifts | GuardShiftController@store | vsm-guard-shift.manage | Store shift |
| PUT | /visitor-security/guard-shifts/{shift} | GuardShiftController@update | vsm-guard-shift.manage | Update shift |
| POST | /visitor-security/guard-shifts/{shift}/clock-in | GuardShiftController@clockIn | vsm-guard-shift.self | Guard clock-in |
| POST | /visitor-security/guard-shifts/{shift}/clock-out | GuardShiftController@clockOut | vsm-guard-shift.self | Guard clock-out |
| GET | /visitor-security/patrol-rounds | PatrolController@index | vsm-patrol.manage | Patrol rounds list |
| POST | /visitor-security/patrol-rounds | PatrolController@store | vsm-patrol.manage | Start patrol round |
| GET | /visitor-security/patrol-rounds/{round} | PatrolController@show | vsm-patrol.manage | Round detail |
| POST | /visitor-security/patrol-rounds/{round}/scan | PatrolController@scanCheckpoint | vsm-patrol.manage | Log checkpoint scan |
| POST | /visitor-security/patrol-rounds/{round}/complete | PatrolController@complete | vsm-patrol.manage | Complete round |
| GET | /visitor-security/patrol-checkpoints | PatrolController@checkpoints | vsm-patrol.manage | Checkpoint management |
| POST | /visitor-security/patrol-checkpoints | PatrolController@storeCheckpoint | vsm-patrol.manage | Create checkpoint |
| GET | /visitor-security/emergency | EmergencyController@index | vsm-emergency.view | Emergency events list |
| GET | /visitor-security/emergency/broadcast | EmergencyController@broadcastForm | vsm-emergency.broadcast | Broadcast form |
| POST | /visitor-security/emergency/broadcast | EmergencyController@broadcast | vsm-emergency.broadcast | Trigger broadcast |
| POST | /visitor-security/emergency/{event}/resolve | EmergencyController@resolve | vsm-emergency.broadcast | Resolve emergency |
| GET | /visitor-security/emergency/protocols | EmergencyController@protocols | vsm-emergency.view | Protocol list |
| POST | /visitor-security/emergency/protocols | EmergencyController@storeProtocol | vsm-emergency.broadcast | Create protocol |
| GET | /visitor-security/reports/visitor-log | ReportController@visitorLog | vsm-report.view | Visitor log report |
| GET | /visitor-security/reports/frequent-visitors | ReportController@frequentVisitors | vsm-report.view | Frequent visitors |
| GET | /visitor-security/reports/guard-attendance | ReportController@guardAttendance | vsm-report.view | Guard attendance |

### 6.2 API Routes (auth:sanctum, prefix /api/v1/vsm)

| Method | URI | Controller@Method | Description |
|---|---|---|---|
| POST | /api/v1/vsm/checkin | Api\VsmApiController@checkin | QR scan check-in (kiosk/tablet) |
| POST | /api/v1/vsm/checkout | Api\VsmApiController@checkout | QR scan check-out |
| GET | /api/v1/vsm/dashboard | Api\VsmApiController@dashboard | Live campus stats (JSON) |
| POST | /api/v1/vsm/patrol/scan | Api\VsmApiController@patrolScan | Guard scans checkpoint QR |
| GET | /api/v1/vsm/visitors/search | Api\VsmApiController@searchVisitor | Search by mobile/name |
| GET | /api/v1/vsm/gate-passes/{token}/validate | Api\VsmApiController@validatePass | Validate gate pass token |
| POST | /api/v1/vsm/contractors/checkin | Api\VsmApiController@contractorCheckin | Contractor entry check-in |
| POST | /api/v1/vsm/emergency/broadcast | Api\VsmApiController@emergencyBroadcast | Emergency alert (mobile app) |
| GET | /api/v1/vsm/active-visits | Api\VsmApiController@activeVisits | Current on-campus visitors |
| POST | /api/v1/vsm/cctv/event | Api\VsmApiController@cctvEvent | Receive CCTV webhook event |
| GET | /api/v1/vsm/guard-shifts/today | Api\VsmApiController@todayShifts | Guard's today shifts |
| POST | /api/v1/vsm/guard-shifts/{shift}/clock | Api\VsmApiController@guardClock | Guard clock-in/out (mobile) |

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Description |
|---|---|---|---|
| SCR-VSM-01 | Security Dashboard | vsm.dashboard | Live occupancy count, overdue alerts, recent check-ins, quick actions |
| SCR-VSM-02 | Visitor List | vsm.visitors.index | Searchable list with photo, mobile, visit count, blacklist badge |
| SCR-VSM-03 | Walk-in Registration | vsm.visitors.create | Form: name, mobile, ID, photo capture, purpose, host selection |
| SCR-VSM-04 | Pre-Registration | vsm.visitors.pre-register | Host pre-registers: visitor details + expected date/time + QR dispatch |
| SCR-VSM-05 | Visitor Profile | vsm.visitors.show | Profile + full visit history + blacklist status |
| SCR-VSM-06 | Gate Check-in | vsm.gate.checkin | QR scan widget + manual search fallback; live camera capture |
| SCR-VSM-07 | Gate Check-out | vsm.gate.checkout | QR scan or manual search; duration display |
| SCR-VSM-08 | Today's Visit Log | vsm.visits.today | Chronological table: all today's visits with status badges |
| SCR-VSM-09 | Visit Detail | vsm.visits.show | Full visit record with photo, ID proof, timeline |
| SCR-VSM-10 | Gate Pass Badge | vsm.gate-passes.badge | Printable PDF badge: photo, name, purpose, host, valid until |
| SCR-VSM-11 | Pickup Authorisation | vsm.pickup-auth.index | List of pending/completed student pickups |
| SCR-VSM-12 | Contractor List | vsm.contractors.index | Active contractors with zone badges and expiry dates |
| SCR-VSM-13 | Contractor Form | vsm.contractors.create | Contractor registration: work order, zones, date range |
| SCR-VSM-14 | Blacklist | vsm.blacklist.index | Blacklisted persons with reason, added by, valid until |
| SCR-VSM-15 | Guard Shifts | vsm.guard-shifts.index | Weekly schedule grid; attendance status indicators |
| SCR-VSM-16 | Shift Form | vsm.guard-shifts.create | Create/edit guard shift: guard, post, date, time |
| SCR-VSM-17 | Patrol Rounds | vsm.patrol.index | Patrol round history with completion % progress bars |
| SCR-VSM-18 | Active Patrol | vsm.patrol.show | Live patrol: checkpoint checklist; scan button per checkpoint |
| SCR-VSM-19 | Checkpoint Management | vsm.patrol.checkpoints | Define/edit campus checkpoints; QR print per checkpoint |
| SCR-VSM-20 | Emergency Broadcast | vsm.emergency.broadcast | Alert type selector, message, zone; big RED button |
| SCR-VSM-21 | Active Emergency | vsm.emergency.index | Current lockdown status; headcount progress per section |
| SCR-VSM-22 | Emergency Protocols | vsm.emergency.protocols | SOP list per emergency type; attach media files |
| SCR-VSM-23 | Visitor Log Report | vsm.reports.visitor-log | Filtered date range report; PDF/CSV export |
| SCR-VSM-24 | Frequent Visitors Report | vsm.reports.frequent-visitors | Top visitors by frequency; CSV export |
| SCR-VSM-25 | Guard Attendance Report | vsm.reports.guard-attendance | Guard-wise attendance with late/early stats; PDF/CSV |

---

## 8. Business Rules

| Rule ID | Description |
|---|---|
| BR-VSM-001 | Blacklist check is mandatory on every visitor registration. Match by mobile_no OR id_number. Matching visitor is blocked and reception staff sees alert with blacklist reason. |
| BR-VSM-002 | Gate pass token must be UUID v4 (not sequential). Expires at end of expected_date OR after 24 hours from issuance, whichever is earlier. |
| BR-VSM-003 | A visitor can only have one active (status=Checked_In) visit at a time. A second check-in attempt requires supervisor override with reason. |
| BR-VSM-004 | Overdue flagging scheduler runs every 15 minutes. A visit is overdue when: checkin_time + expected_duration_minutes < NOW() AND status=Checked_In. |
| BR-VSM-005 | Emergency broadcast dispatches notifications to ALL active sys_users (staff and teachers) via SMS + in-app push simultaneously. |
| BR-VSM-006 | Patrol round completion = (checkpoints_completed / checkpoints_total) × 100. Rounds with completion < 80% are auto-marked status=Incomplete. |
| BR-VSM-007 | Guard attendance_status is auto-set to Late if actual_start_time > shift_start_time + 15 minutes; Early_Departure if actual_end_time < shift_end_time - 15 minutes. |
| BR-VSM-008 | Host notification dispatched immediately on visitor check-in via Notification module (in-app + SMS if staff mobile is set). |
| BR-VSM-009 | Visitor photos and ID proof stored in sys_media with model_type=vsm_visitors and model_id=visitor.id. Not publicly accessible (private disk). |
| BR-VSM-010 | When is_lockdown_active=true on any vsm_emergency_events: gate pass generation is disabled; check-in screen shows LOCKDOWN banner; new walk-in registrations require admin override. |
| BR-VSM-011 | Student pickup by unrecognised guardian requires supervisor override logged with override_reason and supervisor ID. |
| BR-VSM-012 | Contractor pass_token is valid only within access_from to access_until date range and only on days listed in entry_days_json. |
| BR-VSM-013 | vsm_visitors.visit_count is incremented on each confirmed check-in (status transitions to Checked_In). |
| BR-VSM-014 | Blacklist entries with valid_until < TODAY() are auto-expired (is_active=0) by the daily scheduler. |
| BR-VSM-015 | All check-in, check-out, emergency broadcast, and blacklist-hit events are written to sys_activity_logs. |

---

## 9. Workflow Diagrams

### 9.1 Visitor Lifecycle FSM

```
[Pre_Registered] ──(check-in scan)──► [Checked_In] ──(check-out scan)──► [Checked_Out]
      │                                     │
      │ (no-show after expected_date)        │ (overdue job fires)
      ▼                                     ▼
  [No_Show]                          [is_overdue=true]  ──(manual check-out)──► [Checked_Out]
      │
[Registered] ──(check-in scan)──► [Checked_In]
      │
      │ (cancelled by host/admin)
      ▼
  [Cancelled]
```

### 9.2 Gate Pass Status FSM

```
[Issued] ──(QR scanned at gate)──► [Used]
   │
   │ (expires_at < NOW)
   ▼
[Expired]
   │
   │ (revoked by admin)
[Revoked]
```

### 9.3 Emergency Event FSM

```
[Triggered] ──(notifications dispatched)──► [Active]
                                                │
                                     (lockdown enabled if type=Lockdown)
                                                │
                                   (Admin resolves: set resolved_at)
                                                ▼
                                          [Resolved]
```

### 9.4 Guard Shift Attendance FSM

```
[Scheduled]
    │
    │ (guard clocks in)
    ▼
[Present] or [Late]   (Late if actual_start > shift_start + 15min)
    │
    │ (guard clocks out)
    ▼
[Present/Complete] or [Early_Departure]  (Early if actual_end < shift_end - 15min)
```

### 9.5 Pre-Registration + Check-in Flow

```
Host fills pre-registration form
        │
        ▼
Blacklist check ──(match)──► Block + Alert security + Log blacklist_hit
        │
     (no match)
        ▼
vsm_visitors upsert (by mobile_no)
        │
        ▼
vsm_visits created (status=Pre_Registered)
        │
        ▼
QR gate pass generated (pass_token = UUID v4)
        │
        ▼
SMS + email to visitor via Notification module
        │
        ▼
--- VISITOR ARRIVES ---
        │
        ▼
Guard scans QR at gate
        │
        ▼
Token validation: status=Issued? Not expired? Not already checked in?
        ├── No ──► Error shown to guard
        └── Yes ──► checkin_time=NOW(), status=Checked_In
                         │
                         ▼
                   Gate photo captured (optional)
                         │
                         ▼
                   pass_token status = Used
                         │
                         ▼
                   Notify host: "[Name] has arrived"
                         │
                         ▼
                   Badge PDF available for print
```

---

## 10. Non-Functional Requirements

| Category | Requirement | Implementation Guidance |
|---|---|---|
| Performance | Dashboard live count query < 1 second | Composite index on `(status, expected_date)` in vsm_visits |
| Performance | QR scan check-in response < 2 seconds end-to-end | gate pass lookup by indexed pass_token (VARCHAR UNIQUE) |
| Security | Gate pass token must be UUID v4, never sequential IDs | `Str::uuid()` in VisitorService |
| Security | Gate pass tokens expire strictly by TIMESTAMP — server-side only, not client-enforced | Compare expires_at against NOW() in DB query |
| Security | Visitor ID proof images not publicly accessible | Store on private disk; serve via signed URL or controller stream |
| Concurrency | Check-in must use DB transaction + SELECT FOR UPDATE to prevent duplicate check-in race | `DB::transaction()` + model lock in VisitorService::processCheckin() |
| Availability | Emergency broadcast must succeed even under load | Dedicated queue channel; bypass rate limiting for emergency job |
| Audit | All check-in, check-out, blacklist-hit, and emergency events logged in sys_activity_logs | AuditTrait on Visit and EmergencyEvent models |
| Privacy | Visitor photos and ID proofs governed by data retention policy | 90-day retention by default; configurable via sys_school_settings |
| HTTPS | Live photo capture via webcam requires getUserMedia API — HTTPS mandatory | Enforce HTTPS in production; fallback to file upload on HTTP |
| Timezone | Overdue scheduler must compute times in school's configured timezone | Use school timezone from sys_school_settings; Carbon::setTimezone() |
| QR Codes | Generated via SimpleSoftwareIO/simple-qrcode; embedded as hosted URL in SMS | URL format: `/visitor-security/gate-passes/{pass_token}/scan` |
| Badge Printing | DomPDF PDF badge; browser print() triggered automatically | Badge includes: photo, name, purpose, host, check-in time, valid until |
| Mobile-Friendliness | Gate check-in screen must be usable on tablet (guard kiosk) | Responsive layout; large touch targets; camera access via HTML5 |
| Scalability | Emergency SMS bulk dispatch respects gateway rate limits | Batch via queue; use Notification module's existing SMS queue channel |

---

## 11. Module Dependencies

| Module | Direction | Integration Detail |
|---|---|---|
| NTF — Notification | Outbound | Host arrival alerts, emergency broadcasts, overdue alerts, QR pass dispatch (SMS + in-app) |
| ATT — Attendance | Inbound (Read) | Emergency headcount queries today's present students from attendance module |
| STD — Student Profile | Inbound (Read) | Pickup authorisation reads std_student guardian list for verification |
| SCH — School Setup | Inbound (Read) | School timezone, academic term dates from sys_school_settings |
| SYS — Media (sys_media) | Outbound (Write) | Visitor photos, ID proof scans, checkpoint QR images, SOP documents |
| SYS — Users (sys_users) | Inbound (Read) | Guard assignments, host staff lookups, emergency broadcast recipient list |
| COM — Communication | Optional | Parent portal pre-registration can link to guardian profiles |
| PPT — Parent Portal | Optional (Read) | Parents pre-registered for PTM visits linked to guardian profile |
| BIL — Billing | None | No billing integration required |
| LXP | None | No LXP integration required |

### 11.1 Dependency Diagram

```
VSM ──outbound──► NTF (notifications)
VSM ──outbound──► sys_media (photos)
VSM ──inbound───  ATT (attendance data for headcount)
VSM ──inbound───  STD (guardian list for pickup auth)
VSM ──inbound───  SCH (school timezone/settings)
VSM ──inbound───  sys_users (staff list, guards)
VSM ──optional──  PPT (parent pre-reg for PTM)
```

---

## 12. Test Scenarios

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| T01 | VisitorRegistrationTest | Feature | Walk-in registration stores visitor + visit; photo uploaded to sys_media; blacklist check runs | Critical |
| T02 | BlacklistBlockTest | Feature | Visitor with blacklisted mobile_no → registration blocked; blacklist_hit=1 logged | Critical |
| T03 | PreRegistrationQrTest | Feature | Pre-register stores visit (Pre_Registered); QR token generated; SMS notification dispatched | Critical |
| T04 | GateCheckinTest | Feature | QR scan → checkin_time set; status=Checked_In; gate pass status=Used; host notified | Critical |
| T05 | DuplicateCheckinBlockTest | Feature | Second check-in attempt for already-checked-in visitor → 422 error without override | Critical |
| T06 | GateCheckoutTest | Feature | Checkout scan → checkout_time set; duration_minutes calculated; status=Checked_Out | High |
| T07 | OverdueFlaggingTest | Feature | Visitor not checked out after expected duration → scheduler sets is_overdue=1 | High |
| T08 | EmergencyBroadcastTest | Feature | Broadcast dispatched; vsm_emergency_events created; notification_count updated | High |
| T09 | LockdownModeTest | Feature | is_lockdown_active=true → gate pass generation returns 403; check-in screen shows banner | High |
| T10 | StudentPickupAuthTest | Feature | Authorised guardian matched → pickup logged is_authorised=1; unmatched → override required | High |
| T11 | ContractorAccessTest | Feature | Contractor pass valid within date range; expired after access_until; blocked on revoked | High |
| T12 | PatrolRoundTest | Feature | Checkpoint scan sequence → completion % recalculated; < 80% → status=Incomplete | Medium |
| T13 | GuardClockInTest | Feature | Clock-in 20 min late → attendance_status=Late auto-set | Medium |
| T14 | BlacklistExpiryTest | Unit | Blacklist entry with valid_until < today → is_active=0 after scheduler runs | Medium |
| T15 | GatePassExpiryTest | Unit | Gate pass expires_at < NOW → validate returns status=Expired, blocks check-in | High |
| T16 | RepeatVisitorTest | Feature | Second registration with same mobile_no → existing vsm_visitors record matched; visit_count incremented on check-in | Medium |
| T17 | ContractorEntryDayBlockTest | Feature | Contractor entry on day not in entry_days_json → check-in rejected | Medium |
| T18 | CctvWebhookTest | Feature | POST /api/v1/vsm/cctv/event → vsm_cctv_events record created; linked to active visit if gate camera | Low |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Gate Pass | Time-limited QR-encoded token issued to a visitor or contractor for campus entry |
| Pass Token | UUID v4 string encoded in the gate pass QR code; single-use for visitor passes |
| Pre-Registration | Host staff registers a visitor in advance; visitor receives QR before arriving |
| Walk-in | Unannounced visitor registered at reception on arrival |
| Check-in | Gate scan recording visitor entry time (checkin_time) |
| Check-out | Gate scan recording visitor exit time (checkout_time) |
| Overdue | Visitor whose expected duration has elapsed without check-out |
| Blacklist | List of persons blocked from campus entry |
| Blacklist Hit | A registration attempt that matched a blacklist entry |
| Pickup Auth | Guardian verification before releasing a student |
| Contractor | External vendor/service provider with time-bound multi-day campus access |
| Patrol Round | A guard's systematic visit to all campus checkpoints; logged by QR scan |
| Checkpoint | Physical campus location with a QR code for patrol round logging |
| Emergency Event | Formal incident triggering broadcast alert and lockdown/evacuation protocol |
| Lockdown | Emergency state blocking new gate pass generation and visitor entry |
| Headcount | Emergency roll-call: class teachers report student safety status per section |
| Host | Staff member being visited; receives notification on visitor arrival |
| Guard Shift | Scheduled duty period for a security guard at a defined post |
| CCTV Hook | Webhook endpoint receiving camera trigger events from external CCTV systems |
| Repeat Visitor | Visitor with visit_count > 0; previous details auto-filled on re-registration |

---

## 14. Suggestions & Improvements

### 14.1 High-Priority Enhancements

| ID | Suggestion | Rationale | Effort |
|---|---|---|---|
| SUG-VSM-01 | WhatsApp delivery for QR gate pass | Most Indian parents/visitors use WhatsApp; higher delivery rate than SMS | Medium — Notification module must support WhatsApp channel |
| SUG-VSM-02 | Kiosk self-check-in screen | Visitors scan their own QR on arrival at unmanned kiosk; reduces reception workload | Medium — full-screen kiosk Blade view, no auth required for public scan endpoint |
| SUG-VSM-03 | OTP-based visitor identity verification | Visitor receives OTP on pre-registered mobile; must enter OTP at gate to check in | Medium — adds fraud prevention for pre-registered passes |
| SUG-VSM-04 | Visitor invitation portal (public URL) | Host sends a public pre-registration link to visitor; visitor fills own details | Medium — unauthenticated form stores pending pre-registration for host approval |
| SUG-VSM-05 | Bulk PTM pre-registration | Admin uploads CSV of expected parents for PTM day; bulk QR generation and SMS dispatch | Medium — batch processing service |

### 14.2 Medium-Priority Enhancements

| ID | Suggestion | Rationale | Effort |
|---|---|---|---|
| SUG-VSM-06 | Multi-gate support | Schools with multiple gates need per-gate visit logs and guard assignment | Low — gate_assigned column already in vsm_visits; enhance with vsm_gates master table |
| SUG-VSM-07 | Expected vs. actual visit analytics | Track purpose accuracy, average duration by purpose, peak arrival hours | Low — computed from existing vsm_visits data |
| SUG-VSM-08 | Parent portal integration for PTM booking | Parents book PTM slots via Parent Portal; appointment auto-creates pre-registration | High effort — requires PPT module |
| SUG-VSM-09 | Digital visitor signature on check-in | Visitor signs on touchscreen at reception; stored as sys_media | Low — canvas signature capture in JS |
| SUG-VSM-10 | RFID / NFC card support for frequent visitors | Issue proximity card to regular visitors (contractors, frequent staff visitors) | High — hardware dependency |

### 14.3 Design Decisions (Open)

| Decision | Options | Recommendation |
|---|---|---|
| Gate pass QR delivery | SMS only / SMS+email / WhatsApp | SMS + email (V2); WhatsApp channel via Notification module in V3 |
| Badge printing | DomPDF PDF + browser print vs thermal printer ZPL | DomPDF PDF (hardware-agnostic); thermal ZPL in V3 |
| Live dashboard refresh | Polling 60s vs Server-Sent Events (SSE) | Start with polling; SSE upgrade when scale demands |
| Emergency headcount | In-app task to teachers vs dedicated headcount screen | Dedicated headcount screen with per-section teacher response collection |
| Visitor self-service kiosk | Guarded login vs public scan endpoint | Public scan endpoint for QR-only; no guest account needed |

---

## 15. Appendices

### 15.1 FormRequest Validation Rules

| FormRequest | Key Rules |
|---|---|
| StoreVisitorRequest | name: required, max:150; mobile_no: required, digits_between:10,15; id_type: nullable, in:Aadhar,DrivingLicense,Passport,VoterID,Other; photo: nullable, image, max:2048 |
| PreRegisterVisitRequest | visitor_name: required; visitor_mobile: required; purpose: required, in:PTM,...; host_staff_id: required, exists:sys_users,id; expected_date: required, date, after_or_equal:today; expected_time: nullable, date_format:H:i |
| ProcessCheckinRequest | pass_token: required_without:visit_id, max:100; visit_id: required_without:pass_token, exists:vsm_visits,id |
| ProcessCheckoutRequest | visit_id: required, exists:vsm_visits,id (scoped to status=Checked_In) |
| StoreGuardShiftRequest | guard_user_id: required, exists:sys_users,id; shift_date: required, date; shift_start_time: required, date_format:H:i; shift_end_time: required, date_format:H:i, after:shift_start_time |
| BroadcastEmergencyRequest | emergency_type: required, in:Lockdown,Fire,Earthquake,MedicalEmergency,Evacuation,Other; message: required, max:500 |
| StoreBlacklistRequest | name: required, max:150; reason: required, max:1000; mobile_no: nullable, digits_between:10,15 |
| StoreContractorRequest | contractor_name: required, max:150; mobile_no: required; access_from: required, date; access_until: required, date, after_or_equal:access_from; allowed_zones_json: nullable, json |
| ProcessPickupRequest | student_id: required, exists:std_students,id; guardian_name: required; guardian_mobile: required; relationship: nullable, max:50 |
| StorePatrolCheckpointRequest | name: required, max:100; sequence_order: nullable, integer, min:0 |

### 15.2 Permission Slugs

| Permission Slug | Assigned Roles |
|---|---|
| tenant.vsm-visitor.view | Admin, Principal, Reception, Guard |
| tenant.vsm-visitor.create | Admin, Reception |
| tenant.vsm-visitor.pre-register | Admin, Principal, Reception, Teacher, Staff |
| tenant.vsm-visitor.update | Admin, Reception |
| tenant.vsm-visitor.delete | Admin |
| tenant.vsm-visit.checkin | Admin, Reception, Guard |
| tenant.vsm-visit.checkout | Admin, Reception, Guard |
| tenant.vsm-visit.view | Admin, Principal, Reception, Guard |
| tenant.vsm-contractor.view | Admin, Reception |
| tenant.vsm-contractor.manage | Admin |
| tenant.vsm-blacklist.manage | Admin, Principal |
| tenant.vsm-guard-shift.manage | Admin |
| tenant.vsm-guard-shift.self | Guard (own shift clock-in/out) |
| tenant.vsm-patrol.manage | Admin, Guard |
| tenant.vsm-emergency.view | Admin, Principal, Reception, Guard |
| tenant.vsm-emergency.broadcast | Admin, Principal |
| tenant.vsm-report.view | Admin, Principal |

### 15.3 Scheduled Jobs

| Job | Schedule | Description |
|---|---|---|
| FlagOverdueVisitorsJob | Every 15 minutes | Set is_overdue=1 on checked-in visits beyond expected duration; dispatch in-app alert |
| ExpireGatePassesJob | Every 1 hour | Set status=Expired on vsm_gate_passes where expires_at < NOW() |
| ExpireBlacklistEntriesJob | Daily at midnight | Set is_active=0 on vsm_blacklist where valid_until < TODAY() |
| ExpireContractorPassesJob | Daily at midnight | Set pass_status=Expired on vsm_contractors where access_until < TODAY() |

### 15.4 RBS Module Mapping

| RBS Code | RBS Description | VSM FR |
|---|---|---|
| F.X1.1 / T.X1.1.1 | Visitor Pre-Registration | FR-VSM-01 |
| T.X1.1.2 / ST.X1.1.2.1–2 | Walk-in Visitor Registration | FR-VSM-02 |
| T.X2.1.1 / ST.X2.1.1.1–2 | Gate Check-in | FR-VSM-03 |
| T.X2.1.2 / ST.X2.1.2.1–2 | Gate Check-out + Overdue | FR-VSM-04 |
| F.X3.1 / T.X3.1.1 / ST.X3.1.1.1–2 | Real-time Campus Dashboard | FR-VSM-05 |
| F.X3.2 / T.X3.2.1 / ST.X3.2.1.1–2 | Emergency Alert + Headcount | FR-VSM-06 |
| BR-M-002 (RBS Spec) | Student Pickup by Guardian | FR-VSM-07 |
| M1 (FRO module — RBS) | Visitor Management | FR-VSM-01..04, FR-VSM-09 |
| M4 (FRO module — RBS) | Gate Pass | FR-VSM-03 |
| V2 Enhancement | Contractor Access | FR-VSM-08 |
| V2 Enhancement | Repeat Visitor Detection | FR-VSM-12 |
| V2 Enhancement | CCTV Integration Hooks | FR-VSM-13 |

---

## 16. V1 → V2 Delta

### 16.1 New Features Added in V2

| Feature | Reason |
|---|---|
| FR-VSM-07: Student Pickup Authorisation | Critical safety requirement from RBS BR-M-002; guardian verification missing in V1 |
| FR-VSM-08: Contractor & Vendor Access Management | Contractors need multi-day reusable passes distinct from single-visit passes |
| FR-VSM-12: Repeat Visitor Detection | UX improvement; returning visitors should not require full re-registration |
| FR-VSM-13: CCTV Integration Hooks | Future-proof webhook layer for CCTV hardware integrations; low-code hook, hardware out of scope |
| FR-VSM-14: Visitor Log Reports (expanded) | Added Frequent Visitors, Blacklist Hits, and Contractor Access Log reports |

### 16.2 New Tables Added in V2

| Table | Reason |
|---|---|
| `vsm_contractors` | Contractor/vendor access management is a distinct entity from one-visit visitors |
| `vsm_pickup_auth` | Student pickup authorisation needs a separate log linked to std_students |
| `vsm_cctv_events` | Webhook ingestion for CCTV events requires a dedicated table |
| `vsm_emergency_events.is_lockdown_active` | New column; V1 had no lockdown-mode gate blocking mechanism |

### 16.3 Schema Changes from V1 to V2

| Table | Column | Change | Reason |
|---|---|---|---|
| vsm_visits | purpose ENUM | Added 'StudentPickup', 'Contractor' values | New pickup + contractor flows |
| vsm_visits | gate_assigned | NEW column VARCHAR(50) | Multi-gate support |
| vsm_patrol_rounds | status | Added ENUM column | V1 had no explicit round status; needed for Incomplete flagging |
| All tables | id: INT → BIGINT UNSIGNED | Type widened | Consistency with platform standard |
| vsm_emergency_events | is_lockdown_active | NEW column TINYINT(1) | Lockdown mode feature |
| vsm_emergency_events | notification_count | NEW column | Track delivery success |
| vsm_emergency_events | headcount_initiated | NEW column | Track headcount dispatch |

### 16.4 Counts Comparison

| Metric | V1 | V2 | Delta |
|---|---|---|---|
| DB Tables | 9 | 13 | +4 |
| Named Web Routes | ~55 | ~55 | +0 |
| Named API Routes | 5 | 12 | +7 |
| Controllers | 7 | 8 | +1 (ContractorController) |
| Services | 3 | 4 | +1 (ContractorAccessService) |
| Models | 9 | 13 | +4 |
| Functional Requirements | 8 | 14 | +6 |
| Test Scenarios | 10 | 18 | +8 |
| FormRequests | 7 | 10 | +3 |

### 16.5 V1 Items Retained Unchanged

All V1 functional requirements (FR-VSM-01 through FR-VSM-11 original numbering) are carried forward in V2 with equivalent or expanded coverage. No V1 features were removed.

---

*RBS Reference: Module X — Visitor & Security Management (ST.X1.1.1.1 – ST.X3.2.1.2) + Module M (FRO) Visitor Management*
*Document generated: 2026-03-26 | Version: 2.0 | Status: Draft | Mode: RBS_ONLY (Greenfield)*
