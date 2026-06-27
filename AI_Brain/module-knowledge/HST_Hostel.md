# Module Knowledge: Hostel (HST)
# Last Updated: 2026-06-27
# Completion Status: 0% — Greenfield (RBS_ONLY, no implementation started)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `hst_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Hostel_DDL_v4.sql` — **36 tables** (internally labelled v3.0, reviewed 2026-05-04) |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/HST_Hostel_Requirement.md` |
| Routes | `routes/tenant.php` under `hostel/` prefix (~65 routes) |
| Controllers | 20 proposed |
| Models | 20 proposed (req doc); DDL has 36 tables |
| Services | 7 proposed |
| FormRequests | 27 proposed |
| Policies | 12 proposed |
| Blade Views | ~65 proposed |
| Seeders | 2 (RoomTypes, IncidentTypes) |
| Events | 7 domain events |
| Queued Jobs | 2 |
| Business Rules | 22 (BR-HST-001 to BR-HST-022) |
| PDFs | 2 DomPDF documents (Leave Pass PDF, Warning Letter) |
| Test Classes | 11 feature + 4 unit = 15 proposed |
| FRD | Not yet generated |

---

## DDL Version Gap: Requirement vs Actual DDL

| Dimension | V2 Req Doc (2026-03-26) | DDL v4 file (v3.0 internally, 2026-05-04) |
|-----------|------------------------|-------------------------------------------|
| Table count | 20 proposed | **36 tables** |
| Extra tables | — | 15 new tables added by DB Architect review |
| Status fields | ENUM on each table | INT UNSIGNED FK → `hst_dynamic_status_masters` |
| Room type | ENUM('single','double','triple','dormitory') | TINYINT UNSIGNED FK → `hst_room_types` master |
| Bed type | not specified | TINYINT UNSIGNED FK → `hst_bed_types` master |
| sys_users FK type | BIGINT UNSIGNED (req claims) | **INT UNSIGNED** (DDL corrects; verified) |
| std_students FK type | BIGINT UNSIGNED (req claims) | **INT UNSIGNED** (DDL; verified) |
| sch_academic_term | `sch_academic_sessions` (req doc guesses) | `sch_academic_term` (singular; INT UNSIGNED — verify before migration) |

**Critical**: The DDL is more authoritative than the req doc for column types and status field design. Always reference the DDL for implementation.

---

## DDL Table Inventory (36 tables)

### Config / Setup (3 — no hst_* deps)
| Table | Description |
|-------|-------------|
| `hst_room_types` | Room type master (single/double/triple/dormitory + custom) |
| `hst_bed_types` | Bed type master (lower_bunk/upper_bunk/single + custom) |
| `hst_dynamic_status_masters` | Universal status master — all ENUM-like status codes across module |

### Core Infrastructure — v2 retained (21 tables, all enhanced in v3)
| Layer | Tables |
|-------|--------|
| L1 | `hst_hostels` |
| L2 | `hst_floors`, `hst_warden_assignments` |
| L3 | `hst_rooms` |
| L4 | `hst_beds`, `hst_fee_structures`, `hst_mess_weekly_menus`, `hst_room_inventory` |
| L5 | `hst_allotments`, `hst_special_diets`, `hst_visitor_log`, `hst_movement_log` |
| L6 | `hst_attendance`, `hst_incidents`, `hst_mess_attendance`, `hst_complaints`, `hst_sick_bay_log` |
| L7 | `hst_attendance_entries`, `hst_room_change_requests`, `hst_leave_passes` |
| L8 | `hst_incident_media` |

### New in v3 (15 tables)
| Group | Tables | Purpose |
|-------|--------|---------|
| A | `hst_warden_duty_roster` | Daily on-duty assignment per hostel/floor/shift |
| B | `hst_bed_maintenance_log`, `hst_housekeeping_log` | Maintenance ticket lifecycle; daily cleaning records |
| C | `hst_laundry_tickets` | Per-student laundry in/out tracking |
| D | `hst_mess_opt_outs`, `hst_mess_bills` | Per-meal opt-outs; monthly mess bill summary |
| E | `hst_fee_demands` | Local audit of charges raised against fin_* |
| F | `hst_incident_types`, `hst_incident_warnings` | Incident type master; warning-letter audit log |
| G | `hst_room_reservations` | Pre-allotment reservation during admission flow |
| H | `hst_emergency_contacts` | Hostel-level emergency numbers (doctor, ambulance, fire) |
| I | `hst_visitor_media` | Multi-photo attachments per visitor entry |
| J | `hst_sick_bay_vitals`, `hst_sick_bay_medications` | Structured vitals; medication administration log |
| K | `hst_audit_log`, `hst_notification_log` | Generic change trail; notification dispatch log |

