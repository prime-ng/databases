# Route Master — Business Requirements

## What This Screen Does

The Route Master screen defines the paths that school buses follow. Each route carries a code and name, a direction (Pickup or Drop), a link to a specific shift, an optional description, and a spatial geometry column designed to store the exact GPS path of the route on a map. Routes are the structural backbone of everything the Transport module does — daily trips are generated from routes, drivers and vehicles are assigned per route, and students are allocated to stops that belong to routes.

This screen transforms a chaotic collection of buses and drivers into an organised fleet with predictable paths. Without routes, there would be no way to tell the system that Bus 1 follows the MG Road corridor in the morning while Bus 2 takes the Church Street corridor in the afternoon. The Transport Manager would have no mechanism to standardise where each bus goes, which stops it visits, or what time it should arrive — every day would require manual coordination and verbal instructions. By defining routes upfront, the school ensures that every bus operates on a predictable schedule that parents can rely on and the system can enforce.

The screen appears in two contexts:
1. **Transport Master → Route tab** — Paginated list loaded by `TransportMasterController@routesQuery()`.
2. **Standalone CRUD** — Full resource via `RouteController` with create/edit/show/trash/restore/forceDelete/toggleStatus.

---

## Default Data Load

When the user navigates to Transport Master → Route tab, `TransportMasterController@routesQuery()` runs `Route::with('shift')->where('shift_id', ...)` with tab-specific search (name/code/description) and status filters, paginated 10 per page.

When accessed standalone, `RouteController@index()` runs `Route::with('shift')->paginate(10)`.

---

## When This Screen Is Used

