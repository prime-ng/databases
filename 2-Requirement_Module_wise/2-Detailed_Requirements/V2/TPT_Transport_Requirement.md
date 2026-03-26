# TPT — Transport Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** FULL

---

## 1. Executive Summary

The Transport module is the largest and most operationally complex module in the Prime-AI platform. It manages end-to-end school bus operations for Indian K-12 schools: vehicle and driver master data, route and stop configuration, daily trip execution, student boarding attendance via QR/RFID, vehicle compliance tracking, maintenance lifecycle, transport fee collection, and GPS infrastructure stubs for future live tracking.

At development completion of approximately 55%, the module has a comprehensive UI layer (100+ blade views, 31 controllers, 42+ policies, 18 FormRequests) and a well-structured DDL (25 tables). However it has four production-blocking issues that require resolution before any school can go live: (1) a Gate prefix typo in `AttendanceDeviceController` that breaks all authorization on that sub-module, (2) Aadhaar/PAN numbers stored in plaintext in `tpt_personnel.id_no`, (3) the `EnsureTenantHasModule` middleware is missing from the transport route group (any tenant can access transport even if not licensed), and (4) zero service classes exist for 31 controllers, making all business logic untestable and difficult to maintain.

**Overall readiness score: 5.5/10.** The UI skeleton is strong; service layer, test coverage, and security hardening are the primary gaps.

---

## 2. Module Overview

| Attribute | Value |
|-----------|-------|
| Module Code | TPT |
| Module Name | Transport Management |
| DB Prefix | `tpt_` |
| Layer | Tenant Module (per-school isolated database) |
| RBS Reference | Module N — Transport Management |
| V1 Document Date | 2026-03-25 |
| V2 Document Date | 2026-03-26 |
| Completion (V1) | ~55% |
| Laravel Module Path | `Modules/Transport/` |
| Controller Count | 31 (+ 1 archived `.php-old`) |
| DDL Table Count | 25 tables |
| Model Count | 36 models (25 DDL-backed + 11 stub/ML/GPS) |
| FormRequest Count | 18 |
| Policy Count | 42+ |
| Test Count | 0 |

### Sub-module Areas

1. **Vehicle Management** — master data, documents, compliance expiry, fuel logs, maintenance lifecycle
2. **Route Management** — route/stop master, sequencing, stop-to-route mapping, spatial geometry
3. **Personnel Management** — driver and helper profiles, license tracking, police verification, attendance
4. **Student Transport Allocation** — session-based pickup/drop assignment, stop-change workflow
5. **Trip Management** — daily trip creation from schedulers, stop-by-stop tracking, incidents, approval
6. **Student Boarding Attendance** — QR/RFID scan events, boarding logs, parent notification
7. **Attendance Devices** — QR scanner / RFID reader device registry and management
8. **Transport Fee** — route-wise fee master, monthly fee schedule, collection, fines
9. **GPS Tracking** — data models and alert infrastructure (live integration is a planned stub)
10. **ML Route Optimization** — feature store and recommendation history (data structure only)
11. **Reports and Dashboard** — 11 report types, analytics dashboard

---

## 3. Stakeholders & Roles

| Role | Gate Prefix Pattern | Access Summary |
|------|---------------------|----------------|
| Super Admin / School Admin | All gates bypass via `before` hook | Full access |
| Transport Manager | `tenant.vehicle.*`, `tenant.route.*`, `tenant.trip.*`, etc. | Full CRUD on all transport sub-modules |
| Driver | `tenant.trip.view`, `tenant.driver-attendance.*` | View own trips; mark own attendance |
| Helper | `tenant.driver-attendance.*` | Mark own attendance |
| Accountant | `tenant.fee-master.*`, `tenant.fee-collection.*` | Transport fee entry and reports |
| Class Teacher / Coordinator | `tenant.student-allocation.viewAny` | Read-only student allocation view |
| Parent | (Student/Parent Portal module — future) | View own child bus location |

Permission gates follow the project-wide `tenant.{resource}.{action}` pattern. Six standard actions apply to each resource: `viewAny`, `view`, `create`, `update`, `delete`, `restore`, `forceDelete`.

---

## 4. Functional Requirements

Status indicators: ✅ Implemented | 🟡 Partial | ❌ Not Started | 📐 Proposed (new in V2)

### FR-TPT-01: Shift Master

**FR-TPT-01.1 — Shift Definition** ✅
- Define transport shifts with code, name, effective_from date, effective_to date.
- Shifts are referenced by routes, pickup points, route-stop junctions, and driver-route-vehicle assignments.
- Soft delete with restore.

**FR-TPT-01.2 — Shift Seeder** ❌
- No seeder exists for default transport shifts (Morning, Afternoon, Evening).
- Fresh install has no data; first-use requires manual setup.
- 📐 Create `TransportShiftSeeder` with the three standard shifts as default data.

### FR-TPT-02: Vehicle Management

**FR-TPT-02.1 — Vehicle Registration** ✅
- Capture: vehicle number (VIN/chassis), registration number, model, manufacturer.
- Vehicle type (FK to `sys_dropdown_table`: BUS, VAN, CAR), fuel type (FK: Diesel, Petrol, CNG, Electric), emission class (FK: BS IV, BS V, BS VI).
- Ownership type (FK: Owned, Leased, Rented) with vendor linkage for non-owned vehicles.
- Seating capacity and max capacity (integer).
- GPS device identifier (free-text field for device serial/IMEI).
- Availability status flag (boolean).
- Soft delete with restore and force-delete.

**FR-TPT-02.2 — Compliance Document Management** ✅
- Eight Spatie MediaLibrary collections: `vehicle_photo`, `registration_img`, `fitness_img`, `insurance_img`, `pollution_img`, `vehicle_emission_cert_img`, `fire_extinguisher_cert_img`, `gps_device_cert_img`.
- Per-document upload status tracked with boolean flags (`*_cert_upload` columns).
- Expiry dates: `fitness_valid_upto`, `insurance_valid_upto`, `pollution_valid_upto`, `fire_extinguisher_valid_upto`.

**FR-TPT-02.3 — Compliance Expiry Alerts** 🟡
- System must flag vehicles with any compliance document expiring within 30 days.
- Dashboard widget must display count of vehicles with expired or near-expiry documents per category.
- 📐 Auto-set `availability_status = 0` when any compliance document expires (requires scheduled job).
- Alert categories: fitness certificate, insurance, pollution certificate, fire extinguisher.

**FR-TPT-02.4 — Fuel Log Management** ✅
- Record per-vehicle fuel entries: date, quantity (litres), cost, fuel type (FK dropdown), odometer reading, driver, remarks.
- Fuel log approval workflow: Pending → Approved / Rejected.
- Only Transport Manager or Admin can approve; approval stores `approved_by` and `approved_at`.
- Calculate fuel efficiency (km/litre) from consecutive odometer readings.

**FR-TPT-02.5 — Vendor Integration for Hired Vehicles** ✅
- `tpt_vehicle.vendor_id` FK to `vnd_vendors.id`.
- `VehicleController` queries vendor dropdown using `sys_dropdown_table` key for vendor type.
- 🟡 `tpt_notification_log` vendor usage log integration (triggered on trip approval) is not yet implemented as service code. DDL comment references `trip_usage_needs_to_be_updated_into_vendor_usage_log` setting in `sch_settings`.

### FR-TPT-03: Route Management

**FR-TPT-03.1 — Route Setup** ✅
- Define routes: code (unique), name (unique), description, direction enum (Pickup / Drop), shift FK.
- Route geometry stored as `LINESTRING SRID 4326` with spatial index for map display.
- Soft delete with restore.

**FR-TPT-03.2 — Pickup Point (Stop) Master** ✅
- Define stops: code (unique), name (unique), latitude/longitude (DECIMAL), POINT geometry (SRID 4326, spatial index).
- Stop type enum (Pickup / Drop / Both).
- Total distance and estimated time from depot (informational).
- Shift FK for operational grouping.

**FR-TPT-03.3 — Route-Stop Assignment (Junction)** ✅
- `tpt_pickup_points_route_jnt` assigns stops to routes with ordinal sequence.
- Per-assignment: arrival time (minutes from start), departure time, estimated time, one-side fare, both-side fare.
- Unique constraint: one stop appears on a route only once.
- Index on `(route_id, ordinal)` for ordered stop retrieval.

