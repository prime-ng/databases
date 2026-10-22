# Module Knowledge: Hostel (HST)
# Last Updated: 2026-06-29
# Completion Status: ~70–75% — Substantially Implemented (corrected from 0% Greenfield)

---

## FRD Summary

| Item | Value |
|------|-------|
| FRD file | `4-Requirement_Module_wise/0-FRD_Documents/HST_FRD_2026-06-29.md` (flat storage) |
| Date / Version | 2026-06-29 / v1.0 (fresh — generated from 001) |
| Functional Requirements (REQ-) | **29** (REQ-HST-001 … 029) |
| Business Rules (BR-) | **54** (BR-HST-001 … 054) — original 001–022 preserved verbatim; 023–054 added for testability + post-V2 scope (reservations, mess opt-outs/bills, laundry, duty roster, masters, audit/notification logs) |
| Workflows | **10** (allocation, room change, leave, roll-call/absence, movement/overdue, incident/escalation, complaint SLA, sick bay, mess opt-out/billing, reservation conversion) |
| Reports (RPT-) | **14** (RPT-HST-001 … 014) |
| Enhancements (ENH-) | **10** (ENH-HST-001 … 010) |
| Priority split | **P0 = 13, P1 = 13, P2 = 3** |
| Sources synthesised | V2 (HST_Hostel_Requirement.md, 21 FR/22 BR) + V1 screen-spec folder (Hostel_v2, 40 screens) + DDL (Hostel_DDL_v4.sql, 36–40 tables) + Laravel module (~70–75% built) + this knowledge file |
| Section 10.4 reconciliation | Verified: 29 REQ / 54 BR / 10 WF / 14 RPT / 10 ENH; P0+P1+P2 = 29 |
| Notes | REQ- re-numbered from 001 (NOT copied from V2 FR-). BR-HST-001…022 are the downstream gap-analysis contract and were carried over unchanged in meaning. No prior FRD existed — created fresh, not superseding. |

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `hst_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Hostel_DDL_v4.sql` — **36 tables** (internally labelled v3.0, reviewed 2026-05-04) |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/HST_Hostel_Requirement.md` |
| Routes | `Modules/Hostel/routes/web.php` (560 lines) + `api.php` (13 lines) = **573 total** |
| Controllers | **53** (req doc proposed 20) |
| Models | **41** (req doc proposed 20; modules-map 2026-06-21 shows 44 — discrepancy noted) |
| Services | **22** (req doc proposed 7) |
| FormRequests | **38** (req doc proposed 27) |
| Policies | **20** (req doc proposed 12; in `Modules/Hostel/app/Policies/` — NOT in `app/Policies/`) |
| Middleware | **1** — `WardenScopeMiddleware` ✓ |
| Blade Views | **278** (req doc proposed ~65) |
| Seeders | **9** (req doc proposed 2) |
| Events | **7** domain events ✓ (matches req doc) |
| Listeners | **0** — gap; events dispatch jobs directly |
| Queued Jobs | **2** ✓ (matches req doc) |
| Artisan Commands | **1** — `EscalateComplaintsCommand` (hst:escalate-complaints; scheduled hourly) |
| Named Routes | **337** in web.php |
| Migrations (tenant/) | **41** files in `database/migrations/tenant/` ✓ (36 CREATE + 5 ALTER/add) |
| Module-level migrations | **0** — all in central `database/migrations/tenant/` |
| Business Rules | 22 (BR-HST-001 to BR-HST-022) |
| PDFs | 2 DomPDF documents (Leave Pass PDF, Warning Letter) |
| Test Classes | **0 actual** (15 proposed — critical gap) |
| FRD | **Generated 2026-06-29** → `HST_FRD_2026-06-29.md` (29 REQ / 54 BR / 14 RPT / 10 WF / 10 ENH) |

---

## Verified Filesystem Counts (2026-06-27)

> All counts verified via `ls` against `Modules/Hostel/` in LARAVEL_REPO (`/Users/bkwork/Herd/prime_ai`).
> Do NOT rely on req doc counts — every artifact category was systematically under-proposed.

### Controllers (53 total)
```
AllotmentController, AuditLogController, BedController, BedMaintenanceController,
BedTypeController, EmergencyContactController, FeeDemandController, FloorController,
HostelAttendanceReportController, HostelController, HostelDisciplineReportController,
HostelFeeReportController, HostelLaundryReportController, HostelLeaveReportController,
HostelMaintenanceReportController, HostelMedicalReportController, HostelMessReportController,
HostelOccupancyReportController, HostelReservationReportController, HostelSetupController,
HostelWardenReportController, HousekeepingController, HstAttendanceController,
HstAuditLogController, HstComplaintController, HstDashboardController,
HstDynamicStatusMasterController, HstFeeController, HstNotificationLogController,
HstReportController, IncidentController, IncidentTypeController, IncidentWarningController,
LaundryController, LeavePassController, MessAttendanceController, MessBillController,
MessMenuController, MessOptOutController, MovementLogController, NotificationLogController,
RoomChangeRequestController, RoomController, RoomInventoryController, RoomReservationController,
RoomTypeController, SickBayController, SickBayMedicationController, SickBayVitalController,
SpecialDietController, VisitorLogController, WardenAssignmentController, WardenDutyRosterController
```
> Note: Both `AuditLogController` and `HstAuditLogController` exist; similarly `NotificationLogController` and `HstNotificationLogController`. Possible naming duplication — verify before FRD.

### Models (41 total)
```
Allotment, Bed, BedMaintenanceLog, BedType, EmergencyContact, FeeDemand, Floor, Hostel,
HousekeepingLog, HstAttendance, HstAttendanceEntry, HstAuditLog, HstBedType,
HstComplaint, HstDynamicStatusMaster, HstFeeStructure, HstIncident, HstIncidentMedia,
HstIncidentType, HstIncidentWarning, HstNotificationLog, HstSickBayLog, HstSickBayMedication,
HstSickBayVital, HstVisitorLog, HstVisitorMedia, LaundryTicket, LeavePass, MessAttendance,
MessBill, MessOptOut, MessWeeklyMenu, MovementLog, Room, RoomChangeRequest,
RoomInventory, RoomReservation, RoomType, SpecialDiet, WardenAssignment, WardenDutyRoster
```
> **Naming inconsistency:** `BedType.php` AND `HstBedType.php` both exist — two models for one `hst_bed_types` table. Requires deduplication.
> **modules-map discrepancy:** modules-map (2026-06-21) records 44 models; actual `ls` returns 41. Delta of 3 unresolved.

### Services (22 total)
```
AllotmentService, HostelAttendanceReportService, HostelAuditService,
HostelDisciplineReportService, HostelFeeReportService, HostelFeeService,
HostelLaundryReportService, HostelLeaveReportService, HostelMaintenanceReportService,
HostelMedicalReportService, HostelMessReportService, HostelMovementReportService,
HostelOccupancyReportService, HostelReservationReportService, HostelVisitorFrequencyService,
HostelVisitorReportService, HostelWardenReportService, HstAttendanceService,
HstComplaintService, IncidentService, LeavePassService, SickBayService
```
> 7 core domain services from req doc all exist. Developer added 15 report-specific services.

### FormRequests (38 total)
```
ApproveLeavePassRequest, BedMaintenanceRequest, BedRequest, BulkMarkAttendanceRequest,
BulkMessAttendanceRequest, BulkVacateRequest, DischargeSickBayRequest,
EmergencyContactRequest, FeeDemandRequest, FloorRequest, HostelRequest,
HousekeepingRequest, IncidentTypeRequest, IncidentWarningRequest, LaundryTicketRequest,
MarkReturnedRequest, MessBillRequest, MessOptOutRequest, ResolveComplaintRequest,
RoomInventoryRequest, RoomRequest, RoomReservationRequest, StoreAllotmentRequest,
StoreHstAttendanceRequest, StoreHstComplaintRequest, StoreHstFeeStructureRequest,
StoreIncidentRequest, StoreLeavePassRequest, StoreMessAttendanceRequest,
StoreMessMenuRequest, StoreMovementLogRequest, StoreRoomChangeRequestRequest,
StoreSickBayRequest, StoreSpecialDietRequest, StoreVisitorLogRequest,
TransferAllotmentRequest, WardenAssignmentRequest, WardenDutyRosterRequest
```

### Policies (20 total — in `Modules/Hostel/app/Policies/`)
```
AllotmentPolicy, BedPolicy, EmergencyContactPolicy, FloorPolicy, HstAttendancePolicy,
HstComplaintPolicy, HstFeeStructurePolicy, HstIncidentPolicy, HostelPolicy, LeavePassPolicy,
MessAttendancePolicy, MessWeeklyMenuPolicy, MovementLogPolicy, RoomChangeRequestPolicy,
RoomInventoryPolicy, RoomPolicy, SickBayLogPolicy, SpecialDietPolicy,
VisitorLogPolicy, WardenAssignmentPolicy
```
> All registered in `HostelServiceProvider::registerPolicies()`. **NOT in central `app/Policies/`.**

### Seeders (9 total)
```
HostelComprehensiveSeeder, HostelDatabaseSeeder, HostelDemoDataSeeder,
HostelHistorySeeder, HstBedTypeSeeder, HstDynamicStatusMasterSeeder,
HstIncidentTypeSeeder, HstRoomTypeSeeder, HstSeederRunner
```
> modules-map records 8; actual ls returns 9. `HstSeederRunner` is an orchestrator seeder.

### Events (7 total) ✓
```
HostelAbsenceDetected, HostelIncidentRecorded, LeavePassApproved, LeavePassRejected,
SickBayAdmissionRecorded, SickBayDischarged, StudentReturned
```

### Jobs (2 total) ✓
```
SendHstComplaintEscalationJob, SendHstNotificationJob
```

### Artisan Commands (1 total)
```
EscalateComplaintsCommand  →  hst:escalate-complaints
```
Registered in `HostelServiceProvider::registerCommands()`.
Scheduled hourly via `registerCommandSchedules()` — multi-tenant note: needs `tenants:run hst:escalate-complaints` wrapper for per-tenant execution.

### Middleware (1 total) ✓
```
WardenScopeMiddleware  →  aliased as 'warden.scope' in HostelServiceProvider
```
Design Decision D10 (Block Warden scoped data access) is IMPLEMENTED.

### Migrations (41 files in `database/migrations/tenant/`)
All 36 DDL tables have migration files. Verified list (2026-06-27):
```
hst_audit_log, hst_bed_types, hst_dynamic_status_masters, hst_hostels, hst_incident_types,
hst_notification_log, hst_room_types, hst_attendance, hst_emergency_contacts, hst_floors,
hst_laundry_tickets, hst_mess_attendance, hst_mess_bills, hst_mess_opt_outs,
hst_mess_weekly_menus, hst_movement_log, hst_sick_bay_log, hst_special_diets,
hst_visitor_log, hst_incidents, hst_fee_structures, hst_attendance_entries, hst_rooms,
hst_warden_assignments, hst_warden_duty_roster, hst_sick_bay_medications,
hst_sick_bay_vitals, hst_visitor_media, hst_incident_media, hst_incident_warnings,
hst_beds, hst_complaints, hst_housekeeping_log, hst_room_inventory, hst_allotments,
hst_bed_maintenance_log, hst_fee_demands, hst_leave_passes, hst_room_change_requests,
hst_room_reservations
```
Plus 1 ALTER: `add_bed_condition_status_to_hst_dynamic_status_masters` (2026-06-18)

### Tests (0)
> **Critical gap.** 15 tests proposed (11 feature + 4 unit); 0 exist.

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

### Critical Gaps (must resolve before FRD/Code Gap Analysis)

| # | Gap | Severity | Notes |
|---|-----|----------|-------|
| G1 | 0 tests (15 proposed) | P1 | 11 feature + 4 unit tests needed; none exist |
| G2 | 0 Listeners | P2 | 7 events fire; jobs dispatch notifications directly — verify this is intentional or a Listener layer is missing |
| G3 | `BedType.php` + `HstBedType.php` duplicate models | P1 | Two models for one `hst_bed_types` table. One must be removed or aliased. |
| G4 | Controller naming duplication | P2 | `AuditLogController` vs `HstAuditLogController`; `NotificationLogController` vs `HstNotificationLogController` — likely dead code |
| G5 | models-map count mismatch | P3 | modules-map records 44 models; actual ls returns 41. Delta of 3 unaccounted. |
| G6 | Report service completeness unknown | P2 | 14 report controllers + 15 report services exist; FRD needed to verify screen/feature coverage |
| G7 | FRD not generated | P2 | No FRD exists; gap analysis cannot proceed without it |

### Technical Audit Findings — 2026-06-29 (Mode A, 12-layer, read-only)

> Confirmed against live code at `/Users/bkwork/Herd/prime_ai/Modules/Hostel/`. Full report:
> `3-Audit_Reports/V1_Jun-2026/Hostel_Technical_Audit_2026-06-29.md`. Health **39/100 (P0 cap ≤40)**.
> New codes (orchestrator consolidates into known-issues.md): P0×1, P1×6, P2×5, P3×1.

| Code | Sev | Issue | Location |
|------|-----|-------|----------|
| DAT-HST-001 | **P0** | `gen_active_bed_id`/`gen_active_student_id` written as plain nullable cols (NOT generated) → both UNIQUE indexes inert (all-NULL) → BR-HST-001/002 unenforced; no `lockForUpdate` anywhere → concurrent double-allotment of bed/student. AllotmentService's stated concurrency strategy is silently dead; `translateDuplicateError()` waits for a 1062 that can't fire. | `database/migrations/tenant/2026_06_15_153428_create_hst_allotments_table.php:23-24,44-45` + `AllotmentService.php` |
| MIG-HST-001 | P1 | `hst_mess_bills.total_amount` is plain NOT-NULL `decimal(10,2)` no default, NOT `GENERATED` (D34 #3 requires it). Model has it in `$casts` but not `$fillable` → `MessBill::create()` w/o it fails (SQLSTATE 1364); BR-HST-025 unenforced. | `…create_hst_mess_bills_table.php:29` + `Models/MessBill.php:16-46` |
| JOB-HST-001 | P1 | `hst:escalate-complaints` scheduled as a bare central command (`registerCommandSchedules`), no `tenants:run` wrapper; command runs `checkSlaBreaches()` inline on central DB → BR-HST-020 SLA escalation never runs per tenant. | `Providers/HostelServiceProvider.php:150-160`, `EscalateComplaintsCommand.php`, `SendHstComplaintEscalationJob.php` |
| BUG-HST-006 | P1 | `SendHstNotificationJob::handle()` only `Log::info()` (stub). 0 Listeners, `EventServiceProvider::$listen=[]`. All 7 events dispatch this job → parent alerts (BR-HST-008/017/031/049) never delivered. | `Jobs/SendHstNotificationJob.php:40-46` |
| PERF-HST-003 | P1 | `Schema::hasTable()` as runtime feature-flags (info_schema per request) — tables all exist. | `HostelFeeService.php:108,211,225`, `LeavePassService.php:209,260`, `HstAttendanceService.php:145`, `IncidentService.php:178` |
| SEC-HST-004 | P1 | 35/38 FormRequests `authorize()` return bare `true` (D30). | `app/Http/Requests/` |
| DAT-HST-002 | P1 | Room/hostel `current_occupancy` non-atomic read-modify-write, no lock → counter drift + missed `full` flip (BR-HST-010). (Hostel total uses atomic increment — room does not.) | `AllotmentService.php` create/transfer/vacate |
| VAL-HST-002 | P2 | BR-HST-015 (fee structure must exist before allotment) is a soft `Log::info`, not a hard block — contradicts FRD REQ-HST-008 AC#3. | `HostelFeeService::validateFeeStructureExists()` |
| ORM-HST-001 | P2 | Duplicate model→table: `BedType`+`HstBedType` both → `hst_bed_types`; both live (BedType: HostelSetup/BedTypeController; HstBedType: Bed rel + BedController). Resolves G3. | `Models/BedType.php:13`, `Models/HstBedType.php:14` |
| MIG-HST-002 | P2 | D29: 29 hst migrations use `->enum()` (~35 calls: vacation_reason, meal_plan…) instead of dropdown FK. Top platform offender. | `…create_hst_allotments_table.php:21` et al. |
| TEN-HST-001 | P2 | `RouteServiceProvider::mapApiRoutes()` = only `api` middleware (no tenancy/auth). api.php empty → latent; Phase-7 endpoints would be unprotected. | `Providers/RouteServiceProvider.php:46` |
| BUG-HST-007 | P2 | `forwardToStudentFee()` hardcodes `return null` → fee demands stored locally but never pushed to StudentFee (REQ-HST-019 stub). | `HostelFeeService::forwardToStudentFee()` |
| DEAD-HST-002 | P3 | Commented-out Gate in AuditLogController (compounds DEAD-HST-001/BUG-HST-005). | `AuditLogController.php:112` |

**Verified CLEAN (not findings):** web `RouteServiceProvider` has full tenancy stack; no `$request->all()` into models; no `dd()`/debug; no backup files; no bare-string cache keys; events are dispatched (not orphaned); generated columns are never written directly by code (the bug is they're never written at all).

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

6. **Listeners layer** — Do 7 events need Listeners, or do controllers/services dispatch `SendHstNotificationJob` directly? Check `EventServiceProvider.php` before assuming gap.

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

10. **Block Warden scoped data access** — `WardenScopeMiddleware` + `HostelScope` — `WardenScopeMiddleware` is **IMPLEMENTED** (confirmed 2026-06-27). Block/floor wardens see only students and data for floors they are currently assigned to (active `hst_warden_assignments` record). Chief Warden has full hostel-wide access.

11. **Attendance session is idempotent on create** — UNIQUE on `(hostel_id, attendance_date, shift)`. Service uses `firstOrCreate()`. Submitting same session twice must UPDATE, not throw duplicate error.

12. **Pre-computed attendance counts** — `hst_attendance.present_count`, `absent_count`, `leave_count`, `late_count` are stored at save time in the session record. Never aggregated on report load. Critical for 500+ student hostels.

13. **Leave approval auto-marks attendance AND mess**: `LeavePassService::approve()` must call both `markAttendanceForLeave()` (writes `hst_attendance_entries` status='leave') and `markMessAttendanceForLeave()` (writes `hst_mess_attendance` status='on_leave') for all sessions/meals in the leave date range.

14. **Late return auto-creates incident**: `LeavePassService::markReturned()` checks if `actual_return_date > to_date`. If so, auto-creates `hst_incidents` record with `incident_type='late_arrival'` and `is_auto_generated=1`. `late_return_incident_id` FK on leave_pass links them.

15. **`hst:escalate-complaints` command scheduled hourly** — implemented in `HostelServiceProvider::registerCommandSchedules()`. Multi-tenant deployment requires `tenants:run hst:escalate-complaints` wrapper; bare `schedule->command()` only runs on central domain context.

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

**Listeners: 0** — verify whether events dispatch jobs directly in EventServiceProvider, or if Listeners layer is missing entirely.

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
| `HostelAuditService` | Internal audit trail writes to `hst_audit_log` |
| 14 Report Services | One per report type: attendance, discipline, fee, laundry, leave, maintenance, medical, mess, movement, occupancy, reservation, visitor frequency, visitor, warden |

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

**`WardenScopeMiddleware` is IMPLEMENTED as of 2026-06-27.** Phase 1/2 requirement is fulfilled.

---

## Lessons Learned

- **Status "0% Greenfield" was wrong** — module was seeded from req doc only, never verified against filesystem. Hostel had 53 controllers, 278 views, 41 migrations, and 22 services already built. Always `ls` before trusting any seeded count.
- **Policies are in the module, not `app/Policies/`** — HST has 20 policies in `Modules/Hostel/app/Policies/`. Post-migration architecture puts module policies in each module's own directory. Grep on `app/Policies/` returns 0 — not a gap.
- **Report services inflate service count significantly** — 15 of 22 services are report-specific (`HostelAttendanceReportService`, etc.). Core domain services: 7. This pattern exists in other modules too — always distinguish domain services from report services when comparing.
- **Model naming inconsistency is a real risk** — `BedType.php` and `HstBedType.php` both exist for the same `hst_bed_types` table. This must be caught in code gap analysis before FRD work proceeds.

### [2026-06-29 | Technical Auditor]
- **The Laravel migrations dropped the DDL's MySQL generated-column expressions — silently fatal.** `HST_DDL_v3` (D34) declares `hst_allotments.gen_active_bed_id`/`gen_active_student_id` as STORED `GENERATED ALWAYS AS (IF(is_alloted=1, bed_id, NULL))` and `hst_mess_bills.total_amount` as a GENERATED formula. The hand-written tenant migrations created all three as **plain columns** (`bigInteger()->nullable()`, `decimal()`), with no `storedAs`/`virtualAs` anywhere in any `hst_*` migration. Result: the allotment UNIQUE indexes enforce nothing (all-NULL columns), and the whole BR-HST-001/002 concurrency guarantee is a no-op (DAT-HST-001, P0). **Lesson: whenever a DDL master uses a generated column for a uniqueness/computed invariant, grep the migration for `storedAs|virtualAs|GENERATED` — a missing expression turns a DB-enforced rule into a silent lie. Don't trust a service docblock that says "relies on UNIQUE(...)"; verify the column is actually generated.**
- **Generated-column "never written directly" can be a false comfort.** The audit guardrail is "confirm code never writes the generated column." Here code never writes it AND the DB never generates it → permanently NULL. The correct check is both directions.
- **`Schema::hasTable()` Phase-gating leaves dead introspection cost.** Services were written to no-op until a table "ships," but the tables shipped — the guards now just hit `information_schema` every request (PERF-HST-003).
- **Notification subsystem is a Log stub end-to-end.** Events dispatch correctly but the single sink job only logs; 0 Listeners. The module's headline safety value (parent alerts) is non-functional until Phase 5 (BUG-HST-006). Cross-module "Phase N will wire this" stubs (also BUG-HST-007 StudentFee, JOB-HST-001 scheduler) are the dominant gap class here, not security holes.
- **Authorization is healthier than the platform norm for CRUD** — 20 policies registered, main controllers gated, no `$request->all()`. The authz weakness is concentrated in the 7 read-only report controllers (SEC-HST-001/002/003) and the universal D30 FormRequest `true` (SEC-HST-004).

---

## Pending Next Steps

- [ ] Verify `BedType.php` vs `HstBedType.php` — determine which is live, which is dead; remove duplicate
- [ ] Verify duplicate controllers: `AuditLogController` vs `HstAuditLogController`; `NotificationLogController` vs `HstNotificationLogController`
- [ ] Check `EventServiceProvider.php` — confirm whether 0 Listeners is intentional (jobs dispatched directly) or a gap
- [ ] Verify modules-map model count discrepancy: 44 (map) vs 41 (actual ls)
- [x] Generate FRD → done 2026-06-29 → `HST_FRD_2026-06-29.md` (29 REQ / 54 BR / 14 RPT / 10 WF / 10 ENH)
- [ ] Run DDL Schema Gap Analysis → `act as DB Architect` — FRD Section 10.1 "DDL Entity Needed = Yes" rows vs Hostel_DDL_v4.sql
- [ ] Run Code Gap Analysis → `act as Technical Auditor` — FRD-driven, against `Modules/Hostel/`
- [ ] Run Completion Scoring (6-dim) → `act as Status_Analyzer` using HST_FRD_2026-06-29.md as denominator
- [ ] Test Coverage Gap → `act as Testing Architect` — acceptance criteria vs the 0 existing tests
- [ ] Define `sys_settings` key for repeated-offender threshold (BR-HST-022)
- [ ] Define StudentFee integration mechanism (direct Eloquent / event / service interface) before Phase 5
- [ ] Write 15 test classes (11 feature + 4 unit) — 0 exist today
- [ ] Multi-tenant scheduler wrapper: `hst:escalate-complaints` needs `tenants:run` for per-tenant execution

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (HST_Hostel_Requirement.md v2) + DDL (Hostel_DDL_v4.sql / internally v3.0). No session work yet. Status recorded as 0% Greenfield. |
| 2026-06-27 | Business Analyst | Full filesystem verification pass. Status corrected to ~70–75% complete. All artifact counts updated from filesystem. 13 known gaps/corrections documented. Lessons Learned populated. |
| 2026-06-29 | Business Analyst | FRD generated fresh → `HST_FRD_2026-06-29.md` (flat FRD storage). 29 REQ / 54 BR / 14 RPT / 10 WF / 10 ENH; P0=13/P1=13/P2=3. Original BR-HST-001…022 preserved verbatim (downstream contract); BR-HST-023…054 added. REQ- re-numbered from 001. FRD Summary block added; Pending Next Steps updated to point at the four post-FRD gap analyses. Section 10.4 totals verified against actual document counts. |
| 2026-06-29 | Technical Auditor | Mode A 12-layer deep audit (priority L6/8/2/5/10) against live module + tenant migrations, cross-referenced to HST_FRD_2026-06-29.md and D34/D29/D30/D17. Report → `3-Audit_Reports/V1_Jun-2026/Hostel_Technical_Audit_2026-06-29.md`. Health **39/100, P0 cap applied**. 13 new codes: **DAT-HST-001 (P0** — generated-UNIQUE allotment columns are inert plain columns → BR-HST-001/002 unenforced, concurrent double-allotment**)**, MIG-HST-001/JOB-HST-001/BUG-HST-006/PERF-HST-003/SEC-HST-004/DAT-HST-002 (P1), VAL-HST-002/ORM-HST-001/MIG-HST-002/TEN-HST-001/BUG-HST-007 (P2), DEAD-HST-002 (P3). Known Gaps + Lessons Learned appended. known-issues.md NOT edited (parallel-run protocol — orchestrator consolidates). |

---

## Complete Analysis Pack (2026-06-29)

> Generated by Business Analyst (Complete Analysis Pack Mode), FRD-first, all IDs reused from `HST_FRD_2026-06-29.md`.
> **Folder:** `5-Project_Planning/2-Analysis_Pack/HST/` · **Index:** `HST_Analysis_Index.md`

| Artifact | File |
|----------|------|
| Index | `HST_Analysis_Index.md` |
| RTM (REQ↔BR↔WF↔RPT↔test↔code-status) | `HST_RTM.md` |
| Business Rules + Conditions + Validation | `HST_Rules_Conditions_Validation.md` |
| Workflows + FSM Catalog (8 FSMs) | `HST_Workflows_FSM.md` |
| Data Dictionary + Dependency Map | `HST_DataDictionary_Dependencies.md` |
| NFR Catalog + Risk Register (9 NFR, 9 RISK) | `HST_NFR_Risk.md` |
| Prioritization + Estimation + Sprint Tasks (~152h, 4 sprints) | `HST_Prioritization_Estimation.md` |
| User Stories (26 P0/P1) + KPI Catalog (12 KPI) | `HST_UserStories_KPI.md` |
| Conditions (canonical pointer) | `4-Requirement_Module_wise/5-Requirement_Conditions/Hostel_Conditions.md` |

> The RTM "Code Status" column folds in the Mode A audit defects (DAT-HST-001 double-allotment, MIG-HST-001 mess-bill, BUG-HST-006 notification stub, BUG-HST-007 fee-push, JOB-HST-001 escalation) so the spec and the audit are cross-linked. Reconciles to FRD §10.4 (29 REQ / 54 BR / 14 RPT).

## Version History (analysis pack)
| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-29 | Business Analyst | Complete Analysis Pack generated (8 artifacts) FRD-first; reused all REQ/BR/RPT IDs; RTM cross-links audit findings; conditions populate `5-Requirement_Conditions/`. |