---

## Sub-Modules

| Code | Sub-Module | Key Tables | FR |
|------|-----------|-----------|-----|
| K1 | Room & Bed Management | hostels, floors, rooms, beds, warden_assignments | FR-HST-001 to 004 |
| K2 | Student Room Allocation | allotments, room_change_requests, room_reservations | FR-HST-005 to 006 |
| K3 | Hostel Attendance | attendance, attendance_entries, movement_log, warden_duty_roster | FR-HST-007 to 008 |
| K3b | Leave Pass Management | leave_passes | FR-HST-009 |
| K4 | Mess Management | mess_weekly_menus, special_diets, mess_attendance, mess_opt_outs, mess_bills | FR-HST-010 to 012 |
| K5 | Hostel Fee Integration | fee_structures, fee_demands | FR-HST-013 to 014 |
| K6 | Hostel Complaint Register | complaints | FR-HST-015 |
| — | Warden Management | warden_assignments, warden_duty_roster | FR-HST-016 |
| — | Visitor Log | visitor_log, visitor_media | FR-HST-017 |
| — | Sick Bay | sick_bay_log, sick_bay_vitals, sick_bay_medications | FR-HST-018 |
| — | Room Inventory | room_inventory, bed_maintenance_log, housekeeping_log | FR-HST-019 |
| — | Dashboard & Reports | aggregated reads; 12 report types | FR-HST-020 to 021 |

---

## Known Gaps & Open Issues

### Implementation Blockers (Prerequisites)

| # | Prerequisite | Owner | Blocks |
|---|-------------|-------|--------|
| P1 | STD (std_students) complete | StudentProfile | All student-related tables |
| P2 | SCH (sch_academic_term) complete | SchoolSetup | allotments, fee_structures, mess_weekly_menus |
| P3 | SYS (sys_users, sys_media) complete | System | All warden/staff FKs, incident attachments, visitor photos |
| P4 | NTF module complete | Notification | 7 event types dispatched on leave, incident, absence, sick bay |
| P5 | StudentFee (FIN) integration interface defined | StudentFee | Fee demand push, room change differential, damage charges |
| P6 | HPC module interface for sick bay referral | HPC | `hpc_record_id` on sick_bay_log (soft FK; manual link until HPC built) |

### Open Pre-Implementation Questions

1. **Academic session table name** — req doc guesses `sch_academic_sessions`; DDL uses `sch_academic_term` (singular). Verify exact table name in `0-DDL_Masters/tenant_db_v4.sql` before writing any migration. **Use `sch_academic_term` per DDL.**

2. **StudentFee integration mechanism** — three options: (a) direct Eloquent INSERT into `fin_fee_demands`, (b) event `HostelFeeAssigned` listened by StudentFee, (c) formal service interface. Decide before Phase 5. `hst_fee_demands` table is the local HST-side audit; `external_demand_id` links to fin_* once accepted.

3. **HPC sick bay referral** — `hst_sick_bay_log.hpc_record_id` is nullable, no DB constraint. Manual link for now; auto-create approach deferred until HPC module built.

4. **Mess overlap with `mes_*`** — `hst_mess_*` tables are HST-internal for hostel boarders. If a separate `mes_*` Mess Management module is built for school canteen, review table ownership. Current recommendation: keep `hst_mess_*` in HST.

5. **Repeated offender threshold** — BR-HST-022 hardcodes 3 incidents. Should be configurable via `sys_settings`. Define setting key before Phase 6.

### DDL Deferred Items (v4 scope)

- Normalize `hst_hostels.facilities_json` + `hst_rooms.amenities_json` to master+junction tables
- Drop `hst_incidents.incident_type` (VARCHAR free text) once all callers migrate to `incident_type_id`
- Encrypt-at-rest for `hst_visitor_log.id_proof_number_masked`
- Partition `hst_audit_log` and `hst_notification_log` by month
- Visitor blacklist table (`hst_visitor_blacklist`)
- Vendor/contractor tables (likely `vnd_*` scope)

---

## Design Decisions Made

1. **`hst_dynamic_status_masters` replaces ENUMs**: All status-like fields in `hst_*` tables use `INT UNSIGNED FK → hst_dynamic_status_masters` instead of inline ENUMs. Allows adding new statuses without code changes. Covers 17 status types: Room Status, Bed Status, Allotment Status, Attendance Entry Status, Leave Approval Status, Mess Attendance Status, Complaint Status, Room Change Request Status, Bed Maintenance Status, Laundry Ticket Status, Mess Opt-out Status, Mess Bill Status, Hostel Fee Status, Room Reservation Status, etc.

