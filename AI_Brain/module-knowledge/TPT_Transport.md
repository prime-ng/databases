# Module Knowledge: Transport (TPT)
# Last Updated: 2026-06-29 (FRD generated)
# Completion Status: ~55% (readiness score 5.5/10 — V2 requirement, March 2026)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `tpt_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Transport_DDL_v2.3.sql` — 27 tables |
| V2 Requirement | `4-Requirement_Module_wise/2-Detailed_Requirements/V2/TPT_Transport_Requirement.md` |
| Laravel Module Path | `Modules/Transport/` |
| Controllers | 31 (+ 1 archived `.php-old`) |
| Models | 36 (25 DDL-backed + 11 stub/ML/GPS — no DDL tables) |
| FormRequests | 18 |
| Policies | 42+ |
| Dusk Tests | **0** — all test directories contain only `.gitkeep` files |
| FRD | `4-Requirement_Module_wise/0-FRD_Documents/TPT_FRD_2026-06-29.md` (v1.0) — generated 2026-06-29 |

**Note on table count:** V2 requirement (March 2026) listed 25 tables. DDL v2.3 (May 2026) has 27 tables — adds `tpt_fine_category` (May 2026 change log) and reconciles Dec 2025 boarding + notification log additions.

---

## Sub-Module Areas (11 areas)

1. Vehicle Management — master data, documents, compliance expiry, fuel logs, maintenance lifecycle
2. Route Management — route/stop master, sequencing, junction mapping, spatial geometry
3. Personnel Management — driver/helper profiles, license tracking, police verification, attendance
4. Student Transport Allocation — session-based pickup/drop assignment, stop-change workflow
5. Trip Management — daily trip creation from schedulers, stop-by-stop tracking, incidents, approval
6. Student Boarding Attendance — QR/RFID scan events, boarding logs, parent notification
7. Attendance Devices — QR scanner / RFID reader device registry and management
8. Transport Fee — route-wise fee master, monthly fee schedule, collection, fines
9. GPS Tracking — data models and alert infrastructure (live integration stub only)
10. ML Route Optimization — feature store and recommendation history (data structure only, no implementation)
11. Reports and Dashboard — 11 report types, analytics dashboard

---

## P0 Production-Blocking Issues

These 4 issues must be resolved before any school can go live:

### 1. EnsureTenantHasModule Middleware Missing (RT-01)
- **Where:** `routes/tenant.php` — transport route group (~line 2214)
- **Impact:** Any tenant can access transport endpoints even if not licensed for the Transport module
- **Fix:** Add `'module:TPT'` (or project-standard EnsureTenantHasModule syntax) to the route group middleware array
- **Test:** TST-08

### 2. AttendanceDeviceController — Gate Prefix Typo (SEC-TPT-02)
- **Where:** `Modules/Transport/app/Http/Controllers/AttendanceDeviceController.php`
- **Impact:** ALL Gate::authorize() calls use prefix `tested.` instead of `tenant.` — 100% of device management requests return HTTP 403 for all users, completely blocking device functionality
- **Fix:** Global find-replace `tested.attendance-device` → `tenant.attendance-device` (6 occurrences)
- **Test:** TST-01, TST-02
- **Exact fix documented in:** V2 requirement Appendix A

### 3. PII Plaintext Storage — Aadhaar/PAN (SEC-TPT-01 / NFR-TPT-01)
- **Where:** `tpt_personnel.id_no` column stores Aadhaar, PAN, Passport, Voter ID in plaintext
- **Legal risk:** Violation of Aadhaar Act 2016 + DPDP Act 2023
- **Fix:** Add `'id_no' => 'encrypted'` and `'license_no' => 'encrypted'` casts to DriverHelper model. Add `id_no_hash` (SHA-256) for search. Also encrypt `tpt_attendance_device.pg_fcm_token`
- **Test:** TST-17, TST-18

### 4. Zero Service Classes
- **Impact:** 0 of 31 controllers has a corresponding service class. All business logic lives inline in controllers — untestable, unmaintainable
- **Fix:** Implement 9 service classes (see Service Layer section below)

---

## Known Gaps & Open Issues

### Security
- `VehicleController.create()` uses wrong Gate: `tenant.vehicle.view` instead of `tenant.vehicle.create` (Appendix B)
- Gate prefix typo in AttendanceDeviceController (P0 — see above)
- EnsureTenantHasModule missing (P0 — see above)
- PII plaintext (P0 — see above)

