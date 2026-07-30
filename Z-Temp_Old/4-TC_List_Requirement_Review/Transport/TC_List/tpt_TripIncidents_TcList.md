# tpt_TripIncidents_TcList

## Module: Transport → Trip Management → Trip Incidents

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Transport |
| Tab Group | Trip Management |
| Feature | Trip Incidents |
| URL(s) | `/transport/trip-management?tab=trip_incidents` (index via tab), `/transport/trip-incident/{id}/resolve` (resolveIncident GET) |
| Primary Controller (tab) | `Modules\Transport\Http\Controllers\TripMgmtController@index()` — tab: `trip_incidents` |
| Resolve Controller | `Modules\Transport\Http\Controllers\TripMgmtController@resolveIncident()` |
| Incident Creation Controller | `Modules\Transport\Http\Controllers\TripController@stopAction()` — case 'emergency' creates incidents |
| Model | `Modules\Transport\Models\TptTripIncidents` — table: `tpt_trip_incidents` |
| Permissions | `tenant.transport.viewAny` (page access), `tenant.trip.incident.viewAny` (tab visibility), `tenant.trip.incident.resolve` (resolve), `tenant.trip.incident.status` (resolve button in blade) |
| Soft Deletes | Yes (`TptTripIncidents` uses `SoftDeletes` trait) |
| Constants (Model) | `TYPE`: 0=StopEmergency, 1=VehicleBreakdown, 2=Accident, 3=RouteBlocked; `STATUS`: 0=OPEN, 1=RESOLVED; `SEVERITY`: LOW, MEDIUM, HIGH |
| Policy | `Modules\Transport\Policies\TransportTripIncidentPolicy` — defined but controller uses `Gate::authorize()` with string, NOT policy-based gates |
| Blade View | `Modules/Transport/resources/views/trip-incidents/index.blade.php` (partial included in hub) |
| JS | `Modules/Transport/resources/views/trip-incidents/js/js.blade.php` — SweetAlert2 confirmation + Litepicker date range |
| Routes File | `Modules/Transport/routes/web.php` line 56 |
| Created Via | Only via `TripController@stopAction()` `case 'emergency'` — no manual create route |
| PermissionsList Entry | `'trip.incident' => $crud` at permissionslist.php line 324 — NOTE: `$crud` does NOT contain `resolve` |

---

## 2. Pre-conditions

- Required permissions: `tenant.transport.viewAny` (page access via controller `Gate::authorize`), `tenant.trip.incident.viewAny` (tab visibility in blade), `tenant.trip.incident.resolve` (resolve action), `tenant.trip.incident.status` (resolve button visibility in blade)
- A trip must exist to associate incidents
- Incidents are created ONLY via the emergency action in stopAction() — no manual create route exists
- The incident tab is part of Trip Management (TripMgmtController@index)
- A route scheduler with driver_id is needed for `raised_by` population during incident creation
- An active trip must be in 'Ongoing' status for stop actions to function (stopAction uses trip date matching)
- The `tenant.trip.incident.resolve` permission key does NOT exist in `permissionslist.php` `$crud` array — only works via `is_super_admin` bypass in `Gate::before()`
- `@canany(['tenant.trip.incident.status'])` in blade line 69 uses `@endcan` on line 71 — directive mismatch (`@canany` must close with `@endcanany`)

---

## 3. Default Data Load

| Data | Source | Query | Controller Gate | Tab Permission | Filters | Pagination |
|------|--------|-------|-----------------|----------------|---------|------------|
| Incidents Grid | [Query/Code Removed] | [Query/Code Removed] | `tenant.transport.viewAny` | `tenant.trip.incident.viewAny` (blade) | `tab=trip_incidents`: `incident_type`, `status`, `date_range` | 10/page |

### Query Details

The `incidentQuery()` method (TripMgmtController line 449-485):



### Pagination

- Paginator: `incidentData` — set in `TripMgmtController@index()` line 87: `$incidentData = $this->incidentQuery($request)->paginate(10)->withQueryString();`
- Blade renders: `{{ $incidentData->withQueryString()->links() }}` (line 145 of blade)
- NOTE: Uses generic `->withQueryString()` — does NOT append `['tab' => 'trip_incidents']` unlike other tab partials in this codebase. This means page changes may lose the active tab context in certain form/filter configurations.

### Eager Loading

- The `trip()`, `raisedByUser()`, `incidentType()`, `statusMaster()`, `raisedBy()`, `raisedTo()` relationships are NOT eager-loaded
- Blade accesses `$incident->incident_type_label` (accessor, no query) and `$incident->resolvedBy?->name` (eager-loaded)
- Blade accesses `$incident->status_label` (accessor, no query) and `$incident->severity` (direct column)

---

## 4. Test Data Strategy

- Incidents can be created programmatically or via `stopAction` with `action=emergency`
- Incident creation via stopAction requires: an active trip, a PickupPointRoute junction record, and `POST /transport/trip/stop-action` with `id`, `action=emergency`, and optional `remark`
- Resolve sets `status=1`, `resolved_at=now()`, `resolved_by=auth()->id()`
- Double-resolve prevention: if status is already 1, redirects back with 'warning' flash
- No dedicated CRUD controller for incidents
- Soft-delete is possible via direct DB or model call (`$incident->delete()`) but no route/method exposes this
- DB-level cascade: trip deletion cascades to incidents (FK `fk_ti_trip` ON DELETE CASCADE)
- For testing the filter by `incident_type`: create incidents with different types (0,1,2,3)
- For testing the date_range filter: create incidents with different incident_time values spread across multiple days
- For pagination test: create 11+ incidents (adjust `paginate(10)` in query)
- For dependency tests: trip deletion (TC-D01), user deletion (TC-D02)

---

## 5. Business Conditions

### 5.1 Database Schema — `tpt_trip_incidents`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | trip_id | INT UNSIGNED | NOT NULL, FK → tpt_trip.id, ON DELETE CASCADE |
| BC-DB-03 | incident_time | TIMESTAMP | NOT NULL |
| BC-DB-04 | incident_type | INT UNSIGNED | NOT NULL |
| BC-DB-05 | severity | ENUM('LOW','MEDIUM','HIGH') | DEFAULT 'MEDIUM' |
| BC-DB-06 | latitude | DECIMAL(10,7) | DEFAULT NULL |
| BC-DB-07 | longitude | DECIMAL(10,7) | DEFAULT NULL |
| BC-DB-08 | description | VARCHAR(512) | DEFAULT NULL |
| BC-DB-09 | status | INT UNSIGNED | DEFAULT NULL (0=OPEN, 1=RESOLVED) |
| BC-DB-10 | raised_by | INT UNSIGNED | DEFAULT NULL, FK → sys_users.id, ON DELETE SET NULL |
| BC-DB-11 | raised_at | TIMESTAMP | NULL |
| BC-DB-12 | resolved_at | TIMESTAMP | NULL |
| BC-DB-13 | resolved_by | INT UNSIGNED | DEFAULT NULL, FK → sys_users.id, ON DELETE SET NULL |
| BC-DB-14 | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-15 | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-16 | deleted_at | TIMESTAMP | NULL |

### 5.1b Migration DDL Analysis — Gaps Found

| BC-ID-DDL | Issue | Details |
|-----------|-------|---------|
| BC-DDL-GAP-01 | Migration missing `trip_id` column declaration before FK | `trip_id` declared at line 29 AFTER other columns (status, raised_at, resolved_at) — FK reference column declared at line 30. Not a functional issue but DDL ordering puts FK column after timestamp columns, atypical for migration structure. |
| BC-DDL-GAP-02 | `raised_to` column does NOT exist in migration | Model has `raisedTo()` relationship referencing `raised_to` FK, but migration file `2026_06_16_140625_create_tpt_trip_incidents_table.php` has NO `raised_to` column. Running this relationship at runtime will throw `Illuminate\Database\Eloquent\RelationNotFoundException` or `SQLSTATE[42S22]: Column not found`. |
| BC-DDL-GAP-03 | Enum order mismatch: DDL vs Model | DDL defines `enum('severity', ['HIGH', 'LOW', 'MEDIUM'])` (line 18) — order is HIGH, LOW, MEDIUM. Model defines `SEVERITY` array with order LOW, MEDIUM, HIGH (line 60-64). While functionally equivalent, the order inconsistency could cause confusion during DB migrations and enum validation. |
| BC-DDL-GAP-04 | `raised_at` column is NULLABLE but `incident_time` is NOT NULL | Model `booted()` sets `raised_at` default on create, but `incident_time` has no model default and is NOT NULL in DDL. The controller `stopAction()` always passes `incident_time => $now`, so this is consistent at runtime but the model has no fallback guard for `incident_time`. |
| BC-DDL-GAP-05 | No index on `incident_type` or `status` columns | The `incidentQuery()` method filters by `incident_type` and `status` columns. With 10/page pagination and potential large datasets, lack of indexes on these filter columns could cause performance degradation. |
| BC-DDL-GAP-06 | No index on `incident_time` column | [Query/Code Removed] |
| BC-DDL-GAP-07 | `resolved_at` declared before `resolved_by` in DDL | DDL line 24: `resolved_at`, line 25-26: `created_at`/`updated_at`, line 33: `resolved_by`. The `resolved_by` FK column is declared AFTER `created_at`/`updated_at` — schema design places audit metadata in between the resolved fields. Minor schema design inconsistency. |

### 5.2 Authorization (Permission Gates)

| BC ID | Permission | Method / Location | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.transport.viewAny | TripMgmtController@index() (Gate::authorize) | Without → 403 |
| BC-AUTH-02 | tenant.trip.incident.viewAny | Blade `@can` wrapping tab & include | Without → tab hidden |
| BC-AUTH-03 | tenant.trip.incident.viewAny | Blade `@can` including `trip-incidents.index` partial | Without → partial not rendered |
| BC-AUTH-04 | tenant.trip.incident.resolve | resolveIncident() (Gate::authorize) | Without → 403 |
| BC-AUTH-05 | tenant.trip.incident.status | Blade `@canany` wrapping Action column (th + td) | Without → Resolve button hidden |

### 5.2b Authorization — Gap Analysis

