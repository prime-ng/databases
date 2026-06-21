# VSM — Visitor & Security Management Feature Specification
**Module:** VisitorSecurity | **Version:** v2 | **Generated:** 2026-03-27
**Based on:** VSM_VisitorSecurity_Requirement.md v2

---

## Section 1 — Module Identity & Scope

| Attribute | Value |
|---|---|
| Module Code | VSM |
| Module Name | Visitor & Security Management |
| Laravel Namespace | `Modules\VisitorSecurity` |
| Laravel Module Path | `Modules/VisitorSecurity/` |
| Route Prefix | `visitor-security/` |
| Route Name Prefix | `vsm.` |
| DB Table Prefix | `vsm_` |
| Database | `tenant_db` (per-tenant isolated; **no `tenant_id` columns**) |
| Module Type | Greenfield (0% implemented) |
| RBS Code | Module X (RBS Spec v2) |
| Menu Path | School Admin → Visitor & Security |

### 1.1 In-Scope Features

**Visitor Management:**
- Pre-registration by host staff → QR gate pass dispatched via SMS/email before arrival
- Walk-in registration at reception: photo + ID proof captured to sys_media
- Repeat visitor detection: match by mobile_no → auto-fill + "Returning visitor" badge
- Blacklist enforcement: match mobile_no OR id_number on every registration → block + alert
- Student pickup authorisation: verified against std_student_guardian_jnt.can_pickup; unauthorised requires supervisor override

**Gate Operations:**
- QR scan check-in: decode pass_token → validate → set checkin_time → notify host
- QR scan check-out: record checkout_time, calculate duration_minutes
- Overdue flagging: FlagOverdueVisitorsJob every 15 min flags checkin_time + expected_duration_minutes < NOW()
- Printable DomPDF visitor badge: photo, name, purpose, host, valid until

**Contractor Access Management:**
- Multi-day contractor access: work order, allowed zones (JSON), date range, per-day restrictions
- Reusable pass_token (UUID v4) valid within access_from..access_until + entry_days_json
- Auto-expiry by ExpireContractorPassesJob daily

**Guard Management:**
- Guard shift scheduling: UNIQUE(guard_user_id, shift_date, shift_start_time) prevents overlap
- Clock-in/out attendance: auto-sets Late / Early_Departure per BR-VSM-007
- Patrol rounds: guard scans checkpoint QR codes → completion% = (scanned/total)×100; < 80% → Incomplete

**Emergency System:**
- One-click broadcast: SMS + in-app push to ALL active sys_users via dedicated queue channel
- Lockdown mode: is_lockdown_active=true blocks gate pass generation; check-in shows banner
- Emergency headcount: query ATT module; dispatch per-section task to class teachers

**Dashboard:**
- Live campus occupancy (status=Checked_In count)
- Overdue alerts (is_overdue=1 count + list)
- Recent check-ins (last 5), today's total, pending pre-registrations
- Auto-refresh every 60 seconds (AJAX polling; SSE upgrade when scale demands)
- Lockdown banner when is_lockdown_active=true on any active vsm_emergency_events

**Reports (FR-VSM-14):**
- Daily Visitor Log, Frequent Visitors, Overdue Incidents, Guard Attendance, Blacklist Hits, Contractor Access Log
- PDF (DomPDF) and CSV (fputcsv) exports

**CCTV Hooks (FR-VSM-13 — webhook ingestion ONLY):**
- POST webhook endpoint receives camera events; creates vsm_cctv_events records
- Hardware integration is OUT OF SCOPE; only ingestion layer provided

### 1.2 Out-of-Scope
- Student attendance marking → STD module
- Student profile management → STD module
- HR payroll for guards → HRS module
- CCTV hardware integration (only webhook ingestion in scope)
- Parent portal pre-registration → PPT module (optional future integration)

### 1.3 Module Scale

| Artifact | Count |
|---|---|
| vsm_* Tables | 13 |
| Controllers | 8 web + 1 API + 1 Report = 10 |
| Services | 4 |
| Models | 13 |
| Blade Views | ~32 |
| FormRequests | 10 |
| Policy Classes | 8 |
| Scheduled Jobs | 4 |
| Web Routes | ~70 |
| API Routes | 12 |

---

## Section 2 — Entity Inventory (All 13 Tables)

### 2.1 Visitor Core

---

#### `vsm_visitors` — Master Visitor Profile
One row per unique visitor (matched by mobile_no). Upserted on every new registration.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(150) | NO | | | Full visitor name |
| mobile_no | VARCHAR(20) | NO | | INDEX | Primary match key; used for blacklist check |
| email | VARCHAR(100) | YES | NULL | | Optional email for QR dispatch |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | YES | NULL | | Government ID type |
| id_number | VARCHAR(50) | YES | NULL | INDEX | Secondary blacklist match key |
| company_name | VARCHAR(150) | YES | NULL | | Employer/organisation |
| photo_media_id | INT UNSIGNED | YES | NULL | FK→sys_media.id | Visitor photo (private disk) |
| id_proof_media_id | INT UNSIGNED | YES | NULL | FK→sys_media.id | ID proof scan (private disk) |
| visit_count | INT UNSIGNED | NO | 0 | | Denormalised; incremented on each check-in (BR-VSM-013) |
| is_blacklisted | TINYINT(1) | NO | 0 | | Cache flag; updated when blacklist match found |
| is_active | TINYINT(1) | NO | 1 | | Soft enable/disable |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | Soft delete |

**Indexes:** `KEY idx_vsm_vis_mobile (mobile_no)`, `KEY idx_vsm_vis_id_number (id_number)`
**Cross-module FKs:** `photo_media_id → sys_media.id (INT UNSIGNED)`, `id_proof_media_id → sys_media.id`
**Note:** `photo_media_id` and `id_proof_media_id` use `INT UNSIGNED` to match actual `sys_media.id` type in tenant_db.

---

