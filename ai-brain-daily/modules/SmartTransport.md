# Module: SmartTransport

Append-only rollup. Newest entries at the bottom.

## 2026-10-21 — DDL v2.4 proposal schema, Proposal Type CRUD, non-destructive route planner, proposals UI, Smart Advisor save

- **Commits:** `3ce42bbdf`, `3d496eab5`, `3a76de3ba`, `e8f1412ae`, `53e31d6a4`, `ec069f54b`, `61e12d88a`, `59e95ea23`, `e07162937`, `2c4a9f06d`, `65b47edad`, `08654a713`, `8d12bae2c`, `1e66f3005`, `9d49761d3`, `160ab85ef`, `878e55ed0`
- **Files:** 38 unique in `Modules/SmartTransport` (+ 16 tenant migrations under `database/migrations/tenant/`)
- **What:**
  - **DDL v2.4 migrations:** aligned `tpt_vehicle`, `tpt_route`, driver-vehicle jnt, route scheduler jnt, driver attendance and `std_student_pay_log`; created 10 new tables `2026_10_21_100001..100010` (`tpt_proposal_type`, `tpt_route_proposal_master`, `tpt_proposed_route`, `tpt_proposed_pickup_points`, pickup-point-route jnt, proposed student allocation, 4 history tables).
  - **Models:** 12 models under `Modules\SmartTransport\Models` (10 new + `Vehicle`/`Route`). Auto-calc `avg_exp_per_km` from fuel/maintenance and `est_exp_per_km` fallbacks.
  - **Proposal Type CRUD:** `ProposalTypeController`, `ProposalTypeRequest`, `TransportProposalTypePolicy`, 6 blades, `ProposalTypeSeeder` (10 system rows, idempotent), tab on Transport Master, routes, permission, breadcrumb.
  - **`RouteProposalPlanner`:** non-destructive, shift-scoped generator writing only proposal tables. Demand from active allocations, 650 m walk zone, 600 m merge, thin-stop removal, capacity-aware clustering from `tpt_vehicle`, merge/split/remove/student changes, dynamic financials (crew salary, fuel, maintenance, vendor rent), `DB::transaction` + retry, guards for every data condition. Route direction is Pickup or Drop only (`tpt_route.pickup_drop` enum); `stop_type`/`transport_use_type` keep `Both`.
  - **Proposals UI:** `RouteProposalController` master list grouped by proposal, shift/route cascading filters, direction badges; detail page Route → Stop → Student accordion with old-vs-new mapping, fares, distances, times, optimisation audit, pagination.
  - **Smart Advisor:** `SmartAdvisorController::saveProposal()` persists selected suggestions into the 4 proposal tables atomically; exact modal-tab-3 stops, linked transferred students, dynamic `est_exp_per_km`; SweetAlert2 UI + compact Save button.
  - **Wiring:** `MenuSyncController` menu item, `config/permissionslist.php`, `config/breadcrumbs.php`, `SeederController` + `TenantDatabaseSeeder` registration.
- **Verified:** tenant `00000000-0000-4000-8000-000000000001` — Pickup #30 = 11 routes / 435 students / 0 warnings; Drop #31 = 12 routes / 435 students / 0 warnings; no null required columns; geometry SRID 4326; `php -l`, Pint, `route:list`, `view:cache` passed.
- **Open:** approval/apply workflow (Phase 3) not built; proposed vehicle assignment computed not persisted; no server-side OSRM (haversine × road factor); 14 plan decisions pending; permission rows may need sync.
- **Status:** Done (committed; approval workflow pending)
- **Report:** `ai-brain-daily/daily/2026-10-21.md`; plan `ai-brain-daily/live/2026-10-21/plan.md`

## 2026-10-22 — Route Proposal Planner cleanup, 1-to-1 Vehicle fare/rating, Driver-Route-Vehicle proposal persistence, cascading filters & pagination

