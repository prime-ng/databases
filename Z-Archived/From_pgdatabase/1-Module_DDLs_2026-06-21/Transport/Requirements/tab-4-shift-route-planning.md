# Transport Tab 4: Shift & Route Planning

This screen defines the operational shifts and the routes that run within each shift. Routes are directional — each route is either a Pickup route (morning, collecting students) or a Drop route (afternoon/evening, dropping students home). Pickup points with GPS coordinates are assigned to routes in sequential order.

---

## How It Works

The screen has three interconnected sections. First, the administrator defines shifts — for example, "Morning Shift" and "Evening Shift" — each with a code, name, and effective date range. A shift represents a time period during which transport operations run.

Second, within each shift, the administrator creates routes. Each route has a code, name, description, and a direction (Pickup or Drop). Routes cannot serve both directions — a route is exclusively for picking students up or dropping them off. The route can optionally have a spatial geometry (LINESTRING) for GPS tracking.

Third, for each route, the administrator assigns pickup points in sequential order. Each pickup point has a name, GPS coordinates (latitude/longitude), a spatial POINT location, total distance from the depot, and estimated travel time. The administrator also sets the arrival time, departure time, and fare for each stop on the route — including separate fares for one-side (pickup or drop) and both-side service.

---

## Important Business Rules

- Shift codes and names must each be unique across all shifts.
- Each route is directional (Pickup or Drop only, not both). A separate route must be created for the opposite direction.
- A route belongs to exactly one shift.
- Route codes and names must each be unique across the entire system.
- A pickup point can belong to multiple routes, but a specific pickup point can appear only once on a given route.
- Pickup points are ordered on a route using the `ordinal` field — stop sequence is determined by this number.
- GPS coordinates are stored both as separate decimal fields (latitude/longitude) and as a spatial POINT for geo-queries.
- The `stop_type` on a pickup point determines if it is used for Pickup, Drop, or Both — this is independent of the route's direction.
- Fares for each pickup-point-on-route are stored at the junction level, so the same pickup point can have different fares on different routes.

---

## Database Columns & Behavior

### tpt_shift
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `code` — VARCHAR(20), NOT NULL. Unique shift code.
- `name` — VARCHAR(100), NOT NULL. Unique shift name.
- `effective_from` — DATE, NOT NULL. Start date of the shift period.
- `effective_to` — DATE, NOT NULL. End date of the shift period.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_route
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `code` — VARCHAR(50), NOT NULL. Unique route code.
- `name` — VARCHAR(200), NOT NULL. Unique route name.
- `description` — VARCHAR(500), nullable. Route description.
- `pickup_drop` — ENUM('Pickup','Drop'), NOT NULL, default 'Pickup'. Route direction.
- `shift_id` — INT UNSIGNED, NOT NULL. FK to tpt_shift. Shift this route belongs to.
- `route_geometry` — LINESTRING (SRID 4326), nullable. Spatial geometry for GPS route tracking.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_pickup_points
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `shift_id` — INT UNSIGNED, NOT NULL. FK to tpt_shift. Shift this point belongs to.
- `code` — VARCHAR(50), NOT NULL. Unique pickup point code.
- `name` — VARCHAR(200), NOT NULL. Unique pickup point name.
- `latitude` — DECIMAL(10,7), nullable. GPS latitude.
- `longitude` — DECIMAL(10,7), nullable. GPS longitude.
- `location` — POINT (SRID 4326), NOT NULL. Spatial point for geo-queries.
- `total_distance` — DECIMAL(7,2), nullable. Distance from depot in km.
- `estimated_time` — INT, nullable. Estimated travel time in minutes.
- `stop_type` — ENUM('Pickup','Drop','Both'), NOT NULL, default 'Both'.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_pickup_points_route_jnt
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `shift_id` — INT UNSIGNED, NOT NULL. FK to tpt_shift.
- `route_id` — INT UNSIGNED, NOT NULL. FK to tpt_route.
- `pickup_drop` — ENUM('Pickup','Drop'), NOT NULL, default 'Pickup'. Direction for this junction.
- `pickup_point_id` — INT UNSIGNED, NOT NULL. FK to tpt_pickup_points.
- `ordinal` — SMALLINT UNSIGNED, default 1. Stop sequence number on the route.
- `total_distance` — DECIMAL(7,2), nullable. Distance from previous stop in km.
- `arrival_time` — INT, nullable. Scheduled arrival time in minutes from shift start.
- `departure_time` — INT, nullable. Scheduled departure time in minutes from shift start.
- `estimated_time` — INT, nullable. Estimated time to next stop in minutes.
- `pickup_drop_fare` — DECIMAL(10,2), nullable. One-side fare for this stop.
- `both_side_fare` — DECIMAL(10,2), nullable. Both-side fare for this stop.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.
- Unique key on (`route_id`, `pickup_point_id`).

---

## Deep Analysis

### Business Workflows & State Machines

- **Shift Management:** Add Shift → Validate unique code/name → INSERT with effective date range → Editable until routes are assigned.
- **Route Creation:** Select shift → Set direction (Pickup/Drop exclusive) → Add code/name/description → INSERT → Optionally set spatial geometry.
- **Pickup Point Assignment:** Select route → Add pickup points with GPS coordinates → Set ordinal sequence → Configure arrival/departure times and fares → Junction record saved.
- **State Machine (Shift):** Active → (when routes exist) → cannot be deleted; can only be deactivated via `is_active = 0`.
- **State Machine (Route):** Active → (when allocated to a driver) → cannot be deleted; only deactivated.

### Validation Rules & Edge Cases

- **Shift uniqueness:** `code` and `name` each have unique indexes; enforce separately.
- **Route direction:** A route marked as `Pickup` cannot have stops of type `Drop` only; `Both` type stops are allowed regardless.
- **Ordinal sequence:** Must be unique per route; no duplicates allowed. Gaps are acceptable but may cause display issues.
- **Fare logic:** `pickup_drop_fare` and `both_side_fare` can be set per junction; both_side_fare should be ≥ pickup_drop_fare.
- **GPS coordinates:** Must be valid lat/lng pairs; latitude -90 to 90, longitude -180 to 180.
- **Spatial data:** `location` POINT is required (NOT NULL); `latitude`/`longitude` can be nullable but at least one representation must be filled.
- **Effective date range:** `effective_to` must be ≥ `effective_from` for shifts; routes inherit shift's date range.
- **Time fields:** `arrival_time` and `departure_time` are stored as minutes from shift start; departure must be ≥ arrival time for each stop.

### Integration Points

- **tpt_driver_route_vehicle_jnt** — references `route_id` and `shift_id`.
- **tpt_route_scheduler_jnt** — references `route_id` and `shift_id`.
- **tpt_trip** — references `route_id`.
- **tpt_pickup_points** — shared across shifts; linked via junction table.
- **tpt_student_route_allocation_jnt** — references `pickup_route_id` and `drop_route_id`.
- **tpt_trip_stop_detail** — references `stop_id`.
- **Spatial indexes:** `route_geometry` (LINESTRING) and `location` (POINT) with SRID 4326 enable geo-queries.

### Permissions Matrix

| Role | Shift CRUD | Route CRUD | Pickup Point CRUD | Junction Config |
|---|---|---|---|---|
| Super Admin | Full | Full | Full | Full |
| School Admin | Full | Full | Full | Full |
| Transport Manager | View only | Create/Edit | Create/Edit | Create/Edit |
| Driver / Helper | No access | No access | No access | No access |