#### `vsm_visits` — Per-Visit Record (Status FSM)
One row per visit attempt. Tracks the full visit lifecycle from registration to check-out.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| visit_number | VARCHAR(30) | NO | | UNIQUE | Format: VSM-YYYYMMDD-XXXX; generated in VisitorService |
| visitor_id | BIGINT UNSIGNED | NO | | FK→vsm_visitors.id, INDEX | |
| host_user_id | INT UNSIGNED | YES | NULL | FK→sys_users.id, INDEX | Staff being visited; NULL for walk-in deliveries |
| purpose | ENUM('PTM','Admission','Meeting','Delivery','Maintenance','Interview','StudentPickup','Contractor','Other') | NO | | | |
| purpose_detail | VARCHAR(255) | YES | NULL | | Free-text detail |
| expected_date | DATE | NO | | INDEX (composite with status) | |
| expected_time | TIME | YES | NULL | | Expected arrival time |
| expected_duration_minutes | SMALLINT UNSIGNED | NO | 60 | | Used by overdue scheduler (BR-VSM-004) |
| vehicle_number | VARCHAR(20) | YES | NULL | | |
| gate_assigned | VARCHAR(50) | YES | NULL | | Main Gate / Back Gate etc. |
| checkin_time | TIMESTAMP | YES | NULL | INDEX | Set on QR scan check-in |
| checkin_photo_media_id | INT UNSIGNED | YES | NULL | FK→sys_media.id | Gate photo captured at check-in |
| checkout_time | TIMESTAMP | YES | NULL | | Set on check-out |
| duration_minutes | SMALLINT UNSIGNED | YES | NULL | | Computed: (checkout_time - checkin_time) in minutes |
| status | ENUM('Pre_Registered','Registered','Checked_In','Checked_Out','No_Show','Cancelled') | NO | 'Registered' | | Visit lifecycle state |
| is_overdue | TINYINT(1) | NO | 0 | | **Set by FlagOverdueVisitorsJob every 15 min**; cleared on check-out |
| blacklist_hit | TINYINT(1) | NO | 0 | | **Set at registration** if blacklist match found (BR-VSM-001) |
| notes | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE KEY uq_vsm_visit_number (visit_number)`
**Indexes:** `KEY idx_vsm_vst_date_status (expected_date, status)`, `KEY idx_vsm_vst_visitor (visitor_id)`, `KEY idx_vsm_vst_host (host_user_id)`, `KEY idx_vsm_vst_checkin (checkin_time)`

**Status Values:**
| Status | Meaning | Transitions From |
|---|---|---|
| Pre_Registered | Host pre-registered; visitor not yet arrived | — (initial state for pre-reg) |
| Registered | Walk-in registered at reception | — (initial state for walk-in) |
| Checked_In | QR scanned; visitor on campus | Pre_Registered, Registered |
| Checked_Out | Exit recorded; duration computed | Checked_In |
| No_Show | Expected_date passed without check-in | Pre_Registered (by NoShowJob) |
| Cancelled | Cancelled by host or admin | Pre_Registered, Registered |

---

#### `vsm_gate_passes` — QR Gate Pass Token
One row per visit (1:1 with vsm_visits). UUID v4 pass_token encoded in QR code.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| visit_id | BIGINT UNSIGNED | NO | | UNIQUE FK→vsm_visits.id | One pass per visit (BR-VSM-002) |
| visitor_id | BIGINT UNSIGNED | NO | | FK→vsm_visitors.id, INDEX | Denorm for fast badge rendering |
| pass_token | VARCHAR(100) | NO | | UNIQUE | **UUID v4 — Str::uuid(); never sequential; lookup key at gate** |
| qr_code_path | VARCHAR(255) | YES | NULL | | Stored QR image path (SimpleSoftwareIO) |
| status | ENUM('Issued','Used','Expired','Revoked') | NO | 'Issued' | | |
| issued_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | | |
| expires_at | TIMESTAMP | NO | | | **MIN(end of expected_date, issued_at + 24h) — server-side only; never trust client (BR-VSM-002)** |
| used_at | TIMESTAMP | YES | NULL | | Set when QR scanned at gate |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE KEY uq_vsm_gp_visit (visit_id)` | `UNIQUE KEY uq_vsm_gp_token (pass_token)`
**Index:** `KEY idx_vsm_gp_expires (expires_at)`, `KEY idx_vsm_gp_visitor (visitor_id)`

**Status Values:**
| Status | Meaning |
|---|---|
| Issued | Pass generated; not yet used |
| Used | QR scanned at gate; visit=Checked_In |
| Expired | expires_at < NOW (set by ExpireGatePassesJob hourly) |
| Revoked | Admin revoked; cannot be used |

---

### 2.2 Access Control

---

#### `vsm_contractors` — Multi-Day Contractor Access
Standalone table. Contractor gets a reusable pass_token valid within date range + allowed days.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| contractor_name | VARCHAR(150) | NO | | | |
| company_name | VARCHAR(150) | YES | NULL | | |
| mobile_no | VARCHAR(20) | NO | | INDEX | Also checked against blacklist |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | YES | NULL | | |
| id_number | VARCHAR(50) | YES | NULL | | |
| photo_media_id | INT UNSIGNED | YES | NULL | FK→sys_media.id | |
| work_order_no | VARCHAR(100) | YES | NULL | | |
| work_description | TEXT | YES | NULL | | |
| allowed_zones_json | JSON | YES | NULL | | **Array of zone name strings; e.g. ["Lab Block","Admin Block"]** |
| access_from | DATE | NO | | INDEX (composite) | |
| access_until | DATE | NO | | | Auto-expired by daily job |
| entry_days_json | JSON | YES | NULL | | **e.g. ["Mon","Tue","Wed","Thu","Fri"] — BR-VSM-012** |
| pass_token | VARCHAR(100) | NO | | UNIQUE | **UUID v4; reusable within date range; different from visitor single-use** |
| pass_status | ENUM('Active','Expired','Revoked') | NO | 'Active' | INDEX | |
| entry_count | INT UNSIGNED | NO | 0 | | Incremented at application layer on each entry |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE KEY uq_vsm_con_token (pass_token)`
**Indexes:** `KEY idx_vsm_con_mobile (mobile_no)`, `KEY idx_vsm_con_access (access_from, access_until)`, `KEY idx_vsm_con_status (pass_status)`

---

#### `vsm_pickup_auth` — Student Pickup Authorisation Log
One row per pickup event. Linked to both vsm_visits and std_students.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| visit_id | BIGINT UNSIGNED | NO | | FK→vsm_visits.id, INDEX | The visit record for this pickup |
| student_id | INT UNSIGNED | NO | | FK→std_students.id, INDEX | Student being picked up |
| guardian_name | VARCHAR(150) | NO | | | Person at gate |
| guardian_mobile | VARCHAR(20) | NO | | | |
| relationship | VARCHAR(50) | YES | NULL | | Father/Mother/Uncle etc. |
| is_authorised | TINYINT(1) | NO | | NOT NULL | **1 = guardian found in std_student_guardian_jnt.can_pickup=1; 0 = override required** |
| id_proof_media_id | INT UNSIGNED | YES | NULL | FK→sys_media.id | Guardian ID proof |
| override_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | **Supervisor who overrode unauthorised pickup (BR-VSM-011)** |
| override_reason | TEXT | YES | NULL | | Required when override_by is set |
| processed_by | INT UNSIGNED | NO | | FK→sys_users.id | Reception staff who processed |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `KEY idx_vsm_pa_student (student_id)`, `KEY idx_vsm_pa_visit (visit_id)`
**Cross-module:** `student_id → std_students.id (INT UNSIGNED)`; verifies `std_student_guardian_jnt.can_pickup = 1`

---

#### `vsm_blacklist` — Blacklisted Persons
Checked on every visitor registration. Match by mobile_no OR id_number blocks entry.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(150) | NO | | | |
| mobile_no | VARCHAR(20) | YES | NULL | INDEX | **Primary match key** |
| id_type | ENUM('Aadhar','DrivingLicense','Passport','VoterID','Other') | YES | NULL | | |
| id_number | VARCHAR(50) | YES | NULL | INDEX | **Secondary match key** |
| photo_media_id | INT UNSIGNED | YES | NULL | FK→sys_media.id | |
| reason | TEXT | NO | | | Why blacklisted (shown to reception on block) |
| blacklisted_by | INT UNSIGNED | NO | | FK→sys_users.id, INDEX | Admin who added |
| valid_until | DATE | YES | NULL | | **NULL = permanent blacklist; if not NULL and < TODAY → auto-expired by daily job (BR-VSM-014)** |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `KEY idx_vsm_bl_mobile (mobile_no)`, `KEY idx_vsm_bl_id_number (id_number)`, `KEY idx_vsm_bl_by (blacklisted_by)`

---

### 2.3 Guard Operations

---

#### `vsm_guard_shifts` — Guard Shift Schedules + Attendance

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| guard_user_id | INT UNSIGNED | NO | | FK→sys_users.id, INDEX | Must be user with Guard role |
| shift_date | DATE | NO | | | |
| shift_start_time | TIME | NO | | | |
| shift_end_time | TIME | NO | | | |
| post | VARCHAR(100) | NO | | | Main Gate / Back Gate / Block Patrol etc. |
| actual_start_time | TIMESTAMP | YES | NULL | | Clock-in time recorded by guard |
| actual_end_time | TIMESTAMP | YES | NULL | | Clock-out time recorded by guard |
| attendance_status | ENUM('Scheduled','Present','Absent','Late','Early_Departure') | NO | 'Scheduled' | | Auto-set per BR-VSM-007 |
| notes | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE KEY uq_vsm_gs_guard_shift (guard_user_id, shift_date, shift_start_time)` — prevents duplicate shift for same guard
**Index:** `KEY idx_vsm_gs_guard (guard_user_id)`