| BC-ID-AUTH | Issue | Details | Severity |
|-----------|-------|---------|----------|
| BC-AUTH-GAP-01 | `tenant.trip.incident.resolve` NOT in permissionslist.php `$crud` | The `$crud` array (line 13-31 of permissionslist.php) defines standard actions: create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve. `resolve` is NOT in this list. The permission group `'trip.incident' => $crud` creates `tenant.trip.incident.create`, `tenant.trip.incident.view`, etc. but NOT `tenant.trip.incident.resolve`. `Gate::authorize('tenant.trip.incident.resolve')` will NEVER match a real permission — only works via `is_super_admin` bypass in `Gate::before()`. | 🔴 CRITICAL |
| BC-AUTH-GAP-02 | Gate mismatch — controller vs blade | Controller `index()` uses `Gate::authorize('tenant.transport.viewAny')` but the blade tab uses `permission => 'tenant.trip.incident.viewAny'`. A user who has `tenant.transport.viewAny` (passes controller gate) but NOT `tenant.trip.incident.viewAny` can access the page but won't see the tab. Vice versa, a user with `tenant.trip.incident.viewAny` but NOT `tenant.transport.viewAny` gets 403 at controller level but tab would have rendered. Two different permission keys guard the same feature — potential UX confusion. | 🟡 MEDIUM |
| BC-AUTH-GAP-03 | `status` action exists in $crud but blade uses `status` for button visibility | The `$crud` array includes `'status'`. So `tenant.trip.incident.status` IS a valid permission key created by `'trip.incident' => $crud`. This part actually works. However, the blade uses `@canany(['tenant.trip.incident.status'])` (single-element array) with incorrect closing directive (`@endcan` instead of `@endcanany`). See BC-BLADE-GAP-01. | 🟡 MEDIUM |
| BC-AUTH-GAP-04 | `tenant.trip.incident.*` part of `trip.incident` group, not fully documented | `permissionslist.php` line 324: `'trip.incident' => $crud` under `// begin::Transport Trip Management here`. This creates permissions like `tenant.trip.incident.create`, `tenant.trip.incident.view`, `tenant.trip.incident.update`, `tenant.trip.incident.delete`, `tenant.trip.incident.restore`, `tenant.trip.incident.forceDelete`. None of these are used by any controller or blade because incidents have NO dedicated CRUD. The permission group is defined but underutilized. | 🟢 LOW |
| BC-AUTH-GAP-05 | Policy `TransportTripIncidentPolicy` defines methods unused by controllers | Policy defines: `viewAny`, `view`, `status`, `create`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print`, `report`, `resolve`, `escalate`, `viewReports`, `generateReport`. Controller only uses `Gate::authorize('tenant.trip.incident.resolve')`. Methods `escalate`, `viewReports`, `generateReport`, `report`, `import`, `export`, `print` are defined but never called by any controller. This is dead code in the policy. | 🟡 MEDIUM |
| BC-AUTH-GAP-06 | `resolve` permission works only via super_admin bypass | Since `resolve` is not in `$crud`, `tenant.trip.incident.resolve` does NOT exist as a real DB permission. The only way `Gate::authorize('tenant.trip.incident.resolve')` passes is if the user is a super_admin (via `Gate::before()` check in AuthServiceProvider). Non-super-admin users will ALWAYS get 403 on resolve regardless of role configuration. | 🔴 CRITICAL |
| BC-AUTH-GAP-07 | `tenant.trip-management.*` in TripMgmtPolicy does NOT exist in permissionslist.php | `TripMgmtPolicy` uses `tenant.trip-management.viewAny` etc. Permission group `trip-management` does NOT exist in `permissionslist.php`. This policy is effectively dead — the controller never uses policy-based gates and the permission strings in the policy will never match anything. | 🔴 CRITICAL |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Incident created via stopAction emergency | TptTripIncidents created with incident_type=0, severity='MEDIUM', status=0, description from request->remark, raised_by=driver_id from routeScheduler, raised_at=now() |
| BC-BIZ-02 | Resolve incident with status=0 (OPEN) | status=1, resolved_at=now(), resolved_by=auth()->id(); redirect with success |
| BC-BIZ-03 | Resolve already-resolved incident (status=1) | Redirect back with warning 'Incident already resolved.' |
| BC-BIZ-04 | Model auto-sets raised_at on create | In booted() creating: if raised_at not set, defaults to now() |
| BC-BIZ-05 | Activity log on resolve | `activityLog($incident, 'Toggled', ['message' => 'Incident status updated.', 'performed_by' => Auth::user()->name])` |

### 5.3b Business Logic — Deep Dive (BC-BIZ-DEEP entries)

| BC-ID-DEEP | Condition | Code Location | Actual Code | Expected vs Actual Analysis |
|-----------|-----------|---------------|-------------|---------------------------|
| BC-BIZ-DEEP-01 | Incident creation via stopAction emergency | TripController.php:277-296 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-02 | No activityLog on incident creation | TripController.php:277-296 (case 'emergency') | [Query/Code Removed] | ❌ **GAP**: Unlike resolve (which calls activityLog at line 435-438), the emergency action does NOT log incident creation. This means incident creation is invisible in the activity log. Activity is inconsistent between creation (no log) and resolution (logged). |
| BC-BIZ-DEEP-03 | Resolve activityLog uses 'Toggled' event | TripMgmtController.php:435-438 | `activityLog($incident, 'Toggled', ['message' => 'Incident status updated.', 'performed_by' => Auth::user()->name])` | ❌ **GAP**: The event name 'Toggled' is semantically incorrect for a resolve action. 'Toggled' implies toggling between states (like on/off switch), but resolve is a forward-only state transition (OPEN→RESOLVED). The activity log will show 'Incident status updated' for both resolve operations. Moreover, the activityLog is called BEFORE the update() at line 440-444 — if the update fails, the activity log would have recorded an event for an operation that didn't complete. |
| BC-BIZ-DEEP-04 | activityLog order vs update order | TripMgmtController.php:435 vs 440 | activityLog() is called at lines 435-438, THEN update() at lines 440-444. | ❌ **GAP**: activityLog is recorded BEFORE the actual DB update. If the update fails, the activity log will show 'Incident status updated' for an incident that never actually changed status. Standard practice is to perform the DB mutation FIRST, then log after success. |
| BC-BIZ-DEEP-05 | Double-resolve prevention check | TripMgmtController.php:430-432 | `if ($incident->status == 1) { return redirect()->back()->with('warning', 'Incident already resolved.'); }` | ✅ **WORKS**: Uses loose equality (`==`). Since status is INT UNSIGNED with values 0 or 1, loose vs strict equality doesn't matter here. Flash message is 'warning', which will show as yellow/orange alert. |
| BC-BIZ-DEEP-06 | Model booted() auto-sets raised_at | TptTripIncidents.php:140-147 | `static::creating(function ($model) { if (!$model->raised_at) { $model->raised_at = now(); } });` | ✅ **WORKS**: However, note that stopAction already passes `raised_at => $now` explicitly (line 292), so the booted() fallback is never triggered for the primary creation path. The fallback only matters if incidents are created programmatically without raised_at. |
| BC-BIZ-DEEP-07 | Missing `scopeHighSeverity` constant | TptTripIncidents.php:133-135 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-08 | scopeOpen uses resolved_at check | TptTripIncidents.php:127-129 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-09 | Controller uses loose `status == 1` check | TripMgmtController.php:431 | `if ($incident->status == 1)` | ✅ **WORKS** for current implementation where status is INT. However, if status ever changes to string ENUM ('OPEN', 'RESOLVED'), this comparison would fail. The model uses `const STATUS = [0=>'OPEN', 1=>'RESOLVED']` indicating INT-based status is intentional. |
| BC-BIZ-DEEP-10 | Resolve send `flash('restored.Incident')` | TripMgmtController.php:446 | `return redirect()->back()->with('success', flash('restored.Incident'));` | ❌ **GAP**: The flash key is `flash('restored.Incident')` but the action is a RESOLVE, not a RESTORE. The flash message will display a text like "Incident restored successfully" because it uses the `restored` locale key. This is misleading — the incident was resolved, not restored from trash. Should use `flash('resolved.Incident')` or similar. However, this depends on whether the `flash()` helper has a `resolved.Incident` key defined in translation files. |
| BC-BIZ-DEEP-11 | raised_by stores driver_id from routeScheduler | TripController.php:185, 291 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-12 | severity is hardcoded to 'MEDIUM' | TripController.php:293 | `'severity' => 'MEDIUM'` | ❌ **GAP**: All incidents created via stopAction emergency are hardcoded to MEDIUM severity regardless of the actual emergency situation. There is no way for the driver or user to specify severity when triggering emergency. This means the severity filter in the blade (which shows HIGH/MEDIUM/LOW) will always show only MEDIUM incidents from the automatic creation path. If incidents could be created via other means (seeder, API, etc.) with different severities, those would appear, but the primary creation path always produces MEDIUM. |
| BC-BIZ-DEEP-13 | incident_type is hardcoded to 0 | TripController.php:288 | `'incident_type' => 0` | ❌ **GAP**: All incidents via stopAction emergency are created with `incident_type=0` (Stop Emergency). Other types (1=VehicleBreakdown, 2=Accident, 3=RouteBlocked) can never be created via the stopAction flow. If a vehicle breaks down, the driver triggers emergency and it's logged as 'Stop Emergency' rather than 'Vehicle Breakdown'. The incident_type filter in the blade (which shows all 4 types) will only ever show type 0 incidents from the automatic path. |
| BC-BIZ-DEEP-14 | No trip_id validation in incident creation | TripController.php:286 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-15 | Resolve route is GET, not POST | Route (web.php:56) | `Route::get('trip-incident/{id}/resolve', ...)` | ❌ **GAP**: Resolving an incident is a state-mutating operation (changes DB). Using GET violates HTTP specification (RFC 7231 Section 4.3.1 — GET requests should be safe and idempotent). Additionally: (1) No CSRF protection on GET, (2) Browser prefetch could accidentally trigger resolve, (3) Caching layers may cache the redirect response. The blade button is an `<a>` tag (line 122: `<a href="{{ ... }}">`) which makes a GET request when clicked (even with JS confirm). Should be a `<form>` with POST method or use a POST route with proper CSRF token. |
| BC-BIZ-DEEP-16 | resolveIncident has no validation for $id | TripMgmtController.php:428 | `$incident = TptTripIncidents::findOrFail($id);` | ✅ **WORKS**: findOrFail throws ModelNotFoundException if incident doesn't exist, which Laravel converts to 404. |

### 5.4 Model Relationships — `TptTripIncidents`

| BC ID | Relationship | Type | Foreign Key | Analysis |
|-------|-------------|------|-------------|----------|
| BC-REL-01 | trip() | BelongsTo TptTrip | trip_id | ✅ Exists in both model and DDL. ON DELETE CASCADE. |
| BC-REL-02 | raisedByUser() | BelongsTo User | raised_by | ✅ Duplicate of raisedBy() but with different method name. Both work. |
| BC-REL-03 | incidentType() | BelongsTo TptIncidentType | incident_type | ❌ **MODEL DOES NOT EXIST**: `TptIncidentType` class not found in codebase. Using this relationship will throw `Class "Modules\Transport\Models\TptIncidentType" not found`. |
| BC-REL-04 | statusMaster() | BelongsTo TptIncidentStatus | status | ❌ **MODEL DOES NOT EXIST**: `TptIncidentStatus` class not found in codebase. Using this relationship will throw ClassNotFoundException. |
| BC-REL-05 | raisedBy() | BelongsTo User | raised_by | ✅ Works. Duplicate of raisedByUser(). |
| BC-REL-06 | raisedTo() | BelongsTo User | raised_to | ❌ **COLUMN DOES NOT EXIST**: Migration has NO `raised_to` column. This relationship references a non-existent FK and will throw QueryException at runtime: `Column not found: 1054 Unknown column 'tpt_trip_incidents.raised_to'`. |
| BC-REL-07 | resolvedBy() | BelongsTo User | resolved_by | ✅ Works. FK exists in DDL with ON DELETE SET NULL. This is the only relationship eagerly loaded in incidentQuery(). |

### 5.4b Model Relationship — Dependency and Runtime Impact Table

| Relationship | Referenced Model | Referenced FK | Runtime Behavior If Accessed | Eager-Loaded? |
|-------------|-----------------|---------------|------------------------------|---------------|
| trip() | TptTrip | trip_id | ✅ Works | ❌ No |
| raisedByUser() | User (SysUsers) | raised_by | ✅ Works | ❌ No |
| incidentType() | TptIncidentType (MISSING) | incident_type | ❌ ClassNotFoundException | ❌ No |
| statusMaster() | TptIncidentStatus (MISSING) | status | ❌ ClassNotFoundException | ❌ No |
| raisedBy() | User (SysUsers) | raised_by | ✅ Works | ❌ No |
| raisedTo() | User (SysUsers) | raised_to (MISSING) | ❌ QueryException (column not found) | ❌ No |
| resolvedBy() | User (SysUsers) | resolved_by | ✅ Works | ✅ Yes |

### 5.5 Blade View Analysis — `trip-incidents/index.blade.php`

| BC-ID-BLADE | Location | Code | Analysis |
|------------|----------|------|----------|
| BC-BLADE-01 | Line 69-71 | `@canany(['tenant.trip.incident.status']) ... @endcan` | ❌ **GAP**: `@canany` is opened at line 69 but closed with `@endcan` at line 71 (not `@endcanany`). This is a directive mismatch. Blade may render this incorrectly depending on Blade compiler version. The `@canany` directive expects `@endcanany` as its closing tag. |
| BC-BLADE-02 | Line 119-130 | `@canany(['tenant.trip.incident.status']) ... @endcan` (second occurrence) | ❌ **GAP**: Same directive mismatch as BC-BLADE-01. The `<td>` action cell (lines 120-129) is wrapped in `@canany` but closed with `@endcan` at line 130. The `<th>` has the same issue at lines 69-71. |
| BC-BLADE-03 | Line 69-71 | `@canany(['tenant.trip.incident.status'])` | 🔴 **GAP**: `@canany` with a SINGLE permission in array is redundant — should be `@can('tenant.trip.incident.status')`. While `@canany` with one element works, it's semantically incorrect and misleading. |
| BC-BLADE-04 | Line 44 | `@include('transport::trip-incidents.js.js')` | ❌ **GAP**: The JS file is included OUTSIDE the `.tab-pane` div (which closes at line 148). The JS include at line 151 is after the closing `</div>` at line 148. It's also outside the layout's `.container-fluid` structure (but the master layout wraps everything). The placement is unconventional — JS includes are normally in a `@push('scripts')` section or at the bottom of `x-backend.layouts.app`, not scattered after HTML elements. |
| BC-BLADE-05 | Lines 14-19 | `@foreach(\Modules\Transport\Models\TptTripIncidents::TYPE as $key => $label)` | ❌ **GAP**: The blade directly references the Model class in the template to populate the type dropdown. This couples the view to the model's constant structure. If the TYPE constant changes or is removed, this blade will break. Standard practice is to pass the types from the controller. |
| BC-BLADE-06 | Lines 8-54 | Filter form uses `<form method="GET">` | ✅ **WORKS**: GET form correctly appends query parameters including `tab=trip_incidents` (hidden input at line 9). The Clear button (line 49) correctly routes back to the index with the tab parameter. |
| BC-BLADE-07 | Line 145 | `{{ $incidentData->withQueryString()->links() }}` | ❌ **GAP**: Uses `->withQueryString()` but does NOT append `['tab' => 'trip_incidents']` specifically. The `->withQueryString()` passes ALL current query parameters, which does include `tab` from the URL. However, this is fragile — if pagination is performed outside the valid tab context, it could lose the tab parameter. Other tab partials in this codebase use `->appends(['tab' => 'trip_incidents'])` explicitly. |
| BC-BLADE-08 | Line 122 | Resolve URL: `route('transport.trip.incident.resolve', $incident->id)` | ✅ ✅ **Confirmed**: Route exists at web.php:56 as `trip.incident.resolve`. This generates URL `/transport/trip-incident/{id}/resolve`. The route name must be used with the `transport.` prefix (i.e., `transport.trip.incident.resolve`) per Laravel route naming convention with route groups. |
| BC-BLADE-09 | Lines 69, 119 | Permission `tenant.trip.incident.status` used for action column visibility | ✅ **WORKS** (if permission exists): The blade checks `tenant.trip.incident.status` (which IS in `$crud`, so it works). However, the button action (resolve) actually requires `tenant.trip.incident.resolve` permission (the controller gate). This creates a UX inconsistency: a user could see the Resolve button (via `status` permission) but get 403 when clicking it (because `resolve` permission doesn't exist in permissionslist.php). See BC-AUTH-GAP-01. |
| BC-BLADE-10 | Line 48 | `@if(request()->anyFilled(['incident_type', 'status', 'date_range']))` | ✅ **WORKS**: Correctly uses `anyFilled()` helper to check if any filter is active before showing the Clear button. |

### 5.6 Route Analysis

| BC-ID-ROUTE | Route | Method | Controller | Name | Analysis |
|------------|-------|--------|-----------|------|----------|
| BC-ROUTE-01 | `transport/trip-incident/{id}/resolve` | GET | `TripMgmtController@resolveIncident` | `trip.incident.resolve` | ❌ **GAP**: GET used for DB mutation. See BC-BIZ-DEEP-15. |
| BC-ROUTE-02 | `transport/trip-management` | GET | `TripMgmtController@index` | Auto (resource) | ✅ Works. Route::resource('trip-management', TripMgmtController::class) at web.php:53 generates standard resource routes. |
| BC-ROUTE-03 | `transport/trip/stop-action` | POST | `TripController@stopAction` | `trip.stop-action` | ✅ POST used for data creation. Correct HTTP method for mutation. |

### 5.6b Route File — Complete Route Table

| # | URI | Method | Controller@Method | Name | Notes |
|---|-----|--------|-------------------|------|-------|
| 1 | `transport/trip-management` | GET | TripMgmtController@index | trip-management.index | Resource route — lists all tabs |
| 2 | `transport/trip-management/create` | GET | TripMgmtController@create | trip-management.create | Resource route — unused (no view) |
| 3 | `transport/trip-management` | POST | TripMgmtController@store | trip-management.store | Resource route — empty method |
| 4 | `transport/trip-management/{trip_management}` | GET | TripMgmtController@show | trip-management.show | Resource route — returns generic view |
| 5 | `transport/trip-management/{trip_management}/edit` | GET | TripMgmtController@edit | trip-management.edit | Resource route — returns generic view |
| 6 | `transport/trip-management/{trip_management}` | PUT/PATCH | TripMgmtController@update | trip-management.update | Resource route — empty method |
| 7 | `transport/trip-management/{trip_management}` | DELETE | TripMgmtController@destroy | trip-management.destroy | Resource route — empty method |
| 8 | `transport/trip-incident/{id}/resolve` | GET | TripMgmtController@resolveIncident | trip.incident.resolve | Custom route — incident resolve |

### 5.7 Policy Analysis — `TransportTripIncidentPolicy`

| Policy Method | Permission String | Called By Controller? | Used In Blade? | Status |
|-------------|-------------------|---------------------|----------------|--------|
| viewAny(User) | tenant.trip.incident.viewAny | ❌ (uses Gate::authorize string) | ✅ tab and index include | Policy-defined, controller uses Gate::authorize directly |
| view(User, TptTripIncidents) | tenant.trip.incident.view | ❌ | ❌ | Dead code |
| status(User, TptTripIncidents) | tenant.trip.incident.status | ❌ | ✅ blade @canany | Dead code in policy, active in blade |
| create(User) | tenant.trip.incident.create | ❌ no create route | ❌ | Dead code |
| update(User, TptTripIncidents) | tenant.trip.incident.update | ❌ no update route | ❌ | Dead code |
| delete(User, TptTripIncidents) | tenant.trip.incident.delete | ❌ no delete route | ❌ | Dead code |
| restore(User, TptTripIncidents) | tenant.trip.incident.restore | ❌ no restore route | ❌ | Dead code |
| forceDelete(User, TptTripIncidents) | tenant.trip.incident.forceDelete | ❌ no forceDelete route | ❌ | Dead code |
| import(User) | tenant.trip.incident.import | ❌ | ❌ | Dead code |
| export(User) | tenant.trip.incident.export | ❌ | ❌ | Dead code |
| print(User) | tenant.trip.incident.print | ❌ | ❌ | Dead code |
| report(User) | tenant.trip.incident.report | ❌ | ❌ | Dead code |
| resolve(User, TptTripIncidents) | tenant.trip.incident.resolve | ✅ (Gate::authorize) | ✅ resolve button route | Active — but permission not in permissionslist.php |
| escalate(User, TptTripIncidents) | tenant.trip.incident.escalate | ❌ | ❌ | Dead code — not a real permission |
| viewReports(User) | tenant.trip.incident.viewReports | ❌ | ❌ | Dead code — not a real permission |
| generateReport(User) | tenant.trip.incident.generateReport | ❌ | ❌ | Dead code — not a real permission |

### 5.8 Route Model Binding & URL Generation

| Aspect | Details |
|--------|---------|
| Resolve URL pattern | `/transport/trip-incident/{id}/resolve` — uses explicit `$id` parameter, NO implicit route model binding |
| Controller signature | `resolveIncident($id)` — receives raw ID, calls `TptTripIncidents::findOrFail($id)` |
| No implicit binding | Laravel convention: `{tripIncident}` (model variable) would trigger implicit binding. But route uses `{id}`, so no auto-resolution. This is intentional to avoid coupling. |
| Route name prefix | Route is defined inside a `/transport` prefix group (from the parent route file), so final URL is `/transport/trip-incident/{id}/resolve` |
| Blade route generation | `route('transport.trip.incident.resolve', $incident->id)` — generates absolute URL with the incident ID |

### 5.9 JavaScript & Frontend Analysis

| BC-ID-JS | Location | Code | Analysis |
|---------|----------|------|----------|
| BC-JS-01 | js.blade.php:5-25 | SweetAlert2 confirmation on `.resolve-incident` | ❌ **GAP**: The JS adds click handler that prevents default and shows confirmation dialog. On confirmation, it sets `window.location.href = url` — making a GET request. Combined with the GET route (see BC-ROUTE-01), this means the resolve action is confirmed via Swal then executed as a GET navigation. No fetch/AJAX call is used. If the resolve fails (403, 404, double-resolve), the browser navigates to the redirect response URL. This is a suboptimal UX pattern. |
| BC-JS-02 | js.blade.php:39-63 | Litepicker date range initialization | ❌ **GAP**: The JS references `$(this).closest('form').find('.start_date')` and `.end_date` (lines 55-56), but the blade filter form does NOT contain any elements with class `start_date` or `end_date`. These jQuery selectors will return empty results. The date range is sent as a single `date_range` string via the Litepicker element itself, so the hidden inputs are not strictly needed. However, this is dead JS code that will silently fail (no error since jQuery's `val()` on empty set is a no-op). |
| BC-JS-03 | js.blade.php:1 | CDN script: `sweetalert2@11` | ✅ **WORKS**: Loads SweetAlert2 from CDN. However, requires internet connectivity. If CDN is unreachable, the confirmation dialog will not render and the resolve button will behave as a normal `<a>` link (navigating directly). |
| BC-JS-04 | js.blade.php:29 | CDN script: `litepicker` | ✅ **WORKS**: Loads Litepicker from CDN. Same internet dependency issue. |

---

## 6. Test Case List

### 6.0 Code Trace Test Cases (CODE-TRACE)

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CT-01 | CODE-TRACE | P1 | Trace: TripMgmtController@index → incidentQuery | Full code path from index() to incidentData variable to view compact | incidentQuery called with $request, returns query builder with ->with('resolvedBy')->orderByDesc('incident_time'), paginate(10) applied, compact('incidentData') passed to view | — | — | ◌ |
| TC-CT-02 | CODE-TRACE | P1 | Trace: TripController@stopAction → emergency | Full code path from stopAction reception to TptTripIncidents::create | stopAction validates request, matches action='emergency', creates incident with hardcoded values: incident_type=0, severity='MEDIUM', raised_by=driver_id, returns JSON success | — | — | ◌ |
| TC-CT-03 | CODE-TRACE | P1 | Trace: TripMgmtController@resolveIncident | Full code path from route dispatch to redirect | Gate::authorize('tenant.trip.incident.resolve'), findOrFail($id), double-resolve check, activityLog, update(status=1, resolved_at, resolved_by), redirect back | — | — | ◌ |
| TC-CT-04 | CODE-TRACE | P1 | Trace: Blade rendering chain | Hub tab → partial → JS inclusion | tripmanagement.blade.php @can → @include('transport::trip-incidents.index') → renders tab-pane with filter form + table + pagination → @include('transport::trip-incidents.js.js') for JS | — | — | ◌ |
| TC-CT-05 | CODE-TRACE | P1 | Trace: Route dispatch for resolve | Browser GET → web.php → controller method | Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident']) → Laravel dispatches to resolveIncident($id) → Gate::authorize → findOrFail → update → redirect | — | — | ◌ |

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Incident Tab Loads | `/transport/trip-management?tab=trip_incidents` shows incident grid with filters (requires `tenant.transport.viewAny` + `tenant.trip.incident.viewAny`) | — | — | ⬜ |
| TC-P02 | Incident Created via Emergency Action | POST `/transport/trip/stop-action` with action=emergency, remark="Flat tire" → incident created with incident_type=0, severity=MEDIUM, raised_by=driver_id | — | — | ⬜ |
| TC-P03 | View Incident in List | Incident appears in grid with Incident Time, Type, Severity, Description, Status, Resolved At, Resolved By, Action columns | — | — | ⬜ |
| TC-P04 | Resolve Open Incident | GET `/transport/trip-incident/{id}/resolve` where status=0 → status=1, resolved_at set, resolved_by set | — | — | ⬜ |
| TC-P05 | Filter by Incident Type | Select type dropdown → matching incidents | — | — | ⬜ |
| TC-P06 | Filter by Status (OPEN / RESOLVED) | Select status → matching incidents | — | — | ⬜ |
| TC-P07 | Filter by Date Range | Enter date range → incidents within that range | — | — | ⬜ |
| TC-P08 | Empty State — No Incidents | "No incidents found" message displayed | — | — | ⬜ |
| TC-P09 | Pagination | 11+ incidents → pagination appears with page 2 showing remaining incidents | — | — | ⬜ |
| TC-P10 | Resolve via SweetAlert Confirmation | Click Resolve → Swal dialog → Confirm → incident resolved | — | — | ⬜ |
| TC-P11 | Severity Badge Styling | LOW=bg-secondary, MEDIUM=bg-warning, HIGH=bg-danger | — | — | ⬜ |
| TC-P12 | Status Badge Styling | OPEN=bg-danger badge, RESOLVED=bg-success badge | — | — | ⬜ |
| TC-P13 | Resolved By Shows Name | After resolve, resolved_by column shows user name on next page load | — | — | ⬜ |
| TC-P14 | Resolved At Shows Timestamp | After resolve, resolved_at column shows formatted datetime on next page load | — | — | ⬜ |
| TC-P15 | Multiple Filters Combined | incident_type + status + date_range all applied simultaneously → intersection of conditions | — | — | ⬜ |
| TC-P16 | Filter Clear Resets Grid | Click Clear after applying filters → all filters cleared, full dataset shown | — | — | ⬜ |
| TC-P17 | Trip Management Page Loads Without Tab Parameter | `/transport/trip-management` (no ?tab=) → default tab loads (first tab in hub) | — | — | ⬜ |
| TC-P18 | Incident Loop Count Shows Correctly | `$loop->iteration` increments per page correctly | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Resolve Already-Resolved Incident | GET `/transport/trip-incident/{id}/resolve` for status=1 incident → back with warning 'already resolved' | — | — | ⬜ |
| TC-N02 | Resolve Non-Existent Incident | GET `/transport/trip-incident/99999/resolve` → findOrFail → 404 | — | — | ⬜ |
| TC-N03 | Permission 403 — No incident.resolve | User without `tenant.trip.incident.resolve` → 403 on GET resolve | — | — | ⬜ |
| TC-N04 | Guest Access | Redirect to `/login` | — | — | ⬜ |
| TC-N05 | Emergency without remark | stopAction creates incident with description=null | — | — | ⬜ |
| TC-N06 | Permission 403 — No transport.viewAny (page access) | GET `/transport/trip-management` without `tenant.transport.viewAny` → 403 | — | — | ⬜ |
| TC-N07 | Tab Hidden — No trip.incident.viewAny | Has `tenant.transport.viewAny` but NOT `tenant.trip.incident.viewAny` → page loads but Trip Incidents tab not visible | — | — | ⬜ |
| TC-N08 | Permission 403 — No resolve permission but has status permission | User sees Resolve button (via `tenant.trip.incident.status` blade check) but gets 403 when clicking (no `tenant.trip.incident.resolve`) | — | — | ⬜ |
| TC-N09 | Invalid Date Range Format | date_range with wrong format → parse error → 500 (no try/catch in incidentQuery) | — | — | ⬜ |
| TC-N10 | Trip Deletion While Incidents Exist | Delete trip → incidents cascade deleted (DDL CASCADE) | — | — | ⬜ |
| TC-N11 | Negative or Zero ID in Resolve URL | `/transport/trip-incident/-1/resolve` or `/transport/trip-incident/0/resolve` → findOrFail throws ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N12 | Non-integer ID in Resolve URL | [Query/Code Removed] | — | — | ⬜ |
| TC-N13 | Date Range with Only Start Date | date_range="2026-06-01" (no " - " separator) → condition `str_contains($range, ' - ')` is false → filter silently skipped → shows all records | — | — | ⬜ |
| TC-N14 | Empty Incident Type Filter | incident_type="" → `filled('incident_type')` is false → filter not applied | — | — | ⬜ |
| TC-N15 | status=2 (Invalid Status Value) | Filter by status=2 → where('status', 2) returns empty set since no incident has status=2 | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Trip Deletion — Incidents Cascade | DDL CASCADE → related incidents auto-deleted | — | — | ⬜ |
| TC-D02 | B | RaisedBy/ResolvedBy User — SET NULL | User deletion → raised_by/resolved_by becomes NULL | — | — | ⬜ |

### 6.3b Exploration / Deep-Dive Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-EX-01 | EXPLORE | P2 | scopeHighSeverity returns empty due to undefined constant | Call TptTripIncidents::highSeverity()->get() → executes `where('severity', null)` → returns empty collection even if HIGH severity records exist | — | — | ◌ |
| TC-EX-02 | EXPLORE | P2 | scopeOpen returns incidents with resolved_at=null but status=1 | Set status=1, resolved_at=null → scopeOpen() includes it incorrectly | — | — | ◌ |
| TC-EX-03 | EXPLORE | P3 | raisedTo() relationship at runtime | Access `$incident->raisedTo` → QueryException: Column not found 'raised_to' | — | — | ◌ |
| TC-EX-04 | EXPLORE | P3 | incidentType() relationship at runtime | Access `$incident->incidentType` → ClassNotFoundException: TptIncidentType | — | — | ◌ |
| TC-EX-05 | EXPLORE | P3 | statusMaster() relationship at runtime | Access `$incident->statusMaster` → ClassNotFoundException: TptIncidentStatus | — | — | ◌ |
| TC-EX-06 | EXPLORE | P2 | Non-super-admin resolve attempt | User with roles but NOT super_admin calls resolve → 403 because `tenant.trip.incident.resolve` not in permissionslist.php | — | — | ◌ |
| TC-EX-07 | EXPLORE | P2 | activityLog called before update in resolveIncident | If update() throws, activityLog already recorded → audit trail shows event that didn't complete | — | — | ◌ |
| TC-EX-08 | EXPLORE | P3 | Flash message text for resolve | `flash('restored.Incident')` displays incorrect verb (shows 'restored' instead of 'resolved') | — | — | ◌ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() in resolveIncident | `Gate::authorize('tenant.trip.incident.resolve')` present | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Double-resolve prevention | `if ($incident->status == 1)` check before update | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog on resolve | Logged with 'Toggled' event | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — No CRUD (create/edit/destroy) | Only listing via TripMgmtController and one resolve action | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — No way to edit incident details | No route/method for updating description, severity, etc. | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — No way to delete incidents | No destroy/forceDelete/trash operations | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — Table Name | `protected $table = 'tpt_trip_incidents'` | — | — | ◌ |
| TC-CR08 | CR | P1 | Model — Fillable Fields | 12 fillable fields: trip_id, incident_time, incident_type, severity, latitude, longitude, description, status, raised_by, raised_at, resolved_at, resolved_by | — | — | ◌ |
| TC-CR09 | CR | P1 | Model — Constants Defined | TYPE[0..3], STATUS[0,1], SEVERITY[LOW/MEDIUM/HIGH] | — | — | ◌ |
| TC-CR10 | CR | P1 | Model — Relationships | trip, raisedByUser, incidentType, statusMaster, raisedBy, raisedTo, resolvedBy — 7 relationships | — | — | ◌ |
| TC-CR11 | CR | P1 | Model — Accessors | `getIncidentTypeLabelAttribute()`, `getStatusLabelAttribute()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Model — Scopes | `scopeOpen()`: whereNull('resolved_at'); `scopeHighSeverity()`: where('severity', self::SEVERITY_HIGH) — NOTE: SEVERITY_HIGH constant is NOT defined (uses array SEVERITY, not individual constants) — code bug | — | — | ◌ |
| TC-CR13 | CR | P1 | DDL — FK Constraints | trip_id CASCADE, raised_by SET NULL, resolved_by SET NULL | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — resolveIncident | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])` — GET for state mutation (route prefix `transport` → URL `/transport/trip-incident/{id}/resolve`) | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — GET used for mutation (resolve) | Resolving an incident via GET violates HTTP spec | — | — | ◌ |
| TC-CR16 | CR | P1 | Gap — No incident_type validation in stopAction | Always creates incident_type=0 regardless of actual incident type | — | — | ◌ |
| TC-CR17 | CR | P1 | Gap — No incident soft delete/restore/forceDelete | SoftDeletes trait exists but no routes or methods | — | — | ◌ |
| TC-CR18 | CR | P1 | Gap — No dedicated IncidentController | All incident logic mixed into TripMgmtController and TripController | — | — | ◌ |
| TC-CR19 | CR | P1 | TripMgmtController — incidentQuery filters | incident_type, status, date_range filters | — | — | ◌ |
| TC-CR20 | CR | P1 | Gap — No activityLog on incident creation | stopAction('emergency') creates incident without calling activityLog | — | — | ◌ |
| TC-CR21 | CR | P1 | Gate mismatch — controller vs blade permission | Controller index() uses `tenant.transport.viewAny`, but blade tab uses `tenant.trip.incident.viewAny` — two different permission keys guard access | — | — | ◌ |
| TC-CR22 | CR | P1 | `resolve` action NOT in permissionslist.php $crud | `$crud` array lacks `resolve` action, so `tenant.trip.incident.resolve` will never match a real permission (only works via super_admin bypass) | — | — | ◌ |
| TC-CR23 | CR | P1 | scopeHighSeverity references undefined constant | `self::SEVERITY_HIGH` is not defined (SEVERITY is an array constant `self::SEVERITY['HIGH']`) | — | — | ◌ |
| TC-CR24 | CR | P1 | raisedTo() relationship references non-existent column | Model has `raisedTo()` → `raised_to` FK, but migration has NO `raised_to` column | — | — | ◌ |
| TC-CR25 | CR | P1 | incidentType() / statusMaster() reference non-existent models | `TptIncidentType` and `TptIncidentStatus` models do not exist in codebase | — | — | ◌ |
| TC-CR26 | CR | P1 | Blade — @canany/@endcan directive mismatch | Blade line 69 uses @canany but closes with @endcan (line 71) instead of @endcanany | — | — | ◌ |
| TC-CR27 | CR | P1 | Blade — @canany with single element | `@canany(['tenant.trip.incident.status'])` should be `@can('tenant.trip.incident.status')` | — | — | ◌ |
| TC-CR28 | CR | P2 | activityLog order — logged before DB update | If update() exceptions, activityLog still records 'Incident status updated' | — | — | ◌ |
| TC-CR29 | CR | P2 | activityLog event name — 'Toggled' for resolve | 'Toggled' is semantically incorrect for a resolve (forward-only) operation | — | — | ◌ |
| TC-CR30 | CR | P2 | Flash message — 'restored' instead of 'resolved' | `flash('restored.Incident')` uses locale key for restore, not resolve | — | — | ◌ |
| TC-CR31 | CR | P2 | severity hardcoded to 'MEDIUM' in stopAction | All emergency incidents have severity=MEDIUM, no way to specify LOW/HIGH | — | — | ◌ |
| TC-CR32 | CR | P2 | incident_type hardcoded to 0 in stopAction | All emergency incidents have incident_type=0 (StopEmergency), cannot create VehicleBreakdown/Accident/RouteBlocked | — | — | ◌ |
| TC-CR33 | CR | P2 | raised_by stores driver_id not auth user | `raised_by=optional($trip->routeScheduler)->driver_id` — non-obvious behavior | — | — | ◌ |
| TC-CR34 | CR | P2 | Model class referenced directly in blade | Line 14: `\Modules\Transport\Models\TptTripIncidents::TYPE` — view coupled to model constant | — | — | ◌ |
| TC-CR35 | CR | P2 | JS references non-existent .start_date/.end_date elements | js.blade.php lines 55-56 jQuery selectors return empty set | — | — | ◌ |
| TC-CR36 | CR | P2 | Pagination uses withQueryString() not appends(['tab']) | Tab context may be lost if query string is manipulated | — | — | ◌ |
| TC-CR37 | CR | P2 | Policy defines 16 methods, only 1 used by controller | 15 of 16 policy methods are dead code | — | — | ◌ |
| TC-CR38 | CR | P2 | TripMgmtPolicy references non-existent permission group | Uses `tenant.trip-management.*` which is NOT in permissionslist.php | — | — | ◌ |
| TC-CR39 | CR | P2 | No DB indexes on filter columns | incident_type, status, incident_time have no indexes | — | — | ◌ |
| TC-CR40 | CR | P2 | DDL enum order differs from model constant order | DDL: `['HIGH','LOW','MEDIUM']`, Model: `['LOW'=>'LOW', 'MEDIUM'=>'MEDIUM', 'HIGH'=>'HIGH']` | — | — | ◌ |
| TC-CR41 | CR | P2 | scopeOpen uses resolved_at check not status check | Should check status=0, not resolved_at IS NULL | — | — | ◌ |
| TC-CR42 | CR | P2 | No incident_time fallback in model | DDL: incident_time NOT NULL, Model: no default/booted fallback. If created programmatically without incident_time → DB error | — | — | ◌ |
| TC-CR43 | CR | P2 | [Query/Code Removed] | Non-integer IDs may not properly 404 | — | — | ◌ |
| TC-CR44 | CR | P3 | Date range parsing has no try/catch | [Query/Code Removed] | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Incident Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with permissions: `tenant.transport.viewAny`, `tenant.trip.incident.viewAny` | Dashboard/landing page loads |
| 2 | Navigate to `/transport/trip-management?tab=trip_incidents` | Page loads without 403 error |
| 3 | Inspect page for Trip Incidents tab | Tab is visible in the nav-tab bar with label "Trip Incidents" and icon `fa-triangle-exclamation` |
| 4 | Click the Trip Incidents tab | Tab pane becomes active (fade in + show class) |
| 5 | Inspect filter bar | Filter bar visible with: Incident Type dropdown, Status dropdown, Date Range picker, Filter button |
| 6 | Inspect incident grid | Table visible with columns: #, Incident Time, Type, Severity, Description, Status, Resolved At, Resolved By, Action |
| 7 | Verify table header classes | `<thead class="table-light">` present |

### TC-P02: Incident Created via Emergency Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Start a trip via stopAction start_trip | Trip status='Ongoing' |
| 2 | POST `/transport/trip/stop-action` with action=emergency, id=existing_stop_detail_id, remark="Flat tire encountered" | JSON success |
| 3 | [Query/Code Removed] | Record exists with incident_type=0, severity='MEDIUM', description='Flat tire encountered', status=0 |
| 4 | Navigate to Trip Incidents tab | Incident visible in grid with type='Stop Emergency', status='OPEN', severity='MEDIUM' |
| 5 | Verify raised_by in DB | `raised_by` = driver_id from routeScheduler (NOT auth user id) |
| 6 | Verify raised_at in DB | `raised_at` = current timestamp (within tolerance of test execution) |
| 7 | Verify incident_time in DB | `incident_time` matches the timestamp of the stopAction call |
| 8 | Check activity_log table | No activity_log entry for incident creation (BC-BIZ-DEEP-02 — confirmed gap) |

### TC-P03: View Incident in List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a test incident with incident_type=1, severity='HIGH', status=0 (via DB seeder or factory) | Incident data prepared |
| 2 | Navigate to Trip Incidents tab | Incident appears in grid |
| 3 | Verify Incident Time column | Shows formatted datetime: `d M Y, h:i A` (e.g., "22 Jul 2026, 10:30 AM") |
| 4 | Verify Type column | Shows `incident_type_label` (e.g., "Vehicle Breakdown") wrapped in `badge bg-info` |
| 5 | Verify Severity column | Shows severity text in color-coded badge: HIGH=bg-danger, MEDIUM=bg-warning, LOW=bg-secondary |
| 6 | Verify Description column | Shows description text |
| 7 | Verify Status column | Shows `status_label` ("OPEN" or "RESOLVED") in badge: OPEN=bg-danger, RESOLVED=bg-success |
| 8 | Verify Resolved At column | Shows "-" for unresolved, formatted datetime for resolved |
| 9 | Verify Resolved By column | Shows "-" for unresolved, user name for resolved |
| 10 | Verify Action column | For OPEN: Resolve button visible (if user has `tenant.trip.incident.status`). For RESOLVED: "Completed" text shown |

### TC-P04: Resolve Open Incident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a test incident with status=0, resolved_at=NULL, resolved_by=NULL | Open incident available |
| 2 | Verify user has `tenant.trip.incident.resolve` permission | Gate passes (note: may need super_admin due to BC-AUTH-GAP-06) |
| 3 | GET `/transport/trip-incident/{id}/resolve` (or click Resolve button + confirm in Swal) | Redirect back with 'success' flash message |
| 4 | DB check: `SELECT status, resolved_at, resolved_by FROM tpt_trip_incidents WHERE id={id}` | status=1, resolved_at=not null (current timestamp), resolved_by=auth()->id() |
| 5 | Navigate to Trip Incidents tab | Incident now shows status='RESOLVED' (green badge), Resolved At column shows timestamp, Resolved By column shows current user name |
| 6 | Action column now shows "Completed" text instead of Resolve button | Text is `<span class="text-muted">Completed</span>` |
| 7 | Check activity_log table | Entry exists with event='Toggled', message='Incident status updated.', performed_by=auth user name |

### TC-P05: Filter by Incident Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 incidents: incident_type=0 (StopEmergency), incident_type=1 (VehicleBreakdown), incident_type=2 (Accident) | Incidents with different types |
| 2 | Navigate to Trip Incidents tab | All 3 incidents visible |
| 3 | Select "Stop Emergency" (type=0) from Incident Type dropdown | Filter applied |
| 4 | Click Filter button | Only Stop Emergency type incident visible |
| 5 | Select "Vehicle Breakdown" (type=1) | Only Vehicle Breakdown incident visible |
| 6 | Select "All Types" | All 3 incidents visible again |
| 7 | Verify URL contains `incident_type` parameter | URL: `/transport/trip-management?tab=trip_incidents&incident_type=1` |

### TC-P06: Filter by Status (OPEN / RESOLVED)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 incidents: one OPEN (status=0), one RESOLVED (status=1) | Incidents in both states |
| 2 | Navigate to Trip Incidents tab | Both incidents visible |
| 3 | Select "OPEN" (status=0) from Status dropdown | Only OPEN incident visible |
| 4 | Select "RESOLVED" (status=1) from Status dropdown | Only RESOLVED incident visible |
| 5 | Select "All Status" | Both incidents visible |
| 6 | Verify URL contains status parameter | URL: `/transport/trip-management?tab=trip_incidents&status=0` |

### TC-P07: Filter by Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 incidents: incident_time=2026-06-01, 2026-06-15, 2026-07-01 | Incidents on different dates |
| 2 | Navigate to Trip Incidents tab | All 3 incidents visible |
| 3 | Use date range picker to select 2026-06-01 to 2026-06-20 | Filter applied |
| 4 | Click Filter button | Only incidents from June 1-20 visible (first 2) |
| 5 | Change date range to 2026-06-20 to 2026-07-05 | Only July 1 incident visible |
| 6 | Verify URL contains date_range parameter | URL: `/transport/trip-management?tab=trip_incidents&date_range=2026-06-01+-+2026-06-20` |
| 7 | Click Clear button | All incidents visible, date range cleared |

### TC-P08: Empty State — No Incidents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no incidents exist for any trip (truncate or work on fresh DB) | No incident records |
| 2 | Navigate to Trip Incidents tab | Table body shows: `<tr><td colspan="9" class="text-center text-muted py-3">No incidents found</td></tr>` |
| 3 | Verify pagination section | Pagination hidden (no pages when data empty) |

### TC-P09: Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 incidents (paginate(10) → should show 2 pages) | 12 incidents exist |
| 2 | Navigate to Trip Incidents tab | Page 1: 10 incidents visible, pagination controls at bottom |
| 3 | Click page 2 | Page 2: 2 incidents visible |
| 4 | Verify # column restarts at 1 on page 2 | `$loop->iteration` = 1 for first item on page 2 |
| 5 | Navigate back to page 1 | Page 1 shows fully again |

### TC-N01: Resolve Already-Resolved Incident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Resolve incident first time | GET resolves successfully; status=1 |
| 2 | Resolve same incident again | GET `/transport/trip-incident/{id}/resolve` |
| 3 | Check response | Redirect back with 'warning' flash: 'Incident already resolved.' |
| 4 | DB check | status remains 1; resolved_at unchanged |

### TC-N02: Resolve Non-Existent Incident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure incident with ID 99999 does NOT exist | No record |
| 2 | GET `/transport/trip-incident/99999/resolve` | `ModelNotFoundException` thrown by `findOrFail(99999)` |
| 3 | Check HTTP response | 404 Not Found returned |
| 4 | Check Laravel debug | If APP_DEBUG=true: ModelNotFoundException details shown. If APP_DEBUG=false: Generic 404 page. |

### TC-N03: Permission 403 — No incident.resolve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.trip.incident.resolve` (non-super_admin) | Auth as limited user |
| 2 | GET `/transport/trip-incident/{id}/resolve` | `Gate::authorize('tenant.trip.incident.resolve')` throws `AuthorizationException` |
| 3 | Check HTTP response | 403 Forbidden |
| 4 | Verify | Message: "This action is unauthorized." (default Laravel 403 message) |

