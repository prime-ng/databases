# 06 — Transport module: deep scan as the base for PrimeTransport (2026-10-23)

This is a static scan of `prime_ai/Modules/Transport`, which PrimeTransport will extend. SmartTransport is out of scope and stays untouched.

## 1. Size & shape
- **32 web controllers** + 1 mobile controller (38 actions), **34 models**, 6 mobile services, 16 imports, 3 exports, 49 policies, 158 views.
- **38 `tpt_*` tables** (+ `std_student_pay_log`). Every core model uses SoftDeletes.
- **Routes:** web routes at `/transport` (`transport.*`, gated `EnsureTenantHasModule:Transport`); the mobile API at `admin/transport` is loaded from `routes/api.php:74`.
- **Transactions and try/catch:** now present in nearly every mutating controller. The 2026-08-18 alignment record (`prime_info/Final/ControllerAlignment/Transport.md`, 3% aligned) is out of date.
- **Tests:** 0.

## 2. Menu (6 pages)
Dashboard · Transport Master (Vehicle, Staff, Shift, Route, Stops, Stop list, Assign stops, Device, Fine Category, Fine Master) · Vehicle Mgmt (Fuel, Inspection, Service, Approval, Maintenance) · Trip Management (Roster, Scheduler, Daily Trip, Stop status, Stop details, Board/Unboard, Incidents, Trip approve, Notification log) · Student Transport Mgmt (Allocation, Fee invoicing, Fine detail, Fee collection, Fee log) · Transport Report (11 report tabs).

## 3. The data PrimeTransport will read

| Area | Tables | Useful for the engine / advisor |
|---|---|---|
| Network | `tpt_shift`, `tpt_route` (LINESTRING, `est_exp_per_km`), `tpt_pickup_points` (lat/lng + POINT), `tpt_pickup_points_route_jnt` (ordinal, distance, arrival/departure, `pickup_drop_fare`, `both_side_fare`) | current routes = the **baseline plan** |
| Fleet & crew | `tpt_vehicle` (capacity, max_capacity, ownership, vendor, doc expiries, `gps_device_id`, `avg_exp_per_km`, `avg_fare_per_km`, rating), `tpt_personnel` (role, licence, experience, police verification) | vehicle types, cost per km, compliance |
| Assignment | `tpt_driver_route_vehicle_jnt` (+ unique-assignment trigger), `tpt_route_scheduler_jnt` (per date) | who drives what; daily overrides |
| Demand | `tpt_student_route_allocation_jnt` (student_session, use type, pickup/drop route+stop, **fare typed by hand**) | students per stop and direction |
| Execution | `tpt_trip` (odometer, fuel readings, approval), `tpt_trip_stop_detail` (**scheduled vs actual arrival/leave**, emergency flag), `tpt_student_boarding_log`, `tpt_trip_incidents` (lat/lng, severity) | **learned ETAs**, delays, safety |
| Cost | `tpt_vehicle_fuel`, `tpt_vehicle_maintenance`, `tpt_vehicle_service_request`, `tpt_daily_vehicle_inspection` | real ₹/km, wear, downtime |
| Money | `tpt_student_fee_detail` (**amount typed per student-month**), `tpt_student_fee_collection`, `tpt_student_fine_detail`, `tpt_fine_master` | income per route |
| Crew attendance | `tpt_driver_attendance` (+ log, QR/RFID/NFC) | crew minutes, overtime |
| Parent comms | `tpt_notification_log` (TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled × app/SMS/email/WhatsApp status) | adoption and coverage |

## 4. Gaps that block a "smart" layer

| # | Gap | Evidence | Impact |
|---|---|---|---|
| G1 | **Shifts have no times**, only `effective_from/to` | `create_tpt_shift_table.php` | can't enforce "reach school by 7:30", can't reuse buses across shifts (tiering) |
| G2 | **No vehicle depot/parking location** | `tpt_vehicle` columns | empty-run km and first-stop time are unknown |
| G3 | **No student home coordinates** anywhere | no lat/lng in any std_/adm_ migration | no stop-placement optimiser, no admission quote by address |
| G4 | **No GPS ping storage.** `TptGpsTripLog`, `TptGpsAlerts`, `TptFeatureStore`, `TptModelRecommendations`, `TptRecommendationHistory` and `TptStudentEventLog` are 22-line empty stubs with no table | `app/Models/*` | no live position, overspeed or AIS-140 panic ingest |
| G5 | **Parent notifications are fake.** `MobileTripService::notify()` only inserts a `tpt_notification_log` row with `app_notification_status='Sent'`; nothing is sent | `Services/MobileTripService.php:133-142` | parents get nothing; adoption metrics are meaningless |
| G6 | **Missing coordinates become Bangalore** (12.9716, 77.5946) | `Imports/PickupPointImport.php:66-67`, `Models/PickupPoint.php:61-62`, `Models/Route.php:55`, `Imports/RouteImport.php:72` | poisons every distance and cost calculation |
| G7 | **Fares and fees are manual.** The allocation `fare` and the monthly fee `amount` are typed in, not derived from stop or route | `StudentAllocationRequest`, `FeeMasterController::store` | route income is only as good as the typing |
| G8 | **No domain events.** Transport fires no Laravel events (trip start, stop reached, incident, allocation change) | grep `event(` = 0 | another module can't react without polling |
| G9 | `TptTripIncidents::incidentType()/statusMaster()` point to classes that don't exist (`TptIncidentType`, `TptIncidentStatus`) | `Models/TptTripIncidents.php:92-101` | latent crash the first time someone eager-loads them |
| G10 | `TptFeeCollection` maps to `tpt_fee_collection`, a table that does not exist; the model is unused | `Models/TptFeeCollection.php` | dead code |
| G11 | Map assets come from unpkg, and routing from the public OSRM demo server | `pickup_point.blade.php:196-197` | not production-grade |

## 5. Existing integrations
- **Outbound:** SchoolSetup (72 imports), StudentProfile (22), Prime (10), GlobalMaster (6), Vendor (5), Template (4), **Accounting `RemoteEntryService`** (allocation + mobile fee collection).
- **Inbound (other modules that use Transport):** StudentProfile (Student, StudentAcademicSession), SchoolSetup User, StudentFee, ParentPortal, StudentPortal, Complaint, Vendor (agreements/invoices), Template seeder.
- **Licence:** `EnsureTenantHasModule` resolves the module from route name → `glb_menus` → `glb_menu_module_jnt` → `glb_modules`. A new module needs its own central module row and menu mapping.
- **Reusable pattern:** SmartTimetable's `Services/Python/PythonRunner.php` + `Jobs/GenerateTimetableJob.php` + `GenerationProgress` + `SolverProcessReaper`, with the rule "**PHP owns the database; Python gets a JSON payload, no DB driver**".
- **Python environment:** `/usr/bin/python3` = 3.14.4. **OR-Tools is not installed**; numpy is the only dependency today.
