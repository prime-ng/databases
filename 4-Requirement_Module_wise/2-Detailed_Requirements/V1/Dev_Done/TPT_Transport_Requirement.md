# TPT — Transport Management Module
## Requirement Document v1.0

**Module Code:** TPT
**Module Name:** Transport Management
**DB Prefix:** `tpt_`
**Layer:** Tenant Module (per-school database)
**RBS Reference:** Module N — Transport Management (lines 3238–3333)
**Document Date:** 2026-03-25
**Status:** Development ~55% complete

---

## Section 1 — Module Overview

The Transport module manages end-to-end school transport operations for Indian K-12 schools. It covers the full lifecycle from vehicle registration through daily trip execution: vehicle and route master data, driver/helper profile management, student route allocation, daily vehicle inspections, trip management with live tracking, driver attendance via QR/device, GPS monitoring (stub), transport fee integration, and analytics/reporting.

The module is a Tenant-layer module, running inside each school's isolated `tenant_{uuid}` database, with the `tpt_` prefix for all its tables.

---

## Section 2 — Scope

### In Scope
- Vehicle master: registration, compliance documents, maintenance lifecycle (inspection → service request → maintenance)
- Route management: route setup, pickup points with GPS coordinates, stop sequencing, shift-based routes
- Driver/helper personnel management: profiles, license tracking, document uploads, police verification
- Driver-route-vehicle assignment (junction)
- Student route allocation: assign pickup and drop routes/stops per academic session
- Trip scheduling and execution: route schedulers, daily trips, stop-by-stop tracking
- Student boarding/un-boarding logs: QR scan or manual, per-trip per-stop
- Driver attendance: daily check-in/out with QR/app support
- Vehicle inspection: daily pre-trip checklist (15+ checkpoints), service requests, maintenance records
- Fuel log management: per-vehicle fuel entries with approval workflow
- Transport fee management: route-wise fee master, monthly fee schedules, fee collection, fines
- GPS tracking: data structures and alert models defined; live integration is a stub (planned)
- ML/AI route optimization models: data structures present; inference is a stub (planned)
- Reporting: route efficiency, vehicle usage, attendance, fee collection

### Out of Scope
- HR payroll processing for drivers/helpers (handled by HR & Payroll module when built)
- Student academic attendance (handled by the Attendance module)
- Parent-facing mobile app (Student/Parent Portal module)
- Accounting voucher generation from transport fee (Accounting module integration — future)

---

## Section 3 — User Roles and Permissions

| Role | Access Level |
|---|---|
| Super Admin | Full access all transport functions |
| School Admin | Full access all transport functions |
| Transport Manager | Full CRUD on all transport sub-modules |
| Driver | Read own trip, mark own attendance |
| Accountant | Transport fee collection, fee reports |
| Class Teacher / Coordinator | View student allocation |
| Parent | View own child bus location (future — Parent Portal) |

Permission gates follow `tenant.{resource}.{action}` pattern (e.g., `tenant.vehicle.viewAny`, `tenant.vehicle.create`, `tenant.vehicle.update`, `tenant.vehicle.delete`, `tenant.vehicle.restore`, `tenant.vehicle.forceDelete`).

**Critical Bug — AttendanceDevice Gate prefix:** All AttendanceDeviceController Gate calls use `tested.attendance-device.*` instead of `tenant.attendance-device.*`. This breaks all permission checks for the attendance device sub-module. Must be fixed before production.

---

## Section 4 — Functional Requirements

### FR-N1: Vehicle Management

**FR-N1.1 — Vehicle Registration**
- Capture vehicle number, registration number, model, manufacturer, vehicle type (dropdown), fuel type (dropdown), seating capacity, maximum capacity.
- Record ownership type (school-owned, hired, contracted) with vendor linkage for hired/contracted vehicles.
- Upload and store compliance documents as Spatie Media Library collections: registration certificate (`registration_img`), pollution certificate (`pollution_img`), fitness certificate (`fitness_img`), insurance certificate (`insurance_img`), vehicle photo (`vehicle_photo`), vehicle emission certificate (`vehicle_emission_cert_img`), fire extinguisher certificate (`fire_extinguisher_cert_img`), GPS device certificate (`gps_device_cert_img`).
- Record compliance expiry dates: `fitness_valid_upto`, `insurance_valid_upto`, `pollution_valid_upto`, `fire_extinguisher_valid_upto`.
- Track availability status (boolean: available/not available).
- Soft delete with restore and force-delete capabilities.