### TC-N04: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout or use incognito session | Not authenticated |
| 2 | GET `/transport/trip-management?tab=trip_incidents` | Redirected to `/login` (Laravel auth middleware) |
| 3 | GET `/transport/trip-incident/1/resolve` | Redirected to `/login` |

### TC-N05: Emergency without remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/stop-action` with action=emergency, id=existing_stop_detail_id, NO remark field | JSON success |
| 2 | DB check: incident created | Incident exists with description=NULL |
| 3 | Navigate to Trip Incidents tab | Incident visible with empty Description column |

### TC-N06: Permission 403 — No transport.viewAny (page access)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.transport.viewAny` | Auth as limited user |
| 2 | GET `/transport/trip-management` | `Gate::authorize('tenant.transport.viewAny')` throws AuthorizationException |
| 3 | Check HTTP response | 403 Forbidden |

### TC-N07: Tab Hidden — No trip.incident.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` but WITHOUT `tenant.trip.incident.viewAny` | Auth with limited tab permissions |
| 2 | GET `/transport/trip-management` | Page loads, no 403 |
| 3 | Check tab navigation | Trip Incidents tab NOT visible in the nav-tab list |
| 4 | Inspect DOM for `trip_incidents-pane` | Partial NOT rendered (wrapped in `@can('tenant.trip.incident.viewAny')`) |
| 5 | Direct URL: GET `/transport/trip-management?tab=trip_incidents` | Tab parameter ignored (tab content not rendered, falls back to default tab) |