---

#### `vsm_patrol_checkpoints` — Campus Checkpoint Definitions
Admin-defined physical locations with QR codes placed at each location.

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(100) | NO | | | e.g., Lab Block Entrance |
| location_description | TEXT | YES | NULL | | |
| building | VARCHAR(100) | YES | NULL | | |
| floor | VARCHAR(20) | YES | NULL | | |
| sequence_order | TINYINT UNSIGNED | NO | 0 | | Patrol route order |
| qr_token | VARCHAR(100) | NO | | UNIQUE | **UUID v4 QR placed at physical location; lookup key on guard scan** |
| qr_code_path | VARCHAR(255) | YES | NULL | | Generated QR image path |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE KEY uq_vsm_pc_qr_token (qr_token)`

---

#### `vsm_patrol_rounds` — Per-Patrol Summary

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| guard_user_id | INT UNSIGNED | NO | | FK→sys_users.id, INDEX | Guard conducting patrol |
| guard_shift_id | BIGINT UNSIGNED | YES | NULL | FK→vsm_guard_shifts.id, INDEX | Linked shift (optional) |
| patrol_start_time | TIMESTAMP | NO | | | |
| patrol_end_time | TIMESTAMP | YES | NULL | | Set when round completed |
| checkpoints_total | TINYINT UNSIGNED | NO | 0 | | Count of active checkpoints at round start |
| checkpoints_completed | TINYINT UNSIGNED | NO | 0 | | Incremented on each checkpoint scan |
| completion_pct | DECIMAL(5,2) | NO | 0.00 | | **(completed/total)×100 — computed at application layer; NOT a generated column** |
| status | ENUM('In_Progress','Completed','Incomplete') | NO | 'In_Progress' | | Incomplete if completion_pct < 80% (BR-VSM-006) |
| notes | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `KEY idx_vsm_pr_guard (guard_user_id)`, `KEY idx_vsm_pr_shift (guard_shift_id)`

---

#### `vsm_patrol_checkpoint_log` — Per-Checkpoint Scan Within a Round
**IMMUTABLE scan record — no updated_at, no deleted_at (audit rule exception).**

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| patrol_round_id | BIGINT UNSIGNED | NO | | FK→vsm_patrol_rounds.id, INDEX | |
| checkpoint_id | BIGINT UNSIGNED | NO | | FK→vsm_patrol_checkpoints.id, INDEX | |
| scanned_at | TIMESTAMP | NO | | | **Immutable scan timestamp** |
| notes | TEXT | YES | NULL | | |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | | |

**Indexes:** `KEY idx_vsm_pcl_round (patrol_round_id)`, `KEY idx_vsm_pcl_checkpoint (checkpoint_id)`
**Audit Exception:** No `is_active`, no `updated_at`, no `deleted_at`, no `created_by`, no `updated_by` — immutable guard scan log.

---

### 2.4 Emergency Management

---

#### `vsm_emergency_protocols` — SOP Templates Per Emergency Type

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| protocol_type | ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other') | NO | | INDEX | |
| title | VARCHAR(200) | NO | | | e.g., Campus Lockdown Protocol |
| description | TEXT | NO | | | Step-by-step SOP |
| responsible_roles_json | JSON | YES | NULL | | **Array of role strings: ["Admin","Principal","Guard"]** |
| media_ids_json | JSON | YES | NULL | | sys_media IDs (evacuation maps, SOP PDFs) |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Index:** `KEY idx_vsm_ep_type (protocol_type)`

---

#### `vsm_emergency_events` — Active Emergency Events Log

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| emergency_type | ENUM('Fire','Earthquake','Lockdown','MedicalEmergency','Evacuation','Other') | NO | | | |
| protocol_id | BIGINT UNSIGNED | YES | NULL | FK→vsm_emergency_protocols.id, INDEX | Optional linked SOP |
| message | TEXT | NO | | | Broadcast message |
| affected_zones | VARCHAR(500) | YES | NULL | | |
| triggered_by | INT UNSIGNED | NO | | FK→sys_users.id, INDEX | Admin/Principal who triggered |
| triggered_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | | **Immutable; NOT NULL DEFAULT CURRENT_TIMESTAMP** |
| resolved_at | TIMESTAMP | YES | NULL | | Set by admin on resolution |
| is_lockdown_active | TINYINT(1) | NO | 0 | INDEX | **When 1: gate pass generation DISABLED; check-in blocked; shows LOCKDOWN banner (BR-VSM-010)** |
| notification_count | INT UNSIGNED | NO | 0 | | Count of staff notified |
| headcount_initiated | TINYINT(1) | NO | 0 | | 1 when ATT headcount dispatched |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| updated_by | INT UNSIGNED | YES | NULL | FK→sys_users.id | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `KEY idx_vsm_ee_lockdown (is_lockdown_active)`, `KEY idx_vsm_ee_triggered (triggered_at)`, `KEY idx_vsm_ee_protocol (protocol_id)`, `KEY idx_vsm_ee_by (triggered_by)`

---

### 2.5 CCTV Integration

---

#### `vsm_cctv_events` — Inbound Webhook Events From CCTV Systems
**IMMUTABLE webhook event log — no updated_at, no deleted_at.**

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| camera_id | VARCHAR(100) | NO | | INDEX (composite) | External camera identifier from CCTV system |
| event_type | VARCHAR(100) | NO | | | e.g., motion_detected, gate_open |
| event_timestamp | TIMESTAMP | NO | | | Timestamp from CCTV system |
| snapshot_url | VARCHAR(500) | YES | NULL | | External URL from CCTV system |
| linked_visit_id | BIGINT UNSIGNED | YES | NULL | FK→vsm_visits.id, INDEX | Auto-linked if gate camera + active visit within check-in window |
| raw_payload_json | JSON | YES | NULL | | Full webhook payload stored for audit |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | | |

**Indexes:** `KEY idx_vsm_ce_camera_time (camera_id, event_timestamp)`, `KEY idx_vsm_ce_visit (linked_visit_id)`
**Audit Exception:** No `is_active`, no `updated_at`, no `deleted_at`, no `created_by`, no `updated_by` — immutable webhook event record.

---

### 2.6 Audit Column Exceptions (DDL Rule 2)

| Table | Missing Columns | Reason |
|---|---|---|
| `vsm_patrol_checkpoint_log` | `is_active`, `updated_at`, `deleted_at`, `created_by`, `updated_by` | Immutable guard scan log — once created, never updated or soft-deleted |
| `vsm_cctv_events` | `is_active`, `updated_at`, `deleted_at`, `created_by`, `updated_by` | Immutable webhook event record — system writes, never modified |

---

### 2.7 Schema Note — FK Type Discrepancy

DDL Rule 6 specifies `BIGINT UNSIGNED` for all IDs. However, the actual `tenant_db_v2.sql` defines `sys_users.id`, `sys_media.id`, `std_students.id`, and `std_guardians.id` as `INT UNSIGNED`. MySQL requires FK columns to match the referenced column type exactly.

**Resolution applied in DDL:**
- `vsm_*` table PKs: `BIGINT UNSIGNED` (per requirement v2 Section 5.1 and DDL Rule 6)
- FK columns pointing to other `vsm_*` tables: `BIGINT UNSIGNED`
- FK columns pointing to `sys_users.id`, `sys_media.id`, `std_students.id`: `INT UNSIGNED` (to match actual column types and prevent MySQL FK errors)

---

## Section 3 — Entity Relationship Diagram

```
VISITOR CORE
────────────
vsm_visitors ──1:N──► vsm_visits ──1:1──► vsm_gate_passes
    │                      │
    │              host_user_id ──────────────► sys_users
    │              checkin_photo_media_id ─────► sys_media
    │
    photo_media_id ────────────────────────────► sys_media
    id_proof_media_id ─────────────────────────► sys_media