**FR-N1.2 — Compliance Expiry Alerts**
- System must flag vehicles with documents expiring within 30 days.
- Dashboard must display count of vehicles with expired or near-expiry documents.
- Alert categories: fitness certificate, insurance, pollution certificate, fire extinguisher certificate.

**FR-N1.3 — Vehicle Fuel Logs**
- Record fuel entries per vehicle: date, quantity (litres), cost, fuel type, odometer reading, driver, remarks.
- Fuel log status workflow: Pending → Approved/Rejected.
- Support fuel efficiency calculation (km per litre) from odometer and fuel records.

**FR-N1.4 — Vehicle Maintenance Lifecycle**
- Three-stage maintenance pipeline:
  1. Daily inspection (`tpt_daily_vehicle_inspection`) — pre-trip checklist with 15 checkpoints.
  2. Service request (`tpt_vehicle_service_requests`) — raised when inspection fails or issue found.
  3. Maintenance record (`tpt_vehicle_maintenance`) — actual repair/service with cost, workshop, in/out service dates, next due date.
- Maintenance status: Pending → Approved.
- Maintenance approval tracked with `approved_by` (user FK) and `approved_at`.

### FR-N2: Route Management

**FR-N2.1 — Route Setup**
- Define routes with code, name, description, pickup/drop direction flag, shift assignment, route geometry (GeoJSON for map display).
- Each route belongs to one shift (morning/afternoon/evening).
- Support both pickup-only and drop-only routes as separate entities.

**FR-N2.2 — Pickup Point (Stop) Management**
- Define pickup points (stops) with name, geo-coordinates (latitude/longitude), landmark description.
- Assign pickup points to routes with ordinal sequence via `tpt_pickup_point_route` junction.
- Define scheduled arrival time per stop-route combination.
- Support change-of-stop workflow: request → approve/reject.

**FR-N2.3 — Driver-Route-Vehicle Assignment**
- Assign a driver, vehicle, and helper to a specific route for a date range.
- Manage via `tpt_driver_route_vehicle_jnt` junction table.
- Historical assignment records must be preserved (no hard overwrites).

**FR-N2.4 — Route Scheduler**
- `tpt_route_scheduler_jnt` acts as a template: a predefined combination of route, vehicle, driver, and helper for a recurring schedule.
- Route schedulers feed into daily trip generation.

### FR-N3: Driver and Helper Management (Personnel)

**FR-N3.1 — Personnel Profile**
- Unified `tpt_personnel` table manages both Drivers and Helpers (role field: Driver / Helper / Both).
- Capture: name, phone, ID type (Aadhaar / Licence / PAN / Voter ID / Passport), ID number, role, license number, license expiry date, driving experience (months), assigned vehicle, police verification status.
- Upload documents via Spatie Media: photo, ID card, driving license, police verification certificate, address proof.
- Upload status tracked with boolean flags per document type.
- System user linkage via `user_id` (optional, for app-based attendance).

**FR-N3.2 — License Expiry Monitoring**
- Alert transport manager when any driver's license is expiring within 30 days.

**FR-N3.3 — Police Verification Tracking**
- `police_verification_done` boolean flag on personnel record.
- Dashboard widget showing count of personnel with incomplete police verification.

**FR-N3.4 — Driver Attendance**
- `tpt_driver_attendance` records daily attendance: date, first-in time, last-out time, total work minutes, status (Present/Absent/Half-Day/Late).
- `via_app` flag distinguishes QR/device-based attendance from manual entry.
- Attendance log history stored in `tpt_driver_attendance_log`.
- Attendance device management (`tpt_attendance_devices`): register QR scanner or RFID reader device linked to a driver/helper user.

### FR-N4: Student Route Allocation

**FR-N4.1 — Student Transport Enrollment**
- Allocate student to a pickup route + pickup stop and a drop route + drop stop for an academic session.
- Record fare amount and effective-from date.
- One student per academic session has one active allocation record.
- Bulk import via Excel (`StudentAllocationImport`).
- Export to Excel (`StudentAllocationExport`).

**FR-N4.2 — Stop Change Workflow**
- Parent or admin can request a stop change.
- Transport manager approves or rejects.
- Approved changes create a new allocation record with updated effective-from date; old record is preserved in history.

