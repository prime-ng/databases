# tpt_Route_TcList

## Module: Transport → Transport Master → Route

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Transport Master |
| Feature | Route |
| URL(s) | `/transport/master` (index via tab), `/route` (create form), `/route` (store), `/route/{id}` (show), `/route/{id}/edit` (edit), `/route/{id}` (update PUT), `/route/{id}` (destroy DELETE), `/route/trash/view` (trash), `/route/{id}/restore` (restore GET), `/route/{id}/force-delete` (forceDelete DELETE), `/route/{route}/toggle-status` (toggleStatus POST) |
| Controller | `Modules\Transport\Http\Controllers\RouteController` |
| Tab Container Controller | `Modules\Transport\Http\Controllers\TransportMasterController@index()` |
| Model | `Modules\Transport\Models\Route` — table: `tpt_route` |
| Validation (Create + Update) | `Modules\Transport\Http\Requests\RouteRequest` |
| Permissions | `tenant.route.viewAny`, `tenant.route.view`, `tenant.route.create`, `tenant.route.update`, `tenant.route.edit` (⚠️ defined in `permissionslist.php` but **no Policy method `edit()`** — see BC-AUTH-05), `tenant.route.delete`, `tenant.route.restore`, `tenant.route.forceDelete`, `tenant.route.status` (defined in Policy but controller uses `tenant.route.update` instead — see BC-AUTH-09), `tenant.route.import`, `tenant.route.export`, `tenant.route.print` |
| Soft Deletes | Yes (`Route` uses `SoftDeletes` trait) |
| Activity Log | Events: `Stored` (create), `Updated`, `Trashed` (soft delete), `Restored`, `Deleted` (force delete), `Toggled` (toggleStatus) |
| Import / Export | Not implemented in RouteController |

---

## 2. Pre-conditions

- Required permissions: `tenant.route.viewAny`, `tenant.route.view`, `tenant.route.create`, `tenant.route.update`, `tenant.route.delete`, `tenant.route.restore`, `tenant.route.forceDelete`, `tenant.route.status` (⚠️ `tenant.route.edit` is in permissionslist.php but has NO Policy method — makes Blade @can checks always fail for non-super-admin users; ⚠️ `tenant.route.status` is defined in Policy but controller uses `tenant.route.update` for toggleStatus instead)
- Required seed data: At least one active `Shift` (tpt_shift) with `is_active = 1`
- Test user must have all above permissions (default admin user)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Route geometry column is `LINESTRING SRID 4326` — test data must provide geometry via `DB::raw("ST_GeomFromText('LINESTRING(...)', 4326)")`
- The Route tab is loaded as part of TransportMaster — the URL `/transport/master?tab=route` loads TransportMasterController@index with all master tabs simultaneously

---

## 3. Default Data Load

When the page loads via TransportMasterController@index() (GET /transport/master), all master tab data is fetched in a single request and passed to the view:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Routes Grid | `TransportMasterController@routesQuery()` | `Route::query()->latest()` | tab=route: `search`(code,name), `shift_id`, `pickup_drop`, `status` | 10/page via `->paginate(10)->withQueryString()` |
| Route Tab Partial | view: `transport::route.index` | Included inside `transportmaster.blade.php` via `@include('transport::route.index')` | Uses `$routes` variable from controller | As above |
| Shifts for filter | view's filter dropdown | `$shifts` collection (all shifts passed from TransportMasterController — see shiftQuery result) | None | None |

Note: Route's list is embedded within the Transport Master tab container at `/transport/master?tab=route`. However, `Route::resource('route', RouteController::class)` also creates a standalone GET `/route` index route. While the `store()` redirect goes to `transport.transport-master.index`, the standalone index at `/route` still responds. The list loads inside `/transport/master?tab=route` as the primary UX flow.

The `RouteController` methods `create()`, `show()`, `edit()` load their own dedicated full-page views (with breadcrumb and layout). These are loaded at their respective `/route/*` URLs independently of the tab container.

---

## 4. Test Data Strategy