**FR-TPT-03.4 — Driver-Route-Vehicle Assignment** ✅
- `tpt_driver_route_vehicle_jnt` records date-range assignments: shift, route, vehicle, driver, helper, direction, `effective_from`, `effective_to`.
- DB trigger `trg_driver_route_vehicle_unique_assignment` prevents overlapping assignments for the same shift+route+vehicle+driver combination.
- `total_students` counter maintained on junction record.
- Historical records preserved (no hard overwrite).

**FR-TPT-03.5 — Route Capacity Enforcement** 🟡
- `tpt_vehicle.capacity` defines the maximum student allocation per vehicle per route.
- 📐 `TransportAllocationService` must enforce: new allocation rejected if route vehicle at 100% capacity; warning emitted at 90%.
- Current code: no capacity check in `StudentAllocationController` at save time.

**FR-TPT-03.6 — Stop Change Request Workflow** 🟡
- Parent or admin requests stop change for a student.
- Transport Manager approves or rejects.
- On approval: new `tpt_student_route_allocation_jnt` record created with updated `effective_from`; prior record deactivated (not deleted).
- 📐 `TransportAllocationService::requestStopChange()` and `approveStopChange()` methods required.
- Current code: model relationships exist but controller workflow is incomplete.

### FR-TPT-04: Personnel Management (Drivers & Helpers)

**FR-TPT-04.1 — Personnel Profile** ✅
- Unified `tpt_personnel` table for Drivers, Helpers, and Transport Managers (role field).
- QR code for attendance scanning (`user_qr_code`), ID card type enum (QR / RFID / NFC / Barcode).
- ID type (Aadhaar / PAN / Voter ID / Passport / Licence), ID number (PII — see SEC-TPT-01).
- License number, license expiry date, driving experience (months), assigned vehicle FK, police verification boolean, address.
- Document upload flags: ID card, photo, driving license, police verification certificate, address proof.
- System user linkage (`user_id`) for app-based attendance.
- Soft delete with restore.

**FR-TPT-04.2 — License Expiry Monitoring** 🟡
- Alert Transport Manager when any driver license expires within 30 days.
- 📐 Scheduled job (daily) queries `tpt_personnel` where `license_valid_upto <= NOW() + 30 days` and sends alerts.
- Dashboard widget: count of drivers with expired or near-expiry licenses.

**FR-TPT-04.3 — Police Verification Tracking** ✅
- `police_verification_done` boolean on `tpt_personnel`.
- Dashboard widget showing count of personnel without completed verification.
- 📐 Business rule: configurable school policy — alert-only vs hard-block trip assignment for unverified personnel.

**FR-TPT-04.4 — Driver Attendance (QR/Device)** ✅
- `tpt_driver_attendance` records daily attendance: driver FK, date (unique per driver per day), first-in time, last-out time, total work minutes, attendance status (FK to dropdown: Present / Absent / Half-Day / Late), `via_app` flag.
- `tpt_driver_attendance_log` stores each individual punch event: scan time, attendance type (IN/OUT), scan method enum (QR/RFID/NFC/Manual), device FK, lat/lon (for location-stamped punches), scan status (Valid/Duplicate/Rejected).
- `total_work_minutes` calculated as `(last_out - first_in)` in minutes.

**FR-TPT-04.5 — Attendance Device Management** 🟡 (**CRITICAL BUG — see SEC-TPT-02**)
- `tpt_attendance_device` registers QR scanner / RFID reader devices: device UUID (unique), device type, OS, model, app version, FCM token.
- Device linked to a `tpt_personnel` user via FK.
- `pg_last_seen_at` timestamp updated on each scan.
- **All authorization in `AttendanceDeviceController` is broken due to Gate prefix typo** (see Section 8 and SEC-TPT-02).

### FR-TPT-05: Route Scheduler

**FR-TPT-05.1 — Schedule Template** ✅
- `tpt_route_scheduler_jnt` defines a recurring slot: scheduled date, shift, route, vehicle, driver, helper, direction.
- Unique constraints prevent double-booking of the same vehicle or driver on the same date+shift+direction.
- Route schedulers serve as templates for daily trip generation.

**FR-TPT-05.2 — Auto Trip Generation** 🟡
- Route scheduler records feed into `tpt_trip` generation.
- 📐 `TransportTripService::generateTripsFromScheduler(date)` should batch-create trip records for all active route schedulers for a given date.
- Current code: manual trip creation exists; batch generation from scheduler is not fully implemented.

### FR-TPT-06: Trip Management

**FR-TPT-06.1 — Trip Lifecycle** ✅
- `tpt_trip` captures: trip date, route scheduler FK, route, vehicle, driver, helper, direction.
- Operational fields: `start_time`, `end_time`, `start_odometer_reading`, `end_odometer_reading`, `start_fuel_reading`, `end_fuel_reading`.
- Status: Scheduled → In Progress → Completed → Approved (one-directional).
- Approval: `approved` boolean, `approved_by` (user FK), `approved_at` timestamp.
- `deleted_at` for soft delete; note: DDL gap — `is_active` column is missing (DB-03).

**FR-TPT-06.2 — Trip Stop Details** ✅
- `tpt_trip_stop_detail` records per-stop events within a trip.
- Fields: trip FK, stop FK, direction, scheduled arrival/departure (DATETIME), `reached_flag` (boolean), `reaching_time`, `leaving_time`.
- Emergency fields: `emergency_flag`, `emergency_time`, `emergency_remarks`.
- `updated_by` FK to `tpt_personnel` for driver-entered updates.

**FR-TPT-06.3 — Trip Incidents** 🟡
- `tpt_trip_incidents` captures incidents during a trip: incident time, type (FK dropdown), severity enum (LOW/MEDIUM/HIGH), GPS coordinates, description.
- Resolution fields: `raised_by`, `raised_at`, `resolved_by`, `resolved_at`, status FK dropdown.
- `TripMgmtController::resolveIncident()` method present; full resolution workflow needs `TripIncidentRequest` FormRequest.

**FR-TPT-06.4 — Live Trip (GPS Stub)** 🟡
- `TptLiveTrip` and `TptGpsTripLog` models exist as GPS infrastructure stubs.
- `TptGpsAlerts` stores triggered geofence/deviation alerts.
- `LiveTripController` and `LiveTripRequest` present.
- 📐 DDL definitions for `tpt_live_trip`, `tpt_gps_trip_log`, `tpt_gps_alerts` are missing from `tenant_db_v2.sql` — must be added before GPS integration (MD-06).

**FR-TPT-06.5 — Vendor Usage Log Integration** ❌
- DDL comment in `tpt_notification_log` section references: when a trip is approved, if `trip_usage_needs_to_be_updated_into_vendor_usage_log` setting is `true` in `sch_settings`, the system must write a record to `vnd_usage_logs`.
- No service code implements this; blocked pending Vendor Usage Log schema finalization.

### FR-TPT-07: Student Boarding Attendance

**FR-TPT-07.1 — Boarding Log** ✅
- `tpt_student_boarding_log` records per-student-per-trip-date events: boarding route, trip, stop, time; un-boarding route, trip, stop, time.
- Device FK links to the attendance device that scanned the event.
- Student FK and student session FK both present (corrected from V1 DDL gap DB-14 which showed missing `student_id`).

**FR-TPT-07.2 — QR/RFID Scan Flow** 🟡
- Driver or helper scans student QR/RFID at each stop.
- System must validate: student is allocated to this route and stop for the current session.
- Creates `tpt_student_boarding_log` record on valid scan.
- 📐 `TransportAttendanceService::processBoardingScan(deviceUuid, studentQr, tripId, stopId)` required as central validation point.

**FR-TPT-07.3 — Parent Notification on Boarding** 🟡
- `tpt_notification_log` records notification sent to parent on boarding event.
- Notification types: TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled.
- Channels: App push, SMS, Email, WhatsApp (each tracked independently with Sent/Failed/NotRegistered status).
- Current code: log model present; integration with Notification module not yet wired.

**FR-TPT-07.4 — Student Event Log** ❌
- `TptStudentEventLog` model exists for audit trail of all student transport events (boarding, un-boarding, absent, stop change).
- No corresponding DDL table in `tenant_db_v2.sql` (MD-07).
- 📐 Add DDL for `tpt_student_event_log` and implement population in boarding and allocation workflows.

### FR-TPT-08: Vehicle Inspection and Maintenance

