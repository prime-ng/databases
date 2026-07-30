# tpt_AssignStops_TcList

## Module: Transport → Transport Master → Assign Stops to Route

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Master |
| Feature | Assign Stops to Route |
| URL(s) | `/transport/master` (index via tab), `/pickup-point-route` (index GET standalone — no Gate), `/pickup-point-route/create` (create GET), `/pickup-point-route` (store POST), `/pickup-point-route/{id}` (show GET), `/pickup-point-route/{id}/edit` (edit GET), `/pickup-point-route/{id}` (update PUT), `/pickup-point-route/{id}` (destroy DELETE), `/pickup-point-route/trash/view` (trash GET), `/pickup-point-route/{id}/restore` (restore GET), `/pickup-point-route/{id}/force-delete` (forceDelete DELETE), `/pickup-point-route/{pickupPointRoute}/toggle-status` (toggleStatus POST), `/pickup-point-route/route/{routeId}/toggle-status` (toggleRouteStatus POST — route registered in web.php line 105 but controller method NOT defined → 404), `/pickup-point-route/reorder` (reorder POST), `/get-routes-by-shift/{shiftId}` (getRoutesByShift GET) |
| Controller | `Modules\Transport\Http\Controllers\PickupPointRouteController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab: `assign_stops` |
| Model | `Modules\Transport\Models\PickupPointRoute` — table: `tpt_pickup_points_route_jnt` |
| Validation (Create + Update) | `Modules\Transport\Http\Requests\PickupPointRouteRequest` |
| Permissions | `tenant.pickup-point-route.viewAny`, `tenant.pickup-point-route.view`, `tenant.pickup-point-route.status`, `tenant.pickup-point-route.create`, `tenant.pickup-point-route.update`, `tenant.pickup-point-route.edit`, `tenant.pickup-point-route.delete`, `tenant.pickup-point-route.restore`, `tenant.pickup-point-route.forceDelete`, `tenant.pickup-point-route.import`, `tenant.pickup-point-route.export`, `tenant.pickup-point-route.print` |
| Policy | `Modules\Transport\Policies\PickupPointRoutePolicy` — 12 gates (viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print) |
| Soft Deletes | Yes (`BaseModel` includes `SoftDeletes` trait) |
| Activity Log | GAP — controller has ZERO `activityLog()` calls across all 6 mutation methods. See TC-CR37–TC-CR39 |
| Reorder | Drag-and-drop via SortableJS + AJAX POST to `/pickup-point-route/reorder` |

---

## 2. Pre-conditions

- Required permissions: `tenant.pickup-point-route.viewAny` (tab visibility) + per-action permissions
- Required seed data: At least 1 active `Route` (`tpt_route`), 1 active `Shift` (`tpt_shift`), 1 active `PickupPoint` (`tpt_pickup_points`) with latitude/longitude
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Settings required: `allow_only_one_side_transport_charges` and `allow_different_pickup_and_drop_point` in `sch_settings` table — affect fare column visibility in create/edit forms
- SortableJS CDN (`cdn.jsdelivr.net/npm/sortablejs@1.15.0`) required for reorder functionality
- The Assign Stops tab is loaded as part of TransportMaster — the URL `/transport/master?tab=assign_stops` loads TransportMasterController@index with all master tabs simultaneously
- `routes/web.php` line 105 defines `toggleRouteStatus` route pointing to `PickupPointRouteController::class` but NO `toggleRouteStatus()` method exists in the controller → calling this route returns 404

---

## 3. Default Data Load

When the page loads via `TransportMasterController@index()` (GET `/transport/master`), the Assign Stops tab data is loaded:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Assign Stops Grid | `TransportMasterController@pickupPointRoutesQuery()` | `PickupPointRoute::with(['route','pickupPoint','shift'])->orderBy('route_id')->orderBy('shift_id')->orderBy('ordinal')` | tab=assign_stops: `search` (pickupPoint.name), `route_id`, `shift_id`, `pickup_drop` (stop_type), `status` | 10/page via `->paginate(10)->withQueryString()` |
| Assign Stops Tab Partial | view: `transport::pickup_point_route.index` | Included inside `transportmaster.blade.php` via `@include('transport::pickup_point_route.index')` wrapped in `@can('tenant.pickup-point-route.viewAny')` | Uses `$pickupPointRoutes` variable from controller | As above |

**Standalone Controller** (`TransportMasterController::index() ? pickupPointRoutesQuery() [Tab-based]()` — ONLY when accessed directly at `/pickup-point-route`):

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Routes Dropdown | `TransportMasterController::index() ? pickupPointRoutesQuery() [Tab-based]()` line 20 | `Route::all()` — ALL routes (no active filter) | None | None |
| Shifts Dropdown | `TransportMasterController::index() ? pickupPointRoutesQuery() [Tab-based]()` line 21 | `Shift::all()` — ALL shifts | None | None |
| PickupPointRoutes Grid | `TransportMasterController::index() ? pickupPointRoutesQuery() [Tab-based]()` lines 24–36 | `PickupPointRoute::query()->where(...)` filtering by `route_id`, `shift_id`, `pickup_drop` | search (pickupPoint.name via whereHas), status | None (`->get()` — no pagination) |

**Key difference**: Standalone controller requires ALL THREE filters (route_id AND shift_id AND pickup_drop) to be present before executing the main query. The TransportMaster tab version has no such requirement and always returns paginated results.

**Key difference**: Standalone `index()` at `PickupPointRouteController.php:18` has NO `Gate::authorize()` call. TransportMasterController guards tab visibility via `@can('tenant.pickup-point-route.viewAny')` and `Gate::any()` at line 28.

---

## 4. Test Data Strategy

- **Unique suffix**: Use `now()->format('His') . random_int(100, 999)` for test entities
- **Route–Shift–PickupPoint combo**: Each test creates a unique combination to avoid `uq_pickupPointRoute_route_pickupPoint` unique key violation
- **Pre-test cleanup**: Delete created pickup point routes by ID before/after tests
- **Ordinal**: Auto-incremented in `store()` via `max('ordinal') ?? 0 + 1` per route+shift combo
- **Time fields**: Stored as integer minutes (e.g., 08:30 → 510). Request accepts `H:i` format. Create blade uses `<input type="time">` which sends `HH:MM`. Converted via `timeToMinutes()` in store/update
- **Fare fields**: `pickup_drop_fare` (one side) and `both_side_fare` (both sides). Column visibility depends on settings
- **Geometry auto-update**: After every create/update/delete/restore/forceDelete, `updateRouteGeometry()` regenerates `route_geometry` on the parent `tpt_route` as a JSON array of {lat, lng} points ordered by ordinal. **GAP**: `reorder()` does NOT call `updateRouteGeometry()`
- **Soft delete behavior**: `destroy()` calls `$pickupRoute->delete()` directly — does NOT set `is_active=false` first (unlike Route controller pattern)
- **Restore behavior**: `restore()` calls `$pickupRoute->restore()` directly
- **Force delete**: `forceDelete()` uses `onlyTrashed()->findOrFail()` — cannot force-delete non-trashed records. This differs from RouteController which uses `withTrashed()`
- **DB transaction wrapping**: All 5 CUD methods (store, update, destroy, restore, forceDelete) use `DB::beginTransaction()` / `DB::commit()` / `DB::rollBack()`

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_pickup_points_route_jnt`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED AUTO_INCREMENT | PK |
| BC-DB-02 | shift_id | INT UNSIGNED | NOT NULL, FK → `tpt_shift.id` ON DELETE CASCADE |
| BC-DB-03 | route_id | INT UNSIGNED | NOT NULL, FK → `tpt_route.id` ON DELETE CASCADE |
| BC-DB-04 | pickup_drop | ENUM('Pickup','Drop') | NOT NULL, DEFAULT 'Pickup' |
| BC-DB-05 | pickup_point_id | INT UNSIGNED | NOT NULL, FK → `tpt_pickup_points.id` ON DELETE CASCADE |
| BC-DB-06 | ordinal | SMALLINT UNSIGNED | NOT NULL, DEFAULT 1 |
| BC-DB-07 | total_distance | DECIMAL(7,2) | DEFAULT NULL |
| BC-DB-08 | arrival_time | INT | DEFAULT NULL (minutes since midnight) |
| BC-DB-09 | departure_time | INT | DEFAULT NULL (minutes since midnight) |
| BC-DB-10 | estimated_time | INT | DEFAULT NULL |
| BC-DB-11 | pickup_drop_fare | DECIMAL(10,2) | DEFAULT NULL — One Side (Pickup/Drop) Fare |
| BC-DB-12 | both_side_fare | DECIMAL(10,2) | DEFAULT NULL — Bothside Fare |
| BC-DB-13 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 (cast to boolean in model) |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-17 | UNIQUE KEY `uq_pickupPointRoute_route_pickupPoint` | (route_id, pickup_point_id) | Prevents duplicate stop assignment |
| BC-DB-18 | INDEX `idx_pprj_route_ordinal` | (route_id, ordinal) | Optimizes geometry update queries |

### 5.2 Validation Rules — `PickupPointRouteRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | route_id | required, `exists:tpt_route,id` | Default |
| BC-VAL-02 | shift_id | required, `exists:tpt_shift,id` | Default |
| BC-VAL-03 | rows | required, array, min:1 | Default |
| BC-VAL-04 | rows.*.pickup_point_id | required, `exists:tpt_pickup_points,id` | Default |
| BC-VAL-05 | rows.*.arrival_time | nullable, `date_format:H:i` | Default |
| BC-VAL-06 | rows.*.departure_time | nullable, `date_format:H:i` | Default |
| BC-VAL-07 | rows.*.total_distance | nullable, numeric, min:0 | Default |
| BC-VAL-08 | rows.*.estimated_time | nullable, numeric, min:0 | Default |
| BC-VAL-09 | rows.*.pickup_drop_fare | nullable, numeric, min:0 | Default |
| BC-VAL-10 | rows.*.both_side_fare | nullable, numeric, min:0 | Default |
| BC-VAL-11 | rows.*.is_active | nullable, boolean | Default |

**Custom Validation After-Hook** (`withValidator` at `PickupPointRouteRequest.php:45–161`):

| BC ID | Rule | Logic | Error |
|-------|------|-------|-------|
| BC-VAL-12 | Duplicate pickup_point_id within request | `array_column('pickup_point_id')` !== `array_unique(...)` | "Same pickup point cannot be added more than once." |
| BC-VAL-13 | Duplicate pickup_point_id against DB (store only) | `PickupPointRoute::where(route_id,shift_id,pickup_point_id)->exists()` for each row | "This pickup point is already assigned to this route and shift." |
| BC-VAL-14 | Departure must be after arrival | `arrival_time > departure_time` | "Departure time must be after arrival time." |
| BC-VAL-15 | Fare required (one side charge enabled) | `allowOneSide && empty(pickup_drop_fare)` | "Fare is required." |
| BC-VAL-16 | Both side fare required (same pickup/drop point) | `!allowOneSide && !allowDifferentPickupDrop && empty(both_side_fare)` | "Both side fare is required." |
| BC-VAL-17 | Pickup/Drop fare required (different points) | `!allowOneSide && allowDifferentPickupDrop && empty(pickup_drop_fare)` | "'{Pickup/Drop}' fare is required." |

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.pickup-point-route.viewAny | index() tab display in TransportMaster | Without → tab hidden (blade `@can`) |
| BC-AUTH-02 | tenant.pickup-point-route.view | show() line 47, trashed() line 315 | Without → 403 |
| BC-AUTH-03 | tenant.pickup-point-route.create | store() (via Request authorize), create() line 60 | Without → 403 |
| BC-AUTH-04 | tenant.pickup-point-route.update | update() (via Request authorize), reorder() line 440 | Without → 403 |
| BC-AUTH-05 | tenant.pickup-point-route.edit | edit() line 194, toggleStatus() line 381 | Without → 403; blade `@can` hides edit button |
| BC-AUTH-06 | tenant.pickup-point-route.delete | destroy() line 286, forceDelete() line 353 | Without → 403 |
| BC-AUTH-07 | tenant.pickup-point-route.restore | restore() line 324 | Without → 403 |
| BC-AUTH-08 | tenant.pickup-point-route.forceDelete | forceDelete() (Gate check uses `tenant.pickup-point-route.delete` at line 353) | Without → 403 |
| BC-AUTH-09 | tenant.pickup-point-route.status | Policy line 29 defines `status()` gate checking `tenant.pickup-point-route.status`, BUT controller toggleStatus() at line 381 uses `tenant.pickup-point-route.edit` | **Policy Gate not used** — controller bypasses dedicated status permission |
| BC-AUTH-10 | **GAP**: standalone index() line 18 | NO Gate::authorize() | Any authenticated user can access `/pickup-point-route` |
| BC-AUTH-11 | **GAP**: store() line 105 | NO controller-level Gate (relies only on FormRequest authorize at line 14) | If Request bypassed, no guard |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create via `store(PickupPointRouteRequest)` | New pickup point route(s) created; `pickup_drop` taken FROM route table (not request); ordinal auto-incremented per route+shift; redirect to transport-master.index with success flash |
| BC-BIZ-02 | Time conversion: `timeToMinutes(H:i)` | `08:30` → `510`; `14:45` → `885`. Stored as integer minutes in DB |
| BC-BIZ-03 | Fare defaults to 0 | If `pickup_drop_fare` or `both_side_fare` empty in request, stored as 0 |
| BC-BIZ-04 | is_active handling on create | `!empty($row['is_active']) ? 1 : 0` — checkbox unchecked → 0 |
| BC-BIZ-05 | is_active handling on update | `$request->has('is_active') ? 1 : 0` — unchecked checkbox → 0 |
| BC-BIZ-06 | Geometry auto-update after create | `updateRouteGeometry($routeId)` called after DB::commit — builds JSON array |
| BC-BIZ-07 | Geometry auto-update after update | Same as create — rebuilds geometry |
| BC-BIZ-08 | Geometry auto-update after delete | Same — geometry regenerated without the deleted point |
| BC-BIZ-09 | Geometry auto-update after restore | Same — regenerated |
| BC-BIZ-10 | Geometry auto-update after forceDelete | Same — regenerated |
| BC-BIZ-11 | Geometry with no valid points | If no PickupPointRoute has a pickupPoint with lat/lng → `route_geometry` set to NULL |
| BC-BIZ-12 | Soft delete via `destroy()` | `$pickupRoute->delete()` — does NOT set `is_active=false` before delete |
| BC-BIZ-13 | Redirect after soft delete | Redirect to `transport.transport-master.index` with flash |
| BC-BIZ-14 | Trash list via `trashed()` | `PickupPointRoute::onlyTrashed()->paginate(10)` |
| BC-BIZ-15 | Restore via `restore($id)` | `PickupPointRoute::onlyTrashed()->findOrFail($id)` → `$pickupRoute->restore()` |
| BC-BIZ-16 | Force delete via `forceDelete($id)` | `PickupPointRoute::onlyTrashed()->findOrFail($id)` → `$pickupRoute->forceDelete()` — CANNOT force-delete non-trashed records |
| BC-BIZ-17 | toggleStatus via `toggleStatus(Request, PickupPointRoute $pickupPointRoute)` | Route model binding; validates `is_active => required\|boolean`; returns JSON |
| BC-BIZ-18 | Reorder via `reorder(Request)` | Accepts `{order: [{id, ordinal}, ...]}`; updates each record's ordinal; returns JSON |
| BC-BIZ-19 | Standalone index requires all 3 filters | `$request->route_id && $request->shift_id && $request->pickup_drop` must all be non-empty; otherwise empty collection |
| BC-BIZ-20 | Create form gets routes by shift via AJAX | Shift on change → AJAX GET `/get-routes-by-shift/{shiftId}` → populates route dropdown |
| BC-BIZ-21 | Settings dependency for fare columns | `allow_only_one_side_transport_charges` and `allow_different_pickup_and_drop_point` determine fare column visibility |
| BC-BIZ-22 | Gate check NOT in Request authorize for edit | `PickupPointRouteRequest::authorize()` returns `create` for POST, `update` for PUT/PATCH. Edit view has SEPARATE Gate in controller `edit()` |
| BC-BIZ-23 | Standalone index has NO Gate check | `TransportMasterController::index() ? pickupPointRoutesQuery() [Tab-based]()` does NOT call `Gate::authorize()` |
| BC-BIZ-24 | NO activity logging | ZERO `activityLog()` calls in entire controller |