**FR-N4.3 — Route Capacity Enforcement**
- System enforces that student allocations per route do not exceed the vehicle's `capacity` for the assigned vehicle.
- Warning alert when allocations approach 90% of capacity.

### FR-N5: Trip Management

**FR-N5.1 — Trip Scheduling**
- Daily trips are created from route schedulers or manually.
- Trip fields: trip date, route, vehicle, driver, helper, trip type (shift), planned start/end time, odometer start/end, fuel start/end.
- Trip status lifecycle: Scheduled → In Progress → Completed → Approved.
- Trip approval by authorized user with `approved_by` and `approved_at`.

**FR-N5.2 — Trip Stop Details**
- `tpt_trip_stop_detail` records when the vehicle reaches each stop (`reached_flag`, actual time).
- Parents receive push notification when bus reaches a configurable number of stops before their child's stop (GPS notification — future).

**FR-N5.3 — Trip Incidents**
- `tpt_trip_incidents` records any incidents during a trip (accident, breakdown, delay).
- Incident resolution tracked with resolve workflow (`resolveIncident` controller method present).

**FR-N5.4 — Live Trip**
- `tpt_live_trip` and `tpt_gps_trip_log` models stub GPS real-time tracking.
- `tpt_gps_alerts` stores triggered geofence and deviation alerts.
- Actual live GPS integration requires a third-party GPS API (future implementation).

### FR-N6: Student Boarding Attendance

**FR-N6.1 — Boarding Log**
- `tpt_student_boarding_log` records each student's boarding event per trip date.
- Fields: student, student session, boarding route, trip, stop, boarding time; separate un-boarding fields for return trip.
- Device ID links to attendance device record (QR scanner / RFID reader).

**FR-N6.2 — Parent Notifications**
- `tpt_notification_log` records notifications sent to parents (boarding confirmation, bus location alerts).
- Notification channel: push notification (future), SMS (future).

**FR-N6.3 — Student Event Log**
- `tpt_student_event_log` captures all student transport events for audit (boarding, un-boarding, absent, stop change).

### FR-N7: Transport Fee Management

**FR-N7.1 — Fee Master**
- `tpt_student_fee_detail` defines monthly fee records per student academic session: month, base amount, due date, fine amount, status.
- Fee master can be imported via Excel (`FeeMasterImport`).

**FR-N7.2 — Fee Collection**
- `tpt_student_fee_collection` (and `tpt_student_pay_log`) records actual payments.
- Fee collection export via `FeeCollectionExport`.

**FR-N7.3 — Fine Management**
- `tpt_fine_master` defines fine rules.
- `tpt_student_fine_detail` records fine instances applied to students.

**FR-N7.4 — Route-Wise Fee Configuration**
- `tpt_route_fee_master` (referenced by `StudentRouteFeesController`) links routes to fee amounts for auto-assignment during student allocation.
- Auto-calculate monthly charges based on route-fare assignment.

**FR-N7.5 — Finance Integration (Future)**
- Transport fee collection must eventually post to the Accounting module as receipts.
- When the Accounting (ACC) module is built, `tpt_student_fee_collection` records should trigger voucher entries in `acc_vouchers`.
- For now, transport fee is standalone within the Transport module.

### FR-N8: Reports and Analytics

- Route efficiency report: stops coverage, on-time performance, average delay.
- Vehicle usage report: trips per vehicle, km covered, fuel consumed, cost per km.
- Driver attendance report: monthly attendance summary per driver.
- Student boarding attendance: per-route or per-student daily boarding records.
- Maintenance cost report: per vehicle, per period.
- Transport fee outstanding report: pending fee, collected fee, overdue fee.
- AI route optimization (stub): `MlModels` and `MlModelFeatures` tables exist for future ML-based route suggestions.

---

## Section 5 — Data Model

### Core Tables