**FR-TPT-08.1 — Pre-Trip Inspection** ✅
- `tpt_daily_vehicle_inspection` records 15-checkpoint checklist: tires, lights, brakes, engine, battery, fire extinguisher, first aid kit, seat belts, headlights, taillights, wipers, mirrors, steering wheel, emergency tools, cleanliness.
- Overall status: Passed / Failed / Pending.
- `any_issues_found` boolean; `issues_description` text.
- `inspected_by` (user FK), `inspected_at` timestamp.

**FR-TPT-08.2 — Service Request** ✅
- `tpt_vehicle_service_request` raised when inspection fails or issue found.
- FK to `tpt_daily_vehicle_inspection`; request date, reason, vehicle status FK dropdown, approval workflow fields.
- Business rule: direct entry to `tpt_vehicle_maintenance` is not allowed — must go through service request approval.
- On request creation: vehicle `availability_status` must be set to `false`.

**FR-TPT-08.3 — Maintenance Record** ✅
- `tpt_vehicle_maintenance` created from an approved service request (FK to `tpt_vehicle_service_request`).
- Fields: maintenance initiation date, maintenance type (free text), cost, in-service date, out-service date, workshop details, next due date, status (Pending / Approved / Rejected), approval fields.
- On maintenance approval: post expense to `vnd_vendor_bill_due_for_payment` (DDL comment condition; not yet implemented as service code).
- On out-service date set: vehicle `availability_status` restored to `true`.

### FR-TPT-09: Student Transport Allocation

**FR-TPT-09.1 — Allocation Record** ✅
- `tpt_student_route_allocation_jnt` links a student session to pickup route + stop and drop route + stop.
- Fare amount and effective_from date captured.
- One active allocation per student per academic session (enforced via `active_status` flag).
- Bulk import via Excel (`StudentAllocationImport`); export via `StudentAllocationExport`.

**FR-TPT-09.2 — Allocation Uniqueness** 📐
- Creating a new allocation must deactivate the prior record (set `active_status = 0`) and record the new `effective_from` date.
- 📐 Implement in `TransportAllocationService::allocate()` — check for existing active record, deactivate it, then insert new record in a database transaction.

**FR-TPT-09.3 — Session Reference** ✅
- `student_session_id` FK to `std_student_sessions_jnt`.
- `student_id` FK to `std_students` also present (corrected in V2 DDL).

### FR-TPT-10: Transport Fee Management

**FR-TPT-10.1 — Fine Master** ✅
- `tpt_fine_master` defines fine rules per academic session: day range (fine_from_days, fine_to_days), type (Fixed / Percentage), rate, student restriction flag.
- DDL gaps: missing `updated_at`, `is_active`, `created_by` columns (DB-06) — must be added.

**FR-TPT-10.2 — Monthly Fee Schedule** ✅
- `tpt_student_fee_detail` records a monthly fee entry per student session: month (DATE), amount, fine amount, total, due date, status (VARCHAR — propose FK to dropdown).
- Import via `FeeMasterImport`; export via `FeeMasterExport`; PDF generation present.
- DDL gaps: missing `updated_at`, `is_active`, `created_by` (DB-07).

**FR-TPT-10.3 — Fine Detail per Student** ✅
- `tpt_student_fine_detail` links a fee detail record to a fine master rule.
- Fields: fine days elapsed, type, rate, gross fine, waived amount, net fine.
- DDL gaps: missing `updated_at`, `is_active`, `created_by` (DB-08).

**FR-TPT-10.4 — Fee Collection** ✅
- `tpt_student_fee_collection` records payments: fee detail FK, payment date, delay days, paid amount, payment mode (VARCHAR — propose FK to dropdown), status (VARCHAR — propose FK), reconciled flag.
- DDL gaps: missing `updated_at`, `is_active`, `created_by` (DB-09).
- Export via `FeeCollectionExport`.

**FR-TPT-10.5 — Payment Log** ✅
- `std_student_pay_log` (shared cross-module log table) records every payment activity referencing the transport module: module_name, activity_type, amount, reference_id, reference_table, triggered_by.

**FR-TPT-10.6 — Route-Wise Fee Master** ✅
- `StudentRouteFeesController` manages route-to-fare linking for auto-assignment during student allocation.
- Stop-level fare also captured on `tpt_pickup_points_route_jnt` (`pickup_drop_fare`, `both_side_fare`).

**FR-TPT-10.7 — Accounting Integration** ❌
- When transport fee is collected, a payment receipt must eventually post to `acc_vouchers` in the Accounting module.
- When maintenance is approved, an expense voucher must post to the Accounting module.
- Blocked pending Accounting (ACC/FAC) module implementation.

### FR-TPT-11: Reports and Analytics

**FR-TPT-11.1 — Report Types** 🟡
- 11 report types with views present in `report/` directory and routes in `TransportReportController`.
- Report categories:
  1. Route performance (stops coverage, on-time percentage, average delay)
  2. Trip execution (trips per route, per vehicle, completion rate)
  3. Vehicle usage (km covered, fuel consumed, cost per km)
  4. Driver performance (attendance rate, on-time departures)
  5. Student boarding attendance (per route or per student, daily)
  6. Student transport usage (sessions, routes used, boarding count)
  7. Transport finance (fee collected, outstanding, overdue by route)
  8. Stop analysis (students per stop, utilization per stop)
  9. Cost maintenance (per vehicle, per period, per category)
  10. Management dashboard (KPI summary for Transport Manager)
  11. Notifications report (delivery rates per channel)

**FR-TPT-11.2 — Service Layer for Reports** ❌
- 📐 `TransportReportService` must encapsulate all report queries, replacing inline controller queries.
- Must support date-range filtering, route filter, vehicle filter, and export (CSV/PDF) for each report type.

**FR-TPT-11.3 — Dashboard** 🟡
- `TransportDashboardController` provides AJAX data endpoint.
- 📐 Dashboard KPIs should include: active trips today, vehicles with expiring documents (30-day window), drivers with expiring licenses, students without allocation (active session), pending service requests, fee outstanding total.

### FR-TPT-12: ML Route Optimization (Stub)

**FR-TPT-12.1 — Data Models** 🟡
- `MlModels`, `MlModelFeatures`, `TptFeatureStore`, `TptModelRecommendations`, `TptRecommendationHistory` models exist.
- No corresponding DDL tables in `tenant_db_v2.sql` (MD-05) — must add DDL if this feature is to be built.
- No inference or training pipeline implemented.
- 📐 Deprioritized to Phase 4 pending ML infrastructure decision.

---

## 5. Data Model

### 5.1 DDL Tables (25 in tenant_db_v2.sql)

| # | Table | DDL Line | Description |
|---|-------|----------|-------------|
| 1 | `tpt_vehicle` | 1131 | Vehicle master: registration, compliance docs, expiry dates, vendor link |
| 2 | `tpt_personnel` | 1171 | Drivers and helpers: license, PII (ID/Aadhaar), police verification |
| 3 | `tpt_shift` | 1200 | Shift master: code, name, effective dates |
| 4 | `tpt_route` | 1214 | Route master: code, name, direction enum, shift FK, LINESTRING geometry |
| 5 | `tpt_pickup_points` | 1232 | Stop master: code, name, lat/lon, POINT geometry, stop_type enum |
| 6 | `tpt_pickup_points_route_jnt` | 1253 | Route-stop junction: ordinal, times, fares |
| 7 | `tpt_driver_route_vehicle_jnt` | 1281 | Driver+vehicle+route assignment with date range |
| 8 | `tpt_route_scheduler_jnt` | 1328 | Recurring schedule template per date |
| 9 | `tpt_trip` | 1356 | Daily trip: vehicle, driver, odometer, fuel, status |
| 10 | `tpt_trip_stop_detail` | 1386 | Per-stop arrival/departure within a trip |
| 11 | `tpt_attendance_device` | 1412 | QR/RFID device registry |
| 12 | `tpt_driver_attendance` | 1436 | Daily driver attendance summary |
| 13 | `tpt_driver_attendance_log` | 1451 | Punch-level log (IN/OUT per device) |
| 14 | `tpt_student_route_allocation_jnt` | 1471 | Student pickup/drop allocation per session |
| 15 | `tpt_fine_master` | 1496 | Fine rule definitions per session |
| 16 | `tpt_student_fee_detail` | 1509 | Monthly fee record per student session |
| 17 | `tpt_student_fine_detail` | 1523 | Fine instance applied to a fee record |
| 18 | `tpt_student_fee_collection` | 1540 | Fee payment record |
| 19 | `std_student_pay_log` | 1557 | Cross-module payment audit log (shared) |
| 20 | `tpt_vehicle_fuel` | 1588 | Fuel entry per vehicle |
| 21 | `tpt_daily_vehicle_inspection` | 1609 | 15-checkpoint pre-trip checklist |
| 22 | `tpt_vehicle_service_request` | 1650 | Service request raised from inspection |
| 23 | `tpt_vehicle_maintenance` | 1675 | Actual repair record (from approved service request) |
| 24 | `tpt_trip_incidents` | 1704 | In-trip incidents: type, severity, GPS, resolution |
| 25 | `tpt_notification_log` | 1766 | Parent notification events per trip/student |