### Logic / Workflow Gaps
- **Route capacity enforcement missing** — `StudentAllocationController` has no check against `tpt_vehicle.capacity` at save time; allocation can exceed vehicle capacity (FR-TPT-03.5)
- **Stop change request workflow incomplete** — model relationships exist but controller logic unfinished (FR-TPT-03.6)
- **Auto trip generation from scheduler not fully implemented** — manual trip creation works; batch generation from route scheduler is partial (FR-TPT-05.2)
- **Trip boarding scan service missing** — `TransportAttendanceService::processBoardingScan()` not yet written; boarding scan has no central validation point (FR-TPT-07.2)
- **Vendor usage log not wired** — when a trip is approved and `trip_usage_needs_to_be_updated_into_vendor_usage_log = true` in `sch_settings`, the `vnd_usage_logs` write is not implemented (FR-TPT-06.5, BR-TPT-11)
- **Maintenance → Vendor billing not wired** — on maintenance approval, `vnd_vendor_bill_due_for_payment` entry is not created (BR-TPT-10)
- **Accounting integration deferred** — fee collection → `acc_vouchers`, maintenance expenses → `acc_vouchers` (FR-TPT-10.7)
- **Parent notification not wired** — `tpt_notification_log` model present; integration with Notification module not implemented (FR-TPT-07.3)
- **Compliance auto-flag missing** — scheduled job to set `availability_status = 0` when any compliance doc expires does not exist (FR-TPT-02.3)
- **No TransportShiftSeeder** — fresh install has no default shift data; first-use requires manual setup (FR-TPT-01.2)

### DDL Column Gaps

| ID | Table | Missing Columns | Severity |
|----|-------|-----------------|----------|
| DB-01 | `tpt_vehicle` | `created_by` | P1 |
| DB-02 | `tpt_personnel` | `created_by` | P1 |
| DB-03 | `tpt_trip` | `is_active` | P1 |
| DB-04 | `tpt_driver_attendance` | `updated_at`, `deleted_at`, `is_active` | P1 |
| DB-05 | `tpt_driver_attendance_log` | `updated_at`, `deleted_at`, `is_active` | P1 |
| DB-06 | `tpt_fine_master` | `updated_at`, `is_active`, `created_by` | P2 |
| DB-07 | `tpt_student_fee_detail` | `updated_at`, `is_active`, `created_by` | P2 |
| DB-08 | `tpt_student_fine_detail` | `updated_at`, `is_active`, `created_by` | P2 |
| DB-09 | `tpt_student_fee_collection` | `updated_at`, `is_active`, `created_by` | P2 |
| DB-10 | `tpt_trip.status` | VARCHAR — should be FK to sys_dropdown_table | P2 |
| DB-11 | `tpt_student_fee_detail.status` | VARCHAR — should be FK | P2 |
| DB-12 | `tpt_student_fee_collection.status` | VARCHAR — should be FK | P2 |
| DB-13 | `tpt_student_fee_collection.payment_mode` | VARCHAR — should be FK | P2 |
| DB-15 | `tpt_fine_master.Remark` | Uppercase R — use `remark` | P3 |
| DB-16 | `tpt_daily_vehicle_inspection` | `Create Table` mixed case keyword | P3 |
| DB-17 | `tpt_vehicle_service_request.Vehicle_status` | Uppercase V — use `vehicle_status` | P3 |

### Models Without DDL Tables (must add DDL before migration)

| Model | Gap ID | Action |
|-------|--------|--------|
| `TptGpsAlerts` | MD-06 | Add DDL `tpt_gps_alerts` |
| `TptGpsTripLog` | MD-06 | Add DDL `tpt_gps_trip_log` |
| `TptLiveTrip` | MD-06 | Add DDL `tpt_live_trip` |
| `TptStudentEventLog` | MD-07 | Add DDL `tpt_student_event_log` |
| `MlModels` | MD-05 | Add DDL or remove |
| `MlModelFeatures` | MD-05 | Add DDL or remove |
| `TptFeatureStore` | MD-05 | Add DDL or remove |
| `TptModelRecommendations` | MD-05 | Add DDL or remove |
| `TptRecommendationHistory` | MD-05 | Add DDL or remove |

