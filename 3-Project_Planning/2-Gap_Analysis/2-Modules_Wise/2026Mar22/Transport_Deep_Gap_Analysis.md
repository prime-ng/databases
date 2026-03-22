# Transport Module — Production-Readiness Gap Analysis
**Date:** 2026-03-22  |  **Branch:** Brijesh_SmartTimetable  |  **Auditor:** Claude Code (Deep Audit)
**Module Path:** /Users/bkwork/Herd/prime_ai/Modules/Transport

---

## EXECUTIVE SUMMARY

| Metric | Count |
|--------|-------|
| Critical (P0) | 4 |
| High (P1) | 10 |
| Medium (P2) | 15 |
| Low (P3) | 7 |
| **Total Issues** | **36** |

| Area | Score |
|------|-------|
| DB Integrity | 6/10 |
| Route Integrity | 7/10 |
| Controller Quality | 7/10 |
| Model Quality | 7/10 |
| Service Layer | 2/10 |
| FormRequest | 8/10 |
| Policy/Auth | 8/10 |
| Test Coverage | 0/10 |
| Security | 5/10 |
| Performance | 5/10 |
| **Overall** | **5.5/10** |

---

## SECTION 1: DATABASE INTEGRITY

### DDL Tables (23 tables)
1. `tpt_vehicle` (line 1131)
2. `tpt_personnel` (line 1171)
3. `tpt_shift` (line 1200)
4. `tpt_route` (line 1214)
5. `tpt_pickup_points` (line 1232)
6. `tpt_pickup_points_route_jnt` (line 1253)
7. `tpt_driver_route_vehicle_jnt` (line 1281)
8. `tpt_route_scheduler_jnt` (line 1328)
9. `tpt_trip` (line 1356)
10. `tpt_trip_stop_detail` (line 1386)
11. `tpt_attendance_device` (line 1412)
12. `tpt_driver_attendance` (line 1436)
13. `tpt_driver_attendance_log` (line 1451)
14. `tpt_student_route_allocation_jnt` (line 1471)
15. `tpt_fine_master` (line 1496)
16. `tpt_student_fee_detail` (line 1509)
17. `tpt_student_fine_detail` (line 1523)
18. `tpt_student_fee_collection` (line 1540)
19. `tpt_vehicle_fuel` (line 1588)
20. `tpt_daily_vehicle_inspection` (line 1609)
21. `tpt_vehicle_service_request` (line 1650)
22. `tpt_vehicle_maintenance` (line 1675)
23. `tpt_trip_incidents` (line 1704)
24. `tpt_student_boarding_log` (line 1734)
25. `tpt_notification_log` (line 1766)

### Issues

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| DB-01 | P1 | `tpt_vehicle` missing `created_by` column | DDL line 1131-1169 |
| DB-02 | P1 | `tpt_personnel` missing `created_by` column | DDL line 1171-1198 |
| DB-03 | P1 | `tpt_trip` missing `is_active` column | DDL line 1356-1384 |
| DB-04 | P1 | `tpt_driver_attendance` missing `updated_at`, `deleted_at`, `is_active` columns | DDL line 1436-1449 |
| DB-05 | P1 | `tpt_driver_attendance_log` missing `updated_at`, `deleted_at`, `is_active` columns | DDL line 1451-1465 |
| DB-06 | P2 | `tpt_fine_master` missing `updated_at`, `is_active`, `created_by` columns | DDL line 1496-1507 |
| DB-07 | P2 | `tpt_student_fee_detail` missing `updated_at`, `is_active`, `created_by` columns | DDL line 1509-1521 |
| DB-08 | P2 | `tpt_student_fine_detail` missing `updated_at`, `is_active`, `created_by` columns | DDL line 1523-1538 |
| DB-09 | P2 | `tpt_student_fee_collection` missing `updated_at`, `is_active`, `created_by` columns | DDL line 1540-1555 |
| DB-10 | P2 | `tpt_trip.status` is VARCHAR(20) but should be FK to sys_dropdown_table for consistency | DDL line 1370 |
| DB-11 | P2 | `tpt_student_fee_detail.status` is VARCHAR(20) — should be FK | DDL line 1518 |
| DB-12 | P2 | `tpt_student_fee_collection.status` is VARCHAR(20) — should be FK | DDL line 1547 |
| DB-13 | P2 | `tpt_student_fee_collection.payment_mode` is VARCHAR(20) — should be FK | DDL line 1546 |
| DB-14 | P2 | `tpt_student_route_allocation_jnt` missing `student_id` FK to `std_students` — only has `student_session_id` FK | DDL line 1471-1490 |
| DB-15 | P3 | `tpt_fine_master.Remark` uses uppercase R — inconsistent with project convention | DDL line 1504 |
| DB-16 | P3 | `tpt_daily_vehicle_inspection` uses lowercase `Create Table` — inconsistent casing | DDL line 1609 |
| DB-17 | P3 | `tpt_vehicle_service_request.Vehicle_status` uses uppercase V — inconsistent | DDL line 1655 |

