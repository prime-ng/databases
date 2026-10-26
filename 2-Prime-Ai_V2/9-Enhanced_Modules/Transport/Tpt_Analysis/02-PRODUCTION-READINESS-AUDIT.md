# 02 — Production Readiness Audit (2026-10-23)

This is a static audit. Severity: **P0** = data loss or security, block go-live · **P1** = wrong results or broken feature · **P2** = hardening · **P3** = hygiene.
Paths are relative to `prime_ai/Modules/SmartTransport/` unless they say otherwise. "Both" means the issue also exists in `Modules/Transport`.

## Verdict
**SmartTransport: NOT READY.** Two P0s are open, and the proposal workflow is only half built.
**Transport: conditionally ready** for its operational CRUD. It shares P1-04 (no tenancy in the expiry command), P2-01 (exception leaks), P2-05 (no tests) and the DDL drift. It inherits the P0-01 blast radius, because SmartTransport writes to the same tables.

---

## P0

### P0-01 One-click wipe of every route, trip and incident
`app/Http/Controllers/PickupPointController.php:611-652` (`autoGenerateAllRoutes`, route `POST smarttransport/pickup-points/auto-generate-routes`, gate `pickup-point.sync`)

Inside one transaction it does all of the following:
- sets `pickup_route_id`/`drop_route_id = NULL` on **every** `tpt_student_route_allocation_jnt` row
- hard-deletes every `tpt_trip`, `tpt_trip_stop_detail` and **`tpt_trip_incidents`** row
- deletes every `tpt_route_scheduler_jnt` row
- `forceDelete()`s every route, route-stop and driver/vehicle assignment

It then rebuilds routes but **never re-links students**, so every student is left without a route.
- **Shared blast radius:** both modules use the same `tpt_*` tables, so this also wipes Transport's data.
- **Safety record loss:** incident records are safety and compliance history, and they are destroyed.
- **No button calls it today.** The UI uses the non-destructive `auto-generate-proposal`. The route is still live for anyone holding `pickup-point.sync` plus a CSRF token.

**Fix:** delete the endpoint and the route (generation must go through proposals only). If a "reset" is ever needed, make it a proposal of type `Route_Remove`, or a super-admin artisan command that takes a backup first.

### P0-02 Approved proposals can never reach live routes (half-built lifecycle)
- **What the DDL defines:** `tpt_route_history.status ENUM('Auto_Generated','Proposed','In-Review','Approved','Rejected','Cancelled','Restored')`, review/approve/restore columns, and five `*_history` snapshot tables. The permission list defines `route-proposal.{generate,review,approve,reject,restore}`.
- **What the code has:** only `index/show/preview/apply/generate/stopStudents` in `RouteProposalController` and `saveProposal` in `SmartAdvisorController`. There is no review, approve, reject, restore or promote step.
- **What the history models do:** `TptRouteHistory`, `TptPickupPointHistory`, `TptPickupPointRouteHistory`, `TptStudentRouteAllocationHistory` and `TptDriverRouteVehicleJntHistory` are referenced only by other models. Nothing writes to them.

**Effect:** "Route Auto Generation" and the Advisor's "Save as proposal" produce rows nobody can act on. This is the gap that most separates the module from SmartTimetable (generate → review → publish → snapshot/restore).

---

## P1

### P1-01 Smart Advisor computes everything inside the page request
`app/Http/Controllers/SmartAdvisorController.php:41-80`
- `set_time_limit(180)`, then 68 rules, route cost, bus cost and work-days are computed inline, each wrapped in a 10-minute `Cache::remember` keyed by tenant.
- The first visitor after cache expiry waits for the full computation. A slow tenant can hit the 180 s limit, and nginx/php-fpm timeouts are usually lower.
- The cache is never invalidated when data changes, so cards can stay stale for 10 minutes after a fix.
- `/smart-advisor/map` uses a **45-second** cache for the same keys, so the two pages fight over the cache.

**Fix:** a queued job that writes a snapshot, as in SmartTimetable's generation and live-status pattern (see 03).

### P1-02 Route planner: wrong distances, wrong stop order
`app/Services/RouteProposalPlanner.php`
1. **Distances are guessed.** Distances are haversine × `ROAD_FACTOR 1.30` (L39), and times assume a constant `AVG_SPEED_KPH 25` (L41). There is no road network, so fares are built on a guess (`leg_fare = straight-line km × fare/km`).
2. **Stops are not routed.** Stop order is a **radial sort by distance from school** (L603), not a route. Two stops on opposite sides of a cluster at similar radius get visited back-to-back, which makes zig-zag routes. The better `orderStopsByProximity()` (L919) is **dead code**, never called. `nearestIndex()` and `chainKm()` look unused as well.
3. **Restarts can drop stops.** Growing the route count restarts clustering (L680), but the restart consumes one of the 12 iterations (L645). If a restart happens on the last pass, the loop exits with partially filled clusters. `applyPlan` then throws "Only X of Y student allocations could be placed", so the plan fails without explanation for larger or heterogeneous fleets.
4. **Missing constraints:** no maximum ride time, no school arrival window, no deadhead from depot or driver home, and no check that a vehicle is not double-booked across shifts whose times overlap (each shift is planned independently).
5. **Pickup and drop costs are inconsistent.** The pickup leg starts at the first stop with no deadhead. The drop leg adds the return-to-school leg, so pickup and drop costs are not comparable.