2. **Active allotment uniqueness via generated columns**: `hst_allotments` uses two STORED generated columns:
   - `gen_active_bed_id = IF(is_alloted=1, bed_id, NULL)` + `UNIQUE(gen_active_bed_id)`
   - `gen_active_student_id = IF(is_alloted=1, student_id, NULL)` + `UNIQUE(gen_active_student_id)`
   One active allotment per bed AND per student enforced at DB level. `is_alloted` flag (not just `status`) is the discriminator. Soft-deleted rows must also null out this column — validate generated column expression handles `deleted_at IS NOT NULL` edge case.

3. **`hst_mess_bills.total_amount` is GENERATED ALWAYS**: `base_charge + special_diet_charge - leave_credit - opt_out_credit + manual_adjustment`. Never INSERT/UPDATE this column directly.

4. **`hst_audit_log` is HST-internal generic audit**: All `hst_*` service mutations write before/after JSON here. Separate from `sys_activity_logs`. No user entry — system writes only. Designed for partition-by-month at v4.

5. **`hst_notification_log` is HST-internal dispatch log**: Records every parent/warden/principal notification with delivery status (queued/sent/delivered/failed) and external vendor message ID. Separate from NTF module — this is the HST-side delivery audit.

6. **`hst_incidents.incident_type` dual field**: Old VARCHAR field kept for backward-compatibility; new `incident_type_id INT UNSIGNED FK → hst_incident_types` is preferred going forward. Deferred to v4 to drop the VARCHAR.

7. **`hst_sick_bay_log.hpc_record_id` is a soft FK** — no DB constraint. Stores the HPC module record ID for referral cases. Must not be JOIN-queried without application-layer null check.

8. **`hst_room_reservations.student_id` is nullable** — supports pre-admission inquiries where the student `std_students` record does not yet exist. `prospective_name` and `prospective_contact` capture the applicant. Converts to a real allotment via `converted_to_allotment_id` on confirmation.

9. **`hst_housekeeping_log.cleaned_by` is VARCHAR** — cleaning staff may be third-party contractors not in `sys_users`. `cleaned_by_user_id` is a nullable FK for internal staff only.

10. **Block Warden scoped data access** — `WardenScopeMiddleware` + `HostelScope` must be built in Phase 1/2. Block/floor wardens see only students and data for floors they are currently assigned to (active `hst_warden_assignments` record). Chief Warden has full hostel-wide access. This must be retrofitted nowhere — build early.

11. **Attendance session is idempotent on create** — UNIQUE on `(hostel_id, attendance_date, shift)`. Service uses `firstOrCreate()`. Submitting same session twice must UPDATE, not throw duplicate error.

12. **Pre-computed attendance counts** — `hst_attendance.present_count`, `absent_count`, `leave_count`, `late_count` are stored at save time in the session record. Never aggregated on report load. Critical for 500+ student hostels.

13. **Leave approval auto-marks attendance AND mess**: `LeavePassService::approve()` must call both `markAttendanceForLeave()` (writes `hst_attendance_entries` status='leave') and `markMessAttendanceForLeave()` (writes `hst_mess_attendance` status='on_leave') for all sessions/meals in the leave date range.

14. **Late return auto-creates incident**: `LeavePassService::markReturned()` checks if `actual_return_date > to_date`. If so, auto-creates `hst_incidents` record with `incident_type='late_arrival'` and `is_auto_generated=1`. `late_return_incident_id` FK on leave_pass links them.

---

## State Machine Summaries

| FSM | States |
|-----|--------|
| Leave Pass | `pending` → `approved` (auto-marks att + mess) / `rejected` → `returned` (late return → auto-incident) / `cancelled` |
| Room Change Request | `pending` → `approved` (triggers transfer) / `rejected` |
| Room Reservation | `pending` → `confirmed` → `converted` (becomes allotment) / `expired` / `cancelled` / `refunded` |
| Sick Bay Admission | `admitted` (attendance auto-mark) → `discharged` / `hospital_referred` (link to HPC) |
| Allotment | `active` → `vacated` / `transferred` / `waitlisted` |
| Hostel Complaint | `open` → `in_progress` → `resolved` / `escalated` / `closed` |
| Bed Maintenance | `reported` → `assigned` → `in_progress` → `blocked` / `resolved` / `closed` / `cancelled` |
| Laundry Ticket | `submitted` → `in_wash` → `ready` → `collected` / `lost` / `damaged` / `disputed` |
| Mess Opt-Out | `pending` → `approved` / `rejected` / `active` / `expired` / `cancelled` |
| Mess Bill | `draft` → `finalised` / `disputed` / `adjusted` → `settled` |