| Table | Model Class | Description |
|---|---|---|
| `tpt_vehicle` | `Vehicle` | Vehicle master: compliance docs, expiry dates, vendor link |
| `tpt_personnel` | `DriverHelper` | Drivers and helpers: license, documents, police verification |
| `tpt_route` | `Route` | Route master: code, name, direction, shift, geometry |
| `tpt_pickup_point` | `PickupPoint` | Bus stop master: name, GPS coordinates |
| `tpt_pickup_point_route` | `PickupPointRoute` | Route-stop junction: ordinal sequence, scheduled time |
| `tpt_shift` | `Shift` | Shift master: name, start time, end time (Morning/Afternoon/Evening) |
| `tpt_driver_route_vehicle_jnt` | `DriverRouteVehicleJnt` | Driver+Vehicle+Route assignment |
| `tpt_route_scheduler_jnt` | `TptRouteSchedulerJnt` | Recurring schedule template |
| `tpt_student_route_allocation_jnt` | `TptStudentAllocationJnt` | Student pickup/drop allocation per session |

### Operational Tables

| Table | Model Class | Description |
|---|---|---|
| `tpt_trip` | `TptTrip` | Daily trip records: vehicle, driver, odometer, fuel, status |
| `tpt_trip_stop_detail` | `TptTripStopDetail` | Per-stop arrival records within a trip |
| `tpt_trip_incidents` | `TptTripIncidents` | Incident records per trip |
| `tpt_live_trip` | `TptLiveTrip` | Real-time trip state (GPS stub) |
| `tpt_student_boarding_log` | `StudentBoardingLog` | Student boarding/un-boarding per trip |
| `tpt_student_event_log` | `TptStudentEventLog` | Audit trail of student transport events |
| `tpt_driver_attendance` | `TptDriverAttendance` | Daily driver/helper attendance |
| `tpt_driver_attendance_log` | `TptDriverAttendanceLog` | Punch-level attendance logs |
| `tpt_attendance_devices` | `AttendanceDevice` | QR/RFID reader device registry |

### Compliance and Maintenance Tables

| Table | Model Class | Description |
|---|---|---|
| `tpt_daily_vehicle_inspection` | `TptDailyVehicleInspection` | Pre-trip inspection checklist (15 checkpoints) |
| `tpt_vehicle_service_requests` | `TptVehicleServiceRequest` | Service request raised from inspection |
| `tpt_vehicle_maintenance` | `TptVehicleMaintenance` | Actual maintenance record with cost |
| `tpt_vehicle_fuel` | `TptVehicleFuel` | Fuel log per vehicle per day |

### Fee Tables

| Table | Model Class | Description |
|---|---|---|
| `tpt_student_fee_detail` | `TptFeeMaster` | Monthly fee record per student-session |
| `tpt_student_fee_collection` | `TptStudentFeeCollection` | Payment collection records |
| `tpt_student_pay_log` | `StudentPayLog` | Payment event log |
| `tpt_fine_master` | `TptFineMaster` | Fine rule definitions |
| `tpt_student_fine_detail` | `TptStudentFineDetail` | Fine instances per student |

### GPS and AI Tables (Stubs)

| Table | Model Class | Description |
|---|---|---|
| `tpt_gps_trip_log` | `TptGpsTripLog` | GPS coordinate log per trip (stub — fillable empty) |
| `tpt_gps_alerts` | `TptGpsAlerts` | Geofence / deviation alerts |
| `tpt_notification_log` | `TptNotificationLog` | Parent notification records |
| `tpt_ml_models` | `MlModels` | ML model registry for route optimization |
| `tpt_ml_model_features` | `MlModelFeatures` | Feature store for ML models |
| `tpt_feature_store` | `TptFeatureStore` | Feature data for ML inference |
| `tpt_model_recommendations` | `TptModelRecommendations` | AI route optimization recommendations |
| `tpt_recommendation_history` | `TptRecommendationHistory` | History of applied recommendations |

### Key Relationships

```
tpt_vehicle 1—N tpt_daily_vehicle_inspection
tpt_daily_vehicle_inspection 1—N tpt_vehicle_service_requests
tpt_vehicle_service_requests 1—N tpt_vehicle_maintenance
tpt_vehicle 1—N tpt_vehicle_fuel

tpt_personnel (driver) 1—N tpt_driver_attendance
tpt_personnel (driver) 1—N tpt_driver_attendance_log

tpt_route 1—N tpt_pickup_point_route N—1 tpt_pickup_point
tpt_route N—N tpt_personnel N—N tpt_vehicle (via tpt_driver_route_vehicle_jnt)
tpt_route_scheduler_jnt 1—N tpt_trip

tpt_trip 1—N tpt_trip_stop_detail
tpt_trip 1—N tpt_trip_incidents
tpt_trip 1—N tpt_student_boarding_log

std_students N—N tpt_route (via tpt_student_route_allocation_jnt)
tpt_student_route_allocation_jnt 1—N tpt_student_fee_detail
```