### BC-BIZ-DEEP: Deep Business Logic Entries

| BC ID | Condition | Expected Behavior | Code Reference |
|-------|-----------|-------------------|----------------|
| BC-BIZ-DEEP-01 | `store()` auto-ordinal calculation | `$maxOrdinal = PickupPointRoute::where('route_id', $routeId)->where('shift_id', $shiftId)->max('ordinal') ?? 0`. Then `$maxOrdinal++` per row. Ordinal is scoped to route+shift combo | `PickupPointRouteController.php:114–116,124` |
| BC-BIZ-DEEP-02 | `store()` skips empty pickup_point_id rows | `if (empty($row['pickup_point_id'])) { continue; }` — row silently skipped, no error raised, no increment of ordinal | `PickupPointRouteController.php:120–122` |
| BC-BIZ-DEEP-03 | Store fetches Route.pickup_drop with minimal select | `Route::select('id', 'pickup_drop')->where('id', $routeId)->where('is_active', 1)->first()` — only 2 columns | `PickupPointRouteController.php:137–140` |
| BC-BIZ-DEEP-04 | Store tie-break when route is inactive | If Route `is_active=0`, `$route` becomes null → `$route->pickup_drop` throws `Call to member function... on null` — **500 error bug** | `PickupPointRouteController.php:148` |
| BC-BIZ-DEEP-05 | `timeToMinutes()` implementation | `[$h, $m] = explode(':', $time); return ((int)$h * 60) + (int)$m;` — no validation, assumes valid H:i input | `PickupPointRouteController.php:186–190` |
| BC-BIZ-DEEP-06 | `normalizeBoolean()` handles 'ture' typo | `in_array($value, ['1','true','ture','yes','on'])` — explicitly handles the common misspelling 'ture' | `PickupPointRouteController.php:84–93` |
| BC-BIZ-DEEP-07 | `updateRouteGeometry()` eager-loads only id, latitude, longitude | `with('pickupPoint:id,latitude,longitude')` — efficient select, only 3 columns from pickup_points | `PickupPointRouteController.php:411` |
| BC-BIZ-DEEP-08 | Geometry query filters points without coordinates | `whereHas('pickupPoint', fn($q) => $q->whereNotNull('latitude')->whereNotNull('longitude'))` — excludes incomplete data | `PickupPointRouteController.php:407–410` |
| BC-BIZ-DEEP-09 | Geometry stores as JSON string, not JSON column | `'route_geometry' => json_encode($points)` — raw JSON string in VARCHAR/TEXT column | `PickupPointRouteController.php:433–434` |
| BC-BIZ-DEEP-10 | Geometry float casting | `(float) $row->pickupPoint->latitude` — explicit float cast ensures numeric JSON output | `PickupPointRouteController.php:414–416` |
| BC-BIZ-DEEP-11 | `destroy()` calls `$pickupRoute->delete()` directly | No `->update(['is_active' => 0])` before soft delete. Record remains active in trash | `PickupPointRouteController.php:294` |
| BC-BIZ-DEEP-12 | `restore()` uses `onlyTrashed()` — correct pattern | `PickupPointRoute::onlyTrashed()->findOrFail($id)` — can only restore what's in trash | `PickupPointRouteController.php:329` |
| BC-BIZ-DEEP-13 | `forceDelete()` uses `onlyTrashed()` — **GAP** | Should use `withTrashed()` like RouteController. Current code rejects force-delete of active (non-deleted) records | `PickupPointRouteController.php:358` |
| BC-BIZ-DEEP-14 | `toggleStatus()` uses route-model-binding | Method signature: `toggleStatus(Request $request, PickupPointRoute $pickupPointRoute)` — Laravel auto-resolves model by ID | `PickupPointRouteController.php:379` |
| BC-BIZ-DEEP-15 | `toggleStatus()` validation is inline, not FormRequest | `$request->validate(['is_active' => 'required|boolean'])` — standalone validation in controller | `PickupPointRouteController.php:383–385` |
| BC-BIZ-DEEP-16 | `toggleStatus()` boolean extraction | `$request->boolean('is_active')` — Laravel helper that interprets "1","true","on" as true | `PickupPointRouteController.php:387` |
| BC-BIZ-DEEP-17 | `toggleStatus()` success/failure response | Success: `{success: true, message: 'Pickup Point Route Status update'}`. Failure: `{success: false, message: 'Status update failed'}` — BOTH return 200 | `PickupPointRouteController.php:389–399` |
| BC-BIZ-DEEP-18 | `reorder()` has NO validation | `foreach ($request->order as $item)` — no type check, no exists check on IDs, no required fields | `PickupPointRouteController.php:442` |
| BC-BIZ-DEEP-19 | `reorder()` does NOT call `updateRouteGeometry()` | **GAP**: Ordinals change but route_geometry is not recalculated → geometry out of sync with stop order | `PickupPointRouteController.php:438–448` |
| BC-BIZ-DEEP-20 | `create()` loads only active supporting entities | `Route::where('is_active',1)->get()`, `PickupPoint::where('is_active',1)->get()`, `Shift::where('is_active',1)->get()` | `PickupPointRouteController.php:76–78` |
| BC-BIZ-DEEP-21 | `index()` loads ALL routes and shifts (no active filter) | `Route::all()` and `Shift::all()` — inactive routes/shifts appear in filter dropdowns | `PickupPointRouteController.php:20–21` |
| BC-BIZ-DEEP-22 | `show()` uses `first()` not `findOrFail()` | `->where('id', $id)->orderBy('ordinal')->first()` — returns null for invalid ID → 500 in view | `PickupPointRouteController.php:49–52` |
| BC-BIZ-DEEP-23 | `edit()` uses `first()` not `findOrFail()` | `->where('id', $pickupPointRouteId)->orderBy('ordinal')->first()` — null for invalid ID → 500 | `PickupPointRouteController.php:197–200` |
| BC-BIZ-DEEP-24 | `show()` has redundant `orderBy('ordinal')` | Single-record lookup with `where('id', $id)` returns at most 1 row — orderBy has no effect | `PickupPointRouteController.php:51` |
| BC-BIZ-DEEP-25 | Store fare defaults: `0` not null | `$pickupDropFare = 0` and `$bothSideFare = 0` initialized to 0, only overridden if `!empty()` | `PickupPointRouteController.php:126–135` |
| BC-BIZ-DEEP-26 | Update fare defaults via `?? 0` | `$request->pickup_drop_fare ?? 0` — null coalescing; differs from store's `!empty()` approach | `PickupPointRouteController.php:262–263` |
| BC-BIZ-DEEP-27 | `getRoutesByShift()` has NO Gate | No `Gate::authorize()` — any authenticated user can call this AJAX endpoint | `PickupPointRouteController.php:95–102` |
| BC-BIZ-DEEP-28 | `getRoutesByShift()` returns only active routes | `Route::where('shift_id', $shiftId)->where('is_active', 1)->select('id', 'name')->get()` | `PickupPointRouteController.php:97–100` |
| BC-BIZ-DEEP-29 | TransportMaster tab query uses `paginate(10)` | `$this->pickupPointRoutesQuery($request)->paginate(10)->withQueryString()` — always paginated | `TransportMasterController.php:75` |
| BC-BIZ-DEEP-30 | TransportMaster tab query orders by route_id, shift_id, ordinal | `->orderBy('route_id')->orderBy('shift_id')->orderBy('ordinal')` — sorted by route then shift then stop order | `TransportMasterController.php:261–263` |
| BC-BIZ-DEEP-31 | TransportMaster tab eager-loads 3 relationships | `PickupPointRoute::with(['route', 'pickupPoint', 'shift'])` — N+1 prevented | `TransportMasterController.php:260` |
| BC-BIZ-DEEP-32 | TransportMaster tab search filters by pickupPoint.name | `whereHas('pickupPoint', fn($p) => $p->where('name', 'like', "%{$search}%"))` — subquery join | `TransportMasterController.php:271–273` |
| BC-BIZ-DEEP-33 | TransportMaster tab pickup_drop filter uses stop_type on pickupPoint | `whereHas('pickupPoint', fn($q) => $q->where('stop_type', $request->pickup_drop))` — filters on related table | `TransportMasterController.php:289–291` |
| BC-BIZ-DEEP-34 | TransportMaster tab route filter on pickupPointRoute.route_id directly | `$query->where('route_id', $request->route_id)` — direct column filter | `TransportMasterController.php:279` |
| BC-BIZ-DEEP-35 | TransportMaster tab shift filter on pickupPointRoute.shift_id directly | `$query->where('shift_id', $request->shift_id)` — direct column filter | `TransportMasterController.php:284` |
| BC-BIZ-DEEP-36 | `@canany` in blade for action column visibility | `@canany(['tenant.pickup-point-route.edit', 'tenant.pickup-point-route.delete'])` — action column shown if user has edit OR delete | Blade view |
| BC-BIZ-DEEP-37 | Settings queried 2× per form load | `create()` loads settings (line 62–65), `PickupPointRouteRequest::withValidator()` also loads settings (line 58–61) — no memoization | `PickupPointRouteController.php:62–65` and `PickupPointRouteRequest.php:58–61` |
| BC-BIZ-DEEP-38 | Same settings evaluated differently | Controller `normalizeBoolean()` uses `in_array(['1','true','ture','yes','on'])`. Request uses `in_array(['1','true','yes','on'])` — **missing 'ture' in request** | Controller line 84–93 vs Request line 63–70 |
| BC-BIZ-DEEP-39 | Model `$attributes` defaults: `is_active=true`, `ordinal=1`, `pickup_drop='Pickup'` | Controller always overrides all 3: pickup_drop from route (line 148), ordinal from counter (line 150), is_active from request (line 166) | `PickupPointRoute.php:38–42` |
| BC-BIZ-DEEP-40 | Model `scopeActive()` defined but NOT used in controller | `scopeActive($query) { return $query->where('is_active', true); }` — dead code in current usage | `PickupPointRoute.php:44–47` |
| BC-BIZ-DEEP-41 | `PickupPointRouteRequest` duplicate DB check is store-only | `if (!$isUpdate)` guard at line 88 — update can silently assign duplicate pickup_point_id | `PickupPointRouteRequest.php:88` |
| BC-BIZ-DEEP-42 | Arrival/departure time strings compared as strings in Request | `$row['arrival_time'] > $row['departure_time']` — string comparison "10:00" > "09:00" works for H:i format | `PickupPointRouteRequest.php:116` |
| BC-BIZ-DEEP-43 | Inactive route validation gap | Request validates `route_id exists:tpt_route,id` (allows inactive), but controller fetches only `where('is_active',1)` → null pointer | `PickupPointRouteRequest.php:23` vs `PickupPointRouteController.php:139` |
| BC-BIZ-DEEP-44 | `toggleRouteStatus()` route defined but method missing | `Route::post('pickup-point-route/route/{routeId}/toggle-status', [PickupPointRouteController::class, 'toggleRouteStatus'])` — calling this returns 404 | `routes/web.php:105` |
| BC-BIZ-DEEP-45 | Policy has `status()` gate using `tenant.pickup-point-route.status` | But controller `toggleStatus()` never calls this gate — uses `tenant.pickup-point-route.edit` instead | `PickupPointRoutePolicy.php:29–32` |
| BC-BIZ-DEEP-46 | Policy has import/export/print gates (no controller methods) | `import()`, `export()`, `print()` defined but no corresponding controller actions | `PickupPointRoutePolicy.php:77–96` |
| BC-BIZ-DEEP-47 | Unique key violation in store caught by try/catch | If duplicate slips past Request validation, DB throws integrity constraint violation → caught → rollback + error message | `PickupPointRouteController.php:177–183` |
| BC-BIZ-DEEP-48 | All redirects go to `transport.transport-master.index` | store/update/destroy/restore/forceDelete ALL redirect to master index (not pickup-point-route.index) | Throughout controller |
| BC-BIZ-DEEP-49 | Success messages are hardcoded English strings | No `__()` or translation wrapper. Store: "Pickup Point Routes added successfully.", Update: "Pickup Point Route updated successfully.", Destroy: "Pickup point removed successfully.", Restore: "Pickup point restored successfully.", ForceDelete: "Pickup point permanently deleted." | Throughout controller |
| BC-BIZ-DEEP-50 | Error messages expose exception details | `'Something went wrong: ' . $e->getMessage()` — raw exception message exposed to user | `PickupPointRouteController.php:181` |
| BC-BIZ-DEEP-51 | Store behavior when ALL rows are skipped | If all rows have empty pickup_point_id, loop does 0 creates, DB::commit() still called → success message shown but nothing created | `PickupPointRouteController.php:120–122,170–175` |
| BC-BIZ-DEEP-52 | `show()` view receives single model instance | `compact('pickupPointRoute')` — singular variable name, single model (or null) | `PickupPointRouteController.php:53–55` |
| BC-BIZ-DEEP-53 | `edit()` passes same variable name as `$pickupPointRoutes` (plural) | `compact('pickupPointRoutes')` — stores single record but variable named plurally | `PickupPointRouteController.php:221` |
| BC-BIZ-DEEP-54 | `trashed()` has separate Gate from `show()` | Both use `tenant.pickup-point-route.view` but trashed shows deleted records | `PickupPointRouteController.php:315` |
| BC-BIZ-DEEP-55 | Pagination only in trashed, not in standalone index | `trashed()` uses `paginate(10)`. Standalone `index()` uses `get()` (all records). TransportMaster tab uses `paginate(10)` | `PickupPointRouteController.php:317` vs line 35 vs `TransportMasterController.php:75` |
| BC-BIZ-DEEP-56 | No `is_system_defined` protection | Unlike some Syllabus entities, PickupPointRoute has no system-defined record protection | Throughout controller |
| BC-BIZ-DEEP-57 | `destroy()` uses `findOrFail` (manual ID) not route-model-binding | `destroy($id)` — receives $id as parameter, calls `findOrFail($id)` | `PickupPointRouteController.php:291` |
| BC-BIZ-DEEP-58 | `toggleStatus()` uses route-model-binding | `toggleStatus(Request $request, PickupPointRoute $pickupPointRoute)` — auto-resolved | `PickupPointRouteController.php:379` |
| BC-BIZ-DEEP-59 | `restore()` and `forceDelete()` use `onlyTrashed()` | Both query only soft-deleted records via `onlyTrashed()` | `PickupPointRouteController.php:329,358` |
| BC-BIZ-DEEP-60 | Blade uses `$item->route->name ?? ''` for null-safe display | Null coalescing prevents errors when relationship is null | Blade view |
| BC-BIZ-DEEP-61 | `minutesToTime()` helper in blade shows '-' for null | Helper function converts null to dash | Blade view lines 6–16 |
| BC-BIZ-DEEP-62 | TransportMaster uses Gate::any() for page access | `Gate::any([... 11 permissions ...]) || abort(403)` — any one of 11 permissions grants access | `TransportMasterController.php:28–41` |
| BC-BIZ-DEEP-63 | `getRoutesByShift()` returns JSON array | `return response()->json($routes)` — direct JSON response, no view | `PickupPointRouteController.php:101` |
| BC-BIZ-DEEP-64 | `reorder()` returns `response()->json(['success' => true])` | Simple success boolean, no error handling for invalid input | `PickupPointRouteController.php:447` |
| BC-BIZ-DEEP-65 | Store route_id and pickup_point_id from request but pickup_drop from route table | `'pickup_drop' => $route->pickup_drop` — key design decision: stop inherits route's pickup/drop type | `PickupPointRouteController.php:148` |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | route() | BelongsTo Route | route_id | Returns the route this stop assignment belongs to |
| BC-REL-02 | pickupPoint() | BelongsTo PickupPoint | pickup_point_id | Returns the pickup point (stop) assigned |
| BC-REL-03 | shift() | BelongsTo Shift | shift_id | Returns the shift for this assignment |