---

## SECTION 2: ROUTE INTEGRITY

### Registered Routes (tenant.php lines 2214+)
The Transport module has extensive routes covering:
- `transport.transport-master.*` — resource
- `transport.vehicles.ajax` — AJAX endpoint
- `transport.dashboard.data` — dashboard
- Vehicle, Route, PickupPoint, DriverHelper, PickupPointRoute, Shift, DriverRouteVehicle, RouteScheduler — all with CRUD + trash/restore/forceDelete/toggleStatus
- Trip, LiveTrip, DriverAttendance, StudentAllocation — CRUD + extra endpoints
- FeeMaster, FeeCollection, FineMaster, AttendanceDevice — CRUD
- VehicleFuel, DailyVehicleInspection, VehicleMaintenance, VehicleServiceRequest — CRUD
- StudentFineDetail, StudentBoarding, StudentAttendance — CRUD
- TransportReport — 11 report types

### Issues

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| RT-01 | P0 | `EnsureTenantHasModule` middleware NOT applied to transport route group | tenant.php line 2214 |
| RT-02 | P2 | Extremely large number of routes (~150+) in single group — consider sub-grouping | tenant.php lines 2214+ |
| RT-03 | P2 | Some route names may collide due to flat naming under `transport.*` prefix | Various |
| RT-04 | P3 | Mix of snake_case and kebab-case in route prefixes (e.g., `driver_route_vehicle` vs `driver-attendance`) | Various route definitions |

---

## SECTION 3: CONTROLLER AUDIT