---

## Section 6 — Controllers Inventory

### Registered in Tenant Routes

| Controller | Route Prefix | Auth | Notes |
|---|---|---|---|
| `TransportMasterController` | `transport-master` | Yes | Hub controller — tabbed view |
| `TransportDashboardController` | `dashboard/data` | Yes | Dashboard data endpoint |
| `VehicleController` | via master | Yes | Vehicle CRUD |
| `VehicleMgmtController` | via master | Partial | Vehicle management sub-actions |
| `RouteController` | via master | Yes | Route CRUD |
| `PickupPointController` | via master | Yes | Pickup point CRUD |
| `PickupPointRouteController` | via master | Yes | Route-stop assignment |
| `DriverHelperController` | via master | Yes | Personnel CRUD |
| `DriverRouteVehicleController` | via master | Yes | Assignment junction |
| `TripController` | via master | Yes | Trip CRUD |
| `TripMgmtController` | `trip-management` | Yes | Trip management + incident resolve |
| `DriverAttendanceController` | via master | Yes | Driver attendance |
| `StudentAllocationController` | via master | Yes | Student allocation CRUD |
| `StudentAttendanceController` | via master | Yes | Student boarding attendance |
| `StudentBoardingController` | via master | Yes | Boarding log |
| `TptDailyVehicleInspectionController` | via master | Yes | Inspection CRUD |
| `TptVehicleMaintenanceController` | via master | Yes | Maintenance records |
| `TptVehicleServiceRequestController` | via master | Yes | Service requests |
| `TptVehicleFuelController` | via master | Yes | Fuel log |
| `FeeMasterController` | via master | Yes | Fee master |
| `FeeCollectionController` | via master | Yes | Fee collection |
| `StudentRouteFeesController` | `std-route-Fees-mgmt` | Yes | Route-fee mapping |
| `FineMasterController` | via master | Yes | Fine rules |
| `TptStudentFineDetailController` | via master | Yes | Student fines |
| `ShiftController` | via master | Yes | Shift master |
| `RouteSchedulerController` | via master | Yes | Route schedulers |
| `NewTripController` | via master | Yes | New trip creation |
| `LiveTripController` | via master | Yes | Live trip (GPS stub) |
| `TransportReportController` | `transport-report` | Yes | Reports |
| `StaffMgmtController` | via master | Yes | Staff management view |

### Controllers with Zero Auth (Critical Bug)

| Controller | Issue |
|---|---|
| `AttendanceDeviceController` | Gate prefix is `tested.*` instead of `tenant.*` — all Gates fail |

**Note:** Five additional controllers have been identified in module code review that use no Gate checks at all. The development team must audit all 31 controllers to confirm Gate coverage.

---

## Section 7 — Services Gap

**Critical Gap: 0 service classes exist for 31 controllers.**

All business logic is currently embedded directly in controllers. This violates separation of concerns and makes unit testing impossible. The following service classes must be created:

| Service Class | Responsibility |
|---|---|
| `TransportVehicleService` | Vehicle CRUD, document upload, compliance expiry checks |
| `TransportRouteService` | Route/stop management, capacity calculations |
| `TransportAllocationService` | Student allocation, stop-change workflow, capacity enforcement |
| `TransportTripService` | Trip creation, status transitions, stop-detail recording |
| `TransportAttendanceService` | Driver attendance, QR/device processing, boarding logs |
| `TransportInspectionService` | Inspection workflow, service request creation |
| `TransportFeeService` | Fee master, collection, fine calculation |
| `TransportGpsService` | GPS data ingestion, alert generation (stub until live GPS) |
| `TransportReportService` | Report queries, export helpers |

---

## Section 8 — Business Rules

### BR-TPT-01: Vehicle Capacity
- A route's active student allocations must not exceed the assigned vehicle's `capacity`.
- System must prevent allocation if vehicle is at 100% capacity.
- Warning at 90% capacity.

### BR-TPT-02: Compliance Enforcement
- A vehicle with an expired fitness certificate, insurance, or pollution certificate must not be assignable to active trips.
- Vehicle `availability_status` should auto-set to `false` when any compliance document expires.
- Expiry alert: 30 days advance notice to Transport Manager.