### 5.6 Referential Integrity (DDL)

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | shift_id | tpt_shift (id) | CASCADE |
| BC-REF-02 | route_id | tpt_route (id) | CASCADE |
| BC-REF-03 | pickup_point_id | tpt_pickup_points (id) | CASCADE |

### 5.7 Route Geometry Auto-Update

| BC ID | Method | Line | Trigger | Behavior |
|-------|--------|------|---------|----------|
| BC-GEO-01 | `updateRouteGeometry()` | 403–436 | After create/update/delete/restore/forceDelete | Queries ALL PickupPointRoute for given route_id, eager-loads pickupPoint.latitude+longitude, builds JSON array, updates `tpt_route.route_geometry` |
| BC-GEO-02 | Empty geometry | 423–428 | When no points with lat/lng found | Sets `route_geometry = NULL` |
| BC-GEO-03 | Data format | 433–435 | When points exist | Stores as JSON string: `[{"lat":12.9,"lng":77.5},...]` |
| BC-GEO-04 | Map to float | 414–416 | Per point | `(float) $row->pickupPoint->latitude` — explicit float cast |
| BC-GEO-05 | Eager load optimization | 411 | Query | `with('pickupPoint:id,latitude,longitude')` — selects only 3 columns |
| BC-GEO-06 | **GAP**: Not called after reorder() | 438–448 | After drag-drop | `reorder()` updates ordinals but geometry out of sync |

### 5.8 CODE-TRACE: Controller Method Analysis

#### CODE-TRACE: `index()` — Standalone (PickupPointRouteController.php:18–43)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 20 | `$routes = Route::all()` | ALL routes, no filter, no pagination |
| 2 | 21 | `$shifts = Shift::all()` | ALL shifts, no filter |
| 3 | 22 | `$pickupPointRoutes = collect()` | Empty collection default |
| 4 | 24 | `if ($request->route_id && $request->shift_id && $request->pickup_drop)` | ALL 3 required |
| 5 | 25–28 | `PickupPointRoute::query()->where('route_id',...)->where('shift_id',...)->where('pickup_drop',...)` | 3 exact-match where clauses |
| 6 | 29–30 | `->when($request->status !== null && $request->status !== '', fn => where('is_active', $request->status))` | Status filter (empty-string safe) |
| 7 | 31–33 | `->when($request->search, fn => whereHas('pickupPoint', fn => where('name','like','%...%')))` | Search via subquery |
| 8 | 34 | `->orderBy('ordinal')` | Single column sort |
| 9 | 35 | `->get()` | No pagination — all matching rows |
| 10 | 38–42 | `compact('routes','shifts','pickupPointRoutes')` | View: `transport::pickup_point_route.index` |

**Gaps identified:**
- NO `Gate::authorize()` call (line 18)
- `Route::all()` includes inactive routes in filter dropdown
- No pagination on result set
- View calls `->links()` on line 140 of blade but receives Collection → potential `BadMethodCallException`

#### CODE-TRACE: `show($id)` (PickupPointRouteController.php:45–56)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 47 | `Gate::authorize('tenant.pickup-point-route.view')` | First line |
| 2 | 49–52 | `PickupPointRoute::with(['route', 'pickupPoint', 'shift'])->where('id', $id)->orderBy('ordinal')->first()` | Eager loads 3 relationships |
| 3 | 53–55 | `compact('pickupPointRoute')` → view `transport::pickup_point_route.show` | |

**Gaps identified:**
- Uses `->first()` not `findOrFail()` — invalid ID returns null → 500 error in view
- `orderBy('ordinal')` redundant for single-record lookup

#### CODE-TRACE: `create()` (PickupPointRouteController.php:58–82)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 60 | `Gate::authorize('tenant.pickup-point-route.create')` | Viewing create form |
| 2 | 62–65 | `Setting::whereIn('key', ['allow_only_one_side...','allow_different...'])->pluck('value','key')` | Loads 2 settings |
| 3 | 67–73 | `normalizeBoolean()` applied to both settings | Handles 'ture' typo |
| 4 | 76 | `Route::where('is_active', 1)->get()` | Only active routes |
| 5 | 77 | `PickupPoint::where('is_active', 1)->get()` | Only active pickup points |
| 6 | 78 | `Shift::where('is_active', 1)->get()` | Only active shifts |
| 7 | 75–81 | `compact(...)` → view `transport::pickup_point_route.create` | |

#### CODE-TRACE: `store(PickupPointRouteRequest $request)` (PickupPointRouteController.php:105–184)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 105 | `public function store(PickupPointRouteRequest $request)` | No controller-level Gate — relies on Request |
| 2 | 108 | `DB::beginTransaction()` | Start transaction |
| 3 | 111–112 | `$routeId = $request->route_id; $shiftId = $request->shift_id` | Capture from request |
| 4 | 114–116 | `$maxOrdinal = PickupPointRoute::where('route_id', $routeId)->where('shift_id', $shiftId)->max('ordinal') ?? 0` | Per combo ordinal |
| 5 | 118–167 | `foreach ($request->rows as $index => $row)` | Loop rows |
| 6 | 120–122 | `if (empty($row['pickup_point_id'])) { continue; }` | Skip empty rows |
| 7 | 124 | `$maxOrdinal++` | Increment per row |
| 8 | 126–127 | `$pickupDropFare = 0; $bothSideFare = 0` | Default to 0 |
| 9 | 129–135 | Override fares if non-empty | `if (!empty($row['pickup_drop_fare']))` |
| 10 | 137–140 | `Route::select('id','pickup_drop')->where('id',$routeId)->where('is_active',1)->first()` | Fetch route's pickup_drop |
| 11 | 142–167 | `PickupPointRoute::create([...])` | Create record |
| 12 | 148 | `'pickup_drop' => $route->pickup_drop` | **From route table** |
| 13 | 152–158 | `timeToMinutes($row['arrival_time'])` | Time conversion |
| 14 | 166 | `'is_active' => !empty($row['is_active']) ? 1 : 0` | Boolean handling |
| 15 | 170 | `DB::commit()` | Commit transaction |
| 16 | 171 | `$this->updateRouteGeometry($routeId)` | Rebuild geometry |
| 17 | 173–175 | `redirect()->route('transport.transport-master.index')->with('success', ...)` | Redirect to master tab |

**Gaps:**
- No controller-level Gate (only FormRequest authorize)
- No activityLog() 
- Null pointer if route inactive (line 148)
- Silent skip of empty pickup_point_id rows

#### CODE-TRACE: `edit($pickupPointRouteId)` (PickupPointRouteController.php:192–229)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 194 | `Gate::authorize('tenant.pickup-point-route.edit')` | First line |
| 2 | 197–200 | `PickupPointRoute::with('pickupPoint')->where('id', $pickupPointRouteId)->orderBy('ordinal')->first()` | Loads single record |
| 3 | 203 | `PickupPoint::where('is_active', 1)->get()` | Active pickup points |
| 4 | 204 | `Shift::where('is_active', 1)->get()` | Active shifts |
| 5 | 205 | `Route::where('is_active', 1)->get()` | Active routes |
| 6 | 208–219 | Settings loaded + normalizeBoolean applied | Same as create() |
| 7 | 221–228 | `compact(...)` → view `transport::pickup_point_route.edit` | |

**Gaps:**
- Uses `->first()` not `findOrFail()` — invalid ID → 500
- Variable name `$pickupPointRoutes` (plural) for single record

#### CODE-TRACE: `update(PickupPointRouteRequest $request, $id)` (PickupPointRouteController.php:232–282)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 234 | `Gate::authorize('tenant.pickup-point-route.edit')` | Gate check |
| 2 | 236 | `DB::beginTransaction()` | Start transaction |
| 3 | 239–242 | `Route::select('id','pickup_drop')->where('id',$request->route_id)->where('is_active',1)->first()` | Fetch route's pickup_drop |
| 4 | 243 | `$pickupRoute = PickupPointRoute::findOrFail($id)` | Uses findOrFail — proper 404 |
| 5 | 245–266 | `$pickupRoute->update([...])` | Update 11 fields |
| 6 | 249 | `'pickup_drop' => $route->pickup_drop` | From route table |
| 7 | 251–257 | `timeToMinutes($request->arrival_time)` | Time conversion |
| 8 | 262–263 | `$request->pickup_drop_fare ?? 0` | Null coalescing (differs from store) |
| 9 | 265 | `'is_active' => $request->has('is_active') ? 1 : 0` | Different from store's `!empty()` |
| 10 | 268 | `DB::commit()` | Commit |
| 11 | 269 | `$this->updateRouteGeometry($request->route_id)` | Geometry update |
| 12 | 271–273 | Redirect to master index with flash | |

**Gap:** No activityLog()

#### CODE-TRACE: `destroy($id)` (PickupPointRouteController.php:284–310)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 286 | `Gate::authorize('tenant.pickup-point-route.delete')` | Gate check |
| 2 | 288 | `DB::beginTransaction()` | Start transaction |
| 3 | 291 | `$pickupRoute = PickupPointRoute::findOrFail($id)` | Manual findOrFail |
| 4 | 292 | `$routeId = $pickupRoute->route_id` | Save route_id before delete |
| 5 | 294 | `$pickupRoute->delete()` | Soft delete |
| 6 | 296 | `DB::commit()` | Commit |
| 7 | 297 | `$this->updateRouteGeometry($routeId)` | Rebuild geometry |
| 8 | 299–301 | Redirect to master index with flash | |

**Gap:** No `is_active=false` before soft-delete. No activityLog().

#### CODE-TRACE: `trashed()` (PickupPointRouteController.php:313–320)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 315 | `Gate::authorize('tenant.pickup-point-route.view')` | Gate check |
| 2 | 317 | `$pickupPointRoutes = PickupPointRoute::onlyTrashed()->paginate(10)` | 10 per page, only soft-deleted |
| 3 | 319 | `compact('pickupPointRoutes')` → view `transport::pickup_point_route.trash` | |

#### CODE-TRACE: `restore($id)` (PickupPointRouteController.php:322–348)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 324 | `Gate::authorize('tenant.pickup-point-route.restore')` | Gate check |
| 2 | 326 | `DB::beginTransaction()` | Start transaction |
| 3 | 329 | `$pickupRoute = PickupPointRoute::onlyTrashed()->findOrFail($id)` | Must be in trash |
| 4 | 330 | `$routeId = $pickupRoute->route_id` | Save route_id |
| 5 | 332 | `$pickupRoute->restore()` | Restore soft-deleted |
| 6 | 334 | `DB::commit()` | Commit |
| 7 | 335 | `$this->updateRouteGeometry($routeId)` | Rebuild geometry |
| 8 | 337–339 | Redirect to master index with flash | |

**Gap:** No activityLog()

#### CODE-TRACE: `forceDelete($id)` (PickupPointRouteController.php:351–377)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 353 | `Gate::authorize('tenant.pickup-point-route.delete')` | Reuses delete permission |
| 2 | 355 | `DB::beginTransaction()` | Start transaction |
| 3 | 358 | `$pickupRoute = PickupPointRoute::onlyTrashed()->findOrFail($id)` | **onlyTrashed()** — GAP |
| 4 | 359 | `$routeId = $pickupRoute->route_id` | Save route_id |
| 5 | 361 | `$pickupRoute->forceDelete()` | Permanent delete |
| 6 | 363 | `DB::commit()` | Commit |
| 7 | 364 | `$this->updateRouteGeometry($routeId)` | Rebuild geometry |
| 8 | 366–368 | Redirect to master index with flash | |

**Gaps:**
- `onlyTrashed()` instead of `withTrashed()` — cannot force-delete active records
- Reuses `delete` permission instead of `forceDelete` permission
- No activityLog()

