# 07 — PrimeTransport: build plan (2026-10-23) — PLAN ONLY, nothing built

## 0. Decisions

### Taken by Tarun (2026-10-23)
| # | Decision |
|---|---|
| D1 | New module **`Modules/PrimeTransport`**. **SmartTransport is not touched** and keeps running. |
| D2 | PrimeTransport **extends Transport**. Transport stays the base (masters, trips, fees). **Additive changes inside Transport are allowed** where data is missing. Existing screens keep working the same, and the original create migrations are edited (dev rule). |
| D3 | **Fresh rewrite.** SmartTransport's code is reference only, never copied. |
| D4 | **Own Python runner:** Python + Google OR-Tools, with PrimeTransport's own copy of the SmartTimetable runner/job pattern. SmartTimetable is not touched. |
| D5 | v1 includes **all four feature groups**: Engine + Publish · Advisor + Ledger · What-if + ETA · Ops + Safety. They are built in phases, and v1 = all phases done. |

### Defaults I set (change any of them before Phase 0)
| # | Default | Why |
|---|---|---|
| S1 | Table prefix **`ptr_`** | free (verified against the tenant migrations); short; not `tpt_`, so we never collide with Transport or SmartTransport |
| S2 | Routes `/prime-transport`, names `prime-transport.*`, permissions `tenant.prime-transport.<feature>.<action>` | matches `smart-timetable.*` and the permission naming standard |
| S3 | Central module **PrimeTransport**, routes gated `EnsureTenantHasModule:PrimeTransport`; a tenant also needs Transport | can be sold as a premium add-on |
| S4 | Road distances from **self-hosted OSRM**. If OSRM is down, fall back to straight-line × factor, and every such number gets an **"Estimated"** badge | trust: a number is never silently a guess |
| S4b | **Maps are 100% open source and self-hosted, with no paid map API and no API keys** (Tarun, 2026-10-23). Full stack in §5b | no per-use cost, no vendor lock-in |
| S5 | PrimeTransport **never deletes** anything in `tpt_*`. Publish only inserts, updates or deactivates, and always snapshots first | the lesson from SmartTransport P0-01 |

---

## 1. Architecture

**Layers:**
- **Transport (base)** owns the live network and operations. Its data is the `tpt_*` tables: routes, stops, vehicles, crew, trips, fees and incidents.
- **PrimeTransport (intelligence)** owns plans, the engine, the advisor and its own data in the `ptr_*` tables:
  - plans and scenarios, snapshots, the distance matrix
  - suggestions and the savings ledger, learned speeds
  - student geo, quotes, disruptions, safety scores
- **The Python engine** (`Modules/PrimeTransport/python/`) receives a JSON payload and returns a JSON result. It never touches the database.

**How the layers talk:**

| From | To | How |
|---|---|---|
| Transport | PrimeTransport | Laravel domain events (TripStarted, StopReached, IncidentRaised, AllocationChanged, …), added in T4 |
| PrimeTransport | Transport | READ through Transport's models; WRITE only through the Publish service (snapshot first) |
| PrimeTransport | Python engine | queued job → runner → JSON payload in, JSON result out |

Rules:
1. **One entry point writes to live tables:** `PublishService`. Everything else (engine, what-if, advisor actions, disruption fixes) produces a **plan** that goes through review → publish.
2. **Plans are full copies.** A plan holds its own routes, stops, allocations and assignments in `ptr_plan_*`. Live tables are untouched until publish.
3. **Drift guard.** Every plan stores a hash of the live network it was built from. If Transport, SmartTransport or a human changed live data since then, publish is blocked with "Live network changed — rebase or regenerate". This matters because SmartTransport writes to the same `tpt_*` tables.
4. **Snapshots are self-contained JSON** in `ptr_snapshots`. Rollback still works even if a `tpt_*` row was later hard-deleted by another module.

---

## 2. Additive changes inside Transport (D2)
Each item is small and keeps existing behaviour; I'll show each diff before applying it.