### TC-P10: Resolve via SweetAlert Confirmation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trip Incidents tab with at least one OPEN incident | Resolve button visible (green `btn btn-sm btn-success`) |
| 2 | Click Resolve button | SweetAlert2 dialog appears: title="Are you sure?", text="Do you want to mark this incident as resolved?", icon="warning", confirmButton="Yes, Resolve", cancelButton="Cancel" |
| 3 | Click Cancel | Dialog closes, no action taken |
| 4 | Click Resolve button again, then click "Yes, Resolve" | Browser navigates to `/transport/trip-incident/{id}/resolve` |
| 5 | Page reloads after redirect | Incident status updated to RESOLVED |

### TC-P11: Severity Badge Styling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 incidents with severity=LOW, MEDIUM, HIGH | Incidents with all severities |
| 2 | Navigate to Trip Incidents tab | 
| 3 | Check LOW severity badge | `class="badge bg-secondary"` — grey |
| 4 | Check MEDIUM severity badge | `class="badge bg-warning"` — yellow |
| 5 | Check HIGH severity badge | `class="badge bg-danger"` — red |

### TC-P15: Multiple Filters Combined

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create incidents with varied attributes: (type=0, status=0, date=2026-06-01), (type=0, status=1, date=2026-06-15), (type=1, status=0, date=2026-06-01) | Diverse dataset |
| 2 | Navigate to Trip Incidents tab | All records visible |
| 3 | Select incident_type=0, status=0, date_range=2026-05-01 - 2026-06-10 | Only first incident (type=0, OPEN, June 1) visible |
| 4 | Change date_range to 2026-06-10 - 2026-06-30 | Only second incident (type=0, RESOLVED, June 15) visible |
| 5 | Verify URL | Query params: `incident_type=0&status=0&date_range=2026-05-01+-+2026-06-10` |

### TC-P16: Filter Clear Resets Grid

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Apply incident_type=2, status=1 filter | URL has query params |
| 2 | Click Clear button (visible only when filters active) | Redirect to `/transport/trip-management?tab=trip_incidents` |
| 3 | Verify filters reset | All selector values back to default ("All Types", "All Status"), date range empty |
| 4 | Verify all records visible | Full dataset displayed |

### TC-CR15: Gap — GET used for mutation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `web.php` route | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])` — uses GET |
| 2 | Check CSRF protection | GET routes have no CSRF token requirement |
| 3 | Security implication | CSRF not required; browser prefetch could trigger resolve |
| 4 | Check `<a>` tag in blade | Line 122: `<a href="{{ route('transport.trip.incident.resolve', $incident->id) }}">` — standard anchor tag, makes GET request |
| 5 | Verify no `<form>` with POST | No POST form exists for resolve action |

### TC-CR20: Gap — No activityLog on incident creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TripController.php stopAction() | Lines 277-296 (case 'emergency') |
| 2 | [Query/Code Removed] | No activityLog call present after incident creation |
| 3 | Compare with resolveIncident() | resolveIncident() at line 435 calls activityLog — inconsistent |

### TC-CR22: Gap — resolve NOT in permissionslist.php $crud

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/permissionslist.php` | Read the file |
| 2 | Inspect `$crud` array (lines 13-31) | Array elements: create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve — NO `resolve` |
| 3 | Check `trip.incident` group (line 324) | `'trip.incident' => $crud` — expands to all $crud actions but NOT resolve |
| 4 | Verify no resolve-specific entry | No `'trip.incident.resolve' => ['resolve']` or similar override elsewhere in file |
| 5 | Conclude | Permission `tenant.trip.incident.resolve` does NOT exist in permissionslist.php → Role assignment UIs cannot assign this permission → Only super_admin bypass works |

### TC-CR23: Gap — scopeHighSeverity undefined constant

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TptTripIncidents.php | Read model file |
| 2 | Inspect SEVERITY constant (line 60-64) | `const SEVERITY = ['LOW' => 'LOW', 'MEDIUM' => 'MEDIUM', 'HIGH' => 'HIGH']` — array constant |
| 3 | Inspect scopeHighSeverity (line 132-135) | [Query/Code Removed] |
| 4 | Search for SEVERITY_HIGH definition | No separate `const SEVERITY_HIGH = ...` exists in the file |
| 5 | Conclude | `self::SEVERITY_HIGH` evaluates to `null` (undefined constant). `where('severity', null)` returns no records. |

### TC-CR24: Gap — raisedTo() references non-existent column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TptTripIncidents.php line 110-113 | `public function raisedTo() { return $this->belongsTo(User::class, 'raised_to'); }` |
| 2 | Open migration file 2026_06_16_140625 | Read columns — NO `raised_to` column exists |
| 3 | Check all columns in DDL (lines 15-35) | id, trip_id, incident_time, incident_type, severity, latitude, longitude, description, status, raised_at, resolved_at, created_at, updated_at, deleted_at — NO raised_to |
| 4 | Attempt to access `$incident->raisedTo` at runtime | `SQLSTATE[42S22]: Column not found: 1054 Unknown column 'raised_to' in 'field list'` |

### TC-CR25: Gap — incidentType() / statusMaster() reference non-existent models

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search for `TptIncidentType` class in codebase | File not found — class does not exist |
| 2 | Search for `TptIncidentStatus` class in codebase | File not found — class does not exist |
| 3 | Open TptTripIncidents.php line 92-95 | `incidentType()` → `belongsTo(TptIncidentType::class, 'incident_type')` |
| 4 | Runtime behavior when accessing incidentType() | `Class "Modules\Transport\Models\TptIncidentType" not found` → PHP Fatal Error |
| 5 | Open TptTripIncidents.php line 98-101 | `statusMaster()` → `belongsTo(TptIncidentStatus::class, 'status')` |
| 6 | Runtime behavior when accessing statusMaster() | `Class "Modules\Transport\Models\TptIncidentStatus" not found` → PHP Fatal Error |
| 7 | Conclude | These relationships will CRASH if accessed at runtime. The blade does NOT access them currently (`$incident->incident_type_label` uses accessor, not relationship), so they're dormant bugs. |

### TC-CR26: Blade @canany/@endcan directive mismatch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `trip-incidents/index.blade.php` | Read blade file |
| 2 | Inspect line 69 | `@canany(['tenant.trip.incident.status'])` — opens canany block |
| 3 | Inspect line 71 | `@endcan` — closes with WRONG directive (should be `@endcanany`) |
| 4 | Inspect line 119 | `@canany(['tenant.trip.incident.status'])` — second occurrence |
| 5 | Inspect line 130 | `@endcan` — same mismatch |
| 6 | Verify template rendering | Blade compiler may or may not catch this depending on Laravel version. It should render both `<th>` and `<td>` sections correctly but the directive mismatch is a code quality issue. |

### TC-CR38: TripMgmtPolicy references non-existent permission group

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `TripMgmtPolicy.php` line 15 | `$user->can('tenant.trip-management.viewAny')` |
| 2 | Search permissionslist.php for `trip-management` | Not found — permission group does NOT exist in permissionslist.php |
| 3 | Verify $crud groups in Transport section | Groups: transport, transport-dashboard, vehicle, route, pickup-point, trans-stops-list, pickup-point-route, ... shift, driver-helper, driver-route-vehicle, route-scheduler, ... trip, stop-details, stop-details.prepare, student.bording, trip.incident, trip-approve — NO `trip-management` |
| 4 | Check if TripMgmtController uses this policy | Controller uses `Gate::authorize('tenant.transport.viewAny')` — NOT policy-based, NOT `tenant.trip-management.*` |
| 5 | Conclude | TripMgmtPolicy is dead code with non-existent permission references |

### TC-CR44: Date range parsing has no try/catch

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | [Query/Code Removed] | [Query/Code Removed] |
| 2 | Send request with invalid date: `date_range=not-a-date - 2026-06-30` | [Query/Code Removed] |
| 3 | HTTP response | 500 Internal Server Error (no graceful error handling) |
| 4 | Send request with malformed range: `date_range=2026-06-01` (no separator) | `str_contains($range, ' - ')` returns false → filter silently skipped → no error, shows all records |

### TC-CT-01: CODE-TRACE — TripMgmtController@index → incidentQuery

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Route matched | web.php:53 | `Route::resource('trip-management', TripMgmtController::class)` → index() called for GET /transport/trip-management |
| 2 | Gate check | TripMgmtController.php:38 | `Gate::authorize('tenant.transport.viewAny')` — must pass or 403 |
| 3 | Driver query | TripMgmtController.php:40-51 | `Auth::user()->id` → lookup DriverHelper → get driver route IDs |
| 4 | Trip ID resolution | TripMgmtController.php:54-71 | Find TptTrip matching request->date + filters → merge trip_id/tripe_id into request |
| 5 | Reference data | TripMgmtController.php:73-80 | Load vehicles, routes, driverHelpers, shifts, etc. |
| 6 | incidentData call | TripMgmtController.php:87 | `$incidentData = $this->incidentQuery($request)->paginate(10)->withQueryString();` |
| 7 | incidentQuery | TripMgmtController.php:449-485 | [Query/Code Removed] |
| 8 | Pagination applied | TripMgmtController.php:87 (continuation) | `paginate(10)->withQueryString()` — 10 per page, preserve query string |
| 9 | View compact | TripMgmtController.php:92-111 | `return view('transport::tab_module.tripmanagement', compact('incidentData', ...));` |
| 10 | Blade renders | tripmanagement.blade.php:43-44 | `@can('tenant.trip.incident.viewAny') @include('transport::trip-incidents.index') @endcan` |

### TC-CT-02: CODE-TRACE — TripController@stopAction → emergency

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Route matched | web.php:163 | `Route::post('trip/stop-action', [TripController::class, 'stopAction'])` → URL: /transport/trip/stop-action |
| 2 | Gate check | TripController.php:125 | `Gate::authorize('tenant.stop-details.update')` |
| 3 | ID parsing | TripController.php:127-181 | Check if ID is 'new_' prefixed → find or create TptTripStopDetail → load trip |
| 4 | Driver/raised_by | TripController.php:184-185 | `$updatedBy = optional($trip->routeScheduler)->driver_id;` `$raisedBy = optional($trip->routeScheduler)->driver_id;` |
| 5 | Switch dispatch | TripController.php:187 | `switch ($request->action)` — matches 'emergency' |
| 6 | Stop update | TripController.php:278-283 | [Query/Code Removed] |
| 7 | Incident create | TripController.php:285-294 | [Query/Code Removed] |
| 8 | Break | TripController.php:297 | `break;` — exits switch |
| 9 | JSON response | TripController.php:300-304 | `return response()->json(['status'=>true, 'message'=>'Stop updated successfully', 'time'=>$now]);` |

### TC-CT-03: CODE-TRACE — TripMgmtController@resolveIncident

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Route matched | web.php:56 | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])` → URL: /transport/trip-incident/{id}/resolve |
| 2 | Method called | TripMgmtController.php:424 | `public function resolveIncident($id)` |
| 3 | Gate check | TripMgmtController.php:426 | `Gate::authorize('tenant.trip.incident.resolve')` — NOTE: permission not in permissionslist.php (see BC-AUTH-GAP-01) |
| 4 | Find incident | TripMgmtController.php:428 | `$incident = TptTripIncidents::findOrFail($id);` → 404 if not found |
| 5 | Double-resolve check | TripMgmtController.php:430-433 | `if ($incident->status == 1) { return redirect()->back()->with('warning', 'Incident already resolved.'); }` |
| 6 | Activity log (BEFORE update) | TripMgmtController.php:435-438 | `activityLog($incident, 'Toggled', [...])` — logged BEFORE DB mutation |
| 7 | DB update | TripMgmtController.php:440-444 | [Query/Code Removed] |
| 8 | Redirect | TripMgmtController.php:446 | `return redirect()->back()->with('success', flash('restored.Incident'));` — NOTE: flash key says 'restored' (see BC-BIZ-DEEP-10) |

### TC-CT-04: CODE-TRACE — Blade rendering chain

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Hub layout loads | tripmanagement.blade.php:1-4 | `<x-backend.layouts.app>` → breadcrum "Trip Management" |
| 2 | Tab nav renders | tripmanagement.blade.php:9-24 | `<x-backend.tab.nav-tab :tabs="[...]" :active="request('tab', 'driver_roster')">` — tab entry at line 20 includes `'permission' => 'tenant.trip.incident.viewAny'` |
| 3 | Permission check | tripmanagement.blade.php:43 | `@can('tenant.trip.incident.viewAny')` — user must have this permission |
| 4 | Partial included | tripmanagement.blade.php:44 | `@include('transport::trip-incidents.index')` |
| 5 | Tab pane div | index.blade.php:1-5 | `<div class="tab-pane fade p-4 bg-white rounded shadow-sm" id="trip_incidents-pane">` |
| 6 | Filter form | index.blade.php:8-54 | GET form with hidden tab input, incident_type dropdown, status dropdown, date range picker, Filter button, Clear conditional link |
| 7 | Table header | index.blade.php:59-72 | `<table>`, `<thead>` with columns, `@canany` wrapping Action <th> |
| 8 | Table body loop | index.blade.php:76-138 | `@forelse($incidentData as $incident)` — renders row with all columns, accessor calls, conditionals for severity/status badges, `@canany` for Action <td> |
| 9 | Empty state | index.blade.php:132-138 | `@empty` — "No incidents found" colspan=9 |
| 10 | Pagination | index.blade.php:144-146 | `{{ $incidentData->withQueryString()->links() }}` |
| 11 | JS includes | index.blade.php:151 | `@include('transport::trip-incidents.js.js')` — SweetAlert2 + Litepicker initialization |
| 12 | Hub footer | tripmanagement.blade.php:56-59 | `@include('transport::css.css')`, `@include('transport::js.js')`, `@include('transport::model.model')` |