### Performance
- 5 tab-based controllers load ALL sub-resource data in a single request (N+1 risk): `TransportMasterController`, `StaffMgmtController`, `VehicleMgmtController`, `TripMgmtController`, `StudentRouteFeesController` — must refactor to AJAX lazy-load per tab
- Missing indexes: `tpt_trip(trip_date)`, `tpt_student_boarding_log(trip_date, student_id)`, `tpt_driver_attendance(attendance_date)`
- View directory naming inconsistent: `daily-vehicle-Inspection/` (capital I), mix of snake_case and kebab-case

---

## Service Layer (Required — Currently Zero Service Classes)

9 service classes needed before further feature work:

| Service | Primary Responsibility |
|---------|------------------------|
| `TransportVehicleService` | Vehicle CRUD, compliance expiry checks, availability flag management |
| `TransportRouteService` | Route/stop management, capacity calculations, ordinal management |
| `TransportAllocationService` | Student allocation with uniqueness, stop-change workflow, capacity gate |
| `TransportTripService` | Trip creation from scheduler, status machine, stop detail recording, approval |
| `TransportAttendanceService` | Driver QR scan, boarding log creation, boarding scan validation |
| `TransportInspectionService` | Inspection checklist, auto-create service request on failure |
| `TransportFeeService` | Monthly fee generation, fine calculation, collection recording |
| `TransportGpsService` | GPS data ingestion, geofence alert generation (stub; ready for live wiring) |
| `TransportReportService` | Report query encapsulation, export helpers (CSV, PDF) |

**Key service method signatures** documented in V2 requirement Appendix E.

---

## DDL Table Summary (27 tables in v2.3)

| # | Table | Purpose |
|---|-------|---------|
| 1 | `tpt_vehicle` | Vehicle master: registration, compliance docs, expiry dates, vendor link |
| 2 | `tpt_personnel` | Drivers/helpers/managers: license, PII (ENCRYPT!), police verification |
| 3 | `tpt_shift` | Shift master: code, name, effective dates |
| 4 | `tpt_route` | Route master: code, name, direction enum, shift FK, LINESTRING geometry |
| 5 | `tpt_pickup_points` | Stop master: code, name, lat/lon, POINT geometry, stop_type enum |
| 6 | `tpt_pickup_points_route_jnt` | Route-stop junction: ordinal, arrival/departure times, fares |
| 7 | `tpt_driver_route_vehicle_jnt` | Driver+vehicle+route date-range assignment (has DB trigger) |
| 8 | `tpt_route_scheduler_jnt` | Recurring schedule template per date — source for trip generation |
| 9 | `tpt_trip` | Daily trip: vehicle, driver, odometer, fuel readings, status lifecycle |
| 10 | `tpt_trip_stop_detail` | Per-stop arrival/departure within a trip |
| 11 | `tpt_attendance_device` | QR/RFID device registry (FCM token — ENCRYPT!) |
| 12 | `tpt_driver_attendance` | Daily driver attendance summary (missing updated_at/deleted_at) |
| 13 | `tpt_driver_attendance_log` | Punch-level log IN/OUT per device (missing updated_at/deleted_at) |
| 14 | `tpt_student_route_allocation_jnt` | Student pickup/drop allocation per session |
| 15 | `tpt_fine_category` | Fine category master — NEW in v2.3 (May 2026) |
| 16 | `tpt_fine_master` | Fine rule definitions per session (missing standard columns) |
| 17 | `tpt_student_fee_detail` | Monthly fee record per student session (missing standard columns) |
| 18 | `tpt_student_fine_detail` | Fine instance applied to a fee record (missing standard columns) |
| 19 | `tpt_student_fee_collection` | Fee payment record (missing standard columns) |
| 20 | `std_student_pay_log` | Cross-module payment audit log (shared with other modules) |
| 21 | `tpt_vehicle_fuel` | Fuel entry per vehicle: quantity, cost, odometer, approval workflow |
| 22 | `tpt_daily_vehicle_inspection` | 15-checkpoint pre-trip checklist (Create Table mixed case — DB-16) |
| 23 | `tpt_vehicle_service_request` | Service request from failed inspection (Vehicle_status uppercase — DB-17) |
| 24 | `tpt_vehicle_maintenance` | Actual repair record from approved service request |
| 25 | `tpt_trip_incidents` | In-trip incidents: type, severity, GPS, resolution workflow |
| 26 | `tpt_student_boarding_log` | Per-student-per-trip boarding/unboarding events with device FK |
| 27 | `tpt_notification_log` | Parent notification events (5 types, 4 channels) per trip/student |