| # | Change | Fixes gap | Touches |
|---|---|---|---|
| T1 | `tpt_shift`: add nullable `pickup_reach_by` (TIME), `drop_depart_at` (TIME), `days_of_week` (SET). Optional fields on the Shift form. | G1 | create migration, Shift model, request, shift form, DDL file |
| T2 | `tpt_vehicle`: add nullable `depot_latitude`, `depot_longitude`, `depot_name`. Optional "Parking location" map picker on the Vehicle form. | G2 | create migration, Vehicle model, request, vehicle form |
| T3 | Stop the Bangalore default: missing coordinates stay **NULL**, the import reports a warning, the stop list shows a "Location missing" badge, and route geometry stays NULL. | G6 | `PickupPointImport`, `RouteImport`, `PickupPoint`/`Route` model hooks, stop list view |
| T4 | **Domain events** (fired only, no behaviour change): `TripStarted`, `StopReached`, `StopLeft`, `TripCompleted`, `IncidentRaised`, `EmergencyFlagged`, `AllocationChanged`, `VehicleUnavailable`, `DriverAbsent`. | G8 | `MobileTripService`, `TripController`, `TripMgmtController`, `StudentAllocationController`, `VehicleMgmtController`, `DriverAttendanceController` |
| T5 | **GPS storage:** give the existing stub models `TptGpsTripLog` and `TptGpsAlerts` real tables (`tpt_gps_trip_log`: vehicle, trip, lat/lng, speed, heading, ts, source app/AIS140; `tpt_gps_alerts`: type panic/overspeed/tamper/geofence, ts, payload). Ingest endpoints live in PrimeTransport. | G4 | 2 create migrations, 2 models |
| T6 | Fix the dead relations: `TptTripIncidents::incidentType/statusMaster` → the real dropdown model or remove; delete `TptFeeCollection` (no table). | G9, G10 | 2 models |
| T7 | **Real parent notification:** `MobileTripService::notify()` fires the T4 event. A PrimeTransport listener sends through the Notification/Automation core and writes the true status (`Sent`/`Failed`/`NotRegistered`) back to `tpt_notification_log`. | G5 | `MobileTripService` |
| T8 | Self-host Leaflet assets (no unpkg) on Transport's map pages. | G11 | 3–4 views |

Not changed in Transport: fees and fares stay manual (G7). PrimeTransport *suggests* fares and shows "typed vs suggested" gaps; it doesn't overwrite them.

---

## 3. PrimeTransport data model (`ptr_*`, ~24 tables)

| Group | Table | Purpose |
|---|---|---|
| Settings | `ptr_settings` | per-school knobs: max ride min (by class band), max walk m, school-arrival buffer, default speed, road factor, objective weights, ledger windows, ETA alert minutes |
| | `ptr_rule_settings` | per rule: enabled, thresholds, priority override |
| Geo | `ptr_distance_matrix` | from_point, to_point, km, minutes, time_band, source (`osrm`/`estimated`), computed_at; unique per pair + band |
| | `ptr_segment_speeds` | learned minutes per stop pair × weekday × time band, sample count, p50/p85 |
| | `ptr_student_geo` | student_id, lat/lng, source (pin/geocode/manual), **consent_at, consent_by**, verified_at |
| Engine | `ptr_engine_runs` | queued/running/done/failed/superseded, kind (generate/whatif/repair/stop-optimise), payload hash, progress %, best-so-far KPIs, log, by/at |
| Plans | `ptr_plans` | type (generated/whatif/advisor/disruption/manual), status `Draft → InReview → Approved → Scheduled → Published → Superseded` / `Rejected` / `RolledBack`, baseline hash, effective date, scenario levers JSON, KPI summary JSON |
| | `ptr_plan_routes` · `ptr_plan_route_stops` · `ptr_plan_allocations` · `ptr_plan_vehicle_assignments` | full proposed network (mirrors the tpt shapes, plus `change_kind`: new/changed/removed/unchanged and a `source_id` that links to the live row) |
| | `ptr_plan_new_stops` | stops the plan wants to create (from the stop optimiser) |
| | `ptr_plan_locks` | lock a route / vehicle / stop / student assignment for regeneration |
| | `ptr_plan_reviews` | per-route accept/reject + remark, approval steps (who, when, decision) |
| | `ptr_snapshots` | full JSON copy of the live network before each publish + row counts + hash; used for rollback |
| Advisor | `ptr_advisor_runs` | nightly / on-demand run, duration, rules run, failures |
| | `ptr_suggestions` | rule_code, category, priority, entity, title/problem/action text, **predicted ₹/km/min**, calculation trace JSON, fingerprint (dedupe), status `open/accepted/dismissed/snoozed/resolved/expired`, owner, due date, snooze_until, linked plan_id |
| | `ptr_suggestion_outcomes` | baseline metrics at acceptance; measured at 30/60/90 days; **actual ₹ saved**; confidence |
| Ops | `ptr_eta_live` | per running trip × upcoming stop: predicted arrival, last update, alert sent flags |
| | `ptr_disruptions` | date, type (vehicle down / driver absent / road closed), affected route, ranked options JSON, chosen option, parents notified count |
| | `ptr_admission_quotes` | enquiry ref, address, lat/lng, nearest stop, walk m, route, seats free, quoted fare, needs-new-stop flag |
| Safety | `ptr_safety_scores` | period, vehicle_id, driver_id, component scores JSON (docs, incidents, overspeed, harsh events, inspections, attendant rules), total |
| | `ptr_safety_rules` | the rule catalogue (female attendant for last girl drop, helper for pre-primary, max driving hours, …), state/board reference text |