### TC-CT-05: CODE-TRACE — Route dispatch for resolve

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Browser request | N/A | GET /transport/trip-incident/5/resolve |
| 2 | Route group prefix | Laravel RouteServiceProvider | `/transport` prefix applied to all routes in web.php |
| 3 | Route match | web.php:56 | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])->name('trip.incident.resolve')` — matches `/transport/trip-incident/5/resolve` |
| 4 | Middleware | Laravel Kernel | `auth` middleware ensures user is logged in (`web` middleware group) |
| 5 | Controller dispatch | TripMgmtController.php:424 | `resolveIncident(5)` method called with $id=5 |
| 6 | Gate authorization | TripMgmtController.php:426 | `Gate::authorize('tenant.trip.incident.resolve')` |
| 7 | Model retrieval | TripMgmtController.php:428 | `TptTripIncidents::findOrFail(5)` |
| 8 | Business logic | TripMgmtController.php:430-444 | Double-resolve check → activityLog → update (see TC-CT-03) |
| 9 | HTTP response | TripMgmtController.php:446 | `redirect()->back()` — redirects to previous page (trip management tab) with flash message |

### TC-EX-01: scopeHighSeverity returns empty due to undefined constant

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Connect to tinker or PHP artisan | `php artisan tinker` |
| 2 | Create a HIGH severity incident | [Query/Code Removed] |
| 3 | Call scopeHighSeverity | `TptTripIncidents::highSeverity()->get()` |
| 4 | Check result | Returns empty collection even though HIGH severity incident exists |
| 5 | Verify SQL | [Query/Code Removed] |
| 6 | Root cause | `self::SEVERITY_HIGH` is undefined → evaluates to null → `where('severity', null)` → use IS NULL comparison inadvertently |

### TC-EX-06: Non-super-admin resolve attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with roles but NOT super_admin | Standard role-based user |
| 2 | Assign `tenant.trip.incident.*` via role UI | Assign all CRUD permissions for trip.incident group |
| 3 | Verify user does NOT have super_admin | `Gate::before()` callback passes only for super_admin |
| 4 | GET `/transport/trip-incident/{id}/resolve` | `Gate::authorize('tenant.trip.incident.resolve')` → 403 |
| 5 | Check permissionslist.php | `trip.incident => $crud` generates: create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve — NOT resolve |
| 6 | Conclusion | Only super_admin can resolve incidents in production. Non-super-admin always gets 403. |

### TC-D01: Trip Deletion — Incidents Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a trip with associated incidents | Trip + incidents exist |
| 2 | Note incident count for that trip | [Query/Code Removed] |
| 3 | Delete the trip | [Query/Code Removed] |
| 4 | Check incidents for deleted trip | [Query/Code Removed] |
| 5 | Check incidents table for deleted trip_id | No records remain with that trip_id |

### TC-D02: RaisedBy/ResolvedBy User — SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a user referenced in raised_by | `SELECT raised_by FROM tpt_trip_incidents WHERE raised_by IS NOT NULL LIMIT 1` |
| 2 | Delete that user | `DELETE FROM sys_users WHERE id={userId}` |
| 3 | Check incidents | `SELECT raised_by FROM tpt_trip_incidents WHERE raised_by={userId}` → NULL (SET NULL) |
| 4 | Repeat for resolved_by | Same behavior — resolved_by becomes NULL |

### 5.1b Migration DDL Analysis — Gaps Found

| BC-ID-DDL | Issue | Details |
|-----------|-------|---------|
| BC-DDL-GAP-01 | Migration missing `trip_id` column declaration before FK | `trip_id` declared at line 29 AFTER other columns (status, raised_at, resolved_at) — FK reference column declared at line 30. Not a functional issue but DDL ordering puts FK column after timestamp columns, atypical for migration structure. |
| BC-DDL-GAP-02 | `raised_to` column does NOT exist in migration | Model has `raisedTo()` relationship referencing `raised_to` FK, but migration file `2026_06_16_140625_create_tpt_trip_incidents_table.php` has NO `raised_to` column. Running this relationship at runtime will throw `Illuminate\Database\Eloquent\RelationNotFoundException` or `SQLSTATE[42S22]: Column not found`. |
| BC-DDL-GAP-03 | Enum order mismatch: DDL vs Model | DDL defines `enum('severity', ['HIGH', 'LOW', 'MEDIUM'])` (line 18) — order is HIGH, LOW, MEDIUM. Model defines `SEVERITY` array with order LOW, MEDIUM, HIGH (line 60-64). While functionally equivalent, the order inconsistency could cause confusion during DB migrations and enum validation. |
| BC-DDL-GAP-04 | `raised_at` column is NULLABLE but `incident_time` is NOT NULL | Model `booted()` sets `raised_at` default on create, but `incident_time` has no model default and is NOT NULL in DDL. The controller `stopAction()` always passes `incident_time => $now`, so this is consistent at runtime but the model has no fallback guard for `incident_time`. |
| BC-DDL-GAP-05 | No index on `incident_type` or `status` columns | The `incidentQuery()` method filters by `incident_type` and `status` columns. With 10/page pagination and potential large datasets, lack of indexes on these filter columns could cause performance degradation. |
| BC-DDL-GAP-06 | No index on `incident_time` column | [Query/Code Removed] |
| BC-DDL-GAP-07 | `resolved_at` declared before `resolved_by` in DDL | DDL line 24: `resolved_at`, line 25-26: `created_at`/`updated_at`, line 33: `resolved_by`. The `resolved_by` FK column is declared AFTER `created_at`/`updated_at` — schema design places audit metadata in between the resolved fields. Minor schema design inconsistency. |
| BC-DDL-GAP-08 | No index on `trip_id` FK column | FK constraint exists but no explicit index. MySQL auto-indexes FK columns in InnoDB, so this is not a functional gap. But explicit index naming would improve schema clarity. |
| BC-DDL-GAP-09 | `deleted_at` column nullable but no index | SoftDeletes trait queries include `WHERE deleted_at IS NULL` by default. Without an index on `deleted_at`, filtered queries may perform full table scans on large datasets. |
| BC-DDL-GAP-10 | Migration uses `timestamp` type (not `timestampTz`) | No timezone support. `incident_time`, `raised_at`, `resolved_at` are stored without timezone information. Server timezone settings will affect interpretation. |

### 5.2 Authorization (Permission Gates)

| BC ID | Permission | Method / Location | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.transport.viewAny | TripMgmtController@index() (Gate::authorize) | Without → 403 |
| BC-AUTH-02 | tenant.trip.incident.viewAny | Blade `@can` wrapping tab & include | Without → tab hidden |
| BC-AUTH-03 | tenant.trip.incident.viewAny | Blade `@can` including `trip-incidents.index` partial | Without → partial not rendered |
| BC-AUTH-04 | tenant.trip.incident.resolve | resolveIncident() (Gate::authorize) | Without → 403 |
| BC-AUTH-05 | tenant.trip.incident.status | Blade `@canany` wrapping Action column (th + td) | Without → Resolve button hidden |

### 5.2b Authorization — Gap Analysis

| BC-ID-AUTH | Issue | Details | Severity |
|-----------|-------|---------|----------|
| BC-AUTH-GAP-01 | `tenant.trip.incident.resolve` NOT in permissionslist.php `$crud` | The `$crud` array (line 13-31 of permissionslist.php) defines standard actions: create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve. `resolve` is NOT in this list. The permission group `'trip.incident' => $crud` creates `tenant.trip.incident.create`, `tenant.trip.incident.view`, etc. but NOT `tenant.trip.incident.resolve`. `Gate::authorize('tenant.trip.incident.resolve')` will NEVER match a real permission — only works via `is_super_admin` bypass in `Gate::before()`. | 🔴 CRITICAL |
| BC-AUTH-GAP-02 | Gate mismatch — controller vs blade | Controller `index()` uses `Gate::authorize('tenant.transport.viewAny')` but the blade tab uses `permission => 'tenant.trip.incident.viewAny'`. A user who has `tenant.transport.viewAny` (passes controller gate) but NOT `tenant.trip.incident.viewAny` can access the page but won't see the tab. Vice versa, a user with `tenant.trip.incident.viewAny` but NOT `tenant.transport.viewAny` gets 403 at controller level but tab would have rendered. Two different permission keys guard the same feature — potential UX confusion. | 🟡 MEDIUM |
| BC-AUTH-GAP-03 | `status` action exists in $crud but blade uses `status` for button visibility | The `$crud` array includes `'status'`. So `tenant.trip.incident.status` IS a valid permission key created by `'trip.incident' => $crud`. This part actually works. However, the blade uses `@canany(['tenant.trip.incident.status'])` (single-element array) with incorrect closing directive (`@endcan` instead of `@endcanany`). See BC-BLADE-GAP-01. | 🟡 MEDIUM |
| BC-AUTH-GAP-04 | `tenant.trip.incident.*` part of `trip.incident` group, not fully documented | `permissionslist.php` line 324: `'trip.incident' => $crud` under `// begin::Transport Trip Management here`. This creates permissions like `tenant.trip.incident.create`, `tenant.trip.incident.view`, `tenant.trip.incident.update`, `tenant.trip.incident.delete`, `tenant.trip.incident.restore`, `tenant.trip.incident.forceDelete`. None of these are used by any controller or blade because incidents have NO dedicated CRUD. The permission group is defined but underutilized. | 🟢 LOW |
| BC-AUTH-GAP-05 | Policy `TransportTripIncidentPolicy` defines methods unused by controllers | Policy defines: `viewAny`, `view`, `status`, `create`, `update`, `delete`, `restore`, `forceDelete`, `import`, `export`, `print`, `report`, `resolve`, `escalate`, `viewReports`, `generateReport`. Controller only uses `Gate::authorize('tenant.trip.incident.resolve')`. Methods `escalate`, `viewReports`, `generateReport`, `report`, `import`, `export`, `print` are defined but never called by any controller. This is dead code in the policy. | 🟡 MEDIUM |
| BC-AUTH-GAP-06 | `resolve` permission works only via super_admin bypass | Since `resolve` is not in `$crud`, `tenant.trip.incident.resolve` does NOT exist as a real DB permission. The only way `Gate::authorize('tenant.trip.incident.resolve')` passes is if the user is a super_admin (via `Gate::before()` check in AuthServiceProvider). Non-super-admin users will ALWAYS get 403 on resolve regardless of role configuration. | 🔴 CRITICAL |
| BC-AUTH-GAP-07 | `tenant.trip-management.*` in TripMgmtPolicy does NOT exist in permissionslist.php | `TripMgmtPolicy` uses `tenant.trip-management.viewAny` etc. Permission group `trip-management` does NOT exist in `permissionslist.php`. This policy is effectively dead — the controller never uses policy-based gates and the permission strings in the policy will never match anything. | 🔴 CRITICAL |
| BC-AUTH-GAP-08 | Blade uses `@can('tenant.trip.incident.viewAny')` for tab body — no controller-level check | The tab body is only guarded by blade-level `@can`. If a user navigates directly to `?tab=trip_incidents` without the viewAny permission, the tab pane div simply won't render. But the page will still load (no 403) because the controller gate only checks `tenant.transport.viewAny`. This means partial data (from other tabs) still loads via the controller's queries, potentially exposing information indirectly. | 🟡 MEDIUM |
| BC-AUTH-GAP-09 | `tenant.trip.incident.resolve` used in Gate::authorize() but policy also defines `resolve()` method | The controller uses `Gate::authorize('tenant.trip.incident.resolve')` which calls `TransportTripIncidentPolicy@resolve()`. Policy method exists. However, since `resolve` is not in `$crud`, the `can()` check within the policy method returns false for non-super-admins. The policy method is correct but the underlying permission doesn't exist. | 🟡 MEDIUM |

### 5.3 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Incident created via stopAction emergency | TptTripIncidents created with incident_type=0, severity='MEDIUM', status=0, description from request->remark, raised_by=driver_id from routeScheduler, raised_at=now() |
| BC-BIZ-02 | Resolve incident with status=0 (OPEN) | status=1, resolved_at=now(), resolved_by=auth()->id(); redirect with success |
| BC-BIZ-03 | Resolve already-resolved incident (status=1) | Redirect back with warning 'Incident already resolved.' |
| BC-BIZ-04 | Model auto-sets raised_at on create | In booted() creating: if raised_at not set, defaults to now() |
| BC-BIZ-05 | Activity log on resolve | `activityLog($incident, 'Toggled', ['message' => 'Incident status updated.', 'performed_by' => Auth::user()->name])` |

### 5.3b Business Logic — Deep Dive (BC-BIZ-DEEP entries)

| BC-ID-DEEP | Condition | Code Location | Actual Code | Expected vs Actual Analysis |
|-----------|-----------|---------------|-------------|---------------------------|
| BC-BIZ-DEEP-01 | Incident creation via stopAction emergency | TripController.php:277-296 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-02 | No activityLog on incident creation | TripController.php:277-296 (case 'emergency') | [Query/Code Removed] | ❌ **GAP**: Unlike resolve (which calls activityLog at line 435-438), the emergency action does NOT log incident creation. This means incident creation is invisible in the activity log. Activity is inconsistent between creation (no log) and resolution (logged). |
| BC-BIZ-DEEP-03 | Resolve activityLog uses 'Toggled' event | TripMgmtController.php:435-438 | `activityLog($incident, 'Toggled', ['message' => 'Incident status updated.', 'performed_by' => Auth::user()->name])` | ❌ **GAP**: The event name 'Toggled' is semantically incorrect for a resolve action. 'Toggled' implies toggling between states (like on/off switch), but resolve is a forward-only state transition (OPEN→RESOLVED). The activity log will show 'Incident status updated' for both resolve operations. Moreover, the activityLog is called BEFORE the update() at line 440-444 — if the update fails, the activity log would have recorded an event for an operation that didn't complete. |
| BC-BIZ-DEEP-04 | activityLog order vs update order | TripMgmtController.php:435 vs 440 | activityLog() is called at lines 435-438, THEN update() at lines 440-444. | ❌ **GAP**: activityLog is recorded BEFORE the actual DB update. If the update fails, the activity log will show 'Incident status updated' for an incident that never actually changed status. Standard practice is to perform the DB mutation FIRST, then log after success. |
| BC-BIZ-DEEP-05 | Double-resolve prevention check | TripMgmtController.php:430-432 | `if ($incident->status == 1) { return redirect()->back()->with('warning', 'Incident already resolved.'); }` | ✅ **WORKS**: Uses loose equality (`==`). Since status is INT UNSIGNED with values 0 or 1, loose vs strict equality doesn't matter here. Flash message is 'warning', which will show as yellow/orange alert. |
| BC-BIZ-DEEP-06 | Model booted() auto-sets raised_at | TptTripIncidents.php:140-147 | `static::creating(function ($model) { if (!$model->raised_at) { $model->raised_at = now(); } });` | ✅ **WORKS**: However, note that stopAction already passes `raised_at => $now` explicitly (line 292), so the booted() fallback is never triggered for the primary creation path. The fallback only matters if incidents are created programmatically without raised_at. |
| BC-BIZ-DEEP-07 | Missing `scopeHighSeverity` constant | TptTripIncidents.php:133-135 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-08 | scopeOpen uses resolved_at check | TptTripIncidents.php:127-129 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-09 | Controller uses loose `status == 1` check | TripMgmtController.php:431 | `if ($incident->status == 1)` | ✅ **WORKS** for current implementation where status is INT. However, if status ever changes to string ENUM ('OPEN', 'RESOLVED'), this comparison would fail. The model uses `const STATUS = [0=>'OPEN', 1=>'RESOLVED']` indicating INT-based status is intentional. |
| BC-BIZ-DEEP-10 | Resolve send `flash('restored.Incident')` | TripMgmtController.php:446 | `return redirect()->back()->with('success', flash('restored.Incident'));` | ❌ **GAP**: The flash key is `flash('restored.Incident')` but the action is a RESOLVE, not a RESTORE. The flash message will display a text like "Incident restored successfully" because it uses the `restored` locale key. This is misleading — the incident was resolved, not restored from trash. Should use `flash('resolved.Incident')` or similar. However, this depends on whether the `flash()` helper has a `resolved.Incident` key defined in translation files. |
| BC-BIZ-DEEP-11 | raised_by stores driver_id from routeScheduler | TripController.php:185, 291 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-12 | severity is hardcoded to 'MEDIUM' | TripController.php:293 | `'severity' => 'MEDIUM'` | ❌ **GAP**: All incidents created via stopAction emergency are hardcoded to MEDIUM severity regardless of the actual emergency situation. There is no way for the driver or user to specify severity when triggering emergency. This means the severity filter in the blade (which shows HIGH/MEDIUM/LOW) will always show only MEDIUM incidents from the automatic creation path. If incidents could be created via other means (seeder, API, etc.) with different severities, those would appear, but the primary creation path always produces MEDIUM. |
| BC-BIZ-DEEP-13 | incident_type is hardcoded to 0 | TripController.php:288 | `'incident_type' => 0` | ❌ **GAP**: All incidents via stopAction emergency are created with `incident_type=0` (Stop Emergency). Other types (1=VehicleBreakdown, 2=Accident, 3=RouteBlocked) can never be created via the stopAction flow. If a vehicle breaks down, the driver triggers emergency and it's logged as 'Stop Emergency' rather than 'Vehicle Breakdown'. The incident_type filter in the blade (which shows all 4 types) will only ever show type 0 incidents from the automatic path. |
| BC-BIZ-DEEP-14 | No trip_id validation in incident creation | TripController.php:286 | [Query/Code Removed] | [Query/Code Removed] |
| BC-BIZ-DEEP-15 | Resolve route is GET, not POST | Route (web.php:56) | `Route::get('trip-incident/{id}/resolve', ...)` | ❌ **GAP**: Resolving an incident is a state-mutating operation (changes DB). Using GET violates HTTP specification (RFC 7231 Section 4.3.1 — GET requests should be safe and idempotent). Additionally: (1) No CSRF protection on GET, (2) Browser prefetch could accidentally trigger resolve, (3) Caching layers may cache the redirect response. The blade button is an `<a>` tag (line 122: `<a href="{{ ... }}">`) which makes a GET request when clicked (even with JS confirm). Should be a `<form>` with POST method or use a POST route with proper CSRF token. |
| BC-BIZ-DEEP-16 | resolveIncident has no validation for $id | TripMgmtController.php:428 | `$incident = TptTripIncidents::findOrFail($id);` | ✅ **WORKS**: findOrFail throws ModelNotFoundException if incident doesn't exist, which Laravel converts to 404. |
| BC-BIZ-DEEP-17 | stopAction('emergency') uses `updatedBy` AND `raisedBy` both from driver_id | TripController.php:184-185 | `$updatedBy = optional($trip->routeScheduler)->driver_id; $raisedBy = optional($trip->routeScheduler)->driver_id;` | ✅ **DESIGN**: Both variables use the same source (driver_id). `updatedBy` is used to update the stop detail's `updated_by` field. `raisedBy` is used in the incident's `raised_by`. They could be combined into one variable since they're identical. Minor code clarity issue. |
| BC-BIZ-DEEP-18 | stopAction('emergency') updates stop detail before creating incident | TripController.php:278-294 | Stop update first (lines 278-283), then incident creation (lines 285-294). | ✅ **ORDER**: Stop detail is updated first (emergency_flag=1, emergency_time, etc.), then incident is created. If incident creation fails, the stop detail already has emergency_flag=1 but no incident record exists — partial state. The code does NOT use DB::transaction() for the emergency case, unlike other stopAction cases that have single operations. |
| BC-BIZ-DEEP-19 | No DB::transaction around emergency stop update + incident creation | TripController.php:277-297 | The `case 'emergency'` block does NOT wrap the two DB operations (stop update + incident create) in a DB::transaction(). | ❌ **GAP**: If incident creation fails (e.g., FK violation, DB error), the stop detail update has already been committed. This leaves the system in an inconsistent state: stop_detail.emergency_flag=1 but no incident record. Should use `DB::transaction(function() { ... })` to ensure atomicity. |
| BC-BIZ-DEEP-20 | Multiple concurrent emergency triggers | TripController.php:285-294 (stopAction) | If stopAction('emergency') is called multiple times for the same stop, multiple incidents are created. | ❌ **GAP**: There is NO duplicate prevention for emergency actions. Each call to stopAction('emergency') creates a new incident record. If a driver presses emergency button twice accidentally, two incident records are created for the same stop. No check exists like `if already has open incident for this trip`. |

### 5.4 Model Relationships — `TptTripIncidents`

| BC ID | Relationship | Type | Foreign Key | Analysis |
|-------|-------------|------|-------------|----------|
| BC-REL-01 | trip() | BelongsTo TptTrip | trip_id | ✅ Exists in both model and DDL. ON DELETE CASCADE. |
| BC-REL-02 | raisedByUser() | BelongsTo User | raised_by | ✅ Duplicate of raisedBy() but with different method name. Both work. |
| BC-REL-03 | incidentType() | BelongsTo TptIncidentType | incident_type | ❌ **MODEL DOES NOT EXIST**: `TptIncidentType` class not found in codebase. Using this relationship will throw `Class "Modules\Transport\Models\TptIncidentType" not found`. |
| BC-REL-04 | statusMaster() | BelongsTo TptIncidentStatus | status | ❌ **MODEL DOES NOT EXIST**: `TptIncidentStatus` class not found in codebase. Using this relationship will throw ClassNotFoundException. |
| BC-REL-05 | raisedBy() | BelongsTo User | raised_by | ✅ Works. Duplicate of raisedByUser(). |
| BC-REL-06 | raisedTo() | BelongsTo User | raised_to | ❌ **COLUMN DOES NOT EXIST**: Migration has NO `raised_to` column. This relationship references a non-existent FK and will throw QueryException at runtime: `Column not found: 1054 Unknown column 'tpt_trip_incidents.raised_to'`. |
| BC-REL-07 | resolvedBy() | BelongsTo User | resolved_by | ✅ Works. FK exists in DDL with ON DELETE SET NULL. This is the only relationship eagerly loaded in incidentQuery(). |