#### CODE-TRACE: `toggleStatus(Request $request, PickupPointRoute $pickupPointRoute)` (PickupPointRouteController.php:379–400)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 381 | `Gate::authorize('tenant.pickup-point-route.edit')` | Uses edit, not status gate |
| 2 | 383–385 | `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 3 | 387 | `$pickupPointRoute->is_active = $request->boolean('is_active')` | Boolean cast |
| 4 | 389 | `if ($pickupPointRoute->save())` | Save + conditional response |
| 5 | 390–392 | Success: `return response()->json(['success'=>true, 'message'=>'Pickup Point Route Status update'])` | JSON success |
| 6 | 396–398 | Failure: `return response()->json(['success'=>false, 'message'=>'Status update failed'])` | JSON failure (also 200) |

**Gaps:**
- No activityLog()
- Uses `edit` permission instead of `status` permission

#### CODE-TRACE: `reorder(Request $request)` (PickupPointRouteController.php:438–448)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 440 | `Gate::authorize('tenant.pickup-point-route.update')` | Gate check |
| 2 | 442–445 | `foreach ($request->order as $item) { PickupPointRoute::where('id', $item['id'])->update(['ordinal' => $item['ordinal']]); }` | Bulk update, NO validation |
| 3 | 447 | `return response()->json(['success' => true])` | JSON response |

**Gaps:**
- NO validation on `$request->order` structure
- NO exists check on IDs — invalid IDs silently ignored
- NO `updateRouteGeometry()` call — geometry out of sync
- No activityLog()

#### CODE-TRACE: `getRoutesByShift($shiftId)` (PickupPointRouteController.php:95–102)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 97–100 | `Route::where('shift_id', $shiftId)->where('is_active', 1)->select('id', 'name')->get()` | Active routes only, 2 columns |
| 2 | 101 | `return response()->json($routes)` | JSON array |

**Gap:** NO Gate::authorize() — any authenticated user can call

#### CODE-TRACE: `pickupPointRoutesQuery()` in TransportMasterController (TransportMasterController.php:258–301)

| Step | Line | Code | Notes |
|------|------|------|-------|
| 1 | 260 | `$query = PickupPointRoute::with(['route', 'pickupPoint', 'shift'])` | Eager load 3 relationships |
| 2 | 261–263 | `->orderBy('route_id')->orderBy('shift_id')->orderBy('ordinal')` | Triple sort |
| 3 | 265 | `if ($request->tab === 'assign_stops')` | Tab guard |
| 4 | 268–274 | Search filter: `whereHas('pickupPoint', fn => where('name','like','%search%'))` | By pickup point name |
| 5 | 278–279 | Route filter: `where('route_id', $request->route_id)` | Direct column |
| 6 | 283–284 | Shift filter: `where('shift_id', $request->shift_id)` | Direct column |
| 7 | 288–291 | Pickup/Drop filter: `whereHas('pickupPoint', fn => where('stop_type', $request->pickup_drop))` | On related table |
| 8 | 295–297 | Status filter: `where('is_active', $request->status)` | `isset()` not `filled()` |

---

## 6. Test Case List

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Assign Stops Tab Loads Inside Transport Master | `/transport/master?tab=assign_stops` loads the tab with filter bar (search, route, shift, pickup/drop, status), table (drag handle, Route, Pickup Point, Arrival, Departure, Distance, Est. Time, Status, Action), Add and Trash buttons | — | — | ⬜ |
| TC-P02 | Create Assign Stops — Single Row | POST `/pickup-point-route` with route_id, shift_id, 1 row → record created; redirected to master tab with success flash | — | — | ⬜ |
| TC-P03 | Create Assign Stops — Multiple Rows | POST with 3 rows (different pickup_point_id) → all 3 records created; ordinal auto-incremented 1,2,3 | — | — | ⬜ |
| TC-P04 | Auto-ordinal on Create | First record for route+shift → ordinal=1; second → ordinal=2; third → ordinal=3 | — | — | ⬜ |
| TC-P05 | Time Conversion on Create | Send `arrival_time=08:30` → stored as 510 in DB; displayed as `08:30` in views | — | — | ⬜ |
| TC-P06 | Fare Defaults to 0 | Empty fare fields → stored as 0 | — | — | ⬜ |
| TC-P07 | pickup_drop Inherited From Route | Route has `pickup_drop='Drop'` → created record has `pickup_drop='Drop'` (from route, not request) | — | — | ⬜ |
| TC-P08 | View Assign Stop Details | `/pickup-point-route/{id}` shows Route, Shift, Pickup/Drop, Pickup Point, Arrival/Departure Time, Distance, Est. Time, Fare, Active checkbox | — | — | ⬜ |
| TC-P09 | Edit Loads Pre-Filled Data | `/pickup-point-route/{id}/edit` shows existing values for all fields | — | — | ⬜ |
| TC-P10 | Update Assign Stop | PUT `/pickup-point-route/{id}` with updated fields → updated; geometry auto-regenerated; redirect with success flash | — | — | ⬜ |
| TC-P11 | Soft Delete Assign Stop | DELETE `/pickup-point-route/{id}` → deleted_at set; record hidden from main list; geometry auto-updated | — | — | ⬜ |
| TC-P12 | Trash Page Shows Deleted Records | GET `/pickup-point-route/trash/view` → list of soft-deleted records with Route, Pickup Point, Ordinal, Action (Restore/Force Delete) | — | — | ⬜ |
| TC-P13 | Restore From Trash | GET `/pickup-point-route/{id}/restore` → deleted_at=NULL; record visible; geometry auto-updated | — | — | ⬜ |
| TC-P14 | Force Delete From Trash | DELETE `/pickup-point-route/{id}/force-delete` → record permanently removed; geometry auto-updated | — | — | ⬜ |
| TC-P15 | Toggle Status | POST `/pickup-point-route/{pickupPointRoute}/toggle-status` with `is_active=true/false` → JSON `{success: true, message}`; status switch in UI updates | — | — | ⬜ |
| TC-P16 | Reorder via Drag and Drop | Drag row to new position → AJAX POST `/pickup-point-route/reorder` → JSON `{success: true}`; table order updates | — | — | ⬜ |
| TC-P17 | Filter by Route | Select route from dropdown → table filters to assignments for that route | — | — | ⬜ |
| TC-P18 | Filter by Shift | Select shift from dropdown → table filters to assignments for that shift | — | — | ⬜ |
| TC-P19 | Filter by Pickup/Drop | Select "Pickup" or "Drop" → table filters by stop_type | — | — | ⬜ |
| TC-P20 | Filter by Status | Select "Active"/"Inactive" → table filters by is_active | — | — | ⬜ |
| TC-P21 | Search by Pickup Point Name | Enter pickup point name → table filters via `whereHas('pickupPoint', fn => where('name','like','%...%'))` | — | — | ⬜ |
| TC-P22 | Empty State — No Assignments | Table shows "No Data Found" across all columns | — | — | ⬜ |
| TC-P23 | Empty Trash | Trash table shows "No Data Found" | — | — | ⬜ |
| TC-P24 | TransportMaster Tab Pagination | 11+ records → pagination links; `->paginate(10)->withQueryString()` | — | — | ⬜ |
| TC-P25 | Standalone Index With All 3 Filters | GET `/pickup-point-route?route_id=X&shift_id=Y&pickup_drop=Pickup` → returns filtered results (not paginated) | — | — | ⬜ |
| TC-P26 | Fare Column Visibility Based on Settings | `allow_only_one_side_transport_charges=true` → shows "Pickup / Drop Fare" column; `allow_different_pickup_and_drop_point=true` → shows "Both Fare" column | — | — | ⬜ |
| TC-P27 | Create Stop with Midnight Time | Arrival `00:00` → stored as 0 minutes; Departure `00:05` → stored as 5 minutes | — | — | ⬜ |
| TC-P28 | Create Stop with End-of-Day Time | Arrival `23:55` → 1435 minutes; Departure `23:59` → 1439 minutes | — | — | ⬜ |
| TC-P29 | Create Stop with Zero Distance | `total_distance=0` passes `min:0` validation | — | — | ⬜ |
| TC-P30 | Minimal Create — Only pickup_point_id | All optional fields left empty → record created with null times and 0 fares | — | — | ⬜ |
| TC-P31 | `getRoutesByShift` AJAX Returns Active Routes | GET `/get-routes-by-shift/{shiftId}` → JSON array of `{id, name}` for active routes only | — | — | ⬜ |
| TC-P32 | Create Stop with All Optional Fields | Include arrival, departure, distance, est time, both fares → all saved correctly | — | — | ⬜ |
| TC-P33 | Edit Stop — Change Route | Change route_id → pickup_drop inherited from NEW route; geometry recalculated for both old and new route | — | — | ⬜ |
| TC-P34 | Soft-delete Then Restore Same Record | Sequence: create → soft-delete → restore → same record back in active list with same is_active value | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing route_id | Validation error: "The route id field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing shift_id | Validation error: "The shift id field is required." | — | — | ⬜ |
| TC-N03 | Required — Empty rows array | Validation error: "The rows field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing pickup_point_id in row | Validation error: "The rows.0.pickup_point_id field is required." | — | — | ⬜ |
| TC-N05 | Invalid route_id — Non-Existent | "The selected route id is invalid." | — | — | ⬜ |
| TC-N06 | Invalid shift_id — Non-Existent | "The selected shift id is invalid." | — | — | ⬜ |
| TC-N07 | Invalid pickup_point_id — Non-Existent | "The selected rows.0.pickup_point_id is invalid." | — | — | ⬜ |
| TC-N08 | Duplicate pickup_point in same request | "Same pickup point cannot be added more than once." | — | — | ⬜ |
| TC-N09 | Duplicate pickup_point against DB (store only) | "This pickup point is already assigned to this route and shift." | — | — | ⬜ |
| TC-N10 | Arrival time after Departure time | "Departure time must be after arrival time." | — | — | ⬜ |
| TC-N11 | Invalid time format (not H:i) | `date_format:H:i` validation error | — | — | ⬜ |
| TC-N12 | Negative distance | `min:0` validation error | — | — | ⬜ |
| TC-N13 | Non-numeric fare | `numeric` validation error | — | — | ⬜ |
| TC-N14 | View Invalid ID | GET `/pickup-point-route/99999` → null returned (no findOrFail) → 500 error | — | — | ⬜ |
| TC-N15 | Edit Invalid ID | GET `/pickup-point-route/99999/edit` → null → 500 error (no findOrFail) | — | — | ⬜ |
| TC-N16 | Update Invalid ID | PUT `/pickup-point-route/99999` → 404 (findOrFail) | — | — | ⬜ |
| TC-N17 | Delete Invalid ID | DELETE `/pickup-point-route/99999` → 404 (findOrFail) | — | — | ⬜ |
| TC-N18 | Toggle Status Invalid ID | POST with non-existent model → ModelNotFoundException (route model binding) → 404 | — | — | ⬜ |
| TC-N19 | Restore Non-Deleted Record | GET `/pickup-point-route/{id}/restore` where not trashed → `onlyTrashed()` returns null → 404 | — | — | ⬜ |
| TC-N20 | Force Delete Non-Trashed Record | DELETE `/pickup-point-route/{id}/force-delete` → `onlyTrashed()` returns null → 404 | — | — | ⬜ |
| TC-N21 | Toggle Status with Non-Boolean is_active | POST with `is_active=invalid` → validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N22 | Reorder with missing order data | POST `/pickup-point-route/reorder` with empty/invalid payload → foreach on null may fail → 500 | — | — | ⬜ |
| TC-N23 | Standalone Index — Missing required filters | GET `/pickup-point-route` with missing route_id/shift_id/pickup_drop → empty collection; no error | — | — | ⬜ |
| TC-N24 | Permission 403 | No `tenant.pickup-point-route.*` → tab hidden; direct URL access to create/edit/etc → 403 | — | — | ⬜ |
| TC-N25 | Guest Access Redirect | All URLs redirect to `/login` for unauthenticated users | — | — | ⬜ |
| TC-N26 | XSS in Pickup Point name | `<script>` stored in pickup_point.name → Blade `{{ }}` escapes output | — | — | ⬜ |
| TC-N27 | is_active Unchecked on Update | Update with is_active checkbox unchecked → `$request->has('is_active')` false → is_active=0 | — | — | ⬜ |
| TC-N28 | Fare required condition based on settings | When `allowOneSide=true` and `pickup_drop_fare` empty → "Fare is required." | — | — | ⬜ |
| TC-N29 | Store with inactive route (null pointer bug) | Route set to is_active=0 → validation passes (exists:tpt_route,id) → controller line 148: `$route->pickup_drop` on null → 500 error | — | — | ⬜ |
| TC-N30 | Store with all rows skipped (empty pickup_point_id) | All rows have empty pickup_point_id → 0 records created but success message shown | — | — | ⬜ |
| TC-N31 | Restore invalid ID | GET `/pickup-point-route/99999/restore` → `onlyTrashed()->findOrFail(99999)` → 404 | — | — | ⬜ |
| TC-N32 | Force delete invalid ID | DELETE `/pickup-point-route/99999/force-delete` → `onlyTrashed()->findOrFail(99999)` → 404 | — | — | ⬜ |
| TC-N33 | Missing both_side_fare in same-point mode | `allowOneSide=false + allowDifferentPickupDrop=false` → both_side_fare required | — | — | ⬜ |
| TC-N34 | Missing pickup_drop_fare in diff-point mode | `allowOneSide=false + allowDifferentPickupDrop=true` → pickup_drop_fare required | — | — | ⬜ |
| TC-N35 | `toggleRouteStatus` URL returns 404 | POST `/pickup-point-route/route/{routeId}/toggle-status` → route exists but controller method NOT defined → 404 | — | — | ⬜ |
| TC-N36 | Arrival time invalid hour (25:00) | `date_format:H:i` fails — "does not match the format H:i" | — | — | ⬜ |
| TC-N37 | Departure time invalid minute (07:60) | `date_format:H:i` fails | — | — | ⬜ |
| TC-N38 | Create with inactive route_id via API bypass | Manually POST with inactive route_id → validation passes → null pointer error in controller | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Route Deletion Cascades to PickupPointRoute | DDL CASCADE → tpt_route deleted → all pickupPointRoute records for that route cascade deleted | — | — | ⬜ |
| TC-D02 | A | PickupPoint Deletion Cascades | DDL CASCADE → pickup_point deleted → assignment records cascade deleted | — | — | ⬜ |
| TC-D03 | B | Shift Deletion Cascades | DDL CASCADE → shift deleted → assignments cascade deleted | — | — | ⬜ |
| TC-D04 | C | Route Geometry Updates After Create | Creating a PickupPointRoute with lat/lng → tpt_route.route_geometry regenerated with correct JSON | — | — | ⬜ |
| TC-D05 | D | Route Geometry Updates After Delete | Deleting → geometry regenerated without removed point | — | — | ⬜ |
| TC-D06 | E | Route Geometry Updates After Restore | Restoring → geometry regenerated with restored point | — | — | ⬜ |
| TC-D07 | F | Route Geometry Set to Null When No Points | Delete last PickupPointRoute → geometry set to NULL | — | — | ⬜ |
| TC-D08 | G | Route Geometry Stores Correct Ordinal Order | Points ordered by ordinal in JSON array maintained by `orderBy('ordinal')` | — | — | ⬜ |
| TC-D09 | H | Concurrent Reorder Requests | Rapid drag-and-drop triggers multiple AJAX calls → no data corruption; last ordinal wins | — | — | ⬜ |
| TC-D10 | I | Unique Key Violation on Duplicate PickupPoint | Creating existing route+pickupPoint combo → DB integrity violation caught by try/catch → back with error | — | — | ⬜ |
| TC-D11 | J | Transaction Rollback on Exception in Store | Force exception after partial inserts → `DB::rollBack()` → no rows created | — | — | ⬜ |
| TC-D12 | K | Reorder Does NOT Call updateRouteGeometry (GAP) | After reorder, route_geometry reflects OLD ordinal order — out of sync | — | — | ⬜ |
| TC-D13 | L | Settings Change Affects Fare Validation | Toggle settings → validation rules change accordingly without code change | — | — | ⬜ |
| TC-D14 | M | Store with 50+ Rows (Bulk Performance) | Submit 50+ rows → all created; ordinal auto-increment works; no timeout | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Action Buttons Protected | index: `@canany(['tenant.pickup-point-route.edit', 'tenant.pickup-point-route.delete'])` for action column | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Gate::authorize() Before State Changes | show(), create(), edit(), update(), destroy(), trashed(), restore(), forceDelete(), toggleStatus(), reorder() all have Gate first | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — NO activityLog calls | ZERO `activityLog()` calls across all 6 mutation methods | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — DB::beginTransaction() for CRUD | store/update/destroy/restore/forceDelete all wrapped in transaction | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Geometry auto-update after ALL mutations | updateRouteGeometry() called after store/update/destroy/restore/forceDelete (NOT reorder) | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — timeToMinutes() conversion | store() and update() convert H:i to integer minutes | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — pickup_drop from Route NOT Request | store() line 148 and update() line 249 use `$route->pickup_drop` | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — forceDelete uses onlyTrashed() | forceDelete() line 358: `PickupPointRoute::onlyTrashed()->findOrFail($id)` — cannot force-delete active records | — | — | ◌ |
| TC-CR09 | CR | P1 | Controller — Standalone index() has NO Gate | `TransportMasterController::index() ? pickupPointRoutesQuery() [Tab-based]()` line 18: no `Gate::authorize()` call | — | — | ◌ |
| TC-CR10 | CR | P1 | Controller — reorder() accepts arbitrary input | reorder() line 442: `foreach ($request->order as $item)` — no validation, no exists check | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — authorize() matches controller gates | POST → `tenant.pickup-point-route.create`; PUT/PATCH → `tenant.pickup-point-route.update` | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — rules() match DDL constraints | rows.*.pickup_point_id `exists:tpt_pickup_points,id` matches FK; date_format:H:i matches INT storage | — | — | ◌ |
| TC-CR13 | CR | P1 | Request — Custom validation with withValidator | 4 validations: duplicate in-request, duplicate-vs-DB (store-only), arrival<departure, fare-by-settings | — | — | ◌ |
| TC-CR14 | CR | P1 | Model — Table Name and Fillable | `$table = 'tpt_pickup_points_route_jnt'`; 12 fillable fields | — | — | ◌ |
| TC-CR15 | CR | P1 | Model — Casts | 8 casts: is_active→boolean, distances/fares→decimal:2, times→integer, ordinal→integer | — | — | ◌ |
| TC-CR16 | CR | P1 | Model — Default Attributes | `is_active => true`, `ordinal => 1`, `pickup_drop => 'Pickup'` (all overridden by controller) | — | — | ◌ |
| TC-CR17 | CR | P1 | Model — Relationships | 3 BelongsTo: route(), pickupPoint(), shift() | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — Resource + Additional Routes | web.php: `Route::resource('pickup-point-route')` + 6 additional routes (trash, restore, forceDelete, toggleStatus, toggleRouteStatus, reorder, getRoutesByShift) | — | — | ◌ |
| TC-CR19 | CR | P1 | Routes — Route Names Use `transport.pickup-point-route.*` | Consistent prefix | — | — | ◌ |
| TC-CR20 | CR | P1 | View — Table Columns Match Requirements | Drag Handle, Route, Pickup Point, Arrival Time, Departure Time, Total Distance, Estimated Time, Status, Action | — | — | ◌ |
| TC-CR21 | CR | P1 | View — Filter Controls Present | Search input, Route dropdown, Shift dropdown, Pickup/Drop dropdown, Status dropdown, Search + Reset buttons | — | — | ◌ |
| TC-CR22 | CR | P1 | View — Show Page Displays All Fields | Route, Shift, Pickup/Drop badge, Pickup Point, Arrival/Departure (time inputs), Distance, Est. Time, Fare, Active (checkbox disabled) | — | — | ◌ |
| TC-CR23 | CR | P1 | View — SortableJS Drag-and-Drop | `Sortable` on `#sortableBody` with `.drag-handle`; onEnd POSTs to reorder route | — | — | ◌ |
| TC-CR24 | CR | P1 | View — Create Blade Uses Dynamic Fare Columns | `@if($allowOneSide)` shows Pickup/Drop Fare; `@if($allowDifferentPickupDrop)` shows Both Fare | — | — | ◌ |
| TC-CR25 | CR | P1 | View — isset()/optional() for Null Relationships | `$item->route->name ?? ''`, `$item->pickupPoint->name ?? '-'` throughout | — | — | ◌ |
| TC-CR26 | CR | P1 | View — Pagination Appends Tab Parameter | `$pickupPointRoutes->appends(['tab' => request('tab', 'assign_stops')])->links()` — but standalone index uses `->get()` | — | — | ◌ |
| TC-CR27 | CR | P1 | DDL — Unique Key for Route+PickupPoint | `uq_pickupPointRoute_route_pickupPoint` on (route_id, pickup_point_id) | — | — | ◌ |
| TC-CR28 | CR | P1 | DDL — Composite Index for Ordinal Ordering | `idx_pprj_route_ordinal` on (route_id, ordinal) | — | — | ◌ |
| TC-CR29 | CR | P1 | DDL — All ON DELETE CASCADE | All 3 FKs use CASCADE | — | — | ◌ |
| TC-CR30 | CR | P1 | GAP — No activityLog in Controller | ZERO activityLog calls across ALL mutation methods | — | — | ◌ |
| TC-CR31 | CR | P1 | GAP — Controller uses destroy() without is_active=false | Direct `->delete()`, no `update(['is_active'=>0])` first | — | — | ◌ |
| TC-CR32 | CR | P1 | GAP — forceDelete uses onlyTrashed() | Should use withTrashed(); cannot force-delete active records | — | — | ◌ |
| TC-CR33 | CR | P1 | GAP — Standalone index() has no gate | Accessible without permission check | — | — | ◌ |
| TC-CR34 | CR | P1 | GAP — reorder() input not validated | No validation on $request->order; invalid IDs silently ignored | — | — | ◌ |
| TC-CR35 | CR | P1 | GAP — Store route query only selects id+pickup_drop with is_active=1 | If route inactive, $route null → null pointer | — | — | ◌ |
| TC-CR36 | CR | P1 | Policy — Has separate status() gate not used by controller | toggleStatus() uses edit, not status | — | — | ◌ |
| TC-CR37 | CR | P1 | GAP — No activityLog after store/create | activityLog() NEVER called after successful commit | — | — | ◌ |
| TC-CR38 | CR | P1 | GAP — No activityLog after update/destroy/restore/forceDelete | All 4 methods skip activityLog() | — | — | ◌ |
| TC-CR39 | CR | P1 | GAP — No activityLog after toggleStatus | Status toggles unlogged | — | — | ◌ |
| TC-CR40 | CR | P2 | GAP — reorder() missing geometry update | After reorder, route_geometry reflects old ordinal order | — | — | ◌ |
| TC-CR41 | CR | P2 | GAP — show() uses first() not findOrFail() | Invalid ID returns null → 500 error in view | — | — | ◌ |
| TC-CR42 | CR | P2 | GAP — edit() uses first() not findOrFail() | Invalid ID returns null → 500 error in view | — | — | ◌ |
| TC-CR43 | CR | P2 | GAP — toggleRouteStatus() route defined but method missing | Route exists, calling it returns 404 | — | — | ◌ |
| TC-CR44 | CR | P2 | GAP — store() has no controller-level Gate | Only FormRequest authorize guards store() | — | — | ◌ |
| TC-CR45 | CR | P2 | GAP — getRoutesByShift() has no Gate | Any authenticated user can call AJAX endpoint | — | — | ◌ |
| TC-CR46 | CR | P2 | GAP — Settings evaluated differently in Controller vs Request | Controller normalizeBoolean includes 'ture'; Request doesn't | — | — | ◌ |
| TC-CR47 | CR | P2 | GAP — Duplicate DB check only on store, not update | Update can assign duplicate pickup_point_id on same route | — | — | ◌ |
| TC-CR48 | CR | P2 | GAP — No is_system_defined protection | All records deletable/editable | — | — | ◌ |
| TC-CR49 | CR | P2 | GAP — Force delete reuses delete permission | forceDelete uses `tenant.pickup-point-route.delete` (no separate forceDelete permission check in controller) | — | — | ◌ |
| TC-CR50 | CR | P2 | GAP — Success messages hardcoded, not translatable | 5 success messages are plain English strings | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Assign Stops Tab Loads Inside Transport Master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with all permissions | Dashboard loads |
| 2 | Expand "Transport" → Click "Transport Master" | URL: `/transport/master` |
| 3 | Click "Assign Stops to Route" tab | URL updates to `/transport/master?tab=assign_stops`; tab-pane visible |
| 4 | Check filter bar | Search input, Route dropdown, Shift dropdown, Pickup/Drop dropdown, Status dropdown, Search + Reset buttons |
| 5 | Check table headers | Drag Handle (#), Route, Pickup Point, Arrival Time, Departure Time, Total Distance, Estimated Time, Status, Action |
| 6 | Check drag handle column | `fa-grip-vertical` icon present in first column for sorting |
| 7 | If records exist, check action buttons | View (eye), Edit (pencil), Delete (trash), status toggle switch per permissions |
| 8 | **Verify CODE-TRACE**: TransportMasterController@index() line 28–41 uses `Gate::any()` with 11 permissions | Page loads for authorized users |
| 9 | **Verify CODE-TRACE**: Line 75 calls `$this->pickupPointRoutesQuery($request)->paginate(10)->withQueryString()` | Data loads with pagination |
| 10 | **Verify CODE-TRACE**: pickupPointRoutesQuery() line 260 eager-loads route, pickupPoint, shift | N+1 query prevented |

### TC-P02: Create Assign Stops — Single Row

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Assign Stops tab | Tab loaded |
| 2 | Click "Add" button | Navigate to `/pickup-point-route/create` — full-page create form |
| 3 | Select Shift from dropdown | JS event fires → AJAX loads routes for this shift |
| 4 | Select Route from dynamically populated dropdown | Route dropdown shows only routes for selected shift |
| 5 | Click "+ Add Row" | A new table row appears with Pickup Point dropdown, Arrival/Departure time inputs, Distance, Est. Time, Fare, Active checkbox, Remove button |
| 6 | Select Pickup Point | Select an active pickup point |
| 7 | Enter Arrival: `08:30`, Departure: `08:35` | Time inputs filled |
| 8 | Enter Distance: `5.5`, Est. Time: `15` | Numeric fields filled |
| 9 | Leave Active checked | Checkbox checked |
| 10 | Click "Save Pickup Point Route" | POST `/pickup-point-route` with rows[0] data |
| 11 | **Verify CODE-TRACE**: Gate check in PickupPointRouteRequest::authorize() line 14 | `Gate::allows('tenant.pickup-point-route.create')` |
| 12 | **Verify CODE-TRACE**: Request rules validate route_id, shift_id, rows.*.pickup_point_id | All required rules pass |
| 13 | **Verify CODE-TRACE**: Request withValidator fires 4 custom validations | No duplicates, arrival<departure, fare ok |
| 14 | **Verify CODE-TRACE**: store() line 108 DB::beginTransaction() starts | Transaction active |
| 15 | **Verify CODE-TRACE**: store() line 114–116: `$maxOrdinal = PickupPointRoute::max(...) ?? 0` | Returns 0 if first record |
| 16 | **Verify CODE-TRACE**: store() line 148: `pickup_drop` taken from Route table | `$route->pickup_drop` stored |
| 17 | **Verify CODE-TRACE**: store() line 152–154: `timeToMinutes('08:30')` = 510 | Arrival stored as 510 |
| 18 | **Verify CODE-TRACE**: store() line 156–158: `timeToMinutes('08:35')` = 515 | Departure stored as 515 |
| 19 | **Verify CODE-TRACE**: store() line 170: DB::commit() | Transaction committed |
| 20 | **Verify CODE-TRACE**: store() line 171: `updateRouteGeometry($routeId)` called | Geometry rebuilt |
| 21 | **Verify CODE-TRACE**: store() line 173–175: redirect to transport-master.index with flash | Redirect + success message |
| 22 | DB check: `SELECT * FROM tpt_pickup_points_route_jnt WHERE route_id=X AND pickup_point_id=Y` | Record exists with correct shift_id, ordinal=1, arrival_time=510, departure_time=515, pickup_drop matches route |
| 23 | Geometry check: `SELECT route_geometry FROM tpt_route WHERE id=X` | route_geometry contains JSON array with {lat, lng} of the pickup point |

### TC-P05: Time Conversion on Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Set Arrival: `09:15` | Input shows 09:15 |
| 3 | Set Departure: `09:20` | Input shows 09:20 |
| 4 | Submit form | Data sent with `arrival_time=09:15` |
| 5 | **Verify CODE-TRACE**: timeToMinutes("09:15") line 186–190 | `explode(':', "09:15")` = ["09","15"] → (9*60)+15 = 555 |
| 6 | DB check: `SELECT arrival_time, departure_time FROM tpt_pickup_points_route_jnt` | arrival_time=555, departure_time=560 |
| 7 | View the record | Show page displays `09:15` and `09:20` (minutesToTime converts back) |

### TC-P07: pickup_drop Inherited From Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure Route R1 has `pickup_drop='Drop'` | Route configured as Drop type |
| 2 | Navigate to create form | Form loads |
| 3 | Select Route=R1 | Route selected |
| 4 | Add row with any pickup point | Row filled |
| 5 | Submit form | POST to store |
| 6 | **Verify CODE-TRACE**: store() line 137–140: `Route::select('id','pickup_drop')->where('id',$routeId)->where('is_active',1)->first()` | `$route->pickup_drop` = "Drop" |
| 7 | **Verify CODE-TRACE**: store() line 148: `'pickup_drop' => $route->pickup_drop` | Stored as "Drop" |
| 8 | DB check: `SELECT pickup_drop FROM tpt_pickup_points_route_jnt` | "Drop" |
| 9 | **Note**: pickup_drop is NEVER submitted from the form — always inherited | Design intent |

### TC-P11: Soft Delete Assign Stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops tab | List visible |
| 2 | Note the record's route_id and pickup_point | Record exists |
| 3 | Click Delete (trash) icon | Confirm dialog (if any) |
| 4 | Confirm deletion | DELETE `/pickup-point-route/{id}` |
| 5 | **Verify CODE-TRACE**: destroy() line 286: `Gate::authorize('tenant.pickup-point-route.delete')` | Authorized |
| 6 | **Verify CODE-TRACE**: destroy() line 288: `DB::beginTransaction()` | Transaction starts |
| 7 | **Verify CODE-TRACE**: destroy() line 291: `PickupPointRoute::findOrFail($id)` | Record found |
| 8 | **Verify CODE-TRACE**: destroy() line 292: `$routeId = $pickupRoute->route_id` saved | For geometry |
| 9 | **Verify CODE-TRACE**: destroy() line 294: `$pickupRoute->delete()` | Soft delete — sets deleted_at |
| 10 | **Verify CODE-TRACE**: destroy() line 296: `DB::commit()` | Committed |
| 11 | **Verify CODE-TRACE**: destroy() line 297: `updateRouteGeometry($routeId)` | Geometry recalculated |
| 12 | Verify redirect | Redirected to `/transport/master?tab=assign_stops` |
| 13 | Verify flash message | "Pickup point removed successfully." |
| 14 | DB check: `SELECT deleted_at FROM tpt_pickup_points_route_jnt WHERE id={id}` | deleted_at IS NOT NULL |
| 15 | **GAP check**: `SELECT is_active FROM tpt_pickup_points_route_jnt WHERE id={id}` | is_active=1 (NOT set to 0 before delete) |
| 16 | Record no longer in main list | Row not visible |
| 17 | Click Trash button → verify record in trash | URL: `/pickup-point-route/trash/view`; record visible |

### TC-P12: Trash Page Shows Deleted Records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/pickup-point-route/trash/view` | Trash page with breadcrumb |
| 2 | **Verify CODE-TRACE**: trashed() line 315: `Gate::authorize('tenant.pickup-point-route.view')` | Authorized |
| 3 | **Verify CODE-TRACE**: trashed() line 317: `PickupPointRoute::onlyTrashed()->paginate(10)` | 10 per page, only soft-deleted |
| 4 | Check table columns | Route, Pickup Point, Ordinal, Action |
| 5 | If records exist, check action buttons | Restore and Force Delete buttons visible (if permissions granted) |
| 6 | Test Restore | Click Restore → record restored; redirected to transport-master.index |
| 7 | Test Force Delete on remaining trashed record | Click Force Delete → record permanently removed; redirected |

### TC-P15: Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops tab | Stop row visible |
| 2 | Click the status toggle switch | AJAX POST to `/pickup-point-route/{pickupPointRoute}/toggle-status` |
| 3 | **Verify CODE-TRACE**: toggleStatus() line 381: `Gate::authorize('tenant.pickup-point-route.edit')` | Authorized (uses edit, NOT status) |
| 4 | **Verify CODE-TRACE**: toggleStatus() line 383–385: `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 5 | **Verify CODE-TRACE**: toggleStatus() line 387: `$pickupPointRoute->is_active = $request->boolean('is_active')` | Boolean cast |
| 6 | **Verify CODE-TRACE**: toggleStatus() line 389: `$pickupPointRoute->save()` | Returns true |
| 7 | **Verify CODE-TRACE**: toggleStatus() line 390–392: JSON success response | `{success: true, message: 'Pickup Point Route Status update'}` |
| 8 | **Verify**: is_active changed in DB | `SELECT is_active FROM tpt_pickup_points_route_jnt WHERE id=X` — flipped value |

### TC-P18: Reorder via Drag and Drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops tab with 3+ records sorted by ordinal | Records displayed in ordinal order |
| 2 | Click and drag a row's grip handle to a new position | Row visually moves; SortableJS animation plays |
| 3 | On drop, check AJAX request | POST `/pickup-point-route/reorder` with `{order: [{id: 1, ordinal: 3}, {id: 2, ordinal: 1}, {id: 3, ordinal: 2}]}` |
| 4 | **Verify CODE-TRACE**: reorder() line 440: `Gate::authorize('tenant.pickup-point-route.update')` | Authorized |
| 5 | **Verify CODE-TRACE**: reorder() line 442–445: 3 iterations of `PickupPointRoute::where('id',id)->update(['ordinal'=>ordinal])` | 3 updates |
| 6 | **Verify CODE-TRACE**: reorder() line 447: JSON response | `{success: true}` |
| 7 | DB check: `SELECT id, ordinal FROM tpt_pickup_points_route_jnt WHERE route_id=X ORDER BY ordinal` | Ordinals updated to match new order |
| 8 | **GAP check**: `SELECT route_geometry FROM tpt_route WHERE id=X` | route_geometry reflects OLD order — **NOT updated by reorder()** |
| 9 | Verify toast notification | "Order updated successfully" toast |

### TC-P24: TransportMaster Tab Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12+ PickupPointRoutes for the same route+shift | 12 records |
| 2 | Navigate to TransportMaster → Assign Stops tab | Tab loaded |
| 3 | Select Route, Shift, Pickup/Drop (mandatory tab filters) | Filters applied |
| 4 | **Verify CODE-TRACE**: TransportMasterController line 75: `->paginate(10)->withQueryString()` | 10 records on page 1 |
| 5 | **Verify**: Pagination links visible | `->links()` rendered |
| 6 | Click page 2 | Records 11–12 shown |
| 7 | **Verify CODE-TRACE**: pickupPointRoutesQuery() line 265 tab check | `$request->tab === 'assign_stops'` ensures correct query |

### TC-P25: Standalone Index With All 3 Filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/pickup-point-route?route_id=1&shift_id=1&pickup_drop=Pickup` | Standalone index |
| 2 | **Verify CODE-TRACE**: index() line 24: all 3 params present | `$request->route_id && $request->shift_id && $request->pickup_drop` = true |
| 3 | **Verify CODE-TRACE**: index() line 25–28: 3 where clauses applied | `->where('route_id',1)->where('shift_id',1)->where('pickup_drop','Pickup')` |
| 4 | **Verify CODE-TRACE**: index() line 35: `->get()` | All matching rows returned (no pagination) |
| 5 | **GAP check**: index() line 18: no Gate::authorize() | Page loads without permission check |
| 6 | **GAP check**: index() line 20–21: `Route::all()` and `Shift::all()` | Inactive routes/shifts also shown in dropdowns |

### TC-N08: Duplicate pickup_point in same request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift, Route | Valid selections |
| 3 | Add 2 rows | Both rows visible |
| 4 | Row 1: Select Pickup Point = "Main Gate" | pickup_point_id = X |
| 5 | Row 2: Select Pickup Point = "Main Gate" (same) | pickup_point_id = X |
| 6 | Click Save | Form submission |
| 7 | **Verify CODE-TRACE**: Request line 76: `$pickupPoints = array_column($rows, 'pickup_point_id')` | [X, X] |
| 8 | **Verify CODE-TRACE**: Request line 78: `count($pickupPoints) !== count(array_unique($pickupPoints))` | true (2 !== 1) |
| 9 | **Verify CODE-TRACE**: Request line 79–82: error added to validator | "Same pickup point cannot be added more than once." |
| 10 | **Verify**: No records created | DB unchanged |

### TC-N10: Arrival Time After Departure Time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Add a row with Arrival: `09:30` and Departure: `09:25` | Departure is BEFORE arrival |
| 3 | Submit form | `withValidator` fires → validation fails |
| 4 | **Verify CODE-TRACE**: Request line 112–123: foreach checks `$row['arrival_time'] > $row['departure_time']` | true for "09:30" > "09:25" (string comparison works in H:i) |
| 5 | **Verify CODE-TRACE**: Request line 118–121: error added on rows.0.departure_time | "Departure time must be after arrival time." |
| 6 | Verify form NOT submitted | Still on create page; data preserved |

### TC-N19: Restore Non-Deleted Record (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active PickupPointRoute (not deleted) | id=X, deleted_at=NULL |
| 2 | Call restore(X) | Controller hit |
| 3 | **Verify CODE-TRACE**: restore() line 324: `Gate::authorize('tenant.pickup-point-route.restore')` | Authorized |
| 4 | **Verify CODE-TRACE**: restore() line 329: `PickupPointRoute::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 5 | Active record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 6 | **Verify**: 404 error | "No query results" |

### TC-N20: Force Delete Non-Trashed Record (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active PickupPointRoute (not deleted) | id=X, deleted_at=NULL |
| 2 | Call forceDelete(X) via DELETE or trash action | Controller hit |
| 3 | **Verify CODE-TRACE**: forceDelete() line 353: `Gate::authorize('tenant.pickup-point-route.delete')` | Authorized (uses delete permission) |
| 4 | **Verify CODE-TRACE**: forceDelete() line 358: `PickupPointRoute::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 5 | Active record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 6 | **Verify**: 404 error | "No query results" |
| 7 | **Workaround**: Must soft-delete first, then force-delete | Two-step process |
| 8 | **GAP**: Should use `withTrashed()` like RouteController pattern | Current behavior is a usability bug |

### TC-N27: is_active Unchecked on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit form for an active record | `is_active` checkbox is checked |
| 2 | Uncheck `is_active` checkbox | Checkbox unchecked |
| 3 | Submit form | PUT with is_active field absent (checkbox not sent) |
| 4 | **Verify CODE-TRACE**: update() line 265: `$request->has('is_active')` | Returns false → is_active set to 0 |
| 5 | DB check: `SELECT is_active FROM tpt_pickup_points_route_jnt WHERE id=X` | is_active = 0 |

### TC-N29: Store with Inactive Route (Null Pointer Bug)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Route R1 to `is_active=0` | Route inactive |
| 2 | Navigate to create form | Form shows active routes only → R1 NOT visible |
| 3 | Manually POST with `route_id=R1` (bypass UI) | POST to store |
| 4 | **Verify CODE-TRACE**: Request line 23: `route_id: exists:tpt_route,id` | Validation passes (exists ignores is_active) |
| 5 | **Verify CODE-TRACE**: Controller line 137–140: `Route::select(...)->where('id',$routeId)->where('is_active',1)->first()` | `$route = null` (route not active) |
| 6 | **Verify CODE-TRACE**: Controller line 148: `'pickup_drop' => $route->pickup_drop` | **Error**: `Call to a member function pickup_drop on null` |
| 7 | **Verify CODE-TRACE**: catch block line 177–183: `DB::rollBack()` | Transaction rolled back |
| 8 | Error returned: "Something went wrong: Call to a member function pickup_drop on null" | 500 error displayed |

### TC-N30: All Rows Skipped (Misleading Success)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 3 rows | 3 rows visible |
| 2 | Leave ALL rows with empty pickup_point_id | All rows skipped |
| 3 | Click Save | POST submitted |
| 4 | **Verify**: Request validation: `rows.*.pickup_point_id: required` fails first | Validation error — **never reaches controller** |
| 5 | **Note**: TC-N30 scenario only possible if validation is bypassed | Controller skip is dead code for happy path |
| 6 | **If validation bypassed**: Controller foreach loop does 0 creates, DB::commit() still called | Success message "Pickup Point Routes added successfully." shown but NOTHING created |

### TC-N35: toggleRouteStatus Route Returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `/pickup-point-route/route/1/toggle-status` | Route registered in web.php line 105 |
| 2 | Check routes list: `php artisan route:list | grep toggleRouteStatus` | Route exists |
| 3 | Controller `PickupPointRouteController` has NO `toggleRouteStatus()` method | Method NOT defined |
| 4 | Call the URL | 404 — "Route not found" or controller method missing error |

### TC-CR30: GAP — No activityLog in Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `activityLog` in `PickupPointRouteController.php` | No matches — zero activity logging |
| 2 | Create a new pickup point route | Record created but no `activity_log` entry generated |
| 3 | DB check: `SELECT * FROM activity_log WHERE log_name LIKE '%PickupPointRoute%'` | No entries found |
| 4 | Compare with RouteController | RouteController has `activityLog(...)` calls after every CRUD operation |
| 5 | Document as GAP | All create/update/delete/restore/forceDelete/toggleStatus events are unlogged |

### TC-CR33: GAP — Standalone index() Has No Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT any `tenant.pickup-point-route.*` permissions | Dashboard loads |
| 2 | Navigate to `/transport/master` | Assign Stops tab is hidden |
| 3 | Directly navigate to `/pickup-point-route` | Page loads WITHOUT 403 — no gate check |
| 4 | Document as GAP | Standalone index() at `PickupPointRouteController.php:18` has no `Gate::authorize()` call |

### TC-CR37: GAP — No activityLog After Store/Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | Dashboard loads |
| 2 | Create a new pickup point route via store() | POST to `/pickup-point-route` with valid data |
| 3 | Verify record created | Record exists in DB |
| 4 | Query `activity_log` for subject_type=PickupPointRoute and event=created | **No entry found** |
| 5 | Compare with RouteController's store() | RouteController calls `activityLog($record, 'Stored', ...)` after create |
| 6 | Document as GAP | All create operations are unlogged |

### TC-CR38: GAP — No activityLog After Update/Destroy/Restore/ForceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | Dashboard loads |
| 2 | Execute update() on an existing record | PUT to `/pickup-point-route/{id}` — record updated |
| 3 | Query `activity_log` for updated event | **No entry found** |
| 4 | Execute destroy() on an existing record | DELETE to `/pickup-point-route/{id}` — soft deleted |
| 5 | Query `activity_log` for trashed/deleted event | **No entry found** |
| 6 | Execute restore() on a trashed record | GET to `/pickup-point-route/{id}/restore` — restored |
| 7 | Query `activity_log` for restored event | **No entry found** |
| 8 | Execute forceDelete() on a trashed record | DELETE to `/pickup-point-route/{id}/force-delete` — permanently deleted |
| 9 | Query `activity_log` for deleted event | **No entry found** |
| 10 | Document as GAP | All 4 mutation methods (update, destroy, restore, forceDelete) skip activityLog() |

### TC-CR39: GAP — No activityLog After toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | Dashboard loads |
| 2 | Toggle status on a pickup point route | POST to `/pickup-point-route/{id}/toggle-status` — JSON success |
| 3 | Verify `is_active` changed in DB | Record's is_active flipped |
| 4 | Query `activity_log` for event=toggled | **No entry found** |
| 5 | Document as GAP | Status toggles are unlogged |

### TC-CR40: GAP — reorder() Missing Geometry Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 stops for route R1 with points having lat/lng | 3 records, ordinals 1,2,3 |
| 2 | Check `route_geometry` for route R1 | Points in order [A, B, C] |
| 3 | Drag stop C to position 1 (ordinal 1) | Reorder completes |
| 4 | **Verify CODE-TRACE**: reorder() line 438–448: NO `updateRouteGeometry()` call | Not called |
| 5 | DB check: `SELECT ordinal FROM tpt_pickup_points_route_jnt WHERE route_id=R1 ORDER BY ordinal` | Now C(1), A(2), B(3) |
| 6 | DB check: `SELECT route_geometry FROM tpt_route WHERE id=R1` | Still shows [A, B, C] — **OUT OF SYNC** |
| 7 | Document as GAP | Geometry must be recalculated after reorder |

### TC-CR41: GAP — show() Uses first() Not findOrFail()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open PickupPointRouteController.php line 49–52 | `->where('id', $id)->orderBy('ordinal')->first()` |
| 2 | Call GET `/pickup-point-route/99999` | Non-existent ID |
| 3 | Controller line 49–52 executes | `$pickupPointRoute = null` |
| 4 | View receives null `$pickupPointRoute` | 500 error when accessing `$pickupPointRoute->route` |
| 5 | Compare with edit() which has same pattern | Both have this bug |

### TC-CR43: GAP — toggleRouteStatus Route Defined But Method Missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` line 105 | `Route::post('/pickup-point-route/route/{routeId}/toggle-status', [PickupPointRouteController::class, 'toggleRouteStatus'])->name('pickup-point-route.toggleRouteStatus')` |
| 2 | Open `PickupPointRouteController.php` | Search for `toggleRouteStatus` — **NOT FOUND** |
| 3 | Call the route via POST | 404 error |
| 4 | Document as GAP | Route registered but method never implemented |

### TC-D04: Route Geometry Updates After Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPoint for route R1 with lat=28.61, lng=77.23 | Valid coordinates |
| 2 | Check current `route_geometry` for route R1 | Previous state |
| 3 | Create new PickupPointRoute for route R1 with this pickup point | store() called |
| 4 | **Verify CODE-TRACE**: updateRouteGeometry() line 403–436 called after commit | `$this->updateRouteGeometry($routeId)` at line 171 |
| 5 | **Verify CODE-TRACE**: line 406–418: Queries all PickupPointRoute for route R1 with whereHas(lat+lng) | Builds points array |
| 6 | **Verify CODE-TRACE**: line 433–435: `Route::update(['route_geometry' => json_encode($points)])` | JSON updated |
| 7 | DB check: `SELECT route_geometry FROM tpt_route WHERE id=R1` | JSON includes new point's {lat, lng} |

### TC-D11: Transaction Rollback on Exception in Store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute with route_id=R1 that causes exception | e.g., inactive route as in TC-N29 |
| 2 | **Verify CODE-TRACE**: store() line 108: `DB::beginTransaction()` | Transaction started |
| 3 | Some rows may have been inserted before exception | Partial inserts |
| 4 | **Verify CODE-TRACE**: catch block line 177–183: `DB::rollBack()` called | All DB changes reverted |
| 5 | **Verify**: No rows created despite partial inserts | COUNT unchanged |
| 6 | **Verify**: Error returned to user | "Something went wrong: ..." with exception message |

### TC-D12: Reorder Does NOT Call updateRouteGeometry (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `reorder()` method lines 438–448 | Iterates and updates ordinals |
| 2 | Search for `updateRouteGeometry` inside reorder() | **NOT FOUND** |
| 3 | **Impact**: Route geometry JSON reflects OLD ordinal order | Geometry out of sync |
| 4 | Steps to reproduce: 3 stops A(1), B(2), C(3) → reorder C→1 → ordinals updated to C(1), A(2), B(3) → geometry still [A, B, C] | **Verifiable GAP** |

### TC-CR16: Different is_active Handling — store() vs update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | **store()** line 166: `'is_active' => !empty($row['is_active']) ? 1 : 0` | `!empty('0')` = false → 0 |
| 2 | **update()** line 265: `'is_active' => $request->has('is_active') ? 1 : 0` | `$request->has('0')` = true → 1 |
| 3 | **Test store**: Submit is_active="0" | `!empty("0")` = false → is_active=0 ✓ |
| 4 | **Test update**: Submit is_active="0" | `$request->has("0")` = true → is_active=1 ✗ |
| 5 | **Impact**: Update treats explicitly sent "0" as 1 (active) | Inconsistent with store behavior |

### TC-CR22: show() Null Handling Gap

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:49–52` | `$pickupPointRoute = PickupPointRoute::with(...)->where('id', $id)->first()` |
| 2 | Note: NO `findOrFail()`, NO null check | Just `first()` |
| 3 | Call with invalid ID | `$pickupPointRoute = null` |
| 4 | View tries `$pickupPointRoute->route->name` | `Call to a member function on null` — 500 error |
| 5 | **Fix recommendation**: Use `findOrFail($id)` or add null check before passing to view | Match update()/destroy() pattern |

### TC-CR47: Duplicate DB Check Only on Store (Not Update)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteRequest.php:88` | `if (!$isUpdate)` — guard for store-only |
| 2 | **On store**: Duplicate pickup_point_id for route+shift is checked against DB | Validation error |
| 3 | **On update**: Same check is SKIPPED (only runs for POST) | No validation |
| 4 | Update can assign pickup_point_id that already exists for same route+shift | **Data integrity risk** — two stops with same point |
| 5 | DB unique key `uq_pickupPointRoute_route_pickupPoint` prevents full duplicate | But update target is different record, so DB constraint doesn't catch it |

### TC-P30: Minimal Create — Only pickup_point_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift, Route | Valid |
| 3 | Add 1 row | Row visible |
| 4 | Select Pickup Point only | pickup_point_id set |
| 5 | Leave arrival, departure, distance, est time, fare ALL empty | Optional fields = null/0 |
| 6 | Leave Active = default (checked) | is_active = 1 |
| 7 | Click Save | POST to store |
| 8 | **Verify CODE-TRACE**: Controller line 120–122: `empty($row['pickup_point_id'])` = false | Row processed |
| 9 | **Verify CODE-TRACE**: Controller line 126–127: `$pickupDropFare = 0; $bothSideFare = 0` | Defaults |
| 10 | **Verify CODE-TRACE**: Controller line 152–154: `!empty($row['arrival_time'])` = false | `arrival_time` = null |
| 11 | **Verify CODE-TRACE**: Controller line 156–158: `!empty($row['departure_time'])` = false | `departure_time` = null |
| 12 | **Verify CODE-TRACE**: Controller line 160: `$row['total_distance'] ?? null` | total_distance = null |
| 13 | **Verify CODE-TRACE**: Controller line 161: `$row['estimated_time'] ?? null` | estimated_time = null |
| 14 | **Verify CODE-TRACE**: Controller line 129–131: `!empty($row['pickup_drop_fare'])` = false | `pickup_drop_fare` = 0 |
| 15 | **Verify CODE-TRACE**: Controller line 133–135: `!empty($row['both_side_fare'])` = false | `both_side_fare` = 0 |
| 16 | **Verify CODE-TRACE**: Controller line 166: `!empty($row['is_active'])` = true (default checked) | is_active = 1 |
| 17 | DB check: All fields correct | Record with null times, 0 fares, is_active=1 |

### TC-P31: getRoutesByShift AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Route R1 for shift S1, Route R2 for shift S1, R3 for different shift | Test data |
| 2 | Set R1 active, R2 active, R3 inactive | Mixed active/inactive |
| 3 | Call GET `/get-routes-by-shift/S1` | AJAX endpoint |
| 4 | **Verify CODE-TRACE**: getRoutesByShift() line 97–100: `Route::where('shift_id',S1)->where('is_active',1)->select('id','name')->get()` | Only R1 and R2 |
| 5 | Verify JSON response | `[{id: R1, name: "Route A"}, {id: R2, name: "Route B"}]` |
| 6 | **GAP check**: NO Gate::authorize() | Any authenticated user can call |

### TC-D07: Route Geometry Set to Null When No Points

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route R1 with multiple PickupPointRoutes having lat/lng | Geometry populated |
| 2 | Delete ALL PickupPointRoutes for route R1 | Last point removed |
| 3 | **Verify CODE-TRACE**: updateRouteGeometry() line 423: `$points->isEmpty()` = true | Empty collection |
| 4 | **Verify CODE-TRACE**: updateRouteGeometry() line 424–427: `Route::where('id', $routeId)->update(['route_geometry' => null])` | Geometry set to NULL |
| 5 | DB check: `SELECT route_geometry FROM tpt_route WHERE id=R1` | NULL |

### TC-CR18: Routes — web.php Analysis

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `routes/web.php` line 101 | `Route::resource('pickup-point-route', PickupPointRouteController::class)` — creates 7 RESTful routes |
| 2 | Open `routes/web.php` line 102 | `Route::get('/pickup-point-route/trash/view', ...)->name('pickup-point-route.trashed')` |
| 3 | Open `routes/web.php` line 103 | `Route::get('/pickup-point-route/{id}/restore', ...)->name('pickup-point-route.restore')` |
| 4 | Open `routes/web.php` line 104 | `Route::delete('/pickup-point-route/{id}/force-delete', ...)->name('pickup-point-route.forceDelete')` |
| 5 | Open `routes/web.php` line 105 | `Route::post('/pickup-point-route/route/{routeId}/toggle-status', ...)->name('pickup-point-route.toggleRouteStatus')` — **method missing from controller** |
| 6 | Open `routes/web.php` line 106 | `Route::post('pickup-point-route/reorder', ...)->name('pickup-point-route.reorder')` |
| 7 | Open `routes/web.php` line 91 | `Route::post('pickup-point-route/{pickupPointRoute}/toggle-status', ...)->name('pickup-point-route.toggleStatus')` |
| 8 | Open `routes/web.php` line 108 | `Route::get('get-routes-by-shift/{shiftId}', ...)->name('routes.by-shift')` |
| 9 | **Total**: 7 (resource) + 7 (additional) = 14 routes defined | All use `transport.` prefix (namespaced within route group) |

### TC-CR49: Force Delete Reuses Delete Permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` line 286 | `Gate::authorize('tenant.pickup-point-route.delete')` |
| 2 | Open `forceDelete()` line 353 | `Gate::authorize('tenant.pickup-point-route.delete')` — **SAME permission** |
| 3 | Open `PickupPointRoutePolicy.php:69–72` | `forceDelete()` checks `tenant.pickup-point-route.forceDelete` |
| 4 | **GAP**: Controller bypasses the Policy's forceDelete permission | Controller reuses delete permission directly |
| 5 | **Implication**: User with delete can also forceDelete | No additional guard for permanent deletion |

### TC-BIZ-DEEP-52: ScopeActive Not Used in Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:44–47` | `scopeActive($query) { return $query->where('is_active', true); }` |
| 2 | Search all queries in `PickupPointRouteController.php` for `->active()` or `scopeActive` | **NOT USED** anywhere in controller |
| 3 | **Impact**: Index shows both active AND inactive stops | No default active filter applied |
| 4 | **Recommendation**: Use `->active()` scope where applicable | Scope exists but is dead code |

### TC-BIZ-DEEP-53: TransportMasterController Gate::any() Lists 11 Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportMasterController.php:28–41` | `Gate::any([...11 permissions...])` |
| 2 | Note: `tenant.pickup-point-route.viewAny` is one of 11 | Assign Stops tab guard |
| 3 | User without ANY of 11 permissions gets 403 | Authorization enforced at page level |
| 4 | User with only `tenant.vehicle.viewAny` can see page BUT NOT Assign Stops tab | Tab hidden via `@can` |

### TC-BIZ-DEEP-54: Tab Data Eager Loads 3 Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportMasterController.php:260` | `PickupPointRoute::with(['route', 'pickupPoint', 'shift'])` |
| 2 | Each PickupPointRoute has 3 related models fetched | Prevents N+1 queries |
| 3 | Order: `->orderBy('route_id')->orderBy('shift_id')->orderBy('ordinal')` | Triple-sort for grouped display |
| 4 | No select() constraint — all columns fetched from all 4 tables | Full model data |

### TC-BIZ-DEEP-55: Tab pickup_drop Filter Uses Stop_type on Related Table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportMasterController.php:288–291` | `whereHas('pickupPoint', fn($q) => $q->where('stop_type', $request->pickup_drop))` |
| 2 | pickup_drop on PickupPointRoute is from route table (Pickup/Drop) | But filter checks PickupPoint.stop_type |
| 3 | These are DIFFERENT fields on different tables | `pickupPointRoute.pickup_drop` (from route) vs `pickupPoint.stop_type` |
| 4 | **Potential inconsistency**: Filter might not match displayed data | Test: Route has pickup_drop="Drop" but its points have stop_type="Pickup" → filtered out even though pickup_drop column says "Drop" |

### TC-BIZ-DEEP-56: Tab Search Only Searches PickupPoint.Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportMasterController.php:268–274` | `whereHas('pickupPoint', fn => where('name','like','%search%'))` |
| 2 | Does NOT search route name, code, or shift name | Single-field search only |
| 3 | **Impact**: Search by route name returns no results | Only pickup point name matching |
| 4 | Compare with standalone index: same `whereHas('pickupPoint')` search | Consistent behavior |

### TC-BIZ-DEEP-57: Tab Status Filter Uses isset() not filled()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportMasterController.php:295–297` | `if (isset($request->status)) { $query->where('is_active', $request->status); }` |
| 2 | `isset()` returns true for status=0 | Correctly filters for status=0 |
| 3 | `isset()` returns true for status="" (empty string) | Empty string passed → potential incorrect filtering |
| 4 | Compare with standalone index line 29: `$request->status !== null && $request->status !== ''` | Standalone has extra empty-string guard, tab does not |

### TC-BIZ-DEEP-58: No Tab-Specific Gate Checks in pickupPointRoutesQuery

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportMasterController.php:258–301` | `pickupPointRoutesQuery()` — pure query builder |
| 2 | No `Gate::authorize()` inside query method | Gate check happens at TransportMasterController@index() level |
| 3 | Tab blade wraps include in `@can('tenant.pickup-point-route.viewAny')` | Blade-level guard for tab visibility |

### TC-BIZ-DEEP-59: Tab Uses paginate(10) with Query String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | TransportMasterController.php line 75 | `$this->pickupPointRoutesQuery($request)->paginate(10)->withQueryString()` |
| 2 | Pagination preserves all filter params in URL | `/transport/master?tab=assign_stops&route_id=1&page=2` |
| 3 | Blade renders `->appends(['tab' => 'assign_stops'])->links()` | Tab param preserved in pagination |
| 4 | **Note**: Standalone index uses `->get()` not `->paginate()` | Inconsistent pagination between tab and standalone |

### TC-BIZ-DEEP-60: Blade SortableJS Reorder Implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index blade initializes Sortable on `#sortableBody` | Drag handle `.drag-handle` activates sorting |
| 2 | `onEnd` callback builds order array from DOM | `[{id: rowId, ordinal: newIndex+1}, ...]` |
| 3 | POST to reorderUrl with JSON body | `Content-Type: application/json` |
| 4 | Success handler shows toast: "Order updated successfully" | User feedback |
| 5 | Error handler shows error toast | Graceful failure |
| 6 | **Note**: No confirmation dialog before reorder | Immediate action |

### TC-BIZ-DEEP-61: Blade Time Display Uses minutesToTime() Helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade file lines 6–16 | Custom `minutesToTime($minutes)` JS/PHP helper |
| 2 | Input 450 → floor(450/60)=7 → 07, 450%60=30 → "07:30" | HH:MM format |
| 3 | Input 0 → "00:00" | Midnight |
| 4 | Input null → "-" (dash) | Null safe |
| 5 | Used in all views (index, show, edit) for arrival_time and departure_time | Consistent display |

### TC-BIZ-DEEP-62: Blade Status Toggle Uses Generic Component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 116–119 | `<x-backend.table.status-switch>` component |
| 2 | Component handles AJAX toggle call to toggleStatus route | Automatic POST on toggle |
| 3 | Component reads `$item->is_active` for initial state | Bootstrap toggle switch |
| 4 | Component uses route model binding URL pattern | `/pickup-point-route/{id}/toggle-status` |

### TC-BIZ-DEEP-63: PickupPointRoute Is Used by Other Controllers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `TripController.php:135,489` | Uses `PickupPointRoute::find()` for trip processing |
| 2 | `TripMgmtController.php:256` | Queries `PickupPointRoute::with('pickupPoint')` for trip management |
| 3 | `StudentAllocationController.php:45,50,197,202` | Queries pickup/drop points for student allocation |
| 4 | `StudentRouteFeesController.php:374` | Queries for fee calculation |
| 5 | `MobileStudentFeeService.php:99,111` | Mobile API uses PickupPointRoute for fee display |
| 6 | `MobileTripService.php:73` | Mobile trip tracking uses PickupPointRoute |
| 7 | **Impact**: Changes to PickupPointRoute model affect 7+ other controllers/services | High blast radius |

### TC-BIZ-DEEP-64: Route Model Has pickupPointRoutes() HasMany Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Route.php:70` | `return $this->hasMany(PickupPointRoute::class, 'route_id')->orderBy('ordinal')` |
| 2 | Route model also has `pickupPointRoute()` singular (line 75) | `return $this->hasOne(PickupPointRoute::class, 'route_id')->orderBy('ordinal')` |
| 3 | Both relationships order by ordinal | Consistent ordering |

### TC-BIZ-DEEP-65: Seeder Data Creates PickupPointRoutes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TransportModuleSeeder.php:210` | `PickupPointRoute::create([...])` with specific route, shift, point |
| 2 | Seeder creates active records with times and ordinals | Seed data for testing |
| 3 | Seeder lines 274–275: Uses PickupPointRoute for trip seeding | Dependent seeding |

### TC-BIZ-DEEP-66: Policy Defines 12 Methods but Only 9 Gates Used

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoutePolicy.php` | Methods: viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print |
| 2 | Controller uses: viewAny (blade @can), view (show/trashed), create (create/store), update (reorder), edit (edit/update/toggleStatus), delete (destroy/forceDelete), restore (restore) | 7 used by controller |
| 3 | Policy has: status, import, export, print — NOT used by controller | 4 methods dead code |
| 4 | Policy has: forceDelete — has its own gate but controller reuses delete | Policy forceDelete gate bypassed |

### TC-BIZ-DEEP-67: No SoftDeletes Import in Model Directly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:3–6` | `use App\Models\BaseModel; class PickupPointRoute extends BaseModel` |
| 2 | BaseModel likely uses `SoftDeletes` trait | Inherited, not explicit |
| 3 | Migration line 41: `$table->softDeletes()` | deleted_at column exists |
| 4 | `destroy()` calls `->delete()` which sets deleted_at | Soft delete works via inheritance |

### TC-BIZ-DEEP-68: NormalizeBoolean Difference Between Controller and Request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Controller `normalizeBoolean()` line 84–93 | Returns true for `['1','true','ture','yes','on']` |
| 2 | Request `withValidator()` line 63–70 | Returns true for `['1','true','yes','on']` — **missing 'ture'** |
| 3 | If setting value is "ture": Controller treats as true, Request treats as false | **Inconsistency**: Controller might show fare column based on true, but validation might not enforce fare requirement |
| 4 | **Impact**: Settings misinterpreted between form display and validation | Subtle bug |

### TC-BIZ-DEEP-69: errorBag Not Customized

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `$errorBag` or `MessageBag` | NOT defined |
| 2 | All validation errors use default error bag | Default Laravel behavior |
| 3 | Custom after-validation errors use `$validator->errors()->add()` | Added to default bag |

### TC-BIZ-DEEP-70: All Exception Messages Include Raw Error Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | store() catch: `'Something went wrong: ' . $e->getMessage()` | Exposes SQL/driver details |
| 2 | update() catch: `'Update failed: ' . $e->getMessage()` | Same |
| 3 | destroy() catch: `'Delete failed: ' . $e->getMessage()` | Same |
| 4 | restore() catch: `'Restore failed: ' . $e->getMessage()` | Same |
| 5 | forceDelete() catch: `'Force delete failed: ' . $e->getMessage()` | Same |
| 6 | **Security concern**: SQL details, table names, constraint names leaked to user | Information disclosure |

### TC-P35: Create Stop — Full Integration Test

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin | Dashboard loads |
| 2 | Navigate to Transport Master → Assign Stops tab | Tab visible |
| 3 | Click "Add" button | Navigate to create form |
| 4 | Select Shift from dropdown | Shift selected |
| 5 | Wait for AJAX route population (getRoutesByShift) | Route dropdown populated |
| 6 | Select Route | Route selected |
| 7 | Click "+ Add Row" | New row appears |
| 8 | Row: Pickup Point = any active point | Point selected |
| 9 | Row: Arrival = "07:30", Departure = "07:35" | Times set |
| 10 | Row: Distance = 3.5, Est. Time = 12 | Numeric values |
| 11 | Row: Fare = 50.00 (if allowOneSide enabled) | Fare entered |
| 12 | Row: Active = checked | is_active = 1 |
| 13 | Click "Save Pickup Point Route" | POST submitted |
| 14 | **Full request payload**: `route_id=X, shift_id=Y, rows[0][pickup_point_id]=Z, rows[0][arrival_time]=07:30, rows[0][departure_time]=07:35, rows[0][total_distance]=3.5, rows[0][estimated_time]=12, rows[0][pickup_drop_fare]=50.00, rows[0][is_active]=1` | All fields sent |
| 15 | DB verification: `SELECT * FROM tpt_pickup_points_route_jnt WHERE route_id=X AND pickup_point_id=Z` | Record exists, ordinal=1 (or next in sequence), arrival=450, departure=455, distance=3.50, est_time=12, fare=50.00, is_active=1 |
| 16 | Geometry verification: `SELECT route_geometry FROM tpt_route WHERE id=X` | Contains {lat,lng} for pickup point Z |
| 17 | Flash message: "Pickup Point Routes added successfully." | Success |
| 18 | Redirect URL: `/transport/master?tab=assign_stops` | Correct redirect |

### TC-P36: Batch Create 3 Stops — Ordinal Auto-Increment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift S1, Route R1 | Valid combo |
| 3 | Add 3 rows | Rows 1, 2, 3 visible |
| 4 | Row 1: Pickup Point A | First point |
| 5 | Row 2: Pickup Point B (different) | Second point |
| 6 | Row 3: Pickup Point C (different) | Third point |
| 7 | Submit | POST to store |
| 8 | **Verify CODE-TRACE**: store() line 114–116: max ordinal for R1+S1 | e.g., 5 (if 5 existing) |
| 9 | **Verify CODE-TRACE**: Row 1 ordinal = 6 | `$maxOrdinal`++ = 6 |
| 10 | **Verify CODE-TRACE**: Row 2 ordinal = 7 | `$maxOrdinal`++ = 7 |
| 11 | **Verify CODE-TRACE**: Row 3 ordinal = 8 | `$maxOrdinal`++ = 8 |
| 12 | DB check: `SELECT ordinal FROM tpt_pickup_points_route_jnt WHERE route_id=R1 AND shift_id=S1 ORDER BY ordinal DESC LIMIT 3` | [8, 7, 6] |
| 13 | **Note**: Ordinal is PER route+shift combo, not global | Different routes can have same ordinal |

### TC-P37: Edit Stop — Change Arrival/Departure Times

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops list | List visible |
| 2 | Click Edit on a stop with existing times | Edit form pre-filled |
| 3 | Change Arrival from "07:00" to "08:00" | Field updated |
| 4 | Change Departure from "07:05" to "08:10" | Field updated |
| 5 | Click Save | PUT to update |
| 6 | **Verify CODE-TRACE**: update() line 251–257: `timeToMinutes("08:00")` = 480, `timeToMinutes("08:10")` = 490 | Correct conversion |
| 7 | DB check: arrival_time = 480, departure_time = 490 | Times updated |
| 8 | Geometry: `SELECT route_geometry FROM tpt_route WHERE id=routeId` | Recalculated |

### TC-P38: Edit Stop — Change Route (Geometry Impact)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit form for a stop assigned to Route R1 | Edit form |
| 2 | Change Route dropdown to Route R2 (different route) | Route changed |
| 3 | Click Save | PUT with new route_id |
| 4 | **Verify CODE-TRACE**: update() line 249: `'pickup_drop' => $route->pickup_drop` | pickup_drop from new route |
| 5 | **Verify CODE-TRACE**: update() line 269: `$this->updateRouteGeometry($request->route_id)` | Geometry updated for NEW route |
| 6 | **GAP check**: `updateRouteGeometry()` called for NEW route only | Old route R1 geometry NOT recalculated — still includes removed point |
| 7 | DB check route_geometry for R1 | Still contains the removed stop's coordinates — **out of sync** |

### TC-P39: Toggle Status Off → On → Off Cycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Record is_active=1 | Active |
| 2 | Toggle OFF → POST is_active=0 | DB: is_active=0 |
| 3 | Toggle ON → POST is_active=1 | DB: is_active=1 |
| 4 | Toggle OFF → POST is_active=0 | DB: is_active=0 |
| 5 | **Verify**: No geometry change triggered by any toggle | `toggleStatus()` does NOT call `updateRouteGeometry()` |
| 6 | **Verify**: No activityLog entry for any toggle | ZERO entries |

### TC-P40: Trash Pagination Navigation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 12+ records | Trash has >10 items |
| 2 | Navigate to `/pickup-point-route/trash/view` | Page 1 shows 10 records |
| 3 | Click page 2 | Shows remaining records (2+) |
| 4 | **Verify CODE-TRACE**: trashed() line 317: `PickupPointRoute::onlyTrashed()->paginate(10)` | 10 per page |
| 5 | Click Restore on page 1 | Record restored, redirect to master |
| 6 | Navigate back to trash | Count reduced by 1 |
| 7 | Click Force Delete on page 2 | Record permanently removed, redirect to master |
| 8 | Navigate back to trash | Count reduced by 1 |

### TC-P41: Create Stop with Fare Settings Variation — allowOneSide=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `allow_only_one_side_transport_charges=true` | One-side mode |
| 2 | Navigate to create form | Fare column "Pickup / Drop Fare" visible |
| 3 | Add row, leave pickup_drop_fare empty | Fare empty |
| 4 | Submit | Validation error: "Fare is required." |
| 5 | Add pickup_drop_fare = 75 | Fare filled |
| 6 | Submit | Success — pickup_drop_fare = 75.00 |
| 7 | **Verify CODE-TRACE**: store() line 129–131: `!empty($row['pickup_drop_fare'])` = true | `$pickupDropFare = 75` |

### TC-P42: Create Stop with Fare Settings — both_side_fare

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `allow_only_one_side_transport_charges=false`, `allow_different_pickup_and_drop_point=false` | Both-side same-point mode |
| 2 | Navigate to create form | "Both Fare" column visible |
| 3 | Add row, leave both_side_fare empty | Fare empty |
| 4 | Submit | Validation error: "Both side fare is required." |
| 5 | Add both_side_fare = 120 | Fare filled |
| 6 | Submit | Success — both_side_fare = 120.00 |

### TC-P43: Create Stop with Fare Settings — Pickup/Drop Fare

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `allow_only_one_side_transport_charges=false`, `allow_different_pickup_and_drop_point=true` | Diff-point mode |
| 2 | Ensure route has pickup_drop="Drop" | Route R1 is Drop type |
| 3 | Navigate to create form | Fare column shows dynamic label |
| 4 | Add row with Route=R1, pickup_point=X | Row filled |
| 5 | Leave pickup_drop_fare empty | Fare empty |
| 6 | Submit | Validation error: "Drop fare is required." (dynamic: ucfirst($row['pickup_drop']) . ' fare is required.') |
| 7 | Add pickup_drop_fare = 90 | Fare filled |
| 8 | Submit | Success — pickup_drop_fare = 90.00 |

### TC-N38: Store with Invalid Time Format "25:00"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift, Route, add row | Row visible |
| 3 | Enter arrival = "25:00" (invalid hour) | Not valid H:i |
| 4 | Submit | `date_format:H:i` fails |
| 5 | Error: "The rows.0.arrival_time does not match the format H:i." | Format validation |

### TC-N39: Store with Departure Time "07:60"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add row | Row visible |
| 2 | Enter departure = "07:60" (invalid minute) | Not valid H:i |
| 3 | Submit | `date_format:H:i` fails |
| 4 | Error: "The rows.0.departure_time does not match the format H:i." | Format validation |

### TC-N40: Store with Non-Numeric Distance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add row | Row visible |
| 2 | Enter total_distance = "abc" | Non-numeric |
| 3 | Submit | `numeric` validation fails |
| 4 | Error: "The rows.0.total_distance must be a number." | Numeric validation |

### TC-N41: Update with Non-Existent pickup_point_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit form for existing stop | Form loaded |
| 2 | Change pickup_point_id to 99999 (non-existent) | Invalid point |
| 3 | Submit | `exists:tpt_pickup_points,id` fails |
| 4 | Error: "The selected rows.0.pickup_point_id is invalid." | Validation error |

### TC-N42: Force Delete on Already Force-Deleted Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete record X | Trashed |
| 2 | Force delete record X | `forceDelete()` succeeds, record gone |
| 3 | Force delete record X again | `onlyTrashed()->findOrFail(X)` → no record found → 404 |
| 4 | Error: "No query results" | ModelNotFoundException |

### TC-N43: Create with Shift Having No Active Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Shift from dropdown | AJAX to getRoutesByShift |
| 2 | No active routes for this shift | Route dropdown remains empty or shows "No routes available" |
| 3 | User cannot proceed without selecting route | UI prevents submission |
| 4 | **Workaround**: Manually POST with route_id | Possible via API bypass |

### TC-N44: Store with Both Fare Settings True

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `allowOneSide=true`, `allowDifferentPickupDrop=true` | Both settings true |
| 2 | Navigate to create form | Both fare columns visible |
| 3 | Add row with empty pickup_drop_fare and both_side_fare | Both empty |
| 4 | Submit | Validation: "Fare is required." (allowOneSide=true check fires FIRST, blocks both_side_fare check) |
| 5 | **CODE-TRACE**: Request line 131: `if ($allowOneSide)` checked before line 150 | allowOneSide check short-circuits other fare checks |

### TC-N45: Concurrent Same-Second Store Requests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 2 simultaneous POST requests with same route+shift+different pickup_point | Race condition |
| 2 | Request A: $maxOrdinal = MAX(ordinal) = 5 | Reads 5 |
| 3 | Request B: $maxOrdinal = MAX(ordinal) = 5 | Also reads 5 (before A commits) |
| 4 | Request A: creates with ordinal 6, commits | A: ordinal=6 |
| 5 | Request B: creates with ordinal 6 (DUPLICATE) | B: ordinal=6 — same ordinal! |
| 6 | **Impact**: Two records share ordinal=6 | Ordinal collision under concurrent requests |
| 7 | **Fix**: Use `DB::transaction` with lock or unique scope+ordinal constraint | Existing code has no ordinal uniqueness |

### TC-D13: Verify FK CASCADE on Route Delete Via Controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count PickupPointRoutes for route_id=R1 | e.g., 3 records |
| 2 | Delete Route R1 using route controller DELETE | Route soft-deleted? or hard-deleted? |
| 3 | **Verify**: If Route is hard-deleted, ON DELETE CASCADE removes PickupPointRoutes | All 3 records cascade deleted |
| 4 | **Verify**: If Route uses soft delete, PickupPointRoutes NOT cascade deleted | Records remain with foreign key intact |
| 5 | DB check: `SELECT COUNT(*) FROM tpt_pickup_points_route_jnt WHERE route_id=R1` | 0 (hard delete) or 3 (soft delete) |

### TC-D14: Verify Route Model pickupPointRoute() HasOne Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Route.php:75` | `return $this->hasOne(PickupPointRoute::class, 'route_id')->orderBy('ordinal')` |
| 2 | This returns the FIRST PickupPointRoute for the route (ordinal ASC) | First stop only |
| 3 | Used in TripController for route processing | Picks first stop as starting point |

### TC-CR50: Policy Has Status Gate But Controller Uses Edit

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoutePolicy.php:29–32` | `status()` checks `tenant.pickup-point-route.status` |
| 2 | Open `toggleStatus()` controller line 381 | `Gate::authorize('tenant.pickup-point-route.edit')` |
| 3 | **GAP**: toggleStatus should check `tenant.pickup-point-route.status` | Controller uses wrong permission |
| 4 | **Impact**: User with edit permission can toggle status even without status permission | Policy-defined status gate is circumvented |

### TC-CR51: Gate::authorize Called Without User Context Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | All Gate::authorize() calls use `Gate::authorize('permission.name')` | No `$user->can()` or `$request->user()->can()` |
| 2 | `Gate::authorize()` uses currently authenticated user | Correct — Laravel facade resolves user from context |
| 3 | No explicit user parameter passed | Works via Auth facade |

### TC-CR52: destroy() Saves route_id Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` line 291–292 | `$pickupRoute = PickupPointRoute::findOrFail($id); $routeId = $pickupRoute->route_id;` |
| 2 | `$routeId` captured BEFORE delete | After delete, relation still accessible via loaded model |
| 3 | Line 294: `$pickupRoute->delete()` | `route_id` still accessible on model after soft delete |
| 4 | Line 297: `$this->updateRouteGeometry($routeId)` | Uses saved route_id — correct |

### TC-CR53: routeGeometry Updates Use Same Method for All Operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `updateRouteGeometry()` at line 403–436 | Single method for all geometry updates |
| 2 | Called from store, update, destroy, restore, forceDelete | Consistent behavior |
| 3 | NOT called from toggleStatus or reorder | toggleStatus correct (no geometry change), reorder is GAP |

### TC-CR54: Index() Blade Attempts Pagination on Collection (Potential Error)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open standalone blade/pickup_point_route/index.blade.php line 140 | `$pickupPointRoutes->appends(...)->links()` |
| 2 | Standalone controller uses `->get()` returns Collection (when filters present) | NOT a LengthAwarePaginator |
| 3 | Collection has no `->links()` method | `BadMethodCallException` thrown |
| 4 | **Condition**: Only fails when 3 filters present AND data exists | Intermittent error |
| 5 | **When empty collection**: `collect()->links()` returns empty string | No error when no data |
| 6 | **Recommendation**: Use `->paginate()` in standalone or guard `->links()` with `instanceof LengthAwarePaginator` | Fix for production bug |

### TC-CR55: No Request Logging or Auditing of Any Kind

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `Log::`, `logger()`, `info()`, `record()` | **ZERO logging statements** |
| 2 | Search for `audit`, `Audit` | NOT found |
| 3 | **Impact**: No debug path for troubleshooting | Hard to debug production issues |
| 4 | Compare with other Transport controllers | Some have logging, this one has none |

### TC-CR56: No Throttle or Rate Limit on API Endpoints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `throttle`, `RateLimiter`, `middleware` | NOT found |
| 2 | GET `/get-routes-by-shift/{shiftId}` — no throttle | Can be spammed |
| 3 | POST `/pickup-point-route/reorder` — no throttle | Rapid reorder requests |
| 4 | POST `/pickup-point-route/{id}/toggle-status` — no throttle | Rapid toggle requests |
| 5 | POST `/pickup-point-route` (store) — no throttle | Bulk insert spam possible |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: AssignStops (PickupPointRoute) | Date: 2026-07-21*

