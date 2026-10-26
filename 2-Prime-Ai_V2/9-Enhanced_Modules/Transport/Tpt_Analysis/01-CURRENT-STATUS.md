# 01 — Current Status (2026-10-23)

## 1. The two modules

| | Transport | SmartTransport |
|---|---|---|
| Path | `Modules/Transport` | `Modules/SmartTransport` |
| Created | long-standing (402 commits) | 2026-10-17, fork by Shailesh (29 commits, last 2026-10-22) |
| Files / PHP lines | 357 / ~67.6K | 385 / ~87.2K |
| Web prefix / route names | `/transport`, `transport.*` | `/smarttransport`, `smarttransport.*` |
| Licence gate | `EnsureTenantHasModule:Transport` | **also** `EnsureTenantHasModule:Transport` (no own key) |
| Permissions | `tenant.transport.*` | `tenant.smarttransport.*` (48 keys in `config/permissionslist.php` §09b; all 181 gates used resolve to a defined permission ✅) |
| Mobile API | loaded from `routes/api.php:74` | `routes/mobile_api.php` exists but is **never loaded** (dead copy; same `admin/transport` prefix) |
| Daily command | `transport:check-expiries` | `smarttransport:check-expiries` (both scheduled daily) |
| Tables | `tpt_*` | **the same `tpt_*` tables**, plus the proposal and history tables |
| Tests | 0 real tests | 0 real tests |

### Fork drift
After swapping the namespace, 188 shared files are identical and **155 have diverged**. The biggest diffs are in `TripController` (791 changed lines), `TransportReportController` (775), `PickupPointController` (510), `FeeCollectionController` (356), all six `Mobile*Service` files, `StudentAllocationController` (298) and `FeeMasterController` (216).
So a bug fixed in one module is usually *not* fixed in the other. For example, the 2026-10-21 Transport model fixes and the 2026-10-22 SmartTransport fixes each landed in one module only.

## 2. Menu & tabs (from `Modules/PrimeCore/.../MenuSyncController.php` ~L1626–1670)

### Transport (6 menu entries)
Dashboard · Transport Master · Vehicle Mgmt · Trip Management · Student Transport Mgmt. · Transport Report

### Smart Transport (8 menu entries)
The first six repeat Transport's menu with a "Smart" prefix. The last two are new.

| Menu | Tabs |
|---|---|
| Smart Transport Dashboard | dashboard |
| Smart Transport Master | Vehicle · Staff · Shift · Route · Trans. Stops · Pickup Stops List · Assign Stops to Route · Device Setup · Fine Category · Fine Master · **Proposal Type** (new) |
| Smart Vehicle Mgmt | Fuel Log · Inspection · Service Log · Veh. Approval · Veh. Maintenance |
| Smart Trip Management | Driver/Vehicle Roster · Route Scheduler · Daily Trip · Stopage Status Update · Stopage Details · Student Bord Unbord · Trip Incidents · Trip Approve · Notification Log |
| Smart Student Transport Mgmt. | Stundet Transport Allocation · Fee Creation (Invoicing) · Fine Detail · Fee Collection · Fee Log |
| Smart Transport Report | Route Performance · St.Transport Usage · Stop & Locality Analysis · Trip & Discipline · Driver & Attendant · Transport Finance & Leakage · Cost-Maintenance · Management Summary · Student Boarding/Unboarding · Notifications · Universal Transport |
| **Smart Advisor** (new) | All Suggestions · Cost Cutting & Savings · Routes & Capacity · Fleet & Vehicles · Drivers & Crew · Fees & Revenue · Trips & Schedules · Fuel & Maintenance · Safety & Incidents · Parent Communication · Cost Analysis (Leaflet map) · Profitability Advisor |
| **Route Auto Generation** (new) | Auto Generate Route (preview → apply into proposal tables) |

UI copy issues: "Stundet", "Bord Unbord" and "Stopage" (4 occurrences). There are also leftover files: `tab_module/oldcode.html` (5.9 KB, unused) and `tab_module/newfile.blade.php`, which is still rendered by `NewTripController`.

## 3. Smart-only code (what SmartTransport adds)

| Component | Size | What it does |
|---|---|---|
| `Services/Suggestions/SuggestionEngine.php` | 4,352 lines | **68 rules** across compliance (docs, licence, PUC, police verification), capacity (overload, low-student stop, size mismatch, merge candidates), finance (deficit, fare anomaly, fines, reconciliation), operations (late stops, skipped stops, trip variance, peak traffic), fuel/maintenance (mileage, pilferage, replace-vs-repair, premature wear), safety (incident hotspots, high-severity) and parent comms (app adoption, SMS fallback). |
| `Services/LossRecoveryAdvisor.php` | 4,458 lines | Per loss-making route or bus, **26 recovery options**: fill seats, fee recovery, detour, cluster stops, central hub stop, fuel calibration, add stop(s), swap, merge, shift reuse, right-size, route split, tail analysis, two mini-buses, fare, rent, maintenance, subsidy/withdraw, transfer overlapping stop, corridor rebalance, shift load balance, fleet monetisation, walking-zone policy. Includes a "zero-harm guard" and a combined plan builder. |
| `Services/TransportCostAnalysisService.php` | 1,222 lines | Route and vehicle P&L: fuel, maintenance, rent, crew salary, vendor rates, income from allocations, confidence flags. |
| `Services/RouteProposalPlanner.php` | 1,497 lines | Auto route generation for one shift and direction: demand per stop → capacity-aware k-means (farthest-point seeding, 12 iterations) → vehicle assignment → stop ordering → distance, time and fare per stop → financials → persisted to `tpt_proposed_*`. |
| `Services/SmartAdvisorRosterService.php` | 490 lines | On-demand drill-down rows for each suggestion card. |
| `RouteProposalController`, `SmartAdvisorController`, `ProposalTypeController` | 359 / 693 / 276 lines | UI endpoints. |

## 4. Data model (DDL v2.4 + migrations)

37 tables appear in the DDL and 38 `tpt_*` create migrations exist.

- **Operational:** vehicle, personnel, shift, route, pickup_points, pickup_points_route_jnt, driver_route_vehicle_jnt (with a uniqueness trigger), route_scheduler_jnt, trip, trip_stop_detail, trip_incidents, student_route_allocation_jnt, student_boarding_log, attendance_device, driver_attendance(+log), daily_vehicle_inspection, vehicle_fuel, vehicle_maintenance, vehicle_service_request, notification_log.
- **Finance:** student_fee_detail, student_fee_collection, student_fine_detail, fine_master, fine_category, std_student_pay_log.
- **Smart (v2.4):** proposal_type, route_proposal_master, proposed_route, proposed_pickup_points, proposed_pickup_points_route_jnt, proposed_student_route_allocation, proposed_driver_route_vehicle_jnt (migration only), plus `*_history` snapshots for route, pickup_points, pickup_points_route_jnt, student_route_allocation, and driver_route_vehicle_jnt (migration only).

Proposal status enum in the DDL: `Auto_Generated → Proposed → In-Review → Approved | Rejected | Cancelled | Restored`.
