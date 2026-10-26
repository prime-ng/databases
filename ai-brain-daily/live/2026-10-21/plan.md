AI Brain loaded: 2026-10-21, 13 live entries, last report 2026-10-20.
Application code, DB, and UI remain unchanged. Below is the detailed plan, split into the two phases you asked for.
1. Executive summary
Phase 1 — tpt_proposal_type CRUD tab
Add a new Proposal Type tab on Transport Master, with full CRUD, system-record protection, and an idempotent seeder for the 10 default operation types.
Phase 2 — Proposal-based route generation
Replace the destructive auto-generate flow with a shift-scoped generator that writes only to proposal tables. Live routes, stops, allocations, trips, and schedulers are not touched until a proposal is approved.
Phase 3 — Review / approve / reject / apply
Add the proposal dashboard, detail view, map, review/approve/reject actions, and apply-to-live + history workflow.
The critical schema blocker is tpt_proposed_student_route_allocation: its new_* FKs currently point to live tpt_route / tpt_pickup_points, so proposed route/stop IDs cannot be stored. This must be decided before Phase 2 can write allocation proposals.
2. What exists today
2.1 Proposal type
- Table/model already exist:
- database/migrations/tenant/2026_10_21_100001_create_tpt_proposal_type_table.php
- Modules/SmartTransport/app/Models/TptProposalType.php
- Fields: id (tinyIncrements), code, name, description, is_active, is_system, timestamps, soft deletes.
- Unique indexes on code and name.
- TptProposalType already has SoftDeletes, scopeActive, and relationships to proposal/history tables.
- No CRUD controller, request, views, routes, permissions, or seeder yet.
2.2 Transport Master tabs
- Modules/SmartTransport/app/Http/Controllers/TransportMasterController.php
- $availableTabs currently: vehicle, staff, shift, route, trans_stops, trans_stops_list, assign_stops, device_setup, fine_category, fine_master.
- Each tab has a private query method and paginated data passed to the view.
- Modules/SmartTransport/resources/views/tab_module/transportmaster.blade.php
- Tab array + @include per tab.
- Existing CRUD pattern to mirror: Fine Category
- FineCategoryController, FineCategoryRequest, TptFineCategory
- resources/views/fine-category/{index,create,edit,show,trash}.blade.php
- Routes at Modules/SmartTransport/routes/web.php:289-293
- Permissions at config/permissionslist.php:851
- Controller uses direct Gate::authorize(...); a TransportFineCategoryPolicy exists but is not registered in SmartTransportServiceProvider.
2.3 Current auto-generate flow
PickupPointController::autoGenerateAllRoutes at Modules/SmartTransport/app/Http/Controllers/PickupPointController.php:610.
It currently:
1. Loads all active shifts — no shift selection.
2. Nulls tpt_student_route_allocation_jnt.pickup_route_id / drop_route_id.
3. Deletes tpt_trip_stop_detail, tpt_trip_incidents, tpt_trip, tpt_route_scheduler_jnt.
4. Force-deletes tpt_pickup_points_route_jnt, tpt_driver_route_vehicle_jnt, tpt_route.
5. Recreates live routes, live stop junctions, and live vehicle assignments.
6. Never writes to proposal tables.
Button JS is at Modules/SmartTransport/resources/views/pickup_point/index.blade.php:271; warning text says “force delete existing routes”.
2.4 Services available for reuse
- Modules/SmartTransport/app/Services/LossRecoveryAdvisor.php
- Public: workDaysPerMonth, tripsPerDay, getFleetMiniVanCapacityRange, getFleetCostThresholds, vanEconomics (private), etc.
- Private cost helpers: fleetMedianRoadFactor, roadFactorOfRoute, fleetVariableRate, costPerKmOfRoute, optMerge, optRouteSplit, optClusterStops, optAddStop, optAddMultipleStops, optTransferOverlappingStop, optCorridorRebalance, zeroHarmGuard.
- Modules/SmartTransport/app/Services/TransportCostAnalysisService.php
- getRouteCostAnalysis() returns per-route actual income/expense/student counts/cost per km.
- getVehicleCostAnalysis() returns vehicle-level cost data.
- Modules/SmartTransport/app/Services/Suggestions/SuggestionEngine.php
- Unallocated/empty stop detection and merge/split financial logic.
- Frontend already uses Leaflet + OSRM in pickup_point/pickup_point.blade.php and smart-advisor/route-map.blade.php.
- No Google Maps API integration or API key exists; only Google Maps links.
3. Schema review and inconsistencies
The migrations already corrected several invalid parts of Transport_DDL_v2.4.sql. Remaining issues and decisions:
#	Issue	Current state
1	tpt_route_proposal_master.academic_year_id FK to acad_academic_years	Migration correctly references sch_org_academic_sessions_jnt
2	in_review_by / approve_reject_by FK to usr_users	Migration correctly references sys_users
3	tpt_proposed_pickup_points_route_jnt uses route_id / pickup_point_id in v2.4	Migration correctly uses proposed_route_id / proposed_pickup_point_id and FKs to proposed tables
4	tpt_proposed_student_route_allocation FKs on non-existent old_route_id, old_pickup_stop_id, etc.	Migration omitted those invalid FKs
5	tpt_proposed_student_route_allocation.new_* FKs point to live tpt_route / tpt_pickup_points	Migration still points to live tables
6	tpt_route_proposal_master has no status	Status lives only on child rows
7	tpt_proposed_pickup_points has no status	Status lives on route/junction rows
8	No proposed vehicle/driver assignment table	v2.4 has none
9	tpt_proposed_route.route_geometry spatial index in v2.4	Migration removed it because column is nullable
10	tpt_proposed_pickup_points.location NOT NULL + spatial index	Valid
11	History tables use live route_id / pickup_point_id	Correct, because history is written after live rows exist
12	tpt_proposed_pickup_points model defaults lat/lng to Bengaluru if null	Model boot fills 77.5946 / 12.9716
13	tpt_proposal_type unique code / name includes soft-deleted rows	DB unique indexes are not partial
4. Phase 1 — Proposal Type CRUD
4.1 UI
Add a new tab:
- Tab id: proposal_type
- Label: Proposal Type
- Icon: fa-solid fa-list-check (or similar existing icon style)
- Permission: tenant.smarttransport.proposal-type.viewAny
- Position: after fine_master (last tab) to minimize disruption.
Files:
- Modules/SmartTransport/resources/views/tab_module/transportmaster.blade.php
- Add tab definition.
- Add @can('tenant.smarttransport.proposal-type.viewAny') @include('smarttransport::proposal-type.index') @endcan.
- Modules/SmartTransport/resources/views/proposal-type/index.blade.php
- Mirror fine-category/index.blade.php.
- Search by code / name.
- Status filter: All / Active / Inactive.
- Create button.
- Table columns: Code, Name, Description, System, Status, Action.
- System rows show a lock badge and no edit/delete/status switch.
- Pagination uses proposal_type_page.
- create.blade.php, edit.blade.php, show.blade.php, trash.blade.php
- Mirror Fine Category views.
- Edit page must reject system records server-side; UI also hides the link.
4.2 Controller
New: Modules/SmartTransport/app/Http/Controllers/ProposalTypeController.php
Mirror FineCategoryController exactly:
- index — list + search/status filter, paginate 10.
- create — form.
- store — validate, create, activityLog, redirect to smarttransport.transport-master.index with tab => proposal_type.
- show — view.
- edit — block system records.
- update — block system records.
- destroy — soft delete; block system records.
- trashed — only non-system records should appear; block force delete of system.
- restore — restore non-system; system restore allowed only as recovery.
- forceDelete — block system records permanently.
- toggleStatus — block system records.
System protection:
abort_if($record->is_system, 403, 'System proposal types cannot be modified or deleted.');
store must force is_system = false; is_system must never be accepted from the request.
Use DB::beginTransaction() / DB::commit() / DB::rollBack() and Log::error like FineCategoryController.
4.3 Form request
New: Modules/SmartTransport/app/Http/Requests/ProposalTypeRequest.php
Rules:
- code: required, string, max 20, regex ^[A-Za-z][A-Za-z0-9_]*$, unique on tpt_proposal_type.code ignoring current record.
- name: required, string, max 200, unique on tpt_proposal_type.name ignoring current record.
- description: nullable, string, max 500.
- is_active: boolean.
prepareForValidation() merges is_active default true. is_system is not in the rules.
authorize() checks create on POST and update otherwise, mirroring FineCategoryRequest.
4.4 Routes
Add near fine-category routes in Modules/SmartTransport/routes/web.php:
Route::resource('proposal-type', ProposalTypeController::class);
Route::get('/proposal-type/trash/view', [ProposalTypeController::class, 'trashed'])->name('proposal-type.trashed');
Route::get('/proposal-type/{id}/restore', [ProposalTypeController::class, 'restore'])->name('proposal-type.restore');
Route::delete('/proposal-type/{id}/force-delete', [ProposalTypeController::class, 'forceDelete'])->name('proposal-type.forceDelete');
Route::post('/proposal-type/{id}/toggle-status', [ProposalTypeController::class, 'toggleStatus'])->name('proposal-type.toggleStatus');
Resulting names: smarttransport.proposal-type.*.
4.5 Permissions
Add to config/permissionslist.php in the SmartTransport block:
'smarttransport.proposal-type' => $crud,
Resulting permission names:
- tenant.smarttransport.proposal-type.viewAny
- tenant.smarttransport.proposal-type.view
- tenant.smarttransport.proposal-type.create
- tenant.smarttransport.proposal-type.update
- tenant.smarttransport.proposal-type.delete
- tenant.smarttransport.proposal-type.restore
- tenant.smarttransport.proposal-type.forceDelete
Add 'tenant.smarttransport.proposal-type.viewAny' to the Gate::any([...]) list in TransportMasterController::index.
Deployment note: adding a permission key requires re-running the tenant permission seeder (TenantRolePermissionSeeder) so the permission rows exist in each tenant DB. Existing transport roles already auto-include smarttransport.* defaults.
4.6 Policy
New: Modules/SmartTransport/app/Policies/TransportProposalTypePolicy.php
Mirror TransportFineCategoryPolicy, but also block system records in update, delete, and forceDelete:
public function update(User $user, TptProposalType $type): bool
{
    return ! $type->is_system && $user->can('tenant.smarttransport.proposal-type.update');
}
Register it in SmartTransportServiceProvider::registerPolicies():
Gate::policy(TptProposalType::class, TransportProposalTypePolicy::class);
The controller still uses direct Gate::authorize(...) like FineCategoryController; the policy is for model-level checks and future @can.
4.7 Seeder
New: Modules/SmartTransport/database/seeders/ProposalTypeSeeder.php
Seed exactly these 10 system rows:
Code	Name
Stopage_Add	Stopage Add
Stopage_Remove	Stopage Remove
Route_New	Route New
Route_Remove	Route Remove
Student_Add	Student Add
Student_Remove	Student Remove
Stopage_Merge	Stopage Merge
Stopage_Split	Stopage Split
Route_Merge	Route Merge
Route_Split	Route Split
Each row: is_system = true, is_active = true, short description.
Idempotent logic:
$row = TptProposalType::withTrashed()->firstOrNew(['code' => $code]);
$row->fill([... 'is_system' => true, 'is_active' => true]);
$row->deleted_at = null; // or restore() if trashed
$row->save();
No duplicates on repeat. System rows are restored if someone trashed them in the DB.
Call it from SmartTransportDatabaseSeeder::run():
$this->call([ProposalTypeSeeder::class]);
Then add SmartTransportDatabaseSeeder::class to database/seeders/TenantDatabaseSeeder.php after LibraryDatabaseSeeder::class (around line 180).
Do not run seeders now; this is part of implementation.
4.8 Tab query integration
In TransportMasterController:
- Import TptProposalType.
- Add proposal_type to $availableTabs.
- Add gate 'tenant.smarttransport.proposal-type.viewAny'.
- Add private proposalTypesQuery(Request $request):
$query = TptProposalType::query();
if ($request->tab === 'proposal_type') {
    if ($request->filled('search')) {
        $search = trim($request->search);
        $query->where(fn ($q) => $q
            ->where('code', 'like', "%{$search}%")
            ->orWhere('name', 'like', "%{$search}%"));
    }
    if (isset($request->status)) {
        $query->where('is_active', $request->status);
    }
}
return $query->orderByDesc('is_system')->orderBy('code');
- Pass 'proposalTypes' => $this->proposalTypesQuery(...)->paginate(10, ['*'], 'proposal_type_page')->withQueryString().
4.9 Phase 1 verification
- php -l on all new/modified PHP files.
- php artisan route:list --name=smarttransport.proposal-type.
- Seeder twice; assert exactly 10 rows, no duplicates.
- CRUD smoke:
- Create custom type.
- Edit custom type.
- Toggle custom type status.
- Soft delete, restore, force delete.
- System type: edit/update/delete/toggle/force delete all return 403; UI hides controls.
- Tab visible only with proposal-type.viewAny.
- Existing Transport Master tabs unaffected.
5. Phase 2 — Proposal-based auto generation
5.1 Target flow
1. User opens Transport Master → Trans. Stops tab.
2. Clicks Auto Generate Routes.
3. Modal requires Shift selection (active shifts only). Optional checkboxes:
- Include Pickup / Drop (default both).
- Evaluate merges (default on).
- Evaluate splits (default on, conservative).
- Include empty stops (default off).
4. Submit shift_id + options.
5. Controller validates:
- Active shift exists.
- Current academic session exists.
- Required proposal type rows exist.
6. RouteProposalService builds a proposal:
- One tpt_route_proposal_master row for the selected shift.
- tpt_proposed_pickup_points for stops used.
- tpt_proposed_route for proposed routes.
- tpt_proposed_pickup_points_route_jnt for stop order/distance/time/fare.
- tpt_proposed_student_route_allocation only if schema decision #5 is approved.
7. Response returns summary:
- Proposed routes count.
- Stops covered / excluded.
- Students covered / unserved.
- Estimated cost and estimated savings.
- Merge/split candidates.
- Warnings (missing coordinates, capacity shortage, missing fares, missing session).
8. Live tables are untouched.
5.2 What must be removed
In autoGenerateAllRoutes, remove all live destructive code:
- DB::table('tpt_student_route_allocation_jnt')->update([...])
- DB::table('tpt_trip_stop_detail')->whereIn(...)->delete()
- DB::table('tpt_trip_incidents')->whereIn(...)->delete()
- DB::table('tpt_trip')->whereIn(...)->delete()
- DB::table('tpt_route_scheduler_jnt')->whereIn(...)->delete()
- PickupPointRoute::withTrashed()->forceDelete()
- DriverRouteVehicleJnt::withTrashed()->forceDelete()
- Route::withTrashed()->forceDelete()
- Route::create(...)
- PickupPointRoute::create(...)
- DriverRouteVehicleJnt::create(...)
Keep the planning logic (buildRoutePlan, assembleRoute, orderStopsByProximity, haversineDistance, lineStringFromPath, schoolOrigin) but move/adapt it into RouteProposalService. The controller becomes validation + service call + JSON response.
5.3 Shift-scoped generation
- Current method loads all active shifts. Replace with:
- shift_id required.
- Rule::exists('tpt_shift', 'id')->where('is_active', 1).
- One master per generation run for that shift.
- Generate both directions by default, or only selected directions.
- Do not generate for other shifts.
5.4 Master row values
tpt_route_proposal_master:
Field	Value
academic_year_id	sch_org_academic_sessions_jnt.id where is_current = 1
shift_id	selected shift
proposal_date	now()
proposal_type	Auto_Generated
created_at	now()
created_by	auth()->id()
If no current academic session: return 422 with a clear message. Do not guess.
5.5 Proposal type resolution
Resolve once per run from tpt_proposal_type by code:
- Route_New, Route_Merge, Route_Split, Route_Remove
- Stopage_Add, Stopage_Merge, Stopage_Split
- Student_Add, Student_Remove
If any required code is missing: 422 “Proposal types are not seeded. Run ProposalTypeSeeder.”
Never hardcode numeric IDs.
5.6 Demand model
Use existing data only; do not invent a new eligibility table.
- Active demand: TptStudentAllocationJnt::active() rows with valid pickup_stop_id / drop_stop_id.
- Count distinct students per stop per direction.
- transport_use_type = Both counts in both Pickup and Drop.
- Lost-service demand: active allocations whose route/stop is null, inactive, or deleted. Map to the stop if the stop is still active; otherwise report as unplaceable.
- Zero-demand stops: excluded by default; optionally included if include_empty_stops is checked.
- Unallocated eligible students: only if a reliable opt-in source exists. If not, do not invent one; report this as a data gap.
5.7 Routing algorithm
Step 1 — Build stop demand list
For each active stop in the shift/direction:
- id, code, name, latitude, longitude
- students (active demand)
- lost_service_students
- existing_route_ids
- existing_ordinal
Skip stops missing coordinates and report them.
Step 2 — Geographic/direction clustering
Use the existing 2.5 km radius heuristic as the baseline, with improvements:
- Compute bearing from school for each stop.
- Split stops into directional sectors (e.g., 8 sectors). Do not mix opposite directions unless a merge is clearly beneficial.
- Seed each cluster with the farthest unassigned stop (not nearest), so remote stops are covered.
- Grow the cluster by nearest-neighbor within the radius.
- Respect capacity:
- Target Vehicle.capacity.
- Hard limit Vehicle.max_capacity only if the existing setting allow_extra_student_in_vehicale_beyond_capacity is enabled.
- If fleet is insufficient, do not silently reuse vehicles. Generate proposals and flag “vehicle shortage”; reviewer assigns later.
Step 3 — Stop sequencing
- Pickup: school → nearest → farthest.
- Drop: school → farthest → nearest (reverse of pickup), because the bus leaves school first.
- Improve with 2-opt to reduce total distance.
- Compute leg distances and cumulative distance/time.
Step 4 — Road distance, time, geometry
Existing frontend uses OSRM; there is no server-side routing service. Plan:
- Add Modules/SmartTransport/app/Services/RoadRoutingService.php:
- route(array $points): array calls OSRM route/v1/driving/{lon,lat;...}?overview=full&geometries=geojson.
- Returns distance_km, duration_min, geometry_wkt.
- Cache by ordered waypoint hash for 1 day.
- Timeout 5s; on failure fall back to haversine × fleet median road factor.
- Fallback time: distance / 25 km/h + 1 minute dwell per stop (current formula).
- Store route_geometry as LINESTRING WKT; no spatial index.
- Use OSRM leg distances for stop-level total_distance when available; otherwise cumulative haversine.
Step 5 — Time semantics
Use integer minutes, as the schema requires.
- estimated_time = minutes from school to stop.
- arrival_time / departure_time = clock minutes since midnight.
- Pickup:
- arrival_time = shift default_start_time − estimated_time − dwell.
- departure_time = arrival_time + dwell.
- Drop:
- arrival_time = shift default_end_time + estimated_time.
- departure_time = arrival_time + dwell.
- If shift times are missing: use 0 and add a warning.
- Do not set arrival_time = estimated_time like the current code; that is not a clock time.
Step 6 — Vehicle matching
- Sort vehicles by capacity descending.
- Match largest vehicle to largest demand cluster.
- Compute utilization and flag over-capacity.
- Do not persist vehicle assignment in Phase 2 unless decision #8 approves a new table.
- Show matched vehicle in the review UI.
- On approval, create tpt_driver_route_vehicle_jnt using the matched/selected vehicle.
Step 7 — Merge evaluation
For each pair of existing routes in the same shift/direction, and for nearby new clusters:
- Combined students ≤ survivor vehicle hard capacity.
- Combined route time within shift window.
- Nearest inter-route stop distance ≤ threshold (e.g., 3.5 km) or clear corridor overlap.
- Compute merged route distance/time.
- Compare current cost from TransportCostAnalysisService::getRouteCostAnalysis() vs estimated merged cost.
- Propose Route_Merge only if:
- Monthly saving > 0 (recommended minimum ₹500/month to avoid noise).
- zeroHarmGuard passes: no affected route turns loss-making, no capacity violation.
- The proposed merged route contains all stops; each junction row keeps old_route_id so the source route is traceable.
- Source routes are not modified until approval.
Step 8 — Split evaluation
For existing routes with high utilization and a low-demand tail:
- Use LossRecoveryAdvisor::vanEconomics() logic to size a feeder van.
- Build two proposed routes:
- Big bus route for the main corridor.
- Feeder van route for the tail.
- Propose Route_Split only if:
- Capacity and time are valid.
- Estimated saving > 0.
- Zero-harm guard passes.
- If not viable, report as “split not recommended” and do not create a proposal.
- If split logic becomes too large for Phase 2, defer to Phase 3; merge is the priority.
Step 9 — Removal evaluation
- Routes with zero active demand and no lost-service demand.
- Recommended: report only in Phase 2; do not auto-propose removal.
- If the user explicitly enables “propose route removal”, create a Route_Remove proposed route with metadata and no junction rows; approval deactivates the live route.
Step 10 — Coverage audit
- Eligible students = active allocations + lost-service allocations.
- Covered = students whose stop is included in a proposed route.
- Unserved = capacity shortage, missing coordinates, missing stop, or unplaceable lost-service.
- Return counts and reasons in the response.
- Do not silently drop students.
5.8 Proposal child rows
tpt_proposed_pickup_points
One row per unique live stop used in the proposal:
Field	Value
proposal_master_id	master id
shift_id	selected shift
code	live stop code
name	live stop name
proposal_type	Stopage_Add / Stopage_Merge / Stopage_Split
latitude / longitude	live coordinates
location	ST_GeomFromText('POINT(lng lat)', 4326)
total_distance	distance from school
estimated_time	minutes from school
stop_type	live stop type
Unique per (proposal_master_id, code).
tpt_proposed_route
Field	Value
proposal_master_id	master id
proposal_date	run date
code	deterministic, e.g. PRP-{masterId}-{PK/DP}-{index}
name	e.g. Morning Pickup Route 1 (12 Stops)
description	stops, distance, students, estimated cost, merge/split source
proposal_type	Route_New / Route_Merge / Route_Split / Route_Remove
pickup_drop	Pickup / Drop
shift_id	selected shift
route_geometry	OSRM/fallback LINESTRING
est_exp_per_km	estimated cost per km (2 decimals)
status	Auto_Generated
Unique per (proposal_master_id, code).
tpt_proposed_pickup_points_route_jnt
Field	Value
proposal_master_id	master id
shift_id	selected shift
proposed_route_id	proposed route id
old_route_id	live route id if the stop came from an existing route; null for new
pickup_drop	direction
proposed_pickup_point_id	proposed stop id
proposal_type	Stopage_Add / Stopage_Merge / Stopage_Split
ordinal	1-based sequence
total_distance	cumulative km from school
arrival_time	clock minutes
departure_time	clock minutes
estimated_time	minutes from school
pickup_drop_fare	copied from live junction if available; else null
both_side_fare	copied from live junction if available; else null
status	Auto_Generated
Fare source: copy from the live tpt_pickup_points_route_jnt for the same stop; if the stop is new, leave null and flag “fare needs review”. Do not hardcode.
tpt_proposed_student_route_allocation
Only if decision #5 is approved.
- One row per student whose allocation changes or who is newly covered.
- proposal_type = Student_Add (new/reassigned) or Student_Remove (no longer served).
- new_pickup_route_id / new_pickup_stop_id etc. store proposed IDs after the FK migration.
- fare: copy from the student’s existing active allocation; if missing, 0.00 and flag.
- effective_from: current academic session start date, else today.
- status: Auto_Generated.
If decision #5 is rejected, Phase 2 must skip this table entirely and approval cannot safely update allocations.
5.9 Time management / duplicate runs
- One master per generation run.
- proposal_date = run timestamp; created_at = run timestamp.
- On re-run for the same shift/date:
- If an existing master is entirely Auto_Generated and has not entered review, replace it (delete children, recreate).
- If any child is Proposed, In-Review, Approved, Rejected, Cancelled, or Restored, create a new master version instead of overwriting.
- Use DB::transaction and lockForUpdate on the existing master check to avoid concurrent duplicate runs.
- Keep generation synchronous in Phase 2. Move to a queued job only if runtime becomes a problem and the user approves.
5.10 Button / modal changes
Modules/SmartTransport/resources/views/pickup_point/index.blade.php:
- Replace the “force delete” warning with:
- “This will create route proposals only. Live routes, stops, and student allocations will not change until the proposal is approved.”
- Add a modal with:
- Shift select ($allShifts; add allShifts to PickupPointController::index for the standalone page).
- Direction checkboxes (Pickup/Drop, both default).
- Evaluate merges checkbox (default on).
- Evaluate splits checkbox (default on).
- Include empty stops checkbox (default off).
- Submit JSON body with shift_id and options.
- Disable button while generating; show summary on success.
- Do not reload the page immediately; show proposal summary and link to the proposal review page.
6. Cost and loss-recovery integration
6.1 Existing routes
Use TransportCostAnalysisService::getRouteCostAnalysis() for actuals:
- route_id, route_name, student_count
- monthly_income
- fuel_cost, maint_cost, crew_salary, rent_amount, other_expense
- total_expense, net_profit_loss
- profit_advisor.cost_per_km (variable/fixed/total/monthly_km)
These are actuals for current routes; label them as actual in the UI.
6.2 Proposed routes
No actuals exist, so estimate:
- work_days = LossRecoveryAdvisor::workDaysPerMonth()
- trips_per_day = LossRecoveryAdvisor::tripsPerDay()
- road_factor = fleet median road factor (add a public wrapper)
- variable_rate = fleet variable rate per km (add a public wrapper)
- fixed_cost = crew salary + rent for matched vehicle; else fleet median
- monthly_km = one-way route distance × 2 × work_days × trips_per_day
- variable_cost = monthly_km × variable_rate (or vehicle avg_exp_per_km if available)
- total_cost = variable_cost + fixed_cost
- est_exp_per_km = total_cost / monthly_km
Add small public wrappers to LossRecoveryAdvisor instead of duplicating formulas:
- public function fleetRoadFactor(): float
- public function fleetVariableRatePerKm(): float
- public function fleetDriverSalary(): float
- public function costPerKmForRouteItem(array $item): array
- public function vanEconomicsForSplit(...) if split is implemented
These are additive and reuse the existing private logic.
6.3 Merge/split savings
- Current cost = getRouteCostAnalysis() item total.
- Proposed cost = estimator above.
- Saving = current total − proposed total.
- Only propose if saving > 0 (recommended minimum ₹500/month) and zero-harm passes.
- Distinguish “estimated saving” from “actual saving” in the UI.
- If fuel/maintenance/salary data is missing, flag low confidence and show the basis.
7. Phase 3 — Review / approve / reject / apply
7.1 Proposal list
Add a new tab route_proposal on Transport Master (Phase 3), or a standalone page if preferred.
- Filters: date range, shift, proposal type, status, created by.
- Columns: date, shift, type, routes, stops, students covered, estimated cost, status, actions.
- Permission: tenant.smarttransport.route-proposal.viewAny.
7.2 Proposal detail
- Master summary.
- Route cards:
- Name, direction, stops, distance, time, students, estimated cost/km, status.
- Merge/split source routes.
- Map with Leaflet + OSRM polyline (reuse pickup_point/pickup_point.blade.php pattern).
- Stop table with ordinal, distance, arrival/departure/estimated time, fare.
- Student coverage summary and unserved list.
- Review/approve/reject/cancel buttons with remarks.
7.3 Status transitions
Recommended master statuses (if decision #6 approves master status):
Auto_Generated → Proposed → In-Review → Approved / Rejected / Cancelled → Restored
- Proposed: user opens/submits for review.
- In-Review: set in_review_by / in_review_at.
- Approved: set approve_reject_by / approve_reject_at; apply to live.
- Rejected: set remark; no live changes.
- Cancelled: no live changes.
- Restored: history restore.
If master status is not added, derive it from children and document the mixed-status rules.
7.4 Apply to live
New: Modules/SmartTransport/app/Services/RouteProposalApprovalService.php
In a single transaction:
1. Lock the master and verify status is not already Approved.
2. For each proposed route:
- Route_New: create live tpt_route; create live tpt_pickup_points_route_jnt rows.
- Route_Merge: create a new live route with all stops; deactivate/soft-delete source routes; copy old live rows to history.
- Route_Split: create two live routes; deactivate/soft-delete original; copy old rows to history.
- Route_Remove: deactivate/soft-delete route; copy old rows to history.
3. Reuse existing live pickup points by code; create new ones only if needed.
4. Update tpt_student_route_allocation_jnt only if allocation proposals exist and FKs are fixed; copy old allocations to tpt_student_route_allocation_history.
5. Create tpt_driver_route_vehicle_jnt only if a vehicle is assigned.
6. Write history rows:
- tpt_route_history
- tpt_pickup_points_history
- tpt_pickup_points_route_jnt_history
- tpt_student_route_allocation_history
7. Set master/children Approved.
8. Commit.
Never force-delete live routes; soft-delete/deactivate so history FKs remain valid.
7.5 Restore
- Use history tables to revert live rows.
- Set restored_by / restored_at.
- Mark proposal Restored.
- Do not delete history.
- Permission: restore-history.
7.6 Permissions for Phase 3
Add per-key extra verbs in config/permissionslist.php:
'smarttransport.route-proposal' => array_merge($crud, [
    'review', 'approve', 'reject', 'cancel', 'apply', 'restore-history',
]),
Do not add these to $crud itself.
8. File-by-file plan
Phase 1 — new files
File
Modules/SmartTransport/app/Http/Controllers/ProposalTypeController.php
Modules/SmartTransport/app/Http/Requests/ProposalTypeRequest.php
Modules/SmartTransport/app/Policies/TransportProposalTypePolicy.php
Modules/SmartTransport/resources/views/proposal-type/index.blade.php
Modules/SmartTransport/resources/views/proposal-type/create.blade.php
Modules/SmartTransport/resources/views/proposal-type/edit.blade.php
Modules/SmartTransport/resources/views/proposal-type/show.blade.php
Modules/SmartTransport/resources/views/proposal-type/trash.blade.php
Modules/SmartTransport/database/seeders/ProposalTypeSeeder.php
Phase 1 — modified files
File	Change
Modules/SmartTransport/routes/web.php	Add proposal-type resource + trash/restore/forceDelete/toggleStatus
Modules/SmartTransport/app/Http/Controllers/TransportMasterController.php	Import model; add tab, gate, query method, view data
Modules/SmartTransport/resources/views/tab_module/transportmaster.blade.php	Add tab definition + include
config/permissionslist.php	Add smarttransport.proposal-type
Modules/SmartTransport/app/Providers/SmartTransportServiceProvider.php	Register policy
Modules/SmartTransport/database/seeders/SmartTransportDatabaseSeeder.php	Call ProposalTypeSeeder
database/seeders/TenantDatabaseSeeder.php	Add SmartTransportDatabaseSeeder
Phase 2 — new files
File	Purpose
Modules/SmartTransport/app/Services/RouteProposalService.php	Demand, clustering, sequencing, proposal persistence
Modules/SmartTransport/app/Services/RoadRoutingService.php	OSRM route/distance/time + cache + fallback
Phase 2 — modified files
File	Change
Modules/SmartTransport/app/Http/Controllers/PickupPointController.php	Replace destructive autoGenerateAllRoutes; add shift validation; remove live writes
Modules/SmartTransport/app/Services/LossRecoveryAdvisor.php	Add public wrappers for fleet rates/cost
Modules/SmartTransport/resources/views/pickup_point/index.blade.php	Shift-selection modal; new warning; send options; show summary
Modules/SmartTransport/app/Http/Controllers/PickupPointController.php	Pass allShifts to standalone index
Modules/SmartTransport/routes/web.php	Keep auto-generate route; add proposal review routes later
Phase 3 — new files
File
Modules/SmartTransport/app/Http/Controllers/RouteProposalController.php
Modules/SmartTransport/app/Services/RouteProposalApprovalService.php
Modules/SmartTransport/resources/views/route-proposal/index.blade.php
Modules/SmartTransport/resources/views/route-proposal/show.blade.php
Modules/SmartTransport/resources/views/route-proposal/partials/route-card.blade.php
Modules/SmartTransport/resources/views/route-proposal/partials/stop-table.blade.php
Optional additive migrations (only if approved)
File
database/migrations/tenant/2026_10_21_100011_alter_tpt_proposed_student_route_allocation_fks.php
database/migrations/tenant/2026_10_21_100012_add_status_to_tpt_route_proposal_master.php
database/migrations/tenant/2026_10_21_100013_create_tpt_proposed_route_vehicle_jnt_table.php
Do not edit the already-committed migrations.
9. Validation and testing plan
Phase 1
1. php -l on all new/modified PHP files.
2. php artisan route:list --name=smarttransport.proposal-type.
3. Run ProposalTypeSeeder twice; assert exactly 10 rows.
4. Create custom type; edit; toggle; delete; restore; force delete.
5. System type: edit/update/delete/toggle/force delete → 403; UI hides controls.
6. Tab visible only with proposal-type.viewAny.
7. Existing Transport Master tabs and fine category CRUD unaffected.
Phase 2
 1. Auto-generate without shift_id → 422.
 2. Inactive shift → 422.
 3. No current academic session → 422.
 4. Missing proposal type rows → 422 with seeder message.
 5. Selected shift only: proposals created for that shift; other shifts untouched.
 6. Assert tpt_route, tpt_pickup_points_route_jnt, tpt_driver_route_vehicle_jnt, tpt_student_route_allocation_jnt, tpt_trip* counts/values unchanged.
 7. Assert master + children created with Auto_Generated.
 8. Stops missing lat/lng → skipped and reported.
 9. Capacity shortage → unserved students reported.
10. Merge candidate → Route_Merge, saving > 0, zero-harm passes.
11. Split candidate → Route_Split or “not recommended”.
12. Re-run same shift/date → replace untouched master; reviewed master not overwritten.
13. OSRM failure → fallback distance/time/geometry used.
14. Fare copied from live junction; new stop flagged.
15. Time fields are valid clock minutes; Pickup before shift start, Drop after shift end.
16. No live data changed.
Phase 3
1. Review → status In-Review, in_review_by/at set.
2. Reject → Rejected, remark saved, no live changes.
3. Approve → live rows created/updated; history rows written; allocations updated; status Approved.
4. Approve twice → idempotent, no duplicate live rows.
5. Merge approval → new live route; source routes deactivated; history valid.
6. Split approval → two live routes; original deactivated; history valid.
7. Restore → live rows reverted; restored_by/at set.
8. Regression: existing pickup point, route, allocation, trip pages unaffected.
Do not run tenants:test-migrate on production; use a disposable tenant DB if migrations are added.
10. Decisions needed before implementation
#	Decision	Recommended
1	Fix tpt_proposed_student_route_allocation.new_* FKs to proposed tables?	Yes
2	Add status to tpt_route_proposal_master?	Yes
3	Persist proposed vehicle assignment?	No, compute only
4	Fare source for proposed junction rows?	Copy live junction fare; null + review flag if new
5	Time convention?	estimated_time = minutes from school; arrival/departure = clock minutes
6	est_exp_per_km source?	Matched vehicle avg_exp_per_km; else fleet estimate
7	Academic year source?	sch_org_academic_sessions_jnt.is_current = 1
8	Duplicate run behavior?	Replace untouched Auto_Generated master; new version if reviewed
9	One master per shift or per shift+direction?	One per shift, both directions
10	Google Maps or OSRM?	OSRM + fallback
11	Auto-propose route removal?	Report only in Phase 2
12	Implement split in Phase 2?	Conservative candidate; defer if complex
13	Queue generation?	Synchronous now
14	Reuse soft-deleted proposal type code/name?	No
11. What I will not do without approval
- No application code changes.
- No DB migrations or schema changes.
- No UI changes.
- No live route/stop/allocation/trip deletion or updates.
- No student allocation changes during generation.
- No Google Maps API integration.
- No queue/job introduction.
- No editing of already-committed migrations.
Next step: confirm the 14 decisions above, especially #1 (allocation FKs), #2 (master status), #3 (vehicle persistence), and #10 (OSRM vs Google Maps). Once approved, I will implement Phase 1 only first: tpt_proposal_type CRUD + seeder + tab + permissions, then stop for review before Phase 2