**Key DB trigger:** `trg_driver_route_vehicle_unique_assignment` — BEFORE INSERT on `tpt_driver_route_vehicle_jnt`. Prevents overlapping date-range assignments for same shift+route+vehicle+driver. Fires on INSERT only — UPDATE must replicate overlap check in application code.

---

## Cross-Module Dependencies

| Dependency | Direction | Integration Point |
|------------|-----------|-------------------|
| StudentProfile (`std_students`) | Transport consumes | Student FK in allocation + boarding log |
| StudentProfile (`std_student_academic_sessions`) | Transport consumes | Session FK in allocation, fee detail, notification log |
| SystemUsers (`sys_users`) | Transport consumes | `approved_by`, `inspected_by`, `raised_by`, `resolved_by` FKs |
| SystemDropdown (`sys_dropdown_table`) | Transport consumes | Vehicle type, fuel type, ownership type, emission class, attendance status |
| Vendor (`vnd_vendors`) | Transport consumes | Vendor FK on hired/contracted vehicles |
| Vendor (`vnd_usage_logs`) | Transport produces | Trip usage log on trip approval — NOT YET WIRED |
| Vendor (`vnd_vendor_bill_due_for_payment`) | Transport produces | Maintenance cost billing — NOT YET WIRED |
| SystemMedia (`sys_media`) | Transport consumes | Spatie MediaLibrary for vehicle + personnel documents |
| ActivityLog (`sys_activity_logs`) | Transport produces | Audit entries for all transport changes |
| Notification (NTF) | Transport produces | Parent boarding/trip notifications — NOT YET WIRED |
| SchoolSetup (SCH) | Transport consumes | `sch_settings.trip_usage_needs_to_be_updated_into_vendor_usage_log` flag |
| Finance (FIN/ACC) | Future | Fee collection + maintenance expense vouchers → Accounting module |

**External dependencies (not yet implemented):**
- GPS Hardware API (TrackoBit, GPSTrack, or similar)
- Google Maps / Mapbox (partial — spatial data stored, map display partial)
- FCM / Firebase (token field present; push integration pending)
- SMS Gateway
- WhatsApp Business API

---

## Workflows (5 key workflows)

All 5 documented in V2 requirement Section 9:
1. **WF-TPT-01** — Student Boarding (QR Scan): scan → validate allocation → log boarding → notify parent → audit event log
2. **WF-TPT-02** — Trip Lifecycle: scheduler → create trip → depart → stop updates + boarding scans → complete → approve → vendor log
3. **WF-TPT-03** — Vehicle Inspection → Maintenance: 15 checkpoints → failed = auto service request → approved = maintenance record → completed = vendor bill + restore availability
4. **WF-TPT-04** — Driver Attendance (QR/Manual): scan IN → update summary → scan OUT → calculate total_work_minutes
5. **WF-TPT-05** — Student Allocation + Stop Change: allocate (deactivate prior) → stop change request → approve → new allocation record

---

## Business Rules (12 key rules)

| Rule | Summary |
|------|---------|
| BR-TPT-01 | Vehicle capacity hard block at 100%; warning at 90% |
| BR-TPT-02 | Vehicle with any expired compliance doc cannot be assigned to a new trip |
| BR-TPT-03 | Driver with expired license cannot be assigned as primary driver |
| BR-TPT-04 | Driver without police verification must be flagged; trip block is school-policy configurable |
| BR-TPT-05 | Trip status is one-directional: Scheduled → In Progress → Completed → Approved |
| BR-TPT-06 | Failed inspection auto-creates service request; vehicle set to unavailable |
| BR-TPT-07 | Student can have only one active_status=1 allocation per session; new allocation deactivates prior (atomic transaction) |
| BR-TPT-08 | Fuel entries are Pending by default; only Transport Manager/Admin can approve |
| BR-TPT-09 | Transport fee is monthly; mid-month proration is school-policy configurable |
| BR-TPT-10 | Maintenance approval → creates vendor bill in vnd_vendor_bill_due_for_payment |
| BR-TPT-11 | Trip approval → writes to vnd_usage_logs if sch_settings flag is true |
| BR-TPT-12 | Boarding scan valid only if: student allocated to route/stop, device registered, not duplicate |

---

## Reports (11 report types)

