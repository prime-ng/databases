# Assign Stops (Pickup Stops List) — TC_List

---

## 1. Feature Information

| Attribute | Details |
|-----------|---------|
| **Module** | Transport (TPT) |
| **Tab Group** | Transport Master → Assign Stops |
| **Feature** | Pickup Stops List / Route–Stop Assignment — assign pickup points to routes with arrival/departure times, fares, distances |
| **URL(s)** | `/transport/transport-master` (index via tab `assign_stops`), `/transport/pickup-point-route/create`, `/transport/pickup-point-route/{id}`, `/transport/pickup-point-route/{id}/edit`, `/transport/pickup-point-route/{id} (PUT)`, `/transport/pickup-point-route/{id} (DELETE)`, `/transport/pickup-point-route/trash`, `/transport/pickup-point-route/{id}/restore`, `/transport/pickup-point-route/{id}/force-delete`, `/transport/pickup-point-route/{pickupPointRoute}/toggle-status`, `/transport/pickup-point-route/reorder`, `/transport/pickup-point-route/get-routes/{shiftId}` |
| **Controller** | `Modules\Transport\Http\Controllers\PickupPointRouteController` — 13 methods — ⚠️ `index()` NOT called for tab listing; standalone route only |
| **Tab Container Controller** | `Modules\Transport\Http\Controllers\TransportMasterController@index()` — tab id `assign_stops`, private `pickupPointRoutesQuery()` for listing |
| **Model** | `Modules\Transport\Models\PickupPointRoute` — BaseModel, 3 relationships, 12 fillable fields, SoftDeletes via BaseModel (`deleted_at` present in migration) |
| **Validation** | `Modules\Transport\Http\Requests\PickupPointRouteRequest` — 9 field rules + 4 custom after-validations (duplicate-in-request, duplicate-in-DB-store-only, arrival<departure, fare-based-on-settings) |
| **Permissions** | `tenant.pickup-point-route.*` (create, edit, delete, restore, view, update) — no `forceDelete` permission in code; `forceDelete` reuses `tenant.pickup-point-route.delete` |
| **Soft Deletes** | Yes (`deleted_at` column in migration, BaseModel uses SoftDeletes) |
| **Activity Log** | **NONE** — no `activityLog()` calls in ANY controller method |
| **DB Table** | `tpt_pickup_points_route_jnt` — 11 columns + 3 CASCADE FKs + 1 UNIQUE + 1 INDEX |
| **Key Features** | Batch store for multiple stops per route, auto-ordinal, drag-drop reorder via SortableJS, route geometry auto-update, fare validation based on global settings, time stored as minutes-since-midnight |

---

## 2. Pre-conditions

| # | Pre-condition | Source |
|---|--------------|--------|
| PC-01 | User must have `tenant.pickup-point-route.*` permissions | Policy-based |
| PC-02 | At least one active `tpt_route` must exist (FK `fk_pickupPointRoute_routeId` CASCADE) | DDL migration |
| PC-03 | At least one active `tpt_shift` must exist (FK `fk_pickupPointRoute_shiftId` CASCADE) | DDL migration |
| PC-04 | At least one active `tpt_pickup_points` must exist (FK `fk_pickupPointRoute_pickupPointId` CASCADE) | DDL migration |
| PC-05 | Global settings `allow_only_one_side_transport_charges` and `allow_different_pickup_and_drop_point` must be configured in `sys_settings` | `PickupPointRouteRequest.php:58-61` |
| PC-06 | Tab id `assign_stops-pane` registered in transportmaster.blade.php | `pickup_point_route/index.blade.php:1` |
| PC-07 | SortableJS library loaded for reorder functionality | `pickup_point_route/index.blade.php:144` |

---

## 3. Default Data Load

| # | Data Load Rule | Details | Source |
|---|----------------|---------|--------|
| DL-01 | Routes loaded: `Route::all()` — no active filter | All routes | `PickupPointRouteController.php:20` |
| DL-02 | Shifts loaded: `Shift::all()` — no active filter | All shifts | `PickupPointRouteController.php:21` |
| DL-03 | PickupPointRoutes initially empty collection | `$pickupPointRoutes = collect()` | `PickupPointRouteController.php:22` |
| DL-04 | Data loads ONLY when `route_id` AND `shift_id` AND `pickup_drop` are all present | Filter-driven list | `PickupPointRouteController.php:24` |
| DL-05 | Query filters: route_id, shift_id, pickup_drop (exact match) + optional status + search on pickupPoint.name | `->where()` chain | `PickupPointRouteController.php:25-33` |
| DL-06 | Ordered by `ordinal` ascending | `->orderBy('ordinal')` | `PickupPointRouteController.php:34` |
| DL-07 | No pagination in index — returns `->get()` (all matching records) | `->get()` not `->paginate()` | `PickupPointRouteController.php:35` |
| DL-08 | Table columns: Drag Handle, Route, Pickup Point, Arrival Time, Departure Time, Total Distance, Estimated Time, Status (toggle), Action | `pickup_point_route/index.blade.php:87-98` |
| DL-09 | Arrival/Departure displayed as `HH:MM` via `minutesToTime()` helper | Converts stored INT minutes to time string | `pickup_point_route/index.blade.php:110-111` |
| DL-10 | Status toggle via `<x-backend.table.status-switch>` generic component | `pickup_point_route/index.blade.php:116-119` |
| DL-11 | Drag-drop reorder via SortableJS, POST to `transport.pickup-point-route.reorder` | `pickup_point_route/index.blade.php:146-191` |
| DL-12 | Create form: Shift dropdown, Route dropdown (AJAX-loaded by shift), dynamic table rows with pickup point, arrival, departure, distance, est time, fare (conditional), active toggle | `pickup_point_route/create.blade.php` |

---

## 4. Test Data Strategy

| # | Data Strategy | Details | Source |
|---|---------------|---------|--------|
| TD-01 | **Batch store 3 valid stops** | 3 pickup points with different IDs, ordinals auto-assigned 1,2,3 |
| TD-02 | **Single store** | 1 pickup point with valid arrival<departure, fare, distance |
| TD-03 | **Duplicate pickup_point_id in same request** | 2 rows with same pickup_point_id → custom validation error | `PickupPointRouteRequest.php:76-83` |
| TD-04 | **Already assigned (store only)** | pickup_point_id already exists for route+shift → validation error | `PickupPointRouteRequest.php:88-107` |
| TD-05 | **Arrival > Departure** | arrival=10:00, departure=09:00 → error | `PickupPointRouteRequest.php:112-123` |
| TD-06 | **Setting: allowOneSide=true** | pickup_drop_fare required | `PickupPointRouteRequest.php:131-138` |
| TD-07 | **Setting: bothSide, same point** | both_side_fare required | `PickupPointRouteRequest.php:141-148` |
| TD-08 | **Setting: bothSide, diff points** | pickup_drop_fare required with dynamic label | `PickupPointRouteRequest.php:151-158` |
| TD-09 | **Reorder 3 stops** | Drag stop3 to position 1 → ordinals updated via AJAX | `PickupPointRouteController.php:438-448` |

---

## 5. Business Conditions (BC)

### BC-DB: Database Conditions — `tpt_pickup_points_route_jnt`

| BC ID | Column | Type (Migration) | Constraints | Source |
|-------|--------|------------------|-------------|--------|
| BC-DB-01 | `id` | INT UNSIGNED AUTO_INCREMENT | PK | Migration line 15 |
| BC-DB-02 | `pickup_drop` | ENUM('Drop','Pickup') | DEFAULT 'Pickup', NOT NULL | Migration line 16 |
| BC-DB-03 | `ordinal` | SMALLINT UNSIGNED | DEFAULT 1, NOT NULL | Migration line 17 |
| BC-DB-04 | `total_distance` | DECIMAL(7,2) | NULLABLE (model casts to decimal:2) | Migration line 18 |
| BC-DB-05 | `arrival_time` | INT | NULLABLE (minutes since midnight) | Migration line 19 |
| BC-DB-06 | `departure_time` | INT | NULLABLE (minutes since midnight) | Migration line 20 |
| BC-DB-07 | `estimated_time` | INT | NULLABLE | Migration line 21 |
| BC-DB-08 | `pickup_drop_fare` | DECIMAL(10,2) | NULLABLE | Migration line 22 |
| BC-DB-09 | `both_side_fare` | DECIMAL(10,2) | NULLABLE | Migration line 23 |
| BC-DB-10 | `is_active` | BOOLEAN/TINYINT | DEFAULT true (1), NOT NULL | Migration line 24 |
| BC-DB-11 | `shift_id` | INT UNSIGNED | FK → `tpt_shift.id` ON DELETE CASCADE | Migration line 27-28 |
| BC-DB-12 | `route_id` | INT UNSIGNED | FK → `tpt_route.id` ON DELETE CASCADE | Migration line 29-30 |
| BC-DB-13 | `pickup_point_id` | INT UNSIGNED | FK → `tpt_pickup_points.id` ON DELETE CASCADE | Migration line 31-32 |
| BC-DB-14 | UNIQUE `uq_pickupPointRoute_route_pickupPoint` | (route_id, pickup_point_id) | Prevents duplicate stop per route | Migration line 35 |
| BC-DB-15 | INDEX `idx_pprj_route_ordinal` | (route_id, ordinal) | Efficient ordering queries | Migration line 38 |
| BC-DB-16 | `deleted_at` | TIMESTAMP NULL | Soft delete support | Migration line 41 |
| BC-DB-17 | All 3 FKs are CASCADE | shift, route, pickup_point deletion cascades to junction | Migration lines 28,30,32 |

### BC-VAL: Validation Conditions — `PickupPointRouteRequest`

| BC ID | Field | Rule | Source |
|-------|-------|------|--------|
| BC-VAL-01 | `route_id` | required, exists:tpt_route,id | `PickupPointRouteRequest.php:23` |
| BC-VAL-02 | `shift_id` | required, exists:tpt_shift,id | `PickupPointRouteRequest.php:24` |
| BC-VAL-03 | `rows` | required, array, min:1 | `PickupPointRouteRequest.php:26` |
| BC-VAL-04 | `rows.*.pickup_point_id` | required, exists:tpt_pickup_points,id | `PickupPointRouteRequest.php:29` |
| BC-VAL-05 | `rows.*.arrival_time` | nullable, date_format:H:i | `PickupPointRouteRequest.php:31` |
| BC-VAL-06 | `rows.*.departure_time` | nullable, date_format:H:i | `PickupPointRouteRequest.php:32` |
| BC-VAL-07 | `rows.*.total_distance` | nullable, numeric, min:0 | `PickupPointRouteRequest.php:34` |
| BC-VAL-08 | `rows.*.estimated_time` | nullable, numeric, min:0 | `PickupPointRouteRequest.php:35` |
| BC-VAL-09 | `rows.*.pickup_drop_fare` | nullable, numeric, min:0 | `PickupPointRouteRequest.php:38` |
| BC-VAL-10 | `rows.*.both_side_fare` | nullable, numeric, min:0 | `PickupPointRouteRequest.php:39` |
| BC-VAL-11 | `rows.*.is_active` | nullable, boolean | `PickupPointRouteRequest.php:41` |

### BC-VAL-CUSTOM: Custom After-Validations

| BC ID | Condition | Error Message | Scope | Source |
|-------|-----------|---------------|-------|--------|
| BC-VAL-C01 | Duplicate `pickup_point_id` in same request rows | "Same pickup point cannot be added more than once." | Store + Update | `PickupPointRouteRequest.php:76-83` |
| BC-VAL-C02 | `pickup_point_id` already assigned to route+shift in DB | "This pickup point is already assigned to this route and shift." | Store ONLY | `PickupPointRouteRequest.php:88-107` |
| BC-VAL-C03 | `arrival_time > departure_time` | "Departure time must be after arrival time." | Store + Update | `PickupPointRouteRequest.php:112-123` |
| BC-VAL-C04a | Setting `allow_one_side=true` → `pickup_drop_fare` required | "Fare is required." | Store + Update | `PickupPointRouteRequest.php:131-138` |
| BC-VAL-C04b | Setting `allow_one_side=false` AND `allowDifferentPickupDrop=false` → `both_side_fare` required | "Both side fare is required." | Store + Update | `PickupPointRouteRequest.php:141-148` |
| BC-VAL-C04c | Setting `allow_one_side=false` AND `allowDifferentPickupDrop=true` → `pickup_drop_fare` required | "'{Pickup/Drop}' fare is required." | Store + Update | `PickupPointRouteRequest.php:151-158` |