ACCESS CONTROL
──────────────
vsm_visits ──1:N──► vsm_pickup_auth
                        │
                student_id ────────────────────► std_students
                                                    (verify via std_student_guardian_jnt.can_pickup=1)
                override_by ───────────────────► sys_users
                processed_by ──────────────────► sys_users

vsm_contractors  (standalone; own pass_token; checked against vsm_blacklist at registration)

vsm_blacklist  (checked against vsm_visitors.mobile_no / id_number on every registration)

GUARD OPERATIONS
────────────────
vsm_guard_shifts ──────────────────────────────► sys_users (guard_user_id)
        │
        └── vsm_patrol_rounds ──────────────────► sys_users (guard_user_id)
                    │
                    └──1:N──► vsm_patrol_checkpoint_log
                                        │
                              checkpoint_id ─────► vsm_patrol_checkpoints

EMERGENCY MANAGEMENT
────────────────────
vsm_emergency_protocols  (SOP templates — standalone)
        │
        └──(nullable)── vsm_emergency_events ───► sys_users (triggered_by)

CCTV INTEGRATION
────────────────
vsm_cctv_events ──(nullable)──► vsm_visits (linked_visit_id — auto-linked if gate camera)
```

**Cross-Module FK Summary:**

| Column | Table | References | Type |
|---|---|---|---|
| `host_user_id` | `vsm_visits` | `sys_users.id` | INT UNSIGNED |
| `checkin_photo_media_id` | `vsm_visits` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `vsm_visitors` | `sys_media.id` | INT UNSIGNED |
| `id_proof_media_id` | `vsm_visitors` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `vsm_contractors` | `sys_media.id` | INT UNSIGNED |
| `id_proof_media_id` | `vsm_pickup_auth` | `sys_media.id` | INT UNSIGNED |
| `photo_media_id` | `vsm_blacklist` | `sys_media.id` | INT UNSIGNED |
| `student_id` | `vsm_pickup_auth` | `std_students.id` | INT UNSIGNED |
| `override_by` | `vsm_pickup_auth` | `sys_users.id` | INT UNSIGNED |
| `processed_by` | `vsm_pickup_auth` | `sys_users.id` | INT UNSIGNED |
| `guard_user_id` | `vsm_guard_shifts` | `sys_users.id` | INT UNSIGNED |
| `guard_user_id` | `vsm_patrol_rounds` | `sys_users.id` | INT UNSIGNED |
| `triggered_by` | `vsm_emergency_events` | `sys_users.id` | INT UNSIGNED |
| `blacklisted_by` | `vsm_blacklist` | `sys_users.id` | INT UNSIGNED |
| `created_by` / `updated_by` | All tables | `sys_users.id` | INT UNSIGNED |

---

## Section 4 — Business Rules (15 Rules)

| Rule ID | Rule | Table/Column | Enforcement |
|---|---|---|---|
| BR-VSM-001 | Blacklist check mandatory on EVERY registration — match mobile_no OR id_number → block + alert reception | `vsm_visits.blacklist_hit` | `service_layer` (VisitorService::checkBlacklist) |
| BR-VSM-002 | Gate pass token = UUID v4; expires = MIN(end of expected_date, issued_at + 24h); server-side comparison only — never trust client | `vsm_gate_passes.pass_token, expires_at` | `service_layer` (VisitorService::generateGatePass) |
| BR-VSM-003 | Only one active (status=Checked_In) visit per visitor at a time; second check-in requires supervisor override + reason | `vsm_visits.status` | `service_layer` + `db_constraint` (DB::transaction + lockForUpdate) |
| BR-VSM-004 | Overdue flagging every 15 min: checkin_time + expected_duration_minutes < NOW() AND status=Checked_In → is_overdue=1 | `vsm_visits.is_overdue` | `scheduled_job` (FlagOverdueVisitorsJob) |
| BR-VSM-005 | Emergency broadcast dispatches to ALL active sys_users (staff + teachers) via SMS + in-app push simultaneously via dedicated queue channel | `vsm_emergency_events.notification_count` | `service_layer` (SecurityAlertService::broadcastEmergency → EmergencyBroadcastJob on 'emergency' queue) |
| BR-VSM-006 | Patrol completion = (checkpoints_completed / checkpoints_total) × 100; < 80% → status=Incomplete | `vsm_patrol_rounds.completion_pct, status` | `service_layer` (PatrolService::completeRound) |
| BR-VSM-007 | Guard attendance_status: Late if actual_start_time > shift_start_time + 15 min; Early_Departure if actual_end_time < shift_end_time - 15 min | `vsm_guard_shifts.attendance_status` | `service_layer` (GuardShiftController::clockIn/clockOut) |
| BR-VSM-008 | Host notification dispatched immediately on visitor check-in via NTF module (in-app + SMS if staff mobile set) | — | `service_layer` (VisitorService::processCheckin → NTF dispatch) |
| BR-VSM-009 | Visitor photos + ID proofs stored in sys_media with model_type='vsm_visitors', model_id=visitor.id; private disk; served via signed URL | `vsm_visitors.photo_media_id, id_proof_media_id` | `service_layer` + `form_validation` |
| BR-VSM-010 | When is_lockdown_active=true: gate pass generation disabled (403); check-in screen shows LOCKDOWN banner; walk-in registration requires admin override | `vsm_emergency_events.is_lockdown_active` | `service_layer` (SecurityAlertService::isLockdownActive check before gate pass generation) |
| BR-VSM-011 | Unauthorised student pickup (guardian not in std_student_guardian_jnt.can_pickup=1) requires supervisor override with override_reason + supervisor ID | `vsm_pickup_auth.is_authorised, override_by, override_reason` | `service_layer` (VisitorService::processPickupAuthorisation) |
| BR-VSM-012 | Contractor pass valid only within access_from..access_until AND only on days in entry_days_json | `vsm_contractors.entry_days_json, access_from, access_until` | `service_layer` (ContractorAccessService::validateEntry) |
| BR-VSM-013 | vsm_visitors.visit_count incremented on each confirmed check-in (status=Checked_In) via DB::increment | `vsm_visitors.visit_count` | `service_layer` (VisitorService::processCheckin Step 8) |
| BR-VSM-014 | Blacklist entries with valid_until < TODAY() auto-expired (is_active=0) by daily scheduler | `vsm_blacklist.valid_until, is_active` | `scheduled_job` (ExpireBlacklistEntriesJob) |
| BR-VSM-015 | All check-in, check-out, emergency broadcast, and blacklist-hit events written to sys_activity_logs | — | `service_layer` (AuditTrait / direct write in services) |

---

## Section 5 — Workflow State Machines (5 FSMs)

### FSM 1: Visitor Visit Lifecycle

```
                        ┌─────────────────────────────────────────────┐
                        │                                             │
                        ▼                                             │
  [Pre_Registered] ──(QR scan, valid)──► [Checked_In] ──(QR scan checkout)──► [Checked_Out]
         │                                    │
         │ (expected_date passed; no checkin)  │ (checkin_time + expected_duration < NOW)
         ▼                                    ▼
     [No_Show]                          is_overdue=true
                                             │
  [Registered] ──(QR scan, valid)──► [Checked_In] ──(manual checkout)──► [Checked_Out]
         │
         │ (admin/host cancels)
         ▼
     [Cancelled]
