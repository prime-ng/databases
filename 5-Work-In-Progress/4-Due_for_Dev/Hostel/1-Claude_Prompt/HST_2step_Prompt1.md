# HST — Hostel Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **HST (Hostel Management)** module using `HST_Hostel_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `HST_FeatureSpec.md` — Feature Specification
2. `HST_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `HST_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** Hostel Management — Complete residential hostel operations for Indian K-12 boarding schools.
Tables: `hst_*` (21 tables across infrastructure, allocation, attendance, leave, mess, fee, incidents, complaints, visitor log, sick bay, room inventory).

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
MODULE_CODE       = HST
MODULE            = Hostel
MODULE_DIR        = Modules/Hostel/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = K                              # Hostel Management in RBS v4.0 (K1–K6)
DB_TABLE_PREFIX   = hst_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/Hostel/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/HST_Hostel_Requirement.md

FEATURE_FILE      = HST_FeatureSpec.md
DDL_FILE_NAME     = HST_DDL_v1.sql
DEV_PLAN_FILE     = HST_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — HST (HOSTEL MANAGEMENT) MODULE

### What This Module Does

The Hostel module provides a **complete residential hostel operations system** for Indian K-12 boarding schools on the Prime-AI SaaS platform. It covers the full lifecycle from infrastructure setup (building → floor → room → bed hierarchy) through student bed allotment, daily roll-call attendance (3 shifts: morning/evening/night), leave pass management with parent notifications, mess meal planning and attendance, hostel fee integration with StudentFee module, incident/discipline management with warning letter generation (DomPDF), hostel-internal complaint tracking with SLA escalation, visitor register, sick bay log, and room inventory — all scoped by warden hierarchy with strict role-based data access.

**K1 — Room & Bed Management:**
- Building/hostel configuration: type (boys/girls/mixed), gender restrictions, chief warden assignment, sick bay capacity, visiting day/hour config, facilities list
- Floor hierarchy within hostel; floor incharge assignment; wing modelled as separate hostel or floor label
- Room setup: room_type ENUM (single/double/triple/dormitory), capacity, amenities JSON, status auto-update (available/full/maintenance)
- Bed management: bed label within room, status (available/occupied/maintenance), condition (good/fair/poor)
- `hst_hostels.current_occupancy` + `hst_rooms.current_occupancy` are denormalized counters — updated synchronously by `AllotmentService` on every allot/vacate/transfer

**K2 — Student Room Allocation:**
- Bed allotment with gender validation, double-allotment prevention, fee auto-calculation via `HostelFeeService`
- Vacate, transfer (old allotment → 'transferred'; new allotment 'active'), bulk academic-year reset
- Waitlist support for full rooms
- Room change request workflow: pending → approved/rejected; on approval calls `AllotmentService::transfer()`

**K3 — Hostel Attendance:**
- 3 roll calls daily (morning/evening/night); one session per (hostel, date, shift) — duplicate blocked
- Per-student: present/absent/leave/home/late/sick_bay; bulk-mark with individual exceptions
- Summary counts (present_count, absent_count, leave_count, late_count) stored on `hst_attendance` session row — NOT aggregated on every load
- Attendance lock after 24 hours (Chief Warden override only)
- In-out movement register: departure, expected return, actual return; pending returns dashboard

**K3b — Leave Pass Management:**
- Leave pass FSM: pending → approved/rejected; approved → returned/cancelled
- On APPROVAL: `LeavePassService::approve()` runs inside `DB::transaction()` — updates pass status + auto-marks ALL shifts during leave period as 'leave' in `hst_attendance_entries` + auto-marks ALL meals as 'on_leave' in `hst_mess_attendance`
- On RETURN: if `actual_return_date > to_date` → `IncidentService::createAutoIncident(type='late_arrival', is_auto_generated=1)` → `hst_leave_passes.late_return_incident_id` set (nullable FK)
- DomPDF: leave pass PDF gate pass + full leave register PDF

**K4 — Mess Management:**
- Weekly menu: per hostel per academic session per week per day per meal (Mon–Sun × breakfast/lunch/dinner/snacks); copy-week template
- Special diet assignment per student: diabetic / jain_vegetarian / gluten_free / nut_allergy / religious_fasting / custom; with effective from/to dates
- Meal attendance: present/absent/on_leave/opted_out per student per meal; special diet served flag; monthly summary for billing

**K5 — Hostel Fee Integration:**
- Fee structure per (hostel, academic_session, room_type, meal_plan): room_rent_monthly, mess_charge_monthly, electricity_charge_monthly, laundry_charge_monthly, security_deposit; effective from/to
- **Prorated fee formula:** `(monthly_rate / 30) × remaining_days_in_month` (BR-HST-011)
- `HostelFeeService::pushFeeDemand()` — no FK from hst_* to fin_* tables — service-to-service call within tenant context; pushes to `fin_fee_head_master` via StudentFee module API
- Prorated room change differential + vacating refund

**K6 — Hostel Complaint Register:**
- Hostel-internal maintenance/service complaint register (`hst_complaints`) — SEPARATE from school-wide Complaint module (`cmp_*`)
- SLA-based auto-escalation: `sla_due_at` computed on creation; `SendHstComplaintEscalationJob` runs hourly via scheduler
- Status FSM: open → in_progress → resolved/escalated/closed

**Additional Sub-modules:**
- **Warden Management**: Chief/Block/Floor/Assistant warden assignment with effective from/to dates (rotation); scoped data access enforced via `WardenScopeMiddleware`
- **Visitor Log**: Hostel-specific visitor register (SEPARATE from Frontdesk `fnt_*`); visiting hours enforcement; ID proof masked (last 4 digits only)
- **Medical/Sick Bay**: Admission/discharge/treatment notes; auto-marks attendance as 'sick_bay'; parent notification on admission; hospital referral flag links to HPC module (soft FK — no DB constraint)
- **Room Inventory**: Furniture/fixtures per room with condition tracking, damage reporting, repair workflow, cost recovery via StudentFee

### Architecture Decisions

- **Single Laravel module** (`Modules\Hostel`) — all K1–K6 sub-modules + Warden/Visitor/SickBay/RoomInventory in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `hostel/` | Route name prefix: `hostel.`
- **Warden scoped access**: `WardenScopeMiddleware` applied on warden-facing routes; block/floor wardens see only their assigned floors; Chief Warden has full hostel-wide access
- **Double-allotment prevention** (TWO rules): One active allotment per bed + one active allotment per student — both enforced via GENERATED column partial UNIQUE indexes on `hst_allotments`:
  - `gen_active_bed_id BIGINT GENERATED ALWAYS AS (IF(status='active', bed_id, NULL)) STORED` + `UNIQUE (gen_active_bed_id)`
  - `gen_active_student_id BIGINT GENERATED ALWAYS AS (IF(status='active', student_id, NULL)) STORED` + `UNIQUE (gen_active_student_id)`
- **Leave pass approval transaction**: `DB::transaction()` wraps pass status update + ALL attendance entries for leave period + ALL mess attendance entries for leave period (atomic — one failure rolls back all)
- **StudentFee integration**: No direct FK from `hst_*` to `fin_*` tables — `HostelFeeService` calls StudentFee module service methods within tenant context; fee demands pushed as service calls, not DB writes from HST
- **HPC module link** (sick bay): `hst_sick_bay_log.hpc_record_id` is a soft FK — `BIGINT UNSIGNED NULL` with NO FK constraint — set when student is referred to hospital; HPC module reads and links on its side
- **Module Scale (v2)**: Note: Section 1.2 of req says "20 tables" but Section 5 DDL lists 21 tables (5.1–5.21); use 21 from Section 5 as the authoritative count

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 20 (from Section 12.2) |
| Models | 21 |
| Services | 7 |
| FormRequests | 27 (from Section 12.3) |
| Policies | 12 |
| hst_* tables | 21 (Section 5.1–5.21; spec header says 20 — use 21) |
| Blade views (estimated) | ~65 |
| Seeders | 2 + 1 runner |
| Events | 7 |
| Queued Jobs | 2 |

### Complete Table Inventory