- **Commits:** `a3496c0d9`, `6ec61fba3`, `bd1bfe03f`, `bc942288a`, `b5f7707cd`, `8a384230e`, `33c160b70`, `ab72a5f6d`, `f83f756d5`
- **Files:** 20 unique in `Modules/SmartTransport` (+ 4 tenant migrations, + 3 in `Modules/Transport`)
- **What:**
  - **Auto Route Generation Cleanup:** Completely eliminated artificial route merging, splitting, and leftover load ratio floors (`MIN_ROUTE_LOAD_FLOOR`, `MIN_ROUTE_LOAD_RATIO`) in `RouteProposalPlanner`.
  - **1-to-1 Vehicle Fare Integration:** Stop pickup/drop fares strictly derive 1-to-1 from vehicle average fare rate (`avg_fare_per_km * distance`). Added vehicle rating (3.5–5.0) and facilities checklist (`is_ac`, `is_cctv`, `wifi`, `tv`, `water_bottle`) across CRUD views, requests, models, and migrations (`2026_10_22_100000_add_fare_and_rating_to_tpt_vehicle_table.php`).
  - **Proposed Driver-Route-Vehicle Persistence:** Added DDL migrations and models (`TptProposedDriverRouteVehicleJnt`, `TptDriverRouteVehicleJntHistory`), and persisted assignments during proposal generation.
  - **Proposal View Cleanup & Filtering:** Removed all legacy Old-vs-New comparison artifacts and removed Proposal Type column from the student allocation table in proposal show view. Implemented cascading filters on the Route Proposals tab: **Shift -> Master -> Route**.
  - **Numbered Pagination & Badging:** Implemented client-side numbered pagination with strict 10 records per page limit on both the Auto-Generate Preview modal and Proposal Show view. Added Route Name badges in the preview modal student allocation list.
- **Verified:** Tenant `00000000-0000-4000-8000-000000000001` — `TransportModuleSeeder` seeded 20 routes, 26 buses, 725 students with vehicle fares/ratings/facilities; proposal generation verified; `php -l`, Pint, `view:cache` passed.
- **Open:** Phase 3 (Approval & Apply workflow) to convert approved proposals into live routes/stops.
- **Status:** Done (committed; Phase 3 approval workflow pending)
- **Report:** [daily/2026-10-22.md](../daily/2026-10-22.md)

## 2026-10-23 — Smart Advisor proposal persistence (one master per suggestion, all card kinds), corridor rebalancing & seat fill parity, per-route preview tabs & UI polish

- **Commits:** `4be95bbda`, `acd0e716d`, `4fca870e6`, `89ce9c77a`, `21ea93479`, `c077a3714`
- **Files:** `Modules/SmartTransport/app/Services/SmartAdvisorProposalSaver.php`, `Modules/SmartTransport/app/Http/Controllers/SmartAdvisorController.php`, `Modules/SmartTransport/app/Http/Controllers/RouteProposalController.php`, `Modules/SmartTransport/resources/views/route_proposal/ai_show.blade.php`, `Modules/SmartTransport/resources/views/route_proposal/index.blade.php`, `public/backend/js/smart-advisor-map.js`
- **What:**
  - **Smart Advisor Suggestion Saving:** Split proposal saving into one master per suggestion (`tpt_route_proposal_master`); implemented full persistence for all advisor card types (`detour`, `cluster`, `central_hub`, `merge`, `split`, `small_tail`, `add`, `general`).
  - **Corridor Rebalancing & Seat Fill Parity:** Saved proposal details now mirror the advisor modal without requiring new DB columns. Added donor snapshot with shared-stop live counts and 'Added Here' indicators.
  - **Bug Fixes & UI Enhancements:** Fixed null vehicle crashes (`$targetDvRow->update()`), whole-proposal stop and student total displays on the index list, and implemented per-route tabs on the AI proposal view. Fixed geometry calculations, blocked guards, and merge direction.
- **Verified:** Tenant `00000000-0000-4000-8000-000000000001` — Verified proposal saving from advisor modal across all suggestion types; `php -l` and Pint passed; proposal views render cleanly.
- **Open:** Phase 3 (Proposal Approval & Conversion to Live Routes).
- **Status:** Done (committed; Phase 3 approval workflow pending)
- **Report:** [daily/2026-10-23.md](../daily/2026-10-23.md)