```

**Transition: → Checked_In**
- Pre-condition: status = Pre_Registered or Registered; pass status = Issued; expires_at > NOW; no other Checked_In visit for this visitor (BR-VSM-003)
- DB writes: `DB::transaction()` + `lockForUpdate()`; checkin_time=NOW(); status=Checked_In; pass status=Used; used_at=NOW(); visit_count++ (vsm_visitors via DB::increment)
- Side effects: optional gate photo → sys_media; host notification via NTF (in-app + SMS); badge PDF available; log to sys_activity_logs (BR-VSM-015)

**Transition: → Checked_Out**
- DB writes: checkout_time=NOW(); duration_minutes=(checkout_time - checkin_time) in minutes; status=Checked_Out; is_overdue=false (cleared)
- Side effects: log to sys_activity_logs

**Transition: → No_Show**
- Trigger: FlagOverdueVisitorsJob (or separate NoShowJob) when expected_date < TODAY and status=Pre_Registered
- Side effects: no notification (informational flag only)

---

### FSM 2: Gate Pass Status

```
  [Issued] ──(QR scanned at gate, all validations pass)──► [Used]
      │
      │ (expires_at < NOW — ExpireGatePassesJob hourly)
      ▼
  [Expired]

  [Issued] ──(admin revoke)──► [Revoked]
  [Expired] ──(admin revoke)──► [Revoked]
  Note: [Used] passes CANNOT be revoked; pass_token is single-use
```

**Validation on scan:**
1. pass_token exists in vsm_gate_passes (UNIQUE lookup — fast)
2. status = Issued (not Used, Expired, or Revoked)
3. expires_at > NOW() (server-side only — BR-VSM-002)
4. Linked vsm_visits.status NOT already Checked_In (BR-VSM-003)
5. SecurityAlertService::isLockdownActive() = false (BR-VSM-010)

---

### FSM 3: Emergency Event

```
  [Triggered] → vsm_emergency_events created
       │
       │ EmergencyBroadcastJob dispatched (dedicated 'emergency' queue; 3 retries; bypasses rate limiting)
       │ → ALL active sys_users: SMS + in-app push
       │ → if type=Lockdown: is_lockdown_active=true → gate pass generation blocked
       │ → headcount_initiated=true → ATT module query → dispatch to class teachers
       ▼
    [Active]
       │
       │ Admin resolves: resolved_at=NOW(); is_lockdown_active=false
       │ → notify staff "Emergency resolved"
       ▼
    [Resolved]
```

---

### FSM 4: Guard Shift Attendance

```
  [Scheduled]
       │
       │ guard clocks in → actual_start_time recorded
       ▼
  [Present]        if actual_start <= shift_start_time + 15 min
  [Late]           if actual_start >  shift_start_time + 15 min (BR-VSM-007)
       │
       │ guard clocks out → actual_end_time recorded
       ▼
  [Early_Departure] if actual_end <  shift_end_time - 15 min (BR-VSM-007)
  [Present]         if actual_end >= shift_end_time - 15 min
  [Absent]          set by admin if guard never clocked in
```

**UNIQUE KEY** on `(guard_user_id, shift_date, shift_start_time)` prevents duplicate shift creation.

---

### FSM 5: Pre-Registration + Gate Check-in Full Flow

```
  Host fills pre-registration form
       │
       ▼
  Blacklist check (BR-VSM-001) ──(match)──► Block + Alert security + Log blacklist_hit=1
       │ (no match)
       ▼
  vsm_visitors.upsert(mobile_no)  [visit_count NOT incremented yet]
       │
       ▼
  vsm_visits.create(status=Pre_Registered)
       │
       ▼
  vsm_gate_passes.create(pass_token=Str::uuid(), expires_at=MIN(end_of_expected_date, NOW+24h))
       │
       ▼
  QR code rendered via SimpleSoftwareIO; URL = /visitor-security/gate-passes/{pass_token}/scan
       │
       ▼
  NTF dispatch: SMS + email to visitor with QR URL

  ─── VISITOR ARRIVES ───

       ▼
  Guard scans QR at gate kiosk
       │
       ▼
  Resolve pass_token → vsm_gate_passes (UNIQUE index lookup)
       │
       ├── status ≠ Issued        ──► Error: "Pass already used / expired / revoked"
       ├── expires_at < NOW()     ──► Error: "Gate pass has expired"
       ├── visit.status=Checked_In──► Error: "Visitor already on campus" (BR-VSM-003)
       └── is_lockdown_active=true──► Error: "Campus is in lockdown" (BR-VSM-010)
                              │
                              ▼ (all checks pass)
       DB::transaction() begins
         vsm_visits.checkin_time = NOW()
         vsm_visits.status = Checked_In
         vsm_gate_passes.status = Used, used_at = NOW()
         vsm_visitors.visit_count++ (DB::increment — BR-VSM-013)
         [optional] gate photo → sys_media; set checkin_photo_media_id
       DB::transaction() commits
                              │
                              ▼
       NTF: host notification (in-app + SMS if mobile set — BR-VSM-008)
       sys_activity_logs: write check-in event (BR-VSM-015)
       Badge PDF available for print (GatePassController@badge via DomPDF)