### 5.4b Model Relationship — Dependency and Runtime Impact Table

| Relationship | Referenced Model | Referenced FK | Runtime Behavior If Accessed | Eager-Loaded? | Used In Blade? |
|-------------|-----------------|---------------|------------------------------|---------------|----------------|
| trip() | TptTrip | trip_id | ✅ Works | ❌ No | ❌ No |
| raisedByUser() | User (SysUsers) | raised_by | ✅ Works | ❌ No | ❌ No |
| incidentType() | TptIncidentType (MISSING) | incident_type | ❌ ClassNotFoundException | ❌ No | ❌ No (uses accessor) |
| statusMaster() | TptIncidentStatus (MISSING) | status | ❌ ClassNotFoundException | ❌ No | ❌ No (uses accessor) |
| raisedBy() | User (SysUsers) | raised_by | ✅ Works | ❌ No | ❌ No |
| raisedTo() | User (SysUsers) | raised_to (MISSING) | ❌ QueryException (column not found) | ❌ No | ❌ No |
| resolvedBy() | User (SysUsers) | resolved_by | ✅ Works | ✅ Yes | ✅ Yes (`$incident->resolvedBy?->name`) |

### 5.4c Model Fillable vs DDL Column Comparison

| # | Fillable Field | DDL Column | Match? | Notes |
|---|---------------|------------|--------|-------|
| 1 | trip_id | trip_id | ✅ | Both NOT NULL |
| 2 | incident_time | incident_time | ✅ | Both NOT NULL |
| 3 | incident_type | incident_type | ✅ | Both NOT NULL |
| 4 | severity | severity | ✅ | DDL ENUM, model constant |
| 5 | latitude | latitude | ✅ | Both nullable |
| 6 | longitude | longitude | ✅ | Both nullable |
| 7 | description | description | ✅ | Both VARCHAR(512) nullable |
| 8 | status | status | ✅ | Both INT UNSIGNED nullable |
| 9 | raised_by | raised_by | ✅ | Both FK to sys_users nullable |
| 10 | raised_at | raised_at | ✅ | Both TIMESTAMP nullable |
| 11 | resolved_at | resolved_at | ✅ | Both TIMESTAMP nullable |
| 12 | resolved_by | resolved_by | ✅ | Both FK to sys_users nullable |
| 13 | (not fillable) | created_at | — | TIMESTAMP, auto-set by migration |
| 14 | (not fillable) | updated_at | — | TIMESTAMP, auto-set by migration |
| 15 | (not fillable) | deleted_at | — | TIMESTAMP, SoftDeletes |

### 5.5 Blade View Analysis — `trip-incidents/index.blade.php`

