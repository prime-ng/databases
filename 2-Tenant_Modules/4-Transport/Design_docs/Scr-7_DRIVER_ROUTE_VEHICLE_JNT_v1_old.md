**Title**: Driver - Route - Vehicle Assignment

**Purpose**: UI to manage assignments of drivers and vehicles to routes and shifts. Mirrors `tpt_driver_route_vehicle_jnt` table.

Summary
- Primary actor: Transport Admin
- Use-cases: create assignments, edit effective dates, view active assignments, deactivate/soft-delete.

Data model (fields)
- `id` : bigint (PK)
- `shift_id` : bigint (FK -> `tpt_shift.id`)
- `route_id` : bigint (FK -> `tpt_route.id`)
- `vehicle_id` : bigint (FK -> `tpt_vehicle.id`)
- `driver_id` : bigint (FK -> `tpt_personnel.id`)
- `helper_id` : bigint (FK -> `tpt_personnel.id`, nullable)
- `effective_from` : date
- `effective_to` : date (nullable)
- `is_active` : boolean
- `created_at`, `updated_at`, `deleted_at`

Key UX Flows
- List view: filterable by shift, route, vehicle, driver, date; shows current active assignment rows with quick actions (Edit, Deactivate, View History).
- Create: modal or page with fields for shift, route, vehicle, driver, helper and effective date range. Validate overlapping assignments.
- Edit: allow changing effective_to to end assignment or reassign vehicle/driver (creates new record recommended).
- Detail: audit log, history of assignments for driver/vehicle, sample route map link.

API Contracts
- GET /api/transport/assignments?shift={}&route={}&active=1 -> list
- POST /api/transport/assignments -> create {shift_id, route_id, vehicle_id, driver_id, helper_id, effective_from, effective_to}
- GET /api/transport/assignments/{id} -> get
- PUT /api/transport/assignments/{id} -> update
- DELETE /api/transport/assignments/{id} -> soft-delete (sets `deleted_at`)

Validation Rules
- All of `shift_id`, `route_id`, `vehicle_id`, `driver_id` required
- `effective_from` <= `effective_to` (if provided)
- Prevent overlapping active assignment for same vehicle+shift+date range (client shows warning; enforcement via backend check)

UI Components
- Filters row: shift select, route select, date picker, driver search, vehicle search.
- Grid: columns (ID, Shift, Route, Vehicle, Driver, Helper, From, To, Active, Actions)
- Create/Edit form: selects with typeahead for driver/vehicle; date range pickers; preview map link for route

Acceptance Tests
- Create assignment with valid data -> 201 and row appears in list
- Attempt overlapping assignment for same vehicle in same date range -> 4xx validation error
- Soft-delete assignment -> record not returned in active list

Notes
- Because `tpt_driver_route_vehicle_jnt` is junction for scheduling, prefer write-once pattern for history: avoid in-place edits; create new record for changes to preserve audit.
- UI should show assignment conflict warnings but allow override with explicit confirm (admin privileges).