### BC-AUTH: Authorization Conditions

| BC ID | Permission | Controller Method | Source |
|-------|-----------|-------------------|--------|
| BC-AUTH-01 | `tenant.pickup-point-route.view` | `show()` — Gate present | `PickupPointRouteController.php:47` |
| BC-AUTH-02 | `tenant.pickup-point-route.create` | `create()` — Gate present via controller | `PickupPointRouteController.php:60` |
| BC-AUTH-03 | `tenant.pickup-point-route.create` | `store()` — Gate relies on FormRequest `authorize()` only | `PickupPointRouteRequest.php:15` |
| BC-AUTH-04 | `tenant.pickup-point-route.edit` | `edit()` — Gate present via controller | `PickupPointRouteController.php:194` |
| BC-AUTH-05 | `tenant.pickup-point-route.update` | `update()` — Gate via controller AND FormRequest authorize | `PickupPointRouteController.php:234` |
| BC-AUTH-06 | `tenant.pickup-point-route.delete` | `destroy()` — Gate present | `PickupPointRouteController.php:286` |
| BC-AUTH-07 | `tenant.pickup-point-route.view` | `trashed()` — Gate present | `PickupPointRouteController.php:315` |
| BC-AUTH-08 | `tenant.pickup-point-route.restore` | `restore()` — Gate present | `PickupPointRouteController.php:324` |
| BC-AUTH-09 | `tenant.pickup-point-route.delete` (reused) | `forceDelete()` — Gate uses delete permission | `PickupPointRouteController.php:353` |
| BC-AUTH-10 | `tenant.pickup-point-route.edit` | `toggleStatus()` — Gate present | `PickupPointRouteController.php:381` |
| BC-AUTH-11 | `tenant.pickup-point-route.update` | `reorder()` — Gate present | `PickupPointRouteController.php:440` |
| BC-AUTH-12 | **MISSING**: `index()` has NO Gate::authorize() | Any authenticated user can access | `PickupPointRouteController.php:18-43` |
| BC-AUTH-13 | **MISSING**: `create()` has Gate but `store()` only has FormRequest authorize | If FormRequest bypassed, no guard | `PickupPointRouteController.php:105` |

### BC-BIZ: Business Conditions