```

---

## Section 6 — Functional Requirements Summary (14 FRs)

### Core Visitor Management

| FR ID | Name | Tables Used | Key Validations | Related BRs | Priority |
|---|---|---|---|---|---|
| FR-VSM-01 | Pre-Registration | vsm_visitors, vsm_visits, vsm_gate_passes | host_staff_id exists; expected_date ≥ today; blacklist check | BR-001, BR-002, BR-009 | Critical |
| FR-VSM-02 | Walk-in Registration | vsm_visitors, vsm_visits, vsm_gate_passes | mobile_no required; blacklist check; photo to sys_media | BR-001, BR-009 | Critical |
| FR-VSM-03 | Gate Check-in | vsm_visits, vsm_gate_passes, vsm_visitors | pass_token valid; not expired; not already checked-in; lockdown check | BR-002, BR-003, BR-008, BR-010, BR-013 | Critical |
| FR-VSM-04 | Gate Check-out | vsm_visits | status=Checked_In; duration computed | BR-004 | Critical |

### Campus Operations

| FR ID | Name | Tables Used | Key Validations | Related BRs | Priority |
|---|---|---|---|---|---|
| FR-VSM-05 | Real-time Dashboard | vsm_visits (read), vsm_emergency_events (read) | Read-only; cache 60s; lockdown banner | BR-010 | Critical |
| FR-VSM-06 | Emergency Alert System | vsm_emergency_events, vsm_emergency_protocols | emergency_type required; message max:500 | BR-005, BR-010, BR-015 | Critical |

### Security Controls

| FR ID | Name | Tables Used | Key Validations | Related BRs | Priority |
|---|---|---|---|---|---|
| FR-VSM-07 | Student Pickup Auth | vsm_pickup_auth, vsm_visits, std_students | student_id exists; guardian match vs std_student_guardian_jnt | BR-011 | High |
| FR-VSM-08 | Contractor Access | vsm_contractors | date range valid; blacklist check; entry_days_json valid JSON | BR-012 | High |
| FR-VSM-09 | Blacklist Management | vsm_blacklist | mobile_no OR id_number required (at least one); valid_until ≥ today | BR-001, BR-014 | High |

### Guard Management

| FR ID | Name | Tables Used | Key Validations | Related BRs | Priority |
|---|---|---|---|---|---|
| FR-VSM-10 | Guard Shift Management | vsm_guard_shifts | shift_end_time after shift_start_time; unique(guard,date,start) | BR-007 | High |
| FR-VSM-11 | Security Patrol Rounds | vsm_patrol_rounds, vsm_patrol_checkpoints, vsm_patrol_checkpoint_log | qr_token exists in vsm_patrol_checkpoints; round status=In_Progress | BR-006 | High |

### Analytics & Misc

| FR ID | Name | Tables Used | Key Validations | Related BRs | Priority |
|---|---|---|---|---|---|
| FR-VSM-12 | Repeat Visitor Detection | vsm_visitors (read) | mobile_no lookup; visit_count > 0 triggers "Returning visitor" badge | BR-013 | Medium |
| FR-VSM-13 | CCTV Hooks | vsm_cctv_events | **Webhook ingestion ONLY — hardware out of scope**; validate X-CCTV-Secret header; `->withoutMiddleware(['auth','tenant'])` | — | Low |
| FR-VSM-14 | Visitor Log Reports | All vsm_* (read) | Date range filters; ?format=pdf\|csv; DomPDF / fputcsv | — | Medium |

---

## Section 7 — Permission Matrix

| Permission Slug | Admin | Principal | Reception | Guard | Teacher/Staff |
|---|---|---|---|---|---|
| `tenant.vsm-visitor.view` | ✓ | ✓ | ✓ | ✓ | — |
| `tenant.vsm-visitor.create` | ✓ | — | ✓ | — | — |
| `tenant.vsm-visitor.pre-register` | ✓ | ✓ | ✓ | — | ✓ |
| `tenant.vsm-visitor.update` | ✓ | — | ✓ | — | — |
| `tenant.vsm-visitor.delete` | ✓ | — | — | — | — |
| `tenant.vsm-visit.checkin` | ✓ | — | ✓ | ✓ | — |
| `tenant.vsm-visit.checkout` | ✓ | — | ✓ | ✓ | — |
| `tenant.vsm-visit.view` | ✓ | ✓ | ✓ | ✓ | — |
| `tenant.vsm-contractor.view` | ✓ | — | ✓ | — | — |
| `tenant.vsm-contractor.manage` | ✓ | — | — | — | — |
| `tenant.vsm-blacklist.manage` | ✓ | ✓ | — | — | — |
| `tenant.vsm-guard-shift.manage` | ✓ | — | — | — | — |
| `tenant.vsm-guard-shift.self` | — | — | — | ✓ | — |
| `tenant.vsm-patrol.manage` | ✓ | — | — | ✓ | — |
| `tenant.vsm-emergency.view` | ✓ | ✓ | ✓ | ✓ | — |
| `tenant.vsm-emergency.broadcast` | ✓ | ✓ | — | — | — |
| `tenant.vsm-report.view` | ✓ | ✓ | — | — | — |

**Policy Classes (8):**

| Policy | Protects |
|---|---|
| `VisitorPolicy` | VisitorController — view, create, update, delete, pre-register |
| `VisitPolicy` | VisitController — view, checkin, checkout |
| `GatePassPolicy` | GatePassController — badge, revoke |
| `BlacklistPolicy` | VisitorController@blacklist* — manage |
| `ContractorPolicy` | ContractorController — view, manage, revoke |
| `GuardShiftPolicy` | GuardShiftController — manage (admin), self (guard clock-in/out) |
| `PatrolPolicy` | PatrolController — manage |
| `EmergencyPolicy` | EmergencyController — view, broadcast, resolve |

---

## Section 8 — Service Architecture (4 Services)

```
Service:     VisitorService
File:        Modules/VisitorSecurity/app/Services/VisitorService.php
Namespace:   Modules\VisitorSecurity\app\Services
Depends on:  SecurityAlertService (lockdown check), NTF module (notifications)
Fires:       NTF host arrival alert, NTF QR dispatch (SMS+email), sys_activity_logs write

Key Methods:
  registerWalkIn(StoreVisitorRequest $request): array
    └── blacklist check → upsert vsm_visitors → create vsm_visits(Registered) → generateGatePass → notify host; returns [visitor, visit, gate_pass]

  preRegister(PreRegisterVisitRequest $request): array
    └── blacklist check → upsert vsm_visitors → create vsm_visits(Pre_Registered) → generateGatePass → sendQrToVisitor via NTF; returns [visitor, visit, gate_pass]

  processCheckin(ProcessCheckinRequest $request): VsmVisit
    └── Step 1: Resolve pass_token → vsm_gate_passes; verify status=Issued, expires_at > NOW
        Step 2: Load vsm_visits; verify status NOT Checked_In (BR-VSM-003)
        Step 3: Blacklist re-check at gate (belt-and-suspenders — BR-VSM-001)
        Step 4: SecurityAlertService::isLockdownActive() (BR-VSM-010)
        Step 5: DB::transaction() begins
        Step 6: vsm_visits: checkin_time=NOW(), status=Checked_In
        Step 7: vsm_gate_passes: status=Used, used_at=NOW()
        Step 8: vsm_visitors: visit_count++ via DB::increment (BR-VSM-013)
        Step 9: Optional gate photo → sys_media; set checkin_photo_media_id
        Step 10: DB::transaction() commits
        Step 11: Dispatch host NTF (in-app + SMS — BR-VSM-008)
        Step 12: Write to sys_activity_logs (BR-VSM-015)
        Return: updated vsm_visits record

  processCheckout(ProcessCheckoutRequest $request): VsmVisit
    └── set checkout_time=NOW(); compute duration_minutes; clear is_overdue; gate pass status=Closed; log audit

  generateGatePass(VsmVisit $visit): VsmGatePass
    └── Str::uuid() as pass_token; expires_at = MIN(end_of_expected_date, NOW+24h); SimpleSoftwareIO QR; store qr_code_path

  checkBlacklist(string $mobileNo, ?string $idNumber): ?VsmBlacklist
    └── match by mobile_no OR id_number; check is_active=1 and (valid_until >= TODAY or valid_until IS NULL)

  sendQrToVisitor(VsmGatePass $pass, string $mobile, ?string $email): void
    └── dispatch via NTF module — SMS + email with hosted QR URL (/visitor-security/gate-passes/{pass_token}/scan)

  processPickupAuthorisation(ProcessPickupRequest $request): VsmPickupAuth
    └── lookup std_student_guardian_jnt WHERE student_id=$student AND guardian.mobile_no=$mobile AND can_pickup=1
        If match: is_authorised=1
        If no match: require override_by + override_reason (BR-VSM-011)