Route performance, Trip execution, Vehicle usage, Driver performance, Student boarding attendance, Student transport usage, Transport finance (fee/outstanding), Stop analysis, Cost maintenance, Management dashboard (KPI), Notifications report.

All views present in `report/` directory. Service layer for report queries (`TransportReportService`) not yet written — all queries currently inline in `TransportReportController`.

---

## Design Decisions Made

*(none yet — to be populated after FRD and audit sessions)*

---

## Lessons Learned

*(none yet — to be populated after session work)*

---

## Pending Next Steps

| # | Work | Agent | Input |
|---|------|-------|-------|
| 1 | Generate FRD | `act as Business Analyst` | "create an FRD for Transport" — 11 sub-modules, complex; allocate a full session |
| 2 | Fix P0 Gate typo | `act as Developer` | Find-replace `tested.attendance-device` → `tenant.attendance-device` in AttendanceDeviceController |
| 3 | Fix P0 PII encryption | `act as Developer` | Add encrypted casts to DriverHelper model; add id_no_hash column |
| 4 | Add EnsureTenantHasModule | `act as Developer` | Add middleware to transport route group in tenant.php |
| 5 | DDL gap migration | `act as DB Architect` | Create migration for DB-01 through DB-09 (missing standard columns); fix DB-15/16/17 naming |
| 6 | Service layer | `act as Backend Developer` | Implement 9 service classes (signatures in V2 req Appendix E) |
| 7 | Code audit | `act as Technical Auditor` | Full Gate::authorize() audit across all 31 controllers |

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-25 | Business Analyst | Knowledge file seeded from `TPT_Transport_Requirement.md` (V2, 2026-03-26) + `Transport_DDL_v2.3.sql`. No session work yet. |

---

## FRD Summary (2026-06-29)