### 5.2 Models Without DDL Tables (to be resolved)

| Model | Gap Type | Action Required |
|-------|----------|-----------------|
| `TptGpsAlerts` | Missing DDL (MD-06) | Add DDL table `tpt_gps_alerts` |
| `TptGpsTripLog` | Missing DDL (MD-06) | Add DDL table `tpt_gps_trip_log` |
| `TptLiveTrip` | Missing DDL (MD-06) | Add DDL table `tpt_live_trip` |
| `TptStudentEventLog` | Missing DDL (MD-07) | Add DDL table `tpt_student_event_log` |
| `MlModels` | Missing DDL (MD-05) | Add DDL or remove model |
| `MlModelFeatures` | Missing DDL (MD-05) | Add DDL or remove model |
| `TptFeatureStore` | Missing DDL (MD-05) | Add DDL or remove model |
| `TptModelRecommendations` | Missing DDL (MD-05) | Add DDL or remove model |
| `TptRecommendationHistory` | Missing DDL (MD-05) | Add DDL or remove model |

### 5.3 DDL Column Gaps (from Gap Analysis)

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
| DB-10 | `tpt_trip.status` | Should be FK to `sys_dropdown_table` not VARCHAR | P2 |
| DB-11 | `tpt_student_fee_detail.status` | Should be FK not VARCHAR | P2 |
| DB-12 | `tpt_student_fee_collection.status` | Should be FK not VARCHAR | P2 |
| DB-13 | `tpt_student_fee_collection.payment_mode` | Should be FK not VARCHAR | P2 |
| DB-15 | `tpt_fine_master.Remark` | Uppercase R — use `remark` | P3 |
| DB-16 | `tpt_daily_vehicle_inspection` | `Create Table` lowercase keyword | P3 |
| DB-17 | `tpt_vehicle_service_request.Vehicle_status` | Uppercase V — use `vehicle_status` | P3 |

### 5.4 Key Relationships

```
tpt_vehicle 1—N tpt_daily_vehicle_inspection
tpt_daily_vehicle_inspection 1—1 tpt_vehicle_service_request
tpt_vehicle_service_request 1—1 tpt_vehicle_maintenance
tpt_vehicle 1—N tpt_vehicle_fuel

tpt_personnel (driver) 1—N tpt_driver_attendance
tpt_driver_attendance 1—N tpt_driver_attendance_log
tpt_attendance_device 1—N tpt_driver_attendance_log

tpt_shift 1—N tpt_route
tpt_shift 1—N tpt_pickup_points
tpt_route N—N tpt_pickup_points (via tpt_pickup_points_route_jnt)
tpt_route N—N tpt_personnel N—N tpt_vehicle (via tpt_driver_route_vehicle_jnt)
tpt_route_scheduler_jnt 1—N tpt_trip

tpt_trip 1—N tpt_trip_stop_detail
tpt_trip 1—N tpt_trip_incidents
tpt_trip 1—N tpt_student_boarding_log
tpt_trip 1—N tpt_notification_log

std_students N—N tpt_route (via tpt_student_route_allocation_jnt)
tpt_student_route_allocation_jnt.student_id → std_students.id
tpt_student_route_allocation_jnt.student_session_id → std_student_sessions_jnt.id

tpt_student_fee_detail → std_student_sessions_jnt (academic sessions)
tpt_student_fee_detail 1—N tpt_student_fine_detail
tpt_student_fee_detail 1—N tpt_student_fee_collection
```

### 5.5 Trigger

`trg_driver_route_vehicle_unique_assignment` — BEFORE INSERT on `tpt_driver_route_vehicle_jnt`. Raises `SQLSTATE '45000'` if an overlapping date-range assignment exists for the same shift+route+vehicle+driver. Note: this only fires on INSERT, not UPDATE — update logic must replicate the overlap check in application code.

---

## 6. API Endpoints & Routes

### 6.1 Route Group Configuration

```php
// tenant.php — Transport route group
Route::prefix('transport')->name('transport.')->middleware([
    'auth',
    'verified',
    'tenancy.enforce',          // currently applied
    // 'EnsureTenantHasModule',  // MISSING — RT-01 critical bug
])->group(function () { ... });
```

**RT-01 (P0 Bug):** `EnsureTenantHasModule` middleware is NOT applied to the transport route group. Any tenant can access transport endpoints even if the Transport module is not licensed in their subscription. Must add before production.

### 6.2 Controller Inventory (31 controllers)

| Controller | Route Prefix / Pattern | Auth Gates | Notes |
|------------|------------------------|------------|-------|
| `TransportMasterController` | `transport-master` | Yes | Hub controller — tabbed view |
| `TransportDashboardController` | `dashboard/data` | Yes | AJAX data endpoint |
| `VehicleController` | via master | Yes | Vehicle CRUD + documents |
| `VehicleMgmtController` | via master | Partial | Vehicle management sub-actions |
| `RouteController` | via master | Yes | Route CRUD |
| `PickupPointController` | via master | Yes | Stop CRUD + map |
| `PickupPointRouteController` | via master | Yes | Route-stop assignment |
| `ShiftController` | via master | Yes | Shift CRUD |
| `DriverHelperController` | via master | Yes | Personnel CRUD + documents |
| `DriverRouteVehicleController` | via master | Yes | Assignment junction CRUD |
| `RouteSchedulerController` | via master | Yes | Scheduler CRUD + createtrip view |
| `NewTripController` | via master | Yes | New trip creation |
| `TripController` | via master | Yes | Trip CRUD |
| `TripMgmtController` | `trip-management` | Yes | Trip mgmt + incident resolve |
| `LiveTripController` | via master | Yes | Live trip GPS stub |
| `DriverAttendanceController` | via master | Yes | Driver attendance CRUD + QR |
| `AttendanceDeviceController` | via master | **BROKEN** | Gate prefix is `tested.*` not `tenant.*` |
| `StudentAllocationController` | via master | Yes | Allocation CRUD + import/export |
| `StudentAttendanceController` | via master | Yes | Student boarding attendance |
| `StudentBoardingController` | via master | Yes | Boarding log CRUD |
| `TptDailyVehicleInspectionController` | via master | Yes | Inspection CRUD |
| `TptVehicleServiceRequestController` | via master | Yes | Service request CRUD + approval |
| `TptVehicleMaintenanceController` | via master | Yes | Maintenance CRUD + approval |
| `TptVehicleFuelController` | via master | Yes | Fuel log CRUD + approval |
| `FeeMasterController` | via master | Yes | Fee master CRUD + PDF |
| `FeeCollectionController` | via master | Yes | Fee collection CRUD |
| `StudentRouteFeesController` | `std-route-Fees-mgmt` | Yes | Route-fee mapping |
| `FineMasterController` | via master | Yes | Fine rule CRUD |
| `TptStudentFineDetailController` | via master | Yes | Student fine instance CRUD |
| `StaffMgmtController` | via master | Yes | Staff management tab view |
| `TransportReportController` | `transport-report` | Yes | 11 report endpoints |

### 6.3 Standard Route Patterns Per Resource

Each resource follows the standard pattern (example: vehicle):
```
GET    transport/vehicle              index
GET    transport/vehicle/create       create
POST   transport/vehicle              store
GET    transport/vehicle/{id}         show
GET    transport/vehicle/{id}/edit    edit
PUT    transport/vehicle/{id}         update
DELETE transport/vehicle/{id}         destroy
GET    transport/vehicle/trash        trashed
POST   transport/vehicle/{id}/restore restore
DELETE transport/vehicle/{id}/force   forceDelete
POST   transport/vehicle/{id}/toggle  toggleStatus
```

Approximately 150+ routes total under the `transport.*` prefix.

### 6.4 Named Route Examples

