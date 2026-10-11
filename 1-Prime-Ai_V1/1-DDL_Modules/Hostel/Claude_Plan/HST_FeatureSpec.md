# HST — Hostel Management Module Feature Specification
**Version:** 1.0 | **Date:** 2026-03-27 | **Based on:** HST_Hostel_Requirement.md v2
**Module Code:** HST | **DB Prefix:** `hst_*` | **Tables:** 21 | **Database:** `tenant_db`

---

## Table of Contents

1. [Module Identity & Scope](#section-1)
2. [Entity Inventory — All 21 Tables](#section-2)
3. [Entity Relationship Diagram](#section-3)
4. [Business Rules (22 rules)](#section-4)
5. [Workflow State Machines (4 FSMs)](#section-5)
6. [Functional Requirements Summary (21 FRs)](#section-6)
7. [Permission Matrix](#section-7)
8. [Service Architecture (7 Services)](#section-8)
9. [Integration Contracts (7 events + 1 direct service)](#section-9)
10. [Non-Functional Requirements](#section-10)
11. [Test Plan Outline](#section-11)

---

## Section 1 — Module Identity & Scope {#section-1}

### 1.1 Module Identity

| Property | Value |
|---|---|
| Module Name | Hostel Management |
| Module Code | HST |
| RBS Reference | K — Hostel Management (K1–K6) |
| nwidart Namespace | `Modules\Hostel` |
| Module Path | `Modules/Hostel/` |
| Route Prefix | `hostel/` |
| Route Name Prefix | `hostel.` |
| DB Table Prefix | `hst_*` |
| Module Type | Tenant (per-school, stancl/tenancy v3.9 — dedicated DB per tenant) |
| No `tenant_id` columns | Isolation via separate database |
| Registration | `routes/tenant.php` |

### 1.2 Sub-Modules In Scope

| Sub-Module | RBS Ref | Description |
|---|---|---|
| K1 — Room & Bed Management | K1 | Building → Floor → Room → Bed hierarchy; capacity tracking |
| K2 — Student Room Allocation | K2 | Bed allotment, gender validation, transfer, bulk vacate, waitlist |
| K3 — Hostel Attendance | K3 | 3 daily shifts (morning/evening/night); bulk mark; movement log |
| K3b — Leave Pass Management | K3 | Leave pass FSM; auto-attendance mark; late return auto-incident |
| K4 — Mess Management | K4 | Weekly menu, special diet assignment, meal attendance |
| K5 — Hostel Fee Integration | K5 | Fee structure per room type; prorated calculation; StudentFee push |
| K6 — Hostel Complaint Register | K6 | Internal maintenance complaints; SLA auto-escalation |
| Warden Management | — | Assignment rotation with effective date range; scoped access |
| Visitor Log | — | Hostel-specific visitor register; visiting hours enforcement |
| Medical / Sick Bay | — | Admission, discharge, attendance auto-mark; HPC soft link |
| Room Inventory | — | Furniture/fixtures per room; damage reporting; cost recovery |
| Dashboard & Reports | — | Live occupancy KPIs; 12 report types; PDF/CSV export |

### 1.3 Out of Scope

- Student academic profile, class records, marks → StudentProfile module (`std_*`)
- School fee collection, payment gateway, receipts → StudentFee module (`fin_*`) — HST integrates via service-only calls
- Full medical records, hospital visits → HPC module (sick bay is HST-internal; serious cases soft-link to HPC)
- Campus-wide visitor management → Frontdesk module (`fnt_*`)
- Day-scholar canteen → Mess Management module (`mes_*`) when applicable
- Staff accommodation / quarters management
- CCTV / access control hardware integration

### 1.4 Module Scale

| Artifact | Count |
|---|---|
| Controllers | 20 |
| Models | 21 |
| Services | 7 |
| FormRequests | 27 |
| Policies | 12 |
| `hst_*` Tables | **21** (Section 5 authoritative; Section 1.2 header says 20 — use 21) |
| Blade Views | ~65 |
| Seeders | 2 + 1 runner |
| Events | 7 |
| Queued Jobs | 2 |

### 1.5 Cross-Module FK Type Resolution (Critical)

**DDL Rule 7** states "All IDs and FK references: BIGINT UNSIGNED". However, verification of `tenant_db_v2.sql` shows that all referenced parent tables use `INT UNSIGNED` PKs:

| Parent Table | Parent PK Type | Confirmed From |
|---|---|---|
| `sys_users.id` | `INT UNSIGNED` | tenant_db_v2.sql (line ~957: user_id INT UNSIGNED NOT NULL) |
| `sys_media.id` | `INT UNSIGNED` | tenant_db_v2.sql (per VSM precedent + media FK pattern) |
| `std_students.id` | `INT UNSIGNED` | tenant_db_v2.sql (line ~6372: student_id INT UNSIGNED NOT NULL) |
| `sch_academic_term.id` | `INT UNSIGNED` | tenant_db_v2.sql (line ~3115: academic_term_id INT UNSIGNED) |

> **Note:** Requirement file uses `sch_academic_sessions` but the actual DDL table is `sch_academic_term` (singular). All hst_* references to academic sessions use `sch_academic_term.id`.

**Resolution:** `hst_*` PKs and internal FKs → `BIGINT UNSIGNED`. Cross-module FK columns (sys_users, sys_media, std_students, sch_academic_term) → `INT UNSIGNED`. MySQL FK constraints require matching column types; using BIGINT UNSIGNED to reference INT UNSIGNED parent columns would cause migration failure.

---

## Section 2 — Entity Inventory (All 21 Tables) {#section-2}

### 2.1 Infrastructure Domain

---

#### `hst_hostels` — Hostel/Building configuration master

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| name | VARCHAR(150) | NO | — | NOT NULL | Hostel/building name |
| type | ENUM('boys','girls','mixed') | NO | — | NOT NULL | Gender type restriction |
| code | VARCHAR(20) | YES | NULL | UNIQUE | Short code (BH1, GH1, etc.) — NULL allowed; multiple NULLs OK |
| warden_id | INT UNSIGNED | YES | NULL | FK → sys_users.id | Current chief warden (nullable) |
| total_capacity | SMALLINT UNSIGNED | NO | 0 | — | Total beds; recomputed by AllotmentService |
| current_occupancy | SMALLINT UNSIGNED | NO | 0 | — | Denormalized occupied bed count; updated by AllotmentService |
| sick_bay_capacity | TINYINT UNSIGNED | NO | 5 | — | Sick bay bed count configuration |
| address | VARCHAR(500) | YES | NULL | — | Physical address |
| contact_phone | VARCHAR(20) | YES | NULL | — | Hostel contact number |
| visiting_days_json | JSON | YES | NULL | — | Visiting day/hour config array |
| facilities_json | JSON | YES | NULL | — | Facility name array (WiFi, Laundry, etc.) |
| is_active | TINYINT(1) | NO | 1 | — | Soft enable/disable |
| created_by | INT UNSIGNED | NO | — | NOT NULL | sys_users.id |
| updated_by | INT UNSIGNED | NO | — | NOT NULL | sys_users.id |
| created_at | TIMESTAMP | YES | NULL | — | Record creation timestamp |
| updated_at | TIMESTAMP | YES | NULL | — | Last update timestamp |
| deleted_at | TIMESTAMP | YES | NULL | — | Soft delete timestamp |

**Unique:** `UNIQUE KEY uq_hst_hostel_code (code)` — nullable; MySQL allows multiple NULLs
**Indexes:** `KEY idx_hst_hostel_warden (warden_id)`

---

#### `hst_floors` — Floor within a hostel

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Parent hostel |
| floor_number | TINYINT | NO | — | NOT NULL | Floor number (0 = Ground) |
| display_name | VARCHAR(100) | YES | NULL | — | "Ground Floor", "First Floor" etc. |
| floor_incharge_id | INT UNSIGNED | YES | NULL | FK → sys_users.id | Current floor incharge |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_floor_num (hostel_id, floor_number)`
**Indexes:** `KEY idx_hst_floor_hostel (hostel_id)`, `KEY idx_hst_floor_incharge (floor_incharge_id)`

---

#### `hst_rooms` — Room within a floor

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| floor_id | BIGINT UNSIGNED | NO | — | FK → hst_floors.id | Parent floor |
| room_number | VARCHAR(20) | NO | — | NOT NULL | Room number/label |
| room_type | ENUM('single','double','triple','dormitory') | NO | — | NOT NULL | Room type |
| capacity | TINYINT UNSIGNED | NO | — | NOT NULL | Total beds in room |
| current_occupancy | TINYINT UNSIGNED | NO | 0 | — | Denormalized occupied count; maintained by AllotmentService |
| status | ENUM('available','full','maintenance') | NO | 'available' | — | Availability; auto-updated (BR-HST-010) |
| amenities_json | JSON | YES | NULL | — | AC, attached bath, fan, etc. |
| priority_flags_json | JSON | YES | NULL | — | medical, senior, merit priority flags |
| notes | VARCHAR(500) | YES | NULL | — | Admin notes |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_room_num (floor_id, room_number)`
**Indexes:** `KEY idx_hst_room_floor (floor_id)`

---

#### `hst_beds` — Bed within a room

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| room_id | BIGINT UNSIGNED | NO | — | FK → hst_rooms.id | Parent room |
| bed_label | VARCHAR(20) | NO | — | NOT NULL | Bed A, Bed 1, etc. |
| status | ENUM('available','occupied','maintenance') | NO | 'available' | — | Bed availability status |
| condition | ENUM('good','fair','poor') | NO | 'good' | — | Physical condition |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_bed_label (room_id, bed_label)`
**Indexes:** `KEY idx_hst_bed_room (room_id)`

---

### 2.2 Warden Management Domain

---

#### `hst_warden_assignments` — Warden rotation log

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel context |
| floor_id | BIGINT UNSIGNED | YES | NULL | FK → hst_floors.id | Floor (NULL = hostel-level chief warden) |
| user_id | INT UNSIGNED | NO | — | FK → sys_users.id | Staff assigned as warden |
| assignment_type | ENUM('chief','block','floor','assistant') | NO | — | NOT NULL | Warden role type |
| effective_from | DATE | NO | — | NOT NULL | Assignment start date |
| effective_to | DATE | YES | NULL | — | Assignment end (NULL = currently active) |
| remarks | VARCHAR(300) | YES | NULL | — | Rotation notes |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_wa_hostel_floor_to (hostel_id, floor_id, effective_to)` — for current-warden lookup, `KEY idx_hst_wa_user (user_id)`

---

### 2.3 Allocation Domain

---

#### `hst_allotments` — Student bed allotment (with double-allotment prevention)

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student being allotted |
| bed_id | BIGINT UNSIGNED | NO | — | FK → hst_beds.id | Assigned bed |
| academic_session_id | INT UNSIGNED | NO | — | FK → sch_academic_term.id | Academic year scope |
| allotment_date | DATE | NO | — | NOT NULL | Date of allotment |
| vacating_date | DATE | YES | NULL | — | Vacating date (NULL = currently active) |
| meal_plan | ENUM('full_board','lunch_only','dinner_only','none') | NO | 'full_board' | — | Meal plan selected |
| status | ENUM('active','vacated','transferred','waitlisted') | NO | 'active' | — | Allotment lifecycle status |
| remarks | VARCHAR(500) | YES | NULL | — | Notes |
| gen_active_bed_id | BIGINT | YES | GENERATED | GENERATED ALWAYS AS (IF(status='active', bed_id, NULL)) STORED | Null when not active — enables partial UNIQUE |
| gen_active_student_id | BIGINT | YES | GENERATED | GENERATED ALWAYS AS (IF(status='active', student_id, NULL)) STORED | Null when not active — enables partial UNIQUE |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Critical UNIQUE indexes (double-allotment prevention):**
- `UNIQUE KEY uq_hst_allot_active_bed (gen_active_bed_id)` — prevents 2 active allotments to same bed
- `UNIQUE KEY uq_hst_allot_active_student (gen_active_student_id)` — prevents student having 2 active allotments

**Indexes:** `KEY idx_hst_allot_student_status (student_id, status)`, `KEY idx_hst_allot_bed_status (bed_id, status)`, `KEY idx_hst_allot_session (academic_session_id)`

---

#### `hst_room_change_requests` — Room transfer workflow

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Requesting student |
| from_allotment_id | BIGINT UNSIGNED | NO | — | FK → hst_allotments.id | Current active allotment |
| requested_room_id | BIGINT UNSIGNED | YES | NULL | FK → hst_rooms.id | Preferred target room (optional) |
| reason | TEXT | NO | — | NOT NULL | Reason for request |
| status | ENUM('pending','approved','rejected') | NO | 'pending' | — | Request status |
| approved_by | INT UNSIGNED | YES | NULL | FK → sys_users.id | Approving warden |
| approved_at | TIMESTAMP | YES | NULL | — | Approval timestamp |
| rejection_reason | TEXT | YES | NULL | — | Required on rejection |
| new_allotment_id | BIGINT UNSIGNED | YES | NULL | FK → hst_allotments.id | Created on approval |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_rcr_student (student_id)`, `KEY idx_hst_rcr_from_allot (from_allotment_id)`, `KEY idx_hst_rcr_room (requested_room_id)`, `KEY idx_hst_rcr_approved_by (approved_by)`, `KEY idx_hst_rcr_new_allot (new_allotment_id)`

---

#### `hst_room_inventory` — Room furniture/fixtures tracking

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| room_id | BIGINT UNSIGNED | NO | — | FK → hst_rooms.id | Room this item belongs to |
| item_name | VARCHAR(150) | NO | — | NOT NULL | Bed / Mattress / Study Table / Chair / Cupboard |
| quantity | TINYINT UNSIGNED | NO | 1 | — | Count of this item in room |
| condition | ENUM('good','fair','poor','under_repair','disposed') | NO | 'good' | — | Current condition |
| last_inspected_at | DATE | YES | NULL | — | Last inspection date |
| damage_description | TEXT | YES | NULL | — | Damage description |
| estimated_repair_cost | DECIMAL(10,2) | YES | NULL | — | Repair/replacement cost estimate |
| repair_status | ENUM('none','pending','under_repair','repaired','written_off') | NO | 'none' | — | Repair workflow status |
| responsible_student_id | INT UNSIGNED | YES | NULL | FK → std_students.id | Student responsible for damage |
| charge_pushed_to_fee | TINYINT(1) | NO | 0 | — | Flag: damage charge pushed to StudentFee module |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_inv_room (room_id)`, `KEY idx_hst_inv_student (responsible_student_id)`

---

### 2.4 Attendance Domain

---

#### `hst_attendance` — Roll-call session (one per hostel, date, shift)

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| attendance_date | DATE | NO | — | NOT NULL | Roll call date |
| shift | ENUM('morning','evening','night') | NO | — | NOT NULL | Shift |
| marked_by | INT UNSIGNED | NO | — | FK → sys_users.id | Warden who marked this session |
| present_count | SMALLINT UNSIGNED | NO | 0 | — | Pre-computed present count; set by HstAttendanceService at save |
| absent_count | SMALLINT UNSIGNED | NO | 0 | — | Pre-computed absent count; set at save |
| leave_count | SMALLINT UNSIGNED | NO | 0 | — | Pre-computed on-leave count; set at save |
| late_count | SMALLINT UNSIGNED | NO | 0 | — | Pre-computed late count; set at save |
| is_locked | TINYINT(1) | NO | 0 | — | Locked after 24h; editable by Chief Warden only |
| remarks | VARCHAR(500) | YES | NULL | — | Session-level notes |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_att_session (hostel_id, attendance_date, shift)` — prevents duplicate sessions even on double-submit
**Indexes:** `KEY idx_hst_att_hostel (hostel_id)`, `KEY idx_hst_att_marked_by (marked_by)`

---

#### `hst_attendance_entries` — Per-student row in a session

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| attendance_id | BIGINT UNSIGNED | NO | — | FK → hst_attendance.id CASCADE DELETE | Parent session |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student |
| status | ENUM('present','absent','leave','home','late','sick_bay') | NO | — | NOT NULL | Attendance status |
| late_remarks | VARCHAR(255) | YES | NULL | — | Remarks for late/absent entries |
| check_in_time | TIME | YES | NULL | — | Actual check-in time (for late) |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_att_entry (attendance_id, student_id)`
**Indexes:** `KEY idx_hst_ae_attendance (attendance_id)`, `KEY idx_hst_ae_student (student_id)`
**CASCADE:** `ON DELETE CASCADE` from `hst_attendance` — entries deleted when session deleted

---

#### `hst_movement_log` — In-out gate register

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| movement_date | DATE | NO | — | NOT NULL | Date of movement |
| out_time | TIME | NO | — | NOT NULL | Departure time |
| in_time | TIME | YES | NULL | — | Actual return (NULL = not yet returned) |
| expected_return_time | TIME | YES | NULL | — | Expected return time |
| destination | VARCHAR(255) | NO | — | NOT NULL | Destination/reason |
| purpose | VARCHAR(500) | YES | NULL | — | Additional details |
| gate_pass_issued_by | INT UNSIGNED | YES | NULL | FK → sys_users.id | Warden who issued pass |
| overdue_notified | TINYINT(1) | NO | 0 | — | Overdue notification sent flag |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_ml_hostel_date (hostel_id, movement_date)`, `KEY idx_hst_ml_student_in (student_id, in_time)` — critical for pending-returns query (`WHERE in_time IS NULL AND movement_date = ?`), `KEY idx_hst_ml_issued_by (gate_pass_issued_by)`

---

### 2.5 Leave Pass Domain

---

#### `hst_leave_passes` — Leave pass FSM

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student |
| allotment_id | BIGINT UNSIGNED | NO | — | FK → hst_allotments.id | Active allotment at time of application |
| leave_type | ENUM('home','emergency','medical','festival','vacation','other') | NO | — | NOT NULL | Leave category |
| from_date | DATE | NO | — | NOT NULL | Leave start date |
| to_date | DATE | NO | — | NOT NULL | Leave end date (>= from_date; FormRequest validated) |
| destination | VARCHAR(255) | NO | — | NOT NULL | Leave destination |
| purpose | VARCHAR(500) | NO | — | NOT NULL | Purpose of leave |
| guardian_contact | VARCHAR(20) | YES | NULL | — | Guardian contact during leave |
| applied_by | INT UNSIGNED | NO | — | FK → sys_users.id | Staff who created the application |
| approved_by | INT UNSIGNED | YES | NULL | FK → sys_users.id | Approving warden |
| approved_at | TIMESTAMP | YES | NULL | — | Approval timestamp |
| status | ENUM('pending','approved','rejected','returned','cancelled') | NO | 'pending' | — | Leave pass FSM state |
| rejection_reason | TEXT | YES | NULL | — | Reason required on rejection |
| actual_return_date | DATE | YES | NULL | — | Filled on return confirmation |
| late_return_incident_id | BIGINT UNSIGNED | YES | NULL | FK → hst_incidents.id | Auto-created incident if late return |
| parent_notified | TINYINT(1) | NO | 0 | — | Parent notification dispatch flag |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_lp_student (student_id)`, `KEY idx_hst_lp_allotment (allotment_id)`, `KEY idx_hst_lp_applied_by (applied_by)`, `KEY idx_hst_lp_approved_by (approved_by)`, `KEY idx_hst_lp_incident (late_return_incident_id)`

---

### 2.6 Mess Management Domain

---

#### `hst_mess_weekly_menus` — Weekly meal plan per hostel

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| academic_session_id | INT UNSIGNED | NO | — | FK → sch_academic_term.id | Academic session |
| week_start_date | DATE | NO | — | NOT NULL | Monday of the week |
| day_of_week | TINYINT UNSIGNED | NO | — | NOT NULL | 1=Mon … 7=Sun |
| meal_type | ENUM('breakfast','lunch','dinner','snacks') | NO | — | NOT NULL | Meal time |
| menu_description | TEXT | YES | NULL | — | Menu items description |
| is_special_diet_available | TINYINT(1) | NO | 0 | — | Special diet option available for this meal |
| special_diet_description | VARCHAR(500) | YES | NULL | — | Special diet offered |
| is_published | TINYINT(1) | NO | 0 | — | Published (visible to student/parent portal) |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_menu_slot (hostel_id, week_start_date, day_of_week, meal_type)`
**Indexes:** `KEY idx_hst_menu_hostel (hostel_id)`, `KEY idx_hst_menu_session (academic_session_id)`

---

#### `hst_special_diets` — Per-student diet assignment

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel context |
| diet_type | ENUM('diabetic','jain_vegetarian','gluten_free','nut_allergy','religious_fasting','custom') | NO | — | NOT NULL | Diet category |
| custom_description | VARCHAR(300) | YES | NULL | — | Description for custom diet type |
| fasting_days_json | JSON | YES | NULL | — | Specific fasting days/periods for religious fasting |
| effective_from | DATE | NO | — | NOT NULL | Diet assignment start |
| effective_to | DATE | YES | NULL | — | Diet end (NULL = ongoing for academic year) |
| prescribed_by | VARCHAR(150) | YES | NULL | — | Doctor/authority who prescribed |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_sd_student (student_id)`, `KEY idx_hst_sd_hostel (hostel_id)`

---

#### `hst_mess_attendance` — Meal attendance per student per meal

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| attendance_date | DATE | NO | — | NOT NULL | Date |
| meal_type | ENUM('breakfast','lunch','dinner','snacks') | NO | — | NOT NULL | Meal |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student |
| status | ENUM('present','absent','on_leave','opted_out') | NO | — | NOT NULL | Meal status (on_leave set by LeavePassService) |
| is_special_diet_served | TINYINT(1) | NO | 0 | — | Special diet was actually served |
| special_diet_served_desc | VARCHAR(255) | YES | NULL | — | What special diet was served |
| marked_by | INT UNSIGNED | YES | NULL | FK → sys_users.id | Mess supervisor |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_mess_att (hostel_id, attendance_date, meal_type, student_id)`
**Indexes:** `KEY idx_hst_ma_hostel (hostel_id)`, `KEY idx_hst_ma_student (student_id)`, `KEY idx_hst_ma_marked_by (marked_by)`

---

### 2.7 Fee Structure Domain

---

#### `hst_fee_structures` — Room-type fee rates per academic session

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| academic_session_id | INT UNSIGNED | NO | — | FK → sch_academic_term.id | Academic session |
| room_type | ENUM('single','double','triple','dormitory') | NO | — | NOT NULL | Room type |
| meal_plan | ENUM('full_board','lunch_only','dinner_only','none') | NO | — | NOT NULL | Meal plan variant |
| room_rent_monthly | DECIMAL(10,2) | NO | 0.00 | NOT NULL | Monthly room rent |
| mess_charge_monthly | DECIMAL(10,2) | NO | 0.00 | NOT NULL | Monthly mess charge |
| electricity_charge_monthly | DECIMAL(10,2) | NO | 0.00 | — | Monthly electricity/water charge |
| laundry_charge_monthly | DECIMAL(10,2) | NO | 0.00 | — | Monthly laundry charge |
| security_deposit | DECIMAL(10,2) | NO | 0.00 | — | One-time security deposit |
| effective_from | DATE | NO | — | NOT NULL | Fee effective start date |
| effective_to | DATE | YES | NULL | — | Fee effective end date |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Unique:** `UNIQUE KEY uq_hst_fee_struct (hostel_id, academic_session_id, room_type, meal_plan, effective_from)`
**Indexes:** `KEY idx_hst_fs_hostel (hostel_id)`, `KEY idx_hst_fs_session (academic_session_id)`
**Note:** No FK to `fin_*` tables — integration with StudentFee is service-only (HostelFeeService::pushFeeDemand)

---

### 2.8 Incidents & Complaints Domain

---

#### `hst_incidents` — Discipline incident register

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student involved |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| incident_date | DATE | NO | — | NOT NULL | Date of incident |
| incident_time | TIME | YES | NULL | — | Time of incident |
| incident_type | VARCHAR(100) | NO | — | NOT NULL | late_arrival / rule_violation / property_damage / misconduct / other |
| description | TEXT | NO | — | NOT NULL | Detailed description |
| severity | ENUM('minor','moderate','serious') | NO | — | NOT NULL | Incident severity |
| action_taken | TEXT | YES | NULL | — | Action taken |
| reported_by | INT UNSIGNED | NO | — | FK → sys_users.id | Warden who reported |
| is_escalated | TINYINT(1) | NO | 0 | — | Escalated to Principal flag |
| escalated_at | TIMESTAMP | YES | NULL | — | Escalation timestamp |
| warning_letter_sent | TINYINT(1) | NO | 0 | — | Warning letter generated and sent |
| parent_notified | TINYINT(1) | NO | 0 | — | Parent notification dispatched |
| is_auto_generated | TINYINT(1) | NO | 0 | — | 1 = auto-created by system (e.g., late return) |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_inc_student (student_id)`, `KEY idx_hst_inc_hostel (hostel_id)`, `KEY idx_hst_inc_reported_by (reported_by)`, `KEY idx_hst_inc_date (incident_date)`

---

#### `hst_incident_media` — Incident photo/document attachments

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| incident_id | BIGINT UNSIGNED | NO | — | FK → hst_incidents.id CASCADE DELETE | Parent incident |
| media_id | **INT UNSIGNED** | NO | — | FK → sys_media.id | **INT UNSIGNED** — sys_media.id is INT UNSIGNED (not BIGINT) |
| media_type | VARCHAR(50) | YES | NULL | — | photo / document / witness_statement |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_im_incident (incident_id)`, `KEY idx_hst_im_media (media_id)`
**CASCADE:** `ON DELETE CASCADE` from `hst_incidents` — media rows deleted when incident deleted

> **CRITICAL:** `media_id` is `INT UNSIGNED` (NOT BIGINT UNSIGNED) to match `sys_media.id` which is `INT UNSIGNED`.

---

#### `hst_complaints` — Hostel-internal maintenance/service complaints

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| room_id | BIGINT UNSIGNED | YES | NULL | FK → hst_rooms.id | Room related to complaint |
| reported_by_student_id | INT UNSIGNED | YES | NULL | FK → std_students.id | Student who reported |
| reported_by_user_id | INT UNSIGNED | YES | NULL | FK → sys_users.id | Staff who reported |
| category | ENUM('maintenance','electrical','plumbing','cleanliness','security','food','other') | NO | — | NOT NULL | Complaint category |
| subject | VARCHAR(255) | NO | — | NOT NULL | Short subject line |
| description | TEXT | NO | — | NOT NULL | Detailed description |
| priority | ENUM('low','medium','high','urgent') | NO | 'medium' | — | Priority |
| status | ENUM('open','in_progress','resolved','escalated','closed') | NO | 'open' | — | Complaint FSM status |
| assigned_to | INT UNSIGNED | YES | NULL | FK → sys_users.id | Assigned staff |
| resolution_notes | TEXT | YES | NULL | — | Resolution description |
| resolved_at | TIMESTAMP | YES | NULL | — | Resolution timestamp |
| sla_due_at | TIMESTAMP | YES | NULL | — | SLA deadline computed by HstComplaintService on creation |
| is_escalated | TINYINT(1) | NO | 0 | — | Escalated flag |
| escalated_at | TIMESTAMP | YES | NULL | — | Escalation timestamp |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_cmp_hostel (hostel_id)`, `KEY idx_hst_cmp_room (room_id)`, `KEY idx_hst_cmp_student (reported_by_student_id)`, `KEY idx_hst_cmp_user (reported_by_user_id)`, `KEY idx_hst_cmp_assigned (assigned_to)`, `KEY idx_hst_cmp_sla (sla_due_at)`

---

### 2.9 Visitor & Medical Domain

---

#### `hst_visitor_log` — Hostel visitor register

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel visited |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student being visited |
| visitor_name | VARCHAR(150) | NO | — | NOT NULL | Visitor full name |
| relationship | ENUM('parent','guardian','sibling','relative','other') | NO | — | NOT NULL | Relationship to student |
| visitor_phone | VARCHAR(20) | YES | NULL | — | Visitor contact |
| id_proof_type | VARCHAR(50) | YES | NULL | — | Aadhaar / PAN / Passport / DL |
| id_proof_number_masked | VARCHAR(30) | YES | NULL | — | Last 4 digits only — full number NEVER stored |
| visit_date | DATE | NO | — | NOT NULL | Date of visit |
| in_time | TIME | NO | — | NOT NULL | Check-in time |
| out_time | TIME | YES | NULL | — | Check-out time (NULL = still inside) |
| purpose | VARCHAR(300) | YES | NULL | — | Purpose of visit |
| allowed_by | INT UNSIGNED | YES | NULL | FK → sys_users.id | Warden who authorised |
| is_outside_visiting_hours | TINYINT(1) | NO | 0 | — | Visit outside configured hours flag |
| override_reason | VARCHAR(300) | YES | NULL | — | Warden reason for out-of-hours override |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_vl_hostel_date (hostel_id, visit_date)`, `KEY idx_hst_vl_student (student_id)`, `KEY idx_hst_vl_allowed_by (allowed_by)`

---

#### `hst_sick_bay_log` — Sick bay admission/discharge log

| Column | Type | Nullable | Default | Constraints | Comment |
|---|---|---|---|---|---|
| id | BIGINT UNSIGNED | NO | AUTO_INCREMENT | PK | Primary key |
| hostel_id | BIGINT UNSIGNED | NO | — | FK → hst_hostels.id | Hostel |
| student_id | INT UNSIGNED | NO | — | FK → std_students.id | Student |
| admission_datetime | DATETIME | NO | — | NOT NULL | Admission date and time |
| discharge_datetime | DATETIME | YES | NULL | — | Discharge time (NULL = current inpatient) |
| presenting_symptoms | TEXT | NO | — | NOT NULL | Symptoms on admission |
| initial_diagnosis | VARCHAR(500) | YES | NULL | — | Initial assessment |
| treatment_notes | TEXT | YES | NULL | — | Treatment/medication notes |
| attending_staff_id | INT UNSIGNED | YES | NULL | FK → sys_users.id | Nurse/warden attending |
| discharge_notes | TEXT | YES | NULL | — | Discharge instructions |
| is_hospital_referred | TINYINT(1) | NO | 0 | — | Referred to hospital flag |
| hpc_record_id | BIGINT UNSIGNED | YES | NULL | **NO FK CONSTRAINT** | Soft reference to HPC module record (no enforced FK) |
| parent_notified | TINYINT(1) | NO | 0 | — | Parent notification dispatched |
| + standard audit | — | — | — | — | is_active, created_by, updated_by, created_at, updated_at, deleted_at |

**Indexes:** `KEY idx_hst_sb_hostel_admission (hostel_id, admission_datetime)`, `KEY idx_hst_sb_student (student_id)`, `KEY idx_hst_sb_discharge (discharge_datetime)` — critical for current inpatients query (`WHERE discharge_datetime IS NULL`), `KEY idx_hst_sb_staff (attending_staff_id)`

> **CRITICAL:** `hpc_record_id` is `BIGINT UNSIGNED NULL` with **NO FK CONSTRAINT**. It is a soft reference to the HPC module; no database-enforced constraint. The HPC module reads this column to link records.

---

## Section 3 — Entity Relationship Diagram {#section-3}

```
══════════════════════════════════════════════════════════════════
  EXTERNAL MODULES (read-only by HST — never modified)
══════════════════════════════════════════════════════════════════
  sys_users          — Warden IDs, approved_by, marked_by, created_by
  sys_media          — hst_incident_media.media_id [INT UNSIGNED]
  std_students       — Student FK on all allocation/attendance/leave tables
  sch_academic_term  — Academic session scope on allotments/menus/fee structures
  fin_fee_head_master — No FK; HostelFeeService pushes demands via service call

══════════════════════════════════════════════════════════════════
  HST INFRASTRUCTURE LAYER (Layer 1–4)
══════════════════════════════════════════════════════════════════

  hst_hostels (L1)
    → sys_users (warden_id) [INT UNSIGNED, nullable]
    ↓
  hst_floors (L2) → hst_hostels
    → sys_users (floor_incharge_id) [INT UNSIGNED, nullable]
    ↓
  hst_rooms (L3) → hst_floors
    ↓
  hst_beds (L4) → hst_rooms

══════════════════════════════════════════════════════════════════
  WARDEN & ALLOCATION LAYER (Layer 2 & 5)
══════════════════════════════════════════════════════════════════

  hst_warden_assignments (L2)
    → hst_hostels
    → hst_floors [nullable]
    → sys_users (user_id) [INT UNSIGNED]

  hst_allotments (L5) ← GENERATED COLUMN UNIQUE INDEXES
    → std_students (student_id) [INT UNSIGNED]
    → hst_beds
    → sch_academic_term (academic_session_id) [INT UNSIGNED]
    gen_active_bed_id:     UNIQUE → prevents 2 active allotments to same bed
    gen_active_student_id: UNIQUE → prevents student with 2 active allotments

  hst_room_change_requests (L7)
    → std_students [INT UNSIGNED]
    → hst_allotments (from_allotment_id)
    → hst_rooms (requested_room_id) [nullable]
    → sys_users (approved_by) [INT UNSIGNED, nullable]
    → hst_allotments (new_allotment_id) [nullable]

  hst_room_inventory (L4)
    → hst_rooms
    → std_students (responsible_student_id) [INT UNSIGNED, nullable]

══════════════════════════════════════════════════════════════════
  ATTENDANCE & MOVEMENT LAYER (Layer 6–7)
══════════════════════════════════════════════════════════════════

  hst_attendance (L6)
    → hst_hostels
    → sys_users (marked_by) [INT UNSIGNED]
    UNIQUE (hostel_id, attendance_date, shift)

  hst_attendance_entries (L7) CASCADE DELETE
    → hst_attendance (ON DELETE CASCADE)
    → std_students [INT UNSIGNED]

  hst_movement_log (L5)
    → std_students [INT UNSIGNED]
    → hst_hostels
    → sys_users (gate_pass_issued_by) [INT UNSIGNED, nullable]

══════════════════════════════════════════════════════════════════
  LEAVE PASS LAYER (Layer 7) — cross-references hst_incidents
══════════════════════════════════════════════════════════════════

  hst_leave_passes (L7)
    → std_students [INT UNSIGNED]
    → hst_allotments
    → sys_users (applied_by, approved_by) [INT UNSIGNED]
    → hst_incidents (late_return_incident_id) [nullable — set on late return only]

══════════════════════════════════════════════════════════════════
  MESS LAYER (Layer 5–6)
══════════════════════════════════════════════════════════════════

  hst_mess_weekly_menus (L4)
    → hst_hostels
    → sch_academic_term [INT UNSIGNED]
    UNIQUE (hostel_id, week_start_date, day_of_week, meal_type)

  hst_special_diets (L5)
    → std_students [INT UNSIGNED]
    → hst_hostels

  hst_mess_attendance (L6)
    → hst_hostels
    → std_students [INT UNSIGNED]
    → sys_users (marked_by) [INT UNSIGNED, nullable]
    UNIQUE (hostel_id, attendance_date, meal_type, student_id)

══════════════════════════════════════════════════════════════════
  FEE STRUCTURE LAYER (Layer 4)
══════════════════════════════════════════════════════════════════

  hst_fee_structures (L4) — NO FK to fin_* tables
    → hst_hostels
    → sch_academic_term [INT UNSIGNED]
    UNIQUE (hostel_id, academic_session_id, room_type, meal_plan, effective_from)

══════════════════════════════════════════════════════════════════
  INCIDENTS & COMPLAINTS LAYER (Layer 6–8)
══════════════════════════════════════════════════════════════════

  hst_incidents (L6)
    → std_students [INT UNSIGNED]
    → hst_hostels
    → sys_users (reported_by) [INT UNSIGNED]

  hst_incident_media (L8) CASCADE DELETE
    → hst_incidents (ON DELETE CASCADE)
    → sys_media (media_id) [INT UNSIGNED — matches sys_media.id]

  hst_complaints (L6)
    → hst_hostels
    → hst_rooms [nullable]
    → std_students [INT UNSIGNED, nullable]
    → sys_users (reported_by_user_id, assigned_to) [INT UNSIGNED, nullable]

══════════════════════════════════════════════════════════════════
  VISITOR & MEDICAL LAYER (Layer 5–6)
══════════════════════════════════════════════════════════════════

  hst_visitor_log (L5)
    → hst_hostels
    → std_students [INT UNSIGNED]
    → sys_users (allowed_by) [INT UNSIGNED, nullable]

  hst_sick_bay_log (L6)
    → hst_hostels
    → std_students [INT UNSIGNED]
    → sys_users (attending_staff_id) [INT UNSIGNED, nullable]
    hpc_record_id: BIGINT UNSIGNED NULL — NO FK CONSTRAINT (soft ref)
```

---

## Section 4 — Business Rules (22 Rules) {#section-4}

| Rule ID | Rule | Table/Column | Enforcement Point |
|---|---|---|---|
| BR-HST-001 | A bed can have only one `active` allotment at a time | `hst_allotments.gen_active_bed_id` | `db_constraint` (UNIQUE on generated column) + `service_layer` catch on DuplicateEntry |
| BR-HST-002 | A student can have only one `active` allotment at a time | `hst_allotments.gen_active_student_id` | `db_constraint` (UNIQUE on generated column) + `service_layer` catch |
| BR-HST-003 | Student gender must match hostel type (`boys`/`girls`) before allotment | `hst_allotments` / `hst_hostels.type` / `std_students.gender` | `service_layer` — AllotmentService::validateGender() before INSERT |
| BR-HST-004 | Leave pass `to_date` must be >= `from_date` | `hst_leave_passes.to_date` | `form_validation` — StoreLeavePassRequest cross-field rule |
| BR-HST-005 | Leave pass approval auto-marks ALL shifts during leave period as `leave` | `hst_attendance_entries.status` | `service_layer` — LeavePassService::approve() inside DB::transaction() |
| BR-HST-006 | Leave pass approval auto-marks ALL meals during leave period as `on_leave` | `hst_mess_attendance.status` | `service_layer` — same DB::transaction() as BR-HST-005 |
| BR-HST-007 | Attendance session unique per `(hostel_id, attendance_date, shift)` — duplicate returns existing | `hst_attendance` | `db_constraint` UNIQUE KEY `uq_hst_att_session` |
| BR-HST-008 | Moderate/Serious incidents trigger parent notification automatically | `hst_incidents.severity` | `service_layer` — IncidentService::record() dispatches HostelIncidentRecorded for moderate/serious |
| BR-HST-009 | Hostel deactivation blocked if active allotments exist | `hst_hostels.is_active` / `hst_allotments.status='active'` | `service_layer` — HostelController checks before soft-delete |
| BR-HST-010 | Room status auto-updates: `full` when `current_occupancy >= capacity`; `available` when drops below | `hst_rooms.status` | `service_layer` — AllotmentService updates after each allot/vacate/transfer |
| BR-HST-011 | Prorated fee = `(monthly_rate / 30) × remaining_days_in_month` | `hst_fee_structures` | `service_layer` — HostelFeeService::calculateProratedAmount() |
| BR-HST-012 | Late return: `actual_return_date > to_date` → auto-create incident `is_auto_generated=1, type='late_arrival'` | `hst_incidents.is_auto_generated` / `hst_leave_passes.late_return_incident_id` | `service_layer` — LeavePassService::markReturned() |
| BR-HST-013 | Block/floor wardens see only their assigned hostels/floors | All hst_* queries on warden routes | `service_layer` — WardenScopeMiddleware injects floor_id scope |
| BR-HST-014 | Bulk-vacate requires explicit typed confirmation; all changes logged in sys_activity_logs | `hst_allotments` bulk status change | `form_validation` (BulkVacateRequest confirmation_text='CONFIRM') + `service_layer` audit log |
| BR-HST-015 | Fee structure must exist for room_type + meal_plan before allotment | `hst_fee_structures` | `service_layer` — AllotmentService::validateFeeStructureExists() |
| BR-HST-016 | Student admitted to sick bay is auto-marked `sick_bay` in attendance | `hst_attendance_entries.status='sick_bay'` | `service_layer` — SickBayService::admit() |
| BR-HST-017 | Student absent from roll call (not on leave, not sick_bay) triggers parent notification | `hst_attendance_entries.status='absent'` | `service_layer` — HstAttendanceService dispatches HostelAbsenceDetected |
| BR-HST-018 | Students with attendance below threshold (default 90%) flagged on dashboard | Dashboard query | `scheduled_command` — daily aggregation job + dashboard query |
| BR-HST-019 | Warden may view fee defaulters before approving leave pass (advisory by default) | Leave pass approval screen | `service_layer` — HostelFeeService::getFeeDefaulters() available on approve screen |
| BR-HST-020 | Hostel complaint SLA breach (default 48h high/urgent) triggers auto-escalation | `hst_complaints.sla_due_at` / `status='escalated'` | `scheduled_command` — SendHstComplaintEscalationJob (hourly) |
| BR-HST-021 | Visitor entry outside visiting hours requires warden override with reason | `hst_visitor_log.is_outside_visiting_hours` / `override_reason` | `form_validation` + `service_layer` — VisitorLogController validates hostel.visiting_days_json |
| BR-HST-022 | Student with 3+ incidents in current academic year flagged as `repeated_offender` on dashboard | `hst_incidents` count per student per session | `service_layer` — IncidentService::checkRepeatedOffender() (configurable threshold via sys_settings) |

---

## Section 5 — Workflow State Machines (4 FSMs) {#section-5}

### FSM 1 — Student Allotment Lifecycle

```
                 ┌──────────────────────────────────┐
  APPLY          │         AllotmentService::create()│
  ──────────────►│  Validate: bed.status='available' │
                 │  Validate: gen_active_bed NULL    │
                 │  Validate: gen_active_student NULL│
                 │  Validate: gender match           │
                 │  Validate: fee structure exists   │
                 └──────────────┬───────────────────┘
                                │ All validations pass
                                ▼
                          ┌──────────┐
             ┌────────────│  ACTIVE  │────────────────┐
             │            └──────────┘                │
             │ vacate()                  transfer()    │
             ▼                                        ▼
      ┌───────────┐                       ┌─────────────────┐
      │  VACATED  │                       │   TRANSFERRED   │
      └───────────┘                       └─────────────────┘
      bed → available                     old allot → transferred
      room.current_occupancy -1           old bed → available
      hostel.current_occupancy -1         new allot → active
      HostelFeeService::                  new bed → occupied
        calculateVacatingRefund()         HostelFeeService::
                                           calculateRoomChangeDiff()

      WAITLISTED → ACTIVE on bed available (manual warden promotion Phase 2)
```

**Create Pre-Conditions:** bed.status = 'available' AND gen_active_bed_id IS NULL (DB) AND gen_active_student_id IS NULL (DB) AND student.gender matches hostel.type AND fee_structure exists
**Side Effects on Allotment:**
- INSERT hst_allotments (status='active')
- UPDATE hst_beds.status = 'occupied'
- UPDATE hst_rooms.current_occupancy +1; if >= capacity → status='full'
- UPDATE hst_hostels.current_occupancy +1
- **AFTER** transaction commit → HostelFeeService::pushFeeDemand($allotment)

**Bulk Vacate (year-end):**
- All active allotments → 'vacated' for given academic_session_id
- Requires confirmation_text='CONFIRM' (BulkVacateRequest)
- Audit log written to sys_activity_logs (irreversible action)

---

### FSM 2 — Leave Pass FSM

```
  ┌─────────────────────────────────────────────────────┐
  │                      PENDING                        │
  └──────┬──────────────────────────┬───────────────────┘
         │ approve()                │ reject()
         ▼                          ▼
  ┌────────────┐            ┌───────────────┐
  │  APPROVED  │            │   REJECTED    │
  └──────┬─────┘            └───────────────┘
         │                  (rejection_reason required)
         │ markReturned()   or cancel()
         ├────────────────────────────┐
         │                           │
         ▼                           ▼
  ┌────────────┐            ┌────────────────┐
  │  RETURNED  │            │   CANCELLED    │
  └────────────┘            └────────────────┘
  actual_return_date set     attendance/mess entries reverted
  if late → auto-incident
```

**On APPROVE — DB::transaction() wraps ALL 3 operations:**
1. UPDATE hst_leave_passes: status='approved', approved_by, approved_at
2. markAttendanceForLeave(): For each date in [from_date…to_date], for each shift (morning/evening/night): INSERT/UPDATE hst_attendance_entries status='leave'; recompute session leave_count
3. markMessAttendanceForLeave(): For each date, for each meal (breakfast/lunch/dinner/snacks): INSERT/UPDATE hst_mess_attendance status='on_leave'
4. **After transaction commit:** Dispatch SendHstNotificationJob(new LeavePassApproved($pass)) — queued; notification failure does NOT roll back approval

**On RETURN (markReturned):**
- UPDATE pass: status='returned', actual_return_date
- IF actual_return_date > to_date:
  - IncidentService::createAutoIncident(type='late_arrival', is_auto_generated=1)
  - SET hst_leave_passes.late_return_incident_id = new_incident.id
- Dispatch StudentReturned event (is_late flag included in payload)

**On CANCEL (from approved only):**
- Revert all hst_attendance_entries status='leave' back to 'present' for the leave period
- Revert hst_mess_attendance status='on_leave' back to 'absent'
- UPDATE pass: status='cancelled'

---

### FSM 3 — Incident Severity & Escalation

```
  RECORD ──► OPEN
               │
  severity?
  ├── minor: record only; no auto-notification
  ├── moderate: HostelIncidentRecorded event → parent SMS/push
  └── serious: HostelIncidentRecorded event + prompt Principal escalation
                 is_escalated=1, escalated_at=NOW()

  is_auto_generated=1 (late return): created by LeavePassService::markReturned()
    └── same severity rules apply for notification

  ESCALATION (manual by Chief Warden):
    is_escalated = 1, escalated_at = NOW()

  OPEN / ESCALATED ──► CLOSED (on action_taken filled, manual)

  Warning Letter PDF (on demand):
    IncidentService::generateWarningLetter() → DomPDF → warning_letter_sent=1
```

**Repeated Offender (BR-HST-022):**
- Dashboard query: COUNT(hst_incidents) WHERE student_id = ? AND academic_session scope >= 3
- Threshold configurable via sys_settings key `hostel.incident_escalation_threshold` (default 3)

---

### FSM 4 — Hostel Complaint FSM

```
  CREATE ──► OPEN
    sla_due_at computed by HstComplaintService::computeSlaDeadline(priority):
      urgent/high → NOW() + 48 hours
      medium      → NOW() + 72 hours
      low         → NOW() + 7 days

  OPEN ──► IN_PROGRESS (assign to staff)
    assigned_to = user_id; status='in_progress'

  IN_PROGRESS ──► RESOLVED
    resolution_notes required
    resolved_at = NOW()

  OPEN/IN_PROGRESS ──► ESCALATED (by SendHstComplaintEscalationJob, hourly)
    IF NOW() > sla_due_at AND status NOT IN ('resolved','closed','escalated'):
      status='escalated'; is_escalated=1; escalated_at=NOW(); alert Chief Warden

  ESCALATED ──► RESOLVED or CLOSED (by Chief Warden)

  RESOLVED ──► CLOSED (admin confirmation)
```

---

## Section 6 — Functional Requirements Summary (21 FRs) {#section-6}

| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|
| FR-HST-001 | Building/Hostel Configuration | K1 | hst_hostels | name required max:150, type enum, code unique if set | BR-HST-009 | sys_users |
| FR-HST-002 | Floor Management | K1 | hst_floors | hostel_id exists, floor_number unique within hostel | — | hst_hostels |
| FR-HST-003 | Room Setup | K1 | hst_rooms | floor_id exists, room_number unique within floor, capacity min:1 | BR-HST-010 | hst_floors |
| FR-HST-004 | Bed Management | K1 | hst_beds | room_id exists, bed_label unique within room | — | hst_rooms |
| FR-HST-005 | Student Bed Allotment | K2 | hst_allotments, hst_beds, hst_rooms, hst_hostels | gender match, bed available, fee structure exists, one-active-per-bed, one-active-per-student | BR-HST-001/002/003/010/011/015 | std_students, hst_beds, hst_fee_structures, sch_academic_term |
| FR-HST-006 | Room Change Request Workflow | K2 | hst_room_change_requests, hst_allotments | from_allotment active, reason required | — | hst_allotments |
| FR-HST-007 | Hostel Daily Roll Call | K3 | hst_attendance, hst_attendance_entries | session unique per (hostel, date, shift); counts computed at save | BR-HST-007/017/018 | hst_hostels, std_students |
| FR-HST-008 | In-Out Movement Register | K3 | hst_movement_log | out_time required, student exists, hostel exists | — | std_students, hst_hostels |
| FR-HST-009 | Leave Pass Workflow | K3b | hst_leave_passes, hst_attendance_entries, hst_mess_attendance | to_date >= from_date, allotment active, DB::transaction on approval | BR-HST-004/005/006/012/019 | hst_allotments, hst_attendance, hst_incidents |
| FR-HST-010 | Weekly Mess Menu | K4 | hst_mess_weekly_menus | week_start_date is Monday, slot unique per hostel/week/day/meal | — | hst_hostels, sch_academic_term |
| FR-HST-011 | Special Diet Assignment | K4 | hst_special_diets | student exists, diet_type enum, effective_from required | — | std_students, hst_hostels |
| FR-HST-012 | Mess Attendance Marking | K4 | hst_mess_attendance | slot unique (hostel, date, meal, student); auto-absent on leave approval | BR-HST-006 | hst_hostels, std_students |
| FR-HST-013 | Hostel Fee Structure | K5 | hst_fee_structures | room_type + meal_plan + hostel + session unique per effective_from; amounts >= 0 | BR-HST-011/015 | hst_hostels, sch_academic_term |
| FR-HST-014 | Fee Assignment on Allotment | K5 | hst_fee_structures (read); fin_* (via service) | fee structure must exist; prorated on mid-month allotment | BR-HST-011/015 | HostelFeeService |
| FR-HST-015 | Hostel Complaint Register | K6 | hst_complaints | category enum, subject required, sla_due_at auto-computed | BR-HST-020 | hst_hostels |
| FR-HST-016 | Warden Assignment & Scoped Access | Warden | hst_warden_assignments | user_id exists, hostel_id exists, effective_from DATE, effective_to after from | BR-HST-013 | hst_hostels, hst_floors, sys_users |
| FR-HST-017 | Hostel Visitor Register | Visitor | hst_visitor_log | visitor_name required, relationship enum, in_time required, ID proof masked | BR-HST-021 | hst_hostels, std_students |
| FR-HST-018 | Sick Bay Admission/Discharge | Sick Bay | hst_sick_bay_log | admission_datetime required, capacity check, auto-mark attendance | BR-HST-016 | hst_hostels, std_students, hst_attendance |
| FR-HST-019 | Room Inventory Tracking | Room Inventory | hst_room_inventory | room_id exists, item_name required, quantity min:1, condition enum | — | hst_rooms, std_students |
| FR-HST-020 | Hostel Dashboard | Dashboard | all hst_* (pre-computed counters) | reads current_occupancy, present_count, etc. — no aggregation on load | BR-HST-018/022 | all domains |
| FR-HST-021 | Hostel Reports | Reports | all hst_* | 12 report types; PDF (DomPDF) + CSV (fputcsv) export | — | all domains |

---

## Section 7 — Permission Matrix {#section-7}

| Permission String | School Admin | Chief Warden | Block/Floor Warden | Mess Supervisor | Accountant | Medical Staff |
|---|---|---|---|---|---|---|
| hostel.hostel.viewAny | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| hostel.hostel.create | ✓ | — | — | — | — | — |
| hostel.hostel.update | ✓ | — | — | — | — | — |
| hostel.hostel.delete | ✓ | — | — | — | — | — |
| hostel.floor.viewAny | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| hostel.floor.create | ✓ | — | — | — | — | — |
| hostel.floor.update | ✓ | — | — | — | — | — |
| hostel.room.viewAny | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| hostel.room.create | ✓ | — | — | — | — | — |
| hostel.room.update | ✓ | — | — | — | — | — |
| hostel.bed.viewAny | ✓ | ✓ | ✓ | — | — | — |
| hostel.bed.create | ✓ | — | — | — | — | — |
| hostel.bed.update | ✓ | — | — | — | — | — |
| hostel.warden.manage | ✓ | View | View | — | — | — |
| hostel.allotment.viewAny | ✓ | ✓ | Own floor | — | ✓ | — |
| hostel.allotment.create | ✓ | ✓ | Own floor | — | — | — |
| hostel.allotment.transfer | ✓ | ✓ | Own floor | — | — | — |
| hostel.allotment.vacate | ✓ | ✓ | Own floor | — | — | — |
| hostel.allotment.bulk-vacate | ✓ | — | — | — | — | — |
| hostel.rcr.viewAny | ✓ | ✓ | Own floor | — | — | — |
| hostel.rcr.approve | ✓ | ✓ | Own floor | — | — | — |
| hostel.leave.viewAny | ✓ | ✓ | Own floor | — | ✓ | — |
| hostel.leave.create | ✓ | ✓ | ✓ | — | — | — |
| hostel.leave.approve | ✓ | ✓ | Own floor | — | — | — |
| hostel.leave.print | ✓ | ✓ | ✓ | — | — | — |
| hostel.attendance.viewAny | ✓ | ✓ | Own floor | — | — | — |
| hostel.attendance.create | ✓ | ✓ | Own floor | — | — | — |
| hostel.attendance.update | ✓ | ✓ | Own floor (Chief can unlock) | — | — | — |
| hostel.attendance.lock | ✓ | ✓ | — | — | — | — |
| hostel.movement.manage | ✓ | ✓ | Own floor | — | — | — |
| hostel.incident.viewAny | ✓ | ✓ | Own floor | — | — | — |
| hostel.incident.create | ✓ | ✓ | Own floor | — | — | — |
| hostel.incident.escalate | ✓ | ✓ | — | — | — | — |
| hostel.incident.warning-letter | ✓ | ✓ | ✓ | — | — | — |
| hostel.mess.menu.manage | ✓ | ✓ | View | ✓ | — | View |
| hostel.mess.diet.manage | ✓ | ✓ | View | ✓ | — | ✓ |
| hostel.mess.attendance.mark | ✓ | ✓ | View | ✓ | — | — |
| hostel.fee.viewAny | ✓ | ✓ | — | — | ✓ | — |
| hostel.fee.manage | ✓ | — | — | — | ✓ | — |
| hostel.complaint.viewAny | ✓ | ✓ | Own floor | Own floor | — | — |
| hostel.complaint.create | ✓ | ✓ | Own floor | Own floor | — | — |
| hostel.complaint.manage | ✓ | ✓ | Own floor | Own floor | — | — |
| hostel.visitor.manage | ✓ | ✓ | Own floor | — | — | — |
| hostel.sickbay.manage | ✓ | ✓ | View | — | — | ✓ |
| hostel.inventory.manage | ✓ | ✓ | Own floor | — | — | — |
| hostel.report.view | ✓ | ✓ | Own floor | Mess reports | Fee/defaulter | Sick bay |
| hostel.report.export | ✓ | ✓ | Own floor | Mess | Fee | Sick bay |

**Policy Classes (12):** `HostelPolicy`, `FloorPolicy`, `RoomPolicy`, `BedPolicy`, `AllotmentPolicy`, `LeavePassPolicy`, `AttendancePolicy`, `IncidentPolicy`, `MessMenuPolicy`, `HstComplaintPolicy`, `VisitorLogPolicy`, `SickBayPolicy`

---

## Section 8 — Service Architecture (7 Services) {#section-8}

---

### Service 1: AllotmentService

```
Service:     AllotmentService
File:        app/Services/AllotmentService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  HostelFeeService
Fires:       (no events; HostelFeeService called directly after transaction)
```

**Key Methods:**
```
create(array $data): Allotment
  └── Validate bed available, no active bed conflict, no active student conflict,
      gender match, fee structure exists → DB::transaction: INSERT allotment,
      UPDATE bed/room/hostel counters → AFTER commit: HostelFeeService::pushFeeDemand()

transfer(Allotment $old, Bed $targetBed, array $data): Allotment
  └── DB::transaction: old→'transferred'+vacating_date, old bed→available,
      room.occupancy-1; INSERT new allotment, new bed→occupied, room.occupancy+1,
      hostel.occupancy unchanged → HostelFeeService::calculateRoomChangeDifferential()

vacate(Allotment $allotment, array $data): void
  └── DB::transaction: allotment→'vacated', vacating_date, bed→'available',
      room.occupancy-1, hostel.occupancy-1 → HostelFeeService::calculateVacatingRefund()

bulkVacate(int $academicSessionId, int $doneBy): int
  └── Bulk UPDATE active allotments → 'vacated'; UPDATE all beds to available;
      Recompute room/hostel occupancy; Write to sys_activity_logs (audit); returns count

validateGender(Student $student, Hostel $hostel): void
  └── Throw if hostel.type='boys' && student.gender!='male' (or girls/female mismatch)

checkBedAvailability(Bed $bed): void
  └── Throw if bed.status != 'available'

checkDoubleAllotment(int $bedId, int $studentId): void
  └── Catch DB DuplicateEntry on gen_active_bed_id / gen_active_student_id; throw user-friendly error

validateFeeStructureExists(Hostel $hostel, string $roomType, string $mealPlan, int $sessionId): void
  └── Query hst_fee_structures; throw if none found (BR-HST-015)
```

---

### Service 2: LeavePassService

```
Service:     LeavePassService
File:        app/Services/LeavePassService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  IncidentService
Fires:       LeavePassApproved, LeavePassRejected, StudentReturned
```

**Key Methods:**
```
approve(LeavePass $pass, User $warden): void
  └── [8-step transaction — see Phase 3 pseudocode]
      Steps 1-7 inside DB::transaction(); Step 8 queued notification after commit

reject(LeavePass $pass, User $warden, string $reason): void
  └── UPDATE pass: status='rejected', rejection_reason; Dispatch LeavePassRejected

markReturned(LeavePass $pass, Date $actualReturnDate): void
  └── UPDATE status='returned', actual_return_date;
      IF actualReturnDate > pass.to_date:
        IncidentService::createAutoIncident(type='late_arrival', is_auto_generated=1)
        SET pass.late_return_incident_id = incident.id
      Dispatch StudentReturned(is_late flag)

cancel(LeavePass $pass): void
  └── Revert attendance entries from 'leave' to 'present' for leave period;
      Revert mess attendance from 'on_leave' to 'absent'; UPDATE status='cancelled'

markAttendanceForLeave(LeavePass $pass): void (called within transaction)
  └── For each date in [from_date…to_date]:
        For each shift in ['morning','evening','night']:
          Fetch or create hst_attendance session
          INSERT/UPDATE hst_attendance_entries: student_id, status='leave'
          UPDATE session leave_count += 1

markMessAttendanceForLeave(LeavePass $pass): void (called within transaction)
  └── For each date in [from_date…to_date]:
        For each meal in ['breakfast','lunch','dinner','snacks']:
          INSERT/UPDATE hst_mess_attendance: student_id, status='on_leave'

generatePdf(LeavePass $pass): \Barryvdh\DomPDF\PDF
  └── Load gate pass blade template; return DomPDF instance for download
```

---

### Service 3: HstAttendanceService

```
Service:     HstAttendanceService
File:        app/Services/HstAttendanceService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  (none — direct DB)
Fires:       HostelAbsenceDetected (for absent entries not on leave/sick_bay)
```

**Key Methods:**
```
createSession(array $data): HstAttendance
  └── firstOrCreate on (hostel_id, attendance_date, shift) — returns existing if duplicate

bulkMarkPresent(HstAttendance $session, Collection $studentIds): void
  └── Batch INSERT entries with status='present'; chunk 500 for performance (<3s target)

markEntry(HstAttendance $session, int $studentId, string $status, array $extras): HstAttendanceEntry
  └── upsert single entry; if status='absent' → dispatch HostelAbsenceDetected (queued)

computeAndStoreCounts(HstAttendance $session): void
  └── COUNT entries by status; UPDATE session: present_count, absent_count, leave_count, late_count
      (called once at end of bulk-mark, NOT per entry — performance critical)

lockSession(HstAttendance $session, User $chiefWarden): void
  └── Validate: either within 24h OR user has hostel.attendance.lock permission;
      UPDATE is_locked=1

isEditable(HstAttendance $session, User $user): bool
  └── Return true if NOT locked OR user is Chief Warden with permission
```

---

### Service 4: IncidentService

```
Service:     IncidentService
File:        app/Services/IncidentService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  (none — fires events, DomPDF)
Fires:       HostelIncidentRecorded (for moderate/serious only)
```

**Key Methods:**
```
record(array $data): HstIncident
  └── INSERT incident; IF severity in [moderate, serious] → dispatch HostelIncidentRecorded

createAutoIncident(string $type, int $studentId, int $hostelId, int $createdBy): HstIncident
  └── INSERT incident with is_auto_generated=1, incident_type=$type; apply same severity dispatch rules

escalate(HstIncident $incident, User $chiefWarden): void
  └── UPDATE is_escalated=1, escalated_at=NOW()

notifyParent(HstIncident $incident): void
  └── Dispatch HostelIncidentRecorded even for manual re-notify

generateWarningLetter(HstIncident $incident): \Barryvdh\DomPDF\PDF
  └── Blade template with student, incident, warden signature; UPDATE warning_letter_sent=1

checkRepeatedOffender(int $studentId, int $academicSessionId): bool
  └── COUNT incidents for student in session >= threshold (sys_settings or default 3)
```

---

### Service 5: HostelFeeService

```
Service:     HostelFeeService
File:        app/Services/HostelFeeService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  StudentFee module (service-to-service, no direct FK to fin_* tables)
Fires:       (no events — synchronous service calls)
```

**Key Methods:**
```
lookupFeeStructure(int $hostelId, string $roomType, string $mealPlan, int $sessionId): HstFeeStructure
  └── Query hst_fee_structures WHERE effective_from <= today AND (effective_to IS NULL OR effective_to >= today)

calculateMonthlyFee(HstFeeStructure $structure): float
  └── Return sum: room_rent + mess_charge + electricity + laundry

calculateProratedAmount(HstFeeStructure $structure, Date $eventDate): float
  └── (monthly_rate / 30) × remaining_days_in_month (BR-HST-011)

calculateRoomChangeDifferential(Allotment $old, Bed $newBed, Date $changeDate): array
  └── Credit for old room (remaining days × old daily rate); charge for new room

calculateVacatingRefund(Allotment $allotment, Date $vacatingDate): float
  └── Prorated refund for unused days (monthly_rate / 30 × unused_days)

pushFeeDemand(Allotment $allotment): void
  └── Look up fee structure; calculate; call StudentFee module service to push to fin_fee_head_master
      (no direct DB write to fin_* tables from HST)

pushDamageCharge(HstRoomInventory $item, int $studentId): void
  └── Push estimated_repair_cost as ad-hoc fee item to StudentFee module; set charge_pushed_to_fee=1

getFeeDefaulters(int $hostelId, int $sessionId): Collection
  └── Service-to-service query to StudentFee module for students with outstanding hostel fee balance
```

---

### Service 6: HstComplaintService

```
Service:     HstComplaintService
File:        app/Services/HstComplaintService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  (none)
Fires:       (no events — escalation is direct DB update)
```

**Key Methods:**
```
create(array $data): HstComplaint
  └── INSERT complaint; sla_due_at = computeSlaDeadline(priority); return

assign(HstComplaint $complaint, int $staffUserId): void
  └── UPDATE assigned_to, status='in_progress'

resolve(HstComplaint $complaint, string $notes): void
  └── UPDATE status='resolved', resolution_notes, resolved_at=NOW()

escalate(HstComplaint $complaint): void
  └── UPDATE status='escalated', is_escalated=1, escalated_at=NOW()

checkSlaBreaches(): int
  └── Called by SendHstComplaintEscalationJob hourly;
      Query WHERE sla_due_at < NOW() AND status NOT IN ('resolved','closed','escalated')
      For each: escalate(); alert Chief Warden; returns count escalated

computeSlaDeadline(string $priority): Carbon
  └── urgent/high → now + 48h; medium → now + 72h; low → now + 7 days (BR-HST-020)
```

---

### Service 7: SickBayService

```
Service:     SickBayService
File:        app/Services/SickBayService.php
Namespace:   Modules\Hostel\app\Services
Depends on:  HstAttendanceService
Fires:       SickBayAdmissionRecorded, SickBayDischarged
```

**Key Methods:**
```
admit(array $data): HstSickBayLog
  └── Check capacity: getCurrentOccupancy($hostelId) < hostel.sick_bay_capacity;
      INSERT log; auto-mark attendance 'sick_bay' for current and future shifts (via HstAttendanceService);
      Dispatch SickBayAdmissionRecorded (queued)

updateTreatmentNotes(HstSickBayLog $log, array $data): void
  └── UPDATE treatment_notes, initial_diagnosis

discharge(HstSickBayLog $log, array $data): void
  └── UPDATE discharge_datetime, discharge_notes; resume normal attendance;
      Dispatch SickBayDischarged (queued)

setHospitalReferral(HstSickBayLog $log, ?int $hpcRecordId): void
  └── UPDATE is_hospital_referred=1, hpc_record_id=$hpcRecordId — NO FK enforced; soft link only

getCurrentOccupancy(int $hostelId): int
  └── COUNT WHERE hostel_id=$hostelId AND discharge_datetime IS NULL (indexed query)
```

---

## Section 9 — Integration Contracts {#section-9}

### 9.1 Event Contracts (7 events)

| Event | Fired By | Listener Module | Payload | Action |
|---|---|---|---|---|
| `LeavePassApproved` | LeavePassService::approve() — after DB::transaction() commit | Notification module | student, from_date, to_date, destination, warden_name | Parent SMS/push/email (configurable) |
| `LeavePassRejected` | LeavePassService::reject() | Notification module | student, rejection_reason | Alert to applicant staff |
| `StudentReturned` | LeavePassService::markReturned() | Notification module | student, actual_return_date, is_late | Parent SMS/push |
| `HostelIncidentRecorded` | IncidentService::record()/createAutoIncident() — moderate/serious only | Notification module | student, incident_type, severity, action_taken | Parent SMS/push |
| `HostelAbsenceDetected` | HstAttendanceService::markEntry() — status=absent, not on leave | Notification module | student, date, shift, hostel | Parent SMS/push |
| `SickBayAdmissionRecorded` | SickBayService::admit() | Notification module | student, admission_time, symptoms | Parent SMS/push |
| `SickBayDischarged` | SickBayService::discharge() | Notification module | student, discharge_time | Parent SMS/push |

### 9.2 Event Payload Detail

**LeavePassApproved:**
```php
new LeavePassApproved(LeavePass $pass)
// Payload: student_id, student_name, from_date, to_date, destination,
//          warden_name (approved_by user), guardian_contact
```

**HostelIncidentRecorded:**
```php
new HostelIncidentRecorded(HstIncident $incident)
// Payload: student_id, student_name, incident_type, severity, incident_date,
//          description (truncated 200 chars), action_taken, is_auto_generated
// Listener: skip dispatch if severity='minor'
```

### 9.3 Direct Service Call (not event-based)

| Integration | Mechanism | Direction | Description |
|---|---|---|---|
| HostelFeeService → StudentFee module | Direct service-to-service call within tenant context | Outbound | On allotment: pushes room_rent + mess_charge + ancillary as separate fee items to fin_fee_head_master. No direct DB write from HST to fin_* tables. No FK from hst_* to fin_*. |

### 9.4 Inbound Dependencies (read-only by HST)

| Table | Module | HST Usage |
|---|---|---|
| `std_students` | StudentProfile | student_id FK in all allocation, attendance, leave, incident, mess, sick bay tables |
| `sch_academic_term` | SchoolSetup | Academic session scoping; **Note:** requirement says sch_academic_sessions — actual DDL is sch_academic_term |
| `sys_users` | System | Warden IDs, approved_by, marked_by, created_by — all `INT UNSIGNED` |
| `sys_media` | System | hst_incident_media.media_id — `INT UNSIGNED` (matches sys_media.id) |
| `sys_activity_logs` | System | Audit trail for bulk-vacate, allotment changes, leave approvals |

---

## Section 10 — Non-Functional Requirements {#section-10}

| NFR | Requirement | Implementation Note |
|---|---|---|
| Performance: Bulk attendance | 500 students < 3 seconds | Batch INSERT with chunk(500); computeAndStoreCounts() called once at end — not per entry |
| Performance: Dashboard load | < 2 seconds | `hst_hostels.current_occupancy` and `hst_attendance.present_count` are pre-computed denormalized counters; no aggregation on dashboard load |
| Performance: Mess bulk mark | 300 students × 1 meal < 2 seconds | Batch INSERT with upsert; single DB round-trip |
| Performance: Pending returns | Indexed query | `INDEX (hostel_id, movement_date)` + `INDEX (student_id, in_time)` — query: `WHERE hostel_id=? AND in_time IS NULL AND movement_date=?` |
| Reliability: Leave approval | Notification failure ≠ rollback | DB::transaction() covers ONLY pass update + attendance + mess. Notification dispatched to queue AFTER commit; queue failure is independent |
| Reliability: Sick bay notification | Queued dispatch | SickBayAdmissionRecorded dispatched via SendHstNotificationJob to queue — UI not blocked |
| Reliability: Complaint SLA | Scheduled job | SendHstComplaintEscalationJob runs hourly via Laravel Scheduler |
| Data Integrity: No tenant_id | Tenancy via separate DB | No `tenant_id` column on any `hst_*` table |
| Data Integrity: Active allotment | DB-level prevention | UNIQUE on gen_active_bed_id + gen_active_student_id (generated columns) |
| Data Integrity: Leave dates | FormRequest | StoreLeavePassRequest: to_date >= from_date cross-field rule |
| Data Integrity: Gender match | Service layer | AllotmentService::validateGender() before INSERT |
| Data Integrity: Attendance UNIQUE | DB constraint | UNIQUE (hostel_id, attendance_date, shift) — no duplicate sessions |
| Data Integrity: Attendance lock | Application rule | is_locked=1 blocks UPDATE except Chief Warden (permission check) |
| Security: All routes | auth middleware | All hostel.* routes: auth + tenant + EnsureTenantHasModule:Hostel |
| Security: Warden scope | WardenScopeMiddleware | Injected floor_id scope into query builder before controller executes; block warden cannot access other floors |
| Security: Visitor ID proof | Masking | id_proof_number_masked stores ONLY last 4 digits; full number NEVER stored in DB |
| Security: Parent notifications | Data isolation | Each notification payload contains only the target student's data |
| Accessibility: Attendance UI | Tablet-optimised | One-tap bulk mark with individual exceptions; Alpine.js toggle; designed for warden roll-call workflow |
| Accessibility: PDF exports | A4 DomPDF | Leave pass gate pass PDF + leave register PDF + warning letter PDF — all A4, DomPDF renderer |

---

## Section 11 — Test Plan Outline {#section-11}

### 11.1 Feature Tests (Pest) — 11 files

| File | Test Count | Key Scenarios |
|---|---|---|
| `HostelInfrastructureTest` | ~12 | Create hostel/floor/room/bed; gender type on hostel; capacity auto-update; deactivation blocked with active allotments (BR-HST-009) |
| `AllotmentTest` | ~14 | Allot student to bed; prevent double-allotment on same bed (DuplicateEntry); prevent two active allotments per student; gender mismatch rejection (BR-HST-003); vacate reverts bed status; transfer executes correctly; bulk-vacate with audit log (BR-HST-014); fee structure missing blocks allotment |
| `RoomChangeRequestTest` | ~6 | Submit request; approve executes AllotmentService::transfer(); reject with reason; fee recalculation on approval |
| `LeavePassTest` | ~10 | Apply leave pass; approve dispatches queued notification (Event::fake()); attendance auto-marked for full date range (BR-HST-005); mess auto-marked on approval (BR-HST-006); mark returned; late return creates auto-incident with is_auto_generated=1 (BR-HST-012); cancel reverts entries; transaction failure rolls back all 3 operations |
| `HstAttendanceTest` | ~8 | Create session; bulk mark present; mark individual exceptions; duplicate session returns existing (BR-HST-007); summary counts computed from entries and stored; lock after 24h; Chief Warden can edit locked session |
| `IncidentTest` | ~8 | Record minor (no notification); record moderate (HostelIncidentRecorded dispatched); record serious (notification + escalation prompt); auto-incident from late return; repeated offender flagged at 3+ incidents (BR-HST-022) |
| `MessMenuTest` | ~7 | Create weekly menu; duplicate slot prevention; copy-week function; special diet assignment; mess auto-absent on leave approval (BR-HST-006) |
| `HstFeeTest` | ~8 | Configure fee structure; calculate monthly fee on allotment; prorated mid-month allotment (`rate/30 × remaining_days`); prorated vacating refund; room change differential (BR-HST-011) |
| `HstComplaintTest` | ~6 | Lodge complaint with SLA deadline computed; assign to staff; resolve; SLA breach triggers escalation by SendHstComplaintEscalationJob (BR-HST-020) |
| `SickBayTest` | ~7 | Admit student; attendance auto-marked sick_bay (BR-HST-016); parent notification dispatched (Event::fake()); treatment notes update; discharge; hospital referral sets hpc_record_id (no FK error); capacity check blocks admission when full |
| `VisitorLogTest` | ~5 | Log visitor; checkout sets out_time; out-of-hours requires override_reason (BR-HST-021); ID proof stored as last 4 digits only |

### 11.2 Unit Tests (PHPUnit) — 4 files

| File | Scenarios |
|---|---|
| `AllotmentServiceTest` | Bed availability logic (available/occupied/maintenance); gender validation (boys/girls/mixed hostel); double-allotment detection (bed + student) |
| `LeavePassServiceTest` | Date range calculation for attendance auto-mark (from_date to to_date inclusive); late return detection (actual > to_date) |
| `HostelFeeServiceTest` | Prorated mid-month allotment: (rate/30 × remaining_days); mid-month vacate refund; room change differential (credit old + charge new) |
| `HstComplaintServiceTest` | SLA due_at computation: urgent/high → +48h, medium → +72h, low → +7 days (BR-HST-020) |

### 11.3 Policy Tests

`HostelPolicyTest`:
- School Admin has full access to all hostel CRUD
- Chief Warden can approve leave pass, cannot bulk-vacate
- Block Warden can only view/manage own-floor data (WardenScopeMiddleware tested)
- Mess Supervisor can access mess routes only; cannot approve leave pass

### 11.4 Test Data Requirements

**Required Factories:**
```
HostelFactory      — type, sick_bay_capacity, current_occupancy=0
FloorFactory       — hostel_id, floor_number
RoomFactory        — floor_id, room_type, capacity, status='available', current_occupancy=0
BedFactory         — room_id, bed_label, status='available'
AllotmentFactory   — student_id, bed_id, academic_session_id, status='active'
LeavePassFactory   — student_id, allotment_id, from_date, to_date, status='pending'
```

**Mock Strategy:**
```
Event::fake()  — for LeavePassApproved, LeavePassRejected, HostelIncidentRecorded,
                 HostelAbsenceDetected, SickBayAdmissionRecorded, SickBayDischarged
Queue::fake()  — for SendHstNotificationJob, SendHstComplaintEscalationJob
Bus::fake()    — for Artisan command tests (hst:escalate-complaints, hst:send-attendance-alerts)
Mock HostelFeeService::pushFeeDemand() in AllotmentTest — avoid StudentFee dependency
DB::transaction() rollback test in LeavePassTest — simulate failure in markMessAttendanceForLeave()
  → verify pass status NOT updated (full rollback)
```

---

## Phase 1 Quality Gate Verification

- [x] All 21 hst_* tables appear in Section 2 (4 infra + 1 warden + 3 allocation + 3 attendance + 1 leave + 3 mess + 1 fee + 3 incidents/complaints + 2 visitor/medical = 21)
- [x] All 21 FRs (HST-001 to HST-021) appear in Section 6
- [x] All 22 business rules (BR-HST-001 to BR-HST-022) in Section 4 with enforcement point
- [x] All 4 FSMs documented with ASCII state diagram and side effects
- [x] All 7 services listed with key method signatures in Section 8
- [x] All 7 events + 1 direct service call documented in Section 9
- [x] `hst_allotments` dual generated-column UNIQUE indexes documented (active-bed + active-student)
- [x] `hst_incident_media.media_id → sys_media.id` noted as `INT UNSIGNED` (not BIGINT)
- [x] `hst_sick_bay_log.hpc_record_id` noted as soft FK (no DB constraint)
- [x] Leave pass approval is a single `DB::transaction()` covering 3 operations
- [x] `HostelFeeService` — no FK from hst_* to fin_* noted; service-to-service call only
- [x] BR-HST-011 prorated fee formula: `(monthly_rate / 30) × remaining_days_in_month`
- [x] BR-HST-012 (late return auto-incident with is_auto_generated=1) enforcement: service_layer
- [x] `WardenScopeMiddleware` documented with floor-level scoping
- [x] Attendance session denormalized counts — computed and stored at save time, NOT on load
- [x] No `tenant_id` column mentioned in any table definition
- [x] Permission matrix covers School Admin / Chief Warden / Block Warden / Mess Supervisor / Accountant / Medical Staff
- [x] **FK Type resolution documented (Section 1.5):** cross-module FKs use INT UNSIGNED to match actual parent table types
- [x] **Table name fix documented:** `sch_academic_sessions` in requirement → actual DDL is `sch_academic_term`