| Item | Value |
|------|-------|
| FRD File | `4-Requirement_Module_wise/0-FRD_Documents/TPT_FRD_2026-06-29.md` (v1.0, flat folder) |
| Total REQ- | 23 (REQ-TPT-001..023, mapped from the 12 V2 FR groups + reports/dashboard/GPS/ML split out) |
| Total BR- | 26 (BR-TPT-001..026; derived fresh from 001 per ID-hygiene — NOT copied from V2's BR-TPT-01..12) |
| Workflows | 6 (boarding scan, trip lifecycle, inspection→service→maintenance, driver attendance, allocation+stop-change, fee charging) |
| Reports | 11 (RPT-TPT-001..011) |
| Enhancements | 10 (ENH-TPT-001..010 — GPS, ML, multi-channel notif, batch trips, shift seeder, ACC vouchers, portal stop-change, parent live-view, unverified-block toggle, student event log) |
| Priority split | P0 = 8 · P1 = 13 · P2 = 2 |

> **ID note:** No prior TPT FRD existed; REQ-/BR- numbered fresh from 001. The V2 doc's `FR-TPT-01..12` and `BR-TPT-01..12` are NOT the FRD contract — the FRD's `REQ-TPT-*`/`BR-TPT-*` are. Key BRs encode the safety/finance core: BR-TPT-002/003 (compliance/licence gating), BR-TPT-005/006 (trip FSM + approval), BR-TPT-009 (allocation atomicity), BR-TPT-014 (boarding-scan validation), BR-TPT-021 (Aadhaar/PII encryption), BR-TPT-022 (module-subscription gate).

> **Cross-ref to audit findings:** the FRD's Section 10.1 is the new baseline for gap analysis. Open audit items already known (SEC-TPT-01 Aadhaar plaintext, SEC-TPT-02 `tested.` gate typo on AttendanceDevice, RT-01 missing module middleware, 0 service classes, `TripController.php:587 dd($e)`, hardcoded Maps key in 3 pickup_point blades, 19/19 FormRequests authorize()=true) map directly onto BR-TPT-021/022, REQ-TPT-005, and the NFRs — a Mode B/C pass against this FRD is the natural next step.

## Pending Next Steps

- [ ] DDL Schema Gap → `act as DB Architect` — FRD §10.1 (25 entities incl. the 5 missing-DDL GPS/ML tables MD-05/06/07) vs `Transport_DDL_v2.3.sql`
- [ ] Application Code Gap → `act as Technical Auditor` (Mode B) — 23 REQ vs 30 controllers / 0 services
- [ ] Business-Rule Enforcement → `act as Technical Auditor` (Mode C) — 26 BRs, esp. BR-TPT-002/003/005/009/014/021/022
- [ ] Complete the in-progress Mode A audit (started 2026-06-29: confirmed `dd($e)` at TripController:587, Maps key in 3 blades, 19/19 FormRequests true, 0 enum in tpt migrations vs baseline's "19")

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-29 | Business Analyst | FRD v1.0 generated (`TPT_FRD_2026-06-29.md`) — 23 REQ, 26 BR, 6 workflows, 11 reports, 10 ENH. Synthesised from V2 req + 41 V1 screen specs + DDL (25 tables) + live code + this knowledge file. Saved to flat FRD folder. |

---

## Mode A Deep Audit (2026-06-29)

> Report: `3-Audit_Reports/V1_Jun-2026/Transport_Technical_Audit_2026-06-29.md` · Health **38/100** (P0 cap) · verified vs LIVE code.

### New codes
- **BUG-TPT-011 (P0):** `dd($e)` live in bulk trip-update catch (`TripController.php:587`).
- **FE-TPT-001 (P1):** committed Google Maps key in 3 pickup_point blades.
- **VAL-TPT-001 (P1):** 19/19 FormRequests `authorize()=true` (D30).
- **PERF-TPT-001 (P1):** god controllers (Mobile 1984/Report 1054/Trip 800) + eager tabs + unbounded `::all()`; 0 services.
- **MIG-TPT-001 (P2):** `tpt_trip.status` VARCHAR not dropdown FK; `is_active` missing (DB-03/10..13).
- **DEAD-TPT-002 (P2):** `TransportController.php-old` orphan.

### Re-confirmed OPEN
SEC-TPT-004 (`updateLastSeen` ungated + force-enables device), SEC-TPT-005 (Aadhaar/licence plaintext — no `encrypted` cast), TEN-RTG-001 (no `EnsureTenantHasModule` on transport group).

### ⚠ Snapshot corrections (this file was STALE — fixed against live code)
- **`tested.` gate typo (P0 #2 above) is FIXED** — `AttendanceDeviceController` now uses `tenant.attendance-device.*` on all 10 gated methods. *(Update the "P0 Production-Blocking Issues #2" section — it is resolved.)*
- **"Route capacity enforcement missing" is WRONG** — it IS implemented (`StudentAllocationController:137`, 100% block via `allow_extra_student_in_vehicale_beyond_capacity` setting; only the explicit 90% warning is absent).
- **Allocation atomicity present** — store/toggle wrapped in `DB::transaction` (`:74,488`).
- **D29 "tpt 19 enums" is WRONG** — tpt migrations have **0** `->enum()`; status columns are free-text VARCHAR (MIG-TPT-001).
- D36 generated-column degradation N/A (Transport DDL has no GENERATED columns).
- Still true: **0 service classes** (confirmed), Aadhaar plaintext, RT-01/TEN-RTG-001 module-middleware gap, `dd($e)`.

### Lessons Learned
- [2026-06-29 | Technical Auditor] Two of this file's four "P0 production blockers" were stale: the `tested.` gate typo and the missing capacity check were both already fixed/implemented in live code. Always re-verify snapshot P0s against the tree before reporting (STEP 1 reading discipline). Net live posture: 1 new P0 (dd) + 1 legal P0 (Aadhaar plaintext) remain.

## Version History (audit)

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-29 | Technical Auditor | Mode A 12-layer audit vs live code. Health 38/100. New: BUG-TPT-011, FE-TPT-001, VAL-TPT-001, PERF-TPT-001, MIG-TPT-001, DEAD-TPT-002. Re-confirmed SEC-TPT-004/005, TEN-RTG-001. Corrected stale snapshot: `tested.` typo FIXED, capacity enforced, allocation atomic, 0 enums. Report in `3-Audit_Reports/V1_Jun-2026/`. |

> **Mode X Complete Audit (2026-06-29):** `3-Audit_Reports/V1_Jun-2026/Transport_Complete_Audit_2026-06-29.md` — A+B+C+G+scoped-D unified. Deploy: NO-GO. BR enforcement 9 ENFORCED / 7 PARTIAL / 9 MISSING (+1 N/A). FRD code-gaps cluster in automation (notifications/expiry jobs), cross-module hand-offs (vendor bill/usage log), and boarding-scan validation; 0/23 REQ tested.