```
transport.transport-master.index
transport.vehicles.ajax
transport.dashboard.data
transport.route.index / .create / .store / .edit / .update / .destroy
transport.pickup-point.index / .create ...
transport.driver-route-vehicle.index ...
transport.trip.index / .store ...
transport.trip-management.index
transport.driver-attendance.index / .qr
transport.student-allocation.index / .import / .export
transport.attendance-device.index   (currently broken — Gate prefix typo)
transport.fee-master.index / .pdf
transport.fee-collection.index / .export
transport.transport-report.route-performance ...
```

---

## 7. UI Screens

### 7.1 Screen Inventory (100+ blade views)

| Area | Directory | View Count | Status |
|------|-----------|------------|--------|
| Vehicle | `vehicle/` | 6 (index, create, edit, show, trash + partials) | ✅ |
| Route | `route/` | 5 | ✅ |
| Shift | `shift/` | 5 | ✅ |
| Pickup Point | `pickup_point/` | 6 (inc. map view) | ✅ |
| Pickup Point Route | `pickup_point_route/` | 5 | ✅ |
| Driver/Helper | `driver_helper/` | 5 | ✅ |
| Driver Route Vehicle | `driver_route_vehicle/` | 5 | ✅ |
| Route Scheduler | `route-scheduler/` | 6 (inc. createtrip) | ✅ |
| Trip | `trip/` | 5 | ✅ |
| Live Trip | `live-trip/` | 5 | 🟡 GPS stub |
| Driver Attendance | `driver-attendance/` | 6 (inc. QR scanner view) | ✅ |
| Student Allocation | `student-allocation/` | 7 (inc. JS + import modal) | ✅ |
| Attendance Device | `attendance_device/` | 5 | 🟡 Auth broken |
| Fee Master | `fee-master/` | 6 (inc. PDF view) | ✅ |
| Fee Collection | `fee-collection/` | 4 | ✅ |
| Fine Master | `fine-master/` | 5 | ✅ |
| Fine Details | `fine-details/` | 4 | ✅ |
| Vehicle Fuel | `vehicle_fuel/` | 5 | ✅ |
| Daily Inspection | `daily-vehicle-Inspection/` | 5 | ✅ |
| Vehicle Maintenance | `vehiclemaintenance/` | 3 | ✅ |
| Service Request | `vehicle-service-request/` | 6 (inc. approval tab) | ✅ |
| Trip Details | `trip-details/` | 4 | 🟡 |
| Trip Incidents | `trip-incidents/` | 2 | 🟡 |
| Trip Approve | `trip_approve/` | 3 | ✅ |
| Student Boarding/Unboarding | `student-bord-unbord/` | 3 | 🟡 |
| Student Attendance | `student_attendance/` | 1 | 🟡 |
| Dashboard | `dashboard/` | 1 | 🟡 |
| Reports | `report/` | 10 report views | 🟡 |
| Tab Modules | `tab_module/` | 6 tab layout views | ✅ |
| Logs | `logs/` | 2 | 🟡 |

### 7.2 Screen Notes

- Tab-based architecture: `TransportMasterController`, `StaffMgmtController`, `VehicleMgmtController`, `TripMgmtController`, `StudentRouteFeesController` each load all sub-resource data in a single request (CT-04/PERF-01). These must be refactored to lazy-load tabs via AJAX.
- View directory naming is inconsistent: `daily-vehicle-Inspection/` (capital I), mix of `snake_case` and `kebab-case`. Standardize to kebab-case.

---

## 8. Business Rules

### BR-TPT-01: Vehicle Capacity Enforcement
- A route's active student allocations must not exceed the vehicle's `capacity` field.
- System must block allocation if vehicle is at 100% capacity.
- System must emit warning when allocations reach 90% of capacity.
- Implementation: `TransportAllocationService::checkCapacity(routeId, sessionId)`.

### BR-TPT-02: Compliance Enforcement on Trip Assignment
- A vehicle with any expired compliance document (fitness, insurance, pollution, fire extinguisher) must not be assigned to a new trip.
- Vehicle `availability_status` must auto-set to `false` when any document expires (scheduled job).
- Trip creation must validate vehicle `availability_status = 1` before saving.
- Expiry alert threshold: 30 days in advance to Transport Manager.

### BR-TPT-03: Driver License Validation on Trip Assignment
- A driver with expired `license_valid_upto` must not be assigned as primary driver for a new trip.
- License expiry alert: 30 days advance notice via dashboard and notification.

### BR-TPT-04: Police Verification
- A driver/helper without `police_verification_done = true` must be flagged on the dashboard.
- Trip assignment behavior is school-policy configurable: alert-only (default) or hard block.

### BR-TPT-05: Trip Status Lifecycle
- Status transitions are one-directional: `Scheduled → In Progress → Completed → Approved`.
- A Completed trip cannot revert to In Progress.
- Only a user with `tenant.trip-approve.create` Gate permission can set status to Approved.

### BR-TPT-06: Inspection-to-Maintenance Pipeline
- When `inspection_status = Failed` is saved, the system must automatically create a `tpt_vehicle_service_request` record (or block inspection save until service request is raised).
- A vehicle with a Pending/open service request must have `availability_status = 0`.
- Direct creation of `tpt_vehicle_maintenance` records is not allowed — must flow through approved service request.

### BR-TPT-07: Student Allocation Uniqueness
- A student can have only one record with `active_status = 1` per academic session.
- Creating a new allocation must deactivate the prior record before inserting the new one (atomic transaction).

### BR-TPT-08: Fuel Log Approval
- Fuel entries default to `status = Pending`.
- Only Transport Manager or Admin can approve fuel entries.
- Rejected entries are preserved in history with rejection reason.

### BR-TPT-09: Transport Fee Monthly Charging
- Transport fee is per calendar month.
- Mid-month route change proration rule is school-policy configurable (full month or prorated from effective date).

### BR-TPT-10: Maintenance Creates Vendor Bill
- When `tpt_vehicle_maintenance.status` transitions to `Approved`, an entry must be created in `vnd_vendor_bill_due_for_payment` for the maintenance cost.
- Controlled by: DDL comment condition, not yet implemented as service code.

### BR-TPT-11: Vendor Usage Log from Trip Approval
- When a trip is approved, if school setting `trip_usage_needs_to_be_updated_into_vendor_usage_log = true`, a usage log entry must be written to `vnd_usage_logs`.

### BR-TPT-12: Boarding Scan Validation
- QR/RFID scan accepted only if: (a) student has an active allocation for the current session, (b) the scanned stop matches the allocated stop for the route direction, (c) the device is registered and active.
- Duplicate scan on same trip returns `scan_status = Duplicate` in `tpt_driver_attendance_log` pattern.

---

## 9. Workflows

### WF-TPT-01: Student Boarding (QR Scan)

```
1. Bus arrives at stop
   Driver/helper scans student QR code on AttendanceDevice (RFID/QR scanner)
2. System receives scan:
   TransportAttendanceService::processBoardingScan(deviceUuid, qrCode, tripId, stopId)
   → Validate: device registered + active
   → Look up student by qr_code → validate active allocation for route/stop/session
   → On valid: INSERT tpt_student_boarding_log (boarding fields)
   → On invalid: log error, return failure response to device
3. Notification triggered:
   → INSERT tpt_notification_log (TripStart / ReachedStop / ApproachingStop)
   → Notification module sends push/SMS/WhatsApp to parent
4. Audit:
   → INSERT tpt_student_event_log (event_type = Boarded)
5. Return trip (afternoon):
   → Same flow for un-boarding fields (unboarding_route_id, unboarding_trip_id, etc.)
```

### WF-TPT-02: Trip Lifecycle

```
1. Route scheduler template exists for the date (from RouteSchedulerController)
2. Transport Manager creates trip:
   TransportTripService::createFromScheduler(schedulerId, date)
   → Validate vehicle availability_status = 1, driver license not expired
   → INSERT tpt_trip (status = Scheduled)
3. Driver departs depot:
   → UPDATE tpt_trip: status = In Progress, start_time, start_odometer, start_fuel
4. At each stop:
   → INSERT tpt_trip_stop_detail (reached_flag = 1, reaching_time)
   → QR scan triggers boarding log (WF-TPT-01)
5. Trip ends at school:
   → UPDATE tpt_trip: end_time, end_odometer, end_fuel, status = Completed
6. Transport Manager reviews:
   → UPDATE tpt_trip: approved = 1, approved_by, approved_at, status = Approved
   → IF setting trip_usage_needs_to_be_updated_into_vendor_usage_log = true:
       INSERT vnd_usage_logs
```