### VehicleController.php (analyzed first 100 lines)
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Transport/app/Http/Controllers/VehicleController.php`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| CT-01 | P2 | `create()` uses Gate `tenant.vehicle.view` instead of `tenant.vehicle.create` | Line 61 |
| CT-02 | P2 | `create()` has a Dropdown query to find vendor type — hardcoded dropdown key | Lines 64-65 |
| CT-03 | P3 | `show()` has commented `dd($vehicle)` | Line 51 |

**Positive observations:**
- Uses `VehicleRequest` FormRequest for store
- Uses `$request->validated()` via FormRequest
- Gate authorization on all methods
- Spatie MediaLibrary integration for document uploads
- AJAX-aware responses

### Controllers (34 total)
The Transport module has the most controllers of any module:
1. `AttendanceDeviceController.php`
2. `DriverAttendanceController.php`
3. `DriverHelperController.php`
4. `DriverRouteVehicleController.php`
5. `FeeCollectionController.php`
6. `FeeMasterController.php`
7. `FineMasterController.php`
8. `LiveTripController.php`
9. `NewTripController.php`
10. `PickupPointController.php`
11. `PickupPointRouteController.php`
12. `RouteController.php`
13. `RouteSchedulerController.php`
14. `ShiftController.php`
15. `StaffMgmtController.php`
16. `StudentAllocationController.php`
17. `StudentAttendanceController.php`
18. `StudentBoardingController.php`
19. `StudentRouteFeesController.php`
20. `TptDailyVehicleInspectionController.php`
21. `TptStudentFineDetailController.php`
22. `TptVehicleFuelController.php`
23. `TptVehicleMaintenanceController.php`
24. `TptVehicleServiceRequestController.php`
25. `TransportDashboardController.php`
26. `TransportMasterController.php`
27. `TransportReportController.php`
28. `TripController.php`
29. `TripMgmtController.php`
30. `VehicleController.php`
31. `VehicleMgmtController.php`

### General Controller Issues

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| CT-04 | P1 | Tab-based controllers (TransportMasterController, StaffMgmtController, VehicleMgmtController, TripMgmtController, StudentRouteFeesController) likely load all sub-resource data in single request — performance concern | Tab controllers |
| CT-05 | P2 | Controller naming inconsistency: `TptVehicleFuelController` (prefixed) vs `VehicleController` (not prefixed) | Controller names |
| CT-06 | P3 | Some controllers may have `New` prefix (NewTripController) — should follow standard naming | NewTripController |

---

## SECTION 4: MODEL AUDIT

### Vehicle Model
**Path:** `/Users/bkwork/Herd/prime_ai/Modules/Transport/app/Models/Vehicle.php`

**Positive observations:**
- `SoftDeletes` trait present
- Comprehensive `$fillable` matching DDL columns
- Proper `$casts` for dates, integers, booleans
- Good relationships: inspections, driverRouteVehicles, serviceRequests, maintenanceRecords, vendor, fuelLogs, vehicleType, fuelType, ownershipType, emissionClass
- Spatie MediaLibrary with 8 document collections
- `scopeActive` defined

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| MD-01 | P2 | `serviceRequests()` uses indirect HasMany via `whereHas` — non-standard pattern, may confuse eager loading | Lines 72-76 |
| MD-02 | P2 | `maintenanceRecords()` same indirect pattern | Lines 79-84 |
| MD-03 | P2 | Missing `created_by` in `$fillable` | Lines 23-43 |
| MD-04 | P3 | `$fillable` contains `documents_uploaded` but DDL has separate `_upload` columns per document type | Line 42 vs DDL |

### Models (28+ total)
Comprehensive model coverage — all DDL tables have corresponding models plus extras:
- `Vehicle`, `DriverHelper`, `Shift`, `Route`, `PickupPoint`, `PickupPointRoute`
- `DriverRouteVehicleJnt`, `TptRouteSchedulerJnt`, `TptTrip`, `TptTripStopDetail`
- `AttendanceDevice`, `TptDriverAttendance`, `TptDriverAttendanceLog`
- `TptStudentAllocationJnt`, `TptFineMaster`, `TptStudentFineDetail`
- `TptFeeCollection`, `TptFeeMaster`, `TptStudentFeeCollection`
- `TptVehicleFuel`, `TptDailyVehicleInspection`, `TptVehicleServiceRequest`, `TptVehicleMaintenance`
- `TptTripIncidents`, `StudentBoardingLog`, `TptNotificationLog`
- `TptLiveTrip`, `TptGpsAlerts`, `TptGpsTripLog` (GPS-related)
- `StudentPayLog`, `MlModels`, `MlModelFeatures`, `TptFeatureStore`, `TptModelRecommendations`, `TptRecommendationHistory` (ML-related)
- `TptStudentEventLog`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| MD-05 | P1 | ML-related models (`MlModels`, `MlModelFeatures`, `TptFeatureStore`, `TptModelRecommendations`) have no corresponding DDL tables | Model files |
| MD-06 | P1 | GPS-related models (`TptGpsAlerts`, `TptGpsTripLog`, `TptLiveTrip`) have no DDL definitions in tenant_db_v2.sql | Model files |
| MD-07 | P2 | `TptStudentEventLog` model has no corresponding DDL table | Model file |

---

## SECTION 5: SERVICE AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| SV-01 | P0 | **NO Service classes exist** for the Transport module | `Modules/Transport/app/Services/` directory does not exist |
| SV-02 | P0 | Complex business logic (route scheduling, fee calculation, trip management, attendance processing) all in controllers | Controllers |
| SV-03 | P1 | Invoice/billing integration with Vendor module (`trip_usage_needs_to_be_updated_into_vendor_usage_log`) not implemented as service | Business requirement from DDL comments |
| SV-04 | P1 | No service for GPS/live tracking operations | TptLiveTrip, TptGpsAlerts models |

---

## SECTION 6: FORMREQUEST AUDIT

### Present FormRequests (15)
1. `AttendanceDeviceRequest.php`
2. `DriverAttendanceRequest.php`
3. `DriverHelperRequest.php`
4. `DriverRouteVehicleRequest.php`
5. `FeeCollectionRequest.php`
6. `FineMasterRequest.php`
7. `LiveTripRequest.php`
8. `PickupPointRequest.php`
9. `PickupPointRouteRequest.php`
10. `RouteRequest.php`
11. `ShiftRequest.php`
12. `StudentAllocationRequest.php`
13. `TptDailyVehicleInspectionRequest.php`
14. `TptVehicleFuelRequest.php`
15. `TptVehicleMaintenanceRequest.php`
16. `TripRequest.php`
17. `VehicleRequest.php`
18. `VendorRequest.php` (Transport-specific vendor request)

**Excellent FormRequest coverage — 18 request classes for the module's operations.**

### Issues

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| FR-01 | P2 | Missing FormRequest for RouteScheduler operations | No RouteSchedulerRequest.php |
| FR-02 | P2 | Missing FormRequest for StudentBoarding operations | No StudentBoardingRequest.php |
| FR-03 | P2 | Missing FormRequest for TripIncidents | No TripIncidentRequest.php |
| FR-04 | P3 | `VendorRequest.php` in Transport module — should use Vendor module's request or be renamed | Transport-specific vendor request |

---

## SECTION 7: POLICY AUDIT

### Policies Present (42+)
The Transport module has the most comprehensive policy coverage:

**Core Resource Policies:**
- `VehiclePolicy`, `RoutePolicy`, `ShiftPolicy`, `PickupPointPolicy`, `PickupPointRoutePolicy`
- `DriverHelperPolicy`, `DriverRouteVehiclePolicy`, `DriverAttendancePolicy`
- `RouteSchedulerPolicy`, `StudentAllocationPolicy`
- `TptDailyVehicleInspectionPolicy`, `TptVehicleMaintenancePolicy`
- `LiveTripPolicy`, `TripPolicy`, `TripMgmtPolicy`
- `TransportDashboardPolicy`

**Granular Feature Policies:**
- `TransportDriverRouteVehiclePolicy`, `TransportRouteSchedulerPolicy`
- `TransportDailyVehicleInspectionPolicy`, `TransportVehicleServiceRequestPolicy`
- `TransportVehicleServiceApprovalPolicy`, `TransportVehicleMaintenancePolicy`
- `TransportStopsListPolicy`, `TransportAttendanceDevicePolicy`
- `TransportDriverAttendancePolicy`, `TransportTripPolicy`
- `TransportStopDetailsPolicy`, `TransportStudentBoardingPolicy`
- `TransportTripIncidentPolicy`, `TransportTripApprovePolicy`
- `TransportFineMasterPolicy`, `TransportStudentAllocationPolicy`
- `TransportFeeMasterPolicy`, `TransportFineDetailPolicy`
- `TransportFeeCollectionPolicy`, `TransportStudentPayLogPolicy`
- `TransportPolicy`

**Report Policies:**
- `CostMaintenanceReportPolicy`, `DriverPerformanceReportPolicy`
- `RoutePerformanceReportPolicy`, `ManagementDashboardReportPolicy`
- `NotificationsReportPolicy`, `StopAnalysisReportPolicy`
- `StudentBoardingReportPolicy`, `StudentTransportUsageReportPolicy`
- `TransportFinanceReportPolicy`, `TripExecutionReportPolicy`
- `UniversalReportPolicy`

All registered in `AppServiceProvider.php`.

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| PL-01 | P2 | Duplicate policy patterns — both `DriverAttendancePolicy` and `TransportDriverAttendancePolicy` exist | Policies directory |
| PL-02 | P2 | Some policies may not map to actual model-controller pairs — verify all are used | AppServiceProvider |

---

## SECTION 8: VIEW AUDIT

Comprehensive view coverage with 100+ blade files organized by feature:
- `vehicle/` — CRUD + partials (6 views)
- `route/` — CRUD + trash (5 views)
- `shift/` — CRUD + trash (5 views)
- `pickup_point/` — CRUD + trash + map (6 views)
- `pickup_point_route/` — CRUD + trash (5 views)
- `driver_helper/` — CRUD + trash (5 views)
- `driver_route_vehicle/` — CRUD + trash (5 views)
- `route-scheduler/` — CRUD + trash + createtrip (6 views)
- `trip/` — CRUD + trash (5 views)
- `live-trip/` — CRUD + trash (5 views)
- `driver-attendance/` — CRUD + trash + QR (6 views)
- `student-allocation/` — CRUD + trash + js + model (7 views)
- `attendance_device/` — CRUD + trash (5 views)
- `fee-master/` — CRUD + trash + PDF (6 views)
- `fee-collection/` — CRUD (4 views)
- `fine-master/` — CRUD + trash (5 views)
- `fine-details/` — edit + index + show + trash (4 views)
- `vehicle_fuel/` — CRUD + trash (5 views)
- `daily-vehicle-Inspection/` — CRUD + trash (5 views)
- `vehiclemaintenance/` — edit + index + show (3 views)
- `vehicle-service-request/` — CRUD + trash + approval (6 views)
- `trip-details/` — details-list + index + js + model (4 views)
- `trip-incidents/` — index + js (2 views)
- `trip_approve/` — index + js + model (3 views)
- `student-bord-unbord/` — index + js + model (3 views)
- `student_attendance/` — index (1 view)
- `dashboard/` — index (1 view)
- `report/` — 10 report views
- `tab_module/` — 6 tab views
- `logs/` — index + js (2 views)
- Exports: `FeeCollectionExport`, `FeeMasterExport`, `StudentAllocationExport`
- Imports: `FeeMasterImport`, `FeeMasterReadOnly`, `StudentAllocationImport`, `StudentAllocationReadOnly`

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| VW-01 | P3 | Directory naming inconsistency: `daily-vehicle-Inspection/` (capital I) vs `vehicle-service-request/` (lowercase) | Views directory |
| VW-02 | P3 | Mix of snake_case (`pickup_point/`) and kebab-case (`fee-master/`) directories | Views directory |

---

## SECTION 9: SECURITY AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| SEC-01 | P1 | `tpt_personnel` stores `id_no` (Aadhaar/PAN/Passport) in plain text — PII exposure | DDL line 1179, DriverHelper model |
| SEC-02 | P1 | `tpt_personnel.license_no` stored in plain text | DDL line 1181 |
| SEC-03 | P1 | GPS coordinates (`latitude`, `longitude`) stored without access controls — privacy concern | Multiple DDL tables |
| SEC-04 | P2 | `tpt_attendance_device.pg_fcm_token` stored as plain TEXT — should be encrypted | DDL line 1423 |
| SEC-05 | P2 | Student boarding logs contain location data tied to individual students — COPPA/privacy concerns | DDL line 1734 |
| SEC-06 | P2 | No rate limiting on live trip update endpoints | Routes |

---

## SECTION 10: PERFORMANCE AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| PERF-01 | P1 | Tab-based controllers likely load all sub-data in single request (6 tab controllers: TransportMaster, StaffMgmt, VehicleMgmt, TripMgmt, StudentRouteFees, TransportReport) | Tab controllers |
| PERF-02 | P1 | `tpt_trip` no index on `trip_date` for date-range queries | DDL line 1356 |
| PERF-03 | P2 | `tpt_student_boarding_log` no index on `trip_date` or `student_id` | DDL line 1734 |
| PERF-04 | P2 | `tpt_driver_attendance` no index on `attendance_date` beyond the unique key | DDL line 1436 |
| PERF-05 | P2 | SPATIAL index on `route_geometry` and `location` — verify MySQL spatial functions are used in queries | DDL lines 1228, 1249 |
| PERF-06 | P2 | No caching strategy for frequently accessed data (vehicle list, route list, shift list) | Module-wide |
| PERF-07 | P3 | Trigger `trg_driver_route_vehicle_unique_assignment` on every INSERT — could be slow at scale | DDL lines 1303-1326 |

---

## SECTION 11: ARCHITECTURE AUDIT

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| ARCH-01 | P0 | **NO Service layer** — Transport is the largest module (34 controllers, 28 models, 23 tables) with zero services | Module-wide |
| ARCH-02 | P1 | Export classes exist (good pattern) — `FeeCollectionExport`, `FeeMasterExport`, `StudentAllocationExport` | Exports directory |
| ARCH-03 | P1 | Import classes exist (good pattern) — with ReadOnly variants for validation | Imports directory |
| ARCH-04 | P1 | ML model files exist but no DDL — unclear if feature is production-ready | ML models |
| ARCH-05 | P2 | No Event/Listener classes — trip completion, attendance logging, incident alerts should be event-driven | Module-wide |
| ARCH-06 | P2 | No Job classes for background processing (route scheduling, batch fee generation, GPS processing) | Module-wide |
| ARCH-07 | P3 | Good use of Spatie MediaLibrary for document management | Vehicle, DriverHelper models |

---

## SECTION 12: TEST COVERAGE

| ID | Severity | Issue | Location |
|----|----------|-------|----------|
| TST-01 | P0 | **ZERO tests** — only `.gitkeep` files in tests/Feature and tests/Unit | `Modules/Transport/tests/` |

---

## SECTION 13: BUSINESS LOGIC COMPLETENESS

| Feature | Status | Notes |
|---------|--------|-------|
| Vehicle CRUD | Complete | FormRequest, Gate, Media uploads |
| Personnel/Driver-Helper CRUD | Complete | FormRequest, Gate |
| Shift CRUD | Complete | FormRequest, Gate |
| Route CRUD | Complete | FormRequest, Gate, Spatial data |
| Pickup Points CRUD | Complete | FormRequest, Gate, Spatial data |
| Pickup Point Route Mapping | Complete | FormRequest, Gate |
| Driver-Route-Vehicle Assignment | Complete | FormRequest, Gate, DB trigger for overlap prevention |
| Route Scheduler | Complete | Views, controller present |
| Trip Management | Complete | CRUD + approval workflow |
| Live Trip Tracking | Present | Controller + views, GPS models |
| Driver Attendance | Complete | QR-based, device management |
| Student Allocation | Complete | CRUD + bulk import/export |
| Fee Master | Complete | CRUD + import/export + PDF |
| Fee Collection | Complete | CRUD |
| Fine Master & Details | Complete | CRUD |
| Vehicle Fuel Logging | Complete | CRUD + approval |
| Daily Vehicle Inspection | Complete | CRUD + checklist |
| Vehicle Service Request | Complete | CRUD + approval workflow |
| Vehicle Maintenance | Complete | CRUD + approval |
| Trip Incidents | Present | Views exist |
| Student Boarding/Unboarding | Present | Controller + views |
| Student Attendance | Present | Basic views |
| Transport Dashboard | Present | AJAX data endpoint |
| Transport Reports | Present | 11 report types with views |
| Vendor Usage Log Integration | NOT IMPLEMENTED | DDL condition mentions it but no service code |
| GPS Real-time Tracking | Partial | Models exist but no real-time infrastructure |
| Notification Alerts | Partial | NotificationLog model but no integration with Notification module |
| ML Recommendations | Partial | Models exist but no service/pipeline |

---

## PRIORITY FIX PLAN

### P0 — Must Fix Before Production
1. Create Service layer — at minimum: TripService, RouteSchedulingService, FeeCalculationService, AttendanceService
2. Add `EnsureTenantHasModule` middleware to route group
3. Write critical path tests (Vehicle CRUD, Trip lifecycle, Fee collection)
4. Add missing DDL tables for ML and GPS models

### P1 — Fix Before Beta
1. Add `created_by` columns to vehicle, personnel, and other tables missing it
2. Add missing standard columns (`is_active`, `updated_at`, `deleted_at`) to fee/fine/attendance tables
3. Encrypt PII data (Aadhaar, PAN, license numbers)
4. Implement vendor usage log integration
5. Create Event/Listener classes for trip lifecycle
6. Create Job classes for batch operations
7. Fix duplicate policy patterns
8. Fix tab controller performance (lazy-load via AJAX)
9. Add missing FormRequests (RouteScheduler, StudentBoarding, TripIncidents)
10. Standardize `status` columns to FK instead of VARCHAR

### P2 — Fix Before GA
1. Add database indexes for date-range and status queries
2. Implement caching for lookup tables
3. Add notification module integration
4. Complete GPS tracking infrastructure
5. Fix view directory naming inconsistencies
6. Fix controller naming conventions
7. Add export/report for vehicle maintenance cost analysis

### P3 — Nice to Have
1. Fix DDL column naming conventions (uppercase fields)
2. Standardize view directory naming
3. ML recommendation pipeline
4. Route optimization algorithms

---

## EFFORT ESTIMATION

| Priority | Estimated Hours |
|----------|----------------|
| P0 Fixes | 32-40 hours |
| P1 Fixes | 40-56 hours |
| P2 Fixes | 24-32 hours |
| P3 Fixes | 8-12 hours |
| Test Suite | 32-48 hours |
| **Total** | **136-188 hours** |