---

## Key Business Rules

| Rule | Summary |
|------|---------|
| BR-HST-001 | One active allotment per bed — enforced via `gen_active_bed_id` UNIQUE generated column |
| BR-HST-002 | One active allotment per student — enforced via `gen_active_student_id` UNIQUE generated column |
| BR-HST-003 | Student gender must match hostel type (`boys`/`girls`) before allotment |
| BR-HST-005 | Leave approval auto-marks all shifts during leave period as `leave` in attendance_entries |
| BR-HST-006 | Leave approval auto-marks all meals during leave period as `on_leave` in mess_attendance |
| BR-HST-007 | Attendance session UNIQUE on `(hostel_id, attendance_date, shift)` — idempotent create |
| BR-HST-008 | Moderate and Serious incidents auto-dispatch parent notification (queued job) |
| BR-HST-009 | Hostel deactivation blocked if any active allotments exist |
| BR-HST-010 | Room status auto-updates: `full` when occupancy >= capacity; `available` when drops below |
| BR-HST-011 | Prorated fee = `(monthly_rate / 30) × remaining_days_in_month` |
| BR-HST-012 | Late return: `actual_return_date > to_date` → auto-creates `hst_incidents` with `is_auto_generated=1` |
| BR-HST-013 | Block warden scoped access: sees only assigned hostel/floor data |
| BR-HST-015 | Fee structure must exist for room_type + meal_plan before allotment can be created |
| BR-HST-016 | Sick bay admission auto-marks attendance as `sick_bay` for admission period |
| BR-HST-017 | Absent from roll call (not on leave, not in sick bay) → parent notification dispatched |
| BR-HST-019 | Warden may view fee defaulters before leave pass approval; advisory by default (configurable as hard block) |
| BR-HST-020 | Hostel complaint SLA breach (default 48h for high/urgent) triggers auto-escalation via scheduled job |
| BR-HST-021 | Visitor outside configured visiting hours requires warden override with reason text |
| BR-HST-022 | Student with 3+ incidents in current academic year flagged as `repeated_offender` (threshold configurable) |

---

## Domain Events & Jobs

| Event | Fired When | Target | Channel |
|-------|-----------|--------|---------|
| `LeavePassApproved` | Warden approves leave pass | Parent | SMS, Push, Email |
| `LeavePassRejected` | Warden rejects leave pass | Applicant staff | SMS, Push |
| `StudentReturned` | Warden marks student returned | Parent | SMS, Push |
| `HostelIncidentRecorded` | Moderate/serious incident created | Parent | SMS, Push |
| `HostelAbsenceDetected` | Student absent at roll call (not on leave) | Parent | SMS, Push |
| `SickBayAdmissionRecorded` | Student admitted to sick bay | Parent | SMS, Push |
| `SickBayDischarged` | Student discharged | Parent | SMS, Push |

**Queued Jobs:**
- `SendHstNotificationJob` — generic dispatcher used by all 7 events above
- `SendHstComplaintEscalationJob` — runs hourly via Laravel scheduler; checks SLA breach and auto-escalates

---

## Cross-Module Dependencies

### Inbound (HST reads from)

| Module | Table/Channel | Integration Point |
|--------|--------------|-------------------|
| StudentProfile (STD) | `std_students` | All student FKs throughout module (INT UNSIGNED) |
| SchoolSetup (SCH) | `sch_academic_term` | Academic session on allotments, fee_structures, mess_weekly_menus |
| System (SYS) | `sys_users` | Warden refs, approved_by, marked_by, created_by (INT UNSIGNED) |
| System (SYS) | `sys_media` | Incident photos, visitor photos/ID, inventory damage photos, leave consent scans |
| System (SYS) | `sys_activity_logs` | Bulk-vacate and allotment audit trail |

### Outbound (HST integrates with)

| Target Module | Mechanism | What Is Sent |
|--------------|-----------|--------------|
| StudentFee (FIN) | `HostelFeeService` service call | Hostel fee demand, room change differential, prorated vacating refund, damage charge |
| Notification (NTF) | 7 domain events → queued listeners | Parent/warden/principal notifications |
| HPC | Soft FK `hpc_record_id` | Hospital referral link from sick bay admission |