### BR-TPT-03: Driver License Validation
- A driver with an expired `license_valid_upto` must not be assignable as the primary driver for a new trip.
- License expiry alert: 30 days advance notice.

### BR-TPT-04: Police Verification
- A driver/helper without `police_verification_done = true` must be flagged on the dashboard.
- System should prevent trip assignment (configurable: alert-only vs hard block, school policy).

### BR-TPT-05: Trip Lifecycle
- Trip status transitions are one-directional: Scheduled → In Progress → Completed → Approved.
- Only a user with trip-approval permission can set status to Approved.
- A Completed trip cannot revert to In Progress.

### BR-TPT-06: Inspection-to-Maintenance Pipeline
- When an inspection records `any_issues_found = true`, the system must create a service request automatically (or prompt the inspector to raise one before saving).
- A vehicle with a Pending or open service request should be flagged as unavailable until the maintenance record is closed.

### BR-TPT-07: Student Allocation Uniqueness
- A student can have only one active allocation per academic session.
- Creating a new allocation must deactivate the prior one and record the effective-from date for audit.

### BR-TPT-08: Fuel Log Approval
- Fuel entries default to `status = Pending`.
- Only an authorized user (Transport Manager or Admin) can approve fuel entries.
- Rejected entries remain in history with rejection reason.

### BR-TPT-09: Transport Fee Monthly Schedule
- Transport fee is charged per calendar month.
- If a student changes routes mid-month, proration rules apply (configurable: full month charged, or prorated from effective date).

---

## Section 9 — Workflows

### WF-TPT-01: Student Boarding Flow (QR Scan)

```
1. Bus departs stop (driver/helper scans student QR)
   → AttendanceDevice receives QR data
   → System looks up student by QR code
   → Validates: student is allocated to this route/stop
   → Creates tpt_student_boarding_log record
   → Sets boarding_route_id, boarding_trip_id, boarding_stop_id, boarding_time
2. Bus arrives school
   → (End of morning trip — no un-boarding required)
3. Afternoon return trip
   → Un-boarding recorded: unboarding_route_id, unboarding_trip_id, unboarding_stop_id, unboarding_time
4. tpt_notification_log entry created → Parent notified
5. tpt_student_event_log entry created → Audit trail
```

### WF-TPT-02: Trip Lifecycle

```
1. Route Scheduler template defines recurring trip (route + vehicle + driver + helper)
2. Transport Manager creates daily trip from scheduler (or manually)
   → tpt_trip record created, status = Scheduled
3. Driver departs
   → Status = In Progress
   → start_time, start_odometer_reading, start_fuel_reading recorded
4. At each stop
   → tpt_trip_stop_detail record created with reached_flag = true and actual_time
   → Student boarding logs created
5. Trip ends
   → end_time, end_odometer_reading, end_fuel_reading recorded
   → Status = Completed
6. Transport Manager reviews and approves
   → approved_by, approved_at set; status = Approved
```

### WF-TPT-03: Vehicle Inspection → Maintenance

```
1. Driver performs pre-trip inspection
   → tpt_daily_vehicle_inspection record created (15 checkpoints)
   → If all pass: inspection_status = Passed → Trip proceeds
   → If any fail: inspection_status = Failed → any_issues_found = true
2. Service request raised
   → tpt_vehicle_service_requests record created
   → Vehicle availability_status set to false
3. Transport Manager approves service request
4. Vehicle sent to workshop
   → tpt_vehicle_maintenance record created
   → in_service_date recorded; workshop_details captured
5. Vehicle returns from workshop
   → out_service_date, next_due_date recorded
   → Maintenance status = Approved
   → Vehicle availability_status restored to true
```

### WF-TPT-04: Driver Attendance

```
1. Driver arrives at depot
   → QR scan via AttendanceDevice OR manual mark by Transport Manager
   → tpt_driver_attendance: first_in_time recorded, via_app = true if device
2. Driver completes shift
   → last_out_time recorded
   → total_work_minutes = (last_out - first_in) in minutes
   → attendance_status = Present / Late / Half-Day based on rules
3. If driver absent: Transport Manager marks Absent; trip may need reassignment
4. tpt_driver_attendance_log records all punch events
```

---

## Section 10 — Integration Points