- **Start-of-Year Route Planning** — At the beginning of each academic year (or whenever the school's transport routes change), the Transport Manager sits down to define every bus path for the upcoming session. They create separate pickup routes for each shift — for example, a Morning Pickup route for students living near MG Road, and a different Afternoon Drop route covering the same area. This is a once-per-year configuration activity that sets the foundation for all daily operations that follow.

- **Adding a New Stop to a Route** — When a new housing colony develops near the school and new parents request bus service, the Transport Manager cannot simply add the new stop to thin air. The route must already exist in the system. Only after the route is defined can the manager open the Assign Stops screen and insert the new stop at the correct ordinal position within the route's sequence.

- **Driver-Vehicle Pairing** — Before the Transport Manager can tell the system "Driver Ram is driving Bus KL-01 on the MG Road route tomorrow," the MG Road route must already be registered in the Route Master. The Driver-Route-Vehicle assignment screen draws routes from this master list.

- **Trip Generation and Daily Operations** — Every morning, the system generates trips based on the routes defined here. If a route is missing or misconfigured, the trip for that entire corridor fails to generate, leaving students stranded and parents calling the school office. The accuracy of this screen directly determines whether the fleet runs smoothly or descends into chaos.

---

## Key Fields at a Glance

**Route Identity and Description**
Every route needs a short code like "MG-PK-01" that fits in dropdowns and reports, and a full descriptive name like "MG Road Morning Pickup Route" that clearly communicates the route's purpose to anyone reading a trip schedule. An optional description field of up to 500 characters allows the manager to add notes like "This route covers the main arterial road and has three sharp U-turns — only experienced drivers should be assigned."

**Direction and Shift Assignment**
Each route has a direction — either Pickup (bringing students from home to school) or Drop (taking students from school back home). This distinction matters because the same bus and driver might run a pickup route in the morning and a completely different drop route in the afternoon. Every route is locked to a specific shift (Morning, Afternoon, or Evening), ensuring that route planning stays within the correct time window.

**Map Geometry**
The database includes a `route_geometry` column designed as a LINESTRING spatial data type with an SRID 4326 coordinate system and a spatial index for map-based queries. This field exists to store GPS breadcrumb trails or drawn route paths on a map, allowing visual display of the exact roads the bus follows. However, the current CRUD forms do not include a map drawing interface — the field exists in the schema but is functionally unused, silently remaining NULL for all routes.

---

## Business Rules and Conditions

**Route Identity Uniqueness (BR-TPT-015)**
No two routes can share the same code or the same name. In a busy school with 50+ routes across three shifts and two directions, duplicate route names would cause chaos in trip generation and student allocation. Both the code and name are enforced as unique at the database level.

**Shift Dependency**
A route always belongs to exactly one shift. If a shift is deleted, the database cascades the deletion to all its routes — meaning deleting the "Afternoon" shift would silently delete every afternoon route along with it. There is no soft-block or warning; the CASCADE happens at the database level without application awareness.

**Unused Map Geometry**
The database schema includes a sophisticated spatial column (`route_geometry` as LINESTRING SRID 4326 with a spatial index) designed to store the exact GPS path of a bus route on a map. However, the current user interface has no map drawing tool, route recording feature, or GPX import — so this field is functionally dead. It remains NULL for every route, and the spatial index is unused.

**Soft Delete Behaviour**
Deleting a route sets `is_active = false` first, then calls the soft delete. When restored, only the `deleted_at` timestamp is cleared — the `is_active` flag stays false, requiring a manual status toggle to bring the route back into active service.

---

## Workflow Steps

**Creating a New Route from Scratch**
It is the first week of the academic year. The Transport Manager, Mr. Sharma, opens Transport Master and clicks the Route tab. The system shows an empty list with a search bar and an "Add Route" button. Mr. Sharma clicks Add Route. A form opens asking for the route code, route name, a brief description, the direction (Pickup or Drop), and the shift (Morning, Afternoon, or Evening). Mr. Sharma enters code "MG-PK-01", name "MG Road Morning Pickup Route", selects direction "Pickup", shift "Morning", and optionally adds a note: _This route covers the main arterial road — only experienced drivers should be assigned._ He clicks Save. The system checks that no other route uses code "MG-PK-01" or name "MG Road Morning Pickup Route", creates the record, logs "Route MG-PK-01 created successfully" in the activity log, and returns to the Route tab where the new route now appears in the table. The route is now available in every dropdown across the Transport module — Assign Stops, Driver-Route-Vehicle Assignment, and Trip Generation.

**Editing an Existing Route to Change Direction**
Two weeks into the term, Mr. Sharma realises that the MG Road route should actually serve as a Drop route in the afternoon, not a Pickup route in the morning. He finds MG-PK-01 in the list, clicks Edit, changes the direction from "Pickup" to "Drop" and the shift from "Morning" to "Afternoon", then saves. The system captures the old value ("Pickup") and the new value ("Drop") and records only the changed fields in the activity log. If no fields changed, the system logs "No changes were made" instead of creating an empty audit entry.

**Deactivating a Route Temporarily**
During summer break, some routes are not needed. Mr. Sharma clicks the toggle button next to MG-PK-01 in the route list. An AJAX request fires, flipping `is_active` from 1 to 0. The route disappears from the active list immediately. When the new term begins, he toggles it back on. This approach is better than deleting the route because all historical trip data, stop assignments, and student allocations remain intact — they are just hidden while the route is inactive.

---

## Example Scenario

Green Valley School operates 8 buses across three shifts — Morning (7:00 AM - 9:00 AM), Afternoon (12:00 PM - 1:00 PM), and Evening (3:00 PM - 5:00 PM). At the start of the new academic year, the school's catchment area has expanded to include two new residential colonies: MG Road Extension and Whitefield Phase 2.

The Transport Manager, Mrs. Desai, must create two new pickup routes — one for each colony — and two corresponding drop routes for the afternoon return journey. She opens the Route tab and creates:

1. **MG-PK-01** — "MG Road Extension Morning Pickup", direction Pickup, shift Morning
2. **MG-DR-01** — "MG Road Extension Afternoon Drop", direction Drop, shift Afternoon
3. **WF-PK-01** — "Whitefield Phase 2 Morning Pickup", direction Pickup, shift Morning
4. **WF-DR-01** — "Whitefield Phase 2 Afternoon Drop", direction Drop, shift Afternoon

The system saves all four routes. Mrs. Desai then moves to the Assign Stops to Route tab and adds 6 stops to MG-PK-01 in sequence: Whitefield Cross (ordinal 1), KFC Junction (ordinal 2), MG Road Signal (ordinal 3), Green Valley Apartments (ordinal 4), Lake View Gate (ordinal 5), and School Main Gate (ordinal 6 — the destination). Each stop gets an arrival time calculated in minutes from the route start.

Later, she opens Driver-Route-Vehicle Assignment and assigns Bus KL-05 with driver Rajesh to route MG-PK-01. From this point forward, when the morning shift begins, the system knows exactly which bus takes which route, which stops it visits, in what order, and at what times — all because the routes were defined first.

---

## Related Screens

- **Assign Stops to Route** — Where stops are linked to this route in sequence.
- **Shift Master** — Routes are assigned to a shift.
- **Driver-Route-Vehicle Assignment** — Drivers and vehicles are assigned to routes.
- **Trip Management** — Trips are generated per route.

---

## Requirements

- Controller: `RouteController` with resource methods plus `trashed`, `restore`, `forceDelete`, `toggleStatus`
- Hub tab data: `TransportMasterController@routesQuery()` + AJAX via TransportMasterController
- Route: `Route::resource('route', RouteController::class)` + trash/restore/forceDelete/toggleStatus routes
- Permission gates: `tenant.route.viewAny`, `tenant.route.view`, `tenant.route.create`, `tenant.route.update`, `tenant.route.delete`, `tenant.route.restore`, `tenant.route.forceDelete`
- Form request: `RouteRequest` — validates code (unique), name (unique), pickup_drop (in:Pickup,Drop), shift_id (exists), is_active (boolean)
- Activity logging: ✅ Present on all CRUD + toggleStatus

---

## Who Can Access

- **Transport Manager** — Full CRUD access: create, edit, soft-delete, restore, force-delete routes, and toggle their active status. This is the primary user of the screen.
- **Fleet Supervisor** — Read and update access: can view routes and edit their descriptions and shift assignments, but cannot delete or create new routes.
- **School Administrator** — Read-only access: can view the route list and see which routes exist, but cannot make any changes.
- **Driver** — No access to this screen. Drivers interact with routes only through the Driver-Route-Vehicle Assignment screen and their mobile app.

All access is gated by the `tenant.route.*` permission set. The system enforces these permissions through `Gate::authorize()` calls in each controller method.

---

## Logic Flow

The Transport Master screen loads all master tabs at once, but each tab's data is fetched on demand via AJAX. When the user clicks the Route tab for the first time, the `TransportMasterController@routesQuery()` method runs in the background. It checks which shift the user is viewing (defaults to the first active shift if none selected), queries the `tpt_route` table with an eager-loaded `shift` relationship, applies any search term typed into the search box (matching against `name`, `code`, or `description`), applies the active/inactive status filter if one is selected, and paginates the results at 10 records per page.

When the user clicks the standalone Route menu (outside Transport Master), the `RouteController@index()` method takes over. It loads all routes with their shift relations, paginated at 10 per page, and applies a default ordering by the latest created first.

For creating a new route, the user clicks Add Route. The `create()` method loads only the active shifts from the Shift Master so the user can pick the right time slot. On form submission, the `store()` method validates the input through the `RouteRequest` form request class, which checks that both the code and name are unique across all routes (including soft-deleted ones), that the direction is either "Pickup" or "Drop", and that the shift ID exists in the database. If validation passes, the route is created with `is_active` defaulting to 1, the activity is logged with the message "Stored", and the user is redirected back to Transport Master where the route now appears in the table.

For updates, the `edit()` method loads the existing route with its shift relation, while the `update()` method takes a slightly different approach from most controllers: it first captures all the original field values into an array, then runs the update. After saving, it compares old and new values using `array_diff_assoc`. If differences are found, it logs each changed field with its old and new values in the activity log as "Updated". If no fields changed, it logs "No changes were made" rather than creating a meaningless audit entry.

For soft deletion, the `destroy()` method sets `is_active = 0` first, then calls the Eloquent soft delete, and logs "Trashed" in the activity log. The `restore()` method clears the `deleted_at` timestamp — but notably does NOT set `is_active` back to 1, so the restored route remains hidden from active lists until the Transport Manager manually toggles it back on.

For status toggling, an AJAX POST request hits the `toggleStatus()` endpoint. The controller finds the route, flips `is_active` between 0 and 1, saves the model, logs "Toggled" with the new status value, and returns a JSON response with the new state and a success message. The frontend JavaScript then updates the toggle button UI without refreshing the page.

For permanent deletion, the `forceDelete()` method gates the `tenant.route.forceDelete` permission and permanently removes the route from the database. This is irreversible and typically only used when a route was created by mistake with no downstream data attached to it.

---

## Validate Before Save

| Field | Rule(s) | Error Message |
|-------|---------|---------------|
| `code` | `required, string, max:50, unique:tpt_route` | "The code has already been taken." |
| `name` | `required, string, max:200, unique:tpt_route` | "The name has already been taken." |
| `pickup_drop` | `required, in:Pickup,Drop` | "The selected pickup/drop direction is invalid. Please choose Pickup or Drop." |
| `shift_id` | `required, exists:tpt_shift,id` | "The selected shift is invalid or does not exist." |
| `is_active` | `required, boolean` | "The active status field must be true or false." |

---

## Error Handling and Validation Messages

| Scenario | Message | Type |
|----------|---------|------|
| Duplicate route code | "The code has already been taken." | Validation — unique rule |
| Duplicate route name | "The name has already been taken." | Validation — unique rule |
| Missing route code | "The code field is required." | Validation — required rule |
| Invalid direction value | "The selected pickup/drop direction is invalid. Please choose Pickup or Drop." | Validation — in rule |
| Shift ID does not exist | "The selected shift is invalid or does not exist." | Validation — exists rule |
| Permission denied on index | `Gate::authorize()` throws `AuthorizationException` → 403 Forbidden | Framework |
| Permission denied on force delete | "This action is unauthorized." — `Gate::authorize()` throws 403 | Framework |
| Route geometry field ignored | The map geometry field exists in the DDL but no UI control writes to it. The field silently remains NULL for all routes. | 🔴 Gap — schema dead column |
| Shift CASCADE delete | If a shift is deleted, all its routes are deleted at the database level without any application-level warning or confirmation to the user. | 🔴 Gap — silent data loss |

---

## Success Scenarios

**SC-001 — Create a New Pickup Route at the Start of the Year**
At the beginning of the academic year, the Transport Manager creates 10 pickup routes and 10 drop routes across Morning, Afternoon, and Evening shifts. Each route is given a unique code (e.g., "MG-PK-01", "WF-DR-02"), a descriptive name, and the correct direction. All 20 routes are saved successfully without any duplicate code or name conflicts. The system logs each creation with "Stored" in the activity log. The routes are now available in the Assign Stops, Driver-Route-Vehicle Assignment, and Trip Generation screens.

**SC-002 — Edit a Route to Correct Its Direction**
The Transport Manager realises that route "MG-PK-01" was accidentally created as a Drop route but should be a Pickup route. They open the edit form, change the direction from "Drop" to "Pickup", and save. The system detects the field change, logs "Route ID 5 updated: pickup_drop changed from 'Drop' to 'Pickup'" in the activity log, and returns to the route list where the updated direction is now displayed correctly.

**SC-003 — Toggle a Route Off for the Summer Holidays**
During the summer break, the school needs only 5 of its 20 routes active. The Transport Manager toggles off 15 routes one by one using the AJAX toggle button. Each toggle sends a POST request, the system flips `is_active` from 1 to 0, logs "Toggled (0)" in the activity log, and returns a JSON success response. The frontend greys out the toggled route in the list without a full page reload. When the new term starts, the manager toggles them all back on.

---

## Failure Scenarios

**FC-001 — Duplicate Route Code Rejected**
The Transport Manager tries to create a route with code "MG-PK-01" but this code is already used by another route. The system displays the validation error "The code has already been taken." and the form is not submitted. The manager must choose a different code, such as "MG-PK-02", to proceed.

**FC-002 — Duplicate Route Name Rejected**
The Transport Manager tries to create a route named "MG Road Morning Pickup Route" but a route with exactly this name already exists (a previous year's route that was soft-deleted but still in the database). The system checks uniqueness against all records including trashed and displays "The name has already been taken." The manager renames it to "MG Road Morning Pickup Route 2025-26" and saves successfully.

**FC-003 — Shift Deleted with Active Routes (Silent Data Loss)**
An administrator deletes the "Afternoon" shift from the Shift Master because the school discontinued the afternoon session. Because the DDL defines `ON DELETE CASCADE` on the `shift_id` foreign key, all routes that belonged to the Afternoon shift — including their stop assignments, trip histories, and driver assignments — are deleted at the database level without any warning or confirmation. The Transport Manager does not discover the loss until the next morning when afternoon trips fail to generate. **This is a critical data integrity gap.**

**FC-004 — Restored Route Does Not Reactivate**
The Transport Manager restores a previously deleted route expecting it to become active. However, the `restore()` method only clears `deleted_at` — it does not set `is_active` back to 1. The route remains invisible in all dropdowns and the manager cannot assign stops or generate trips for it. The manager must manually find the route in the active/inactive filter and toggle it back on, which is non-obvious and causes confusion.

---

## Dependencies

| Dependency | Type | Details |
|-----------|------|---------|
| `tpt_shift` | FK Table | shift_id → CASCADE |
| `tpt_pickup_points_route_jnt` | Child Table | Junction referencing route_id → CASCADE |
| `tpt_driver_route_vehicle_jnt` | Child Table | Assignments per route |
| `tpt_trip` | Child Table | Trips per route |
| `tpt_student_route_allocation_jnt` | Child Table | Student route allocations |

**Table:** `tpt_route`

| Column | Type | Details |
|--------|------|---------|
| id | INT UNSIGNED PK | Auto-increment |
| code | VARCHAR(50) NOT NULL UNIQUE | Route code |
| name | VARCHAR(200) NOT NULL UNIQUE | Route name |
| description | VARCHAR(500) NULL | Notes |
| pickup_drop | ENUM('Pickup','Drop') | Direction |
| shift_id | INT UNSIGNED NOT NULL FK | → `tpt_shift.id` CASCADE |
| route_geometry | LINESTRING SRID 4326 | Map path (spatial) |
| is_active | TINYINT(1) DEFAULT 1 | — |
| created_at | TIMESTAMP | — |
| updated_at | TIMESTAMP | — |
| deleted_at | TIMESTAMP NULL | Soft deletes |
| SPATIAL INDEX | `(route_geometry)` | For map queries |