- **Unique suffix**: `now()->format('His') . random_int(100, 999)` via `uniqueSuffix()` method
- **Route code**: String max 50 chars (backend validation); globally unique (`uq_route_code`). View placeholder says "max 20" but backend allows 50 — test at both limits.
- **Route name**: String max 200 chars (backend); globally unique (`uq_route_name`). View placeholder says "max 100" — discrepancy with backend max:200.
- **Route geometry**: DDL type `LINESTRING SRID 4326`. Must be provided as spatial data via `DB::raw("ST_GeomFromText('LINESTRING(77.5 12.9, 77.6 13.0)', 4326)")`. Not exposed in create/edit form — only shown in show and trash views.
- **Shift**: Must reference an existing active `tpt_shift` record via `shift_id`
- **pickup_drop**: ENUM with allowed values `'Pickup'` or `'Drop'`. Default in model is `'pickup'` (lowercase) but request validation expects `'Pickup'` (PascalCase via `Rule::in(['Pickup', 'Drop'])`).
- **is_active**: Defaults to `true` via `protected $attributes = ['is_active' => true]`. Request normalizes checkbox value via `prepareForValidation()` — converts `'on'` → true, absent → false.
- **Pre-test cleanup**: Delete created routes by code before/after tests to avoid unique key collisions
- **Activity log cleanup**: Records cleaned up after force-delete tests
- **Soft delete behavior**: `destroy()` sets `is_active = false` and calls `save()` BEFORE calling `$route->delete()`
- **Restore behavior**: `restore()` calls `$route->restore()` but does NOT restore `is_active` back to true — it remains false
- **toggleStatus**: Accepts `is_active` as boolean from request body. Validates `required|boolean` inline. Returns JSON `{success: true/false, is_active, message}`. Response uses `flash('status_updated.route')` / `flash('status_switch_failed.route')`.
- **Update change tracking**: `getOriginal()` captured before update; `getChanges()` compared after; `updated_at` excluded from log; activity log records `changes` array with old→new per field; if no changes, message says "No attributes changed."
- **Description discrepancy**: View `maxlength="200"` but RouteRequest `max:500` — the stricter limit in the view will truncate before backend validation triggers.

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_route`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | code | VARCHAR(50) | NOT NULL, UNIQUE (`uq_route_code`) |
| BC-DB-03 | name | VARCHAR(200) | NOT NULL, UNIQUE (`uq_route_name`) |
| BC-DB-04 | description | VARCHAR(500) | DEFAULT NULL |
| BC-DB-05 | pickup_drop | ENUM('Pickup','Drop') | NOT NULL, DEFAULT 'Pickup' |
| BC-DB-06 | shift_id | INT UNSIGNED | NOT NULL, FK → `tpt_shift.id`, ON DELETE CASCADE |
| BC-DB-07 | route_geometry | LINESTRING SRID 4326 | NOT NULL, SPATIAL INDEX (`sp_idx_route_geometry`) |
| BC-DB-08 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 (cast to boolean in model) |
| BC-DB-09 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-11 | deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### 5.2 Validation Rules — `RouteRequest`

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:50, `Rule::unique('tpt_route','code')->ignore($routeId)` | Default unique violation message |
| BC-VAL-02 | name | required, string, max:200, `Rule::unique('tpt_route','name')->ignore($routeId)` | Default unique violation message |
| BC-VAL-03 | description | nullable, string, max:500 | — |
| BC-VAL-04 | pickup_drop | required, `Rule::in(['Pickup', 'Drop'])` | — |
| BC-VAL-05 | shift_id | required, `exists:tpt_shift,id` | — |
| BC-VAL-06 | is_active | required, boolean (normalized: checkbox 'on' → true) | — |

Note: `route_geometry` and `route_geometry` are NOT in RouteRequest validation rules, only in the model's `$fillable` array. They can be set programmatically but are not validated by the form request.

### 5.3 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.route.viewAny | Tab: `Gate::any([...tenant.route.viewAny...])` in `TransportMasterController::index()` (line 28-41) + Blade `@can('tenant.route.viewAny')`; Standalone: `Gate::authorize()` in `RouteController::index()` (line 20) | Without → tab hidden (blade @can); hitting standalone `/route` with bad permission → 403 from `RouteController::index()` |
| BC-AUTH-02 | tenant.route.view | show() | Without → 403 |
| BC-AUTH-03 | tenant.route.create | store(), create() | Without → 403; also in RouteRequest::authorize() |
| BC-AUTH-04 | tenant.route.update | update(), edit() | Without → 403; also in RouteRequest::authorize() |
| BC-AUTH-05 | tenant.route.edit | Action column visibility (blade `@canany(['tenant.route.edit', 'tenant.route.delete'])`) | ⚠️ **Policy gap**: `RoutePolicy` has NO `edit()` method, only `update()`. The `@can('tenant.route.edit')` check in Blade falls through — for non-super-admin users, `Gate::allows()` returns `false` because no Policy method handles `tenant.route.edit`. Action column is **always hidden** for normal users even if they have `tenant.route.update` permission. This is a bug: should reference `tenant.route.update` instead of `tenant.route.edit`. |
| BC-AUTH-06 | tenant.route.delete | destroy() | Without → 403 |
| BC-AUTH-07 | tenant.route.restore | restore(), trashed() | Without → 403; also trash view button hidden |
| BC-AUTH-08 | tenant.route.forceDelete | forceDelete() | Without → 403 |
| BC-AUTH-09 | tenant.route.status | `toggleStatus()` controller uses `Gate::authorize('tenant.route.update')`, NOT `tenant.route.status` | `tenant.route.status` is defined in `RoutePolicy::status()` but controller never calls it; Policy's `status()` method is dead code. Controller uses `tenant.route.update` gate instead. Without either permission → 403 from `update` gate |

### 5.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Create via `Route::create($request->validated())` | New route created with validated data; redirect to `transport.transport-master.index` with flash `created.route` |
| BC-BIZ-02 | Activity log on create | `activityLog($route, 'Stored', ['message' => 'A new route was created.', 'other' => 'Some other information'])` |
| BC-BIZ-03 | Update via `$route->update($request->validated())` | Route attributes updated; changes tracked via `getOriginal()` vs `getChanges()` |
| BC-BIZ-04 | Change tracking detail on update | `updated_at` excluded; each changed field logged with old→new values; `$changedAttributes[$field] = ['old' => $original[$field], 'new' => $newValue]` |
| BC-BIZ-05 | Update with zero attribute changes | activityLog uses message: "Route updated. No attributes changed." |
| BC-BIZ-06 | Activity log on update | `activityLog($route, 'Updated', ['message' => 'Route was updated.', 'changes' => $changedAttributes, 'performed_by' => Auth::user()->name])` |
| BC-BIZ-07 | Soft delete via `destroy()` | `$route->is_active = false` → `$route->save()` → `$route->delete()` — is_active set false BEFORE soft delete |
| BC-BIZ-08 | Activity log on soft delete | `activityLog($route, 'Trashed', ['message' => 'Route was deactivated and trashed.', 'performed_by' => Auth::user()->name])` |
| BC-BIZ-09 | Redirect after soft delete | Redirect to `transport.transport-master.index` with flash `trashed.route` |
| BC-BIZ-10 | Trash list via `trashed()` | `Route::onlyTrashed()->with('shift')->paginate(10)` — shows soft-deleted records |
| BC-BIZ-11 | Restore via `restore($id)` | `Route::onlyTrashed()->findOrFail($id)` → `$route->restore()`; redirects to `transport.route.trashed` |
| BC-BIZ-12 | Restore does NOT revert is_active | is_active stays false after restore — must be manually toggled back to active |
| BC-BIZ-13 | Activity log on restore | `activityLog($route, 'Restored', ['message' => 'Route was restored.', 'other' => 'Some other information'])` |
| BC-BIZ-14 | Force delete via `forceDelete($id)` | `Route::withTrashed()->findOrFail($id)` → `$route->forceDelete()` — permanent removal |
| BC-BIZ-15 | Activity log on force delete | `activityLog($route, 'Deleted', ['message' => 'Route was permanently deleted.', 'other' => 'Some other information'])` |
| BC-BIZ-16 | toggleStatus via `toggleStatus(Request, Route $route)` | `$request->validate(['is_active' => 'required|boolean'])` → `$route->is_active = $request->is_active` → `activityLog()` → `$route->save()` — **bug**: activityLog runs BEFORE save, so even if save fails, activity log is written |
| BC-BIZ-17 | toggleStatus success response | JSON `{success: true, is_active: bool, message: flash('status_updated.route')}` |
| BC-BIZ-18 | toggleStatus failure response | JSON `{success: false, message: flash('status_switch_failed.route')}` |
| BC-BIZ-19 | Activity log on toggle | `activityLog($route, 'Toggled', ['message' => 'Route status was updated.', 'other' => 'Some other information'])` |
| BC-BIZ-20 | Gate check in RouteRequest::authorize() | For POST: `Gate::allows('tenant.route.create')`; for PUT/PATCH: `Gate::allows('tenant.route.update')` |
| BC-BIZ-21 | All RouteController methods use `Gate::authorize()` | Gate check at start of every method BEFORE any DB query |
| BC-BIZ-22 | Route query filters in TransportMasterController | Only applied when `$request->tab === 'route'`: search (code, name LIKE), shift_id, pickup_drop exact match, status (is_active) |
| BC-BIZ-23 | `Route::active()` scope | `where('is_active', true)` |
| BC-BIZ-24 | pickup_drop model default | `protected $attributes = ['pickup_drop' => 'pickup']` (lowercase) — different from ENUM values 'Pickup'/'Drop' (PascalCase). If model is saved without validation, lowercase may be stored. |
| BC-BIZ-25 | Route show view displays geometry | `{{ $route->route_geometry ?? '-' }}` — shows raw geometry value |
| BC-BIZ-26 | View discrepancy — code/name max lengths | Frontend placeholders say "max 20" (code) and "max 100" (name) but backend allows 50 and 200. This is a UX gap. |
| BC-BIZ-27 | View discrepancy — description max length | Frontend `maxlength="200"` but backend `max:500`. User cannot enter >200 chars through UI but API can accept up to 500. |

### 5.5 Model Relationships

| BC ID | Relationship | Type | Foreign Key | Notes |
|-------|-------------|------|-------------|-------|
| BC-REL-01 | shift() | BelongsTo Shift | shift_id | Returns the shift this route belongs to |
| BC-REL-02 | pickupPointRoutes() | HasMany PickupPointRoute | route_id | Ordered by ordinal; stop assignments for this route |
| BC-REL-03 | GetpickupPointRoutes() | HasOne PickupPointRoute | route_id | Single pickup point route record (first by ordinal) |
| BC-REL-04 | pickupPoints() | HasMany PickupPoint | route_id | Direct pickup points (relationship defined but may not be standard) |
| BC-REL-05 | driverRouteVehicles() | HasMany DriverRouteVehicleJnt | route_id | Driver-vehicle assignments on this route |
| BC-REL-06 | studentAllocationsAll() | HasMany TptStudentAllocationJnt | pickup_route_id OR drop_route_id | All student allocations referencing this route as pickup or drop |
| BC-REL-07 | trips() | HasMany TptTrip | route_id | Trips created for this route |
| BC-REL-08 | boardingLogs() | HasMany StudentBoardingLog | boarding_route_id | Boarding logs where this is the boarding route |
| BC-REL-09 | unBoardingLogs() | HasMany StudentBoardingLog | unboarding_route_id | Boarding logs where this is the unboarding route |
| BC-REL-10 | tripStopDetails() | HasManyThrough TptTripStopDetail via TptTrip | route_id → TptTrip.id → TptTripStopDetail.trip_id | Trip stop details filtered by `reached_flag = 1` |

### 5.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | shift_id | tpt_shift (id) | CASCADE |
| BC-REF-02 | route_id (in tpt_pickup_points_route_jnt) | tpt_route (id) | CASCADE |
| BC-REF-03 | route_id (in tpt_driver_route_vehicle_jnt) | tpt_route (id) | CASCADE |
| BC-REF-04 | route_id (in tpt_route_scheduler_jnt) | tpt_route (id) | CASCADE |
| BC-REF-05 | route_id (in tpt_trip) | tpt_route (id) | RESTRICT (via scheduler FK chain) |
| BC-REF-06 | pickup_route_id (in tpt_student_route_allocation_jnt) | tpt_route (id) | RESTRICT |
| BC-REF-07 | drop_route_id (in tpt_student_route_allocation_jnt) | tpt_route (id) | RESTRICT |
| BC-REF-08 | boarding_route_id (in tpt_student_boarding_log) | tpt_route (id) | SET NULL |
| BC-REF-09 | unboarding_route_id (in tpt_student_boarding_log) | tpt_route (id) | SET NULL |

### 5.7 Deep Business Conditions — Code-Level Analysis

| BC-BIZ-DEEP ID | Condition | Expected Behavior | Source (Line) |
|----------------|-----------|-------------------|---------------|
| BC-BIZ-DEEP-01 | `TransportMasterController::index() → routesQuery() [Tab-based]()` — Aggregate gate check | `Gate::any([...tenant.route.viewAny...])` at line 28-41 — aggregate gate for ALL transport master tabs | `TransportMasterController.php:28-41` |
| BC-BIZ-DEEP-02 | `TransportMasterController::index() → routesQuery() [Tab-based]()` — Route query | `Route::with('shift')->when(tab='route')->latest()->paginate(10, ['*'], 'routes_page')` — eager loads shift, paginated with unique page name | `TransportMasterController.php:149-158` |
| BC-BIZ-DEEP-03 | `TransportMasterController::index() → routesQuery() [Tab-based]()` — Tab partial rendered | `@include('transport::route.index')` via transportmaster.blade.php — NOT standalone full-page view | `transportmaster.blade.php` + `TransportMasterController.php:149-158` |
| BC-BIZ-DEEP-04 | `RouteController::create()` — Gate check | `Gate::authorize('tenant.route.create')` — authorization gate for creation | `RouteController.php:32` |
| BC-BIZ-DEEP-05 | `RouteController::create()` — Shift load | `Shift::active()->get()` — ONLY active shifts passed to create view in `$shifts` | `RouteController.php:34` |
| BC-BIZ-DEEP-06 | `RouteController::store()` — Gate check | `Gate::authorize('tenant.route.create')` — duplicate gate (same as create()) | `RouteController.php:44` |
| BC-BIZ-DEEP-07 | `RouteController::store()` — Creation | `Route::create($request->validated())` — mass-assigns validated data from RouteRequest | `RouteController.php:46` |
| BC-BIZ-DEEP-08 | `RouteController::store()` — Redirect target | `redirect()->route('transport.transport-master.index')` — always redirects to transport master tab, NOT to route index | `RouteController.php:53-54` |
| BC-BIZ-DEEP-09 | `RouteController::store()` — Flash message | `->with('success', flash('created.route'))` — flash key 'created.route' translated by localization helper `flash()` | `RouteController.php:54` |
| BC-BIZ-DEEP-10 | `RouteController::store()` — Activity log order | Activity log is created AFTER `Route::create()` — log references the newly created `$route` model which now has an `id` | `RouteController.php:48-51` |
| BC-BIZ-DEEP-11 | `RouteController::show()` — Route loading | `Route::with('shift')->findOrFail($id)` — eager loads shift; throws ModelNotFoundException if ID invalid | `RouteController.php:64` |
| BC-BIZ-DEEP-12 | `RouteController::edit()` — Route loading | `Route::findOrFail($id)` — NO `with('shift')` unlike show(); only loads the route itself | `RouteController.php:76` |
| BC-BIZ-DEEP-13 | `RouteController::edit()` — Shift load for dropdown | `Shift::active()->get()` — same active-only scope as create(), populates shift select dropdown | `RouteController.php:77` |
| BC-BIZ-DEEP-14 | `RouteController::update()` — Route model binding | Uses implicit route-model-binding: `Route $route` — Laravel auto-resolves from {route} parameter | `RouteController.php:85` |
| BC-BIZ-DEEP-15 | `RouteController::update()` — Original capture | `$original = $route->getOriginal()` — captures pre-update attribute values BEFORE `update()` call | `RouteController.php:89` |
| BC-BIZ-DEEP-16 | `RouteController::update()` — Change detection | `$changes = $route->getChanges()` returns only dirty attributes post-update; `updated_at` filtered out in loop | `RouteController.php:92-102` |
| BC-BIZ-DEEP-17 | `RouteController::update()` — Change tracking format | Each changed field stored as `['old' => originalValue, 'new' => newValue]` — uses `$original[$field]` for old value | `RouteController.php:98-101` |
| BC-BIZ-DEEP-18 | `RouteController::update()` — No-changes activity log | When `getChanges()` returns only `['updated_at' => ...]` → `$changedAttributes` empty → logs "Route updated. No attributes changed." | `RouteController.php:110-114` |
| BC-BIZ-DEEP-19 | `RouteController::update()` — Changes activity log | When changes exist, logs with `'changes' => $changedAttributes` and `'performed_by' => Auth::user()->name` | `RouteController.php:105-109` |
| BC-BIZ-DEEP-20 | `RouteController::update()` — Redirect target | Same as store: redirects to `transport.transport-master.index` with flash `updated.route` | `RouteController.php:117-118` |
| BC-BIZ-DEEP-21 | `RouteController::destroy()` — Manual two-step deactivation | Line 128: `$route->is_active = false` → Line 129: `$route->save()` → Line 130: `$route->delete()` — explicit save BEFORE soft delete | `RouteController.php:128-130` |
| BC-BIZ-DEEP-22 | `RouteController::destroy()` — Activity log event | Logged as `'Trashed'` event with message "Route was deactivated and trashed." — not 'Deleted' | `RouteController.php:132-135` |
| BC-BIZ-DEEP-23 | `RouteController::destroy()` — Redirect | Redirects to `transport.transport-master.index` with flash `trashed.route` — NOT to a dedicated page | `RouteController.php:137-138` |
| BC-BIZ-DEEP-24 | `RouteController::trashed()` — Gate permission | Uses `Gate::authorize('tenant.route.restore')` — NOT `tenant.route.viewAny` or delete | `RouteController.php:146` |
| BC-BIZ-DEEP-25 | `RouteController::trashed()` — onlyTrashed vs withTrashed | Uses `Route::onlyTrashed()->with('shift')->paginate(10)` — only soft-deleted records shown | `RouteController.php:148` |
| BC-BIZ-DEEP-26 | `RouteController::trashed()` — Eager load | `->with('shift')` — same as index(), loads shift relationship for each trashed route | `RouteController.php:148` |
| BC-BIZ-DEEP-27 | `RouteController::restore()` — onlyTrashed query | `Route::onlyTrashed()->findOrFail($id)` — can ONLY find soft-deleted records; active records get 404 | `RouteController.php:160` |
| BC-BIZ-DEEP-28 | `RouteController::restore()` — is_active NOT restored | `$route->restore()` only sets `deleted_at = NULL`; `is_active` remains `false` (was set false in destroy()) | `RouteController.php:161` |
| BC-BIZ-DEEP-29 | `RouteController::restore()` — Redirect | Redirects to `transport.route.trashed` (the trash list view), NOT to transport master | `RouteController.php:168-169` |
| BC-BIZ-DEEP-30 | `RouteController::forceDelete()` — withTrashed query | `Route::withTrashed()->findOrFail($id)` — can find BOTH active and soft-deleted records | `RouteController.php:179` |
| BC-BIZ-DEEP-31 | `RouteController::forceDelete()` — Permanent deletion | `$route->forceDelete()` — removes row from DB entirely; PK cannot be reused cleanly | `RouteController.php:180` |
| BC-BIZ-DEEP-32 | `RouteController::forceDelete()` — Redirect | Redirects to `transport.route.trashed` with flash `force_deleted.route` | `RouteController.php:187-188` |
| BC-BIZ-DEEP-33 | `RouteController::toggleStatus()` — Gate mismatch | Uses `Gate::authorize('tenant.route.update')` but `RoutePolicy` defines a separate `status()` method for `tenant.route.status` | `RouteController.php:196`; `RoutePolicy.php:29-32` |
| BC-BIZ-DEEP-34 | `RouteController::toggleStatus()` — Inline validation | `$request->validate(['is_active' => 'required|boolean'])` — NOT using RouteRequest form request | `RouteController.php:198-200` |
| BC-BIZ-DEEP-35 | `RouteController::toggleStatus()` — Activity BEFORE save | Line 204-207: `activityLog($route, 'Toggled', [...])` is called BEFORE `$route->save()` at line 209. If save() fails (DB error), activity log is still written. | `RouteController.php:204-207,209` |
| BC-BIZ-DEEP-36 | `RouteController::toggleStatus()` — Success JSON response | Returns `{success: true, is_active: (bool), message: flash('status_updated.route')}` | `RouteController.php:210-215` |
| BC-BIZ-DEEP-37 | `RouteController::toggleStatus()` — Failure JSON response | Returns `{success: false, message: flash('status_switch_failed.route')}` — HTTP 200 not 500 | `RouteController.php:217-221` |
| BC-BIZ-DEEP-38 | `RouteController::toggleStatus()` — Route model binding | Uses implicit binding: `Route $route` — auto-resolves, throws ModelNotFoundException on invalid ID | `RouteController.php:194` |
| BC-BIZ-DEEP-39 | `RouteRequest::authorize()` — Method-based branching | POST returns `Gate::allows('tenant.route.create')`; all other methods (PUT/PATCH) return `Gate::allows('tenant.route.update')` | `RouteRequest.php:13-16` |
| BC-BIZ-DEEP-40 | `RouteRequest::rules()` — $routeId resolution | `$this->route('route')?->id` — uses null-safe operator; returns null on create (no route param) → ignore adds no condition | `RouteRequest.php:22` |
| BC-BIZ-DEEP-41 | `RouteRequest::rules()` — Unique ignore on update | Both `code` and `name` unique rules use `->ignore($routeId)` — on update, excludes current record from uniqueness check | `RouteRequest.php:29,36` |
| BC-BIZ-DEEP-42 | `RouteRequest::prepareForValidation()` — Checkbox logic | `$this->has('is_active') && $this->input('is_active') === 'on'` — only the string "on" triggers true; anything else (absent, "0", "off", "true") → false | `RouteRequest.php:65-66` |
| BC-BIZ-DEEP-43 | `RouteRequest::prepareForValidation()` — Merge timing | `$this->merge([...])` runs BEFORE rules() — rules see normalized boolean `is_active` | `RouteRequest.php:65-67` |
| BC-BIZ-DEEP-44 | `RoutePolicy` — Method list coverage | Policy defines: viewAny, view, status, create, update, delete, restore, forceDelete, import, export, print (11 methods). NO `edit()` method. | `RoutePolicy.php:13-96` |
| BC-BIZ-DEEP-45 | `RoutePolicy` — Dead `status()` method | `status()` at line 29-32 checks `tenant.route.status` but is NEVER called by any controller method | `RoutePolicy.php:29-32` |
| BC-BIZ-DEEP-46 | `Route` Model — SoftDeletes trait | `use HasFactory, SoftDeletes;` at line 14 — enables `delete()`, `restore()`, `forceDelete()`, `trashed()` scopes | `Route.php:14` |
| BC-BIZ-DEEP-47 | `Route` Model — Fillable vs Guarded | Uses `$fillable` with 7 fields — code, name, description, pickup_drop, shift_id, is_active, route_geometry. All mass-assignable. | `Route.php:19-27` |
| BC-BIZ-DEEP-48 | `Route` Model — $attributes defaults | `is_active => true` (boolean true), `pickup_drop => 'pickup'` (lowercase). Note: lowercase 'pickup' does NOT match ENUM 'Pickup' — model default bypasses validation | `Route.php:41-44` |
| BC-BIZ-DEEP-49 | `Route` Model — $casts detail | `is_active => 'boolean'`, timestamps `=> 'datetime'`. route_geometry, pickup_drop, shift_id have NO casts | `Route.php:30-35` |
| BC-BIZ-DEEP-50 | `Route` Model — active() scope | `scopeActive($query) { return $query->where('is_active', true); }` — used by Shift::active() in create/edit views | `Route.php:47-50` |
| BC-BIZ-DEEP-51 | `TransportMasterController::index()` — Aggregate gate | `Gate::any([...'tenant.route.viewAny'...]) || abort(403)` — checks if user has ANY transport tab permission, not specifically route | `TransportMasterController.php:28-41` |
| BC-BIZ-DEEP-52 | `TransportMasterController::routesQuery()` — Tab guard | All route-specific filters are wrapped in `if ($request->tab === 'route')` — filters only apply when Route tab is active | `TransportMasterController.php:153-178` |
| BC-BIZ-DEEP-53 | `TransportMasterController::routesQuery()` — Search scope | Search filters on `code` LIKE and `name` LIKE (OR combined) — searches both fields simultaneously | `TransportMasterController.php:156-161` |
| BC-BIZ-DEEP-54 | `TransportMasterController::routesQuery()` — Status filter | Uses `isset($request->status)` (not `filled()`) — `filled()` treats 0 as empty, `isset()` catches 0 correctly for status=inactive | `TransportMasterController.php:175-177` |
| BC-BIZ-DEEP-55 | `TransportMasterController::routesQuery()` — Shift filter | `isset($request->shift_id)` — same pattern; works with 0 (though shift_id is FK > 0) | `TransportMasterController.php:165-167` |
| BC-BIZ-DEEP-56 | `transportmaster.blade.php` — Route tab definition | Tab id='route', label='Route', icon='fa-solid fa-route', permission='tenant.route.viewAny' | `transportmaster.blade.php:11` |
| BC-BIZ-DEEP-57 | `transportmaster.blade.php` — Conditional tab rendering | `@can('tenant.route.viewAny')` wraps the tab pane — tab hidden for users without viewAny | `transportmaster.blade.php:39` |
| BC-BIZ-DEEP-58 | `route/index.blade.php` — Search bar component | `<x-backend.tab.search-bar url="transport.route" permissions="tenant.route">` — Add and Trash buttons are rendered by this component along with search/filter | `route/index.blade.php:5` |
| BC-BIZ-DEEP-59 | `route/index.blade.php` — Action column conditional | Header and body both wrapped in `@canany(['tenant.route.edit', 'tenant.route.delete'])` — but `tenant.route.edit` has no Policy method | `route/index.blade.php:69,90` |
| BC-BIZ-DEEP-60 | `route/index.blade.php` — Status column NOT permission-gated | Status column `<th>` and `<x-backend.table.status-switch>` have NO `@can` wrapper — visible to all users with viewAny | `route/index.blade.php` ~lines 65,80 |
| BC-BIZ-DEEP-61 | `route/show.blade.php` — Edit button gated | `@can('tenant.route.edit')` wraps the Edit button — again suffers from missing Policy method | `route/show.blade.php:15` |
| BC-BIZ-DEEP-62 | `route/trash.blade.php` — Correct permissions | `@canany(['tenant.route.restore', 'tenant.route.forceDelete'])` — both exist in Policy, works correctly | `route/trash.blade.php:22` |
| BC-BIZ-DEEP-63 | `Route` model — STOP_TYPES constant | `public const STOP_TYPES = ['Pickup', 'Drop']` — matches ENUM values but not used in RouteRequest validation | `Route.php:38` |
| BC-BIZ-DEEP-64 | `activityLog()` helper — Function signature | `activityLog($model, $event, $properties)` — globally available helper (not part of controller) | Used in 6 controller methods |
| BC-BIZ-DEEP-65 | `flash()` helper — Localization pattern | `flash('created.route')` resolves via translation files to "Route created successfully" — pattern: `{pastTense}.{entity}` | Used on all redirects |

### 5.8 Model Attributes and Casts Deep-Dive

| Attribute | Model Default | Cast | Fillable | DDL Type | Notes |
|-----------|---------------|------|----------|----------|-------|
| code | none | none | yes | VARCHAR(50) UNIQUE | Required in RouteRequest |
| name | none | none | yes | VARCHAR(200) UNIQUE | Required in RouteRequest |
| description | none | none | yes | VARCHAR(500) NULLABLE | Optional in RouteRequest |
| pickup_drop | 'pickup' (lowercase) | none | yes | ENUM('Pickup','Drop') | Default does NOT match ENUM values |
| shift_id | none | none | yes | INT UNSIGNED FK | Required in RouteRequest |
| is_active | true (boolean) | boolean | yes | TINYINT(1) | Required in RouteRequest |
| route_geometry | none | none | yes | LINESTRING SRID 4326 | NOT in RouteRequest validation |
| id | auto | none | no | INT UNSIGNED PK | Auto-increment |
| created_at | CURRENT_TIMESTAMP | datetime | no | TIMESTAMP | Set by Eloquent |
| updated_at | CURRENT_TIMESTAMP ON UPDATE | datetime | no | TIMESTAMP | Set by Eloquent |
| deleted_at | NULL | datetime | no | TIMESTAMP NULLABLE | Set by SoftDeletes |

---

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Route Tab Loads Inside Transport Master | `/transport/master?tab=route` loads the Route tab with filter bar, table (Code, Name, Description, Pickup/Drop, Shift, Status, Action), Add and Trash buttons | — | — | ⬜ |
| TC-P02 | Create Route With All Required Fields | POST to `/route` with code, name, pickup_drop, shift_id, is_active=on → route created, redirect to master tab, flash success | — | — | ⬜ |
| TC-P03 | Create Route With Description | Description field saved correctly in DB | — | — | ⬜ |
| TC-P04 | View Route Details | `/route/{id}` shows Route Code, Name, Geometry, Pickup Drop, Description, Shift, Status, Created At, Updated At | — | — | ⬜ |
| TC-P05 | Edit Route Loads Pre-Filled Data | `/route/{id}/edit` shows existing values in all form fields | — | — | ⬜ |
| TC-P06 | Update Route — Change Name and Code | PUT to `/route/{id}` updates name and code; activity log records old→new values | — | — | ⬜ |
| TC-P07 | Update Route — Change Shift Assignment | shift_id updated; redirect with success flash | — | — | ⬜ |
| TC-P08 | Update Route — Toggle pickup_drop | pickup_drop changed; activity log tracks change | — | — | ⬜ |
| TC-P09 | Update Route — No Changes Submitted | PUT with same values → activity log "No attributes changed" | — | — | ⬜ |
| TC-P10 | Soft Delete Route | DELETE `/route/{id}` → is_active=false, deleted_at set; route hidden from main list | — | — | ⬜ |
| TC-P11 | Trash Page Shows Deleted Routes | GET `/route/trash/view` → list of soft-deleted routes with Restore and Force Delete buttons | — | — | ⬜ |
| TC-P12 | Restore Route From Trash | GET `/route/{id}/restore` → deleted_at=NULL; route visible on main list; is_active still false | — | — | ⬜ |
| TC-P13 | Force Delete Route (No Dependencies) | DELETE `/route/{id}/force-delete` → record permanently removed; activity log "Deleted" | — | — | ⬜ |
| TC-P14 | Toggle Status Active → Inactive | POST `/route/{route}/toggle-status` with `is_active=0` → JSON `{success:true, is_active:false}`; activity log "Toggled" recorded; table shows Inactive badge | — | — | ⬜ |
| TC-P15 | Toggle Status Inactive → Active | POST with `is_active=1` → JSON `{success:true, is_active:true}`; activity log "Toggled" recorded; table shows Active badge | — | — | ⬜ |
| TC-P16 | Full Lifecycle | Create → View → Edit → Toggle → Delete → Trash → Restore → Toggle Active → Force Delete; all steps succeed | — | — | ⬜ |
| TC-P17 | Filter Routes By Search (Code) | Enter route code in search box → table shows only matching route | — | — | ⬜ |
| TC-P18 | Filter Routes By Search (Name) | Enter route name fragment → table shows matching routes | — | — | ⬜ |
| TC-P19 | Filter Routes By Shift | Select shift from dropdown → table filters to routes of that shift | — | — | ⬜ |
| TC-P20 | Filter Routes By Pickup/Drop Type | Select "Pickup" → only Pickup routes shown; select "Drop" → only Drop routes shown | — | — | ⬜ |
| TC-P21 | Filter Routes By Status | Select "Active" → only is_active=1 routes; "Inactive" → only is_active=0 routes | — | — | ⬜ |
| TC-P22 | Empty State — No Routes | Table shows "No Data Found" message across all 7 columns | — | — | ⬜ |
| TC-P23 | Empty State — No Trashed Routes | Trash table shows "No Data Found" | — | — | ⬜ |
| TC-P24 | Pagination — Routes Exceed First Page | When 11+ routes exist, pagination links appear; navigating to page 2 shows next set | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Required — Missing Code | Validation error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Required — Missing Name | Validation error: "The name field is required." | — | — | ⬜ |
| TC-N03 | Required — Missing pickup_drop | Validation error: "The pickup drop field is required." | — | — | ⬜ |
| TC-N04 | Required — Missing shift_id | Validation error: "The shift id field is required." | — | — | ⬜ |
| TC-N05 | Duplicate Code (Global Unique) | "The code has already been taken." — integrity violation at DB or validation | — | — | ⬜ |
| TC-N06 | Duplicate Name (Global Unique) | "The name has already been taken." | — | — | ⬜ |
| TC-N07 | Max Length — Code > 50 Characters | Backend validation: `code.max` error; frontend allows up to 50 (placeholder says 20 misleadingly) | — | — | ⬜ |
| TC-N08 | Max Length — Name > 200 Characters | Backend validation: `name.max` error; frontend allows up to 200 (placeholder says 100 misleadingly) | — | — | ⬜ |
| TC-N09 | Max Length — Description > 500 Characters | Backend validation: `description.max` error | — | — | ⬜ |
| TC-N10 | Invalid pickup_drop — Not 'Pickup' or 'Drop' | "The selected pickup drop is invalid." | — | — | ⬜ |
| TC-N11 | Invalid shift_id — Non-Existent Shift | "The selected shift id is invalid." | — | — | ⬜ |
| TC-N12 | View Route With Invalid ID | GET `/route/99999` → 404 | — | — | ⬜ |
| TC-N13 | Edit Route With Invalid ID | GET `/route/99999/edit` → 404 | — | — | ⬜ |
| TC-N14 | Update Route With Invalid ID | PUT `/route/99999` → 404 | — | — | ⬜ |
| TC-N15 | Delete Route With Invalid ID | DELETE `/route/99999` → 404 | — | — | ⬜ |
| TC-N16 | Toggle Status With Invalid ID | POST `/route/99999/toggle-status` → ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N17 | Restore Non-Deleted Route (Active) | GET `/route/{id}/restore` where route is not trashed → `onlyTrashed()->find()` returns null → 404 | — | — | ⬜ |
| TC-N18 | Force Delete Non-Trashed Route | DELETE `/route/{id}/force-delete` where route is not trashed → `withTrashed()->findOrFail` finds it → but forceDelete works on any record (including non-trashed). Should verify: withTrashed finds all records including active ones. |
| TC-N19 | Force Delete Route That Has Active Student Allocations (RESTRICT) | DDL FK RESTRICT on pickup_route_id/drop_route_id → DB integrity violation, deletion blocked | — | — | ⬜ |
| TC-N20 | Toggle Status With Non-Boolean is_active | POST with `is_active=invalid` → validation error: "The is active field must be true or false." | — | — | ⬜ |
| TC-N21 | Permission 403 — No Route Permissions | 403 Forbidden on all CRUD endpoints for user without `tenant.route.*` permissions | — | — | ⬜ |
| TC-N22 | Guest Access Redirect | All `/route/*` URLs redirect to `/login` for unauthenticated users | — | — | ⬜ |
| TC-N23 | XSS Injection In Name or Code | `<script>alert('xss')</script>` stored as literal string; Blade `{{ }}` escapes output — no script execution | — | — | ⬜ |
| TC-N24 | Whitespace-Only Name or Code | Required validation catches whitespace-only strings (Laravel `required` rule treats whitespace as filled — actually this PASSES validation, which is a potential gap) | — | — | ⬜ |
| TC-N25 | is_active Checkbox Not Checked | `prepareForValidation()` sets `is_active = false` when checkbox absent → route created as inactive | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Soft-Delete Route — PickupPointRoute Cascade Deleted | DDL CASCADE → child pickup_point_route records soft-deleted | — | — | ⬜ |
| TC-D02 | A | Soft-Delete Route — DriverRouteVehicleJnt Cascade Deleted | DDL CASCADE → driver_route_vehicle_jnt records cascade deleted | — | — | ⬜ |
| TC-D03 | B | Delete Route Blocked by Student Allocation (RESTRICT) | FK RESTRICT on tpt_student_route_allocation_jnt.pickup_route_id → deletion blocked | — | — | ⬜ |
| TC-D04 | B | Delete Route Blocked by Drop Allocation (RESTRICT) | FK RESTRICT on tpt_student_route_allocation_jnt.drop_route_id → deletion blocked | — | — | ⬜ |
| TC-D05 | C | Shift Deletion Cascades To Routes (CASCADE) | Deleting a shift in tpt_shift auto-deletes all routes with that shift_id | — | — | ⬜ |
| TC-D06 | D | Route Deletion — BoardingLog SET NULL | DDL SET NULL → boarding_log records remain, boarding_route_id becomes NULL | — | — | ⬜ |
| TC-D07 | D | Route Deletion — UnboardingLog SET NULL | DDL SET NULL → unboarding_log records remain, unboarding_route_id becomes NULL | — | — | ⬜ |
| TC-D08 | E | Restore Does Not Cascade to PickupPointRoute | After soft-delete + restore, pickupPointRoute records are not restored (they were cascade-deleted) | — | — | ⬜ |
| TC-D09 | F | Rapid Status Toggle | Rapid clicking toggle button → no data corruption or duplicate requests | — | — | ⬜ |
| TC-D10 | G | Concurrent Update — Two Users Edit Same Route | Last save wins; no data corruption; change tracking shows only last user's changes | — | — | ⬜ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — All Action Buttons Protected | index: `@canany(['tenant.route.edit', 'tenant.route.delete'])` for action column; show: `@can('tenant.route.edit')` for Edit button; trash: `@canany(['tenant.route.restore', 'tenant.route.forceDelete'])` | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Gate::authorize() Before Every State Change | Each method has Gate::authorize() as FIRST executable line (before any query) | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog Created After Every CRUD | Stored, Updated, Trashed, Restored, Deleted, Toggled — all events logged | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — Change Tracking on Update | getOriginal() captured before; getChanges() compared after; updated_at excluded; old→new values logged | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — is_active=false Before Soft Delete | destroy() sets is_active=false AND calls save() BEFORE delete() | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — withTrashed() for forceDelete | forceDelete uses `Route::withTrashed()->findOrFail()` (not onlyTrashed) — so it can delete either trashed or non-trashed records | — | — | ◌ |
| TC-CR07 | CR | P1 | Controller — onlyTrashed() for Restore | restore uses `Route::onlyTrashed()->findOrFail()` — only trashed records can be restored | — | — | ◌ |
| TC-CR08 | CR | P1 | Controller — Non-RESTful Action Methods | `toggleStatus()` is additional non-resource method — not part of Route::resource | — | — | ◌ |
| TC-CR09 | CR | P1 | Request — authorize() matches controller gate | RouteRequest::authorize() checks create for POST, update for PUT/PATCH — same as controller | — | — | ◌ |
| TC-CR10 | CR | P1 | Request — Validation Rules Match DDL Constraints | code max:50 matches VARCHAR(50); name max:200 matches VARCHAR(200); description max:500 matches VARCHAR(500); pickup_drop Rule::in(['Pickup','Drop']) matches ENUM; shift_id exists:tpt_shift,id matches FK | — | — | ◌ |
| TC-CR11 | CR | P1 | Request — prepareForValidation Checkbox Handling | `$this->has('is_active') && $this->input('is_active') === 'on'` converts to boolean | — | — | ◌ |
| TC-CR12 | CR | P1 | Request — Unique Rule Ignore on Update | Both code and name uniques use `->ignore($routeId)` via `$this->route('route')?->id` | — | — | ◌ |
| TC-CR13 | CR | P1 | Model — Table Name and SoftDeletes | `protected $table = 'tpt_route'` and `use SoftDeletes` trait present | — | — | ◌ |
| TC-CR14 | CR | P1 | Model — Fillable Matches DB Columns | $fillable: code, name, description, pickup_drop, shift_id, is_active, route_geometry — 7 fields all present | — | — | ◌ |
| TC-CR15 | CR | P1 | Model — Casts for is_active and Dates | `is_active => 'boolean'`, `created_at/updated_at/deleted_at => 'datetime'` | — | — | ◌ |
| TC-CR16 | CR | P1 | Model — Default Attributes | `is_active => true`, `pickup_drop => 'pickup'` (note: lowercase, not matching ENUM PascalCase) | — | — | ◌ |
| TC-CR17 | CR | P1 | Model — Relationships Defined | All 10 relationships present: shift, pickupPointRoutes, GetpickupPointRoutes, pickupPoints, driverRouteVehicles, studentAllocationsAll, trips, boardingLogs, unBoardingLogs, tripStopDetails | — | — | ◌ |
| TC-CR18 | CR | P1 | Routes — Resource + Additional Routes | web.php: `Route::resource('route', RouteController::class)` + 4 additional routes (trashed, restore, forceDelete, toggleStatus) | — | — | ◌ |
| TC-CR19 | CR | P1 | Routes — Route Names Consistently Prefixed | All route names use `transport.route.*` pattern (transport.route.index, transport.route.store, transport.route.trashed, etc.) | — | — | ◌ |
| TC-CR20 | CR | P1 | View — Table Columns Match Requirements | Columns in index: Code, Name, Description, Pickup/Drop, Shift, Status, Action (7 columns) | — | — | ◌ |
| TC-CR21 | CR | P1 | View — Filter Controls Present | Search input (code, name), Shift dropdown, Pickup/Drop dropdown, Status dropdown, Search + Reset buttons | — | — | ◌ |
| TC-CR22 | CR | P1 | View — Show Page Displays All Fields | Route Code (badge), Route Name (strong), Route Geometry, Pickup Drop, Description, Shift (badge+code), Status (badge), Created At, Updated At — 9 rows | — | — | ◌ |
| TC-CR23 | CR | P1 | View — Flash Messages After Every CRUD | Controller uses `flash('created.route')`, `flash('updated.route')`, `flash('trashed.route')`, `flash('restored.route')`, `flash('force_deleted.route')` | — | — | ◌ |
| TC-CR24 | CR | P1 | View — isset()/optional() for Null Relationships | `$route->shift?->name ?? 'N/A'` uses null-safe operator; `$route->description ?? '-'` uses null coalescing | — | — | ◌ |
| TC-CR25 | CR | P1 | DDL — Spatial Index Present | `sp_idx_route_geometry` SPATIAL INDEX on route_geometry column | — | — | ◌ |
| TC-CR26 | CR | P1 | DDL — Unique Constraints Present | `uq_route_code` on code, `uq_route_name` on name | — | — | ◌ |
| TC-CR27 | CR | P1 | Frontend-Backend Discrepancy — Code Max Length | View placeholder says "max 20" but backend allows max:50. Test both: 20-char code works, 30-char code works in backend but may exceed frontend expectation. | — | — | ◌ |
| TC-CR28 | CR | P1 | Frontend-Backend Discrepancy — Name Max Length | View placeholder says "max 100" but backend allows max:200. Similar gap. | — | — | ◌ |
| TC-CR29 | CR | P1 | Frontend-Backend Discrepancy — Description Max Length | View `maxlength="200"` but backend `max:500`. Users constrained to 200 in UI. | — | — | ◌ |
| TC-CR30 | CR | P1 | TransportMasterController — Route Query Filtering | `routesQuery()` uses `$request->tab === 'route'` guard; search, shift_id, pickup_drop, status filters applied only on route tab | — | — | ◌ |

### 6.5 Code Trace — Controller Method Analysis

> ⚠️ **Note**: CODE-TRACE-01 traces the **standalone route** `/route` → `RouteController::index()`. The **primary tab listing** at `/transport/master?tab=route` goes through `TransportMasterController::index()` → `routesQuery()` (see CODE-TRACE-A below).

Each entry below traces the exact execution flow of a RouteController method, with line numbers from the actual source file.

#### CODE-TRACE-01: `index()` — List Routes (Standalone Route)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.viewAny')` | 20 | Authorization check; if denied → 403 thrown, method exits immediately |
| 2 | `Route::with('shift')->paginate(10)` | 22 | Query: SELECT * FROM tpt_route WHERE deleted_at IS NULL ORDER BY ... LIMIT 10 OFFSET 0; Eager loads shift relationship |
| 3 | `return view('transport::route.index', compact('routes'))` | 24 | Renders route/index.blade.php with $routes paginator (10 per page, withQueryString) |
| **Code Flow** | index() is a READ operation returning paginated route list with shift relationship eager-loaded |

#### CODE-TRACE-A: `routesQuery(Request $request)` — TransportMasterController Lines 149-158 (Tab Listing)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::any([...tenant.route.viewAny...])` | 28-41 | Aggregate gate — user must have ANY transport master tab permission |
| 2 | `$query = Route::with('shift')` | 149 | Eager load shift relationship |
| 3 | `if ($request->input('tab') === 'route')` | 151 | Only apply filters when Route tab is active |
| 4 | `->when(search/status)` | 152-155 | Search on route name/other + status filter |
| 5 | `->latest()` | 156 | Order by created_at DESC |
| 6 | `->paginate(10, ['*'], 'routes_page')` | index() | Paginate with unique page name `routes_page` |
| 7 | `->withQueryString()` | index() | Preserve query params |
| 8 | `@include('transport::route.index')` | tab.blade.php | Tab partial rendered inside transportmaster tab |

#### CODE-TRACE-02: `create()` — Show Create Form

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.create')` | 32 | Authorization check for create permission |
| 2 | `Shift::active()->get()` | 34 | Query: SELECT * FROM tpt_shift WHERE is_active = 1 — only active shifts for dropdown |
| 3 | `return view('transport::route.create', compact('shifts'))` | 36 | Renders route/create.blade.php with $shifts collection |
| **Code Flow** | create() is a READ operation that loads active shifts for the form dropdown, then returns the create view |

#### CODE-TRACE-03: `store()` — Create Route (POST)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.create')` | 44 | Authorization check for create permission |
| 2 | `$request->validated()` | 46 | RouteRequest validation runs: required fields, unique code/name, max lengths, ENUM in, shift exists |
| 3 | `Route::create($request->validated())` | 46 | INSERT INTO tpt_route (code, name, description, pickup_drop, shift_id, is_active) VALUES (...); Returns model with id |
| 4 | `activityLog($route, 'Stored', [...])` | 48-51 | Logs: event='Stored', message='A new route was created.', other='Some other information' |
| 5 | `redirect()->route('transport.transport-master.index')` | 53 | Redirects to /transport/master (master tab) |
| 6 | `->with('success', flash('created.route'))` | 54 | Flash message: "Route created successfully" |
| **Code Flow** | store() is a CREATE operation: authorize → validate → insert DB → log activity → redirect to master tab |

#### CODE-TRACE-04: `show($id)` — View Single Route

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.view')` | 62 | Authorization check for view permission |
| 2 | `Route::with('shift')->findOrFail($id)` | 64 | Query: SELECT * FROM tpt_route WHERE id = $id AND deleted_at IS NULL; throws ModelNotFoundException if not found |
| 3 | `return view('transport::route.show', compact('route'))` | 66 | Renders route/show.blade.php with $route (includes shift relationship) |
| **Code Flow** | show() is a READ operation: check permission → find by ID with shift → render show view |

#### CODE-TRACE-05: `edit($id)` — Show Edit Form

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.update')` | 74 | Authorization check for update permission |
| 2 | `Route::findOrFail($id)` | 76 | Query: SELECT * FROM tpt_route WHERE id = $id AND deleted_at IS NULL; throws ModelNotFoundException if not found. NOTE: does NOT eager-load shift |
| 3 | `Shift::active()->get()` | 77 | Query: SELECT * FROM tpt_shift WHERE is_active = 1 — same as create() |
| 4 | `return view('transport::route.edit', compact('route', 'shifts'))` | 79 | Renders route/edit.blade.php with $route model + $shifts collection for dropdown |
| **Code Flow** | edit() is a READ operation: check permission → find route → load active shifts → render edit form pre-filled |

#### CODE-TRACE-06: `update(RouteRequest $request, Route $route)` — Update Route (PUT)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.update')` | 87 | Authorization check for update permission. Uses implicit route-model-binding so $route is resolved BEFORE gate check |
| 2 | `$original = $route->getOriginal()` | 89 | Captures pre-update DB values (array keyed by column names) |
| 3 | `$route->update($request->validated())` | 90 | UPDATE tpt_route SET ... WHERE id = $id; uses validated data from RouteRequest (unique rules ignore current route ID) |
| 4 | `$changes = $route->getChanges()` | 92 | Gets only changed attributes (dirty after sync). Format: ['column' => 'new_value'] |
| 5 | Loops: `foreach ($changes as $field => $newValue)` | 95 | Iterates changed fields, skips 'updated_at', builds $changedAttributes with old→new pairs |
| 6 | `if (!empty($changedAttributes))` | 104 | Branches: changes exist → log with changes array; no changes → log "No attributes changed." |
| 7 | `activityLog($route, 'Updated', [...])` | 105-115 | Logs event='Updated' with changes or no-changes message. Includes performed_by = Auth::user()->name when changes exist |
| 8 | `redirect()->route('transport.transport-master.index')` | 117 | Redirects to /transport/master |
| 9 | `->with('success', flash('updated.route'))` | 118 | Flash message: "Route updated successfully" |
| **Code Flow** | update() is an UPDATE operation: authorize → capture original → apply changes → detect+log changes → redirect to master tab |

#### CODE-TRACE-07: `destroy(Route $route)` — Soft Delete (DELETE)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.delete')` | 126 | Authorization check for delete permission. Uses implicit route-model-binding |
| 2 | `$route->is_active = false` | 128 | Sets is_active to false (not yet saved to DB — in-memory only) |
| 3 | `$route->save()` | 129 | UPDATE tpt_route SET is_active = 0, updated_at = NOW() WHERE id = $id |
| 4 | `$route->delete()` | 130 | UPDATE tpt_route SET deleted_at = NOW() WHERE id = $id (SoftDeletes behavior) |
| 5 | `activityLog($route, 'Trashed', [...])` | 132-135 | Logs: event='Trashed', message='Route was deactivated and trashed.', performed_by=Auth::user()->name |
| 6 | `redirect()->route('transport.transport-master.index')` | 137 | Redirects to /transport/master |
| 7 | `->with('success', flash('trashed.route'))` | 138 | Flash message: "Route trashed successfully" |
| **Code Flow** | destroy() is a SOFT DELETE operation: authorize → deactivate (is_active=false) → save → soft delete → log → redirect. Two DB writes (save + delete). |

#### CODE-TRACE-08: `trashed()` — Show Trash List

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.restore')` | 146 | Authorization check for restore permission (NOT viewAny or delete) |
| 2 | `Route::onlyTrashed()->with('shift')->paginate(10)` | 148 | Query: SELECT * FROM tpt_route WHERE deleted_at IS NOT NULL LIMIT 10 OFFSET 0; Eager loads shift |
| 3 | `return view('transport::route.trash', compact('routes'))` | 150 | Renders route/trash.blade.php with paginated $routes of only soft-deleted records |
| **Code Flow** | trashed() is a READ operation: authorize (restore gate) → query onlyTrashed with shift → render trash view |

#### CODE-TRACE-09: `restore($id)` — Restore Soft-Deleted Route (GET)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.restore')` | 158 | Authorization check for restore permission |
| 2 | `Route::onlyTrashed()->findOrFail($id)` | 160 | Query: SELECT * FROM tpt_route WHERE id = $id AND deleted_at IS NOT NULL; throws ModelNotFoundException if active or non-existent |
| 3 | `$route->restore()` | 161 | UPDATE tpt_route SET deleted_at = NULL, updated_at = NOW() WHERE id = $id. NOTE: is_active remains false |
| 4 | `activityLog($route, 'Restored', [...])` | 163-166 | Logs: event='Restored', message='Route was restored.', other='Some other information' |
| 5 | `redirect()->route('transport.route.trashed')` | 168 | Redirects BACK to trash list (NOT to master tab) |
| 6 | `->with('success', flash('restored.route'))` | 169 | Flash message: "Route restored successfully" |
| **Code Flow** | restore() is a RESTORE operation: authorize → find onlyTrashed → restore (set deleted_at=NULL) → log → redirect to trash. is_active NOT reverted. |

#### CODE-TRACE-10: `forceDelete($id)` — Permanent Delete (DELETE)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.forceDelete')` | 177 | Authorization check for forceDelete permission |
| 2 | `Route::withTrashed()->findOrFail($id)` | 179 | Query: SELECT * FROM tpt_route WHERE id = $id (ignores deleted_at) — finds both active and trashed records |
| 3 | `$route->forceDelete()` | 180 | DELETE FROM tpt_route WHERE id = $id — permanently removes row |
| 4 | `activityLog($route, 'Deleted', [...])` | 182-185 | Logs: event='Deleted', message='Route was permanently deleted.', other='Some other information' |
| 5 | `redirect()->route('transport.route.trashed')` | 187 | Redirects back to trash list |
| 6 | `->with('success', flash('force_deleted.route'))` | 188 | Flash message: "Route permanently deleted." |
| **Code Flow** | forceDelete() is a PERMANENT DELETE operation: authorize → find withTrashed (active or trashed) → force delete → log → redirect to trash |

#### CODE-TRACE-11: `toggleStatus(Request $request, Route $route)` — Toggle Active (POST)

| Step | Code | Line | What Happens |
|------|------|------|-------------|
| 1 | `Gate::authorize('tenant.route.update')` | 196 | Authorization check for update permission (NOT tenant.route.status despite Policy having status()) |
| 2 | `$request->validate(['is_active' => 'required|boolean'])` | 198-200 | Inline validation: is_active must be present and boolean (true/false/0/1/"0"/"1") |
| 3 | `$route->is_active = $request->is_active` | 202 | Sets model property from request (e.g., true or false). NOTE: no cast on assignment — request provides raw value |
| 4 | `activityLog($route, 'Toggled', [...])` | 204-207 | **BUG**: Activity log written BEFORE save(). If save() fails, log is still written. Log: event='Toggled', message='Route status was updated.' |
| 5 | `if ($route->save())` | 209 | UPDATE tpt_route SET is_active = $request->is_active, updated_at = NOW() WHERE id = $id. Returns true/false |
| 6 | Success branch | 210-215 | Returns JSON: `{success: true, is_active: $route->is_active, message: flash('status_updated.route')}` |
| 7 | Failure branch | 217-221 | Returns JSON: `{success: false, message: flash('status_switch_failed.route')}` — same HTTP 200 status |
| **Code Flow** | toggleStatus() is an UPDATE operation: authorize → validate inline → set property → log (before save) → save → return JSON response |

---

## 7. Detailed Test Steps

### TC-P01: Route Tab Loads Inside Transport Master

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with all route permissions | Dashboard loads |
| 2 | Expand "Transport" sidebar menu → Click "Transport Master" | URL: `/transport/master` |
| 3 | Click "Route" tab | URL updates to `/transport/master?tab=route`; Route tab-pane visible |
| 4 | Check filter bar | Search input (placeholder "Search...Code,Name"), Shift dropdown, Pickup/Drop dropdown, Status dropdown, Search button (magnifying glass), Reset button (rotate-left) |
| 5 | Check Add Route button | Button visible (part of `x-backend.tab.search-bar` component with `url="transport.route" permissions="tenant.route"`) |
| 6 | Check Trash button | Button visible |
| 7 | Check table headers | Code, Name, Description, Pickup/Drop, Shift, Status, Action |
| 8 | If routes exist, check action buttons per row | View (eye), Edit (pencil), Delete (trash), Status toggle (switch) visible per permissions |

### TC-P02: Create Route With All Required Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Route tab | Tab loaded |
| 2 | Click "Add Route" button | Navigate to `/route/create` — full-page create form with breadcrumb |
| 3 | Enter code: "MG-ROAD-01" | Field filled |
| 4 | Enter name: "MG Road Morning Pickup" | Field filled |
| 5 | Select pickup_drop: "Pickup" | Dropdown set |
| 6 | Select shift from dropdown | Shift selected by ID |
| 7 | Ensure Status toggle is ON (is_active checked) | Switch shows active |
| 8 | Click "Add Route" submit button | POST `/route` with form data |
| 9 | Verify redirect | Redirected to `/transport/master?tab=route` |
| 10 | Verify flash message | Success alert: "Route created successfully" |
| 11 | DB check: `SELECT * FROM tpt_route WHERE code='MG-ROAD-01'` | Record exists with code, name, pickup_drop='Pickup', shift_id, is_active=1 |
| 12 | Activity log check: `SELECT * FROM activity_logs WHERE log_name='Route' AND description LIKE '%Stored%'` | "Stored" entry exists with message "A new route was created." |

### TC-P04: View Route Details

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Route tab | Route list visible |
| 2 | Click View (eye) icon on a route row | Navigate to `/route/{id}` |
| 3 | Check Route Code row | Badge with code value displayed |
| 4 | Check Route Name | Name in strong tag |
| 5 | Check Route Geometry | Geometry value displayed (or dash if null) |
| 6 | Check Pickup Drop | Text value |
| 7 | Check Description | Description text or dash |
| 8 | Check Shift | Shift name as badge with code in parentheses |
| 9 | Check Status | "Active" (green badge with check icon) or "Inactive" (red badge with times icon) |
| 10 | Check Created At | Date in "d M Y, h:i A" format |
| 11 | Check Updated At | Date in "d M Y, h:i A" format |
| 12 | Check Back to List button | Present and links to `transport.transport-master.index` |
| 13 | Check Edit button | Present (if `tenant.route.edit` permission) and links to `/route/{id}/edit` |

### TC-P10: Soft Delete Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Route tab | Route list visible |
| 2 | Note the route code and status | Route exists with is_active=true/false |
| 3 | Click Delete (trash) icon on the route | Confirm dialog (if any) |
| 4 | Confirm deletion | DELETE `/route/{id}` |
| 5 | Verify redirect | Redirected to `/transport/master?tab=route` |
| 6 | Verify flash message | "Route trashed successfully" |
| 7 | DB check: `SELECT is_active, deleted_at FROM tpt_route WHERE id={id}` | is_active=0 AND deleted_at IS NOT NULL |
| 8 | Route no longer in main list | Route row not visible |
| 9 | Click Trash button | Navigate to `/route/trash/view` — route visible in trash list |
| 10 | Activity log check: `SELECT * FROM activity_logs WHERE log_name='Route' AND description LIKE '%Trashed%'` | "Trashed" entry exists with message "Route was deactivated and trashed." |

### TC-P12: Restore Route From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/route/trash/view` | Trashed routes list |
| 2 | Locate the soft-deleted route | Route visible in table |
| 3 | Click Restore button | GET `/route/{id}/restore` |
| 4 | Verify redirect | Redirected to `/route/trash/view` |
| 5 | Verify flash message | "Route restored successfully" |
| 6 | DB check: `SELECT deleted_at, is_active FROM tpt_route WHERE id={id}` | deleted_at=NULL, is_active=0 (NOT auto-restored) |
| 7 | Activity log check: `SELECT * FROM activity_logs WHERE log_name='Route' AND description LIKE '%Restored%'` | "Restored" entry exists with message "Route was restored." |
| 8 | Go back to Route tab | Route visible in main list but status shows Inactive |

### TC-N21: Permission 403 — No Route Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.route.viewAny` | Dashboard loads |
| 2 | Navigate to `/transport/master` | Route tab is HIDDEN (does not appear in tab list) |
| 3 | Login as user WITH `tenant.route.viewAny` but WITHOUT `tenant.route.create` | Dashboard loads |
| 4 | Navigate to Route tab | Route list visible |
| 5 | Check for Add Route button | Button is HIDDEN |
| 6 | Try POST to `/route` directly | 403 Forbidden |
| 7 | Login as user WITHOUT `tenant.route.update` | Route list visible |
| 8 | Try PUT to `/route/{id}` | 403 Forbidden |
| 9 | Login as user WITHOUT `tenant.route.delete` | Route list visible |
| 10 | Try DELETE `/route/{id}` | 403 Forbidden |
| 11 | Login as user WITHOUT `tenant.route.restore` | Route list visible |
| 12 | Navigate to `/route/trash/view` | 403 Forbidden (trashed() checks restore) |
| 13 | Login as user WITHOUT `tenant.route.view` | Route tab visible (viewAny granted) |
| 14 | Try GET `/route/{id}` (show page) | 403 Forbidden (show() checks view) |
| 15 | Login as user WITHOUT `tenant.route.forceDelete` | Route list visible |
| 16 | Login as user WITH `tenant.route.restore` (to see trash) | Trash page loads |
| 17 | Try DELETE `/route/{id}/force-delete` on a trashed route | 403 Forbidden (forceDelete() checks forceDelete) |
| 18 | Login as user WITHOUT `tenant.route.update` | Route list visible |
| 19 | Try POST `/route/{route}/toggle-status` with `is_active=0` | 403 Forbidden (toggleStatus() checks update) |

### TC-CR01: Blade @can Directives — Permission-based Visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `route/index.blade.php` | Search bar uses `<x-backend.tab.search-bar url="transport.route" permissions="tenant.route">` component |
| 2 | Inspect action column header | `@canany(['tenant.route.edit', 'tenant.route.delete'])` wraps `<th>Action</th>` |
| 2b | Inspect action column body | Same `@canany(['tenant.route.edit', 'tenant.route.delete'])` wraps `<x-backend.table.action>` — symmetric header/body ✅ |
| 2c | ⚠️ Bug note | `tenant.route.edit` is NOT defined in `RoutePolicy` (only `tenant.route.update` exists). For non-super-admin users, `Gate::allows('tenant.route.edit')` returns `false`. The action column is **always hidden** for normal users. Should be `@canany(['tenant.route.update', 'tenant.route.delete'])`. |
| 3 | Inspect `route/show.blade.php` | `@can('tenant.route.edit')` wraps Edit button in card-tools — same issue: `tenant.route.edit` has no Policy method, Edit button always hidden for normal users. Should be `@can('tenant.route.update')`. |
| 4 | Inspect `route/trash.blade.php` | `@canany(['tenant.route.restore', 'tenant.route.forceDelete'])` wraps `<x-backend.table.action-trashed>` ✅ both permissions exist in Policy |
| 4b | Inspect trash action column body | Same `@canany` also wraps `<td>` — symmetric header/body ✅ |
| 5 | Inspect status column in index | `<th>Status</th>` has NO `@can` wrapper; `<td>` with `<x-backend.table.status-switch>` also has NO `@can` wrapper — symmetric (neither side wrapped). The status-switch component does NOT pass a `permission` attribute. ⚠️ Users with `tenant.route.viewAny` only (no `tenant.route.update`) will still see the toggle switch, but the switch API call will return 403 when clicked (toggleStatus checks `tenant.route.update`). This is a UX gap: the switch should be hidden from users who cannot toggle. |
| 6 | Login as user with all permissions | All buttons visible and functional |
| 7 | Login as user with viewAny only | Add button hidden; action column shows no buttons (due to `tenant.route.edit` bug); status switch visible but non-functional (403 on click) |

### TC-CR02: Controller — Gate::authorize() Before Every State Change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `TransportMasterController::index() ? routesQuery() [Tab-based]()` | Line 20: `Gate::authorize('tenant.route.viewAny')` |
| 2 | Inspect `create()` | Line 32: `Gate::authorize('tenant.route.create')` |
| 3 | Inspect `store()` | Line 44: `Gate::authorize('tenant.route.create')` |
| 4 | Inspect `show()` | Line 62: `Gate::authorize('tenant.route.view')` |
| 5 | Inspect `edit()` | Line 74: `Gate::authorize('tenant.route.update')` |
| 6 | Inspect `update()` | Line 87: `Gate::authorize('tenant.route.update')` |
| 7 | Inspect `destroy()` | Line 126: `Gate::authorize('tenant.route.delete')` |
| 8 | Inspect `trashed()` | Line 146: `Gate::authorize('tenant.route.restore')` |
| 9 | Inspect `restore()` | Line 158: `Gate::authorize('tenant.route.restore')` |
| 10 | Inspect `forceDelete()` | Line 177: `Gate::authorize('tenant.route.forceDelete')` |
| 11 | Inspect `toggleStatus()` | Line 196: `Gate::authorize('tenant.route.update')` |

### TC-CR27: Frontend-Backend Discrepancy — Code Max Length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open route create form | Form loaded |
| 2 | Check code field placeholder | "Enter route code (max 20 characters)" |
| 3 | Enter 21-character code: "ABCDEFGHIJKLMNOPQRSTU" | Browser may allow (no maxlength attribute) |
| 4 | Submit form | POST to store |
| 5 | Check result | Validation passes (backend max is 50). Route created with 21-char code. |
| 6 | Verify code in DB | Code stored as 21 characters |
| 7 | Backend test: Enter 51-character code | Backend validation fails: "The code must not be greater than 50 characters." |

### TC-P03: Create Route With Description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/route/create` | Create form displayed |
| 2 | Enter code: "ROUTE-DESC" | Code field filled |
| 3 | Enter name: "Route with Description" | Name field filled |
| 4 | Select pickup_drop: "Pickup" | Dropdown set |
| 5 | Select shift from dropdown | Shift selected by ID |
| 6 | Ensure Status toggle is ON | is_active checked |
| 7 | Enter description: "This is a test route description for morning pickup service covering main road areas" | Description field filled (≤500 chars) |
| 8 | Click "Add Route" submit button | POST `/route` |
| 9 | Verify redirect | Redirected to `/transport/master?tab=route` |
| 10 | Verify flash message | Success alert displayed |
| 11 | DB check: `SELECT description FROM tpt_route WHERE code='ROUTE-DESC'` | Description stored exactly as entered |
| 12 | View route: Click View icon | Show page displays description text (not dash) |

### TC-P05: Edit Route Loads Pre-Filled Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Route tab | Route list visible |
| 2 | Click Edit (pencil) icon on a route row | Navigate to `/route/{id}/edit` |
| 3 | Verify Gate check | `Gate::authorize('tenant.route.update')` passes (line 74) |
| 4 | Verify route loaded | `Route::findOrFail($id)` — route found |
| 5 | Check code field | Pre-filled with existing route code |
| 6 | Check name field | Pre-filled with existing route name |
| 7 | Check pickup_drop dropdown | Set to existing value |
| 8 | Check shift dropdown | Set to existing shift_id, populated with active shifts only (Shift::active()->get()) |
| 9 | Check status checkbox | Toggle matches current is_active value |
| 10 | Check description field | Pre-filled with existing description |
| 11 | Verify form action URL | Form action points to `/route/{id}` with method PUT |

### TC-P06: Update Route — Change Name and Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/route/{id}/edit` for existing route | Edit form loaded |
| 2 | Record original code: "OLD-CODE" and name: "Old Name" | Values noted |
| 3 | Change code to: "NEW-CODE-UPDATED" | Code field updated |
| 4 | Change name to: "Updated Route Name" | Name field updated |
| 5 | Click "Update Route" submit button | PUT `/route/{id}` |
| 6 | Verify controller flow | Line 89: `$original = $route->getOriginal()` captures old values; Line 90: `$route->update($request->validated())` executes; Line 92: `$changes = $route->getChanges()` detects changes |
| 7 | Verify redirect | Redirected to `/transport/master?tab=route` |
| 8 | Verify flash message | "Route updated successfully" |
| 9 | DB check: `SELECT code, name FROM tpt_route WHERE id={id}` | code='NEW-CODE-UPDATED', name='Updated Route Name' |
| 10 | Activity log check | `activity_logs` table has entry with event='Updated', changes showing old→new for both code and name |
| 11 | Verify change tracking detail | Each field logged as `['old' => 'OLD-CODE', 'new' => 'NEW-CODE-UPDATED']` — `updated_at` excluded from changes |
| 12 | Verify performed_by in log | `Auth::user()->name` present in activity log properties |

### TC-P07: Update Route — Change Shift Assignment

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure two active shifts exist: Shift A (id=1) and Shift B (id=2) | Shifts active |
| 2 | Create route with shift_id=1 | Route assigned to Shift A |
| 3 | Navigate to edit form for this route | Edit form with Shift A selected |
| 4 | Change shift dropdown to Shift B | shift_id=2 selected |
| 5 | Click "Update Route" | PUT `/route/{id}` |
| 6 | Verify validation | `shift_id` rule `exists:tpt_shift,id` passes (Shift B exists and is active) |
| 7 | DB check: `SELECT shift_id FROM tpt_route WHERE id={id}` | shift_id=2 |
| 8 | Verify activity log | Changes array includes `shift_id` with old:1, new:2 |
| 9 | View route: shift badge shows Shift B name | Shift relationship loaded correctly |

### TC-P08: Update Route — Toggle pickup_drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route with pickup_drop="Pickup" | Route with Pickup type |
| 2 | Navigate to edit form | Edit form loads with pickup_drop="Pickup" |
| 3 | Change pickup_drop to "Drop" | Dropdown changed |
| 4 | Click "Update Route" | PUT `/route/{id}` |
| 5 | Verify validation | `Rule::in(['Pickup', 'Drop'])` passes for "Drop" |
| 6 | DB check: `SELECT pickup_drop FROM tpt_route WHERE id={id}` | 'Drop' |
| 7 | Verify activity log | Changes array includes `pickup_drop` with old:'Pickup', new:'Drop' |
| 8 | Index page shows "Drop" badge | Table column updated |
| 9 | Change back to "Pickup" | Same process, reverse change tracked |

### TC-P09: Update Route — No Changes Submitted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit form for existing route | Edit form with pre-filled values |
| 2 | Click "Update Route" WITHOUT changing any field | PUT `/route/{id}` with same values |
| 3 | Verify controller flow | Line 89-90: `$original` captured, `$route->update()` called with identical data |
| 4 | Verify `getChanges()` | Returns only `['updated_at' => '...']` or empty (depends on DB driver) |
| 5 | Verify `updated_at` filtered out | Line 96: `if ($field === 'updated_at') continue;` → `$changedAttributes` empty |
| 6 | Verify no-changes branch | Line 104: `if (!empty($changedAttributes))` evaluates false |
| 7 | Verify activity log message | "Route updated. No attributes changed." stored in activity_logs |
| 8 | Verify redirect and flash | Redirected with success flash despite no changes |
| 9 | DB check: `SELECT updated_at FROM tpt_route WHERE id={id}` | Timestamp updated (Eloquent always touches updated_at on update()) |

### TC-P11: Trash Page Shows Deleted Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least one route has been soft-deleted | Route with deleted_at NOT NULL |
| 2 | Navigate to `/route/trash/view` | Trash list page loads |
| 3 | Verify Gate check | `Gate::authorize('tenant.route.restore')` passes (line 146) |
| 4 | Verify query | `Route::onlyTrashed()->with('shift')->paginate(10)` — only soft-deleted records |
| 5 | Check table headers | Route Code, Route Name, Description, Route Geometry, Shift, is_active, Created At, Deleted At, Action |
| 6 | Verify trashed route visible | Previously deleted route appears in table |
| 7 | Check Action column buttons | Restore (recycle icon) and Force Delete (red trash icon) buttons visible |
| 8 | Check Restore button link | URL matches `transport.route.restore` route pattern |
| 9 | Check Force Delete button | URL matches `transport.route.forceDelete` route pattern |
| 10 | Check pagination | If more than 10 trashed routes, pagination links appear |

### TC-P13: Force Delete Route (No Dependencies)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a route exists (either active or trashed) | Route with no FK dependencies |
| 2 | Navigate to `/route/trash/view` | Trash list |
| 3 | Click Force Delete button on a trashed route | DELETE `/route/{id}/force-delete` |
| 4 | Verify Gate check | `Gate::authorize('tenant.route.forceDelete')` passes (line 177) |
| 5 | Verify `withTrashed()` query | `Route::withTrashed()->findOrFail($id)` finds the record regardless of deleted_at status (line 179) |
| 6 | Verify `forceDelete()` | `$route->forceDelete()` executes DELETE FROM tpt_route WHERE id = $id (line 180) |
| 7 | Verify redirect | Redirected to `/route/trash/view` |
| 8 | Verify flash message | "Route permanently deleted." |
| 9 | DB check: `SELECT * FROM tpt_route WHERE id={id}` | Record no longer exists (0 rows) |
| 10 | Activity log check | `activity_logs` has event='Deleted' with message "Route was permanently deleted." |
| 11 | Verify FK behavior | If dependent records exist (tpt_pickup_points_route_jnt with CASCADE), they are also permanently deleted |

### TC-P14: Toggle Status Active → Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Route tab | Route list with at least one active route |
| 2 | Locate the status toggle switch on an active row | Toggle shows "Active" (green/checked) |
| 3 | Click the toggle switch | AJAX POST to `/route/{route}/toggle-status` |
| 4 | Verify Gate check | `Gate::authorize('tenant.route.update')` passes (line 196) |
| 5 | Verify inline validation | `$request->validate(['is_active' => 'required|boolean'])` passes with is_active=false |
| 6 | Verify model assignment | `$route->is_active = $request->is_active` sets to false (line 202) |
| 7 | Verify activity log | Log written BEFORE save (line 204-207): event='Toggled', message='Route status was updated.' |
| 8 | Verify save | `$route->save()` executes UPDATE tpt_route SET is_active=0 WHERE id=$id (line 209) |
| 9 | Verify JSON response | `{success: true, is_active: false, message: "Status updated"}` |
| 10 | Verify UI update | Toggle switch shows "Inactive" (red/unchecked) |
| 11 | DB check: `SELECT is_active FROM tpt_route WHERE id={id}` | is_active=0 |

### TC-P15: Toggle Status Inactive → Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Transport Master → Route tab | Route list with at least one inactive route |
| 2 | Locate the status toggle switch on an inactive row | Toggle shows "Inactive" (red/unchecked) |
| 3 | Click the toggle switch | AJAX POST to `/route/{route}/toggle-status` with is_active=true |
| 4 | Verify inline validation | `required|boolean` passes |
| 5 | Verify `$route->is_active = $request->is_active` | Set to true |
| 6 | Verify JSON response | `{success: true, is_active: true}` |
| 7 | DB check: `SELECT is_active FROM tpt_route WHERE id={id}` | is_active=1 |
| 8 | UI shows "Active" badge | Green badge displayed |

### TC-P16: Full Lifecycle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route via POST `/route` with all fields | Route created, redirect to master tab |
| 2 | Verify DB has the new record | `SELECT * FROM tpt_route WHERE code='LIFECYCLE-TEST'` returns row |
| 3 | View route via GET `/route/{id}` | Show page renders all fields |
| 4 | Edit route via GET `/route/{id}/edit` | Edit form pre-filled |
| 5 | Update route via PUT `/route/{id}` (change name) | Updated, activity log recorded |
| 6 | Toggle status OFF via POST toggle-status | JSON success, is_active=false |
| 7 | Soft delete via DELETE `/route/{id}` | is_active=false, deleted_at set |
| 8 | Navigate to trash `/route/trash/view` | Route visible in trash list |
| 9 | Restore via GET `/route/{id}/restore` | deleted_at=NULL, is_active stays false |
| 10 | Toggle status ON via POST toggle-status | is_active=true, route active again |
| 11 | Force delete via DELETE `/route/{id}/force-delete` | Record permanently removed |
| 12 | Verify DB record gone | `SELECT * FROM tpt_route WHERE id={id}` returns 0 rows |
| 13 | Verify activity logs for all 6 events | Stored, Updated, Toggled, Trashed, Restored, Deleted — all present |

### TC-P17: Filter Routes By Search (Code)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 2 routes exist with different codes | e.g., "ROUTE-A", "ROUTE-B" |
| 2 | Navigate to Transport Master → Route tab | All routes visible |
| 3 | Enter route code "ROUTE-A" in search input | Search box filled |
| 4 | Click Search (magnifying glass) button | GET `/transport/master?tab=route&search=ROUTE-A` |
| 5 | Verify TransportMasterController query | `routesQuery()` sees tab=route, search=ROUTE-A → `WHERE (code LIKE '%ROUTE-A%' OR name LIKE '%ROUTE-A%')` |
| 6 | Table shows only Route A | Route B is not visible |
| 7 | Click Reset button | All routes shown again |

### TC-P18: Filter Routes By Search (Name)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create routes with names "Morning Pickup Route" and "Evening Drop Route" | Two routes |
| 2 | Enter "Morning" in search input | Search box filled |
| 3 | Click Search | GET with search=Morning |
| 4 | Verify query | `WHERE (code LIKE '%Morning%' OR name LIKE '%Morning%')` — matches name |
| 5 | Only "Morning Pickup Route" visible | Filtered result |

### TC-P19: Filter Routes By Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 2+ shifts exist with routes assigned | Routes: R1 (shift=A), R2 (shift=B) |
| 2 | Navigate to Route tab | All routes visible |
| 3 | Select Shift A from filter dropdown | shift_id dropdown set to A |
| 4 | Click Search | GET `/transport/master?tab=route&shift_id=A` |
| 5 | Verify query | `routesQuery()` applies `where('shift_id', A)` |
| 6 | Table shows only routes with Shift A | R2 (shift=B) hidden |

### TC-P20: Filter Routes By Pickup/Drop Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure routes with both Pickup and Drop types exist | R1: 'Pickup', R2: 'Drop' |
| 2 | Select "Pickup" from Pickup/Drop dropdown | Dropdown set |
| 3 | Click Search | GET with pickup_drop='Pickup' |
| 4 | Verify query | `where('pickup_drop', 'Pickup')` applied |
| 5 | Only Pickup routes visible | Drop routes filtered out |
| 6 | Select "Drop" → only Drop routes visible | Filter works both ways |
| 7 | Select empty/default → all routes visible | Filter removed |

### TC-P21: Filter Routes By Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure both active and inactive routes exist | R1: is_active=1, R2: is_active=0 |
| 2 | Select "Inactive" from Status dropdown | Status=0 |
| 3 | Click Search | GET with status=0 |
| 4 | Verify query uses `isset($request->status)` | `isset(0)` = true — correct handling |
| 5 | Only inactive routes visible | All is_active=0 |
| 6 | Select "Active" → only active routes visible | is_active=1 |
| 7 | Note: `isset()` is correct for status filter because `filled()` treats 0 as empty | Important implementation detail |

### TC-P22: Empty State — No Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no routes exist in DB | `Route::count() = 0` |
| 2 | Navigate to Transport Master → Route tab | Tab loads |
| 3 | Check table body | Shows "No Data Found" message spanning all 7 columns |
| 4 | Verify filter bar works (disable all filters) | Still "No Data Found" (correct — no data) |
| 5 | Verify Add Route button still visible | User can navigate to create new route |

### TC-P23: Empty State — No Trashed Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no soft-deleted routes exist | `Route::onlyTrashed()->count() = 0` |
| 2 | Navigate to `/route/trash/view` | Trash list loads |
| 3 | Check table body | Shows "No Data Found" message |
| 4 | Verify Restore and Force Delete no-action | No rows to act on |

### TC-P24: Pagination — Routes Exceed First Page

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 12+ routes exist in DB | `Route::count() >= 12` |
| 2 | Navigate to Route tab | First page shows 10 routes |
| 3 | Check bottom of table | Pagination links visible (1, 2, Next, Last) |
| 4 | Verify `withQueryString()` | Current tab param preserved in pagination links: `/transport/master?tab=route&page=2` |
| 5 | Click page 2 | URL updates to `/transport/master?tab=route&page=2`, shows remaining routes |
| 6 | Verify filter persistence | If search active, param preserved: `/transport/master?tab=route&search=ABC&page=2`

### TC-N01: Required — Missing Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/route/create` | Create form |
| 2 | Leave code field EMPTY | No input |
| 3 | Fill all other required fields (name, pickup_drop, shift, is_active) | Valid other fields |
| 4 | Click "Add Route" | POST to store |
| 5 | Verify RouteRequest validation | `code` rule 'required' fires |
| 6 | Validation error: "The code field is required." | Error displayed on form |
| 7 | DB check: no new route created | Record count unchanged |

### TC-N02: Required — Missing Name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `/route/create` | Create form |
| 2 | Fill code, pickup_drop, shift, is_active | Valid other fields |
| 3 | Leave name field EMPTY | No input |
| 4 | Click "Add Route" | POST to store |
| 5 | Validation error: "The name field is required." | Error on name field |
| 6 | DB unchanged | 0 new rows |

### TC-N03: Required — Missing pickup_drop

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Fill code, name, shift, is_active | Valid other fields |
| 3 | Leave pickup_drop unselected | No value |
| 4 | Click "Add Route" | POST to store |
| 5 | Validation error: "The pickup drop field is required." | Error on pickup_drop |

### TC-N04: Required — Missing shift_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Fill code, name, pickup_drop, is_active | Valid other fields |
| 3 | Leave shift dropdown unselected | No shift_id |
| 4 | Click "Add Route" | POST to store |
| 5 | Validation error: "The shift id field is required." | Error on shift_id |

### TC-N05: Duplicate Code (Global Unique)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route with code "DUP-CODE" | Route created |
| 2 | Navigate to create form again | Form loaded |
| 3 | Enter code "DUP-CODE" (same code) | Duplicate value |
| 4 | Fill other required fields | Valid |
| 5 | Click "Add Route" | POST to store |
| 6 | RouteRequest validation: `Rule::unique('tpt_route','code')` fires | "The code has already been taken." |
| 7 | Edit the original route and try changing to another existing code | Unique rule ignores current record via `->ignore($routeId)` — should pass |

### TC-N06: Duplicate Name (Global Unique)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route with name "Duplicate Name Route" | Route created |
| 2 | Create another route with same name "Duplicate Name Route" | POST with duplicate name |
| 3 | Validation error: "The name has already been taken." | `Rule::unique('tpt_route','name')` fires |
| 4 | Update original route's name to another existing name without changing | Unique rule with `->ignore($routeId)` works on update |

### TC-N07: Max Length — Code > 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter 51-character code: "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ" | 51 chars |
| 3 | Fill other fields | Valid |
| 4 | Click "Add Route" | POST to store |
| 5 | RouteRequest validation: `max:50` fires | "The code must not be greater than 50 characters." |
| 6 | Frontend test: Note view placeholder says "max 20" — this is misleading | UX discrepancy confirmed |

### TC-N08: Max Length — Name > 200 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter 201-character name | Over max:200 |
| 3 | Click "Add Route" | POST to store |
| 4 | Validation error: "The name must not be greater than 200 characters." | Backend catches |
| 5 | Note: View placeholder says "max 100" — UX discrepancy | Backend allows twice as much |

### TC-N09: Max Length — Description > 500 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Enter 501-character description | Over max:500 |
| 3 | Click "Add Route" | POST to store |
| 4 | Validation error: "The description must not be greater than 500 characters." | Backend catches |
| 5 | Note: View maxlength="200" — browser truncates before backend validation | Frontend limit is stricter |

### TC-N10: Invalid pickup_drop — Not 'Pickup' or 'Drop'

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Manipulate pickup_drop value to "Invalid" (via browser dev tools or direct API) | Value not in ['Pickup','Drop'] |
| 3 | Submit form | POST to store |
| 4 | Validation error: "The selected pickup drop is invalid." | `Rule::in(['Pickup', 'Drop'])` fires |
| 5 | Test also empty string and null | Same error |

### TC-N11: Invalid shift_id — Non-Existent Shift

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Manipulate shift_id to 99999 (non-existent) | Value not in tpt_shift table |
| 2 | Submit create form | POST to store |
| 3 | Validation error: "The selected shift id is invalid." | `exists:tpt_shift,id` fires |

### TC-N12: View Route With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/route/99999` | RouteController@show(99999) |
| 2 | `Route::with('shift')->findOrFail(99999)` | ModelNotFoundException thrown |
| 3 | 404 error page rendered | "No query results for model..." |

### TC-N13: Edit Route With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/route/99999/edit` | RouteController@edit(99999) |
| 2 | `Route::findOrFail(99999)` | ModelNotFoundException |
| 3 | 404 response | "No query results" |

### TC-N14: Update Route With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | PUT `/route/99999` with valid data | RouteController@update() with implicit binding |
| 2 | Route model binding: no Route with id=99999 | ModelNotFoundException before method body executes |
| 3 | 404 response | Route not found |

### TC-N15: Delete Route With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/route/99999` | RouteController@destroy() with implicit binding |
| 2 | Route model binding fails (no record) | ModelNotFoundException |
| 3 | 404 response | Route not found |

### TC-N16: Toggle Status With Invalid ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/route/99999/toggle-status` with is_active=0 | RouteController@toggleStatus() with implicit binding |
| 2 | Route model binding: no Route with id=99999 | ModelNotFoundException before Gate check |
| 3 | 404 response | Route not found |

### TC-N17: Restore Non-Deleted Route (Active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a route exists with deleted_at=NULL (active) | Active route |
| 2 | GET `/route/{id}/restore` where id is an ACTIVE route | Controller@restore($id) |
| 3 | `Gate::authorize('tenant.route.restore')` passes | Authorized |
| 4 | `Route::onlyTrashed()->findOrFail($id)` | WHERE deleted_at IS NOT NULL AND id = $id → no rows because route is active |
| 5 | ModelNotFoundException thrown | 404 response |
| 6 | DB check: route remains unchanged | deleted_at still NULL, is_active unchanged |

### TC-N18: Force Delete Non-Trashed Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a route exists with deleted_at=NULL (active, NOT trashed) | Active route |
| 2 | DELETE `/route/{id}/force-delete` on the active route | Controller@forceDelete($id) |
| 3 | `Gate::authorize('tenant.route.forceDelete')` passes | Authorized |
| 4 | `Route::withTrashed()->findOrFail($id)` — NOTE: uses withTrashed(), NOT onlyTrashed() | Finds the active route (withTrashed ignores deleted_at) |
| 5 | `$route->forceDelete()` | Permanently deletes even though route was active |
| 6 | DB check: record is gone | `SELECT * FROM tpt_route WHERE id={id}` = 0 rows |
| 7 | **Contrast**: This is correct behavior — withTrashed() allows force-deleting active routes without soft-deleting first | RouteController follows correct pattern |

### TC-N19: Force Delete Route With Active Student Allocations (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route with student allocations referencing it | pickup_route_id or drop_route_id = route.id |
| 2 | DELETE `/route/{id}/force-delete` | Controller@forceDelete() |
| 3 | `$route->forceDelete()` executes | DELETE FROM tpt_route WHERE id = $id |
| 4 | DDL FK RESTRICT on tpt_student_route_allocation_jnt fires | DB integrity violation: "Cannot delete or update a parent row: a foreign key constraint fails" |
| 5 | PDOException or QueryException thrown | forceDelete() fails |
| 6 | Route record still exists in DB | Deletion blocked by FK constraint |
| 7 | Note: RouteController does NOT wrap forceDelete in try-catch | User sees 500 error (not caught) |

### TC-N20: Toggle Status With Non-Boolean is_active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/route/{route}/toggle-status` with is_active="invalid" | AJAX request |
| 2 | Inline validation at line 198-200: `$request->validate(['is_active' => 'required|boolean'])` | "The is active field must be true or false." |
| 3 | Test with is_active="abc" | Same error |
| 4 | Test with is_active=null | "The is active field is required." |
| 5 | Test with is_active=2 | "The is active field must be true or false." (2 is not 0/1/"0"/"1"/true/false for boolean rule) |
| 6 | Test with is_active=0 | Valid (0 is accepted by boolean rule) |
| 7 | Test with is_active=1 | Valid |

### TC-N22: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (no authenticated session) | Guest user |
| 2 | GET `/transport/master` | Redirect to `/login` |
| 3 | GET `/route` | Redirect to `/login` |
| 4 | GET `/route/create` | Redirect to `/login` |
| 5 | POST `/route` | Redirect to `/login` |
| 6 | GET `/route/{id}` | Redirect to `/login` |
| 7 | GET `/route/{id}/edit` | Redirect to `/login` |
| 8 | PUT `/route/{id}` | Redirect to `/login` |
| 9 | DELETE `/route/{id}` | Redirect to `/login` |
| 10 | GET `/route/trash/view` | Redirect to `/login` |
| 11 | GET `/route/{id}/restore` | Redirect to `/login` |
| 12 | DELETE `/route/{id}/force-delete` | Redirect to `/login` |
| 13 | POST `/route/{route}/toggle-status` | Redirect to `/login` |

### TC-N23: XSS Injection In Name or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route with code: `<script>alert('xss')</script>` | Code stored in DB as literal string |
| 2 | Create route with name: `<img src=x onerror=alert(1)>` | Name stored as literal string |
| 3 | Navigate to Route tab | Table displays values using Blade `{{ }}` syntax — automatically HTML-escaped |
| 4 | View route show page | Same — `{{ $route->code }}` escapes output |
| 5 | View route edit form | Input fields display escaped values |
| 6 | DB check: raw values stored as-is | `SELECT code, name FROM tpt_route WHERE id={id}` shows the raw script tags |
| 7 | No JavaScript execution in browser | All outputs properly escaped |

### TC-N24: Whitespace-Only Name or Code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route with code: "   " (3 spaces) | Code field: "   " |
| 2 | Fill other required fields | Valid |
| 3 | Click "Add Route" | POST to store |
| 4 | RouteRequest `required` rule | Laravel's `required` rule considers non-empty strings (including whitespace) as filled |
| 5 | Validation PASSES (potential gap) | "required" does NOT trim/validate meaningful content |
| 6 | Route created with whitespace-only code | Stored as "   " — may cause issues in UI display and filtering |
| 7 | Name with whitespace-only: same behavior | Passes validation, stored as-is |
| 8 | **Gap**: No `not_regex:/^\s*$/` or custom validation for meaningful content | Routes with invisible codes created |

### TC-N25: is_active Checkbox Not Checked

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loaded |
| 2 | Fill code, name, pickup_drop, shift_id | Valid |
| 3 | Leave is_active checkbox UNCHECKED | Browser does NOT send checkbox value when unchecked |
| 4 | Click "Add Route" | POST to store |
| 5 | RouteRequest::prepareForValidation() runs | `$this->has('is_active')` = false (checkbox not in request) → `is_active = false` |
| 6 | Route created with is_active=0 | Inactive route |
| 7 | DB check: `SELECT is_active FROM tpt_route` | 0 |
| 8 | Navigate to Route tab with "Active" filter | New route NOT visible (filtered out because is_active=0) |
| 9 | Navigate with "Inactive" filter | New route visible |

### TC-D01: Soft-Delete Route — PickupPointRoute Cascade Deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure route has associated PickupPointRoute records | `PickupPointRoute::where('route_id', $routeId)->count() >= 1` |
| 2 | Note current count of pickup point routes for this route | e.g., 3 records |
| 3 | Soft-delete the route via DELETE `/route/{id}` | `$route->delete()` sets deleted_at |
| 4 | DDL FK on `tpt_pickup_points_route_jnt.route_id` has ON DELETE CASCADE | Child rows auto-deleted |
| 5 | DB check: `SELECT COUNT(*) FROM tpt_pickup_points_route_jnt WHERE route_id={id}` | 0 rows (all cascaded) |
| 6 | Note: Cascade delete on pickup_point_route is permanent (not soft) | Child records are hard-deleted, not soft-deleted |

### TC-D02: Soft-Delete Route — DriverRouteVehicleJnt Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure route has DriverRouteVehicleJnt records | `DriverRouteVehicleJnt::where('route_id', $routeId)->exists()` = true |
| 2 | Soft-delete the route | deleted_at set |
| 3 | FK CASCADE on route_id in driver_route_vehicle_jnt | Child records auto-permanently deleted |
| 4 | DB check: Child records gone | 0 rows |

### TC-D03: Delete Route Blocked by Student Allocation (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route and assign to a student allocation as pickup_route | `tpt_student_route_allocation_jnt.pickup_route_id = route.id` |
| 2 | Attempt to forceDelete the route | DELETE query executed |
| 3 | FK RESTRICT on pickup_route_id | Integrity constraint violation thrown |
| 4 | Route record remains in DB | Deletion prevented |

### TC-D04: Delete Route Blocked by Drop Allocation (RESTRICT)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create route as drop_route in student allocation | `drop_route_id = route.id` |
| 2 | Attempt forceDelete | FK RESTRICT blocks it |
| 3 | Same behavior as TC-D03 | Route protected by RESTRICT FK |

### TC-D05: Shift Deletion Cascades To Routes (CASCADE)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure shift has routes assigned | Route(s) with shift_id = shift.id |
| 2 | Delete the shift from DB | DELETE FROM tpt_shift WHERE id = X |
| 3 | FK CASCADE on tpt_route.shift_id | All routes with that shift_id auto-deleted (soft-deleted via SoftDeletes? Depends on implementation) |
| 4 | DB check: `SELECT * FROM tpt_route WHERE shift_id = X` | 0 rows (all cascaded) |

### TC-D06: Route Deletion — BoardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure route has boarding_log records | `StudentBoardingLog::where('boarding_route_id', $routeId)->exists()` |
| 2 | Force-delete the route | Permanently removed |
| 3 | FK SET NULL on boarding_route_id | Boarding log records preserved, boarding_route_id set to NULL |
| 4 | DB check: `SELECT boarding_route_id FROM tpt_student_boarding_log WHERE boarding_route_id = X` | All NULL |

### TC-D07: Route Deletion — UnboardingLog SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure route has unboarding_log records | `StudentBoardingLog::where('unboarding_route_id', $routeId)->exists()` |
| 2 | Force-delete the route | Behavior same as TC-D06 |
| 3 | FK SET NULL on unboarding_route_id | Records preserved, unboarding_route_id = NULL |

### TC-D08: Restore Does Not Cascade to PickupPointRoute

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Route with PickupPointRoute records exists | Children exist |
| 2 | Soft-delete the route (destroy) | PickupPointRoute records are CASCADE-permanently-deleted |
| 3 | Restore the route (restore) | Route restored, deleted_at=NULL |
| 4 | Check PickupPointRoute records | **GONE** — cascade on soft-delete was permanent, not soft. CASCADE + SoftDeletes: child records were hard-deleted, not restored with parent |
| 5 | **Important**: This is a data loss scenario. Soft-deleting a route permanently deletes its pickup point route assignments. | Cannot recover stop assignments after route restore. |

### TC-D09: Rapid Status Toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Route tab | Route list visible |
| 2 | Rapidly click the status toggle switch 5 times in quick succession | 5 AJAX POST requests sent |
| 3 | Verify each request completes | Each returns JSON success/failure |
| 4 | Verify final state | `SELECT is_active FROM tpt_route WHERE id=X` — final toggle state (may be active or inactive depending on number of clicks parity) |
| 5 | Verify activity log | Each toggle creates a separate activityLog entry |
| 6 | Verify no duplicate records or data corruption | DB integrity maintained |

### TC-D10: Concurrent Update — Two Users Edit Same Route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens edit form for route X | Form loaded with current values |
| 2 | User B opens edit form for route X (same route) | Form loaded with same values |
| 3 | User A changes name to "Name-A" and submits PUT | Update succeeds, name = "Name-A" |
| 4 | User B changes name to "Name-B" and submits PUT | Update succeeds (no optimistic locking), name = "Name-B" |
| 5 | Final DB state: name = "Name-B" | Last save wins — User A's change is overwritten |
| 6 | Activity log shows two Update events | First: old → "Name-A"; Second: "Name-A" → "Name-B" (old shows previous, not original) |
| 7 | **Note**: getOriginal() captures values at time User B loaded the page, not at time of User A's update | Change tracking logs the transition from the stale value, not the User A-updated value |

### TC-CR03: Controller — activityLog After Every CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `store()` | Line 48-51: `activityLog($route, 'Stored', [...])` — present ✅ |
| 2 | Inspect `update()` | Lines 105-115: `activityLog($route, 'Updated', [...])` — present with change tracking ✅ |
| 3 | Inspect `destroy()` | Lines 132-135: `activityLog($route, 'Trashed', [...])` — present ✅ |
| 4 | Inspect `restore()` | Lines 163-166: `activityLog($route, 'Restored', [...])` — present ✅ |
| 5 | Inspect `forceDelete()` | Lines 182-185: `activityLog($route, 'Deleted', [...])` — present ✅ |
| 6 | Inspect `toggleStatus()` | Lines 204-207: `activityLog($route, 'Toggled', [...])` — present ✅ |
| 7 | **All 6 CRUD/action methods have activityLog** | Consistent audit trail across all state changes ✅ |
| 8 | **Note**: toggleStatus logs BEFORE save (potential issue) | Line 204-207 before line 209 save |

### TC-CR04: Controller — Change Tracking on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `update()` line 89 | `$original = $route->getOriginal()` — captures pre-update state |
| 2 | Inspect line 90 | `$route->update($request->validated())` — applies changes |
| 3 | Inspect line 92 | `$changes = $route->getChanges()` — gets only dirty attributes |
| 4 | Inspect line 96 | `if ($field === 'updated_at') continue;` — excludes timestamp from tracking |
| 5 | Inspect lines 98-101 | Each change: `$changedAttributes[$field] = ['old' => $original[$field], 'new' => $newValue]` |
| 6 | Inspect line 104-114 | If no real changes (only updated_at), logs "No attributes changed." message |
| 7 | **Pattern matches requirement** | Change tracking implemented correctly ✅ |

### TC-CR05: Controller — is_active=false Before Soft Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `destroy()` line 128 | `$route->is_active = false` — sets inactive in memory |
| 2 | Inspect line 129 | `$route->save()` — persists is_active=false to DB |
| 3 | Inspect line 130 | `$route->delete()` — sets deleted_at timestamp |
| 4 | **Order confirmed**: is_active=false → save → delete | Two DB writes executed sequentially ✅ |

### TC-CR06: Controller — withTrashed() for forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `forceDelete()` line 179 | `Route::withTrashed()->findOrFail($id)` |
| 2 | `withTrashed()` ignores deleted_at filter | Finds both active AND soft-deleted records |
| 3 | Can force-delete an active route without soft-deleting first | Correct pattern — differs from some other controllers that use onlyTrashed() |
| 4 | **Contrast with restore()** which uses onlyTrashed() | Proper separation: restore only for trashed, forceDelete for any ✅ |

### TC-CR07: Controller — onlyTrashed() for Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `restore()` line 160 | `Route::onlyTrashed()->findOrFail($id)` |
| 2 | `onlyTrashed()` adds WHERE deleted_at IS NOT NULL | Only soft-deleted records can be restored |
| 3 | Active records get 404 | Correct — can't restore what isn't deleted ✅ |

### TC-CR08: Controller — Non-RESTful toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect web.php route definitions | `Route::resource('route', RouteController::class)` — 7 RESTful routes |
| 2 | Additional routes include: `Route::post('/route/{route}/toggle-status', ...)` | toggleStatus is NOT part of Route::resource |
| 3 | **Only non-RESTful action** in RouteController | Other methods (trashed, restore, forceDelete) are also non-resource but follow standard patterns |

### TC-CR09: Request — authorize() Matches Controller Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `RouteRequest::authorize()` lines 11-17 | POST → `Gate::allows('tenant.route.create')` |
| 2 | Non-POST (PUT/PATCH) → `Gate::allows('tenant.route.update')` | Matches controller: store() uses create, update() uses update |
| 3 | **Double authorization**: Controller Gate::authorize() + Request authorize() | Both must pass for request to proceed ✅ |

### TC-CR10: Request — Validation Rules Match DDL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | code: `max:50` matches DDL `VARCHAR(50)` | ✅ |
| 2 | name: `max:200` matches DDL `VARCHAR(200)` | ✅ |
| 3 | description: `max:500` matches DDL `VARCHAR(500)` | ✅ |
| 4 | pickup_drop: `Rule::in(['Pickup','Drop'])` matches ENUM('Pickup','Drop') | ✅ |
| 5 | shift_id: `exists:tpt_shift,id` matches FK constraint | ✅ |

### TC-CR11: Request — prepareForValidation Checkbox Handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `prepareForValidation()` line 62-68 | Runs before rules() |
| 2 | `$this->has('is_active')` — checks if field exists in request | Returns false if checkbox unchecked (browser omits it) |
| 3 | `&& $this->input('is_active') === 'on'` — strict string comparison | Only the literal string "on" (what browser sends for checked checkbox) evaluates to true |
| 4 | `$this->merge(['is_active' => false])` when condition fails | Absent checkbox → merged as `false` (boolean) |
| 5 | `$this->merge(['is_active' => true])` when condition passes | Checked checkbox → merged as `true` (boolean) |
| 6 | **Edge case**: is_active="1" or is_active=true sent via API | Would fail `=== 'on'` check → merged as false. But API should send is_active boolean directly which gets normalized anyway |

### TC-CR12: Request — Unique Rule Ignore on Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `rules()` line 22 | `$routeId = $this->route('route')?->id` |
| 2 | On create: `$this->route('route')` is null → `$routeId = null` | `->ignore(null)` ignores nothing — full unique check |
| 3 | On update: `$this->route('route')` resolves the Route model → `->id` gives current record ID | `->ignore($routeId)` excludes current record from unique check |
| 4 | Both code and name use this pattern | Correct unique-on-update behavior ✅ |

### TC-CR13: Model — Table Name and SoftDeletes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `Route.php` line 16 | `protected $table = 'tpt_route';` ✅ |
| 2 | Open line 14 | `use HasFactory, SoftDeletes;` ✅ |
| 3 | Verify SoftDeletes provides: delete(), restore(), forceDelete(), trashed() scopes | All available ✅ |

### TC-CR14: Model — Fillable Matches DB Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `$fillable` lines 19-27 | 7 fields: code, name, description, pickup_drop, shift_id, is_active, route_geometry |
| 2 | Compare with DB columns (excluding PK, FKs, timestamps, deleted_at) | All user-input columns are fillable ✅ |
| 3 | **Note**: route_geometry is fillable but NOT validated in RouteRequest | Can be set programmatically but not via form submission |

### TC-CR15: Model — Casts for is_active and Dates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `$casts` lines 30-35 | `'is_active' => 'boolean'`, timestamps `=> 'datetime'` |
| 2 | `is_active` cast: 0→false, 1→true, "0"→false, "1"→true | Correct boolean behavior |
| 3 | `deleted_at => 'datetime'` — carbon instance | Available for date formatting |

### TC-CR16: Model — Default Attributes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `$attributes` lines 41-44 | `'is_active' => true`, `'pickup_drop' => 'pickup'` |
| 2 | `is_active => true` — new routes default to active | Correct |
| 3 | `pickup_drop => 'pickup'` — lowercase 'pickup' | Does NOT match ENUM values ['Pickup', 'Drop'] (PascalCase) |
| 4 | **Risk**: If model is saved WITHOUT going through RouteRequest validation (e.g., tinker, factory), lowercase 'pickup' would be stored | DB ENUM may reject lowercase, or MySQL may silently insert empty string depending on strict mode |

### TC-CR17: Model — All 10 Relationships Defined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `shift()` at line 83-86 | BelongsTo Shift ✅ |
| 2 | `pickupPointRoutes()` at line 68-71 | HasMany PickupPointRoute (ordered by ordinal) ✅ |
| 3 | `GetpickupPointRoutes()` at line 73-76 | HasOne PickupPointRoute ✅ |
| 4 | `pickupPoints()` at line 78-81 | HasMany PickupPoint ✅ |
| 5 | `driverRouteVehicles()` at line 88-91 | HasMany DriverRouteVehicleJnt ✅ |
| 6 | `studentAllocationsAll()` at line 94-98 | HasMany TptStudentAllocationJnt (pickup OR drop) ✅ |
| 7 | `trips()` at line 58-60 | HasMany TptTrip ✅ |
| 8 | `boardingLogs()` at line 53-56 | HasMany StudentBoardingLog (boarding_route_id) ✅ |
| 9 | `unBoardingLogs()` at line 62-65 | HasMany StudentBoardingLog (unboarding_route_id) ✅ |
| 10 | `tripStopDetails()` at line 101-111 | HasManyThrough TptTripStopDetail (via TptTrip, filtered by reached_flag=1) ✅ |

### TC-CR18: Routes — Resource + Additional Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | `Route::resource('route', RouteController::class)` | Creates 7 routes: index, create, store, show, edit, update, destroy |
| 2 | 4 additional routes: trashed (GET), restore (GET), forceDelete (DELETE), toggleStatus (POST) | Total: 11 routes mapped to RouteController |
| 3 | Additional routes use named patterns: `transport.route.trashed`, `transport.route.restore`, etc. | Consistent naming ✅ |

### TC-CR19: Route Names Consistently Prefixed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resource routes: `transport.route.index`, `transport.route.store`, etc. | ✅ |
| 2 | Additional routes follow same pattern: `transport.route.trashed`, `transport.route.restore`, `transport.route.forceDelete` | ✅ |
| 3 | Redirects in controller use these named routes consistently | All redirects reference `transport.transport-master.index` or `transport.route.trashed` ✅ |

### TC-CR20: View — Table Columns Match Requirements

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `route/index.blade.php` table header | 7 columns: #, Code, Name, Description, Pickup/Drop, Shift, Status, Action |
| 2 | **Note**: counted as 8 columns if serial number included | Requirements specify 7 + optional serial # |

### TC-CR21: View — Filter Controls Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect filter bar in `route/index.blade.php` | Search input (placeholder "Search...Code,Name"), Shift dropdown, Pickup/Drop dropdown, Status dropdown |
| 2 | Search button with magnifying glass icon | Submits filter form |
| 3 | Reset button with rotate-left icon | Clears all filters and reloads |
| 4 | All controls present | ✅ |

### TC-CR22: View — Show Page Displays All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `route/show.blade.php` | Route Code (badge), Route Name (strong), Route Geometry, Pickup Drop, Description, Shift (badge+code), Status (badge with icon), Created At, Updated At |
| 2 | 9 info rows displayed | ✅ |

### TC-CR23: View — Flash Messages After Every CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Store redirect: `flash('created.route')` | "Route created successfully" |
| 2 | Update redirect: `flash('updated.route')` | "Route updated successfully" |
| 3 | Destroy redirect: `flash('trashed.route')` | "Route trashed successfully" |
| 4 | Restore redirect: `flash('restored.route')` | "Route restored successfully" |
| 5 | ForceDelete redirect: `flash('force_deleted.route')` | "Route permanently deleted." |
| 6 | ToggleStatus failure: `flash('status_switch_failed.route')` | "Status update failed" |
| 7 | ToggleStatus success: `flash('status_updated.route')` | "Status updated" |

### TC-CR24: View — Null-Safe Operators for Relationships

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check `$route->shift?->name ?? 'N/A'` | Null-safe `?->` prevents error if shift is null (deleted or not set) |
| 2 | Check `$route->description ?? '-'` | Null coalescing shows dash for null description |
| 3 | All nullable fields handled safely | ✅ |

### TC-CR25: DDL — Spatial Index Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Read migration for tpt_route | `sp_idx_route_geometry` SPATIAL INDEX on route_geometry column |
| 2 | Column type: LINESTRING SRID 4326 | Spatial data type with SRID for GPS coordinates |

### TC-CR26: DDL — Unique Constraints Present

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Migration: `uq_route_code` UNIQUE on code | Prevents duplicate codes |
| 2 | Migration: `uq_route_name` UNIQUE on name | Prevents duplicate names |
| 3 | Both enforced at DB level as well as RouteRequest level | Double protection ✅ |

### TC-CR28: Frontend-Backend Discrepancy — Name Max Length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form, check name field placeholder | "Enter route name (max 100 characters)" |
| 2 | Enter 101-character name | If no maxlength on input, browser allows entry |
| 3 | Submit form | Backend max:200 → validation passes for up to 200 chars |
| 4 | Enter 201-character name | Backend validation fails: "The name must not be greater than 200 characters." |
| 5 | **Discrepancy confirmed**: Placeholder says 100, backend allows 200 | UX gap — user may never attempt values between 101-200 |

### TC-CR29: Frontend-Backend Discrepancy — Description Max Length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form, check description `maxlength` attribute | `maxlength="200"` on textarea |
| 2 | Browser enforces 200-char limit | Can't type more than 200 chars |
| 3 | Submit description with 200 chars | Backend accepts (max:500) |
| 4 | Submit description through API (bypassing browser) with 300 chars | Backend accepts (valid: max:500) |
| 5 | **Discrepancy confirmed**: Frontend 200, backend 500 | Users limited by browser; API users can submit 500 |

### TC-CR30: TransportMasterController — Route Query Filtering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `routesQuery()` line 149-181 | Query starts: `Route::query()->latest()` |
| 2 | Line 153: `if ($request->tab === 'route')` | All filters guarded by tab check |
| 3 | When tab is NOT 'route' → returns unfiltered query | `Route::query()->latest()` only |
| 4 | When tab IS 'route' → search, shift_id, pickup_drop, status filters applied | Line 155-177 |
| 5 | Search: `where('code', 'LIKE', "%{$search}%")->orWhere('name', 'LIKE', "%{$search}%")` | Both fields searched |
| 6 | Shift filter: `where('shift_id', $request->shift_id)` | Exact match |
| 7 | Pickup/Drop filter: `where('pickup_drop', $request->pickup_drop)` | Exact match on ENUM value |
| 8 | Status filter: `where('is_active', $request->status)` with `isset()` check | Correct handling of 0/inactive |
| 9 | Index view receives `$this->routesQuery($request)->paginate(10)->withQueryString()` | Paginated with query string preserved ✅ |

---

*Template: tpt_PickupStopsList_TcList.md (Syllabus depth) | Entity: Route | Date: 2026-07-21*