### INT-TPT-01: Student Profile Module
- `tpt_student_route_allocation_jnt.student_id` → `std_students.id`
- `tpt_student_route_allocation_jnt.student_session_id` → `std_student_academic_sessions.id`
- Student fee records reference `std_student_academic_sessions.id`

### INT-TPT-02: Vendor Module
- `tpt_vehicle.vendor_id` → `vnd_vendors.id`
- Vehicles with `ownership_type = Hired/Contracted` are linked to vendors.
- VehicleController queries Vendor model using dropdown key `vnd_vendors.vendor_type_id.vendor_type_id`.

### INT-TPT-03: School Setup Module
- Shift configuration may reference school-level academic terms.
- Student allocations reference `sch_organization_academic_sessions`.

### INT-TPT-04: Accounting Module (Future)
- Transport fee collections (`tpt_student_fee_collection`) should post payment vouchers to `acc_vouchers` when the Accounting module is implemented.
- Transport maintenance costs should post expense vouchers to the Accounting module.

### INT-TPT-05: Notification Module
- `tpt_notification_log` integrates with the system notification engine for parent alerts.
- Boarding confirmation, bus delay, and route deviation alerts.

### INT-TPT-06: GPS API (Planned)
- `tpt_gps_trip_log` and `tpt_live_trip` await integration with a hardware GPS device API or a third-party GPS tracking platform (e.g., Google Maps Fleet, Verizon Connect, or Indian providers such as TrackoBit).
- Geofence alerts stored in `tpt_gps_alerts`.

---

## Section 11 — Security Issues (Critical)

### SEC-TPT-01: PII Stored Unencrypted — CRITICAL
**Severity: Critical**

The `tpt_personnel` table stores personally identifiable information in plaintext:
- `id_no` — stores Aadhaar number, PAN, Voter ID, or Passport number depending on `id_type`.
- This is a direct violation of the Information Technology Act 2000 (IT Act) and DPDP Act 2023 for Indian data subjects.
- Aadhaar storage is specifically regulated under the Aadhaar (Targeted Delivery) Act and UIDAI guidelines.

**Required Fix:** Encrypt `id_no` using AES-256 encryption at the Laravel model level (`$casts` with `encrypted`) or at the MySQL level (application-level encryption before insert). Implement a key rotation strategy. The field must be decryptable for display but not stored in plain text.

### SEC-TPT-02: AttendanceDevice Gate Prefix Typo — CRITICAL
**Severity: Critical**

All Gate checks in `AttendanceDeviceController` use the prefix `tested.*` instead of `tenant.*`:
```php
Gate::authorize('tested.attendance-device.viewAny');  // WRONG
// Should be:
Gate::authorize('tenant.attendance-device.viewAny');  // CORRECT
```
This means **all permission checks for AttendanceDevice fail silently** — the Gate likely throws an AuthorizationException or passes through depending on Gate::before policy. This must be corrected before production deployment.

### SEC-TPT-03: Zero Service Layer — Security Impact
**Severity: High**

With all business logic in controllers, there are no centralized validation hooks. Input sanitization and business rule enforcement (capacity limits, license validation) are scattered and inconsistent. The service layer gap must be addressed.

### SEC-TPT-04: GPS Data Privacy
**Severity: Medium**

When GPS integration is implemented, student location data (derived from bus location) will be PII. The GPS data storage strategy must include:
- Data retention policy (purge GPS logs after N days).
- Access control: parent can only see their own child's bus.
- No cross-tenant GPS data leakage.

---

## Section 12 — FormRequests Inventory

| FormRequest | Covers |
|---|---|
| `VehicleRequest` | Vehicle create/update validation |
| `DriverHelperRequest` | Personnel create/update |
| `RouteRequest` | Route create/update |
| `PickupPointRequest` | Pickup point create/update |
| `PickupPointRouteRequest` | Route-stop assignment |
| `DriverRouteVehicleRequest` | Driver-route-vehicle junction |
| `TripRequest` | Trip create/update |
| `ShiftRequest` | Shift master |
| `StudentAllocationRequest` | Student route allocation |
| `AttendanceDeviceRequest` | Device registration |
| `DriverAttendanceRequest` | Driver attendance entry |
| `TptDailyVehicleInspectionRequest` | Pre-trip inspection |
| `TptVehicleMaintenanceRequest` | Maintenance record |
| `TptVehicleFuelRequest` | Fuel log entry |
| `LiveTripRequest` | Live trip (GPS) |
| `FineMasterRequest` | Fine rule |
| `FeeCollectionRequest` | Fee collection |
| `VendorRequest` | (Misplaced — belongs in Vendor module, not Transport) |