| BC-ID-BLADE | Location | Code | Analysis |
|------------|----------|------|----------|
| BC-BLADE-01 | Lines 69-71 | `@canany(['tenant.trip.incident.status']) ... @endcan` | ❌ **GAP**: `@canany` is opened at line 69 but closed with `@endcan` at line 71 (not `@endcanany`). This is a directive mismatch. Blade may render this incorrectly depending on Blade compiler version. The `@canany` directive expects `@endcanany` as its closing tag. |
| BC-BLADE-02 | Lines 119-130 | `@canany(['tenant.trip.incident.status']) ... @endcan` (second occurrence) | ❌ **GAP**: Same directive mismatch as BC-BLADE-01. The `<td>` action cell (lines 120-129) is wrapped in `@canany` but closed with `@endcan` at line 130. The `<th>` has the same issue at lines 69-71. |
| BC-BLADE-03 | Lines 69-71 | `@canany(['tenant.trip.incident.status'])` | 🔴 **GAP**: `@canany` with a SINGLE permission in array is redundant — should be `@can('tenant.trip.incident.status')`. While `@canany` with one element works, it's semantically incorrect and misleading. |
| BC-BLADE-04 | Line 151 | `@include('transport::trip-incidents.js.js')` | ❌ **GAP**: The JS file is included OUTSIDE the `.tab-pane` div (which closes at line 148). The JS include at line 151 is after the closing `</div>` at line 148. It's also outside the layout's `.container-fluid` structure (but the master layout wraps everything). The placement is unconventional — JS includes are normally in a `@push('scripts')` section or at the bottom of `x-backend.layouts.app`, not scattered after HTML elements. |
| BC-BLADE-05 | Lines 14-19 | `@foreach(\Modules\Transport\Models\TptTripIncidents::TYPE as $key => $label)` | ❌ **GAP**: The blade directly references the Model class in the template to populate the type dropdown. This couples the view to the model's constant structure. If the TYPE constant changes or is removed, this blade will break. Standard practice is to pass the types from the controller. |
| BC-BLADE-06 | Lines 8-54 | Filter form uses `<form method="GET">` | ✅ **WORKS**: GET form correctly appends query parameters including `tab=trip_incidents` (hidden input at line 9). The Clear button (line 49) correctly routes back to the index with the tab parameter. |
| BC-BLADE-07 | Line 145 | `{{ $incidentData->withQueryString()->links() }}` | ❌ **GAP**: Uses `->withQueryString()` but does NOT append `['tab' => 'trip_incidents']` specifically. The `->withQueryString()` passes ALL current query parameters, which does include `tab` from the URL. However, this is fragile — if pagination is performed outside the valid tab context, it could lose the tab parameter. Other tab partials in this codebase use `->appends(['tab' => 'trip_incidents'])` explicitly. |
| BC-BLADE-08 | Line 122 | Resolve URL: `route('transport.trip.incident.resolve', $incident->id)` | ✅ ✅ **Confirmed**: Route exists at web.php:56 as `trip.incident.resolve`. This generates URL `/transport/trip-incident/{id}/resolve`. The route name must be used with the `transport.` prefix (i.e., `transport.trip.incident.resolve`) per Laravel route naming convention with route groups. |
| BC-BLADE-09 | Lines 69, 119 | Permission `tenant.trip.incident.status` used for action column visibility | ✅ **WORKS** (if permission exists): The blade checks `tenant.trip.incident.status` (which IS in `$crud`, so it works). However, the button action (resolve) actually requires `tenant.trip.incident.resolve` permission (the controller gate). This creates a UX inconsistency: a user could see the Resolve button (via `status` permission) but get 403 when clicking it (because `resolve` permission doesn't exist in permissionslist.php). See BC-AUTH-GAP-01. |
| BC-BLADE-10 | Line 48 | `@if(request()->anyFilled(['incident_type', 'status', 'date_range']))` | ✅ **WORKS**: Correctly uses `anyFilled()` helper to check if any filter is active before showing the Clear button. |

### 5.6 Route Analysis

| BC-ID-ROUTE | URI | Method | Controller | Name | Analysis |
|------------|------|--------|-----------|------|----------|
| BC-ROUTE-01 | `/transport/trip-incident/{id}/resolve` | GET | `TripMgmtController@resolveIncident` | `trip.incident.resolve` | ❌ **GAP**: GET used for DB mutation. See BC-BIZ-DEEP-15. |
| BC-ROUTE-02 | `/transport/trip-management` | GET | `TripMgmtController@index` | Auto (resource) | ✅ Works. Route::resource('trip-management', TripMgmtController::class) at web.php:53 generates standard resource routes. |
| BC-ROUTE-03 | `/transport/trip/stop-action` | POST | `TripController@stopAction` | `trip.stop-action` | ✅ POST used for data creation. Correct HTTP method for mutation. |

### 5.6b Route File — Complete Route Table for Trip Mgmt

| # | URI | Method | Controller@Method | Name | Notes |
|---|-----|--------|-------------------|------|-------|
| 1 | `transport/trip-management` | GET | TripMgmtController@index | trip-management.index | Resource route — lists all tabs |
| 2 | `transport/trip-management/create` | GET | TripMgmtController@create | trip-management.create | Resource route — unused (no view) |
| 3 | `transport/trip-management` | POST | TripMgmtController@store | trip-management.store | Resource route — empty method |
| 4 | `transport/trip-management/{trip_management}` | GET | TripMgmtController@show | trip-management.show | Resource route — returns generic view |
| 5 | `transport/trip-management/{trip_management}/edit` | GET | TripMgmtController@edit | trip-management.edit | Resource route — returns generic view |
| 6 | `transport/trip-management/{trip_management}` | PUT/PATCH | TripMgmtController@update | trip-management.update | Resource route — empty method |
| 7 | `transport/trip-management/{trip_management}` | DELETE | TripMgmtController@destroy | trip-management.destroy | Resource route — empty method |
| 8 | `transport/trip-incident/{id}/resolve` | GET | TripMgmtController@resolveIncident | trip.incident.resolve | Custom route — incident resolve |

### 5.7 Policy Analysis

| Policy Method | Permission String | Called By Controller? | Used In Blade? | Status |
|-------------|-------------------|---------------------|----------------|--------|
| viewAny(User) | tenant.trip.incident.viewAny | ❌ (uses Gate::authorize string) | ✅ tab and index include | Policy-defined, controller uses Gate::authorize directly |
| view(User, TptTripIncidents) | tenant.trip.incident.view | ❌ | ❌ | Dead code |
| status(User, TptTripIncidents) | tenant.trip.incident.status | ❌ | ✅ blade @canany | Dead code in policy, active in blade |
| create(User) | tenant.trip.incident.create | ❌ no create route | ❌ | Dead code |
| update(User, TptTripIncidents) | tenant.trip.incident.update | ❌ no update route | ❌ | Dead code |
| delete(User, TptTripIncidents) | tenant.trip.incident.delete | ❌ no delete route | ❌ | Dead code |
| restore(User, TptTripIncidents) | tenant.trip.incident.restore | ❌ no restore route | ❌ | Dead code |
| forceDelete(User, TptTripIncidents) | tenant.trip.incident.forceDelete | ❌ no forceDelete route | ❌ | Dead code |
| import(User) | tenant.trip.incident.import | ❌ | ❌ | Dead code |
| export(User) | tenant.trip.incident.export | ❌ | ❌ | Dead code |
| print(User) | tenant.trip.incident.print | ❌ | ❌ | Dead code |
| report(User) | tenant.trip.incident.report | ❌ | ❌ | Dead code |
| resolve(User, TptTripIncidents) | tenant.trip.incident.resolve | ✅ (Gate::authorize) | ✅ resolve button route | Active — but permission not in permissionslist.php |
| escalate(User, TptTripIncidents) | tenant.trip.incident.escalate | ❌ | ❌ | Dead code — not a real permission |
| viewReports(User) | tenant.trip.incident.viewReports | ❌ | ❌ | Dead code — not a real permission |
| generateReport(User) | tenant.trip.incident.generateReport | ❌ | ❌ | Dead code — not a real permission |

### 5.8 Route Model Binding & URL Generation

| Aspect | Details |
|--------|---------|
| Resolve URL pattern | `/transport/trip-incident/{id}/resolve` — uses explicit `$id` parameter, NO implicit route model binding |
| Controller signature | `resolveIncident($id)` — receives raw ID, calls `TptTripIncidents::findOrFail($id)` |
| No implicit binding | Laravel convention: `{tripIncident}` (model variable) would trigger implicit binding. But route uses `{id}`, so no auto-resolution. |
| Route name prefix | Route is defined inside a `/transport` prefix group (from the parent route file), so final URL is `/transport/trip-incident/{id}/resolve` |
| Blade route generation | `route('transport.trip.incident.resolve', $incident->id)` — generates absolute URL with the incident ID |

### 5.9 JavaScript & Frontend Analysis

| BC-ID-JS | Location | Code | Analysis |
|---------|----------|------|----------|
| BC-JS-01 | js.blade.php:5-25 | SweetAlert2 confirmation on `.resolve-incident` | ❌ **GAP**: The JS adds click handler that prevents default and shows confirmation dialog. On confirmation, it sets `window.location.href = url` — making a GET request. Combined with the GET route (see BC-ROUTE-01), this means the resolve action is confirmed via Swal then executed as a GET navigation. No fetch/AJAX call is used. If the resolve fails (403, 404, double-resolve), the browser navigates to the redirect response URL. This is a suboptimal UX pattern. |
| BC-JS-02 | js.blade.php:39-63 | Litepicker date range initialization | ❌ **GAP**: The JS references `$(this).closest('form').find('.start_date')` and `.end_date` (lines 55-56), but the blade filter form does NOT contain any elements with class `start_date` or `end_date`. These jQuery selectors will return empty results. The date range is sent as a single `date_range` string via the Litepicker element itself, so the hidden inputs are not strictly needed. However, this is dead JS code that will silently fail. |
| BC-JS-03 | js.blade.php:1 | CDN script: `sweetalert2@11` | ✅ **WORKS**: Loads SweetAlert2 from CDN. However, requires internet connectivity. If CDN is unreachable, the confirmation dialog will not render and the resolve button will behave as a normal `<a>` link (navigating directly). |

### 5.10 Performance & Security Analysis

| BC-ID-PERF | Category | Issue | Details |
|-----------|----------|-------|---------|
| BC-PERF-01 | Performance | All tab queries run on every page load | TripMgmtController@index() executes 8+ separate queries (TripQuery, incidentQuery, SchedulerQuery, tripBordUnbord, tripStopNew, tripStopTimeline, driverRouteVehicleQuery, notificationLogQuery) regardless of which tab is active. Each query hits the database and builds a paginator. For trips with large datasets, this means unnecessary queries for inactive tabs. |
| BC-PERF-02 | Performance | No pagination cache or query optimization | Each page load executes fresh queries. With 10/page pagination and potential thousands of incidents, the `orderByDesc('incident_time')` query could become slow without index. No query caching. |
| BC-PERF-03 | Performance | Eager loading only `resolvedBy` relationship | Only one relationship (resolvedBy) is eager-loaded. The `trip()` relationship is NOT eager-loaded, but it's not needed in the blade either. |
| BC-SEC-01 | Security | GET route for state mutation | CSRF attack vector: An attacker could craft an `<img>` tag pointing to `/transport/trip-incident/{id}/resolve` to trigger resolve without user consent. Since GET has no CSRF token, the request would succeed if the victim is authenticated. |
| BC-SEC-02 | Security | No rate limiting on resolve route | The resolve route has no throttle middleware. An attacker could rapidly call resolve on multiple incidents. |
| BC-SEC-03 | Security | No logging of failed resolve attempts | Failed resolve attempts (404, 403, double-resolve) are NOT logged in activity_log. Only successful resolves are logged. This reduces audit trail effectiveness. |

### 5.11 Integration Points Analysis

| BC-ID-INT | Integration | Details |
|-----------|-------------|---------|
| BC-INT-01 | Activity Log | `activityLog()` helper called on resolve (but NOT on creation). Logs to activity_log table with event='Toggled'. |
| BC-INT-02 | Notification Log | stopAction('emergency') does NOT create a TptNotificationLog entry, unlike start_trip (TripStart), reach (ReachedStop/Delayed), leave (ApproachingStop) which all create notification logs. |
| BC-INT-03 | Trip Stop Detail | Incidents are linked to trips via trip_id, but not directly linked to stop details. The emergency flag on TptTripStopDetail (emergency_flag=1, emergency_remarks) is set independently from the TptTripIncidents record. |
| BC-INT-04 | Vendor Module | No vendor integration for incidents (unlike trip approval which creates VndUsageLog). |
| BC-INT-05 | User/SysUsers | Both raised_by and resolved_by FK to sys_users table with ON DELETE SET NULL. |

---

## 6. Test Case List

### 6.0 Code Trace Test Cases (CODE-TRACE)

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CT-01 | CODE-TRACE | P1 | Trace: TripMgmtController@index → incidentQuery | Full code path from index() to incidentData variable to view compact | incidentQuery called with $request, returns query builder with ->with('resolvedBy')->orderByDesc('incident_time'), paginate(10) applied, compact('incidentData') passed to view | — | — | ◌ |
| TC-CT-02 | CODE-TRACE | P1 | Trace: TripController@stopAction → emergency | Full code path from stopAction reception to TptTripIncidents::create | stopAction validates request, matches action='emergency', creates incident with hardcoded values: incident_type=0, severity='MEDIUM', raised_by=driver_id, returns JSON success | — | — | ◌ |
| TC-CT-03 | CODE-TRACE | P1 | Trace: TripMgmtController@resolveIncident | Full code path from route dispatch to redirect | Gate::authorize('tenant.trip.incident.resolve'), findOrFail($id), double-resolve check, activityLog, update(status=1, resolved_at, resolved_by), redirect back | — | — | ◌ |
| TC-CT-04 | CODE-TRACE | P1 | Trace: Blade rendering chain | Hub tab → partial → JS inclusion | tripmanagement.blade.php @can → @include('transport::trip-incidents.index') → renders tab-pane with filter form + table + pagination → @include('transport::trip-incidents.js.js') for JS | — | — | ◌ |
| TC-CT-05 | CODE-TRACE | P1 | Trace: Route dispatch for resolve | Browser GET → web.php → controller method | Route::get('trip-incident/{id}/resolve', ...) → Laravel dispatches to resolveIncident($id) → Gate::authorize → findOrFail → update → redirect | — | — | ◌ |
| TC-CT-06 | CODE-TRACE | P2 | [Query/Code Removed] | TptTripIncidents creating event | [Query/Code Removed] | — | — | ◌ |
| TC-CT-07 | CODE-TRACE | P2 | Trace: View compact variable chain | Controller → blade variable access | $incidentData passed via compact → blade accesses as $incidentData → paginate() calls links() → iteration with $incident | — | — | ◌ |
| TC-CT-08 | CODE-TRACE | P2 | Trace: Filter form submission | Form GET → query params → incidentQuery filters | Form submits GET to current URL → tab=trip_incidents&incident_type=X&status=Y&date_range=Z → incidentQuery reads from $request | — | — | ◌ |

### 6.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Incident Tab Loads | `/transport/trip-management?tab=trip_incidents` shows incident grid with filters (requires `tenant.transport.viewAny` + `tenant.trip.incident.viewAny`) | — | — | ⬜ |
| TC-P02 | Incident Created via Emergency Action | POST `/transport/trip/stop-action` with action=emergency, remark="Flat tire" → incident created with incident_type=0, severity=MEDIUM, raised_by=driver_id | — | — | ⬜ |
| TC-P03 | View Incident in List | Incident appears in grid with Incident Time, Type, Severity, Description, Status, Resolved At, Resolved By, Action columns | — | — | ⬜ |
| TC-P04 | Resolve Open Incident | GET `/transport/trip-incident/{id}/resolve` where status=0 → status=1, resolved_at set, resolved_by set | — | — | ⬜ |
| TC-P05 | Filter by Incident Type | Select type dropdown → matching incidents | — | — | ⬜ |
| TC-P06 | Filter by Status (OPEN / RESOLVED) | Select status → matching incidents | — | — | ⬜ |
| TC-P07 | Filter by Date Range | Enter date range → incidents within that range | — | — | ⬜ |
| TC-P08 | Empty State — No Incidents | "No incidents found" message displayed | — | — | ⬜ |
| TC-P09 | Pagination | 11+ incidents → pagination appears with page 2 showing remaining incidents | — | — | ⬜ |
| TC-P10 | Resolve via SweetAlert Confirmation | Click Resolve → Swal dialog → Confirm → incident resolved | — | — | ⬜ |
| TC-P11 | Severity Badge Styling | LOW=bg-secondary, MEDIUM=bg-warning, HIGH=bg-danger | — | — | ⬜ |
| TC-P12 | Status Badge Styling | OPEN=bg-danger badge, RESOLVED=bg-success badge | — | — | ⬜ |
| TC-P13 | Resolved By Shows Name | After resolve, resolved_by column shows user name on next page load | — | — | ⬜ |
| TC-P14 | Resolved At Shows Timestamp | After resolve, resolved_at column shows formatted datetime on next page load | — | — | ⬜ |
| TC-P15 | Multiple Filters Combined | incident_type + status + date_range all applied simultaneously → intersection of conditions | — | — | ⬜ |
| TC-P16 | Filter Clear Resets Grid | Click Clear after applying filters → all filters cleared, full dataset shown | — | — | ⬜ |
| TC-P17 | Trip Management Page Loads Without Tab Parameter | `/transport/trip-management` (no ?tab=) → default tab loads (first tab in hub) | — | — | ⬜ |
| TC-P18 | Incident Loop Count Shows Correctly | `$loop->iteration` increments per page correctly | — | — | ⬜ |

### 6.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Resolve Already-Resolved Incident | GET `/transport/trip-incident/{id}/resolve` for status=1 incident → back with warning 'already resolved' | — | — | ⬜ |
| TC-N02 | Resolve Non-Existent Incident | GET `/transport/trip-incident/99999/resolve` → findOrFail → 404 | — | — | ⬜ |
| TC-N03 | Permission 403 — No incident.resolve | User without `tenant.trip.incident.resolve` → 403 on GET resolve | — | — | ⬜ |
| TC-N04 | Guest Access | Redirect to `/login` | — | — | ⬜ |
| TC-N05 | Emergency without remark | stopAction creates incident with description=null | — | — | ⬜ |
| TC-N06 | Permission 403 — No transport.viewAny (page access) | GET `/transport/trip-management` without `tenant.transport.viewAny` → 403 | — | — | ⬜ |
| TC-N07 | Tab Hidden — No trip.incident.viewAny | Has `tenant.transport.viewAny` but NOT `tenant.trip.incident.viewAny` → page loads but Trip Incidents tab not visible | — | — | ⬜ |
| TC-N08 | Permission 403 — No resolve permission but has status permission | User sees Resolve button (via `tenant.trip.incident.status` blade check) but gets 403 when clicking (no `tenant.trip.incident.resolve`) | — | — | ⬜ |
| TC-N09 | Invalid Date Range Format | date_range with wrong format → parse error → 500 (no try/catch in incidentQuery) | — | — | ⬜ |
| TC-N10 | Trip Deletion While Incidents Exist | Delete trip → incidents cascade deleted (DDL CASCADE) | — | — | ⬜ |
| TC-N11 | Negative or Zero ID in Resolve URL | `/transport/trip-incident/-1/resolve` or `/transport/trip-incident/0/resolve` → findOrFail throws ModelNotFoundException → 404 | — | — | ⬜ |
| TC-N12 | Non-integer ID in Resolve URL | [Query/Code Removed] | — | — | ⬜ |
| TC-N13 | Date Range with Only Start Date | date_range="2026-06-01" (no " - " separator) → condition `str_contains($range, ' - ')` is false → filter silently skipped → shows all records | — | — | ⬜ |
| TC-N14 | Empty Incident Type Filter | incident_type="" → `filled('incident_type')` is false → filter not applied | — | — | ⬜ |
| TC-N15 | status=2 (Invalid Status Value) | Filter by status=2 → where('status', 2) returns empty set since no incident has status=2 | — | — | ⬜ |
| TC-N16 | Duplicate Emergency Trigger | Call stopAction('emergency') twice for same stop → two incidents created (no duplicate prevention) | — | — | ⬜ |
| TC-N17 | Trip Not Found for Emergency | Call stopAction('emergency') with nonexistent stop_id → 404 on find() before emergency logic | — | — | ⬜ |
| TC-N18 | No Trips Exist for Emergency | Call stopAction('emergency') with new_ ID but no trip for today → JSON 404 'No active trip scheduled' | — | — | ⬜ |
| TC-N19 | Route Scheduler Missing driver_id | stopAction('emergency') with routeScheduler that has null driver_id → raised_by set to null | — | — | ⬜ |
| TC-N20 | Cross-tab Pagination Conflict | Paginate on one tab, switch tabs, paginate on incidents tab → incident pagination should remain independent | — | — | ⬜ |

### 6.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Trip Deletion — Incidents Cascade | DDL CASCADE → related incidents auto-deleted | — | — | ⬜ |
| TC-D02 | B | RaisedBy/ResolvedBy User — SET NULL | User deletion → raised_by/resolved_by becomes NULL | — | — | ⬜ |

### 6.3b Exploration / Deep-Dive Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-EX-01 | EXPLORE | P2 | scopeHighSeverity returns empty due to undefined constant | Call TptTripIncidents::highSeverity()->get() → executes `where('severity', null)` → returns empty collection even if HIGH severity records exist | — | — | ◌ |
| TC-EX-02 | EXPLORE | P2 | scopeOpen returns incidents with resolved_at=null but status=1 | Set status=1, resolved_at=null → scopeOpen() includes it incorrectly | — | — | ◌ |
| TC-EX-03 | EXPLORE | P3 | raisedTo() relationship at runtime | Access `$incident->raisedTo` → QueryException: Column not found 'raised_to' | — | — | ◌ |
| TC-EX-04 | EXPLORE | P3 | incidentType() relationship at runtime | Access `$incident->incidentType` → ClassNotFoundException: TptIncidentType | — | — | ◌ |
| TC-EX-05 | EXPLORE | P3 | statusMaster() relationship at runtime | Access `$incident->statusMaster` → ClassNotFoundException: TptIncidentStatus | — | — | ◌ |
| TC-EX-06 | EXPLORE | P2 | Non-super-admin resolve attempt | User with roles but NOT super_admin calls resolve → 403 because `tenant.trip.incident.resolve` not in permissionslist.php | — | — | ◌ |
| TC-EX-07 | EXPLORE | P2 | activityLog called before update in resolveIncident | If update() throws, activityLog already recorded → audit trail shows event that didn't complete | — | — | ◌ |
| TC-EX-08 | EXPLORE | P3 | Flash message text for resolve | `flash('restored.Incident')` displays incorrect verb (shows 'restored' instead of 'resolved') | — | — | ◌ |
| TC-EX-09 | EXPLORE | P2 | Multiple filters with invalid combination | incident_type=0 + status=0 + date_range that includes no type=0 open incidents → empty result | — | — | ◌ |
| TC-EX-10 | EXPLORE | P3 | Incident created with null raised_by | routeScheduler driver_id is null → raised_by in incident is null → raisedByUser/raisedBy return null | — | — | ◌ |

### 6.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Controller — Gate::authorize() in resolveIncident | `Gate::authorize('tenant.trip.incident.resolve')` present | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — Double-resolve prevention | `if ($incident->status == 1)` check before update | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — activityLog on resolve | Logged with 'Toggled' event | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — No CRUD (create/edit/destroy) | Only listing via TripMgmtController and one resolve action | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — No way to edit incident details | No route/method for updating description, severity, etc. | — | — | ◌ |
| TC-CR06 | CR | P1 | Controller — No way to delete incidents | No destroy/forceDelete/trash operations | — | — | ◌ |
| TC-CR07 | CR | P1 | Model — Table Name | `protected $table = 'tpt_trip_incidents'` | — | — | ◌ |
| TC-CR08 | CR | P1 | Model — Fillable Fields | 12 fillable fields: trip_id, incident_time, incident_type, severity, latitude, longitude, description, status, raised_by, raised_at, resolved_at, resolved_by | — | — | ◌ |
| TC-CR09 | CR | P1 | Model — Constants Defined | TYPE[0..3], STATUS[0,1], SEVERITY[LOW/MEDIUM/HIGH] | — | — | ◌ |
| TC-CR10 | CR | P1 | Model — Relationships | trip, raisedByUser, incidentType, statusMaster, raisedBy, raisedTo, resolvedBy — 7 relationships | — | — | ◌ |
| TC-CR11 | CR | P1 | Model — Accessors | `getIncidentTypeLabelAttribute()`, `getStatusLabelAttribute()` | — | — | ◌ |
| TC-CR12 | CR | P1 | Model — Scopes | `scopeOpen()`: whereNull('resolved_at'); `scopeHighSeverity()`: where('severity', self::SEVERITY_HIGH) — NOTE: SEVERITY_HIGH constant is NOT defined (uses array SEVERITY, not individual constants) — code bug | — | — | ◌ |
| TC-CR13 | CR | P1 | DDL — FK Constraints | trip_id CASCADE, raised_by SET NULL, resolved_by SET NULL | — | — | ◌ |
| TC-CR14 | CR | P1 | Routes — resolveIncident | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])` — GET for state mutation (route prefix `transport` → URL `/transport/trip-incident/{id}/resolve`) | — | — | ◌ |
| TC-CR15 | CR | P1 | Gap — GET used for mutation (resolve) | Resolving an incident via GET violates HTTP spec | — | — | ◌ |
| TC-CR16 | CR | P1 | Gap — No incident_type validation in stopAction | Always creates incident_type=0 regardless of actual incident type | — | — | ◌ |
| TC-CR17 | CR | P1 | Gap — No incident soft delete/restore/forceDelete | SoftDeletes trait exists but no routes or methods | — | — | ◌ |
| TC-CR18 | CR | P1 | Gap — No dedicated IncidentController | All incident logic mixed into TripMgmtController and TripController | — | — | ◌ |
| TC-CR19 | CR | P1 | TripMgmtController — incidentQuery filters | incident_type, status, date_range filters | — | — | ◌ |
| TC-CR20 | CR | P1 | Gap — No activityLog on incident creation | stopAction('emergency') creates incident without calling activityLog | — | — | ◌ |
| TC-CR21 | CR | P1 | Gate mismatch — controller vs blade permission | Controller index() uses `tenant.transport.viewAny`, but blade tab uses `tenant.trip.incident.viewAny` — two different permission keys guard access | — | — | ◌ |
| TC-CR22 | CR | P1 | `resolve` action NOT in permissionslist.php $crud | `$crud` array lacks `resolve` action, so `tenant.trip.incident.resolve` will never match a real permission (only works via super_admin bypass) | — | — | ◌ |
| TC-CR23 | CR | P1 | scopeHighSeverity references undefined constant | `self::SEVERITY_HIGH` is not defined (SEVERITY is an array constant `self::SEVERITY['HIGH']`) | — | — | ◌ |
| TC-CR24 | CR | P1 | raisedTo() relationship references non-existent column | Model has `raisedTo()` → `raised_to` FK, but migration has NO `raised_to` column | — | — | ◌ |
| TC-CR25 | CR | P1 | incidentType() / statusMaster() reference non-existent models | `TptIncidentType` and `TptIncidentStatus` models do not exist in codebase | — | — | ◌ |
| TC-CR26 | CR | P1 | Blade — @canany/@endcan directive mismatch | Blade line 69 uses @canany but closes with @endcan (line 71) instead of @endcanany | — | — | ◌ |
| TC-CR27 | CR | P1 | Blade — @canany with single element | `@canany(['tenant.trip.incident.status'])` should be `@can('tenant.trip.incident.status')` | — | — | ◌ |
| TC-CR28 | CR | P2 | activityLog order — logged before DB update | If update() exceptions, activityLog still records 'Incident status updated' | — | — | ◌ |
| TC-CR29 | CR | P2 | activityLog event name — 'Toggled' for resolve | 'Toggled' is semantically incorrect for a resolve (forward-only) operation | — | — | ◌ |
| TC-CR30 | CR | P2 | Flash message — 'restored' instead of 'resolved' | `flash('restored.Incident')` uses locale key for restore, not resolve | — | — | ◌ |
| TC-CR31 | CR | P2 | severity hardcoded to 'MEDIUM' in stopAction | All emergency incidents have severity=MEDIUM, no way to specify LOW/HIGH | — | — | ◌ |
| TC-CR32 | CR | P2 | incident_type hardcoded to 0 in stopAction | All emergency incidents have incident_type=0 (StopEmergency), cannot create VehicleBreakdown/Accident/RouteBlocked | — | — | ◌ |
| TC-CR33 | CR | P2 | raised_by stores driver_id not auth user | `raised_by=optional($trip->routeScheduler)->driver_id` — non-obvious behavior | — | — | ◌ |
| TC-CR34 | CR | P2 | Model class referenced directly in blade | Line 14: `\Modules\Transport\Models\TptTripIncidents::TYPE` — view coupled to model constant | — | — | ◌ |
| TC-CR35 | CR | P2 | JS references non-existent .start_date/.end_date elements | js.blade.php lines 55-56 jQuery selectors return empty set | — | — | ◌ |
| TC-CR36 | CR | P2 | Pagination uses withQueryString() not appends(['tab']) | Tab context may be lost if query string is manipulated | — | — | ◌ |
| TC-CR37 | CR | P2 | Policy defines 16 methods, only 1 used by controller | 15 of 16 policy methods are dead code | — | — | ◌ |
| TC-CR38 | CR | P2 | TripMgmtPolicy references non-existent permission group | Uses `tenant.trip-management.*` which is NOT in permissionslist.php | — | — | ◌ |
| TC-CR39 | CR | P2 | No DB indexes on filter columns | incident_type, status, incident_time have no indexes | — | — | ◌ |
| TC-CR40 | CR | P2 | DDL enum order differs from model constant order | DDL: `['HIGH','LOW','MEDIUM']`, Model: `['LOW'=>'LOW', 'MEDIUM'=>'MEDIUM', 'HIGH'=>'HIGH']` | — | — | ◌ |
| TC-CR41 | CR | P2 | scopeOpen uses resolved_at check not status check | Should check status=0, not resolved_at IS NULL | — | — | ◌ |
| TC-CR42 | CR | P2 | No incident_time fallback in model | DDL: incident_time NOT NULL, Model: no default/booted fallback. If created programmatically without incident_time → DB error | — | — | ◌ |
| TC-CR43 | CR | P2 | [Query/Code Removed] | Non-integer IDs may not properly 404 | — | — | ◌ |
| TC-CR44 | CR | P3 | Date range parsing has no try/catch | [Query/Code Removed] | — | — | ◌ |
| TC-CR45 | CR | P2 | No DB::transaction() around emergency creation | Stop update + incident create not in transaction → partial failure possible | — | — | ◌ |
| TC-CR46 | CR | P2 | No duplicate prevention for emergency | Multiple stopAction('emergency') for same stop creates duplicate incidents | — | — | ◌ |
| TC-CR47 | CR | P3 | `$updatedBy` and `$raisedBy` use same source | Both set to `optional($trip->routeScheduler)->driver_id` — redundant variables | — | — | ◌ |
| TC-CR48 | CR | P2 | No notification log for emergency action | Unlike start_trip, reach, leave — emergency creates no TptNotificationLog | — | — | ◌ |

---

## 7. Detailed Test Steps

### TC-P01: Incident Tab Loads

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with permissions: `tenant.transport.viewAny`, `tenant.trip.incident.viewAny` | Dashboard/landing page loads |
| 2 | Navigate to `/transport/trip-management?tab=trip_incidents` | Page loads without 403 error |
| 3 | Inspect page for Trip Incidents tab | Tab is visible in the nav-tab bar with label "Trip Incidents" and icon `fa-triangle-exclamation` |
| 4 | Click the Trip Incidents tab | Tab pane becomes active (fade in + show class) |
| 5 | Inspect filter bar | Filter bar visible with: Incident Type dropdown, Status dropdown, Date Range picker, Filter button |
| 6 | Inspect incident grid | Table visible with columns: #, Incident Time, Type, Severity, Description, Status, Resolved At, Resolved By, Action |
| 7 | Verify table header classes | `<thead class="table-light">` present |

### TC-P02: Incident Created via Emergency Action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Setup: Create a route, driver, vehicle, routeScheduler (with driver_id), and PickupPointRoute record | Pre-requisite data exists |
| 2 | Start a trip via stopAction start_trip | Trip status='Ongoing' |
| 3 | POST `/transport/trip/stop-action` with action=emergency, id=existing_stop_detail_id, remark="Flat tire encountered" | JSON success with `{"status": true, "message": "Stop updated successfully", "time": "..."}` |
| 4 | [Query/Code Removed] | Record exists |
| 5 | Verify incident_type field | `incident_type` = 0 |
| 6 | Verify severity field | `severity` = 'MEDIUM' |
| 7 | Verify description field | `description` = 'Flat tire encountered' |
| 8 | Verify status field | `status` = 0 |
| 9 | Verify raised_by field | `raised_by` = driver_id from routeScheduler (NOT auth user id) |
| 10 | Verify raised_at field | `raised_at` = current timestamp (within tolerance of test execution) |
| 11 | Verify incident_time field | `incident_time` matches the timestamp of the stopAction call |
| 12 | Navigate to Trip Incidents tab | Incident visible in grid with type='Stop Emergency', status='OPEN', severity='MEDIUM' |
| 13 | Check activity_log table | No activity_log entry for incident creation (confirmed gap — BC-BIZ-DEEP-02) |

### TC-P03: View Incident in List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a test incident with incident_type=1, severity='HIGH', status=0 | Incident data prepared |
| 2 | Navigate to Trip Incidents tab | Incident appears in grid |
| 3 | Verify Incident Time column | Shows formatted datetime: `d M Y, h:i A` (e.g., "22 Jul 2026, 10:30 AM") |
| 4 | Verify Type column | Shows `incident_type_label` (e.g., "Vehicle Breakdown") wrapped in `badge bg-info` |
| 5 | Verify Severity column | Shows severity text in color-coded badge: HIGH=bg-danger, MEDIUM=bg-warning, LOW=bg-secondary |
| 6 | Verify Description column | Shows description text |
| 7 | Verify Status column | Shows `status_label` ("OPEN" or "RESOLVED") in badge: OPEN=bg-danger, RESOLVED=bg-success |
| 8 | Verify Resolved At column | Shows "-" for unresolved, formatted datetime for resolved |
| 9 | Verify Resolved By column | Shows "-" for unresolved, user name for resolved |
| 10 | Verify Action column | For OPEN: Resolve button visible (if user has `tenant.trip.incident.status`). For RESOLVED: "Completed" text shown |

### TC-P04: Resolve Open Incident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a test incident with status=0, resolved_at=NULL, resolved_by=NULL | Open incident available |
| 2 | Verify user has `tenant.trip.incident.resolve` permission | Gate passes (note: may need super_admin due to BC-AUTH-GAP-06) |
| 3 | GET `/transport/trip-incident/{id}/resolve` (or click Resolve button + confirm in Swal) | Redirect back with 'success' flash message |
| 4 | DB check: `SELECT status, resolved_at, resolved_by FROM tpt_trip_incidents WHERE id={id}` | status=1, resolved_at=not null (current timestamp), resolved_by=auth()->id() |
| 5 | Navigate to Trip Incidents tab | Incident now shows status='RESOLVED' (green badge), Resolved At column shows timestamp, Resolved By column shows current user name |
| 6 | Action column now shows "Completed" text instead of Resolve button | Text is `<span class="text-muted">Completed</span>` |
| 7 | Check activity_log table | Entry exists with event='Toggled', message='Incident status updated.', performed_by=auth user name |

### TC-P05: Filter by Incident Type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 incidents: incident_type=0 (StopEmergency), incident_type=1 (VehicleBreakdown), incident_type=2 (Accident) | Incidents with different types |
| 2 | Navigate to Trip Incidents tab | All 3 incidents visible |
| 3 | Select "Stop Emergency" (type=0) from Incident Type dropdown | Filter applied |
| 4 | Click Filter button | Only Stop Emergency type incident visible |
| 5 | Select "Vehicle Breakdown" (type=1) | Only Vehicle Breakdown incident visible |
| 6 | Select "All Types" | All 3 incidents visible again |
| 7 | Verify URL contains `incident_type` parameter | URL: `/transport/trip-management?tab=trip_incidents&incident_type=1` |

### TC-P06: Filter by Status (OPEN / RESOLVED)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 incidents: one OPEN (status=0), one RESOLVED (status=1) | Incidents in both states |
| 2 | Navigate to Trip Incidents tab | Both incidents visible |
| 3 | Select "OPEN" (status=0) from Status dropdown | Only OPEN incident visible |
| 4 | Select "RESOLVED" (status=1) from Status dropdown | Only RESOLVED incident visible |
| 5 | Select "All Status" | Both incidents visible |
| 6 | Verify URL contains status parameter | URL: `/transport/trip-management?tab=trip_incidents&status=0` |

### TC-P07: Filter by Date Range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 3 incidents: incident_time=2026-06-01, 2026-06-15, 2026-07-01 | Incidents on different dates |
| 2 | Navigate to Trip Incidents tab | All 3 incidents visible |
| 3 | Use date range picker to select 2026-06-01 to 2026-06-20 | Filter applied |
| 4 | Click Filter button | Only incidents from June 1-20 visible (first 2) |
| 5 | Change date range to 2026-06-20 to 2026-07-05 | Only July 1 incident visible |
| 6 | Verify URL contains date_range parameter | URL: `/transport/trip-management?tab=trip_incidents&date_range=2026-06-01+-+2026-06-20` |
| 7 | Click Clear button | All incidents visible, date range cleared |

### TC-P08: Empty State — No Incidents

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no incidents exist for any trip (truncate or work on fresh DB) | No incident records |
| 2 | Navigate to Trip Incidents tab | Table body shows empty state row: `<tr><td colspan="9" class="text-center text-muted py-3">No incidents found</td></tr>` |
| 3 | Verify colspan=9 | All 9 columns merged in empty state |
| 4 | Verify pagination section | Pagination hidden (no pages when data empty) |

### TC-P09: Pagination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 12 incidents (paginate(10) → should show 2 pages) | 12 incidents exist |
| 2 | Navigate to Trip Incidents tab | Page 1: 10 incidents visible, pagination controls at bottom |
| 3 | Click page 2 | Page 2: 2 incidents visible |
| 4 | Verify # column restarts at 1 on page 2 | `$loop->iteration` = 1 for first item on page 2 |
| 5 | Navigate back to page 1 | Page 1 shows fully again |
| 6 | Verify page parameter in URL | URL: `/transport/trip-management?tab=trip_incidents&page=2` |

### TC-P10: Resolve via SweetAlert Confirmation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trip Incidents tab with at least one OPEN incident | Resolve button visible (green `btn btn-sm btn-success`) |
| 2 | Click Resolve button | SweetAlert2 dialog appears: title="Are you sure?", text="Do you want to mark this incident as resolved?", icon="warning", confirmButton="Yes, Resolve", cancelButton="Cancel" |
| 3 | Click Cancel | Dialog closes, no action taken |
| 4 | Click Resolve button again, then click "Yes, Resolve" | Browser navigates to `/transport/trip-incident/{id}/resolve` |
| 5 | Page reloads after redirect | Incident status updated to RESOLVED |

### TC-N01: Resolve Already-Resolved Incident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an incident with status=0 | Open incident |
| 2 | Resolve incident first time | GET resolves successfully; status=1 |
| 3 | Resolve same incident again | GET `/transport/trip-incident/{id}/resolve` |
| 4 | Check response | Redirect back with 'warning' flash: 'Incident already resolved.' |
| 5 | DB check | status remains 1; resolved_at unchanged |

### TC-N02: Resolve Non-Existent Incident

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure incident with ID 99999 does NOT exist | No record |
| 2 | GET `/transport/trip-incident/99999/resolve` | `ModelNotFoundException` thrown by `findOrFail(99999)` |
| 3 | Check HTTP response | 404 Not Found returned |
| 4 | Check Laravel debug | If APP_DEBUG=true: ModelNotFoundException details shown. If APP_DEBUG=false: Generic 404 page. |

### TC-N03: Permission 403 — No incident.resolve

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.trip.incident.resolve` (non-super_admin) | Auth as limited user |
| 2 | GET `/transport/trip-incident/{id}/resolve` | `Gate::authorize('tenant.trip.incident.resolve')` throws `AuthorizationException` |
| 3 | Check HTTP response | 403 Forbidden |
| 4 | Verify | Message: "This action is unauthorized." (default Laravel 403 message) |