```

```
Service:     SecurityAlertService
File:        Modules/VisitorSecurity/app/Services/SecurityAlertService.php
Namespace:   Modules\VisitorSecurity\app\Services
Depends on:  NTF module (emergency broadcast), ATT module (headcount)
Fires:       EmergencyBroadcastJob (dedicated 'emergency' queue; 3 retries; bypasses rate limiting)

Key Methods:
  broadcastEmergency(BroadcastEmergencyRequest $request): VsmEmergencyEvent
    └── Step 1: Create vsm_emergency_events record
        Step 2: If type=Lockdown: is_lockdown_active=true
        Step 3: Dispatch EmergencyBroadcastJob (queue: 'emergency', 3 retries)
                → Query ALL active sys_users (staff + teachers)
                → Dispatch SMS + in-app push to each via NTF module
                → Update notification_count
        Step 4: headcount_initiated=true
                → Query ATT module for today's present students
                → Dispatch per-section headcount task to class teachers (in-app)
        Step 5: Log to sys_activity_logs (BR-VSM-015)
        Return: vsm_emergency_events record

  resolveEmergency(VsmEmergencyEvent $event): void
    └── set resolved_at=NOW(); is_lockdown_active=false; notify staff of resolution

  flagOverdueVisitors(): int
    └── called by FlagOverdueVisitorsJob every 15 min;
        WHERE status=Checked_In AND TIMESTAMPADD(MINUTE, expected_duration_minutes, checkin_time) < NOW()
        Carbon::setTimezone(school_timezone) for correct NOW() comparison
        returns count of newly flagged; dispatches in-app alert to security desk

  isLockdownActive(): bool
    └── check vsm_emergency_events WHERE is_lockdown_active=1 AND resolved_at IS NULL; used as gate guard before pass generation
```

```
Service:     PatrolService
File:        Modules/VisitorSecurity/app/Services/PatrolService.php
Namespace:   Modules\VisitorSecurity\app\Services
Depends on:  —
Fires:       Admin alert when round is Incomplete

Key Methods:
  startRound(int $guardUserId, ?int $shiftId): VsmPatrolRound
    └── create vsm_patrol_rounds (status=In_Progress); set checkpoints_total from active checkpoint count

  scanCheckpoint(VsmPatrolRound $round, string $qrToken): VsmPatrolCheckpointLog
    └── resolve qr_token → vsm_patrol_checkpoints; create VsmPatrolCheckpointLog; increment checkpoints_completed; recompute completion_pct; if all scanned: auto-call completeRound

  completeRound(VsmPatrolRound $round): VsmPatrolRound
    └── compute completion_pct = (checkpoints_completed / checkpoints_total) × 100;
        if completion_pct < 80: status=Incomplete, alert admin (BR-VSM-006)
        else: status=Completed
        set patrol_end_time=NOW()

  generateCheckpointQr(VsmPatrolCheckpoint $checkpoint): string
    └── SimpleSoftwareIO QR for qr_token; store qr_code_path; return image URL
```

```
Service:     ContractorAccessService
File:        Modules/VisitorSecurity/app/Services/ContractorAccessService.php
Namespace:   Modules\VisitorSecurity\app\Services
Depends on:  VisitorService (blacklist check)
Fires:       Admin notification on contractor registration and each entry

Key Methods:
  register(StoreContractorRequest $request): VsmContractor
    └── blacklist check (mobile_no); create vsm_contractors; generate unique pass_token = Str::uuid(); notify admin

  validateEntry(string $passToken): array
    └── find by pass_token; check pass_status=Active; validate access_from <= today <= access_until; validate day_of_week in entry_days_json (BR-VSM-012); increment entry_count
        Returns: [contractor, status, error_message]

  revokeAccess(VsmContractor $contractor): void
    └── set pass_status=Revoked; notify admin

  expireOldContracts(): int
    └── called by ExpireContractorPassesJob; UPDATE WHERE access_until < TODAY; returns count expired