**Infrastructure (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `hst_hostels` | Hostel/building config | UNIQUE `(code)` nullable; warden_id nullable FK → sys_users |
| 2 | `hst_floors` | Floor within hostel | UNIQUE `(hostel_id, floor_number)` |
| 3 | `hst_rooms` | Room within floor | UNIQUE `(floor_id, room_number)`; status ENUM |
| 4 | `hst_beds` | Bed within room | UNIQUE `(room_id, bed_label)`; status + condition ENUM |

**Warden Management (1 table):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 5 | `hst_warden_assignments` | Warden rotation log | INDEX `(hostel_id, floor_id, effective_to)` for current-warden lookup |

**Allocation (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 6 | `hst_allotments` | Student bed allotment | TWO generated-column UNIQUE indexes for active-bed + active-student; INDEX `(student_id, status)`, `(bed_id, status)` |
| 7 | `hst_room_change_requests` | Room transfer requests | FK → hst_allotments (current + new); status ENUM |
| 8 | `hst_room_inventory` | Room furniture/fixtures | FK → hst_rooms; repair_status ENUM |

**Attendance (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 9 | `hst_attendance` | Roll-call session | UNIQUE `(hostel_id, attendance_date, shift)`; denormalized counts |
| 10 | `hst_attendance_entries` | Per-student row in session | UNIQUE `(attendance_id, student_id)`; CASCADE DELETE from hst_attendance |
| 11 | `hst_movement_log` | In-out gate register | INDEX `(hostel_id, movement_date)`, `(student_id, in_time)` |

**Leave Pass (1 table):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 12 | `hst_leave_passes` | Leave pass FSM | FK → hst_allotments; `late_return_incident_id` nullable FK → hst_incidents |

**Mess Management (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 13 | `hst_mess_weekly_menus` | Weekly meal plan | UNIQUE `(hostel_id, week_start_date, day_of_week, meal_type)` |
| 14 | `hst_special_diets` | Student diet assignment | FK → std_students + hst_hostels; effective from/to dates |
| 15 | `hst_mess_attendance` | Meal attendance per student | UNIQUE `(hostel_id, attendance_date, meal_type, student_id)` |

**Fee Structure (1 table):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 16 | `hst_fee_structures` | Room-type fee rates per session | UNIQUE `(hostel_id, academic_session_id, room_type, meal_plan, effective_from)` |

**Incidents & Complaints (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 17 | `hst_incidents` | Discipline incident register | FK → std_students + hst_hostels; `is_auto_generated` flag |
| 18 | `hst_incident_media` | Incident photo/doc attachments | FK → hst_incidents CASCADE DELETE; media_id → sys_media (`INT UNSIGNED`) |
| 19 | `hst_complaints` | Hostel maintenance/service complaints | FK → hst_hostels + hst_rooms nullable + std_students nullable; `sla_due_at` TIMESTAMP |

**Visitor & Medical (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 20 | `hst_visitor_log` | Hostel visitor register | INDEX `(hostel_id, visit_date)`, `(student_id)` |
| 21 | `hst_sick_bay_log` | Sick bay admission/discharge | `hpc_record_id` BIGINT UNSIGNED NULL — NO FK constraint (soft ref to HPC); INDEX `(discharge_datetime)` for current inpatients |

**Existing Tables REUSED (Hostel reads from; never modifies schema):**
| Table | Source | Hostel Usage |
|---|---|---|
| `std_students` | StudentProfile (STD) | Student FK in allotments, attendance, leave passes, incidents, mess, sick bay |
| `sch_academic_sessions` | SchoolSetup (SCH) | Academic year scoping on allotments, fee structures, mess menus |
| `sys_users` | System | Warden IDs, approved_by, marked_by, created_by |
| `sys_media` | System | `hst_incident_media.media_id` — **use `INT UNSIGNED`** (not BIGINT) |
| `sys_activity_logs` | System | Audit trail for bulk-vacate, allotment changes |
| `ntf_notifications` | Notification | Leave pass, incident, absence, sick bay parent notifications |
| `fin_fee_head_master` | StudentFee (FIN) | Service-only integration — no FK; HostelFeeService pushes fee demands |

### Cross-Module Integration (Service Events + Direct Service Calls)
```
On Bed Allotted:
  HostelFeeService::pushFeeDemand(allotment) → StudentFee module
  → Pushes room_rent + mess_charge + ancillary as separate fee items to fin_fee_head_master
  (service-to-service call — no direct DB write to fin_* tables from HST)

On Leave Pass Approved (DB::transaction()):
  1. UPDATE hst_leave_passes: status='approved'
  2. INSERT/UPDATE hst_attendance_entries status='leave' for ALL (hostel,date,shift) in date range
  3. INSERT/UPDATE hst_mess_attendance status='on_leave' for ALL meals in date range
  4. event(new LeavePassApproved($pass)) → Notification module → parent SMS/push

On Student Returned Late (actual_return_date > to_date):
  IncidentService::createAutoIncident(type='late_arrival', is_auto_generated=1)
  → hst_leave_passes.late_return_incident_id = new_incident_id

On Incident Recorded (moderate/serious):
  event(new HostelIncidentRecorded($incident)) → Notification → parent SMS/push

On Absent from Roll Call (not on leave, not sick_bay):
  event(new HostelAbsenceDetected($entry)) → Notification → parent SMS/push

On Sick Bay Admission:
  SickBayService → auto-mark hst_attendance_entries as 'sick_bay' for admission period
  event(new SickBayAdmissionRecorded($log)) → Notification → parent SMS/push
  If is_hospital_referred=1: set hpc_record_id (soft FK to HPC module)

On Hostel Complaint SLA Breach:
  SendHstComplaintEscalationJob (hourly scheduler) → escalates to Chief Warden

Note: HostelFeeService fires no events — direct service-to-service calls only.
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — HST v2 requirement (Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: std_students, sch_academic_sessions, sys_users, sys_media (use exact column names; confirm sys_media.id is INT UNSIGNED)

### Phase 1 Task — Generate `HST_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope sub-modules (K1–K6 + Warden Mgmt + Visitor Log + Medical/Sick Bay + Room Inventory — verbatim from req v2 Section 3.1)
- Out-of-scope items: student academic/class records (std_*), school fee collection + payment (fin_* — integration only), full medical records (HPC), campus-wide visitor mgmt (fnt_*), day-scholar canteen (mes_*), staff quarters, CCTV hardware
- Module scale table (controller / model / service / FormRequest / policy / table counts)

#### Section 2 — Entity Inventory (All 21 Tables)
For each `hst_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Infrastructure** (hst_hostels, hst_floors, hst_rooms, hst_beds)
- **Warden Management** (hst_warden_assignments)
- **Allocation** (hst_allotments, hst_room_change_requests, hst_room_inventory)
- **Attendance** (hst_attendance, hst_attendance_entries, hst_movement_log)
- **Leave Pass** (hst_leave_passes)
- **Mess Management** (hst_mess_weekly_menus, hst_special_diets, hst_mess_attendance)
- **Fee Structure** (hst_fee_structures)
- **Incidents & Complaints** (hst_incidents, hst_incident_media, hst_complaints)
- **Visitor & Medical** (hst_visitor_log, hst_sick_bay_log)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 21 tables grouped by layer (hst_* vs cross-module reads from std_*/sch_*/sys_*/fin_*).
Use `→` for FK direction (child → parent).

Critical cross-module FKs to highlight:
- `hst_allotments.student_id → std_students.id` (student gender validated before allotment)
- `hst_allotments.academic_session_id → sch_academic_sessions.id`
- `hst_incident_media.media_id → sys_media.id` (**INT UNSIGNED**, not BIGINT)
- `hst_sick_bay_log.hpc_record_id` — **NO FK constraint** (soft reference, nullable BIGINT UNSIGNED)
- `hst_fee_structures`: no FK to `fin_*` — StudentFee integration is service-only
- `hst_leave_passes.late_return_incident_id → hst_incidents.id` (nullable; set on late return only)
- `hst_allotments` dual generated-column unique indexes (active bed + active student)

#### Section 4 — Business Rules (22 rules)
For each rule, state:
- Rule ID (BR-HST-001 to BR-HST-022)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event` | `scheduled_command`

Critical rules to emphasise:
- BR-HST-001: One active allotment per bed — generated-column partial UNIQUE on `hst_allotments`
- BR-HST-002: One active allotment per student — same mechanism, separate generated column
- BR-HST-003: Gender match (student vs hostel type) — AllotmentService validates before INSERT
- BR-HST-005: Leave approval auto-marks ALL attendance entries — inside DB::transaction()
- BR-HST-006: Leave approval auto-marks ALL mess attendance — same transaction as BR-HST-005
- BR-HST-007: Attendance session UNIQUE per (hostel_id, attendance_date, shift) — db_constraint
- BR-HST-011: Prorated fee = (monthly_rate / 30) × remaining_days_in_month
- BR-HST-012: Late return auto-creates incident with `is_auto_generated=1` — service_layer
- BR-HST-013: Warden scope — WardenScopeMiddleware enforces floor-level data restriction
- BR-HST-015: Fee structure must exist for room_type + meal_plan before allotment — service_layer
- BR-HST-022: 3+ incidents in academic year flags student as `repeated_offender` on dashboard

#### Section 5 — Workflow State Machines (4 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, notifications)

FSMs to document:
1. **Student Allotment Lifecycle** — `active → vacated/transferred/waitlisted`
   - Create: validate gender + bed availability + no double-allotment + fee structure exists; INSERT allotment; UPDATE bed.status='occupied'; UPDATE room.current_occupancy +1; UPDATE hostel.current_occupancy +1; HostelFeeService::pushFeeDemand()
   - Transfer: old allotment → 'transferred'; vacating_date=today; bed → 'available'; room.current_occupancy -1; new allotment 'active'; HostelFeeService::calculateRoomChangeDifferential()
   - Vacate: allotment → 'vacated'; bed → 'available'; room.current_occupancy -1; HostelFeeService::calculateVacatingRefund() if mid-month
   - Bulk Vacate (year-end): all active allotments → 'vacated'; audit log written to sys_activity_logs; irreversible

2. **Leave Pass FSM** — `pending → approved/rejected; approved → returned/cancelled`
   - On APPROVE: DB::transaction wraps: pass.status='approved' + ALL attendance entries marked 'leave' + ALL mess entries marked 'on_leave'; LeavePassApproved event dispatched (queued notification)
   - On RETURN: pass.status='returned', actual_return_date set; if actual_return_date > to_date → IncidentService::createAutoIncident(is_auto_generated=1, type='late_arrival') + pass.late_return_incident_id set; StudentReturned event
   - On REJECT: pass.status='rejected', rejection_reason required
   - On CANCEL: only from 'approved'; attendance/mess entries reverted; pass.status='cancelled'

3. **Incident Severity & Escalation** — `open → escalated/closed`
   - Minor: record only; no auto-notification
   - Moderate: HostelIncidentRecorded event dispatched → parent SMS/push
   - Serious: HostelIncidentRecorded event + prompt for Principal escalation; is_escalated=1, escalated_at set
   - Auto-incident (late return): is_auto_generated=1, incident_type='late_arrival'; same severity rules apply
   - Warning letter PDF generated via DomPDF on demand; warning_letter_sent=1 set

4. **Hostel Complaint FSM** — `open → in_progress → resolved/escalated/closed`
   - Create: compute sla_due_at based on priority (default: 48h for high/urgent from req BR-HST-020)
   - Assign: assigned_to set; status='in_progress'
   - Resolve: resolution_notes required; resolved_at set; status='resolved'
   - SLA Breach (hourly `SendHstComplaintEscalationJob`): if status not resolved AND NOW() > sla_due_at → status='escalated'; is_escalated=1; escalated_at set; alert Chief Warden

#### Section 6 — Functional Requirements Summary (21 FRs)
For each FR-HST-001 to FR-HST-021 (FR-HST-019 is Room Inventory; FR-HST-020 is Dashboard; FR-HST-021 is Reports):
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by sub-module (K1–K6 + Warden + Visitor + Sick Bay + Room Inventory + Dashboard/Reports per req v2 Sections 4.1–4.12).

#### Section 7 — Permission Matrix
| Permission String | School Admin | Chief Warden | Block/Floor Warden | Mess Supervisor | Accountant | Medical Staff |
|---|---|---|---|---|---|---|

Derive permissions from req v2 Section 10 (Role-Permission Matrix). Include:
- `hostel.hostel.*` (infrastructure CRUD)
- `hostel.allotment.*` (allot / vacate / transfer / bulk-vacate)
- `hostel.leave.*` (create / approve / print)
- `hostel.attendance.*` (create / update / lock)
- `hostel.incident.*` (create / escalate / warning-letter)
- `hostel.mess.*` (menu.manage / diet.manage / attendance.mark)
- `hostel.fee.*` (viewAny / manage)
- `hostel.complaint.*` (create / manage)
- `hostel.visitor.manage`
- `hostel.sickbay.manage`
- `hostel.inventory.manage`
- `hostel.report.*` (view / export)
- `hostel.warden.manage`
Which Policy class enforces each permission (12 policies from req v2 Section 10.3)

#### Section 8 — Service Architecture (7 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\Hostel\app\Services
Depends on:  [other services it calls]
Fires:       [events it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **AllotmentService** — create allotment (validate gender + bed availability + double-allotment + fee structure exists); update bed.status, room.current_occupancy, hostel.current_occupancy; transfer() vacates old + creates new + fee differential; bulkVacate() (academic year reset with audit log); validateGender(); checkBedAvailability(); checkDoubleAllotment()
2. **LeavePassService** — approve() runs DB::transaction (status + attendance + mess entries atomically); reject(); markReturned() detects late return → calls IncidentService::createAutoIncident(); cancel(); markAttendanceForLeave() (insert/update all shifts in date range); markMessAttendanceForLeave() (insert/update all meals in date range); generatePdf() via DomPDF
3. **HstAttendanceService** — createSession() (duplicate check via UNIQUE constraint); bulkMarkPresent(); markEntry() (per-student status); computeAndStoreCounts() (updates present_count/absent_count/leave_count/late_count on session row); lockSession() (Chief Warden only after 24h); isEditable()
4. **IncidentService** — record(); createAutoIncident() (from late return, is_auto_generated=1); escalate() (sets is_escalated=1); notifyParent() (dispatches HostelIncidentRecorded); generateWarningLetter() via DomPDF; classifyAutoEscalation() (serious → prompt for Principal); checkRepeatedOffender() (3+ incidents in academic year flag)
5. **HostelFeeService** — lookupFeeStructure(hostel, roomType, mealPlan, academicSession); calculateMonthlyFee(); calculateProratedAmount(allotmentDate or vacatingDate); calculateRoomChangeDifferential(oldAllotment, newAllotment); pushFeeDemand(allotment) → calls StudentFee service; calculateVacatingRefund(); pushDamageCharge(roomInventory, student); getFeeDefaulters()
6. **HstComplaintService** — create() (compute sla_due_at based on priority); assign(staff); resolve(notes); escalate(); checkSlaBreaches() — called by SendHstComplaintEscalationJob hourly; computeSlaDeadline(priority) — 48h for high/urgent, 72h for medium, 7 days for low
7. **SickBayService** — admit() (check capacity, auto-mark attendance 'sick_bay', dispatch SickBayAdmissionRecorded); updateTreatmentNotes(); discharge() (set discharge_datetime, dispatch SickBayDischarged, resume normal attendance); setHospitalReferral(hpcRecordId) (sets is_hospital_referred=1, soft-links hpc_record_id — no FK enforced); getCurrentOccupancy()

#### Section 9 — Integration Contracts (7 events + 1 direct service)
For each event:
| Event | Fired By (service + when) | Listener Module | Payload | Action |
|---|---|---|---|---|
- `LeavePassApproved` → Notification → Parent SMS/push (leave dates, destination, warden name)
- `LeavePassRejected` → Notification → Alert to applicant staff
- `StudentReturned` → Notification → Parent SMS/push (is_late flag included)
- `HostelIncidentRecorded` → Notification → Parent SMS/push (moderate/serious only)
- `HostelAbsenceDetected` → Notification → Parent SMS/push (absent from roll call, not on leave)
- `SickBayAdmissionRecorded` → Notification → Parent SMS/push (symptoms, admission time)
- `SickBayDischarged` → Notification → Parent SMS/push (discharged)
- **Direct service call** (not event): `HostelFeeService::pushFeeDemand()` → StudentFee module on allotment/transfer/vacate (no event — synchronous service-to-service call within tenant context)

Document payload structure for `LeavePassApproved` and `HostelIncidentRecorded` from req v2 Section 11.3.

#### Section 10 — Non-Functional Requirements
From req v2 Sections 7.1–7.5.
For each NFR, add an "Implementation Note" column explaining HOW it will be met in code:
- Bulk attendance save (500 students): < 3 seconds — batch INSERT with chunking; counts computed once at end
- Dashboard load: < 2 seconds — pre-computed `current_occupancy` on hst_hostels; `present_count` on hst_attendance; no aggregation on page load
- Leave pass approval transaction: `DB::transaction()` wraps all 3 operations atomically
- Attendance UNIQUE constraint: `UNIQUE (hostel_id, attendance_date, shift)` — no duplicate sessions even on double-submit
- Notification dispatch: queued jobs — approval of leave pass does NOT block UI response
- Warden scoped access: `WardenScopeMiddleware` — injects floor_id scope into query builder before controller runs
- Visitor ID proof: last 4 digits only stored — never store full number

#### Section 11 — Test Plan Outline
From req v2 Sections 13.1–13.2:

**Feature Tests (Pest) — 11 test files:**
| File | Key Scenarios |
|---|---|
(List all 11 files from req v2 Section 13.1 with count and scenarios)

**Unit Tests (PHPUnit) — 4 test files:**
| File | Key Scenarios |
|---|---|
(List all 4 files from req v2 Section 13.2)

**Policy Tests:**
- `HostelPolicyTest` — Chief Warden can approve leave, Block Warden own-floor only, Mess Supervisor mess-only access

**Test Data:**
- Required seeders for test database
- Required factories: HostelFactory, FloorFactory, RoomFactory, BedFactory, AllotmentFactory, LeavePassFactory
- Mock strategy: `Event::fake()` for integration tests (LeavePassApproved, HostelIncidentRecorded); `Queue::fake()` for SendHstNotificationJob; `DB::transaction()` rollback tests for leave approval; `Bus::fake()` for Artisan command tests

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `HST_FeatureSpec.md` | `{OUTPUT_DIR}/HST_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 21 hst_* tables appear in Section 2 entity inventory (note: req Section 1.2 says 20 — actual Section 5 count is 21 including hst_room_inventory; use 21)
- [ ] All 21 FRs (HST-001 to HST-021) appear in Section 6
- [ ] All 22 business rules (BR-HST-001 to BR-HST-022) in Section 4 with enforcement point
- [ ] All 4 FSMs documented with ASCII state diagram and side effects
- [ ] All 7 services listed with key method signatures in Section 8
- [ ] All 7 events + 1 direct service call documented in Section 9
- [ ] `hst_allotments` dual generated-column UNIQUE indexes documented (active-bed + active-student)
- [ ] `hst_incident_media.media_id → sys_media.id` noted as `INT UNSIGNED` (not BIGINT)
- [ ] `hst_sick_bay_log.hpc_record_id` noted as soft FK (no DB constraint)
- [ ] Leave pass approval is a single `DB::transaction()` covering 3 operations
- [ ] `HostelFeeService` — no FK from hst_* to fin_* noted; service-to-service call only
- [ ] BR-HST-011 prorated fee formula documented: `(monthly_rate / 30) × remaining_days_in_month`
- [ ] BR-HST-012 (late return auto-incident with is_auto_generated=1) enforcement: service_layer
- [ ] `WardenScopeMiddleware` documented with floor-level scoping
- [ ] Attendance session denormalized counts (present_count etc.) — computed and stored at save time, NOT on load
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] Permission matrix covers School Admin / Chief Warden / Block Warden / Mess Supervisor / Accountant / Medical Staff roles

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/HST_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/HST_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 21 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify std_students.id, sch_academic_sessions.id are BIGINT UNSIGNED; verify sys_media.id is INT UNSIGNED; check no duplicate hst_* tables being created

### Phase 2A Task — Generate DDL (`HST_DDL_v1.sql`)

Generate CREATE TABLE statements for all 21 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**
1. Table prefix: `hst_` for all tables — no exceptions
2. Every table MUST include: `id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `updated_by BIGINT UNSIGNED NOT NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (none required in HST — use descriptive names like `hst_incident_media` not `_jnt`)
5. JSON columns: suffix `_json` (e.g., `facilities_json`, `amenities_json`, `visiting_days_json`)
6. Boolean flag columns: prefix `is_` or `has_`
7. All IDs and FK references: `BIGINT UNSIGNED` — EXCEPT `media_id` in `hst_incident_media` which is `INT UNSIGNED` (matches sys_media.id)
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_hst_{tableshort}_{column}` (e.g., `fk_hst_allot_bed_id`)
12. **Do NOT recreate std_*, sch_*, sys_*, fin_*, hpc_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `hst_allotments` MUST include TWO generated columns + UNIQUE indexes for double-allotment prevention:
    ```sql
    gen_active_bed_id BIGINT GENERATED ALWAYS AS (IF(status='active', bed_id, NULL)) STORED,
    gen_active_student_id BIGINT GENERATED ALWAYS AS (IF(status='active', student_id, NULL)) STORED,
    UNIQUE KEY uq_hst_allot_active_bed (gen_active_bed_id),
    UNIQUE KEY uq_hst_allot_active_student (gen_active_student_id)
    ```

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No hst_* dependencies (may reference sys_*/sch_* only):
  `hst_hostels` (→ sys_users nullable for warden_id)

Layer 2 — Depends on Layer 1 only:
  `hst_floors` (→ hst_hostels),
  `hst_warden_assignments` (→ hst_hostels + hst_floors nullable + sys_users)

Layer 3 — Depends on Layer 2:
  `hst_rooms` (→ hst_floors)

Layer 4 — Depends on Layer 3 + cross-module:
  `hst_beds` (→ hst_rooms),
  `hst_fee_structures` (→ hst_hostels + sch_academic_sessions),
  `hst_mess_weekly_menus` (→ hst_hostels + sch_academic_sessions),
  `hst_room_inventory` (→ hst_rooms + std_students nullable)

Layer 5 — Depends on Layer 4 + std_students:
  `hst_allotments` (→ std_students + hst_beds + sch_academic_sessions) [with generated columns for active-bed + active-student UNIQUE],
  `hst_special_diets` (→ std_students + hst_hostels),
  `hst_visitor_log` (→ hst_hostels + std_students + sys_users nullable),
  `hst_movement_log` (→ std_students + hst_hostels + sys_users nullable)

Layer 6 — Depends on Layer 5:
  `hst_attendance` (→ hst_hostels + sys_users),
  `hst_incidents` (→ std_students + hst_hostels + sys_users),
  `hst_mess_attendance` (→ hst_hostels + std_students + sys_users nullable),
  `hst_complaints` (→ hst_hostels + hst_rooms nullable + std_students nullable + sys_users nullable),
  `hst_sick_bay_log` (→ hst_hostels + std_students + sys_users nullable; `hpc_record_id` BIGINT UNSIGNED NULL — NO FK constraint)

Layer 7 — Depends on Layer 6:
  `hst_attendance_entries` (→ hst_attendance CASCADE DELETE + std_students),
  `hst_room_change_requests` (→ std_students + hst_allotments + hst_rooms nullable + sys_users + hst_allotments nullable for new_allotment_id),
  `hst_leave_passes` (→ std_students + hst_allotments + sys_users + hst_incidents nullable for late_return_incident_id)

Layer 8 — Depends on Layer 7:
  `hst_incident_media` (→ hst_incidents CASCADE DELETE + sys_media [INT UNSIGNED])

**Critical unique constraints to include:**
```sql
-- hst_hostels
UNIQUE KEY uq_hst_hostel_code (code)    -- nullable, allows multiple NULLs

-- hst_floors
UNIQUE KEY uq_hst_floor_num (hostel_id, floor_number)

-- hst_rooms
UNIQUE KEY uq_hst_room_num (floor_id, room_number)

-- hst_beds
UNIQUE KEY uq_hst_bed_label (room_id, bed_label)

-- hst_allotments (GENERATED COLUMNS for partial unique active-only)
gen_active_bed_id BIGINT GENERATED ALWAYS AS (IF(status='active', bed_id, NULL)) STORED
gen_active_student_id BIGINT GENERATED ALWAYS AS (IF(status='active', student_id, NULL)) STORED
UNIQUE KEY uq_hst_allot_active_bed (gen_active_bed_id)
UNIQUE KEY uq_hst_allot_active_student (gen_active_student_id)

-- hst_attendance
UNIQUE KEY uq_hst_att_session (hostel_id, attendance_date, shift)

-- hst_attendance_entries
UNIQUE KEY uq_hst_att_entry (attendance_id, student_id)

-- hst_mess_weekly_menus
UNIQUE KEY uq_hst_menu_slot (hostel_id, week_start_date, day_of_week, meal_type)

-- hst_mess_attendance
UNIQUE KEY uq_hst_mess_att (hostel_id, attendance_date, meal_type, student_id)

-- hst_fee_structures
UNIQUE KEY uq_hst_fee_struct (hostel_id, academic_session_id, room_type, meal_plan, effective_from)
```

**ENUM values (exact, to match application code):**
```
hst_hostels.type:                   'boys','girls','mixed'
hst_rooms.room_type:                'single','double','triple','dormitory'
hst_rooms.status:                   'available','full','maintenance'
hst_beds.status:                    'available','occupied','maintenance'
hst_beds.condition:                 'good','fair','poor'
hst_warden_assignments.assignment_type: 'chief','block','floor','assistant'
hst_allotments.meal_plan:           'full_board','lunch_only','dinner_only','none'
hst_allotments.status:              'active','vacated','transferred','waitlisted'
hst_room_change_requests.status:    'pending','approved','rejected'
hst_attendance.shift:               'morning','evening','night'
hst_attendance_entries.status:      'present','absent','leave','home','late','sick_bay'
hst_leave_passes.leave_type:        'home','emergency','medical','festival','vacation','other'
hst_leave_passes.status:            'pending','approved','rejected','returned','cancelled'
hst_incidents.severity:             'minor','moderate','serious'
hst_fee_structures.room_type:       'single','double','triple','dormitory'
hst_fee_structures.meal_plan:       'full_board','lunch_only','dinner_only','none'
hst_special_diets.diet_type:        'diabetic','jain_vegetarian','gluten_free','nut_allergy','religious_fasting','custom'
hst_mess_weekly_menus.meal_type:    'breakfast','lunch','dinner','snacks'
hst_mess_attendance.meal_type:      'breakfast','lunch','dinner','snacks'
hst_mess_attendance.status:         'present','absent','on_leave','opted_out'
hst_complaints.category:            'maintenance','electrical','plumbing','cleanliness','security','food','other'
hst_complaints.priority:            'low','medium','high','urgent'
hst_complaints.status:              'open','in_progress','resolved','escalated','closed'
hst_visitor_log.relationship:       'parent','guardian','sibling','relative','other'
hst_room_inventory.condition:       'good','fair','poor','under_repair','disposed'
hst_room_inventory.repair_status:   'none','pending','under_repair','repaired','written_off'
```

**Critical columns to get right:**
- `hst_incident_media.media_id`: `INT UNSIGNED NOT NULL` — sys_media.id is INT UNSIGNED (NOT BIGINT)
- `hst_sick_bay_log.hpc_record_id`: `BIGINT UNSIGNED NULL` — NO FK constraint (soft reference across modules)
- `hst_allotments.gen_active_bed_id` / `gen_active_student_id`: GENERATED ALWAYS — do NOT allow INSERT/UPDATE on these columns
- `hst_attendance.present_count` / `absent_count` / `leave_count` / `late_count`: `SMALLINT UNSIGNED DEFAULT 0` — auto-computed by HstAttendanceService at save time, never directly user-entered
- `hst_hostels.current_occupancy` + `hst_rooms.current_occupancy`: `SMALLINT UNSIGNED DEFAULT 0` — denormalized, maintained by AllotmentService
- `hst_leave_passes.late_return_incident_id`: `BIGINT UNSIGNED NULL` — nullable FK → hst_incidents; set only on late return
- `hst_room_inventory.responsible_student_id`: `BIGINT UNSIGNED NULL` — nullable FK → std_students; set only when student identified as responsible for damage
- `hst_complaints.sla_due_at`: `TIMESTAMP NULL` — computed by HstComplaintService on creation based on priority; not user-entered

**File header comment to include:**
```sql
-- =============================================================================
-- HST — Hostel Management Module DDL
-- Module: Hostel Management (Modules\Hostel)
-- Table Prefix: hst_* (21 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: HST_Hostel_Requirement.md v2
-- Sub-Modules: K1 Room & Bed Mgmt, K2 Allocation, K3 Attendance,
--              K3b Leave Pass, K4 Mess, K5 Fee, K6 Complaints,
--              Warden Mgmt, Visitor Log, Sick Bay, Room Inventory
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`HST_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_hst_tables.php`.
- `up()`: creates all 21 tables in Layer 1 → Layer 8 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 8 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, decimal with `->decimal(10, 2)`, generated columns with `->storedAs()`
- All FK constraints added in `up()` using `$table->foreign()`
- For `hst_sick_bay_log.hpc_record_id`: add as plain `->unsignedBigInteger()->nullable()` — do NOT add `->foreign()` constraint
- For `hst_allotments` generated columns: use `->storedAs("IF(status='active', bed_id, NULL)")` and `->storedAs("IF(status='active', student_id, NULL)")`
- For `hst_attendance_entries` CASCADE DELETE: `$table->foreign('attendance_id')->references('id')->on('hst_attendance')->onDelete('cascade')`
- For `hst_incident_media.media_id`: `$table->unsignedInteger('media_id')` — use `unsignedInteger` not `unsignedBigInteger`

### Phase 2C Task — Generate Seeders (2 seeders + 1 runner)

Namespace: `Modules\Hostel\Database\Seeders`

**Note on seeder scope:** `hst_rooms.room_type` is an ENUM (not a lookup table). The 2 required seeders (RoomTypes, IncidentTypes) seed reference configuration. Implement them as seeding system-level `sys_settings` entries OR a dedicated config approach. Phase 1 spec may have clarified whether lookup tables are used; follow that decision. If no lookup table was created, seed as dropdown master entries.

**1. `HstRoomTypeSeeder.php`** — Default room type display configuration:
```
single      | display_name: 'Single Room'     | is_system: 1 | description: 'One student per room; highest privacy'
double      | display_name: 'Double Sharing'  | is_system: 1 | description: 'Two students per room'
triple      | display_name: 'Triple Sharing'  | is_system: 1 | description: 'Three students per room'
dormitory   | display_name: 'Dormitory'       | is_system: 1 | description: 'Four or more students; shared common area'
```
If seeding to sys_settings: key pattern `hostel.room_type_labels.{type}` → value = display_name.

**2. `HstIncidentTypeSeeder.php`** — Common incident type string values seeded as reference:
```
late_arrival          | label: 'Late Arrival'             | is_auto_generated: 1 | description: 'System-generated on late return from leave'
rule_violation        | label: 'Hostel Rule Violation'    | is_auto_generated: 0 | description: 'General violation of hostel rules'
property_damage       | label: 'Property Damage'          | is_auto_generated: 0 | description: 'Damage to room furniture or hostel property'
misconduct            | label: 'Misconduct'               | is_auto_generated: 0 | description: 'Behavioral misconduct within hostel premises'
ragging               | label: 'Ragging'                  | is_auto_generated: 0 | description: 'Ragging or bullying — UGC/CBSE regulated'
unauthorized_absence  | label: 'Unauthorized Absence'     | is_auto_generated: 0 | description: 'Absent without approved leave or explanation'
```
Note: `incident_type` on `hst_incidents` is VARCHAR(100) — these values are reference labels, not enforced by FK. Use sys_settings or a dropdown master table as established in the project.

**3. `HstSeederRunner.php`** (Master seeder, calls both in order):
```php
$this->call([
    HstRoomTypeSeeder::class,      // no dependencies
    HstIncidentTypeSeeder::class,  // no dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `HST_DDL_v1.sql` | `{OUTPUT_DIR}/HST_DDL_v1.sql` |
| `HST_Migration.php` | `{OUTPUT_DIR}/HST_Migration.php` |
| `HST_TableSummary.md` | `{OUTPUT_DIR}/HST_TableSummary.md` |
| `Seeders/HstRoomTypeSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/HstIncidentTypeSeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/HstSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 21 hst_* tables exist in DDL (4 infrastructure + 1 warden + 3 allocation + 3 attendance + 1 leave + 3 mess + 1 fee + 3 incidents/complaints + 2 visitor/medical = 21 ✓)
- [ ] Standard columns (id, is_active, created_by, updated_by, created_at, updated_at, deleted_at) on ALL 21 tables
- [ ] `hst_allotments` has BOTH generated columns AND BOTH UNIQUE indexes (active-bed + active-student)
- [ ] `hst_incident_media.media_id` is `INT UNSIGNED` (NOT BIGINT UNSIGNED)
- [ ] `hst_sick_bay_log.hpc_record_id` is `BIGINT UNSIGNED NULL` with **NO FK constraint**
- [ ] `hst_attendance_entries` CASCADE DELETE from hst_attendance
- [ ] `hst_incident_media` CASCADE DELETE from hst_incidents
- [ ] `hst_attendance.present_count/absent_count/leave_count/late_count` are SMALLINT UNSIGNED (computed counters)
- [ ] `hst_hostels.current_occupancy` + `hst_rooms.current_occupancy` are SMALLINT UNSIGNED DEFAULT 0 (denormalized)
- [ ] **No `tenant_id` column** on any table
- [ ] All UNIQUE constraints listed above are present
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] All 5 UNIQUE constraints for sessions/slots are present: floors, rooms, beds, attendance, mess_weekly_menus, mess_attendance, fee_structures
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_hst_` convention throughout
- [ ] `hst_attendance_entries.status` ENUM includes 'sick_bay' value
- [ ] `hst_allotments.meal_plan` includes 'none' option (no mess for this student)
- [ ] HstRoomTypeSeeder has all 4 room types with display names
- [ ] HstIncidentTypeSeeder has all 6 incident types with is_auto_generated flag
- [ ] `HstSeederRunner.php` calls both seeders
- [ ] `HST_TableSummary.md` has one-line description for all 21 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `HST_DDL_v1.sql` + Migration + 3 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/HST_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 12 (service layer / controllers / FormRequests), Section 13 (tests), Section 14 (implementation status)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (naming conventions)

### Phase 3 Task — Generate `HST_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 6 (routes) and Section 12.2. For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (20 total, from req v2 Section 12.2):
1. `HstDashboardController` — index (live occupancy, today's attendance, pending passes, open incidents, sick bay, fee defaulters, attendance compliance)
2. `HostelController` — index, store, show, update, destroy, toggleStatus
3. `FloorController` — index, store, show, update, destroy
4. `RoomController` — index, store, show, update, destroy, toggleStatus + roomInventory, storeInventory, updateInventory, destroyInventory (nested room inventory routes)
5. `BedController` — index, store, show, update, destroy (+ toggle maintenance)
6. `WardenAssignmentController` — index, store, show, update, end (end assignment)
7. `AllotmentController` — index, store, show, update, vacate, transfer, bulkVacate, availability
8. `RoomChangeRequestController` — index, store, show, approve, reject
9. `HstAttendanceController` — index, store, show, update (for locked-session correction by Chief Warden), entries, storeEntries, bulkMark, lock
10. `MovementLogController` — index, store, show, recordReturn, pendingReturns
11. `LeavePassController` — index, store, show, update, approve, reject, markReturned, cancel, print, calendar
12. `IncidentController` — index, store, show, update, escalate, printWarningLetter, notifyParent, storeMedia, destroyMedia
13. `MessMenuController` — index, store, show, update, destroy, copyWeek
14. `SpecialDietController` — index, store, show, update, destroy
15. `MessAttendanceController` — index, store, bulkStore, monthlyReport
16. `HstFeeController` — index, store, show, update, destroy, calculate, defaulters
17. `HstComplaintController` — index, store, show, update, assign, resolve, escalate
18. `VisitorLogController` — index, store, show, update, checkout
19. `SickBayController` — index, store, show, update, discharge, current
20. `HstReportController` — occupancy, attendance, leaveRegister, movement, feeDefaulters, incidents, messAttendance, roomInventory, visitors, sickBay, export

#### Section 2 — Service Inventory (7 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Events fired
- Other services called (dependency graph)

Include the leave pass approval sequence as inline pseudocode in `LeavePassService`:
```
approve(LeavePass $pass, User $warden): void
  Step 1: Validate pass is in 'pending' status
  Step 2: Validate warden has permission for this hostel/floor
  Step 3: DB::transaction() begins
  Step 4: UPDATE hst_leave_passes: status='approved', approved_by=$warden->id, approved_at=now()
  Step 5: markAttendanceForLeave($pass):
            → For each date in [$pass->from_date ... $pass->to_date]:
                For each shift (morning, evening, night):
                  Fetch or create hst_attendance session for (hostel, date, shift)
                  INSERT/UPDATE hst_attendance_entries: student_id, status='leave'
                  Recompute and UPDATE session leave_count
  Step 6: markMessAttendanceForLeave($pass):
            → For each date in date range:
                For each meal (breakfast, lunch, dinner, snacks):
                  INSERT/UPDATE hst_mess_attendance: student_id, status='on_leave'
  Step 7: DB::transaction() commits
  Step 8: Dispatch SendHstNotificationJob(new LeavePassApproved($pass)) → queued
```

Include the allotment creation sequence as inline pseudocode in `AllotmentService`:
```
create(array $data): Allotment
  Step 1: Load bed + room; validate bed.status = 'available'
  Step 2: Check gen_active_bed_id uniqueness (UNIQUE constraint handles this at DB level; catch DuplicateEntry for user-friendly error)
  Step 3: Check gen_active_student_id uniqueness (same — student cannot have 2 active allotments)
  Step 4: Load hostel; validateGender($student, $hostel) — throw if mismatch
  Step 5: validateFeeStructureExists($hostel, $bed->room->room_type, $data['meal_plan'], $academicSession)
  Step 6: DB::transaction() begins
  Step 7: INSERT hst_allotments (status='active')
  Step 8: UPDATE hst_beds.status = 'occupied'
  Step 9: UPDATE hst_rooms.current_occupancy + 1; if current_occupancy >= capacity → status='full'
  Step 10: UPDATE hst_hostels.current_occupancy + 1
  Step 11: DB::transaction() commits
  Step 12: HostelFeeService::pushFeeDemand($allotment) — called AFTER transaction commit
```

#### Section 3 — FormRequest Inventory (27 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

Group by controller. 27 total (from req v2 Section 12.3):
- `StoreHostelRequest` — name required max:150, type in (boys,girls,mixed), sick_bay_capacity min:0
- `StoreFloorRequest` — hostel_id exists in hst_hostels, floor_number min:0 unique within hostel
- `StoreRoomRequest` — floor_id exists, room_number required max:20, room_type valid enum, capacity min:1 max:50
- `StoreBedRequest` — room_id exists, bed_label required max:20, unique within room
- `StoreWardenAssignmentRequest` — user_id exists in sys_users, hostel_id exists, assignment_type valid enum, effective_from required DATE, effective_to after effective_from if provided
- `StoreAllotmentRequest` — student_id exists in std_students, bed_id exists and available, academic_session_id exists, allotment_date required DATE, meal_plan valid enum
- `TransferAllotmentRequest` — allotment_id active status, target_bed_id available, reason required
- `BulkVacateRequest` — academic_session_id required, confirmation_text must match 'CONFIRM' (irreversible action)
- `StoreRoomChangeRequest` — from_allotment_id active, reason required TEXT, requested_room_id optional exists in hst_rooms
- `StoreHstAttendanceRequest` — hostel_id exists, attendance_date required DATE, shift valid enum, marked_by exists in sys_users
- `BulkMarkAttendanceRequest` — attendance_id exists, entries array required, each entry: student_id + status valid enum
- `StoreMovementLogRequest` — student_id exists, hostel_id exists, movement_date DATE, out_time TIME required, expected_return_time TIME optional
- `StoreLeavePassRequest` — student_id exists, from_date required DATE, to_date >= from_date, leave_type valid enum, destination required max:255
- `ApproveLeavePassRequest` — leave_pass must be in 'pending' status
- `MarkReturnedRequest` — actual_return_date DATE required, leave_pass must be in 'approved' status
- `StoreIncidentRequest` — student_id exists, hostel_id exists, incident_date DATE, severity valid enum (minor/moderate/serious), description required TEXT
- `StoreMessMenuRequest` — hostel_id exists, week_start_date is a Monday (day_of_week check), meal_type valid enum, is_published boolean
- `StoreSpecialDietRequest` — student_id exists, hostel_id exists, diet_type valid enum, effective_from required DATE, effective_to after from if provided
- `StoreMessAttendanceRequest` — hostel_id exists, attendance_date DATE, meal_type valid enum, student_id exists, status valid enum
- `BulkMessAttendanceRequest` — hostel_id exists, attendance_date DATE, meal_type valid enum, entries array with student_id + status each
- `StoreHstFeeStructureRequest` — hostel_id exists, academic_session_id exists, room_type valid enum, meal_plan valid enum, room_rent_monthly min:0, effective_from required DATE
- `StoreHstComplaintRequest` — hostel_id exists, category valid enum, subject required max:255, description required TEXT, priority valid enum
- `ResolveComplaintRequest` — complaint in (open/in_progress/escalated) status, resolution_notes required
- `StoreVisitorLogRequest` — hostel_id exists, student_id exists, visitor_name required, relationship valid enum, visit_date DATE, in_time TIME required
- `StoreSickBayRequest` — hostel_id exists, student_id exists, admission_datetime required DATETIME, presenting_symptoms required TEXT
- `DischargeSickBayRequest` — sick bay log in admitted state (discharge_datetime is NULL), discharge_notes optional TEXT
- `StoreRoomInventoryRequest` — room_id exists, item_name required, quantity min:1, condition valid enum

#### Section 4 — Blade View Inventory (~65 views)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and screen counts (from req v2 routes + FRs):
- Dashboard: 1 view
- Infrastructure (Hostel, Floor, Room, Bed): ~10 views
- Warden Assignments: ~3 views
- Allotment (allot/transfer/vacate/waitlist/bulk-vacate): ~8 views
- Room Change Requests: ~3 views
- Attendance (session list/form/entry-sheet/lock): ~5 views
- Movement Log (index/form/pending): ~3 views
- Leave Pass (list/form/show/approve/calendar/print-PDF): ~7 views
- Incidents (list/form/show/warning-letter-PDF): ~5 views
- Mess (menu-weekly/copy-week/special-diets/meal-attendance/monthly-report): ~7 views
- Fee Structures (list/form/show/calculate/defaulters): ~5 views
- Complaints (list/form/show/assign/resolve): ~4 views
- Visitor Log (list/form/show): ~3 views
- Sick Bay (list/form/current-occupancy/discharge): ~4 views
- Room Inventory (per-room list/form): ~2 views
- Reports (10 report views + export): ~11 views (occupancy, attendance, leave-register, movement, fee-defaulters, incidents, mess-attendance, room-inventory, visitors, sick-bay + export)
- Shared partials: _hostel_filter, _floor_selector, _student_search, _pagination

For key screens document:
- Leave pass approval form — date range warning + attendance auto-mark preview count before submit
- Attendance entry sheet — tablet-optimised bulk-mark with individual exception toggles (Alpine.js one-tap)
- Allotment form — cascading dropdowns: Hostel → Floor → Room (filtered by availability) → Bed; gender validation inline
- Pending returns dashboard widget — polling `/movement-log/pending` every 60s; overdue highlighted in red
- Mess weekly menu — 7-day × 4-meal grid with copy-week button

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by section (6.1–6.12). Count total routes at the end (target ~65).
Middleware on all routes: `['auth', 'tenant', 'EnsureTenantHasModule:Hostel']`
Additional middleware: `['WardenScopeMiddleware']` on attendance, leave pass, allotment, incident routes for block/floor warden scoping.

#### Section 6 — Implementation Phases (7 phases)

For each phase, provide a detailed sprint plan:

**Phase 1 — Infrastructure (K1: Rooms & Beds):**
FRs: HST-001, HST-002, HST-003, HST-004
Files to create:
- Controllers: HstDashboardController (stub), HostelController, FloorController, RoomController (+ room inventory sub-routes), BedController
- Services: (none yet)
- Models: Hostel, Floor, Room, Bed, RoomInventory
- FormRequests: StoreHostelRequest, StoreFloorRequest, StoreRoomRequest, StoreBedRequest, StoreRoomInventoryRequest
- Seeders: HstRoomTypeSeeder, HstIncidentTypeSeeder, HstSeederRunner
- Views: ~10 infrastructure views (hostel list/form, floor list/form, room list/form with room_inventory nested, bed list/form)
- Tests: HostelInfrastructureTest

**Phase 2 — Warden & Allotment (K2):**
FRs: HST-005, HST-006, HST-016
Files to create:
- Controllers: WardenAssignmentController, AllotmentController, RoomChangeRequestController
- Services: AllotmentService (full — with fee validation, occupancy update, gender check, generated-column duplicate handling)
- Models: WardenAssignment, Allotment, RoomChangeRequest
- FormRequests: StoreWardenAssignmentRequest, StoreAllotmentRequest, TransferAllotmentRequest, BulkVacateRequest, StoreRoomChangeRequest
- Middleware: WardenScopeMiddleware
- Views: ~11 allotment views (allotment list/form/show, availability grid, waitlist, bulk-vacate wizard, room change list/form/show)
- Tests: AllotmentTest, RoomChangeRequestTest

**Phase 3 — Attendance (K3):**
FRs: HST-007, HST-008
Files to create:
- Controllers: HstAttendanceController, MovementLogController
- Services: HstAttendanceService (create session + bulk mark + compute counts + lock)
- Models: HstAttendance, HstAttendanceEntry, MovementLog
- FormRequests: StoreHstAttendanceRequest, BulkMarkAttendanceRequest, StoreMovementLogRequest
- Jobs: (none yet)
- Views: ~8 attendance views (session list/form, entry sheet — tablet UI, pending returns dashboard)
- Tests: HstAttendanceTest

**Phase 4 — Leave Pass (K3b):**
FRs: HST-009
Files to create:
- Controllers: LeavePassController
- Services: LeavePassService (full — DB::transaction approve, markReturned, auto-incident, DomPDF)
- Models: LeavePass
- FormRequests: StoreLeavePassRequest, ApproveLeavePassRequest, MarkReturnedRequest
- Events: LeavePassApproved, LeavePassRejected, StudentReturned
- Jobs: SendHstNotificationJob (generic — used by all hostel notification events)
- Views: ~7 leave pass views (list/form/show/approve/calendar/leave-register-PDF/gate-pass-PDF)
- Artisan: n/a (leave pass driven by user action; notification via queued job)
- Tests: LeavePassTest

**Phase 5 — Incidents & Mess (K4 + Discipline):**
FRs: HST-010, HST-011, HST-012 + discipline incidents
Files to create:
- Controllers: IncidentController, MessMenuController, SpecialDietController, MessAttendanceController
- Services: IncidentService (record, auto-incident, escalate, DomPDF warning letter)
- Models: Incident, IncidentMedia, MessWeeklyMenu, SpecialDiet, MessAttendance
- FormRequests: StoreIncidentRequest, StoreMessMenuRequest, StoreSpecialDietRequest, StoreMessAttendanceRequest, BulkMessAttendanceRequest
- Events: HostelIncidentRecorded, HostelAbsenceDetected
- Views: ~12 incident + mess views (incident list/form/show/warning-letter-PDF, menu weekly-grid/copy-week, diet assignment, meal attendance bulk-sheet, monthly-report)
- Tests: IncidentTest, MessMenuTest

**Phase 6 — Fee, Complaints, Visitor & Sick Bay (K5+K6+new):**
FRs: HST-013, HST-014, HST-015, HST-017, HST-018, HST-019 (room inventory damage charge recovery)
Files to create:
- Controllers: HstFeeController, HstComplaintController, VisitorLogController, SickBayController
- Services: HostelFeeService (full — StudentFee push, proration), HstComplaintService (SLA), SickBayService (admit/discharge/HPC link)
- Models: HstFeeStructure, HstComplaint, VisitorLog, SickBayLog
- FormRequests: StoreHstFeeStructureRequest, StoreHstComplaintRequest, ResolveComplaintRequest, StoreVisitorLogRequest, StoreSickBayRequest, DischargeSickBayRequest
- Events: SickBayAdmissionRecorded, SickBayDischarged
- Jobs: SendHstComplaintEscalationJob (hourly scheduler)
- Artisan: `hst:escalate-complaints` (hourly — checks SLA breaches)
- Views: ~14 fee/complaint/visitor/sick bay views
- Tests: HstFeeTest, HstComplaintTest, VisitorLogTest, SickBayTest

**Phase 7 — Dashboard (complete) & Reports:**
FRs: HST-020, HST-021
Files to create:
- Controllers: HstDashboardController (complete — full KPIs), HstReportController (all 12 report types)
- Services: (reads from all hst_* tables; DomPDF for PDF reports; fputcsv for CSV exports)
- Models: (no new)
- Views: ~11 report views (occupancy/attendance/leave-register/movement/fee-defaulters/incidents/mess-attendance/room-inventory/visitors/sick-bay + export)
- Artisan: `hst:send-attendance-alerts` (daily — attendance threshold below 90%); `hst:flag-overdue-movements` (runs every 30 min via scheduler or triggered by MovementLogController)
- Tests: Report output format tests; dashboard KPI accuracy tests

#### Section 7 — Seeder Execution Order

```
php artisan module:seed Hostel --class=HstSeederRunner
  ↓ HstRoomTypeSeeder         (no dependencies)
  ↓ HstIncidentTypeSeeder     (no dependencies)
```

For test runs: use both seeders as minimum required.
For Phase 2+ tests: ensure test database has std_students and sch_academic_sessions factories available (cross-module FKs).

Artisan scheduled commands (register in `routes/console.php`):
```
hst:escalate-complaints       → hourly (SLA breach auto-escalation)
hst:send-attendance-alerts    → daily morning (attendance threshold notifications)
hst:flag-overdue-movements    → every 30 minutes (pending returns alert)
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// Leave pass approval: DB::transaction test — verify all 3 operations succeed or none do
// Event::fake() in leave pass, incident, absence, sick bay, complaint escalation tests
// Queue::fake() in SendHstNotificationJob tests
// Bus::fake() for Artisan command tests (hst:escalate-complaints, hst:send-attendance-alerts)
// StudentFee service: mock HostelFeeService::pushFeeDemand() in allotment tests
// WardenScopeMiddleware: test that block warden cannot see other floors' data
```

**Minimum Test Coverage Targets:**
- Dual active-allotment prevention: AllotmentTest — attempt to allot same bed twice throws DuplicateEntry; attempt to allot same student twice throws DuplicateEntry
- Gender restriction: AllotmentTest — boys student allotment to girls hostel rejected
- Leave approval transaction: LeavePassTest — approval marks ALL attendance + ALL mess attendance atomically; simulate transaction failure → all changes rolled back
- Late return auto-incident: LeavePassTest — marking returned with actual_return_date > to_date creates auto-incident with is_auto_generated=1
- Attendance UNIQUE: HstAttendanceTest — duplicate session creation returns existing session (not 422)
- Attendance counts: HstAttendanceTest — present_count computed correctly after bulk-mark; verified from DB row not aggregation
- SLA breach: HstComplaintTest — complaint past SLA gets escalated by SendHstComplaintEscalationJob
- Sick bay attendance: SickBayTest — student admitted to sick bay auto-marked 'sick_bay' in attendance; parent notification dispatched
- Prorated fee: HstFeeTest — mid-month allotment calculates (rate/30 × remaining days); mid-month vacate calculates refund
- Warden scope: AllotmentTest / AttendanceTest — block warden cannot view floor not in their assignment

**Feature Test File Summary (from req v2 Section 13.1):**
List all 11 test files with file path, test count, and key scenarios.

**Unit Test File Summary (from req v2 Section 13.2):**
List all 4 unit test files:
- `AllotmentServiceTest` — bed availability logic, gender validation, double-allotment detection
- `LeavePassServiceTest` — date range calculation for attendance auto-mark, late return detection
- `HostelFeeServiceTest` — prorated mid-month allotment, mid-month vacate, room change differential
- `HstComplaintServiceTest` — SLA due_at computation per priority level

**Factory Requirements:**
```
HostelFactory      — generates hostel with type, sick_bay_capacity, current_occupancy=0
FloorFactory       — generates floor with hostel_id, floor_number
RoomFactory        — generates room with floor_id, room_type, capacity, status='available'
BedFactory         — generates bed with room_id, bed_label, status='available'
AllotmentFactory   — generates active allotment with student_id + bed_id + academic_session_id
LeavePassFactory   — generates leave pass with student_id, from_date, to_date, status='pending'
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `HST_Dev_Plan.md` | `{OUTPUT_DIR}/HST_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 20 controllers listed with all methods
- [ ] All 7 services listed with at minimum 3 key method signatures each
- [ ] LeavePassService approve() pseudocode present (8-step transaction sequence)
- [ ] AllotmentService create() pseudocode present (12-step sequence)
- [ ] All 27 FormRequests listed with their key validation rules
- [ ] All 21 FRs (HST-001 to HST-021) appear in at least one implementation phase
- [ ] All 7 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented (both seeders no dependencies)
- [ ] All 3 Artisan commands listed with schedule (hourly, daily, every 30 min)
- [ ] Route list consolidated with middleware and FR reference (~65 routes total)
- [ ] View count per sub-module totals approximately 65
- [ ] `WardenScopeMiddleware` listed in Phase 2 and on attendance/leave/allotment routes
- [ ] `DB::transaction()` for leave pass approval explicitly noted in LeavePassService
- [ ] Dual active-allotment prevention test explicitly referenced (bed AND student)
- [ ] Late return → auto-incident test explicitly referenced with is_auto_generated=1
- [ ] Prorated fee formula explicitly referenced in HstFeeTest
- [ ] `hst:escalate-complaints` hourly schedule confirmed
- [ ] Test strategy includes Event::fake() for LeavePassApproved/HostelIncidentRecorded
- [ ] hst_sick_bay_log.hpc_record_id has NO FK constraint note in model and migration

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `HST_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/HST_FeatureSpec.md`
2. `{OUTPUT_DIR}/HST_DDL_v1.sql` + Migration + 3 Seeders
3. `{OUTPUT_DIR}/HST_Dev_Plan.md`
Development lifecycle for HST (Hostel Management) module is ready to begin."

---

## QUICK REFERENCE — HST Module Tables vs Controllers vs Services

| Domain | hst_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Infrastructure | hst_hostels, hst_floors, hst_rooms, hst_beds | HostelController, FloorController, RoomController, BedController | — |
| Room Inventory | hst_room_inventory | RoomController (nested) | HostelFeeService (damage charge) |
| Warden Mgmt | hst_warden_assignments | WardenAssignmentController | — (direct in controller) |
| Allocation | hst_allotments, hst_room_change_requests | AllotmentController, RoomChangeRequestController | AllotmentService |
| Attendance | hst_attendance, hst_attendance_entries | HstAttendanceController | HstAttendanceService |
| Movement | hst_movement_log | MovementLogController | — (direct in controller) |
| Leave Pass | hst_leave_passes | LeavePassController | LeavePassService |
| Mess | hst_mess_weekly_menus, hst_special_diets, hst_mess_attendance | MessMenuController, SpecialDietController, MessAttendanceController | — (direct + LeavePassService for auto-mark) |
| Fee | hst_fee_structures | HstFeeController | HostelFeeService |
| Incidents | hst_incidents, hst_incident_media | IncidentController | IncidentService |
| Complaints | hst_complaints | HstComplaintController | HstComplaintService |
| Visitor | hst_visitor_log | VisitorLogController | — (direct in controller) |
| Sick Bay | hst_sick_bay_log | SickBayController | SickBayService |
| Dashboard | (aggregates all hst_* pre-computed counters) | HstDashboardController | — (direct queries on counters) |
| Reports | (reads all hst_* tables) | HstReportController | — (DomPDF + fputcsv inline) |