### P1-03 Missing coordinates silently become Bangalore
- `app/Imports/PickupPointImport.php:70-71` defaults blank lat/lng to `12.9716, 77.5946`.
- `app/Models/PickupPoint.php` (saving hook) does the same for `location`.
- `PickupPointController.php:676` uses a Bangalore LINESTRING as the "empty" route geometry.

For a Surat or Delhi school, the planner then treats such a stop as real and ~1,000+ km away. That distorts clusters, fares and every cost rule. A missing coordinate must stay NULL and be flagged as "needs geocoding", which the planner already handles by skipping it.

### P1-04 Daily expiry commands run without a tenant (Both)
`app/Console/CheckTransportExpiries.php` is scheduled daily by **both** providers (`SmartTransportServiceProvider.php:153`, `TransportServiceProvider.php:149`).
- It queries `Vehicle`/personnel without initialising tenancy, so it hits the central DB.
- It only writes to the log; nobody is notified.

**Fix:** loop over tenants (`tenancy()->runForMultiple`), keep one command, and send a notification through the Automation core.

### P1-05 Routing calls go to the public OSRM demo server
`resources/views/pickup_point/{create,edit,pickup_point}.blade.php` and `smart-advisor/tabs/cost-analysis.blade.php:1175` call `https://router.project-osrm.org` from the browser.
- The demo server's policy forbids heavy or commercial use and gives no guarantees, and access can be withdrawn without notice.
- Leaflet is also loaded from unpkg on several pages.

**Fix:** self-host OSRM on the VPS (an India extract is a few GB), or use a paid matrix API through a server-side proxy with caching.

### P1-06 Two forks, 155 diverged files (Both)
Every bug fix has to be made twice and usually isn't (see 01 §1). With "both ship", this is a permanent correctness risk.
**Fix (recommended):** turn SmartTransport into an add-on that **depends on** Transport:
- it keeps only the smart controllers, services, views and proposal/history models
- it reuses Transport's models and CRUD
- it adds its own licence key (`EnsureTenantHasModule:SmartTransport`)

This removes ~300 duplicated files. Until then, freeze feature work on the duplicated CRUD in one of the two.

### P1-07 No separate licence key
`app/Providers/RouteServiceProvider.php:47` gates on `:Transport`. Every tenant that has Transport gets SmartTransport for free and sees both menus. It cannot be sold as a premium tier.

---

## P2

| # | Finding | Where |
|---|---|---|
| P2-01 | `$e->getMessage()` returned to the browser in ~154 places (138 in Transport). This leaks SQL and constraint text to users. | e.g. `RouteProposalController.php:192,199,224,231`, `PickupPointController.php` `autoGenerate*` |
| P2-02 | User FKs use `ON DELETE CASCADE` (11 in the 2026-10-21 proposal migrations). Deleting a user deletes the proposals and history they created or reviewed. Use `SET NULL` / `RESTRICT`. | `database/migrations/tenant/2026_10_21_1000*` |
| P2-03 | Raw WKT built by string interpolation (`ST_GeomFromText('POINT({$lng} {$lat})')`). The values are cast to float in most paths, but the model hook uses raw attributes. Use bindings: `DB::raw('ST_GeomFromText(?, 4326)')` via `selectRaw`/`ST_SRID(POINT(?,?),4326)`. | `Models/PickupPoint.php`, `Models/TptProposedPickupPoint.php:51`, `PickupPointRouteController.php:466,475`, `PickupPointController.php:675` |
| P2-04 | Suggestion thresholds are hard-coded in the `SuggestionEngine` constructor (expiry 30 d, merge distance 1000 m, replace-vs-repair ₹1,00,000, etc.) and there is no settings UI per school. | `SuggestionEngine.php:154-176` |
| P2-05 | Zero automated tests in both modules, for 150K+ lines including money calculations (fare, P&L, loss recovery). | `tests/` |
| P2-06 | `$request->all()` used 13 times per module (mass-assignment surface). | grep `request->all()` |
| P2-07 | `SmartTransport/routes/mobile_api.php` and `Mobile*Service` are dead copies. The app uses Transport's. Delete them, or decide which one the app uses. | `routes/mobile_api.php` |
| P2-08 | DDL file is stale. The header says **v2.3** in a v2.4 file. It references `usr_users` 8× (the tenant table is `sys_users`). It lacks `tpt_proposed_driver_route_vehicle_jnt` and `tpt_driver_route_vehicle_jnt_history`, which exist as migrations. A 2026-10-22 `add_proposal_columns_…` alter migration exists, against the dev rule "edit the create migration". | `pgdatabase/.../Transport_DDL_v2.4.sql`, `database/migrations/tenant/2026_10_22_110000_*` |

## P3
- 18 `console.log` in views per module; a commented `// dd($vehicle)` in `VehicleController.php:54`.
- UI typos: "Stundet", "Bord Unbord", "Stopage".
- Dead files: `tab_module/oldcode.html`.
- The menu duplicates names: 6 "Smart X" entries that mirror the Transport entries. Users won't know which one to use (it resolves with P1-06).

## Not covered (needs a follow-up)
- Render-time 500s (unknown route names, missing eager loads) need a live page sweep.
- Unrouted public controller methods (per the controller-alignment rule they get `abort(403)`).
- Tenant data volumes, to size the background job.