### WF-TPT-03: Vehicle Inspection to Maintenance

```
1. Driver performs pre-trip inspection:
   → INSERT tpt_daily_vehicle_inspection (all 15 checkpoints)
   → If all pass: inspection_status = Passed → trip may proceed
   → If any fail: inspection_status = Failed, any_issues_found = 1
2. On Failed inspection:
   → System auto-creates tpt_vehicle_service_request (vehicle_inspection_id FK)
   → UPDATE tpt_vehicle: availability_status = 0
3. Transport Manager reviews service request:
   → Approves: request_approval_status = Approved
   → On approval: system auto-creates tpt_vehicle_maintenance record
4. Maintenance record filled:
   → in_service_date recorded (vehicle at workshop)
5. Maintenance completed:
   → out_service_date, next_due_date recorded
   → UPDATE tpt_vehicle_maintenance: status = Approved
   → UPDATE tpt_vehicle: availability_status = 1
   → INSERT vnd_vendor_bill_due_for_payment (maintenance cost)
```

### WF-TPT-04: Driver Attendance (QR/Manual)

```
1. Driver arrives at depot:
   Option A — QR scan via registered AttendanceDevice:
   → INSERT or UPDATE tpt_driver_attendance (first_in_time, via_app = 1)
   → INSERT tpt_driver_attendance_log (scan_time, type = IN, scan_method, device_id)
   Option B — Manual entry by Transport Manager:
   → INSERT tpt_driver_attendance (first_in_time, via_app = 0)
2. Driver completes shift:
   → UPDATE tpt_driver_attendance (last_out_time)
   → total_work_minutes = TIMESTAMPDIFF(MINUTE, first_in_time, last_out_time)
   → attendance_status = derived from minutes vs shift rules
3. If driver absent:
   → Transport Manager marks Absent; system flags trip for reassignment
```

### WF-TPT-05: Student Allocation and Stop Change

```
1. Initial allocation:
   TransportAllocationService::allocate(studentSessionId, pickupRouteId, pickupStopId,
                                         dropRouteId, dropStopId, fare, effectiveFrom)
   → Check route capacity (vehicle capacity vs existing allocations)
   → Deactivate any existing active_status = 1 record for same student_session_id
   → INSERT tpt_student_route_allocation_jnt (active_status = 1)
2. Stop change request (parent/admin):
   → TransportAllocationService::requestStopChange(allocationId, newStopId, direction)
   → Creates pending change request record
3. Transport Manager approves stop change:
   → TransportAllocationService::approveStopChange(requestId)
   → Same flow as step 1 with new stop values and today as effective_from
```

---

## 10. Non-Functional Requirements

### NFR-TPT-01: PII Encryption (CRITICAL)

**Field:** `tpt_personnel.id_no`

This column stores government-issued ID numbers — including Aadhaar card numbers — in plaintext. Aadhaar storage is regulated under the Aadhaar (Targeted Delivery of Financial and Other Subsidies, Benefits and Services) Act, 2016 and UIDAI circular guidelines. Storage of Aadhaar numbers without encryption by entities not licensed as AUAs is unlawful. The DPDP Act 2023 further classifies such identifiers as sensitive personal data.

**Required fix:**
```php
// In DriverHelper model:
protected $casts = [
    'id_no'      => 'encrypted',   // AES-256 via Laravel's built-in encrypter
    'license_no' => 'encrypted',   // SEC-TPT-02 from gap analysis
    // ...
];
```