```

---

## Section 9 — Integration Contracts

### 9.1 Outbound Notifications (VSM → NTF Module)

| Trigger | Fired By | Target / Channel | Timing | Payload |
|---|---|---|---|---|
| Host arrival alert | VisitorService::processCheckin | host_user_id; in-app + SMS if mobile set | Real-time at check-in | visitor name, purpose, checkin_time, badge URL |
| QR gate pass dispatch | VisitorService::preRegister / registerWalkIn | visitor mobile + email; SMS + email | At registration | QR URL: `/visitor-security/gate-passes/{token}/scan`, expires_at |
| Emergency broadcast | SecurityAlertService::broadcastEmergency | ALL active sys_users; SMS + in-app push; **dedicated 'emergency' queue; bypasses rate limiting** | Immediate on trigger | emergency_type, message, affected_zones, is_lockdown |
| Overdue visitor alert | FlagOverdueVisitorsJob | Security desk; in-app | Every 15 min run | Count of overdue visitors, list |
| Blacklist hit alert | VisitorService::checkBlacklist | Reception desk; in-app | Real-time on registration | Blacklist reason, visitor name |
| Incomplete patrol alert | PatrolService::completeRound | Admin; in-app | On round completion | Guard name, completion_pct, round_id |
| Emergency resolved | SecurityAlertService::resolveEmergency | All active sys_users; in-app | On resolution | resolved_at, message |

### 9.2 Inbound Reads (VSM reads from other modules)

| Module | Table Read | Purpose |
|---|---|---|
| STD | `std_students`, `std_student_guardian_jnt` (can_pickup=1) | Pickup auth: verify guardian authorised for student |
| ATT | Attendance tables | Emergency headcount: query present students per section |
| SCH | `sys_school_settings` (key: `timezone`) | School timezone for overdue scheduler Carbon::setTimezone() |
| SCH | `sys_school_settings` (key: `vsm_visitor_media_retention_days`) | Data retention: visitor photo purge policy (90-day default) |

### 9.3 CCTV Webhook Contract (Inbound — FR-VSM-13)

```
POST /api/v1/vsm/cctv/event
Auth:     NONE — withoutMiddleware(['auth', 'tenant'])
Security: Validate X-CCTV-Secret header against stored secret
Payload:  { "camera_id": "CAM001", "event_type": "gate_open", "timestamp": "...", "snapshot_url": "..." }
Action:   Create vsm_cctv_events; link to active vsm_visits if camera is gate camera + visit within check-in window
Response: { "success": true, "event_id": N } or { "success": false, "message": "Invalid CCTV secret" }
```

### 9.4 Public Scan Route

```
GET /visitor-security/gate-passes/{pass_token}/scan
Auth:     NONE — public route; QR URL embedded in SMS
Purpose:  Visitor scans QR on mobile to see identity + access status; no check-in action
Note:     Shows only visitor name, purpose, host, expected date — NO sensitive data
```

---

## Section 10 — Non-Functional Requirements

| Category | Requirement | Implementation Note |
|---|---|---|
| Performance | Dashboard live count query < 1 second | Composite index `(status, expected_date)` on vsm_visits; cache dashboard aggregates for 60s |
| Performance | QR scan check-in response < 2 seconds | gate pass lookup by UNIQUE indexed `pass_token` (VARCHAR); no full-table scan |
| Security | Gate pass token = UUID v4, never sequential | `Str::uuid()` in VisitorService::generateGatePass() |
| Security | Gate pass expiry server-side only | Compare `expires_at` against DB NOW(); never client-side timeout |
| Security | Visitor ID proof not publicly accessible | Private disk storage; serve via signed URL or controller stream (not public URL) |
| Concurrency | Check-in duplicate prevention | `DB::transaction()` + model `lockForUpdate()` in VisitorService::processCheckin() (BR-VSM-003) |
| Availability | Emergency broadcast under load | Dedicated queue channel `'emergency'`; no rate limiting; 3 retries; separate worker recommended |
| Privacy | Data retention for visitor media | 90-day default; configurable via `sys_school_settings` key `vsm_visitor_media_retention_days`; `vsm:purge-old-media` Artisan command |
| Timezone | Overdue scheduler timezone accuracy | `Carbon::setTimezone(school_timezone)` from sys_school_settings before any NOW() comparison |
| HTTPS | Gate check-in webcam capture | HTML5 `getUserMedia` API requires HTTPS; fallback to file upload input on HTTP |
| Mobile-friendliness | Guard kiosk usability | Responsive layout; large touch targets (min 44px); camera access on tablet/mobile |
| QR Generation | Visitor + contractor + checkpoint QRs | `SimpleSoftwareIO/simple-qrcode`; hosted URL in SMS |
| Badge Printing | DomPDF visitor badge | GatePassController@badge generates PDF; auto triggers `window.print()` via JS |

---

## Section 11 — Test Plan Outline

### 4 Scheduled Jobs

| Job | Schedule | Command |
|---|---|---|
| `FlagOverdueVisitorsJob` | Every 15 minutes | `vsm:flag-overdue-visitors` |
| `ExpireGatePassesJob` | Every 1 hour | `vsm:expire-gate-passes` |
| `ExpireBlacklistEntriesJob` | Daily at midnight | `vsm:expire-blacklist-entries` |
| `ExpireContractorPassesJob` | Daily at midnight | `vsm:expire-contractor-passes` |

### Feature Tests (Pest) — 10 files

| File | Key Scenarios | Priority |
|---|---|---|
| `VisitorRegistrationTest` | Walk-in registration stores visitor + visit; photo uploaded to sys_media; blacklist check runs | Critical |
| `BlacklistBlockTest` | Blacklisted mobile_no → blocked; blacklist_hit=1 logged | Critical |
| `PreRegistrationQrTest` | Pre-register → QR generated; SMS dispatched | Critical |
| `GateCheckinTest` | QR scan → checkin_time set; pass=Used; host notified | Critical |
| `DuplicateCheckinBlockTest` | Second check-in attempt → 422 without supervisor override | Critical |
| `GateCheckoutTest` | Checkout → duration_minutes computed; status=Checked_Out | High |
| `OverdueFlaggingTest` | Scheduler marks is_overdue=1 after duration; clears on checkout | High |
| `EmergencyBroadcastTest` | Broadcast dispatched; vsm_emergency_events created; lockdown mode enabled | High |
| `LockdownModeTest` | is_lockdown_active=true → gate pass generation blocked (403) | High |
| `StudentPickupAuthTest` | Authorised guardian matched (is_authorised=1); unmatched → override required | High |

### Additional Tests

| File | Key Scenarios | Priority |
|---|---|---|
| `ContractorAccessTest` | Pass valid in date range; expired after access_until; blocked on revoked | High |
| `PatrolRoundTest` | Checkpoint scan → completion % recalculated; < 80% → status=Incomplete | Medium |
| `GuardClockInTest` | Clock-in 20 min late → attendance_status=Late auto-set | Medium |
| `BlacklistExpiryTest` (Unit) | Entry with valid_until < today → is_active=0 after scheduler | Medium |
| `GatePassExpiryTest` (Unit) | expires_at < NOW → validate blocks check-in | High |
| `RepeatVisitorTest` | Same mobile_no → existing record matched; visit_count incremented on check-in | Medium |
| `ContractorEntryDayBlockTest` | Entry on day not in entry_days_json → check-in rejected | Medium |
| `CctvWebhookTest` | POST /api/v1/vsm/cctv/event → vsm_cctv_events created; linked to visit if gate camera | Low |

### Test Setup

```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// Actor factories: AdminUser, ReceptionUser, GuardUser, TeacherUser, PrincipalUser
// VsmVisitorFactory: generates visitor with mobile_no, optional id_number
// VsmVisitFactory(status: 'Checked_In'|'Pre_Registered'|etc.)
// VsmGatePassFactory: generates UUID v4 pass_token, expires_at in future
// Notification::fake() for host arrival alerts + emergency broadcast tests
// Queue::fake() for FlagOverdueVisitorsJob, EmergencyBroadcastJob
// Storage::fake() for visitor photo uploads
// For lockdown test: create active VsmEmergencyEvent with is_lockdown_active=1
// CCTV webhook: withoutMiddleware(['auth']) + mock X-CCTV-Secret header
```

---

## Phase 1 Quality Gate — Verification

- [x] All 13 vsm_* tables in Section 2 entity inventory with full column details
- [x] All 14 FRs (FR-VSM-01 to FR-VSM-14) in Section 6
- [x] All 15 BRs (BR-VSM-001 to BR-VSM-015) in Section 4 with enforcement point
- [x] All 5 FSMs documented with ASCII state diagram and side effects
- [x] All 4 services listed with key method signatures in Section 8
- [x] `vsm_gate_passes.pass_token` noted as UUID v4 (Str::uuid()); never sequential
- [x] `vsm_gate_passes.expires_at` noted as server-side only comparison (BR-VSM-002)
- [x] `vsm_visits.blacklist_hit` documented with trigger (registration time)
- [x] `vsm_visits.is_overdue` documented with trigger (FlagOverdueVisitorsJob)
- [x] `vsm_contractors.entry_days_json` and BR-VSM-012 documented together
- [x] Check-in concurrency: DB::transaction() + lockForUpdate() in Section 8 + Section 10
- [x] Emergency broadcast: dedicated 'emergency' queue; bypasses rate limiting in Section 8 + Section 10
- [x] No `tenant_id` column mentioned in any table definition
- [x] Cross-module STD dependency (std_students, std_student_guardian_jnt.can_pickup) documented in Section 9
- [x] Permission matrix covers all 17 permission slugs from req v2 Section 15.2
- [x] FR-VSM-13 (CCTV Hooks) clearly noted as webhook ingestion ONLY; hardware out of scope
- [x] Dashboard auto-refresh at 60s (polling; SSE upgrade noted as future)
- [x] All 4 scheduled jobs listed with schedule in Section 11
- [x] Visitor photo/ID proof: sys_media with model_type='vsm_visitors'; private disk; signed URL noted
- [x] Data retention 90-day default configurable in Section 10
- [x] School timezone handling: Carbon::setTimezone() in Section 10
- [x] FK type discrepancy noted and resolution documented (Section 2.7)
- [x] std_student_guardian_jnt.can_pickup=1 verified as pickup auth column