### Module Independence Notes
- `hst_emergency_contacts` = hostel-level (doctor, ambulance, fire) — distinct from student emergency contacts in `std_*`
- `hst_complaints` (`hst_*`) is hostel-internal maintenance register — separate from `cmp_*` school-wide Complaint module
- `hst_mess_*` tables are exclusive to hostel boarders — do NOT merge with school-wide CAF mess or `mes_*` canteen module

---

## Service Layer

| Service | Responsibility |
|---------|---------------|
| `AllotmentService` | Create allotment, validate bed + gender + fee structure, update occupancy, transfer, bulk-vacate |
| `LeavePassService` | Approval FSM, auto-mark attendance + mess, dispatch notifications, detect late return, create auto-incident |
| `HstAttendanceService` | Create session (idempotent), bulk-mark, compute summary counts, lock after 24h |
| `IncidentService` | Record incident, classify severity, auto-notify, escalate to principal, generate warning letter PDF (DomPDF) |
| `HostelFeeService` | Fee structure lookup, monthly charge calculation, prorated amounts, push fee demand to StudentFee |
| `HstComplaintService` | Create complaint, compute SLA due_at, assign, resolve, escalate overdue |
| `SickBayService` | Admit student, auto-mark attendance, dispatch parent notification, discharge, flag hospital referral |

---

## PDF Generation (DomPDF)

| Document | Trigger |
|----------|---------|
| Leave Pass PDF | `LeavePassController@print` — student details, dates, destination, approving warden signature line |
| Warning Letter PDF | `IncidentController@printWarningLetter` — level (verbal/first written/final), rendered body stored in `hst_incident_warnings.letter_body` as audit trail |

---

## Implementation Sequence (Recommended)

| Phase | Components | Deliverable |
|-------|-----------|-------------|
| Phase 1 | hst_hostels + hst_floors + hst_rooms + hst_beds + config masters + basic dashboard | Hostel setup screens; room/bed browser |
| Phase 2 | hst_warden_assignments + hst_allotments + hst_room_change_requests + AllotmentService + WardenScopeMiddleware | Full allocation workflow; scoped warden access |
| Phase 3 | hst_attendance + hst_attendance_entries + hst_movement_log + hst_warden_duty_roster + HstAttendanceService | Daily roll call; in-out register |
| Phase 4 | hst_leave_passes + LeavePassService + notification events | Leave pass workflow; auto-attendance mark; parent notifications |
| Phase 5 | hst_fee_structures + hst_fee_demands + HostelFeeService + StudentFee integration | Hostel fee calculation; fee demand push |
| Phase 6 | hst_incidents + hst_incident_types + hst_incident_warnings + hst_incident_media + IncidentService + DomPDF | Incident register; warning letter; auto-escalation |
| Phase 7 | hst_mess_weekly_menus + hst_special_diets + hst_mess_attendance + hst_mess_opt_outs + hst_mess_bills | Mess menu; special diet; meal attendance; monthly billing |
| Phase 8 | hst_complaints + hst_visitor_log + hst_visitor_media + hst_sick_bay_log + hst_sick_bay_vitals + hst_sick_bay_medications + hst_room_inventory + hst_bed_maintenance_log + hst_housekeeping_log + hst_laundry_tickets | Support features; sick bay; maintenance |
| Phase 9 | HstReportController (12 report types) + dashboard analytics + exports | Full reporting suite |

**Build `WardenScopeMiddleware` + `HostelScope` in Phase 1/2.** Must not be retrofitted later across all controllers.

---

## Lessons Learned

(empty until session work populates this)

---

## Pending Next Steps

- [ ] Verify exact academic session table name in `0-DDL_Masters/tenant_db_v4.sql` — req doc says `sch_academic_sessions`; DDL uses `sch_academic_term` (singular)
- [ ] Define StudentFee integration mechanism (direct Eloquent / event / service interface) before Phase 5
- [ ] Define `sys_settings` key for repeated-offender threshold (BR-HST-022)
- [ ] Generate FRD → `act as Business Analyst` → "create an FRD for Hostel"
- [ ] DDL Gap Analysis → `act as DB Architect` — V2 req (20 tables) vs DDL v4 (36 tables); confirm all 15 new v3 tables are requirement-aligned
- [ ] Code Gap Analysis → `act as Technical Auditor` — after FRD generated

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (HST_Hostel_Requirement.md v2) + DDL (Hostel_DDL_v4.sql / internally v3.0). No session work yet. |