Key management: use `APP_KEY` in `.env` (Laravel's default). Implement key rotation procedure documented in ops runbook. The field must remain searchable for admin lookup — implement encrypted index or separate hashed lookup column (`id_no_hash` as SHA-256 of raw value for exact-match queries).

**Also encrypt:** `tpt_attendance_device.pg_fcm_token` should be stored encrypted (SEC-TPT-04 from gap analysis).

### NFR-TPT-02: Performance

| Requirement | Threshold |
|-------------|-----------|
| Trip list page load | < 2s for 1,000 trips |
| Student allocation import (Excel) | < 30s for 500 rows |
| Dashboard AJAX endpoint | < 1s |
| Boarding log QR scan response | < 500ms (device UX) |

**Missing indexes to add:**
- `tpt_trip`: index on `trip_date` (PERF-02)
- `tpt_student_boarding_log`: index on `(trip_date, student_id)` (PERF-03)
- `tpt_driver_attendance`: index on `attendance_date` (PERF-04)
- Verify spatial index queries use MySQL 8.x `ST_Contains`, `ST_Distance_Sphere` functions

**Caching:** Add Redis/array cache for frequently read reference data (vehicle list, route list, shift list) with 15-minute TTL.

**Tab controllers:** Refactor `TransportMasterController`, `StaffMgmtController`, `VehicleMgmtController`, `TripMgmtController`, `StudentRouteFeesController` to load tab content via AJAX instead of eagerly loading all sub-resource data in one request.

### NFR-TPT-03: GPS Data Privacy

When live GPS integration is implemented:
- Student location data (inferred from bus position near their stop) is PII under DPDP Act 2023.
- Retention policy: purge `tpt_gps_trip_log` records older than 90 days by default (configurable).
- Access control: parent may only query their own child's bus. No cross-student queries.
- No GPS data must cross tenant boundaries.

### NFR-TPT-04: Rate Limiting

- Live trip update endpoints (GPS data ingestion from hardware device) must have rate limiting (e.g., max 1 request per second per device) to prevent GPS device flooding.
- QR scan endpoints should rate-limit per device UUID to prevent brute-force or replay attacks.

### NFR-TPT-05: Audit Trail

All transport entity changes must be logged in `sys_activity_logs` (the platform-wide audit log). Priority entities: vehicle compliance changes, trip approval, student allocation changes, fee collection, maintenance approval.

### NFR-TPT-06: Multi-Tenancy Isolation

- `EnsureTenantHasModule` middleware must be added to the transport route group immediately (RT-01).
- No `tpt_*` query should ever reference data outside the current tenant's database context.

---

## 11. Dependencies

### 11.1 Internal Module Dependencies

| Dependency | Direction | Usage |
|------------|-----------|-------|
| `std_students` | Transport consumes | Student FK in allocation and boarding log |
| `std_student_sessions_jnt` | Transport consumes | Session FK in allocation, fee detail, notification log |
| `sys_users` | Transport consumes | `approved_by`, `inspected_by`, `raised_by`, `resolved_by` FKs |
| `sys_dropdown_table` | Transport consumes | Vehicle type, fuel type, ownership type, emission class, attendance status, OS type |
| `vnd_vendors` | Transport consumes | Vendor FK on vehicle for hired/contracted vehicles |
| `vnd_usage_logs` | Transport produces | Trip usage log on trip approval (conditional) |
| `vnd_vendor_bill_due_for_payment` | Transport produces | Maintenance cost billing on maintenance approval |
| `sys_media` | Transport consumes | Spatie MediaLibrary for vehicle and personnel documents |
| `sys_activity_logs` | Transport produces | Audit entries for all transport changes |
| Notification Module (NTF) | Transport produces | `tpt_notification_log` integration for parent alerts |
| Finance Module (FIN) | Parallel | Transport fee is standalone; ACC integration deferred |
| Accounting Module (ACC/FAC) | Transport will produce | Fee collection vouchers and maintenance expense vouchers (future) |
| School Setup (SCH) | Transport consumes | `sch_settings.trip_usage_needs_to_be_updated_into_vendor_usage_log` flag |

### 11.2 External Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| GPS Hardware API | Not implemented | Third-party GPS tracking platform (TrackoBit, GPSTrack, or similar) required for live tracking |
| Google Maps / Mapbox | Partial | Spatial data stored; map display in pickup point views |
| FCM (Firebase Cloud Messaging) | Not implemented | `pg_fcm_token` stored in device table; push notification integration pending |
| SMS Gateway | Not implemented | `sms_notification_status` field present in notification log |
| WhatsApp Business API | Not implemented | `whatsapp_notification_status` field present in notification log |

---

## 12. Test Scenarios

**Current test count: 0.** All test directories contain only `.gitkeep` files.

### 12.1 Critical Path Tests (P0 — Must implement)

| ID | Test | Type |
|----|------|------|
| TST-01 | `AttendanceDeviceController` returns 403 for unauthorized user with corrected Gate prefix | Feature |
| TST-02 | `AttendanceDeviceController.index` accessible for authorized user after Gate prefix fix | Feature |
| TST-03 | Vehicle with expired fitness certificate cannot be assigned to new trip | Feature |
| TST-04 | Student allocation blocked when vehicle is at 100% capacity | Feature |
| TST-05 | Trip status transitions: only Scheduled→InProgress→Completed→Approved allowed | Feature |
| TST-06 | Creating second active allocation for same student+session deactivates first | Feature |
| TST-07 | Failed vehicle inspection auto-creates service request | Feature |
| TST-08 | `EnsureTenantHasModule` middleware blocks transport access for unlicensed tenant | Feature |

### 12.2 Service Layer Tests (post service layer implementation)

| ID | Test | Type |
|----|------|------|
| TST-09 | `TransportVehicleService::checkComplianceExpiry()` returns correct expiry list | Unit |
| TST-10 | `TransportAllocationService::allocate()` enforces capacity and deactivates prior record | Unit |
| TST-11 | `TransportTripService::createFromScheduler()` validates vehicle availability | Unit |
| TST-12 | `TransportFeeService::calculateMonthlyFee()` applies fine correctly | Unit |
| TST-13 | `TransportAttendanceService::processBoardingScan()` rejects unallocated student | Unit |
| TST-14 | Driver `total_work_minutes` computed correctly from in/out times | Unit |
| TST-15 | Fuel log approval workflow: Pending → Approved by authorized role | Feature |
| TST-16 | Stop-change approval creates new allocation and deactivates old | Feature |

### 12.3 Security Tests

| ID | Test | Type |
|----|------|------|
| TST-17 | `tpt_personnel.id_no` stored as ciphertext in database after encryption cast | Unit |
| TST-18 | Decrypted `id_no` matches original value on model retrieval | Unit |
| TST-19 | Cross-tenant isolation: transport data from Tenant A not accessible in Tenant B context | Feature |
| TST-20 | QR scan endpoint rate-limited beyond N requests per device per minute | Feature |

---

## 13. Glossary

| Term | Definition |
|------|------------|
| Shift | An operational time window for transport (Morning, Afternoon, Evening). All routes, stops, and assignments belong to a shift. |
| Route | A defined bus path for a specific direction (Pickup or Drop) in a specific shift. |
| Pickup Point (Stop) | A physical bus stop with GPS coordinates where students board or alight. |
| Ordinal | The sequence number of a stop within a route (1 = first stop on the route). |
| Route Scheduler | A template record that defines which vehicle, driver, and route operate together on a specific date — used to generate daily trips. |
| Trip | A single execution of a route on a specific date. Has lifecycle status: Scheduled → In Progress → Completed → Approved. |
| Trip Stop Detail | A per-stop arrival/departure record within a trip, updated in real-time by the driver. |
| Personnel | A unified term for Drivers, Helpers, and Transport Managers in the `tpt_personnel` table. |
| Boarding Log | A record of a student's boarding or un-boarding event on a specific trip at a specific stop. |
| Student Route Allocation | The assignment of a student (per academic session) to specific pickup and drop routes and stops. |
| Fee Detail | A monthly transport fee record for a student session, including base amount, fine, and due date. |
| Fine Master | The rule table defining how transport fee fines are calculated (day range, type, rate). |
| Attendance Device | A registered QR scanner or RFID reader device used by drivers/helpers to scan students and record driver attendance. |
| vehicle_emission_class | Bharat Stage (BS) emission standard — the Indian equivalent of Euro emission standards. |
| PII | Personally Identifiable Information. Includes Aadhaar number, PAN, Passport, Voter ID, license number, address. |
| DPDP Act 2023 | Digital Personal Data Protection Act, 2023 — Indian data privacy legislation governing storage and processing of personal data. |
| AUA | Authentication User Agency — an entity licensed by UIDAI to authenticate using Aadhaar. Schools are generally not AUAs and must not store raw Aadhaar numbers. |
| EnsureTenantHasModule | Laravel middleware that checks whether the current tenant's subscription includes the requested module. |
| GPS Stub | GPS-related code that accepts the correct data structures but does not yet connect to a live hardware GPS API. |
| FCM Token | Firebase Cloud Messaging device token stored in `tpt_attendance_device.pg_fcm_token`, used for push notifications. |

---

## 14. Suggestions

### 14.1 Architecture Suggestions

**S-01 — Service Layer (Priority 1):**
Implement nine service classes before any further feature work. Minimum viable set:

| Service | Primary Responsibility |
|---------|------------------------|
| `TransportVehicleService` | Vehicle CRUD, document upload, compliance expiry checks, availability flag management |
| `TransportRouteService` | Route and stop management, capacity calculations, ordinal management |
| `TransportAllocationService` | Student allocation with uniqueness enforcement, stop-change workflow, capacity gate |
| `TransportTripService` | Trip creation from scheduler, status machine, stop detail recording, trip approval |
| `TransportAttendanceService` | Driver QR scan processing, boarding log creation, boarding scan validation |
| `TransportInspectionService` | Inspection checklist submission, auto-create service request on failure |
| `TransportFeeService` | Monthly fee generation, fine calculation, collection recording |
| `TransportGpsService` | GPS data ingestion, geofence alert generation (stub; ready for live wiring) |
| `TransportReportService` | Report query encapsulation, export helpers (CSV, PDF) |

**S-02 — Event-Driven Architecture:**
High-value events that should use Laravel Event+Listener pattern:
- `TripCompleted` → triggers vendor usage log write (listener checks `sch_settings` flag)
- `TripApproved` → same vendor usage log trigger (if approval is the trigger point)
- `InspectionFailed` → auto-creates service request
- `MaintenanceApproved` → creates vendor bill due record, restores vehicle availability
- `StudentBoarded` → fires parent notification
- `ComplianceExpiring` → dispatched by scheduled command, triggers notification

**S-03 — Background Jobs:**
Implement Queue-based Jobs for:
- `CheckComplianceExpiryJob` — daily, queries all active vehicles for near-expiry documents
- `CheckLicenseExpiryJob` — daily, queries all active drivers for near-expiry licenses
- `GenerateDailyTripsJob` — runs on configured time each morning, creates trips from schedulers for today
- `GenerateMonthlyTransportFeesJob` — runs on first of each month, generates `tpt_student_fee_detail` records for all active allocations

**S-04 — Controller Naming Standardization:**
Rename controllers for consistency:
- `NewTripController` → `TripCreateController` or merge into `TripController`
- `TptVehicleFuelController` → `VehicleFuelController` (drop module prefix on controller name)
- `TptDailyVehicleInspectionController` → `VehicleInspectionController`
- `TptVehicleMaintenanceController` → `VehicleMaintenanceController`
- `TptVehicleServiceRequestController` → `VehicleServiceRequestController`

**S-05 — Route Group Cleanup:**
- Separate transport routes into sub-files: `transport-master.php`, `transport-fee.php`, `transport-trip.php` for maintainability.
- Standardize all route prefixes to kebab-case (`driver-attendance`, not `driver_attendance`).

### 14.2 Security Suggestions

**S-06 — PII Encryption (Mandatory):**
Encrypt `tpt_personnel.id_no` and `tpt_personnel.license_no` using Laravel's `encrypted` cast. Add `id_no_hash` (SHA-256) for search. Document key rotation procedure.

**S-07 — FCM Token Encryption:**
Encrypt `tpt_attendance_device.pg_fcm_token` — FCM tokens can be used to impersonate a device for push notifications.

**S-08 — GPS Rate Limiting:**
Before any live GPS integration, implement rate limiting on GPS data submission endpoints (1 req/sec/device).

### 14.3 DDL Suggestions

**S-09 — Add Missing Standard Columns:**
The fee and fine tables (`tpt_fine_master`, `tpt_student_fee_detail`, `tpt_student_fine_detail`, `tpt_student_fee_collection`) are missing standard project columns: `updated_at`, `is_active`, `created_by`. These must be added via migration.

**S-10 — Status Columns to FK:**
Convert `tpt_trip.status`, `tpt_student_fee_detail.status`, `tpt_student_fee_collection.status`, and `tpt_student_fee_collection.payment_mode` from VARCHAR to INT UNSIGNED FK to `sys_dropdown_table`. This enables dropdown-driven status values and consistent reporting.

**S-11 — Add Missing DDL Tables:**
Add DDL definitions for: `tpt_live_trip`, `tpt_gps_trip_log`, `tpt_gps_alerts`, `tpt_student_event_log`. Currently models exist without tables — any migration relying on these models will fail.

**S-12 — Add Indexes:**
```sql
ALTER TABLE tpt_trip ADD INDEX idx_trip_date (trip_date);
ALTER TABLE tpt_student_boarding_log ADD INDEX idx_sbl_date_student (trip_date, student_id);
ALTER TABLE tpt_driver_attendance ADD INDEX idx_da_date (attendance_date);
```

---

## 15. Appendices

### Appendix A: AttendanceDeviceController Gate Typo — Exact Fix

**File:** `Modules/Transport/app/Http/Controllers/AttendanceDeviceController.php`

**Problem:** All `Gate::authorize()` calls use the prefix `tested.` instead of `tenant.`.

```php
// WRONG (current code — lines 20, 50, 62, etc.):
Gate::authorize('tested.attendance-device.viewAny');
Gate::authorize('tested.attendance-device.create');
Gate::authorize('tested.attendance-device.update');
Gate::authorize('tested.attendance-device.delete');
Gate::authorize('tested.attendance-device.restore');
Gate::authorize('tested.attendance-device.forceDelete');

// CORRECT (after fix):
Gate::authorize('tenant.attendance-device.viewAny');
Gate::authorize('tenant.attendance-device.create');
Gate::authorize('tenant.attendance-device.update');
Gate::authorize('tenant.attendance-device.delete');
Gate::authorize('tenant.attendance-device.restore');
Gate::authorize('tenant.attendance-device.forceDelete');
```

**Impact if not fixed:** The `Gate::authorize()` call will throw `Illuminate\Auth\Access\AuthorizationException` for every request because no Gate named `tested.attendance-device.*` is registered anywhere. This results in HTTP 403 responses for all users on every AttendanceDevice endpoint, completely blocking device management functionality.

**Fix method:** Global find-and-replace `tested.attendance-device` → `tenant.attendance-device` within `AttendanceDeviceController.php`. Regression test: TST-01 and TST-02 in Section 12.

### Appendix B: VehicleController Wrong Gate on create()

**File:** `Modules/Transport/app/Http/Controllers/VehicleController.php` line ~61

```php
// WRONG:
Gate::authorize('tenant.vehicle.view');   // should be .create, not .view

// CORRECT:
Gate::authorize('tenant.vehicle.create');
```

This allows users with only `view` permission to access the create form, bypassing the intended create permission gate. Fix in same sprint as Appendix A.

### Appendix C: EnsureTenantHasModule Middleware Addition

**File:** `routes/tenant.php` (approximately line 2214)

```php
// CURRENT (missing middleware):
Route::prefix('transport')->name('transport.')->middleware([
    'auth', 'verified', 'tenancy.enforce'
])->group(function () { ... });

// REQUIRED:
Route::prefix('transport')->name('transport.')->middleware([
    'auth', 'verified', 'tenancy.enforce',
    'module:TPT'   // or the project-standard syntax for EnsureTenantHasModule
])->group(function () { ... });
```

### Appendix D: Missing FormRequests to Create

| FormRequest to Create | Used By | Key Validation |
|-----------------------|---------|----------------|
| `RouteSchedulerRequest` | `RouteSchedulerController` | scheduled_date required; shift/route/vehicle/driver FK exists; no duplicate per date+shift+route+direction |
| `StudentBoardingRequest` | `StudentBoardingController` | student_id, trip_id, stop_id, boarding_time required; stop allocated to student's route |
| `TripIncidentRequest` | `TripMgmtController::resolveIncident` | incident_type FK, severity enum, description required; trip must be In Progress |

### Appendix E: Proposed Service Layer Method Signatures

```php
// TransportAllocationService
public function allocate(int $studentSessionId, array $allocationData): TptStudentAllocationJnt;
public function checkCapacity(int $routeId, int $sessionId): array; // returns ['count', 'capacity', 'percentage']
public function requestStopChange(int $allocationId, string $direction, int $newStopId): void;
public function approveStopChange(int $requestId): TptStudentAllocationJnt;

// TransportTripService
public function createFromScheduler(int $schedulerId, string $date): TptTrip;
public function updateStatus(TptTrip $trip, string $newStatus, ?int $approvedBy = null): TptTrip;
public function generateTripsFromScheduler(string $date): Collection;

// TransportAttendanceService
public function processBoardingScan(string $deviceUuid, string $qrCode, int $tripId, int $stopId): StudentBoardingLog;
public function markDriverAttendance(int $personnelId, string $type, string $method, ?int $deviceId): TptDriverAttendanceLog;

// TransportInspectionService
public function submitInspection(array $checkpoints, int $vehicleId, ?int $driverId): TptDailyVehicleInspection;
public function createServiceRequestFromInspection(TptDailyVehicleInspection $inspection): TptVehicleServiceRequest;

// TransportFeeService
public function generateMonthlyFees(int $academicSessionId, string $month): Collection;
public function applyFine(int $feeDetailId, int $overdueDays): TptStudentFineDetail;
public function recordPayment(int $feeDetailId, array $paymentData): TptStudentFeeCollection;
```

---

## 16. V1 to V2 Delta

### New Sections in V2

| Section | Content Added |
|---------|---------------|
| Sec 1 (Executive Summary) | Quantified module readiness (5.5/10); identified 4 production-blocking issues |
| Sec 5.2 | Explicit table of 9 models without DDL tables |
| Sec 5.3 | Full DDL column gap table (DB-01 through DB-17) from gap analysis |
| Sec 5.4 | Trigger documentation (`trg_driver_route_vehicle_unique_assignment`) |
| Sec 6.1 | Route group configuration with middleware gap explicitly documented |
| Sec 6.3 | Standard route pattern examples |
| Sec 7.1 | Complete view inventory with status per area |
| Sec 10 | NFRs expanded: PII encryption with exact code fix, performance targets, GPS privacy, rate limiting, audit trail, multi-tenancy |
| Sec 12 | 20 test scenarios across critical path, service layer, and security |
| Sec 15 Appendix A | Exact Gate typo text — before and after code showing all 6 wrong calls |
| Sec 15 Appendix B | VehicleController wrong Gate on create() |
| Sec 15 Appendix C | EnsureTenantHasModule middleware addition template |
| Sec 15 Appendix D | Missing FormRequest table with validation requirements |
| Sec 15 Appendix E | Proposed service layer method signatures |

### V1 Errors Corrected in V2

| V1 Statement | V2 Correction |
|--------------|---------------|
| V1 stated DDL has 23 tables | V2 confirms 25 DDL tables (gap analysis found `tpt_student_boarding_log` and `tpt_notification_log` as additional new tables added Dec 2025) |
| V1 said "5 controllers with zero Gate checks" without specifics | V2 from gap analysis: only `AttendanceDeviceController` confirmed with Gate prefix bug; full audit of remaining 30 controllers still required |
| V1 Section 5 table named model as `TptStudentAllocationJnt` | DDL table is `tpt_student_route_allocation_jnt`; V2 uses DDL canonical name throughout |
| V1 said `tpt_student_route_allocation_jnt` had only `student_session_id` FK (DB-14) | V2 DDL reading at line 1474 confirms `student_id` column IS present — DB-14 from gap analysis was incorrect for the V2 DDL |
| V1 stated `VendorRequest.php` is misplaced | Retained in V2 as a note — may be transport-specific vendor validation, not a duplicate |

### Status Changes from V1 to V2

| Item | V1 Status | V2 Status | Reason |
|------|-----------|-----------|--------|
| `tpt_student_route_allocation_jnt.student_id` | Listed as missing (DB-14) | Present in DDL | DDL line 1474 shows `student_id` column |
| Route group middleware gap | Mentioned as note | Elevated to P0 critical | Gap analysis classifies as RT-01 P0 |
| Total controller count | 31 stated | 31 confirmed (+ 1 archived) | Gap analysis confirms 31 active |
| Total DDL table count | 23 stated | 25 confirmed | Two Dec 2025 additions found in DDL |

---

*Document generated: 2026-03-26 | Sources: V1 TPT_Transport_Requirement.md (2026-03-25), Transport_Deep_Gap_Analysis.md (2026-03-22), tenant_db_v2.sql (lines 1131–1795), Module code at `/Modules/Transport/`*