**Gap:** No FormRequest exists for:
- `StudentAttendanceRequest` (student boarding log)
- `TptVehicleServiceRequestRequest` (service requests)
- `RouteSchedulerRequest` (route scheduler)

---

## Section 13 — Tests Gap

**Current test count: 0**

There are no unit tests or feature tests in the Transport module. Given the complexity of the business rules (capacity limits, compliance expiry, trip lifecycle, fee calculation), testing is critical.

**Priority test areas:**
1. Vehicle compliance expiry detection
2. Student allocation capacity enforcement
3. Trip status lifecycle transitions
4. Fee calculation (base + fine)
5. Driver attendance calculation (total_work_minutes)
6. Inspection-to-maintenance pipeline trigger
7. AttendanceDeviceController Gate fix (regression test)

---

## Section 14 — Gaps and Pending Work

### Critical Bugs to Fix Before Production
1. `AttendanceDeviceController` — `tested.*` Gate prefix bug (all auth broken).
2. Aadhaar/ID number stored unencrypted in `tpt_personnel.id_no`.
3. Five or more controllers identified with zero Gate checks — full auth audit required.

### Missing Features (vs. RBS Module N)
| RBS Requirement | Status |
|---|---|
| Real-time GPS tracking (F.N4.1) | Stub only — no live integration |
| Parent push notifications when bus approaches stop (F.N4.2) | Stub only |
| AI route optimization (F.N8.2) | Data structures only — no inference |
| Stop-change approval workflow (F.N3.1.2) | Model exists; controller workflow incomplete |
| Auto-sync bus attendance with school attendance (F.N5.1.2) | Not implemented |
| Timetable sync for transport fee billing cycle (F.N6.1) | Partial |

### Architecture Gaps
| Gap | Impact |
|---|---|
| Zero service classes (0 of recommended 9) | All logic in controllers; untestable |
| GPS integration not implemented | F.N4 GPS tracking non-functional |
| No seeder for transport master data | Fresh install has no shifts, vehicle types, fuel types |
| `tpt_vendor` migration exists in Transport module | Duplicate — vendor data should be in Vendor module only |
| `VendorRequest.php` in Transport module | Misplaced FormRequest |

---

## Section 15 — Development Priority

### Phase 1 — Bug Fixes (Sprint 1)
1. Fix `AttendanceDeviceController` Gate prefix (`tested.*` → `tenant.*`).
2. Encrypt `id_no` field in `tpt_personnel` (AES-256).
3. Audit all 31 controllers for missing Gate checks; add missing authorization.
4. Remove duplicate `tpt_vendor` migration and `VendorRequest` from Transport module.

### Phase 2 — Service Layer (Sprint 2)
5. Create `TransportVehicleService` — vehicle CRUD + compliance check logic.
6. Create `TransportRouteService` — route + stop + capacity logic.
7. Create `TransportAllocationService` — student allocation + stop-change workflow.
8. Create `TransportTripService` — trip lifecycle state machine.
9. Create `TransportFeeService` — fee calculation and collection.

### Phase 3 — Missing Workflows (Sprint 3)
10. Implement stop-change approval workflow (request → approve/reject → new allocation).
11. Implement capacity enforcement in StudentAllocationController (pre-save check).
12. Implement compliance expiry check on vehicle-to-trip assignment.
13. Complete route scheduler → auto-trip generation flow.
14. Auto-sync bus attendance boarding log to school attendance module.

### Phase 4 — Integration (Sprint 4)
15. Accounting module integration: transport fee collection → acc_vouchers.
16. Notification module integration: boarding confirmation, bus delay alerts.
17. GPS API stub → live integration (hardware/API selection required).
18. Parent portal integration: "Where is the bus?" screen.

### Phase 5 — Testing (Sprint 5)
19. Write unit tests for all service classes.
20. Write feature tests for all major workflows (allocation, trip lifecycle, fee collection).

---

*Document generated: 2026-03-25 | Reviewed against: Module code at `/Modules/Transport`, RBS Module N, tenant_db schema*