---

## 4. The engine (Python + OR-Tools)

**Location:** `Modules/PrimeTransport/python/prime_transport/` with its own `requirements.txt` (ortools, numpy) and pytest suite. **No DB driver** (the same boundary rule as SmartTimetable).

**Payload (built by PHP `PayloadBuilder`):**
- school point(s) and shifts with `pickup_reach_by` / `drop_depart_at` (T1)
- stops with demand per direction (students, class bands)
- vehicles with capacity, depot (T2), ₹/km, fixed monthly cost, availability windows
- the distance/time matrix (§5)
- constraints from `ptr_settings`
- locks, the objective, the time limit, and the baseline plan (for minimal-change mode)

**Model:** capacitated VRP with time windows, as an open route (depot → stops → school for pickup; school → stops → depot for drop).
- **Capacity:** a capacity dimension with a heterogeneous fleet.
- **Ride time:** a time dimension. Each child's ride time is capped by class band (e.g. pre-primary ≤ 35 min, others ≤ 60).
- **Arrival:** school arrival ≤ `pickup_reach_by` − buffer.
- **Optional stops:** disjunctions with penalties. This is how merge and drop of tiny stops gets decided.
- **Locks:** fixed routes, or fixed vehicle-to-route assignments.
- **Multi-shift tiering:** a vehicle is available in shift B only after its shift-A route ends plus a turnaround time.
- **Objectives** (chosen in the UI): fewest vehicles · least km · least ₹ · shortest max ride · **minimal change from current** (penalise moving students who don't need to move).

**Run:**
1. `GeneratePlanJob` (queued) calls `PrimeTransportPythonRunner`.
2. The runner streams progress events to `GenerationProgress` (cache), which the modal polls.
3. A `SolverProcessReaper` kills orphaned runs, and a newer run supersedes an older one.

**Output:** routes, ordered stops, times, loads and unserved stops with reasons. `SolutionAdapter` writes the result to the `ptr_plan_*` tables and computes the KPI diff against the baseline.

**Tests:** pytest with small fixed schools (5 stops, 2 buses → known optimum), property tests (no capacity overflow, no ride-time breach), and a Python-3.14 wheel check (if OR-Tools has no 3.14 wheel, use a 3.12 venv; the binary path comes from config).

---

## 5. Distance service
- **`DistanceMatrixService`** (PHP) fetches only missing or stale pairs from OSRM's `/table` endpoint in batches and stores them in `ptr_distance_matrix`.
- **Time bands:** learned speeds (`ptr_segment_speeds`, §8) override OSRM free-flow minutes when the sample count is ≥ N.
- **Fallback:** if OSRM is unreachable, use haversine × `road_factor` with `source=estimated`. The UI shows the "Estimated" badge, and the plan's KPI header shows "% of distances estimated".
- **OSRM hosting:** a Docker container on the VPS with a regional extract (e.g. Geofabrik western-zone for Gujarat/Maharashtra schools) to keep RAM small. Adding a region is one command. ⚠ Size the VPS RAM before Phase 1 (decision O2).

---

## 5b. Map stack: free, open source, self-hosted (no paid maps)

| Job | Choice | Licence | Hosted where |
|---|---|---|---|
| Draw the map in the browser (routes, stops, side-by-side plan compare, live bus) | **MapLibre GL JS** (vector maps, smooth with hundreds of route lines, built-in side-by-side sync) | BSD-3 | JS/CSS files vendored into `public/vendor/maplibre/`, no CDN |
| Base map (streets, names) | **Protomaps basemap as one `.pmtiles` file**, cut to India (or per region) with the `pmtiles` CLI, built from OpenStreetMap data | data ODbL (attribution "© OpenStreetMap contributors") | a static file on our own VPS/nginx (HTTP range requests); **no tile server to run** |
| Road distances and route lines | **OSRM** (`/table` for the distance matrix, `/route` for drawing the real road path of each route) | BSD-2 | Docker container on our VPS (§5) |
| Address → point (admission quote, student home) | v1: **drop a pin on the map** (no geocoder needed). Optional later: self-hosted **Photon** or **Nominatim** | Apache-2 / GPL-2 (server-side) | own server only if O7 = yes |
| Android apps (parent/admin) | **MapLibre Native** reading the same `.pmtiles` file | BSD | same file |

What we will **not** use in production:
- `tile.openstreetmap.org` (the OSM tile usage policy forbids heavy or app use and can block without notice)
- public `router.project-osrm.org` (demo only)
- public `nominatim.openstreetmap.org` (max 1 request/second, no bulk)
- Google, Mapbox or any other paid key

**Map screens in PrimeTransport:**
- **Plan review:** two synced maps (Live | Proposed). Each route has its own colour, drawn along the real road from OSRM. Stops are sized by number of students. Removed stops are grey; new stops are green.
- **What-if compare:** up to 3 synced maps.
- **Live operations:** bus markers from GPS pings (T5), ETA labels on upcoming stops.
- **Student locations:** consent-gated pins, a walk-radius circle around each stop, uncovered students in red.
- The attribution "© OpenStreetMap contributors" stays visible on every map (licence requirement).

Transport's existing Leaflet pages (T8) keep Leaflet, but load it from our own server and use the same self-hosted basemap. So no page in the product calls a public tile or routing server.

---

## 6. Review → Publish → Rollback (`PublishService`)

1. **Review screen:** two Leaflet maps (live vs plan), a KPI diff (vehicles, km/month, ₹/month, max and average ride, students moved, stops added/removed, routes in loss), and a per-route accept/reject with remark.
2. **Approval chain:** InReview → Approved. Who can approve is set by permission `prime-transport.plan.approve`. The approver can set an **effective date**.
3. **Publish** (immediately, or by the scheduler at 00:05 on the effective date), all in **one DB transaction**:
   1. drift check (baseline hash = current live hash), else stop
   2. snapshot the live network into `ptr_snapshots`
   3. insert new routes, stops, stop-route links and driver/vehicle assignments
   4. update changed ones
   5. **deactivate** (`is_active=0`) removed ones, **never delete**
   6. re-point student allocations (`pickup/drop_route_id`, `stop_id`)
   7. **never touch** trips, stop details, incidents, boarding logs or fees
4. **After commit:** notify affected parents ("from 1 Nov: Route 4, Pal Gam stop, 6:52 AM"), notify crew of new assignments, and write an activity log.
5. **Rollback:** create a plan from a snapshot, then go through the same publish (with the drift check and its own snapshot). Undoing a rollback is therefore possible too.

---

## 7. Smart Advisor + Savings Ledger (fresh design)
- **Rule framework:**
  - Each rule is a class implementing `AdvisorRule` (`code()`, `category()`, `evaluate(AdvisorContext): Finding[]`).
  - A `Finding` carries a predicted impact (₹/km/min), a calculation trace and an optional **action** that builds a plan (merge/split/right-size → `ptr_plans` type `advisor`).
  - Rules are listed in a registry; thresholds come from `ptr_rule_settings`.
- **Context:** `AdvisorContext` preloads everything once per run (routes, loads, costs, trips, fuel, incidents), so rules never query in loops.
- **Runs:** nightly `AdvisorRunJob` per tenant, plus a "Refresh now" button (queued, with a progress toast). The page reads only `ptr_suggestions`, so it opens instantly.
- **Dedupe and lifecycle:** suggestions are deduplicated by fingerprint. A rule that stops firing marks its open suggestion `resolved`. Dismissed and snoozed suggestions don't reappear until snooze ends or the facts change materially.
- **Ledger:** on Accept, store baseline metrics for the entity. `LedgerMeasureJob` measures at 30/60/90 days. The "₹ saved this term" tile sums `actual_saving` (with confidence) and is shown separately from "predicted".
- **Catalogue (written in Phase 0 as `09-RULE-CATALOGUE.md` in this folder):** families are compliance · capacity & loads · route cost & profit · fees & fares (typed vs suggested fare) · trip punctuality · fuel & maintenance · crew · safety · parent comms. Every catalogued rule is built (no deferrals).

---

## 8. What-if + learned ETA + real alerts
- **What-if Lab:**
  - Clone the live baseline into a `whatif` plan, set levers: shift time ± min, remove/add N vehicles, vehicle type swap, fare ₹/km, walking-zone radius, new demand area (pins or CSV), max ride time.
  - Run the engine and compare up to 3 scenarios side by side.
  - Promoting a scenario turns it into a normal plan → review → publish.
- **Learned ETA:**
  - `SpeedLearnJob` (nightly) reads `tpt_trip_stop_detail` (`leaving_time` of stop i → `reaching_time` of stop i+1) and writes `ptr_segment_speeds` by weekday × time band.
  - Outliers are trimmed (p50/p85).
  - Printed stop times in plans use learned speeds where they exist.
- **Live ETA:**
  - On `StopReached`/`StopLeft` (T4), or a GPS ping (T5), recompute the ETA for the remaining stops into `ptr_eta_live`.
  - Send `ApproachingStop` when ETA ≤ X min, and `Delayed` when the delay is > Y min (settings).
  - Status is written back to `tpt_notification_log` (T7).
  - Parent app: new `GET /api/.../prime-transport/eta/{student}` in PrimeTransport's mobile routes.

---

## 9. Ops + Safety
- **Admission quote:**
  - A `QuoteService` + tool page "Check transport for an address": geocode/pin → nearest stops within walk limit → route, seats free on that direction/shift, fare (current stop fare and suggested fare) → needs-new-stop flag. Saved to `ptr_admission_quotes`.
  - The Admission enquiry form embed is an **optional, separate decision (O3)** because it touches the Admission module.
- **Daily disruption re-plan:**
  - On `VehicleUnavailable` / `DriverAbsent`, or manual "Report problem", build ranked options: spare vehicle/driver; nearby route with free seats (engine "repair" mode with everything else locked); split across 2 routes.
  - The chosen option writes a **date-only** override into `tpt_route_scheduler_jnt` (existing table, no permanent change) and notifies affected parents and crew.
  - Absent / one-way students → skip-stop list for the day's trip.
- **Safety & compliance score:**
  - Nightly per vehicle and driver: document validity, incidents (severity-weighted), inspections failed, overspeed/harsh events (GPS, if present), attendance and driving hours, and attendant rules from `ptr_safety_rules`.
  - PDF export for inspections.
  - AIS-140 panic alert (T5 ingest) → immediate incident + escalation notification.
- **Student geo + stop optimiser:**
  - A consent-gated pin capture (staff page + parent app endpoint).
  - The engine's "stop-optimise" mode proposes stops under a max walk distance with safety flags. The result is a plan with `ptr_plan_new_stops`.

---

## 10. Menu, pages, permissions
**Menu "Prime Transport"** (one entry, tabbed pages, following the breadcrumb, search-bar and table-action standards):

| Page | Tabs |
|---|---|
| Command Centre | KPIs (vehicles, km, ₹, utilisation, on-time %), ₹ saved, open alerts, today's disruptions |
| Route Planner | Generate · Runs (live status) · Locks · Settings |
| Plans & Approvals | All plans · Review (map diff) · Scheduled · History & Rollback |
| What-if Lab | Scenarios · Compare |
| Smart Advisor | Suggestions (by family) · My actions · Savings Ledger · Rule settings |
| Live Operations | ETA board · Delays · Disruptions · GPS alerts |
| Safety & Compliance | Scores · Rule breaches · Export |
| Tools | Admission quote · Student locations (consent) · Distance service status |

Permissions (`tenant.prime-transport.*`): `planner`, `plan` (+`review`, `approve`, `publish`, `rollback`), `whatif`, `advisor` (+`refresh`, `act`), `ledger`, `live-ops`, `disruption`, `safety`, `quote`, `student-geo`, `settings`. Default role grants go through the seeder (not migrations; see the role-grant memory).

---

## 11. Phases (v1 = all phases)

| Phase | Deliverables | Exit check | Size (solo) |
|---|---|---|---|
| **0 Foundations** | module scaffold + provider/routes/licence row/menu/permissions; T1–T6, T8; all `ptr_` migrations + models; settings page; OSRM container + `DistanceMatrixService`; Python venv + OR-Tools + runner skeleton; `09-RULE-CATALOGUE.md`; fixture school | `php artisan route:list` clean; matrix fills for a demo tenant; `pytest` green on a 5-stop toy | 1–1.5 wk |
| **1 Engine + Publish** | PayloadBuilder, OR-Tools model, GeneratePlanJob + live status, SolutionAdapter, KPI diff, Review map, approvals, PublishService + snapshots + rollback, drift guard, parent change notices | generate → approve → publish → rollback on a demo tenant leaves trips/incidents untouched (feature test) | 3 wk |
| **2 Advisor + Ledger** | rule framework, all catalogued rules, nightly/refresh jobs, suggestion lifecycle, advisor-action → plan, ledger measurement | page opens < 1 s from stored suggestions; accept → 30-day measure job computes on fixture data | 2–2.5 wk |
| **3 What-if + ETA** | What-if Lab + compare; SpeedLearnJob; ETA live; T7 real notifications; parent ETA API | scenario "shift +20 min" shows bus reuse; a simulated trip sends Approaching/Delayed with true status | 2 wk |
| **4 Ops + Safety** | admission quote; disruption re-plan; safety score + rules + PDF; GPS/AIS-140 ingest; student geo + stop optimiser | vehicle-down drill produces ranked options and a one-day override; safety PDF exports | 2–2.5 wk |

**Total ≈ 10–11.5 weeks solo.** This is longer than the 4–6 week go-live window, so decision O5 below matters.

Testing throughout: pytest for the engine; PHP feature tests for publish/rollback, ledger maths and the drift guard; no "testing later" for money or publish paths.

---

## 12. Risks
1. **OR-Tools on Python 3.14:** the wheel may not exist yet. Mitigation: a dedicated 3.12 venv; the binary comes from config.
2. **OSRM RAM on the VPS:** preprocessing a big extract needs much more RAM than serving it. Mitigation: a regional extract, preprocessed off-box, with only the serving container on the VPS.
3. **Shared `tpt_*` tables with SmartTransport:** SmartTransport can still change or wipe live data. Mitigation: the drift guard, self-contained snapshots, and publish never deletes.
4. **Data quality:** stops without coordinates (T3 makes them visible), and manual fares (PrimeTransport flags gaps, doesn't overwrite).
5. **Privacy:** student home pins need consent, a role-restricted view and a retention policy.
6. **Scope:** five feature groups in v1. Mitigation: each phase ships behind its own permission, so finished phases can be enabled early.

---

## 13. Open decisions (needed before Phase 0 starts)
| # | Question | My recommendation |
|---|---|---|
| O1 | Table prefix `ptr_` and route prefix `prime-transport`: OK? | yes |
| O2 | ~~Distance source~~ **Settled 2026-10-23: open source only.** Self-hosted OSRM + Protomaps `.pmtiles` + MapLibre (§5b). Remaining question: which region extract(s) first (all India vs the states our tenants are in)? | states of current tenants first |
| O7 | Do we need a typed-address search in v1 (self-hosted Photon/Nominatim, extra disk/RAM), or is pin-drop enough? | pin-drop in v1, geocoder later |
| O3 | May the Admission enquiry form get an embedded "Transport quote" widget (a small additive change in Admission)? | yes, Phase 4 |
| O4 | Who approves plans: transport incharge → principal (2-step), or 1-step? | 2-step, configurable |
| O5 | Go-live: ship phases 0–1 inside the current go-live window and the rest after, or hold PrimeTransport until all phases are done? | ship phase by phase behind permissions |
| O6 | Long-term: once PrimeTransport is live, is SmartTransport retired (menu hidden for new tenants)? | decide after Phase 2 |