| BC ID | Condition | Expected Behavior | Source |
|-------|-----------|-------------------|--------|
| BC-BIZ-01 | Auto-ordinal: starts at max(ordinal)+1 for route+shift | `$maxOrdinal = PickupPointRoute::max('ordinal') ?? 0; $maxOrdinal++` per row | `PickupPointRouteController.php:114-116,124` |
| BC-BIZ-02 | `pickup_drop` derived from Route table, not from form input | `$route->pickup_drop` from Route::select('id','pickup_drop')->first() | `PickupPointRouteController.php:137-148` |
| BC-BIZ-03 | Time stored as minutes since midnight via `timeToMinutes()` | `explode(':', $time)` → `($h*60)+$m` | `PickupPointRouteController.php:186-190` |
| BC-BIZ-04 | `updateRouteGeometry()` called after store, update, destroy, restore, forceDelete | Recalculates route_geometry JSON with lat/lng from ordered pickup points | `PickupPointRouteController.php:403-436` |
| BC-BIZ-05 | All CUD operations wrapped in `DB::beginTransaction()` + `DB::commit()` | Rollback on exception | All store/update/destroy/restore/forceDelete |
| BC-BIZ-06 | `destroy()` does NOT set `is_active=false` before soft-delete | Direct `->delete()` | `PickupPointRouteController.php:294` |
| BC-BIZ-07 | `forceDelete()` uses `onlyTrashed()` (WRONG — should be `withTrashed()`) | Cannot force-delete active (non-deleted) records | `PickupPointRouteController.php:358` |
| BC-BIZ-08 | `restore()` uses `onlyTrashed()` (correct for restore) | Finds only trashed records | `PickupPointRouteController.php:329` |
| BC-BIZ-09 | `update()` uses `$request->has('is_active')` (different from store's `!empty()`) | Unchecked checkbox → `.has()` = false → is_active=0 | `PickupPointRouteController.php:265` |
| BC-BIZ-10 | `store()` uses `!empty($row['is_active'])` (looser than `has()`) | `!empty('0')` = false, `!empty('1')` = true | `PickupPointRouteController.php:166` |
| BC-BIZ-11 | Row with empty `pickup_point_id` is SKIPPED silently in store | `if (empty($row['pickup_point_id'])) { continue; }` | `PickupPointRouteController.php:120-122` |
| BC-BIZ-12 | `reorder()` accepts `$request->order` array with id+ordinal pairs | Bulk update each row | `PickupPointRouteController.php:442-445` |
| BC-BIZ-13 | `show()` uses `->where('id', $id)->orderBy('ordinal')->first()` | Redundant ordinal order for single record | `PickupPointRouteController.php:49-52` |
| BC-BIZ-14 | `toggleStatus()` validates inline (`$request->validate`) NOT via FormRequest | Uses `$request->boolean('is_active')` | `PickupPointRouteController.php:383-387` |
| BC-BIZ-15 | Route geometry stored as JSON string or NULL | `json_encode($points)` or `null` if no valid points | `PickupPointRouteController.php:423-435` |
| BC-BIZ-16 | Route geometry only includes points with lat+long | `whereHas('pickupPoint', fn => whereNotNull lat/lng)` | `PickupPointRouteController.php:407-410` |
| BC-BIZ-17 | **GAP**: NO `activityLog()` calls in ANY method | store/update/destroy/restore/forceDelete/toggleStatus/reorder all lack logging | Throughout controller |

### BC-REF: Reference & UI Conditions

| BC ID | Condition | Source |
|-------|-----------|--------|
| BC-REF-01 | Tab id `assign_stops-pane`, hidden `tab=assign_stops` | `pickup_point_route/index.blade.php:1,22` |
| BC-REF-02 | Drag handle column with SortableJS — POST to reorder endpoint | `pickup_point_route/index.blade.php:105-106,146-191` |
| BC-REF-03 | Arrival/Departure displayed as `HH:MM` via `minutesToTime()` helper function | `pickup_point_route/index.blade.php:6-16,110-111` |
| BC-REF-04 | Status toggle via generic `<x-backend.table.status-switch>` component | `pickup_point_route/index.blade.php:116-119` |
| BC-REF-05 | 4 mandatory filters required to show data: Route, Shift, Pickup/Drop type, plus optional Status and Search | `pickup_point_route/index.blade.php:26-69` |
| BC-REF-06 | Create: Shift dropdown → loads Routes via AJAX `getRoutesByShift()` | `pickup_point_route/create.blade.php:41-43` |
| BC-REF-07 | Create: Dynamic table rows with add/remove, fare columns conditionally shown based on settings | `pickup_point_route/create.blade.php:48-81` |
| BC-REF-08 | Settings `ALLOW_ONE_SIDE` and `ALLOW_DIFFERENT_PICKUP_DROP` passed to JS as JSON | `pickup_point_route/create.blade.php:89-92` |

---

## 6. Test Case List

### TC-P: Positive Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-P-01 | Batch add 3 stops to route (store) | Route R1, Shift S1: submit 3 valid rows | All 3 created with ordinals 1,2,3, geometry updated, redirect success |
| TC-P-02 | Add 1 stop with all optional fields | Include arrival, departure, distance, est time, both fares | All fields saved correctly |
| TC-P-03 | Add stop with only pickup_point_id (minimal) | All optional fields left empty | Created with NULL optional fields |
| TC-P-04 | Filter index by route+shift+pickup_drop | Select Route R1, Shift S1, Pickup_Drop="Pickup" | Matching records displayed, ordered by ordinal |
| TC-P-05 | Search by pickup point name | Enter partial name in search | Filtered results matching name |
| TC-P-06 | Edit existing stop | Change arrival_time, fare | Updated, geometry recalculated |
| TC-P-07 | Toggle status ON→OFF | Click status toggle | AJAX success, is_active=0 |
| TC-P-08 | Reorder stops via drag-drop | Drag stop 3 to position 1 | Ordinals updated via AJAX, success toast |
| TC-P-09 | Soft delete a stop | Click delete | deleted_at set, geometry recalculated, success message |
| TC-P-10 | Restore soft-deleted stop | Click restore in trash | Restored, geometry recalculated, success message |
| TC-P-11 | View single stop details | Click show | All fields displayed with route/pickupPoint/shift relationships |
| TC-P-12 | Trash list paginated | Navigate to trash | 10 items per page, only soft-deleted items |

### TC-N: Negative Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-N-01 | Submit with empty rows array | No rows → min:1 | "The rows must contain at least 1 items." |
| TC-N-02 | Submit with empty pickup_point_id row | Row has no pickup_point_id | Silently skipped (not an error, but row ignored) |
| TC-N-03 | Duplicate pickup_point_id in same request | 2 rows, same pickup point | "Same pickup point cannot be added more than once." |
| TC-N-04 | Pickup point already assigned to route+shift (store) | Existing DB row with same route+shift+point | "This pickup point is already assigned to this route and shift." |
| TC-N-05 | arrival_time > departure_time | arrival=10:00, departure=09:00 | "Departure time must be after arrival time." |
| TC-N-06 | Invalid route_id | route_id=99999 | "The selected route id is invalid." |
| TC-N-07 | Invalid pickup_point_id | pickup_point_id=99999 | "The selected rows.*.pickup_point_id is invalid." |
| TC-N-08 | Negative distance | total_distance=-5 | "The rows.0.total_distance must be at least 0." |
| TC-N-09 | Missing fare when allowOneSide=true | Setting on, pickup_drop_fare empty | "Fare is required." |
| TC-N-10 | Missing both_side_fare when same-point mode | Setting bothSide+samePoint, both_side_fare empty | "Both side fare is required." |
| TC-N-11 | Missing pickup_drop_fare when diff-point mode | Setting bothSide+diffPoint, pickup_drop_fare empty | "'{Pickup/Drop}' fare is required." |
| TC-N-12 | Force delete active (non-trashed) record | not deleted → onlyTrashed() → 404 | "No query results" — `onlyTrashed()` finds nothing |
| TC-N-13 | Restore non-trashed record | Active record → onlyTrashed() → 404 | "No query results" |
| TC-N-14 | Access without permission | No tenant.pickup-point-role.* | 403 |
| TC-N-15 | Create with invalid shift_id | shift_id=99999 | "The selected shift id is invalid." |
| TC-N-16 | Store with empty rows (all rows skipped) | All rows have empty pickup_point_id | No records created, geometry unchanged, redirect with success (misleading) |

### TC-D: Data Integrity Test Cases

| ID | Test Case | Summary | Expected Result |
|----|-----------|---------|-----------------|
| TC-D-01 | Verify auto-ordinal assignment | Batch add 3 stops → ordinals 1,2,3 | `max(ordinal)+1` per row |
| TC-D-02 | Verify time stored as minutes | arrival=07:30 → stored as 450 (7*60+30) | DB has INT 450 |
| TC-D-03 | Verify pickup_drop taken from Route | Route has pickup_drop="Drop" → all stops inherit "Drop" | DB has pickup_drop="Drop" |
| TC-D-04 | Verify geometry recalculated after CUD | After store/update/destroy/restore/forceDelete → check route_geometry | JSON array of {lat,lng} ordered, or NULL |
| TC-D-05 | Verify geometry NULL when no valid points | Delete all stops with lat/lng → geometry becomes NULL | `Route::update(['route_geometry' => null])` |
| TC-D-06 | Verify UNIQUE constraint prevents duplicate | Insert same route_id+pickup_point_id again | DB integrity violation |
| TC-D-07 | Verify FK CASCADE on route delete | Delete Route → all its PickupPointRoutes cascade deleted | `onDelete('cascade')` |
| TC-D-08 | Verify FK CASCADE on pickup point delete | Delete PickupPoint → junction rows cascade deleted | `onDelete('cascade')` |
| TC-D-09 | Verify no is_active=false before soft-delete | destroy() → check DB | `is_active` stays true, `deleted_at` set |
| TC-D-10 | Verify reorder persists correctly | Drag item down 2 positions → ordinals updated | AJAX success, DB updated |

### TC-CR: Code Review Test Cases

| ID | Test Case | Steps | Expected |
|----|-----------|-------|----------|
| TC-CR-01 | **GAP: index() missing Gate** | 1. Open `PickupPointRouteController.php:18-43` | No `Gate::authorize()` call — any user can list |
| TC-CR-02 | **GAP: store() relies only on FormRequest** | 1. Open line 105 | No controller-level Gate, only `PickupPointRouteRequest::authorize()` |
| TC-CR-03 | **GAP: no activityLog() in store** | 1. Search controller for `activityLog` | ZERO activityLog calls in entire controller |
| TC-CR-04 | **GAP: no activityLog() in update** | 1. Search controller for `activityLog` | Missing |
| TC-CR-05 | **GAP: no activityLog() in destroy** | 1. Search controller for `activityLog` | Missing |
| TC-CR-06 | **GAP: no activityLog() in restore** | 1. Search controller for `activityLog` | Missing |
| TC-CR-07 | **GAP: no activityLog() in forceDelete** | 1. Search controller for `activityLog` | Missing |
| TC-CR-08 | **GAP: no activityLog() in toggleStatus** | 1. Search controller for `activityLog` | Missing |
| TC-CR-09 | **GAP: no activityLog() in reorder** | 1. Search controller for `activityLog` | Missing |
| TC-CR-10 | **GAP: forceDelete uses onlyTrashed()** | 1. Open line 358 | `PickupPointRoute::onlyTrashed()->findOrFail($id)` — should be `withTrashed()` |
| TC-CR-11 | **GAP: destroy no is_active=false before delete** | 1. Open lines 284-310 | Direct `->delete()`, no `->update(['is_active'=>false])` first |
| TC-CR-12 | **GAP: show() redundant orderBy** | 1. Open lines 49-52 | Single-record `->where('id', $id)->orderBy('ordinal')->first()` — orderBy has no effect |
| TC-CR-13 | **DB transaction in all CUD** | 1. Check store/update/destroy/restore/forceDelete | All wrapped in `DB::beginTransaction/commit/rollback` |
| TC-CR-14 | **updateRouteGeometry() after every CUD** | 1. Check store line 171, update line 269, destroy line 297, restore line 335, forceDelete line 364 | Called on each with routeId |
| TC-CR-15 | **4 custom after-validations** | 1. Open `PickupPointRouteRequest.php:45-161` | Duplicate request, duplicate DB, arrival<departure, fare-by-setting |
| TC-CR-16 | **update uses `has()`, store uses `!empty()` for is_active** | 1. Store line 166: `!empty($row['is_active'])` | Different boolean check strategies |
| TC-CR-17 | **Reuse of delete permission for forceDelete** | 1. Open lines 286 and 353 | `forceDelete()` uses `tenant.pickup-point-route.delete` (no forceDelete permission) |

---

## 7. Detailed Test Steps

### TC-P-01: Batch add 3 stops to route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with `tenant.pickup-point-route.create` | Success |
| 2 | Navigate to `/transport/pickup-point-route/create` | Create form with Shift dropdown, Route dropdown, empty dynamic table |
| 3 | Select Shift = "Morning" from `select[name=shift_id]` | Shift selected |
| 4 | Select Route = "Route A" from `select#route_id` (AJAX-loaded based on shift) | Route selected |
| 5 | Click "+ Add Row" button | New row added with: Pickup Point dropdown, Arrival, Departure, Distance, Est. Time, Fare fields (conditional), Active checkbox, Remove button |
| 6 | Click "+ Add Row" 2 more times | 3 rows visible |
| 7 | Row 1: Select Pickup Point = "Main Gate", Arrival="07:00", Departure="07:05", Distance=0.5, Est. Time=5, Fare=50, Active=checked | Row 1 filled |
| 8 | Row 2: Select Pickup Point = "Bus Stand", Arrival="07:10", Departure="07:15", Distance=1.2, Est. Time=10, Fare=50, Active=checked | Row 2 filled |
| 9 | Row 3: Select Pickup Point = "School", Arrival="07:20", Departure="07:25", Distance=0.8, Est. Time=8, Fare=0, Active=checked | Row 3 filled |
| 10 | Click "Save Pickup Point Route" | POST to `transport.pickup-point-route.store` |
| 11 | **Verify**: `PickupPointRouteRequest` rules pass | All field validations ok |
| 12 | **Verify**: Custom after-validations pass | No duplicates, arrival<departure, fare valid |
| 13 | **Verify**: `DB::beginTransaction()` starts | Transaction active |
| 14 | **Verify**: `$maxOrdinal = PickupPointRoute::max('ordinal')` | If no existing: 0 |
| 15 | **Verify**: Row 1: ordinals = 1 | `$maxOrdinal++` = 1 |
| 16 | **Verify**: Row 2: ordinals = 2 | `$maxOrdinal++` = 2 |
| 17 | **Verify**: Row 3: ordinals = 3 | `$maxOrdinal++` = 3 |
| 18 | **Verify**: `pickup_drop` from Route table | `$route->pickup_drop` stored |
| 19 | **Verify**: arrival_time stored as minutes via `timeToMinutes("07:00")` | 07*60+00 = 420 |
| 20 | **Verify**: departure_time stored as minutes | 07*60+05 = 425 |
| 21 | **Verify**: Each `PickupPointRoute::create()` inserts row | 3 DB rows |
| 22 | **Verify**: `DB::commit()` | Transaction committed |
| 23 | **Verify**: `updateRouteGeometry(routeId)` called | Route's route_geometry recalculated |
| 24 | **Verify**: Redirect to `transport.transport-master.index?tab=assign_stops` | Success |
| 25 | **Verify**: Flash "Pickup Point Routes added successfully." | Success message |
| 26 | **Verify**: List page shows 3 rows with ordinals 1,2,3 | Table populated |

### TC-P-04: Filter index by route+shift+pickup_drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login | Success |
| 2 | Navigate to Transport Master → Assign Stops tab | Tab `assign_stops-pane` active |
| 3 | No filters selected → empty list | `$pickupPointRoutes = collect()` — no data |
| 4 | Select Route = "Route A" from dropdown | Route selected |
| 5 | Select Shift = "Morning" from dropdown | Shift selected |
| 6 | Select Type = "Pickup" from `pickup_drop` dropdown | Type selected |
| 7 | Click Search/Submit | GET with `route_id`, `shift_id`, `pickup_drop` params |
| 8 | **Verify**: `PickupPointRoute::where('route_id', ...)->where('shift_id', ...)->where('pickup_drop', ...)` | Query built with 3 conditions |
| 9 | **Verify**: `->orderBy('ordinal')` | Sorted by ordinal |
| 10 | **Verify**: `->get()` | All matching rows (no pagination) |
| 11 | **Verify**: Table shows: Drag Handle, Route, Pickup Point, Arrival (HH:MM), Departure (HH:MM), Distance, Est. Time, Status toggle, Action | Columns match blade |

### TC-N-03: Duplicate pickup_point_id in same request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift, Route | Valid selections |
| 3 | Add 2 rows | Both rows visible |
| 4 | Row 1: Select Pickup Point = "Main Gate" | pickup_point_id = X |
| 5 | Row 2: Select Pickup Point = "Main Gate" (same) | pickup_point_id = X |
| 6 | Click Save | Form submission |
| 7 | **Verify**: `$pickupPoints = array_column($rows, 'pickup_point_id')` | [X, X] |
| 8 | **Verify**: `count($pickupPoints) !== count(array_unique($pickupPoints))` | true (2 !== 1) |
| 9 | **Verify**: Error added: "Same pickup point cannot be added more than once." | Validation error |
| 10 | **Verify**: No records created | DB unchanged |

### TC-N-04: Pickup point already assigned (store)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a PickupPointRoute with route_id=R1, shift_id=S1, pickup_point_id=X | Existing assignment |
| 2 | Navigate to create form | Form loads |
| 3 | Select Shift=S1, Route=R1 (same as existing) | Same route+shift |
| 4 | Add row with Pickup Point = X (same point) | pickup_point_id = X |
| 5 | Click Save | Form submission |
| 6 | **Verify**: Request method is POST → `$isUpdate = false` | Store path |
| 7 | **Verify**: `PickupPointRoute::where('route_id',R1)->where('shift_id',S1)->where('pickup_point_id',X)->exists()` | true |
| 8 | **Verify**: Error: "This pickup point is already assigned to this route and shift." | Validation error |
| 9 | **Verify**: No duplicate created | DB unchanged |

### TC-N-12: Force delete active record (GAP)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute (active, not deleted) | id=X, deleted_at=NULL |
| 2 | Call `forceDelete(X)` via DELETE or trash action force-delete | Controller hit |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.delete')` passes | Authorized |
| 4 | **Verify**: `PickupPointRoute::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` filters to WHERE deleted_at IS NOT NULL |
| 5 | Record has deleted_at=NULL → not found | `findOrFail()` throws ModelNotFoundException |
| 6 | **Verify**: 404 response | "No query results" |
| 7 | **Compare** with correct pattern: should use `withTrashed()` | `PickupPointRoute::withTrashed()->findOrFail($id)` would find active records |
| 8 | **Workaround**: Must soft-delete first, then force-delete | Two-step process |
| 9 | **Impact**: forceDelete unusable on active records | **GAP** |

### TC-CR-01: GAP — index() missing Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:18-43` | `index()` method |
| 2 | Search for `Gate::authorize()` or `$this->authorize()` | NOT found |
| 3 | Compare with `show()` which has Gate at line 47 | `index()` has NO authorization check |
| 4 | Navigate to `/transport/transport-master?tab=assign_stops` without permission | Page loads (no 403) |
| 5 | **Impact**: Any authenticated user can see the Assign Stops listing | Authorization gap |

### TC-CR-03 through TC-CR-09: GAP — no activityLog in any method

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php` | Full file |
| 2 | Search for `activityLog` | **ZERO matches** |
| 3 | Check each CRUD method: store (line 105), update (line 232), destroy (line 284), restore (line 322), forceDelete (line 351), toggleStatus (line 379), reorder (line 438) | None call `activityLog()` |
| 4 | Compare with RouteController which logs every CRUD | **GAP**: No audit trail for any operation |
| 5 | **Impact**: User actions on Assign Stops are untracked | No history of who created/updated/deleted |

### TC-D-01: Verify auto-ordinal assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check max ordinal for route_id=R1, shift_id=S1 | e.g., current max = 5 |
| 2 | Submit batch store with 2 new rows | Rows submitted |
| 3 | **Verify**: `$maxOrdinal = PickupPointRoute::max('ordinal') ?? 0` | = 5 |
| 4 | **Verify**: Row 1 ordinal = 6 | `$maxOrdinal`++ from 5 → 6 |
| 5 | **Verify**: Row 2 ordinal = 7 | `$maxOrdinal`++ from 6 → 7 |
| 6 | DB check: `SELECT ordinal FROM tpt_pickup_points_route_jnt ORDER BY id DESC LIMIT 2` | [7, 6] |

### TC-D-09: Verify no is_active=false before soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute with is_active=1 | Active record |
| 2 | Note current is_active value | 1 (true) |
| 3 | Call `destroy($id)` | Soft delete |
| 4 | **Verify**: `$pickupRoute->delete()` called directly | No `update(['is_active'=>false])` before delete |
| 5 | DB check: `SELECT is_active, deleted_at FROM tpt_pickup_points_route_jnt WHERE id = X` | `is_active=1`, `deleted_at` IS NOT NULL |
| 6 | **Compare** with RouteController pattern (sets is_active=false first) | **GAP**: record stays active in trash |

### TC-P-02: Add 1 stop with all optional fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift + Route | Valid |
| 3 | Add 1 row | Row visible |
| 4 | Select Pickup Point = "Main Gate" | pickup_point_id set |
| 5 | Enter Arrival = "07:30" | Must be valid H:i format |
| 6 | Enter Departure = "07:35" | After arrival |
| 7 | Enter Distance = 2.5 | Numeric, min:0 |
| 8 | Enter Est. Time = 15 | Numeric, min:0 |
| 9 | Enter Pickup/Drop Fare = 100 (if allowOneSide=true) | Based on setting |
| 10 | Enter Both Side Fare = 80 (if bothSide mode) | Based on setting |
| 11 | Check Active = true | is_active = 1 |
| 12 | Click Save | POST to store |
| 13 | **Verify**: All fields pass validation | Rules pass |
| 14 | **Verify**: `PickupPointRoute::create()` with all fields | DB row has all values |
| 15 | **Verify**: arrival_time=450, departure_time=455 | timeToMinutes converts correctly |

### TC-P-06: Edit existing stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops list | List of stops |
| 2 | Click edit icon on a stop | GET to `/transport/pickup-point-route/{id}/edit` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.edit')` passes | Authorized |
| 4 | **Verify**: `$pickupPointRoutes = PickupPointRoute::with('pickupPoint')->where('id', $id)->first()` | Single record loaded |
| 5 | **Verify**: Supporting data: `PickupPoint::where('is_active',1)->get()`, `Shift::where('is_active',1)->get()`, `Route::where('is_active',1)->get()` | All loaded |
| 6 | **Verify**: Settings loaded: `allow_only_one_side_transport_charges`, `allow_different_pickup_and_drop_point` | normalizeBoolean applied |
| 7 | Edit form shows current values for all fields | Pre-filled |
| 8 | Change Arrival from "07:00" to "07:15" | Updated |
| 9 | Change Pickup/Drop Fare from 50 to 60 | Updated |
| 10 | Click Save | PUT to `/transport/pickup-point-route/{id}` |
| 11 | **Verify**: `PickupPointRouteRequest` rules pass | Valid |
| 12 | **Verify**: `Route::select('id','pickup_drop')->where('id', $request->route_id)->first()` | pickup_drop fetched |
| 13 | **Verify**: `$pickupRoute->update([...])` called | DB updated |
| 14 | **Verify**: `$request->has('is_active')` determines is_active | Checkbox unchecked → is_active=0 |
| 15 | **Verify**: `DB::commit()` | Transaction committed |
| 16 | **Verify**: `updateRouteGeometry($request->route_id)` | Geometry recalculated |
| 17 | **Verify**: Redirect + flash "Pickup Point Route updated successfully." | Success |

### TC-P-07: Toggle status ON to OFF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops list | Stop row visible |
| 2 | Click the status toggle switch | AJAX POST to `/transport/pickup-point-route/{pickupPointRoute}/toggle-status` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.edit')` passes | Authorized |
| 4 | **Verify**: `$request->validate(['is_active' => 'required|boolean'])` passes | Inline validation |
| 5 | **Verify**: `$request->boolean('is_active')` | Returns false (toggle was ON, now OFF) |
| 6 | **Verify**: `$pickupPointRoute->is_active = false` | Property set |
| 7 | **Verify**: `$pickupPointRoute->save()` returns true | DB updated |
| 8 | **Verify**: JSON response `{success: true, message: 'Pickup Point Route Status update'}` | 200 OK |
| 9 | **Verify**: Toggle switch now unchecked | UI updated |

### TC-P-08: Reorder stops via drag-drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops with 3+ stops | List with drag handles |
| 2 | Drag stop #3 to position 1 | SortableJS triggers `onEnd` |
| 3 | **Verify**: `order` array built: `[{id: 3, ordinal: 1}, {id: 1, ordinal: 2}, {id: 2, ordinal: 3}]` | Correct mapping |
| 4 | POST to `/transport/pickup-point-route/reorder` | AJAX request |
| 5 | **Verify**: `Gate::authorize('tenant.pickup-point-route.update')` passes | Authorized |
| 6 | **Verify**: `foreach($request->order as $item)` loops 3 times | 3 iterations |
| 7 | **Verify**: `PickupPointRoute::where('id', $item['id'])->update(['ordinal' => $item['ordinal']])` | Each row updated |
| 8 | **Verify**: JSON response `{success: true}` | 200 OK |
| 9 | **Verify**: Toast "Order updated successfully" | UI feedback |

### TC-P-09: Soft delete a stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops list | Stop row visible |
| 2 | Click delete icon | DELETE to `/transport/pickup-point-route/{id}` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.delete')` passes | Authorized |
| 4 | **Verify**: `DB::beginTransaction()` starts | Transaction active |
| 5 | **Verify**: `PickupPointRoute::findOrFail($id)` | Record found |
| 6 | **Verify**: `$routeId = $pickupRoute->route_id` saved before delete | For geometry update |
| 7 | **Verify**: `$pickupRoute->delete()` | Soft delete, deleted_at set |
| 8 | **Verify**: `DB::commit()` | Committed |
| 9 | **Verify**: `updateRouteGeometry($routeId)` | Geometry recalculated without this stop |
| 10 | **Verify**: Redirect + flash "Pickup point removed successfully." | Success |
| 11 | DB check: `SELECT deleted_at FROM tpt_pickup_points_route_jnt WHERE id = X` | deleted_at IS NOT NULL |

### TC-P-10: Restore soft-deleted stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash tab | Only trashed items |
| 2 | Click restore on a trashed stop | GET to `/transport/pickup-point-route/{id}/restore` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.restore')` passes | Authorized |
| 4 | **Verify**: `PickupPointRoute::onlyTrashed()->findOrFail($id)` | Found in trash |
| 5 | **Verify**: `$routeId = $pickupRoute->route_id` saved | For geometry |
| 6 | **Verify**: `$pickupRoute->restore()` | deleted_at = NULL |
| 7 | **Verify**: `updateRouteGeometry($routeId)` | Geometry recalculated |
| 8 | **Verify**: Redirect + flash "Pickup point restored successfully." | Success |

### TC-N-01: Submit with empty rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift + Route | Valid |
| 3 | Do NOT add any rows | Table empty |
| 4 | Click Save | Form submitted with `rows = []` |
| 5 | **Verify**: `PickupPointRouteRequest` rule: `rows` required, array, min:1 | "The rows must contain at least 1 items." |
| 6 | **Verify**: Error displayed on form | Alert box shows error |

### TC-N-05: arrival_time > departure_time

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift + Route | Valid |
| 3 | Add 1 row | Row visible |
| 4 | Select Pickup Point | Valid |
| 5 | Enter Arrival = "10:00" | After departure |
| 6 | Enter Departure = "09:00" | Before arrival |
| 7 | Click Save | Form submitted |
| 8 | **Verify**: Custom validation: `$row['arrival_time'] > $row['departure_time']` | true |
| 9 | **Verify**: Error: "Departure time must be after arrival time." | on `rows.0.departure_time` |
| 10 | **Verify**: No records created | DB unchanged |

### TC-N-09: Missing fare when allowOneSide=true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Setting `allow_only_one_side_transport_charges` = true | One-side mode |
| 2 | Navigate to create form | Form shows "Pickup / Drop Fare" column |
| 3 | Select Shift + Route | Valid |
| 4 | Add 1 row, fill all fields except `pickup_drop_fare` | Fare left empty |
| 5 | Click Save | Form submitted |
| 6 | **Verify**: `$allowOneSide = true` from settings | true |
| 7 | **Verify**: `empty($row['pickup_drop_fare'])` | true |
| 8 | **Verify**: Error: "Fare is required." | on `rows.0.pickup_drop_fare` |

### TC-N-10: Missing both_side_fare when same-point mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `allow_only_one_side_transport_charges` = false, `allow_different_pickup_and_drop_point` = false | BothSide same-point mode |
| 2 | Navigate to create form | Form shows "Both Fare" column |
| 3 | Add 1 row, fill all fields except `both_side_fare` | Both fare empty |
| 4 | Click Save | Form submitted |
| 5 | **Verify**: `!$allowOneSide && !$allowDifferentPickupDrop` | true |
| 6 | **Verify**: `empty($row['both_side_fare'])` | true |
| 7 | **Verify**: Error: "Both side fare is required." | on `rows.0.both_side_fare` |

### TC-N-11: Missing pickup_drop_fare when diff-point mode

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set `allow_only_one_side_transport_charges` = false, `allow_different_pickup_and_drop_point` = true | Diff-point mode |
| 2 | Navigate to create form | Form shows fare columns |
| 3 | Add 1 row with Pickup type, fill all fields except `pickup_drop_fare` | Fare empty |
| 4 | Click Save | Form submitted |
| 5 | **Verify**: `!$allowOneSide && $allowDifferentPickupDrop` | true |
| 6 | **Verify**: `empty($row['pickup_drop_fare'])` | true |
| 7 | **Verify**: Error: "Pickup fare is required." (where "Pickup" comes from `ucfirst($row['pickup_drop'])`) | Dynamic label |

### TC-D-02: Verify time stored as minutes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop with arrival="07:30" | Time stored |
| 2 | **Verify**: `timeToMinutes("07:30")` returns 450 | `explode(':', "07:30")` = [07, 30], `(7*60)+30` = 450 |
| 3 | DB check: `SELECT arrival_time FROM tpt_pickup_points_route_jnt` | 450 |
| 4 | Display check: `minutesToTime(450)` returns "07:30" | `floor(450/60)=7, 450%60=30` → "07:30" |

### TC-D-04: Verify geometry recalculated after CUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check current `Route.route_geometry` for route_id=R1 | e.g., `[{"lat":28.61,"lng":77.23},...]` |
| 2 | Add new stop with pickup point having lat/lng to route R1 | store triggers updateRouteGeometry |
| 3 | **Verify**: `PickupPointRoute::where('route_id',R1)->whereHas('pickupPoint', fn=>lat+lng)->orderBy('ordinal')->get()` | Points list includes new stop |
| 4 | **Verify**: `Route::where('id',R1)->update(['route_geometry' => json_encode($points)])` | JSON updated |
| 5 | Delete a stop from route R1 | destroy triggers updateRouteGeometry |
| 6 | **Verify**: Route geometry no longer contains deleted stop's coordinates | JSON updated |

### TC-D-06: Verify UNIQUE constraint prevents duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute with route_id=R1, pickup_point_id=X | Created |
| 2 | Manually insert same route_id=R1, pickup_point_id=X via DB | INSERT query |
| 3 | **Verify**: DB throws integrity constraint violation | `Duplicate entry '...' for key 'uq_pickupPointRoute_route_pickupPoint'` |
| 4 | **Note**: PickupPointRouteRequest's custom validation (BC-VAL-C02) should catch this on store before DB | Validation on store prevents reaching DB |

### TC-CR-13: DB transaction in all CUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` at line 108 | `DB::beginTransaction()` — try/catch with `DB::rollback()` on exception |
| 2 | Open `update()` at line 236 | Same pattern |
| 3 | Open `destroy()` at line 288 | Same |
| 4 | Open `restore()` at line 326 | Same |
| 5 | Open `forceDelete()` at line 355 | Same |
| 6 | **Test**: Force exception inside store → verify rollback | All DB changes reverted |

### TC-CR-16: update uses `has()` vs store uses `!empty()` for is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` line 166 | `'is_active' => !empty($row['is_active']) ? 1 : 0` |
| 2 | Open `update()` line 265 | `'is_active' => $request->has('is_active') ? 1 : 0` |
| 3 | **Difference**: `!empty('0')` = false (0 treated as empty) | Store: value "0" becomes 0 |
| 4 | **Difference**: `$request->has('is_active')` = true even for "0" | Update: "0" is still 1 |
| 5 | **Test**: Store with is_active="0" (unchecked but sent as "0") | `!empty("0")` = false → is_active=0 ✓ |
| 6 | **Test**: Update with is_active="0" (unchecked, checkbox removed from DOM) | `$request->has('is_active')` = false → is_active=0 ✓ (but only if checkbox not sent) |
| 7 | **Impact**: Different behavior when value "0" is explicitly sent | Store treats "0" as false, Update treats "0" as true |

### TC-P-03: Add stop with minimal fields (only pickup_point_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Select Shift, Route | Valid |
| 3 | Add 1 row | Row visible |
| 4 | Select Pickup Point only | pickup_point_id set |
| 5 | Leave arrival, departure, distance, est time, fare ALL empty | Optional fields = null |
| 6 | Leave Active = default (checked) | is_active = 1 |
| 7 | Click Save | POST to store |
| 8 | **Verify**: `PickupPointRouteRequest` passes | All nullable fields valid |
| 9 | **Verify**: Controller line 120-122: `empty($row['pickup_point_id'])` = false | Row processed |
| 10 | **Verify**: Controller line 152-154: `!empty($row['arrival_time'])` = false | `arrival_time` = null |
| 11 | **Verify**: Controller line 156-158: `!empty($row['departure_time'])` = false | `departure_time` = null |
| 12 | **Verify**: Controller line 129-131: `!empty($row['pickup_drop_fare'])` = false | `pickup_drop_fare` = 0 (default) |
| 13 | **Verify**: Controller line 133-135: `!empty($row['both_side_fare'])` = false | `both_side_fare` = 0 (default) |
| 14 | **Verify**: `PickupPointRoute::create()` with null times + zero fares | DB row inserted |

### TC-P-04: Filter index by route+shift+pickup_drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with any authenticated user | Success |
| 2 | Navigate to Transport Master → Assign Stops tab | Tab `assign_stops-pane` active |
| 3 | No filters selected → table empty | `$pickupPointRoutes = collect()` — no data |
| 4 | Select Route = "Route A" from `select[name=route_id]` | route_id=R1 |
| 5 | Select Shift = "Morning" from `select[name=shift_id]` | shift_id=S1 |
| 6 | Select Type = "Pickup" from `select[name=pickup_drop]` | pickup_drop="Pickup" |
| 7 | Click Search | GET with route_id=R1, shift_id=S1, pickup_drop="Pickup" |
| 8 | **Verify**: Controller line 24: all 3 params present | `$request->route_id && $request->shift_id && $request->pickup_drop` = true |
| 9 | **Verify**: Controller lines 25-28: `where('route_id',R1)->where('shift_id',S1)->where('pickup_drop','Pickup')` | 3 conditions applied |
| 10 | **Verify**: Controller line 34: `->orderBy('ordinal')` | Sorted ascending |
| 11 | **Verify**: Controller line 35: `->get()` | All matching rows (no pagination) |
| 12 | **Verify**: Table shows columns: Drag Handle, Route, Pickup Point, Arrival (HH:MM), Departure (HH:MM), Total Distance, Est. Time, Status toggle, Action | Blade renders correctly |

### TC-P-05: Search by pickup point name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select Route=R1, Shift=S1, Type="Pickup" (mandatory filters) | Filters set |
| 2 | Enter search text "Main" in search input | `search=Main` |
| 3 | Click Search | GET with all params |
| 4 | **Verify**: Controller line 31-33: `when($request->search, fn=>whereHas('pickupPoint',fn=>where('name','like','%Main%')))` | Subquery filters by pickup point name |
| 5 | **Verify**: Only rows where pickupPoint.name contains "Main" | Filtered results |

### TC-P-11: View single stop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Assign Stops list | List with action buttons |
| 2 | Click view/show icon on a stop | GET to `/transport/pickup-point-route/{id}` |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.view')` | Authorized |
| 4 | **Verify**: `PickupPointRoute::with(['route', 'pickupPoint', 'shift'])->where('id', $id)->orderBy('ordinal')->first()` | Single record loaded with relationships |
| 5 | **Note**: `orderBy('ordinal')` is redundant for single-record lookup | No effect |
| 6 | **Verify**: Show view renders: route name, pickup point name, shift name, arrival/departure (HH:MM), distance, fares, status | All fields visible |

### TC-P-12: Trash list paginated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash URL `/transport/pickup-point-route/trash` | Trash page |
| 2 | **Verify**: `Gate::authorize('tenant.pickup-point-route.view')` | Authorized |
| 3 | **Verify**: `PickupPointRoute::onlyTrashed()->paginate(10)` | 10 items per page, only soft-deleted |
| 4 | **Verify**: Pagination links present if >10 items | `->links()` rendered |

### TC-P-13: Add stop with arrival at midnight boundary

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Set arrival = "00:00" (midnight) | Valid H:i |
| 3 | Set departure = "00:05" | 5 minutes after midnight |
| 4 | Save | `timeToMinutes("00:00")` = 0, `timeToMinutes("00:05")` = 5 |

### TC-P-14: Add stop with arrival at end of day

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form | Loaded |
| 2 | Set arrival = "23:55" | Valid H:i |
| 3 | Set departure = "23:59" | Valid |
| 4 | Save | `timeToMinutes("23:55")` = 1435, `timeToMinutes("23:59")` = 1439 |

### TC-P-15: Create stop with zero distance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form with total_distance = 0 | Valid (min:0) |
| 2 | Save | `total_distance=0.00` stored |

### TC-P-16: Soft-delete then restore the same record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop | id=X, is_active=1 |
| 2 | Call destroy(X) | Soft-deleted, geometry updated |
| 3 | Call restore(X) | `onlyTrashed()` finds it, `->restore()` sets deleted_at=null, geometry updated |
| 4 | **Verify**: Stop back in active list | active_status=1 (was never changed to 0) |

### TC-N-02: Row with empty pickup_point_id is silently skipped

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 2 rows | Row 1 + Row 2 |
| 2 | Row 1: Select Pickup Point = "Main Gate" | Valid |
| 3 | Row 2: Leave Pickup Point empty (no selection) | pickup_point_id = "" or null |
| 4 | Click Save | Form submitted |
| 5 | **Verify**: Controller line 120-122: `if (empty($row['pickup_point_id'])) { continue; }` | Row 2 skipped |
| 6 | **Verify**: Only Row 1 created | 1 DB row |
| 7 | **Verify**: ordinal = 1 (not 2, because Row 2 skipped before increment) | Correct ordinal |
| 8 | **Note**: No error message shown for skipped row | Silent skip — user may be confused |

### TC-N-03: Duplicate pickup_point_id in same request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 3 rows | 3 rows |
| 2 | Row 1: Pickup Point = "Main Gate" | ID=X |
| 3 | Row 2: Pickup Point = "Bus Stand" | ID=Y |
| 4 | Row 3: Pickup Point = "Main Gate" | ID=X (same as Row 1) |
| 5 | Click Save | Form submitted |
| 6 | **Verify**: Request line 76-78: `$pickupPoints = array_column($rows, 'pickup_point_id')` | [X, Y, X] |
| 7 | **Verify**: `count($pickupPoints) !== count(array_unique($pickupPoints))` | 3 !== 2 → true |
| 8 | **Verify**: Error added on `rows` field | "Same pickup point cannot be added more than once." |
| 9 | **Verify**: No records created | DB unchanged |
| 10 | **Verify**: Form re-displayed with error | Alert box shows error |

### TC-N-04: Already assigned pickpoint (store only)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure PickupPointRoute exists: route_id=R1, shift_id=S1, pickup_point_id=X | Existing row |
| 2 | Navigate to create form | Form loads |
| 3 | Select Shift=S1, Route=R1 | Same route+shift |
| 4 | Add row with Pickup Point = X | Same point |
| 5 | Click Save | Form submitted |
| 6 | **Verify**: Request line 53: `$isUpdate = $this->isMethod('PUT') || $this->isMethod('PATCH')` | false (store is POST) |
| 7 | **Verify**: Request line 88: `if (!$isUpdate)` → enters store-only check | true |
| 8 | **Verify**: Request line 95-98: `PickupPointRoute::where('route_id',R1)->where('shift_id',S1)->where('pickup_point_id',X)->exists()` | true |
| 9 | **Verify**: Error: "This pickup point is already assigned to this route and shift." | on rows.X.pickup_point_id |

### TC-N-06: Invalid route_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 1 row | Row visible |
| 2 | Select Shift = valid | OK |
| 3 | Manipulate route_id = 99999 | Non-existent route |
| 4 | Click Save | Form submitted |
| 5 | **Verify**: Rule `route_id` → `exists:tpt_route,id` | "The selected route id is invalid." |

### TC-N-07: Invalid pickup_point_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 1 row | Row visible |
| 2 | Manipulate `rows[0][pickup_point_id]` = 99999 | Non-existent point |
| 3 | Click Save | Form submitted |
| 4 | **Verify**: Rule `rows.*.pickup_point_id` → `exists:tpt_pickup_points,id` | "The selected rows.*.pickup_point_id is invalid." |

### TC-N-08: Negative total_distance

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 1 row | Row visible |
| 2 | Enter total_distance = -5 | Negative value |
| 3 | Click Save | Form submitted |
| 4 | **Verify**: Rule `rows.*.total_distance` → `min:0` | "The rows.0.total_distance must be at least 0." |

### TC-N-13: Restore non-trashed record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active PickupPointRoute (not deleted) | id=X, deleted_at=NULL |
| 2 | Call restore(X) | Controller hit |
| 3 | **Verify**: `Gate::authorize('tenant.pickup-point-route.restore')` | Authorized |
| 4 | **Verify**: `PickupPointRoute::onlyTrashed()->findOrFail($id)` | `onlyTrashed()` → WHERE deleted_at IS NOT NULL |
| 5 | Active record has deleted_at=NULL → not found | `findOrFail()` → ModelNotFoundException |
| 6 | **Verify**: 404 error | "No query results" |

### TC-N-14: Access without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.pickup-point-route.*` | No permissions |
| 2 | Navigate to `/transport/pickup-point-route/create` | `Gate::authorize()` → 403 |
| 3 | POST to `/transport/pickup-point-route` with valid data | `PickupPointRouteRequest::authorize()` → 403 |
| 4 | Navigate to `/transport/pickup-point-route/{id}/edit` | Gate → 403 |
| 5 | Call PUT to `/{id}` | FormRequest authorize → 403 |
| 6 | Call DELETE to `/{id}` | Gate → 403 |
| 7 | Call POST to `/reorder` | Gate → 403 |
| 8 | Call POST to `/toggle-status` | Gate → 403 |
| 9 | **Note**: `index()` has NO Gate — user CAN view list even without permission | **GAP** |

### TC-N-15: Invalid shift_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 1 row | Row visible |
| 2 | Set shift_id = 99999 | Non-existent |
| 3 | Click Save | POST |
| 4 | **Verify**: Rule `shift_id` → `exists:tpt_shift,id` | "The selected shift id is invalid." |

### TC-N-16: All rows skipped (empty pickup_point_id)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add 3 rows | 3 rows |
| 2 | Leave ALL rows with empty pickup_point_id | All rows skipped |
| 3 | Click Save | POST |
| 4 | **Verify**: Controller foreach loop: each row hits `continue` | Loop completes with 0 creates |
| 5 | **Verify**: `DB::commit()` still called | Transaction commits (empty) |
| 6 | **Verify**: `updateRouteGeometry($routeId)` called | Geometry recalculated (no change) |
| 7 | **Verify**: Redirect with success message | "Pickup Point Routes added successfully." |
| 8 | **Issue**: Success message shown but NOTHING was created | **MISLEADING** — user thinks stops were added |

### TC-D-03: Verify pickup_drop taken from Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Route with pickup_drop="Drop" | Route R1 |
| 2 | Navigate to create form, select Route=R1 | System loads route |
| 3 | Add stop, submit | Form submitted |
| 4 | **Verify**: Controller line 137-140: `Route::select('id','pickup_drop')->where('id', $routeId)->where('is_active',1)->first()` | `$route->pickup_drop` = "Drop" |
| 5 | **Verify**: Controller line 148: `'pickup_drop' => $route->pickup_drop` | Stored as "Drop" |
| 6 | DB check: `SELECT pickup_drop FROM tpt_pickup_points_route_jnt` | "Drop" |

### TC-D-05: Verify geometry NULL when no valid points

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute with pickup point that has NULL lat/lng | Point has no coordinates |
| 2 | Call `updateRouteGeometry(routeId)` | Private method |
| 3 | **Verify**: Line 406-418: `PickupPointRoute::where('route_id',routeId)->whereHas('pickupPoint',fn=>whereNotNull('latitude')->whereNotNull('longitude'))` | Empty collection (no valid points) |
| 4 | **Verify**: Line 423: `$points->isEmpty()` | true |
| 5 | **Verify**: Line 424-427: `Route::where('id', routeId)->update(['route_geometry' => null])` | Geometry set to NULL |
| 6 | DB check: `SELECT route_geometry FROM tpt_route WHERE id=routeId` | NULL |

### TC-D-05b: Verify geometry populated when valid points exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute with pickup point having lat=28.61, lng=77.23 | Valid coordinates |
| 2 | Create another with lat=28.62, lng=77.24, ordinal=2 | Second point |
| 3 | Call `updateRouteGeometry(routeId)` | Private method |
| 4 | **Verify**: `$points` = `[['lat'=>28.61,'lng'=>77.23], ['lat'=>28.62,'lng'=>77.24]]` | 2 points, ordered by ordinal |
| 5 | **Verify**: `Route::update(['route_geometry' => json_encode($points)])` | `[{"lat":28.61,"lng":77.23},{"lat":28.62,"lng":77.24}]` |

### TC-D-07: Verify FK CASCADE on route delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count PickupPointRoutes for route_id=R1 | e.g., 5 rows |
| 2 | Delete Route R1 from DB | `DELETE FROM tpt_route WHERE id=R1` |
| 3 | Verify FK `fk_pickupPointRoute_routeId` has `ON DELETE CASCADE` | Migration line 30 |
| 4 | **Verify**: All 5 PickupPointRoutes for route R1 auto-deleted | `SELECT COUNT(*) FROM tpt_pickup_points_route_jnt WHERE route_id=R1` = 0 |
| 5 | **Note**: This is CASCADE behavior, cannot be tested via UI (routes have their own controller) | DB-level integrity |

### TC-D-08: Verify FK CASCADE on pickup point delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Count PickupPointRoutes for pickup_point_id=X | e.g., 3 rows |
| 2 | Delete PickupPoint X from DB | `DELETE FROM tpt_pickup_points WHERE id=X` |
| 3 | Verify FK `fk_pickupPointRoute_pickupPointId` has `ON DELETE CASCADE` | Migration line 32 |
| 4 | **Verify**: All 3 PickupPointRoutes for point X auto-deleted | COUNT = 0 |

### TC-D-10: Verify reorder persists correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 3 stops exist with ordinals 1,2,3 | order: A(1), B(2), C(3) |
| 2 | Drag C to position 1 | SortableJS sends `order` array |
| 3 | **Verify**: POST body: `{order: [{id:C, ordinal:1}, {id:A, ordinal:2}, {id:B, ordinal:3}]}` | Correct mapping |
| 4 | **Verify**: Controller: 3 iterations of `PickupPointRoute::where('id',id)->update(['ordinal'=>ordinal])` | 3 updates |
| 5 | DB check: `SELECT id, ordinal FROM tpt_pickup_points_route_jnt ORDER BY ordinal` | C(1), A(2), B(3) |

### TC-CR-02: GAP — store() relies only on FormRequest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:105-108` | `store()` method starts with `DB::beginTransaction()` |
| 2 | No `Gate::authorize()` call in method body | **MISSING** |
| 3 | Open `PickupPointRouteRequest.php:12-18` | `authorize()` checks POST → `tenant.pickup-point-route.create` |
| 4 | **Risk**: If FormRequest is bypassed (e.g., controller called directly), store() has no guard | Authorization gap |
| 5 | Compare with `create()` line 60 which HAS `Gate::authorize()` directly | Inconsistent pattern |

### TC-CR-12: GAP — show() has redundant orderBy

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:49-52` | `PickupPointRoute::with(...)->where('id', $id)->orderBy('ordinal')->first()` |
| 2 | `where('id', $id)` returns at most 1 record | Ordering a single record has no effect |
| 3 | **Impact**: No functional impact, but unnecessary query clause | Minor code smell |

### TC-CR-14: updateRouteGeometry() called after every CUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `store()` line 171 | `$this->updateRouteGeometry($routeId)` |
| 2 | Open `update()` line 269 | `$this->updateRouteGeometry($request->route_id)` |
| 3 | Open `destroy()` line 297 | `$this->updateRouteGeometry($routeId)` |
| 4 | Open `restore()` line 335 | `$this->updateRouteGeometry($routeId)` |
| 5 | Open `forceDelete()` line 364 | `$this->updateRouteGeometry($routeId)` |
| 6 | **Verify**: All 5 CUD methods call updateRouteGeometry after commit | Geometry always in sync |
| 7 | **Note**: `toggleStatus()` does NOT call updateRouteGeometry | Status toggle doesn't change route geometry (correct) |
| 8 | **Note**: `reorder()` does NOT call updateRouteGeometry | Reorder changes ordinal but geometry recalculation not triggered — **potential GAP** |

### TC-CR-15: 4 custom after-validations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteRequest.php:76-83` | Validation 1: Duplicate pickup_point_id in request |
| 2 | Open `PickupPointRouteRequest.php:88-107` | Validation 2: Already assigned to DB (store only, guarded by `!$isUpdate`) |
| 3 | Open `PickupPointRouteRequest.php:112-123` | Validation 3: arrival_time must be before departure_time |
| 4 | Open `PickupPointRouteRequest.php:128-159` | Validation 4a/4b/4c: Fare required based on settings (3 sub-conditions) |
| 5 | **Verify**: All 4 validations run inside `$validator->after()` closure | After-validation hooks |
| 6 | **Verify**: Settings are queried fresh each request from `sys_settings` table | DB query per request |

### TC-CR-17: Reuse of delete permission for forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` line 286 | `Gate::authorize('tenant.pickup-point-route.delete')` |
| 2 | Open `forceDelete()` line 353 | `Gate::authorize('tenant.pickup-point-route.delete')` — SAME permission |
| 3 | **Implication**: No separate `forceDelete` permission exists | User with delete can also forceDelete |
| 4 | Compare with other controllers that have distinct `forceDelete` permission | Inconsistent authorization model |

### TC-CR-18: normalizeBoolean() helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:84-93` | Private method |
| 2 | Input: boolean `true` → returns `true` | `is_bool($value)` check |
| 3 | Input: string "1", "true", "ture", "yes", "on" → returns `true` | `in_array()` with lowercase |
| 4 | Input: string "0", "false", "no", "off" → returns `false` | Not in allowed array |
| 5 | Input: "ture" (typo) → returns `true` | Intentional — handles common misspelling |
| 6 | Used in `create()` and `edit()` to normalize settings values | Applied to `allowOneSide` and `allowDifferentPickupDrop` |

### TC-CR-19: timeToMinutes() conversion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:186-190` | Private method |
| 2 | Input: "07:30" → `explode(':', "07:30")` = ["07", "30"] | `(7*60)+30` = 450 |
| 3 | Input: "00:00" → ["00","00"] | `(0*60)+0` = 0 |
| 4 | Input: "23:59" → ["23","59"] | `(23*60)+59` = 1439 |
| 5 | Used in store() lines 152-158 and update() lines 251-257 | Both batch and single record |

### TC-CR-20: getRoutesByShift() AJAX endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/transport/pickup-point-route/get-routes/{shiftId}` | AJAX endpoint |
| 2 | **Verify**: `Route::where('shift_id', $shiftId)->where('is_active', 1)->select('id','name')->get()` | Active routes for shift |
| 3 | **Verify**: JSON response with route id+name pairs | `[{id:1, name:"Route A"}, ...]` |

### TC-CR-21: store() does not validate route is_active for existence check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteRequest.php:23` | Rule: `'route_id' => ['required', 'exists:tpt_route,id']` |
| 2 | **Note**: `exists:tpt_route,id` checks ANY route, not just `is_active=1` | Inactive route can be used |
| 3 | Controller line 137-140: `Route::select(...)->where('id',$routeId)->where('is_active',1)->first()` | Only fetches pickup_drop if active |
| 4 | **Risk**: If route is inactive, `$route` may be null → `$route->pickup_drop` throws error | `Call to member function pickup_drop on null` |
| 5 | **Test**: Set route to is_active=0, then create PickupPointRoute with that route_id | **500 error** — null pointer on line 148 |

### TC-CR-22: show() does not handle null return from first()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:49-55` | `->where('id', $id)->...->first()` then passes to view |
| 2 | `first()` returns null if ID not found (no `findOrFail()`) | Null passed to view |
| 3 | View tries to access `$pickupPointRoute->route` etc. | **500 error** — null property access |
| 4 | Compare with `edit()` which does NOT validate existence either (no findOrFail) | Same issue |

### TC-CR-23: edit() does not validate ID existence

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRouteController.php:192-229` | `edit($pickupPointRouteId)` |
| 2 | Line 197: `PickupPointRoute::with('pickupPoint')->where('id', $pickupPointRouteId)->first()` | No `findOrFail()`, no null check |
| 3 | **Test**: Call edit with invalid ID (99999) | `$pickupPointRoutes = null`, passed to view → **500 error** |

### TC-N-17: arrival_time invalid format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add row | Row visible |
| 2 | Enter arrival = "25:00" (invalid hour) | Not valid H:i |
| 3 | Click Save | POST |
| 4 | **Verify**: Rule `date_format:H:i` fails | "The rows.0.arrival_time does not match the format H:i." |

### TC-N-18: departure_time invalid format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, add row | Row visible |
| 2 | Enter departure = "07:60" (invalid minute) | Not valid H:i |
| 3 | Click Save | POST |
| 4 | **Verify**: Rule `date_format:H:i` fails | "The rows.0.departure_time does not match the format H:i." |

### TC-N-19: Store with inactive route_id (null pointer bug)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set Route R1 to is_active=0 | Route inactive |
| 2 | Create PickupPointRoute with route_id=R1 (validation passes because `exists:tpt_route,id` ignores is_active) | Validation OK |
| 3 | Controller line 137-140: `Route::select(...)->where('id',$routeId)->where('is_active',1)->first()` | `$route = null` (route not active) |
| 4 | Controller line 148: `'pickup_drop' => $route->pickup_drop` | **Error**: `Call to a member function pickup_drop on null` |
| 5 | `DB::rollBack()` triggered by catch block | Transaction rolled back |
| 6 | Error returned: "Something went wrong: Call to a member function pickup_drop on null" | User sees 500 error |

### TC-N-20: show() with non-existent ID (null pointer bug)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/transport/pickup-point-route/{id}` with id=99999 | Non-existent |
| 2 | Controller line 49-52: `->where('id',99999)->first()` | `$pickupPointRoute = null` |
| 3 | View tries `$pickupPointRoute->route` → null access | **500 error** |

### TC-N-21: edit() with non-existent ID (null pointer bug)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call GET `/transport/pickup-point-route/99999/edit` | Non-existent |
| 2 | Controller line 197: `->where('id',99999)->first()` | `$pickupPointRoutes = null` |
| 3 | View receives null variable | **500 error** |

### TC-D-11: Verify transaction rollback on exception in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create PickupPointRoute with route_id=R1 that causes exception | e.g., inactive route as in TC-N-19 |
| 2 | Controller line 108: `DB::beginTransaction()` | Transaction started |
| 3 | Some rows may have been inserted before exception | Partial inserts |
| 4 | Controller line 177-183: catch block calls `DB::rollBack()` | All DB changes reverted |
| 5 | **Verify**: No rows created despite partial inserts | COUNT unchanged |

### TC-D-12: Verify reorder does NOT call updateRouteGeometry

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `reorder()` method lines 438-448 | Only updates ordinals |
| 2 | No call to `$this->updateRouteGeometry()` | **MISSING** |
| 3 | **Impact**: Route geometry JSON reflects OLD ordinal order | Geometry out of sync with actual stop order |
| 4 | DB check: route_geometry order vs actual ordinal order | Mismatch after reorder |

### TC-BIZ-DEEP-01: Default attributes from model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:38-42` | `$attributes = ['is_active' => true, 'ordinal' => 1, 'pickup_drop' => 'Pickup']` |
| 2 | Create PickupPointRoute without setting these fields | Defaults applied |
| 3 | **Verify**: `is_active = true` | No explicit set needed |
| 4 | **Verify**: `pickup_drop = 'Pickup'` | Overridden by controller (line 148) which explicitly sets from Route table |

### TC-BIZ-DEEP-02: Soft deletes on BaseModel

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:7` | `extends BaseModel` |
| 2 | Check if BaseModel uses `SoftDeletes` trait | Yes (all BaseModel models support soft deletes) |
| 3 | Migration line 41: `$table->softDeletes()` | `deleted_at` column present |
| 4 | `destroy()` calls `->delete()` | Sets `deleted_at` timestamp |

### TC-BIZ-DEEP-03: Model casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:27-36` | Casts: is_active→boolean, total_distance→decimal:2, pickup_drop_fare→decimal:2, both_side_fare→decimal:2, ordinal→integer, arrival_time→integer, departure_time→integer, estimated_time→integer |
| 2 | Create with is_active=1 → `$model->is_active` returns `true` (boolean) | Correct cast |
| 3 | Create with total_distance=5.5 → `$model->total_distance` returns `5.50` | decimal:2 format |

### TC-BIZ-DEEP-04: Fillable fields vs DDL columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php:12-25` | 12 fillable fields |
| 2 | Open migration lines 14-41 | DDL has 16 columns (id, pickup_drop, ordinal, total_distance, arrival_time, departure_time, estimated_time, pickup_drop_fare, both_side_fare, is_active, shift_id, route_id, pickup_point_id, timestamps, deleted_at) |
| 3 | **Note**: `id`, `shift_id`, `route_id`, `pickup_point_id`, timestamps, `deleted_at` are NOT in `$fillable` | Correct — these are set by FK/auto |

### TC-BIZ-DEEP-05: Controller sets fare defaults to 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() lines 126-135 | `$pickupDropFare = 0; $bothSideFare = 0;` |
| 2 | Only overrides if `!empty($row['pickup_drop_fare'])` | Fare defaults to 0 |
| 3 | Update() lines 262-263: `$request->pickup_drop_fare ?? 0` | Same default 0 |

### TC-BIZ-DEEP-06: index() uses get() not paginate()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open controller line 35 | `->get()` returns all matching rows |
| 2 | **Note**: No pagination on index listing | All stops for a route displayed at once |
| 3 | Blade line 140 tries `$pickupPointRoutes->appends(...)->links()` | `->links()` on a Collection → **error** (links() requires LengthAwarePaginator) |
| 4 | **Verify**: `get()` returns Collection, not Paginator | Pagination links may error if `$pickupPointRoutes` has items |
| 5 | When `$pickupPointRoutes` is empty collection → `links()` works on Collection | Conditional behavior |

### TC-BIZ-DEEP-07: create() loads only active entities

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create()` lines 76-78 | `Route::where('is_active',1)->get()`, `PickupPoint::where('is_active',1)->get()`, `Shift::where('is_active',1)->get()` |
| 2 | Only active routes/shifts/points available in create form | Inactive entities hidden |
| 3 | But store validation only checks `exists:tpt_route,id` (ignores is_active) | Inconsistency: form hides but API accepts inactive |

### TC-BIZ-DEEP-08: update() fare defaults differ from store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store line 129-131: `if (!empty($row['pickup_drop_fare']))` → uses row value, else 0 | Conditional assignment |
| 2 | Update line 262: `$request->pickup_drop_fare ?? 0` | Null coalescing |
| 3 | **Difference**: Store uses `!empty()` which treats "0" as empty → falls to 0 | Same end result |
| 4 | Update uses `??` which only catches null, not empty string | If empty string "", `??` keeps "" → cast to 0 by model |

### TC-BIZ-DEEP-09: toggleStatus() uses inline validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` line 383-385 | `$request->validate(['is_active' => 'required|boolean'])` |
| 2 | **Note**: Does NOT use `PickupPointRouteRequest` | Inline validation only |
| 3 | Uses route-model-binding: `PickupPointRoute $pickupPointRoute` | Auto-resolved, no 404 check needed |

### TC-BIZ-DEEP-10: Index displays time via minutesToTime helper

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 6-16: `minutesToTime()` helper function | Converts INT minutes to HH:MM string |
| 2 | Input 450 → `floor(450/60)=7`, `450%60=30` → "07:30" | Correct |
| 3 | Input 0 → `floor(0/60)=0`, `0%60=0` → "00:00" | Midnight |
| 4 | Input null → returns '-' | Null safe |

### TC-BIZ-DEEP-11: Status toggle sends different response for success vs failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `toggleStatus()` line 389-398 | `if ($pickupPointRoute->save())` → success JSON, else → failure JSON |
| 2 | **Success**: `{success: true, message: 'Pickup Point Route Status update'}` | 200 OK |
| 3 | **Failure**: `{success: false, message: 'Status update failed'}` | 200 OK (not 500) |

### TC-BIZ-DEEP-12: Arrival/departure both stored as INT minutes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert stop with arrival="08:15", departure="08:20" | Both times set |
| 2 | DB: `arrival_time` = 495 (8*60+15) | `departure_time` = 500 (8*60+20) |
| 3 | Model casts: `arrival_time` → integer, `departure_time` → integer | PHP integer type |

### TC-BIZ-DEEP-13: SortableJS sends POST with JSON body

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade lines 168-175 | `fetch(reorderUrl, {method: POST, headers: {Content-Type: application/json}, body: JSON.stringify({order})})` |
| 2 | Request body: `{order: [{id: 1, ordinal: 3}, {id: 2, ordinal: 1}, {id: 3, ordinal: 2}]}` | JSON format |
| 3 | Controller line 442: `foreach ($request->order as $item)` | Laravel auto-decodes JSON to array |

### TC-BIZ-DEEP-14: Scrollable index with appends for tab param

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open blade line 140 | `$pickupPointRoutes->appends(['tab' => request('tab', 'assign_stops')])->links()` |
| 2 | **Issue**: Controller uses `->get()` not `->paginate()` | `$pickupPointRoutes` is Collection → `->links()` not available |
| 3 | **Potential error**: `BadMethodCallException` when calling `->links()` on Collection | If data is loaded (3 filters present), pagination breaks |
| 4 | **Note**: Only works when `$pickupPointRoutes` is empty Collection (no data loaded) | `empty()->links()` → empty string |

### TC-BIZ-DEEP-15: No is_system_defined guard in controller

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search controller for `is_system_defined` | NOT found |
| 2 | **Note**: Unlike Syllabus entities, PickupPointRoute has no system-defined protection | All records editable/deletable |

### TC-BIZ-DEEP-16: No change tracking in update()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `update()` lines 232-282 | Calls `$pickupRoute->update([...])` |
| 2 | No `getOriginal()` / `getChanges()` calls before/after | **No change tracking** |
| 3 | No activityLog to record what changed | Audit trail absent |

### TC-BIZ-DEEP-17: destroy() uses findOrFail not route-model-binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `destroy()` line 284-310 | `destroy($id)` — manual ID parameter |
| 2 | Line 291: `PickupPointRoute::findOrFail($id)` | Uses findOrFail, proper 404 on missing |
| 3 | Compare with `toggleStatus()` which uses route-model-binding | Inconsistent parameter styles |

### TC-BIZ-DEEP-18: forceDelete reuses delete Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `forceDelete()` line 351-377 | `Gate::authorize('tenant.pickup-point-route.delete')` |
| 2 | No `forceDelete` permission in policy | Same permission as soft delete |
| 3 | **Implication**: Any user with delete permission can permanently delete | No additional guard for permanent deletion |

### TC-BIZ-DEEP-19: trashed() paginates at 10

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trashed()` line 317 | `PickupPointRoute::onlyTrashed()->paginate(10)` |
| 2 | Paginated at 10 per page | Consistent with other entities |

### TC-BIZ-DEEP-20: Success messages are hardcoded strings (not flash keys)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 174-175 | `->with('success', 'Pickup Point Routes added successfully.')` — hardcoded string |
| 2 | Open update() line 272-273 | `->with('success', 'Pickup Point Route updated successfully.')` — hardcoded |
| 3 | Open destroy() line 300-301 | `->with('success', 'Pickup point removed successfully.')` — hardcoded |
| 4 | Open restore() line 338-339 | `->with('success', 'Pickup point restored successfully.')` — hardcoded |
| 5 | Open forceDelete() line 367-368 | `->with('success', 'Pickup point permanently deleted.')` — hardcoded |
| 6 | **Note**: Unlike other Transport controllers which use `flash('key')` pattern | Inconsistent — these are plain strings |

### TC-BIZ-DEEP-21: Error messages use back()->withErrors()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() catch block lines 180-183 | `return back()->withErrors(['error' => 'Something went wrong: ' . $e->getMessage()])` |
| 2 | Same pattern in update(), destroy(), restore(), forceDelete() | Consistent error handling |
| 3 | **Note**: Generic error message exposes exception details to user | Potential information disclosure |

### TC-BIZ-DEEP-22: Pickup points filtered by is_active in create() but NOT in edit()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create()` line 77 | `PickupPoint::where('is_active', 1)->get()` |
| 2 | Open `edit()` line 203 | `PickupPoint::where('is_active', 1)->get()` |
| 3 | Both use active-only pickup points | Consistent |

### TC-BIZ-DEEP-23: Shift/Route loaded without is_active filter in index()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `index()` line 20-21 | `Route::all()` and `Shift::all()` — NO is_active filter |
| 2 | **Note**: All routes and shifts shown in filter dropdowns, even inactive | User can filter by inactive route |

### TC-BIZ-DEEP-24: Settings query per request

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `create()` lines 62-65 | `Setting::whereIn('key', [...])->pluck('value', 'key')` |
| 2 | Open `edit()` lines 208-211 | Same query |
| 3 | Open `PickupPointRouteRequest.php:58-61` | Same query in after-validation |
| 4 | Settings queried 3 times per store operation (create() view + request validation + store() actually uses request, not own query) | 2 DB queries for settings per form load |

### TC-BIZ-DEEP-25: store() route query selects only id, pickup_drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open store() line 137-140 | `Route::select('id', 'pickup_drop')->where('id', $routeId)->where('is_active', 1)->first()` |
| 2 | Minimal select — only 2 columns fetched | Efficient query |

### TC-BIZ-DEEP-26: Arrival without departure (or vice versa)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop with arrival="07:30", departure=empty | Only arrival set |
| 2 | Controller: `!empty($row['departure_time'])` = false → `departure_time = null` | departure_time is NULL |
| 3 | DB: arrival=450, departure=NULL | Partial time OK |
| 4 | Display: arrival="07:30", departure="-" | minutesToTime(null) = '-' |

### TC-BIZ-DEEP-27: Estimated_time and total_distance both nullable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create stop with only distance, no est_time | `total_distance=5.5`, `estimated_time=null` |
| 2 | Create stop with only est_time, no distance | `estimated_time=20`, `total_distance=null` |
| 3 | Both NULL | Both displayed as '-' in blade |

### TC-BIZ-DEEP-28: Blade conditionally shows fare columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setting allowOneSide=true → blade shows "Pickup / Drop Fare" column | `@if($allowOneSide)` line 58 |
| 2 | Setting allowOneSide=false AND allowDifferentPickupDrop=true → blade shows "Both Fare" column | `@if($allowDifferentPickupDrop)` line 63 |
| 3 | Setting allowOneSide=false AND allowDifferentPickupDrop=false → both fare columns hidden | User cannot enter fare |

### TC-BIZ-DEEP-29: getRoutesByShift returns only active routes for shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Route R1 with shift_id=S1, is_active=1 | Active route for shift |
| 2 | Create Route R2 with shift_id=S1, is_active=0 | Inactive route for shift |
| 3 | Call getRoutesByShift(S1) | Only R1 returned (is_active=1) |
| 4 | **Verify**: `Route::where('shift_id',S1)->where('is_active',1)->select('id','name')->get()` | `[{id:R1, name:"Route A"}]` |

### TC-BIZ-DEEP-30: Both side fare column visible only with settings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | allowOneSide=false, allowDifferentPickupDrop=true | Both fare column visible |
| 2 | allowOneSide=false, allowDifferentPickupDrop=false | No fare column visible |
| 3 | allowOneSide=true | Pickup/Drop fare column visible (overrides other settings) |

### TC-BIZ-DEEP-31: Controller store accepts is_active as 1/0 from checkbox

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Checkbox checked → browser sends `is_active=1` (or "on") | `!empty("1")` = true → is_active=1 |
| 2 | Checkbox unchecked → browser sends nothing (or hidden 0) | `!empty(null)` = false → is_active=0 |
| 3 | **Note**: HTML checkbox doesn't send value when unchecked | `!empty()` correctly treats missing as false |

### TC-BIZ-DEEP-32: Update() uses has() for checkbox — different behavior

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Checkbox checked in edit form → `has('is_active')` = true | is_active=1 |
| 2 | Checkbox unchecked → `has('is_active')` = false | is_active=0 |
| 3 | Hidden input with 0 sent alongside checkbox → `has('is_active')` = true (sees "0") | is_active=1 — **Bug**: "0" treated as checked |
| 4 | **Issue**: If form includes hidden `is_active=0` + checkbox `is_active=1`, `has()` returns true for both | Last value wins depend on request order |

### TC-BIZ-DEEP-33: updateRouteGeometry uses whereHas to filter valid points

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 407-410: `whereHas('pickupPoint', fn($q) => $q->whereNotNull('latitude')->whereNotNull('longitude'))` | Only points with coordinates included |
| 2 | Point with lat=null → excluded | Geometry incomplete |
| 3 | Point with lat=0, lng=0 → included (0 is valid coordinate) | Not excluded |

### TC-BIZ-DEEP-34: Geometry stores float values from string casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 414-416: `map(fn ($row) => ['lat' => (float) $row->pickupPoint->latitude, 'lng' => (float) $row->pickupPoint->longitude])` | Cast to float |
| 2 | Input "28.610000" → (float) = 28.61 | Float cast |
| 3 | JSON: `[{"lat":28.61,"lng":77.23}]` | Float values in JSON |

### TC-BIZ-DEEP-35: Store skip row has performance consideration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 120-122: `if (empty($row['pickup_point_id'])) { continue; }` | Skip row |
| 2 | **Note**: Skipped row still gets validated by PickupPointRouteRequest (required rule fires first) | Validation catches empty pickup_point_id before controller runs |
| 3 | **Impact**: Request validation `required` rule prevents empty pickup_point_id from reaching controller | Controller skip is dead code for happy path |

### TC-BIZ-DEEP-36: Store rows.*.pickup_point_id validation fires before custom validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Rule line 29: `'rows.*.pickup_point_id' => ['required', 'exists:tpt_pickup_points,id']` | Base validation |
| 2 | Custom after-validation lines 76-83: duplicate in request | Custom runs after |
| 3 | Base validation fails first → custom validation never reached | Duplicate check only runs if base passes |

### TC-BIZ-DEEP-37: Duplicate DB check only runs on store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 88: `if (!$isUpdate)` | Guard for store-only |
| 2 | Update can assign a pickup_point_id that's already used by another stop on same route | No duplicate check on update |
| 3 | **Impact**: After update, two stops on same route+shift can have same pickup_point_id | **Data integrity risk** on update |

### TC-BIZ-DEEP-38: ForceDelete with already-deleted record works

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete stop X (deleted_at set) | Trashed |
| 2 | Call forceDelete(X) | `onlyTrashed()` finds it |
| 3 | **Verify**: `$pickupRoute->forceDelete()` | Permanently removed |
| 4 | Geometry recalculated without stop X | Geometry updated |

### TC-BIZ-DEEP-39: Restore restores with is_active unchanged

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete stop with is_active=1 | Trashed, active |
| 2 | Restore | deleted_at=NULL, is_active stays 1 |
| 3 | **Note**: Unlike destroy() which leaves is_active=true, restore() also leaves it unchanged | Consistent |

### TC-BIZ-DEEP-40: toggleStatus validates is_active is boolean inline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Line 383-385: `$request->validate(['is_active' => 'required|boolean'])` | Inline validation |
| 2 | Send is_active="abc" | "The is_active field must be true or false." |
| 3 | Send is_active=1 | Valid |
| 4 | Send is_active=true | Valid (PHP boolean converted to string "true" → boolean rule accepts) |
| 5 | Send is_active=0 | Valid |
| 6 | Missing is_active | "The is_active field is required." |

### TC-BIZ-DEEP-41: store() route_id uses both where clauses

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Validation: `exists:tpt_route,id` (any route, including inactive) | Passes for active AND inactive routes |
| 2 | Controller line 139: `where('is_active', 1)` | Only fetches if active |
| 3 | **Gap**: Validate allows inactive, controller crashes on inactive | **Bug** documented in TC-N-19 |

### TC-BIZ-DEEP-42: Fare validation settings loaded from sys_settings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create/Edit form: `Setting::whereIn('key', [...])->pluck('value', 'key')` | Loads both settings |
| 2 | Request validation: same query | Queried again inside `withValidator()` |
| 3 | Settings cached in PHP variable per request | No cache/memoization |

### TC-BIZ-DEEP-43: PickupPointRoute model lacks SoftDeletes import

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `PickupPointRoute.php` | `use App\Models\BaseModel` |
| 2 | `BaseModel` likely uses SoftDeletes | Check BaseModel for `SoftDeletes` trait |
| 3 | Migration has `$table->softDeletes()` | Column exists |
| 4 | **Verify**: `destroy()` calls `->delete()` | Works via BaseModel's SoftDeletes |

### TC-BIZ-DEEP-44: Blade uses @canany for action column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Index blade line 95-97: `@canany(['tenant.pickup-point-route.edit', 'tenant.pickup-point-route.delete'])` | Action column visible if user has edit OR delete |
| 2 | User with edit only → sees Action column | Conditional rendering |
| 3 | User with neither → Action column hidden | Width 110 not rendered |

### TC-BIZ-DEEP-45: Store with empty rows but valid route/shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form, select Shift=R1, Route=S1 | Valid route+shift |
| 2 | Do NOT add any rows | Table empty |
| 3 | Click Save | POST with `route_id=R1, shift_id=S1, rows=[]` |
| 4 | Validation: `rows` required, min:1 | "The rows must contain at least 1 items." |

### TC-BIZ-DEEP-46: Pickup point dropdown in create form shows all active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create() loads `PickupPoint::where('is_active', 1)->get()` | All active points |
| 2 | Blade renders each as `<option value="{{ $point->id }}">` | Dropdown populated |
| 3 | Inactive pickup points NOT shown | Filtered out |

### TC-BIZ-DEEP-47: Route dropdown in create uses AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create form: Route dropdown initially empty | `<option value="">Select Route</option>` |
| 2 | Select Shift → JS calls GET `/transport/pickup-point-route/get-routes/{shiftId}` | AJAX |
| 3 | Routes populated dynamically | `<option value="1">Route A</option>` |

### TC-BIZ-DEEP-48: Store success message not translatable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store line 174-175: `->with('success', 'Pickup Point Routes added successfully.')` | Hardcoded English string |
| 2 | No `__()` or `flash()` wrapper | Not translatable |
| 3 | All 5 success messages are hardcoded | No localization support |

### TC-BIZ-DEEP-49: store() fare default to 0 vs null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `$pickupDropFare = 0` (line 126) | Default 0, not null |
| 2 | `both_side_fare: $bothSideFare = 0` (line 127) | Default 0, not null |
| 3 | DDL: `pickup_drop_fare DECIMAL(10,2) NULLABLE` | Default 0 vs DB nullable |
| 4 | **Note**: 0 is stored explicitly, not null | Difference from DB schema intent |

### TC-BIZ-DEEP-50: index() shows - for null values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Blade line 112: `{{ $item->total_distance ?? '-' }}` | Null → '-' |
| 2 | Blade line 113: `{{ $item->estimated_time ?? '-' }}` | Null → '-' |
| 3 | Blade line 110: `minutesToTime($item->arrival_time)` with null → returns '-' | Null safe via helper |

### TC-BIZ-DEEP-51: updateRouteGeometry with mixed valid/invalid points

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route R1 has 5 stops: 3 with lat/lng, 2 with null lat | Mixed points |
| 2 | `updateRouteGeometry()`: `whereHas('pickupPoint', fn => whereNotNull lat/lng)` | Only 3 valid points |
| 3 | Geometry JSON: 3 points, ordered by ordinal | Partial geometry |

### TC-BIZ-DEEP-52: PickupPointRoute scopeActive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open model line 44-47: `scopeActive($query) { return $query->where('is_active', true); }` | Scope defined |
| 2 | **Note**: scopeActive NOT used in controller | No active filter in queries |
| 3 | **Impact**: Index shows both active AND inactive stops | No default active filter |

### TC-BIZ-DEEP-53: Model default attributes vs controller override

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Model `$attributes = ['is_active' => true, 'ordinal' => 1, 'pickup_drop' => 'Pickup']` | Defaults |
| 2 | Store line 148: `'pickup_drop' => $route->pickup_drop` | Overrides pickup_drop default with route's value |
| 3 | Store line 150: `'ordinal' => $maxOrdinal` | Overrides ordinal default |
| 4 | Store line 166: `'is_active' => !empty($row['is_active']) ? 1 : 0` | Overrides is_active default |
| 5 | **Model defaults are never used** because controller always sets these 3 fields | Defaults only apply if create() called without these fields |

### TC-BIZ-DEEP-54: show() passes single record to view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `show()` returns `view('transport::pickup_point_route.show', compact('pickupPointRoute'))` | Single variable |
| 2 | `$pickupPointRoute` is one model instance (or null) | Singular naming |

### TC-BIZ-DEEP-55: trashed() uses paginate, index() uses get()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `trashed()`: `onlyTrashed()->paginate(10)` | Paginated |
| 2 | `index()`: `->get()` (when filters present) | All results |
| 3 | **Inconsistency**: Trash is paginated but main list is not | Potential performance issue with many stops |

---

*Template: tpt_FineCategory_TcList.md (code-only) | Entity: PickupStopsList (PickupPointRoute) | Date: 2026-07-21*