### TC-N04: Guest Access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout or use incognito session | Not authenticated |
| 2 | GET `/transport/trip-management?tab=trip_incidents` | Redirected to `/login` (Laravel auth middleware) |
| 3 | GET `/transport/trip-incident/1/resolve` | Redirected to `/login` |

### TC-N05: Emergency without remark

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/stop-action` with action=emergency, id=existing_stop_detail_id, NO remark field | JSON success |
| 2 | DB check: incident created | Incident exists with description=NULL |
| 3 | Navigate to Trip Incidents tab | Incident visible with empty Description column |

### TC-N06: Permission 403 — No transport.viewAny (page access)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.transport.viewAny` | Auth as limited user |
| 2 | GET `/transport/trip-management` | `Gate::authorize('tenant.transport.viewAny')` throws AuthorizationException |
| 3 | Check HTTP response | 403 Forbidden |

### TC-N07: Tab Hidden — No trip.incident.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.transport.viewAny` but WITHOUT `tenant.trip.incident.viewAny` | Auth with limited tab permissions |
| 2 | GET `/transport/trip-management` | Page loads, no 403 |
| 3 | Check tab navigation | Trip Incidents tab NOT visible in the nav-tab list |
| 4 | Inspect DOM for `trip_incidents-pane` | Partial NOT rendered (wrapped in `@can('tenant.trip.incident.viewAny')`) |
| 5 | Direct URL: GET `/transport/trip-management?tab=trip_incidents` | Tab parameter ignored (tab content not rendered, falls back to default tab) |

### TC-N08: Button Visible but Action Returns 403

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.trip.incident.status` but WITHOUT `tenant.trip.incident.resolve` | Auth with partial permissions |
| 2 | Navigate to Trip Incidents tab with an OPEN incident | Resolve button is visible because `@canany(['tenant.trip.incident.status'])` passes |
| 3 | Click Resolve button → confirm in Swal | Browser navigates to `/transport/trip-incident/{id}/resolve` |
| 4 | GET request hits `Gate::authorize('tenant.trip.incident.resolve')` | 403 Forbidden (or 500 if super_admin bypass not configured) |
| 5 | User sees 403 page | UX inconsistency: button visible but action forbidden |

### TC-N09: Invalid Date Range Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Trip Incidents tab | Grid loads normally |
| 2 | Manually set date_range parameter: `date_range=invalid-date` | Submit form |
| 3 | Check incidentQuery code path | `$request->filled('date_range')` is true → `trim('invalid-date')` → `str_contains('invalid-date', ' - ')` is false → filter skipped |
| 4 | Result | All incidents shown, no error (filter silently dropped) |
| 5 | Set date_range to something that passes str_contains: `date_range=not-a-date - also-not-a-date` | Submit form |
| 6 | [Query/Code Removed] | `InvalidArgumentException` thrown → 500 error (no try/catch) |

### TC-N16: Duplicate Emergency Trigger

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/transport/trip/stop-action` with action=emergency, id=existing_stop, remark="First" | JSON success, 1 incident created |
| 2 | POST `/transport/trip/stop-action` with action=emergency, id=existing_stop, remark="Second" | JSON success, 2nd incident created |
| 3 | DB check: count incidents for this trip | 2 incidents exist (no duplicate prevention) |
| 4 | Both incidents appear in grid | Two entries with same trip_id but different incident_time and description |

### TC-CR15: Gap — GET used for mutation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `web.php` route line 56 | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])` — uses GET |
| 2 | Check CSRF protection | GET routes have no CSRF token requirement |
| 3 | Security implication | CSRF not required; browser prefetch could trigger resolve |
| 4 | Check `<a>` tag in blade line 122 | `<a href="{{ route('transport.trip.incident.resolve', $incident->id) }}">` — standard anchor tag, makes GET request |
| 5 | Verify no `<form>` with POST | No POST form exists for resolve action |

### TC-CR20: Gap — No activityLog on incident creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect TripController.php stopAction() | Read lines 277-296 (case 'emergency') |
| 2 | [Query/Code Removed] | No activityLog call present after incident creation |
| 3 | Compare with resolveIncident() | resolveIncident() at line 435 calls activityLog — inconsistency confirmed |

### TC-CR22: Gap — resolve NOT in permissionslist.php $crud

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open `config/permissionslist.php` | Read the file |
| 2 | Inspect `$crud` array (lines 13-31) | Array elements: create, view, viewAny, update, delete, restore, forceDelete, import, export, print, publish, status, email-schedule, remark, pdf, edit, approve — NO `resolve` |
| 3 | Check `trip.incident` group (line 324) | `'trip.incident' => $crud` — expands to all $crud actions but NOT resolve |
| 4 | Verify no resolve-specific entry | No `'trip.incident.resolve' => ['resolve']` elsewhere in file |
| 5 | Conclude | Permission `tenant.trip.incident.resolve` does NOT exist in permissionslist.php → Role assignment UIs cannot assign this permission → Only super_admin bypass works |

### TC-CR23: Gap — scopeHighSeverity undefined constant

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open TptTripIncidents.php | Read model file |
| 2 | Inspect SEVERITY constant (line 60-64) | `const SEVERITY = ['LOW' => 'LOW', 'MEDIUM' => 'MEDIUM', 'HIGH' => 'HIGH']` — array constant |
| 3 | Inspect scopeHighSeverity (line 132-135) | [Query/Code Removed] |
| 4 | Search for SEVERITY_HIGH definition | No separate `const SEVERITY_HIGH` exists in the file |
| 5 | Conclude | `self::SEVERITY_HIGH` evaluates to `null`. `where('severity', null)` returns no records. |

### TC-CT-01: CODE-TRACE — TripMgmtController@index → incidentQuery

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Route matched | web.php:53 | `Route::resource('trip-management', TripMgmtController::class)` → index() called for GET /transport/trip-management |
| 2 | Gate check | TripMgmtController.php:38 | `Gate::authorize('tenant.transport.viewAny')` — must pass or 403 |
| 3 | Driver query | TripMgmtController.php:40-51 | `Auth::user()->id` → lookup DriverHelper → get driver route IDs |
| 4 | Trip ID resolution | TripMgmtController.php:54-71 | Find TptTrip matching request->date + filters → merge trip_id/tripe_id into request |
| 5 | Reference data | TripMgmtController.php:73-80 | Load vehicles, routes, driverHelpers, shifts, etc. |
| 6 | incidentData call | TripMgmtController.php:87 | `$incidentData = $this->incidentQuery($request)->paginate(10)->withQueryString();` |
| 7 | incidentQuery | TripMgmtController.php:449-485 | [Query/Code Removed] |
| 8 | Pagination | TripMgmtController.php:87 | `paginate(10)->withQueryString()` — 10 per page |
| 9 | View compact | TripMgmtController.php:92-111 | `return view('transport::tab_module.tripmanagement', compact('incidentData', ...));` |
| 10 | Blade renders | tripmanagement.blade.php:43-44 | `@can('tenant.trip.incident.viewAny') @include('transport::trip-incidents.index') @endcan` |

### TC-CT-02: CODE-TRACE — TripController@stopAction → emergency

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Route matched | web.php:163 | `Route::post('trip/stop-action', [TripController::class, 'stopAction'])` |
| 2 | Gate check | TripController.php:125 | `Gate::authorize('tenant.stop-details.update')` |
| 3 | ID parsing | TripController.php:127-181 | Check if ID is 'new_' prefixed → find or create TptTripStopDetail |
| 4 | Driver/raised_by | TripController.php:184-185 | `$raisedBy = optional($trip->routeScheduler)->driver_id;` |
| 5 | Switch dispatch | TripController.php:187 | `switch ($request->action)` — matches 'emergency' |
| 6 | Stop update | TripController.php:278-283 | [Query/Code Removed] |
| 7 | Incident create | TripController.php:285-294 | [Query/Code Removed] |
| 8 | Break + response | TripController.php:297-304 | `return response()->json(['status'=>true, ...]);` |

### TC-CT-03: CODE-TRACE — TripMgmtController@resolveIncident

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Route matched | web.php:56 | `Route::get('trip-incident/{id}/resolve', [TripMgmtController::class, 'resolveIncident'])` |
| 2 | Method called | TripMgmtController.php:424 | `public function resolveIncident($id)` |
| 3 | Gate check | TripMgmtController.php:426 | `Gate::authorize('tenant.trip.incident.resolve')` — permission not in permissionslist.php |
| 4 | Find incident | TripMgmtController.php:428 | `$incident = TptTripIncidents::findOrFail($id);` |
| 5 | Double-resolve check | TripMgmtController.php:430-433 | `if ($incident->status == 1) { return back()->with('warning', ...); }` |
| 6 | Activity log (BEFORE update) | TripMgmtController.php:435-438 | `activityLog($incident, 'Toggled', [...])` — logged BEFORE DB mutation |
| 7 | DB update | TripMgmtController.php:440-444 | [Query/Code Removed] |
| 8 | Redirect | TripMgmtController.php:446 | `return redirect()->back()->with('success', flash('restored.Incident'));` |

### TC-CT-04: CODE-TRACE — Blade rendering chain

| Step # | Trace Point | File:Line | Code |
|--------|------------|-----------|------|
| 1 | Hub layout loads | tripmanagement.blade.php:1-4 | `<x-backend.layouts.app>` → breadcrum "Trip Management" |
| 2 | Tab nav renders | tripmanagement.blade.php:9-24 | Tab entry: `'permission' => 'tenant.trip.incident.viewAny'` |
| 3 | Permission check | tripmanagement.blade.php:43 | `@can('tenant.trip.incident.viewAny')` |
| 4 | Partial included | tripmanagement.blade.php:44 | `@include('transport::trip-incidents.index')` |
| 5 | Tab pane div | index.blade.php:1-5 | `<div class="tab-pane fade ..." id="trip_incidents-pane">` |
| 6 | Filter form | index.blade.php:8-54 | GET form with tab input, filters, Filter + Clear buttons |
| 7 | Table header | index.blade.php:59-72 | `<thead>` with `@canany` wrapping Action `<th>` |
| 8 | Table body loop | index.blade.php:76-138 | `@forelse($incidentData as $incident)` — renders all columns |
| 9 | Empty state | index.blade.php:132-138 | `@empty` — "No incidents found" colspan=9 |
| 10 | Pagination | index.blade.php:144-146 | `{{ $incidentData->withQueryString()->links() }}` |
| 11 | JS includes | index.blade.php:151 | `@include('transport::trip-incidents.js.js')` |

### TC-EX-01: scopeHighSeverity returns empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a HIGH severity incident | [Query/Code Removed] |
| 2 | Call `TptTripIncidents::highSeverity()->get()` | Returns empty collection (bug) |
| 3 | Verify SQL | `WHERE severity = NULL` — always false |
| 4 | Root cause | `self::SEVERITY_HIGH` is undefined constant → `null` |

### TC-EX-06: Non-super-admin resolve attempt

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as non-super_admin user | Standard role-based user |
| 2 | Assign all `trip.incident.*` permissions via role UI | Includes CRUD but NOT resolve |
| 3 | GET `/transport/trip-incident/{id}/resolve` | 403 Forbidden |
| 4 | Reason | `resolve` is not in permissionslist.php $crud array |
| 5 | Conclusion | Only super_admin can resolve incidents in production |

### TC-D01: Trip Deletion — Incidents Cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create trip with incidents | Trip + incidents exist |
| 2 | Note incident count | [Query/Code Removed] |
| 3 | Delete the trip | `DELETE FROM tpt_trip WHERE id={id}` |
| 4 | Recheck incident count | 0 (CASCADE deleted) |

### TC-D02: RaisedBy/ResolvedBy User — SET NULL

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Identify a user referenced in raised_by | `SELECT raised_by FROM tpt_trip_incidents WHERE raised_by IS NOT NULL LIMIT 1` |
| 2 | Delete that user | `DELETE FROM sys_users WHERE id={userId}` |
| 3 | Recheck incidents | `raised_by` is NULL (SET NULL) |
| 4 | Repeat for resolved_by | Same behavior |

(End of file - total 1558 lines)
